		var stromboli_loop_flag = 0;
	
		var stromboli_central_factor = 1.0;
		var stromboli_side_factor = 1.0;
		
		var stromboli_central_probability = 0.99;
		var stromboli_side_probability = 0.99;

	
		var stromboli_loop = func (timer, strength, timer_sec, strength_sec) {

		if (stromboli_loop_flag == 0) 
			{
			print("Ending Stromboli simulation.");
			return;
			}
			
		
		if ((timer <= 0.0) and (rand() > stromboli_central_probability)) 
			{
				strength = 180.0 + 70.0 * rand();
				strength *= stromboli_central_factor;
				timer = 0.3 + 0.3 * rand();
			}
		else if (timer <= 0.0)	
			{
			strength = strength - 3.0;
			}
		else	
			{
			strength = strength - 0.5;
			}

		if (strength < 10.0) {strength = 10.0;}


		setprop("/environment/volcanoes/stromboli/stromboli-eruption-strength",  strength );
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-strength-inner", 0.95 * strength );
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-quantity", int(5.0*strength + rand()));
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-quantity-inner", int(1.0*strength + 0.2 * rand()));

		timer = timer - 0.1;
		
		
		if ((timer_sec <= 0.0) and (rand() > stromboli_side_probability)) 
			{
				strength_sec = 140.0 + 60.0 * rand();
				strength_sec *= stromboli_side_factor;
				timer_sec = 0.2 + 0.2 * rand();
			}
		else if (timer_sec <= 0.0)	
			{
			strength_sec = strength_sec - 3.0;
			}
		else	
			{
			strength_sec = strength_sec - 0.5;
			}

		if (strength_sec < 10.0) {strength_sec = 10.0;}


		setprop("/environment/volcanoes/stromboli/stromboli-eruption-strength-sec", 0.95 * ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-strength-sec-inner", ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-quantity-sec", int(5.0*strength_sec + rand()));
		setprop("/environment/volcanoes/stromboli/stromboli-eruption-quantity-sec-inner", int(1.0*strength_sec + 0.2 * rand()));

		timer_sec = timer_sec - 0.1;
		
		settimer(func {stromboli_loop(timer, strength, timer_sec, strength_sec);}, 0.1);
		}

		stromboli_state_manager = func {
		
			#print ("Stromboli state manager");
			var state1 = getprop("/environment/volcanoes/stromboli/central-activity");
			var state2 = getprop("/environment/volcanoes/stromboli/side-activity");

			if (state1 > 2)
				{
				stromboli_central_probability = 0.99;
				stromboli_central_factor = 1.0;
				}
			else
				{
				stromboli_central_probability = 0.998;
				stromboli_central_factor = 0.6;	
				}
			
			if (state2 > 2)
				{
				stromboli_side_probability = 0.99;
				stromboli_side_factor = 1.0;
				}
			else
				{
				stromboli_side_probability = 0.998;
				stromboli_side_factor = 0.6;	
				}
				
			
			var state = state1;
			if (state2 > state) {state = state2;}
			
			if ((state > 1) and (stromboli_loop_flag == 0))
				{
				print("Starting Stromboli eruption simulation.");
				stromboli_loop_flag = 1;
				stromboli_loop(0.0, 0.0, 0.0, 0.0);
				}
			else if (state <= 1)
				{
				stromboli_loop_flag = 0;
				}
		
		}
		
		# call state manager once to get correct autosaved behavior, otherwise use listener
		
		stromboli_state_manager();
		setlistener("/environment/volcanoes/stromboli/central-activity", stromboli_state_manager);
		setlistener("/environment/volcanoes/stromboli/side-activity", stromboli_state_manager);
