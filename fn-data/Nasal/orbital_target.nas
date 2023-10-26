###########################################################################
# simulation of a faraway orbital target (needs handover to spacecraft-specific 
# code for close range)
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#
# Thorsten Renk 2016-2019
###########################################################################


var orbitalTarget = {
	new: func(altitude, inclination, node_longitude, anomaly) {
	        var t = { parents: [orbitalTarget] };
		t.altitude = altitude;
		t.radius = 20908323.0 * 0.3048 + t.altitude;
		t.GM =  398759391386476.0; 
		#t.GM = 	 398600441800000.0;
		t.period = 2.0 * math.pi * math.sqrt(math.pow(t.radius, 3.0)/ t.GM);
		t.inclination = inclination;
		t.inc_rad = t.inclination * math.pi/180.0;
		t.l_vec = [math.sin(t.inc_rad), 0.0, math.cos(t.inc_rad)];
		t.node_longitude = node_longitude;
		t.nl_rad = t.node_longitude * math.pi/180.0;
		t.initial_nl_rad = t.nl_rad;
		var l_tmp = t.l_vec[0];
		t.l_vec[0] = math.sin(t.nl_rad) * l_tmp;
		t.l_vec[1] = -math.cos(t.nl_rad) * l_tmp;
		t.anomaly = anomaly;
		t.anomaly_rad = t.anomaly * math.pi/180.0;
		t.initial_anomaly_rad = t.anomaly_rad;
		t.delta_lon = 0.0;
		t.update_time = 0.1;
		t.running_flag = 0;
		t.elapsed_time = 0.0;
		t.delta_time = 0.0;
		t.label = "";

		print ("Orbital Period: ", t.period);

		# Coefficients  for the J3 altitude variation

		var inc_var = t.inclination/60.0;
		#print ("inc_var:", inc_var);

		t.coeff1 =  (10268. - 0.99579 * (t.altitude / 1000.0)) * inc_var;
		t.coeff2 = 0.212 * 2.0 * math.pi;		


		#t.node_drift = -4361.26 * 1./math.pow(t.radius/1000.0 ,2.0) * math.cos(t.inc_rad); 
		
		t.node_drift = -2.16732e+9 /math.pow(t.radius/1000.0, 3.48908) * math.cos(t.inc_rad); 	
	
		print ("Drift rate: ", t.node_drift);
		return t;
	},

	set_anomaly: func (anomaly) {

		t.anomaly = anomaly;
		t.anomaly_rad = t.anomaly * math.pi/180.0;

	},

	set_delta_lon: func (dl) {
		t.delta_lon = dl;
	},

	list: func {

		print("Radius: ", me.radius, " period: ", me.period);
		print("L_vector: ", me.l_vec[0], " ", me.l_vec[1], " ", me.l_vec[2]);
		print("L_norm: ", math.sqrt(me.l_vec[0] * me.l_vec[0] + me.l_vec[1] * me.l_vec[1] + me.l_vec[2] * me.l_vec[2]));
		var pos = me.get_inertial_pos();
		print("Inertial: ", pos[0], " ", pos[1], " ", pos[2]);
		print("Rad: ", math.sqrt(pos[0] * pos[0] + pos[1] * pos[1] + pos[2] * pos[2]));
		var lla = me.get_latlonalt();
		print("Lat: ", lla[0], " lon: ", lla[1], " alt: ", lla[2]);
	},
	
	evolve: func {
		var dt = getprop("/sim/time/delta-sec");
		#var speedup = getprop("/sim/speed-up");
		#dt = dt * speedup;
		me.anomaly_rad = me.anomaly_rad + dt/me.period * 2.0 * math.pi;
		if (me.anomaly_rad > 2.0 * math.pi)
			{
			me.anomaly_rad = me.anomaly_rad - 2.0 * math.pi;
			}
		me.anomaly = me.anomaly_rad * 180.0/math.pi;
		me.delta_lon = me.delta_lon + dt * 0.00418333333333327;
		me.node_longitude = me.node_longitude + me.node_drift * dt;
		me.nl_rad = me.node_longitude * math.pi/180.0;

		me.l_vec = [math.sin(me.inc_rad), 0.0, math.cos(me.inc_rad)];
		var l_tmp = me.l_vec[0];
		me.l_vec[0] = math.sin(me.nl_rad) * l_tmp;
		me.l_vec[1] = -math.cos(me.nl_rad) * l_tmp;
	
		#print (me.label);


	},
	get_inertial_pos: func {

		return me.compute_inertial_pos(me.anomaly_rad, me.nl_rad);

	},

	get_inertial_pos_at_time: func (time) {


		var anomaly_rad = me.initial_anomaly_rad + (time - me.delta_time)/me.period * 2.0 * math.pi;
		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		var nl_rad = me.initial_nl_rad + me.node_drift * (time - me.delta_time) * math.pi/180.0;

		return me.compute_inertial_pos(anomaly_rad, nl_rad);

	},



	get_inertial_speed: func () {

		# obtain via numerical discretization from two points
	
		var anomaly_rad = me.anomaly_rad;
		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		var pos1 = me.compute_inertial_pos(anomaly_rad, me.nl_rad);

		anomaly_rad = me.anomaly_rad + 0.1/me.period * 2.0 * math.pi;
		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		var pos2 = me.compute_inertial_pos(anomaly_rad, me.nl_rad);

		var vx = (pos2[0] - pos1[0])/0.1;
		var vy = (pos2[1] - pos1[1])/0.1;
		var vz = (pos2[2] - pos1[2])/0.1;

		return [vx, vy, vz];
	},

	get_inertial_speed_at_time: func (time) {

		# obtain via numerical discretization from two points
	
		var anomaly_rad = me.initial_anomaly_rad + (time- me.delta_time)/me.period * 2.0 * math.pi;
		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		var nl_rad = me.initial_nl_rad + me.node_drift * (time - me.delta_time) * math.pi/180.0;
		var pos1 = me.compute_inertial_pos(anomaly_rad, nl_rad);

		anomaly_rad = me.initial_anomaly_rad + ((time - me.delta_time) + 0.1)/me.period * 2.0 * math.pi;
		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		nl_rad = me.initial_nl_rad + me.node_drift * ((time - me.delta_time) +0.1) * math.pi/180.0;
		var pos2 = me.compute_inertial_pos(anomaly_rad, nl_rad);

		var vx = (pos2[0] - pos1[0])/0.1;
		var vy = (pos2[1] - pos1[1])/0.1;
		var vz = (pos2[2] - pos1[2])/0.1;

		return [vx, vy, vz];
	},



	compute_inertial_pos: func (anomaly_rad, nl_rad) {

		# J3 variation around radius

		while (anomaly_rad > 2.0 * math.pi)
			{
			anomaly_rad = anomaly_rad - 2.0 * math.pi;
			}

		while (anomaly_rad < 0.0)
			{
			anomaly_rad = anomaly_rad + 2.0 * math.pi;
			}



		var r_corr = me.coeff1 * math.exp(- math.pow(((anomaly_rad - math.pi)/ me.coeff2),2.0));

		#r_corr = 0.0;
		#print (r_corr);


		# movement around equatorial orbit
		var x = (me.radius + r_corr) * math.cos(anomaly_rad);
		var y = (me.radius + r_corr) * math.sin(anomaly_rad);
		var z = 0;
	
		# tilt with inclination
		z = y * math.sin(me.inc_rad);
		y = y * math.cos(me.inc_rad);


		# rotate with node longitude

		var xp = x * math.cos(nl_rad) - y * math.sin(nl_rad);
		var yp = x * math.sin(nl_rad) + y * math.cos(nl_rad); 

		# this is a good bit of trickery to capture leading J3 dynamics

		var corr_200 = 	-2.6e-5 * me.inclination + 1.00321;
		
		var corr = corr_200 * (1.0 + (me.altitude/1000.0-200.0) * 6e-7);
		
		corr = 1.0 + (0.64 * (corr -1.0));
		#print ("Corr200 is now:", corr_200);
		#print ("Corr is now:", corr);
		#print ("Altitude: ", me.altitude);
		
		var radius_orig = math.sqrt(xp * xp + yp * yp + z* z);


		z /= corr;

		var radius_corr = math.sqrt(xp * xp + yp * yp + z* z);

		xp *= radius_orig/radius_corr;		
		yp *= radius_orig/radius_corr;		
		z *= radius_orig/radius_corr;		

		return [xp, yp, z];

	},

	get_latlonalt: func {

		var coordinates = geo.Coord.new();
		var inertial_pos = me.get_inertial_pos();
		coordinates.set_xyz(inertial_pos[0], inertial_pos[1], inertial_pos[2]);
		coordinates.set_lon(coordinates.lon() - me.delta_lon);
	
		return [coordinates.lat(), coordinates.lon(), coordinates.alt()];
	},

	start: func {
		if (me.running_flag == 1) {return;}
		me.running_flag = 1;
		me.run();

	},
	stop: func {
		me.running_flag = 0;
	},

	run: func {
		me.evolve (me.update_time);
		if (me.running_flag == 1)
			{settimer(func me.run(), 0);}
	},
	

	test_suite: func {

		var time = 0;
		var radius = 0;
		var pos = [];

		for (var i = 0; i< 300; i=i+1)
			{
			time = i * 60;
			pos = me.get_inertial_pos_at_time(time);
			
			radius = math.sqrt(pos[0] * pos[0] + pos[1] * pos[1] + pos[2] * pos[2]);		

			print (time, " ", radius);
			

			}

	},

};
