/*
 * SPDX-License-Identifier: CC0-1.0
 * 
 * heading_indicator_fg.hxx - an electrically-powered fluxgate compass.
 * Written by David Megginson, started 2002.
 * 
 * This file is in the Public Domain and comes with no warranty.
*/

#pragma once

#ifndef __cplusplus
# error This library requires C++
#endif

#include <simgear/props/props.hxx>

#include <Instrumentation/AbstractInstrument.hxx>

#include "gyro.hxx"


/**
 * Model an electrically-powered fluxgate compass
 *
 * Input properties:
 *
 * /instrumentation/"name"/serviceable
 * /instrumentation/"name"/spin
 * /instrumentation/"name"/offset-deg
 * /orientation/heading-deg
 * /systems/electrical/outputs/"name"["number"]
 *
 * Output properties:
 *
 * /instrumentation/"name"/indicated-heading-deg
 */
class HeadingIndicatorFG : public AbstractInstrument
{
public:
    HeadingIndicatorFG ( SGPropertyNode *node );
    HeadingIndicatorFG ();
    virtual ~HeadingIndicatorFG ();

    // Subsystem API.
    //void bind() override;
    void init() override;
    void reinit() override;
    //void unbind() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "heading-indicator-fg"; }

private:
    Gyro _gyro;
    double _last_heading_deg;

    SGPropertyNode_ptr _offset_node;
    SGPropertyNode_ptr _heading_in_node;
    SGPropertyNode_ptr _serviceable_node;
    SGPropertyNode_ptr _heading_out_node;
    SGPropertyNode_ptr _electrical_node;
    SGPropertyNode_ptr _error_node;
    SGPropertyNode_ptr _nav1_error_node;
    SGPropertyNode_ptr _off_node;
    SGPropertyNode_ptr _spin_node;
};
