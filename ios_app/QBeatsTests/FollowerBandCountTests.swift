import XCTest

// === A432, parte 2a — banco del conto del Follower sulla band (`FollowerBandCount`, banco Models) ===
// Seguito «PARTE 2a» del mandato A432, par. 2.2: il seme (3,847 a 141 e 3,983 a 121 ⇒ 4; mezza battuta in 2/4 ⇒
// nessun conto; 6/8; una prima sezione più corta del seme), la lettura, il posto della band coi salti misurati,
// il riferimento fisso col suo controllo negativo, le tre rimappature del 01/11 con J = −delta, la deriva degli
// orologi, A.2 coi casi 1-5 del referto A431 par. 2.5, i numeri del 29/10 e del 01/11 che il tipo puro sa
// calcolare, A.9 e A.12 scritti come limiti, la ripartenza dell'iPad a metà sezione, le righe 2, 5 e 18 della
// tabella delle cause di A431 par. 2.4 e, il limite delle due sezioni corte di seguito.
// 24.000.000 tick al secondo, come `ShowClockTests`. Gli attesi sono scritti per esteso, dai numeri dei casi.
// Gli stessi casi, con gli stessi numeri, girano sul modello Python delle regole (fuori dal deposito), dove ogni
// test cade se si toglie la riga della regola che prova: il controllo negativo del riferimento fisso («124 contro
// 120» col riferimento che segue le letture resta certo, e il test cade) è una rottura di quel modello.
// Mai `!` sugli optional: i test lanciano (`XCTUnwrap`).

final class FollowerBandCountTests: XCTestCase {

    private struct NotTheExpectedCase: Error {}

    private let tps = 24_000_000.0
    /// L'ora dell'àncora (o dell'ingresso) dei casi di lettura: 100 s.
    private let t0: UInt64 = 100 * 24_000_000
    /// L'ora del richiamo del Play nei casi del seme: 50 s.
    private let play: UInt64 = 50 * 24_000_000

    private func ticks(_ base: UInt64, _ seconds: Double) -> UInt64 {
        base + UInt64((seconds * tps).rounded())
    }

    private func song(_ sections: [(Int, Int, Double)]) -> SongMap {
        SongMap(sections: sections.map { SongMapSection(beatsPerBar: $0.0, repetitions: $0.1, bpm: $0.2) })
    }

    private func count(_ map: SongMap, section: Int = 0, beat: Int = 0, link: Double = 1000.0) -> FollowerBandCount {
        FollowerBandCount(map: map, anchor: ShowClockAnchor(section: section, beatInSection: beat,
                                                            linkBeat: link, ticks: t0))
    }

    /// Una lettura: il battito della sessione e i secondi dall'àncora dell'ora del battito in attesa; `last` è
    /// l'ultimo battito contato dall'iPad (sezione, battito, secondi dall'àncora).
    private func read(_ c: inout FollowerBandCount, _ link: Double, _ seconds: Double,
                      last: (Int, Int, Double)? = nil) -> FollowerBandReading {
        var counted: FollowerCountedBeat? = nil
        if let l = last {
            counted = FollowerCountedBeat(section: l.0, beatInSection: l.1, ticks: ticks(t0, l.2))
        }
        return c.read(pendingLinkBeat: link, pendingTicks: ticks(t0, seconds), ticksPerSecond: tps,
                      lastCounted: counted)
    }

    private func enter(_ current: FollowerBandCount?, _ map: SongMap, entry: UInt64, link: Double,
                       playTicks: UInt64? = nil, ticksPerSecond: Double? = nil) -> FollowerBandEntry {
        FollowerBandCount.enter(current: current,
                                seed: FollowerBandSeedInput(map: map, playCallbackTicks: playTicks ?? play,
                                                            entryTicks: entry, entryLinkBeat: link,
                                                            ticksPerSecond: ticksPerSecond ?? tps))
    }

    private func anchored(_ entry: FollowerBandEntry, file: StaticString = #filePath,
                          line: UInt = #line) throws -> (FollowerBandCount, FollowerBandSeed) {
        guard case .anchored(let c, let s) = entry else {
            XCTFail("atteso un seme preso, è \(entry)", file: file, line: line)
            throw NotTheExpectedCase()
        }
        return (c, s)
    }

    private func noCount(_ entry: FollowerBandEntry, file: StaticString = #filePath,
                         line: UInt = #line) throws -> FollowerBandCount {
        guard case .noCount(let c) = entry else {
            XCTFail("atteso nessun conto, è \(entry)", file: file, line: line)
            throw NotTheExpectedCase()
        }
        return c
    }

    private func kept(_ entry: FollowerBandEntry, file: StaticString = #filePath,
                      line: UInt = #line) throws -> FollowerBandCount {
        guard case .kept(let c) = entry else {
            XCTFail("attesa l'àncora tenuta, è \(entry)", file: file, line: line)
            throw NotTheExpectedCase()
        }
        return c
    }

    private func inSong(_ section: Int, _ beat: Int, _ inBar: Int) -> FollowerBandPlace? {
        FollowerBandPlace.inSong(section: section, beatInSection: beat, beatInBar: inBar)
    }

    private func assertCertain(_ r: FollowerBandReading, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(r.certain, "non certo: \(String(describing: r.reason))", file: file, line: line)
        XCTAssertNil(r.reason, file: file, line: line)
    }

    private func assertUncertain(_ r: FollowerBandReading, _ reason: FollowerBandCountClosed,
                                 file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(r.certain, file: file, line: line)
        XCTAssertEqual(r.reason, reason, file: file, line: line)
        XCTAssertNil(r.place, file: file, line: line)
    }

    private func gap(_ r: FollowerBandReading, file: StaticString = #filePath, line: UInt = #line) throws -> Double {
        try XCTUnwrap(r.gapBeats, file: file, line: line)
    }

    // MARK: - Il seme

