/*
 * SPDX-FileName: AITanker.hxx
 * SPDX-FileComment: Tanker specific code isolated from AI Aircraft code, based on David Culp's AIModel code
 * SPDX-FileCopyrightText: by Thomas Foerster, started June 2007
 * SPDX-FileContributor: Original code written by David Culp, started October 2003 - davidculp2@comcast.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string_view>

#include "AIAircraft.hxx"


/**
 * An AI tanker for air-air refueling.
 *
 * This class is just a refactoring of the AA refueling related code in FGAIAircraft. The idea
 * is to have a clean generic AIAircraft class without any special functionality. In your
 * scenario specification use 'tanker' as the scenario type to use this class.
 * 
 * @author Thomas F�ster <t.foerster@biologie.hu-berlin.de>
*/

class FGAITanker : public FGAIAircraft
{
public:
    explicit FGAITanker(FGAISchedule* ref = 0);
    virtual ~FGAITanker() = default;

    std::string_view getTypeString() const override { return "tanker"; }
    void readFromScenario(SGPropertyNode* scFileNode) override;
    void bind() override;

    void setTACANChannelID(const std::string& id);

private:
    std::string TACAN_channel_id; // The TACAN channel of this tanker
    bool contact = false;         // set if this tanker is within fuelling range

    virtual void Run(double dt);
    void update(double dt) override;
};
