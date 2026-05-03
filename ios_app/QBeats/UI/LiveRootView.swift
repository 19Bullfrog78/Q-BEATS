import SwiftUI

struct LiveRootView: View {
    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()
            Text("LIVE — in costruzione")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
