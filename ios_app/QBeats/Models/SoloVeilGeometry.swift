import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — LE POSIZIONI DEI VELI, DI «TAP TO START» E DI V4 ===
// Punti del foglio (y dall'alto, barra di stato compresa), portati sull'apparecchio con la cornice e il fattore di
// `SoloPlayerGeometry` (D4): per il Solo e per la fine scaletta di tutti i ruoli (mandato M3 §3).
//  · il blocco del velo (`.p-vb{top:248px;left:26px;right:26px}`): parte a 248, largo 338, cresce in basso;
//  · «Tap to start» (`.p-tap`, `style="top:618px"`; tabella 3: 618–662): alto 44, largo quanto lo schermo, gruppo centrato;
//  · END SHOW (`.p-es{top:360px;left:0;right:0}`, `font:900 44px/1`): la riga alta 44 da 360;
//  · «Back to Shows» (`.p-bs{bottom:50px;left:45px;right:45px;height:64px}`): dal basso 50 sullo schermo 844, cioè da
//    730 a 794, largo 300;
//  · la zona del tocco di V1/V2 (decisione del referee, M3 §3.2): tutto ciò che sta sotto la riga di stato, fino al
//    fondo dell'area utile, largo quanto l'area utile (bande comprese); testata e riga di stato fuori;
//  · la zona senza tocco di H: dalla riga di stato alla console (il tocco non fa niente, punto 87).
extension SoloPlayerGeometry {

    static let veilBlockTop: Double = 248
    static let veilBlockX: Double = 26
    static let veilBlockWidth: Double = 338
    static let tapToStartTop: Double = 618
    static let tapToStartHeight: Double = 44
    static let endShowTop: Double = 360
    static let endShowHeight: Double = 44
    static let backToShowsBottomInset: Double = 50
    static let backToShowsSide: Double = 45
    static let backToShowsHeight: Double = 64

    /// Il blocco del velo, alto quanto il suo contenuto (in punti del foglio).
    func veilBlock(height: Double) -> SoloRect {
        rect(sheetX: Self.veilBlockX, sheetY: Self.veilBlockTop, width: Self.veilBlockWidth, height: max(height, 0))
    }

    /// «Tap to start»: 618–662, largo quanto la cornice.
    var tapToStart: SoloRect {
        rect(sheetX: 0, sheetY: Self.tapToStartTop, width: Self.frameWidth, height: Self.tapToStartHeight)
    }

    /// La riga di END SHOW: alta 44 da 360, larga quanto la cornice.
    var endShowLine: SoloRect {
        rect(sheetX: 0, sheetY: Self.endShowTop, width: Self.frameWidth, height: Self.endShowHeight)
    }

    /// «Back to Shows»: 730–794, da 45 a 345.
    var backToShows: SoloRect {
        rect(sheetX: Self.backToShowsSide,
             sheetY: Self.sheetHeight - Self.backToShowsBottomInset - Self.backToShowsHeight,
             width: Self.frameWidth - 2 * Self.backToShowsSide,
             height: Self.backToShowsHeight)
    }

    /// La zona del tocco sui veli V1/V2, in punti dell'area utile: sotto la riga di stato, fino al fondo, larga
    /// quanto l'area utile.
    var veilTapZone: SoloRect {
        let top = statusRow.maxY
        return SoloRect(x: 0, y: top, width: usableWidth, height: max(usableHeight - top, 0))
    }

    /// La zona senza tocco di H: dalla riga di stato alla console, larga quanto l'area utile.
    var resumeDeadZone: SoloRect {
        let top = statusRow.maxY
        return SoloRect(x: 0, y: top, width: usableWidth, height: max(console.minY - top, 0))
    }
}
