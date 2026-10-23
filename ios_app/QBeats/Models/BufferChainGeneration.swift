import Foundation

// === A420 (23/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 1: LA CATENA DEI BUFFER HA UN NUMERO ===
// Il fatto (BUGS, `TD-catena-dei-buffer-doppia`; referto A407, §6.7; referto A419, §3.4; referto A420, §1). Il lettore
// del click lavora a catena: tre buffer in coda quando una catena comincia, e il richiamo di fine di ogni buffer, accodato
// sulla coda del motore, programma il buffer dopo (`AudioEngine.scheduleNextBuffer`). Il richiamo arriva anche quando il
// lettore si ferma (Apple, `scheduleBuffer(_:completionHandler:)`). Fino ad A419 il richiamo non sapeva di quale catena
// era, e `scheduleNextBuffer` guardava solo `isRunning`: un richiamo della catena di prima arrivato dopo un avvio (uno Stop
// e un Play vicinissimi, il lettore vecchio dopo la ricostruzione del reset, l'attesa fra l'avvio del motore e il fuoco di
// un ingresso o di un rientro) programmava un buffer in più, e la catena diventava doppia, o nasceva prima del fuoco. Mai
// visto sul telefono: viene dalla lettura del codice.
//
// La regola (mandato A420, par. 2.2, con la risposta del referee del 23/10, par. 1), l'invariante:
//  · ogni passaggio di `isRunning` da falso a vero apre una generazione (in `start()`, accanto a `isRunning = true`, dopo
//    `engine.start()` riuscito);
//  · dentro un avvio, ogni catena che comincia ne apre un'altra, prima del primo dei suoi tre buffer (la ripresa e il ramo
//    standalone/Direttore di `start()`, il fuoco dell'ingresso del Follower, il fuoco del rientro del Direttore,
//    `kickScheduling`);
//  · un richiamo con una generazione diversa dalla corrente si scarta senza programmare niente, e si conta. Ogni buffer
//    porta nel suo richiamo la generazione con cui è stato programmato.
// Una generazione in più non scarta mai un richiamo buono: dove si apre, nessuna catena della generazione di prima è viva
// (all'avvio `isRunning` era falso, e lo stop del lettore, sulla coda nello stesso blocco che l'ha abbassato, ha tolto ogni
// buffer in programma; nei rami che programmano subito i loro buffer le due salite cadono nello stesso blocco, senza niente
// in mezzo). La riga dello scarto: al primo, poi una ogni dieci (1, 11, 21, …).
// ⚠️ Non è la generazione dell'ingresso armato (`AudioEngine.joinGeneration`), che scarta i fuochi orfani: le righe di
// quella dicono «generazione:», quella dello scarto di questa dice «catena:».
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum BufferChainGeneration {

    /// La generazione con cui nasce il motore.
    static let initial: Int = 0
    /// Ogni quanti scarti una riga, dopo la prima.
    static let discardLineEvery: Int = 10

    /// La generazione nuova dopo `current` (un passaggio di `isRunning` da falso a vero, o una catena che comincia).
    static func opened(after current: Int) -> Int {
        current &+ 1
    }

    /// Il richiamo di un buffer programmato con `callbackGeneration` si accetta solo se è la generazione corrente.
    static func accepts(callbackGeneration: Int, current: Int) -> Bool {
        callbackGeneration == current
    }

    /// La riga dello scarto numero `discarded` (contato da 1): la prima, poi una ogni dieci.
    static func writesDiscardLine(discarded: Int) -> Bool {
        discarded > 0 && (discarded - 1) % discardLineEvery == 0
    }
}
