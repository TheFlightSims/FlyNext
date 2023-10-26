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


#pragma once

#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

#include "test_suite/FGTestApi/testGlobals.hxx"

#include "Main/options.hxx"

// The system tests.
class OptionsTests : public CppUnit::TestFixture
{
    // Set up the test suite.
    CPPUNIT_TEST_SUITE(OptionsTests);
    CPPUNIT_TEST(testLoadDefaultAircraft);
    CPPUNIT_TEST(testOptionAircraftWithAircraftDir);
    CPPUNIT_TEST(testOptionAircraftUnqualified);
    CPPUNIT_TEST(testOptionAircraftFullyQualified);
    CPPUNIT_TEST(testOptionAircraftWithFGAircraft);

    CPPUNIT_TEST(testDisableSound);
    CPPUNIT_TEST(testDisableSoundByFalseWithSpaceSeparator);
    CPPUNIT_TEST(testDisableSoundBy0WithSpaceSeparator);
    CPPUNIT_TEST(testDisableSoundByNoWithSpaceSeparator);
    CPPUNIT_TEST(testDisableSoundByFalseWithEqualSeparator);
    CPPUNIT_TEST(testDisableSoundBy0WithEqualSeparator);
    CPPUNIT_TEST(testDisableSoundByNoWithEqualSeparator);

    CPPUNIT_TEST(testEnableSound);
    CPPUNIT_TEST(testEnableSoundWithoutValue);
    CPPUNIT_TEST(testEnableSoundWithIncorrectValue);
    CPPUNIT_TEST(testEnableSoundByTrueWithSpaceSeparator);
    CPPUNIT_TEST(testEnableSoundBy1WithSpaceSeparator);
    CPPUNIT_TEST(testEnableSoundByYesWithSpaceSeparator);
    CPPUNIT_TEST(testEnableSoundWithoutValueWithSpaceSeparator);
    CPPUNIT_TEST(testEnableSoundWithIncorrectValueWithEqualSeparator);
    CPPUNIT_TEST(testEnableSoundByTrueWithEqualSeparator);
    CPPUNIT_TEST(testEnableSoundBy1WithEqualSeparator);
    CPPUNIT_TEST(testEnableSoundByYesWithEqualSeparator);

    CPPUNIT_TEST(testDisableFreeze);
    CPPUNIT_TEST(testDisableFreezeByFalseWithSpaceSeparator);
    CPPUNIT_TEST(testDisableFreezeBy0WithSpaceSeparator);
    CPPUNIT_TEST(testDisableFreezeByNoWithSpaceSeparator);
    CPPUNIT_TEST(testDisableFreezeByFalseWithEqualSeparator);
    CPPUNIT_TEST(testDisableFreezeBy0WithEqualSeparator);
    CPPUNIT_TEST(testDisableFreezeByNoWithEqualSeparator);

    CPPUNIT_TEST(testEnableFreeze);
    CPPUNIT_TEST(testEnableFreezeWithoutValue);
    CPPUNIT_TEST(testEnableFreezeWithIncorrectValue);
    CPPUNIT_TEST(testEnableFreezeByTrueWithSpaceSeparator);
    CPPUNIT_TEST(testEnableFreezeBy1WithSpaceSeparator);
    CPPUNIT_TEST(testEnableFreezeByYesWithSpaceSeparator);
    CPPUNIT_TEST(testEnableFreezeWithoutValueWithEqualSeparator);
    CPPUNIT_TEST(testEnableFreezeWithIncorrectValueWithEqualSeparator);
    CPPUNIT_TEST(testEnableFreezeByTrueWithEqualSeparator);
    CPPUNIT_TEST(testEnableFreezeBy1WithEqualSeparator);
    CPPUNIT_TEST(testEnableFreezeByYesWithEqualSeparator);

    CPPUNIT_TEST(testPropWithEqualSeparator);
    CPPUNIT_TEST(testPropWithSpaceSeparator);

    CPPUNIT_TEST(testMetarWithEqualSeparator);
    CPPUNIT_TEST(testMetarWithSpaceSeparator);

    CPPUNIT_TEST(testXmlFileBetweenOptions);
    CPPUNIT_TEST(testGetArgValueWithSpaceSeparator);
    CPPUNIT_TEST(testGetArgValueWithEqualSeparator);
    CPPUNIT_TEST(testCheckForArgEnable);
    CPPUNIT_TEST(testCheckForArgEnableByTrueWithSpaceSeparator);
    CPPUNIT_TEST(testCheckForArgEnableByTrueWithEqualSeparator);
    CPPUNIT_TEST(testCheckForArgDisableByFalseWithSpaceSeparator);
    CPPUNIT_TEST(testCheckForArgDisableByFalseWithEqualSeparator);
    CPPUNIT_TEST(testCheckForArgDisableMissingOption);
    CPPUNIT_TEST(testCheckForArgEnableMissingOption);

    CPPUNIT_TEST(testIsBoolOptionEnable);
    CPPUNIT_TEST(testIsBoolOptionEnableWithoutValue);
    CPPUNIT_TEST(testIsBoolOptionEnableWithIncorrectValue);
    CPPUNIT_TEST(testIsBoolOptionEnableByTrueWithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableBy1WithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableByYesWithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableWithoutValueWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableWithIncorrectValueWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableByTrueWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableBy1WithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableByYesWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionEnableMissingOption);

