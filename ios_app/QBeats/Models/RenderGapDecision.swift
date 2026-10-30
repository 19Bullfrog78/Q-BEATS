import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: IL BUCO DEL RENDER DIVENTA UNA CRISI (U7, U8) ===
// Il fatto (referto A419, §3.2; collaudo del 24/10). Il misuratore (`RenderGapMeter`, A416) vede un buco alla prima chiamata
// di `scheduleNextBuffer` dopo la ripresa del render, quando almeno un buffer è già passato al rendering; fino ad A420 la
// riga `[RENDER]` e basta, e sul Direttore il buffer del buco faceva l'assert e spostava la band (19/10: 1,4371 battiti;
// 24/10: 1,5253). I buchi misurati: sul Direttore e nel Solo solo con un cambio di percorso (108-906 ms); sul Follower
// senza (32,2-48,8 ms).
//
// La regola di A421 (mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.1 U7 e U8; referto A419, §3.2.b e §3.2.c (iii)): la
// crisi da misuratore, a 75 ms, solo per il Direttore a show aperto con la canzone in corso e il motore in moto; sotto la
// soglia in canzone, e fuori da una canzone per ogni buco sopra la soglia della riga, il Direttore segue Link fino al Play
// dopo; Follower e Solo: la riga e basta.
//
// === A421 · SEGUITO 2 (30/10/2026) — LA «B» DI MAURO: IL DIRETTORE VA AVANTI, MAI AUDIO VECCHIO (mandato, par. 4) ===
// Il fatto (par. 4.1). L'iPad Direttore col Centro di Controllo (29/10): 29 buchi senza notizia da 33,2 a 116,5 ms, tre crisi
// da misuratore (83,4 · 98,6 · 116,5) con un silenzio fino alla battuta dopo (0,7-1,3 s). Il 30/10 allo stacco del cavo il
// misuratore è arrivato PRIMA della notizia (119,3 ms, la tolta 1 ms dopo; lo stesso a due stacchi del 28/10: 112,4 e
// 118,0): la premessa di U3 («la notizia arriva col render già fermo») non vale sempre. Decisione di Mauro del 30/10 («1. B»,
// «confermo la B»): col suono che inciampa il click del Direttore va avanti, al più un colpo si conta e non si suona, mai
// un click in ritardo. Le regole (par. 4.3), per il Direttore a show aperto, con la canzone in corso e il motore in moto:
//  · la crisi (com'era, U7) alla chiamata del buco se il buco arriva alla soglia min(150 ms, mezzo battito al tempo del motore
//    meno tre buffer del lettore meno P) — `RenderGapMeter.crisisThresholdSeconds(bpm:…)`; P è la proiezione della correzione
//    di fase quando il Direttore non segue ancora Link, zero se lo segue; crisi anche nella scorta muta del rientro (lì la
//    correzione gira una volta sola, e la prima, col buco dentro, può scavalcare l'«uno»), e se l'uscita esterna da cui usciva il
//    click non c'è più (la memoria di U5 dice esterna e il percorso di adesso no: un cambio d'uscita la cui notizia non è
//    ancora arrivata), in canzone o fuori, a ogni buco sopra la soglia della riga;
//  · sotto la soglia: segue Link (U8, com'era sotto i 75 ms) e il ritorno dopo il buco (`OutputReturnDecision`, il volume torna
//    alla prima chiamata col primo campione a volume 1 alla scadenza o dopo, senza aspettare l'«uno»);
//  · nella finestra «sync skip» (i 100 buffer dopo un cambio di sezione o di tempo, dove non gira nessuna correzione) i ritardi
//    si sommano: a ogni buco, e alla prima chiamata dopo la finestra, con la soglia si confronta la salita dello scarto del
//    misuratore dall'ultima chiamata prima della finestra (coi buchi già visti e i pezzi messi nella base), e la soglia ha P se
//    all'apertura della finestra il Direttore non seguiva ancora Link: alla soglia la crisi (motivo «finestra»); sotto, il
//    click tace fino alla prima correzione dopo la finestra, mai in ritardo.
// Direttore fuori da una canzone con l'uscita di prima: segue Link (U8) e il ritorno dopo il buco. Follower: la riga e il
// ritorno dopo il buco. Solo (anche il Direttore con Link spento): la riga e basta, niente guardiano e niente ritorno (il Solo
// non segue una griglia: dopo il buco va avanti da dov'era).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// L'esito, col nome che va nella riga `[RENDER] … -> esito:`.
enum RenderGapOutcome: String, Equatable, CaseIterable {
    case lineOnly = "solo-riga"
    case followLink = "segue-link"
    case crisis = "crisi"
}

