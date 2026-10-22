import Foundation

// === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: LA FREQUENZA DI CAMPIONAMENTO, UNA FONTE SOLA ===
// Il fatto (referto A415, §4.1-§4.4). Dentro l'app la frequenza aveva più copie, scritte da mani diverse in momenti
// diversi: la copia del motore (`AudioEngine.sampleRate`, che dà il formato ai nodi e a ogni buffer), quella del DSP
// (`metronome_set_sample_rate`, scritta solo all'avvio dell'app e dopo il reset dei servizi audio), i campioni del click
// (fatti solo lì), la durata del buffer chiesta alla sessione (dalla copia del motore) e una copia nel ponte del tap che
// nessuno leggeva. Dopo un cambio d'uscita la copia del motore e i nodi seguivano la sessione e il DSP no: col DSP a
// 48000 e i nodi a 44100 il click del Direttore e del Solo andrebbe al 91,9 % del tempo (A415 §4.4); il Follower si
// salvava con una correzione a ogni buffer.
//
// La regola (mandato del referee «USCITA-AUDIO-PASSO-1», §2.1):
//  · la fonte è il formato d'uscita del nodo d'uscita del motore, `engine.outputNode.outputFormat(forBus: 0)`. Apple
//    (pagine di `AVAudioEngine.outputNode` e di `AVAudioOutputNode`): è il formato dell'hardware quando il nodo è
//    collegato all'hardware, e una frequenza (o un numero di canali) a zero vuol dire uscita non abilitata. Se vale
//    zero, la frequenza della sessione (`AVAudioSession.sampleRate`); se vale zero anche quella, la copia resta com'è;
//  · una funzione sola del motore (`applySampleRateQ`, su audioQueue) porta la frequenza scelta a tutte le copie nello
//    stesso momento: la copia del motore, il DSP, i campioni del click, la durata del buffer chiesta (512 campioni alla
//    frequenza scelta). Il sequencer MIDI la segue già a ogni buffer, dalla copia del motore;
//  · il DSP conta le posizioni in campioni (`MetronomeDSP::setSampleRate` cambia il numero e basta): si scrive solo a
//    motore fermo, e ogni avvio e ogni rientro riscrivono poi la posizione. A motore in moto con una copia diversa
//    niente si scrive: chi chiama ferma il motore e ricostruisce. Chi riparte e come lo decidono le regole di A412
//    (`CrisisStopDecision`, `RecoveryDecision`);
//  · la frequenza preferita della sessione resta 48000, il valore con cui la copia del motore nasce.
// «Motore in moto» qui è `isRunning` del motore (la catena dei buffer): `scheduleNextBuffer`, l'unico che fa lavorare il
// DSP, gira solo con lui vero, sulla stessa coda di `applySampleRateQ`.
// Due frequenze a meno di mezzo hertz l'una dall'altra sono la stessa (nessuna ricostruzione per un arrotondamento).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Da dove viene la frequenza scelta, col nome che va nella riga [FORMATO].
enum SampleRateSource: String, Equatable {
    /// Il formato d'uscita del nodo d'uscita del motore.
    case output = "uscita"
    /// La frequenza della sessione (il nodo d'uscita dava zero).
    case session = "sessione"
    /// Nessuna delle due: resta la copia del motore. (Il nome non è `none`, che si confonderebbe con quello degli
    /// opzionali.)
    case noSource = "nessuna"
}

/// Che cosa fa `applySampleRateQ`, col nome che va nella riga [FORMATO].
enum SampleRateAction: String, Equatable {
    /// Tutte le copie hanno già la frequenza scelta.
    case unchanged = "invariata"
    /// Motore fermo: le copie diverse si riscrivono adesso.
    case apply = "aggiornata"
    /// Motore in moto con la copia del motore, il DSP o i campioni del click diversi dalla frequenza scelta: niente si
    /// scrive; chi chiama ferma il motore e ricostruisce.
    case stopAndRebuild = "fermare-e-ricostruire"
}