    CPPUNIT_TEST(testIsBoolOptionDisable);
    CPPUNIT_TEST(testIsBoolOptionDisableByFalseWithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableBy0WithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableByNoWithSpaceSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableByFalseWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableBy0WithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableByNoWithEqualSeparator);
    CPPUNIT_TEST(testIsBoolOptionDisableMissingOption);

    CPPUNIT_TEST_SUITE_END();

    flightgear::Options* runProcessOptions(const char* argv[]);
    int getElementsNumber(const char* argv[]);

public:
    // Set up function for each test.
    void setUp();

    // Clean up after each test.
    void tearDown();

    // The tests.
    void testOptionAircraftWithAircraftDir();
    void testOptionAircraftUnqualified();
    void testOptionAircraftFullyQualified();
    void testOptionAircraftWithFGAircraft();
    void testLoadDefaultAircraft();

    void testDisableSound();
    void testDisableSoundByFalseWithSpaceSeparator();
    void testDisableSoundBy0WithSpaceSeparator();
    void testDisableSoundByNoWithSpaceSeparator();
    void testDisableSoundByFalseWithEqualSeparator();
    void testDisableSoundBy0WithEqualSeparator();
    void testDisableSoundByNoWithEqualSeparator();
    
    void testEnableSound();
    void testEnableSoundWithoutValue();
    void testEnableSoundWithIncorrectValue();
    void testEnableSoundByTrueWithSpaceSeparator();
    void testEnableSoundBy1WithSpaceSeparator();
    void testEnableSoundByYesWithSpaceSeparator();
    void testEnableSoundWithoutValueWithSpaceSeparator();
    void testEnableSoundWithIncorrectValueWithEqualSeparator();
    void testEnableSoundByTrueWithEqualSeparator();
    void testEnableSoundBy1WithEqualSeparator();
    void testEnableSoundByYesWithEqualSeparator();

    void testDisableFreeze();
    void testDisableFreezeByFalseWithSpaceSeparator();
    void testDisableFreezeBy0WithSpaceSeparator();
    void testDisableFreezeByNoWithSpaceSeparator();
    void testDisableFreezeByFalseWithEqualSeparator();
    void testDisableFreezeBy0WithEqualSeparator();
    void testDisableFreezeByNoWithEqualSeparator();
    
    void testEnableFreeze();
    void testEnableFreezeWithoutValue();
    void testEnableFreezeWithIncorrectValue();
    void testEnableFreezeByTrueWithSpaceSeparator();
    void testEnableFreezeBy1WithSpaceSeparator();
    void testEnableFreezeByYesWithSpaceSeparator();
    void testEnableFreezeWithoutValueWithEqualSeparator();
    void testEnableFreezeWithIncorrectValueWithEqualSeparator();
    void testEnableFreezeByTrueWithEqualSeparator();
    void testEnableFreezeBy1WithEqualSeparator();
    void testEnableFreezeByYesWithEqualSeparator();

    void testPropWithEqualSeparator();
    void testPropWithSpaceSeparator();

    void testMetarWithEqualSeparator();
    void testMetarWithSpaceSeparator();

    void testXmlFileBetweenOptions();
    void testGetArgValueWithSpaceSeparator();
    void testGetArgValueWithEqualSeparator();
    
    void testCheckForArgEnable();
    void testCheckForArgEnableByTrueWithSpaceSeparator();
    void testCheckForArgEnableByTrueWithEqualSeparator();
    void testCheckForArgEnableMissingOption();

    void testCheckForArgDisableByFalseWithSpaceSeparator();
    void testCheckForArgDisableByFalseWithEqualSeparator();
    void testCheckForArgDisableMissingOption();

    void testIsBoolOptionEnable();
    void testIsBoolOptionEnableWithoutValue();
    void testIsBoolOptionEnableWithIncorrectValue();
    void testIsBoolOptionEnableByTrueWithSpaceSeparator();
    void testIsBoolOptionEnableBy1WithSpaceSeparator();
    void testIsBoolOptionEnableByYesWithSpaceSeparator();
    void testIsBoolOptionEnableWithoutValueWithEqualSeparator();
    void testIsBoolOptionEnableWithIncorrectValueWithEqualSeparator();
    void testIsBoolOptionEnableByTrueWithEqualSeparator();
    void testIsBoolOptionEnableBy1WithEqualSeparator();
    void testIsBoolOptionEnableByYesWithEqualSeparator();
    void testIsBoolOptionEnableMissingOption();

    void testIsBoolOptionDisable();
    void testIsBoolOptionDisableByFalseWithSpaceSeparator();
    void testIsBoolOptionDisableBy0WithSpaceSeparator();
    void testIsBoolOptionDisableByNoWithSpaceSeparator();
    void testIsBoolOptionDisableByFalseWithEqualSeparator();
    void testIsBoolOptionDisableBy0WithEqualSeparator();
    void testIsBoolOptionDisableByNoWithEqualSeparator();
    void testIsBoolOptionDisableMissingOption();
};
