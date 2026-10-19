import Foundation

// === A412 · SEGUITO 1 (18/10/2026) — IL DIRETTORE RIBATTE IL PROPRIO TEMPO SU LINK SOLO SE SUONA LA SUA LINEA ===
// Il fatto (collaudo di A412 del 18/10/2026, prova P2-bis; registri `QBeats_registro_iPhone_2026-10-18_14-31-48.txt`
// e `QBeats_registro_iPad_2026-10-18_14-31-41.txt`). Dopo Siri l'iPhone Direttore aspettava il rientro col motore
// acceso e muto, da `start()` col bersaglio fino al fuoco. In quei secondi l'iPad, al cambio di sezione, ha scritto
// 110 su Link (W2), e il richiamo del tempo dell'iPhone, ramo del Direttore, ha ribattuto il suo `_audioBPM` (90, la
// sezione di prima) perché il motore era «in moto»: l'iPad ha adottato 90 e ha suonato a 90 la sezione a 110. È il
// difetto del referto A409 §4.3 («il Direttore ripartito impone alla band il tempo di prima») nella finestra
// dell'attesa del rientro, contro il divieto di A412 «l'ingresso del rientro non scrive niente su Link».
//
// La regola (mandato del referee «A412 · SEGUITO 1», §2.1): al richiamo del tempo di Link il Direttore ribatte il
// proprio tempo solo se suona davvero la sua linea — motore in moto, non muto in canzone (dalla crisi al rientro
// riuscito o alla fine del silenzio, attesa del rientro compresa), non nella fase «segue Link» dopo un rientro (T4) —
// e se il tempo del richiamo è diverso dal suo (il controllo di sempre contro il rimpallo). In ogni altro caso il
// richiamo non scrive niente su Link e, come sempre per il Direttore, non entra nel motore. Chi non è Direttore non
// passa di qui: il suo ramo del richiamo resta quello di oggi.
// L'ordine dei motivi è la precedenza: il silenzio prima di «segue Link» (dopo un rientro, una crisi nuova rimette il
// Direttore muto con «segue Link» ancora alzato, e la riga che conta è quella del silenzio).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum DirectorTempoRebroadcastDecision {

    /// Perché il Direttore non ribatte, nell'ordine della regola, col nome che va nelle righe di registro.
    enum Hold: String, CaseIterable, Equatable {
        /// Solo o Follower: questa regola non li riguarda.
        case notDirector = "non-direttore"
        /// Muto in canzone, attesa del rientro compresa (A412 · SEGUITO 1).
        case silentInSong = "muto-in-canzone"
        /// Dopo un rientro, fino all'avvio dopo (A412, T4).
        case followsLink = "segue-link"
        /// Motore fermo: niente da ribattere, e la sessione resta a chi suona (com'era).
        case engineStopped = "motore-fermo"
        /// Il richiamo porta il tempo del Direttore: niente rimpallo (com'era).
        case sameTempo = "stesso-tempo"
    }

    enum Outcome: Equatable {
        /// Il Direttore riscrive su Link il proprio tempo (`link_engine_set_bpm(_audioBPM)`), come a click in moto.
        case rebroadcast
        /// Nessuna scrittura verso Link.
        case hold(Hold)

        var rebroadcasts: Bool {
            if case .rebroadcast = self { return true }
            return false
        }
    }

    /// La regola. `playerRole`: il ruolo del player (`PlayerRoleDecision`); `engineRunning`: il motore in moto
    /// (`isRunning`); `silentInSong`: il Direttore muto in canzone; `followsLink`: la fase «segue Link» dopo un rientro;
    /// `callbackTempo`: il tempo che porta il richiamo; `ownTempo`: il tempo della linea del Direttore (`_audioBPM`).
    static func outcome(playerRole: PlayerRole,
                        engineRunning: Bool,
                        silentInSong: Bool,
                        followsLink: Bool,
                        callbackTempo: Double,
                        ownTempo: Double) -> Outcome {
        guard playerRole == .direttore else { return .hold(.notDirector) }
        if silentInSong { return .hold(.silentInSong) }
        if followsLink { return .hold(.followsLink) }
        guard engineRunning else { return .hold(.engineStopped) }
        guard callbackTempo != ownTempo else { return .hold(.sameTempo) }
        return .rebroadcast
    }
}
