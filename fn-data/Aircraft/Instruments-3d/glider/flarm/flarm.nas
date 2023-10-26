##		FLARM
##	Version 09/2022
##	by Benedikt Wolf (D-ECHO)

##	References:
##	[1]	https://flarm.com/wp-content/uploads/man/FLARM_OperatingManual_E.pdf	(FLARM Technology and traditional/main instrument)
##	[2]	https://swiss-bat.ch/.cm4all/iproc.php/flarm/Handbuch_V3%2B_FW571_DV100-a-EN.pdf?cdp=a	(for v3 display, the one described there additionally has a numerical distance indicator)

# Initialize necessary properties
var flarm_base	=	props.globals.initNode("/instrumentation/flarm");
var play_newcontact	=	flarm_base.initNode("new-contact", 0, "BOOL");
var play_warn		=	flarm_base.initNode("warn", 0, "INT");			# two warning levels: 0 = off; 1 = warning level 1; 2 = warning level 2
var receive_flag	=	flarm_base.initNode("receive", 0, "BOOL");
var ub_leds		=	[
	flarm_base.initNode("ub-LED[0]", 0, "BOOL"),
	flarm_base.initNode("ub-LED[1]", 0, "BOOL"),
	flarm_base.initNode("ub-LED[2]", 0, "BOOL"),
	flarm_base.initNode("ub-LED[3]", 0, "BOOL"),	];
var leds_green		=	[];
var leds_red		=	[];
for( var i = 0; i <= 11; i = i + 1 ){
	append(leds_green, flarm_base.initNode("LED["~i~"]", 0, "BOOL"));
	append(leds_red, flarm_base.initNode("LED-red["~i~"]", 0, "BOOL"));
}

var volts	=	props.globals.initNode("systems/electrical/outputs/flarm", 0.0, "DOUBLE");
var track	=	props.globals.getNode("/orientation/track-deg");
var ai_models	=	props.globals.getNode("/ai/models");
var elapsed_sec	=	props.globals.getNode("/sim/time/elapsed-sec");

var version = 202209;	# used for backwards compatibility (e.g. Salus Combined Instrument)

# Initialize Arrays to internally store targets and warnings
var targets	=	[];
var warnings	=	[];
var targets_tracked	=	[];

# Initialize internal variables
var max_dist	=	4;	# according to [1] typically 3-5km, depending on installation of antenna
var running	=	0;

#Set properties
for(var f=0; f<=30; f=f+1){
	append(targets, nil);
	append(warnings, nil);
	append(targets_tracked, 0);
}

# Helper function to return relative bearing towards target
var relative = func (brg, heading) {
	brg = brg - heading;
	return geo.normdeg(brg);
}

# Helper function to play sound for new contact
var new_contact = func ()  { #Sound message for new contact
	play_newcontact.setBoolValue( !play_newcontact.getBoolValue() );
}

#	Target class
var Target = {
	new : func(n, type, scnd){
		m = { parents : [Target] };
		m.id=n;
		m.prop_path = ai_models.getNode(type ~ "[" ~n~ "]" );
		m.lat = m.prop_path.getNode("position/latitude-deg");
		m.lon = m.prop_path.getNode("position/longitude-deg");
		m.alt = m.prop_path.getNode("position/altitude-ft");
		m.pos = geo.Coord.new().set_latlon(	m.lat.getDoubleValue(),
							m.lon.getDoubleValue(),
							m.alt.getDoubleValue()	);
		m.hdg = m.prop_path.getNode("orientation/true-heading-deg");
		m.vario = m.prop_path.getNode("velocities/vertical-speed-fps");
		m.second=0.0;
		var ac = geo.aircraft_position();
		m.last_dist = m.pos.direct_distance_to( ac );
		new_contact();
		return m;
	},
    
	update_data : func(){
		me.pos.set_latlon(	me.lat.getDoubleValue(),
					me.lon.getDoubleValue(),
					me.alt.getDoubleValue()	);
	},
    
	update_LED : func( scnd ) {
		var ac = geo.aircraft_position();
		#Time difference
		var delta_time = scnd - me.second;
		me.second = scnd;
		var actual_dist_now = me.pos.direct_distance_to( ac );
		
		#Delta Distance
		var delta_dist = ( me.last_dist - actual_dist_now ) / delta_time;
		
		#(Theoretical) time to collision
		if( delta_dist == 0 ){
			ttc=999;
		}else{
			var ttc = actual_dist_now / delta_dist;
		}
		
		if( ttc <= 0 ){
			ttc = 999;
		}
		
		var LED = [0,0,0,0,0,0,0,0,0,0,0,0];
		
		var bearing = ac.course_to( me.pos );
		var relative_bearing = relative( bearing, track.getDoubleValue() );
		
		var alt_diff = math.abs( ( me.pos.alt() * FT2M ) - ac.alt() );	#Altitude difference in meters
		
		if( ttc < 6 and alt_diff < 150){
			#Warn 1: all LEDs red
			warnings[me.id]=2;
			forindex(var key; LED){
				LED[key]=2;
			}
		}else if(ttc<14 and alt_diff < 300){
			#Warn 2: corresponding LED red
			warnings[me.id]=1;
			LED[int(relative_bearing/30+1)-1] = 2;
		}else{
			#Normal: corresponding LED green
			warnings[me.id]=0;
			LED[int(relative_bearing/30+1)-1] = 1;
		}
		
		me.last_dist=actual_dist_now;
		
		return LED;
	},
	update_ub : func(){
		var ac = geo.aircraft_position();
		var alt_diff = ( me.pos.alt() * FT2M ) - ac.alt(); #Altitude difference in meters
		var distance = ac.distance_to(me.pos);
		var angle = ( math.atan( alt_diff/distance ) )*R2D;
		return angle;
	},
	get_distance : func() {
		return me.pos.alt();
	},
};


