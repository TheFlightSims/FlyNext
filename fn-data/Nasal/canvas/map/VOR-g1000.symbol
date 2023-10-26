# Class things:
var name = 'VOR-g1000';
var parents = [SVGSymbol];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

var element_type = "group"; # we want a group, becomes "me.element"
var text_vor = nil;

var svg_path = 'Nasal/canvas/map/Garmin/Images/g1000_vor2.svg';
#var svg_path = 'Nasal/canvas/map/Airbus/Images/airbus_vor.svg';
var vor_sym = nil;
var vor_center = nil;

var draw = func{
    if(me.vor_sym == nil) {
      me.vor_sym = me.element.getElementById("vor");
      #me.vor_sym = me.element.getElementById("airbus-vor-sym");
    }

    me.vor_sym.setTranslation(-100,-100);

    var heading = me.map.getHdg();
		me.vor_sym.setRotation(heading);

    #me.vor_sym.setScale(0.5);

    if(me.text_vor == nil){
        var transl = me.getStyle('translation', [-10,20]);
        var text_color = me.getStyle('text_color', [1,1,1]);
        me.text_vor = me.element.createChild("text")
        .setDrawMode( canvas.Text.TEXT )
        .setText(me.model.id)
        .setFont("LiberationFonts/LiberationSans-Regular.ttf")
        .setFontSize(12)
        .setColor(text_color)
        .setTranslation(transl);
    }
    if(me.vor_center == nil) {
      var line_width = me.getStyle('line_width', 3);
      var color = me.getStyle('color', [0.2,0.2,0.6]);
      me.vor_center = me.element.createChild("path")
        .moveTo(-15,0)
        .lineTo(-7.5,12.5)
        .lineTo(7.5,12.5)
        .lineTo(15,0)
        .lineTo(7.5,-12.5)
        .lineTo(-7.5,-12.5)
        .close()
        .setStrokeLineWidth(line_width)
        .setColor(color)
        .set("z-index",-2);
    }

    var frq = me.model.frequency;
    if(frq != nil){
        var dfcolor = me.getStyle('color', [0.9,0,0.47]);
        var tuned_color = me.getStyle('tuned_color', [0,0.62,0.84]);
        frq = frq / 100;
        var nav1_frq = getprop(me.options.nav1_frq);
        var nav2_frq = getprop(me.options.nav2_frq);
        if(nav1_frq == frq or nav2_frq == frq){
            me.text_vor.setColor(me.getStyle('text_color', [1,1,1]));
        } else {
            me.text_vor.setColor(me.getStyle('text_color', [0.7,0.7,0.7]));
        }
    }


}
