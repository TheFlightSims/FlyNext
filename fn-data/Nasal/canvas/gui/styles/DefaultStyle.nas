var DefaultStyle = {
  new: func(name, name_icon_theme)
  {
    return {
      parents: [ gui.Style.new(name, name_icon_theme),
                 DefaultStyle ]
    };
  },
  createWidget: func(parent, type, cfg)
  {
    var factory = me.widgets[type];
    if( factory == nil )
    {
      debug.warn("DefaultStyle: unknown widget type (" ~ type ~ ")");
      return nil;
    }

    var w = {
      parents: [factory],
      _style: me
    };
    call(factory.new, [parent, cfg], w);
    return w;
  },
  widgets: {}
};

# A button
DefaultStyle.widgets.button = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "button");
    me._bg =
      me._root.createChild("path");
    me._border =
      me._root.createChild("image", "button")
              .set("slice", "10 12"); #"7")
    me._label =
      me._root.createChild("text")
              .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
              .set("character-size", 14)
              .set("alignment", "center-baseline");
  },
  setSize: func(model, w, h)
  {
    me._bg.reset()
          .rect(3, 3, w - 6, h - 6, {"border-radius": 5});
    me._border.setSize(w, h);
  },
  setText: func(model, text)
  {
    me._label.setText(text);

    var min_width = math.max(80, me._label.maxWidth() + 16);
    model.setLayoutMinimumSize([min_width, 16]);
    model.setLayoutSizeHint([min_width, 28]);

    return me;
  },
  update: func(model)
  {
    var backdrop = !model._windowFocus();
    var (w, h) = model._size;
    var file = me._style._dir_widgets ~ "/";

    # TODO unify color names with image names
    var bg_color_name = "button_bg_color";
    if( backdrop )
      bg_color_name = "button_backdrop_bg_color";
    else if( !model._enabled )
      bg_color_name = "button_bg_color_insensitive";
    else if( model._down )
      bg_color_name = "button_bg_color_down";
    else if( model._hover )
      bg_color_name = "button_bg_color_hover";
    me._bg.set("fill", me._style.getColor(bg_color_name));

    if( backdrop )
    {
      file ~= "backdrop-";
      me._label.set("fill", me._style.getColor("backdrop_fg_color"));
    }
    else
      me._label.set("fill", me._style.getColor("fg_color"));
    file ~= "button";

    if( model._down )
    {
      file ~= "-active";
      me._label.setTranslation(w / 2 + 1, h / 2 + 6);
    }
    else
      me._label.setTranslation(w / 2, h / 2 + 5);

    if( model._enabled )
    {
      if( model._focused and !backdrop )
        file ~= "-focused";

      if( model._hover and !model._down )
        file ~= "-hover";
    }
    else
      file ~= "-disabled";

    me._border.set("src", file ~ ".png");
  }
};

# A checkbox
DefaultStyle.widgets.checkbox = {
  new: func(parent, cfg)
  {
    me._label_position = cfg.get("label-position", "right");
    me._root = parent.createChild("group", "checkbox");
    me._icon =
      me._root.createChild("image", "checkbox-icon")
              .setSize(18, 18);
    me._label =
      me._root.createChild("text")
              .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
              .set("character-size", 14)
              .set("alignment", "left-center");
  },
  setSize: func(model, w, h)
  {
    if (me._label_position == "left") {
      me._label.setTranslation(3, int((h / 2) + 1));
      me._icon.setTranslation(w - 24, int((h - 18) / 2));
    } else {
      me._icon.setTranslation(3, int((h - 18) / 2));
      me._label.setTranslation(24, int(h / 2) + 1);
    }

    return me;
  },
  setText: func(model, text)
  {
    me._label.setText(text);

    var min_width = me._label.maxWidth() + 3 + 24;
    model.setLayoutMinimumSize([min_width, 18]);
    model.setLayoutSizeHint([min_width, 24]);

    return me;
  },
  update: func(model)
  {
    var backdrop = !model._windowFocus();
    var (w, h) = model._size;
    var file = me._style._dir_widgets ~ "/";

    if( backdrop )
    {
      file ~= "backdrop-";
      me._label.set("fill", me._style.getColor("backdrop_fg_color"));
    }
    else
      me._label.set("fill", me._style.getColor("fg_color"));
    file ~= "check";

    if( model._down )
      file ~= "-selected";
    else
      file ~= "-unselected";

    if( model._enabled )
    {
      if( model._hover )
        file ~= "-hover";
    }
    else
      file ~= "-disabled";

    me._icon.set("src", file ~ ".png");
  }
};

DefaultStyle.widgets.switch = {
        new: func(parent, cfg) {
                me._root = parent.createChild("group", "switch");
                me._bg = me._root.createChild("path", "switch-background");
                me._thumb = me._root.createChild("path", "switch-thumb");
        },

        setSize: func(model, w, h) {
                me._bg.reset()
                                                .moveTo(w / 4, 0.5)
                                                .arcSmallCCWTo((w - 1) / 4, (h - 1) / 2, 0, w / 4, h - 0.5)
                                                .horiz(w / 2)
                                                .arcSmallCCWTo((w - 1) / 4, (h - 1) / 2, 0, w / 4 * 3, 0.5)
                                                .close();
                me._thumb.reset()
                                                .ellipse((w - 1) / 4, (h - 1) / 2, w / 4, h / 2);
        },

        update:  func(model) {
                var bg_color = "switch_bg_color";
                if (model._down) {
                        bg_color ~= "_checked";
                } elsif (!model._enabled) {
                        bg_color ~= "_disabled";
                }
                me._bg.set("fill", me._style.getColor(bg_color));
                me._bg.set("stroke", me._style.getColor("switch_bg_border_color"));
                me._thumb.set("fill", me._style.getColor("switch_thumb_color"));
                me._thumb.set("stroke", me._style.getColor("switch_thumb_border_color"));
                me._thumb.setTranslation(model._down * 24, 0);
        },
};

