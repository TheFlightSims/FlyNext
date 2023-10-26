#-------------------------------------------------------------------------------
# canvas.Group
#-------------------------------------------------------------------------------
# Class for a group element on a canvas
#
var Group = {
    new: func(ghost) {
        var obj = {
            parents: [Group, Element.new(ghost)],
        };
        return obj;
    },

    # Create a child of given type with specified id.
    # type can be group, text
    createChild: func(type, id = nil) {
        var ghost = me._createChild(type, id);
        var factory = me._getFactory(type);
        if (factory == nil) {
            return ghost;
        }
        return factory(ghost);
    },

    # Create multiple children of given type
    createChildren: func(type, count) {
        var factory = me._getFactory(type);
        if (factory == nil) {
            return [];
        }
        var nodes = props._addChildren(me._node._g, [type, count, 0, 0]);
        for (var i = 0; i < count; i += 1) {
            nodes[i] = factory(me._getChild(nodes[i]));
        }
        return nodes;
    },

    # Create a path child drawing a (rounded) rectangle
    #
    # @param x        Position of left border
    # @param y        Position of top border
    # @param w        Width
    # @param h        Height
    # @param cfg    Optional settings (eg. {"border-top-radius": 5})
    rect: func(x, y, w, h, cfg = nil) {
        return me.createChild("path").rect(x, y, w, h, cfg);
    },

    # Get a vector of all child elements
    getChildren: func() {
        var children = [];
        foreach(var c; me._node.getChildren()) {
            if (me._isElementNode(c)) {
                append(children, me._wrapElement(c));
            }
        }
        return children;
    },

    # Recursively get all children of class specified by first param
    getChildrenOfType: func(type, array = nil) {
        var children = array;
        if (children == nil) {
            children = [];
        }
        var my_children = me.getChildren();
        if (!isvec(type)) {
            type = [type];
        }
        foreach(var c; my_children) {
            foreach(var t; type) {
                if (isa(c, t)) {
                    append(children, c);
                }
            }
            if (isa(c, canvas.Group)) {
                c.getChildrenOfType(type, children);
            }
        }
        return children;
    },

    # Set color to children of type Path and Text. It is possible to optionally
    # specify which types of children should be affected by passing a vector as
    # the last agrument, ie. my_group.setColor(1,1,1,[Path]);
    setColor: func() {
        var color = arg;
        var types = [Path, Text];
        var arg_c = size(color);
        if (arg_c > 1 and isvec(color[-1])) {
            types = color[-1];
            color = subvec(color, 0, arg_c - 1);
        }
        var children = me.getChildrenOfType(types);
        if (isvec(color)) {
            var first = color[0];
            if (isvec(first)) {
                color = first;
            }
        }
        foreach(var c; children) {
            c.setColor(color);
        }
    },

    # Get first child with given id (breadth-first search)
    #
    # @note Use with care as it can take several miliseconds (for me eg. ~2ms).
    #             TODO check with new C++ implementation
    getElementById: func(id) {
        var ghost = me._getElementById(id);
        if (ghost == nil) { return nil; }

        var node = props.wrapNode(ghost._node_ghost);
        var factory = me._getFactory(node.getName());
        if (factory == nil) { return ghost; }
        return factory(ghost);
    },

    # Remove all children
    removeAllChildren: func() {
        foreach(var type; keys(me._element_factories)) {
            me._node.removeChildren(type, 0);
        }
        return me;
    },

    # private:
    # element nodes have type NONE and valid element names (those in the factory
    # list)
    _isElementNode: func(el) {
        return el.getType() == "NONE" and me._element_factories[el.getName()] != nil;
    },

    # Create element from existing node
    _wrapElement: func(node) {
        var factory = me._getFactory(node.getName());
        return factory(me._getChild(node._g));
    },

    _getFactory: func(type) {
        var factory = me._element_factories[type];
        if (factory == nil) {
            logprint(DEV_ALERT, "canvas.Group.createChild(): unknown type ("~type~")");
        }
        return factory;
    }
};
