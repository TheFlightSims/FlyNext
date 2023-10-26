#
# canvas.draw library
# created 12/2018 by jsb
# based on plot2D.nas from the oscilloscope add-on by R. Leibner
#
# Contains functions to draw path elements on an existing canvas group.
# - basic shapes
# - grids
# - scale marks
#
# Basic shapes:
# These are macros calling existing API command for path elements.
# They return a path element, no styling done. You can easily do by passing
# the returned element to other existing functions like setColor, e.g.
# var myCircle = canvas.circle(myCanvasGroup, 10, 30, 30).setColor(myColor)
#
# Grids:
# draw horizontal and vertical lines
# from the Oscilloscope add-on by rleibner with a few modifications
#
# Scale marks:
# Draw equidistant lines ("marker", "ticks") perpendicular to a baseline.
# Baseline can be a horizontal or vertical line or a part of a circle.
# This is a building block for compass rose and tapes.
#

var draw = {
    # draw line; from and to must be vectors [x,y]
    line: func(cgroup, from, to) {
        var path = cgroup.createChild("path", "line");
        return path.moveTo(from[0], from[1]).lineTo(to[0], to[1]);
    },
    
    # draw horizontal line; 
    # from: optional, vector, defaults to [0,0]
    #       or scalar  
    hline: func(cgroup, length, from = nil) {
        if (from == nil) {
            to = [length, 0];
            from = [0,0];
        }
        elsif (typeof(from) == "scalar") {
            to = [num(from) + length, 0];
            from = [num(from) ,0];
        }
        else to = [from[0] + length, from[1]];
        me.line(cgroup, from, to);
    },
    
    # draw vertical line; 
    # from: optional, vector, defaults to [0,0]
    #       or scalar  
    vline: func(cgroup, length, from = nil) {
        if (from == nil) {
            to = [0, length];
            from = [0,0];
        }
        elsif (typeof(from) == "scalar") {
            to = [0, num(from) + length];
            from = [0, num(from)];
        }
        else to = [from[0], from[1] + length];
        me.line(cgroup, from, to); 
    },
    # if center_x is given as vector, its first two elements define the center
    # and center_y is ignored
    circle: func(cgroup, radius, center_x = nil, center_y = nil) {
        var path = cgroup.createChild("path", "circle");
        return path.circle(radius, center_x, center_y);
    },

    # if center_x is given as vector, its first two elements define the center
    # and center_y is ignored
    ellipse: func(cgroup, radius_x, radius_y, center_x = nil, center_y = nil) {
        var path = cgroup.createChild("path", "ellipse");
        return path.ellipse(radius_x, radius_y, center_x, center_y);
    },

    # draw part of a circle
    # radius    as integer (for circle) or [rx,ry] (for ellipse) in pixels.
    # center    vector [x,y]
    # from_deg  begin of arc in degree (0 = north, increasing clockwise)
    # to_deg    end of arc
    arc: func(cgroup, radius, center, from_deg = nil, to_deg = nil) {
        if (from_deg == nil)
            return me.circle(radius, center);

        var path = cgroup.createChild("path", "arc");
        from_deg *= D2R;
        to_deg *= D2R;
        var (rx, ry) = (typeof(radius) == "vector") ? [radius[0], radius[1]] : [radius, radius];
        var (fs, fc) = [math.sin(from_deg), math.cos(from_deg)];
        var dx = (math.sin(to_deg) - fs) * rx;
        var dy = (math.cos(to_deg) - fc) * ry;

        path.moveTo(center[0] + rx*fs, center[1] - ry*fc);
        if(abs(to_deg - from_deg) > 180*D2R) {
            path.arcLargeCW(rx, ry, 0, dx, -dy);
        }
        else {
            path.arcSmallCW(rx, ry, 0, dx, -dy);
        }
        return path;
    },

    # x, y is top, left corner
    rectangle: func(cgroup, width, height, x = 0, y = 0, rounded = nil) {
        var path = cgroup.createChild("path", "rectangle");
        return path.rect(x, y, width, height, {"border-radius": rounded});
    },

    # x, y is top, left corner
    square: func(cgroup, length, center_x = 0, center_y = 0, cfg = nil) {
        var path = cgroup.createChild("path", "square");
        return path.square(center_x, center_y, length, cfg = nil);
    },

    # deltoid draws a kite (dy1 > 0 and dy2 > 0) or a arrow head (dy2 < 0)
    # dx  = width
    # dy1 = height of "upper" triangle
    # dy2 = height of "lower" triangle, < 0 draws an arrow head
    # x, y = position of tip
    deltoid: func (cgroup, dx, dy1, dy2, x = 0, y = 0) {
        var path = cgroup.createChild("path", "deltoid");
        path.moveTo(x, y)
            .line(-dx/2, dy1)
            .line(dx/2, dy2)
            .line(dx/2, -dy2)
            .close();
        return path;
    },

    # draw a "diamond"
    # dx: width
    # dy: height
    rhombus: func(cgroup, dx, dy, center_x = 0, center_y = 0) {
        return draw.deltoid(cgroup, dx, dy/2, dy/2, center_x, center_y - dy/2);
    },
};

