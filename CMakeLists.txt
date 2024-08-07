cmake_minimum_required(VERSION 3.16)
project(planner)

message(STATUS "------------- [Build Type] ${CMAKE_BUILD_TYPE} ------------------")

if(CMAKE_BUILD_TYPE MATCHES "Debug")
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CMAKE_COMMAND} -E time")
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK "${CMAKE_COMMAND} -E time")
endif()

set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY true)
add_compile_options(-DNDEBUG)
add_definitions("-DUSE_CONAN")
if(${USE_CONAN} MATCHES "ON")
  include(cmake/Deps.cmake)
  include(cmake/toolchain_conan.cmake)
  include(cmake/pybind11Tools.cmake)

  find_package(glog REQUIRED)
  include_directories(${glog_INCLUDE_DIRS})

  find_package(Eigen3 REQUIRED)
  include_directories(${Eigen3_INCLUDE_DIRS})

  find_package(nlohmann_json REQUIRED)
  include_directories(${nlohmann_json_INCLUDE_DIRS})



  find_package(Protobuf REQUIRED)
  include_directories(${Protobuf_INCLUDE_DIRS})
  set(PROTOBUF_LIBRARIES ${Protobuf_LIBRARIES})

  find_package(osqp REQUIRED)
  include_directories(${osqp_INCLUDE_DIRS})

  find_package(libuuid REQUIRED)
  include_directories(${libuuid_INCLUDE_DIRS})

  find_package(OpenCV REQUIRED)
  include_directories(${opencv_INCLUDE_DIRS})

  find_package(base_component_library REQUIRED)
  include_directories(${base_component_library_INCLUDE_DIRS})

  find_package(determinism REQUIRED)
  list(FILTER determinism_LIBRARIES EXCLUDE REGEX ".+\:\:.+")
  include_directories(${determinism_INCLUDE_DIRS})

  find_package(hipp REQUIRED)
  include_directories(${hipp_INCLUDE_DIRS})
  set(hipp_local_LIBRARIES "${hipp_LIB_DIRS}/libhipp.so")
  message("hipp_local_LIBRARIES: ${hipp_local_LIBRARIES}")


  if ($ENV{MAZU_ARCH} MATCHES aarch64)
    find_package(compiler_runtime REQUIRED)
    include_directories(${compiler_runtime_INCLUDE_DIRS})
    set(compiler_runtime_LIBRARIES compiler_runtime::compiler_runtime)
  else()
    find_package(compiler_runtime_cpu REQUIRED)
    include_directories(${compiler_runtime_cpu_INCLUDE_DIRS})
    set(compiler_runtime_LIBRARIES ${compiler_runtime_cpu_LIBRARIES})
  endif()

  find_package(common_cyber REQUIRED)
  list(FILTER common_cyber_LIBRARIES EXCLUDE REGEX ".+\:\:.+")
  include_directories(${common_cyber_INCLUDE_DIRS})
  link_directories(${common_cyber_LIB_DIRS})

  find_package(parking_navigation REQUIRED)
  list(FILTER parking_navigation_LIBRARIES EXCLUDE REGEX ".+\:\:.+")
  include_directories(${parking_navigation_INCLUDE_DIRS})
  link_directories(${parking_navigation_LIB_DIRS})




endif()

if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "aarch64")
  set(CMAKE_CXX_FLAGS
      "${CMAKE_CXX_FLAGS} -g -std=c++17 -pipe -Wall -Wshadow=compatible-local -Wextra -Wno-sign-compare -Wno-unused-parameter -fopenmp -fPIC -pthread -march=armv8-a+crypto -Wno-ignored-qualifiers -Wno-unused-but-set-parameter -Werror=return-type"
  )
  if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
  else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
  endif()
  if (NOT NO_UT)
    set(WITH_TESTING "ON")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-access-control -ldl")
  endif()
else()
  set(CMAKE_CXX_FLAGS
  "${CMAKE_CXX_FLAGS} -g -std=c++17 -Werror=return-type -pipe -Wall -Wshadow=compatible-local -Wno-sign-compare -Wno-unused-parameter -Wno-maybe-uninitialized -Wno-misleading-indentation -Wno-deprecated-declarations -fopenmp -fPIC -pthread -Wl,--copy-dt-needed-entries"
  )
  if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
  else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")
  endif()
  if (NOT NO_UT)
    set(WITH_TESTING "ON")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-access-control")
  endif()
