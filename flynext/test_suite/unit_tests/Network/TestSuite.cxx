/*
 * SPDX-FileCopyrightText: (C) 2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "config.h"

#if defined(ENABLE_SWIFT)

#include "test_swiftAircraftManager.hxx"
#include "test_swiftService.hxx"

// Set up the unit tests.
CPPUNIT_TEST_SUITE_NAMED_REGISTRATION(SwiftAircraftManagerTest, "Unit tests");
CPPUNIT_TEST_SUITE_NAMED_REGISTRATION(SwiftServiceTest, "Unit tests");

#endif