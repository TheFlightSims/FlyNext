# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'GRID';
var parents = [SymbolLayer.Controller];
var __self__ = caller(0)[0];
SymbolLayer.Controller.add(name, __self__);
SymbolLayer.add(name, {
	parents: [MultiSymbolLayer],
	type: name, # Symbol type
	df_controller: __self__, # controller to use by default -- this one
	df_options: { # default configuration options
		granularity_lon: 0.25,
		granularity_lat: 0.25,
	}
});
var new = func(layer) {
	var m = {
		parents: [__self__],
		layer: layer,
		map: layer.map,
		listeners: [],
		last_lat: -999,
		last_lon: -999,
		last_range: -999,
		last_result: [],
	};
	layer.searcher._equals = func(l,r) 0; # TODO: create model objects instead?

	m.addVisibilityListener();
	return m;
};
var del = func() {
	foreach (var l; me.listeners)
		removelistener(l);
};

var searchCmd = func() {

	var lines = [];
	var delta_lon = me.layer.options.granularity_lon;
	var delta_lat = me.layer.options.granularity_lat;

	# Find the nearest lat/lon line to the map position.  If we were just displaying
	# integer lat/lon lines, this would just be rounding.
	var lat = delta_lat * math.round(me.layer.map.getLat() / delta_lat);
  var lon = delta_lon * math.round(me.layer.map.getLon() / delta_lon);
	var range = me.layer.map.getRange();

	# Return early if no significant change in lat/lon/range - implies no additional
	# grid lines required
	if ((lat == me.last_lat) and (lon == me.last_lon) and (range == me.last_range)) return me.last_result;

	# Determine number of degrees of lat/lon we need to display based on range
	# 60nm = 1 degree latitude, degree range for longitude is dependent on latitude.
	var lon_range = math.ceil(geo.Coord.new(me.layer.map.getPosCoord()).apply_course_distance(90.0, range * globals.NM2M).lon() - lon) * 2;
	var lat_range = math.ceil(range/60.0) * 2;

	for (var x = (lon - lon_range); x <= (lon + lon_range); x += delta_lon) {
		var coords = [];

		# We could do a simple line from start to finish, but depending on projection,
		# the line may not be straight.
		for (var y = (lat - lat_range); y <= (lat + lat_range); y +=  delta_lat) {
			append(coords, {lon:x, lat:y});
		}

		append(lines, {
			id: x,
			type: "lon",
			path: coords,
			equals: func(o){
				return (me.id == o.id and me.type == o.type); # We only display one line of each lat/lon
			}
		});
	}

	# Lines of latitude
	for (var y = (lat - lat_range); y <= (lat + lat_range); y += delta_lat) {
		var coords = [];

		# We could do a simple line from start to finish, but depending on projection,
		# the line may not be straight.
		for (var x = (lon - lon_range); x <= (lon + lon_range); x += delta_lon) {
			append(coords, {lon:x, lat:y});
		}

		append(lines, {
			id: y,
			type: "lat",
			path: coords,
			equals: func(o){
				return (me.id == o.id and me.type == o.type); # We only display one line of each lat/lon
			}
		});
	}

	me.last_lat = lat;
	me.last_lon = lon;
	me.last_range = range;
	me.last_result = lines;

	return lines;
};
