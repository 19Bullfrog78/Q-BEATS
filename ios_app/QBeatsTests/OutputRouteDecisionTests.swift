import XCTest

// === A421 — banco della classe dell'uscita e dello stato «uscita zittita» / «uscita mancante» (`OutputRouteDecision`, banco
// Models), mandato par. 2.1 U2, U3, U5, U16, par. 2.2 f e g, par. 2.3 a e c ===
// La classe dalle porte di prima e di adesso (tipo e identificativo), qualunque sia il motivo: gli otto motivi con uscite che
// cambiano e che non cambiano; i quattro casi del 21/10; `unknown` con Speaker → Headphones (13:55:42 del 24/10); esterna →
// esterna; due esterne dello stesso tipo con identificativi diversi (aggiunta) e la stessa porta con lo stesso identificativo
// (nessuna). Poi il passo per ruolo (silenzio, crisi, «uscita mancante», ritorno), la matrice, lo stato con tutte le sue
// transizioni (la notizia persa con l'app sospesa, tolta e aggiunta nella stessa interruzione, il tocco «altoparlante»), il
// volume che `start()` scrive e i due invarianti.

final class OutputRouteDecisionTests: XCTestCase {

    private let speaker = OutputPort(type: "Speaker", uid: "Speaker")
    private let receiver = OutputPort(type: "Receiver", uid: "Receiver")
    private let headphones = OutputPort(type: "Headphones", uid: "Wired Headphones")
    private let bluetooth = OutputPort(type: "BluetoothA2DPOutput", uid: "00:11:22:33:44:55-tacl")
    private let bluetooth2 = OutputPort(type: "BluetoothA2DPOutput", uid: "66:77:88:99:AA:BB-tacl")
    private let usb = OutputPort(type: "USBAudio", uid: "AppleUSBAudioEngine:Focusrite:Scarlett 4i4:1")
    private let reasons = ["unknown", "newDeviceAvailable", "oldDeviceUnavailable", "categoryChange", "override",
                           "wakeFromSleep", "noSuitableRouteForCategory", "routeConfigurationChange"]
    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func classify(_ previous: [OutputPort], _ current: [OutputPort]) -> OutputRouteClass {
        OutputRouteDecision.classify(previous: previous, current: current).routeClass
    }

    // MARK: - Esterna

    func testExternalIsEveryOutputButTheSpeakerAndTheReceiver() {
        XCTAssertFalse(OutputRouteDecision.isExternal(portType: "Speaker"))
        XCTAssertFalse(OutputRouteDecision.isExternal(portType: "Receiver"))
        for type in ["Headphones", "BluetoothA2DPOutput", "BluetoothLE", "BluetoothHFP", "USBAudio", "LineOut", "HDMI",
                     "AirPlay", "CarAudio", "Thunderbolt", "DisplayPort", "AVB", "PCI", "FireWire", "Virtual"] {
            XCTAssertTrue(OutputRouteDecision.isExternal(portType: type), type)
        }
        XCTAssertEqual(OutputRouteDecision.builtInSpeakerType, "Speaker")
        XCTAssertEqual(OutputRouteDecision.builtInReceiverType, "Receiver")
        XCTAssertFalse(OutputRouteDecision.hasExternal([speaker]))
        XCTAssertFalse(OutputRouteDecision.hasExternal([]))
        XCTAssertTrue(OutputRouteDecision.hasExternal([speaker, headphones]))
    }

    // MARK: - La classe (U2)

    /// I quattro casi del 21/10 (referto A419, §2.1).
    func testTheFourCasesOfOctober21() {
        XCTAssertEqual(classify([headphones], [speaker]), .removed)
        XCTAssertEqual(classify([speaker], [headphones]), .added)
        XCTAssertEqual(classify([speaker], [bluetooth]), .added)
        XCTAssertEqual(classify([bluetooth], [speaker]), .removed)
    }

