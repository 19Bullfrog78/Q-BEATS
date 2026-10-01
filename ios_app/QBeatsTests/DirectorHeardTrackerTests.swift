import XCTest

// === A386 · FASE B1 — banco del segnale «sento il Direttore» (banco Models) ===
// Soglia in tick: 3,0 s a 24.000 tick per millisecondo (misura A382 §3.6) = 72.000.000 tick;
// il tipo riceve i tick, la conversione e' del chiamante. Attesi letterali per ogni regola:
// il primo campione non e' un colpo; un cambio fra due catture lo e'; un cambio nello stesso
// intervallo di una scrittura propria della linea temporale (W2) non lo e'; un colpo falso
// isolato ritarda il «non sento» di una soglia e basta; a Link spento si riparte da capo.
// B2b: «Searching…» — dal primo campione al primo verdetto (primo colpo, o una soglia senza
// colpi), mai oltre la soglia; a Link spento e riacceso si ricomincia a cercare.

final class DirectorHeardTrackerTests: XCTestCase {

    private let threshold: UInt64 = 72_000_000        // 3,0 s
    private let second: UInt64 = 24_000_000           // 1,0 s

    private func sample(playing: Bool = true, time: UInt64, link: Bool = true) -> DirectorHeardSample {
        DirectorHeardSample(linkEnabled: link, isPlaying: playing, timeForIsPlaying: time)
    }

    func testFirstSampleIsNotAHit() {
        let v = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: 10 * second,
                                                   thresholdTicks: threshold,
                                                   ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(v.heard)
        XCTAssertFalse(v.hit)
        XCTAssertEqual(v.next.lastSample, sample(time: 1_000))
        XCTAssertNil(v.next.lastHitAt)
    }

