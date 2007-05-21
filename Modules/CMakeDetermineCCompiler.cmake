
# determine the compiler to use for C programs
# NOTE, a generator may set CMAKE_C_COMPILER before
# loading this file to force a compiler.
# use environment variable CC first if defined by user, next use 
# the cmake variable CMAKE_GENERATOR_CC which can be defined by a generator
# as a default compiler
# If the internal cmake variable _CMAKE_TOOLCHAIN_PREFIX is set, this is used 
# as prefix for the tools (e.g. arm-elf-gcc, arm-elf-ar etc.). This works
# currently with the GNU crosscompilers.
# It also tries to detect a MS crosscompiler and find out its 
# suffix (clarm.exe), which will be stored in _CMAKE_TOOLCHAIN_SUFFIX and
# reused for the CXX compiler.
#
#
# Sets the following variables: 
#   CMAKE_C_COMPILER
#   CMAKE_AR
#   CMAKE_RANLIB
#   CMAKE_COMPILER_IS_GNUCC
#
# If not already set before, it also sets
#   _CMAKE_TOOLCHAIN_PREFIX
#   _CMAKE_TOOLCHAIN_SUFFIX

IF(NOT CMAKE_C_COMPILER)
  SET(CMAKE_CXX_COMPILER_INIT NOTFOUND)

  # prefer the environment variable CC
  IF($ENV{CC} MATCHES ".+")
    GET_FILENAME_COMPONENT(CMAKE_C_COMPILER_INIT $ENV{CC} PROGRAM PROGRAM_ARGS CMAKE_C_FLAGS_ENV_INIT)
    IF(CMAKE_C_FLAGS_ENV_INIT)
      SET(CMAKE_C_COMPILER_ARG1 "${CMAKE_C_FLAGS_ENV_INIT}" CACHE STRING "First argument to C compiler")
    ENDIF(CMAKE_C_FLAGS_ENV_INIT)
    IF(NOT EXISTS ${CMAKE_C_COMPILER_INIT})
      MESSAGE(FATAL_ERROR "Could not find compiler set in environment variable CC:\n$ENV{CC}.") 
    ENDIF(NOT EXISTS ${CMAKE_C_COMPILER_INIT})
  ENDIF($ENV{CC} MATCHES ".+")

  # next try prefer the compiler specified by the generator
  IF(CMAKE_GENERATOR_CC) 
    IF(NOT CMAKE_C_COMPILER_INIT)
      SET(CMAKE_C_COMPILER_INIT ${CMAKE_GENERATOR_CC})
    ENDIF(NOT CMAKE_C_COMPILER_INIT)
  ENDIF(CMAKE_GENERATOR_CC)

  # finally list compilers to try
  IF(CMAKE_C_COMPILER_INIT)
    SET(CMAKE_C_COMPILER_LIST ${CMAKE_C_COMPILER_INIT})
  ELSE(CMAKE_C_COMPILER_INIT)
    SET(CMAKE_C_COMPILER_LIST ${_CMAKE_TOOLCHAIN_PREFIX}gcc ${_CMAKE_TOOLCHAIN_PREFIX}cc cl${_CMAKE_TOOLCHAIN_SUFFIX} bcc xlc)
  ENDIF(CMAKE_C_COMPILER_INIT)

  # Find the compiler.
  IF (_CMAKE_USER_CXX_COMPILER_PATH)
    FIND_PROGRAM(CMAKE_C_COMPILER NAMES ${CMAKE_C_COMPILER_LIST} PATHS ${_CMAKE_USER_CXX_COMPILER_PATH} DOC "C compiler" NO_DEFAULT_PATH)
  ENDIF (_CMAKE_USER_CXX_COMPILER_PATH)
  FIND_PROGRAM(CMAKE_C_COMPILER NAMES ${CMAKE_C_COMPILER_LIST} DOC "C compiler")
  
  IF(CMAKE_C_COMPILER_INIT AND NOT CMAKE_C_COMPILER)
    SET(CMAKE_C_COMPILER "${CMAKE_C_COMPILER_INIT}" CACHE FILEPATH "C compiler" FORCE)
  ENDIF(CMAKE_C_COMPILER_INIT AND NOT CMAKE_C_COMPILER)
ELSE(NOT CMAKE_C_COMPILER)

  # if a compiler was specified by the user but without path, 
  # now try to find it with the full path
  # if it is found, force it into the cache, 
  # if not, don't overwrite the setting (which was given by the user) with "NOTFOUND"
  # if the C compiler already had a path, reuse it for searching the CXX compiler
  GET_FILENAME_COMPONENT(_CMAKE_USER_C_COMPILER_PATH "${CMAKE_C_COMPILER}" PATH)
  IF(NOT _CMAKE_USER_C_COMPILER_PATH)
    FIND_PROGRAM(CMAKE_C_COMPILER_WITH_PATH NAMES ${CMAKE_C_COMPILER})
    MARK_AS_ADVANCED(CMAKE_C_COMPILER_WITH_PATH)
    IF(CMAKE_C_COMPILER_WITH_PATH)
      SET(CMAKE_C_COMPILER ${CMAKE_C_COMPILER_WITH_PATH} CACHE FILEPATH "C compiler" FORCE)
    ENDIF(CMAKE_C_COMPILER_WITH_PATH)
  ENDIF(NOT _CMAKE_USER_C_COMPILER_PATH)
