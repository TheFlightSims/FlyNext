#include <cppunit/TestFixture.h>
#include <cppunit/extensions/HelperMacros.h>

struct YASimGearTests : CppUnit::TestFixture
{
    void setUp();

    void tearDown();

    void test();
    
    CPPUNIT_TEST_SUITE(YASimGearTests);
    CPPUNIT_TEST(test);
    CPPUNIT_TEST_SUITE_END();
};
