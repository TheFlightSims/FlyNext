// marker.hxx - 3D Marker pins in FlightGear
// Copyright (C) 2022 Tobias Dammers
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

#pragma once

namespace osgText {
    class String;
}

namespace osg {
    class Node;
    class Vec4f;
}

osg::Node* fgCreateMarkerNode(const osgText::String&, float font_size, float pin_height, float tip_height, const osg::Vec4f& color);
