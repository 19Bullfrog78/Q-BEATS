import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — LE VESTI DEL FOGLIO PER IL PEZZO DEL TESTO, E LE ALTEZZE DEI BLOCCHI ===
// Dalla Solo REV18 (CSS citato accanto a ogni valore; tabella C riga i; tabella 3 «Blocco del velo»; punto 114):
//  · `.p-vn`  — il nome sui veli: Inter 900 (`Inter-Black`) da 80 a 48, interlinea 1,02, spaziatura −0,03 em, largo 338
//               (`.p-vb{left:26px;right:26px}`), due righe al più, a 48 i puntini;
//  · `.p-se b` — la sezione in K: Inter 800 (`Inter-ExtraBold`) 42 fisso, interlinea 1,08, spaziatura −0,035 em, largo
//               366 (`.p-se{left:12px;right:12px}`), due righe al più, poi i puntini; il blocco centrato nel riquadro
//               alto 100 (`.p-se{align-items:center}`);
//  · `.p-va`  — la riga A dei veli: Inter 600 (`Inter-SemiBold`) 21, interlinea 1,25, largo 338, due righe al più; in
//               H la sezione in Inter 700 (`Inter-Bold`) nella stessa riga (`.p-va b`): una riga fatta di pezzi;
//  · `.p-vt`  — tempo e metrica: JetBrains Mono 500 (`JetBrainsMono-Medium`) 21, interlinea 1,2, una riga;
//  · `.p-es`  — END SHOW: Inter 900 44, interlinea 1, spaziatura −0,02 em, una riga, largo quanto lo schermo;
//  · `.p-tap` — «Tap to start»: Inter 600 21, interlinea 1,2, una riga.
// Il blocco del velo parte a 248 e cresce in basso: riga A; 14 (`.p-vn{margin-top:14px}`); il nome; 12
// (`.p-vt{margin-top:12px}`); tempo e metrica. Col nome su una riga a 80 finisce a 407 (tabella 3: «248–407»); con due
// righe a 80 a 489 (punto 114). Tutto in punti del foglio: il fattore D4 si applica al risultato.
// I nomi dei caratteri sono i nomi PostScript dei file in bundle (`ios_app/QBeats/Fonts/`, `UIAppFonts`).
enum SoloFonts {
    static let interBlack = "Inter-Black"
    static let interExtraBold = "Inter-ExtraBold"
    static let interBold = "Inter-Bold"
    static let interSemiBold = "Inter-SemiBold"
    static let jetBrainsMonoMedium = "JetBrainsMono-Medium"
    /// I cinque caratteri che il pezzo del testo usa nel Solo.
    static let all = [interBlack, interExtraBold, interBold, interSemiBold, jetBrainsMonoMedium]
}

enum SoloVeilTypography {

    // MARK: Il nome sui veli (`.p-vn`, punto 114)

    static let nameMaxSize = 80
    static let nameMinSize = 48
    static let nameLineHeight: Double = 1.02
    static let nameTrackingEm: Double = -0.03
    static let veilWidth: Double = 338
    static let veilMaxLines = 2

