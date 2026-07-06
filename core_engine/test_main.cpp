#include "MetronomeDSP.h"
#include <cassert>
#include <cstdio>
#include <iostream>
#include <cmath>

void test_basic_beat() {
    MetronomeDSP dsp(48000.0, 120.0);
    auto beats = dsp.processBuffer(256);
    assert(beats.size() == 1);
    assert(beats[0].offset == 0);
    
    bool foundSecondBeat = false;
    for (int i = 1; i <= 93; ++i) { // processa buffer da indice 1 a 93 incluso (94 buffer totali contando il buffer 0 iniziale)
        beats = dsp.processBuffer(256);
        if (i == 93) { // sample assoluti 23808-24063, beat atteso a offset 192 (sample 24000)
            assert(beats.size() == 1);
            assert(beats[0].offset == 192); // 23808 + 192 = 24000
            foundSecondBeat = true;
        } else {
            assert(beats.empty());
        }
    }
    assert(foundSecondBeat);
    std::cout << "test_basic_beat passed" << std::endl;
}

void test_buffer_wrap() {
    uint32_t bufferSizes[] = {64, 128, 256, 512};
    for (uint32_t bufferSize : bufferSizes) {
        MetronomeDSP dsp(48000.0, 120.0);
        uint64_t samplesPerBeat = (uint64_t)std::round(48000.0 * 60.0 / 120.0);
        dsp.setAbsolutePositionForTesting(samplesPerBeat - (bufferSize - 1));
        
        auto beats = dsp.processBuffer(bufferSize);
        assert(beats.size() == 1);
        assert(beats[0].offset == bufferSize - 1);
        
        auto nextBeats = dsp.processBuffer(bufferSize);
        assert(nextBeats.empty());
    }
    std::cout << "test_buffer_wrap passed" << std::endl;
}

void test_long_term_drift() {
    MetronomeDSP dsp(48000.0, 121.0);
    uint32_t totalBeats = 0;
    uint32_t buffersProcessed = 0;
    bool foundBeatIndex1000 = false;
    
    for (int i = 0; i < 100000; ++i) {
        auto beats = dsp.processBuffer(256);
        for (const auto& beat : beats) {
            uint64_t currentAbsolute = beat.offset + (buffersProcessed * 256);
            uint64_t expected = (uint64_t)std::round((double)totalBeats * 48000.0 * 60.0 / 121.0);
            
            assert(currentAbsolute == expected);
            
            if (totalBeats == 1000) {
                 foundBeatIndex1000 = true;
            }
            totalBeats++;
        }
        buffersProcessed++;
        if (foundBeatIndex1000) break;
    }
    assert(foundBeatIndex1000);
    std::cout << "test_long_term_drift passed" << std::endl;
}

// Raccoglie i primi N BeatEvent elaborando buffer da 256 sample
static std::vector<BeatEvent> collectBeats(MetronomeDSP& dsp, size_t count) {
    std::vector<BeatEvent> result;
    for (int buf = 0; buf < 2000 && result.size() < count; ++buf) {
        auto beats = dsp.processBuffer(256);
        result.insert(result.end(), beats.begin(), beats.end());
    }
    return result;
}

struct AbsoluteBeat {
    uint64_t absoluteSample;
    bool     accent;
    bool     isBeat;
};

// Raccoglie i primi N eventi con posizione assoluta in sample
static std::vector<AbsoluteBeat> collectAbsolute(MetronomeDSP& dsp, size_t count, uint32_t bufSize = 256) {
    std::vector<AbsoluteBeat> result;
    uint64_t processed = 0;
    while (result.size() < count && processed < 500000) {
        auto beats = dsp.processBuffer(bufSize);
        for (const auto& ev : beats) {
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        }
        processed += bufSize;
    }
    return result;
}

void test_accent_default_downbeat() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    auto bar = collectBeats(dsp, 4);
    assert(bar.size() == 4);
    assert(bar[0].accent == true);
    assert(bar[1].accent == false);
    assert(bar[2].accent == false);
    assert(bar[3].accent == false);
    std::cout << "test_accent_default_downbeat passed" << std::endl;
}

