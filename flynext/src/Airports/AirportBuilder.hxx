/*
 * SPDX-FileName: AirportBuilder.hxx
 * SPDX-FileComment: Builder to create airports based on airport data for rendering in the scenery
 * SPDX-FileCopyrightText: Copyright (C) 2020  Stuart Buchanan stuart13@gmail.com
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <osgDB/Registry>
#include <simgear/scene/material/Effect.hxx>
#include <simgear/scene/material/EffectGeode.hxx>

#include "airport.hxx"


namespace flightgear {

static const float RUNWAY_OFFSET = 3.0;

class AirportBuilder : public osgDB::ReaderWriter
{
public:
    // The different layers are offset to avoid z-buffering issues.  As they
    // are viewed from above only, this doesn't cause any problems visually.
    const float MARKING_OFFSET = 2.0;
    const float PAVEMENT_OFFSET = 1.0;
    const float BOUNDARY_OFFSET = 0.0;

    AirportBuilder();
    virtual ~AirportBuilder();

    virtual const char* className() const;

    virtual ReadResult readNode(const std::string& fileName,
                                const osgDB::Options* options)
        const;

private:
    osg::Node* createRunway(const osg::Matrixd mat, const SGVec3f center, const FGRunwayRef runway, const osgDB::Options* options) const;
    osg::Node* createPavement(const osg::Matrixd mat, const SGVec3f center, const FGPavementRef pavement, const osgDB::Options* options) const;
    osg::Node* createBoundary(const osg::Matrixd mat, const SGVec3f center, const FGPavementRef pavement, const osgDB::Options* options) const;
    osg::Node* createLine(const osg::Matrixd mat, const SGVec3f center, const FGPavementRef pavement, const osgDB::Options* options) const;
    osg::Vec4f getLineColor(const int aPaintCode) const;
    osg::ref_ptr<simgear::Effect> getMaterialEffect(std::string material, const osgDB::Options* options) const;
};

} // namespace flightgear
