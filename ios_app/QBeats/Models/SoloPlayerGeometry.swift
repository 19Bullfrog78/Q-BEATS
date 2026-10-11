import Foundation

// === SOLO-G1-PEZZO-1-M2 · A397 (06/10/2026) — LA GEOMETRIA DI K: CORNICE, FATTORE, BLOCCHI ===
// Il foglio normativo del Solo (`DESIGN/QLive_Nav/2026-10-05_QLive-Player_G1-SOLO-REV18_390x844_1.html`, blob
// `bac89abc4a8968636d6c303186742608c11962b9`) misura in punti dall'alto di uno schermo 390 x 844 che comprende la
// barra di stato del telefono (`.p-sb`, da 0 a 44); le misure di K in moto sono quelle della REV9 («in moto,
// REV9»: tabella «3 · Le misure per chi costruisce»), i casi nuovi quelle della sezione C della REV18.
// Decisione D4 del referee (mandato M2, 06/10/2026): cornice di riferimento = il foglio da 44 a 810 (844 meno i
// 34 in basso dell'iPhone di riferimento), cioè 390 x 766; y nella cornice = y del foglio − 44, x come nel
// foglio; fattore unico = il minore fra larghezza utile/390 e altezza utile/766; cornice centrata nell'area
// utile; fuori dalla cornice il fondo del foglio. Il fattore entra nelle misure (corpi, diametri, spessori,
// posizioni) e viaggia come parametro alle viste, non come trasformazione della vista. Sull'iPhone di
// riferimento (area utile 390 x 763) il fattore è 1 a meno di pochi millesimi: il foglio al punto. Su iPad e
// telefoni piccoli è una legge provvisoria finché CD non disegna quegli apparecchi; per il player del Solo
// prende il posto della legge «token × max(1, scaleFactor)» della Vista LIVE.
// ⚠️ A401 (10/10/2026) — per il player del Solo fa fede la Solo REV20
//    (`DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`, blob
//    `5ac0d521143e2ad5a2f43852580173d5307b58ec`; LIBRO, riga 2026-10-10). Della geometria di K cambia un blocco
//    solo: il riquadro del teleprompter (punto 115), al suo posto qui sotto.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro. Misure in `Double`.
struct SoloRect: Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }
    var midX: Double { x + width / 2 }
    var midY: Double { y + height / 2 }

    /// Vero se i due rettangoli hanno area in comune (i bordi che si toccano non contano).
    func overlaps(_ other: SoloRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }

    /// Vero se questo rettangolo sta dentro `outer` (bordi compresi), con una tolleranza.
    func isInside(_ outer: SoloRect, tolerance: Double = 0.001) -> Bool {
        minX >= outer.minX - tolerance && minY >= outer.minY - tolerance
            && maxX <= outer.maxX + tolerance && maxY <= outer.maxY + tolerance
    }
}

struct SoloPlayerGeometry: Equatable {
    /// Lo schermo del foglio: 390 x 844, con la barra di stato (0-44) e i 34 in basso dell'iPhone di riferimento.
    static let sheetWidth: Double = 390
    static let sheetHeight: Double = 844
    static let sheetStatusBar: Double = 44
    static let sheetBottomInset: Double = 34
    /// La cornice di riferimento: dal 44 all'810 del foglio, 390 x 766.
    static let frameWidth: Double = sheetWidth
    static let frameHeight: Double = sheetHeight - sheetStatusBar - sheetBottomInset

    let usableWidth: Double
    let usableHeight: Double
    /// Il fattore unico.
    let scale: Double
    /// La cornice, nelle coordinate dell'area utile (origine in alto a sinistra dell'area utile).
    let frame: SoloRect

    init(usableWidth: Double, usableHeight: Double) {
        // Totale: un'area degenere (0 o negativa) non divide per zero e non rende misure negative.
        let w = max(usableWidth, 1)
        let h = max(usableHeight, 1)
        self.usableWidth = w
        self.usableHeight = h
        let s = min(w / Self.frameWidth, h / Self.frameHeight)
        self.scale = s
        let fw = Self.frameWidth * s
        let fh = Self.frameHeight * s
        self.frame = SoloRect(x: (w - fw) / 2, y: (h - fh) / 2, width: fw, height: fh)
    }

