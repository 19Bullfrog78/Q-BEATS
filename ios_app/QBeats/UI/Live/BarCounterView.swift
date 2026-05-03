import SwiftUI

struct BarCounterView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    var body: some View {
        HStack {
            switch state {
            case .countIn, .standby:
                Text("— / —")
                    .font(.jbMono(.medium, size: 16))
                    .foregroundColor(Color.white.opacity(0.88))
            default:
                let isInf   = total == -1
                let isReady = total > 0 || isInf
                Group {
                    Text("Battuta ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isReady ? "\(current)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    + Text(" di ")
                        .foregroundColor(Color.white.opacity(0.88))
                    + Text(isInf ? "∞" : isReady ? "\(total)" : "—")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .font(.jbMono(.medium, size: 16))
            }
            Spacer()
        }
    }
}
