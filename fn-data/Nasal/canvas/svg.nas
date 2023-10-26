# Parse an xml file into a canvas group element
#
# @param group    The canvas.Group instance to append the parsed elements to
# @param path     The path of the svg file (absolute or relative to FG_ROOT)
# @param options  Optional hash of options
#                 font-mapper  func
#                 parse_images bool
var parsesvg = func(group, path, options = nil)
{
  if( !isa(group, Group) )
    die("Invalid argument group (type != Group)");

  if( options == nil )
    options = {};

  if (!ishash(options)) {
    die("Options need to be of type hash!");
  }

  # resolve paths using standard SimGear logic
  var file_path = resolvepath(path);
  if (file_path == "")
    die("File not found: "~path);
  path = file_path;

  
  var logpr = func(level, msg)
  {
    logprint(level, "parsesvg: "~msg~" [path='"~ path~"']");
  };

  # Helper to get number without unit (eg. px)
  var evalCSSNum = func(css_num)
  {
    if( css_num.ends_with("px") )
      return substr(css_num, 0, size(css_num) - 2);
    else if( css_num.ends_with("%") )
      return substr(css_num, 0, size(css_num) - 1) / 100;

    return css_num;
  }

  var level = 0;
  var skip  = 0;
  var stack = [group];
  var close_stack = []; # helper for check tag closing

  var defs_stack = [];

  var text = nil;
  var tspans = nil;

  # lookup table for element ids (for <use> element)
  var id_dict = {};

  # lookup table for mask and clipPath element ids
  var clip_dict = {};
  var cur_clip = nil;

  # ----------------------------------------------------------------------------
  # Create a new child an push it onto the stack
  var pushElement = func(type, id = nil)
  {
    append(stack, stack[-1].createChild(type, id));
    append(close_stack, level);

    if (isscalar(id) and size(id)) {
      id_dict[ id ] = stack[-1];
    }

    if( cur_clip != nil )
    {
      if(cur_clip['x'] != nil and cur_clip['y'] != nil
         and cur_clip['width'] != nil and cur_clip['height'] != nil ) {
        stack[-1].setClipByBoundingBox(cur_clip['x'], cur_clip['y'],
           cur_clip['x'] + cur_clip['width'], cur_clip['y'] + cur_clip['height']);
      }
      else {
        logpr(LOG_WARN, "Invalid or unsupported clip for element '" ~ id ~ "'");
      }
      cur_clip = nil;
    }
  }

  # ----------------------------------------------------------------------------
  # Remove the topmost element from the stack
  var popElement = func
  {
    stack[-1].updateCenter();
    # Create rotation matrix after all SVG defined transformations
    stack[-1].set("tf-rot-index", stack[-1].createTransform()._node.getIndex());

    pop(stack);
    pop(close_stack);
  }

  # ----------------------------------------------------------------------------
  # Parse a transformation (matrix)
  # http://www.w3.org/TR/SVG/coords.html#TransformAttribute
  var parseTransform = func(tf)
  {
    if( tf == nil )
      return;

    var end = 0;
    while(1)
    {
      var start_type = tf.find_first_not_of("\t\n ", end);
      if( start_type < 0 )
        break;

      var end_type = tf.find_first_of("(\t\n ", start_type + 1);
      if( end_type < 0 )
        break;

      var start_args = tf.find('(', end_type);
      if( start_args < 0 )
        break;

      var values = [];
      end = start_args + 1;
      while(1)
      {
        var start_num = tf.find_first_not_of(",\t\n ", end);
        if( start_num < 0 )
          break;
        if( tf[start_num] == `)` )
          break;

        end = tf.find_first_of("),\t\n ", start_num + 1);
        if( end < 0 )
          break;
        append(values, substr(tf, start_num, end - start_num));
      }

      if( end > 0 )
        end += 1;

      var type = substr(tf, start_type, end_type - start_type);

      # TODO should we warn if to much/wrong number of arguments given?
      if( type == "translate" )
      {
        # translate(<tx> [<ty>]), which specifies a translation by tx and ty. If
        # <ty> is not provided, it is assumed to be zero.
        stack[-1].createTransform().setTranslation
        (
          values[0],
          size(values) > 1 ? values[1] : 0,
        );
      }
      else if( type == "scale" )
      {
        # scale(<sx> [<sy>]), which specifies a scale operation by sx and sy. If
        # <sy> is not provided, it is assumed to be equal to <sx>.
        stack[-1].createTransform().setScale(values);
      }
      else if( type == "rotate" )
      {
        # rotate(<rotate-angle> [<cx> <cy>]), which specifies a rotation by
        # <rotate-angle> degrees about a given point.
        stack[-1].createTransform().setRotation
        (
          values[0] * D2R, # internal functions use rad
          size(values) > 1 ? values[1:] : nil
        );
      }
      else if( type == "matrix" )
      {
        if( size(values) == 6 )
          stack[-1].createTransform(values);
        else
          logpr(LOG_WARN,
            "Invalid arguments to matrix transform: " ~ debug.string(values, 0)
          );
      }
      else
        logpr(LOG_WARN, "Unknown transform type: '" ~ type ~ "'");
    }
  };

  # ----------------------------------------------------------------------------
  # Parse a path
  # http://www.w3.org/TR/SVG/paths.html#PathData

  # map svg commands OpenVG commands
  var cmd_map = {
    z: Path.VG_CLOSE_PATH,
    m: Path.VG_MOVE_TO,
    l: Path.VG_LINE_TO,
    h: Path.VG_HLINE_TO,
    v: Path.VG_VLINE_TO,
    q: Path.VG_QUAD_TO,
    c: Path.VG_CUBIC_TO,
    t: Path.VG_SQUAD_TO,
    s: Path.VG_SCUBIC_TO
  };

  var parsePath = func(path_data)
  {
    if( path_data == nil )
      return;

    var pos = 0;
    var cmds = [];
    var coords = [];

    while(1)
    {
      # skip leading spaces
      pos = path_data.find_first_not_of("\t\n ", pos);
      if( pos < 0 )
        break;

      # get command (single character);
      var cmd = substr(path_data, pos, 1);
      pos += 1;

      # and get all following arguments
      # the '-' is kind of hard, it belongs to a number, might appear twice in 
      # one arg (e.g. -2e-3) and some SVG do not separate args starting with '-'
      # so the '-' is the separator as well in this case.
      # SVG samples (cut)
      # 1: m 547.56916,962.17731 c 10e-6,25.66886 -20.80872,46.47759 -46.47758,46.47759 -25.66886,0 ...
      # 2: M831,144.861c-0.236,0.087-0.423,0.255-0.629,0.39c-1.169,0.765-2.333,1.536-3.499,2.305   c-0.019,0.013-0.041, ...
      var args = [];
      #skip non-argument spaces and separator
      pos = path_data.find_first_not_of(",\t\n ", pos);
      var start_num = pos;
      while(1)
      {
        pos = path_data.find_first_not_of(",\t\n ", pos);
        if (pos < 0) break;
        start_num = pos;        
        while (1) {
          var chr1 = substr(path_data, pos, 1);
          if (chr1 == "-")
            pos = path_data.find_first_not_of("e.0123456789", pos + 1);
          else 
            pos = path_data.find_first_not_of("e.0123456789", pos);
          #check for e- (e.g. 42e-6)
          if (pos > 0 and substr(path_data, pos - 1, 1) == "e" 
                      and substr(path_data, pos, 1) == "-")
            continue;
          else 
            break;
        }
        if (start_num == pos) break;

        append(args, substr( path_data,
                             start_num,
                             pos > 0 ? pos - start_num : nil ));
      }

      # now execute the command
      var rel = string.islower(cmd[0]);
      var cmd = string.lc(cmd);
      if( cmd == 'a' )
      {
        for(var i = 0; i + 7 <= size(args); i += 7)
        {
          # SVG: (rx ry x-axis-rotation large-arc-flag sweep-flag x y)+
          # OpenVG: rh,rv,rot,x0,y0
          if( args[i + 3] )
            var cmd_vg = args[i + 4] ? Path.VG_LCWARC_TO : Path.VG_LCCWARC_TO;
          else
            var cmd_vg = args[i + 4] ? Path.VG_SCWARC_TO : Path.VG_SCCWARC_TO;
          append(cmds, rel ? cmd_vg + 1: cmd_vg);
          append(coords, args[i],
                         args[i + 1],
                         args[i + 2],
                         args[i + 5],
                         args[i + 6] );
        }

        if( math.mod(size(args), 7) > 0 ) {
          logpr(LOG_WARN, "Invalid number of coords for cmd 'a' ("~
            size(args)~" mod 7 != 0)");
        }
      }
      else
      {
        var cmd_vg = cmd_map[cmd];
        if( cmd_vg == nil )
        {
          logpr(LOG_WARN, "command not found: '" ~ cmd ~ "'");
          continue;
        }

        var num_coords = Path.num_coords[int(cmd_vg)];
        if( num_coords == 0 )
          append(cmds, cmd_vg);
        else
        {
          for(var i = 0; i + num_coords <= size(args); i += num_coords)
          {
            append(cmds, rel ? cmd_vg + 1: cmd_vg);
            for(var j = i; j < i + num_coords; j += 1)
              append(coords, args[j]);

            # If a moveto is followed by multiple pairs of coordinates, the
            # subsequent pairs are treated as implicit lineto commands.
            if( cmd == 'm' )
              cmd_vg = cmd_map['l'];
          }

          if( math.mod(size(args), num_coords) > 0 )
            logpr(LOG_WARN,"Invalid number of coords for cmd '" ~ cmd ~ "' ("
              ~size(args)~" mod "~num_coords~" != 0)"
            );
        }
      }
    }

    stack[-1].setData(cmds, coords);
  };

  # ----------------------------------------------------------------------------
  # Parse text styles (and apply them to the topmost element)
  var parseTextStyles = func(style)
  {
    # http://www.w3.org/TR/SVG/text.html#TextAnchorProperty
    var h_align = style["text-anchor"];
    if( h_align != nil )
    {
      if( h_align == "end" )
        h_align = "right";
      else if( h_align == "middle" )
        h_align = "center";
      else # "start"
        h_align = "left";
      stack[-1].set("alignment", h_align ~ "-baseline");
    }
    # TODO vertical align

    var fill = style['fill'];
    if( fill != nil )
      stack[-1].set("fill", fill);

    var font_family = style["font-family"];
    var font_weight = style["font-weight"];
    var font_style = style["font-style"];
    if( font_family != nil or font_weight != nil or font_style != nil )
      stack[-1].set("font", font_mapper(font_family, font_weight, font_style, options));

    var font_size = style["font-size"];
    if( font_size != nil )
      stack[-1].setDouble("character-size", evalCSSNum(font_size));

    var line_height = style["line-height"];
    if( line_height != nil )
      stack[-1].setDouble("line-height", evalCSSNum(line_height));
  }

  # ----------------------------------------------------------------------------
  # Parse a css style attribute
  var parseStyle = func(style)
  {
    if( style == nil )
      return {};

    var styles = {};
    foreach(var part; split(';', style))
    {
      if( !size(part = string.trim(part)) )
        continue;
      if( size(part = split(':',part)) != 2 )
        continue;

      var key = string.trim(part[0]);
      if( !size(key) )
        continue;

      var value = string.trim(part[1]);
      if( !size(value) )
        continue;

      styles[key] = value;
    }

    return styles;
  }

  # ----------------------------------------------------------------------------
  # Parse a css color
  var parseColor = func(s)
  {
    var color = [0, 0, 0];
    if( s == nil )
      return color;

    if( size(s) == 7 and substr(s, 0, 1) == '#' )
    {
      return [ std.stoul(substr(s, 1, 2), 16) / 255,
                std.stoul(substr(s, 3, 2), 16) / 255,
                std.stoul(substr(s, 5, 2), 16) / 255 ];
    }

    return color;
  };

  # ----------------------------------------------------------------------------
  # XML parsers element open callback
  var start = func(name, attr)
  {
    level += 1;

    if( skip )
      return;

    if( level == 1 )
    {
      if( name != 'svg' )
        die("Not an svg file (root=" ~ name ~ ")");
      else
        return;
    }

    if( size(defs_stack) > 0 )
    {
      if( name == "mask" or name == "clipPath" )
      {
        append(defs_stack, {'type': name, 'id': attr['id']});
      }
      else if( ishash(defs_stack[-1]) and name == "rect" )
      {
        foreach(var p; ["x", "y", "width", "height"])
          defs_stack[-1][p] = evalCSSNum(attr[p]);
        skip = level;
      }
      else
      {
        logpr(LOG_INFO, "Skipping unknown element in <defs>: <" ~ name ~ ">");
        skip = level;
      }
      return;
    }

    var style = parseStyle(attr['style']);

    var clip_id = attr['clip-path'] or attr['mask'];
    if( clip_id != nil and clip_id != "none" )
    {
      if(     clip_id.starts_with("url(#")
          and clip_id[-1] == `)` )
        clip_id = substr(clip_id, 5, size(clip_id) - 5 - 1);

      cur_clip = clip_dict[clip_id];
      if( cur_clip == nil )
        logpr(LOG_WARN, "Clip not found: '" ~ clip_id ~ "'");
    }

    if( style['display'] == 'none' )
    {
      skip = level;
      return;
    }
    else if( name == "g" )
    {
      pushElement('group', attr['id']);
    }
    else if( name == "text" )
    {
      text = {
        "attr": attr,
        "style": style,
        "text": ""
      };
      tspans = [];
      return;
    }
    else if( name == "tspan" )
    {
      append(tspans, {
        "attr": attr,
        "style": style,
        "text": ""
      });
      return;
    }
    else if( name == "path" or name == "rect" or name == "circle" or name == "ellipse")
    {
      pushElement('path', attr['id']);

      if( name == "rect" )
      {
        var width = evalCSSNum(attr['width']);
        var height = evalCSSNum(attr['height']);
        var x = evalCSSNum(attr['x']);
        var y = evalCSSNum(attr['y']);
        var rx = attr['rx'];
        var ry = attr['ry'];

        if( ry == nil )
          ry = rx;
        else if( rx == nil )
          rx = ry;

        var cfg = {};
        if( rx != nil )
          cfg["border-radius"] = [evalCSSNum(rx), evalCSSNum(ry)];

        stack[-1].rect(x, y, width, height, cfg);
      }
      if (name == "circle") {
        var cx = evalCSSNum(attr['cx']);
        var cy = evalCSSNum(attr['cy']);
        var r = evalCSSNum(attr['r']);
        stack[-1].circle(r, cx, cy);
      }
      if (name == "ellipse") {
        var cx = evalCSSNum(attr['cx']);
        var cy = evalCSSNum(attr['cy']);
        var rx = evalCSSNum(attr['rx']);
        var ry = evalCSSNum(attr['ry']);
        stack[-1].ellipse(rx, ry, cx, cy);
      }
      if (name == "path") {
        parsePath(attr['d']);
      }

      var fill = style['fill'];
      if( fill != nil )
        stack[-1].set('fill', fill);

      var fill_opacity = style['fill-opacity'];
      if( fill_opacity != nil)
        stack[-1].setDouble('fill-opacity', fill_opacity);

      var stroke = style['stroke'];
      if( stroke != nil )
        stack[-1].set('stroke', stroke);

      var stroke_opacity = style['stroke-opacity'];
      if( stroke_opacity != nil)
        stack[-1].setDouble('stroke-opacity', stroke_opacity);

      var w = style['stroke-width'];
      stack[-1].setStrokeLineWidth( w != nil ? evalCSSNum(w) : 1 );

      var linecap = style['stroke-linecap'];
      if( linecap != nil )
        stack[-1].setStrokeLineCap(style['stroke-linecap']);

      var linejoin = style['stroke-linejoin'];
      if( linejoin != nil )
        stack[-1].setStrokeLineJoin(style['stroke-linejoin']);

      # http://www.w3.org/TR/SVG/painting.html#StrokeDasharrayProperty
      var dash = style['stroke-dasharray'];
      if( dash and size(dash) > 3 )
        # at least 2 comma separated values...
        stack[-1].setStrokeDashArray(split(',', dash));
    } #end path/rect/ellipse/circle
    else if( name == "use" )
    {
      var ref = attr["xlink:href"];
      if( ref == nil or size(ref) < 2 or ref[0] != `#` )
        return logpr(LOG_WARN, "Invalid or missing href: '" ~ ref ~ "'");

      var el_src = id_dict[ substr(ref, 1) ];
      if( el_src == nil )
        return logpr(LOG_WARN, "Reference to unknown element '" ~ ref ~ "'");

      # Create new element and copy sub branch from source node
      pushElement(el_src._node.getName(), attr['id']);
      props.copy(el_src._node, stack[-1]._node);

      # copying also overrides the id so we need to set it again
      stack[-1]._node.getNode("id").setValue(attr['id']);
    }
    else if( name == "defs" )
    {
      append(defs_stack, "defs");
      return;
    }
    else if (name == "image" and options["parse_images"])
    {
      var ref = attr["xlink:href"];
      # ref must not be missing and shall not contain Windows path separator
      # find("\\") is correct, backslash is control character and must be escaped
      # by adding another backslash - otherwise parse error anywhere below 
      if (ref == nil or find("\\", ref) > -1)
      {
        return logpr(LOG_WARN, "Invalid or missing href in image tag: '" ~ ref ~ "'");
      }
      if (substr(ref, 0, 5) == "data:") {
        return logpr(LOG_WARN, "Unsupported embedded image");
      }
      elsif (substr(ref, 0, 5) != "file:") {
        # absolute paths seem to start with "file:"
        # prepend relative paths with the path of SVG file and hope the image is there
        # file access limitations apply
        ref = io.dirname(path) ~ ref;
      }
      pushElement("image", attr["id"]);

      if (attr["x"] != nil and attr["y"] != nil) {
        stack[-1].createTransform().setTranslation(attr["x"], attr["y"]);
      }
      if (attr["width"] != nil and attr["height"] != nil) {
        stack[-1].setSize(attr["width"], attr["height"]);
      }
      stack[-1].setFile(ref);
    }
    elsif (name == "sodipodi:namedview" or name == "metadata") 
    {
      # silently skip these
      skip = level;
      return;
    }
    else
    {
      logpr(LOG_INFO, "Skipping unknown element '" ~ name ~ "'");
      skip = level;
      return;
    }

    parseTransform(attr['transform']);

    var cx = attr['inkscape:transform-center-x'];
    if( cx != nil and cx != 0 )
      stack[-1].setDouble("center-offset-x", evalCSSNum(cx));

    var cy = attr['inkscape:transform-center-y'];
    if( cy != nil and cy != 0 )
      stack[-1].setDouble("center-offset-y", -evalCSSNum(cy));
  };

  # XML parsers element close callback
  var end = func(name)
  {
    level -= 1;

    if( skip )
    {
      if( level < skip )
        skip = 0;
      return;
    }

    if( size(defs_stack) > 0 )
    {
      if( name != "defs" )
      {
        var type = defs_stack[-1]['type'];
        if( type == "mask" or type == "clipPath" )
          clip_dict[defs_stack[-1]['id']] = defs_stack[-1];
      }

      pop(defs_stack);
      return;
    }

    if( size(close_stack) and (level + 1) == close_stack[-1] )
      popElement();

    if( name == "text" )
    {
      # Inkscape/SVG text is a bit complicated. If we only got a single tspan
      # or text without tspan we create just a single canvas.Text, otherwise
      # we create a canvas.Group with a canvas.Text as child for each tspan.
      # We need to take care to apply the transform attribute of the text
      # element to the correct canvas element, and also correctly inherit
      # the style properties.
      var character_size = 24;
      if( size(tspans) > 1 )
      {
        pushElement('group', text.attr['id']);
        parseTextStyles(text.style);
        parseTransform(text.attr['transform']);

        character_size = stack[-1].get("character-size", character_size);
      }

      # Helper for getting first number in space separated list of numbers.
      var first_num = func(str)
      {
        if( str == nil )
          return 0;
        var end = str.find_first_of(" \n\t");
        if( end < 0 )
          return str;
        else
          return substr(str, 0, end);
      }

      var line = 0;
      foreach(var tspan; tspans)
      {
        # Always take first number and ignore individual character placment
        var x = first_num(tspan.attr['x'] or text.attr['x']);
        var y = first_num(tspan.attr['y'] or text.attr['y']);

        # Sometimes Inkscape forgets writing x and y coordinates and instead
        # just indicates a multiline text with sodipodi:role="line".
        if( tspan.attr['y'] == nil and tspan.attr['sodipodi:role'] == "line" )
          # TODO should we combine multiple lines into a single text separated
          #      with newline characters?
          y += line
             * stack[-1].get("line-height", 1.25)
             * stack[-1].get("character-size", character_size);

        # Use id of text element with single tspan child, fall back to id of
        # tspan if text has no id.
        var id = text.attr['id'];
        if( id == nil or size(tspans) > 1 )
          id = tspan.attr['id'];

        pushElement('text', id);
        stack[-1].setText(tspan.text);

        if( x != 0 or y != 0 )
          stack[-1].createTransform().setTranslation(x, y);

        if( size(tspans) == 1 )
        {
          parseTextStyles(text.style);
          parseTransform(text.attr['transform']);
        }

        parseTextStyles(tspan.style);
        popElement();

        line += 1;
      }

      if( size(tspans) > 1 )
        popElement();

      text = nil;
      tspans = nil;
    }
  }; #end()

  # XML parsers element data callback
  var data = func(data)
  {
    if( skip )
      return;

    if( size(data) and tspans != nil )
    {
      if( size(tspans) == 0 )
        # If no tspan is found use text element itself
        append(tspans, text);

      # If text contains xml entities it gets split at each entity. So let's
      # glue it back into a single text...
      tspans[-1]["text"] ~= data;
    }
  };

  call(func parsexml(path, start, end, data), nil, var err = []);
  if( size(err) )
  {
    logpr(LOG_ALERT, "parse XML failed");
    debug.printerror(err);
    return 0;
  }

  return 1;
}
