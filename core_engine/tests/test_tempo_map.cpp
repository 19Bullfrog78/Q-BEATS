#include "beat_tracker/TempoMap.h"
#include "beat_tracker/TempoMapJSON.h"

#include <cassert>
#include <clocale>
#include <cstdio>
#include <initializer_list>
#include <limits>
#include <string>
#include <vector>

// NOTA DOMINIO CLOCK (contratto in TempoMap.h, ratifica referee 03/07 punto ④):
// tutte le posizioni passate a bpmAt in questi test sono POSIZIONI NELLA BASE
// in campioni @ sourceSampleRate (dominio nativo della mappa). Il banco NON
// può far emergere un mismatch di dominio (qui i numeri combaciano comunque):
// il contratto va rispettato a monte, al confine del wiring — non "provato" qui.

static TempoMap makeMap(std::initializer_list<TempoPoint> pts, double sr = 48000.0) {
    TempoMap m;
    const bool ok = TempoMap::make(std::vector<TempoPoint>(pts), sr, m);
    assert(ok);
    return m;
}

// ─── test_validation_rejects ────────────────────────────────────────────────
static void test_validation_rejects() {
    TempoMap m;
    // vuota
    assert(!TempoMap::make({}, 48000.0, m));
    // non ordinata
    assert(!TempoMap::make({{100, 120.0}, {50, 130.0}}, 48000.0, m));
    // offset duplicato
    assert(!TempoMap::make({{100, 120.0}, {100, 130.0}}, 48000.0, m));
    // bpm zero / negativo / NaN / inf
    assert(!TempoMap::make({{0, 0.0}}, 48000.0, m));
    assert(!TempoMap::make({{0, -121.0}}, 48000.0, m));
    assert(!TempoMap::make({{0, std::numeric_limits<double>::quiet_NaN()}}, 48000.0, m));
    assert(!TempoMap::make({{0, std::numeric_limits<double>::infinity()}}, 48000.0, m));
    // sample rate non valido
    assert(!TempoMap::make({{0, 121.0}}, 0.0, m));
    assert(!TempoMap::make({{0, 121.0}}, -48000.0, m));
    // oltre cap (kMaxPoints + 1 punti)
    std::vector<TempoPoint> big;
    for (size_t i = 0; i <= TempoMap::kMaxPoints; ++i)
        big.push_back({(uint64_t)i * 100, 120.0});
    assert(!TempoMap::make(std::move(big), 48000.0, m));

    // la mappa buona passa e riempie out
    assert(TempoMap::make({{0, 121.0}}, 48000.0, m));
    assert(m.isValid() && m.size() == 1);

    // su errore `out` resta INVARIATA (m è ancora la mappa buona di sopra)
    assert(!TempoMap::make({{0, 0.0}}, 48000.0, m));
    assert(m.isValid() && m.size() == 1 && m.bpmAt(0) == 121.0);

    printf("PASS test_validation_rejects\n");
}

// ─── test_bpmat_exact_and_midpoint ──────────────────────────────────────────
static void test_bpmat_exact_and_midpoint() {
    TempoMap m = makeMap({{0, 120.0}, {48000, 130.0}});
    assert(m.bpmAt(0)     == 120.0);   // punto esatto
    assert(m.bpmAt(48000) == 130.0);   // punto esatto
    assert(m.bpmAt(24000) == 125.0);   // midpoint: t=0.5 esatto
    printf("PASS test_bpmat_exact_and_midpoint\n");
}

// ─── test_bpmat_clamp_edges ─────────────────────────────────────────────────
static void test_bpmat_clamp_edges() {
    TempoMap m = makeMap({{1000, 120.0}, {2000, 140.0}});
    assert(m.bpmAt(0)      == 120.0);  // prima del primo punto → clamp
    assert(m.bpmAt(999)    == 120.0);
    assert(m.bpmAt(2000)   == 140.0);
    assert(m.bpmAt(999999) == 140.0);  // dopo l'ultimo punto → clamp
    printf("PASS test_bpmat_clamp_edges\n");
}

