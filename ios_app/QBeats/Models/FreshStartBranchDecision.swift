import Foundation

// === RIENTRO-P1 (17/09/2026) — IL RAMO DELL'AVVIO FRESCO: UN SOLO POSTO, TESTATO ===
// Un avvio fresco del motore (`AudioEngine.start(resumeAtBeat:)`, ramo senza beat di
// ripresa) sceglie fra tre porte. Fino a oggi la scelta era una condizione scritta in
// linea dentro `start`; da qui esce la stessa scelta, con UNA riga in più:
//
//     a Link spento si va sempre nel ramo standalone.
//
// Perché. «Almeno un collegato» nel motore è `link_engine_num_peers`, cioè il contatore
// C++ `numPeers_` (`LinkEngine.mm`), che si scrive solo nel callback `isConnected` di
// LinkKit. Quando l'utente spegne Link dal pannello quel callback NON scatta: il contatore
// resta a 1. Collaudo del 17/09/2026 su `c21fbef`, giro G7 (log dell'iPad, 10:39:19):
// Follower con Link spento dal pannello, tocco sul velo, e il motore passa dal ramo
// condiviso con `peers:1 isPlaying:0 phase:0.0000 attesa:0.0000`. Oggi è innocuo (a Link
// spento il ponte esce subito da probe e join), ma il ramo condiviso è quello su cui i
// passi successivi del rientro esatto appenderanno i giudizi «non certo → fermo»: un
// apparecchio che suona da solo non deve poterci finire per un contatore stantio.
// Referto A364, §3.h e §5.m.
//
// Che cosa NON cambia:
//  · il Follower deciso in testa a `start` (`FollowerStartDecision`, A361/A362) entra
//    nella sessione che suona, qualunque cosa dicano gli altri ingressi;
//  · a Link acceso la tabella è quella di sempre (BOX5, «Link — fresh play branching»):
//    nessun collegato E sessione ferma → standalone; Direttore → sempre il suo ramo;
//    altrimenti sessione condivisa.
// «Link acceso» qui è l'interruttore dell'APP (`link_engine_is_enabled`, cioè `enabled_`):
// lo spengono sia l'utente dal pannello (callback `isEnabled`) sia l'app in secondo piano.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct FreshStartBranchDecision: Equatable {

    enum Outcome: Equatable {
        /// Follower e sessione che suona: ingresso in coda alla battuta (`armSharedJoin`).
        case followerJoin
        /// Standalone puro o Direttore: parte subito da battito 0.
        case standaloneOrDirector
        /// Sessione condivisa di chi NON è Follower: ingresso in coda alla battuta.
        case sharedJoin
    }

    /// `FollowerStartDecision.outcome == .joinRunningSession`.
    let followerJoins: Bool
    let role: LinkMode
    /// L'interruttore dell'app (`link_engine_is_enabled`).
    let linkEnabled: Bool
    /// `link_engine_num_peers > 0` — può restare indietro: è il motivo di questo tipo.
    let anyPeerConnected: Bool
    /// `isPlaying` letto da Link (`link_engine_probe_session`; a Link spento rende falso).
    let sessionPlaying: Bool

    let outcome: Outcome
    /// Vero quando a decidere è la riga nuova: Link spento E la tabella di sempre avrebbe
    /// mandato nel ramo condiviso. Serve alla riga di log, non decide niente.
    let linkOffOverridesStalePeers: Bool

    init(followerJoins: Bool, role: LinkMode, linkEnabled: Bool,
         anyPeerConnected: Bool, sessionPlaying: Bool) {
        self.followerJoins = followerJoins
        self.role = role
        self.linkEnabled = linkEnabled
        self.anyPeerConnected = anyPeerConnected
        self.sessionPlaying = sessionPlaying
        // La tabella di sempre, parola per parola:
        // `(peersCount == 0 && !probe.isPlaying) || self._linkMode == .direttore`.
        let standaloneByTheOldTable = (!anyPeerConnected && !sessionPlaying) || role == .direttore
        if followerJoins {
            self.outcome = .followerJoin
            self.linkOffOverridesStalePeers = false
        } else if !linkEnabled {
            self.outcome = .standaloneOrDirector
            self.linkOffOverridesStalePeers = !standaloneByTheOldTable
        } else if standaloneByTheOldTable {
            self.outcome = .standaloneOrDirector
            self.linkOffOverridesStalePeers = false
        } else {
            self.outcome = .sharedJoin
            self.linkOffOverridesStalePeers = false
        }
    }
}
