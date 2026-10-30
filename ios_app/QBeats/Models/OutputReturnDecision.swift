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
/// A421 · SEGUITO 2 (par. 5.4, E.9) — e il quantum con cui è stato scelto (`beatsPerBar`): la battuta dopo lo usa, e un metro
/// cambiato fra l'armo e l'«uno» riarma (`refreshUno`, motivo «metro-cambiato»).
struct FollowerReturnUno: Equatable {
    let beat: Double
    let clock: FollowerReturnClock
    let beatsPerBar: Int
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
    /// A421 · SEGUITO 2 (par. 5.1, F1) — il buffer porta l'«uno» ma questa chiamata salta la correzione (la finestra «sync
    /// skip»): all'«uno» della battuta dopo, con la stessa scadenza; i click non sono ancora corretti.
    case nextBarInWindow
}

/// A421 · SEGUITO 2 (par. 4.4) — che cosa fa la chiamata col ritorno dopo il buco armato: il volume torna alla prima chiamata
/// col primo campione a volume 1 alla scadenza o dopo, senza aspettare l'«uno»; mai in una chiamata che salta la correzione;
/// mai se l'uscita esterna da cui usciva il click non c'è più (la notizia della tolta in ritardo: la riserva di 2 s).
enum GapReturnStep: Equatable {
    case wait
    case restore
    /// Il volume tornerebbe, ma la memoria dice esterna e un'esterna non c'è: si aspetta la notizia (o la riserva).
    case externalVanished
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
    /// A421 · SEGUITO 2 (par. 5.4, E.9): lo stesso se il metro (`_beatsPerBarQ`) non è più quello con cui l'«uno» è stato scelto,
    /// motivo «metro-cambiato»; se è lo stesso, l'ora dell'«uno» riletta dal battito salvato (Link: `link_engine_time_at_beat`;
    /// DA-SOLO: `ownTicks` sulla linea propria), così regge un cambio di tempo fra l'armo e l'«uno»; se non si può rileggere
    /// (`nil`), si riarma.
    static func refreshUno(saved: FollowerReturnUno, clockNow: FollowerReturnClock, beatsPerBarNow: Int,
                           rereadTicks: UInt64?) -> FollowerUnoRefresh {
        if saved.clock != clockNow { return .rearm(reason: "orologio-cambiato") }
        if saved.beatsPerBar != beatsPerBarNow { return .rearm(reason: "metro-cambiato") }
        guard let ticks = rereadTicks else { return .rearm(reason: "uno-non-rileggibile") }
        return .ticks(ticks)
    }

    /// L'«uno» della battuta dopo: il battito scelto più una battuta (Link: il quantum; DA-SOLO: i battiti della battuta),
    /// sullo stesso orologio e col quantum dell'«uno» (A421 · SEGUITO 2, E.9). Non si ricalcola con
    /// `nextBarBeat(atOrAfter: scadenza)`, che darebbe lo stesso «uno».
    static func nextBarUno(_ uno: FollowerReturnUno) -> FollowerReturnUno? {
        guard uno.beat.isFinite, uno.beatsPerBar > 0 else { return nil }
        return FollowerReturnUno(beat: uno.beat + Double(uno.beatsPerBar), clock: uno.clock, beatsPerBar: uno.beatsPerBar)
    }

    /// La chiamata col ritorno armato (le condizioni del motore — motore in moto, interruzione bassa, uscita non mancante,
    /// volume a 0, servizi normali — le guarda il motore). Con un «uno»: se il buffer non lo porta, si aspetta; se lo porta e il
    /// primo campione a volume 1 non è prima della scadenza, il volume torna; se è prima, all'«uno» della battuta dopo, con la
    /// stessa scadenza. Senza un «uno» calcolabile: il volume torna alla prima chiamata in cui il primo campione non è prima
    /// della scadenza. A421 · SEGUITO 2 (par. 5.1, F1): in una chiamata che salta la correzione (`skipsCorrection`, la finestra
    /// «sync skip») il volume non torna: con l'«uno» raggiunto si passa alla battuta dopo, senza «uno» si aspetta.
    static func followerReturnStep(bufferOutputTicks: UInt64,
                                   bufferTicks: UInt64,
                                   unoTicks: UInt64?,
                                   deadlineTicks: UInt64,
                                   firstSampleTicks: UInt64,
                                   skipsCorrection: Bool = false) -> FollowerReturnStep {
        let mayReturn = volumeMayReturn(firstSampleTicks: firstSampleTicks, deadlineTicks: deadlineTicks)
        guard let uno = unoTicks else {
            if skipsCorrection { return .wait }
            return mayReturn ? .restore : .wait
        }
        guard bufferReachesUno(bufferOutputTicks: bufferOutputTicks, bufferTicks: bufferTicks, unoTicks: uno) else {
            return .wait
        }
        if skipsCorrection { return .nextBarInWindow }
        return mayReturn ? .restore : .nextBar(earlyTicks: deadlineTicks - firstSampleTicks)
    }

