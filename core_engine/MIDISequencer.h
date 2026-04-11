#pragma once
#include <cstdint>
#include <vector>

// Risoluzione inviolabile del progetto Q-BEATS
static constexpr uint32_t SEQUENCER_PPQN = 960;
static constexpr uint32_t MAX_EVENTS_PER_BUFFER = 256;

// Evento MIDI grezzo
struct MIDIEvent {
    uint32_t tick;    // posizione assoluta in tick (0-based)
    uint8_t  data[3]; // byte MIDI: es. { 0x90, 60, 100 }
    uint8_t  length;  // numero di byte validi: 1, 2 o 3
};

// Evento con sample position calcolata, pronto per l'output
struct ScheduledEvent {
    uint64_t samplePosition; // sample assoluto in cui va inviato
    MIDIEvent event;
};

// Struttura pre-allocata RT-safe per l'output del buffer
struct ScheduledEventBuffer {
    ScheduledEvent events[MAX_EVENTS_PER_BUFFER];
    uint32_t count = 0;
};

class MIDISequencer {
public:
    MIDISequencer();

    // Impostare prima di qualsiasi processBuffer()
    void setBPM(double bpm);
    void setSampleRate(double sampleRate);

    // Gestione eventi — non chiamare dal render thread
    void setPattern(const std::vector<MIDIEvent>& events, uint32_t patternLengthTicks);
    void clearPattern();

    // Chiamare all'inizio di ogni buffer audio.
    // startSample = sample assoluto di inizio buffer.
    // bufferSize  = dimensione buffer in samples.
    // RT-safe: popola outBuffer fino a MAX_EVENTS_PER_BUFFER (eventi in eccesso vengono droppati).
    void processBuffer(uint64_t startSample,
                       uint32_t bufferSize,
                       ScheduledEventBuffer& outBuffer);

private:
    double   _bpm;
    double   _sampleRate;
    double   _samplesPerTick; // (sampleRate * 60.0) / (bpm * SEQUENCER_PPQN)

    std::vector<MIDIEvent> _pattern;
    uint32_t _patternLengthTicks = 0;

    void     _recalculate();  // ricalcola _samplesPerTick dopo cambio bpm/sr
    uint64_t _tickToSample(uint64_t absoluteTick) const;
    // Formula: (uint64_t)((double)tick * _samplesPerTick)
    // Usa double precision per evitare drift accumulato.
};
