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
}