# A checkbox
DefaultStyle.widgets["radio-button"] = {
  new: func(parent, cfg) {
    me._root = parent.createChild("group", "radio-button");
    me._bg = me._root.createChild("path");
    me._icon = me._root.createChild("group", "radio-button-icon");
    me._icon_background = me._icon.createChild("path", "radio-button-icon-border")
            .circle(8.5, 9, 9);
    me._icon_selected_indicator = me._icon.createChild("path", "radio-button-icon-selected-indicator")
            .circle(6, 9, 9)
            .set("stroke-width", 5);
    me._icon_border = me._icon.createChild("path", "radio-button-icon-border")
            .circle(8, 9, 9)
            .set("stroke-width", 1);
    me._label = me._root.createChild("text")
            .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
            .set("character-size", 14)
            .set("alignment", "left-center");
  },
  setSize: func(model, w, h) {
    me._bg.reset().rect(0, 0, w, h);
    me._icon.setTranslation(3, int((h - 18) / 2));
    me._label.setTranslation(24, int(h / 2) + 1);

    return me;
  },
  setText: func(model, text) {
    me._label.setText(text);

    var min_width = me._label.maxWidth() + 3 + 24;
    model.setLayoutMinimumSize([min_width, 24]);
    model.setLayoutSizeHint([min_width, 24]);

    return me;
  },
  update: func(model) {
    var backdrop = !model._windowFocus();
    
    me._bg.set("fill", me._style.getColor("radio_button_bg_color" ~ (model._hover ? "_hovered" : "")));

    me._icon_border.set("stroke", me._style.getColor("radio_button_selected_indicator_border_color"));
    if (backdrop) {
      me._label.set("fill", me._style.getColor("backdrop_fg_color"));
    } else {
      me._label.set("fill", me._style.getColor("fg_color"));
    }

    if (model._checked) {
      me._icon_selected_indicator.show();
    } else {
      me._icon_selected_indicator.hide();
    }

    if (model._enabled) {
      if (model._hover) {
        me._icon_background.set("fill", me._style.getColor("radio_button_selected_indicator_bg_color_hovered"));
      } else {
        me._icon_background.set("fill", me._style.getColor("radio_button_selected_indicator_bg_color"));
      }
      me._icon_selected_indicator.set("stroke", me._style.getColor("radio_button_selected_indicator_color"));
    } else {
      me._icon_background.set("fill", me._style.getColor("radio_button_selected_indicator_bg_color_disabled"));
      me._icon_selected_indicator.set("stroke", me._style.getColor("radio_button_selected_indicator_color_disabled"));
    }
  }
};

# A label
DefaultStyle.widgets.label = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "label");
  },
  setSize: func(model, w, h)
  {
    if( me['_bg'] != nil )
      me._bg.reset().rect(0, 0, w, h);
    if( me['_img'] != nil )
      me._img.set("size[0]", w)
             .set("size[1]", h);
    if( me['_text'] != nil )
    {
      # TODO different alignment
      me._text.setTranslation(2, 2 + h / 2);
      me._text.set(
        "max-width",
        model._cfg.get("wordWrap", 0) ? (w - 4) : 0
      );
    }
    return me;
  },
  setText: func(model, text)
  {
    if ( !isstr(text) or size(text) == 0 )
    {
      model.setHeightForWidthFunc(nil);
      return me._deleteElement('text');
    }

    me._createElement("text", "text")
      .setText(text);

    var hfw_func = nil;
    var min_width = me._text.maxWidth() + 4;
    var width_hint = min_width;

    if( model._cfg.get("wordWrap", 0) )
    {
      var m = me;
      hfw_func = func(w) m.heightForWidth(w);
      min_width = math.min(32, min_width);

      # prefer approximately quadratic text blocks
      if( width_hint > 24 )
        width_hint = int(math.sqrt(width_hint * 24));
    }

    model.setHeightForWidthFunc(hfw_func);
    model.setLayoutMinimumSize([min_width, 14]);
    model.setLayoutSizeHint([width_hint, 24]);

    return me.update(model);
  },
  setImage: func(model, img)
  {
    if( img == nil or size(img) == 0 )
      return me._deleteElement('img');

    me._createElement("img", "image")
      .set("src", img)
      .set("preserveAspectRatio", "xMidYMid slice");

    return me;
  },
  # @param bg CSS color or 'none'
  setBackground: func(model, bg)
  {
    if( bg == nil or bg == "none" )
      return me._deleteElement("bg");

    me._createElement("bg", "path")
      .set("fill", bg);

    me.setSize(model, model._size[0], model._size[1]);
    return me;
  },
  heightForWidth: func(w)
  {
    if( me['_text'] == nil )
      return -1;

    return math.max(14, me._text.heightForWidth(w - 4));
  },
  update: func(model)
  {
    if( me['_text'] != nil )
    {
      var color_name = model._windowFocus() ? "fg_color" : "backdrop_fg_color";
      me._text.set("fill", me._style.getColor(color_name));
    }
  },
# protected:
  _createElement: func(name, type)
  {
    var mem = '_' ~ name;
    if( me[ mem ] == nil )
    {
      me[ mem ] = me._root.createChild(type, "label-" ~ name);

      if( type == "text" )
      {
         me[ mem ].set("font", "LiberationFonts/LiberationSans-Regular.ttf")
                  .set("character-size", 14)
                  .set("alignment", "left-center");
      }
    }
    return me[ mem ];
  },
  _deleteElement: func(name)
  {
    name = '_' ~ name;
    if( me[ name ] != nil )
    {
      me[ name ].del();
      me[ name ] = nil;
    }
    return me;
  }
};

