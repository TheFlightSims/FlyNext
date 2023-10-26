#
#			TOWING NASAL CODE
#
#		original version by D-NXKT up to version 30.12.2014
#		updates by Benedikt Wolf and D-NXKT, version 01/2023
#
#
# Purpose of this routine:
# ------------------------
#
# - Create visible winch- and towropes for gliders and towplanes
# - Support of aerotowing and winch for JSBSim-aircraft (glider and towplanes)
#
# This routine is very similar to /FDM/YASim/Hitch.cpp
# Aerotowing is fully compatible to the YASim functionality.
# This means that YASim-gliders could be towed by JSBSim-aircraft and vice versa.
# Setup-instructions with copy and paste examples are given below:
#
#
# Setup of visible winch/towropes for Yasim-aircraft:
# ----------------------------------------------------
#
# YASim-aircraft with winch/aerotowing functionality should work out of the box.
# Optional you can customize the rope-diameter by adding the following to "your_aircraft-set.xml":
# </sim>
#  <hitches>
#   <aerotow>
#    <rope>
#     <rope-diameter-mm type ="float">10</rope-diameter-mm>
#    </rope>
#   </aerotow>
#   <winch>
#    <rope>
#     <rope-diameter-mm type ="float">20</rope-diameter-mm>
#    </rope>
#   </winch>
#  </hitches>
# </sim>
#
# That's all!
#
#
#
# Support of aerotowing and winch for JSBSim-aircraft (glider and towplanes):
# ----------------------------------------------------------------------------
#
# 1. Define a hitch in the JSBSim-File. Coordinates according to JSBSims structural frame of reference
# (x points to the tail, y points to the right wing, z points upwards).
# Unit must be "LBS", frame must be "BODY". The force name is arbitrary.
#
# <external_reactions>
#  <force name="hitch" frame="BODY" unit="LBS" >
#   <location unit="M">
#    <x>3.65</x>
#    <y> 0.0</y>
#    <z>-0.12</z>
#   </location>
#   <direction>
#    <x>0.0</x>
#    <y>0.0</y>
#    <z>0.0</z>
#   </direction>
#  </force>
# </external_reactions>


# 2. Define controls for aerotowing and winch.
# Add the following key bindings in "yourAircraft-set.xml":
# <input>
#  <keyboard>
#
#   <key n="15">
#     <name>Ctrl-o</name>
#     <desc>Find aircraft for aerotow</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.findBestAIObject()</script>
#     </binding>
#   </key>
#
#   <key n="111">
#     <name>o</name>
#     <desc>Lock aerotow-hook</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.closeHitch()</script>
#     </binding>
#   </key>
#
#   <key n="79">
#     <name>O</name>
#     <desc>Open aerotow-hook</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.releaseHitch("aerotow")</script>
#     </binding>
#   </key>
#
#   <key n="23">
#     <name>Ctrl-w</name>
#     <desc>Place Winch and hook in</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.setWinchPositionAuto()</script>
#     </binding>
#   </key>
#
#   <key n="119">
#     <name>w</name>
#     <desc>Start winch</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.runWinch()</script>
#     </binding>
#   </key>
#
#   <key n="87">
#     <name>W</name>
#     <desc>Open winch-hook</desc>
#     <binding>
#	<command>nasal</command>
#	<script>towing.releaseHitch("winch")</script>
#     </binding>
#   </key>
#
#  </keyboard>
# </input>
#
# For towplanes only "key n=79" (Open aerotow-hook) is required!


# 3. Set mandatory properties:
#<sim>
# <hitches>
#  <aerotow>
#   <force_name_jsbsim type="string">hitch</force_name_jsbsim>
#   <force-is-calculated-by-other type="bool">false</force-is-calculated-by-other>
#   <mp-auto-connect-period type="float">0.0</mp-auto-connect-period>
#   <!-- OPTIONAL
#     <decoupled-force-and-rope-locations type="bool">true</decoupled-force-and-rope-locations>
#     <local-pos-x type="float">1.5</local-pos-x>
#     <local-pos-y type="float"> 0.00</local-pos-y>
#     <local-pos-z type="float">-0.3</local-pos-z>
#   -->
#  </aerotow>
#  <winch>
#   <force_name_jsbsim type="string">hitch</force_name_jsbsim>
#   <!-- OPTIONAL
#     <decoupled-force-and-rope-locations type="bool">true</decoupled-force-and-rope-locations>
#     <local-pos-x type="float">0.0</local-pos-x>
#     <local-pos-y type="float">0.0</local-pos-y>
#     <local-pos-z type="float">0.0</local-pos-z>
#   -->
#  </winch>
# </hitches>
#</sim>
#
# "force_name_jsbsim" must be the external force name in JSBSim.
# "force-is-calculated-by-other" should be "false" for gliders and "true" for tow planes.
# "mp-auto-connect-period" is only needed for tow planes and should be "1".
#
# IMPORTANT:
# The hitch location is stored twice in the property tree (for tow force and for rope animation).
# This is necessary to keep the towrope animation compatible to YASim-aircraft.
# The hitch location for the tow force is stored in "fdm/jsbsim/external_reactions/hitch/location-x(yz)-in" and for the
# animated towrope in "sim/hitches/aerotow(winch)/local-pos-x(yz)".
# By default only values for the tow force location have to be defined. The values for the towrope location are set
# automatically (decoupled-force-and-rope-locations is "false" by default).
# It is feasible to use different locations for the force and rope. In order to do this, you have to set
# "decoupled-force-and-rope-locations" to "true" and provide values for "sim/hitches/aerotow(winch)/local-pos-x(yz)".
# Note that the frame of reference is different. Here the coordinates for the "YASim-System" are needed
# (x points to the nose, y points to the left wing, z points upwards).


# 4. Set optional properties:
#
# Only aircraft-specific properties should be set by the aircraft. All other options can be adjusted by the
# winch GUI dialog and are stored by this script itself (TODO)
#
# Aircraft-specific properties are
#	* weak link (aerotow/winch)
#		sim/hitches/aerotow/tow/break-fource [N]
#		sim/hitches/winch/tow/break-force [N]
#	* typical tow speed (winch)
#		sim/hitches/winch/typical-tow-speed-kph [kph]
#	* automatic release angle (winch)
#		sim/hitches/winch/automatic-release-angle-deg [deg]
#
#<sim>
# <hitches>
#  <aerotow>
#   <tow>
#    <break-force type="float">6000</break-force>
#   </tow>
#  </aerotow>
#  <winch>
#   <automatic-release-angle-deg type="float">70.</automatic-release-angle-deg>
#	<typical-tow-speed-kph type="float">100</typical-tow-speed-kph>
#	<typical-tow-force-N type="float">5000</typical-tow-force-N>
#   <tow>
#    <break-force type="float">10000</break-force>
#   </tow>
#  </winch>
# </hitches>
#<sim>


# That's it!


##################################################  general info  ############################################
#
# 3 different types of towplanes could exist: AI-plane, MP-plane without interaction, MP-plane with interaction.
# AI-planes are identified by the node "ai/models/aircraft/" or "ai/models/dragger".
# MP-planes (interactice/non-interactive) are identified by the existence of node "ai/models/multiplayer".
# Interactive MP-plane: variables in node "ai/models/multiplayer/sim/hitches/" are updated.
# Non-interactive MP-plane: variables are not updated (values are either not defined or have "wrong" values
# from a former owner of this node.
#
# The following properties are transmitted in multiplayer:
# "sim/hitches/aerotow/tow/elastic-constant"
# "sim/hitches/aerotow/tow/weight-per-m-kg-m"
# "sim/hitches/aerotow/tow/dist"
# "sim/hitches/aerotow/tow/connected-to-property-node"
# "sim/hitches/aerotow/tow/connected-to-ai-or-mp-callsign"
# "sim/hitches/aerotow/tow/break-force"
# "sim/hitches/aerotow/tow/end-force-x"
# "sim/hitches/aerotow/tow/end-force-y"
# "sim/hitches/aerotow/tow/end-force-z"
# "sim/hitches/aerotow/is-slave"
# "sim/hitches/aerotow/speed-in-tow-direction"
# "sim/hitches/aerotow/open", open);
# "sim/hitches/aerotow/local-pos-x"
# "sim/hitches/aerotow/local-pos-y"
# "sim/hitches/aerotow/local-pos-z"
#
##############################################################################################################




# ######################################################################################################################
#                                            check, if towing support makes sense
# ######################################################################################################################

# Check if node "sim/hitches" is defined. If not, return!
if (props.globals.getNode("sim/hitches") == nil ) return;
print("towing is active!");


# ######################################################################################################################
#                                           set defaults / initialize at startup
# ######################################################################################################################

# set defaults for properties that are NOT already defined

var fdm	=	getprop("/sim/flight-model") or "";

if ( !(fdm == "jsb" or fdm == "yasim") ){
	print("Unsupported FDM for towing");
	return;
}

var check_or_create = func ( name, value, type ) {
	if ( getprop( name ) == nil ){
		return props.globals.initNode(name, value, type);
	} else {
		return props.globals.getNode(name);
	}
}

#	Load stored settings
var config_file = getprop("/sim/fg-home") ~ "/Export/hitch-config.xml";

var load_prop = func( property, cnfg_p ){
	if( cnfg_p != nil ){
		property.setValue( cnfg_p.getValue() );
	}
}

var config = {
	aerotow: {
		elastic_constant:	props.globals.initNode("sim/hitches/aerotow/tow/elastic-constant", 9111.0, "DOUBLE"), # saved in config
		weight_per_m_kg_m:	props.globals.initNode("sim/hitches/aerotow/tow/weight-per-m-kg-m", 0.35, "DOUBLE"), # saved in config
		length:				props.globals.initNode("sim/hitches/aerotow/tow/length", 60.0, "DOUBLE"), # saved in config
		path_to_model:		props.globals.initNode("sim/hitches/aerotow/rope/path_to_model", "Models/Aircraft/towropes.xml", "STRING"), # saved in config
		rope_diameter_mm:	props.globals.initNode("sim/hitches/aerotow/rope/rope-diameter-mm", 20.0, "DOUBLE"), # saved in config
	},
	winch: {
		elastic_constant:	props.globals.initNode("sim/hitches/winch/tow/elastic-constant", 40001.0, "DOUBLE"), # saved in config
		weight_per_m_kg_m:	props.globals.initNode("sim/hitches/winch/tow/weight-per-m-kg-m", 0.1, "DOUBLE"), # saved in config
		initial_tow_length:	props.globals.initNode("sim/hitches/winch/winch/initial-tow-length-m", 1000.0, "DOUBLE"), # saved in config
		path_to_model:		props.globals.initNode("sim/hitches/winch/rope/path_to_model", "Models/Aircraft/towropes.xml", "STRING"), # saved in config
		rope_diameter_mm:	props.globals.initNode("sim/hitches/winch/rope/rope-diameter-mm", 20.0, "DOUBLE"), # saved in config

		rope_breakage: {
			height:		props.globals.initNode("sim/hitches/winch/breakage/height", 100.0, "DOUBLE"), # saved in config
			random:		props.globals.initNode("sim/hitches/winch/breakage/random", 0, "BOOL"), # saved in config
		},
		loss_of_power: {
			height:		props.globals.initNode("sim/hitches/winch/loss-of-power/height", 100.0, "DOUBLE"), # saved in config
			random:		props.globals.initNode("sim/hitches/winch/loss-of-power/random", 0, "BOOL"), # saved in config
		},
		max_tow_length_m:	props.globals.initNode("sim/hitches/winch/winch/max-tow-length-m", 1500.0, "DOUBLE"), # saved in config
		max_spool_speed:	props.globals.initNode("sim/hitches/winch/winch/max-spool-speed-m-s", 40.0, "DOUBLE"), # saved in config

		force_acceleration:	props.globals.initNode("sim/hitches/winch/winch/force-acceleration-N-s", 1000.0, "DOUBLE"), # saved in config
		spool_acceleration:	props.globals.initNode("sim/hitches/winch/winch/spool-acceleration-m-s-s", 8.0, "DOUBLE"), # saved in config

		max_unspool_speed:	props.globals.initNode("sim/hitches/winch/winch/max-unspool-speed-m-s", 40.0, "DOUBLE"), # saved in config
		max_force:			props.globals.initNode("sim/hitches/winch/winch/max-force-N", 10000.0, "DOUBLE"), # saved in config
		max_power:			props.globals.initNode("sim/hitches/winch/winch/max-power-kW", 123.0, "DOUBLE"), # saved in config
		magic_constant:		props.globals.initNode("sim/hitches/winch/winch/magic-constant", 500.0, "DOUBLE"), # saved in config

		messages: {
			launch_signaller:	props.globals.initNode("/sim/hitches/winch/messages/launch-signaller", 1, "BOOL"), # saved in config
			winch_driver:	props.globals.initNode("/sim/hitches/winch/messages/winch-driver", 1, "BOOL"), # saved in config
			pilot:		props.globals.initNode("/sim/hitches/winch/messages/pilot", 1, "BOOL"), # saved in config
			remote_ac:		props.globals.initNode("/sim/hitches/winch/messages/remote-ac", 1, "BOOL"), # saved in config
		},
	},
};

