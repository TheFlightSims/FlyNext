/*
 * SPDX-FileName: test_Commands.cxx
 * SPDX-FileComment: Unit tests for built-in commands
 * SPDX-FileCopyrightText: Copyright (C) 2023  James Turner
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "test_commands.hxx"
#include "config.h"

#include <simgear/structure/commands.hxx>

#include "Main/fg_commands.hxx"
#include "Main/fg_props.hxx"
#include "Main/globals.hxx"

#include "test_suite/FGTestApi/testGlobals.hxx"

using namespace std::string_literals;
using namespace flightgear;

void CommandsTests::setUp()
{
    FGTestApi::setUp::initTestGlobals("commands");
    fgLoadProps("defaults.xml", globals->get_props());

    fgInitCommands();
}

void CommandsTests::tearDown()
{
    delete SGCommandMgr::instance();
}

void CommandsTests::testPropertyAdjustCommand()
{
    auto propAdjust = SGCommandMgr::instance()->getCommand("property-adjust");

    {
        fgSetDouble("/foo", 10.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setDoubleValue("step", 1.0);
        CPPUNIT_ASSERT((*propAdjust)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-adjust step failed", 11.0, fgGetDouble("/foo"), 0.0001);
    }

    {
        fgSetDouble("/foo", 10.0);
        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setDoubleValue("step", 5.0);
        arg->setDoubleValue("max", 12.0);
        CPPUNIT_ASSERT((*propAdjust)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-adjust step with max", 12.0, fgGetDouble("/foo"), 0.0001);
    }

    {
        fgSetDouble("/foo", 30.0);
        fgSetDouble("/wib/bar", 33.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setDoubleValue("step", 5.0);
        arg->setStringValue("max-prop", "/wib/bar");
        CPPUNIT_ASSERT((*propAdjust)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-adjust step with max from prop", 33.0, fgGetDouble("/foo"), 0.0001);
    }

    // check fallback code path if max-prop is missing
    {
        fgSetDouble("/foo", 30.0);
        fgSetDouble("/wib/bar", 33.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setDoubleValue("step", 5.0);
        arg->setStringValue("max-prop", "/wib/xxxbar");
        arg->setDoubleValue("max", 34.0);
        CPPUNIT_ASSERT((*propAdjust)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-adjust step with max from prop", 34.0, fgGetDouble("/foo"), 0.0001);
    }
}

void CommandsTests::testPropertyMultiplyCommand()
{
    auto cmd = SGCommandMgr::instance()->getCommand("property-multiply");

    {
        fgSetDouble("/foo", 10.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setDoubleValue("factor", 4.0);
        CPPUNIT_ASSERT((*cmd)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-multiply failed", 40.0, fgGetDouble("/foo"), 0.0001);
    }

    {
        fgSetDouble("/foo", 10.0);
        fgSetDouble("/bar", 5.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");
        arg->setStringValue("factor-prop", "/bar");
        CPPUNIT_ASSERT((*cmd)(arg, globals->get_props()));

        CPPUNIT_ASSERT_DOUBLES_EQUAL_MESSAGE("property-multiply failed", 50.0, fgGetDouble("/foo"), 0.0001);
    }

    // missing factor
    {
        fgSetDouble("/foo", 10.0);

        SGPropertyNode_ptr arg(new SGPropertyNode);
        arg->setStringValue("property", "/foo");

        // check the command fails
        CPPUNIT_ASSERT(!(*cmd)(arg, globals->get_props()));
    }
}