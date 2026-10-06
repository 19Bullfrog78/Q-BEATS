import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco del ricordo «visto collegato in questo show» (banco Models) ===
// Show nuovo, tutto azzerato; visto e poi perso, resta visto; Link spento dall'app (utente acceso,
// app spento), ricordo di Link azzerato; gli altri due ricordi non ne risentono.
// A397 · SOLO-G1-PEZZO-1-M2 — BOX5 V54, decisioni 3 e 4: anche Link spento dall'UTENTE azzera il ricordo di
// Link (il banco `testLinkOffByTheUserIsNotAnAppSuspension` di M1 è rovesciato in
// `testLinkOffByTheUserForgetsLinkToo`); a show chiuso il ricordo resta `.none`.

final class ShowConnectionMemoryTests: XCTestCase {

    private func step(_ m: ShowConnectionMemory, link: Bool = false, wifi: Bool = false, midi: Bool = false,
                      user: Bool = true, app: Bool = true, showOpen: Bool = true) -> ShowConnectionMemory {
        m.updated(linkConnected: link, wifiConnected: wifi, midiConnected: midi,
                  linkUserEnabled: user, linkAppEnabled: app, showOpen: showOpen)
    }

    func testANewShowRemembersNothing() {
        XCTAssertEqual(ShowConnectionMemory.none,
                       ShowConnectionMemory(linkSeen: false, wifiSeen: false, midiSeen: false))
    }

    func testNothingConnectedStaysNothing() {
        XCTAssertEqual(step(.none), .none)
    }

    func testSeenThenLostStaysSeen() {
        let seen = step(.none, link: true, wifi: true, midi: true)
        XCTAssertEqual(seen, ShowConnectionMemory(linkSeen: true, wifiSeen: true, midiSeen: true))
        let lost = step(seen)
        XCTAssertEqual(lost, seen, "perso dopo visto: il ricordo resta")
    }

    func testEachLightIsRememberedOnItsOwn() {
        XCTAssertEqual(step(.none, link: true), ShowConnectionMemory(linkSeen: true, wifiSeen: false, midiSeen: false))
        XCTAssertEqual(step(.none, wifi: true), ShowConnectionMemory(linkSeen: false, wifiSeen: true, midiSeen: false))
        XCTAssertEqual(step(.none, midi: true), ShowConnectionMemory(linkSeen: false, wifiSeen: false, midiSeen: true))
    }

    func testLinkSwitchedOffByTheAppForgetsLinkOnly() {
        let seen = step(.none, link: true, wifi: true, midi: true)
        // Sfondo a click fermo: l'app spegne il suo interruttore, quello dell'utente resta acceso.
        let suspended = step(seen, link: false, wifi: true, midi: true, user: true, app: false)
        XCTAssertEqual(suspended, ShowConnectionMemory(linkSeen: false, wifiSeen: true, midiSeen: true))
        // Al ritorno, prima che Link si ricolleghi: ancora nessun ricordo di Link.
        let back = step(suspended, link: false, user: true, app: true)
        XCTAssertFalse(back.linkSeen)
        XCTAssertTrue(back.wifiSeen)
        XCTAssertTrue(back.midiSeen)
        // Ricollegato: visto di nuovo.
        XCTAssertTrue(step(back, link: true).linkSeen)
    }

    func testAppSuspensionWhileLinkWasNeverSeenKeepsNothingToForget() {
        XCTAssertEqual(step(.none, user: true, app: false), .none)
    }

    func testLinkOffByTheUserForgetsLinkToo() {
        // A397 · M2 — BOX5 V54, decisione 3: rovescia `testLinkOffByTheUserIsNotAnAppSuspension` di M1, che
        // teneva il ricordo a Link spento dall'utente. Uno spegnimento voluto, dell'utente come dell'app, non è
        // una perdita: il ricordo di Link si azzera; Wi-Fi e MIDI restano.
        let seen = step(.none, link: true, wifi: true, midi: true)
        let off = step(seen, link: false, wifi: true, midi: true, user: false, app: false)
        XCTAssertEqual(off, ShowConnectionMemory(linkSeen: false, wifiSeen: true, midiSeen: true))
        // Riacceso dall'utente, prima che Link si ricolleghi: ancora nessun ricordo di Link, niente «Link lost».
        XCTAssertFalse(step(off, link: false, user: true, app: true).linkSeen)
        // Ricollegato: visto di nuovo.
        XCTAssertTrue(step(off, link: true).linkSeen)
    }

    func testLinkOffByTheUserWhileLinkWasNeverSeenKeepsNothingToForget() {
        XCTAssertEqual(step(.none, user: false, app: false), .none)
        XCTAssertEqual(step(.none, wifi: true, user: false, app: false),
                       ShowConnectionMemory(linkSeen: false, wifiSeen: true, midiSeen: false))
    }

    func testAClosedShowRemembersNothing() {
        // A397 · M2 — BOX5 V54, decisione 4: tutto collegato ma show chiuso, niente si ricorda.
        XCTAssertEqual(step(.none, link: true, wifi: true, midi: true, showOpen: false), .none)
        // Un ricordo pieno con lo show chiuso torna vuoto.
        let seen = step(.none, link: true, wifi: true, midi: true)
        XCTAssertEqual(step(seen, link: true, wifi: true, midi: true, showOpen: false), .none)
        // Riaperto lo show, si riparte da zero e si rivede solo ciò che è collegato adesso.
        XCTAssertEqual(step(.none, wifi: true, showOpen: true),
                       ShowConnectionMemory(linkSeen: false, wifiSeen: true, midiSeen: false))
    }
}
