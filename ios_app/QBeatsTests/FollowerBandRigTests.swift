import XCTest

// === A432, parte 2b — banco dei fili del conto del Follower sulla band (`FollowerBandRig`, banco Models) ===
// Il rig rifà il motore dell'iPad Follower per quello che i fili del conto toccano, e nient'altro: il DSP (la linea
// a campioni, il battito in attesa con la sua identità, l'etichetta, i cambi armati), la correzione di fase, il
// giro dei battiti con lo scambio di sezione e il tempo armato, il runner, il passo della vista. Le regole pure
// sono quelle vere del deposito: `FollowerBandCount`, `ShowClock`, `SectionPreloadDecision`, `SectionRealign`,
// `LateBeatDecision`.
// I 25 casi, con gli stessi nomi e gli stessi numeri, girano sul modello Python del motore (fuori dal deposito),
// dove 26 rotture volute tolgono una regola alla volta e ogni test cade con almeno una. Qui le rotture non ci
// sono: c'è solo il ramo sano. L'unica eccezione è `withoutPointR`, il «gemello» di due casi (l'iPad com'era prima
// di questo lavoro).
// Le condizioni del rig sono scritte come le scrive il motore (`AudioEngine`, blocco «A432 · il conto del Follower
// sulla band»), e ogni funzione porta il nome di quella che rispecchia: `followerBandEntryAtFireQ`,
// `takeFollowerBandAnchorQ`, `consumeSongMapForRunningStartQ`, `noteFollowerRealignDueQ`, `followerSecondQ`,
// `resetFollowerBandCountQ`, il punto R di `scheduleNextBuffer` e `followerBandCountPointRQ`,
// `readFollowerBandCountQ`, `loadFollowerSectionForRealignQ`, `followerRealignQ`, `logFollowerSectionEndCheckQ`,
// `preloadNextSection`, `noteLateBeatCorrectionQ`, `ownClockPinQ`.
// 24.000.000 tick al secondo, come `ShowClockTests` e `FollowerBandCountTests`; 48 kHz, buffer da 512 campioni.
// Mai `!` sugli optional: i test lanciano (`XCTUnwrap`).

// MARK: - I numeri del rig

private enum RigNumbers {
    static let tps = 24_000_000.0
    static let frames = 512
    static let rate = 48000.0
    /// Un buffer in secondi: 10,667 ms.
    static let buf = Double(frames) / rate
    /// La latenza d'uscita più un ciclo: l'ora d'uscita di un buffer è l'ora della chiamata più 30 ms.
    static let outDelay = 0.030
    /// La soglia della correzione di fase di Link, in battiti.
    static let syncThreshold = 0.01
    /// La finestra «sync skip» dopo uno scambio di sezione, in chiamate.
    static let window = 100

    static func ticks(_ seconds: Double) -> UInt64 {
        UInt64((seconds * tps).rounded())
    }

    /// Quattro decimali, come le ore delle chiamate nelle righe del modello.
    static func round4(_ value: Double) -> Double {
        (value * 10_000.0).rounded() / 10_000.0
    }

    /// Sei decimali, come le ore d'uscita dei battiti nel modello.
    static func round6(_ value: Double) -> Double {
        (value * 1_000_000.0).rounded() / 1_000_000.0
    }
}

private extension SongMapSection {
    /// I battiti della sezione come `_sectionTotalBeats` del motore: 0 per un ciclo.
    var rigTotal: Int { totalBeats ?? 0 }
}

// MARK: - Il DSP del Follower (`core_engine/MetronomeDSP.cpp`)

/// Un evento del buffer: lo scostamento in campioni, l'etichetta (la posizione nella battuta), l'accento e
/// l'identità del battito (l'origine più il suo indice).
private struct RigDSPEvent {
    let offset: Int
    let label: Int
    let accent: Bool
    let identity: Double
}

/// Il DSP del Follower per quello che serve al conto. Gli arrotondamenti sono quelli del C++: `std::round` è
/// `.rounded()` (al più vicino, i mezzi lontano dallo zero). Le suddivisioni non servono al conto e non ci sono.
private struct RigFollowerDSP {
    let rate: Double
    private(set) var bpm: Double
    private(set) var bpb = 4
    /// `_currentBeatInBar`
    private var label = 0
    /// `_pendingBeatIdx`
    private var idx = 0
    /// `_absoluteSamplePosition`
    private var cursor = 0
    /// `_exactNextBeatSample`
    private var exact = 0.0
    /// `_startAbsoluteBeat`
    private var origin = 0.0
    private var accent: [Int] = [1, 0, 0, 0] + [Int](repeating: 0, count: 12)
    private var armedBpb: Int? = nil
    private(set) var armedBpm: Double? = nil

    init(rate: Double, bpm: Double) {
        self.rate = rate
        self.bpm = bpm
    }

    private var samplesPerBeat: Double { rate * 60.0 / bpm }

    // I setter

    /// `MetronomeDSP::resetForStart`
    mutating func resetForStart(_ startBeat: Double) {
        guard startBeat.isFinite, startBeat >= 0.0 else { return }
        origin = startBeat
        let spb = samplesPerBeat
        cursor = Int((startBeat * spb).rounded())
        label = 0
        idx = 0
        exact = startBeat * spb
    }

    /// `MetronomeDSP::setBPM`, con la cura della parte 2a: il battito in attesa mai nel passato.
    mutating func setBPM(_ newBpm: Double) {
        guard newBpm.isFinite, newBpm > 0.0 else { return }
        if newBpm > 0.0 && bpm > 0.0 && newBpm != bpm {
            exact = Double(cursor) + (exact - Double(cursor)) * (bpm / newBpm)
            if exact.rounded() < Double(cursor) {
                exact = Double(cursor)
            }
        }
        bpm = newBpm
    }

    /// `MetronomeDSP::setBeatsPerBar`: rimette l'etichetta a 0 e l'accento sul primo battito.
    mutating func setBeatsPerBar(_ newBpb: Int) {
        bpb = newBpb
        label = 0
        accent = [1] + [Int](repeating: 0, count: 15)
    }

    /// `MetronomeDSP::scheduleBeatsPerBarChange`
    mutating func scheduleBpb(_ newBpb: Int) {
        armedBpb = newBpb
    }

    /// `MetronomeDSP::scheduleBPMChange`
    mutating func scheduleBpm(_ newBpm: Double) {
        guard newBpm.isFinite, newBpm > 0.0 else { return }
        armedBpm = newBpm
    }

    /// `metronome_cancel_pending_bpm` e `metronome_cancel_pending_bpb`
    mutating func cancelPending() {
        armedBpb = nil
        armedBpm = nil
    }

    /// `MetronomeDSP::setBeatPositionTimeOnly`, col «subito»: un battito scavalcato dalla correzione va al cursore.
    mutating func setBeatPositionTimeOnly(_ beat: Double) {
        guard beat.isFinite, beat >= 0.0 else { return }
        let spb = samplesPerBeat
        var ahead = (exact - Double(cursor)) / spb
        ahead = min(max(ahead, 0.0), 1.5)
        cursor = Int((beat * spb).rounded())
        let relative = beat - origin
        let relIdx = (relative + ahead).rounded()
        exact = (origin + relIdx) * spb
        idx = Int(relIdx)
        if exact < Double(cursor) {
            exact = Double(cursor)
        }
    }

    /// `MetronomeDSP::renamePendingBeat`: cambia il nome del battito in attesa, non il suo campione.
    mutating func renamePendingBeat(_ beatInBar: Int) {
        if bpb == 0 { return }
        label = beatInBar % bpb
    }

    // I getter (`metronome_pending_beat`)

    /// Il battito in attesa: l'origine più il suo indice.
    var pendingBeat: Double { origin + Double(idx) }

    /// I campioni dal cursore al battito in attesa.
    var pendingSamplesAhead: Int { Int(exact.rounded() - Double(cursor)) }

    // Il buffer

    /// `MetronomeDSP::processBuffer`: rende gli eventi del buffer. Lo stesso esito del giro campione per campione
    /// del C++ (l'uguaglianza stretta fra il cursore e il campione arrotondato del battito in attesa), senza girare
    /// su ogni campione: il battito esce solo se il suo campione arrotondato cade in questo buffer, a partire dal
    /// campione che il giro ha già raggiunto.
    mutating func process(frames: Int) -> [RigDSPEvent] {
        var events: [RigDSPEvent] = []
        var spb = samplesPerBeat
        var i = 0
        while true {
            let r = Int(exact.rounded())
            if r < cursor + i || r >= cursor + frames {
                break
            }
            i = r - cursor
            let eventLabel = label
            events.append(RigDSPEvent(offset: i, label: eventLabel, accent: accent[eventLabel] > 0,
                                      identity: origin + Double(idx)))
            if label == 0 {
                if let armed = armedBpb {
                    bpb = armed
                    armedBpb = nil
                }
                if let armed = armedBpm {
                    bpm = armed
                    armedBpm = nil
                    spb = samplesPerBeat
                }
            }
            label = (label + 1) % bpb
            exact += spb
            idx += 1
            i += 1
        }
        cursor += frames
        return events
    }
}

// MARK: - La band

/// La band (il Direttore): suona la canzone dall'inizio a `tPlay`; la numerazione della sessione di Link è il
/// battito della canzone più `link0`, più le rinumerazioni (ora, salto) da quando avvengono.
private struct RigBand {
    let map: SongMap
    let tPlay: Double
    let link0: Double
    var renumbers: [(at: Double, jump: Double)] = []

    init(map: SongMap, tPlay: Double, link0: Double = 1000.0) {
        self.map = map
        self.tPlay = tPlay
        self.link0 = link0
    }

    /// I battiti della canzone all'ora `t` (negativi prima del Play; oltre la fine col tempo dell'ultima sezione).
    func songBeats(_ t: Double) -> Double {
        let sections = map.sections
        var rest = t - tPlay
        if rest <= 0 {
            return rest * sections[0].bpm / 60.0
        }
        var walked = 0.0
        for s in sections {
            let total = Double(s.rigTotal)
            let dur = total * 60.0 / s.bpm
            if rest < dur {
                return walked + rest * s.bpm / 60.0
            }
            rest -= dur
            walked += total
        }
        return walked + rest * sections[sections.count - 1].bpm / 60.0
    }

    /// Il battito della sessione di Link all'ora `t`.
    func linkBeat(_ t: Double) -> Double {
        var jumps = 0.0
        for renumber in renumbers where t >= renumber.at {
            jumps += renumber.jump
        }
        return link0 + songBeats(t) + jumps
    }
}

// MARK: - La vista

/// Quello che la vista mostra a un tick: battuta e battito (da 1; 0 e 0 senza l'àncora della battuta).
private struct RigShown: Equatable {
    let tick: Int
    let bar: Int
    let beat: Int
}

/// Il passo di `LiveView`: l'àncora della battuta (`sectionStartTick`), il marker del cambio di sezione
/// (`pendingSectionStart`, `lastSeenSectionIdx`), il messaggio del riallineo (`sectionRealignSubject`).
private struct RigView {
    private var sectionStartTick = 1
    private var pendingSectionStart = false
    private var barAnchorValid = false
    private var lastSeen: Int? = nil
    private(set) var shown: [RigShown] = []

    init() {}

    /// Il cambio dell'indice del runner.
    mutating func runnerSection(_ idx: Int) {
        if let seen = lastSeen, seen != idx {
            pendingSectionStart = true
        }
        lastSeen = idx
    }

    /// Il messaggio del riallineo (P10): l'àncora della battuta si rifà con l'identità di `SectionRealign`.
    mutating func realign(_ message: SectionRealign) {
        sectionStartTick = message.sectionStartTick
        pendingSectionStart = false
        barAnchorValid = true
        lastSeen = message.sectionIdx
    }

