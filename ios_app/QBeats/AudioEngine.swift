import AVFoundation
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

class AudioEngine: ObservableObject {

    @Published var clickStatus : String  = "non caricato"
    @Published var currentBPM: Double = 120.0
    @Published var linkEnabled: Bool = false
    @Published var linkIsConnected: Bool = false
    @Published var isPlaying   : Bool    = false
    @Published var beatsPerBar : UInt32  = 4
    // -------------------------------------------------------

    private var metronomeHandle      : MetronomeHandle?
    private var midiEngineHandle     : MIDIEngineHandle? = nil
    // === MODIFICATO 6A ===
    private var linkEngineHandle     : LinkEngineHandle? = nil

    // === AGGIUNTO 6C — timebase cachato all'avvio ===
    private let machTimebase: mach_timebase_info_data_t = {
        var tbi = mach_timebase_info_data_t()
        mach_timebase_info(&tbi)
        return tbi
    }()

    private let engine               = AVAudioEngine()
    private let playerNode           = AVAudioPlayerNode()
    private let sampleRate           : Double = 48000.0
    private let bufferSize           : AVAudioFrameCount = 512
    private let maxBeats             : Int = 16

    // --- Stato audio: accesso SOLO su audioQueue ---
    private var clickSamples         : [Float] = []
    private var accentedClickSamples : [Float] = []
    private var isRunning            = false
    private var bufferCount          : Int = 0
    private var beatTotal            : Int = 0
    private var clickPlayhead        : Int = -1
    private var accentPlayhead       : Int = -1
    private var offsets              : [UInt32]
    private var accents              : [UInt8]

    // === AGGIUNTO 6C — Link phase sync (accesso solo su audioQueue) ===
    private var outputLatencyTicks : UInt64 = 0
    private var bufferDurationTicks: UInt64 = 0



    // Usato da handleEngineConfigChange per ricalcolare beat position accurata
    private var lastStartBeat:      Double = 0.0
    private var lastStartTimestamp: UInt64 = 0

    // === Blocco 7 — Silent Ticking (accesso SOLO su audioQueue) ===
    // Il clock C++ (metronome, MIDI, Link) non si ferma mai durante le interruzioni.
    // Solo l'audio layer (AVAudioEngine + playerNode) viene sospeso.
    private var isAudioInterrupted:  Bool = false
    private var clockLinkWasEnabled: Bool = false
    private var lastInterruptionResumeTime: UInt64 = 0
    private var pendingResume: Bool = false
    private var pendingResumeBeat: Double? = nil
    private var currentResumeToken: Int = 0

    // ------------------------------------------------

    private let audioQueue = DispatchQueue(label: "com.bullfrog.qbeats.audio", qos: .userInteractive)

