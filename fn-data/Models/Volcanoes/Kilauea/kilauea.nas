		var puu_oo_loop_flag = 1;
	
		var puu_oo_loop = func (strength, tgt_strength) {

		if (puu_oo_loop_flag == 0) 
			{
			print("Ending Puu Oo eruption simulation.");
			return;
			}
		
		if (rand() > 0.99) {tgt_strength = 100.0;}

		tgt_strength = tgt_strength - 0.5;
		if (tgt_strength < 40.0) {tgt_strength = 40.0;}

		var step = 5.0;

		if (math.abs(strength - tgt_strength) < 5.0) {step = 1.0;}

		if (strength < tgt_strength) 
			{strength += step;}
		else
			{strength -= step;}

		setprop("/environment/volcanoes/kilauea/puu-oo-eruption-strength", strength);
		setprop("/environment/volcanoes/kilauea/puu-oo-eruption-quantity", int(0.5*strength));


		settimer(func {puu_oo_loop(strength, tgt_strength);}, 0.1);
		}

		puu_oo_state_manager = func {
		
			#print ("Puu Oo state manager");
			var state = getprop("/environment/volcanoes/kilauea/puu-oo-activity");
			
			if (state == 3)
				{
				print("Starting Puu Oo eruption simulation.");
				puu_oo_loop_flag = 1;
				puu_oo_loop(50.0, 50.0);
				}
			else
				{
				puu_oo_loop_flag = 0;
				}
		
		}
		
		# call state manager once to get correct autosaved behavior, otherwise use listener
		
		puu_oo_state_manager();
		
		setlistener("/environment/volcanoes/kilauea/puu-oo-activity", puu_oo_state_manager);
