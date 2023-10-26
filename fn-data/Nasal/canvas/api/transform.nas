#-------------------------------------------------------------------------------
# Transform
#-------------------------------------------------------------------------------
# A transformation matrix which is used to transform an #Element on the canvas.
# The dimensions of the matrix are 3x3 where the last row is always 0 0 1:
#
#  a c e
#  b d f
#  0 0 1
#
# See http://www.w3.org/TR/SVG/coords.html#TransformMatrixDefined for details.
#     https://www.w3.org/TR/css-transforms-1/#mathematical-description
#
var Transform = {
    new: func(node, vals = nil) {
        var m = {
            parents: [Transform],
            _node: node,
            a: node.getNode("m[0]", 1),
            b: node.getNode("m[1]", 1),
            c: node.getNode("m[2]", 1),
            d: node.getNode("m[3]", 1),
            e: node.getNode("m[4]", 1), #tx
            f: node.getNode("m[5]", 1), #ty
        };

        var use_vals = isvec(vals) and size(vals) == 6;

        # initialize to identity matrix
        m.a.setDoubleValue(use_vals ? vals[0] : 1);
        m.b.setDoubleValue(use_vals ? vals[1] : 0);
        m.c.setDoubleValue(use_vals ? vals[2] : 0);
        m.d.setDoubleValue(use_vals ? vals[3] : 1);
        m.e.setDoubleValue(use_vals ? vals[4] : 0);
        m.f.setDoubleValue(use_vals ? vals[5] : 0);

        return m;
    },

    setTranslation: func() {
        var trans = _arg2valarray(arg);

        me.e.setDoubleValue(trans[0]);
        me.f.setDoubleValue(trans[1]);

        return me;
    },
    
    getTranslation: func() {
        return [me.e.getValue(), me.f.getValue()];
    },
    
    # Set rotation (Optionally around a specified point instead of (0,0))
    #
    #    setRotation(rot)
    #    setRotation(rot, cx, cy)
    #
    # @note If using with rotation center different to (0,0) do not use
    #             #setTranslation as it would interfere with the rotation.
    setRotation: func(angle) {
        var center = _arg2valarray(arg);

        var s = math.sin(angle);
        var c = math.cos(angle);

        # rotation goes to the top-left 2x2 part of the matrix
        me.a.setDoubleValue(c);     me.c.setDoubleValue(-s);
        me.b.setDoubleValue(s);     me.d.setDoubleValue(c);

        if (size(center) == 2) {
            me.e.setDoubleValue((-center[0] * c) + (center[1] * s) + center[0]);
            me.f.setDoubleValue((-center[0] * s) - (center[1] * c) + center[1]);
        }

        return me;
    },

    # Set scale (either as parameters or array)
    #
    # If only one parameter is given its value is used for both x and y
    #    setScale(x, y)
    #    setScale([x, y])
    setScale: func {
        var scale = _arg2valarray(arg);
        # the scale factors go to the diagonal elements of the matrix
        me.a.setDoubleValue(scale[0]);
        me.d.setDoubleValue(size(scale) >= 2 ? scale[1] : scale[0]);
        return me;
    },

    getScale: func() {
        # TODO handle rotation
        return [me.a.getValue(), me.d.getValue()];
    },
    
    # this function is called very often, if a canvas map is active and
    # the aircraft symbol is shown.
    setGeoPosition: func(lat, lon) {
        if (me["_gn"] == nil) { me._gn = me._node.getNode("m-geo[4]", 1); }
        if (me["_ge"] == nil) { me._ge = me._node.getNode("m-geo[5]", 1); }
        me._gn.setValue("N" ~ lat);
        me._ge.setValue("E" ~ lon);
        return me;
    },
};
