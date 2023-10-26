# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later


var GUIMenuItem = {

    aboutToShow: func() {

    },

    # return a Canvas object (group) of the contents
    show: func(viewParent) {

    }

};

var GUIMenu = {

    aboutToShow: func() {

    },

    # return a Canvas object (group) of the contents
    show: func(viewParent) {
        # loop over children
    }

};

var GUIMenuBar = {
    aboutToShow: func() {

    },

    # return a Canvas object (group) of the contents
    show: func(viewParent) {

    }

};

# this is the callback function invoked by C++ to build Nasal peers
# for the C++ menu objects.
var _createMenuObject = func(type)
{
    if (type == "menubar") {

    } else if (type == "menuitem") {

    } else if (type == "seperator") {

    } else if (type == "menu") {
        # do we need to distuinguish submenus here:
    }

    return nil;
}

logprint(LOG_INFO, "Did load GUI menubar");
