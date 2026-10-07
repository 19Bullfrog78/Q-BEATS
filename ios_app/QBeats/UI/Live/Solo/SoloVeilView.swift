import SwiftUI

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — V1 E V2: IL VELO PRIMA DELLA CANZONE E FRA DUE CANZONI ===
// Foglio Solo REV18, schermi V1, V2 e i1; punti 80, 89, 100, 102, 114. Testata come in K con al centro il nome dello
// show (punto 102), freccia e muto con le azioni di oggi; riga di stato come in K (punto 80); il blocco del velo a
// 248 («Next», il nome, tempo e metrica); «Tap to start» a 618–662; console nascosta (punto 89). Sotto il velo K non
// si vede e non prende tocchi: questa vista prende il posto di K (`LiveView`), su un fondo pieno. La zona del tocco
// (decisione del referee, M3 §3.2): tutto ciò che sta sotto la riga di stato, fino al fondo dell'area utile, largo
// quanto l'area utile (bande comprese); testata e riga di stato restano fuori: freccia e muto coi loro tocchi, il
// resto non fa partire niente. Il tocco fa partire la canzone con la chiamata di oggi (`runner.startCurrentSong`,
// nel chiamante). Le scritte le decide `SoloScreenDecision` (parole) e il pezzo del testo (righe e corpi).
struct SoloVeilView: View {
    let screen: SoloScreen
    let geometry: SoloPlayerGeometry
    let lights: StatusLights
    let midiLampOff: Bool
    let clickMuted: Bool
    let onExit: () -> Void
    let onToggleMute: () -> Void
    let onTap: () -> Void
    /// Alla comparsa e a ogni cambio delle scritte: per la riga di log del chiamante.
    let onShown: (SoloVeilTexts) -> Void

    var body: some View {
        let g = geometry
        let s = g.scale
        let texts = SoloVeilTexts(screen: screen, measurer: CoreTextWidthMeasurer.shared)
        ZStack(alignment: .topLeading) {
            QLiveSolo.background
                .frame(width: CGFloat(g.usableWidth), height: CGFloat(g.usableHeight))
            SoloHeaderView(title: screen.headerTitle,
                           muted: clickMuted,
                           scale: s,
                           contentOpacity: 1.0,
                           onExit: onExit,
                           onToggleMute: onToggleMute)
                .soloPlaced(g.header)
            SoloStatusRowView(lights: lights, midiLampOff: midiLampOff, scale: s,
                              sidePadding: CGFloat(g.scaled(18)))
                .soloPlaced(g.rect(sheetX: 0, sheetY: 98, width: SoloPlayerGeometry.frameWidth, height: 30))
            SoloVeilBlockView(texts: texts, scale: s)
                .soloPlaced(g.veilBlock(height: texts.blockHeight))
            SoloTapToStartView(scale: s)
                .soloPlaced(g.tapToStart)
            // La zona del tocco sta sopra le scritte (che non prendono tocchi) e sotto la riga di stato.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
                .soloPlaced(g.veilTapZone)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { onShown(texts) }
        .onChange(of: texts) { newTexts in onShown(newTexts) }
    }
}
