import Foundation

// === A386 · FASE B1 (2D) — LA CANZONE DEL DIRETTORE SI CHIUDE ALLO STOP, TESTATO ===
// D3 (24/09/2026): in modalita' Direttore OGNI porta che ferma il motore a canzone in corso
// chiude la canzone — si riparte solo dall'inizio della successiva — tranne le interruzioni di
// sistema (LIBRO 2026-09-17), che non passano da `stop()`. In Solo tutto invariato.
// D7-bis (24/09/2026): se lo Stop cade entro la prima battuta dal Play (`FalseStartDecision`,
// sui battiti di sessione) la canzone NON si chiude: falsa partenza, si riarma la stessa.
// D4 (24/09/2026): RIENTRA arma qualsiasi canzone della scaletta, anche gia' suonata.
// «Direttore» qui e' ruolo `.direttore` E Link acceso dall'utente: lo specchio di
// `FollowerDecision` (con Link spento dall'utente il ruolo Direttore si comporta da Solo, come
// gia' nel ramo d'avvio, `FreshStartBranchDecision`).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum DirectorSongCloseDecision {

    enum StopOutcome: Equatable {
        /// Chiudi: la successiva si arma (`runner.armNextSong`).
        case closeAndArmNext(songIdx: Int)
        /// Chiudi: era l'ultima (`.fineSetlist`).
        case closeAndFinishSetlist
        /// D7-bis: falsa partenza, riarma la stessa (`runner.armSong(currentSongIdx)`).
        case rearmSame(songIdx: Int)
        /// Solo, Link spento dall'utente, canzone non in corso, indici non validi: niente.
        case none
    }

    enum ArmOutcome: Equatable {
        case arm(songIdx: Int)
        case refuse
    }

    /// La regola nuda: chi chiude la canzone allo Stop.
    static func closesSongOnStop(role: LinkMode, userLinkEnabled: Bool) -> Bool {
        role == .direttore && userLinkEnabled
    }

    /// Allo Stop del motore. `songInProgress`: la sessione era `.playing`, `.countIn` o
    /// `.starting`. `falseStart`: `FalseStartDecision` sui battiti di sessione (D7-bis).
    static func onStop(role: LinkMode,
                       userLinkEnabled: Bool,
                       songInProgress: Bool,
                       falseStart: Bool,
                       currentSongIdx: Int,
                       songCount: Int) -> StopOutcome {
        guard closesSongOnStop(role: role, userLinkEnabled: userLinkEnabled) else { return .none }
        guard songInProgress else { return .none }
        guard songCount > 0, currentSongIdx >= 0, currentSongIdx < songCount else { return .none }
        if falseStart {
            return .rearmSame(songIdx: currentSongIdx)
        }
        if currentSongIdx + 1 < songCount {
            return .closeAndArmNext(songIdx: currentSongIdx + 1)
        }
        return .closeAndFinishSetlist
    }

    /// RIENTRA (D4): qualsiasi indice del catalogo, anche gia' suonato.
    static func armSong(index: Int, songCount: Int) -> ArmOutcome {
        guard songCount > 0, index >= 0, index < songCount else { return .refuse }
        return .arm(songIdx: index)
    }
}