#aliases
draw.diamond = draw.rhombus;

#base class for styles
draw.style = {
    new: func() {
        var obj = {
            parents: [draw.style],
            _color: [255, 255, 255, 1],
            _color_fill: nil,
            _stroke_width: 1,
        };
        return obj;
    },

    #set value of existing(!) key
    set: func(key, value) {
        if (contains(me, key)) {
            me[key] = value;
            return me;
        }
        return nil;
    },

    get: func(key) {
        return me[key];
    },

    setColor: func() {
        me._color = arg;
        return me;
    },

    getColor: func() {
        return me._color;
    },

    setColorFill: func() {
        me._color_fill = arg;
        return me;
    },

    setStrokeLineWidth: func() {
        me._stroke_width = arg;
        return me;
    },
};

#
# marksStyle - parameter set for draw.marks*
# Interpretation depends on the draw function used. In general, marks are
# lines drawn perpendicular to a baseline in certain intervals. 'Big' and
# 'small' marks are supported by means of 'subdivisions'.
# Some values are expressed as percentage to allow easy scaling.
# Again: Interpretation depends on the draw function using this style.
#
draw.marksStyle = {
    # constants to align marks relative to baseline
    MARK_LEFT: -1,
    MARK_UP: -1,
    MARK_CENTER: 0,
    MARK_RIGHT: 1,
    MARK_DOWN: 1,

    MARK_IN: -1,    # from radius to center of circle
    MARK_OUT: 1,    # from radius to outside

    new: func() {
        var obj = {
            parents: [draw.marksStyle, draw.style.new()],
            baseline_width: 0,  # stroke of baseline
            mark_length: 0.8,   # length of a division marker in %interval or %radius
            mark_offset: 0,     # in %mark_length, see setMarkLength below
            mark_width: 1,      # in pixel
            subdivisions: 0,    # number of smaller marks between to marks
            subdiv_length: 0.5, # in %mark_length
        };
        return obj;
    },

    setBaselineWidth: func(value) {
        me.baseline_width = num(value) or 0;
        return me;
    },

    setMarkLength: func(value) {
        me.mark_length = num(value) or 1;
        return me;
    },

    # position of mark relative to baseline, call this with MARK_* defined above
    # -1 = left, 0 = center, 1 = right
    setMarkOffset: func(value) {
        if (num(value) == nil) return nil;
        me.mark_offset = value;
        return me;
    },

    setMarkWidth: func(value) {
        me.mark_width = num(value) or 1;
        return me;
    },

    setSubdivisions: func(value) {
        me.subdivisions = int(value) or 0;
        return me;
    },

    setSubdivisionLength: func(value) {
        me.subdiv_length = num(value) or 0.5;
        return me;
    },
};

# draw.marksLinear: draw marks for a linear scale on a canvas group, e.g. speed tape
# mark lines are draws perpendicular to baseline
# orientation      of baseline; "up", "down", "left", "right"
# num_marks        number of marks to draw
# interval         distance between marks (pixel)
# style            marksStyle hash with more parameters

draw.marksLinear = func(cgroup, orientation, num_marks, interval, style)
{
    if (!isa(style, draw.marksStyle)) {
        logprint(DEV_WARN, "draw.marks: invalid style argument.");
        return nil;
    }
    orientation = chr(string.tolower(orientation[0]));
    if (orientation == "v") orientation = "d";
    if (orientation == "h") orientation = "r";
    var marks = cgroup.createChild("path", "marks");

    if (style.baseline_width > 0) {
        var length = interval * (num_marks - 1);
        if (orientation == "d") {
            marks.vert(length);
        }
        elsif(orientation == "u") {
            marks.vert(-length);
        }
        elsif(orientation == "r") {
            marks.horiz(length);
        }
        elsif(orientation == "l") {
            marks.horiz(-length);
        }
    }

    var mark_length = interval * style.mark_length;
    if (style.subdivisions > 0) {
        interval /= (style.subdivisions + 1);
        var subdiv_length = mark_length * style.subdiv_length;
    };
    marks.setColor(style.getColor());

    var offset0 = 0.5 * style.mark_offset - 0.5;
    for (var i = 0; i < num_marks; i += 1) {
        for (var j = 0; j <= style.subdivisions; j += 1) {
            var length = (j == 0) ? mark_length : subdiv_length;
            var translation = interval * (i*(style.subdivisions + 1) + j);
            var offset = offset0 * length;
            if (orientation == "d") {
                marks.moveTo(offset, translation)
                .horiz(length);
            }
            elsif (orientation == "u") {
                marks.moveTo(offset, -translation)
                .horiz(length);
            }
            elsif (orientation == "r") {
                marks.moveTo(translation, offset)
                .vert(length);
            }
            elsif (orientation == "l") {
                marks.moveTo(-translation, offset)
                .vert(length);
            }
        }
    }
    while (j) {
        marks.pop_back();
        j -= 1;
    }
    return marks;
}

