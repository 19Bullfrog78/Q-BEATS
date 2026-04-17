#include "MIDISequencer.h"
#include <algorithm>
#include <cmath>
#include <atomic>

MIDISequencer::MIDISequencer()
    : _bpm(120.0)
    , _sampleRate(48000.0)
    , _samplesPerTick(0.0)
{
    _recalculate();
}

void MIDISequencer::setBPM(double bpm) {
    _bpm = bpm;
    _recalculate();
}

void MIDISequencer::setSampleRate(double sampleRate) {
    _sampleRate = sampleRate;
    _recalculate();
}

void MIDISequencer::_recalculate() {
    // Questa è la formula centrale del sequencer.
    // Usa double per mantenere precisione sub-sample.
    _samplesPerTick = (_sampleRate * 60.0) / (_bpm * (double)SEQUENCER_PPQN);
}

double MIDISequencer::getBeatPosition(uint64_t currentSample) const {
    if (_samplesPerTick <= 0.0) return 0.0;
    int64_t adj = _sampleBaseAdj.load(std::memory_order_relaxed);
    int64_t virtSample = (int64_t)currentSample + adj;
    if (virtSample < 0) virtSample = 0;
    return ((double)virtSample / _samplesPerTick) / (double)SEQUENCER_PPQN;
}

void MIDISequencer::setBeatPosition(double targetBeats, uint64_t currentSample) {
    if (_samplesPerTick <= 0.0) return;
    // Al campione currentSample vogliamo essere a targetBeats.
    // virtual sample target = targetBeats * PPQN * samplesPerTick
    double targetVirtSample = targetBeats * (double)SEQUENCER_PPQN * _samplesPerTick;
    _sampleBaseAdj.store(
        (int64_t)targetVirtSample - (int64_t)currentSample,
        std::memory_order_relaxed);
}

uint64_t MIDISequencer::_tickToSample(uint64_t absoluteTick) const {
    // Conversione diretta tick→sample via floating point.
    // NON accumulare sample per sample: calcolare sempre da tick assoluto
    // per evitare drift cumulativo.
    return (uint64_t)((double)absoluteTick * _samplesPerTick);
}

void MIDISequencer::setPattern(const std::vector<MIDIEvent>& events, uint32_t patternLengthTicks) {
    _pattern = events;
    std::sort(_pattern.begin(), _pattern.end(), [](const MIDIEvent& a, const MIDIEvent& b) {
        return a.tick < b.tick;
    });
    _patternLengthTicks = patternLengthTicks;
}

void MIDISequencer::clearPattern() {
    _pattern.clear();
    _patternLengthTicks = 0;
}

// Implementazioni rimosse: la logica usa solo _pattern e F8


void MIDISequencer::processBuffer(uint64_t startSample,
                                   uint32_t bufferSize,
                                   ScheduledEventBuffer& outBuffer) {
    outBuffer.count = 0;
    uint64_t endSample = startSample + (uint64_t)bufferSize;

    // === MODIFICATO 6C — virtual sample space per Link phase sync ===
    // _sampleBaseAdj sposta la finestra nel dominio virtuale.
    // Tutti i calcoli tick/pattern avvengono in spazio virtuale;
    // i samplePosition emessi vengono riconvertiti in spazio reale.
    int64_t adj = _sampleBaseAdj.load(std::memory_order_relaxed);
    int64_t virtStartI = (int64_t)startSample + adj;
    int64_t virtEndI   = (int64_t)endSample   + adj;
    if (virtEndI <= 0) return; // buffer completamente prima del tempo virtuale
    if (virtStartI < 0) virtStartI = 0;
    uint64_t vStart = (uint64_t)virtStartI;
    uint64_t vEnd   = (uint64_t)virtEndI;

    uint64_t startTick      = (uint64_t)((double)vStart / _samplesPerTick);
    uint64_t firstClockTick = ((startTick + 39) / 40) * 40;

    for (uint64_t clockTick = firstClockTick; ; clockTick += 40) {
        uint64_t virtSamplePos = _tickToSample(clockTick);
        if (virtSamplePos >= vEnd) break;
        if (virtSamplePos >= vStart) {
            int64_t realSamplePos = (int64_t)virtSamplePos - adj;
            if (realSamplePos < (int64_t)startSample ||
                realSamplePos >= (int64_t)endSample) continue;
            if (outBuffer.count >= MAX_EVENTS_PER_BUFFER) continue;
            ScheduledEvent& se = outBuffer.events[outBuffer.count++];
            se.samplePosition = (uint64_t)realSamplePos;
            se.event.tick     = (uint32_t)clockTick;
            se.event.data[0]  = 0xF8;
            se.event.data[1]  = 0x00;
            se.event.data[2]  = 0x00;
            se.event.length   = 1;
        }
    }

    if (_pattern.empty() || _patternLengthTicks == 0) {
        return;
    }

    uint64_t cycleStartGlobalTick =
        (startTick / _patternLengthTicks) * _patternLengthTicks;

    for (uint64_t globalCycle = cycleStartGlobalTick; ; globalCycle += _patternLengthTicks) {
        if (_tickToSample(globalCycle) >= vEnd) break;

        for (const auto& ev : _pattern) {
            uint64_t absoluteTick  = globalCycle + ev.tick;
            uint64_t virtSamplePos = _tickToSample(absoluteTick);
            if (virtSamplePos >= vEnd) break;
            if (virtSamplePos >= vStart) {
                int64_t realSamplePos = (int64_t)virtSamplePos - adj;
                if (realSamplePos < (int64_t)startSample ||
                    realSamplePos >= (int64_t)endSample) continue;
                if (outBuffer.count >= MAX_EVENTS_PER_BUFFER) continue;
                ScheduledEvent& se = outBuffer.events[outBuffer.count++];
                se.samplePosition = (uint64_t)realSamplePos;
                se.event = ev;
            }
        }
    }

    std::sort(outBuffer.events, outBuffer.events + outBuffer.count,
              [](const ScheduledEvent& a, const ScheduledEvent& b) {
                  return a.samplePosition < b.samplePosition;
              });
}

