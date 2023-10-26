# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#-------------------------------------------------------------------------------
# svgcanvas.nas - base class to populate canvas from SVG and animate elements
# author:       jsb
# created:      06/2020
#-------------------------------------------------------------------------------
# Examples:
# var myCanvas = SVGCanvas.new("mySVG");
# myCanvas.loadsvg("myfile.svg", ["foo", "bar"]);
#
# to hide/show a SVG element based on a property you can use:
# var L = setlistener("/controls/foo", myCanvas._makeListener_showHide("foo"));
#
# to animate a SVG element you can use:
# myCanvas["bar"].setTranslation(10,20);
#-------------------------------------------------------------------------------

var SVGCanvas = {
    colors: canvas.colors,
    
    # constructor
    # name:     name of canvas
    # settings: hash with canvas settings
    new: func(name, settings=nil) {
        var canvas_settings = {
            "name": "SVG_canvas",
            "size": [1024,1024],
            "view": [1024,1024],
            "mipmapping": 1
        };

        if (settings != nil) {
            # override defaults
            foreach (var key; keys(settings)) {
                canvas_settings[key] = settings[key];
            }            
        }
        canvas_settings["name"] = name;       

        var obj = {
            parents: [me],
            _canvas: canvas.new(canvas_settings),
            _root: nil,
            name: name,
        };    
        obj._root = obj._canvas.createGroup();
        return obj;
    },

    del: func() {
        if (me.window != nil) me.window.del();
        me._canvas.del();
        return nil;
    },
    # loadSVG - loads SVG file and create canvas.element objects for given IDs
    # file:     filename to load
    # svg_keys: vector of id strings
    # options:  options to canvas.parsesvg
    loadSVG: func(file, svg_keys, options=nil) {
        var default_options = {
            "default-font-family": "LiberationSans",
            "default-font-weight": "",
            "default-font-style": "",
        };
        if (ishash(options)) {
            # override defaults
            foreach (var key; keys(options)) {
                default_options[key] = options[key];
            }            
        }
        if (canvas.parsesvg(me._root, file, default_options)) {
            # create nasal variables for SVG elements;
            foreach (var key; svg_keys) {
                me[key] = me._root.getElementById(key);
                if (me[key] != nil) {
                    me._updateClip(key);
                }
                else logprint(DEV_WARN, "  loadSVG: id '", key, "' not found in SVG file");
            }
        }
        return me;
    },
    
    # openInWindow - opens the canvas in a window 
    # window_size: vector [size_x, size_y] passed to canvas.Window.new
    # returns canvas.window object
    asWindow: func(window_size) {
        if (me["window"] != nil) 
            return me.window;
            
        me.window = canvas.Window.new(window_size, "dialog");
        me.window.set('title', me.name)
            .set("resize", 1)
            .setCanvas(me._canvas);
        me.window.lockAspectRatio(1);
        me.window.del = func() { 
            call(canvas.Window.del, [], me, var err = []);
            me.window = nil;
        }
        return me.window
    },
    
    getPath: func {
        return me._canvas.getPath();
    },

    getCanvas: func {
        return me._canvas;
    },

    getRoot: func {
        return me._root;
    },

    # svgkey:   id of text element to updateTextElement
    # text:     new text
    updateTextElement: func(svgkey, text, color = nil) {
        if (me[svgkey] == nil or !isa(me[svgkey], canvas.Text)) {
            logprint(DEV_ALERT, "updateTextElement(): Invalid argument ", svgkey);
            return;
        }
        me[svgkey].setText(text);
        if (color != nil) {
            if (isvec(color)) me[svgkey].setColor(color);
            elsif (isstr(color)) me[svgkey].setColor(me.colors[color]);
        }
        return me;
    },
    
    #--------------------------------------------------------------
    # private methods, to be used in this and derived classes only
    #--------------------------------------------------------------
    _updateClip: func(key) {
        var clip_elem = me._root.getElementById(key~"_clip");
        if (clip_elem != nil) {
            clip_elem.setVisible(0);
            me[key].setClipByElement(clip_elem);
        }
    },

    # returns generic listener to show/hide element(s)
    # svgkeys: can be a string referring to a single element
    #          or vector of strings referring to SVG elements
    #         (hint: if possible, group elements in SVG and animate group)
    # value: optional value to trigger show(); otherwise node.value will be implicitly treated as bool
    _makeListener_showHide: func(svgkeys, value=nil) {
        if (value == nil) {
            if (isvec(svgkeys)) {
                return func(n) {
                    if (n.getValue())
                        foreach (var key; svgkeys) me[key].show();
                    else
                        foreach (var key; svgkeys) me[key].hide();
                }
            }
            else {
                return func(n) {
                    if (n.getValue()) me[svgkeys].show();
                    else me[svgkeys].hide();
                }
            }
        }
        else {
            if (isvec(svgkeys)) {
                return func(n) {
                    if (n.getValue() == value)
                        foreach (var key; svgkeys) me[key].show();
                    else
                        foreach (var key; svgkeys) me[key].hide();
                };
            }
            else {
                return func(n) {
                    if (n.getValue() == value) me[svgkeys].show();
                    else me[svgkeys].hide();
                };
            }
        }
    },

    # returns listener to set rotation of element(s)
    # svgkeys: can be a string referring to a single element
    #          or vector of strings referring to SVG elements
    # factors: optional, number (if svgkeys is a single key) or hash of numbers
    #          {"svgkey" : factor}, missing keys will be treated as 1
    _makeListener_rotate: func(svgkeys, factors=nil) {
        if (factors == nil) {
            if (isvec(svgkeys)) {
                return func(n) {
                    var value = n.getValue() or 0;
                    foreach (var key; svgkeys) {
                        me[key].setRotation(value);
                    }
                }
            }
            else {
                return func(n) {
                    var value = n.getValue() or 0;
                    me[svgkeys].setRotation(value);
                }
            }
        }
        else {
            if (isvec(svgkeys)) {
                return func(n) {
                    var value = n.getValue() or 0;
                    foreach (var key; svgkeys) {
                        var factor = factors[key] or 1;
                        me[key].setRotation(value * factor);
                    }
                };
            }
            else {
                return func(n) {
                    var value = n.getValue() or 0;
                    var factor = num(factors) or 1;
                    me[svgkeys].setRotation(value * factor);
                };
            }
        }
    },

    # returns listener to set translation of element(s)
    # svgkeys: can be a string referring to a single element
    #          or vector of strings referring to SVG elements
    # factors: number (if svgkeys is a single key) or hash of numbers
    #          {"svgkey" : factor}, missing keys will be treated as 0 (=no op)
    _makeListener_translate: func(svgkeys, fx, fy) {
        if (isvec(svgkeys)) {
            var x = num(fx) or 0;
            var y = num(fy) or 0;
            if (ishash(fx) or ishash(fy)) {
                return func(n) {
                    foreach (var key; svgkeys) {
                        var value = n.getValue() or 0;
                        if (ishash(fx)) x = fx[key] or 0;
                        if (ishash(fy)) y = fy[key] or 0;
                        me[key].setTranslation(value * x, value * y);
                    }
                };
            }
            else {
                return func(n) {
                    foreach (var key; svgkeys) {
                        var value = n.getValue() or 0;
                        me[key].setTranslation(value * x, value * y);
                    }
                };
            }
        }
        else {
            if (num(fx) == nil or num(fy) == nil) {
                logprint(DEV_ALERT, "_makeListener_translate(): Error, factor not a number.");
                return func ;
            }
            return func(n) {
                var value = n.getValue() or 0;
                if (num(value) == nil)
                    value = 0;
                me[svgkeys].setTranslation(value * fx, value * fy);
            };
        }
    },
    
    # returns generic listener to change element color
    # svgkeys: can be a string referring to a single element
    #          or vector of strings referring to SVG elements
    #         (hint: putting elements in a SVG group (if possible) might be easier)
    # colors can be either a vector e.g. [r,g,b] or "name" from me.colors
    _makeListener_setColor: func(svgkeys, color_true, color_false) {
        var col_0 = isvec(color_false) ? color_false : me.colors[color_false];
        var col_1 = isvec(color_true) ? color_true : me.colors[color_true];
        if (isvec(svgkeys) )  {
            return func(n) {
                if (n.getValue())
                    foreach (var key; svgkeys) me[key].setColor(col_1);
                else
                    foreach (var key; svgkeys) me[key].setColor(col_0);
            };
        }
        else {
            return func(n) {
                if (n.getValue()) me[svgkeys].setColor(col_1);
                else me[svgkeys].setColor(col_0);
            };
        }
    },

    _makeListener_updateText: func(svgkeys, format="%s", default="") {
        if (isvec(svgkeys)) {
            return func(n) {
                foreach (var key; svgkeys) {
                    me.updateTextElement(key, sprintf(format, n.getValue() or default));
                }
            };
        }
        else {
            return func(n) {
                me.updateTextElement(svgkeys, sprintf(format, n.getValue() or default));
            };
        }
    },   
};