    /// Una misura del foglio portata sull'apparecchio.
    func scaled(_ value: Double) -> Double { value * scale }

    /// Un rettangolo del foglio (x e y dall'alto del foglio, barra di stato compresa) → area utile.
    func rect(sheetX: Double, sheetY: Double, width: Double, height: Double) -> SoloRect {
        SoloRect(x: frame.x + sheetX * scale,
                 y: frame.y + (sheetY - Self.sheetStatusBar) * scale,
                 width: width * scale,
                 height: height * scale)
    }

    // MARK: - I blocchi di K (foglio: y dall'alto, barra di stato compresa)

    /// Testata: le due tonde 44 (`.p-rk`) centrate nei 60 della `.p-hd` (44-104), cioè da 52 a 96; margini 14.
    var header: SoloRect { rect(sheetX: 14, sheetY: 52, width: 362, height: 44) }
    /// Riga di stato (`.p-rl`): 98-128, margini 18.
    var statusRow: SoloRect { rect(sheetX: 18, sheetY: 98, width: 354, height: 30) }
    /// Le spie (`.p-lp`, `.lp`): 156-202, fila centrata larga al massimo 354, centro a 179.
    var beatLights: SoloRect { rect(sheetX: 18, sheetY: 156, width: 354, height: 46) }
    /// Battuta e tempo (`.p-bc`): 226-252.
    var barRow: SoloRect { rect(sheetX: 18, sheetY: 226, width: 354, height: 26) }
    /// La barra delle battute (`.p-bm`, `.bm`): 264-276.
    var barMeter: SoloRect { rect(sheetX: 18, sheetY: 264, width: 354, height: 12) }
    /// Il teleprompter (`.p-se`): 284-457, riquadro 366 x 173, margini 12.
    /// ⚠️ A401 (10/10/2026) — SOLO REV20, PUNTO 115 (cambia il 51). Era 346-446, alto 100. Foglio
    /// `DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`, tabella della sezione R, riga
    /// «Riquadro del teleprompter»: «284–457», «largo 366, margini 12 · alto 173»; `.p-se{top:284px;left:12px;
    /// right:12px;height:173px}`. Comincia 8 sotto la barra delle battute (276) e finisce 5 sopra il pannello del
    /// mixer aperto (462): il nome non si sposta e non va sotto il pannello. Il resto di K non si muove.
    var prompter: SoloRect { rect(sheetX: 12, sheetY: 284, width: 366, height: 173) }
    /// Next (`.p-nx`): 516-576.
    var next: SoloRect { rect(sheetX: 18, sheetY: 516, width: 354, height: 60) }
    /// La barra della canzone (`.p-sp`): 596-606.
    var songBar: SoloRect { rect(sheetX: 18, sheetY: 596, width: 354, height: 10) }
    /// La console B (`.kB`): 630-806, 354 x 176.
    var console: SoloRect { rect(sheetX: 18, sheetY: 630, width: 354, height: 176) }
    /// Il pannello del mixer aperto (punto 111; decisione D2 (b) del referee): bordo in basso a 622, 8 sopra la
    /// console, alto 160 (la misura giusta del foglio, da 462 a 622: l'altezza non si misura più sullo schermo),
    /// largo quanto la cornice (`.mxp{left:0;right:0}`).
    var mixerPanel: SoloRect { rect(sheetX: 0, sheetY: 462, width: Self.frameWidth, height: 160) }

    /// I nove blocchi a schermo, nell'ordine dall'alto (il pannello del mixer non c'è: sta sopra due di loro).
    var blocks: [SoloRect] {
        [header, statusRow, beatLights, barRow, barMeter, prompter, next, songBar, console]
    }
    /// L'area utile come rettangolo.
    var usableArea: SoloRect { SoloRect(x: 0, y: 0, width: usableWidth, height: usableHeight) }
}
