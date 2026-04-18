import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("networkMIDIEnabled") private var networkMIDIEnabled: Bool = false
    @ObservedObject var audioEngine: AudioEngine
    @State private var showBTMIDIPicker: Bool = false
    @State private var showLinkSettings: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Ableton Link") {
                    Toggle("Ableton Link", isOn: Binding(
                        get: { audioEngine.linkEnabled },
                        set: { audioEngine.setLinkEnabled($0) }
                    ))

                    Text(audioEngine.linkIsConnected ? "Connesso" : "Nessun peer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if audioEngine.linkEnabled {
                        Button("Impostazioni Link") {
                            showLinkSettings = true
                        }
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
            .sheet(isPresented: $showLinkSettings) {
                LinkSettingsUIView(presenter: audioEngine.makeLinkSettingsPresenter())
            }
        }
    }
}
