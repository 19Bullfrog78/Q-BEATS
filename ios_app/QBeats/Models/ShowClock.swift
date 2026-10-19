import Foundation

// === A410 (16/10/2026) — IL CONTEGGIO IN SILENZIO: DOVE STA LA BAND, DA UN'ÀNCORA E DALLA MAPPA ===
// Il fatto (referto A409, §6.3 e §8.3). Quando il motore di un apparecchio tace a canzone in corso
// (un'interruzione di sistema, i servizi audio persi), la band continua: la griglia di Link non si
// ferma (`ABLLink.h:12-17`) e la canzone avanza sezione dopo sezione. Per rientrare nel punto
// esatto l'apparecchio deve sapere, in ogni momento, dove sta la band: sezione, battuta, battito.
// Link non lo dice (dà la fase rispetto a un quantum, non la battuta: `ABLLink.h:277-290`); lo dice
// il conto fatto sulla struttura della canzone a partire da un'àncora.
//
// L'ÀNCORA (A376 §2.1, P1): un battito della canzone uscito davvero prima del silenzio — sezione e
// battito nella sezione — con la sua ora d'uscita e il battito di Link a quell'ora. ⚠️ RISCRITTO A412 ·
// SEGUITO 2 (18/10/2026). Il testo di prima diceva «letto con quantum 1, cioè sulla griglia condivisa»: a
// quantum 1 è condivisa la fase, non la parte intera, che un cambio di tempo fatto da un altro può
// rinumerare di un battito (collaudo di A412 delle 16:24; `ABLLink.h:280-286`). Il motore legge ora il
// battito nella numerazione della sessione (`DirectorRejoinDecision.sessionQuantum`); il tipo non sa
// quale numerazione riceve, gli basta che àncora e adesso siano nella stessa. Da lì, due righelli:
//  · BATTITI DI LINK (primario, A376 P2): la sessione e la canzone avanzano allo stesso tempo, quindi
//    i battiti di Link passati dall'àncora sono i battiti della canzone passati dall'àncora, e la
//    deriva fra gli orologi non entra. Vale finché il tempo della sessione segue la canzone (W2 dei
//    Follower in sync; LIBRO 2026-09-18, «strada 2 e poi strada 3»);
//  · SECONDI SULLA MAPPA (controllo): l'ora passata dall'àncora, camminata sezione per sezione col
//    tempo scritto nella mappa.
// Se i due righelli si discostano oltre un ottavo di battito (A376 §2.3, P7) il conto NON è certo:
// chi lo usa non deve né entrare né fermare niente (decisione di Mauro del 16/10/2026, D4 = (a)).
// Esiti: dentro la canzone (sezione, battuta, battito, il battito di Link del prossimo «uno»),
// canzone finita (il battito di Link e l'ora della fine), «non so» (un ciclo attraversato: i loop
// restano ciechi, decisione del 29/08/2026; oppure valori non validi).
//
// Il tipo non sa chi lo usa: niente qui è solo del Direttore (scelta T13 del referee sul referto
// A409: lo stesso conto servirà al Follower, passi 2B e 2C del progetto A376).
// La mappa è quella che il motore carica (`AudioEngine.loadSection`): per ogni sezione battiti per
// battuta, ripetizioni (= battute) e tempo; ripetizioni <= 0 = ciclo, il motore non conta.
// Gli indici di sezione e di battito nella sezione partono da 0 (`SetlistRunner.currentSectionIdx`,
// `AudioEngine._sectionBeatCounter` prima del suo incremento); battuta e battito nella battuta, da 1.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Una sezione della mappa della canzone.
struct SongMapSection: Equatable {
    /// Battiti per battuta.
    let beatsPerBar: Int
    /// Battute della sezione: le «ripetizioni» di `SongSection`. <= 0 = ciclo (loop infinito).
    let repetitions: Int
    /// Tempo della sezione, battiti al minuto.
    let bpm: Double

    /// Ciclo: il motore non conta (`AudioEngine.loadSection`, totale a 0) e la sezione non finisce.
    var isCycle: Bool { repetitions <= 0 }

