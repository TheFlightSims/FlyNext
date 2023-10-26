/*
 * SPDX-FileName: AIThermal.hxx
 * SPDX-FileComment: AIBase-derived class creates an AI thermal. An attempt to refine the thermal shape and behaviour by WooT 2009
 * SPDX-FileCopyrightText: Copyright (C) 2009 Patrice Poly ( WooT )
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string_view>

#include "AIBase.hxx"
#include "AIManager.hxx"

#include <string>


class FGAIThermal : public FGAIBase
{
public:
    FGAIThermal();
    virtual ~FGAIThermal() = default;

    std::string_view getTypeString(void) const override { return "thermal"; }
    void readFromScenario(SGPropertyNode* scFileNode) override;

    bool init(ModelSearchOrder searchOrder) override;
    void bind() override;
    void update(double dt) override;

    inline void setMaxStrength(double s) { max_strength = s; };
    inline void setDiameter(double d) { diameter = d; };
    inline void setHeight(double h) { height = h; };
    inline void setMaxUpdraft(double lift) { v_up_max = lift; };
    inline void setMinUpdraft(double sink) { v_up_min = sink; };
    inline void setR_up_frac(double r) { r_up_frac = r; };

    inline double getStrength() const { return strength; };
    inline double getDiameter() const { return diameter; };
    inline double getHeight() const { return height; };
    inline double getV_up_max() const { return v_up_max; };
    inline double getV_up_min() const { return v_up_min; };
    inline double getR_up_frac() const { return r_up_frac; };

    void getGroundElev(double dt);

private:
    void Run(double dt);

    double get_strength_fac(double alt_frac);
    double max_strength{0.0};
    double strength{0.0};
    double diameter{0.0};
    double height{0.0};
    double factor{0.0};
    double alt_rel{0.0};
    double alt{0.0};
    double v_up_max{0.0}; //max updraft at the user altitude and time
    double v_up_min{0.0}; //min updraft at the user altitude and time, this is a negative number
    double r_up_frac{0.9}; //the relative radius of the thermal where we have updraft, between 0 an 1
    double cycle_timer{0.0};
    double dt_count{0.0};
    double time{0.0};
    double xx{0.0};
    double ground_elev_ft{0.0}; // ground level in ft

    bool do_agl_calc = false;
    bool is_forming = false;
    bool is_formed = false;
    bool is_dying = false;
    bool is_dead = false;

    SGPropertyNode_ptr _surface_wind_from_deg_node;
    SGPropertyNode_ptr _surface_wind_speed_node;
    SGPropertyNode_ptr _aloft_wind_from_deg_node;
    SGPropertyNode_ptr _aloft_wind_speed_node;
};
