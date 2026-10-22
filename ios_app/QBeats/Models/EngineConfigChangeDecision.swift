import Foundation

// === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: IL CAMBIO DI CONFIGURAZIONE DEL MOTORE, UNA REGOLA DI STATO ===
// Il fatto (referto A415, §4.3, §4.7 e §4.9). Apple (pagina di `AVAudioEngineConfigurationChangeNotification`): quando
// l'unità d'ingresso/uscita del motore vede cambiare la frequenza o i canali dell'hardware, il motore si ferma, si
// disinizializza e manda la notifica; i nodi restano collegati coi formati di prima, e tocca all'app ricollegarli.
// Fino ad A415 il gestore (`AudioEngine.handleEngineConfigChange`), oltre alla guardia di stato, aveva due uscite che
// lasciavano il motore fermo con `isRunning` vero, senza crisi e senza ripartenza:
//  · «SR mismatch … skip»: la frequenza della sessione diversa dalla copia del motore (il 19/10 alle 10:51:00 la
//    sessione dava ancora la frequenza vecchia mentre l'uscita andava già a 48 kHz);
//  · «Config change post-interruption skip»: nei 20 s dopo la ripresa da un'interruzione.
// L'origine dei 20 s (ritrovata nella storia, mandato §2.2): commit `7c0a8aa6875b1cd836b7ea3c0d12a3b5991aea28`
// del 22/04/2026, «[BUILD #148] AudioEngine: Temporal guard for anti-double snap». Il motivo sta nel BOX4 V2 e V3 del
// 23/04/2026 (Blocco 7, «Sequenza Eventi VoIP», fuori dal deposito: `ARCHIVIO.MD/Aprile/23_04_2026/`): alla fine di una
// chiamata iOS manda due cambi di configurazione, il primo alla frequenza della chiamata e il secondo, 8-12 s dopo, a
// 48 kHz; la ripresa dopo la chiamata aveva già fatto ripartire il click con lo scatto alla battuta («snap»), e il
// secondo cambio lo avrebbe fatto ripartire una seconda volta, con un secondo scatto. I 20 s dovevano evitare la
// ripartenza doppia. Ma il gestore arriva oltre la guardia di stato solo col motore già fermo (`isRunning` vero e
// `engine.isRunning` falso): saltare lì non toglieva una ripartenza doppia, lasciava il click muto.
//
// La regola (mandato «USCITA-AUDIO-PASSO-1», §2.2), solo stato e nessun orologio:
//  · motore fermo e `isRunning` vero: si riparte sempre (la ripresa pendente, se c'è, o la ripartenza di sempre). Il
//    gestore prima abbassa `isRunning` sulla coda del motore (l'arresto esplicito, con la regola delle crisi di A412),
//    poi ricostruisce e riparte da `activateSessionAndStart` (`RecoveryDecision`);
//  · una ripartenza già in corso non si raddoppia: una seconda notifica per lo stesso arresto trova `isRunning` basso
//    e si ignora con la sua riga; i tentativi ripetuti di `activateSessionAndStart` hanno il gettone di sempre
//    (`currentResumeToken`), e `start()` non parte due volte (la sua guardia `!isRunning`);
//  · la notifica di un motore che non è quello corrente si ignora (A408); fuori da «normale» (reset dei servizi audio)
//    niente lavoro sul motore vecchio (A408).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Che cosa fa il gestore del cambio di configurazione.
enum EngineConfigChangeOutcome: String, Equatable, CaseIterable {
    /// La notifica è di un motore che non è quello corrente (dopo la ricostruzione del reset): si ignora.
    case notCurrentEngine = "motore-non-corrente"
    /// Il motore non è fermo con `isRunning` vero: niente da far ripartire (il motore gira, o è fermo per scelta, o una
    /// ripartenza è già in corso). Una riga.
    case ignored = "ignorato"
    /// Fuori da «normale»: la strada del reset dei servizi audio (A408). La riga la scrive `mediaResetSkipsQ`.
    case mediaReset = "reset-dei-servizi"
    /// Motore fermo con `isRunning` vero e una ripresa pendente: arresto esplicito, ricostruzione, ripresa pendente.
    case recoverPending = "ripresa-pendente"
    /// Motore fermo con `isRunning` vero: arresto esplicito, ricostruzione, ripartenza.
    case restart = "ripartenza"

    /// Il gestore riparte (e prima abbassa `isRunning`).
    var restarts: Bool {
        self == .recoverPending || self == .restart
    }
}

enum EngineConfigChangeDecision {

    /// La regola. Nessun ingresso è un tempo.
    static func outcome(senderIsCurrent: Bool,
                        stateRunning: Bool,
                        engineRunning: Bool,
                        audioWorkAllowed: Bool,
                        pendingResume: Bool) -> EngineConfigChangeOutcome {
        guard senderIsCurrent else { return .notCurrentEngine }
        guard stateRunning, !engineRunning else { return .ignored }
        guard audioWorkAllowed else { return .mediaReset }
        return pendingResume ? .recoverPending : .restart
    }

    /// `isRunning` dopo il passo del gestore: chi riparte lo abbassa prima, sulla coda del motore.
    static func stateRunningAfter(_ outcome: EngineConfigChangeOutcome, stateRunning: Bool) -> Bool {
        outcome.restarts ? false : stateRunning
    }
}
