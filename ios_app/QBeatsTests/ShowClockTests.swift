import XCTest

// === A410 — banco del conteggio in silenzio (`ShowClock`, banco Models) ===
// Mandato A410, §3: dentro una sezione; attraverso metri diversi (Test Song A, 4/4 → 4/4 → 3/4);
// fine canzone esatta e oltre; ciclo; 100 → 120 → 140 coi numeri di L1.b; zero, negativi, enormi;
// prossimo inizio di battuta; disaccordo dei righelli.
// Le canzoni sono quelle dei dati di prova della schermata Debug (`DebugView`):
//  · «Test Song A» (`loadTestDataL1b`): Intro 100 4/4 × 12 battute, Verse 120 4/4 × 3, Bridge 140 3/4 × 2
//    — 48 + 12 + 6 = 66 battiti, 28,8 + 6,0 + 2,571428… = 37,371428… s;
//  · «3/4 Long» (`loadTestData34Long`): 4/4 × 8, 3/4 × 16, 4/4 × 8, tutte a 100.
// 24.000.000 tick al secondo (misura A382 §3.6: il tipo riceve i tick al secondo dal chiamante).
// Gli attesi sono scritti per esteso, dai numeri delle canzoni, non ricavati dal tipo.

final class ShowClockTests: XCTestCase {

    private let tps = 24_000_000.0
    private let second: UInt64 = 24_000_000

