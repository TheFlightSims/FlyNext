/*
 * Copyright (C) 2018 Edward d'Auvergne
 *
 * This file is part of the program FlightGear.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#ifndef _FG_INSTANCED_SUBSYSTEM_SYSTEM_TESTS_HXX
#define _FG_INSTANCED_SUBSYSTEM_SYSTEM_TESTS_HXX


#include <cppunit/extensions/HelperMacros.h>
#include <cppunit/TestFixture.h>

#include <simgear/structure/subsystem_mgr.hxx>


// The system tests.
class InstancedSubsystemTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(InstancedSubsystemTests);
    //CPPUNIT_TEST(testADF);                        // Not registered yet.
    //CPPUNIT_TEST(testAirspeedIndicator);          // Not registered yet.
    //CPPUNIT_TEST(testAltimeter);                  // Not registered yet.
    //CPPUNIT_TEST(testAttitudeIndicator);          // Not registered yet.
    //CPPUNIT_TEST(testCommRadio);                  // Not registered yet.
    //CPPUNIT_TEST(testClock);                      // Not registered yet.
    //CPPUNIT_TEST(testDME);                        // Not registered yet.
    //CPPUNIT_TEST(testFGKR_87);                    // Not registered yet.
    //CPPUNIT_TEST(testFGMarkerBeacon);             // Not registered yet.
    //CPPUNIT_TEST(testFGNavRadio);                 // Not registered yet.
    //CPPUNIT_TEST(testGPS);                        // Not registered yet.
    //CPPUNIT_TEST(testGSDI);                       // Not registered yet.
    //CPPUNIT_TEST(testHeadingIndicator);           // Not registered yet.
    //CPPUNIT_TEST(testHeadingIndicatorDG);         // Not registered yet.
    //CPPUNIT_TEST(testHeadingIndicatorFG);         // Not registered yet.
    //CPPUNIT_TEST(testHUD);                        // Segfault.
    //CPPUNIT_TEST(testInstVerticalSpeedIndicator); // Not registered yet.
    //CPPUNIT_TEST(testKLN89);                      // Not registered yet.
    //CPPUNIT_TEST(testMagCompass);                 // Not registered yet.
    //CPPUNIT_TEST(testMasterReferenceGyro);        // Not registered yet.
    //CPPUNIT_TEST(testMK_VIII);                    // Not registered yet.
    //CPPUNIT_TEST(testNavRadio);                   // Segfault.
    //CPPUNIT_TEST(testRadarAltimeter);             // Not registered yet.
    //CPPUNIT_TEST(testSlipSkidBall);               // Not registered yet.
    //CPPUNIT_TEST(testTACAN);                      // Not registered yet.
    //CPPUNIT_TEST(testTCAS);                       // Not registered yet.
    //CPPUNIT_TEST(testTransponder);                // Not registered yet.
    //CPPUNIT_TEST(testTurnIndicator);              // Not registered yet.
    //CPPUNIT_TEST(testVerticalSpeedIndicator);     // Not registered yet.
    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // The subsystem tests.
    void testADF();
    void testAirspeedIndicator();
    void testAltimeter();
    void testAttitudeIndicator();
    void testClock();
    void testCommRadio();
    void testDME();
    void testFGKR_87();
    void testFGMarkerBeacon();
    void testFGNavRadio();
    void testGPS();
    void testGSDI();
    void testHeadingIndicator();
    void testHeadingIndicatorDG();
    void testHeadingIndicatorFG();
    void testHUD();
    void testInstVerticalSpeedIndicator();
    void testKLN89();
    void testMagCompass();
    void testMasterReferenceGyro();
    void testMK_VIII();
    void testNavRadio();
    void testRadarAltimeter();
    void testSlipSkidBall();
    void testTACAN();
    void testTCAS();
    void testTransponder();
    void testTurnIndicator();
    void testVerticalSpeedIndicator();

private:
    // The subsystem manager.
    std::unique_ptr<SGSubsystemMgr> _mgr;

    // Helper functions.
    void create(const char* name);
};

#endif  // _FG_INSTANCED_SUBSYSTEM_SYSTEM_TESTS_HXX
