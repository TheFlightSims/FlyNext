#
# canvas_draw loader
# 03/2020 by jsb
# if you add files to the draw subdirectory, add corresponding lines below in 
# the main() function
#

var _canvas_draw_load = {
    namespace: "canvas",
    path: getprop("/sim/fg-root")~"/Nasal/canvas/draw/",

    load: func(filename) {
        io.load_nasal(me.path~filename, me.namespace);
    },

    main: func {
        me.load("draw.nas");
        me.load("transform.nas");
        
        me.load("scales.nas");
        me.load("compass.nas");
    },
};

_canvas_draw_load.main();
_canvas_draw_load = nil;