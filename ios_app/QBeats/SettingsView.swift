import SwiftUI

private struct ABLLinkSettingsSheetView: UIViewControllerRepresentable {
    let presenter: LinkSettingsPresenter

    func makeUIViewController(context: Context) -> UIViewController {
        presenter.settingsViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("networkMIDIEnabled") private var networkMIDIEnabled: Bool = false
    @ObservedObject var audioEngine: AudioEngine
    @State private var showBTMIDIPicker: Bool = false
    @State private var showLinkSetup: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Ableton Link") {
                    Toggle("Link", isOn: Binding(
                        get: { audioEngine.linkEnabled },
                        set: { newValue in
                            if newValue,
                               let p = audioEngine.linkSettingsPresenter,
                               !p.ablIsEnabled() {
                                showLinkSetup = true
                            } else {
                                audioEngine.setLinkEnabled(newValue)
                            }
                        }
                    ))
                    HStack {
                        Text("Peers")
                        Spacer()
                        Text("\(audioEngine.linkPeers)")
                            .foregroundColor(audioEngine.linkPeers > 0 ? .green : .secondary)
                            .monospacedDigit()
                    }
                    HStack {
                        Text("BPM")
                        Spacer()
                        Text(String(format: "%.1f", audioEngine.currentBPM))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                }

                Section("MIDI Connections") {
                    Toggle("Network MIDI (WiFi)", isOn: $networkMIDIEnabled)
                        .onChange(of: networkMIDIEnabled) { enabled in
                            if enabled {
                                audioEngine.enableNetworkMIDI()
                            } else {
                                audioEngine.disableNetworkMIDI()
                            }
                        }

                    Button("Bluetooth MIDI") {
                        showBTMIDIPicker = true
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBTMIDIPicker) {
                BTMIDICentralPickerView()
            }
            .sheet(isPresented: $showLinkSetup, onDismiss: {
                if let p = audioEngine.linkSettingsPresenter, p.ablIsEnabled() {
                    audioEngine.completeSetupAndEnable()
                }
            }) {
                if let p = audioEngine.linkSettingsPresenter {
                    ABLLinkSettingsSheetView(presenter: p)
                }
            }
        }
    }
}
