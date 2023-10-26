###########################################################
# Aurora Borealis manager
# 
# this runs once at startup to randomize Aurora appearance
# a little and otherwise simulates detailed Aurora evolution
# only when requested by the user
###########################################################

var aurora_manager = {

	running_flag : 0,
	
	storm_probability: 0.1,
	storm_flag: 0,
	storm_duration: 0,
	storm_timer: 0,
	
	afterglow_flag: 0,
	afterglow_timer: 0,
	
	strength_bg: 0,
	strength_target: 0,
	strength_current: 0,
	strength_rate: 0.015,
	
	ray_bg: 0,
	ray_target: 0,
	ray_current: 0,
	ray_rate: 0.005,
	
	glow_bg: 0,
	glow_target: 0,
	glow_current: 0,
	glow_rate: 0.02,
	
	upper_bg: 0,
	upper_target: 0,
	upper_current: 0,
	upper_rate: 0.025,
	
	delta_t: 0.1,
	

	init: func {
	
		var rn = rand();
		setprop("/environment/aurora/penetration-factor", rn);
		
		rn = rand();
		setprop("/environment/aurora/ray-factor", 0.8 * rn);
		me.ray_bg = 0.4 * rn;
		
		rn = rand();
		setprop("/environment/aurora/patchiness", rn);
		
		rn = rand();
		setprop("/environment/aurora/upper-alt-factor", rn);
		me.upper_bg = 0.5 * rn;
		
		me.strength_bg = 0.4 * rand();
		
		me.strength_rate = me.strength_rate * me.delta_t;
		me.ray_rate = me.ray_rate * me.delta_t;
		me.glow_rate = me.glow_rate * me.delta_t;
		me.upper_rate = me.upper_rate * me.delta_t;
	
		# me.storm_probability = me.storm_probability * me.delta_t;
				
		
	},
	
	state: func {
	
		var state = getprop("/environment/aurora/aurora-manager");
		print("Aurora state manager");
		if (state == 1) {me.start();}
		else {me.stop();}
	
	},
	
	start: func {
	
		if (me.running_flag == 1) {return;}
		
		print("Starting aurora manager.");
		
		me.running_flag = 1;
		me.ray_target = me.ray_bg;
		me.upper_target = me.upper_bg;
		me.strength_target = getprop("/environment/aurora/set-strength");
		me.ray_current = me.ray_target;
		me.upper_current = me.ray_target;
		me.strength_current = me.ray_target;

		
		me.update();
	
	},
	
	stop: func {
		
		me.running_flag = 0;
		print("Stopping aurora manager.");

		
	},
	
	update: func {
	
		if (me.running_flag == 0) {return;}
		
		
		if ((rand() < me.storm_probability) and (me.storm_flag == 0) and (me.afterglow_flag == 0))# init auroral storm
				{
				me.storm_flag = 1;
				me.storm_timer = 0;
				me.storm_duration = 60.0 + rand() * 120.0;
				me.storm_duration *= 0.4;
				print("Auroral storm duration: ", me.storm_duration, " s");
				}
				
		if (me.storm_flag == 1)
				{
				if (me.storm_timer < me.storm_duration)
					{
					me.strength_target = 1.0;
					me.ray_target = 0.7;
					me.upper_target = 1.0;
					}
				else	
					{
					me.ray_target = me.ray_bg;
					me.storm_flag = 0;
					me.afterglow_timer = 0;
					me.afterglow_flag = 1;
					}
				
				me.storm_timer = me.storm_timer + me.delta_t;
				}
		if (me.afterglow_flag == 1)
				{
					if (me.afterglow_timer < 60)
						{
						me.glow_target = 1.0 - me.strength_bg;
						}
					else if (me.afterglow_timer < 120)
						{
						me.upper_target = me.upper_bg;
						me.strength_target = me.strength_bg;
						me.glow_target = 0.0;
						}
					else	
						{
						me.afterglow_flag = 0;
						}
					
				me.afterglow_timer = me.afterglow_timer + me.delta_t;
				}
				
		
		me.evolve();
	
	
		settimer (func me.update(), me.delta_t);
	
	},
	
	
	evolve: func  {
	
	
			if (me.strength_current < me.strength_target)
				{
				me.strength_current = me.strength_current + me.strength_rate;
				if (me.strength_current > me.strength_target) {me.strength_current = me.strength_target;}
				}
			else if (me.strength_current > me.strength_target)
				{
				me.strength_current = me.strength_current - me.strength_rate;
				if (me.strength_current < me.strength_target) {me.strength_current = me.strength_target;}
				}

			if (me.ray_current < me.ray_target)
				{
				me.ray_current = me.ray_current + me.ray_rate;
				if (me.ray_current > me.ray_target) {me.ray_current = me.ray_target;}
				}
			else if (me.ray_current > me.ray_target)
				{
				me.ray_current = me.ray_current - me.ray_rate;
				if (me.ray_current < me.ray_target) {me.ray_current = me.ray_target;}
				}	

			if (me.upper_current < me.upper_target)
				{
				me.upper_current = me.upper_current + me.upper_rate;
				if (me.upper_current > me.upper_target) {me.upper_current = me.upper_target;}
				}
			else if (me.upper_current > me.upper_target)
				{
				me.upper_current = me.upper_current - me.upper_rate;
				if (me.upper_current < me.upper_target) {me.upper_current = me.upper_target;}
				}	

			if (me.glow_current < me.glow_target)
				{
				me.glow_current = me.glow_current + me.glow_rate;
				if (me.glow_current > me.glow_target) {me.glow_current = me.glow_target;}
				}
			else if (me.glow_current > me.glow_target)
				{
				me.glow_current = me.glow_current - me.glow_rate;
				if (me.glow_current < me.glow_target) {me.glow_current = me.glow_target;}
				}				

			setprop("/environment/aurora/set-strength", me.strength_current);
			setprop("/environment/aurora/ray-factor", me.ray_current);
			setprop("/environment/aurora/upper-alt-factor", me.upper_current);
			setprop("/environment/aurora/afterglow", me.glow_current);

	},
	

};

aurora_manager.init();
