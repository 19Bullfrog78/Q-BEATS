import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA TESTATA DI K ===
// Foglio (Solo REV18 e REV9): `.p-hd` (44-104, `padding:0 14px`, `gap:10px`); `.p-rk` (tonda 44, fondo `--sf`,
// colore `--w86`, filo chiaro in alto `inset 0 1px 0 rgba(255,255,255,.055)`; `.or` = `--orl` per la freccia;
// `.mu` = `--amb` per il muto acceso); `.p-hn` (titolo Inter 700 24, spaziatura −0,01 em, `--w86`, una riga,
// puntini). Punto 110: acceso, l'altoparlante barrato (`i-sm`) ambra nella tonda di sempre; il tocco lo spegne.
// Le azioni sono quelle di oggi (`LiveHeaderView`): freccia → `onExit`; muto → `appSettings.clickMuted.toggle()`
// (lo fa il chiamante). In moto il titolo è la canzone; sui veli dirà lo show (M3). In attesa, sotto il velo di
// oggi (fino a M3), il titolo scende con il resto (`contentOpacity`); freccia e muto restano pieni e toccabili
// (decisione 13, A355). Le misure sono quelle del foglio per il fattore della geometria (D4).
struct SoloHeaderView: View {
    let title: String
    let muted: Bool
    let scale: Double
    let contentOpacity: Double
    let onExit: () -> Void
    let onToggleMute: () -> Void

    var body: some View {
        let round = CGFloat(QLiveSolo.Header.round * scale)
        let icon = CGFloat(QLiveSolo.Header.icon * scale)
        let titleSize = CGFloat(QLiveSolo.Header.titleSize * scale)
        HStack(spacing: CGFloat(QLiveSolo.Header.gap * scale)) {
            Button(action: onExit) {
                roundFace(size: round)
                    .overlay(SoloIconView(icon: .back, size: icon, color: QLiveSolo.orange))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.custom("Inter-Bold", size: titleSize))
                .tracking(titleSize * CGFloat(QLiveSolo.Header.titleTrackingEm))
                .foregroundColor(QLiveSolo.whiteAlpha(QLiveSolo.Header.titleOpacity))
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(contentOpacity)

            Button(action: onToggleMute) {
                roundFace(size: round)
                    .overlay(SoloIconView(icon: muted ? .speakerMuted : .speaker, size: icon,
                                          color: muted ? QLiveSolo.amber : QLiveSolo.whiteAlpha(QLiveSolo.Header.iconOpacity)))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// La tonda (`.p-rk`): fondo `--sf`, col filo chiaro di 1 lungo il bordo in alto.
    private func roundFace(size: CGFloat) -> some View {
        Circle()
            .fill(QLiveSolo.surface)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(QLiveSolo.Header.roundHighlight), lineWidth: 1)
                    .mask(alignment: .top) { Rectangle().frame(height: size / 2) }
            )
            .frame(width: size, height: size)
    }
}