/// A421 · SEGUITO 2 — perché la crisi, col nome che va nella riga `crisi da misuratore … motivo:`.
enum RenderGapCrisisReason: String, Equatable, CaseIterable {
    /// Il buco arriva alla soglia.
    case hole = "buco"
    /// Un buco nella scorta muta del rientro.
    case leadIn = "scorta"
    /// L'uscita esterna da cui usciva il click non c'è più (la notizia della tolta non è ancora arrivata).
    case outputVanished = "uscita-sparita"
    /// La salita dello scarto nella finestra «sync skip» arriva alla soglia.
    case window = "finestra"
}

/// A421 · SEGUITO 2 — il verdetto: l'esito, il motivo della crisi (solo con `.crisis`) e la soglia usata (solo per il Direttore
/// in canzone col motore in moto; `nil` dove la soglia non entra).
struct RenderGapVerdict: Equatable {
    let outcome: RenderGapOutcome
    let crisisReason: RenderGapCrisisReason?
    let thresholdSeconds: Double?

    static let lineOnly = RenderGapVerdict(outcome: .lineOnly, crisisReason: nil, thresholdSeconds: nil)
    static let followLink = RenderGapVerdict(outcome: .followLink, crisisReason: nil, thresholdSeconds: nil)
}

enum RenderGapDecision {

    /// Quello che il motore sa alla chiamata del buco, su audioQueue.
    struct Situation: Equatable {
        /// Il buco stimato dal misuratore (scarto meno base), già sopra la soglia della riga.
        let holeSeconds: Double
        let playerRole: PlayerRole
        let showOpen: Bool
        let songInProgress: Bool
        let engineRunning: Bool
        /// Il Direttore segue già Link (dopo un rientro o un buco di prima): P vale zero.
        let followsLink: Bool
        /// La scorta muta del rientro è viva (`_rejoinLeadInQ`).
        let inLeadIn: Bool
        /// La memoria di U5 dice esterna e il percorso di adesso non ha un'uscita esterna (letto alla chiamata del buco).
        let externalVanished: Bool
        /// La finestra «sync skip» era aperta all'inizio della chiamata (il contatore maggiore di zero).
        let windowOpen: Bool
        /// Nella finestra: la salita dello scarto del misuratore dall'ultima chiamata prima della finestra. `nil` senza una
        /// misura (la finestra aperta prima del riferimento).
        let windowRiseSeconds: Double?
        /// P all'apertura della finestra (zero se allora il Direttore seguiva già Link).
        let windowProjectionSeconds: Double
        /// Il tempo del motore (`_engineTempoQ`), il buffer del lettore e la frequenza dei nodi, per la soglia.
        let bpm: Double
        let bufferFrames: Int
        let sampleRate: Double
        /// P adesso: latenza d'uscita più ciclo d'uscita (la proiezione della convenzione), prima che `followsLink` lo azzeri.
        let projectionSeconds: Double
    }

