// turn_indicator.cxx - an electric-powered turn indicator.
// Written by David Megginson, started 2003.
//
// This file is in the Public Domain and comes with no warranty.

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include <simgear/compiler.h>
#include <iostream>
#include <string>
#include <sstream>

#include "turn_indicator.hxx"
#include <Main/fg_props.hxx>
#include <Main/util.hxx>

using std::string;

// Use a bigger number to be more responsive, or a smaller number
// to be more sluggish.
#define RESPONSIVENESS 0.5


TurnIndicator::TurnIndicator ( SGPropertyNode *node) :
    _last_rate(0)
{
    if( !node->getBoolValue("new-default-power-path", 0) ){
       setDefaultPowerSupplyPath("/systems/electrical/outputs/turn-coordinator");
    }
    readConfig(node, "turn-indicator");
}

TurnIndicator::~TurnIndicator ()
{
}

void
TurnIndicator::init ()
{
    string branch = nodePath();

    SGPropertyNode *node = fgGetNode(branch, true );
    _roll_rate_node = fgGetNode("/orientation/roll-rate-degps", true);
    _yaw_rate_node = fgGetNode("/orientation/yaw-rate-degps", true);
    _rate_out_node = node->getChild("indicated-turn-rate", 0, true);
    _spin_node = node->getChild("spin", 0, true);

    initServicePowerProperties(node);

    reinit();
}

void
TurnIndicator::reinit ()
{
    _last_rate = 0;
    _gyro.reinit();
}

void
TurnIndicator::update (double dt)
{
                                // Get the spin from the gyro
    _gyro.set_power_norm(isServiceableAndPowered());
    _gyro.update(dt);
    double spin = _gyro.get_spin_norm();
    _spin_node->setDoubleValue( spin );

                                // Calculate the indicated rate
    double factor = 1.0 - ((1.0 - spin) * (1.0 - spin) * (1.0 - spin));
    double rate = ((_roll_rate_node->getDoubleValue() / 20.0) +
                   (_yaw_rate_node->getDoubleValue() / 3.0));

                                // Clamp the rate
    if (rate < -2.5)
        rate = -2.5;
    else if (rate > 2.5)
        rate = 2.5;

                                // Lag left, based on gyro spin
    rate = -2.5 + (factor * (rate + 2.5));
    rate = fgGetLowPass(_last_rate, rate, dt*RESPONSIVENESS);
    _last_rate = rate;
    
                                // Publish the indicated rate
    _rate_out_node->setDoubleValue(rate);
}

// end of turn_indicator.cxx