// ─── test_bpmat_single_point ────────────────────────────────────────────────
static void test_bpmat_single_point() {
    TempoMap m = makeMap({{500, 121.0}});
    assert(m.bpmAt(0)    == 121.0);
    assert(m.bpmAt(500)  == 121.0);
    assert(m.bpmAt(5000) == 121.0);
    printf("PASS test_bpmat_single_point\n");
}

// ─── test_bpmat_segment_selection ───────────────────────────────────────────
static void test_bpmat_segment_selection() {
    // Più segmenti: il binary search deve scegliere la coppia giusta.
    TempoMap m = makeMap({{0, 120.0}, {100, 140.0}, {200, 100.0}, {300, 100.0}});
    assert(m.bpmAt(50)  == 130.0);   // segmento 0→100:   120 + 0.5·(140−120)
    assert(m.bpmAt(150) == 120.0);   // segmento 100→200: 140 + 0.5·(100−140)
    assert(m.bpmAt(250) == 100.0);   // segmento piatto
    assert(m.bpmAt(100) == 140.0);   // punto esatto interno
    printf("PASS test_bpmat_segment_selection\n");
}

// ─── test_json_round_trip_exact ─────────────────────────────────────────────
static void test_json_round_trip_exact() {
    // bpm con decimali non rappresentabili finiti in base 2: il round-trip
    // deve comunque essere ESATTO bit-a-bit grazie a %.17g. Offset grande per
    // coprire l'intero senza segno oltre i 32 bit.
    TempoMap in = makeMap({{0, 121.0},
                           {44100, 121.0 + 1.0 / 3.0},
                           {123456789012345ULL, 0.1 + 0.2}}, 44100.0);
    const std::string j = tempomap_json::toJSON(in);
    TempoMap out;
    assert(tempomap_json::fromJSON(j, out));
    assert(out == in);
    printf("PASS test_json_round_trip_exact\n");
}

// ─── test_json_round_trip_cap_size ──────────────────────────────────────────
static void test_json_round_trip_cap_size() {
    // Mappa alla dimensione massima ratificata (kMaxPoints = 8192).
    std::vector<TempoPoint> pts;
    for (size_t i = 0; i < TempoMap::kMaxPoints; ++i)
        pts.push_back({(uint64_t)i * 4801, 60.0 + (double)(i % 200) * 0.37});
    TempoMap in;
    assert(TempoMap::make(std::move(pts), 48000.0, in));
    const std::string j = tempomap_json::toJSON(in);
    TempoMap out;
    assert(tempomap_json::fromJSON(j, out));
    assert(out == in);
    printf("PASS test_json_round_trip_cap_size\n");
}

// ─── test_json_whitespace_and_key_order ─────────────────────────────────────
static void test_json_whitespace_and_key_order() {
    // Whitespace libero + chiavi in ordine qualunque (il Codable Swift non
    // garantisce l'ordine delle chiavi).
    TempoMap out;
    const char* j =
        "  {\n"
        "    \"points\" : [ { \"bpm\" : 121.5 , \"sampleOffset\" : 0 } ,\n"
        "                  { \"sampleOffset\" : 48000 , \"bpm\" : 119 } ] ,\n"
        "    \"sourceSampleRate\" : 48000\n"
        "  }  ";
    assert(tempomap_json::fromJSON(j, out));
    assert(out.isValid() && out.size() == 2);
    assert(out.sourceSampleRate() == 48000.0);
    assert(out.bpmAt(0) == 121.5);
    assert(out.bpmAt(48000) == 119.0);
    printf("PASS test_json_whitespace_and_key_order\n");
}

