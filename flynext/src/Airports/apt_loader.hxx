/*
 * SPDX-FileName: apt_loader.hxx
 * SPDX-FileComment: a front end loader of the apt.dat file.  This loader populates the runway and basic classes.
 * SPDX-FileCopyrightText: Copyright (C) 2004  Curtis L. Olson  - http://www.flightgear.org/~curt
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include <Navaids/positioned.hxx>
#include <Navaids/NavDataCache.hxx>
#include <simgear/compiler.h>
#include <simgear/math/SGGeod.hxx>
#include <simgear/misc/sg_path.hxx>
#include <simgear/structure/SGSharedPtr.hxx>

#include "airport.hxx"


class sg_gzifstream;
class FGPavement;


namespace flightgear {

class APTLoader
{
public:
    APTLoader();
    virtual ~APTLoader();

    // Read the specified apt.dat file into 'airportInfoMap'.
    // 'bytesReadSoFar' and 'totalSizeOfAllAptDatFiles' are used for progress
    // information.
    void readAptDatFile(const NavDataCache::SceneryLocation& sceneryLocation,
                        std::size_t bytesReadSoFar,
                        std::size_t totalSizeOfAllAptDatFiles);
    // Read all airports gathered in 'airportInfoMap' and load them into the
    // navdata cache (even in case of overlapping apt.dat files,
    // 'airportInfoMap' has only one entry per airport).
    void loadAirports();

    // Load a specific airport defined in aptdb_file, and return a "rich" view
    // of the airport including taxiways, pavement and line features.
    const FGAirport* loadAirportFromFile(const std::string& id, const NavDataCache::SceneryLocation& sceneryLocation);

private:
    struct Line {
        Line(unsigned int number_, unsigned int rowCode_, const std::string& str_)
            : number(number_), rowCode(rowCode_), str(str_) {}

        unsigned int number;
        unsigned int rowCode; // Terminology of the apt.dat spec
        std::string str;
    };

    typedef std::vector<Line> LinesList;

    struct RawAirportInfo {
        // apt.dat file where the airport was defined
        SGPath file;
        // Base path of the corresponding scenery
        SGPath sceneryPath;
        // Row code for the airport (1, 16 or 17)
        unsigned int rowCode;
        // Line number in the apt.dat file where the airport definition starts
        unsigned int firstLineNum;
        // The whitespace-separated strings comprising the first line of the airport
        // definition
        std::vector<std::string> firstLineTokens;
        // Subsequent lines of the airport definition (one element per line)
        LinesList otherLines;
    };

    typedef std::unordered_map<std::string, RawAirportInfo> AirportInfoMapType;
    typedef SGSharedPtr<FGPavement> FGPavementPtr;
    typedef std::vector<FGPavementPtr> NodeList;

    APTLoader(const APTLoader&);            // disable copy constructor
    APTLoader& operator=(const APTLoader&); // disable copy-assignment operator

    const FGAirport* loadAirport(const SGPath& aptDat, const std::string& airportID, RawAirportInfo* airport_info, bool createFGAirport = false);

    // Tell whether an apt.dat line is blank or a comment line
    bool isBlankOrCommentLine(const std::string& line);
    // Return a copy of 'line' with trailing '\r' char(s) removed
    std::string cleanLine(const std::string& line);
    void throwExceptionIfStreamError(const sg_gzifstream& input_stream,
                                     const SGPath& path);
    void parseAirportLine(unsigned int rowCode,
                          const std::vector<std::string>& token,
                          const SGPath& sceneryPath);
    void finishAirport(const std::string& aptDat);
    void parseRunwayLine810(const std::string& aptDat, unsigned int lineNum,
                            const std::vector<std::string>& token);
    void parseRunwayLine850(const std::string& aptDat, unsigned int lineNum,
                            const std::vector<std::string>& token);
    void parseWaterRunwayLine850(const std::string& aptDat, unsigned int lineNum,
                                 const std::vector<std::string>& token);
    void parseHelipadLine850(const std::string& aptDat, unsigned int lineNum,
                             const std::vector<std::string>& token);
    void parseViewpointLine(const std::string& aptDat, unsigned int lineNum,
                            const std::vector<std::string>& token);
    void parsePavementLine850(const std::vector<std::string>& token);
    void parseNodeLine850(
        NodeList* nodelist,
        const std::string& aptDat, unsigned int lineNum, int rowCode,
        const std::vector<std::string>& token);

    void parseCommLine(
        const std::string& aptDat, unsigned int lineNum, unsigned int rowCode,
        const std::vector<std::string>& token);

    std::vector<std::string> token;
    AirportInfoMapType airportInfoMap;
    double rwy_lat_accum{0.0};
    double rwy_lon_accum{0.0};
    double last_rwy_heading{0.0};
    int rwy_count{0};
    std::string last_apt_id;
    double last_apt_elev;
    SGGeod tower;

    std::string pavement_ident;
    NodeList pavements;
    NodeList airport_boundary;
    NodeList linear_feature;

    // Not an airport identifier in the sense of the apt.dat spec!
    PositionedID currentAirportPosID;
    NavDataCache* cache;

    // Enum to keep track of whether we are tracking a pavement, airport boundary
    // or linear feature when parsing the file.
    enum NodeBlock { None,
                     Pavement,
                     AirportBoundary,
                     LinearFeature };
};

bool metarDataLoad(const SGPath& path);

} // namespace flightgear
