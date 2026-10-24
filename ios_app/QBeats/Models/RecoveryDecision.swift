import Foundation

// === A412 (18/10/2026) — DIRETTORE IN CRISI, PASSO 2: LE RIPARTENZE AUTOMATICHE, UNA REGOLA SOLA ===
// Il fatto (referto A409, §4.1, §7.3 e §8.9; referto A410, Aperto 4). Il motore riparte da solo da
// dieci strade (fine interruzione, ripresa pendente, reti di sicurezza, tentativi ripetuti, cambio di
// configurazione, di frequenza, di modo, risveglio), tutte attraverso `activateSessionAndStart` →
// `start(resumeAtBeat:)`. Oggi nessuna chiede chi sta suonando né perché si era fermato: il Direttore
// ripartiva dalla battuta 1 della sezione e spostava la griglia di tutti; il Solo ripartiva da solo
// contro LIBRO 2026-08-30 ③ (attiva per il Solo); e una ripresa rimasta in sospeso faceva ripartire il
// click anche dopo uno Stop voluto (automatismo cieco, LIBRO 2026-10-02).
//
// La regola (mandato del referee «DIRETTORE-IN-CRISI-PASSO-2», §2.6, nell'ordine):
//  · Follower: come oggi (il suo rientro esatto è dei passi 2B e 2C; mandato, Divieti);
//  · uno Stop voluto dopo la crisi: niente;
//  · Direttore muto in canzone: il coordinatore (`DirectorRejoinDecision`, mandato §2.2);
//  · Solo dopo una crisi della sessione audio (interruzione, Lost, reset), ripresa pendente compresa:
//    niente, riparte col Play (mandato §2.7);
//  · tutto il resto: come oggi.
// L'innesco entra per il registro e per il banco: l'esito non dipende da lui (il banco lo prova). I
// tentativi ripetuti portano l'innesco della chiamata d'origine; la rete a 5 s ha il suo.
// In più la fine dell'interruzione senza `shouldResume` (referto A410, Aperto 4): rialzava la ripresa
// pendente e la sua rete di sicurezza anche senza un'interruzione attiva e dopo uno Stop voluto; ora la
// rialza solo con un'interruzione attiva e nessuno Stop voluto dopo la crisi.
// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2 (mandato, par. 2.1 U4, U5, U6, U7, par. 2.2 a) ===
//  · tre inneschi nuovi: `outputAdded` (il ritorno del Direttore dopo le cuffie, U6), `renderGap` (il ritorno
//    dopo la crisi da misuratore, U7), `engineStoppedBySystem` (la rete del motore fermo dal sistema, par.
//    2.2 a). Come gli altri: l'esito non dipende dall'innesco;
//  · un ingresso nuovo, «uscita mancante» (U5, `OutputRouteDecision`): il Direttore con l'uscita mancante
//    (muto in canzone, o fermo fuori da una canzone) ⇒ niente, per ogni innesco, compresa la ripresa pendente
//    che recupera il gestore del percorso. Il Play del batterista non passa di qui (D2);
//  · il Solo: niente dopo una causa che lo ferma (`CrisisCause.stopsSolo`: le crisi della sessione audio e
//    «uscita-tolta»), al posto di `isAudioSessionCrisis`.
// L'ordine della regola: Follower come oggi; uno Stop voluto; il Direttore con l'uscita mancante; il
// Direttore muto in canzone al coordinatore; il Solo dopo una causa che lo ferma; tutto il resto come oggi.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Gli inneschi delle ripartenze automatiche (referto A409 §4.1), col nome che il motore scrive già
/// nelle righe [RESUME].
enum RecoveryTrigger: String, CaseIterable, Equatable {
    case interruptionEnded = "interruption_ended"
    case pendingRecovery = "pending_recovery"
    case safetyNetNoResume = "safety_net_noresume"
    case safetyNet = "safety_net"
    case engineConfigChange = "engine_config_change"
    case sampleRateChange = "sample_rate_change"
    case modeChange = "mode_change"
    case wakeupPendingRecovery = "wakeup_pending_recovery"
    case appWakeup = "app_wakeup"
    // A421 — il ritorno del Direttore dopo le cuffie (U6), dopo il buco del render (U7), e la rete del
    // motore fermo dal sistema (par. 2.2 a).
    case outputAdded = "uscita_aggiunta"
    case renderGap = "buco_del_render"
    case engineStoppedBySystem = "motore_fermo_dal_sistema"
}

/// A421 — perché una ripartenza automatica è «niente» (per la riga e per il motore, che all'uscita mancante
/// abbassa l'interruzione e ripubblica il tasto: mandato U5).
enum NoRestartReason: String, Equatable {
    case wantedStop = "stop-voluto"
    case outputMissing = "uscita-mancante"
    case soloAfterCrisis = "solo-dopo-la-crisi"
}

/// Dove va una ripartenza automatica.
enum RecoveryRoute: String, Equatable {
    /// Il coordinatore del rientro del Direttore (passa da `start()`, che col Direttore muto in
    /// canzone non prende mai il ramo fresco).
    case coordinator = "coordinatore"
    /// `start(resumeAtBeat:)` come oggi.
    case startAsToday = "avvio-come-oggi"
    /// Nessuna ripartenza.
    case noRestart = "niente"
}

enum RecoveryDecision {

    /// La regola. `crisisCause`: la causa dell'ultima crisi (`nil` = nessuna dall'ultimo avvio). `outputMissing`:
    /// «uscita mancante» (A421, U5; il valore di default è per i chiamanti di prima e il banco di A412).
    static func route(trigger: RecoveryTrigger,
                      playerRole: PlayerRole,
                      silentInSong: Bool,
                      wantedStopSinceCrisis: Bool,
                      crisisCause: CrisisCause?,
                      outputMissing: Bool = false) -> RecoveryRoute {
        if playerRole == .follower { return .startAsToday }
        if wantedStopSinceCrisis { return .noRestart }
        if playerRole == .direttore && outputMissing { return .noRestart }
        if playerRole == .direttore && silentInSong { return .coordinator }
        if playerRole == .solo, let cause = crisisCause, cause.stopsSolo { return .noRestart }
        return .startAsToday
    }

    /// A421 — il motivo di un esito «niente», nell'ordine della regola; `nil` se l'esito non è «niente».
    static func noRestartReason(trigger: RecoveryTrigger,
                                playerRole: PlayerRole,
                                silentInSong: Bool,
                                wantedStopSinceCrisis: Bool,
                                crisisCause: CrisisCause?,
                                outputMissing: Bool) -> NoRestartReason? {
        guard route(trigger: trigger, playerRole: playerRole, silentInSong: silentInSong,
                    wantedStopSinceCrisis: wantedStopSinceCrisis, crisisCause: crisisCause,
                    outputMissing: outputMissing) == .noRestart else { return nil }
        if wantedStopSinceCrisis { return .wantedStop }
        if playerRole == .direttore && outputMissing { return .outputMissing }
        return .soloAfterCrisis
    }

    /// La fine dell'interruzione senza `shouldResume` rialza la ripresa pendente (e la sua rete di
    /// sicurezza a 1 s) solo con un'interruzione attiva e nessuno Stop voluto dopo la crisi.
    static func raisesPendingOnEndedWithoutResume(interruptionActive: Bool,
                                                  wantedStopSinceCrisis: Bool) -> Bool {
        interruptionActive && !wantedStopSinceCrisis
    }
}