    init() {
        offsets = [UInt32](repeating: 0, count: maxBeats)
        accents = [UInt8](repeating: 0, count: maxBeats)
        metronomeHandle = metronome_create(sampleRate, 120.0)
        midiEngineHandle = midi_engine_create()
        // === MODIFICATO 6A ===
        linkEngineHandle = link_engine_create()

        if let lh = linkEngineHandle {
            link_engine_set_tempo_callback(lh, { bpm, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async {
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
        }

        // === AGGIUNTO 6D — Start/Stop sync callback da peer Link ===
        if let lh = linkEngineHandle {
            link_engine_set_start_stop_callback(lh, { isPlaying, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
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

        setupSession()
        setupGraph()
        audioQueue.sync {
            self.clickSamples         = self.generateClickSamples(frequency: 1000.0)
            self.accentedClickSamples = self.generateClickSamples(frequency: 1500.0)
        }
        setupNotifications()
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
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isRunning, let _ = self.metronomeHandle else { return }
            do {
                self.bufferCount    = 0
                self.beatTotal      = 0
                self.clickPlayhead  = -1
                self.accentPlayhead = -1

                self.lastStartBeat      = resumeAtBeat ?? 0.0
                self.lastStartTimestamp = mach_absolute_time()
                try self.engine.start()
                self.playerNode.reset()
                self.playerNode.play()
                self.isRunning = true

                if let mh = self.midiEngineHandle {
                    let resumeBeat: Double? = resumeAtBeat

                    midi_engine_start(mh)
                    midi_engine_sync_clock(mh, 0, mach_absolute_time(), self.sampleRate)

                    if let beat = resumeBeat {
                        // Option B: Snap al prossimo confine di misura (Downbeat)
                        let beatsPerBarD = Double(self.beatsPerBar)
                        let snappedBeat = ceil(beat / beatsPerBarD) * beatsPerBarD
                        
                        os_log("[Q-BEATS][RESUME] Snap: %.4f -> %.4f (Measure boundary)", 
                               log: .default, type: .default, beat, snappedBeat)
                        
                        midi_engine_set_beat_position(mh, snappedBeat)
                        if let h = self.metronomeHandle {
                            metronome_set_beat_position(h, snappedBeat)
                        }
                    } else {
                        // Fresh play: fissa phase origin a 0 e azzera _currentBeatInBar.
                        midi_engine_set_beat_position(mh, 0.0)
                        if let h = self.metronomeHandle {
                            metronome_reset_for_start(h, 0.0)
                        }
                    }
                    if let lh = self.linkEngineHandle {
                        link_engine_set_quantum(lh, Double(self.beatsPerBar))
                    }

                    // Annuncio Link (join senza forzare downbeat)
                    if let lh = self.linkEngineHandle {
                        link_engine_set_is_playing(lh, true, mach_absolute_time())
                    }

                    if UserDefaults.standard.bool(forKey: "networkMIDIEnabled") {
                        midi_engine_network_enable(mh)
                    } else {
                        midi_engine_network_disable(mh)
                    }
                }

                let sr  = AVAudioSession.sharedInstance().sampleRate
                let buf = AVAudioSession.sharedInstance().ioBufferDuration * sr
                let statusStr = "started SR:\(Int(sr)) buf:\(Int(buf)) samples:\(self.clickSamples.count)"
                DispatchQueue.main.async {
                    self.isPlaying   = true
                    self.clickStatus = statusStr
                }

                let avSession = AVAudioSession.sharedInstance()
                self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                if let lh = self.linkEngineHandle {
                    link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                }

                self.scheduleNextBuffer()
                self.scheduleNextBuffer()
                self.scheduleNextBuffer()
            } catch {
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
            if let mh = self.midiEngineHandle {
                midi_engine_set_bpm(mh, bpm)
            }
            if let lh = self.linkEngineHandle {
                link_engine_set_bpm(lh, bpm)
                DispatchQueue.main.async { self.currentBPM = bpm }
            }
        }
    }

    func setLinkEnabled(_ enabled: Bool) {
        audioQueue.async { [weak self] in
            guard let self = self, let lh = self.linkEngineHandle else { return }
            link_engine_set_enabled(lh, enabled)
            DispatchQueue.main.async {
                self.linkEnabled = enabled
                if !enabled {
                    self.linkIsConnected = false
                }
            }
        }
    }

    func makeLinkSettingsPresenter() -> LinkSettingsPresenter {
        guard let lh = linkEngineHandle else {
            fatalError("LinkEngine non inizializzato")
        }
        return LinkSettingsPresenter(handle: lh)
    }

    func enableNetworkMIDI() {
        audioQueue.async { [weak self] in
            guard let self = self, let h = self.midiEngineHandle else { return }
            midi_engine_network_enable(h)
        }
    }

    func disableNetworkMIDI() {
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
        audioQueue.async {
            metronome_setBeatsPerBar(h, beatsPerBar)
            if let lh = self.linkEngineHandle {
                link_engine_set_quantum(lh, Double(beatsPerBar))
            }
        }
    }

    // MARK: - Private

    // NON chiamare dall'interno di audioQueue (deadlock).
    private func stopSync() {
        var wasRunning = false
        var bc = 0
        var bt = 0
        audioQueue.sync {
            wasRunning = self.isRunning
            guard self.isRunning else { return }
            self.isRunning = false
            bc = self.bufferCount
            bt = self.beatTotal
            
            // === AGGIUNTO 6D — notifica Link che la riproduzione è ferma ===
            if let lh = linkEngineHandle {
                link_engine_set_is_playing(lh, false, mach_absolute_time())
            }
        }
        guard wasRunning else { return }
        playerNode.stop()
        engine.stop()
        if let mh = midiEngineHandle { midi_engine_stop(mh) }
        let statusStr = "stopped buf:\(bc) beats:\(bt)"
        DispatchQueue.main.async {
            self.isPlaying   = false
            self.clickStatus = statusStr
        }
    }

    private func activateSessionAndStart(
        resumeAtBeat: Double?,
        trigger: String,
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

                self.start(resumeAtBeat: resumeAtBeat)

            } catch {
                guard attempt < 10 else {
                    self.pendingResume = true
                    self.pendingResumeBeat = nil
                    os_log("[Q-BEATS][RESUME] setActive esaurito — pendingResume=true beat:%.4f trigger:%{public}@",
                           log: .default, type: .default, resumeAtBeat ?? -1.0, trigger)

                    // Safety net: un solo tentativo ritardato dopo 3s
                    self.audioQueue.asyncAfter(deadline: .now() + 3.0) { [weak self] in
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

                os_log("[Q-BEATS][RESUME] setActive attempt %d/10 fallito (token:%d), retry in 100ms",
                       log: .default, type: .default, attempt + 1, activeToken)

                self.audioQueue.asyncAfter(deadline: .now() + 0.1) { [weak self] in
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
            try session.setActive(true)
        } catch {
            DispatchQueue.main.async { self.clickStatus = "session fallita: \(error)" }
        }
    }

    private func setupGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
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
                if link_engine_sync_phase(lh, hostTimeAtOutput, currentBeat, &newBeat) {
                    midi_engine_set_beat_position(mh, newBeat)
                    metronome_set_beat_position(h, newBeat)
                    os_log("[Q-BEATS][LINK] Phase sync: %.4f → %.4f beats",
                           log: .default, type: .default,
                           currentBeat, newBeat)
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

        let beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, &accents, UInt32(maxBeats))
        bufferCount += 1
        beatTotal   += Int(beatCount)

        if clickPlayhead >= 0 && !clickSamples.isEmpty {
            let remaining = clickSamples.count - clickPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            for j in 0..<writeLen { dst[j] += clickSamples[clickPlayhead + j] }
            clickPlayhead += writeLen
            if clickPlayhead >= clickSamples.count { clickPlayhead = -1 }
        }

        if accentPlayhead >= 0 && !accentedClickSamples.isEmpty {
            let remaining = accentedClickSamples.count - accentPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            for j in 0..<writeLen { dst[j] += accentedClickSamples[accentPlayhead + j] }
            accentPlayhead += writeLen
            if accentPlayhead >= accentedClickSamples.count { accentPlayhead = -1 }
        }

        if beatCount > 0 {
            for i in 0..<Int(beatCount) {
                let offset   = Int(offsets[i])
                let isAccent = accents[i] != 0
                let samples  = isAccent ? accentedClickSamples : clickSamples
                guard offset < Int(bufferSize), !samples.isEmpty else { continue }
                let writeLen = min(samples.count, Int(bufferSize) - offset)
                for j in 0..<writeLen { dst[offset + j] += samples[j] }
                if writeLen < samples.count {
                    if isAccent { accentPlayhead = writeLen }
                    else        { clickPlayhead  = writeLen }
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
                self.engine.disconnectNodeOutput(self.playerNode)
                self.engine.connect(self.playerNode, to: self.engine.mainMixerNode, format: nil)
                self.engine.prepare()

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
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.pendingResume else { return }
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
        }

        guard let info        = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason      = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable {
            // Fermare solo se il device rimosso era un output audio reale
            // (cuffie, BT A2DP, BT LE). NON fermare per rilascio del
            // codec telefonico (earpiece/mic chiamata) che manda
            // oldDeviceUnavailable quando la chiamata finisce.
            if let previousRoute = info[AVAudioSessionRouteChangePreviousRouteKey]
                as? AVAudioSessionRouteDescription {
                let wasAudioOutput = previousRoute.outputs.contains {
                    $0.portType == .headphones ||
                    $0.portType == .bluetoothA2DP ||
                    $0.portType == .bluetoothLE ||
                    $0.portType == .airPlay
                }
                if wasAudioOutput { stopSync() }
            }
        }

        // Resume dopo chiamata telefonica o altre route changes CallKit
        // iOS non manda sempre .ended via InterruptionNotification per chiamate.
        // Invece manda routeChange con .categoryChange quando la chiamata finisce.
        if reason == .categoryChange {
            audioQueue.async { [weak self] in
                guard let self = self else { return }

                let avSession = AVAudioSession.sharedInstance()
                let currentSR = avSession.sampleRate

                let isVoiceActive = avSession.mode == .voiceChat ||
                                    avSession.mode == .videoChat ||
                                    avSession.category == .record ||
                                    avSession.category == .playAndRecord ||
                                    currentSR < 44100

                // === CASO VOICE BEGAN ===
                if isVoiceActive {
                    guard self.isRunning else {
                        os_log("[Q-BEATS][INTERRUPTION][ROUTE] categoryChange voice — engine già fermo (mode:%@ cat:%@)",
                               log: .default, type: .default,
                               avSession.mode.rawValue, avSession.category.rawValue)
                        return
                    }
                    if let lh = self.linkEngineHandle {
                        self.clockLinkWasEnabled = link_engine_is_enabled(lh)
                    } else {
                        self.clockLinkWasEnabled = false
                    }
                    self.isAudioInterrupted = true
                    self.isRunning          = false
                    self.playerNode.stop()
                    self.engine.stop()
                    // NON chiamare midi_engine_stop() — clock C++ continua.
                    // NON notificare stop a Link.
                    DispatchQueue.main.async {
                        self.isPlaying   = false
                        self.clickStatus = "voice active — clock running"
                    }
                    os_log("[Q-BEATS][INTERRUPTION][ROUTE] voice began — audio stopped, clock running (mode:%@ SR:%.0f)",
                           log: .default, type: .default,
                           avSession.mode.rawValue, currentSR)
                    return
                }

                // === CASO RESUME ===
                let startTime = mach_absolute_time()

                self.audioQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    
                    let session = AVAudioSession.sharedInstance()
                    let elapsed = self.machTicksToSeconds(mach_absolute_time() - startTime)
                    
                    let isCallActive = session.category == .playAndRecord || 
                                       session.category == .record || 
                                       session.mode == .voiceChat || 
                                       session.mode == .videoChat ||
                                       session.mode == .voicePrompt
                    
                    let silenceHint = session.secondaryAudioShouldBeSilencedHint
                    
                    os_log("[Q-BEATS][ROUTE] Delayed check (%.3fs): isCallActive:%d silenceHint:%d", 
                           log: .default, type: .default, elapsed, isCallActive ? 1 : 0, silenceHint ? 1 : 0)
                    
                    // GUARDIA: se ancora occupato, esce senza resettare lo stato di interruzione
                    guard !isCallActive && !silenceHint else {
                        os_log("[Q-BEATS][ROUTE] Chiamata/Prompt ancora attiva dopo delay — skip", 
                               log: .default, type: .default)
                        return
                    }

                    // VERIFICA STATO: procediamo solo se siamo effettivamente in interruzione
                    guard self.isAudioInterrupted else { return }

                    // NON resettare isAudioInterrupted qui — lo fa activateSessionAndStart dopo setActive OK
                    self.lastInterruptionResumeTime = mach_absolute_time()
                    let linkWasEnabled = self.clockLinkWasEnabled

                    // 1. Graph rebuild
                    self.engine.disconnectNodeOutput(self.playerNode)
                    self.engine.connect(self.playerNode, to: self.engine.mainMixerNode, format: nil)
                    self.engine.prepare()

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
                    os_log("[Q-BEATS][INTERRUPTION][ROUTE] resume after categoryChange — resumeBeat:%.4f link:%d",
                           log: .default, type: .default,
                           resumeBeat ?? -1.0, linkWasEnabled ? 1 : 0)

                    // 4. Start
                    // Con Link attivo passa nil: la phase sync avviene automaticamente
                    // nei primi buffer di scheduleNextBuffer().
                    self.activateSessionAndStart(
                        resumeAtBeat: linkWasEnabled ? nil : resumeBeat,
                        trigger: "route_category_change"
                    )
                }
            }
        }

        let avSession = AVAudioSession.sharedInstance()
        audioQueue.async { [weak self] in
            guard let self else { return }
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
            self.clickSamples         = self.generateClickSamples(frequency: 1000.0)
            self.accentedClickSamples = self.generateClickSamples(frequency: 1500.0)
        }
        if wasRunning { start() }
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

            // 1. Graph rebuild con auto-negoziazione formato
            self.engine.disconnectNodeOutput(self.playerNode)
            self.engine.connect(self.playerNode, to: self.engine.mainMixerNode, format: nil)
            self.engine.prepare()

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