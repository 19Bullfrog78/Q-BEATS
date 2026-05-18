import SwiftUI

struct StandbyOverlayView: View {
    let nextSongName: String

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Ricevuto come parametro esplicito da `LiveView` per uniformità
    /// (denominatore 390pt unico per tutta la Vista LIVE). Il
    /// `GeometryReader` interno serve invece per il layout verticale
    /// (Spacer 0.27 × height) e NON va toccato.
    let scaleFactor: CGFloat

    @State private var pulseOpacity: Double = 0.45

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer().frame(height: geo.size.height * 0.27)
                Text(nextSongName.uppercased())
                    .font(.custom("Inter-Black", size: 52 * scaleFactor))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(pulseOpacity)
                    .padding(.horizontal, 20)
                Spacer()
            }
        }
        .onAppear { startPulse() }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            pulseOpacity = 1.0
        }
    }
}
