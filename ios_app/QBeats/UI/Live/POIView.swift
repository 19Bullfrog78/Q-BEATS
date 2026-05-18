import SwiftUI

struct POIView: View {
    let nextSection: String?
    let nextSong: String?

    /// TD #23 (17/05/2026) — fattore di scala responsive iPad v1.
    /// Vedi `LiveView` per la baseline 390pt.
    let scaleFactor: CGFloat

    var body: some View {
        HStack {
            if let next = nextSection {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("NEXT:")
                        .font(.jbMono(.semibold, size: 10 * scaleFactor))
                        .tracking(2)
                        .foregroundColor(Color.white.opacity(0.25))
                    Text(next.uppercased())
                        .font(.custom("Inter-ExtraBold", size: 34 * scaleFactor))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
            } else if let song = nextSong {
                Text("FINE · NEXT SONG: \(song.uppercased())")
                    .font(.jbMono(.semibold, size: 10 * scaleFactor))
                    .tracking(1.5)
                    .foregroundColor(Color.white.opacity(0.25))
            }
            Spacer()
        }
    }
}
