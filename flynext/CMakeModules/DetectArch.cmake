IF(CMAKE_SYSTEM_PROCESSOR MATCHES amd64.*|x86_64.* OR CMAKE_GENERATOR MATCHES "Visual Studio.*Win64")
  IF(CMAKE_C_FLAGS MATCHES -m32 OR CMAKE_CXX_FLAGS MATCHES -m32)
    SET(X86 1)
  ELSE(CMAKE_C_FLAGS MATCHES -m32 OR CMAKE_CXX_FLAGS MATCHES -m32)
    SET(X86_64 1)
  ENDIF(CMAKE_C_FLAGS MATCHES -m32 OR CMAKE_CXX_FLAGS MATCHES -m32)
ELSEIF(CMAKE_SYSTEM_PROCESSOR MATCHES i686.*|i386.*|x86.*)
  IF(CMAKE_C_FLAGS MATCHES -m64 OR CMAKE_CXX_FLAGS MATCHES -m64)
    SET(X86_64 1)
  ELSE(CMAKE_C_FLAGS MATCHES -m64 OR CMAKE_CXX_FLAGS MATCHES -m64)
    SET(X86 1)
  ENDIF(CMAKE_C_FLAGS MATCHES -m64 OR CMAKE_CXX_FLAGS MATCHES -m64)
ELSEIF(CMAKE_SYSTEM_PROCESSOR MATCHES arm.* AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    SET(ARM 1)
ELSEIF(CMAKE_SYSTEM_PROCESSOR MATCHES mips)
    SET(MIPS 1)
ENDIF()

IF ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
  # using Clang
  SET(CLANG 1)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "TinyCC")
  # using TinyCC
  SET(TINYCC 1)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
  # using GCC
  SET(GCC 1)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "Intel")
  # using Intel C++
  SET(INTELCC 1)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
  # using Visual Studio C++
  SET(MSVC 1)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "MIPSpro")
  # using SGI MIPSpro
  SET(MIPSPRO 1)
ENDIF()
