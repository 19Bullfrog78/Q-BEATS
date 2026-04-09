import AVFoundation

class AudioEngine {
    private var metronomeHandle: MetronomeHandle?
    private let engine       = AVAudioEngine()
    private let playerNode   = AVAudioPlayerNode()
    private let sampleRate   : Double = 48000.0
    private let bufferSize   : AVAudioFrameCount = 512
    private var clickBuffer  : AVAudioPCMBuffer?
    private var isRunning    = false

    init() {
        metronomeHandle = metronome_create(sampleRate, 120.0)
        setupSession()
        setupGraph()
        clickBuffer = makeClickBuffer()
        setupNotifications()
    }

    deinit {
        stop()
        if let h = metronomeHandle { metronome_destroy(h) }
    }

    func start() {
        guard !isRunning, let _ = metronomeHandle else { return }
        do {
            try engine.start()
            playerNode.play()
            isRunning = true
            scheduleNextBuffer()
            scheduleNextBuffer()
            scheduleNextBuffer()
        } catch {
            print("[AudioEngine] Start fallito: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        playerNode.stop()
        engine.stop()
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
            print("[AudioEngine] AVAudioSession setup fallito: \(error)")
        }
    }

    private func setupGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle, let click = clickBuffer else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        guard let dst = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(bufferSize) { dst[i] = 0.0 }

        var offsets = [UInt32](repeating: 0, count: 16)
        let beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, 16)

        if beatCount > 0, let src = click.floatChannelData?[0] {
            let clickLen = Int(click.frameLength)
            for i in 0..<Int(beatCount) {
                let offset = Int(offsets[i])
                guard offset < Int(bufferSize) else { continue }
                let writeLen = min(clickLen, Int(bufferSize) - offset)
                for j in 0..<writeLen { dst[offset + j] += src[j] }
            }
        }

        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.global(qos: .userInteractive).async {
                self?.scheduleNextBuffer()
            }
        }
    }

    private func makeClickBuffer() -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "wav") else {
            print("[AudioEngine] click.wav non trovato nel bundle")
            return nil
        }
        do {
            let file = try AVAudioFile(forReading: url)
            let targetFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return nil }
            let converter = AVAudioConverter(from: file.processingFormat, to: targetFormat)!
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                let inputBuffer = try? AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)
                try? file.read(into: inputBuffer!)
                outStatus.pointee = .haveData
                return inputBuffer
            }
            var error: NSError?
            converter.convert(to: buffer, error: &error, withInputFrom: inputBlock)
            if let e = error {
                print("[AudioEngine] Conversione click.wav fallita: \(e)")
                return nil
            }
            return buffer
        } catch {
            print("[AudioEngine] Caricamento click.wav fallito: \(error)")
            return nil
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
        stop(); setupSession(); setupGraph(); clickBuffer = makeClickBuffer()
        if isRunning { isRunning = false; start() }
    }
}