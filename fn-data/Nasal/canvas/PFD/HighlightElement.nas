# PFD UI Element - Highlight UI Element. Can have values set and retrieved
# Highlighting flashes the element.
var HighlightElement =
{
  new : func (pagename, svg, name, value="", style=nil)
  {
    var obj = {
      parents : [ HighlightElement, PFD.UIElement ],
      _name : pagename ~ name,
      _value : value,
      _style : style,
    };

    if (style == nil) obj._style = PFD.DefaultStyle;

    obj._symbol = svg.getElementById(obj._name);
    assert(obj._symbol != nil, "Unable to find element " ~ obj._name);

    # State and timer for flashing highlighting of elements
    # We need a separate Enabled flag as the timers are in a separate thread.
    obj._highlightEnabled = 0;
    obj._highlighted = 0;
    obj._flashTimer = nil;

    obj.setVisible(0);

    return obj;
  },

  getName : func() { return me._name; },
  getValue : func() { return me._value; },
  setValue : func(value) { me._value = value; },
  setVisible : func(vis) { me._symbol.setVisible(vis); },

  _flashElement : func() {
    if (me._highlighted == 0) {
      me._symbol.setVisible(1);
      me._highlighted = 1;
    } else {
      me._symbol.setVisible(0);
      me._highlighted = 0;
    }
  },
  highlightElement : func() {
    me._highlightEnabled = 1;
    me._highlighted = 0;
    # Force it to immediately display, rather than waiting for the timer
    me._symbol.setVisible(1);
    PFD.HighlightTimer.startHighlight(me, -1);
  },
  unhighlightElement : func() {
    me._symbol.setVisible(0);
    me._highlighted = 0;
    me._highlightEnabled = 0;
    PFD.HighlightTimer.stopHighlight(me);
  },
  isEditable : func () { return 0; },
  isInEdit : func() { return 0; },
  enterElement : func() { return me.getValue(); },
  isHighlighted : func() { return me._highlighted; },
  clearElement : func() { },
  editElement : func()  { },
  incrSmall : func(value) { },
  incrLarge : func(value) { },
};
