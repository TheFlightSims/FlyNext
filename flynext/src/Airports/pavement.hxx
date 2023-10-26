/*
 * SPDX-FileName: pavement.hxx
 * SPDX-FileComment: class to represent complex taxiway specified in v850 apt.dat
 * SPDX-FileCopyrightText: Copyright (C) 2009 Frederic Bouvier
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <Navaids/positioned.hxx>

class FGPavement : public FGPositioned
{
public:
    /*
   * 111 = Node (simple point).
   * 112 = Node with Bezier control point.
   * 113 = Node (close loop) point (to close a pavement boundary).
   * 114 = Node (close loop) point with Bezier control point (to close a pavement boundary).
   * 115 = Node (end) point to terminate a linear feature (so has no descriptive codes).
   * 116 = Node (end) point with Bezier control point, to terminate a linear feature (so has no descriptive codes).
   */
    struct NodeBase : public SGReferenced {
        SGGeod mPos;
        bool mClose;
        bool mLoop;
        int mPaintCode;
        int mLightCode;
        virtual ~NodeBase() {}          // To enable RTTI
    };
    struct SimpleNode : public NodeBase //111,113,115
    {
        SimpleNode(const SGGeod& aPos, bool aClose, bool aLoop, int aPaintCode, int aLightCode)
        {
            mPos = aPos;
            mClose = aClose;
            mLoop = aLoop;
            mPaintCode = aPaintCode;
            mLightCode = aLightCode;
        }
    };
    struct BezierNode : public NodeBase //112,114,116
    {
        BezierNode(const SGGeod& aPos, const SGGeod& aCtrlPt, bool aClose, bool aLoop, int aPaintCode, int aLightCode) : mControl{aCtrlPt}
        {
            mPos = aPos;
            mClose = aClose;
            mLoop = aLoop;
            mPaintCode = aPaintCode;
            mLightCode = aLightCode;
        }
        SGGeod mControl;
    };
    typedef std::vector<SGSharedPtr<NodeBase>> NodeList;


    FGPavement(PositionedID aGuid, const std::string& aIdent, const SGGeod& aPos);

    void addNode(const SGGeod& aPos, bool aClose = false, bool aLoop = false, int paintCode = 0, int lightCode = 0);
    void addBezierNode(const SGGeod& aPos, const SGGeod& aCtrlPt, bool aClose = false, bool aLoop = false, int paintCode = 0, int lightCode = 0);

    const NodeList& getNodeList() const { return mNodes; }


private:
    NodeList mNodes;
};
