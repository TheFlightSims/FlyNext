# PropertyWidgets.nas - subclassed canvas widgets that are synced with a property node

# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.PropertyWidget = {
	new: func(base, parent, style = nil, cfg = nil) {
		style = style or canvas.style;
		cfg = cfg or {};
		if (cfg["node"] == nil) {
			die("Missing configuration 'node' field");
		}
		if (!isa(cfg["node"], props.Node)) {
			cfg["node"] = props.globals.getNode(cfg["node"], 1);
		}
		var m = base.new(parent, style, cfg);
		m.parents = [gui.widgets.PropertyWidget] ~ m.parents;
		m._node = cfg["node"];
		m._propertySynced = 1;
		
		return m;
	},
	
	setPropertySynced: func(synced = 1) {
		me._propertySynced = synced;
	},
};

gui.widgets.PropertySwitch = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.Switch, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertySwitch] ~ m.parents;
		
		m.setChecked(m._node.getBoolValue());
		m.listen("toggled", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setBoolValue(int(e.detail.checked));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setChecked(n.getBoolValue());
		}, 1, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyButton = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.Button, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertyButton] ~ m.parents;
		
		m.setChecked(m._node.getBoolValue());
		m.listen("toggled", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setBoolValue(int(e.detail.checked));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setChecked(n.getBoolValue());
		}, 1, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyRadioButtonsGroup = {
	new: func(node, name = "unnamed") {
		if (!isa(node, props.Node)) {
			node = props.globals.getNode(node, 1);
		}
		var m = gui.widgets.RadioButtonsGroup.new(name);
		m.parents = [gui.widgets.PropertyRadioButtonsGroup] ~ m.parents;
		m._node = node;
		m._propertySynced = 1;
		m._ignore_radio_toggles = 0;
		m._nodeListener = setlistener(node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m._ignore_radio_toggles = 1;
			var value = node.getValue();
			foreach (var radio; m.radios) {
				if (value == radio.getData("property-value")) {
					radio.setChecked(1);
				} else {
					radio.setChecked(0);
				}
			}
			m._ignore_radio_toggles = 0;
		});
	},
	
	setPropertySynced: func(synced = 1) {
		me._propertySynced = synced;
	},
	
	_onRadioToggled: func {
		if (me._ignore_radio_toggles) {
			return;
		}
		var checked = me.getCheckedRadio();
		foreach (var radio; me.radios) {
			radio._trigger("group-checked-radio-changed", {checkedRadio: checked});
		}
		if (m._propertySynced) {
			m._node.setValue(checked != nil ? checked.getData("property-value") : nil);
		}
	},
};

gui.widgets.PropertyRadioButton = {
	new: func(parent, style = nil, cfg = nil) {
		cfg = cfg or {};
		if (cfg["node"] == nil) {
			die("Missing configuration 'node' field");
		}
		if (!isa(cfg["node"], props.Node)) {
			cfg["node"] = props.globals.getNode(cfg["node"], 1);
		}
		cfg["radioButtonGroup"] = gui.widgets.PropertyRadioButtonsGroup.new(cfg["node"]);
		
		var m = gui.widgets.PropertyWidget.new(gui.widgets.RadioButton, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertyRadioButton] ~ m.parents;
		
		m.setChecked(m._node.getBoolValue());
		m.listen("toggled", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setBoolValue(int(e.detail.checked));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setChecked(n.getBoolValue());
		}, 1, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyList = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.List, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertyList] ~ m.parents;
		
		if (str(m.findItemByData(m._node.getValue()))) {
			m.setItemSelection(m.findItemByData("property-value", m._node.getValue()));
		}
		m.listen("selection-changed", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setValue(m.getSelectedItems()[0].getData("property-value"));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			if (str(m.findItemByData("property-value", n.getValue()))) {
				m.setItemSelection(m.findItemByData("property-value", n.getValue()));
			}
		}, 1, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyComboBox = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.ComboBox, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertyComboBox] ~ m.parents;
		
		m.setCurrentByValue(m._node.getValue());
		m.listen("selected-item-changed", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setValue(e.detail.value);
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			if (n.getValue() != m._items[m._currentIndex].menuValue) {
				m.setCurrentByValue(n.getValue());
			}
		}, 0, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyLabel = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.Label, parent, style, cfg);
		m._checkable = 1;
		
		m.parents = [gui.widgets.PropertyLabel] ~ m.parents;
		
		m.setText(m._node.getValue());
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setText(n.getValue());
		}, 0, 0);
	},
	
	del: func {
		removelistener(m._listener);
	},
};


gui.widgets.PropertyLineEdit = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.LineEdit, parent, style, cfg);
		m._checkable = 1;
		
		m.parents = [gui.widgets.PropertyLineEdit] ~ m.parents;
		
		m.setText(m._node.getValue());
		m.listen("text-changed", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setValue(m.getText());
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setText(n.getValue());
		}, 0, 0);
	},
	
	del: func {
		removelistener(m._listener);
	},
};

gui.widgets.PropertyCheckBox = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.CheckBox, parent, style, cfg);
		m._checkable = 1;

		m.parents = [gui.widgets.PropertyCheckBox] ~ m.parents;
		
		m.setChecked(m._node.getBoolValue());
		m.listen("toggled", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setBoolValue(int(e.detail.checked));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setChecked(n.getBoolValue());
		}, 0, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertySlider = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.Slider, parent, style, cfg);

		m.parents = [gui.widgets.PropertySlider] ~ m.parents;
		
		m.setValue(m._node.getValue());
		m.listen("value-changed", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setValue(num(e.detail.value));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setValue(n.getValue());
		}, 0, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

gui.widgets.PropertyDial = {
	new: func(parent, style = nil, cfg = nil) {
		var m = gui.widgets.PropertyWidget.new(gui.widgets.Dial, parent, style, cfg);

		m.parents = [gui.widgets.PropertyDial] ~ m.parents;
		
		m.setValue(m._node.getValue());
		m.listen("value-changed", func(e) {
			if (!m._propertySynced) {
				return;
			}
			m._node.setValue(num(e.detail.value));
		});
		m._listener = setlistener(m._node, func(n) {
			if (!m._propertySynced) {
				return;
			}
			m.setValue(n.getValue());
		}, 0, 0);
		
		return m;
	},
	
	del: func {
		removelistener(me._listener);
	},
};

