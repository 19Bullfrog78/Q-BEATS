import Foundation

// === A432, parte 2a (12/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: IL PRECARICO COL NUMERO DELLA SEZIONE (P41) ===
// Il fatto (referto A431, par. 2.3; VERIFICA_REFEREE_A431, par. 3.1, P41). Allo scambio di sezione il motore manda
// sul thread principale la chiusura del runner, che avanza l'indice e precarica «la sezione dopo» con un blocco
// sulla coda del motore. Se nel frattempo un riallineo (o un rientro) ha portato il motore in un'altra sezione,
// quel precarico arriva dopo e riscrive quello giusto: al confine seguente il motore caricherebbe la sezione
// sbagliata.
// La regola: il precarico porta il numero della sezione che precarica, e il motore lo prende solo se è la sezione
// dopo quella che conta adesso. Senza mappa (il motore non conta le sezioni: indice negativo) passa sempre, com'è
// oggi. Un precarico in ordine passa sempre; uno vecchio, dopo un riallineo in avanti o all'indietro, no.
// Il tipo è solo la regola. Dalla parte 2b la chiama il motore, sulla sua coda, in `AudioEngine.preloadNextSection`
// (il runner passa il numero della sezione che precarica, `forSection`).
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum SectionPreloadDecision {

    /// Il motore prende il precarico della sezione `preloadSection` (da 0) mentre conta la sezione
    /// `engineSection` (da 0; negativo = nessuna mappa)?
    static func accepts(preloadSection: Int, engineSection: Int) -> Bool {
        if engineSection < 0 { return true }
        return preloadSection == engineSection + 1
    }
}