    private let songA = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 12, bpm: 100),
        SongMapSection(beatsPerBar: 4, repetitions: 3, bpm: 120),
        SongMapSection(beatsPerBar: 3, repetitions: 2, bpm: 140),
    ])

    private let threeFourLong = SongMap(sections: [
        SongMapSection(beatsPerBar: 4, repetitions: 8, bpm: 100),
        SongMapSection(beatsPerBar: 3, repetitions: 16, bpm: 100),
        SongMapSection(beatsPerBar: 4, repetitions: 8, bpm: 100),
    ])

    /// L'ora dell'àncora di tutti i casi: 100 s.
    private var anchorTicks: UInt64 { 100 * second }

    private func ticks(afterAnchor seconds: Double) -> UInt64 {
        if seconds >= 0 {
            return anchorTicks + UInt64((seconds * tps).rounded())
        }
        return anchorTicks - UInt64((-seconds * tps).rounded())
    }

    private func clock(_ map: SongMap, section: Int, beat: Int, linkBeat: Double) -> ShowClock {
        ShowClock(map: map, anchor: ShowClockAnchor(section: section, beatInSection: beat,
                                                    linkBeat: linkBeat, ticks: anchorTicks))
    }

    /// Sezione e battiti di un posto dentro la canzone, o `nil`.
    private func inSong(_ place: ShowClockPlace) -> (section: Int, beat: Double)? {
        if case .inSong(let section, let beat) = place { return (section, beat) }
        return nil
    }

    private func pastEnd(_ place: ShowClockPlace) -> Double? {
        if case .pastEnd(let beats) = place { return beats }
        return nil
    }

    // MARK: - Dentro una sezione

    /// Àncora al battito 8 dell'Intro (battuta 3, battito 1), battito di Link 500. Sei battiti e
    /// mezzo dopo (3,9 s a 100): battuta 4, battito 3; il prossimo «uno» è il battito 16 = Link 508.
    func testInsideASection() {
        let c = clock(songA, section: 0, beat: 8, linkBeat: 500)
        let reading = c.read(nowLinkBeat: 506.5, nowTicks: ticks(afterAnchor: 3.9), ticksPerSecond: tps)
        let byBeats = inSong(reading.byLinkBeats.place)
        XCTAssertEqual(byBeats?.section, 0)
        XCTAssertEqual(byBeats?.beat ?? -1, 14.5, accuracy: 1e-9)
        let bySeconds = inSong(reading.bySeconds.place)
        XCTAssertEqual(bySeconds?.section, 0)
        XCTAssertEqual(bySeconds?.beat ?? -1, 14.5, accuracy: 1e-6)
        XCTAssertEqual(reading.gapBeats ?? 99, 0, accuracy: 1e-6)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 0, bar: 4, beat: 3,
                               nextDownbeat: ShowClockDownbeat(section: 0, bar: 5, beatInSection: 16, linkBeat: 508)))
    }

    // MARK: - Attraverso metri diversi

    /// Àncora al battito 40 dell'Intro (battuta 11), Link 1000. 21,5 battiti dopo: 8 per finire
    /// l'Intro, 12 del Verse, 1,5 nel Bridge in 3/4 → battuta 1, battito 2; il prossimo «uno» è la
    /// battuta 2 del Bridge, 8 + 12 + 3 = 23 battiti dopo l'àncora. In secondi: 4,8 + 6,0 + 1,5 × 60/140.
    func testAcrossMeters() {
        let c = clock(songA, section: 0, beat: 40, linkBeat: 1000)
        let seconds = 4.8 + 6.0 + 1.5 * 60.0 / 140.0
        let reading = c.read(nowLinkBeat: 1021.5, nowTicks: ticks(afterAnchor: seconds), ticksPerSecond: tps)
        XCTAssertEqual(inSong(reading.byLinkBeats.place)?.section, 2)
        XCTAssertEqual(inSong(reading.byLinkBeats.place)?.beat ?? -1, 1.5, accuracy: 1e-9)
        XCTAssertEqual(inSong(reading.bySeconds.place)?.section, 2)
        XCTAssertEqual(inSong(reading.bySeconds.place)?.beat ?? -1, 1.5, accuracy: 1e-6)
        XCTAssertEqual(reading.bySeconds.beatsFromAnchor, 21.5, accuracy: 1e-6)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 2, bar: 1, beat: 2,
                               nextDownbeat: ShowClockDownbeat(section: 2, bar: 2, beatInSection: 3, linkBeat: 1023)))
    }

    /// Nel Verse (4/4 a 120): 10 battiti dopo l'àncora del 40 si è al battito 2 del Verse.
    func testFromIntroIntoTheVerse() {
        let c = clock(songA, section: 0, beat: 40, linkBeat: 1000)
        let reading = c.read(nowLinkBeat: 1010, nowTicks: ticks(afterAnchor: 4.8 + 2 * 0.5), ticksPerSecond: tps)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 1, bar: 1, beat: 3,
                               nextDownbeat: ShowClockDownbeat(section: 1, bar: 2, beatInSection: 4, linkBeat: 1012)))
    }

    // MARK: - La fine della canzone

    /// Dal battito 40 dell'Intro alla fine: 8 + 12 + 6 = 26 battiti → Link 1026; in secondi
    /// 4,8 + 6,0 + 6 × 60/140 = 13,371428… s.
    func testSongEndExactlyAndBeyond() {
        let c = clock(songA, section: 0, beat: 40, linkBeat: 1000)
        let endSeconds = 4.8 + 6.0 + 6.0 * 60.0 / 140.0
        XCTAssertEqual(c.endLinkBeat, 1026)
        XCTAssertEqual(Double(c.endTicks(ticksPerSecond: tps) ?? 0), Double(ticks(afterAnchor: endSeconds)), accuracy: 2)

        // Esattamente alla fine: il righello dei battiti è oltre la fine di 0.
        let atEnd = c.read(nowLinkBeat: 1026, nowTicks: ticks(afterAnchor: endSeconds), ticksPerSecond: tps)
        XCTAssertEqual(pastEnd(atEnd.byLinkBeats.place) ?? -1, 0, accuracy: 1e-9)
        XCTAssertTrue(atEnd.certain)
        if case .songEnded(let endBeat, let endTicks) = atEnd.outcome {
            XCTAssertEqual(endBeat, 1026)
            XCTAssertEqual(Double(endTicks ?? 0), Double(ticks(afterAnchor: endSeconds)), accuracy: 2)
        } else {
            XCTFail("atteso songEnded, avuto \(atEnd.outcome)")
        }

        // Un decimo di battito prima della fine: Bridge battuta 2, battito 3, e nessun «uno» dopo.
        let justBefore = c.read(nowLinkBeat: 1025.9,
                                nowTicks: ticks(afterAnchor: endSeconds - 0.1 * 60.0 / 140.0),
                                ticksPerSecond: tps)
        XCTAssertTrue(justBefore.certain)
        XCTAssertEqual(justBefore.outcome, .inSong(section: 2, bar: 2, beat: 3, nextDownbeat: nil))

        // Oltre: quattro battiti dopo la fine (al tempo dell'ultima sezione per i secondi).
        let beyond = c.read(nowLinkBeat: 1030,
                            nowTicks: ticks(afterAnchor: endSeconds + 4.0 * 60.0 / 140.0),
                            ticksPerSecond: tps)
        XCTAssertEqual(pastEnd(beyond.byLinkBeats.place) ?? -1, 4, accuracy: 1e-9)
        XCTAssertEqual(pastEnd(beyond.bySeconds.place) ?? -1, 4, accuracy: 1e-6)
        XCTAssertTrue(beyond.certain)
        if case .songEnded(let endBeat, _) = beyond.outcome {
            XCTAssertEqual(endBeat, 1026)
        } else {
            XCTFail("atteso songEnded, avuto \(beyond.outcome)")
        }
    }

    // MARK: - Il ciclo

    /// Due battute di 4/4, poi un ciclo. Dentro la prima sezione il conto c'è; il prossimo «uno»
    /// cadrebbe all'inizio del ciclo: non si dà. Oltre, «non so». Con l'àncora nel ciclo, «non so».
    func testCycle() {
        let map = SongMap(sections: [
            SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 100),
            SongMapSection(beatsPerBar: 4, repetitions: -1, bpm: 100),
        ])
        XCTAssertTrue(map.sections[1].isCycle)
        XCTAssertEqual(map.sections[1].totalBeats, 0)
        XCTAssertTrue(map.isValid)
        let c = clock(map, section: 0, beat: 4, linkBeat: 0)
        XCTAssertNil(c.endLinkBeat)
        XCTAssertNil(c.endTicks(ticksPerSecond: tps))

        let inside = c.read(nowLinkBeat: 3, nowTicks: ticks(afterAnchor: 1.8), ticksPerSecond: tps)
        XCTAssertTrue(inside.certain)
        XCTAssertEqual(inside.outcome, .inSong(section: 0, bar: 2, beat: 4, nextDownbeat: nil))
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 3.5), .unknown(.cycle))

        let through = c.read(nowLinkBeat: 5, nowTicks: ticks(afterAnchor: 3.0), ticksPerSecond: tps)
        XCTAssertEqual(through.byLinkBeats.place, .unknown(.cycle))
        XCTAssertEqual(through.bySeconds.place, .unknown(.cycle))
        XCTAssertFalse(through.certain)
        XCTAssertEqual(through.outcome, .unknown(.cycle))

        let anchoredInCycle = clock(map, section: 1, beat: 0, linkBeat: 0)
        XCTAssertEqual(anchoredInCycle.invalidity, .cycle)
        XCTAssertEqual(anchoredInCycle.read(nowLinkBeat: 1, nowTicks: ticks(afterAnchor: 0.6),
                                            ticksPerSecond: tps).outcome, .unknown(.cycle))
    }

    // MARK: - 100 → 120 → 140, i numeri di L1.b

    /// Dall'inizio della canzone (Intro, battito 0): l'Intro dura 28,8 s, il Verse 6,0 s, il Bridge
    /// 2,571428… s. A 30 s si è al battito 2,4 del Verse; a 35 s al battito 0,2 × 140/60 del Bridge;
    /// a 40 s oltre la fine di 2,628571… × 140/60 battiti.
    func testTheNumbersOfL1b() {
        let c = clock(songA, section: 0, beat: 0, linkBeat: 0)
        XCTAssertEqual(c.endLinkBeat, 66)
        XCTAssertEqual(Double(c.endTicks(ticksPerSecond: tps) ?? 0),
                       Double(ticks(afterAnchor: 28.8 + 6.0 + 6.0 * 60.0 / 140.0)), accuracy: 2)

        let at30 = c.bySeconds(nowTicks: ticks(afterAnchor: 30), ticksPerSecond: tps)
        XCTAssertEqual(inSong(at30.place)?.section, 1)
        XCTAssertEqual(inSong(at30.place)?.beat ?? -1, 2.4, accuracy: 1e-6)
        XCTAssertEqual(at30.beatsFromAnchor, 50.4, accuracy: 1e-6)

        let at35 = c.bySeconds(nowTicks: ticks(afterAnchor: 35), ticksPerSecond: tps)
        XCTAssertEqual(inSong(at35.place)?.section, 2)
        XCTAssertEqual(inSong(at35.place)?.beat ?? -1, 0.2 * 140.0 / 60.0, accuracy: 1e-6)

        let at40 = c.bySeconds(nowTicks: ticks(afterAnchor: 40), ticksPerSecond: tps)
        XCTAssertEqual(pastEnd(at40.place) ?? -1, (40.0 - (28.8 + 6.0 + 6.0 * 60.0 / 140.0)) * 140.0 / 60.0, accuracy: 1e-6)

        // Coi battiti di Link che seguono la canzone i due righelli coincidono.
        let reading = c.read(nowLinkBeat: 50.4, nowTicks: ticks(afterAnchor: 30), ticksPerSecond: tps)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 1, bar: 1, beat: 3,
                               nextDownbeat: ShowClockDownbeat(section: 1, bar: 2, beatInSection: 4, linkBeat: 52)))
    }

    // MARK: - Zero, negativi, enormi

    func testZero() {
        let c = clock(songA, section: 0, beat: 8, linkBeat: 500)
        let reading = c.read(nowLinkBeat: 500, nowTicks: anchorTicks, ticksPerSecond: tps)
        XCTAssertEqual(reading.byLinkBeats.place, .inSong(section: 0, beatInSection: 8))
        XCTAssertEqual(reading.bySeconds.place, .inSong(section: 0, beatInSection: 8))
        XCTAssertEqual(reading.gapBeats, 0)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 0, bar: 3, beat: 1,
                               nextDownbeat: ShowClockDownbeat(section: 0, bar: 4, beatInSection: 12, linkBeat: 504)))
    }

    func testNegatives() {
        let c = clock(songA, section: 0, beat: 5, linkBeat: 500)
        // Due battiti prima dell'àncora (1,2 s a 100): battito 3 dell'Intro = battuta 1, battito 4.
        let back = c.read(nowLinkBeat: 498, nowTicks: ticks(afterAnchor: -1.2), ticksPerSecond: tps)
        XCTAssertEqual(inSong(back.bySeconds.place)?.beat ?? -1, 3, accuracy: 1e-6)
        XCTAssertTrue(back.certain)
        XCTAssertEqual(back.outcome,
                       .inSong(section: 0, bar: 1, beat: 4,
                               nextDownbeat: ShowClockDownbeat(section: 0, bar: 2, beatInSection: 4, linkBeat: 499)))
        // Prima dell'inizio della sezione dell'àncora: non si sa.
        let tooFar = c.read(nowLinkBeat: 490, nowTicks: ticks(afterAnchor: -6.0), ticksPerSecond: tps)
        XCTAssertEqual(tooFar.byLinkBeats.place, .unknown(.beforeAnchorSection))
        XCTAssertEqual(tooFar.bySeconds.place, .unknown(.beforeAnchorSection))
        XCTAssertFalse(tooFar.certain)
        XCTAssertEqual(tooFar.outcome, .unknown(.beforeAnchorSection))
        // Àncore fuori dalla mappa.
        XCTAssertEqual(clock(songA, section: 0, beat: -1, linkBeat: 0).invalidity, .invalidAnchor)
        XCTAssertEqual(clock(songA, section: 0, beat: 48, linkBeat: 0).invalidity, .invalidAnchor)
        XCTAssertEqual(clock(songA, section: -1, beat: 0, linkBeat: 0).invalidity, .invalidAnchor)
        XCTAssertEqual(clock(songA, section: 3, beat: 0, linkBeat: 0).invalidity, .invalidAnchor)
        XCTAssertEqual(clock(songA, section: -1, beat: 0, linkBeat: 0)
                        .read(nowLinkBeat: 1, nowTicks: anchorTicks, ticksPerSecond: tps).outcome,
                       .unknown(.invalidAnchor))
        // Mappe non valide: vuota, zero battiti per battuta, tempo zero, negativo o non finito.
        XCTAssertEqual(clock(SongMap(sections: []), section: 0, beat: 0, linkBeat: 0).invalidity, .invalidMap)
        let zeroMeter = SongMap(sections: [SongMapSection(beatsPerBar: 0, repetitions: 4, bpm: 100)])
        XCTAssertEqual(clock(zeroMeter, section: 0, beat: 0, linkBeat: 0).invalidity, .invalidMap)
        for bpm in [0.0, -120.0, Double.nan, Double.infinity] {
            let badTempo = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 4, bpm: bpm)])
            XCTAssertEqual(clock(badTempo, section: 0, beat: 0, linkBeat: 0).invalidity, .invalidMap, "bpm:\(bpm)")
        }
        // Un ciclo può avere qualunque tempo: la mappa resta valida.
        let cycleAnyTempo = SongMap(sections: [
            SongMapSection(beatsPerBar: 4, repetitions: 1, bpm: 100),
            SongMapSection(beatsPerBar: 4, repetitions: 0, bpm: 0),
        ])
        XCTAssertTrue(cycleAnyTempo.isValid)
    }

    func testHugeAndNotFinite() {
        let c = clock(songA, section: 0, beat: 8, linkBeat: 500)
        // Un battito di Link enorme: oltre la fine, canzone finita, nessun traboccamento.
        let huge = c.read(nowLinkBeat: 500 + 1e12, nowTicks: UInt64.max, ticksPerSecond: tps)
        XCTAssertNotNil(pastEnd(huge.byLinkBeats.place))
        XCTAssertNotNil(pastEnd(huge.bySeconds.place))
        if case .songEnded(let endBeat, _) = huge.outcome {
            XCTAssertEqual(endBeat, 500 + 58)
        } else {
            XCTFail("atteso songEnded, avuto \(huge.outcome)")
        }
        // Ripetizioni che traboccano: mappa non valida.
        let overflow = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: Int.max, bpm: 100)])
        XCTAssertNil(overflow.sections[0].totalBeats)
        XCTAssertFalse(overflow.isValid)
        // Il tetto dei battiti di sezione: 2^40 sì, uno di più no.
        XCTAssertTrue(SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 1 << 38, bpm: 100)]).isValid)
        XCTAssertFalse(SongMap(sections: [SongMapSection(beatsPerBar: 1, repetitions: (1 << 40) + 1, bpm: 100)]).isValid)
        // Battuta e battito di un valore non finito, enorme o negativo: nessuna conversione fuori
        // intervallo (l'Intro ha 48 battiti: l'ultimo è battuta 12, battito 4).
        XCTAssertEqual(c.barAndBeat(section: 0, beatInSection: .nan).bar, 0)
        XCTAssertEqual(c.barAndBeat(section: 0, beatInSection: 1e300).bar, 12)
        XCTAssertEqual(c.barAndBeat(section: 0, beatInSection: 1e300).beat, 4)
        XCTAssertEqual(c.barAndBeat(section: 0, beatInSection: -5).bar, 1)
        XCTAssertEqual(c.barAndBeat(section: 0, beatInSection: -5).beat, 1)
        XCTAssertEqual(c.barAndBeat(section: 7, beatInSection: 1).bar, 0)
        // Valori non finiti.
        XCTAssertEqual(c.byLinkBeats(nowLinkBeat: .nan).place, .unknown(.invalidInput))
        XCTAssertEqual(c.byLinkBeats(nowLinkBeat: .infinity).place, .unknown(.invalidInput))
        XCTAssertEqual(clock(songA, section: 0, beat: 0, linkBeat: .nan).invalidity, .invalidInput)
        // Tick al secondo non validi: il righello dei secondi non dà un posto, il conto non è certo,
        // l'esito resta quello dei battiti di Link.
        for badTps in [0.0, -1.0, Double.nan, Double.infinity] {
            let reading = c.read(nowLinkBeat: 504, nowTicks: anchorTicks, ticksPerSecond: badTps)
            XCTAssertEqual(reading.bySeconds.place, .unknown(.invalidInput), "tps:\(badTps)")
            XCTAssertNil(reading.gapBeats)
            XCTAssertFalse(reading.certain)
            XCTAssertNil(c.endTicks(ticksPerSecond: badTps))
        }
        // L'ora della fine si ferma ai bordi di UInt64.
        let late = ShowClock(map: songA, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 0,
                                                                 ticks: UInt64.max - 10))
        XCTAssertEqual(late.endTicks(ticksPerSecond: tps), UInt64.max)
        XCTAssertEqual(ShowClock.ticks(UInt64.max - 10, plusSeconds: 1, ticksPerSecond: tps), UInt64.max)
        XCTAssertEqual(ShowClock.ticks(5, plusSeconds: -1, ticksPerSecond: tps), 0)
        XCTAssertEqual(ShowClock.ticks(5, plusSeconds: .infinity, ticksPerSecond: tps), UInt64.max)
        XCTAssertEqual(ShowClock.ticks(5, plusSeconds: -.infinity, ticksPerSecond: tps), 0)
        XCTAssertEqual(ShowClock.ticks(5, plusSeconds: .nan, ticksPerSecond: tps), 0)
        XCTAssertEqual(ShowClock.ticks(second, plusSeconds: 1, ticksPerSecond: tps), 2 * second)
    }

    // MARK: - Il prossimo inizio di battuta

    func testNextDownbeat() {
        let c = clock(songA, section: 0, beat: 8, linkBeat: 500)
        // Esattamente su un «uno»: quello.
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 508),
                       .found(ShowClockDownbeat(section: 0, bar: 5, beatInSection: 16, linkBeat: 508)))
        // Appena dopo: il successivo.
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 508.0001),
                       .found(ShowClockDownbeat(section: 0, bar: 6, beatInSection: 20, linkBeat: 512)))
        // Nel Verse: battito 5 → la battuta 3 (battito 8) = Link 500 + 40 + 8.
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 545),
                       .found(ShowClockDownbeat(section: 1, bar: 3, beatInSection: 8, linkBeat: 548)))
        // Nell'ultima battuta del Verse: l'«uno» è l'inizio del Bridge = Link 500 + 40 + 12.
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 551),
                       .found(ShowClockDownbeat(section: 2, bar: 1, beatInSection: 0, linkBeat: 552)))
        // Nell'ultima battuta della canzone: la canzone finisce prima.
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 556), .songEndsFirst)
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 600), .songEndsFirst)
        // L'ultimo battito di una sezione come àncora: il prossimo «uno» è l'inizio della sezione dopo.
        let last = clock(songA, section: 0, beat: 47, linkBeat: 2000)
        XCTAssertEqual(last.read(nowLinkBeat: 2000.5, nowTicks: ticks(afterAnchor: 0.3), ticksPerSecond: tps).outcome,
                       .inSong(section: 0, bar: 12, beat: 4,
                               nextDownbeat: ShowClockDownbeat(section: 1, bar: 1, beatInSection: 0, linkBeat: 2001)))
    }

    /// «3/4 Long»: il 3/4 comincia al battito 32 della canzone, e 32 mod 3 = 2 (il caso del
    /// 21/09). Le sue battute cadono sui battiti di Link ≡ 2 mod 3 se l'àncora è sullo 0: il conto
    /// le trova dalla struttura, non dalla fase di Link.
    func testThreeFourLongDownbeats() {
        let c = clock(threeFourLong, section: 0, beat: 0, linkBeat: 0)
        XCTAssertEqual(c.downbeat(atOrAfterLinkBeat: 32),
                       .found(ShowClockDownbeat(section: 1, bar: 1, beatInSection: 0, linkBeat: 32)))
        let search = c.downbeat(atOrAfterLinkBeat: 33.5)
        XCTAssertEqual(search, .found(ShowClockDownbeat(section: 1, bar: 2, beatInSection: 3, linkBeat: 35)))
        if case .found(let d) = search {
            XCTAssertEqual(Int(d.linkBeat) % 3, 2)
        }
        // Dentro il 3/4: battuta 6, battito 2 = battito 16 del 3/4.
        let reading = c.read(nowLinkBeat: 48, nowTicks: ticks(afterAnchor: 48 * 0.6), ticksPerSecond: tps)
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 1, bar: 6, beat: 2,
                               nextDownbeat: ShowClockDownbeat(section: 1, bar: 7, beatInSection: 18, linkBeat: 50)))
    }

    // MARK: - Il disaccordo dei righelli

    /// Link dice 20 battiti dopo l'àncora (inizio del Bridge), l'orologio 10 s: 8 battiti per finire
    /// l'Intro (4,8 s) e 5,2 s × 2 = 10,4 nel Verse, 18,4 in tutto. Scarto 1,6: non certo.
    func testRulersDisagree() {
        let c = clock(songA, section: 0, beat: 40, linkBeat: 1000)
        let reading = c.read(nowLinkBeat: 1020, nowTicks: ticks(afterAnchor: 10), ticksPerSecond: tps)
        XCTAssertEqual(reading.bySeconds.beatsFromAnchor, 18.4, accuracy: 1e-6)
        XCTAssertEqual(reading.gapBeats ?? 0, 1.6, accuracy: 1e-6)
        XCTAssertFalse(reading.certain)
        XCTAssertEqual(reading.outcome,
                       .inSong(section: 2, bar: 1, beat: 1,
                               nextDownbeat: ShowClockDownbeat(section: 2, bar: 2, beatInSection: 3, linkBeat: 1023)))
    }

    /// La tolleranza è un ottavo di battito, compreso; un millesimo in più non è certo, nei due versi.
    func testToleranceIsAnEighthOfABeat() {
        let c = clock(songA, section: 0, beat: 8, linkBeat: 500)
        let now = ticks(afterAnchor: 6.0)   // 10 battiti a 100
        XCTAssertEqual(c.read(nowLinkBeat: 510.1, nowTicks: now, ticksPerSecond: tps).certain, true)
        XCTAssertEqual(c.read(nowLinkBeat: 510.125, nowTicks: now, ticksPerSecond: tps).certain, true)
        XCTAssertEqual(c.read(nowLinkBeat: 510.126, nowTicks: now, ticksPerSecond: tps).certain, false)
        XCTAssertEqual(c.read(nowLinkBeat: 509.875, nowTicks: now, ticksPerSecond: tps).certain, true)
        XCTAssertEqual(c.read(nowLinkBeat: 509.874, nowTicks: now, ticksPerSecond: tps).certain, false)
        XCTAssertEqual(ShowClock.defaultToleranceBeats, 0.125)
        let wide = ShowClock(map: songA,
                             anchor: ShowClockAnchor(section: 0, beatInSection: 8, linkBeat: 500, ticks: anchorTicks),
                             toleranceBeats: 0.5)
        XCTAssertTrue(wide.read(nowLinkBeat: 510.4, nowTicks: now, ticksPerSecond: tps).certain)
    }

    // MARK: - La mappa dalle sezioni di Q-Stage

    func testSongMapFromSongSections() {
        let sections = [
            SongSection(name: "Intro 100", bpm: 100, beatsPerBar: 4, beatUnit: 4, repetitions: 12,
                        notes: "", accentPattern: [2, 1, 1, 1], subdivisionMultiplier: 1, swingRatio: 0.5),
            SongSection(name: "Loop", bpm: 90, beatsPerBar: 3, beatUnit: 4, repetitions: -1,
                        notes: "", accentPattern: [2, 1, 1], subdivisionMultiplier: 1, swingRatio: 0.5),
        ]
        let map = SongMap(songSections: sections)
        XCTAssertEqual(map, SongMap(sections: [
            SongMapSection(beatsPerBar: 4, repetitions: 12, bpm: 100),
            SongMapSection(beatsPerBar: 3, repetitions: -1, bpm: 90),
        ]))
        XCTAssertEqual(map.sections[0].totalBeats, 48)
        XCTAssertTrue(map.sections[1].isCycle)
        XCTAssertEqual(map.sections[1].totalBeats, 0)
    }

    /// Il conto non legge niente del Direttore: è lo stesso per chiunque gli dia una mappa e
    /// un'àncora (scelta T13). Due orologi con gli stessi ingressi danno la stessa lettura.
    func testSameInputsSameReading() {
        let one = clock(songA, section: 1, beat: 2, linkBeat: 77)
        let other = clock(songA, section: 1, beat: 2, linkBeat: 77)
        XCTAssertEqual(one, other)
        XCTAssertEqual(one.read(nowLinkBeat: 80, nowTicks: ticks(afterAnchor: 1.5), ticksPerSecond: tps),
                       other.read(nowLinkBeat: 80, nowTicks: ticks(afterAnchor: 1.5), ticksPerSecond: tps))
    }
}
