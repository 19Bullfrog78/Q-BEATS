import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()
            // LOTTIE_INJECTION_POINT — sostituire con LottieView(name: "qbeats_splash")
            // quando CD consegna il file JSON. Non modificare nulla intorno a questo punto.
            Text("Q-BEATS")
                .font(.custom("JetBrainsMono-Bold", size: 48))
                .foregroundColor(.white)
                .kerning(-1.5)
        }
    }
}
