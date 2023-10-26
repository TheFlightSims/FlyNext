/*
 * groundreactions.hxx
 * caclulate ground reactions based on ground properties and weather scenarios
 *
 * SPDX-FileCopyrightText: (C) 2023 Erik Hofman <erik@ehof,am.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */


#include <cmath>

#include <simgear/bvh/BVHMaterial.hxx>
#include <simgear/math/sg_random.hxx>
#include <Main/fg_props.hxx>

#include "groundreactions.hxx"

GroundReactions::GroundReactions()
{
    precipitation = fgGetNode("/environment/rain-norm", true);
    temperature = fgGetNode("/environment/temperature-degc",true);
    dew_point = fgGetNode("/environment/dewpoint-degc", true);
    ground_wind = fgGetNode("/environment/config/boundary/entry[0]/wind-speed-kt",true);
    turbulence_gain = fgGetNode("/environment/turbulence/magnitude-norm",true);
    turbulence_rate = fgGetNode("/environment/turbulence/rate-hz",true);
    turbulence_model = fgGetNode("/environment/params/jsbsim-turbulence-model",true);

    wind_from_north= fgGetNode("/environment/wind-from-north-fps",true);
    wind_from_east = fgGetNode("/environment/wind-from-east-fps" ,true);
    wind_from_down = fgGetNode("/environment/wind-from-down-fps" ,true);
}

bool
GroundReactions::update(simgear::BVHMaterial const*& material)
{
    if (material)
    {
        float friction_factor = (*material).get_friction_factor();

        // TODO: Moist Mud, Wed Mud, Frozen Mud
        // Traction coefficient factors for tires vs. dry asphalt:
        // Dry Asphalt   1.0             Wet Asphalt     0.75
        // Dry Ice/Snow  0.375           Wet Ice         0.125
        wet = (precipitation->getDoubleValue() > 0.0);
        snow = (wet && temperature->getDoubleValue() <= 0.0);
        water_body = (*material).solid_is_prop();
        solid = (*material).get_solid();
        frozen = (water_body && solid);
        if (frozen) // on ice
        {
            bumpiness = 0.1f;
            if (wet)
            {
                if (!snow) // Wet Ice
                {
                    roling_friction_factor = 0.05f;
                    static_friction_factor = 0.125f*friction_factor;
                }
                else // snow
                {
                    roling_friction_factor = 0.15f;
                    static_friction_factor = 0.375f*friction_factor;
                }
            }
            else // Dry Ice
            {
                roling_friction_factor = 0.05f;
                static_friction_factor = 0.375f*friction_factor;
            }
            pressure = (*material).get_load_resistance()*1000;
        }
        else // not on ice
        {
            roling_friction_factor = (*material).get_rolling_friction()/0.02f;
            bumpiness = (*material).get_bumpiness();
            static_friction_factor = friction_factor;
            if (wet) static_friction_factor *= 0.75f;
            pressure = (*material).get_load_resistance();
        }
        return true;
    }
    return false;
}

void
GroundReactions::setPosition(const double pt[3])
{
    pos[0] = pt[0];
    pos[1] = pt[1];
    pos[2] = pt[2];
}

float
GroundReactions::getGroundDisplacement()
{
    static const float maxGroundBumpAmplitude = 0.4;

    if (bumpiness < 0.001f) return 0.0f;

    float s = sinf(heading);
    float c = cosf(heading);
    float px = pos[0]*0.1f;
    float py = pos[1]*0.1f;
    px -= floor(px);
    py -= floor(py);
    px *= 1000.0f;
    py *= 1000.0f;

    int x = c*px - s*py;
    int y = s*px + c*py;

    // TODO: differentiate between land/water and
    //       implement hydrodynamcs

//  pc_init(x+y);
    return pc_map_rand(x, y, 1) * bumpiness*maxGroundBumpAmplitude;
}

