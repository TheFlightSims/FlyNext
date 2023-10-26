/*
SPDX-Copyright: James Turner
SPDX-License-Identifier: GPL-2.0-or-later 
 */


#pragma once

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

#include <simgear/props/props.hxx>


// The system tests.
class InputValueTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(InputValueTests);
    CPPUNIT_TEST(testPropertyPath);
    CPPUNIT_TEST_SUITE_END();

    SGPropertyNode_ptr configFromString(const std::string& s);

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();


    // The tests.
    void testPropertyPath();
};
