import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: I RITORNI DOPO IL SILENZIO E LA RETE DEL MOTORE FERMO ===
// Il fatto (collaudo del 24/10, registri delle 12:37, 13:59 e 14:37; mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.2
// a-d). Con le cuffie col filo il render è ripartito 681 e 684 ms dopo la notizia del cambio di percorso (la premessa del
// referto A419, 30-36 ms, non vale sempre); con la cassa Bluetooth il sistema ferma il motore 16-641 ms dopo la notizia e
// manda la notifica di configurazione 132-837 ms dopo; e alle 12:35:23.016 un richiamo della catena corrente, arrivato
// 11 ms dopo che il sistema aveva fermato il motore, ha programmato un buffer e fatto l'assert che ha spostato la band.
//
// Le regole:
//  · il ritorno del Direttore (U6): dopo il silenzio e l'arresto, l'innesco `outputAdded` (o `renderGap`) verso
//    `activateSessionAndStart` → `RecoveryDecision` → il coordinatore → il rientro (T4, T5). Quando: se la frequenza della
//    sessione è già diversa dalla copia si aspetta la notifica di configurazione, e la notifica «ignorato» (il motore
//    l'abbiamo già fermato noi) è il suo segnale (par. 2.2 b), con una riserva a 2 s; se no, 100 ms d'assestamento;
//  · il ritorno del Follower (par. 2.2 c): il volume torna al primo «uno» di battuta che cade dopo tutte e due queste ore:
//    0,3 s dopo la notizia, e la fine d'uscita dei buffer programmati fino alla prima chiamata di `scheduleNextBuffer` dopo
//    la notizia (compreso quello che quella chiamata produce) più la durata del click (40 ms), latenza d'uscita compresa.
//    L'«uno» è di Link (la cattura senza commit, T11) o, DA-SOLO, della linea propria. Il volume si rimette prima che si
//    calcoli il battito dell'«uno» (U3 c): nella chiamata di `scheduleNextBuffer` che produce il buffer dell'«uno», prima di
//    `metronome_processBuffer`, cioè circa due buffer prima che quel buffer vada al rendering (⚠️ RISCRITTO dopo la verifica
//    indipendente del diff: la prima stesura lo rimetteva al rendering stimato del buffer, su un timer, con un margine da zero a
//    una frazione di buffer);
//  · il tocco «altoparlante» (par. 2.2 g): lo stesso ritorno. ⚠️ RISCRITTO A421 · SEGUITO 1 (26/10/2026): qui si diceva «con la
//    sola ora "0,3 s dopo il tocco"». Due difetti erano del mandato A421 (seguito 1, par. 1): il tocco con una regola sua, e
//    la scadenza scritta per l'«uno». Da qui (seguito 1, par. 2): il tocco ha le due ore della notizia, con l'ora del tocco; e
//    la scadenza vale per il PRIMO CAMPIONE A VOLUME 1, non per l'«uno»: il volume torna al calcolo del buffer dell'«uno» coi
//    buffer già programmati davanti, e il primo campione che può suonare a volume 1 (`firstSampleAtVolumeOneTicks`, dal
//    rendering, caso peggiore) deve essere alla scadenza o dopo; se no il ritorno passa all'«uno» della battuta dopo. L'«uno»
//    si porta come battito col suo orologio (`FollowerReturnUno`) e si rilegge a ogni chiamata (`refreshUno`): un cambio di
//    tempo lo tiene sulla battuta, un cambio d'orologio o un'ora non rileggibile riarmano; senza un «uno» calcolabile il
//    volume torna alla prima chiamata col primo campione alla scadenza o dopo; un buco del render visto dal misuratore riarma;
//  · la rete del motore fermo dal sistema (par. 2.2 a): se un richiamo trova il motore di sistema fermo con `isRunning`
//    vero non programma niente; se entro 2 s non arriva nessun gestore e lo stato è ancora quello, si usa la decisione
//    della configurazione (`EngineConfigChangeDecision`).
// Ogni attesa ha un padrone solo e riguarda le sue condizioni quando scatta (par. 2.3 b): lo fa il motore, con queste
// regole. Qui solo aritmetica su tick e battiti.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Che cosa aspetta il ritorno del Direttore.
enum DirectorReturnWait: String, Equatable {
    /// 100 ms d'assestamento (il filo: la frequenza non cambia).
    case settle = "assestamento"
    /// La notifica di configurazione (la frequenza della sessione è già diversa dalla copia), con la riserva.
    case configuration = "configurazione"
}