    /// 3,847 battiti a 141 e 3,983 a 121 dal richiamo del Play all'ingresso (29/10 sera): il seme è 4, la seconda
    /// battuta; il ritardo del richiamo è 0,153 e 0,017 battiti.
    func testTheSeedOfTheEveningOfThe29thOfOctober() throws {
        for (bpm, measured, delay) in [(141.0, 3.847, 0.153), (121.0, 3.983, 0.017)] {
            let map = song([(4, 16, bpm)])
            let entry = ticks(play, measured * 60.0 / bpm)
            let (c, s) = try anchored(enter(nil, map, entry: entry, link: 812.25))
            XCTAssertEqual(s.section, 0)
            XCTAssertEqual(s.beatInSection, 4)
            XCTAssertEqual(s.songBeat, 4)
            XCTAssertEqual(s.measuredBeats, measured, accuracy: 1e-6)
            XCTAssertEqual(s.callbackDelayBeats, delay, accuracy: 1e-6)
            XCTAssertEqual(c.anchor, ShowClockAnchor(section: 0, beatInSection: 4, linkBeat: 812.25, ticks: entry))
            XCTAssertNil(c.closed)
            XCTAssertEqual(c.renumbering, .closed)
        }
    }

    /// 2/4 a 120: 5 battiti (2,5 s) dal richiamo, un battito intero dalle battute 4 e 6; il quarto di battuta è
    /// mezzo battito. Nessun conto, e per tutta la canzone (P33).
    func testHalfABarInTwoFourGivesNoCountForTheWholeSong() throws {
        let map = song([(2, 16, 120.0)])
        var c = try noCount(enter(nil, map, entry: ticks(play, 2.5), link: 300.0))
        XCTAssertEqual(c.closed, FollowerBandCountClosed.seedOffBar)
        XCTAssertNil(c.anchor)
        let r = c.read(pendingLinkBeat: 310.0, pendingTicks: ticks(play, 7.5), ticksPerSecond: tps, lastCounted: nil)
        assertUncertain(r, .seedOffBar)
        XCTAssertTrue(r.closedBefore)
        // un secondo ingresso nella stessa canzone, questa volta su una battuta: resta senza conto
        let again = try noCount(enter(c, map, entry: ticks(play, 4.0), link: 303.0))
        XCTAssertEqual(again.closed, FollowerBandCountClosed.seedOffBar)
    }

    func testTheQuarterOfABarIsIncluded() throws {
        let map = song([(4, 16, 120.0)])
        // 5,0 battiti: un battito (un quarto di battuta) dopo la battuta 4: certo, col ritardo negativo
        var s = try anchored(enter(nil, map, entry: ticks(play, 2.5), link: 300.0)).1
        XCTAssertEqual(s.songBeat, 4)
        XCTAssertEqual(s.callbackDelayBeats, -1.0, accuracy: 1e-9)
        // 5,04 battiti: oltre il quarto da tutte e due le battute
        _ = try noCount(enter(nil, map, entry: ticks(play, 2.52), link: 300.0))
        // 7,0 battiti: un battito prima della battuta 8
        s = try anchored(enter(nil, map, entry: ticks(play, 3.5), link: 300.0)).1
        XCTAssertEqual(s.songBeat, 8)
        XCTAssertEqual(s.callbackDelayBeats, 1.0, accuracy: 1e-9)
        _ = try noCount(enter(nil, map, entry: ticks(play, 3.48), link: 300.0))
    }

    /// 6/8 a 101: il quarto di battuta è un battito e mezzo.
    func testTheSeedInSixEight() throws {
        let map = song([(6, 8, 101.0)])
        let s = try anchored(enter(nil, map, entry: ticks(play, 10.6 * 60.0 / 101.0), link: 300.0)).1
        XCTAssertEqual(s.section, 0)
        XCTAssertEqual(s.beatInSection, 12)
        XCTAssertEqual(s.songBeat, 12)
        XCTAssertEqual(s.callbackDelayBeats, 1.4, accuracy: 1e-6)
        let c = try noCount(enter(nil, map, entry: ticks(play, 10.4 * 60.0 / 101.0), link: 300.0))
        XCTAssertEqual(c.closed, FollowerBandCountClosed.seedOffBar)
    }

    /// Una battuta di 4/4 a 120 (2 s), poi 3/4 a 90: 3,95 s dal richiamo sono 4 battiti più 2,925 nella seconda
    /// sezione. Il seme cammina la mappa: sezione 1, battito 3.
    func testAFirstSectionShorterThanTheSeed() throws {
        let map = song([(4, 1, 120.0), (3, 8, 90.0)])
        var (c, s) = try anchored(enter(nil, map, entry: ticks(play, 3.95), link: 300.0))
        XCTAssertEqual(s.section, 1)
        XCTAssertEqual(s.beatInSection, 3)
        XCTAssertEqual(s.songBeat, 7)
        XCTAssertEqual(s.measuredBeats, 6.925, accuracy: 1e-6)
        XCTAssertEqual(s.callbackDelayBeats, 0.075, accuracy: 1e-6)
        XCTAssertEqual(try XCTUnwrap(c.anchor).section, 1)
        XCTAssertEqual(try XCTUnwrap(c.anchor).beatInSection, 3)
        XCTAssertEqual(c.bandSection, 1)
        // 1,9 s: 3,8 battiti, la battuta più vicina è l'inizio della seconda sezione
        (c, s) = try anchored(enter(nil, map, entry: ticks(play, 1.9), link: 300.0))
        XCTAssertEqual(s.section, 1)
        XCTAssertEqual(s.beatInSection, 0)
        XCTAssertEqual(s.songBeat, 4)
        XCTAssertEqual(s.callbackDelayBeats, 0.2, accuracy: 1e-6)
    }

