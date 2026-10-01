import XCTest

// === A386 · FASE B2c — banco di «il Follower segue Link?» (banco Models) ===
// Ingressi: ruolo × Link acceso dall'utente × stato della macchina × orologio proprio fino
// all'arresto. Attesi LETTERALI. Una regola sola dice «non segue»: il Follower (ruolo
// `.collaborativa` E Link acceso dall'utente) in DA SOLO, o nella coda fra l'uscita da DA SOLO e
// l'arresto del motore. Tutto il resto e' la prova che Direttore, Solo, ruolo Follower con Link
// spento dall'utente, IN SYNC e FUORI restano come prima.
// Il banco gira in CI (`.github/workflows/ios_build.yml`, `xcodebuild test -scheme QBeatsTests`).

final class FollowerLinkFollowDecisionTests: XCTestCase {

    private let states: [FollowerSyncState] = [
        .inSync(songClosed: false),
        .inSync(songClosed: true),
        .alone,
        .out(armed: nil),
        .out(armed: 3),
    ]

    private func follows(_ role: LinkMode, _ user: Bool, _ state: FollowerSyncState, ownClock: Bool = false) -> Bool {
        FollowerLinkFollowDecision.followsLink(role: role, userLinkEnabled: user,
                                               state: state, ownClockUntilStop: ownClock)
    }

    // MARK: - Il Follower, stato per stato

    func testFollowerInSyncFollowsLink() {
        XCTAssertTrue(follows(.collaborativa, true, .inSync(songClosed: false)))
        XCTAssertTrue(follows(.collaborativa, true, .inSync(songClosed: true)))
    }

    func testFollowerAloneDoesNotFollowLink() {
        XCTAssertFalse(follows(.collaborativa, true, .alone))
    }

    func testFollowerOutFollowsLinkAsToday() {
        XCTAssertTrue(follows(.collaborativa, true, .out(armed: nil)))
        XCTAssertTrue(follows(.collaborativa, true, .out(armed: 3)))
    }

    /// DA SOLO resta «non segue» anche dopo un riavvio del motore (ripresa dopo un'interruzione):
    /// il motore abbassa l'orologio proprio, ma lo stato basta da solo.
    func testFollowerAloneDoesNotFollowEvenWithTheOwnClockLowered() {
        XCTAssertFalse(follows(.collaborativa, true, .alone, ownClock: false))
        XCTAssertFalse(follows(.collaborativa, true, .alone, ownClock: true))
    }

    // MARK: - La coda fra l'uscita da DA SOLO e l'arresto del motore

    func testFollowerOutWithOwnClockDoesNotFollowUntilTheEngineStops() {
        XCTAssertFalse(follows(.collaborativa, true, .out(armed: nil), ownClock: true))
        XCTAssertFalse(follows(.collaborativa, true, .out(armed: 3), ownClock: true))
    }

    func testOwnClockRisesEnteringAloneAndStaysForEveryOtherState() {
        let lost = FollowerSyncEvent.directorHeard(false, engineRunning: true)
        XCTAssertTrue(FollowerLinkFollowDecision.ownClockUntilStop(after: lost, state: .alone, previous: false))
        XCTAssertTrue(FollowerLinkFollowDecision.ownClockUntilStop(after: lost, state: .alone, previous: true))
        for state in states where state != .alone {
            XCTAssertFalse(FollowerLinkFollowDecision.ownClockUntilStop(after: .ownSongEnded, state: state, previous: false),
                           "stato:\(state)")
            XCTAssertTrue(FollowerLinkFollowDecision.ownClockUntilStop(after: .ownSongEnded, state: state, previous: true),
                          "stato:\(state)")
        }
    }