# A one line text input field
DefaultStyle.widgets["line-edit"] = {
  new: func(parent, cfg)
  {
    me._hpadding = cfg.get("hpadding", 8);

    me._root = parent.createChild("group", "line-edit");
    me._border =
      me._root.createChild("image", "border")
              .set("slice", "10 12"); #"7")
    me._text =
      me._root.createChild("text", "input")
              .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
              .set("character-size", 14)
              .set("alignment", "left-baseline")
              .set("clip-frame", Element.PARENT);
    me._selection = me._root.createChild("path", "selection")
              .set("clip-frame", Element.PARENT)
              .set("fill", "#3333ff");
    me._selected_text = me._root.createChild("text", "selected-text")
              .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
              .set("character-size", 14)
              .set("alignment", "left-baseline")
              .set("clip-frame", Element.PARENT)
              .set("fill", "#ffffff");
    me._cursor =
      me._root.createChild("path", "cursor")
              .set("stroke", "#333")
              .set("stroke-width", 1)
              .moveTo(me._hpadding, 5)
              .vert(10);
    me._hscroll = 0;
    me._cursor_blink = 1;
    me._cursor_blink_timer = maketimer(0.5, func {
      me._cursor_blink = !me._cursor_blink;
      me._cursor.setVisible(me._cursor_visible and me._cursor_blink);
    });
    me._cursor_blink_timer.simulatedTime = 0;
    me._cursor_blink_timer.start();
  },
  setSize: func(model, w, h)
  {
    me._border.setSize(w, h);
    me._text.set(
      "clip",
      "rect(0, " ~ (w - me._hpadding) ~ ", " ~ h ~ ", " ~ me._hpadding ~ ")"
    );
    me._selected_text.set(
      "clip",
      "rect(0, " ~ (w - me._hpadding) ~ ", " ~ h ~ ", " ~ me._hpadding ~ ")"
    );
    me._selection.set(
      "clip",
      "rect(0, " ~ (w - me._hpadding) ~ ", " ~ h ~ ", " ~ me._hpadding ~ ")"
    );
    me._cursor.setDouble("coord[2]", h - 10);

    return me.update(model);
  },
  setText: func(model, text)
  {
    me._text.setText(text);
    model._onStateChange();
  },
  update: func(model)
  {
    var backdrop = !model._windowFocus();
    var file = me._style._dir_widgets ~ "/";

    if( backdrop )
      file ~= "backdrop-";

    file ~= "entry";

    if( !model._enabled )
      file ~= "-disabled";
    else if( model._focused and !backdrop )
      file ~= "-focused";

    me._border.set("src", file ~ ".png");

    var color_name = backdrop ? "backdrop_fg_color" : "fg_color";
    me._text.set("fill", me._style.getColor(color_name));
    me._selected_text.set("fill", me._style.getColor("text_color_selected"));
    me._selection.set("fill", me._style.getColor((backdrop ? "backdrop_" : "") ~ "text_color_bg_selected"));

    me._cursor_visible = model._enabled and model._focused and !backdrop and model._selection_start == model._selection_end;
    me._cursor.setVisible(me._cursor_visible and me._cursor_blink);
    me._selection.reset()
            .moveTo(me._text.getCursorPos(0, model._selection_start)[0], 0)
            .vert(16)
            .horizTo(me._text.getCursorPos(0, model._selection_end)[0])
            .vert(-16);
    me._selected_text.setText(model.selectedText());

    var width = model._size[0] - 2 * me._hpadding;
    var cursor_pos = me._text.getCursorPos(0, model._cursor)[0];
    var text_width = me._text.getCursorPos(0, me._text.lineLength(0))[0];

    if( text_width <= width )
      # fit -> align left (TODO handle different alignment)
      me._hscroll = 0;
    else if( me._hscroll + cursor_pos > width )
      # does not fit, cursor to the right
      me._hscroll = width - cursor_pos;
    else if( me._hscroll + cursor_pos < 0 )
      # does not fit, cursor to the left
      me._hscroll = -cursor_pos;
    else if( me._hscroll + text_width < width )
      # does not fit, limit scroll to align with right side
      me._hscroll = width - text_width;

    var text_pos = me._hscroll + me._hpadding;

    me._text
      .setTranslation(text_pos, model._size[1] / 2 + 5)
      .update();
    me._cursor
      .setDouble("coord[0]", text_pos + cursor_pos)
      .update();
    me._selection.setTranslation(text_pos, model._size[1] / 2 - 8)
            .update();
    me._selected_text.setTranslation(text_pos + me._text.getCursorPos(0, model._selection_start)[0], model._size[1] / 2 + 5)
            .update();
  }
};

# ScrollArea
DefaultStyle.widgets["scroll-area"] = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "scroll-area");

    me._bg     = me._root.createChild("path", "background")
                         .set("fill", "#e0e0e0");
    me.content = me._root.createChild("group", "scroll-content")
                         .set("clip-frame", Element.PARENT);
    me.vert  = me._newScroll(me._root, "vert");
    me.horiz = me._newScroll(me._root, "horiz");
  },
  setColorBackground: func
  {
    if( size(arg) == 1 )
    	  var arg = arg[0];
    	me._bg.setColorFill(arg);
  },
  update: func(model)
  {
    me.horiz.reset();
    if( model._max_scroll[0] > 1 )
      # only show scroll bar if horizontally scrollable
      me.horiz.moveTo( model._scroller_offset[0] + model._scroller_pos[0],
                       model._size[1] - 2 )
              .horiz(model._scroller_size[0]);

    me.vert.reset();
    if( model._max_scroll[1] > 1 )
      # only show scroll bar if vertically scrollable
      me.vert.moveTo( model._size[0] - 2,
                      model._scroller_offset[1] + model._scroller_pos[1] )
             .vert(model._scroller_size[1]);

    me._bg.reset()
          .rect(0, 0, model._size[0], model._size[1]);
    me.content.set(
      "clip",
      "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)"
    );
  },
# private:
  _newScroll: func(el, orient)
  {
    return el.createChild("path", "scroll-" ~ orient)
             .set("stroke", "#f07845")
             .set("stroke-width", 4);
  },
  # Calculate size and limits of scroller
  #
  # @param model
  # @param dir 0 for horizontal, 1 for vertical
  # @return [scroller_size, min_pos, max_pos]
  _updateScrollMetrics: func(model, dir)
  {
    if( model._content_size[dir] <= model._size[dir] )
      return;

    model._scroller_size[dir] =
      math.max(
        12,
        model._size[dir] * (model._size[dir] / model._content_size[dir])
      );
    model._scroller_offset[dir] = 0;
    model._scroller_delta[dir] = model._size[dir] - model._scroller_size[dir];
  }
};

DefaultStyle.widgets["tab-widget"] = {
	tabBarHeight: 36,
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "tab-widget");
		me.bg = me._root.createChild("path", "background")
					.set("fill", "#e0e0e0");
		me.tabBar = me._root.createChild("group", "tab-widget-tabbar");
		me.content = me._root.createChild("group", "tab-widget-content");
	},
	
	update: func(model) {
		me.bg.set("fill", me._style.getColor("bg_color"));
		me.tabBar.update();
		me.content.update();
	},
	
	setSize: func(model, w, h) {
		me.bg.reset().rect(0, w, h, 0);
		me.content.setTranslation(0, me.tabBarHeight);
	},
};

