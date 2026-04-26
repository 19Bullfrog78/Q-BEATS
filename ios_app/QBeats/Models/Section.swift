import Foundation

struct Section: Codable, Identifiable {
    var id: UUID
    var name: String
    var bpm: Double
    var beatsPerBar: UInt32
    var repetitions: Int      // -1 = loop infinito (sentinel, non genericamente < 0)
    var notes: String
    var accentPattern: [UInt8]
    var subdivisionMultiplier: UInt8
    var swingRatio: Double
}

extension Section {
    static func makeDefault() -> Section {
        Section(
            id: UUID(),
            name: "Sezione",
            bpm: 120.0,
            beatsPerBar: 4,
            repetitions: 1,
            notes: "",
            accentPattern: [1, 0, 0, 0],
            subdivisionMultiplier: 1,
            swingRatio: 0.5
        )
    }

    var estimatedDurationSeconds: Double {
        guard repetitions > 0 else { return 0 }
        return (60.0 / bpm) * Double(beatsPerBar) * Double(repetitions)
    }
}