void test_accent_pattern_6_8() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(6);
    uint8_t pattern[6] = {1,0,0,1,0,0};
    dsp.setAccentPattern(pattern, 6);
    auto bar = collectBeats(dsp, 6);
    assert(bar.size() == 6);
    assert(bar[0].accent == true);
    assert(bar[1].accent == false);
    assert(bar[2].accent == false);
    assert(bar[3].accent == true);
    assert(bar[4].accent == false);
    assert(bar[5].accent == false);
    std::cout << "test_accent_pattern_6_8 passed" << std::endl;
}

void test_accent_pattern_7_8() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(7);
    uint8_t pattern[7] = {1,0,0,1,0,1,0};
    dsp.setAccentPattern(pattern, 7);
    auto bar = collectBeats(dsp, 7);
    assert(bar.size() == 7);
    assert(bar[0].accent == true);
    assert(bar[1].accent == false);
    assert(bar[2].accent == false);
    assert(bar[3].accent == true);
    assert(bar[4].accent == false);
    assert(bar[5].accent == true);
    assert(bar[6].accent == false);
    std::cout << "test_accent_pattern_7_8 passed" << std::endl;
}

void test_accent_guard_wrong_length() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    // Lunghezza sbagliata (3 invece di 4): pattern ignorato
    uint8_t wrongPattern[3] = {1,1,1};
    dsp.setAccentPattern(wrongPattern, 3);
    auto bar = collectBeats(dsp, 4);
    assert(bar.size() == 4);
    assert(bar[0].accent == true);
    assert(bar[1].accent == false);
    assert(bar[2].accent == false);
    assert(bar[3].accent == false);
    std::cout << "test_accent_guard_wrong_length passed" << std::endl;
}

void test_accent_guard_too_large() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    // Lunghezza > 16: pattern ignorato
    uint8_t bigPattern[17] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    dsp.setAccentPattern(bigPattern, 17);
    auto bar = collectBeats(dsp, 4);
    assert(bar.size() == 4);
    assert(bar[0].accent == true);
    assert(bar[1].accent == false);
    std::cout << "test_accent_guard_too_large passed" << std::endl;
}

void test_subdivision_eighth_straight() {
    // 120 BPM, 48kHz: spb=24000 — subdiv a 12000 campioni dal beat
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(2, 0.5);
    auto ev = collectAbsolute(dsp, 5);
    assert(ev.size() == 5);
    assert(ev[0].absoluteSample == 0     && ev[0].isBeat == true);
    assert(ev[1].absoluteSample == 12000 && ev[1].isBeat == false);
    assert(ev[2].absoluteSample == 24000 && ev[2].isBeat == true);
    assert(ev[3].absoluteSample == 36000 && ev[3].isBeat == false);
    assert(ev[4].absoluteSample == 48000 && ev[4].isBeat == true);
    std::cout << "test_subdivision_eighth_straight passed" << std::endl;
}

void test_subdivision_triplets() {
    // spb=24000 — terzine a 8000 e 16000 per beat
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(3, 0.5);
    auto ev = collectAbsolute(dsp, 7);
    assert(ev.size() == 7);
    assert(ev[0].absoluteSample == 0     && ev[0].isBeat == true);
    assert(ev[1].absoluteSample == 8000  && ev[1].isBeat == false);
    assert(ev[2].absoluteSample == 16000 && ev[2].isBeat == false);
    assert(ev[3].absoluteSample == 24000 && ev[3].isBeat == true);
    assert(ev[4].absoluteSample == 32000 && ev[4].isBeat == false);
    assert(ev[5].absoluteSample == 40000 && ev[5].isBeat == false);
    assert(ev[6].absoluteSample == 48000 && ev[6].isBeat == true);
    std::cout << "test_subdivision_triplets passed" << std::endl;
}

void test_subdivision_sixteenth() {
    // spb=24000 — semicrome a 6000, 12000, 18000 per beat
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(4, 0.5);
    auto ev = collectAbsolute(dsp, 9);
    assert(ev.size() == 9);
    assert(ev[0].absoluteSample == 0     && ev[0].isBeat == true);
    assert(ev[1].absoluteSample == 6000  && ev[1].isBeat == false);
    assert(ev[2].absoluteSample == 12000 && ev[2].isBeat == false);
    assert(ev[3].absoluteSample == 18000 && ev[3].isBeat == false);
    assert(ev[4].absoluteSample == 24000 && ev[4].isBeat == true);
    assert(ev[5].absoluteSample == 30000 && ev[5].isBeat == false);
    assert(ev[6].absoluteSample == 36000 && ev[6].isBeat == false);
    assert(ev[7].absoluteSample == 42000 && ev[7].isBeat == false);
    assert(ev[8].absoluteSample == 48000 && ev[8].isBeat == true);
    std::cout << "test_subdivision_sixteenth passed" << std::endl;
}

