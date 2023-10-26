/*
 * Copyright (C) 2022 Keith Paterson
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

#include "test_VectorMath.hxx"

#include <cstring>
#include <memory>

#include <cppunit/TestAssert.h>

#include "config.h"
#include "test_suite/FGTestApi/testGlobals.hxx"

#include <AIModel/VectorMath.hxx>

using namespace flightgear;

// Set up function for each test.
void VectorMathTests::setUp()
{
}

// Clean up after each test.
void VectorMathTests::tearDown()
{
}

void VectorMathTests::testInnerTanget()
{
    double r1 = 10;
    double r2 = 10;
    // when the circles are dist appart the angle will be 45°
    double dist = 2 * r1 + 2 * r2;
    SGGeod m1 = SGGeod::fromDeg(9,51);
    SGGeod m2 = SGGeodesy::direct(m1, 90, dist);

    auto angles = VectorMath::innerTangentsAngle(m1, m2, r1, r2);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 60, angles[0], 0.1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 120, angles[1], 0.1);
}

void VectorMathTests::testInnerTangent2()
{
    double r1 = 10;
    double r2 = 10;
    // when the circles are dist appart the angle will be 45°
    double dist = 2 * r1 + 2 * r2;
    SGGeod m1 = SGGeod::fromDeg(9,51);
    SGGeod m2 = SGGeodesy::direct(m1, 0, dist);

    auto angles = VectorMath::innerTangentsAngle(m1, m2, r1, r2);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 330, angles[0], 0.1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 30, angles[1], 0.1);
}

void VectorMathTests::testOuterTanget()
{
    double r1 = 10;
    double r2 = 50;
    // when the circles are dist appart the angle will be 45°
    double dist = 40;
    SGGeod m1 = SGGeod::fromDeg(9,51);
    SGGeod m2 = SGGeodesy::direct(m1, 90, dist);

    auto angles = VectorMath::outerTangentsAngle(m1, m2, r1, r2);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 45, angles[0], 0.1);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 135, angles[1], 0.1);
}