    /// A.12 (il limite scritto): la band è al battito 4, ma il richiamo del Play è arrivato 3,2 battiti (0,8
    /// battute) in ritardo: all'ingresso ne risultano 0,8, entro un quarto dalla battuta 0. Il seme è 0: una
    /// battuta indietro, e il tipo non può accorgersene.
    func testThePlayCallbackEightTenthsOfABarLateIsTheWrittenLimit() throws {
        let map = song([(4, 16, 120.0)])
        let s = try anchored(enter(nil, map, entry: ticks(play, 0.4), link: 300.0)).1
        XCTAssertEqual(s.songBeat, 0)
        XCTAssertEqual(s.callbackDelayBeats, -0.8, accuracy: 1e-6)
    }

    func testTheSeedEdges() throws {
        let empty = SongMap(sections: [])
        XCTAssertEqual(try noCount(enter(nil, empty, entry: ticks(play, 2.0), link: 300.0)).closed,
                       FollowerBandCountClosed.seedInvalidInput)                       // niente mappa
        let map = song([(4, 2, 120.0)])
        XCTAssertEqual(try noCount(enter(nil, map, entry: play - 1, link: 300.0)).closed,
                       FollowerBandCountClosed.seedInvalidInput)                       // l'ingresso prima del richiamo
        XCTAssertEqual(try noCount(enter(nil, map, entry: ticks(play, 2.0), link: Double.nan)).closed,
                       FollowerBandCountClosed.seedInvalidInput)
        XCTAssertEqual(try noCount(enter(nil, map, entry: ticks(play, 2.0), link: 300.0, ticksPerSecond: 0.0)).closed,
                       FollowerBandCountClosed.seedInvalidInput)
        XCTAssertEqual(try noCount(enter(nil, map, entry: ticks(play, 5.0), link: 300.0)).closed,
                       FollowerBandCountClosed.seedPastEnd)                            // oltre la fine (8 battiti, 4 s)
        XCTAssertEqual(try noCount(enter(nil, map, entry: ticks(play, 3.9), link: 300.0)).closed,
                       FollowerBandCountClosed.seedPastEnd)                            // la battuta più vicina è la fine
        XCTAssertEqual(try noCount(enter(nil, song([(4, 0, 120.0)]), entry: ticks(play, 2.0), link: 300.0)).closed,
                       FollowerBandCountClosed.seedCycle)                              // la prima sezione è un ciclo
        XCTAssertEqual(try noCount(enter(nil, song([(4, 1, 120.0), (4, 0, 120.0)]), entry: ticks(play, 1.9),
                                         link: 300.0)).closed,
                       FollowerBandCountClosed.seedCycle)
        var c = try noCount(enter(nil, empty, entry: ticks(play, 2.0), link: 300.0))
        let r = c.read(pendingLinkBeat: 310.0, pendingTicks: ticks(play, 3.0), ticksPerSecond: tps, lastCounted: nil)
        assertUncertain(r, .seedInvalidInput)
    }

    /// La ripartenza dell'iPad a metà sezione (A431 par. 2.2, banco 5): l'àncora e il riferimento restano; la
    /// lettura dopo dà lo stesso scarto di prima, nessun salto.
    func testAnEntryWithALiveAnchorKeepsIt() throws {
        let map = song([(4, 16, 121.0)])
        let entry = ticks(play, 3.983 * 60.0 / 121.0)
        var c = try anchored(enter(nil, map, entry: entry, link: 812.25)).0
        var r = c.read(pendingLinkBeat: 812.25 + 10.0, pendingTicks: ticks(entry, 10.0 * 60.0 / 121.0),
                       ticksPerSecond: tps, lastCounted: nil)
        assertCertain(r)
        XCTAssertEqual(r.place, inSong(0, 14, 2))
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        let before = c.anchor
        var after = try kept(enter(c, map, entry: ticks(entry, 6.0), link: 999.0))   // l'iPad riparte sei secondi dopo
        XCTAssertEqual(after.anchor, before)
        r = after.read(pendingLinkBeat: 812.25 + 26.0, pendingTicks: ticks(entry, 26.0 * 60.0 / 121.0),
                       ticksPerSecond: tps, lastCounted: nil)
        assertCertain(r)
        XCTAssertEqual(r.place, inSong(0, 30, 2))
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertNil(r.recognized)
    }

    /// Riga 2 della tabella delle cause: la rinumerazione dell'assert d'avvio (qui +1,9172) cade prima
    /// dell'àncora, che prende il battito della sessione già rinumerato: dopo, nessun gradino.
    func testAnAnchorTakenAfterTheStartAssertSeesNoStep() throws {
        let map = song([(4, 16, 121.0)])
        let entry = ticks(play, 4.0 * 60.0 / 121.0)
        var c = try anchored(enter(nil, map, entry: entry, link: 300.0 + 1.9172)).0
        var last = FollowerBandReading(certain: false, reason: nil, place: nil, gapBeats: nil, recognized: nil,
                                       closedBefore: false)
        for beats in [1.0, 9.0, 40.0] {
            last = c.read(pendingLinkBeat: 301.9172 + beats, pendingTicks: ticks(entry, beats * 60.0 / 121.0),
                          ticksPerSecond: tps, lastCounted: nil)
            assertCertain(last)
            XCTAssertEqual(try gap(last), 0.0, accuracy: 1e-6)
            XCTAssertNil(last.recognized)
        }
        XCTAssertEqual(last.place, inSong(0, 44, 0))
    }

    // MARK: - La lettura e il posto della band

    func testTheBandPlaceForThePendingBeat() throws {
        var c = count(song([(4, 16, 121.0)]), beat: 4, link: 1000.0)
        let r = read(&c, 1010.0, 10.0 * 60.0 / 121.0)
        assertCertain(r)
        XCTAssertEqual(r.place, inSong(0, 14, 2))
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertFalse(r.closedBefore)
        XCTAssertEqual(c.renumbering, .closed)
    }