    /// Battiti della sezione, come `_sectionTotalBeats` del motore: 0 per un ciclo, `nil` se il
    /// prodotto battute × battiti per battuta trabocca.
    var totalBeats: Int? {
        if isCycle { return 0 }
        let (product, overflow) = repetitions.multipliedReportingOverflow(by: beatsPerBar)
        return overflow ? nil : product
    }
}

/// La mappa della canzone: le sue sezioni, nell'ordine.
struct SongMap: Equatable {
    let sections: [SongMapSection]

    /// Il tetto dei battiti di una sezione: 2^40, mille miliardi. Una canzone vera ne ha qualche
    /// centinaio; il tetto tiene ogni conto lontano dai bordi di `Int` e di `Double`.
    static let maxSectionBeats: Int = 1 << 40

    /// Usabile per il conto: almeno una sezione; in ogni sezione almeno un battito per battuta; in
    /// ogni sezione che non è un ciclo, battiti di sezione senza traboccare e sotto il tetto, e tempo
    /// finito e positivo.
    var isValid: Bool {
        guard !sections.isEmpty else { return false }
        for section in sections {
            guard section.beatsPerBar >= 1 else { return false }
            if section.isCycle { continue }
            guard let total = section.totalBeats, total <= SongMap.maxSectionBeats,
                  section.bpm.isFinite, section.bpm > 0 else { return false }
        }
        return true
    }
}

extension SongMap {
    /// La mappa di una canzone di Q-Stage, dalle sue sezioni.
    init(songSections: [SongSection]) {
        self.init(sections: songSections.map {
            SongMapSection(beatsPerBar: Int($0.beatsPerBar), repetitions: $0.repetitions, bpm: $0.bpm)
        })
    }
}

/// L'àncora del conto: un battito della canzone, la sua ora d'uscita e dove stava su Link.
struct ShowClockAnchor: Equatable {
    /// Indice della sezione nella mappa, da 0.
    let section: Int
    /// Indice del battito nella sezione, da 0: (battuta − 1) × battiti per battuta + (battito − 1).
    let beatInSection: Int
    /// Il battito di Link all'ora del battito, nella numerazione con cui si leggerà «adesso».
    /// ⚠️ RISCRITTO A412 · SEGUITO 2: diceva «(quantum 1)»; il motore passa la numerazione della sessione.
    let linkBeat: Double
    /// L'ora d'uscita del battito, in tick dell'orologio dell'apparecchio.
    let ticks: UInt64
}

/// Perché il conto non dà un posto.
enum ShowClockUnknown: Equatable {
    /// Mappa vuota, battiti per battuta < 1, battiti di sezione che traboccano, tempo non valido.
    case invalidMap
    /// L'àncora cade fuori dalla mappa (sezione o battito).
    case invalidAnchor
    /// Un valore d'ingresso non finito, o tick al secondo non validi.
    case invalidInput
    /// Un ciclo: l'àncora sta in un ciclo, oppure il cammino ne raggiunge uno.
    case cycle
    /// Il punto chiesto cade prima dell'inizio della sezione dell'àncora.
    case beforeAnchorSection
}

/// Dove sta la band per un righello.
enum ShowClockPlace: Equatable {
    /// Dentro la canzone: sezione e battiti, con la frazione, dall'inizio della sezione.
    case inSong(section: Int, beatInSection: Double)
    /// Oltre l'ultimo battito della canzone, di tanti battiti.
    case pastEnd(beats: Double)
    /// Non si sa.
    case unknown(ShowClockUnknown)

    /// Un posto c'è (dentro o oltre la canzone): i due righelli si possono confrontare.
    var isLocated: Bool {
        switch self {
        case .inSong, .pastEnd: return true
        case .unknown: return false
        }
    }
}

/// La risposta di un righello: i battiti della canzone passati dall'àncora (negativi prima
/// dell'àncora) e il posto.
struct ShowClockRuler: Equatable {
    let beatsFromAnchor: Double
    let place: ShowClockPlace
}

/// Un inizio di battuta («uno») della canzone e il suo battito di Link.
struct ShowClockDownbeat: Equatable {
    let section: Int
    /// Battuta nella sezione, da 1.
    let bar: Int
    /// Indice del battito nella sezione, da 0: (bar − 1) × battiti per battuta.
    let beatInSection: Int
    let linkBeat: Double
}

