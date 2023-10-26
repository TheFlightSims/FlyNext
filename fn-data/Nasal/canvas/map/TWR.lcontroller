# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'TWR';
var parents = [SymbolLayer.Controller];
var __self__ = caller(0)[0];
SymbolLayer.Controller.add(name, __self__);
SymbolLayer.add(name, {
	parents: [MultiSymbolLayer],
	type: name, # Symbol type
	df_controller: __self__, # controller to use by default -- this one
	df_style: {
		color: { r:0.2, g:0.2, b:1.2 },
		line_width: 1,
	},
	df_options: { # default configuration options
		disable_position: 1,
	},
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
	#print(name,".lcontroller.del()");
	foreach (var l; me.listeners)
		removelistener(l);
};

var searchCmd = func {
	#print("Running query:", name);
	var range = me.map.getRange();
	if (range == nil) return;
	return positioned.findAirportsWithinRange(me.map.getPosCoord(), range);
};
