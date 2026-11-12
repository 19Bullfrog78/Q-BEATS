import Foundation

// === A432, parte 2a (12/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: IL MESSAGGIO DEL RIALLINEO DI SEZIONE (P10) ===
// Il fatto (referto A424, par. 3.3 b, passo 4; referto A431, par. 3.1 h). Quando il riallineo del Follower cambia
// sezione, la vista deve sapere a quale tick comincia la sezione nuova: oggi prende per «battuta 1» il primo tick
// che vede dopo il cambio. Il motore le manderà questo messaggio, dopo aver mosso il runner: la sezione, il
// prossimo tick e il battito della sezione che quel tick porta.
// Il tipo è solo il messaggio, con l'identità che la vista usa già (`sectionStartTick = tick − sectionBeat + 1`):
// in questa parte (2a) nessun codice dell'app lo manda né lo riceve.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

struct SectionRealign: Equatable {
    /// L'indice della sezione in cui sta la band (da 0).
    let sectionIdx: Int
    /// Il prossimo tick dei battiti del motore: quello del battito in attesa.
    let nextTick: Int
    /// Il battito nella sezione che quel tick porta, da 1.
    let sectionBeat: Int

    /// Il tick del primo battito della sezione.
    var sectionStartTick: Int { nextTick - sectionBeat + 1 }
}