/// La ricerca di un «uno».
enum ShowClockDownbeatSearch: Equatable {
    case found(ShowClockDownbeat)
    /// La canzone finisce prima del primo «uno» cercato.
    case songEndsFirst
    case unknown(ShowClockUnknown)
}

/// L'esito del conto, dal righello primario (battiti di Link).
enum ShowClockOutcome: Equatable {
    /// Dentro la canzone: sezione (da 0), battuta e battito (da 1), il prossimo «uno» dopo adesso
    /// (`nil` se la canzone finisce prima, o se il prossimo «uno» cade in un ciclo).
    case inSong(section: Int, bar: Int, beat: Int, nextDownbeat: ShowClockDownbeat?)
    /// Canzone finita: il battito di Link della fine e l'ora della fine sulla mappa (`nil` con tick
    /// al secondo non validi).
    case songEnded(endLinkBeat: Double, endTicks: UInt64?)
    case unknown(ShowClockUnknown)
}

/// Una lettura del conto: i due righelli, il loro scarto e l'esito.
struct ShowClockReading: Equatable {
    let byLinkBeats: ShowClockRuler
    let bySeconds: ShowClockRuler
    /// Battiti di Link meno secondi sulla mappa, in battiti della canzone. `nil` se uno dei due non
    /// dà un posto.
    let gapBeats: Double?
    /// I due righelli danno un posto e si discostano al più della tolleranza.
    let certain: Bool
    let outcome: ShowClockOutcome
}

struct ShowClock: Equatable {

    /// Oltre questo scarto fra i due righelli il conto non è certo: un ottavo di battito (A376 P7).
    static let defaultToleranceBeats: Double = 0.125
    /// «Dopo adesso» per il prossimo «uno»: un millesimo di millesimo di battito, così un «uno»
    /// che cade esattamente adesso non conta.
    static let nextDownbeatLead: Double = 1e-6
    /// Margine sugli arrotondamenti quando si cerca un inizio di battuta.
    private static let epsilon: Double = 1e-9

    let map: SongMap
    let anchor: ShowClockAnchor
    let toleranceBeats: Double

    init(map: SongMap, anchor: ShowClockAnchor, toleranceBeats: Double = ShowClock.defaultToleranceBeats) {
        self.map = map
        self.anchor = anchor
        self.toleranceBeats = toleranceBeats
    }

    /// Perché il conto non si può fare, o `nil` se si può.
    var invalidity: ShowClockUnknown? {
        guard map.isValid else { return .invalidMap }
        guard anchor.section >= 0, anchor.section < map.sections.count else { return .invalidAnchor }
        if map.sections[anchor.section].isCycle { return .cycle }
        guard anchor.beatInSection >= 0, anchor.beatInSection < sectionBeats(anchor.section) else {
            return .invalidAnchor
        }
        guard anchor.linkBeat.isFinite else { return .invalidInput }
        return nil
    }

    /// Battiti della sezione `index`. Solo dopo `invalidity == nil` (mappa valida, indice in mappa).
    private func sectionBeats(_ index: Int) -> Int {
        map.sections[index].totalBeats ?? 0
    }

    // MARK: Il righello dei battiti di Link

    /// Dove sta la band `beats` battiti della canzone dopo il battito dell'àncora.
    func place(beatsFromAnchor beats: Double) -> ShowClockPlace {
        if let bad = invalidity { return .unknown(bad) }
        guard beats.isFinite else { return .unknown(.invalidInput) }
        var section = anchor.section
        var x = Double(anchor.beatInSection) + beats
        guard x >= 0 else { return .unknown(.beforeAnchorSection) }
        while section < map.sections.count {
            if map.sections[section].isCycle { return .unknown(.cycle) }
            let n = Double(sectionBeats(section))
            if x < n { return .inSong(section: section, beatInSection: x) }
            x -= n
            section += 1
        }
        return .pastEnd(beats: x)
    }