    /// Un tick dei battiti.
    mutating func tick(_ n: Int, startOffset: Int, bpb: Int) {
        if n == 1 {
            sectionStartTick = 1 - startOffset
            pendingSectionStart = false
            barAnchorValid = true
        } else if pendingSectionStart {
            sectionStartTick = n
            pendingSectionStart = false
            barAnchorValid = true
        }
        guard barAnchorValid else {
            shown.append(RigShown(tick: n, bar: 0, beat: 0))
            return
        }
        let rel = n - sectionStartTick + 1
        // La divisione per difetto e il resto mai negativo (in Swift `%` può rendere un negativo).
        let beatIndex = (((rel - 1) % bpb) + bpb) % bpb
        let barIndex = (rel - 1 - beatIndex) / bpb
        shown.append(RigShown(tick: n, bar: barIndex + 1, beat: beatIndex + 1))
    }
}

// MARK: - Le righe e i battiti del rig

/// Un posto nella canzone: sezione e battito nella sezione, da 0.
private struct RigSpot: Equatable {
    let section: Int
    let beat: Int
}

/// Il battito in attesa come lo dice il DSP: l'identità e i campioni dal cursore.
private struct RigPending: Equatable {
    let beat: Double
    let samplesAhead: Int
}

/// Un battito uscito: l'ora d'uscita (arrotondata a sei decimali), la sezione e il battito nella sezione che il
/// motore gli dà, l'etichetta e l'accento del DSP, e se è stato zittito (U9).
private struct RigBeat: Equatable {
    let outTime: Double
    let section: Int
    let beatInSection: Int
    let label: Int
    let accent: Bool
    let muted: Bool
}

/// Una W2 uscita: la sezione e l'ora d'uscita del suo battito.
private struct RigW2: Equatable {
    let section: Int
    let outTime: Double
}

/// La riga «ancora presa».
private struct RigAnchorTaken {
    let section: Int
    let beat: Int
    let delayBeats: Double
    let seedApplied: Bool
}

/// La riga «lettura».
private struct RigReadingRow {
    let reason: String
    let gapBeats: Double?
    let certain: Bool
    let state: FollowerBandRenumbering
    let stateBefore: FollowerBandRenumbering
    let pendingBeat: Double
    let samplesAhead: Int
}

/// I campi di un riallineo dentro la canzone.
private struct RigRealignDetail {
    let band: RigSpot
    let jumpBeats: Int
    let loadsSection: Bool
    let tempoArmed: Bool
    let pendingBefore: RigPending
    let pendingAfter: RigPending
}

/// La riga «riallineo»: il motivo, il posto del motore, l'ora della chiamata (arrotondata a quattro decimali);
/// `inSong` è `nil` quando la band è oltre la fine della canzone.
private struct RigRealignRow {
    let reason: String
    let motor: RigSpot
    let callTime: Double
    let inSong: RigRealignDetail?
}

/// La riga «precarico scartato».
private struct RigDiscardedPreload: Equatable {
    let section: Int
    let engineSection: Int
}

/// Le righe di registro del rig, in breve.
private enum RigRow {
    case anchorTaken(RigAnchorTaken)
    case anchorAlreadyAlive
    case anchorNotTaken(reason: String)
    case noCount(closed: FollowerBandCountClosed?)
    case reading(RigReadingRow)
    case renumberingRecognized(FollowerBandRenumberingRecognized)
    case countNotCertain(reason: FollowerBandCountClosed?)
    case realign(RigRealignRow)
    case sectionEndCheck(motor: RigSpot, band: RigSpot?, agrees: Bool)
    case preloadDiscarded(RigDiscardedPreload)
    case lateBeatCorrection(before: Double, after: Double, pendingBeat: Double)
    case songEndDelivered(callTime: Double)
}

/// La linea propria del Follower DA-SOLO (`OwnClockTimeline`): l'ora, la posizione e il tempo dell'àncora.
private struct RigOwnTimeline {
    let time: Double
    let position: Double
    let bpm: Double
}

// MARK: - Il motore dell'iPad Follower

/// Il motore dell'iPad Follower, per quello che i fili toccano. Una classe: i blocchi rimandati «al principale»
/// catturano il rig.
private final class FollowerBandRig {
    let map: SongMap
    var band: RigBand
    private(set) var dsp: RigFollowerDSP
    private(set) var running = false
    /// Falso = DA-SOLO (la linea propria).
    private var inSync = true
    /// La linea dell'iPad: posizione = battito della sessione meno `line0`.
    var line0 = 0.0
    /// La posizione del sequencer, in battiti (`midi_engine_get_beat_position`).
    private(set) var pos = 0.0
    /// `_ownTimelineQ`: `nil` = la linea propria è da ri-ancorare.
    private var ownTimeline: RigOwnTimeline? = nil
    /// `_songMapSectionQ`
    private(set) var mapSection = 0
    /// `_sectionBeatCounter`
    var counter = 0
    /// `_sectionTotalBeats`
    private var total = 0
    private(set) var bpb: Int
    /// L'indice della sezione precaricata (`_pendingNext*`).
    private(set) var pendingNext: Int? = nil
    /// `_pendingBPMValue`
    private(set) var pendingBpmValue: Double? = nil
    private var pendingBpmTargetTick = 0
    /// `beatTickCounter`
    private var tick = 0
    /// `startBeatOffset`
    private(set) var startOffset = 0
    /// `linkSyncSkipBuffers`
    private var syncSkip = 0
    /// `_sectionEndPending`
    private var sectionEndPending = false
    /// La chiusura di fine canzone consegnata.
    private(set) var ended = false
    private(set) var engineTempo: Double
    private(set) var seqTempo: Double
    private(set) var screenBpm: Double
    /// `_followerBandCountQ`
    private(set) var count: FollowerBandCount? = nil
    /// `_followerPlayCallbackTicksQ`
    private(set) var playTicks: UInt64? = nil
    /// `_followerEntryPendingQ`
    private(set) var entryPending: (ticks: UInt64, linkBeat: Double)? = nil
    /// `_songMapForNextStartQ`
    private var mapForNextStart = false
    /// `_followerRealignDueQ`
    private(set) var realignDue: String? = nil
    /// `_followerCountedAtDueQ`
    private var countedAtDue: FollowerCountedBeat? = nil
    /// `_lastCountedBeatQ`
    private var lastCounted: FollowerCountedBeat? = nil
    /// `_followerRealignsQ`
    private(set) var realigns = 0
    /// `_lateBeatsMutedQ`
    private(set) var lateMuted = 0
    private(set) var w2: [RigW2] = []
    var beats: [RigBeat] = []
    var rows: [RigRow] = []
    private(set) var runnerSection = 0
    private(set) var runnerRejoins: [Int] = []
    /// I blocchi rimandati al principale: (quando, blocco), in ordine d'arrivo.
    private var mainQueue: [(when: Double, work: () -> Void)] = []
    private(set) var view = RigView()
    private(set) var calls = 0
    private(set) var readings = 0
    /// Il ritardo del principale, in secondi.
    var mainDelay = 0.0
    var outDelay = RigNumbers.outDelay
    /// `_muteLateBeatThisBufferQ`
    private var muteLate = false
    private var now = 0.0
    /// Solo per il «gemello» di due casi: l'iPad com'era prima di questo lavoro, senza il punto R.
    var withoutPointR = false

    /// La mappa dei casi ha sempre almeno una sezione.
    init(map: SongMap, band: RigBand) {
        let first = map.sections[0]
        self.map = map
        self.band = band
        self.dsp = RigFollowerDSP(rate: RigNumbers.rate, bpm: first.bpm)
        self.bpb = first.beatsPerBar
        self.engineTempo = first.bpm
        self.seqTempo = first.bpm
        self.screenBpm = first.bpm
    }

    private var sections: [SongMapSection] { map.sections }

    // MARK: Le righe, per tipo

    var anchorsTaken: [RigAnchorTaken] {
        var out: [RigAnchorTaken] = []
        for row in rows {
            if case .anchorTaken(let taken) = row { out.append(taken) }
        }
        return out
    }

    var anchorsAlreadyAlive: Int {
        var out = 0
        for row in rows {
            if case .anchorAlreadyAlive = row { out += 1 }
        }
        return out
    }

    var anchorsNotTaken: [String] {
        var out: [String] = []
        for row in rows {
            if case .anchorNotTaken(let reason) = row { out.append(reason) }
        }
        return out
    }

    var noCounts: [FollowerBandCountClosed?] {
        var out: [FollowerBandCountClosed?] = []
        for row in rows {
            if case .noCount(let closed) = row { out.append(closed) }
        }
        return out
    }

    var readingRows: [RigReadingRow] {
        var out: [RigReadingRow] = []
        for row in rows {
            if case .reading(let reading) = row { out.append(reading) }
        }
        return out
    }

    var recognizedRows: [FollowerBandRenumberingRecognized] {
        var out: [FollowerBandRenumberingRecognized] = []
        for row in rows {
            if case .renumberingRecognized(let recognized) = row { out.append(recognized) }
        }
        return out
    }

    var notCertainReasons: [FollowerBandCountClosed?] {
        var out: [FollowerBandCountClosed?] = []
        for row in rows {
            if case .countNotCertain(let reason) = row { out.append(reason) }
        }
        return out
    }

    var realignRows: [RigRealignRow] {
        var out: [RigRealignRow] = []
        for row in rows {
            if case .realign(let realign) = row { out.append(realign) }
        }
        return out
    }

    var sectionEndAgreements: [Bool] {
        var out: [Bool] = []
        for row in rows {
            if case .sectionEndCheck(_, _, let agrees) = row { out.append(agrees) }
        }
        return out
    }

    var discardedPreloads: [RigDiscardedPreload] {
        var out: [RigDiscardedPreload] = []
        for row in rows {
            if case .preloadDiscarded(let discarded) = row { out.append(discarded) }
        }
        return out
    }

    var lateBeatCorrections: Int {
        var out = 0
        for row in rows {
            if case .lateBeatCorrection = row { out += 1 }
        }
        return out
    }

    var songEndsDelivered: [Double] {
        var out: [Double] = []
        for row in rows {
            if case .songEndDelivered(let callTime) = row { out.append(callTime) }
        }
        return out
    }

    // MARK: Il runner (sul principale)

    /// L'avvio di una sezione dal runner (`SetlistRunner.prepareAndStartCurrentSection`): `loadSection`,
    /// `setSongMap` (il segno della mappa per il prossimo avvio) e il precarico della sezione dopo.
    func loadSectionFromRunner(_ idx: Int) {
        let s = sections[idx]
        bpb = s.beatsPerBar
        dsp.setBeatsPerBar(s.beatsPerBar)
        total = s.rigTotal
        counter = 0
        dsp.setBPM(s.bpm)
        engineTempo = s.bpm
        seqTempo = s.bpm
        screenBpm = s.bpm
        mapSection = idx
        runnerSection = idx
        view.runnerSection(idx)
        mapForNextStart = true
        preload(forSection: idx + 1)
    }

    /// `preloadNextSection(..., forSection:)` sulla coda del motore: il precarico col numero (P41).
    func preload(forSection: Int) {
        guard forSection < sections.count else { return }
        guard SectionPreloadDecision.accepts(preloadSection: forSection, engineSection: mapSection) else {
            rows.append(.preloadDiscarded(RigDiscardedPreload(section: forSection, engineSection: mapSection)))
            return
        }
        pendingNext = forSection
    }

    /// La chiusura di fine sezione del runner, ramo «avanza»: l'indice sale e precarica la sezione dopo.
    func runnerClosure() {
        runnerSection += 1
        view.runnerSection(runnerSection)
        preload(forSection: runnerSection + 1)
    }

    /// `DispatchQueue.main.async`: il blocco gira `mainDelay` secondi dopo.
    private func postMain(_ work: @escaping () -> Void) {
        mainQueue.append((when: now + mainDelay, work: work))
    }

    /// Il principale: in ordine d'arrivo, un blocco non passa davanti a uno accodato prima.
    private func runMain(_ time: Double) {
        while let first = mainQueue.first, first.when <= time {
            mainQueue.removeFirst()
            first.work()
        }
    }

