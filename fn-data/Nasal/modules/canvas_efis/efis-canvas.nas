#------------------------------------------
# efis-canvas.nas - Canvas EFIS framework
# author:       jsb
# created:      12/2017
#------------------------------------------

#--  EFISCanvas - base class to create canvas displays / pages --
# * manages a canvas
# * can load a SVG file and create clipping from <name>_clip elements
# * allows to register multiple update functions with individual update intervals
# * update functions can be en-/disabled by a single property that should
#   reflect the visibility of the canvas
# * several listener factories for common animations

var EFISCanvas = {
    # static members
    _instances: [],
    unload: func() {
        print("-- Removing EFISCanvas instances --");
        foreach (var instance; EFISCanvas._instances) {
            print("  - "~instance.name);
            instance.del();
        }
        EFISCanvas._instances = [];
    },

    # destructor
    del: func() {
        me._canvas.del();
        foreach (var timer; me._timers) {
            timer.stop();
        }
        me._timers = [];
    },

    colors: canvas.colors,
    canvas_settings: EFIS.defaultcanvas_settings,

    new: func(name) {
        var obj = {
            parents: [me, canvas.SVGCanvas.new(name, me.canvas_settings)],
            _id: size(EFISCanvas._instances), # internal ID for EFIS window mgmt.
            id: 0,                            # instance id e.g. for PFD/MFD
            name: name,
            svg_keys: [],
            # for reload support while efis development
            _timers: [],
            updateN: nil,       # to be used in update() to pause updates
            _instr_props: {},
        };
        append(EFISCanvas._instances, obj);
        var n = props.Node.makeValidPropName(name);
        obj.updateCountN = EFIS_root_node.getNode("update/count-"~n, 1);
        obj.updateCountN.setIntValue(0);
        obj.debugN = EFIS_root_node.getNode("debug/"~n, 1);
        obj.debugN.setBoolValue(0);
        return obj;
    },


    #set node that en-/dis-ables canvas updates
    setUpdateN: func(n) {
        me.updateN = n;
    },

    # register an update function with a certain update interval
    # f: function 
    # f_me: if there is any "me" reference in "f", you can set "me" with this
    #       defaults to EFISCanvas instance calling this method, useful if "f" 
    #       is a member of the EFISCanvas instance
    addUpdateFunction: func(f, interval, f_me = nil) {
        if (!isfunc(f)) {
            logprint(DEV_ALERT, "EFISCanvas.addUpdateFunction: argument is not a function.");
            return;
        }
        interval = num(interval);
        f_me = (f_me == nil) ? me : f_me;
        if (interval != nil and interval >= 0) {
            var timer = maketimer(interval, me, func {
                if (me.updateN != nil and me.updateN.getValue()) {
                    var err = [];
                    call(f, [], f_me, nil, err);
                    if (size(err))
                        debug.printerror(err);
                    # debug/performance monitoring
                    me.updateCountN.increment();
                }
            });
            append(me._timers, timer);
            return timer;
        }
    },

    # start all registered update functions
    startUpdates: func() {
        foreach (var t; me._timers)
            t.start();
    },

    # stop all registered update functions
    stopUpdates: func() {
        foreach (var t; me._timers) {
            t.stop();
        }
    },

    # getInstr - get props from /instrumentation/<sys>[i]/<prop>
    # creates prop node objects for efficient access
    # sys: the instrument name (path) (me.id is appended as index!!)
    # prop: the property(path)
    getInstr: func(sys, prop, default=0, id=nil) {
        if (me._instr_props[sys] == nil)
            me._instr_props[sys] = {};
        if (me._instr_props[sys][prop] == nil) {
            if (id == nil) { id = me.id; }
            me._instr_props[sys][prop] =
                props.getNode("/instrumentation/"~sys~"["~id~"]/"~prop, 1);
        }
        var value = me._instr_props[sys][prop].getValue();
        if (value != nil) return value;
        else return default;
    },
};
