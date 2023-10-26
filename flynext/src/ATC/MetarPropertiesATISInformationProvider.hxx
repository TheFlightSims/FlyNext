/*
Provide Data for the ATIS Encoder from metarproperties
Copyright (C) 2014 Torsten Dreyer

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#ifndef __METARPROPERTIES_ATIS_ENCODER_HXX
#define __METARPROPERTIES_ATIS_ENCODER_HXX

/* ATIS encoder from metarproperties */

#include <simgear/props/props.hxx>

#include <string>
#include "ATISEncoder.hxx"

class MetarPropertiesATISInformationProvider : public ATISInformationProvider
{
public:
    explicit MetarPropertiesATISInformationProvider( SGPropertyNode_ptr metar );
    virtual ~MetarPropertiesATISInformationProvider();

protected:
    virtual bool isValid() const override;
    virtual std::string airportId() const override;
    virtual long getTime() const override;
    virtual int getWindDeg() const override;
    virtual int getWindMinDeg() const override;
    virtual int getWindMaxDeg() const override;
    virtual int getWindSpeedKt() const override;
    virtual int getGustsKt() const override;
    virtual int getQnh() const override;
    virtual double getQnhInHg() const override;
    virtual bool isCavok() const override;
    virtual int getVisibilityMeters() const override;
    virtual std::string getPhenomena() const override;
    virtual CloudEntries getClouds();
    virtual int getTemperatureDeg() const override;
    virtual int getDewpointDeg() const override;
    virtual std::string getTrend() const override;

private:
    SGPropertyNode_ptr _metar;
};

#endif
