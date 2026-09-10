import Foundation

enum LivePlaybackState: Equatable {
    case standby(nextSongName: String)
    case countIn(countdown: Int)
    case playing
    case stopped
    case loopActive
    case overlayStop(sectionName: String, songName: String)
    case fineSetlist
    // CD-6 (27/05/2026) — Follower Collaborativo in attesa che il Director
    // cross-device prema Play. Entrato quando l'utente tappa Play in Vista LIVE
    // con `linkMode == .collaborativa`. Uscita: (a) Director starta → callback
    // Link emette `linkStartedSubject` → LiveView observer transita a .playing
    // via runner.startSetlist; (b) tap START LOCAL nella WaitingForDirectorView
    // → runner.startSetlist locale; (c) tap CANCEL → dismiss UIHostingController
    // a Bivio. CD-Q2=B ratificato libro mastro v14.
    // ⚠️ MARCATURA 23/08 — «Bivio» NON ESISTE PIÙ dopo N1b: l'uscita del
    //    player torna alla lista Shows della stanza. Testo sopra invariato.
    // ⚠️ MARCATURA A240 (28/08) — (a) e (b) NON passano più da `startSetlist`:
    //    l'observer sceglie `startCurrentSong` (standby) o `startCurrentSection`
    //    (conserva il punto); START LOCAL chiama `startCurrentSection`.
    //    Testo sopra invariato.
    case waitingForDirector
    // ⟦A345⟧ (10/09/2026) — AVVIO COMANDATO, MOTORE NON ANCORA IN MOTO. Nono caso,
    //    senza payload: la verita' dei millisecondi fra il comando di avvio e la
    //    prima parola del motore. `start()` differisce tutto a `audioQueue.async`
    //    (`AudioEngine.swift:867`) e pubblica `isPlaying`/`.playing` in un
    //    `main.async` da dentro quella coda (`:1034-1036`): a comando dato il motore
    //    dice ancora «fermo», e un player che si monta in quell'attimo troverebbe la
    //    sessione a `.stopped` e armerebbe il velo (`SetlistRunner.primeDisplay`,
    //    lista di permessi Cond (c)) sopra un click che sta partendo.
    //    CHI LO ACCENDE: SOLO la closure di RESUME della terza faccia del dettaglio
    //    (`QLiveRootView`, `onResume`), scritto PRIMA di `startCurrentSection`.
    //    CHI LO SPEGNE: lo specchio del motore in `LiveView`
    //    (`.onReceive(audioEngine.$playbackState)`, ramo `.playing`), oppure
    //    `QLiveSession.endShow(audioEngine:)`, che scrive `.stopped`.
    //    PERCHE' ESISTE: referto `HANDOFF/MISURE_CC_2026-09-10_A345-RESUME-TERZA-FACCIA.md`
    //    (25.082 byte, sha256 240d0377d0c66a7a7ec06bc2b01b41f719a767ddaa3c5c19dc6c35ab829cf7d5),
    //    §2.2: da `QLiveRootView` sola nessuna forma evita il velo in tutti gli ordini
    //    di montaggio (onAppear/onReceive e tempo del `.playing` non sono sorgentabili);
    //    con uno stato NOMINATO `primeDisplay` non arma (≠ `.stopped`) e la guardia di
    //    `LiveView` scarta il `.stopped` iniziale del motore. Scelta G1 del referee
    //    (10/09): stato dichiarato nella macchina, famiglia di `.countIn`, non un
    //    segnale nascosto nel runner. La lista di permessi di `primeDisplay` NON cambia.
    //    SE `start()` FALLISCE (`AudioEngine.swift:869-873`, `:1079-1084`: nessuno stato
    //    pubblicato) la sessione resta qui: il player si mostra senza velo e il PLAY
    //    del transport rientra da `TransportView.swift:92` (misura A345 parte 2, §2.2).
    case starting
}