setlistener("/sim/signals/fdm-initialized", func{
	phase1_timer = maketimer( 0.2, flarm_start_phase2 );
	phase2_timer = maketimer( 5, flarm_start_phase3 );
	phase3_timer = maketimer( 2, flarm_start_phase4 );
	startup_loop_timer = maketimer( 0, startup_loop );
	
	phase1_timer.singleShot = 1;
	phase2_timer.singleShot = 1;
	phase3_timer.singleShot = 1;
});


var update_FLARM = func{
	# Check MP first, AI afterwards
	var type = "multiplayer";
	for(var f = 0; f < 15; f += 1){
		if(getprop("/ai/models/"~ type ~"[" ~f~ "]/position/latitude-deg") != nil){
			var temp_pos = geo.Coord.set_latlon(	getprop("/ai/models/"~ type ~"[" ~f~ "]/position/latitude-deg"),
								getprop("/ai/models/"~ type ~"[" ~f~ "]/position/longitude-deg"),
								getprop("/ai/models/"~ type ~"[" ~f~ "]/position/altitude-ft"));
							
			#Check whether in range and target not already existing
			var distance_km = temp_pos.distance_to(geo.aircraft_position())/1000;
			if( distance_km < max_dist and targets_tracked[f] == 0){
				#Now generate a target
				targets[f]=Target.new( f, type, elapsed_sec.getDoubleValue() );
				targets_tracked[f] = 1;
			}else if( distance_km > max_dist and targets_tracked[f] == 1){
				#Target existing, but has moved meanwhile out of range
				targets[f] = nil;
				targets_tracked[f] = 0;
			}
		} else if ( targets_tracked[f] == 1){
			#Target existing, but has meanwhile logged out
			targets[f]=nil;
			targets_tracked[f] = 0;
		}
	}
	type = "aircraft";
	for(var f = 0; f < 15; f += 1){
		if(getprop("/ai/models/"~ type ~"[" ~f~ "]/position/latitude-deg") != nil){
			var temp_pos = geo.Coord.set_latlon(	getprop("/ai/models/"~ type ~"[" ~f~ "]/position/latitude-deg"),
								getprop("/ai/models/"~ type ~"[" ~f~ "]/position/longitude-deg"),
								getprop("/ai/models/"~ type ~"[" ~f~ "]/position/altitude-ft"));
							
			#Check whether in range and target not already existing
			var distance_km = temp_pos.distance_to(geo.aircraft_position())/1000;
			if( distance_km < max_dist and targets_tracked[ f+15 ] == 0){
				#Now generate a target
				targets[ f+15 ]=Target.new( f, type, elapsed_sec.getDoubleValue() );
				targets_tracked[ f+15 ] = 1;
			}else if( distance_km > max_dist and targets_tracked[ f+15 ] == 1){
				#Target existing, but has moved meanwhile out of range
				targets[ f+15 ] = nil;
				targets_tracked[ f+15 ] = 0;
			}
		} else if ( targets_tracked[ f+15 ] == 1){
			#Target existing, but has meanwhile logged out
			targets[ f+15 ]=nil;
			targets_tracked[ f+15 ] = 0;
		}
	}
	
	receive = 0;
	
	forindex(var key; targets){
		if(targets[key] != nil){
			targets[key].update_data();
			receive=1;
		}
	}	
	
	#Check LEDs
	#12 LEDS, each cover 30 degrees	
	
	var stored_distance=9999;
	var used_angle=nil;
	var LEDs=[0,0,0,0,0,0,0,0,0,0,0,0];
	forindex(var key; targets){
		if(targets[key]!=nil){
			var LED=targets[key].update_LED( elapsed_sec.getDoubleValue() );	#Get the value each time again because it should be precisely the current time
			forindex(var f; LED){
				if(LED[f]==1){
					LEDs[f]=1;
				}else if(LED[f]==2){
					LEDs[f]=2;
				}
			}
			var angle=targets[key].update_ub();
			var distance=targets[key].get_distance();
			if(distance<stored_distance){
				used_angle=angle;
				stored_distance=distance;
			}
			
		}
	}
	if(used_angle!=nil){
		if(used_angle > 14){
			ub_leds[0].setBoolValue(1);
			ub_leds[1].setBoolValue(0);
			ub_leds[2].setBoolValue(0);
			ub_leds[3].setBoolValue(0);
		}else if(used_angle > 0){
			ub_leds[0].setBoolValue(0);
			ub_leds[1].setBoolValue(1);
			ub_leds[2].setBoolValue(0);
			ub_leds[3].setBoolValue(0);
		}else if(used_angle < -14){
			ub_leds[0].setBoolValue(0);
			ub_leds[1].setBoolValue(0);
			ub_leds[2].setBoolValue(0);
			ub_leds[3].setBoolValue(1);
		}else if(used_angle < 0){
			ub_leds[0].setBoolValue(0);
			ub_leds[1].setBoolValue(0);
			ub_leds[2].setBoolValue(1);
			ub_leds[3].setBoolValue(0);
		}else{
			ub_leds[0].setBoolValue(0);
			ub_leds[1].setBoolValue(0);
			ub_leds[2].setBoolValue(0);
			ub_leds[3].setBoolValue(0);
		}
	}else{
		ub_leds[0].setBoolValue(0);
		ub_leds[1].setBoolValue(0);
		ub_leds[2].setBoolValue(0);
		ub_leds[3].setBoolValue(0);
	}
	
	forindex(var key; LEDs){
		if(LEDs[key]<=1){
			leds_green[key].setBoolValue(LEDs[key]);
			leds_red[key].setBoolValue(0);
		}else if(LEDs[key]==2){
			leds_green[key].setBoolValue(0);
			leds_red[key].setBoolValue(1);
		}
			
	}
	
	#Check Warning sounds
	warn=0;
	forindex(var key; warnings){
		if(warnings[key]==2 and warn<2){
			warn=2;
		}else if(warnings[key]==1 and warn<1){
			warn=1;
		}
	}
	play_warn.setValue(warn);
	
	
	
	if ( volts.getDoubleValue() > 9){
		receive_flag.setBoolValue(receive);
		if( running == 0 ){
			running = 1;
		}
	} else {
		running = 0;
		foreach(var led; leds_green){
			led.setBoolValue(0);
		}
		foreach(var led; leds_red){
			led.setBoolValue(0);
		}
		foreach(var led; ub_leds){
			led.setBoolValue(0);
		}
		receive_flag.setBoolValue(0);
		flarm_update.stop();
	}
}

