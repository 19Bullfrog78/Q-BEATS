import Foundation

// === A361 (16/09/2026) — LA DECISIONE D'AVVIO DEL FOLLOWER: UN SOLO POSTO, TESTATO ===
// Il Follower non manda avvio a Link da nessuna porta, e il suo motore parte SOLO per
// entrare in una sessione che suona. La regola sta nel punto unico di avvio del motore
// (`AudioEngine.start(resumeAtBeat:)`), prima della scelta del ramo — non porta per
// porta: pedale, ripresa dopo un'interruzione di sistema, cambio di configurazione,
// reset dei servizi media, risveglio, recupero pendente, schermata di debug passano
// tutti di lì.
//
//  · chi comanda il trasporto (Direttore, Solo, e un ruolo Follower con Link spento
//    dall'utente): il motore parte come oggi, ripresa a beat noto compresa —
//    `commandsTransport`;
//  · Follower e sessione che suona: entra come entra oggi quando parte il Direttore
//    (`link_engine_join_running_session`), anche se l'innesco era una ripresa con un
//    beat — il beat di ripresa non si usa — `joinRunningSession`;
//  · Follower e sessione ferma: il motore NON parte — `stayStopped`. Dal Follower non
//    escono mai `link_engine_start_at_beat_zero` né `link_engine_start_at_beat`.
//
// ⚠️ A362 (16/09/2026) — L'ESITO DIPENDE DA DUE COSE SOLE: «è Follower» e «la sessione
//    suona». «Almeno un collegato» (`link_engine_num_peers`) NON entra nell'esito: quel
//    numero è la spia dei collegati, che può restare indietro (`TD-link-indicator-stale`),
//    e alla punta un Follower con la spia a zero e la sessione che suona entrava comunque
//    nel ramo condiviso (`armSharedJoin`); farlo dipendere dalla spia l'avrebbe tenuto
//    fermo al Play del Direttore. Resta qui solo come dato della riga di log, e il banco
//    prova che non cambia l'esito.
//
// «Follower» è la stessa regola di `FollowerDecision` (ruolo E Link acceso dall'utente).
// «Sessione che suona» è `isPlaying` letto da Link (`link_engine_probe_session`, che a
// Link spento rende falso).
//
// Ratifiche: LIBRO `2026-09-09/11` «IL TRASPORTO È DEL DIRETTORE» · «SI PARTE DAL PRIMO
// STANDBY» · `2026-09-10` «NIENTE START LOCAL» («Non parte mai da solo») ·
// `2026-09-09/11` «IL COMANDO DEL DIRETTORE FA RIPARTIRE ANCHE IL FOLLOWER».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct FollowerStartDecision: Equatable {

    enum Outcome: Equatable {
        /// Non è Follower: il motore parte come oggi (ripresa a beat noto compresa).
        case commandsTransport
        /// Follower e sessione che suona: entra nella sessione.
        case joinRunningSession
        /// Follower e sessione ferma: il motore non parte.
        case stayStopped
    }

    let isFollower: Bool
    /// Solo per la riga di log: non decide niente (A362).
    let anyPeerConnected: Bool
    let sessionPlaying: Bool
    /// L'innesco portava un beat di ripresa (`resumeAtBeat != nil`).
    let isResume: Bool
    let outcome: Outcome

    /// Il beat di ripresa si usa solo da chi comanda il trasporto: il Follower entra
    /// sempre come partenza fresca, in coda al prossimo confine di barra della sessione.
    var usesResumeBeat: Bool { outcome == .commandsTransport && isResume }

    init(role: LinkMode, userLinkEnabled: Bool,
         anyPeerConnected: Bool, sessionPlaying: Bool, isResume: Bool) {
        let follower = FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled)
        self.isFollower = follower
        self.anyPeerConnected = anyPeerConnected
        self.sessionPlaying = sessionPlaying
        self.isResume = isResume
        if !follower {
            self.outcome = .commandsTransport
        } else if sessionPlaying {
            self.outcome = .joinRunningSession
        } else {
            self.outcome = .stayStopped
        }
    }
}
