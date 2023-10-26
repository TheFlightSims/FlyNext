# See: http://wiki.flightgear.org/MapStructure
# GPS line.  Displays GPS leg information

# Class things:
var name = 'GPS';
var parents = [SymbolLayer.Controller];
var __self__ = caller(0)[0];
SymbolLayer.Controller.add(name, __self__);
SymbolLayer.add(name, {
	parents: [MultiSymbolLayer],
	type: name, # Symbol type
	df_controller: __self__, # controller to use by default -- this one
	df_options: { # default configuration options
		from_node : "/instrumentation/gps/wp/wp[0]",
		to_node : "/instrumentation/gps/wp/wp[1]",

		trigger_node1 : "/instrumentation/gps/wp/wp[1]/longitude-deg",
		trigger_node2 : "/instrumentation/gps/wp/wp[1]/latitude-deg",
		trigger_node3 : "/instrumentation/gps/wp/wp[1]/altitude-ft",
	}
});
var new = func(layer) {
	var m = {
		parents: [__self__],
		layer: layer,
		map: layer.map,
		listeners: [],
		last_result: [],
	};
	layer.searcher._equals = func(l,r) 0; # TODO: create model objects instead?

	append(m.listeners, setlistener(layer.options.trigger_node1, func m.layer.update(), 0, 0));
	append(m.listeners, setlistener(layer.options.trigger_node2, func m.layer.update(), 0, 0));
	append(m.listeners, setlistener(layer.options.trigger_node3, func m.layer.update(), 0, 0));

	m.addVisibilityListener();
	return m;
};
var del = func() {
	foreach (var l; me.listeners)
		removelistener(l);
};

var searchCmd = func() {
	var coords = [];

	var from = props.globals.getNode(me.layer.options.from_node);
	var to = props.globals.getNode(me.layer.options.to_node);

	# Perform various checks for valid data.  Unfortunately to avoid either
	# having continual triggering every frame as the property values are updated
	# (though not changed), we need to trigger this on any changes to the waypoint.
	# In an initial case, not all the properties may have been initialized yet.
	if ((from == nil) or (to == nil)) return [];
	if (to.getNode("valid").getBoolValue() == 0) return [];
	if (to.getValue("longitude-deg") == nil) return [];
	if (to.getValue("latitude-deg") == nil) return [];

	# Nil altitude is valid - set to 0.
	# if (to.getValue("altitude-ft") == nil) return [];

	append(coords, {lon: from.getValue("longitude-deg"),
	                lat: from.getValue("latitude-deg"),
									alt: from.getValue("altitude-ft") });

	append(coords, {lon: to.getValue("longitude-deg"),
	                lat: to.getValue("latitude-deg"),
									alt: to.getValue("altitude-ft") or 0.0});

	var lines = [];

	append(lines, {
		id: to.getNode("name", 1).getValue(),
		type: "gps",
		path: coords,
		equals: func(o){
			return (me.path == o.path and me.type == o.type);
		}
	});

	return lines;
};
