import XCTest

// === A411 · SOLO-INERTE — banco del ruolo fuori dal salvataggio (banco Models), mandato §2.1 ===
// A ogni apertura il ruolo è Solo. Un salvataggio scritto fino ad A410 porta il ruolo: si legge senza
// errori, il ruolo diventa `.standalone`, i volumi restano quelli salvati. Un salvataggio nuovo non scrive
// più il ruolo. I volumi del banco sono frazioni binarie esatte (0,125 · 0,25 · 0,375 · 0,5 · 0,625 ·
// 0,75 · 0,875): l'uguaglianza non dipende da arrotondamenti di Double o Float.

final class AppSettingsRoleTests: XCTestCase {

    /// Un salvataggio come lo scriveva l'app fino ad A410: volumi non di default, e il ruolo.
    private func oldSave(role: String) -> Data {
        Data(#"{"accentVolume":0.375,"beatVolume":0.625,"subdivVolume":0.125,"clickMuted":true,"ch1Volume":0.875,"ch2Volume":0.5,"ch3Volume":0.25,"ch4Volume":0.75,"showDNDReminder":false,"linkMode":"\#(role)"}"#.utf8)
    }

    /// Lo stesso salvataggio senza il ruolo: com'è da A411.
    private let newSave = Data(#"{"accentVolume":0.375,"beatVolume":0.625,"subdivVolume":0.125,"clickMuted":true,"ch1Volume":0.875,"ch2Volume":0.5,"ch3Volume":0.25,"ch4Volume":0.75,"showDNDReminder":false}"#.utf8)

    private func assertSavedValues(_ s: AppSettings, _ context: String) {
        XCTAssertEqual(s.accentVolume, 0.375, context)
        XCTAssertEqual(s.beatVolume, 0.625, context)
        XCTAssertEqual(s.subdivVolume, 0.125, context)
        XCTAssertTrue(s.clickMuted, context)
        XCTAssertEqual(s.ch1Volume, 0.875, context)
        XCTAssertEqual(s.ch2Volume, 0.5, context)
        XCTAssertEqual(s.ch3Volume, 0.25, context)
        XCTAssertEqual(s.ch4Volume, 0.75, context)
        XCTAssertFalse(s.showDNDReminder, context)
    }

    func testOldSaveWithDirectorOpensInSoloWithTheVolumesIntact() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: oldSave(role: "direttore"))
        XCTAssertEqual(s.linkMode, .standalone)
        assertSavedValues(s, "salvataggio col Direttore")
    }

    func testOldSaveWithFollowerOpensInSoloWithTheVolumesIntact() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: oldSave(role: "collaborativa"))
        XCTAssertEqual(s.linkMode, .standalone)
        assertSavedValues(s, "salvataggio col Follower")
    }

    func testOldSaveWithSoloOpensInSolo() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: oldSave(role: "standalone"))
        XCTAssertEqual(s.linkMode, .standalone)
        assertSavedValues(s, "salvataggio col Solo")
    }

    /// Un ruolo che non esiste più non rompe la lettura: la chiave non si legge affatto.
    func testOldSaveWithAnUnknownRoleStillOpens() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: oldSave(role: "pippo"))
        XCTAssertEqual(s.linkMode, .standalone)
        assertSavedValues(s, "salvataggio con un ruolo sconosciuto")
    }

    func testNewSaveWithoutRoleOpens() throws {
        let s = try JSONDecoder().decode(AppSettings.self, from: newSave)
        XCTAssertEqual(s.linkMode, .standalone)
        assertSavedValues(s, "salvataggio nuovo")
    }

    /// Il salvataggio nuovo porta i nove campi e non il ruolo, anche col Director scelto in memoria.
    func testTheSaveNoLongerWritesTheRole() throws {
        var s = AppSettings()
        s.linkMode = .direttore
        let data = try JSONEncoder().encode(s)
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["linkMode"])
        XCTAssertEqual(Set(object.keys), ["accentVolume", "beatVolume", "subdivVolume", "clickMuted",
                                          "ch1Volume", "ch2Volume", "ch3Volume", "ch4Volume", "showDNDReminder"])
    }

    /// Scrivere e rileggere: i volumi tornano, il ruolo no.
    func testRoundTripKeepsTheVolumesAndDropsTheRole() throws {
        for role in [LinkMode.standalone, .direttore, .collaborativa] {
            var s = AppSettings()
            s.accentVolume = 0.375
            s.beatVolume = 0.625
            s.subdivVolume = 0.125
            s.clickMuted = true
            s.ch1Volume = 0.875
            s.ch2Volume = 0.5
            s.ch3Volume = 0.25
            s.ch4Volume = 0.75
            s.showDNDReminder = false
            s.linkMode = role
            let back = try JSONDecoder().decode(AppSettings.self, from: try JSONEncoder().encode(s))
            XCTAssertEqual(back.linkMode, .standalone, "ruolo scelto:\(role)")
            assertSavedValues(back, "ruolo scelto:\(role)")
        }
    }

    /// I valori di partenza non cambiano: il ruolo di un'app senza salvataggio è Solo, come prima.
    func testDefaultsAreUnchanged() {
        let s = AppSettings()
        XCTAssertEqual(s.linkMode, .standalone)
        XCTAssertEqual(s.accentVolume, 1.0)
        XCTAssertEqual(s.beatVolume, 0.8)
        XCTAssertEqual(s.subdivVolume, 0.4)
        XCTAssertFalse(s.clickMuted)
        XCTAssertEqual(s.ch1Volume, 1.0)
        XCTAssertEqual(s.ch2Volume, 1.0)
        XCTAssertEqual(s.ch3Volume, 0.0)
        XCTAssertEqual(s.ch4Volume, 0.0)
        XCTAssertTrue(s.showDNDReminder)
    }

    /// La riga di registro all'avvio legge il ruolo di un salvataggio di prima, e nient'altro.
    func testSavedRoleForTheBootLine() {
        XCTAssertEqual(AppSettings.savedRole(in: oldSave(role: "direttore")), "direttore")
        XCTAssertEqual(AppSettings.savedRole(in: oldSave(role: "collaborativa")), "collaborativa")
        XCTAssertEqual(AppSettings.savedRole(in: oldSave(role: "standalone")), "standalone")
        XCTAssertNil(AppSettings.savedRole(in: newSave))
        XCTAssertNil(AppSettings.savedRole(in: Data("non json".utf8)))
        XCTAssertNil(AppSettings.savedRole(in: Data()))
    }
}