/// A421 · SEGUITO 1 — l'orologio da cui viene l'«uno» del ritorno del Follower (par. 2.2): Link, o la linea propria DA-SOLO.
enum FollowerReturnClock: String, Equatable {
    case link = "link"
    case own = "proprio"
}

/// A421 · SEGUITO 1 — l'«uno» scelto all'armo: il battito e il suo orologio. Nel motore `nil` è il segno «uno non calcolabile».
struct FollowerReturnUno: Equatable {
    let beat: Double
    let clock: FollowerReturnClock
}

/// A421 · SEGUITO 1 — la rilettura dell'«uno» a ogni chiamata (par. 2.2).
enum FollowerUnoRefresh: Equatable {
    /// L'orologio non è più quello salvato, o l'ora dell'«uno» non si rilegge: si riarma con la stessa regola.
    case rearm(reason: String)
    /// L'ora dell'«uno» riletta dal battito salvato.
    case ticks(UInt64)
}

/// A421 · SEGUITO 1 — che cosa fa la chiamata di `scheduleNextBuffer` col ritorno del Follower armato (par. 2.2).
enum FollowerReturnStep: Equatable {
    /// Non ancora: il buffer non porta l'«uno» (o, senza un «uno», il primo campione a volume 1 è prima della scadenza).
    case wait
    /// Il volume torna adesso.
    case restore
    /// Il buffer porta l'«uno» ma il primo campione a volume 1 sarebbe prima della scadenza (di `earlyTicks`): all'«uno»
    /// della battuta dopo, con la stessa scadenza.
    case nextBar(earlyTicks: UInt64)
}

enum OutputReturnDecision {

    /// L'assestamento del Direttore (U6; decisione del 23/10, confermata il 24/10: par. 2.2 d).
    static let directorSettleSeconds: Double = 0.100
    /// La riserva quando si aspetta la configurazione: da 1 s a 2 s (par. 2.2 b; il 24/10 fra notizia e configurazione
    /// 756, 837 e 132 ms).
    static let configurationReserveSeconds: Double = 2.0
    /// Il Follower (e il tocco): il volume non torna prima di 0,3 s dalla notizia.
    static let followerMinimumSeconds: Double = 0.3
    /// La coda di un click (`generateClickSamples`: 40 ms), che continua nei buffer dopo.
    static let clickTailSeconds: Double = 0.040
    /// I buffer che il motore tiene programmati: tre a ogni catena, due davanti a quello che una chiamata produce.
    static let queuedAheadBuffers: Int = 2
    /// La rete del motore fermo dal sistema (par. 2.2 a).
    static let stoppedEngineNetSeconds: Double = 2.0
    /// La riga del motore fermo dal sistema: la prima volta, poi una ogni dieci.
    static let stoppedEngineLineEvery: Int = 10

    static func directorWait(sessionRateDiffersFromCopy: Bool) -> DirectorReturnWait {
        sessionRateDiffersFromCopy ? .configuration : .settle
    }

    static func directorWaitSeconds(_ wait: DirectorReturnWait) -> Double {
        switch wait {
        case .settle: return directorSettleSeconds
        case .configuration: return configurationReserveSeconds
        }
    }

    /// `a` più `seconds`, in tick; si ferma a zero.
    static func ticks(_ a: UInt64, plusSeconds seconds: Double, ticksPerSecond: Double) -> UInt64 {
        guard ticksPerSecond > 0, ticksPerSecond.isFinite, seconds.isFinite else { return a }
        let delta = seconds * ticksPerSecond
        if delta >= 0 {
            let (sum, overflow) = a.addingReportingOverflow(UInt64(delta))
            return overflow ? UInt64.max : sum
        }
        let back = UInt64(-delta)
        return a >= back ? a - back : 0
    }

    /// La fine d'uscita del buffer che la chiamata di adesso produce: l'ora d'uscita del prossimo buffer da rendere
    /// (`nextBufferOutputHostTime`) più i buffer davanti al nostro, più il nostro.
    static func programmedEndOutputTicks(nextBufferOutputTicks: UInt64, queuedAhead: Int, bufferTicks: UInt64) -> UInt64 {
        let (span, overflow) = bufferTicks.multipliedReportingOverflow(by: UInt64(max(queuedAhead, 0) + 1))
        if overflow { return UInt64.max }
        let (sum, overflow2) = nextBufferOutputTicks.addingReportingOverflow(span)
        return overflow2 ? UInt64.max : sum
    }

