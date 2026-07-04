import Foundation

// === B7-A5b — Song.metronomeMode + decoder retro-compat a 3 livelli ===
// CodingKeys SINTETIZZATE, scelta deliberata (ruling referee 04/07): su un
// modello PERSISTENTE un enum CodingKeys esplicito ha il footgun
// omissione-campo — l'encode sintetico salta un campo dimenticato nell'enum
// SENZA errore di compilazione = perdita-dati al primo re-save. Le
// sintetizzate generano una chiave per OGNI stored property, automatiche.
// ⚠️ GUARD-RAIL RENAME (la chiave JSON segue il nome della property):
// - rename di un campo REQUIRED (id/name/sections/countIn) → i songs.json
//   vecchi non hanno la chiave nuova → keyNotFound → swallow dello store
//   (QBeatsStore.swift:163-165) → WIPE dell'INTERO catalogo;
// - rename di un campo TOLLERANTE (backtrackFilename/metronomeMode) →
//   perdita SILENZIOSA di quel solo campo (nil/.fixed), catalogo vivo.
// Backstop = le fixture di round-trip su JSON vecchio (QBeatsTests), NON le
// CodingKeys: mai rinominare una stored property senza quelle fixture.
struct Song: Codable, Identifiable {
    var id: UUID
    var name: String
    var sections: [SongSection]
    var countIn: Int          // 0=nessuno, 1=1 battuta, 2=2 battute
    var backtrackFilename: String?
    var metronomeMode: MetronomeMode

    // Init esplicito (pattern SongSection.swift:15-37): dichiarare init(from:)
    // nel body SOPPRIME l'init memberwise gratuito — senza questo init i
    // call-site Song(...) esistenti non compilano. Il default `.fixed` in
    // coda li lascia INVARIATI.
    init(
        id: UUID,
        name: String,
        sections: [SongSection],
        countIn: Int,
        backtrackFilename: String?,
        metronomeMode: MetronomeMode = .fixed
    ) {
        self.id = id
        self.name = name
        self.sections = sections
        self.countIn = countIn
        self.backtrackFilename = backtrackFilename
        self.metronomeMode = metronomeMode
    }

    // Backward-compatible decode (pattern SongSection.swift:40-52), 3 livelli.
    // Un throw qui viene INGOIATO dallo store (QBeatsStore.swift:163-165) e
    // per l'utente è il catalogo canzoni VUOTO, reso permanente dal primo
    // save: ogni scelta di questo decoder è anti-perdita-dati.
    // encode(to:) resta SINTETIZZATO (come SongSection).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // TIER 1 — required, STRETTI: throwano su assenza e corruzione (dati
        // veri, non si azzerano in silenzio). `sections` è stretto solo sulla
        // PRESENZA della chiave: dentro ogni sezione decide
        // SongSection.init(from:), che resta tollerante (beatUnit
        // decodeIfPresent ?? 4) e NON si tocca in A5b.
        id       = try c.decode(UUID.self,          forKey: .id)
        name     = try c.decode(String.self,        forKey: .name)
        sections = try c.decode([SongSection].self, forKey: .sections)
        countIn  = try c.decode(Int.self,           forKey: .countIn)
        // TIER 2 — decodeIfPresent, MAI decode: l'encoder sintetico OMETTE la
        // chiave quando il valore è nil → `decode` fallirebbe (keyNotFound)
        // su ogni song reale senza backtrack. Tollerante per ASSENZA; su tipo
        // corrotto throwa comunque (corruzione vera, non retro-compat).
        backtrackFilename = try c.decodeIfPresent(String.self, forKey: .backtrackFilename)
        // TIER 3 — via String, MAI decodeIfPresent(MetronomeMode.self): un
        // rawValue PRESENTE ma ignoto (case futuro arrivato via iCloud da
        // un'app più nuova) farebbe throware l'init sintetizzato dell'enum
        // (dataCorrupted) → swallow → wipe. Stringa grezza + mapping
        // difensivo. Ruling ⑤ EMENDATO (referee 04/07): degrado accettato —
        // valore ignoto → .fixed, e al re-save viene riscritto .fixed: si
        // perde la fedeltà di UN campo, si salva l'INTERO catalogo. Chiave
        // assente (songs.json pre-A5b) → .fixed.
        metronomeMode = try c.decodeIfPresent(String.self, forKey: .metronomeMode)
            .flatMap(MetronomeMode.init(rawValue:)) ?? .fixed
    }
}

extension Song {
    static func makeDefault() -> Song {
        Song(
            id: UUID(),
            name: "New Song",
            sections: [SongSection.makeDefault()],
            countIn: 1,
            backtrackFilename: nil,
            metronomeMode: .fixed
        )
    }

    var estimatedDurationSeconds: Double {
        sections.reduce(0.0) { $0 + $1.estimatedDurationSeconds }
    }
}
