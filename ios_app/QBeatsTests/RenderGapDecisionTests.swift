import XCTest

// === A421 — banco della crisi da misuratore (`RenderGapDecision`, banco Models), mandato par. 2.1 U7 e U8 ===
// I 19 buchi del referto A419 (par. 3.2.b) e i cinque del 24/10 (906,1 · 835,4 · 783,7 · 254,5 · 108,8 ms), col ruolo che
// avevano; il Direttore che segue già Link; fuori da una canzone; Follower e Solo solo riga; la matrice.
// === A421 · SEGUITO 2 (30/10/2026) — la «B» di Mauro (mandato, par. 4.3, 4.7) ===
// La soglia al tempo del motore, min(150 ms, mezzo battito meno tre buffer meno P), a 121, 165, 180, 200 e 240 BPM, a 48 e
// a 44,1 kHz, con P zero, 13,4, 23,3 e 123 ms, col Direttore che segue già Link o no; i buchi 33,2 · 116,5 · 119,3 · 149 · 151
// ms; la scorta; l'uscita esterna presente e sparita; la finestra «sync skip»; la cassa del 29/10 col primo buco dopo il Play
// di 130 ms (crisi: senza P la prima correzione sarebbe di 0,51 battiti); il buco di 70,0 ms del 29/10 (segue Link). Le
// asserzioni di A421 sulla soglia di 75 ms (testTheThreshold, testTheDirectorThatFollowsLinkStillGoesIntoCrisis,
// testBelowTheThresholdTheDirectorFollowsLink e la matrice; testTheSilentDirectorWithTheEngineRunning tolto: ripeteva la regola) sono riscritte qui
// sulla soglia nuova, col motivo nel referto.

final class RenderGapDecisionTests: XCTestCase {

    private let roles: [PlayerRole] = [.solo, .direttore, .follower]
    private let bools = [false, true]

    private func situation(_ holeMs: Double, _ role: PlayerRole, show: Bool = true, song: Bool = true, running: Bool = true,
                           follows: Bool = false, leadIn: Bool = false, vanished: Bool = false, windowOpen: Bool = false,
                           windowRiseMs: Double? = nil, windowP: Double = 0, bpm: Double = 121, frames: Int = 512,
                           rate: Double = 48_000, projectionMs: Double = 23.3) -> RenderGapDecision.Situation {
        RenderGapDecision.Situation(holeSeconds: holeMs / 1000.0, playerRole: role, showOpen: show, songInProgress: song,
                                    engineRunning: running, followsLink: follows, inLeadIn: leadIn, externalVanished: vanished,
                                    windowOpen: windowOpen, windowRiseSeconds: windowRiseMs.map { $0 / 1000.0 },
                                    windowProjectionSeconds: windowP / 1000.0, bpm: bpm, bufferFrames: frames, sampleRate: rate,
                                    projectionSeconds: projectionMs / 1000.0)
    }

    private func outcome(_ holeMs: Double, _ role: PlayerRole, show: Bool = true, song: Bool = true, running: Bool = true,
                         follows: Bool = false, bpm: Double = 121, projectionMs: Double = 23.3) -> RenderGapOutcome {
        RenderGapDecision.verdict(situation(holeMs, role, show: show, song: song, running: running, follows: follows, bpm: bpm,
                                            projectionMs: projectionMs)).outcome
    }

    private func thresholdMs(bpm: Double, rate: Double = 48_000, pMs: Double = 0) -> Double {
        RenderGapMeter.crisisThresholdSeconds(bpm: bpm, bufferFrames: 512, sampleRate: rate, projectionSeconds: pMs / 1000.0) * 1000.0
    }

    // MARK: - La soglia (par. 4.3)

    /// Il tetto passa da 75 a 150 ms; la soglia della riga resta a tre buffer.
    func testTheThresholdCeilingIs150ms() {
        XCTAssertEqual(RenderGapMeter.crisisThresholdSeconds, 0.150)
        XCTAssertEqual(RenderGapMeter.thresholdBuffers, 3, "la soglia della riga resta a tre buffer")
        // Col Direttore che segue già Link a 121 BPM: 150 ms è la soglia; 149 segue Link, 151 crisi.
        XCTAssertEqual(outcome(149.0, .direttore, follows: true), .followLink)
        XCTAssertEqual(outcome(150.0, .direttore, follows: true), .crisis)
        XCTAssertEqual(outcome(151.0, .direttore, follows: true), .crisis)
    }

