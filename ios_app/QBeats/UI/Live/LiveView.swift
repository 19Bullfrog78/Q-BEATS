import SwiftUI
import os

struct LiveView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var runner: SetlistRunner
    /// Nodo A N0 — seam d'uscita fornito dal presenter (LiveRootView ←
    /// HomeRootView.presentLive). Inoltrato ai 2 leaf d'uscita reali:
    /// LiveHeaderView (back) e WaitingForDirectorView (CANCEL).
    let onExit: () -> Void
    @StateObject private var session = LiveSession()
    // L1.b — Tick di riferimento per il bar counter relativo alla sezione corrente.
    // beatTickCounter di AudioEngine cresce monotono dalla partenza; per resettare
    // il display "Battuta X di Y" ad ogni cambio sezione manteniamo qui in Layer 3
    // il primo tick della sezione corrente, e calcoliamo `currentBar` come tick relativo.
    @State private var sectionStartTick: Int = 1
    @State private var pendingSectionStart: Bool = false
    // P2 — Finestra "fade post-sezione naturale": acceso fra l'autostop L1.a e
    // lo spegnimento sincronizzato di segmento+LED, durata = un beat al BPM corrente.
    @State private var sectionHold: Bool = false

    // MARK: - Mirror UI per cambi sezione SEAMLESS (TD #38(a) + #40 fix, 17/05/2026)
    //
    // I @Published `audioEngine.beatsPerBar`, `currentAccentPattern`,
    // `currentSectionRepetitions` vengono dispatchati su main dal ramo
    // SEAMLESS di `scheduleNextBuffer` (step h) durante l'ULTIMO beat della
    // sezione precedente — 1 beat PRIMA del cambio audio effettivo (atomic
    // exchange DSP al downbeat nuova sezione).
    //
    // Senza buffering, la UI vedeva il nuovo BPB / accent / total subito al
    // beat finale sezione precedente, causando 3 sintomi:
    //   - TD #38(a) Sez 5/4 ultimo slot MetSlotStripView non illuminato
    //   - TD #40 flash microbar al cambio sezione (cambio BPM, BPB invariato)
    //   - TD #41 risolto separatamente in SetlistRunner via beatTickSubject
    //
    // Strategia: mirror @State (`display*`) usati dal body. Su arrivo @Published,
    // se `audioEngine.isPlaying == true` siamo in finestra SEAMLESS → bufferizza
    // in `pending*`. Altrimenti (setup, post-Stop, Q-Stage→LiveView return)
    // applica subito al mirror. Il handler `beatTickSubject` applica i pending
    // al primo tick post-arrivo (= primo beat nuova sezione audio).
    @State private var displayBpb: UInt32 = 4
    @State private var displayAccentPattern: [UInt8] = [2, 1, 1, 1]
    @State private var pendingBpb: UInt32? = nil
    @State private var pendingAccentPattern: [UInt8]? = nil
    @State private var pendingReps: Int? = nil

    // MARK: - Computed UI helpers

    /// Badge HEAD CD-Q1=B (libro mastro v14, 27/05/2026) propagato a
    /// `LiveHeaderView`. Nil se Link disabilitato (nessun badge visibile —
    /// coerente con i LED di connessione che pure scompaiono quando
    /// `linkIsConnected == false`).
    ///
    /// `audioEngine.currentLinkMode` è il mirror `@Published` su AudioEngine
    /// (Q-D1 ratificato libro mastro v15: AppSettings è `struct`, non
    /// `ObservableObject` → mirror obbligatorio; nome `currentLinkMode`
    /// invece di `linkMode` per evitare collisione del backing field
    /// sintetizzato `_linkMode: Published<...>` con `_linkMode: LinkMode`
    /// audio-queue privato — CI failure run 26581236612). SwiftUI
    /// ri-renderizza LiveView quando `currentLinkMode` o `linkEnabled`
    /// cambiano → questa computed viene ricalcolata automaticamente.
    ///
    /// Caveat R3-α: in Fase 6-7 implementiamo solo il badge HEAD
    /// (Bug 2.a). Il counter offset "bar 2 di N" (Bug 2.b) è rimandato a
    /// Fase 6-7-bis.
    private var linkRoleBadge: String? {
        guard audioEngine.linkEnabled else { return nil }
        switch audioEngine.currentLinkMode {
        case .direttore:     return "DIRECTOR"
        case .collaborativa: return "FOLLOWER"
        case .standalone:    return "SOLO"   // naming Decisione 2 CD; badge visibile solo se linkEnabled (guard :63)
        }
    }

    var body: some View {
        GeometryReader { geo in
            // TD #23 (17/05/2026) — scaleFactor responsive iPad v1.
            // Baseline 390pt = larghezza geo.size.width reale su iPhone 13
            // portrait, misurata empiricamente con log Fase 1 (commit adfcc39):
            //   "[QBEATS][ScaleFactor] geo.size.width = 390.000000".
            // Su iPad Mini (~744pt) scaleFactor ≈ 1.91; su iPad Pro 12.9"
            // (~1024pt portrait) ≈ 2.63. Tutti i 24 callsite font in UI/Live/
            // moltiplicano la loro pt size per scaleFactor. Spacing/padding
            // restano pt assoluti per non destabilizzare il layout esistente.
            // Unica fonte di verità: ricalcolato qui, propagato come parametro
            // CGFloat a tutti i sub-view che ne hanno bisogno.
            let scaleFactor: CGFloat = geo.size.width / 390
            ZStack {
                Color(hex: "#0e0e10").ignoresSafeArea(.all)

                let isStandby: Bool = {
                    if case .standby = session.playbackState { return true }
                    return false
                }()

                VStack(spacing: 0) {
                    LiveHeaderView(session: session, onExit: onExit, scaleFactor: scaleFactor, linkRoleBadge: linkRoleBadge)
                        .frame(height: geo.size.height * 0.08)
                    MetSlotStripView(pattern: accentPatternToStrings(displayAccentPattern), beatActive: session.beatActive)
                        .frame(height: geo.size.height * 0.10)
                    BarCounterView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState, scaleFactor: scaleFactor)
                        .frame(height: geo.size.height * 0.08)
                    MicroSegBarView(current: session.currentBar, total: session.totalBarsInSection, state: session.playbackState, sectionHold: sectionHold)
                        .frame(height: geo.size.height * 0.04)
                    VStack(spacing: 0) {
                        TeleprompterCapsuleView(session: session, scaleFactor: scaleFactor)
                            .frame(height: geo.size.height * 0.35)
                        MacroBarView(current: session.macroBarCurrent, total: session.macroBarTotal, state: session.playbackState)
                            .frame(height: geo.size.height * 0.02)
                        POIView(nextSection: session.nextSectionName, nextSong: session.nextSongName, scaleFactor: scaleFactor)
                            .frame(height: geo.size.height * 0.10)
                        HandleStripView()
                            .frame(height: geo.size.height * 0.02)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                if value.translation.height > 15 {
                                    session.showMixer = true
                                }
                            }
                    )
                    TransportView(session: session, audioEngine: audioEngine, scaleFactor: scaleFactor)
                        .frame(height: geo.size.height * 0.21)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .opacity(isStandby ? 0.10 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isStandby)

                if case .standby(let nextSong) = session.playbackState {
                    StandbyOverlayView(nextSongName: nextSong, scaleFactor: scaleFactor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            runner.startCurrentSong(audioEngine: audioEngine, session: session)
                        }
                }

                if case .overlayStop(let sec, let song) = session.playbackState {
                    OverlayStopView(sectionName: sec, songName: song, audioEngine: audioEngine, scaleFactor: scaleFactor)
                }

                if case .fineSetlist = session.playbackState {
                    FineSetlistView(scaleFactor: scaleFactor)
                }

                // CD-6 (libro mastro v14, 27/05/2026) — Vista WAITING FOR
                // DIRECTOR per Follower Collaborativo in attesa che il
                // Director cross-device prema Play. Entry da TransportView
                // tap Play con `linkMode == .collaborativa`. Uscite:
                //  (a) Director starta → callback Link → linkStartedSubject
                //      → observer più sotto → runner.startSetlist →
                //      session.playbackState = .playing (via runner →
                //      audioEngine.start → audioEngine.$playbackState
                //      observer riga ~165) → questa view scompare;
                //  (b) tap START LOCAL → callback `onStartLocal` qui sotto
                //      → runner.startSetlist standalone;
                //  (c) tap CANCEL → `onExit()` in WaitingForDirectorView
                //      (seam N0, fornito dal presenter) → il presenter
                //      dismissa lo UIHostingController → ritorno a Home
                //      (deviazione esplicita da CD-Q2=B "→ Select Setlist"
                //      — Select Setlist non esiste ancora, F2.3 aperto;
                //      ratificata 28/05/2026).
                if case .waitingForDirector = session.playbackState {
                    WaitingForDirectorView(scaleFactor: scaleFactor, onExit: onExit) {
                        // START LOCAL — utente decide di partire standalone
                        // ignorando l'attesa Director. Nessun guard idempotenza
                        // esplicito: WaitingForDirectorView è renderizzata
                        // SOLO in `.waitingForDirector`, quindi questa
                        // closure scatta solo in quello stato.
                        runner.startSetlist(audioEngine: audioEngine, session: session)
                    }
                }

                VStack(spacing: 0) {
                    Spacer()
                    if session.showMixer {
                        Color.clear
                            .frame(height: geo.size.height * 0.49)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                session.showMixer = false
                            }
                        MixerOverlayView(session: session, audioEngine: audioEngine, scaleFactor: scaleFactor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(session.showMixer)

            }
        }
        .onDisappear { audioEngine.stop() }
        .onAppear {
            // Sincronizzazione iniziale mirror UI con stato corrente AudioEngine.
            // Necessario quando l'utente entra in Vista LIVE dopo aver modificato
            // BPB/AccentPattern in altre schermate (es. ContentView Q-Beats Studio).
            // Senza questo, i mirror restano sui valori @State init (4, [2,1,1,1])
            // fino al primo beat tick.
            displayBpb = audioEngine.beatsPerBar
            displayAccentPattern = audioEngine.currentAccentPattern
            // Problema A fix (27/05/2026) — Popola il display LiveSession dalla
            // prima sezione della setlist caricata, così al primo ingresso in
            // Vista LIVE l'utente vede subito nome canzone, sezione corrente,
            // next sezione, macrobar — senza dover tappare Play. Prima di questo
            // fix la videata appariva "vuota" finché non partiva il playback
            // (updateSessionDisplay veniva chiamato solo in
            // prepareAndStartCurrentSection, dentro Play).
            //
            // NB nomenclatura: questo NON è il "Bug 1" del RECAP 24/05 (Follower
            // no update cross-device — Problema B). Questo è Problema A locale.
            // Coerente con TD #28 (17/05/2026): stato iniziale `.stopped`, no
            // overlay standby, videata deve mostrare dati setlist caricata.
            runner.primeDisplay(session: session)
            // Sync displayBpb/displayAccentPattern dalla prima sezione del runner.
            // Override il sync da audioEngine sopra: la setlist caricata è "verità"
            // di display, lo stato pendente in audioEngine può essere stale
            // (es. utente ha aperto Q-Stage dopo aver caricato la setlist).
            if let section = runner.currentSection {
                displayBpb = section.beatsPerBar
                displayAccentPattern = section.accentPattern
            }
        }
        // MARK: - AudioEngine → LiveSession sync
        .onReceive(audioEngine.$playbackState) { state in
            switch state {
            case .stopped:
                // L1.b: il runner gestisce .standby e .fineSetlist impostando
                // session.playbackState PRIMA di chiamare audioEngine.stop().
                // Lo stop() dispatcha .stopped su main qualche ms dopo —
                // NON sovrascrivere stati già impostati dal runner.
                switch session.playbackState {
                case .standby, .fineSetlist:
                    return
                default:
                    break
                }
                session.playbackState = .stopped
                // P2 sync stop manuale: spegnimento all'unisono LED+trattini.
                // Se sectionHold=false → stop manuale (o overlay) → reset beatActive
                // subito (LED metronomo si spegne insieme ai trattini gia gestiti
                // dal gate state==.playing in MicroSegBarView).
                // Se sectionHold=true → autostop in corso → NON toccare beatActive:
                // ci pensa l'asyncAfter di sectionEndedSubject a fare il reset
                // sincronizzato dopo durata-beat (mantiene il fade di ~500ms).
                // Ordine eventi su main: sectionEndedSubject.send() viene processato
                // PRIMA di playbackState=.stopped (dispatch async successivo dalla
                // stop()), quindi quando arrivo qui sectionHold e' gia' true se
                // siamo in autostop.
                if !sectionHold {
                    session.beatActive = 0
                }
            case .countIn:
                session.playbackState = .countIn(countdown: 4)
            case .playing:
                session.playbackState = .playing
                // P2: chiusura della finestra fade se l'utente preme Play durante
                // i ~500ms post-autostop (asyncAfter pendente sara' poi no-op via guard).
                sectionHold = false
                pendingSectionStart = false
            case .pausedAwaitingChoice(let sec, let song):
                session.playbackState = .overlayStop(sectionName: sec, songName: song)
                session.beatActive = 0
                sectionHold = false
            }
        }
        .onReceive(audioEngine.$currentBPM) { bpm in
            session.currentBPM = bpm
        }
        .onReceive(audioEngine.$beatsPerBar) { beats in
            // TD #38(a) fix: durante setlist playing bufferizza al next tick
            // (finestra SEAMLESS). Fuori playing (setup, Stop, Q-Stage→LiveView
            // return) applica subito al mirror.
            if audioEngine.isPlaying {
                pendingBpb = beats
                // Bug 2.b fix: in playing currentTimeSig NON è più applicato
                // subito (anticipava la barretta di 1 beat → desync visivo
                // cross-device). È differito al primo beat della nuova sezione
                // nell'handler beatTickSubject, nello stesso blocco di displayBpb.
            } else {
                displayBpb = beats
                // Pre-Play / setup / Stop / Q-Stage→LiveView: applica subito,
                // display coerente fuori dalla finestra SEAMLESS.
                session.currentTimeSig = timeSigString(for: beats)
            }
        }
        .onReceive(audioEngine.$currentAccentPattern) { ap in
            // TD #38(a) fix: stesso pattern di $beatsPerBar.
            if audioEngine.isPlaying {
                pendingAccentPattern = ap
            } else {
                displayAccentPattern = ap
            }
        }
        .onReceive(audioEngine.$currentSectionRepetitions) { reps in
            // TD #40 fix: stesso pattern di $beatsPerBar.
            if audioEngine.isPlaying {
                pendingReps = reps
            } else {
                session.totalBarsInSection = reps
            }
        }
        .onReceive(audioEngine.beatTickSubject) { tickN in
            // Bug 2.b — ancora deterministica del 1° beat di un avvio fresco.
            // tickN==1 identifica intrinsecamente il primo beat dopo start()
            // (beatTickCounter azzerato in start(), AudioEngine.swift:635): nessun
            // flag armato in .playing, nessuna corsa col primo tick. L'offset è
            // già finale qui (work item SHARED pubblica startBeatOffset PRIMA del
            // 1° scheduleNextBuffer). Director/standalone: startBeatOffset=0 →
            // sectionStartTick=1. Follower: startBeatOffset = bar d'ingresso →
            // sectionStartTick = 1 - offset. Un avvio fresco supera SEMPRE il marker
            // di cambio sezione (un avanzamento mid-canzone NON riavvia il motore
            // → tickN!=1) → azzera pendingSectionStart.
            if tickN == 1 {
                sectionStartTick = 1 - audioEngine.startBeatOffset
                pendingSectionStart = false
            } else if pendingSectionStart {
                // L1.b — avanzamento sezione mid-canzone (seamless): il 1° tick
                // della nuova sezione diventa l'ancora → currentBar=1.
                sectionStartTick = tickN
                pendingSectionStart = false
            }
            // TD #38(a) + #40 fix: applica i mirror bufferizzati al primo
            // tick post-arrivo @Published (= primo beat nuova sezione audio).
            if let bpb = pendingBpb {
                displayBpb = bpb
                // Bug 2.b fix: il time-sig dell'header flippa QUI, sullo stesso
                // tick della barretta (displayBpb) e del cambio audio (downbeat
                // Link-synced) → header e barretta condividono un unico punto di
                // applicazione e non possono più divergere per costruzione.
                session.currentTimeSig = timeSigString(for: bpb)
                pendingBpb = nil
            }
            if let ap = pendingAccentPattern {
                displayAccentPattern = ap
                pendingAccentPattern = nil
            }
            if let reps = pendingReps {
                session.totalBarsInSection = reps
                pendingReps = nil
            }
            let bpb = max(1, Int(displayBpb))
            // Tick relativo alla sezione corrente (1-based dentro la sezione).
            let relativeTick = tickN - sectionStartTick + 1
            session.beatActive = ((relativeTick - 1) % bpb) + 1
            session.currentBar = ((relativeTick - 1) / bpb) + 1
        }
        // L1.b — Marker per il cambio sezione: alla transizione di
        // currentSectionIdx (ramo avanza o ramo standby), il prossimo tick
        // generato dall'audio engine sarà il primo della nuova sezione e
        // diventerà sectionStartTick. Il ramo standby chiama audioEngine.stop()
        // → nessun tick fino al prossimo startCurrentSong, che farà partire
        // l'engine fresh (beatTickCounter=0); il primo tick=1 sarà catturato
        // qui come sectionStartTick.
        .onReceive(runner.$currentSectionIdx) { _ in
            pendingSectionStart = true
        }
        .onReceive(audioEngine.$audioMode) { mode in
            session.isProMode = mode == .pro
        }
        // P2 — Fade SINCRONIZZATO segmento+LED a fine sezione NATURALE (autostop L1.a).
        // sectionHold=true tiene acceso il segmento durante la finestra di fade
        // (override del gate state==.playing). Dopo durata-beat al BPM corrente,
        // sectionHold=false E beatActive=0 dispatchati nello stesso istante:
        // segmento e LED si spengono INSIEME, esattamente quello che serve a fine
        // sezione naturale ("metronomo e segmento si comportano insieme").
        // Stop manuale: NON emette il subject — segmento si spegne subito al
        // .stopped (Test 4 verde) e LED resta da TD#10.
        // Guard su .stopped: se l'utente preme Play durante il fade, lo switch
        // su .playing ha gia' resettato sectionHold; questo asyncAfter diventa
        // un no-op silenzioso.
        .onReceive(audioEngine.sectionEndedSubject) { _ in
            sectionHold = true
            let beatDurationSeconds = 60.0 / max(audioEngine.currentBPM, 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + beatDurationSeconds) {
                if case .stopped = session.playbackState {
                    sectionHold = false
                    session.beatActive = 0
                }
            }
        }
        // CD-6 / Bug 4 fix (28/05/2026) — Observer Opzione C orchestrazione
        // cross-device. AudioEngine emette `linkStartedSubject` dal callback
        // Link `set_start_stop_callback` (righe ~436-442 di AudioEngine.swift)
        // DOPO `engine.start()` quando un Director peer ha premuto Play e
        // il nostro engine flippa da non-playing a starting. Qui orchestriamo
        // la sezione corrente: in `.standby` `runner.startCurrentSong(...)`
        // (preserva `currentSongIdx`), altrimenti `runner.startSetlist(...)` che
        // resetta indici a 0 e fa il setup completo (setBeatsPerBar,
        // setAccentPattern, loadSection, setBPM) — senza questo il Follower
        // partirebbe audio ma `_sectionTotalBeats=0` → counter all'infinito
        // + nome canzone vuoto (Problema B / Bug 4).
        //
        // Gate idempotenza Q-D3 ratificato: se siamo già in `.playing` —
        // o perché un precedente callback ha già orchestrato (transizione
        // .waitingForDirector → .playing tramite startSetlist →
        // audioEngine.start → `.onReceive(audioEngine.$playbackState)`
        // riga ~165 mirrora su session), o perché Q-B è sorgente Direttore
        // (in quel caso il callback non arriva neanche: guard early-return
        // AudioEngine.swift riga ~432) — return silenzioso per evitare
        // doppio reset indici runner (ramo `else`: `startSetlist` resetta
        // `currentSongIdx=0` `currentSectionIdx=0` — Q-D3 Read).
        //
        // SwiftUI `.onReceive(...)` gestisce automaticamente il cancellable
        // (subscription legata al lifetime della view), nessun
        // `AnyCancellable` manuale necessario.
        .onReceive(audioEngine.linkStartedSubject) { _ in
            guard session.playbackState != .playing else { return }
            // Cambio-canzone cross-device (buco copertura Opzione C/CD-6):
            // in .standby il Follower ha currentSongIdx già avanzato →
            // startCurrentSong preserva la canzone corrente; startSetlist
            // la resetterebbe a songIdx 0 (Song A). Vedi BUGS_QBEATS.md.
            if case .standby = session.playbackState {
                runner.startCurrentSong(audioEngine: audioEngine, session: session)
            } else {
                runner.startSetlist(audioEngine: audioEngine, session: session)
            }
        }
    }

    private func accentPatternToStrings(_ pattern: [UInt8]) -> [String] {
        pattern.map { value in
            switch value {
            case 2:  return "accent"
            case 1:  return "beat"
            default: return "subdiv"
            }
        }
    }

    private func timeSigString(for beats: UInt32) -> String {
        let denom: UInt32 = (beats == 6 || beats == 12) ? 8 : 4
        return "\(beats)/\(denom)"
    }


}

private struct HandleStripView: View {
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.20))
                .frame(width: 32, height: 3)
            Spacer()
        }
    }
}
