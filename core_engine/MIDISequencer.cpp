#include "MIDISequencer.h"
#include <algorithm>
#include <cmath>

MIDISequencer::MIDISequencer()
    : _bpm(120.0)
    , _sampleRate(48000.0)
    , _samplesPerTick(0.0)
    , _nextEventIndex(0)
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

uint64_t MIDISequencer::_tickToSample(uint32_t tick) const {
    // Conversione diretta tick→sample via floating point.
    // NON accumulare sample per sample: calcolare sempre da tick assoluto
    // per evitare drift cumulativo.
    return (uint64_t)((double)tick * _samplesPerTick);
}

void MIDISequencer::addEvent(const MIDIEvent& event) {
    // Inserisce mantenendo ordine per tick crescente
    auto it = std::lower_bound(
        _events.begin(), _events.end(), event,
        [](const MIDIEvent& a, const MIDIEvent& b) {
            return a.tick < b.tick;
        });
    _events.insert(it, event);
}

void MIDISequencer::clearEvents() {
    _events.clear();
    _nextEventIndex = 0;
}

void MIDISequencer::reset() {
    _nextEventIndex = 0;
}

std::vector<ScheduledEvent> MIDISequencer::processBuffer(uint64_t startSample,
                                                          uint32_t bufferSize) {
    std::vector<ScheduledEvent> result;
    uint64_t endSample = startSample + (uint64_t)bufferSize;

    // --- Sezione 1: eventi MIDI normali da _events ---
    for (uint32_t i = _nextEventIndex; i < (uint32_t)_events.size(); ++i) {
        uint64_t samplePos = _tickToSample(_events[i].tick);
        if (samplePos >= endSample) break;
        if (samplePos >= startSample) {
            ScheduledEvent se;
            se.samplePosition = samplePos;
            se.event          = _events[i];
            result.push_back(se);
            _nextEventIndex   = i + 1;
        }
    }

    // --- Sezione 2: MIDI Clock F8 (24 per quarter note = ogni 40 tick) ---
    //
    // Calcolo dal sample assoluto — NON da un contatore incrementale.
    // Garantisce jitter zero su esecuzioni arbitrariamente lunghe.
    //
    // Formula:
    //   startTick      = (uint64_t)(startSample / _samplesPerTick)
    //   firstClockTick = ((startTick + 39) / 40) * 40
    //
    // Il divisore intero (+ 39) / 40 * 40 è ceiling al multiplo di 40
    // più vicino >= startTick. Funziona correttamente anche quando
    // startTick == 0: (0 + 39) / 40 = 0 → firstClockTick = 0.
    //
    // Esempio a 121 BPM, 48000 Hz (samplesPerTick = 24.7933...):
    //   startSample = 0    → startTick = 0  → firstClockTick = 0
    //   startSample = 256  → startTick = 10 → firstClockTick = 40
    //   startSample = 1024 → startTick = 41 → firstClockTick = 80

    uint64_t startTick     = (uint64_t)((double)startSample / _samplesPerTick);
    uint64_t firstClockTick = ((startTick + 39) / 40) * 40;

    for (uint64_t clockTick = firstClockTick; ; clockTick += 40) {
        uint64_t samplePos = _tickToSample((uint32_t)clockTick);
        if (samplePos >= endSample)   break;
        if (samplePos >= startSample) {
            ScheduledEvent se;
            se.samplePosition = samplePos;
            se.event.tick     = (uint32_t)clockTick;
            se.event.data[0]  = 0xF8;
            se.event.data[1]  = 0x00;
            se.event.data[2]  = 0x00;
            se.event.length   = 1;
            result.push_back(se);
        }
    }

    // --- Sezione 3: ordinamento cronologico ---
    // Interfoliazione F8 + eventi normali per samplePosition crescente.
    // NOTA: std::sort è accettabile qui — processBuffer NON viene chiamato
    // dal render thread iOS. Il porting RT-safe è una fase separata.
    std::sort(result.begin(), result.end(),
              [](const ScheduledEvent& a, const ScheduledEvent& b) {
                  return a.samplePosition < b.samplePosition;
              });

    return result;
}

