// heading_indicator_fg.cxx - a flux_gate compass.
// Based on the vacuum driven Heading Indicator Written by David Megginson, started 2002.
//
// Written by Vivian Meazza, started 2005.
//
// This file is in the Public Domain and comes with no warranty.

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include <simgear/compiler.h>
#include <iostream>
#include <string>
#include <sstream>

#include <simgear/math/SGMath.hxx>

#include <Main/fg_props.hxx>
#include <Main/util.hxx>

#include "heading_indicator_fg.hxx"

using std::string;

HeadingIndicatorFG::HeadingIndicatorFG ( SGPropertyNode *node )
    :
    _last_heading_deg(0)
{
    readConfig(node, "heading-indicator-fg");
}

HeadingIndicatorFG::HeadingIndicatorFG ()
{
}

HeadingIndicatorFG::~HeadingIndicatorFG ()
{
}

void
HeadingIndicatorFG::init ()
{
    string branch = nodePath();
    
    _heading_in_node = fgGetNode("/orientation/heading-deg", true);

    SGPropertyNode *node = fgGetNode(branch, true );
    if( NULL == (_offset_node = node->getChild("offset-deg", 0, false)) ) {
      _offset_node = node->getChild("offset-deg", 0, true);
      _offset_node->setDoubleValue( -fgGetDouble("/environment/magnetic-variation-deg") );
    }
    _error_node = node->getChild("heading-bug-error-deg", 0, true);
    _nav1_error_node = node->getChild("nav1-course-error-deg", 0, true);
    _heading_out_node = node->getChild("indicated-heading-deg", 0, true);
    _off_node         = node->getChild("off-flag", 0, true);
    _spin_node              = node->getChild("spin", 0, true);

    initServicePowerProperties(node);

    reinit();
}

void
HeadingIndicatorFG::reinit ()
{
    _last_heading_deg = (_heading_in_node->getDoubleValue() +
                         _offset_node->getDoubleValue());
    _gyro.reinit();
}

void
HeadingIndicatorFG::update (double dt)
{
                                // Get the spin from the gyro
	 _gyro.set_power_norm(isServiceableAndPowered());
	_gyro.update(dt);
    double spin = _gyro.get_spin_norm();
    _spin_node->setDoubleValue( spin );

    if ( isServiceableAndPowered() && spin >= 0.25) {
        _off_node->setBoolValue(false);
    } else {
        _off_node->setBoolValue(true);
        return;
    }

                                // No time-based precession	for a flux gate compass
	                            // We just use offset to get the magvar
	double offset = _offset_node->getDoubleValue();
	   
                                // TODO: movement-induced error

                                // Next, calculate the indicated heading,
                                // introducing errors.
    double factor = 100 * (spin * spin * spin * spin * spin * spin);
    double heading = _heading_in_node->getDoubleValue();

                                // Now, we have to get the current
                                // heading and the last heading into
                                // the same range.
    if ((heading - _last_heading_deg) > 180)
        _last_heading_deg += 360;
    if ((heading - _last_heading_deg) < -180)
        _last_heading_deg -= 360;

    heading = fgGetLowPass(_last_heading_deg, heading, dt * factor);
    _last_heading_deg = heading;

	heading += offset;

    if (heading < 0)
        heading += 360;
    if (heading > 360)
        heading -= 360;

    _heading_out_node->setDoubleValue(heading);

	                             // calculate the difference between the indicated heading
	                             // and the selected heading for use with an autopilot
	SGPropertyNode *bnode
        = fgGetNode( "/autopilot/settings/heading-bug-deg", false );
	double diff = 0;
	if ( bnode ){
		diff = bnode->getDoubleValue() - heading;
		if ( diff < -180.0 ) { diff += 360.0; }
		if ( diff > 180.0 ) { diff -= 360.0; }
		_error_node->setDoubleValue( diff );
	}   
	                             // calculate the difference between the indicated heading
	                             // and the selected nav1 radial for use with an autopilot
	SGPropertyNode *nnode
        = fgGetNode( "/instrumentation/nav/radials/selected-deg", true );
	double ndiff = 0;
	if ( nnode ){
		ndiff = nnode->getDoubleValue() - heading;
		if ( ndiff < -180.0 ) { ndiff += 360.0; }
		if ( ndiff > 180.0 ) { ndiff -= 360.0; }
		_nav1_error_node->setDoubleValue( ndiff );
	}   


}


// Register the subsystem.
#if 0
SGSubsystemMgr::InstancedRegistrant<HeadingIndicatorFG> registrantHeadingIndicatorFG(
    SGSubsystemMgr::FDM,
    {{"instrumentation", SGSubsystemMgr::Dependency::HARD}});
#endif

// end of heading_indicator_fg.cxx
