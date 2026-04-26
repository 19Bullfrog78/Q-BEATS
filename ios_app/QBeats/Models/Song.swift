import Foundation

struct Song: Codable, Identifiable {
    var id: UUID
    var name: String
    var sections: [Section]
    var countIn: Int          // 0=nessuno, 1=1 battuta, 2=2 battute
    var backtrackFilename: String?
}

extension Song {
    static func makeDefault() -> Song {
        Song(
            id: UUID(),
            name: "Nuova canzone",
            sections: [Section.makeDefault()],
            countIn: 1,
            backtrackFilename: nil
        )
    }

    var estimatedDurationSeconds: Double {
        sections.reduce(0.0) { $0 + $1.estimatedDurationSeconds }
    }
}
