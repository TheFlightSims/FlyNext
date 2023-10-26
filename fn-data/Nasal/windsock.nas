###############################################################################
##
## Windsock turbulence animation
##
###############################################################################

# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#
# Copyright (C) 2017-2020 by Erik Hofman

var dt = 0.0;
var windsock = func {
  var wind = getprop("/environment/wind-speed-kt") or 0;
  var mag1 = getprop("/environment/turbulence/magnitude-norm") or 0;
  var mag2 = getprop("/environment/turbulence/raw-magnitude-norm") or 0;
  var sens = getprop("/environment/turbulence/sensitivity") or 1.0;
  var rateHz = getprop("/environment/turbulence/rate-hz") or 0;
  var rate = 3.1514 * rateHz;
  var tot1 = math.sin(dt*rate)*mag1*mag1;
  var tot2 = math.sin(3.33*dt*rate/sens)*sens*mag2*mag2;
  tot2 = mag2*tot2 + (1-mag2)*math.tan(dt/10)/5;
  var total = wind + tot2 + tot1*tot2;

  interpolate("/environment/windsock/wind-speed-kt", total, 0.3);

  total += 5*mag2;
  interpolate("/environment/windsock/wind-speed-12.5kt", total, 0.1);

  dt += 0.08 + 0.02*(math.sin(dt)+math.cos(dt/(mag2+0.01))*0.33);
}
windsockTimer = maketimer(0.25, windsock);
windsockTimer.simulatedTime = 1;
windsockTimer.start();
