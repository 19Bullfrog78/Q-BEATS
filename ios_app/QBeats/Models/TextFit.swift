import Foundation

// === SOLO-G1-PEZZO-1-M3 · A398 (07/10/2026) — IL PEZZO CHE SCRIVE IL TESTO CON L'INTERLINEA DEL FOGLIO ===
// Un pezzo solo per il Solo: la sezione di K, i nomi sui veli, la riga A e la riga di tempo e metrica dei veli
// (e, nel pezzo 3, il 190/1 del conto). Prende il posto di `SoloPrompterView` di M2, che lasciava l'interlinea del
// carattere: due righe a 42 di Inter-ExtraBold facevano 101,2 punti nel riquadro di 99,6 e l'app tagliava a una
// riga (collaudo del 06/10, P1-5; mandato M3 §2 e §3.6).
// La regola, come la dà il foglio (Solo REV18: `.p-se b` 42/1.08, `.p-vn` 80/1.02, `.p-va` 21/1.25, `.p-vt` 21/1.2,
// `.p-es` 44/1; tabella C riga i; lo script `function fit`):
//  · INTERLINEA: fra due linee di base, interlinea del foglio × corpo. Dentro la sua riga la linea di base sta come
//    nel modello CSS: lo scarto fra interlinea e altezza del carattere (ascendente + discendente) va per metà sopra
//    e per metà sotto (W3C, CSS 2.1, §10.8.1 «Leading and half-leading»: L = line-height − (A + D), metà sopra e
//    metà sotto il contenuto; https://www.w3.org/TR/CSS21/visudet.html#leading). Le metriche le legge il misuratore
//    dal carattere in bundle (`CoreTextWidthMeasurer`), non si scrivono a mano.
//  · A CAPO: sugli spazi e dopo un trattino-meno (-) già scritto; mai dentro una parola; nessun trattino aggiunto.
//    Ogni riga si riempie quanto può prima di andare a capo (il foglio non bilancia le righe). Le righe le decide
//    questo pezzo: a schermo ogni riga è una scritta che non va più a capo da sola (`FittedTextView`).
//  · LARGHEZZA DI UNA RIGA: gli avanzamenti dei glifi con la crenatura, più la spaziatura del foglio dopo ogni
//    carattere, l'ultimo compreso; lo spazio dove si va a capo non conta. Il limite è esatto (338 sui veli, 366 in
//    K): lo script del foglio tollera 1 px sulla parola sola (`e.scrollWidth>e.clientWidth+1`), l'app no (decisione
//    del referee, M3 §3.6: un nome a cavallo può uscire di 1 punto più piccolo che nello script; voluto).
//  · CORPI: a corpo fisso (la sezione di K a 42, la riga A a 21) oppure a scendere di 1 alla volta (i nomi: da 80 a
//    48) finché il testo sta nelle righe senza parole che sporgono; un corpo solo per tutte le righe.
//  · I PUNTINI: a corpo fisso, o al pavimento (48), se il testo non sta nelle righe si tengono le prime righe
//    dell'a capo e l'ultima si chiude con «…» (U+2026), togliendo caratteri dalla fine finché riga e «…» stanno nel
//    limite; una riga che sporge da sola (una parola più larga del limite) si accorcia e si chiude allo stesso modo.
//  · La regola si calcola in punti del foglio; il fattore D4 si applica al risultato (le viste scalano corpi,
//    interlinee e linee di base): corpi e righe scelti sono gli stessi su ogni apparecchio.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro. Il misuratore vero sta in
// `CoreTextWidthMeasurer` (CoreText, niente SwiftUI, niente motore); il banco usa anche un misuratore finto.

/// Le metriche verticali di un carattere, in frazioni del corpo.
struct FontVerticalMetrics: Equatable {
    /// Ascendente (sopra la linea di base), in em.
    let ascentEm: Double
    /// Discendente (sotto la linea di base), in em, positivo.
    let descentEm: Double
    /// Lo spazio fra le righe che il carattere dichiara (non usato dal foglio: vale l'interlinea del foglio).
    let lineGapEm: Double

