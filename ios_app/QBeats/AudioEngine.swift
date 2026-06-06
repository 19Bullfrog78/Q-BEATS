import AVFoundation
import Combine
import os
import UIKit

// Regole thread — inviolabili:
// 1. isRunning, clickPlayhead, accentPlayhead, bufferCount, beatTotal,
//    clickSamples, accentedClickSamples, offsets, accents
//    sono accedute ESCLUSIVAMENTE su audioQueue.
// 2. clickStatus, isPlaying, beatsPerBar sono @Published:
//    ogni write avviene su DispatchQueue.main.async.
//    beatsPerBar è scritto dalla UI (main thread) tramite Picker;
//    setBeatsPerBar() dispatcha solo su audioQueue, non riscrive @Published.
// 3. audioMode è @Published e scritto SOLO su DispatchQueue.main.async.
//    applyChannelRouting(for:) riceve il mode come parametro, non legge self.audioMode.

// MARK: - AudioMode (Fase 1.5a)
enum AudioMode: Equatable {
    case base
    case pro
}

// MARK: - PlaybackState (UX-3)
enum PlaybackState {
    case stopped
    case countIn
    case playing
    case pausedAwaitingChoice(sectionName: String, songName: String)
}


class AudioEngine: ObservableObject {
    static let shared = AudioEngine()

    @Published var clickStatus : String  = "non caricato"
    @Published var currentBPM: Double = 120.0
    @Published var linkEnabled: Bool = false
    @Published var linkIsConnected: Bool = false
    @Published var linkPeers: Int = 0
    @Published var isWaitingForLinkDownbeat: Bool = false
    // CD-Q1=B mirror UI (libro mastro v14, 28/05/2026) — Mirror @Published di
    // `_linkMode` audio-queue per consumo da UI (LiveView calcola
    // `linkRoleBadge` per LiveHeaderView). Sync nel blocco `main.async` di
    // `applySettings(_)`. Fonte di verità autoritativa resta
    // `appSettings.linkMode` (settato da SettingsView). Q-D1 ratificato:
    // AppSettings è struct, non ObservableObject → mirror obbligatorio.
    //
    // NOMENCLATURA: `currentLinkMode` (non `linkMode`) per evitare collisione
    // con la property privata `_linkMode: LinkMode` (audio-queue copy, riga
    // ~264): `@Published var linkMode` sintetizzerebbe un backing
    // `_linkMode: Published<LinkMode>` che collide letteralmente col nome
    // esistente → CI failure run 26581236612 28/05/2026 sera. Naming allineato
    // con `currentBPM`, `currentAccentPattern`, `currentSectionRepetitions`
    // già esistenti nel file (linea "current* = mirror UI di stato audio").
    @Published var currentLinkMode: LinkMode = .collaborativa
    @Published var isPlaying   : Bool    = false
    @Published var beatsPerBar : UInt32  = 4 {
        didSet {
            // Strada A — Guard suppress PRIMA di guard oldValue.
            // Il ramo SEAMLESS setta _suppressBeatsPerBarDidSet=true su main
            // prima di assegnare self.beatsPerBar, per evitare che il didSet
            // chiami metronome_setBeatsPerBar (immediato, resetta
            // _currentBeatInBar nel DSP — distruggerebbe il sample-accurate
            // exchange al downbeat). L'ordine è critico: con il guard oldValue
            // prima, due sezioni con stesso BPB (es. 4/4 → 4/4) lascerebbero
            // il flag bruciato per i didSet successivi.
            if _suppressBeatsPerBarDidSet {
                os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → SKIP (suppress flag attivo)",
                       log: .default, type: .default, Int(beatsPerBar), Int(oldValue))
                _suppressBeatsPerBarDidSet = false
                return
            }
            guard beatsPerBar != oldValue else {
                os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → SKIP (valore uguale, nessun push al motore)",
                       log: .default, type: .default, Int(beatsPerBar), Int(oldValue))
                return
            }
            guard let h = metronomeHandle else { return }
            os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → PUSH al motore (DSP + Link quantum)",
                   log: .default, type: .default, Int(beatsPerBar), Int(oldValue))
            let bpb = beatsPerBar
            let pattern = defaultAccentPattern(for: bpb)
            let mappedPattern: [UInt8] = pattern.map { $0 > 0 ? 2 : 1 }
            DispatchQueue.main.async { self.currentAccentPattern = mappedPattern }
            audioQueue.async { [h, pattern, bpb] in
                self._beatsPerBarQ = bpb
                metronome_setBeatsPerBar(h, bpb)
                if let lh = self.linkEngineHandle {
                    link_engine_set_quantum(lh, Double(bpb))
                }
                pattern.withUnsafeBufferPointer { ptr in
                    metronome_setAccentPattern(h, ptr.baseAddress, UInt32(pattern.count))
                }
            }
        }
    }
    @Published var currentAccentPattern: [UInt8] = [2, 1, 1, 1]
    @Published var currentSectionRepetitions: Int = 0
    @Published var channelVolumes: [Float] = [1.0, 1.0, 0.0, 0.0]
    
    // --- Variabili per DebugView (Fase 1.5a) ---
    @Published var audioMode: AudioMode = .base
    @Published var sampleRateInfo: Double = 48000.0
    @Published var currentBeat: Double = 0.0
    @Published var debugLogs: [String] = []
    // -------------------------------------------------------

    // Fase VOL — settings globali
    @Published var appSettings: AppSettings = AppSettings.load() {
        didSet {
            appSettings.save()
            applySettings(appSettings)
        }
    }

    // Fase 1.6 — MIDI Learn
    @Published var midiLearnStore: MIDILearnStore = MIDILearnStore.load()
    @Published var midiLearnPendingAction: MIDIAction? = nil

    // Beat tick discreto — PassthroughSubject, no coalescing
    let beatTickSubject = PassthroughSubject<Int, Never>()
    private var beatTickCounter: Int = 0

    // === Strada A — Flag suppress per didSet di beatsPerBar ===
    // Single-shot: settato dal ramo SEAMLESS prima di assegnare
    // self.beatsPerBar. Il didSet lo legge e auto-resetta.
    // Accesso esclusivamente su main thread.
    private var _suppressBeatsPerBarDidSet: Bool = false

    // === CD-6 / Bug 4 fix (28/05/2026) — Gate anti double-emit linkStartedSubject ===
    // Settato `true` nel branch `isPlaying && !engine.isPlaying` del callback
    // Link `set_start_stop_callback`, resettato `false` in
    // `DispatchQueue.main.async` di `start()` (righe ~745-750) dove
    // `self.isPlaying = true`. Tra `engine.start()` e il flip di `isPlaying`
    // ci sono ≥3 hop di dispatch (audioQueue.async + main.async annidato) —
    // questa finestra è vulnerabile a doppio callback Link (burst peer
    // reannounce) che ri-passerebbe il guard `!engine.isPlaying`.
    // Q-D4 esteso ratificato libro mastro v15. Accesso ESCLUSIVAMENTE su main.
    private var _linkStartEmitInFlight: Bool = false

    // === Task D — Section BPM broadcast su Link ===
    // Pattern identico a L1.a (closure single-shot a beat-target).
    // Quando scheduleBPMChange viene chiamato:
    //   - il C++ DSP arma _bpmChangeDirty e applicherà _pendingBPM al prossimo
    //     downbeat (sample-accurate, atomic exchange in processBuffer);
    //   - Swift memorizza qui il valore target e il tick atteso del downbeat.
    // Nel beat-tick callback di scheduleNextBuffer, quando beatTickCounter ==
    // _pendingBPMTargetTick, propaga link_engine_set_bpm + _audioBPM +
    // midi_engine_set_bpm + currentBPM UI, in sincrono col cambio DSP.
    // Reset su setBPM (path immediato), stopSync, e auto-reset post-scatto.
    // Accesso SOLO su audioQueue.
    private var _pendingBPMValue: Double? = nil
    private var _pendingBPMTargetTick: Int = 0

    // L1.a/L1.b — segnale "fine vera della performance".
    // Esposto da AudioEngine ma emesso ESCLUSIVAMENTE dal callsite di
    // loadSection(onEnd:), che ha contesto setlist e può discriminare fine
    // intermedia da fine vera (TD #16, refactor L1.b).
    //   L1.a (DebugView): callsite emette subject prima di stop() — singola
    //     sezione di test, "fine vera" coincide con "fine sezione".
    //   L1.b (Layer 3): callsite emette subject solo nel ramo `fineSetlist`
    //     della closure end-of-section. Transizioni intermedie NON emettono.
    // LiveView ascolta per il fade del LED ultimo beat (durata pari a un
    // beat al BPM corrente, poi spegnimento). Stop manuale chiama stop()
    // senza emettere il subject — LED spento netto.
    let sectionEndedSubject = PassthroughSubject<Void, Never>()

    // CD-6 / Bug 4 fix (28/05/2026) — Opzione C orchestrazione cross-device.
    // Emesso dal callback Link `set_start_stop_callback` (righe ~436-442)
    // quando `engine.isPlaying` flippa false→true a causa di un Director
    // peer che ha premuto Play. LiveView observer chiama
    // `runner.startSetlist(...)` per orchestrare la sezione corrente sul
    // Follower: prima del fix, il callback Link chiamava solo
    // `engine.start()` ignorando il runner → `_sectionTotalBeats=0` su
    // Follower → check `_sectionTotalBeats > 0` non passava → counter
    // macrobar all'infinito + nome canzone non mostrato (Problema B / Bug 4).
    // Gate anti double-emit: `_linkStartEmitInFlight` (vedi callback).
    // Gate idempotenza observer: `guard session.playbackState != .playing`
    // in LiveView (Q-D3 ratificato). NB: in modalità Direttore (linkMode ==
    // .direttore) il guard early-return riga ~432 del callback impedisce
    // di entrare nel branch — il Subject NON viene emesso quando Q-BEATS è
    // sorgente. Q-D2/Q-D3/Q-D4 ratificati libro mastro v15.
    let linkStartedSubject = PassthroughSubject<Void, Never>()

    // UX-3 — state machine playback
    @Published var playbackState: PlaybackState = .stopped

    // UX-2 — DND Reminder
    @Published var shouldShowDNDReminder: Bool = false
    private var dndReminderShownThisSession = false

    // Placeholder L3 — sostituiti dalla song/section model di Layer 3
    var currentSection: String? = nil
    var currentSong: String? = nil

    private var tapTempoEngine = TapTempoEngine()

    private func applySettings(_ s: AppSettings) {
        audioQueue.async { [weak self] in
            guard let self = self,
                  let mh = self.metronomeHandle else { return }
            self.accentVolume = s.accentVolume
            self.beatVolume   = s.beatVolume
            self.subdivVolume = s.subdivVolume
            metronome_set_accent_volume(mh, s.accentVolume)
            metronome_set_beat_volume(mh, s.beatVolume)
            metronome_set_subdiv_volume(mh, s.subdivVolume)
            self._clickMuted = s.clickMuted
            self._linkMode = s.linkMode
            // Layer 1 non riceve mai il mute — beat events continuano a scattare.
            self.ch1Volume = s.ch1Volume
            self.ch2Volume = s.ch2Volume
            self.ch3Volume = s.ch3Volume
            self.ch4Volume = s.ch4Volume
            self.ch1MixerNode.outputVolume = s.ch1Volume
            self.ch2MixerNode.outputVolume = s.ch2Volume
            self.ch3MixerNode.outputVolume = s.ch3Volume
            self.ch4MixerNode.outputVolume = s.ch4Volume
            let vols = [s.ch1Volume, s.ch2Volume, s.ch3Volume, s.ch4Volume]
            let linkModeMirror = s.linkMode
            DispatchQueue.main.async {
                self.channelVolumes = vols
                // CD-Q1=B mirror UI — sync @Published `currentLinkMode` dal
                // valore appena applicato a `_linkMode` audio-queue. Cattura
                // locale per evitare read di `s` su main (s.linkMode è copia
                // di valore struct, ma `linkModeMirror` rende l'intent esplicito).
                self.currentLinkMode = linkModeMirror
            }
            os_log("applySettings accent=%.2f beat=%.2f subdiv=%.2f muted=%{public}@ ch=[%.2f,%.2f,%.2f,%.2f]",
                   log: .default, type: .default,
                   s.accentVolume, s.beatVolume, s.subdivVolume, "\(s.clickMuted)",
                   s.ch1Volume, s.ch2Volume, s.ch3Volume, s.ch4Volume)
        }
    }

    private var metronomeHandle      : MetronomeHandle?
    private var midiEngineHandle     : MIDIEngineHandle? = nil
    // === MODIFICATO 6A ===
    private var linkEngineHandle     : LinkEngineHandle? = nil
    private(set) var linkSettingsPresenter: LinkSettingsPresenter?

    // === Task D refactor #18 — Atomic pending + sink node audio-thread ===
    // linkPending: ponte lockfree fra audioQueue (arming) e render thread
    // (sink block). Allocato in init(), distrutto in deinit() DOPO detach
    // del sink node (Correzione 1 referee — evita use-after-free).
    // Vedi QBeatsAtomics.h per dettagli RT-safety.
    private let linkPending: OpaquePointer
    // === Task D refactor #18c ===
    // AVAudioSinkNode (refactor #18) sostituito da installTap su
    // engine.mainMixerNode (refactor #18c) perche' il sink in
    // multi-destination da playerNode non veniva mai invocato dal
    // render thread (diagnosi #18b: zero log A/B/C/D). Vedi
    // installLinkTap() per setup del tap RT-equivalente.

    // === AGGIUNTO 6C — timebase cachato all'avvio ===
    private let machTimebase: mach_timebase_info_data_t = {
        var tbi = mach_timebase_info_data_t()
        mach_timebase_info(&tbi)
        return tbi
    }()

    private let engine               = AVAudioEngine()
    private let playerNode           = AVAudioPlayerNode()
    // Fase 1.5a: sampleRate dinamico — aggiornato da AVAudioSession dopo setActive(true)
    private var sampleRate           : Double = 48000.0
    private let bufferSize           : AVAudioFrameCount = 512
    private let maxBeats             : Int = 16

    // --- Stato audio: accesso SOLO su audioQueue ---
    private var clickSamples              : [Float] = []
    private var accentedClickSamples      : [Float] = []
    private var subdivisionClickSamples   : [Float] = []
    private var isRunning            = false
    private var bufferCount          : Int = 0
    private var beatTotal            : Int = 0
    private var clickPlayhead        : Int = -1
    private var accentPlayhead       : Int = -1
    private var subdivPlayhead       : Int = -1
    private var _clickMuted: Bool = false   // accesso SOLO su audioQueue
    private var _linkMode: LinkMode = .collaborativa   // accesso SOLO su audioQueue
    private var _audioBPM: Double = 120.0   // accesso SOLO su audioQueue
    // DEFAULT DEVE COINCIDERE con @Published var beatsPerBar (didSet non scatta in init)
    private var _beatsPerBarQ: UInt32 = 4   // accesso SOLO su audioQueue
    // === L1.a — Sezione corrente (mirror su audioQueue) ===
    // Sincronizzati via loadSection(beatsPerBar:repetitions:onEnd:).
    // _sectionTotalBeats = 0 → nessun limite (loop infinito o sezione non caricata).
    // _onSectionEnd è single-shot: consumata (settata nil) sull'ultimo beat per evitare double-fire.
    private var _sectionTotalBeats: Int = 0
    private var _sectionBeatCounter: Int = 0
    private var _onSectionEnd: (() -> Void)? = nil
    // === L1.a — Drain mode dopo fine sezione ===
    // Quando il counter raggiunge il totale, _sectionEndPending viene settato.
    // I buffer successivi NON chiamano metronome_processBuffer (no beat fantasma)
    // ma continuano a drenare clickPlayhead/accentPlayhead/subdivPlayhead esistenti.
    // Quando tutti i playhead sono < 0 → dispatch _pendingEndClosure → stop reale.
    // Sample-accurate: il dispatch arriva quando l'ultimo click è stato riprodotto
    // integralmente, non con timer arbitrari su main thread.
    private var _sectionEndPending: Bool = false
    private var _pendingEndClosure: (() -> Void)? = nil

    // === Strada A — Pre-load nuova sezione (audioQueue-private) ===
    // Riempiti da preloadNextSection() chiamato dal SetlistRunner all'inizio
    // della sezione corrente con i parametri della sezione N+1. Consumati e
    // azzerati nel ramo SEAMLESS del beat callback quando
    // _sectionBeatCounter >= _sectionTotalBeats. Tutti nil → ramo DRAIN.
    private var _pendingNextBPM: Double? = nil
    private var _pendingNextBPB: UInt32? = nil
    private var _pendingNextAccentPattern: [UInt8]? = nil
    private var _pendingNextSectionTotalBeats: Int? = nil
    private var _pendingNextOnSectionEnd: (() -> Void)? = nil
    private var _pendingNextRepetitions: Int? = nil

    private var offsets              : [UInt32]
    private var accents              : [UInt8]
    private var isBeats              : [UInt8]

    // Fase VOL — volumi su audioQueue
    private var accentVolume: Double = 1.0
    private var beatVolume:   Double = 0.8
    private var subdivVolume: Double = 0.4

    // === AGGIUNTO 6C — Link phase sync (accesso solo su audioQueue) ===
    private var outputLatencyTicks : UInt64 = 0
    private var bufferDurationTicks: UInt64 = 0

