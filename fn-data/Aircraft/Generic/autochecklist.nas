################################################################################
#
# Automated Checklists
#
# Copyright (c) 2015, Richard Senior
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
################################################################################
#
# This script runs the bindings in a sequence of checklists. Typically used
# to implement autostart or shutdown but can run any checklist sequence at any
# time. Checklist execution runs each binding where the condition is not yet
# satisfied and waits until the condition becomes true before moving on. If
# the condition does not become true within a timeout period, the checklist
# execution fails.
#
# Can also run in no wait mode where items are run in order without waiting
# for the previous condition to become true. Checklists never timeout or fail
# in no wait mode but some conditions may remain false.
#
# Typical usage:
#
# 1. Add this script to <Aircraft>-set.xml:
#
#    <nasal>
#      ... other scripts here
#      <autochecklist>
#        <file>Aircraft/Generic/autochecklist.nas</file>
#      </autochecklist>
#    </nasal>
#
# 2. In the <Aircraft>-set.xml, define a list of checklist indexes to run
#    as a named sequence.
#
#    For example, to run checklists with indexes 0 and 1 for startup and
#    checklist 9 for shutdown:
#
#   <checklists>
#     <checklist include="Checklists/before-starting-engines.xml"/>
#     <checklist include="Checklists/start-engines.xml"/>
#     ... more checklists here
#     <checklist include="Checklists/parking.xml"/>
#     <startup>
#       <index n="0">0</index> <!-- Before starting engines -->
#       <index n="1">1</index> <!-- Start engines -->
#     </startup>
#     <shutdown>
#       <index n="0">9</index> <!-- Parking -->
#     </startup>
#   </checklists>
#     
#    If you are using <group>-tags in your checklist definition, you need
#    to add one  <group-index> per sequence.
#
# 3. Define a menu item that calls the complete_checklists function with
#    the name of the checklist sequence you would like to run.
#
#    For example:
#
#    <item>
#      <label>Autostart</label>
#      <binding>
#        <command>nasal</command>
#        <script>autochecklist.complete_checklists("startup");</script>
#      </binding>
#    </item>
#
#    For a no wait checklist execution (which will never fail), pass zero (0)
#    as the second argument:
#
#    autochecklist.complete_checklists(sequence:"startup", wait:0);
#
# 4. Optionally, configure automated execution using the following properties.
#    See comments within the autochecklist_init function for a description.
#
#   <checklists>
#     ...
#     <auto>
#       <completed-message>Checklists complete</completed-message>
#       <startup-message>Running checklists, please wait ...</startup-message>
#       <timeout-message>Some checks failed.</timeout-message>
#       <timeout-sec>10</timeout-sec>
#       <wait-sec>3</wait-sec>
#     <auto>
#   </checklists>
#
#   Note that messages are not displayed for no wait execution.
#
################################################################################

var checklists = nil;
var auto = nil;
var active = nil;
var expedited = nil;
var timeout_sec = nil;
var timeout_start = nil;
var wait_sec = nil;
var completed_message = nil;
var startup_message = nil;
var timeout_message = nil;

var autochecklist_init = func()
{
    # Root property tree path for checklists
    #
    checklists = props.globals.getNode("sim/checklists");

    # Root property tree path for auto checklists
    #
    auto = checklists.initNode("auto");

    # Flag to indicate that checklists are being completed automatically.
    # This can be used in Nasal bindings in the checklists to suppress a
    # binding when automated execution is in progress, e.g. for checklist
    # items that display dialogs.
    #
    active = auto.initNode("active", 0, "BOOL");

    # Flag to indicate that checklist execution is expedited, i.e. there
    # is no wait time between items. Typically indicates an in-air start. Note
    # that the expedited flag does not imply automated checklists are active.
    #
    expedited = auto.initNode("expedited", 0, "BOOL");

    # Timeout for completion of a checklist item. If the previous condition
    # is still not satisifed after this timeout, the checklist fails.
    #
    timeout_sec = auto.initNode("timeout-sec", 10, "INT");
    timeout_start = auto.initNode("timeout-start", 0.0, "DOUBLE");

    # If the previous checklist item is not complete, the process waits
    # this number of seconds before trying again.
    #
    wait_sec = auto.initNode("wait-sec", 3, "INT");

    # Messages
    #
    completed_message = auto.initNode("completed-message",
        "Checklists complete."
    );

    startup_message = auto.initNode("startup-message",
        "Running checklists, please wait ..."
    );

    timeout_message = auto.initNode("timeout-message",
        "Some checks failed. Try completing checklist manually."
    );
}

