import Foundation

// === A412 · SEGUITO 3 (18/10/2026) — IL TIMER ALL'ORA CHIESTA: COLPO SINGOLO, MARGINE DICHIARATO DI 1 ms ===
// Mandato del referee «A412 · SEGUITO 3». Al collaudo dell'IPA #776 (18/10/2026, 19:02-19:03) l'armamento del
// rientro del Direttore, atteso con `asyncAfter`, e' scattato fino a 135,7 ms dopo l'ora chiesta, su un'attesa di
// 3,538 s: il fuoco e' arrivato in ritardo due volte e il rientro e' slittato di due battute. Secondo la lettura del
// referee del sorgente di libdispatch [R], `asyncAfter` concede al sistema un ritardo pari a una frazione
// dell'attesa (5% sulla coda del motore, che e' `.userInteractive`). Questo timer dichiara il suo: una sorgente GCD a
// colpo singolo (`repeating: .never`), col flag `.strict` e un margine (leeway) di 1 ms.
// Lo usano le due attese del Direttore muto che mirano a un'ora: l'armamento del rientro e lo Stop di fine canzone
// (`AudioEngine`). L'ingresso del Follower lo potra' usare piu' avanti (M4); oggi resta su `asyncAfter`.
// Le regole:
//  - un'attesa sola alla volta: armare annulla quella di prima, anche dentro lo scatto di quella di prima;
//  - allo scatto il timer si rilascia PRIMA di eseguire il lavoro: un armamento fatto dal lavoro trova il timer
//    vuoto, e il nuovo resta l'unico armato;
//  - il lavoro e' un `DispatchWorkItem`, eseguito sulla coda del timer solo se nessuno l'ha annullato, come lo
//    esegue `asyncAfter`;
//  - il lavoro lo tiene il timer, non la sorgente: il gestore della sorgente ha solo un riferimento debole al timer e
//    il numero dell'armamento, e allo scatto si fa consegnare il lavoro. Cosi' la vita del lavoro non dipende da
//    quando GCD lascia il gestore di una sorgente annullata;
//  - dopo lo scatto o l'annullo il timer non tiene piu' niente: ne' la sorgente ne' il lavoro (`isArmed`,
//    `holdsWork`);
//  - si arma, si annulla e si legge SOLO sulla coda del timer (per il motore: audioQueue).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
final class StrictOneShotTimer {

    /// Il margine dichiarato, in millisecondi: lo stesso minimo che `asyncAfter` si da' da se' [R].
    static let leewayMilliseconds: Int = 1

    private let queue: DispatchQueue
    private var source: DispatchSourceTimer?
    /// Il lavoro dell'attesa armata. Lo tiene solo il timer, fino allo scatto o all'annullo.
    private var work: DispatchWorkItem?
    /// Cresce a ogni armamento: lo scatto consegna il lavoro solo se l'armamento e' ancora il suo.
    private var armings: UInt64 = 0

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    deinit {
        source?.cancel()
    }

    /// C'e' un'attesa armata, non ancora scattata ne' annullata.
    var isArmed: Bool { source != nil }

    /// Il timer tiene un lavoro: solo fra l'armamento e lo scatto o l'annullo.
    var holdsWork: Bool { work != nil }

    /// Arma `work` fra `seconds` secondi da adesso, come `asyncAfter(deadline: .now() + seconds)`, e annulla
    /// l'attesa di prima, se c'e'.
    func arm(afterSeconds seconds: Double, work: DispatchWorkItem) {
        cancel()
        armings &+= 1
        let arming = armings
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.schedule(deadline: .now() + seconds, repeating: .never,
                       leeway: .milliseconds(StrictOneShotTimer.leewayMilliseconds))
        timer.setEventHandler { [weak self] in
            // Colpo singolo: prima il rilascio (che consegna il lavoro), poi il lavoro.
            guard let self, self.armings == arming, let item = self.disarm() else { return }
            if !item.isCancelled {
                item.perform()
            }
        }
        source = timer
        self.work = work
        timer.resume()
    }

    /// Annulla l'attesa armata, se c'e': il lavoro non parte e il timer non tiene piu' niente.
    func cancel() {
        _ = disarm()
    }

