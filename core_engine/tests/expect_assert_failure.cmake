# === A432, parte 2a (12/11/2026) — «assert falso => CTest rosso» (VERIFICA_REFEREE_A432_PARTE1, par. 3.1, A.14) ===
# Lanciato da CTest: cmake -DEXE=<eseguibile> -P expect_assert_failure.cmake (core_engine/CMakeLists.txt, il
# test test_assert_false_turns_red). L'eseguibile (tests/assert_false_probe.cpp) scrive una riga su stderr e poi
# incontra un assert() falso: deve finire male. Questo script fallisce (e CTest diventa rosso) se:
# - l'eseguibile non esiste (un percorso sbagliato non deve passare per buono);
# - la riga scritta prima dell'assert non e' arrivata (l'eseguibile non e' partito davvero);
# - l'eseguibile e' uscito con 0 (l'assert falso non ha fermato il processo: assert spenti o catena rotta).
# Non si usa WILL_FAIL sull'eseguibile nudo: un assert falso finisce con abort(), una terminazione anomala che
# WILL_FAIL non inverte. Con execute_process il risultato di una terminazione anomala e' un numero diverso da 0
# oppure un testo che descrive l'errore: in tutti e due i casi «non 0».
if(NOT DEFINED EXE)
  message(FATAL_ERROR "expect_assert_failure: manca -DEXE=<eseguibile>")
endif()
if(NOT EXISTS "${EXE}")
  message(FATAL_ERROR "expect_assert_failure: l'eseguibile non esiste: ${EXE}")
endif()

execute_process(
  COMMAND "${EXE}"
  RESULT_VARIABLE risultato
  OUTPUT_VARIABLE uscita
  ERROR_VARIABLE errori
)
message(STATUS "expect_assert_failure: risultato='${risultato}'")
message(STATUS "expect_assert_failure: stderr='${errori}'")

string(FIND "${errori}${uscita}" "ASSERT_FALSE_PROBE: prima dell'assert" primaDellAssert)
if(primaDellAssert EQUAL -1)
  message(FATAL_ERROR "expect_assert_failure: la riga prima dell'assert non e' arrivata: l'eseguibile non e' partito davvero (risultato='${risultato}')")
endif()
string(FIND "${errori}${uscita}" "DOPO l'assert" dopoLAssert)
if(NOT dopoLAssert EQUAL -1)
  message(FATAL_ERROR "expect_assert_failure: l'eseguibile ha passato l'assert falso: gli assert non fermano il processo")
endif()
if("${risultato}" STREQUAL "0")
  message(FATAL_ERROR "expect_assert_failure: l'eseguibile con l'assert falso e' uscito con 0: un assert falso non farebbe diventare rosso CTest")
endif()
message(STATUS "PASS expect_assert_failure: l'assert falso ha fermato il processo (risultato='${risultato}')")