    /// I salti misurati: dopo un buco di G battiti il DSP mette in attesa il battito p + round(G) (FIX-B); il
    /// conto dice il posto della band per l'ora di quel battito: +2, +1, +2, +1 rispetto al contatore del motore.
    func testTheBandPlaceWithTheMeasuredHoles() throws {
        for (bpm, bpb, gapBeats, delta) in [(121.0, 4, 1.61, 2), (91.0, 4, 1.19, 1), (141.0, 4, 1.86, 2),
                                            (101.0, 6, 1.30, 1)] {
            XCTAssertEqual(Int(gapBeats.rounded()), delta)
            let p = 20
            for noise in [-0.006, 0.006] {       // lo scarto della lettura di Link
                var c = count(song([(bpb, 16, bpm)]), link: 500.0)
                var r = read(&c, 500.0 + Double(p), Double(p) * 60.0 / bpm)
                assertCertain(r)
                XCTAssertEqual(r.place, inSong(0, p, p % bpb))
                let k = p + delta
                r = read(&c, 500.0 + Double(k) + noise, Double(k) * 60.0 / bpm)
                assertCertain(r)
                XCTAssertEqual(r.place, inSong(0, k, k % bpb))
                XCTAssertEqual(try gap(r), noise, accuracy: 1e-6)
            }
        }
        // i 23 buchi del 29/10, da 752,0 a 809,8 ms: due battiti a 121 e 141, uno a 91 e 101
        for (bpm, delta) in [(121.0, 2), (141.0, 2), (91.0, 1), (101.0, 1)] {
            for ms in [752.0, 809.8] {
                XCTAssertEqual(Int((ms / 1000.0 * bpm / 60.0).rounded()), delta)
            }
        }
    }

    /// 29/10, la canzone a due sezioni: il motore, indietro di 8 battiti, è ancora nella prima sezione; per l'ora
    /// del battito in attesa la band è al primo battito della seconda.
    func testTheBoundaryFrom121To91WithTheMotorEightBeatsBehind() throws {
        var c = count(song([(4, 8, 121.0), (4, 8, 91.0)]), link: 300.0)
        var r = read(&c, 332.0, 32.0 * 60.0 / 121.0)
        assertCertain(r)
        XCTAssertEqual(r.place, inSong(1, 0, 0))
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        r = read(&c, 343.0, 32.0 * 60.0 / 121.0 + 11.0 * 60.0 / 91.0)
        assertCertain(r)
        XCTAssertEqual(r.place, inSong(1, 11, 3))
    }

    func testTheEndOfTheSongIsAPlaceNotAnUncertainty() {
        var c = count(song([(4, 2, 120.0)]), link: 100.0)          // 8 battiti, 4 s
        let r = read(&c, 110.0, 5.0)
        assertCertain(r)
        XCTAssertEqual(r.place, FollowerBandPlace.pastEnd(beats: 2))
    }

    func testAReadWithoutAPlaceClosesTheCount() {
        var c = count(song([(4, 16, 120.0)]), link: 100.0)
        assertUncertain(read(&c, Double.infinity, 2.0), .noPlace(.invalidInput))
        XCTAssertEqual(c.closed, FollowerBandCountClosed.noPlace(.invalidInput))
        c = count(song([(4, 2, 120.0), (4, 0, 120.0)]), link: 100.0)      // un ciclo dopo la prima sezione
        assertCertain(read(&c, 104.0, 2.0))
        assertUncertain(read(&c, 109.0, 4.5), .noPlace(.cycle))
        c = count(song([(4, 4, 120.0), (4, 4, 120.0)]), section: 1, beat: 0, link: 100.0)
        // un secondo prima dell'àncora, fuori dalla sua sezione
        let r = c.read(pendingLinkBeat: 98.0, pendingTicks: t0 - 24_000_000, ticksPerSecond: tps, lastCounted: nil)
        assertUncertain(r, .noPlace(.beforeAnchorSection))
    }

    // MARK: - Il riferimento fisso

    /// «Certo fino a 1/8 compreso», la regola di `ShowClock`.
    func testOneEighthExactlyIsStillCertain() {
        var c = count(song([(4, 16, 120.0)]), link: 1000.0)
        var r = read(&c, 1008.125, 4.0)
        assertCertain(r)
        XCTAssertEqual(r.gapBeats, 0.125)
        XCTAssertEqual(r.place, inSong(0, 8, 0))
        r = read(&c, 1008.125 + 1.0 / 1024.0, 4.0)
        assertUncertain(r, .jumpOutsideRenumbering)
        let justOver: Double = 0.125 + 1.0 / 1024.0
        XCTAssertEqual(r.gapBeats, justOver)
    }

    /// La strofa uguale (8 battute a 120, 16 s), poi la band a 124 e la mappa dell'iPad a 120: lo scarto
    /// dall'àncora cresce di 4/60 di battito al secondo e passa 1/8 dopo 1,875 s. Con una lettura al secondo, per
    /// ogni fase, il primo «non certo» cade fra 1,875 e 2,875 s dopo il confine, e non prima. Col riferimento che
    /// segue le letture lo scarto non passerebbe mai 1/8: il conto resterebbe certo e questo test cadrebbe.
    func test124Against120AfterTheVerse() throws {
        for phase in 0..<10 {
            var c = count(song([(4, 8, 120.0), (4, 16, 120.0)]), link: 2000.0)
            var first: Double? = nil
            for n in 0..<6 {
                let tau = Double(phase) / 10.0 + Double(n)
                let r = read(&c, 2000.0 + 32.0 + tau * 124.0 / 60.0, 16.0 + tau)
                if r.certain {
                    XCTAssertLessThanOrEqual(tau, 1.875, "certo a \(tau) s dal confine")
                    XCTAssertEqual(try gap(r), tau * 4.0 / 60.0, accuracy: 1e-6)
                } else {
                    first = tau
                    assertUncertain(r, .jumpOutsideRenumbering)
                    break
                }
            }
            let firstUncertain = try XCTUnwrap(first, "fase \(phase): mai non certo")
            XCTAssertGreaterThan(firstUncertain, 1.875)
            XCTAssertLessThanOrEqual(firstUncertain, 2.875)
        }
    }