    /// La scadenza del Follower: le due ore — 0,3 s dalla notizia e la fine d'uscita dei buffer programmati più la coda del
    /// click — e vince la più tarda. A421 · SEGUITO 1 (par. 2.1): la stessa regola per il tocco «altoparlante», con l'ora del
    /// tocco al posto di quella della notizia (`tapDeadlineTicks`, la sola ora «0,3 s dopo il tocco», è uscito: dentro un buco
    /// del render la prima chiamata dopo il tocco è quella dopo il buco, e i buffer programmati prima uscivano a volume 1).
    static func followerDeadlineTicks(noticeTicks: UInt64, programmedEndOutputTicks: UInt64, ticksPerSecond: Double) -> UInt64 {
        let byNotice = ticks(noticeTicks, plusSeconds: followerMinimumSeconds, ticksPerSecond: ticksPerSecond)
        let byBuffers = ticks(programmedEndOutputTicks, plusSeconds: clickTailSeconds, ticksPerSecond: ticksPerSecond)
        return max(byNotice, byBuffers)
    }

    // === A421 · SEGUITO 1 (26/10/2026) — LA SCADENZA VALE PER IL PRIMO CAMPIONE A VOLUME 1, NON PER L'«UNO» (par. 2.2) ===

    /// Il primo campione che può uscire a volume 1 dopo una scrittura di `outputVolume` in questa chiamata, nel caso peggiore
    /// (Apple non dice da quando la scrittura vale per il rendering; [Ipotesi: dal ciclo dopo]; si prende il ciclo in corso):
    /// l'ora d'uscita del prossimo buffer da rendere (`nextBufferOutputHostTime`) meno un CICLO D'USCITA (`cycleTicks` =
    /// `bufferDurationTicks`, la durata del buffer di I/O della sessione: 5,33-21,33 ms; non il buffer da 512 campioni del
    /// lettore); con la lettura di riserva (`lastRenderTime` non valido: `now + latenza + ciclo`, che sottostima) un ciclo in
    /// più. Si ferma a zero. (Dopo la verifica indipendente del diff: la prima stesura toglieva il buffer da 512 campioni.)
    static func firstSampleAtVolumeOneTicks(nextBufferOutputTicks: UInt64, cycleTicks: UInt64, fallbackRead: Bool) -> UInt64 {
        let cycles: UInt64 = fallbackRead ? 2 : 1
        let (back, overflow) = cycleTicks.multipliedReportingOverflow(by: cycles)
        if overflow { return 0 }
        return nextBufferOutputTicks >= back ? nextBufferOutputTicks - back : 0
    }

    /// La guardia del primo campione: il volume torna solo se il primo campione a volume 1 non è prima della scadenza.
    static func volumeMayReturn(firstSampleTicks: UInt64, deadlineTicks: UInt64) -> Bool {
        firstSampleTicks >= deadlineTicks
    }

    /// L'orologio dell'«uno»: Link quando il Follower segue Link (`followsLinkQ`), se no la linea propria DA-SOLO.
    static func unoClock(followsLink: Bool) -> FollowerReturnClock {
        followsLink ? .link : .own
    }

    /// A ogni chiamata, prima della guardia: se l'orologio non è più quello salvato il ritorno si riarma con la stessa regola;
    /// se è lo stesso, l'ora dell'«uno» riletta dal battito salvato (Link: `link_engine_time_at_beat`; DA-SOLO: `ownTicks`
    /// sulla linea propria), così regge un cambio di tempo fra l'armo e l'«uno»; se non si può rileggere (`nil`), si riarma.
    static func refreshUno(saved: FollowerReturnUno, clockNow: FollowerReturnClock, rereadTicks: UInt64?) -> FollowerUnoRefresh {
        if saved.clock != clockNow { return .rearm(reason: "orologio-cambiato") }
        guard let ticks = rereadTicks else { return .rearm(reason: "uno-non-rileggibile") }
        return .ticks(ticks)
    }