    /// min(150 ms, mezzo battito meno tre buffer meno P): i numeri del mandato (par. 4.3), a 48 e a 44,1 kHz.
    func testTheThresholdAtTheTempo() {
        // Col Direttore che segue già Link (P zero): 150 fino a circa 165 BPM a 48 kHz (162 a 44,1).
        XCTAssertEqual(thresholdMs(bpm: 121), 150.0, accuracy: 0.01)
        XCTAssertEqual(thresholdMs(bpm: 164), 150.0, accuracy: 0.01)
        XCTAssertLessThan(thresholdMs(bpm: 166), 150.0)
        XCTAssertEqual(thresholdMs(bpm: 180), 134.7, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 200), 118.0, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 240), 93.0, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 162, rate: 44_100), 150.0, accuracy: 0.01)
        XCTAssertLessThan(thresholdMs(bpm: 163, rate: 44_100), 150.0)
        XCTAssertEqual(thresholdMs(bpm: 180, rate: 44_100), 131.8, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 200, rate: 44_100), 115.2, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 240, rate: 44_100), 90.2, accuracy: 0.1)
        // Al primo buco dopo il Play, con P: a 121 BPM 150 con le cuffie (13,4), con l'altoparlante (23,3) e con l'iPad sotto i
        // 44 ms di latenza (21,33 + 44 = 65,3); circa 90 con la cassa Bluetooth (123); a 180 BPM 121,3 con le cuffie, 111,4 con
        // l'altoparlante.
        XCTAssertEqual(thresholdMs(bpm: 121, pMs: 13.4), 150.0, accuracy: 0.01)
        XCTAssertEqual(thresholdMs(bpm: 121, pMs: 23.3), 150.0, accuracy: 0.01)
        XCTAssertEqual(thresholdMs(bpm: 121, pMs: 21.33 + 44.0), 150.0, accuracy: 0.1)
        XCTAssertLessThan(thresholdMs(bpm: 121, pMs: 21.33 + 46.0), 150.0)
        XCTAssertEqual(thresholdMs(bpm: 121, pMs: 123.0), 92.9, accuracy: 0.2)
        XCTAssertEqual(thresholdMs(bpm: 180, pMs: 13.4), 121.3, accuracy: 0.1)
        XCTAssertEqual(thresholdMs(bpm: 180, pMs: 23.3), 111.4, accuracy: 0.1)
        // Valori non validi: il tetto; mai sotto zero.
        XCTAssertEqual(thresholdMs(bpm: 0), 150.0)
        XCTAssertEqual(thresholdMs(bpm: .nan), 150.0)
        XCTAssertEqual(RenderGapMeter.crisisThresholdSeconds(bpm: 121, bufferFrames: 0, sampleRate: 48_000, projectionSeconds: 0), 0.150)
        XCTAssertEqual(RenderGapMeter.crisisThresholdSeconds(bpm: 121, bufferFrames: 512, sampleRate: 0, projectionSeconds: 0), 0.150)
        XCTAssertEqual(thresholdMs(bpm: 600, pMs: 100), 0)
        XCTAssertEqual(thresholdMs(bpm: 121, pMs: -5), 150.0, "una P negativa vale zero")
    }

    // MARK: - I buchi misurati

    /// I 19 buchi del referto A419, par. 3.2.b, col ruolo del registro.
    func testTheNineteenHolesOfA419() {
        // Solo: R1 121,5 (tolta), R5 218,7 (aggiunta) e 108,0 (tolta): solo riga (la crisi del Solo arriva dalla notizia).
        for ms in [121.5, 218.7, 108.0] {
            XCTAssertEqual(outcome(ms, .solo), .lineOnly, "\(ms)")
        }
        // Direttore in canzone: R2 155,2 e 187,5; R4 circa 791 e 803 (19/10): crisi anche con la soglia a 150.
        for ms in [155.2, 187.5, 791.0, 803.0] {
            XCTAssertEqual(outcome(ms, .direttore), .crisis, "\(ms)")
        }
        // Follower senza notizia: R7 32,6 · 42,0; R6 34,3 · 33,7 · 41,1; R8 36,5 · 48,8 · 32,8 · 34,3 · 45,7 · 32,9 · 32,2: solo riga.
        for ms in [32.6, 42.0, 34.3, 33.7, 41.1, 36.5, 48.8, 32.8, 34.3, 45.7, 32.9, 32.2] {
            XCTAssertEqual(outcome(ms, .follower), .lineOnly, "\(ms)")
        }
    }

    /// I cinque buchi del 24/10: 906,1 sul Direttore (la cassa Bluetooth: crisi, è il caso dell'assert di 1,5253 battiti);
    /// 835,4 e 783,7 nel Solo (le cuffie col filo), 254,5 e 108,8 nel Solo (la cassa): solo riga. Sul Direttore in canzone
    /// sarebbero crisi i quattro sopra i 150 ms; 108,8 (crisi a 75) da qui segue Link.
    func testTheFiveHolesOfOctober24() {
        XCTAssertEqual(outcome(906.1, .direttore), .crisis)
        for ms in [835.4, 783.7, 254.5, 108.8] {
            XCTAssertEqual(outcome(ms, .solo), .lineOnly, "\(ms)")
        }
        for ms in [906.1, 835.4, 783.7, 254.5] {
            XCTAssertEqual(outcome(ms, .direttore), .crisis, "\(ms)")
        }
        XCTAssertEqual(outcome(108.8, .direttore), .followLink, "sotto i 150 ms: segue Link (la «B»)")
    }

    /// I buchi del seguito 2 (par. 4.7): 33,2 e 116,5 (l'iPad col Centro di Controllo), 119,3 (lo stacco 1 del 30/10 con
    /// l'uscita ancora presente), 149 e 151, sul Direttore in canzone a 121 BPM con l'altoparlante (P 23,3).
    func testTheHolesOfTheSeguito2() {
        for ms in [33.2, 116.5, 119.3, 149.0] {
            XCTAssertEqual(outcome(ms, .direttore), .followLink, "\(ms)")
        }
        XCTAssertEqual(outcome(151.0, .direttore), .crisis)
        XCTAssertEqual(outcome(150.0, .direttore), .crisis)
    }

    /// Il 29/10: il buco di 70,0 ms sul Direttore in canzone (0,1412 battiti a 121), la prima correzione di 0,1883 battiti (il
    /// buco più P di 0,0469): sotto mezzo battito, segue Link. La cassa Bluetooth (P circa 123 ms) col primo buco dopo il Play
    /// di 130 ms: crisi — senza P la prima correzione sarebbe di 0,51 battiti e il DSP rinominerebbe il battito.
    func testTheSeventyMsHoleFollowsLinkAndTheSpeakerWith130msIsACrisis() {
        XCTAssertEqual(outcome(70.0, .direttore), .followLink)
        let correctionBeats = (70.0 + 23.3) / 1000.0 * 121.0 / 60.0
        XCTAssertEqual(correctionBeats, 0.1882, accuracy: 0.001)
        XCTAssertLessThan(correctionBeats, 0.5)
        XCTAssertEqual(outcome(130.0, .direttore, projectionMs: 123.0), .crisis, "la cassa: soglia circa 90 ms")
        XCTAssertEqual((130.0 + 123.0) / 1000.0 * 121.0 / 60.0, 0.51, accuracy: 0.01)
        XCTAssertEqual(outcome(130.0, .direttore, follows: true, projectionMs: 123.0), .followLink, "segue già Link: P zero")
    }

    /// Il Direttore che segue già Link (T4): P vale zero; alla soglia va in crisi come gli altri, sotto segue Link.
    func testTheDirectorThatFollowsLinkUsesNoProjection() {
        XCTAssertEqual(outcome(906.1, .direttore, follows: true), .crisis)
        XCTAssertEqual(outcome(150.0, .direttore, follows: true), .crisis)
        XCTAssertEqual(outcome(48.8, .direttore, follows: true), .followLink)
        XCTAssertEqual(RenderGapDecision.verdict(situation(100.0, .direttore, follows: true)).thresholdSeconds!, 0.150, accuracy: 1e-9)
        XCTAssertEqual(RenderGapDecision.verdict(situation(100.0, .direttore, bpm: 180, projectionMs: 23.3)).thresholdSeconds!,
                       0.1114, accuracy: 0.0002)
    }

    // MARK: - La scorta, l'uscita sparita, la finestra

    /// Nella scorta muta del rientro ogni buco sopra la soglia della riga è una crisi (motivo «scorta»), anche piccolo.
    func testAHoleInTheLeadInIsACrisis() {
        for ms in [33.2, 82.0, 149.0] {
            let verdict = RenderGapDecision.verdict(situation(ms, .direttore, follows: true, leadIn: true))
            XCTAssertEqual(verdict.outcome, .crisis, "\(ms)")
            XCTAssertEqual(verdict.crisisReason, .leadIn, "\(ms)")
        }
        // Fuori da una canzone la scorta non c'è (il rientro è in canzone): segue Link.
        XCTAssertEqual(RenderGapDecision.verdict(situation(82.0, .direttore, song: false, leadIn: true)).outcome, .followLink)
    }

    /// L'uscita esterna da cui usciva il click non c'è più (il misuratore prima della notizia: lo stacco 1 del 30/10, 119,3 ms):
    /// crisi a ogni buco sopra la soglia della riga, in canzone o fuori, motivo «uscita-sparita», senza soglia.
    func testAVanishedExternalOutputIsACrisisInOrOutOfASong() {
        for (show, song) in [(true, true), (true, false), (false, false), (false, true)] {
            for ms in [33.2, 119.3, 906.1] {
                let verdict = RenderGapDecision.verdict(situation(ms, .direttore, show: show, song: song, vanished: true))
                XCTAssertEqual(verdict.outcome, .crisis, "show:\(show) canzone:\(song) \(ms)")
                XCTAssertEqual(verdict.crisisReason, .outputVanished, "show:\(show) canzone:\(song) \(ms)")
                XCTAssertNil(verdict.thresholdSeconds)
            }
        }
        // Follower e Solo: la regola non li ferma (il Follower rilegge U5 al ritorno; il Solo niente).
        XCTAssertEqual(RenderGapDecision.verdict(situation(119.3, .follower, vanished: true)).outcome, .lineOnly)
        XCTAssertEqual(RenderGapDecision.verdict(situation(119.3, .solo, vanished: true)).outcome, .lineOnly)
    }

    /// Nella finestra «sync skip» conta la salita dello scarto dall'apertura, con P dell'apertura: due buchi del Centro di
    /// Controllo a 180,5 BPM, 98,6 e 83,4 ms (182,0 insieme, sopra mezzo battito meno tre buffer: 134,2 ms): la crisi al secondo;
    /// il primo da solo sotto la soglia segue Link; la stessa misura alla chiusura della finestra.
    func testTheWindowSumsTheHoles() {
        let first = RenderGapDecision.verdict(situation(98.6, .direttore, follows: true, windowOpen: true, windowRiseMs: 98.6, bpm: 180.5))
        XCTAssertEqual(first.outcome, .followLink)
        XCTAssertEqual(first.thresholdSeconds!, 0.1342, accuracy: 0.0005)
        let second = RenderGapDecision.verdict(situation(83.4, .direttore, follows: true, windowOpen: true, windowRiseMs: 182.0, bpm: 180.5))
        XCTAssertEqual(second.outcome, .crisis)
        XCTAssertEqual(second.crisisReason, .window)
        // Nella finestra il buco da solo non decide: 151 ms con una salita sotto la soglia segue Link (la salita comprende il buco).
        XCTAssertEqual(RenderGapDecision.verdict(situation(151.0, .direttore, follows: true, windowOpen: true, windowRiseMs: 60.0)).outcome,
                       .followLink, "nella finestra conta la salita, non il buco")
        // Senza una misura della salita (la finestra aperta prima del riferimento) conta il buco: 151 ms e' una crisi, 100 no
        // (correzione B3 del verificatore).
        XCTAssertEqual(RenderGapDecision.verdict(situation(151.0, .direttore, follows: true, windowOpen: true, windowRiseMs: nil)).outcome,
                       .crisis)
        XCTAssertEqual(RenderGapDecision.verdict(situation(100.0, .direttore, follows: true, windowOpen: true, windowRiseMs: nil)).outcome,
                       .followLink, "senza misura, sotto la soglia")
        // P dell'apertura: all'apertura il Direttore non seguiva Link con la cassa (123 ms): a 121 BPM la soglia della finestra è
        // circa 93 ms, e una salita di 100 ms è una crisi anche se adesso segue Link.
        let withP = RenderGapDecision.verdict(situation(60.0, .direttore, follows: true, windowOpen: true, windowRiseMs: 100.0, windowP: 123.0))
        XCTAssertEqual(withP.outcome, .crisis)
        XCTAssertEqual(withP.crisisReason, .window)
        // La chiusura della finestra: la stessa misura, solo per il Direttore in canzone col motore in moto.
        let close = RenderGapDecision.windowCloseVerdict(riseSeconds: 0.182, playerRole: .direttore, showOpen: true, songInProgress: true,
                                                         engineRunning: true, bpm: 180.5, bufferFrames: 512, sampleRate: 48_000,
                                                         windowProjectionSeconds: 0)
        XCTAssertEqual(close?.outcome, .crisis)
        XCTAssertEqual(close?.crisisReason, .window)
        XCTAssertNil(RenderGapDecision.windowCloseVerdict(riseSeconds: 0.0986, playerRole: .direttore, showOpen: true, songInProgress: true,
                                                          engineRunning: true, bpm: 180.5, bufferFrames: 512, sampleRate: 48_000,
                                                          windowProjectionSeconds: 0))
        XCTAssertNil(RenderGapDecision.windowCloseVerdict(riseSeconds: 0.182, playerRole: .follower, showOpen: true, songInProgress: true,
                                                          engineRunning: true, bpm: 180.5, bufferFrames: 512, sampleRate: 48_000,
                                                          windowProjectionSeconds: 0))
        XCTAssertNil(RenderGapDecision.windowCloseVerdict(riseSeconds: 0.182, playerRole: .direttore, showOpen: true, songInProgress: false,
                                                          engineRunning: true, bpm: 180.5, bufferFrames: 512, sampleRate: 48_000,
                                                          windowProjectionSeconds: 0))
        XCTAssertNil(RenderGapDecision.windowCloseVerdict(riseSeconds: nil, playerRole: .direttore, showOpen: true, songInProgress: true,
                                                          engineRunning: true, bpm: 180.5, bufferFrames: 512, sampleRate: 48_000,
                                                          windowProjectionSeconds: 0))
    }

    /// L'ordine: l'uscita sparita prima di tutto; poi fuori da una canzone segue Link anche nella scorta e nella finestra; in
    /// canzone la scorta prima della finestra.
    func testThePrecedence() {
        let vanishedInLeadIn = RenderGapDecision.verdict(situation(82.0, .direttore, leadIn: true, vanished: true))
        XCTAssertEqual(vanishedInLeadIn.crisisReason, .outputVanished)
        let leadInInWindow = RenderGapDecision.verdict(situation(82.0, .direttore, leadIn: true, windowOpen: true, windowRiseMs: 10.0))
        XCTAssertEqual(leadInInWindow.crisisReason, .leadIn)
        XCTAssertEqual(RenderGapDecision.verdict(situation(906.1, .direttore, song: false, windowOpen: true, windowRiseMs: 906.1)).outcome,
                       .followLink)
    }

    // MARK: - Il Direttore muto, fuori da una canzone, Follower e Solo, motore fermo

    /// Sotto la soglia col Direttore in canzone: segue Link (U8, la (iii) del referto A419), fino a 149 ms a 121 BPM.
    func testBelowTheThresholdTheDirectorFollowsLink() {
        for ms in [32.2, 48.8, 60.0, 74.99, 100.0, 149.99] {
            XCTAssertEqual(outcome(ms, .direttore), .followLink, "\(ms)")
        }
        XCTAssertEqual(RenderGapDecision.followLinkTrigger(showOpen: true, songInProgress: true), "buco-piccolo")
    }

    /// Fuori da una canzone (show chiuso, o click senza canzone) con l'uscita di prima: per ogni buco sopra la soglia della riga
    /// segue Link, mai una crisi (lì U7 non c'è).
    func testOutOfASongEveryHoleMakesTheDirectorFollowLink() {
        for (show, song) in [(false, false), (true, false), (false, true)] {
            for ms in [32.2, 150.0, 906.1] {
                XCTAssertEqual(outcome(ms, .direttore, show: show, song: song), .followLink, "show:\(show) canzone:\(song) \(ms)")
            }
            XCTAssertEqual(RenderGapDecision.followLinkTrigger(showOpen: show, songInProgress: song), "buco-fuori-canzone")
        }
    }

    /// Follower e Solo: solo riga, qualunque buco e qualunque stato (il ritorno dopo il buco del Follower lo arma il motore).
    func testFollowerAndSoloAreLineOnly() {
        for role in [PlayerRole.follower, .solo] {
            for ms in [32.2, 150.0, 906.1, 5000.0] {
                for show in bools {
                    for song in bools {
                        for follows in bools {
                            XCTAssertEqual(outcome(ms, role, show: show, song: song, follows: follows), .lineOnly,
                                           "ruolo:\(role) \(ms) show:\(show) canzone:\(song)")
                        }
                    }
                }
            }
        }
        XCTAssertTrue(RenderGapDecision.guardsAgainstHoles(playerRole: .direttore))
        XCTAssertTrue(RenderGapDecision.guardsAgainstHoles(playerRole: .follower))
        XCTAssertFalse(RenderGapDecision.guardsAgainstHoles(playerRole: .solo))
    }

    /// A motore fermo niente (il misuratore non gira: entra per la matrice).
    func testEngineStoppedIsLineOnly() {
        XCTAssertEqual(outcome(906.1, .direttore, running: false), .lineOnly)
        XCTAssertEqual(RenderGapDecision.verdict(situation(906.1, .direttore, running: false, vanished: true)).outcome, .lineOnly)
    }

    // MARK: - La matrice

    private func expected(_ holeMs: Double, _ role: PlayerRole, show: Bool, song: Bool, running: Bool, follows: Bool,
                          bpm: Double, pMs: Double) -> RenderGapOutcome {
        guard role == .direttore, running else { return .lineOnly }
        guard show && song else { return .followLink }
        let threshold = min(150.0, 30_000.0 / bpm - 3.0 * 512.0 / 48.0 - (follows ? 0 : pMs))
        return holeMs >= max(threshold, 0) ? .crisis : .followLink
    }

    func testTheMatrix() {
        var cells = 0
        for ms in [32.2, 110.0, 149.9, 150.0, 906.1] {
            for role in roles {
                for show in bools {
                    for song in bools {
                        for running in bools {
                            for follows in bools {
                                for bpm in [121.0, 180.0, 240.0] {
                                    for pMs in [0.0, 23.3, 123.0] {
                                        cells += 1
                                        let got = RenderGapDecision.verdict(situation(ms, role, show: show, song: song, running: running,
                                                                                      follows: follows, bpm: bpm, projectionMs: pMs))
                                        let tag = "\(ms) ruolo:\(role) show:\(show) canzone:\(song) motore:\(running) segue:\(follows) bpm:\(bpm) P:\(pMs)"
                                        XCTAssertEqual(got.outcome, expected(ms, role, show: show, song: song, running: running,
                                                                             follows: follows, bpm: bpm, pMs: pMs), tag)
                                        if got.outcome == .crisis {
                                            XCTAssertTrue(role == .direttore && show && song && running, tag)
                                            XCTAssertEqual(got.crisisReason, .hole, tag)
                                        } else {
                                            XCTAssertNil(got.crisisReason, tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cells, 5 * 3 * 2 * 2 * 2 * 2 * 3 * 3)
    }

    func testTheNamesInTheLines() {
        XCTAssertEqual(RenderGapOutcome.lineOnly.rawValue, "solo-riga")
        XCTAssertEqual(RenderGapOutcome.followLink.rawValue, "segue-link")
        XCTAssertEqual(RenderGapOutcome.crisis.rawValue, "crisi")
        XCTAssertEqual(RenderGapOutcome.allCases.count, 3)
        XCTAssertEqual(RenderGapCrisisReason.hole.rawValue, "buco")
        XCTAssertEqual(RenderGapCrisisReason.leadIn.rawValue, "scorta")
        XCTAssertEqual(RenderGapCrisisReason.outputVanished.rawValue, "uscita-sparita")
        XCTAssertEqual(RenderGapCrisisReason.window.rawValue, "finestra")
        XCTAssertEqual(RenderGapCrisisReason.allCases.count, 4)
    }
}