#if QB_DIAG_SPY
    // === Bug 2.b — SPIA passiva L3 (asse CONTATORE + griglia). OFF salvo QB_DIAG_SPY. ===
    // Marker in SOLA LETTURA: gridBeat (engine, sync a Link) al 1° beat di sezione.
    // Mai variabile di produzione, mai scritto nel path audio di emissione.
    // La round()/modulo della fase derivata-griglia si calcola al FLUSH (offline).
    private var _spySectionStartMarker: Double = 0.0
    private var _spySectionInstanceIdx: Int = 0
    private var _spyMarkerPending: Bool = true   // cattura il marker al 1° beat di sezione
#endif

    // QA-1 drift analysis — eseguito su audioQueue
    private var qa1BeatCounter: UInt64 = 0
    private var qa1StartTime: UInt64 = 0  // mach_absolute_time al beat 0

    // === Blocco 7 — Silent Ticking (accesso SOLO su audioQueue) ===
    // Il clock C++ (metronome, MIDI, Link) non si ferma mai durante le interruzioni.
    // Solo l'audio layer (AVAudioEngine + playerNode) viene sospeso.
    private var isAudioInterrupted:  Bool = false
    private var clockLinkWasEnabled: Bool = false
    private var lastInterruptionResumeTime: UInt64 = 0
    private var pendingResume: Bool = false
    private var pendingResumeBeat: Double? = nil
    private var currentResumeToken: Int = 0
    // Beat assoluto di clock al momento del Play originale — usato per snap relativo.
    private var _startAbsoluteBeat: Double = 0.0
    // Bug 2.b ramo X — offset d'ingresso del Follower in BEAT (multiplo di bpb
    // su downbeat); 0 per Director/standalone/resume. Seminato nel work item
    // SHARED prima del pre-roll; letto da LiveView al primo tick per allineare
    // sectionStartTick (visivo). Accesso scrittura su audioQueue, lettura su main.
    private(set) var startBeatOffset: Int = 0
    // Opzione B — Link downbeat wait (accesso SOLO su audioQueue)
    private var pendingLinkStart: DispatchWorkItem? = nil
    // Build 303 — salta sync Link nei primi 3 buffer dopo fresh play
    private var linkSyncSkipBuffers: Int = 0
    // L1.b sync investigation — conta 3 buffer dopo cambio BPM per log DIRECTOR-ASSERT
    private var _linkSyncLogBuffers: Int = 0

    // --- Backtrack state: accesso SOLO su audioQueue ---
    private let backtrackPlayerNode = AVAudioPlayerNode()
    private var backtrackBuffer: AVAudioPCMBuffer? = nil
    private var backtrackArmed: Bool = false

    // --- Mixer 4 canali ---
    private let ch1MixerNode = AVAudioMixerNode()   // Click / Metronomo
    private let ch2MixerNode = AVAudioMixerNode()   // Backtrack musicale
    private let ch3MixerNode = AVAudioMixerNode()   // Guide vocals (disabilitato senza HW Pro)
    private let ch4MixerNode = AVAudioMixerNode()   // FX ambientali (disabilitato senza HW Pro)

    private let ch3PlayerNode = AVAudioPlayerNode()
    private let ch4PlayerNode = AVAudioPlayerNode()

    // Volumi indipendenti per canale — accesso SOLO su audioQueue
    private var ch1Volume: Float = 1.0
    private var ch2Volume: Float = 1.0
    private var ch3Volume: Float = 0.0   // disabilitato di default
    private var ch4Volume: Float = 0.0   // disabilitato di default

    // ------------------------------------------------

    private let audioQueue = DispatchQueue(label: "com.bullfrog.qbeats.audio", qos: .userInteractive)

    init() {
        offsets  = [UInt32](repeating: 0, count: maxBeats)
        accents  = [UInt8](repeating: 0, count: maxBeats)
        isBeats  = [UInt8](repeating: 0, count: maxBeats)

        // === Task D refactor #18 — alloca atomic pending struct ===
        // Una sola malloc, mai dal render thread. RT-safe per design.
        guard let pending = qbeats_link_pending_create() else {
            fatalError("[Q-BEATS] qbeats_link_pending_create failed (OOM)")
        }
        self.linkPending = pending

        metronomeHandle = metronome_create(sampleRate, 120.0)
        midiEngineHandle = midi_engine_create()
        // midi_engine_start() spostato dopo setupGraph() —
        // Link registra il suo listener UDP multicast prima che CoreMIDI
        // apra virtual ports e scan queue. Previene contesa rete al boot.
        // === MODIFICATO 6A ===
        linkEngineHandle = link_engine_create()
        if let lh = linkEngineHandle {
            linkSettingsPresenter = LinkSettingsPresenter(linkHandle: lh)
        }

        if let lh = linkEngineHandle {
            link_engine_set_tempo_callback(lh, { bpm, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async {
                    // Modalità Direttore: non subisce MAI il BPM del peer (Bug 5-BPM chiuso).
                    // Affinamento 29/05/2026 (test R2/R6 su device):
                    // - In play: re-broadcasta _audioBPM e vince la negoziazione Link
                    //   (check bpm != _audioBPM evita loop quando il peer rimanda il valore Q-B).
                    // - In stop: NON adotta il BPM del peer e NON combatte la sessione, così un
                    //   Follower in START LOCAL (CD-6) può seguire il tempo della propria setlist.
                    // Il return (sotto) garantisce entrambi: il Direttore esce sempre prima del
                    // blocco di adozione interna (metronome / MIDI / currentBPM, righe seguenti).
                    if engine._linkMode == .direttore {
                        if engine.isRunning, bpm != engine._audioBPM,
                           let lh = engine.linkEngineHandle {
                            link_engine_set_bpm(lh, engine._audioBPM)
                        }
                        return
                    }
                    if let h = engine.metronomeHandle {
                        metronome_setBPM(h, bpm)
                    }
                    if let mh = engine.midiEngineHandle {
                        midi_engine_set_bpm(mh, bpm)
                    }
                    DispatchQueue.main.async { engine.currentBPM = bpm }
                }
            }, Unmanaged.passUnretained(self).toOpaque())

            link_engine_set_is_connected_callback(lh, { isConnected, ctx in
                guard let ctx = ctx else { return }
                // Callback su main thread (LinkKit 3.2.2)
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                DispatchQueue.main.async {
                    engine.linkIsConnected = isConnected
                }
            }, Unmanaged.passUnretained(self).toOpaque())

            link_engine_set_peers_changed_callback(lh, { ctx, count in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                // già su main thread (LinkKit 3.2.2)
                engine.linkPeers = Int(count)
            }, Unmanaged.passUnretained(self).toOpaque())

            // === Reattività pane Ableton — ABLLinkSetIsEnabledCallback ===
            // Callback main-thread quando l'utente flicca toggle Link nel pane
            // Ableton. Il flag enabled_ C++ è già stato sincronizzato dal
            // callback C++ stesso. Qui replichiamo il pattern di setLinkEnabled
            // SOLO per la parte UI (linkEnabled / linkIsConnected / linkPeers
            // con re-check post-2s), SENZA ri-chiamare link_engine_set_enabled
            // (eviterebbe potenziale loop di re-emission).
            link_engine_set_is_enabled_callback(lh, { isEnabled, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async { [weak engine] in
                    guard let engine = engine,
                          let lh = engine.linkEngineHandle else { return }
                    if isEnabled {
                        let isConn = link_engine_is_connected(lh)
                        DispatchQueue.main.async {
                            engine.linkEnabled = true
                            engine.linkIsConnected = isConn
                            engine.linkPeers = isConn ? 1 : 0
                        }
                        if !isConn {
                            engine.audioQueue.asyncAfter(deadline: .now() + 2.0) {
                                [weak engine] in
                                guard let engine = engine,
                                      let lh = engine.linkEngineHandle else { return }
                                guard link_engine_is_enabled(lh) else { return }
                                let isConn2 = link_engine_is_connected(lh)
                                if isConn2 {
                                    DispatchQueue.main.async {
                                        engine.linkIsConnected = true
                                        engine.linkPeers = 1
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            engine.linkEnabled = false
                            engine.linkIsConnected = false
                            engine.linkPeers = 0
                        }
                    }
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        // === AGGIUNTO 6D — Start/Stop sync callback da peer Link ===
        //
        // CD-6 / Bug 4 fix (28/05/2026) — Opzione C: oltre a propagare lo
        // start/stop al motore audio locale, emette `linkStartedSubject` per
        // far orchestrare LiveView (→ runner.startSetlist). Senza emit il
        // Follower partirebbe audio ma con `_sectionTotalBeats=0` → counter
        // all'infinito + nome canzone non mostrato (Bug 4 / Problema B).
        //
        // Doppia protezione anti race:
        //  (1) Gate `_linkStartEmitInFlight` lato AudioEngine (qui sotto):
        //      evita doppia emissione se il callback arriva 2 volte ravvicinato
        //      prima che `engine.isPlaying` flippi a true (≥3 hop dispatch fra
        //      `engine.start()` audioQueue.async e `main.async` riga ~745).
        //  (2) Gate `playbackState != .playing` lato LiveView observer
        //      (Q-D3 ratificato).
        // Q-D4 esteso ratificato libro mastro v15.
        if let lh = linkEngineHandle {
            link_engine_set_start_stop_callback(lh, { isPlaying, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                // Modalità Direttore: ignora SEMPRE start/stop da peer in qualsiasi
                // stato (sorgente unica autoritativa).
                // Bug 5 fix 28/05/2026 — pre-fix richiedeva isRunning: Director in
                // stop accettava start da peer Collab via START LOCAL (CD-6).
                // Lettura _linkMode da non-audioQueue: Swift enum è safe per lettura concorrente.
                if engine._linkMode == .direttore { return }
                // CRITICO: NON dispatchiamo su audioQueue — stopSync() ha
                // audioQueue.sync dentro e causerebbe deadlock.
                DispatchQueue.main.async {
                    if isPlaying && !engine.isPlaying {
                        // Q-D4 esteso — Gate anti double-emit (vedi commento
                        // su `_linkStartEmitInFlight` decl).
                        guard !engine._linkStartEmitInFlight else { return }
                        engine._linkStartEmitInFlight = true
                        engine.start()
                        engine.linkStartedSubject.send()
                    } else if !isPlaying && engine.isPlaying {
                        engine.stop()
                    }
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        // link_engine_activate() esegue boot reconciliation di ABLLinkIsEnabled
        // persistito (se true: enabled_.store + ABLLinkSetActive(true) +
        // propagazione isEnabledCallback → linkEnabled=true Swift), poi avvia
        // il poll diagnostico #293. Vedi commento estensivo in LinkEngine.mm.
        // Quando ABLLinkIsEnabled è false, l'attivazione resta affidata al
        // toggle UI (link_engine_set_enabled).
        if let lh = linkEngineHandle {
            link_engine_activate(lh)
        }

        // === Task D refactor #18c — pending atomic init ===
        // Inizializzazione preliminare sample_rate nel pending atomic prima
        // che il tap block possa essere invocato. Il tap su mainMixerNode
        // viene installato in setupGraph() dopo connectAllNodes (richiede
        // mainMixerNode collegato al graph). Vedi installLinkTap().
        qbeats_link_pending_set_sample_rate(self.linkPending, sampleRate)

        setupSession()
        setupGraph()
        // MIDI engine avvia DOPO Link e grafo audio — ordine intenzionale.
        if let mh = midiEngineHandle {
            midi_engine_start(mh)
        }
        audioQueue.sync {
            self.clickSamples              = self.generateClickSamples(frequency: 1000.0)
            self.accentedClickSamples      = self.generateClickSamples(frequency: 1500.0)
            self.subdivisionClickSamples   = self.generateClickSamples(frequency: 800.0)
        }
        DispatchQueue.main.async {
            self.sampleRateInfo = AVAudioSession.sharedInstance().sampleRate
        }
        setupNotifications()
        os_log("AppSettings loaded: accent=%.2f beat=%.2f subdiv=%.2f muted=%d",
               log: .default, type: .default,
               appSettings.accentVolume, appSettings.beatVolume, appSettings.subdivVolume,
               appSettings.clickMuted ? 1 : 0)
        applySettings(appSettings)

        if let mh = midiEngineHandle {
            midi_engine_set_receive_callback(mh, { data, length, ctx in
                guard let data = data, let ctx = ctx, length >= 2 else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                let bytes = Array(UnsafeBufferPointer(start: data, count: Int(length)))
                engine.audioQueue.async {
                    engine.handleMIDIInput(bytes)
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }
    }

    // Aggiunge log al ring buffer visivo (ultimi 10 eventi) per la DebugView
    func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logMessage = "[\(timestamp)] \(message)"
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.debugLogs.insert(logMessage, at: 0)
            if self.debugLogs.count > 10 {
                self.debugLogs.removeLast()
            }
        }
    }

    deinit {
        stopSync()
        // === Task D refactor #18c — Correzione 1 referee adattata a installTap ===
        // 1. stopSync() — sopra
        // 2. engine.stop() — ferma render thread (blocking, sincrono per Apple docs)
        // 3. mainMixerNode.removeTap(onBus: 0) — release del tap block ref
        // 4. destroy degli handle C (incluso qbeats_link_pending_destroy)
        // Senza questo ordine, free(linkPending) potrebbe race col render
        // thread che sta ancora eseguendo il tap block → use-after-free.
        engine.stop()
        engine.mainMixerNode.removeTap(onBus: 0)
        if let h = metronomeHandle {
#if QB_DIAG_SPY
            metronome_flush_diag(h)   // SPIA passiva: ultimo flush prima del destroy
#endif
            metronome_destroy(h)
        }
        if let mh = midiEngineHandle { midi_engine_destroy(mh) }
        // === MODIFICATO 6A ===
        if let lh = linkEngineHandle { link_engine_destroy(lh) }
        qbeats_link_pending_destroy(linkPending)
    }

    // MARK: - Public API (chiamabile da qualsiasi thread)

    func start(resumeAtBeat: Double? = nil) {
        os_log("[Q-BEATS][START] ENTRY resumeAtBeat=%{public}@ _startAbsoluteBeat=%.6f",
               log: .default, type: .default,
               resumeAtBeat.map { String(format: "%.6f", $0) } ?? "nil",
               self._startAbsoluteBeat)

        audioQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isRunning, let _ = self.metronomeHandle else {
                os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                       log: .default, type: .default)
                return
            }

            // Build #309: rimosso il vecchio DOWNBEAT WAIT (Opzione B) e il
            // parametro skipLinkWait. La distinzione standalone/master-con-peer/
            // follower avviene ora esplicitamente dentro il blocco do { ... }
            // qui sotto via probe atomica + lettura num_peers, secondo il
            // modello a 3 rami (vedi BOX3_V43_07_05_2026.md).

            do {
                self.bufferCount      = 0
                self.beatTotal        = 0
                self.beatTickCounter  = 0
                // L1.a — coerenza con stopSync(): replay safe.
                // Vedi commento in stopSync() per la motivazione di non
                // toccare _sectionTotalBeats e _onSectionEnd.
                self._sectionBeatCounter = 0
                self.clickPlayhead    = -1
                self.accentPlayhead   = -1
                self.subdivPlayhead   = -1

                try self.engine.start()
                self.playerNode.reset()
                self.playerNode.play()
                self.isRunning = true

#if QB_DIAG_SPY
                // SPIA passiva: abilita il ring L1 (seq azzerato → join con beatTick L3)
                // e ri-arma i marker di sezione. Drain/flush solo allo stop (audio fermo).
                if let h = self.metronomeHandle { metronome_set_diag_enabled(h, true) }
                self._spySectionInstanceIdx = 0
                self._spyMarkerPending = true
                os_log("[Q-BEATS][Bug2b-SPY] enabled — start (ring L1 ON, marker pending)",
                       log: .default, type: .default)
#endif

                if let mh = self.midiEngineHandle {
                    let resumeBeat: Double? = resumeAtBeat

                    midi_engine_sync_clock(mh, 0, mach_absolute_time(), self.sampleRate)

                    if let beat = resumeBeat {
                        // CALCOLO SNAP RELATIVO ALLA FASE DEL PLAY
                        let beatsPerBarD = Double(self._beatsPerBarQ)

                        // 1. Distanza dal beat di inizio del Playback originale
                        let relativePhase = beat - self._startAbsoluteBeat
                        // 2. Snappa alla prossima misura relativa
                        let snappedRelative = ceil(relativePhase / beatsPerBarD) * beatsPerBarD
                        // 3. Torna al beat assoluto del clock di sistema
                        let snappedBeat = self._startAbsoluteBeat + snappedRelative

                        os_log("[Q-BEATS][RESUME] Snap: %.4f -> %.4f (startBeat:%.4f)",
                               log: .default, type: .default, beat, snappedBeat, self._startAbsoluteBeat)

                        midi_engine_set_beat_position(mh, snappedBeat)
                        if let h = self.metronomeHandle {
                            metronome_set_beat_position(h, snappedBeat)
                            os_log("[Q-BEATS][START] -> metronome_set_beat_position(%.6f)",
                                   log: .default, type: .default, snappedBeat)
                        } else {
                            os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                                   log: .default, type: .default)
                        }
                    } else {
                        midi_engine_set_beat_position(mh, 0.0)
                    }
                    if let lh = self.linkEngineHandle {
                        link_engine_set_quantum(lh, Double(self._beatsPerBarQ))
                    }

                    // === Build #309 — Start API semantica (Opzione 2, modello a 3 rami) ===
                    // Branching corretto rispetto a #307: distingue standalone puro
                    // (peers==0) da sessione condivisa (peers>0). Lo standalone è
                    // l'unico caso in cui Q-BEATS può sovrascrivere la timeline Link.
                    if resumeAtBeat != nil {
                        // RESUME: ripartiamo da snappedBeat (calcolato sopra).
                        // Q-BEATS detta la timeline a beat noto. snappedBeat è in
                        // scope sopra dentro l'`if let beat = resumeBeat`,
                        // qui lo ricalcoliamo coerentemente per il branch link.
                        // Bug 2.b ramo X — resume non semina: snap già gestito da
                        // _startAbsoluteBeat. Offset azzerato.
                        self.startBeatOffset = 0
                        let beatsPerBarD = Double(self._beatsPerBarQ)
                        let relativePhase = (resumeAtBeat ?? 0.0) - self._startAbsoluteBeat
                        let snappedRelative = ceil(relativePhase / beatsPerBarD) * beatsPerBarD
                        let snappedBeatLocal = self._startAbsoluteBeat + snappedRelative
                        self.linkSyncSkipBuffers = 3
                        if let lh = self.linkEngineHandle {
                            link_engine_start_at_beat(lh, mach_absolute_time(), snappedBeatLocal)
                        }
                        self.scheduleNextBuffer()
                        self.scheduleNextBuffer()
                        self.scheduleNextBuffer()
                        os_log("[Q-BEATS][LINK][START] resume avviato a beat:%.4f",
                               log: .default, type: .default, snappedBeatLocal)
                    } else {
                        // FRESH PLAY: probe + num_peers per distinguere i 3 scenari.
                        let hostNow = mach_absolute_time()
                        let quantum = Double(self._beatsPerBarQ)
                        var probe = LinkSessionProbe(isPlaying: false,
                                                     phaseAtHost: 0.0,
                                                     tempo: 0.0)
                        var peersCount: UInt32 = 0
                        if let lh = self.linkEngineHandle {
                            probe = link_engine_probe_session(lh, hostNow, quantum)
                            peersCount = link_engine_num_peers(lh)
                        }

                        if (peersCount == 0 && !probe.isPlaying) || self._linkMode == .direttore {
                            // === STANDALONE PURO o DIRETTORE (sorgente unica autoritativa) ===
                            // Bug 2.b ramo X — sorgente autoritativa parte da bar 1: nessun
                            // offset d'ingresso. Garantisce Director/standalone bit-identici.
                            self.startBeatOffset = 0
                            // Director forza la timeline indipendentemente dallo stato dei
                            // peer: start_at_beat_zero mappa beat 0 a hostNow.
                            // I peer ricevono la nuova timeline via Link e si allineano a
                            // beat 0 — partenza musicalmente corretta dall'inizio del brano.
                            // Fix 1.j 28/05/2026 — pre-fix Director con peer in stop prendeva
                            // ramo SHARED → join → latenza fino a ~1s + avvio a metà battuta.
                            // Edge case (peer già in play): Director forza comunque beat 0,
                            // peer si riallinea. Progettato e ratificato.
                            // (Standalone puro: stesso comportamento, Q-BEATS solo nella
                            // sessione Link o Link disabled — bridge early return su !enabled.)
                            if let h = self.metronomeHandle {
                                metronome_reset_for_start(h, 0.0)
                            }
                            self.linkSyncSkipBuffers = 3
                            if let lh = self.linkEngineHandle {
                                link_engine_start_at_beat_zero(lh, hostNow)
                            }
                            self.scheduleNextBuffer()
                            self.scheduleNextBuffer()
                            self.scheduleNextBuffer()
                            os_log("[Q-BEATS][LINK][START] standalone/direttore avviato (mode:%{public}@ peers:%u)",
                                   log: .default, type: .default,
                                   self._linkMode == .direttore ? "direttore" : "standalone",
                                   peersCount)
                        } else {
                            // === SESSIONE CONDIVISA — solo LinkMode.collaborativa ===
                            // Q-BEATS si adegua alla timeline Link esistente: quantized
                            // launch al prossimo downbeat via join_running_session.
                            // Pattern aderente alla doc Ableton: "chi entra si adegua,
                            // chi c'è già non si muove".
                            // (Il ramo .direttore non arriva mai qui — gestito sopra.)
                            let bpm = probe.tempo > 0.0 ? probe.tempo : self.currentBPM
                            let phase = probe.phaseAtHost
                            // Se phase ≈ 0 o ≈ quantum siamo già sul downbeat → no wait.
                            // Altrimenti aspettiamo (quantum - phase) beat.
                            let beatsToWait = (phase < 0.001 || phase > quantum - 0.001)
                                              ? 0.0
                                              : (quantum - phase)
                            let delaySecondsBase = beatsToWait * (60.0 / bpm)
#if DIAG_FORCE_BORN_OFFSET
                            // === HARNESS forzatura born — SEPARATO dalla spia passiva ===
                            // Modifica di COMPORTAMENTO (NON osservazione): aggiunge 0.5 beat
                            // all'attesa così l'aggancio cade FUORI dal downbeat
                            // (round(startBeat)≠0) → riproduce il born oltre N=1.
                            // Dati TAGGATI [Bug2b-SPY-FORCED] = distinti dai giri passivi.
                            // Compilato SOLO con DIAG_FORCE_BORN_OFFSET (config dedicata, MAI
                            // il build di default; si usa insieme a QB_DIAG_SPY per osservare).
                            let delaySeconds = delaySecondsBase + 0.5 * (60.0 / bpm)
                            os_log("[Q-BEATS][Bug2b-SPY-FORCED] born forzato +0.5 beat (delay %.3f→%.3f s)",
                                   log: .default, type: .default, delaySecondsBase, delaySeconds)
#else
                            let delaySeconds = delaySecondsBase
#endif

                            // Conversione delaySeconds → mach ticks per
                            // futureHostTime esatto (timestamp Link insensibile
                            // al jitter dispatch).
                            var timebase = mach_timebase_info_data_t()
                            mach_timebase_info(&timebase)
                            let delayNs = delaySeconds * 1_000_000_000.0
                            let delayTicks = UInt64(delayNs
                                                    * Double(timebase.denom)
                                                    / Double(timebase.numer))
                            let futureHostTime = hostNow + delayTicks

                            os_log("[Q-BEATS][LINK][SHARED] peers:%u isPlaying:%d phase:%.4f attesa:%.4f beat (%.3f s) bpm:%.2f",
                                   log: .default, type: .default,
                                   peersCount, probe.isPlaying ? 1 : 0,
                                   phase, beatsToWait, delaySeconds, bpm)

                            DispatchQueue.main.async {
                                self.isWaitingForLinkDownbeat = true
                            }

                            // ROTTA α (Build #307→#309): l'annuncio Link è DENTRO
                            // il work item. Se l'utente preme stop prima del fire,
                            // pendingLinkStart?.cancel() impedisce ogni
                            // pubblicazione di stato a Link → atomicità by design.
                            // Timestamp = futureHostTime catturato in closure,
                            // NON mach_absolute_time() rileggiuto al fire.
                            let lhCaptured = self.linkEngineHandle
                            let work = DispatchWorkItem { [weak self] in
                                guard let self else { return }
                                DispatchQueue.main.async {
                                    self.isWaitingForLinkDownbeat = false
                                }
                                if let lh = lhCaptured {
                                    link_engine_join_running_session(lh, futureHostTime)
                                }
                                if let h = self.metronomeHandle {
                                    metronome_reset_for_start(h, 0.0)
                                }
                                // === Bug 2.b ramo X — SEED contatore sezione del Follower ===
                                // Il Follower entra dopo il count-in del Director (≥1 bar).
                                // _sectionBeatCounter è già stato azzerato da loadSection (936-944)
                                // e da start() (~634), ENTRAMBI prima di questo work item ritardato.
                                // Seminiamo QUI, PRIMA del pre-roll sottostante: il primo
                                // scheduleNextBuffer emette già il primo beat (resetForStart fissa
                                // _exactNextBeatSample=0 → beat al sample 0) che fa
                                // _sectionBeatCounter += 1. Seminare dopo il pre-roll = off-by-one.
                                //
                                // startBeat = fase allineata alla sessione Link al momento del join
                                // (≈ bar saltati nel count-in del Director). È within-section e NON
                                // si accumula tra brani perché il Director rimappa Link a beat 0 a
                                // ogni canzone (link_engine_start_at_beat_zero, LinkEngine.mm:427-445).
                                // Variabile LOCALE: NON tocchiamo _startAbsoluteBeat (snap resume).
                                if let mh = self.midiEngineHandle {
                                    let startBeat = midi_engine_get_beat_at_time(
                                        mh,
                                        futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks)
                                    // Spia: aggancio non sul downbeat (frazione in valore assoluto).
                                    // Problema a monte da non mascherare — log, non correzione.
                                    if abs(startBeat - startBeat.rounded()) > 0.1 {
                                        os_log("[Q-BEATS][Bug2b] WARN aggancio non su downbeat — startBeat:%.4f frazione:%.3f",
                                               log: .default, type: .error,
                                               startBeat, startBeat - startBeat.rounded())
                                    }
                                    let offset = Int(startBeat.rounded())
                                    // Rete portante: semina SOLO se l'offset è coerente con la
                                    // sezione. Fuori (0, _sectionTotalBeats) → no-op = comportamento
                                    // di oggi (counter da bar 1), niente swap immediato né brano rotto.
                                    if offset > 0 && offset < self._sectionTotalBeats {
                                        self.startBeatOffset = offset
                                        self._sectionBeatCounter = offset
                                    } else {
                                        self.startBeatOffset = 0
                                        self._sectionBeatCounter = 0
                                        // Il ramo SHARED si aspetta SEMPRE offset > 0 (il Follower
                                        // entra dopo il count-in del Director): qualsiasi else —
                                        // incluso offset == 0 — è un'anomalia da loggare sempre.
                                        os_log("[Q-BEATS][Bug2b] seed SKIP su SHARED — offset:%d fuori range [1,%d) — no-op safe (atteso >0)",
                                               log: .default, type: .error,
                                               offset, self._sectionTotalBeats)
                                    }
                                }
                                self.linkSyncSkipBuffers = 3
                                self.scheduleNextBuffer()
                                self.scheduleNextBuffer()
                                self.scheduleNextBuffer()
                                // Sovrascrive _startAbsoluteBeat con il valore
                                // corretto: il primo sample audio reale parte a
                                // futureHostTime, non al mach_absolute_time() di
                                // quando è stato schedulato il work item.
                                if let mh = self.midiEngineHandle {
                                    self._startAbsoluteBeat = midi_engine_get_beat_at_time(
                                        mh,
                                        futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks)
                                }
                                os_log("[Q-BEATS][LINK][SHARED] downbeat raggiunto — avvio motore startBeat:%.4f",
                                       log: .default, type: .default,
                                       self._startAbsoluteBeat)

#if QB_DIAG_SPY
                                // SPIA passiva — TRE sorgenti all'aggancio (campo concomitante,
                                // letture PASSIVE su audioQueue, nessun cambio di comportamento):
                                //  linkPhase_schedule = Link ABLLinkPhaseAtTime @hostNow (R1, già usata da prod)
                                //  linkPhase_fire     = Link ABLLinkPhaseAtTime @fireHostTime (probe passiva)
                                //  midiBeat_fire      = MIDI engine @fireHostTime (R2/R3, usata da prod)
                                // Coerenza Link↔MIDI osservabile: linkPhase_fire vs (midiBeat_fire mod quantum).
                                if let lhSpy = lhCaptured, let mhSpy = self.midiEngineHandle {
                                    let fireHostTime = futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks
                                    let probeFire = link_engine_probe_session(lhSpy, fireHostTime, quantum)
                                    let midiBeatFire = midi_engine_get_beat_at_time(mhSpy, fireHostTime)
                                    os_log("[Q-BEATS][Bug2b-SPY-ATTACH] linkPhase_schedule:%.4f linkPhase_fire:%.4f midiBeat_fire:%.4f quantum:%.1f startAbs:%.4f",
                                           log: .default, type: .default,
                                           phase, probeFire.phaseAtHost, midiBeatFire, quantum, self._startAbsoluteBeat)
                                }
#endif
                            }
                            self.pendingLinkStart = work
                            self.audioQueue.asyncAfter(deadline: .now() + delaySeconds, execute: work)
                        }
                    }

                    if UserDefaults.standard.bool(forKey: "networkMIDIEnabled") {
                        midi_engine_network_enable(mh)
                    } else {
                        midi_engine_network_disable(mh)
                    }
                } else {
                    os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                           log: .default, type: .default)
                }

                let sr  = AVAudioSession.sharedInstance().sampleRate
                let buf = AVAudioSession.sharedInstance().ioBufferDuration * sr
                let statusStr = "started SR:\(Int(sr)) buf:\(Int(buf)) samples:\(self.clickSamples.count)"
                let uiPattern = self.defaultAccentPattern(for: self._beatsPerBarQ).map { $0 > 0 ? 2 : 1 as UInt8 }
                DispatchQueue.main.async {
                    self.isPlaying            = true
                    self.playbackState        = .playing
                    self.clickStatus          = statusStr
                    self.currentAccentPattern = uiPattern
                    // CD-6 / Bug 4 fix (Q-D4 esteso) — Reset gate anti
                    // double-emit linkStartedSubject. Da qui `isPlaying == true`
                    // → il guard `!engine.isPlaying` del callback Link
                    // protegge da double-start senza più bisogno del flag.
                    self._linkStartEmitInFlight = false
                }

                let avSession = AVAudioSession.sharedInstance()
                self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                if let lh = self.linkEngineHandle {
                    link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                }

                // Registra il beat di partenza (solo fresh play, latenza inclusa).
                // Build #309: per il ramo "sessione condivisa" (peers > 0) questo
                // valore verrà sovrascritto al fire del work item (vedi flow sopra),
                // perché il primo sample reale parte a futureHostTime, non a "now".
                // Per standalone resta corretto.
                if resumeAtBeat == nil, let mh = self.midiEngineHandle {
                    let hostTimeAtFirstSample = mach_absolute_time()
                                                + self.outputLatencyTicks
                                                + self.bufferDurationTicks
                    self._startAbsoluteBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
                }

                // Build #309: rimosso il scheduleNextBuffer × 3 ridondante per il
                // resume (ora è già chiamato esplicitamente dentro il branch RESUME
                // sopra, con la nuova API link_engine_start_at_beat).
            } catch {
                os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                       log: .default, type: .default)
                let errStr = "start fallito: \(error)"
                DispatchQueue.main.async { self.clickStatus = errStr }
            }
        }
    }

    func stop() {
        stopSync()
#if QB_DIAG_SPY
        // SPIA passiva: flush finale del ring L1 (audio già fermo da stopSync → no race).
        if let h = metronomeHandle { metronome_flush_diag(h) }
#endif
        // P1+P3 fix: allinea playbackState all'isPlaying su ogni percorso di stop.
        // Pattern già usato in handleStop() (.countIn/.playing) e restartFromBeginning().
        // Senza questo dispatch, lo stop manuale lasciava playbackState=.playing
        // mentre isPlaying=false → desincronizzazione UI (segmento bloccato bianco,
        // TransportView label/glyph fuori sync — TransportView re-render solo su
        // session.playbackState, non su audioEngine.isPlaying).
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    }

    func setBPM(_ bpm: Double) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            // Task D — Annulla cambio BPM schedulato non ancora scattato.
            // setBPM è path immediato: il valore di bpm sostituisce qualunque
            // valore pending. Cancel Layer 1 PRIMA di metronome_setBPM evita
            // che un downbeat appena successivo applichi il valore vecchio
            // (race-free: tutto su audioQueue).
            if self._pendingBPMValue != nil {
                metronome_cancel_pending_bpm(h)
                self._pendingBPMValue = nil
                self._pendingBPMTargetTick = 0
            }
            metronome_setBPM(h, bpm)
            self._audioBPM = bpm
            if let mh = self.midiEngineHandle {
                // Strada E (Task D fix #2) — re-anchor MIDI engine beat position
                // attraverso il cambio BPM. MIDISequencer::setBPM ricalcola
                // _samplesPerTick ma NON aggiorna _sampleBaseAdj → la posizione
                // tracciata salta proporzionalmente a currentSample (verificato
                // sui log 11/05/2026: beat_proj=22.23 con beatTickCounter=20).
                // Leggi posizione PRIMA del cambio, applica setBPM (che salta),
                // ri-ancora alla stessa posizione col nuovo BPM.
                let preChangeBeatPos = midi_engine_get_beat_position(mh)
                midi_engine_set_bpm(mh, bpm)
                midi_engine_set_beat_position(mh, preChangeBeatPos)
            }
            if let lh = self.linkEngineHandle {
                link_engine_set_bpm(lh, bpm)
            }
            DispatchQueue.main.async { self.currentBPM = bpm }
        }
    }

    // === L1.a — Caricamento sezione + closure end-of-section ===
    // Chiamabile da qualunque thread. Internamente:
    //   - audioQueue per i 3 mirror privati (_sectionTotalBeats, _sectionBeatCounter, _onSectionEnd)
    //   - main per currentSectionRepetitions @Published (display Vista LIVE)
    // Semantica:
    //   repetitions > 0  → registra closure single-shot, scatterà sull'ultimo beat
    //                       della sezione (totalBeats = repetitions × beatsPerBar)
    //   repetitions <= 0 → nessun limite (loop infinito esplicito -1 o reset 0),
    //                       closure NON registrata, nessun stop automatico
    // Il display Vista LIVE riflette il valore passato (positivo, 0, o -1) — la
    // distinzione 0 vs -1 è preservata per coerenza con SongSection.repetitions.
    func loadSection(beatsPerBar: UInt32,
                     repetitions: Int,
                     onEnd: @escaping () -> Void) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            if repetitions > 0 {
                self._sectionTotalBeats = repetitions * Int(beatsPerBar)
                self._sectionBeatCounter = 0
                self._onSectionEnd = onEnd
            } else {
                self._sectionTotalBeats = 0
                self._sectionBeatCounter = 0
                self._onSectionEnd = nil
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.currentSectionRepetitions = repetitions
        }
    }

    // === Strada A — Pre-load parametri sezione successiva ===
    // Salva i parametri della prossima sezione nei _pendingNext* SENZA
    // toccare la sezione corrente e SENZA chiamare alcuna C-API DSP.
    // Le C-API metronome_schedule_* partono SOLO nel beat callback
    // all'ultimo beat della sezione corrente (ramo SEAMLESS in
    // scheduleNextBuffer).
    //
    // Parametro accentPattern: convenzione UI (2=accent, 1=beat, 0=subdiv),
    // coerente con setAccentPattern. La conversione UI→DSP avviene nello
    // step d del ramo SEAMLESS.
    //
    // Calcolo critico: _pendingNextSectionTotalBeats = repetitions * Int(beatsPerBar)
    // USANDO IL NUOVO beatsPerBar PARAMETRO, MAI _beatsPerBarQ corrente.
    func preloadNextSection(bpm: Double,
                            beatsPerBar: UInt32,
                            accentPattern: [UInt8],
                            repetitions: Int,
                            onEnd: @escaping () -> Void) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self._pendingNextBPM = bpm
            self._pendingNextBPB = beatsPerBar
            self._pendingNextAccentPattern = accentPattern
            self._pendingNextSectionTotalBeats = repetitions * Int(beatsPerBar)
            self._pendingNextOnSectionEnd = onEnd
            self._pendingNextRepetitions = repetitions
        }
    }

    /// Riavvia la catena di completion handler del playerNode dopo un drain
    /// di sezione. Il branch drain fa `return` senza schedulare un nuovo
    /// buffer al playerNode. Le sezioni lunghe (steady-state buffer al
    /// minimo) lasciano la coda vuota dopo il drain, e la catena di
    /// completion handler si esaurisce naturalmente. Sezioni brevi
    /// sopravvivono per buffer residui del pre-roll iniziale non ancora
    /// consumati. Questo metodo ripristina 3 buffer in coda
    /// incondizionatamente, eliminando la dipendenza dalla fortuna.
    /// Pattern identico al pre-roll iniziale (righe 586-588).
    /// Chiamare SOLO dal ramo avanza di SetlistRunner, dopo scheduleBPMChange.
    /// Wrappa in audioQueue.async perché il chiamante gira su main thread
    /// (closure end dispatchata da DispatchQueue.main.async).
    func kickScheduling() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
        }
    }

    func tapTempo() {
        guard let bpm = tapTempoEngine.tap() else { return }
        let rounded = (bpm * 10).rounded() / 10
        setBPM(rounded)
        os_log("Tap tempo: %{public}.1f BPM", log: .default, type: .default, rounded)
    }

    func handleStop() {
        switch playbackState {
        case .playing:
            stopSync()
            let sectionName = currentSection ?? ""
            let songName = currentSong ?? ""
            os_log("[Q-BEATS][UX-3] handleStop: playing → pausedAwaitingChoice section:%{public}@ song:%{public}@",
                   log: .default, type: .default, sectionName, songName)
            DispatchQueue.main.async { [weak self] in
                self?.playbackState = .pausedAwaitingChoice(sectionName: sectionName, songName: songName)
            }
        case .countIn:
            stopSync()
            resetToSongStart()
            os_log("[Q-BEATS][UX-3] handleStop: countIn → stopped",
                   log: .default, type: .default)
            DispatchQueue.main.async { [weak self] in
                self?.playbackState = .stopped
            }
        default:
            break
        }
    }

    func resumeFromCurrentSection() {
        os_log("[Q-BEATS][UX-3] resumeFromCurrentSection → countIn",
               log: .default, type: .default)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .countIn
        }
        startCountIn(for: currentSection)
    }

    func restartFromBeginning() {
        resetToSongStart()
        os_log("[Q-BEATS][UX-3] restartFromBeginning → stopped",
               log: .default, type: .default)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    }

    // Stub — implementazione in Fase Backtrack
    func restartCurrentSong() { restartFromBeginning() }
    func prevSection() {}
    func nextSection() {}
    func toggleLoop() {}

    func triggerDNDReminderIfNeeded() {
        guard appSettings.showDNDReminder,
              !dndReminderShownThisSession else { return }
        dndReminderShownThisSession = true
        DispatchQueue.main.async {
            self.shouldShowDNDReminder = true
        }
    }

    func dismissDNDReminder(permanent: Bool) {
        DispatchQueue.main.async {
            self.shouldShowDNDReminder = false
            if permanent {
                self.appSettings.showDNDReminder = false
                self.appSettings.save()
            }
        }
    }

    func setShowDNDReminder(_ value: Bool) {
        appSettings.showDNDReminder = value
        appSettings.save()
    }

    func setLinkEnabled(_ enabled: Bool) {
        audioQueue.async { [weak self] in
            guard let self = self, let lh = self.linkEngineHandle else {
                os_log("[Q-BEATS][LINK][SWIFT] setLinkEnabled: guard fallita — handle o self nil",
                       log: .default, type: .default)
                return
            }
            os_log("[Q-BEATS][LINK][SWIFT] setLinkEnabled(%{public}@) → chiamata C++",
                   log: .default, type: .default, enabled ? "true" : "false")
            link_engine_set_enabled(lh, enabled)
            if enabled {
                let isConn = link_engine_is_connected(lh)
                DispatchQueue.main.async {
                    self.linkEnabled = true
                    self.linkIsConnected = isConn
                    self.linkPeers = isConn ? 1 : 0
                }
                if !isConn {
                    self.audioQueue.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        guard let self = self, let lh = self.linkEngineHandle else { return }
                        guard link_engine_is_enabled(lh) else { return }
                        let isConn2 = link_engine_is_connected(lh)
                        os_log("[Q-BEATS][LINK][SWIFT] check 2s post-enable — isConn:%{public}@",
                               log: .default, type: .default, isConn2 ? "true" : "false")
                        if isConn2 {
                            DispatchQueue.main.async {
                                self.linkIsConnected = true
                                self.linkPeers = 1
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.linkEnabled = false
                    self.linkIsConnected = false
                    self.linkPeers = 0
                }
            }
        }
    }

    func disableLinkOnTerminate() {
        audioQueue.sync {
            if let lh = linkEngineHandle {
                link_engine_set_enabled(lh, false)
            }
        }
    }

    func enableNetworkMIDI() {
        UserDefaults.standard.set(true, forKey: "networkMIDIEnabled")
        audioQueue.async { [weak self] in
            guard let self = self, let h = self.midiEngineHandle else { return }
            midi_engine_network_enable(h)
        }
    }

    func disableNetworkMIDI() {
        UserDefaults.standard.set(false, forKey: "networkMIDIEnabled")
        audioQueue.async { [weak self] in
            guard let self = self, let h = self.midiEngineHandle else { return }
            midi_engine_network_disable(h)
        }
    }

    // Wrapper thin per callsite non-UI. Tutta la logica DSP vive nel didSet
    // della @Published beatsPerBar (tech debt #14 — V53).
    func setBeatsPerBar(_ bpb: UInt32) {
        self.beatsPerBar = bpb
    }

    func setAccentPattern(_ pattern: [UInt8]) {
        guard let h = metronomeHandle else { return }
        // L1.b — `pattern` arriva in convenzione UI/SongSection:
        //   0 = subdiv, 1 = beat normale, 2 = accent.
        // Display @Published `currentAccentPattern` usa stessa convenzione
        // UI (MetSlotStripView mappa 2→accent, 1→beat, 0→subdiv) — passa
        // pattern RAW, senza mapping.
        DispatchQueue.main.async { self.currentAccentPattern = pattern }
        // DSP C++ usa convenzione propria: 1 = accent, 0 = beat normale.
        // Converti UI → DSP prima di passare a metronome_setAccentPattern.
        // Coerente con setBeatsPerBar didSet che alimenta il DSP con
        // l'output RAW di defaultAccentPattern (già in convenzione DSP).
        let dspPattern: [UInt8] = pattern.map { $0 == 2 ? 1 : 0 }
        audioQueue.async { [h, dspPattern] in
            dspPattern.withUnsafeBufferPointer { ptr in
                metronome_setAccentPattern(h, ptr.baseAddress, UInt32(dspPattern.count))
            }
        }
    }

    func setSubdivision(multiplier: UInt8, swingRatio: Double = 0.5) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_setSubdivision(h, multiplier, swingRatio)
        }
    }

    func scheduleBPMChange(_ newBPM: Double, atNextBeat: Bool = false) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_schedule_bpm_change(h, newBPM)
            // === Step 3 (rev.2) — disabilita DIRECTOR-ASSERT durante transizione tempo ===
            // linkSyncSkipBuffers settato QUI (audioQueue.async, FIFO prima di
            // kickScheduling nel ramo avanza SetlistRunner) anzichè nel beat callback
            // target tick. Motivo: i 3 buffer di kickScheduling girano su audioQueue
            // PRIMA che il beat target sia processato. Senza skip pre-armato,
            // link_engine_assert_session_state scatta con il vecchio BPM durante i
            // kick buffer (osservato a 19:21:17 sul commit d29c4b7: DIRECTOR-ASSERT
            // bpm:100.00 PRIMA del broadcast TaskD-AQ a bpm:130.0). 100 buffer ~1s
            // coprono sia la finestra pre-broadcast (kick buffer con vecchio BPM)
            // sia la finestra post-broadcast (downbeat applicato + margine residuo
            // convergenza fase). max() evita di ridurre uno skip già più lungo se
            // due cambi BPM si sovrappongono.
            self.linkSyncSkipBuffers = max(self.linkSyncSkipBuffers, 100)
            // Task D — calcola il tick del prossimo downbeat in scala
            // beatTickCounter (1-based: tick=1 è il primo downbeat al play,
            // poi tick=1+beatsPerBar, 1+2*beatsPerBar, ...).
            // Formula: downbeat sse (tick-1) % beatsPerBar == 0.
            // Caso beatTickCounter == 0 (pre-play): target=1, scatterà al play.
            // Altrimenti: primo downbeat strettamente > beatTickCounter.
            //
            // L1.b Opzione A — atNextBeat:true bypassa la formula bpb-dipendente.
            // Usato dal ramo avanza di SetlistRunner: a fine sezione, il prossimo
            // beat coincide col primo beat (= primo downbeat) della nuova sezione,
            // indipendentemente da cambi di time signature. Evita il bug noto
            // della formula quando _beatsPerBarQ è già stato aggiornato al nuovo
            // bpb da setBeatsPerBar prima della chiamata.
            let bpb = Int(self._beatsPerBarQ)
            let target: Int
            if atNextBeat {
                target = self.beatTickCounter + 1
            } else if self.beatTickCounter == 0 {
                target = 1
            } else {
                target = ((self.beatTickCounter - 1) / bpb + 1) * bpb + 1
            }
            self._pendingBPMValue = newBPM
            self._pendingBPMTargetTick = target
            os_log("[Q-BEATS][TaskD] scheduleBPMChange %.1f BPM — target tick:%d (current:%d, bpb:%d, atNextBeat:%d)",
                   log: .default, type: .default,
                   newBPM, target, self.beatTickCounter, bpb, atNextBeat ? 1 : 0)
        }
    }

    func setChannelVolume(_ channel: Int, volume: Float) {
        guard (1...4).contains(channel) else { return }
        let v = max(0.0, min(1.0, volume))
        audioQueue.async { [weak self] in
            guard let self else { return }
            switch channel {
            case 1:
                self.ch1Volume = v
                self.ch1MixerNode.outputVolume = v
            case 2:
                self.ch2Volume = v
                self.ch2MixerNode.outputVolume = v
            case 3:
                self.ch3Volume = v
                self.ch3MixerNode.outputVolume = v
            case 4:
                self.ch4Volume = v
                self.ch4MixerNode.outputVolume = v
            default: break
            }
            let vols = [self.ch1Volume, self.ch2Volume, self.ch3Volume, self.ch4Volume]
            let v1 = self.ch1Volume
            let v2 = self.ch2Volume
            let v3 = self.ch3Volume
            let v4 = self.ch4Volume
            DispatchQueue.main.async {
                self.channelVolumes = vols
                self.appSettings.updateChannelVolumes(ch1: v1, ch2: v2, ch3: v3, ch4: v4)
            }
        }
    }

    func armBacktrack(url: URL) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                ) else {
                    os_log("[Q-BEATS][BACKTRACK] armBacktrack: buffer alloc fallito",
                           log: .default, type: .error)
                    return
                }
                try file.read(into: buffer)
                self.backtrackBuffer = buffer
                self.backtrackArmed  = true
                os_log("[Q-BEATS][BACKTRACK] armed — frames:%d SR:%.0f",
                       log: .default, type: .default,
                       buffer.frameLength,
                       file.processingFormat.sampleRate)
            } catch {
                self.backtrackBuffer = nil
                self.backtrackArmed  = false
                os_log("[Q-BEATS][BACKTRACK] armBacktrack error: %{public}@",
                       log: .default, type: .error,
                       error.localizedDescription)
            }
        }
    }

    func playBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard self.backtrackArmed, let buffer = self.backtrackBuffer else {
                os_log("[Q-BEATS][BACKTRACK] playBacktrack: non armato — noop",
                       log: .default, type: .default)
                return
            }
            self.backtrackPlayerNode.stop()
            self.backtrackPlayerNode.scheduleBuffer(buffer, at: nil, options: []) {
                os_log("[Q-BEATS][BACKTRACK] playback completato",
                       log: .default, type: .default)
            }
            self.backtrackPlayerNode.play()
            os_log("[Q-BEATS][BACKTRACK] play avviato",
                   log: .default, type: .default)
        }
    }

    func stopBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.backtrackPlayerNode.stop()
            os_log("[Q-BEATS][BACKTRACK] stop emergenza",
                   log: .default, type: .default)
        }
    }

    func disarmBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.backtrackPlayerNode.stop()
            self.backtrackBuffer = nil
            self.backtrackArmed  = false
            os_log("[Q-BEATS][BACKTRACK] disarmato",
                   log: .default, type: .default)
        }
    }

    private func defaultAccentPattern(for beatsPerBar: UInt32) -> [UInt8] {
        switch beatsPerBar {
        case 2:  return [1,0]
        case 3:  return [1,0,0]
        case 4:  return [1,0,0,0]
        case 5:  return [1,0,0,1,0]
        case 6:  return [1,0,0,1,0,0]
        case 7:  return [1,0,0,1,0,1,0]
        case 12: return [1,0,0,1,0,0,1,0,0,1,0,0]
        default:
            var p = [UInt8](repeating: 0, count: Int(beatsPerBar))
            if !p.isEmpty { p[0] = 1 }
            return p
        }
    }

    // MARK: - Private

    // L3 stub — sostituito da Layer 3 quando disponibile.
    private func startCountIn(for section: String?) {
        start()
    }

    // L3 stub — sostituito da Layer 3 quando disponibile.
    private func resetToSongStart() {}

    // Chiamare SOLO su audioQueue.
    private func handleMIDIInput(_ bytes: [UInt8]) {
        guard bytes.count >= 2 else { return }
        let status  = bytes[0] & 0xF0
        let channel = (bytes[0] & 0x0F) + 1  // 1-based
        let number  = bytes[1]

        let eventType: MIDIEventType
        switch status {
        case 0xB0:
            eventType = .cc
        case 0x90:
            guard bytes.count >= 3, bytes[2] > 0 else { return }  // filtra Note Off (velocity=0)
            eventType = .note
        default:
            return  // ignora SysEx, PitchBend, AfterTouch, ecc.
        }

        DispatchQueue.main.async {
            if let pendingAction = self.midiLearnPendingAction {
                let mapping = MIDILearnMapping(channel: channel, type: eventType, number: number)
                self.midiLearnStore.setMapping(mapping, for: pendingAction)
                self.midiLearnPendingAction = nil
                os_log("[Q-BEATS][MIDI LEARN] Mappato %{public}@ → type:%{public}@ ch:%d num:%d",
                       log: .default, type: .default,
                       pendingAction.rawValue, eventType.rawValue,
                       channel, number)
                self.addLog("LEARN OK: \(pendingAction.rawValue) → \(eventType.rawValue) ch:\(channel) num:\(number)")
                return
            }
            if let action = self.midiLearnStore.action(for: eventType, channel: channel, number: number) {
                self.executeMIDIAction(action)
                self.addLog("MIDI ACTION: \(action.rawValue)")
            }
        }
    }

    // Chiamare SOLO su main thread.
    private func executeMIDIAction(_ action: MIDIAction) {
        switch action {
        case .playPause:
            if isPlaying { stop() } else { start() }
        case .stop:
            handleStop()
        case .muteClickToggle:
            appSettings.clickMuted.toggle()
        case .stopBacktrack:
            stopBacktrack()
        case .tapTempo:
            tapTempo()
        case .nextSection, .prevSection, .nextSong, .startSong, .loopToggle:
            os_log("[Q-BEATS][MIDI ACTION] %{public}@ — richiede Layer 3",
                   log: .default, type: .default, action.rawValue)
        }
    }

    // NON chiamare dall'interno di audioQueue (deadlock).
    private func stopSync() {
        var wasRunning = false
        var bc = 0
        var bt = 0
        audioQueue.sync {
            pendingLinkStart?.cancel()
            pendingLinkStart = nil
            if isWaitingForLinkDownbeat {
                DispatchQueue.main.async {
                    self.isWaitingForLinkDownbeat = false
                }
            }
            wasRunning = self.isRunning
            guard self.isRunning else { return }
            self.isRunning = false
            bc = self.bufferCount
            bt = self.beatTotal
            
            // Build #309: notifica Link che la riproduzione è ferma — API semantica.
            if let lh = linkEngineHandle {
                link_engine_stop(lh, mach_absolute_time())
            }
            // QA-1 drift analysis reset
            self.qa1BeatCounter  = 0
            self.qa1StartTime    = 0
            self.beatTickCounter = 0
            // L1.a — reset counter sezione per replay corretto.
            // _sectionTotalBeats e _onSectionEnd RESTANO registrati: la sezione
            // caricata deve persistere tra stop/play (es. utente preme Stop a
            // metà sezione e poi Play — la sezione ricomincia da capo, non
            // viene "scaricata"). Solo il counter va azzerato.
            self._sectionBeatCounter = 0
            // Bug 2.b ramo X — nessun offset d'ingresso stale al prossimo play.
            self.startBeatOffset = 0
            // Task D — Stop manuale o autostop: annulla cambio BPM pending.
            // Senza questo, un cambio armato pre-stop scatterebbe al replay
            // (DSP riapplicherebbe _pendingBPM al primo downbeat post-Play).
            // Cancel DSP + reset Swift, sempre simmetrico.
            if let mh = self.metronomeHandle {
                if self._pendingBPMValue != nil {
                    metronome_cancel_pending_bpm(mh)
                }
                // Strada A — Cancel BPB INCONDIZIONATO.
                // Dopo il ramo seamless tutti i _pendingNext* sono nil, ma
                // _bpbChangeDirty nel DSP è ancora true (armato in step d).
                // Se lo stop arriva tra lo swap e il downbeat, il cancel
                // condizionale non scatterebbe e il BPB pendente verrebbe
                // applicato al replay successivo.
                // No-op se _bpbChangeDirty già false — zero costo.
                metronome_cancel_pending_bpb(mh)
            }
            self._pendingBPMValue = nil
            self._pendingBPMTargetTick = 0
            // Strada A — Reset tutti i _pendingNext* a nil.
            // Accent pattern NON richiede cancel: _patternDirty viene
            // sovrascritto dal prossimo setAccentPattern al reload.
            self._pendingNextBPM = nil
            self._pendingNextBPB = nil
            self._pendingNextAccentPattern = nil
            self._pendingNextSectionTotalBeats = nil
            self._pendingNextOnSectionEnd = nil
            self._pendingNextRepetitions = nil
            // L1.a — Stop manuale durante drain: aborta dispatch pending.
            // Non chiamiamo la closure: stopSync sta già facendo il lavoro che
            // la closure di L1.a avrebbe fatto (stop motore + reset). Lasciarla
            // pending la farebbe scattare al prossimo Play, scenario indesiderato.
            self._sectionEndPending = false
            self._pendingEndClosure = nil
            self.backtrackPlayerNode.stop()
        }
        guard wasRunning else { return }
        playerNode.stop()
        engine.stop()
        let statusStr = "stopped buf:\(bc) beats:\(bt)"
        DispatchQueue.main.async {
            self.isPlaying   = false
            self.clickStatus = statusStr
        }
    }

    private func activateSessionAndStart(
        resumeAtBeat: Double?,
        trigger: String,
        mode: AudioMode? = nil,
        attempt: Int = 0,
        token: Int = -1
    ) {
        // — Token anti-zombie —
        var activeToken = token
        if attempt == 0 {
            currentResumeToken += 1
            activeToken = currentResumeToken

            // — Reset sessione e hardware gate (solo al primo tentativo) —
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [])
            } catch {
                os_log("[Q-BEATS][RESUME] setCategory fallito: %{public}@. Pending=true.",
                       log: .default, type: .error, error.localizedDescription)
                self.pendingResume = true
                self.pendingResumeBeat = nil
                return
            }

            // Sequenza iOS obbligatoria: setCategory → setPreferredOutputNumberOfChannels → setActive.
            // mode passato dal call site quando noto; nil = rileva ora.
            let targetMode = mode ?? detectAudioMode()
            configureSessionChannels(for: targetMode)

            if session.isOtherAudioPlaying {
                os_log("[Q-BEATS][RESUME] Hardware ancora occupato (isOtherAudioPlaying). Pending=true.",
                       log: .default, type: .default)
                self.pendingResume = true
                self.pendingResumeBeat = nil
                return
            }
        } else if activeToken != currentResumeToken {
            os_log("[Q-BEATS][RESUME] Zombie retry ucciso (token %d vs %d) trigger:%{public}@",
                   log: .default, type: .default, activeToken, currentResumeToken, trigger)
            return
        }

        os_log("[Q-BEATS][RESUME] trigger:%{public}@ attempt:%d token:%d",
               log: .default, type: .default, trigger, attempt, activeToken)

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try AVAudioSession.sharedInstance().setActive(true,
                    options: .notifyOthersOnDeactivation)

                // SOLO QUI: reset stato interruzione
                self.isAudioInterrupted = false
                self.pendingResume = false
                self.pendingResumeBeat = nil

                os_log("[Q-BEATS][RESUME] setActive OK dopo %d tentativi (token:%d trigger:%{public}@)",
                       log: .default, type: .default, attempt, activeToken, trigger)

                // Rebuild grafo Pro DOPO setActive(true) — il formato 4ch è disponibile solo ora.
                // In Base mode il grafo è già corretto (setupGraph usa sempre Base).
                let currentMode = mode ?? self.detectAudioMode()
                if currentMode == .pro {
                    self.rebuildGraph(for: .pro)
                    os_log("[Q-BEATS][RESUME] rebuildGraph Pro eseguito post-setActive (trigger:%{public}@)",
                           log: .default, type: .default, trigger)
                }

                self.start(resumeAtBeat: resumeAtBeat)

            } catch {
                let maxAttempts = 20
                let retryDelay = 0.5

                guard attempt < maxAttempts else {
                    self.pendingResume = true
                    self.pendingResumeBeat = nil
                    os_log("[Q-BEATS][RESUME] setActive esaurito — pendingResume=true beat:%.4f trigger:%{public}@",
                           log: .default, type: .default, resumeAtBeat ?? -1.0, trigger)

                    // Safety net a 5 secondi (non 3)
                    self.audioQueue.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                        guard let self = self else { return }
                        guard self.pendingResume,
                              self.currentResumeToken == activeToken else {
                            os_log("[Q-BEATS][RESUME] Safety net annullato — token cambiato o pendingResume cleared",
                                   log: .default, type: .default)
                            return
                        }
                        self.pendingResume = false
                        self.pendingResumeBeat = nil
                        self.activateSessionAndStart(
                            resumeAtBeat: resumeAtBeat,
                            trigger: "safety_net",
                            attempt: 1,
                            token: activeToken
                        )
                    }
                    return
                }

                os_log("[Q-BEATS][RESUME] retry attempt %d/20 in 500ms (token:%d)",
                       log: .default, type: .default, attempt + 1, activeToken)

                self.audioQueue.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                    self?.activateSessionAndStart(
                        resumeAtBeat: resumeAtBeat,
                        trigger: trigger,
                        attempt: attempt + 1,
                        token: activeToken
                    )
                }
            }
        }
    }

    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
            // Sequenza iOS obbligatoria: setCategory → setPreferredOutputNumberOfChannels → setActive
            configureSessionChannels(for: detectAudioMode())
            try session.setActive(true)
            sampleRate = AVAudioSession.sharedInstance().sampleRate
            if let mh = metronomeHandle {
                metronome_set_sample_rate(mh, sampleRate)
            }
            // Task D refactor #18 — propaga sampleRate al pending atomic
            // (sink block lo legge per calcolo offset hostTime sample-accurate).
            qbeats_link_pending_set_sample_rate(self.linkPending, sampleRate)
            os_log("QA-3 sampleRate aggiornato: %{public}.1f", log: .default, type: .default, sampleRate)
        } catch {
            DispatchQueue.main.async { self.clickStatus = "session fallita: \(error)" }
        }
    }

    private func setupGraph() {
        self.sampleRate = AVAudioSession.sharedInstance().sampleRate
        // Task D refactor #18 — propaga sampleRate al pending atomic.
        qbeats_link_pending_set_sample_rate(self.linkPending, self.sampleRate)
        let detectedMode = detectAudioMode()
        DispatchQueue.main.async {
            self.audioMode = detectedMode
            self.sampleRateInfo = self.sampleRate
        }
        os_log("setupGraph sampleRate=%.1f audioMode=%{public}@",
               log: .default, type: .default,
               self.sampleRate, "\(detectedMode)")

        engine.attach(playerNode)
        engine.attach(backtrackPlayerNode)
        engine.attach(ch3PlayerNode)
        engine.attach(ch4PlayerNode)
        engine.attach(ch1MixerNode)
        engine.attach(ch2MixerNode)
        engine.attach(ch3MixerNode)
        engine.attach(ch4MixerNode)
        connectAllNodes(for: detectedMode)
        // === Task D refactor #18c — installTap su mainMixerNode ===
        // Sostituisce engine.attach(linkSinkNode) di refactor #18.
        // Il tap richiede mainMixerNode presente nel graph (connectAllNodes
        // lo configura). Idempotente — vedi installLinkTap().
        installLinkTap()
        applyChannelRouting(for: detectedMode)
    }

    /// Costruisce la topologia del grafo AVAudioEngine in base alla modalità hardware.
    /// Base: tutti i mixer al mainMixerNode (stereo). Ch3/Ch4 silenziate via outputVolume.
    /// Pro:  connessione diretta a outputNode su bus fisici separati.
    ///       Guard su maximumOutputNumberOfChannels — se l'hardware non supporta 4 canali,
    ///       fallback automatico a topologia Base con log di errore.
    /// Chiamare solo con engine fermo.
    private func connectAllNodes(for mode: AudioMode) {
        let monoFormat   = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Player → ch1Mixer (singola destination, identico in Base e Pro)
        // === Task D refactor #18c ===
        // Multi-destination [ch1Mixer, linkSinkNode] di refactor #18 era
        // architetturalmente corretto ma AVAudioEngine non onorava il sink
        // come secondo consumer (sink block mai invocato — diagnosi #18b).
        // Sostituito da installTap su mainMixerNode (vedi installLinkTap).
        engine.connect(playerNode, to: ch1MixerNode, format: monoFormat)
        engine.connect(backtrackPlayerNode, to: ch2MixerNode, format: nil)
        engine.connect(ch3PlayerNode,       to: ch3MixerNode, format: nil)
        engine.connect(ch4PlayerNode,       to: ch4MixerNode, format: nil)

        ch1MixerNode.outputVolume = ch1Volume
        ch2MixerNode.outputVolume = ch2Volume
        ch3MixerNode.outputVolume = ch3Volume
        ch4MixerNode.outputVolume = ch4Volume

        switch mode {
        case .base:
            engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: monoFormat)
            engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            os_log("connectAllNodes: topologia BASE",
                   log: .default, type: .default)

        case .pro:
            // Formato reale dell'outputNode — disponibile SOLO dopo setActive(true).
            // Questo metodo viene chiamato da rebuildGraph() che è chiamato
            // dentro activateSessionAndStart dopo setActive OK — mai prima.
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            let outputChannels = outputFormat.channelCount

            guard outputChannels >= 4 else {
                os_log("connectAllNodes: Pro richiesto ma outputChannels=%d < 4 — fallback Base",
                       log: .default, type: .error, outputChannels)
                engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: monoFormat)
                engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                return
            }

            // Connessione esplicita mainMixerNode → outputNode con formato 4ch.
            // Senza questa connessione esplicita il channelMap non è efficace.
            // Fonte: Apple Developer Forums thread/713983.
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)

            // Ogni ch mixer → mainMixerNode con outputFormat (4ch).
            // Necessario per attivare il channelMap — con formato mono non funziona.
            engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: outputFormat)

            // channelMap: [NSNumber] — indice = canale output 4ch, valore = canale input (-1 = silenzio).
            ch1MixerNode.auAudioUnit.channelMap = [0, -1, -1, -1]   // click → out 0
            ch2MixerNode.auAudioUnit.channelMap = [-1, 0, -1, -1]   // backtrack → out 1
            ch3MixerNode.auAudioUnit.channelMap = [-1, -1, 0, -1]   // guide vocals → out 2
            ch4MixerNode.auAudioUnit.channelMap = [-1, -1, -1, 0]   // FX → out 3

            os_log("connectAllNodes: topologia PRO — channelMap attivo (outputChannels:%d SR:%.0f)",
                   log: .default, type: .default,
                   outputChannels, outputFormat.sampleRate)
        }
    }

    /// Ricostruisce il grafo: disconnette tutti i nodi, riconnette per la modalità
    /// indicata, prepara l'engine.
    /// Chiamare solo con engine e playerNode già fermi.
    private func rebuildGraph(for mode: AudioMode) {
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(backtrackPlayerNode)
        engine.disconnectNodeOutput(ch3PlayerNode)
        engine.disconnectNodeOutput(ch4PlayerNode)
        engine.disconnectNodeOutput(ch1MixerNode)
        engine.disconnectNodeOutput(ch2MixerNode)
        engine.disconnectNodeOutput(ch3MixerNode)
        engine.disconnectNodeOutput(ch4MixerNode)
        connectAllNodes(for: mode)
        // === Task D refactor #18c — re-install tap dopo rebuild ===
        // disconnectNodeOutput non rimuove il tap installato su mainMixerNode,
        // ma per safety reinstalliamo (idempotente: removeTap precede installTap).
        installLinkTap()
        engine.prepare()
        os_log("rebuildGraph completato — mode: %{public}@",
               log: .default, type: .default, "\(mode)")
    }

    // === Task D refactor #18c — installTap su mainMixerNode ===
    // Sostituisce AVAudioSinkNode (refactor #18) che non veniva mai
    // invocato come secondo consumer multi-destination di playerNode.
    //
    // installTap su mainMixerNode opera con priorita' RT equivalente al
    // rendering AVAudioEngine (NON e' il "vero" render thread Core Audio
    // in senso stretto, ma scheduling RT garantito ad ogni render del
    // mainMixer — sempre attivo durante engine running).
    //
    // Le API ABLLink AudioSessionState (Capture/Commit) sono LOCKFREE
    // per design: compatibili con thread RT secondo doc Ableton ABLLink.h.
    //
    // Vincoli del block (identici al sink originario):
    // - niente self / weak / class Swift (no ARC)
    // - niente ObjC messaging
    // - niente lock / I/O
    // - solo C function su atomic + ABLLink Audio*SessionState (lockfree)
    //
    // Cattura esplicita:
    // - opaque C pointers (pendingPtr, handle) — stabili per lifecycle
    // - scalar primitive (tbNumer, tbDenom) — let immutabili
    //
    // Idempotente: removeTap precede installTap per sopravvivere a
    // rebuildGraph (cambio modalita' Base/Pro).
    private func installLinkTap() {
        engine.mainMixerNode.removeTap(onBus: 0)

        let pendingPtr: OpaquePointer = self.linkPending
        let handle: LinkEngineHandle? = self.linkEngineHandle
        let tbNumer: UInt32 = self.machTimebase.numer
        let tbDenom: UInt32 = self.machTimebase.denom

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 512, format: nil) { _, when in
            // Tap block — priorita' RT equivalente al rendering AVAudioEngine.
            // Vincoli: no self/weak/class, no ObjC msg, no lock, no I/O.
            // ABLLink Audio*SessionState lockfree → compatibili con thread RT.
            let renderBufferId = qbeats_link_pending_increment_render_buffer(pendingPtr)

            if renderBufferId % 1024 == 0 {
                os_log("[Q-BEATS][SinkDiag-RT] heartbeat — renderBufferId:%llu",
                       log: .default, type: .default, renderBufferId)
            }

            // Calibrazione delta sched-render (one-shot self-correcting)
            if qbeats_link_pending_get_delta(pendingPtr) == 0 {
                let schedNow = qbeats_link_pending_get_sched_buffer_count(pendingPtr)
                if schedNow > 0 {
                    let delta = Int64(schedNow) - Int64(renderBufferId)
                    if delta > 0 {
                        qbeats_link_pending_set_delta(pendingPtr, delta)
                    }
                }
            }

            // === DISABLED — broadcast moved to scheduleNextBuffer beat callback ===
            // Il design del match buffer-id (sched ~100/s vs render ~10/s) non regge
            // l'asimmetria reale: il match `renderBufferId == targetBufferId` non
            // scatta nei tempi del target (verifica Step 1A, sessione 15/05/2026).
            // Broadcast Link ora parte da audioQueue — vedi commento "Step 2 —
            // broadcast Link da audioQueue" nel beat callback di scheduleNextBuffer.
            // Codice mantenuto visibile per reference durante validazione; pulizia
            // definitiva in commit separato post-device verde.
            /*
            // Arming check + apply al sample-accurate del downbeat
            if qbeats_link_pending_load_scheduled(pendingPtr) {
                let targetBufferId = qbeats_link_pending_load_buffer_id(pendingPtr)
                if renderBufferId == targetBufferId {
                    let bpm = qbeats_link_pending_load_bpm(pendingPtr)
                    let sampleOffset = qbeats_link_pending_load_sample_offset(pendingPtr)
                    let sampleRate = qbeats_link_pending_load_sample_rate(pendingPtr)
                    // hostTime preciso del sample del downbeat:
                    //   when.hostTime + offset_in_buffer in ticks
                    let nanosOffset = Double(sampleOffset) / sampleRate * 1.0e9
                    let ticksOffset = UInt64(nanosOffset * Double(tbDenom) / Double(tbNumer))
                    let hostTime = when.hostTime + ticksOffset
                    if let h = handle {
                        let nowAtSink = mach_absolute_time()
                        os_log("[Q-BEATS][SinkSync] broadcast — bpm:%.1f renderBufferId:%llu when.hostTime:%llu ticksOffset:%llu hostTime:%llu deltaFromNow:%lld",
                               log: .default, type: .default,
                               bpm, renderBufferId, when.hostTime, ticksOffset, hostTime,
                               Int64(hostTime) - Int64(nowAtSink))
                        link_engine_set_bpm_audio_thread(h, bpm, hostTime)
                    }
                    qbeats_link_pending_clear_scheduled(pendingPtr)
                }
            }
            */
        }
    }

    // MARK: - Fase 1.5a — Hardware Detection

    private func detectAudioMode() -> AudioMode {
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .usbAudio && (output.channels?.count ?? 0) > 2 {
                return .pro
            }
        }
        return .base
    }

    /// Imposta il numero di canali output preferiti su AVAudioSession.
    /// Chiamare DOPO setCategory e PRIMA di setActive — invariante iOS.
    /// Non throwing: errore loggato, non propagato.
    private func configureSessionChannels(for mode: AudioMode) {
        let session = AVAudioSession.sharedInstance()
        do {
            switch mode {
            case .pro:
                try session.setPreferredOutputNumberOfChannels(4)
                os_log("configureSessionChannels: Pro — 4 canali richiesti (max hardware: %d)",
                       log: .default, type: .default,
                       session.maximumOutputNumberOfChannels)
            case .base:
                try session.setPreferredOutputNumberOfChannels(2)
                os_log("configureSessionChannels: Base — 2 canali",
                       log: .default, type: .default)
            }
        } catch {
            os_log("configureSessionChannels error: %{public}@",
                   log: .default, type: .error, error.localizedDescription)
        }
    }

    private func applyChannelRouting(for mode: AudioMode) {
        switch mode {
        case .base:
            ch1MixerNode.pan = -1.0
            ch2MixerNode.pan =  1.0
            ch3MixerNode.outputVolume = 0.0
            ch4MixerNode.outputVolume = 0.0
            os_log("routing BASE: Ch1 pan L, Ch2 pan R, Ch3/Ch4 muted",
                   log: .default, type: .default)
        case .pro:
            ch1MixerNode.pan = 0.0
            ch2MixerNode.pan = 0.0
            ch3MixerNode.outputVolume = ch3Volume
            ch4MixerNode.outputVolume = ch4Volume
            os_log("routing PRO: Ch1-Ch4 active, pan center",
                   log: .default, type: .default)
        }
    }

    // Genera click sintetico alla frequenza indicata.
    // Chiamare SOLO su audioQueue.
    private func generateClickSamples(frequency: Double) -> [Float] {
        let freq       : Float = Float(frequency)
        let durationMs : Float = 40.0
        let frameCount = Int(Float(sampleRate) * durationMs / 1000.0)
        let decayRate  : Float = 80.0
        var samples = [Float](repeating: 0.0, count: frameCount)
        for i in 0..<frameCount {
            let t        = Float(i) / Float(sampleRate)
            let envelope = expf(-decayRate * t)
            samples[i]   = sinf(2.0 * Float.pi * freq * t) * envelope * 0.8
        }
        return samples
    }

    // === AGGIUNTO 6C ===
    // Converte secondi in mach ticks usando timebase cachata.
    // Chiamabile da qualsiasi thread.
    private func secondsToMachTicks(_ seconds: Double) -> UInt64 {
        guard seconds > 0, machTimebase.numer > 0 else { return 0 }
        let nanos = seconds * 1_000_000_000.0
        return UInt64(nanos) * UInt64(machTimebase.denom) / UInt64(machTimebase.numer)
    }

    private func machTicksToSeconds(_ ticks: UInt64) -> Double {
        guard machTimebase.denom > 0 else { return 0.0 }
        let nanos = Double(ticks) * Double(machTimebase.numer) / Double(machTimebase.denom)
        return nanos / 1_000_000_000.0
    }

    // === Fix #4 — vero hostTime di output del prossimo buffer ===
    // playerNode.lastRenderTime è hardware-accurate, ancorato al clock audio
    // del sistema, non a mach_absolute_time(). Indica l'orario in cui
    // l'ULTIMO buffer è stato renderizzato. Il buffer corrente (quello in
    // scheduleNextBuffer) sarà renderizzato ~bufferDuration dopo, e l'output
    // udibile arriva ~outputLatency dopo il rendering.
    //
    // Il fallback (now + outputLatency + bufferDuration) sottostima di
    // ~15ms perché non include il pre-roll AVAudioPlayerNode (1-2 buffer
    // in coda). Verificato 12/05/2026 da test su device: SB anticipava di
    // ~15ms = 0.035 beat a 140 BPM. Sotto soglia DIRECTOR-ASSERT 0.04 →
    // nessuna correzione automatica, ma percettibile all'orecchio.
    //
    // Chiamabile da audioQueue.
    private func nextBufferOutputHostTime() -> UInt64 {
        let now = mach_absolute_time()
        if let renderTime = self.playerNode.lastRenderTime,
           renderTime.isHostTimeValid {
            let result = renderTime.hostTime
                       + self.bufferDurationTicks
                       + self.outputLatencyTicks
            os_log("[Q-BEATS][L1bSync] nextBufferOutputHostTime HARDWARE — lastRender:%llu now:%llu bufDur:%llu outLat:%llu result:%llu deltaFromNow:%lld",
                   log: .default, type: .default,
                   renderTime.hostTime, now, self.bufferDurationTicks, self.outputLatencyTicks,
                   result, Int64(result) - Int64(now))
            return result
        }
        // Fallback: playerNode non running, oppure hostTime non valido.
        // Errore residuo come fix #3 (~15ms sottostimato).
        let fallback = now + self.outputLatencyTicks + self.bufferDurationTicks
        os_log("[Q-BEATS][L1bSync] nextBufferOutputHostTime FALLBACK — lastRender:nil-or-invalid now:%llu bufDur:%llu outLat:%llu result:%llu deltaFromNow:%lld",
               log: .default, type: .default,
               now, self.bufferDurationTicks, self.outputLatencyTicks,
               fallback, Int64(fallback) - Int64(now))
        return fallback
    }

    // Chiamare SOLO su audioQueue.
    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }

        // === Task D refactor #18 — esponi bufferCount al render thread ===
        // Atomic snapshot del bufferCount audioQueue. Il sink block lo legge
        // per calibrare delta = sched - render al primo invocation. Pattern
        // self-calibrating, no modifica Layer 1.
        qbeats_link_pending_set_sched_buffer_count(self.linkPending,
                                                    UInt64(self.bufferCount))

        // === L1.a — Drain mode check ===
        // Se in drain (sezione finita) e tutti i playhead sono esauriti, il
        // click è stato riprodotto integralmente: dispatch closure stop ora.
        // Sample-accurate: il completion handler dell'ultimo buffer ci ha
        // svegliato esattamente quando l'audio era esaurito.
        if self._sectionEndPending
            && self.clickPlayhead < 0
            && self.accentPlayhead < 0
            && self.subdivPlayhead < 0 {
            os_log("[Q-BEATS][DRAIN] entered — bufCount:%d beatTick:%d",
                   log: .default, type: .default,
                   self.bufferCount, self.beatTickCounter)
            self._sectionEndPending = false
            let endClosure = self._pendingEndClosure
            self._pendingEndClosure = nil
            let renderInfo: String
            if let rt = self.playerNode.lastRenderTime, rt.isHostTimeValid {
                renderInfo = "valid hostTime=\(rt.hostTime)"
            } else {
                renderInfo = "INVALID"
            }
            os_log("[Q-BEATS][L1bSync] drain completato → onSectionEnd dispatch — lastRenderTime:%{public}@",
                   log: .default, type: .default,
                   renderInfo)
            // TD #16: l'engine NON emette più sectionEndedSubject. Limita
            // l'azione a dispatch della closure end-of-section registrata
            // dal callsite (DebugView in L1.a, Layer 3 in L1.b). È il
            // callsite a decidere se emettere il subject prima di stop()
            // — solo quando si tratta di fine vera della performance, non
            // di transizione fra sezioni intermedie.
            DispatchQueue.main.async { [weak self] in
                endClosure?()
            }
            os_log("[Q-BEATS][DRAIN] return — no buffer scheduled to playerNode",
                   log: .default, type: .default)
            return
        }

        // === Task D fix #1 pre-apply RIMOSSO (refactor #18) ===
        // Il pre-apply non conosceva l'offset del downbeat nel buffer
        // (metronome_processBuffer non ancora chiamato). L'arming pending
        // audio-thread richiede l'offset preciso, che è disponibile SOLO
        // nel beat callback DOPO metronome_processBuffer (vedi loop beat
        // più sotto). L'arming è ora unificato nel beat callback.

        if bufferCount == 0 || bufferCount % 100 == 0 {
            os_log("[Q-BEATS][SCHED] bufCount:%d hardwareSR:%.0f nodeSR:%.0f",
                   log: .default, type: .default,
                   bufferCount, AVAudioSession.sharedInstance().sampleRate, self.sampleRate)
        }
        if let mh = midiEngineHandle {
            midi_engine_sync_clock(mh,
                UInt64(bufferCount) * UInt64(bufferSize),
                mach_absolute_time(),
                sampleRate)
            // === Phase sync Link (Phase Correction Policy v1.2) + diagnostica restart ===
            if let lh = linkEngineHandle, let mh = midiEngineHandle {
                let hostTimeAtOutput = mach_absolute_time()
                                     + outputLatencyTicks
                                     + bufferDurationTicks
                let currentBeat = midi_engine_get_beat_position(mh)
                var newBeat: Double = 0.0
                if self.linkSyncSkipBuffers > 0 {
                    self.linkSyncSkipBuffers -= 1
                    os_log("[Q-BEATS][LINK] sync skip — buffer rimanenti:%d",
                           log: .default, type: .default, self.linkSyncSkipBuffers)
                } else if _linkMode == .direttore {
                    // Modalità Direttore in play (siamo dentro scheduleNextBuffer,
                    // quindi isRunning è già garantito true dal guard a riga 1359).
                    // Q-BEATS impone BPM e fase al session state in un singolo
                    // capture/commit atomico — vedi rationale in
                    // link_engine_assert_session_state. Risolve il drift di fase
                    // post-deviazione peer (test D2, build #333).
                    if self._linkSyncLogBuffers > 0 {
                        self._linkSyncLogBuffers -= 1
                        os_log("[Q-BEATS][AssertSync] hostTimeAtOutput:%llu audioBPM:%.1f beatTick:%d",
                               log: .default, type: .default,
                               hostTimeAtOutput, self._audioBPM, self.beatTickCounter)
                    }
                    link_engine_assert_session_state(lh, hostTimeAtOutput,
                                                    currentBeat, _audioBPM)
                } else if link_engine_sync_phase(lh, hostTimeAtOutput, currentBeat, &newBeat) {
                    midi_engine_set_beat_position(mh, newBeat)
                    // Bug 2.b — solo timeline a campioni: la fase di battuta resta
                    // governata dal contatore di sezione (no riscrittura _currentBeatInBar).
                    metronome_set_beat_position_time_only(h, newBeat)
                    os_log("[Q-BEATS][LINK] Phase sync: %.4f → %.4f beats",
                           log: .default, type: .default,
                           currentBeat, newBeat)
                    DispatchQueue.main.async { [weak self] in
                        self?.currentBeat = newBeat
                    }
                    if bufferCount <= 2 {
                        os_log("[Q-BEATS][LINK][RESTART] buffer #%d: correction %.4f → %.4f (delta=%.4f)",
                               log: .default, type: .default,
                               bufferCount, currentBeat, newBeat, newBeat - currentBeat)
                    }
                } else if bufferCount <= 2 {
                    os_log("[Q-BEATS][LINK][RESTART] buffer #%d: beat=%.4f — no correction",
                           log: .default, type: .default,
                           bufferCount, currentBeat)
                }
            }

            midi_engine_process(mh, UInt32(bufferSize))
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        guard let dst = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(bufferSize) { dst[i] = 0.0 }

        // === L1.a — Drain mode: skip metronome_processBuffer ===
        // Durante il drain non chiediamo nuovi beat events al motore C++:
        // questo evita che vengano generati click "fantasma" in attesa che
        // il drain finisca. I playhead esistenti (clickPlayhead/accent/subdiv)
        // continuano comunque a essere drenati nel buffer corrente sotto.
        let beatCount: UInt32
        if self._sectionEndPending {
            beatCount = 0
        } else {
            beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, &accents, &isBeats, UInt32(maxBeats))
        }
        bufferCount += 1
        beatTotal   += Int(beatCount)

        let muteGain: Float = self._clickMuted ? 0.0 : 1.0

        if clickPlayhead >= 0 && !clickSamples.isEmpty {
            let remaining = clickSamples.count - clickPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(beatVolume) * muteGain
            for j in 0..<writeLen { dst[j] += clickSamples[clickPlayhead + j] * gain }
            clickPlayhead += writeLen
            if clickPlayhead >= clickSamples.count { clickPlayhead = -1 }
        }

        if accentPlayhead >= 0 && !accentedClickSamples.isEmpty {
            let remaining = accentedClickSamples.count - accentPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(accentVolume) * muteGain
            for j in 0..<writeLen { dst[j] += accentedClickSamples[accentPlayhead + j] * gain }
            accentPlayhead += writeLen
            if accentPlayhead >= accentedClickSamples.count { accentPlayhead = -1 }
        }

        if subdivPlayhead >= 0 && !subdivisionClickSamples.isEmpty {
            let remaining = subdivisionClickSamples.count - subdivPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(subdivVolume) * muteGain
            for j in 0..<writeLen { dst[j] += subdivisionClickSamples[subdivPlayhead + j] * gain }
            subdivPlayhead += writeLen
            if subdivPlayhead >= subdivisionClickSamples.count { subdivPlayhead = -1 }
        }

        if beatCount > 0 {
            if let mh = midiEngineHandle {
                let currentBeatNow = midi_engine_get_beat_position(mh)
                DispatchQueue.main.async { [weak self] in
                    self?.currentBeat = currentBeatNow
                }
            }
            for i in 0..<Int(beatCount) {
                let offset   = Int(offsets[i])
                let isAccent = accents[i]  != 0
                let isBeat   = isBeats[i]  != 0

                if isBeat {
                    self.beatTickCounter += 1
                    let tickN = self.beatTickCounter
                    DispatchQueue.main.async { [weak self] in
                        self?.beatTickSubject.send(tickN)
                    }

#if QB_DIAG_SPY
                    // SPIA passiva L3 — per OGNI beat: asse CONTATORE + riferimento griglia
                    // (gridBeat = engine beat, sincronizzato a Link). Campi GREZZI: la fase
                    // derivata round(gridBeat − sectionStartMarker) % bpbQ si calcola al FLUSH.
                    // L'asse ACCENTO (_currentBeatInBar) arriva dal ring L1 (join beatTick↔seq).
                    if let mhSpy = self.midiEngineHandle {
                        let gridBeat = midi_engine_get_beat_position(mhSpy)
                        if self._spyMarkerPending {
                            self._spySectionStartMarker = gridBeat   // SOLA LETTURA, marker passivo
                            self._spyMarkerPending = false
                        }
                        os_log("[Q-BEATS][Bug2b-SPY-L3] beatTick:%d sectionBeatCounter:%d sectionInstance:%d bpbQ:%u gridBeat:%.4f sectionStartMarker:%.4f offset:%d",
                               log: .default, type: .default,
                               self.beatTickCounter, self._sectionBeatCounter,
                               self._spySectionInstanceIdx, self._beatsPerBarQ,
                               gridBeat, self._spySectionStartMarker, offset)
                    }
#endif

                    if self.beatTickCounter % 32 == 0 {
                        let sinkCount = qbeats_link_pending_get_render_buffer_id(self.linkPending)
                        os_log("[Q-BEATS][SinkDiag-AQ] relay — renderBufferId:%llu beatTick:%d",
                               log: .default, type: .default, sinkCount, self.beatTickCounter)
                    }

                    // === Task D — Propagazione BPM al downbeat target (refactor #18) ===
                    // Il DSP C++ ha appena applicato _pendingBPM a _bpm
                    // (atomic exchange in processBuffer, sample-accurate a
                    // _currentBeatInBar==0). Ora propaghiamo:
                    //   1. _audioBPM mirror (Nota 1 referee — PRIMA di tutto: il
                    //      render thread può leggere il pending tra qui e l'arming,
                    //      _audioBPM deve già contenere il nuovo valore per il
                    //      Direttore re-broadcast del tempo callback Link)
                    //   2. MIDI engine re-anchor (Strada E fix #2 invariato)
                    //   3. Branch esplicito audio-thread vs fallback warm-up
                    //      (Nota 3 referee — niente silent no-op)
                    //   4. UI dispatch
                    if let pending = self._pendingBPMValue,
                       self.beatTickCounter == self._pendingBPMTargetTick {
                        // [Nota 1] _audioBPM PRIMA di tutto
                        self._audioBPM = pending
                        // L1.b sync investigation — abilita log DIRECTOR-ASSERT per 3 buffer
                        self._linkSyncLogBuffers = 3

                        // MIDI re-anchor (Strada E fix #2 invariato)
                        if let mh = self.midiEngineHandle {
                            let preChangeBeatPos = midi_engine_get_beat_position(mh)
                            midi_engine_set_bpm(mh, pending)
                            midi_engine_set_beat_position(mh, preChangeBeatPos)
                        }

                        // === Step 2 — broadcast Link da audioQueue ===
                        // Il path tap broadcast è disattivato (vedi installLinkTap):
                        // il design del delta non regge l'asimmetria sched-vs-render
                        // rate (~100/s vs ~10/s in pratica), il match buffer-id non
                        // scatta mai. Broadcast diretto qui, single-threaded, con
                        // hostTime sample-accurate = nextBufferOutputHostTime +
                        // ticksOffset del downbeat dentro il buffer.
                        // === Step 4 (15/05/2026) — broadcast atomic tempo + fase ===
                        // Sostituisce link_engine_set_bpm_at_time (solo tempo) con
                        // link_engine_set_bpm_and_beat_at_time (tempo + fase nello
                        // stesso session commit). Risolve drift sistemico 0.02-0.09
                        // beat ai cambi BPM (test L2.b 15/05/2026 sera, riprodotto
                        // su Tick e Metronome Pro, numeri identici entro 20%).
                        if let lh = self.linkEngineHandle, let mh = self.midiEngineHandle {
                            let sampleOffset = UInt32(offset)
                            let nanosOffset = Double(sampleOffset) / self.sampleRate * 1.0e9
                            let ticksOffset = UInt64(nanosOffset * Double(self.machTimebase.denom) / Double(self.machTimebase.numer))
                            // Step 2.5 — pre-roll AVAudioPlayerNode: ~2 buffer in coda davanti
                            // al buffer che stiamo riempiendo (pre-roll iniziale 3 buffer
                            // righe 586-588 + completion handler scheduleNextBuffer mantengono
                            // steady-state ~2 in coda). nextBufferOutputHostTime punta al
                            // prossimo buffer da renderizzare; il nostro è dietro di preRollTicks.
                            let preRollTicks = 2 * self.bufferDurationTicks
                            let hostTime = self.nextBufferOutputHostTime() + preRollTicks + ticksOffset
                            let currentBeat = midi_engine_get_beat_position(mh)
                            link_engine_set_bpm_and_beat_at_time(lh, pending, currentBeat, hostTime)
                            os_log("[Q-BEATS][TaskD-AQ] broadcast — bpm:%.1f beatNow:%.4f sampleOffset:%d ticksOffset:%llu preRollTicks:%llu bufDurTicks:%llu hostTime:%llu",
                                   log: .default, type: .default,
                                   pending, currentBeat, sampleOffset, ticksOffset, preRollTicks, self.bufferDurationTicks, hostTime)
                        }

                        // UI dispatch (invariato)
                        let valueForMain = pending
                        DispatchQueue.main.async { [weak self] in
                            self?.currentBPM = valueForMain
                        }

                        // Reset stato pending Swift
                        self._pendingBPMValue = nil
                        self._pendingBPMTargetTick = 0
                    }

                    // QA-1 drift analysis — eseguito su audioQueue
                    if self.qa1BeatCounter == 0 {
                        self.qa1StartTime = mach_absolute_time()
                    }
                    self.qa1BeatCounter += 1

                    if self.qa1BeatCounter % 100 == 0 {
                        let elapsed = self.machTicksToSeconds(mach_absolute_time() - self.qa1StartTime)
                        let expected = Double(self.qa1BeatCounter - 1) * 60.0 / self.currentBPM
                        let deltams = (elapsed - expected) * 1000.0
                        os_log("QA1 beat=%{public}llu expected=%.3fs elapsed=%.3fs delta=%{public}.2fms",
                               log: .default, type: .default,
                               self.qa1BeatCounter, expected, elapsed, deltams)
                    }

                    // === L1.a — Stop a fine ultima ripetizione (drain-based) ===
                    // _sectionTotalBeats > 0 → sezione con limite caricata via loadSection.
                    // Incremento contatore + check fine. NESSUN dispatch immediato:
                    // settare _sectionEndPending attiva il drain mode, che skippa
                    // metronome_processBuffer (no beat fantasma) e drena clickPlayhead
                    // residuo nei buffer successivi. Quando tutti i playhead sono
                    // esauriti (controllo all'inizio di scheduleNextBuffer), il
                    // dispatch della closure arriva sample-accurate.
                    if self._sectionTotalBeats > 0 {
                        self._sectionBeatCounter += 1
                        if self._sectionBeatCounter >= self._sectionTotalBeats {
                            // Strada A — Distingue ramo SEAMLESS (transizione
                            // intra-canzone con preload) da ramo DRAIN
                            // (standby / fineSetlist).
                            if self._pendingNextSectionTotalBeats != nil {
                                // === RAMO SEAMLESS ===
                                os_log("[Q-BEATS][SEAMLESS] fine sezione — swap atomico (Strada A)",
                                       log: .default, type: .default)

                                // (a) Cattura locali — prima di qualsiasi reset.
                                let closureToDispatch    = self._onSectionEnd
                                let pendingBPB           = self._pendingNextBPB!
                                let pendingBPM           = self._pendingNextBPM!
                                let pendingAccentPattern = self._pendingNextAccentPattern!
                                let pendingTotalBeats    = self._pendingNextSectionTotalBeats!
                                let pendingOnSectionEnd  = self._pendingNextOnSectionEnd
                                let pendingRepetitions   = self._pendingNextRepetitions!

                                // (b) Reset _pendingNext* (safe — locali già catturati).
                                self._pendingNextBPB = nil
                                self._pendingNextBPM = nil
                                self._pendingNextAccentPattern = nil
                                self._pendingNextSectionTotalBeats = nil
                                self._pendingNextOnSectionEnd = nil
                                self._pendingNextRepetitions = nil

                                // (c) Swap contatori Swift.
                                // _sectionEndPending resta false — il ramo SEAMLESS
                                // non entra mai in drain mode.
                                // _audioBPM assegnato presto per coerenza col bypass
                                // DIRECTOR-ASSERT via linkSyncSkipBuffers (step f).
                                self._sectionTotalBeats = pendingTotalBeats
                                self._sectionBeatCounter = 0
                                self._onSectionEnd = pendingOnSectionEnd
                                self._beatsPerBarQ = pendingBPB
                                self._audioBPM = pendingBPM

#if QB_DIAG_SPY
                                // SPIA passiva: nuova sezione → ri-cattura il marker griglia
                                // al 1° beat della sezione e incrementa l'indice di sezione.
                                self._spySectionInstanceIdx += 1
                                self._spyMarkerPending = true
#endif

                                // (d) Arm DSP Layer 1 — atomic exchange al downbeat
                                // di transizione. Conversione accent UI→DSP:
                                // UI usa 2=accent, 1=beat, 0=subdiv;
                                // DSP usa 1=accent, 0=beat (no subdiv).
                                let dspPattern: [UInt8] = pendingAccentPattern.map {
                                    $0 == 2 ? UInt8(1) : UInt8(0)
                                }
                                metronome_schedule_bpb_change(h, pendingBPB)
                                dspPattern.withUnsafeBufferPointer { ptr in
                                    metronome_schedule_accent_pattern_change(
                                        h, ptr.baseAddress, UInt32(dspPattern.count))
                                }
                                metronome_schedule_bpm_change(h, pendingBPM)

                                // (e) Arm Link — quantum aggiornato per il nuovo BPB.
                                if let lh = self.linkEngineHandle {
                                    link_engine_set_quantum(lh, Double(pendingBPB))
                                }

                                // (f) Disabilita DIRECTOR-ASSERT per 100 buffer (~1s)
                                // durante la transizione, coerente con scheduleBPMChange.
                                self.linkSyncSkipBuffers = max(self.linkSyncSkipBuffers, 100)

                                // (g) Arm Swift BPM — il broadcast Link/MIDI/UI
                                // al downbeat target viene fatto al prossimo beat
                                // (dal blocco "if let pending = self._pendingBPMValue"
                                // più sopra in questo stesso loop, alla prossima
                                // invocazione di scheduleNextBuffer).
                                self._pendingBPMValue = pendingBPM
                                self._pendingBPMTargetTick = self.beatTickCounter + 1

                                // (h) Dispatch @Published su main.
                                // Invariante architetturale: in Studio non esistono
                                // _pendingNext* armati (niente setlist), quindi
                                // _suppressBeatsPerBarDidSet non viene mai settato.
                                // In Live la UI Studio non è accessibile.
                                // Nessun conflitto possibile.
                                DispatchQueue.main.async { [weak self] in
                                    guard let self else { return }
                                    self._suppressBeatsPerBarDidSet = true
                                    self.beatsPerBar = pendingBPB
                                    self.currentAccentPattern = pendingAccentPattern
                                    self.currentSectionRepetitions = pendingRepetitions
                                }

                                // (i) Dispatch closure SetlistRunner su main.
                                // Se stopSync arriva tra lo swap (audioQueue) e
                                // questo dispatch, la closure può eseguire dopo lo
                                // stop — gli effetti vengono usati al resume o
                                // sovrascritti al restart (vedi tech debt OSS2
                                // su epoch counter, fix post-validazione device).
                                DispatchQueue.main.async {
                                    closureToDispatch?()
                                }

                            } else {
                                // === RAMO DRAIN (invariato) — standby / fineSetlist ===
                                os_log("[Q-BEATS][L1.a] fine ultima ripetizione — beat:%d/%d → drain mode",
                                       log: .default, type: .default,
                                       self._sectionBeatCounter, self._sectionTotalBeats)
                                // Salva closure corrente per dispatch a fine drain.
                                // _sectionTotalBeats e _onSectionEnd RESTANO registrati:
                                // la sezione caricata persiste tra play/replay (utente
                                // ascolta sezione 4 battute → stop automatico → ripreme
                                // Play → si aspetta che la stessa sezione ricominci).
                                // Solo _sectionBeatCounter va azzerato per il replay.
                                // Niente double-fire durante il drain: metronome_processBuffer
                                // skippato → beatCount=0 → hook non scatta.
                                self._pendingEndClosure = self._onSectionEnd
                                self._sectionEndPending = true
                                self._sectionBeatCounter = 0
                            }
                        }
                    }
                }

                let samples: [Float]
                let gain: Float
                if isAccent    { samples = accentedClickSamples; gain = Float(accentVolume) * muteGain }
                else if isBeat { samples = clickSamples; gain = Float(beatVolume) * muteGain }
                else           { samples = subdivisionClickSamples; gain = Float(subdivVolume) * muteGain }
                guard offset < Int(bufferSize), !samples.isEmpty else { continue }
                let writeLen = min(samples.count, Int(bufferSize) - offset)
                for j in 0..<writeLen { dst[offset + j] += samples[j] * gain }
                if writeLen < samples.count {
                    if isAccent    { accentPlayhead = writeLen }
                    else if isBeat { clickPlayhead  = writeLen }
                    else           { subdivPlayhead = writeLen }
                }
            }
        }

        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.audioQueue.async { self?.scheduleNextBuffer() }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaReset),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEngineConfigChange),
            name: .AVAudioEngineConfigurationChange, object: engine)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWakeUp),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            var shouldStop = false
            audioQueue.sync {
                guard self.isRunning else {
                    os_log("[Q-BEATS][INTERRUPTION] began — engine già fermo, noop",
                           log: .default, type: .default)
                    return
                }
                // Salva stato Link PRIMA di fermare l'audio layer.
                // CRITICO: NON chiamare midi_engine_stop() — il sequencer C++ continua a
                // mantenere la beat position corrente. NON notificare stop a Link.
                if let lh = self.linkEngineHandle {
                    self.clockLinkWasEnabled = link_engine_is_enabled(lh)
                } else {
                    self.clockLinkWasEnabled = false
                }
                // CRITICO: NON salvare beat/timestamp — midi_engine_get_beat_at_time()
                // calcola la posizione corretta al momento del resume usando lastMachTime
                // e lastSamplePosition aggiornati dall'ultimo sync_clock.
                self.isAudioInterrupted = true
                self.isRunning          = false
                shouldStop              = true
            }
            guard shouldStop else { return }
            playerNode.stop()
            engine.stop()
            DispatchQueue.main.async {
                self.isPlaying   = false
                self.clickStatus = "audio muted — clock running"
            }
            os_log("[Q-BEATS][INTERRUPTION] began — audio stopped, MIDI/Link clock running",
                   log: .default, type: .default)

        case .ended:
            audioQueue.async { [weak self] in
                guard let self = self else { return }

                // Recovery pendingResume
                if self.pendingResume {
                    self.pendingResume = false
                    self.pendingResumeBeat = nil
                    let recoveryBeat: Double?
                    if let mh = self.midiEngineHandle {
                        let hostTime = mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks
                        recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                    } else {
                        recoveryBeat = nil
                    }
                    os_log("[Q-BEATS][RESUME] pendingResume recuperato da InterruptionEnded beat:%.4f",
                           log: .default, type: .default, recoveryBeat ?? -1.0)
                    self.activateSessionAndStart(resumeAtBeat: recoveryBeat, trigger: "pending_recovery")
                    return
                }

                // Filtro shouldResume
                let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let shouldResume = AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                if !shouldResume {
                    os_log("[Q-BEATS][RESUME] .ended ricevuto ma shouldResume=false — Pending=true.",
                           log: .default, type: .default)
                    self.pendingResumeBeat = nil
                    self.pendingResume = true

                    // Safety net autonomo: iOS non manda eventi successivi in questo path.
                    // Dopo 2s triggeriamo recovery via activateSessionAndStart se ancora pending.
                    let capturedToken = self.currentResumeToken
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self else { return }
                        self.audioQueue.async { [weak self] in
                            guard let self = self else { return }
                            guard self.pendingResume else { return }
                            guard self.currentResumeToken == capturedToken else { return }
                            os_log("[Q-BEATS][RESUME] safety_net_shouldResume_false triggered (token:%d)",
                                   log: .default, type: .default, capturedToken)
                            self.pendingResume = false
                            self.pendingResumeBeat = nil
                            var recoveryBeat: Double? = nil
                            if let mh = self.midiEngineHandle {
                                let hostTime = mach_absolute_time()
                                             + self.outputLatencyTicks
                                             + self.bufferDurationTicks
                                recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                            }
                            self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                                         trigger: "safety_net_noresume")
                        }
                    }
                    return
                }

                guard self.isAudioInterrupted else {
                    os_log("[Q-BEATS][INTERRUPTION] ended — nessuna interruzione attiva, noop",
                           log: .default, type: .default)
                    return
                }

                // Guardia hardware: se ancora occupato non ripartire
                let session = AVAudioSession.sharedInstance()
                let isCallActive = session.mode == .voiceChat ||
                                   session.mode == .videoChat ||
                                   session.mode == .voicePrompt ||
                                   session.category == .record ||
                                   session.category == .playAndRecord
                let silenceHint = session.secondaryAudioShouldBeSilencedHint

                if isCallActive || silenceHint {
                    os_log("[Q-BEATS][INTERRUPTION] ended — hardware ancora occupato (isCallActive:%d silenceHint:%d) — skip",
                           log: .default, type: .default, isCallActive ? 1 : 0, silenceHint ? 1 : 0)
                    if let _ = self.midiEngineHandle {
                        self.pendingResumeBeat = nil
                        self.pendingResume = true
                    }
                    return
                }

                // NON resettare isAudioInterrupted qui — lo fa activateSessionAndStart dopo setActive OK
                let linkWasEnabled = self.clockLinkWasEnabled

                // 1. Graph rebuild
                self.rebuildGraph(for: self.detectAudioMode())

                // 2. Calcola resumeBeat DOPO setActive — il più tardi possibile
                let resumeBeat: Double?
                if let mh = self.midiEngineHandle {
                    let avSession = AVAudioSession.sharedInstance()
                    self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                    self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                    if let lh = self.linkEngineHandle {
                        link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                    }
                    let hostTimeAtFirstSample = mach_absolute_time()
                                                + self.outputLatencyTicks
                                                + self.bufferDurationTicks
                    resumeBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
                } else {
                    resumeBeat = nil
                }

                // 3. Log
                os_log("[Q-BEATS][INTERRUPTION] ended — resumeBeat:%.4f link:%d",
                       log: .default, type: .default,
                       resumeBeat ?? -1.0, linkWasEnabled ? 1 : 0)

                // 4. Aggiorna timestamp resume — blocca handleEngineConfigChange post-interruzione
                self.lastInterruptionResumeTime = mach_absolute_time()

                // 5. Start — Con Link attivo passa nil: phase sync automatica nei primi buffer
                self.activateSessionAndStart(
                    resumeAtBeat: linkWasEnabled ? nil : resumeBeat,
                    trigger: "interruption_ended"
                )
            }

        @unknown default: break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        os_log("routeChange reason=%{public}@",
               log: .default, type: .default, "\(reason)")

        // B1 Hard Sync: clock C++ NON si ferma mai durante route change.
        // MAI chiamare midi_engine_stop() qui.

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // --- pendingResume recovery (path esistente preservato) ---
            if self.pendingResume {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }
                os_log("[Q-BEATS][RESUME] pendingResume recuperato da RouteChange — beat:%.4f",
                       log: .default, type: .default, recoveryBeat ?? -1.0)
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat, trigger: "pending_recovery")
                return
            }

            // --- Fase 1.5a: hardware detection e routing dinamico ---
            let newSampleRate = AVAudioSession.sharedInstance().sampleRate
            let detectedMode = self.detectAudioMode()
            let sampleRateChanged = newSampleRate != self.sampleRate
            let modeChanged = detectedMode != self.audioMode

            os_log("routeChange newSampleRate=%.1f detectedMode=%{public}@ srChanged=%{public}@ modeChanged=%{public}@",
                   log: .default, type: .default,
                   newSampleRate, "\(detectedMode)",
                   "\(sampleRateChanged)", "\(modeChanged)")

            self.sampleRate = newSampleRate
            // Task D refactor #18 — propaga sampleRate al pending atomic
            // su route change (es. cambio interface 48 kHz ↔ 44.1 kHz).
            qbeats_link_pending_set_sample_rate(self.linkPending, newSampleRate)

            if sampleRateChanged {
                let wasRunning = self.isRunning
                self.setupGraph()

                guard wasRunning else {
                    os_log("[Q-BEATS][ROUTE] sampleRateChanged — engine fermo, no restart",
                           log: .default, type: .default)
                    DispatchQueue.main.async {
                        self.audioMode = detectedMode
                        self.sampleRateInfo = newSampleRate
                    }
                    return
                }

                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time()
                                 + self.outputLatencyTicks
                                 + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }

                os_log("[Q-BEATS][ROUTE] sampleRateChanged — recoveryBeat:%.4f",
                       log: .default, type: .default, recoveryBeat ?? -1.0)

                self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                              trigger: "sample_rate_change")
                return
            } else if modeChanged {
                // Topologia grafo cambia tra Base e Pro — rebuild completo obbligatorio.
                // B1 Hard Sync: clock C++ non si ferma — MAI midi_engine_stop() qui.
                let wasRunning = self.isRunning
                self.isRunning = false
                self.playerNode.stop()
                self.engine.stop()

                self.rebuildGraph(for: detectedMode)
                self.applyChannelRouting(for: detectedMode)

                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time()
                                 + self.outputLatencyTicks
                                 + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }

                os_log("[Q-BEATS][ROUTE] modeChanged %{public}@ → %{public}@ — recoveryBeat:%.4f",
                       log: .default, type: .default,
                       "\(self.audioMode)", "\(detectedMode)", recoveryBeat ?? -1.0)

                DispatchQueue.main.async {
                    self.audioMode = detectedMode
                    self.sampleRateInfo = newSampleRate
                }

                guard wasRunning else {
                    os_log("[Q-BEATS][ROUTE] modeChanged — engine fermo, no restart",
                           log: .default, type: .default)
                    return
                }

                self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                             trigger: "mode_change",
                                             mode: detectedMode)
                return
            }

            // Path senza cambio né SR né mode
            DispatchQueue.main.async {
                self.audioMode = detectedMode
                self.sampleRateInfo = newSampleRate
            }

            // --- Aggiornamento latency ticks ---
            let avSession = AVAudioSession.sharedInstance()
            self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
            self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
            if let lh = self.linkEngineHandle {
                link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
            }

        }
    }

    @objc private func handleMediaReset(_ notification: Notification) {
        let wasRunning: Bool = audioQueue.sync { self.isRunning }
        stopSync()
        setupSession()
        setupGraph()
        audioQueue.sync {
            self.backtrackBuffer = nil
            self.backtrackArmed  = false
        }
        applySettings(appSettings)
        audioQueue.sync {
            self.clickSamples              = self.generateClickSamples(frequency: 1000.0)
            self.accentedClickSamples      = self.generateClickSamples(frequency: 1500.0)
            self.subdivisionClickSamples   = self.generateClickSamples(frequency: 800.0)
        }
        if wasRunning {
            activateSessionAndStart(resumeAtBeat: nil, trigger: "media_reset")
        }
    }

    @objc private func handleEngineConfigChange(_ notification: Notification) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            guard self.isRunning, !self.engine.isRunning else { return }

            let hardwareSR = AVAudioSession.sharedInstance().sampleRate
            let nodeSR = self.sampleRate
            guard abs(hardwareSR - nodeSR) < 1.0 else {
                os_log("[Q-BEATS] handleEngineConfigChange: SR mismatch hardware=%.0f node=%.0f — skip",
                       log: .default, type: .default, hardwareSR, nodeSR)
                return
            }

            let timeSinceResume = self.machTicksToSeconds(mach_absolute_time() - self.lastInterruptionResumeTime)

            guard self.lastInterruptionResumeTime == 0 || timeSinceResume > 20.0 else {
                os_log("[Q-BEATS][ENGINE] Config change post-interruption skip (%.1fs since resume)", 
                       log: .default, type: .default, timeSinceResume)
                return
            }

            if self.pendingResume {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }
                os_log("[Q-BEATS][RESUME] pendingResume recuperato da EngineConfigChange — beat:%.4f",
                       log: .default, type: .default, recoveryBeat ?? -1.0)
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat, trigger: "pending_recovery")
                return
            }

            os_log("[Q-BEATS][ENGINE] Config change detected — rebuilding graph and restarting",
                   log: .default, type: .default)

            self.isRunning = false
            self.playerNode.stop()

            // 1. Graph rebuild
            self.rebuildGraph(for: self.detectAudioMode())

            // 2. Calcolo resumeBeat professionale (Backlog #15 fix)
            let resumeBeat: Double?
            if let mh = self.midiEngineHandle {
                let avSession = AVAudioSession.sharedInstance()
                self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                
                if let lh = self.linkEngineHandle {
                    link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                }

                let hostTimeAtFirstSample = mach_absolute_time() 
                                            + self.outputLatencyTicks 
                                            + self.bufferDurationTicks
                resumeBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
            } else {
                resumeBeat = nil
            }

            // 3. Riattivazione sessione e restart
            self.activateSessionAndStart(resumeAtBeat: resumeBeat, trigger: "engine_config_change")
        }
    }

    @objc private func handleAppWakeUp() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isPlaying, !self.isRunning else { return }

            if self.pendingResume {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                var recoveryBeat: Double? = nil
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time()
                                 + self.outputLatencyTicks
                                 + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                }
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                             trigger: "wakeup_pending_recovery")
                return
            }

            var resumeBeat: Double? = nil
            if let mh = self.midiEngineHandle {
                let hostTime = mach_absolute_time()
                             + self.outputLatencyTicks
                             + self.bufferDurationTicks
                resumeBeat = midi_engine_get_beat_at_time(mh, hostTime)
            }
            self.activateSessionAndStart(resumeAtBeat: resumeBeat, trigger: "app_wakeup")
        }
    }
}