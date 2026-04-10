#include "MetronomeDSP.h"
#include <cassert>
#include <iostream>
#include <cmath>

void test_basic_beat() {
    MetronomeDSP dsp(48000.0, 120.0);
    auto beats = dsp.processBuffer(256);
    assert(beats.size() == 1);
    assert(beats[0] == 0);
    
    bool foundSecondBeat = false;
    for (int i = 1; i <= 93; ++i) { // processa buffer da indice 1 a 93 incluso (94 buffer totali contando il buffer 0 iniziale)
        beats = dsp.processBuffer(256);
        if (i == 93) { // sample assoluti 23808-24063, beat atteso a offset 192 (sample 24000)
            assert(beats.size() == 1);
            assert(beats[0] == 192); // 23808 + 192 = 24000
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
        assert(beats[0] == bufferSize - 1);
        
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
        for (uint32_t offset : beats) {
            uint64_t currentAbsolute = offset + (buffersProcessed * 256);
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

int main() {
    test_basic_beat();
    test_buffer_wrap();
    test_long_term_drift();
    std::cout << "All C++ Core Engine tests passed successfully!" << std::endl;
    return 0;
}
