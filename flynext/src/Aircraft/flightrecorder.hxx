/*
 * SPDX-FileName: flightrecorder.hxx
 * SPDX-FileCopyrightText: Copyright (C) 2011 Thorsten Brehm - brehmt (at) gmail com
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <MultiPlayer/multiplaymgr.hxx>
#include <simgear/props/props.hxx>

#include "replay-internal.hxx"

namespace FlightRecorder {

typedef enum {
    discrete = 0,    // no interpolation
    linear = 1,      // linear interpolation
    angular_rad = 2, // angular interpolation, value in radians
    angular_deg = 3  // angular interpolation, value in degrees
} TInterpolation;

typedef struct
{
    SGPropertyNode_ptr Signal;
    TInterpolation Interpolation;
} TCapture;

typedef std::vector<TCapture> TSignalList;

} // namespace FlightRecorder

class FGFlightRecorder
{
public:
    explicit FGFlightRecorder(const char* pConfigName);
    virtual ~FGFlightRecorder();

    void reinit();
    void reinit(SGPropertyNode_ptr ConfigNode);
    FGReplayData* capture(double SimTime, FGReplayData* pRecycledBuffer);

    // Updates main_window_* out-params if we find window move/resize events
    // and replay of such events is enabled.
    void replay(double SimTime, const FGReplayData* pNextBuffer,
                const FGReplayData* pLastBuffer,
                int* main_window_xpos,
                int* main_window_ypos,
                int* main_window_xsize,
                int* main_window_ysize);
    int getRecordSize() { return m_TotalRecordSize; }
    void getConfig(SGPropertyNode* root);
    void resetExtraProperties();

private:
    SGPropertyNode_ptr getDefault();
    void initSignalList(const char* pSignalType, FlightRecorder::TSignalList& SignalList,
                        SGPropertyNode_ptr BaseNode);
    void processSignalList(const char* pSignalType, FlightRecorder::TSignalList& SignalList,
                           SGPropertyNode_ptr SignalListNode,
                           std::string PropPrefix = "", int Count = 1);
    bool haveProperty(FlightRecorder::TSignalList& Capture, const SGPropertyNode* pProperty);
    bool haveProperty(const SGPropertyNode* pProperty);

    int getConfig(SGPropertyNode* root, const char* typeStr, const FlightRecorder::TSignalList& SignalList);

    SGPropertyNode_ptr m_RecorderNode;
    SGPropertyNode_ptr m_ConfigNode;

    SGPropertyNode_ptr m_ReplayMultiplayer;
    SGPropertyNode_ptr m_ReplayExtraProperties;
    SGPropertyNode_ptr m_ReplayMainView;
    SGPropertyNode_ptr m_ReplayMainWindowPosition;
    SGPropertyNode_ptr m_ReplayMainWindowSize;

    SGPropertyNode_ptr m_RecordContinuous;
    SGPropertyNode_ptr m_RecordExtraProperties;

    SGPropertyNode_ptr m_LogRawSpeed;

    // This contains copy of all properties that we are recording, so that we
    // can send only differences.
    //
    SGPropertyNode_ptr m_RecordExtraPropertiesReference;

    FlightRecorder::TSignalList m_CaptureDouble;
    FlightRecorder::TSignalList m_CaptureFloat;
    FlightRecorder::TSignalList m_CaptureInteger;
    FlightRecorder::TSignalList m_CaptureInt16;
    FlightRecorder::TSignalList m_CaptureInt8;
    FlightRecorder::TSignalList m_CaptureBool;

    unsigned m_TotalRecordSize;
    std::string m_ConfigName;
    bool m_usingDefaultConfig;
    FGMultiplayMgr* m_MultiplayMgr;
};
