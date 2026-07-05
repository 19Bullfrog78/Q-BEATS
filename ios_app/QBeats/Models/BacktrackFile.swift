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

// === B7-A5c-2 — Politica di merge del RESTORE (funzione pura) ===
// Il restore non fa MAI blind-upsert dell'entry in arrivo (piano A5c v2
// §3.4, rimedio B3): un backup vecchio con entry pre-analisi non deve
// clobberare un'analisi locale più nuova. La regola vive QUI, pura e senza
// I/O, perché il banco QBeatsTests compila solo Models: la verità sta nelle
// fixture FS5, il manager APPLICA soltanto il vincitore.
// Precondizione del chiamante: existing (se presente) e incoming
// condividono lo stesso filename (la selezione a monte è per-filename).
extension BacktrackFile {
    // Regole (piano §3.4; tie-break esplicitato in A5c-2):
    // 1. esistente ASSENTE o mai-analizzata (tempoMap == nil) → entra
    //    l'arrivo (anche un arrivo mai-analizzato: lettera del piano);
    // 2. arrivo mai-analizzato NON sostituisce un'esistente analizzata;
    // 3. entrambe analizzate → vince tempoMapAnalyzedAt più recente
    //    (nil = più vecchia); PAREGGIO ESATTO (incluso doppio nil) → si
    //    TIENE l'esistente: a parità di informazione la scelta meno
    //    distruttiva è non toccare il dato locale.
    static func merged(existing: BacktrackFile?, incoming: BacktrackFile) -> BacktrackFile {
        guard let existing else { return incoming }               // (1) assente
        guard existing.tempoMap != nil else { return incoming }   // (1) mai analizzata
        guard incoming.tempoMap != nil else { return existing }   // (2)
        switch (existing.tempoMapAnalyzedAt, incoming.tempoMapAnalyzedAt) {
        case (nil, nil):   return existing                        // (3) pareggio di non-datate
        case (_?, nil):    return existing                        // (3) nil = più vecchia
        case (nil, _?):    return incoming
        case let (e?, i?): return i > e ? incoming : existing     // (3) pareggio esatto → esistente
        }
    }
}
