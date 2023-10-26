# Failure Manager public interface
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


var proproot = "sim/failure-manager/";


##
# Nasal modules can subscribe to FailureMgr events.
# Each event has an independent dispatcher so modules can subscribe only to
# the events they are interested in. This also simplifies processing at client
# side by being able to subscibe different callbacks to different events.
#
# Example:
#
# var handle = FailureMgr.events["trigger-fired"].subscribe(my_callback);

var events = {};

# Event: trigger-fired
# Format: { mode_id: <failure mode id>, trigger: <trigger that fired> }
events["trigger-fired"] = globals.events.EventDispatcher.new();

##
# Encodes a pair "category" and "failure_mode" into a "mode_id".
#
# These just have the simple form "category/mode", and are used to refer to
# failure modes throughout the FailureMgr API and to create a path within the
# sim/failure-manager property tree for the failure mode.
#
# examples of categories:
#	structural, instrumentation, controls, sensors, etc...
#
# examples of failure modes:
#	altimeter, pitot, left-tire, landing-light, etc...

var get_id = func(category, failure_mode) {
	return sprintf("%s/%s", string.normpath(category), failure_mode);
}

##
# Returns a vector containing: [category, failure_mode]

var split_id = func(mode_id) {
	return [string.normpath(io.dirname(mode_id)), io.basename(mode_id)];
}

##
# Subscribe a new failure mode to the system.
#
# id:          Unique identifier for this failure mode.
#              eg: "engine/carburetor-ice"
#
# description: Short text description, suitable for printing to the user.
#              eg: "Ice in the carburetor"
#
# actuator:    Object implementing the FailureActuator interface.
#              Used by the failure manager to apply a certain level of
#              failure to the failure mode.

var add_failure_mode = func(id, description, actuator) {
	_failmgr.add_failure_mode(
		FailureMode.new(id, description, actuator));
}

##
# Returns a vector with all failure modes in the system.
# Each vector entry is a hash with the following keys:
#	{ id, description }

var get_failure_modes = func() {
	_failmgr.get_failure_modes();
}

##
# Remove a failure mode from the system.
# id: FailureMode id string, e.g. "systems/pitot"

var remove_failure_mode = func(id) {
	_failmgr.remove_failure_mode(id);
}

##
# Removes all failure modes from the failure manager.

var remove_all = func {
	_failmgr.remove_all();
}

##
# Attaches a trigger to the given failure mode. Discards the current trigger
# if any.
#
# mode_id: FailureMode id string, e.g. "systems/pitot"
# trigger: Trigger object or nil. Nil will just detach the current trigger

var set_trigger = func(mode_id, trigger) {
	_failmgr.set_trigger(mode_id, trigger);
}

##
# Returns the trigger object attached to the given failure mode.
# mode_id: FailureMode id string, e.g. "systems/pitot"

var get_trigger = func(mode_id) {
	_failmgr.get_trigger(mode_id);
}

##
# Applies a certain level of failure to this failure mode.
#
# mode_id: Failure mode id string.
# level:   Floating point number in the range [0, 1]
#          Zero represents no failure and one means total failure.

var set_failure_level = func(mode_id, level) {
	setprop(proproot ~ mode_id ~ "/failure-level", level);
}

##
# Returns the current failure level for the given failure mode.
# mode_id: Failure mode id string.

var get_failure_level = func(mode_id) {
	getprop(proproot ~ mode_id ~ "/failure-level");
}

##
# Restores all failure modes to level = 0

var repair_all = func {
	_failmgr.repair_all();
}

##
# Returns a vector of timestamped failure manager events, such as the
# messages shown in the console when there are changes to the failure conditions.
#
# Each entry in the vector has the following format:
#     { time: <time stamp>, message: <event description> }

var get_log_buffer = func {
	_failmgr.logbuf.get_buffer();
}

##
# Allows applications to disable the failure manager and restore it later on.
# While disabled, no failure modes will be activated from the failure manager.

var enable = func setprop(proproot ~ "enabled", 1);
var disable = func setprop(proproot ~ "enabled", 0);

