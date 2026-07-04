import Foundation

// === B7-A5a — Metadati per-backtrack (modello Swift) ===
// Forma dal piano A5 ratificato §3 (Opzione B): entry del futuro terzo
// catalogo `backtracks.json` — il catalogo arriva con l'atomo A5c, QUI solo
// il modello, nessun consumatore.
// - filename: chiave di aggancio a Song.backtrackFilename (Song.swift:8) e
//   identità dell'entry (Identifiable: id = filename) → non-optional.
// - Campi mappa TUTTI optional, prefisso tempoMap* (nomi RATIFICATI = formato
//   persistente): tutti nil = base MAI analizzata. Il marcatore è nil, NON
//   l'array vuoto.
// - tempoMap: punti allineati al C++ (vedi TempoPoint.swift).
// - tempoMapSampleRate: sample-rate NATIVO della mappa (ruling ⑤ — specchia
//   il `sourceSampleRate` del container C++, TempoMapJSON.h:11-12).
// - tempoMapConfidence: dall'analyzer (ITempoAnalyzer: analyze → {TempoMap,
//   confidence}); `Double?` ratificato (piano A5).
// - tempoMapAnalyzedAt: quando l'analisi è stata prodotta.
struct BacktrackFile: Codable, Identifiable, Equatable {
    var filename: String
    var tempoMap: [TempoPoint]?
    var tempoMapSampleRate: Double?
    var tempoMapConfidence: Double?
    var tempoMapAnalyzedAt: Date?

    // Identità di catalogo = filename (computed: NON entra in CodingKeys)
    var id: String { filename }

    // Chiavi ESPLICITE come su TempoPoint (confermate referee 04/07): da A5c
    // questo è il formato persistente di backtracks.json (+ backup) — un
    // rename di property non deve poterlo cambiare in silenzio.
    enum CodingKeys: String, CodingKey {
        case filename = "filename"
        case tempoMap = "tempoMap"
        case tempoMapSampleRate = "tempoMapSampleRate"
        case tempoMapConfidence = "tempoMapConfidence"
        case tempoMapAnalyzedAt = "tempoMapAnalyzedAt"
    }
}
