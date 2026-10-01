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
// ⚠️ B2b (A2, Mauro 25/09/2026 — «il segnale del Direttore vale solo a show aperto»): «sempre»
//    qui sopra non vale piu'. Il Direttore ripete SOLO a show aperto (`showOpen`: il runner sta
//    nello slot della stanza — riempito da `install`, svuotato da END SHOW e dall'uscita dalla
//    stanza). A show chiuso salta con `showClosed`: allo scadere della soglia i Follower vanno
//    FUORI e rientrano scegliendo la canzone. Il testo sopra resta come storia.
// ⚠️ B2d (mandato «A386 · FASE B2d», 01/10/2026) — IL GIRO HA TRE VALORI, NON DUE. «Il segno si
//    alterna … l'ora oscilla» qui sopra non vale piu'. Con due valori alternati l'ora tornava
//    uguale ogni due ripetizioni: un Follower che fra due letture ne riceveva due (o che ne
//    perdeva una) rileggeva il valore di prima e non contava niente — al collaudo dell'01/10
//    (log `A386_D7_iPad.txt`, 20:03:12 e 20:04:31) questo, con l'ascolto a 1 s, ha dato due
//    «non sento» falsi a Direttore presente. Ora lo spostamento gira su tre passi sull'ora
//    catturata: +1 ms, −2 ms, +1 ms. Se la cattura restituisce cio' che e' stato scritto, l'ora
//    fa T+1 ms, T−1 ms, T e poi da capo: tre valori distinti, somma zero (non deriva), e fra
//    due ripetizioni qualunque distanti una o due posizioni l'ora e' sempre diversa. Torna
//    uguale solo dopo tre ripetizioni, cioe' dopo la soglia di «non sento» (3 s).
//    Il passo piu' piccolo resta 1 ms, quello gia' provato sugli apparecchi.
//    L'ERRORE SULL'ORA: dopo un Play o uno Stop veri il giro riparte dal primo passo (`Cycle`,
//    `lastPlaying`: «suona» e' cambiato rispetto all'ultima ripetizione), quindi l'ora ripetuta
//    resta entro 1 ms da quella vera, come prima. Se l'ora catturata cambia SENZA che cambi
//    «suona» (due cambi di trasporto dentro lo stesso secondo, o Link che rimappa l'ora), il
//    giro non lo sa e continua dal passo dov'era: l'ora ripetuta resta entro 2 ms da quella
//    nuova. Mai oltre: la somma di passi consecutivi del giro sta fra −2 ms e +2 ms.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
struct DirectorReannounceDecision: Equatable {

    /// B2d — dove si trova il giro della ripetizione. Vive nel motore, su audioQueue.
    struct Cycle: Equatable {
        /// Il passo che usera' la prossima ripetizione: 0, 1, 2.
        let step: Int
        /// «Suona» scritto all'ultima ripetizione (`nil` = nessuna ripetizione ancora).
        let lastPlaying: Bool?

        /// Quanti passi ha il giro, cioe' quanti valori distinti prende l'ora.
        static let length = 3
        /// Prima di ogni ripetizione.
        static let start = Cycle(step: 0, lastPlaying: nil)
    }

    enum SkipReason: Equatable {
        case notDirector
        case userLinkOff
        case startStopSyncOff
        case linkUnavailable
        /// B2b (A2): nessuno show aperto nella stanza del Direttore.
        case showClosed
    }

    enum Outcome: Equatable {
        case skip(SkipReason)
        /// Scrivi `{isPlaying, at}` con una cattura e un commit (`link_engine_reannounce_transport`).
        case reannounce(isPlaying: Bool, at: UInt64)
    }

    let outcome: Outcome
    /// Lo spostamento col segno da dare al ponte, in tick; zero quando si salta.
    let shift: Int64
    /// Il passo del giro usato da questa ripetizione (0, 1, 2); `nil` quando si salta.
    let step: Int?
    /// Il giro per la prossima ripetizione: avanza SOLO quando si e' ripetuto.
    let nextCycle: Cycle

    /// Lo spostamento del passo `step` (0, 1, 2) per un millisecondo di `shiftTicks` tick:
    /// +1 ms, −2 ms, +1 ms. Fuori dal giro vale il passo modulo tre.
    static func signedShift(step: Int, shiftTicks: UInt64) -> Int64 {
        let one = Int64(clamping: shiftTicks)
        let position = ((step % Cycle.length) + Cycle.length) % Cycle.length
        return position == 1 ? -2 * one : one
    }

    init(role: LinkMode,
         userLinkEnabled: Bool,
         startStopSyncEnabled: Bool,
         linkEnabled: Bool,
         showOpen: Bool,
         sessionPlaying: Bool,
         capturedTime: UInt64,
         shiftTicks: UInt64,
         cycle: Cycle) {
        let skipReason: SkipReason?
        if role != .direttore {
            skipReason = .notDirector
        } else if !userLinkEnabled {
            skipReason = .userLinkOff
        } else if !startStopSyncEnabled {
            skipReason = .startStopSyncOff
        } else if !linkEnabled {
            skipReason = .linkUnavailable
        } else if !showOpen {
            skipReason = .showClosed
        } else {
            skipReason = nil
        }
        if let reason = skipReason {
            outcome = .skip(reason)
            shift = 0
            step = nil
            nextCycle = cycle
            return
        }
        // Un Play o uno Stop veri dall'ultima ripetizione: l'ora catturata e' quella vera, e il
        // giro riparte dal primo passo (T+1 ms, T−1 ms, T).
        let transportChanged = cycle.lastPlaying != nil && cycle.lastPlaying != sessionPlaying
        let used = transportChanged ? 0 : ((cycle.step % Cycle.length) + Cycle.length) % Cycle.length
        let signed = DirectorReannounceDecision.signedShift(step: used, shiftTicks: shiftTicks)
        let at: UInt64
        if signed >= 0 {
            at = capturedTime &+ signed.magnitude
        } else {
            at = capturedTime >= signed.magnitude ? capturedTime - signed.magnitude : 0
        }
        outcome = .reannounce(isPlaying: sessionPlaying, at: at)
        shift = signed
        step = used
        nextCycle = Cycle(step: (used + 1) % Cycle.length, lastPlaying: sessionPlaying)
    }
}
