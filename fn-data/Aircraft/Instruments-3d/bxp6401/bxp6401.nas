# Becker Transponder BXP6401 by Benedikt Wolf (D-ECHO) based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)

#	Reference:	http://www.becker-avionics.com/wp-content/uploads/2018/06/BXP6401_IO_issue05.pdf

## REQUIRES:
##	* transponder module enabled from <sim><instrumentation>
##	* power supply from systems/electrical/outputs/transponder (default)

#####################
## Version 05/2020 ##
#####################
## Features of this version:
##	* use maketimer, only update visible pages
##	* use props.nas, store in local variables where sensible
##	* store instrument directory in variable
##	* use of arrays where sensible
##	* clarity through indentation
##	* use functions for common functionality
##	* clean up listeners
##	* self-sufficient: does not need properties to be set-up via -set/-main/-base file (exceptions: "REQUIRES"-section)

var BXP6401_start = nil;
var BXP6401_ai = nil;
var BXP6401_alt = nil;
var BXP6401_display = nil;
var page = "start";

var transponder	=	props.globals.getNode("/instrumentation/transponder[0]");
var inputs	=	transponder.getNode("inputs");

var mode_prop	=	inputs.initNode("knob-mode", 0, "INT");
var start_prop	=	transponder.initNode("start", 0.0, "DOUBLE");
var volt_prop	=	props.globals.initNode("/systems/electrical/outputs/transponder", 15.0, "DOUBLE");
var active_prop	=	inputs.initNode("current-change", 0, "INT");
var ident_prop	=	inputs.initNode("ident-btn", 0, "BOOL");
var idcode_prop	=	transponder.initNode("id-code", 7000, "INT");
var alt		=	transponder.getNode("altitude");
var alt_val	=	transponder.getNode("altitude-valid");
var brightness	=	transponder.initNode("brightness", 0.5, "DOUBLE");

var ident_arr		=	[0, 0, 0, 0];
var ident_prop_arr	=	[	inputs.initNode("digit[0]", 7, "INT"), 
					inputs.initNode("digit[1]", 0, "INT"), 
					inputs.initNode("digit[2]", 0, "INT"), 
					inputs.initNode("digit[3]", 0, "INT"),	];

var instrument_dir	=	"Aircraft/Instruments-3d/bxp6401/";


var canvas_BXP6401_base = {
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
		var mode = mode_prop.getIntValue();
		var start = start_prop.getDoubleValue();
		if ( start == 1.0 and volt_prop.getDoubleValue() > 10 and mode != 0 ) {
			BXP6401_start.page.hide();
			if(mode==1 or mode==4){
				BXP6401_ai.page.show();
				BXP6401_ai.update();
				BXP6401_alt.page.hide();
			}else if(mode==5){
				BXP6401_alt.page.show();
				BXP6401_alt.update();
				BXP6401_ai.page.hide();
			}else{
				mode_prop.setIntValue(1);	#GND and TEST not available for this transponder, so we reset to STBY
			}
		} else if ( start > 0.0 and start < 1.0 and volt_prop.getDoubleValue() > 10 and mode_prop.getIntValue() != 0){
			BXP6401_ai.page.hide();
			BXP6401_alt.page.hide();
			BXP6401_start.page.show();
		} else {
			BXP6401_ai.page.hide();
			BXP6401_alt.page.hide();
			BXP6401_start.page.hide();
		}
	},
	update_common: func() {
		
		#IDENT (ID) FLAG
		if( ident_prop.getBoolValue() == 1 ){
			me["ident.flag"].show();
		}else{
			me["ident.flag"].hide();
		}
		
		#ID CODE
		var cc = active_prop.getIntValue();
		forindex(var i; ident_arr){
			ident_arr[i] = ident_prop_arr[i].getIntValue();
		}
		if( cc == 0 ){
			me["id1.change"].hide();
			me["id2.change"].hide();
			me["id3.change"].hide();
			me["id4.change"].hide();
			me["id1.digit"].show();
			me["id2.digit"].show();
			me["id3.digit"].show();
			me["id4.digit"].show();
			me["id1.digit"].setText(sprintf("%1d", ident_arr[3]));
			me["id2.digit"].setText(sprintf("%1d", ident_arr[2]));
			me["id3.digit"].setText(sprintf("%1d", ident_arr[1]));
			me["id4.digit"].setText(sprintf("%1d", ident_arr[0]));
		}else if ( cc == 1 ){
			me["id1.change"].show();
			me["id1.change.digit"].setText(sprintf("%1d", ident_arr[3]));
			me["id2.change"].hide();
			me["id3.change"].hide();
			me["id4.change"].hide();
			me["id1.digit"].hide();
			me["id2.digit"].show();
			me["id3.digit"].show();
			me["id4.digit"].show();
			me["id2.digit"].setText(sprintf("%1d", ident_arr[2]));
			me["id3.digit"].setText(sprintf("%1d", ident_arr[1]));
			me["id4.digit"].setText(sprintf("%1d", ident_arr[0]));
		}else if ( cc == 2 ){
			me["id2.change"].show();
			me["id2.change.digit"].setText(sprintf("%1d", ident_arr[2]));
			me["id1.change"].hide();
			me["id3.change"].hide();
			me["id4.change"].hide();
			me["id1.digit"].show();
			me["id2.digit"].hide();
			me["id3.digit"].show();
			me["id4.digit"].show();
			me["id1.digit"].setText(sprintf("%1d", ident_arr[3]));
			me["id3.digit"].setText(sprintf("%1d", ident_arr[1]));
			me["id4.digit"].setText(sprintf("%1d", ident_arr[0]));
		}else if ( cc == 3 ){
			me["id3.change"].show();
			me["id3.change.digit"].setText(sprintf("%1d", ident_arr[1]));
			me["id1.change"].hide();
			me["id2.change"].hide();
			me["id4.change"].hide();
			me["id1.digit"].show();
			me["id2.digit"].show();
			me["id3.digit"].hide();
			me["id4.digit"].show();
			me["id1.digit"].setText(sprintf("%1d", ident_arr[3]));
			me["id2.digit"].setText(sprintf("%1d", ident_arr[2]));
			me["id4.digit"].setText(sprintf("%1d", ident_arr[0]));
		}else if ( cc == 4 ){
			me["id4.change"].show();
			me["id4.change.digit"].setText(sprintf("%1d", ident_arr[0]));
			me["id1.change"].hide();
			me["id2.change"].hide();
			me["id3.change"].hide();
			me["id1.digit"].show();
			me["id2.digit"].show();
			me["id3.digit"].show();
			me["id4.digit"].hide();
			me["id1.digit"].setText(sprintf("%1d", ident_arr[3]));
			me["id2.digit"].setText(sprintf("%1d", ident_arr[2]));
			me["id3.digit"].setText(sprintf("%1d", ident_arr[1]));
		}
		
	},
};
	
	
var canvas_BXP6401_ai = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_BXP6401_ai , canvas_BXP6401_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["ident.flag","r.flag","id1.digit","id2.digit","id3.digit","id4.digit","id1.change","id1.change.digit","id2.change","id2.change.digit","id3.change","id3.change.digit","id4.change","id4.change.digit","status"];
	},
	update: func() {
		#Status (STBY/ON)
		var stat = mode_prop.getIntValue();
		if( stat == 1 ){
			me["status"].setText("SBY");
		}else if( stat == 4 ) {
			me["status"].setText("ON");
		}else{
			me["status"].setText("FAIL");
		}
		
		me.update_common();
	}
	
};


