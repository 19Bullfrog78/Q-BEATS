import Foundation

// === A432, parte 2a (12/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: IL CONTO DEL FOLLOWER SULLA BAND ===
// Il fatto (referti A423 par. 3.3, A424 par. 3.3, A431 par. 2.2, 2.5 e 3.1). Il Follower sa dov'è la band solo
// contando i battiti che ha suonato: un buco del suono gli fa saltare dei battiti nel tempo senza che contatore,
// accento, sezione e grafica li contino. La cura tiene un CONTO della canzone sulla band, coi due righelli di
// `ShowClock` (i battiti della sessione di Link e i secondi sulla mappa) da un'àncora presa all'ingresso; quando
// i battiti dell'iPad hanno un nome sbagliato il motore li rinomina, e non sposta mai un click nel tempo.
//
// Questo tipo è solo la regola: valori in ingresso, valori in uscita. Non chiama Link né il motore, e in questa
// parte (2a) nessun codice dell'app lo chiama: i fili nel motore sono la parte 2b.
//
// LE REGOLE, con le decisioni del referee:
//  · IL SEME DALLA BAND (A423 par. 3.3 a, A424 par. 3.3 a). All'ingresso si misurano i secondi fra l'ora in cui
//    l'iPad ha saputo del Play e l'ora d'uscita dell'ingresso, e si camminano sulla mappa dall'inizio della
//    canzone. Il seme è l'inizio di battuta più vicino a quel punto; vale solo se dista al più un quarto della
//    battuta in cui il punto cade. Oltre: NESSUN CONTO PER TUTTA LA CANZONE (P33). Il «ritardo del richiamo» è il
//    seme meno i battiti misurati (A424, Aperto A.12): se il richiamo arriva più di tre quarti di battuta in
//    ritardo il seme cade una battuta prima, e il tipo non può accorgersene (il limite scritto).
//  · L'ÀNCORA COL RIFERIMENTO FISSO (P28, A431 par. 2.2): il battito del seme, il battito della sessione
//    all'ora dell'ingresso (B0) e quell'ora (t0). Lo scarto di ogni lettura si misura da lì, mai dalla lettura
//    di prima: g = (B − B0) − (battiti della mappa nei secondi passati da t0). CERTO = |g| ≤ 1/8 di battito,
//    1/8 compreso, la tolleranza di `ShowClock`. Un ingresso con l'àncora viva non la riprende.
//  · LA LETTURA (P37): per l'ora del battito in attesa del DSP rende certo o no, il posto della band (sezione,
//    battito nella sezione, posizione nella battuta) e lo scarto. Il posto è il battito intero più vicino sul
//    righello dei battiti di Link, camminato sulla mappa.
//  · LA RINUMERAZIONE ATTESA (P21, con A.2: VERIFICA_REFEREE_A424 par. 3.2; A431 par. 2.5). Al cambio di metro
//    il Direttore rinumera la sessione circa un secondo dopo lo scambio: è un salto dello scarto che non è un
//    salto della band. Lo stato si apre quando LA BAND passa un confine col cambio di metro (sul righello dei
//    secondi), resta aperto finché la rinumerazione non è riconosciuta o la band non ha passato il secondo
//    confine dopo quello, e un confine che cambia di nuovo il metro lo riapre da capo. Nello stato, il primo
//    scarto oltre 1/8 col contatore dell'iPad d'accordo coi secondi è la rinumerazione: B0 prende il salto e lo
//    stato si chiude. In una lettura vengono prima i confini, poi lo scarto. Solo eventi e stati, nessun tempo.
//  · IL CONTO NON CERTO RESTA CHIUSO PER IL RESTO DELLA CANZONE, col suo motivo (`FollowerBandCountClosed`).
//    Lo «stesso avvio» della band non si legge qui (P39): un avvio nuovo passa da uno Stop, che chiude l'àncora
//    nel motore.
// Solo Foundation e i tipi di Models/ (`ShowClock`): il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Perché il conto non c'è (dal seme) o non è più certo (da una lettura). Un motivo per ogni esito che il tipo
/// distingue coi suoi ingressi: cause diverse che gli arrivano uguali hanno lo stesso motivo.
enum FollowerBandCountClosed: Equatable {
    /// Il seme: mappa non valida, ore o tick al secondo non validi, l'ingresso prima del richiamo del Play.
    case seedInvalidInput
    /// Il seme: fra l'inizio della canzone e l'ingresso c'è un ciclo.
    case seedCycle
    /// Il seme: l'ingresso cade oltre la fine della canzone, o la battuta più vicina è la fine.
    case seedPastEnd
    /// Il seme: più di un quarto di battuta dall'inizio di battuta più vicino.
    case seedOffBar
    /// La lettura: un righello non dà un posto (un ciclo, un valore non valido, prima della sezione dell'àncora).
    case noPlace(ShowClockUnknown)
    /// La lettura: lo scarto dall'àncora passa 1/8 con lo stato «rinumerazione attesa» chiuso.
    case jumpOutsideRenumbering
    /// La lettura: lo scarto passa 1/8 nello stato aperto, ma il contatore dell'iPad non è d'accordo coi secondi.
    case jumpWithoutCounterAgreement
}

