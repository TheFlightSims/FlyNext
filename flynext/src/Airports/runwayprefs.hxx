/*
 * SPDX-FileName: runwayprefs.hxx
 * SPDX-FileComment: A number of classes to configure runway assignments by the AI code
 * SPDX-FileCopyrightText: Copyright (C) 2004 Durk Talsma.
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <time.h>

#include <simgear/compiler.h>

#include "airports_fwd.hxx"


typedef std::vector<time_t> timeVec;
typedef std::vector<time_t>::const_iterator timeVecConstIterator;

typedef std::vector<std::string> stringVec;
typedef std::vector<std::string>::iterator stringVecIterator;
typedef std::vector<std::string>::const_iterator stringVecConstIterator;


/***************************************************************************/
class ScheduleTime
{
private:
    timeVec start;
    timeVec end;
    stringVec scheduleNames;
    double tailWind;
    double crssWind;

public:
    ScheduleTime() : tailWind(0), crssWind(0){};
    ScheduleTime(const ScheduleTime& other);
    ScheduleTime& operator=(const ScheduleTime& other);
    std::string getName(time_t dayStart);

    void clear();
    void addStartTime(time_t time) { start.push_back(time); };
    void addEndTime(time_t time) { end.push_back(time); };
    void addScheduleName(const std::string& sched) { scheduleNames.push_back(sched); };
    void setTailWind(double wnd) { tailWind = wnd; };
    void setCrossWind(double wnd) { tailWind = wnd; };

    double getTailWind() { return tailWind; };
    double getCrossWind() { return crssWind; };
};

//typedef vector<ScheduleTime> ScheduleTimes;
/*****************************************************************************/

class RunwayList
{
private:
    std::string type;
    stringVec preferredRunways;

public:
    RunwayList(){};
    RunwayList(const RunwayList& other);
    RunwayList& operator=(const RunwayList& other);

    void set(const std::string&, const std::string&);
    void clear();

    std::string getType() { return type; };
    const stringVec& getPreferredRunways() const { return preferredRunways; };
};

/*****************************************************************************/

class RunwayGroup
{
private:
    std::string name;
    RunwayListVec rwyList;
    int active = -1;
    int choice[2] = {0};
    int nrActive = 0;

public:
    RunwayGroup(){};
    RunwayGroup(const RunwayGroup& other);
    RunwayGroup& operator=(const RunwayGroup& other);

    void setName(const std::string& nm) { name = nm; };
    void add(const RunwayList& list) { rwyList.push_back(list); };
    void setActive(const FGAirport* airport, double windSpeed, double windHeading, double maxTail, double maxCross, stringVec* curr);

    int getNrActiveRunways() { return nrActive; };
    void getActive(int i, std::string& name, std::string& type);

    const std::string& getName() const { return name; };
    void clear() { rwyList.clear(); };
};

/******************************************************************************/

class FGRunwayPreference
{
private:
    FGAirport* _ap;

    ScheduleTime comTimes; // Commercial Traffic;
    ScheduleTime genTimes; // General Aviation;
    ScheduleTime milTimes; // Military Traffic;
    ScheduleTime ulTimes;  // Ultralight Traffic

    PreferenceList preferences;

    bool initialized;

public:
    explicit FGRunwayPreference(FGAirport* ap);
    FGRunwayPreference(const FGRunwayPreference& other);

    FGRunwayPreference& operator=(const FGRunwayPreference& other);

    ScheduleTime* getSchedule(const char* trafficType);
    RunwayGroup* getGroup(const std::string& groupName);

    std::string getId();

    bool available() { return initialized; };
    void setInitialized(bool state) { initialized = state; };

    void setMilTimes(const ScheduleTime& t) { milTimes = t; };
    void setGenTimes(const ScheduleTime& t) { genTimes = t; };
    void setComTimes(const ScheduleTime& t) { comTimes = t; };
    void setULTimes(const ScheduleTime& t) { ulTimes = t; };

    void addRunwayGroup(RunwayGroup& g) { preferences.push_back(g); };
};
