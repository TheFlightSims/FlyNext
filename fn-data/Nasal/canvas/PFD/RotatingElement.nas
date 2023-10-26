# PFD UI Element - Rotating UI Element. Displays value by rotating an element around a center-point
var RotatingElement =
{
  new : func (pagename, svg, name, minVal, maxVal, rangeDeg, centerOffset, value=0, style=nil)
  {
    var obj = {
      parents : [ RotatingElement, PFD.UIElement ],
      _name : pagename ~ name,
      _edit : 0,
      _min : minVal,
      _max : maxVal,
      _rangeDeg : rangeDeg,
      _style : style,
    };

    if (style == nil) obj._style = PFD.DefaultStyle;

    obj._symbol = svg.getElementById(obj._name);
    assert(obj._symbol != nil, "Unable to find element " ~ obj._name);
    obj._baseTranslation = obj._symbol.getTranslation();

    # Set the center for rotation purposes.
    assert(size(centerOffset) == 2, "centerOffset must be an array of two elements [x,y]");
    obj._symbol.set("center-offset-x", centerOffset[0]);
    obj._symbol.set("center-offset-y", centerOffset[1]);

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

    # Rotate, scales appropriately
    me._symbol.setRotation(value * me._rangeDeg * D2R, [0.0, 0.0]);
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
