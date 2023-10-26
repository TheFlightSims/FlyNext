# SPDX-FileCopyrightText: (C) 2022 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

gui.Popup = {
	__used_ids: [],
	# Constructor
	#
	# @param size ([width, height])
	new: func(size_, id = nil, parent = nil, take_focus = 0) {
		var ghost = _newWindowGhost(id);
		var m = {
			parents: [gui.Popup, PropertyElement, ghost],
			_ghost: ghost,
			_node: props.wrapNode(ghost._node_ghost),
			_focused: 0,
			_widgets: [],
			_parent: parent,
			_canvas: nil,
			_frame_width: 1,
			_take_focus: take_focus,
		};

		m.setInt("content-size[0]", size_[0]);
		m.setInt("content-size[1]", size_[1]);
		m._updateDecoration();
		
		m.setFocus();

		# arg = [child, listener_node, mode, is_child_event]
		setlistener(m._node, func m._propCallback(arg[0], arg[2]), 0, 2);
		
		return m;
	},
	# Destructor
	del: func {
		me.clearFocus();
		
		if (me["_canvas"] != nil) {
			var placements = me._canvas._node.getChildren("placement");
			# Do not remove canvas if other placements exist
			if (size(placements) > 1) {
				foreach (var p; placements) {
					if (p.getValue("type") == "window" and p.getValue("id") == me.get("id")) {
						p.remove();
					}
				}
			} else {
				me._canvas.del();
			}
			me._canvas = nil;
		}
		if (me._node != nil) {
			me._node.remove();
			me._node = nil;
		}
	},
	# Create the canvas to be used for this Window
	#
	# @return The new canvas
	createCanvas: func() {
		var size = [
			me.get("content-size[0]"),
			me.get("content-size[1]")
		];
		
		me._canvas = new({
			size: [size[0], size[1]],
			view: size,
			placement: {
				type: "window",
				id: me.get("id")
			},
			
			# Standard alpha blending
			"blend-source-rgb": "src-alpha",
			"blend-destination-rgb": "one-minus-src-alpha",
			
			# Just keep current alpha (TODO allow using rgb textures instead of rgba?)
			"blend-source-alpha": "zero",
			"blend-destination-alpha": "one"
		});
		
		me._canvas._focused_widget = nil;
		me._canvas.data("focused", me._focused);
		
		return me._canvas;
	},
	# Set an existing canvas to be used for this Window
	setCanvas: func(canvas_) {
		if (ghosttype(canvas_) != "Canvas") {
			return debug.warn("Not a Canvas");
		}
		
		canvas_.addPlacement({type: "window", "id": me.get("id")});
		me['_canvas'] = canvas_;
		
		canvas_._focused_widget = nil;
		canvas_.data("focused", me._focused);
		
		return me;
	},
	# Get the displayed canvas
	getCanvas: func(create = 0) {
		if (me['_canvas'] == nil and create) {
			me.createCanvas();
		}
		
		return me['_canvas'];
	},
	setLayout: func(l) {
		if (me['_canvas'] == nil) {
			me.createCanvas();
		}
		
		me._canvas.update(); # Ensure placement is applied
		me._ghost.setLayout(l);
		return me;
	},
	#
	setFocus: func {
		if (gui.focused_window != nil and me._take_focus) {
			gui.focused_window.clearFocus();
			gui.focused_window = me;
		}
		
#		me.onFocusIn();
		me._focused = 1;
		me._onStateChange();
		return me;
	},
	#
	clearFocus: func {
#		me.onFocusOut();
		me._focused = 0;
		me._onStateChange();
		if (me._take_focus) {
			if (gui.focused_window == me) {
				gui.focused_window = nil;
			}
			if (me._parent != nil and contains(gui.open_popups, me._parent)) {
				me._parent.setFocus();
			}
		}
		return me;
	},
	setPosition: func {
		if (size(arg) == 1) {
			var arg = arg[0];
		}
		var (x, y) = arg;
		
		me.setInt("tf/t[0]", x);
		me.setInt("tf/t[1]", y);
		return me;
	},
	setSize: func {
		if (size(arg) == 1) {
			var arg = arg[0];
		}
		var (w, h) = arg;
		
		me.set("content-size[0]", w);
		me.set("content-size[1]", h);
		
		if (me.onResize != nil) {
			me.onResize();
		}
		
		return me;
	},
	getSize: func {
		var w = me.get("content-size[0]");
		var h = me.get("content-size[1]");
		return [w,h];
	},
	# Raise to top of window stack
	raise: func() {
		# on writing the z-index the window always is moved to the top of all other
		# windows with the same z-index.
		me.setInt("z-index", me.get("z-index", gui.STACK_INDEX["always-on-top"]));
		
		me.setFocus();
	},
	hide: func(parents = 0) {
		me.clearFocus();
		me._ghost.hide();
		for (var i = 0; i < size(gui.open_popups); i += 1) {
			if (gui.open_popups[i] == me) {
				gui.open_popups = subvec(gui.open_popups, 0, i) ~ subvec(gui.open_popups, i);
				break;
			}
		}
		if (me._parent != nil) {
			me._parent.setFocus();
		}
	},
	show: func() {
		me._ghost.show();
		me.raise();
		if (me._canvas != nil) {
			me._canvas.update();
		}
		for (var i = 0; i < size(gui.open_popups); i += 1) {
			gui.open_popups[i].clearFocus();
		}
		append(gui.open_popups, me);
	},
	# Hide / show the window based on whether it's currently visible
	toggle: func() {
		if (me.isVisible()) {
			me.hide();
		} else {
			me.show();
			me.raise();
		}
	},
	onResize: func() {
		if (me['_canvas'] == nil) {
			return;
		}
		
		for(var i = 0; i < 2; i += 1) {
			var size = me.get("content-size[" ~ i ~ "]");
			me._canvas.set("size[" ~ i ~ "]", size);
			me._canvas.set("view[" ~ i ~ "]", size);
		}
	},
# protected:
	_onStateChange: func {
		var event = canvas.CustomEvent.new("wm.focus-" ~ (me._focused ? "in" : "out"));
		
		if (me.getCanvas() != nil) {
			me.getCanvas().data("focused", me._focused).dispatchEvent(event);
		}
	},
# private:
	#mode 0 = value changed, +-1 add/remove node
	_propCallback: func(child, mode) {
		if (!me._node.equals(child.getParent())) {
			return;
		}
		var name = child.getName();
		
		# support for CSS like position: absolute; with right and/or bottom margin
		if (name == "right") {
			me._handlePositionAbsolute(child, mode, name, 0);
		} elsif (name == "bottom") {
			me._handlePositionAbsolute(child, mode, name, 1);
		}

		if (mode == 0) {
			if (name == "size") {
				me._resizeDecoration();
			}
		}
	},
	_handlePositionAbsolute: func(child, mode, name, index) {
		# mode
		#	 -1 child removed
		#		0 value changed
		#		1 child added

		if (mode == 0) {
			me._updatePos(index, name);
		} elsif (mode == 1) {
			me["_listener_" ~ name] = [
				setlistener(
					"/sim/gui/canvas/size[" ~ index ~ "]",
					func me._updatePos(index, name)
				),
				setlistener(
					me._node.getNode("content-size[" ~ index ~ "]"),
					func me._updatePos(index, name)
				)
			];
		} elsif (mode == -1) {
			for (var i = 0; i < 2; i += 1) {
				removelistener(me["_listener_" ~ name][i]);
			}
		}
	},
	_updatePos: func(index, name) {
		me.setInt(
			"tf/t[" ~ index ~ "]",
			getprop("/sim/gui/canvas/size[" ~ index ~ "]") - me.get(name) - me.get("content-size[" ~ index ~ "]")
		);
	},
	getCanvasDecoration: func() {
		return wrapCanvas(me._getCanvasDecoration());
	},
	_updateDecoration: func() {
		me.set("decoration-border", "1 1 1");
		me.set("shadow-inset", 5);
		me.set("shadow-radius", 2);
		me.setBool("update", 1);

		var canvas_deco = me.getCanvasDecoration();
		canvas_deco.addEventListener("mousedown", func me.raise());
		canvas_deco.set("blend-source-rgb", "src-alpha");
		canvas_deco.set("blend-destination-rgb", "one-minus-src-alpha");
		canvas_deco.set("blend-source-alpha", "one");
		canvas_deco.set("blend-destination-alpha", "one");

		var group_deco = canvas_deco.getGroup("decoration");
		me._frame = group_deco.createChild("path");
		me._frame.set("fill", "none");
		me._frame.set("stroke", "#888888");
		me._frame.set("stroke-width", me._frame_width);

		me._resizeDecoration();
		me._onStateChange();
	},
	_resizeDecoration: func() {
		me._frame.reset()
			.rect(0, 0, me.get("size[0]"), me.get("size[1]"));
	}
};


