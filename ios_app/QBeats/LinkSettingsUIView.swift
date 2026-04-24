import SwiftUI

struct LinkSettingsUIView: View {
    @ObservedObject var engine = AudioEngine.shared

    var body: some View {
        Form {
            Section("Ableton Link") {
                Toggle("Link", isOn: Binding(
                    get: { engine.linkEnabled },
                    set: { engine.setLinkEnabled($0) }
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
    }
}
