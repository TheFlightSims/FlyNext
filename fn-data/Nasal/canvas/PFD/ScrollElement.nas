# PFD UI Element - Scrolling UI Text Element.
# Has a set of values and arrows left & right to indicate whether there are
# further data items to scroll through.
var ScrollElement =
{

  new : func (pageName, svg, name, values, initialIndex=0, style=nil)
  {
    var obj = {
      parents : [ ScrollElement, PFD.UIElement ],
      _name : pageName ~ name,
      _values : values,
      _index : 0,
      _style : style,
    };

    if (style == nil) obj._style = PFD.DefaultStyle;

    obj._symbol = svg.getElementById(obj._name);
    assert(obj._symbol != nil, "Unable to find element " ~ obj._name);

    obj._leftsymbol = svg.getElementById(obj._name ~ "Left");
    assert(obj._leftsymbol != nil, "Unable to find element " ~ obj._name ~ "Left");

    obj._rightsymbol = svg.getElementById(obj._name ~ "Right");
    assert(obj._rightsymbol != nil, "Unable to find element " ~ obj._name ~ "Right");

    obj._index = initialIndex;
    assert(initialIndex < size(values) , "Initial index " ~ initialIndex ~ " extends past end of value array");

    # State and timer for flashing highlighting of elements
    # We need a separate Enabled flag as the timers are in a separate thread.
    obj._highlightEnabled = 0;
    obj._highlighted = 0;
    obj._flashTimer = nil;

    obj.updateValues();

    return obj;
  },

  updateValues : func() {
    if (me._index == 0 ) {
      me._leftsymbol.setColorFill(me._style.SCROLL_UNAVAILABLE);
      me._leftsymbol.setColor(me._style.SCROLL_UNAVAILABLE);
    } else {
      me._leftsymbol.setColorFill(me._style.SCROLL_AVAILABLE);
      me._leftsymbol.setColor(me._style.SCROLL_AVAILABLE);
    }

    if ((size(me._values) > 0) and (me._index < (size(me._values) -1))) {
      me._rightsymbol.setColorFill(me._style.SCROLL_AVAILABLE);
      me._rightsymbol.setColor(me._style.SCROLL_AVAILABLE);
    } else {
      me._rightsymbol.setColorFill(me._style.SCROLL_UNAVAILABLE);
      me._rightsymbol.setColor(me._style.SCROLL_UNAVAILABLE);
    }

    me._symbol.setText(me._values[me._index]);
  },

  getName : func() { return me._name; },
  getValue : func() { return me._symbol.getText(); },
  setValue : func(value) {
    var idx = find(value, me._values);
    if (idx != -1) {
      me._index = idx;
      me._symbol.setText(value);
    }
  },
  setValues : func(values) {
    me._values = values;
    me._index = 0;
    me.updateValues();
  },
  setVisible : func(vis) {
    me._symbol.setVisible(vis);
    me._leftsymbol.setVisible(vis);
    me._rightsymbol.setVisible(vis);
  },
  _flashElement : func() {
    if (me._highlightEnabled == 0) {
      me._symbol.setDrawMode(canvas.Text.TEXT);
      me._symbol.setColor(me._style.NORMAL_TEXT_COLOR);
      me._highlighted = 0;
    } else {
      if (me._highlighted == 0) {
        me._symbol.setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX);
        me._symbol.setColorFill(me._style.HIGHLIGHT_COLOR);
        me._symbol.setColor(me._style.HIGHLIGHT_TEXT_COLOR);
        me._highlighted = 1;
      } else {
        me._symbol.setDrawMode(canvas.Text.TEXT);
        me._symbol.setColor(me._style.NORMAL_TEXT_COLOR);
        me._highlighted = 0;
      }
    }
  },
  highlightElement : func() {
    me._highlightEnabled = 1;
    me._highlighted = 0;
    me._flashElement();
    me._flashTimer = maketimer(me._style.CURSOR_BLINK_PERIOD, me, me._flashElement);
    me._flashTimer.start();
  },
  unhighlightElement : func() {
    if (me._flashTimer != nil) me._flashTimer.stop();
    me._flashTimer = nil;
    me._highlightEnabled = 0;
    me._highlighted = 0;
    me._flashElement();
  },
  isEditable : func () { return 0; },
  isInEdit : func() { return 0; },
  enterElement : func() { return me.getValue(); },
  clearElement : func() { },
  editElement : func()  { },
  incrSmall : func(value) {
    # Increment the scroll value;
    var incr_or_decr = (value > 0) ? 1 : -1;
    if ((me._index + incr_or_decr) < 0) return;
    if ((me._index + incr_or_decr) > (size(me._values) -1)) return;
    me._index = me._index + incr_or_decr;
    me.updateValues();
  },
  incrLarge : func(value) { },
};
