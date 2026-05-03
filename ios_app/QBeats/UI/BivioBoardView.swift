import SwiftUI
import os

struct BivioBoardView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        ZStack {
            Color(hex: "#0e0e10").ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Q-BEATS")
                    .font(.custom("JetBrainsMono-Bold", size: 28))
                    .foregroundColor(.white)
                    .padding(.top, 60)

                Spacer()

                VStack(spacing: 20) {
                    Button {
                        os_log("Bivio: STUDIO selezionato")
                        path.append(AppDestination.studio)
                    } label: {
                        BivioButton(title: "STUDIO", background: Color(hex: "#16161a"), isAccent: false)
                    }

                    Button {
                        os_log("Bivio: LIVE selezionato")
                        audioEngine.triggerDNDReminderIfNeeded() // UX-2
                        path.append(AppDestination.live)
                    } label: {
                        BivioButton(title: "LIVE", background: Color(hex: "#d43f00"), isAccent: true)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct BivioButton: View {
    let title: String
    let background: Color
    let isAccent: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(background)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isAccent ? Color.clear : Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}
