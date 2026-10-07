import SwiftUI
import os

struct TransportView: View {
    @ObservedObject var session: LiveSession
    // A361 — `let`, come dice BOX5 («Invarianti tecnici Layer 3», riga «`let` vs
    // `@ObservedObject` su View figli», V21): questa fascia NON si ridisegna sui cambi
    // di proprietà del motore, solo su quelli di `session`, e ogni transizione visibile
    // passa da `session.playbackState`. A360 l'aveva resa `@ObservedObject` per leggere
    // la forma della fascia dal motore: la forma si legge nel `body` a ogni ridisegno
    // della sessione, e a player aperto il ruolo non cambia — basta `let`.
    let audioEngine: AudioEngine
    @EnvironmentObject var runner: SetlistRunner

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato a tutti i `RubberBtnView` per scalare label e glyph.
    let scaleFactor: CGFloat

    /// A386 · B2b (30/09/2026) — LA FASCIA DA SOLO (foglio CD 2D-QUATER, file 2, L3): `true`
    /// quando la macchina del Follower è DA SOLO. Lo decide `LiveView`, che osserva il motore
    /// (`followerSync`) e lo passa come valore: questa fascia resta `let audioEngine` (A361)
    /// e si ridisegna perché cambia il parametro, non perché osserva il motore.
    let followerAlone: Bool
    /// B2b — lo Stop a pressione della fascia DA SOLO è scattato: `LiveView` lo porta alla
    /// stanza (`QLiveSession.followerMusicianStop`), l'unica porta dello Stop del musicista.
    let onHoldStop: () -> Void
    /// SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — le aperture del pannello del mixer (la maniglia, il trascinamento in su)
    /// passano dal chiamante con la loro causa: `LiveView` le apre col cancello di stato (non in `.standby` né in
    /// `.fineSetlist`, M3 §3.9 a) e le scrive nel registro con la causa vera (M3 §3.9 b).
    let onOpenMixer: (MixerCause) -> Void
    /// A398 — il tocco su List mode: nessuna azione, una riga nel log del chiamante.
    let onListMode: () -> Void

    private var isCountIn: Bool {
        if case .countIn = session.playbackState { return true }
        return false
    }
    private var isStandby: Bool {
        if case .standby = session.playbackState { return true }
        return false
    }
    private var isStopped: Bool { session.playbackState == .stopped }
    @State private var killFlashing = false

    // A360 (16/09/2026) — DUE FASCE, UNA REGOLA. A chi comanda il trasporto (Direttore,
    // Solo) la fascia intera di sempre, invariata. Al Follower la fascia della lastra ④
    // del foglio CD 11/09 IL-FOLLOWER-NON-TOCCA-IL-TRASPORTO: la riga-regola
    // «TRANSPORT · DIRECTOR ONLY» e il solo EMERG, dov'è e com'è oggi; escono sezione
    // indietro, play/stop, sezione avanti, loop e KILL BASE (LIBRO `2026-09-11` «CRITERIO
    // GENERALE DEL PERIMETRO DEL FOLLOWER»). Muto (testata) e maniglia del mixer restano;
    // la fascia conserva la sua altezza (la decide `LiveView`, 21%). Chi è Follower lo dice
    // `FollowerDecision` (ruolo E Link acceso dall'utente): con Link spento dall'utente
    // l'apparecchio ha la fascia intera e suona da solo. La forma si legge nel `body`
    // (A361: `audioEngine` è `let`, la fascia si ridisegna con la sessione; a player aperto
    // il ruolo non cambia).
    // ⚠️ A386 · B2b (30/09/2026) — TRE FASCE: al Follower DA SOLO la fascia ambra della lastra L3
    //    del foglio 2D-QUATER («On your own», lo Stop a pressione, EMERG com'è oggi). La fascia
    //    IN SYNC di A360/A362 resta invariata: in moto la fascia È il segnale (grigia = IN SYNC,
    //    ambra = da solo).
    var body: some View {
        let follower = audioEngine.followerDecision.isFollower
        Group {
            if follower {
                if followerAlone {
                    aloneStrip
                } else {
                    followerStrip
                }
            } else {
                commandStrip
            }
        }
        .onAppear {
            os_log("[Q-BEATS][A360] fascia montata - follower:%{public}@",
                   log: .default, type: .default, follower ? "si" : "no")
        }
    }

    // MARK: - La fascia di chi comanda il trasporto (Direttore, Solo) — invariata

    private var commandStrip: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                RubberBtnView(label: "prev sez", glyph: "◀",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.prevSection() }

