#-------------------------------------------------------------------------------
# canvas.Path
#-------------------------------------------------------------------------------
# Class for an (OpenVG) path element on a canvas
#
var Path = {
    # Path segment commands (VGPathCommand)
    VG_CLOSE_PATH:     0,
    VG_MOVE_TO:        2,
    VG_MOVE_TO_ABS:    2,
    VG_MOVE_TO_REL:    3,
    VG_LINE_TO:        4,
    VG_LINE_TO_ABS:    4,
    VG_LINE_TO_REL:    5,
    VG_HLINE_TO:       6,
    VG_HLINE_TO_ABS:   6,
    VG_HLINE_TO_REL:   7,
    VG_VLINE_TO:       8,
    VG_VLINE_TO_ABS:   8,
    VG_VLINE_TO_REL:   9,
    VG_QUAD_TO:       10,
    VG_QUAD_TO_ABS:   10,
    VG_QUAD_TO_REL:   11,
    VG_CUBIC_TO:      12,
    VG_CUBIC_TO_ABS:  12,
    VG_CUBIC_TO_REL:  13,
    VG_SQUAD_TO:      14,
    VG_SQUAD_TO_ABS:  14,
    VG_SQUAD_TO_REL:  15,
    VG_SCUBIC_TO:     16,
    VG_SCUBIC_TO_ABS: 16,
    VG_SCUBIC_TO_REL: 17,
    VG_SCCWARC_TO:    20, # Note that CC and CCW commands are swapped. This is
    VG_SCCWARC_TO_ABS:20, # needed due to the different coordinate systems used.
    VG_SCCWARC_TO_REL:21, # In OpenVG values along the y-axis increase from bottom
    VG_SCWARC_TO:     18, # to top, whereas in the Canvas system it is flipped.
    VG_SCWARC_TO_ABS: 18,
    VG_SCWARC_TO_REL: 19,
    VG_LCCWARC_TO:    24,
    VG_LCCWARC_TO_ABS:24,
    VG_LCCWARC_TO_REL:25,
    VG_LCWARC_TO:     22,
    VG_LCWARC_TO_ABS: 22,
    VG_LCWARC_TO_REL: 23,

    # Number of coordinates per command
    num_coords: [
        0, 0, # VG_CLOSE_PATH
        2, 2, # VG_MOVE_TO
        2, 2, # VG_LINE_TO
        1, 1, # VG_HLINE_TO
        1, 1, # VG_VLINE_TO
        4, 4, # VG_QUAD_TO
        6, 6, # VG_CUBIC_TO
        2, 2, # VG_SQUAD_TO
        4, 4, # VG_SCUBIC_TO
        5, 5, # VG_SCCWARC_TO
        5, 5, # VG_SCWARC_TO
        5, 5, # VG_LCCWARC_TO
        5, 5, # VG_LCWARC_TO
   ],

    #
    new: func(ghost)
    {
        var obj = {
            parents: [Path, Element.new(ghost)],
            _first_cmd: 0,
            _first_coord: 0,
            _last_cmd: -1,
            _last_coord: -1
        };
        return obj;
    },

    # Remove all existing path data
    reset: func {
        me._node.removeChildren("cmd", 0);
        me._node.removeChildren("coord", 0);
        me._node.removeChildren("coord-geo", 0);
        me._first_cmd = 0;
        me._first_coord = 0;
        me._last_cmd = -1;
        me._last_coord = -1;
        return me;
    },

    # Set the path data (commands and coordinates)
    setData: func(cmds, coords) {
        me.reset();
        me._node.setValues({cmd: cmds, coord: coords});
        me._last_cmd = size(cmds) - 1;
        me._last_coord = size(coords) - 1;
        return me;
    },

    setDataGeo: func(cmds, coords) {
        me.reset();
        me._node.setValues({cmd: cmds, "coord-geo": coords});
        me._last_cmd = size(cmds) - 1;
        me._last_coord = size(coords) - 1;
        return me;
    },

    # Add a path segment
    addSegment: func(cmd, coords...) {
        var coords = _arg2valarray(coords);
        var num_coords = me.num_coords[cmd];
        if (size(coords) != num_coords) {
            debug.warn("Invalid number of arguments (expected "~num_coords~")");
        }
        else {
            me.setInt("cmd["~(me._last_cmd += 1)~"]", cmd);
            for (var i = 0; i < num_coords; i += 1)
                me.setDouble("coord["~(me._last_coord += 1)~"]", coords[i]);
        }

        return me;
    },

    addSegmentGeo: func(cmd, coords...) {
        var coords = _arg2valarray(coords);
        var num_coords = me.num_coords[cmd];
        if (size(coords) != num_coords) {
            debug.warn("Invalid number of arguments (expected "~num_coords~")");
        }
        else {
            me.setInt("cmd["~(me._last_cmd += 1)~"]", cmd);
            for (var i = 0; i < num_coords; i += 1)
                me.set("coord-geo["~(me._last_coord += 1)~"]", coords[i]);
        }
        return me;
    },

    # Remove first segment
    pop_front: func {
        me._removeSegment(1);
    },

    # Remove last segment
    pop_back: func {
        me._removeSegment(0);
    },

    # Get the number of segments
    getNumSegments: func() {
        return me._last_cmd - me._first_cmd + 1;
    },

    # Get the number of coordinates (each command has 0..n coords)
    getNumCoords: func() {
        return me._last_coord - me._first_coord + 1;
    },

    # Move path cursor
    moveTo: func me.addSegment(me.VG_MOVE_TO_ABS, arg),
    move:   func me.addSegment(me.VG_MOVE_TO_REL, arg),
    # Add a line
    lineTo: func me.addSegment(me.VG_LINE_TO_ABS, arg),
    line:   func me.addSegment(me.VG_LINE_TO_REL, arg),
    # Add a horizontal line
    horizTo: func me.addSegment(me.VG_HLINE_TO_ABS, arg),
    horiz:   func me.addSegment(me.VG_HLINE_TO_REL, arg),
    # Add a vertical line
    vertTo: func me.addSegment(me.VG_VLINE_TO_ABS, arg),
    vert:   func me.addSegment(me.VG_VLINE_TO_REL, arg),
    # Add a quadratic Bézier curve
    quadTo: func me.addSegment(me.VG_QUAD_TO_ABS, arg),
    quad:   func me.addSegment(me.VG_QUAD_TO_REL, arg),
    # Add a cubic Bézier curve
    cubicTo: func me.addSegment(me.VG_CUBIC_TO_ABS, arg),
    cubic:   func me.addSegment(me.VG_CUBIC_TO_REL, arg),
    # Add a smooth quadratic Bézier curve
    squadTo: func me.addSegment(me.VG_SQUAD_TO_ABS, arg),
    squad:   func me.addSegment(me.VG_SQUAD_TO_REL, arg),
    # Add a smooth cubic Bézier curve
    scubicTo: func me.addSegment(me.VG_SCUBIC_TO_ABS, arg),
    scubic:   func me.addSegment(me.VG_SCUBIC_TO_REL, arg),
    # Draw an elliptical arc (shorter counter-clockwise arc)
    arcSmallCCWTo: func me.addSegment(me.VG_SCCWARC_TO_ABS, arg),
    arcSmallCCW:   func me.addSegment(me.VG_SCCWARC_TO_REL, arg),
    # Draw an elliptical arc (shorter clockwise arc)
    arcSmallCWTo: func me.addSegment(me.VG_SCWARC_TO_ABS, arg),
    arcSmallCW:   func me.addSegment(me.VG_SCWARC_TO_REL, arg),
    # Draw an elliptical arc (longer counter-clockwise arc)
    arcLargeCCWTo: func me.addSegment(me.VG_LCCWARC_TO_ABS, arg),
    arcLargeCCW:   func me.addSegment(me.VG_LCCWARC_TO_REL, arg),
    # Draw an elliptical arc (shorter clockwise arc)
    arcLargeCWTo: func me.addSegment(me.VG_LCWARC_TO_ABS, arg),
    arcLargeCW:   func me.addSegment(me.VG_LCWARC_TO_REL, arg),
    # Close the path (implicit lineTo to first point of path)
    close: func me.addSegment(me.VG_CLOSE_PATH),

    # Add a (rounded) rectangle to the path
    #
    # @param x    Position of left border
    # @param y    Position of top border
    # @param w    Width
    # @param h    Height
    # @param cfg  Optional settings (eg. {"border-top-radius": 5})
    rect: func(x, y, w, h, cfg = nil) {
        var opts = (cfg != nil) ? cfg : {};

        # resolve border-[top-,bottom-][left-,right-]radius
        var br = opts["border-radius"];
        if (isscalar(br)) {
            br = [br, br];
        }

        var _parseRadius = func(id) {
            if ((var r = opts["border-"~id~"-radius"]) == nil) {
                # parse top, bottom, left, right separate if no value specified for
                # single corner
                foreach(var s; ["top", "bottom", "left", "right"]) {
                    if (id.starts_with(s~"-")) {
                        r = opts["border-"~s~"-radius"];
                        break;
                    }
                }
            }

            if (r == nil) { return br; }
            else if (isscalar(r)) { return [r, r]; }
            else { return r; }
        };

        # top-left
        if ((var r = _parseRadius("top-left")) != nil) {
            me.moveTo(x, y + r[1]).arcSmallCWTo(r[0], r[1], 0, x + r[0], y);
        }
        else { me.moveTo(x, y); }

        # top-right
        if ((r = _parseRadius("top-right")) != nil) {
            me.horizTo(x + w - r[0]).arcSmallCWTo(r[0], r[1], 0, x + w, y + r[1]);
        }
        else { me.horizTo(x + w); }

        # bottom-right
        if ((r = _parseRadius("bottom-right")) != nil) {
            me.vertTo(y + h - r[1]).arcSmallCWTo(r[0], r[1], 0, x + w - r[0], y + h);
        }
        else { me.vertTo(y + h); }

        # bottom-left
        if ((r = _parseRadius("bottom-left")) != nil) {
            me.horizTo(x + r[0]).arcSmallCWTo(r[0], r[1], 0, x, y + h - r[1]);
        }
        else { me.horizTo(x); }
        return me.close();
    },

    # Add a (rounded) square to the path
    #
    # @param x        Position of left border
    # @param y        Position of top border
    # @param l        length
    # @param cfg    Optional settings (eg. {"border-top-radius": 5})
    square: func(x, y, l, cfg = nil) {
        return me.rect(x, y, l, l, cfg);
    },

    # Add an ellipse to the path
    #
    # @param rx        radius x
    # @param ry        radius y
    # @param cx        (optional) center x coordinate or vector [cx, cy]
    # @param cy        (optional) center y coordinate
    ellipse: func(rx, ry, cx = nil, cy = nil) {
        if (isvec(cx)) {
            cy = cx[1];
            cx = cx[0];
        }
        else {
            cx = num(cx) or 0;
            cy = num(cy) or 0;
        }
        me.moveTo(cx - rx, cy)
            .arcSmallCW(rx, ry, 0, 2*rx, 0)
            .arcSmallCW(rx, ry, 0, -2*rx, 0);
        return me;
    },

    # Add a circle to the path
    #
    # @param r    radius
    # @param cx  (optional) center x coordinate or vector [cx, cy]
    # @param cy  (optional) center y coordinate
    circle: func(r, cx = nil, cy = nil) {
        return me.ellipse(r, r, cx, cy);
    },

    setColor: func {
        me.setStroke(_getColor(arg));
    },

    getColor: func {
        me.getStroke();
    },

    setColorFill: func {
        me.setFill(_getColor(arg));
    },

    getColorFill: func {
        me.getColorFill();
    },

    setFill: func(fill) {
        me.set("fill", fill);
    },

    setStroke: func(stroke) {
        me.set("stroke", stroke);
    },

    getStroke: func {
        me.get("stroke");
    },

    setStrokeLineWidth: func(width) {
        me.setDouble("stroke-width", width);
    },

    # Set stroke linecap
    #
    # @param linecap String, "butt", "round" or "square"
    #
    # See http://www.w3.org/TR/SVG/painting.html#StrokeLinecapProperty for details
    setStrokeLineCap: func(linecap) {
        me.set("stroke-linecap", linecap);
    },

    # Set stroke linejoin
    #
    # @param linejoin String, "miter", "round" or "bevel"
    #
    # See http://www.w3.org/TR/SVG/painting.html#StrokeLinejoinProperty for details
    setStrokeLineJoin: func(linejoin) {
        me.set("stroke-linejoin", linejoin);
    },

    # Set stroke dasharray
    #
    # @param pattern Vector, Vector of alternating dash and gap lengths
    #    [on1, off1, on2, ...]
    setStrokeDashArray: func(pattern) {
        if (isvec(pattern)) {
            me.set("stroke-dasharray", string.join(",", pattern));
        }
        else {
            debug.warn("setStrokeDashArray: vector expected!");
        }
        return me;
    },

    # private:
    _removeSegment: func(front) {
        if (me.getNumSegments() < 1) {
            debug.warn("No segment available");
            return me;
        }

        var cmd = front ? me._first_cmd : me._last_cmd;
        var num_coords = me.num_coords[me.get("cmd["~cmd~"]")];
        if (me.getNumCoords() < num_coords) {
            debug.warn("To few coords available");
        }

        me._node.removeChild("cmd", cmd);

        var first_coord = front ? me._first_coord : me._last_coord - num_coords + 1;
        for (var i = 0; i < num_coords; i += 1) {
            me._node.removeChild("coord", first_coord + i);
        }

        if (front) {
            me._first_cmd += 1;
            me._first_coord += num_coords;
        }
        else {
            me._last_cmd -= 1;
            me._last_coord -= num_coords;
        }
        return me;
    },
};