# Tab button for the tab widget
DefaultStyle.widgets["tab-widget-tab-button"] = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "tab-widget-tab-button");
		me._bg = me._root.createChild("path")
						.set("fill", me._style.getColor("tab_widget_tab_button_bg_focused"))
						.set("stroke", me._style.getColor("tab_widget_tab_button_border"))
						.set("stroke-width", 1);
		me._selected_indicator = me._root.createChild("path")
						.set("stroke-width", 4);
		me._label = me._root.createChild("text")
						.set("font", "LiberationFonts/LiberationSans-Regular.ttf")
						.set("character-size", 14)
						.set("alignment", "center-baseline");
	},
	
	setSize: func(model, w, h) {
		me._bg.reset().rect(3, 0, w - 6, h);
		me._selected_indicator.reset().moveTo(3, h - 2).horiz(w - 6);
		me._label.setTranslation((w - 24 - 8) / 2, h / 2 + 5);
		model._close_button.move(w - 24 - 8, h / 2 - 12);
	},
	
	setText: func(model, text) {
		me._label.setText(text);

		var min_width = math.max(80, me._label.maxWidth() + 12 + (model._cfg.get("tab-closeable") ? 24 + 12 : 0));
		model.setLayoutMinimumSize([min_width, 36]);
		model.setLayoutSizeHint([min_width, 36]);

		return me;
	},
	
	update: func(model) {
		var backdrop = !model._windowFocus();
		var (w, h) = model._size;
		
		var bg_color_name = "tab_widget_tab_button_bg_focused";
		if (backdrop) {
			bg_color_name = "tab_widget_tab_button_bg_unfocused";
		} else if (model._selected) {
			bg_color_name = "tab_widget_tab_button_bg_selected";
		} else if (model._hover) {
			bg_color_name = "tab_widget_tab_button_bg_hovered";
		}
		me._bg.set("fill", me._style.getColor(bg_color_name));
		
		me._selected_indicator.setVisible(model._selected or model._hover);
		var selected_indicator_color_name = "tab_widget_tab_button_selected_indicator_selected";
		if (!model._selected and model._hover) {
			selected_indicator_color_name = "tab_widget_tab_button_selected_indicator_unselected_hovered";
		}
		me._selected_indicator.set("stroke", me._style.getColor(selected_indicator_color_name));

		me._label.set("fill", me._style.getColor((backdrop ? "backdrop_" : "") ~ "fg_color"));
	}
};

DefaultStyle.widgets["tab-button-close-button"] = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "button");
		me._bg = me._root.createChild("path");
		me._border = me._root.createChild("image", "button")
						.set("slice", "10 12"); #"7")
		me._cross = me._root.createChild("text")
						.set("font", "LiberationFonts/LiberationSans-Regular.ttf")
						.set("character-size", 21)
						.set("alignment", "center-baseline")
						.setText("×");
	},
	setSize: func(model, w, h) {
		me._bg.reset().rect(3, 3, w - 6, h - 6, {"border-radius": 5});
		me._border.setSize(w, h);
		me._cross.setTranslation(w / 2, h / 2 + 7);
	},
	update: func(model) {
		var backdrop = !model._windowFocus();
		var file = me._style._dir_widgets ~ "/";

		# TODO unify color names with image names
		var bg_color_name = "button_bg_color";
		if (backdrop) {
			bg_color_name = "button_backdrop_bg_color";
		} elsif (model._down) {
			bg_color_name = "button_bg_color_down";
		} elsif (model._hover) {
			bg_color_name = "button_bg_color_hover";
		}
		me._bg.set("fill", me._style.getColor(bg_color_name));

		if (model._hover or model._down) {
			me._cross.set("fill", me._style.getColor("fg_color"));
			me._border.show();
			me._bg.show();
		} else {
			me._cross.set("fill", me._style.getColor("backdrop_fg_color"));
			me._border.hide();
			me._bg.hide();
		}
		if (backdrop) {
			file ~= "backdrop-";
		}
		file ~= "button";

		if (model._down) {
			file ~= "-active";
		}

		if (model._focused and !backdrop) {
			file ~= "-focused";
		}
		if (model._hover and !model._down) {
			file ~= "-hover";
		}
		me._border.set("src", file ~ ".png");
	}
};

# A horizontal or vertical rule line
# possibly with a text label embedded
DefaultStyle.widgets.rule = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "rule");
    var bgColor = me._style.getColor("fg_color");
    var shadowColor = me._style.getColor("fg_color_shadow");

    me._bg = me._root.createChild("path")
						.set("fill", bgColor)
						.set("stroke", bgColor)
						.set("stroke-width", 1);
    me._shadow = me._root.createChild("path")
						.set("fill", shadowColor)
						.set("stroke", shadowColor)
						.set("stroke-width", 1);

    me._isVertical = cfg.get("isVertical");
  },
  setSize: func(model, w, h)
  {
    var firstWidth = w;
    var firstHeight = h;
    var hh = h * 0.5;
    
    if( me['_text'] != nil )
    {
      firstHeight = firstWidth = 20; # TODO make this settable in Style.xml
      
      # TODO handle eliding for translations?
      me._text.setTranslation(firstWidth + 3, hh);
      var maxW = model._cfg.get("maxTextWidth", -1);
      if (maxW > 0) {
         me._text.set("max-width", maxW);
      }

      # assume horizontal for now, with a label
      var bg2Left = maxW > 0 ? maxW : me._text.maxWidth() + 22;
      var bg2Width = w - bg2Left;
      me._bg2.reset().rect(bg2Left, hh - 1, bg2Width, 2);
      me._shadow2.reset().moveTo(bg2Left + 1, hh).horiz(bg2Width - 1);
    }

    if (me._isVertical ) {
      me._bg.reset().rect(0, 0, 2, firstHeight);
      me._shadow.reset().moveTo(1, 1).vert(firstHeight - 1);
    } else {
      me._bg.reset().rect(0, hh - 1, firstWidth, 2);
      me._shadow.reset().moveTo(1, hh).horiz(firstWidth - 1);
    }

    return me;
  },
  setText: func(model, text)
  {
    if( text == nil or size(text) == 0 )
    {
      # force a resize?
      me._deleteElement('bg2');
      me._deleteElement('shadow2');
      return me._deleteElement('text');
    }

    if (me._isVertical) {
      logprint(LOG_DEVALERT, "Text label not supported for vertical rules, yet");
      return;
    }

    me._createElement("text", "text")
      .setText(text);

    var width_hint =  me._text.maxWidth() + 40;


    var bgColor = me._style.getColor("fg_color");
    var shadowColor = me._style.getColor("fg_color_shadow");

    me._bg2 = me._root.createChild("path")
						.set("fill", bgColor)
						.set("stroke", bgColor)
						.set("stroke-width", 1);
    me._shadow2 = me._root.createChild("path")
						.set("fill", shadowColor)
						.set("stroke", shadowColor)
						.set("stroke-width", 1);

    model.setLayoutMinimumSize([40, 14]);
    # TODO mark as expanding?
    model.setLayoutSizeHint([width_hint, 24]);

    return me.update(model);
  },
  update: func(model)
  {

    # different color if disabled?
    if( me['_text'] != nil )
    {
      var color_name = model._windowFocus() ? "fg_color" : "backdrop_fg_color";
      me._text.set("fill", me._style.getColor(color_name));
    }
  },
