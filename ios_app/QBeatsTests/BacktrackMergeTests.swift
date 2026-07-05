import XCTest

// === B7-A5c-2 — FS5: politica di merge del restore (banco Models) ===
// BacktrackFile.merged è LA regola anti-perdita-dati del restore (piano A5c
// v2 §3.4, rimedio B3) e questo è il suo unico banco automatico: l'end-to-end
// (ex-FS1) è demansionato a gate DEVICE per costruzione (zip + store reali
// fuori dal target). Attesi LETTERALI (§7): ogni caso costruisce existing e
// incoming a mano e pinna il vincitore per contenuto — mai ricalcolando la
// regola. Il bpm marchia la provenienza (locale = 100, arrivo = 140); le
// Date sono timeIntervalSinceReferenceDate LETTERALI, mai Date() runtime.

final class BacktrackMergeTests: XCTestCase {

    // Fabbriche SENZA logica (solo campi espliciti): un backtrack analizzato
    // col bpm-marchio richiesto, e uno mai-analizzato (tutti i campi mappa
    // nil — il marcatore è tempoMap == nil, BacktrackFile.swift).
    private func analyzed(bpm: Double, at analyzedAt: Date?) -> BacktrackFile {
        BacktrackFile(
            filename: "track.wav",
            tempoMap: [TempoPoint(sampleOffset: 0, bpm: bpm)],
            tempoMapSampleRate: 48_000.0,
            tempoMapConfidence: 0.9,
            tempoMapAnalyzedAt: analyzedAt
        )
    }

    private func neverAnalyzed() -> BacktrackFile {
        BacktrackFile(
            filename: "track.wav",
            tempoMap: nil,
            tempoMapSampleRate: nil,
            tempoMapConfidence: nil,
            tempoMapAnalyzedAt: nil
        )
    }

    private let older = Date(timeIntervalSinceReferenceDate: 700_000_000.0)
    private let newer = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

    // MARK: - Regola 1 — esistente assente o mai-analizzata: entra l'arrivo

    func testIncomingEntersWhenExistingAbsent() {
        let incoming = analyzed(bpm: 140.0, at: older)
        let result = BacktrackFile.merged(existing: nil, incoming: incoming)
        XCTAssertEqual(result, incoming)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 140.0)
    }

    func testIncomingEntersWhenExistingNeverAnalyzed() {
        let incoming = analyzed(bpm: 140.0, at: older)
        let result = BacktrackFile.merged(existing: neverAnalyzed(), incoming: incoming)
        XCTAssertEqual(result, incoming)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 140.0)
    }

    func testIncomingEntersWhenBothNeverAnalyzed() {
        // Lettera del piano §3.4: «se l'esistente manca o è nil-mappa, entra
        // l'arrivo» — vale anche quando l'arrivo è a sua volta nil-mappa
        // (contenuto informativo equivalente, nessun dato da proteggere).
        // ONESTÀ DEL BANCO: due mai-analizzate sono Equatable-uguali per
        // costruzione → questo test DOCUMENTA il ramo, non lo falsifica
        // (passerebbe anche tenendo l'esistente; distinguerle richiederebbe
        // una fixture incoerente col modello A5a "tutti nil = mai analizzata").
        let incoming = neverAnalyzed()
        let result = BacktrackFile.merged(existing: neverAnalyzed(), incoming: incoming)
        XCTAssertEqual(result, incoming)
        XCTAssertNil(result.tempoMap)
    }

    // MARK: - Regola 2 — nil NON sovrascrive analizzata

    func testNeverAnalyzedIncomingDoesNotOverwriteAnalyzed() {
        // IL caso B3: backup vecchio con entry pre-analisi vs analisi locale.
        let existing = analyzed(bpm: 100.0, at: newer)
        let result = BacktrackFile.merged(existing: existing, incoming: neverAnalyzed())
        XCTAssertEqual(result, existing)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 100.0)  // la locale sopravvive
    }

    // MARK: - Regola 3 — entrambe analizzate: più recente vince

    func testNewerIncomingWins() {
        let existing = analyzed(bpm: 100.0, at: older)
        let incoming = analyzed(bpm: 140.0, at: newer)
        let result = BacktrackFile.merged(existing: existing, incoming: incoming)
        XCTAssertEqual(result, incoming)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 140.0)
    }

    func testNewerExistingWins() {
        let existing = analyzed(bpm: 100.0, at: newer)
        let incoming = analyzed(bpm: 140.0, at: older)
        let result = BacktrackFile.merged(existing: existing, incoming: incoming)
        XCTAssertEqual(result, existing)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 100.0)
    }

    func testNilAnalyzedAtCountsAsOlder() {
        // nil = più vecchia, nelle DUE direzioni. Assert full-struct come
        // negli altri rami: pinna il vincitore per contenuto INTERO (esclude
        // un ipotetico field-mixing), il bpm resta come marchio leggibile.
        let undatedExisting = analyzed(bpm: 100.0, at: nil)
        let datedIncoming = analyzed(bpm: 140.0, at: older)
        let r1 = BacktrackFile.merged(existing: undatedExisting, incoming: datedIncoming)
        XCTAssertEqual(r1, datedIncoming)                       // datata batte non-datata
        XCTAssertEqual(r1.tempoMap?.first?.bpm, 140.0)

        let datedExisting = analyzed(bpm: 100.0, at: older)
        let undatedIncoming = analyzed(bpm: 140.0, at: nil)
        let r2 = BacktrackFile.merged(existing: datedExisting, incoming: undatedIncoming)
        XCTAssertEqual(r2, datedExisting)                       // idem, ruoli invertiti
        XCTAssertEqual(r2.tempoMap?.first?.bpm, 100.0)
    }

    // MARK: - Regola 3, tie-break — pareggio: si TIENE l'esistente

    func testExactTieKeepsExisting() {
        // Pareggio ESATTO di tempoMapAnalyzedAt (stesso istante letterale):
        // a parità di informazione vince la scelta meno distruttiva — il
        // dato locale non si tocca.
        let existing = analyzed(bpm: 100.0, at: newer)
        let incoming = analyzed(bpm: 140.0, at: newer)
        let result = BacktrackFile.merged(existing: existing, incoming: incoming)
        XCTAssertEqual(result, existing)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 100.0)
    }

    func testBothNilAnalyzedAtKeepsExisting() {
        // Doppio nil = pareggio di non-datate → esistente.
        let existing = analyzed(bpm: 100.0, at: nil)
        let incoming = analyzed(bpm: 140.0, at: nil)
        let result = BacktrackFile.merged(existing: existing, incoming: incoming)
        XCTAssertEqual(result, existing)
        XCTAssertEqual(result.tempoMap?.first?.bpm, 100.0)
    }
}
