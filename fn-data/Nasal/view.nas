##
## view.nas
##
##  Nasal code for implementing view-specific functionality.

# ATTENTION:
# /sim/current-view/view-number is in the range 0..viewCount, it is NOT
# the index used in aircraft XML files (e.g. <view n="100">).
#
# For the latter, use /sim/current-view/view-number-raw.

# For debugging. Returns string containing description of <x>.
#
var str = func(x, prefix='') {
    prefix = '';
    var ret = '';
    ret = ret ~ prefix ~ typeof(x) ~ ':';
    if (typeof(x) == "hash") {
        ret = ret ~ '{';
        #prefix = prefix ~ '    ';
        foreach(var key; keys(x)){
            ret = ret ~ prefix ~ " '" ~ key ~ "'" ~ ':';
            ret = ret ~ str(x[key], prefix ~ '    ');
        }
        ret = ret ~ '}'
    }
    else {
        ret = ret ~ sprintf('%s', x);
    }
    return ret;
}

var index = nil;    # current view index
var indices = {};   # view_index -> number
var views = nil;    # list of all view branches (/sim/view[n]) as props.Node
var current = nil;  # current view branch (e.g. /sim/view[1]) as props.Node
var fovProp = nil;

var setView = func(n) {
    setprop("/sim/current-view/view-number", n);

    # We install a listener for /sim/current-view/view-number which also sets
    # /sim/current-view/view-number-raw, but set it here anyway, just in case.
    setprop("/sim/current-view/view-number-raw", views[n].getIndex());
}

# activate view by index number used in XML definition (e.g. >100)
var setViewByIndex = func(i) {
    if (indices[i] != nil)
        setView(indices[i]);
}

var hasmember = func(class, member) {
	if (contains(class, member))
		return 1;
	if (!contains(class, "parents"))
		return 0;
	if (typeof(class.parents) != "vector")
		return 0;
	foreach (var parent; class.parents)
		if (hasmember(parent, member))
			return 1;
	return 0;
}


# Dynamically calculate limits so that it takes STEPS iterations to
# traverse the whole range, the maximum FOV is fixed at 120 degrees,
# and the minimum corresponds to normal maximum human visual acuity
# (~1 arc minute of resolution, although apparently people vary widely
# in this ability).  Quick derivation of the math:
#
#   mul^steps = max/min
#   steps * ln(mul) = ln(max/min)
#   mul = exp(ln(max/min) / steps)
var STEPS = 40;
var ACUITY = 1/60; # Maximum angle subtended by one pixel (== 1 arc minute)
var max = var min = var mul = 0;
var calcMul = func {
    max = 120; # Fixed at 120 degrees
    min = getprop("/sim/startup/xsize") * ACUITY;
    mul = math.exp(math.ln(max/min) / STEPS);
}

##
# Handler.  Increase FOV by one step
#
var increase = func {
    calcMul();
    var val = fovProp.getValue() * mul;
    if(val == max) { return; }
    if(val > max) { val = max }
    fovProp.setDoubleValue(val);
    var popup=getprop("/sim/view-name-popup");
    if(popup == 1 or popup==nil) gui.popupTip(sprintf("FOV: %.1f", val));
}

##
# Handler.  Decrease FOV by one step
#
var decrease = func {
    calcMul();
    var val = fovProp.getValue() / mul;
    fovProp.setDoubleValue(val);
    var popup=getprop("/sim/view-name-popup");
    if(popup == 1 or popup==nil) gui.popupTip(sprintf("FOV: %.1f%s", val, val < min ? " (overzoom)" : ""));
}

##
# Handler.  Reset FOV to default.
#
var resetFOV = func {
    setprop("/sim/current-view/field-of-view",
            getprop("/sim/current-view/config/default-field-of-view-deg"));
}

var resetViewPos = func {
    var v = current.getNode("config");
    setprop("/sim/current-view/x-offset-m", v.getNode("x-offset-m", 1).getValue() or 0);
    setprop("/sim/current-view/y-offset-m", v.getNode("y-offset-m", 1).getValue() or 0);
    setprop("/sim/current-view/z-offset-m", v.getNode("z-offset-m", 1).getValue() or 0);
}

