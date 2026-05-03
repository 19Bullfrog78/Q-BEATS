import SwiftUI

struct OverlayStopView: View {
    let sectionName: String
    let songName: String
    let audioEngine: AudioEngine

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 16) {
                Button("Riprendi da \(sectionName)") {
                    audioEngine.resumeFromCurrentSection()
                }
                .buttonStyle(OverlayStopButtonStyle(primary: true))

                Button("Dall'inizio · \(songName)") {
                    audioEngine.restartCurrentSong()
                }
                .buttonStyle(OverlayStopButtonStyle(primary: false))
            }
            .padding(.horizontal, 32)
        }
    }
}

struct OverlayStopButtonStyle: ButtonStyle {
    let primary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.jbMono(.bold, size: 15))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(primary ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
