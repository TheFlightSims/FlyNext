# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'TWR';
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

var element_type = "group"; # we want a group, becomes "me.element"

var init = func {
	var apt=airportinfo(me.model.id);

	var clr = me.style.color;
	var line_width = me.style.line_width;


	var icon_tower =
	me.element.createChild("path", "tower")
						.setStrokeLineWidth(line_width)
						.setScale(1.5)
						.setColor(clr.r, clr.g, clr.b)
						.moveTo(-3, 0)
						.vert(-10)
						.line(-3, -10)
						.horiz(12)
						.line(-3, 10)
						.vert(10);

	icon_tower.setGeoPosition(apt.tower().lat, apt.tower().lon);
};
var draw = func;
