import Foundation

// === A435 (16/11/2026) — IL TAP TEMPO DEL PEDALE A CANZONE IN CORSO ===
// Mandato A435, par. 2.2; LIBRO_MASTRO, la riga «a canzone in corso il Direttore solo Stop» con la marcatura
// dell'08/11/2026 sul tap tempo; VERIFICA_REFEREE_A424 par. 3.3. La regola: col DIRETTORE e la canzone in corso il
// pedale tap tempo non fa niente (un tocco cambierebbe il tempo a tutta la band a metà canzone); a click fermo fa
// quello che fa oggi. Il SOLO come oggi, in canzone e fermo (la decisione del 04/11 è per il Direttore). Il FOLLOWER
// come oggi: il suo pedale è già ignorato dalla guardia A360/A361 di `AudioEngine.executeMIDIAction`, prima di
// arrivare al tap.
// «Canzone in corso» è quella del motore (`_songInProgressQ`): la consegna la coda di `AudioEngine`, letta nel momento
// del tocco. Il Direttore muto in canzone è in canzone: il silenzio entra nella regola per essere ignorato, e il banco
// lo prova.
// ⚠️ CORRETTO A435 (16/11/2026; seguito 2 di A435, par. 2 a), c'era «il silenzio entra nella regola per essere ignorato, e
// il banco lo prova»: il banco SCRIVE il caso, non lo prova (`decide` non legge `directorSilent`: nessuna riga tolta lo
// farebbe cadere). La regola vera è che «canzone in corso» resta alta col Direttore muto in canzone (nessuno dei sette
// scrittori di `_songInProgressQ` sta sulla strada del muto in canzone), e la prova è al collaudo (C16). L'ingresso resta.
// Regola pura, solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro (Costituzione V6, par. 4:
// nessuna decisione nel callback di render; qui si decide sul principale, al tocco).
enum TapTempoPedalOutcome: String, Equatable {
    /// Il tap agisce: `tapTempo()`.
    case taps
    /// Direttore, canzone in corso: niente, e una riga.
    case ignoredSongInProgress
    /// Follower: niente (la guardia A360/A361 lo ferma prima).
    case ignoredFollower
}

enum TapTempoPedalDecision {

    /// Solo col Direttore la regola legge «canzone in corso»: per gli altri ruoli chi chiama non la deve leggere
    /// (nel motore è una lettura sincrona sulla coda, che si fa solo quando serve).
    static func readsSongInProgress(role: PlayerRole) -> Bool {
        role == .direttore
    }

    /// `songInProgress`: «canzone in corso» del motore. `directorSilent`: il Direttore è muto (cuffie tolte o
    /// aggiunte, buco del suono): non cambia l'esito.
    static func decide(role: PlayerRole, songInProgress: Bool, directorSilent: Bool) -> TapTempoPedalOutcome {
        switch role {
        case .follower:
            return .ignoredFollower
        case .solo:
            return .taps
        case .direttore:
            return songInProgress ? .ignoredSongInProgress : .taps
        }
    }

    /// Il tap fa fare davvero qualcosa all'app: è l'ingresso della spia (`MIDILampDecision`).
    static func acts(_ outcome: TapTempoPedalOutcome) -> Bool {
        outcome == .taps
    }
}
