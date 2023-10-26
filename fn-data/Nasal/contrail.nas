# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#
# Copyright (C) 2010 by Vivian Meazza
# Copyright (C) 2013 by Philosopher
# Copyright (C) 2020 by Henning Stahlke

#########
# contrail calculator. Based on an approxmation to the "Appleman Chart"
# y = -0.077x2 + 2.7188x - 64.36
########

var pressure_Node = props.globals.initNode("environment/pressure-inhg", 1, "DOUBLE");
var temperature_Node = props.globals.initNode("environment/temperature-degc", 1, "DOUBLE");
var contrail_Node = props.globals.initNode("environment/contrail", 1, "BOOL");
var contrail_temp_Node = props.globals.initNode("environment/contrail-temperature-degc", 1, "DOUBLE");
var static_contrail_node = props.globals.getNode("sim/ai/aircraft/contrail", 1);
var time_node = props.globals.getNode("sim/time/elapsed-sec", 1);

updateContrail = func {
    var x = pressure_Node.getValue();
    var y = temperature_Node.getValue();
    var con_temp = -0.077 * x * x + 2.7188 * x - 64.36;
    contrail_temp_Node.setValue(con_temp);

    if (y < con_temp and y < -40) {
        contrail_Node.setValue(1);
    } else {
        contrail_Node.setValue(0);
    }
}

updateContrail(); # avoid 30 second delay on startup https://sourceforge.net/p/flightgear/codetickets/2077/

contrailTimer = maketimer(30, updateContrail);
contrailTimer.simulatedTime = 1;
contrailTimer.restart(30);
