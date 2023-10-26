/*
 * SPDX-FileName: AINotifications.hxx
 * SPDX-FileComment: Emesary notifications for AI system
 * SPDX-FileCopyrightText: Richard Harrison; April 2020.
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <simgear/emesary/Emesary.hxx>
#include <simgear/math/SGMath.hxx>


class NearestCarrierToNotification : public simgear::Emesary::INotification
{
public:
    explicit NearestCarrierToNotification(SGGeod _comparisonPosition) : position(),
                                                                        comparisonPosition(_comparisonPosition),
                                                                        heading(0),
                                                                        vckts(0),
                                                                        deckheight(0),
                                                                        distanceMeters(std::numeric_limits<double>::max()),
                                                                        carrier(0)
    {
    }

    /*virtual ~NearestCarrierToNotification()
    {
        if (position)
            delete position;
        position = 0;
    }*/
    const char* GetType() override { return "NearestCarrierToNotification"; }

    const SGGeod* GetPosition() const { return position; }
    double GetHeading() const { return heading; }
    double GetVckts() const { return vckts; }
    double GetDeckheight() const { return deckheight; }
    const class FGAICarrier* GetCarrier() const { return carrier; }
    double GetDistanceMeters() const { return distanceMeters; }
    std::string GetCarrierIdent() const { return carrierIdent; }
    double GetDistanceToMeters(const SGGeod& pos) const
    {
        if (carrier)
            return SGGeodesy::distanceM(comparisonPosition, pos);
        else
            return std::numeric_limits<double>::max() - 1;
    }

    void SetPosition(SGGeod* _position) { position = _position; }

    void SetHeading(double _heading) { heading = _heading; }
    void SetVckts(double _vckts) { vckts = _vckts; }
    void SetDeckheight(double _deckheight) { deckheight = _deckheight; }

    void SetCarrier(FGAICarrier* _carrier, SGGeod* _position)
    {
        carrier = _carrier;
        distanceMeters = SGGeodesy::distanceM(comparisonPosition, *_position);
        position = _position;
    }
    void SetDistanceMeters(double _distanceMeters) { distanceMeters = _distanceMeters; }
    void SetCarrierIdent(const std::string& _carrierIdent) { carrierIdent = _carrierIdent; }

    SGPropertyNode_ptr GetViewPositionLatNode() { return viewPositionLatDegNode; }
    SGPropertyNode_ptr GetViewPositionLonNode() { return viewPositionLonDegNode; }
    SGPropertyNode_ptr GetViewPositionAltNode() { return viewPositionAltFtNode; }

    void SetViewPositionLatNode(SGPropertyNode_ptr _viewPositionLatNode) { viewPositionLatDegNode = _viewPositionLatNode; }
    void SetViewPositionLonNode(SGPropertyNode_ptr _viewPositionLonNode) { viewPositionLonDegNode = _viewPositionLonNode; }
    void SetViewPositionAltNode(SGPropertyNode_ptr _viewPositionAltNode) { viewPositionAltFtNode = _viewPositionAltNode; }


protected:
    SGGeod* position;
    SGGeod comparisonPosition;

    SGPropertyNode_ptr viewPositionLatDegNode;
    SGPropertyNode_ptr viewPositionLonDegNode;
    SGPropertyNode_ptr viewPositionAltFtNode;

    double heading;
    double vckts;
    double deckheight;
    double distanceMeters;
    std::string carrierIdent;
    class FGAICarrier* carrier;
};