##
# Encapsulates a condition that when met, will make the failure manager to
# apply a certain level of failure to the failure mode it is bound to.
#
# Two types of triggers are supported: pollable and asynchronous.
#
# Pollable triggers require periodic check for trigger conditions. For example,
# an altitude trigger will need to poll current altitude until the fire
# condition is reached.
#
# Asynchronous trigger do not require periodic updates. They can detect
# the firing condition by themselves by using timers or listeners.
# Async triggers must call the inherited method on_fire() to let the Failure
# Manager know about the fired condition.
#
# See Aircraft/Generic/Systems/failures.nas for concrete examples of triggers.

var Trigger = {

	type: nil,
	# 1 for pollable triggers, 0 for async triggers.
	requires_polling: 0,
	enabled: 0,

	new: func {
		return {
			parents: [Trigger],
			params: {},
			armed: 0,
			fired: 0,

			##
			# Async triggers shall call the on_fire() callback when their fire
			# conditions are met to notify the failure manager.
			on_fire: func 0,

			_path: nil
		};
	},

	##
	# Forces a check of the firing conditions. Returns 1 if the trigger fired,
	# 0 otherwise.

	update: func 0,

	##
	# Returns a printable string describing the trigger condition.

	to_str: func "undefined trigger",

	##
	# Modify a trigger parameter. Parameters will take effect after the next
	# call to reset()

	set_param: func(param, value) {
		assert(me._path != nil, "Trigger.set_param: unbound trigger");

		contains(me.params, param) or
			die("Trigger.set_param: undefined param: " ~ param);

		setprop(sprintf("%s/%s",me._path, param), value);
	},

	##
	# Load trigger parameters and reset internal state. Once armed, the trigger
	# will fire as soon as the right conditions are met. It can be called after
	# the trigger fires to rearm it again.
	#
	# The "armed" condition survives enable/disable calls.

	arm: func {
		assert(me._path != nil, "Trigger.arm: unbound trigger");
		setprop(me._path ~ "/armed", 1);
	},

	_arm: func {
		foreach (var p; keys(me.params))
			me.params[p] = getprop(sprintf("%s/%s", me._path, p));

		me.fired = 0;
		me.armed = 1;
	},

	##
	# Deactivate the trigger. The trigger will not fire until rearmed again.

	disarm: func {
		assert(me._path != nil, "Trigger.disarm: unbound trigger");
		setprop(me._path ~ "/armed", 0);
	},

	_disarm: func {
		me.armed = 0;
	},

	##
	# Enables/disables the trigger. While a trigger is disabled, any timer
	# or listener that could potentially own shall be disabled.
	#
	# The FailureMgr calls these methods when the entire system is
	# enabled/disabled. By keeping enabled/disabled state separated from
	# armed/disarmed allows the FailureMgr to keep its configuration while
	# disabled, i.e. those triggers that where armed when the system was
	# disabled will resume when the system is enabled again.
	#
	# The FailureMgr disables itself during a teleport.

	enable: func { me.enabled = 1 },
	disable: func { me.enabled = 0 },

	##
	# Creates an interface for the trigger in the property tree.
	# Every parameter in the params hash will be exposed, in addition to
	# a path/reset property for resetting the trigger from the prop tree.

	bind: func(path) {
		assert(me._path == nil, "Trigger.bind: trigger already bound");

		me._path = path;
		props.globals.getNode(path) != nil or props.globals.initNode(path);
		props.globals.getNode(path).setValues(me.params);

		var prop = path ~ "/armed";
		props.globals.initNode(prop, 0, "BOOL");
		setlistener(prop,
		            func(p) { p.getValue() ? me._arm() : me._disarm() }, 0, 1);
	},

	##
	# Removes this trigger's interface from the property tree.

	unbind: func {
		props.globals.getNode(me._path ~ "/armed").remove();
		foreach (var p; keys(me.params))
			props.globals.getNode(me._path ~ "/" ~ p).remove();

		me._path = nil;
	}
};

##
# FailureActuators encapsulate the actions required for activating the actual
# failure simulation.
#
# Traditionally this action was just manipulating a "serviceable" property
# somewhere, but the FailureActuator gives you more flexibility, allowing you
# to touch several properties at once or call other Nasal scripts, for example.
#
# See Aircraft/Generic/Systems/failure.nas and
# Aircraft/Generic/Systems/compat_failures.nas for some examples of actuators.

var FailureActuator = {

	##
	# Called from the failure manager to activate a certain level of failure.
	# level: Target level of failure [0 to 1].

	set_failure_level: func(level) 0,

	##
	# Returns the level of failure that is currently being simulated.

	get_failure_level: func 0,
};
