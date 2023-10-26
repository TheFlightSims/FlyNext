		var surtsey_ash_loop_flag = 0;
	
		var surtsey_main_factor = 1.0;
		var surtsey_main_probability = 0.985;
		
		var surtsey_pos = geo.Coord.new().set_latlon(63.30510848,  -20.6054166);

	
		var surtsey_ash_loop = func (timer) {

		if (surtsey_ash_loop_flag == 0) 
			{
			print("Ending Surtsey ash eruption simulation.");
			return;
			}
			
		if (timer < 0.0) 
			{
			
			if (rand() > 0.6)
				{
				setprop("/environment/volcanoes/surtsey/ash-main-alpha", (rand() - 0.5) * 40.0);
				setprop("/environment/volcanoes/surtsey/ash-main-beta", (rand() - 0.5) * 40.0);
				}
			else
				{	
				setprop("/environment/volcanoes/surtsey/ash-main-alpha", 0.0);
				setprop("/environment/volcanoes/surtsey/ash-main-beta", 0.0);					
				}
			timer = 2.0 + 3.0 * rand();
			}
			
		var aircraft_pos = geo.aircraft_position();
		var dist = aircraft_pos.distance_to(surtsey_pos);
		var turbulence = 100000.0/(dist * dist);
		if (turbulence > 1.0) {turbulence = 1.0;}
		
		setprop("/environment/volcanoes/turbulence", turbulence);
		
		timer = timer - 0.1;
		
		settimer(func {surtsey_ash_loop(timer);}, 0.1);
		}
	
	
	surtsey_state_manager = func {
				
		var state_main = getprop("/environment/volcanoes/surtsey/main-activity");
		
		if ( (state_main > 1) and (surtsey_ash_loop_flag == 0))
			{
			print ("Starting Surtsey ash eruption simulation.");
			surtsey_ash_loop_flag = 1;
			surtsey_ash_loop(0.0);
			}
		else if  ((state_main < 2) and (surtsey_ash_loop_flag == 1)) 
			{
			surtsey_ash_loop_flag = 0;	
			setprop("/environment/volcanoes/turbulence", 0);
			
			}
		
		
		

		}
		
	# call state manager once to get correct autosaved behavior, otherwise use listener
		
	surtsey_state_manager();
	setlistener("/environment/volcanoes/surtsey/main-activity", surtsey_state_manager);