var flarm_update = maketimer( 1, func() { update_FLARM(); } );
flarm_update.simulatedTime = 1;

# Startup as described in [1], p.6
var phase1_timer = nil;
var phase2_timer = nil;
var phase3_timer = nil;
var startup_loop_timer = nil;

var starting = 0;

var leds_startup = {
	green: [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	red: [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
};

var startup_loop = func {
	if( !starting ){
		startup_loop_timer.stop();
	}
	if( volts.getDoubleValue() > 9 ){
		forindex( var key; leds_startup.green ){
			leds_green[key].setBoolValue( leds_startup.green[ key ] );
			leds_red[key].setBoolValue( leds_startup.red[ key ] );
		}
	} else {
		foreach( var el; leds_startup.green ){
			el = 0;
		}
		foreach( var el; leds_startup.red ){
			el = 0;
		}
		forindex(var key; leds_green){
			leds_green[key].setBoolValue(0);
			leds_red[key].setBoolValue(0);
		}
		starting = 0;
	}
}

flarm_start_phase1 = func () {
	if( volts.getDoubleValue() <= 9 ){
		return;
	}
	# 1. Short beep, all LEDs light up
	forindex(var key; leds_startup.green ){
		leds_startup.green[ key ] = 1;
		leds_startup.red[ key ] = 1;
	}
	play_warn.setIntValue(1);
	phase1_timer.restart(0.2);
}
flarm_start_phase2 = func () {
	if( volts.getDoubleValue() <= 9 ){
		return;
	}
	# beep and LEDs off except to show hardware version (here: show green LEDs 0 and 1)
	play_warn.setIntValue(0);
	forindex(var key; leds_startup.green){
		if( key > 1 ){
			leds_startup.green[key] = 0;
		}
		leds_startup.red[key] = 0;
	}
	phase2_timer.restart(5);
}
flarm_start_phase3 = func () {
	if( volts.getDoubleValue() <= 9 ){
		return;
	}
	# Show firmware version ( emit green LEDs 7 and 8 as well as 2 and 3 )
	leds_startup.green[0]= 0;
	leds_startup.green[1]= 0;
	leds_startup.green[2]= 1;
	leds_startup.green[3]= 1;
	leds_startup.green[7]= 1;
	leds_startup.green[8]= 1;
	phase3_timer.restart(2);
}
flarm_start_phase4 = func () {
	if( volts.getDoubleValue() <= 9 ){
		return;
	}
	# Go to normal operation
	starting = 0;
	running = 1;
	flarm_update.restart(1);
}

setlistener(volts, func{
	if( running == 0 and starting == 0 and volts.getDoubleValue() > 9) {
		starting = 1;
		flarm_start_phase1();
		startup_loop_timer.restart( 0 );
	}
});