    func testAChangeBetweenTwoSamplesIsAHitAndIsHeard() {
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: 10 * second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let later = first.next.observe(sample: sample(time: 1_000 + 24_000), now: 11 * second,
                                       thresholdTicks: threshold,
                                       ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(later.hit)
        XCTAssertTrue(later.heard)
        XCTAssertEqual(later.next.lastHitAt, 11 * second)
    }

    func testIsPlayingChangeAloneIsAHit() {
        let first = DirectorHeardTracker.start.observe(sample: sample(playing: true, time: 5_000), now: second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let v = first.next.observe(sample: sample(playing: false, time: 5_000), now: 2 * second,
                                   thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(v.hit)
        XCTAssertTrue(v.heard)
    }

    func testHeardLastsLessThanTheThresholdThenStops() {
        let hitAt = 20 * second
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: hitAt)
        let unchanged = sample(time: 7_000)
        let before = tracker.observe(sample: unchanged, now: hitAt + threshold - 1,
                                     thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(before.heard)
        XCTAssertFalse(before.hit)
        let atEdge = tracker.observe(sample: unchanged, now: hitAt + threshold,
                                     thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(atEdge.heard)
        let after = tracker.observe(sample: unchanged, now: hitAt + threshold + second,
                                    thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(after.heard)
    }

    func testOwnTimelineWriteIsNotAHitAndTheNewValueIsAdopted() {
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: nil)
        let v = tracker.observe(sample: sample(time: 9_000), now: 30 * second,
                                thresholdTicks: threshold, ownTimelineWriteSinceLastSample: true)
        XCTAssertFalse(v.hit)
        XCTAssertFalse(v.heard)
        XCTAssertEqual(v.next.lastSample, sample(time: 9_000))
        XCTAssertNil(v.next.lastHitAt)
        // un cambio successivo, rispetto al valore adottato, e' un colpo
        let later = v.next.observe(sample: sample(time: 9_000 + 24_000), now: 31 * second,
                                   thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(later.hit)
        XCTAssertTrue(later.heard)
        // e lo stesso valore adottato, senza scrittura propria, non lo e'
        let same = v.next.observe(sample: sample(time: 9_000), now: 31 * second,
                                  thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(same.hit)
    }

    func testOwnTimelineWriteDoesNotExtendAnEarlierHit() {
        let hitAt = 20 * second
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: hitAt)
        let v = tracker.observe(sample: sample(time: 9_000), now: hitAt + threshold + second,
                                thresholdTicks: threshold, ownTimelineWriteSinceLastSample: true)
        XCTAssertFalse(v.hit)
        XCTAssertFalse(v.heard)
        XCTAssertEqual(v.next.lastHitAt, hitAt)
    }

    func testAnIsolatedFalseHitDuringAbsenceDelaysNotHeardByOneThreshold() {
        // assenza dal tick 0: l'ultimo colpo vero e' a 0
        var tracker = DirectorHeardTracker(lastSample: sample(time: 1_000), lastHitAt: 0)
        var now: UInt64 = threshold + second          // gia' «non sento»
        var v = tracker.observe(sample: sample(time: 1_000), now: now, thresholdTicks: threshold,
                                ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(v.heard)
        tracker = v.next
        // un colpo falso isolato
        now += second
        v = tracker.observe(sample: sample(time: 1_000 + 24_000), now: now, thresholdTicks: threshold,
                            ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(v.hit)
        XCTAssertTrue(v.heard)
        let falseHitAt = now
        tracker = v.next
        // poi silenzio: si sente fino alla soglia dal colpo falso, e non oltre
        v = tracker.observe(sample: sample(time: 1_000 + 24_000), now: falseHitAt + threshold - 1,
                            thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(v.heard)
        v = tracker.observe(sample: sample(time: 1_000 + 24_000), now: falseHitAt + threshold,
                            thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(v.heard)
    }

    func testLinkOffResetsAndTheFirstSampleAfterIsNotAHit() {
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: 5 * second)
        let off = tracker.observe(sample: sample(time: 0, link: false), now: 6 * second,
                                  thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(off.heard)
        XCTAssertFalse(off.hit)
        XCTAssertEqual(off.next, .start)
        let back = off.next.observe(sample: sample(time: 12_000), now: 7 * second,
                                    thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(back.hit)
        XCTAssertFalse(back.heard)
    }

    func testZeroThresholdIsNeverHeard() {
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: second,
                                                       thresholdTicks: 0, ownTimelineWriteSinceLastSample: false)
        let v = first.next.observe(sample: sample(time: 2_000), now: 2 * second,
                                   thresholdTicks: 0, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(v.hit)
        XCTAssertFalse(v.heard)
    }

    // MARK: - B2b: «Searching…», dal primo campione al primo verdetto

    func testSearchingStartsWithTheFirstSample() {
        let v = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: 10 * second,
                                                   thresholdTicks: threshold,
                                                   ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(v.searching)
        XCTAssertFalse(v.heard)
        XCTAssertEqual(v.next.firstSampleAt, 10 * second)
    }

    func testSearchingEndsAtTheFirstHitAndNeverComesBack() {
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: 10 * second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let hit = first.next.observe(sample: sample(time: 1_000 + 24_000), now: 11 * second,
                                     thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(hit.hit)
        XCTAssertTrue(hit.heard)
        XCTAssertFalse(hit.searching)
        // poi silenzio oltre la soglia: «non sento», non «cerco»
        let lost = hit.next.observe(sample: sample(time: 1_000 + 24_000), now: 11 * second + threshold + second,
                                    thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(lost.heard)
        XCTAssertFalse(lost.searching)
    }

    func testSearchingEndsAfterOneThresholdWithoutHitsNeverBeyond() {
        let start = 10 * second
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: start,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let still = first.next.observe(sample: sample(time: 1_000), now: start + threshold - 1,
                                       thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(still.searching)
        XCTAssertFalse(still.heard)
        let over = still.next.observe(sample: sample(time: 1_000), now: start + threshold,
                                      thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(over.searching)
        XCTAssertFalse(over.heard)
        let later = over.next.observe(sample: sample(time: 1_000), now: start + 2 * threshold,
                                      thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(later.searching)
    }

    func testSearchingIsNeverTrueTogetherWithHeard() {
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let hit = first.next.observe(sample: sample(time: 2_000), now: 2 * second,
                                     thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(hit.heard)
        XCTAssertFalse(hit.searching)
    }

    func testOwnTimelineWriteWhileSearchingKeepsSearching() {
        let first = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        let echo = first.next.observe(sample: sample(time: 9_000), now: 2 * second,
                                      thresholdTicks: threshold, ownTimelineWriteSinceLastSample: true)
        XCTAssertFalse(echo.hit)
        XCTAssertTrue(echo.searching)
        XCTAssertEqual(echo.next.firstSampleAt, second)
    }

    func testLinkOffThenOnSearchesAgain() {
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: 5 * second,
                                           firstSampleAt: second)
        let off = tracker.observe(sample: sample(time: 0, link: false), now: 6 * second,
                                  thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(off.searching)
        XCTAssertNil(off.next.firstSampleAt)
        let back = off.next.observe(sample: sample(time: 12_000), now: 7 * second,
                                    thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(back.searching)
        XCTAssertEqual(back.next.firstSampleAt, 7 * second)
    }

    func testZeroThresholdNeverSearches() {
        let v = DirectorHeardTracker.start.observe(sample: sample(time: 1_000), now: second,
                                                   thresholdTicks: 0, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(v.searching)
    }

    // MARK: - B2c: un Play o uno Stop ricevuto e' un colpo, subito

    func testTransportEventIsAHitEvenWithoutAPreviousSample() {
        let v = DirectorHeardTracker.start.observeTransportEvent(sample: sample(playing: false, time: 4_000),
                                                                 now: 10 * second, thresholdTicks: threshold)
        XCTAssertTrue(v.hit)
        XCTAssertTrue(v.heard)
        XCTAssertFalse(v.searching)
        XCTAssertEqual(v.next.lastSample, sample(playing: false, time: 4_000))
        XCTAssertEqual(v.next.lastHitAt, 10 * second)
        XCTAssertEqual(v.next.firstSampleAt, 10 * second)
    }

    /// Il caso del collaudo (log C2, 14:17:36): non si sentiva piu', arriva lo Stop del
    /// Direttore — si sente nello stesso istante, senza aspettare il battito successivo.
    func testTransportEventIsHeardAtOnceAfterALongSilence() {
        let lastHit = 5 * second
        let tracker = DirectorHeardTracker(lastSample: sample(playing: true, time: 7_000),
                                           lastHitAt: lastHit, firstSampleAt: second)
        let silent = tracker.observe(sample: sample(playing: true, time: 7_000), now: lastHit + threshold + 10 * second,
                                     thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(silent.heard)
        let eventAt = lastHit + threshold + 10 * second + 1
        let v = silent.next.observeTransportEvent(sample: sample(playing: false, time: 90_000),
                                                  now: eventAt, thresholdTicks: threshold)
        XCTAssertTrue(v.hit)
        XCTAssertTrue(v.heard)
        XCTAssertEqual(v.next.lastHitAt, eventAt)
        XCTAssertEqual(v.next.firstSampleAt, second)
    }

    func testTransportEventIsHeardForOneThresholdLikeAnyHit() {
        let eventAt = 20 * second
        let event = DirectorHeardTracker.start.observeTransportEvent(sample: sample(playing: true, time: 9_000),
                                                                     now: eventAt, thresholdTicks: threshold)
        let before = event.next.observe(sample: sample(playing: true, time: 9_000), now: eventAt + threshold - 1,
                                        thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(before.heard)
        XCTAssertFalse(before.hit)
        let atEdge = event.next.observe(sample: sample(playing: true, time: 9_000), now: eventAt + threshold,
                                        thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(atEdge.heard)
        XCTAssertFalse(atEdge.searching)
    }

    /// La cattura del richiamo diventa l'ultimo campione: il battito successivo, con la stessa
    /// coppia, non conta lo stesso cambio una seconda volta; una coppia nuova e' un colpo nuovo.
    func testThePulseAfterATransportEventDoesNotCountTheSameChangeTwice() {
        let tracker = DirectorHeardTracker(lastSample: sample(playing: true, time: 7_000), lastHitAt: nil,
                                           firstSampleAt: second)
        let event = tracker.observeTransportEvent(sample: sample(playing: false, time: 8_000),
                                                  now: 30 * second, thresholdTicks: threshold)
        let samePair = event.next.observe(sample: sample(playing: false, time: 8_000), now: 31 * second,
                                          thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(samePair.hit)
        XCTAssertTrue(samePair.heard)
        XCTAssertEqual(samePair.next.lastHitAt, 30 * second)
        let newPair = event.next.observe(sample: sample(playing: false, time: 8_000 + 24_000), now: 31 * second,
                                         thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(newPair.hit)
        XCTAssertEqual(newPair.next.lastHitAt, 31 * second)
    }

    func testTransportEventEndsSearching() {
        let first = DirectorHeardTracker.start.observe(sample: sample(playing: false, time: 1_000), now: second,
                                                       thresholdTicks: threshold,
                                                       ownTimelineWriteSinceLastSample: false)
        XCTAssertTrue(first.searching)
        let event = first.next.observeTransportEvent(sample: sample(playing: true, time: 2_000),
                                                     now: second + 1, thresholdTicks: threshold)
        XCTAssertFalse(event.searching)
        XCTAssertTrue(event.heard)
        XCTAssertEqual(event.next.firstSampleAt, second)
        // dopo il colpo non si torna a cercare, nemmeno oltre la soglia
        let lost = event.next.observe(sample: sample(playing: true, time: 2_000), now: second + 1 + threshold,
                                      thresholdTicks: threshold, ownTimelineWriteSinceLastSample: false)
        XCTAssertFalse(lost.heard)
        XCTAssertFalse(lost.searching)
    }

    func testTransportEventWithLinkOffIsNotAHitAndResets() {
        let tracker = DirectorHeardTracker(lastSample: sample(time: 7_000), lastHitAt: 5 * second,
                                           firstSampleAt: second)
        let v = tracker.observeTransportEvent(sample: sample(playing: false, time: 0, link: false),
                                              now: 6 * second, thresholdTicks: threshold)
        XCTAssertFalse(v.hit)
        XCTAssertFalse(v.heard)
        XCTAssertFalse(v.searching)
        XCTAssertEqual(v.next, .start)
    }

    func testTransportEventWithZeroThresholdIsAHitButNeverHeard() {
        let v = DirectorHeardTracker.start.observeTransportEvent(sample: sample(time: 1_000),
                                                                 now: second, thresholdTicks: 0)
        XCTAssertTrue(v.hit)
        XCTAssertFalse(v.heard)
        XCTAssertFalse(v.searching)
    }
}
