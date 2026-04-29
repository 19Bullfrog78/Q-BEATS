import Foundation

struct Section: Codable, Identifiable {
    var id: UUID
    var name: String
    var bpm: Double
    var beatsPerBar: UInt32
    var beatUnit: UInt32
    var repetitions: Int      // -1 = loop infinito (sentinel, non genericamente < 0)
    var notes: String
    var accentPattern: [UInt8]
    var subdivisionMultiplier: UInt8
    var swingRatio: Double

    init(
        id: UUID = UUID(),
        name: String,
        bpm: Double,
        beatsPerBar: UInt32,
        beatUnit: UInt32 = 4,
        repetitions: Int,
        notes: String,
        accentPattern: [UInt8],
        subdivisionMultiplier: UInt8,
        swingRatio: Double
    ) {
        self.id = id
        self.name = name
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
        self.repetitions = repetitions
        self.notes = notes
        self.accentPattern = accentPattern
        self.subdivisionMultiplier = subdivisionMultiplier
        self.swingRatio = swingRatio
    }

    // Backward-compatible decode: old JSON senza beatUnit riceve default 4
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                    = try c.decode(UUID.self,    forKey: .id)
        name                  = try c.decode(String.self,  forKey: .name)
        bpm                   = try c.decode(Double.self,  forKey: .bpm)
        beatsPerBar           = try c.decode(UInt32.self,  forKey: .beatsPerBar)
        beatUnit              = try c.decodeIfPresent(UInt32.self, forKey: .beatUnit) ?? 4
        repetitions           = try c.decode(Int.self,     forKey: .repetitions)
        notes                 = try c.decode(String.self,  forKey: .notes)
        accentPattern         = try c.decode([UInt8].self, forKey: .accentPattern)
        subdivisionMultiplier = try c.decode(UInt8.self,   forKey: .subdivisionMultiplier)
        swingRatio            = try c.decode(Double.self,  forKey: .swingRatio)
    }
}

extension Section {
    static func makeDefault() -> Section {
        Section(
            id: UUID(),
            name: "Sezione",
            bpm: 120.0,
            beatsPerBar: 4,
            beatUnit: 4,
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
