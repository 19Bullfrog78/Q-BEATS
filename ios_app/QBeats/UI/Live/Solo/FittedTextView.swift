import SwiftUI

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — A SCHERMO, LE RIGHE DECISE DAL PEZZO DEL TESTO ===
// Le righe le decide `TextFitter` (Models/), non il sistema: qui ogni riga è una scritta che non va più a capo da
// sola (`lineLimit(1)` + `fixedSize`), messa nella sua riga alta interlinea × corpo con la linea di base dove il
// modello CSS la vuole (`FittedText.baselines`: la mezza interlinea sopra e sotto). La linea di base si aggancia con
// `alignmentGuide(.top)` sul `firstTextBaseline` della scritta: così non conta l'altezza naturale del carattere, che
// SwiftUI darebbe alla riga. Le vesti (carattere, spaziatura) sono quelle con cui le righe sono state misurate
// (`FittedText.styles`); i colori li dà il chiamante, uno per veste. Corpi, interlinee e linee di base sono in punti
// del foglio e qui si moltiplicano per il fattore D4. La spaziatura dei caratteri è `tracking` sul corpo scalato
// (dopo ogni carattere, l'ultimo compreso, come `letter-spacing`).
struct FittedTextView: View {
    let fit: FittedText
    /// Un colore per veste (`fit.styles`); se mancano, vale l'ultimo.
    let colors: [Color]
    let scale: Double

    var body: some View {
        let s = CGFloat(scale)
        let lineHeight = CGFloat(fit.lineHeight) * s
        VStack(spacing: 0) {
            ForEach(Array(fit.lines.enumerated()), id: \.offset) { i, line in
                let baselineInLine = CGFloat(fit.baselines[i] - Double(i) * fit.lineHeight) * s
                lineText(line)
                    .lineLimit(1)
                    .fixedSize()
                    .alignmentGuide(.top) { d in d[.firstTextBaseline] - baselineInLine }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: lineHeight, alignment: .top)
            }
        }
        .frame(height: CGFloat(fit.height) * s)
    }

    /// Una riga: i suoi pezzi, ognuno con la sua veste, uniti in un `Text` solo.
    private func lineText(_ line: FittedLine) -> Text {
        let size = CGFloat(fit.size * scale)
        var text = Text("")
        for run in line.runs {
            let index = min(max(run.style, 0), max(fit.styles.count - 1, 0))
            let fontName = fit.styles.isEmpty ? SoloFonts.interBold : fit.styles[index].fontName
            let trackingEm = fit.styles.isEmpty ? 0 : fit.styles[index].trackingEm
            let color = colors.isEmpty ? Color.white : colors[min(index, colors.count - 1)]
            text = text + Text(run.text)
                .font(.custom(fontName, size: size))
                .tracking(size * CGFloat(trackingEm))
                .foregroundColor(color)
        }
        return text
    }
}

/// Un blocco al suo posto nell'area utile: misura e posizione dalla geometria (D4), in punti dell'area utile.
extension View {
    func soloPlaced(_ r: SoloRect) -> some View {
        self
            .frame(width: CGFloat(r.width), height: CGFloat(r.height))
            .offset(x: CGFloat(r.x), y: CGFloat(r.y))
    }
}

/// Il respiro del nome sui veli del Solo (V1, V2, H): ciclo intero 2,2 s, opacità da 1 a .45 e ritorno, ease-in-out
/// per ogni metà (Solo REV18: `@keyframes pu{0%,100%{opacity:1}50%{opacity:.45}}`, `animation:pu 2.2s ease-in-out
/// infinite` su `.p-vn`; tabella 3: «respiro 2,2 s»). Con Riduci movimento acceso il nome non respira
/// (`@media (prefers-reduced-motion:reduce){.p-vn{animation:none}}`; l'impostazione la legge l'ambiente di SwiftUI,
/// `EnvironmentValues.accessibilityReduceMotion`, iOS 13.0+:
/// https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion). Stessa forma di
/// `ArmedNamePulse` (FollowerOutView): lo stato si inverte all'`onAppear`, l'animazione è legata al solo valore.
/// `QLiveStage.Veil.pulsePeriod` (2,2 s per mezza corsa) resta a Direttore e Follower: qui il token è
/// `QLiveSolo.Veil.pulsePeriod`, il ciclo intero.
struct SoloVeilNamePulse: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dimmed = false

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1.0 : (dimmed ? QLiveSolo.Veil.pulseOpacityLow : 1.0))
            .animation(reduceMotion ? nil : .easeInOut(duration: QLiveSolo.Veil.pulseHalfPeriod).repeatForever(autoreverses: true),
                       value: dimmed)
            .onAppear { dimmed.toggle() }
    }
}
