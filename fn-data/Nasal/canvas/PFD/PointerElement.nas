# PFD UI Element - Pointer UI Element. Displays value by moving the element on a horizontal or vertical scale.
var PointerElement =
{
  new : func (pagename, svg, name, minVal, maxVal, scalePx, vertical=0, value=0, style=nil)
  {
    var obj = {
      parents : [ PointerElement, PFD.UIElement ],
      _name : pagename ~ name,
      _edit : 0,
      _min : minVal,
      _max : maxVal,
      _scale : scalePx,
      _vertical : vertical,
      _style : style,
    };

    if (style == nil) obj._style = PFD.DefaultStyle;

    obj._symbol = svg.getElementById(obj._name);
    assert(obj._symbol != nil, "Unable to find element " ~ obj._name);
    obj._baseTranslation = obj._symbol.getTranslation();
    obj.setValue(value);

    # State and timer for flashing highlighting of elements
    # We need a separate Enabled flag as the timers are in a separate thread.
    obj._highlightEnabled = 0;
    obj._highlighted = 0;
    obj._flashTimer = nil;

    return obj;
  },

  getName : func() { return me._name; },
  getValue : func() { return me._value; },
  setValue : func(value) {
    if (value == nil) value = 0.0;

    #  Bound value to the minimum and maximum values.
    value = math.max(me._min, value);
    value = math.min(me._max, value);

    # Convert to normalized value
    value = (value - me._min) / (me._max - me._min);

    # Simply shift the slider along.
    if (me._vertical) {
      # Vertical
      me._symbol.setTranslation([
        me._baseTranslation[0],
        me._baseTranslation[1] + (value * me._scale)
      ]);
    } else {
      # Horizontal
      me._symbol.setTranslation([
        me._baseTranslation[0] + (value * me._scale),
        me._baseTranslation[1]
      ]);

    }
  },

  setVisible : func(vis) { me._symbol.setVisible(vis); },
  _flashElement : func() {
    if (me._highlightEnabled == 0) {
      me._symbol.setVisible(0);
      me._highlighted = 0;
    } else {
      if (me._highlighted == 0) {
        me._symbol.setVisible(1);
        me._highlighted = 1;
      } else {
        me._symbol.setVisible(0);
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
  incrSmall : func(value) { },
  incrLarge : func(value) { },
};