################################################################################

# Announces a message to the pilot
#
# @param message: the message to display
#
var announce = func(message)
{
    setprop("sim/messages/copilot", message);
    logprint(3, message);
}

# Resets the timestamp used for checking timeouts
#
var reset_timeout = func()
{
    timeout_start.setValue(0.0);
}

# Return true if the timeout period has been exceeded
#
var timed_out = func()
{
    var elapsed = getprop("sim/time/elapsed-sec") - timeout_start.getValue();
    return timeout_start.getValue() and elapsed > timeout_sec.getValue();
}

# Waits for the completion of an item, setting a timestamp for timeouts
#
# @param node: the node containing the list of checklist indexes to run
# @param from: the checklist item node from which to start
#
var wait_for_completion = func(node, from)
{
    var t = maketimer(wait_sec.getValue(), func {
        complete(node, 1, from);
    });
    t.singleShot = 1;
    t.start();

    if (!timeout_start.getValue()) {
        timeout_start.setValue(getprop("sim/time/elapsed-sec"));
    }
}

# Automatically complete a set of checklists defined by a series of indexes
# listed under the node argument. Not intended to be called from outside this
# script.
#
# @param node: the node containing the list of checklist indexes to run
# @param wait: whether to wait for the preceding binding to complete
# @param from: the checklist item node from which to start, default nil
#
var complete = func(node, wait, from = nil)
{
    var previous_condition = nil;
    var skipping = from != nil;
    
    if( node.getChild("group-index") != nil ){
	    var checklists_node = checklists.getChild("group", node.getChild("group-index").getIntValue());
    } else {
	    var checklists_node = checklists;
    }
	
    foreach (var index; node.getChildren("index")) {
        var checklist = checklists_node.getChild("checklist", index.getValue());
	  if( size( checklist.getChildren("page") ) > 0 ){
		foreach( var page; checklist.getChildren("page") ){
			foreach (var item; page.getChildren("item")) {
				var condition = item.getNode("condition");
				if (skipping) {
					if (!item.equals(from)) {
						previous_condition = condition;
						continue;
					}
					skipping = 0;
				}
				if (wait) {
					if (props.condition(previous_condition)) {
						reset_timeout();
					} else {
						if (timed_out()) {
							var title = checklist.getNode("title").getValue();
							announce(title~": "~timeout_message.getValue());
						} else {
							wait_for_completion(node: node, from: item);
						}
						return;
					}
				}
				if (!props.condition(condition)) {
					foreach (var binding; item.getChildren("binding")) {
						active.setValue(1);
						props.runBinding(binding);
						active.setValue(0);
					}
				}
				previous_condition = condition;
			}

		}

	 } else {
		foreach (var item; checklist.getChildren("item")) {
			var condition = item.getNode("condition");
			if (skipping) {
			if (!item.equals(from)) {
				previous_condition = condition;
				continue;
			}
			skipping = 0;
			}
			if (wait) {
			if (props.condition(previous_condition)) {
				reset_timeout();
			} else {
				if (timed_out()) {
					var title = checklist.getNode("title").getValue();
					announce(title~": "~timeout_message.getValue());
				} else {
					wait_for_completion(node: node, from: item);
				}
				return;
			}
			}
			if (!props.condition(condition)) {
			foreach (var binding; item.getChildren("binding")) {
				active.setValue(1);
				props.runBinding(binding);
				active.setValue(0);
			}
			}
			previous_condition = condition;
		}
	 }

    }
    if (wait) {
        announce(completed_message.getValue());
    }
}

################################################################################

# Complete a checklist sequence, typically called from a Nasal binding in a
# menu, e.g. Autostart, but could be assigned to a controller button or even
# called from a listener.
#
# @param sequence: the name of the checklist sequence to run
# @param wait: whether to wait for the preceding binding, default 1 (true)
#
var complete_checklists = func(sequence, wait = 1)
{
    var node = checklists.getNode(sequence);
    if (node != nil) {
        if (wait) {
            announce(startup_message.getValue());
        }
        expedited.setValue(!wait);
        complete(node, wait);
    } else {
        announce("Could not find checklist sequence called '"~sequence~"'");
    }
}

setlistener("/sim/signals/fdm-initialized", func() {
    autochecklist_init();
});

