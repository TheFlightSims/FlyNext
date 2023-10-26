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

#include "test_suite/FGTestApi/testGlobals.hxx"

#include "test_instanced_creation.hxx"


// Set up function for each test.
void InstancedSubsystemTests::setUp()
{
    // First set up the globals object.
    FGTestApi::setUp::initTestGlobals("InstancedSubsystemCreationTests");

    // The subsystem manager.
    _mgr.reset(new SGSubsystemMgr());
}


// Clean up after each test.
void InstancedSubsystemTests::tearDown()
{
    // Remove the manager.
    _mgr.reset();

    // Clean up globals.
    FGTestApi::tearDown::shutdownTestGlobals();
}


// Helper functions.
void InstancedSubsystemTests::create(const char* name)
{
    // Create two subsystem instances and add them to the manager.
    _mgr->addInstance(name, "inst1");
    _mgr->addInstance(name, "inst2");
    auto sub1 = _mgr->get_subsystem(name, "inst1");
    auto sub2 = _mgr->get_subsystem(name, "inst2");

    // Check the first subsystem.
    CPPUNIT_ASSERT(sub1);
    CPPUNIT_ASSERT_EQUAL(sub1->subsystemId(), std::string(name) + ".inst1");
    CPPUNIT_ASSERT_EQUAL(sub1->subsystemClassId(), std::string(name));
    CPPUNIT_ASSERT_EQUAL(sub1->subsystemInstanceId(), std::string("inst1"));

    // Check the second subsystem.
    CPPUNIT_ASSERT(sub2);
    CPPUNIT_ASSERT_EQUAL(sub2->subsystemId(), std::string(name) + ".inst2");
    CPPUNIT_ASSERT_EQUAL(sub2->subsystemClassId(), std::string(name));
    CPPUNIT_ASSERT_EQUAL(sub2->subsystemInstanceId(), std::string("inst2"));
}


// The instanced subsystems.
void InstancedSubsystemTests::testADF()                        { create("adf"); }
void InstancedSubsystemTests::testAirspeedIndicator()          { create("airspeed-indicator"); }
void InstancedSubsystemTests::testAltimeter()                  { create("altimeter"); }
void InstancedSubsystemTests::testAttitudeIndicator()          { create("attitude-indicator"); }
void InstancedSubsystemTests::testClock()                      { create("clock"); }
void InstancedSubsystemTests::testCommRadio()                  { create("comm-radio"); }
void InstancedSubsystemTests::testDME()                        { create("dme"); }
void InstancedSubsystemTests::testFGKR_87()                    { create("KR-87"); }
void InstancedSubsystemTests::testFGMarkerBeacon()             { create("marker-beacon"); }
void InstancedSubsystemTests::testFGNavRadio()                 { create("old-navradio"); }
void InstancedSubsystemTests::testGPS()                        { create("gps"); }
void InstancedSubsystemTests::testGSDI()                       { create("gsdi"); }
void InstancedSubsystemTests::testHeadingIndicator()           { create("heading-indicator"); }
void InstancedSubsystemTests::testHeadingIndicatorDG()         { create("heading-indicator-dg"); }
void InstancedSubsystemTests::testHeadingIndicatorFG()         { create("heading-indicator-fg"); }
void InstancedSubsystemTests::testHUD()                        { create("hud"); }
void InstancedSubsystemTests::testInstVerticalSpeedIndicator() { create("inst-vertical-speed-indicator"); }
void InstancedSubsystemTests::testKLN89()                      { create("kln89"); }
void InstancedSubsystemTests::testMagCompass()                 { create("magnetic-compass"); }
void InstancedSubsystemTests::testMasterReferenceGyro()        { create("master-reference-gyro"); }
void InstancedSubsystemTests::testMK_VIII()                    { create("mk-viii"); }
void InstancedSubsystemTests::testNavRadio()                   { create("nav-radio"); }
void InstancedSubsystemTests::testRadarAltimeter()             { create("radar-altimeter"); }
void InstancedSubsystemTests::testSlipSkidBall()               { create("slip-skid-ball"); }
void InstancedSubsystemTests::testTACAN()                      { create("tacan"); }
void InstancedSubsystemTests::testTCAS()                       { create("tcas"); }
void InstancedSubsystemTests::testTransponder()                { create("transponder"); }
void InstancedSubsystemTests::testTurnIndicator()              { create("turn-indicator"); }
void InstancedSubsystemTests::testVerticalSpeedIndicator()     { create("vertical-speed-indicator"); }