void test_swing_offset() {
    // spb=24000, swing=0.667 — subdiv a round(0.667*24000)=16008 dal beat
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(2, 0.667);
    auto ev = collectAbsolute(dsp, 5);
    assert(ev.size() == 5);
    assert(ev[0].absoluteSample == 0     && ev[0].isBeat == true);
    assert(ev[1].absoluteSample == 16008 && ev[1].isBeat == false);
    assert(ev[2].absoluteSample == 24000 && ev[2].isBeat == true);
    assert(ev[3].absoluteSample == 40008 && ev[3].isBeat == false);
    assert(ev[4].absoluteSample == 48000 && ev[4].isBeat == true);
    std::cout << "test_swing_offset passed" << std::endl;
}

void test_isBeat_accent_flags() {
    // Beat 0 (accent) isBeat=true accent=true
    // Beat 1-3 isBeat=true accent=false
    // Suddivisioni isBeat=false accent=false sempre
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(2, 0.5);
    auto ev = collectAbsolute(dsp, 9);  // 4 beat + 4 subdiv + beat 4
    assert(ev[0].isBeat == true  && ev[0].accent == true);   // downbeat bar 1
    assert(ev[1].isBeat == false && ev[1].accent == false);  // subdiv
    assert(ev[2].isBeat == true  && ev[2].accent == false);  // beat 2
    assert(ev[4].isBeat == true  && ev[4].accent == false);  // beat 3
    assert(ev[6].isBeat == true  && ev[6].accent == false);  // beat 4
    assert(ev[8].isBeat == true  && ev[8].accent == true);   // downbeat bar 2
    std::cout << "test_isBeat_accent_flags passed" << std::endl;
}

void test_bpm_change_on_bar_boundary() {
    // 120 BPM → 60 BPM: schedula mid-bar-1 → cambio al downbeat bar-2 (sample 96000)
    // Verifica: downbeat a 96000 accent=true, beat successivo a 96000+48000
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);

    std::vector<AbsoluteBeat> result;
    uint64_t processed = 0;
    bool scheduled = false;
    while (result.size() < 6 && processed < 500000) {
        auto beats = dsp.processBuffer(256);
        for (const auto& ev : beats)
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        processed += 256;
        // Schedula dopo che beat 0 (sample 0) è già passato — prossimo downbeat = 96000
        if (!scheduled && result.size() >= 1) {
            dsp.scheduleBPMChange(60.0);
            scheduled = true;
        }
    }
    assert(result[0].absoluteSample == 0);
    assert(result[1].absoluteSample == 24000);
    assert(result[2].absoluteSample == 48000);
    assert(result[3].absoluteSample == 72000);
    // Bar-2 downbeat alla posizione naturale (96000, vecchio spb), cambio BPM qui
    assert(result[4].absoluteSample == 96000);
    assert(result[4].isBeat  == true);
    assert(result[4].accent  == true);
    // Beat successivo usa nuovo spb = 48000 (60 BPM)
    assert(result[5].absoluteSample == 96000 + 48000);
    std::cout << "test_bpm_change_on_bar_boundary passed" << std::endl;
}

void test_bpm_change_mid_buffer() {
    // Il downbeat cade dentro un buffer — verifica che i beat rimanenti usino nuovo spb
    // 120 BPM, beatsPerBar=4: downbeat ogni 96000 sample
    // Posizioniamo a 96000 - 100 sample, buffer=256 → downbeat a offset 100 nel buffer
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setAbsolutePositionForTesting(96000 - 100);
    dsp.scheduleBPMChange(60.0);

    std::vector<AbsoluteBeat> result;
    uint64_t processed = 96000 - 100;
    while (result.size() < 2 && processed < 300000) {
        auto beats = dsp.processBuffer(256);
        for (const auto& ev : beats)
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        processed += 256;
    }
    // Primo evento nel buffer: downbeat a 96000 (offset 100), accent=true
    assert(result[0].absoluteSample == 96000);
    assert(result[0].isBeat  == true);
    assert(result[0].accent  == true);
    // Secondo evento: usa nuovo spb 48000 (60 BPM)
    assert(result[1].absoluteSample == 96000 + 48000);
    std::cout << "test_bpm_change_mid_buffer passed" << std::endl;
}

