/*
 * groundreactions.hxx
 * caclulate ground reactions based on ground properties and weather scenarios
 *
 * SPDX-FileCopyrightText: (C) 2023 Erik Hofman <erik@ehof,am.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */


#pragma once

# include <float.h>

#include <simgear/math/SGMath.hxx>

class GroundReactions
{
public:
    GroundReactions();
    ~GroundReactions() = default;

    // call once before processing all gear locations
    bool update(simgear::BVHMaterial const*& material);

    // first set the gear position in local frame
    void setPosition(const double pt[3]);

    // and the true heading in radians
    inline void setHeading(float h) { heading = h; };

    // then get the bum height at that position
    float getGroundDisplacement();

   inline float getPressure() { return pressure; }
   inline float getBumpiness() { return bumpiness; }
   inline float getStaticFrictionFactor() { return static_friction_factor; }
   inline float getRolingFrictionFactor() { return roling_friction_factor; }

   inline bool getSolid() { return solid; }

private:
    SGPropertyNode_ptr precipitation;
    SGPropertyNode_ptr temperature;
    SGPropertyNode_ptr dew_point;
    SGPropertyNode_ptr ground_wind;
    SGPropertyNode_ptr turbulence_gain;
    SGPropertyNode_ptr turbulence_rate;
    SGPropertyNode_ptr turbulence_model;

    SGPropertyNode_ptr wind_from_north;
    SGPropertyNode_ptr wind_from_east;
    SGPropertyNode_ptr wind_from_down;

    SGVec3d pos;
    float heading;

    float random = 0.0f;
    float bumpiness = 0.0f;
    float static_friction_factor = 1.0f;
    float roling_friction_factor = 1.0f;
    float pressure = FLT_MAX;

    bool wet = false;		// is it wet?
    bool snow = false;		// is it snowed over?
    bool solid = true;		// is it solid ground or water?
    bool water_body = false;	// if water, can it ge frozen over?
    bool frozen = false;	// is it actuall frozen?
    bool mud = false;		// is it mud?
};

