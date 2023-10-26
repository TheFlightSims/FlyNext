# Slider.nas : show a user-draggable slider
# with optional tick marks and value display
# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.Slider = {
  ValueStyle: {
    Fixed: 0,
    Moving: 1,
  },
  ValuePosition: {
    None: 0,
    Above: 1,
    Below: 2,
  },
  TicksPosition: {
    None: 0,
    Above: 1,
    Below: 2,
  },
  new: func(parent, style, cfg)
  {
    var cfg = Config.new(cfg);
    var m = gui.Widget.new(gui.widgets.Slider);
    m._focus_policy = m.StrongFocus;
    m._thumbDown = 0;
    m._minValue = cfg.get("min-value", 0);
    m._maxValue = cfg.get("max-value", 100);
    m._value = cfg.get("value", 50);
    m._stepSize = cfg.get("step-size", 1);
    m._pageSize = cfg.get("page-size", 10);
    m._tickStep = cfg.get("tick-step", 10);

    m._ticksPosition = cfg.get("ticks-position", m.TicksPosition.None);
    m._valueDisplayStyle = cfg.get("value-style", m.ValueStyle.Moving);
    m._valueDisplayPosition = cfg.get("value-position", m.ValuePosition.None);

    m._setView(style.createWidget(parent, cfg.get("type", "slider"), cfg));
    m._view._updateLayoutSizes(m);

    return m;
  },

  setValue: func(val)
  {
    me._value = math.clamp(val, me._minValue, me._maxValue);
    if (me._view != nil) {
      me._view.setNormValue(me, me._normValue());
    }
    return me;
  },

  setValuePosition: func(pos) {
    me._valueDisplayPosition = pos;
    me._view._updateLayoutSizes(me);
  },

  setValueStyle: func(style) {
    me._valueDisplayStyle = style;
    me._view._updateLayoutSizes(me);
  },

  setTicksPositon: func(pos) {
    me._ticksPosition = pos;
    me._view._updateLayoutSizes(me);
  },

# protected:
  _setView: func(view)
  {
    call(gui.Widget._setView, [view], me);

    var el = view._root;
    el.addEventListener("click", func(e) {
      me._dragThumb(e);
    });
    
    view._thumb.addEventListener("drag", func(e) {
      me._dragThumb(e);
      e.stopPropagation();
    });
    view._thumb.addEventListener("mousedown", func(e) {
      me._thumbDown = 1;
      me._onStateChange();
    });
    view._thumb.addEventListener("mouseup", func(e) {
      me._thumbDown = 0;
      me._onStateChange();
    });
    view._root.addEventListener("wheel", func(e) {
      if (!me._enabled) {
        return;
      }

      me.setValue(me._value + e.deltaY * me._stepSize);
      e.stopPropagation();
    });
    view._root.addEventListener("keydown", func(e) {
      var value = me._value;
      if (contains([
        keyboard.FunctionKeys.Left, keyboard.FunctionKeys.KP_Left,
        keyboard.FunctionKeys.Down, keyboard.FunctionKeys.KP_Down,
        keyboard.PrintableKeys.Minus, keyboard.FunctionKeys.KP_Subtract,
      ], e.keyCode)) {
        value -= me._stepSize;
      } elsif (contains([
        keyboard.FunctionKeys.Right, keyboard.FunctionKeys.KP_Right,
        keyboard.FunctionKeys.Up, keyboard.FunctionKeys.KP_Up,
        keyboard.PrintableKeys.Plus, keyboard.FunctionKeys.KP_Add,
      ], e.keyCode)) {
        value += me._stepSize;
      } elsif (contains([keyboard.FunctionKeys.Page_Down, keyboard.FunctionKeys.KP_Page_Down], e.keyCode)) {
        value -= me._pageSize;
      } elsif (contains([keyboard.FunctionKeys.Page_Up, keyboard.FunctionKeys.KP_Page_Up], e.keyCode)) {
        value += me._pageSize;
      } elsif (contains([keyboard.FunctionKeys.Home, keyboard.FunctionKeys.KP_Home], e.keyCode)) {
        value = me._minValue;
      } elsif (contains([keyboard.FunctionKeys.End, keyboard.FunctionKeys.KP_End], e.keyCode)) {
        value = me._maxValue;
      }
      me.setValue(value);
    });
  },

  _dragThumb: func(event)
  {
    if (!me._enabled) {
      return;
    }
    var vr =  me._view._root;
    var viewPosX = vr.canvasToLocal([event.clientX, event.clientY])[0];
    var width = me._size[0];

    if (viewPosX < 0) {
      me.setValue(me._minValue);
    } elsif (viewPosX > width) {
      me.setValue(me._maxValue);
    } else {
      var norm = viewPosX / width;
      var mouseValue = me._minValue + norm * ( me._maxValue - me._minValue);
      if (me._stepSize != 0) {
        mouseValue = math.round(mouseValue / me._stepSize) * me._stepSize;
      }
      me.setValue(mouseValue);
    }
  },

  # return value as its normalised equivalent
  _normValue: func
  {
    var range = me._maxValue - me._minValue;
    var v = math.clamp(me._value, me._minValue, me._maxValue) - me._minValue;
    return v / range;
  }
};
