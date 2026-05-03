import SwiftUI

struct TransportView: View {
    @ObservedObject var session: LiveSession
    let audioEngine: AudioEngine

    private var isCountIn: Bool {
        if case .countIn = session.playbackState { return true }
        return false
    }
    private var isStandby: Bool {
        if case .standby = session.playbackState { return true }
        return false
    }
    private var isStopped: Bool { session.playbackState == .stopped }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                RubberBtnView(label: "prev sez", glyph: "◀",
                    disabled: isCountIn || isStandby) { audioEngine.prevSection() }

                RubberBtnView(
                    label: isCountIn ? "stop" : (audioEngine.isPlaying ? "stop" : "play"),
                    glyph: isCountIn ? "⏹" : (audioEngine.isPlaying ? "⏹" : "▶"),
                    primary: !isStopped,
                    disabled: isStandby) {
                        audioEngine.isPlaying ? audioEngine.stop() : audioEngine.start()
                }

                RubberBtnView(label: "next sez", glyph: "▶▶",
                    disabled: isCountIn || isStandby) { audioEngine.nextSection() }
            }

            HStack(spacing: 6) {
                RubberBtnView(label: loopLabel, glyph: "↺",
                    disabled: isCountIn || isStandby) { audioEngine.toggleLoop() }

                RubberBtnView(label: "stop bt", glyph: "■",
                    disabled: isCountIn || isStandby) { audioEngine.stopBacktrack() }

                RubberBtnView(label: "emerg", glyph: "⚠", danger: true,
                    disabled: false) { /* navigazione Vista LISTA — Fase successiva */ }
            }

            if !session.showMixer {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 28, height: 3)
                    .padding(.top, 4)
                    .onTapGesture { session.showMixer = true }
            }
        }
        .padding(.vertical, 6)
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { val in
                if val.translation.height < -30 { session.showMixer = true }
            }
        )
    }

    private var loopLabel: String {
        // Placeholder — binding reale a stato loop in Fase Backtrack
        "loop"
    }
}