var resetViewDir = func {
    var v = current.getNode("config");
    setprop("/sim/current-view/heading-offset-deg", v.getNode("heading-offset-deg", 1).getValue() or 0);
    setprop("/sim/current-view/pitch-offset-deg", v.getNode("pitch-offset-deg", 1).getValue() or 0);
    setprop("/sim/current-view/roll-offset-deg", v.getNode("roll-offset-deg", 1).getValue() or 0);
}

##
# Handler.  Step to the next (force=1) or next enabled view.
#
var stepView = func(step, force = 0) {
    step = step > 0 ? 1 : -1;
    var n = index;
    for (var i = 0; i < size(views); i += 1) {
        n += step;
        if (n < 0)
            n = size(views) - 1;
        elsif (n >= size(views))
            n = 0;
        var e = views[n].getNode("enabled");
        if (force or (e == nil or e.getBoolValue()) and
            (views[n].getNode("name")!=nil))
            break;
    }
    setView(n);

    # And pop up a nice reminder
    var popup=getprop("/sim/view-name-popup");
    if(popup == 1 or popup==nil) gui.popupTip(views[n].getNode("name").getValue());
}

##
# Get view index by name.
#
var indexof = func(name) {
    forindex (var i; views)
        if (views[i].getNode("name", 1).getValue() == name)
            return i;
    return nil;
}

##
# Standard view "slew" rate, in degrees/sec.
#
var VIEW_PAN_RATE = 60;

##
# Pans the view horizontally.  The argument specifies a relative rate
# (or number of "steps" -- same thing) to the standard rate.
#
var panViewDir = func(step) {
    if (getprop("/sim/freeze/master"))
        var prop = "/sim/current-view/heading-offset-deg";
    else
        var prop = "/sim/current-view/goal-heading-offset-deg";

    controls.slewProp(prop, step * VIEW_PAN_RATE);
}

##
# Pans the view vertically.  The argument specifies a relative rate
# (or number of "steps" -- same thing) to the standard rate.
#
var panViewPitch = func(step) {
    if (getprop("/sim/freeze/master"))
        var prop = "/sim/current-view/pitch-offset-deg";
    else
        var prop = "/sim/current-view/goal-pitch-offset-deg";

    controls.slewProp(prop, step * VIEW_PAN_RATE);
}


##
# Reset view to default using current view manager (see default_handler).
#
var resetView = func {
	manager.reset();
}


##
# Default view handler used by view.manager.
#
var default_handler = {
	reset : func {
		resetViewDir();
		resetFOV();
	},
};


# If <from>/<path> exists and <to>/<path> doesn't, copy the former to the
# latter.
#
var set_default = func(from, path, to) {
    from_ = from.getNode(path);
    if (from_ != nil) {
        if (to.getNode(path) == nil) {
            to.setValue(path, from_.getValue());
        }
    }
}

