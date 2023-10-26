/*
 * SPDX-FileName: sidstar.hxx
 * SPDX-FileComment: a class to store and maintain data for SID and STAR procedures
 * SPDX-FileCopyrightText: Written by Durk Talsma, started March 2009
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <simgear/misc/sg_path.hxx>
#include <simgear/xml/easyxml.hxx>

#include <ATC/trafficcontrol.hxx>

#include "airports_fwd.hxx"


class FGSidStar
{
private:
    std::string id;
    bool initialized;
    FlightPlanVecMap data;

public:
    explicit FGSidStar(FGAirport* ap);
    FGSidStar(const FGSidStar& other);

    std::string getId() const { return id; };
    void load(SGPath path);
    FGAIFlightPlan* getBest(const std::string& activeRunway, double heading);
};
