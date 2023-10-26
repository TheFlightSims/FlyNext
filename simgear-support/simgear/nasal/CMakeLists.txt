
include (SimGearComponent)

add_definitions(-DSOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

set(HEADERS 
    naref.h
    nasal.h
    iolib.h
    NasalEmesaryInterface.hxx
    )

set(SOURCES 
    bitslib.c
    code.c
    codegen.c
    gc.c
    hash.c
    iolib.c
    lex.c
    lib.c
    mathlib.c
    misc.c
    parse.c
    string.c
    thread-posix.c
    thread-win32.c
    threadlib.c
    utf8lib.c
    vector.c
    code.h
    data.h
    parse.h
    NasalEmesaryInterface.cxx
    )

if (NOT WIN32)
  set(SOURCES ${SOURCES}
      unixlib.c
      )
endif(NOT WIN32)

simgear_component(nasal nasal "${SOURCES}" "${HEADERS}")

if(ENABLE_TESTS)

add_simgear_test(nasal-bin nasal-bin.c)

endif(ENABLE_TESTS)
