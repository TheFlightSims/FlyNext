/* 
SPDX-Copyright: James Turner
SPDX-License-Identifier: GPL-2.0-or-later 
*/


#include "test_condition.hxx"

#include <simgear/props/condition.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/exception.hxx>

#include <simgear/debug/logstream.hxx>

#include "test_suite/FGTestApi/testGlobals.hxx"

// Set up function for each test.
void SimgearConditionTests::setUp()
{
    // Create a property tree.
    tree = new SGPropertyNode;
}


// Clean up SimgearConditionTests each test.
void SimgearConditionTests::tearDown()
{
}


// Test property aliasing, to catch possible memory leaks.
void SimgearConditionTests::testEmptyCondition()
{
    auto config = FGTestApi::propsFromString(R"(<?xml version="1.0" encoding="UTF-8"?>
                                    <PropertyList>
                                       <enabled>/foo/bar</enabled>
                                    </PropertyList>
                                    )");

    sglog().setDeveloperMode(true);

    CPPUNIT_ASSERT_THROW(sgReadCondition(tree, config->getChild("enabled")), sg_exception);

    // repeat in non-developer mode; test the legacy behaviour
    sglog().setDeveloperMode(false);

    auto n2 = sgReadCondition(tree, config->getChild("enabled"));
    CPPUNIT_ASSERT(n2);
    CPPUNIT_ASSERT(n2->test());
}