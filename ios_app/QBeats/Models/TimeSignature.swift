import Foundation

struct TimeSignature: Hashable, Identifiable {
    let numerator: UInt32
    let denominator: UInt32
    let label: String
    let defaultAccentPattern: [UInt8]

    var id: String { label }

    func hash(into hasher: inout Hasher) {
        hasher.combine(numerator)
        hasher.combine(denominator)
    }

    static func == (lhs: TimeSignature, rhs: TimeSignature) -> Bool {
        lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
    }
}

extension TimeSignature {
    // Lista chiusa v1 — 12 time signature
    static let all: [TimeSignature] = [
        // Semplici comuni
        TimeSignature(numerator: 4,  denominator: 4, label: "4/4",  defaultAccentPattern: [1,0,0,0]),
        TimeSignature(numerator: 3,  denominator: 4, label: "3/4",  defaultAccentPattern: [1,0,0]),
        TimeSignature(numerator: 2,  denominator: 4, label: "2/4",  defaultAccentPattern: [1,0]),
        // Semplici meno comuni
        TimeSignature(numerator: 5,  denominator: 4, label: "5/4",  defaultAccentPattern: [1,0,0,1,0]),
        TimeSignature(numerator: 6,  denominator: 4, label: "6/4",  defaultAccentPattern: [1,0,0,1,0,0]),
        TimeSignature(numerator: 7,  denominator: 4, label: "7/4",  defaultAccentPattern: [1,0,0,1,0,1,0]),
        // Composte
        TimeSignature(numerator: 6,  denominator: 8, label: "6/8",  defaultAccentPattern: [1,0,0,1,0,0]),
        TimeSignature(numerator: 9,  denominator: 8, label: "9/8",  defaultAccentPattern: [1,0,0,1,0,0,1,0,0]),
        TimeSignature(numerator: 12, denominator: 8, label: "12/8", defaultAccentPattern: [1,0,0,1,0,0,1,0,0,1,0,0]),
        // Dispari
        TimeSignature(numerator: 5,  denominator: 8, label: "5/8",  defaultAccentPattern: [1,0,1,0,0]),
        TimeSignature(numerator: 7,  denominator: 8, label: "7/8",  defaultAccentPattern: [1,0,0,1,0,1,0]),
        TimeSignature(numerator: 11, denominator: 8, label: "11/8", defaultAccentPattern: [1,0,0,1,0,0,1,0,0,1,0]),
    ]

    static func find(numerator: UInt32, denominator: UInt32) -> TimeSignature? {
        all.first { $0.numerator == numerator && $0.denominator == denominator }
    }

    // Ritorna la time sig corrente di una Section, o nil se non è nella lista chiusa
    static func matching(_ section: Section) -> TimeSignature? {
        find(numerator: section.beatsPerBar, denominator: section.beatUnit)
    }
}
