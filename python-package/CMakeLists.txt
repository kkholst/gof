cmake_minimum_required(VERSION 2.8.12)
set(target "gof_c")
project(${gof})

#set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
#set(CMAKE_BUILD_WITH_INSTALL_RPATH ON)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    message(STATUS "******************** Using ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif(CCACHE_FOUND)

find_package(PythonLibs QUIET)
include_directories(${PYTHON_INCLUDE_DIRS})
message(STATUS "PYTHON_LIBRARIES = ${PYTHON_LIBRARIES}")
message(STATUS "PYTHON_EXECUTABLE = ${PYTHON_EXECUTABLE}")
message(STATUS "PYTHON_INCLUDE_DIRS = ${PYTHON_INCLUDE_DIRS}")

find_package(Armadillo 9.500 QUIET)
if (ARMADILLO_FOUND)	
  MESSAGE ([Main]  " Armadillo FOUND")
else()
  MESSAGE ([Main]  " Using Armadillo included in this package")
  find_package(LAPACK REQUIRED)
  add_subdirectory(src/armadillo)
  include_directories(src/armadillo/include)
endif ()
MESSAGE( [Main] " ARMADILLO_LIBRARIES = ${ARMADILLO_LIBRARIES}")
MESSAGE( [Main] " ARMADILLO_INCLUDE_DIRS = ${ARMADILLO_INCLUDE_DIRS}")


################################################################################
# Tests
################################################################################

SET(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/gof")
SET(TEST_DIR "tests")
SET(TESTS
  #"${SOURCE_DIR}/lib.cpp"
  "${TEST_DIR}/test_main.cpp")
  "${TEST_DIR}/test_c.cpp")
SET(RUN_TESTS TRUE)   

if (RUN_TESTS) 

  # find_package(UnitTest++ QUIET)
  # if (UnitTest++_FOUND)	
  #   MESSAGE ([Main]  " UnitTest++ FOUND")
  # else()
  #   MESSAGE ([Main]  " Using UnitTest++ included in this package")
  #   set(UTPP_INCLUDE_TESTS_IN_BUILD OFF CACHE BOOL "unit test building disabled" FORCE)  
  #   add_subdirectory(src/unittest-cpp)
  #   include_directories(src/unittest-cpp)
  # endif()

  # add_executable("${PROJECT_NAME}_test" ${TESTS})
  # target_link_libraries("${PROJECT_NAME}_test" PRIVATE armadillo UnitTest++)

  find_package(Catch2 QUIET)
  if (UnitTest++_FOUND)	
    MESSAGE ([Main]  " UnitTest++ FOUND")
  else()
    MESSAGE ([Main]  " Using UnitTest++ included in this package")
    set(UTPP_INCLUDE_TESTS_IN_BUILD OFF CACHE BOOL "unit test building disabled" FORCE)  
    add_subdirectory(src/unittest-cpp)
    include_directories(src/unittest-cpp)
  endif()

  # add_executable("${PROJECT_NAME}_test" ${TESTS})
  # target_link_libraries("${PROJECT_NAME}_test" PRIVATE armadillo UnitTest++)
  
endif()

################################################################################
# Python bindings
################################################################################

find_package(pybind11 QUIET)
if (pybind11_FOUND)	
  MESSAGE ([Main]  " pybind11 FOUND")
else()
  MESSAGE ([Main]  " Using pybind11 included in this package")
  add_subdirectory(src/pybind11)
endif()

SET(LIBGOF_DIR "${CMAKE_SOURCE_DIR}/src/target-cpp")
FILE(GLOB LIBGOF_SRC ${LIBGOF_DIR}/*.cpp)
FILE(GLOB LIBGOF_HDR ${LIBGOF_DIR}/*.hpp)
MESSAGE( [Main] " LIBGOF_DIR = ${LIBGOF_DIR}")
include_directories(${LIBGOF_DIR} LIBGOF)

pybind11_add_module(__${target}__
  ${LIBGOF_SRC} ${LIBGOF_HDR}
  src/gof/interface.cpp
 )

target_link_libraries(__${target}__ PRIVATE armadillo)
 
if(APPLE)
  set_target_properties(__${target}__ PROPERTIES INSTALL_NAME_DIR "@rpath")
  set_target_properties(__${target}__ PROPERTIES INSTALL_RPATH "@loader_path")
else()
  set_target_properties(__${target}__ PROPERTIES INSTALL_RPATH "$ORIGIN")
  #set_target_properties(${target} PROPERTIES LINK_FLAGS "-shared")
endif()