var write_config = func {
	var c = props.Node.new();
	var a = c.addChild("aerotow");
	var w = c.addChild("winch");

	a.initNode("elastic-constant").setDoubleValue( config.aerotow.elastic_constant.getDoubleValue() );
	a.initNode("weight-per-m-kg-m").setDoubleValue( config.aerotow.weight_per_m_kg_m.getDoubleValue() );
	a.initNode("length").setDoubleValue( config.aerotow.length.getDoubleValue() );
	a.initNode("path_to_model","","STRING").setValue( config.aerotow.path_to_model.getValue() );
	a.initNode("rope-diameter-mm").setDoubleValue( config.aerotow.rope_diameter_mm.getDoubleValue() );

	w.initNode("elastic-constant").setDoubleValue( config.winch.elastic_constant.getDoubleValue() );
	w.initNode("weight-per-m-kg-m").setDoubleValue( config.winch.weight_per_m_kg_m.getDoubleValue() );
	w.initNode("initial-tow-length-m").setDoubleValue( config.winch.initial_tow_length.getDoubleValue() );
	w.initNode("path_to_model","","STRING").setValue( config.winch.path_to_model.getValue() );
	w.initNode("rope-diameter-mm").setDoubleValue( config.winch.rope_diameter_mm.getDoubleValue() );
	w.initNode("breakage/height").setDoubleValue(config.winch.rope_breakage.height.getDoubleValue() );
	w.initNode("breakage/random",0,"BOOL").setBoolValue(config.winch.rope_breakage.random.getBoolValue() );
	w.initNode("loss-of-power/height").setDoubleValue(config.winch.loss_of_power.height.getDoubleValue() );
	w.initNode("loss-of-power/random",0,"BOOL").setBoolValue(config.winch.loss_of_power.random.getBoolValue() );
	w.initNode("max-tow-length-m").setDoubleValue( config.winch.max_tow_length_m.getDoubleValue() );
	w.initNode("max-spool-speed-m-s").setDoubleValue( config.winch.max_spool_speed.getDoubleValue() );
	w.initNode("force-acceleration-N-s").setDoubleValue( config.winch.force_acceleration.getDoubleValue() );
	w.initNode("spool-acceleration-m-s-s").setDoubleValue( config.winch.spool_acceleration.getDoubleValue() );
	w.initNode("max-unspool-speed-m-s").setDoubleValue( config.winch.max_unspool_speed.getDoubleValue() );
	w.initNode("max-force-N").setDoubleValue( config.winch.max_force.getDoubleValue() );
	w.initNode("max-power-kW").setDoubleValue( config.winch.max_power.getDoubleValue() );
	w.initNode("magic-constant").setDoubleValue( config.winch.magic_constant.getDoubleValue() );
	w.initNode("messages/launch-signaller",1,"BOOL").setBoolValue( config.winch.messages.launch_signaller.getBoolValue() );
	w.initNode("messages/winch-driver",1,"BOOL").setBoolValue( config.winch.messages.winch_driver.getBoolValue() );
	w.initNode("messages/pilot",1,"BOOL").setBoolValue( config.winch.messages.pilot.getBoolValue() );
	w.initNode("messages/remote-ac",1,"BOOL").setBoolValue( config.winch.messages.remote_ac.getBoolValue() );

	io.write_properties( config_file, c );
}

if( io.stat( config_file ) != nil ){
	var config_properties = io.read_properties( config_file );

	load_prop( config.aerotow.elastic_constant, config_properties.getNode("aerotow/elastic-constant") );
	load_prop( config.aerotow.weight_per_m_kg_m, config_properties.getNode("aerotow/weight-per-m-kg-m") );
	load_prop( config.aerotow.length, config_properties.getNode("aerotow/length") );
	load_prop( config.aerotow.path_to_model, config_properties.getNode("aerotow/path_to_model") );
	load_prop( config.aerotow.rope_diameter_mm, config_properties.getNode("aerotow/rope-diameter-mm") );

	load_prop( config.winch.elastic_constant, config_properties.getNode("winch/elastic-constant") );
	load_prop( config.winch.weight_per_m_kg_m, config_properties.getNode("winch/weight-per-m-kg-m") );
	load_prop( config.winch.initial_tow_length, config_properties.getNode("winch/initial-tow-length-m") );
	load_prop( config.winch.path_to_model, config_properties.getNode("winch/path_to_model") );
	load_prop( config.winch.rope_diameter_mm, config_properties.getNode("winch/rope-diameter-mm") );
	load_prop( config.winch.rope_breakage.height, config_properties.getNode("winch/breakage/height") );
	load_prop( config.winch.rope_breakage.random, config_properties.getNode("winch/breakage/random") );
	load_prop( config.winch.loss_of_power.height, config_properties.getNode("winch/loss-of-power/height") );
	load_prop( config.winch.loss_of_power.random, config_properties.getNode("winch/loss-of-power/random") );
	load_prop( config.winch.max_tow_length_m, config_properties.getNode("winch/max-tow-length-m") );
	load_prop( config.winch.max_spool_speed, config_properties.getNode("winch/max-spool-speed-m-s") );
	load_prop( config.winch.force_acceleration, config_properties.getNode("winch/force-acceleration-N-s") );
	load_prop( config.winch.spool_acceleration, config_properties.getNode("winch/spool-acceleration-m-s-s") );
	load_prop( config.winch.max_unspool_speed, config_properties.getNode("winch/max-unspool-speed-m-s") );
	load_prop( config.winch.max_force, config_properties.getNode("winch/max-force-N") );
	load_prop( config.winch.max_power, config_properties.getNode("winch/max-power-kW") );
	load_prop( config.winch.magic_constant, config_properties.getNode("winch/magic-constant") );
	load_prop( config.winch.messages.launch_signaller, config_properties.getNode("winch/messages/launch-signaller") );
	load_prop( config.winch.messages.winch_driver, config_properties.getNode("winch/messages/winch-driver") );
	load_prop( config.winch.messages.pilot, config_properties.getNode("winch/messages/pilot") );
	load_prop( config.winch.messages.remote_ac, config_properties.getNode("winch/messages/remote-ac") );
}

var aircraft_settings = {
	aerotow: {
		force_calc_by_other:	check_or_create("sim/hitches/aerotow/force-is-calculated-by-other", 0, "BOOL"),	# aircraft-specific
		is_slave:			check_or_create("sim/hitches/aerotow/is-slave", 0, "BOOL"),	# aircraft-specific
		break_force:		check_or_create("sim/hitches/aerotow/tow/break-force", 12345.0, "DOUBLE"),	# aircraft-specific
		local_pos:	[
						check_or_create("sim/hitches/aerotow/local-pos-x", 0.0, "DOUBLE"),	# aircraft-specific
						check_or_create("sim/hitches/aerotow/local-pos-y", 0.0, "DOUBLE"),	# aircraft-specific
						check_or_create("sim/hitches/aerotow/local-pos-z", 0.0, "DOUBLE"),	# aircraft-specific
				],
	},
	winch: {
		typical_tow_speed:		props.globals.getNode("sim/hitches/winch/typical-tow-speed-kph"),
		typical_tow_force:		props.globals.getNode("sim/hitches/winch/typical-tow-force-N"),
						# Winch type: 0 = tow with constant force; 1 = tow with constant rope speed; aircraft-specific
		type_p:				check_or_create("sim/hitches/winch/type", 0, "INT"),
		break_force:			check_or_create("sim/hitches/winch/tow/break-force", 12345.0, "DOUBLE"),	# aircraft-specific
		local_pos:	[
							check_or_create("sim/hitches/winch/local-pos-x", 0.0, "DOUBLE"), # aircraft-specific
							check_or_create("sim/hitches/winch/local-pos-y", 0.0, "DOUBLE"), # aircraft-specific
							check_or_create("sim/hitches/winch/local-pos-z", 0.0, "DOUBLE"), # aircraft-specific
		],
	},
};

var check_aircraft_tow_settings = func{
	if( aircraft_settings.winch.typical_tow_speed == nil ){
		aircraft_settings.winch.typical_tow_speed = props.globals.initNode( "sim/hitches/winch/typical-tow-speed-kph" );

		# Estimate typical tow speed from aircraft weight, this will inherently be a rough guess
		#	Estimation basis:
		#			type	|	typical tow speed	|	typical weight	|	reference
		#		hang glider	|		50 kph			|		100 kg		|	https://www.safa.asn.au/resources/Tow%20Manual%20v5.4.1.pdf
		#		Ka6			|		90 kph			|		250 kg		|	http://www.smbc-eferding.at/wp-content/uploads/2014/01/Flughandbuch-Ka-6.pdf
		#		LS8			|		120 kph			|		500 kg		|	https://www.sglenzburg.ch/org/public/Dokumente/SGL/10-AFM/fhb_ls8a_rev3_tm8020.pdf
		#		DG-1000S	|		130 kph			|		650 kg		|	http://adelaidesoaring.on.net/wp-content/uploads/2014/01/DG-1000s-Flight-Manual.pdf
		#
		#	a quadratic regression for this data leads to y = -0.0002x2 + 0.3286x + 20.839, we use (simplified): f(x) = -0.0002 * x^2 + 0.33 * x + 21
		var weight_kg = weight_lb.getDoubleValue() * LB2KG;
		aircraft_settings.winch.typical_tow_speed.setDoubleValue( -0.0002 * weight_kg * weight_kg + 0.33 * weight_kg + 21 );
	}
	if( aircraft_settings.winch.typical_tow_force == nil ){
		aircraft_settings.winch.typical_tow_force = props.globals.initNode( "sim/hitches/winch/typical-tow-force-N" );

		aircraft_settings.winch.typical_tow_force.setDoubleValue( 0.15 * math.pow( weight_lb.getDoubleValue(), 1.25 ) * LB2KG * 9.81);
	}
}

# yasim properties for aerotow (should be already defined for yasim aircraft but not for JSBSim aircraft
var aerotow_hash = {
	broken: 		props.globals.initNode("sim/hitches/aerotow/broken", 0, "BOOL"),
	force: 			props.globals.initNode("sim/hitches/aerotow/force", 0.0, "DOUBLE"),
	mp_auto_connect_period:	props.globals.initNode("sim/hitches/aerotow/mp-auto-connect-period", 0.0, "DOUBLE"),
	mp_time_lag:	props.globals.initNode("sim/hitches/aerotow/mp-time-lag", 0.0, "DOUBLE"),
	open:			props.globals.initNode("sim/hitches/aerotow/open", 1, "BOOL"),	#always init to true
	speed_tow_direction:	props.globals.initNode("sim/hitches/aerotow/speed-in-tow-direction", 0.0, "DOUBLE"),
	old_open:		props.globals.initNode("sim/hitches/aerotow/oldOpen", 1, "BOOL"),
	tow: {
		conn_ai_node:		props.globals.initNode("sim/hitches/aerotow/tow/connected-to-ai-node", 0, "BOOL"),
		conn_ai_or_mp_callsign:	props.globals.initNode("sim/hitches/aerotow/tow/connected-to-ai-or-mp-callsign", "", "STRING"),
		conn_ai_or_mp_id:	props.globals.initNode("sim/hitches/aerotow/tow/connected-to-ai-or-mp-id", 0, "INT"),
		conn_mp_node:		props.globals.initNode("sim/hitches/aerotow/tow/connected-to-mp-node", 0, "BOOL"),
		conn_prop_node:		props.globals.initNode("sim/hitches/aerotow/tow/connected-to-property-node", 0, "BOOL"),
		dist:				props.globals.initNode("sim/hitches/aerotow/tow/dist", 0.0, "DOUBLE"),
		end_force:	[
			props.globals.initNode("sim/hitches/aerotow/tow/end-force-x", 0.0, "DOUBLE"),
			props.globals.initNode("sim/hitches/aerotow/tow/end-force-y", 0.0, "DOUBLE"),
			props.globals.initNode("sim/hitches/aerotow/tow/end-force-z", 0.0, "DOUBLE"),
		],
		node:			props.globals.initNode("sim/hitches/aerotow/tow/node", "", "STRING"),
		length:		props.globals.initNode("sim/hitches/aerotow/tow/length", 60.0, "DOUBLE"),
	},
	rope: {
		exist:			props.globals.initNode("sim/hitches/aerotow/rope/exist", 0, "BOOL"),
		model_id:		props.globals.initNode("sim/hitches/aerotow/rope/model_id", -1, "INT"),
		
		lat:			props.globals.initNode("ai/models/aerotowrope/position/latitude-deg", 0.0, "DOUBLE"),
		lon:			props.globals.initNode("ai/models/aerotowrope/position/longitude-deg", 0.0, "DOUBLE"),
		alt:			props.globals.initNode("ai/models/aerotowrope/position/altitude-ft", 0.0, "DOUBLE"),
		hdg:			props.globals.initNode("ai/models/aerotowrope/orientation/true-heading-deg", 0.0, "DOUBLE"),
		pitch:			props.globals.initNode("ai/models/aerotowrope/orientation/pitch-deg", 0.0, "DOUBLE"),
	},
};
				
# yasim properties for winch (should already be defined for yasim aircraft but not for JSBSim aircraft
var winch_hash = {
	open:			props.globals.initNode("sim/hitches/winch/open", 1, "BOOL"),	#always init to true
	broken:			props.globals.initNode("sim/hitches/winch/broken", 0, "BOOL"),
	type:			0,
	rope_breakage_p:	props.globals.initNode("sim/hitches/winch/breakage/enabled", 0, "BOOL"), # NOT saved in config: Must be selected explicitly each time
	rope_breakage:		0,
	rope_breakage_height_int: 100.0,
	loss_of_power: {
		enabled_p:	props.globals.initNode("sim/hitches/winch/loss-of-power/enabled", 0, "BOOL"), # NOT saved in config: Must be selected explicitly each time
		enabled:	0,
		height_int: 	100.0,
	},
	global_pos:	[
		props.globals.initNode("sim/hitches/winch/winch/global-pos-x", 0.0, "DOUBLE"),
		props.globals.initNode("sim/hitches/winch/winch/global-pos-y", 0.0, "DOUBLE"),
		props.globals.initNode("sim/hitches/winch/winch/global-pos-z", 0.0, "DOUBLE"),
		],
	tow: {
		length:			props.globals.initNode("sim/hitches/winch/tow/length", 0.0, "DOUBLE"),
		dist:			props.globals.initNode("sim/hitches/winch/tow/dist", 0.0, "DOUBLE"),
	},
	old_open:		props.globals.initNode("sim/hitches/winch/oldOpen", 1, "BOOL"),
	rope: {
		exist:			props.globals.initNode("sim/hitches/winch/rope/exist", 0, "BOOL"),
		model_id:		props.globals.initNode("sim/hitches/winch/rope/model_id", -1, "INT"),
		
		lat:			props.globals.initNode("ai/models/winchrope/position/latitude-deg", 0.0, "DOUBLE"),
		lon:			props.globals.initNode("ai/models/winchrope/position/longitude-deg", 0.0, "DOUBLE"),
		alt:			props.globals.initNode("ai/models/winchrope/position/altitude-ft", 0.0, "DOUBLE"),
		hdg:			props.globals.initNode("ai/models/winchrope/orientation/true-heading-deg", 0.0, "DOUBLE"),
		pitch:			props.globals.initNode("ai/models/winchrope/orientation/pitch-deg", 0.0, "DOUBLE"),
	},
};

