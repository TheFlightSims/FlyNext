# See: http://wiki.flightgear.org/MapStructure
#
# Direct TO line.  Displays line from current position to a given Lat/Lon

# Class things:
var name = 'DTO';
var parents = [LineSymbol];
var __self__ = caller(0)[0];
LineSymbol.makeinstance( name, __self__ );

SymbolLayer.get(name).df_style = { # style to use by default
	line_width: 2,
	color: [1.0,1.0,1.0],
	dash_array: [5,5,5,5],
};

var init = func {
	me.element.setColor(me.layer.style.color)
	.setStrokeLineWidth(me.layer.style.line_width)
	.setStrokeDashArray(me.layer.style.dash_array);
};

var draw = func() {
	me.callback('draw_before');
	logprint(_MP_dbg_lvl, "redrawing a LineSymbol "~me.layer.type);
	me.element.reset();
	var cmds = [];
	var coords = [];
	var cmd = canvas.Path.VG_LINE_TO;

	append(coords,"N"~me.layer.map.getLat());
	append(coords,"E"~me.layer.map.getLon());
	append(cmds,canvas.Path.VG_MOVE_TO);

	var path = me.model;
	if(typeof(path) == 'hash'){
		path = me.model.path;
		if(path == nil)
			__die("LineSymbol model requires a 'path' member (vector)");
	}
	foreach (var m; path) {
		if(size(keys(m)) >= 2){
			var (lat,lon) = me.controller.getpos(m);
			append(coords,"N"~lat);
			append(coords,"E"~lon);
			append(cmds,cmd);
			cmd = canvas.Path.VG_LINE_TO;
		} else {
			cmd = canvas.Path.VG_MOVE_TO;
		}
	}
	me.element.setDataGeo(cmds, coords);
	me.element.update(); # this doesn't help with flickering, it seems
	me.callback('draw_after');
};
