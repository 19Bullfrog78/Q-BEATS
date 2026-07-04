import Foundation

// === B7-A5a — Punto di tempo della mappa (modello Swift) ===
// Controparte Codable del TempoPoint C++ serializzato da
// core_engine/beat_tracker/TempoMapJSON.{h,cpp}: i nomi-campo JSON
// ("sampleOffset","bpm") DEVONO restare identici al C++ (TempoMapJSON.h:9,
// ruling ⑤ referee 03/07/2026). CodingKeys ESPLICITE anche se coincidono coi
// nomi property: blindano l'allineamento contro rinomini futuri.
// Solo modello, nessuna logica: la validazione della serie (ordinamento,
// bpm > 0, cap 8192, sample rate) resta UNICA in C++ (TempoMap::make).
struct TempoPoint: Codable, Equatable {
    var sampleOffset: UInt64   // posizione @ sample-rate NATIVO della mappa (ruling ④)
    var bpm: Double

    enum CodingKeys: String, CodingKey {
        case sampleOffset = "sampleOffset"
        case bpm = "bpm"
    }
}