# protected:
  _createElement: func(name, type)
  {
    var mem = '_' ~ name;
    if( me[ mem ] == nil )
    {
      me[ mem ] = me._root.createChild(type, "rule-" ~ name);

      if( type == "text" )
      {
         me[ mem ].set("font", "LiberationFonts/LiberationSans-Regular.ttf")
                  .set("character-size", 14)
                  .set("alignment", "left-center");
      }
    }
    return me[ mem ];
  },
  _deleteElement: func(name)
  {
    name = '_' ~ name;
    if( me[ name ] != nil )
    {
      me[ name ].del();
      me[ name ] = nil;
    }
    return me;
  }
};

# a frame (sometimes called a group box), with optional label
# and enable/disable checkbox
DefaultStyle.widgets.frame = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "frame-box");
    me._createElement("bg", "image")
       .set("slice", "8 8");
    me.content = me._root.createChild("group", "frame-content");

    # handle label + checkable flag
  },

  update: func(model)
  {
    var file = me._style._dir_widgets ~ "/";
    file ~= "frame";

#    if( !model._enabled )
 #     file ~= "-disabled";

    me._bg.set("src", file ~ ".png");
    
    me._bg.setSize(model._size[0], model._size[1]);
  },
  # protected:
  _createElement: func(name, type)
  {
    var mem = '_' ~ name;
    if( me[ mem ] == nil )
    {
      me[ mem ] = me._root.createChild(type, "frame-" ~ name);

      if( type == "text" )
      {
         me[ mem ].set("font", "LiberationFonts/LiberationSans-Regular.ttf")
                  .set("character-size", 14)
                  .set("alignment", "left-center");
      }
    }
    return me[ mem ];
  },
  _deleteElement: func(name)
  {
    name = '_' ~ name;
    if( me[ name ] != nil )
    {
      me[ name ].del();
      me[ name ] = nil;
    }
    return me;
  }

};

# a horizontal or vertical slider, for selecting /
# dragging over a numerical range
DefaultStyle.widgets.slider = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "slider");
    me._createElement("bg", "image")
       .set("slice", "2 6");

    me._createElement("fill", "image")
       .set("slice", "2 6");

    me._ticks = me._root.createChild("path")
            .set("stroke-width", me._style.getSize("slider-ticks-width", 1));

    me._fillHeight = me._fill.imageSize()[1];
    me._createElement("thumb", "image");
    me._thumbSize = me._thumb.imageSize();

    me._value = me._root.createChild("text")
            .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
            .set("character-size", me._style.getSize("slider-value-font-size", me._style.getSize("base-font-size")))
            .set("alignment", "center-top");
  },

  _updateLayoutSizes: func(model) {
  	me.update(model);
    var h = me._thumb.imageSize()[1] + 6;
    if (model._valueDisplayPosition != model.ValuePosition.None) {
      h += me._style.getSize("slider-value-font-size", me._style.getSize("base-font-size")) +
               me._style.getSize("slider-thumb-value-margin", 8);
    }
    if (model._ticksPosition != model.TicksPosition.None and model._valueDisplayPosition != model._ticksPosition) {
      h += me._style.getSize("slider-fill-ticks-margin", 3) + me._style.getSize("slider-tick-length", 10);
    } 
    model.setLayoutMinimumSize([50, h]);
    model.setLayoutSizeHint([(model._maxValue -  model._minValue) / (model._stepSize or 1), h]);
    model.setLayoutMaximumSize([model._MAX_SIZE, h]);
  },

  setNormValue: func(model, normValue)
  {
    var w = model._size[0];
    var halfThumbWidth =  me._thumbSize[0] * 0.5;
    var availWidthPos = w - me._thumbSize[0];
    var thumbX = math.round(availWidthPos * normValue);

    var valueX = 0;
    if (model._valueDisplayStyle == model.ValueStyle.Moving) {
      var startPos = me._value.maxWidth() / 2;
      var thumbPos = thumbX + me._thumbSize[0] * 0.5;
      var endPos = w - (me._value.maxWidth() / 2);
      valueX = math.clamp(thumbPos, startPos, endPos);
    } elsif (model._valueDisplayStyle == model.ValueStyle.Fixed) {
      valueX = w / 2;
    }
    me._value.setTranslation(valueX, me._value.getTranslation()[1]);
    me._thumb.setTranslation(thumbX, me._thumb.getTranslation()[1]);
    me._fill.setSize(thumbX, me._fillHeight);
    me._fill.setTranslation(halfThumbWidth, me._fill.getTranslation()[1]);
    me._value.setText(model._value);
  },

  update: func(model)
  {
    var direction = "horizontal";
  # set background state
    var file = me._style._dir_widgets ~ "/";
    file ~= "scale-" ~ direction ~ "-trough";
    if( !model._enabled )
      file ~= "-disabled";

    me._bg.set("src", file ~ ".png");
    
  # fill state
    var file = me._style._dir_widgets ~ "/";
    file ~= "scale-" ~ direction ~ "-fill";
    if( !model._enabled ) {
      file ~= "-disabled";
    } else {
 
    }

    me._fill.set("src", file ~ ".png");
    me._fillHeight = me._fill.imageSize()[1];

  # set thumb state
    file = me._style._dir_widgets ~ "/";
    file ~= "slider-" ~ direction;  
    if( !model._enabled ) {
      file ~= "-disabled";
    } else {
      if (model._thumbDown)
        file ~= "-focused";
      if (model._hover)
        file ~= "-hover";
    }

    me._thumb.set("src", file ~ ".png");
    me._thumbSize = me._thumb.imageSize();
    
    var color_name = model._windowFocus() ? "fg_color" : "backdrop_fg_color";
    me._value.set("fill", me._style.getColor(color_name));
    if (model._valueDisplayPosition != model.ValuePosition.None) {
      me._value.show();
    } else {
      me._value.hide();
    }
    
    me._ticks.set("stroke", me._style.getColor("slider_ticks"));
    if (model._ticksPosition != model.TicksPosition.None) {
      me._ticks.show();
    } else {
      me._ticks.hide();
    }

  # update the position as well, since other stuff
  # may have changed
    me.setNormValue(model, model._normValue());
  },

  setSize: func(model, w, h)
  {
    var valueFontSize = me._style.getSize("slider-value-font-size", me._style.getSize("base-font-size"));
    var thumbValueMargin = me._style.getSize("slider-thumb-value-margin", 8);
    var fillTicksMargin = me._style.getSize("slider-fill-ticks-margin", 3);
    var ticksOffset = fillTicksMargin + me._style.getSize("slider-tick-length", 10);

    var thumbY = (h - me._thumbSize[1]) * 0.5;
    if (model._valueDisplayPosition != model.ValuePosition.None) {
      thumbY -= (valueFontSize + thumbValueMargin) * 0.5;
    }
    if (model._ticksPosition != model.TicksPosition.None and model._ticksPosition != model._valueDisplayPosition) {
      thumbY -= ticksOffset * 0.5;
    }

    var valueY = thumbY;
    if (model._valueDisplayPosition == model.ValuePosition.Above) {
      thumbY += valueFontSize + thumbValueMargin;
    } elsif (model._valueDisplayPosition == model.ValuePosition.Below) {
      valueY += me._thumbSize[1] + thumbValueMargin;
    }

    var fillY = thumbY + (me._thumbSize[1] - me._fillHeight) * 0.5;

    var ticksY = fillY;
    if (model._ticksPosition == model.TicksPosition.Below) {
      ticksY += me._fillHeight + fillTicksMargin;
    } elsif (model._ticksPosition == model.TicksPosition.Above) {
      if (model._valueDisplayPosition == model.ValuePosition.Below) {
        thumbY += ticksOffset;
        fillY += ticksOffset;
        valueY += ticksOffset;
      } else {
        ticksY -= ticksOffset;
      }
    }

    me._bg.setTranslation(me._thumbSize[0] / 2, fillY);
    me._fill.setTranslation(me._fill.getTranslation()[0], fillY);
    me._ticks.setTranslation(me._thumbSize[0] / 2, ticksY);
    me._thumb.setTranslation(me._thumb.getTranslation()[0], thumbY);
    me._value.setTranslation(me._value.getTranslation()[0], valueY);
    me._bg.setSize(w - me._thumbSize[0], me._fillHeight);
    me.setNormValue(model, model._normValue());
    me._drawTicks(model);
  },

  _drawTicks: func(model) {
    me._ticks.reset();
    var range = model._maxValue - model._minValue;
    if (range <= 0 or model._tickStep <= 0) {
      return;
    }
    var availWidthPos = model._size[0] - me._thumbSize[0];
    var pixelsPerUnit = availWidthPos / range;
    var remainder = math.mod(range, model._tickStep);
    var numTicks = int((range - remainder) / model._tickStep);
    if (remainder == 0) {
      numTicks -= 1;
    }
    for (var i = 1; i <= numTicks; i += 1) {
      me._ticks.moveTo(i * pixelsPerUnit * model._tickStep, 0)
                       .vert(me._style.getSize("slider-tick-length", 8));
    }
  },

   # protected:
  _createElement: func(name, type)
  {
    var mem = '_' ~ name;
    if( me[ mem ] == nil )
    {
      me[ mem ] = me._root.createChild(type, "slider-" ~ name);

      if( type == "text" )
      {
         me[ mem ].set("font", "LiberationFonts/LiberationSans-Regular.ttf")
                  .set("character-size", me._style.getSize("slider-value-font-size", me._style.getSize("base-font-size")))
                  .set("alignment", "left-center");
      }
    }
    return me[ mem ];
  },
  _deleteElement: func(name)
  {
    name = '_' ~ name;
    if( me[ name ] != nil )
    {
      me[ name ].del();
      me[ name ] = nil;
    }
    return me;
  }
};

