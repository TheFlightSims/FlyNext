		var eyjafjallajokull_ash_loop_flag = 0;
	
		var eyjafjallajokull_main_factor = 1.0;
		var eyjafjallajokull_main_probability = 0.985;

		var eyjafjallajokull_pos = geo.Coord.new().set_latlon(63.628335, -19.62823);

	
		var eyjafjallajokull_ash_loop = func (timer) {

		if (eyjafjallajokull_ash_loop_flag == 0) 
			{
			print("Ending Eyjafjallajökull ash eruption simulation.");
			return;
			}
			
		if (timer < 0.0) 
			{
			
			if (rand() > 0.6)
				{
				setprop("/environment/volcanoes/eyjafjallajokull/ash-main-alpha", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/eyjafjallajokull/ash-main-beta", (rand() - 0.5) * 60.0);
				}
			else
				{	
				setprop("/environment/volcanoes/eyjafjallajokull/ash-main-alpha", 0.0);
				setprop("/environment/volcanoes/eyjafjallajokull/ash-main-beta", 0.0);					
				}
			timer = 2.0 + 3.0 * rand();
			}
			
		var aircraft_pos = geo.aircraft_position();
		var dist = aircraft_pos.distance_to(eyjafjallajokull_pos);
		var turbulence = 1000000.0/(dist * dist);
		if (turbulence > 1.0) {turbulence = 1.0;}
		
		setprop("/environment/volcanoes/turbulence", turbulence);
		
		timer = timer - 0.1;
		
		settimer(func {eyjafjallajokull_ash_loop(timer);}, 0.1);
		}
	
	
	eyjafjallajokull_state_manager = func {
				
		var state_main = getprop("/environment/volcanoes/eyjafjallajokull/main-activity");
		
		if ( (state_main > 0) and (eyjafjallajokull_ash_loop_flag == 0))
			{
			print ("Starting Eyjafjallajökull ash eruption simulation.");
			eyjafjallajokull_ash_loop_flag = 1;
			eyjafjallajokull_ash_loop(0.0);
			}
		else if  ((state_main < 1) and (eyjafjallajokull_ash_loop_flag == 1)) 
			{
			eyjafjallajokull_ash_loop_flag = 0;	
			setprop("/environment/volcanoes/turbulence", 0);
			
			}
		
		
		

		}
		
	# call state manager once to get correct autosaved behavior, otherwise use listener
		
	eyjafjallajokull_state_manager();
	setlistener("/environment/volcanoes/eyjafjallajokull/main-activity", eyjafjallajokull_state_manager);