    /// L'altezza del carattere: ascendente + discendente.
    var contentHeightEm: Double { ascentEm + descentEm }
}

/// Chi misura: la larghezza di una scritta nella convenzione del foglio (avanzamenti con la crenatura più la
/// spaziatura dopo ogni carattere, l'ultimo compreso) e le metriche verticali del carattere.
protocol TextWidthMeasurer {
    func width(of text: String, fontName: String, size: Double, trackingEm: Double) -> Double
    func verticalMetrics(fontName: String) -> FontVerticalMetrics
}

/// La veste di un pezzo di testo, per quanto serve alla misura: il carattere (nome PostScript) e la spaziatura
/// in em (`letter-spacing` del foglio). Il colore lo mette la vista.
struct TextFitStyle: Equatable {
    let fontName: String
    let trackingEm: Double
}

/// Un pezzo di testo con la sua veste (indice in `TextFitSpec.styles`).
struct TextRun: Equatable {
    let text: String
    let style: Int
}

/// Cosa scrivere e con quali regole.
struct TextFitSpec: Equatable {
    /// Le vesti; la prima dà le metriche verticali della riga.
    let styles: [TextFitStyle]
    /// Il testo, in pezzi con la loro veste, nell'ordine.
    let runs: [TextRun]
    /// Interlinea del foglio (1,02, 1,08, 1,25, 1,2, 1).
    let lineHeightFactor: Double
    /// Il limite esatto in punti del foglio.
    let maxWidth: Double
    /// Quante righe al più.
    let maxLines: Int
    /// I corpi da provare, nell'ordine: il primo che sta vince; l'ultimo è il pavimento, dove si mettono i puntini.
    let sizes: [Double]

    init(styles: [TextFitStyle], runs: [TextRun], lineHeightFactor: Double, maxWidth: Double, maxLines: Int,
         sizes: [Double]) {
        self.styles = styles
        self.runs = runs
        self.lineHeightFactor = lineHeightFactor
        self.maxWidth = maxWidth
        self.maxLines = max(1, maxLines)
        self.sizes = sizes.isEmpty ? [1] : sizes
    }

    /// I corpi a scendere di 1 da `from` a `to` (80 → 48).
    static func descending(from: Int, to: Int) -> [Double] {
        guard from >= to else { return [Double(from)] }
        return stride(from: from, through: to, by: -1).map { Double($0) }
    }
}

/// Una riga decisa: i suoi pezzi, la larghezza misurata, se è stata chiusa coi puntini.
struct FittedLine: Equatable {
    let runs: [TextRun]
    let width: Double
    let truncated: Bool

    /// Il testo della riga, i pezzi uniti.
    var text: String { runs.map { $0.text }.joined() }
}

/// Il risultato: corpo scelto, righe, interlinea, altezza del blocco e linee di base (dall'alto del blocco),
/// tutto in punti del foglio.
struct FittedText: Equatable {
    let size: Double
    let lines: [FittedLine]
    /// Interlinea × corpo: la distanza fra due linee di base e l'altezza di ogni riga.
    let lineHeight: Double
    /// Righe × interlinea.
    let height: Double
    /// La linea di base di ogni riga, dall'alto del blocco.
    let baselines: [Double]
    /// Vero se almeno una riga porta i puntini.
    let truncated: Bool
    /// Vero se il testo stava nelle righe e nel limite al corpo scelto, senza puntini.
    let fits: Bool

    var lineCount: Int { lines.count }
}

enum TextFitter {

    static let ellipsis = "\u{2026}"
    /// Tolleranza sui confronti di larghezza: solo rumore di virgola mobile, non una tolleranza del foglio.
    static let epsilon: Double = 1e-9

    // MARK: - La regola

