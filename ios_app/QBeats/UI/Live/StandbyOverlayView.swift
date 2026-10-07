import SwiftUI

// A355 (15/09/2026) — IL VELO DICE DA DOVE: tre righe, un solo dato.
// Riga A, relazione (STAGE-CAPS): «Resume from ⟨sezione⟩» oppure «Next:» ·
// riga B, il nome della canzone (STAGE-HERO, regola del gigante) · riga C, il
// gesto (STAGE-CAPS): «Tap anywhere» a chi comanda il trasporto, «The director
// starts» al Follower.
// ⚠️ SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — a chi comanda il trasporto la riga C dice «Tap to start» con la mano
//    (forma A), nella veste `.qb-hi` del foglio SYNC REV8, 40 sotto la riga nuova di tempo e metrica (`.qb-mt`),
//    che sta 14 sotto il nome; lo slot E del Follower resta sotto di lei. Il resto del velo è quello di oggi (il
//    blocco a 248, «Stay on this screen», il nome dello show, «Next» senza i due punti, il respiro di 2,2 s per
//    ciclo intero e l'interlinea 1,04 arrivano coi giri di Direttore e Follower). Il testo sopra resta come storia. Le righe arrivano GIÀ DECISE (`StandbyOverlayDecision`,
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
// ⚠️ A386 · B2b (30/09/2026) — LO SLOT E DEL FOLLOWER È QUELLO DEL FOGLIO CD 2D-QUATER (L1,
//    `.qb-sg.ok.g2`): sul velo IN SYNC compare solo «Director signal OK» col pallino verde,
//    deciso da `FollowerVeilDecision` e disegnato da `FollowerSignalView`, allo stesso posto
//    (C→E) della lastra ⑧ di A360. Le due righe «No device connected» · «nothing will start
//    from here» sono uscite: il collegato di Link non decide più niente sul velo del Follower.
struct StandbyOverlayView: View {
    /// Le tre righe e la forma del nome, decise in `LiveView` dallo stesso dato
    /// del tocco. Era `nextSongName: String` — il nome della sola canzone.
    /// ⛔ Il caso `.standby(nextSongName:)` di `LivePlaybackState` NON cambia nome:
    ///    «la canzone che parte al prossimo tocco» è vero in tutti i casi
    ///    (`SetlistRunner`, ramo standby). Cambia solo ciò che la vista riceve.
    let decision: StandbyOverlayDecision

    /// B2b — sul Follower, lo slot E del foglio 2D-QUATER (L1): `nil` a chi comanda il trasporto.
    let followerVeil: FollowerVeilDecision?

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

                // ── SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — tempo e metrica della sezione che parte, 14 sotto il nome
                //    (foglio SYNC REV8, schermi 1, 1b e 9, `.qb-mt`: JetBrains Mono 500 17, bianco puro .45; BOX5 V54,
                //    decisione 5: «tempo e metrica sui veli dove il foglio del sync li disegna»). Lo stesso dato e la
                //    stessa scritta dei veli del Solo. Senza sezione la riga non c'è (D6). ──
                if let tempo = decision.tempoLine {
                    Text(tempo)
                        .font(.jbMono(QLiveStage.Tempo.weight, size: QLiveStage.scaled(QLiveStage.Tempo.size, scaleFactor)))
                        .foregroundColor(Color.white.opacity(QLiveStage.Tempo.opacity))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
                        .frame(maxWidth: .infinity)
                        .padding(.top, QLiveStage.Veil.gapNameToTempo)
                }

                // ── Riga C — gesto: una riga sola, le sue due stringhe sono fisse ──
                // ⚠️ A398 — la riga del gesto prende la veste `.qb-hi` (bianco .82) e sta 40 sotto la riga di tempo e
                //    metrica (`.qb-hi{margin-top:40px}`, schermo 9); per chi comanda il trasporto «Tap to start» con la
                //    mano a sinistra (forma A, `.qb-hi.tp`, `.qb-tap` di 2,1 em col tratto 1,7, .5 em fra mano e
                //    scritta); il Follower tiene «The director starts». Decisione del referee: per il Direttore il posto
                //    in basso del foglio (bottom 180) arriva col giro del Direttore; fino ad allora la riga resta nel
                //    blocco, alla distanza che il foglio dà al Follower. `gapNameToGesture` (34) non si usa più qui.
                gestureLine(decision.gestureLine, withHand: !decision.isFollower, size: capsSize)
                    .padding(.top, QLiveStage.Veil.gapTempoToGesture)

                // ── B2b — Slot E, sul Follower: «Director signal OK» col pallino verde (foglio
                //    2D-QUATER L1, `.qb-sg.ok.g2`), allo stesso posto (C→E) della lastra ⑧ di
                //    A360. La faccia la decide `FollowerVeilDecision`; qui si disegna. ──
                if let followerVeil {
                    FollowerSignalView(decision: followerVeil, scaleFactor: scaleFactor, centered: true)
                        .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
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
    /// B2b — lo slot E ora lo disegna `FollowerSignalView`; `color` resta col suo default.
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

    /// A398 — la riga del gesto nella veste `.qb-hi`: JetBrains Mono 600 21, spaziatura 1,5, MAIUSCOLE, bianco puro .82;
    /// con la mano `i-tp` a sinistra (2,1 em, tratto 1,7, .5 em di distanza) quando il tocco fa partire.
    private func gestureLine(_ text: String, withHand: Bool, size: CGFloat) -> some View {
        let color = Color.white.opacity(QLiveStage.Gesture.opacity)
        return HStack(spacing: size * QLiveStage.Gesture.gapEm) {
            if withHand {
                let hand = size * QLiveStage.Gesture.handEm
                SoloIconView(icon: .tapHand, size: hand, color: color,
                             strokeWidth: hand * QLiveStage.Gesture.handStroke / 24)
            }
            Text(text)
                .font(.jbMono(QLiveStage.Caps.weight, size: size))
                .tracking(QLiveStage.Caps.tracking)
                .foregroundColor(color)
                .textCase(.uppercase)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, QLiveStage.Veil.horizontalMargin)
        .frame(maxWidth: .infinity)
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: QLiveStage.Veil.pulsePeriod).repeatForever(autoreverses: true)) {
            pulseOpacity = QLiveStage.Veil.pulseOpacityHigh
        }
    }
}
