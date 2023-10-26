# RadioButton.nas : radio button, and group helper
# to manage updating checked state conherently
# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>, Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.widgets.RadioButton = {
  new: func(parent, style = nil, cfg = nil) {
    var m = gui.Widget.new(gui.widgets.RadioButton);
    style = style or canvas.style;
    m._cfg = Config.new(cfg or {});
    m._focus_policy = m.StrongFocus;
    m._checked = 0;
    m.radioGroup = nil;
    m._data = m._cfg.get("data", {});

    m._setView( style.createWidget(parent, m._cfg.get("type", "radio-button"), m._cfg) );

    var radioButtonGroup = m._cfg.get("radioButtonGroup");
    var parentRadio = m._cfg.get("parentRadio", nil);
    var radioButtonGroupClass = m._cfg.get("radioButtonGroupClass");
    if (radioButtonGroup != nil) {
      m.radioGroup = radioButtonGroup;
    } elsif (parentRadio != nil) {
      m.radioGroup = parentRadio.radioGroup;
    } elsif (radioButtonGroupClass != nil) {
      m.radioGroup = radioButtonGroupClass.new();
    } else {
      m.radioGroup = gui.widgets.RadioButtonsGroup.new();
    }
    m.radioGroup.addRadio(m);

    return m;
  },
  # @description Set the data for this radio button.
  # @param key Union[scalar, hash] required If @param key is a hash, this item's data is replaced with that hash.
  #                                                                           If @param key is a scalar, the data field with that name will be set to value.
  #                                                                           If @param key is anything else, an error will be raised.
  # @param value Any optional The value to set the data field with key @param key to, if @param key is a scalar;
  #                                                    otherwise, this argument is ignored.
  # @return canvas.gui.widgets.RadioButton This radio button to support method chaining.
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
  
  # @description Get the data of this radio button.
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
  # @return canvas.gui.widgets.RadioButton This radio button to support method chaining.
  clearData: func {
    me._data = {};
    return me;
  },

  setText: func(text) {
    me._view.setText(me, text);
    return me;
  },

  setChecked: func(checked = 1) {
    if (me._checked == checked) {
      return me;
    }

    me._setRadioGroupSiblingsUnchecked();
    me._trigger("toggled", {checked: checked});
    if (checked) {
    	me._trigger("checked");
    } else {
    	me._trigger("unchecked");
    }
    me._checked = checked;
    me._onStateChange();
    return me;
  },

  _setRadioGroupSiblingsUnchecked: func {
    me.radioGroup._updateChecked(me);
  },

  toggle: func {
    me.setChecked(!me._checked);
    return me;
  },

  _setView: func(view) {
    call(gui.Widget._setView, [view], me);

    var el = view._root;
    el.addEventListener("click", func {
      if (me._enabled) {
        me.setChecked()
      }
    });

    el.addEventListener("drag", func(e) e.stopPropagation());
  },
};

# auto manage radio-button checked state
gui.widgets.RadioButtonsGroup = {
  new: func(name = "unnamed")
  {
    var m = {
      parents: [gui.widgets.RadioButtonsGroup],
      name: name,
      radios: [],
    };
    return m;
  },

  _onRadioToggled: func {
    var checked = me.getCheckedRadio();
    foreach (var radio; me.radios) {
      radio._trigger("group-checked-radio-changed", {checkedRadio: checked});
    }
  },

  addRadio: func(r)
  {
    r.listen("toggled", func me._onRadioToggled());
    append(me.radios, r);
  },

  removeRadio: func(r)
  {
    # XXX should we update some other item to be checked ?
    if (contains(me.radios, r)) {
      var index = find(r, me.radios);
      me.radios = subvec(me.radios, 0, index) ~ subvec(me.radios, index + 1);
    }
  },

  setEnabled: func(enabled = 1)
  {
    foreach (var r; me.radios) {
      r.setEnabled(enabled);
    }
    return me;
  },
  
  getCheckedRadio: func {
    foreach (var radio; me.radios) {
      if (radio._checked) {
        return radio;
      }
    }
    return nil;
  },

  # update check state of all radios in the group
  _updateChecked: func(active)
  {
    foreach (var r; me.radios) {
      if (r != active) {
        r.setChecked(0);
      }
    }
    return me;
  },
};
