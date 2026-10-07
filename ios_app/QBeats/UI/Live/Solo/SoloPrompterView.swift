import SwiftUI
import os

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA SEZIONE (IL TELEPROMPTER DI K) ===
// Foglio (REV9, `.p-se`, riga «Teleprompter» delle misure; punto 51): riquadro 366 x 100 (346-446, margini 12),
// Inter 800 42, interlinea 1,08, spaziatura −0,035 em, bianco pieno, centrato; una riga sta al centro del
// riquadro, due righe lo riempiono, oltre due righe puntini alla fine della seconda. Niente capsula, niente
// maiuscolo forzato, corpo fisso: il nome come è scritto. Senza nome «Section N» (punto 109), deciso dal
// chiamante con `SectionNameDecision`.
// ⚠️ SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — L'INTERLINEA 1,08 È COSTRUITA. In M2 la lasciava al carattere
//    (1,21: due righe a 42 fanno 101,2 nel riquadro di 99,6, e l'app tagliava a una riga: collaudo del 06/10, P1-5,
//    «Bridge attenzione vai piano» su una riga coi puntini). Ora le righe le decide il pezzo del testo
//    (`TextFitter` + `SoloVeilTypography.sectionSpec`, col misuratore vero): 42 fisso, interlinea 1,08, spaziatura
//    −0,035 em, largo 366, due righe al più, poi i puntini; il blocco (due righe = 90,72) centrato nel riquadro di
//    100 (`.p-se{align-items:center}`). Una riga di log a ogni cambio di sezione: corpo, righe, puntini.
struct SoloPrompterView: View {
    let name: String
    let scale: Double

    var body: some View {
        let fit = TextFitter.fit(SoloVeilTypography.sectionSpec(name), measurer: CoreTextWidthMeasurer.shared)
        FittedTextView(fit: fit, colors: [QLiveSolo.white], scale: scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { sectionFitted(fit) }
            .onChange(of: fit) { newFit in sectionFitted(newFit) }
    }

    /// Corpo e righe della sezione di K, a ogni cambio di sezione (mandato M3 §6).
    private func sectionFitted(_ fit: FittedText) {
        os_log("[Q-BEATS][SOLO-M3][SEZIONE] corpo:%d righe:%d puntini:%{public}@ nome:%{public}@",
               log: .default, type: .default,
               Int(fit.size.rounded()), fit.lineCount, fit.truncated ? "si" : "no", name)
    }
}
