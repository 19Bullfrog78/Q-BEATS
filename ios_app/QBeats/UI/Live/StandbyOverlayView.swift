import SwiftUI

// A355 (15/09/2026) — IL VELO DICE DA DOVE: tre righe, un solo dato.
// Riga A, relazione (STAGE-CAPS): «Resume from ⟨sezione⟩» oppure «Next:» ·
// riga B, il nome della canzone (STAGE-HERO, regola del gigante) · riga C, il
// gesto (STAGE-CAPS): «Tap anywhere» a chi comanda il trasporto, «The director
// starts» al Follower. Le righe arrivano GIÀ DECISE (`StandbyOverlayDecision`,
// costruita in `LiveView` dallo stesso dato che sceglie la ripartenza): questa
// vista non decide niente, mette a schermo. Nessuna riga di count-in, in nessun
// caso (BOX5, invariante «Il velo NON porta righe di count-in finché il
// count-in non suona»). Nessuna grandezza scritta qui: token `QLiveStage`
// (`QLiveKit.swift`), scala di palco P = 17.
// Fonti: LIBRO 2026-08-30 «⑤ IL VELO DEL PLAYER DEVE DIRE DOVE RIPARTE» · LIBRO
// 2026-09-09/11 «IL TRASPORTO È DEL DIRETTORE» · LIBRO 2026-09-11 «CRITERIO GENERALE
// DEL PERIMETRO DEL FOLLOWER» · BOX5 «SCALA DI PALCO» ·
// foglio CD 11/09 IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO lastre ①②⑥ (`.vlbl`,
// `.vnm`, `.vhint`) · LA-TABELLA-FINALE §③ e riga «velo» delle MISURE.
struct StandbyOverlayView: View {
    /// Le tre righe e la forma del nome, decise in `LiveView` dallo stesso dato
    /// del tocco. Era `nextSongName: String` — il nome della sola canzone.
    /// ⛔ Il caso `.standby(nextSongName:)` di `LivePlaybackState` NON cambia nome:
    ///    «la canzone che parte al prossimo tocco» è vero in tutti i casi
    ///    (`SetlistRunner`, ramo standby). Cambia solo ciò che la vista riceve.
    let decision: StandbyOverlayDecision

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Ricevuto come parametro esplicito da `LiveView` per uniformità
    /// (denominatore 390pt unico per tutta la Vista LIVE). Il
    /// `GeometryReader` interno serve invece per il layout verticale
    /// (Spacer 0.27 × height) e NON va toccato.
    /// A355 — i corpi seguono `token × max(1, scaleFactor)` (BOX5 «Fra device»);
    /// distanze e margine restano in punti, come il resto della Vista LIVE.
    let scaleFactor: CGFloat

    /// A356 — l'altezza della testata che sta sopra il velo. Il velo è corto (parte
    /// sotto la testata, decisione 13) ma le tre righe restano dove stavano col velo
    /// intero: lo spazio in alto è 0,27 dell'altezza intera (velo + testata) meno la
    /// testata. Il valore 0,27 resta quello di sempre.
    let headerHeight: CGFloat

    @State private var pulseOpacity: Double = QLiveStage.Veil.pulseOpacityLow

