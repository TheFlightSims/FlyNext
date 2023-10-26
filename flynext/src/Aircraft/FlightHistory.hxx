/*
 * SPDX-FileName: FlightHistory.hxx
 * SPDX-FileCopyrightText: Copyright (C) 2012 James Turner - zakalawe (at) mac com
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <vector>

#include <simgear/math/SGMath.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>

typedef std::vector<SGGeod> SGGeodVec;

class PagedPathForHistory : public SGReferenced
{
public:
    PagedPathForHistory() : last_seen(0) {}
    virtual ~PagedPathForHistory() {}
    SGGeodVec path;
    time_t last_seen;
};

typedef SGSharedPtr<PagedPathForHistory> PagedPathForHistory_ptr;

const unsigned int SAMPLE_BUCKET_WIDTH = 1024;

/**
 * record the history of the aircraft's movements, making it available
 * as a contiguous block. This can be used to show the historical flight-path
 * over a long period of time (unlike the replay system), but only a small,
 * fixed set of properties are recorded. (Positioned and orientation, but
 * not velocity, acceleration, control inputs, or so on)
 */
class FGFlightHistory : public SGSubsystem
{
public:
    FGFlightHistory();
    virtual ~FGFlightHistory();

    // Subsystem API.
    void init() override;
    void reinit() override;
    void shutdown() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "history"; }

    PagedPathForHistory_ptr pagedPathForHistory(size_t max_entries, size_t newerThan = 0) const;
    /**
     * retrieve the path, collapsing segments shorter than
     * the specified minimum length
     */
    SGGeodVec pathForHistory(double minEdgeLengthM = 50.0) const;

    /**
     * clear the history
     */

    void clear();

private:
    /**
     * @class A single data sample in the history system.
     */
    class Sample
    {
    public:
        SGGeod position;
        /// heading, pitch and roll can be recorded at lower precision
        /// than a double - actually 16 bits might be sufficient
        float heading, pitch, roll;
        size_t simTimeMSec;
    };


    /**
     * Bucket is a fixed-size container of samples. This is a crude slab
     * allocation of samples, in chunks defined by the width constant above.
     * Keep in mind that even with a 1Hz sample frequency, we use less than
     * 200 KB per hour - avoiding continuous malloc traffic, or expensive
     * std::vector reallocations, is the key factor here.
     */
    class SampleBucket
    {
    public:
        Sample samples[SAMPLE_BUCKET_WIDTH];
    };

    double m_lastCaptureTime{0.0};
    double m_sampleInterval; ///< sample interval in seconds
                             /// our store of samples (in buckets). The last bucket is partially full,
                             /// with the number of valid samples indicated by m_validSampleCount
    std::vector<SampleBucket*> m_buckets;

    /// number of valid samples in the final bucket
    unsigned int m_validSampleCount;

    SGPropertyNode_ptr m_weightOnWheels;
    SGPropertyNode_ptr m_enabled;

    bool m_lastWoW{false};
    size_t m_maxMemoryUseBytes{0};

    void allocateNewBucket();

    void capture();

    size_t currentMemoryUseBytes() const;
};
