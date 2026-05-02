import Foundation

struct TapTempoEngine {
    private let maxTaps: Int = 8
    private let timeoutSeconds: Double = 2.0
    private let minBPM: Double = 40.0
    private let maxBPM: Double = 250.0

    private var timestamps: [Date] = []

    mutating func tap() -> Double? {
        let now = Date()

        if let last = timestamps.last,
           now.timeIntervalSince(last) > timeoutSeconds {
            timestamps.removeAll()
        }

        timestamps.append(now)

        if timestamps.count > maxTaps {
            timestamps.removeFirst()
        }

        guard timestamps.count >= 2 else { return nil }

        var totalInterval: Double = 0
        for i in 1..<timestamps.count {
            totalInterval += timestamps[i].timeIntervalSince(timestamps[i-1])
        }
        let avgInterval = totalInterval / Double(timestamps.count - 1)
        let bpm = 60.0 / avgInterval

        guard bpm >= minBPM && bpm <= maxBPM else {
            timestamps.removeAll()
            return nil
        }

        return bpm
    }

    mutating func reset() {
        timestamps.removeAll()
    }
}
