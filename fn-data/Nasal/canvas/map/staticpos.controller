# Class things:
var parents = [Map.Controller];
var __self__ = caller(0)[0];
Map.Controller.add("Static position", __self__);
#Map.df_controller = __self__;

##
# A controller to handle static updates of position, for example an airport
# diagram or non-moving map.
#
# Note that in contrast to the Aircraft Controllers, update_pos() or
# update_layers() must be called explicitly to trigger an update of the map.
##

var new = func(map, source='main') {
	var m = {
		parents: [__self__],
		map: map,
		_pos: nil, _time: nil, _range: nil,
		_alt: 0, _hdg: 0,
	};
	m._pos = geo.Coord.new();
	m._pos.set_latlon(0.0,0.0);
	m.update_pos();
	return m;
};

var del = func(map) {
	if (map != me.map) die();
};

var setHeading  = func(hdg) { me._hdg = hdg; };
var setAltitude = func(alt) { me._alt = alt; };
var getHeading  = func()    { return me._hdg; };
var getAltitude = func()    { return me._alt; };
var setPosition = func(lat, lon) {
	me._pos.set_latlon(lat, lon);
	me.update_pos();
};

var applyOffset = func(x, y) {
	# Apply an offset in screen coordinates, e.g. from a mouse event
	var crs = 0.0;
	if (x != 0.0) {
		# Calculate course in degrees
		crs = 90.0 + 180.0 / math.pi * math.atan(y/x);
		if (x < 0.0 ) crs = crs + 180.0;
	} else {
		if (y < 0.0) crs = 0.0;
		if (y > 0.0) crs = 180.0
	}

	# Screen resolution m/pixel is range/screen_range
	var screen_range = me.map.getScreenRange() or 200;
	var screen_resolution = me.map.getRange() * globals.NM2M / screen_range;
	me._pos.apply_course_distance(crs, math.sqrt(x*x + y*y) * screen_resolution);
	me.update_pos();
};

# Controller methods
var update_pos = func {
	me.map.setPos(lat: me._pos.lat(), lon: me._pos.lon(),
	              hdg: me._hdg,,
	              alt: me._alt,);
	me.map.update();
};

var update_layers = func {
	me.map.update();
};

var get_position = func {
	return [ me._pos.lat(), me._pos.lon()	];
}
