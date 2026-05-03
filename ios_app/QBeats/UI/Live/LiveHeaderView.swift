import SwiftUI

struct LiveHeaderView: View {
    @ObservedObject var session: LiveSession
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var appNav: AppNavigationState

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.09), lineWidth: 1))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.65))
                )
                .onTapGesture { appNav.showLive = false }

            Spacer()

            HStack(spacing: 6) {
                Text(session.currentSongName.isEmpty ? "Q-BEATS" : session.currentSongName)
                    .font(.jbMono(.bold, size: 28))
                    .foregroundColor(Color.white.opacity(0.95))
                    .lineLimit(1)

                Text("·").foregroundColor(Color.white.opacity(0.20)).font(.system(size: 13))

                HStack(spacing: 3) {
                    Text("\(Int(session.currentBPM.rounded()))")
                        .font(.jbMono(.regular, size: 17))
                        .foregroundColor(Color.white.opacity(0.50))
                    if session.isBacktrackLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                }

                Text("·").foregroundColor(Color.white.opacity(0.20)).font(.system(size: 13))

                Text(session.currentTimeSig)
                    .font(.jbMono(.regular, size: 15))
                    .foregroundColor(Color.white.opacity(0.50))
            }

            Spacer()

            // LEDs — visibili solo se connessione attiva
            HStack(spacing: 4) {
                if audioEngine.linkIsConnected {
                    Circle()
                        .fill(Color(hex: "#00c96e"))
                        .frame(width: 5, height: 5)
                }
                // btConnected / wifiConnected — stub (AudioEngine non espone ancora questi)
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.07), lineWidth: 1))
                .frame(width: 34, height: 34)
                .overlay(
                    Text("◎")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.55))
                )
                .onTapGesture { session.showMixer = true }
        }
    }
}