    /// Il righello primario: il battito di Link di adesso contro quello dell'àncora, nella stessa
    /// numerazione (⚠️ RISCRITTO A412 · SEGUITO 2: diceva «(quantum 1)»; dal motore, quella della sessione).
    func byLinkBeats(nowLinkBeat: Double) -> ShowClockRuler {
        let beats = nowLinkBeat - anchor.linkBeat
        return ShowClockRuler(beatsFromAnchor: beats, place: place(beatsFromAnchor: beats))
    }

    // MARK: Il righello dei secondi sulla mappa

    /// Il righello di controllo: l'ora di adesso contro l'ora dell'àncora, camminata col tempo della
    /// mappa. Prima dell'àncora si torna indietro solo dentro la sezione dell'àncora; oltre la fine
    /// i battiti si contano al tempo dell'ultima sezione (solo per il confronto).
    func bySeconds(nowTicks: UInt64, ticksPerSecond: Double) -> ShowClockRuler {
        if let bad = invalidity { return ShowClockRuler(beatsFromAnchor: 0, place: .unknown(bad)) }
        guard ticksPerSecond > 0, ticksPerSecond.isFinite else {
            return ShowClockRuler(beatsFromAnchor: 0, place: .unknown(.invalidInput))
        }
        let elapsed: Double = nowTicks >= anchor.ticks
            ? Double(nowTicks - anchor.ticks) / ticksPerSecond
            : -Double(anchor.ticks - nowTicks) / ticksPerSecond
        var section = anchor.section
        var x = Double(anchor.beatInSection)
        if elapsed < 0 {
            let back = elapsed * map.sections[section].bpm / 60.0
            guard x + back >= 0 else {
                return ShowClockRuler(beatsFromAnchor: back, place: .unknown(.beforeAnchorSection))
            }
            return ShowClockRuler(beatsFromAnchor: back, place: .inSong(section: section, beatInSection: x + back))
        }
        var rest = elapsed
        var walked = 0.0
        while section < map.sections.count {
            let current = map.sections[section]
            if current.isCycle { return ShowClockRuler(beatsFromAnchor: walked, place: .unknown(.cycle)) }
            let remainingBeats = Double(sectionBeats(section)) - x
            let remainingSeconds = remainingBeats * 60.0 / current.bpm
            if rest < remainingSeconds {
                let advance = rest * current.bpm / 60.0
                return ShowClockRuler(beatsFromAnchor: walked + advance,
                                      place: .inSong(section: section, beatInSection: x + advance))
            }
            rest -= remainingSeconds
            walked += remainingBeats
            section += 1
            x = 0
        }
        let beyond = rest * map.sections[map.sections.count - 1].bpm / 60.0
        return ShowClockRuler(beatsFromAnchor: walked + beyond, place: .pastEnd(beats: beyond))
    }

    // MARK: La lettura

    /// I due righelli adesso, il loro scarto e l'esito del righello primario.
    func read(nowLinkBeat: Double, nowTicks: UInt64, ticksPerSecond: Double) -> ShowClockReading {
        let byBeats = byLinkBeats(nowLinkBeat: nowLinkBeat)
        let bySecs = bySeconds(nowTicks: nowTicks, ticksPerSecond: ticksPerSecond)
        let gap: Double?
        if byBeats.place.isLocated && bySecs.place.isLocated {
            gap = byBeats.beatsFromAnchor - bySecs.beatsFromAnchor
        } else {
            gap = nil
        }
        let certain = gap.map { $0.isFinite && abs($0) <= toleranceBeats } ?? false
        let outcome: ShowClockOutcome
        switch byBeats.place {
        case .inSong(let section, let x):
            let position = barAndBeat(section: section, beatInSection: x)
            var next: ShowClockDownbeat? = nil
            if case .found(let upcoming) = downbeat(atOrAfterLinkBeat: nowLinkBeat + ShowClock.nextDownbeatLead) {
                next = upcoming
            }
            outcome = .inSong(section: section, bar: position.bar, beat: position.beat, nextDownbeat: next)
        case .pastEnd:
            outcome = .songEnded(endLinkBeat: endLinkBeat ?? anchor.linkBeat,
                                 endTicks: endTicks(ticksPerSecond: ticksPerSecond))
        case .unknown(let why):
            outcome = .unknown(why)
        }
        return ShowClockReading(byLinkBeats: byBeats, bySeconds: bySecs, gapBeats: gap,
                                certain: certain, outcome: outcome)
    }

