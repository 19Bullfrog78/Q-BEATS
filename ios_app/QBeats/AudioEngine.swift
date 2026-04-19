import AVFoundation
import os

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

    // === AGGIUNTO Blocco 7 — stato interruzione (protetto da audioQueue) ===
    private var wasPlayingBeforeInterruption: Bool   = false
    private var interruptionBeatPosition:     Double  = 0.0
    private var interruptionBPM:              Double  = 120.0
    private var interruptionTimestamp:        UInt64  = 0
    private var interruptionLinkWasEnabled:   Bool    = false

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
                try self.engine.start()
                self.playerNode.play()
                // Reset stato interno del playerNode dopo restart engine.
                // Senza questo, i completion handler di scheduleBuffer
                // non si attivano dopo una interruzione AVAudioSession.
                self.playerNode.reset()
                self.isRunning = true

                if let mh = self.midiEngineHandle {
                    midi_engine_start(mh)

                    // Reset sequencer: azzera lastSamplePosition + _sampleBaseAdj
                    midi_engine_sync_clock(mh, 0, mach_absolute_time(), self.sampleRate)
                    // start(resumeAtBeat:) applica beat corretto prima dei buffer → zero race condition
                    let startBeat = resumeAtBeat ?? 0.0
                    midi_engine_set_beat_position(mh, startBeat)
                    if let h = self.metronomeHandle {
                        metronome_set_beat_position(h, startBeat)
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

    // Chiamare SOLO su audioQueue.
    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }
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
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info      = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type      = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {

        case .began:
            audioQueue.sync {
                // Salva stato prima di fermarsi
                self.wasPlayingBeforeInterruption = self.isRunning
                guard self.isRunning else { return }

                // Salva beat position e BPM al momento dell'interruzione
                if let mh = self.midiEngineHandle {
                    self.interruptionBeatPosition = midi_engine_get_beat_position(mh)
                }
                self.interruptionBPM       = self.currentBPM
                self.interruptionTimestamp = mach_absolute_time()

                // Salva se Link era attivo (non leggere @Published in .ended)
                if let lh = self.linkEngineHandle {
                    self.interruptionLinkWasEnabled = link_engine_is_enabled(lh)
                    // Notifica Link che la riproduzione si è fermata
                    link_engine_set_is_playing(lh, false, mach_absolute_time())
                } else {
                    self.interruptionLinkWasEnabled = false
                }

                self.isRunning = false
            }

            guard wasPlayingBeforeInterruption else { return }
            playerNode.stop()
            engine.stop()
            if let mh = midiEngineHandle { midi_engine_stop(mh) }
            let bc = audioQueue.sync { self.bufferCount }
            let bt = audioQueue.sync { self.beatTotal }
            DispatchQueue.main.async {
                self.isPlaying   = false
                self.clickStatus = "interrupted buf:\(bc) beats:\(bt)"
            }
            os_log("[Q-BEATS][INTERRUPTION] began — beat:%.4f bpm:%.1f link:%d",
                   log: .default, type: .default,
                   interruptionBeatPosition, interruptionBPM,
                   interruptionLinkWasEnabled ? 1 : 0)

        case .ended:
            // Ignoriamo shouldResume per comportamento live: un metronomo/sequencer
            // deve sempre riprendere quando l'utente torna sull'app, anche se iOS
            // lo considera non-resumable (es. dopo interruzione da YouTube).
            guard wasPlayingBeforeInterruption else { return }

            // Copia locale + reset stato — previene doppio setActive se iOS manda
            // anche .categoryChange dopo .ended (es. chiamata rifiutata).
            // Il secondo setActive mentre l'engine è già running corrompe
            // silenziosamente la session e blocca il completion handler dei buffer.
            let resumeBeatPosition = interruptionBeatPosition
            let resumeBPM          = interruptionBPM
            let resumeLinkEnabled  = interruptionLinkWasEnabled
            let resumeTimestamp    = interruptionTimestamp

            wasPlayingBeforeInterruption = false
            interruptionTimestamp        = 0
            interruptionBeatPosition     = 0.0
            interruptionBPM              = 120.0
            interruptionLinkWasEnabled   = false

            try? AVAudioSession.sharedInstance().setActive(true,
                options: .notifyOthersOnDeactivation)

            let elapsedTicks = mach_absolute_time() - resumeTimestamp
            let elapsedNanos = Double(elapsedTicks)
                             * Double(machTimebase.numer)
                             / Double(machTimebase.denom)
            let elapsedSecs  = elapsedNanos / 1_000_000_000.0
            let resumeBeat   = resumeBeatPosition
                             + (elapsedSecs * resumeBPM / 60.0)

            os_log("[Q-BEATS][INTERRUPTION] ended — elapsed:%.3fs resumeBeat:%.4f link:%d",
                   log: .default, type: .default,
                   elapsedSecs, resumeBeat,
                   resumeLinkEnabled ? 1 : 0)

            start(resumeAtBeat: resumeLinkEnabled ? nil : resumeBeat)

        @unknown default: break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info        = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason      = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable { stopSync() }

        // Resume dopo chiamata telefonica o altre route changes CallKit
        // iOS non manda sempre .ended via InterruptionNotification per chiamate.
        // Invece manda routeChange con .categoryChange quando la chiamata finisce.
        if reason == .categoryChange {
            audioQueue.async { [weak self] in
                guard let self = self,
                      self.wasPlayingBeforeInterruption else { return }

                // === GUARD SR contro false resume durante chiamata attiva ===
                let currentSampleRate = AVAudioSession.sharedInstance().sampleRate
                guard currentSampleRate >= 44100 else {
                    os_log("[Q-BEATS][INTERRUPTION][ROUTE] categoryChange ignorato — SR:%.0f",
                           log: .default, type: .default, currentSampleRate)
                    return
                }

                // === GUARD durata minima interruzione ===
                // Suoneria (Ringtone) non abbassa SR ma manda began+categoryChange
                // a distanza di ~100-200ms. Una interruzione reale dura >= 500ms.
                let elapsedTicksCheck = mach_absolute_time() - self.interruptionTimestamp
                let elapsedSecsCheck  = Double(elapsedTicksCheck)
                                      * Double(self.machTimebase.numer)
                                      / Double(self.machTimebase.denom)
                                      / 1_000_000_000.0
                guard elapsedSecsCheck >= 0.5 else {
                    os_log("[Q-BEATS][INTERRUPTION][ROUTE] categoryChange ignorato — elapsed troppo breve: %.3fs",
                           log: .default, type: .default, elapsedSecsCheck)
                    return
                }

                // Copia locale dello stato prima di consumarlo
                let resumeBeatPosition = self.interruptionBeatPosition
                let resumeBPM          = self.interruptionBPM
                let resumeLinkEnabled  = self.interruptionLinkWasEnabled
                let resumeTimestamp    = self.interruptionTimestamp

                // Consuma lo stato di interruzione per evitare valori sporchi successivi
                self.wasPlayingBeforeInterruption = false
                self.interruptionTimestamp        = 0
                self.interruptionBeatPosition     = 0.0
                self.interruptionBPM              = 120.0
                self.interruptionLinkWasEnabled   = false

                // Calcolo elapsed
                let elapsedTicks = mach_absolute_time() - resumeTimestamp
                let elapsedNanos = Double(elapsedTicks)
                                 * Double(self.machTimebase.numer)
                                 / Double(self.machTimebase.denom)
                let elapsedSecs  = elapsedNanos / 1_000_000_000.0
                let resumeBeat   = resumeBeatPosition
                                 + (elapsedSecs * resumeBPM / 60.0)

                os_log("[Q-BEATS][INTERRUPTION][ROUTE] resume after categoryChange — elapsed:%.3fs resumeBeat:%.4f link:%d",
                       log: .default, type: .default,
                       elapsedSecs, resumeBeat, resumeLinkEnabled ? 1 : 0)

                DispatchQueue.main.async {
                    try? AVAudioSession.sharedInstance().setActive(true,
                        options: .notifyOthersOnDeactivation)
                    self.start(resumeAtBeat: resumeLinkEnabled ? nil : resumeBeat)
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
}