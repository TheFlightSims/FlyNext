# List.nas - a list widget similar to Qt's QListWidget

# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.ListItem = {
        new: func(parent, style = nil, cfg = nil) {
                var m = gui.Widget.new(gui.widgets.ListItem);
                style = style or canvas.style;
                m._cfg = Config.new(cfg or {});
                m._focus_policy = m.NoFocus;
                
                m._data = m._cfg.get("data", {});
                m._text = m._cfg.get("text", "");
                m._selected = m._cfg.get("selected", 0);
                m._list = nil;

                m._setView(style.createWidget(parent, "list-item", m._cfg));
                m._view._updateLayoutSizes(m);

                m.setText(m._text);
                m.setSelected(m._selected);
                m.setLayoutMaximumSize([m._MAX_SIZE, 24]);

                return m;
        },
        
        # @description Set the data for this item.
        # @param key Union[scalar, hash] required If @param key is a hash, this item's data is replaced with that hash.
        #                                                                           If @param key is a scalar, the data field with that name will be set to value.
        #                                                                           If @param key is anything else, an error will be raised.
        # @param value Any optional The value to set the data field with key @param key to, if @param key is a scalar;
        #                                                    otherwise, this argument is ignored.
        # @return canvas.gui.widgets.ListItem This list item to support method chaining.
        setData: func(key, value = nil) {
                if (isscalar(key)) {
                        me._data[key] = value;
                } elsif (ishash(key)) {
                        me._data = key;
                } else {
                        die("cannot set data field with non-scalar key !");
                }
                return me;
        },
        
        # @description Get the data of this item.
        # @param key Union[scalar, nil] The scalar key of the data field to return the value of, or nil to return the whole data.
        # @return Any If @param key is a scalar, the value of the field with key @param key, else the whole data as a hash.
        getData: func(key = nil) {
                if (key != nil) {
                        if (!isscalar(key)) {
                                die("cannot get data field with non-scalar key !")
                        }
                        return me._data[key];
                } else {
                        return me._data;
                }
        },
        
        # @description Clear data
        # @return canvas.gui.widgets.ListItem This list item to support method chaining.
        clearData: func {
                me._data = {};
                return me;
        },
        
        setText: func(text) {
                me._text = text;
                me._view.setText(me, text);
                return me;
        },
        
        getText: func {
                return me._text;
        },
        
        setSelected: func(selected = 1) {
                if (me.getParent() != nil) {
                        me.getParent().setItemSelection(me, selected);
                }
                return me;
        },
        
        getSelected: func {
                return me._selected;
        },
        
        _setSelected: func(selected) {
                if (selected != me._selected) {
                        me._selected = selected;
                        me.update();
                        me._trigger("selection-state-changed", {"selected": selected});
                        if (me._selected) {
                                me._trigger("selected");
                        } else {
                                me._trigger("unselected");
                        }
                }
                return me;
        },
        
        _setView: func(view) {
                call(gui.Widget._setView, [view], me);

                var el = view._root;
                el.addEventListener("click", func me.setSelected());
        },
        
        update: func {
                me._view.update(me);
                return me;
        },
};

