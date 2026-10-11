import SwiftUI

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — V4, LA FINE SCALETTA, PER TUTTI I RUOLI ===
// === A401 (10/10/2026) — SOLO REV20, PUNTO 117: AL CENTRO DELLA TESTATA IL NOME DELLO SHOW, PER I TRE RUOLI ===
// BOX5 V54, decisione 5 («la fine scaletta V4 del foglio Solo», ora per tutti); foglio Solo REV20
// (`DESIGN/QLive_Nav/2026-10-10_QLive-Player_G1-SOLO-REV20_390x844_1.html`), schermo V4 («uguale per i tre ruoli») e
// punto 117 («V4 è una vista sola per i tre ruoli (M3). Anche per Direttore e Follower al centro della testata va il
// nome dello show, nella veste del Solo (Inter 700 24 bianco .86, punto 102), come negli schermi 3 e 12 della SYNC
// REV8. [...] La riga di stato resta come dice la decisione 5.»); foglio SYNC REV8, schermi 3 e 12 (le stesse
// misure: END SHOW poco sopra il centro, «Back to Shows» in fondo). Una vista sola per i tre ruoli, sulla cornice D4
// (`SoloPlayerGeometry`), fondo `--bg` pieno e opaco su tutto lo schermo. Testata con freccia e muto, con le azioni
// di oggi (`onExit` e il muto del click), come in K, e al centro il nome dello show per tutti (punti 102 e 117: la
// stessa `SoloHeaderView`, la stessa veste); se lo show non ha nome il centro resta vuoto (D6). La riga di stato
// solo nel Solo (decisione 5: «Per ora solo nel Solo: la riga di stato [...]»). Fino ad A400 il centro della testata
// era vuoto per Direttore e Follower: il 117 supera la decisione 5 per quel solo punto (LIBRO, riga 2026-10-10).
// «END SHOW» a 360 (`.p-es`: Inter 900 44, interlinea 1, spaziatura −0,02 em, bianco pieno, centrato; la linea di
// base come nel modello di riga del pezzo del testo). «Back to Shows» in fondo (`.p-bs`: dal basso 50, margini 45,
// alto 64, raggio 20, filo interno 2 bianco .42, senza fondo; freccia `M19 12H5M11 6l-6 6 6 6` in `.ic`, 24, tratto
// 2,2; 10 fra freccia e scritta; Inter 700 19 bianco .86). Il tasto fa quello che fa oggi, per tutti (`onEndShow`).
// Vivi su V4: freccia, muto, Back to Shows; nient'altro. Prende il
// posto di `FineSetlistView`. Il Follower FUORI vede la sua faccia (`LiveView`, `!followerOutFace`).
struct EndShowView: View {
    let geometry: SoloPlayerGeometry
    /// Il centro della testata: il nome dello show, per i tre ruoli (`SoloScreenDecision.endShowHeaderTitle`).
    let title: String
    /// La riga di stato: solo nel Solo (`SoloScreenDecision.endShowStatusRow`).
    let statusRow: Bool
    let lights: StatusLights
    let midiLampOff: Bool
    let clickMuted: Bool
    let onExit: () -> Void
    let onToggleMute: () -> Void
    let onBackToShows: () -> Void

    var body: some View {
        let g = geometry
        let s = g.scale
        let endShow = TextFitter.fit(SoloVeilTypography.endShowSpec(width: SoloPlayerGeometry.frameWidth),
                                     measurer: CoreTextWidthMeasurer.shared)
        ZStack(alignment: .topLeading) {
            QLiveSolo.background
                .frame(width: CGFloat(g.usableWidth), height: CGFloat(g.usableHeight))
            SoloHeaderView(title: title,
                           muted: clickMuted,
                           scale: s,
                           contentOpacity: 1.0,
                           onExit: onExit,
                           onToggleMute: onToggleMute)
                .soloPlaced(g.header)
            if statusRow {
                SoloStatusRowView(lights: lights, midiLampOff: midiLampOff, scale: s,
                                  sidePadding: CGFloat(g.scaled(18)))
                    .soloPlaced(g.rect(sheetX: 0, sheetY: 98, width: SoloPlayerGeometry.frameWidth, height: 30))
            }
            FittedTextView(fit: endShow, colors: [QLiveSolo.white], scale: s)
                .soloPlaced(g.endShowLine)
            BackToShowsButton(scale: s, action: onBackToShows)
                .soloPlaced(g.backToShows)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// «Back to Shows» (`.p-bs`): raggio 20, filo interno 2 bianco .42, senza fondo; la freccia 24 e la scritta Inter 700 19
/// bianco .86, 10 fra le due, centrate.
struct BackToShowsButton: View {
    let scale: Double
    let action: () -> Void

    var body: some View {
        let s = CGFloat(scale)
        let color = QLiveSolo.whiteAlpha(QLiveSolo.EndShow.buttonOpacity)
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat(QLiveSolo.EndShow.buttonRadius) * s)
                    .strokeBorder(QLiveSolo.whiteAlpha(QLiveSolo.EndShow.buttonBorderOpacity),
                                  lineWidth: CGFloat(QLiveSolo.EndShow.buttonBorder) * s)
                HStack(spacing: CGFloat(QLiveSolo.EndShow.buttonGap) * s) {
                    SoloIconView(icon: .backArrow, size: CGFloat(QLiveSolo.EndShow.buttonIcon) * s, color: color)
                    Text(SoloScreenDecision.backToShows)
                        .font(.custom(SoloFonts.interBold, size: CGFloat(QLiveSolo.EndShow.buttonFontSize) * s))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: CGFloat(QLiveSolo.EndShow.buttonRadius) * s))
        }
        .buttonStyle(.plain)
    }
}
