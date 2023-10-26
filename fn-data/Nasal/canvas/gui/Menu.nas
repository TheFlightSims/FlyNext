# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Usage example for the menu, with submenu:
#
# var m = canvas.gui.Menu.new();
# var i1 = m.createItem("Text");
# var i2 = m.createItem("Text 2");
# var sub = canvas.gui.Menu.new();
# var s1 = sub.createItem("Sub", nil);
# var s2 = sub.createItem("Sub", nil);
# i1.setMenu(sub);
# m.setPosition(200, 200);
# m.show();

gui.MenuItem = {
        MenuPosition: {
                Above: 0x0,
                Right: 0x1,
                Below: 0x2,
                Left: 0x4
        },
        # @description Create a new menu item widget
        # @cfg_field text: str Text of the new menu item
        # @cfg_field shortcut: str String representation of the keyboard shortcut for the item
        # @cfg_field cb: callable Function / method to call when the item is clicked
        # @cfg_field icon: str Path of an icon to be displayed (relative to the path in `canvas.style._dir_widgets`)
        # @cfg_field enabled: bool Initial state of the menu item: enabled (1) or disabled (0)
        new: func(parent, style, cfg) {
                var cfg = Config.new(cfg);
                var m = gui.Widget.new(gui.MenuItem);
                m._text = cfg.get("text", "Menu item");
                m._shortcut = cfg.get("shortcut", nil);
                m._cb = cfg.get("cb", nil);
                m._cb_me = cfg.get("cb_me", m);
                m._icon = cfg.get("icon", nil);
                m._enabled = cfg.get("enabled", 1);
                m._menu_position = cfg.get("menu_position", gui.MenuItem.MenuPosition.Right);
                m._hovered = 0;
                m._menu = nil;
                m._parent_menu = nil;
                m._is_menubar_item = 0;
                m._mouseOver = 0;

                m._setView(style.createWidget(parent, cfg.get("type", "menu-item"), cfg));

                m.setLayoutMinimumSize([48, 24]);
                m.setLayoutSizeHint([64, 24]);
                m.setLayoutMaximumSize([1024, 24]);
                
                m.setText(m._text);
                m.setIcon(m._icon);
                m.setShortcut(m._shortcut);
                return m;
        },

        text: func {
                return me._text;
        },

        setMenu: func(menu) {
                menu._parent_item = me;
                menu._canvas_item = me._parent_menu._canvas_item;
                me._menu = menu;

                return me.update();
        },
        
        onClicked: func(e) {
                if (!me._menu and me._cb) {
                        call(me._cb, [e], me._cb_me, var errors = []);
                        if (size(errors)) {
                        	logprint(LOG_ALERT, "Error(s) executing callback for menu item '" ~ me._text ~ "':");
                        	debug.printerror(errors);
                        }
                }
                me._unsetOthersHovered();
                if (me._is_menubar_item and me._enabled) {
                        if (!me._menu.isVisible()) {
                                me._hovered = 1;
                                me.update();
                                var x = e.screenX - e.localX;
                                var y = e.screenY - e.localY;
                                me._showMenu(x, y);
                        } else {
                        	me._hovered = 0;
                        	me.update();
                                me._hideMenu();
                        }
                } elsif (me._parent_menu != nil and me._menu == nil) {
                        me._hovered = 0;
                        me.update();
                        me._parent_menu.hide();
                }
        },

        _unsetOthersHovered: func {
                for (var i = 0; i < me._parent_menu._layout.count(); i += 1) {
                        var item = me._parent_menu._layout.itemAt(i);
                        item._hovered = 0;
                        item.update();
                        if (item._menu != nil) {
                                item._menu.hide();
                        }
                }
        },

        onMouseEnter: func(e) {
                var any_hovered = 0;
                for (var i = 0; i < me._parent_menu._layout.count(); i += 1) {
                        any_hovered |= me._parent_menu._layout.itemAt(i)._hovered;
                }
                me._unsetOthersHovered();
                me._mouseOver = 1;
                if ((!me._is_menubar_item or any_hovered) and me._enabled) {
                        me._hovered = 1;
                        me.update();
                         var x = e.screenX - e.localX;
                        var y = e.screenY - e.localY;
                        me._showMenu(x, y);
                }
        },

        onMouseLeave: func(e) {
                me._mouseOver = 0;
                if (me._menu == nil) {
                        me._hovered = 0;
                }
                me.update();
        },

        removeMenu: func() {
                me._menu = nil;
                return me.update();
        },

        _showMenu: func(x, y) {
                if (me._menu) {
                        var pos = [0, 0];
                        if (me._menu_position == gui.MenuItem.MenuPosition.Right) {
                                pos = [x + me.geometry()[2], y];
                        } elsif (me._menu_position == gui.MenuItem.MenuPosition.Below) {
                                pos = [x, me.geometry()[3] + y];
                        } elsif (me._menu_position == gui.MenuItem.MenuPosition.Above) {
                                pos = [x, y - me._menu.getSize()[1]];
                        } elsif (me._menu_position == gui.MenuItem.MenuPosition.Left) {
                                pos = [x - me._menu.getSize()[0], y];
                        }
                        me._menu.show(pos[0], pos[1]);
                }
        },

        _hideMenu: func {
                if (me._menu) {
                        me._menu.hide(1);
                }
        },

        setEnabled: func(enabled = 1) {
                me._enabled = enabled;
                return me.update();
        },

        setText: func(text) {
                me._text = text;
                me._view.setText(me, text);
                return me.update();
        },
        
        text: func {
                return me._text;
        },

        setShortcut: func(shortcut) {
        	if (!shortcut) {
        		me._keyBinding = nil;
        		return;
        	}
                if (!isstr(shortcut)) {
                        logprint(LOG_ALERT, "Menu.setShortcut: invalid shortcut");
                        return;
                }

                me._keyBinding = KeyBinding.fromShortcut(shortcut, me._cb);
                getDesktop().addKeyBinding(me._keyBinding);
                me._view.setShortcut(me, KeyBinding.repr(me._keyBinding));
                return me.update();
        },

        _setParentMenu: func(m) {
                me._parent_menu = m;
                if (me._parent_menu != nil and me._parent_menu._canvas_item != nil and me._cb != nil) {
                        # fixme: add window-level shortcurt handling
                        # if (me._shortcut != nil) {
	                #         me._parent_menu._canvas_item.bindShortcut(me._shortcut, me._cb);
                        # }
                        if (me._menu != nil) {
                                for (var i = 0; i < me._menu.count(); i += 1) {
                                        me._menu.getItem(i).setCanvasItem(me._parent_menu._canvas_item);
                                }
                        }
                }
        },

        setIcon: func(icon) {
                me._icon = icon;
                me._view.setIcon(me, icon);
                return me.update();
        },

        setCallback: func(cb = nil) {
                me._cb = cb;
                if (me._keyBinding) {
                        me._keyBinding.addBinding(cb);
                }
                return me;
        },

        update: func {
        	if (me._view != nil) {
                	me._view.update(me);
                        me._view._updateLayoutSizes(me);
        	}
                return me;
        },

        _setView: func(view) {
                call(gui.Widget._setView, [view], me);

                var el = view._root;
                el.addEventListener("click", func(e) me.onClicked(e));

                el.addEventListener("mouseenter", func(e) me.onMouseEnter(e));
                el.addEventListener("mouseleave", func(e) me.onMouseLeave(e));
                el.addEventListener("drag", func(e) e.stopPropagation());
        }
};

