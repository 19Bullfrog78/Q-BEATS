import XCTest

// === B7-A5b — Fixture retro-compat del decoder di Song (3 livelli) ===
// Fixture LETTERALI scritte a mano — MAI generate dal nuovo encoder
// (auto-conferma circolare §7). Song NON è Equatable (D2) → confronti
// campo-per-campo. Un fallimento di decode qui, in produzione, è il catalogo
// canzoni VUOTO (swallow QBeatsStore.swift:163-165, permanente al primo
// save): questi test sono il guardiano anti-perdita-dati dell'atomo A5b.
// F1 doppia-chiave-assente · F2 round-trip .adaptive (config store) ·
// F4 filo-in off/adaptive · F5 rawValue ignoto → .fixed (ruling ⑤ emendato)
// · F6 sezione formato VECCHIO senza beatUnit sotto il nuovo decoder.
// Deterministico: zero I/O, zero Date, Double = frazioni binarie esatte.

final class SongRetroCompatDecodingTests: XCTestCase {

    // MARK: - F1 — vecchio formato: senza "metronomeMode" E senza "backtrackFilename"

    func testOldFormatSongDoubleAbsentKeys() throws {
        // Song REALE pre-A5b: niente "metronomeMode" (campo non esisteva) e
        // niente "backtrackFilename" (l'encoder sintetico OMETTE la chiave
        // quando nil — così appare sul device ogni song senza backtrack).
        // Espone il wipe se qualcuno regredisce backtrackFilename a `decode`.
        let literal = Data("""
        {
          "countIn" : 1,
          "id" : "11111111-2222-3333-4444-555555555555",
          "name" : "Vecchia Song",
          "sections" : [
            {
              "accentPattern" : [2, 0, 1, 0],
              "beatUnit" : 4,
              "beatsPerBar" : 4,
              "bpm" : 120,
              "id" : "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
              "name" : "Intro",
              "notes" : "",
              "repetitions" : 4,
              "subdivisionMultiplier" : 1,
              "swingRatio" : 0.5
            }
          ]
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(Song.self, from: literal)
        XCTAssertEqual(decoded.metronomeMode, .fixed)      // chiave assente → default
        XCTAssertNil(decoded.backtrackFilename)            // chiave assente → nil
        XCTAssertEqual(decoded.id, UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        XCTAssertEqual(decoded.name, "Vecchia Song")
        XCTAssertEqual(decoded.countIn, 1)
        XCTAssertEqual(decoded.sections.count, 1)
        let s = try XCTUnwrap(decoded.sections.first)
        XCTAssertEqual(s.bpm, 120.0)
        XCTAssertEqual(s.beatsPerBar, 4)
    }

    // MARK: - F2 — round-trip .adaptive con la config dello store

    func testRoundTripAdaptiveWithStoreConfig() throws {
        let original = Song(
            id: UUID(),
            name: "Round Trip",
            sections: [SongSection.makeDefault()],
            countIn: 2,
            backtrackFilename: "base.mp3",
            metronomeMode: .adaptive
        )

        // Stessa config dello store: encoder QBeatsStore.swift:175-177,
        // decoder :159-160.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Song.self, from: data)

        // Campo-per-campo (Song non è Equatable — D2)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.countIn, original.countIn)
        XCTAssertEqual(decoded.backtrackFilename, original.backtrackFilename)
        XCTAssertEqual(decoded.metronomeMode, .adaptive)
        XCTAssertEqual(decoded.sections.count, original.sections.count)
        let d = try XCTUnwrap(decoded.sections.first)
        let o = try XCTUnwrap(original.sections.first)
        XCTAssertEqual(d.id, o.id)
        XCTAssertEqual(d.bpm, o.bpm)
        XCTAssertEqual(d.beatUnit, o.beatUnit)
    }

    // MARK: - F4 — filo-in: "off" / "adaptive" espliciti → case giusto

    func testDecodeExplicitModeLiterals() throws {
        // Coppie (filo, case) LETTERALI — l'atteso non deriva dal decoder.
        let expected: [(String, MetronomeMode)] = [
            ("off", .off), ("adaptive", .adaptive)
        ]
        for (wire, mode) in expected {
            let literal = Data("""
            {"countIn":0,"id":"11111111-2222-3333-4444-555555555555","metronomeMode":"\(wire)","name":"M","sections":[]}
            """.utf8)
            let decoded = try JSONDecoder().decode(Song.self, from: literal)
            XCTAssertEqual(decoded.metronomeMode, mode)
        }
    }

    // MARK: - F5 — rawValue ignoto → .fixed, NON throw (ruling ⑤ emendato)

    func testUnknownRawValueDegradesToFixed() throws {
        // Un case futuro (es. "swing" da un'app più nuova via iCloud) NON
        // deve far fallire il decode del catalogo: degrado a .fixed.
        let literal = Data("""
        {"countIn":0,"id":"11111111-2222-3333-4444-555555555555","metronomeMode":"swing","name":"S","sections":[]}
        """.utf8)
        let decoded = try JSONDecoder().decode(Song.self, from: literal)
        XCTAssertEqual(decoded.metronomeMode, .fixed)
    }

    // MARK: - F6 — sezione formato VECCHIO (senza beatUnit) sotto il nuovo decoder

    func testOldFormatSectionWithoutBeatUnitSurvives() throws {
        // Il retro-compat di SongSection (SongSection.swift:40-52,
        // decodeIfPresent ?? 4) deve reggere INVARIATO sotto il nuovo
        // init(from:) di Song — è ciò che tiene vivi i songs.json con
        // sezioni pre-beatUnit. Fixture integrale vecchio formato: senza
        // beatUnit, senza metronomeMode, senza backtrackFilename.
        let literal = Data("""
        {
          "countIn" : 0,
          "id" : "22222222-3333-4444-5555-666666666666",
          "name" : "Song Sezioni Vecchie",
          "sections" : [
            {
              "accentPattern" : [1, 0, 0],
              "beatsPerBar" : 3,
              "bpm" : 90,
              "id" : "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF",
              "name" : "Valzer",
              "notes" : "",
              "repetitions" : 8,
              "subdivisionMultiplier" : 1,
              "swingRatio" : 0.5
            }
          ]
        }
        """.utf8)

        let decoded = try JSONDecoder().decode(Song.self, from: literal)
        let s = try XCTUnwrap(decoded.sections.first)
        XCTAssertEqual(s.beatUnit, 4)                      // decodeIfPresent ?? 4
        XCTAssertEqual(s.beatsPerBar, 3)
        XCTAssertEqual(s.bpm, 90.0)
        XCTAssertEqual(decoded.metronomeMode, .fixed)
        XCTAssertNil(decoded.backtrackFilename)
    }
}
