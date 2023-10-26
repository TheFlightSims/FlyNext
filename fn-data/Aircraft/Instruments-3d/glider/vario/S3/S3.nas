# LX Vario S3 by Benedikt Wolf (D-ECHO) based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

# THANKS TO Colin Geniet (SoundPitchController), original developers of the ilec-sc7 (WooT)

# Information based on manual http://www.lx-avionik.de/wp/download/manuals/LXS3ManualGermanVer0100.pdf
#######################################

## REQUIRES:
##	* second altimeter module enabled from <sim><instrumentation>
##	* power supply from systems/electrical/outputs/S3
##	(opt) * vario sound set up in the aircraft's sound file (see S3-sound.txt as an example)

#####################
## Version 05/2020 ##
#####################
## Features of this version:
##	* use maketimer, only update visible pages
##	* use props.nas, store in local variables where sensible
##	* store instrument directory in variable
##	* clarity through indentation
##	* use functions for common functionality
##	* clean up listeners

var S3_start = nil;
var S3_main = nil;
var S3_display = nil;

var s3		=	props.globals.initNode("/instrumentation/s3");

var start_prop		=	s3.initNode("start", 0.0, "DOUBLE");
var pushknob_prop	=	s3.initNode("knob-pushed", 0, "BOOL");

var te_rdg	=	s3.initNode("te-reading-mps", 0.0, "DOUBLE");
var te_avg	=	s3.initNode("te-average-mps", 0.0, "DOUBLE");
var volume	=	s3.initNode("volume", 0.5, "DOUBLE");

var alt		=	props.globals.initNode("instrumentation/altimeter[1]/indicated-altitude-ft", 0.0, "DOUBLE");
var volt_prop	=	props.globals.initNode("/systems/electrical/outputs/S3", 0.0, "DOUBLE");

var mc		=	s3.initNode("mc", 1.5, "DOUBLE");

var needle	=	s3.initNode( "needle-deg", 0.0, "DOUBLE" );

var instrument_dir	=	"Aircraft/Instruments-3d/glider/vario/S3/";

var canvas_S3_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Bold.ttf";
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		var start = start_prop.getDoubleValue();
		var volts = volt_prop.getDoubleValue();
		if ( start == 1 and volts > 9 ) {
			S3_start.page.hide();
			S3_main.page.show();
			S3_main.update();
		} else if ( start > 0 and start < 1 and volts > 9 ){
			S3_main.page.hide();
			S3_start.page.show();
		} else {
			S3_main.page.hide();
			S3_start.page.hide();
		}
	},
};
	
	
var canvas_S3_main = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_S3_main , canvas_S3_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["altitude","average","average.needle","mccready.needle"];
	},
	update: func() {
		
		#Altimeter
		me["altitude"].setText( sprintf( "%4d", math.round( alt.getDoubleValue() * FT2M ) ) );
		
		
		#Average climbrate
		var av = te_avg.getDoubleValue();
		me["average"].setText(sprintf("%2.1f", av));
		if(av<5 and av>-5){
			var av2=av;
		}else if(av<-5){
			var av2=-5;
		}else if(av>5){
			var av2=5;
		}
		me["average.needle"].setRotation(av2*D2R*24);
		
		#McCready
		me["mccready.needle"].setRotation( mc.getDoubleValue()*D2R*24 );
	}
	
};


var canvas_S3_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_S3_start , canvas_S3_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	}
	
};

var s3_update = maketimer(0.2, func() { canvas_S3_base.update() } );
s3_update.simulatedTime = 1;

var vario_needle_ctrl = func {
	if( start_prop.getDoubleValue() == 1.0 ){
		needle.setDoubleValue( math.clamp( te_rdg.getDoubleValue() * 24, -132, 132 ) );	# max deflection: 132 deg at +- 5.5 m/s
	} else {
		needle.setDoubleValue( 0.0 );
	}
}

var needle_update = maketimer( 0.0, vario_needle_ctrl );
needle_update.simulatedTime = 1;

var ls = setlistener("sim/signals/fdm-initialized", func {
	S3_display = canvas.new({
		"name": "S3",
		"size": [320, 240],
		"view": [320, 240],
		"mipmapping": 1
	});
	S3_display.addPlacement({"node": "S3.display"});
	var groupMain = S3_display.createGroup();
	var groupStart = S3_display.createGroup();


	S3_main = canvas_S3_main.new(groupMain, instrument_dir~"S3_main.svg");
	S3_start = canvas_S3_start.new(groupStart, instrument_dir~"S3_start.svg");
	
	s3_update.start();
	needle_update.start();
	
	removelistener(ls);
});

var i=0;

var check_off = func () {
	if( pushknob_prop.getBoolValue() and i<50){
		i=i+1;
		settimer(check_off, 0.1);
	}else if( pushknob_prop.getBoolValue() and i >= 50){
		i=0;
		start_prop.setDoubleValue( 0.0 ); #put proper shutdown routine here later
	}else{
		i=0;
	}
}

var check_electric_off = func () {
	if( volt_prop.getDoubleValue() < 9.0 and start_prop.getDoubleValue() != 0.0 ){
		start_prop.setDoubleValue( 0.0 );
	}
}


setlistener(pushknob_prop, func {
	if( pushknob_prop.getBoolValue() ) {
		if( volt_prop.getDoubleValue() >= 9.0 and start_prop.getDoubleValue() == 0.0 ){
			interpolate(start_prop, 1, 4 );
		} else {
			check_electric_off();
		}
		check_off();
	}
});


setlistener(volt_prop, func {
	check_electric_off();
});



#The following code is based on the ILEC SC7 e-vario and computes the different values shown by the display and the mechanical needle
io.include("Aircraft/Generic/soaring-instrumentation-sdk.nas");

####################################
####	INSTRUMENT SETUP	####
####################################

# Vario sound pitch controller by Colin Geniet (for ASK21), thanks!
#
# var vario_sound = SoundPitchController.new(
#   input: Object connected to the pitch controller input, e.g. a variometer reading.
#   max_pitch: (optional) Maximum sound frequency factor, the output will be
#              in the range [1/max_pitch, max_pitch], default 2.
#   max_input: Value of input for which max_pitch is reached.
#	on_update: (optional) function to call whenever a new output is available

var SoundPitchController = {
	parents: [InstrumentComponent],
	
	new: func(input, max_input, max_pitch = 2, on_update = nil) {
		return {
			parents: [me],
			input: input,
			max_pitch: max_pitch,
			max_input: max_input,
			on_update: on_update,
		};
	},
	
	update: func {
		var input = math.clamp(me.input.output, -me.max_input, me.max_input);
		me.output = math.pow(me.max_pitch, input / me.max_input);
		
		if (me.on_update != nil) me.on_update(me.output);
	},
};

var probe = TotalEnergyProbe.new();

var s3_needle = Dampener.new(
	input: probe,
	dampening: 1.5, 
	on_update: update_prop("/instrumentation/s3/te-reading-mps"));#1.5 is default dampening value according to POH

var averager = Averager.new(
	input: probe,
	buffer_size: 20,
	on_update: update_prop("/instrumentation/s3/te-average-mps")); #20s is default time according to POH
	
var s3_sound = SoundPitchController.new(
	input: s3_needle,
	max_input: 5,
	on_update: update_prop("/instrumentation/s3/sound-pitch"));

# Wrap everything together into an instrument
var fast_instruments = UpdateLoop.new(
	update_period: 0,
	components: [probe, s3_needle, s3_sound],
	enable: 1);

var slow_instruments = UpdateLoop.new(
	update_period: 1,
	components: [averager],
	enable: 1);
	
