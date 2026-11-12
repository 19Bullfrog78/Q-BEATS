// === A432, parte 2a (12/11/2026) — LA PROVA CHE UN assert() FALSO FA DIVENTARE ROSSO CTEST (VERIFICA_REFEREE_A432_PARTE1, par. 3.1, A.14) ===
// Non e' un banco: e' un eseguibile che DEVE finire male. Scrive una riga su stderr, poi incontra un assert()
// falso. Lo lancia lo script expect_assert_failure.cmake (il test test_assert_false_turns_red di
// core_engine/CMakeLists.txt), che fallisce se questo eseguibile esce con 0, se non esiste, o se la riga prima
// dell'assert non e' arrivata. Cosi' la catena «assert falso => CTest rosso» e' provata a ogni run: se un giorno
// gli assert fossero spenti (NDEBUG) o non fermassero piu' il processo, questo eseguibile arriverebbe in fondo,
// uscirebbe con 0 e il test cadrebbe. Si compila con le stesse opzioni dei banchi (nessuna opzione per bersaglio).
#ifdef NDEBUG
#error "assert_false_probe: NDEBUG definito, gli assert() sarebbero spenti - compilare in Debug (-DCMAKE_BUILD_TYPE=Debug)"
#endif

#include <cassert>
#include <cstdio>

// Solo per una compilazione locale su Windows con la CRT di debug di MSVC: un assert() fallito andrebbe in una
// finestra modale; qui va su stderr e il processo esce (abort: codice 3). Nessun effetto sul runner della CI.
#if defined(_MSC_VER) && defined(_DEBUG)
#include <crtdbg.h>
#include <cstdlib>
static void assertSuStderr() {
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
}
#else
static void assertSuStderr() {}
#endif

// Il valore si legge a runtime: il compilatore non puo' togliere l'assert ne' il codice dopo.
static volatile int g_zero = 0;

int main() {
    assertSuStderr();
    // Su stderr, senza buffer: abort() puo' non svuotare i buffer di stdout.
    std::fprintf(stderr, "ASSERT_FALSE_PROBE: prima dell'assert\n");
    std::fflush(stderr);
    assert(g_zero == 1 && "assert_false_probe: questo assert e' falso apposta");
    std::fprintf(stderr, "ASSERT_FALSE_PROBE: DOPO l'assert - l'assert falso non ha fermato il processo\n");
    std::fflush(stderr);
    return 0;
}
