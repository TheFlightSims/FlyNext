# helper functions
# ==============================================================================

# creates (if necessary) and returns a property node from arg[0],
# which can be a property node already, or a property path
#
var _makeNode = func(n) {
	if (isa(n, props.Node))
		return n;
	else
		return props.globals.getNode(n, 1);
}


# PropertyElement
# ==============================================================================
# Baseclass for all property controlled elements/objects
#
var PropertyElement = {
  # Constructor
  #
  # @param node     Node to be used for element or vector [parent, type] for
  #                 creation of a new node with name type and given parent
  # @param id       ID/Name (Should be unique)
  new: func(node, id)
  {
    if (isvec(node)) {
      var node = _makeNode(node[0]).addChild(node[1], 0, 0);
    }
    else {
      var node = _makeNode(node);
    }

    if( !isa(node, props.Node) )
      return debug.warn("Not a props.Node!");

    var m = {
      parents: [PropertyElement],
      _node: node
    };

    if( id != nil )
      m.set("id", id);

    return m;
  },
  # Destructor (has to be called manually!)
  del: func()
  {
    me._node.remove();
  },
  set: func(key, value)
  {
    me._node.getNode(key, 1).setValue(value);
    return me;
  },
  setBool: func(key, value)
  {
    me._node.getNode(key, 1).setBoolValue(value);
    return me;
  },
  setDouble: func(key, value)
  {
    me._node.getNode(key, 1).setDoubleValue(value);
    return me;
  },
  setInt: func(key, value)
  {
    me._node.getNode(key, 1).setIntValue(value);
    return me;
  },
  get: func(key, default = nil)
  {
    var node = me._node.getNode(key);
    if( node != nil )
      return node.getValue();
    else
      return default;
  },
  getBool: func(key)
  {
    me._node.getNode(key, 1).getBoolValue();
  },
  # Trigger an update of the element
  #
  # Elements are automatically updated once a frame, with a delay of one frame.
  # If you wan't to get an element updated in the current frame you have to use
  # this method.
  update: func
  {
    me.setBool("update", 1);
  }
};
