// attitude_indicator_electric.hxx - an electrically-powered attitude indicator.
// Written by David Megginson, started 2002.
// Ported to Electric by Benedikt Wolf 2023
//
// This file is in the Public Domain and comes with no warranty.

// TODO:
// - better spin-up

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include <simgear/compiler.h>

#include <iostream>
#include <string>
#include <sstream>

#include <cmath>    // fabs()

#include "attitude_indicator_electric.hxx"
#include <Main/fg_props.hxx>
#include <Main/util.hxx>

using std::string;

AttitudeIndicatorElectric::AttitudeIndicatorElectric ( SGPropertyNode *node )
:
spin_thresh(0.8),
max_roll_error(40.0),
max_pitch_error(12.0)
{
    readConfig(node, "attitude-indicator-electric");
}

AttitudeIndicatorElectric::~AttitudeIndicatorElectric ()
{
}

void
AttitudeIndicatorElectric::init ()
{
	string branch = nodePath();

	SGPropertyNode *node    = fgGetNode(branch, true );
	SGPropertyNode *n;

	_pitch_in_node = fgGetNode("/orientation/pitch-deg", true);
	_roll_in_node = fgGetNode("/orientation/roll-deg", true);
	SGPropertyNode *cnode = node->getChild("config", 0, true);
	_tumble_flag_node = cnode->getChild("tumble-flag", 0, true);
	_caged_node = node->getChild("caged-flag", 0, true);
	_tumble_node = node->getChild("tumble-norm", 0, true);
	if( ( n = cnode->getChild("spin-thresh", 0, false ) ) != NULL )
		spin_thresh = n->getDoubleValue();
	if( ( n = cnode->getChild("max-roll-error-deg", 0, false ) ) != NULL )
		max_roll_error = n->getDoubleValue();
	if( ( n = cnode->getChild("max-pitch-error-deg", 0, false ) ) != NULL )
		max_pitch_error = n->getDoubleValue();
	_pitch_int_node = node->getChild("internal-pitch-deg", 0, true);
	_roll_int_node = node->getChild("internal-roll-deg", 0, true);
	_pitch_out_node = node->getChild("indicated-pitch-deg", 0, true);
	_roll_out_node = node->getChild("indicated-roll-deg", 0, true);
	_off_node         = node->getChild("off-flag", 0, true);
	_spin_node = node->getChild("spin", 0, true);

	initServicePowerProperties(node);

	reinit();
}

void
AttitudeIndicatorElectric::reinit ()
{
	_roll_int_node->setDoubleValue(0.0);
	_pitch_int_node->setDoubleValue(0.0);
	_gyro.reinit();
}

void
AttitudeIndicatorElectric::update (double dt)
{
	// If it's caged, it doesn't indicate
	if (_caged_node->getBoolValue()) {
		_roll_int_node->setDoubleValue(0.0);
		_pitch_int_node->setDoubleValue(0.0);
		return;
	}

	// Get the spin from the gyro
	_gyro.set_power_norm(isServiceableAndPowered());
	_gyro.update(dt);
	double spin = _gyro.get_spin_norm();
	_spin_node->setDoubleValue( spin );
	
	_off_node->setBoolValue( !( isServiceableAndPowered() && spin >= 0.25 ) );

	// Calculate the responsiveness
	double responsiveness = spin * spin * spin * spin * spin * spin;

	// Get the indicated roll and pitch
	double roll = _roll_in_node->getDoubleValue();
	double pitch = _pitch_in_node->getDoubleValue();

	// Calculate the tumble for the
	// next pass.
	if (_tumble_flag_node->getBoolValue()) {
		double tumble = _tumble_node->getDoubleValue();
		if (fabs(roll) > 45.0) {
			double target = (fabs(roll) - 45.0) / 45.0;
			target *= target;   // exponential past +-45 degrees
			if (roll < 0)
				target = -target;

			if (fabs(target) > fabs(tumble))
				tumble = target;

			if (tumble > 1.0)
				tumble = 1.0;
			else if (tumble < -1.0)
				tumble = -1.0;
		}
		// Reerect in 5 minutes
		double step = dt/300.0;
		if (tumble < -step)
			tumble += step;
		else if (tumble > step)
			tumble -= step;

		roll += tumble * 45;
		_tumble_node->setDoubleValue(tumble);
	}

	roll = fgGetLowPass(_roll_int_node->getDoubleValue(), roll,
				  responsiveness);
	pitch = fgGetLowPass(_pitch_int_node->getDoubleValue(), pitch,
				   responsiveness);

	// Assign the new values
	_roll_int_node->setDoubleValue(roll);
	_pitch_int_node->setDoubleValue(pitch);

	// add in a gyro underspin "error" if gyro is spinning too slowly
	double roll_error;
	double pitch_error;
	if ( spin <= spin_thresh ) {
		double roll_error_factor = (spin_thresh - spin) / spin_thresh;
		double pitch_error_factor = (spin_thresh - spin) / spin_thresh;
		roll_error = roll_error_factor * roll_error_factor * max_roll_error;
		pitch_error = pitch_error_factor * pitch_error_factor * max_pitch_error;
	} else {
		roll_error = 0.0;
		pitch_error = 0.0;
	}

	_roll_out_node->setDoubleValue(roll + roll_error);
	_pitch_out_node->setDoubleValue(pitch + pitch_error);
}

// end of attitude_indicator_electric.cxx