void test_bpm_change_subdiv_coherent() {
    // 120 BPM → 60 BPM al downbeat sample 96000 con subdivision 2 (crome)
    // Prima subdiv dopo il cambio deve essere a 96000+24000 (spb_new/2 = 48000/2)
    // Usa setAbsolutePositionForTesting per posizionarsi con _currentBeatInBar==0 a 96000
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    dsp.setSubdivision(2, 0.5);
    dsp.setAbsolutePositionForTesting(96000 - 100);
    dsp.scheduleBPMChange(60.0);

    std::vector<AbsoluteBeat> result;
    uint64_t processed = 96000 - 100;
    while (result.size() < 2 && processed < 300000) {
        auto beats = dsp.processBuffer(256);
        for (const auto& ev : beats)
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        processed += 256;
    }
    assert(result[0].absoluteSample == 96000);
    assert(result[0].isBeat == true);
    // Subdiv con nuovo spb 48000: intervallo = 24000
    assert(result[1].absoluteSample == 96000 + 24000);
    assert(result[1].isBeat == false);
    std::cout << "test_bpm_change_subdiv_coherent passed" << std::endl;
}

// === ATOM C — subdivision schedulata al downbeat ===
void test_schedule_subdivision_at_downbeat() {
    // 48000 Hz, 120 BPM (spb=24000), bpb=4: beat a 0/24000/48000/72000,
    // downbeat bar-2 a 96000. Multiplier iniziale 1 (default, zero sub).
    // Armo scheduleSubdivisionChange(2, 0.5) DOPO il beat 0 (mid-bar):
    // deve applicare SOLO al downbeat 96000 — NESSUNA sub ai beat 1/2/3
    // (24000/48000/72000 non sono downbeat), prima sub ESATTAMENTE a
    // 96000 + 12000 (spb/2 = 24000/2). Attesi letterali a mano (§7).
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);

    std::vector<AbsoluteBeat> result;
    uint64_t processed = 0;
    bool scheduled = false;
    while (result.size() < 6 && processed < 500000) {
        auto beats = dsp.processBuffer(256);
        for (const auto& ev : beats)
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        processed += 256;
        // Arm dopo che il beat 0 è passato — mid-bar-1, come il test BPM sopra.
        if (!scheduled && result.size() >= 1) {
            dsp.scheduleSubdivisionChange(2, 0.5);
            scheduled = true;
        }
    }
    // Bar 1: quattro beat PULITI, nessuna sub (l'arm non applica mid-bar).
    assert(result[0].absoluteSample == 0     && result[0].isBeat == true);
    assert(result[1].absoluteSample == 24000 && result[1].isBeat == true);
    assert(result[2].absoluteSample == 48000 && result[2].isBeat == true);
    assert(result[3].absoluteSample == 72000 && result[3].isBeat == true);
    // Downbeat bar-2: apply qui (accent intatto = zero regressione beat).
    assert(result[4].absoluteSample == 96000 && result[4].isBeat == true);
    assert(result[4].accent == true);
    // Prima sub-nota ESATTAMENTE a metà del primo beat della bar-2.
    assert(result[5].absoluteSample == 96000 + 12000);
    assert(result[5].isBeat == false);
    std::cout << "test_schedule_subdivision_at_downbeat passed" << std::endl;
}

void test_cancel_pending_subdivision() {
    // B1 (stop-mid-transizione): armo la schedule e la CANCELLO prima del
    // downbeat → il downbeat NON deve applicare nulla: 6 beat puliti,
    // nessuna sub-nota mai emessa (multiplier resta 1).
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);

    std::vector<AbsoluteBeat> result;
    uint64_t processed = 0;
    bool armed = false;
    while (result.size() < 6 && processed < 500000) {
        auto beats = dsp.processBuffer(256);
        for (const auto& ev : beats)
            result.push_back({processed + ev.offset, ev.accent, ev.isBeat});
        processed += 256;
        if (!armed && result.size() >= 1) {
            dsp.scheduleSubdivisionChange(2, 0.5);
            dsp.cancelPendingSubdivision();   // lo stop arriva prima del downbeat
            armed = true;
        }
    }
    // Sei beat puliti sulla griglia 24000 — zero eventi isBeat=false.
    for (size_t i = 0; i < 6; ++i) {
        assert(result[i].absoluteSample == (uint64_t)(i * 24000));
        assert(result[i].isBeat == true);
    }
    std::cout << "test_cancel_pending_subdivision passed" << std::endl;
}