var canvas_BXP6401_alt = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_BXP6401_alt , canvas_BXP6401_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["ident.flag","r.flag","id1.digit","id2.digit","id3.digit","id4.digit","id1.change","id1.change.digit","id2.change","id2.change.digit","id3.change","id3.change.digit","id4.change","id4.change.digit","altitude"];
	},
	update: func() {
		#Altitude (FL)
		if( alt_val.getBoolValue() ){
			me["altitude"].setText(sprintf("%03d", math.round( alt.getDoubleValue() /100)));
		}else{
			me["altitude"].setText("---");
		}
		
		me.update_common();
	}
	
};


var canvas_BXP6401_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_BXP6401_start , canvas_BXP6401_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
	}
	
};

var update_bxp6401 = maketimer( 0.2, func () { canvas_BXP6401_base.update() } );

var ls = setlistener("sim/signals/fdm-initialized", func {
	BXP6401_display = canvas.new({
		"name": "BXP6401",
		"size": [1024, 512],
		"view": [1024, 512],
		"mipmapping": 1
	});
	BXP6401_display.addPlacement({"node": "BXP6401.display"});
	var groupAi = BXP6401_display.createGroup();
	var groupAlt = BXP6401_display.createGroup();
	var groupStart = BXP6401_display.createGroup();


	BXP6401_ai = canvas_BXP6401_ai.new(groupAi, instrument_dir~"bxp6401-ai.svg");
	BXP6401_alt = canvas_BXP6401_alt.new(groupAlt, instrument_dir~"bxp6401-alt.svg");
	BXP6401_start = canvas_BXP6401_start.new(groupStart, instrument_dir~"bxp6401-start.svg");

	update_bxp6401.start();
	
	removelistener(ls);
});

var identoff = func {
	ident_prop.setIntValue(0);
}

var ident_btn = func() {
	ident_prop.setIntValue(1);
	settimer(identoff, 18);
}

var check_state	= func() {
	if( mode_prop.getIntValue() != 0 and volt_prop.getDoubleValue() > 10 and start_prop.getDoubleValue() == 0){
		interpolate(start_prop, 1, 1 );
	}else if( ( mode_prop.getIntValue() == 0 or volt_prop.getDoubleValue() <= 10 ) and start_prop.getDoubleValue() != 0){
		start_prop.setDoubleValue(0.0);
	}
}

setlistener(mode_prop, func{
	check_state();
});

setlistener(volt_prop, func{
	check_state();
});