var force_setting = 0.0;	# used with constant force type winch
var speed_setting = 0.0;	# used with constant speed type winch


if ( fdm == "jsb" ) {
	# new properties for JSBSim aerotow
	aircraft_settings.aerotow.force_name_jsbsim		= check_or_create("sim/hitches/aerotow/force_name_jsbsim", "hitch", "STRING"); # aircraft-specific
	aircraft_settings.aerotow.decoupled_locations	= check_or_create("sim/hitches/aerotow/decoupled-force-and-rope-locations", 0, "BOOL"); # aircraft-specific
	aircraft_settings.winch.force_name_jsbsim		= check_or_create("sim/hitches/winch/force_name_jsbsim", "hitch", "STRING"); # aircraft-specific
	aircraft_settings.winch.automatic_release_angle	= check_or_create("sim/hitches/winch/automatic-release-angle-deg", 361.0, "DOUBLE"); # aircraft-specific
	aircraft_settings.winch.decoupled_locations		= check_or_create("sim/hitches/winch/decoupled-force-and-rope-locations", 0, "BOOL"); # aircraft-specific

	aerotow_hash.mp_old_open	= props.globals.initNode("sim/hitches/aerotow/mp_oldOpen", 1, "BOOL");
	aerotow_hash.tow.mp_last_reported_dist	= props.globals.initNode("sim/hitches/aerotow/tow/mp_last_reported_dist", 0.0, "DOUBLE");
	
	# new properties for JSBSim winch
	winch_hash.clutched			= props.globals.initNode("sim/hitches/winch/winch/clutched", 0, "BOOL");
	winch_hash.actual_spool_speed		= props.globals.initNode("sim/hitches/winch/winch/actual-spool-speed-m-s", 0.0, "DOUBLE");
	
	winch_hash.actual_force			= props.globals.initNode("sim/hitches/winch/winch/actual-force-N", 0.0, "DOUBLE");
	
	var hitchname = aircraft_settings.winch.force_name_jsbsim.getValue();
	winch_hash.apply_force = {
		magnitude: props.globals.initNode("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/magnitude", 0.0, "DOUBLE"),
		coord:	[
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/x", 0.0, "DOUBLE"), # aircraft-specific
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/y", 0.0, "DOUBLE"), # aircraft-specific
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/z", 0.0, "DOUBLE"), # aircraft-specific
			],
	};
	
	var hitchname = aircraft_settings.aerotow.force_name_jsbsim.getValue();
	aerotow_hash.apply_force = {
		magnitude: props.globals.initNode("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/magnitude", 0.0, "DOUBLE"),
		coord:	[
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/x", 0.0, "DOUBLE"), # aircraft-specific
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/y", 0.0, "DOUBLE"), # aircraft-specific
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/z", 0.0, "DOUBLE"), # aircraft-specific
			],
	};
	
	# consider older JSBSim-versions which do NOT provide the locations of external_reactions in the property tree
	if( getprop("fdm/jsbsim/external_reactions/" ~ aircraft_settings.aerotow.force_name_jsbsim.getValue() ~ "/location-x-in") == nil ) {
		aircraft_settings.aerotow.decoupled_locations.setBoolValue( 1 );
	}
	if( getprop("fdm/jsbsim/external_reactions/" ~ aircraft_settings.winch.force_name_jsbsim.getValue() ~ "/location-x-in") == nil ) {
		aircraft_settings.winch.decoupled_locations.setBoolValue( 1 );
	}
	
	
	setlistener(aircraft_settings.winch.force_name_jsbsim , func() {
		var hitchname = aircraft_settings.winch.force_name_jsbsim.getValue();
		set_force_apply( winch_hash, hitchname );
	});
	setlistener(aircraft_settings.aerotow.force_name_jsbsim , func() {
		var hitchname = aircraft_settings.aerotow.force_name_jsbsim.getValue();
		set_force_apply( aerotow_hash, hitchname );
	});
}


var callsign		=	check_or_create("sim/multiplay/callsign", "", "STRING"); # session-specific

var message_pilot		=	props.globals.getNode("sim/messages/pilot", 1);
var message_ai		=	props.globals.getNode("sim/messages/ai-plane", 1);
var message_atc		=	props.globals.getNode("sim/messages/atc", 1);
var write_message = func( type, message ){
	if( type == "launch-signaller" ){
		if( config.winch.messages.launch_signaller.getBoolValue() ) message_atc.setValue( message );
	} elsif( type == "winch-driver" ){
		if( config.winch.messages.winch_driver.getBoolValue() ) message_ai.setValue( message );
	} elsif( type == "pilot" ){
		if( config.winch.messages.pilot.getBoolValue() ) message_pilot.setValue( message );
	} elsif( type == "remote-ac" ){
		if( config.winch.messages.remote_ac.getBoolValue() ) message_ai.setValue( message );
	} elsif( type == "system" ){
		message_atc.setValue( message );
	} else {
		screen.log.write( message ~ " [type: unknown]");
	}
}

var delta_time		=	props.globals.getNode("sim/time/delta-sec", 1);

var orientation = [
		props.globals.getNode("orientation/heading-deg", 1),
		props.globals.getNode("orientation/roll-deg", 1),
		props.globals.getNode("orientation/pitch-deg", 1),
	];

var wind_from		=	check_or_create("environment/wind-from-heading-deg", 0.0, "DOUBLE");
var wind_speed_kt	=	check_or_create("environment/wind-speed-kt", 0.0, "DOUBLE");
	
var set_force_apply = func ( hash, hitchname ){
	hash.apply_force = {
		magnitude: check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/magnitude", 0.0, "DOUBLE"),
		coord:	[
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/x", 0.0, "DOUBLE"),
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/y", 0.0, "DOUBLE"),
			check_or_create("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/z", 0.0, "DOUBLE"),
			],
	};
}


var loss_of_power = func () {
	# The maximum power is lost to 1/10 of it over a time span of 3 +- 1 seconds
	interpolate( config.winch.max_power, config.winch.max_power.getDoubleValue() / 10, 2 + 2 * rand() );
	# Afterwards it is completely lost after another 2 +- 1 seconds
	settimer( func() {
				interpolate( config.winch.max_power, 0, 1 + 2 * rand() );
			}, 3);
}
	

# ######################################################################################################################
#                                                         main function
# ######################################################################################################################

var towing = func {
	
	
	var dt = 0;
	
	# -------------------------------  aerotow part -------------------------------
	
	var open = aerotow_hash.open.getBoolValue();
	var oldOpen = aerotow_hash.old_open.getBoolValue();
	
	if ( open != oldOpen ) {   # check if my hitch state has changed, if yes: message
		
		if ( !open ) {      # my hitch was open and is closed now
			if ( fdm == "jsb" ) {
				var distance = aerotow_hash.tow.dist.getDoubleValue();
				var towlength_m = aerotow_hash.tow.length.getDoubleValue();
				if ( distance > towlength_m * 1.0001 ) {
					write_message( "system", sprintf("Could not lock hitch (tow length is insufficient) on hitch %i!", aerotow_hash.tow.conn_mp_node.getIntValue()) );
					aerotow_hash.open.setBoolValue( 1 );  # open my hitch again
				}  else {  # mp aircraft to far away
					# my hitch is closed
					write_message( "system", sprintf("Locked hitch aerotow %i!", aerotow_hash.tow.conn_mp_node.getIntValue()) );
				}
				aerotow_hash.broken.setBoolValue(0);
			}  # end: JSBSim
			if ( !aerotow_hash.open.getBoolValue() ) {
				# setup ai-towrope
				createTowrope("aerotow");
				
				# set default hitch coordinates (needed for Ai- and non-interactive MP aircraft)
				setAIObjectDefaults() ;
			}
		}  # end hitch is closed
		
		if ( open ) {   # my hitch is now open
			if ( fdm == "jsb" ) {
				if ( aerotow_hash.broken.getBoolValue() ) {
					#getprop("sim/hitches/aerotow/broken")
					write_message( "pilot", "Oh no, the tow is broken" );
				} else {
					write_message( "pilot", sprintf("Opened hitch aerotow %i!", aerotow_hash.tow.conn_mp_node.getIntValue() ) );
				}
				releaseHitch("aerotow"); # open=1 / forces=0
			}  # end: JSBSim
			removeTowrope("aerotow");   # remove towrope model
		}  # end hitch is open
		
		aerotow_hash.old_open.setBoolValue( open );
	}  # end hitch state has changed
	
	if (!open ) {
		aerotow(open);
		# end hitch is closed (open == 0)
	}  else {  
		# my hitch is open
		var mp_auto_connect_period = aerotow_hash.mp_auto_connect_period.getDoubleValue();
		if ( mp_auto_connect_period != 0 ) {   # if auto-connect
			if ( fdm == "jsb" ) {  # only for JSBSim aircraft
				findBestAIObject();
			}   # end JSBSim	aircraft
			dt = mp_auto_connect_period;
		} else {  # my hitch is open and not auto-connect
			dt = 0;
		}
	}
	
	# winch part
	if (!winch_hash.open.getBoolValue() ) {
		winch(winch_hash.open.getBoolValue());
	}
	
	settimer( towing, dt );
	
}   # end towing

setlistener( winch_hash.open, func {
	var winchopen = winch_hash.open.getBoolValue();
	var wincholdOpen = winch_hash.old_open.getBoolValue();
	
	if ( winchopen != wincholdOpen ) {   # check if my hitch state has changed, if yes: message
		if ( !winchopen ) {      # my hitch was open and is closed now
			if ( fdm == "jsb" ) {
				var distance = winch_hash.tow.dist.getDoubleValue();
				var towlength_m = winch_hash.tow.length.getDoubleValue();
				if ( distance > towlength_m ) {
					write_message( "system", sprintf("Could not lock hitch (tow length is insufficient) on hitch %i!", aerotow_hash.tow.conn_mp_node.getIntValue() ) );
					winch_hash.open.setBoolValue( 1 );  # open my hitch again
				} else {  # mp aircraft to far away
					# my hitch is closed
					write_message( "system", sprintf("Locked hitch winch %i!", aerotow_hash.tow.conn_mp_node.getIntValue() ) );
					winch_hash.clutched.setBoolValue( 0 );;
				}
				winch_hash.broken.setBoolValue( 0 );
				winch_hash.actual_spool_speed.setDoubleValue( 0.0 );
			}  # end: JSBSim
			if ( !winch_hash.open.getBoolValue() ) {
				# setup ai-towrope
				createTowrope("winch");
				
				# set default hitch coordinates (needed for Ai- and non-interactive MP aircraft)
				setAIObjectDefaults() ;
			}
		}  # end hitch is closed
		
		if ( winchopen ) {   # my hitch is now open
			if ( fdm == "jsb" ) {
				if ( winch_hash.broken.getBoolValue() ) {
					write_message( "pilot", "Oh no, the tow is broken" );
				}
				releaseHitch("winch");
			}  # end: JSBSim
			pull_in_rope();
		}  # end hitch is open
		
		winch_hash.old_open.setBoolValue( winchopen );
	} # end hitch state has changed
	
});

setlistener( aircraft_settings.winch.type_p, func {
	winch_hash.type = aircraft_settings.winch.type_p.getIntValue();
});


# ######################################################################################################################
#                                                   find best AI object
# ######################################################################################################################

