# Frame.nas: container with a visual frame around it,
# and optional checkbox / label (usuallt at the top / left)
# to enable / disable it

# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later


gui.widgets.Frame = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.Frame);
    m._cfg = Config.new(cfg);
    # m._focus_policy = m.NoFocus; maybe?
    m._setView( style.createWidget(parent, "frame", m._cfg) );
    m._checkable = cfg.get("checkable", 0);
    m._label = cfg.get("label");
    m._layout = nil;

    m.setLayoutSizeHint([200, 200]);
    m.setLayoutMaximumSize([m._MAX_SIZE, m._MAX_SIZE]);
    return m;
  },
  getContent: func()
  {
    return me._view.content;
  },
  setLabel: func(text)
  {
    me._label = text;
    me._view.update(me);
    return me;
  },
  setCheckable: func(e)
  {
    me._checkable = e;
    me._view.update(me);
    return me;
  },
  setLayout: func(;)
  {
    me._layout = l;
    l.setParent(me);
    return me.update();
  },
  setSize: func
  {
    if( size(arg) == 1 )
      var arg = arg[0];
    var (x,y) = arg;
    me._size = [x,y];
    return me.update();
  },
    # Needs to be called when the size of the content changes.
  update: func()
  {
   # var offset = [ me._content_offset[0] - me._content_pos[0],
    #               me._content_offset[1] - me._content_pos[1] ];
 
    me.getContent().setTranslation(10, 10);
    me.getContent().setSize([me._size[0] - 20, me._size[1] - 20]);

    me._view.update(me);
    me.getContent().update();

    return me;
  },
};