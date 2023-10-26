/*
 * SPDX-FileName: AISwiftAircraft.h
 * SPDX-FileComment: Derived AIBase class for swift aircraft
 * SPDX-FileCopyrightText: Written by Lars Toenning <dev@ltoenning.de> started on April 2020
 * SPDX-FileContributor: Copyright (C) 2020 - swift Project Community / Contributors (http://swift-project.org/)
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <string_view>
#include <utility>

#include "AIBaseAircraft.hxx"


struct AircraftTransponder {
    AircraftTransponder(std::string callsign, int code, bool modeC, bool ident)
        : callsign(std::move(callsign)), code(code), modeC(modeC), ident(ident)
    {
    }

    std::string callsign;
    int code;
    bool modeC;
    bool ident;
};

struct AircraftSurfaces {
    AircraftSurfaces(std::string callsign, double gear, double flaps, double spoilers, double speedBrake, double slats, double wingSweeps,
                     double thrust, double elevator, double rudder, double aileron, bool landingLight, bool taxiLight, bool beaconLight,
                     bool strobeLight, bool navLight, int lightPattern)
        : callsign(std::move(callsign)), gear(gear), flaps(flaps), spoilers(spoilers), speedBrake(speedBrake), slats(slats), wingSweeps(wingSweeps),
          thrust(thrust), elevator(elevator), rudder(rudder), aileron(aileron), landingLight(landingLight), taxiLight(taxiLight), beaconLight(beaconLight),
          strobeLight(strobeLight), navLight(navLight), lightPattern(lightPattern) {}

    std::string callsign;
    double gear;
    double flaps;
    double spoilers;
    double speedBrake;
    double slats;
    double wingSweeps;
    double thrust;
    double elevator;
    double rudder;
    double aileron;
    bool landingLight;
    bool taxiLight;
    bool beaconLight;
    bool strobeLight;
    bool navLight;
    int lightPattern;
};

class FGAISwiftAircraft : public FGAIBaseAircraft
{
public:
    FGAISwiftAircraft(const std::string& callsign, const std::string& modelString);
    virtual ~FGAISwiftAircraft() = default;

    std::string_view getTypeString() const override { return "swift"; }
    void update(double dt) override;

    void updatePosition(const SGGeod& position, const SGVec3d& orientation, double groundspeed, bool initPos);
    double getGroundElevation(const SGGeod& pos) const;
    void initProps();
    void setPlaneSurface(const AircraftSurfaces& surfaces);
    void setPlaneTransponder(const AircraftTransponder& transponder);

private:
    bool m_initPos = false;
    // Property Nodes for transponder and parts
    SGPropertyNode_ptr m_transponderCodeNode;
    SGPropertyNode_ptr m_transponderCModeNode;
    SGPropertyNode_ptr m_transponderIdentNode;
};
