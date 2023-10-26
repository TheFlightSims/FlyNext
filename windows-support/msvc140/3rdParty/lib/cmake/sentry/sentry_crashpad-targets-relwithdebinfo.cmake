#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "sentry_crashpad::crashpad_handler" for configuration "RelWithDebInfo"
set_property(TARGET sentry_crashpad::crashpad_handler APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(sentry_crashpad::crashpad_handler PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/bin/crashpad_handler.exe"
  )

list(APPEND _IMPORT_CHECK_TARGETS sentry_crashpad::crashpad_handler )
list(APPEND _IMPORT_CHECK_FILES_FOR_sentry_crashpad::crashpad_handler "${_IMPORT_PREFIX}/bin/crashpad_handler.exe" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
