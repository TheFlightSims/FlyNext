#-------------------------------------------------------------------------------
# Canvas
#-------------------------------------------------------------------------------
# Class for a canvas
# not to be confused with the namespace canvas (case sensitive!)
#
var Canvas = {
    # private helper for wrapCanvas;
    _new: func(canvas_ghost) {
        var obj = {
            parents: [Canvas, PropertyElement],
            _node: props.wrapNode(canvas_ghost._node_ghost),
        };
        return obj;
    },

    # Place this canvas somewhere onto the object. Pass criterions for placement
    # as a hash, eg:
    #
    #    my_canvas.addPlacement({
    #        "texture": "EICAS.png",
    #        "node": "PFD-Screen",
    #        "parent": "Some parent name"
    #    });
    #
    # Note that we can choose whichever of the three filter criterions we use for
    # matching the target object for our placement. If none of the three fields is
    # given every texture of the model will be replaced.
    addPlacement: func(vals) {
        var placement = me._node.addChild("placement", 0, 0);
        placement.setValues(vals);
        return placement;
    },

    # Create a new group with the given name
    #
    # @param id Optional id/name for the group
    createGroup: func(id = nil) {
        return Group.new(me._createGroup(id));
    },

    # Get the group with the given name
    getGroup: func(id) {
        return Group.new(me._getGroup(id));
    },

    # Set the background color
    #
    # @param color    Vector of 3 or 4 values in [0, 1]
    setColorBackground: func {
        me.set("background", _getColor(arg));
    },

    getColorBackground: func {
        me.get("background");
    },

    # Get path of canvas to be used eg. in Image::setFile
    getPath: func() {
        return "canvas://by-index/texture["~me._node.getIndex()~"]";
    },

    # Destructor
    #
    # releases associated canvas and makes this object unusable
    del: func {
        me._node.remove();
        me.parents = nil; # ensure all ghosts get destroyed
    }
};
