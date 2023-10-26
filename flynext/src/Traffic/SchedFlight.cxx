/******************************************************************************
 * SchedFlight.cxx
 * Written by Durk Talsma, started May 5, 2004.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 *
 **************************************************************************/

/* This a prototype version of a top-level flight plan manager for Flightgear.
 * It parses the fgtraffic.txt file and determine for a specific time/date,
 * where each aircraft listed in this file is at the current time.
 *
 * I'm currently assuming the following simplifications:
 * 1) The earth is a perfect sphere
 * 2) Each aircraft flies a perfect great circle route.
 * 3) Each aircraft flies at a constant speed (with infinite accelerations and
 *    decelerations)
 * 4) Each aircraft leaves at exactly the departure time.
 * 5) Each aircraft arrives at exactly the specified arrival time.
 *
 * TODO:
 * - Check the code for known portability issues
 *
 *****************************************************************************/

#ifdef HAVE_CONFIG_H
#  include "config.h"
#endif

#include <stdlib.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include <simgear/compiler.h>
#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>
#include <simgear/timing/sg_time.hxx>
#include <simgear/xml/easyxml.hxx>

#include <AIModel/AIFlightPlan.hxx>
#include <AIModel/AIManager.hxx>
#include <Airports/airport.hxx>

#include <Main/globals.hxx>

#include "SchedFlight.hxx"

using std::string;


/******************************************************************************
 * FGScheduledFlight stuff
 *****************************************************************************/

std::map<std::string, std::string> FGScheduledFlight::missingAirports = std::map<std::string, std::string>();

FGScheduledFlight::FGScheduledFlight() : departurePort{nullptr},
                                         arrivalPort{nullptr},
                                         departureTime{0},
                                         arrivalTime{0},
                                         repeatPeriod{0}
{
    cruiseAltitude = 0;
    initialized = false;
    available = true;
}

FGScheduledFlight::FGScheduledFlight(const FGScheduledFlight &other) : callsign{other.callsign},
                                                                       fltRules{other.fltRules},
                                                                       departurePort{other.departurePort},
                                                                       arrivalPort{other.arrivalPort},
                                                                       depId{other.depId},
                                                                       arrId{other.arrId},
                                                                       requiredAircraft{other.requiredAircraft},
                                                                       departureTime{other.departureTime},
                                                                       arrivalTime{other.arrivalTime},
                                                                       repeatPeriod{other.repeatPeriod}
{
  cruiseAltitude    = other.cruiseAltitude;
  initialized       = other.initialized;
  available         = other.available;
}

/**
 * @param cs The callsign
 * @param fr The flightrules
 * @param depPrt The departure ICAO
 * @param arrPrt The arrival ICAO
 */

FGScheduledFlight::FGScheduledFlight(const string& cs,
		                             const string& fr,
		                             const string& depPrt,
		                             const string& arrPrt,
		                             int cruiseAlt,
		                             const string& deptime,
		                             const string& arrtime,
		                             const string& rep,
		                             const string& reqAC) : callsign{cs},
                                                            fltRules{fr},
                                                            departurePort{nullptr},
                                                            arrivalPort{nullptr},
                                                            depId{depPrt},
                                                            arrId{arrPrt},
                                                            requiredAircraft{reqAC}
{
  //departurePort.setId(depPrt);
  //arrivalPort.setId(arrPrt);

  //cerr << "Constructor: departure " << depId << ". arrival " << arrId << endl;
  //departureTime     = processTimeString(deptime);
  //arrivalTime       = processTimeString(arrtime);
  cruiseAltitude    = cruiseAlt;

  // Process the repeat period string
  if (rep.find("WEEK",0) != string::npos)
    {
      repeatPeriod = 7*24*60*60; // in seconds
    }
  else if (rep.find("Hr", 0) != string::npos)
    {
      repeatPeriod = 60*60*atoi(rep.substr(0,2).c_str());
    }
  else
    {
      repeatPeriod = 365*24*60*60;
      SG_LOG( SG_AI, SG_ALERT, "Unknown repeat period in flight plan "
                                    "of flight '" << cs << "': " << rep );
    }
  if (!repeatPeriod) {
      SG_LOG( SG_AI, SG_ALERT, "Zero repeat period in flight plan "
                                    "of flight '" << cs << "': " << rep );
      available = false;
      return;
  }


  // What we still need to do is preprocess the departure and
  // arrival times.
  departureTime = processTimeString(deptime);
  arrivalTime   = processTimeString(arrtime);
  //departureTime += rand() % 300; // Make sure departure times are not limited to 5 minute increments.
  if (departureTime > arrivalTime)
    {
      departureTime -= repeatPeriod;
    }
  initialized = false;
  available   = true;
}


FGScheduledFlight:: ~FGScheduledFlight()
{
}

