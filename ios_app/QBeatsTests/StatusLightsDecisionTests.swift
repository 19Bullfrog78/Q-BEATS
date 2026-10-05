import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco delle spie (banco Models) ===
// Link spento dall'utente, nessuna spia «Link»; collegato, verde; mai collegato, grigio; visto e
// perso, ambra e «Link lost»; con anche il Wi-Fi visto e perso, «Link lost · no Wi-Fi»; Wi-Fi visto
// e perso a Link spento, ambra senza striscia; MIDI visto e perso, ambra.

final class StatusLightsDecisionTests: XCTestCase {

    private func lights(user: Bool = true, link: Bool = false, wifi: Bool = false, midi: Bool = false,
                        seenLink: Bool = false, seenWifi: Bool = false, seenMidi: Bool = false) -> StatusLights {
        StatusLightsDecision.lights(linkUserEnabled: user,
                                    linkConnected: link,
                                    wifiConnected: wifi,
                                    midiConnected: midi,
                                    memory: ShowConnectionMemory(linkSeen: seenLink, wifiSeen: seenWifi, midiSeen: seenMidi))
    }

    func testTheFaceRuleLiterally() {
        XCTAssertEqual(StatusLightsDecision.face(connected: true,  seen: false), .connected)
        XCTAssertEqual(StatusLightsDecision.face(connected: true,  seen: true),  .connected)
        XCTAssertEqual(StatusLightsDecision.face(connected: false, seen: false), .off)
        XCTAssertEqual(StatusLightsDecision.face(connected: false, seen: true),  .lost)
    }

    func testLinkOffByTheUserShowsNoLinkLight() {
        let l = lights(user: false, link: false, seenLink: true)
        XCTAssertNil(l.link)
        XCTAssertNil(l.strip)
    }

    func testLinkConnectedIsGreen() {
        let l = lights(link: true)
        XCTAssertEqual(l.link, .connected)
        XCTAssertNil(l.strip)
    }

    func testLinkNeverSeenIsGrey() {
        let l = lights(link: false, seenLink: false)
        XCTAssertEqual(l.link, .off)
        XCTAssertNil(l.strip)
    }

    func testLinkSeenAndLostIsAmberWithTheStrip() {
        let l = lights(link: false, seenLink: true)
        XCTAssertEqual(l.link, .lost)
        XCTAssertEqual(l.strip, "Link lost")
    }

    func testLinkLostWithWifiLostNamesTheWifi() {
        let l = lights(link: false, wifi: false, seenLink: true, seenWifi: true)
        XCTAssertEqual(l.link, .lost)
        XCTAssertEqual(l.wifi, .lost)
        XCTAssertEqual(l.strip, "Link lost · no Wi-Fi")
    }

    func testLinkLostWithWifiNeverSeenKeepsTheShortStrip() {
        let l = lights(link: false, wifi: false, seenLink: true, seenWifi: false)
        XCTAssertEqual(l.wifi, .off)
        XCTAssertEqual(l.strip, "Link lost")
    }

    func testLinkLostWithWifiConnectedKeepsTheShortStrip() {
        let l = lights(link: false, wifi: true, seenLink: true, seenWifi: true)
        XCTAssertEqual(l.wifi, .connected)
        XCTAssertEqual(l.strip, "Link lost")
    }

    func testWifiLostWithLinkOffByTheUserIsAmberWithoutStrip() {
        let l = lights(user: false, wifi: false, seenWifi: true)
        XCTAssertNil(l.link)
        XCTAssertEqual(l.wifi, .lost)
        XCTAssertNil(l.strip)
    }

    func testWifiLostWithLinkConnectedIsAmberWithoutStrip() {
        let l = lights(link: true, wifi: false, seenWifi: true)
        XCTAssertEqual(l.link, .connected)
        XCTAssertEqual(l.wifi, .lost)
        XCTAssertNil(l.strip, "la striscia è solo di Link")
    }

    func testMidiFaces() {
        XCTAssertEqual(lights(midi: true).midi, .connected)
        XCTAssertEqual(lights(midi: false).midi, .off)
        let lost = lights(midi: false, seenMidi: true)
        XCTAssertEqual(lost.midi, .lost)
        XCTAssertNil(lost.strip)
    }

    func testTheStripWords() {
        XCTAssertEqual(StatusLightsDecision.linkLostStrip, "Link lost")
        XCTAssertEqual(StatusLightsDecision.linkLostNoWifiStrip, "Link lost · no Wi-Fi")
    }
}
