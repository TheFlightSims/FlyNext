var PropertyTreeBrowser = {
        new: func(node = nil) {
                if (node == nil) {
                        node = props.globals.getNode(props.globals.getValue("/sim/gui/dialogs/property-browser/selected"));
                }
                var m = {
                        parents: [PropertyTreeBrowser],
                };
                
                m.resetTitleTimer = maketimer(5, func {
                        m.window.setTitle(m.getWindowTitle(m.propertyTree.getNode()));
                        m.resetTitleTimer.stop();
                });
                m.simulatedTime = 0;
                m.singleShot = 1;
                
                m.window = canvas.Window.new([400, 550], "dialog")
                                                .setTitle(m.getWindowTitle(node))
                                                .set("resize", 1);
                m.window.onClose = func m.onClose();
                m.root = m.window.getCanvas(1)
                                                .set("background", style.getColor("bg_color"))
                                                .createGroup();
                m.layout = VBoxLayout.new();
                m.layout.setContentsMargin(10);
                m.window.setLayout(m.layout);
                
                m.propertyTree = gui.widgets.PropertyTree.new(m.root);
                if (node != nil) {
                        m.propertyTree.setNode(node);
                }
                m.propertyTree._view._root.addEventListener("click", func {
                        props.globals.setValue("/sim/gui/dialogs/property-browser/selected", m.propertyTree.getNode().getPath());
                        m.window.setTitle(m.getWindowTitle(m.propertyTree.getNode()));
                        var selected = m.propertyTree.getSelectedItems();
                        if (!size(selected)) {
                                return;
                        }
                        var node = selected[0].getData("node");
                        if (size(node.getChildren()) == 0) {
                                var value = nil;
                                var type = node.getType();
                                if (type == "BOOL") {
                                        value = node.getBoolValue() ? "true" : "false";
                                        m.window.setTitle("Hint: hold Ctrl while clicking to toggle bool value");
                                        m.resetTitleTimer.restart(5);
                                } elsif (type == "STRING") {
                                        value = node.getValue();
                                } elsif (type == "NONE") {
                                        value = "";
                                } elsif (type != "ALIAS") {
                                        value = node.getValue() ~ "";
                                }
                                m.valueEntry.setText(value);
                        } else {
                                m.window.setTitle(m.getWindowTitle(m.propertyTree.getNode()));
                                m.valueEntry.clear();
                        }
                });
                m.propertyTree.setLayoutSizeHint([m.propertyTree._MAX_SIZE, m.propertyTree._MAX_SIZE]);
                m.layout.addItem(m.propertyTree);
                
                m.showAttrsCheckbox = gui.widgets.CheckBox.new(m.root, canvas.style, {})
                                                .setText("Show attributes and listener count")
                                                .listen("toggled", func(e) {
                                                        m.propertyTree.showAttrs = e.detail.checked;
                                                });
                m.layout.addItem(m.showAttrsCheckbox);
                
                m.valueLayout = HBoxLayout.new();
                m.layout.addItem(m.valueLayout);
                m.valueEntry = gui.widgets.LineEdit.new(m.root, canvas.style, {});
                m.valueLayout.addItem(m.valueEntry);
                m.valueButton = gui.widgets.Button.new(m.root, canvas.style, {})
                                                .setText("Set")
                                                .setFixedSize(50, 28)
                                                .listen("clicked", func {
                                                        var selected = m.propertyTree.getSelectedItems();
                                                        if (size(selected) == 0) {
                                                                return;
                                                        }
                                                        var node = selected[0].getData("node");
                                                        node.setValue(m.valueEntry.text());
                                                });
                m.valueLayout.addItem(m.valueButton);
                
                m.buttonsLayout = HBoxLayout.new();
                m.layout.addItem(m.buttonsLayout);
                
                m.cloneButton = gui.widgets.Button.new(m.root, canvas.style, {})
                                                .setText("Clone")
                                                .listen("clicked", func m.clone());
                m.cloneButton.setAlignment(AlignLeft);
                m.buttonsLayout.addItem(m.cloneButton);
                
                m.closeButton = gui.widgets.Button.new(m.root, canvas.style, {})
                                                .setText("Close")
                                                .listen("clicked", func m.onClose());
                m.closeButton.setAlignment(AlignRight);
                m.buttonsLayout.addItem(m.closeButton);
                
                m.show();
                
                return m;
        },
        
        clone: func {
                PropertyTreeBrowser.new(me.propertyTree.getNode());
        },
        
        onClose: func {
                if (me.window._destroy_on_close) {
                        me.del();
                } else {
                        me.hide();
                }
        },
        
        show: func {
                me.window.show();
                me.propertyTree.show();
        },
        
        hide: func {
                me.propertyTree.hide();
                me.window.hide();
        },
        
        del: func {
                me.resetTitleTimer.stop();
                me.propertyTree.del();
                me.window.del();
        },

        getWindowTitle: func(node) {
                var path = (node == nil ? "/" : node.getPath());
                if (path == "" or path == nil) {
                        path = "/";
                }

                return path ~ " - Property browser";
        },
};
