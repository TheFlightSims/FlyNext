/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <simgear/compiler.h>
#include <simgear/structure/SGSharedPtr.hxx>

#include <Navaids/positioned.hxx>


class FGTaxiNode : public FGPositioned
{
protected:
    const int m_index;

    const bool isOnRunway;
    const int holdType;
    bool m_isPushback;

public:
    FGTaxiNode(FGPositioned::Type ty, int index, const SGGeod& pos, bool aOnRunway, int aHoldType, const std::string& ident = {});
    virtual ~FGTaxiNode() = default;

    void setElevation(double val);

    double getElevationM();
    double getElevationFt();

    int getIndex() const;

    int getHoldPointType() const { return holdType; };
    bool getIsOnRunway() const { return isOnRunway; };
    bool isPushback() const { return m_isPushback; }

    void setIsPushback();
};
