#include "beat_tracker/ReferenceTempoAnalyzer.h"

#include <cassert>
#include <cmath>
#include <cstdio>
#include <vector>

// PALETTO ANTI-CIRCOLARE (§7 — ratifica A2, referee 03/07): i click sono
// piazzati a POSIZIONI LETTERALI precalcolate a priori (fuori dal codice
// dell'analizzatore) e gli assert confrontano l'output con VALORI LETTERALI
// precalcolati a mano in fase di stesura (es. 2880000/23802 = 120.99824).
// Nessun assert ri-usa la matematica dell'analizzatore per produrre l'atteso.
// L'unica "formula" condivisa è la DEFINIZIONE di BPM (60·sr/IOI): è l'unità
// di misura del dominio, non l'algoritmo sotto test (envelope + picchi).

// Traccia di click sintetica: spike singoli (1.0f) alle posizioni date.
static std::vector<float> clickTrack(const std::vector<uint64_t>& positions,
                                     size_t length) {
    std::vector<float> buf(length, 0.0f);
    for (uint64_t p : positions)
        if (p < length) buf[(size_t)p] = 1.0f;
    return buf;
}

// ─── test_silence_zero_confidence ───────────────────────────────────────────
static void test_silence_zero_confidence() {
    std::vector<float> silence(48000, 0.0f);   // 1 s di zeri @48k
    ReferenceTempoAnalyzer an;
    TempoAnalysis r = an.analyze(silence.data(), silence.size(), 48000.0);
    assert(!r.map.isValid());
    assert(r.confidence == 0.0f);
    // Input degeneri espliciti: nullptr e buffer troppo corto.
    assert(an.analyze(nullptr, 48000, 48000.0).confidence == 0.0f);
    float one = 1.0f;
    assert(an.analyze(&one, 1, 48000.0).confidence == 0.0f);
    printf("PASS test_silence_zero_confidence\n");
}

// ─── test_degenerate_single_click ───────────────────────────────────────────
static void test_degenerate_single_click() {
    // Un solo onset: nessun intervallo → nessuna mappa, confidence 0.
    std::vector<float> buf = clickTrack({1000}, 48000);
    ReferenceTempoAnalyzer an;
    TempoAnalysis r = an.analyze(buf.data(), buf.size(), 48000.0);
    assert(!r.map.isValid());
    assert(r.confidence == 0.0f);
    printf("PASS test_degenerate_single_click\n");
}

// ─── test_two_clicks_one_point_low_confidence ───────────────────────────────
static void test_two_clicks_one_point_low_confidence() {
    // IOI NOTO a priori = 24000 campioni → BPM vero = 2880000/24000 = 120.0
    // ESATTO (letterale). Due soli onset = mappa valida ma confidence bassa.
    std::vector<float> buf = clickTrack({0, 24000}, 72000);
    ReferenceTempoAnalyzer an;
    TempoAnalysis r = an.analyze(buf.data(), buf.size(), 48000.0);
    assert(r.map.isValid());
    assert(r.map.size() == 1);
    assert(std::fabs(r.map.points()[0].bpm - 120.0) < 1e-9);
    assert(r.map.points()[0].sampleOffset == 0);
    assert(r.confidence > 0.0f && r.confidence <= 0.30001f);
    printf("PASS test_two_clicks_one_point_low_confidence\n");
}

// ─── test_steady_121_within_declared_tolerance ──────────────────────────────
static void test_steady_121_within_declared_tolerance() {
    // IOI NOTO a priori = 23802 campioni (letterale). BPM vero =
    // 2880000/23802 = 120.99824 (precalcolato a mano; ~121 come da spec).
    // Tolleranza dichiarata dell'attrezzo su click sintetici puliti: ±0.01 BPM
    // (il raffinamento al campione rende l'IOI misurato esatto).
    std::vector<uint64_t> pos;
    for (uint64_t i = 0; i < 10; ++i) pos.push_back(i * 23802);
    std::vector<float> buf = clickTrack(pos, 10 * 23802 + 24000);
    ReferenceTempoAnalyzer an;
    TempoAnalysis r = an.analyze(buf.data(), buf.size(), 48000.0);
    assert(r.map.isValid());
    assert(r.map.size() == 9);                     // 10 onset → 9 intervalli
    for (const TempoPoint& p : r.map.points())
        assert(std::fabs(p.bpm - 120.99824) < 0.01);
    assert(r.confidence > 0.8f);                   // regolare + tanti onset
    printf("PASS test_steady_121_within_declared_tolerance\n");
}

// ─── test_ramp_119_123_follows_direction ────────────────────────────────────
static void test_ramp_119_123_follows_direction() {
    // IOI NOTI a priori (letterali, da 119 a 123 BPM):
    //   24202, 24000, 23802, 23607, 23415 campioni.
    // Onsets cumulativi (precalcolati a mano):
    //   0, 24202, 48202, 72004, 95611, 119026.
    // BPM veri agli estremi (precalcolati a mano):
    //   primo = 2880000/24202 = 118.99843 · ultimo = 2880000/23415 = 122.99808.
    std::vector<uint64_t> pos = {0, 24202, 48202, 72004, 95611, 119026};
    std::vector<float> buf = clickTrack(pos, 119026 + 24000);
    ReferenceTempoAnalyzer an;
    TempoAnalysis r = an.analyze(buf.data(), buf.size(), 48000.0);
    assert(r.map.isValid());
    assert(r.map.size() == 5);                     // 6 onset → 5 intervalli
    const std::vector<TempoPoint>& pts = r.map.points();
    for (size_t i = 1; i < pts.size(); ++i)
        assert(pts[i].bpm > pts[i - 1].bpm);       // il verso giusto: cresce
    assert(std::fabs(pts.front().bpm - 118.99843) < 0.01);
    assert(std::fabs(pts.back().bpm  - 122.99808) < 0.01);
    assert(r.confidence > 0.8f);                   // rampa dolce = quasi regolare
    printf("PASS test_ramp_119_123_follows_direction\n");
}

// ─── test_output_always_valid_series ────────────────────────────────────────
static void test_output_always_valid_series() {
    // Ogni mappa valida prodotta deve ri-passare la validazione UNICA di A1
    // (riusata, non duplicata): ordinamento, bpm>0 finiti, cap, sample rate.
    ReferenceTempoAnalyzer an;

    std::vector<uint64_t> steady;
    for (uint64_t i = 0; i < 10; ++i) steady.push_back(i * 23802);
    std::vector<float> a = clickTrack(steady, 10 * 23802 + 24000);
    TempoAnalysis ra = an.analyze(a.data(), a.size(), 48000.0);
    assert(ra.map.isValid());
    assert(TempoMap::isValidSeries(ra.map.points(), ra.map.sourceSampleRate()));
    assert(ra.map.sourceSampleRate() == 48000.0);

    std::vector<float> b = clickTrack({0, 24202, 48202, 72004, 95611, 119026},
                                      119026 + 24000);
    TempoAnalysis rb = an.analyze(b.data(), b.size(), 44100.0);
    assert(rb.map.isValid());
    assert(TempoMap::isValidSeries(rb.map.points(), rb.map.sourceSampleRate()));
    assert(rb.map.sourceSampleRate() == 44100.0);  // il rate in ingresso è quello della mappa
    printf("PASS test_output_always_valid_series\n");
}

int main() {
    test_silence_zero_confidence();
    test_degenerate_single_click();
    test_two_clicks_one_point_low_confidence();
    test_steady_121_within_declared_tolerance();
    test_ramp_119_123_follows_direction();
    test_output_always_valid_series();
    printf("\nALL TESTS PASSED\n");
    return 0;
}
