# Failure Manager implementation
#
# Monitors trigger conditions periodically and fires failure modes when those
# conditions are met. It also provides a central access point for publishing
# failure modes to the user interface and the property tree.
#
# Copyright (C) 2014 Anton Gomez Alvedro
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.



##
# Represents one way things can go wrong, for example "a blown tire".

var FailureMode = {

	##
	# id:          Unique identifier for this failure mode.
	#              eg: "engine/carburetor-ice"
	#
	# description: Short text description, suitable for printing to the user.
	#              eg: "Ice in the carburetor"
	#
	# actuator:    Object implementing the FailureActuator interface.
	#              Used by the failure manager to apply a certain level of
	#              failure to the failure mode.

	new: func(id, description, actuator) {
		return {
			parents: [FailureMode],
			id: id,
			description: description,
			actuator: actuator,
			_path: nil
		};
	},

	##
	# Applies a certain level of failure to this failure mode.
	# level: Floating point number in the range [0, 1] zero being no failure
	#        and 1 total failure.

	set_failure_level: func(level) {
		assert(me._path != nil, "FailureMode.set_failure_level: unbound mode");
		setprop(me._path ~ me.id ~ "/failure-level", level);
	},

	##
	# Internal version that actually does the job.

	_set_failure_level: func(level) {
		me.actuator.set_failure_level(level);
		_failmgr.log(sprintf("%s condition %d%%", me.description, (1-level)*100));
	},

	##
	# Returns the level of failure currently being simulated.

	get_failure_level: func me.actuator.get_failure_level(),

	##
	# Creates an interface for this failure mode in the property tree at the
	# given location. Currently the interface is just:
	#
	# path/failure-level (double, rw)

	bind: func(path) {
		assert(me._path == nil, "FailureMode.bind: mode already bound");

		var prop = path ~ me.id ~ "/failure-level";
		props.globals.initNode(prop, me.actuator.get_failure_level(), "DOUBLE");
		setlistener(prop, func (p) me._set_failure_level(p.getValue()), 0, 0);
		me._path = path;
	},

	##
	# Remove bound properties from the property tree.

	unbind: func {
		me._path != nil and props.globals.getNode(me._path ~ me.id).remove();
		me._path = nil;
	},
};

##
# Implements the FailureMgr functionality.
#
# It is wrapped into an object to leave the door open to several evolution
# approaches, for example moving the implementation down to the C++ engine.
# Additionally, it also serves to isolate implementation details into its own
# namespace.

