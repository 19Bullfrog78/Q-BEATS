import SwiftUI

struct FineSetlistView: View {
    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Propagato a `OverlayStopButtonStyle` con lo stesso valore ricevuto
    /// da `LiveView` (denominatore 390pt unico in tutta la Vista LIVE).
    let scaleFactor: CGFloat

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()
            VStack(spacing: 24) {
                Text("FINE SHOW")
                    .font(.jbMono(.bold, size: 28 * scaleFactor))
                    .foregroundColor(.white)
                    .tracking(2)

                VStack(spacing: 12) {
                    Button("TORNA AGLI SHOWS") { /* navigazione — Fase successiva */ }
                        .buttonStyle(OverlayStopButtonStyle(primary: true, scaleFactor: scaleFactor))
                    Button("RICOMINCIA") { /* restart setlist — Fase successiva */ }
                        .buttonStyle(OverlayStopButtonStyle(primary: false, scaleFactor: scaleFactor))
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