##
# View manager. Administrates optional Nasal view handlers.
# Usage:  view.manager.register(<view-id>, <view-handler>);
#
#   view-id:      the view's name (e.g. "Chase View") or index number
#   view-handler: a hash with any combination of the functions listed in the
#                 following example, or none at all. Only define the interface
#                 functions that you really need! The hash may contain local
#                 variables and other, non-interface functions.
#
# Example:
#
#   var some_view_handler = {
#           init   : func {},    # called only once at startup
#           start  : func {},    # called when view is switched to our view
#           stop   : func {},    # called when view is switched away from our view
#           reset  : func {},    # called with view.resetView()
#           update : func { 0 }, # called iteratively if defined. Must return
#   };                           # interval in seconds until next invocation
#                                # Don't define it if you don't need it!
#
#   view.manager.register("Some View", some_view_handler);
#
#
var manager = {
	current : { node: nil, handler: default_handler },
	init : func {
                me.current = nil;
		me.views = {};
		me.loopid = 0;
		var viewnodes = props.globals.getNode("sim").getChildren("view");
                var helicopter_view = viewnodes[1];
                forindex (var i; viewnodes) {
                    # Install this view, marking as multiplayer if appropriate.
                    var multiplayer = 1;
                    if (0) {
                        # Use this for views that do not work with multiplayer
                        # aircraft.
                        multiplayer = 0;
                    }
                    var viewnode = viewnodes[i];
                    me.views[i] = {
                        node: viewnode,
                        handler: default_handler,
                        multiplayer: multiplayer
                        };
                    # If this view is similar to helicopter view, copy across
                    # Helicopter View target offsets if not specified. E.g.
                    # this allows Tower View AGL to work on aircraft that don't
                    # know about it but need non-zero target-*-offset-m values
                    # to centre the view on the middle of the aircraft.
                    if (i==2 or i==3 or i==5 or i==7 or i==8) {
                        set_default(helicopter_view, "config/target-x-offset-m", viewnode);
                        set_default(helicopter_view, "config/target-y-offset-m", viewnode);
                        set_default(helicopter_view, "config/target-z-offset-m", viewnode);
                    }
                }
        # see comment at begin of file
		setlistener("/sim/current-view/view-number", func(n) {
			manager.set_view(n.getValue());
		}, 1);
	},
	register : func(which, handler = nil) {
                var n = num(which);
                if (n == nil)   n = indexof(which);
                if (n == nil) {
                    printf('Unable to register view handler: which=%s', which);
                    return;
                }
		if (handler == nil)
			handler = default_handler;
		me.views[n]["handler"] = handler;
		var viewnodes = props.globals.getNode("sim").getChildren("view");
                me.views[n]["node"] = viewnodes[n];
		if (hasmember(handler, "init"))
			handler.init(me.views[n].node);
		me.set_view();
	},
	set_view : func(which = nil) {
		if (which == nil)
			which = index;
		elsif (num(which) == nil)
			which = indexof(which);

		me.loopid += 1;
                if (me.current != nil) {
                    if (me.current.multiplayer) {
                        model_view_handler.stop();
                    }
		    if (hasmember(me.current.handler, "stop"))
			me.current.handler.stop();
                }

		me.current = me.views[which];

		if (hasmember(me.current.handler, "start"))
			me.current.handler.start();
		if (hasmember(me.current.handler, "update"))
			me._loop_(me.loopid += 1);
                if (me.current != nil and me.current.multiplayer) {
                    model_view_handler.start();
                }
		screenWidthCompens.update();

                # Make sure /sim/current-view/view-number-raw is kept up to
                # date.
                setprop("/sim/current-view/view-number-raw", views[which].getIndex());
	},
	reset : func {
		if (hasmember(me.current.handler, "reset"))
			me.current.handler.reset();
		else
			default_handler.reset();
	},
	_loop_ : func(id) {
		id == me.loopid or return;
		settimer(func { me._loop_(id) }, me.current.handler.update() or 0);
	},
        multiplayer_callback: func(data) {
                # We are called by model_view_handler when the user wants to
                # look at a different aircraft.
                #
                # We can be called very early due to model_view_handler_class's use
                # of a listener, so we need to protect against me.current.node not
                # being set up yet.
                #
                if (me.current.node != nil) {
                    me.current.node.getNode("config").setValues({
                        "root": data.root,});
                    me.current.node.getNode("config/root").setValue(data.root)
                }
        },
};