    /// L'«uno» della battuta dopo: il battito scelto più una battuta (Link: il quantum; DA-SOLO: i battiti della battuta),
    /// sullo stesso orologio. Non si ricalcola con `nextBarBeat(atOrAfter: scadenza)`, che darebbe lo stesso «uno».
    static func nextBarUno(_ uno: FollowerReturnUno, beatsPerBar: Int) -> FollowerReturnUno? {
        guard uno.beat.isFinite, beatsPerBar > 0 else { return nil }
        return FollowerReturnUno(beat: uno.beat + Double(beatsPerBar), clock: uno.clock)
    }

    /// La chiamata col ritorno armato (le condizioni del motore — motore in moto, interruzione bassa, uscita non mancante,
    /// volume a 0, servizi normali — le guarda il motore). Con un «uno»: se il buffer non lo porta, si aspetta; se lo porta e il
    /// primo campione a volume 1 non è prima della scadenza, il volume torna; se è prima, all'«uno» della battuta dopo, con la
    /// stessa scadenza. Senza un «uno» calcolabile: il volume torna alla prima chiamata in cui il primo campione non è prima
    /// della scadenza.
    static func followerReturnStep(bufferOutputTicks: UInt64,
                                   bufferTicks: UInt64,
                                   unoTicks: UInt64?,
                                   deadlineTicks: UInt64,
                                   firstSampleTicks: UInt64) -> FollowerReturnStep {
        let mayReturn = volumeMayReturn(firstSampleTicks: firstSampleTicks, deadlineTicks: deadlineTicks)
        guard let uno = unoTicks else {
            return mayReturn ? .restore : .wait
        }
        guard bufferReachesUno(bufferOutputTicks: bufferOutputTicks, bufferTicks: bufferTicks, unoTicks: uno) else {
            return .wait
        }
        return mayReturn ? .restore : .nextBar(earlyTicks: deadlineTicks - firstSampleTicks)
    }

    /// Il primo «uno» di battuta di Link non prima di `beat`: il multiplo del quantum uguale o seguente.
    /// Un battito esattamente su una battuta (a meno di un milionesimo) è quella battuta.
    static func nextBarBeat(atOrAfter beat: Double, quantum: Double) -> Double? {
        guard beat.isFinite, quantum > 0, quantum.isFinite else { return nil }
        return (beat / quantum - 1e-6).rounded(.up) * quantum
    }

    /// DA-SOLO: il primo «uno» non prima di `beatAtDeadline`, contando a battute dall'ultimo «uno» uscito.
    static func nextOwnUnoBeat(atOrAfter beatAtDeadline: Double, lastUnoBeat: Double, beatsPerBar: Int) -> Double? {
        guard beatAtDeadline.isFinite, lastUnoBeat.isFinite, beatsPerBar > 0 else { return nil }
        let bars = ((beatAtDeadline - lastUnoBeat) / Double(beatsPerBar) - 1e-6).rounded(.up)
        return lastUnoBeat + max(bars, 1) * Double(beatsPerBar)
    }

    /// L'ora, sulla linea propria, di un battito: l'inversa di `OwnClockTimeline.beat(atTicks:)`.
    static func ownTicks(atBeat beat: Double, timeline: OwnClockTimeline, ticksPerSecond: Double) -> UInt64? {
        guard beat.isFinite, timeline.bpm > 0, timeline.bpm.isFinite, ticksPerSecond > 0, ticksPerSecond.isFinite else {
            return nil
        }
        let seconds = (beat - timeline.anchorBeat) * 60.0 / timeline.bpm
        return ticks(timeline.anchorTicks, plusSeconds: seconds, ticksPerSecond: ticksPerSecond)
    }

    /// Il buffer che la chiamata di adesso produce porta l'«uno» (o lo scavalca): la sua fine d'uscita è oltre l'«uno».
    static func bufferReachesUno(bufferOutputTicks: UInt64, bufferTicks: UInt64, unoTicks: UInt64) -> Bool {
        let (end, overflow) = bufferOutputTicks.addingReportingOverflow(bufferTicks)
        return overflow || end > unoTicks
    }

    /// La riga del motore fermo dal sistema: al richiamo numero `callbacks` (da 1), la prima volta e poi una ogni dieci.
    static func writesStoppedEngineLine(callbacks: Int) -> Bool {
        callbacks > 0 && (callbacks - 1) % stoppedEngineLineEvery == 0
    }
}