var findBestAIObject = func (){
	
	# the nearest found plane, that is close enough will be used
	# set some default variables, needed later to identify if the found object is
	# an AI-Object, a "non-interactiv MP-Object or an interactive MP-Object
	
	# local variables
	var aiobjects = [];                    # keeps the ai-planes from the property tree
	var aiPosition = geo.Coord.new();      # current processed ai-plane
	var myPosition = geo.Coord.new();      # coordinates of glider
	var distance_m = 0;                    # distance to ai-plane
	
	var nodeIsAiAircraft = 0;
	var nodeIsMpAircraft = 0;
	var running_as_autoconnect = 0;
	var mp_open_last_state = 0;
	var isSlave = 0;
	
	if ( fdm == "yasim" ) return;	# bypass this routine for Yasim-aircraft
		
		
		if (aerotow_hash.mp_auto_connect_period.getDoubleValue() != 0 ) {
			var running_as_autoconnect = 1;
		}
		
		var towlength_m = aerotow_hash.tow.length.getDoubleValue();
	
	var bestdist_m = towlength_m; # initial value
	
	myPosition = geo.aircraft_position();
	# todo: calculate exact hitch position
	
	if( running_as_autoconnect ) {
		var mycallsign = callsign.getValue();
	}
	
	var found = 0;
	aiobjects = props.globals.getNode("ai/models").getChildren();
	foreach (var aimember; aiobjects) {
		if ( (var node = aimember.getName() ) != nil ) {
			nodeIsAiAircraft = 0;
			nodeIsMpAircraft = 0;
			if ( sprintf("%8s",node)  == "aircraft" or sprintf("%7s",node) == "dragger" )	nodeIsAiAircraft = 1;
			if ( sprintf("%11s",node) == "multiplayer" ) nodeIsMpAircraft = 1;
			if ( aimember.getNode("valid") == nil ) continue;
			if ( !nodeIsAiAircraft and !nodeIsMpAircraft) continue;
			if ( !aimember.getNode("valid").getValue() )   continue;   # node is invalid
				
				if( running_as_autoconnect ) {
					if ( !nodeIsMpAircraft ) continue;
					#if ( aimember.getValue("sim/hitches/aerotow/open") == nil ) continue; # this node MUST exist for mp-aircraft which want to be towed
					#if ( aimember.getValue("sim/hitches/aerotow/open") == 1 ) continue;   # if mp hook open, auto-connect is NOT possible
					if ( aimember.getValue("sim/hitches/aerotow/open") != 0 ) continue;
					if (mycallsign != aimember.getValue("sim/hitches/aerotow/tow/connected-to-ai-or-mp-callsign") ) continue ;  # I am the wrong one
					if ( !aerotow_hash.mp_old_open.getBoolValue() ) continue;	# this prevents an unwanted immediate auto-connect after the dragger
													# released its hitch. Firstly wait for a reported "open" hitch from glider
				}
				
				var lat_deg = aimember.getNode("position/latitude-deg").getValue();
				var lon_deg = aimember.getNode("position/longitude-deg").getValue();
				var alt_m = aimember.getNode("position/altitude-ft").getValue() * FT2M;
				
				var aiPosition = geo.Coord.set_latlon( lat_deg, lon_deg, alt_m );
				distance_m = (myPosition.distance_to(aiPosition));
				if ( distance_m < bestdist_m ) {
					bestdist_m = distance_m;
					
					var towEndNode = node;
					var nodeID = aimember.getNode("id").getValue();
					var aicallsign = aimember.getNode("callsign").getValue();
					
					#set properties
					aerotow_hash.open.setBoolValue( 0 );
					aerotow_hash.tow.conn_ai_node.setBoolValue( nodeIsAiAircraft );
					aerotow_hash.tow.conn_mp_node.setBoolValue( nodeIsMpAircraft );
					aerotow_hash.tow.conn_ai_or_mp_callsign.setValue( aicallsign );
					aerotow_hash.tow.conn_ai_or_mp_id.setIntValue( nodeID );
					aerotow_hash.tow.conn_prop_node.setBoolValue( 1 );
					aerotow_hash.tow.node.setValue( towEndNode );
					aerotow_hash.tow.dist.setDoubleValue( bestdist_m );
					aerotow_hash.tow.mp_last_reported_dist.setDoubleValue( 0.0 );
					
					# Set some dummy values. In case of an "interactive"-MP plane
					# the correct values will be transmitted in the following loop
					aimember.getNode("sim/hitches/aerotow/local-pos-x",1).setValue(-5.);
					aimember.getNode("sim/hitches/aerotow/local-pos-y",1).setValue(0.);
					aimember.getNode("sim/hitches/aerotow/local-pos-z",1).setValue(0.);
					aimember.getNode("sim/hitches/aerotow/tow/dist",1).setValue(-1.);
					
					found = 1;
				}   # end distance_m < bestdist_m
		}   # end node != nil
	}   # end loop aiobjects
	
	if (found) {
		if ( !running_as_autoconnect) {
			write_message( "pilot", sprintf("%s, I am on your hook, distance %4.3f meter.",aicallsign,bestdist_m) );
		} else {
			write_message( "remote-ac", sprintf("%s: I am on your hook, distance %4.3f meter.",aicallsign,bestdist_m ) );
		}
		if ( running_as_autoconnect ) {
			isSlave = 1;
			aircraft_settings.aerotow.is_slave.setBoolValue( isSlave );
		}
		
		aerotow_hash.mp_old_open.setBoolValue( 1 );
		
	}   # end: if found
	else {
		if (!running_as_autoconnect) {
			write_message( "system", "Sorry, no aircraft for aerotow!" );
		} else{
			aerotow_hash.old_open.setBoolValue( 1 );
		}
	}
	
} # End function findBestAIObject


# ######################################################################################################################


# Start the towing animation ASAP
towing();



# ######################################################################################################################
#                                                         aerotow function
# ######################################################################################################################

var aerotow = func (open){
	
	#print("function aerotow is running");
	
	#  if (!open ) {
	
	###########################################  my hitch position  ############################################
	
	myPosition = geo.aircraft_position();
	var my_head_deg  = orientation[0].getDoubleValue();
	var my_roll_deg  = orientation[1].getDoubleValue();
	var my_pitch_deg = orientation[2].getDoubleValue();
	
	# hook coordinates in Yasim-system (x-> nose / y -> left wing / z -> up)
	assignHitchLocations("aerotow");
	var x = aircraft_settings.aerotow.local_pos[0].getDoubleValue();
	var y = aircraft_settings.aerotow.local_pos[1].getDoubleValue();
	var z = aircraft_settings.aerotow.local_pos[2].getDoubleValue();
	
	var alpha_deg = my_roll_deg * (1.);   # roll clockwise (looking in x-direction) := +
	var beta_deg  = my_pitch_deg * (-1.); # pitch clockwise (looking in y-direction) := -
	
	# transform hook coordinates
	var Xn = PointRotate3D(x:x,y:y,z:z,xr:0.,yr:0.,zr:0.,alpha_deg:alpha_deg,beta_deg:beta_deg,gamma_deg:0.);
	
	var install_distance_m = Xn[0]; # in front of ref-point of glider
	var install_side_m     = Xn[1];
	var install_alt_m      = Xn[2];
	
	var myHitch_pos    = myPosition.apply_course_distance( my_head_deg , install_distance_m );
	var myHitch_pos    = myPosition.apply_course_distance( my_head_deg - 90. , install_side_m );
	myHitch_pos.set_alt(myPosition.alt() + install_alt_m);
	
	###########################################  ai hitch position  ############################################
	
	#var aiNodeID = getprop("sim/hitches/aerotow/tow/connected-to-ai-or-mp-id");   # id of former found ai/mp aircraft
	#print("aiNodeID=",aiNodeID);
	var aiCallsign = aerotow_hash.tow.conn_ai_or_mp_callsign.getValue();		# callsign of former found ai/mp aircraft
	
	var found = 0;
	
	aiobjects = props.globals.getNode("ai/models").getChildren();
	foreach (var aimember; aiobjects) {
		if ( (var c = aimember.getNode("id") ) != nil ) {
			if ( !aimember.getNode("valid").getValue() ) continue;  # node is invalid
				
				# Identifying the MP-aircraft by its node-id works fine with JSBSim-aircraft but NOT with YASim.
				# In YASim the node-id is not updated which could lead to complications (e.g. node-id changes after "Pause" or "Exit").
				#var testprop = c.getValue();
				#if ( testprop ==  aiNodeID) {
				
				# Identifying the MP-aircraft by its callsign works fine with JSBSim AND YASim-aircraft
				var testprop = aimember.getNode("callsign").getValue();
			if ( testprop == aiCallsign ) {
				
				found = found + 1;
				
				######################  check status of ai hitch  ######################
				if ( fdm == "jsb" ) {
					# check if the multiplayer hitch state has changed
					# this trick avoids immediate opening after locking because MP-aircraft has not yet reported a locked hitch
					if ( (var d = aimember.getNode("sim/hitches/aerotow/open") ) != nil ) {
						var mpOpen = aimember.getNode("sim/hitches/aerotow/open").getValue();
						var mp_oldOpen = aerotow_hash.mp_old_open.getBoolValue();
						#print('mpOpen=',mpOpen,'  mp_oldOpen=',mp_oldOpen);
						if ( mpOpen != mp_oldOpen ) { # state has changed: was open and is now locked OR was locked and is now open
							if ( mpOpen ) {
								write_message( "remote-ac", sprintf("%s: I have released the tow!", aerotow_hash.tow.conn_ai_or_mp_callsign.getValue() ) );
								releaseHitch("aerotow"); # my open=1 / forces=0 / remove towrope
							}  # end: open
							aerotow_hash.mp_old_open.setBoolValue(mpOpen);
						}  # end: state has changed
					}  # end: node is available
				}  #end : JSBSim
				########################################################################
				
				# get coordinates
				var ai_lat = aimember.getNode("position/latitude-deg").getValue();
				var ai_lon = aimember.getNode("position/longitude-deg").getValue();
				var ai_alt = (aimember.getNode("position/altitude-ft").getValue()) * FT2M;
				#print("ai_lat,lon,alt",ai_lat,ai_lon,ai_alt);
				
				var ai_pitch_deg = aimember.getNode("orientation/pitch-deg").getValue();
				var ai_roll_deg = aimember.getNode("orientation/roll-deg").getValue();
				var ai_head_deg = aimember.getNode("orientation/true-heading-deg").getValue();
				
				var aiHitchX = aimember.getNode("sim/hitches/aerotow/local-pos-x").getValue();
				var aiHitchY = aimember.getNode("sim/hitches/aerotow/local-pos-y").getValue();
				var aiHitchZ = aimember.getNode("sim/hitches/aerotow/local-pos-z").getValue();
				
				var aiPosition = geo.Coord.set_latlon( ai_lat, ai_lon, ai_alt );
				
				var alpha_deg = ai_roll_deg * (1.);
				var beta_deg  = ai_pitch_deg * (-1.);
				
				# transform hook coordinates
				var Xn = PointRotate3D(x:aiHitchX,y:aiHitchY,z:aiHitchZ,xr:0.,yr:0.,zr:0.,alpha_deg:alpha_deg,beta_deg:beta_deg,gamma_deg:0.);
				
				var install_distance_m =  Xn[0]; # in front of ref-point of glider
				var install_side_m     =  Xn[1];
				var install_alt_m      =  Xn[2];
				
				var aiHitch_pos    = aiPosition.apply_course_distance( ai_head_deg , install_distance_m );
				var aiHitch_pos    = aiPosition.apply_course_distance( ai_head_deg - 90. , install_side_m );
				aiHitch_pos.set_alt(aiPosition.alt() + install_alt_m);
				
				###########################################  distance between hitches  #####################################
				
				var distance = (myHitch_pos.direct_distance_to(aiHitch_pos));      # distance to plane in meter
				var aiHitchheadto = (myHitch_pos.course_to(aiHitch_pos));
				var height = myHitch_pos.alt() - aiHitch_pos.alt();
				
				var aiHitchpitchto = -math.asin((myHitch_pos.alt()-aiHitch_pos.alt())/distance) / 0.01745;
				#print("  pitch: ", aiHitchpitchto);
				
				# update position of rope
				aerotow_hash.rope.lat.setDoubleValue( myHitch_pos.lat() );
				aerotow_hash.rope.lon.setDoubleValue( myHitch_pos.lon() );
				aerotow_hash.rope.alt.setDoubleValue( myHitch_pos.alt() * M2FT );
				# update orientation of rope
				aerotow_hash.rope.hdg.setDoubleValue( aiHitchheadto );
				aerotow_hash.rope.pitch.setDoubleValue( aiHitchpitchto );
				
				# update length of rope
				aerotow_hash.tow.dist.setDoubleValue( distance );
				
				
				#############################################  calc forces  ##################################################
				
				# calc forces only for JSBSim-aircraft
				
				# tow-end-forces must be reported in N to be consiststent to Yasim-aircraft
				# hitch-forces must be LBS to be consistent to the JSBSim "external_forces/.../magnitude" definition
				
				if ( fdm == "jsb" ) {
					
					# check if the MP-aircraft properties have been updated. If not (maybe due to time-lag) bypass force calculation (use previous forces instead)
					var mp_reported_dist = aimember.getNode("sim/hitches/aerotow/tow/dist").getValue();
					var mp_last_reported_dist = aerotow_hash.tow.mp_last_reported_dist.getDoubleValue();
					var mp_delta_reported_dist = mp_reported_dist - mp_last_reported_dist ;
					aerotow_hash.tow.mp_last_reported_dist.setDoubleValue( mp_reported_dist );
					var mp_delta_reported_dist2 = mp_delta_reported_dist  * mp_delta_reported_dist ;   # we need the absolute value
					if ( (mp_delta_reported_dist2 > 0.0000001) or (mp_reported_dist < 0. )){     # we have the updated MP coordinates (no time lag)
						# or the MP-aircraft is a non-interactive mp plane (mp_reported_dist = -1)
						# => update forces else use the old forces!
						
						var breakforce_N = getprop("sim/hitches/aerotow/tow/break-force");  # could be different in both aircraft
						
						var isSlave = aircraft_settings.aerotow.is_slave.getBoolValue();
						if ( !isSlave ){  # if we are master, we have to calculate the forces
							var elastic_constant = getprop("sim/hitches/aerotow/tow/elastic-constant");
							var towlength_m = getprop("sim/hitches/aerotow/tow/length");
							
							var delta_towlength_m = distance - towlength_m;
							
							if ( delta_towlength_m < 0. ) {
								var forcetow_N = 0.;
							}
							else{
								var forcetow_N = elastic_constant * delta_towlength_m / towlength_m;
							}
						} else {   # we are slave and get the forces from master
							var forcetowX_N = aimember.getNode("sim/hitches/aerotow/tow/end-force-x").getValue() * 1;
							var forcetowY_N = aimember.getNode("sim/hitches/aerotow/tow/end-force-y").getValue() * 1;
							var forcetowZ_N = aimember.getNode("sim/hitches/aerotow/tow/end-force-z").getValue() * 1;
							var forcetow_N = math.sqrt( forcetowX_N * forcetowX_N + forcetowY_N * forcetowY_N + forcetowZ_N * forcetowZ_N );
						}
						
						var forcetow_LBS = forcetow_N * 0.224809;   # N -> LBF
						
						if ( forcetow_N < breakforce_N ) {
							
							var distancepr = (myHitch_pos.distance_to(aiHitch_pos));
							
							# correct a failure, if the projected length is larger than direct length
							if (distancepr > distance) { distancepr = distance;}
							
							var alpha = math.acos( (distancepr / distance) );
							if ( aiHitch_pos.alt() > myHitch_pos.alt()) alpha = - alpha;
							
							var beta = ( aiHitchheadto - my_head_deg ) * 0.01745;
							var gamma = my_pitch_deg * 0.01745;
							var delta = my_roll_deg * 0.01745;
							
							var sina = math.sin(alpha);
							var cosa = math.cos(alpha);
							var sinb = math.sin(beta);
							var cosb = math.cos(beta);
							var sing = math.sin(gamma);
							var cosg = math.cos(gamma);
							var sind = math.sin(delta);
							var cosd = math.cos(delta);
							
							var forcetow = forcetow_LBS;   # we deliver LBS to JSBSim
							
							# calculate unit vector of force direction in JSBSim-system
							var force = 1;
							
							# global forces: alpha beta
							var fglobalx = force * cosa * cosb;
							var fglobaly = force * cosa * sinb;
							var fglobalz = force * sina;
							
							# local forces by pitch: gamma
							var flpitchx = fglobalx * cosg - fglobalz * sing;
							var flpitchy = fglobaly;
							var flpitchz = fglobalx * sing + fglobalz * cosg;
							
							# local forces by roll: delta
							var flrollx  =   flpitchx;
							var flrolly  =   flpitchy * cosd + flpitchz * sind;
							var flrollz  = - flpitchy * sind + flpitchz * cosd;
							
							# asigning to LOCAL coord of plane
							var forcex = flrollx;
							var forcey = flrolly;
							var forcez = flrollz;
							
							# JSBSim-body-frame:  x-> nose / y -> right wing / z -> down
							# apply forces to hook (forces are in LBS or N see above)
							var hitchname = getprop("sim/hitches/aerotow/force_name_jsbsim");
							setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/magnitude", forcetow);
							setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/x", forcex);
							setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/y", forcey);
							setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/z", forcez);
							
						} else {  # rope is broken
							aerotow_hash.broken.setBoolValue( 1 );
							#setprop("sim/messages/atc", sprintf("Oh no, the tow is broken"));
							releaseHitch("aerotow"); # open=1 / forces=0 / remove towrope
						}
						
						#############################################  report forces  ##############################################
						
						# if we are connected to a MP-aircraft and master
						var nodeIsMpAircraft = getprop("sim/hitches/aerotow/tow/connected-to-mp-node");
						if ( nodeIsMpAircraft and !isSlave ){
							
							# transform my hitch coordinates to cartesian earth coordinates
							var myHitchCartEarth = geodtocart(myHitch_pos.lat(),myHitch_pos.lon(),myHitch_pos.alt() );
							var myHitchXearth_m = myHitchCartEarth[0];
							var myHitchYearth_m = myHitchCartEarth[1];
							var myHitchZearth_m = myHitchCartEarth[2];
							
							# transform MP hitch coordinates to cartesian earth coordinates
							var aiHitchCartEarth = geodtocart(aiHitch_pos.lat(),aiHitch_pos.lon(),aiHitch_pos.alt() );
							var aiHitchXearth_m = aiHitchCartEarth[0];
							var aiHitchYearth_m = aiHitchCartEarth[1];
							var aiHitchZearth_m = aiHitchCartEarth[2];
							
							# calculate normal vector in tow direction in cartesian earth coordinates
							var dx = aiHitchXearth_m - myHitchXearth_m;
							var dy = aiHitchYearth_m - myHitchYearth_m;
							var dz = aiHitchZearth_m - myHitchZearth_m;
							var dl = math.sqrt( dx * dx + dy * dy + dz * dz );
							
							var forcetowX_N = forcetow_N * dx / dl;
							var forcetowY_N = forcetow_N * dy / dl;
							var forcetowZ_N = forcetow_N * dz / dl;
							
							setprop("sim/hitches/aerotow/tow/dist", distance);
							setprop("sim/hitches/aerotow/tow/end-force-x", -forcetowX_N); # force acts in
							setprop("sim/hitches/aerotow/tow/end-force-y", -forcetowY_N); # opposite direction
							setprop("sim/hitches/aerotow/tow/end-force-z", -forcetowZ_N); # at tow end
							
						} # end report forces
						
					}  # end: timelag
				}  # end forces/JSBSim
				
				
			}  # end: aiNodeID
		}  # end: check id != nil
	}  # end: loop over aiobjects
	
	if ( found == 0 ) {
		if ( fdm == "jsb" ) {
			write_message( "system", "MP-aircraft disappeared!" );
			aerotow_hash.open.setBoolValue( 1 );  # open my hitch
			aerotow_hash.tow.conn_ai_or_mp_id.setIntValue( 0 );
			aerotow_hash.tow.conn_ai_or_mp_callsign.setValue( "" );
			aerotow_hash.tow.conn_ai_node.setBoolValue( 0 );
			aerotow_hash.tow.conn_mp_node.setBoolValue( 0 );
			aerotow_hash.tow.conn_prop_node.setBoolValue( 0 );
		}
		#if ( fdm == "yasim" ) removeTowrope("aerotow");   # remove towrope model
	} # end found=0
	
}   # end function aerotow