    /// Toglie e annulla la sorgente, e consegna il lavoro: da qui il timer non tiene niente.
    private func disarm() -> DispatchWorkItem? {
        let item = work
        work = nil
        if let timer = source {
            source = nil
            timer.cancel()
        }
        return item
    }
}

// === A421 · SEGUITO 2 (30/10/2026) — IL TIMER CHE SI RIARMA SENZA RIFARSI: il guardiano del buco (mandato, par. 4.2) ===
// Il guardiano si arma a ogni buffer programmato, circa cento volte al secondo: col timer qui sopra sarebbero una sorgente GCD
// creata e una annullata a ogni buffer (due operazioni di sistema, piu' una chiusura). Qui la sorgente e' una sola, viva finche'
// vive il timer: ogni armamento la ri-programma (`schedule(deadline:)`) e le da' un gestore nuovo col numero dell'armamento
// (`setEventHandler`); l'annullo ri-programma a mai e alza il numero.
// ⚠️ RISCRITTO A421 · SEGUITO 3 (31/10/2026, mandato par. 6), con le fonti. Il testo di prima diceva, senza fonte, che
// `schedule(deadline:)` «sostituisce la scadenza di prima e scarta l'evento in sospeso: e' questa la guardia contro lo scatto
// vecchio» e che il numero era «la seconda guardia, per un evento gia' consegnato alla coda prima della ri-programmazione».
// Le fonti: libdispatch open source, github.com/apple-oss-distributions/libdispatch, commit
// 2361ffb78a76f7ee488cd052eb0bc5c767118bf9 (tag libdispatch-1542.0.4); che sia il libdispatch di iOS 27 e' [Probabile].
//  - La guardia contro lo scatto vecchio e' la ri-programmazione. dispatch/source.h:694-697 (`dispatch_source_set_timer`),
//    verbatim: «Once this function returns, any pending source data accumulated for the previous timer values has been cleared;
//    the next fire of the timer will occur at 'start', and every 'interval' nanoseconds thereafter until the timer source is
//    canceled.» Nel codice: `dispatch_source_set_timer` (src/source.c:1343-1367) alloca la configurazione nuova
//    (`_dispatch_timer_config_create`, :1231-1235: una `_dispatch_calloc`), la scambia in `dt_pending_config` (:1364, liberando
//    quella in sospeso) e sveglia la sorgente (:1366); nell'invoke della sorgente (:802-810) `_dispatch_timer_unote_configure`
//    (src/event/event.c:869-882) applica la configurazione e azzera i dati in sospeso (:880-882: «Clear any pending data that
//    might have accumulated on older timer params»), PRIMA della consegna (:826-833): un evento vecchio non arriva al gestore.
//  - Il gestore nuovo: `setEventHandler` (src/swift/Source.swift:21-28 → `dispatch_source_set_event_handler`, src/source.c:368-371
//    → `_dispatch_source_set_handler`, :333-364) alloca una continuation (`_dispatch_source_handler_alloc`, :243-249) e, sulla
//    sorgente gia' attiva, la consegna con `_dispatch_barrier_trysync_or_async_f` (:362-363): subito se la corsia della sorgente
//    e' libera, altrimenti in coda, segnata come mutazione dopo l'attivazione (:352). Anche in coda il cambio di gestore si svuota
//    nell'invoke (:762-768) prima della configurazione (:802-810) e della consegna (:826-833, col gestore corrente: :564). Il
//    numero dell'armamento protegge quindi solo dal gestore vecchio, che alla consegna non c'e' piu', non da un evento vecchio: resta
//    per prudenza e costa un confronto.
//  - Il crash «Cannot change a handler of this source after it has been activated» (src/source.c:346-348) vale solo per le sorgenti
//    DSF_STRICT: dal tipo (`dst_strict`, :53-54) o da un cancel handler obbligatorio (:394, :410). `DispatchSource.makeTimerSource(
//    flags: .strict, queue:)` (src/swift/Source.swift:207-209) chiama `dispatch_source_create(_swift_dispatch_source_type_TIMER(), 0,
//    UInt(flags.rawValue), coda)`: l'handle e' 0 e il flag e' `TimerFlags.strict` = 1 (:132-137) = DISPATCH_TIMER_STRICT.
//    `_swift_dispatch_source_type_TIMER()` rende `DISPATCH_SOURCE_TYPE_TIMER` (dispatch/source.h:187, `&_dispatch_source_type_timer`):
//    cosi' nello shim dell'overlay di Darwin quando stava in swiftlang/swift (swift-5.3-RELEASE,
//    stdlib/public/SwiftShims/DispatchOverlayShims.h:77-87, il macro `SWIFT_DISPATCH_SOURCE_TYPE(TIMER)`; e
//    stdlib/public/Darwin/Dispatch/Source.swift:184-185, lo stesso handle 0) e nello shim dell'overlay open source di oggi
//    (swiftlang/swift-corelibs-libdispatch, src/swift/shims/DispatchOverlayShims.h:70-80). Lo shim dell'overlay di Darwin di oggi
//    (`_SwiftDispatchOverlayShims`, importato da src/swift/Source.swift:14) non e' nel deposito Apple: che sia lo stesso e'
//    [Probabile]. Con l'handle 0 la creazione
//    (`_dispatch_source_timer_create`, src/event/event.c:938-972, :955-957) resta sul tipo `_dispatch_source_type_timer`
//    (:988-999), senza `dst_strict`; DISPATCH_TIMER_STRICT sta nella maschera del tipo (:992) e non e' DSF_STRICT. Solo un handle
//    DISPATCH_CLOCKID_* porterebbe al tipo «timer (fixed-clock)» (:958-969, :1001-1009), che e' strict e farebbe crashare ogni
//    armamento dopo il primo: non e' il nostro caso.
// Il costo per armamento, dalle fonti: una chiusura Swift; una continuation per il gestore e una configurazione del timer (due
// allocazioni, e la liberazione della configurazione di prima); due chiamate sulla sorgente e un suo risveglio; la registrazione
// vera del timer la fa l'invoke della sorgente, sulla sua coda. Nessuna creazione e nessun annullo di sorgente. Le regole:
//  - un'attesa sola alla volta: armare sostituisce quella di prima;
//  - allo scatto il lavoro si consegna PRIMA di eseguirlo: un armamento fatto dal lavoro resta l'unico armato;
//  - si arma, si annulla e si legge SOLO sulla coda del timer (per il motore: audioQueue).
final class StrictRearmableTimer {

