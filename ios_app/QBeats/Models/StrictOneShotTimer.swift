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
// vive il timer: ogni armamento la ri-programma (`schedule(deadline:)`, che sostituisce la scadenza di prima) e le da' un gestore
// nuovo col numero dell'armamento (`setEventHandler`); un gestore vecchio gia' consegnato alla coda non trova il suo numero e non
// fa niente, come nel timer qui sopra. Il costo per armamento: una chiusura e due chiamate sulla sorgente, nessuna creazione e
// nessun annullo. L'annullo ri-programma a mai e alza il numero. Le regole:
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
