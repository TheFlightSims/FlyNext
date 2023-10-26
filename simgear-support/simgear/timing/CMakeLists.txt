

include (SimGearComponent)

set(HEADERS 
    sg_time.hxx
    timestamp.hxx
    timezone.h
    zonedetect.h
    lowleveltime.h
    rawprofile.hxx
    )
    
set(SOURCES 
    lowleveltime.cxx
    sg_time.cxx
    timestamp.cxx
    timezone.cxx
    zonedetect.c
    )

if(ENABLE_TESTS)
    function(create_test TEST_NAME)
        add_executable(${TEST_NAME} ${TEST_NAME}.cxx)
        target_link_libraries(${TEST_NAME} SimGearCore)
        set_target_properties(${TEST_NAME} PROPERTIES
            COMPILE_DEFINITIONS "SRC_DIR=\"${CMAKE_CURRENT_SOURCE_DIR}\"" )

        # for simgear_config.h
        target_include_directories(${TEST_NAME} PRIVATE ${PROJECT_BINARY_DIR}/simgear)
    endfunction()

    create_test(zonetest)
endif()

simgear_component(timing timing "${SOURCES}" "${HEADERS}")