# ######################################################################################################################
#                                                         winch function
# ######################################################################################################################

var winch = func (open){
	
	if (!open ) {
		
		
		###########################################  my hitch position  ############################################
		
		myPosition = geo.aircraft_position();
		var my_head_deg  = orientation[0].getDoubleValue();
		var my_roll_deg  = orientation[1].getDoubleValue();
		var my_pitch_deg = orientation[2].getDoubleValue();
		
		# hook coordinates in Yasim-system (x-> nose / y -> left wing / z -> up)
		assignHitchLocations("winch");
		var x = aircraft_settings.winch.local_pos[0].getDoubleValue();
		var y = aircraft_settings.winch.local_pos[1].getDoubleValue();
		var z = aircraft_settings.winch.local_pos[2].getDoubleValue();
		
		var alpha_deg = my_roll_deg * (1.);   # roll clockwise (looking in x-direction) := +
		var beta_deg  = my_pitch_deg * (-1.); # pitch clockwise (looking in y-direction) := -
		
		# transform hook coordinates
		var Xn = PointRotate3D(x:x,y:y,z:z,xr:0.,yr:0.,zr:0.,alpha_deg:alpha_deg,beta_deg:beta_deg,gamma_deg:0.);
		
		var install_distance_m = Xn[0]; # in front of ref-point of glider
		var install_side_m     = Xn[1];
		var install_alt_m      = Xn[2];
		
		var myHitch_pos    = myPosition.apply_course_distance( my_head_deg , install_distance_m );
		var myHitch_pos    = myPosition.apply_course_distance( my_head_deg - 90. , install_side_m );
		myHitch_pos.set_alt(myPosition.alt() + install_alt_m);
		
		
		############################ Check for rope breakage ###############################
		var my_height = myHitch_pos.alt() - geo.elevation( myHitch_pos.lat(), myHitch_pos.lon() );
		
		if( winch_hash.rope_breakage and my_height > winch_hash.rope_breakage_height_int ) {
			releaseHitch("winch");
			winch_hash.rope_breakage = 0;
			# The pilot shouldn't immediately be notified this was a rope breakage (to train recognizing a rope breakage)
			# That's why we report the breakage and its height 5 seconds later
			var temp = winch_hash.rope_breakage_height_int;
			settimer( func() {
					write_message( "winch-driver", "Rope broke at " ~ sprintf("%4d", math.round( temp ) ) ~ "m height" );
				}, 5);
			return;
		}
		
		############################ Check for winch loss of power ##########################
		if( winch_hash.loss_of_power.enabled and my_height > winch_hash.loss_of_power.height_int ) {
			loss_of_power();
			winch_hash.loss_of_power.enabled = 0;
			# The pilot shouldn't immediately be notified this was a loss of power (to train recognizing a winch loss of power)
			# That's why we report the loss of power and its height 15 seconds later
			var temp = winch_hash.loss_of_power.height_int;
			settimer( func() {
					write_message( "winch-driver", "Winch lost power at " ~ sprintf("%4d", math.round( temp ) ) ~ "m height" );
				}, 15);
			return;
		}
		
		###########################################  winch hitch position  ############################################
		
		# get coordinates
		var winch_global_pos_x = winch_hash.global_pos[0].getDoubleValue();
		var winch_global_pos_y = winch_hash.global_pos[1].getDoubleValue();
		var winch_global_pos_z = winch_hash.global_pos[2].getDoubleValue();
		
		var winch_geod = carttogeod(winch_global_pos_x, winch_global_pos_y, winch_global_pos_z);
		
		var ai_lat = winch_geod[0];
		var ai_lon = winch_geod[1];
		#var ai_alt = winch_geod[2] * FT2M;
		var ai_alt = winch_geod[2];
		#print("ai_lat,lon,alt",ai_lat,ai_lon,ai_alt);
		
		var aiHitch_pos = geo.Coord.set_latlon( ai_lat, ai_lon, ai_alt );
		
		
		###########################################  distance between hitches  #####################################
		
		var distance = (myHitch_pos.direct_distance_to(aiHitch_pos));    # distance to winch in meter
		var aiHitchheadto = (myHitch_pos.course_to(aiHitch_pos));
		var height = myHitch_pos.alt() - aiHitch_pos.alt();
		
		var aiHitchpitchto = -math.asin((myHitch_pos.alt()-aiHitch_pos.alt())/distance) * R2D;
		#print("  pitch: ", aiHitchpitchto);
		
		#print("Update Winch Rope");
		#print("Winch Rope Lat is "~ myHitch_pos.lat() );
		# update position of rope
		winch_hash.rope.lat.setDoubleValue( myHitch_pos.lat() );
		winch_hash.rope.lon.setDoubleValue( myHitch_pos.lon() );
		winch_hash.rope.alt.setDoubleValue( myHitch_pos.alt() * M2FT );
		# update orientation of rope
		winch_hash.rope.hdg.setDoubleValue( aiHitchheadto );
		winch_hash.rope.pitch.setDoubleValue( aiHitchpitchto );
		
		# update length of rope
		winch_hash.tow.dist.setDoubleValue( distance );
		#print("distance=",distance);
		
		
		#############################################  calc forces  ##################################################
		
		# calc forces only for JSBSim-aircraft
		
		# tow-end-forces must be reported in N to be consiststent to Yasim-aircraft
		# hitch-forces must be LBS to be consistent to the JSBSim "external_forces/.../magnitude" definition
		
		if ( fdm == "jsb"  ) {
			
			var spool_max = config.winch.max_spool_speed.getDoubleValue();
			var unspool_max = config.winch.max_unspool_speed.getDoubleValue();
			var max_force_N = config.winch.max_force.getDoubleValue();
			var max_power_W = config.winch.max_power.getDoubleValue() * 1000.;
			var breakforce_N = aircraft_settings.winch.break_force.getDoubleValue();
			var elastic_constant = config.winch.elastic_constant.getDoubleValue();
			var towlength_m = winch_hash.tow.length.getDoubleValue();
			var max_tow_length_m = config.winch.max_tow_length_m.getDoubleValue();
			var spoolspeed = winch_hash.actual_spool_speed.getDoubleValue();
			var spool_acceleration = config.winch.spool_acceleration.getDoubleValue();
			var delta_t = delta_time.getDoubleValue();
			
			#print("towlength_m= ", towlength_m , "  elastic_constant= ", elastic_constant,"  delta_towlength_m= ", delta_towlength_m);
			
			var forcetow_N = winch_hash.actual_force.getDoubleValue();
			var towlength_new_m = nil;
			var delta_towlength_m = nil;
			
			if ( winch_hash.clutched.getBoolValue() ) {
				
				if( winch_hash.type == 0 ){
					# Concept: force is given
					forcetow_N = force_setting;
					
				} else if ( winch_hash.type == 1 ){
					# Concept: regulate force to reach target speed
					var speed_trgt = speed_setting;
					if( math.abs ( spoolspeed - speed_trgt ) > 0.5 ) {
						if( speed_trgt > spoolspeed ) {
							forcetow_N += acceleration_N_s * delta_t;
						} else if ( speed_trgt < spoolspeed ){
							forcetow_N -= acceleration_N_s * delta_t;
						}
					}
				}
				
				# New towlength is distance from hook to winch; previous towlength is stored in winch_hash.towlength_m
				towlength_new_m = distance;
				delta_towlength_m = -1 * ( distance - towlength_m );
				spoolspeed = delta_towlength_m / delta_t;	
				
			} else {   # un-clutched
				# --- experimental --- #
				towlength_new_m = towlength_m - spoolspeed * delta_t;
				delta_towlength_m = distance - towlength_new_m;
				
				# we assume that the the winch-operator avoids tow sagging ( => rigid rope; negativ forces allowed)
				forcetow_N = elastic_constant * delta_towlength_m / towlength_new_m;
				
				# drag of tow-rope ( magic! )
				var magic_constant = config.winch.magic_constant.getDoubleValue();
				tow_drag_N = spoolspeed * spoolspeed * math.sqrt( math.sqrt( height * height ) * max_tow_length_m ) / magic_constant ;
				
				# mass = tow-mass only (drum-mass ignored)
				var mass_kg = max_tow_length_m * config.winch.weight_per_m_kg_m.getDoubleValue();
				
				var acceleration = ( forcetow_N - tow_drag_N ) / mass_kg;
				var delta_spoolspeed = acceleration * delta_t;
				spoolspeed = spoolspeed - delta_spoolspeed;
				if ( spoolspeed < - unspool_max ) spoolspeed = - unspool_max;
				
				
				#if ( delta_towlength_m < 0. ) {
				#	forcetow_N = 0.;
				#}
			}

			if ( forcetow_N > max_force_N ) {
				forcetow_N = max_force_N;
				var towlength_new_m = distance / ( forcetow_N / elastic_constant + 1. );
				spoolspeed = (towlength_m - towlength_new_m ) / delta_t;
			}
			
			var power = forcetow_N * spoolspeed;
			if ( power > max_power_W) {
				power = max_power_W;
				forcetow_N = power / spoolspeed;
				towlength_new_m = towlength_m - spoolspeed * delta_t;
			}
			
			winch_hash.tow.length.setDoubleValue( towlength_new_m );
			winch_hash.actual_spool_speed.setDoubleValue( spoolspeed );
			winch_hash.actual_force.setDoubleValue( forcetow_N );
			
			# force due to tow-weight (acts in tow direction at the heigher hitch)
			var force_due_to_weight_N = config.winch.weight_per_m_kg_m.getDoubleValue() * 9.81 * height;
			if (height < 0. ) force_due_to_weight_N = 0.;
			
			forcetow_N = forcetow_N + force_due_to_weight_N;
			var forcetow_LBS = forcetow_N * 0.224809;   # N -> LBF
			
			if ( forcetow_N < breakforce_N ) {
				
				var distancepr = (myHitch_pos.distance_to(aiHitch_pos));
				
				# correct a failure, if the projected length is larger than direct length
				if (distancepr > distance) { distancepr = distance;}
				
				var alpha = math.acos( (distancepr / distance) );
				if ( aiHitch_pos.alt() > myHitch_pos.alt()) alpha = - alpha;
				var beta = ( aiHitchheadto - my_head_deg ) * D2R;
				var gamma = my_pitch_deg * D2R;
				var delta = my_roll_deg * D2R;
				
				var sina = math.sin(alpha);
				var cosa = math.cos(alpha);
				var sinb = math.sin(beta);
				var cosb = math.cos(beta);
				var sing = math.sin(gamma);
				var cosg = math.cos(gamma);
				var sind = math.sin(delta);
				var cosd = math.cos(delta);
				
				# calculate unit vector of force direction in JSBSim-system
				var force = 1;
				
				# global forces: alpha beta
				var fglobalx = force * cosa * cosb;
				var fglobaly = force * cosa * sinb;
				var fglobalz = force * sina;
				
				# local forces by pitch: gamma
				var flpitchx = fglobalx * cosg - fglobalz * sing;
				var flpitchy = fglobaly;
				var flpitchz = fglobalx * sing + fglobalz * cosg;
				
				# local forces by roll: delta
				var flrollx  =   flpitchx;
				var flrolly  =   flpitchy * cosd + flpitchz * sind;
				var flrollz  = - flpitchy * sind + flpitchz * cosd;
				
				# asigning to LOCAL coord of plane
				var forcex = flrollx;
				var forcey = flrolly;
				var forcez = flrollz;
				
				# JSBSim-body-frame:  x-> nose / y -> right wing / z -> down
				# apply forces to hook (forces are in LBS or N see above)
				winch_hash.apply_force.magnitude.setDoubleValue( forcetow_LBS );
				winch_hash.apply_force.coord[0].setDoubleValue( forcex );
				winch_hash.apply_force.coord[1].setDoubleValue( forcey );
				winch_hash.apply_force.coord[2].setDoubleValue( forcez );
				
				# check, if auto-release condition is reached
				var rope_angle_deg = math.atan2(forcez , forcex ) * R2D;
				#print("rope_angle_deg=",rope_angle_deg);
				if (rope_angle_deg > aircraft_settings.winch.automatic_release_angle.getDoubleValue() ) releaseWinch();
				
			}  # end force < break force
			else {  # rope is broken
				winch_hash.broken.setBoolValue( 1 );
				releaseWinch();
			}
			
			if ( towlength_new_m > max_tow_length_m ) {
				write_message( "system", "tow length exceeded!" );
				releaseWinch();
			}
			
		}  # end forces/JSBSim
		
	}  # end hitch is closed (open == 0)
	
}  # end function winch


