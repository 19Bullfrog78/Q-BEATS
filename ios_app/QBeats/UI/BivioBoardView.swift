import SwiftUI
import os

struct BivioBoardView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var audioEngine: AudioEngine
    #if DEBUG
    @State private var showDebug = false
    #endif

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
                        audioEngine.triggerDNDReminderIfNeeded()
                        let vc = FullBleedHostingController(rootView: LiveView().environmentObject(audioEngine))
                        vc.modalPresentationStyle = .overFullScreen
                        UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.windows.first?
                            .rootViewController?
                            .present(vc, animated: false)
                    } label: {
                        BivioButton(title: "LIVE", background: Color(hex: "#d43f00"), isAccent: true)
                    }
                }
                .padding(.horizontal, 40)

                #if DEBUG
                Button("⚙ DEBUG") {
                    showDebug = true
                }
                .foregroundColor(Color.white.opacity(0.30))
                .font(.system(size: 13, design: .monospaced))
                .padding(.top, 16)
                #endif

                Spacer()
            }
        }
        .onAppear {
            audioEngine.stop()
        }
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .fullScreenCover(isPresented: $showDebug, onDismiss: {
            audioEngine.stop()
        }) {
            ZStack(alignment: .topTrailing) {
                ContentView()
                Button("✕  BIVIO") {
                    showDebug = false
                }
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.40))
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
        }
        #endif
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
