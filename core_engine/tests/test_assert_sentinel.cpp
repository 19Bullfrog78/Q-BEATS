// === A432 (09/11/2026) — LA SENTINELLA DEGLI ASSERT DEL BANCO DI core_engine (P31) ===
// I banchi di core_engine segnalano gli errori solo con assert(), che con NDEBUG definito non fa
// niente: una compilazione senza assert passerebbe in silenzio. Questo file, come ogni banco nuovo
// di A432, si rifiuta di compilare con NDEBUG, e a runtime prova che assert() valuta la sua
// espressione. Si compila con le stesse opzioni dei banchi di oggi (core_engine/CMakeLists.txt).
#ifdef NDEBUG
#error "core_engine/tests: NDEBUG definito, gli assert() del banco sarebbero spenti - compilare in Debug (-DCMAKE_BUILD_TYPE=Debug)"
#endif

#include <cassert>
#include <cstdio>

// Solo per una compilazione locale su Windows con la CRT di debug di MSVC: un assert() fallito andrebbe in una
// finestra modale; qui va su stderr e il processo esce, come su macOS. Nessun effetto sul runner della CI.
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

static int g_valutazioni = 0;

static bool segna() {
    ++g_valutazioni;
    return true;
}

int main() {
    assertSuStderr();
    assert(segna());
    if (g_valutazioni != 1) {
        std::printf("FAIL test_assert_sentinel: assert() non ha valutato la sua espressione (valutazioni=%d)\n",
                    g_valutazioni);
        return 1;
    }
    std::printf("PASS test_assert_sentinel: assert() attivo, NDEBUG non definito (valutazioni=%d)\n",
                g_valutazioni);
    return 0;
}