/// Lo stato «rinumerazione attesa» (P21 con A.2).
enum FollowerBandRenumbering: Equatable {
    case closed
    /// Aperto al confine `boundary` (l'indice della sezione che lì comincia); `boundariesAfter` = i confini senza
    /// cambio di metro che la band ha passato dopo.
    case open(boundary: Int, boundariesAfter: Int)
}

/// Gli ingressi del seme: valori già letti dal motore al fuoco dell'ingresso.
struct FollowerBandSeedInput: Equatable {
    let map: SongMap
    /// L'ora dell'apparecchio in cui il Follower ha saputo del Play del Direttore.
    let playCallbackTicks: UInt64
    /// L'ora d'uscita prevista dell'ingresso.
    let entryTicks: UInt64
    /// Il battito della sessione a quell'ora, nella numerazione con cui si leggerà il battito in attesa.
    let entryLinkBeat: Double
    let ticksPerSecond: Double
}

/// Il seme preso.
struct FollowerBandSeed: Equatable {
    /// Sezione e battito nella sezione dell'inizio di battuta scelto (da 0).
    let section: Int
    let beatInSection: Int
    /// Lo stesso punto in battiti della canzone dall'inizio.
    let songBeat: Int
    /// I battiti della band dal richiamo del Play all'ingresso, camminati sulla mappa.
    let measuredBeats: Double
    /// Il ritardo del richiamo del Play, in battiti: il seme meno i battiti misurati.
    let callbackDelayBeats: Double
}

/// L'esito di un ingresso.
enum FollowerBandEntry: Equatable {
    /// Àncora presa, col suo seme.
    case anchored(FollowerBandCount, FollowerBandSeed)
    /// L'àncora era già viva: resta quella (al motore: riallineo dovuto).
    case kept(FollowerBandCount)
    /// Nessun conto per questa canzone: il conto è chiuso col suo motivo.
    case noCount(FollowerBandCount)
}

/// L'ultimo battito contato dall'iPad: sezione, battito nella sezione (da 0) e la sua ora d'uscita.
struct FollowerCountedBeat: Equatable {
    let section: Int
    let beatInSection: Int
    let ticks: UInt64
}

/// Il posto della band per l'ora del battito in attesa.
enum FollowerBandPlace: Equatable {
    /// Dentro la canzone: sezione, battito nella sezione e posizione nella battuta, tutti da 0.
    case inSong(section: Int, beatInSection: Int, beatInBar: Int)
    /// Oltre la fine della canzone, di tanti battiti: non è un «non certo».
    case pastEnd(beats: Int)
}

/// Una rinumerazione riconosciuta: il confine che aveva aperto lo stato e il salto preso dall'àncora.
struct FollowerBandRenumberingRecognized: Equatable {
    let boundary: Int
    let jump: Double
}