    /// Il 24/10 alle 13:55:42.778: `unknown`, Speaker → Headphones. Con la tabella del referto A419 sarebbe stato «nessuna»;
    /// la classe la danno le uscite: aggiunta.
    func testUnknownReasonWithSpeakerToHeadphonesIsAdded() {
        XCTAssertEqual(classify([speaker], [headphones]), .added)
        for reason in reasons {
            // Il motivo non entra nella classe: la funzione non lo prende nemmeno; qui si prova che per ogni motivo le
            // stesse uscite danno la stessa classe (il motivo va solo nella riga).
            XCTAssertEqual(classify([speaker], [headphones]), .added, reason)
            XCTAssertEqual(classify([headphones], [speaker]), .removed, reason)
            XCTAssertEqual(classify([speaker], [speaker]), .none, reason)
            XCTAssertEqual(classify([headphones], [headphones]), .none, reason)
        }
    }

    /// Esterna → esterna (le Bluetooth si spengono e restano quelle col filo; o la cassa al posto delle cuffie): aggiunta.
    func testExternalToExternalIsAdded() {
        XCTAssertEqual(classify([bluetooth], [headphones]), .added)
        XCTAssertEqual(classify([headphones, bluetooth], [headphones]), .added)
        XCTAssertEqual(classify([headphones], [headphones, usb]), .added)
    }

    /// Due esterne dello stesso tipo con identificativi diversi: aggiunta; la stessa porta con lo stesso identificativo:
    /// nessuna (anche con l'altoparlante accanto, e anche nessuna e nessuna).
    func testSameTypeDifferentUidIsAddedAndSamePortIsNone() {
        let step = OutputRouteDecision.classify(previous: [bluetooth], current: [bluetooth2])
        XCTAssertEqual(step.routeClass, .added)
        XCTAssertEqual(step.identity, .different)
        let same = OutputRouteDecision.classify(previous: [bluetooth], current: [bluetooth])
        XCTAssertEqual(same.routeClass, .none)
        XCTAssertEqual(same.identity, .same)
        XCTAssertEqual(classify([speaker, bluetooth], [bluetooth, speaker]), .none)
        let nothing = OutputRouteDecision.classify(previous: [speaker], current: [receiver])
        XCTAssertEqual(nothing.routeClass, .none)
        XCTAssertEqual(nothing.identity, .same)
        XCTAssertEqual(classify([], []), .none)
    }

    /// L'identità nella riga: «diverse» a ogni tolta e aggiunta, «stesse» a ogni nessuna.
    func testIdentityFollowsTheClass() {
        for (previous, current) in [([headphones], [speaker]), ([speaker], [headphones]), ([bluetooth], [headphones])] {
            XCTAssertEqual(OutputRouteDecision.classify(previous: previous, current: current).identity, .different)
        }
        XCTAssertEqual(OutputRouteDecision.classify(previous: [headphones], current: [headphones]).identity, .same)
    }

    func testTheNamesInTheLines() {
        XCTAssertEqual(OutputRouteClass.removed.rawValue, "tolta")
        XCTAssertEqual(OutputRouteClass.added.rawValue, "aggiunta")
        XCTAssertEqual(OutputRouteClass.none.rawValue, "nessuna")
        XCTAssertEqual(OutputRouteIdentity.same.rawValue, "stesse")
        XCTAssertEqual(OutputRouteIdentity.different.rawValue, "diverse")
        XCTAssertEqual(OutputReturnKind.director.rawValue, "direttore")
        XCTAssertEqual(OutputReturnKind.follower.rawValue, "follower")
    }

    // MARK: - Il passo per ruolo (U3, U4, U5, U16, par. 2.2 f)

    private func step(_ routeClass: OutputRouteClass, _ role: PlayerRole, show: Bool = true, song: Bool = true,
                      running: Bool = true, stoppedByCrisis: Bool = false, interruption: Bool = false) -> OutputRouteStep {
        OutputRouteDecision.step(routeClass: routeClass, playerRole: role, showOpen: show, songInProgress: song,
                                 engineRunning: running, stoppedByCrisis: stoppedByCrisis, inInterruption: interruption)
    }

