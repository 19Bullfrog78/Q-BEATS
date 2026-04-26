import Foundation

#if DEBUG
extension Section {
    static var preview: Section {
        Section(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
            name: "Intro",
            bpm: 100.0,
            beatsPerBar: 4,
            repetitions: 2,
            notes: "",
            accentPattern: [1, 0, 0, 0],
            subdivisionMultiplier: 1,
            swingRatio: 0.5
        )
    }
}

extension Song {
    static var preview: Song {
        Song(
            id: UUID(uuidString: "22222222-0000-0000-0000-000000000001")!,
            name: "Superstition",
            sections: [
                Section(
                    id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
                    name: "Intro",
                    bpm: 100.0,
                    beatsPerBar: 4,
                    repetitions: 2,
                    notes: "",
                    accentPattern: [1, 0, 0, 0],
                    subdivisionMultiplier: 1,
                    swingRatio: 0.5
                ),
                Section(
                    id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
                    name: "Verse",
                    bpm: 100.0,
                    beatsPerBar: 4,
                    repetitions: 4,
                    notes: "",
                    accentPattern: [1, 0, 0, 0],
                    subdivisionMultiplier: 1,
                    swingRatio: 0.5
                )
            ],
            countIn: 1,
            backtrackFilename: nil
        )
    }
}

extension Setlist {
    static var preview: Setlist {
        Setlist(
            id: UUID(uuidString: "33333333-0000-0000-0000-000000000001")!,
            name: "Concerto Milano",
            date: Date(),
            songIDs: [UUID(uuidString: "22222222-0000-0000-0000-000000000001")!]
        )
    }
}
#endif
