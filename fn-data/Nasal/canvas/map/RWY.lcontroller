# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'RWY';
var parents = [SymbolLayer.Controller];
var __self__ = caller(0)[0];
SymbolLayer.Controller.add(name, __self__);
SymbolLayer.add(name, {
	parents: [MultiSymbolLayer],
	type: name, # Symbol type
	df_controller: __self__, # controller to use by default -- this one
	df_options: { # default configuration options
		disable_position: 1,
	},
	df_style: {},
});
var a_instance = nil;
var new = func(layer) {
	var m = {
		parents: [__self__],
		layer: layer,
		map: layer.map,
		listeners: [],
	};
	m.addVisibilityListener();

	return m;
};
var del = func() {
	foreach (var l; me.listeners)
		removelistener(l);
};

var searchCmd = func {
	var range = me.map.getRange();
	if (range == nil) return;
	return positioned.findAirportsWithinRange(me.map.getPosCoord(), range);
};