    /// Il Direttore in canzone: tolta e aggiunta zittiscono e dichiarano la crisi; la tolta alza «uscita mancante»,
    /// l'aggiunta la abbassa e arma il ritorno del Direttore.
    func testDirectorInSong() {
        let removed = step(.removed, .direttore)
        XCTAssertTrue(removed.silences)
        XCTAssertEqual(removed.crisisCause, .outputRemoved)
        XCTAssertTrue(removed.raisesMissing)
        XCTAssertFalse(removed.lowersMissing)
        XCTAssertNil(removed.armsReturn)
        let added = step(.added, .direttore)
        XCTAssertTrue(added.silences)
        XCTAssertEqual(added.crisisCause, .outputAdded)
        XCTAssertFalse(added.raisesMissing)
        XCTAssertTrue(added.lowersMissing)
        XCTAssertEqual(added.armsReturn, .director)
        // Già muto a motore fermo per una crisi: la tolta alza «uscita mancante» senza silenzio; l'aggiunta arma il ritorno.
        let removedStopped = step(.removed, .direttore, running: false, stoppedByCrisis: true)
        XCTAssertFalse(removedStopped.silences)
        XCTAssertEqual(removedStopped.crisisCause, .outputRemoved)
        XCTAssertTrue(removedStopped.raisesMissing)
        let addedStopped = step(.added, .direttore, running: false, stoppedByCrisis: true)
        XCTAssertFalse(addedStopped.silences)
        XCTAssertEqual(addedStopped.armsReturn, .director)
        XCTAssertTrue(addedStopped.lowersMissing)
        // Fermo per uno Stop (fra una canzone e l'altra, a click fermo): la tolta non alza niente.
        XCTAssertFalse(step(.removed, .direttore, running: false).raisesMissing)
    }

    /// Il Direttore fuori da una canzone (U16): tolta ⇒ silenzio, crisi (arresto locale) e «uscita mancante»; aggiunta ⇒
    /// come oggi (niente silenzio, niente crisi, niente ritorno), con «uscita mancante» giù perché un'esterna c'è.
    func testDirectorOutOfSong() {
        for (show, song) in [(false, false), (true, false), (false, true)] {
            let removed = step(.removed, .direttore, show: show, song: song)
            XCTAssertTrue(removed.silences, "show:\(show) canzone:\(song)")
            XCTAssertEqual(removed.crisisCause, .outputRemoved, "show:\(show) canzone:\(song)")
            XCTAssertTrue(removed.raisesMissing, "show:\(show) canzone:\(song)")
            let added = step(.added, .direttore, show: show, song: song)
            XCTAssertFalse(added.silences, "show:\(show) canzone:\(song)")
            XCTAssertNil(added.crisisCause, "show:\(show) canzone:\(song)")
            XCTAssertNil(added.armsReturn, "show:\(show) canzone:\(song)")
            XCTAssertTrue(added.lowersMissing, "show:\(show) canzone:\(song)")
        }
    }

    /// Il Follower: tolta e aggiunta zittiscono (motore in moto), mai una crisi; la tolta alza «uscita mancante», l'aggiunta
    /// la abbassa e arma il ritorno del Follower (solo a motore in moto: a motore fermo decide `start()`).
    func testFollower() {
        for show in bools {
            for song in bools {
                let removed = step(.removed, .follower, show: show, song: song)
                XCTAssertTrue(removed.silences)
                XCTAssertNil(removed.crisisCause)
                XCTAssertTrue(removed.raisesMissing)
                let added = step(.added, .follower, show: show, song: song)
                XCTAssertTrue(added.silences)
                XCTAssertNil(added.crisisCause)
                XCTAssertTrue(added.lowersMissing)
                XCTAssertEqual(added.armsReturn, .follower)
            }
        }
        let addedStopped = step(.added, .follower, running: false, stoppedByCrisis: true)
        XCTAssertFalse(addedStopped.silences)
        XCTAssertNil(addedStopped.armsReturn)
        XCTAssertTrue(addedStopped.lowersMissing)
        XCTAssertTrue(step(.removed, .follower, running: false, stoppedByCrisis: true).raisesMissing)
        XCTAssertFalse(step(.removed, .follower, running: false).raisesMissing)
    }

