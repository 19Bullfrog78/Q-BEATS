import SwiftUI

struct FineSetlistView: View {
    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").opacity(0.95).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("FINE SETLIST")
                    .font(.jbMono(.bold, size: 28))
                    .foregroundColor(.white)
                    .tracking(2)

                VStack(spacing: 12) {
                    Button("TORNA A SETLIST") { /* navigazione — Fase successiva */ }
                        .buttonStyle(OverlayStopButtonStyle(primary: true))
                    Button("RICOMINCIA") { /* restart setlist — Fase successiva */ }
                        .buttonStyle(OverlayStopButtonStyle(primary: false))
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
