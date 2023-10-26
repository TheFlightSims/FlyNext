/*
 * SPDX-FileName: sidstar.cxx
 * SPDX-FileComment: Code to manage departure / arrival procedures
 * SPDX-FileCopyrightText: Written by Durk Talsma, started March 2009
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <iostream>
#include <stdlib.h>

#include <simgear/props/props.hxx>
#include <simgear/props/props_io.hxx>

#include <AIModel/AIFlightPlan.hxx>
#include <Airports/airport.hxx>

#include "sidstar.hxx"


FGSidStar::FGSidStar(FGAirport* ap) : id{ap->getId()}
{
    initialized = false;
}


FGSidStar::FGSidStar(const FGSidStar& other)
{
    std::cerr << "TODO" << std::endl;
}

void FGSidStar::load(SGPath filename)
{
    SGPropertyNode root;

    try {
        readProperties(filename, &root);
    } catch (const sg_exception&) {
        SG_LOG(SG_GENERAL, SG_ALERT, "Error reading AI flight plan: " << filename);
        // cout << path.str() << std::endl;
        return;
    }

    SGPropertyNode* node = root.getNode("SIDS");
    FGAIFlightPlan* fp;

    for (int i = 0; i < node->nChildren(); i++) {
        fp = new FGAIFlightPlan;
        SGPropertyNode* fpl_node = node->getChild(i);
        std::string name = fpl_node->getStringValue("name", "END");
        std::string runway = fpl_node->getStringValue("runway", "27");
        //std::cerr << "Runway = " << runway << std::endl;

        fp->setName(name);
        SGPropertyNode* wpts_node = fpl_node->getNode("wpts");

        for (int j = 0; j < wpts_node->nChildren(); j++) {
            FGAIWaypoint* wpt = new FGAIWaypoint;
            SGPropertyNode* wpt_node = wpts_node->getChild(j);
            //std::cerr << "Reading waypoint " << j << wpt_node->getStringValue("name", "END") << std::endl;

            wpt->setName(wpt_node->getStringValue("name", "END"));
            wpt->setLatitude(wpt_node->getDoubleValue("lat", 0));
            wpt->setLongitude(wpt_node->getDoubleValue("lon", 0));
            wpt->setAltitude(wpt_node->getDoubleValue("alt", 0));
            wpt->setSpeed(wpt_node->getDoubleValue("ktas", 0));
            wpt->setCrossat(wpt_node->getDoubleValue("crossat", -10000));
            wpt->setGear_down(wpt_node->getBoolValue("gear-down", false));
            wpt->setFlaps(wpt_node->getBoolValue("flaps-down", false) ? 0.5 : 0.0); //  We'll assume all SIDS only require half-flaps
            wpt->setOn_ground(wpt_node->getBoolValue("on-ground", false));
            wpt->setTime_sec(wpt_node->getDoubleValue("time-sec", 0));
            wpt->setTime(wpt_node->getStringValue("time", ""));

            if (wpt->contains("END"))
                wpt->setFinished(true);
            else
                wpt->setFinished(false);

            //
            fp->addWaypoint(wpt);
        }
        data[runway].push_back(fp);
        //std::cerr << "Runway = " << runway << std::endl;
    }

    //wpt_iterator = waypoints.begin();
    //cout << waypoints.size() << " waypoints read." << std::endl;
}


FGAIFlightPlan* FGSidStar::getBest(const std::string& activeRunway, double heading)
{
    //std::cerr << "Getting best procedure for " << activeRunway << std::endl;
    for (FlightPlanVecIterator i = data[activeRunway].begin(); i != data[activeRunway].end(); i++) {
        //std::cerr << (*i)->getName() << std::endl;
    }
    int size = data[activeRunway].size();
    //std::cerr << "size is " << size << std::endl;
    if (size) {
        return data[activeRunway][(rand() % size)];
    } else {
        return 0;
    }
}