time_t FGScheduledFlight::processTimeString(const string& theTime)
{
    int timeOffsetInDays = 0;
    int targetHour;
    int targetMinute;
    int targetSecond;

    tm targetTimeDate;
    SGTime* currTimeDate = globals->get_time_params();

    string timeCopy = theTime;


    // okay first split theTime string into
    // weekday, hour, minute, second;
    // Check if a week day is specified
    const auto daySeparatorPos = timeCopy.find("/", 0);
    if (daySeparatorPos != string::npos) {
        const int weekday = std::stoi(timeCopy.substr(0, daySeparatorPos));
        timeOffsetInDays = weekday - currTimeDate->getGmt()->tm_wday;
        timeCopy = theTime.substr(daySeparatorPos + 1);
    }

    const auto timeTokens = simgear::strutils::split(timeCopy, ":");
    if (timeTokens.size() != 3) {
        SG_LOG(SG_AI, SG_DEV_WARN, "FGScheduledFlight: Timestring too short. " << theTime << " Defaulted to now");
        return currTimeDate->get_cur_time();
    }


    targetHour = std::stoi(timeTokens.at(0));
    targetMinute = std::stoi(timeTokens.at(1));
    targetSecond = std::stoi(timeTokens.at(2));
    targetTimeDate.tm_year = currTimeDate->getGmt()->tm_year;
    targetTimeDate.tm_mon = currTimeDate->getGmt()->tm_mon;
    targetTimeDate.tm_mday = currTimeDate->getGmt()->tm_mday;
    targetTimeDate.tm_hour = targetHour;
    targetTimeDate.tm_min = targetMinute;
    targetTimeDate.tm_sec = targetSecond;

    time_t processedTime = sgTimeGetGMT(&targetTimeDate);
    processedTime += timeOffsetInDays * 24 * 60 * 60;
    if (processedTime < currTimeDate->get_cur_time()) {
        processedTime += repeatPeriod;
    }
  //tm *temp = currTimeDate->getGmt();
  //char buffer[512];
  //sgTimeFormatTime(&targetTimeDate, buffer);
  //cout << "Scheduled Time " << buffer << endl;
  //cout << "Time :" << time(NULL) << " SGTime : " << sgTimeGetGMT(temp) << endl;
  return processedTime;
}

void FGScheduledFlight::update()
{
  departureTime += repeatPeriod;
  arrivalTime  += repeatPeriod;
}

/**
 * //FIXME Doesn't have to be an iteration / when sitting at departure why adjust based on arrival
 */

void FGScheduledFlight::adjustTime(time_t now)
{
    // Make sure that the arrival time is in between
    // the current time and the next repeat period.
    while ((arrivalTime < now) || (arrivalTime > now + repeatPeriod)) {
        if (arrivalTime < now) {
            departureTime += repeatPeriod;
            arrivalTime += repeatPeriod;
            SG_LOG(SG_AI, SG_BULK, "Adjusted schedule forward : " << callsign << " " << now << " " << departureTime << " " << arrivalTime);
        } else if (arrivalTime > now + repeatPeriod) {
            departureTime -= repeatPeriod;
            arrivalTime -= repeatPeriod;
            SG_LOG(SG_AI, SG_BULK, "Adjusted schedule backward : " << callsign << " " << now << " " << departureTime << " " << arrivalTime);
        } else {
            SG_LOG(SG_AI, SG_BULK, "Not Adjusted schedule : " << now);
        }
    }
}


FGAirport *FGScheduledFlight::getDepartureAirport()
{
  if (!(initialized))
    {
      initializeAirports();
    }
  if (initialized)
    return departurePort;
  else
    return 0;
}

FGAirport * FGScheduledFlight::getArrivalAirport  ()
{
   if (!(initialized))
    {
      initializeAirports();
    }
   if (initialized)
     return arrivalPort;
   else
     return 0;
}

// Upon the first time of requesting airport information
// for this scheduled flight, these data need to be
// looked up in the main FlightGear database.
// Missing or bogus Airport codes are currently ignored,
// but we should improve that. The best idea is probably to cancel
// this flight entirely by removing it from the schedule, if one
// of the airports cannot be found.
bool FGScheduledFlight::initializeAirports()
{
  //cerr << "Initializing using : " << depId << " " << arrId << endl;
  departurePort = FGAirport::findByIdent(depId);
  if(departurePort == nullptr)
    {
      if (!FGScheduledFlight::missingAirports.count(depId)) {
        FGScheduledFlight::missingAirports.insert(std::pair<std::string,std::string>(depId, depId));
        SG_LOG( SG_AI, SG_DEBUG, "Traffic manager could not find airport : " << depId);
      }
      return false;
    }
  arrivalPort = FGAirport::findByIdent(arrId);
  if(arrivalPort == nullptr)
    {
      if (!FGScheduledFlight::missingAirports.count(arrId)) {
        FGScheduledFlight::missingAirports.insert(std::pair<std::string,std::string>(arrId, arrId));
        SG_LOG( SG_AI, SG_DEBUG, "Traffic manager could not find airport : " << arrId);
      }
      return false;
    }

  //cerr << "Found : " << departurePort->getId() << endl;
  //cerr << "Found : " << arrivalPort->getId() << endl;
  initialized = true;
  return true;
}

bool FGScheduledFlight::compareScheduledFlights(const FGScheduledFlight *a, const FGScheduledFlight *b)
{
  return (*a) < (*b);
};