/// Una lettura del conto.
struct FollowerBandReading: Equatable {
    let certain: Bool
    /// Il motivo, se non è certo.
    let reason: FollowerBandCountClosed?
    /// Il posto della band; `nil` se non è certo.
    let place: FollowerBandPlace?
    /// Lo scarto dall'àncora misurato in questa lettura (prima dell'eventuale rinumerazione riconosciuta);
    /// `nil` se un righello non dà un posto o se il conto era già chiuso.
    let gapBeats: Double?
    let recognized: FollowerBandRenumberingRecognized?
    /// Il conto era già chiuso prima di questa lettura.
    let closedBefore: Bool
}

struct FollowerBandCount: Equatable {

    /// Certo fino a questo scarto compreso: la tolleranza di `ShowClock`, un ottavo di battito.
    static let toleranceBeats: Double = ShowClock.defaultToleranceBeats
    /// Il seme vale entro questa parte di battuta dall'inizio di battuta più vicino.
    static let seedToleranceBars: Double = 0.25
    /// Lo stato «rinumerazione attesa» si chiude quando la band ha passato questo numero di confini senza cambio
    /// di metro dopo quello che l'ha aperto (A.2: il secondo).
    static let boundariesToWait: Int = 2
    /// Il tetto dei battiti «oltre la fine» resi come intero.
    private static let pastEndCap: Double = Double(SongMap.maxSectionBeats)

    let map: SongMap
    /// L'àncora col riferimento fisso; `nil` solo per un conto nato chiuso (seme non certo).
    private(set) var anchor: ShowClockAnchor?
    /// Il motivo, se il conto è chiuso per il resto della canzone.
    private(set) var closed: FollowerBandCountClosed?
    private(set) var renumbering: FollowerBandRenumbering
    /// La sezione della band all'ultima lettura, sul righello dei secondi (`map.sections.count` = oltre la fine).
    private(set) var bandSection: Int

    /// Un conto con l'àncora data: stato chiuso, la band nella sezione dell'àncora.
    init(map: SongMap, anchor: ShowClockAnchor) {
        self.map = map
        self.anchor = anchor
        self.closed = nil
        self.renumbering = .closed
        self.bandSection = anchor.section
    }

    /// Un conto nato chiuso: il seme non è certo.
    private init(map: SongMap, closedBySeed reason: FollowerBandCountClosed) {
        self.map = map
        self.anchor = nil
        self.closed = reason
        self.renumbering = .closed
        self.bandSection = 0
    }

    // MARK: L'ingresso e il seme

    /// Un ingresso del Follower nella canzone. Col conto chiuso resta chiuso (nessun conto per tutta la canzone);
    /// con l'àncora viva resta quella; se no, il seme dalla band.
    static func enter(current: FollowerBandCount?, seed input: FollowerBandSeedInput) -> FollowerBandEntry {
        if let count = current {
            if count.closed != nil { return .noCount(count) }
            return .kept(count)
        }
        return seed(input)
    }

