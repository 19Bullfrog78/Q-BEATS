import SwiftUI

struct OverlayStopView: View {
    let sectionName: String
    let songName: String
    let audioEngine: AudioEngine

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato a `OverlayStopButtonStyle` per scalare il font del bottone.
    let scaleFactor: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 16) {
                Button("Riprendi da \(sectionName)") {
                    audioEngine.resumeFromCurrentSection()
                }
                .buttonStyle(OverlayStopButtonStyle(primary: true, scaleFactor: scaleFactor))

                Button("Dall'inizio · \(songName)") {
                    audioEngine.restartCurrentSong()
                }
                .buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))
            }
            .padding(.horizontal, 32)
        }
    }
}

struct OverlayStopButtonStyle: ButtonStyle {
    let primary: Bool

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Parametro esplicito all'init (NON cattura dall'ambiente).
    /// Riusato sia da `OverlayStopView` che da `FineSetlistView` per
    /// uniformità tipografica dei bottoni overlay. Stesso `scaleFactor`
    /// ovunque (denominatore 390pt unico da `LiveView`).
    let scaleFactor: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jbMono(.bold, size: 15 * scaleFactor))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(primary ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
