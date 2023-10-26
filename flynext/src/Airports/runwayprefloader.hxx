/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <time.h>

#include <simgear/compiler.h>
#include <simgear/xml/easyxml.hxx>

#include "runwayprefs.hxx"


class FGRunwayPreferenceXMLLoader : public XMLVisitor
{
public:
    explicit FGRunwayPreferenceXMLLoader(FGRunwayPreference* p);

protected:
    virtual void startXML();
    virtual void endXML();
    virtual void startElement(const char* name, const XMLAttributes& atts);
    virtual void endElement(const char* name);
    virtual void data(const char* s, int len);
    virtual void pi(const char* target, const char* data);
    virtual void warning(const char* message, int line, int column);
    virtual void error(const char* message, int line, int column);

    time_t processTime(const std::string& tme);

private:
    FGRunwayPreference* _pref;

    std::string value;

    std::string scheduleName;
    ScheduleTime currTimes; // Needed for parsing;

    RunwayList rwyList;
    RunwayGroup rwyGroup;
};
