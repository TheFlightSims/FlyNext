/*
 * SPDX-License-Identifier: CC0-1.0
 * 
 * heading_indicator_dg.hxx - an electrically-powered heading indicator
 * Written by David Megginson, started 2002.
 * 
 * This file is in the Public Domain and comes with no warranty.
*/

#pragma once


#include <Instrumentation/AbstractInstrument.hxx>

#include <simgear/math/sg_random.hxx>

#include "gyro.hxx"


/**
 * Model an electrically-powered heading indicator.
 *
 * Input properties:
 *
 * /instrumentation/"name"/serviceable
 * /instrumentation/"name"/spin
 * /instrumentation/"name"/offset-deg
 * /orientation/heading-deg
 * /systems/electrical/outputs/DG
 *
 * Output properties:
 *
 * /instrumentation/"name"/indicated-heading-deg
 * 
 * 
 * Configuration:
 * 
 *   name
 *   number
 *   new-default-power-path: use /systems/electrical/outputs/"name"[ number ] instead of 
 *                           /systems/electrical/outputs/DG as the default power
 *                           supply path (not used when power-supply is set)
 *   power-supply
 *   minimum-supply-volts
 */
class HeadingIndicatorDG : public AbstractInstrument
{
public:
    HeadingIndicatorDG ( SGPropertyNode *node );
    HeadingIndicatorDG ();
    virtual ~HeadingIndicatorDG ();

    // Subsystem API.
    void init() override;
    void reinit() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "heading-indicator-dg"; };

private:
    Gyro _gyro;
    double _last_heading_deg, _last_indicated_heading_dg;

    std::string _powerSupplyPath;

    SGPropertyNode_ptr _offset_node;
    SGPropertyNode_ptr _heading_in_node;
    SGPropertyNode_ptr _serviceable_node;
    SGPropertyNode_ptr _heading_out_node;
    SGPropertyNode_ptr _electrical_node;
    SGPropertyNode_ptr _error_node;
    SGPropertyNode_ptr _nav1_error_node;
    SGPropertyNode_ptr _align_node;
    SGPropertyNode_ptr _yaw_rate_node;
    SGPropertyNode_ptr _heading_bug_error_node;
    SGPropertyNode_ptr _g_node;
    SGPropertyNode_ptr _spin_node;
};
