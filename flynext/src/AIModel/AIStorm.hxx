/*
 * SPDX-FileName: AIStorm.hxx
 * SPDX-FileComment: AIBase derived class creates an AI thunderstorm
 * SPDX-FileCopyrightText: Copyright (C) 2004  David P. Culp - davidculp2@comcast.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <string_view>

#include "AIBase.hxx"
#include "AIManager.hxx"


class FGAIStorm : public FGAIBase
{
public:
    FGAIStorm();
    virtual ~FGAIStorm() = default;

    std::string_view getTypeString(void) const override { return "thunderstorm"; }
    void readFromScenario(SGPropertyNode* scFileNode) override;
    void update(double dt) override;

    inline void setStrengthNorm(double s) { strength_norm = s; };
    inline void setDiameter(double d) { diameter = d; };
    inline void setHeight(double h) { height = h; };
    inline double getStrengthNorm() const { return strength_norm; };
    inline double getDiameter() const { return diameter; };
    inline double getHeight() const { return height; };

private:
    double diameter = 0.0;      // diameter of turbulence zone, in nm
    double height = 0.0;        // top of turbulence zone, in feet MSL
    double strength_norm = 0.0; // strength of turbulence

    void Run(double dt);

    // lightning stuff
    double delay;        // average time (sec) between lightning flashes
    int subflashes;      // number of subflashes per flash
    double random_delay; // delay +/- random number
    double timer;
    SGPropertyNode_ptr flash_node;
    int flashed;   // number of subflashes already done this flash
    bool flashing; // true if currently flashing;
    int subflash_array[8];
    int subflash_index;

    // turbulence stuff
    SGPropertyNode_ptr turb_mag_node;
    SGPropertyNode_ptr turb_rate_node;
};