void test_bpm_no_change_without_schedule() {
    // Senza scheduleBPMChange, il BPM rimane invariato — 9 beat (2 bar + 1 extra)
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setBeatsPerBar(4);
    auto ev = collectAbsolute(dsp, 9);
    assert(ev.size() == 9);
    for (size_t i = 0; i < 9; ++i) {
        uint64_t expected = (uint64_t)std::round((double)i * 48000.0 * 60.0 / 120.0);
        assert(ev[i].absoluteSample == expected);
    }
    std::cout << "test_bpm_no_change_without_schedule passed" << std::endl;
}

void SampleRateUpdateTakesEffect() {
    MetronomeDSP dsp(48000.0, 120.0);
    dsp.setSampleRate(44100.0);
    dsp.resetForStart(0.0);
    
    // spb = 44100 * 60.0 / 120.0 = 22050
    // primo beat atteso al sample 22050 (oltre a quello a 0)
    auto beats = dsp.processBuffer(44100);
    
    bool foundCorrect = false;
    bool foundWrong = false;
    for (const auto& b : beats) {
        if (b.offset == 22050) foundCorrect = true;
        if (b.offset == 24000) foundWrong = true; // 24000 = 48000 * 60 / 120
    }
    
    assert(foundCorrect);
    assert(!foundWrong);
    std::cout << "SampleRateUpdateTakesEffect passed" << std::endl;
}

// ═══ B7-A4 — Anti-drift "121 ±2" con ORACOLO IN FORMA CHIUSA ════════════════
// Estende test_long_term_drift: da bpm FISSO a TempoMap oscillante ±2 attorno
// a 121 (triangolo 119↔123, media 121).
//
// ORACOLO PRIMARIO (ratifica referee 03/07, chiodo ③ + ruling punto 6): la
// fase-in-beat è l'INTEGRALE della mappa, B(s) = ∫ bpm(u) du / (60·SR); sui
// segmenti lineari il trapezio è ESATTO, e il sample del k-esimo beat esce
// per INVERSIONE (quadratica dentro il segmento). Long double, test-side,
// NESSUN codice condiviso col follower (ZOH per-buffer + "+= spb"): metodi
// indipendenti sulla stessa mappa-dato LETTERALE del test (non via bpmAt).
// L'integratore per-buffer long double è solo CROSS-CHECK SECONDARIO
// (ratifica: MAI oracolo primario — è la stessa matematica del follower) e
// serve a isolare la componente ZOH pura.
//
// SOGLIE: PROPOSTE — il numero finale lo approva il referee al gate A4
// (procedura ratificata: bound caratterizzato + margine).

struct OraclePoint { long double s; long double bpm; };

// Sample del k-esimo beat per integrazione + inversione (forma chiusa).
static long double oracleBeatSample(const std::vector<OraclePoint>& pts,
                                    long double SR, uint64_t k) {
    const long double target = (long double)k;
    long double accBeats = 0.0L;
    for (size_t i = 0; i + 1 < pts.size(); ++i) {
        const long double s0 = pts[i].s,   s1 = pts[i + 1].s;
        const long double b0 = pts[i].bpm, b1 = pts[i + 1].bpm;
        const long double segBeats = (b0 + b1) / 2.0L * (s1 - s0) / (60.0L * SR);
        if (accBeats + segBeats < target) { accBeats += segBeats; continue; }
        const long double R = target - accBeats;         // beat residui nel segmento
        const long double m = (b1 - b0) / (s1 - s0);     // pendenza bpm/sample
        if (m == 0.0L) return s0 + R * 60.0L * SR / b0;
        // (m/2)·x² + b0·x − R·60·SR = 0 → radice positiva (disc tra b0² e b1², sempre > 0)
        const long double disc = b0 * b0 + 2.0L * m * R * 60.0L * SR;
        return s0 + (-b0 + sqrtl(disc)) / m;
    }
    const OraclePoint& last = pts.back();                // clamp: bpm costante
    return last.s + (target - accBeats) * 60.0L * SR / last.bpm;
}

