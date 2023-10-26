/*
 * SPDX-FileName: AIShip.hxx
 * SPDX-FileComment: AIBase derived class creates an AI ship
 * SPDX-FileCopyrightText: Copyright (C) 2003  David P. Culp - davidculp2@comcast.net
 * SPDX-FileContributor: with major amendments and additions by Vivian Meazza, 2004 - 2007
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string_view>

#include <simgear/scene/material/mat.hxx>

#include "AIBase.hxx"
#include "AIFlightPlan.hxx"


class FGAIManager;

class FGAIShip : public FGAIBase
{
public:
    explicit FGAIShip(object_type ot = object_type::otShip);
    virtual ~FGAIShip() = default;

    std::string_view getTypeString(void) const override { return "ship"; }
    void readFromScenario(SGPropertyNode* scFileNode) override;

    bool init(ModelSearchOrder searchOrder) override;
    void bind() override;
    void update(double dt) override;
    void reinit() override;
    double getDefaultModelRadius() override { return 200.0; }

    void setRudder(float r);
    void setRoll(double rl);
    void ProcessFlightPlan(double dt);
    void AccelTo(double speed);
    void PitchTo(double angle);
    void RollTo(double angle);

#if 0
    void YawTo(double angle);
#endif

    void ClimbTo(double altitude);
    void TurnTo(double heading);
    void setCurrName(const std::string&);
    void setNextName(const std::string&);
    void setPrevName(const std::string&);
    void setLeadAngleGain(double g);
    void setLeadAngleLimit(double l);
    void setLeadAngleProp(double p);
    void setRudderConstant(double rc);
    void setSpeedConstant(double sc);
    void setFixedTurnRadius(double ft);
    void setRollFactor(double rf);

    void setTunnel(bool t);
    void setInitialTunnel(bool t);

    void setWPNames();
    void setWPPos();

    double sign(double x);

    bool _hdg_lock = false;
    bool _serviceable = false;
    bool _waiting;
    bool _new_waypoint;
    bool _tunnel, _initial_tunnel;
    bool _restart;

    double _rudder_constant = 0.0;
    double _speed_constant = 0.0;
    double _hdg_constant, _limit;
    double _elevation_ft;
    double _missed_range = 0.0;
    double _tow_angle;
    double _wait_count = 0.0;
    double _missed_count, _wp_range;
    double _dt_count, _next_run;

    FGAIWaypoint* prev = nullptr; // the one behind you
    FGAIWaypoint* curr = nullptr; // the one ahead
    FGAIWaypoint* next = nullptr; // the next plus 1

protected:

private:
    void setRepeat(bool r);
    void setRestart(bool r);
    void setMissed(bool m);

    void setServiceable(bool s);
    void Run(double dt);
    void setStartTime(const std::string&);
    void setUntilTime(const std::string&);
    //void setWPPos();
    void setWPAlt();
    void setXTrackError();

    SGGeod wppos;

    double getRange(double lat, double lon, double lat2, double lon2) const;
    double getCourse(double lat, double lon, double lat2, double lon2) const;
    double getDaySeconds();
    double processTimeString(const std::string& time);

    bool initFlightPlan();
    bool advanceFlightPlan(double elapsed_sec, double day_sec);

    float _rudder = 0.0f;
    float _tgt_rudder = 0.0f;

    double _roll_constant, _roll_factor;
    double _sp_turn_radius_ft = 0.0;
    double _rd_turn_radius_ft = 0.0;
    double _fixed_turn_radius = 0.0;
    double _old_range, _range_rate;
    double _missed_time_sec;
    double _start_sec = 0.0;
    double _day;
    double _lead_angle;
    double _lead_angle_gain = 0.0;
    double _lead_angle_limit = 0.0;
    double _proportion = 0.0;
    double _course = 0.0;
    double _xtrack_error;
    double _curr_alt, _prev_alt;

    std::string _prev_name, _curr_name, _next_name;
    std::string _start_time, _until_time;

    bool _repeat = false;
    bool _fp_init;
    bool _missed;
};
