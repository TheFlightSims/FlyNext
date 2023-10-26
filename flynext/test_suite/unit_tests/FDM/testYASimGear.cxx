#include "testYASimGear.hxx"

#include "test_suite/FGTestApi/testGlobals.hxx"

#include "FDM/YASim/Gear.hpp"

#include <simgear/debug/logstream.hxx>

#include <sstream>


void YASimGearTests::setUp()
{
    FGTestApi::setUp::initTestGlobals("");
}

void YASimGearTests::tearDown()
{
    FGTestApi::tearDown::shutdownTestGlobals();
}


void YASimGearTests::test()
{
    /* Check we get expected values for a particular set of inputs. */
    
    float ground[4] = { -0.22097, 0.00507429, -0.975263, 2.35943};
    float wheel_pos[3] = { -0.953044, 2.20823, -2.00883};
    yasim::GearVector wheel_axle( -0, 0.16383, -0.114715);
    float wheel_radius = 0.261257;
    float tyre_radius = 0.130629;
    yasim::GearVector   compression( -0.139389, -0, 0.480178);
    
    float contact[3];
    float compress_distance_vertical;
    float compress_norm;
    
    bool on_ground = yasim::gearCompression(
            ground,
            compression,
            wheel_pos,
            wheel_axle,
            wheel_radius,
            tyre_radius,
            [] () { return 0; },
            
            /* output params: */
            contact,
            compress_distance_vertical,
            compress_norm
            );
    
    SG_LOG( SG_GENERAL, SG_ALERT, "on_ground=" << on_ground);
    SG_LOG( SG_GENERAL, SG_ALERT, "contact=(" << contact[0] << ", " << contact[1] << ", " << contact[1] << ")");
    SG_LOG( SG_GENERAL, SG_ALERT, "compress_distance_vertical=" << compress_distance_vertical);
    SG_LOG( SG_GENERAL, SG_ALERT, "compress_norm=" << compress_norm);
    
    double e = 0.0001;
    CPPUNIT_ASSERT( on_ground);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( -1.1053, contact[0], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 2.0645, contact[1], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( -2.1581, contact[2], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 0.167955, compress_distance_vertical, e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( 0.383887, compress_norm, e);
    
    
    /* Now check we get same results as old point-contact algorithm, when using
    wheel_radius=0 and tyre_radius=0. */
    
    /* For this test we set gear contact point to bottom of what was the wheel,
    so that it will be approximately in same position as earlier contact point,
    and so slightly underground. */
    wheel_pos[2] -= wheel_radius + tyre_radius;
    
    float bump_altitude_override = 0.1;
    
    on_ground = yasim::gearCompression(
            ground,
            compression,
            wheel_pos /* contact point. */,
            wheel_axle /* values don't matter. */,
            0 /*wheel_radius*/,
            0 /*tyre_radius*/,
            [bump_altitude_override] () { return bump_altitude_override; },
            
            /* output params: */
            contact,
            compress_distance_vertical,
            compress_norm
            );
    
    float contact_old[3];
    float compress_distance_vertical_old;
    float compress_norm_old;
    
    bool on_ground_old = yasim::gearCompressionOld(
            ground,
            compression,
            wheel_pos /* contact point. */,
            [bump_altitude_override] () { return bump_altitude_override; },
            
            /* output params: */
            contact_old,
            compress_distance_vertical_old,
            compress_norm_old
            );
    
    SG_LOG( SG_GENERAL, SG_ALERT, "comparing with old algorithm.");
    SG_LOG( SG_GENERAL, SG_ALERT, "old:");
    SG_LOG( SG_GENERAL, SG_ALERT, "    on_ground_old=" << on_ground_old);
    SG_LOG( SG_GENERAL, SG_ALERT, "    contact=(" << contact_old[0] << ", " << contact_old[1] << ", " << contact_old[1] << ")");
    SG_LOG( SG_GENERAL, SG_ALERT, "    compress_distance_vertical=" << compress_distance_vertical_old);
    SG_LOG( SG_GENERAL, SG_ALERT, "    compress_norm=" << compress_norm_old);
    SG_LOG( SG_GENERAL, SG_ALERT, "new:");
    SG_LOG( SG_GENERAL, SG_ALERT, "    on_ground=" << on_ground);
    SG_LOG( SG_GENERAL, SG_ALERT, "    contact=(" << contact[0] << ", " << contact[1] << ", " << contact[1] << ")");
    SG_LOG( SG_GENERAL, SG_ALERT, "    compress_distance_vertical=" << compress_distance_vertical);
    SG_LOG( SG_GENERAL, SG_ALERT, "    compress_norm=" << compress_norm);
    
    CPPUNIT_ASSERT( on_ground);
    CPPUNIT_ASSERT_EQUAL( on_ground_old, on_ground);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( contact_old[0], contact[0], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( contact_old[1], contact[1], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( contact_old[2], contact[2], e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( compress_distance_vertical_old, compress_distance_vertical, e);
    CPPUNIT_ASSERT_DOUBLES_EQUAL( compress_norm_old, compress_norm, e);
}

