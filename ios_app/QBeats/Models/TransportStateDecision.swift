import Foundation

// === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: isPlaying È LO SPECCHIO DI isRunning (par. 2.2 e) ===
// Il fatto (BUGS, `TD-isplaying-resta-vero-dopo-lo-stop-del-direttore-muto`; registro dell'iPhone del 24/10 delle 12:57).
// Dopo lo Stop voluto col Direttore muto in canzone a motore fermo `isPlaying` restava vero fino al Play dopo: la politica
// dello sfondo leggeva «click:1» e non sospendeva Link, il pedale playPause faceva `stop()` (cioè niente). Le cause: la
// ripartenza per la frequenza e il ramo del modo abbassavano `isRunning` senza toccare `isPlaying`; lo Stop voluto a motore
// fermo usciva da `stopSync` prima di `isPlaying = false`; le uscite di `start()` senza avvio, la fine canzone nel silenzio
// e T6 scrivevano solo `playbackState`.
//
// La regola (mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 2.2 e): `isPlaying` è lo specchio di `isRunning`. Lo pubblica
// una mano sola, dalla coda, a ogni passaggio di `isRunning` e a ogni uscita di `start()` senza avvio; uno Stop voluto lo
// mette falso anche a motore già fermo. Il Follower muto per l'uscita mancante ha il motore in moto: `isPlaying` resta vero
// (in sfondo Link non si sospende, e il ritorno resta possibile). Il ritorno in primo piano (`handleAppWakeUp`) leggeva
// «`isPlaying` vero a motore fermo» come «il click suonava»: con lo specchio non succede più, e la guardia dice quello che
// serve davvero: le due strade che ci contavano, la ripresa pendente e il Direttore muto in canzone (D5).
// ⚠️ RISCRITTO A421 dopo la verifica indipendente del diff. La prima stesura faceva passare anche «una causa di crisi viva»:
// il Direttore fuori da una canzone fermato da una tolta (U16) ha la causa viva finché non riparte, e con l'uscita tornata
// `RecoveryDecision` direbbe «come oggi»: al risveglio sarebbe ripartito da solo, e con lui la band (`link_engine_start_at_beat`),
// contro U16 («riparte col Play»). Lo stesso il Follower fermato da un'interruzione: un risveglio durante la chiamata
// avrebbe fatto una `setActive` dentro l'interruzione. La causa viva NON è una ragione per riprovare.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

enum TransportStateDecision {

    /// Lo specchio: `isPlaying` vale `isRunning`.
    static func isPlaying(engineRunning: Bool) -> Bool {
        engineRunning
    }

    /// Il ritorno in primo piano prova una ripartenza automatica solo con il motore fermo e una strada valida che ci contava:
    /// la ripresa pendente, o il Direttore muto in canzone. A motore in moto, o fermo per uno Stop o per una crisi che
    /// aspetta il Play (U16, il Solo), niente.
    static func wakeupRecovers(engineRunning: Bool,
                               pendingResume: Bool,
                               silentInSong: Bool) -> Bool {
        guard !engineRunning else { return false }
        return pendingResume || silentInSong
    }
}
