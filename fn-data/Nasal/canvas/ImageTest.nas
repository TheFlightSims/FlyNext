var ImageTest = {

  new : func()
  {
    var obj = {
      parents : [ ImageTest ],
      width : 528,
      height : 528,
    };

    obj.window = canvas.Window.new([obj.width,obj.height],"dialog").set('title',"CanvasImageTest");

    # creating the top-level/root group which will contain all other elements/group
    obj.myCanvas = obj.window.createCanvas();
    obj.myCanvas.set("name", "Test");
    obj.root = obj.myCanvas.createGroup();
    obj._slice = 17;

    obj._frame =
      obj.root.createChild("image", "background")
          .set("src", "gui/images/tooltip.png")
          .set("slice", obj._slice ~ " fill")
          .setSize([obj.width,obj.height]);

    obj._image = obj.root.createChild("image", "TestImage")
      .setSize(500, 500);
    obj._image.set("src", "gui/images/cat.png");

      obj.pixelX = 0;
      obj.pixelY = 0;

      var t = maketimer(0.05, obj, func {
        obj.pixelX += 1;
        if (obj.pixelX >= obj.width) {
          obj.pixelX = 0;
          obj.pixelY += 1;
          if (obj.pixelY >= obj.height) {
            obj.pixelY = 0;
          }
        }
       
        var c = math.mod(obj.pixelX + obj.pixelY, 32) / 32.0;
        me._image.setPixel(obj.pixelX, obj.pixelY, [c, (1.0 - c), c, 1.0]);
        me._image.dirtyPixels();
      });
      t.start();
  }
};

