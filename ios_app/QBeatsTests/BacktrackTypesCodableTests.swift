import XCTest

// === B7-A5a — Fixture Codable dei tre tipi nuovi (inerti) ===
// TempoPoint / MetronomeMode / BacktrackFile: round-trip + PIN del formato
// filo. Il solo round-trip NON prova l'allineamento col C++ (tornerebbe
// identico anche con chiavi sbagliate — auto-conferma circolare, §7): le
// chiavi JSON sono asserite come STRINGHE LETTERALI ("sampleOffset","bpm" =
// TempoMapJSON.h:9) e un decode parte da JSON LETTERALE nella forma che il
// C++ emette (TempoMapJSON.cpp:144-149). Deterministico: zero I/O, zero
// random, Date FISSA da intervallo binariamente esatto; Double di fixture =
// frazioni binarie esatte (121.5, 0.75, …) → uguaglianza esatta, mai a
// tolleranza (stesso criterio di SongCodableRoundTripTests).

final class BacktrackTypesCodableTests: XCTestCase {

    // MARK: - TempoPoint

    func testTempoPointRoundTripAndWireKeys() throws {
        // sampleOffset > 2^32 per pinnare la larghezza UInt64 (48 kHz · ~28 h)
        let original = TempoPoint(sampleOffset: 4_800_000_000, bpm: 121.5)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TempoPoint.self, from: data)
        XCTAssertEqual(decoded, original)

        // PIN delle chiavi filo — identiche al C++ (ruling ⑤)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"sampleOffset\""))
        XCTAssertTrue(json.contains("\"bpm\""))
    }

    func testTempoPointDecodesCppShapedLiteral() throws {
        // JSON nella forma ESATTA che il serializzatore C++ emette per un
        // punto (TempoMapJSON.cpp:144-149): prova di allineamento non
        // circolare — se le CodingKeys divergessero, questo decode fallirebbe.
        let literal = Data(#"{"sampleOffset":96000,"bpm":121.5}"#.utf8)
        let decoded = try JSONDecoder().decode(TempoPoint.self, from: literal)
        XCTAssertEqual(decoded, TempoPoint(sampleOffset: 96_000, bpm: 121.5))
    }

    // MARK: - MetronomeMode

    func testMetronomeModeRawValuesAreStable() {
        // Contratto filo: queste stringhe finiranno nei file utente (A5b)
        XCTAssertEqual(MetronomeMode.off.rawValue, "off")
        XCTAssertEqual(MetronomeMode.fixed.rawValue, "fixed")
        XCTAssertEqual(MetronomeMode.adaptive.rawValue, "adaptive")
        XCTAssertEqual(MetronomeMode.allCases, [.off, .fixed, .adaptive])
    }

    func testMetronomeModeRoundTripEveryCase() throws {
        // Coppie (case, filo) LETTERALI: l'atteso NON deriva da rawValue —
        // niente auto-conferma (§7). Il count-check impedisce a un case
        // futuro di sfuggire alla lista.
        let expected: [(MetronomeMode, String)] = [
            (.off, "off"), (.fixed, "fixed"), (.adaptive, "adaptive")
        ]
        XCTAssertEqual(MetronomeMode.allCases.count, expected.count)

        for (mode, wire) in expected {
            // Incapsulato in array: nessun fragment JSON top-level in gioco
            let data = try JSONEncoder().encode([mode])
            let json = try XCTUnwrap(String(data: data, encoding: .utf8))
            XCTAssertEqual(json, "[\"\(wire)\"]")            // filo esatto
            let decoded = try JSONDecoder().decode([MetronomeMode].self, from: data)
            XCTAssertEqual(decoded, [mode])
        }
    }

    // MARK: - BacktrackFile

    func testBacktrackFileRoundTripAllFieldsSet() throws {
        let original = BacktrackFile(
            filename: "bench_song.mp3",
            tempoMap: [
                TempoPoint(sampleOffset: 0, bpm: 119.0),
                TempoPoint(sampleOffset: 720_000, bpm: 123.0),
                TempoPoint(sampleOffset: 4_800_000_000, bpm: 121.5)
            ],
            tempoMapSampleRate: 48_000.0,
            tempoMapConfidence: 0.75,
            tempoMapAnalyzedAt: Date(timeIntervalSinceReferenceDate: 778_000_000.5)
        )
        XCTAssertEqual(original.id, original.filename)   // Identifiable: id = filename

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BacktrackFile.self, from: data)
        XCTAssertEqual(decoded, original)

        // PIN del nome-campo ratificato (ruling ⑤) e delle altre chiavi del
        // formato persistente che A5c erediterà (backtracks.json + backup)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        for key in ["filename", "tempoMap", "tempoMapSampleRate",
                    "tempoMapConfidence", "tempoMapAnalyzedAt"] {
            XCTAssertTrue(json.contains("\"\(key)\""),
                          "chiave assente dal filo: \(key)")
        }
        // `id` è computed (non in CodingKeys): NON deve finire sul filo
        XCTAssertFalse(json.contains("\"id\""))
    }

    func testBacktrackFileNeverAnalyzedRoundTrip() throws {
        // Base MAI analizzata = TUTTI i campi mappa nil (semantica piano A5:
        // il marcatore è nil, NON l'array vuoto). Il decode deve restituire
        // nil, non fallire (terreno che A5b/A5c calpesteranno).
        let original = BacktrackFile(
            filename: "mai_analizzata.wav",
            tempoMap: nil,
            tempoMapSampleRate: nil,
            tempoMapConfidence: nil,
            tempoMapAnalyzedAt: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BacktrackFile.self, from: data)
        XCTAssertEqual(decoded, original)

        // encodeIfPresent sintetizzato: gli optional nil OMETTONO la chiave
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        for key in ["tempoMap", "tempoMapSampleRate",
                    "tempoMapConfidence", "tempoMapAnalyzedAt"] {
            XCTAssertFalse(json.contains("\"\(key)\""),
                           "chiave inattesa nel filo: \(key)")
        }

        // Contro-prova della distinzione: [] sul filo decodifica in []
        // (analizzata, mappa vuota), NON in nil — nil ≠ [] anche al decode.
        let literal = Data(#"{"filename":"vuota.mp3","tempoMap":[]}"#.utf8)
        let empty = try JSONDecoder().decode(BacktrackFile.self, from: literal)
        XCTAssertEqual(empty.tempoMap, [])
        XCTAssertNil(empty.tempoMapSampleRate)
    }
}
