import SwiftUI

struct POIView: View {
    let nextSection: String?
    let nextSong: String?

    var body: some View {
        HStack {
            if let next = nextSection {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("NEXT:")
                        .font(.jbMono(.semibold, size: 10))
                        .tracking(2)
                        .foregroundColor(Color.white.opacity(0.25))
                    Text(next.uppercased())
                        .font(.custom("Inter-ExtraBold", size: 34))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
            } else if let song = nextSong {
                Text("FINE · NEXT SONG: \(song.uppercased())")
                    .font(.jbMono(.semibold, size: 10))
                    .tracking(1.5)
                    .foregroundColor(Color.white.opacity(0.25))
            }
            Spacer()
        }
    }
}
