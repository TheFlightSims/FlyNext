/*
 * SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

#include <simgear/timing/sg_time.hxx>

// The unit tests of the simgear property tree.
class SimgearTimingTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(SimgearTimingTests);
    CPPUNIT_TEST(testBadZoneDetectPosition);
    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // The tests.
    void testBadZoneDetectPosition();

private:

};
