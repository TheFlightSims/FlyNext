/*
 * SPDX-FileName: ATISEncoder.hxx
 * SPDX-FileComment: Encode an ATIS into spoken words
 * SPDX-FileCopyrightText: Copyright (C) 2014 Torsten Dreyer
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <map>
#include <string>

#include <Airports/airport.hxx>
#include <simgear/props/props.hxx>


class ATCSpeech
{
public:
    static std::string getSpokenDigit(int i);
    static std::string getSpokenNumber(std::string number);
    static std::string getSpokenNumber(int number, bool leadingZero = false, int digits = 1);
    static std::string getSpokenAltitude(int altitude);
};

class ATISInformationProvider
{
public:
    virtual ~ATISInformationProvider() {}
    virtual bool isValid() const = 0;
    virtual std::string airportId() const = 0;

    static long makeAtisTime(int day, int hour, int minute)
    {
        return 100 * 100l * day + 100l * hour + minute;
    }
    inline int getAtisTimeDay(long atisTime) { return atisTime / (100l * 100l); }
    inline int getAtisTimeHour(long atisTime) { return (atisTime % (100l * 100l)) / 100l; }
    inline int getAtisTimeMinute(long atisTime) { return atisTime % 100l; }
    virtual long getTime() const = 0; // see makeAtisTime

    virtual int getWindDeg() const = 0;
    virtual int getWindMinDeg() const = 0;
    virtual int getWindMaxDeg() const = 0;
    virtual int getWindSpeedKt() const = 0;
    virtual int getGustsKt() const = 0;
    virtual int getQnh() const = 0;
    virtual double getQnhInHg() const = 0;
    virtual bool isCavok() const = 0;
    virtual int getVisibilityMeters() const = 0;
    virtual std::string getPhenomena() const = 0;

    typedef std::map<int, std::string> CloudEntries;
    virtual CloudEntries getClouds() = 0;
    virtual int getTemperatureDeg() const = 0;
    virtual int getDewpointDeg() const = 0;
    virtual std::string getTrend() const = 0;
};

class ATISEncoder : public ATCSpeech
{
public:
    ATISEncoder();
    virtual ~ATISEncoder();
    virtual std::string encodeATIS(ATISInformationProvider* atisInformationProvider);

protected:
    virtual std::string getAtisId(SGPropertyNode_ptr);
    virtual std::string getAirportName(SGPropertyNode_ptr);
    virtual std::string getTime(SGPropertyNode_ptr);
    virtual std::string getApproachType(SGPropertyNode_ptr);
    virtual std::string getLandingRunway(SGPropertyNode_ptr);
    virtual std::string getTakeoffRunway(SGPropertyNode_ptr);
    virtual std::string getTransitionLevel(SGPropertyNode_ptr);
    virtual std::string getWindDirection(SGPropertyNode_ptr);
    virtual std::string getWindMinDirection(SGPropertyNode_ptr);
    virtual std::string getWindMaxDirection(SGPropertyNode_ptr);
    virtual std::string getWindspeedKnots(SGPropertyNode_ptr);
    virtual std::string getGustsKnots(SGPropertyNode_ptr);
    virtual std::string getCavok(SGPropertyNode_ptr);
    virtual std::string getVisibilityMetric(SGPropertyNode_ptr);
    virtual std::string getVisibilityMiles(SGPropertyNode_ptr);
    virtual std::string getPhenomena(SGPropertyNode_ptr);
    virtual std::string getClouds(SGPropertyNode_ptr);
    virtual std::string getCloudsBrief(SGPropertyNode_ptr);
    virtual std::string getTemperatureDeg(SGPropertyNode_ptr);
    virtual std::string getDewpointDeg(SGPropertyNode_ptr);
    virtual std::string getQnh(SGPropertyNode_ptr);
    virtual std::string getInhgInteger(SGPropertyNode_ptr);
    virtual std::string getInhgFraction(SGPropertyNode_ptr);
    virtual std::string getInhg(SGPropertyNode_ptr);
    virtual std::string getTrend(SGPropertyNode_ptr);

    typedef std::string (ATISEncoder::*handler_t)(SGPropertyNode_ptr baseNode);
    typedef std::map<std::string, handler_t> HandlerMap;
    HandlerMap handlerMap;

    SGPropertyNode_ptr atisSchemaNode;

    std::string processTokens(SGPropertyNode_ptr baseNode);
    std::string processToken(SGPropertyNode_ptr baseNode);

    std::string processTextToken(SGPropertyNode_ptr baseNode);
    std::string processTokenToken(SGPropertyNode_ptr baseNode);
    std::string processIfToken(SGPropertyNode_ptr baseNode);

    bool checkEmptyCondition(SGPropertyNode_ptr node, bool isEmpty);

    // Wrappers that can be passed as function pointers to checkCondition
    // @see simgear::strutils::starts_with
    // @see simgear::strutils::ends_with
    static bool contains(const std::string& s, const std::string& substring)
    {
        return s.find(substring) != std::string::npos;
    };
    static bool equals(const std::string& s1, const std::string& s2)
    {
        return s1 == s2;
    };

    bool checkCondition(SGPropertyNode_ptr node, bool notInverted,
                        bool (*fp)(const std::string&, const std::string&),
                        const std::string& name);

    FGAirportRef airport;
    ATISInformationProvider* _atis{nullptr};
};
