set(TESTSUITE_SOURCES
    ${TESTSUITE_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/TestSuite.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_props.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_condition.cxx
    PARENT_SCOPE
)

set(TESTSUITE_HEADERS
    ${TESTSUITE_HEADERS}
    ${CMAKE_CURRENT_SOURCE_DIR}/test_props.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_condition.hxx
    PARENT_SCOPE
)