// bpm della mappa a un sample (interp lineare + clamp), long double — usato
// SOLO dal cross-check secondario per-buffer.
static long double mapBpmAtLD(const std::vector<OraclePoint>& pts, long double s) {
    if (s <= pts.front().s) return pts.front().bpm;
    if (s >= pts.back().s)  return pts.back().bpm;
    size_t i = 0;
    while (pts[i + 1].s <= s) ++i;
    const long double t = (s - pts[i].s) / (pts[i + 1].s - pts[i].s);
    return pts[i].bpm + t * (pts[i + 1].bpm - pts[i].bpm);
}

static void runAdaptiveDriftCase(uint32_t bufSize) {
    const long double SR = 48000.0L;
    // Mappa LETTERALE: triangolo 119↔123 (media 121), un punto ogni 15 s
    // (720000 campioni), 41 punti = 20 periodi interi da 30 s (600 s totali).
    std::vector<OraclePoint> opts;
    std::vector<TempoPoint>  tpts;
    for (int i = 0; i <= 40; ++i) {
        const uint64_t off = (uint64_t)i * 720000ULL;
        const double   b   = (i % 2 == 0) ? 119.0 : 123.0;
        opts.push_back({ (long double)off, (long double)b });
        tpts.push_back({ off, b });
    }
    TempoMap map;
    assert(TempoMap::make(tpts, 48000.0, map));

    MetronomeDSP dsp(48000.0, 90.0);   // bpm iniziale ininfluente: vince la mappa
    assert(dsp.setTempoMap(map));
    dsp.resetForStart(0.0);

    const size_t kBeats = 1200;        // ~595 s, dentro i 600 s coperti dalla mappa
    std::vector<uint64_t> beats;
    beats.reserve(kBeats);
    uint64_t pos = 0;
    while (beats.size() < kBeats && pos < 28800000ULL) {
        auto evs = dsp.processBuffer(bufSize);
        for (const auto& e : evs)
            if (e.isBeat) beats.push_back(pos + e.offset);
        pos += bufSize;
    }
    assert(beats.size() == kBeats);    // nessun beat perso sull'intera corsa

    // Oracolo precalcolato una volta (riusato da follower-check e cross-check).
    std::vector<long double> oracleS(kBeats);
    for (size_t k = 0; k < kBeats; ++k)
        oracleS[k] = oracleBeatSample(opts, SR, (uint64_t)k);

    // Deviazioni follower vs oracolo (in ms) + caratterizzazione.
    std::vector<long double> devMs(kBeats);
    long double maxAbs = 0.0L, maxFirst = 0.0L, maxSecond = 0.0L;
    for (size_t k = 0; k < kBeats; ++k) {
        devMs[k] = ((long double)beats[k] - oracleS[k]) / 48.0L;
        const long double a = fabsl(devMs[k]);
        if (a > maxAbs) maxAbs = a;
        if (k < kBeats / 2) { if (a > maxFirst)  maxFirst  = a; }
        else                { if (a > maxSecond) maxSecond = a; }
    }

    // Deriva NETTA ai confini di DOPPIO periodo (60 s = 121 beat ESATTI:
    // media 121 sul triangolo simmetrico → l'errore oscillante si elide).
    long double maxBoundary = 0.0L;
    printf("  [A4][buf=%u] deriva netta ai confini 60s (n=1..9, ms):", bufSize);
    for (int n = 1; n <= 9; ++n) {
        const long double a = fabsl(devMs[(size_t)n * 121]);
        printf(" %.3f", (double)a);
        if (a > maxBoundary) maxBoundary = a;
    }
    printf("\n");

    // CROSS-CHECK SECONDARIO: integratore long double con lo STESSO
    // campionamento per-buffer del follower → isola la componente ZOH pura
    // (attesa sotto-millisecondo, ruling punto 6).
    long double zohMax = 0.0L;
    {
        long double phase = 0.0L;
        uint64_t p = 0;
        size_t next = 0;
        while (next < kBeats && p < 28800000ULL) {
            const long double bpmTop = mapBpmAtLD(opts, (long double)p);
            const long double dph = bpmTop * (long double)bufSize / (60.0L * SR);
            while (next < kBeats && phase + dph >= (long double)next) {
                const long double frac = ((long double)next - phase) / dph;
                const long double sBeat = (long double)p + frac * (long double)bufSize;
                const long double d = fabsl(sBeat - oracleS[next]) / 48.0L;
                if (d > zohMax) zohMax = d;
                ++next;
            }
            phase += dph;
            p += bufSize;
        }
        assert(next == kBeats);
    }

    // Componente di deriva LINEARE (trovata dalla serie dei confini):
    // bias di 2° ordine del campionamento a inizio-gap — la convessità di
    // 1/bpm non si elide sul triangolo (i termini di 1° ordine sì). Tasso
    // QUADRATICO nella pendenza della mappa: su questa fixture aggressiva
    // (+/-2 BPM per 15 s) ~0.065-0.070 ms/min. Su materiale reale la deriva
    // si accumula SOLO sui tratti a tempo VARIABILE (brevi e alternati) →
    // pochi ms al massimo su un set intero; un accelerando ripido è
    // localmente più pendente della fixture, ma dura secondi e poi
    // l'accumulo si ferma a tempo costante. (Correzione referee: NON
    // "collassa sempre 100x".)
    const long double netRatePerMin =
        (fabsl(devMs[(size_t)9 * 121]) - fabsl(devMs[121])) / 8.0L;
    printf("  [A4][buf=%u] peak=%.3f ms | 1a meta'=%.3f | 2a meta'=%.3f | confini-60s=%.3f | ZOH-only=%.3f ms | deriva=%.4f ms/min\n",
           bufSize, (double)maxAbs, (double)maxFirst, (double)maxSecond,
           (double)maxBoundary, (double)zohMax, (double)netRatePerMin);

    // SOGLIE FISSATE DAL REFEREE (gate A4 03/07, opzione (a) di Mauro):
    assert(zohMax        <= 0.5L);            // (i) componente ZOH: sotto-millisecondo
    assert(maxAbs        <= 12.0L);           // picco totale (lag-1-beat ratificato, ~8.8 ms)
    // (ii) NB: l'errore NON è "bounded" in senso assoluto — CRESCE (deriva
    // lineare sopra). Su 10 min la crescita resta < 0.5 ms, quindi questo
    // slack regge SOLO perché legato alla durata della corsa (non è
    // scale-invariante). Il guardiano di lungo termine è il TASSO (assert
    // sotto), non questo slack.
    assert(maxSecond     <= maxFirst + 0.5L);
    assert(maxBoundary   <= 2.5L);            // deriva netta contenuta a ogni doppio periodo
    // Guardiano di regressione (referee): quasi-deterministico su fixture
    // fissa (misurato 0.065-0.070 ms/min) → 0.10 scatta se la deriva
    // ~raddoppia (~0.14); 0.15 l'avrebbe lasciata passare. Margine ~1.4x
    // sul rumore.
    assert(netRatePerMin <= 0.10L);
}

