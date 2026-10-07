import XCTest

// === A398 · SOLO-G1-PEZZO-1-M3 — banco delle voci del selettore «Mode» (banco Models) ===
// Tutte le voci di `LinkMode` ci sono, con le loro parole e nell'ordine del mandato (il default per primo); il
// banco cade se un ruolo resta senza voce (BUGS, `TD-mode-picker-senza-solo`).

final class LinkModeMenuTests: XCTestCase {

    func testEveryRoleHasExactlyOneEntry() {
        let modes = LinkModeMenu.entries.map { $0.mode }
        XCTAssertEqual(Set(modes), Set(LinkMode.allCases), "un ruolo senza voce, o una voce senza ruolo")
        XCTAssertEqual(modes.count, LinkMode.allCases.count)
        XCTAssertEqual(Set(modes).count, modes.count, "nessun ruolo due volte")
        XCTAssertEqual(LinkMode.allCases.count, 3)
    }

    func testTheWordsAndTheOrder() {
        XCTAssertEqual(LinkModeMenu.entries.map { $0.title }, ["Solo", "Director", "Follower"])
        XCTAssertEqual(LinkModeMenu.entries.map { $0.mode }, [.standalone, .direttore, .collaborativa])
        XCTAssertEqual(LinkModeMenu.entries.first?.mode, .standalone, "il default per primo")
        XCTAssertEqual(LinkModeMenu.title(for: .standalone), "Solo")
        XCTAssertEqual(LinkModeMenu.title(for: .direttore), "Director")
        XCTAssertEqual(LinkModeMenu.title(for: .collaborativa), "Follower")
    }
}
