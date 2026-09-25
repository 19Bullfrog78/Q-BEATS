import XCTest

// === A386 · FASE B1 — banco del segnale «sento il Direttore» (banco Models) ===
// Soglia in tick: 3,0 s a 24.000 tick per millisecondo (misura A382 §3.6) = 72.000.000 tick;
// il tipo riceve i tick, la conversione e' del chiamante. Attesi letterali per ogni regola:
// il primo campione non e' un colpo; un cambio fra due catture lo e'; un cambio nello stesso
// intervallo di una scrittura propria della linea temporale (W2) non lo e'; un colpo falso
// isolato ritarda il «non sento» di una soglia e basta; a Link spento si riparte da capo.

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
}
