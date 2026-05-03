import SwiftUI

struct RubberBtnView: View {
    let label: String
    let glyph: String
    var danger: Bool = false
    var primary: Bool = false
    var disabled: Bool = false
    var accentColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            VStack(spacing: 3) {
                Text(label)
                    .font(.jbMono(.regular, size: 8))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(labelColor)

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bgColor)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
                    if !glyph.isEmpty {
                        Text(glyph)
                            .font(glyph.count <= 3
                                ? .jbMono(.semibold, size: 18)
                                : .jbMono(.semibold, size: 13))
                            .foregroundColor(glyphColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .opacity(disabled ? 0.4 : 1.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var glyphColor: Color {
        if let ac = accentColor { return ac }
        return danger ? Color(hex: "#ff3b30") : disabled ? Color.white.opacity(0.22) : .white
    }
    private var labelColor: Color {
        danger ? Color(hex: "#ff3b30").opacity(0.75) : disabled ? Color.white.opacity(0.18) : Color.white.opacity(0.28)
    }
    private var bgColor: Color {
        if let ac = accentColor { return ac.opacity(0.08) }
        return danger ? Color(hex: "#ff3b30").opacity(0.10) : primary ? Color.white.opacity(0.10) : Color(hex: "#181820")
    }
    private var borderColor: Color {
        if let ac = accentColor { return ac.opacity(0.6) }
        return danger ? Color(hex: "#ff3b30").opacity(0.25) : disabled ? Color.white.opacity(0.05) : Color.white.opacity(0.08)
    }
}
