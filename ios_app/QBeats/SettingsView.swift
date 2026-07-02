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
                SwiftUI.Section("Ableton Link") {
                    Button("Ableton Link") {
                        showLinkSetup = true
                    }
                    if audioEngine.linkEnabled {
                        Picker("Mode", selection: Binding(
                            get: { audioEngine.appSettings.linkMode },
                            set: { newValue in
                                audioEngine.appSettings.linkMode = newValue
                            }
                        )) {
                            Text("Director").tag(LinkMode.direttore)
                            Text("Follower").tag(LinkMode.collaborativa)
                        }
                        .pickerStyle(.menu)
                        .disabled(audioEngine.isPlaying)
                        HStack {
                            Text("Peers")
                            Spacer()
                            Text(audioEngine.linkIsConnected ? "Connected" : "Standalone")
                                .foregroundColor(audioEngine.linkIsConnected ? .green : .secondary)
                        }
                        HStack {
                            Text("BPM")
                            Spacer()
                            Text(String(format: "%.1f", audioEngine.currentBPM))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                        }
                    }
                }

                SwiftUI.Section("Audio") {
                    Toggle("Show Airplane Mode / Do Not Disturb reminder", isOn: Binding(
                        get: { audioEngine.appSettings.showDNDReminder },
                        set: { audioEngine.setShowDNDReminder($0) }
                    ))
                }

                SwiftUI.Section("MIDI Connections") {
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
                guard let p = audioEngine.linkSettingsPresenter else { return }
                audioEngine.setLinkEnabled(p.ablIsEnabled())
            }) {
                if let p = audioEngine.linkSettingsPresenter {
                    ABLLinkSettingsSheetView(presenter: p)
                }
            }
        }
    }
}