var fly_by_view_handler = {

        init : func {
		setlistener("/sim/signals/reinit", func(n) { n.getValue() or me.reset() });
		setlistener("/sim/crashed", func(n) { n.getValue() and me.reset() });
		setlistener("/sim/freeze/replay-state", func {
			settimer(func { me.reset() }, 1); # time for replay to catch up
		});
                setlistener("/sim/current-view/multiplayer", func(n) { me.reset(); } );

                me.reset();
	},

	start : func {
		me.reset();
	},

        # Sets me.root to node with path given by the value of property
        # /sim/view[6]/config/root (which will be /ai/models/multiplayer[N]
        # where N is the index of the multiplayer aircraft].  Note that this
        # node sometimes doesn't yet exist, in which case we return with
        # me.root = nil.
        #
        _set_multiplayer_root: func() {
            # Set me.root to /ai/models/multiplayer[.]
            var root = getprop("/sim/view[6]/config/root"); # /ai/models/multiplayer[]
            me.root = props.globals.getNode(root);
            if (me.root == nil) {
                #printf("root does not exist: %s", str(root));
            }
        },

        aircraft_position: func() {
            if (me.multiplayer) {
                me._set_multiplayer_root();
                if (me.root == nil) {
                    return geo.Coord.new();
                }
                var lat = me.root.getValue("position/latitude-deg");
                var lon = me.root.getValue("position/longitude-deg");
                var alt = me.root.getValue("position/altitude-ft") * FT2M;

	        return geo.Coord.new().set_latlon(lat, lon, alt);
            }
            else {
                return geo.aircraft_position();
            }
        },

	reset: func {
    me.multiplayer = getprop("/sim/current-view/multiplayer") or 0;

    if (me.multiplayer) {
        me._set_multiplayer_root();
        if (me.root == nil) {
            return;
        }

        me.chase = me.root.getValue("set/sim/chase-distance-m");
    }
    else {
        me.chase = getprop("/sim/chase-distance-m");
    }
    if (me.chase == nil or me.chase == 0)   me.chase = -25;
    me.chase = -me.chase;
                
		me.last = me.aircraft_position();
		me.setpos(1);
	},

	setpos : func(force = 0) {
                if (me.multiplayer) {
                    me._set_multiplayer_root();
                    if (me.root == nil) {
                        return 1;   # Ensure we get called back soon to try again.
                    }
                    # We would like to find the aircraft's actual velocity
                    # vector rather than heading, but it's not easily available
                    # as a property, so we use the aircraft heading and its
                    # forwards speed (uBody-fps).
                    #
                    # E.g. i think this may give biased viewpoint positions if
                    # aircraft is moving sideways due to wind.
                    #
                    var u = me.root.getValue("velocities/uBody-fps");   # forwards
                    #var v = me.root.getValue("velocities/vBody-fps");   # vertical
                    #var w = me.root.getValue("velocities/wBody-fps");   # lateral

                    var course = me.root.getValue("orientation/true-heading-deg");
                    var course_rad = course * math.pi / 180;
                    var vn = u * math.cos(course_rad);
                    var ve = u * -math.sin(course_rad);
                }
                else {
		    var vn = getprop("/velocities/speed-north-fps");
		    var ve = getprop("/velocities/speed-east-fps");
                    var course = (0.5*math.pi - math.atan2(vn, ve))*R2D;
                }

		var pos = me.aircraft_position();

		var dist = 0.0;
		if ( force ) {
		    # predict distance based on speed
		    var mps = math.sqrt( vn*vn + ve*ve ) * FT2M;
		    dist = mps * 3.5; # 3.5 seconds worth of travel
		} else {
		    # use actual distance
		    dist = me.last.distance_to(pos);
		    # reset when too far (i.e. position changed due to skipping time in replay mode)
		    if (dist>5000) return me.reset();
		}

		# check if the aircraft has moved enough
		if (dist < 1.7 * me.chase and !force)
			return 1.13;

                # "predict" and remember next aircraft position
                var delta_alt = (pos.alt() - me.last.alt()) * 0.5;
		pos.apply_course_distance(course, dist * 0.8);
		pos.set_alt(pos.alt() + delta_alt);
		me.last.set(pos);

		# apply random deviation
		var radius = me.chase * (0.5 * rand() + 0.7);

                if (me.multiplayer) {
                    # AGL not available for multiplayer aircraft as a property,
                    # so we calculate it explicitly.
                    var gl = geo.elevation(pos.lat(), pos.lon());
                    if (gl == nil)  gl = 0;
                    var agl = pos.alt() - gl;
                }
                else {
		    var agl = getprop("/position/altitude-agl-ft") * FT2M;
                }
		if (agl > me.chase)
			var angle = rand() * 2 * math.pi;
		else
			var angle = ((2 * rand() - 1) * 0.15 + 0.5) * (rand() < 0.5 ? -math.pi : math.pi);

		var dev_alt = math.cos(angle) * radius;
		var dev_side = math.sin(angle) * radius;
		pos.apply_course_distance(course + 90, dev_side);

                # and make sure it's not under ground
		var lat = pos.lat();
		var lon = pos.lon();
		var alt = pos.alt();
		var elev = geo.elevation(lat, lon);
		if (elev != nil) {
			elev += 2;   # min elevation
			if (alt + dev_alt < elev and dev_alt < 0)
				dev_alt = -dev_alt;
			if (alt + dev_alt < elev)
				alt = elev;
			else
				alt += dev_alt;
		}

		# set new view point
                if (me.multiplayer) {
                    # flightgear:src/Viewer/view.cxx will
                    # expect to find viewing position in
                    # /ai/models/multiplayer[]/sim/viewer/latitude-deg etc.
                    #
                    me.root.setValue("sim/viewer/latitude-deg", lat);
                    me.root.setValue("sim/viewer/longitude-deg", lon);
                    me.root.setValue("sim/viewer/altitude-ft", alt * M2FT);
                }
                else {
                    setprop("/sim/viewer/latitude-deg", lat);
                    setprop("/sim/viewer/longitude-deg", lon);
                    setprop("/sim/viewer/altitude-ft", alt * M2FT);
                }
		return 7.3;
	},

	update : func {
		return me.setpos();
	},
};


