/*
 * SPDX-FileName: AIMultiplayer.hxx
 * SPDX-FileComment: AIBase derived class creates an AI multiplayer aircraft
 * SPDX-FileCopyrightText: Copyright (C) 2003  David P. Culp - davidculp2@comcast.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <map>
#include <string>
#include <string_view>

#include <MultiPlayer/mpmessages.hxx>

#include "AIBase.hxx"


class FGAIMultiplayer : public FGAIBase
{
public:
    FGAIMultiplayer();
    virtual ~FGAIMultiplayer() = default;

    std::string_view getTypeString() const override { return "multiplayer"; }
    bool init(ModelSearchOrder searchOrder) override;
    void bind() override;
    void update(double dt) override;

    void addMotionInfo(FGExternalMotionData& motionInfo, long stamp);

#if 0
  void setDoubleProperty(const std::string& prop, double val);
#endif

    long getLastTimestamp() const
    {
        return mLastTimestamp;
    }

    void setAllowExtrapolation(bool allowExtrapolation)
    {
        mAllowExtrapolation = allowExtrapolation;
    }
    bool getAllowExtrapolation() const
    {
        return mAllowExtrapolation;
    }

    void setLagAdjustSystemSpeed(double lagAdjustSystemSpeed)
    {
        if (lagAdjustSystemSpeed < 0)
            lagAdjustSystemSpeed = 0;
        mLagAdjustSystemSpeed = lagAdjustSystemSpeed;
    }

    double getLagAdjustSystemSpeed() const
    {
        return mLagAdjustSystemSpeed;
    }

    void addPropertyId(unsigned id, const char* name)
    {
        mPropertyMap[id] = props->getNode(name, true);
    }

    double getplayerLag() const
    {
        return playerLag;
    }

    void setplayerLag(double mplayerLag)
    {
        playerLag = mplayerLag;
    }

    int getcompensateLag() const
    {
        return compensateLag;
    }

    void setcompensateLag(int mcompensateLag)
    {
        compensateLag = mcompensateLag;
    }

    SGPropertyNode* getPropertyRoot()
    {
        return props;
    }

    void clearMotionInfo();

private:
    // Automatic sorting of motion data according to its timestamp
    typedef std::map<double, FGExternalMotionData> MotionInfo;
    MotionInfo mMotionInfo;

    // Map between the property id's from the multiplayer network packets
    // and the property nodes
    typedef std::map<unsigned, SGSharedPtr<SGPropertyNode>> PropertyMap;
    PropertyMap mPropertyMap;

    // Calculates position, orientation and velocity using interpolation between
    // *prevIt and *nextIt, specifically (1-tau)*(*prevIt) + tau*(*nextIt).
    //
    // Cannot call this method 'interpolate' because that would hide the name in
    // OSG.
    //
    void FGAIMultiplayerInterpolate(
        MotionInfo::iterator prevIt,
        MotionInfo::iterator nextIt,
        double tau,
        SGVec3d& ecPos,
        SGQuatf& ecOrient,
        SGVec3f& ecLinearVel);

    // Calculates position, orientation and velocity using extrapolation from
    // *nextIt.
    //
    void FGAIMultiplayerExtrapolate(
        MotionInfo::iterator nextIt,
        double tInterp,
        bool motion_logging,
        SGVec3d& ecPos,
        SGQuatf& ecOrient,
        SGVec3f& ecLinearVel);

    bool mTimeOffsetSet = false;
    bool realTime = false;
    int compensateLag = 1;
    double playerLag = 0.03;
    double mTimeOffset = 0.0;
    double lastUpdateTime = 0.0;
    double lastTime = 0.0;
    double lagPpsAveraged = 1.0;
    double rawLag = 0.0;
    double rawLagMod = 0.0;
    double lagModAveraged = 0.0;

    /// Properties which are for now exposed for testing
    bool mAllowExtrapolation = true;
    double mLagAdjustSystemSpeed = 10.0;

    long mLastTimestamp = 0;

    // Properties for tankers
    SGPropertyNode_ptr refuel_node;
    bool isTanker = false;
    bool contact = false; // set if this tanker is within fuelling range

    // velocities/u,v,wbody-fps
    SGPropertyNode_ptr _uBodyNode;
    SGPropertyNode_ptr _vBodyNode;
    SGPropertyNode_ptr _wBodyNode;

    // Things for simple-time.
    //
    SGPropertyNode_ptr m_simple_time_enabled;

    SGPropertyNode_ptr m_sim_replay_replay_state;
    SGPropertyNode_ptr m_sim_replay_time;

    bool m_simple_time_first_time = true;
    double m_simple_time_offset = 0.0;
    double m_simple_time_offset_smoothed = 0.0;
    double m_simple_time_compensation = 0.0;
    double m_simple_time_recent_packet_time = 0.0;

    SGPropertyNode_ptr m_lagPPSAveragedNode;
    SGPropertyNode_ptr m_lagModAveragedNode;

    SGPropertyNode_ptr m_node_simple_time_latest;
    SGPropertyNode_ptr m_node_simple_time_offset;
    SGPropertyNode_ptr m_node_simple_time_offset_smoothed;
    SGPropertyNode_ptr m_node_simple_time_compensation;

    // For use with scripts/python/recordreplay.py --test-motion-mp.
    SGPropertyNode_ptr mLogRawSpeedMultiplayer;

    SGPropertyNode_ptr m_node_ai_latch;
    std::string m_ai_latch;
    SGPropertyNode_ptr m_node_ai_latch_latitude;
    SGPropertyNode_ptr m_node_ai_latch_longitude;
    SGPropertyNode_ptr m_node_ai_latch_altitude;
    SGPropertyNode_ptr m_node_ai_latch_heading;
    SGPropertyNode_ptr m_node_ai_latch_pitch;
    SGPropertyNode_ptr m_node_ai_latch_roll;
    SGPropertyNode_ptr m_node_ai_latch_ubody_fps;
    SGPropertyNode_ptr m_node_ai_latch_vbody_fps;
    SGPropertyNode_ptr m_node_ai_latch_wbody_fps;
    SGPropertyNode_ptr m_node_ai_latch_speed_kts;

    SGPropertyNode_ptr m_node_log_multiplayer;
};
