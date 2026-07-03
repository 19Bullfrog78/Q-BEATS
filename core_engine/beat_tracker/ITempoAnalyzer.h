#pragma once
#include "TempoMap.h"

// === B7-fondazione — ITempoAnalyzer (Atomo A2) ===
// La PRESA dell'analisi tempo: chi analizza audio e produce una TempoMap si
// conforma a questa interfaccia. Stack-agnostica: non conosce CoreML, aubio
// né BeatIt — il detector reale (BeatIt/CoreML, fase successiva) arriverà
// dietro questo contratto senza toccare i chiamanti. L'analisi è elaborazione
// OFFLINE (thread background, mai il thread audio RT).

struct TempoAnalysis {
    TempoMap map;          // valida (map.isValid()) solo se l'analisi ha retto
    float    confidence;   // 0.0–1.0: quanto fidarsi della mappa (0 = inutilizzabile)
};

class ITempoAnalyzer {
public:
    virtual ~ITempoAnalyzer() = default;

    // samples: audio MONO PCM in [-1, 1], n campioni consecutivi @ sampleRate.
    // Ritorna mappa + confidence. Su input inutilizzabile (nullptr, troppo
    // corto, silenzio, nessun evento ritmico): mappa NON valida e confidence 0.
    // La mappa ritornata, se valida, passa TempoMap::make (validazione unica A1).
    virtual TempoAnalysis analyze(const float* samples, size_t n,
                                  double sampleRate) = 0;
};