# Helper for views that can show multiplayer aircaft as well as the user's
# aircraft. Used by <manager> above.
#
var model_view_handler_class = {
    new: func() {
        var m = { parents:[model_view_handler_class]};
        m.current = nil;
        m.legendN = props.globals.initNode("/sim/current-view/model-view", "");
        m.dialog = props.Node.new({ "dialog-name": "model-view" });
        m.listener = setlistener("/sim/signals/multiplayer-updated", func m._update_(), 1);
        m.reset();
        _setlistener("/sim/menubar/legacy-multiplayer-view-selector/enabled", func {
                var enabled = getprop("/sim/menubar/legacy-multiplayer-view-selector/enabled");
                if (enabled) {
                    m.start();
                }
                else {
                    m.stop();
                }
                });
        return m;
    },
    start: func() {
        if (getprop('/sim/menubar/legacy-multiplayer-view-selector/enabled')) {
            fgcommand("dialog-show", me.dialog);
        }
        me.next(0);
    },
    stop: func() {
        fgcommand("dialog-close", me.dialog);
    },
    reset: func {
        me.select(0);
    },
    find: func(callsign) {
        forindex (var i; me.list) {
            if (me.list[i].callsign == callsign)
                return i;
        }
        return nil;
    },
    select: func(which, by_callsign=0) {
        if (by_callsign or num(which) == nil) {
            which = me.find(which) or 0;  # turn callsign into index
        }
        me.setup(me.list[which]);
    },
    next: func(step) {
        var i = me.find(me.current);
        i = i == nil ? 0 : math.mod(i + step, size(me.list));
        me.setup(me.list[i]);
    },
    _update_: func {
        var self = {
                callsign: getprop("/sim/multiplay/callsign"),
                model:,
                node: props.globals,
                root: '/',
                };
        # It looks like we can get called (from me.new()) before
        # multiplayer.model.list is created, so need to check whether it
        # exists.
        if (hasmember(multiplayer.model, 'list')) {
            me.list = [self] ~ multiplayer.model.list;
        }
        else {
            me.list = [self];
        }
        if (!me.find(me.current))
            me.select(0);
    },
    setup: func(data) {
        if (data.root == '/') {
            var ident = '[' ~ data.callsign ~ ']';
            setprop('/sim/current-view/multiplayer', 0);
        } else {
            var ident = '"' ~ data.callsign ~ '" (' ~ data.model ~ ')';
            setprop('/sim/current-view/multiplayer', 1);
        }

        me.current = data.callsign;
        me.legendN.setValue(data.callsign);
        manager.multiplayer_callback(data);
    },
};

var model_view_handler = model_view_handler_class.new();
# Note that gui/dialogs/model-view.xml expects to be able to call
# view.model_view_handler.next() etc.