# ######################################################################################################################
#                                                      create towrope
# ######################################################################################################################

var createTowrope = func (device){
	
	# create the towrope in the model property tree
	#print("createTowrope for ",device);
	
	if ( getprop("sim/hitches/" ~ device ~ "/rope/exist") == 0 ) {   # does the towrope exist?
		
		# get the next free model id
		var freeModelid = getFreeModelID();
		
		props.globals.getNode("sim/hitches/" ~ device ~ "/rope/model_id").setIntValue(freeModelid);
		props.globals.getNode("sim/hitches/" ~ device ~ "/rope/exist").setBoolValue(1);
		
		var towrope_ai  = props.globals.getNode("ai/models/" ~ device ~ "rope", 1);
		var towrope_mod  = props.globals.getNode("models", 1);
		
		towrope_ai.getNode("id", 1).setIntValue(4711);
		towrope_ai.getNode("callsign", 1).setValue("towrope");
		towrope_ai.getNode("valid", 1).setBoolValue(1);
		towrope_ai.getNode("position/latitude-deg", 1).setValue(0.);
		towrope_ai.getNode("position/longitude-deg", 1).setValue(0.);
		towrope_ai.getNode("position/altitude-ft", 1).setValue(0.);
		towrope_ai.getNode("orientation/true-heading-deg", 1).setValue(0.);
		towrope_ai.getNode("orientation/pitch-deg", 1).setValue(0.);
		towrope_ai.getNode("orientation/roll-deg", 1).setValue(0.);
		
		towrope_mod.model = towrope_mod.getChild("model", freeModelid, 1);
		towrope_mod.model.getNode("path", 1).setValue(getprop("sim/hitches/" ~ device ~ "/rope/path_to_model") );
		towrope_mod.model.getNode("longitude-deg-prop", 1).setValue("ai/models/" ~ device ~ "rope/position/longitude-deg");
		towrope_mod.model.getNode("latitude-deg-prop", 1).setValue("ai/models/" ~ device ~ "rope/position/latitude-deg");
		towrope_mod.model.getNode("elevation-ft-prop", 1).setValue("ai/models/" ~ device ~ "rope/position/altitude-ft");
		towrope_mod.model.getNode("heading-deg-prop", 1).setValue("ai/models/" ~ device ~ "rope/orientation/true-heading-deg");
		towrope_mod.model.getNode("roll-deg-prop", 1).setValue("ai/models/" ~ device ~ "rope/orientation/roll-deg");
		towrope_mod.model.getNode("pitch-deg-prop", 1).setValue("ai/models/" ~ device ~ "rope/orientation/pitch-deg");
		towrope_mod.model.getNode("load", 1).remove();
		
		if( device == "winch" ){
			winch_hash.rope.lat=	check_or_create("ai/models/winchrope/position/latitude-deg", 0.0, "DOUBLE");
			winch_hash.rope.lon=	check_or_create("ai/models/winchrope/position/longitude-deg", 0.0, "DOUBLE");
			winch_hash.rope.alt=	check_or_create("ai/models/winchrope/position/altitude-ft", 0.0, "DOUBLE");
			winch_hash.rope.hdg=	check_or_create("ai/models/winchrope/orientation/true-heading-deg", 0.0, "DOUBLE");
			winch_hash.rope.pitch=	check_or_create("ai/models/winchrope/orientation/pitch-deg", 0.0, "DOUBLE");
		}
	}  # end towrope exist
}


# ######################################################################################################################
#                                     get the next free id of "models/model" members
# ######################################################################################################################

var getFreeModelID = func {
	#print("getFreeModelID");
	var modelid = 0;   # next unused id
	modelobjects = props.globals.getNode("models", 1).getChildren();
	foreach ( var member; modelobjects ) {
		if ( (var c = member.getIndex()) != nil) {
			modelid = c + 1;
		}
	}
	#print("modelid=",modelid);
	return(modelid);
}


# ######################################################################################################################
#                                                   close aerotow hitch
# ######################################################################################################################

var closeHitch = func {
	
	#print("closeHitch");
	
	# close only, if
	# - not yet closed
	# - connected to property-node
	# - distance < towrope length
	
	if ( !aerotow_hash.open.getBoolValue() ) return;
	
	var aiNodeID = getprop("sim/hitches/aerotow/tow/connected-to-ai-or-mp-id");   # id of former found ai/mp aircraft
	if ( aiNodeID < 1 ) {
		setprop("sim/messages/atc", sprintf("No aircraft selected!"));
		return;
	}
	
	#####################################  calc distance between hitches  ######################
	
	######################  my hitch position  #######################
	
	myPosition = geo.aircraft_position();
	var my_head_deg  = getprop("orientation/heading-deg");
	var my_roll_deg  = getprop("orientation/roll-deg");
	var my_pitch_deg = getprop("orientation/pitch-deg");
	
	# hook coordinates in Yasim-system (x-> nose / y -> left wing / z -> up)
	assignHitchLocations("aerotow");
	var x = aircraft_settings.aerotow.local_pos[0].getDoubleValue();
	var y = aircraft_settings.aerotow.local_pos[1].getDoubleValue();
	var z = aircraft_settings.aerotow.local_pos[2].getDoubleValue();
	#var x = getprop("sim/hitches/aerotow/local-pos-x");
	#var y = getprop("sim/hitches/aerotow/local-pos-y");
	#var z = getprop("sim/hitches/aerotow/local-pos-z");
	
	var alpha_deg = my_roll_deg * (1.);   # roll clockwise (looking in x-direction) := +
	var beta_deg  = my_pitch_deg * (-1.); # pitch clockwise (looking in y-direction) := -
	
	# transform hook coordinates
	var Xn = PointRotate3D(x:x,y:y,z:z,xr:0.,yr:0.,zr:0.,alpha_deg:alpha_deg,beta_deg:beta_deg,gamma_deg:0.);
	
	var install_distance_m = Xn[0]; # in front of ref-point of glider
	var install_side_m     = Xn[1];
	var install_alt_m      = Xn[2];
	
	var myHitch_pos    = myPosition.apply_course_distance( my_head_deg , install_distance_m );
	var myHitch_pos    = myPosition.apply_course_distance( my_head_deg - 90. , install_side_m );
	myHitch_pos.set_alt(myPosition.alt() + install_alt_m);
	
	######################  ai hitch position  #######################
	
	var found = 0;
	
	aiobjects = props.globals.getNode("ai/models").getChildren();
	foreach (var aimember; aiobjects) {
		if ( (var c = aimember.getNode("id") ) != nil ) {
			var testprop = c.getValue();
			if ( testprop ==  aiNodeID) {
				found = found + 1;
				
				# get coordinates
				var ai_lat = aimember.getNode("position/latitude-deg").getValue();
				var ai_lon = aimember.getNode("position/longitude-deg").getValue();
				var ai_alt = (aimember.getNode("position/altitude-ft").getValue()) * FT2M;
				
				var ai_pitch_deg = aimember.getNode("orientation/pitch-deg").getValue();
				var ai_roll_deg = aimember.getNode("orientation/roll-deg").getValue();
				var ai_head_deg = aimember.getNode("orientation/true-heading-deg").getValue();
				
				var aiHitchX = aimember.getNode("sim/hitches/aerotow/local-pos-x").getValue();
				var aiHitchY = aimember.getNode("sim/hitches/aerotow/local-pos-y").getValue();
				var aiHitchZ = aimember.getNode("sim/hitches/aerotow/local-pos-z").getValue();
				
				var aiPosition = geo.Coord.set_latlon( ai_lat, ai_lon, ai_alt );
				
				var alpha_deg = ai_roll_deg * (1.);
				var beta_deg  = ai_pitch_deg * (-1.);
				
				# transform hook coordinates
				var Xn = PointRotate3D(x:aiHitchX,y:aiHitchY,z:aiHitchZ,xr:0.,yr:0.,zr:0.,alpha_deg:alpha_deg,beta_deg:beta_deg,gamma_deg:0.);
				
				var install_distance_m =  Xn[0]; # in front of ref-point of glider
				var install_side_m     =  Xn[1];
				var install_alt_m      =  Xn[2];
				
				var aiHitch_pos    = aiPosition.apply_course_distance( ai_head_deg , install_distance_m );
				var aiHitch_pos    = aiPosition.apply_course_distance( ai_head_deg - 90. , install_side_m );
				aiHitch_pos.set_alt(aiPosition.alt() + install_alt_m);
				
				var distance = (myHitch_pos.direct_distance_to(aiHitch_pos));
				
				var towlength_m = props.globals.getNode("sim/hitches/aerotow/tow/length").getValue();
				if ( distance > towlength_m ) {
					var aicallsign = getprop("sim/hitches/aerotow/tow/connected-to-ai-or-mp-callsign");
					#setprop("sim/messages/atc", sprintf("Aircraft with callsign %s is too far away (distance is %4.0f meter).",aicallsign, distance));
					setprop("sim/messages/atc", sprintf("Selected aircraft is too far away (distance to %s is %4.0f meter).",aicallsign, distance));
					return;
				}
				
				setprop("sim/hitches/aerotow/tow/dist", distance);
				
			}
		}
	}
	
	aerotow_hash.open.setBoolValue( 0 );
	setprop("sim/hitches/aerotow/mp_oldOpen", "true");
	
} # End function closeHitch


# ######################################################################################################################
#                                                     release hitch
# ######################################################################################################################

var releaseHitch = func (device){
	
	#print("releaseHitch");
	
	if ( fdm == "yasim" ) return;	# bypass this routine for Yasim-aircraft
		
		setprop("sim/hitches/" ~ device ~ "/open", "true");
	
	var hitchname = getprop("sim/hitches/" ~ device ~ "/force_name_jsbsim");
	setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/magnitude", 0.);
	setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/x", 0.);
	setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/y", 0.);
	setprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/z", 0.);
	
	if ( device == "aerotow" ) {
		setprop("sim/hitches/aerotow/tow/end-force-x", 0.);		 # MP tow-end forces
		setprop("sim/hitches/aerotow/tow/end-force-y", 0.);		 #
		setprop("sim/hitches/aerotow/tow/end-force-z", 0.);		 #
	} else {
		# Put automatic winch driver in after-tow phase
		phase = 5;
	}
	
} # End function releaseHitch


# ######################################################################################################################
#                                                  remove/delete towrope
# ######################################################################################################################

