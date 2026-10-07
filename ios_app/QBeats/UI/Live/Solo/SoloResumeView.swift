import SwiftUI

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — H SENZA LA FILA: FERMO DOPO LO STOP, O RIENTRO CON LA SEZIONE CONSERVATA ===
// BOX5 V54, decisione 6; foglio Solo REV18, schermi H, f2 e i2, tabella 3; punti 84, 87, 88, 102, 105, 109, 111.
// Testata col nome dello show e riga di stato, come in V1. Il blocco del velo a 248 (punto 105): «Resume from » e
// la sezione nella stessa riga (`.p-va`, `.p-va b`), il nome della canzone, tempo e metrica della sezione da cui si
// riparte; senza nome «Section N» (punto 109). La console a 630 come in M2 a canzone ferma: Play al centro, Mixer
// acceso, Kill e List mode spenti (punti 84 e 88); il Play chiama `runner.startCurrentSection` (nel chiamante; BOX5,
// «RESUME = runner.startCurrentSection»). Il tocco sul velo non fa niente (punto 87): la zona dalla riga di stato
// alla console prende il tocco e lo lascia cadere (il chiamante lo scrive nel log). Vivi su H: freccia, muto, Play,
// Mixer e, a pannello aperto, i suoi cursori; nient'altro. Decisione del referee: fra la fine del blocco e la
// console niente — né la linea a 526 né «Resume from» a 540, che presentano la fila, che è del pezzo 2. Il pannello
// del mixer lo monta `LiveView` nello stesso posto che ha in K (foglio f2: «Lo stesso posto a canzone ferma»); se il
// blocco scende sotto 462 il pannello ne copre la parte bassa (caso D6, da portare a CD).
struct SoloResumeView: View {
    let screen: SoloScreen
    let geometry: SoloPlayerGeometry
    let lights: StatusLights
    let midiLampOff: Bool
    let clickMuted: Bool
    let faces: SoloConsoleFaces
    let onExit: () -> Void
    let onToggleMute: () -> Void
    let onConsoleKey: (SoloConsoleKey) -> Void
    /// Il tocco nella zona del velo: non fa niente; il chiamante lo scrive nel log.
    let onDeadTap: () -> Void
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
            // La zona senza tocco, sotto le scritte: dalla riga di stato alla console.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDeadTap() }
                .soloPlaced(g.resumeDeadZone)
            SoloVeilBlockView(texts: texts, scale: s)
                .soloPlaced(g.veilBlock(height: texts.blockHeight))
                .allowsHitTesting(false)
            SoloConsoleView(faces: faces, scale: s, onKey: onConsoleKey)
                .soloPlaced(g.console)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { onShown(texts) }
        .onChange(of: texts) { newTexts in onShown(newTexts) }
    }
}
