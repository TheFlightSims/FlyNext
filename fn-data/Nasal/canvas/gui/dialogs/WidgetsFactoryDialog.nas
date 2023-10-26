var WidgetsFactoryDialog = {
	new: func {
		var m = {
			parents: [WidgetsFactoryDialog],
			window: canvas.Window.new([500, 500], "dialog")
		};
		
		m.window.setBool("resize", 1);
		
		m.root = m.window.getCanvas(1)
						.set("background", style.getColor("bg_color"))
						.createGroup();
		m.vbox = VBoxLayout.new();
		m.window.setLayout(m.vbox);
		
		m.menubar = canvas.gui.widgets.MenuBar.new(m.root, canvas.style, {});

		m.fileMenu = m.menubar.createMenu("File");
		m.fileMenu.createItem(text: "Quit", cb: func m.del(), shortcut: "<Ctrl>+Q");
		
		m.tabsMenu = m.menubar.createMenu("Tabs");
		m.tabsMenu.createItem(text: "Select first tab", cb: func m.tabs.setCurrentTab("tab-1"));
		m.tabsMenu.createItem(text: "Select second tab", cb: func m.tabs.setCurrentTab("tab-2"));
		
		m.widgetsMenu = m.menubar.createMenu("Widgets");
		m.widgetsMenu.createItem(text: "Benchmark label", cb: func {
			m.benchmark_widget(canvas.gui.widgets.Label, func(w, i) {
				w.setText("Label " ~ i);
			});
		});
		m.widgetsMenu.createItem(text: "Benchmark slider", cb: func {
			m.benchmark_widget(widget: canvas.gui.widgets.Slider, proc_func: func(w, i) {
				w.setValue(i);
			}, cfg: {
				"value-position": canvas.gui.widgets.Slider.ValuePosition.Below,
				"value-style": canvas.gui.widgets.Slider.ValueStyle.Moving,
				"ticks-position": gui.widgets.Slider.TicksPosition.Below,
			});
		});
		m.widgetsMenu.createItem(text: "Benchmark radio button", cb: func {
			m.benchmark_radio_button(func(w, i) {
				w.setText("Radio button " ~ i);
			});
		});
		m.vbox.addItem(m.menubar);
		
		m.tabs = gui.widgets.TabWidget.new(m.root, style, {"tabs-closeable": 1});
		m.tabsContent = m.tabs.getContent();
		m.vbox.addItem(m.tabs);
		
		m.tab_1 = VBoxLayout.new();
		m.tabs.addTab("tab-1", "Tab 1", m.tab_1);
		m.label = gui.widgets.Label.new(m.tabsContent, style, {})
						.setText("A label")
						.setBackground("#ffaaaa");
		m.tab_1.addItem(m.label);

		var r = gui.widgets.HorizontalRule.new(m.tabsContent, style, {});
		r.setText("Checkboxes!");
		m.tab_1.addItem(r);

		m.checkbox_left = gui.widgets.CheckBox.new(m.tabsContent, style, {})
						.setText("Wanna check something ?");
		m.tab_1.addItem(m.checkbox_left);
		m.checkbox_right = gui.widgets.CheckBox.new(m.tabsContent, style, {"label-position": "left"})
						.setText("Checkbox with text on the left side");
		m.tab_1.addItem(m.checkbox_right);
		m.property_checkbox = gui.widgets.PropertyCheckBox.new(m.tabsContent, style, {
			"node": props.globals.getNode("/controls/lighting/nav-lights"),
		})
						.setText("Nav lights");
		m.tab_1.addItem(m.property_checkbox);
		
		var r2 = gui.widgets.HorizontalRule.new(m.tabsContent, style, {});
		m.tab_1.addItem(r2);
		
		m.radio_label = gui.widgets.Label.new(m.tabsContent, style, {})
						.setText("Selected radio button: none");
		m.tab_1.addItem(m.radio_label);
		m.radio1 = gui.widgets.RadioButton.new(m.tabsContent)
						.setText("Radio button 1");
		m.radio1.listen("group-checked-radio-changed", func(e) {
			m.radio_label.setText("Selected radio button: " ~ (e.detail.checkedRadio != nil ? e.detail.checkedRadio._text : "none"));
		});
		
		m.tab_1.addItem(m.radio1);
		m.radio2 = gui.widgets.RadioButton.new(parent: m.tabsContent, cfg: {parentRadio: m.radio1})
						.setText("Radio button 2");
		m.tab_1.addItem(m.radio2);
		m.radio3 = gui.widgets.RadioButton.new(parent: m.tabsContent, cfg: {parentRadio: m.radio1})
						.setText("Radio button 3");
		m.tab_1.addItem(m.radio3);
		m.radio4 = gui.widgets.RadioButton.new(parent: m.tabsContent, cfg: {parentRadio: m.radio1})
						.setText("Radio button 4");
		m.tab_1.addItem(m.radio4);

		m.tab_2 = HBoxLayout.new();
		m.tabs.addTab("tab-2", "Tab 2", m.tab_2);
		
		m.button_box = VBoxLayout.new();
		m.tab_2.addItem(m.button_box);
		
		m.button = gui.widgets.Button.new(m.tabsContent, style, {})
						.setText("A button")
						.setFixedSize(128, 30)
						.listen("clicked", func {
							InputDialog.getText("You clicked the button …", "Enter some text:", func (button, text) {
								MessageBox.information("You clicked the button …", "… and entered '" ~ (text != nil ? text : "nothing") ~ "' !");
							});
						});
		m.button_box.addItem(m.button);
		m.image = gui.widgets.Label.new(m.tabsContent, style, {})
						.setImage("Textures/Splash1.png")
						.setVisible(0)
						.setFixedSize(128, 128);

		m.button_box.addItem(m.image);
		m.image._view._root.addEventListener("mousedown", func (e) {
			logprint(LOG_INFO, "Image was clicked at:" ~ e.localX ~ "," ~ e.localY);
			logprint(LOG_INFO, "Client pos:" ~ e.clientX ~ "," ~ e.clientY);
			logprint(LOG_INFO, "Screen pos:" ~ e.screenX ~ "," ~ e.screenY);

			var img = m.image._view._root;
			var localPos = [e.localX, e.localY];
			var canvasPos = img.localToCanvas(localPos);

			logprint(LOG_INFO, "computed canvasPos pos:" ~ canvasPos[0] ~ "," ~ canvasPos[1]);

			var screenPos = m.window.toScreenPosition(canvasPos);
			logprint(LOG_INFO, "computed screen pos:" ~ screenPos[0] ~ "," ~ screenPos[1]);
		});

		m.checkable_button = gui.widgets.Button.new(m.tabsContent, style, {})
						.setCheckable(1)
						.setChecked(0)
						.setText("Checkable button")
						.setFixedSize(128, 30)
						.listen("toggled", func (e) {
							m.image.setVisible(int(e.detail.checked));
						});
		m.button_box.addItem(m.checkable_button);

		m.upsize_button = gui.widgets.Button.new(m.tabsContent, style, {})
						.setText("Upsize window")
						.setFixedSize(128, 30)
						.listen("clicked", func {
							var s = m.window.getSize();
							m.window.setSize(s[0] + 100, s[1] + 100);
						});
		m.button_box.addItem(m.upsize_button);
		
		m.downsize_button = gui.widgets.Button.new(m.tabsContent, style, {})
						.setText("Downsize window")
						.setFixedSize(128, 30)
						.listen("clicked", func {
							var s = m.window.getSize();
							m.window.setSize(s[0] - 100, s[1] - 100);
						});
		m.button_box.addItem(m.downsize_button);
		m.combo1 = gui.widgets.ComboBox.new(m.tabsContent, style, {});
		m.combo1.addMenuItem("Apples", 0);
		m.combo1.addMenuItem("Pears", 1);
		m.combo1.addMenuItem("Lemons", 2);
		m.combo1.addMenuItem("Oranges", 3);
		m.combo1.setFixedSize(128, 30);
		m.button_box.addItem(m.combo1);
		
		m.switch_box = HBoxLayout.new();
		m.button_box.addItem(m.switch_box);
		
		m.switch_label = gui.widgets.Label.new(m.tabsContent, style, {})
						.setText("Switch state: on");
		m.switch_box.addItem(m.switch_label);
		m.switch = gui.widgets.Switch.new(m.tabsContent)
						.setChecked(1)
						.listen("toggled", func(e) {
							m.switch_label.setText("Switch state: " ~ (e.detail.checked ? "on" : "off"));
						});
		m.switch_box.addItem(m.switch);
		
		m.list_box = VBoxLayout.new();
		m.tab_2.addItem(m.list_box);
		
		m.list = gui.widgets.List.new(m.tabsContent);
		for (var i = 0; i < 30; i += 1) {
			m.list.createItem("Item " ~ i);
		}
		m.list.listen("selection-changed", func {
			m.list_selection_label.setText("Selected items: " ~ (string.join(", ", std.map(func(item) item._text, m.list.getSelectedItems())) or "none"));
		});
		m.list.setSizeHint([m.list._MAX_SIZE, m.list._MAX_SIZE]);
		m.list_box.addItem(m.list);
		
		m.list_selection_label = gui.widgets.Label.new(m.tabsContent, canvas.style, {})
						.setText("Selected items: none");
		m.list_selection_label.setAlignment(canvas.AlignBottom);
		m.list_box.addItem(m.list_selection_label);
		
		m.benchmark_tab = VBoxLayout.new();
		m.tabs.addTab("benchmark", "Benchmark", m.benchmark_tab);
		m.benchmark_tab_scroll = canvas.gui.widgets.ScrollArea.new(m.tabsContent, canvas.style, {});
		m.benchmark_tab_scroll.setSizeHint([m.list._MAX_SIZE, m.list._MAX_SIZE]);
		m.benchmark_tab_scroll_layout = VBoxLayout.new();
		m.benchmark_tab_scroll_layout.setSpacing(0);
		m.benchmark_tab_scroll.setLayout(m.benchmark_tab_scroll_layout);
		m.benchmark_tab.addItem(m.benchmark_tab_scroll);
		m.benchmark_statistics = canvas.gui.widgets.Label.new(m.tabsContent, canvas.style, {});
		m.benchmark_statistics.setAlignment(canvas.AlignBottom);
		m.benchmark_tab.addItem(m.benchmark_statistics);

		m.numericControlsTab = VBoxLayout.new();
		m.tabs.addTab("numeric-controls", "Numeric controls", m.numericControlsTab);
		m.slider = gui.widgets.Slider.new(m.tabsContent, style, {
				"max-value" : 100,
				"page-size" : 20,
				"tick-step" : 10,
				"value-style": gui.widgets.Slider.ValueStyle.Moving,
				"value-position": gui.widgets.Slider.ValuePosition.Above,
				"ticks-position": gui.widgets.Slider.TicksPosition.Above,
		})
			.setValue(42);
		m.numericControlsTab.addItem(m.slider);
		
		m.dialBox = HBoxLayout.new();
		m.dialBox.setContentsMargin(10);
		m.numericControlsTab.addItem(m.dialBox);
		
		m.dial = gui.widgets.Dial.new(m.tabsContent, style, {
			"min-value": 5,
			"max-value": 50,
			"step-size": 0.5,
			"page-size": 5,
			"tick-step": 2,
			"show-value": 0,
			"show-ticks": 0,
			"value": 14,
			"value-format": "%.1f",
			"wrap": 0,
		});
		m.dialBox.addItem(m.dial);
		
		m.dialOptionsBox =VBoxLayout.new();
		m.dialBox.addItem(m.dialOptionsBox);
		m.dialShowValueCheckBox = gui.widgets.CheckBox.new(m.tabsContent, canvas.style, {})
						.setText("Show value")
						.listen("toggled", func(e) {
							m.dial.setShowValue(e.detail.checked);
						});
		m.dialShowValueCheckBox.setAlignment(canvas.AlignTop);
		m.dialOptionsBox.addItem(m.dialShowValueCheckBox);
		m.dialShowTicksCheckBox = gui.widgets.CheckBox.new(m.tabsContent, canvas.style, {})
						.setText("Show ticks")
						.listen("toggled", func(e) {
							m.dial.setShowTicks(e.detail.checked);
						});
		m.dialShowTicksCheckBox.setAlignment(canvas.AlignTop);
		m.dialOptionsBox.addItem(m.dialShowTicksCheckBox);
		m.dialWrapCheckBox = gui.widgets.CheckBox.new(m.tabsContent, canvas.style, {})
						.setText("Wrap value")
						.listen("toggled", func(e) {
							m.dial.setWrap(e.detail.checked);
						});
		m.dialWrapCheckBox.setAlignment(canvas.AlignTop);
		m.dialOptionsBox.addItem(m.dialWrapCheckBox);


		return m;
	},
	
	benchmark_widget: func(widget, proc_func=nil, amount=50, cfg=nil) {
		cfg = cfg or {};
		var start = systime();
		me.benchmark_tab_scroll_layout.clear();
		for (var i = 0; i < amount; i += 1) {
			var w = widget.new(me.benchmark_tab_scroll.getContent(), canvas.style, cfg);
			if (proc_func != nil) {
				proc_func(w, i);
			}
			me.benchmark_tab_scroll_layout.addItem(w);
		}
		var time = systime() - start;
		me.benchmark_statistics.setText("Took " ~ time ~ " seconds to add " ~ amount ~ " widgets.");
	},
	
	benchmark_radio_button: func(proc_func=nil, amount=50, cfg= nil) {
		cfg = cfg or {};
		var start = systime();
		me.benchmark_tab_scroll_layout.clear();
		var r = canvas.gui.widgets.RadioButton.new(me.benchmark_tab_scroll.getContent());
		cfg["parentRadio"] = r;
		for (var i = 1; i < amount; i += 1) {
			var w = canvas.gui.widgets.RadioButton.new(me.benchmark_tab_scroll.getContent(), canvas.style, cfg);
			if (proc_func != nil) {
				proc_func(w, i);
			}
			me.benchmark_tab_scroll_layout.addItem(w);
		}
		var time = systime() - start;
		me.benchmark_statistics.setText("Took " ~ time ~ " seconds to add " ~ amount ~ " widgets.");
	},
	
	del: func {
		me.property_checkbox.del();
		me.window.del();
	}
};

