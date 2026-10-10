import Foundation

// === A400 (10/10/2026) — IL RICHIAMO AVVIO/STOP DI LINK: UN SOLO POSTO, TESTATO ===
// Regola del referee (ratifica del 10/10/2026 sul referto A399 §5): un avvio comandato da
// questo apparecchio non gli torna indietro come avvio di un altro. Gli avvii e gli stop
// che arrivano dagli altri apparecchi passano come prima.
//
// Il fatto (referto A399 §5, misurato sui log del collaudo di M3). LinkKit richiama sul
// main thread quando cambia lo stato avvio/stop della sessione (`ABLLink.h`: «Invoked on
// the main thread when the Start/stop state of the Link session changes»). Misurato: con
// Start Stop Sync acceso e nessun collegato richiama anche per l'avvio scritto
// dall'apparecchio stesso. Il Solo scrive «suona» in Link da `audioQueue`, dentro
// `start()`, prima che `isPlaying` passi a vero su main: il richiamo trovava il motore
// ancora «fermo» e lo faceva partire una seconda volta, e il secondo avvio riazzerava il
// contatore di sezione dopo il primo colpo.
//
// La cura è per costruzione, non per tempi. Il motore tiene un segno confinato ad
// `audioQueue` (`_ownTransportStartPendingQ`), alzato subito prima di ogni propria
// scrittura «suona» in Link: dice «ho scritto io», non legge `isPlaying` e non confronta
// ore. Il richiamo ha due passi, e il tipo li porta tutti e due:
//  · passo di coda (`queueStep`, su `audioQueue`): se il richiamo dice «suona» e il segno
//    è alzato, è l'eco del proprio avvio — il segno si consuma e non si fa altro;
//    altrimenti si passa a main. Dalla coda il motore fa passare solo il richiamo «suona»;
//  · passo di main (`mainStep`): la tabella di sempre — avvio a motore fermo → il motore
//    parte, se il lucchetto del doppio invio (`_linkStartEmitInFlight`) è giù; stop a
//    motore in moto → il motore si ferma; il resto niente.
// Uno stop non è mai un eco: il segno si consuma solo su «suona». E lo stop non passa
// dalla coda: il motore lo manda dritto a main, com'era prima di A400, perché dalla coda
// fermerebbe in ritardo rispetto ai comandi locali e quattro ordini si rovescerebbero
// contro il comportamento di prima (referto A400 §8.2, V1-V4). Così l'eco del proprio stop
// resta inerte, com'era. Per la regola non cambia niente: a uno stop il passo di coda
// rende comunque «a main».
//
// I due rami di ruolo — il Direttore ignora sempre, il Follower passa dalla sua macchina
// (`FollowerSyncDecision`) — restano scritti nel richiamo, prima dei due passi; qui sono
// la stessa tabella, per il banco. «Follower» è la regola di `FollowerDecision` (ruolo E
// Link acceso dall'utente).
// Storia del ramo: il primo commit portava qui la regola di prima (il passo di coda
// mandava sempre a main) e il banco con l'atteso nuovo; i tre test `testOwnEcho…`
// cadevano. Con questa regola passano. Il secondo commit faceva passare dalla coda anche
// lo stop; il quarto l'ha riportato dritto a main (decisione del referee del 10/10/2026).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct LinkTransportCallbackDecision: Equatable {

    enum Action: Equatable {
        /// Direttore: ignora sempre avvii e stop dei collegati.
        case directorIgnores
        /// Follower: decide la sua macchina.
        case followerMachine
        /// Eco del proprio avvio: si consuma il segno e non si fa altro.
        case consumeOwnEcho
        /// Avvio di un altro apparecchio a motore fermo: il motore parte.
        case start
        /// Stop a motore in moto: il motore si ferma.
        case stop
        /// Niente.
        case none
    }

    /// L'esito del passo di coda.
    enum QueueStep: Equatable {
        case consumeOwnEcho
        case forwardToMain
    }

    /// L'esito del passo di main.
    enum MainStep: Equatable {
        case start
        case stop
        case none
    }

    /// `isPlaying` del richiamo: il nuovo stato avvio/stop della sessione.
    let isPlaying: Bool
    let role: LinkMode
    /// Link acceso dall'utente nel pannello Link.
    let userLinkEnabled: Bool
    /// Il segno del proprio avvio (`_ownTransportStartPendingQ`).
    let ownStartPending: Bool
    /// `isPlaying` del motore, letto su main.
    let engineIsPlaying: Bool
    /// Il lucchetto del doppio invio (`_linkStartEmitInFlight`), letto su main.
    let startEmitInFlight: Bool

    let action: Action

    init(isPlaying: Bool, role: LinkMode, userLinkEnabled: Bool,
         ownStartPending: Bool, engineIsPlaying: Bool, startEmitInFlight: Bool) {
        self.isPlaying = isPlaying
        self.role = role
        self.userLinkEnabled = userLinkEnabled
        self.ownStartPending = ownStartPending
        self.engineIsPlaying = engineIsPlaying
        self.startEmitInFlight = startEmitInFlight
        if role == .direttore {
            self.action = .directorIgnores
        } else if FollowerDecision.isFollower(role: role, userLinkEnabled: userLinkEnabled) {
            self.action = .followerMachine
        } else if Self.queueStep(isPlaying: isPlaying,
                                 ownStartPending: ownStartPending) == .consumeOwnEcho {
            self.action = .consumeOwnEcho
        } else {
            switch Self.mainStep(isPlaying: isPlaying,
                                 engineIsPlaying: engineIsPlaying,
                                 startEmitInFlight: startEmitInFlight) {
            case .start: self.action = .start
            case .stop: self.action = .stop
            case .none: self.action = .none
            }
        }
    }

    /// Il passo di coda: «suona» col segno alzato è l'eco del proprio avvio. Uno stop passa
    /// sempre a main, qualunque sia il segno (e il motore, per lo stop, non fa nemmeno il
    /// salto sulla coda: lo accoda direttamente su main).
    static func queueStep(isPlaying: Bool, ownStartPending: Bool) -> QueueStep {
        return (isPlaying && ownStartPending) ? .consumeOwnEcho : .forwardToMain
    }

    /// Il passo di main, parola per parola il blocco che il richiamo aveva prima di A400:
    /// `if isPlaying && !engine.isPlaying { guard !engine._linkStartEmitInFlight … start }`
    /// `else if !isPlaying && engine.isPlaying { stop }`.
    static func mainStep(isPlaying: Bool, engineIsPlaying: Bool,
                         startEmitInFlight: Bool) -> MainStep {
        if isPlaying && !engineIsPlaying {
            return startEmitInFlight ? .none : .start
        } else if !isPlaying && engineIsPlaying {
            return .stop
        }
        return .none
    }
}
