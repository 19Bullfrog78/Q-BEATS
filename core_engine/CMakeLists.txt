cmake_minimum_required(VERSION 3.15)
project(LiveHostCoreEngine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(metronome_dsp_tests
    MetronomeDSP.cpp
    MIDISequencer.cpp
    test_main.cpp
)

add_executable(test_midi_sequencer
    tests/test_midi_sequencer.cpp
    MIDISequencer.cpp
)
target_include_directories(test_midi_sequencer PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

enable_testing()
add_test(NAME test_midi_sequencer COMMAND test_midi_sequencer)
