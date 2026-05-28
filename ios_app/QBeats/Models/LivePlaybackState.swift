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
    case waitingForDirector
}
