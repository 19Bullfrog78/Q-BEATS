import SwiftUI

struct TeleprompterCapsuleView: View {
    @ObservedObject var session: LiveSession

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Vedi `LiveView` per la baseline 390pt.
    let scaleFactor: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: "#16161a"))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.06), lineWidth: 1))

            switch session.playbackState {
            case .countIn(let n):
                Text("\(n)")
                    .font(.jbMono(.bold, size: 80 * scaleFactor))
                    .foregroundColor(.white)

            case .standby:
                // TD #25 — In standby il default branch finisce nel fallback BPM
                // (currentSectionName azzerato dal ramo standby di SetlistRunner)
                // e mostra il valore della sezione precedente sotto lo StandbyOverlay.
                EmptyView()

            default:
                if session.currentSectionName.isEmpty {
                    VStack(spacing: 4) {
                        Text("\(Int(session.currentBPM.rounded()))")
                            .font(.jbMono(.bold, size: 48 * scaleFactor))
                            .foregroundColor(Color.white.opacity(0.55))
                        Text("BPM")
                            .font(.jbMono(.regular, size: 11 * scaleFactor))
                            .foregroundColor(Color.white.opacity(0.25))
                            .tracking(2)
                    }
                } else {
                    let fontSize: CGFloat = (session.currentSectionName.count > 10 ? 44 : 56) * scaleFactor
                    Text(session.currentSectionName.uppercased())
                        .font(.custom("Inter-Black", size: fontSize))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
