cmake_minimum_required(VERSION 3.0)

project(MyUtil)

# Set C++ standard to C++11 (or the version you prefer)
set(CMAKE_CXX_STANDARD 11)

# Source code
set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)

# Include the directory containing source files
include_directories(${SRC_DIR})  # Use include_directories to add the directory

# Find the Boost libraries
find_package(Boost REQUIRED)

if(Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    add_executable(main main.cpp)
    target_link_libraries(main ${Boost_LIBRARIES})
else()
    message(FATAL_ERROR "Boost library not found. Please install Boost or adjust CMake configuration.")
endif()