var pilot_view_limiter = {
	new : func {
		return { parents: [pilot_view_limiter] };
	},
	init : func {
		me.hdgN = props.globals.getNode("/sim/current-view/heading-offset-deg");
		me.xoffsetN = props.globals.getNode("/sim/current-view/x-offset-m");
		me.xoffset_lowpass = aircraft.lowpass.new(0.1);
		me.last_offset = 0;
		me.needs_start = 0;
	},
	start : func {
		var limits = current.getNode("config/limits", 1);
		me.left = {
			heading_max : abs(limits.getNode("left/heading-max-deg", 1).getValue() or 1000),
			threshold : abs(limits.getNode("left/x-offset-threshold-deg", 1).getValue() or 0),
			xoffset_max : abs(limits.getNode("left/x-offset-max-m", 1).getValue() or 0),
		};
		me.right = {
			heading_max : -abs(limits.getNode("right/heading-max-deg", 1).getValue() or 1000),
			threshold : -abs(limits.getNode("right/x-offset-threshold-deg", 1).getValue() or 0),
			xoffset_max : -abs(limits.getNode("right/x-offset-max-m", 1).getValue() or 0),
		};
		me.left.scale = me.left.xoffset_max / (me.left.heading_max - me.left.threshold);
		me.right.scale = me.right.xoffset_max / (me.right.heading_max - me.right.threshold);
		me.last_hdg = normdeg(me.hdgN.getValue());
		me.enable_xoffset = me.right.xoffset_max > 0.001 or me.left.xoffset_max > 0.001;

		me.needs_start = 0;
	},
	update : func {
		if (getprop("/devices/status/keyboard/ctrl"))
			return;

    if( getprop("/sim/signals/reinit") )
    {
      me.needs_start = 1;
      return;
    }
    else if( me.needs_start )
      me.start();

		var hdg = normdeg(me.hdgN.getValue());
		if (abs(me.last_hdg - hdg) > 180)  # avoid wrap-around skips
			me.hdgN.setDoubleValue(hdg = me.last_hdg);
		elsif (hdg > me.left.heading_max)
			me.hdgN.setDoubleValue(hdg = me.left.heading_max);
		elsif (hdg < me.right.heading_max)
			me.hdgN.setDoubleValue(hdg = me.right.heading_max);
		me.last_hdg = hdg;

		# translate view on X axis to look far right or far left
		if (me.enable_xoffset) {
			var offset = 0;
			if (hdg > me.left.threshold)
				offset = (me.left.threshold - hdg) * me.left.scale;
			elsif (hdg < me.right.threshold)
				offset = (me.right.threshold - hdg) * me.right.scale;

			var new_offset = me.xoffset_lowpass.filter(offset);
			me.xoffsetN.setDoubleValue((me.xoffsetN.getValue() or 0) - me.last_offset + new_offset);
			me.last_offset = new_offset;
		}
		return 0;
	},
};


var panViewDir = func(step) {	# FIXME overrides panViewDir function from above; needs better integration
	if (getprop("/sim/freeze/master"))
		var prop = "/sim/current-view/heading-offset-deg";
	else
		var prop = "/sim/current-view/goal-heading-offset-deg";
	var viewVal = getprop(prop);
	var delta = step * VIEW_PAN_RATE * getprop("/sim/time/delta-realtime-sec");
	var viewValSlew = normdeg(viewVal + delta);
	var headingMax = abs(current.getNode("config/limits/left/heading-max-deg", 1).getValue() or 1000);
	var headingMin = -abs(current.getNode("config/limits/right/heading-max-deg", 1).getValue() or 1000);
	if (viewValSlew > headingMax)
		viewValSlew = headingMax;
	elsif (viewValSlew < headingMin)
		viewValSlew = headingMin;
	setprop(prop, viewValSlew);
}


#------------------------------------------------------------------------------
#
# Saves/restores/moves the view point (position, orientation, field-of-view).
# Moves are interpolated with sinusoidal characteristic. There's only one
# instance of this class, available as "view.point".
#
# Usage:
#    view.point.save();        ... save current view and return reference to
#                                  saved values in the form of a props.Node
#
#    view.point.restore();     ... restore saved view parameters
#
#    view.point.move(<prop> [, <time>]);
#                              ... set view parameters from a props.Node with
#                                  optional move time in seconds. <prop> may be
#                                  nil, in which case nothing happens.
#
# A parameter set as expected by set() and returned by save() is a props.Node
# object containing any (or none) of these children:
#
#   <heading-offset-deg>
#   <pitch-offset-deg>
#   <roll-offset-deg>
#   <x-offset-m>
#   <y-offset-m>
#   <z-offset-m>
#   <field-of-view>
#   <move-time-sec>
#
# The <move-time> isn't really a property of the view, but is available
# for convenience. The time argument in the move() method overrides it.


##
# Normalize angle to  -180 <= angle < 180
#
var normdeg = func(a) {
	while (a >= 180)
		a -= 360;
	while (a < -180)
		a += 360;
	return a;
}


