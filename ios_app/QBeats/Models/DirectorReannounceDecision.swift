import Foundation

// === A386 · FASE B1 (2D) — LA RIPETIZIONE DEL DIRETTORE: COSA SCRIVE, TESTATO ===
// Il Direttore ripete il proprio stato di trasporto ogni 1,0 s, sempre (decisione di Mauro,
// 23/09/2026): in moto `{vero, T ± 1 ms}`, da fermo `{falso, Tstop ± 1 ms}` — `T` e `Tstop`
// sono l'ora letta dalla cattura di Link (`ABLLinkTimeForIsPlaying`), NON «adesso»: cosi' un
// Follower che perde lo Stop vero e riceve una ripetizione decide il count-in come gli altri
// (D7, regole del referee). Il segno si alterna a ogni ripetizione: l'ora oscilla e non deriva.
// Perche' basta 1 ms: [R] Link.ipp:39-54, lo stato avvio/stop parte solo se diverso da quello
// catturato (:47-52) e porta come timbro l'ora del commit; Controller.hpp:402-403 lo adotta se
// piu' recente. Il millisecondo in tick lo da' il chiamante da `mach_timebase_info`.
// Chi non ripete: chi non e' Direttore; Direttore con Link spento dall'utente; Start Stop Sync
// spento (con lui il commit non esce, [R5]); ponte spento (`enabled_`).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct DirectorReannounceDecision: Equatable {

    enum Sign: Equatable {
        case plus
        case minus
        var flipped: Sign { self == .plus ? .minus : .plus }
    }

    enum SkipReason: Equatable {
        case notDirector
        case userLinkOff
        case startStopSyncOff
        case linkUnavailable
    }

    enum Outcome: Equatable {
        case skip(SkipReason)
        /// Scrivi `{isPlaying, at}` con una cattura e un commit (`link_engine_reannounce_transport`).
        case reannounce(isPlaying: Bool, at: UInt64)
    }

    let outcome: Outcome
    /// Il segno da usare alla prossima ripetizione: si alterna SOLO quando si e' ripetuto.
    let nextSign: Sign

    init(role: LinkMode,
         userLinkEnabled: Bool,
         startStopSyncEnabled: Bool,
         linkEnabled: Bool,
         sessionPlaying: Bool,
         capturedTime: UInt64,
         shiftTicks: UInt64,
         sign: Sign) {
        if role != .direttore {
            outcome = .skip(.notDirector)
            nextSign = sign
            return
        }
        if !userLinkEnabled {
            outcome = .skip(.userLinkOff)
            nextSign = sign
            return
        }
        if !startStopSyncEnabled {
            outcome = .skip(.startStopSyncOff)
            nextSign = sign
            return
        }
        if !linkEnabled {
            outcome = .skip(.linkUnavailable)
            nextSign = sign
            return
        }
        let at: UInt64
        switch sign {
        case .plus:
            at = capturedTime &+ shiftTicks
        case .minus:
            at = capturedTime >= shiftTicks ? capturedTime - shiftTicks : 0
        }
        outcome = .reannounce(isPlaying: sessionPlaying, at: at)
        nextSign = sign.flipped
    }
}