    static func nameSpec(_ name: String) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interBlack, trackingEm: nameTrackingEm)],
                    runs: [TextRun(text: name, style: 0)],
                    lineHeightFactor: nameLineHeight,
                    maxWidth: veilWidth,
                    maxLines: veilMaxLines,
                    sizes: TextFitSpec.descending(from: nameMaxSize, to: nameMinSize))
    }

    // MARK: La sezione in K (`.p-se b`)

    static let sectionSize: Double = 42
    static let sectionLineHeight: Double = 1.08
    static let sectionTrackingEm: Double = -0.035
    static let sectionWidth: Double = 366
    static let sectionBoxHeight: Double = 100
    static let sectionMaxLines = 2

    static func sectionSpec(_ name: String) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interExtraBold, trackingEm: sectionTrackingEm)],
                    runs: [TextRun(text: name, style: 0)],
                    lineHeightFactor: sectionLineHeight,
                    maxWidth: sectionWidth,
                    maxLines: sectionMaxLines,
                    sizes: [sectionSize])
    }

    /// Il blocco della sezione sta al centro del riquadro alto 100: dove comincia (dall'alto del riquadro).
    static func sectionBlockTop(height: Double) -> Double {
        (sectionBoxHeight - height) / 2
    }

    // MARK: La riga A dei veli (`.p-va`, `.p-va b`)

    static let relationSize: Double = 21
    static let relationLineHeight: Double = 1.25
    /// Veste 0: la frase («Next», «Resume from »); veste 1: la sezione, in Inter 700 bianco pieno.
    static let relationStyles = [TextFitStyle(fontName: SoloFonts.interSemiBold, trackingEm: 0),
                                 TextFitStyle(fontName: SoloFonts.interBold, trackingEm: 0)]

    static func relationSpec(prefix: String, section: String?) -> TextFitSpec {
        var runs = [TextRun(text: prefix, style: 0)]
        if let section, !section.isEmpty {
            runs.append(TextRun(text: section, style: 1))
        }
        return TextFitSpec(styles: relationStyles,
                           runs: runs,
                           lineHeightFactor: relationLineHeight,
                           maxWidth: veilWidth,
                           maxLines: veilMaxLines,
                           sizes: [relationSize])
    }

    // MARK: Tempo e metrica (`.p-vt`)

    static let tempoSize: Double = 21
    static let tempoLineHeight: Double = 1.2

    static func tempoSpec(_ text: String) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.jetBrainsMonoMedium, trackingEm: 0)],
                    runs: [TextRun(text: text, style: 0)],
                    lineHeightFactor: tempoLineHeight,
                    maxWidth: veilWidth,
                    maxLines: 1,
                    sizes: [tempoSize])
    }

    // MARK: END SHOW (`.p-es`) e «Tap to start» (`.p-tap`)

    static let endShowSize: Double = 44
    static let endShowLineHeight: Double = 1.0
    static let endShowTrackingEm: Double = -0.02
    static let endShowWord = "END SHOW"

    static func endShowSpec(width: Double) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interBlack, trackingEm: endShowTrackingEm)],
                    runs: [TextRun(text: endShowWord, style: 0)],
                    lineHeightFactor: endShowLineHeight,
                    maxWidth: width,
                    maxLines: 1,
                    sizes: [endShowSize])
    }

    static let tapSize: Double = 21
    static let tapLineHeight: Double = 1.2

    static func tapSpec(_ text: String, width: Double) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interSemiBold, trackingEm: 0)],
                    runs: [TextRun(text: text, style: 0)],
                    lineHeightFactor: tapLineHeight,
                    maxWidth: width,
                    maxLines: 1,
                    sizes: [tapSize])
    }

    // MARK: Il blocco del velo: 248, riga A, 14, nome, 12, tempo e metrica

    static let blockTop: Double = 248
    static let gapRelationToName: Double = 14
    static let gapNameToTempo: Double = 12

    /// L'altezza del blocco dalle tre scritte già decise.
    static func blockHeight(relation: FittedText, name: FittedText, tempo: FittedText) -> Double {
        relation.height + gapRelationToName + name.height + gapNameToTempo + tempo.height
    }

    /// L'altezza del blocco dai soli numeri di righe e dal corpo del nome (riga A a 21/1,25; tempo a 21/1,2).
    static func blockHeight(relationLines: Int, nameLines: Int, nameSize: Double) -> Double {
        Double(relationLines) * relationSize * relationLineHeight
            + gapRelationToName
            + Double(nameLines) * nameSize * nameLineHeight
            + gapNameToTempo
            + tempoSize * tempoLineHeight
    }

    /// Dove comincia il nome e dove tempo e metrica, dall'alto del blocco.
    static func nameTop(relation: FittedText) -> Double { relation.height + gapRelationToName }
    static func tempoTop(relation: FittedText, name: FittedText) -> Double {
        nameTop(relation: relation) + name.height + gapNameToTempo
    }
}