    /// Un `reset` (Link spento dall'utente, cambio di ruolo, END SHOW, uscita dalla stanza)
    /// abbassa l'orologio proprio, da qualunque stato: se l'apparecchio ridiventa Follower a
    /// motore in moto, segue Link come oggi.
    func testResetLowersTheOwnClock() {
        for state in states {
            for previous in [false, true] {
                XCTAssertFalse(FollowerLinkFollowDecision.ownClockUntilStop(after: .reset, state: state, previous: previous),
                               "stato:\(state) prima:\(previous)")
            }
        }
        // sulla macchina vera: DA SOLO -> reset -> FUORI non armato, orologio proprio abbassato
        var ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: .directorHeard(false, engineRunning: true),
                                                                    state: .alone, previous: false)
        XCTAssertTrue(ownClock)
        let reset = FollowerSyncDecision.transition(state: .alone, event: .reset)
        XCTAssertEqual(reset.state, .out(armed: nil))
        ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: .reset, state: reset.state, previous: ownClock)
        XCTAssertFalse(ownClock)
        XCTAssertTrue(follows(.collaborativa, true, reset.state, ownClock: ownClock))
    }

    /// Il giro del difetto del collaudo dell'01/10/2026, passo per passo sulla macchina vera:
    /// IN SYNC in moto -> non si sente piu' il Direttore -> DA SOLO -> la rete torna e il Direttore
    /// si sente di nuovo -> ancora DA SOLO -> fine canzone propria -> FUORI.
    func testTheDefectScenarioThroughTheRealMachine() {
        var state: FollowerSyncState = .inSync(songClosed: false)
        var ownClock = false
        func step(_ event: FollowerSyncEvent) {
            state = FollowerSyncDecision.transition(state: state, event: event).state
            ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: event, state: state, previous: ownClock)
        }
        XCTAssertTrue(follows(.collaborativa, true, state, ownClock: ownClock))
        step(.directorHeard(false, engineRunning: true))
        XCTAssertEqual(state, .alone)
        XCTAssertFalse(follows(.collaborativa, true, state, ownClock: ownClock))
        step(.directorHeard(true, engineRunning: true))
        XCTAssertEqual(state, .alone)
        XCTAssertFalse(follows(.collaborativa, true, state, ownClock: ownClock),
                       "la rete e' tornata: DA SOLO resta sul proprio orologio")
        step(.ownSongEnded)
        XCTAssertEqual(state, .out(armed: nil))
        XCTAssertFalse(follows(.collaborativa, true, state, ownClock: ownClock),
                       "FUORI, motore non ancora dichiarato fermo: ancora orologio proprio")
        // il motore si ferma: abbassa l'orologio proprio
        ownClock = false
        XCTAssertTrue(follows(.collaborativa, true, state, ownClock: ownClock))
        // rientro: armato, Play del Direttore -> IN SYNC, segue Link come oggi
        step(.armed(FollowerArming(source: .rientra(songIdx: 1), directorHeard: true, sessionPlaying: false)))
        step(.linkPlay(withinHalfBar: true))
        XCTAssertEqual(state, .inSync(songClosed: false))
        XCTAssertTrue(follows(.collaborativa, true, state, ownClock: ownClock))
    }

    /// DA SOLO + Stop del Direttore: la macchina va FUORI con «fermati», il motore si ferma dopo.
    func testDirectorStopWhileAloneKeepsTheOwnClockInTheTail() {
        var ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: .directorHeard(false, engineRunning: true),
                                                                    state: .alone, previous: false)
        let stopEvent = FollowerSyncEvent.linkStop(falseStart: false, engineRunning: true)
        let stop = FollowerSyncDecision.transition(state: .alone, event: stopEvent)
        XCTAssertEqual(stop.state, .out(armed: nil))
        XCTAssertEqual(stop.action, .stopAndArmNext)
        ownClock = FollowerLinkFollowDecision.ownClockUntilStop(after: stopEvent, state: stop.state, previous: ownClock)
        XCTAssertFalse(follows(.collaborativa, true, stop.state, ownClock: ownClock))
    }

    // MARK: - Chi non e' Follower: tutto come prima, qualunque stato e qualunque orologio

    func testWhoIsNotAFollowerAlwaysFollowsTheRoadsOfToday() {
        let notFollowers: [(LinkMode, Bool)] = [
            (.standalone, false), (.standalone, true),
            (.direttore, false), (.direttore, true),
            (.collaborativa, false),
        ]
        for (role, user) in notFollowers {
            for state in states {
                for ownClock in [false, true] {
                    XCTAssertTrue(follows(role, user, state, ownClock: ownClock),
                                  "ruolo:\(role) linkUtente:\(user) stato:\(state) orologioProprio:\(ownClock)")
                }
            }
        }
    }

    /// La decisione usa la STESSA regola di `FollowerDecision`: solo chi e' Follower puo' non seguire.
    func testOnlyAFollowerCanStopFollowing() {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            for user in [false, true] {
                let isFollower = FollowerDecision.isFollower(role: role, userLinkEnabled: user)
                XCTAssertEqual(follows(role, user, .alone), !isFollower,
                               "ruolo:\(role) linkUtente:\(user)")
            }
        }
    }

    // MARK: - Il tempo da ridare al motore alla soglia di DA SOLO

    func testNothingToRestoreWhenTheTempoInForceIsTheSongsOwn() {
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: 121.0, adoptedFromLink: nil,
                                                               sectionChangePending: false))
    }

    func testTheSectionTempoIsRestoredWhenTheTempoInForceCameFromLink() {
        XCTAssertEqual(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: 121.0, adoptedFromLink: 141.0,
                                                                 sectionChangePending: false), 121.0)
        // anche quando il valore adottato e' lo stesso a meno dell'arrotondamento di Link
        XCTAssertEqual(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: 121.0, adoptedFromLink: 120.999944,
                                                                 sectionChangePending: false), 121.0)
    }

    func testNothingToRestoreWhenASectionChangeIsAlreadyArmed() {
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: 130.0, adoptedFromLink: 141.0,
                                                               sectionChangePending: true))
    }

    func testNothingToRestoreWithAnInvalidSectionTempo() {
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: 0.0, adoptedFromLink: 141.0,
                                                               sectionChangePending: false))
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: -1.0, adoptedFromLink: 141.0,
                                                               sectionChangePending: false))
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: .nan, adoptedFromLink: 141.0,
                                                               sectionChangePending: false))
        XCTAssertNil(FollowerLinkFollowDecision.tempoToRestore(sectionTempo: .infinity, adoptedFromLink: 141.0,
                                                               sectionChangePending: false))
    }
}