                // ⚠️ CARTELLO A228 (misura, non ratifica) — `disabled: isStandby` qui sotto è
                // il SECONDO lucchetto sul Play in standby, indipendente dal velo
                // (`LiveView.swift` `StandbyOverlayView` + `.contentShape` tap-ovunque).
                // Il giorno in cui questo blocco viene tolto, il Play chiama
                // `runner.startSetlist(...)` più sotto in questo stesso blocco, che AZZERA
                // `currentSongIdx` — mentre il tocco sul velo (`startCurrentSong`) lo
                // CONSERVA. Due gesti sullo stesso stato .standby, due esiti diversi.
                // Chi toglie `isStandby` da qui deve decidere quale dei due esiti vuole,
                // non ereditarlo per caso. Misura completa: `HANDOFF/
                // MISURE_CC_2026-08-27_A228-VELO-STANDBY.md`.
                // ⚠️ MARCATURA A240 (28/08) — il Play qui sotto NON chiama più
                //    `startSetlist`: chiama `startCurrentSection`, che CONSERVA
                //    canzone e sezione (TD-stop-perde-il-punto; cartello A240 in
                //    SetlistRunner). L'asimmetria dei due gesti descritta sopra
                //    resta ma cambia faccia: velo → sezione azzerata · Play →
                //    tutto conservato. Testo sopra invariato.
                // ⚠️ MARCATURA A267 (30/08) — «velo → sezione azzerata» non è più
                //    sempre vero: con sezione conservata >0 il velo instrada su
                //    `startCurrentSection` e CONSERVA anche lui (ratifica Mauro
                //    30/08, cartello A267 in LiveView). Con sezione 0 azzera come
                //    prima. Testo sopra invariato.
                // ⚠️ MARCATURA A360 (16/09/2026) — IL RAMO `.collaborativa → .waitingForDirector`
                //    NON C'È PIÙ: questa fascia si monta solo a chi comanda il trasporto
                //    (`FollowerDecision`), e il Follower non ha PLAY. Lo stato
                //    `.waitingForDirector`, `WaitingForDirectorView`, START LOCAL e CANCEL sono
                //    usciti dal codice (LIBRO `2026-09-10` «NIENTE START LOCAL»). Il cartello
                //    CD-Q2=B che stava dentro la closure resta qui sotto come storia.
                //    -- CD-Q2=B + Bug 4 fix (Q-D1 ratificato libro mastro v15) —
                //    In modalità Collaborativa il Follower NON parte
                //    standalone al tap Play: entra in `.waitingForDirector`.
                //    Uscita: (a) Director cross-device preme Play →
                //    callback Link → audioEngine.linkStartedSubject →
                //    LiveView observer chiama runner.startSetlist;
                //    (b) tap START LOCAL nella WaitingForDirectorView;
                //    (c) tap CANCEL → dismiss a Bivio.
                //    ⚠️ MARCATURA 23/08 — «Bivio» NON ESISTE PIÙ
                //       dopo N1b: si torna alla lista Shows.
                //       Testo sopra invariato.
                //    ⚠️ MARCATURA A240 (28/08) — le uscite (a) e (b) NON
                //       passano più da `startSetlist`: l'observer sceglie
                //       `startCurrentSong` (standby) o `startCurrentSection`
                //       (conserva il punto). Testo sopra invariato.
                //    Correzione AI esterna #1 (Fase C): condizione SENZA
                //    `&& !audioEngine.linkIsConnected` — anche con Link
                //    connesso ai peer, finché Director non ha premuto
                //    Play il Follower aspetta (CD-Q2=B letterale).
                //    Lettura `currentLinkMode` da @Published mirror su
                //    AudioEngine (Q-D1: AppSettings è struct, mirror
                //    obbligatorio; nome `currentLinkMode` evita collision
                //    con `_linkMode` audio-queue privato — CI failure run
                //    26581236612).
                RubberBtnView(
                    label: isCountIn ? "stop" : (audioEngine.isPlaying ? "stop" : "play"),
                    glyph: isCountIn ? "■" : (audioEngine.isPlaying ? "■" : "▶"),
                    primary: !isStopped,
                    disabled: isStandby,
                    scaleFactor: scaleFactor) {
                        if audioEngine.isPlaying {
                            audioEngine.stop()
                        } else {
                            // Modalità Direttore: Q-BEATS è sorgente, parte
                            // standalone immediatamente.
                            // ⚠️ A240 — era `startSetlist`: azzerava canzone e
                            //    sezione, e il punto si perdeva QUI (A239, sito 1).
                            runner.startCurrentSection(audioEngine: audioEngine, session: session)
                        }
                }