    // MARK: Il Play del Direttore, lo Stop, l'ingresso

    /// `resetFollowerBandCountQ`
    private func resetCount() {
        count = nil
        playTicks = nil
        entryPending = nil
        realignDue = nil
        countedAtDue = nil
    }

    /// Il richiamo del Play del Direttore accettato: il conto di prima finisce (`resetFollowerBandCountQ`,
    /// «play-direttore») e si prende l'ora del Play (`_followerPlayCallbackTicksQ`).
    func playCallback(_ t: Double) {
        resetCount()
        playTicks = RigNumbers.ticks(t)
    }

    /// Lo Stop (`cleanupAfterStopQ`): il conto finisce (`resetFollowerBandCountQ`, «stop»).
    func stop() {
        running = false
        resetCount()
        tick = 0
        counter = 0
        pendingBpmValue = nil
        pendingNext = nil
        sectionEndPending = false
    }

    /// Un'interruzione di sistema o una ripartenza dell'iPad: il motore si ferma senza la pulizia dello Stop.
    func interruption() {
        running = false
    }

    /// Il fuoco dell'ingresso (il lavoro di `armSharedJoin`): il DSP riparte dall'«uno», il seme locale, l'àncora
    /// del conto (`followerBandEntryAtFireQ`), tre buffer senza correzione. `mapArrived` falso: la gara con l'attesa
    /// zero (il fuoco prima della mappa).
    func enter(_ tFire: Double, localSeed: Int = 0, mapArrived: Bool = true) {
        running = true
        tick = 0
        lastCounted = nil
        dsp.resetForStart(0.0)
        pos = 0.0
        // `tFire` è l'istante della battuta di Link (l'ora in cui la band suona quell'«uno»); il primo buffer
        // dell'iPad esce `outDelay` dopo. La linea dell'iPad riparte da 0 alla battuta: la prima correzione la porta
        // avanti di `outDelay` × tempo / 60 battiti. L'àncora del conto si prende all'istante della battuta, non
        // all'ora d'uscita.
        line0 = band.linkBeat(tFire)
        let anchorAt = tFire
        if 0 < localSeed && localSeed < total {
            startOffset = localSeed
            counter = localSeed
        } else {
            startOffset = 0
            counter = 0
        }
        // `followerBandEntryAtFireQ`
        entryPending = nil
        let link = band.linkBeat(anchorAt)
        if count != nil || (mapArrived && mapForNextStart) {
            takeAnchor(entryTicks: RigNumbers.ticks(anchorAt), entryLinkBeat: link, atFire: true)
        } else {
            entryPending = (ticks: RigNumbers.ticks(anchorAt), linkBeat: link)
        }
        if mapArrived {
            mapForNextStart = false
        }
        syncSkip = 3
    }

    /// La mappa arrivata dopo il fuoco (`consumeSongMapForRunningStartQ` alla guardia «avvio-gia-in-moto»).
    func mapArrivesAfterFire() {
        mapForNextStart = false
        if let pending = entryPending {
            entryPending = nil
            takeAnchor(entryTicks: pending.ticks, entryLinkBeat: pending.linkBeat, atFire: false)
        }
    }

    /// `takeFollowerBandAnchorQ`: l'ingresso nel conto (`FollowerBandCount.enter`).
    private func takeAnchor(entryTicks: UInt64, entryLinkBeat: Double, atFire: Bool) {
        let current = count
        let seedPlayTicks: UInt64
        if current == nil {
            guard let play = playTicks else {
                rows.append(.anchorNotTaken(reason: "senza-ora-del-play"))
                return
            }
            seedPlayTicks = play
        } else {
            seedPlayTicks = 0
        }
        let input = FollowerBandSeedInput(map: map, playCallbackTicks: seedPlayTicks, entryTicks: entryTicks,
                                          entryLinkBeat: entryLinkBeat, ticksPerSecond: RigNumbers.tps)
        switch FollowerBandCount.enter(current: current, seed: input) {
        case .anchored(let taken, let seed):
            count = taken
            var seedApplied = false
            if atFire, seed.section == mapSection, total > 0, seed.beatInSection < total {
                startOffset = seed.beatInSection
                counter = seed.beatInSection
                seedApplied = true
            } else {
                noteRealignDue(reason: "ingresso")
            }
            rows.append(.anchorTaken(RigAnchorTaken(section: seed.section, beat: seed.beatInSection,
                                                    delayBeats: seed.callbackDelayBeats, seedApplied: seedApplied)))
        case .kept(let kept):
            count = kept
            noteRealignDue(reason: "ingresso")
            rows.append(.anchorAlreadyAlive)
        case .noCount(let closedCount):
            count = closedCount
            rows.append(.noCount(closed: closedCount.closed))
        }
    }

    /// `noteFollowerRealignDueQ`: il buco vince sugli altri motivi, e prende l'ultimo battito contato adesso.
    private func noteRealignDue(reason: String) {
        guard running, let alive = count, alive.closed == nil else { return }
        if reason == "buco" {
            if countedAtDue == nil {
                countedAtDue = lastCounted
            }
            realignDue = reason
        } else if realignDue == nil {
            realignDue = reason
        }
    }

    /// Il battito a 1 s del Follower (`followerSecondQ`): la rete del conto.
    func secondPulse() {
        noteRealignDue(reason: "al-secondo")
    }

    // MARK: scheduleNextBuffer

    /// Dove la correzione porta la posizione per l'ora d'uscita `tOut`: IN SYNC la linea di Link
    /// (`link_engine_sync_phase`), DA-SOLO la linea propria (`ownClockPinQ`).
    private func positionTarget(_ tOut: Double) -> Double {
        guard !inSync, let own = ownTimeline else {
            return band.linkBeat(tOut) - line0
        }
        return own.position + (tOut - own.time) * own.bpm / 60.0
    }

    /// DA-SOLO: la linea propria si àncora dove sta la posizione, col tempo della propria sezione.
    func goAlone(_ t: Double) {
        inSync = false
        ownTimeline = RigOwnTimeline(time: t + outDelay, position: pos, bpm: engineTempo)
    }

    /// Una chiamata di `scheduleNextBuffer` all'ora `t`. `hole`: è la prima chiamata dopo un buco del render.
    func call(_ t: Double, hole: Bool = false) {
        guard running else { return }
        calls += 1
        now = t
        runMain(t)
        let out = t + outDelay
        if sectionEndPending {
            // Il drenaggio: la chiusura di fine canzone si consegna e questo richiamo non programma niente.
            sectionEndPending = false
            ended = true
            rows.append(.songEndDelivered(callTime: t))
            stop()
            return
        }
        if hole {
            // Il misuratore dice buco: il riallineo è dovuto.
            noteRealignDue(reason: "buco")
        }
        // `_correctionJumpThisCallQ`: `nil` se in questa chiamata la correzione non è stata valutata.
        var jump: Double? = nil
        if syncSkip > 0 {
            syncSkip -= 1
        } else {
            if !inSync && ownTimeline == nil {
                // La linea propria si ri-àncora (dopo un cambio di tempo): nessuna correzione in questa chiamata.
                ownTimeline = RigOwnTimeline(time: out, position: pos, bpm: engineTempo)
            } else {
                let before = pos
                let target = positionTarget(out)
                let delta = target - before
                if abs(delta) > RigNumbers.syncThreshold || !inSync {
                    dsp.setBeatPositionTimeOnly(target)
                    pos = target
                    noteLateBeatCorrection(before: before, after: target)
                    jump = delta
                } else {
                    jump = 0.0
                }
            }
        }
        // Il punto R, come in `scheduleNextBuffer`: col conto vivo, e solo se c'è un motivo.
        if !withoutPointR, count != nil, realignDue != nil || abs(jump ?? 0.0) >= 0.5 {
            pointR(out: out, correctionJump: jump)
        }
        if sectionEndPending {
            return
        }
        runMain(t)
        let events = dsp.process(frames: RigNumbers.frames)
        pos += RigNumbers.buf * seqTempo / 60.0
        let mutedFlag = muteLate
        muteLate = false
        for (n, event) in events.enumerated() {
            let beatOut = out + Double(event.offset) / RigNumbers.rate
            let muted = mutedFlag && n == 0 && event.offset == 0
            if muted {
                lateMuted += 1
            }
            tick += 1
            lastCounted = FollowerCountedBeat(section: mapSection, beatInSection: total > 0 ? counter : -1,
                                              ticks: RigNumbers.ticks(beatOut))
            beats.append(RigBeat(outTime: RigNumbers.round6(beatOut), section: mapSection, beatInSection: counter,
                                 label: event.label, accent: event.accent, muted: muted))
            view.tick(tick, startOffset: startOffset, bpb: bpb)
            if let pending = pendingBpmValue, tick == pendingBpmTargetTick {
                // Il tempo armato allo scambio: il primo battito della sezione nuova, e la W2 (solo IN SYNC).
                engineTempo = pending
                seqTempo = pending
                ownTimeline = nil
                if inSync {
                    w2.append(RigW2(section: mapSection, outTime: beatOut))
                }
                screenBpm = pending
                pendingBpmValue = nil
                pendingBpmTargetTick = 0
            }
            if total > 0 {
                counter += 1
                if counter >= total {
                    sectionEndCheck(section: mapSection, beatInSection: total - 1,
                                    outTicks: RigNumbers.ticks(beatOut))
                    if let nextIdx = pendingNext {
                        // Il ramo SEAMLESS: lo scambio di sezione.
                        let next = sections[nextIdx]
                        pendingNext = nil
                        total = next.rigTotal
                        counter = 0
                        mapSection += 1
                        bpb = next.beatsPerBar
                        dsp.scheduleBpb(next.beatsPerBar)
                        dsp.scheduleBpm(next.bpm)
                        syncSkip = max(syncSkip, RigNumbers.window)
                        pendingBpmValue = next.bpm
                        pendingBpmTargetTick = tick + 1
                        postMain { [weak self] in
                            self?.runnerClosure()
                        }
                    } else {
                        // Il ramo del drenaggio: fine canzone.
                        sectionEndPending = true
                        counter = 0
                    }
                }
            }
        }
    }

    /// `noteLateBeatCorrectionQ` — U9 col getter (P38): il battito in attesa lo dice il DSP, letto subito dopo la
    /// correzione; la regola è quella vera (`LateBeatDecision.lateBeats(pendingBeat:after:)` e `mutesLateBeat`).
    private func noteLateBeatCorrection(before: Double, after: Double) {
        let pending = dsp.pendingBeat
        let late = LateBeatDecision.lateBeats(pendingBeat: pending, after: after)
        guard LateBeatDecision.mutesLateBeat(lateBeats: late, bpm: engineTempo, bufferFrames: RigNumbers.frames,
                                             sampleRate: RigNumbers.rate) else {
            return
        }
        muteLate = true
        rows.append(.lateBeatCorrection(before: before, after: after, pendingBeat: pending))
    }

    /// `readFollowerBandCountQ`: IN SYNC il battito della sessione all'ora `ticks`; DA-SOLO Link non si chiama, e il
    /// battito è quello che il righello dei secondi dà dall'àncora. `nil` se il conto non ha l'àncora.
    private func readCount(_ count: inout FollowerBandCount, ticks: UInt64,
                           lastCounted: FollowerCountedBeat?) -> FollowerBandReading? {
        let tps = RigNumbers.tps
        let linkBeat: Double
        if inSync {
            linkBeat = band.linkBeat(Double(ticks) / tps)
        } else {
            guard let anchor = count.anchor else { return nil }
            let ruler = ShowClock(map: count.map, anchor: anchor).bySeconds(nowTicks: ticks, ticksPerSecond: tps)
            linkBeat = anchor.linkBeat + ruler.beatsFromAnchor
        }
        return count.read(pendingLinkBeat: linkBeat, pendingTicks: ticks, ticksPerSecond: tps,
                          lastCounted: lastCounted)
    }

