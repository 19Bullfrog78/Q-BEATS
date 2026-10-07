import Foundation
import CoreText

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — IL MISURATORE VERO: CORETEXT SUI CARATTERI IN BUNDLE ===
// Misura nella convenzione del foglio (`TextFit.swift`): la larghezza tipografica della riga composta da CoreText
// — avanzamenti dei glifi con la crenatura del carattere (`kern`), come fa il browser — più la spaziatura in em dopo
// ogni carattere, l'ultimo compreso. Le metriche verticali (ascendente, discendente, spazio fra le righe) le legge
// dal carattere (`CTFontGetAscent`, `CTFontGetDescent`, `CTFontGetLeading`), non si scrivono a mano.
// Fonti Apple: CTLineCreateWithAttributedString e CTLineGetTypographicBounds
// (https://developer.apple.com/documentation/coretext/ctline); CTFontCreateWithName, CTFontCopyPostScriptName,
// CTFontGetAscent/Descent/Leading (https://developer.apple.com/documentation/coretext/ctfont).
// ⚠️ `CTFontCreateWithName` non rende `nil` se il nome non c'è: rende un altro carattere. Qui il nome PostScript del
//    carattere ottenuto si confronta con quello chiesto (`resolves(_:)`): il banco coi caratteri veri lo pretende
//    uguale, e il player lo scrive nel log al montaggio.
// Niente SwiftUI, niente motore: si usa dalle viste (main) e dal banco. Le chiamate sono protette da un lucchetto.
final class CoreTextWidthMeasurer: TextWidthMeasurer {

    static let shared = CoreTextWidthMeasurer()

    private let lock = NSLock()
    private var fonts: [String: CTFont] = [:]
    private var resolved: [String: Bool] = [:]
    /// Il corpo a cui si leggono le metriche verticali (poi divise per questo).
    private let metricsSize: Double = 1000

    /// Il carattere a quel corpo; registra se il nome PostScript ottenuto è quello chiesto.
    private func font(_ name: String, size: Double) -> CTFont {
        let key = "\(name)@\(size)"
        if let f = fonts[key] { return f }
        let f = CTFontCreateWithName(name as CFString, CGFloat(size), nil)
        let got = CTFontCopyPostScriptName(f) as String
        resolved[name] = (got == name)
        fonts[key] = f
        return f
    }

    /// Vero se il carattere chiesto è davvero quello che CoreText dà (nome PostScript uguale).
    func resolves(_ fontName: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        _ = font(fontName, size: metricsSize)
        return resolved[fontName] ?? false
    }

    func width(of text: String, fontName: String, size: Double, trackingEm: Double) -> Double {
        guard !text.isEmpty else { return 0 }
        lock.lock(); defer { lock.unlock() }
        let f = font(fontName, size: size)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key(rawValue: kCTFontAttributeName as String): f]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let typographic = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        return typographic + trackingEm * size * Double(text.count)
    }

    func verticalMetrics(fontName: String) -> FontVerticalMetrics {
        lock.lock(); defer { lock.unlock() }
        let f = font(fontName, size: metricsSize)
        return FontVerticalMetrics(ascentEm: Double(CTFontGetAscent(f)) / metricsSize,
                                   descentEm: Double(CTFontGetDescent(f)) / metricsSize,
                                   lineGapEm: Double(CTFontGetLeading(f)) / metricsSize)
    }
}