    static func fit(_ spec: TextFitSpec, measurer: TextWidthMeasurer) -> FittedText {
        let atoms = tokenize(spec.runs)
        var chosenSize = spec.sizes[spec.sizes.count - 1]
        var chosenLines: [[Atom]] = []
        var fits = false
        for size in spec.sizes {
            let lines = wrap(atoms, size: size, spec: spec, measurer: measurer)
            chosenSize = size
            chosenLines = lines
            if lines.count <= spec.maxLines && lines.allSatisfy({ lineWidth($0, size: size, spec: spec, measurer: measurer) <= spec.maxWidth + epsilon }) {
                fits = true
                break
            }
        }
        let fitted = finish(chosenLines, size: chosenSize, spec: spec, measurer: measurer, fits: fits)
        return fitted
    }

    /// Le linee di base di `count` righe alte `lineHeight`, col modello CSS della mezza interlinea.
    static func baselines(count: Int, size: Double, lineHeight: Double, metrics: FontVerticalMetrics) -> [Double] {
        let ascent = metrics.ascentEm * size
        let descent = metrics.descentEm * size
        let halfLeading = (lineHeight - (ascent + descent)) / 2
        return (0..<max(0, count)).map { Double($0) * lineHeight + halfLeading + ascent }
    }

    // MARK: - Gli atomi: le parole, e i pezzi di parola dopo un trattino

    struct Atom: Equatable {
        let text: String
        let style: Int
        /// Prima di questo atomo c'era uno spazio (che si scrive se l'atomo non apre la riga).
        let spaceBefore: Bool
        /// La veste dello spazio (quella del pezzo da cui viene).
        let spaceStyle: Int
        /// Qui si può andare a capo: dopo uno spazio o dopo un trattino già scritto.
        let canBreakBefore: Bool
    }

    static func tokenize(_ runs: [TextRun]) -> [Atom] {
        var atoms: [Atom] = []
        var pendingSpace = false
        var pendingSpaceStyle = 0
        var afterHyphen = false
        var word = ""
        var wordStyle = 0
        func closeWord() {
            guard !word.isEmpty else { return }
            atoms.append(Atom(text: word, style: wordStyle, spaceBefore: pendingSpace, spaceStyle: pendingSpaceStyle,
                              canBreakBefore: pendingSpace || afterHyphen || atoms.isEmpty))
            afterHyphen = word.hasSuffix("-")
            pendingSpace = false
            word = ""
        }
        for run in runs {
            for ch in run.text {
                if ch == " " {
                    closeWord()
                    pendingSpace = true
                    pendingSpaceStyle = run.style
                    continue
                }
                if word.isEmpty { wordStyle = run.style }
                if wordStyle != run.style {
                    // Un cambio di veste dentro una parola: due atomi senza a capo fra loro.
                    closeWord()
                    wordStyle = run.style
                }
                word.append(ch)
                if ch == "-" {
                    closeWord()
                }
            }
            closeWord()
        }
        return atoms
    }

    // MARK: - L'a capo

