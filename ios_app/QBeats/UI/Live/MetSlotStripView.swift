import SwiftUI

struct MetSlotStripView: View {
    let pattern: [String]   // "accent" | "beat" | "subdiv"
    let beatActive: Int     // 1-based, 0 = nessuno

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { i, stato in
                let active = (i + 1) == beatActive
                SlotBar(stato: stato, active: active)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(hex: "#16161a"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

private struct SlotBar: View {
    let stato: String
    let active: Bool

    var body: some View {
        let height: CGFloat = stato == "accent" ? 18 : stato == "subdiv" ? 8 : 14
        let bg: Color = active
            ? (stato == "accent" ? Color(hex: "#d43f00") : stato == "subdiv" ? Color.white.opacity(0.55) : Color.white.opacity(0.92))
            : Color.white.opacity(0.07)
        let opacity: Double = active ? 1.0 : (stato == "accent" ? 0.6 : stato == "subdiv" ? 0.4 : 0.5)

        return Rectangle()
            .fill(bg)
            .frame(height: height)
            .cornerRadius(3)
            .opacity(opacity)
            .shadow(color: active && stato == "accent" ? Color(hex: "#d43f00").opacity(0.6) : .clear, radius: 4)
    }
}
