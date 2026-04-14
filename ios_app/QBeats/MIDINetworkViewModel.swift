import Foundation
import Network

@MainActor
final class MIDINetworkViewModel: ObservableObject {
    @Published var discoveredHosts: [NWBrowser.Result] = []
    @Published var isNetworkEnabled: Bool = false

    private var browser: NWBrowser?

    func startDiscovery() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_apple-midi._tcp.", domain: "local.")
        let params = NWParameters()
        params.includePeerToPeer = true
        browser = NWBrowser(for: descriptor, using: params)
        browser?.stateUpdateHandler = { _ in }
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.discoveredHosts = Array(results)
            }
        }
        browser?.start(queue: .main)
    }

    func stopDiscovery() {
        browser?.cancel()
        browser = nil
        discoveredHosts = []
    }
}
