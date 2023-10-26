#-------------------------------------------------------------------------------
# canvas.Element
#-------------------------------------------------------------------------------
# Baseclass for all elements on a canvas
#
var Element = {
    # Reference frames (for "clip" coordinates)
    GLOBAL: 0,
    PARENT: 1,
    LOCAL:    2,

    # Constructor
    #
    # @param ghost    Element ghost as retrieved from core methods
    new: func(ghost) {
        var obj = {
            parents: [Element, PropertyElement, ghost],
            _node: props.wrapNode(ghost._node_ghost),
        };
        return obj;
    },

    getType: func () {
        return me._node.getName();
    },    

    # Get parent group/element
    getParent: func() {
        var parent_ghost = me._getParent();
        if (parent_ghost == nil)
            return nil;

        var type = props.wrapNode(parent_ghost._node_ghost).getName();
        var factory = Group._getFactory(type);
        if (factory == nil)
            return parent_ghost;

        return factory(parent_ghost);
    },

    # Get the canvas this element is placed on
    getCanvas: func() {
        wrapCanvas(me._getCanvas());
    },

    # Check if elements represent same instance
    #
    # @param el Other Element or element ghost
    equals: func(el) {
        return me._node.equals(el._node_ghost);
    },

    # Hide/Show element
    #
    # @param visible    Whether the element should be visible
    setVisible: func(visible = 1) {
        me.setBool("visible", visible);
        return me;
    },

    getVisible: func {
        me.getBool("visible")
    },

    # Hide element (Shortcut for setVisible(0))
    hide: func {
        me.setVisible(0);
    },

    # Show element (Shortcut for setVisible(1))
    show: func {
        me.setVisible(1);
    },

    # Toggle element visibility
    toggleVisibility: func {
        me.setVisible(!me.getVisible());
    },

    setGeoPosition: func(lat, lon) {
        me._getTf().setGeoPosition(lat, lon);
        return me;
    },

    # Create a new transformation matrix
    #
    # @param vals Default values (Vector of 6 elements)
    createTransform: func(vals = nil) {
        # tf[0] is reserved for setRotation, so min. index 1 is used here
        var node = me._node.addChild("tf", 1);
        return Transform.new(node, vals);
    },

    # Shortcut for setting translation
    setTranslation: func {
        me._getTf().setTranslation(arg);
        return me;
    },

    # Get translation set with #setTranslation
    getTranslation: func() {
        if (me["_tf"] == nil) {
            return [0, 0];
        }
        return me._tf.getTranslation();
    },

    # Set rotation around transformation center (see #setCenter).
    #
    # @note This replaces the the existing transformation. For additional scale
    # or translation use additional transforms (see #createTransform).
    setRotation: func(rot) {
        if (me["_tf_rot"] == nil) {
            # always use the first matrix slot to ensure correct rotation
            # around transformation center.
            # tf-rot-index can be set to change the slot to be used. This is used for
            # example by the SVG parser to apply the rotation after all
            # transformations defined in the SVG file.
            me["_tf_rot"] = Transform.new(
                me._node.getNode("tf["~me.get("tf-rot-index", 0)~"]", 1)
            );
        }
        me._tf_rot.setRotation(rot, me.getCenter());
        return me;
    },

    # Shortcut for setting scale
    setScale: func {
        me._getTf().setScale(arg);
        return me;
    },

    # Shortcut for getting scale
    getScale: func {
        me._getTf().getScale();
    },

    # Set the fill/background/boundingbox color
    #
    # @param color    Vector of 3 or 4 values in [0, 1]
    setColorFill: func {
        me.set("fill", _getColor(arg));
    },

    getColorFill: func {
        me.get("fill");
    },

    getTransformedBounds: func {
        me.getTightBoundingBox();
    },

    # Calculate the transformation center based on bounding box and center-offset
    updateCenter: func {
        me.update();
        var bb = me.getTightBoundingBox();

        if (bb[0] > bb[2] or bb[1] > bb[3]) {
            return;
        }

        me._setupCenterNodes(
            (bb[0] + bb[2]) / 2 + (me.get("center-offset-x") or 0),
            (bb[1] + bb[3]) / 2 + (me.get("center-offset-y") or 0));
        return me;
    },

    # Set transformation center (currently only used for rotation)
    setCenter: func() {
        var center = _arg2valarray(arg);
        if (size(center) != 2){ return debug.warn("invalid arg"); }
        me._setupCenterNodes(center[0], center[1]);
        return me;
    },

    # Get transformation center
    getCenter: func() {
        var center = [0, 0];
        me._setupCenterNodes();

        if (me._center[0] != nil) {
            center[0] = me._center[0].getValue() or 0;
        }
        if (me._center[1] != nil) {
            center[1] = me._center[1].getValue() or 0;
        }
        return center;
    },
    
    # Set size in pixels
    # Use either with x, y size:
    #     e.setSize(<x>, <y>)
    # or with a vector containing x, y:
    #     e.setSize([<x>, <y>])
    setSize: func {
        if (size(arg) == 1) {
            var (x, y) = arg[0];
        } else {
        	var (x, y) = arg;
        }
        var (sx, sy) = me.getScale();
        var (curx, cury) = me.getSize();
        me.setScale(x / (curx / sy), y / (cury / sy));
    },

    #return vector [sx, sy] with dimensions of bounding box
    getSize: func {
        var bb = me.getTightBoundingBox();
        return [bb[2] - bb[0], bb[3] - bb[1]];
    },

    # convert bounding box vector into clip string (yes, different order)
    boundingbox2clip: func(bb) {
        return sprintf("rect(%d,%d,%d,%d)", bb[1], bb[2], bb[3], bb[0]);
    },

    # set clip by bounding box
    # bounding_box: [xmin, ymin, xmax, ymax]
    setClipByBoundingBox: func(bounding_box, clip_frame = nil) {
        if (clip_frame == nil) { clip_frame = Element.PARENT; }
        me.set("clip", me.boundingbox2clip(bounding_box));
        me.set("clip-frame", clip_frame);
        return me;
    },

    # set clipping by bounding box of another element
    setClipByElement: func(clip_elem) {
        clip_elem.update();
        var bounds = clip_elem.getTightBoundingBox();
        me.setClipByBoundingBox(bounds, canvas.Element.PARENT);
    },

    # Internal Transform for convenience transform functions
    _getTf: func {
        if (me["_tf"] == nil) { me["_tf"] = me.createTransform(); }
        return me._tf;
    },

    _setupCenterNodes: func(cx = nil, cy = nil) {
        if (me["_center"] == nil or (size(me._center) >= 1 and me._center[0] == nil) or (size(me._center) >= 2 and me._center[1] == nil)) {
            me["_center"] = [me._node.getNode("center[0]", cx != nil),
                             me._node.getNode("center[1]", cy != nil)];
        }
        if (cx != nil) {
            me._center[0].setDoubleValue(cx);
        }
        if (cy != nil) {
            me._center[1].setDoubleValue(cy);
        }
    },
};