void test_adaptive_drift_121_pm2_closed_form_oracle() {
    runAdaptiveDriftCase(512);   // buffer target del ruling (punto 6)
    runAdaptiveDriftCase(256);   // conferma alla dimensione standard del banco
    std::cout << "test_adaptive_drift_121_pm2_closed_form_oracle passed" << std::endl;
}

int main() {
    test_basic_beat();
    test_buffer_wrap();
    test_long_term_drift();
    test_adaptive_drift_121_pm2_closed_form_oracle();
    test_accent_default_downbeat();
    test_accent_pattern_6_8();
    test_accent_pattern_7_8();
    test_accent_guard_wrong_length();
    test_accent_guard_too_large();
    test_subdivision_eighth_straight();
    test_subdivision_triplets();
    test_subdivision_sixteenth();
    test_swing_offset();
    test_isBeat_accent_flags();
    test_bpm_change_on_bar_boundary();
    test_bpm_change_mid_buffer();
    test_bpm_change_subdiv_coherent();
    test_schedule_subdivision_at_downbeat();
    test_cancel_pending_subdivision();
    test_bpm_no_change_without_schedule();
    SampleRateUpdateTakesEffect();
    std::cout << "All C++ Core Engine tests passed successfully!" << std::endl;
    return 0;
}
