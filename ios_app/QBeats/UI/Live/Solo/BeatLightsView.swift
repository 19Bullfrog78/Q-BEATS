import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LE SPIE DEL BATTITO ===
// Foglio (Solo REV18, punto 106 e tavola a): una spia per battito, su una fila sola centrata, Ø e spazio da
// `BeatLightsLayout` (Models/, col suo banco); facce della REV9: spenta `--w07` con bordo 1,5 `rgba(…,.1)`,
// accesa verde `--acc` dove il pattern vale 2, bianca `--w` per 1 e 0 (BOX5 V54, decisione 8). Stesso contratto
// di `MetSlotStripView`: il pattern di `displayAccentPattern` e `beatActive` della sessione (1-based, 0 = nessuno),
// mai il motore; il battito arriva solo dal percorso di oggi (`beatTickSubject` → `beatActive`), anche a click
// muto (il muto è il guadagno, non il battito).
struct BeatLightsView: View {
    let pattern: [UInt8]
    let beatActive: Int
    let scale: Double

    var body: some View {
        let layout = BeatLightsLayout(beats: pattern.count)
        let d = CGFloat(layout.diameter * scale)
        let ring = CGFloat(QLiveSolo.Lights.offRing * scale)
        HStack(spacing: CGFloat(layout.gap * scale)) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { i, value in
                let active = (i + 1) == beatActive
                let face = BeatLightsLayout.face(patternValue: value)
                Circle()
                    .fill(active
                          ? (face == .accent ? QLiveSolo.accent : QLiveSolo.white)
                          : QLiveSolo.whiteAlpha(QLiveSolo.Lights.offFill))
                    .overlay(
                        Circle().strokeBorder(QLiveSolo.whiteAlpha(QLiveSolo.Lights.offRingOpacity),
                                              lineWidth: active ? 0 : ring)
                    )
                    .frame(width: d, height: d)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
