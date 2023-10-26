# TabWidget.nas - widget with a tabs bar and a content area which always displays
# exactly one of its tabs

# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

# Usage  example
# var window = canvas.Window.new([300, 300], "dialog");
# var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));
# var root = myCanvas.createGroup();
# var vbox = canvas.VBoxLayout.new();
# myCanvas.setLayout(vbox);
# 
# var tabs = canvas.gui.widgets.TabWidget.new(root, canvas.style, {});
# var tabsContent = tabs.getContent();
# vbox.addItem(tabs);
# 
# var tab1 = canvas.VBoxLayout.new();
# var image1 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setImage("Textures/Splash1.png")
#                 .setFixedSize(128, 128);
# tab1.addItem(image1);
# var text1 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setText("Texture 1");
# tab1.addItem(text1);
# tabs.addTab("tab1", "Texture 1", tab1);
# 
# var tab2 = canvas.VBoxLayout.new();
# var image2 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setImage("Textures/Splash2.png")
#                 .setFixedSize(128, 128);
# tab2.addItem(image2);
# var text2 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setText("Texture 2");
# tab2.addItem(text2);
# tabs.addTab("tab2", "Texture 2", tab2);
# 
# var tab3 = canvas.VBoxLayout.new();
# var image3 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setImage("Textures/Splash3.png")
#                 .setFixedSize(128, 128);
# tab3.addItem(image3);
# var text3 = canvas.gui.widgets.Label.new(tabsContent, canvas.style, {})
#                 .setText("Texture 3");
# tab3.addItem(text3);
# tabs.addTab("tab3", "Texture 3", tab3);

gui.widgets.TabWidgetTabButton = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.Widget.new(gui.widgets.TabWidgetTabButton);
		m._cfg = Config.new(cfg or {});
		m._style = style or canvas.style;
		m._focus_policy = m.StrongFocus;
		m._selected = 0;

		m._setView(m._style.createWidget(parent, "tab-widget-tab-button", m._cfg));
		m._close_button = gui.widgets.Button.new(m._view._root, style, {"type": "tab-button-close-button"})
						.setSize(24, 24)
						.listen("clicked", func(e) {
							m._trigger("close-button-clicked");
						});
		m._close_button._onStateChange();
		return m;
	},
	setText: func(text) {
		me._view.setText(me, text);
		
		return me;
	},
	setSelected: func(selected = 1) {
		if (me._selected == selected) {
			return me;
		}

		me._selected = selected;
		me._trigger("toggled", {selected: selected});
		me.update();
		return me;
	},
	_setView: func(view) {
		call(gui.Widget._setView, [view], me);

		var el = view._root;
		#el.addEventListener("mousedown", func me.dragStart());
		#el.addEventListener("mouseup", func me.dragStop());
		el.addEventListener("click", func me.setSelected());

		el.addEventListener("drag", func(e) { e.stopPropagation() });
		#el.addEventListener("drag", me.drag);
	},
	update: func {
		if (me._cfg.get("tab-closeable")) {
			me._close_button.show();
		} else {
			me._close_button.hide();
		}
		me._view.update(me);
		me._close_button._onStateChange();
	}
};

gui.widgets.TabWidget = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.Widget.new(gui.widgets.TabWidget);
		m._cfg = Config.new(cfg or {});
		m._style = style or canvas.style;
		m._focus_policy = m.NoFocus;
		m._setView(m._style.createWidget(parent, "tab-widget", m._cfg));
		m._layout = VBoxLayout.new();
		m._layout.setCanvas(m._view._root.getCanvas());
		m._layout.setParent(m);
		m._tabBar = HBoxLayout.new();
		m._layout.addItem(m._tabBar);
		m._content = VBoxLayout.new();
		m._layout.addItem(m._content);
		m._currentTab = nil;
		m._currentTabId = nil;
		m._tabs = {};
		m._tabButtons = {};
		m._closeable_tabs = m._cfg.get("tabs-closeable", 0);
		
		m.setLayoutMinimumSize([50, 36]);
		m.setLayoutSizeHint([100, 36]);
		
		return m;
	},
	
	getContent: func {
		return me._view.content;
	},
	
	hasTab: func(id) {
		return me._tabs[id] != nil;
	},
	
	getTab: func(id) {
		if (!me.hasTab(id)) {
			die("tab with id '" ~ id ~ "' does not exist");
		}
		
		return me._tabs[id];
	},
	
	getTabs: func {
		return me._tabs;
	},
	
	addTab: func(id, label, widget) {
		if (me.hasTab(id)) {
			die("cannot add multiple tabs with the same id: " ~ id);
		}
		
		me._tabButtons[id] = gui.widgets.TabWidgetTabButton.new(me._view.tabBar, canvas.style, {
			"tab-closeable": me._cfg.get("tabs-closeable"),
		})
								.setText(label)
								.listen("close-button-clicked", func {
									me.removeTab(id);
								})
								.listen("toggled", func (e) {
									if (e.detail.selected and id != me._currentTabId) {
										me.setCurrentTab(id);
									}
								});
		
		me._tabBar.addItem(me._tabButtons[id]);
		me._tabs[id] = widget;
		me._content.addItem(widget);
		# hack to force a doLayout for each tab
		me.setCurrentTab(id);
		me.setCurrentTab(keys(me._tabs)[0]);
		
		return me;
	},
	
	removeTab: func(id) {
		if (!me.hasTab(id)) {
			die("tab with id '" ~ id ~ "' does not exist");
		}
		
		me._tabs[id].setVisible(0);
		me._content.removeItem(me._tabs[id]);
		delete(me._tabs, id);
		me._tabBar.removeItem(me._tabButtons[id]);
		delete(me._tabButtons, id);
		if (size(keys(me._tabs)) > 0) {
			me.setCurrentTab(keys(me._tabs)[-1]);
		}
		
		return me;
	},
	
	setCurrentTab: func(id) {
		if (!me.hasTab(id)) {
			die("tab with id '" ~ id ~ "' does not exist");
		}
		
		if (me._currentTabId == id) {
			return; # no need to do anything
		}

		if (me._currentTabId and me._tabButtons[me._currentTabId] != nil) {
			me._tabButtons[me._currentTabId].setSelected(0);
		}
		me._tabButtons[id].setSelected();
		foreach (var tabid; keys(me._tabs)) {
			me._tabs[tabid].setVisible(tabid == id);
		}
		me._currentTabId = id;
		me._currentTab = me._tabs[id];
		
		return me.update();
	},
	
	setSize: func {
		if (size(arg) == 1) {
			var arg = arg[0];
		}
		var (x, y) = arg;
		me._size = [x, y];
		return me.update();
	},
	
	# Needs to be called when the size of the content changes.
	update: func() {
		if(me._layout.getParent() == nil) {
			me._layout.setParent(me);
		}
		me._layout.setGeometry([0, 0, me._size[0], me._size[1]]);
		me._tabBar.setGeometry([0, 0, me._size[0], me._view.tabBarHeight]);
		me._content.setGeometry([0, 0, me._size[0], me._size[1] - me._view.tabBarHeight]);
		if (me._currentTab != nil) {
			me._currentTab.setGeometry([0, 0, me._size[0], me._size[1] - me._view.tabBarHeight]);
		}
		me.setLayoutSizeHint(me._size);
		me._view.setSize(me, me._size[0], me._size[1]);
		
		me._view.update(me);

		return me;
	},
};
