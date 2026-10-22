import Foundation

// === A416 · SEGUITO 2 (21/10/2026) — L'INTERRUZIONE DI SISTEMA E IL CAMBIO DI PERCORSO RIMANDATO ===
// Il fatto (mandato del referee «A416 · SEGUITO 2», §1; registro dell'iPhone del 21/10 delle 18:21:18). Con A416, durante
// una telefonata accettata dal banner con l'app davanti, il cambio di percorso verso il ricevitore ha portato la frequenza
// a tutte le copie, chiedendo la durata del buffer, e ha ricollegato il grafo (`engine.prepare()`); 28 ms dopo la fine del
// ricollegamento iOS ha dichiarato attiva la nostra sessione, senza una nostra `setActive`. La fine dell'interruzione non
// è arrivata e il Direttore è rimasto muto fino a fine canzone. Prima di A416 lo stesso ramo non chiedeva la durata del
// buffer e non preparava il motore, e in due telefonate su due (19/10) la fine è arrivata. Quale dei passi nuovi abbia
// fatto attivare la sessione non ha fonte; la regola qui sotto non ha bisogno di saperlo.
//
// La regola (mandato §2):
//  · uno stato «interruzione di sistema in corso», separato da `isAudioInterrupted` (che è lo stato della ripresa: il
//    Solo non lo alza, e la fine canzone e lo Stop voluto lo abbassano anche a interruzione in corso). Si alza a ogni
//    inizio di interruzione, per ogni ruolo. Si abbassa alla fine, qualunque siano le opzioni, a ogni attivazione
//    riuscita della sessione e a ogni avvio riuscito del motore: se la fine non arriva, il primo avvio dopo lo abbassa;
//  · con lo stato alzato un cambio di percorso non tocca né la sessione né il motore: si rimanda, e resta il motivo
//    dell'ultimo arrivato. Con lo stato basso fa quello che faceva (A416);
//  · il rimandato si esegue una volta sola: alla fine dell'interruzione, se la fine passa dalla ricostruzione del grafo,
//    oppure all'avvio dopo; mai per un altro cambio di percorso.
// Gli altri ingressi del cambio di percorso (motore, frequenza, modo, ripresa pendente) non cambiano l'esito: entrano qui
// perché il banco ne faccia la matrice (mandato §2.2) e dica che con lo stato alzato nessuno di loro fa passare niente.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Lo stato su audioQueue: l'interruzione di sistema in corso e il motivo del cambio di percorso rimandato.
struct InterruptionRouteState: Equatable {
    /// Interruzione di sistema in corso: alzato dall'inizio, abbassato dalla fine, dalla sessione attivata, dal motore
    /// avviato.
    var systemInterruption: Bool
    /// Il motivo dell'ultimo cambio di percorso rimandato (il nome di `AVAudioSession.RouteChangeReason`); `nil` =
    /// nessun rimandato.
    var deferredReason: String?

    static let initial = InterruptionRouteState(systemInterruption: false, deferredReason: nil)
}

/// Che cosa fa il cambio di percorso.
enum InterruptionRouteOutcome: String, Equatable, CaseIterable {
    /// Stato basso: il cambio di percorso di oggi (A416), con tutti i suoi rami.
    case asToday = "come-oggi"
    /// Stato alzato: niente che tocchi la sessione o il motore; si ricorda il motivo e si scrive la riga.
    case deferred = "rimanda"
}

/// Dove si esegue il rimandato: è il `contesto:` della riga «rimandato eseguito».
enum DeferredRouteRunner: String, Equatable, CaseIterable {
    /// La fine dell'interruzione che passa dalla ricostruzione del grafo.
    case interruptionEnd = "fine-interruzione"
    /// L'avvio del motore (`start()`), prima della frequenza.
    case start = "avvio"
}

enum InterruptionRouteDecision {

    /// Gli eventi che alzano o abbassano lo stato. Il nome è il `da:` della riga dello stato.
    enum Event: String, Equatable, CaseIterable {
        /// Inizio di un'interruzione (ogni ruolo): alza.
        case began = "inizio"
        /// Fine di un'interruzione, qualunque siano le opzioni: abbassa.
        case ended = "fine"
        /// Una `setActive(true)` riuscita: abbassa.
        case sessionActivated = "sessione-attivata"
        /// Un `engine.start()` riuscito: abbassa.
        case engineStarted = "motore-avviato"
    }

    /// Quello che il cambio di percorso di oggi guarderebbe: `isRunning` (il segno della coda, non il motore di sistema),
    /// la frequenza della sessione contro la copia, il modo, la ripresa pendente. Non cambia l'esito (vedi in testa).
    struct RouteConditions: Equatable {
        var engineRunning: Bool
        var rateDiffers: Bool
        var modeDiffers: Bool
        var pendingResume: Bool
    }

    /// Lo stato dopo un evento. Il rimandato resta: lo toglie solo chi lo esegue.
    static func state(after event: Event, from state: InterruptionRouteState) -> InterruptionRouteState {
        var next = state
        next.systemInterruption = (event == .began)
        return next
    }

    /// Il cambio di percorso. Stato alzato: si rimanda, e il motivo diventa quello di questo cambio (l'ultimo arrivato).
    /// Stato basso: come oggi, e lo stato non cambia (un rimandato in attesa lo esegue l'avvio).
    static func routeChange(reason: String,
                            conditions: RouteConditions,
                            state: InterruptionRouteState) -> (outcome: InterruptionRouteOutcome, state: InterruptionRouteState) {
        guard state.systemInterruption else { return (.asToday, state) }
        var next = state
        next.deferredReason = reason
        return (.deferred, next)
    }

    /// Alla fine dell'interruzione che passa dalla ricostruzione, o all'avvio: se c'è un rimandato si esegue (il suo
    /// motivo) e si toglie, una volta sola; altrimenti niente (`nil`).
    static func runDeferred(at runner: DeferredRouteRunner,
                            state: InterruptionRouteState) -> (reason: String?, state: InterruptionRouteState) {
        guard let reason = state.deferredReason else { return (nil, state) }
        var next = state
        next.deferredReason = nil
        return (reason, next)
    }
}
