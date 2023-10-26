var GUI =
{

  new : func(isfd, isfd_canvas, scale = 1.0)
  {
    var obj = {
      parents : [ GUI ],
      isfd : isfd,
      width : 528,
      height : 528,
      scale : scale
    };

    obj.window = canvas.Window.new([obj.scale*obj.width,obj.scale*obj.height],"dialog").set('title',"ISFD");

    obj.window.del = func() {
      # Over-ride the window.del function so we clean up when the user closes the window
      # Use call method to ensure we have the correct closure.
      call(obj.cleanup, [], obj);
    };

    # creating the top-level/root group which will contain all other elements/group
    obj.myCanvas = obj.window.createCanvas();
    obj.myCanvas.set("name", "ISFD");
    obj.root = obj.myCanvas.createGroup();

    # Project the canvas onto the dialog
    var mfd_child = obj.root.createChild("image")
      .setFile(isfd_canvas.getPath())
      .set("z-index", 150)
      .setTranslation(obj.scale*8,obj.scale*8)
      .setSize(obj.scale*512, obj.scale*512);


    # Create the surround fascia, which is just a PNG image;
    var child = obj.root.createChild("image")
        .setFile("Aircraft/Instruments-3d/ISFD/fascia.png")
        .set("z-index", 100)
        .setTranslation(0, 0)
        .setSize(obj.scale*obj.width,obj.scale*obj.height);


    return obj;
  },

  cleanup : func()
  {
    me.isfd.del();
    # Clean up the window itself
    call(canvas.Window.del, [], me.window);
  },
};