var _failmgr = {

	pollable_trigger_count: 0,
	enable_after_teleport: 0,

	timer: nil,
	update_period: 10, # 0.1 Hz

	failure_modes: {},
	logbuf: events.LogBuffer.new(echo: 1),

	init: func {
		me.timer = maketimer(me.update_period, func me._update());
		setlistener("sim/signals/reinit", func(n) me._on_teleport(n));
		setlistener("sim/signals/fdm-initialized", func(n) me._on_teleport(n));

		props.globals.initNode(proproot ~ "display-on-screen", 1, "BOOL");
		props.globals.initNode(proproot ~ "enabled", 1, "BOOL");
		setlistener(proproot ~ "enabled",
		            func (n) { n.getValue() ? me._enable() : me._disable() });
	},

	add_failure_mode: func(mode) {
		contains(me.failure_modes, mode.id) and
			die("add_failure_mode: failure mode already exists: " ~ mode.id);

		me.failure_modes[mode.id] = { mode: mode, trigger: nil };
		mode.bind(proproot);
	},

	get_failure_modes: func {
		var modes = [];

		foreach (var k; keys(me.failure_modes)) {
			var m = me.failure_modes[k];
			append(modes, {
				id: k,
				description: m.mode.description });
		}

		return modes;
	},

	remove_failure_mode: func(id) {
		contains(me.failure_modes, id) or
			die("remove_failure_mode: failure mode does not exist: " ~ id);

		var trigger = me.failure_modes[id].trigger;
		if (trigger != nil)
			me._discard_trigger(trigger);

		me.failure_modes[id].mode.unbind();
		delete(me.failure_modes, id);
	},

	remove_all: func {
		foreach(var id; keys(me.failure_modes))
			me.remove_failure_mode(id);
	},

	repair_all: func {
		foreach(var id; keys(me.failure_modes))
			me.failure_modes[id].mode.set_failure_level(0);
	},

	set_trigger: func(mode_id, trigger) {
		contains(me.failure_modes, mode_id) or
			die("set_trigger: failure mode does not exist: " ~ mode_id);

		var mode = me.failure_modes[mode_id];

		if (mode.trigger != nil)
			me._discard_trigger(mode.trigger);

		mode.trigger = trigger;
		if (trigger == nil) return;

		trigger.bind(proproot ~ mode_id);
		trigger.on_fire = func _failmgr.on_trigger_activated(trigger);

		if (trigger.requires_polling) {
			me.pollable_trigger_count += 1;

			if (me.enabled() and !me.timer.isRunning)
				me.timer.start();
		}

		if (me.enabled())
			trigger.enable();
	},

	get_trigger: func(mode_id) {
		contains(me.failure_modes, mode_id) or
			die("get_trigger: failure mode does not exist: " ~ mode_id);

		return me.failure_modes[mode_id].trigger;
	},

	##
	# Observer interface. Called from asynchronous triggers when they fire.
	# trigger: Reference to the firing trigger.

	on_trigger_activated: func(trigger) {
		assert(me.enabled(), "A " ~ trigger.type ~ " trigger fired while the FailureMgr was disabled");
		var found = 0;

		foreach (var id; keys(me.failure_modes)) {
			if (me.failure_modes[id].trigger == trigger) {
				found = 1;
				me.failure_modes[id].mode.set_failure_level(1);
				trigger.disarm();
				FailureMgr.events["trigger-fired"].notify(
					{ mode_id: id, trigger: trigger });
				break;
			}
		}

		assert(found, "FailureMgr.on_trigger_activated: trigger not found");
	},

	##
	# Enable the failure manager. Starts the trigger poll timer and enables
	# all triggers.
	#
	# Called from /sim/failure-manager/enabled and during a teleport if the
	# FM was enabled when the teleport was initiated.

	_enable: func {
		foreach(var id; keys(me.failure_modes)) {
			var trigger = me.failure_modes[id].trigger;
			trigger != nil and trigger.enable();
		}

		if (me.pollable_trigger_count > 0)
			me.timer.start();
	},

	##
	# Suspends failure manager activity. Pollable triggers will not be updated
	# and all triggers will be disabled.
	# Called from /sim/failure-manager/enabled and during a teleport.

	_disable: func {
		me.timer.stop();

		foreach(var id; keys(me.failure_modes)) {
			var trigger = me.failure_modes[id].trigger;
			trigger != nil and trigger.disable();
		}

	},

	enabled: func {
		getprop(proproot ~ "enabled");
	},

	log: func(message) {
		me.logbuf.push(message);
		if (getprop(proproot ~ "/display-on-screen"))
			screen.log.write(message, 1.0, 0.0, 0.0);
	},

	##
	# Poll loop. Updates pollable triggers and applies a failure level
	# when they fire.

	_update: func {
		foreach (var id; keys(me.failure_modes)) {
			var failure = me.failure_modes[id];
			var trigger = failure.trigger;

			if (trigger == nil or !trigger.requires_polling or !trigger.armed)
				continue;

			var level = trigger.update();
			if (level == 0) continue;

			if (level != failure.mode.get_failure_level())
				failure.mode.set_failure_level(level);
			trigger.disarm();

			FailureMgr.events["trigger-fired"].notify(
				{ mode_id: id, trigger: trigger });
		}
	},

	_discard_trigger: func(trigger) {
		trigger.disable();
		trigger.unbind();

		if (trigger.requires_polling) {
			me.pollable_trigger_count -= 1;
			me.pollable_trigger_count == 0 and me.timer.stop();
		}
	},

	##
	# Teleport listener. During repositioning, all triggers are disabled to
	# avoid them firing in a possibly inconsistent state.

	_on_teleport: func(pnode) {

		if (pnode.getName() == "fdm-initialized") {
			if (me.enable_after_teleport) {
				me._enable();
				me.enable_after_teleport = 0;
			}
		}
		else {
			# then, it's /sim/signals/reinit
			# only react when the signal raises to true.
			if (pnode.getValue() == 1) {
				me.enable_after_teleport = me.enabled();
				me._disable();
			}
		}
	},

	dump_status: func(mode_ids=nil) {

		if (mode_ids == nil)
			mode_ids = keys(me.failure_modes);

		print("\nFailureMgr Status\n----------------------------------------");

		foreach(var id; mode_ids) {
			var mode = me.failure_modes[id].mode;
			var trigger = me.failure_modes[id].trigger;

			print(id, ": failure level ", mode.get_failure_level());

			if (trigger == nil) {
				print("  no trigger");
			}
			else {
				print("  ", trigger.type, " trigger (",
				      trigger.enabled? "enabled, " : "disabled, ",
				      trigger.armed? "armed)" : "disarmed)");
			}
		}
	}
};

##
# Module initialization

var _init = func {
	removelistener(lsnr);
	_failmgr.init();

	# Load legacy failure modes for backwards compatibility
	io.load_nasal(getprop("/sim/fg-root") ~
	              "/Aircraft/Generic/Systems/compat_failure_modes.nas");
}

var lsnr = setlistener("/nasal/FailureMgr/loaded", _init);
