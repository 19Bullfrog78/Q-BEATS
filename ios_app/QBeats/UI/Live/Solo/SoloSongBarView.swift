import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA BARRA DELLA CANZONE ===
// Foglio (REV9, `.p-sp`, riga «Barra della canzone» delle misure; REV18, schermi K, c1, c2): 596-606, un blocco
// per sezione largo in proporzione alle battute, spazio 4, raggio 5; fatte bianco .34, in corso bianco .62 fino
// al punto (`u`, dentro il blocco, tagliato dal suo raggio), il resto `--w12`; nessun colore. Pesi, stati e
// avanzamento da `SoloSongBarLayout` (Models/, col suo banco).
struct SoloSongBarView: View {
    let layout: SoloSongBarLayout
    let scale: Double

    var body: some View {
        GeometryReader { geo in
            let gap = CGFloat(QLiveSolo.SongBar.gap * scale)
            let radius = CGFloat(QLiveSolo.SongBar.radius * scale)
            let widths = layout.widths(rowWidth: Double(geo.size.width), gap: Double(gap))
            HStack(spacing: gap) {
                ForEach(Array(layout.blocks.enumerated()), id: \.offset) { i, block in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(block.state == .done
                                  ? QLiveSolo.whiteAlpha(QLiveSolo.SongBar.doneOpacity)
                                  : QLiveSolo.whiteAlpha(QLiveSolo.SongBar.otherOpacity))
                        if block.state == .current {
                            Rectangle()
                                .fill(QLiveSolo.whiteAlpha(QLiveSolo.SongBar.progressOpacity))
                                .frame(width: CGFloat(widths[i]) * CGFloat(block.progress))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                    .frame(width: CGFloat(widths[i]))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
