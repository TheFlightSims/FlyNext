set(TESTSUITE_SOURCES
    ${TESTSUITE_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/TestSuite.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_instanced_creation.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_noninstanced_creation.cxx
    PARENT_SCOPE
)

set(TESTSUITE_HEADERS
    ${TESTSUITE_HEADERS}
    ${CMAKE_CURRENT_SOURCE_DIR}/test_instanced_creation.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/test_noninstanced_creation.hxx
    PARENT_SCOPE
)
