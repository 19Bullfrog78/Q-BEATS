import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA CONSOLE B ===
// Foglio (REV9, `.kB`, `.q`, `.kst`, riga «Console B» delle misure; REV18, punti 84 e 88, schermi K, K0, H e
// f1): 630-806, quattro quadranti 173 x 84 con spazio 8 (griglia 2 x 2), raggio 20, fondo `--sf` col filo chiaro
// in alto, etichette Inter 700 17 `--w72`, icona 24, 7 fra icona ed etichetta; i quadranti accanto al tondo
// lasciano 64 al tondo (`.q.l{padding-right:64}`, `.q.r{padding-left:64}`). In alto a sinistra il tasto da
// definire, pieno e spento (`.q.dead`, opacità .4, senza icona né scritta; punto 54). Kill e List mode spenti
// (`.q.off`, opacità .4): il tocco non fa niente, ferma e in moto (punti 84 e 88, Mauro «B»). Mixer acceso;
// a pannello aperto la veste del tasto selezionato (`.q.on`: fondo bianco .14, bordo 1,5 bianco .5, scritta
// bianca piena). Il tondo (`.kst`): Ø 128 al centro, anello 8 di `--bg` che stacca dai quadranti; Stop: fondo
// rosso .16 su `--bg`, bordo 2 rosso .7, quadrato 42 raggio 8 `--red`; Play (`.kst.pl`): fondo verde .14, bordo 2
// `--acc`, triangolo 46 col tratto 2,4 `--acc`, spostato di 6 a destra. Le facce arrivano da
// `SoloConsoleDecision` (Models/, col suo banco); i tocchi tornano al chiamante con il tasto (`SoloConsoleKey`),
// che agisce e logga; i tasti spenti restano toccabili per dire «nessuna azione» nel log.
struct SoloConsoleView: View {
    let faces: SoloConsoleFaces
    let scale: Double
    let onKey: (SoloConsoleKey) -> Void

    private enum Side { case left, right }

    var body: some View {
        GeometryReader { geo in
            let gap = CGFloat(QLiveSolo.Console.gap * scale)
            let qw = max((geo.size.width - gap) / 2, 0)
            let qh = max((geo.size.height - gap) / 2, 0)
            ZStack {
                VStack(spacing: gap) {
                    HStack(spacing: gap) {
                        deadQuadrant(width: qw, height: qh)
                        quadrant(icon: .mixer, label: "Mixer", on: faces.mixerOn, selected: faces.mixerSelected,
                                 side: .right, width: qw, height: qh) { onKey(.mixer) }
                    }
                    HStack(spacing: gap) {
                        quadrant(icon: .listMode, label: "List mode", on: faces.listModeOn, selected: false,
                                 side: .left, width: qw, height: qh) { onKey(.listMode) }
                        quadrant(icon: .kill, label: "Kill", on: faces.killOn, selected: false,
                                 side: .right, width: qw, height: qh) { onKey(.kill) }
                    }
                }
                centerButton
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Il fondo di un quadrante (`.q`): `--sf`, raggio 20, filo chiaro in alto; selezionato (`.q.on`) fondo e bordo.
    private func quadrantFace(selected: Bool) -> some View {
        let radius = CGFloat(QLiveSolo.Console.radius * scale)
        return RoundedRectangle(cornerRadius: radius)
            .fill(selected ? QLiveSolo.whiteAlpha(QLiveSolo.Console.selectedFillOpacity) : QLiveSolo.surface)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(selected ? QLiveSolo.whiteAlpha(QLiveSolo.Console.selectedBorderOpacity)
                                           : Color.white.opacity(QLiveSolo.Console.highlight),
                                  lineWidth: selected ? CGFloat(QLiveSolo.Console.selectedBorder * scale) : 1)
            )
    }

    /// Il tasto da definire (`.q.dead`): pieno, opacità .4, senza icona né scritta; inerte.
    private func deadQuadrant(width: CGFloat, height: CGFloat) -> some View {
        quadrantFace(selected: false)
            .frame(width: width, height: height)
            .opacity(QLiveSolo.Console.offOpacity)
    }

    /// Un quadrante con icona ed etichetta; spento (`.q.off`) opacità .4, il tocco torna comunque al chiamante.
    private func quadrant(icon: SoloIcon, label: String, on: Bool, selected: Bool, side: Side,
                          width: CGFloat, height: CGFloat, action: @escaping () -> Void) -> some View {
        let iconSize = CGFloat(QLiveSolo.Console.icon * scale)
        let clearance = CGFloat(QLiveSolo.Console.centerClearance * scale)
        let labelColor = selected ? QLiveSolo.white : QLiveSolo.whiteAlpha(QLiveSolo.Console.labelOpacity)
        return Button(action: action) {
            ZStack {
                quadrantFace(selected: selected)
                VStack(spacing: CGFloat(QLiveSolo.Console.iconLabelGap * scale)) {
                    SoloIconView(icon: icon, size: iconSize, color: labelColor)
                    Text(label)
                        .font(.custom("Inter-Bold", size: CGFloat(QLiveSolo.Console.labelSize * scale)))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                }
                .padding(.leading, side == .right ? clearance : 0)
                .padding(.trailing, side == .left ? clearance : 0)
            }
            .frame(width: width, height: height)
            .opacity(on ? 1.0 : QLiveSolo.Console.offOpacity)
        }
        .buttonStyle(.plain)
    }

    /// Il tondo al centro (`.kst`): Stop in moto, Play da fermo; la faccia e l'azione dallo stesso dato (D5).
    private var centerButton: some View {
        let d = CGFloat(QLiveSolo.Console.centerDiameter * scale)
        let ring = CGFloat(QLiveSolo.Console.centerRing * scale)
        let border = CGFloat(QLiveSolo.Console.centerBorder * scale)
        let isStop = faces.center == .stop
        let square = CGFloat(QLiveSolo.Console.stopSquare * scale)
        let triangle = CGFloat(QLiveSolo.Console.playTriangle * scale)
        return Button(action: { onKey(.center) }) {
            ZStack {
                Circle()
                    .fill(QLiveSolo.background)
                    .frame(width: d + 2 * ring, height: d + 2 * ring)
                Circle()
                    .fill(isStop
                          ? QLiveSolo.red.opacity(QLiveSolo.Console.stopFillOpacity)
                          : QLiveSolo.accent.opacity(QLiveSolo.Console.playFillOpacity))
                    .frame(width: d, height: d)
                Circle()
                    .strokeBorder(isStop ? QLiveSolo.red.opacity(QLiveSolo.Console.stopBorderOpacity) : QLiveSolo.accent,
                                  lineWidth: border)
                    .frame(width: d, height: d)
                if isStop {
                    RoundedRectangle(cornerRadius: CGFloat(QLiveSolo.Console.stopSquareRadius * scale))
                        .fill(QLiveSolo.red)
                        .frame(width: square, height: square)
                } else {
                    SoloIconView(icon: .play, size: triangle, color: QLiveSolo.accent,
                                 strokeWidth: triangle * CGFloat(QLiveSolo.Console.playStroke / QLiveSolo.iconViewBox))
                        .offset(x: CGFloat(QLiveSolo.Console.playOffset * scale))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
