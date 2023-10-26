# volcano management routines
# Thorsten Renk 2017




var volcano = {
	new: func(name, lat, lon) {
	        var v = { parents: [volcano] };
	        v.lat = lat;
			v.lon = lon;
			v.pos = geo.Coord.new().set_latlon(lat, lon);
			v.name = name;
			v.loaded = 0;
	        return v;
	},
	
};


var volcano_manager = {
	
	dist_to_load: 100000.0,
	active: 0,
	
	init: func {
		
		me.volcano_array = [];
		me.pos = {};
		me.init_state();
	
	},
	
	start: func {
	
		if (me.active == 1)
			{
			me.run(0);
			}
	
	},
	
	init_state: func {
		var state = getprop("/environment/volcanoes/enable-volcanoes");
		me.active = state;
		if (state == 1) 
			{logprint(LOG_INFO, "Volcanic activity on.");}
		else {logprint(LOG_DEBUG, "Volcanic activity off.");}
	},
	
	set_state: func {
		var state = getprop("/environment/volcanoes/enable-volcanoes");
		me.active = state;
		if (state == 1) 
			{
			logprint(LOG_INFO, "Volcanic activity on.");
			me.run(0);
			}
		else {logprint(LOG_INFO, "Volcanic activity off.");}
	
	},
	
	run: func (index) {
		
		
		if (me.active == 0) {return;}
		
		if (index > size(me.volcano_array) - 1) {index = 0;}
			

		
		if (me.volcano_array[index].loaded == 0)
			{
			me.pos = geo.aircraft_position();
			var dist = me.pos.distance_to(me.volcano_array[index].pos);
			#print ("Distance is now: ", dist);

			var visibility = getprop("/environment/visibility-m");
		
			
			if ((dist < me.dist_to_load) and (dist < visibility))
				{
				logprint(LOG_INFO, "Loading ", me.volcano_array[index].name, ".");
				me.volcano_array[index].set();
				me.volcano_array[index].loaded = 1;
				}
			}
			
		index += 1;
	
		settimer( func { me.run(index);}, 1.0);
	},

};

volcano_manager.init();



# setter functions for volcano sceneries

var set_kilauea = func {

io.include("Models/Volcanoes/Kilauea/kilauea.nas");
geo.put_model("Models/Volcanoes/Kilauea/halemaumau.xml", 19.4062038, -155.2840123);
geo.put_model("Models/Volcanoes/Kilauea/puu_oo.xml", 19.38881767, -155.10669939);
}

var set_stromboli = func {

io.include("Models/Volcanoes/Stromboli/stromboli.nas");
geo.put_model("Models/Volcanoes/Stromboli/central_crater.xml", 38.7892, 15.2105);
geo.put_model("Models/Volcanoes/Stromboli/side_crater.xml", 38.7950, 15.2139);
}

var set_etna = func {

io.include("Models/Volcanoes/Etna/etna.nas");
geo.put_model("Models/Volcanoes/Etna/southeast_crater.xml", 37.7472, 14.9984 );
geo.put_model("Models/Volcanoes/Etna/northeast_crater.xml", 37.7552, 14.9967 );

}


var set_beerenberg = func {

io.include("Models/Volcanoes/Beerenberg/beerenberg.nas");
geo.put_model("Models/Volcanoes/Beerenberg/main_crater.xml", 71.0805, -8.1496 );

}

var set_eyjafjallajokull = func {

io.include("Models/Volcanoes/Eyjafjallajokull/eyjafjallajokull.nas");
geo.put_model("Models/Volcanoes/Eyjafjallajokull/main_crater.xml", 63.628335, -19.62823 );

}

var set_katla = func {

io.include("Models/Volcanoes/Katla/katla.nas");
geo.put_model("Models/Volcanoes/Katla/main_crater.xml", 63.65750,  -19.182871 );

}

var set_surtsey = func {

io.include("Models/Volcanoes/Surtsey/surtsey.nas");
geo.put_model("Models/Volcanoes/Surtsey/main_crater.xml", 63.30510848,  -20.6054166 );

}

# volcano definitions

var kilauea = volcano.new("Kilauea", 19.39, -155.20);
kilauea.set = set_kilauea;
append(volcano_manager.volcano_array, kilauea);

var stromboli = volcano.new("Stromboli", 38.78, 15.21);
stromboli.set = set_stromboli;
append(volcano_manager.volcano_array, stromboli);

var etna = volcano.new("Etna", 37.74, 14.99 );
etna.set = set_etna;
append(volcano_manager.volcano_array, etna);

var beerenberg = volcano.new("Beerenberg", 71.08, -8.15);
beerenberg.set = set_beerenberg;
append(volcano_manager.volcano_array, beerenberg);

var eyjafjallajokull = volcano.new("Eyjafjallajokull", 63.62, -19.62);
eyjafjallajokull.set = set_eyjafjallajokull;
append(volcano_manager.volcano_array, eyjafjallajokull);

var katla = volcano.new("Katla", 63.65750, -19.182871);
katla.set = set_katla;
append(volcano_manager.volcano_array, katla);

var surtsey = volcano.new("Surtsey", 63.305,  -20.605);
surtsey.set = set_surtsey;
append(volcano_manager.volcano_array, surtsey);


# start the manager when autosaved (need some delay for terrain loading to finish)

settimer(func {volcano_manager.start();}, 5.0);

# set the relevant listeners

setlistener("/environment/volcanoes/enable-volcanoes", func {volcano_manager.set_state();},0,0 );



