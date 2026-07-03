#pragma once
#include "ITempoAnalyzer.h"

// === B7-fondazione — ReferenceTempoAnalyzer (Atomo A2) ===
// ⚠️ ATTREZZO DI RIFERIMENTO per test/harness — NON music-grade, NON il
// detector. Il rilevamento reale (BeatIt/CoreML) arriva dietro ITempoAnalyzer
// in una fase successiva: nessuno deve scambiare QUESTA classe per il
// cervello dell'analisi. (Marchio obbligatorio — ratifica referee 03/07.)
//
// Scopo: dare al banco un'analisi DETERMINISTICA a zero dipendenze su input
// sintetici/controllati. Metodo volutamente elementare: envelope d'energia a
// finestre fisse → peak-picking con soglia relativa + refrattario →
// raffinamento dell'onset al campione (argmax |x|) → inter-onset → un
// TempoPoint per intervallo. Confidence: 0 su silenzio/degenere, tetto basso
// con pochi onset, penalità per IOI irregolari. La mappa prodotta passa
// TempoMap::make (validazione unica di A1 — non duplicata qui).

class ReferenceTempoAnalyzer final : public ITempoAnalyzer {
public:
    TempoAnalysis analyze(const float* samples, size_t n,
                          double sampleRate) override;
};
