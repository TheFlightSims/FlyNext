var i = 0;
var spectator = 0;
var spectator_offset = 0.5;
var range = 3.0;
var offset = 0.0;
var apply_close = 0;
var master = 0;
var close = 0;
var initialised = 0;

var ls_spect = nil;
var ls_spctoffset = nil;
var ls_range = nil;
var ls_offset = nil;
var ls_close = nil;

#   the compensatelag value are used like that by AIMultiplayer.cxx:
#
#   1 : old behaviour, trying to keep the plane without doing prediction
#   2 : predict the plane position in the futur
#   3 : display more in the past to avoid predictions

var mpCheck = func() {
	var mpname = getprop("/ai/models/multiplayer["~i~"]/callsign");
	if (mpname != nil) {
		if ((spectator) and (master)) {
			setprop("/ai/models/multiplayer["~i~"]/controls/compensate-lag", 3);
			setprop("/ai/models/multiplayer["~i~"]/controls/player-lag", -spectator_offset);
		} else {
			if ((apply_close) and (master)) {
				var self = geo.aircraft_position();
				var x = getprop("/ai/models/multiplayer["~i~"]/position/global-x");
				var y = getprop("/ai/models/multiplayer["~i~"]/position/global-y");
				var z = getprop("/ai/models/multiplayer["~i~"]/position/global-z");
				var ac = geo.Coord.new().set_xyz(x, y, z);
				var distance = self.distance_to(ac)*M2NM;
				if ((distance > range)or(distance==nil)) {
					setprop("/ai/models/multiplayer["~i~"]/controls/compensate-lag", 1);
				} else {
					setprop("/ai/models/multiplayer["~i~"]/controls/compensate-lag", 2);
					setprop("/ai/models/multiplayer["~i~"]/controls/player-lag", offset);
				}
			} else {
				setprop("/ai/models/multiplayer["~i~"]/controls/compensate-lag", 1);
			}
		}
		i += 1;
	} else {
		i = 0;
		if (close) close = 0;
	}
	if ((master) or (close)) {
		settimer(mpCheck, 1);
	}
}

var mpInit = func() {
	if (!initialised) {
		print("initialising the mp lag system");
		initialised = 1;
		ls_spect = setlistener("/sim/multiplay/lag/spectator",func { spectator =  getprop("/sim/multiplay/lag/spectator")}, 1);
		ls_spctoffset = setlistener("/sim/multiplay/lag/spectator-offset",func { spectator_offset = getprop("/sim/multiplay/lag/spectator-offset")}, 1);
		ls_range = setlistener("/sim/multiplay/lag/range",func { range = getprop("/sim/multiplay/lag/range")}, 1);
		ls_offset = setlistener("/sim/multiplay/lag/offset",func { offset = getprop("/sim/multiplay/lag/offset")}, 1);
		ls_close = setlistener("/sim/multiplay/lag/apply-close", func { apply_close = getprop("/sim/multiplay/lag/apply-close")}, 1);
	}
}

var mpClean = func() {
	close = 1;
	master = 0;
}

var mpStart = func() {
	var test = getprop("/sim/multiplay/lag/master");
	if (test == nil) {
		settimer(mpStart, 2);
	} else {
		setlistener("/sim/multiplay/lag/master", masterSwitch,1);
	}
}

var masterSwitch = func() {
	master = getprop("/sim/multiplay/lag/master");
	if (master)  {
		mpInit();
		mpCheck();
			} else {
		mpClean();
	}
}

mpStart();
