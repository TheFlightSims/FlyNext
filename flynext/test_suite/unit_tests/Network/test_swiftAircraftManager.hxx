/*
 * SPDX-FileCopyrightText: (C) 2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef FLIGHTGEAR_TEST_SWIFTAIRCRAFTMANAGER_H
#define FLIGHTGEAR_TEST_SWIFTAIRCRAFTMANAGER_H

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

#include <AIModel/AIBase.hxx>


class SwiftAircraftManagerTest : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(SwiftAircraftManagerTest);
    CPPUNIT_TEST(testAircraftManager);
    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // Test
    void testAircraftManager();

    // Helper
    std::vector<SGSharedPtr<FGAIBase>> getAIList();
};


#endif //FLIGHTGEAR_TEST_SWIFTAIRCRAFTMANAGER_H