    /// Battuta e battito (da 1) di un punto dentro una sezione: la battuta del battito in corso.
    /// Un punto che per gli arrotondamenti cade sulla fine della sezione resta sull'ultimo battito.
    func barAndBeat(section: Int, beatInSection: Double) -> (bar: Int, beat: Int) {
        guard section >= 0, section < map.sections.count, beatInSection.isFinite else { return (0, 0) }
        let bpb = max(map.sections[section].beatsPerBar, 1)
        let last = max(sectionBeats(section) - 1, 0)
        // Prima si stringe il valore fra 0 e l'ultimo battito, poi lo si converte: nessuna
        // conversione fuori dall'intervallo di `Int` (la mappa valida tiene i battiti di sezione
        // sotto `SongMap.maxSectionBeats`).
        let clamped = min(max(beatInSection, 0), Double(last))
        let index = Int(clamped.rounded(.down))
        return (index / bpb + 1, index % bpb + 1)
    }

    // MARK: Gli «uno»

    /// Il primo inizio di battuta della canzone col battito di Link >= `linkBeat`.
    func downbeat(atOrAfterLinkBeat linkBeat: Double) -> ShowClockDownbeatSearch {
        switch place(beatsFromAnchor: linkBeat - anchor.linkBeat) {
        case .unknown(let why):
            return .unknown(why)
        case .pastEnd:
            return .songEndsFirst
        case .inSong(let section, let x):
            let bpb = map.sections[section].beatsPerBar
            let barIndex = max(Int(((x - ShowClock.epsilon) / Double(bpb)).rounded(.up)), 0)
            var targetSection = section
            var targetBeat = barIndex * bpb
            if targetBeat >= sectionBeats(section) {
                // La sezione finisce prima: il primo «uno» è l'inizio della sezione dopo.
                targetSection = section + 1
                targetBeat = 0
                guard targetSection < map.sections.count else { return .songEndsFirst }
                if map.sections[targetSection].isCycle { return .unknown(.cycle) }
            }
            let targetBpb = map.sections[targetSection].beatsPerBar
            return .found(ShowClockDownbeat(section: targetSection,
                                            bar: targetBeat / targetBpb + 1,
                                            beatInSection: targetBeat,
                                            linkBeat: anchor.linkBeat + beatsFromAnchor(section: targetSection,
                                                                                        beatInSection: targetBeat)))
        }
    }

    /// I battiti della canzone dal battito dell'àncora al battito `beatInSection` della sezione
    /// `section` (una sezione dell'àncora o successiva; `map.sections.count` = la fine).
    func beatsFromAnchor(section: Int, beatInSection: Int) -> Double {
        if section == anchor.section { return Double(beatInSection - anchor.beatInSection) }
        var total = Double(sectionBeats(anchor.section) - anchor.beatInSection)
        var index = anchor.section + 1
        while index < section && index < map.sections.count {
            total += Double(sectionBeats(index))
            index += 1
        }
        return total + Double(beatInSection)
    }

    /// I secondi dall'inizio della sua sezione a un «uno», col tempo della mappa.
    func secondsIntoSection(_ downbeat: ShowClockDownbeat) -> Double {
        guard downbeat.section >= 0, downbeat.section < map.sections.count else { return 0 }
        let bpm = map.sections[downbeat.section].bpm
        guard bpm > 0, bpm.isFinite else { return 0 }
        return Double(downbeat.beatInSection) * 60.0 / bpm
    }

