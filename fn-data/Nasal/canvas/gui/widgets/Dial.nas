# Dial.nas : show a user-rotable dial knob
# with optional tick marks and value display
# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.Dial = {
  new: func(parent, style = nil, cfg = nil) {
    style = style or canvas.style;
    var m = gui.Widget.new(gui.widgets.Dial);
    m._cfg = Config.new(cfg or {});
    m._focus_policy = m.StrongFocus;
    m._minValue = m._cfg.get("min-value", 0);
    m._maxValue = m._cfg.get("max-value", 100);
    m._value = m._mouseValue = m._cfg.get("value", 50);
    m._stepSize = m._cfg.get("step-size", 1);
    m._pageSize = m._cfg.get("page-size", 10);
    m._tickStep = m._cfg.get("tick-step", 10);
    m._showTicks = m._cfg.get("show-ticks", 0);
    m._showValue = m._cfg.get("show-value", 1);
    m._valueFormat = m._cfg.get("value-format", nil);
    m._wraps = m._cfg.get("wrap", 0);

    m._handleDown = 0;
    m._lastMouseAngle = 0;
    m._dragging = 0;

    m._setView(style.createWidget(parent, m._cfg.get("type", "dial"), m._cfg));
    m.setValueFormat(m._valueFormat);
    m.setValue(m._value);
    m.setMinValue(m._minValue);
    m.setMaxValue(m._maxValue);
    m.setShowTicks(m._showTicks);
    m.setShowValue(m._showValue);
    m._onStateChange();

    return m;
  },

  setShowTicks: func(showTicks) {
    me._showTicks = showTicks;
    me._view._updateLayoutSizes(me);
    me._onStateChange();
  },

  setShowValue: func(showValue) {
    me._showValue = showValue;
    me._view._updateLayoutSizes(me);
    me._onStateChange();
  },

  setWrap: func(wrap) {
    me._wraps = wrap;
    me._view.setValue(me, me._value);
    me._view._drawTicks(me);
  },

  setSize: func(w, h) {
    var size = math.min(w, h);
    me._size[0] = size;
    me._size[1] = size;

    me._view.setSize(me, size, size);
    return me;
  },

  setValueFormat: func(format) {
    me._valueFormat = format;
    me._view._updateMaxValueWidth(me);
    me._view._updateLayoutSizes(me);
    me.setValue(me._value);
  },

  setValue: func(value) {
    value = math.clamp(value, me._minValue, me._maxValue);
    me._view.setValue(me, value);
    if (me._value != value) {
      me._value = value;
      me._trigger("value-changed", {"value": value});
    }
    return me;
  },

  setMinValue: func(minValue) {
    me._minValue = minValue;
    me._view._updateMaxValueWidth(me);
    me._view._updateLayoutSizes(me);
    me._view._drawTicks(me);
  },

  setMaxValue: func(maxValue) {
    me._maxValue = maxValue;
    me._view._updateMaxValueWidth(me);
    me._view._updateLayoutSizes(me);
    me._view._drawTicks(me);
  },

# protected:
  _setView: func(view) {
    call(gui.Widget._setView, [view], me);

    var el = view._root;
    
    el.addEventListener("drag", func(e) {
      me._dragDial(e);
      e.stopPropagation();
    });
    el.addEventListener("mousedown", func(e) {
      me._handleDown = 1;
      me._dragDial(e);
      me._onStateChange();
    });
    el.addEventListener("mouseup", func(e) {
      me._handleDown = 0;
      me._dragging = 0;
      me._onStateChange();
    });
    el.addEventListener("mouseleave", func(e) {
      me._handleDown = 0;
      me._dragging = 0;
      me._onStateChange();
    });
    el.addEventListener("wheel", func(e) {
      if (!me._enabled) {
        return;
      }

      me.setValue(me._value + e.deltaY * me._stepSize);
      e.stopPropagation();
    });
    el.addEventListener("keydown", func(e) {
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

  _dragDial: func(e) {
    if (!me._enabled) {
      return;
    }
    var vr =  me._view._root;

    var localPos = vr.canvasToLocal([e.clientX - me._size[0] / 2, e.clientY - me._size[1] / 2]);
    var mouseAngle = math.atan2(localPos[0], -localPos[1]) * R2D + 180;
    var deltaAngle = math.periodic(-180, 180, mouseAngle - me._lastMouseAngle);
    me._lastMouseAngle = mouseAngle;
    if (!me._dragging) {
      me._dragging = 1;
      return;
    }
    
    var value = me._mouseValue + (me._maxValue - me._minValue) * (deltaAngle / 360);
    if (!me._wraps) {
      if (value > me._maxValue) {
        value = me._maxValue;
      } elsif (value < me._minValue) {
        value = me._minValue;
      }
    } else {
      value = math.periodic(me._minValue, me._maxValue, value);
    }
    me._mouseValue = value;
    if (me._stepSize != 0) {
      value = math.round(value / me._stepSize) * me._stepSize;
    }
    me.setValue(value);
  },

  # return value as its normalised equivalent
  _normValue: func {
    var range = me._maxValue - me._minValue;
    var v = math.clamp(me._value, me._minValue, me._maxValue) - me._minValue;
    return v / range;
  },
};
