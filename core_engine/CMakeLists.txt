cmake_minimum_required(VERSION 3.15)
project(LiveHostCoreEngine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(metronome_dsp_tests
    MetronomeDSP.cpp
    MIDISequencer.cpp
    beat_tracker/TempoMap.cpp
    test_main.cpp
)

add_executable(test_midi_sequencer
    tests/test_midi_sequencer.cpp
    MIDISequencer.cpp
)
target_include_directories(test_midi_sequencer PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(test_tempo_map
    tests/test_tempo_map.cpp
    beat_tracker/TempoMap.cpp
    beat_tracker/TempoMapJSON.cpp
)
target_include_directories(test_tempo_map PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(test_reference_analyzer
    tests/test_reference_analyzer.cpp
    beat_tracker/TempoMap.cpp
    beat_tracker/ReferenceTempoAnalyzer.cpp
)
target_include_directories(test_reference_analyzer PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(test_adaptive_follower
    tests/test_adaptive_follower.cpp
    MetronomeDSP.cpp
    MIDISequencer.cpp
    beat_tracker/TempoMap.cpp
)
target_include_directories(test_adaptive_follower PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# A432 — i banchi del battito in attesa (P26, P31, P36) e la sentinella degli assert, con lo
# stesso schema dei banchi qui sopra: un eseguibile e un test per file. Si compilano in Debug
# (nessun NDEBUG): ogni file rifiuta NDEBUG con #error, e test_assert_sentinel prova a runtime
# che assert() valuta la sua espressione.
add_executable(test_rename_pending_beat
    tests/test_rename_pending_beat.cpp
    MetronomeDSP.cpp
    beat_tracker/TempoMap.cpp
)
target_include_directories(test_rename_pending_beat PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(test_pending_beat
    tests/test_pending_beat.cpp
    MetronomeDSP.cpp
    beat_tracker/TempoMap.cpp
)
target_include_directories(test_pending_beat PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(test_assert_sentinel
    tests/test_assert_sentinel.cpp
)
target_include_directories(test_assert_sentinel PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

enable_testing()
add_test(NAME metronome_dsp_tests COMMAND metronome_dsp_tests)
add_test(NAME test_midi_sequencer COMMAND test_midi_sequencer)
add_test(NAME test_tempo_map COMMAND test_tempo_map)
add_test(NAME test_reference_analyzer COMMAND test_reference_analyzer)
add_test(NAME test_adaptive_follower COMMAND test_adaptive_follower)
add_test(NAME test_rename_pending_beat COMMAND test_rename_pending_beat)
add_test(NAME test_pending_beat COMMAND test_pending_beat)
add_test(NAME test_assert_sentinel COMMAND test_assert_sentinel)
