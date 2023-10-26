/* 
SPDX-Copyright: James Turner
SPDX-License-Identifier: GPL-2.0-or-later 
*/

#include "testInputValue.hxx"

#include <strstream>

#include "test_suite/FGTestApi/testGlobals.hxx"


#include <Autopilot/autopilot.hxx>
#include <Main/fg_props.hxx>
#include <Main/globals.hxx>
#include <simgear/misc/inputvalue.hxx>


#include <simgear/math/sg_random.hxx>
#include <simgear/props/props_io.hxx>

using namespace FGXMLAutopilot;

// Set up function for each test.
void InputValueTests::setUp()
{
    FGTestApi::setUp::initTestGlobals("ap-inputvalue");
}


// Clean up after each test.
void InputValueTests::tearDown()
{
    FGTestApi::tearDown::shutdownTestGlobals();
}


SGPropertyNode_ptr InputValueTests::configFromString(const std::string& s)
{
    SGPropertyNode_ptr config = new SGPropertyNode;

    std::istringstream iss(s);
    readProperties(iss, config);
    return config;
}

void InputValueTests::testPropertyPath()
{

    sg_srandom(999);

        auto config = configFromString(R"(<?xml version="1.0" encoding="UTF-8"?>
                                    <PropertyList>
                                       <property-path>/test/altitude-ft-node-path</property-path>
                                        <value>1.23</value>
                                    </PropertyList>
                                    )");

    fgSetString("/test/altitude-ft-node-path", "/test/a");
    fgSetDouble("/test/a", 0.5);

    simgear::Value_ptr valueA = new simgear::Value(*globals->get_props(), *config);

    CPPUNIT_ASSERT(valueA->is_enabled());
    // check value is not written back
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.5, valueA->get_value(), 0.001);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.5, fgGetDouble("/test/a"), 0.001);

    fgSetDouble("/test/a", 2.34);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(2.34, valueA->get_value(), 0.001);

    fgSetString("/test/altitude-ft-node-path", "blah");
    CPPUNIT_ASSERT(!valueA->is_enabled());
    // <value> is used
    CPPUNIT_ASSERT_DOUBLES_EQUAL(1.23, valueA->get_value(), 0.001);


    fgSetDouble("/foo/bpath", 99);
    fgSetString("/test/altitude-ft-node-path", "/foo/bpath");
    CPPUNIT_ASSERT(valueA->is_enabled());
    CPPUNIT_ASSERT_DOUBLES_EQUAL(99.0, valueA->get_value(), 0.001);
    
    fgSetDouble("/foo/bpath", -45.1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL(-45.1, valueA->get_value(), 0.001);
    
// start with different config
    auto config2 = configFromString(R"(<?xml version="1.0" encoding="UTF-8"?>
                                <PropertyList>
                                   <property-path>/test/indicated-knots-node-path</property-path>
                                </PropertyList>
                                )");

    simgear::Value_ptr valueB = new simgear::Value(*globals->get_props(), *config2);
    CPPUNIT_ASSERT(!valueB->is_enabled());
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, valueB->get_value(), 0.001);
    
    fgSetString("/test/indicated-knots-node-path", "/instruments/airspeed/output/knots");
    CPPUNIT_ASSERT(!valueB->is_enabled());
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, valueB->get_value(), 0.001);
    
    // create the property, but this does not trigger the change listener, so
    // stays invalid
    fgSetDouble("/instruments/airspeed/output/knots", 415);
    CPPUNIT_ASSERT(!valueB->is_enabled());
    CPPUNIT_ASSERT_DOUBLES_EQUAL(0.0, valueB->get_value(), 0.001);

    // set the path again (with some whitespace, which is trimmed)
    fgSetString("/test/indicated-knots-node-path", "  /instruments/airspeed/output/knots  ");
    CPPUNIT_ASSERT(valueB->is_enabled());
    CPPUNIT_ASSERT_DOUBLES_EQUAL(415.0, valueB->get_value(), 0.001);
    
    fgSetString("/test/indicated-knots-node-path", "");
    CPPUNIT_ASSERT(!valueB->is_enabled());

}
