#------------------------------------------
# display-unit.nas - Canvas EFIS framework
# author:       jsb
# created:      12/2017
#------------------------------------------


# Class DisplayUnit (DU) - handles a named display 3D object in the cockpit
#  * creates a canvas that is placed on the 3D object once
#  * creates an image element on canvas to show source input
#  * handles power on/off by (un-)hiding canvas root group

var DisplayUnit =
{
    #-- static members
    _instances: [],
    bgcolor: [0.01, 0.01, 0.01, 1],
    
    # call del() on all instances
    unload: func() {
        foreach (var instance; DisplayUnit._instances) {
            instance.del();
        }
        DisplayUnit._instances = [];
    },
    
    del: func() {
        if (me.window != nil) {
            me.window.del();
            me.window = nil;
        }
        if (me.placement != nil) { 
            me.placement.remove();
            me.placement = nil;
        }
        if (me.du_canvas != nil) {
            me.du_canvas.del();
            me.du_canvas = nil;
        }
    },

    # name: string, used in canvas window title and on DU test canvas
    # canvas_settings: hash
    # screen_obj: string, name of 3D object for canvas placement
    # parent_obj: string, optional parent 3D object for placement
    new: func(name, canvas_settings, screen_obj, parent_obj = nil) {
        var obj = {
            parents: [me],
            _id: size(DisplayUnit._instances),
            canvas_settings: canvas_settings,
            placement_node: screen_obj,
            placement_parent: parent_obj,
            placement: nil,
            du_canvas: nil,
            root: nil,
            window: nil,
            name: name,
            img: nil,     # canvas image element, shall use other canvas as source
            powerN: nil,
        };
        append(DisplayUnit._instances, obj);
        return obj._init();
    },

    _init: func() {
        me.canvas_settings["name"] = "DisplayUnit " ~ size(DisplayUnit._instances);
        me.du_canvas = canvas.new(me.canvas_settings).setColorBackground(DisplayUnit.bgcolor);
        me.root = me.du_canvas.createGroup();
        #-- optional for development: create test image
        me._test_img();
        
        me.img = me.root.createChild("image", "DisplayUnit "~me.name);
        var place = { parent: me.placement_parent, node: me.placement_node };
        me.placement = me.du_canvas.addPlacement(place);
        #var status = me.placement.getNode("status-msg",1);
        return me;
    },

    _test_img: func() {
        var x = num(me.canvas_settings.view[0])/2 or 20;
        var y = num(me.canvas_settings.view[1])/2 or 20;
        me.root.createChild("text").setText("'"~me.name~"'\n no source ")
            .setColor(1,1,1,1)
            .setAlignment("center-center")
            .setTranslation(x, y);

        var L = int(y/16);
        var black = [0, 0, 0, 1];
        var blue = [0, 0.2, 0.9, 1];
        var yellow = [1, 1, 0, 1];
        var grey = [0.7, 0.7, 0.7, 1];
        var tl = me.root.createChild("group", "top-left");
        var r = tl.createChild("path").rect(L, L, 8*L, 8*L)
            .setColorFill(grey);
        for (var i=1; i <= 3; i += 1) {
            for (var j=1; j <= 8; j += 1) {
                var r = tl.createChild("path").rect(i*L, j*L, L, L);
                # .setStrokeLineWidth(0);
                math.mod(i+j, 2) ?  r.setColorFill(black) : r.setColorFill(yellow);
            }
        }
        var F = tl.createChild("path")
            .setColorFill(blue)
            .setColor(blue)
            .setStrokeLineJoin("round")
            .setStrokeLineWidth(3);
        F.moveTo(5*L, 2*L)
            .line(3.5*L, 0).line(0, L).line(-2.5*L, 0)
            .line(0, L)
            .line(2*L, 0).line(0, L).line(-2*L, 0)
            .line(0, 3*L)
            .line(-L, 0)
            .close();
        x = me.canvas_settings.view[0]-L;
        y = me.canvas_settings.view[1]-L;
        me.root.createChild("path", "square-top-left").rect(0, 0, L, L)
            .setColorFill(1,1,1,1);
        me.root.createChild("path", "square-top-right").rect(x, 0, L, L)
            .setColorFill(1,1,1,1);
        me.root.createChild("path", "square-btm-left").rect(0, y, L, L)
            .setColorFill(1,1,1,1);
        me.root.createChild("path", "square-btm-right").rect(x, y, L, L)
            .setColorFill(1,1,1,1);
    },
    
    # set a new source path for canvas image element
    setSource: func(path) {
        #print("DisplayUnit.setSource for "~me.du_canvas.getPath()~" ("~me.name~") to "~path);
        if (path == "")
            me.img.hide();
        else {
            me.img.set("src", path);
            me.img.show();
        }
        return me;
    },

    setPowerSource: func(prop, min) {
        me.powerN = props.getNode(prop,1);
        setlistener(me.powerN, func(n) {
            if ((n.getValue() or 0) >= min) me.root.show();
            else me.root.hide();
        }, 1, 0);
    },
    
    asWindow: func(window_size) {
        me.window = canvas.Window.new(window_size, "dialog");
        me.window.set('title', "EFIS " ~ me.name)
            .set("resize", 1)
            .setCanvas(me.du_canvas);
        me.window.move(me._id*200, me._id*40);
        if (typeof(me.window.lockAspectRatio) == "func")
            me.window.lockAspectRatio(1);
        me.window.del = func() { call(canvas.Window.del, [], me); }
        return me.window
    },    
};
