import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA BARRA DELLE BATTUTE ===
// Foglio (Solo REV18, punto 107 e tavola b; REV9, riga «Barra delle battute»): 264-276, un segmento per battuta,
// spazio e raggio da `SoloBarMeterLayout` (Models/, col suo banco); fatte `.42`, in corso bianco pieno, le altre
// `--w12`. Regole di stato di `MicroSegBarView` (SegBarViews.swift): accesa se `.playing` oppure nella finestra
// `sectionHold` (il fade sincronizzato di fine sezione, P2), spenta in `.standby`; a battuta 0 niente è fatto.
struct SoloBarMeterView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState
    let sectionHold: Bool
    let scale: Double

    var body: some View {
        let layout = SoloBarMeterLayout(totalBars: total)
        let isPlaying: Bool = {
            if case .playing = state { return true }
            return false
        }()
        let isStandby: Bool = {
            if case .standby = state { return true }
            return false
        }()
        let lit = !isStandby && (isPlaying || sectionHold)
        let states = SoloBarMeterLayout.states(count: layout.count, currentBar: current, lit: lit)
        HStack(spacing: CGFloat(layout.gap * scale)) {
            ForEach(0..<layout.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: CGFloat(layout.cornerRadius * scale))
                    .fill(color(for: states[i]))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func color(for s: SoloBarSegmentState) -> Color {
        switch s {
        case .done: return QLiveSolo.whiteAlpha(QLiveSolo.BarMeter.doneOpacity)
        case .current: return QLiveSolo.white
        case .other: return QLiveSolo.whiteAlpha(QLiveSolo.BarMeter.otherOpacity)
        }
    }
}