##
# Manages one translation/rotation axis. (For simplicity reasons the
# field-of-view parameter is also managed by this class.)
#
var ViewAxis = {
	new : func(prop) {
		var m = { parents : [ViewAxis] };
		m.prop = props.globals.getNode(prop, 1);
		if (m.prop.getType() == "NONE")
			m.prop.setDoubleValue(0);

		m.from = m.to = m.prop.getValue();
		return m;
	},
	reset : func {
		me.from = me.to = normdeg(me.prop.getValue());
	},
	target : func(v) {
		me.to = normdeg(v);
	},
	move : func(blend) {
		me.prop.setValue(me.from + blend * (me.to - me.from));
	},
};



##
# view.point: handles smooth view movements
#
var point = {
	init : func {
		me.axes = {
			"heading-offset-deg" : ViewAxis.new("/sim/current-view/goal-heading-offset-deg"),
			"pitch-offset-deg" : ViewAxis.new("/sim/current-view/goal-pitch-offset-deg"),
			"roll-offset-deg" : ViewAxis.new("/sim/current-view/goal-roll-offset-deg"),
			"x-offset-m" : ViewAxis.new("/sim/current-view/x-offset-m"),
			"y-offset-m" : ViewAxis.new("/sim/current-view/y-offset-m"),
			"z-offset-m" : ViewAxis.new("/sim/current-view/z-offset-m"),
			"field-of-view" : ViewAxis.new("/sim/current-view/field-of-view"),
		};
		me.storeN = props.Node.new();
		me.dtN = props.globals.getNode("/sim/time/delta-realtime-sec", 1);
		me.currviewN = props.globals.getNode("/sim/current-view", 1);
		me.blend = 0;
		me.loop_id = 0;
		props.copy(props.globals.getNode("/sim/view/config"), me.storeN);
	},
	save : func {
		me.storeN = props.Node.new();
		props.copy(me.currviewN, me.storeN);
		return me.storeN;
	},
	restore : func {
		me.move(me.storeN);
	},
	move : func(prop, time = nil) {
		prop != nil or return;
		var n = prop.getNode("view-number");
		if (n != nil)
			setView(n.getValue());
		foreach (var a; keys(me.axes)) {
			var n = prop.getNode(a);
			me.axes[a].reset();
			if (n != nil)
				me.axes[a].target(n.getValue());
		}
		var m = prop.getNode("move-time-sec");
		if (m != nil)
			time = m.getValue();

		if (time == nil)
			time = 1;

		me.blend = -1;   # range -1 .. 1
		me._loop_(me.loop_id += 1, time);
	},
	_loop_ : func(id, time) {
		me.loop_id == id or return;
		me.blend += me.dtN.getValue() / time;
		if (me.blend > 1)
			me.blend = 1;

		var b = (math.sin(me.blend * math.pi / 2) + 1) / 2; # range 0 .. 1
		foreach (var a; keys(me.axes))
			me.axes[a].move(b);

		if (me.blend < 1)
			settimer(func { me._loop_(id, time) }, 0);
	},
};



##
# view.ScreenWidthCompens: optional FOV compensation for wider screens.
# It keeps an equivalent of 55° FOV on a 4:3 zone centered on the screen
# whichever is the screen width/height ratio. Works only if width >= height.

