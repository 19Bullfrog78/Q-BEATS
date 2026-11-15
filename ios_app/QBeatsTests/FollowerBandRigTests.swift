import XCTest

// === A432, parte 2b — banco dei fili del conto del Follower sulla band (`FollowerBandRig`, banco Models) ===
// Il rig rifà il motore dell'iPad Follower per quello che i fili del conto toccano, e nient'altro: il DSP (la linea
// a campioni, il battito in attesa con la sua identità, l'etichetta, i cambi armati), la correzione di fase, il
// giro dei battiti con lo scambio di sezione e il tempo armato, il runner, il passo della vista. Le regole pure
// sono quelle vere del deposito: `FollowerBandCount`, `ShowClock`, `SectionPreloadDecision`, `SectionRealign`,
// `LateBeatDecision`.
// A432, parte 2c (13/11/2026) — in più della 2b il rig rifà: il battito di controllo «sulla griglia» e l'àncora come
// controllo (`followerControlBeatQ`, col numero d'avvio del motore), il drenaggio come lo scrive il motore (la coda
// del click, il sequencer che avanza, il DSP fermo) e la cura del drenaggio riaperto, la rinumerazione vista solo
// dalla cattura fatta dopo di lei (P6), il sequencer ri-ancorato all'inizio del buffer del cambio di tempo.
// A432, parte 2d (14/11/2026) — in più della 2c il rig rifà (DECISIONI_REFEREE_A432_PARTE2D_ARRESTO, _ARRESTO-2 e
// VERIFICA_REFEREE_A432_PARTE2C): E1, il Play accettato che abbassa il segno della mappa; D1, l'àncora al fuoco anche
// con «canzone in corso» alta; D2, l'ordine vero dei blocchi su audioQueue (Play, primo avvio, mappa, guardia del
// secondo avvio, fuoco), col segno della mappa e «canzone in corso» mossi dalle funzioni vere di
// `SongInProgressDecision`; K1, il numero dell'avvio tenuto coi numeri del fuoco; K4, la consegna di una mappa
// diversa; K7 e D5, il richiamo del tempo di Link e il limite di sicurezza della cura del drenaggio riaperto.
// I 60 casi (i 25 della parte 2b, i 19 della parte 2c e i 16 della parte 2d), con gli stessi nomi e gli stessi
// numeri, girano sul modello Python del motore (fuori dal deposito), dove 50 rotture volute tolgono una regola alla
// volta e ogni test cade con almeno una. Qui i casi girano sul ramo sano. Le eccezioni: `withoutPointR`, il «gemello»
// di due casi (l'iPad com'era prima di questo lavoro), e gli interruttori di rottura della parte 2d (proprietà del
// rig, falsi di base: nessuno stato globale), per le scene che devono restare verdi con una regola tolta.
// Le condizioni del rig sono scritte come le scrive il motore (`AudioEngine`, blocco «A432 · il conto del Follower
// sulla band»), e ogni funzione porta il nome di quella che rispecchia: `followerBandEntryAtFireQ`,
// `takeFollowerBandAnchorQ`, `consumeSongMapForRunningStartQ`, `noteFollowerRealignDueQ`, `followerSecondQ`,
// `resetFollowerBandCountQ`, il punto R di `scheduleNextBuffer` e `followerBandCountPointRQ`,
// `followerControlBeatQ`, `readFollowerBandCountQ`, `loadFollowerSectionForRealignQ`, `followerRealignQ`,
// `logFollowerSectionEndCheckQ`, `preloadNextSection`, `noteLateBeatCorrectionQ`, `ownClockPinQ`; dalla parte 2d
// anche `prepareNormalStartQ`, `lowerSongMapForNextStartQ`, `setSongMap` e il richiamo del tempo di Link.
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
    /// I campioni del click (`generateClickSamples`: 40 ms): 1920 a 48 kHz. La coda del click: i playhead.
    static let click = Int(rate * 0.040)

    static func ticks(_ seconds: Double) -> UInt64 {
        UInt64((seconds * tps).rounded())
    }

    /// Tre decimali, come i passi fra i battiti in un caso del modello.
    static func round3(_ value: Double) -> Double {
        (value * 1_000.0).rounded() / 1_000.0
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

    /// Il battito della sessione di Link per l'ora `t`, come lo dice una cattura fatta all'ora `now` (P6): una
    /// rinumerazione la vede solo una cattura fatta dopo di lei, anche se l'ora chiesta è nel futuro. Senza `now` la
    /// cattura è fatta all'ora chiesta.
    func linkBeat(_ t: Double, now: Double? = nil) -> Double {
        let seen = now ?? t
        var jumps = 0.0
        for renumber in renumbers where seen >= renumber.at {
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

/// Un drenaggio riaperto da un riallineo: le chiamate del drenaggio in cui il DSP è rimasto fermo prima, e l'ora
/// della chiamata (arrotondata a quattro decimali).
private struct RigReopened: Equatable {
    let drainSkipped: Int
    let callTime: Double
}

/// Un cambio di tempo armato arrivato al suo battito: il tempo di prima, il tempo nuovo e lo scostamento dell'«uno»
/// nel suo buffer, in campioni.
private struct RigTempoChange: Equatable {
    let was: Double
    let now: Double
    let offset: Int
}

/// Il richiamo del tempo di Link in sync: il tempo del richiamo, il tempo che il motore aveva, e se sono diversi
/// (`adottato`).
private struct RigTempoCallback: Equatable {
    let bpm: Double
    let engineTempo: Double
    let adopted: Bool
}

/// Una cura del drenaggio riaperto fatta: di quanto il sequencer stava avanti al DSP e la soglia in avanti, in
/// battiti (a sei decimali, come nel modello).
private struct RigReopenCured: Equatable {
    let aheadOfDSP: Double
    let aheadLimitBeats: Double
}

/// Una cura del drenaggio riaperto saltata dal limite di sicurezza: la posizione del sequencer, la posizione del DSP
/// e le due soglie (indietro e avanti), in battiti (a quattro decimali, come nel modello). Senza un tempo valido la
/// posizione del DSP e le soglie non sono numeri.
private struct RigReopenSkipped: Equatable {
    let sequencerBeat: Double
    let dspBeat: Double
    let behindLimitBeats: Double
    let aheadLimitBeats: Double
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
    case countReset(reason: String)
    case tempoCallback(RigTempoCallback)
    case sessionTempoIgnored(bpm: Double)
    case reopenedDrainSkipped(RigReopenSkipped)
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
    /// La mappa della canzone del motore (`_songMapQ`): la consegna il runner (`setSongMap`), e può essere un'altra.
    private(set) var map: SongMap
    var band: RigBand
    private(set) var dsp: RigFollowerDSP
    private(set) var running = false
    /// Falso = DA-SOLO (la linea propria).
    private var inSync = true
    /// La linea dell'iPad: posizione = battito della sessione meno `line0`.
    var line0 = 0.0
    /// La posizione del sequencer, in battiti (`midi_engine_get_beat_position`). Un caso della parte 2d la sposta a
    /// mano.
    var pos = 0.0
    /// `_ownTimelineQ`: `nil` = la linea propria è da ri-ancorare.
    private(set) var ownTimeline: RigOwnTimeline? = nil
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
    private(set) var sectionEndPending = false
    /// La chiusura di fine canzone consegnata.
    private(set) var ended = false
    private(set) var engineTempo: Double
    private(set) var seqTempo: Double
    private(set) var screenBpm: Double
    /// `_followerBandCountQ`
    private(set) var count: FollowerBandCount? = nil
    /// `_followerPlayCallbackTicksQ`
    private(set) var playTicks: UInt64? = nil
    /// `_followerEntryPendingQ`: i numeri del fuoco tenuti, col numero dell'avvio del motore in cui il fuoco è passato
    /// (K1).
    private(set) var entryPending: (ticks: UInt64, linkBeat: Double, startSerial: Int)? = nil
    /// `_songMapForNextStartQ`: il segno della mappa per il prossimo avvio.
    private(set) var mapForNextStart = false
    /// `_songInProgressQ`: «canzone in corso».
    private(set) var songInProgress = false
    /// `_followerRealignDueQ`
    private(set) var realignDue: String? = nil
    /// `_lastCountedBeatQ`
    private var lastCounted: FollowerCountedBeat? = nil
    /// `_followerGridBeatQ`: l'ultimo battito contato uscito sulla griglia (il battito di controllo).
    private(set) var gridBeat: FollowerCountedBeat? = nil
    /// `_engineStartSerialQ`: gli avvii del motore.
    private(set) var startSerial = 0
    /// `_followerAnchorStartSerialQ`: l'avvio in cui è nata l'àncora.
    private(set) var anchorStart: Int? = nil
    /// I campioni del click ancora da scrivere (la coda: `clickPlayhead`, `accentPlayhead`, `subdivPlayhead`).
    private var clickLeft = 0
    /// Le chiamate del drenaggio in cui il DSP non ha girato.
    private(set) var drainSkipped = 0
    /// Le stesse, contate dall'ultima scrittura della posizione del DSP fatta dalla correzione di fase.
    private(set) var frozenCalls = 0
    /// I drenaggi riaperti da un riallineo.
    private(set) var reopened: [RigReopened] = []
    /// K7: le cure del drenaggio riaperto saltate dal limite di sicurezza.
    private(set) var reopenSkipped: [RigReopenSkipped] = []
    /// K7: le cure del drenaggio riaperto fatte.
    private(set) var reopenCured: [RigReopenCured] = []
    /// I cambi di tempo armati arrivati al loro battito.
    private(set) var tempoChangeOffsets: [RigTempoChange] = []
    /// Per i casi, che cosa ha visto l'ultima lettura al punto R: l'ora del battito in attesa, le chiamate del
    /// drenaggio col DSP fermo (0 fuori dal drenaggio), la finestra «sync skip» rimasta, il posto della band, e da
    /// dove veniva il battito di controllo («griglia», «ancora», «nessuno»: `source` di `followerControlBeatQ`).
    private(set) var pendingTimeAtRead: Double? = nil
    private(set) var drainSkippedAtRead: Int? = nil
    private(set) var syncSkipAtRead: Int? = nil
    private(set) var placeAtRead: FollowerBandPlace? = nil
    private(set) var controlAtRead: String? = nil
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
    // Gli interruttori di rottura della parte 2d: ognuno toglie una regola, e di base sono falsi. Sono proprietà del
    // rig (nessuno stato globale): un caso che deve restare verde con una regola tolta fa un rig con l'interruttore
    // acceso (nel modello Python: `with rotte(...)`).
    /// E1 tolta: il Play accettato non abbassa il segno della mappa.
    var playDoesNotLowerTheMapMark = false
    /// D1 tolta, la regola (i) spenta: al fuoco «canzone in corso» alta non basta per prendere l'àncora.
    var entryRuleOff = false
    /// D1 al rovescio: al fuoco l'àncora si prende sempre.
    var fireAlwaysTrue = false
    /// D2, una difesa tolta: l'avvio che prosegue non riscrive «canzone in corso» (`normalStart`).
    var startDoesNotRewriteSongInProgress = false
    /// D2, l'altra difesa tolta: lo Stop non abbassa «canzone in corso» (`stopped`).
    var stopDoesNotLowerSongInProgress = false
    /// K1 tolta: l'àncora nata dai numeri del fuoco tenuti prende il numero dell'avvio in corso.
    var anchorTakesTheRunningStart = false
    /// K4 tolta: una mappa diversa lascia il battito di controllo e l'avvio dell'àncora.
    var newMapKeepsTheControlBeat = false
    /// K4 tolta: il conto azzerato lascia il battito di controllo e l'avvio dell'àncora.
    var resetKeepsTheControlBeat = false
    /// K7 tolta: la cura del drenaggio riaperto senza il limite di sicurezza.
    var reopenedDrainWithoutLimit = false
    /// D5 tolta: la soglia della cura in valore assoluto, non a un lato.
    var reopenedDrainAbsoluteThreshold = false

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

    /// Il segno della mappa e «canzone in corso» insieme, come li prendono le mosse di `SongInProgressDecision`.
    var mark: SongMapMark {
        SongMapMark(mapForNextStart: mapForNextStart, songInProgress: songInProgress)
    }

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

    /// Le righe «conto azzerato», coi loro motivi (solo la consegna di una mappa diversa ne scrive una).
    var countResets: [String] {
        var out: [String] = []
        for row in rows {
            if case .countReset(let reason) = row { out.append(reason) }
        }
        return out
    }

    var tempoCallbacks: [RigTempoCallback] {
        var out: [RigTempoCallback] = []
        for row in rows {
            if case .tempoCallback(let callback) = row { out.append(callback) }
        }
        return out
    }

    var reopenedDrainSkippedRows: [RigReopenSkipped] {
        var out: [RigReopenSkipped] = []
        for row in rows {
            if case .reopenedDrainSkipped(let skipped) = row { out.append(skipped) }
        }
        return out
    }

    // MARK: Il runner (sul principale)

    /// L'avvio di una sezione dal runner (`SetlistRunner.prepareAndStartCurrentSection`): la consegna della mappa
    /// (`setSongMap`: il segno si alza; `map` = una canzone diversa), i setter della sezione (`loadSection`) e il
    /// precarico della sezione dopo.
    func loadSectionFromRunner(_ idx: Int, map delivered: SongMap? = nil) {
        setSongMap(delivered ?? map, startSection: idx)
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
        preload(forSection: idx + 1)
    }

    /// `setSongMap` su audioQueue — K4 (2d), la consegna della mappa: un conto vivo su un'altra mappa non vale più;
    /// con lui i numeri del fuoco, il riallineo dovuto, il battito di controllo e l'avvio dell'àncora. L'ora del Play
    /// resta. Il segno della mappa si alza: il motore scrive il campo direttamente (`_songMapForNextStartQ = true`),
    /// il rig passa da `SongInProgressDecision.mapDelivered`, con lo stesso effetto.
    private func setSongMap(_ delivered: SongMap, startSection: Int) {
        if let alive = count, alive.map != delivered {
            count = nil
            entryPending = nil
            realignDue = nil
            if !newMapKeepsTheControlBeat {
                gridBeat = nil
                anchorStart = nil
            }
            rows.append(.countReset(reason: "mappa-nuova"))
        }
        map = delivered
        mapSection = startSection
        let delivery = SongInProgressDecision.mapDelivered(mark)
        mapForNextStart = delivery.mapForNextStart
        songInProgress = delivery.songInProgress
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

    /// `resetFollowerBandCountQ`: col conto finiscono il battito di controllo e l'avvio dell'àncora.
    private func resetCount() {
        count = nil
        playTicks = nil
        entryPending = nil
        realignDue = nil
        if !resetKeepsTheControlBeat {
            gridBeat = nil
            anchorStart = nil
        }
    }

    /// Il richiamo del Play del Direttore accettato (`followerHandleLinkTransport`, ramo `.start`): il conto di prima
    /// finisce (`resetFollowerBandCountQ`, «play-direttore») e si prende l'ora del Play
    /// (`_followerPlayCallbackTicksQ`). E1 (2d): il segno della mappa rimasto da una consegna di prima si abbassa
    /// (`lowerSongMapForNextStartQ`, «play-direttore»): una mappa consegnata prima del Play non è la mappa di quel
    /// Play. Prima del primo avvio e della mappa nuova.
    func playCallback(_ t: Double) {
        resetCount()
        playTicks = RigNumbers.ticks(t)
        if !playDoesNotLowerTheMapMark {
            lowerSongMapForNextStart()
        }
    }

    /// `lowerSongMapForNextStartQ`: il segno della mappa si abbassa senza consumarlo in «canzone in corso». Nel motore
    /// è una scrittura diretta del segno (nessuna mossa di `SongInProgressDecision`), e qui è la stessa.
    private func lowerSongMapForNextStart() {
        guard mapForNextStart else { return }
        mapForNextStart = false
    }

    /// Lo Stop (`cleanupAfterStopQ`): il conto finisce (`resetFollowerBandCountQ`, «stop»). Ogni `stopSync` chiude
    /// «canzone in corso»: il motore scrive il campo direttamente (`_songInProgressQ = false`), il rig passa da
    /// `SongInProgressDecision.stopped`, con lo stesso effetto; il segno della mappa com'è.
    func stop() {
        running = false
        if !stopDoesNotLowerSongInProgress {
            let halted = SongInProgressDecision.stopped(mark)
            mapForNextStart = halted.mapForNextStart
            songInProgress = halted.songInProgress
        }
        resetCount()
        tick = 0
        counter = 0
        pendingBpmValue = nil
        pendingNext = nil
        sectionEndPending = false
        clickLeft = 0
    }

    /// Un'interruzione di sistema o una ripartenza dell'iPad: il motore si ferma senza la pulizia dello Stop.
    func interruption() {
        running = false
    }

    /// Il blocco di un `start()` che prosegue (su audioQueue): `prepareNormalStartQ` fa di «canzone in corso» il segno
    /// di quel momento e abbassa il segno (`SongInProgressDecision.normalStart`); il numero dell'avvio sale
    /// (`_engineStartSerialQ`), i battiti contati ripartono, il battito di controllo si azzera, salvo quando un
    /// riallineo dovuto «buco» aspetta ancora la sua lettura. Non tocca i numeri del fuoco tenuti. È anche la
    /// «ripartenza senza fuoco» di K1.
    func engineStart() {
        let start = SongInProgressDecision.normalStart(mark)
        if !startDoesNotRewriteSongInProgress {
            songInProgress = start.songInProgress
        }
        mapForNextStart = start.mapForNextStart
        running = true
        tick = 0
        lastCounted = nil
        startSerial += 1
        if realignDue != "buco" {
            gridBeat = nil
        }
    }

    /// `consumeSongMapForRunningStartQ`: col segno alto «canzone in corso» si alza e il segno si abbassa
    /// (`SongInProgressDecision.runningStart`); col segno basso niente, e i numeri del fuoco tenuti NON si guardano.
    /// Se il consumo c'è e il fuoco ha tenuto i suoi numeri, l'àncora si prende qui (i buffer sono già partiti), col
    /// numero dell'avvio del fuoco (K1).
    private func consumeMapForRunningStart() {
        let step = SongInProgressDecision.runningStart(mark)
        guard step.consumed else { return }
        mapForNextStart = step.mark.mapForNextStart
        songInProgress = step.mark.songInProgress
        if let pending = entryPending {
            entryPending = nil
            takeAnchor(entryTicks: pending.ticks, entryLinkBeat: pending.linkBeat, atFire: false,
                       bornInStart: pending.startSerial)
        }
    }

    /// Il secondo `start()` del runner, che trova il motore in moto ed esce alla guardia «avvio-gia-in-moto»: lì la
    /// mappa consegnata a un avvio in corso si consuma (A425, P4).
    func secondStartGuard() {
        if running {
            consumeMapForRunningStart()
        }
    }

    /// Il fuoco dell'ingresso (il lavoro di `armSharedJoin`): il DSP riparte dall'«uno», il seme locale, l'àncora
    /// del conto (`followerBandEntryAtFireQ`), tre buffer senza correzione. `engineStarted`: il blocco del primo
    /// avvio è già passato (l'ordine vero: `engineStart`, poi mappa e guardia, poi il fuoco); senza, l'avvio e il
    /// fuoco di seguito (una ripartenza).
    func enter(_ tFire: Double, localSeed: Int = 0, engineStarted: Bool = false) {
        if !engineStarted {
            engineStart()
        }
        running = true
        tick = 0
        clickLeft = 0
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
        // `followerBandEntryAtFireQ` — D1 (2d), la regola (i): l'àncora al fuoco col conto vivo, col segno della mappa
        // alto, o con «canzone in corso» alta (la mappa di questo avvio è arrivata ed è già stata consumata dalla
        // guardia del secondo avvio).
        entryPending = nil
        let link = band.linkBeat(anchorAt)
        if fireAlwaysTrue || count != nil || mapForNextStart || (songInProgress && !entryRuleOff) {
            takeAnchor(entryTicks: RigNumbers.ticks(anchorAt), entryLinkBeat: link, atFire: true)
        } else {
            // K1 (2d): coi numeri del fuoco si tiene il numero dell'avvio in cui il fuoco è passato.
            entryPending = (ticks: RigNumbers.ticks(anchorAt), linkBeat: link, startSerial: startSerial)
        }
        // Il fuoco consuma la mappa se il segno è ancora alto (`consumeSongMapForRunningStartQ` dopo l'àncora).
        consumeMapForRunningStart()
        syncSkip = 3
    }

    /// `takeFollowerBandAnchorQ`: l'ingresso nel conto (`FollowerBandCount.enter`). K1 (2d) — `bornInStart`: il numero
    /// dell'avvio in cui sono nati i numeri d'ingresso, quando non è l'avvio in corso (i numeri del fuoco tenuti);
    /// `nil` per tutti gli altri ingressi (l'àncora è dell'avvio in corso).
    private func takeAnchor(entryTicks: UInt64, entryLinkBeat: Double, atFire: Bool, bornInStart: Int? = nil) {
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
            // L'àncora nasce in questo avvio del motore (`_followerAnchorStartSerialQ`), salvo quando nasce dai numeri
            // del fuoco tenuti (K1): allora è dell'avvio del fuoco (`bornInStart`), non di quello in corso.
            if anchorTakesTheRunningStart {
                anchorStart = startSerial
            } else {
                anchorStart = bornInStart ?? startSerial
            }
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

    /// `noteFollowerRealignDueQ`: il buco vince sugli altri motivi. Dal momento in cui il buco è dovuto fino alla sua
    /// lettura i battiti contati non aggiornano il battito di controllo (`gridBeat`), che resta quello di prima del
    /// buco.
    private func noteRealignDue(reason: String) {
        guard running, let alive = count, alive.closed == nil else { return }
        if reason == "buco" {
            realignDue = reason
        } else if realignDue == nil {
            realignDue = reason
        }
    }

    /// K7 (2d) — il richiamo del tempo di Link sul Follower (il blocco di `link_engine_set_tempo_callback`). DA-SOLO
    /// il tempo della sessione si ignora. In sync: `adottato` = il tempo è diverso da quello del motore; il motore,
    /// il DSP (`metronome_setBPM`: la distanza al battito in attesa riscalata) e il sequencer prendono il tempo, e il
    /// sequencer NON si ri-àncora (`midi_engine_set_bpm` da solo): la sua posizione ASSOLUTA (il battito della
    /// sessione: la posizione più `line0`) si moltiplica per tempo nuovo / tempo di prima.
    func tempoCallback(_ bpm: Double) {
        guard inSync else {
            rows.append(.sessionTempoIgnored(bpm: bpm))
            return
        }
        rows.append(.tempoCallback(RigTempoCallback(bpm: bpm, engineTempo: engineTempo, adopted: bpm != engineTempo)))
        engineTempo = bpm
        dsp.setBPM(bpm)
        if bpm != seqTempo {
            let absolute = pos + line0
            pos = absolute * bpm / seqTempo - line0
            seqTempo = bpm
        }
        screenBpm = bpm
    }

    /// Il battito a 1 s del Follower (`followerSecondQ`): la rete del conto.
    func secondPulse() {
        noteRealignDue(reason: "al-secondo")
    }

    // MARK: scheduleNextBuffer

    /// Dove la correzione porta la posizione per l'ora d'uscita `tOut`: IN SYNC la linea di Link
    /// (`link_engine_sync_phase`: una cattura fatta adesso, P6), DA-SOLO la linea propria (`ownClockPinQ`).
    private func positionTarget(_ tOut: Double) -> Double {
        guard !inSync, let own = ownTimeline else {
            return band.linkBeat(tOut, now: now) - line0
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
        // «L1.a — Drain mode check» di `scheduleNextBuffer`: la chiusura si consegna quando la coda del click è
        // esaurita (nel motore i tre playhead sotto zero). Fino ad allora le chiamate del drenaggio vanno avanti (il
        // misuratore, la correzione, il punto R) senza far girare il DSP.
        if sectionEndPending && clickLeft <= 0 {
            // La chiusura di fine canzone si consegna e questo richiamo non programma niente.
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
                    frozenCalls = 0
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
        runMain(t)
        // «L1.a — Drain mode: skip metronome_processBuffer» di `scheduleNextBuffer`: nel drenaggio il DSP non gira
        // (nessun evento), e il battito in attesa resta dov'è.
        let events: [RigDSPEvent]
        if sectionEndPending {
            events = []
            drainSkipped += 1
            frozenCalls += 1
        } else {
            events = dsp.process(frames: RigNumbers.frames)
        }
        // Il sequencer avanza di un buffer a ogni chiamata, anche nel drenaggio (`bufferCount` sale sempre).
        pos += RigNumbers.buf * seqTempo / 60.0
        // La coda del click scritta in questo buffer.
        if clickLeft > 0 {
            clickLeft = max(clickLeft - RigNumbers.frames, 0)
        }
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
            // Il battito di controllo «sulla griglia», come in `scheduleNextBuffer` sotto la scrittura di
            // `_lastCountedBeatQ`: lo stesso battito, solo col conto vivo, e non se un riallineo dovuto «buco»
            // aspetta ancora la sua lettura o se è il battito messo a «subito» che U9 conta e non suona
            // (`muteThisEvent`).
            if count != nil, realignDue != "buco", !muted {
                gridBeat = lastCounted
            }
            // Un battito suonato arma la coda del click: i suoi campioni oltre la fine di questo buffer.
            if !muted {
                clickLeft = max(RigNumbers.click - (RigNumbers.frames - event.offset), 0)
            }
            beats.append(RigBeat(outTime: RigNumbers.round6(beatOut), section: mapSection, beatInSection: counter,
                                 label: event.label, accent: event.accent, muted: muted))
            view.tick(tick, startOffset: startOffset, bpb: bpb)
            if let pending = pendingBpmValue, tick == pendingBpmTargetTick {
                // Il tempo armato allo scambio: il primo battito della sezione nuova, e la W2 (solo IN SYNC).
                // «Propagazione BPM al downbeat target»: il sequencer prende il tempo nuovo ri-ancorato alla
                // posizione dell'inizio di QUESTO buffer (`midi_engine_set_bpm` e `midi_engine_set_beat_position`
                // con la posizione di prima del cambio): il buffer intero conta al tempo nuovo.
                tempoChangeOffsets.append(RigTempoChange(was: seqTempo, now: pending, offset: event.offset))
                pos += RigNumbers.buf * (pending - seqTempo) / 60.0
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
                        drainSkipped = 0
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

    /// `readFollowerBandCountQ`: IN SYNC il battito della sessione all'ora `ticks`, da una cattura fatta adesso (P6);
    /// DA-SOLO Link non si chiama, e il battito è quello che il righello dei secondi dà dall'àncora. `nil` se il conto
    /// non ha l'àncora.
    private func readCount(_ count: inout FollowerBandCount, ticks: UInt64,
                           lastCounted: FollowerCountedBeat?) -> FollowerBandReading? {
        let tps = RigNumbers.tps
        let linkBeat: Double
        if inSync {
            linkBeat = band.linkBeat(Double(ticks) / tps, now: now)
        } else {
            guard let anchor = count.anchor else { return nil }
            let ruler = ShowClock(map: count.map, anchor: anchor).bySeconds(nowTicks: ticks, ticksPerSecond: tps)
            linkBeat = anchor.linkBeat + ruler.beatsFromAnchor
        }
        return count.read(pendingLinkBeat: linkBeat, pendingTicks: ticks, ticksPerSecond: tps,
                          lastCounted: lastCounted)
    }

    /// `followerControlBeatQ` — il battito che va al contatore d'accordo, per ogni lettura e per ogni motivo: l'ultimo
    /// battito contato sulla griglia; se non ce n'è nessuno, l'àncora stessa (sezione, battito nella sezione e ora
    /// dell'àncora), solo se è nata nell'avvio del motore in cui si fa la lettura; altrimenti nessun battito.
    private func controlBeat() -> FollowerCountedBeat? {
        if let grid = gridBeat {
            return grid
        }
        guard let anchor = count?.anchor, let born = anchorStart, born == startSerial else {
            return nil
        }
        return FollowerCountedBeat(section: anchor.section, beatInSection: anchor.beatInSection, ticks: anchor.ticks)
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
        let pendingTime = out + Double(aheadSamples) / RigNumbers.rate
        let pendingTicks = RigNumbers.ticks(pendingTime)
        // Per i casi: che cosa ha visto questa lettura.
        pendingTimeAtRead = pendingTime
        drainSkippedAtRead = sectionEndPending ? drainSkipped : 0
        syncSkipAtRead = syncSkip
        let stateBefore = alive.renumbering
        // Al contatore d'accordo va il battito di controllo (`followerControlBeatQ`), mai `lastCounted` com'è.
        let control = controlBeat()
        // Per i casi: da dove viene il battito di controllo.
        if control == nil {
            controlAtRead = "nessuno"
        } else if let grid = gridBeat, control == grid {
            controlAtRead = "griglia"
        } else {
            controlAtRead = "ancora"
        }
        // Il motivo si consuma qui: da qui i battiti contati tornano ad aggiornare il battito di controllo.
        realignDue = nil
        guard let reading = readCount(&alive, ticks: pendingTicks, lastCounted: control) else { return }
        count = alive
        readings += 1
        placeAtRead = reading.place
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
    /// vista sul principale; oltre la fine della canzone la chiusura si consegna adesso. Mai un click spostato, a
    /// meno del riallineo che riapre la sezione col motore in drenaggio (parte 2c): lì il DSP, rimasto fermo, si
    /// porta alla posizione del sequencer, come fa ogni correzione di fase.
    private func realign(place: FollowerBandPlace, reason: String) {
        let motorSection = mapSection
        let motorBeat = counter
        let wasDraining = sectionEndPending
        let tempoArmed = pendingBpmValue != nil
        // K7 (2d) — il tempo del motore, che è il tempo del DSP, in questo istante: PRIMA del caricamento della
        // sezione. È il tempo a cui il battito in attesa è stato letto, e il tempo delle chiamate ferme del drenaggio.
        let tempoAtReading = engineTempo
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
            drainSkipped = 0
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
            if wasDraining {
                // «IL DRENAGGIO RIAPERTO» di `followerRealignQ`: il riallineo ha riaperto la sezione col motore in
                // drenaggio. Il DSP è rimasto fermo mentre il sequencer avanzava: la sua posizione si porta dove
                // sarebbe senza drenaggio, cioè alla posizione del sequencer (`midi_engine_get_beat_position`), con
                // le due chiamate della correzione di fase e solo quelle: il setter della posizione
                // (`metronome_set_beat_position_time_only`) e U9 (`noteLateBeatCorrectionQ`, prima e dopo uguali).
                // Prima del contatore e della rinomina, che resta l'ultima.
                reopened.append(RigReopened(drainSkipped: drainSkipped, callTime: RigNumbers.round4(now)))
                let sequencerBeat = pos
                // «IL LIMITE DI SICUREZZA» di `followerRealignQ` (K7 e D5, 2d), prima delle due chiamate: la posizione
                // del DSP quando il battito in attesa è stato letto (il battito in attesa meno i suoi campioni
                // d'anticipo, in battiti al tempo di allora, `tempoAtReading`: il getter non si rilegge, il
                // caricamento qui sopra ha già riscritto il tempo del DSP) e di quanto il sequencer le sta avanti,
                // col segno. Un drenaggio porta il sequencer solo AVANTI al DSP. LA SOGLIA, A UN LATO: avanti di non
                // più di (tre chiamate ferme più una) buffer più il margine, indietro di non più del margine; il
                // margine è 1,575 buffer alla frequenza vera (R3 della 2d-bis: 16,8 ms a 48 kHz, la sola frequenza
                // di questo rig); tutto in battiti a `tempoAtReading`. Fuori dalla soglia la cura non fa niente
                // (nessun setter, nessun U9) e lo dice con una riga («drenaggio riaperto saltato»).
                let aheadSamples = pendingBefore.samplesAhead > 0 ? pendingBefore.samplesAhead : 0
                var cureWithinLimit = false
                var dspBeat = Double.nan
                var aheadOfDSP = Double.nan
                var behindLimitBeats = Double.nan
                var aheadLimitBeats = Double.nan
                if tempoAtReading.isFinite, tempoAtReading > 0, RigNumbers.rate > 0 {
                    let beatsPerSecond = tempoAtReading / 60.0
                    let frozenCallsAtMost = 3.0
                    let epsilonMarginBuffers = 1.575
                    let epsilonMarginSeconds = epsilonMarginBuffers * (Double(RigNumbers.frames) / RigNumbers.rate)
                    dspBeat = pendingBefore.beat - Double(aheadSamples) / RigNumbers.rate * beatsPerSecond
                    aheadOfDSP = sequencerBeat - dspBeat
                    behindLimitBeats = epsilonMarginSeconds * beatsPerSecond
                    let bufferBeats = Double(RigNumbers.frames) / RigNumbers.rate * beatsPerSecond
                    aheadLimitBeats = (frozenCallsAtMost + 1.0) * bufferBeats + behindLimitBeats
                    if reopenedDrainAbsoluteThreshold {
                        cureWithinLimit = abs(aheadOfDSP) <= aheadLimitBeats
                    } else {
                        cureWithinLimit = aheadOfDSP >= -behindLimitBeats && aheadOfDSP <= aheadLimitBeats
                    }
                }
                if cureWithinLimit || reopenedDrainWithoutLimit {
                    if !aheadOfDSP.isNaN {
                        reopenCured.append(RigReopenCured(aheadOfDSP: RigNumbers.round6(aheadOfDSP),
                                                          aheadLimitBeats: RigNumbers.round6(aheadLimitBeats)))
                    }
                    dsp.setBeatPositionTimeOnly(sequencerBeat)
                    noteLateBeatCorrection(before: sequencerBeat, after: sequencerBeat)
                } else {
                    let skipped = RigReopenSkipped(sequencerBeat: RigNumbers.round4(sequencerBeat),
                                                   dspBeat: RigNumbers.round4(dspBeat),
                                                   behindLimitBeats: RigNumbers.round4(behindLimitBeats),
                                                   aheadLimitBeats: RigNumbers.round4(aheadLimitBeats))
                    reopenSkipped.append(skipped)
                    rows.append(.reopenedDrainSkipped(skipped))
                }
            }
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

    /// `logFollowerSectionEndCheckQ`: la riga di controllo a fine sezione, letta su una COPIA del conto, con lo stesso
    /// battito di controllo del punto R (`followerControlBeatQ`).
    private func sectionEndCheck(section: Int, beatInSection: Int, outTicks: UInt64) {
        guard let alive = count, alive.closed == nil else { return }
        var probe = alive
        guard let reading = readCount(&probe, ticks: outTicks, lastCounted: controlBeat()) else { return }
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

    /// L'ordine dei blocchi di un ingresso su audioQueue, dopo il Play (`entryBlocks`).
    private enum EntryOrder {
        /// L'ordine VERO (i registri A425-A429: 50 ingressi su 50): il primo avvio, la mappa, la guardia del secondo
        /// avvio, il fuoco.
        case real
        /// La gara: il primo avvio e il fuoco, PRIMA della mappa (la mappa e la guardia le fa il test, dopo): mai
        /// vista sugli apparecchi.
        case race
        /// «Mappa, fuoco»: il primo avvio, la mappa e il fuoco col segno ancora alto, senza la guardia in mezzo: era
        /// l'ingresso di base della 2b e della 2c, e sugli apparecchi non si è mai visto.
        case mapThenFire
    }

    /// I blocchi di un ingresso su audioQueue, dopo il Play, nell'ordine `order`.
    private func entryBlocks(_ f: FollowerBandRig, _ tFire: Double, localSeed: Int = 0,
                             order: EntryOrder = .real) {
        f.engineStart()
        switch order {
        case .real:
            f.loadSectionFromRunner(0)
            f.secondStartGuard()
        case .mapThenFire:
            f.loadSectionFromRunner(0)
        case .race:
            break
        }
        f.enter(tFire, localSeed: localSeed, engineStarted: true)
    }

    /// La band parte a `play`; l'iPad sente il Play 50 ms dopo (il Play accettato), poi i blocchi dell'ingresso
    /// nell'ordine vero; il fuoco cade sull'istante del battito `entryBeat` della canzone (una battuta di Link); il
    /// primo buffer esce `outDelay` dopo. `mapArrived` falso: la gara (il fuoco prima della mappa). `order`: un altro
    /// ordine dei blocchi. `renumbers`: (secondi dal Play, salto). `broken`: gli interruttori di rottura da accendere
    /// sul rig appena fatto. Rende il rig, la band e l'ora del fuoco.
    private func started(_ map: SongMap, entryBeat: Int = 4, localSeed: Int = 0,
                         renumbers: [(Double, Double)] = [], mapArrived: Bool = true, outDelay: Double? = nil,
                         withoutPointR: Bool = false, order: EntryOrder? = nil,
                         broken: (FollowerBandRig) -> Void = { _ in }) -> (FollowerBandRig, RigBand, Double) {
        var band = RigBand(map: map, tPlay: play)
        for (after, jump) in renumbers {
            band.renumbers.append((at: play + after, jump: jump))
        }
        let f = FollowerBandRig(map: map, band: band)
        f.withoutPointR = withoutPointR
        broken(f)
        if let delay = outDelay {
            f.outDelay = delay
        }
        f.playCallback(play + callback)
        let tFire = play + beatTime(map, entryBeat)
        entryBlocks(f, tFire, localSeed: localSeed, order: order ?? (mapArrived ? .real : .race))
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
        let t = play + beatTime(map, 4)
        entryBlocks(f, t)
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
        f.secondStartGuard()
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
        let t2 = 40.0 + beatTime(map, 4)
        entryBlocks(f, t2)
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
        f.rows = []
        let t3 = 80.0 + beatTime(map, 4)
        entryBlocks(f, t3)
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

    // MARK: - A432 PARTE 2c — i casi nuovi
    // DECISIONI_REFEREE_A432_PARTE2C_ARRESTO_2026-11-13 (par. 1, 3, 4, 5) e seguito 2c (punti 2, 3, 4).

    /// La rinumerazione del 01/11 al 7 → 9.
    private let jumpA = 4.0188
    /// E al 9 → 4.
    private let jumpB = 0.9352

    /// Una sezione sola: nessun cambio di tempo prima del drenaggio.
    private var songLast: SongMap { song([(4, 6, 121.0)]) }

    /// I tempi e i conti della scena «buco e poi rinumerazione» (`runHoleThenRenumbering`).
    private struct HoleScene {
        /// I battiti contati fra la prima chiamata dopo il buco e la lettura del buco.
        var countedBetween = 0
        /// Nella chiamata della lettura un battito è stato zittito (U9).
        var asapInReadCall = false
        /// La lettura del buco è nella prima chiamata dopo il buco.
        var readInHoleCall = false
        /// I battiti usciti fra la lettura del buco e l'esito della rinumerazione.
        var beatsBeforeRenumbering = 0
        var swapAt: Double? = nil
        var hole: (start: Double, end: Double)? = nil
        var holeCall: Double? = nil
        var readAt: Double? = nil
        var doneAt: Double? = nil
    }

    /// Le rinumerazioni riconosciute. Il salto è quello della riga, non arrotondato: i casi lo confrontano a quattro
    /// decimali (`assertRecognized`), come nel modello.
    private func recognized(_ f: FollowerBandRig) -> [FollowerBandRenumberingRecognized] {
        f.recognizedRows
    }

    /// Le letture dovute a un buco.
    private func holeReadings(_ f: FollowerBandRig) -> [RigReadingRow] {
        f.readingRows.filter { $0.reason == "buco" }
    }

    /// L'unico riallineo dovuto a un buco, coi suoi campi «dentro la canzone».
    private func singleHoleRealign(_ f: FollowerBandRig, file: StaticString = #filePath,
                                   line: UInt = #line) throws -> (row: RigRealignRow, detail: RigRealignDetail) {
        let all = f.realignRows.filter { $0.reason == "buco" }
        XCTAssertEqual(all.count, 1, "i riallinei dovuti a un buco", file: file, line: line)
        let row = try XCTUnwrap(all.first, "nessun riallineo dovuto a un buco", file: file, line: line)
        let detail = try XCTUnwrap(row.inSong, "il riallineo è «oltre la fine»", file: file, line: line)
        return (row, detail)
    }

    /// La scena della sonda: lo scambio di sezione dell'iPad al confine `boundaryBeat` (un cambio di metro: lo stato
    /// «rinumerazione attesa» si apre); un buco che comincia `holeStartCalls` chiamate dopo lo scambio e dura
    /// `holeSeconds`; la rinumerazione del Direttore due buffer dopo la LETTURA dovuta al buco (ci sia o no un
    /// riallineo), cioè dentro il battito che la segue. `prepare`: chiamata a ogni giro prima del buco, rende vero
    /// quando il buco può cominciare (per scegliere la fase). Rende il rig, la band (con la rinumerazione aggiunta) e
    /// i tempi.
    private func runHoleThenRenumbering(_ map: SongMap, boundaryBeat: Int, sectionAfter: Int, holeStartCalls: Int,
                                        holeSeconds: Double, jump: Double, entryBeat: Int,
                                        earlier: [(Double, Double)] = [], limitAfter: Double = 8.0,
                                        prepare: ((FollowerBandRig) -> Bool)? = nil)
        -> (FollowerBandRig, RigBand, HoleScene) {
        let (f, _, t) = started(map, entryBeat: entryBeat, renumbers: earlier)
        var tt = t
        var info = HoleScene()
        let limit = play + beatTime(map, boundaryBeat) + limitAfter
        while tt < limit && info.doneAt == nil {
            let before = f.mapSection
            var inHole = false
            if let hole = info.hole {
                inHole = hole.start <= tt && tt < hole.end
            }
            if !inHole {
                var firstAfter = false
                if let hole = info.hole, info.holeCall == nil, tt >= hole.end {
                    firstAfter = true
                    info.holeCall = tt
                }
                let beatsBefore = f.beats.count
                let readingsBefore = holeReadings(f).count
                let outcomesBefore = recognized(f).count + f.notCertainReasons.count
                let mutedBefore = f.lateMuted
                f.call(tt, hole: firstAfter)
                if info.readAt == nil && holeReadings(f).count > readingsBefore {
                    info.readAt = tt
                    if let holeCall = info.holeCall {
                        info.readInHoleCall = abs(tt - holeCall) < 1e-9
                    }
                    info.asapInReadCall = f.lateMuted > mutedBefore
                    // La band del rig è la sua copia: la rinumerazione si aggiunge lì.
                    f.band.renumbers.append((at: tt + 2.0 * buf - 1e-6, jump: jump))
                } else if info.readAt == nil && info.holeCall != nil {
                    info.countedBetween += f.beats.count - beatsBefore
                } else if info.readAt != nil {
                    if recognized(f).count + f.notCertainReasons.count > outcomesBefore {
                        info.doneAt = tt
                    } else {
                        info.beatsBeforeRenumbering += f.beats.count - beatsBefore
                    }
                }
            }
            if info.swapAt == nil && f.mapSection != before && f.mapSection == sectionAfter {
                info.swapAt = tt
            }
            if let swapAt = info.swapAt, info.hole == nil {
                var ready = (tt - swapAt) >= Double(holeStartCalls) * buf - 1e-9
                if ready, let prepare = prepare {
                    ready = prepare(f)
                }
                if ready {
                    info.hole = (start: tt + buf, end: tt + buf + holeSeconds)
                }
            }
            tt += buf
        }
        return (f, f.band, info)
    }

    /// Una corsa della sonda larga del referto d'arresto: la canzone del 01/11, il confine 7 → 9, un buco di
    /// `dBeats` battiti a 180,5 che comincia `h0` chiamate dopo lo scambio dell'iPad. Rende (riconosciuta, dentro la
    /// finestra, riallinei, i tempi).
    private func sweepRun(_ h0: Int, _ dBeats: Double) -> (Bool, Bool, Int, HoleScene) {
        let (f, _, info) = runHoleThenRenumbering(songA, boundaryBeat: 28, sectionAfter: 1, holeStartCalls: h0,
                                                  holeSeconds: dBeats * 60.0 / 180.5, jump: jumpA, entryBeat: 7)
        let seen = recognized(f)
        // una sola, al confine 1, col salto a quattro decimali, e nessun «conto non certo»
        let onlyThatOne = seen.count == 1 && seen.allSatisfy { $0.boundary == 1 && abs($0.jump - jumpA) <= 0.00005 }
        let ok = onlyThatOne && f.notCertainReasons.isEmpty
        let inside = info.readAt != nil && !info.readInHoleCall
        return (ok, inside, f.realignRows.count, info)
    }

    // MARK: - D4: il battito di controllo «sulla griglia»

    /// D4 (a): il Chorus del 01/11 (9 a 180,5 → 4 a 121). Un buco di 1,61 battiti a 121 (0,798 s, il buco del 29/10)
    /// dentro la finestra «sync skip» dello scambio; il riallineo alla prima chiamata dopo la finestra (+2); la
    /// rinumerazione del Direttore due buffer dopo, cioè meno di un battito dopo il riallineo. I battiti contati fra
    /// il buco e il riallineo sono usciti 1,61 battiti in ritardo: non sono sulla griglia e non fanno da controllo.
    /// Il controllo è l'ultimo battito contato prima del buco: la rinumerazione si riconosce, il conto resta certo.
    func testAFractionalHoleInsideTheWindowThenTheRenumberingWithinABeatIsRecognized() throws {
        let b1 = beatTime(songA, 28)
        let hole = 1.61 * 60.0 / 121.0
        let (f, band, info) = runHoleThenRenumbering(songA, boundaryBeat: 64, sectionAfter: 2, holeStartCalls: 10,
                                                     holeSeconds: hole, jump: jumpB, entryBeat: 7,
                                                     earlier: [(b1 + 1.08, jumpA)])
        // la lettura dopo la finestra, non nella chiamata del buco
        let readAt = try XCTUnwrap(info.readAt)
        XCTAssertFalse(info.readInHoleCall)
        // battiti contati col buco in attesa
        XCTAssertGreaterThanOrEqual(info.countedBetween, 1)
        let r = try singleHoleRealign(f)
        XCTAssertEqual(r.detail.jumpBeats, 2)
        // il riallineo nella chiamata della lettura
        XCTAssertEqual(r.row.callTime, readAt, accuracy: 1e-4)
        // nessun battito nuovo fra il riallineo e la rinumerazione
        XCTAssertEqual(info.beatsBeforeRenumbering, 0)
        // meno di un battito dopo
        let doneAt = try XCTUnwrap(info.doneAt)
        XCTAssertLessThan(doneAt - readAt, 60.0 / 121.0)
        assertRecognized(f, [(1, jumpA), (2, jumpB)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
    }

    /// D4 (b), il gemello: lo stesso buco FUORI dalla finestra (comincia 115 chiamate dopo lo scambio). La correzione
    /// è valutata nella chiamata del buco, il riallineo è lì, prima che esca qualunque battito: l'ultimo battito
    /// contato è quello di prima del buco, sulla griglia col suo nome. Deve restare lui il controllo (rinominarlo del
    /// salto lo sbaglia di due battiti): la rinumerazione si riconosce, come alla punta.
    func testAFractionalHoleOutsideTheWindowThenTheRenumberingWithinABeatIsRecognized() throws {
        let b1 = beatTime(songA, 28)
        let hole = 1.61 * 60.0 / 121.0
        let (f, _, info) = runHoleThenRenumbering(songA, boundaryBeat: 64, sectionAfter: 2, holeStartCalls: 115,
                                                  holeSeconds: hole, jump: jumpB, entryBeat: 7,
                                                  earlier: [(b1 + 1.08, jumpA)])
        XCTAssertTrue(info.readInHoleCall)
        XCTAssertEqual(info.countedBetween, 0)
        let r = try singleHoleRealign(f)
        XCTAssertEqual(r.detail.jumpBeats, 2)
        // K3: nessun battito nuovo fra la lettura e la rinumerazione
        XCTAssertEqual(info.beatsBeforeRenumbering, 0)
        assertRecognized(f, [(1, jumpA), (2, jumpB)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
    }

    /// D4 (c): un buco sotto il mezzo battito (0,3 battiti a 121: 149 ms) non fa perdere battiti: la lettura c'è, il
    /// riallineo no. Dentro la finestra i battiti contati dopo il buco sono usciti 0,3 battiti in ritardo (oltre
    /// 1/8): non fanno da controllo. Fuori dalla finestra il controllo è il battito di prima del buco. Riconosciuta
    /// in tutti e due.
    func testAHoleUnderHalfABeatInsideAndOutsideTheWindowKeepsTheCount() throws {
        let b1 = beatTime(songA, 28)
        let hole = 0.3 * 60.0 / 121.0
        let cases: [(Int, Bool)] = [(10, true), (115, false)]
        for (startCalls, inside) in cases {
            let (f, _, info) = runHoleThenRenumbering(songA, boundaryBeat: 64, sectionAfter: 2,
                                                      holeStartCalls: startCalls, holeSeconds: hole, jump: jumpB,
                                                      entryBeat: 7, earlier: [(b1 + 1.08, jumpA)])
            XCTAssertEqual(info.readInHoleCall, !inside, "\(startCalls)")
            XCTAssertEqual(holeReadings(f).count, 1, "\(startCalls)")
            // K3
            XCTAssertEqual(info.beatsBeforeRenumbering, 0, "\(startCalls)")
            XCTAssertEqual(f.realignRows.filter { $0.reason == "buco" }.count, 0, "\(startCalls)")
            assertRecognized(f, [(1, jumpA), (2, jumpB)])
            XCTAssertEqual(f.notCertainReasons.count, 0, "\(startCalls)")
            if inside {
                XCTAssertGreaterThanOrEqual(info.countedBetween, 1)
            }
        }
    }

    /// D4 (d): fuori dalla finestra, un buco di 1,25 battiti che comincia quando al battito in attesa mancano meno di
    /// 0,05 battiti. Al ritorno la correzione lo scavalca: il DSP lo fa uscire «subito», al primo campione, un quinto
    /// di battito in ritardo (U9: contato e non suonato), nella stessa chiamata della lettura e DOPO il punto R. Non
    /// è sulla griglia: il controllo resta il battito di prima del buco, e la rinumerazione due buffer dopo si
    /// riconosce.
    func testTheBeatSetAtOnceInTheReadingCallIsNotTheControl() throws {
        let b1 = beatTime(songA, 28)
        let hole = 1.25 * 60.0 / 121.0
        let (f, band, info) = runHoleThenRenumbering(
            songA, boundaryBeat: 64, sectionAfter: 2, holeStartCalls: 115, holeSeconds: hole, jump: jumpB,
            entryBeat: 7, earlier: [(b1 + 1.08, jumpA)],
            prepare: { rig in
                let ahead = rig.dsp.pendingBeat - rig.pos
                return 0.0 < ahead && ahead < 0.05
            })
        XCTAssertTrue(info.readInHoleCall)
        XCTAssertTrue(info.asapInReadCall)
        // K3: dopo il «subito» nessun altro battito prima della rinumerazione
        XCTAssertEqual(info.beatsBeforeRenumbering, 0)
        XCTAssertEqual(f.lateMuted, 1)
        let muted = f.beats.filter { $0.muted }
        XCTAssertEqual(muted.count, 1)
        let only = try XCTUnwrap(muted.first)
        // fuori griglia di più di 1/8
        let bandBeats = band.songBeats(only.outTime)
        XCTAssertGreaterThan(abs(bandBeats - bandBeats.rounded()), 0.125)
        assertRecognized(f, [(1, jumpA), (2, jumpB)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
    }

    /// Il confine 7 → 9 della canzone del 01/11; l'iPad si ferma (una ripartenza nella stessa canzone) e rientra dopo
    /// la rinumerazione del Direttore (+4,0188, 1,08 s dopo il confine), su una battuta di Link. `withHole`: prima di
    /// fermarsi un buco dentro la finestra dello scambio ha alzato il riallineo dovuto, che aspetta ancora la sua
    /// lettura. Rende il rig e la band.
    private func restartScene(withHole: Bool, file: StaticString = #filePath,
                              line: UInt = #line) throws -> (FollowerBandRig, RigBand) {
        let b1 = beatTime(songA, 28)
        let (f, band, t) = started(songA, entryBeat: 7, renumbers: [(b1 + 1.08, jumpA)])
        var tt = try runUntil(f, from: t, file: file, line: line) { $0.mapSection == 1 }
        for _ in 0..<10 {
            f.call(tt)
            tt += buf
        }
        if withHole {
            tt += 0.25
            f.call(tt, hole: true)
            tt += buf
            XCTAssertEqual(f.realignDue, "buco", file: file, line: line)
            f.call(tt)
        }
        // prima di fermarsi c'è un battito di controllo
        XCTAssertNotNil(f.gridBeat, file: file, line: line)
        f.interruption()
        // il primo battito della terza battuta del 9, 6 s dopo il confine
        let t2 = play + beatTime(songA, 28 + 9 * 2)
        XCTAssertGreaterThan(t2, play + b1 + 1.08, file: file, line: line)
        f.enter(t2, localSeed: 0)
        XCTAssertEqual(f.anchorsAlreadyAlive, 1, file: file, line: line)
        f.run(from: t2, to: t2 + 3.0, pulses: false)
        return (f, band)
    }

    /// D4 (e): buco nella finestra, ripartenza dell'iPad nella stessa canzone, lettura col salto. Il battito di
    /// controllo (quello di prima del buco) sopravvive all'avvio perché il riallineo dovuto «buco» aspetta ancora la
    /// sua lettura: la rinumerazione si riconosce e il riallineo rimette i nomi, come alla punta.
    func testAHoleWaitingForItsReadingSurvivesARestartOfTheIPad() throws {
        let (f, band) = try restartScene(withHole: true)
        let first = try XCTUnwrap(f.readingRows.first)
        XCTAssertEqual(first.reason, "buco")
        assertRecognized(f, [(1, jumpA)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
        XCTAssertGreaterThanOrEqual(f.realignRows.count, 1)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
    }

    /// D4 (f), il gemello: la stessa ripartenza senza nessun buco in attesa. All'avvio il battito di controllo si
    /// azzera, e l'àncora è nata nell'avvio di prima: alla lettura «ingresso» (prima del primo battito contato del
    /// nuovo avvio) il contatore d'accordo non ha nessun battito. Lo scarto oltre 1/8 con lo stato aperto non ha
    /// accordo: il conto si chiude, come alla punta. Un battito di prima di una ripartenza non fa da prova per una
    /// lettura dopo.
    func testARestartWithoutAHoleWaitingHasNoControlBeatAndAJumpClosesTheCount() throws {
        let (f, _) = try restartScene(withHole: false)
        let first = try XCTUnwrap(f.readingRows.first)
        XCTAssertEqual(first.reason, "ingresso")
        assertRecognized(f, [])
        let expected: [FollowerBandCountClosed?] = [FollowerBandCountClosed.jumpWithoutCounterAgreement]
        XCTAssertEqual(f.notCertainReasons, expected)
        XCTAssertEqual(f.realignRows.count, 0)
        // l'iPad va come prima
        XCTAssertTrue(f.running)
    }

    /// Le corse della sonda larga del referto d'arresto, un campione dentro il banco (le 507 intere girano sul
    /// modello): buchi di 0,45 · 1,25 · 1,5 · 1,61 battiti, dentro la finestra (25 e 85 chiamate dopo lo scambio) e
    /// fuori (110, 126, 159: le ultime due sono posizioni in cui un battito esce «subito»). La rinumerazione due
    /// buffer dopo la lettura del buco si riconosce sempre.
    func testTheSweepOfTheStopReportIsRecognizedEverywhere() throws {
        for h0 in [25, 85, 110, 126, 159] {
            for d in [0.45, 1.25, 1.5, 1.61] {
                let (ok, inside, realigns, _) = sweepRun(h0, d)
                let place = inside ? "dentro" : "fuori"
                XCTAssertTrue(ok, "h0=\(h0) D=\(d) \(place) riallinei=\(realigns)")
            }
        }
    }

    // MARK: - Il punto 2: l'àncora come controllo

    /// Seguito 2c punto 2, DECISIONI par. 3: l'iPad entra sul primo «uno» del 9 (A.11: lo stato nasce aperto); il
    /// primo buffer arriva dopo un buco di mezzo secondo, prima di qualunque battito contato; il Direttore rinumera
    /// nel frattempo. Alla lettura del buco non c'è nessun battito sulla griglia (quelli contati dopo il buco non lo
    /// sono): il contatore d'accordo prende l'àncora stessa, nata in questo avvio. La rinumerazione si riconosce.
    func testAHoleBeforeTheFirstCountedBeatUsesTheAnchorOfThisStart() throws {
        let (f, _, t) = started(songA, entryBeat: 28)
        let taken = try XCTUnwrap(f.anchorsTaken.first)
        XCTAssertEqual(taken.section, 1)
        XCTAssertEqual(taken.beat, 0)
        f.band.renumbers = [(at: t + 0.2, jump: jumpA)]
        var tt = t + 0.5
        f.call(tt, hole: true)
        tt += buf
        XCTAssertEqual(f.realignDue, "buco")
        f.run(from: tt, to: tt + 3.0, pulses: false)
        let first = try XCTUnwrap(f.readingRows.first)
        XCTAssertEqual(first.reason, "buco")
        assertRecognized(f, [(1, jumpA)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, f.band, realignOut), [])
    }

    /// DECISIONI par. 3 («per ogni motivo di lettura»): la stessa entrata sul primo «uno» del 9 senza nessun buco (il
    /// seme cade nella sezione dopo quella del motore: il riallineo dovuto è «ingresso»); la rinumerazione arriva
    /// prima del primo battito contato. Senza battiti sulla griglia il controllo è l'àncora di questo avvio:
    /// riconosciuta (cade il costo di A.11 scritto nel referto della 2b, C26).
    func testARenumberingBeforeTheFirstCountedBeatIsRecognizedForEveryReason() throws {
        let (f, _, t) = started(songA, entryBeat: 28)
        // dopo l'àncora (presa all'istante della battuta), prima del primo buffer
        f.band.renumbers = [(at: t - 0.004, jump: jumpA)]
        // la linea dell'iPad è già quella rinumerata: nessun salto di posizione
        f.line0 += jumpA
        XCTAssertEqual(f.realignDue, "ingresso")
        f.call(t)
        let reading = try singleReading(f)
        XCTAssertEqual(reading.reason, "ingresso")
        assertRecognized(f, [(1, jumpA)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
    }

    /// Seguito 2c punto 2: la ripartenza nella stessa canzone, il buco prima del primo battito contato del nuovo
    /// avvio e un salto. L'àncora è viva ma è nata nell'avvio di prima: il contatore d'accordo non ha nessun battito,
    /// e uno scarto oltre 1/8 non ha accordo: il conto si chiude, l'iPad va come prima.
    func testAfterARestartAHoleBeforeTheFirstCountedBeatHasNoAnchorAndAJumpClosesTheCount() throws {
        let b1 = beatTime(songA, 28)
        let (f, _, t) = started(songA, entryBeat: 7, renumbers: [(b1 + 1.08, jumpA)])
        var tt = try runUntil(f, from: t) { $0.mapSection == 1 }
        for _ in 0..<10 {
            f.call(tt)
            tt += buf
        }
        f.interruption()
        let t2 = play + beatTime(songA, 28 + 9 * 2)
        f.enter(t2, localSeed: 0)
        // il primo buffer del nuovo avvio arriva dopo un buco
        f.call(t2 + 0.4, hole: true)
        XCTAssertEqual(f.realignDue, "buco")
        f.run(from: t2 + 0.4 + buf, to: t2 + 3.0, pulses: false)
        let first = try XCTUnwrap(f.readingRows.first)
        XCTAssertEqual(first.reason, "buco")
        assertRecognized(f, [])
        let expected: [FollowerBandCountClosed?] = [FollowerBandCountClosed.jumpWithoutCounterAgreement]
        XCTAssertEqual(f.notCertainReasons, expected)
        XCTAssertEqual(f.realignRows.count, 0)
        XCTAssertTrue(f.running)
    }

    // MARK: - Il punto 3: il riallineo a motore in drenaggio

    /// L'iPad passa avanti (o indietro) di `ahead` battiti a mano, senza battiti al secondo; quando il drenaggio
    /// comincia la rete al secondo cade alla `k`-esima chiamata del drenaggio. Rende il rig, la band, e se la rete
    /// al secondo è caduta.
    private func drainRun(_ map: SongMap, ahead: Int, k: Int, alone: Bool = false, shiftAt: Double? = nil,
                          pulse: Bool = true) -> (FollowerBandRig, RigBand, Bool) {
        let (f, band, t) = started(map, entryBeat: 4)
        var total = 0
        for s in map.sections {
            total += s.rigTotal
        }
        let lastTotal = map.sections[map.sections.count - 1].rigTotal
        let when = shiftAt ?? (play + beatTime(map, total - lastTotal / 2) + 0.1)
        var tt = f.run(from: t, to: when, pulses: false)
        if alone {
            f.goAlone(tt)
        }
        f.counter += ahead
        var pulsed = false
        var n = 0
        while f.running && n < 6000 {
            let was = f.sectionEndPending
            f.call(tt)
            tt += buf
            n += 1
            if pulse && !pulsed && !was && f.sectionEndPending {
                for _ in 0..<(k - 1) {
                    f.call(tt)
                    tt += buf
                }
                f.secondPulse()
                pulsed = true
            }
        }
        return (f, band, pulsed)
    }

    /// Il drenaggio come lo scrive il motore: dopo l'ultimo battito la chiusura si consegna quando la coda del click
    /// (40 ms: 1920 campioni) è esaurita, cioè alla quarta o alla quinta chiamata dopo; nelle 3 o 4 chiamate in mezzo
    /// il punto R può girare. Il DSP è fermo: l'ora del battito in attesa letta al punto R si sposta di un buffer a
    /// chiamata (qui la rete al secondo cade alla terza chiamata del drenaggio: due buffer oltre l'ora vera).
    func testTheDrainLastsAsLongAsTheClickAndThePendingBeatTimeMoves() throws {
        let (f, _, _) = drainRun(songLast, ahead: 0, k: 3)
        let end = play + beatTime(songLast, 24)
        let lastBeat = try XCTUnwrap(f.beats.last)
        let done = f.songEndsDelivered
        XCTAssertEqual(done.count, 1)
        let doneAt = try XCTUnwrap(done.first)
        let callsAfter = Int(((doneAt - (lastBeat.outTime - f.outDelay)) / buf).rounded())
        XCTAssertTrue(callsAfter == 4 || callsAfter == 5, "\(callsAfter)")
        XCTAssertEqual(f.readingRows.filter { $0.reason == "al-secondo" }.count, 1)
        XCTAssertEqual(f.drainSkippedAtRead, 2)
        // l'ora letta: quella vera più due buffer
        let pendingTime = try XCTUnwrap(f.pendingTimeAtRead)
        XCTAssertEqual(pendingTime - end, 2.0 * buf, accuracy: 2e-5)
    }

    /// Punto 3 (a) e D5: l'iPad è un battito AVANTI all'ultima battuta: conta il suo ultimo battito quando la band
    /// suona il penultimo, e drena. La rete al secondo cade nel drenaggio (alla prima, seconda, terza chiamata): per
    /// la band il battito in attesa è l'ultimo della canzone. Il riallineo riapre la sezione (salto −1: il posto del
    /// motore in drenaggio è la fine), il DSP, rimasto fermo, si porta dove sarebbe senza drenaggio, e l'ultimo
    /// battito della band esce ALLA STESSA ORA di una corsa in cui l'iPad non era avanti. Poi la canzone finisce con
    /// la band.
    func testARealignInTheDrainReopensTheLastBarAndTheClickIsOnTime() throws {
        let (twin, _, _) = drainRun(songLast, ahead: 0, k: 1, pulse: false)
        let twinLast = try XCTUnwrap(twin.beats.last)
        let twinShown = try XCTUnwrap(twin.view.shown.last)
        for alone in [false, true] {
            for k in [1, 2, 3] {
                let (f, _, _) = drainRun(songLast, ahead: 1, k: k, alone: alone)
                let r = try singleRealign(f)
                XCTAssertEqual(r.row.reason, "al-secondo", "\(alone) \(k)")
                XCTAssertEqual(r.detail.jumpBeats, -1, "\(alone) \(k)")
                XCTAssertTrue(r.detail.loadsSection, "\(alone) \(k)")
                XCTAssertEqual(r.row.motor, RigSpot(section: 0, beat: 0), "\(alone) \(k)")
                XCTAssertEqual(r.detail.band, RigSpot(section: 0, beat: 23), "\(alone) \(k)")
                // le chiamate in cui il DSP è rimasto fermo
                let reopened = try XCTUnwrap(f.reopened.first)
                XCTAssertEqual(reopened.drainSkipped, k - 1, "\(alone) \(k)")
                XCTAssertEqual(f.beats.count, twin.beats.count, "\(alone) \(k)")
                let lastBeat = try XCTUnwrap(f.beats.last)
                XCTAssertEqual(lastBeat.outTime, twinLast.outTime, accuracy: 2e-6,
                               "\(alone) \(k): il click alla stessa ora del gemello")
                // col nome e l'etichetta della band
                XCTAssertEqual(lastBeat.section, 0, "\(alone) \(k)")
                XCTAssertEqual(lastBeat.beatInSection, 23, "\(alone) \(k)")
                XCTAssertEqual(lastBeat.label, 3, "\(alone) \(k)")
                XCTAssertEqual(f.lateMuted, 0, "\(alone) \(k)")
                XCTAssertEqual(f.songEndsDelivered.count, 1, "\(alone) \(k)")
                XCTAssertTrue(f.ended, "\(alone) \(k)")
                // la grafica: battuta e battito dell'ultimo tick sono quelli del gemello
                let shown = try XCTUnwrap(f.view.shown.last)
                XCTAssertEqual(shown.bar, twinShown.bar, "\(alone) \(k)")
                XCTAssertEqual(shown.beat, twinShown.beat, "\(alone) \(k)")
            }
        }
    }

    /// D5, DA-SOLO dentro la finestra «sync skip»: lì la linea propria non rimette la posizione (non gira), e il DSP
    /// nel drenaggio resta fermo come in sync. Un'ultima sezione di una battuta a 241 (un secondo: tutta dentro la
    /// finestra dello scambio), stesso tempo della sezione prima: l'iPad un battito avanti, la lettura alla terza
    /// chiamata del drenaggio. Il click dell'ultimo battito esce alla stessa ora del gemello.
    func testARealignInTheDrainInsideTheWindowOnItsOwnIsOnTime() throws {
        let map = song([(4, 4, 241.0), (4, 1, 241.0)])
        let shift = play + beatTime(map, 17) + 0.05
        let (twin, _, _) = drainRun(map, ahead: 0, k: 1, alone: true, shiftAt: shift, pulse: false)
        let (f, _, _) = drainRun(map, ahead: 1, k: 3, alone: true, shiftAt: shift)
        // la lettura dentro la finestra
        let syncSkip = try XCTUnwrap(f.syncSkipAtRead)
        XCTAssertGreaterThan(syncSkip, 0)
        let r = try singleRealign(f)
        XCTAssertEqual(r.detail.jumpBeats, -1)
        let reopened = try XCTUnwrap(f.reopened.first)
        XCTAssertEqual(reopened.drainSkipped, 2)
        XCTAssertEqual(f.beats.count, twin.beats.count)
        let lastBeat = try XCTUnwrap(f.beats.last)
        let twinLast = try XCTUnwrap(twin.beats.last)
        XCTAssertEqual(lastBeat.outTime, twinLast.outTime, accuracy: 2e-6, "il click alla stessa ora del gemello")
    }

    /// Punto 3, il ramo «posto uguale ma in drenaggio»: l'ultima sezione è una battuta sola e l'iPad è avanti di una
    /// battuta intera: ha finito la canzone quando la band comincia l'ultima battuta. Alla lettura nel drenaggio il
    /// posto della band (sezione 1, battito 0) è uguale al contatore del motore (azzerato dal drenaggio): senza la
    /// condizione sul drenaggio il riallineo non farebbe niente e l'iPad finirebbe una battuta prima. Il riallineo
    /// riapre la sezione (salto −4) e l'iPad risuona l'ultima battuta con la band.
    func testTheIPadAWholeLastSectionAheadIsBroughtBackFromTheDrain() throws {
        let map = song([(4, 5, 121.0), (4, 1, 121.0)])
        let shift = play + beatTime(map, 9) + 0.1
        let (twin, _, _) = drainRun(map, ahead: 0, k: 1, shiftAt: shift, pulse: false)
        let (f, band, _) = drainRun(map, ahead: 4, k: 2, shiftAt: shift)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "al-secondo")
        XCTAssertEqual(r.row.motor, RigSpot(section: 1, beat: 0))
        XCTAssertEqual(r.detail.band, RigSpot(section: 1, beat: 0))
        XCTAssertEqual(r.detail.jumpBeats, -4)
        XCTAssertTrue(r.detail.loadsSection)
        XCTAssertEqual(f.beats.count, twin.beats.count)
        let lastBeat = try XCTUnwrap(f.beats.last)
        let twinLast = try XCTUnwrap(twin.beats.last)
        XCTAssertEqual(lastBeat.outTime, twinLast.outTime, accuracy: 2e-6)
        XCTAssertEqual(f.beats.suffix(4).map { RigSpot(section: $0.section, beat: $0.beatInSection) },
                       [RigSpot(section: 1, beat: 0), RigSpot(section: 1, beat: 1), RigSpot(section: 1, beat: 2),
                        RigSpot(section: 1, beat: 3)])
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        XCTAssertEqual(f.songEndsDelivered.count, 1)
    }

    /// Punto 3 (b): l'iPad allineato (e poi un battito INDIETRO): la lettura al secondo cade nel drenaggio e trova la
    /// band oltre la fine. Il motore drena già: niente da fare. Nessun riallineo, nessuna riga, la chiusura si
    /// consegna una volta sola, quando la coda del click è finita.
    func testAReadingInTheDrainWithTheBandPastTheEndDoesNothing() throws {
        let cases: [(Int, Int)] = [(0, 0), (-1, 1)]
        for (behind, beyond) in cases {
            let (f, _, pulsed) = drainRun(songLast, ahead: behind, k: 2)
            XCTAssertTrue(pulsed, "\(behind)")
            let readings = f.readingRows.filter { $0.reason == "al-secondo" }
            XCTAssertEqual(readings.count, 1, "\(behind)")
            let reading = try XCTUnwrap(readings.first)
            XCTAssertTrue(reading.certain, "\(behind)")
            XCTAssertEqual(f.placeAtRead, FollowerBandPlace.pastEnd(beats: beyond), "\(behind)")
            XCTAssertEqual(f.realignRows.count, 0, "\(behind)")
            XCTAssertEqual(f.realigns, 0, "\(behind)")
            XCTAssertEqual(f.reopened, [], "\(behind)")
            XCTAssertEqual(f.songEndsDelivered.count, 1, "\(behind)")
            XCTAssertEqual(f.beats.count, 20 - behind, "\(behind)")
        }
    }

    /// Punto 3 (c): un buco di 1,61 battiti nell'ultima battuta (non passa la fine): il riallineo rimette il
    /// contatore (+2), l'iPad suona l'ultimo battito con la band e drena con lei; la rete al secondo cade nei buffer
    /// del drenaggio: la band è oltre la fine, niente da fare. Una sola chiusura di fine canzone, entro 60 ms dalla
    /// fine dell'ultimo battito.
    func testAHoleInTheLastBarIsRealignedAndTheNetInTheDrainDoesNothing() throws {
        let map = songLast
        let end = play + beatTime(map, 24)
        let (f, _, t) = started(map, entryBeat: 4)
        let start = play + beatTime(map, 20) + 0.1
        f.run(from: t, to: start, pulses: false)
        var tt = start + 1.61 * 60.0 / 121.0
        f.call(tt, hole: true)
        tt += buf
        let first = try singleRealign(f)
        XCTAssertEqual(first.row.reason, "buco")
        XCTAssertEqual(first.detail.jumpBeats, 2)
        var pulsed = false
        var n = 0
        while f.running {
            let was = f.sectionEndPending
            f.call(tt)
            tt += buf
            if !pulsed && !was && f.sectionEndPending {
                f.call(tt)
                tt += buf
                f.secondPulse()
                pulsed = true
            }
            // il tetto ferma un giro che non finisce
            n += 1
            if n >= 6000 {
                XCTFail("la canzone non finisce")
                throw NotTheExpectedCase()
            }
        }
        XCTAssertTrue(pulsed)
        XCTAssertEqual(f.realignRows.count, 1)
        XCTAssertEqual(f.realigns, 1)
        XCTAssertEqual(f.readingRows.map { $0.reason }, ["buco", "al-secondo"])
        let lastBeat = try XCTUnwrap(f.beats.last)
        XCTAssertEqual(lastBeat.section, 0)
        XCTAssertEqual(lastBeat.beatInSection, 23)
        // l'ultimo battito all'ora della band
        XCTAssertEqual(lastBeat.outTime, end - 60.0 / 121.0, accuracy: 0.001)
        // nessun battito dopo l'ultimo della band
        XCTAssertEqual(f.beats.filter { $0.outTime > end - 0.4 }, [])
        let done = f.songEndsDelivered
        XCTAssertEqual(done.count, 1)
        let doneAt = try XCTUnwrap(done.first)
        let tail = doneAt + f.outDelay - lastBeat.outTime
        XCTAssertGreaterThan(tail, 0.0)
        XCTAssertLessThan(tail, 0.060)
    }

    // MARK: - Il punto 4: A424 par. 2.2 d anche DA-SOLO

    /// A424 par. 2.2 d, DA-SOLO: lo scambio è fatto, il tempo della sezione nuova è armato per il battito dopo,
    /// l'iPad (sulla linea propria) è un battito indietro. Il riallineo carica la sezione coi setter immediati: il
    /// tempo del sequencer, il tempo del motore e il BPM a schermo sono subito quelli della sezione nuova, la linea
    /// propria si butta e si ri-àncora col tempo nuovo; nessuna W2 (DA-SOLO non scrive mai su Link).
    func testOnItsOwnARealignWithTheTempoArmedLoadsTheSectionAtOnce() throws {
        let map = song([(4, 4, 53.0), (4, 8, 67.0)])
        let (f, band, t) = started(map, entryBeat: 4)
        var tt = f.run(from: t, to: t + 2.0, pulses: false)
        f.goAlone(tt)
        tt = f.run(from: tt, to: play + beatTime(map, 13) + 0.3, pulses: false)
        f.counter -= 1
        tt = try runUntil(f, from: tt) { $0.mapSection == 1 }
        XCTAssertEqual(f.counter, 0)
        XCTAssertEqual(f.pendingBpmValue, 67.0)
        XCTAssertEqual(f.engineTempo, 53.0)
        XCTAssertEqual(f.seqTempo, 53.0)
        XCTAssertEqual(f.dsp.bpm, 53.0)
        f.secondPulse()
        f.call(tt)
        tt += buf
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "al-secondo")
        XCTAssertEqual(r.row.motor, RigSpot(section: 1, beat: 0))
        XCTAssertEqual(r.detail.band, RigSpot(section: 1, beat: 1))
        XCTAssertEqual(r.detail.jumpBeats, 1)
        XCTAssertTrue(r.detail.loadsSection)
        XCTAssertTrue(r.detail.tempoArmed)
        XCTAssertEqual(f.engineTempo, 67.0)
        XCTAssertEqual(f.seqTempo, 67.0)
        XCTAssertEqual(f.screenBpm, 67.0)
        XCTAssertEqual(f.dsp.bpm, 67.0)
        XCTAssertNil(f.pendingBpmValue)
        XCTAssertNil(f.dsp.armedBpm)
        // la linea propria col tempo di prima è buttata
        XCTAssertNil(f.ownTimeline)
        f.run(from: tt, to: tt + 6.0, pulses: false)
        // e ri-ancorata col tempo della sezione nuova (dopo la finestra)
        let own = try XCTUnwrap(f.ownTimeline)
        XCTAssertEqual(own.bpm, 67.0)
        XCTAssertEqual(f.w2, [])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
        // il click va a 67 (60 / 67 = 0,8955 s): i passi fra gli ultimi cinque battiti, a tre decimali, sono 0,896
        let lastFive = f.beats.suffix(5).map { $0.outTime }
        var gaps: [Double] = []
        for (earlier, later) in zip(lastFive, lastFive.dropFirst()) {
            gaps.append(RigNumbers.round3(later - earlier))
        }
        XCTAssertEqual(gaps.count, 4)
        for gap in gaps {
            XCTAssertEqual(gap, 0.896, accuracy: 1e-9)
            XCTAssertEqual(gap, 60.0 / 67.0, accuracy: 1e-3)
        }
    }

    /// A424 par. 2.2 d, DA-SOLO, il buco: il buco cade fra lo scambio e il primo battito della sezione nuova. Dentro
    /// la finestra la lettura aspetta; il primo battito esce in ritardo e porta il tempo nuovo per la strada di
    /// sempre. Dopo la finestra il riallineo rimette i nomi: tempo del sequencer, tempo del motore, linea propria e
    /// BPM a schermo sono quelli della sezione nuova; nessuna W2.
    func testOnItsOwnAHoleOnTheFirstBeatAfterASwapEndsInTheNewSectionWithoutW2() throws {
        let map = two
        let (f, band, t) = started(map, entryBeat: 4)
        var tt = f.run(from: t, to: t + 2.0, pulses: false)
        f.goAlone(tt)
        tt = try runUntil(f, from: tt) { $0.mapSection == 1 }
        XCTAssertEqual(f.pendingBpmValue, 91.0)
        tt += 1.61 * 60.0 / 121.0
        f.call(tt, hole: true)
        tt += buf
        XCTAssertEqual(f.realignDue, "buco")
        f.run(from: tt, to: tt + 5.0, pulses: false)
        let r = try singleRealign(f)
        XCTAssertEqual(r.row.reason, "buco")
        XCTAssertEqual(f.mapSection, 1)
        XCTAssertEqual(f.engineTempo, 91.0)
        XCTAssertEqual(f.seqTempo, 91.0)
        XCTAssertEqual(f.screenBpm, 91.0)
        XCTAssertEqual(f.dsp.bpm, 91.0)
        let own = try XCTUnwrap(f.ownTimeline)
        XCTAssertEqual(own.bpm, 91.0)
        XCTAssertEqual(f.w2, [])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let realignOut = try lastRealignOut(f)
        XCTAssertEqual(wrongNamesAfter(f, band, realignOut), [])
    }

    // MARK: - La risposta a D5-bis: lo scarto dopo un cambio di tempo

    /// Risposta del referee a D5-bis (par. 1): «il riallineo non sposta mai un click nel tempo, a meno dello scarto
    /// fra sequencer e DSP dopo un cambio di tempo: lo stesso spostamento che fa ogni correzione di fase». Allo
    /// scambio il sequencer conta al tempo nuovo dall'inizio del buffer, il DSP dal campione dell'«uno» (a
    /// scostamento o nel buffer): dopo, i battiti del DSP stanno a (o / frequenza) × (1 − tempo di prima / tempo
    /// nuovo) secondi dalle posizioni intere del sequencer. Il drenaggio riaperto porta il click su quelle
    /// posizioni: lo spostamento rispetto al gemello è quello della formula, a meno di due campioni, e mai i buffer
    /// interi che uscirebbero senza la cura.
    func testAfterATempoChangeTheReopenedDrainMovesTheClickByTheSequencerOffset() throws {
        let cases: [(Double, Double)] = [(121.0, 91.0), (60.0, 120.0), (180.0, 70.0)]
        for (oldBpm, newBpm) in cases {
            let map = song([(4, 4, oldBpm), (4, 2, newBpm)])
            let (twin, _, _) = drainRun(map, ahead: 0, k: 1, pulse: false)
            let twinLast = try XCTUnwrap(twin.beats.last)
            for k in [1, 2, 3] {
                let (f, _, _) = drainRun(map, ahead: 1, k: k)
                XCTAssertEqual(f.reopened.count, 1, "\(oldBpm)->\(newBpm) k=\(k)")
                let reopened = try XCTUnwrap(f.reopened.first)
                XCTAssertEqual(reopened.drainSkipped, k - 1, "\(oldBpm)->\(newBpm) k=\(k)")
                XCTAssertEqual(f.tempoChangeOffsets.count, 1, "\(oldBpm)->\(newBpm) k=\(k)")
                let change = try XCTUnwrap(f.tempoChangeOffsets.first)
                XCTAssertEqual(change.was, oldBpm)
                XCTAssertEqual(change.now, newBpm)
                let formula = -(Double(change.offset) / RigNumbers.rate) * (1.0 - oldBpm / newBpm)
                // il massimo: lo scostamento è sotto un buffer
                XCTAssertLessThanOrEqual(abs(formula),
                                         (Double(RigNumbers.frames) / RigNumbers.rate) * abs(1.0 - oldBpm / newBpm))
                XCTAssertEqual(f.beats.count, twin.beats.count, "\(oldBpm)->\(newBpm) k=\(k)")
                let lastBeat = try XCTUnwrap(f.beats.last)
                let moved = lastBeat.outTime - twinLast.outTime
                XCTAssertEqual(moved, formula, accuracy: 2.0 / RigNumbers.rate + 1e-6,
                               "\(oldBpm)->\(newBpm) k=\(k): lo spostamento del click")
                XCTAssertEqual(f.lateMuted, 0, "\(oldBpm)->\(newBpm) k=\(k)")
            }
        }
    }

    // MARK: - A432 PARTE 2d — i casi nuovi
    // DECISIONI_REFEREE_A432_PARTE2D_ARRESTO (D1, D2, D5), _ARRESTO-2 (E1) e VERIFICA_REFEREE_A432_PARTE2C (K1-K8).

    /// Una sezione sola in 4/4 a 121.
    private var one: SongMap { song([(4, 16, 121.0)]) }

    /// Che cosa resta dopo il buco di `afterHole`: il conto nato, le àncore prese, i riallinei, i nomi sbagliati
    /// dopo il buco.
    private struct AfterHole: Equatable {
        let countAlive: Bool
        let anchorsTaken: Int
        let realigns: Int
        let wrongNames: Int
    }

    /// Un buco di 0,8 s due secondi dopo l'ingresso: rende (conto nato, àncore prese, riallinei, nomi sbagliati dopo
    /// il buco).
    private func afterHole(_ f: FollowerBandRig, _ band: RigBand, _ tFire: Double) -> AfterHole {
        f.run(from: tFire, to: tFire + 6.0, holes: [(tFire + 2.0, tFire + 2.8)])
        var countAlive = false
        if let alive = f.count {
            countAlive = alive.closed == nil
        }
        return AfterHole(countAlive: countAlive, anchorsTaken: f.anchorsTaken.count, realigns: f.realigns,
                         wrongNames: wrongNamesAfter(f, band, tFire + 3.5).count)
    }

    // MARK: - D1 e D2: la regola dell'ingresso nell'ordine vero

    /// Le scene dell'ingresso (`entryScene`).
    private enum EntryScene {
        /// La scena normale: avvio, mappa, guardia, fuoco.
        case normal
        /// Il gemello 1: avvio SENZA mappa, fuoco.
        case twinOne
        /// Il gemello 3: avvio, mappa, guardia; poi una ripartenza senza mappa PRIMA del primo fuoco.
        case twinThree
        /// Avvio, mappa, guardia; Stop; un Play nuovo senza mappa; avvio, fuoco.
        case stopThenANewPlayWithoutAMap
    }

    /// Le scene dell'ingresso, coi blocchi nell'ordine in cui girano su audioQueue. `broken`: gli interruttori di
    /// rottura da accendere sul rig appena fatto. Rende il rig, la band e l'ora del fuoco.
    private func entryScene(_ scene: EntryScene,
                            broken: (FollowerBandRig) -> Void = { _ in }) -> (FollowerBandRig, RigBand, Double) {
        let band = RigBand(map: one, tPlay: play)
        let f = FollowerBandRig(map: one, band: band)
        broken(f)
        f.playCallback(play + callback)
        let tFire = play + beatTime(one, 4)
        switch scene {
        case .normal:
            f.engineStart()
            f.loadSectionFromRunner(0)
            f.secondStartGuard()
            f.enter(tFire, engineStarted: true)
        case .twinOne:
            f.engineStart()
            f.enter(tFire, engineStarted: true)
        case .twinThree:
            f.engineStart()
            f.loadSectionFromRunner(0)
            f.secondStartGuard()
            f.interruption()
            f.engineStart()
            f.enter(tFire, engineStarted: true)
        case .stopThenANewPlayWithoutAMap:
            f.engineStart()
            f.loadSectionFromRunner(0)
            f.secondStartGuard()
            f.stop()
            f.playCallback(play + callback)
            f.engineStart()
            f.enter(tFire, engineStarted: true)
        }
        return (f, band, tFire)
    }

    /// D1, la scena normale (50 ingressi su 50 nei registri A425-A429): Play, primo avvio, mappa, guardia del secondo
    /// avvio, fuoco. La guardia ha già consumato il segno: al fuoco il segno è basso e «canzone in corso» è alta. Con
    /// la regola (i) l'àncora si prende al fuoco, il seme dalla band entra nel contatore, e dopo un buco il riallineo
    /// rimette i nomi. Senza la regola (i) il fuoco terrebbe i suoi numeri e nessuno li userebbe: nessun conto.
    func testTheNormalEntryTakesTheAnchorAtTheFireWithTheSongInProgress() throws {
        let (f, band, t) = entryScene(.normal)
        XCTAssertEqual(f.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
        XCTAssertNil(f.entryPending)
        try assertSingleAnchorTaken(f, section: 0, beat: 4, delayBeats: callback * 121.0 / 60.0, seedApplied: true)
        XCTAssertEqual(afterHole(f, band, t), AfterHole(countAlive: true, anchorsTaken: 1, realigns: 1, wrongNames: 0))
    }

    /// D2, la gara (mai vista sugli apparecchi): il fuoco prima della mappa tiene i suoi numeri; la mappa e la guardia
    /// del secondo avvio prendono l'àncora, perché il consumo c'è. La regola (i) qui non entra: l'esito è lo stesso
    /// con la regola spenta, e lo si asserisce.
    func testTheRaceFireBeforeTheMapTakesTheAnchorAtTheGuardWithOrWithoutTheEntryRule() throws {
        for off in [false, true] {
            let (f, band, t) = started(one, entryBeat: 4, mapArrived: false, broken: { $0.entryRuleOff = off })
            XCTAssertNil(f.count, "\(off)")
            XCTAssertNotNil(f.entryPending, "\(off)")
            XCTAssertFalse(f.songInProgress, "\(off)")
            f.call(t)
            f.loadSectionFromRunner(0)
            f.counter = 1
            f.secondStartGuard()
            XCTAssertEqual(f.mark, SongMapMark(mapForNextStart: false, songInProgress: true), "\(off)")
            try assertSingleAnchorTaken(f, section: 0, beat: 4, delayBeats: callback * 121.0 / 60.0,
                                        seedApplied: false)
            f.run(from: t + buf, to: t + 6.0, holes: [(t + 2.0, t + 2.8)])
            let alive = try XCTUnwrap(f.count, "\(off)")
            XCTAssertNil(alive.closed, "\(off)")
            XCTAssertEqual(f.realigns, 2, "\(off)")
            XCTAssertEqual(wrongNamesAfter(f, band, t + 3.5).count, 0, "\(off)")
        }
    }

    /// D2, gemello 1: un avvio senza nessuna mappa consegnata, poi il fuoco. Segno basso, «canzone in corso» bassa: i
    /// numeri si tengono e nessun conto nasce; l'iPad va come prima. Uguale con la regola (i) spenta (asserito). Cade
    /// solo se la condizione del fuoco fosse sempre vera.
    func testAnEngineStartWithoutAMapThenTheFireTakesNoAnchor() throws {
        for off in [false, true] {
            let (f, band, t) = entryScene(.twinOne, broken: { $0.entryRuleOff = off })
            XCTAssertEqual(f.mark, SongMapMark(mapForNextStart: false, songInProgress: false), "\(off)")
            XCTAssertNotNil(f.entryPending, "\(off)")
            XCTAssertEqual(afterHole(f, band, t),
                           AfterHole(countAlive: false, anchorsTaken: 0, realigns: 0, wrongNames: 5), "\(off)")
        }
    }

    /// D2, gemello 3, IL LIMITE SCRITTO (DECISIONI par. 1): un'interruzione o un cambio di configurazione fra la
    /// guardia del secondo avvio e il primo fuoco. La ripartenza passa dal primo avvio col segno già basso: «canzone
    /// in corso» torna bassa, il fuoco tiene i suoi numeri, per quella canzone niente conto (il lato sicuro). Uguale
    /// con la regola (i) spenta (asserito). Cade se il primo avvio non riscrivesse «canzone in corso».
    func testARestartBetweenTheGuardAndTheFirstFireLeavesNoCount() throws {
        for off in [false, true] {
            let (f, band, t) = entryScene(.twinThree, broken: { $0.entryRuleOff = off })
            XCTAssertFalse(f.songInProgress, "\(off)")
            XCTAssertEqual(afterHole(f, band, t),
                           AfterHole(countAlive: false, anchorsTaken: 0, realigns: 0, wrongNames: 5), "\(off)")
        }
    }

    /// D2, la scena che prova lo Stop: ingresso normale (senza arrivare al fuoco), Stop, poi un Play nuovo che non
    /// consegna nessuna mappa, e il fuoco. «Canzone in corso» della canzone di prima non deve arrivare al fuoco. Le
    /// difese sono DUE: lo Stop la abbassa (`stopped`) e il primo avvio la riscrive dal segno (`normalStart`). Con una
    /// sola delle due tolta la scena resta verde (asserito qui); cade solo togliendole tutte e due.
    func testAfterAStopANewPlayWithoutAMapTakesNoAnchorAndEachDefenceAloneIsEnough() throws {
        let nothing = AfterHole(countAlive: false, anchorsTaken: 0, realigns: 0, wrongNames: 5)
        let (f, band, t) = entryScene(.stopThenANewPlayWithoutAMap)
        XCTAssertEqual(f.mark, SongMapMark(mapForNextStart: false, songInProgress: false))
        XCTAssertEqual(afterHole(f, band, t), nothing)
        let oneRuleOff: [(String, (FollowerBandRig) -> Void)] = [
            ("stopDoesNotLowerSongInProgress", { $0.stopDoesNotLowerSongInProgress = true }),
            ("startDoesNotRewriteSongInProgress", { $0.startDoesNotRewriteSongInProgress = true }),
            ("entryRuleOff", { $0.entryRuleOff = true })
        ]
        for (name, broken) in oneRuleOff {
            let (rig, rigBand, tFire) = entryScene(.stopThenANewPlayWithoutAMap, broken: broken)
            XCTAssertEqual(afterHole(rig, rigBand, tFire), nothing, name)
        }
    }

    /// D2: l'ordine di base della 2b e della 2c (il primo avvio, la mappa, il fuoco col segno ancora alto, senza la
    /// guardia in mezzo). Sugli apparecchi non si è MAI visto (0 su 50); resta come un solo caso del ramo: il fuoco
    /// prende l'àncora per il segno alto e poi consuma la mappa lui (come la guardia).
    func testTheOldBenchOrderMapThenFireNeverSeenOnDevicesStillTakesTheAnchor() throws {
        let (f, band, t) = started(one, entryBeat: 4, order: .mapThenFire)
        XCTAssertEqual(f.mark, SongMapMark(mapForNextStart: false, songInProgress: true))
        try assertSingleAnchorTaken(f, section: 0, beat: 4, delayBeats: callback * 121.0 / 60.0, seedApplied: true)
        XCTAssertEqual(afterHole(f, band, t), AfterHole(countAlive: true, anchorsTaken: 1, realigns: 1, wrongNames: 0))
    }

    // MARK: - E1: un Play accettato butta il segno vecchio

    /// La canzone A, di prima.
    private var songOld: SongMap { song([(3, 8, 97.0), (4, 8, 121.0)]) }

    /// L'ordine dei blocchi dopo il Play nella scena del segno vecchio (`staleMarkScene`).
    private enum StaleMarkOrder {
        /// La gara: il fuoco prima della mappa di B.
        case race
        /// L'ordine normale: la mappa di B, la guardia, il fuoco.
        case normal
    }

    /// La mappa della canzone A resta consegnata e non consumata (il suo `start()` è uscito senza avviare: il Follower
    /// ha trovato la sessione ferma); il runner passa alla canzone B; Play della band su B. `order`: la gara (il fuoco
    /// prima della mappa di B) o l'ordine normale. `broken`: gli interruttori di rottura da accendere sul rig appena
    /// fatto. Rende il rig, la band, l'ora del fuoco e la mappa del conto al fuoco (`nil`: al fuoco nessun conto).
    private func staleMarkScene(_ order: StaleMarkOrder, broken: (FollowerBandRig) -> Void = { _ in },
                                file: StaticString = #filePath,
                                line: UInt = #line) -> (FollowerBandRig, RigBand, Double, SongMap?) {
        let band = RigBand(map: one, tPlay: play)
        let f = FollowerBandRig(map: songOld, band: band)
        broken(f)
        // la consegna di A; nessun avvio
        f.loadSectionFromRunner(0)
        XCTAssertTrue(f.mapForNextStart, file: file, line: line)
        XCTAssertFalse(f.running, file: file, line: line)
        // il Play della band (su B)
        f.playCallback(play + callback)
        let tFire = play + beatTime(one, 4)
        f.engineStart()
        let atFire: SongMap?
        switch order {
        case .race:
            f.enter(tFire, engineStarted: true)
            atFire = f.count?.map
            f.call(tFire)
            f.loadSectionFromRunner(0, map: one)
            f.counter = 1
            f.secondStartGuard()
            f.run(from: tFire + buf, to: tFire + 6.0, holes: [(tFire + 2.0, tFire + 2.8)])
        case .normal:
            f.loadSectionFromRunner(0, map: one)
            f.secondStartGuard()
            f.enter(tFire, engineStarted: true)
            atFire = f.count?.map
            f.run(from: tFire, to: tFire + 6.0, holes: [(tFire + 2.0, tFire + 2.8)])
        }
        return (f, band, tFire, atFire)
    }

    /// E1 (DECISIONI-2 par. 1 e 2): il segno vecchio di A, poi il Play su B nell'ordine della gara. Il Play accettato
    /// abbassa il segno PRIMA del primo avvio: «canzone in corso» nasce bassa, il fuoco tiene i suoi numeri e l'àncora
    /// si prende alla guardia, sulla mappa di B. Senza la mossa il primo avvio farebbe del segno vecchio «canzone in
    /// corso» e con la regola (i) l'àncora si prenderebbe al fuoco sulla mappa di A (poi azzerata dalla mappa nuova:
    /// nessun conto).
    func testAnOldMapMarkThenAPlayOnAnotherSongInTheRaceOrderCountsOnTheNewSong() throws {
        let (f, band, t, atFire) = staleMarkScene(.race)
        // al fuoco nessun conto: i numeri tenuti
        XCTAssertNil(atFire)
        XCTAssertEqual(f.countResets, [])
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
        XCTAssertEqual(alive.map, one)
        XCTAssertEqual(f.anchorsTaken.count, 1)
        XCTAssertEqual(wrongNamesAfter(f, band, t + 3.5).count, 0)
    }

    /// E1, il gemello: lo stesso segno vecchio nell'ordine normale. Al fuoco la mappa del motore è già quella di B: il
    /// conto nasce su B con o senza la mossa del Play (asserito con la rottura «il Play non abbassa il segno»).
    func testAnOldMapMarkThenAPlayOnAnotherSongInTheNormalOrderCountsOnTheNewSongEitherWay() throws {
        for without in [false, true] {
            let (f, band, t, atFire) = staleMarkScene(.normal, broken: { $0.playDoesNotLowerTheMapMark = without })
            XCTAssertEqual(atFire, one, "\(without)")
            XCTAssertEqual(f.countResets, [], "\(without)")
            XCTAssertEqual(wrongNamesAfter(f, band, t + 3.5).count, 0, "\(without)")
        }
    }

    // MARK: - K1: il numero d'avvio dei numeri del fuoco

    /// La gara «fuoco → (ripartenza) → mappa» sul primo «uno» del 9 della canzone del 01/11 (lo stato nasce aperto).
    /// Il fuoco tiene i suoi numeri col numero del suo avvio; `restart`: prima della mappa il motore riparte senza un
    /// altro fuoco; poi la mappa e la guardia: l'àncora nasce dai numeri del fuoco. Il Direttore rinumera prima della
    /// prima lettura. Rende il rig e il numero dell'avvio del fuoco.
    private func fireThenMap(restart: Bool, file: StaticString = #filePath,
                             line: UInt = #line) throws -> (FollowerBandRig, Int) {
        let (f, _, t) = started(songA, entryBeat: 28, mapArrived: false)
        XCTAssertNil(f.count, file: file, line: line)
        let pending = try XCTUnwrap(f.entryPending, "il fuoco non ha tenuto i suoi numeri", file: file, line: line)
        let fireSerial = f.startSerial
        XCTAssertEqual(pending.startSerial, fireSerial, file: file, line: line)
        if restart {
            // la ripartenza senza fuoco: sale solo il numero dell'avvio
            f.engineStart()
        }
        f.loadSectionFromRunner(0)
        f.secondStartGuard()
        XCTAssertEqual(f.anchorsTaken.count, 1, file: file, line: line)
        // La band del rig è la sua copia: la rinumerazione si mette lì.
        f.band.renumbers = [(at: t - 0.004, jump: jumpA)]
        f.line0 += jumpA
        XCTAssertEqual(f.realignDue, "ingresso", file: file, line: line)
        f.call(t)
        return (f, fireSerial)
    }

    /// K1 (VERIFICA della 2c par. 3.1 voce 4): fuoco, ripartenza, mappa. L'àncora nasce dai numeri del fuoco e prende
    /// il numero dell'avvio del FUOCO, non quello dell'avvio in corso: alla prima lettura il controllo è «nessuno», e
    /// la rinumerazione in quella lettura, senza accordo, chiude il conto (come il caso f della 2c). Col numero
    /// dell'avvio in corso l'àncora farebbe da controllo e il salto verrebbe riconosciuto.
    func testAFireARestartThenTheMapLeavesNoControlAndAJumpClosesTheCount() throws {
        let (f, fireSerial) = try fireThenMap(restart: true)
        XCTAssertEqual(f.anchorStart, fireSerial)
        XCTAssertEqual(f.startSerial, fireSerial + 1)
        let first = try XCTUnwrap(f.readingRows.first)
        XCTAssertEqual(first.reason, "ingresso")
        XCTAssertEqual(f.controlAtRead, "nessuno")
        assertRecognized(f, [])
        let expected: [FollowerBandCountClosed?] = [FollowerBandCountClosed.jumpWithoutCounterAgreement]
        XCTAssertEqual(f.notCertainReasons, expected)
    }

    /// K1, il gemello senza ripartenza: l'àncora è nata nell'avvio della lettura: controllo «ancora», riconosciuta.
    func testAFireThenTheMapWithoutARestartUsesTheAnchorAsControl() throws {
        let (f, fireSerial) = try fireThenMap(restart: false)
        XCTAssertEqual(f.anchorStart, fireSerial)
        XCTAssertEqual(f.startSerial, fireSerial)
        XCTAssertEqual(f.controlAtRead, "ancora")
        assertRecognized(f, [(1, jumpA)])
        XCTAssertEqual(f.notCertainReasons.count, 0)
        let alive = try XCTUnwrap(f.count)
        XCTAssertNil(alive.closed)
    }

    // MARK: - K4: il battito di controllo non passa a un conto nuovo

    /// K4 (N2): un conto vivo con un battito di controllo, un buco nella finestra (il riallineo dovuto «buco» aspetta:
    /// il controllo sopravvive all'avvio), la ripartenza, e il runner consegna una mappa DIVERSA: il conto di prima
    /// finisce, e col conto se ne vanno il battito di controllo e l'avvio dell'àncora. Il fuoco ri-armato prende
    /// l'àncora sulla mappa nuova: alla prima lettura il controllo è l'àncora di questo avvio, mai un battito della
    /// canzone di prima.
    func testANewMapDropsTheControlBeatOfTheOldSong() throws {
        let (f, _, t) = started(songA, entryBeat: 7)
        var tt = try runUntil(f, from: t) { $0.mapSection == 1 }
        for _ in 0..<10 {
            f.call(tt)
            tt += buf
        }
        tt += 0.25
        f.call(tt, hole: true)
        XCTAssertEqual(f.realignDue, "buco")
        let oldGrid = try XCTUnwrap(f.gridBeat)
        f.interruption()
        // il controllo sopravvive: il buco aspetta ancora la sua lettura
        f.engineStart()
        XCTAssertEqual(f.gridBeat, oldGrid)
        // un'altra mappa (l'ultima sezione più corta)
        let other = song([(7, 4, 150.0), (9, 4, 180.5), (4, 12, 121.0)])
        f.loadSectionFromRunner(0, map: other)
        XCTAssertEqual(f.countResets, ["mappa-nuova"])
        XCTAssertNil(f.count)
        XCTAssertNil(f.realignDue)
        XCTAssertNil(f.gridBeat)
        XCTAssertNil(f.anchorStart)
        let t2 = play + beatTime(songA, 28 + 9 * 2)
        // il fuoco (ri-armato) di questo avvio
        f.enter(t2, engineStarted: true)
        // quella della canzone di prima e quella nuova
        XCTAssertEqual(f.anchorsTaken.count, 2)
        XCTAssertEqual(f.realignDue, "ingresso")
        f.call(t2)
        let last = try XCTUnwrap(f.readingRows.last)
        XCTAssertEqual(last.reason, "ingresso")
        XCTAssertEqual(f.controlAtRead, "ancora")
        XCTAssertEqual(f.notCertainReasons.count, 0)
    }

    /// K4 (N3): col conto finiscono il battito di controllo e l'avvio dell'àncora. Un Play nuovo della band accettato
    /// a motore fermo per un'interruzione azzera il conto; la mappa arriva e un fuoco ri-armato (nessun avvio in
    /// mezzo) prende l'àncora nuova: alla lettura dopo il controllo è l'àncora, non un battito del conto di prima.
    func testTheCountResetDropsTheControlBeatAndTheAnchorStart() throws {
        let (f, _, t) = started(one, entryBeat: 4)
        f.run(from: t, to: t + 3.0)
        XCTAssertNotNil(f.gridBeat)
        XCTAssertNotNil(f.anchorStart)
        f.interruption()
        let band2 = RigBand(map: one, tPlay: 40.0, link0: 5000.0)
        f.band = band2
        f.playCallback(40.0 + callback)
        XCTAssertNil(f.count)
        XCTAssertNil(f.gridBeat)
        XCTAssertNil(f.anchorStart)
        f.loadSectionFromRunner(0)
        let t2 = 40.0 + beatTime(one, 4)
        f.enter(t2, engineStarted: true)
        XCTAssertEqual(f.anchorsTaken.count, 2)
        f.secondPulse()
        f.call(t2)
        let last = try XCTUnwrap(f.readingRows.last)
        XCTAssertEqual(last.reason, "al-secondo")
        XCTAssertEqual(f.controlAtRead, "ancora")
    }

    // MARK: - K5: il drenaggio col massimo di chiamate ferme

    /// K5 (N4): la coda del click (1920 campioni) finisce un buffer dopo quando il battito che apre il drenaggio cade
    /// oltre il campione 128 del suo buffer: allora il drenaggio dura quattro chiamate e la lettura può cadere
    /// all'ultima, col DSP rimasto fermo TRE chiamate (il massimo: 32 ms). Nella canzone a 121 è così. L'ultimo click
    /// esce alla stessa ora del gemello, in sync e DA-SOLO; alla quinta chiamata il drenaggio è già chiuso.
    func testTheReadingAtTheLastDrainCallWithThreeFrozenCallsIsOnTime() throws {
        let (twin, _, _) = drainRun(songLast, ahead: 0, k: 1, pulse: false)
        let twinLast = try XCTUnwrap(twin.beats.last)
        for alone in [false, true] {
            let (f, _, _) = drainRun(songLast, ahead: 1, k: 4, alone: alone)
            let r = try singleRealign(f)
            XCTAssertEqual(r.detail.jumpBeats, -1, "\(alone)")
            XCTAssertTrue(r.detail.loadsSection, "\(alone)")
            // tre chiamate ferme prima della lettura
            let reopened = try XCTUnwrap(f.reopened.first, "\(alone)")
            XCTAssertEqual(reopened.drainSkipped, 3, "\(alone)")
            XCTAssertEqual(f.reopenCured.count, 1, "\(alone)")
            XCTAssertEqual(f.reopenSkipped, [], "\(alone)")
            XCTAssertEqual(f.beats.count, twin.beats.count, "\(alone)")
            let lastBeat = try XCTUnwrap(f.beats.last, "\(alone)")
            XCTAssertEqual(lastBeat.outTime, twinLast.outTime, accuracy: 2e-6,
                           "\(alone): il click alla stessa ora del gemello")
            XCTAssertEqual(lastBeat.section, 0, "\(alone)")
            XCTAssertEqual(lastBeat.beatInSection, 23, "\(alone)")
            XCTAssertEqual(lastBeat.label, 3, "\(alone)")
            XCTAssertEqual(f.lateMuted, 0, "\(alone)")
            XCTAssertEqual(f.songEndsDelivered.count, 1, "\(alone)")
        }
        // la quinta chiamata è la chiusura: nessuna lettura, nessun riallineo
        let (late, _, _) = drainRun(songLast, ahead: 1, k: 5)
        XCTAssertEqual(late.reopened, [])
        XCTAssertEqual(late.realignRows.count, 0)
        XCTAssertEqual(late.beats.count, twin.beats.count - 1)
    }

    // MARK: - K7 e D5: il limite di sicurezza della cura del drenaggio riaperto

    /// L'ultima sezione corta, tutta dentro la finestra «sync skip» dello scambio. Dopo lo scambio verso l'ultima
    /// sezione, a `leadCalls` chiamate dall'«uno», arriva il richiamo del tempo di Link col tempo `tempoCallback`
    /// (`nil` = nessun richiamo); `shiftSeconds`: la posizione del sequencer spostata a mano di tanti secondi
    /// (negativo = indietro); l'iPad passa avanti di `ahead` battiti; la rete al secondo cade alla `k`-esima chiamata
    /// del drenaggio (`nil` = mai). Rende il rig, la band, e se la rete al secondo è caduta.
    private func windowDrain(_ map: SongMap, ahead: Int, k: Int?, tempoCallback: Double? = nil, leadCalls: Int = 3,
                             shiftSeconds: Double? = nil, file: StaticString = #filePath,
                             line: UInt = #line) throws -> (FollowerBandRig, RigBand, Bool) {
        let (f, band, t) = started(map, entryBeat: 4)
        let last = map.sections.count - 1
        var tt = try callWhile(f, from: t, limit: 6000, file: file, line: line) { $0.mapSection != last }
        tt = try callWhile(f, from: tt, file: file, line: line) {
            $0.dsp.pendingSamplesAhead >= leadCalls * RigNumbers.frames
        }
        if let sessionTempo = tempoCallback {
            f.tempoCallback(sessionTempo)
        }
        if let shift = shiftSeconds {
            f.pos += shift * f.seqTempo / 60.0
        }
        f.counter += ahead
        var pulsed = false
        var n = 0
        while f.running && n < 6000 {
            let was = f.sectionEndPending
            f.call(tt)
            tt += buf
            n += 1
            if let nth = k, !pulsed, !was, f.sectionEndPending {
                for _ in 0..<(nth - 1) {
                    f.call(tt)
                    tt += buf
                }
                f.secondPulse()
                pulsed = true
            }
        }
        return (f, band, pulsed)
    }

    /// L'ultima sezione una battuta di 2/4: 121 → 163, tutta dentro la finestra.
    private var songRising: SongMap { song([(4, 3, 121.0), (2, 1, 163.0)]) }

    /// Lo stesso tempo: nessuno scarto fra sequencer e DSP allo scambio.
    private var songSame: SongMap { song([(4, 3, 121.0), (2, 1, 121.0)]) }

    /// K7 (VERIFICA della 2c par. 3.1 voce 2): dentro la finestra dello scambio il richiamo del tempo di Link arriva
    /// tre chiamate prima dell'«uno» col motore ancora al tempo di prima (adottato:1): il DSP riscala, il sequencer
    /// NON si ri-àncora e la sua posizione assoluta si moltiplica per 163/121 (centinaia di battiti). Poi l'iPad, un
    /// battito avanti, drena, e il riallineo riapre la sezione. La posizione del sequencer è lontana da quella del DSP
    /// più di quanto il drenaggio possa spiegare: la cura NON fa niente (nessun setter, nessun U9), con una riga;
    /// l'ultimo click esce come senza la cura, in ritardo delle chiamate ferme. Senza il limite uscirebbe 94,6 ms
    /// prima.
    func testASessionTempoCallbackInsideTheWindowThenAReopenedDrainSkipsTheCure() throws {
        let (twin, _, _) = try windowDrain(songRising, ahead: 0, k: nil, tempoCallback: 163.0)
        XCTAssertEqual(twin.tempoCallbacks, [RigTempoCallback(bpm: 163.0, engineTempo: 121.0, adopted: true)])
        let twinLast = try XCTUnwrap(twin.beats.last)
        for k in [2, 3, 4] {
            let (f, _, pulsed) = try windowDrain(songRising, ahead: 1, k: k, tempoCallback: 163.0)
            // la lettura dentro la finestra
            XCTAssertTrue(pulsed, "\(k)")
            let syncSkip = try XCTUnwrap(f.syncSkipAtRead, "\(k)")
            XCTAssertGreaterThan(syncSkip, 0, "\(k)")
            let reopened = try XCTUnwrap(f.reopened.first, "\(k)")
            XCTAssertEqual(reopened.drainSkipped, k - 1, "\(k)")
            XCTAssertEqual(f.reopenCured, [], "\(k)")
            XCTAssertEqual(f.reopenSkipped.count, 1, "\(k)")
            let skipped = try XCTUnwrap(f.reopenSkipped.first, "\(k)")
            XCTAssertGreaterThan(skipped.sequencerBeat - skipped.dspBeat, 100.0, "\(k)")
            XCTAssertLessThan(skipped.aheadLimitBeats, 0.2, "\(k)")
            XCTAssertEqual(f.reopenedDrainSkippedRows.count, 1, "\(k)")
            XCTAssertEqual(f.beats.count, twin.beats.count, "\(k)")
            let lastBeat = try XCTUnwrap(f.beats.last, "\(k)")
            XCTAssertEqual(lastBeat.outTime - twinLast.outTime, Double(k - 1) * buf, accuracy: 2e-6,
                           "\(k): in ritardo delle chiamate ferme, non di più")
            XCTAssertEqual(f.lateMuted, 0, "\(k)")
            XCTAssertEqual(f.notCertainReasons.count, 0, "\(k)")
        }
    }

    /// K7, il gemello senza richiamo: la stessa scena, la cura c'è e l'ultimo click è all'ora della 2c (lo scarto fra
    /// sequencer e DSP dopo il cambio di tempo: la formula della risposta a D5-bis, entro due campioni).
    func testWithoutTheSessionTempoCallbackTheReopenedDrainIsCuredAsBefore() throws {
        let (twin, _, _) = try windowDrain(songRising, ahead: 0, k: nil)
        let twinLast = try XCTUnwrap(twin.beats.last)
        for k in [2, 3] {
            let (f, _, pulsed) = try windowDrain(songRising, ahead: 1, k: k)
            XCTAssertTrue(pulsed, "\(k)")
            let syncSkip = try XCTUnwrap(f.syncSkipAtRead, "\(k)")
            XCTAssertGreaterThan(syncSkip, 0, "\(k)")
            let reopened = try XCTUnwrap(f.reopened.first, "\(k)")
            XCTAssertEqual(reopened.drainSkipped, k - 1, "\(k)")
            XCTAssertEqual(f.reopenSkipped, [], "\(k)")
            XCTAssertEqual(f.reopenCured.count, 1, "\(k)")
            let cured = try XCTUnwrap(f.reopenCured.first, "\(k)")
            XCTAssertGreaterThanOrEqual(cured.aheadOfDSP, 0.0, "\(k)")
            XCTAssertLessThan(cured.aheadOfDSP, cured.aheadLimitBeats, "\(k)")
            let change = try XCTUnwrap(f.tempoChangeOffsets.first, "\(k)")
            XCTAssertEqual(change.was, 121.0, "\(k)")
            XCTAssertEqual(change.now, 163.0, "\(k)")
            let formula = -(Double(change.offset) / RigNumbers.rate) * (1.0 - change.was / change.now)
            let lastBeat = try XCTUnwrap(f.beats.last, "\(k)")
            XCTAssertEqual(lastBeat.outTime - twinLast.outTime, formula, accuracy: 2.0 / RigNumbers.rate + 1e-6,
                           "\(k)")
            XCTAssertEqual(f.reopenedDrainSkippedRows.count, 0, "\(k)")
        }
    }

    /// D5 (DECISIONI par. 5): la soglia è a un lato. Un drenaggio porta il sequencer solo AVANTI al DSP; un sequencer
    /// DIETRO al DSP di più del margine (16,8 ms) non è un drenaggio: la cura si salta. Qui il sequencer è spostato a
    /// mano di 40 ms indietro dentro la finestra (dove la correzione di fase non lo rimette): l'ultimo click esce come
    /// senza la cura. In valore assoluto 40 ms starebbero sotto la soglia (59,5 ms) e la cura sposterebbe il click di
    /// 40 ms.
    func testASequencerBehindTheDSPBeyondTheMarginSkipsTheCure() throws {
        let (twin, _, _) = try windowDrain(songSame, ahead: 0, k: nil)
        let twinLast = try XCTUnwrap(twin.beats.last)
        for k in [1, 2] {
            let (f, _, pulsed) = try windowDrain(songSame, ahead: 1, k: k, shiftSeconds: -0.040)
            XCTAssertTrue(pulsed, "\(k)")
            let syncSkip = try XCTUnwrap(f.syncSkipAtRead, "\(k)")
            XCTAssertGreaterThan(syncSkip, 0, "\(k)")
            let reopened = try XCTUnwrap(f.reopened.first, "\(k)")
            XCTAssertEqual(reopened.drainSkipped, k - 1, "\(k)")
            XCTAssertEqual(f.reopenCured, [], "\(k)")
            XCTAssertEqual(f.reopenSkipped.count, 1, "\(k)")
            XCTAssertEqual(f.beats.count, twin.beats.count, "\(k)")
            let lastBeat = try XCTUnwrap(f.beats.last, "\(k)")
            XCTAssertEqual(lastBeat.outTime - twinLast.outTime, Double(k - 1) * buf, accuracy: 2e-6, "\(k)")
        }
        // il gemello (R1, 2d-bis): lo spostamento dentro il margine, 10 ms indietro alla lettura della PRIMA chiamata
        // del drenaggio (k = 1: nessuna chiamata ferma, il sequencer è davvero 10 ms DIETRO al DSP): la cura c'è
        let (behind, _, _) = try windowDrain(songSame, ahead: 1, k: 1, shiftSeconds: -0.010)
        let behindReopened = try XCTUnwrap(behind.reopened.first)
        XCTAssertEqual(behindReopened.drainSkipped, 0)
        XCTAssertEqual(behind.reopenSkipped, [])
        XCTAssertEqual(behind.reopenCured.count, 1)
        let behindCured = try XCTUnwrap(behind.reopenCured.first)
        XCTAssertLessThan(behindCured.aheadOfDSP, 0.0)
        XCTAssertEqual(behindCured.aheadOfDSP, -0.010 * 121.0 / 60.0, accuracy: 2e-5, "il netto: 10 ms indietro")
        // la scena di prima, con k = 2: una chiamata ferma porta il sequencer un buffer avanti, e con lo spostamento
        // di 10 ms indietro il netto è +0,67 ms, AVANTI (non dietro): la cura c'è, ma questa scena non prova il lato
        // «dietro»
        let (inside, _, _) = try windowDrain(songSame, ahead: 1, k: 2, shiftSeconds: -0.010)
        let insideReopened = try XCTUnwrap(inside.reopened.first)
        XCTAssertEqual(insideReopened.drainSkipped, 1)
        XCTAssertEqual(inside.reopenSkipped, [])
        XCTAssertEqual(inside.reopenCured.count, 1)
        let insideCured = try XCTUnwrap(inside.reopenCured.first)
        XCTAssertGreaterThan(insideCured.aheadOfDSP, 0.0)
        XCTAssertEqual(insideCured.aheadOfDSP, (buf - 0.010) * 121.0 / 60.0, accuracy: 2e-5, "il netto: +0,67 ms")
    }

    // MARK: - R2 (2d-bis): i bordi della soglia

    // VERIFICA_REFEREE_A432_PARTE2D par. 2 (R2). La soglia a 48 kHz va da −16,8 ms a +59,467 ms (quattro buffer più
    // il margine). Le scene di bordo: lo spostamento NETTO del sequencer rispetto al DSP è lo spostamento a mano più
    // un buffer per ogni chiamata ferma; per avere lo stesso netto con k = 1, 2, 3 lo spostamento a mano è il netto
    // meno (k − 1) buffer.

    /// Lo stesso tempo (nessuno scarto allo scambio), l'iPad un battito avanti, la lettura alla `k`-esima chiamata
    /// del drenaggio, il sequencer a `netSeconds` dal DSP (netto, col segno). Rende il rig e il netto in battiti.
    private func edgeScene(netSeconds: Double, k: Int, file: StaticString = #filePath,
                           line: UInt = #line) throws -> (FollowerBandRig, Double) {
        let (f, _, pulsed) = try windowDrain(songSame, ahead: 1, k: k, shiftSeconds: netSeconds - Double(k - 1) * buf,
                                             file: file, line: line)
        XCTAssertTrue(pulsed, "\(k)", file: file, line: line)
        let syncSkip = try XCTUnwrap(f.syncSkipAtRead, "\(k)", file: file, line: line)
        XCTAssertGreaterThan(syncSkip, 0, "\(k)", file: file, line: line)
        let reopened = try XCTUnwrap(f.reopened.first, "\(k)", file: file, line: line)
        XCTAssertEqual(reopened.drainSkipped, k - 1, "\(k)", file: file, line: line)
        return (f, netSeconds * 121.0 / 60.0)
    }

    /// Una scena di bordo dentro la soglia, con k = 1, 2, 3: la cura c'è, e la distanza vista dalla cura è il netto.
    private func assertEdgeIsCured(netSeconds: Double, file: StaticString = #filePath, line: UInt = #line) throws {
        for k in [1, 2, 3] {
            let (f, netBeats) = try edgeScene(netSeconds: netSeconds, k: k, file: file, line: line)
            XCTAssertEqual(f.reopenSkipped, [], "\(k)", file: file, line: line)
            XCTAssertEqual(f.reopenCured.count, 1, "\(k)", file: file, line: line)
            XCTAssertEqual(f.reopenedDrainSkippedRows.count, 0, "\(k)", file: file, line: line)
            let cured = try XCTUnwrap(f.reopenCured.first, "\(k)", file: file, line: line)
            // la scena è quella che dice
            XCTAssertEqual(cured.aheadOfDSP, netBeats, accuracy: 2e-5, "\(k): il netto", file: file, line: line)
        }
    }

    /// Una scena di bordo fuori dalla soglia, con k = 1, 2, 3: la cura si salta, la distanza è il netto (le due
    /// posizioni sono arrotondate a quattro cifre), e l'ultimo click esce in ritardo delle chiamate ferme, non
    /// spostato del netto.
    private func assertEdgeIsSkipped(netSeconds: Double, file: StaticString = #filePath, line: UInt = #line) throws {
        let (twin, _, _) = try windowDrain(songSame, ahead: 0, k: nil, file: file, line: line)
        let twinLast = try XCTUnwrap(twin.beats.last, file: file, line: line)
        for k in [1, 2, 3] {
            let (f, netBeats) = try edgeScene(netSeconds: netSeconds, k: k, file: file, line: line)
            XCTAssertEqual(f.reopenCured, [], "\(k)", file: file, line: line)
            XCTAssertEqual(f.reopenSkipped.count, 1, "\(k)", file: file, line: line)
            XCTAssertEqual(f.reopenedDrainSkippedRows.count, 1, "\(k)", file: file, line: line)
            let skipped = try XCTUnwrap(f.reopenSkipped.first, "\(k)", file: file, line: line)
            XCTAssertEqual(skipped.sequencerBeat - skipped.dspBeat, netBeats, accuracy: 2e-4, "\(k): il netto",
                           file: file, line: line)
            XCTAssertEqual(f.beats.count, twin.beats.count, "\(k)", file: file, line: line)
            let lastBeat = try XCTUnwrap(f.beats.last, "\(k)", file: file, line: line)
            XCTAssertEqual(lastBeat.outTime - twinLast.outTime, Double(k - 1) * buf, accuracy: 2e-6, "\(k)",
                           file: file, line: line)
        }
    }

    /// Il bordo «dietro», fuori: −17,5 ms (il margine è 16,8 ms): la cura si salta.
    func testTheEdgeSeventeenAndAHalfMillisecondsBehindSkipsTheCure() throws {
        try assertEdgeIsSkipped(netSeconds: -0.0175)
    }

    /// Il bordo «dietro», dentro: −16,5 ms: la cura c'è.
    func testTheEdgeSixteenAndAHalfMillisecondsBehindIsCured() throws {
        try assertEdgeIsCured(netSeconds: -0.0165)
    }

    /// Il bordo «avanti», dentro: +59,0 ms (il limite è quattro buffer più il margine: 42,667 + 16,8 = 59,467 ms): la
    /// cura c'è. Senza «la chiamata in più» il limite sarebbe 48,8 ms, senza il margine avanti 42,667 ms: si
    /// salterebbe.
    func testTheEdgeFiftyNineMillisecondsAheadIsCured() throws {
        try assertEdgeIsCured(netSeconds: 0.0590)
    }

    /// Il bordo «avanti», fuori: +60,0 ms: la cura si salta.
    func testTheEdgeSixtyMillisecondsAheadSkipsTheCure() throws {
        try assertEdgeIsSkipped(netSeconds: 0.0600)
    }
}
