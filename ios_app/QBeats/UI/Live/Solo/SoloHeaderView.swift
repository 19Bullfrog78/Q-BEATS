import SwiftUI
import os

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA TESTATA DI K ===
// Foglio (Solo REV18 e REV9): `.p-hd` (44-104, `padding:0 14px`, `gap:10px`); `.p-rk` (tonda 44, fondo `--sf`,
// colore `--w86`, filo chiaro in alto `inset 0 1px 0 rgba(255,255,255,.055)`; `.or` = `--orl` per la freccia;
// `.mu` = `--amb` per il muto acceso); `.p-hn` (titolo Inter 700 24, spaziatura −0,01 em, `--w86`, una riga,
// puntini). Punto 110: acceso, l'altoparlante barrato (`i-sm`) ambra nella tonda di sempre; il tocco lo spegne.
// Le azioni sono quelle di oggi (`LiveHeaderView`): freccia → `onExit`; muto → `appSettings.clickMuted.toggle()`
// (lo fa il chiamante). In moto il titolo è la canzone; sui veli dirà lo show (M3). In attesa, sotto il velo di
// oggi (fino a M3), il titolo scende con il resto (`contentOpacity`); freccia e muto restano pieni e toccabili
// (decisione 13, A355). Le misure sono quelle del foglio per il fattore della geometria (D4).
// ⚠️ A403 (11/10/2026) — SOLO REV22, PUNTO 118: IL NOME LUNGO IN TESTATA. Il titolo non è più a 24 fisso coi puntini
//    del sistema («titolo Inter 700 24 … una riga, puntini» qui sopra è storia per il corpo): corpo e riga li decide
//    `SoloHeaderTitle.fit` (Models/, sopra `TextFitter`, col suo banco): una riga larga 254, da 24 a 17 a scendere
//    di 1; a 17 i puntini, alla fine. A schermo la riga decisa la scrive `FittedTextView`, come per la sezione di K
//    e i nomi sui veli. Carattere (Inter 700), spaziatura (−0,01 em), colore (`--w86`) e posto restano quelli di
//    prima: la riga è alta 1,2 × corpo (`.p-hn{font:700 24px/1.2 Inter}`) e sta al centro della testata. Il fit si
//    calcola una volta per titolo (`SoloHeaderTitleMemo`, tenuto con `@StateObject`: nasce una volta per ogni
//    montaggio della testata), non a ogni valutazione del body: K si rivaluta a ogni battito. Una riga di log a ogni
//    cambio di titolo, dal titolo NUOVO (`onChange(of: title)` consegna il valore nuovo), e alla comparsa; col
//    titolo vuoto non si scrive.
struct SoloHeaderView: View {
    let title: String
    let muted: Bool
    let scale: Double
    let contentOpacity: Double
    let onExit: () -> Void
    let onToggleMute: () -> Void
    @StateObject private var memo = SoloHeaderTitleMemo()

    var body: some View {
        let round = CGFloat(QLiveSolo.Header.round * scale)
        let icon = CGFloat(QLiveSolo.Header.icon * scale)
        let titleFit = memo.fit(title, measurer: CoreTextWidthMeasurer.shared)
        HStack(spacing: CGFloat(QLiveSolo.Header.gap * scale)) {
            Button(action: onExit) {
                roundFace(size: round)
                    .overlay(SoloIconView(icon: .back, size: icon, color: QLiveSolo.orange))
            }
            .buttonStyle(.plain)

            FittedTextView(fit: titleFit, colors: [QLiveSolo.whiteAlpha(QLiveSolo.Header.titleOpacity)], scale: scale)
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
        .onAppear { titleFitted(title) }
        .onChange(of: title) { newTitle in titleFitted(newTitle) }
    }

    /// Corpo e puntini del titolo, alla comparsa e a ogni cambio di titolo, dal titolo che arriva.
    private func titleFitted(_ shown: String) {
        guard !shown.isEmpty else { return }
        let fit = memo.fit(shown, measurer: CoreTextWidthMeasurer.shared)
        os_log("[Q-BEATS][SOLO-M3][TESTATA] corpo:%d puntini:%{public}@ nome:%{public}@",
               log: .default, type: .default,
               Int(fit.size.rounded()), fit.truncated ? "si" : "no", shown)
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
