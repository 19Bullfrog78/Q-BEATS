import Foundation

enum MIDIEventType: String, Codable {
    case cc, note
}

enum MIDIAction: String, Codable, CaseIterable, Identifiable {
    case playPause       = "Play/Pause"
    case stop            = "Stop"
    case nextSection     = "Next Section"
    case prevSection     = "Prev Section"
    case nextSong        = "Next Song"
    case startSong       = "Start Song"
    case tapTempo        = "Tap Tempo"
    case loopToggle      = "Loop Toggle"
    case stopBacktrack   = "Stop Backtrack"
    case muteClickToggle = "Mute Click Toggle"

    var id: String { rawValue }
}

struct MIDILearnMapping: Codable, Equatable {
    var channel: UInt8       // 0 = any channel
    var type: MIDIEventType
    var number: UInt8        // CC number o Note number
}
