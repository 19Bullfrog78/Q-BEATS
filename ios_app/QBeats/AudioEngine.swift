import AVFoundation

class AudioEngine {
    private var metronomeHandle: MetronomeHandle?
    private let engine       = AVAudioEngine()
    private let playerNode   = AVAudioPlayerNode()
    private let sampleRate   : Double = 48000.0
    private let bufferSize   : AVAudioFrameCount = 512
    private var clickSamples : [Float] = []
    private var isRunning    = false
    var clickStatus: String = "non caricato"
    private var bufferCount: Int = 0
    private var beatTotal: Int = 0
    private var clickPlayhead: Int = -1

    init() {
        metronomeHandle = metronome_create(sampleRate, 120.0)
        setupSession()
        setupGraph()
        generateClickSample()
        setupNotifications()
    }

    deinit {
        stop()
        if let h = metronomeHandle { metronome_destroy(h) }
    }

    func start() {
        guard !isRunning, let _ = metronomeHandle else { return }
        do {
            bufferCount = 0
            beatTotal = 0
            clickPlayhead = -1
            try engine.start()
            playerNode.play()
            isRunning = true
            let actualSR = AVAudioSession.sharedInstance().sampleRate
            let actualBuf = AVAudioSession.sharedInstance().ioBufferDuration * actualSR
            clickStatus = "started SR:\(Int(actualSR)) buf:\(Int(actualBuf)) samples:\(clickSamples.count)"
            scheduleNextBuffer()
            scheduleNextBuffer()
            scheduleNextBuffer()
        } catch {
            clickStatus = "start fallito: \(error)"
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        playerNode.stop()
        engine.stop()
        clickStatus = "stopped buf:\(bufferCount) beats:\(beatTotal)"
    }

    func setBPM(_ bpm: Double) {
        guard let h = metronomeHandle else { return }
        metronome_setBPM(h, bpm)
    }

    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setPreferredSampleRate(sampleRate)
            try session.setPreferredIOBufferDuration(512.0 / sampleRate)
            try session.setActive(true)
        } catch {
            clickStatus = "session fallita: \(error)"
        }
    }

    private func setupGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    private func generateClickSample() {
        let frequency: Float = 1000.0
        let durationMs: Float = 40.0
        let frameCount = Int(Float(sampleRate) * durationMs / 1000.0)
        let decayRate: Float = 80.0

        clickSamples = [Float](repeating: 0.0, count: frameCount)

        for i in 0..<frameCount {
            let t = Float(i) / Float(sampleRate)
            let envelope = expf(-decayRate * t)
            let sample = sinf(2.0 * Float.pi * frequency * t) * envelope
            clickSamples[i] = sample * 0.8
        }

        clickStatus = "click sintetico OK: \(frameCount) samples"
    }

    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        guard let dst = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(bufferSize) { dst[i] = 0.0 }

        var offsets = [UInt32](repeating: 0, count: 16)
        let beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, 16)
        bufferCount += 1
        beatTotal += Int(beatCount)

        // Fase 1: continua click in corso dal buffer precedente
        if clickPlayhead >= 0 && !clickSamples.isEmpty {
            let remaining = clickSamples.count - clickPlayhead
            let writeLen = min(remaining, Int(bufferSize))
            for j in 0..<writeLen {
                dst[j] += clickSamples[clickPlayhead + j]
            }
            clickPlayhead += writeLen
            if clickPlayhead >= clickSamples.count {
                clickPlayhead = -1
            }
        }

        // Fase 2: nuovi beat
        if beatCount > 0 && !clickSamples.isEmpty {
            let clickLen = clickSamples.count
            for i in 0..<Int(beatCount) {
                let offset = Int(offsets[i])
                guard offset < Int(bufferSize) else { continue }
                let writeLen = min(clickLen, Int(bufferSize) - offset)
                for j in 0..<writeLen {
                    dst[offset + j] += clickSamples[j]
                }
                // Se il click non è entrato tutto nel buffer, salva il playhead
                if writeLen < clickLen {
                    clickPlayhead = writeLen
                }
            }
        }

        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.global(qos: .userInteractive).async {
                self?.scheduleNextBuffer()
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            let wasRunning = isRunning; stop(); isRunning = wasRunning
        case .ended:
            let options = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let shouldResume = options.map {
                AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume)
            } ?? false
            if isRunning && shouldResume {
                isRunning = false
                try? AVAudioSession.sharedInstance().setActive(true,
                    options: .notifyOthersOnDeactivation)
                start()
            }
        @unknown default: break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        if reason == .oldDeviceUnavailable { stop() }
    }

    @objc private func handleMediaReset(_ notification: Notification) {
        stop(); setupSession(); setupGraph(); generateClickSample()
        if isRunning { isRunning = false; start() }
    }
}