    /// 1800 battiti a 180 (dieci minuti). 40 parti per milione: certo per tutta la canzone. 100: lo scarto è 1/8
    /// al battito 1250; certo letto al battito 1240, «non certo» letto al 1260.
    func testTheClockDriftOverALongSong() throws {
        let map = song([(4, 450, 180.0)])
        var c = count(map, link: 5000.0)
        var r = read(&c, 5000.0, 0.0)
        assertCertain(r)
        for n in [600, 1200, 1799] {
            r = read(&c, 5000.0 + Double(n) * (1.0 + 40e-6), Double(n) / 3.0)
            assertCertain(r)
            XCTAssertEqual(try gap(r), Double(n) * 40e-6, accuracy: 1e-6)
        }
        XCTAssertEqual(r.place, inSong(0, 1799, 3))
        c = count(map, link: 5000.0)
        for n in [600, 1200, 1240] {
            r = read(&c, 5000.0 + Double(n) * (1.0 + 100e-6), Double(n) / 3.0)
            assertCertain(r)
            XCTAssertEqual(try gap(r), Double(n) * 100e-6, accuracy: 1e-6)
        }
        r = read(&c, 5000.0 + 1260.0 * (1.0 + 100e-6), 1260.0 / 3.0)
        assertUncertain(r, .jumpOutsideRenumbering)
        XCTAssertEqual(try gap(r), 0.126, accuracy: 1e-6)
    }

