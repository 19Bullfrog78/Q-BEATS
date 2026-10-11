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
// ⚠️ A401 (10/10/2026) — SOLO REV20, PUNTO 115 (cambia il 51): IL TELEPROMPTER USA LO SPAZIO. Riquadro 366 x 173
//    (284-457, `SoloPlayerGeometry.prompter`); il nome si prova in due righe da 68 a 53, poi in tre righe da 53 a
//    42, e a 42 finisce coi puntini alla fine della terza riga (`SoloVeilTypography.sectionFit`, sopra `TextFitter`);
//    Inter 800, interlinea 1,08, spaziatura −0,035 em e blocco al centro del riquadro restano. «42 fisso», «due
//    righe lo riempiono» e «riquadro di 100» qui sopra sono storia: si marcano.
//    Il fit si calcola una volta per nome (`SoloSectionFitMemo`, tenuto dalla vista con `@StateObject`: nasce una
//    volta sola per ogni montaggio di K), non a ogni valutazione del body. La riga di log si scrive dal nome NUOVO
//    (`onChange(of: name)` consegna il valore nuovo), una volta per cambio di nome, col fit di quel nome; col nome
//    vuoto (display non ancora scritto, o K che si smonta a fine canzone) non si scrive (referto A399 §8.3, punto 4).
struct SoloPrompterView: View {
    let name: String
    let scale: Double
    @StateObject private var memo = SoloSectionFitMemo()

    var body: some View {
        let fit = memo.fit(name, measurer: CoreTextWidthMeasurer.shared)
        FittedTextView(fit: fit, colors: [QLiveSolo.white], scale: scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { sectionFitted(name) }
            .onChange(of: name) { newName in sectionFitted(newName) }
    }

    /// Corpo e righe della sezione di K, una volta per cambio di nome, dal nome che arriva.
    private func sectionFitted(_ shown: String) {
        guard !shown.isEmpty else { return }
        let fit = memo.fit(shown, measurer: CoreTextWidthMeasurer.shared)
        os_log("[Q-BEATS][SOLO-M3][SEZIONE] corpo:%d righe:%d puntini:%{public}@ nome:%{public}@",
               log: .default, type: .default,
               Int(fit.size.rounded()), fit.lineCount, fit.truncated ? "si" : "no", shown)
    }
}
