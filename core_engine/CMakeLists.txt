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

# A432, parte 2a — il battito in attesa mai nel passato (VERIFICA_REFEREE_A432_PARTE1, par. 3.2): la sonda
# dell'auditor, i casi del mezzo campione di setBeatPosition, la prova a tappeto dopo ogni setter.
add_executable(test_pending_beat_never_past
    tests/test_pending_beat_never_past.cpp
    MetronomeDSP.cpp
    beat_tracker/TempoMap.cpp
)
target_include_directories(test_pending_beat_never_past PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# A432, parte 2a — la prova che un assert() falso fa diventare rosso CTest (par. 3.1, A.14). Non e' un banco:
# e' un eseguibile che deve finire male; lo lancia lo script tests/expect_assert_failure.cmake (piu' sotto).
add_executable(assert_false_probe
    tests/assert_false_probe.cpp
)
target_include_directories(assert_false_probe PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

enable_testing()
add_test(NAME metronome_dsp_tests COMMAND metronome_dsp_tests)
add_test(NAME test_midi_sequencer COMMAND test_midi_sequencer)
add_test(NAME test_tempo_map COMMAND test_tempo_map)
add_test(NAME test_reference_analyzer COMMAND test_reference_analyzer)
add_test(NAME test_adaptive_follower COMMAND test_adaptive_follower)
add_test(NAME test_rename_pending_beat COMMAND test_rename_pending_beat)
add_test(NAME test_pending_beat COMMAND test_pending_beat)
add_test(NAME test_assert_sentinel COMMAND test_assert_sentinel)
add_test(NAME test_pending_beat_never_past COMMAND test_pending_beat_never_past)
# Non con WILL_FAIL sull'eseguibile nudo: un assert falso finisce con abort(), una terminazione anomala che
# WILL_FAIL non inverte. Lo script lancia l'eseguibile con execute_process e fallisce se esce con 0, se non
# esiste o se la riga scritta prima dell'assert non arriva.
add_test(NAME test_assert_false_turns_red
    COMMAND ${CMAKE_COMMAND} -DEXE=$<TARGET_FILE:assert_false_probe>
            -P ${CMAKE_CURRENT_SOURCE_DIR}/tests/expect_assert_failure.cmake)
