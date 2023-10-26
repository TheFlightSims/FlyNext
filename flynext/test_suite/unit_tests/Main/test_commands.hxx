/*
 * SPDX-FileName: test_Commands.hxx
 * SPDX-FileComment: Unit tests for built-in commands
 * SPDX-FileCopyrightText: Copyright (C) 2023  James Turner
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>


class CommandsTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(CommandsTests);
    CPPUNIT_TEST(testPropertyAdjustCommand);
    CPPUNIT_TEST(testPropertyMultiplyCommand);

    CPPUNIT_TEST_SUITE_END();

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // The tests.
    void testPropertyAdjustCommand();
    void testPropertyMultiplyCommand();

private:
};