ENDIF(NOT CMAKE_C_COMPILER)
MARK_AS_ADVANCED(CMAKE_C_COMPILER)

IF (NOT _CMAKE_TOOLCHAIN_LOCATION)
  GET_FILENAME_COMPONENT(_CMAKE_TOOLCHAIN_LOCATION "${CMAKE_C_COMPILER}" PATH)
ENDIF (NOT _CMAKE_TOOLCHAIN_LOCATION)

# if we have a gcc cross compiler, they have usually some prefix, like 
# e.g. powerpc-linux-gcc, arm-elf-gcc or i586-mingw32msvc-gcc
# the other tools of the toolchain usually have the same prefix
IF (NOT _CMAKE_TOOLCHAIN_PREFIX)
  GET_FILENAME_COMPONENT(COMPILER_BASENAME "${CMAKE_C_COMPILER}" NAME_WE)
  IF (COMPILER_BASENAME MATCHES "^(.+-)g?cc")
    STRING(REGEX REPLACE "^(.+-)g?cc"  "\\1" _CMAKE_TOOLCHAIN_PREFIX "${COMPILER_BASENAME}")
  ENDIF (COMPILER_BASENAME MATCHES "^(.+-)g?cc")
ENDIF (NOT _CMAKE_TOOLCHAIN_PREFIX)

# if we have a MS cross compiler, it usually has a suffix, like 
# e.g. clarm.exe or clmips.exe. Use this suffix for the CXX compiler too.
IF (NOT _CMAKE_TOOLCHAIN_SUFFIX)
  GET_FILENAME_COMPONENT(COMPILER_BASENAME "${CMAKE_C_COMPILER}" NAME)
  IF (COMPILER_BASENAME MATCHES "^cl(.+)\\.exe$")
    STRING(REGEX REPLACE "^cl(.+)\\.exe$"  "\\1" _CMAKE_TOOLCHAIN_SUFFIX "${COMPILER_BASENAME}")
  ENDIF (COMPILER_BASENAME MATCHES "^cl(.+)\\.exe$")
ENDIF (NOT _CMAKE_TOOLCHAIN_SUFFIX)

# some exotic compilers have different extensions (e.g. sdcc uses .rel)
# so don't overwrite it if it has been already defined by the user
IF(NOT CMAKE_C_OUTPUT_EXTENSION)
  IF(UNIX)
    SET(CMAKE_C_OUTPUT_EXTENSION .o)
  ELSE(UNIX)
    SET(CMAKE_C_OUTPUT_EXTENSION .obj)
  ENDIF(UNIX)
ENDIF(NOT CMAKE_C_OUTPUT_EXTENSION)


# Build a small source file to identify the compiler.
IF(${CMAKE_GENERATOR} MATCHES "Visual Studio")
  SET(CMAKE_C_COMPILER_ID_RUN 1)
  SET(CMAKE_C_PLATFORM_ID "Windows")

  # TODO: Set the compiler id.  It is probably MSVC but
  # the user may be using an integrated Intel compiler.
  # SET(CMAKE_C_COMPILER_ID "MSVC")
ENDIF(${CMAKE_GENERATOR} MATCHES "Visual Studio")

IF(NOT CMAKE_C_COMPILER_ID_RUN)
  SET(CMAKE_C_COMPILER_ID_RUN 1)

  # Try to identify the compiler.
  SET(CMAKE_C_COMPILER_ID)
  INCLUDE(${CMAKE_ROOT}/Modules/CMakeDetermineCompilerId.cmake)
  CMAKE_DETERMINE_COMPILER_ID(C CFLAGS ${CMAKE_ROOT}/Modules/CMakeCCompilerId.c)

  # Set old compiler and platform id variables.
  IF("${CMAKE_C_COMPILER_ID}" MATCHES "GNU")
    SET(CMAKE_COMPILER_IS_GNUCC 1)
  ENDIF("${CMAKE_C_COMPILER_ID}" MATCHES "GNU")
  IF("${CMAKE_C_PLATFORM_ID}" MATCHES "MinGW")
    SET(CMAKE_COMPILER_IS_MINGW 1)
  ELSEIF("${CMAKE_C_PLATFORM_ID}" MATCHES "Cygwin")
    SET(CMAKE_COMPILER_IS_CYGWIN 1)
  ENDIF("${CMAKE_C_PLATFORM_ID}" MATCHES "MinGW")
ENDIF(NOT CMAKE_C_COMPILER_ID_RUN)

INCLUDE(CMakeFindBinUtils)

# configure variables set in this file for fast reload later on
CONFIGURE_FILE(${CMAKE_ROOT}/Modules/CMakeCCompiler.cmake.in 
               "${CMAKE_PLATFORM_ROOT_BIN}/CMakeCCompiler.cmake" IMMEDIATE)

SET(CMAKE_C_COMPILER_ENV_VAR "CC")
