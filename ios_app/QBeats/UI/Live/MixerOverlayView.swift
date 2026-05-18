import SwiftUI

struct MixerOverlayView: View {
    @ObservedObject var session: LiveSession
    @ObservedObject var audioEngine: AudioEngine

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato esplicitamente al sub-component `MixerChannelView`
    /// (callsite font dentro il sub, niente cattura implicita).
    let scaleFactor: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                MixerChannelView(index: 0, label: "CLICK", enabled: true,              audioEngine: audioEngine, scaleFactor: scaleFactor)
                MixerChannelView(index: 1, label: "BACKT", enabled: true,              audioEngine: audioEngine, scaleFactor: scaleFactor)
                MixerChannelView(index: 2, label: "CH3",   enabled: session.isProMode, audioEngine: audioEngine, scaleFactor: scaleFactor)
                MixerChannelView(index: 3, label: "CH4",   enabled: session.isProMode, audioEngine: audioEngine, scaleFactor: scaleFactor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.21)
        .background(Color(hex: "#16161a"))
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundColor(Color.white.opacity(0.10)),
            alignment: .top
        )
        .contentShape(Rectangle())
        .onTapGesture {
            session.showMixer = false
        }
    }
}

private struct MixerChannelView: View {
    let index: Int
    let label: String
    let enabled: Bool
    @ObservedObject var audioEngine: AudioEngine

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato esplicitamente da `MixerOverlayView`.
    let scaleFactor: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.jbMono(.medium, size: 9 * scaleFactor))
                .tracking(1.2)
                .foregroundColor(enabled ? Color.white.opacity(0.55) : Color.white.opacity(0.20))

            GeometryReader { geo in
                let binding = Binding<Float>(
                    get: {
                        guard index < audioEngine.channelVolumes.count else { return 0 }
                        return audioEngine.channelVolumes[index]
                    },
                    set: { audioEngine.setChannelVolume(index + 1, volume: $0) }
                )
                Slider(value: binding, in: 0...1)
                    .rotationEffect(.degrees(-90))
                    .frame(width: geo.size.height, height: geo.size.width)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .tint(enabled ? Color.white.opacity(0.75) : Color.white.opacity(0.25))
                    .disabled(!enabled)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(enabled ? 1.0 : 0.35)
    }
}