# radius        of baseline (circle)
# interval      distance of marks in degree
# phi_start     position of first mark in degree (default 0 = north)
# phi_stop      position of last mark in degree (default 360)
draw.marksCircular = func(cgroup, radius, interval, phi_start = 0, phi_stop = 360, style = nil) {
    if (style == nil) {
        style = draw.marksStyle.new();
    }
    if (!isa(style, draw.marksStyle)) {
        logprint(DEV_WARN, "draw.marksCircular: invalid style argument");
        return nil;
    }
    # normalize
    while (phi_start >= 360) { phi_start -= 360; }
    while (phi_stop > 360) { phi_stop -= 360; }
    if (phi_start > phi_stop) {
        phi_stop += 360;
    }

    if (style.baseline_width > 0) {
        var marks = draw.arc(cgroup, radius, [0,0], phi_start, phi_stop)
            .set("id", "marksCircular")
            .setColor(style.getColor());
    }
    else {
        var marks = cgroup.createChild("path", "marksCircular").setColor(style.getColor());
    }

    var mark_length = style.mark_length * radius;
    var subd_length = style.subdiv_length * mark_length;
    interval *= D2R;
    phi_start *= D2R;
    phi_stop *= D2R;
    var phi_s = interval / (style.subdivisions + 1);
    var x = y = l = 0;
    var offset0 = 0.5 * style.mark_offset - 0.5;
    for (var phi = phi_start; phi <= phi_stop; phi += interval) {
        for (var j = 0; j <= style.subdivisions; j += 1) {
            var p = phi + j * phi_s;
            #print(p*R2D);
            x = math.sin(p);
            y = -math.cos(p);
            l = (j == 0) ? mark_length : subd_length;
            r = radius + offset0 * l;
            marks.moveTo(x * r, y * r)
                .line(x * l, y * l);
        }
    }
    while (j) {
        marks.pop_back();
        j -= 1;
    }
    return marks;
}

# draw.grid
# 1) (cgroup, [sizeX, sizeY], dx, dy, border = 1)
# 2) (cgroup, nx, ny, dx, dy, border = 1)
# size      [width, height] in pixels.
# nx, ny    number of lines in x/y direction
# dx        tiles width in pixels.
# dy        tiles height in pixels.
# border    optional as boolean, True by default.
draw.grid = func(cgroup) {
    var i = 0;
    var (s, n) = ([0, 0], []);
    if (typeof(arg[i]) == "vector") {
        s = arg[i];
        i += 1;
    }
    else {
        var n = [arg[i], arg[i + 1]];
        i += 2;
    }
    var dx = arg[i];
    i += 1;
    var dy = dx;
    var border = 1;
    if (size(arg) - 1 >= i) { dy = arg[i]; i += 1; }
    if (size(arg) - 1 >= i) { border = arg[i]; }
    if (size(n) == 2) {
        s[0] = n[0] * dx - 1;
        s[1] = n[1] * dy - 1;
    }
    #print("size: ", s[0], " ", s[1], " d:", dx, ", ", dy, " b:", border);
    var grid = cgroup.createChild("path", "grid").setColor([255, 255, 255, 1]);
    var (x0, y0) = border ? [0, 0] : [dx, dy];
    for (var x = x0; x <= s[0]; x += dx) {
        grid.moveTo(x, 0).vertTo(s[1]);
    }
    for (var y = y0; y <= s[1]; y += dy) {
        grid.moveTo(0, y).horizTo(s[0]);
    }
    if (border) {
        grid.moveTo(s[0], 0).vertTo(s[1]).horizTo(0);
    }
    return grid;
}

draw.arrow = func(cgroup, length, origin_center=0) {
    #var path = cgroup.createChild("path", "arrow");
    var tip_size = length * 0.1;
    var offset = (origin_center) ? -length/2 : 0;
    var arrow = draw.deltoid(cgroup, tip_size, tip_size, 0, 0, offset);
    #if (offset) { arrow.moveTo(0, offset); }
    arrow.line(0,length);
    return arrow;
}