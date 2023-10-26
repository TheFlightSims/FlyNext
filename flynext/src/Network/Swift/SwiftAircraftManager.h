/*
 * Manger class for aircraft generated by swift
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <AIModel/AIManager.hxx>
#include <AIModel/AISwiftAircraft.h>
#include <Scenery/scenery.hxx>

#include <unordered_map>
#include <vector>

#ifndef FGSWIFTAIRCRAFTMANAGER_H
#define FGSWIFTAIRCRAFTMANAGER_H

struct SwiftPlaneUpdate {
    std::string callsign;
    SGGeod position;
    SGVec3d orientation;
    double groundspeed;
    bool onGround;
};

class FGSwiftAircraftManager
{
    using FGAISwiftAircraftPtr = SGSharedPtr<FGAISwiftAircraft>;

public:
    FGSwiftAircraftManager();
    ~FGSwiftAircraftManager();
    bool addPlane(const std::string& callsign, const std::string& modelString);
    void updatePlanes(const std::vector<SwiftPlaneUpdate>& updates);
    void getRemoteAircraftData(std::vector<std::string>& callsigns, std::vector<double>& latitudesDeg, std::vector<double>& longitudesDeg,
                               std::vector<double>& elevationsM, std::vector<double>& verticalOffsets) const;
    void removePlane(const std::string& callsign);
    void removeAllPlanes();
    void setPlanesTransponders(const std::vector<AircraftTransponder>& transponders);
    double getElevationAtPosition(const std::string& callsign, const SGGeod& pos) const;
    bool isInitialized() const;
    void setPlanesSurfaces(const std::vector<AircraftSurfaces>& surfaces);

private:
    std::unordered_map<std::string, FGAISwiftAircraftPtr> aircraftByCallsign;
    bool m_initialized = false;
};
#endif