    /// Riga 5, la metà certa (numeri scelti qui): un terzo apparecchio porta la sessione a 150 per 50 ms, poi il
    /// Direttore ribatte 120. La sessione guadagna 0,05 × 30 / 60 = 0,025 battiti, che restano (riferimento fisso).
    func testADifferentTempoForOneRoundStaysCertain() throws {
        var c = count(song([(4, 32, 120.0)]), link: 100.0)
        var r = read(&c, 100.0 + 20.0 + 0.025, 10.0)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.025, accuracy: 1e-9)
        XCTAssertEqual(r.place, inSong(0, 20, 0))
        r = read(&c, 100.0 + 100.0 + 0.025, 50.0)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.025, accuracy: 1e-9)
        XCTAssertEqual(r.place, inSong(0, 100, 0))
    }

    /// Riga 18 (M3): nove sezioni 121 / 91 alternate; a ogni cambio la sessione cambia tempo un buffer (512
    /// campioni a 48 kHz) fuori posto, col segno peggiore: 0,010667 × 30 / 60 = 0,005333 battiti a cambio, che si
    /// sommano. Dopo otto cambi 0,0427: sotto 0,043, certo.
    func testEightAlternatingTempoChangesWithOneBufferOfError() throws {
        let bpms: [Double] = (0..<9).map { $0 % 2 == 0 ? 121.0 : 91.0 }
        var c = count(SongMap(sections: bpms.map { SongMapSection(beatsPerBar: 4, repetitions: 4, bpm: $0) }),
                      link: 700.0)
        let e = (512.0 / 48000.0) * 30.0 / 60.0
        var seconds = 0.0
        var lastGap = 0.0
        for k in 1...8 {
            seconds += 16.0 * 60.0 / bpms[k - 1]
            let r = read(&c, 700.0 + 16.0 * Double(k) + 2.0 + Double(k) * e, seconds + 2.0 * 60.0 / bpms[k])
            assertCertain(r)
            lastGap = try gap(r)
            XCTAssertEqual(lastGap, Double(k) * e, accuracy: 1e-6)
            XCTAssertEqual(r.place, inSong(k, 2, 2))
            XCTAssertLessThanOrEqual(abs(lastGap), 0.043)
        }
        XCTAssertEqual(lastGap, 0.0426667, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .closed)
    }

    // MARK: - P21: la rinumerazione attesa fino al secondo confine

    /// La tabella delle transizioni di A431 par. 2.5, le righe dei confini.
    func testTheTransitionsAtTheBoundaries() {
        XCTAssertEqual(FollowerBandCount.afterBoundary(.closed, boundary: 3, meterChanges: true),
                       .open(boundary: 3, boundariesAfter: 0))
        XCTAssertEqual(FollowerBandCount.afterBoundary(.closed, boundary: 3, meterChanges: false), .closed)
        XCTAssertEqual(FollowerBandCount.afterBoundary(.open(boundary: 2, boundariesAfter: 0), boundary: 3,
                                                       meterChanges: false),
                       .open(boundary: 2, boundariesAfter: 1))
        XCTAssertEqual(FollowerBandCount.afterBoundary(.open(boundary: 2, boundariesAfter: 1), boundary: 4,
                                                       meterChanges: false), .closed)
        XCTAssertEqual(FollowerBandCount.afterBoundary(.open(boundary: 2, boundariesAfter: 0), boundary: 3,
                                                       meterChanges: true),
                       .open(boundary: 3, boundariesAfter: 0))
        XCTAssertEqual(FollowerBandCount.afterBoundary(.open(boundary: 2, boundariesAfter: 1), boundary: 4,
                                                       meterChanges: true),
                       .open(boundary: 4, boundariesAfter: 0))
    }

    /// 7/8 a 150 (28 battiti, 11,2 s), 9/8 a 180,5 (36 battiti), 4/4 a 121: i tempi delle sezioni prima del cambio
    /// sono scelti qui; metri, tempi dopo il cambio e salti vengono dalle righe del 01/11.
    private var songA: SongMap { song([(7, 4, 150.0), (9, 4, 180.5), (4, 8, 121.0)]) }
    /// Il confine 7 → 9.
    private let aB1 = 11.2
    /// Il confine 9 → 4.
    private let aB2 = 11.2 + 36.0 * 60.0 / 180.5

    /// Le tre rimappature del 01/11, J = −delta: +4,0188 al 7 → 9 a 180,5; +0,9352 al 9 → 4 a 121; −1,0425
    /// all'11 → 5 a 160,5. Ognuna cade nello stato aperto dalla band, l'àncora prende il salto, il conto resta certo.
    func testTheThreeRenumberingsOfThe1stOfNovember() throws {
        var c = count(songA, link: 800.0)
        var r = read(&c, 820.0, 8.0)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertEqual(r.place, inSong(0, 20, 6))
        r = read(&c, 829.0, aB1 + 1.0 * 60.0 / 180.5)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        XCTAssertNil(r.recognized)
        r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5, last: (1, 3, aB1 + 3.0 * 60.0 / 180.5))
        assertCertain(r)
        var rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, 4.0188, accuracy: 1e-6)
        XCTAssertEqual(try gap(r), 4.0188, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertEqual(r.place, inSong(1, 4, 4))
        XCTAssertEqual(try XCTUnwrap(c.anchor).linkBeat, 804.0188, accuracy: 1e-6)
        r = read(&c, 838.0 + 4.0188, aB1 + 10.0 * 60.0 / 180.5)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertNil(r.recognized)
        XCTAssertEqual(r.place, inSong(1, 10, 1))
        r = read(&c, 865.0 + 4.0188, aB2 + 1.0 * 60.0 / 121.0)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .open(boundary: 2, boundariesAfter: 0))
        r = read(&c, 867.0 + 4.0188 + 0.9352, aB2 + 3.0 * 60.0 / 121.0, last: (2, 2, aB2 + 2.0 * 60.0 / 121.0))
        assertCertain(r)
        rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 2)
        XCTAssertEqual(rec.jump, 0.9352, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertEqual(r.place, inSong(2, 3, 3))
        r = read(&c, 876.0 + 4.0188 + 0.9352, aB2 + 12.0 * 60.0 / 121.0)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(2, 12, 0))
        // la terza: 11 → 5 a 160,5, il salto all'indietro (22 battiti a 140: 9,428571 s)
        let b1 = 22.0 * 60.0 / 140.0
        c = count(song([(11, 2, 140.0), (5, 8, 160.5)]), link: 1200.0)
        r = read(&c, 1223.0, b1 + 1.0 * 60.0 / 160.5)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        r = read(&c, 1226.0 - 1.0425, b1 + 4.0 * 60.0 / 160.5, last: (1, 3, b1 + 3.0 * 60.0 / 160.5))
        assertCertain(r)
        rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, -1.0425, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(1, 4, 4))
        r = read(&c, 1232.0 - 1.0425, b1 + 10.0 * 60.0 / 160.5)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(1, 10, 0))
    }

    /// Un buco a cavallo del confine: l'ultimo battito contato dall'iPad sta ancora nella sezione vecchia (due
    /// battiti prima del confine), la lettura dopo il buco vede insieme il confine della band e la
    /// rinumerazione: prima il confine (lo stato si apre), poi lo scarto (riconosciuta).
    func testARenumberingInTheSameReadAsTheBoundaryBeforeTheFollowerPassesIt() throws {
        var c = count(songA, link: 800.0)
        assertCertain(read(&c, 820.0, 8.0))
        let r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5, last: (0, 26, 26.0 * 0.4))
        assertCertain(r)
        let rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, 4.0188, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(1, 4, 4))
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertEqual(c.bandSection, 1)
    }

    /// Numeri scelti qui: 4/4 → 3/4 a 120, e una rinumerazione di −4 battiti letta tre battiti dopo il confine.
    /// Sul righello di Link la band sembra ancora prima del confine (31 battiti su 32): lo stato lo apre il
    /// righello dei secondi.
    func testTheStateIsOpenedByTheBandOnTheSecondsRuler() throws {
        var c = count(song([(4, 8, 120.0), (3, 16, 120.0)]), link: 400.0)
        let r = read(&c, 400.0 + 35.0 - 4.0, 17.5, last: (1, 2, 17.0))
        assertCertain(r)
        let rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, -4.0, accuracy: 1e-9)
        XCTAssertEqual(r.place, inSong(1, 3, 0))
    }

    /// L'iPad ha perso due battiti di nascosto: il suo ultimo battito contato dice 1 dove i secondi dicono 3.
    func testAJumpInTheOpenStateWithoutTheCounterIsUncertain() {
        var c = count(songA, link: 800.0)
        assertCertain(read(&c, 829.0, aB1 + 1.0 * 60.0 / 180.5))
        var r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5, last: (1, 1, aB1 + 3.0 * 60.0 / 180.5))
        assertUncertain(r, .jumpWithoutCounterAgreement)
        XCTAssertEqual(c.closed, FollowerBandCountClosed.jumpWithoutCounterAgreement)
        // senza nessun battito contato non c'è accordo
        c = count(songA, link: 800.0)
        r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5)
        assertUncertain(r, .jumpWithoutCounterAgreement)
    }

    func testASecondJumpInTheSameOpeningIsUncertain() throws {
        var c = count(songA, link: 800.0)
        var r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5, last: (1, 3, aB1 + 3.0 * 60.0 / 180.5))
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .closed)
        r = read(&c, 834.0 + 4.0188 + 2.0, aB1 + 6.0 * 60.0 / 180.5, last: (1, 5, aB1 + 5.0 * 60.0 / 180.5))
        assertUncertain(r, .jumpOutsideRenumbering)
        XCTAssertEqual(try gap(r), 2.0, accuracy: 1e-6)
    }

    /// Riga 10: un salto fuori dallo stato. Il conto resta chiuso per il resto della canzone.
    func testAJumpInTheMiddleOfASectionClosesTheCountForTheRestOfTheSong() throws {
        let map = song([(4, 16, 120.0)])
        var c = count(map, link: 100.0)
        assertCertain(read(&c, 110.0, 5.0))
        var r = read(&c, 113.0, 6.0, last: (0, 11, 5.5))
        assertUncertain(r, .jumpOutsideRenumbering)
        XCTAssertEqual(try gap(r), 1.0, accuracy: 1e-9)
        XCTAssertFalse(r.closedBefore)
        // lo scarto torna a zero: il conto resta chiuso, col motivo di prima
        r = read(&c, 114.0, 7.0)
        assertUncertain(r, .jumpOutsideRenumbering)
        XCTAssertTrue(r.closedBefore)
        XCTAssertNil(r.gapBeats)
        // e un ingresso nella stessa canzone non lo riapre
        let again = try noCount(enter(c, map, entry: ticks(play, 2.0), link: 300.0))
        XCTAssertEqual(again.closed, FollowerBandCountClosed.jumpOutsideRenumbering)
    }

    /// A.2, caso 1: 4/4 → una battuta di 2/4 a 120 (1 s, meno dell'attesa dell'assert) → 2/4. La rinumerazione
    /// (+2,0188, scelta qui) cade nella sezione dopo la battuta corta: lo stato è ancora aperto (un confine dopo).
    func testOneBarOfTwoFourAfterTheMeterChange() throws {
        var c = count(song([(4, 4, 120.0), (2, 1, 120.0), (2, 8, 120.0)]), link: 600.0)
        assertCertain(read(&c, 617.0, 8.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        assertCertain(read(&c, 619.0, 9.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 1))
        let r = read(&c, 621.0 + 2.0188, 10.5, last: (2, 2, 10.0))
        assertCertain(r)
        let rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, 2.0188, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(2, 3, 1))
        XCTAssertEqual(c.renumbering, .closed)
    }

    /// A.2, caso 2: 7/8 → una battuta di 2/4 → 3/4: il secondo confine cambia di nuovo il metro e riapre lo stato.
    func testAMeterChangeAgainInsideTheStateReopensIt() throws {
        var c = count(song([(7, 2, 120.0), (2, 1, 120.0), (3, 8, 120.0)]), link: 600.0)
        assertCertain(read(&c, 615.0, 7.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        var r = read(&c, 619.0 - 1.0188, 9.5, last: (2, 2, 9.0))
        assertCertain(r)
        var rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 2)
        XCTAssertEqual(rec.jump, -1.0188, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(2, 3, 0))
        // due rinumerazioni, una per apertura: la sezione in 2/4 dura quattro battute
        c = count(song([(7, 2, 120.0), (2, 4, 120.0), (3, 8, 120.0)]), link: 600.0)
        r = read(&c, 617.0 + 3.0188, 8.5, last: (1, 2, 8.0))
        assertCertain(r)
        rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(c.renumbering, .closed)
        r = read(&c, 620.0 + 3.0188, 10.0)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .closed)
        r = read(&c, 623.0 + 3.0188, 11.5)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .open(boundary: 2, boundariesAfter: 0))
        r = read(&c, 625.0 + 3.0188 + 0.9352, 12.5, last: (2, 2, 12.0))
        assertCertain(r)
        rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 2)
        XCTAssertEqual(rec.jump, 0.9352, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(2, 3, 0))
    }

    /// 4/4, una battuta di 2/4, poi 2/4: i confini a 8 s (16 battiti) e a 9 s (18).
    private var shortBar: SongMap { song([(4, 4, 120.0), (2, 1, 120.0), (2, 16, 120.0)]) }
    /// L'ora del battito j della band nella terza sezione, suonata a 124.
    private func at(_ j: Int) -> Double { 9.0 + Double(j) * 60.0 / 124.0 }

    /// A.2, caso 3 (il prezzo): la band va a 124 proprio nella sezione dopo la battuta corta. Il primo scarto
    /// oltre 1/8 (al battito 4: 0,129) col contatore d'accordo passa per rinumerazione; la deriva continua e il
    /// «non certo» arriva al battito 8, 1,935 s dopo il salto preso, non prima.
    func testATrueTempoChangeInTheExtraSectionIsTakenOnceThenUncertain() throws {
        var c = count(shortBar, link: 600.0)
        var r = read(&c, 620.0, at(2), last: (2, 1, at(1)))
        assertCertain(r)
        XCTAssertEqual(try gap(r), 2.0 - 2.0 * 120.0 / 124.0, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 1))
        r = read(&c, 622.0, at(4), last: (2, 3, at(3)))
        assertCertain(r)
        let rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 1)
        XCTAssertEqual(rec.jump, 4.0 - 4.0 * 120.0 / 124.0, accuracy: 1e-6)
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertEqual(r.place, inSong(2, 4, 0))
        for j in [6, 7] {
            r = read(&c, 618.0 + Double(j), at(j), last: (2, j - 1, at(j - 1)))
            assertCertain(r)
        }
        r = read(&c, 626.0, at(8), last: (2, 7, at(7)))
        assertUncertain(r, .jumpOutsideRenumbering)
        let takenToUncertain = at(8) - at(4)
        XCTAssertGreaterThanOrEqual(takenToUncertain, 1.9)
        XCTAssertLessThanOrEqual(takenToUncertain, 2.9)
    }

    /// Lo stesso caso letto al battito 5: lo scarto è 0,161 e l'ultimo battito contato (il 4) dista 0,129 dal suo
    /// posto sui secondi: il contatore non è d'accordo, quindi niente rinumerazione: «non certo» subito.
    func testATrueTempoChangeSeenFirstByTheCounterIsUncertainAtOnce() throws {
        var c = count(shortBar, link: 600.0)
        assertCertain(read(&c, 620.0, at(2), last: (2, 1, at(1))))
        let r = read(&c, 623.0, at(5), last: (2, 4, at(4)))
        assertUncertain(r, .jumpWithoutCounterAgreement)
        XCTAssertEqual(try gap(r), 5.0 - 5.0 * 120.0 / 124.0, accuracy: 1e-6)
    }

    /// 4/4, una battuta di 2/4, poi due sezioni in 2/4: i confini a 8, 9 e 17 s.
    private var late: SongMap { song([(4, 4, 120.0), (2, 1, 120.0), (2, 8, 120.0), (2, 8, 120.0)]) }

    /// L'assert del Direttore non arriva (segue Link dopo un suo buco, o lo scarto è un multiplo del quanto):
    /// nessun salto, lo stato si chiude al secondo confine; un salto dopo è fuori dallo stato. Un assert in
    /// ritardo ma prima del secondo confine si riconosce.
    func testTheStateClosesAtTheSecondBoundaryWhenNoRenumberingComes() throws {
        var c = count(late, link: 600.0)
        assertCertain(read(&c, 617.0, 8.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        assertCertain(read(&c, 619.0, 9.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 1))
        var r = read(&c, 635.0, 17.5)
        assertCertain(r)
        XCTAssertEqual(c.renumbering, .closed)
        XCTAssertNil(r.recognized)
        XCTAssertEqual(r.place, inSong(3, 1, 1))
        r = read(&c, 637.0 + 2.0188, 18.5, last: (3, 2, 18.0))
        assertUncertain(r, .jumpOutsideRenumbering)
        // un assert in ritardo (un buco del Direttore sotto la soglia), ma prima del secondo confine: riconosciuta
        c = count(late, link: 600.0)
        r = read(&c, 624.0 + 2.0188, 12.0, last: (2, 5, 11.5))
        assertCertain(r)
        XCTAssertEqual(try XCTUnwrap(r.recognized).boundary, 1)
        XCTAssertEqual(r.place, inSong(2, 6, 0))
    }

    /// A.2, caso 5 (il limite scritto): 7/8 → 2/4 (una battuta) → 2/4 (una battuta) → 2/4. Il Direttore riapre la
    /// sua finestra a ogni scambio, e l'assert arriva dopo il SECONDO confine dopo il cambio: lì lo stato si è
    /// appena chiuso. «Non certo», come atteso.
    func testTwoShortSectionsThenTheSameMeterIsTheWrittenLimit() {
        var c = count(song([(7, 2, 120.0), (2, 1, 120.0), (2, 1, 120.0), (2, 8, 120.0)]), link: 600.0)
        assertCertain(read(&c, 615.0, 7.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 0))
        assertCertain(read(&c, 617.0, 8.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 1, boundariesAfter: 1))
        assertCertain(read(&c, 619.0, 9.5))
        XCTAssertEqual(c.renumbering, .closed)
        let r = read(&c, 621.0 + 2.0188, 10.5, last: (3, 2, 10.0))
        assertUncertain(r, .jumpOutsideRenumbering)
    }

    /// Lo stesso, ma al secondo confine il metro cambia di nuovo (2/4 → 4/4): lo stato si riapre lì e la
    /// rinumerazione si riconosce.
    func testTwoShortSectionsThenAMeterChangeIsRecognized() throws {
        var c = count(song([(7, 2, 120.0), (2, 1, 120.0), (2, 1, 120.0), (4, 8, 120.0)]), link: 600.0)
        assertCertain(read(&c, 615.0, 7.5))
        assertCertain(read(&c, 617.0, 8.5))
        assertCertain(read(&c, 619.0, 9.5))
        XCTAssertEqual(c.renumbering, .open(boundary: 3, boundariesAfter: 0))
        let r = read(&c, 621.0 + 2.0188, 10.5, last: (3, 2, 10.0))
        assertCertain(r)
        let rec = try XCTUnwrap(r.recognized)
        XCTAssertEqual(rec.boundary, 3)
        XCTAssertEqual(rec.jump, 2.0188, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(3, 3, 3))
    }

    /// Un buco dell'iPad prima del cambio di metro (01/11, il Verse) e uno dopo la rinumerazione riconosciuta: le
    /// letture saltano dei secondi, i due righelli no.
    func testHolesDoNotMoveTheRulers() throws {
        var c = count(songA, link: 800.0)
        assertCertain(read(&c, 804.0, 1.6))
        var r = read(&c, 824.0, 9.6)                       // otto secondi senza letture
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(0, 24, 3))
        r = read(&c, 832.0 + 4.0188, aB1 + 4.0 * 60.0 / 180.5, last: (1, 3, aB1 + 3.0 * 60.0 / 180.5))
        assertCertain(r)
        XCTAssertEqual(try XCTUnwrap(r.recognized).boundary, 1)
        r = read(&c, 858.0 + 4.0188, aB1 + 30.0 * 60.0 / 180.5)
        assertCertain(r)
        XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-6)
        XCTAssertEqual(r.place, inSong(1, 30, 3))
    }

    /// A.9 (il limite scritto): l'iPad ha davanti un altro pezzo con lo stesso tempo e lo stesso metro: i due
    /// righelli vanno d'accordo, il conto resta certo e dice i posti della SUA mappa.
    func testTwoSongsAt120WithDifferentStructuresIsTheWrittenLimit() throws {
        var c = count(song([(4, 8, 120.0), (4, 8, 120.0)]), link: 100.0)
        for (n, section, beat, inBar) in [(10, 0, 10, 2), (40, 1, 8, 0), (60, 1, 28, 0)] {
            let r = read(&c, 100.0 + Double(n), Double(n) / 2.0)
            assertCertain(r)
            XCTAssertEqual(try gap(r), 0.0, accuracy: 1e-9)
            XCTAssertEqual(r.place, inSong(section, beat, inBar))
        }
    }
}