    static func wrap(_ atoms: [Atom], size: Double, spec: TextFitSpec, measurer: TextWidthMeasurer) -> [[Atom]] {
        var lines: [[Atom]] = []
        var current: [Atom] = []
        for atom in atoms {
            if current.isEmpty {
                current = [atom]
                continue
            }
            if atom.canBreakBefore {
                let candidate = current + [atom]
                if lineWidth(candidate, size: size, spec: spec, measurer: measurer) <= spec.maxWidth + epsilon {
                    current = candidate
                } else {
                    lines.append(current)
                    current = [atom]
                }
            } else {
                current.append(atom)
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    /// I pezzi di una riga, con la loro veste: lo spazio prima di un atomo si scrive se l'atomo non apre la riga,
    /// nella veste del pezzo da cui viene; gli atomi della stessa veste si uniscono (la crenatura fra loro vale).
    static func fragments(_ line: [Atom]) -> [TextRun] {
        var out: [TextRun] = []
        func append(_ text: String, style: Int) {
            if let last = out.last, last.style == style {
                out[out.count - 1] = TextRun(text: last.text + text, style: style)
            } else {
                out.append(TextRun(text: text, style: style))
            }
        }
        for (i, atom) in line.enumerated() {
            if i > 0 && atom.spaceBefore { append(" ", style: atom.spaceStyle) }
            append(atom.text, style: atom.style)
        }
        return out
    }

    static func width(of runs: [TextRun], size: Double, spec: TextFitSpec, measurer: TextWidthMeasurer) -> Double {
        guard !spec.styles.isEmpty else { return 0 }
        return runs.reduce(0.0) { acc, run in
            let style = spec.styles[min(max(run.style, 0), spec.styles.count - 1)]
            return acc + measurer.width(of: run.text, fontName: style.fontName, size: size, trackingEm: style.trackingEm)
        }
    }

    static func lineWidth(_ line: [Atom], size: Double, spec: TextFitSpec, measurer: TextWidthMeasurer) -> Double {
        width(of: fragments(line), size: size, spec: spec, measurer: measurer)
    }

    // MARK: - I puntini e il risultato

    static func finish(_ lines: [[Atom]], size: Double, spec: TextFitSpec, measurer: TextWidthMeasurer, fits: Bool) -> FittedText {
        let kept = Array(lines.prefix(spec.maxLines))
        let dropped = lines.count > spec.maxLines
        var out: [FittedLine] = []
        for (i, line) in kept.enumerated() {
            var runs = fragments(line)
            var w = width(of: runs, size: size, spec: spec, measurer: measurer)
            let needsEllipsis = (i == kept.count - 1 && dropped) || w > spec.maxWidth + epsilon
            if needsEllipsis {
                runs = truncate(runs, size: size, spec: spec, measurer: measurer)
                w = width(of: runs, size: size, spec: spec, measurer: measurer)
            }
            out.append(FittedLine(runs: runs, width: w, truncated: needsEllipsis))
        }
        let lineHeight = spec.lineHeightFactor * size
        let metricsFont = spec.styles.first?.fontName ?? ""
        let metrics = measurer.verticalMetrics(fontName: metricsFont)
        return FittedText(size: size,
                          lines: out,
                          lineHeight: lineHeight,
                          height: Double(out.count) * lineHeight,
                          baselines: baselines(count: out.count, size: size, lineHeight: lineHeight, metrics: metrics),
                          truncated: out.contains { $0.truncated },
                          fits: fits && !dropped)
    }

    /// Toglie caratteri dalla fine finché riga e «…» stanno nel limite; gli spazi in coda non restano davanti ai
    /// puntini. Totale: al limite resta «…» da solo.
    static func truncate(_ runs: [TextRun], size: Double, spec: TextFitSpec, measurer: TextWidthMeasurer) -> [TextRun] {
        var body = runs
        while true {
            // Via gli spazi in coda.
            while let last = body.last {
                let trimmed = String(last.text.reversed().drop(while: { $0 == " " }).reversed())
                if trimmed.isEmpty {
                    body.removeLast()
                } else if trimmed != last.text {
                    body[body.count - 1] = TextRun(text: trimmed, style: last.style)
                    break
                } else {
                    break
                }
            }
            let ellipsisStyle = body.last?.style ?? (runs.last?.style ?? 0)
            var candidate = body
            if let last = candidate.last {
                candidate[candidate.count - 1] = TextRun(text: last.text + ellipsis, style: last.style)
            } else {
                candidate = [TextRun(text: ellipsis, style: ellipsisStyle)]
            }
            if width(of: candidate, size: size, spec: spec, measurer: measurer) <= spec.maxWidth + epsilon || body.isEmpty {
                return candidate
            }
            // Un carattere in meno dalla fine.
            if let last = body.last {
                let shorter = String(last.text.dropLast())
                if shorter.isEmpty {
                    body.removeLast()
                } else {
                    body[body.count - 1] = TextRun(text: shorter, style: last.style)
                }
            }
        }
    }
}
