import SwiftUI

struct BarCounterView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Vedi `LiveView` per la baseline 390pt.
    let scaleFactor: CGFloat

    var body: some View {
        HStack {
            switch state {
            case .countIn, .standby:
                Text("— / —")
                    .font(.jbMono(.medium, size: 16 * scaleFactor))
                    .foregroundColor(Color.white.opacity(0.88))
            default:
                let isInf   = total == -1
                let isReady = total > 0 || isInf
                Group {
                    Text("Bar ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isReady ? "\(current)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    + Text(" of ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isInf ? "∞" : isReady ? "\(total)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.jbMono(.medium, size: 16 * scaleFactor))
            }
            Spacer()
        }
    }
}
