/*
 * SPDX-FileName: AITanker.cxx
 * SPDX-FileComment: Tanker specific code isolated from AI Aircraft code, based on David Culp's AIModel code
 * SPDX-FileCopyrightText: by Thomas Foerster, started June 2007
 * SPDX-FileContributor: Original code written by David Culp, started October 2003 - davidculp2@comcast.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "AITanker.hxx"


FGAITanker::FGAITanker(FGAISchedule* ref) : FGAIAircraft(ref)
{
}

void FGAITanker::readFromScenario(SGPropertyNode* scFileNode)
{
    if (!scFileNode)
        return;

    FGAIAircraft::readFromScenario(scFileNode);
    setTACANChannelID(scFileNode->getStringValue("TACAN-channel-ID", ""));
    setName(scFileNode->getStringValue("name", "Tanker"));
}

void FGAITanker::bind()
{
    FGAIAircraft::bind();

    tie("refuel/contact", SGRawValuePointer<bool>(&contact));
    tie("position/altitude-agl-ft", SGRawValuePointer<double>(&altitude_agl_ft));

    props->setStringValue("navaids/tacan/channel-ID", TACAN_channel_id.c_str());
    props->setStringValue("name", _name.c_str());
    props->setBoolValue("tanker", true);
}

void FGAITanker::setTACANChannelID(const std::string& id)
{
    TACAN_channel_id = id;
}

void FGAITanker::Run(double dt)
{
    double start = pos.getElevationFt() + 1000.0;
    altitude_agl_ft = _getAltitudeAGL(pos, start);

    //###########################//
    // do calculations for radar //
    //###########################//
    double range_ft2 = UpdateRadar(manager);

    // check if radar contact
    if ((range_ft2 < 250.0 * 250.0) && (y_shift > 0.0) && (elevation > 0.0)) {
        contact = true;
    } else {
        contact = false;
    }
}

void FGAITanker::update(double dt)
{
    FGAIAircraft::update(dt);
    Run(dt);
    Transform();
}