endif()

if ($ENV{run_gtest} MATCHES "1" )
    set(COVERAGE_CXX_FLAGS "-fprofile-arcs -ftest-coverage")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COVERAGE_CXX_FLAGS}")
endif()

if ($ENV{GPERF} MATCHES "1")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer")
endif()

set(BUILD_SHARED_LIBS true)

# include(${NIO_INSTALL_PREFIX}/share/cyber/cmake/cyber-export.cmake)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/feature_app/src/L2/fct_app)
add_definitions(-DBOOST_GEOMETRY_EXPERIMENTAL_ENABLE_INITIALIZER_LIST
                -DBOOST_GEOMETRY_OVERLAY_NO_THROW
                -DEIGEN_NO_DEBUG
                -DPCL_NO_PRECOMPILE
                -DROSCPP_USE_TCP_NODELAY)

if(NOT DEFINED CMAKE_SUPPRESS_DEVELOPER_WARNINGS)
     set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS 1 CACHE INTERNAL "No dev warnings")
endif()

enable_testing()

# uninstall target
if(NOT TARGET uninstall)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()

if(NOT (${USE_CONAN} MATCHES "ON"))
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} /integration/cmake)

link_directories(${NIO_INSTALL_PREFIX}/lib)



find_package(PROTOBUF REQUIRED)
find_package(OpenCV COMPONENTS core imgproc REQUIRED)
find_package(GTest REQUIRED)
include_directories(SYSTEM ${GTest_INCLUDE_DIRS})

#find_package(Eigen3 REQUIRED)
#include_directories(${EIGEN3_INCLUDE_DIR})
include_directories(SYSTEM "/integration/include/eigen3")

FIND_PACKAGE(Boost REQUIRED COMPONENTS thread filesystem)
IF (Boost_FOUND)
     INCLUDE_DIRECTORIES(SYSTEM ${Boost_INCLUDE_DIR})
     link_directories(${Boost_LIBRARY_DIRS})
ENDIF ()
else()
  find_package(COSINE REQUIRED)
  set(NIODDS_LIBRARIES ${NIODDS_LIBRARIES} ${COSINE_LIBRARIES})

  set(OpenCV_LIBRARIES ${OpenCV_LIBRARIES}
    opencv_core opencv_imgproc
  )
endif()

if ($ENV{MAZU_ARCH} MATCHES aarch64)
  # set(TVM_LIBRARIES tvm_core compiler_runtime)
  set(DWCUDA_LIBRARIES "")
  set(Driveworks_LIBRARIES "")
  set(NVINFER_LIBRARY "")
endif()


# Includes complied protobuf header files.
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/planner)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/feature_app)
include_directories(${NIO_INSTALL_PREFIX}/include/common)
include_directories(${NIO_INSTALL_PREFIX}/include)

set(FCT_APP_SHRD_INCLUDE
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/ahc/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/gn/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/long_control/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/heater/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/lib/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/param/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/fct/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/mil_shrd/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/ids_mil/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/mtn_sal/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/lon_ctrl/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/lat_ctrl/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/ldw/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/state_mil/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/mtnctrl_sal_sm/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/feature_autogen/mainstate/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/diagnostic/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/xcp
    ${CMAKE_SOURCE_DIR}/feature_app/src/xcp/net
    ${CMAKE_SOURCE_DIR}/feature_app/src/xcp/net/ncommon
    ${CMAKE_SOURCE_DIR}/feature_app/src/common_lib/ehy_math/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/common_lib/ehy_obf/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/cal/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/fct_app/api/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/feature_diag/diag_lib/include
    ${CMAKE_SOURCE_DIR}/feature_app/src/L2/feature_input
    CACHE INTERNAL ""
)
add_subdirectory(planner)
add_subdirectory(feature_app)
add_subdirectory(planner_app)

message("---------------------------------------------")
message(${PROJECT_NAME} " Configuration Summary")
message("Build type:                    ${CMAKE_BUILD_TYPE}")
message("---------------------------------------------")

install(FILES setup.bash
        DESTINATION share/planner)

install(FILES setup.bash
        DESTINATION share/feature_app)

install(DIRECTORY script
        DESTINATION bin)

# uninstall target
if(NOT TARGET uninstall)
    configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
            IMMEDIATE @ONLY)

    add_custom_target(uninstall
            COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()
