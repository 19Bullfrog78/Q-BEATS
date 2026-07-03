#include "MetronomeDSP.h"

#include <cassert>
#include <cstdio>
#include <vector>

// === B7-A3 — Test del follower adattivo (piano ratificato 03/07) ===
//
// NOTA DOMINIO (contratto ② in TempoMap.h): questi test alimentano il DSP
// sotto le precondizioni IMPOSTE dal setter — sourceSampleRate della mappa ==
// rate del DSP (rifiuto al set) e start allineato a 0 (attivazione →
// resetForStart(0) → play, nessun reposition con mappa attiva). Sotto queste
// precondizioni il contatore del metronomo È numericamente la posizione della
// base: il banco non può far emergere un mismatch di dominio — il contratto
// va rispettato a monte, al confine del wiring.
//
// PALETTO ANTI-CIRCOLARE (§7): gli attesi sono POSIZIONI LETTERALI
// precalcolate a mano in stesura (es. round(2880000/121) = 23802; la sequenza
// del gradino deriva dalla semantica ZOH-a-inizio-buffer, buffer 256, contata
// a mano). L'oracolo del test di equivalenza è il motore fixed ESISTENTE
// (path odierno, validato dai 18 test storici + device), non il follower.

// Colleziona nBeats posizioni assolute di beat (isBeat), mantenendo la
// posizione globale tra chiamate successive (fasi di uno stesso scenario).
static void collectBeats(MetronomeDSP& dsp, size_t nBeats, uint64_t& globalPos,
                         std::vector<uint64_t>& out, uint32_t bufSize = 256,
                         size_t maxBuffers = 200000) {
    const size_t target = out.size() + nBeats;
    for (size_t b = 0; b < maxBuffers && out.size() < target; ++b) {
        auto evs = dsp.processBuffer(bufSize);
        for (const auto& e : evs)
            if (e.isBeat) out.push_back(globalPos + e.offset);
        globalPos += bufSize;
    }
}

// ─── test_constant_map_equals_fixed_engine ──────────────────────────────────
static void test_constant_map_equals_fixed_engine() {
    // Oracolo INDIPENDENTE: il motore fixed esistente a 121. Il bpm iniziale
    // dell'istanza adaptive è VOLUTAMENTE diverso (90): deve vincere la mappa.
    MetronomeDSP fixedDsp(48000.0, 121.0);
    MetronomeDSP adaptDsp(48000.0, 90.0);
    TempoMap m;
    assert(TempoMap::make({{0, 121.0}}, 48000.0, m));
    assert(adaptDsp.setTempoMap(m));       // attivazione PRIMA del play (②)
    assert(adaptDsp.isAdaptiveActive());
    fixedDsp.resetForStart(0.0);
    adaptDsp.resetForStart(0.0);           // start allineato a 0 (②)

    std::vector<uint64_t> fixedBeats, adaptBeats;
    uint64_t posF = 0, posA = 0;
    collectBeats(fixedDsp, 300, posF, fixedBeats);
    collectBeats(adaptDsp, 300, posA, adaptBeats);
    assert(fixedBeats.size() == 300 && adaptBeats.size() == 300);
    // Sanity letterale (a mano): round(2880000/121) = 23802 — non 90 bpm.
    assert(adaptBeats[0] == 0 && adaptBeats[1] == 23802);
    for (size_t i = 0; i < 300; ++i)
        assert(adaptBeats[i] == fixedBeats[i]);
    printf("PASS test_constant_map_equals_fixed_engine\n");
}

// ─── test_step_map_no_lost_or_doubled_beat ──────────────────────────────────
static void test_step_map_no_lost_or_doubled_beat() {
    // Gradino espresso con due punti a 1 campione di distanza (la mappa è
    // lineare a tratti): piatta a 120 fino a 239999, poi 60 da 240000.
    // Attesi LETTERALI (a mano, semantica ZOH a inizio buffer, buffer 256):
    // il beat a 240000 era già schedulato e il suo incremento usa lo spb del
    // top di buffer 239872 (bpm ancora 120) → 264000 (lag di 1 beat,
    // ratificato: step preserva la fase); dal top 263936 bpm=60 → passi 48000.
    MetronomeDSP dsp(48000.0, 90.0);
    TempoMap m;
    assert(TempoMap::make({{0, 120.0}, {239999, 120.0}, {240000, 60.0}},
                          48000.0, m));
    assert(dsp.setTempoMap(m));
    dsp.resetForStart(0.0);

    std::vector<uint64_t> beats;
    uint64_t pos = 0;
    collectBeats(dsp, 15, pos, beats);
    const uint64_t expected[15] = {
        0, 24000, 48000, 72000, 96000, 120000, 144000, 168000, 192000,
        216000, 240000, 264000, 312000, 360000, 408000
    };
    assert(beats.size() == 15);            // nessun beat perso né raddoppiato
    for (size_t i = 0; i < 15; ++i)
        assert(beats[i] == expected[i]);
    printf("PASS test_step_map_no_lost_or_doubled_beat\n");
}

