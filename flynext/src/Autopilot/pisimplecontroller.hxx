// pisimplecontroller.hxx - implementation of a simple PI controller
//
// Written by Torsten Dreyer
// Based heavily on work created by Curtis Olson, started January 2004.
//
// Copyright (C) 2004  Curtis L. Olson  - http://www.flightgear.org/~curt
// Copyright (C) 2010  Torsten Dreyer - Torsten (at) t3r (dot) de
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
#ifndef __PISIMPLECONTROLLER_HXX
#define __PISIMPLECONTROLLER_HXX 1

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include "analogcomponent.hxx"

#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>

namespace FGXMLAutopilot {

/**
 * A simplistic P [ + I ] PI controller
 */
class PISimpleController : public AnalogComponent
{

private:
    // proportional component data
    simgear::ValueList _Kp;

    // integral component data
    simgear::ValueList _Ki;
    double _int_sum;

protected:
    virtual bool configure( SGPropertyNode& cfg_node,
                            const std::string& cfg_name,
                            SGPropertyNode& prop_root );

public:
    PISimpleController();
    ~PISimpleController() {}

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "pi-simple-controller"; }

    void update( bool firstTime, double dt );
};

}

#endif
