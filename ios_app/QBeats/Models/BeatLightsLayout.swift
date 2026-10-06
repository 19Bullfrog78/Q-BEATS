import Foundation

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LE SPIE DEL BATTITO: MISURA, SPAZIO, FACCE ===
// Fonte: Solo REV18, punto 106 e tavola a) della sezione C: una spia per battito, su una fila sola, mai più
// larga della barra delle battute (354, da 18 a 372), centro a 179; Ø e spazio per numero di battiti: da 2 a 4
// → 46 e 22; 5 e 6 → 46 e 12; 7 → 42 e 10; 9 → 32 e 8; 11 → 26 e 6; 12 → 24 e 6 (le dodici metriche della
// lista chiusa, `TimeSignature.all`). Facce (REV9, tabella delle misure; BOX5 V54, decisione 8): spenta bianco
// .07 con bordo 1,5 bianco .1; accesa verde #28cd41 dove il pattern vale 2 (il motore accenta), bianca per 1 e
// 0, che il motore suona uguali. Stesso contratto di `MetSlotStripView`: il pattern di `displayAccentPattern` e
// `beatActive` della sessione, mai il motore.
// Casi che il foglio non disegna (D6, nel referto «da portare a CD»): 1 battito → Ø 46; 8 e 10 battiti → la
// misura del primo numero disegnato più grande (9: 32 e 8; 11: 26 e 6); oltre 12 → spazio 6 e la spia che ci
// sta, mai oltre 24; se nemmeno lo spazio 6 ci sta, spazio e spia uguali, 354/(2n − 1). La funzione è totale e
// la fila non supera mai 354.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum BeatLightFace: Equatable {
    /// Verde: il pattern vale 2.
    case accent
    /// Bianco: il pattern vale 1 o 0.
    case beat
}

struct BeatLightsLayout: Equatable {
    static let rowWidth: Double = 354
    /// La riga delle spie nel foglio: 156-202, centro a 179 (dall'alto, barra di stato compresa).
    static let sheetCenterY: Double = 179
    static let maxDiameter: Double = 46
    static let gapBeyondTable: Double = 6

    let beats: Int
    let diameter: Double
    let gap: Double

    init(beats: Int) {
        let n = max(beats, 1)
        self.beats = n
        let spec = Self.spec(forBeats: n)
        self.diameter = spec.diameter
        self.gap = spec.gap
    }

    /// La larghezza della fila: n spie e n − 1 spazi.
    var rowWidth: Double { Double(beats) * diameter + Double(beats - 1) * gap }

    /// La tavola del punto 106, e le forme minime per i numeri che non disegna.
    static func spec(forBeats beats: Int) -> (diameter: Double, gap: Double) {
        let n = max(beats, 1)
        switch n {
        case ...4: return (46, 22)
        case 5, 6: return (46, 12)
        case 7: return (42, 10)
        case 8, 9: return (32, 8)
        case 10, 11: return (26, 6)
        case 12: return (24, 6)
        default:
            // D6: oltre 12 lo spazio resta 6 e la spia si stringe quanto basta, mai più larga di quella a 12;
            // quando nemmeno lo spazio 6 ci sta, spazio e spia si dividono la riga alla pari.
            let g = min(gapBeyondTable, rowWidth / Double(2 * n - 1))
            let d = (rowWidth - g * Double(n - 1)) / Double(n)
            return (min(24, max(d, 0)), g)
        }
    }

    /// La faccia di una spia dal valore del pattern (decisione 8: 2 verde, 1 e 0 bianco).
    static func face(patternValue: UInt8) -> BeatLightFace {
        patternValue == 2 ? .accent : .beat
    }
}
