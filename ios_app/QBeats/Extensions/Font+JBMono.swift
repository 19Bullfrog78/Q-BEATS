import SwiftUI

extension Font {
    static func jbMono(_ weight: Font.Weight, size: CGFloat) -> Font {
        let name: String
        switch weight {
        case .bold:     name = "JetBrainsMono-Bold"
        case .semibold: name = "JetBrainsMono-SemiBold"
        case .medium:   name = "JetBrainsMono-Medium"
        default:        name = "JetBrainsMono-Regular"
        }
        return .custom(name, size: size)
    }
}
