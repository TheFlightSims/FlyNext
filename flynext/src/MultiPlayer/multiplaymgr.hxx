/*
 * SPDX-FileName: multiplaymgr.hxx
 * SPDX-FileCopyrightText: Written by Duncan McCreanor, started February 2003 - duncan.mccreanor@airservicesaustralia.com
 * SPDX-FileContributor: Copyright (C) 2003  Airservices Australia, Copyright (C) 2005  Oliver Schroeder
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#define MULTIPLAYTXMGR_HID "$Id$"

const int MIN_MP_PROTOCOL_VERSION = 1;
const int MAX_MP_PROTOCOL_VERSION = 2;

#include <deque>
#include <memory>
#include <string>
#include <vector>

#include <simgear/compiler.h>
#include <simgear/io/raw_socket.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>


class IRCConnection;
class CPDLCManager;

const std::string MPIRC_SERVER_HOST_DEFAULT{"mpirc.flightgear.org"};
const std::string MPIRC_SERVER_HOST_PROPERTY{"/network/mpirc/server-host"};
const std::string MPIRC_SERVER_PORT_PROPERTY{"/network/mpirc/server-port"};
const std::string MPIRC_NICK_PREFIX{"MP_IRC_"};

struct FGExternalMotionData;
class MPPropertyListener;
struct T_MsgHdr;
class FGAIMultiplayer;


class FGMultiplayMgr : public SGSubsystem
{
public:
    FGMultiplayMgr();
    ~FGMultiplayMgr();

    // Subsystem API.
    void init() override;
    void reinit() override;
    void shutdown() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "mp"; }

    // transmitter

    void SendTextMessage(const std::string& sMsgText);
    // receiver

    FGAIMultiplayer* getMultiplayer(const std::string& callsign);

    std::shared_ptr<std::vector<char>> popMessageHistory();
    void pushMessageHistory(std::shared_ptr<std::vector<char>> message);

    // Remove motion information for all multiplayer aircraft, e.g. when
    // scrubbing during replay.
    void ClearMotion();
    CPDLCManager* getCPDLC() { return _cpdlc.get(); };

private:
    std::unique_ptr<IRCConnection> _mpirc;
    std::unique_ptr<CPDLCManager> _cpdlc;
    friend class MPPropertyListener;

    void setPropertiesChanged()
    {
        mPropertiesChanged = true;
    }
    int getProtocolToUse()
    {
        int protocolVersion = pProtocolVersion->getIntValue();
        if (protocolVersion >= MIN_MP_PROTOCOL_VERSION && protocolVersion <= MAX_MP_PROTOCOL_VERSION)
            return protocolVersion;
        else
            return MIN_MP_PROTOCOL_VERSION;
    }

    void findProperties();

    void Send(double currentMPTime);
    void SendMyPosition(const FGExternalMotionData& motionInfo);
    short get_scaled_short(double v, double scale);

    union MsgBuf;
    FGAIMultiplayer* addMultiplayer(const std::string& callsign,
                                    const std::string& modelName,
                                    const int fallback_model_index);
    void FillMsgHdr(T_MsgHdr* MsgHdr, int iMsgId, unsigned _len = 0u);
    void ProcessPosMsg(const MsgBuf& Msg, const simgear::IPAddress& SenderAddress,
                       long stamp);
    void ProcessChatMsg(const MsgBuf& Msg, const simgear::IPAddress& SenderAddress);
    bool isSane(const FGExternalMotionData& motionInfo);
    int GetMsgNetwork(MsgBuf& msgBuf, simgear::IPAddress& SenderAddress);
    int GetMsg(MsgBuf& msgBuf, simgear::IPAddress& SenderAddress);

    /// maps from the callsign string to the FGAIMultiplayer
    typedef std::map<std::string, SGSharedPtr<FGAIMultiplayer>> MultiPlayerMap;
    MultiPlayerMap mMultiPlayerMap;

    std::unique_ptr<simgear::Socket> mSocket;
    simgear::IPAddress mServer;
    bool mHaveServer;
    bool mInitialised;
    std::string mCallsign;

    // Map between the property id's from the multiplayers network packets
    // and the property nodes
    typedef std::map<unsigned int, SGSharedPtr<SGPropertyNode>> PropertyMap;
    PropertyMap mPropertyMap;
    SGPropertyNode* pProtocolVersion;
    SGPropertyNode* pXmitLen;
    SGPropertyNode* pMultiPlayDebugLevel;
    SGPropertyNode* pMultiPlayRange;
    SGPropertyNode* pMultiPlayTransmitPropertyBase;
    SGPropertyNode* pReplayState;
    SGPropertyNode* pLogRawSpeedMultiplayer;

    typedef std::map<unsigned int, const struct IdPropertyList*> PropertyDefinitionMap;
    PropertyDefinitionMap mPropertyDefinition;

    bool mPropertiesChanged;

    MPPropertyListener* mListener;

    double mDt; // reciprocal of /sim/multiplay/tx-rate-hz
    double mNextTransmitTime = 0.0;

    std::deque<std::shared_ptr<std::vector<char>>> mRecordMessageQueue;
    std::deque<std::shared_ptr<std::vector<char>>> mReplayMessageQueue;
};