gui.widgets.List = {
        new: func(parent, style = nil, cfg = nil) {
                var m = gui.Widget.new(gui.widgets.List);
                m._style = style = style or canvas.style;
                m._cfg = Config.new(cfg or {});
                m._focus_policy = m.NoFocus;

                m._setView(style.createWidget(parent, "list", m._cfg));
                
                m._scroll = gui.widgets.ScrollArea.new(m._view._root, style, {});
                m._scrollLayout = VBoxLayout.new();
                m._scroll.setLayout(m._scrollLayout);
                m._scrollLayout.setSpacing(0);

                m.setLayoutMinimumSize([48, 24]);
                
                return m;
        },
        
        setSize: func {
                if (size(arg) == 1) {
                        var arg = arg[0];
                }
                var (x, y) = arg;
                me._size = [x, y];
                me._scroll.setSize(x, y);
                me._view.setSize(me, x, y);
                return me.update();
        },
        
        _onItemSelectionStateChanged: func {
                var items = me.getSelectedItems();
                me._trigger("selection-changed");
        },
        
        # @description Add the given item to this list.
        # @param item canvas.gui.widgets.ListItem required The item to be added to this list.
        # @return canvas.gui.widgets.List This list to support method chaining.
        addItem: func(item) {
                item.listen("selection-state-changed", func me._onItemSelectionStateChanged());
                item.setAlignment(canvas.AlignTop);
                me._scrollLayout.addItem(item);
                item.setParent(me);
                return me;
        },
        
        # @description Create an item with the given text and optionally the given config.
        # @param text str required Text of the new item.
        # @param cfg hash optional Additional configuration of the item.
        # @return canvas.gui.widgets.ListItem The created list item.
        createItem: func(text, cfg = nil) {
                cfg = cfg or {};
                cfg["text"] = text;
                var item = gui.widgets.ListItem.new(me._scroll.getContent(), me._style, cfg);
                me.addItem(item);
                return item;
        },
        
        # @description Count the items of this list.
        # @return int Number of items in this list.
        count: func {
                return me._scrollLayout.count();
        },
        
        # @description Remove all items from this list.
        # @return canvas.gui.widgets.List This list to support method chaining.
        clear: func {
                me._scrollLayout.clear();
                return me;
        },
        
        # @description Get the item with the given index or text
        # @param text_or_index Union[int, str] required If text_or_index is an integer, the item at index text_or_index is returned.
        #                                                                                    If text_or_index is a string, the item with text == text_or_index is returned.
        # @return canvas.gui.widgets.ListItem The item with the given text or index, or nil if no such item is found.
        getItem: func(text_or_index) {
                if (isint(text_or_index)) {
                        return me._scrollLayout.itemAt(text_or_index);
                } else {
                        for (var i = 0; i < me.count(); i += 1) {
                                if (me._scrollLayout.itemAt(i)._text == text_or_index) {
                                        return me.getItem(i);
                                }
                        }
                }
        },
        
        # @description Find the index of the given item or item with the given text.
        # @param text_or_item Union[str, canvas.gui.widgets.ListItem] required The item or text of the item to return the index of.
        # @return int The index of the given item or item with the given text, or -1 if the given item or no item with the given text is found.
        findItem: func(text_or_item) {
                for (var i = 0; i < me.count(); i += 1) {
                        if (
                                                        (isstr(text_or_item) and me._scrollLayout.itemAt(i)._text == text_or_index) or
                                                        text_or_item == me.getItem(i)
                        ) {
                                return i;
                        }
                }
                return -1;
        },
        
        # @description Find the index of the given item or item with the given data value at the given data key.
        # @param key str required The data key to search for
        # @param .value Any required The data value at the given data key to search for.
        # @return int The index of the item with the given data value at the given data key,
        #                       or -1 if no item with the given data value is found.
        findItemByData: func(key, value) {
                for (var i = 0; i < me.count(); i += 1) {
                        if (me.getItem(i).getData(key) == value) {
                                return i;
                        }
                }
                return -1;
        },
        
        # @description Remove and return the item with the given text or index.
        # @param text_or_item Union[str, int] required The text or index of the item to remove and return
        # @return int The item with the given text or index, or nil if no item with the given text or index is found.
        takeItem: func(text_or_index) {
                var index = text_or_index;
                if (!isint(index)) {
                        index = me.findItem(index);
                        if (index < 0) {
                                return nil;
                        }
                } elsif (index < 0) {
                        return nil;
                }
                return me._scrollLayout.takeAt(index);
        },
        
        # @description Remove the item with the given text or index or given item.
        # @param text_or_index_or_item Union[str, int, canvas.gui.widgets.ListItem] required The text or index of the item, or the item, to remove.
        # @return canvas.gui.widgets.List This list to support method chaining.
        removeItem: func(text_or_index_or_item) {
                if (isscalar(text_or_index_or_item)) {
                        me.takeItem(text_or_index_or_item);
                } else {
                        me._scrollLayout.removeItem(item);
                }
                return me;
        },
        
        # @description Unselect all items of this list.
        # @return canvas.gui.widgets.List This list to support method chaining.
        clearSelection: func {
                for (var i = 0; i < me.count(); i += 1) {
                        me.getItem(i)._selected = 0;
                        me.getItem(i).update();
                }
                return me;
        },
        
        # @description Set the selected state of the item item with the given index or text.
        # @param text_or_index Union[int, str] required If text_or_index is an integer, the item at index text_or_index is returned.
        #                                                                                    If text_or_index is a string, the item with text == text_or_index is returned.
        # @param selected bool optional The selection state of the item, defaults to selected if not given.
        # @return canvas.gui.widgets.List This list to support method chaining.
        setItemSelection: func(text_or_index_or_item, selected = 1) {
                var item = text_or_index_or_item;
                if (typeof(item) == "scalar") {
                        item = me.getItem(text_or_index_or_item);
                        if (!item) {
                                die("no item found with given text or index '" ~ text_or_index_or_item ~ "' found !");
                        }
                }
                me.clearSelection();
                item._setSelected(selected);
                return me;
        },
        
        # @description Get a vector containing all selected items of this list
        # @return vector[canvas.gui.widgets.ListItem] Vector containing the selected items
        getSelectedItems: func {
                var items = [];
                for (var i = 0; i < me.count(); i += 1) {
                        var item = me.getItem(i);
                        if (item._selected) {
                                append(items, item);
                        }
                }
                return items;
        },
        
        update: func {
                me._scroll.update();
                me._view.update(me);
                return me;
        }
}

