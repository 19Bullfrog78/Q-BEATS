import Foundation

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA BARRA DELLE BATTUTE E LA BARRA DELLA CANZONE ===
// Barra delle battute (Solo REV18, punto 107 e tavola b) della sezione C): un segmento per battuta, riga larga
// 354 (da 18 a 372), spazio 6 fino a 16 battute, 3 da 17 a 32, 1,5 da 33 a 64; raggio 6, mai più di metà del
// segmento (a 64 il segmento è largo 4 e il raggio 2); fatte .42, in corso bianco pieno, le altre .12 (REV9,
// riga «Barra delle battute»). Regole di stato di `MicroSegBarView` (SegBarViews.swift): accesa se `.playing`
// oppure nella finestra `sectionHold`, spenta in `.standby`; con `currentBar` 0 (ancora non conquistata)
// nessuna battuta è fatta né in corso.
// Barra della canzone (REV9, riga «Barra della canzone»; schermi K, c1 e c2 della REV18): un blocco per
// sezione, largo in proporzione alle battute, spazio 4; fatte bianco .34, in corso bianco .62 fino al punto, il
// resto .12; l'avanzamento dentro la sezione in corso è battuta/battute: 1 di 16 = 6,25 % (K), 5 di 8 = 62,5 %
// (REV9).
// Casi che il foglio non disegna (D6, nel referto «da portare a CD»): più di 64 battute → spazio 1,5 finché il
// segmento resta almeno largo quanto lo spazio, poi spazio 0 e segmento 354/n; sezione a ripetizioni infinite
// (−1) o da 0 battute → un segmento solo nella barra delle battute, peso 1 e avanzamento 0 nella barra della
// canzone. Tutto totale: nessuna divisione per zero, nessuna misura negativa, niente oltre 354.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SoloBarSegmentState: Equatable {
    case done, current, other
}

struct SoloBarMeterLayout: Equatable {
    static let rowWidth: Double = 354
    static let maxCornerRadius: Double = 6

    /// Quanti segmenti si disegnano (almeno 1).
    let count: Int
    let gap: Double
    let segmentWidth: Double
    let cornerRadius: Double

    init(totalBars: Int) {
        let n = max(totalBars, 1)
        var g = Self.gap(forBars: n)
        var w = (Self.rowWidth - g * Double(n - 1)) / Double(n)
        if w < g {
            // D6: oltre il disegnato, quando il segmento scenderebbe sotto lo spazio, lo spazio va a zero.
            g = 0
            w = Self.rowWidth / Double(n)
        }
        self.count = n
        self.gap = g
        self.segmentWidth = w
        self.cornerRadius = min(Self.maxCornerRadius, w / 2)
    }

    /// Lo spazio fra i segmenti: 6 fino a 16, 3 da 17 a 32, 1,5 da 33 in su (il foglio disegna fino a 64).
    static func gap(forBars n: Int) -> Double {
        if n <= 16 { return 6 }
        if n <= 32 { return 3 }
        return 1.5
    }

    /// Lo stato di ogni segmento. `lit` = la barra è accesa (`.playing` o `sectionHold`, e non `.standby`).
    static func states(count: Int, currentBar: Int, lit: Bool) -> [SoloBarSegmentState] {
        (0..<max(count, 0)).map { i -> SoloBarSegmentState in
            guard lit, currentBar > 0 else { return .other }
            let bar = i + 1
            if bar < currentBar { return .done }
            if bar == currentBar { return .current }
            return .other
        }
    }
}

struct SoloSongBarLayout: Equatable {
    static let rowWidth: Double = 354
    static let gap: Double = 4

    struct Block: Equatable {
        /// Il peso del blocco: le battute della sezione (infinite o zero → 1).
        let weight: Double
        let state: SoloBarSegmentState
        /// L'avanzamento dentro il blocco in corso, da 0 a 1 (0 negli altri).
        let progress: Double
    }

    let blocks: [Block]

    /// `barsPerSection`: le ripetizioni di ogni sezione della canzone corrente, nell'ordine; `currentSectionIndex`
    /// contato da 0; `currentBar` e `totalBarsInSection` della sezione in corso (`LiveSession`).
    init(barsPerSection: [Int], currentSectionIndex: Int, currentBar: Int, totalBarsInSection: Int) {
        var progress: Double = 0
        if totalBarsInSection > 0 {
            progress = min(1, max(0, Double(currentBar) / Double(totalBarsInSection)))
        }
        self.blocks = barsPerSection.enumerated().map { (i, bars) -> Block in
            let state: SoloBarSegmentState
            if i < currentSectionIndex {
                state = .done
            } else if i == currentSectionIndex {
                state = .current
            } else {
                state = .other
            }
            return Block(weight: Double(max(bars, 1)),
                         state: state,
                         progress: state == .current ? progress : 0)
        }
    }

    /// Le larghezze dei blocchi per una riga larga `rowWidth`, tolti gli spazi; senza blocchi, niente.
    func widths(rowWidth: Double = SoloSongBarLayout.rowWidth, gap: Double = SoloSongBarLayout.gap) -> [Double] {
        let total = blocks.reduce(0.0) { $0 + $1.weight }
        guard total > 0, !blocks.isEmpty else { return blocks.map { _ in 0 } }
        let available = max(0, rowWidth - gap * Double(blocks.count - 1))
        return blocks.map { available * $0.weight / total }
    }
}
