import XCTest

// === B7-A5c-1 — Fixture retro-compat del BackupManifest (banco Models) ===
// Il manifest è la FONTE-DI-VERITÀ del restore: uno schema-break qui =
// restore rotto per ogni .qbeats esistente. Fixture LETTERALI a mano (MAI
// dall'encoder — anti-circolare §7); Date SEMPRE con .iso8601 su encoder E
// decoder (stessa config di store [coordinatedRead/Write] e manager
// [makeEncoder/makeDecoder] — numeri-riga evitati: slittano). FS2 = VECCHIO
// senza chiave "backtracks" → decode OK, nil. FS3′ = round-trip col campo
// nuovo + PIN esclusione `extractedDir`. FS4 = semantica `?? []` (il ramo
// backup-vecchio del restore, in miniatura) + letterale col campo nuovo.

final class BackupManifestCodableTests: XCTestCase {

    private func makeISODecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private func makeISOEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    // MARK: - FS2 — manifest VECCHIO (pre-A5c, SENZA chiave "backtracks")

    func testOldManifestWithoutBacktracksKeyDecodes() throws {
        // Forma REALE di un manifest.json pre-A5c: 5 chiavi, una song in
        // formato VECCHIO (senza metronomeMode né backtrackFilename). La
        // chiave "backtracks" NON esiste → decodeIfPresent → nil, NO throw.
        let literal = Data("""
        {
          "exportedAt" : "2026-05-13T13:28:46Z",
          "hasSettings" : false,
          "setlists" : [],
          "songs" : [
            {
              "song" : {
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
            }
          ],
          "version" : 1
        }
        """.utf8)

        let m = try makeISODecoder().decode(BackupManifest.self, from: literal)
        XCTAssertNil(m.backtracks)               // chiave assente → nil, no throw
        XCTAssertEqual(m.version, 1)
        XCTAssertFalse(m.hasSettings)
        XCTAssertEqual(m.setlists.count, 0)
        XCTAssertEqual(m.songs.count, 1)
        XCTAssertEqual(m.songs.first?.song.name, "Vecchia Song")
        XCTAssertNil(m.songs.first?.audioFilename)
        // Transitività A5b sotto il manifest: song vecchia → .fixed + nil
        XCTAssertEqual(m.songs.first?.song.metronomeMode, .fixed)
        XCTAssertNil(m.songs.first?.song.backtrackFilename)
        XCTAssertNil(m.extractedDir)             // runtime-only, mai dal filo
    }

    // MARK: - FS3′ — round-trip NUOVO con backtracks (config .iso8601)

    func testNewManifestRoundTripWithBacktracks() throws {
        let bt = BacktrackFile(
            filename: "bench_song.mp3",
            tempoMap: [
                TempoPoint(sampleOffset: 0, bpm: 119.0),
                TempoPoint(sampleOffset: 720_000, bpm: 123.0)
            ],
            tempoMapSampleRate: 48_000.0,
            tempoMapConfidence: 0.75,
            // Secondi INTERI: .iso8601 tronca i sub-secondi — un valore
            // frazionario non round-tripperebbe (falso rosso).
            tempoMapAnalyzedAt: Date(timeIntervalSinceReferenceDate: 778_000_000.0)
        )
        var original = BackupManifest(
            exportedAt: Date(timeIntervalSinceReferenceDate: 778_100_000.0),
            hasSettings: false,
            songs: [],
            setlists: [],
            backtracks: [bt]
        )
        original.extractedDir = URL(fileURLWithPath: "/tmp/qbeats_test")  // runtime-only

        let data = try makeISOEncoder().encode(original)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        // PIN item-6 (ruling referee): extractedDir è FUORI da CodingKeys —
        // un path temp device-specifico non deve MAI entrare nel .qbeats.
        XCTAssertFalse(json.contains("extractedDir"))
        XCTAssertTrue(json.contains("\"backtracks\""))    // il campo nuovo viaggia

        let decoded = try makeISODecoder().decode(BackupManifest.self, from: data)
        XCTAssertEqual(decoded.backtracks, [bt])          // BacktrackFile: Equatable
        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.hasSettings, original.hasSettings)
        XCTAssertEqual(decoded.exportedAt, original.exportedAt)
        XCTAssertEqual(decoded.songs.count, 0)
        XCTAssertEqual(decoded.setlists.count, 0)
        XCTAssertNil(decoded.extractedDir)                // non round-trippa (runtime)
    }

    // MARK: - FS4 — semantica `?? []` (ramo backup-vecchio del restore)

    func testBacktracksNilCoalescesToEmpty() throws {
        // Manifest VECCHIO minimo: ciò che il ramo (b) del restore vedrà —
        // `manifest.backtracks ?? []` DEVE dare lista vuota, mai un throw.
        let old = Data("""
        {"exportedAt":"2026-01-01T00:00:00Z","hasSettings":false,"setlists":[],"songs":[],"version":1}
        """.utf8)
        let m = try makeISODecoder().decode(BackupManifest.self, from: old)
        XCTAssertEqual(m.backtracks ?? [], [])

        // Controprova: letterale NUOVO con la chiave (scritta A MANO — pin
        // non-circolare del nome "backtracks" sul filo) → non-nil, 1 entry.
        let new = Data("""
        {"backtracks":[{"filename":"x.mp3"}],"exportedAt":"2026-01-01T00:00:00Z","hasSettings":false,"setlists":[],"songs":[],"version":1}
        """.utf8)
        let m2 = try makeISODecoder().decode(BackupManifest.self, from: new)
        XCTAssertEqual(m2.backtracks?.count, 1)
        XCTAssertEqual(m2.backtracks?.first?.filename, "x.mp3")
        XCTAssertNil(m2.backtracks?.first?.tempoMap)      // mai analizzata
    }
}
