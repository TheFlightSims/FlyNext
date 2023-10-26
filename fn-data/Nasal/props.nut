#-------------------------------------------------------------------------------
# SPDX-License-Identifier: GPL-2.0-or-later
#-------------------------------------------------------------------------------
# props.Node.nut - Nasal Unit Test for props.Node.nas
# created: 06/2020
# Copyright (C) 2020 by Henning Stahlke
#-------------------------------------------------------------------------------

var setUp = func {
    print("setUp "~caller(0)[2]~" ");
};

var tearDown = func {

};

var test_isValidPropName = func() {
    # test valid names
    unitTest.assert(props.Node.isValidPropName("abc123") == 1, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("_abc123") == 1, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("_1a") == 1, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("_1a.-") == 1, "isValidPropName()");
    # test invalid names
    unitTest.assert(props.Node.isValidPropName("1a") == 0, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("abä") == 0, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("foo:bar") == 0, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("foo<bar") == 0, "isValidPropName()");
    unitTest.assert(props.Node.isValidPropName("") == 0, "isValidPropName()");
}

var test_makeValidPropName = func() {
    # test valid names
    unitTest.assert(props.Node.makeValidPropName("abc123") == "abc123", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("_abc123") == "_abc123", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("_1a") == "_1a", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("_1a.-") == "_1a.-", "makeValidPropName()");
    # test invalid names
    unitTest.assert(props.Node.makeValidPropName("1a") == "_a", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("foo:bar") == "foo_bar", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("foo<bar") == "foo_bar", "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("") == nil, "makeValidPropName()");
    unitTest.assert(props.Node.makeValidPropName("abä") == "ab_", "makeValidPropName()");
}
