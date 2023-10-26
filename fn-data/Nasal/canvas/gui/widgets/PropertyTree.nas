gui.widgets.PropertyTree = {
        AttributeMapping: {
                "archive": "A",
                "alias": "L",
                "preserve": "P",
                "readable": "R",
                "tied": "T",
                "trace-read": "Tr",
                "trace-write": "Tw",
                "userarchive": "U",
                "writable": "W",
        },
        
        new: func(parent, style = nil, cfg = nil) {
                var m = gui.widgets.List.new(parent, style, cfg);
                m.parents = [gui.widgets.PropertyTree] ~ m.parents;
                m.showAttrs = 0;
                m._node = m._cfg.get("node", props.globals);
                m.rebuildList();
                m.listen("selection-changed", func {
                        var selected = m.getSelectedItems();
                        if (!size(selected)) {
                                return;
                        }
                        var node = selected[0].getData("node");
                        if (size(node.getChildren()) > 0) {
                                m.setNode(node);
                        }
                });
                m.updateTimer = maketimer(0, func m.update());
                m.updateTimer.simulatedTime = 0;
                m.updateTimer.start();
                
                return m;
        },
        
        show: func {
                call(me.parents[1].show, [], me);
                me.updateTimer.start();
        },
        
        hide: func {
                call(me.parents[1].hide, [], me);
                me.updateTimer.stop();
        },
        
        getNode: func {
                return me._node;
        },
        
        setNode: func(node) {
                me._node = node;
                me.rebuildList();
                return me;
        },
        
        rebuildList: func {
                me.clear();
                if (me._node.getParent()) {
                        var item = me.createItem("../")
                                                        .setData("node", me._node.getParent());
                }
                foreach (var c; sort(me._node.getChildren(), func(a, b) cmp(a.getName(), b.getName()))) {
                        if (size(c.getChildren())) {
                                var index = c.getIndex();
                                var name = c.getName() ~ (index > 0 ? "[" ~ index ~ "]" : "");

                                var item = me.createItem(name ~ "/");
                        } else {
                                var item = me.createItem("");
                                item._view._root.addEventListener("click", func(e) me.itemClicked(e));
                        }
                        item.setData("node", c);
                }
        },
        
        itemClicked: func(e) {
                if (!e.ctrlKey) {
                        return;
                }
                var selected = me.getSelectedItems();
                if (!size(selected)) {
                        return;
                }
                var node = selected[0].getData("node");
                if (node.getType() == "BOOL") {
                        node.toggleBoolValue();
                }
        },
        
        update: func {
                for (var i = 0; i < me.count(); i += 1) {
                        var item = me.getItem(i);
                        var node = item.getData("node");
                        if (size(node.getChildren()) == 0) {
                                var type = node.getType();
                                var index = node.getIndex();
                                var name = node.getName() ~ (index > 0 ? "[" ~ index ~ "]" : "");
                                var value = nil;
                                if (type == "BOOL") {
                                        value = node.getBoolValue() ? "true" : "false";
                                } elsif (type == "STRING" or type == "UNSPECIFIED") {
                                        value = "'" ~ string.replace(node.getValue(), "\n", "\\n") ~ "'";
                                } elsif (type != "ALIAS" and type != "NONE") {
                                        value = node.getValue() ~ "";
                                }
                                if (value != nil) {
                                        var attrString = "";
                                        if (me.showAttrs) {
                                                attrString ~= " ";
                                                foreach (var attr; sort(keys(me.AttributeMapping), func(a, b) cmp(a, b))) {
                                                        if (node.getAttribute(attr)) {
                                                                attrString ~= me.AttributeMapping[attr];
                                                        }
                                                }
                                                attrString ~= " " ~ node.getAttribute("listeners");
                                        }
                                        item.setText(node.getName() ~ " = " ~ value ~ " (" ~ string.lc(node.getType()) ~ attrString ~ ")");
                                } else {
                                       item.setText(node.getName());
                                }
                        }
                }
                call(me.parents[1].update, [], me);
        },
        
        del: func {
                me.updateTimer.stop();
        },
};

