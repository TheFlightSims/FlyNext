# Rule.nas : horizontal or vertical dividing line,
# optionally with a text label, eg to name a section
# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later


gui.widgets.HorizontalRule = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.HorizontalRule);
    m._cfg = Config.new(cfg);
    m._focus_policy = m.NoFocus;
    m._setView( style.createWidget(parent, "rule", m._cfg) );

# should ask Style the rule height, not hard-code 1px
    m.setLayoutMinimumSize([16, 2]);
    m.setLayoutSizeHint([m._MAX_SIZE, 2]); # expand to fill
    m.setLayoutMaximumSize([m._MAX_SIZE, 2]);
    return m;
  },
  setText: func(text)
  {
    me._view.setText(me, text);
    return me;
  }
};

gui.widgets.VerticalRule = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.VerticalRule);
    m._cfg = Config.new(cfg);
    m._focus_policy = m.NoFocus;
    m._setView( style.createWidget(parent, "rule", m._cfg) );

# should ask Style the rule height, not hard-code 1px
    m.setLayoutMinimumSize([2, 16]);
    m.setLayoutSizeHint([2, m._MAX_SIZE]); # expand to fill
    m.setLayoutMaximumSize([2, m._MAX_SIZE]);
    return m;
  },
  setText: func(text)
  {
    me._view.setText(me, text);
    return me;
  }
};
