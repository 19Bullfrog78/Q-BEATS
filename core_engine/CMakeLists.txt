cmake_minimum_required(VERSION 3.15)
project(LiveHostCoreEngine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(run_tests
    MetronomeDSP.cpp
    test_main.cpp
)
