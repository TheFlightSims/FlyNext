# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#-------------------------------------------------------------------------------
# svgcanvas.nut - Nasal unit test vor svgcanvas.nas
# author:       jsb
# created:      07/2020
#-------------------------------------------------------------------------------

var test_SVGCanvas = func {
    var svgc = canvas.SVGCanvas.new("test");
    unitTest.assert(isa(svgc, canvas.SVGCanvas), "SVGCanvas.new");
    var tmp = svgc.getCanvas();
    unitTest.assert(isghost(tmp) and ghosttype(tmp) == "Canvas", "SVGCanvas.getCanvas");
    var prefix = "canvas://by-index/texture";
    unitTest.assert(left(svgc.getPath(), size(prefix)) == prefix, "SVGCanvas.getPath");
    unitTest.assert(isa(svgc.getRoot(), canvas.Group), "SVGCanvas.getRoot");
    var win = svgc.asWindow([300,300]);
    unitTest.assert(isa(win, canvas.Window), "SVGCanvas.asWindow");
    win.del();
};