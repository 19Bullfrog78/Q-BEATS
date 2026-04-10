import AVFoundation

// Regole thread — inviolabili:
// 1. isRunning, clickPlayhead, bufferCount, beatTotal, clickSamples
//    sono accedute ESCLUSIVAMENTE su audioQueue.
// 2. clickStatus è UI-only: ogni write avviene su audioQueue.async
//    per evitare data race con letture dal main thread.

class AudioEngine {
    private var metronomeHandle : MetronomeHandle?
    private let engine          = AVAudioEngine()
    private let playerNode      = AVAudioPlayerNode()
    private let sampleRate      : Double = 48000.0
    private let bufferSize      : AVAudioFrameCount = 512

    // --- Stato audio: accesso SOLO su audioQueue ---
    private var clickSamples    : [Float] = []
    private var isRunning       = false
    private var bufferCount     : Int = 0
    private var beatTotal       : Int = 0
    private var clickPlayhead   : Int = -1
    // ------------------------------------------------

    // --- UI only: write sempre su audioQueue.async ---
    var clickStatus: String = "non caricato"
    // -------------------------------------------------

    private let audioQueue = DispatchQueue(label: "com.bullfrog.qbeats.audio", qos: .userInteractive)

    init() {
        metronomeHandle = metronome_create(sampleRate, 120.0)
        setupSession()
        setupGraph()
        audioQueue.sync { self.generateClickSamples() }
        setupNotifications()
    }

    deinit {
        stopSync()
        if let h = metronomeHandle { metronome_destroy(h) }
    }

    // MARK: - Public API (chiamabile da qualsiasi thread)

    func start() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isRunning, let _ = self.metronomeHandle else { return }
            do {
                self.bufferCount   = 0
                self.beatTotal     = 0
                self.clickPlayhead = -1
                try self.engine.start()
                self.playerNode.play()
                self.isRunning = true
                let sr  = AVAudioSession.sharedInstance().sampleRate
                let buf = AVAudioSession.sharedInstance().ioBufferDuration * sr
                self.clickStatus = "started SR:\(Int(sr)) buf:\(Int(buf)) samples:\(self.clickSamples.count)"
                self.scheduleNextBuffer()
                self.scheduleNextBuffer()
                self.scheduleNextBuffer()
            } catch {
                self.clickStatus = "start fallito: \(error)"
            }
        }
    }

    func stop() {
        stopSync()
    }

    func setBPM(_ bpm: Double) {
        guard let h = metronomeHandle else { return }
        audioQueue.async { metronome_setBPM(h, bpm) }
    }

    // MARK: - Private

    // Ferma l'engine in modo sincrono.
    // Garantisce che isRunning = false prima di tornare.
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
        }
        guard wasRunning else { return }
        playerNode.stop()
        engine.stop()
        audioQueue.async { self.clickStatus = "stopped buf:\(bc) beats:\(bt)" }
    }

    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
            try session.setActive(true)
        } catch {
            audioQueue.async { self.clickStatus = "session fallita: \(error)" }
        }
    }

    private func setupGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    // Deve essere chiamata SOLO su audioQueue.
    private func generateClickSamples() {
        let frequency  : Float = 1000.0
        let durationMs : Float = 40.0
        let frameCount = Int(Float(sampleRate) * durationMs / 1000.0)
        let decayRate  : Float = 80.0

        var samples = [Float](repeating: 0.0, count: frameCount)
        for i in 0..<frameCount {
            let t        = Float(i) / Float(sampleRate)
            let envelope = expf(-decayRate * t)
            samples[i]   = sinf(2.0 * Float.pi * frequency * t) * envelope * 0.8
        }
        clickSamples = samples
        clickStatus  = "click sintetico OK: \(frameCount) samples"
    }

    // Deve essere chiamata SOLO su audioQueue.
    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        guard let dst = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(bufferSize) { dst[i] = 0.0 }

        var offsets   = [UInt32](repeating: 0, count: 16)
        let beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, 16)
        bufferCount += 1
        beatTotal   += Int(beatCount)

        // Fase 1: continua click in corso dal buffer precedente
        if clickPlayhead >= 0 && !clickSamples.isEmpty {
            let remaining = clickSamples.count - clickPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            for j in 0..<writeLen {
                dst[j] += clickSamples[clickPlayhead + j]
            }
            clickPlayhead += writeLen
            if clickPlayhead >= clickSamples.count { clickPlayhead = -1 }
        }

        // Fase 2: nuovi beat in questo buffer
        if beatCount > 0 && !clickSamples.isEmpty {
            let clickLen = clickSamples.count
            for i in 0..<Int(beatCount) {
                let offset   = Int(offsets[i])
                guard offset < Int(bufferSize) else { continue }
                let writeLen = min(clickLen, Int(bufferSize) - offset)
                for j in 0..<writeLen {
                    dst[offset + j] += clickSamples[j]
                }
                if writeLen < clickLen { clickPlayhead = writeLen }
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
              let type      = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Ferma l'engine. isRunning resta true dopo lo stop fisico,
            // così .ended sa che eravamo in play e può riprendere.
            var wasRunning = false
            var bc = 0
            var bt = 0
            audioQueue.sync {
                wasRunning = self.isRunning
                guard self.isRunning else { return }
                self.isRunning = false
                bc = self.bufferCount
                bt = self.beatTotal
            }
            guard wasRunning else { return }
            playerNode.stop()
            engine.stop()
            audioQueue.async { self.clickStatus = "stopped buf:\(bc) beats:\(bt)" }
            audioQueue.sync { self.isRunning = true }

        case .ended:
            let options      = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let shouldResume = options.map {
                AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume)
            } ?? false
            let wasPlaying: Bool = audioQueue.sync { self.isRunning }
            guard wasPlaying && shouldResume else { return }
            audioQueue.sync { self.isRunning = false }
            try? AVAudioSession.sharedInstance().setActive(true,
                options: .notifyOthersOnDeactivation)
            start()

        @unknown default: break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info        = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason      = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable { stopSync() }
    }

    @objc private func handleMediaReset(_ notification: Notification) {
        let wasRunning: Bool = audioQueue.sync { self.isRunning }
        stopSync()
        setupSession()
        setupGraph()
        audioQueue.sync { self.generateClickSamples() }
        if wasRunning { start() }
    }
}