DefaultStyle.widgets.dial = {
  new: func(parent, cfg) {
    me._root = parent.createChild("group", "dial");
    me._knob = me._root.createChild("path", "dial-knob");
    me._handle = me._root.createChild("image", "dial-handle");
    me._handleTranslateTransform = me._handle.createTransform();
    me._value = me._root.createChild("text", "dial-value")
            .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
            .set("character-size", me._style.getSize("dial-value-font-size", me._style.getSize("base-font-size", 14)))
            .set("alignment", "center-center")
            .setText(0);
    me._ticks = me._root.createChild("path", "dial-ticks");

    me._maxValueWidth = 20;
  },

  _updateLayoutSizes: func(model) {
    var handleSize = me._handle.imageSize()[1];
    var borderHandleMargin = math.clamp(
      math.min(model._size[0], model._size[1]) * 0.0625,
      2,
      me._style.getSize("dial-border-handle-margin", 8),
    );
    var valueSize = [0, 0];
    var valueHandleMargin = me._style.getSize("dial-value-handle-margin", 5);
    if (model._showValue) {
      valueSize = [
        me._maxValueWidth + valueHandleMargin * 2,
        me._style.getSize("dial-value-font-size", me._style.getSize("base-font-size", 14)) + valueHandleMargin * 2
      ];
    } else {
      valueSize = me._style.getSize("dial-center-handle-margin", 2) * 2;
      valueSize = [valueSize, valueSize];
    }
    var minW = borderHandleMargin * 2 + valueSize[0] + handleSize * 2;
    var minH = borderHandleMargin * 2 + valueSize[1] + handleSize * 2;
    var length = math.max(minW, minH);
    if (model._showTicks) {
      length += me._style.getSize("dial-knob-ticks-margin", 2) + me._style.getSize("dial-ticks-length", 10);
    }
    model.setLayoutMinimumSize([length, length]);
  },

  setSize: func(model, length) {
    var knobTicksMargin = me._style.getSize("dial-knob-ticks-margin", 2);
    var ticksLength = me._style.getSize("dial-ticks-length", 10);
    var knobRadius = (length - me._style.getSize("dial-knob-border-width", 1)) / 2;
    var halfLength = length / 2;
    if (model._showTicks) {
      knobRadius -= knobTicksMargin + ticksLength;
    }
    me._knob.reset()
            .circle(knobRadius, halfLength, halfLength);
    me._value.setTranslation(
      halfLength,
      halfLength
    );
    var handleOffset = [
      halfLength - me._handle.imageSize()[0] / 2,
      math.clamp(knobRadius * 0.125, 2, me._style.getSize("dial-border-handle-margin", 8))
    ];
    if (model._showTicks) {
      handleOffset[1] += knobTicksMargin + ticksLength;
    }
    me._handleTranslateTransform.setTranslation(handleOffset[0], handleOffset[1]);
    me._handle.setCenter(
      me._handle.imageSize()[0] / 2,
      halfLength - handleOffset[1]
    );
    var degreesRange = 360;
    var nowrapMargin = me._style.getSize("dial-nowrap-margin-deg", 30); 
    var offset = 0;
    if (!model._wraps) {
      degreesRange -= nowrapMargin;
      offset = nowrapMargin / 2;
    }
    me._handle.setRotation((model._normValue() * degreesRange + offset) * D2R);
    me._drawTicks(model);
  },

  _drawTicks: func(model) {
    var length = math.min(model._size[0], model._size[1]);
    var halfLength = length / 2;
    var knobTicksMargin = me._style.getSize("dial-knob-ticks-margin", 2);
    var ticksLength = me._style.getSize("dial-ticks-length", 10);
    var knobRadius = (length - me._style.getSize("dial-knob-border-width", 1)) / 2 - knobTicksMargin - ticksLength;
    
    var degreesRange = 360;
    var nowrapMargin = me._style.getSize("dial-nowrap-margin-deg", 30);
    var offset = 0;
    if (!model._wraps) {
      degreesRange -= nowrapMargin;
      offset = nowrapMargin / 2;
    }
    var range = model._maxValue - model._minValue;
    var center = [halfLength, halfLength];
    var degreesPerTickStep = (degreesRange / range) * model._tickStep;
    var lengthBegin = knobRadius + knobTicksMargin;
    var lengthEnd = lengthBegin + ticksLength;
    me._ticks.reset();

    for (var i = 0; i < degreesRange / degreesPerTickStep; i += 1) {
      var radians = (i * degreesPerTickStep + offset) * D2R;
      var sin = math.sin(radians);
      var cos = -math.cos(radians);
      var start = [center[0] + sin * lengthBegin, center[1] + cos * lengthBegin];
      var tick = [center[0] + sin * lengthEnd, center[1] + cos * lengthEnd];
      me._ticks.moveTo(start[0], start[1]).lineTo(tick[0], tick[1]);
    }
  },

  _updateMaxValueWidth: func(model) {
    if (model._valueFormat != nil) {
      me._value.setText(sprintf(model._valueFormat, model._minValue));
      var min = me._value.maxWidth();
      me._value.setText(sprintf(model._valueFormat, model._maxValue));
      var max = me._value.maxWidth();
      me._value.setText(sprintf(model._valueFormat, model._minValue + model._stepSize));
      var minStep = me._value.maxWidth();
      me._value.setText(sprintf(model._valueFormat, model._value));
    } else {
      me._value.setText(model._minValue);
      var min = me._value.maxWidth();
      me._value.setText(model._maxValue);
      var max = me._value.maxWidth();
      me._value.setText(model._minValue + model._stepSize);
      var minStep = me._value.maxWidth();
      me._value.setText(model._value);
    }
    me._maxValueWidth = math.max(min, max, minStep);
  },

  setValue: func(model, value) {
    var degreesRange = 360;
    var nowrapMargin = me._style.getSize("dial-nowrap-margin-deg", 30); 
    var offset = 0;
    if (!model._wraps) {
      degreesRange -= nowrapMargin;
      offset = nowrapMargin / 2;
    }
    me._handle.setRotation((model._normValue() * degreesRange + offset) * D2R);
    if (model._valueFormat != nil) {
      me._value.setText(sprintf(model._valueFormat, value));
    } else {
      me._value.setText(value);
    }
  },

  update: func(model) {
    var color_name = model._windowFocus() ? "fg_color" : "backdrop_fg_color";
    me._value.set("fill", me._style.getColor(color_name));

    color_name = "dial_knob_bg";
    if (!model._enabled) {
      color_name ~= "_disabled";
    } elsif (model._focused and model._windowFocus()) {
      color_name ~= "_focused";
    } elsif (!model._windowFocus()) {
      color_name ~= "_backdrop";
    }
    if (model._hover and model._enabled and model._windowFocus()) {
      color_name ~= "_hovered";
    }
    me._knob.set("fill", me._style.getColor(color_name));
    
    color_name = "dial_knob_border";
    if (!model._enabled) {
      color_name ~= "_disabled";
    } elsif (model._focused and model._windowFocus()) {
      color_name ~= "_focused";
    }
    if (model._hover and model._enabled and model._windowFocus()) {
      color_name ~= "_hovered";
    }
    me._knob.set("stroke", me._style.getColor(color_name));
    
    var file = me._style._dir_widgets ~ "/dial-handle";
    if (!model._enabled) {
      file ~= "-disabled";
    } elsif (model._handleDown) {
      file ~= "-down";
    }
    me._handle.set("src", file ~ ".png");

    me._ticks.set("stroke", me._style.getColor("dial_ticks"));

    if (model._showValue) {
      me._value.show();
    } else {
      me._value.hide();
    }
    if (model._showTicks) {
      me._ticks.show();
    } else {
      me._ticks.hide();
    }
  }
};