var removeTowrope = func (device){
	
	# remove the towrope from the property tree ai/models
	# remove the towrope from the property tree models/
	
	if ( getprop("sim/hitches/" ~ device ~ "/rope/exist") == 1 ) {   # does the towrope exist?
		
		# remove 3d model from scenery
		# identification is /models/model[x] with x=id_model
		var id_model = getprop("sim/hitches/" ~ device ~ "/rope/model_id");
		var modelsNode = "models/model[" ~ id_model ~ "]";
		props.globals.getNode(modelsNode).remove();
		props.globals.getNode("ai/models/" ~ device ~ "rope").remove();
		#print("towrope removed");
		setprop("sim/hitches/" ~ device ~ "/rope/exist", 0);
	}
	
}


# ######################################################################################################################
#                                           pull in towrope after hitch has been opened
# ######################################################################################################################

var sink_rate_mps = 0.0;

var pull_in_rope = func {
	
	
	if ( winch_hash.open.getBoolValue() ) {
		
		var current_tow_length = winch_hash.tow.length.getDoubleValue();
		
		if ( current_tow_length > 15.0 ) {
			
			var dt = delta_time.getDoubleValue();
			
			# get position of rope end (former myHitch_pos)
			var tow_lat = winch_hash.rope.lat.getDoubleValue();
			var tow_lon = winch_hash.rope.lon.getDoubleValue();
			var tow_alt_m = winch_hash.rope.alt.getDoubleValue() * FT2M;
			# get pitch and heading of rope
			var tow_heading_deg = winch_hash.rope.hdg.getDoubleValue();
			var tow_pitch_rad = winch_hash.rope.pitch.getDoubleValue() * D2R;
			
			var aiTow_pos = geo.Coord.set_latlon( tow_lat, tow_lon, tow_alt_m );
			
			var delta_length_m = config.winch.max_spool_speed.getDoubleValue() * dt;
			var delta_distance_m = delta_length_m * math.cos(tow_pitch_rad);
			
			aiTow_pos    = aiTow_pos.apply_course_distance( tow_heading_deg , delta_distance_m );
			
			# Wind influence
			aiTow_pos = aiTow_pos.apply_course_distance( wind_from.getDoubleValue() - 180, wind_speed_kt.getDoubleValue() * KT2MPS * dt );
			
			var elevation = geo.elevation( aiTow_pos.lat(), aiTow_pos.lon() );
			if( elevation == nil ) elevation = tow_alt_m;
			if( tow_alt_m > elevation ){
				var delta_alt_m      = delta_length_m * math.sin(tow_pitch_rad);
				# Calculate vertical sink rate
				# assume: drag is exclusively due to the chute, chute size is about 3.14m2 (circle radius 1m), rho is static at 1.29kg/m3
				var mass_kg = current_tow_length * config.winch.weight_per_m_kg_m.getDoubleValue();
				sink_rate_mps = sink_rate_mps + dt * ( 9.81 - 1.29 * math.pow( sink_rate_mps, 2 ) * 3.14 / mass_kg  );
				
				delta_alt_m = delta_alt_m - sink_rate_mps * dt;
				
				aiTow_pos.set_alt( tow_alt_m + delta_alt_m );
			} else {
				aiTow_pos.set_alt( elevation );
			}
			#print("aiTow_pos.alt()= ",aiTow_pos.alt(),"  ",tow_alt_m + delta_alt_m);
			
			# Winch position
			var winch_global_pos_x = winch_hash.global_pos[0].getDoubleValue();
			var winch_global_pos_y = winch_hash.global_pos[1].getDoubleValue();
			var winch_global_pos_z = winch_hash.global_pos[2].getDoubleValue();
			
			var winch_geod = carttogeod(winch_global_pos_x, winch_global_pos_y, winch_global_pos_z);
			var aiWinch_pos = geo.Coord.new();
			aiWinch_pos.set_latlon( winch_geod[0], winch_geod[1], winch_geod[2] );
			
			var new_tow_length_m = aiTow_pos.direct_distance_to(aiWinch_pos);
			var aiHitchpitchto = -math.asin( (aiTow_pos.alt()-aiWinch_pos.alt()) / new_tow_length_m ) * R2D;
		
			# update position of rope
			#print("pull in active");
			winch_hash.rope.lat.setDoubleValue( aiTow_pos.lat() );
			winch_hash.rope.lon.setDoubleValue( aiTow_pos.lon() );
			winch_hash.rope.alt.setDoubleValue( aiTow_pos.alt() * M2FT );
			# update orientation of rope
			winch_hash.rope.hdg.setDoubleValue( aiTow_pos.course_to( aiWinch_pos ) );
			winch_hash.rope.pitch.setDoubleValue( aiHitchpitchto );
		
			# update length of rope
			winch_hash.tow.length.setDoubleValue( new_tow_length_m );
			winch_hash.tow.dist.setDoubleValue( new_tow_length_m );
			
			settimer( pull_in_rope , 0 );
		}  # end towlength > min
		else {
			#print("pull in finished!");
			winch_hash.actual_spool_speed.setDoubleValue( 0 );
			removeTowrope("winch");   # remove towrope model
		}
		
	}  # end if open
	
}


# ######################################################################################################################
#                                              set some AI-object default values
# ######################################################################################################################

var setAIObjectDefaults = func (){
	
	# set some default variables, needed to identify, if the found object is an AI-object, a "non-interactiv MP-object or
	# an interactive MP-object
	
	var aiNodeID = aerotow_hash.tow.conn_ai_or_mp_id.getIntValue();   # id of former found ai/mp aircraft
	
	aiobjects = props.globals.getNode("ai/models").getChildren();
	foreach (var aimember; aiobjects) {
		if ( (var c = aimember.getNode("id") ) != nil ) {
			var testprop = c.getValue();
			if ( testprop ==  aiNodeID) {
				# Set some dummy values. In case of an "interactive"-MP plane
				# the correct values will be transmitted in the following loop.
				# Create this variables if not present.
				aimember.getNode("sim/hitches/aerotow/local-pos-x",1).setValue(-5.);
				aimember.getNode("sim/hitches/aerotow/local-pos-y",1).setValue(0.);
				aimember.getNode("sim/hitches/aerotow/local-pos-z",1).setValue(0.);
				aimember.getNode("sim/hitches/aerotow/tow/dist",1).setValue(-1.);
			}
		}
	}
	
}


# ######################################################################################################################
#                                                  place winch model
# ######################################################################################################################

var setWinchPositionAuto = func {
	
	# remove already existing winch model
	if ( getprop("/sim/hitches/winch/winch/winch-model-index") != nil ) {
		var id_model = getprop("/sim/hitches/winch/winch/winch-model-index");
		var modelsNode = "models/model[" ~ id_model ~ "]";
		props.globals.getNode(modelsNode).remove();
		#print("winch model removed");
	}
	
	var initial_length_m = config.winch.initial_tow_length.getDoubleValue();
	var ac_pos = geo.aircraft_position();			# get position of aircraft
	var ac_hd  = orientation[0].getDoubleValue();		# get heading of aircraft
	
	# setup winch
	# get initial runway position
	var ipos_lat_deg = getprop("sim/presets/latitude-deg");
	var ipos_lon_deg = getprop("sim/presets/longitude-deg");
	var ipos_hd_deg  = getprop("sim/presets/heading-deg");
	var ipos_alt_m = geo.elevation(ipos_lat_deg,ipos_lon_deg);
	var ipos_geo = geo.Coord.new().set_latlon(ipos_lat_deg, ipos_lon_deg, ipos_alt_m);
	# offset to initial position
	var deviation = (ac_pos.distance_to(ipos_geo));
	# if deviation is too much, locate winch in front of glider, otherwise locate winch to end of runway
	if ( deviation > 200) {
		var w = ac_pos.apply_course_distance( ac_hd , initial_length_m -1. );
	}
	else {
		var w = ipos_geo.apply_course_distance( ipos_hd_deg , initial_length_m - 1. );
	}
	var wpalt = geo.elevation(w.lat(), w.lon());
	w.set_alt(wpalt);
	
	var winchModel = geo.put_model("Models/Airport/supacat_winch.xml", w.lat(), w.lon(), (w.alt()+0.81), (w.course_to(ac_pos) ));
	
	winch_hash.global_pos[0].setDoubleValue( w.x() );
	winch_hash.global_pos[1].setDoubleValue( w.y() );
	winch_hash.global_pos[2].setDoubleValue( w.z() );
	
	winch_hash.tow.dist.setDoubleValue( initial_length_m - 1.0 );
	winch_hash.tow.length.setDoubleValue( initial_length_m );
	
	#print("name=",winchModel.getName(),"  Index=",winchModel.getIndex(),"  Type=",winchModel.getType() );
	#print("val=",winchModel.getValue(),"  children=",winchModel.getChildren(),"  size=",size(winchModel) );
	setprop("/sim/hitches/winch/winch/winch-model-index",winchModel.getIndex() );
	
	
	winch_hash.rope_breakage = winch_hash.rope_breakage_p.getBoolValue();
	if( winch_hash.rope_breakage ){
		if( config.winch.rope_breakage.random.getBoolValue() ){
			winch_hash.rope_breakage_height_int = 1 + rand() * 300;
		} else {
			winch_hash.rope_breakage_height_int = config.winch.rope_breakage.height.getDoubleValue();
		}
	}
	
	winch_hash.loss_of_power.enabled = winch_hash.loss_of_power.enabled_p.getBoolValue();
	if( winch_hash.loss_of_power.enabled ){
		if( config.winch.loss_of_power.random.getBoolValue() ){
			winch_hash.loss_of_power.height_int = 1 + rand() * 300;
		} else {
			winch_hash.loss_of_power.height_int = config.winch.loss_of_power.height.getDoubleValue();
		}
	}
	
	write_message( "pilot", "Connected to winch!" );
	
	winch_hash.open.setBoolValue( 0 );
	
} # End function setWinchPositionAuto


# ######################################################################################################################
#                                                  clutch / un-clutch winch
# ######################################################################################################################

var runWinch = func {
	
	if ( !winch_hash.clutched.getBoolValue() ) {
		winch_hash.clutched.setBoolValue( 1 );
		write_message( "pilot", "Winch clutched!" );
		if( alt_agl_ft.getDoubleValue() < 10.0 ){
			auto_winch_driver_init();
			auto_winch_driver_update.restart( 0.0 );
		}
	} else {
		winch_hash.clutched.setBoolValue( 0 );
		write_message( "pilot", "Winch un-clutched!" );
	}
	
} # End function runWinch


# ######################################################################################################################
#                                                     release winch
# ######################################################################################################################

var releaseWinch = func {
	
	winch_hash.open.setBoolValue( 1 );
	
} # End function releaseWinch


# ######################################################################################################################
#                                                  assignHitchLocations
# ######################################################################################################################

