# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."

#-------------------------------------------------------------------------------
# std.nas - class loader for std lib
# author:       Henning Stahlke
# created:      07/2020
#-------------------------------------------------------------------------------
var include_path = "Nasal/std/";
var files = [
    "hash",
    "string",
    "Vector",
];

foreach (var file; files) {
    io.include(include_path~file~".nas");
}

var min = func(a, b) { a < b ? a : b }
var max = func(a, b) { a > b ? a : b }
