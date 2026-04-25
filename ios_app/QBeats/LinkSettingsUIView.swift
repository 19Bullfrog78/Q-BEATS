import SwiftUI

private struct ABLLinkSettingsSheetView: UIViewControllerRepresentable {
    let presenter: LinkSettingsPresenter

    func makeUIViewController(context: Context) -> UIViewController {
        presenter.settingsViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct LinkSettingsUIView: View {
    @ObservedObject var engine = AudioEngine.shared
    @State private var showingLinkSetup = false

    var body: some View {
        Form {
            Section("Ableton Link") {
                Toggle("Link", isOn: Binding(
                    get: { engine.linkEnabled },
                    set: { newValue in
                        if newValue,
                           let p = engine.linkSettingsPresenter,
                           !p.ablIsEnabled() {
                            showingLinkSetup = true
                        } else {
                            engine.setLinkEnabled(newValue)
                        }
                    }
                ))
                HStack {
                    Text("Peers")
                    Spacer()
                    Text("\(engine.linkPeers)")
                        .foregroundColor(engine.linkPeers > 0 ? .green : .secondary)
                        .monospacedDigit()
                }
                HStack {
                    Text("BPM")
                    Spacer()
                    Text(String(format: "%.1f", engine.currentBPM))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle("Link Settings")
        .sheet(isPresented: $showingLinkSetup, onDismiss: {
            if let p = engine.linkSettingsPresenter, p.ablIsEnabled() {
                engine.completeSetupAndEnable()
            }
        }) {
            if let p = engine.linkSettingsPresenter {
                ABLLinkSettingsSheetView(presenter: p)
            }
        }
    }
}