var assignHitchLocations = func (device){
	
	if ( fdm == "yasim" ) return;	# bypass this routine for Yasim-aircraft
		
	if ( getprop("sim/hitches/" ~ device ~ "/decoupled-force-and-rope-locations") ) return; # bypass this routine
			
	#print("assignHitchLocations");
		
	var hitchname = getprop("sim/hitches/" ~ device ~ "/force_name_jsbsim");
	
	# location-x(yz)-in: JSBSim Structural Frame: x points to tail, y points to right wing, z points upward
	# local-pos-x(yz):   YaSim frame:             x points to nose, y points to left wing,  z points upward
	
	setprop("sim/hitches/" ~ device ~ "/local-pos-x", - getprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/location-x-in") * IN2M );
	setprop("sim/hitches/" ~ device ~ "/local-pos-y", - getprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/location-y-in") * IN2M );
	setprop("sim/hitches/" ~ device ~ "/local-pos-z",   getprop("fdm/jsbsim/external_reactions/" ~ hitchname ~ "/location-z-in") * IN2M );
	
} # End function assignHitchLocations


# ######################################################################################################################
#                                                      point transformation
# ######################################################################################################################

var PointRotate3D = func (x,y,z,xr,yr,zr,alpha_deg,beta_deg,gamma_deg){
	
	# ---------------------------------------------------------------------------------
	#   rotates point (x,y,z) about all 3 cartesian axis
	#   center of rotation (xr,yr,zr)
	#   angle of rotation about x-axis = alpha
	#   angle of rotation about y-axis = beta
	#   angle of rotation about z-axis = gamma
	#   delivers new point coordinates (x_new,y_new,z_new)
	# ---------------------------------------------------------------------------------
	#
	#
	# Definitions:
	# ----------------
	#
	# x        y           z
	# alpha    beta        gamma
	#
	#
	#       z
	#       |  y
	#       | /
	#       |/
	#       ----->x
	#
	#----------------------------------------------------------------------------------
	
	# Transformation in rotation-system X_rel = X-Xr = (x-xr, y-yr, z-zr)
	var x_rel = x-xr;
	var y_rel = y-yr;
	var z_rel = z-zr;
	
	# Trigonometry
	
	var alpha_rad	   = D2R * alpha_deg;
	var beta_rad	   = D2R * beta_deg;
	var gamma_rad	   = D2R * gamma_deg;
	
	var sin_alpha = math.sin(alpha_rad);
	var cos_alpha = math.cos(alpha_rad);
	
	var sin_beta  = math.sin(beta_rad);
	var cos_beta  = math.cos(beta_rad);
	
	var sin_gamma = math.sin(gamma_rad);
	var cos_gamma = math.cos(gamma_rad);
	
	# Matrices
	#
	# Rotate about x-axis Rx(alpha)
	#
	#		Rx11 Rx12 Rx13      1	  0	       0
	# Rx(alpha)=  Rx21 Rx22 Rx23   =  0  cos(alpha)  -sin(alpha)
	#		Rx31 Rx32 Rx33      0  sin(alpha)   cos(alpha)
	#
	var Rx11 = 1.;
	var Rx12 = 0.;
	var Rx13 = 0.;
	var Rx21 = 0.;
	var Rx22 = cos_alpha;
	var Rx23 = - sin_alpha;
	var Rx31 = 0.;
	var Rx32 = sin_alpha;
	var Rx33 = cos_alpha;
	#
	# Rotate about y-axis Ry(beta)
	#
	#	       Ry11 Ry12 Ry13	   cos(beta)  0   sin(beta)
	# Ry(beta)=  Ry21 Ry22 Ry23	=      0      1      0
	#	       Ry31 Ry32 Ry33	  -sin(beta)  0   cos(beta)
	#
	var Ry11 = cos_beta;
	var Ry12 = 0.;
	var Ry13 = sin_beta;
	var Ry21 = 0.;
	var Ry22 = 1.;
	var Ry23 = 0.;
	var Ry31 = - sin_beta;
	var Ry32 = 0.;
	var Ry33 = cos_beta;
	#
	# Rotate about z-axis Rz(gamma)
	#
	#	       Rz11 Rz12 Rz13	   cos(gamma)  -sin(gamma)  0
	# Rz(gamma)= Rz21 Rz22 Rz23	=  sin(gamma)	cos(gamma)  0
	#	       Rz31 Rz32 Rz33	       0	    0	    1
	#
	var Rz11 = cos_gamma;
	var Rz12 = - sin_gamma;
	var Rz13 = 0.;
	var Rz21 = sin_gamma;
	var Rz22 = cos_gamma;
	var Rz23 = 0.;
	var Rz31 = 0.;
	var Rz32 = 0.;
	var Rz33 = 1.;
	#
	# First rotation about x-axis
	# X_x = Rx*X_rel
	var x_x = Rx11 * x_rel + Rx12 * y_rel + Rx13 * z_rel;
	var y_x = Rx21 * x_rel + Rx22 * y_rel + Rx23 * z_rel;
	var z_x = Rx31 * x_rel + Rx32 * y_rel + Rx33 * z_rel;
	#
	# subsequent rotation about y-axis
	# X_xy = Ry*X_x
	var x_xy = Ry11 * x_x + Ry12 * y_x + Ry13 * z_x;
	var y_xy = Ry21 * x_x + Ry22 * y_x + Ry23 * z_x;
	var z_xy = Ry31 * x_x + Ry32 * y_x + Ry33 * z_x;
	#
	# subsequent rotation about z-axis:
	# X_xyz = Rz*X_xy
	var x_xyz = Rz11 * x_xy + Rz12 * y_xy + Rz13 * z_xy;
	var y_xyz = Rz21 * x_xy + Rz22 * y_xy + Rz23 * z_xy;
	var z_xyz = Rz31 * x_xy + Rz32 * y_xy + Rz33 * z_xy;
	
	# Back transformation  X_rel = X-Xr = (x-xr, y-yr, z-zr)
	var xn = xr + x_xyz;
	var yn = yr + y_xyz;
	var zn = zr + z_xyz;
	
	var Xn = [xn,yn,zn];
	
	return Xn;
	
}

var groundspeed_kt = props.globals.getNode("velocities/groundspeed-kt");
var alt_agl_ft	= props.globals.getNode("position/altitude-agl-ft");

var weight_lb = nil;
var empty_weight_lb = nil;

var ls = setlistener("/sim/signals/fdm-initialized", func() {
	if( fdm == "jsb" ) {
		weight_lb = props.globals.getNode("fdm/jsbsim/inertia/weight-lbs");
		empty_weight_lb = props.globals.getNode("fdm/jsbsim/inertia/empty-weight-lbs");
	} else if ( fdm == "yasim" ) {
		weight_lb = props.globals.getNode("yasim/gross-weight-lbs");
	}
	check_aircraft_tow_settings();
	removelistener(ls);
});

var winch_target = 0.8;
var winch_throttle = 0.0;

var winch_idle_force = 1000; # N
var winch_idle_speed = 4; # mps

var acceleration_N_s = nil;
var acceleration_m_s_s = nil;

var phase = 0;
var alpha = 0.0;
var requested_change = 0.0;	# positive: request to speed up, negative: request to slow down, 0: auto speed

###########
##	AUTOMATIC WINCH DRIVER
###########

#	Phase				Action description								Triggered by
#	0 		slowly pull rope until tight (currently omitted)			runWinch()
#	1		winch running on idle until aircraft is moving				"rope tight" command
#	2		winch accelerating to pre-defined RPM						"ready" command
#	3	glider in air, winch adjusts RPM based on angular velocity and faster/slower commands by pilot		"clear of ground" command
#	4		winch slowly decelerates to idle							aircraft 10-20 deg from automatic release angle
#	5		winch pulls in remaining rope								"rope released" command

##	Calculation of predefined targets:
#		-weight factor, accounts for additional weight (second pilot, water ballast)
#		-wind factors, account for different tow speed due to headwind/tailwind and crosswind

var target_force = 0.0;	# N
var target_speed = 0.0;	# m/s

var auto_winch_driver_init = func () {
	target_force = aircraft_settings.winch.typical_tow_force.getDoubleValue();
	target_speed = aircraft_settings.winch.typical_tow_speed.getDoubleValue() / 3.6; # convert kph to mps

	# Adjust target speed and force for current wind (increase for tail- and crosswind, reduce for headwind)
	
	# define wind frame: expect from 15 kts tailwind to 15 kts headwind -> translates to a change of +- 0.1
	var launch_heading_deg = winch_hash.rope.hdg.getDoubleValue();
	var wind_from_heading = wind_from.getDoubleValue();
	var wind_speed = wind_speed_kt.getDoubleValue();
	
	# calculate linear component
	var rel_wind_heading = launch_heading_deg - wind_from_heading;
	var wind_linear = wind_speed * math.cos( rel_wind_heading * D2R );		# negative values mean tailwind
	var wind_normal = wind_speed * math.cos( -( 90 - rel_wind_heading ) * D2R );	# negative values mean wind from the left
	# compensate for tail/headwind
	var wind_linear_add = math.clamp( -wind_linear / 150, -0.1, 0.1 );
	# compensate for crosswind
	var wind_normal_add = math.min( math.abs( wind_normal ) / 150, 0.1 );
	
	# apply compensation to winch driver variables
	target_force += ( wind_linear_add + wind_normal_add ) * config.winch.max_force.getDoubleValue();
	target_speed += ( wind_linear_add + wind_normal_add ) * config.winch.max_spool_speed.getDoubleValue();

	# set acceleration/deceleration variables
	acceleration_N_s = config.winch.force_acceleration.getDoubleValue();
	acceleration_m_s_s = config.winch.spool_acceleration.getDoubleValue();
	
	# put winch driver into initial state
	phase = 0;
}

var my_pos = nil;
var winch_pos = geo.Coord.new();

var auto_winch_driver = func () {
	if( !winch_hash.clutched.getBoolValue() ) return;

	var dt = delta_time.getDoubleValue();
	if( winch_hash.type != 0 and winch_hash.type != 1 ) {
		die("(towing system): FATAL: unsupported winch type!");
	}
	
	if( phase == 3 or phase == 4 ){
		my_pos = geo.aircraft_position();
		# Winch position
		var winch_global_pos_x = winch_hash.global_pos[0].getDoubleValue();
		var winch_global_pos_y = winch_hash.global_pos[1].getDoubleValue();
		var winch_global_pos_z = winch_hash.global_pos[2].getDoubleValue();
		
		var winch_geod = carttogeod(winch_global_pos_x, winch_global_pos_y, winch_global_pos_z);
		winch_pos.set_latlon( winch_geod[0], winch_geod[1], winch_geod[2] );
		
		alpha = math.asin( ( my_pos.alt() - winch_pos.alt() ) / winch_pos.direct_distance_to( my_pos ) ) * R2D;
	}
	
	if( phase == 0 ) {
		phase = 1;
	}
	if( phase == 1 ) {
		if( winch_hash.type == 0 ){
			force_setting = winch_idle_force;
		} else {
			speed_setting = winch_idle_speed;
		}
		
		# Condition for going into the next phase
		if( groundspeed_kt.getDoubleValue() > 1.0 ) {
			phase = 2;
			write_message( "launch-signaller", "Ready!" );
			write_message( "winch-driver", "Ready");
		}
	} else if ( phase == 2 or phase == 2.5 ){
		# Accelerate to target value
		if( winch_hash.type == 0 ){
			if( force_setting < target_force ){
				force_setting += acceleration_N_s * dt;
			} else {
				force_setting = target_force;
				if( phase == 2.5 ){
					phase = 3;
				}
			}
		} else {
			if( speed_setting < target_speed ){
				speed_setting += acceleration_m_s_s * dt;
			} else {
				speed_setting = target_speed;
				if( phase == 2.5 ){
					phase = 3;
				}
			}
		}
		
		# Condition for going into the next phase
		if( alt_agl_ft.getDoubleValue() > 10 and phase < 2.5 ){
			phase = 2.5; # stay here until we have reached the target value
			write_message( "launch-signaller", "Clear of ground!" );
			write_message( "winch-driver", "Clear");
		}
	} else if ( phase == 3 ){
		
		if( requested_change != 0 ){
			if( winch_hash.type == 0 ){
				force_setting += requested_change * config.winch.max_force.getDoubleValue() * dt;
			} else {
				speed_setting += requested_change * config.winch.max_spool_speed.getDoubleValue() * dt;
			}
			requested_change -= requested_change * dt;
			if( math.abs( requested_change ) < dt ){
				requested_change = 0.0;
			}
		}
		
		var thr_speed = 0.8;
		var thr_angle = 0.5;

		if( winch_hash.type == 0 ){

			var frac_speed = math.clamp( 0.2 + 1 - ( 1 / ( 1 - thr_speed ) ) * ( ( winch_hash.actual_spool_speed.getDoubleValue() / config.winch.max_spool_speed.getDoubleValue() ) - thr_speed ) * 0.8, 0.0, 1.0 );
			var frac_angle = math.clamp( 0.2 + 1 - ( 1 / ( 1 - thr_angle ) ) * ( ( alpha / ( aircraft_settings.winch.automatic_release_angle.getDoubleValue() - 30 ) ) - thr_angle ) * 0.8, 0.0, 1.0 );
			force_setting = target_force * frac_speed * frac_angle;

		} elsif( winch_hash.type == 1 ){

			var frac_speed = math.clamp( 0.2 + 1 - ( 1 / ( 1 - thr_speed ) ) * ( ( winch_hash.actual_spool_speed.getDoubleValue() / config.winch.max_spool_speed.getDoubleValue() ) - thr_speed ) * 0.8, 0.0, 1.0 );
			var frac_angle = math.clamp( 0.2 + 1 - ( 1 / ( 1 - thr_angle ) ) * ( ( alpha / ( aircraft_settings.winch.automatic_release_angle.getDoubleValue() - 30 ) ) - thr_angle ) * 0.8, 0.0, 1.0 );
			speed_setting = target_speed * frac_speed * frac_angle;

		}
		
		if( ( alpha >= ( aircraft_settings.winch.automatic_release_angle.getDoubleValue() - 10 ) ) ) {
			phase = 4;
		}
	} else if ( phase == 4 ){
		# Reduce values back to idle
		if( speed_setting > winch_idle_speed ){
			var deceleration = 3 * math.clamp( ( speed_setting - winch_idle_speed ) / ( aircraft_settings.winch.automatic_release_angle.getDoubleValue() - 2 - alpha ), 5, acceleration_m_s_s );
			speed_setting -= deceleration * dt;
		} else {
			speed_setting = winch_idle_speed;
		}
		
		# Condition for going into the next phase is set by the releaseHitch() command
	} else if ( phase == 5 ){
		if( winch_hash.type == 0 ){
			force_setting = winch_idle_force;
		} else {
			speed_setting = winch_idle_speed;
		}
		auto_winch_driver_update.stop();
	}
}

var auto_winch_driver_update = maketimer( 0.0, auto_winch_driver );
auto_winch_driver_update.simulatedTime = 1;


var winch_faster = func ( d = 0.1 ) {
	write_message( "pilot", "Faster!");
	
	#	Skip acceleration to pre-set target force/speed in case of pilot command
	if( phase == 2.5 ){
		phase = 3;
	}
	
	if( phase != 3 ){
		write_message( "winch-driver", "Unable!");
		return;
	}
	
	if( ( winch_hash.type == 0 and ( force_setting + d * config.winch.max_force.getDoubleValue() ) <= config.winch.max_force.getDoubleValue() ) or
		( winch_hash.type == 1 and ( speed_setting + d * config.winch.max_spool_speed.getDoubleValue() ) <= config.winch.max_spool_speed.getDoubleValue() ) ){
		
		requested_change = d;
		write_message( "winch-driver", "Faster");
	} else {
		if( winch_hash.type == 0 ){
			force_setting = config.winch.max_force.getDoubleValue();
		} else {
			speed_setting = config.winch.max_spool_speed.getDoubleValue();
		}
		write_message( "winch-driver", "At maximum!");
	}
}
var winch_slower = func ( d = 0.1 ) {
	write_message( "pilot", "Slower!");
	
	#	Skip acceleration to pre-set target force/speed in case of pilot command
	if( phase == 2.5 ){
		phase = 3;
	}
	
	if( phase != 3 ){
		write_message( "winch-driver", "Unable!");
		return;
	}
	
	if( ( winch_hash.type == 0 and force_setting - d * config.winch.max_force.getDoubleValue() >= winch_idle_force ) or
		( winch_hash.type == 1 and speed_setting - d * config.winch.max_spool_speed.getDoubleValue() >= winch_idle_speed ) ){
		
		requested_change = -d;
		write_message( "winch-driver", "Slower");
	} else {
		if( winch_hash.type == 0 ){
			force_setting = winch_idle_force;
		} else {
			speed_setting = winch_idle_speed;
		}
		write_message( "winch-driver", "At minimum!");
	}
}


##################################################################################################################################


# todo:
# ------
#
# - animate rope slack
# - dynamic ID for ai-rope-model
#
# Please contact D_NXKT at yahoo.de for bug-reports, suggestions, ...
#
