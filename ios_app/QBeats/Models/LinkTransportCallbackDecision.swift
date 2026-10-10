import Foundation

// === A400 (10/10/2026) — IL RICHIAMO AVVIO/STOP DI LINK: UN SOLO POSTO, TESTATO ===
// ⚠️ PRIMO COMMIT DEL RAMO: QUI C'È LA REGOLA DI OGGI, estratta dal richiamo com'è alla
//    punta `a292550` (`AudioEngine.init`, `link_engine_set_start_stop_callback`). Il segno
//    del proprio avvio entra già fra gli ingressi ma NON decide: nel motore non esiste
//    ancora, e ogni richiamo va dritto a main. Il banco porta l'atteso NUOVO, quindi i
//    casi dell'eco propria cadono: è la prova che la cura cambia qualcosa. La regola nuova
//    entra col commit della cura, in `queueStep`.
//
// Il fatto (referto A399 §5, misurato sui log del collaudo di M3). LinkKit richiama sul
// main thread quando cambia lo stato avvio/stop della sessione (`ABLLink.h`: «Invoked on
// the main thread when the Start/stop state of the Link session changes»). Misurato: con
// Start Stop Sync acceso e nessun collegato richiama anche per l'avvio scritto
// dall'apparecchio stesso. Il Solo scrive «suona» in Link da `audioQueue`, dentro
// `start()`, prima che `isPlaying` passi a vero su main: il richiamo trova il motore
// ancora «fermo» e lo fa partire una seconda volta (eco propria → avvia).
//
// Il richiamo ha due passi, e il tipo li porta tutti e due:
//  · passo di coda (`queueStep`, su `audioQueue`): oggi non c'è, manda sempre a main;
//  · passo di main (`mainStep`): avvio a motore fermo → il motore parte, se il lucchetto
//    del doppio invio (`_linkStartEmitInFlight`) è giù; stop a motore in moto → il motore
//    si ferma; il resto niente.
//
// I due rami di ruolo — il Direttore ignora sempre, il Follower passa dalla sua macchina
// (`FollowerSyncDecision`) — sono scritti nel richiamo, prima dei due passi; qui sono la
// stessa tabella, per il banco. «Follower» è la regola di `FollowerDecision` (ruolo E Link
// acceso dall'utente).
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

    /// Il passo di coda. REGOLA DI OGGI: il segno non esiste, ogni richiamo va a main.
    static func queueStep(isPlaying: Bool, ownStartPending: Bool) -> QueueStep {
        return .forwardToMain
    }

    /// Il passo di main, parola per parola il blocco del richiamo:
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
