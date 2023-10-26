/*
 * SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */



#include <algorithm>
#include <memory>

#include "test_SGTime.hxx"
#include "test_suite/dataStore.hxx"

#include <simgear/math/SGGeod.hxx>

using namespace std;

// Set up function for each test.
void SimgearTimingTests::setUp()
{
}

// Clean up after each test.
void SimgearTimingTests::tearDown()
{

}


void SimgearTimingTests::testBadZoneDetectPosition()
{
    DataStore &data = DataStore::get();
    const SGPath rootPath{data.getFGRoot()};
    if (rootPath.isNull()) {
        return;
    }
    
    std::unique_ptr<SGTime> t(new SGTime{rootPath});
    
    const auto goodPos = SGGeod::fromDeg(-69.5, 12.0);
    CPPUNIT_ASSERT(t->updateLocal(goodPos, rootPath / "Timezone"));
    
    // discovered while flying with the Shuttle, but actually
    // can happen at sea level.
    // https://sourceforge.net/p/flightgear/codetickets/2780/

    // this was fixed by updating the timezone data from
    // https://github.com/BertoldVdb/ZoneDetect into FGData/Timezone/timezone16.bin
    const auto pos = SGGeod::fromDeg(-69.0, 12.0);
    CPPUNIT_ASSERT(t->updateLocal(pos, rootPath / "Timezone"));
}
