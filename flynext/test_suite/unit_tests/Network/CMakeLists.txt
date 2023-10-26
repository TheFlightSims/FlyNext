

if (ENABLE_SWIFT)
        set(SWIFT_TESTS_SOURCES 
                ${CMAKE_CURRENT_SOURCE_DIR}/test_swiftService.cxx
                ${CMAKE_CURRENT_SOURCE_DIR}/test_swiftAircraftManager.cxx
                )

        set(SWIFT_TESTS_HEADERS
                ${CMAKE_CURRENT_SOURCE_DIR}/test_swiftService.hxx
                ${CMAKE_CURRENT_SOURCE_DIR}/test_swiftAircraftManager.hxx
                )
endif()


set(TESTSUITE_SOURCES
        ${TESTSUITE_SOURCES}
        ${CMAKE_CURRENT_SOURCE_DIR}/TestSuite.cxx
        ${SWIFT_TESTS_SOURCES}
        PARENT_SCOPE
        )

set(TESTSUITE_HEADERS
        ${TESTSUITE_HEADERS}
        ${SWIFT_TESTS_HEADERS}
        PARENT_SCOPE
        )

