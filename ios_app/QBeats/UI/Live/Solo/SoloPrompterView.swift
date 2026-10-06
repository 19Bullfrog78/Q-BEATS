import SwiftUI

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA SEZIONE (IL TELEPROMPTER DI K) ===
// Foglio (REV9, `.p-se`, riga «Teleprompter» delle misure; punto 51): riquadro 366 x 100 (346-446, margini 12),
// Inter 800 42, interlinea 1,08, spaziatura −0,035 em, bianco pieno, centrato; una riga sta al centro del
// riquadro, due righe lo riempiono, oltre due righe puntini alla fine della seconda. Niente capsula, niente
// maiuscolo forzato, corpo fisso: il nome come è scritto. Senza nome «Section N» (punto 109), deciso dal
// chiamante con `SectionNameDecision`.
// Non costruita: l'interlinea 1,08 (SwiftUI non stringe l'interlinea del carattere sotto quella sua: vale quella
// di Inter, come già per il velo, BOX5 «Overlay Standby»). Si guarda al collaudo.
struct SoloPrompterView: View {
    let name: String
    let scale: Double

    var body: some View {
        let size = CGFloat(QLiveSolo.Prompter.fontSize * scale)
        Text(name)
            .font(.custom(QLiveSolo.Prompter.fontName, size: size))
            .tracking(size * CGFloat(QLiveSolo.Prompter.trackingEm))
            .foregroundColor(QLiveSolo.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
