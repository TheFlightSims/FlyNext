#-------------------------------------------------------------------------------
# canvas.Image
#-------------------------------------------------------------------------------
# Class for an image element on a canvas
#
var Image = {
    new: func(ghost) {
        var obj = {
            parents: [Image, Element.new(ghost)],
        };
        return obj;
    },

    # Set image file to be used
    #
    # @param file Path to file or canvas (Use canvas://... for canvas, eg.
    #                         canvas://by-index/texture[0])
    setFile: func(file) {
        me.set("src", file);
    },

    # Set rectangular region of source image to be used
    #
    # @param left       Rectangle minimum x coordinate
    # @param top        Rectangle minimum y coordinate
    # @param right      Rectangle maximum x coordinate
    # @param bottom     Rectangle maximum y coordinate
    # @param normalized Whether to use normalized ([0,1]) or image
    #                   ([0, image_width]/[0, image_height]) coordinates
    setSourceRect: func {
        # Work with both positional arguments and named arguments.
        # Support first argument being a vector instead of four separate ones.
        if (size(arg) == 1) {
            arg = arg[0];
        }
        elsif (size(arg) and size(arg) < 4 and isvec(arg[0])) {
            arg = arg[0]~arg[1:];
        }
        if (!contains(caller(0)[0], "normalized")) {
            if (size(arg) > 4)
                var normalized = arg[4];
            else var normalized = 1;
        }
        if (size(arg) >= 3)
            var (left,top,right,bottom) = arg;

        me._node.getNode("source", 1).setValues({
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            normalized: normalized
        });
        return me;
    },

    # Set size of image element
    #
    # @param width
    # @param height
    # - or -
    # @param size ([width, height])
    setSize: func {
        me._node.setValues({size: _arg2valarray(arg)});
        return me;
    }
};