var screenWidthCompens = {
	defaultFov: nil,
	oldW: nil, oldH: nil, oldOpt: nil,
	assumedW: 4, assumedH: 3,
	fovStore: [],
	lastViewStatus: {},
	statusNode: nil, # = /sim/current-view/field-of-view-compensation
	getStatus: func me.statusNode.getValue(),
	setStatus: func(state) me.statusNode.setValue(state),
	wNode: nil, # = /sim/startup/xsize
	hNode: nil, # = /sim/startup/ysize
	getDimensions: func [me.wNode.getDoubleValue(),me.hNode.getDoubleValue()],
	calcNewFov: func(fov=55, oldW=nil, oldH=nil, w=nil, h=nil) {
		var dim = me.getDimensions();
		if (w == nil) w = dim[0];
		if (h == nil) h = dim[1];
		if (oldW == nil) oldW = me.assumedW;
		if (oldH == nil) oldH = me.assumedH;
		if (w/h == oldW/oldH or h > w) return fov;
		else return math.atan2(w/h, oldW/oldH / math.tan(fov * D2R)) * R2D;
	},
	init: func() {
		me.defaultFov = getprop("/sim/current-view/config/default-field-of-view-deg");
		me.statusNode = props.globals.getNode("/sim/current-view/field-of-view-compensation", 1);
		me.wNode = props.globals.getNode("/sim/startup/xsize", 1);
		me.hNode = props.globals.getNode("/sim/startup/ysize", 1);
		(me.oldW, me.oldH) = me.getDimensions();

		setsize(me.fovStore, size(views));
		forindex (var i; views) {
			me.fovStore[i] = views[i].getNode("config/default-field-of-view-deg", 1).getDoubleValue() or 55;
			me.lastViewStatus[i] = { w:me.assumedW, h:me.assumedH };
		}
		me.update(opt:nil, force:1);
	},
	toggle: func() me.update(!me.getStatus(), 1),
	update: func(opt=nil, force=0) {
		if (opt == nil)
			opt = me.getStatus();
		else me.setStatus(opt);
		var (w, h) = me.getDimensions();
		# Update config/default-field-of-view-deg nodes if state changed:
		if (force or me.oldOpt != opt or me.oldW/me.oldH != w/h) {
			me.oldW = w;
			me.oldH = h;
			me.oldOpt = opt;
			if (!opt) {
				setprop("/sim/current-view/config/default-field-of-view-deg", me.defaultFov);
				forindex (var i; views)
					views[i].setValue("config/default-field-of-view-deg", me.fovStore[i]);
			} else {
				setprop("/sim/current-view/config/default-field-of-view-deg",
				        me.calcNewFov(fov:me.defaultFov, w:w, h:h));
				forindex (var i; views)
					views[i].setValue("config/default-field-of-view-deg",
					                  me.calcNewFov(fov:me.fovStore[i], w:w, h:h));
			}
		}
		# Update this view if necessary:
		if (!opt) (w,h) = (me.assumedW,me.assumedH); # back to default FOV
		var thisview = me.lastViewStatus[index];
		if (thisview.w/thisview.h != w/h) {
			fovProp.setValue(me.calcNewFov(fovProp.getValue(), thisview.w, thisview.h, w, h))
			and
			((thisview.opt,thisview.w,thisview.h) = (opt,w,h));
		}
	},
};


views = props.globals.getNode("/sim", 1).getChildren("view");
fovProp = props.globals.getNode("/sim/current-view/field-of-view", 1);
point.init();

setlistener("/sim/current-view/view-number", func(n) {
    current = views[index = n.getValue()];
}, 1);

# Allow view changes by setting view-number-raw - avoids problems when/if we
# add new default views (between 0 and 99).
#
setlistener("/sim/current-view/view-number-raw", func(n) {
    var index = n.getValue();
    forindex (var i; views) {
        if (views[i].getIndex() == index) {
            props.globals.getNode("/sim/current-view/view-number", 1).setValue(i);
            return;
        }
    }
    printf("Failed to find view-number-raw=%s", index);
}, 1);

props.globals.initNode("/position/altitude-agl-ft"); # needed by Fly-By View
screenWidthCompens.init();
manager.init();
manager.register("Fly-By View", fly_by_view_handler);

setlistener("/sim/signals/reinit", func {
	screenWidthCompens.update(opt:nil,force:1);
});
setlistener("/sim/startup/xsize", func {
	screenWidthCompens.update();
});
setlistener("/sim/startup/ysize", func {
	screenWidthCompens.update();
});


var fdm_init_listener = setlistener("/sim/signals/fdm-initialized", func {
	removelistener(fdm_init_listener); # uninstall, so we are only called once
	var zoffset = nil;
	foreach (var v; views) {
		var index = v.getIndex();
		if (index > 8 and index < 100) {
			globals["view"] = nil;
			die("\n***\n*\n*  Illegal use of reserved view index "
					~ index ~ ". Use indices >= 100!\n*\n***");
		} elsif (index >= 100 and index < 200) {
			if (v.getNode("name") == nil)
				continue;
			var e = v.getNode("enabled");
			if (e != nil) {
				aircraft.data.add(e);
				e.setAttribute("userarchive", 0);
			}
		}
	}

	forindex (var i; views) {
        indices[views[i].getIndex()] = i;
		var limits = views[i].getNode("config/limits/enabled");
		if (limits != nil) {
			func (i) {
				var limiter = pilot_view_limiter.new();
				setlistener(limits, func(n) {
					manager.register(i, n.getBoolValue() ? limiter : nil);
					manager.set_view();
				}, 1);
			}(i);
		}
	}
});