    var body: some View {
        let capsSize = QLiveStage.scaled(QLiveStage.Caps.size, scaleFactor)
        let heroSize = QLiveStage.scaled(QLiveStage.Hero.size, scaleFactor)
        let floorSize = QLiveStage.scaled(QLiveStage.Next.size, scaleFactor)
        // Regola del gigante (BOX5 «SCALA DI PALCO»): fino a 12 caratteri UNA riga,
        // che scende da HERO fino al pavimento NEXT e non oltre; da 13 DUE righe al
        // pavimento, senza rimpicciolire; l'ellissi è la coda di SwiftUI oltre la
        // seconda riga, che per le soglie di CD scatta solo oltre 25 caratteri.
        let oneLine = decision.nameForm == .oneLine
        let nameSize = oneLine ? heroSize : floorSize

        GeometryReader { geo in
            VStack(spacing: 0) {
                // 0,27 dell'altezza INTERA (velo + testata), meno la testata che sta sopra
                // il velo: la posizione verticale è quella del velo intero (A356).
                Spacer().frame(height: (geo.size.height + headerHeight) * 0.27 - headerHeight)

                // ── Riga A — relazione: fino a due righe, centrata, a capo sulle parole,
                //    ellissi solo oltre la seconda — il nome della sezione è identificazione
                //    come quello della canzone (LA-TABELLA-FINALE §③), non si taglia (A356) ──
                capsLine(decision.relationLine, size: capsSize, maxLines: 2)

                // ── Riga B — il nome, come è scritto: niente `.uppercased()` (il foglio
                //    `.vnm` non ha il maiuscolo, che invece hanno `.vlbl` e `.vhint`) ──
                Text(decision.songName)
                    .font(.custom(QLiveStage.Hero.fontName, size: nameSize))
                    .tracking(QLiveStage.Hero.tracking)
                    .foregroundColor(.white)
                    .lineLimit(oneLine ? 1 : 2)
                    .minimumScaleFactor(oneLine ? QLiveStage.Next.size / QLiveStage.Hero.size : 1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .opacity(pulseOpacity)
                    .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
                    // A128 — CENTRATURA ORIZZONTALE. `BOX5_QBEATS.md:253`: «mostra il nome
                    // canzone successiva AL CENTRO SCHERMO». Prima di questa riga il nome
                    // usciva TUTTO A SINISTRA sul device.
                    // ⛔ IL DIFETTO NON ERA `.multilineTextAlignment(.center)` QUI SOPRA, e
                    //    va capito o si ripete: quella allinea le righe FRA LORO dentro il
                    //    frame del testo, non allarga il frame e non lo centra nel genitore.
                    //    Le due modifiche fanno lavori diversi e servono ENTRAMBE.
                    // ⚠️ LA CAUSA VERA È UN'ASIMMETRIA DEL VStack QUI SOPRA: in verticale
                    //    si allarga perché lo `Spacer()` finale spinge lungo l'asse della
                    //    pila; in ORIZZONTALE non spinge nulla, quindi il VStack si stringe
                    //    sul contenuto — e il `GeometryReader` posa il proprio figlio in
                    //    ALTO A SINISTRA. Mancava un vincolo di larghezza, ed è questo.
                    // ✅ Il `GeometryReader` resta dov'è, come prescrive `BOX5:256`: questa
                    //    riparazione ci convive, non lo sostituisce.
                    // Forma: `.frame(maxWidth: .infinity)` — allineamento predefinito
                    // `.center`. È l'idioma già in uso nella stessa cartella su sei siti
                    // (`OverlayStopView.swift:45`, `WaitingForDirectorView.swift:60` e `:77`,
                    // `MixerOverlayView.swift:23` e `:72`, `RubberBtnView.swift:36`).
                    // ⚠️ VA DOPO `.padding`, non prima: così la larghezza piena avvolge il
                    //    testo GIÀ spaziato e i 20pt restano un margine interno anche a nome
                    //    lungo. Invertendo, il padding si sommerebbe FUORI dal frame pieno.
                    // ⚠️ A355 — i 20pt sono diventati il token `QLiveStage.Veil.horizontalMargin`
                    //    (26, LA-TABELLA-FINALE §③); il ragionamento sull'ORDINE vale uguale,
                    //    e lo stesso idioma vale per le righe A e C (`capsLine`).
                    .frame(maxWidth: .infinity)
                    .padding(.top, QLiveStage.Veil.gapRelationToName)

                // ── Riga C — gesto: una riga sola, le sue due stringhe sono fisse ──
                capsLine(decision.gestureLine, size: capsSize, maxLines: 1)
                    .padding(.top, QLiveStage.Veil.gapNameToGesture)

                // ── A360 — Slot E, solo sul Follower senza nessun apparecchio collegato
                //    (lastra ⑧ del foglio CD 11/09, `.vlink`): «No device connected» in
                //    STAGE-CAPS ambra, «nothing will start from here» in STAGE-SECONDARY,
                //    minuscola come è scritta. C→E e il salto fra le due righe sono le
                //    distanze della lastra × k (`QLiveStage.Veil`). Nessun tocco, nessuna
                //    scorciatoia, nessun invito a spegnere Link: due righe e basta. Quando
                //    la decisione cambia (un apparecchio si collega) le righe spariscono. ──
                if decision.showsNoDeviceLines {
                    VStack(spacing: QLiveStage.Veil.gapStatusLines) {
                        capsLine(StandbyOverlayDecision.noDeviceLine, size: capsSize, maxLines: 1,
                                 color: QLiveStage.Veil.statusAmber)
                        secondaryLine(StandbyOverlayDecision.nothingStartsLine,
                                      size: QLiveStage.scaled(QLiveStage.Secondary.size, scaleFactor))
                    }
                    .padding(.top, QLiveStage.Veil.gapGestureToStatus)
                }

                Spacer()
            }
        }
        .onAppear { startPulse() }
    }

    /// STAGE-CAPS: JetBrains Mono 600 · spaziatura 1,5 · MAIUSCOLE · bianco 0,60.
    /// Le maiuscole le mette la vista (stile), non il dato (copy dei fogli CD).
    /// A360 — `color` esiste per la riga 1 dello slot E, ambra: il resto è identico.
    private func capsLine(_ text: String, size: CGFloat, maxLines: Int,
                          color: Color = Color.white.opacity(QLiveStage.Caps.opacity)) -> some View {
        Text(text)
            .font(.jbMono(QLiveStage.Caps.weight, size: size))
            .tracking(QLiveStage.Caps.tracking)
            .foregroundColor(color)
            .textCase(.uppercase)
            .lineLimit(maxLines)
            .multilineTextAlignment(.center)
            .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
            .frame(maxWidth: .infinity)
    }

    /// A360 — STAGE-SECONDARY: JetBrains Mono 500 · spaziatura 0,3 · bianco 0,60, senza
    /// maiuscole (la riga 2 dello slot E è minuscola nella lastra ⑧, `.vlink .c`).
    private func secondaryLine(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.jbMono(QLiveStage.Secondary.weight, size: size))
            .tracking(QLiveStage.Secondary.tracking)
            .foregroundColor(Color.white.opacity(QLiveStage.Secondary.opacity))
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
            .frame(maxWidth: .infinity)
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: QLiveStage.Veil.pulsePeriod).repeatForever(autoreverses: true)) {
            pulseOpacity = QLiveStage.Veil.pulseOpacityHigh
        }
    }
}
