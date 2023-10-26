#-------------------------------------------------------------------------------
# canvas.Map
#-------------------------------------------------------------------------------
# Class for a group element on a canvas with possibly geographic positions
# which automatically get projected according to the specified projection.
# Each map consists of an arbitrary number of layers (canvas groups)
#
var Map = {
    df_controller: nil,
    new: func(ghost) {
        var obj = { 
            parents: [Map, Group.new(ghost)],
            layers: {},
            controller: nil,
        };
        return obj.setController();
    },

    del: func() {
        logprint(_API_dbg_level, "canvas.Map.del()");
        if (me.controller != nil)
            me.controller.del(me);
        foreach (var k; keys(me.layers)) {
            me.layers[k].del();
            delete(me.layers, k);
        }
        # call inherited "del"
        me.parents = subvec(me.parents,1);
        me.del();
    },

    setController: func(controller=nil, arg...) {
        if (me.controller != nil) me.controller.del(me);
        if (controller == nil) {
            controller = Map.df_controller;
        }
        elsif (typeof(controller) != "hash") {
            controller = Map.Controller.get(controller);
        }

        if (controller == nil) {
            me.controller = nil;
        }
        else {
            if (!isa(controller, Map.Controller))
                die("OOP error: controller needs to inherit from Map.Controller");
            me.controller = call(controller.new, [me]~arg, controller, var err=[]); # try...
            if (size(err)) {
                if (err[0] != "No such member: new") # ... and either catch or rethrow
                    die(err[0]);
                else
                    me.controller = controller;
            }
            elsif (me.controller == nil) {
                me.controller = controller;
            }
            elsif (me.controller != controller and !isa(me.controller, controller))
                die("OOP error: created instance needs to inherit from or be the specific controller class");
        }

        return me;
    },

    getController: func() {
        return me.controller;
    },

    addLayer: func(factory, type_arg=nil, priority=nil, style=nil, opts=nil, visible=1) {
        if (contains(me.layers, type_arg)) {
            logprint(DEV_ALERT, "addLayer() warning: overwriting existing layer:", type_arg);
        }

        var options = opts;
        # Argument handling
        if (type_arg != nil) {
            var layer = factory.new(type:type_arg, group:me, map:me, style:style, options:options, visible:visible);
            var type = factory.get(type_arg);
            var key = type_arg;
        } else {
            var layer = factory.new(group:me, map:me, style:style, options:options, visible:visible);
            var type = factory;
            var key = factory.type;
        }
        me.layers[type_arg] = layer;

        if (priority == nil)
            priority = type.df_priority;
        if (priority != nil)
            layer.group.setInt("z-index", priority);

        return layer; # return new layer to caller() so that we can directly work with it, i.e. to register event handlers (panning/zooming)
    },

    getLayer: func(type_arg) {
        me.layers[type_arg];
    },

    setRange: func(range) {
        me.set("range",range);
    },

    setScreenRange: func(range) {
        me.set("screen-range",range);
    },

    setPos: func(lat, lon, hdg=nil, range=nil, alt=nil) {
        # TODO: also propage setPos events to layers and symbols (e.g. for offset maps)
        me.set("ref-lat", lat);
        me.set("ref-lon", lon);
        if (hdg != nil)
            me.set("hdg", hdg);
        if (range != nil)
            me.setRange(range);
        if (alt != nil)
            me.set("altitude", alt);
    },

    getPos: func {
        return [me.get("ref-lat"),
                me.get("ref-lon"),
                me.get("hdg"),
                me.get("range"),
                me.get("altitude")];
    },

    getLat: func me.get("ref-lat"),
    getLon: func me.get("ref-lon"),
    getHdg: func me.get("hdg"),
    getAlt: func me.get("altitude"),
    getRange: func me.get("range"),
    getScreenRange: func me.get("screen-range"),
    getLatLon: func [me.get("ref-lat"), me.get("ref-lon")],

    # N.B.: This always returns the same geo.Coord object,
    # so its values can and will change at any time (call
    # update() on the coord to ensure it is up-to-date,
    # which basically calls this method again).
    getPosCoord: func {
        var (lat, lon) = (me.get("ref-lat"), me.get("ref-lon"));
        var alt = me.get("altitude");
        if (lat == nil or lon == nil) {
            if (contains(me, "coord")) {
                debug.warn("canvas.Map: lost ref-lat and/or ref-lon source");
            }
            return nil;
        }
        if (!contains(me, "coord")) {
            me.coord = geo.Coord.new();
            var m = me;
            me.coord.update = func m.getPosCoord();
        }
        me.coord.set_latlon(lat,lon,alt or 0);
        return me.coord;
    },

    # Update each layer on this Map. Called by
    # me.controller.
    update: func(predicate=nil) {
        var t = systime();
        foreach (var l; keys(me.layers)) {
            var layer = me.layers[l];
            # Only update if the predicate allows
            if (predicate == nil or predicate(layer)) {
                layer.update();
            }
        }
        logprint(_MP_dbg_lvl, "Took "~((systime()-t)*1000)~"ms to update map()");
        me.setBool("update", 1); # update any coordinates that changed, to avoid floating labels etc.
        return me;
    },
};