    /// La regola (par. 4.3). L'ordine è la precedenza: chi non è il Direttore col motore in moto solo la riga; l'uscita sparita
    /// (in canzone o fuori); fuori da una canzone segue Link; in canzone la scorta, poi la finestra, poi il buco contro la soglia.
    static func verdict(_ s: Situation) -> RenderGapVerdict {
        guard s.playerRole == .direttore, s.engineRunning else { return .lineOnly }
        if s.externalVanished {
            return RenderGapVerdict(outcome: .crisis, crisisReason: .outputVanished, thresholdSeconds: nil)
        }
        let inSong = s.showOpen && s.songInProgress
        guard inSong else { return .followLink }
        let threshold = RenderGapMeter.crisisThresholdSeconds(bpm: s.bpm, bufferFrames: s.bufferFrames, sampleRate: s.sampleRate,
                                                              projectionSeconds: s.followsLink ? 0 : s.projectionSeconds)
        if s.inLeadIn {
            return RenderGapVerdict(outcome: .crisis, crisisReason: .leadIn, thresholdSeconds: threshold)
        }
        if s.windowOpen {
            let windowThreshold = RenderGapMeter.crisisThresholdSeconds(bpm: s.bpm, bufferFrames: s.bufferFrames,
                                                                        sampleRate: s.sampleRate,
                                                                        projectionSeconds: s.windowProjectionSeconds)
            // Correzione B3 del verificatore: senza una misura della salita (la finestra aperta prima del riferimento) conta il buco.
            let rise: Double = {
                if let measured = s.windowRiseSeconds, measured.isFinite { return measured }
                return s.holeSeconds
            }()
            if rise.isFinite, rise >= windowThreshold {
                return RenderGapVerdict(outcome: .crisis, crisisReason: .window, thresholdSeconds: windowThreshold)
            }
            return RenderGapVerdict(outcome: .followLink, crisisReason: nil, thresholdSeconds: windowThreshold)
        }
        guard s.holeSeconds.isFinite, s.holeSeconds >= threshold else {
            return RenderGapVerdict(outcome: .followLink, crisisReason: nil, thresholdSeconds: threshold)
        }
        return RenderGapVerdict(outcome: .crisis, crisisReason: .hole, thresholdSeconds: threshold)
    }

    /// Par. 4.3 — la prima chiamata dopo la finestra, prima della correzione: la stessa misura della salita contro la soglia (con
    /// P se all'apertura della finestra il Direttore non seguiva ancora Link). Alla soglia la crisi (motivo «finestra», la
    /// correzione non si applica); sotto `nil`: niente crisi, il ritorno aspetta la prima correzione dopo la finestra. Solo per
    /// il Direttore a show aperto con la canzone in corso e il motore in moto.
    static func windowCloseVerdict(riseSeconds: Double?,
                                   playerRole: PlayerRole,
                                   showOpen: Bool,
                                   songInProgress: Bool,
                                   engineRunning: Bool,
                                   bpm: Double,
                                   bufferFrames: Int,
                                   sampleRate: Double,
                                   windowProjectionSeconds: Double) -> RenderGapVerdict? {
        guard playerRole == .direttore, engineRunning, showOpen, songInProgress,
              let rise = riseSeconds, rise.isFinite else { return nil }
        let threshold = RenderGapMeter.crisisThresholdSeconds(bpm: bpm, bufferFrames: bufferFrames, sampleRate: sampleRate,
                                                              projectionSeconds: windowProjectionSeconds)
        guard rise >= threshold else { return nil }
        return RenderGapVerdict(outcome: .crisis, crisisReason: .window, thresholdSeconds: threshold)
    }

    /// Par. 4.2, 4.4 — il guardiano e il ritorno dopo il buco sono per il Direttore e il Follower; il Solo (anche il Direttore
    /// con Link spento) no.
    static func guardsAgainstHoles(playerRole: PlayerRole) -> Bool {
        playerRole != .solo
    }

    /// L'innesco nella riga `[DIR-RIENTRO] segue Link innesco:…` quando l'esito è `followLink`.
    static func followLinkTrigger(showOpen: Bool, songInProgress: Bool) -> String {
        (showOpen && songInProgress) ? "buco-piccolo" : "buco-fuori-canzone"
    }
}