gui.Menu = {
        new: func(id = nil) {
                var m = gui.Popup.new([100, 60], id);
                m.parents = [gui.Menu] ~ m.parents;
                m.style = style;
                m._parent_item = nil;

                m._canvas = m.createCanvas().setColorBackground(style.getColor("bg_color"));
                m._root = m._canvas.createGroup();
                m._layout = VBoxLayout.new();
                m._layout.setSpacing(0);
                m._canvas_item = nil;
                m.setLayout(m._layout);
                m.hide();

                return m;
        },

        setCanvasItem: func(item) {
                me._canvas_item = item;
                for (var i = 0; i < me._layout.count(); i += 1) {
                        me._layout.itemAt(i)._setParentMenu(me);
                }
        },

        # @description Add the given menu item to the menu (normally a `canvas.gui.MenuItem`, but can be any `canvas.gui.Widget` in theory)
        # @return canvas.gui.Menu Return me to enable method chaining
        addItem: func(item) {
                item._setParentMenu(me);
                me._layout.addItem(item);
                me.setSize(math.max(me._layout.minimumSize()[0], 64), math.max(me._layout.minimumSize()[1], 24));
                return me;
        },

        # @description Create, insert and return a `canvas.gui.MenuItem` with given text and an optional callback, icon and enabled state.
        # @param text: str required Text to display on the menu item
        # @param cb: callable optional Function / method to call when the item is clicked - if no callback is wanted, nil can be used
        # @param cb_me: Union[hash, ghost] optional Object to use for any me references in the callback function (see `call`)
        # @param shortcut: str String representation of the keyboard shortcut for the item 
        # @param icon: str optional Path to the icon (relative to canvas.style._dir_widgets) or nil if none should be displayed
        # @param enabled: bool optional Whether the item should be enabled (1) or disabled (0)
        # @return canvas.gui.MenuItem The item that was created
        createItem: func(text = nil, cb = nil, cb_me = nil, shortcut = nil, icon = nil, enabled = 1) {
                if (text == nil) {
                        die("cannot create a menu item without text");
                }
                var item = gui.MenuItem.new(me._root, me.style, {text: text, cb: cb, cb_me: cb_me, shortcut: shortcut, icon: icon, enabled: enabled});
                me.addItem(item);
                return item;
        },

        # @description Create, insert and return a `canvas.gui.MenuItem with the given text and assign the given submenu to it,
        #                          optionally add the given icon and set the given enabled state
        # @param text: str required Text to display on the menu item
        # @param menu: canvas.gui.Menu Submenu that shall be assigned to the new menu item
        # @param enabled: bool optional Whether the item should be enabled (1) or disabled (0)
        # @return canvas.gui.MenuItem The item that was created
        addMenu: func(text = nil, menu = nil, enabled = 1) {
                if (text == nil) {
                        die("cannot create a menu item without text");
                }
                if (menu == nil) {
                        die("cannot create a submenu item without submenu");
                }
                var item = gui.MenuItem.new(me._root, me.style, {text: text, cb: nil, shortcut: nil, icon: nil, enabled: enabled});
                menu._parent_item = item;
                item.setMenu(menu);
                me.addItem(item);
                return me;
        },

        createMenu: func(text = nil, enabled = 1) {
                if (text == nil) {
                        die("cannot create a submenu item without text");
                }
                var menu = gui.Menu.new();
                var item = gui.MenuItem.new(me._root, me.style, {text: text, cb: nil, shortcut: nil, icon: nil, enabled: enabled});
                menu._parent_item = item;
                item.setMenu(menu);
                me.addItem(item);
                return menu;
        },

        # @description Remove all items from the menu
        # @return canvas.gui.Menu Return me to enable method chaining
        clear: func {
                me._layout.clear();
                return me;
        },

        # @description If `item` is a `canvas.gui.Widget`, remove the given `canvas.gui.Widget` from the menu
        #                         Else assume `item` to be a scalar and try to find an item of the menu that has a `getText` method
        #                         and whose result of calling its `getText` method equals `item` and remove that item
        # @param item: Union[str, canvas.gui.Widget] required The widget or the text of the menu item to remove
        removeItem: func(item) {
                if (isa(item, gui.Widget)) {
                        me._layout.removeItem(item);
                } else {
                        for (var i = 0; i < me._layout.count(); i += 1) {
                                if (me._layout.itemAt(i)["getText"] != nil and me._layout.itemAt(i).getText() == item) {
                                        me._layout.takeAt(i);
                                        return me;
                                }
                        }
                        die("No menu item with given text '" ~ item ~ "' found, could not remove !");
                }
        },

        # @description If `index` is an integer, remove and return the item at the given `index`
        #                         Else assume `item` to be a scalar and try to find an item of the menu that has a `getText` method
        #                         and whose result of calling its `getText` method equals `item` and remove and return that item
        # @param index: Union[int, str] required The index or text of the menu item to remove
        # @return canvas.gui.Widget The item with given text `index` or at the given position `index`
        takeAt: func(index) {
                if (isint(index)) {
                        return me._layout.takeAt(index);
                } else {
                        for (var i = 0; i < me._layout.count(); i += 1) {
                                if (me._layout.itemAt(i)["getText"] != nil and me._layout.itemAt(i).getText() == index) {
                                        return me._layout.takeAt(i);
                                }
                        }
                        die("No menu item with given text '" ~ index ~ "' found, could not remove !");
                }
        },

        # @description Count the items of the menu
        # @return int Number of items
        count: func() {
                return me._layout.count();
        },

        # @description If `index` is an integer, eturn the item at the given `index`
        #                         Else assume `item` to be a scalar and try to find an item of the menu that has a `getText` method
        #                         and whose result of calling its `getText` method equals `item` and eturn that item
        # @param index: Union[int, str] required The index or text of the menu item to return
        # @return canvas.gui.Widget The item with given text `index` or at the given position `index`
        getItem: func(index) {
                if (isint(index)) {
                        return me._layout.itemAt(index);
                } else {
                        for (var i = 0; i < me._layout.count(); i += 1) {
                                if (me._layout.itemAt(i)["getText"] != nil and me._layout.itemAt(i).getText() == index) {
                                        return me._layout.itemAt(i);
                                }
                        }
                        die("No menu item with given text '" ~ index ~ "' found, could not remove !");
                }
        },

        # @description Show the menu, moving it to the position given by `x` and `y` if ´x` and `y` are not nil
        show: func(x = nil, y = nil) {
                if (x != nil and y != nil) {
                        me.setPosition(x, y);
                }
		me._ghost.show();
		me.setInt("z-index", me.get("z-index", gui.STACK_INDEX["always-on-top"]));
		if (me._canvas != nil) {
			me._canvas.update();
		}
		append(gui.open_popups, me);
        },

        # @description Hide the menu (force should only be set to 1 from within the click handler of menu items)
        hide: func(force=0) {
                if (me._parent_item != nil) {
                        if (
                                force or
                                me._parent_item._parent_menu == nil or
                                me._parent_item._parent_menu._view._root._node.getValue("id") != "menu-bar" or
                                me._parent_item._mouseOver == 0
                        ) {
                                me._parent_item._hovered = 0;
                                me._parent_item.update();
                                call(me.parents[1].hide, [], me);
                        }
                } else {
                        call(me.parents[1].hide, [], me);
                }
        },

        # @description Destructor
        del: func() {
                me.hide();
                me.clear();
                me._canvas.del();
        },

        # @description Update the menu and its items
        update: func() {
                me.parents[1].update();
                for (var i = 0; i < me._layout.count(); i += 1) {
                        me._layout.itemAt(i).update();
                }
                return me;
        },
};