                RubberBtnView(label: "next sez", glyph: "▶▶",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.nextSection() }
            }

            HStack(spacing: 6) {
                RubberBtnView(label: loopLabel, glyph: "↺",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.toggleLoop() }

                RubberBtnView(
                    label: "",
                    glyph: "KILL\nBASE",
                    disabled: isCountIn || isStandby,
                    accentColor: killFlashing ? Color(hex: "#f5b820") : nil,
                    scaleFactor: scaleFactor
                ) {
                    audioEngine.stopBacktrack()
                    withAnimation(.easeInOut(duration: 0.4)) { killFlashing = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.4)) { killFlashing = false }
                    }
                }

                listModeButton
            }

            mixerHandle
        }
        .padding(.vertical, 6)
        .gesture(mixerDrag)
    }

    // MARK: - A360 — La fascia del Follower (lastra ④: riga-regola + EMERG)

    // Stessa griglia di sempre, tre celle per riga e due righe (le celle vuote restano
    // vuote: la fascia è la zona morta sotto il pollice, e non si sposta niente). EMERG
    // occupa la sua cella di oggi, in basso a destra, con la stessa `RubberBtnView`
    // (`.ebtn` della lastra «resta in basso-destra», CD-4). La riga-regola sta a
    // sinistra, larga due celle e un intervallo, centrata in verticale sulle due righe
    // (`.tstrip` della lastra: `align-items:center`, `.trule{flex:1}`). Le misure sono
    // quelle della griglia (intervallo 6, come `spacing: 6`), nessun numero nuovo.
    private var followerStrip: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let gap: CGFloat = 6
                let cell = (geo.size.width - 2 * gap) / 3
                let rowHeight = (geo.size.height - gap) / 2
                ZStack(alignment: .bottomTrailing) {
                    followerRuleLine
                        .frame(width: 2 * cell + gap, height: geo.size.height, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    listModeButton
                        .frame(width: cell, height: rowHeight)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }

            mixerHandle
        }
        .padding(.vertical, 6)
        .gesture(mixerDrag)
    }

    /// La riga-regola della lastra ④ (`.trule`: «Transport ·<br />Director only»), a capo
    /// come nella lastra, in STAGE-CAPS (`QLiveStage.Caps`: 21 · JetBrains Mono 600 ·
    /// spaziatura 1,5 · maiuscole · bianco 0,60), corpo `token × max(1, scaleFactor)`.
    /// Le maiuscole le mette la vista, come per le righe A e C del velo.
    private var followerRuleLine: some View {
        Text("Transport \u{00B7}\nDirector only")
            .font(.jbMono(QLiveStage.Caps.weight, size: QLiveStage.scaled(QLiveStage.Caps.size, scaleFactor)))
            .tracking(QLiveStage.Caps.tracking)
            .foregroundColor(Color.white.opacity(QLiveStage.Caps.opacity))
            .textCase(.uppercase)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - A386 · B2b — La fascia DA SOLO (foglio 2D-QUATER, file 2, L3: `.qb-fa.so`)

    // «Niente copre ciò che si legge suonando»: la fascia cambia contenuto, non posto. Sfondo
    // ambra 0,08 e bordo superiore 2 ambra 0,55 (`.qb-fa.so`); dentro, il messaggio
    // (`.qb-fm p`: STAGE-CAPS 700 ambra con l'icona «fino alla stanghetta»; `em`: STAGE-SECONDARY
    // bianco 0,82, «click stops at the song's end» annuncia lo stop, L8) e la riga dei tasti
    // (`.qb-fb`: lo Stop a pressione largo quanto resta, alto 64, e la cella di EMERG larga 98,
    // intervallo 12). EMERG resta com'è oggi (la stessa `RubberBtnView`, inerte per scelta di
    // prodotto), dentro la cella che il foglio gli dà. «Transport · Director only» sparisce
    // perché in DA SOLO non è più vero: c'è uno Stop. La maniglia del mixer non c'è nella
    // lastra: resta il trascinamento (`mixerDrag`).
    // B2b-BIS — lo sfondo ambra e il bordo superiore vanno da bordo a bordo dello schermo, come
    // nella lastra: `LiveView` dà a questa fascia la larghezza intera (il margine di 16 del
    // player lo tengono gli altri figli e le altre due fasce); dentro valgono i margini del
    // foglio, `stripSide` (18) ai lati e `stripBottom` (24) sotto. Su iPhone 390 lo Stop a
    // pressione è largo 390 − 36 − 12 − 98 = 244 (foglio L3: 354 − 98 − 12).
    private var aloneStrip: some View {
        let capsSize = QLiveStage.scaled(QLiveStage.Caps.size, scaleFactor)
        let secondarySize = QLiveStage.scaled(QLiveStage.Secondary.size, scaleFactor)
        return VStack(spacing: 0) {
            Rectangle()
                .fill(QLiveStage.Follower.stripTopRule)
                .frame(height: QLiveStage.Follower.stripTopRuleWidth)
            VStack(alignment: .leading, spacing: QLiveStage.Follower.stripGap) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: capsSize * QLiveStage.Follower.bodyIconGapEm) {
                        FollowerIconView(icon: .toTheBarline,
                                         size: capsSize * QLiveStage.Follower.iconEm,
                                         color: QLiveStage.Follower.amber)
                        Text(FollowerVeilDecision.onYourOwnLine)
                            .font(.jbMono(.bold, size: capsSize))
                            .tracking(QLiveStage.Caps.tracking)
                            .foregroundColor(QLiveStage.Follower.amber)
                            .textCase(.uppercase)
                            .lineLimit(1)
                    }
                    Text(FollowerVeilDecision.clickStopsLine)
                        .font(.jbMono(QLiveStage.Secondary.weight, size: secondarySize))
                        .tracking(QLiveStage.Secondary.tracking)
                        .foregroundColor(Color.white.opacity(QLiveStage.Body.opacity))
                        .lineLimit(1)
                        .padding(.top, QLiveStage.Follower.stripLineTop)
                }
                HStack(spacing: QLiveStage.Follower.stripGap) {
                    HoldToStopButton(scaleFactor: scaleFactor, onComplete: onHoldStop)
                        .frame(height: QLiveStage.Follower.stopHeight)
                    listModeButton
                        .frame(width: QLiveStage.Follower.emergWidth, height: QLiveStage.Follower.stopHeight)
                }
            }
            .padding(.horizontal, QLiveStage.Follower.stripSide)
            .padding(.bottom, QLiveStage.Follower.stripBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .background(QLiveStage.Follower.stripFill)
        .gesture(mixerDrag)
    }

    // MARK: - Pezzi comuni alle fasce (invariati nella resa)

    /// «emerg», dov'è e com'è oggi: inerte per scelta di prodotto (`TD-emerg-bottone-morto`,
    /// marcature 18/08 e 27/08); resta al Follower (LIBRO `2026-09-11`: RESTANO muto, mixer
    /// e il tasto EMERG).
    /// ⚠️ SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — EMERG È DIVENTATO «List mode» (BOX5 V54, decisione 5: «List mode al
    ///    posto di EMERG»; LIBRO 2026-10-04 «LE STESSE PAROLE DAPPERTUTTO»; foglio SYNC REV8, schermi 2, 8, 10 e 11,
    ///    `.qb-lm` e `i-ls`): la parola e il simbolo della console del Solo, nella veste del foglio (fondo `#1f1b18`,
    ///    raggio 20, icona 24 col tratto 2,2 sopra la parola, 5 fra le due, Inter 700 17 bianco caldo .72, filo chiaro
    ///    in alto .055), nella cella e nella misura che EMERG ha in ciascuna fascia (caso D6), coi corpi della legge di
    ///    Direttore e Follower (`QLiveStage.scaled`). Senza azione e acceso, come oggi EMERG; niente veste di
    ///    pericolo. Se per loro debba essere spento lo decide Mauro al giro del sync. Il testo sopra resta come storia.
    private var listModeButton: some View {
        let iconSize = QLiveStage.scaled(QLiveStage.ListMode.icon, scaleFactor)
        let fontSize = QLiveStage.scaled(QLiveStage.ListMode.fontSize, scaleFactor)
        return Button(action: onListMode) {
            ZStack {
                RoundedRectangle(cornerRadius: QLiveStage.ListMode.radius)
                    .fill(QLiveStage.ListMode.fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: QLiveStage.ListMode.radius)
                            .strokeBorder(Color.white.opacity(QLiveStage.ListMode.highlight), lineWidth: 1)
                            .mask(alignment: .top) { Rectangle().frame(height: QLiveStage.ListMode.radius) }
                    )
                VStack(spacing: QLiveStage.ListMode.gap) {
                    SoloIconView(icon: .listMode, size: iconSize, color: QLiveStage.ListMode.text)
                    Text("List mode")
                        .font(.custom("Inter-Bold", size: fontSize))
                        .foregroundColor(QLiveStage.ListMode.text)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: QLiveStage.ListMode.radius))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mixerHandle: some View {
        if !session.showMixer {
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 28, height: 3)
                .padding(.top, 4)
                .onTapGesture { onOpenMixer(.handle) }   // A398: dal chiamante, col cancello di stato e la causa
        }
    }

    private var mixerDrag: some Gesture {
        DragGesture(minimumDistance: 20).onEnded { val in
            if val.translation.height < -30 { onOpenMixer(.dragUp) }   // A398: dal chiamante, col cancello e la causa
        }
    }

    private var loopLabel: String {
        // Placeholder — binding reale a stato loop in Fase Backtrack
        "loop"
    }
}