    // === A421 · SEGUITO 2 (30/10/2026) — IL RITORNO DOPO IL BUCO, LA SCADENZA RILETTA, LA FINESTRA, IL LIMITE SENZA «UNO» ===
    // Mandato «A421 · SEGUITO 2», par. 4.4, 5.1, 5.2, 5.5. Dopo un buco del render il volume (a 0 dal guardiano o dalla chiamata
    // del buco) torna alla prima chiamata in cui il primo campione a volume 1 nel caso peggiore non è prima della scadenza — la
    // fine d'uscita dei buffer programmati fino alla chiamata dell'armo più la coda del click — senza aspettare l'«uno» (la «B»
    // di Mauro: un colpo saltato è meglio di una battuta di silenzio; anche per il Follower, decisione del referee). La scadenza
    // si rilegge a ogni chiamata e non scende mai: un altro buco dopo l'armo, anche uno che il misuratore mette nella base, la
    // sposta con sé. La stessa rilettura vale per la parte dei buffer del ritorno del Follower (E.8).

    /// Par. 4.4 — la fine d'uscita dei buffer programmati alla chiamata dell'armo, riletta adesso e mai in discesa:
    /// max(quella di prima, la fine dei buffer programmati di questa chiamata meno i buffer programmati dall'armo). `buffersSinceArm`
    /// = il `bufferCount` all'inizio di questa chiamata meno quello all'inizio della chiamata dell'armo.
    static func rereadProgrammedEndTicks(previous: UInt64, nextBufferOutputTicks: UInt64, queuedAhead: Int,
                                         bufferTicks: UInt64, buffersSinceArm: Int) -> UInt64 {
        let endNow = programmedEndOutputTicks(nextBufferOutputTicks: nextBufferOutputTicks, queuedAhead: queuedAhead,
                                              bufferTicks: bufferTicks)
        let (back, overflow) = bufferTicks.multipliedReportingOverflow(by: UInt64(max(buffersSinceArm, 0)))
        let endAtArm: UInt64 = (overflow || back > endNow) ? 0 : endNow - back
        return max(previous, endAtArm)
    }

    /// Par. 4.4 — la scadenza del ritorno dopo il buco: la fine dei buffer programmati (riletta) più la coda del click.
    static func gapReturnDeadlineTicks(programmedEndOutputTicks: UInt64, ticksPerSecond: Double) -> UInt64 {
        ticks(programmedEndOutputTicks, plusSeconds: clickTailSeconds, ticksPerSecond: ticksPerSecond)
    }

    /// Par. 4.4 — la chiamata col ritorno dopo il buco armato (le condizioni del motore le guarda il motore): mai in una chiamata
    /// che salta la correzione; il volume torna quando il primo campione a volume 1 non è prima della scadenza, salvo che la
    /// memoria dica esterna e un'esterna non ci sia (`externalVanished`): allora si aspetta la notizia o la riserva.
    static func gapReturnStep(firstSampleTicks: UInt64, deadlineTicks: UInt64, skipsCorrection: Bool,
                              externalVanished: Bool) -> GapReturnStep {
        guard !skipsCorrection, volumeMayReturn(firstSampleTicks: firstSampleTicks, deadlineTicks: deadlineTicks) else { return .wait }
        return externalVanished ? .externalVanished : .restore
    }

    /// Par. 5.1 (F1) — la prima correzione dopo la finestra sposta la posizione di almeno un buffer, a meno di un numero intero
    /// di battiti (a un cambio di metro il battito di Link può cambiare solo nome): conta la distanza della correzione dall'intero
    /// più vicino. Con un ritorno armato, il ritorno si riarma e il volume non torna prima.
    static func correctionMovesAtLeastABuffer(beforeBeat: Double, afterBeat: Double, bpm: Double, bufferSeconds: Double) -> Bool {
        guard beforeBeat.isFinite, afterBeat.isFinite, bpm > 0, bpm.isFinite, bufferSeconds > 0, bufferSeconds.isFinite else {
            return false
        }
        let delta = afterBeat - beforeBeat
        let fraction = abs(delta - delta.rounded())
        return fraction * 60.0 / bpm >= bufferSeconds
    }

    /// Par. 5.2 (E.1) — il ritorno del Follower senza un «uno» calcolabile resta prenotato e le due ore si rifanno alla prima
    /// chiamata con l'«uno» calcolabile (la scelta (a) di Mauro: il click torna sull'«1» della band). Il limite: se una battuta
    /// intera dopo la scadenza l'«uno» non è ancora calcolabile, vale la regola di oggi (il volume alla prima chiamata col primo
    /// campione alla scadenza o dopo). `barTicks`: una battuta al tempo del motore.
    static func noUnoLimitReached(nowTicks: UInt64, deadlineTicks: UInt64, barTicks: UInt64) -> Bool {
        let (limit, overflow) = deadlineTicks.addingReportingOverflow(barTicks)
        return !overflow && nowTicks >= limit
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
