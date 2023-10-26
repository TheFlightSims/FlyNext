/*
 * SPDX-FileName: AIEscort.hxx
 * SPDX-FileCopyrightText: Written by Vivian Meazza, started August 2009 - vivian.meazza at lineone.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <list>
#include <string>
#include <string_view>

#include <simgear/compiler.h>

#include "AIBase.hxx"

#include "AIShip.hxx"

#include "AIBase.hxx"
#include "AIManager.hxx"


class FGAIEscort : public FGAIShip
{
public:
    FGAIEscort();
    virtual ~FGAIEscort() = default;

    std::string_view getTypeString(void) const override { return "escort"; }
    void readFromScenario(SGPropertyNode* scFileNode) override;

    bool init(ModelSearchOrder searchOrder) override;
    void bind() override;
    void reinit() override;
    void update(double dt) override;

private:
    void setStnRange(double r);
    void setStnBrg(double y);
    void setStationSpeed();
    void setStnLimit(double l);
    void setStnAngleLimit(double l);
    void setStnSpeed(double s);
    void setStnHtFt(double h);
    void setStnPatrol(bool p);
    void setStnDegTrue(bool t);
    void setParent();

    void setMaxSpeed(double m);
    void setUpdateInterval(double i);

    void RunEscort(double dt);

    bool getGroundElev(SGGeod inpos);

    SGVec3d getCartHitchPosAt(const SGVec3d& off) const;

    void calcRangeBearing(double lat, double lon, double lat2, double lon2,
                          double& range, double& bearing) const;
    double calcTrueBearingDeg(double bearing, double heading);

    SGGeod _selectedpos;
    SGGeod _tgtpos;

    bool _solid = true; // if true ground is solid for FDMs
    double _tgtrange = 0.0;
    double _tgtbrg = 0.0;
    double _ht_agl_ft = 0.0;
    double _relbrg = 0.0;
    double _parent_speed = 0.0;
    double _parent_hdg = 0.0;
    double _interval = 0.0;

    double _stn_relbrg = 0.0;
    double _stn_truebrg = 0.0;
    double _stn_brg = 0.0;
    double _stn_range = 0.0;
    double _stn_height = 0.0;
    double _stn_speed = 0.0;
    double _stn_angle_limit = 0.0;
    double _stn_limit = 0.0;

    bool _MPControl = false;
    bool _patrol = false;
    bool _stn_deg_true = false;
};
