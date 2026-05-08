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
    @Published var isPlaying   : Bool    = false
    @Published var beatsPerBar : UInt32  = 4
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
            DispatchQueue.main.async { self.channelVolumes = vols }
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
    private var _linkMode: LinkMode = .direttore   // accesso SOLO su audioQueue
    private var _audioBPM: Double = 120.0   // accesso SOLO su audioQueue
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
    // Opzione B — Link downbeat wait (accesso SOLO su audioQueue)
    private var pendingLinkStart: DispatchWorkItem? = nil
    // Build 303 — salta sync Link nei primi 3 buffer dopo fresh play
    private var linkSyncSkipBuffers: Int = 0

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
                    // Modalità Direttore in play: ri-asserisci il proprio tempo
                    // per vincere la negoziazione Link (Q-B detta, peer seguono).
                    // Il check bpm != _audioBPM evita loop di re-broadcast quando
                    // peer riceve il valore Q-B e ritorna lo stesso.
                    if engine.isRunning && engine._linkMode == .direttore {
                        if bpm != engine._audioBPM, let lh = engine.linkEngineHandle {
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
        }

        // === AGGIUNTO 6D — Start/Stop sync callback da peer Link ===
        if let lh = linkEngineHandle {
            link_engine_set_start_stop_callback(lh, { isPlaying, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                // Modalità Direttore in play: ignora start/stop da peer.
                // Lettura _linkMode da non-audioQueue: enum case è atomic in Swift.
                if engine.isRunning && engine._linkMode == .direttore { return }
                // CRITICO: NON dispatchiamo su audioQueue — stopSync() ha
                // audioQueue.sync dentro e causerebbe deadlock.
                DispatchQueue.main.async {
                    if isPlaying && !engine.isPlaying {
                        engine.start()
                    } else if !isPlaying && engine.isPlaying {
                        engine.stop()
                    }
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        // link_engine_activate() registra il POLL diagnostico; NON chiama ABLLinkSetActive.
        // Link viene attivato esclusivamente dal toggle UI (link_engine_set_enabled).
        if let lh = linkEngineHandle {
            link_engine_activate(lh)
        }

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
        if let h = metronomeHandle { metronome_destroy(h) }
        if let mh = midiEngineHandle { midi_engine_destroy(mh) }
        // === MODIFICATO 6A ===
        if let lh = linkEngineHandle { link_engine_destroy(lh) }
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
                self.clickPlayhead    = -1
                self.accentPlayhead   = -1
                self.subdivPlayhead   = -1

                try self.engine.start()
                self.playerNode.reset()
                self.playerNode.play()
                self.isRunning = true

                if let mh = self.midiEngineHandle {
                    let resumeBeat: Double? = resumeAtBeat

                    midi_engine_sync_clock(mh, 0, mach_absolute_time(), self.sampleRate)

                    if let beat = resumeBeat {
                        // CALCOLO SNAP RELATIVO ALLA FASE DEL PLAY
                        let beatsPerBarD = Double(self.beatsPerBar)

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
                        link_engine_set_quantum(lh, Double(self.beatsPerBar))
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
                        let beatsPerBarD = Double(self.beatsPerBar)
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
                        let quantum = Double(self.beatsPerBar)
                        var probe = LinkSessionProbe(isPlaying: false,
                                                     phaseAtHost: 0.0,
                                                     tempo: 0.0)
                        var peersCount: UInt32 = 0
                        if let lh = self.linkEngineHandle {
                            probe = link_engine_probe_session(lh, hostNow, quantum)
                            peersCount = link_engine_num_peers(lh)
                        }

                        if peersCount == 0 && !probe.isPlaying {
                            // === STANDALONE PURO (peers == 0) ===
                            // Q-BEATS è solo nella sessione Link (o Link disabled).
                            // Detta la timeline: chiede a Link di mappare beat 0
                            // a hostNow. Funziona anche con Link disabled (la
                            // funzione bridge fa early return su !enabled).
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
                            os_log("[Q-BEATS][LINK][START] standalone avviato",
                                   log: .default, type: .default)
                        } else {
                            // === SESSIONE CONDIVISA (peers > 0) ===
                            // Peer presenti, qualsiasi loro stato (fermi o in play).
                            // Q-BEATS si adegua alla timeline Link condivisa:
                            // quantized launch al prossimo downbeat con
                            // join_running_session, NESSUN override della timeline.
                            // Pattern aderente alla doc Ableton: "chi entra si
                            // adegua, chi c'è già non si muove" (dove "già nella
                            // sessione" significa "presente", non "in play").
                            let bpm = probe.tempo > 0.0 ? probe.tempo : self.currentBPM
                            let phase = probe.phaseAtHost
                            // Se phase ≈ 0 o ≈ quantum siamo già sul downbeat → no wait.
                            // Altrimenti aspettiamo (quantum - phase) beat.
                            let beatsToWait = (phase < 0.001 || phase > quantum - 0.001)
                                              ? 0.0
                                              : (quantum - phase)
                            let delaySeconds = beatsToWait * (60.0 / bpm)

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
                let uiPattern = self.defaultAccentPattern(for: self.beatsPerBar).map { $0 > 0 ? 2 : 1 as UInt8 }
                DispatchQueue.main.async {
                    self.isPlaying            = true
                    self.playbackState        = .playing
                    self.clickStatus          = statusStr
                    self.currentAccentPattern = uiPattern
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
    }

    func setBPM(_ bpm: Double) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_setBPM(h, bpm)
            self._audioBPM = bpm
            if let mh = self.midiEngineHandle {
                midi_engine_set_bpm(mh, bpm)
            }
            if let lh = self.linkEngineHandle {
                link_engine_set_bpm(lh, bpm)
            }
            DispatchQueue.main.async { self.currentBPM = bpm }
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

    // Dispatcha il valore su audioQueue verso C++.
    // Non tocca @Published beatsPerBar: è la UI che lo scrive
    // tramite Picker su main thread prima di chiamare questo metodo.
    func setBeatsPerBar(_ beatsPerBar: UInt32) {
        guard let h = metronomeHandle else { return }
        let pattern = defaultAccentPattern(for: beatsPerBar)
        self.currentAccentPattern = pattern.map { $0 > 0 ? 2 : 1 }
        audioQueue.async { [h, pattern] in
            metronome_setBeatsPerBar(h, beatsPerBar)
            if let lh = self.linkEngineHandle {
                link_engine_set_quantum(lh, Double(beatsPerBar))
            }
            pattern.withUnsafeBufferPointer { ptr in
                metronome_setAccentPattern(h, ptr.baseAddress, UInt32(pattern.count))
            }
        }
    }

    func setAccentPattern(_ pattern: [UInt8]) {
        guard let h = metronomeHandle else { return }
        DispatchQueue.main.async { self.currentAccentPattern = pattern.map { $0 > 0 ? 2 : 1 } }
        audioQueue.async { [h, pattern] in
            pattern.withUnsafeBufferPointer { ptr in
                metronome_setAccentPattern(h, ptr.baseAddress, UInt32(pattern.count))
            }
        }
    }

    func setSubdivision(multiplier: UInt8, swingRatio: Double = 0.5) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_setSubdivision(h, multiplier, swingRatio)
        }
    }

    func scheduleBPMChange(_ newBPM: Double) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_schedule_bpm_change(h, newBPM)
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
            os_log("QA-3 sampleRate aggiornato: %{public}.1f", log: .default, type: .default, sampleRate)
        } catch {
            DispatchQueue.main.async { self.clickStatus = "session fallita: \(error)" }
        }
    }

    private func setupGraph() {
        self.sampleRate = AVAudioSession.sharedInstance().sampleRate
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

        // Player → Mixer (identico in Base e Pro)
        engine.connect(playerNode,          to: ch1MixerNode, format: monoFormat)
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
        engine.prepare()
        os_log("rebuildGraph completato — mode: %{public}@",
               log: .default, type: .default, "\(mode)")
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

    // Chiamare SOLO su audioQueue.
    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }

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
                    // quindi isRunning è già garantito true dal guard a riga 1350).
                    // Ignora phase correction dai peer — Q-BEATS detta la timeline.
                } else if link_engine_sync_phase(lh, hostTimeAtOutput, currentBeat, &newBeat) {
                    midi_engine_set_beat_position(mh, newBeat)
                    metronome_set_beat_position(h, newBeat)
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

        let beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, &accents, &isBeats, UInt32(maxBeats))
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