enum SampleRateDecision {

    /// La frequenza preferita chiesta alla sessione, e quella con cui nasce la copia del motore (mandato §2.1).
    static let preferredSampleRate: Double = 48000
    /// I campioni di un buffer del motore (`AudioEngine.bufferSize`): la durata del buffer chiesta alla sessione.
    static let bufferFrames: Int = 512
    /// Sotto questa distanza due frequenze sono la stessa.
    static let sameRateToleranceHz: Double = 0.5

    /// Le letture, su audioQueue, al momento della chiamata. `click` e `ioBuffer`: la frequenza con cui sono stati fatti
    /// i campioni del click e quella dell'ultima durata del buffer chiesta (0 = mai).
    struct Reading: Equatable {
        let output: Double
        let session: Double
        let copy: Double
        let dsp: Double
        let click: Double
        let ioBuffer: Double
        let engineRunning: Bool
    }

    struct Outcome: Equatable {
        /// La frequenza scelta.
        let rate: Double
        let source: SampleRateSource
        let action: SampleRateAction
        /// Le copie da riscrivere adesso (tutte false se `action` non è `apply`).
        let rewritesCopy: Bool
        let rewritesDSP: Bool
        let regeneratesClick: Bool
        let requestsIOBuffer: Bool

        /// Il grafo va ricollegato coi formati nuovi: la copia del motore cambia, e i formati dei nodi la seguono.
        var reconnectsGraph: Bool { rewritesCopy }
    }

    /// Una frequenza che si può usare.
    static func isUsable(_ hz: Double) -> Bool {
        hz > 0 && hz.isFinite
    }

    /// Due frequenze uguali, a meno di mezzo hertz.
    static func same(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < sameRateToleranceHz
    }

    /// La fonte: il nodo d'uscita, poi la sessione, poi la copia del motore. Una copia che non si può usare (non succede:
    /// nasce 48000 e si scrive solo con valori usabili) cede alla preferita, mai a zero: il DSP dividerebbe per zero.
    static func chosenRate(output: Double, session: Double, copy: Double) -> (rate: Double, source: SampleRateSource) {
        if isUsable(output) { return (output, .output) }
        if isUsable(session) { return (session, .session) }
        return (isUsable(copy) ? copy : preferredSampleRate, .noSource)
    }

    /// La regola.
    static func outcome(_ reading: Reading) -> Outcome {
        let chosen = chosenRate(output: reading.output, session: reading.session, copy: reading.copy)
        let copyDiffers = !same(chosen.rate, reading.copy)
        let dspDiffers = !same(chosen.rate, reading.dsp)
        let clickDiffers = !same(chosen.rate, reading.click)
        let ioDiffers = !same(chosen.rate, reading.ioBuffer)
        let action: SampleRateAction
        if reading.engineRunning {
            // A motore in moto la durata del buffer da sola non ferma niente: si chiede alla prossima chiamata a motore fermo.
            action = (copyDiffers || dspDiffers || clickDiffers) ? .stopAndRebuild : .unchanged
        } else {
            action = (copyDiffers || dspDiffers || clickDiffers || ioDiffers) ? .apply : .unchanged
        }
        let writes = action == .apply
        return Outcome(rate: chosen.rate,
                       source: chosen.source,
                       action: action,
                       rewritesCopy: writes && copyDiffers,
                       rewritesDSP: writes && dspDiffers,
                       regeneratesClick: writes && clickDiffers,
                       requestsIOBuffer: writes && ioDiffers)
    }

    /// La durata del buffer da chiedere alla sessione: 512 campioni alla frequenza scelta (Apple: la durata si chiede, e
    /// quella vera si legge dopo). `nil` per una frequenza che non si può usare.
    static func ioBufferDuration(rate: Double) -> Double? {
        isUsable(rate) ? Double(bufferFrames) / rate : nil
    }
}
