var testDialog = {

  shape: func(cDefaultGroup) {
    cDefaultGroup.createChild("path")
                 .setColorFill(0,0,0)
                 .setColor(0,0,0);
  },
  label: func(cDefaultGroup,desc,posx,posy,rot=0) {
    cDefaultGroup.createChild("text", desc)
                  .setRotation(rot*0.0174532925)
                  .setTranslation(posx,posy)
                  .setAlignment("center-top")
                  .setFont("typewriter.txf")
                  .setFontSize(40,1.5)
                  .setColor(0,0,0)
                  .setText(desc);
  },
  create_tbl: func(needle_tbl) {
    # hash table for needle positions
    for (var i=1; i<21; i = i+1) {
        var r0 = 150; var r1 = 350;
        var a0 = (i*4.5 - 1.5) * 0.0174533;
        var a1 = (i*4.5 + 1.5) * 0.0174533;

        var r3 = r1+8;
        var a3 = (a0 + a1)/2;

        var x1 = -r0 * math.cos(a0);
        var y1 = r0 * math.sin(a0);

        var x2 = -r1 * math.cos(a0);
        var y2 = r1 * math.sin(a0);

        var x3 = -r3 * math.cos(a3);
        var y3 = r3 * math.sin(a3);

        var x4 = -r1 * math.cos(a1);
        var y4 = r1 * math.sin(a1);

        var x5 = -r0 * math.cos(a1);
        var y5 = r0 * math.sin(a1);

        append(needle_tbl, [x1, y1, x2, y2, x3, y3, x4, y4, x5, y5]);
    }
  },

  draw_vario: func(needles,needle_tbl,cx,cy) {
    var min = 0;
    var max = 20;

    needles.reset();
    for (var i=min; i<max; i = i+1) {
      var x = cx - needle_tbl[i][0];
      var y = cy + needle_tbl[i][1];
      needles.moveTo(x, y);

      var x = cx - needle_tbl[i][2];
      var y = cy + needle_tbl[i][3];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][4];
      var y = cy + needle_tbl[i][5];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][6];
      var y = cy + needle_tbl[i][7];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][8];
      var y = cy + needle_tbl[i][9];
      needles.lineTo(x, y);
      needles.close();
    }

    for (var i=min; i<max; i = i+1) {
      var x = cx + needle_tbl[i][0];
      var y = cy + needle_tbl[i][1];
      needles.moveTo(x, y);

      var x = cx + needle_tbl[i][2];
      var y = cy + needle_tbl[i][3];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][4];
      var y = cy + needle_tbl[i][5];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][6];
      var y = cy + needle_tbl[i][7];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][8];
      var y = cy + needle_tbl[i][9];
      needles.lineTo(x, y);
      needles.close();
    }

    for (var i=min; i<max; i = i+1) {
      var x = cx - needle_tbl[i][0];
      var y = cy - needle_tbl[i][1];
      needles.moveTo(x, y);

      var x = cx - needle_tbl[i][2];
      var y = cy - needle_tbl[i][3];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][4];
      var y = cy - needle_tbl[i][5];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][6];
      var y = cy - needle_tbl[i][7];
      needles.lineTo(x, y);

      var x = cx - needle_tbl[i][8];
      var y = cy - needle_tbl[i][9];
      needles.lineTo(x, y);
      needles.close();
    }

    max = 4;
    for (var i=min; i<max; i = i+1) {
      var x = cx + needle_tbl[i][0];
      var y = cy - needle_tbl[i][1];
      needles.moveTo(x, y);

      var x = cx + needle_tbl[i][2];
      var y = cy - needle_tbl[i][3];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][4];
      var y = cy - needle_tbl[i][5];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][6];
      var y = cy - needle_tbl[i][7];
      needles.lineTo(x, y);

      var x = cx + needle_tbl[i][8];
      var y = cy - needle_tbl[i][9];
      needles.lineTo(x, y);
      needles.close();
    }
  },
  new: func(width=400,height=500)
  {
    var m = {
      parents: [testDialog],
      _dlg: canvas.Window.new([width, height], "dialog")
                         .set("title", "test-pattern"),
    };

    var cDisplay = canvas.new({
      "name": "test-pattern",
      "size": [1024, 1024],
      "view": [800, 1000],
      "mipmapping": 1
    });
    cDisplay.addPlacement({"node": "iq_display"});
    cDisplay.set("background", canvas.style.getColor("bg_color"));

    m._dlg.setCanvas(cDisplay);

    var cDefaultGroup = cDisplay.createGroup();

    var arrow = testDialog.shape(cDefaultGroup);
    arrow.moveTo(0,0);
    arrow.lineTo(400,550);
    arrow.lineTo(400,500);
    arrow.lineTo(450,500);
    arrow.close();

    var sqbl = testDialog.shape(cDefaultGroup);
    sqbl.moveTo(0,1000);
    sqbl.lineTo(20,900);
    sqbl.lineTo(100,980);
    sqbl.close();

    var sqbr = testDialog.shape(cDefaultGroup);
    sqbr.moveTo(800,1000);
    sqbr.lineTo(780,900);
    sqbr.lineTo(700,980);
    sqbr.close();

    var sqtr = testDialog.shape(cDefaultGroup);
    sqtr.moveTo(800,0);
    sqtr.lineTo(780,100);
    sqtr.lineTo(700,20);
    sqtr.close();

    var needle_tbl = [[0,0,0,0,0,0,0,0,0,0]];
    testDialog.create_tbl(needle_tbl);
    var needles = testDialog.shape(cDefaultGroup);
    testDialog.draw_vario(needles,needle_tbl,400,500);

    testDialog.label(cDefaultGroup,"TOP",400,5,0.0);
    testDialog.label(cDefaultGroup,"LEFT",5,500,-90.0);
    testDialog.label(cDefaultGroup,"RIGHT",795,500,90.0);
    testDialog.label(cDefaultGroup,"BOTTOM",400,995,180.0);

    return m;
  },
};
