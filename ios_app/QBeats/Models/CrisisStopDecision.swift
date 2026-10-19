import Foundation

// === A412 (18/10/2026) — DIRETTORE IN CRISI, PASSO 2: CHE COSA FA OGNI CRISI, UNA REGOLA SOLA ===
// Il fatto (referto A409, §3.1 e §8.1; referto A410, §1.1). Il click di un apparecchio tace senza
// che nessuno abbia premuto Stop per sei cause: un'interruzione di sistema (Siri, sveglia, timer,
// chiamata), i servizi audio persi (Lost), il reset dei servizi senza Lost, il reset dopo la Lost, un
// cambio di configurazione del motore, un cambio di modo (Base ↔ Pro). Fino ad A411 ogni gestore
// decideva da sé, e alla Reset dopo la Lost lo `stopSync` mandava lo Stop alla band e chiudeva la
// canzone del Direttore (BUGS, `TD-media-reset-del-direttore-ferma-la-band`), contro LIBRO 2026-09-17
// «IL PRINCIPIO DELLA BAND»: un apparecchio in crisi non ferma la band.
//
// La regola (mandato del referee «DIRETTORE-IN-CRISI-PASSO-2», §2.1 e §2.7):
//  · Direttore a show aperto con la canzone in corso: MUTO IN CANZONE. Il click si ferma in locale
//    (come all'inizio di un'interruzione), l'àncora del conteggio si prende, nessuno Stop verso Link,
//    la canzone resta aperta e il runner resta sulla sua sezione. Il rientro lo decide il
//    coordinatore (`DirectorRejoinDecision`). Un Direttore già muto che riceve una crisi nuova resta
//    muto: non c'è niente da fermare;
//  · Direttore senza show o senza canzone in corso: arresto locale, nessuno Stop verso Link;
//  · Solo: alle crisi della sessione audio (interruzione, Lost, reset) col click in moto si ferma
//    come allo Stop della sua console (stato fermo, schermo dopo lo Stop) e non riparte da solo
//    (LIBRO 2026-08-30 ③, attiva per il Solo: «lo show va in standby e ASPETTA. Non riparte da
//    solo»); a configurazione e modo come oggi (ripartono da sole: non sono interruzioni della
//    sessione audio, referto A409 §3.1);
//  · Follower: come oggi, per ogni causa (alla Reset dopo la Lost lo ferma in locale lo `stopSync`,
//    senza scrivere su Link: è la sua regola A360).
// NESSUNA crisi manda Stop a Link, per nessun ruolo (`sendsStopToLink`). «Ruolo» è quello del player
// (`PlayerRoleDecision`): il ruolo Direttore con la levetta spenta è un Solo.
// «Canzone in corso»: il motore è partito per una canzone del runner (la mappa consegnata subito
// prima dell'avvio) e nessuno Stop lo ha fermato dopo; la tiene il motore, su audioQueue.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Le cause per cui il click tace senza Stop, col nome che va nelle righe di registro.
enum CrisisCause: String, CaseIterable, Equatable {
    case interruption = "interruzione"
    case servicesLost = "servizi-persi"
    case resetWithoutLost = "reset-senza-lost"
    case resetAfterLost = "reset-dopo-la-lost"
    case configuration = "configurazione"
    case mode = "modo"

    /// Una crisi della sessione audio (interruzione, servizi persi, reset): dopo una di queste il
    /// click del Solo non riparte da solo (mandato §2.7). Configurazione e modo no.
    var isAudioSessionCrisis: Bool {
        switch self {
        case .interruption, .servicesLost, .resetWithoutLost, .resetAfterLost:
            return true
        case .configuration, .mode:
            return false
        }
    }
}

/// Che cosa fa il gestore della crisi.
enum CrisisStopOutcome: String, Equatable {
    /// Direttore a show aperto con la canzone in corso: arresto locale (se il motore suona), àncora,
    /// stato «muto in canzone». Niente verso Link, la canzone resta aperta.
    case silentInSong = "muto-in-canzone"
    /// Direttore senza show o senza canzone in corso: arresto locale, niente verso Link.
    case localStop = "arresto-locale"
    /// Solo col click in moto, a una crisi della sessione audio: come lo Stop della sua console.
    case soloStopAsConsole = "come-lo-stop-della-console"
    /// Follower (ogni causa) e Solo a configurazione e modo: il codice di oggi del gestore.
    case asToday = "come-oggi"
    /// Niente da fermare: il motore non suona e nessun silenzio è in corso.
    case nothing = "niente"

    /// Nessun esito manda Stop a Link: il Solo ha il lucchetto (A411), il Follower non scrive (A360), il
    /// Direttore in crisi tace senza dirlo alla band (mandato §2.1). Lo Stop alla band è solo un'azione
    /// voluta (LIBRO 2026-09-17 «IL PRINCIPIO DELLA BAND»).
    var sendsStopToLink: Bool { false }
}

enum CrisisStopDecision {

    /// Mandato §2.1: «Nel banco: nessuna crisi manda Stop a Link, per nessun ruolo».
    static let sendsStopToLink = false

    /// La regola. `silentInSong`: il Direttore è già muto in canzone (una crisi nuova durante il
    /// silenzio, o durante l'attesa del rientro a motore fermo).
    static func outcome(playerRole: PlayerRole,
                        cause: CrisisCause,
                        showOpen: Bool,
                        songInProgress: Bool,
                        engineRunning: Bool,
                        silentInSong: Bool) -> CrisisStopOutcome {
        switch playerRole {
        case .follower:
            return .asToday
        case .solo:
            guard cause.isAudioSessionCrisis else { return .asToday }
            return engineRunning ? .soloStopAsConsole : .nothing
        case .direttore:
            if silentInSong { return .silentInSong }
            guard engineRunning else { return .nothing }
            return (showOpen && songInProgress) ? .silentInSong : .localStop
        }
    }
}
