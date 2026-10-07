import SwiftUI
import os

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
                        // SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — TRE VOCI: «Solo» (`.standalone`, il default), «Director»,
                        //    «Follower» (`LinkModeMenu`, Models/, col banco che cade se un ruolo resta senza voce). Chiude
                        //    `TD-mode-picker-senza-solo` al collaudo (BUGS: «chi sceglie Follower una volta resta con un
                        //    ruolo che non sa togliersi»). Il resto com'è: compare solo a Link acceso, bloccato in moto.
                        //    Una riga di log a ogni cambio (da → a). L'unica scrittura di `appSettings.linkMode` è qui.
                        Picker("Mode", selection: Binding(
                            get: { audioEngine.appSettings.linkMode },
                            set: { newValue in
                                let previous = audioEngine.appSettings.linkMode
                                os_log("[Q-BEATS][SOLO-M3][RUOLO] da:%{public}@ a:%{public}@",
                                       log: .default, type: .default, previous.rawValue, newValue.rawValue)
                                audioEngine.appSettings.linkMode = newValue
                            }
                        )) {
                            ForEach(LinkModeMenu.entries, id: \.mode) { entry in
                                Text(entry.title).tag(entry.mode)
                            }
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
