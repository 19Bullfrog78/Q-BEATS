import SwiftUI

struct MicroSegBarView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    var body: some View {
        let segs = max(total, 1)
        let isPlaying: Bool = {
            if case .playing = state { return true }
            return false
        }()
        HStack(spacing: 3) {
            ForEach(0..<segs, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill((isPlaying && i < current) ? Color.white.opacity(0.85) : Color.white.opacity(0.07))
                    .frame(height: 5)
            }
        }
    }
}

struct MacroBarView: View {
    let current: Int
    let total: Int
    let state: LivePlaybackState

    var body: some View {
        let t = max(total, 1)
        let step = t > 32 ? Int(ceil(Double(t) / 32.0)) : 1
        let segs = Int(ceil(Double(t) / Double(step)))
        let filled = Int(ceil(Double(current) / Double(step)))

        HStack(spacing: 2) {
            ForEach(0..<segs, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < filled ? Color.white.opacity(0.65) : Color.white.opacity(0.09))
                    .frame(height: 3)
            }
        }
    }
}
