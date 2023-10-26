# PFD DataEntryElement - Data Entry UI Element.
#
# Uses the FMS Knobs to enter a text value with a given length and character set.
#
# To use, there must be an element called [PageName][ElementName] which will
# be used for the complete string, and a set of [PageName][ElementName]{0...n}
# elements, each consisting of a single character for input.
#
var DataEntryElement =
{
  new : func (pagename, svg, name, value, size, charSet, style=nil)
  {
    var obj = {
      parents : [ DataEntryElement, PFD.UIElement ],
      _name : pagename ~ name,
      _size : size,
      _charSet : charSet,
      _dataEntryPos : -1,
      _dataEntrySymbol : [],
      _style : style,
    };

    if (style == nil) obj._style = PFD.DefaultStyle;

    obj._symbol = svg.getElementById(obj._name);
    assert(obj._symbol != nil, "Unable to find element" ~ obj._name);
    obj.setValue(value);

    for (var i = 0; i < size; i = i + 1) {
      var nodeName = obj._name ~ i;
      append(obj._dataEntrySymbol, svg.getElementById(nodeName));
      assert(obj._dataEntrySymbol[i] != nil, "Unable to find element " ~ nodeName);
      obj._dataEntrySymbol[i].setVisible(0);
    }

    # State and timer for flashing highlighting of elements
    obj._highlightEnabled = 0;
    obj._flash = 0;
    obj._highlightCharEnabled = 0;
    obj._flashChar = 0;

    return obj;
  },

  getName : func() { return me._name; },
  getValue : func() { return me._symbol.getText(); },
  setValue : func(value) { me._symbol.setText(value); },
  setVisible : func(vis) {
    me._symbol.setVisible(vis);

    # Only ever hide the character entry symbols, as they are displayed
    # only when editing
    if (vis == 0) {
      for (var i = 0; i < me._size; i = i + 1) me._dataEntrySymbol[i].setVisible(0);
    }
  },

  _flashElement : func() {
    if ((me._highlightEnabled == 1) and (me._highlightCharEnabled == 0)) {
      if (me._flash == 0) {
        me._symbol.setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX);
        me._symbol.setColorFill(me._style.HIGHLIGHT_COLOR);
        me._symbol.setColor(me._style.HIGHLIGHT_TEXT_COLOR);
        me._flash = 1;
      } else {
        me._symbol.setDrawMode(canvas.Text.TEXT);
        me._symbol.setColor(me._style.NORMAL_TEXT_COLOR);
        me._flash = 0;
      }
    }

    if (me._highlightCharEnabled == 1) {
      if (me._flashChar == 0) {
        me._dataEntrySymbol[me._dataEntryPos].setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX);
        me._dataEntrySymbol[me._dataEntryPos].setColorFill(me._style.HIGHLIGHT_COLOR);
        me._dataEntrySymbol[me._dataEntryPos].setColor(me._style.HIGHLIGHT_TEXT_COLOR);
        me._flashChar = 1;
      } else {
        me._dataEntrySymbol[me._dataEntryPos].setDrawMode(canvas.Text.TEXT);
        me._dataEntrySymbol[me._dataEntryPos].setColor(me._style.NORMAL_TEXT_COLOR);
        me._flashChar = 0;
      }
    }
  },
  highlightElement : func() {
    me._highlightEnabled = 1;
    me._flash = 0;
    PFD.HighlightTimer.startHighlight(me, -1);
  },
  unhighlightElement : func() {
    me._highlightEnabled = 0;
    me._symbol.setDrawMode(canvas.Text.TEXT);
    me._symbol.setColor(me._style.NORMAL_TEXT_COLOR);
    PFD.HighlightTimer.stopHighlight(me);
  },

  _highlightCharElement : func() {
    me._highlightCharEnabled = 1;
    me._flashChar = 0;
  },
  _unhighlightCharElement : func() {
    me._highlightCharEnabled = 0;
    me._dataEntrySymbol[me._dataEntryPos].setDrawMode(canvas.Text.TEXT);
    me._dataEntrySymbol[me._dataEntryPos].setColor(me._style.NORMAL_TEXT_COLOR);
  },

  isEditable : func () { return 1; },
  isInEdit : func() { return (me._dataEntryPos != -1); },
  isHighlighted : func() { return me._highlightEnabled; },

  enterElement : func() {
    # Handle pressing enter to confirm this element.
    # - Hiding the per-character entry fields
    # - concatenating the data that's been entered into a string
    # - displaying the string in the (highlighted) top level element
    #
    # Also pass back the string to the caller.

    var val = "";

    for (var i = 0; i < me._size; i = i + 1) {
      if (me._dataEntrySymbol[i].getText() != "_") {
        val = val ~ me._dataEntrySymbol[i].getText();
      }
      me._dataEntrySymbol[i].setVisible(0);
    }

    me._symbol.setText(val);
    me._symbol.setVisible(1);
    me.highlightElement();
    me._dataEntryPos = -1;
    return val;
  },
  clearElement : func() {
    # Cancel editing this element by
    # - Hiding the per-character entry fields
    # - Highlighting the top level element

    for (var i = 0; i < me._size; i = i + 1) {
      me._dataEntrySymbol[i].setVisible(0);
    }

    me._symbol.setVisible(1);
    me.highlightElement();
    me._dataEntryPos = -1;
  },
  _startEdit: func() {
      # Start editing by hiding the top level element, and displaying and
      # resetting the character entry fields.
      me._dataEntryPos = 0;

      me._symbol.setVisible(0);

      for (var i = 0; i < me._size; i = i + 1) {
        me._dataEntrySymbol[i].setText("_");
        me._dataEntrySymbol[i].setVisible(1);
      }

      # Highlight the first character element to indicate we're editing it
      me._highlightCharElement();
  },
  keyPress: func(value) {
    if (me._dataEntryPos == -1) {
      me._startEdit();
    } 
    var charSym = me._dataEntrySymbol[me._dataEntryPos];
    charSym.setText(value);

    if ( me._dataEntryPos == me._size -1 ) return;

    me._unhighlightCharElement();
    me._dataEntryPos = me._dataEntryPos + 1;
    me._highlightCharElement();
  },
  incrSmall : func(value) {
    # Change the value of this element, or start editing it if we're not already
    # doing so.

    if (me._dataEntryPos == -1) {
      me._startEdit();
    } else {
      var charSym = me._dataEntrySymbol[me._dataEntryPos];
      var incr_or_decr = (value > 0) ? 1 : -1;

      # Change the value of the data element
      var val = charSym.getText();

      if (val == "_") {
        # Not previously set, so set to the first or last characterset entry
        # depending on direction
        if (incr_or_decr > 0) {
          charSym.setText(chr(me._charSet[0]));
        } else {
          charSym.setText(chr(me._charSet[size(me._charSet) -1]));
        }
      } else {
        var curIdx = find(val, me._charSet);

        if (curIdx == -1) die("Failed to find character " ~ val ~ " in dataEntryElement " ~ element);
        curIdx = math.mod(curIdx + incr_or_decr, size(me._charSet));
        charSym.setText(chr(me._charSet[curIdx]));
      }
    }
  },
  incrLarge : func(value) {
    # Change the cursor position within a data element
    var incr_or_decr = (value > 0) ? 1 : -1;

    if ((me._dataEntryPos == 0)           and (incr_or_decr == -1)) return; # Don't scroll off the start
    if ((me._dataEntryPos == me._size -1) and (incr_or_decr ==  1)) return; # Don't scroll off the end

    me._unhighlightCharElement();
    me._dataEntryPos = me._dataEntryPos + incr_or_decr;
    me._highlightCharElement();
  },
};