    /// `followerBandCountPointRQ` — IL PUNTO R: dopo il blocco della fase e prima di `process`. Dopo un buco aspetta
    /// la prima chiamata con la correzione valutata; l'ora del battito in attesa è l'ora d'uscita del buffer più i
    /// suoi campioni (P37).
    private func pointR(out: Double, correctionJump: Double?) {
        guard var alive = count, alive.closed == nil else { return }
        let reason: String
        if let due = realignDue {
            if due == "buco" && correctionJump == nil { return }
            reason = due
        } else if let jump = correctionJump, abs(jump) >= 0.5 {
            reason = "correzione"
        } else {
            return
        }
        let aheadSamples = max(dsp.pendingSamplesAhead, 0)
        let pendingTicks = RigNumbers.ticks(out + Double(aheadSamples) / RigNumbers.rate)
        let stateBefore = alive.renumbering
        let last = countedAtDue ?? lastCounted
        // Il motivo si consuma qui.
        realignDue = nil
        countedAtDue = nil
        guard let reading = readCount(&alive, ticks: pendingTicks, lastCounted: last) else { return }
        count = alive
        readings += 1
        rows.append(.reading(RigReadingRow(reason: reason, gapBeats: reading.gapBeats, certain: reading.certain,
                                           state: alive.renumbering, stateBefore: stateBefore,
                                           pendingBeat: dsp.pendingBeat, samplesAhead: aheadSamples)))
        if let recognized = reading.recognized {
            rows.append(.renumberingRecognized(recognized))
        }
        guard reading.certain, let place = reading.place else {
            rows.append(.countNotCertain(reason: reading.reason))
            return
        }
        realign(place: place, reason: reason)
    }

    /// `loadFollowerSectionForRealignQ`: la sezione coi setter immediati (prima il tempo, poi il metro), i cambi
    /// armati annullati, la successiva precaricata. Rende falso, senza toccare niente, se la sezione non esiste.
    private func loadSectionForRealign(_ idx: Int) -> Bool {
        guard idx >= 0, idx < sections.count else { return false }
        let arrival = sections[idx]
        dsp.cancelPending()
        pendingBpmValue = nil
        pendingBpmTargetTick = 0
        pendingNext = nil
        sectionEndPending = false
        dsp.setBPM(arrival.bpm)
        dsp.setBeatsPerBar(arrival.beatsPerBar)
        engineTempo = arrival.bpm
        seqTempo = arrival.bpm
        screenBpm = arrival.bpm
        ownTimeline = nil
        bpb = arrival.beatsPerBar
        total = arrival.rigTotal
        mapSection = idx
        if idx + 1 < sections.count {
            pendingNext = idx + 1
        }
        return true
    }

    /// `followerSongBeatQ`: i battiti della canzone dall'inizio fino a `beat` della sezione `section`.
    func songBeat(section: Int, beat: Int) -> Int {
        var sum = beat
        var index = 0
        while index < section && index < sections.count {
            sum += sections[index].rigTotal
            index += 1
        }
        return sum
    }

    /// `followerRealignQ` — IL RIALLINEO: la sezione (se è un'altra, se un tempo è armato o se il motore drenava),
    /// il contatore, l'etichetta del battito in attesa nel DSP per ultima, la grafica, il runner e il messaggio alla
    /// vista sul principale; oltre la fine della canzone la chiusura si consegna adesso. Mai un click spostato.
    private func realign(place: FollowerBandPlace, reason: String) {
        let motorSection = mapSection
        let motorBeat = counter
        let wasDraining = sectionEndPending
        let tempoArmed = pendingBpmValue != nil
        let lastSection = sections.count - 1
        let pendingBefore = RigPending(beat: dsp.pendingBeat, samplesAhead: dsp.pendingSamplesAhead)
        let bandSection: Int
        let bandBeat: Int
        let bandBeatInBar: Int
        switch place {
        case .pastEnd:
            // La band ha finito la canzone. Se il motore drena già, niente da fare.
            guard !wasDraining else { return }
            var sectionChanged = false
            if motorSection != lastSection || tempoArmed {
                guard loadSectionForRealign(lastSection) else { return }
                sectionChanged = motorSection != lastSection
            }
            sectionEndPending = true
            counter = 0
            realigns += 1
            if sectionChanged {
                postMain { [weak self] in
                    self?.runnerRejoin(lastSection)
                }
            }
            rows.append(.realign(RigRealignRow(reason: reason,
                                               motor: RigSpot(section: motorSection, beat: motorBeat),
                                               callTime: RigNumbers.round4(now), inSong: nil)))
            return
        case .inSong(let section, let beatInSection, let beatInBar):
            bandSection = section
            bandBeat = beatInSection
            bandBeatInBar = beatInBar
        }
        let sectionDiffers = bandSection != motorSection
        // Col posto della band uguale a quello del motore non si tocca niente, anche con un tempo armato.
        guard sectionDiffers || bandBeat != motorBeat || wasDraining else { return }
        let motorSongBeat: Int
        if wasDraining {
            motorSongBeat = songBeat(section: motorSection + 1, beat: 0)
        } else {
            motorSongBeat = songBeat(section: motorSection, beat: motorBeat)
        }
        let jumpBeats = songBeat(section: bandSection, beat: bandBeat) - motorSongBeat
        // (1) La sezione.
        let loadsSection = sectionDiffers || wasDraining || tempoArmed
        if loadsSection {
            guard loadSectionForRealign(bandSection) else { return }
        }
        // (2) Il contatore.
        if total > 0 {
            counter = min(max(bandBeat, 0), total - 1)
        } else {
            counter = 0
        }
        // (3) Il DSP: la rinomina, per ultima.
        dsp.renamePendingBeat(max(bandBeatInBar, 0))
        let pendingAfter = RigPending(beat: dsp.pendingBeat, samplesAhead: dsp.pendingSamplesAhead)
        // (4) La grafica.
        if tick == 0 {
            // Nessun battito ancora uscito da questo avvio: il primo tick resta il primo, col seme = il battito
            // della band.
            startOffset = counter
        } else {
            tick = max(tick + jumpBeats, 1)
        }
        realigns += 1
        // (4)-(5) Sul principale: prima il runner (solo se la sezione è cambiata), poi il messaggio alla vista.
        let message = SectionRealign(sectionIdx: bandSection, nextTick: tick + 1, sectionBeat: counter + 1)
        postMain { [weak self] in
            guard let self else { return }
            if sectionDiffers {
                self.runnerRejoin(bandSection)
            }
            self.view.realign(message)
        }
        // (7) La riga.
        let detail = RigRealignDetail(band: RigSpot(section: bandSection, beat: bandBeat), jumpBeats: jumpBeats,
                                      loadsSection: loadsSection, tempoArmed: tempoArmed,
                                      pendingBefore: pendingBefore, pendingAfter: pendingAfter)
        rows.append(.realign(RigRealignRow(reason: reason, motor: RigSpot(section: motorSection, beat: motorBeat),
                                           callTime: RigNumbers.round4(now), inSong: detail)))
    }

    /// Il runner riportato sulla sezione della band (`.rejoin` → `moveToSection`, senza avvio).
    private func runnerRejoin(_ idx: Int) {
        runnerSection = idx
        runnerRejoins.append(idx)
        view.runnerSection(idx)
    }

    /// `logFollowerSectionEndCheckQ`: la riga di controllo a fine sezione, letta su una COPIA del conto.
    private func sectionEndCheck(section: Int, beatInSection: Int, outTicks: UInt64) {
        guard let alive = count, alive.closed == nil else { return }
        var probe = alive
        guard let reading = readCount(&probe, ticks: outTicks, lastCounted: lastCounted) else { return }
        var bandSpot: RigSpot? = nil
        var agrees = false
        if reading.certain, let place = reading.place {
            switch place {
            case .inSong(let bandSection, let bandBeat, _):
                bandSpot = RigSpot(section: bandSection, beat: bandBeat)
                agrees = bandSection == section && bandBeat == beatInSection
            case .pastEnd:
                break
            }
        }
        rows.append(.sectionEndCheck(motor: RigSpot(section: section, beat: beatInSection), band: bandSpot,
                                     agrees: agrees))
    }

    // MARK: Aiuti per gli scenari

    /// Chiamate ogni 10,667 ms da `tFrom` a `tTo`; `holes`: (inizio, fine) dove le chiamate non arrivano. Il battito
    /// a 1 s cade a ogni secondo intero dall'ora d'ingresso. Rende l'ora della chiamata dopo.
    @discardableResult
    func run(from tFrom: Double, to tTo: Double, holes: [(Double, Double)] = [], pulses: Bool = true) -> Double {
        var t = tFrom
        var lastPulse = tFrom.rounded(.down)
        var afterHole = false
        while t < tTo - 1e-9 {
            var inHole = false
            for (start, end) in holes where start <= t && t < end {
                inHole = true
            }
            if inHole {
                afterHole = true
            } else {
                if pulses && t.rounded(.down) > lastPulse {
                    lastPulse = t.rounded(.down)
                    secondPulse()
                }
                call(t, hole: afterHole)
                afterHole = false
            }
            t += RigNumbers.buf
        }
        return t
    }
}

// MARK: - I casi

final class FollowerBandRigTests: XCTestCase {

    private struct NotTheExpectedCase: Error {}

    /// L'ora del primo battito della band.
    private let play = 10.0
    /// Il richiamo del Play arriva 50 ms dopo.
    private let callback = 0.05
    private let buf = RigNumbers.buf

    private func song(_ sections: [(Int, Int, Double)]) -> SongMap {
        SongMap(sections: sections.map { SongMapSection(beatsPerBar: $0.0, repetitions: $0.1, bpm: $0.2) })
    }

    /// La canzone a due sezioni (121 → 91): il confine a 32 battiti, 15,868 s dal Play.
    private var two: SongMap { song([(4, 8, 121.0), (4, 16, 91.0)]) }

    /// La canzone del 01/11: 7/4 a 150, 9/4 a 180,5, 4/4 a 121.
    private var songA: SongMap { song([(7, 4, 150.0), (9, 4, 180.5), (4, 16, 121.0)]) }

    /// L'ora (dal Play) del battito `songBeat` della canzone.
    private func beatTime(_ map: SongMap, _ songBeat: Int) -> Double {
        var t = 0.0
        var left = songBeat
        for s in map.sections {
            if left < s.rigTotal {
                return t + Double(left) * 60.0 / s.bpm
            }
            t += Double(s.rigTotal) * 60.0 / s.bpm
            left -= s.rigTotal
        }
        return t + Double(left) * 60.0 / map.sections[map.sections.count - 1].bpm
    }

    /// La band parte a `play`; l'iPad sente il Play 50 ms dopo, il runner carica la prima sezione e il fuoco
    /// dell'ingresso cade sull'istante del battito `entryBeat` della canzone (una battuta di Link); il primo buffer
    /// esce `outDelay` dopo. `renumbers`: (secondi dal Play, salto). Rende il rig, la band e l'ora del fuoco.
    private func started(_ map: SongMap, entryBeat: Int = 4, localSeed: Int = 0,
                         renumbers: [(Double, Double)] = [], mapArrived: Bool = true, outDelay: Double? = nil,
                         withoutPointR: Bool = false) -> (FollowerBandRig, RigBand, Double) {
        var band = RigBand(map: map, tPlay: play)
        for (after, jump) in renumbers {
            band.renumbers.append((at: play + after, jump: jump))
        }
        let f = FollowerBandRig(map: map, band: band)
        f.withoutPointR = withoutPointR
        if let delay = outDelay {
            f.outDelay = delay
        }
        f.playCallback(play + callback)
        if mapArrived {
            f.loadSectionFromRunner(0)
        }
        let tFire = play + beatTime(map, entryBeat)
        f.enter(tFire, localSeed: localSeed, mapArrived: mapArrived)
        return (f, band, tFire)
    }

