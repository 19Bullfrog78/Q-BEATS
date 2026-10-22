import XCTest

// === A416 — banco del testo dell'errore della sessione audio (`AudioErrorText`, banco Models), mandato §2.4 ===
// Il codice di quattro lettere accanto al numero: `560557684` è `!int` (il codice che il sistema ha scritto il 19/10
// alle 11:55:31, referto A415 §5.6). Un codice che non è fatto di quattro caratteri stampabili dà «-».

final class AudioErrorTextTests: XCTestCase {

    func testTheCodeOf19October() {
        XCTAssertEqual(AudioErrorText.fourCharCode(560_557_684), "!int")
    }

    func testPrintableCodes() {
        XCTAssertEqual(AudioErrorText.fourCharCode(0x7768_6174), "what")
        XCTAssertEqual(AudioErrorText.fourCharCode(0x2170_7269), "!pri")
        // Uno spazio diventa «_»: nelle righe un valore non ha spazi.
        XCTAssertEqual(AudioErrorText.fourCharCode(0x6161_6320), "aac_")
    }

    func testCodesThatAreNotFourCharacters() {
        XCTAssertEqual(AudioErrorText.fourCharCode(0), "-")
        XCTAssertEqual(AudioErrorText.fourCharCode(-50), "-")
        XCTAssertEqual(AudioErrorText.fourCharCode(1), "-")
        XCTAssertEqual(AudioErrorText.fourCharCode(0x7F00_0000), "-")
        // Più di 32 bit: non è un codice di quattro lettere, anche se i byte bassi lo sarebbero.
        XCTAssertEqual(AudioErrorText.fourCharCode((1 << 40) + 560_557_684), "-")
    }

    func testTheLine() {
        XCTAssertEqual(AudioErrorText.line(domain: "NSOSStatusErrorDomain", code: 560_557_684),
                       "NSOSStatusErrorDomain codice:560557684 quattroLettere:!int")
        XCTAssertEqual(AudioErrorText.line(domain: "", code: -50), "- codice:-50 quattroLettere:-")
        XCTAssertEqual(AudioErrorText.line(domain: "un dominio", code: 0), "un_dominio codice:0 quattroLettere:-")
    }
}
