import XCTest

// === B7-A5-pre — Banco Swift: test minimo di infrastruttura ===
// UN test che prova che il target compila, linka i Models e gira in CI:
// round-trip Codable della Song ATTUALE (5 campi). Asserzioni CAMPO-PER-CAMPO
// (D2, ratifica referee 03/07/2026): Song/SongSection non sono Equatable e i
// Models NON si toccano in A5-pre. Deterministico: zero I/O, zero Date, zero
// random (UUID generati ma confrontati solo con sé stessi post-round-trip).
// I Double di fixture sono frazioni binarie ESATTE (97.5, 0.625, 0.5): il
// confronto è di uguaglianza esatta, mai a tolleranza.
// I 5 fixture-test del modello dati (decodeIfPresent ?? .fixed, BacktrackFile,
// TempoPoint) arrivano con l'atomo A5 — NON qui.

final class SongCodableRoundTripTests: XCTestCase {

    func testSongRoundTripFieldByField() throws {
        let s1 = SongSection(
            id: UUID(),
            name: "Intro",
            bpm: 97.5,
            beatsPerBar: 7,
            beatUnit: 8,
            repetitions: 3,
            notes: "count-in on hats",
            accentPattern: [2, 0, 1, 0, 1, 0, 1],
            subdivisionMultiplier: 3,
            swingRatio: 0.625
        )
        let s2 = SongSection(
            id: UUID(),
            name: "Chorus",
            bpm: 141.0,
            beatsPerBar: 3,
            beatUnit: 4,
            repetitions: -1,          // sentinel loop infinito (SongSection.swift:9)
            notes: "open hats",
            accentPattern: [2, 1, 1],
            subdivisionMultiplier: 2,
            swingRatio: 0.5
        )
        let original = Song(
            id: UUID(),
            name: "Bench Song",
            sections: [s1, s2],
            countIn: 2,
            backtrackFilename: "bench_song.mp3"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Song.self, from: data)

        // Song — campo per campo
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.countIn, original.countIn)
        XCTAssertEqual(decoded.backtrackFilename, original.backtrackFilename)
        XCTAssertEqual(decoded.sections.count, original.sections.count)

        // Prima section — i 10 campi
        let d1 = try XCTUnwrap(decoded.sections.first)
        XCTAssertEqual(d1.id, s1.id)
        XCTAssertEqual(d1.name, s1.name)
        XCTAssertEqual(d1.bpm, s1.bpm)
        XCTAssertEqual(d1.beatsPerBar, s1.beatsPerBar)
        XCTAssertEqual(d1.beatUnit, s1.beatUnit)
        XCTAssertEqual(d1.repetitions, s1.repetitions)
        XCTAssertEqual(d1.notes, s1.notes)
        XCTAssertEqual(d1.accentPattern, s1.accentPattern)
        XCTAssertEqual(d1.subdivisionMultiplier, s1.subdivisionMultiplier)
        XCTAssertEqual(d1.swingRatio, s1.swingRatio)
    }
}