    /// Il Solo: la tolta zittisce e dichiara «uscita-tolta» (come lo Stop della console); l'aggiunta è come oggi (par. 2.2
    /// f: nessun silenzio, nessuna crisi); «uscita mancante» non è sua.
    func testSolo() {
        let removed = step(.removed, .solo)
        XCTAssertTrue(removed.silences)
        XCTAssertEqual(removed.crisisCause, .outputRemoved)
        XCTAssertFalse(removed.raisesMissing)
        XCTAssertEqual(step(.added, .solo), .nothing)
        XCTAssertEqual(step(.added, .solo, show: false, song: false), .nothing)
        XCTAssertFalse(step(.removed, .solo, running: false, stoppedByCrisis: true).raisesMissing)
    }

    /// Dentro un'interruzione di sistema (la regola del referee del 21/10): solo lo stato, per ogni ruolo e classe.
    func testInsideAnInterruptionOnlyTheState() {
        for role in roles {
            for show in bools {
                for song in bools {
                    for running in bools {
                        for stopped in bools {
                            for routeClass in OutputRouteClass.allCases {
                                let s = step(routeClass, role, show: show, song: song, running: running,
                                             stoppedByCrisis: stopped, interruption: true)
                                let tag = "ruolo:\(role) classe:\(routeClass) show:\(show) canzone:\(song) motore:\(running) crisi:\(stopped)"
                                XCTAssertFalse(s.silences, tag)
                                XCTAssertNil(s.crisisCause, tag)
                                XCTAssertNil(s.armsReturn, tag)
                                if routeClass == .removed && role != .solo && (running || stopped) {
                                    XCTAssertTrue(s.raisesMissing, tag)
                                }
                                if routeClass == .added && role != .solo {
                                    XCTAssertTrue(s.lowersMissing, tag)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// «Nessuna»: niente, sempre.
    func testNoneDoesNothing() {
        for role in roles {
            for running in bools {
                for interruption in bools {
                    XCTAssertEqual(step(.none, role, running: running, interruption: interruption), .nothing)
                }
            }
        }
    }

    // MARK: - La matrice del passo

    private func expected(_ routeClass: OutputRouteClass, _ role: PlayerRole, show: Bool, song: Bool, running: Bool,
                          stopped: Bool, interruption: Bool) -> OutputRouteStep {
        let inSong = show && song
        switch routeClass {
        case .none:
            return .nothing
        case .removed:
            let raises = role != .solo && (running || stopped)
            if interruption {
                return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: raises, lowersMissing: false, armsReturn: nil)
            }
            return OutputRouteStep(silences: running, crisisCause: role == .follower ? nil : .outputRemoved,
                                   raisesMissing: raises, lowersMissing: false, armsReturn: nil)
        case .added:
            if interruption {
                return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: false, lowersMissing: role != .solo, armsReturn: nil)
            }
            switch role {
            case .solo:
                return .nothing
            case .follower:
                return OutputRouteStep(silences: running, crisisCause: nil, raisesMissing: false, lowersMissing: true,
                                       armsReturn: running ? .follower : nil)
            case .direttore:
                if !inSong {
                    return OutputRouteStep(silences: false, crisisCause: nil, raisesMissing: false, lowersMissing: true, armsReturn: nil)
                }
                return OutputRouteStep(silences: running, crisisCause: .outputAdded, raisesMissing: false, lowersMissing: true,
                                       armsReturn: .director)
            }
        }
    }

    func testTheStepMatrix() {
        var cells = 0
        for routeClass in OutputRouteClass.allCases {
            for role in roles {
                for show in bools {
                    for song in bools {
                        for running in bools {
                            for stopped in bools {
                                for interruption in bools {
                                    cells += 1
                                    let got = step(routeClass, role, show: show, song: song, running: running,
                                                   stoppedByCrisis: stopped, interruption: interruption)
                                    let want = expected(routeClass, role, show: show, song: song, running: running,
                                                        stopped: stopped, interruption: interruption)
                                    let tag = "classe:\(routeClass) ruolo:\(role) show:\(show) canzone:\(song) motore:\(running) crisi:\(stopped) interruzione:\(interruption)"
                                    XCTAssertEqual(got, want, tag)
                                    // Il silenzio solo col motore in moto e fuori da un'interruzione; mai nel Solo a un'aggiunta.
                                    if got.silences { XCTAssertTrue(running && !interruption, tag) }
                                    // Il Follower non dichiara mai una crisi; il Solo solo «uscita-tolta».
                                    if role == .follower { XCTAssertNil(got.crisisCause, tag) }
                                    if role == .solo { XCTAssertTrue(got.crisisCause == nil || got.crisisCause == .outputRemoved, tag) }
                                    // Un ritorno solo dopo un silenzio.
                                    if got.armsReturn != nil { XCTAssertTrue(got.silences || !running, tag) }
                                    // «Uscita mancante» non è del Solo.
                                    if role == .solo { XCTAssertFalse(got.raisesMissing, tag) }
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 3 * 3 * 2 * 2 * 2 * 2 * 2)
    }

    // MARK: - Lo stato (U3 b, U5)

    private func apply(_ events: [OutputSilenceEvent], role: PlayerRole,
                       from state: OutputSilenceState = .initial) -> OutputSilenceState {
        events.reduce(state) { OutputRouteDecision.state(after: $1, from: $0, playerRole: role) }
    }

    func testInitialState() {
        XCTAssertEqual(OutputSilenceState.initial, OutputSilenceState(muted: false, missing: false, lastOutputExternal: nil))
    }

    /// Il silenzio e il volume che torna, con la memoria dell'uscita.
    func testSilencedAndRestored() {
        for role in roles {
            let muted = apply([.silenced], role: role)
            XCTAssertTrue(muted.muted)
            let restored = apply([.silenced, .volumeRestored(externalPresent: true)], role: role)
            XCTAssertFalse(restored.muted)
            XCTAssertEqual(restored.lastOutputExternal, true)
            XCTAssertEqual(apply([.volumeRestored(externalPresent: false)], role: role).lastOutputExternal, false)
        }
    }

    /// La tolta alza «uscita mancante» per Direttore e Follower, mai per il Solo.
    func testRemovedRaisesMissingExceptForTheSolo() {
        XCTAssertTrue(apply([.removed], role: .direttore).missing)
        XCTAssertTrue(apply([.removed], role: .follower).missing)
        XCTAssertFalse(apply([.removed], role: .solo).missing)
    }

    /// La notizia persa con l'app sospesa (13:55:42 del 24/10): a ogni rientro automatico la rilettura del percorso decide
    /// dalla memoria. L'ultima uscita era esterna e adesso non c'è: si alza. Un'esterna c'è: si abbassa. Mai uscito, o
    /// uscito dall'altoparlante, e niente di esterno: resta com'è.
    func testRecoveryReadUsesTheMemory() {
        let wasExternal = OutputSilenceState(muted: false, missing: false, lastOutputExternal: true)
        XCTAssertTrue(apply([.recoveryRead(externalPresent: false)], role: .direttore, from: wasExternal).missing)
        XCTAssertFalse(apply([.recoveryRead(externalPresent: true)], role: .direttore, from: wasExternal).missing)
        let missingNow = OutputSilenceState(muted: true, missing: true, lastOutputExternal: true)
        XCTAssertFalse(apply([.recoveryRead(externalPresent: true)], role: .follower, from: missingNow).missing)
        XCTAssertTrue(apply([.recoveryRead(externalPresent: false)], role: .follower, from: missingNow).missing)
        let fromSpeaker = OutputSilenceState(muted: false, missing: false, lastOutputExternal: false)
        XCTAssertFalse(apply([.recoveryRead(externalPresent: false)], role: .direttore, from: fromSpeaker).missing)
        XCTAssertFalse(apply([.recoveryRead(externalPresent: false)], role: .direttore).missing)
        // U5 è per Direttore e Follower: il Solo non ha «uscita mancante», nemmeno dalla rilettura (dopo la verifica del diff).
        XCTAssertFalse(apply([.recoveryRead(externalPresent: false)], role: .solo, from: wasExternal).missing)
    }

    /// Tolta e aggiunta nella stessa interruzione: alla fine «uscita mancante» è giù.
    func testRemovedThenAddedInTheSameInterruption() {
        for role in [PlayerRole.direttore, .follower] {
            let state = apply([.removed, .externalPresent(playingAtVolumeOne: false)], role: role)
            XCTAssertFalse(state.missing, "\(role)")
            XCTAssertTrue(apply([.removed, .externalPresent(playingAtVolumeOne: false), .removed], role: role).missing, "\(role)")
        }
    }

    /// A421 · SEGUITO 2 (par. 5.3, E.7): un'aggiunta col motore in moto e il volume a 1 che resta (il Direttore fuori da una
    /// canzone, U16) porta la memoria sull'esterna; col volume a 0, o a motore fermo, la memoria resta quella di prima.
    func testAnAddedAtVolumeOneUpdatesTheMemory() {
        let fromSpeaker = OutputSilenceState(muted: false, missing: false, lastOutputExternal: false)
        let playing = apply([.externalPresent(playingAtVolumeOne: true)], role: .direttore, from: fromSpeaker)
        XCTAssertEqual(playing.lastOutputExternal, true)
        XCTAssertFalse(playing.missing)
        let notPlaying = apply([.externalPresent(playingAtVolumeOne: false)], role: .direttore, from: fromSpeaker)
        XCTAssertEqual(notPlaying.lastOutputExternal, false, "la memoria resta")
        let never = apply([.externalPresent(playingAtVolumeOne: false)], role: .follower)
        XCTAssertNil(never.lastOutputExternal)
        // Allo stacco dopo la rilettura alza «uscita mancante» solo se la memoria dice esterna.
        XCTAssertTrue(apply([.recoveryRead(externalPresent: false)], role: .direttore, from: playing).missing)
        XCTAssertFalse(apply([.recoveryRead(externalPresent: false)], role: .direttore, from: notPlaying).missing)
    }

    /// Il Direttore abbassa «uscita mancante» al suo Play (la scelta dell'uscita che c'è: la memoria diventa quella), allo
    /// Stop e a fine canzone (`directorStop`), alla chiusura dello show. Il Follower no al Play del Direttore (non è suo),
    /// no allo Stop e a fine canzone (risposta 3 di Mauro); sì col tocco «altoparlante» e alla chiusura dello show.
    func testWhoLowersMissing() {
        let play = apply([.removed, .directorPlay(externalPresent: false)], role: .direttore)
        XCTAssertFalse(play.missing)
        XCTAssertEqual(play.lastOutputExternal, false)
        XCTAssertFalse(apply([.removed, .directorStop], role: .direttore).missing)
        XCTAssertFalse(apply([.removed, .showClosed], role: .direttore).missing)
        XCTAssertTrue(apply([.removed, .directorPlay(externalPresent: false)], role: .follower).missing)
        XCTAssertTrue(apply([.removed, .directorStop], role: .follower).missing)
        XCTAssertTrue(apply([.removed, .followerSongEnd], role: .follower).missing)
        let tap = apply([.removed, .speakerTap], role: .follower)
        XCTAssertFalse(tap.missing)
        XCTAssertEqual(tap.lastOutputExternal, false)
        XCTAssertFalse(apply([.removed, .showClosed], role: .follower).missing)
        XCTAssertTrue(apply([.removed, .speakerTap], role: .direttore).missing, "il tocco è del Follower")
    }

    /// Il tocco «altoparlante» dopo il tocco: una tolta dopo rimette la regola.
    func testARemovedAfterTheTapRaisesAgain() {
        XCTAssertTrue(apply([.removed, .speakerTap, .removed], role: .follower).missing)
    }

    /// La chiusura dello show e il cambio di ruolo abbassano tutto; la chiusura dello show azzera anche la memoria.
    func testShowClosedAndRoleChangeLowerEverything() {
        for role in roles {
            let closed = apply([.silenced, .removed, .volumeRestored(externalPresent: true), .silenced, .showClosed], role: role)
            XCTAssertEqual(closed, .initial, "\(role)")
            let changed = apply([.silenced, .removed, .roleChange], role: role)
            XCTAssertFalse(changed.muted, "\(role)")
            XCTAssertFalse(changed.missing, "\(role)")
        }
    }

    // MARK: - Il volume di `start()` e gli invarianti (U3 b, par. 2.3 b)

    /// Nessun avvio resta a volume 0, salvo il Follower con l'uscita mancante.
    func testTheVolumeStartWrites() {
        let missing = OutputSilenceState(muted: true, missing: true, lastOutputExternal: true)
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .follower, state: missing), 0.0)
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .follower, state: .initial), 1.0)
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .direttore, state: missing), 1.0)
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .solo, state: missing), 1.0)
        let mutedOnly = OutputSilenceState(muted: true, missing: false, lastOutputExternal: nil)
        for role in roles {
            XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: role, state: mutedOnly), 1.0, "\(role)")
        }
    }

    /// Il Direttore con l'uscita mancante non riparte da solo.
    func testTheDirectorWithTheOutputMissingDoesNotRestartAutomatically() {
        let missing = OutputSilenceState(muted: false, missing: true, lastOutputExternal: true)
        XCTAssertTrue(OutputRouteDecision.directorAutoRestartBlocked(playerRole: .direttore, state: missing))
        XCTAssertFalse(OutputRouteDecision.directorAutoRestartBlocked(playerRole: .direttore, state: .initial))
        XCTAssertFalse(OutputRouteDecision.directorAutoRestartBlocked(playerRole: .follower, state: missing))
        XCTAssertFalse(OutputRouteDecision.directorAutoRestartBlocked(playerRole: .solo, state: missing))
    }

    /// Gli invarianti: volume 1 ⇒ non (Follower con l'uscita mancante); motore in moto ⇒ non (Direttore con l'uscita
    /// mancante). Su tutti gli stati.
    func testTheInvariants() {
        for muted in bools {
            for missing in bools {
                for memory in [nil, false, true] as [Bool?] {
                    let state = OutputSilenceState(muted: muted, missing: missing, lastOutputExternal: memory)
                    XCTAssertEqual(OutputRouteDecision.volumeInvariantHolds(playerRole: .follower, state: state), !(missing && !muted))
                    XCTAssertTrue(OutputRouteDecision.volumeInvariantHolds(playerRole: .direttore, state: state))
                    XCTAssertTrue(OutputRouteDecision.volumeInvariantHolds(playerRole: .solo, state: state))
                    for running in bools {
                        XCTAssertEqual(OutputRouteDecision.engineInvariantHolds(playerRole: .direttore, engineRunning: running, state: state),
                                       !(missing && running))
                        XCTAssertTrue(OutputRouteDecision.engineInvariantHolds(playerRole: .follower, engineRunning: running, state: state))
                        XCTAssertTrue(OutputRouteDecision.engineInvariantHolds(playerRole: .solo, engineRunning: running, state: state))
                    }
                    // Il volume che `start()` scrive rispetta l'invariante del Follower per costruzione.
                    let afterStart = OutputRouteDecision.volumeForStart(playerRole: .follower, state: state) == 0.0
                        ? OutputRouteDecision.state(after: .silenced, from: state, playerRole: .follower)
                        : OutputRouteDecision.state(after: .volumeRestored(externalPresent: false), from: state, playerRole: .follower)
                    XCTAssertTrue(OutputRouteDecision.volumeInvariantHolds(playerRole: .follower, state: afterStart))
                }
            }
        }
    }

    // MARK: - A421 · SEGUITO 1 (par. 4.3): l'apertura dello show

    /// L'apertura dello show azzera la sola memoria dell'ultima uscita: «uscita mancante» e «uscita zittita» restano, per
    /// ogni ruolo. Così il primo avvio di ogni show è come oggi: un click a volume 1 dalle cuffie fra due show (nel Solo) e poi
    /// START SHOW come Follower senza cuffie non alza «uscita mancante» alla rilettura dell'avvio; dentro lo show la memoria
    /// «esterna» del Direttore passa al Follower con il cambio di ruolo e la rilettura alza «uscita mancante».
    func testTheShowOpenResetsOnlyTheMemory() {
        for role in roles {
            for muted in bools {
                for missing in bools {
                    for memory in [nil, false, true] as [Bool?] {
                        let before = OutputSilenceState(muted: muted, missing: missing, lastOutputExternal: memory)
                        let after = OutputRouteDecision.state(after: .showOpened(playingOutputExternal: nil), from: before, playerRole: role)
                        XCTAssertEqual(after.muted, muted, "\(role)")
                        XCTAssertEqual(after.missing, missing, "\(role)")
                        XCTAssertNil(after.lastOutputExternal, "\(role)")
                        // A421 · SEGUITO 2 (E.7): col motore in moto e il volume a 1 la memoria prende l'uscita di adesso.
                        for playing in [false, true] {
                            let playingAfter = OutputRouteDecision.state(after: .showOpened(playingOutputExternal: playing), from: before,
                                                                         playerRole: role)
                            XCTAssertEqual(playingAfter.lastOutputExternal, playing, "\(role)")
                            XCTAssertEqual(playingAfter.muted, muted, "\(role)")
                            XCTAssertEqual(playingAfter.missing, missing, "\(role)")
                        }
                    }
                }
            }
        }
        // Fra due show: il Solo suona nelle cuffie, lo show si apre, il Follower parte senza cuffie: come oggi.
        var between = OutputRouteDecision.state(after: .volumeRestored(externalPresent: true), from: .initial, playerRole: .solo)
        between = OutputRouteDecision.state(after: .roleChange, from: between, playerRole: .solo)
        XCTAssertEqual(between.lastOutputExternal, true, "il cambio di ruolo tiene la memoria")
        between = OutputRouteDecision.state(after: .showOpened(playingOutputExternal: nil), from: between, playerRole: .follower)
        between = OutputRouteDecision.state(after: .recoveryRead(externalPresent: false), from: between, playerRole: .follower)
        XCTAssertFalse(between.missing, "il primo avvio dello show e' come oggi")
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .follower, state: between), 1.0)
        // E.7: START SHOW a click in moto in cuffia: la memoria dice esterna, e lo stacco dopo alza «uscita mancante».
        var inCuffia = OutputRouteDecision.state(after: .showOpened(playingOutputExternal: true), from: .initial, playerRole: .follower)
        XCTAssertEqual(inCuffia.lastOutputExternal, true)
        inCuffia = OutputRouteDecision.state(after: .recoveryRead(externalPresent: false), from: inCuffia, playerRole: .follower)
        XCTAssertTrue(inCuffia.missing)
        // Dentro lo show: il Direttore nelle cuffie, Stop, tolta a click fermo, il ruolo passa a Follower, l'avvio senza cuffie.
        var inside = OutputRouteDecision.state(after: .showOpened(playingOutputExternal: nil), from: .initial, playerRole: .direttore)
        inside = OutputRouteDecision.state(after: .volumeRestored(externalPresent: true), from: inside, playerRole: .direttore)
        inside = OutputRouteDecision.state(after: .directorStop, from: inside, playerRole: .direttore)
        inside = OutputRouteDecision.state(after: .roleChange, from: inside, playerRole: .direttore)
        inside = OutputRouteDecision.state(after: .recoveryRead(externalPresent: false), from: inside, playerRole: .follower)
        XCTAssertTrue(inside.missing, "la memoria esterna dello show alza «uscita mancante» all'avvio del Follower")
        XCTAssertEqual(OutputRouteDecision.volumeForStart(playerRole: .follower, state: inside), 0.0)
    }
}