    /// Il seme dalla band.
    static func seed(_ input: FollowerBandSeedInput) -> FollowerBandEntry {
        let map = input.map
        guard map.isValid,
              input.ticksPerSecond > 0, input.ticksPerSecond.isFinite,
              input.entryLinkBeat.isFinite,
              input.entryTicks >= input.playCallbackTicks else {
            return .noCount(FollowerBandCount(map: map, closedBySeed: .seedInvalidInput))
        }
        // I secondi dal richiamo del Play camminati sulla mappa dall'inizio della canzone.
        let fromStart = ShowClock(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 0,
                                                                    ticks: input.playCallbackTicks))
        let measured = fromStart.bySeconds(nowTicks: input.entryTicks, ticksPerSecond: input.ticksPerSecond)
        let section: Int
        let x: Double
        switch measured.place {
        case .unknown(let why):
            return .noCount(FollowerBandCount(map: map, closedBySeed: why == .cycle ? .seedCycle : .seedInvalidInput))
        case .pastEnd:
            return .noCount(FollowerBandCount(map: map, closedBySeed: .seedPastEnd))
        case .inSong(let placeSection, let placeBeat):
            section = placeSection
            x = placeBeat
        }
        // L'inizio di battuta più vicino: quello della battuta in cui il punto cade, o il successivo.
        let bpb = Double(map.sections[section].beatsPerBar)
        let barStart = (x / bpb).rounded(.down) * bpb
        let down = x - barStart
        let up = bpb - down
        var targetSection = section
        var targetBeat: Int
        let distance: Double
        if down <= up {
            targetBeat = Int(barStart)
            distance = down
        } else {
            targetBeat = Int(barStart + bpb)
            distance = up
            if targetBeat >= (map.sections[section].totalBeats ?? 0) {
                // La sezione finisce lì: il prossimo «uno» è l'inizio della sezione dopo.
                targetSection = section + 1
                targetBeat = 0
            }
        }
        guard distance <= bpb * FollowerBandCount.seedToleranceBars else {
            return .noCount(FollowerBandCount(map: map, closedBySeed: .seedOffBar))
        }
        guard targetSection < map.sections.count else {
            return .noCount(FollowerBandCount(map: map, closedBySeed: .seedPastEnd))
        }
        if map.sections[targetSection].isCycle {
            return .noCount(FollowerBandCount(map: map, closedBySeed: .seedCycle))
        }
        var songBeat = targetBeat
        var index = 0
        while index < targetSection {
            songBeat += map.sections[index].totalBeats ?? 0
            index += 1
        }
        let taken = FollowerBandSeed(section: targetSection, beatInSection: targetBeat, songBeat: songBeat,
                                     measuredBeats: measured.beatsFromAnchor,
                                     callbackDelayBeats: Double(songBeat) - measured.beatsFromAnchor)
        let seedAnchor = ShowClockAnchor(section: targetSection, beatInSection: targetBeat,
                                         linkBeat: input.entryLinkBeat, ticks: input.entryTicks)
        return .anchored(FollowerBandCount(map: map, anchor: seedAnchor), taken)
    }

    // MARK: La rinumerazione attesa

    /// La band passa il confine `boundary`: lo stato dopo (A431 par. 2.5, la tabella delle transizioni).
    static func afterBoundary(_ state: FollowerBandRenumbering, boundary: Int,
                              meterChanges: Bool) -> FollowerBandRenumbering {
        if meterChanges { return .open(boundary: boundary, boundariesAfter: 0) }
        switch state {
        case .closed:
            return .closed
        case .open(let opened, let after):
            if after + 1 >= FollowerBandCount.boundariesToWait { return .closed }
            return .open(boundary: opened, boundariesAfter: after + 1)
        }
    }

    // MARK: La lettura

    /// Una lettura per l'ora del battito in attesa del DSP: `pendingLinkBeat` il battito della sessione a
    /// quell'ora (nella numerazione dell'àncora), `pendingTicks` l'ora, `lastCounted` l'ultimo battito contato
    /// dall'iPad. Prima i confini che la band ha passato, poi lo scarto.
    mutating func read(pendingLinkBeat: Double, pendingTicks: UInt64, ticksPerSecond: Double,
                       lastCounted: FollowerCountedBeat?) -> FollowerBandReading {
        guard closed == nil, let startAnchor = anchor else {
            // Senza àncora il conto nasce chiuso: il motivo c'è sempre (il ripiego non si raggiunge).
            return FollowerBandReading(certain: false, reason: closed ?? .seedInvalidInput, place: nil,
                                       gapBeats: nil, recognized: nil, closedBefore: true)
        }
        var clock = ShowClock(map: map, anchor: startAnchor)
        let linkRuler = clock.byLinkBeats(nowLinkBeat: pendingLinkBeat)
        let secondsRuler = clock.bySeconds(nowTicks: pendingTicks, ticksPerSecond: ticksPerSecond)
        if case .unknown(let why) = secondsRuler.place {
            return closeCount(.noPlace(why), gap: nil, recognized: nil)
        }
        if case .unknown(let why) = linkRuler.place {
            return closeCount(.noPlace(why), gap: nil, recognized: nil)
        }

        // 1. I confini che la band ha passato dall'ultima lettura, uno per uno, sul righello dei secondi.
        let bandNow: Int
        if case .inSong(let nowSection, _) = secondsRuler.place {
            bandNow = nowSection
        } else {
            bandNow = map.sections.count
        }
        if bandNow > bandSection {
            var boundary = bandSection + 1
            while boundary <= bandNow {
                let meterChanges = boundary < map.sections.count
                    && map.sections[boundary].beatsPerBar != map.sections[boundary - 1].beatsPerBar
                renumbering = FollowerBandCount.afterBoundary(renumbering, boundary: boundary,
                                                              meterChanges: meterChanges)
                boundary += 1
            }
            bandSection = bandNow
        }

        // 2. Lo scarto dall'àncora.
        let gap = linkRuler.beatsFromAnchor - secondsRuler.beatsFromAnchor
        var countAnchor = startAnchor
        var recognized: FollowerBandRenumberingRecognized? = nil
        if !(gap.isFinite && abs(gap) <= FollowerBandCount.toleranceBeats) {
            switch renumbering {
            case .closed:
                return closeCount(.jumpOutsideRenumbering, gap: gap, recognized: nil)
            case .open(let boundary, _):
                guard counterAgrees(lastCounted, clock: clock, ticksPerSecond: ticksPerSecond) else {
                    return closeCount(.jumpWithoutCounterAgreement, gap: gap, recognized: nil)
                }
                // La rinumerazione riconosciuta: l'àncora prende il salto, lo stato si chiude.
                countAnchor = ShowClockAnchor(section: startAnchor.section, beatInSection: startAnchor.beatInSection,
                                              linkBeat: startAnchor.linkBeat + gap, ticks: startAnchor.ticks)
                anchor = countAnchor
                renumbering = .closed
                recognized = FollowerBandRenumberingRecognized(boundary: boundary, jump: gap)
                clock = ShowClock(map: map, anchor: countAnchor)
            }
        }

        // 3. Il posto della band: battiti interi dall'àncora sul righello di Link, camminati sulla mappa.
        let fromAnchor = (pendingLinkBeat - countAnchor.linkBeat).rounded()
        switch clock.place(beatsFromAnchor: fromAnchor) {
        case .unknown(let why):
            return closeCount(.noPlace(why), gap: gap, recognized: recognized)
        case .pastEnd(let beyond):
            let beats = Int(min(max(beyond, 0), FollowerBandCount.pastEndCap))
            return FollowerBandReading(certain: true, reason: nil, place: .pastEnd(beats: beats),
                                       gapBeats: gap, recognized: recognized, closedBefore: false)
        case .inSong(let placeSection, let placeBeat):
            let beat = Int(placeBeat)
            let bpb = max(map.sections[placeSection].beatsPerBar, 1)
            return FollowerBandReading(certain: true, reason: nil,
                                       place: .inSong(section: placeSection, beatInSection: beat,
                                                      beatInBar: beat % bpb),
                                       gapBeats: gap, recognized: recognized, closedBefore: false)
        }
    }

    /// Chiude il conto per il resto della canzone e rende la lettura non certa.
    private mutating func closeCount(_ reason: FollowerBandCountClosed, gap: Double?,
                                     recognized: FollowerBandRenumberingRecognized?) -> FollowerBandReading {
        closed = reason
        return FollowerBandReading(certain: false, reason: reason, place: nil, gapBeats: gap,
                                   recognized: recognized, closedBefore: false)
    }

    /// «Il contatore d'accordo coi secondi» (A424 par. 2.2 e): l'ultimo battito contato dall'iPad cade, sul
    /// righello dei secondi e alla sua ora, entro la tolleranza dal suo posto. È un controllo sul conto proprio
    /// dell'iPad, senza Link: dice che non ha perso battiti di nascosto. Senza un battito contato non c'è accordo.
    private func counterAgrees(_ lastCounted: FollowerCountedBeat?, clock: ShowClock,
                               ticksPerSecond: Double) -> Bool {
        guard let last = lastCounted, let countAnchor = anchor else { return false }
        guard last.section >= countAnchor.section, last.section < map.sections.count,
              last.beatInSection >= 0,
              last.beatInSection < (map.sections[last.section].totalBeats ?? 0) else { return false }
        let ruler = clock.bySeconds(nowTicks: last.ticks, ticksPerSecond: ticksPerSecond)
        guard ruler.place.isLocated else { return false }
        let counted = clock.beatsFromAnchor(section: last.section, beatInSection: last.beatInSection)
        return abs(ruler.beatsFromAnchor - counted) <= FollowerBandCount.toleranceBeats
    }
}
