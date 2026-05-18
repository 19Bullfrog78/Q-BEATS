import SwiftUI

struct TransportView: View {
    @ObservedObject var session: LiveSession
    let audioEngine: AudioEngine
    @EnvironmentObject var runner: SetlistRunner

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato a tutti i `RubberBtnView` per scalare label e glyph.
    let scaleFactor: CGFloat

    private var isCountIn: Bool {
        if case .countIn = session.playbackState { return true }
        return false
    }
    private var isStandby: Bool {
        if case .standby = session.playbackState { return true }
        return false
    }
    private var isStopped: Bool { session.playbackState == .stopped }
    @State private var killFlashing = false

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                RubberBtnView(label: "prev sez", glyph: "◀",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.prevSection() }

                RubberBtnView(
                    label: isCountIn ? "stop" : (audioEngine.isPlaying ? "stop" : "play"),
                    glyph: isCountIn ? "■" : (audioEngine.isPlaying ? "■" : "▶"),
                    primary: !isStopped,
                    disabled: isStandby,
                    scaleFactor: scaleFactor) {
                        if audioEngine.isPlaying {
                            audioEngine.stop()
                        } else {
                            runner.startSetlist(audioEngine: audioEngine, session: session)
                        }
                }

                RubberBtnView(label: "next sez", glyph: "▶▶",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.nextSection() }
            }

            HStack(spacing: 6) {
                RubberBtnView(label: loopLabel, glyph: "↺",
                    disabled: isCountIn || isStandby,
                    scaleFactor: scaleFactor) { audioEngine.toggleLoop() }

                RubberBtnView(
                    label: "",
                    glyph: "KILL\nBASE",
                    disabled: isCountIn || isStandby,
                    accentColor: killFlashing ? Color(hex: "#f5b820") : nil,
                    scaleFactor: scaleFactor
                ) {
                    audioEngine.stopBacktrack()
                    withAnimation(.easeInOut(duration: 0.4)) { killFlashing = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.4)) { killFlashing = false }
                    }
                }

                RubberBtnView(label: "emerg", glyph: "⚠", danger: true,
                    disabled: false,
                    scaleFactor: scaleFactor) { /* navigazione Vista LISTA — Fase successiva */ }
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