    /// Il battito della canzone che la band suona all'ora `t`, al più vicino. Nel modello Python è `round`, «i mezzi
    /// al pari»: le ore dei casi non cadono mai su un mezzo esatto, e qui basta `.rounded()`.
    private func bandSongBeat(_ band: RigBand, _ t: Double) -> Int {
        Int(band.songBeats(t).rounded())
    }

    /// I battiti usciti il cui nome (sezione, battito) non è quello della band alla loro ora d'uscita.
    private func wrongNames(_ f: FollowerBandRig, _ band: RigBand) -> [RigBeat] {
        var out: [RigBeat] = []
        for b in f.beats where bandSongBeat(band, b.outTime) != f.songBeat(section: b.section, beat: b.beatInSection) {
            out.append(b)
        }
        return out
    }

    /// I nomi sbagliati fra i battiti usciti da `t0` in poi.
    private func wrongNamesAfter(_ f: FollowerBandRig, _ band: RigBand, _ t0: Double) -> [RigBeat] {
        wrongNames(f, band).filter { $0.outTime >= t0 }
    }

    /// I battiti usciti la cui etichetta del DSP (la posizione nella battuta) non è quella della band.
    private func wrongLabels(_ f: FollowerBandRig, _ band: RigBand) -> [RigBeat] {
        var out: [RigBeat] = []
        for b in f.beats {
            var left = bandSongBeat(band, b.outTime)
            for s in f.map.sections {
                if left < s.rigTotal {
                    if b.label != left % s.beatsPerBar {
                        out.append(b)
                    }
                    break
                }
                left -= s.rigTotal
            }
        }
        return out
    }

    /// Le etichette sbagliate fra i battiti usciti da `t0` in poi.
    private func wrongLabelsAfter(_ f: FollowerBandRig, _ band: RigBand, _ t0: Double) -> [RigBeat] {
        wrongLabels(f, band).filter { $0.outTime >= t0 }
    }

    /// L'ora d'uscita del buffer dell'ultimo riallineo.
    private func lastRealignOut(_ f: FollowerBandRig, file: StaticString = #filePath,
                                line: UInt = #line) throws -> Double {
        let last = try XCTUnwrap(f.realignRows.last, "nessun riallineo", file: file, line: line)
        return last.callTime + f.outDelay
    }

    /// L'unico riallineo del rig, coi suoi campi «dentro la canzone».
    private func singleRealign(_ f: FollowerBandRig, file: StaticString = #filePath,
                               line: UInt = #line) throws -> (row: RigRealignRow, detail: RigRealignDetail) {
        let all = f.realignRows
        XCTAssertEqual(all.count, 1, "i riallinei", file: file, line: line)
        let row = try XCTUnwrap(all.first, "nessun riallineo", file: file, line: line)
        let detail = try XCTUnwrap(row.inSong, "il riallineo è «oltre la fine»", file: file, line: line)
        return (row, detail)
    }

    /// L'unica lettura del rig.
    private func singleReading(_ f: FollowerBandRig, file: StaticString = #filePath,
                               line: UInt = #line) throws -> RigReadingRow {
        let all = f.readingRows
        XCTAssertEqual(all.count, 1, "le letture", file: file, line: line)
        return try XCTUnwrap(all.first, "nessuna lettura", file: file, line: line)
    }

    /// L'unica riga «ancora presa», coi suoi campi; il ritardo a quattro decimali, come nel modello.
    private func assertSingleAnchorTaken(_ f: FollowerBandRig, section: Int, beat: Int, delayBeats: Double,
                                         seedApplied: Bool, file: StaticString = #filePath,
                                         line: UInt = #line) throws {
        let all = f.anchorsTaken
        XCTAssertEqual(all.count, 1, "le ancore prese", file: file, line: line)
        let row = try XCTUnwrap(all.first, "nessuna ancora presa", file: file, line: line)
        XCTAssertEqual(row.section, section, file: file, line: line)
        XCTAssertEqual(row.beat, beat, file: file, line: line)
        XCTAssertEqual(row.delayBeats, delayBeats, accuracy: 0.00005, file: file, line: line)
        XCTAssertEqual(row.seedApplied, seedApplied, file: file, line: line)
    }

    /// Le rinumerazioni riconosciute: i confini, e i salti a quattro decimali, come nel modello.
    private func assertRecognized(_ f: FollowerBandRig, _ expected: [(Int, Double)],
                                  file: StaticString = #filePath, line: UInt = #line) {
        let all = f.recognizedRows
        XCTAssertEqual(all.map { $0.boundary }, expected.map { $0.0 }, file: file, line: line)
        for (row, wanted) in zip(all, expected) {
            XCTAssertEqual(row.jump, wanted.1, accuracy: 0.00005, file: file, line: line)
        }
    }

    /// L'àncora del conto vivo.
    private func anchor(_ f: FollowerBandRig, file: StaticString = #filePath,
                        line: UInt = #line) throws -> ShowClockAnchor {
        let alive = try XCTUnwrap(f.count, "nessun conto", file: file, line: line)
        return try XCTUnwrap(alive.anchor, "il conto non ha l'àncora", file: file, line: line)
    }

    /// Un elemento di una lista, senza uscire dai suoi indici.
    private func item<T>(_ items: [T], _ index: Int, file: StaticString = #filePath,
                         line: UInt = #line) throws -> T {
        guard items.indices.contains(index) else {
            XCTFail("indice \(index) fuori da una lista di \(items.count)", file: file, line: line)
            throw NotTheExpectedCase()
        }
        return items[index]
    }

    /// Chiamate ogni 10,667 ms da `start` finché `condition` è vera (guardata prima di ogni chiamata); rende l'ora
    /// della chiamata dopo. Il tetto ferma un giro che non finisce.
    private func callWhile(_ f: FollowerBandRig, from start: Double, limit: Int = 4000,
                           file: StaticString = #filePath, line: UInt = #line,
                           _ condition: (FollowerBandRig) -> Bool) throws -> Double {
        var t = start
        var n = 0
        while condition(f) {
            f.call(t)
            t += buf
            n += 1
            if n >= limit {
                XCTFail("la condizione non arriva", file: file, line: line)
                throw NotTheExpectedCase()
            }
        }
        return t
    }

    /// Chiamate ogni 10,667 ms da `start` finché `condition` diventa vera (dopo la chiamata); rende l'ora della
    /// chiamata dopo.
    private func runUntil(_ f: FollowerBandRig, from start: Double, file: StaticString = #filePath,
                          line: UInt = #line, _ condition: (FollowerBandRig) -> Bool) throws -> Double {
        var t = start
        var n = 0
        while !condition(f) {
            f.call(t)
            t += buf
            n += 1
            if n >= 4000 {
                XCTFail("la condizione non arriva", file: file, line: line)
                throw NotTheExpectedCase()
            }
        }
        return t
    }

    // MARK: - L'ingresso e il seme dalla band

