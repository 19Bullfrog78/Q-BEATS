import Foundation

// === A425 (04/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3a: LA MAPPA CONSEGNATA A UN AVVIO IN CORSO È DI QUELL'AVVIO (P4) ===
// Il fatto (referto A423, par. 3.1 c; seguito 3 di A421, par. 7 e Aperto A.3; mandato A425, par. 2.2). Il runner consegna la mappa
// della canzone (`setSongMap`: il segno «mappa per il prossimo avvio») e poi chiama `start()`; l'avvio che prosegue senza il
// coordinatore la consuma in «canzone in corso» (`prepareNormalStartQ`). Sul Follower la mappa arriva DOPO il primo `start()`, quello
// della sessione Link: il secondo `start()`, del runner, trova il motore in moto ed esce alla guardia «avvio-gia-in-moto» senza
// consumarla, e il fuoco dell'ingresso la abbassava senza consumarla; «canzone in corso» restava falsa per tutta la canzone, e con
// l'attesa d'ingresso zero (il fuoco prima del blocco di `setSongMap`) il segno restava alto fino a un avvio dopo. Da A425 la mappa
// consegnata a un avvio che trova il motore in moto è di quell'avvio: alla guardia «avvio-gia-in-moto» (solo quando esce perché il
// motore è in moto) e al fuoco dell'ingresso del Follower, col segno alto, «canzone in corso» si alza e il segno si abbassa.
// Qui le mosse del segno e di «canzone in corso». Il motore chiama `normalStart` e `runningStart`; `mapDelivered` e `stopped` sono
// le scritture dirette di `setSongMap` e degli arresti (`stopSync`, lo Stop di fine canzone, la sessione ferma da altri), qui per le
// sequenze del banco.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Il segno della mappa per il prossimo avvio e «canzone in corso» (`_songMapForNextStartQ`, `_songInProgressQ`).
struct SongMapMark: Equatable {
    var mapForNextStart: Bool
    var songInProgress: Bool

    static let initial = SongMapMark(mapForNextStart: false, songInProgress: false)
}

enum SongInProgressDecision {

    /// La consegna della mappa (`setSongMap`): il segno si alza; «canzone in corso» com'è.
    static func mapDelivered(_ mark: SongMapMark) -> SongMapMark {
        SongMapMark(mapForNextStart: true, songInProgress: mark.songInProgress)
    }

    /// L'avvio che prosegue senza il coordinatore (`prepareNormalStartQ`): «canzone in corso» è il segno di questo avvio (falsa
    /// senza mappa) e il segno si abbassa.
    static func normalStart(_ mark: SongMapMark) -> SongMapMark {
        SongMapMark(mapForNextStart: false, songInProgress: mark.mapForNextStart)
    }

    /// P4 — l'avvio in corso (la guardia «avvio-gia-in-moto» col motore in moto, il fuoco dell'ingresso del Follower): col segno
    /// alto la mappa è di questo avvio, «canzone in corso» si alza e il segno si abbassa (`consumed` vero: la riga «mappa consumata
    /// dall'avvio in corso»); col segno basso niente.
    static func runningStart(_ mark: SongMapMark) -> (mark: SongMapMark, consumed: Bool) {
        guard mark.mapForNextStart else { return (mark, false) }
        return (SongMapMark(mapForNextStart: false, songInProgress: true), true)
    }

    /// Lo Stop (`stopSync` per ogni origine, lo Stop di fine canzone, la sessione ferma da altri): «canzone in corso» giù; il segno
    /// com'è.
    static func stopped(_ mark: SongMapMark) -> SongMapMark {
        SongMapMark(mapForNextStart: mark.mapForNextStart, songInProgress: false)
    }
}
