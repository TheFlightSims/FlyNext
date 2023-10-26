/* 
SPDX-Copyright: James Turner
SPDX-License-Identifier: GPL-2.0-or-later 
*/

#pragma once


#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

#include <simgear/props/condition.hxx>
#include <simgear/props/propsfwd.hxx>

// The unit tests of the simgear property tree.
class SimgearConditionTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(SimgearConditionTests);
    CPPUNIT_TEST(testEmptyCondition);
    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // The tests.
    void testEmptyCondition();

private:
    // A property tree.
    SGPropertyNode_ptr tree;
};