// ─── test_json_rejects_malformed ────────────────────────────────────────────
static void test_json_rejects_malformed() {
    TempoMap keep = makeMap({{0, 100.0}});   // per verificare "out invariata"
    TempoMap out  = keep;
    const char* bad[] = {
        "",                                                          // vuoto
        "{",                                                         // troncato
        "{\"sourceSampleRate\":48000}",                              // manca points
        "{\"points\":[{\"sampleOffset\":0,\"bpm\":121}]}",           // manca rate
        "{\"sourceSampleRate\":48000,\"points\":[]}",                // serie vuota
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":0,\"bpm\":121}],\"extra\":1}",  // chiave fuori schema
        "{\"sourceSampleRate\":48000,\"sourceSampleRate\":44100,\"points\":[{\"sampleOffset\":0,\"bpm\":121}]}",  // chiave doppia
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":-5,\"bpm\":121}]}",             // offset negativo
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":0.5,\"bpm\":121}]}",            // offset non intero
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":0,\"bpm\":0}]}",                // bpm 0
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":100,\"bpm\":120},{\"sampleOffset\":50,\"bpm\":121}]}",  // non ordinata
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":0,\"bpm\":121},{\"sampleOffset\":0,\"bpm\":121}]}",     // offset duplicato
        "{\"sourceSampleRate\":48000,\"points\":[{\"sampleOffset\":0,\"bpm\":121}]} x",            // coda spuria
    };
    for (const char* s : bad) {
        assert(!tempomap_json::fromJSON(s, out));
        assert(out == keep);   // su errore la mappa resta invariata
    }
    printf("PASS test_json_rejects_malformed\n");
}

// ─── test_json_locale_independent ───────────────────────────────────────────
static void test_json_locale_independent() {
    // Trappola referee 03/07: con snprintf/strtod NUDI, in una locale con la
    // virgola (it-IT) encode e decode userebbero ENTRAMBI la virgola →
    // round-trip verde "in casa" ma JSON corrotto per qualsiasi lettore
    // standard e per qualsiasi processo con locale diversa. NB: il processo
    // del banco parte in locale "C" anche su Windows italiano, quindi SENZA
    // questo forcing il verde non proverebbe nulla. Qui forziamo it-IT e
    // pretendiamo il PUNTO nel JSON: se in futuro gli helper _l di
    // TempoMapJSON.cpp tornassero funzioni nude, questo test si rompe.
    const char* candidates[] = { "it-IT", "Italian_Italy.1252", "it_IT.UTF-8", "it_IT" };
    const char* cur = setlocale(LC_ALL, nullptr);
    const std::string saved = cur ? cur : "C";
    bool forced = false;
    for (const char* name : candidates) {
        if (setlocale(LC_ALL, name) != nullptr) { forced = true; break; }
    }
    if (!forced) {
        printf("SKIP test_json_locale_independent (nessuna locale italiana disponibile)\n");
        return;
    }

    TempoMap in = makeMap({{0, 121.5}, {48000, 119.25}});
    const std::string j = tempomap_json::toJSON(in);
    TempoMap out;
    const bool parsed = tempomap_json::fromJSON(j, out);
    setlocale(LC_ALL, saved.c_str());   // ripristina PRIMA degli assert

    // Scrittura: separatore decimale = PUNTO anche sotto it-IT.
    assert(j == "{\"sourceSampleRate\":48000,\"points\":["
                "{\"sampleOffset\":0,\"bpm\":121.5},"
                "{\"sampleOffset\":48000,\"bpm\":119.25}]}");
    // Lettura: il parser accetta il punto anche sotto it-IT.
    assert(parsed);
    assert(out == in);
    printf("PASS test_json_locale_independent\n");
}

int main() {
    test_validation_rejects();
    test_bpmat_exact_and_midpoint();
    test_bpmat_clamp_edges();
    test_bpmat_single_point();
    test_bpmat_segment_selection();
    test_json_round_trip_exact();
    test_json_round_trip_cap_size();
    test_json_whitespace_and_key_order();
    test_json_rejects_malformed();
    test_json_locale_independent();
    printf("\nALL TESTS PASSED\n");
    return 0;
}
