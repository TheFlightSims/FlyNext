var Tooltip = {
  # default delay (in seconds)
  DELAY: 4.0,
  # Constructor
  #
  # @param size ([width, height])
  new: func(size, id = nil)
  {
    var m = {
      parents: [Tooltip, PropertyElement.new(["/sim/gui/canvas", "window"], id)],
      _listeners: [],
      _properties: [],
      _mapping: "",
      _mappingFunc: nil,
      _width: 0,
      _height: 0,
      _tipId: nil,
      _isMessage: 0,
      _slice: 17,
      _measureText: nil,
      _measureBB: nil,
      _hideTimer: nil,
      _hiding: nil
    };

    m.setInt("size[0]", size[0]);
    m.setInt("size[1]", size[1]);
    m.setBool("visible", 0);
    m.setInt("z-index", gui.STACK_INDEX["tooltip"]);

    m._hideTimer = maketimer(m.DELAY, m, Tooltip._hideTimeout);
    m._hideTimer.singleShot = 1;

    return m;
  },
  # Destructor
  del: func
  {
    me.parents[1].del();
    if( me["_canvas"] != nil )
      me._canvas.del();
  },
  # Create the canvas to be used for this Tooltip
  #
  # @return The new canvas
  createCanvas: func()
  {
    var size = [
      me.get("size[0]"),
      me.get("size[1]")
    ];

    me._canvas = new({
      size: [2 * size[0], 2 * size[1]],
      view: size,
      placement: {
        type: "window",
        index: me._node.getIndex()
      },
      name: "Tooltip"
    });

    # don't do anything with mouse events ourselves
    me.set("capture-events", 0);
    me.set("fill", "rgba(255,255,255,0.8)");

    # transparent background
    me._canvas.setColorBackground(0.0, 0.0, 0.0, 0.0);

    var root = me._canvas.createGroup();
    me._root = root;

    me._frame =
      root.createChild("image", "background")
          .set("src", "gui/images/tooltip.png")
          .set("slice", me._slice ~ " fill")
          .setSize(size);

    me._text =
      root.createChild("text", "tooltip-caption")
          .setText("Aircraft Help")
          .setAlignment("left-top")
          .setFontSize(14)
          .setFont("LiberationFonts/LiberationSans-Bold.ttf")
          .setColor(1,1,1)
          .setDrawMode(Text.TEXT)
          .setTranslation(me._slice, me._slice)
          .setMaxWidth(size[0]);

    return me._canvas;
  },

  setLabel: func(msg)
  {
    me._label = msg;
    me._updateText();
  },

  setProperties: func(properties)
  {
    foreach(var l; me._listeners) {
      removelistener(l);
    }
    me._listeners = [];
    me._properties = properties;
    foreach(var p; me._properties) {
      if (p != nil) {
        var l = setlistener(p, func { me._updateText(); });
        append(me._listeners, l);
      }
    }
    me._updateText();
  },

  # specify a string used to compute the width of the tooltip
  setWidthText: func(txt)
  {
    me._measureBB = me._text.setText(txt)
                            .update()
                            .getBoundingBox();
    me._updateBounds();
  },

  _updateText: func
  {
    var msg = '';
    if (me._label != nil) {
      var args = [me._label];
      foreach(var p; me._properties) {
        var val = '';
        if (p != nil) val = p.getValue() or 0;
        
        # https://code.google.com/p/flightgear-bugs/issues/detail?id=1454
        # wrap mapping in 'call' to catch conversion errors
        var val_mapped = call(me._remapValue, [val], me, nil, var err = []);
        if( size(err) ) {
          logprint(LOG_WARN,
            "Tooltip: failed to remap " ~ debug.string(p, 0) ~ ":\n"
            ~ debug.string(err, 0)
          );
          val_mapped = '';
        }
        append(args, val_mapped);
      }

      msg = call( sprintf, args);
    }

    me._text.setText(msg);
    me._updateBounds();
  },

  _updateBounds: func
  {
    var max_width = me.get("size[0]") - 2 * me._slice;
    me._text.setMaxWidth(max_width);

    # compute the bounds
    var text_bb = me._text.update().getBoundingBox();
    var width = text_bb[2];
    var height = text_bb[3];

    if( me._measureBB != nil )
    {
      width = math.max(width, me._measureBB[2]);
      height = math.max(height, me._measureBB[3]);
    }

    if( width > max_width )
      width = max_width;

    me._width = width + 2 * me._slice;
    me._height = height + 2 * me._slice;
    me._frame.setSize(me._width, me._height)
             .update();
  },

  _remapValue: func(val)
  {
    if (me._mapping == "") return val;
    if (me._mapping == "percent") return math.round(val * 100);

    # TODO - translate me!
    if (me._mapping == "on-off") return (val == 1) ? "ON" : "OFF";
    if (me._mapping == "arm-disarm") return (val == 1) ? "ARMED" : "DISARMED";

    # provide both 'senses' of the flag here
    if (me._mapping == "up-down") return (val == 1) ? "UP" : "DOWN";
    if (me._mapping == "down-up") return (val == 1) ? "DOWN" : "UP";
    if (me._mapping == "open-close") return (val == 1) ? "OPEN" : "CLOSED";
    if (me._mapping == "close-open") return (val == 1) ? "CLOSED" : "OPEN";

    if (me._mapping == "heading") return geo.normdeg(val);
    if (me._mapping == "nasal") return me._mappingFunc(val);

    return val;
  },

  setMapping: func(mapping, f = nil)
  {
    me._mapping = mapping;
    me._mappingFunc = f;
    me._updateText();
  },

  setTooltipId: func(tipId)
  {
    me._tipId = tipId;
    if ((tipId != nil) and me._hiding) {
      me._hideTimer.stop();
      me._hiding = 0;
    }
  },

  getTooltipId: func { me._tipId; },

  # Get the displayed canvas
  getCanvas: func()
  {
    return me['_canvas'];
  },

  setPosition: func(x, y)
  {
    me.setInt("x", x + 10);
    me.setInt("y", y + 10);
  },

  isMessage: func()
  {
    return me._isMessage;
  },

  show: func()
  {
    # don't show if undefined
    if (me._tipId == nil) return;

    if (me._hiding) {
      me._hideTimer.stop();
      me._hiding = 0;
    }

    if (!me.isVisible()) {
      me.setBool("visible", 1);
    }
  },

  showMessage: func(timeout = nil, node = nil)
  {
    if(var y = me._haveNode(node, 'y') != nil ) {
      me.setInt("y", y);
    } else {
      me.setInt("y", getprop('/sim/startup/ysize') * 0.2);
    }
    if(var x = me._haveNode(node, 'x')  != nil) {
      me.setInt("x", x);
    } else {
      var screenW = getprop('/sim/startup/xsize');
      me.setInt("x", (screenW - me._width) * 0.5);
    }
    me._isMessage = 1;
    me.show();
    # https://code.google.com/p/flightgear-bugs/issues/detail?id=1273
    # when tooltip is shown for some other reason, ensure it stays for
    # the full delay (unless replaced). Don't allow the update-hover
    # code path to hide() with the shorter delay.
    me._hiding = 1;
    me._hideTimer.restart(timeout or me.DELAY);
  },

  _haveNode: func(node, key) {
    if(node == nil ) return nil;
    var value = num(node.getValue(key) );
    return value;
  },

  hide: func()
  {
    # this gets run repeatedly during mouse-moves
    if (me._hiding) return;
    me._hiding = 1;

    me._hideTimer.restart(0.5);
  },

  hideNow: func()
  {
    me._hideTimer.stop();
    me._hideTimeout();
  },

  isVisible: func
  {
    return me.getBool("visible");
  },

  fadeIn: func()
  {
    me.show();
  },

  fadeOut: func()
  {
    me.hide();
  },

# private:
  _hideTimeout: func()
  {
    me.setBool("visible", 0);
    me._hiding = 0;
  }
};