    /// 29/10 sera: l'iPad entra una battuta dopo il Play (il seme locale direbbe 0, «seed SKIP»): il seme dalla
    /// band è 4.
    func testTheSeedFromTheBandReplacesTheLocalSeedAtTheEntry() throws {
        let map = song([(4, 16, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4, localSeed: 0)
        try assertSingleAnchorTaken(f, section: 0, beat: 4, delayBeats: callback * 121.0 / 60.0, seedApplied: true)
        XCTAssertEqual(f.counter, 4)
        XCTAssertEqual(f.startOffset, 4)
        f.run(from: t, to: t + 4.0)
        XCTAssertEqual(wrongNames(f, band), [])
        XCTAssertEqual(wrongLabels(f, band), [])
        XCTAssertEqual(f.realigns, 0)
        // il primo tick: battuta 2, battito 1
        XCTAssertEqual(f.view.shown.first, RigShown(tick: 1, bar: 2, beat: 1))
    }

    /// Mezza battuta in 2/4 (P33): l'ingresso cade un battito dopo l'inizio di battuta della band. Nessuna àncora e
    /// nessun conto per tutta la canzone: il conto chiuso si tiene, nessuna lettura e nessun riallineo, nemmeno dopo
    /// un buco o al battito a 1 s; l'iPad va come prima.
    func testASeedOffBarGivesNoCountAndTheIPadGoesAsToday() throws {
        let map = song([(2, 32, 121.0)])
        let (f, _, t) = started(map, entryBeat: 3)
        let expected: [FollowerBandCountClosed?] = [FollowerBandCountClosed.seedOffBar]
        XCTAssertEqual(f.noCounts, expected)
        let kept = try XCTUnwrap(f.count)
        XCTAssertEqual(kept.closed, FollowerBandCountClosed.seedOffBar)
        XCTAssertNil(kept.anchor)
        f.run(from: t, to: t + 6.0, holes: [(t + 2.0, t + 2.8)])
        XCTAssertEqual(f.readings, 0)
        XCTAssertEqual(f.realigns, 0)
        XCTAssertEqual(f.readingRows.count, 0)
        XCTAssertNil(f.realignDue)
        XCTAssertTrue(f.running)
        XCTAssertGreaterThan(f.beats.count, 8)
    }

    /// Un ingresso senza il richiamo del Play di questa canzone (per esempio dopo uno Stop): nessun conto, l'iPad
    /// come prima.
    func testWithoutThePlayTimeThereIsNoCount() throws {
        let map = song([(4, 16, 121.0)])
        let band = RigBand(map: map, tPlay: play)
        let f = FollowerBandRig(map: map, band: band)
        f.loadSectionFromRunner(0)
        let t = play + beatTime(map, 4)
        f.enter(t, localSeed: 0)
        XCTAssertNil(f.count)
        XCTAssertEqual(f.anchorsNotTaken, ["senza-ora-del-play"])
        f.run(from: t, to: t + 3.0, holes: [(t + 1.0, t + 1.8)])
        XCTAssertEqual(f.readings, 0)
        XCTAssertEqual(f.realigns, 0)
        // come oggi: il conto resta indietro
        XCTAssertGreaterThan(wrongNames(f, band).count, 0)
    }

    /// La gara con l'attesa zero: il fuoco passa prima della mappa, tiene i suoi numeri; alla mappa l'àncora si
    /// prende e il riallineo è dovuto (i buffer sono già partiti): il seme lo mette il riallineo, alla chiamata dopo.
    func testTheMapArrivingAfterTheFireTakesTheAnchorThen() throws {
        let map = song([(4, 16, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4, localSeed: 0, mapArrived: false)
        XCTAssertNil(f.count)
        XCTAssertNotNil(f.entryPending)
        // il primo buffer parte col seme locale (0)
        f.call(t)
        f.loadSectionFromRunner(0)
        // il runner ha caricato la sezione: il battito già uscito resta contato
        f.counter = 1
        f.mapArrivesAfterFire()
        try assertSingleAnchorTaken(f, section: 0, beat: 4, delayBeats: callback * 121.0 / 60.0, seedApplied: false)
        XCTAssertEqual(f.realignDue, "ingresso")
        f.run(from: t + buf, to: t + 3.0)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "ingresso")
        XCTAssertEqual(r.detail.band, RigSpot(section: 0, beat: 5))
        XCTAssertEqual(r.detail.jumpBeats, 4)
        // dal secondo battito i nomi sono quelli della band
        XCTAssertEqual(Array(wrongNames(f, band).dropFirst()), [])
    }

    /// Una cassa Bluetooth: il primo buffer dell'iPad esce 180 ms dopo la battuta di Link del fuoco. A 180 quei
    /// 180 ms sono 0,54 battiti: la band è già oltre la battuta di più di mezzo battito. L'àncora «inizio di battuta
    /// ↔ battito della sessione» si prende all'istante della battuta: i posti del conto sono quelli della band e
    /// nessun riallineo sposta niente. Presa all'ora d'uscita, tutti i posti sarebbero un battito indietro.
    func testTheAnchorIsTakenAtTheBarInstantNotAtTheOutputTime() throws {
        let map = song([(4, 32, 180.0)])
        let (f, band, t) = started(map, entryBeat: 4, outDelay: 0.180)
        XCTAssertGreaterThan(0.180 * 180.0 / 60.0, 0.5)
        let taken = try XCTUnwrap(f.anchorsTaken.first)
        XCTAssertEqual(taken.section, 0)
        XCTAssertEqual(taken.beat, 4)
        f.run(from: t, to: t + 6.0)
        // dopo la prima correzione i click sono sui battiti della band
        let late = f.beats.filter { $0.outTime >= t + 1.0 }
        XCTAssertEqual(wrongNamesAfter(f, band, t + 1.0), [])
        XCTAssertEqual(f.realignRows.filter { $0.callTime >= t + 1.0 }.count, 0)
        XCTAssertGreaterThan(late.count, 10)
    }

    // MARK: - Il riallineo dopo un buco

    /// I quattro tempi del 29/10 coi loro buchi: 1,61 battiti a 121 (+2), 1,19 a 91 (+1), 1,86 a 141 (+2), 1,30 a
    /// 101 in 6/8 (+1). Gli stessi click alle stesse ore di una corsa senza il conto; i nomi giusti solo col conto.
    func testTheHolesOfThe29thOfOctoberAreRealigned() throws {
        let cases: [(Double, Int, Double, Int)] = [(121.0, 4, 1.61, 2), (91.0, 4, 1.19, 1), (141.0, 4, 1.86, 2),
                                                   (101.0, 6, 1.30, 1)]
        for (bpm, bpb, holeBeats, jump) in cases {
            let map = song([(bpb, 24, bpm)])
            let hole = holeBeats * 60.0 / bpm
            // la stessa corsa due volte: col conto, e col «gemello» senza il punto R (l'iPad com'era)
            func runOnce(withoutPointR: Bool) -> (FollowerBandRig, RigBand) {
                let (rig, rigBand, t) = started(map, entryBeat: bpb, withoutPointR: withoutPointR)
                let start = t + 9.3 * 60.0 / bpm
                rig.run(from: t, to: t + 20.0 * 60.0 / bpm, holes: [(start, start + hole)])
                return (rig, rigBand)
            }
            let (f, band) = runOnce(withoutPointR: false)
            let (old, oldBand) = runOnce(withoutPointR: true)
            let r = try singleRealign(f)
            XCTAssertEqual(r.row.reason, "buco", "\(bpm)")
            XCTAssertEqual(r.detail.jumpBeats, jump, "\(bpm)")
            XCTAssertEqual(wrongNames(f, band), [], "\(bpm)")
            XCTAssertEqual(wrongLabels(f, band), [], "\(bpm)")
            XCTAssertEqual(f.beats.map { $0.outTime }, old.beats.map { $0.outTime }, "\(bpm): i click alle stesse ore")
            // la grafica: dopo il riallineo il contatore dei battiti è salito del salto (il tick dell'ultimo battito
            // è il suo numero nella canzone dall'ingresso), senza il conto è rimasto indietro
            let last = try XCTUnwrap(f.beats.last)
            let shown = try XCTUnwrap(f.view.shown.last)
            let oldShown = try XCTUnwrap(old.view.shown.last)
            XCTAssertEqual(shown.tick, f.songBeat(section: last.section, beat: last.beatInSection) - bpb + 1,
                           "\(bpm): il tick")
            XCTAssertEqual(oldShown.tick, shown.tick - jump, "\(bpm): il tick senza il conto")
            XCTAssertGreaterThan(wrongNames(old, oldBand).count, 0, "\(bpm)")
            // l'identità del battito in attesa non cambia con la rinomina, e nemmeno i suoi campioni
            XCTAssertEqual(r.detail.pendingBefore, r.detail.pendingAfter, "\(bpm)")
        }
    }

    /// A424 par. 2.2 c: un buco nella finestra «sync skip» dopo uno scambio di sezione. Il riallineo non si fa
    /// nella chiamata del buco (la posizione non è corretta): cade alla prima chiamata dopo la finestra.
    func testTheRealignAfterAHoleWaitsForTheEvaluatedCorrection() throws {
        let map = song([(4, 2, 121.0), (4, 16, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        let boundary = play + beatTime(map, 8)
        var swapCall: Int? = nil
        var doneCall: Int? = nil
        let holeStart = boundary + 10.0 * buf
        let holeEnd = boundary + 10.0 * buf + 0.8
        var tt = t
        while tt < boundary + 3.0 {
            let before = f.mapSection
            if !(holeStart <= tt && tt < holeEnd) {
                f.call(tt, hole: holeEnd <= tt && tt < holeEnd + buf)
            }
            if swapCall == nil && f.mapSection != before {
                swapCall = f.calls
            }
            if doneCall == nil && !f.realignRows.isEmpty {
                doneCall = f.calls
            }
            tt += buf
        }
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "buco")
        // la centunesima chiamata dopo lo scambio
        let done = try XCTUnwrap(doneCall)
        let swap = try XCTUnwrap(swapCall)
        XCTAssertEqual(done - swap, RigNumbers.window + 1)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        // prima, nella finestra, i battiti hanno il nome di prima (come oggi)
        XCTAssertGreaterThan(wrongNames(f, band).count, 0)
    }

    /// Il caso 2 del punto R: una correzione di almeno mezzo battito senza nessun buco visto dal misuratore. Qui la
    /// linea dell'iPad viene rinumerata di un battito intero: la correzione salta di +1,0, il conto si legge (una
    /// lettura, motivo «correzione»), e siccome i click non si sono mossi nel tempo il posto della band è quello del
    /// motore: nessun riallineo, i nomi restano giusti.
    func testAHalfBeatCorrectionWithoutAHoleIsRead() throws {
        let map = song([(4, 24, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 2.0, pulses: false)
        f.line0 -= 1.0
        f.run(from: t + 2.0 + buf, to: t + 4.0, pulses: false)
        let reading = try singleReading(f)
        XCTAssertEqual(reading.reason, "correzione")
        XCTAssertTrue(reading.certain)
        XCTAssertEqual(f.realignRows.count, 0)
        XCTAssertEqual(wrongNames(f, band), [])
        XCTAssertEqual(wrongLabels(f, band), [])
    }

    /// Il caso 3: il contatore dell'iPad perde un battito senza buco e senza correzione (qui a mano): al secondo il
    /// riallineo è dovuto, e la lettura alla chiamata dopo lo rimette.
    func testTheSecondPulseIsTheNet() throws {
        let map = song([(4, 24, 121.0)])
        let (f, _, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 1.5, pulses: false)
        f.counter -= 1
        f.secondPulse()
        f.call(t + 1.5 + buf)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "al-secondo")
        XCTAssertEqual(r.detail.jumpBeats, 1)
    }

    // MARK: - La sezione, la W2, la grafica

    /// 29/10, la canzone a due sezioni (121 → 91): quattro buchi a 121 da 1,61 battiti. Senza il conto l'iPad
    /// cambia sezione 8 battiti dopo la band; col conto cambia insieme alla band e la W2 esce al confine giusto,
    /// una volta.
    func testTheSectionChangesWithTheBandAndTheW2IsAtTheRightBoundary() throws {
        let map = two
        let hole = 1.61 * 60.0 / 121.0
        var holes: [(Double, Double)] = []
        for i in 0..<4 {
            holes.append((play + 3.0 + Double(i) * 3.0, play + 3.0 + Double(i) * 3.0 + hole))
        }
        let boundary = play + beatTime(map, 32)
        // la stessa corsa due volte: col conto, e col «gemello» senza il punto R (l'iPad com'era)
        func runOnce(withoutPointR: Bool) -> (FollowerBandRig, RigBand) {
            let (rig, rigBand, t) = started(map, entryBeat: 4, withoutPointR: withoutPointR)
            rig.run(from: t, to: boundary + 6.0, holes: holes)
            return (rig, rigBand)
        }
        let (f, band) = runOnce(withoutPointR: false)
        let (old, _) = runOnce(withoutPointR: true)
        XCTAssertEqual(f.realignRows.count, 4)
        XCTAssertEqual(f.w2.count, 1)
        let w2 = try XCTUnwrap(f.w2.first)
        XCTAssertEqual(w2.section, 1)
        XCTAssertEqual(w2.outTime, boundary, accuracy: 0.03, "la W2 al confine della band")
        XCTAssertEqual(wrongNames(f, band), [])
        // senza il conto: la W2 esce 8 battiti dopo, a 91 (5,27 s)
        XCTAssertEqual(old.w2.count, 1)
        let oldW2 = try XCTUnwrap(old.w2.first)
        XCTAssertEqual(oldW2.outTime - boundary, 8.0 * 60.0 / 91.0, accuracy: 0.2)
        // il controllo di fine sezione: d'accordo
        XCTAssertEqual(f.sectionEndAgreements, [true])
        // il runner è avanzato con la chiusura, non col riallineo
        XCTAssertEqual(f.runnerSection, 1)
        XCTAssertEqual(f.runnerRejoins, [])
    }

    /// Un buco che passa il confine: la band è già nella sezione dopo. Il riallineo carica la sezione coi setter
    /// immediati (tempo, metro), precarica la successiva, muove il runner e manda il messaggio alla vista; NIENTE
    /// W2 per il confine passato nel buco.
    func testAHoleAcrossTheBoundaryLoadsTheSectionWithoutW2() throws {
        let map = song([(4, 8, 121.0), (3, 8, 91.0), (4, 8, 141.0)])
        let boundary = play + beatTime(map, 32)
        let (f, band, t) = started(map, entryBeat: 4)
        f.run(from: t, to: boundary + 5.0, holes: [(boundary - 1.0, boundary + 0.5)])
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.motor.section, 0)
        XCTAssertEqual(r.detail.band.section, 1)
        XCTAssertTrue(r.detail.loadsSection)
        XCTAssertEqual(f.w2, [])
        XCTAssertEqual(f.mapSection, 1)
        XCTAssertEqual(f.bpb, 3)
        XCTAssertEqual(f.engineTempo, 91.0)
        XCTAssertEqual(f.seqTempo, 91.0)
        XCTAssertEqual(f.screenBpm, 91.0)
        XCTAssertEqual(f.dsp.bpb, 3)
        XCTAssertEqual(f.dsp.bpm, 91.0)
        XCTAssertEqual(f.pendingNext, 2)
        XCTAssertEqual(f.runnerRejoins, [1])
        XCTAssertEqual(f.runnerSection, 1)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        XCTAssertEqual(wrongLabelsAfter(f, band, realignOut), [])
        // la grafica: dopo il riallineo la vista mostra la battuta e il battito della band nella sezione nuova
        let shown = try XCTUnwrap(f.view.shown.last)
        let k = try XCTUnwrap(f.beats.last).beatInSection
        XCTAssertEqual(shown.bar, k / 3 + 1)
        XCTAssertEqual(shown.beat, k % 3 + 1)
    }

    /// Il passo di LiveView (P10): senza il messaggio del riallineo il primo tick dopo il cambio di sezione
    /// diventerebbe «battuta 1, battito 1». La stessa corsa di prima, guardando il primo tick dopo il riallineo.
    func testWithoutTheViewStepTheBarRestartsFromOne() throws {
        let map = song([(4, 8, 121.0), (3, 8, 91.0), (4, 8, 141.0)])
        let boundary = play + beatTime(map, 32)
        let (f, _, t) = started(map, entryBeat: 4)
        f.run(from: t, to: boundary + 5.0, holes: [(boundary - 1.0, boundary + 0.5)])
        let firstAfter = try XCTUnwrap(f.beats.firstIndex(where: { $0.section == 1 }))
        let k = try item(f.beats, firstAfter).beatInSection
        // la band è già dentro la sezione
        XCTAssertGreaterThan(k, 0)
        let shown = try item(f.view.shown, firstAfter)
        XCTAssertEqual(shown.bar, k / 3 + 1)
        XCTAssertEqual(shown.beat, k % 3 + 1)
    }

    /// R3 (A431 par. 2.3): lo scambio manda al principale la chiusura del runner; il principale è lento; nel
    /// frattempo un riallineo porta il motore due sezioni avanti e precarica la sua successiva. Quando la chiusura
    /// finalmente gira, il suo precarico (vecchio) si scarta.
    func testAStalePreloadAfterARealignIsDiscarded() throws {
        let map = song([(4, 2, 121.0), (4, 2, 121.0), (4, 2, 121.0), (4, 8, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        // il principale esegue la chiusura sei secondi dopo
        f.mainDelay = 6.0
        let b1 = play + beatTime(map, 8)
        // un buco lungo: la band passa in sezione 2
        f.run(from: t, to: b1 + 12.0, holes: [(b1 + 0.2, b1 + 4.3)])
        let r = try singleRealign(f)
        XCTAssertEqual(r.detail.band.section, 2)
        // il precarico vecchio: la sezione 2, col motore già in 2
        XCTAssertEqual(f.discardedPreloads, [RigDiscardedPreload(section: 2, engineSection: 2)])
        // l'ultima scrittura del runner è quella del riallineo
        XCTAssertEqual(f.runnerSection, 2)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        // e al confine dopo il motore ha caricato la sezione giusta
        XCTAssertEqual(f.mapSection, 3)
    }

    /// A431 par. 2.4 d: la W2 dopo un riallineo, in avanti e all'indietro.
    func testTheW2AfterARealignIsCountedAtTheBandBoundary() throws {
        // IN AVANTI: un buco passa il confine 0→1 (nessuna W2 per quel confine); al confine dopo (1→2) la W2 esce
        // una volta, all'ora del confine della band
        do {
            let map = song([(4, 8, 121.0), (3, 8, 91.0), (4, 8, 141.0)])
            let b1 = play + beatTime(map, 32)
            let b2 = play + beatTime(map, 56)
            let (f, _, t) = started(map, entryBeat: 4)
            f.run(from: t, to: b2 + 3.0, holes: [(b1 - 1.0, b1 + 0.5)])
            XCTAssertEqual(f.w2.map { $0.section }, [2])
            let w2 = try XCTUnwrap(f.w2.first)
            XCTAssertEqual(w2.outTime, b2, accuracy: 0.03, "la W2 al confine della band")
        }
        let map = two
        let boundary = play + beatTime(map, 32)
        // ALL'INDIETRO, col primo battito della sezione nuova già uscito: l'iPad è due battiti avanti (qui a mano),
        // passa il confine due battiti prima della band e la sua W2 esce (come oggi); al secondo il riallineo lo
        // riporta nella sezione di prima; al confine della band lo scambio si rifà e la W2 esce un'altra volta: DUE
        // W2 per quel confine, la seconda all'ora del confine della band
        do {
            let (f, band, t) = started(map, entryBeat: 4)
            var tt = f.run(from: t, to: play + beatTime(map, 27) + 0.2, pulses: false)
            f.counter += 2
            tt = try runUntil(f, from: tt) { $0.w2.count == 1 }
            XCTAssertEqual(f.mapSection, 1)
            // la W2 dell'iPad, due battiti prima del confine
            let early = try XCTUnwrap(f.w2.first)
            XCTAssertLessThan(early.outTime, boundary - 0.9)
            f.secondPulse()
            f.call(tt)
            tt += buf
            let r = try singleRealign(f)
            XCTAssertEqual(r.row.reason, "al-secondo")
            XCTAssertEqual(r.detail.jumpBeats, -2)
            XCTAssertEqual(r.row.motor.section, 1)
            XCTAssertEqual(r.detail.band.section, 0)
            XCTAssertEqual(f.mapSection, 0)
            XCTAssertEqual(f.engineTempo, 121.0)
            XCTAssertEqual(f.pendingNext, 1)
            f.run(from: tt, to: boundary + 3.0, pulses: false)
            XCTAssertEqual(f.w2.map { $0.section }, [1, 1])
            let second = try item(f.w2, 1)
            XCTAssertEqual(second.outTime, boundary, accuracy: 0.03, "la seconda W2 al confine della band")
            let realignOut = try lastRealignOut(f)
            XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
            XCTAssertEqual(f.runnerRejoins, [0])
            XCTAssertEqual(f.runnerSection, 1)
        }
        // ALL'INDIETRO, prima che esca il primo battito della sezione nuova: lo scambio è fatto e il tempo è armato,
        // ma la W2 non è ancora uscita; il riallineo ricarica la sezione di prima e toglie il tempo armato: UNA W2
        // sola, al confine della band
        do {
            let (f, band, t) = started(map, entryBeat: 4)
            var tt = f.run(from: t, to: play + beatTime(map, 27) + 0.2, pulses: false)
            f.counter += 2
            tt = try runUntil(f, from: tt) { $0.mapSection == 1 }
            XCTAssertEqual(f.w2, [])
            XCTAssertEqual(f.pendingBpmValue, 91.0)
            f.secondPulse()
            f.call(tt)
            tt += buf
            let r = try singleRealign(f)
            XCTAssertEqual(r.detail.jumpBeats, -2)
            XCTAssertTrue(r.detail.tempoArmed)
            XCTAssertEqual(f.w2, [])
            XCTAssertNil(f.pendingBpmValue)
            f.run(from: tt, to: boundary + 3.0, pulses: false)
            XCTAssertEqual(f.w2.map { $0.section }, [1])
            let w2 = try XCTUnwrap(f.w2.first)
            XCTAssertEqual(w2.outTime, boundary, accuracy: 0.03)
            let realignOut = try lastRealignOut(f)
            XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        }
    }

    /// A424 par. 2.2 d (il tempo armato e il contatore). L'iPad è un battito indietro (qui a mano): fa lo scambio
    /// un battito dopo la band, il tempo della sezione nuova è armato per il battito dopo. Il battito a 1 s cade lì
    /// (a 50 un battito dura 1,2 s): per la band il battito in attesa è il secondo della sezione nuova, per il
    /// motore il primo. Il riallineo carica la sezione coi setter immediati (il tempo vale subito, nel motore e nel
    /// DSP), toglie il tempo armato, mette il contatore: niente W2 per un confine che la band ha già passato.
    func testARealignWithTheTempoArmedLoadsTheSectionAtOnce() throws {
        let map = song([(4, 4, 50.0), (4, 8, 60.0)])
        do {
            let (f, band, t) = started(map, entryBeat: 4)
            var tt = f.run(from: t, to: play + beatTime(map, 13) + 0.3, pulses: false)
            f.counter -= 1
            tt = try runUntil(f, from: tt) { $0.mapSection == 1 }
            XCTAssertEqual(f.counter, 0)
            XCTAssertEqual(f.pendingBpmValue, 60.0)
            XCTAssertEqual(f.engineTempo, 50.0)
            XCTAssertEqual(f.dsp.bpm, 50.0)
            f.secondPulse()
            f.call(tt)
            tt += buf
            let r = try singleRealign(f)
            XCTAssertEqual(r.row.reason, "al-secondo")
            XCTAssertEqual(r.row.motor, RigSpot(section: 1, beat: 0))
            XCTAssertEqual(r.detail.band, RigSpot(section: 1, beat: 1))
            XCTAssertEqual(r.detail.jumpBeats, 1)
            // la sezione caricata, col tempo armato
            XCTAssertTrue(r.detail.loadsSection)
            XCTAssertTrue(r.detail.tempoArmed)
            XCTAssertEqual(f.engineTempo, 60.0)
            XCTAssertEqual(f.seqTempo, 60.0)
            XCTAssertEqual(f.screenBpm, 60.0)
            XCTAssertEqual(f.dsp.bpm, 60.0)
            XCTAssertNil(f.pendingBpmValue)
            XCTAssertNil(f.dsp.armedBpm)
            f.run(from: tt, to: tt + 6.0, pulses: false)
            XCTAssertEqual(f.w2, [])
            let realignOut = try lastRealignOut(f)
            XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
            XCTAssertEqual(wrongLabelsAfter(f, band, realignOut), [])
        }
        // il controllo: col posto UGUALE e il tempo armato il riallineo non tocca niente, e la W2 esce al suo battito
        do {
            let (f, _, t) = started(map, entryBeat: 4)
            var tt = f.run(from: t, to: play + beatTime(map, 13) + 0.3, pulses: false)
            tt = try runUntil(f, from: tt) { $0.mapSection == 1 }
            f.secondPulse()
            f.call(tt)
            tt += buf
            XCTAssertEqual(f.readingRows.count, 1)
            XCTAssertEqual(f.realignRows.count, 0)
            XCTAssertEqual(f.pendingBpmValue, 60.0)
            f.run(from: tt, to: tt + 3.0, pulses: false)
            XCTAssertEqual(f.w2.map { $0.section }, [1])
        }
    }

    /// DA-SOLO (voce j): la band non si sente più, l'iPad va sulla linea propria. Un buco di 1,61 battiti a 121: il
    /// conto legge il solo righello dei secondi dall'àncora (Link non si chiama: il numero della sessione, da soli,
    /// non c'entra con la band), il riallineo rimette i nomi; al confine il tempo cambia senza nessuna W2.
    func testOnItsOwnTheCountReadsTheSecondsRulerAndRealigns() throws {
        let map = two
        let (f, band, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 2.0)
        f.goAlone(t + 2.0)
        let start = t + 9.3 * 60.0 / 121.0
        let hole = 1.61 * 60.0 / 121.0
        let boundary = play + beatTime(map, 32)
        f.run(from: t + 2.0 + buf, to: boundary + 4.0, holes: [(start, start + hole)])
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "buco")
        XCTAssertEqual(r.detail.jumpBeats, 2)
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        XCTAssertEqual(f.w2, [])
        XCTAssertEqual(f.mapSection, 1)
        XCTAssertEqual(f.engineTempo, 91.0)
        XCTAssertEqual(f.sectionEndAgreements, [true])
    }

    // MARK: - La rinumerazione, il non certo

    /// Le due rinumerazioni del 01/11 coi tempi veri (+4,0188 al 7→9 a 180,5; +0,9352 al 9→4 a 121), ognuna 1,08 s
    /// dopo il confine: riconosciute alla lettura al secondo, il conto resta certo, nessun riallineo, nessun
    /// silenzio.
    func testTheRenumberingsOfThe1stOfNovemberAreRecognizedInTheMotor() throws {
        do {
            let map = songA
            let b1 = beatTime(map, 28)
            let b2 = beatTime(map, 64)
            let (f, band, t) = started(map, entryBeat: 7, renumbers: [(b1 + 1.08, 4.0188), (b2 + 1.08, 0.9352)])
            f.run(from: t, to: play + b2 + 6.0)
            assertRecognized(f, [(1, 4.0188), (2, 0.9352)])
            XCTAssertEqual(f.notCertainReasons.count, 0)
            let alive = try XCTUnwrap(f.count)
            XCTAssertNil(alive.closed)
            XCTAssertEqual(wrongNames(f, band), [])
            XCTAssertEqual(f.sectionEndAgreements, [true, true])
            XCTAssertEqual(f.w2.count, 2)
        }
        // la terza del 01/11: 11 → 5 a 160,5, il salto all'indietro (−1,0425), 1,08 s dopo il confine (22 battiti
        // a 140)
        do {
            let map = song([(11, 2, 140.0), (5, 8, 160.5)])
            let b = beatTime(map, 22)
            let (f, band, t) = started(map, entryBeat: 11, renumbers: [(b + 1.08, -1.0425)])
            f.run(from: t, to: play + b + 6.0)
            assertRecognized(f, [(1, -1.0425)])
            XCTAssertEqual(f.notCertainReasons.count, 0)
            let alive = try XCTUnwrap(f.count)
            XCTAssertNil(alive.closed)
            XCTAssertEqual(wrongNames(f, band), [])
            XCTAssertEqual(f.sectionEndAgreements, [true])
        }
    }

    /// A424 par. 3.3 f: il Chorus del 01/11 (9 a 180,5 → 4 a 121). Un buco passa il confine: all'uscita la band è
    /// nel Chorus e il motore è ancora nella sezione in 9. Il riallineo carica il Chorus coi setter immediati (4/4 a
    /// 121, subito, nel motore e nel DSP), nessuna W2 per quel confine; poi il Direttore rinumera (+0,9352, 1,08 s
    /// dopo il confine) e la rinumerazione si riconosce: nessun «non certo», i nomi restano quelli della band.
    func testTheChorusOfThe1stOfNovemberWithTheMotorStillInTheNine() throws {
        let map = songA
        let b2 = beatTime(map, 64)
        let (f, band, t) = started(map, entryBeat: 7,
                                   renumbers: [(beatTime(map, 28) + 1.08, 4.0188), (b2 + 1.08, 0.9352)])
        f.run(from: t, to: play + b2 + 6.0, holes: [(play + b2 - 0.5, play + b2 + 0.3)])
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "buco")
        XCTAssertEqual(r.row.motor.section, 1)
        XCTAssertEqual(r.detail.band.section, 2)
        XCTAssertTrue(r.detail.loadsSection)
        XCTAssertEqual(f.mapSection, 2)
        XCTAssertEqual(f.bpb, 4)
        XCTAssertEqual(f.engineTempo, 121.0)
        XCTAssertEqual(f.dsp.bpm, 121.0)
        XCTAssertEqual(f.dsp.bpb, 4)
        // solo la W2 del confine 7 → 9, uscita al suo posto; nessuna per il Chorus
        XCTAssertEqual(f.w2.map { $0.section }, [1])
        assertRecognized(f, [(1, 4.0188), (2, 0.9352)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        XCTAssertEqual(wrongLabelsAfter(f, band, realignOut), [])
    }

    /// Un salto della sessione a metà sezione (qui +1,0): il conto non è certo, una riga col motivo, niente
    /// riallineo e niente silenzio; il conto resta chiuso e non si legge più.
    func testAJumpOutsideTheStateClosesTheCountAndTheIPadGoesAsToday() throws {
        let map = song([(4, 24, 121.0)])
        let (f, _, t) = started(map, entryBeat: 4, renumbers: [(6.0, 1.0)])
        f.run(from: t, to: t + 9.0)
        let expected: [FollowerBandCountClosed?] = [FollowerBandCountClosed.jumpOutsideRenumbering]
        XCTAssertEqual(f.notCertainReasons, expected)
        XCTAssertEqual(f.realignRows.count, 0)
        let readingsThen = f.readings
        f.run(from: t + 9.0 + buf, to: t + 12.0)
        // chiuso: nessuna lettura in più
        XCTAssertEqual(f.readings, readingsThen)
        XCTAssertTrue(f.running)
        XCTAssertFalse(f.ended)
    }

    /// C3 del collaudo: il cavo mosso subito dopo il cambio di metro. Il buco cade nella finestra «sync skip», il
    /// Direttore rinumera 1,08 s dopo il confine, l'iPad dopo il buco conta in silenzio battiti col nome di prima.
    /// Alla prima lettura dopo la finestra il «contatore d'accordo» guarda l'ultimo battito contato PRIMA del buco:
    /// la rinumerazione si riconosce e il buco si riallinea.
    func testAHoleInsideTheWindowAfterAMeterChangeStillRecognizesTheRenumbering() throws {
        let map = songA
        let b1 = beatTime(map, 28)
        let (f, band, t) = started(map, entryBeat: 7, renumbers: [(b1 + 1.08, 4.0188)])
        f.run(from: t, to: play + b1 + 6.0, holes: [(play + b1 + 0.15, play + b1 + 0.75)])
        assertRecognized(f, [(1, 4.0188)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "buco")
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
    }

    // MARK: - La ripartenza, lo Stop, la fine

    /// Una ripartenza dell'iPad a metà canzone (configurazione, la fine di un'interruzione): l'àncora resta quella,
    /// l'ingresso rimette il seme locale e il riallineo dovuto lo corregge alla prima chiamata. Dentro
    /// l'interruzione non succede niente: nessuna lettura, nessun riallineo.
    func testARestartOfTheIPadInTheSameSongKeepsTheAnchorAndRealigns() throws {
        let map = song([(4, 8, 121.0), (4, 16, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 5.0)
        let anchorBefore = try anchor(f)
        let readingsBefore = f.readings
        f.interruption()
        f.secondPulse()
        f.call(t + 6.0)
        f.secondPulse()
        f.call(t + 7.0)
        XCTAssertEqual(f.readings, readingsBefore)
        XCTAssertNil(f.realignDue)
        // rientra sulla battuta di Link del battito 40 della canzone
        let t2 = play + beatTime(map, 40)
        f.enter(t2, localSeed: 0)
        XCTAssertEqual(f.anchorsAlreadyAlive, 1)
        let anchorAfter = try anchor(f)
        XCTAssertEqual(anchorAfter, anchorBefore)
        f.run(from: t2, to: t2 + 4.0)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "ingresso")
        XCTAssertEqual(r.detail.band, RigSpot(section: 1, beat: 8))
        XCTAssertTrue(r.detail.loadsSection)
        let restartBeats = f.beats.filter { $0.outTime >= t2 }
        XCTAssertEqual(wrongNamesAfter(f, band, t2), [])
        // il primo battito dopo la ripartenza è già rinominato: l'«uno» della battuta
        let firstBeat = try XCTUnwrap(restartBeats.first)
        XCTAssertEqual(firstBeat.label, 0)
    }

    /// Stop e poi un Play nuovo della band: il conto di prima finisce, l'àncora nuova nasce dal Play nuovo.
    func testANewPlayOfTheBandStartsANewCount() throws {
        let map = song([(4, 16, 121.0)])
        let (f, _, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 3.0)
        let first = try anchor(f)
        f.stop()
        XCTAssertNil(f.count)
        XCTAssertNil(f.playTicks)
        let band2 = RigBand(map: map, tPlay: 40.0, link0: 5000.0)
        f.band = band2
        f.playCallback(40.0 + callback)
        f.loadSectionFromRunner(0)
        let t2 = 40.0 + beatTime(map, 4)
        f.enter(t2, localSeed: 0)
        let second = try anchor(f)
        XCTAssertNotEqual(second, first)
        XCTAssertEqual(second.section, 0)
        XCTAssertEqual(second.beatInSection, 4)
        f.beats = []
        f.run(from: t2, to: t2 + 3.0)
        XCTAssertEqual(wrongNames(f, band2), [])
        // e senza uno Stop in mezzo: il motore dell'iPad è fermo per un'interruzione quando la band riparte con un
        // Play nuovo. Il Play accettato azzera il conto di prima PRIMA dell'ingresso: l'àncora è nuova, non quella
        // tenuta
        f.interruption()
        let band3 = RigBand(map: map, tPlay: 80.0, link0: 9000.0)
        f.band = band3
        f.playCallback(80.0 + callback)
        f.loadSectionFromRunner(0)
        f.rows = []
        let t3 = 80.0 + beatTime(map, 4)
        f.enter(t3, localSeed: 0)
        XCTAssertEqual(f.anchorsAlreadyAlive, 0)
        XCTAssertEqual(f.anchorsTaken.count, 1)
        let third = try anchor(f)
        XCTAssertNotEqual(third, second)
    }

    /// La fine: l'iPad ha perso due battiti in un buco nell'ultima sezione e il buco passa la fine della canzone.
    /// Per il conto la band è oltre la fine: la chiusura di fine canzone si consegna subito, non due battiti dopo.
    func testTheIPadEndsTheSongWithTheBand() throws {
        let map = song([(4, 6, 121.0)])
        let end = play + beatTime(map, 24)
        let (f, _, t) = started(map, entryBeat: 4)
        f.run(from: t, to: end + 3.0, holes: [(end - 0.6, end + 0.3)])
        // l'ultimo riallineo è «oltre la fine»
        let lastRealign = try XCTUnwrap(f.realignRows.last)
        XCTAssertNil(lastRealign.inSong)
        XCTAssertTrue(f.ended)
        let done = try XCTUnwrap(f.songEndsDelivered.first)
        XCTAssertEqual(done, end + 0.3, accuracy: 0.05)
        // nessun battito suonato dopo la fine della band
        XCTAssertEqual(f.beats.filter { $0.outTime > end + 0.01 }, [])
    }

    // MARK: - U9 col getter, l'ora del battito a «subito»

    /// U9 (P38): dopo il buco di 1,61 a 121 il DSP ha saltato un battito; una correzione di 0,04 battiti nella
    /// finestra dopo, che passa il battito saltato, non è uno scavalco: nessun battito zittito, nessuna riga falsa.
    func testAfterAFractionalJumpTheLateBeatUsesThePendingBeatOfTheDSP() throws {
        let map = song([(4, 24, 121.0)])
        let (f, _, t) = started(map, entryBeat: 4)
        // il buco comincia con la posizione a 5,302 dopo l'ingresso
        let start = t + 9.302 * 60.0 / 121.0
        f.run(from: t, to: start, pulses: false)
        let hole = 1.61 * 60.0 / 121.0
        f.call(start + hole, hole: true)
        let pos = f.pos
        let pend = f.dsp.pendingBeat
        // il DSP ha saltato un battito: quello in attesa è il successivo
        XCTAssertGreaterThan(pend - pos, 1.0)
        // la posizione arriva appena prima del battito saltato, poi una correzione lo passa
        let skipped = pend - 1.0
        let step = buf * 121.0 / 60.0
        let tt = try callWhile(f, from: start + hole + buf) { $0.pos + step < skipped - 0.01 }
        // 0,08 battiti a 121: 39,7 ms, più di un buffer oltre il battito saltato
        f.line0 -= 0.08
        let before = f.pos
        f.call(tt)
        // la correzione ha passato il battito saltato di più di un buffer
        XCTAssertLessThan(before, skipped)
        XCTAssertLessThan(skipped, f.pos - 0.0215 - buf * 121.0 / 60.0)
        XCTAssertEqual(f.lateBeatCorrections, 0)
        XCTAssertEqual(f.lateMuted, 0)
    }

    /// B.9 (A431 par. 2.8): una correzione in avanti di meno di mezzo battito che scavalca il battito in attesa lo
    /// mette a «subito»: i suoi campioni sono 0 e la sua ora, per la lettura del conto, è l'ora d'uscita del buffer
    /// (il primo campione), non l'ora che il battito avrebbe avuto sulla griglia. Qui la lettura è quella della rete
    /// al secondo, nella stessa chiamata della correzione.
    func testThePendingBeatSetAtOnceIsReadAtTheFirstSample() throws {
        let map = song([(4, 24, 121.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        f.run(from: t, to: t + 1.0, pulses: false)
        // la posizione arriva a meno di 0,05 battiti dal battito in attesa
        let tt = try callWhile(f, from: t + 1.0 + buf) { $0.dsp.pendingBeat - $0.pos > 0.05 }
        let pend = f.dsp.pendingBeat
        // una correzione di +0,2 lo scavalca
        f.line0 -= 0.2
        f.secondPulse()
        let n = f.beats.count
        f.call(tt)
        let reading = try singleReading(f)
        XCTAssertEqual(reading.reason, "al-secondo")
        XCTAssertTrue(reading.certain)
        // lo stesso battito, a 0 campioni: «subito»
        XCTAssertEqual(reading.pendingBeat, pend)
        XCTAssertEqual(reading.samplesAhead, 0)
        XCTAssertEqual(f.realignRows.count, 0)
        let b = try item(f.beats, n)
        // esce al primo campione del buffer
        XCTAssertEqual(b.outTime, tt + RigNumbers.outDelay, accuracy: 1e-6)
        // col nome della band per QUELL'ora
        XCTAssertEqual(bandSongBeat(band, b.outTime), f.songBeat(section: b.section, beat: b.beatInSection))
        // in ritardo di più di un buffer: contato e non suonato (U9)
        XCTAssertTrue(b.muted)
        XCTAssertEqual(f.lateMuted, 1)
    }
}
