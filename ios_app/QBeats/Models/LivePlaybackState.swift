import Foundation

enum LivePlaybackState: Equatable {
    case standby(nextSongName: String)
    case countIn(countdown: Int)
    case playing
    case stopped
    case loopActive
    case overlayStop(sectionName: String, songName: String)
    case fineSetlist
}