    static let leewayMilliseconds: Int = StrictOneShotTimer.leewayMilliseconds

    private let queue: DispatchQueue
    private var source: DispatchSourceTimer?
    private var work: (() -> Void)?
    private var armings: UInt64 = 0

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    deinit {
        source?.cancel()
    }

    /// C'e' un'attesa armata, non ancora scattata ne' annullata.
    var isArmed: Bool { work != nil }

    /// Arma `work` fra `seconds` secondi da adesso (zero o meno: subito), al posto dell'attesa di prima, se c'e'.
    func arm(afterSeconds seconds: Double, work: @escaping () -> Void) {
        armings &+= 1
        let arming = armings
        self.work = work
        let timer: DispatchSourceTimer
        let fresh: Bool
        if let existing = source {
            timer = existing
            fresh = false
        } else {
            timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
            source = timer
            fresh = true
        }
        timer.setEventHandler { [weak self] in
            guard let self, self.armings == arming, let item = self.work else { return }
            self.work = nil
            item()
        }
        timer.schedule(deadline: .now() + max(seconds, 0), repeating: .never,
                       leeway: .milliseconds(StrictRearmableTimer.leewayMilliseconds))
        if fresh {
            timer.resume()
        }
    }

    /// Annulla l'attesa armata, se c'e': il lavoro non parte; la sorgente resta, programmata a mai.
    func cancel() {
        guard work != nil else { return }
        armings &+= 1
        work = nil
        source?.schedule(deadline: .distantFuture, repeating: .never,
                         leeway: .milliseconds(StrictRearmableTimer.leewayMilliseconds))
    }
}
