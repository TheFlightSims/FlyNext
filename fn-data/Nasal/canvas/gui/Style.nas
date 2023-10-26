gui.Style = {
  new: func(name, name_icon_theme)
  {
    var root_node = props.globals.getNode("/sim/gui/canvas", 1)
                                 .addChild("style");
    var gui_path = getprop("/sim/fg-root") ~ "/gui";
    var style_path = gui_path ~ "/styles/" ~ name;

    var m = {
      parents: [gui.Style],
      _path: style_path,
      _dir_icons: gui_path ~ "/icons/" ~ name_icon_theme,
      _node: io.read_properties(style_path ~ "/style.xml", root_node),
      _colors: {},
      _sizes: {}
    };

    # parse theme colors
    var colors = m._node.getChild("colors");
    if( colors != nil )
    {
      foreach(var color; colors.getChildren())
      {
        var tintNode = color.getChild("tint");
        var shadeNode = color.getChild("shade");
        var baseNode = color.getChild("base");

        if (tintNode and baseNode) {
          
        } elsif (shadeNode and baseNode) {

        } else {
          # todo : support a CSS style color as a direct text child,
          # instead of seperate RGBA components
          m._colors[ color.getName() ] = m._parseRGBANodes(color);
        }
      }
    }

    var sizes = m._node.getChild("sizes");
    if (sizes) {
      foreach(var sizeNode; sizes.getChildren()) {
          var factorNode = sizeNode.getChild("factor");
          var baseNode = sizeNode.getChild("base");
          if (factorNode or baseNode) {
            var f = factorNode.getValue() or 1.0;
            m._sizes[sizeNode.getName()] = f * m.getSize(baseNode.getValue(), 1.0);
          } else {
            # simple literal value, easy
            m._sizes[sizeNode.getName()] = sizeNode.getValue();
          }
      } # of sizes iteration
    }

    m._dir_decoration =
      m._path ~ "/" ~ (m._node.getValue("folders/decoration") or "decoration");
    m._dir_widgets =
      m._path ~ "/" ~ (m._node.getValue("folders/widgets") or "widgets");

    return m;
  },
  _parseRGBANodes: func(color)
  {
    var comp_names = ["red", "green", "blue", "alpha"];
    var str = "rgba(";
    for(var i = 0; i < size(comp_names); i += 1)
    {
      if( i > 0 )
        str ~= ",";
      var val = color.getValue(comp_names[i]);
      if( val == nil )
        val = 1;
      if( i < 3 )
        str ~= int(val * 255 + 0.5);
      else
        str ~= int(val * 100) / 100;
    }
    return str ~ ")";
  },

  getColor: func(name, def = "#00ffff")
  {
    return me._colors[name] or def;
  },
  getSize: func(name, def = 1.0) 
  {
    return me._sizes[name] or def;
  }
};