var tooltip = canvas.Tooltip.new([300, 100]);
tooltip.createCanvas();

var innerSetTooltip = func(node)
{
   tooltip.setLabel(nil);
   var propPaths0 = cmdarg().getChildren('property');
   var propPaths = [];
   foreach(var p; propPaths0) {
     var v = p.getValue();
     if (v != nil)  v = props.globals.getNode(v);
     append(propPaths, v);
   }
   tooltip.setProperties(propPaths);

   tooltip.setLabel(cmdarg().getNode('label').getValue());

   var measure = cmdarg().getNode('measure-text');
   if (measure != nil) {
       tooltip.setWidthText(measure.getValue());
   } else {
       tooltip.setWidthText(nil);
   }

   var mapping = cmdarg().getNode('mapping');
   if (mapping != nil) {
     var m = mapping.getValue();
     var f = nil;
     if (m == 'nasal') {
       f = compile(cmdarg().getNode('script').getValue());
     }

     tooltip.setMapping(m, f);
   } else {
     tooltip.setMapping(nil);
  }
}

var setTooltip = func(node)
{
  var tipId = cmdarg().getNode('tooltip-id').getValue();
  if (tooltip.getTooltipId() == tipId) {
    return; # nothing more to do
  }

  var x = cmdarg().getNode('x').getValue();
  var y = cmdarg().getNode('y').getValue();

  var screenHeight = getprop('/sim/startup/ysize');
  tooltip.setPosition(x, screenHeight - y);
  tooltip.setTooltipId(tipId);
  tooltip._isMessage = 0;

  innerSetTooltip(node);

  # don't actually show here, we do that response to tooltip-timeout
  # so this is just getting ready
}

var showTooltip = func(node)
{
  # this is driven by the mouse-move timeout from native code,
  # which is irrelevant for message tips
  if (tooltip.isMessage())
    return;

  var r = node.getNode("reason");
  if ((r != nil) and (r.getValue() == "click")) {
    # click triggering tooltip, show immediately
    tooltip.show();
  } else {
    tooltip.fadeIn();
  }
}

var updateHover = func(node)
{
  tooltip.setTooltipId(nil);

  # if not shown, nothing to do here
  if (!tooltip.isVisible()) return;

  # reset cursor to standard
  tooltip.fadeOut();

}

var showMessage = func(node)
{
  var msgId = node.getNode("id");
  tooltip.setTooltipId((msgId == nil) ? 'msg' : msgId.getValue());
  innerSetTooltip(node);

  var timeout = node.getNode("delay");
  tooltip.showMessage( timeout != nil ? timeout.getValue() : nil, node);
}

var clearMessage = func(node)
{
  var msgId = node.getNode("id");
  if (tooltip.getTooltipId() != msgId.getValue()) return;
  tooltip.hideNow();
}

addcommand("update-hover", updateHover);
addcommand("set-tooltip", setTooltip);
addcommand("tooltip-timeout", showTooltip);
addcommand("show-message", showMessage);
addcommand("clear-message", clearMessage);

# confirm the commands are registered: we use this to
# avoid sending commands before Nasal is inited, and hence
# producing errors
setprop("/sim/mouse/tooltip-commands-registered", 1);

# called by the module unload callback in api.nas
var unloadTooltips = func
{
  removecommand("update-hover");
  removecommand("set-tooltip");
  removecommand("tooltip-timeout");
  removecommand("show-message");
  removecommand("clear-message");

  setprop("/sim/mouse/tooltip-commands-registered", 0);
}
