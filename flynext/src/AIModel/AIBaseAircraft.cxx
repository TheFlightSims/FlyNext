/*
 * SPDX-FileName: AIBaseAircraft.cxx
 * SPDX-FileComment: abstract base class for AI aircraft
 * SPDX-FileCopyrightText: Written by Stuart Buchanan, started August 2002
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "AIBaseAircraft.hxx"

#include <Main/globals.hxx>

FGAIBaseAircraft::FGAIBaseAircraft(object_type ot) : FGAIBase(ot, false),
                                                     m_gearPos(0.0),
                                                     m_flapsPos(0.0),
                                                     m_spoilerPos(0.0),
                                                     m_speedbrakePos(0.0),
                                                     m_beaconLight(false),
                                                     m_cabinLight(false),
                                                     m_landingLight(false),
                                                     m_navLight(false),
                                                     m_strobeLight(false),
                                                     m_taxiLight(false)
{
}

void FGAIBaseAircraft::bind()
{
    FGAIBase::bind();

    // All gear positions are linked for simplicity
    tie("gear/gear[0]/position-norm", SGRawValuePointer<double>(&m_gearPos));
    tie("gear/gear[1]/position-norm", SGRawValuePointer<double>(&m_gearPos));
    tie("gear/gear[2]/position-norm", SGRawValuePointer<double>(&m_gearPos));
    tie("gear/gear[3]/position-norm", SGRawValuePointer<double>(&m_gearPos));
    tie("gear/gear[4]/position-norm", SGRawValuePointer<double>(&m_gearPos));
    tie("gear/gear[5]/position-norm", SGRawValuePointer<double>(&m_gearPos));

    tie("surface-positions/flap-pos-norm",
        SGRawValueMethods<FGAIBaseAircraft, double>(*this,
                                                    &FGAIBaseAircraft::FlapsPos,
                                                    &FGAIBaseAircraft::FlapsPos));

    tie("surface-positions/spoiler-pos-norm",
        SGRawValueMethods<FGAIBaseAircraft, double>(*this,
                                                    &FGAIBaseAircraft::SpoilerPos,
                                                    &FGAIBaseAircraft::SpoilerPos));

    tie("surface-positions/speedbrake-pos-norm",
        SGRawValueMethods<FGAIBaseAircraft, double>(*this,
                                                    &FGAIBaseAircraft::SpeedBrakePos,
                                                    &FGAIBaseAircraft::SpeedBrakePos));

    tie("controls/lighting/beacon",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::BeaconLight,
                                                  &FGAIBaseAircraft::BeaconLight));

    tie("controls/lighting/cabin-lights",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::CabinLight,
                                                  &FGAIBaseAircraft::CabinLight));

    tie("controls/lighting/landing-lights",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::LandingLight,
                                                  &FGAIBaseAircraft::LandingLight));

    tie("controls/lighting/nav-lights",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::NavLight,
                                                  &FGAIBaseAircraft::NavLight));

    tie("controls/lighting/strobe",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::StrobeLight,
                                                  &FGAIBaseAircraft::StrobeLight));

    tie("controls/lighting/taxi-lights",
        SGRawValueMethods<FGAIBaseAircraft, bool>(*this,
                                                  &FGAIBaseAircraft::TaxiLight,
                                                  &FGAIBaseAircraft::TaxiLight));
}
