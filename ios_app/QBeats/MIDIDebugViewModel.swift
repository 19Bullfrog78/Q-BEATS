import Foundation

struct MIDILogEntry: Identifiable {
    let id        = UUID()
    let timestamp : String
    let hex       : String
    let decoded   : String
    let rawBytes  : [UInt8]
}

final class MIDIDebugViewModel: ObservableObject {
    @Published var entries: [MIDILogEntry] = []
    private let maxEntries = 200

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    // Chiamare SOLO su DispatchQueue.main.
    func append(data: [UInt8]) {
        let hex     = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        let decoded = MIDIDebugViewModel.decode(data)
        let entry   = MIDILogEntry(
            timestamp: formatter.string(from: Date()),
            hex:       hex,
            decoded:   decoded,
            rawBytes:  data
        )
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    // Chiamare SOLO su DispatchQueue.main.
    func clear() { entries.removeAll() }

    private static func decode(_ data: [UInt8]) -> String {
        guard !data.isEmpty else { return "empty" }
        let status  = data[0]
        switch status {
        case 0xF8: return "Clock F8"
        case 0xFA: return "Start FA"
        case 0xFB: return "Continue FB"
        case 0xFC: return "Stop FC"
        default: break
        }
        let type    = status & 0xF0
        let ch      = (status & 0x0F) + 1
        let b1      = data.count > 1 ? data[1] : 0
        let b2      = data.count > 2 ? data[2] : 0
        switch type {
        case 0x80: return "Note Off ch:\(ch) n:\(b1)"
        case 0x90: return "Note On  ch:\(ch) n:\(b1) v:\(b2)"
        case 0xB0: return "CC       ch:\(ch) cc:\(b1) v:\(b2)"
        default:   return String(format: "0x%02X", status)
        }
    }
}
