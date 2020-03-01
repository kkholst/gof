cmake_minimum_required(VERSION 2.8.12)
project("gof")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/config")
#SET(CMAKE_CXX_FLAGS_DEBUG "-O0")
#SET(CMAKE_C_FLAGS_DEBUG "-O0")
#set(CMAKE_BUILD_TYPE Debug) # non-optimized code with debug symbols
#set(CMAKE_BUILD_TYPE RelWithDebInfo)
#set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif(CCACHE_FOUND)

find_package(Armadillo 9.500 QUIET)
if (ARMADILLO_FOUND)	
  MESSAGE ([Main]  " Armadillo FOUND")
else()
  MESSAGE ([Main]  " Using Armadillo included in this package")
  find_package(LAPACK REQUIRED)
  add_subdirectory("lib/armadillo")
  include_directories("lib/armadillo")
endif ()
MESSAGE( [Main] " ARMADILLO_LIBRARIES = ${ARMADILLO_LIBRARIES}")
MESSAGE( [Main] " ARMADILLO_INCLUDE_DIRS = ${ARMADILLO_INCLUDE_DIRS}")

find_package(Catch2 QUIET)
if (Catch2_FOUND)	
  MESSAGE ([Main]  " Catch2 FOUND")
else()
  MESSAGE ([Main]  " Using Catch2 included in this package")
  add_subdirectory("lib/catch2")
  include_directories("lib/catch2")
endif()

# find_package(spdlog QUIET)
# if (spdlog_FOUND)	
#   MESSAGE ([Main]  " spdlog FOUND")
# else()
MESSAGE ([Main]  " Using spdlog included in this package")
add_subdirectory("lib/spdlog")
include_directories("lib/spdlog")
# endif()

################################################################################

SET(LIBGOF_DIR "${CMAKE_SOURCE_DIR}/src")
FILE(GLOB LIBGOF_SRC ${LIBGOF_DIR}/*.cpp)
FILE(GLOB LIBGOF_HDR ${LIBGOF_DIR}/*.hpp)
include_directories(${LIBGOF_DIR})
add_library(gof ${LIBGOF_SRC} ${LIBGOF_HDR})
MESSAGE( [Main] " LIBGOF_DIR = ${LIBGOF_DIR}")
target_link_libraries(gof PRIVATE armadillo)

################################################################################
# Executables
################################################################################

add_executable("crdemo" "misc/crdemo.cpp")
target_link_libraries("crdemo" PRIVATE armadillo gof)

################################################################################
# Tests
################################################################################

SET(TEST_DIR "tests")
SET(TESTS
  "${TEST_DIR}/test_main.cpp"
  "${TEST_DIR}/test_misc.cpp"
  "${TEST_DIR}/test_mlogit.cpp"
  )

add_executable("${PROJECT_NAME}_test" ${TESTS})
target_link_libraries("${PROJECT_NAME}_test" PRIVATE armadillo Catch2::Catch2 spdlog gof)

find_program( MEMORYCHECK_COMMAND valgrind )
set( MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full" )
include( CTest )
add_test(NAME "${PROJECT_NAME}_test" COMMAND "${PROJECT_NAME}_test")

add_custom_target(test_memcheck
    COMMAND ${CMAKE_CTEST_COMMAND} 
        --force-new-ctest-process --test-action memcheck
    COMMAND cat "${CMAKE_BINARY_DIR}/Testing/Temporary/MemoryChecker.*.log")

################################################################################
# Code coverage
################################################################################

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  message([DEBUG])
endif()
if(COVERAGE_BUILD AND CMAKE_COMPILER_IS_GNUCXX)
  message([CODE COVERAGE])
  include(CodeCoverage)
  append_coverage_compiler_flags()
  setup_target_for_coverage_lcov(
          NAME coverage
          EXECUTABLE ${PROJECT_NAME}_test
          EXCLUDE "./lib/*" "${PROJECT_SOURCE_DIR}/lib/*")
endif()



