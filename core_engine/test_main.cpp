#include "MetronomeDSP.h"
#include <cassert>
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

int main() {
    test_basic_beat();
    test_buffer_wrap();
    test_long_term_drift();
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
    test_bpm_no_change_without_schedule();
    std::cout << "All C++ Core Engine tests passed successfully!" << std::endl;
    return 0;
}
