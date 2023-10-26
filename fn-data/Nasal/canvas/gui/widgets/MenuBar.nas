# MenuBar.nas - a menu bar that can be added as a normal widget to a layout

# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.MenuBar = {
        new: func(parent, style, cfg) {
                var m = gui.Widget.new(gui.widgets.MenuBar);
                m._cfg = Config.new(cfg);
                m._focus_policy = m.NoFocus;

                m._setView(style.createWidget(parent, "menu-bar", m._cfg));

                m._layout = HBoxLayout.new();
                m._layout.setSpacing(0);
                m._layout.setCanvas(m._view._root.getCanvas());
                m.setCanvasItem(parent);

                m.setLayoutMinimumSize([48, 24]);
                m.setLayoutSizeHint([48, 24]);
                m.setLayoutMaximumSize([48, 24]);

                return m;
        },

        setCanvasItem: func(item) {
                me._canvas_item = item;
                for (var i = 0; i < me._layout.count(); i += 1) {
                        me._layout.itemAt(i)._setParentMenu(me);
                }
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
                var item = gui.MenuItem.new(me._view._items, style, 
                        {
                                text: text, cb: nil, shortcut: nil, icon: nil, enabled: enabled,
                                menu_position: gui.MenuItem.MenuPosition.Below,
                        }
                );
                item._is_menubar_item = 1;
                item._setParentMenu(me);
                item.setMenu(menu);
                me._layout.addItem(item);
                me.setSize(math.max(me._layout.minimumSize()[0], 64), math.max(me._layout.minimumSize()[1], 24));
                return me;
        },

        createMenu: func(text = nil, enabled = 1) {
                if (text == nil) {
                        die("cannot create a submenu item without text");
                }
                var menu = gui.Menu.new();
                me.addMenu(text, menu, enabled);
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
        removeMenu: func(item) {
                if (isa(item, gui.Widget)) {
                        me._layout.removeItem(item);
                } else {
                        for (var i = 0; i < me._layout.count(); i += 1) {
                                if (me._layout.itemAt(i)["getText"] != nil and me._layout.itemAt(i).getText() == item) {
                                        me._layout.takeAt(i);
                                        return me;
                                }
                        }
                        die("No menu  with given text '" ~ item ~ "' found, could not remove !");
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
                                        return me._layout.takeAt(i)._menu;
                                }
                        }
                        die("No menu with given text '" ~ index ~ "' found, could not remove !");
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
                                        return me._layout.itemAt(i)._menu;
                                }
                        }
                        die("No menu item with given text '" ~ index ~ "' found, could not remove !");
                }
        },

        getMenu: func(index) {
                return me.getItem(index)._menu;
        },

        setSize: func {
                if (size(arg) == 1) {
                        var arg = arg[0];
                }
                var (x, y) = arg;
                me._size = [x, 24];
                me.setAlignment(0x01 | 0x20);
                return me.update();
        },

        # @description Update the menu and its items
        update: func() {
                if(me._layout.getParent() == nil) {
                        me._layout.setParent(me);
                }

                me._layout.setGeometry([0, 0, me._size[0], me._size[1]]);
                me._view.setSize(me, me._size[0], me._size[1]);
                me._view.update(me);

                return me;
        },
};

