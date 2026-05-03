import SwiftUI

struct StandbyOverlayView: View {
    let nextSongName: String
    @State private var pulseOpacity: Double = 0.45

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer().frame(height: geo.size.height * 0.27)
                Text(nextSongName.uppercased())
                    .font(.custom("Inter-Black", size: 52))
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
