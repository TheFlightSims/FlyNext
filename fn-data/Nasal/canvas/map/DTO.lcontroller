# See: http://wiki.flightgear.org/MapStructure
# Direct TO line.  Displays line from current position to a given Lat/Lon

# Class things:
var name = 'DTO';
var parents = [SymbolLayer.Controller];
var __self__ = caller(0)[0];
SymbolLayer.Controller.add(name, __self__);
SymbolLayer.add(name, {
	parents: [MultiSymbolLayer],
	type: name, # Symbol type
	df_controller: __self__, # controller to use by default -- this one
	df_options: { # default configuration options
	}
});
var new = func(layer) {
	var m = {
		parents: [__self__],
		layer: layer,
		map: layer.map,
		listeners: [],
		target_lat: -999,
		target_lon: -999,
		target_alt: -999,
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
var setTarget = func(lat, lon, alt=0) {
	me.target_lat = lat;
	me.target_lon = lon;
	me.target_alt = alt;
	me.layer.update();
};

var searchCmd = func() {
	var coords = [];
	append(coords, {lon: me.target_lon, lat: me.target_lat, alt: me.target_alt});

	var lines = [];

	append(lines, {
		id: me.target_lat ~ " " ~ me.target_lon,
		type: "lon",
		path: coords,
		equals: func(o){
			return (me.path == o.path and me.type == o.type);
		}
	});

	return lines;
};
