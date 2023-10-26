# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'TAXI';
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

var element_type = "group"; # we want a group, becomes "me.element"
var rwys = nil;

var SURFACECOLORS = {
	1 : { type: "asphalt",  r:0.2,  g:0.2, b:0.2 },
	2 : { type: "concrete", r:0.3,  g:0.3, b:0.3 },
	3 : { type: "turf",     r:0.2,  g:0.5, b:0.2 },
	4 : { type: "dirt",     r:0.4,  g:0.3, b:0.3 },
	5 : { type: "gravel",   r:0.35, g:0.3, b:0.3 },
#  Helipads
	6 : { type: "asphalt",  r:0.2,  g:0.2, b:0.2 },
	7 : { type: "concrete", r:0.3,  g:0.3, b:0.3 },
	8 : { type: "turf",     r:0.2,  g:0.5, b:0.2 },
	9 : { type: "dirt",     r:0.4,  g:0.3, b:0.3 },
	0 : { type: "gravel",   r:0.35, g:0.3, b:0.3 },
};

var init = func {
	var apt=airportinfo(me.model.id);
	foreach (var taxi; apt.taxiways)
  {
		var clr = me.style.surface_color[taxi.surface];
		if (clr == nil) { clr = SURFACECOLORS[taxi.surface]};
		if (clr == nil) { clr = SURFACECOLORS[0]};

		var taxi_paths =
		me.element.createChild("path", "runway-" ~ taxi.id)
		.setStrokeLineWidth(0.5)
		.setColor(clr.r, clr.g, clr.b)
		.setColorFill(clr.r, clr.g, clr.b);

		var txi = Runway.new(taxi);
		var beg1 = txi.pointOffCenterline(0,  0.5 * taxi.width);
		var beg2 = txi.pointOffCenterline(0, -0.5 * taxi.width);
		var end1 = txi.pointOffCenterline(taxi.length,  0.5 * taxi.width);
		var end2 = txi.pointOffCenterline(taxi.length, -0.5 * taxi.width);

		taxi_paths.setColorFill(clr.r, clr.g, clr.b)
		            .setDataGeo
		            (
		              [ canvas.Path.VG_MOVE_TO,
		                canvas.Path.VG_LINE_TO,
		                canvas.Path.VG_LINE_TO,
		                canvas.Path.VG_LINE_TO,
		                canvas.Path.VG_CLOSE_PATH ],
		              [ beg1[0], beg1[1],
		                beg2[0], beg2[1],
		                end2[0], end2[1],
		                end1[0], end1[1] ]
		            );
	}
};
var draw = func;
