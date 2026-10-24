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
//    calcoli il buffer dell'«uno» (U3 c): all'ora di rendering di quel buffer, che precede l'ora d'uscita della latenza;
//  · il tocco «altoparlante» (par. 2.2 g): lo stesso ritorno, con la sola ora «0,3 s dopo il tocco»;
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

    /// La seconda ora del Follower: la fine d'uscita dei buffer programmati più la coda del click.
    static func followerDeadlineTicks(noticeTicks: UInt64, programmedEndOutputTicks: UInt64, ticksPerSecond: Double) -> UInt64 {
        let byNotice = ticks(noticeTicks, plusSeconds: followerMinimumSeconds, ticksPerSecond: ticksPerSecond)
        let byBuffers = ticks(programmedEndOutputTicks, plusSeconds: clickTailSeconds, ticksPerSecond: ticksPerSecond)
        return max(byNotice, byBuffers)
    }

    /// Il tocco «altoparlante»: la sola ora «0,3 s dopo il tocco».
    static func tapDeadlineTicks(tapTicks: UInt64, ticksPerSecond: Double) -> UInt64 {
        ticks(tapTicks, plusSeconds: followerMinimumSeconds, ticksPerSecond: ticksPerSecond)
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

    /// L'ora in cui rimettere il volume per il buffer dell'«uno» (U3 c): l'ora di rendering di quel buffer, cioè la sua
    /// ora d'uscita meno la latenza; mai prima di adesso.
    static func raiseTicks(bufferOutputTicks: UInt64, outputLatencyTicks: UInt64, nowTicks: UInt64) -> UInt64 {
        let render = bufferOutputTicks >= outputLatencyTicks ? bufferOutputTicks - outputLatencyTicks : 0
        return max(render, nowTicks)
    }

    /// La riga del motore fermo dal sistema: al richiamo numero `callbacks` (da 1), la prima volta e poi una ogni dieci.
    static func writesStoppedEngineLine(callbacks: Int) -> Bool {
        callbacks > 0 && (callbacks - 1) % stoppedEngineLineEvery == 0
    }
}
