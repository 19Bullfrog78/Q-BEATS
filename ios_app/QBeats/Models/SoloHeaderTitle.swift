import Foundation
import Combine

// === A403 (11/10/2026) — SOLO REV22, PUNTO 118: IL NOME LUNGO IN TESTATA ===
// Foglio `DESIGN/QLive_Nav/2026-10-11_QLive-Player_G1-SOLO-REV22_390x844_1.html` (blob
// `b57b13fb26e468578dda05975bc1fa6e1b3d718c`; LIBRO, riga 2026-10-11). Punto 118: «La casella al centro della testata, larga
// 254 fra le due tonde: Inter 700 da 24 a scendere di 1 fino a 17, su una riga; a 17 quello che non sta finisce coi
// puntini. 17 è il corpo più piccolo del player: sotto non si scende. Testata, tonde e riga di stato non si muovono.
// Vale per lo show (V1, V2, V4, velo dopo lo Stop; punto 102) e per la canzone in moto (K, K0).» Riga «Testata»
// delle misure: «il nome che non sta nei 254: il corpo scende da 24 fino a 17, su una riga; a 17 i puntini, alla
// fine». La veste è quella di prima: `.p-hn{flex:1;min-width:0;text-align:center;font:700 24px/1.2 Inter;
// letter-spacing:-.01em;color:var(--w86);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}`.
// La regola sta sopra `TextFitter` (che non cambia), come il nome sui veli e la sezione di K: una riga larga 254,
// corpi da 24 a 17 a scendere di 1, vince il primo a cui il titolo sta; a 17 ciò che non sta finisce coi puntini di
// `TextFitter`, alla fine. Il limite è esatto (decisione del referee, mandato M3 §3.6): lo script del foglio (`fitH`)
// tollera 1 px, l'app no. Vale dove la testata del Solo scrive un titolo, cioè in `SoloHeaderView`: lo show su V1,
// V2, sul velo dopo lo Stop e su V4 (V4 è una vista sola per i tre ruoli, punto 117: anche per Direttore e
// Follower), la canzone in K. Il conto (K0) nell'app non è costruito.
// Solo Foundation, più Combine per il memo: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum SoloHeaderTitle {
    // La testata (`.p-hd{height:60px;gap:10px;padding:0 14px}`, `.p-rk` tonda 44) è larga 390 − 2 × 14 = 362
    // (`SoloPlayerGeometry.header`): tolte le due tonde e i due spazi resta la casella del titolo. Tonda e spazio
    // della vista (`QLiveSolo.Header.round`, `.gap`) sono questi.
    static let sidePadding: Double = 14
    static let roundDiameter: Double = 44
    static let gap: Double = 10
    /// La casella del titolo: 362 − 2 × 44 − 2 × 10 = 254 («larga 254 fra le due tonde»).
    static let width: Double = SoloPlayerGeometry.sheetWidth - 2 * sidePadding - 2 * roundDiameter - 2 * gap

    /// Il tetto: il corpo della veste (`.p-hn`).
    static let maxSize = 24
    /// Il pavimento: «17 è il corpo più piccolo del player: sotto non si scende».
    static let minSize = 17
    static let lineHeight: Double = 1.2
    static let trackingEm: Double = -0.01
    static let maxLines = 1

    /// La regola in una `TextFitSpec`: una riga larga 254, corpi da 24 a 17 a scendere di 1.
    static func spec(_ title: String) -> TextFitSpec {
        TextFitSpec(styles: [TextFitStyle(fontName: SoloFonts.interBold, trackingEm: trackingEm)],
                    runs: [TextRun(text: title, style: 0)],
                    lineHeightFactor: lineHeight,
                    maxWidth: width,
                    maxLines: maxLines,
                    sizes: TextFitSpec.descending(from: maxSize, to: minSize))
    }

    /// Il titolo della testata: corpo, riga e puntini. Vince il primo corpo a cui il titolo sta su una riga
    /// (`FittedText.fits`); a 17 ciò che non sta finisce coi puntini di `TextFitter`, alla fine. In punti del
    /// foglio: il fattore D4 si applica al risultato.
    static func fit(_ title: String, measurer: TextWidthMeasurer) -> FittedText {
        TextFitter.fit(spec(title), measurer: measurer)
    }
}

// Il fit del titolo, una volta per titolo. La testata sta anche in K, che si rivaluta a ogni battito
// (`SoloPlayerView` osserva la sessione): come per la sezione (`SoloSectionFitMemo`, A401), il fit di un titolo si
// calcola la prima volta che il titolo arriva e poi si rilegge. La vista lo tiene con `@StateObject`: l'oggetto
// nasce una volta per ogni montaggio della testata e va via con lei. È `ObservableObject` solo per questo; non ha
// campi `@Published`, quindi leggerlo e riempirlo nel body non rimette in moto il body. Si usa solo dal main.
final class SoloHeaderTitleMemo: ObservableObject {
    private var fits: [String: FittedText] = [:]

    /// Il fit del titolo: calcolato una volta (`SoloHeaderTitle.fit`), poi riletto.
    func fit(_ title: String, measurer: TextWidthMeasurer) -> FittedText {
        if let known = fits[title] { return known }
        let fresh = SoloHeaderTitle.fit(title, measurer: measurer)
        fits[title] = fresh
        return fresh
    }
}
