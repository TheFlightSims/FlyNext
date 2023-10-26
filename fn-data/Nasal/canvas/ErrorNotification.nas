var ErrorNotification = 
{
    SHOW_TIME: 10.0,
    SLICE: 17,
    MARGIN: 10,

  new: func
  {
    var m = {
      parents: [ErrorNotification, PropertyElement.new(["/sim/gui/canvas", "window"], nil)],
      _title: "",
    };

    m.setInt("size[0]", 500);
    m.setInt("size[1]", 400);
    m.setBool("visible", 0);
    m.setInt("z-index", gui.STACK_INDEX["always-on-top"]);

    m._hideTimer = maketimer(m.SHOW_TIME, m, ErrorNotification._hideTimeout);
    m._hideTimer.singleShot = 1;
    m._reportIndex = 0;

    return m;
  },

  # Destructor
  del: func
  {
    me.parents[1].del();
    if( me["_canvas"] != nil )
      me._canvas.del();
  },

  _createCanvas: func()
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
      name: "Error Notification"
    });

    me.set("capture-events", 1);
    me.set("fill", "rgba(255,255,255,0.8)");

    # transparent background
    me._canvas.setColorBackground(0.0, 0.0, 0.0, 0.0);

    var root = me._canvas.createGroup();
    me._root = root;

    me._frame =
      root.createChild("image", "background")
          .set("src", "gui/images/tooltip.png")
          .set("slice", me.SLICE ~ " fill")
          .setSize(size);

    me._warningIcon =
      root.createChild("image", "warning-icon")
          .set("src", "gui/images/warning-icon.png")
          .setTranslation(me.SLICE, me.SLICE);

    var iconWidth = me._warningIcon.get("size[0]");

    me._text =
      root.createChild("text", "error-description")
          .setText("An error occurred")
          .setAlignment("left-top")
          .setFontSize(14)
          .setFont("LiberationFonts/LiberationSans-Bold.ttf")
          .setColor(1,1,1)
          .setDrawMode(Text.TEXT)
          .setTranslation(me.SLICE + iconWidth + me.MARGIN, me.SLICE);

     me._canvas.addEventListener("mousedown", func me.clicked());
     
    return me._canvas;
  },

  clicked: func()
  {
    me.hideNow();
    fgcommand("show-error-report", props.Node.new({ "index": me._reportIndex})); # should we show the current one?
  },

  updateText: func()
  {
    var msg = getprop("/sim/error-report/display/category");
    var clickForMoreMsg = "\n\nClick to show further details.";
    me._text.setText(msg ~ clickForMoreMsg);
    me._updateBounds();
  },

 _updateBounds: func
  {
    # the width of everything except the text
    var extraWidth = me._warningIcon.get("size[0]") + me.MARGIN + (2 * me.SLICE);
    var maxTextWidth = me.get("size[0]") - extraWidth;

    me._text.setMaxWidth(maxTextWidth);

    # compute the bounds
    var text_bb = me._text.update().getBoundingBox();
    var width = text_bb[2];
    var height = text_bb[3];

    if( width > maxTextWidth )
      width = maxTextWidth;

    me._width = width + extraWidth;
    me._height = height + 2 * me.SLICE;
    me._frame.setSize(me._width, me._height)
             .update();

    me._updatePosition();
  },

  _updatePosition: func
  {
    var INSET = 50;
    var y = INSET;
    var x = getprop('/sim/startup/xsize') - (me._width + INSET);

    me.setInt("x", x);
    me.setInt("y", y);
  },

  show: func(index)
  {
    me._reportIndex = index;
    me._hideTimer.stop();
    me.setBool("visible", 1);
    me._hideTimer.start();
  },

  hideNow: func()
  {
    me._hideTimer.stop();
    me._hideTimeout();
  },

  _hideTimeout: func()
  {
    me.setBool("visible", 0);
  }
};

var errorNotificationCanvas = nil;

var showErrorNotification = func(node)
{
    if (errorNotificationCanvas == nil) {
        # create instance
        errorNotificationCanvas = canvas.ErrorNotification.new();
        errorNotificationCanvas._createCanvas();
    }

    errorNotificationCanvas.updateText();
    var reportIndex = node.getNode("index").getValue();
    errorNotificationCanvas.show(reportIndex);
}

addcommand("show-error-notification-popup", showErrorNotification);

# called from unload() in api.nas
var unloadErrorNotification = func
{
  removecommand("show-error-notification-popup");
  if (errorNotificationCanvas) {
    errorNotificationCanvas.del();
    errorNotificationCanvas = nil;
  }
}