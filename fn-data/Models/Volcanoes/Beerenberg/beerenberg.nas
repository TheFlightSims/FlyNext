		var beerenberg_ash_loop_flag = 0;
		var beerenberg_fountain_loop_flag = 0;
	
		var beerenberg_se_factor = 1.0;
		var beerenberg_main_factor = 1.0;
		
		var beerenberg_se_probability = 0.985;
		var beerenberg_main_probability = 0.985;

	
		var beerenberg_ash_loop = func (timer) {

		if (beerenberg_ash_loop_flag == 0) 
			{
			print("Ending Beerenberg ash eruption simulation.");
			return;
			}
			
		if (timer < 0.0) 
			{
			
			if (rand() > 0.6)
				{
				setprop("/environment/volcanoes/beerenberg/ash-se-alpha", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/beerenberg/ash-se-beta", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/beerenberg/ash-main-alpha", (rand() - 0.5) * 60.0);
				setprop("/environment/volcanoes/beerenberg/ash-main-beta", (rand() - 0.5) * 60.0);
				}
			else
				{
				setprop("/environment/volcanoes/beerenberg/ash-se-alpha", 0.0);
				setprop("/environment/volcanoes/beerenberg/ash-se-beta", 0.0);	
				setprop("/environment/volcanoes/beerenberg/ash-main-alpha", 0.0);
				setprop("/environment/volcanoes/beerenberg/ash-main-beta", 0.0);					
				}
			timer = 2.0 + 3.0 * rand();
			}
		
		timer = timer - 0.1;
		
		settimer(func {beerenberg_ash_loop(timer);}, 0.1);
		}
	
	
		var beerenberg_fountain_loop = func (timer, strength, timer_sec, strength_sec) {

		if (beerenberg_fountain_loop_flag == 0) 
			{
			print("Ending Etna lava fountain simulation.");
			return;
			}
			
		
		if ((timer <= 0.0) and (rand() > beerenberg_se_probability)) 
			{
				strength = 180.0 + 70.0 * rand();
				strength *= beerenberg_se_factor;
				timer = 0.4 + 0.4 * rand();
				setprop("/environment/volcanoes/beerenberg/ash-se-alpha", (rand() - 0.5) * 40.0);
				setprop("/environment/volcanoes/beerenberg/ash-se-beta", (rand() - 0.5) * 40.0);
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


		setprop("/environment/volcanoes/beerenberg/se-strength",  strength );
		setprop("/environment/volcanoes/beerenberg/se-strength-inner", 0.95 * strength );
		setprop("/environment/volcanoes/beerenberg/se-quantity", int(5.0*strength + rand()));
		setprop("/environment/volcanoes/beerenberg/se-quantity-inner", int(1.0*strength + 0.2 * rand()));

		timer = timer - 0.1;
		
		
		if ((timer_sec <= 0.0) and (rand() > beerenberg_main_probability)) 
			{
				strength_sec = 140.0 + 60.0 * rand();
				strength_sec *= beerenberg_main_factor;
				timer_sec = 0.2 + 0.2 * rand();
				setprop("/environment/volcanoes/beerenberg/ash-main-alpha", (rand() - 0.5) * 40.0);
				setprop("/environment/volcanoes/beerenberg/ash-main-beta", (rand() - 0.5) * 40.0);
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


		setprop("/environment/volcanoes/beerenberg/main-strength", 0.95 * ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/beerenberg/main-strength-inner", ((0.9 + 0.1 * rand()) * strength_sec) );
		setprop("/environment/volcanoes/beerenberg/main-quantity", int(5.0*strength_sec + rand()));
		setprop("/environment/volcanoes/beerenberg/main-quantity-inner", int(1.0*strength_sec + 0.2 * rand()));

		timer_sec = timer_sec - 0.1;
		
	settimer(func {beerenberg_fountain_loop(timer, strength, timer_sec, strength_sec);}, 0.1);
	}		

		

	beerenberg_state_manager = func {
				
		var state_main = getprop("/environment/volcanoes/beerenberg/main-activity");
		var state_flank = getprop("/environment/volcanoes/beerenberg/flank-activity");
			
		if (((state_flank > 2) or (state_main > 2)) and (beerenberg_ash_loop_flag == 0))
			{
			print ("Starting Beerenberg ash eruption simulation.");
			beerenberg_ash_loop_flag = 1;
			beerenberg_ash_loop(0.0);
			}
		else if ((state_flank < 3) and (state_main < 3) and (beerenberg_ash_loop_flag == 1)) 
			{
			beerenberg_ash_loop_flag = 0;			
			}
		
		
		
		if (((state_flank == 2) or (state_main == 2)) and (beerenberg_fountain_loop_flag == 0))
			{
			print ("Starting Beerenberg lava fountain simulation.");
			beerenberg_fountain_loop_flag = 1;
			beerenberg_fountain_loop(0.0, 0.0, 0.0, 0.0);			
			}
		else if ((state_flank < 2) and (state_main < 2) and (beerenberg_fountain_loop_flag == 1)) 
			{
			beerenberg_fountain_loop_flag = 0;
			}
		}
		
	# call state manager once to get correct autosaved behavior, otherwise use listener
		
	beerenberg_state_manager();
		
	setlistener("/environment/volcanoes/beerenberg/southeast-activity", beerenberg_state_manager);
	setlistener("/environment/volcanoes/beerenberg/main-activity", beerenberg_state_manager);