DefaultStyle.widgets["menu-item"] = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "menu-item");
		me._bg = me._root.createChild("path");
		
		me._icon = me._root.createChild("image")
						.set("slice", "18 18");
		
		me._label = me._root.createChild("text")
						.set("font", "LiberationFonts/LiberationSans-Regular.ttf")
						.set("character-size", 14)
						.set("alignment", "left-baseline");
		
		me._shortcut = me._root.createChild("text")
						.set("font", "LiberationFonts/LiberationSans-Regular.ttf")
						.set("character-size", 14)
						.set("alignment", "right-baseline");
		
		me._submenu_indicator = me._root.createChild("path")
						.vert(12).line(6, -7).close();
	},
	
	setSize: func(model, w, h) {
		me._bg.reset().rect(0, 0, w, h);
		var offset = 0;
		if (!model._is_menubar_item) {
			offset += 5 + 18;
		}
		me._icon.setTranslation(5, int((h - 12) / 2));
		me._label.setTranslation(offset + 5, int(h / 2) + 4);
		me._shortcut.setTranslation(w - 5, int(h / 2) + 4);
		me._submenu_indicator.setTranslation(w - 12, int((h - 12) / 2));
		return me;
	},
	
	_updateLayoutSizes: func(model) {
		var min_width = 5 + me._label.maxWidth() + 5;
		if (!model._is_menubar_item) {
			# add icon space
			min_width += 5 + 18;
			# add shortcut space
			min_width += me._shortcut.maxWidth() + 10;
			if (model._menu != nil) {
				# add submenu indicator space
				min_width += 12;
			}
		}
		model.setLayoutMinimumSize([min_width, 24]);
		model.setLayoutSizeHint([min_width, 24]);
		
		return me;
	},
	
	setText: func(model, text) {
		me._label.setText(text);
		return me._updateLayoutSizes(model);
	},
	
	setShortcut: func(model, shortcut) {
    if (shortcut != nil) {
  		me._shortcut.setText(shortcut);
    }
		return me._updateLayoutSizes(model);
	},
	
	setIcon: func(model, icon) {
		if (!icon) {
			me._icon.hide();
		} else {
			me._icon.show();
			var file = me._style._dir_widgets ~ "/" ~ icon;
			me._icon.set("src", file);
		}
		return me;
	},
	
	update: func(model) {
		me._bg.set("fill", me._style.getColor("menu_item_bg" ~ (model._hovered ? "_hovered" : "")));
		var text_color_name = "menu_item_fg";
		if (model._hovered) {
			text_color_name ~= "_hovered";
		} else if (!model._enabled) {
			text_color_name ~= "_disabled";
		}
		me._label.set("fill", me._style.getColor(text_color_name));
		me._shortcut.set("fill", me._style.getColor(text_color_name));
		me._submenu_indicator.set("fill", me._style.getColor("menu_item_submenu_indicator" ~ (model._hovered ? "_hovered" : "")));
		if (model._menu != nil) {
			if (!model._is_menubar_item) {
				me._submenu_indicator.show();
			}
			me._shortcut.hide();
		} else {
			me._submenu_indicator.hide();
			me._shortcut.show();
		}
		
		return me;
	}
};