// ─── test_setter_rejections ─────────────────────────────────────────────────
static void test_setter_rejections() {
    MetronomeDSP dsp(48000.0, 120.0);
    TempoMap invalid;                      // vuota = non valida
    assert(!dsp.setTempoMap(invalid));
    TempoMap wrongRate;
    assert(TempoMap::make({{0, 121.0}}, 44100.0, wrongRate));
    assert(!dsp.setTempoMap(wrongRate));   // rate ≠ DSP → rifiuto (②)
    assert(!dsp.isAdaptiveActive());       // stato invariato sui rifiuti
    TempoMap ok;
    assert(TempoMap::make({{0, 121.0}}, 48000.0, ok));
    assert(dsp.setTempoMap(ok));
    assert(dsp.isAdaptiveActive());
    printf("PASS test_setter_rejections\n");
}

// ─── test_antiflip_guard_rt_counter ─────────────────────────────────────────
static void test_antiflip_guard_rt_counter() {
    // La guardia conta i BUFFER RT completati (contatore monotono, non
    // wall-clock): ≥2 processBuffer tra due flip riusciti. Primo flip libero
    // (nessuno slot mai letto in RT prima).
    MetronomeDSP dsp(48000.0, 120.0);
    TempoMap m1, m2;
    assert(TempoMap::make({{0, 120.0}}, 48000.0, m1));
    assert(TempoMap::make({{0, 100.0}}, 48000.0, m2));
    assert(dsp.setTempoMap(m1));           // 1° flip: ok senza buffer girati
    assert(!dsp.setTempoMap(m2));          // 0 buffer dal flip → rifiutato
    dsp.processBuffer(256);
    assert(!dsp.setTempoMap(m2));          // 1 buffer → ancora rifiutato
    dsp.processBuffer(256);
    assert(dsp.setTempoMap(m2));           // 2 buffer → accettato
    assert(!dsp.setTempoMap(m1));          // subito dopo: 0 dal nuovo flip → rifiutato
    printf("PASS test_antiflip_guard_rt_counter\n");
}

// ─── test_mode_transitions_no_stale_schedule ────────────────────────────────
static void test_mode_transitions_no_stale_schedule() {
    // bpm iniziale 240 (spb 12000) volutamente diverso da mappa (120) e da
    // entrambi gli schedule (100, 60): ogni spaziatura sbagliata romperebbe
    // i letterali sotto.
    MetronomeDSP dsp(48000.0, 240.0);
    dsp.scheduleBPMChange(100.0);          // stantio: NON deve MAI sparare
    TempoMap m;
    assert(TempoMap::make({{0, 120.0}}, 48000.0, m));
    assert(dsp.setTempoMap(m));            // l'ingresso in adaptive lo cancella
    dsp.resetForStart(0.0);

    std::vector<uint64_t> beats;
    uint64_t pos = 0;
    collectBeats(dsp, 9, pos, beats);      // adaptive: passi esatti da 24000
    for (size_t i = 0; i < 9; ++i)
        assert(beats[i] == (uint64_t)i * 24000);

    dsp.clearTempoMap();                   // uscita: ri-armo pulito
    assert(!dsp.isAdaptiveActive());
    collectBeats(dsp, 3, pos, beats);      // _bpm resta 120; niente 100 stantio
    assert(beats[9]  == 216000);
    assert(beats[10] == 240000);
    assert(beats[11] == 264000);

    dsp.scheduleBPMChange(60.0);           // un NUOVO schedule post-uscita funziona
    collectBeats(dsp, 3, pos, beats);
    assert(beats[12] == 288000);           // beat idx 12 = downbeat → swap consumato
    assert(beats[13] == 336000);           // da qui passi da 48000
    assert(beats[14] == 384000);
    printf("PASS test_mode_transitions_no_stale_schedule\n");
}

int main() {
    test_constant_map_equals_fixed_engine();
    test_step_map_no_lost_or_doubled_beat();
    test_setter_rejections();
    test_antiflip_guard_rt_counter();
    test_mode_transitions_no_stale_schedule();
    printf("\nALL TESTS PASSED\n");
    return 0;
}