    /// A412 (18/10/2026) — L'ORA SULLA MAPPA DI UN BATTITO DELLA CANZONE (mandato «DIRETTORE-IN-CRISI-
    /// PASSO-2», §2.2: «L'ora del bersaglio: la dà la mappa»). L'ora dell'àncora più i secondi che la
    /// mappa dà dal battito dell'àncora al battito `beatInSection` della sezione `section`, camminati
    /// sezione per sezione col tempo di ciascuna: a differenza dell'ora del ponte (`ABLLinkTimeAtBeat`,
    /// inversa di `ABLLinkBeatAtTime` a tempo costante, `ABLLink.h:292-303`) conosce i cambi di tempo
    /// fra adesso e il bersaglio. Nella sezione dell'àncora un battito prima di lei dà un'ora prima della
    /// sua. `nil` se il conto non si può fare, se la sezione non è dell'àncora o successiva, se il
    /// battito cade fuori dalla sua sezione, se il cammino incontra un ciclo, o con tick al secondo non
    /// validi.
    func ticks(section: Int, beatInSection: Int, ticksPerSecond: Double) -> UInt64? {
        guard invalidity == nil, ticksPerSecond > 0, ticksPerSecond.isFinite else { return nil }
        guard section >= anchor.section, section < map.sections.count else { return nil }
        if map.sections[section].isCycle { return nil }
        guard beatInSection >= 0, beatInSection < sectionBeats(section) else { return nil }
        var seconds: Double
        if section == anchor.section {
            seconds = Double(beatInSection - anchor.beatInSection) * 60.0 / map.sections[section].bpm
        } else {
            seconds = Double(sectionBeats(anchor.section) - anchor.beatInSection) * 60.0
                / map.sections[anchor.section].bpm
            var index = anchor.section + 1
            while index < section {
                let current = map.sections[index]
                if current.isCycle { return nil }
                seconds += Double(sectionBeats(index)) * 60.0 / current.bpm
                index += 1
            }
            seconds += Double(beatInSection) * 60.0 / map.sections[section].bpm
        }
        return ShowClock.ticks(anchor.ticks, plusSeconds: seconds, ticksPerSecond: ticksPerSecond)
    }

    /// A412 — l'ora sulla mappa di un «uno» (`ticks(section:beatInSection:ticksPerSecond:)`).
    func ticks(of downbeat: ShowClockDownbeat, ticksPerSecond: Double) -> UInt64? {
        ticks(section: downbeat.section, beatInSection: downbeat.beatInSection, ticksPerSecond: ticksPerSecond)
    }

    // MARK: La fine

    /// Il battito di Link della fine della canzone: il battito che seguirebbe l'ultimo. `nil` se il
    /// conto non si può fare o se dopo l'àncora c'è un ciclo (la canzone non finisce).
    var endLinkBeat: Double? {
        guard invalidity == nil else { return nil }
        var index = anchor.section + 1
        while index < map.sections.count {
            if map.sections[index].isCycle { return nil }
            index += 1
        }
        return anchor.linkBeat + beatsFromAnchor(section: map.sections.count, beatInSection: 0)
    }

    /// L'ora della fine della canzone sulla mappa: l'ora dell'àncora più i secondi che la mappa dà
    /// fino alla fine. `nil` come `endLinkBeat`, o con tick al secondo non validi.
    func endTicks(ticksPerSecond: Double) -> UInt64? {
        guard invalidity == nil, ticksPerSecond > 0, ticksPerSecond.isFinite else { return nil }
        var seconds = Double(sectionBeats(anchor.section) - anchor.beatInSection) * 60.0
            / map.sections[anchor.section].bpm
        var index = anchor.section + 1
        while index < map.sections.count {
            let section = map.sections[index]
            if section.isCycle { return nil }
            seconds += Double(sectionBeats(index)) * 60.0 / section.bpm
            index += 1
        }
        return ShowClock.ticks(anchor.ticks, plusSeconds: seconds, ticksPerSecond: ticksPerSecond)
    }

    /// `base` più `seconds` secondi, in tick; fuori dall'intervallo di `UInt64` si ferma ai bordi.
    static func ticks(_ base: UInt64, plusSeconds seconds: Double, ticksPerSecond: Double) -> UInt64 {
        let delta = seconds * ticksPerSecond
        guard delta.isFinite else { return delta > 0 ? UInt64.max : 0 }
        if delta >= 0 {
            guard delta < Double(UInt64.max) else { return UInt64.max }
            let (sum, overflow) = base.addingReportingOverflow(UInt64(delta))
            return overflow ? UInt64.max : sum
        }
        guard -delta < Double(UInt64.max) else { return 0 }
        let down = UInt64(-delta)
        return base >= down ? base - down : 0
    }
}
