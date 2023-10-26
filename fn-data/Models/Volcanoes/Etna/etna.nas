		var etna_ash_loop_flag = 0;
		var etna_fountain_loop_flag = 0;
	
		var etna_se_factor = 1.0;
		var etna_ne_factor = 1.0;
		
		var etna_se_probability = 0.985;
		var etna_ne_probability = 0.985;

	
		var etna_ash_loop = func (timer) {

		if (etna_ash_loop_flag == 0) 
			{
			print("Ending Etna ash eruption simulation.");
			return;
			}
			
		if (timer < 0.0) 
			{
			
			if (rand() > 0.6)
				{
				setprop("/environment/volcanoes/etna/ash-se-alpha", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/etna/ash-se-beta", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/etna/ash-ne-alpha", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/etna/ash-ne-beta", (rand() - 0.5) * 60.0);
				}
			else
				{
				setprop("/environment/volcanoes/etna/ash-se-alpha", 0.0);
				setprop("/environment/volcanoes/etna/ash-se-beta", 0.0);	
				setprop("/environment/volcanoes/etna/ash-ne-alpha", 0.0);
				setprop("/environment/volcanoes/etna/ash-ne-beta", 0.0);					
				}
			timer = 2.0 + 3.0 * rand();
			}
		
		timer = timer - 0.1;
		
		settimer(func {etna_ash_loop(timer);}, 0.1);
		}
	
	
		var etna_fountain_loop = func (timer, strength, timer_sec, strength_sec) {

		if (etna_fountain_loop_flag == 0) 
			{
			print("Ending Etna lava fountain simulation.");
			return;
			}
			
		
		if ((timer <= 0.0) and (rand() > etna_se_probability)) 
			{
				strength = 180.0 + 70.0 * rand();
				strength *= etna_se_factor;
				timer = 0.4 + 0.4 * rand();
				setprop("/environment/volcanoes/etna/ash-se-alpha", (rand() - 0.5) * 40.0);
				setprop("/environment/volcanoes/etna/ash-se-beta", (rand() - 0.5) * 40.0);
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


		setprop("/environment/volcanoes/etna/se-strength",  strength );
		setprop("/environment/volcanoes/etna/se-strength-inner", 0.95 * strength );
		setprop("/environment/volcanoes/etna/se-quantity", int(5.0*strength + rand()));
		setprop("/environment/volcanoes/etna/se-quantity-inner", int(1.0*strength + 0.2 * rand()));

		timer = timer - 0.1;
		
		
		if ((timer_sec <= 0.0) and (rand() > etna_ne_probability)) 
			{
				strength_sec = 140.0 + 60.0 * rand();
				strength_sec *= etna_ne_factor;
				timer_sec = 0.2 + 0.2 * rand();
				setprop("/environment/volcanoes/etna/ash-ne-alpha", (rand() - 0.5) * 40.0);
				setprop("/environment/volcanoes/etna/ash-ne-beta", (rand() - 0.5) * 40.0);
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


		setprop("/environment/volcanoes/etna/ne-strength", 0.95 * ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/etna/ne-strength-inner", ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/etna/ne-quantity", int(5.0*strength_sec + rand()));
		setprop("/environment/volcanoes/etna/ne-quantity-inner", int(1.0*strength_sec + 0.2 * rand()));

		timer_sec = timer_sec - 0.1;
		
	settimer(func {etna_fountain_loop(timer, strength, timer_sec, strength_sec);}, 0.1);
	}		

		

	etna_state_manager = func {
		
		var state_se = getprop("/environment/volcanoes/etna/southeast-activity");
		var state_ne = getprop("/environment/volcanoes/etna/northeast-activity");
		var state_flank = getprop("/environment/volcanoes/etna/flank-activity");

		if (((state_se > 2) or (state_ne > 2)) and (etna_ash_loop_flag == 0))
			{
			print ("Starting Etna ash eruption simulation.");
			etna_ash_loop_flag = 1;
			etna_ash_loop(0.0);
			}
		else if ((state_se < 3) and (state_ne < 3) and (etna_ash_loop_flag == 1)) 
			{
			etna_ash_loop_flag = 0;			
			}
		
		
		
		if (((state_se == 2) or (state_ne == 2)) and (etna_fountain_loop_flag == 0))
			{
			print ("Starting Etna lava fountain simulation.");
			etna_fountain_loop_flag = 1;
			etna_fountain_loop(0.0, 0.0, 0.0, 0.0);			
			}
		else if ((state_se < 2) and (state_ne < 2) and (etna_fountain_loop_flag == 1)) 
			{
			etna_fountain_loop_flag = 0;
			}
		}
		
	# call state manager once to get correct autosaved behavior, otherwise use listener
		
	etna_state_manager();
		
	setlistener("/environment/volcanoes/etna/southeast-activity", etna_state_manager);
	setlistener("/environment/volcanoes/etna/northeast-activity", etna_state_manager);