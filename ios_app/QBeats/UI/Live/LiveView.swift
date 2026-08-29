import SwiftUI
import os

struct LiveView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var runner: SetlistRunner
    /// Nodo A — seam di RITORNO fornito dal presenter (AppRootView →
    /// QLiveRootView, gate .metronome — back INTERNO, non uscita-stanza). Ai 2 leaf:
    /// LiveHeaderView (back) e WaitingForDirectorView (CANCEL).
    let onExit: () -> Void
    /// ⟦PORTA-RIENTRO⟧ ② — seam di FINE SHOW, distinto da `onExit`.
    ///
    /// ⚠️ PERCHÉ NON BASTAVA `onExit`: fino a oggi END SHOW lo riusava — il
    /// commento del ramo `.fineSetlist` più sotto lo chiama «TERZO inoltro dello
    /// stesso seam» — e con un canale solo il presentatore non può distinguere
    /// «me ne vado dal player» da «lo show è finito». Sono due fatti diversi e ora
    /// hanno due fili diversi: il primo lascia lo show vivo in stanza, il secondo
    /// lo chiude.
    ///
    /// ⛔ QUESTA VISTA NON SVUOTA NULLA e non deve: non possiede lo slot, non sa
    ///    che esiste, e lo spegnimento non va appeso al gesto. Qui si SEGNALA il
    ///    fatto; chi lo raccoglie è la stanza (`QLiveRootView.endShowAndLeave()`),
    ///    che è anche l'unica a poterlo fare.
    let onEndShow: () -> Void
    // ⚠️ A242 — era `@StateObject private var session = LiveSession()`: la
    //    sessione nasceva e MORIVA con questa vista, e con lei i sedici campi
    //    (censimento A229). Ora la possiede la STANZA (`QLiveSession.liveSession`,
    //    cartello A242 lì) e questa vista la OSSERVA soltanto. ⛔ Nessun
    //    default: ogni sito di montaggio dichiara quale sessione passa.
    @ObservedObject var session: LiveSession
    // L1.b — Tick di riferimento per il bar counter relativo alla sezione corrente.
    // beatTickCounter di AudioEngine cresce monotono dalla partenza; per resettare
    // il display "Battuta X di Y" ad ogni cambio sezione manteniamo qui in Layer 3
    // il primo tick della sezione corrente, e calcoliamo `currentBar` come tick relativo.
    @State private var sectionStartTick: Int = 1
    @State private var pendingSectionStart: Bool = false
    // ⟦DISPLAY-FIRMA-A⟧ A5+C1 (28-29/08) — L'ANCORA HA UN CICLO DI VITA, non solo
    // un valore. `sectionStartTick` da solo non distingue «ancora conquistata» da
    // «valore di init mai ancorato»: al RIENTRO su uno show che suona, il tick
    // handler calcolava comunque col valore di init (1) — o peggio, con una
    // FALSA ancora (vedi `lastSeenSectionIdx` sotto) — e il contatore ripartiva
    // da capo nella sezione. È il disallineamento visto sul device il 29/08.
    // ⇒ Finché l'ancora non è CONQUISTATA (avvio fresco tickN==1, o primo tick
    //   dopo un VERO cambio di sezione), contatore e LED restano SPENTI:
    //   0 = trattini/nessun LED, la semantica che `beatActive` dichiara già
    //   («0 = nessuno», LiveSession.swift:27). Verdetto CD firmato 28/08:
    //   «trattini finché la sezione non cambia, poi i numeri veri».
    // ⛔ Il motore NON pubblica una posizione dentro la sezione (misurato:
    //   `beatTickSubject` porta un contatore monotono dalla partenza,
    //   `currentBeat` è timeline assoluta Link/MIDI) ⇒ NON esiste una fonte da
    //   cui «leggere» la battuta al rientro. Spento non è prudenza: è l'unica
    //   resa onesta.
    @State private var barAnchorValid: Bool = false
    // ⟦DISPLAY-FIRMA-A⟧ — FILTRO DELLA FALSA ANCORA. `runner.$currentSectionIdx`
    // emette il valore corrente ALLA SOTTOSCRIZIONE (fatto sorgentato: vedi ⓘ
    // Apple-doc più sotto, :~326-331): al montaggio quell'emissione armava
    // `pendingSectionStart` e il PRIMO tick del rientro diventava l'ancora —
    // falsa: currentBar=1 col motore a metà sezione. Qui si ricorda l'ultimo
    // indice VISTO e si arma solo su un CAMBIO reale.
    @State private var lastSeenSectionIdx: Int? = nil
    // ⟦DISPLAY-FIRMA-A⟧ A7+C3 — FILTRO DELL'EMISSIONE INIZIALE dei mirror motore.
    // Stessa radice: al subscribe i @Published del motore emettono il valore
    // CORRENTE, che al rientro è stantio rispetto alla posizione (il runner può
    // essere avanzato mentre la vista era smontata) e sovrascriveva ciò che
    // `primeDisplay` aveva appena ricalcolato dalla sezione — il 140 e il 3/4
    // del video del 28/08. Si scarta la SOLA emissione di sottoscrizione; ogni
    // cambio successivo passa identico a prima.
    // ⛔ NON si è usata la guardia `audioEngine.isPlaying` (pattern TD#38),
    //   e la ragione è misurata: `setBPM` pubblica `currentBPM` A MOTORE FERMO
    //   nel cambio canzone (prepare gira PRIMA di start) — quella guardia
    //   avrebbe mangiato il BPM della canzone nuova.
    @State private var bpmMirrorPrimed: Bool = false
    @State private var bpbMirrorPrimed: Bool = false
    @State private var repsMirrorPrimed: Bool = false
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
                    // ⟦S5x⟧ (A64) — BACK TO SHOWS, ratifica LIBRO:154 «torna alla
                    // libreria SHOWS». ORDINE OBBLIGATO, ratificato nel mandato:
                    //  (a) sessione a .stopped — il rilascio del sottoalbero al flip
                    //      di `page` è NON SORGENTATO (QLiveRootView.swift:64-67): se
                    //      LiveView NON si smontasse, senza questo reset il prossimo
                    //      ingresso al player si aprirebbe direttamente su END SHOW.
                    //      Scrittura INERTE a motore già fermo (SetlistRunner:378):
                    //      `LiveSession.playbackState` è @Published nudo, zero didSet
                    //      (LiveSession.swift:35); la guardia `case .standby, .fineSetlist:
                    //      return` più sotto NON è su questo percorso — ascolta il MOTORE
                    //      (audioEngine.$playbackState), non la sessione.
                    //  (b) onExit — il seam del presentatore (QLiveRootView.swift:157,
                    //      `navigate(to: .shows)`): stesso identico canale già usato
                    //      da LiveHeaderView (back) e WaitingForDirectorView (CANCEL).
                    //      TERZO inoltro dello stesso seam, nessun percorso nuovo.
                    // ⚠️ CARTELLO ⟦PORTA-RIENTRO⟧ (28/08/2026) — L'ORDINE OBBLIGATO
                    //    DESCRITTO QUI SOPRA NON VIVE PIÙ IN QUESTA CLOSURE, e le due
                    //    righe (a) e (b) non sono state tolte: sono state SPOSTATE
                    //    nella stanza, dentro `QLiveSession.endShow()` +
                    //    `QLiveRootView.endShowAndLeave()`, e lì stanno insieme e
                    //    nello stesso ordine.
                    //    · (a) il reset a `.stopped` è la riga 1 di `endShow()`, con
                    //      la sua motivazione ripresa per intero — ed è diventata più
                    //      necessaria, non meno: da A242 la sessione sopravvive di
                    //      sicuro alla schermata, quindi il caso che (a) temeva non è
                    //      più solo possibile, è certo.
                    //    · (b) la navigazione è la riga 2, sullo stesso seam del
                    //      presentatore.
                    // ⇒ PERCHÉ SPOSTATE: qui erano dentro il GESTO. Lo spegnimento
                    //   dello slot deve stare dove la sessione si chiude, o il
                    //   secondo innesco di END SHOW — quello del dettaglio, disegnato
                    //   da CD il 27/08 e OGGI NON COSTRUITO — nascerebbe già
                    //   dimenticandolo.
                    // ⛔ RESTART SETLIST di `FineSetlistView` NON è toccato da questo
                    //    giro: resta inerte com'era. Una decisione ratificata il
                    //    07/08 (`LIBRO_MASTRO_QBEATS.md:353`) dispone di TOGLIERLO da
                    //    END SHOW, e il mandato ha sciolto che non è di questo giro.
                    //    Lo si incontra per forza lavorando qui: è lasciato intatto
                    //    di proposito, non per svista.
                    FineSetlistView(scaleFactor: scaleFactor, onBackToShows: onEndShow)
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
                //      (seam Nodo A, fornito dal presenter) → AppRootView
                //      commuta `screen = .home` → ritorno a Home
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
                        // ⚠️ A240 — era `startSetlist`: azzerava il punto anche
                        //    quando l'attesa seguiva uno STOP a metà show (A239,
                        //    sito 3). RULING del referee: «si riparte da dov'eri»
                        //    non cambia a seconda di chi preme. Il blocco CD-6 qui
                        //    sopra descrive ancora le partenze vecchie — testo
                        //    invariato, vale questa marcatura.
                        runner.startCurrentSection(audioEngine: audioEngine, session: session)
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
            // ⚠️ CORRETTO DA ⟦S5b⟧ — le due righe qui sotto NON valgono più come
            // scritte. Da ⟦S5b⟧ `primeDisplay` non lascia più la videata in
            // `.stopped`: se e SOLO se lo stato è `.stopped`, la porta in
            // `.standby(nextSongName:)` sulla PRIMA canzone — arma + standby
            // d'ingresso, `BOX5_QBEATS.md:331` (QL-SHOWS-07). Il click non parte:
            // parte al tocco sull'overlay, :134-137. Resta vero il resto: la
            // videata mostra i dati della setlist caricata già prima del Play.
            // (Storia, da leggere come tale:)
            // Coerente con TD #28 (17/05/2026): stato iniziale `.stopped`, no
            // overlay standby, videata deve mostrare dati setlist caricata.
            // ⚠️ A242 — AZZERAMENTO ESPLICITO, l'unico del giro: il mixer è
            //    mobilio della schermata, non memoria dello show. Fino a oggi si
            //    chiudeva da solo perché la sessione MORIVA con la vista; da
            //    A242 la sessione è della stanza e sopravvive all'uscita — senza
            //    questa riga si rientrerebbe col mixer aperto senza capire come.
            //    Ogni ALTRO campo della sessione sopravvive DI PROPOSITO: vedi
            //    il cartello A242 in `QLiveSession.swift`.
            session.showMixer = false
            // ⟦DISPLAY-FIRMA-A⟧ A5+C1+C2 — SPENTO AL MONTAGGIO. Da A242 la
            // sessione sopravvive alla schermata, quindi `currentBar` e
            // `beatActive` arrivano qui con i valori dell'ULTIMA volta — e a
            // motore muto nessun tick li correggerà mai: è l'accento verde
            // acceso a click spento del video del 28/08 (C2, il verdetto più
            // validato dal campo). Si azzerano SEMPRE al montaggio: se il motore
            // suona, i numeri veri tornano alla conquista dell'ancora (primo
            // confine di sezione); se è muto, spento È la resa giusta.
            // 0 = trattini (BarCounterView) / nessun LED (MetSlotStripView).
            session.currentBar = 0
            session.beatActive = 0
            runner.primeDisplay(session: session)
            // Sync displayBpb/displayAccentPattern dalla prima sezione del runner.
            // Override il sync da audioEngine sopra: la setlist caricata è "verità"
            // di display, lo stato pendente in audioEngine può essere stale
            // (es. utente ha aperto Q-Stage dopo aver caricato la setlist).
            if let section = runner.currentSection {
                displayBpb = section.beatsPerBar
                displayAccentPattern = section.accentPattern
                // ⟦DISPLAY-FIRMA-A⟧ C3 — il time-sig dell'header è la FACCIA di
                // displayBpb e fin qui non aveva un ricalcolo al montaggio: lo
                // scrivevano solo il mirror motore e il tick handler, quindi al
                // rientro restava quello sopravvissuto della sessione — il 3/4
                // del video del 28/08. Stessa fonte delle due righe sopra: la
                // sezione della posizione, non il motore.
                session.currentTimeSig = timeSigString(for: section.beatsPerBar)
            }
            // ⟦SYNC-ISTANTANEA⟧ A247 (29/08) — L'ANCORA SI CONQUISTA SUBITO, se
            // il motore sa dov'è. Collaudo Mauro 29/08 su ⟦DISPLAY-FIRMA-A⟧:
            // trattini corretti ma «resta tutto cieco fino al cambio — la
            // sincronizzazione deve avvenire ALL'ISTANTE». La fonte c'è:
            // l'asse CONTATORE del motore (`snapshotSectionPosition`, cartello
            // A247 in AudioEngine). Da esso l'ancora è una sottrazione:
            //   sectionStartTick = tick − sectionBeat + 1
            // — la stessa identità che il ramo tickN==1 produce al join del
            // Follower (tick=1, sectionBeat=offset+1 ⇒ 1−offset), verificata
            // per coincidenza algebrica, non per analogia.
            //
            // TRE GUARDIE, ognuna con la sua ragione misurata:
            //  · !barAnchorValid — un tick può aver già ancorato (o ancorerà
            //    meglio: al confine `pendingSectionStart` sovrascrive comunque
            //    questa ancora con quella vera). Mai retrocedere un'ancora.
            //  · sectionTotal > 0 — ⛔ A248: il non-lo-so VERO è il TOTALE a
            //    zero, non il contatore a zero. Sezione in LOOP (rischio
            //    accettato da Mauro 29/08: i loop restano ciechi ma ONESTI)
            //    o nessuna sezione caricata ⇒ niente ancora: restano i
            //    trattini di 6deea52, che non si butta — si estende.
            //    Il contatore a zero, da solo, NON è non-lo-so: vedi sotto.
            //  · audioEngine.isPlaying — misurato: l'INTERRUZIONE AUDIO
            //    (`.began`, AudioEngine ~:2680-2708) ferma il motore SENZA
            //    azzerare il contatore («clock running»). Senza questa guardia,
            //    rientrare durante un'interruzione aggancerebbe numeri
            //    congelati su un motore muto — il valore vecchio che C1 vieta.
            //
            // ⚠️ A248 — IL CONFINE È UN BEAT LUNGO, e zero ci abita: lo swap
            //    SEAMLESS azzera il contatore DENTRO il beat che chiude la
            //    sezione vecchia (totale nuovo già caricato) ⇒ per un beat
            //    intero (0,6 s a 100 BPM, 3 s a 20) il contatore vale 0 con
            //    l'audio che suona. Chi montava lì restava CIECO FINO AL
            //    CONFINE SUCCESSIVO: la guardia A247 `sectionBeat > 0`
            //    scartava, e il filtro della falsa ancora aveva già consumato
            //    l'emissione di sottoscrizione — nessun arming di riserva.
            //    (Trovata da CD per ragionamento, misurata dal referee.)
            //    ⇒ Con totale > 0 e contatore a 0 la posizione SI CONOSCE:
            //    è l'inizio. L'ancora si conquista con la STESSA formula
            //    (tick − 0 + 1 = il prossimo tick è il beat 1); i numeri NON
            //    si scrivono qui — il beat in corso è l'ultimo della sezione
            //    VECCHIA, e il suo dato è perso: scrivere «Bar 1» adesso
            //    anticiperebbe di un beat una sezione non ancora suonata.
            //    Trattini per ≤1 beat, poi il primo tick scrive Bar 1 da sé.
            //
            // Nel caso normale (contatore > 0) i numeri si scrivono QUI, non
            // al prossimo tick: a 20 BPM il prossimo tick dista 3 secondi, e
            // il mandato chiede l'istante.
            // ⚠️ Il LED si riaccende per CONSEGUENZA della stessa ancora —
            //    stessa aritmetica del tick handler, nessun disegno nuovo
            //    (ratificato da CD 29/08: «contatore e LED sono lo stesso
            //    dato a due granularità»). L'allineamento accento↔contatore
            //    resta quello di oggi (materia Bug 2.b): non lo promette.
            audioEngine.snapshotSectionPosition { sectionBeat, sectionTotal, tick in
                guard !barAnchorValid, sectionTotal > 0, audioEngine.isPlaying else { return }
                sectionStartTick = tick - sectionBeat + 1
                barAnchorValid = true
                // A248 — inizio-sezione (contatore 0): ancora sì, numeri al
                // primo tick della sezione nuova, ≤1 beat da adesso.
                guard sectionBeat > 0 else { return }
                let bpb = max(1, Int(displayBpb))
                session.beatActive = ((sectionBeat - 1) % bpb) + 1
                session.currentBar = ((sectionBeat - 1) / bpb) + 1
            }
        }
        // MARK: - AudioEngine → LiveSession sync
        .onReceive(audioEngine.$playbackState) { state in
            switch state {
            case .stopped:
                // ⛔ QUESTA GUARDIA HA DUE MOTIVI, NON UNO. Chi ne togliesse uno solo
                //    romperebbe l'altro in silenzio: non è codice difensivo ridondante.
                //
                //  (1) L1.b, motivo storico: il runner gestisce .standby e .fineSetlist
                //      impostando session.playbackState PRIMA di chiamare
                //      audioEngine.stop(). Lo stop() dispatcha .stopped su main qualche
                //      ms dopo — NON sovrascrivere stati già impostati dal runner.
                //
                //  (2) ⟦S5b⟧ — È CIÒ CHE TIENE IN PIEDI L'ARMAMENTO D'INGRESSO. Da ⟦S5b⟧
                //      `primeDisplay` (:231) lascia la sessione in `.standby` quando si
                //      entra in uno show. Questa guardia impedisce a QUALSIASI `.stopped`
                //      proveniente dal motore — in qualunque momento arrivi, e qualunque
                //      ne sia la causa — di scrivere sopra quello standby. Senza il
                //      `case .standby` qui sotto l'overlay verrebbe cancellato e lo Start
                //      sembrerebbe non fare nulla.
                //      ⛔ La protezione NON dipende da QUANDO il motore parli: vale per
                //      ogni `.stopped`, il primo compreso. Non c'è alcun assunto sul
                //      momento della prima consegna — se anche non ne arrivasse nessuna
                //      al montaggio, la guardia resterebbe necessaria per tutte le altre.
                //      ⓘ Fatto SORGENTATO, che spiega perché il rischio si presenta già
                //      al montaggio e non solo a show avviato: la documentazione Apple di
                //      `Published` mostra un sottoscrittore che riceve il valore corrente
                //      all'atto della sottoscrizione — nel suo esempio la `sink` stampa
                //      «Temperature now: 20.0» prima di qualunque cambio della proprietà.
                //      https://developer.apple.com/documentation/combine/published
                //      ⚠️ Una pulizia futura che togliesse `.standby` da questa lista
                //      romperebbe ⟦S5b⟧ senza toccarne una riga.
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
            // ⟦DISPLAY-FIRMA-A⟧ A7 — RICALCOLA dalla sezione: il valore del
            // montaggio lo scrive `primeDisplay` (SetlistRunner.swift, sezione
            // della posizione); l'emissione di sottoscrizione del motore — che
            // può essere stantia rispetto alla posizione — si scarta. Ogni
            // cambio successivo (setBPM al cambio canzone, tempo-callback Link,
            // swap al downbeat) passa identico a prima.
            if !bpmMirrorPrimed { bpmMirrorPrimed = true; return }
            session.currentBPM = bpm
        }
        .onReceive(audioEngine.$beatsPerBar) { beats in
            // ⟦DISPLAY-FIRMA-A⟧ C3 — stessa forma di A7 qui sopra: il montaggio
            // lo copre l'onAppear (sezione della posizione), l'emissione di
            // sottoscrizione si scarta. I rami sotto restano INTATTI per ogni
            // cambio vero, playing o no.
            if !bpbMirrorPrimed { bpbMirrorPrimed = true; return }
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
            // ⚠️ ⟦DISPLAY-FIRMA-A⟧ — ESTENSIONE OLTRE LA LETTERA DEL MANDATO,
            // dichiarata: il mandato nomina A5+C1 come «il contatore di battuta»,
            // e questo publisher ne governa la metà «of Y». Senza il filtro,
            // l'emissione di sottoscrizione (motore, stantio al rientro)
            // sovrascriveva il totale che `primeDisplay` aveva appena ricalcolato
            // dalla sezione: «Bar — of ⟨vecchio⟩» non è invisibile. Stessa forma
            // dei due filtri sopra; prima candidata a bocciatura se il referee
            // la legge fuori perimetro.
            if !repsMirrorPrimed { repsMirrorPrimed = true; return }
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
                barAnchorValid = true
            } else if pendingSectionStart {
                // L1.b — avanzamento sezione mid-canzone (seamless): il 1° tick
                // della nuova sezione diventa l'ancora → currentBar=1.
                sectionStartTick = tickN
                pendingSectionStart = false
                barAnchorValid = true
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
            // ⟦DISPLAY-FIRMA-A⟧ A5+C1+C2 — SENZA ANCORA NON SI CONTA. Al rientro
            // su uno show che suona i tick arrivano ma nessuno sa a quale battuta
            // della sezione appartengano (il motore non pubblica quella
            // posizione): calcolare con un'ancora non conquistata è come
            // inventarla. Spento — trattini e LED muto — finché il primo confine
            // di sezione non consegna l'ancora vera; da lì i numeri veri, da
            // soli. ⛔ I mirror bufferizzati qui sopra si applicano COMUNQUE:
            // sono valori di sezione, non derivati dell'ancora.
            guard barAnchorValid else {
                session.beatActive = 0
                session.currentBar = 0
                return
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
        // ⚠️ ⟦DISPLAY-FIRMA-A⟧ (29/08) — SI ARMA SOLO SU UN CAMBIO REALE. Prima
        //    il marker si armava anche sull'emissione di SOTTOSCRIZIONE (un
        //    @Published emette il valore corrente al subscribe — ⓘ sorgentato
        //    più sopra): al rientro su uno show che suona, il primo tick
        //    diventava così una FALSA ancora e il contatore ripartiva da capo
        //    nella sezione — il disallineamento visto sul device il 29/08.
        //    L'emissione iniziale ora REGISTRA l'indice senza armare; ogni
        //    transizione vera arma identica a prima.
        .onReceive(runner.$currentSectionIdx) { idx in
            if let last = lastSeenSectionIdx, last != idx {
                pendingSectionStart = true
            }
            lastSeenSectionIdx = idx
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
        // Link `set_start_stop_callback` (chiamata a `link_engine_set_start_stop_callback` in AudioEngine.swift)
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
                // ⚠️ A240 — era `startSetlist` (il commento qui sopra e il blocco
                //    Q-D3 più su lo descrivono ancora così — testo invariato): il
                //    Follower fermo a metà show perdeva il punto SENZA toccare
                //    nulla quando il Direttore premeva Play (A239, sito 5). RULING
                //    del referee: conserva canzone e sezione; fallback 0/0 dentro
                //    `startCurrentSection` se l'indice non si risolve.
                runner.startCurrentSection(audioEngine: audioEngine, session: session)
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
