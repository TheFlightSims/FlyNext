# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.ComboBox = {
  new: func(parent, style, cfg)
  {
    var cfg = Config.new(cfg);
    var m = gui.Widget.new(gui.widgets.ComboBox);
    m._focus_policy = m.StrongFocus;
#    m._flat = cfg.get("flat", 0);
    m._menu = gui.Menu.new();
    m._setView( style.createWidget(parent, cfg.get("type", "combo-box"), cfg) );
    m._items = [];
    m._currentIndex = nil;
    m._style = style; # cache reference to style for creating items
    m._down = 0;
    
    return m;
  },

  setText: func(text)
  {
    if( me._view != nil )
      me._view.setText(me, text);
    return me;
  },

  show: func()
  {
    # check if enabled
  },

  menu: func()
  {
    return me._menu;
  },

# convenience helper to add simple items
  addMenuItem: func(text, value) {
    var index = size(me._items);
    var m = me;
    var item = me.menu().createItem(text, func { m._itemCallback(index);}, {});
    item.menuValue = value;
    append(me._items, item);
    if (me._currentIndex == nil) {
      # select first item added, if we were previously empty
      me.setCurrentByIndex(0);
    }
  },

# helper to set the current item by passing in
# a value of an item
  setCurrentByValue: func(value) {
    var index = 0;
    foreach(var i; me._items) {
      if (i.menuValue == value) {
        me.setCurrentByIndex(index);
        break;
      }

      index+=1;
    }

    logprint(DEV_WARN, "Canvas.Gui ComboBox: no such value in menu:" ~ value);
  },

  setCurrentByIndex: func(index) {
    if (me._currentIndex == index)
      return;

    if (index >= size(me._items) or index < 0) {
      logprint(DEV_WARN, "Canvas.Gui ComboBox: invalid index passed to setCurrentByIndex" ~ index);
      return;
    }

    me._currentIndex = index;
    me._view.setText(me, me._items[index].text());
    me._trigger("selected-item-changed", {"index": index, "text": me._items[index].text(), "value": me._items[index].menuValue});
  },

  findByValue: func(value) {
    for (var i = 0; i < size(me._items); i += 1) {
      if (me._items[i].menuValue == value) {
        return i;
      }
    }
    return -1;
  },

  findByText: func(text) {
    for (var i = 0; i < size(me._items); i += 1) {
      if (me._items[i].text() == text) {
        return i;
      }
    }
    return -1;
  },

  setDown: func(down = 1)
  {
    if (me._down == down )
      return me;

    me._down = down;
    me._onStateChange();
    return me;
  },

# protected:
  _itemCallback: func(index)
  {
    me._hideMenu();
    me.setCurrentByIndex(index);
  },

  setSize: func {
    if (size(arg) == 1) {
      var arg = arg[0];
    }
    var (x, y) = arg;
    me._size = [x, y];
    me._menu.setSize(x, me._menu.getSize()[1]);
    if (me._view != nil) {
      me._view.setSize(me, x, y);
    }
    return me;
  },

  _setView: func(view)
  {
    call(gui.Widget._setView, [view], me);

    var el = view._root;
    el.addEventListener("click", func(e) {
      if (me._enabled) {
        me.setDown(!me._down);
        if (me._down) {
          me._openMenu(e.screenX - e.localX, e.screenY - e.localY + me._size[1]);
        }
      }
    });
  },

  _openMenu: func(x, y)
  {
    me.menu().setPosition(x, y);
    me.menu().show();
  },
  
  _hideMenu: func {
    me._menu.hide();
    me.setDown(0);
  }
};
