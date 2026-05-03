import SwiftUI

struct LiveRootView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()
            Text("LIVE — in costruzione")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { val in
                    if val.translation.width > 60 { dismiss() }
                }
        )
    }
}
