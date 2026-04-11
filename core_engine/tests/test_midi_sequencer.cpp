#include "../MIDISequencer.h"
#include <cassert>
#include <cstdio>
#include <cmath>

// ─── test_tick_to_sample_accuracy ───────────────────────────────────────────
static void test_tick_to_sample_accuracy() {
    MIDISequencer seq;
    seq.setBPM(121.0);
    seq.setSampleRate(48000.0);

    // Aggiungere eventi sentinel ai tick critici
    struct { uint32_t tick; uint64_t expectedSample; } cases[] = {
        {    0,     0 },
        {  960, 23801 },
        { 1920, 47603 },
        { 2880, 71404 },
        { 3840, 95206 },
    };

    for (auto& c : cases) {
        MIDIEvent ev;
        ev.tick    = c.tick;
        ev.data[0] = 0x90;
        ev.data[1] = 60;
        ev.data[2] = 100;
        ev.length  = 3;
        seq.addEvent(ev);
    }

    // Buffer unico abbastanza largo da contenere tutti gli eventi
    auto result = seq.processBuffer(0, 200000);

    // Filtrare gli F8 — questo test verifica solo gli eventi NoteOn
    std::vector<ScheduledEvent> noteEvents;
    for (auto& se : result) {
        if (se.event.data[0] != 0xF8) noteEvents.push_back(se);
    }

    assert(noteEvents.size() == 5 && "Numero eventi NoteOn atteso: 5");
    for (size_t i = 0; i < 5; ++i) {
        assert(noteEvents[i].samplePosition == cases[i].expectedSample &&
               "tick→sample conversion errata: possibile drift");
    }

    printf("PASS test_tick_to_sample_accuracy\n");
}

// ─── test_process_buffer_windowing ──────────────────────────────────────────
static void test_process_buffer_windowing() {
    MIDISequencer seq;
    seq.setBPM(121.0);
    seq.setSampleRate(48000.0);

    MIDIEvent ev0; ev0.tick = 0;   ev0.data[0] = 0x90; ev0.length = 1;
    MIDIEvent ev1; ev1.tick = 960; ev1.data[0] = 0x91; ev1.length = 1;
    seq.addEvent(ev0);
    seq.addEvent(ev1);

    uint32_t bufSize = 256;
    bool found0 = false;
    bool found1 = false;

    for (uint32_t buf = 0; buf < 400; ++buf) {
        uint64_t start = (uint64_t)buf * bufSize;
        auto events = seq.processBuffer(start, bufSize);
        for (auto& se : events) {
            if (se.event.data[0] == 0x90) found0 = true;
            if (se.event.data[0] == 0x91) found1 = true;
            // Verifica che il sample cada nella finestra corretta
            assert(se.samplePosition >= start);
            assert(se.samplePosition < start + bufSize &&
                   "Evento fuori finestra buffer");
        }
    }

    assert(found0 && "Evento a tick 0 non trovato");
    assert(found1 && "Evento a tick 960 non trovato");

    printf("PASS test_process_buffer_windowing\n");
}

// ─── test_long_term_drift ───────────────────────────────────────────────────
static void test_long_term_drift() {
    MIDISequencer seq;
    seq.setBPM(121.0);
    seq.setSampleRate(48000.0);

    uint32_t lastTick = 10000 * SEQUENCER_PPQN; // 9600000 tick
    MIDIEvent ev;
    ev.tick    = lastTick;
    ev.data[0] = 0xFF;
    ev.length  = 1;
    seq.addEvent(ev);

    // Calcolo analitico atteso:
    //   samplesPerTick = (48000 * 60) / (121 * 960) = 24.793388429...
    //   lastTick       = 9.600.000
    //   expected       = (uint64_t)(9.600.000 * 24.793388429...) = 238.016.528
    double samplesPerTick = (48000.0 * 60.0) / (121.0 * 960.0);
    uint64_t expected = (uint64_t)((double)lastTick * samplesPerTick);

    // Buffer da 512 per coprire tutto il range
    uint32_t bufSize = 512;
    bool found = false;
    uint64_t totalSamples = expected + bufSize;

    for (uint64_t start = 0; start < totalSamples; start += bufSize) {
        auto events = seq.processBuffer(start, bufSize);
        for (auto& se : events) {
            // Ignorare F8 — questo test verifica solo l'evento sentinel 0xFF
            if (se.event.data[0] == 0xF8) continue;
            assert(se.samplePosition == expected &&
                   "Drift rilevato su 10000 quarter note");
            found = true;
        }
    }

    assert(found && "Evento finale non trovato");
    printf("PASS test_long_term_drift\n");
}

// ─── test_clock_f8_generation ────────────────────────────────────────────────
// Verifica emissione F8 ai tick corretti e interfoliazione cronologica
// con eventi MIDI normali.
//
// A 121 BPM, 48000 Hz (samplesPerTick = 24.793388429...):
//   F8 a tick   0 → sample     0
//   F8 a tick  40 → sample   991   (uint64_t)(40  * 24.7933...) = 991
//   NoteOn tick 60 → sample  1487  (uint64_t)(60  * 24.7933...) = 1487
//   F8 a tick  80 → sample  1983   (uint64_t)(80  * 24.7933...) = 1983
//   F8 a tick 120 → sample  2975   (uint64_t)(120 * 24.7933...) = 2975
//
// Il buffer copre [0, 3000): devono uscire 4 F8 + 1 NoteOn = 5 eventi.
// Verifica: ordine cronologico corretto, F8 nel byte corretto, NoteOn
// interfoliato nella posizione giusta.
static void test_clock_f8_generation() {
    MIDISequencer seq;
    seq.setBPM(121.0);
    seq.setSampleRate(48000.0);

    // Evento normale al tick 60
    MIDIEvent noteOn;
    noteOn.tick    = 60;
    noteOn.data[0] = 0x90;
    noteOn.data[1] = 60;
    noteOn.data[2] = 100;
    noteOn.length  = 3;
    seq.addEvent(noteOn);

    auto result = seq.processBuffer(0, 3000);

    // Deve contenere esattamente 5 eventi: 4 F8 + 1 NoteOn
    assert(result.size() == 5 && "Attesi 5 eventi: 4 F8 + 1 NoteOn");

    // Verifica ordine cronologico stretto
    for (size_t i = 1; i < result.size(); ++i) {
        assert(result[i].samplePosition >= result[i-1].samplePosition &&
               "Ordine cronologico violato");
    }

    // Verifica valori sample e byte attesi
    assert(result[0].samplePosition == 0    && result[0].event.data[0] == 0xF8 &&
           "F8 atteso a sample 0");
    assert(result[1].samplePosition == 991  && result[1].event.data[0] == 0xF8 &&
           "F8 atteso a sample 991");
    assert(result[2].samplePosition == 1487 && result[2].event.data[0] == 0x90 &&
           "NoteOn atteso a sample 1487");
    assert(result[3].samplePosition == 1983 && result[3].event.data[0] == 0xF8 &&
           "F8 atteso a sample 1983");
    assert(result[4].samplePosition == 2975 && result[4].event.data[0] == 0xF8 &&
           "F8 atteso a sample 2975");

    printf("PASS test_clock_f8_generation\n");
}

int main() {
    test_tick_to_sample_accuracy();
    test_process_buffer_windowing();
    test_long_term_drift();
    test_clock_f8_generation();
    printf("\nALL TESTS PASSED\n");
    return 0;
}
