$content = @'
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
            print("🔴 [AudioEngine] Start fallito: \(error)")
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
            try session.setPreferredIOBufferDuration(256.0 / sampleRate)
            try session.setActive(true)
        } catch {
            print("🔴 [AudioEngine] AVAudioSession setup fallito: \(error)")
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
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * 0.010)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        guard let data = buf.floatChannelData?[0] else { return nil }
        for i in 0..<Int(frameCount) {
            let t        = Double(i) / sampleRate
            let envelope = exp(-t / 0.005)
            data[i]      = Float(sin(2.0 * .pi * 1000.0 * t) * envelope * 0.8)
        }
        return buf
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
            if isRunning { isRunning = false; start() }
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
'@
[System.IO.File]::WriteAllText("$PWD\ios_app\QBeats\AudioEngine.swift", $content, [System.Text.Encoding]::UTF8)
Write-Host "--- VERIFICA FINALE ---"
Get-Content ios_app/QBeats/AudioEngine.swift | Select-String "offsets"
