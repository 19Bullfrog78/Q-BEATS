import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — NEXT ===
// Foglio (REV9, `.p-nx`, riga «Next» delle misure; REV18, punto 108 e schermi c1/c2): riquadro alto 60 (516-576),
// raggio 16, margini interni 16, bordo 1,5 `--w12`; «Next» o «Next song» Inter 600 19 `--w66`, su una riga; la
// sezione, la canzone dopo o «END SHOW» Inter 700 28, spaziatura −0,015 em, `--w86`, una riga, puntini; 12 fra
// le due. Le parole le decide `SoloNextDecision` (Models/, col suo banco).
struct SoloNextView: View {
    let next: SoloNext
    let scale: Double

    var body: some View {
        let labelSize = CGFloat(QLiveSolo.Next.labelSize * scale)
        let valueSize = CGFloat(QLiveSolo.Next.valueSize * scale)
        HStack(spacing: CGFloat(QLiveSolo.Next.gap * scale)) {
            Text(next.label)
                .font(.custom("Inter-SemiBold", size: labelSize))
                .foregroundColor(QLiveSolo.whiteAlpha(QLiveSolo.Next.labelOpacity))
                .lineLimit(1)
                .fixedSize()
            Text(next.value)
                .font(.custom("Inter-Bold", size: valueSize))
                .tracking(valueSize * CGFloat(QLiveSolo.Next.valueTrackingEm))
                .foregroundColor(QLiveSolo.whiteAlpha(QLiveSolo.Next.valueOpacity))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, CGFloat(QLiveSolo.Next.padding * scale))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(QLiveSolo.Next.radius * scale))
                .strokeBorder(QLiveSolo.whiteAlpha(QLiveSolo.Next.borderOpacity),
                              lineWidth: CGFloat(QLiveSolo.Next.border * scale))
        )
    }
}
