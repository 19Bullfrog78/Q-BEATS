#pragma once
#include <cstdint>
#include <cstddef>
#include <vector>

// === B7-fondazione — TempoMap (Atomo A1) ===
// Tipi dati del metronomo adattivo: serie ordinata di punti-tempo estratti
// dalla base (backing track). In modalità Adattiva la mappa è la fonte di
// verità temporale («la backtrack comanda» — design B7 04/05/2026).
//
// CONTRATTO DOMINIO CLOCK (ratifica referee 03/07/2026, punto ④):
// `sample` in ingresso a bpmAt è la POSIZIONE NELLA BASE, espressa in campioni
// al sample-rate NATIVO della mappa (sourceSampleRate — quello del file).
// NON è il contatore libero del metronomo né una posizione al render-rate:
// l'eventuale conversione render↔nativo avviene FUORI, al confine del wiring
// (A3+), e va resa esplicita lì. I test alimentano posizioni già nel dominio
// della mappa e sono commentati come tali — il banco NON può far emergere un
// mismatch di dominio, quindi il contratto va rispettato a monte.

struct TempoPoint {
    uint64_t sampleOffset;   // posizione nella base, campioni @ sourceSampleRate
    double   bpm;            // tempo istantaneo al punto (> 0, finito)
};

bool operator==(const TempoPoint& a, const TempoPoint& b);

namespace tempomap {

// Interpolazione lineare sul segmento che contiene `sample`; clamp al
// primo/ultimo punto fuori dai bordi. RT-safe: nessuna alloc/lock, O(log n)
// (binary search hand-rolled su array contiguo — A3 la chiamerà dallo slot
// preallocato del double-buffer).
// PRECONDIZIONI (garantite dalla validazione di TempoMap::make): count >= 1,
// sampleOffset strettamente crescenti, ogni bpm > 0 e finito.
// count == 0 → 0.0 difensivo: una mappa vuota non è valida e NON va mai
// attivata (il chiamante gate-a su isValid()).
double bpmAt(const TempoPoint* points, size_t count, uint64_t sample);

} // namespace tempomap

class TempoMap {
public:
    // Cap ratificato (referee 03/07, punto 4): 8192 punti × 16 B ≈ 128 KB per
    // slot (256 KB sui 2 slot del double-buffer A3). Il rifiuto oltre-cap
    // avviene QUI (costruzione, non-RT), mai in RT.
    static constexpr size_t kMaxPoints = 8192;

    TempoMap() = default;   // vuota = non valida (isValid() == false)

    // Regole di validità della serie (UNICHE — usate anche dal parser JSON):
    // 1 <= count <= kMaxPoints · sampleOffset strettamente crescenti (niente
    // duplicati) · ogni bpm > 0 e finito · sourceSampleRate > 0 e finito.
    static bool isValidSeries(const std::vector<TempoPoint>& points,
                              double sourceSampleRate);

    // Unica via di costruzione di una mappa valida: ritorna false (e lascia
    // `out` INVARIATA) se la serie non passa isValidSeries.
    static bool make(std::vector<TempoPoint> points, double sourceSampleRate,
                     TempoMap& out);

    bool   isValid() const { return !_points.empty(); }
    size_t size()    const { return _points.size(); }
    const std::vector<TempoPoint>& points() const { return _points; }
    double sourceSampleRate() const { return _sourceSampleRate; }

    // Precondizione: isValid(). Vedi contratto dominio clock in testa al file.
    double bpmAt(uint64_t sample) const {
        return tempomap::bpmAt(_points.data(), _points.size(), sample);
    }

private:
    std::vector<TempoPoint> _points;          // ordinati per sampleOffset
    double                  _sourceSampleRate = 0.0;
};

bool operator==(const TempoMap& a, const TempoMap& b);
