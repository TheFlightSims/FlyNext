set(TESTSUITE_SOURCES
    ${TESTSUITE_SOURCES}
    ${CMAKE_CURRENT_SOURCE_DIR}/TestSuite.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testDigitalFilter.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testPidController.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testPidControllerData.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testInputValue.cxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testMonostable.cxx
    PARENT_SCOPE
)

set(TESTSUITE_HEADERS
    ${TESTSUITE_HEADERS}
    ${CMAKE_CURRENT_SOURCE_DIR}/testDigitalFilter.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testPidController.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testPidControllerData.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testInputValue.hxx
    ${CMAKE_CURRENT_SOURCE_DIR}/testMonostable.hxx
    PARENT_SCOPE
)
