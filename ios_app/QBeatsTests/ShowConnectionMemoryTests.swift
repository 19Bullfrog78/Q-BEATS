import XCTest

// === A394 · SOLO-G1-PEZZO-1-M1 — banco del ricordo «visto collegato in questo show» (banco Models) ===
// Show nuovo, tutto azzerato; visto e poi perso, resta visto; Link spento dall'app (utente acceso,
// app spento), ricordo di Link azzerato; gli altri due ricordi non ne risentono.

final class ShowConnectionMemoryTests: XCTestCase {

    private func step(_ m: ShowConnectionMemory, link: Bool = false, wifi: Bool = false, midi: Bool = false,
                      user: Bool = true, app: Bool = true) -> ShowConnectionMemory {
        m.updated(linkConnected: link, wifiConnected: wifi, midiConnected: midi,
                  linkUserEnabled: user, linkAppEnabled: app)
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

    func testLinkOffByTheUserIsNotAnAppSuspension() {
        let seen = step(.none, link: true)
        // Utente spento e app spento insieme: non è lo spegnimento fatto dall'app; il ricordo resta
        // (la spia «Link» a Link spento dall'utente non si mostra: `StatusLightsDecision`).
        XCTAssertTrue(step(seen, link: false, user: false, app: false).linkSeen)
    }
}
