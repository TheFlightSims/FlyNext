/*
 * SPDX-FileCopyrightText: (C) 2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef FLIGHTGEAR_TEST_SWIFTSERVICE_H
#define FLIGHTGEAR_TEST_SWIFTSERVICE_H

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

class SwiftServiceTest : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(SwiftServiceTest);
    CPPUNIT_TEST(testService);
    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // Test
    void testService();
};


#endif //FLIGHTGEAR_TEST_SWIFTSERVICE_H