DefaultStyle.widgets["menu-bar"] = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "menu-bar");
		me._bg = me._root.createChild("path");
		me._items = me._root.createChild("group", "menu-bar-items");
	},
	
	setSize: func(model, w, h) {
		me._bg.reset().rect(0, 0, w, 24);
		me._items.setTranslation(0, 0);
		return me;
	},
	
	update: func(model) {
		me._bg.set("fill", me._style.getColor("bg_color"));
		
		return me;
	}
};

# A combo-box
DefaultStyle.widgets["combo-box"] = {
  new: func(parent, cfg)
  {
    me._root = parent.createChild("group", "combo-box");
    me._bg =
      me._root.createChild("path");
    me._border =
      me._root.createChild("image", "border")
              .set("slice", "10 6"); #"7")
    me._buttonBorder =
      me._root.createChild("image", "border-button")
              .set("slice", "10 6"); #"7")
    me._arrowIcon = me._root.createChild("image", "arrow");
    me._label =
      me._root.createChild("text")
              .set("font", "LiberationFonts/LiberationSans-Regular.ttf")
              .set("character-size", 14)
              .set("alignment", "left-center");
  },
  setSize: func(model, w, h)
  {
    var halfWidth = int(w * 0.5);
    var m = me._style.getSize("margin");
    var inset = me._style.getSize("text-inset");

    me._bg.reset()
          .rect(m, m, w - (m * 2), h - (m * 2), {"border-radius": me._style.getSize("frame-radius")});

    # we split the two pieces
    me._border.setSize(halfWidth, h);
    me._buttonBorder.setTranslation(halfWidth, 0);
    me._buttonBorder.setSize(w - halfWidth, h);

    var arrowSize = me._arrowIcon.imageSize();
    me._arrowIcon.setTranslation(w - (arrowSize[0] + inset), (h - arrowSize[1]) * 0.5);

    me._label.setTranslation(inset, h * 0.5);
  },
  setText: func(model, text)
  {
    me._label.setText(text);
    var inset = me._style.getSize("text-inset");
    var min_width = math.max(80, me._label.maxWidth() + inset + me._arrowIcon.imageSize()[0]);
    model.setLayoutMinimumSize([min_width, 16]);
    model.setLayoutSizeHint([min_width, 28]);

    return me;
  },
  update: func(model)
  {
    var backdrop = !model._windowFocus();
    var (w, h) = model._size;
    var file = me._style._dir_widgets ~ "/";

    # TODO unify color names with image names
    var bg_color_name = "button_bg_color";
    if( backdrop )
      bg_color_name = "button_backdrop_bg_color";
    else if( !model._enabled )
      bg_color_name = "button_bg_color_insensitive";
    else if( model._down )
      bg_color_name = "button_bg_color_down";
    else if( model._hover )
      bg_color_name = "button_bg_color_hover";
    me._bg.set("fill", me._style.getColor(bg_color_name));

    var arrowIconFile = file ~ "combobox-arrow";

    if( backdrop )
    {
      file ~= "backdrop-";
      me._label.set("fill", me._style.getColor("backdrop_fg_color"));
    }
    else
      me._label.set("fill", me._style.getColor("fg_color"));
    file ~= "combobox";

    var buttonFile = file ~ "-button";
    file ~= "-entry";

    var suffix = "";
    if( model._down )
    { # no pressed image for the left half
      buttonFile ~= "-pressed";
    }

    if( model._enabled ) {
      if( model._focused and !backdrop )
        suffix ~= "-focused";
    } else {
      suffix ~= "-disabled";
      arrowIconFile ~= "-disabled";
    }

    me._border.set("src", file ~ suffix ~ ".png");
    me._buttonBorder.set("src", buttonFile ~ suffix ~ ".png");
    me._arrowIcon.set("src", arrowIconFile ~ ".png");
  }
};

DefaultStyle.widgets["list-item"] = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "list-item");
		me._bg = me._root.createChild("path");
		me._itemHeight = me._style.getSize("list-item-height");

		me._label = me._root.createChild("text")
						.set("font", "LiberationFonts/LiberationSans-Regular.ttf")
						.set("character-size", me._style.getSize("list-font-size"))
						.set("alignment", "left-baseline");
	},
	
	setSize: func(model, w, h) {
		me._bg.reset().rect(0, 0, w, me._itemHeight);
    var m = me._style.getSize("margin");
		me._label.setTranslation(m, int(h / 2) + m);
		return me;
	},
	
	_updateLayoutSizes: func(model) {
    var m = me._style.getSize("margin");
		var min_width = m + me._label.maxWidth() + m;
		model.setLayoutMinimumSize([min_width, me._itemHeight]);
		model.setLayoutSizeHint([min_width, me._itemHeight]);
		model.setLayoutMaximumSize([model._MAX_SIZE, me._itemHeight]);
		
		return me;
	},
	
	setText: func(model, text) {
		me._label.setText(text);
		return me._updateLayoutSizes(model);
	},
	
	update: func(model) {
		me._bg.set("fill", me._style.getColor("list_item_bg" ~ (model._selected ? "_selected" : "")));
		var text_color_name = "list_item_fg";
		if (model._selected) {
			text_color_name ~= "_selected";
		}
		me._label.set("fill", me._style.getColor(text_color_name));
		
		return me;
	}
};

DefaultStyle.widgets.list = {
	new: func(parent, cfg) {
		me._root = parent.createChild("group", "list");
		me._bg = me._root.createChild("path");
	},
	
	setSize: func(model, w, h) {
		me._bg.reset().rect(0, 0, w, h);
		return me;
	},
	
	update: func(model) {
		me._bg.set("fill", me._style.getColor("bg_color"));
		
		return me;
	},

  _updateLayoutSizes: func(model) {
      model.setLayoutMinimumSize([me._itemHeight * 2, me._itemHeight]);
      model.setLayoutMaximumSize([model._MAX_SIZE, me._itemHeight]);
  }
};

