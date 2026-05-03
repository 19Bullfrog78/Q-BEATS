#if DEBUG
import SwiftUI

struct DebugRootView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DebugView()
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { val in
                        if val.translation.width > 60 { dismiss() }
                    }
            )
    }
}
#endif
