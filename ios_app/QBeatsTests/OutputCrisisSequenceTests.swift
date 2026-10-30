import XCTest

// === A421 — banco delle sequenze delle cuffie e del buco del render (mandato «USCITA AUDIO PASSO 2a PEZZO 2», par. 4) ===
// Il motore ridotto a quello che conta per il pezzo 2 (`OutputRig`): il ruolo, show e canzone, `isRunning` e il motore di
// sistema, il volume del mixer principale e lo stato dell'uscita (`OutputRouteDecision`), la crisi e la causa ricordata
// (`CrisisStopDecision`), le ripartenze automatiche (`RecoveryDecision`), il cambio di configurazione
// (`EngineConfigChangeDecision`), la catena dei buffer, i ritorni e la rete (`OutputReturnDecision`), il battito in ritardo
// (`LateBeatDecision`), lo specchio `isPlaying` e la guardia del risveglio (`TransportStateDecision`), il coordinatore
// ridotto al bersaglio col margine di 150 ms e il salto al bersaglio dopo (T5). Il tempo in secondi, l'orologio a 24 MHz
// dove le regole vogliono i tick; la griglia di Link con la sessione partita a 0.
// Le sequenze del 24/10 coi tempi veri (registri delle 12:37, 13:59, 14:37); quelle del par. 2.3; quelle dei punti U5, U9,
// par. 2.2 a e c. Le tre difese (la notizia, il motore di sistema fermo, il misuratore) si possono spegnere una per una.
// === A421 · SEGUITO 1 (26/10/2026, mandato «A421 · SEGUITO 1», par. 2.3, 3.4, 4.4, 3.5) ===
// Due ore per il ritorno del Follower: la fine dei buffer programmati e il primo campione a volume 1 dall'ora del rendering;
// il buffer dell'«uno» dalla convenzione della correzione di fase. Lo scarto fra le due ore da -1 a +2 buffer (il commento di
// `nextBufferOutputHostTime`: circa 15 ms), il richiamo in ritardo fino a un buffer, il ciclo d'uscita di 5,33, 6,67, 10,67 e
// 21,33 ms (il giro di prove del 22/10), la lettura di riserva. La linea del tempo di Link con un'àncora (un cambio di tempo
// ri-àncora) e la linea propria DA-SOLO. Per il par. 3: il contatore della catena, gli inizi d'interruzione, il segno
// dell'eccezione, i tentativi ogni 0,5 s e la rete a 5 s, le scritture della sessione, gli inizi d'interruzione iniettati fra
// `setCategory` e la `setActive` e fra la `setActive` e `start()`, il modo Pro con la ricostruzione che ferma il motore.
// Per il par. 4: la rilettura del Follower a ogni avvio, l'apertura e la chiusura dello show.
// === A421 · SEGUITO 2 (30/10/2026, mandato «A421 · SEGUITO 2», par. 2.3, 3.5, 4.7, 5.6, 6.5, 7) ===
// Il margine del rientro max(150 ms, D + 80 ms) con D dalla scorta e dalla latenza, il lettore lento (il segno al fuoco in
// ritardo già certo all'armamento, nessun salto consumato); l'àncora tenuta dal rientro fino al primo battito contato uscito;
// il guardiano (un timer a quattro buffer dall'ultima chiamata: il silenzio durante il buco), la soglia al tempo con P, la crisi
// nella scorta e per l'uscita sparita, la finestra «sync skip» (la salita dello scarto, la prima correzione dopo), il ritorno
// dopo il buco (la scadenza riletta, il primo campione, l'esterna sparita con la riserva di 2 s); F1, E.1, E.7, E.9, F2; il Solo
// all'inizio di un'interruzione (m2, m4); il segno della mappa per il prossimo avvio. Il misuratore del buco resta dato dal
// banco (`gapSeconds`); lo scarto cumulato (`meterScarto`) dà la salita nella finestra.

/// Un buffer programmato: l'ora d'uscita (inizio e fine) e la catena.
private struct RigBuffer {
    let outputStart: Double
    let outputEnd: Double
    let chain: Int
}

private struct DirectorReturn {
    let wait: DirectorReturnWait
    let fireAt: Double
    let trigger: RecoveryTrigger
    /// L'ora dell'armamento: la ripresa pendente è assorbita solo da un ritorno armato dalla stessa notizia.
    let armedAt: Double
}

private struct FollowerReturn {
    let noticeAt: Double
    var armPending: Bool
    var chain: Int
    let fromTap: Bool
    /// A421 · SEGUITO 1 — la scadenza, il battito dell'«uno» col suo orologio (`nil` = «uno non calcolabile»), l'ora riletta.
    var deadlineAt: Double? = nil
    var uno: FollowerReturnUno? = nil
    var unoAt: Double? = nil
    /// A421 · SEGUITO 2 — il conto dei buffer all'armo e la fine dei buffer programmati riletta (E.8); la scadenza del primo
    /// tentativo senza «uno» (E.1).
    var armBufferCount: Int = 0
    var programmedEndAt: Double = 0
    var noUnoDeadline: Double? = nil
}

/// A421 · SEGUITO 2 (par. 4.4) — il ritorno dopo il buco.
private struct GapReturn {
    var armBufferCount: Int
    var chain: Int
    var programmedEndAt: Double
    var armedAt: Double
    var vanishedSince: Double? = nil
}

/// A421 · SEGUITO 2 (par. 4.2) — il guardiano armato: la catena, il conto dei buffer, l'ora.
private struct GuardianArm {
    let chain: Int
    let bufferCount: Int
    let dueAt: Double
}

private struct RejoinWait {
    let targetAt: Double
    let fireAt: Double
    let skips: Int
    /// A421 · SEGUITO 2 (par. 2.2 b): armato per adesso col segno «lettore-lento»; e il bersaglio scelto da quel fuoco, che si
    /// arma senza il controllo.
    var slowPlayer: Bool = false
    var fromSlowPlayer: Bool = false
}

/// A421 · SEGUITO 1 — un tentativo di `activateSessionAndStart` in volo (ogni 0,5 s), o la rete a 5 s dopo i tentativi esauriti.
private struct RetryWait {
    let fireAt: Double
    let trigger: RecoveryTrigger
    let attempt: Int
    let token: Int
}

private struct OutputRig {
    static let tps = 24_000_000.0
    /// Il buffer del lettore: 512 campioni, sempre (`bufferSize`); è il passo dei richiami, la misura dei buffer programmati e
    /// di `bufferReachesUno`.
    /// La frequenza dei nodi (48 o 44,1 kHz): il buffer da 512 campioni dura di conseguenza (correzione B4).
    var nodeRate = 48_000.0
    var bufferSeconds: Double { 512.0 / nodeRate }
    /// Il ciclo d'uscita della sessione (`bufferDurationTicks`): la convenzione della correzione di fase e l'ora del rendering
    /// lo sommano; il primo campione a volume 1 lo toglie. 5,33 / 6,67 / 10,67 / 21,33 ms (par. 2.3).
    var cycleSeconds = 512.0 / 48_000.0
    var latency = 0.0233
    var bpm: Double
    var beatsPerBar: Int
    /// A421 · SEGUITO 2 (par. 2.2 a): D, la scorta intera più la latenza, e il margine max(150 ms, D + 80 ms).
    var leadInBuffers: Int { DirectorRejoinDecision.leadInBuffers(bufferSeconds: bufferSeconds, ioBufferSeconds: cycleSeconds) ?? 0 }
    var firstBufferDistance: Double {
        DirectorRejoinDecision.firstBufferDistanceSeconds(bufferSeconds: bufferSeconds, ioBufferSeconds: cycleSeconds, outputLatencySeconds: latency)
    }
    var margin: Double { DirectorRejoinDecision.rejoinMarginSeconds(firstBufferDistanceSeconds: firstBufferDistance) }
    /// Senza il seguito 2 il margine era fisso (per le rotture volute del banco: il fuoco in ritardo del 29/10).
    var useFixedMargin = false
    var useSlowPlayerMark = true
    var useHeldAnchor = true
    /// Il guardiano si accende dove la prova lo guarda (`playing(…, guardian: true)`): i salti di tempo delle prove di prima
    /// (un cambio di percorso dieci secondi dopo l'ultimo richiamo) non sono buchi del render.
    var useGuardian = false
    /// Il percorso fisico quando la notizia non è ancora arrivata (lo stacco visto prima dal misuratore): quello che
    /// `hasExternalOutputNowQ` leggerebbe; `nil` = quello dell'ultima notizia.
    var physicalRoute: [OutputPort]? = nil

    // A421 · SEGUITO 1 — le due ore (par. 2.3): lo scarto fra l'ora del rendering e la convenzione, in buffer (da -1 a +2), e
    // la lettura di riserva; la linea del tempo di Link (àncora e tempo) e la linea propria DA-SOLO. Il richiamo in ritardo
    // sposta la convenzione (`t`), non l'ora del rendering, che resta sull'ora attesa del richiamo (`idealAt`).
    var renderOffsetBuffers = 0.0
    var fallbackRead = false
    var linkAnchorTime = 0.0
    var linkAnchorBeat = 0.0
    var followerClock: FollowerReturnClock = .link
    var ownTimeline: OwnClockTimeline? = nil
    var ownTimelineBPM = 0.0
    var ownBeatAtChange = 0.0
    var ownChangeTime = 0.0
    var ownRepinPending = false
    var lastUnoBeat: Double? = nil

    // Il ruolo e la canzone.
    var role: PlayerRole
    var showOpen = true
    var songInProgress = true

    // Il motore.
    var isRunning = false
    var engineRunning = false
    var isPlaying = false
    var volume: Float = 1.0
    var state = OutputSilenceState.initial
    var route: [OutputPort]
    var hardwareRate = 48_000.0
    var copyRate = 48_000.0
    var mediaServicesNormal = true
    var proMode = false

    // Le crisi e le riprese.
    var silentInSong = false
    var crisisCause: CrisisCause? = nil
    var wantedStop = false
    var followsLink = false
    var interrupted = false
    var systemInterruption = false
    var pendingResume = false
    var hardwareBusy = false
    // A421 · SEGUITO 1 (par. 3): il contatore della catena, gli inizi, il segno dell'eccezione, le `setActive` da far fallire, i
    // tentativi e la rete a 5 s, gli inizi iniettati nelle due finestre.
    var resumeToken = 0
    var beginsCount = 0
    var exceptionMark: InterruptionActivationException? = nil
    var setActiveFailures = 0
    var retry: RetryWait? = nil
    var safetyNet: RetryWait? = nil
    var injectBeginBeforeSetActive = false
    var injectBeginBeforeStart = false
    var injectStopBeforeSetActive = false

    // La catena.
    var chain = 0
    var queued: [RigBuffer] = []
    var drainPending = false
    var pendingBPM: Double? = nil
    var dspOrigin = 0.0
    var position = 0.0
    /// A421 · SEGUITO 2: i buffer programmati dall'avvio (`bufferCount`), la finestra «sync skip» (il contatore, aperta, la base
    /// e P), lo scarto cumulato del misuratore (la salita), la scorta del rientro, l'àncora (presa, tenuta dal rientro) e l'ora
    /// d'uscita del primo battito del rientro, il segno della mappa, la sessione del Follower.
    var bufferCount = 0
    var syncSkip = 0
    var windowOpen = false
    var windowRiseBase = 0.0
    var windowProjection = 0.0
    var firstCorrectionPending = false
    var meterScarto = 0.0
    var leadInBuffersLeft = 0
    var anchor = false
    var anchorHeld = false
    var firstBeatOutAt: Double? = nil
    /// Un battito contato è già uscito in questo avvio (l'àncora si prende solo così, `takeSilenceAnchorQ`).
    var countedBeatOut = false
    var songMapPending = false
    var followerSessionPlaying = true
    /// La distanza del primo buffer secondo le copie, se diversa da quella letta all'armamento (il fuoco la usa).
    var copiesDistance: Double? = nil

    // Le attese.
    var directorReturn: DirectorReturn? = nil
    var followerReturn: FollowerReturn? = nil
    var netAt: Double? = nil
    var rejoin: RejoinWait? = nil
    var engineStartDuration = 0.0
    /// A421 · SEGUITO 2: il ritorno dopo il buco con la sua riserva, il guardiano e il suo segno (la catena dello scatto).
    var gapReturn: GapReturn? = nil
    var gapVanishedAt: Double? = nil
    var guardian: GuardianArm? = nil
    var guardianSilenceChain: Int? = nil

    // Le difese, una per una.
    var useRouteCrisis = true
    var useStoppedEngineCheck = true
    var useMeterCrisis = true

    // I contatori.
    var now = 0.0
    var asserts = 0
    var corrections = 0
    var lateBeatsMuted = 0
    var clickSamplesWritten = 0
    var starts = 0
    var rejoins = 0
    var refusedForMissing = 0
    var stoppedCallbacks = 0
    var drainDelivered = 0
    var linkStops = 0
    var playbackStopped = false
    var raisedAt: Double? = nil
    var firstClickAt: Double? = nil
    var netFired = 0
    // A421 · SEGUITO 1: le ore dell'ultimo ritorno del Follower (par. 2.3), le scritture della sessione e le `setActive`
    // tentate (par. 3.4), le ricostruzioni, i no della regola, le reti a 5 s scattate o saltate.
    var deadlineAt: Double? = nil
    var programmedEndAt: Double? = nil
    var armedUnoAt: Double? = nil
    var restoredUnoAt: Double? = nil
    var firstSampleAt: Double? = nil
    var nextBarMoves = 0
    var rearms = 0
    var gapReturnsDroppedForFollower = 0
    var gapVanishedBack = 0
    var sessionWrites = 0
    var setActiveAttempts = 0
    var rebuilds = 0
    var refusals = 0
    var safetyNetFired = 0
    var safetyNetSkipped = 0
    var deadChainsAtSetActive = 0
    // A421 · SEGUITO 2: i contatori del seguito.
    var guardianFires = 0
    var gapReturnArms = 0
    var gapReturnRestores = 0
    var gapRestoredAt: Double? = nil
    var gapFirstSampleAt: Double? = nil
    var gapDeadlineAt: Double? = nil
    var gapVanishedWaits = 0
    var gapVanishedFired = 0
    var windowCrises = 0
    var leadInCrises = 0
    var vanishedCrises = 0
    var uncertainRejoins = 0
    var slowPlayerFires = 0
    var lateSkips = 0
    var soloStops = 0
    var chainsClosedAtBegin = 0
    var firstCorrectionRearms = 0
    var anchorClosedAt: Double? = nil
    var lastRejoinSkipsLeft: Int? = nil
    var guardianFiredAt: Double? = nil

    init(role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4,
         cycleSeconds: Double = 512.0 / 48_000.0, renderOffsetBuffers: Double = 0.0, fallbackRead: Bool = false) {
        self.role = role
        self.route = route
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.cycleSeconds = cycleSeconds
        self.renderOffsetBuffers = renderOffsetBuffers
        self.fallbackRead = fallbackRead
    }

    // MARK: - Aritmetica

    func ticks(_ seconds: Double) -> UInt64 { UInt64((seconds * OutputRig.tps).rounded()) }
    func seconds(_ t: UInt64) -> Double { Double(t) / OutputRig.tps }
    /// Il battito di Link all'ora `t`, sulla linea con l'àncora (un cambio di tempo ri-àncora).
    func linkBeat(at t: Double) -> Double { linkAnchorBeat + (t - linkAnchorTime) * bpm / 60.0 }
    func time(ofBeat beat: Double) -> Double { linkAnchorTime + (beat - linkAnchorBeat) * 60.0 / bpm }
    var bufferBeats: Double { bufferSeconds * bpm / 60.0 }
    var barSeconds: Double { Double(beatsPerBar) * 60.0 / bpm }

    /// Il primo «uno» di battuta di Link non prima di `t`.
    func nextBarTime(atOrAfter t: Double) -> Double {
        let beat = OutputReturnDecision.nextBarBeat(atOrAfter: linkBeat(at: t), quantum: Double(beatsPerBar))!
        return time(ofBeat: beat)
    }

    /// A421 · SEGUITO 1 — il primo «uno» non prima di `t`, come battito col suo orologio e la sua ora (`nextUnoQ`): Link, o la
    /// linea propria DA-SOLO (dall'ultimo «uno» uscito); `nil` = «uno non calcolabile».
    func nextUno(atOrAfter t: Double) -> (uno: FollowerReturnUno, at: Double)? {
        switch followerClock {
        case .link:
            guard let bar = OutputReturnDecision.nextBarBeat(atOrAfter: linkBeat(at: t), quantum: Double(beatsPerBar)) else { return nil }
            return (FollowerReturnUno(beat: bar, clock: .link, beatsPerBar: beatsPerBar), time(ofBeat: bar))
        case .own:
            guard let timeline = ownTimeline, let last = lastUnoBeat,
                  let beat = OutputReturnDecision.nextOwnUnoBeat(atOrAfter: timeline.beat(atTicks: ticks(t), ticksPerSecond: OutputRig.tps),
                                                                  lastUnoBeat: last, beatsPerBar: beatsPerBar),
                  let at = OutputReturnDecision.ownTicks(atBeat: beat, timeline: timeline, ticksPerSecond: OutputRig.tps) else { return nil }
            return (FollowerReturnUno(beat: beat, clock: .own, beatsPerBar: beatsPerBar), seconds(at))
        }
    }

    /// A421 · SEGUITO 1 — l'ora dell'«uno» riletta dal battito (`unoTicksQ`): `nil` se la linea propria manca.
    func unoTime(for uno: FollowerReturnUno) -> Double? {
        switch uno.clock {
        case .link:
            return time(ofBeat: uno.beat)
        case .own:
            guard let timeline = ownTimeline,
                  let at = OutputReturnDecision.ownTicks(atBeat: uno.beat, timeline: timeline, ticksPerSecond: OutputRig.tps) else { return nil }
            return seconds(at)
        }
    }

    var externalPresent: Bool { OutputRouteDecision.hasExternal(physicalRoute ?? route) }
    var stoppedByCrisis: Bool { !isRunning && ((crisisCause != nil && !wantedStop) || interrupted) }

    // MARK: - Lo stato e le attese

    mutating func apply(_ event: OutputSilenceEvent) {
        state = OutputRouteDecision.state(after: event, from: state, playerRole: role)
    }

    mutating func cancelReturns() {
        directorReturn = nil
        followerReturn = nil
        // A421 · SEGUITO 2 (par. 4.4): anche il ritorno dopo il buco, la sua riserva e il segno del guardiano.
        gapReturn = nil
        gapVanishedAt = nil
        guardianSilenceChain = nil
    }

    /// A421 · SEGUITO 2 (par. 4.2): ogni arresto e ogni catena nuova spengono il guardiano e tolgono il suo segno.
    mutating func cancelGuardian() {
        guardian = nil
        guardianSilenceChain = nil
    }

    var externalVanishedNow: Bool { state.lastOutputExternal == true && !externalPresent }

    mutating func silenceNow() {
        volume = 0.0
        apply(.silenced)
    }

    mutating func publishIsPlaying() {
        isPlaying = TransportStateDecision.isPlaying(engineRunning: isRunning)
    }

    /// `clearPendingResumeQ`: la ripresa pendente, l'interruzione e il contatore della catena che sale.
    mutating func clearPendingResume() {
        pendingResume = false
        interrupted = false
        resumeToken += 1
    }

    /// La regola di ogni crisi, con la causa ricordata.
    mutating func crisis(_ cause: CrisisCause) -> CrisisStopOutcome {
        let outcome = CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: showOpen,
                                                 songInProgress: songInProgress, engineRunning: isRunning,
                                                 silentInSong: silentInSong)
        if outcome != .nothing {
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: cause, playerRole: role)
            wantedStop = false
        }
        // A421 · SEGUITO 2 (par. 3): il Direttore che entra nel silenzio col motore in moto prende l'àncora come il motore
        // (`takeSilenceAnchorQ`: l'ultimo battito contato già uscito): il primo battito della catena è uscito (al Play il
        // primo buffer porta il battito zero, al fuoco il bersaglio porta l'«uno») o un richiamo ha già portato un battito.
        // Un'àncora tenuta dal rientro torna del silenzio.
        if outcome == .silentInSong {
            let firstBeatOut = firstBeatOutAt.map { now >= $0 } ?? false
            if isRunning && !anchor && (countedBeatOut || firstBeatOut) { anchor = true }
            if anchorHeld { anchorHeld = false }
        }
        return outcome
    }

    /// Un pezzo di buco che il misuratore mette nella base senza contarlo (i richiami di fila del Centro di Controllo): lo scarto
    /// cumulato sale, nessuna riga di buco.
    mutating func absorbedPiece(_ seconds: Double) {
        meterScarto += seconds
    }

    /// L'arresto locale di una crisi sulla coda: lettore e motore, il drenaggio consegnato, lo specchio.
    mutating func crisisStop() {
        isRunning = false
        engineRunning = false
        queued = []
        rejoin = nil
        netAt = nil
        leadInBuffersLeft = 0
        cancelGuardian()
        if drainPending {
            drainPending = false
            drainDelivered += 1
        }
        publishIsPlaying()
    }

    /// A421 · SEGUITO 2 (par. 3): l'àncora si chiude (Stop, show chiuso, cambio di ruolo, avvio, il primo battito del rientro).
    mutating func closeAnchor(at t: Double) {
        if anchor { anchorClosedAt = t }
        anchor = false
        anchorHeld = false
        firstBeatOutAt = nil
    }

    /// La pulizia dello Stop (contatori, cambi armati, drenaggio): anche a motore già fermo (par. 2.2 e).
    mutating func stopCleanup() {
        pendingBPM = nil
        drainPending = false
    }

    /// Lo Stop voluto (`stopSync(.wanted)`): durante un'interruzione chiude la ripresa pendente e alza il contatore della catena.
    mutating func stop(at t: Double) {
        advance(to: t)
        wantedStop = true
        cancelReturns()
        cancelGuardian()
        rejoin = nil
        windowOpen = false
        firstCorrectionPending = false
        closeAnchor(at: t)
        if silentInSong {
            silentInSong = false
            if !isRunning { linkStops += 1 }
        }
        if role == .direttore { apply(.directorStop) }
        if interrupted {
            clearPendingResume()
        }
        if isRunning {
            isRunning = false
            engineRunning = false
            queued = []
            netAt = nil
            if role == .direttore { linkStops += 1 }
        }
        stopCleanup()
        publishIsPlaying()
        playbackStopped = true
    }

    /// Il Solo fermo come allo Stop della console (`stopForSoloCrisis` → `stopSync(.soloCrisis)`).
    mutating func soloStop() {
        soloStops += 1
        cancelReturns()
        cancelGuardian()
        if isRunning {
            isRunning = false
            engineRunning = false
            queued = []
            netAt = nil
        }
        stopCleanup()
        publishIsPlaying()
        playbackStopped = true
    }

    /// L'apertura e la chiusura dello show (`setShowOpen`).
    mutating func openShow(at t: Double) {
        advance(to: t)
        showOpen = true
        // A421 · SEGUITO 2 (E.7): col motore in moto e il volume a 1 la memoria prende l'uscita di adesso.
        apply(.showOpened(playingOutputExternal: (isRunning && !state.muted) ? externalPresent : nil))
    }

    /// A421 · SEGUITO 2 (par. 7): la mappa per il prossimo avvio (`setSongMap`) e le tre strade che abbassano il segno.
    mutating func setSongMap() {
        songMapPending = true
    }

    mutating func followerJoinFired() {
        songMapPending = false
    }

    mutating func closeShow(at t: Double) {
        advance(to: t)
        showOpen = false
        songInProgress = false
        silentInSong = false
        songMapPending = false
        closeAnchor(at: t)
        cancelReturns()
        if isRunning && state.muted && mediaServicesNormal {
            volume = 1.0
            apply(.volumeRestored(externalPresent: externalPresent))
        }
        apply(.showClosed)
    }

    /// Il cambio di percorso: la classe sul thread della notizia, poi il blocco della coda nell'ordine del par. 2.3 a.
    mutating func routeChange(at t: Double, to current: [OutputPort], rateChanges: Bool = false, modeChanges: Bool = false) {
        advance(to: t)
        let previous = route
        route = current
        physicalRoute = nil
        let routeClass = OutputRouteDecision.classify(previous: previous, current: current).routeClass
        if rateChanges { hardwareRate = (hardwareRate == 48_000) ? 44_100 : 48_000 }
        let step = OutputRouteDecision.step(routeClass: routeClass, playerRole: role, showOpen: showOpen,
                                            songInProgress: songInProgress, engineRunning: isRunning,
                                            stoppedByCrisis: stoppedByCrisis, inInterruption: systemInterruption)
        // L'ordine del par. 2.3 a (alla lettera, dopo la verifica del diff): `mediaResetSkipsQ`; il silenzio (U3); lo stato
        // puro «uscita mancante» e, a una tolta, l'annullo dei ritorni (anche nel rimando dentro un'interruzione, che poi
        // esce); la crisi e l'arresto; i ritorni; la ripresa pendente; i rami di oggi. Fra la Lost e la Reset niente, nemmeno
        // lo stato: la tolta persa la rilegge l'avvio del Follower dopo la ricostruzione (la rilettura a ogni avvio, par. 4.3).
        guard mediaServicesNormal else { return }
        if useRouteCrisis && step.silences { silenceNow() }
        if step.raisesMissing { apply(.removed) }
        // A421 · SEGUITO 2 (E.7): col motore in moto e il volume a 1 che resta, la memoria prende l'esterna.
        if step.lowersMissing { apply(.externalPresent(playingAtVolumeOne: isRunning && !state.muted)) }
        if routeClass == .removed { cancelReturns() }
        guard !systemInterruption else { return }
        // Il Solo si ferma sul principale (`stopForSoloCrisis`, mai da audioQueue): dopo il blocco della coda, cioè dopo i
        // rami della frequenza e del modo qui sotto.
        var deferredSoloStop = false
        if useRouteCrisis {
            if let cause = step.crisisCause {
                switch crisis(cause) {
                case .silentInSong:
                    silentInSong = true
                    if isRunning { crisisStop() }
                case .localStop:
                    crisisStop()
                    playbackStopped = true
                case .soloStopAsConsole:
                    deferredSoloStop = true
                case .asToday, .nothing:
                    break
                }
            }
            switch step.armsReturn {
            case .director?:
                if silentInSong && !isRunning {
                    let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: hardwareRate != copyRate)
                    directorReturn = DirectorReturn(wait: wait, fireAt: t + OutputReturnDecision.directorWaitSeconds(wait),
                                                    trigger: .outputAdded, armedAt: t)
                }
            case .follower?:
                // Come il motore: solo col motore in moto e il volume a 0.
                if isRunning && state.muted {
                    followerReturn = FollowerReturn(noticeAt: t, armPending: true, chain: chain, fromTap: false)
                    // A421 · SEGUITO 2 (par. 4.4, «un padrone solo»): come `armFollowerReturnQ`, toglie il ritorno dopo il buco e la riserva.
                    if gapReturn != nil { gapReturnsDroppedForFollower += 1 }
                    gapReturn = nil
                    gapVanishedAt = nil
                }
            case nil:
                break
            }
        }
        // La ripresa pendente che il gestore recupera subito: assorbita dal ritorno del Direttore se questa notizia l'ha
        // armato (una ripartenza sola, dopo l'attesa di U6); se no, la ripresa come oggi, da `RecoveryDecision`.
        if pendingResume {
            pendingResume = false
            let armedNow = directorReturn.map { $0.armedAt >= t } ?? false
            if !armedNow {
                activateSessionAndStart(trigger: .pendingRecovery, at: t)
                if deferredSoloStop { soloStop() }
                return
            }
        }
        // I rami di oggi: la frequenza, il modo. Il ramo del modo annulla i ritorni solo se riparte (par. 2.3 b): a motore già
        // fermo da questa crisi il ritorno del Direttore resta (dopo la verifica del diff).
        if rateChanges {
            if isRunning {
                restartForRateChange(trigger: .sampleRateChange, at: t)
            } else {
                copyRate = hardwareRate
            }
        } else if modeChanges {
            let wasRunning = isRunning
            if crisis(.mode) == .silentInSong { silentInSong = true }
            if isRunning { crisisStop() }
            if wasRunning {
                cancelReturns()
                activateSessionAndStart(trigger: .modeChange, at: t)
            }
        }
        if deferredSoloStop { soloStop() }
    }

    mutating func systemStopsEngine(at t: Double) {
        advance(to: t)
        engineRunning = false
    }

    /// La notifica di configurazione del motore corrente.
    mutating func configurationNotification(at t: Double) {
        advance(to: t)
        let outcome = EngineConfigChangeDecision.outcome(senderIsCurrent: true, stateRunning: isRunning,
                                                         engineRunning: engineRunning,
                                                         audioWorkAllowed: mediaServicesNormal, pendingResume: pendingResume)
        switch outcome {
        case .ignored:
            // Par. 2.2 b: la notifica «ignorato» è il segnale del ritorno che aspetta la configurazione.
            if let waiting = directorReturn, waiting.wait == .configuration {
                fireDirectorReturn(at: t)
            }
        case .recoverPending, .restart:
            if outcome == .recoverPending { pendingResume = false }
            restartForRateChange(trigger: outcome == .recoverPending ? .pendingRecovery : .engineConfigChange, at: t)
        case .notCurrentEngine, .mediaReset:
            break
        }
    }

    /// `restartForRateChangeQ`: l'arresto, gli annulli dei ritorni (par. 2.3 b), la frequenza, la ripartenza.
    mutating func restartForRateChange(trigger: RecoveryTrigger, at t: Double) {
        if crisis(.configuration) == .silentInSong { silentInSong = true }
        crisisStop()
        cancelReturns()
        copyRate = hardwareRate
        activateSessionAndStart(trigger: trigger, at: t)
    }

    /// La rilettura del percorso a un rientro automatico (U5) e, dal seguito 1, a ogni avvio del Follower (par. 4.3).
    mutating func recoveryRead() -> Bool {
        apply(.recoveryRead(externalPresent: externalPresent))
        return state.missing
    }

    /// La ricostruzione del grafo (`rebuildGraph` → `reconnectGraphQ`, A420): ferma il motore di sistema che girava, con
    /// `isRunning` che resta vero (lo riprende la rete del motore fermo).
    mutating func rebuildGraph() {
        rebuilds += 1
        if engineRunning { engineRunning = false }
    }

    /// A421 · SEGUITO 1 (par. 3.2-3.3) — la regola con l'eccezione, e il no.
    func activationAllowed(_ point: InterruptionActivationPoint, token: Int) -> Bool {
        InterruptionActivationDecision.allowsActivation(point: point, systemInterruption: systemInterruption,
                                                        mark: exceptionMark, chainToken: token, beginsCount: beginsCount,
                                                        playerRole: role, silentInSong: silentInSong)
    }

    mutating func refuseActivation() {
        refusals += 1
        switch InterruptionActivationDecision.refusal(playerRole: role, isAudioInterrupted: interrupted,
                                                      wantedStopSinceCrisis: wantedStop) {
        case .nothing:
            break
        case .raisePending:
            pendingResume = true
        case .soloStop:
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: .interruption, playerRole: .solo)
            soloStop()
        }
    }

    /// `activateSessionAndStart`, con le due letture di `RecoveryDecision`, il contatore della catena, i tre punti della regola
    /// del par. 3, i tentativi ogni 0,5 s e la rete a 5 s, le due finestre in cui un inizio d'interruzione passa in mezzo.
    mutating func activateSessionAndStart(trigger: RecoveryTrigger, at t: Double, attempt: Int = 0, token: Int = -1) {
        guard mediaServicesNormal else { return }
        let missing = recoveryRead()
        let first = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                           wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause, outputMissing: missing)
        if first == .noRestart {
            noteNoRestart(trigger: trigger, missing: missing)
            return
        }
        var activeToken = token
        if attempt == 0 {
            resumeToken += 1
            activeToken = resumeToken
            exceptionMark = InterruptionActivationDecision.exceptionMark(trigger: trigger, attempt: attempt,
                                                                         systemInterruption: systemInterruption, playerRole: role,
                                                                         silentInSong: silentInSong, chainToken: activeToken,
                                                                         beginsCount: beginsCount)
            // Punto 1, al tentativo 0: prima di `setCategory`, della preferenza degli avvisi, dei canali, di `isOtherAudioPlaying`.
            guard activationAllowed(.entry, token: activeToken) else {
                refuseActivation()
                return
            }
            sessionWrites += 1
            if hardwareBusy {
                pendingResume = true
                return
            }
        } else if activeToken != resumeToken {
            // La catena morta: come oggi, niente.
            return
        } else {
            // Punto 1, ai tentativi dopo.
            guard activationAllowed(.entry, token: activeToken) else {
                refuseActivation()
                return
            }
        }
        // Il blocco della `setActive` (`audioQueue.async`): un inizio d'interruzione, o uno Stop voluto, può passare in mezzo.
        if injectBeginBeforeSetActive {
            injectBeginBeforeSetActive = false
            interruptionBegan(at: t)
        }
        if injectStopBeforeSetActive {
            injectStopBeforeSetActive = false
            stop(at: t)
        }
        // Punto 2: prima il contatore della catena, poi la regola.
        guard activeToken == resumeToken else {
            deadChainsAtSetActive += 1
            return
        }
        guard activationAllowed(.setActive, token: activeToken) else {
            refuseActivation()
            return
        }
        setActiveAttempts += 1
        if setActiveFailures > 0 {
            setActiveFailures -= 1
            if attempt >= 20 {
                // I tentativi esauriti: la ripresa pendente e la rete a 5 s, con lo stesso contatore della catena.
                pendingResume = true
                safetyNet = RetryWait(fireAt: t + 5.0, trigger: .safetyNet, attempt: 1, token: activeToken)
                return
            }
            retry = RetryWait(fireAt: t + 0.5, trigger: trigger, attempt: attempt + 1, token: activeToken)
            return
        }
        // La setActive riuscita: lo stato giù, la ricostruzione Pro.
        sessionWrites += 1
        interrupted = false
        pendingResume = false
        systemInterruption = false
        if proMode { rebuildGraph() }
        let second = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                            wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause,
                                            outputMissing: recoveryRead())
        if second == .noRestart {
            noteNoRestart(trigger: trigger, missing: state.missing)
            return
        }
        // `start()` in un suo blocco della coda: un inizio d'interruzione può passare in mezzo.
        if injectBeginBeforeStart {
            injectBeginBeforeStart = false
            interruptionBegan(at: t)
        }
        start(at: t, recovery: trigger)
    }

    /// A ogni «niente» per l'uscita mancante (U5): l'interruzione giù se l'hardware è libero, se no la ripresa pendente in piedi;
    /// A421 · SEGUITO 1 (par. 5.2): col Direttore fuori da una canzone il player a «fermo».
    mutating func noteNoRestart(trigger: RecoveryTrigger, missing: Bool) {
        let reason = RecoveryDecision.noRestartReason(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                                      wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause,
                                                      outputMissing: missing)
        guard reason == .outputMissing else { return }
        if role == .direttore && !silentInSong { playbackStopped = true }
        if !systemInterruption && !hardwareBusy {
            interrupted = false
        } else if hardwareBusy {
            pendingResume = true
        }
    }

    /// `start()`: `recovery` è l'innesco tipizzato delle ripartenze automatiche; `nil` è il Play del batterista.
    mutating func start(at t: Double, recovery: RecoveryTrigger?) {
        advance(to: t)
        guard !isRunning else { return }
        if recovery != nil && role == .direttore && recoveryRead() {
            refusedForMissing += 1
            publishIsPlaying()
            return
        }
        // A421 · SEGUITO 1 (par. 3.3, punto 3): per le sole ripartenze automatiche, la regola senza eccezione.
        if recovery != nil && !activationAllowed(.start, token: resumeToken) {
            refuseActivation()
            publishIsPlaying()
            return
        }
        if recovery == nil && role == .direttore {
            apply(.directorPlay(externalPresent: externalPresent))
        }
        // Il Follower senza una sessione che suona: `stayStopped`, prima di `prepareNormalStartQ` (il segno della mappa resta).
        if role == .follower && !followerSessionPlaying {
            publishIsPlaying()
            return
        }
        // `prepareNormalStartQ`: l'avvio che non passa dal coordinatore azzera causa e Stop voluto, consuma il segno della mappa
        // e chiude l'àncora. (Come il motore, `start()` non annulla i ritorni: li annullano le strade che fermano e ripartono.)
        if !(role == .direttore && silentInSong) {
            crisisCause = nil
            wantedStop = false
            if songMapPending {
                songInProgress = true
                songMapPending = false
            }
            closeAnchor(at: t)
        }
        copyRate = hardwareRate
        // Il coordinatore, prima di `engine.start()`: il bersaglio col margine (A421 · SEGUITO 2: max(150 ms, D + 80 ms), letto
        // adesso); senza àncora il conto è «non certo» e l'avvio si ferma qui.
        var target: Double? = nil
        if role == .direttore && silentInSong {
            guard anchor else {
                uncertainRejoins += 1
                publishIsPlaying()
                return
            }
            let marginNow = useFixedMargin ? 0.150 : margin
            target = nextBarTime(atOrAfter: t + marginNow)
        }
        // A421 · SEGUITO 1 (par. 4.3): a ogni avvio del Follower che prosegue, la rilettura del percorso con la memoria.
        if role == .follower { _ = recoveryRead() }
        volume = OutputRouteDecision.volumeForStart(playerRole: role, state: state)
        if volume == 0.0 {
            apply(.silenced)
        } else {
            apply(.volumeRestored(externalPresent: externalPresent))
        }
        engineRunning = true
        isRunning = true
        // `engine.start()` riuscito chiude l'interruzione di sistema (A416 · SEGUITO 2) e — A421 · SEGUITO 1 (par. 3.5) — ogni
        // ripresa in sospeso: il contatore della catena sale sempre.
        systemInterruption = false
        if InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: pendingResume, isAudioInterrupted: interrupted) {
            clearPendingResume()
        } else {
            resumeToken += 1
        }
        chain += 1
        cancelGuardian()
        bufferCount = 0
        meterScarto = 0
        windowOpen = false
        firstCorrectionPending = false
        countedBeatOut = false
        // Il Play parte a beat zero: il primo buffer porta il primo battito, che esce circa una latenza dopo l'avvio.
        firstBeatOutAt = t + latency
        starts += 1
        publishIsPlaying()
        playbackStopped = false
        now = t + engineStartDuration
        if let target {
            armRejoin(targetAt: target, skips: 0)
        } else {
            dspOrigin = 0
            position = 0
            syncSkip = 3
            scheduleNextBuffer(at: now)
            scheduleNextBuffer(at: now)
            scheduleNextBuffer(at: now)
        }
    }

    /// A421 · SEGUITO 2 (par. 2.2 b): se all'armamento adesso più l'anticipo minimo supera l'ora d'uscita meno D, il fuoco sarebbe
    /// in ritardo comunque: si arma per adesso col segno «lettore-lento»; un bersaglio scelto da quel fuoco si arma senza il
    /// controllo.
    mutating func armRejoin(targetAt: Double, skips: Int, fromSlowPlayer: Bool = false) {
        let marginNow = useFixedMargin ? 0.150 : margin
        let slow = useSlowPlayerMark && !fromSlowPlayer
            && DirectorRejoinDecision.slowPlayerAtArming(nowTicks: ticks(now), targetOutputTicks: ticks(targetAt),
                                                         distanceTicks: ticks(firstBufferDistance),
                                                         minLeadTicks: ticks(DirectorRejoinDecision.minLeadSeconds))
        rejoin = RejoinWait(targetAt: targetAt, fireAt: slow ? now : max(targetAt - marginNow, now), skips: skips,
                            slowPlayer: slow, fromSlowPlayer: fromSlowPlayer)
        lastRejoinSkipsLeft = DirectorRejoinDecision.maxLateSkips - skips
    }

    /// Il fuoco del rientro (T5): in ritardo si salta al bersaglio dopo, fino a quattro volte; col segno «lettore-lento» il
    /// coordinatore con lo stesso conto dei salti, senza la guardia. Al fuoco la scorta muta, l'àncora resta tenuta dal rientro.
    mutating func fireRejoin(at t: Double) {
        guard let wait = rejoin, isRunning else { rejoin = nil; return }
        rejoin = nil
        let renderAt = wait.targetAt - (copiesDistance ?? firstBufferDistance)
        if t + DirectorRejoinDecision.minLeadSeconds > renderAt {
            if wait.slowPlayer {
                slowPlayerFires += 1
                armRejoin(targetAt: nextBarTime(atOrAfter: wait.targetAt + 0.5 * 60.0 / bpm), skips: wait.skips, fromSlowPlayer: true)
                return
            }
            lateSkips += 1
            guard wait.skips < DirectorRejoinDecision.maxLateSkips else {
                crisisStop()
                return
            }
            armRejoin(targetAt: nextBarTime(atOrAfter: wait.targetAt + 0.5 * 60.0 / bpm), skips: wait.skips + 1)
            return
        }
        rejoins += 1
        firstClickAt = wait.targetAt
        firstBeatOutAt = wait.targetAt
        silentInSong = false
        followsLink = true
        if useHeldAnchor {
            anchorHeld = anchor
        } else {
            closeAnchor(at: t)
        }
        dspOrigin = linkBeat(at: wait.targetAt)
        // Correzione B3: la finestra «sync skip» è della catena.
        windowOpen = false
        firstCorrectionPending = false
        position = dspOrigin
        chain += 1
        cancelGuardian()
        bufferCount = 0
        meterScarto = 0
        countedBeatOut = false
        leadInBuffersLeft = leadInBuffers
        syncSkip = DirectorRejoinDecision.uncorrectedFireBuffers
        scheduleNextBuffer(at: t)
        scheduleNextBuffer(at: t)
        scheduleNextBuffer(at: t)
    }

    /// A421 · SEGUITO 2 (par. 4.3, 5.1): il cambio di sezione (o di tempo) apre la finestra «sync skip» dei 100 buffer.
    mutating func sectionChange(at t: Double) {
        advance(to: t)
        syncSkip = max(syncSkip, 100)
        if !windowOpen {
            windowOpen = true
            windowRiseBase = meterScarto
            windowProjection = followsLink ? 0 : latency + cycleSeconds
            firstCorrectionPending = false
        }
    }

    /// A421 · SEGUITO 2 (E.9): un cambio di metro.
    mutating func meterChange(to newBeatsPerBar: Int, at t: Double) {
        advance(to: t)
        beatsPerBar = newBeatsPerBar
    }

    var inLeadIn: Bool { leadInBuffersLeft > 0 }
    var skipsCorrectionNow: Bool { syncSkip > 0 }

    /// A421 · SEGUITO 2 (par. 4.2): il guardiano scatta: le condizioni dell'armo, poi il silenzio se il volume è a 1.
    mutating func fireGuardian(at t: Double) {
        guard let armed = guardian else { return }
        guardian = nil
        guard armed.chain == chain, armed.bufferCount == bufferCount, isRunning, !systemInterruption, mediaServicesNormal,
              RenderGapDecision.guardsAgainstHoles(playerRole: role) else { return }
        guard !state.muted else { return }
        silenceNow()
        guardianSilenceChain = chain
        guardianFires += 1
        guardianFiredAt = t
    }

    /// A421 · SEGUITO 2 (par. 4.4): il ritorno dopo il buco si arma (o si riarma da questa chiamata), se nessun'altra strada tiene il volume.
    mutating func armGapReturn(at t: Double, renderNext: Double) {
        if followerReturn != nil {
            rearmFollowerReturn()
            return
        }
        guard !state.missing, state.muted else { return }
        let end = renderNext + 3 * bufferSeconds
        if var waiting = gapReturn {
            waiting.armBufferCount = bufferCount
            waiting.chain = chain
            waiting.programmedEndAt = max(waiting.programmedEndAt, end)
            waiting.armedAt = t
            gapReturn = waiting
        } else {
            gapReturn = GapReturn(armBufferCount: bufferCount, chain: chain, programmedEndAt: end, armedAt: t)
        }
        gapReturnArms += 1
    }

    /// A421 · SEGUITO 2 (par. 4.4): la crisi per l'uscita sparita, dalla riserva di 2 s (il Direttore), o la rilettura di U5 (il Follower).
    mutating func fireGapVanished(at t: Double) {
        gapVanishedAt = nil
        guard var waiting = gapReturn, waiting.vanishedSince != nil else { return }
        // Correzione B2: allo scatto il percorso si rilegge; con l'esterna di nuovo presente il ritorno resta alla sua regola.
        if externalPresent {
            waiting.vanishedSince = nil
            gapReturn = waiting
            gapVanishedBack += 1
            return
        }
        gapReturn = nil
        gapVanishedFired += 1
        switch role {
        case .direttore:
            guard isRunning else { return }
            renderGapCrisis(at: t, reason: .outputVanished)
        case .follower:
            _ = recoveryRead()
        case .solo:
            break
        }
    }

    /// `handleRenderGapCrisisQ`: il silenzio, la crisi «buco-del-render», l'arresto, il ritorno del Direttore (in canzone) o il
    /// player a fermo (fuori da una canzone).
    mutating func renderGapCrisis(at t: Double, reason: RenderGapCrisisReason) {
        silenceNow()
        switch reason {
        case .window: windowCrises += 1
        case .leadIn: leadInCrises += 1
        case .outputVanished: vanishedCrises += 1
        case .hole: break
        }
        let outcome = crisis(.renderGap)
        cancelReturns()
        switch outcome {
        case .silentInSong:
            silentInSong = true
            if isRunning { crisisStop() }
            let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: hardwareRate != copyRate)
            directorReturn = DirectorReturn(wait: wait, fireAt: t + OutputReturnDecision.directorWaitSeconds(wait),
                                            trigger: .renderGap, armedAt: t)
        case .localStop:
            if isRunning { crisisStop() }
            playbackStopped = true
        case .soloStopAsConsole, .asToday, .nothing:
            break
        }
    }

    /// A421 · SEGUITO 1 — il ritorno del Follower si riarma con la stessa regola (`rearmFollowerReturnQ`).
    mutating func rearmFollowerReturn() {
        guard var armed = followerReturn, !armed.armPending else { return }
        armed.armPending = true
        followerReturn = armed
        rearms += 1
    }

    /// `scheduleNextBuffer`: la guardia, il motore di sistema fermo (par. 2.2 a), il drenaggio, il misuratore (U7, U8), il
    /// ritorno del Follower (par. 2.2 c; seguito 1, par. 2.2: le due ore, la rilettura dell'«uno», la guardia del primo
    /// campione, la battuta dopo), l'assert o la correzione (U9), il buffer.
    mutating func scheduleNextBuffer(at t: Double, idealAt: Double? = nil, gapSeconds: Double? = nil, correction: Double? = nil) {
        guard isRunning else { return }
        // A421 · SEGUITO 2 (par. 3.3): l'àncora tenuta dal rientro si chiude quando il primo battito contato del rientro è uscito.
        if anchorHeld, let out = firstBeatOutAt, t >= out {
            closeAnchor(at: t)
        }
        let skipAtCallStart = syncSkip
        if useStoppedEngineCheck && !engineRunning {
            stoppedCallbacks += 1
            if netAt == nil { netAt = t + OutputReturnDecision.stoppedEngineNetSeconds }
            return
        }
        if drainPending {
            drainPending = false
            drainDelivered += 1
            return
        }
        // La convenzione della correzione di fase (l'ora d'uscita di questo buffer: `now + latenza + ciclo`) e l'ora del rendering
        // (`lastRenderTime + ciclo + latenza`, qui l'ora attesa del richiamo più il ciclo e lo scarto): la prima dà il buffer
        // dell'«uno», la seconda le due ore. Un richiamo in ritardo sposta la prima e non la seconda.
        let outputStart = t + latency + cycleSeconds
        let outputEnd = outputStart + bufferSeconds
        let renderNext = (idealAt ?? t) + latency + cycleSeconds + renderOffsetBuffers * bufferSeconds
        // Il misuratore: lo scarto cumulato sale del buco (anche di un pezzo messo nella base).
        if let hole = gapSeconds { meterScarto += hole }
        // A421 · SEGUITO 2 (par. 4.3): la prima chiamata dopo la finestra: la salita contro la soglia, prima della correzione.
        if windowOpen && skipAtCallStart == 0 {
            windowOpen = false
            firstCorrectionPending = true
            if useMeterCrisis, let verdict = RenderGapDecision.windowCloseVerdict(riseSeconds: meterScarto - windowRiseBase, playerRole: role,
                                                                                  showOpen: showOpen, songInProgress: songInProgress,
                                                                                  engineRunning: isRunning, bpm: bpm, bufferFrames: 512,
                                                                                  sampleRate: nodeRate, windowProjectionSeconds: windowProjection) {
                _ = verdict
                renderGapCrisis(at: t, reason: .window)
                return
            }
        }
        if let hole = gapSeconds, useMeterCrisis {
            let guards = RenderGapDecision.guardsAgainstHoles(playerRole: role)
            guardianSilenceChain = nil
            // Par. 4.3: il silenzio prima della lettura del percorso e della decisione, se il guardiano non è arrivato prima.
            if guards && !state.muted { silenceNow() }
            let verdict = RenderGapDecision.verdict(RenderGapDecision.Situation(
                holeSeconds: hole, playerRole: role, showOpen: showOpen, songInProgress: songInProgress, engineRunning: isRunning,
                followsLink: followsLink, inLeadIn: inLeadIn, externalVanished: role == .direttore && externalVanishedNow,
                windowOpen: windowOpen && skipAtCallStart > 0, windowRiseSeconds: windowOpen ? meterScarto - windowRiseBase : nil,
                windowProjectionSeconds: windowProjection, bpm: bpm, bufferFrames: 512, sampleRate: nodeRate,
                projectionSeconds: latency + cycleSeconds))
            switch verdict.outcome {
            case .crisis:
                renderGapCrisis(at: t, reason: verdict.crisisReason ?? .hole)
                return
            case .followLink:
                followsLink = true
            case .lineOnly:
                break
            }
            // Par. 4.4: il ritorno dopo il buco (col ritorno del Follower armato vale quello, col riarmo di A421 · SEGUITO 1).
            if guards { armGapReturn(at: t, renderNext: renderNext) }
        } else if let silenceChain = guardianSilenceChain {
            guardianSilenceChain = nil
            if silenceChain == chain && RenderGapDecision.guardsAgainstHoles(playerRole: role) {
                armGapReturn(at: t, renderNext: renderNext)
            }
        }
        // Par. 2.3 b: un ritorno armato con una catena che non è più quella corrente si riarma con la stessa regola.
        if let armed = followerReturn, !armed.armPending, armed.chain != chain {
            rearmFollowerReturn()
        }
        // Seguito 1, par. 2.2: la rilettura dell'«uno», a ogni chiamata col ritorno armato e un «uno» scelto; seguito 2 (E.9): e il metro.
        if var armed = followerReturn, !armed.armPending, let uno = armed.uno {
            switch OutputReturnDecision.refreshUno(saved: uno, clockNow: followerClock, beatsPerBarNow: beatsPerBar,
                                                   rereadTicks: unoTime(for: uno).map(ticks)) {
            case .rearm:
                rearmFollowerReturn()
            case .ticks(let at):
                armed.unoAt = seconds(at)
                followerReturn = armed
            }
        }
        // Seguito 2 (E.8, par. 4.4): la parte dei buffer della scadenza del Follower si rilegge e non scende.
        if var armed = followerReturn, !armed.armPending {
            let endNow = renderNext + 3 * bufferSeconds
            let endAtArm = max(armed.programmedEndAt, endNow - Double(bufferCount - armed.armBufferCount) * bufferSeconds)
            if endAtArm > armed.programmedEndAt + 1e-9 {
                armed.programmedEndAt = endAtArm
                armed.deadlineAt = seconds(OutputReturnDecision.followerDeadlineTicks(noticeTicks: ticks(armed.noticeAt),
                                                                                       programmedEndOutputTicks: ticks(endAtArm),
                                                                                       ticksPerSecond: OutputRig.tps))
                followerReturn = armed
                deadlineAt = armed.deadlineAt
                programmedEndAt = endAtArm
            }
        }
        if var pending = followerReturn, pending.armPending {
            let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: ticks(renderNext),
                                                                    queuedAhead: OutputReturnDecision.queuedAheadBuffers,
                                                                    bufferTicks: ticks(bufferSeconds))
            let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: ticks(pending.noticeAt), programmedEndOutputTicks: end,
                                                                      ticksPerSecond: OutputRig.tps)
            let next = nextUno(atOrAfter: seconds(deadline))
            // Seguito 2 (E.1): senza un «uno» calcolabile resta prenotato, fino a una battuta dopo la scadenza del primo tentativo.
            var armsWithoutUno = false
            if next == nil {
                let firstDeadline = pending.noUnoDeadline ?? seconds(deadline)
                pending.noUnoDeadline = firstDeadline
                if !OutputReturnDecision.noUnoLimitReached(nowTicks: ticks(t), deadlineTicks: ticks(firstDeadline),
                                                           barTicks: ticks(Double(beatsPerBar) * 60.0 / bpm)) {
                    followerReturn = pending
                } else {
                    armsWithoutUno = true
                }
            }
            if next != nil || armsWithoutUno {
                pending.deadlineAt = seconds(deadline)
                pending.uno = next?.uno
                pending.unoAt = next?.at
                pending.armPending = false
                pending.chain = chain
                pending.armBufferCount = bufferCount
                pending.programmedEndAt = seconds(end)
                pending.noUnoDeadline = nil
                followerReturn = pending
                deadlineAt = pending.deadlineAt
                programmedEndAt = seconds(end)
                armedUnoAt = next?.at
            }
        }
        // DA-SOLO: la linea propria si ri-àncora al buffer dopo il cambio di tempo (`ownClockPinQ`), fra l'armo e la guardia.
        if ownRepinPending && followerClock == .own {
            ownRepinPending = false
            let beatNow = ownBeatAtChange + (t - ownChangeTime) * ownTimelineBPM / 60.0
            ownTimeline = OwnClockTimeline(anchorTicks: ticks(t), anchorBeat: beatNow, bpm: ownTimelineBPM)
        }
        // La finestra «sync skip»: il contatore scende; la correzione di fase non gira.
        if syncSkip > 0 { syncSkip -= 1 }
        let skipsCorrection = skipAtCallStart > 0
        // U3 c e la guardia del primo campione (seguito 1, par. 2.2): se questo buffer porta l'«uno», il volume torna ADESSO, se
        // le condizioni reggono e il primo campione a volume 1 non è prima della scadenza; se no la battuta dopo. Senza un
        // «uno» calcolabile, alla prima chiamata col primo campione alla scadenza o dopo. Seguito 2 (F1): mai in una chiamata
        // che salta la correzione.
        if var pending = followerReturn, !pending.armPending, let deadline = pending.deadlineAt {
            let firstSample = seconds(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: ticks(renderNext),
                                                                                      cycleTicks: ticks(cycleSeconds),
                                                                                      fallbackRead: fallbackRead))
            let step = OutputReturnDecision.followerReturnStep(bufferOutputTicks: ticks(outputStart), bufferTicks: ticks(bufferSeconds),
                                                               unoTicks: pending.unoAt.map(ticks), deadlineTicks: ticks(deadline),
                                                               firstSampleTicks: ticks(firstSample), skipsCorrection: skipsCorrection)
            let conditions = isRunning && !systemInterruption && !state.missing && state.muted && mediaServicesNormal
            switch step {
            case .wait:
                break
            case .nextBar, .nextBarInWindow:
                if !conditions {
                    followerReturn = nil
                } else if let uno = pending.uno, let next = OutputReturnDecision.nextBarUno(uno) {
                    pending.uno = next
                    pending.unoAt = unoTime(for: next)
                    if pending.unoAt == nil { pending.armPending = true }
                    followerReturn = pending
                    nextBarMoves += 1
                }
            case .restore:
                followerReturn = nil
                if conditions {
                    volume = 1.0
                    apply(.volumeRestored(externalPresent: externalPresent))
                    raisedAt = t
                    firstSampleAt = firstSample
                    restoredUnoAt = pending.unoAt
                }
            }
        }
        // Seguito 2 (par. 4.4): il ritorno dopo il buco: la scadenza riletta, il primo campione, l'esterna sparita.
        if var waiting = gapReturn {
            if waiting.chain != chain {
                gapReturn = nil
                gapVanishedAt = nil
            } else {
                let endNow = renderNext + 3 * bufferSeconds
                waiting.programmedEndAt = max(waiting.programmedEndAt, endNow - Double(bufferCount - waiting.armBufferCount) * bufferSeconds)
                gapReturn = waiting
                let conditions = isRunning && !systemInterruption && !state.missing && state.muted && mediaServicesNormal
                if !conditions {
                    gapReturn = nil
                    gapVanishedAt = nil
                } else {
                    let firstSample = seconds(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: ticks(renderNext),
                                                                                              cycleTicks: ticks(cycleSeconds),
                                                                                              fallbackRead: fallbackRead))
                    let deadline = waiting.programmedEndAt + OutputReturnDecision.clickTailSeconds
                    let wouldReturn = !skipsCorrection && firstSample >= deadline - 1e-9
                    // Correzione B2: con la riserva in corsa il percorso si rilegge a ogni chiamata.
                    if waiting.vanishedSince != nil, externalPresent {
                        waiting.vanishedSince = nil
                        gapReturn = waiting
                        gapVanishedAt = nil
                        gapVanishedBack += 1
                    }
                    let vanished = wouldReturn && externalVanishedNow
                    switch OutputReturnDecision.gapReturnStep(firstSampleTicks: ticks(firstSample), deadlineTicks: ticks(deadline),
                                                              skipsCorrection: skipsCorrection, externalVanished: vanished) {
                    case .wait:
                        break
                    case .externalVanished:
                        if waiting.vanishedSince == nil {
                            waiting.vanishedSince = t
                            gapReturn = waiting
                            gapVanishedAt = t + OutputReturnDecision.configurationReserveSeconds
                            gapVanishedWaits += 1
                        }
                    case .restore:
                        gapReturn = nil
                        gapVanishedAt = nil
                        volume = 1.0
                        apply(.volumeRestored(externalPresent: externalPresent))
                        gapReturnRestores += 1
                        gapRestoredAt = t
                        gapFirstSampleAt = firstSample
                        gapDeadlineAt = deadline
                    }
                }
            }
        }
        var mutedThisBuffer = false
        if skipsCorrection {
            // La finestra: né assert né correzione.
        } else if role == .direttore && !followsLink {
            asserts += 1
        } else if let delta = correction {
            corrections += 1
            if LateBeatDecision.mutes(origin: dspOrigin, before: position, after: position + delta, bpm: bpm,
                                      bufferFrames: 512, sampleRate: nodeRate) {
                lateBeatsMuted += 1
                mutedThisBuffer = true
            }
            // Seguito 2 (F1): la prima correzione dopo la finestra che sposta di almeno un buffer riarma i ritorni.
            if firstCorrectionPending {
                firstCorrectionPending = false
                if OutputReturnDecision.correctionMovesAtLeastABuffer(beforeBeat: position, afterBeat: position + delta, bpm: bpm,
                                                                      bufferSeconds: bufferSeconds) {
                    firstCorrectionRearms += 1
                    rearmFollowerReturn()
                    if gapReturn != nil { armGapReturn(at: t, renderNext: renderNext) }
                }
            }
            position += delta
        } else if firstCorrectionPending && (role != .direttore || followsLink) {
            // La prima chiamata dopo la finestra senza una correzione: il segno si consuma.
            firstCorrectionPending = false
        }
        if leadInBuffersLeft > 0 { leadInBuffersLeft -= 1 }
        let beatInBuffer = (position + bufferBeats - dspOrigin).rounded(.down) > (position - dspOrigin).rounded(.down)
            || mutedThisBuffer
        if beatInBuffer && !mutedThisBuffer {
            clickSamplesWritten += 1
        }
        if beatInBuffer { countedBeatOut = true }
        position += bufferBeats
        bufferCount += 1
        queued.append(RigBuffer(outputStart: outputStart, outputEnd: outputEnd, chain: chain))
        if queued.count > 3 { queued.removeFirst() }
        // Seguito 2 (par. 4.2): il guardiano, a ogni chiamata che programma, col misuratore in regime (dalla quarta chiamata
        // della catena, con la base presente: non alla chiamata del buco): quattro buffer dall'ultima chiamata.
        if useGuardian && RenderGapDecision.guardsAgainstHoles(playerRole: role) && bufferCount >= 4 && gapSeconds == nil {
            guardian = GuardianArm(chain: chain, bufferCount: bufferCount, dueAt: t + 4 * bufferSeconds)
        } else {
            guardian = nil
        }
    }

    /// I richiami a ogni buffer, da `from`, `count` volte; `late`: ogni secondo richiamo in ritardo di tanti buffer (l'ora del
    /// rendering resta quella attesa).
    mutating func callbacks(from: Double, count: Int, correction: Double? = nil, late: Double = 0.0) {
        for i in 0..<count {
            let ideal = from + Double(i) * bufferSeconds
            let t = ideal + (i % 2 == 1 ? late * bufferSeconds : 0.0)
            advance(to: t)
            scheduleNextBuffer(at: t, idealAt: ideal, correction: correction)
        }
    }

    mutating func fireDirectorReturn(at t: Double) {
        guard let waiting = directorReturn else { return }
        directorReturn = nil
        guard !isRunning, !systemInterruption, silentInSong, !state.missing else { return }
        activateSessionAndStart(trigger: waiting.trigger, at: t)
    }

    mutating func fireNet(at t: Double) {
        netAt = nil
        netFired += 1
        guard isRunning, !engineRunning else { return }
        let outcome = EngineConfigChangeDecision.outcome(senderIsCurrent: true, stateRunning: isRunning,
                                                         engineRunning: engineRunning,
                                                         audioWorkAllowed: mediaServicesNormal, pendingResume: pendingResume)
        switch outcome {
        case .recoverPending, .restart:
            pendingResume = false
            restartForRateChange(trigger: .engineStoppedBySystem, at: t)
        case .ignored, .mediaReset, .notCurrentEngine:
            break
        }
    }

    /// Il tentativo ogni 0,5 s e la rete a 5 s (par. 3): la rete rientra solo con la ripresa pendente e lo stesso contatore.
    mutating func fireRetry(_ wait: RetryWait, at t: Double) {
        activateSessionAndStart(trigger: wait.trigger, at: t, attempt: wait.attempt, token: wait.token)
    }

    mutating func fireSafetyNet(_ wait: RetryWait, at t: Double) {
        guard pendingResume, resumeToken == wait.token else {
            safetyNetSkipped += 1
            return
        }
        safetyNetFired += 1
        pendingResume = false
        activateSessionAndStart(trigger: .safetyNet, at: t, attempt: 1, token: wait.token)
    }

    /// Il tempo passa fino a `t`: le attese scadute scattano nell'ordine.
    mutating func advance(to t: Double) {
        guard t > now else { return }
        while true {
            var due: [(Double, Int)] = []
            if let d = directorReturn, d.fireAt <= t { due.append((d.fireAt, 0)) }
            if let n = netAt, n <= t { due.append((n, 2)) }
            if let j = rejoin, j.fireAt <= t { due.append((j.fireAt, 3)) }
            if let r = retry, r.fireAt <= t { due.append((r.fireAt, 4)) }
            if let s = safetyNet, s.fireAt <= t { due.append((s.fireAt, 5)) }
            // A421 · SEGUITO 2: il guardiano e la riserva dell'esterna sparita.
            if let g = guardian, g.dueAt <= t { due.append((g.dueAt, 6)) }
            if let v = gapVanishedAt, v <= t { due.append((v, 7)) }
            guard let next = due.min(by: { $0.0 < $1.0 }) else { break }
            now = max(now, next.0)
            switch next.1 {
            case 0: fireDirectorReturn(at: next.0)
            case 2: fireNet(at: next.0)
            case 3: fireRejoin(at: next.0)
            case 4:
                let wait = retry!
                retry = nil
                fireRetry(wait, at: next.0)
            case 6: fireGuardian(at: next.0)
            case 7: fireGapVanished(at: next.0)
            default:
                let wait = safetyNet!
                safetyNet = nil
                fireSafetyNet(wait, at: next.0)
            }
        }
        now = t
    }

    // MARK: - Interruzioni, servizi, ruolo, tocco, risveglio, orologi

    mutating func interruptionBegan(at t: Double) {
        advance(to: t)
        systemInterruption = true
        beginsCount += 1
        cancelReturns()
        // Seguito 1, par. 3.3: il Solo con la ripresa pendente già alzata dalla sua catena la perde e si ferma come allo Stop.
        // Seguito 2 (par. 6): m2, già fermo per uno Stop voluto perde solo la ripresa; m4, a motore fermo senza ripresa chiude la
        // catena e ricorda «interruzione», e si ferma solo con una ripartenza in corso.
        switch InterruptionActivationDecision.soloAtInterruptionBegin(playerRole: role, engineRunning: isRunning, pendingResume: pendingResume,
                                                                      wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause) {
        case .nothing:
            break
        case .clearPendingOnly:
            clearPendingResume()
            return
        case .clearPendingAndStop:
            clearPendingResume()
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: .interruption, playerRole: .solo)
            soloStop()
            return
        case .closeChainAndRemember(let stop):
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: .interruption, playerRole: .solo)
            resumeToken += 1
            chainsClosedAtBegin += 1
            if stop { soloStop() }
            return
        }
        switch crisis(.interruption) {
        case .soloStopAsConsole:
            soloStop()
            return
        case .silentInSong where !isRunning:
            interrupted = true
            rejoin = nil
            return
        case .silentInSong:
            silentInSong = true
        case .localStop, .asToday, .nothing:
            break
        }
        guard isRunning else { return }
        interrupted = true
        crisisStop()
    }

    /// La fine dell'interruzione: la ripresa pendente, la guardia, l'hardware occupato, la ricostruzione del grafo e la ripartenza.
    mutating func interruptionEnded(at t: Double, hardwareBusy busy: Bool = false) {
        advance(to: t)
        systemInterruption = false
        hardwareBusy = busy
        if pendingResume {
            pendingResume = false
            activateSessionAndStart(trigger: .pendingRecovery, at: t)
            return
        }
        guard interrupted else { return }
        if busy {
            pendingResume = true
            return
        }
        rebuildGraph()
        activateSessionAndStart(trigger: .interruptionEnded, at: t)
    }

    mutating func servicesLost(at t: Double) {
        advance(to: t)
        mediaServicesNormal = false
        cancelReturns()
        switch crisis(.servicesLost) {
        case .silentInSong:
            silentInSong = true
            if isRunning { crisisStop() }
        case .localStop:
            crisisStop()
        case .soloStopAsConsole:
            soloStop()
        case .asToday, .nothing:
            break
        }
        pendingResume = false
        interrupted = false
    }

    /// La ricostruzione al Play dopo il reset (la rilettura del Follower la fa `start()`, a ogni avvio: par. 4.3).
    mutating func rebuiltAndPlay(at t: Double) {
        mediaServicesNormal = true
        isRunning = false
        engineRunning = false
        start(at: t, recovery: nil)
    }

    mutating func roleChange(to newRole: PlayerRole, at t: Double) {
        advance(to: t)
        cancelReturns()
        songMapPending = false
        closeAnchor(at: t)
        if isRunning && state.muted {
            isRunning = false
            engineRunning = false
            queued = []
            rejoin = nil
            wantedStop = true
            stopCleanup()
            publishIsPlaying()
            playbackStopped = true
        }
        apply(.roleChange)
        silentInSong = false
        followsLink = false
        role = newRole
    }

    mutating func speakerTap(at t: Double) {
        advance(to: t)
        guard role == .follower else { return }
        apply(.speakerTap)
        // Sul motore morto (fra la Lost e la Reset) solo lo stato: il volume lo riscrive `start()` dopo il reset (A408).
        if isRunning && state.muted && mediaServicesNormal {
            followerReturn = FollowerReturn(noticeAt: t, armPending: true, chain: chain, fromTap: true)
            // A421 · SEGUITO 2 (par. 4.4, «un padrone solo»): come `armFollowerReturnQ`, toglie il ritorno dopo il buco e la riserva.
            if gapReturn != nil { gapReturnsDroppedForFollower += 1 }
            gapReturn = nil
            gapVanishedAt = nil
        }
    }

    mutating func wakeup(at t: Double) {
        advance(to: t)
        guard TransportStateDecision.wakeupRecovers(engineRunning: isRunning, pendingResume: pendingResume,
                                                    silentInSong: silentInSong) else { return }
        if pendingResume {
            pendingResume = false
            activateSessionAndStart(trigger: .wakeupPendingRecovery, at: t)
        } else {
            activateSessionAndStart(trigger: .appWakeup, at: t)
        }
    }

    /// Il pedale playPause fuori dal silenzio del Direttore: `isPlaying ? stop() : start()`.
    mutating func pedalPlayPause(at t: Double) {
        if isPlaying { stop(at: t) } else { start(at: t, recovery: nil) }
    }

    /// Un cambio di tempo della sessione Link: la linea si ri-àncora qui, i battiti restano dove sono.
    mutating func linkTempoChange(to newBPM: Double, at t: Double) {
        advance(to: t)
        linkAnchorBeat = linkBeat(at: t)
        linkAnchorTime = t
        bpm = newBPM
    }

    /// La soglia di DA SOLO: il Follower passa alla linea propria, ancorata qui sulla griglia di Link, con l'ultimo «uno».
    mutating func goOwnClock(at t: Double) {
        advance(to: t)
        followerClock = .own
        ownTimelineBPM = bpm
        let beat = linkBeat(at: t)
        ownTimeline = OwnClockTimeline(anchorTicks: ticks(t), anchorBeat: beat, bpm: bpm)
        lastUnoBeat = (beat / Double(beatsPerBar)).rounded(.down) * Double(beatsPerBar)
    }

    /// Un cambio di tempo della sezione DA-SOLO: la linea propria si butta e si ri-àncora al buffer dopo.
    mutating func ownSectionTempoChange(to newBPM: Double, at t: Double) {
        advance(to: t)
        if let timeline = ownTimeline {
            ownBeatAtChange = timeline.beat(atTicks: ticks(t), ticksPerSecond: OutputRig.tps)
        }
        ownChangeTime = t
        ownTimelineBPM = newBPM
        ownTimeline = nil
        ownRepinPending = true
    }
}

final class OutputCrisisSequenceTests: XCTestCase {

    private let speaker = OutputPort(type: "Speaker", uid: "Speaker")
    private let headphones = OutputPort(type: "Headphones", uid: "Wired Headphones")
    private let bluetooth = OutputPort(type: "BluetoothA2DPOutput", uid: "00:11:22:33:44:55-tacl")
    private let usb = OutputPort(type: "USBAudio", uid: "AppleUSBAudioEngine:Focusrite")
    private let usb2 = OutputPort(type: "USBAudio", uid: "AppleUSBAudioEngine:Behringer")

    /// Un rig col click in moto in canzone, sul percorso dato.
    private func playing(_ role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4,
                         at t: Double = 10.0, cycleSeconds: Double = 512.0 / 48_000.0, renderOffsetBuffers: Double = 0.0,
                         fallbackRead: Bool = false, guardian: Bool = false, nodeRate: Double = 48_000.0) -> OutputRig {
        var rig = OutputRig(role: role, route: route, bpm: bpm, beatsPerBar: beatsPerBar, cycleSeconds: cycleSeconds,
                            renderOffsetBuffers: renderOffsetBuffers, fallbackRead: fallbackRead)
        rig.useGuardian = guardian
        rig.nodeRate = nodeRate
        rig.start(at: t, recovery: nil)
        rig.callbacks(from: t + rig.bufferSeconds, count: 50)
        return rig
    }

    /// L'invariante del par. 2.3: nessun campione a volume 1 prima della scadenza, e senza buchi né cambi d'orologio il ritorno
    /// al più una battuta dopo l'«uno» scelto all'armo.
    private func checkReturnInvariants(_ rig: OutputRig, _ tag: String, oneBarAtMost: Bool = true,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(rig.volume, 1.0, "il volume non e' tornato: \(tag)", file: file, line: line)
        guard let first = rig.firstSampleAt, let deadline = rig.deadlineAt else {
            XCTFail("nessun ritorno registrato: \(tag)", file: file, line: line)
            return
        }
        XCTAssertGreaterThanOrEqual(first, deadline - 1e-9, "primo campione a volume 1 prima della scadenza: \(tag)", file: file, line: line)
        if let end = rig.programmedEndAt {
            XCTAssertGreaterThanOrEqual(first, end + 0.040 - 1e-9, "i buffer programmati non sono usciti: \(tag)", file: file, line: line)
        }
        if oneBarAtMost, let armed = rig.armedUnoAt, let restored = rig.restoredUnoAt {
            XCTAssertLessThanOrEqual(restored, armed + rig.barSeconds + 1e-6, "piu' di una battuta dopo l'uno dell'armo: \(tag)",
                                     file: file, line: line)
            XCTAssertGreaterThanOrEqual(restored, armed - 1e-6, "prima dell'uno dell'armo: \(tag)", file: file, line: line)
        }
    }

    // MARK: - Le sequenze del 24/10 (par. 4, punti 1-4)

    /// (1) Il Direttore con la cassa Bluetooth, registro delle 12:37 (6/8 a 101): la notizia alle 22.364 (la frequenza della
    /// sessione già diversa: si aspetta la configurazione), il sistema ferma il motore alle 23.005, il richiamo tardivo alle
    /// 23.016 non programma niente e non fa l'assert, la notifica alle 23.120 («ignorato») è il segnale del ritorno: un
    /// rientro solo, a una battuta, mai un assert.
    func testTheDirectorWithTheBluetoothSpeakerAt123522() {
        var rig = playing(.direttore, route: [speaker], bpm: 101, beatsPerBar: 6, at: 20.0)
        let assertsBefore = rig.asserts
        rig.routeChange(at: 22.364, to: [bluetooth], rateChanges: true)
        XCTAssertFalse(rig.isRunning)
        XCTAssertTrue(rig.silentInSong)
        XCTAssertEqual(rig.volume, 0.0)
        XCTAssertEqual(rig.directorReturn?.wait, .configuration)
        XCTAssertFalse(rig.isPlaying)
        rig.systemStopsEngine(at: 23.005)
        rig.advance(to: 23.016)
        rig.scheduleNextBuffer(at: 23.016, gapSeconds: 0.9061)
        XCTAssertEqual(rig.asserts, assertsBefore, "nessun assert dopo il buco")
        XCTAssertTrue(rig.queued.isEmpty)
        rig.configurationNotification(at: 23.120)
        XCTAssertNil(rig.directorReturn, "la notifica ignorata ha fatto scattare il ritorno")
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.starts, 2)
        rig.advance(to: 30.0)
        XCTAssertEqual(rig.rejoins, 1, "un ritorno solo")
        XCTAssertEqual(rig.asserts, assertsBefore)
        let bars = rig.firstClickAt! / (6 * 60.0 / 101.0)
        XCTAssertEqual(bars, bars.rounded(), accuracy: 1e-6, "a una battuta")
        XCTAssertGreaterThanOrEqual(rig.firstClickAt!, 23.120 + 0.150)
        XCTAssertTrue(rig.followsLink)
        XCTAssertTrue(rig.isPlaying)
    }

    /// Ogni difesa da sola ferma l'assert del 24/10: la notizia (U1), il motore di sistema fermo (par. 2.2 a, con la rete a
    /// 2 s se nessun gestore arriva), il misuratore a 75 ms (U7).
    func testEachDefenseAloneStopsTheAssert() {
        // Solo la notizia.
        var byNotice = playing(.direttore, route: [speaker], bpm: 101, beatsPerBar: 6, at: 20.0)
        byNotice.useStoppedEngineCheck = false
        byNotice.useMeterCrisis = false
        let a1 = byNotice.asserts
        byNotice.routeChange(at: 22.364, to: [bluetooth], rateChanges: true)
        byNotice.systemStopsEngine(at: 23.005)
        byNotice.advance(to: 23.016)
        byNotice.scheduleNextBuffer(at: 23.016, gapSeconds: 0.9061)
        XCTAssertEqual(byNotice.asserts, a1)
        byNotice.configurationNotification(at: 23.120)
        byNotice.advance(to: 30.0)
        XCTAssertEqual(byNotice.rejoins, 1)
        // Solo il motore di sistema fermo: la notizia non fa niente (classe «nessuna»), il misuratore spento.
        var byEngine = playing(.direttore, route: [speaker], bpm: 101, beatsPerBar: 6, at: 20.0)
        byEngine.useRouteCrisis = false
        byEngine.useMeterCrisis = false
        let a2 = byEngine.asserts
        byEngine.systemStopsEngine(at: 23.005)
        byEngine.advance(to: 23.016)
        byEngine.scheduleNextBuffer(at: 23.016, gapSeconds: 0.9061)
        XCTAssertEqual(byEngine.asserts, a2, "il richiamo tardivo non programma niente")
        XCTAssertEqual(byEngine.stoppedCallbacks, 1)
        XCTAssertEqual(byEngine.netAt!, 25.016, accuracy: 1e-9)
        // Nessun gestore arriva: la rete riparte usando la decisione della configurazione.
        byEngine.advance(to: 25.5)
        XCTAssertEqual(byEngine.netFired, 1)
        XCTAssertEqual(byEngine.starts, 2)
        XCTAssertTrue(byEngine.isRunning)
        XCTAssertEqual(byEngine.asserts, a2)
        // Solo il misuratore.
        var byMeter = playing(.direttore, route: [speaker], bpm: 101, beatsPerBar: 6, at: 20.0)
        byMeter.useRouteCrisis = false
        byMeter.useStoppedEngineCheck = false
        let a3 = byMeter.asserts
        byMeter.advance(to: 23.016)
        byMeter.scheduleNextBuffer(at: 23.016, gapSeconds: 0.9061)
        XCTAssertEqual(byMeter.asserts, a3, "la crisi da misuratore esce prima dell'assert")
        XCTAssertFalse(byMeter.isRunning)
        XCTAssertTrue(byMeter.silentInSong)
        XCTAssertEqual(byMeter.directorReturn?.trigger, .renderGap)
        XCTAssertEqual(byMeter.directorReturn!.fireAt, 23.116, accuracy: 1e-9)
        byMeter.advance(to: 30.0)
        XCTAssertEqual(byMeter.rejoins, 1)
        XCTAssertEqual(byMeter.asserts, a3)
    }

    /// La rete del motore fermo (par. 2.2 a) coi servizi audio persi: niente lavoro sul grafo; con una ripresa pendente: il
    /// suo innesco, e la ripresa pendente tolta.
    func testTheNetWithServicesLostAndWithAPendingResume() {
        var lost = playing(.follower, route: [speaker])
        lost.useRouteCrisis = false
        lost.systemStopsEngine(at: 11.0)
        lost.scheduleNextBuffer(at: 11.01)
        XCTAssertNotNil(lost.netAt)
        lost.mediaServicesNormal = false
        lost.advance(to: 13.5)
        XCTAssertEqual(lost.netFired, 1)
        XCTAssertEqual(lost.starts, 1, "niente ripartenza sul motore morto")
        var pending = playing(.follower, route: [speaker])
        pending.systemStopsEngine(at: 11.0)
        pending.scheduleNextBuffer(at: 11.01)
        pending.pendingResume = true
        pending.advance(to: 13.5)
        XCTAssertEqual(pending.netFired, 1)
        XCTAssertEqual(pending.starts, 2)
        XCTAssertFalse(pending.pendingResume)
        XCTAssertTrue(pending.isRunning)
    }

    /// (2) La cassa nel Solo delle 14:32:44: la notizia non fa niente (par. 2.2 f), il sistema ferma il motore alle .571, il
    /// richiamo delle .581 non programma niente (la rete si arma), la configurazione delle .687 riparte come oggi e la rete
    /// non ha più niente da fare.
    func testTheSpeakerInTheSoloAt143244() {
        var rig = playing(.solo, route: [speaker], at: 40.0)
        rig.routeChange(at: 44.555, to: [bluetooth], rateChanges: false)
        XCTAssertTrue(rig.isRunning, "nel Solo un'uscita che compare resta come oggi")
        XCTAssertEqual(rig.volume, 1.0)
        rig.hardwareRate = 44_100
        rig.systemStopsEngine(at: 44.571)
        rig.advance(to: 44.581)
        rig.scheduleNextBuffer(at: 44.581, gapSeconds: 0.2545)
        XCTAssertEqual(rig.stoppedCallbacks, 1)
        XCTAssertNotNil(rig.netAt)
        rig.configurationNotification(at: 44.687)
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.starts, 2, "la ripartenza come oggi")
        XCTAssertNil(rig.netAt, "la ripartenza toglie la rete")
        rig.advance(to: 47.0)
        XCTAssertEqual(rig.netFired, 0)
        XCTAssertEqual(rig.starts, 2)
    }

    /// (3) Le cuffie col filo col render che riparte 681 ms dopo la notizia, sul Direttore: la tolta ferma e alza «uscita
    /// mancante», i richiami tardivi non fanno niente; l'attacco dopo rimette la battuta col ritorno dopo 100 ms.
    func testWiredHeadphonesWithTheRenderRestarting681msLaterOnTheDirector() {
        var rig = playing(.direttore, route: [headphones], at: 50.0)
        let a = rig.asserts
        rig.routeChange(at: 55.0, to: [speaker])
        XCTAssertFalse(rig.isRunning)
        XCTAssertTrue(rig.state.missing)
        XCTAssertTrue(rig.silentInSong)
        XCTAssertFalse(rig.isPlaying)
        rig.callbacks(from: 55.681, count: 3)
        XCTAssertEqual(rig.asserts, a)
        // Una ripartenza automatica (la fine di un'interruzione) non riparte: l'uscita manca.
        rig.activateSessionAndStart(trigger: .interruptionEnded, at: 57.0)
        XCTAssertFalse(rig.isRunning)
        rig.routeChange(at: 60.0, to: [headphones])
        XCTAssertFalse(rig.state.missing)
        XCTAssertEqual(rig.directorReturn?.wait, .settle)
        XCTAssertEqual(rig.directorReturn!.fireAt, 60.1, accuracy: 1e-9)
        rig.advance(to: 63.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.asserts, a)
        XCTAssertGreaterThanOrEqual(rig.firstClickAt!, 60.1 + 0.150)
    }

    /// (3) Lo stesso sul Follower: il volume a 0 col motore in moto, i richiami tardivi a volume 0, poi l'attacco; il render
    /// riparte 684 ms dopo: il volume torna al primo «uno» di Link dopo le due ore, al calcolo del suo buffer (U3 c), col
    /// primo campione a volume 1 alla scadenza o dopo (seguito 1, par. 2.2).
    func testWiredHeadphonesWithTheRenderRestarting684msLaterOnTheFollower() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.routeChange(at: 55.0, to: [speaker])
        XCTAssertTrue(rig.isRunning)
        XCTAssertTrue(rig.isPlaying, "il Follower muto ha il motore in moto")
        XCTAssertEqual(rig.volume, 0.0)
        XCTAssertTrue(rig.state.missing)
        rig.callbacks(from: 55.681, count: 30)
        XCTAssertEqual(rig.volume, 0.0)
        rig.routeChange(at: 58.806, to: [headphones])
        XCTAssertEqual(rig.volume, 0.0)
        XCTAssertFalse(rig.state.missing)
        XCTAssertTrue(rig.followerReturn!.armPending)
        rig.callbacks(from: 58.806 + 0.684, count: 1)
        let uno = rig.followerReturn!.unoAt!
        let firstCall = 58.806 + 0.684
        let deadline = firstCall + rig.latency + rig.cycleSeconds + 3 * rig.bufferSeconds + 0.040
        XCTAssertGreaterThan(deadline, 58.806 + 0.3, "vince la fine dei buffer programmati")
        XCTAssertEqual(rig.deadlineAt!, deadline, accuracy: 1e-6)
        XCTAssertGreaterThanOrEqual(uno, deadline)
        let bars = uno / (4 * 60.0 / 121.0)
        XCTAssertEqual(bars, bars.rounded(), accuracy: 1e-6, "un «uno» di battuta di Link")
        XCTAssertEqual(rig.followerReturn!.uno!.clock, .link)
        rig.callbacks(from: firstCall + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertNotNil(rig.raisedAt)
        XCTAssertLessThanOrEqual(rig.raisedAt!, uno - rig.latency - rig.bufferSeconds + 1e-9,
                                 "al calcolo del buffer dell'«uno», prima del suo rendering (U3 c)")
        XCTAssertGreaterThanOrEqual(rig.raisedAt!, uno - rig.latency - 2 * rig.bufferSeconds - 1e-9)
        XCTAssertNil(rig.followerReturn)
        checkReturnInvariants(rig, "684 ms")
    }

    /// (3) Nel Solo la tolta ferma come allo Stop («Resume from», pulizia, `isPlaying` falso); l'uscita che compare resta
    /// come oggi; il Play riparte dall'uscita che c'è.
    func testWiredHeadphonesOnTheSolo() {
        var rig = playing(.solo, route: [headphones], at: 50.0)
        rig.pendingBPM = 130
        rig.routeChange(at: 55.0, to: [speaker])
        XCTAssertFalse(rig.isRunning)
        XCTAssertFalse(rig.isPlaying)
        XCTAssertTrue(rig.playbackStopped, "lo schermo dopo lo Stop")
        XCTAssertNil(rig.pendingBPM, "la pulizia dello Stop")
        XCTAssertEqual(rig.crisisCause, .outputRemoved)
        rig.callbacks(from: 55.681, count: 3)
        XCTAssertFalse(rig.isRunning)
        rig.routeChange(at: 58.0, to: [headphones])
        XCTAssertFalse(rig.isRunning, "nel Solo nessun ritorno automatico")
        XCTAssertNil(rig.directorReturn)
        XCTAssertNil(rig.followerReturn)
        rig.wakeup(at: 59.0)
        XCTAssertFalse(rig.isRunning, "neanche il risveglio: il Solo dopo «uscita-tolta» aspetta il Play")
        rig.start(at: 60.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.volume, 1.0)
    }

    /// (4) Lo Stop voluto del Direttore muto a motore fermo: `isPlaying` falso, il pedale fa partire, il ritorno in primo
    /// piano con e senza ripresa pendente non riparte.
    func testTheWantedStopOfTheSilentDirectorAtEngineStopped() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 12.0)
        XCTAssertTrue(rig.silentInSong)
        XCTAssertFalse(rig.isRunning)
        rig.pendingBPM = 130
        rig.stop(at: 13.0)
        XCTAssertFalse(rig.isPlaying)
        XCTAssertFalse(rig.silentInSong)
        XCTAssertNil(rig.pendingBPM, "il cambio di tempo armato prima della crisi non scatta al Play dopo")
        XCTAssertTrue(rig.wantedStop)
        rig.wakeup(at: 14.0)
        XCTAssertFalse(rig.isRunning, "senza ripresa pendente")
        rig.pendingResume = true
        rig.wakeup(at: 15.0)
        XCTAssertFalse(rig.isRunning, "con la ripresa pendente")
        XCTAssertEqual(rig.starts, 1)
        rig.pedalPlayPause(at: 16.0)
        XCTAssertTrue(rig.isRunning, "il pedale fa partire")
        XCTAssertEqual(rig.starts, 2)
    }

    // MARK: - Le sequenze del par. 2.3

    /// Una tolta durante l'attesa del ritorno annulla il ritorno e alza «uscita mancante», sul Follower e sul Direttore.
    func testARemovedDuringTheReturnWaitCancelsIt() {
        var follower = playing(.follower, route: [speaker])
        follower.routeChange(at: 11.0, to: [headphones])
        XCTAssertEqual(follower.volume, 0.0)
        XCTAssertNotNil(follower.followerReturn)
        follower.callbacks(from: 11.05, count: 3)
        XCTAssertNotNil(follower.followerReturn?.unoAt)
        follower.routeChange(at: 11.2, to: [speaker])
        XCTAssertNil(follower.followerReturn)
        XCTAssertTrue(follower.state.missing)
        follower.callbacks(from: 11.25, count: 400)
        XCTAssertEqual(follower.volume, 0.0, "il volume non torna")
        var director = playing(.direttore, route: [speaker])
        director.routeChange(at: 11.0, to: [headphones])
        XCTAssertNotNil(director.directorReturn)
        director.routeChange(at: 11.05, to: [speaker])
        XCTAssertNil(director.directorReturn)
        XCTAssertTrue(director.state.missing)
        director.advance(to: 15.0)
        XCTAssertFalse(director.isRunning)
        XCTAssertEqual(director.rejoins, 0)
    }

    /// L'inizio di un'interruzione e uno Stop durante l'attesa del ritorno lo annullano.
    func testAnInterruptionOrAStopDuringTheWaitCancelsTheReturn() {
        var director = playing(.direttore, route: [speaker])
        director.routeChange(at: 11.0, to: [headphones])
        director.interruptionBegan(at: 11.05)
        XCTAssertNil(director.directorReturn)
        director.advance(to: 12.0)
        XCTAssertFalse(director.isRunning)
        XCTAssertTrue(director.interrupted)
        var follower = playing(.follower, route: [speaker])
        follower.routeChange(at: 11.0, to: [headphones])
        follower.callbacks(from: 11.05, count: 3)
        follower.stop(at: 11.1)
        XCTAssertNil(follower.followerReturn)
        XCTAssertFalse(follower.isRunning)
        XCTAssertFalse(follower.isPlaying)
    }

    /// Il risveglio dell'app sospesa prima della notizia (13:55:42 del 24/10): le cuffie rimesse mentre l'app dormiva; al
    /// risveglio la rilettura del percorso abbassa «uscita mancante» e il Direttore rientra; la notizia tardiva (`unknown`,
    /// Speaker → Headphones) è un'aggiunta: un silenzio corto e un secondo rientro, mai un assert.
    func testTheWakeOfTheSuspendedAppBeforeTheNotice() {
        var rig = playing(.direttore, route: [headphones], at: 10.0)
        let a = rig.asserts
        rig.interruptionBegan(at: 12.0)
        rig.routeChange(at: 13.0, to: [speaker])
        XCTAssertTrue(rig.state.missing, "la tolta durante la chiamata aggiorna solo lo stato")
        XCTAssertFalse(rig.isRunning)
        rig.interruptionEnded(at: 14.0)
        XCTAssertFalse(rig.isRunning, "a fine chiamata il Direttore resta muto: l'uscita manca")
        XCTAssertFalse(rig.interrupted, "il tasto offre il Play")
        // L'app sospesa: le cuffie tornano senza notizia.
        rig.route = [headphones]
        rig.wakeup(at: 20.0)
        XCTAssertFalse(rig.state.missing)
        rig.advance(to: 24.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertTrue(rig.isRunning)
        // La notizia tardiva.
        rig.route = [speaker]
        rig.routeChange(at: 24.5, to: [headphones])
        XCTAssertFalse(rig.isRunning)
        XCTAssertNotNil(rig.directorReturn)
        rig.advance(to: 28.0)
        XCTAssertEqual(rig.rejoins, 2)
        XCTAssertEqual(rig.asserts, a)
    }

    /// Il Solo con «uscita-tolta» e un cambio di modo nello stesso blocco (una scheda USB a quattro canali che si stacca): il
    /// Solo si ferma e non riparte (la causa resta «uscita-tolta» anche dopo la crisi del modo).
    func testTheSoloWithARemovedAndAModeChangeInTheSameBlock() {
        var rig = playing(.solo, route: [usb])
        rig.routeChange(at: 11.0, to: [speaker], modeChanges: true)
        XCTAssertFalse(rig.isRunning)
        XCTAssertEqual(rig.crisisCause, .outputRemoved, "la causa che ferma il Solo non si cancella")
        XCTAssertEqual(rig.starts, 1, "nessuna ripartenza dal ramo del modo")
        XCTAssertTrue(rig.playbackStopped)
        rig.advance(to: 15.0)
        XCTAssertEqual(rig.starts, 1)
    }

    /// Il Follower con la stessa scheda che si stacca e si riattacca: il ramo del modo riparte come oggi, e `start()` tiene il
    /// volume a 0 finché «uscita mancante» è su; al riattacco il ramo del modo riparte col volume a 1 (il ritorno si annulla
    /// e decide `start()`).
    func testTheFollowerWithTheUSBCardOffAndOn() {
        var rig = playing(.follower, route: [usb])
        rig.routeChange(at: 11.0, to: [speaker], modeChanges: true)
        XCTAssertTrue(rig.isRunning, "il ramo del modo riparte come oggi")
        XCTAssertEqual(rig.starts, 2)
        XCTAssertEqual(rig.volume, 0.0, "il volume resta a 0: l'uscita manca")
        XCTAssertTrue(rig.state.missing)
        XCTAssertTrue(rig.isPlaying)
        rig.routeChange(at: 20.0, to: [usb], modeChanges: true)
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.starts, 3)
        XCTAssertEqual(rig.volume, 1.0, "il ritorno si annulla e decide start()")
        XCTAssertFalse(rig.state.missing)
        XCTAssertNil(rig.followerReturn)
    }

    /// Il cambio di ruolo e Link spento dall'utente col volume a 0: arresto locale come lo Stop, nessuno Stop a Link, stato
    /// giù, ritorni annullati; il click riparte col Play nel ruolo nuovo.
    func testRoleChangeAndLinkOffAtVolumeZero() {
        var rig = playing(.follower, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertEqual(rig.volume, 0.0)
        rig.roleChange(to: .solo, at: 12.0)
        XCTAssertFalse(rig.isRunning)
        XCTAssertFalse(rig.isPlaying)
        XCTAssertEqual(rig.linkStops, 0)
        XCTAssertFalse(rig.state.muted)
        XCTAssertFalse(rig.state.missing)
        rig.start(at: 13.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.volume, 1.0)
        // Il Direttore con un'aggiunta in attesa del ritorno, Link spento dall'utente: il ritorno si annulla.
        var director = playing(.direttore, route: [speaker])
        director.routeChange(at: 11.0, to: [headphones])
        XCTAssertNotNil(director.directorReturn)
        director.roleChange(to: .solo, at: 11.05)
        XCTAssertNil(director.directorReturn)
        director.advance(to: 15.0)
        XCTAssertFalse(director.isRunning)
    }

    // MARK: - Le sequenze dei punti U5, U9, par. 2.2 a e c

    /// La fine di un'interruzione col Direttore muto e l'uscita mancante: il tasto offre il Play (l'interruzione giù), il
    /// pedale non ferma la band; con l'hardware ancora occupato alla fine la ripresa pendente resta in piedi, e la notizia
    /// dopo la riprova (ancora «niente» se l'uscita manca).
    func testTheEndOfAnInterruptionWithTheSilentDirectorAndTheOutputMissing() {
        var free = playing(.direttore, route: [headphones])
        free.interruptionBegan(at: 11.0)
        free.routeChange(at: 11.5, to: [speaker])
        free.interruptionEnded(at: 12.0)
        XCTAssertFalse(free.isRunning)
        XCTAssertFalse(free.interrupted, "il tasto offre il Play")
        XCTAssertFalse(free.pendingResume)
        XCTAssertTrue(free.silentInSong)
        var busy = playing(.direttore, route: [headphones])
        busy.interruptionBegan(at: 11.0)
        busy.routeChange(at: 11.5, to: [speaker])
        busy.interruptionEnded(at: 12.0, hardwareBusy: true)
        XCTAssertTrue(busy.pendingResume, "l'hardware occupato: la ripresa pendente in piedi")
        XCTAssertTrue(busy.interrupted, "il tasto resta Stop, ed è giusto")
        // La notizia dopo, con l'hardware ancora occupato, recupera la ripresa pendente: «niente», e la ripresa resta.
        busy.interruptionEnded(at: 13.0, hardwareBusy: true)
        XCTAssertTrue(busy.pendingResume)
        XCTAssertFalse(busy.isRunning)
        // L'hardware si libera, le cuffie tornano: il ritorno.
        busy.hardwareBusy = false
        busy.routeChange(at: 14.0, to: [headphones])
        busy.advance(to: 18.0)
        XCTAssertEqual(busy.rejoins, 1)
    }

    /// Il Play del batterista col Direttore muto e l'uscita mancante (dalla fascia e dal pedale): rientra dall'altoparlante.
    func testTheDirectorPlayWithTheOutputMissingRejoins() {
        var rig = playing(.direttore, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertTrue(rig.state.missing)
        rig.start(at: 12.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertFalse(rig.state.missing)
        XCTAssertEqual(rig.state.lastOutputExternal, false, "la memoria diventa l'altoparlante")
        rig.advance(to: 16.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.refusedForMissing, 0)
    }

    /// Una tolta arrivata fra l'ultima lettura di `RecoveryDecision` e `start()`: `start()` la riguarda e lascia il Direttore
    /// com'è, per ogni innesco automatico.
    func testARemovedBetweenTheRecoveryDecisionAndStartRefusesTheStart() {
        for trigger in [RecoveryTrigger.interruptionEnded, .pendingRecovery, .appWakeup, .outputAdded] {
            var rig = playing(.direttore, route: [headphones])
            rig.interruptionBegan(at: 11.0)
            XCTAssertTrue(rig.silentInSong)
            // La tolta cade dopo la lettura e prima dell'avvio: lo stato è ancora «non mancante» alla lettura.
            rig.route = [speaker]
            rig.apply(.removed)
            rig.start(at: 12.0, recovery: trigger)
            XCTAssertFalse(rig.isRunning, "\(trigger)")
            XCTAssertEqual(rig.refusedForMissing, 1, "\(trigger)")
            XCTAssertFalse(rig.isPlaying, "\(trigger)")
        }
    }

    /// Il Direttore fuori da una canzone con la tolta durante una chiamata: alla fine non riparte (U16).
    func testTheDirectorOutOfASongWithARemovedDuringACall() {
        var rig = playing(.direttore, route: [headphones])
        rig.songInProgress = false
        rig.interruptionBegan(at: 11.0)
        XCTAssertFalse(rig.silentInSong)
        XCTAssertFalse(rig.isRunning)
        rig.routeChange(at: 11.5, to: [speaker])
        XCTAssertTrue(rig.state.missing)
        rig.interruptionEnded(at: 12.0)
        XCTAssertFalse(rig.isRunning, "nessuna ripartenza automatica")
        XCTAssertTrue(rig.playbackStopped, "seguito 1, par. 5.2: il player a fermo")
        rig.advance(to: 15.0)
        XCTAssertEqual(rig.starts, 1)
        rig.start(at: 16.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "riparte col Play")
    }

    /// L'attacco durante l'attesa d'ingresso del Follower: niente chiamate fino al fuoco, il ritorno si arma al fuoco e il
    /// volume torna.
    func testAnAddedDuringTheFollowerJoinWait() {
        var rig = OutputRig(role: .follower, route: [speaker])
        // Il motore parte, la catena al fuoco (nessuna chiamata).
        rig.engineRunning = true
        rig.isRunning = true
        rig.chain = 1
        rig.isPlaying = true
        rig.now = 10.0
        rig.routeChange(at: 10.2, to: [headphones])
        XCTAssertEqual(rig.volume, 0.0)
        XCTAssertTrue(rig.followerReturn!.armPending)
        // Il fuoco: i tre buffer.
        rig.callbacks(from: 10.9, count: 3)
        XCTAssertNotNil(rig.followerReturn?.unoAt)
        rig.callbacks(from: 10.9 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        checkReturnInvariants(rig, "attesa d'ingresso")
    }

    /// Il battito in ritardo zittito (U9): una correzione che scavalca il pendente di più di un buffer non scrive campioni e
    /// non arma la coda del click; i tre buffer dopo non portano niente di suo; le correzioni normali non zittiscono.
    func testTheLateBeatIsMutedAndTheNextBuffersCarryNoClick() {
        var rig = playing(.follower, route: [speaker])
        rig.callbacks(from: 12.0, count: 200, correction: 0.0009)
        XCTAssertEqual(rig.lateBeatsMuted, 0, "le correzioni normali non zittiscono")
        XCTAssertGreaterThan(rig.corrections, 0)
        // Un buco: la posizione va portata avanti di 0,25 battiti col pendente a 0,05.
        rig.position = (rig.position + 1).rounded(.down) - 0.05
        let written = rig.clickSamplesWritten
        rig.callbacks(from: 15.0, count: 1, correction: 0.25)
        XCTAssertEqual(rig.lateBeatsMuted, 1)
        XCTAssertEqual(rig.clickSamplesWritten, written, "nessun campione del click")
        rig.callbacks(from: 15.0 + rig.bufferSeconds, count: 3)
        XCTAssertEqual(rig.lateBeatsMuted, 1)
    }

    /// Il Follower dopo la Lost con un ritorno in attesa: nessun riarmo; fra la Lost e la Reset la notizia non tocca nemmeno lo
    /// stato (par. 2.3 a alla lettera); la tolta persa la rilegge l'avvio dopo la ricostruzione (U5, dalla memoria dell'ultima
    /// uscita a volume 1: dal seguito 1 la rilettura di ogni avvio del Follower), e il volume lo scrive `start()`.
    func testTheFollowerAfterTheLostWithAReturnPendingDoesNotRearm() {
        var rig = playing(.follower, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertTrue(rig.state.missing)
        rig.routeChange(at: 11.02, to: [headphones])
        rig.callbacks(from: 11.05, count: 3)
        XCTAssertNotNil(rig.followerReturn)
        rig.servicesLost(at: 11.1)
        XCTAssertNil(rig.followerReturn)
        XCTAssertTrue(rig.isRunning, "il Follower dopo la Lost resta in moto")
        XCTAssertEqual(rig.volume, 0.0)
        rig.routeChange(at: 11.5, to: [speaker])
        XCTAssertFalse(rig.state.missing, "coi servizi persi la notizia non tocca nemmeno lo stato")
        XCTAssertNil(rig.followerReturn)
        rig.rebuiltAndPlay(at: 20.0)
        XCTAssertTrue(rig.state.missing, "la rilettura all'avvio dopo la ricostruzione: l'ultima uscita era esterna")
        XCTAssertEqual(rig.volume, 0.0, "il volume lo scrive start(), dallo stato: l'uscita manca")
        rig.routeChange(at: 21.0, to: [headphones])
        rig.callbacks(from: 21.05, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
    }

    /// Dopo la verifica del diff (U16): il Direttore fuori da una canzone fermato da una tolta NON riparte al ritorno in primo
    /// piano quando l'uscita torna: riparte solo col Play. La guardia del risveglio non guarda la causa viva.
    func testTheWakeupAfterARemovedOutOfASongDoesNotRestartWhenTheOutputReturns() {
        var rig = playing(.direttore, route: [headphones])
        rig.songInProgress = false
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertFalse(rig.isRunning, "U16: arresto locale")
        XCTAssertTrue(rig.state.missing)
        XCTAssertEqual(rig.crisisCause, .outputRemoved)
        rig.routeChange(at: 12.0, to: [headphones])
        XCTAssertFalse(rig.state.missing, "l'aggiunta fuori da una canzone abbassa «uscita mancante»")
        XCTAssertFalse(rig.isRunning)
        rig.wakeup(at: 13.0)
        rig.advance(to: 15.0)
        XCTAssertFalse(rig.isRunning, "nessuna ripartenza automatica: riparte col Play")
        XCTAssertEqual(rig.starts, 1)
        rig.start(at: 16.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertEqual(rig.volume, 1.0)
    }

    /// Dopo la verifica del diff (U6, par. 2.3 a): un'aggiunta che cambia anche il modo (una scheda USB a quattro canali) col
    /// Direttore in canzone: il ramo del modo aggiorna le copie e non annulla il ritorno appena armato; il Direttore rientra da
    /// solo.
    func testAnAddedWithAModeChangeOnTheDirectorInASongKeepsTheReturn() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.routeChange(at: 11.0, to: [usb], modeChanges: true)
        XCTAssertFalse(rig.isRunning)
        XCTAssertTrue(rig.silentInSong)
        XCTAssertNotNil(rig.directorReturn, "il ritorno sopravvive al ramo del modo a motore fermo")
        XCTAssertEqual(rig.starts, 1)
        rig.advance(to: 14.0)
        XCTAssertEqual(rig.rejoins, 1, "il Direttore rientra da solo")
        XCTAssertTrue(rig.isRunning)
    }

    /// Dopo la verifica del diff (U3 b, par. 2.3 b): nessun motore in moto resta a volume 0 senza la sua strada di ritorno —
    /// per il Follower un ritorno in attesa, oppure «uscita mancante» su (la strada è un'esterna o il tocco), oppure i servizi
    /// audio persi (la strada è `start()` dopo il reset); il Direttore in moto non è mai a volume 0. Lungo le sequenze, passo
    /// per passo.
    func testNoRunningEngineStaysMutedWithoutItsReturnPath() {
        func check(_ rig: OutputRig, _ tag: String, file: StaticString = #filePath, line: UInt = #line) {
            if rig.isRunning && rig.state.muted {
                XCTAssertTrue(rig.followerReturn != nil || rig.state.missing || !rig.mediaServicesNormal,
                              "motore in moto a volume 0 senza strada di ritorno: \(tag)", file: file, line: line)
            }
            if rig.role == .direttore {
                XCTAssertFalse(rig.isRunning && rig.state.muted, "il Direttore in moto a volume 0: \(tag)", file: file, line: line)
            }
        }
        var rig = playing(.follower, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker]); check(rig, "tolta")
        rig.callbacks(from: 11.05, count: 50); check(rig, "richiami a volume 0")
        rig.routeChange(at: 12.0, to: [headphones]); check(rig, "aggiunta")
        rig.callbacks(from: 12.05, count: 1); check(rig, "ritorno armato")
        rig.callbacks(from: 12.05 + rig.bufferSeconds, count: 400); check(rig, "volume tornato")
        XCTAssertEqual(rig.volume, 1.0)
        rig.routeChange(at: 20.0, to: [speaker]); check(rig, "seconda tolta")
        rig.speakerTap(at: 21.0); check(rig, "tocco")
        rig.callbacks(from: 21.01, count: 400); check(rig, "dopo il tocco")
        XCTAssertEqual(rig.volume, 1.0)
        var card = playing(.follower, route: [usb])
        card.routeChange(at: 11.0, to: [speaker], modeChanges: true); check(card, "USB via col modo")
        card.routeChange(at: 20.0, to: [usb], modeChanges: true); check(card, "USB torna col modo")
        var director = playing(.direttore, route: [headphones])
        director.routeChange(at: 11.0, to: [speaker]); check(director, "Direttore tolta")
        director.routeChange(at: 12.0, to: [headphones]); check(director, "Direttore aggiunta")
        director.advance(to: 15.0); check(director, "Direttore rientrato")
        XCTAssertTrue(director.isRunning)
    }

    /// Dopo la verifica del diff (A408): il tocco «altoparlante» fra la Lost e la Reset abbassa solo lo stato; il volume lo
    /// riscrive `start()` dopo il reset.
    func testTheTapAfterTheLostDoesNotArmAReturn() {
        var rig = playing(.follower, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker])
        rig.callbacks(from: 11.05, count: 3)
        rig.servicesLost(at: 11.1)
        XCTAssertTrue(rig.isRunning, "il Follower resta in moto fino alla Reset")
        rig.speakerTap(at: 12.0)
        XCTAssertFalse(rig.state.missing)
        XCTAssertNil(rig.followerReturn, "nessun ritorno sul motore morto")
        rig.callbacks(from: 12.01, count: 400)
        XCTAssertEqual(rig.volume, 0.0, "il volume non si scrive sul motore morto")
        rig.rebuiltAndPlay(at: 20.0)
        XCTAssertEqual(rig.volume, 1.0, "dopo il reset decide start(): l'ultima uscita scelta e' l'altoparlante")
    }

    /// Dopo la verifica del diff (U6): col Direttore muto e una ripresa pendente, un'aggiunta arma il ritorno e la ripresa
    /// pendente è assorbita dal ritorno: una ripartenza sola, dopo l'assestamento, non subito nel mezzo del buco.
    func testAnAddedWithAPendingResumeIsAbsorbedByTheDirectorReturn() {
        var rig = playing(.direttore, route: [headphones], at: 10.0)
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertFalse(rig.isRunning)
        rig.pendingResume = true
        rig.routeChange(at: 12.0, to: [headphones])
        XCTAssertNotNil(rig.directorReturn)
        XCTAssertFalse(rig.pendingResume, "assorbita dal ritorno")
        XCTAssertEqual(rig.starts, 1, "non riparte subito")
        rig.advance(to: 12.05)
        XCTAssertEqual(rig.starts, 1, "non prima dei 100 ms")
        rig.advance(to: 15.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.starts, 2, "una ripartenza sola")
    }

    /// Il tocco «altoparlante» del Follower (par. 2.2 g): abbassa «uscita mancante» e il volume torna al primo «uno» almeno
    /// 0,3 s dopo il tocco (seguito 1: con la regola della notizia, senza buco vince l'ora del tocco); una tolta dopo rimette la
    /// regola.
    func testTheSpeakerTap() {
        var rig = playing(.follower, route: [headphones])
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertTrue(rig.state.missing)
        rig.speakerTap(at: 12.0)
        XCTAssertFalse(rig.state.missing)
        XCTAssertEqual(rig.state.lastOutputExternal, false)
        rig.callbacks(from: 12.01, count: 1)
        let uno = rig.followerReturn!.unoAt!
        XCTAssertGreaterThanOrEqual(uno, 12.3)
        XCTAssertEqual(rig.deadlineAt!, 12.3, accuracy: 1e-6, "senza buco vince l'ora del tocco")
        rig.callbacks(from: 12.01 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        checkReturnInvariants(rig, "tocco")
        rig.routeChange(at: 20.0, to: [headphones])
        rig.callbacks(from: 20.05, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        rig.routeChange(at: 25.0, to: [speaker])
        XCTAssertTrue(rig.state.missing, "una tolta dopo rimette la regola")
        XCTAssertEqual(rig.volume, 0.0)
    }

    /// (d) Un `engine.start()` che dura 0,7 s e un buco che continua 0,7 s dopo la notizia: il coordinatore calcola il
    /// bersaglio prima dell'avvio, e se il fuoco è in ritardo T5 passa al bersaglio dopo. Nessun click in ritardo, nemmeno il
    /// primo del rientro.
    func testTheRejoinWithASlowEngineStartAndAGapThatContinues() {
        for noticeAt in [100.0, 100.9, 101.1, 101.4] {
            var rig = playing(.direttore, route: [speaker], at: 90.0)
            rig.engineStartDuration = 0.7
            rig.routeChange(at: noticeAt, to: [headphones])
            let gapEndsAt = noticeAt + 0.7
            rig.advance(to: noticeAt + 10.0)
            XCTAssertEqual(rig.rejoins, 1, "notizia:\(noticeAt)")
            XCTAssertGreaterThanOrEqual(rig.firstClickAt!, gapEndsAt, "notizia:\(noticeAt)")
            XCTAssertGreaterThanOrEqual(rig.firstClickAt! - rig.latency, noticeAt + 0.1 + 0.7, "notizia:\(noticeAt)")
        }
    }

    /// Lo specchio `isPlaying` lungo le sequenze: vero a motore in moto, falso a motore fermo, in ogni stato visitato.
    func testIsPlayingMirrorsIsRunningEverywhere() {
        var rig = playing(.direttore, route: [headphones])
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        rig.routeChange(at: 12.0, to: [headphones])
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        rig.advance(to: 16.0)
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        rig.interruptionBegan(at: 17.0)
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        rig.stop(at: 18.0)
        XCTAssertEqual(rig.isPlaying, rig.isRunning)
        XCTAssertFalse(rig.isPlaying)
    }

    /// Il drenaggio di fine canzone trovato da una crisi: la chiusura si consegna una volta (par. 2.2 j).
    func testACrisisStopDeliversTheDrain() {
        var rig = playing(.direttore, route: [headphones])
        rig.drainPending = true
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertEqual(rig.drainDelivered, 1)
        XCTAssertFalse(rig.drainPending)
        var wanted = playing(.direttore, route: [headphones])
        wanted.drainPending = true
        wanted.stop(at: 11.0)
        XCTAssertEqual(wanted.drainDelivered, 0, "lo Stop voluto chiude senza consegnare")
    }

    // MARK: - A421 · SEGUITO 1, par. 2.3: nessun campione a volume 1 prima della scadenza

    /// Il tocco col render che riparte circa 680 ms dopo (il buco del 24/10, 13:59): la prima chiamata dopo il tocco è quella
    /// dopo il buco; la scadenza è la fine dei buffer programmati più la coda del click, non «0,3 s dopo il tocco»: i due
    /// buffer di prima del buco escono a volume 0, e il volume torna all'«uno» dopo.
    func testTheTapInsideARenderHoleWaitsForTheProgrammedBuffers() {
        for (offset, fallback) in [(0.0, false), (-1.0, false), (2.0, false), (0.0, true), (-1.0, true)] {
            var rig = playing(.follower, route: [headphones], at: 50.0, renderOffsetBuffers: offset, fallbackRead: fallback)
            rig.routeChange(at: 55.0, to: [speaker])
            rig.callbacks(from: 55.011, count: 40)
            XCTAssertEqual(rig.volume, 0.0)
            // Il tocco dentro il buco: nessuna chiamata fino alla ripartenza del render.
            rig.speakerTap(at: 55.6)
            XCTAssertTrue(rig.followerReturn!.armPending)
            let firstCall = 55.6 + 0.68
            rig.advance(to: firstCall)
            rig.scheduleNextBuffer(at: firstCall, gapSeconds: 0.68)
            XCTAssertFalse(rig.followerReturn!.armPending, "armato alla prima chiamata dopo il buco")
            let end = firstCall + rig.latency + rig.cycleSeconds + offset * rig.bufferSeconds + 3 * rig.bufferSeconds
            XCTAssertEqual(rig.programmedEndAt!, end, accuracy: 1e-6, "offset \(offset)")
            XCTAssertEqual(rig.deadlineAt!, end + 0.040, accuracy: 1e-6, "vince la fine dei buffer, non il tocco + 0,3 s")
            XCTAssertGreaterThan(rig.deadlineAt!, 55.6 + 0.3)
            XCTAssertEqual(rig.volume, 0.0, "nessun ritorno nella chiamata dopo il buco")
            rig.callbacks(from: firstCall + rig.bufferSeconds, count: 400)
            checkReturnInvariants(rig, "tocco nel buco offset:\(offset) riserva:\(fallback)")
            XCTAssertGreaterThanOrEqual(rig.firstSampleAt!, end + 0.040 - 1e-9, "i due buffer di prima del buco a volume 0")
        }
    }

    /// Il tocco senza buco: la scadenza è l'ora del tocco più 0,3 s; il volume torna al primo «uno» dopo, o alla battuta dopo
    /// se il primo campione a volume 1 cadrebbe prima della scadenza (lo scarto negativo e la lettura di riserva).
    func testTheTapWithoutAHoleReturnsAtTheFirstUnoAfterTheTwoTimesOrTheNextBar() {
        // L'«uno» subito dopo la scadenza: a 121, 4/4, la battuta 30 cade a 59.504; il tocco 0,305 s prima.
        let bar = 30.0 * 4 * 60.0 / 121.0
        for (offset, fallback, moves) in [(2.0, false, 0), (0.0, false, 1), (-1.0, false, 1), (0.0, true, 1)] {
            var rig = playing(.follower, route: [headphones], at: 50.0, renderOffsetBuffers: offset, fallbackRead: fallback)
            rig.routeChange(at: 55.0, to: [speaker])
            rig.callbacks(from: 55.011, count: 100)
            let tapAt = bar - 0.305
            rig.speakerTap(at: tapAt)
            rig.callbacks(from: tapAt + 0.004, count: 1)
            XCTAssertEqual(rig.deadlineAt!, tapAt + 0.3, accuracy: 1e-6)
            XCTAssertEqual(rig.armedUnoAt!, bar, accuracy: 1e-6, "il primo uno dopo le due ore")
            rig.callbacks(from: tapAt + 0.004 + rig.bufferSeconds, count: 400)
            checkReturnInvariants(rig, "tocco senza buco offset:\(offset) riserva:\(fallback)")
            XCTAssertEqual(rig.nextBarMoves, moves, "offset:\(offset) riserva:\(fallback)")
            if moves == 1 {
                XCTAssertEqual(rig.restoredUnoAt!, bar + rig.barSeconds, accuracy: 1e-6, "la battuta dopo")
            } else {
                XCTAssertEqual(rig.restoredUnoAt!, bar, accuracy: 1e-6)
            }
        }
    }

    /// Un buco del render che comincia dopo la chiamata dell'armo: il misuratore lo vede alla prima chiamata dopo, il ritorno
    /// si riarma e le due ore si rifanno da lì; i buffer programmati prima del buco escono a volume 0.
    func testAHoleAfterTheArmingCallRearmsTheReturn() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 40)
        rig.routeChange(at: 58.0, to: [headphones])
        rig.callbacks(from: 58.004, count: 2)
        XCTAssertFalse(rig.followerReturn!.armPending)
        let firstDeadline = rig.deadlineAt!
        XCTAssertEqual(firstDeadline, 58.3, accuracy: 1e-6)
        // Il buco: nessuna chiamata per 0,68 s, poi la prima dopo col buco visto dal misuratore.
        let afterHole = 58.004 + 2 * rig.bufferSeconds + 0.68
        rig.advance(to: afterHole)
        rig.scheduleNextBuffer(at: afterHole, gapSeconds: 0.68)
        XCTAssertEqual(rig.rearms, 1, "il ritorno si riarma")
        XCTAssertFalse(rig.followerReturn!.armPending, "e si arma di nuovo nella stessa chiamata")
        let end = afterHole + rig.latency + rig.cycleSeconds + 3 * rig.bufferSeconds
        XCTAssertEqual(rig.deadlineAt!, end + 0.040, accuracy: 1e-6, "le due ore rifatte dalla prima chiamata dopo il buco")
        XCTAssertGreaterThan(rig.deadlineAt!, firstDeadline)
        XCTAssertEqual(rig.volume, 0.0)
        rig.callbacks(from: afterHole + rig.bufferSeconds, count: 400)
        checkReturnInvariants(rig, "buco dopo l'armo", oneBarAtMost: false)
        XCTAssertGreaterThanOrEqual(rig.firstSampleAt!, end + 0.040 - 1e-9)
    }

    /// L'orologio che passa da Link a DA-SOLO mentre il ritorno aspetta: alla chiamata dopo il ritorno si riarma e l'«uno»
    /// viene dalla linea propria.
    func testAClockChangeFromLinkToOwnWhileWaitingRearms() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 40)
        rig.routeChange(at: 58.0, to: [headphones])
        rig.callbacks(from: 58.004, count: 2)
        XCTAssertEqual(rig.followerReturn!.uno!.clock, .link)
        rig.goOwnClock(at: 58.05)
        rig.callbacks(from: 58.06, count: 1)
        XCTAssertEqual(rig.rearms, 1)
        XCTAssertEqual(rig.followerReturn!.uno!.clock, .own, "l'uno dalla linea propria")
        XCTAssertFalse(rig.followerReturn!.armPending)
        rig.callbacks(from: 58.06 + rig.bufferSeconds, count: 400)
        checkReturnInvariants(rig, "Link -> proprio", oneBarAtMost: false)
    }

    /// Un cambio di tempo fra l'armo e l'«uno»: il battito dell'«uno» resta sulla battuta, la sua ora si rilegge a ogni chiamata
    /// e il volume torna al calcolo del buffer dell'«uno» all'ora nuova.
    func testATempoChangeBetweenTheArmingAndTheUnoKeepsTheUnoOnTheBar() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 40)
        rig.routeChange(at: 58.0, to: [headphones])
        rig.callbacks(from: 58.004, count: 2)
        let unoBeat = rig.followerReturn!.uno!.beat
        let unoBefore = rig.followerReturn!.unoAt!
        rig.linkTempoChange(to: 160, at: 58.1)
        rig.callbacks(from: 58.11, count: 1)
        XCTAssertEqual(rig.rearms, 0, "nessun riarmo: lo stesso orologio")
        XCTAssertEqual(rig.followerReturn!.uno!.beat, unoBeat, "il battito resta")
        let unoAfter = rig.followerReturn!.unoAt!
        XCTAssertEqual(unoAfter, rig.time(ofBeat: unoBeat), accuracy: 1e-9)
        XCTAssertLessThan(unoAfter, unoBefore, "a 160 l'uno arriva prima")
        rig.callbacks(from: 58.11 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertEqual(rig.restoredUnoAt!, unoAfter, accuracy: 1e-9, "all'ora nuova")
        XCTAssertLessThanOrEqual(rig.raisedAt!, unoAfter - rig.latency - rig.bufferSeconds + 1e-9)
        XCTAssertGreaterThanOrEqual(rig.firstSampleAt!, rig.deadlineAt! - 1e-9)
    }

    /// A421 · SEGUITO 2 (par. 5.2, E.1, la cura (a)): l'ora dell'«uno» che non si può rileggere (DA-SOLO, un cambio di tempo
    /// della sezione butta la linea propria): il ritorno si riarma e resta prenotato («uno non calcolabile»); il volume NON torna
    /// alla scadenza: le due ore si rifanno al primo «uno» calcolabile, sulla linea ri-ancorata al buffer dopo, e il click torna
    /// sull'«1» (fra la scadenza e una battuta dopo: il limite di una battuta di E.1 non scatta).
    /// ⚠️ RISCRITTO A421 · SEGUITO 2: fino al seguito 1 si chiamava testAnUnreadableUnoRearmsAndFallsBackToTheDeadline e
    /// attendeva il volume alla prima chiamata dopo la scadenza, senza «uno» (smentito dal par. 5.2 del seguito 2).
    func testAnUnreadableUnoRearmsAndWaitsForTheUnoOfTheReanchoredLine() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.goOwnClock(at: 54.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 40)
        rig.routeChange(at: 58.0, to: [headphones])
        rig.callbacks(from: 58.004, count: 2)
        XCTAssertEqual(rig.followerReturn!.uno!.clock, .own)
        let unoBeat = rig.followerReturn!.uno!.beat
        let deadline = rig.followerReturn!.deadlineAt!
        XCTAssertEqual(deadline, 58.3, accuracy: 1e-9, "la scadenza della notizia")
        rig.ownSectionTempoChange(to: 140, at: 58.05)
        rig.callbacks(from: 58.06, count: 1)
        XCTAssertEqual(rig.rearms, 1, "l'uno non si rilegge: si riarma")
        XCTAssertTrue(rig.followerReturn!.armPending, "senza un uno calcolabile il ritorno resta prenotato (E.1)")
        XCTAssertNotNil(rig.ownTimeline, "la linea si ri-àncora al buffer dopo")
        XCTAssertEqual(rig.volume, 0.0)
        rig.callbacks(from: 58.06 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertNil(rig.followerReturn)
        XCTAssertEqual(rig.rearms, 1, "un riarmo solo")
        XCTAssertEqual(rig.nextBarMoves, 0)
        guard let restored = rig.restoredUnoAt, let raised = rig.raisedAt, let firstSample = rig.firstSampleAt else {
            return XCTFail("il volume deve tornare su un uno")
        }
        XCTAssertGreaterThan(raised, deadline + 0.5, "non alla scadenza: sull'uno della linea nuova")
        XCTAssertGreaterThanOrEqual(firstSample, deadline - 1e-9)
        XCTAssertLessThanOrEqual(restored, deadline + 4 * 60.0 / 140.0 + 1e-6,
                                 "entro una battuta dopo la scadenza: il limite di E.1 non scatta")
        XCTAssertEqual(restored, 59.3068, accuracy: 0.002, "l'uno di beat \(unoBeat) sulla linea ri-ancorata a 140 (modello)")
        XCTAssertLessThanOrEqual(raised, restored - rig.latency - rig.bufferSeconds + 1e-9)
    }

    /// Dentro un'interruzione (BOX5 :1735, seconda parte): un ritorno passato alla battuta dopo e un inizio d'interruzione
    /// prima dell'«uno»: il ritorno si annulla e il volume non si scrive.
    func testAReturnMovedToTheNextBarIsCancelledByAnInterruptionBegin() {
        let bar = 30.0 * 4 * 60.0 / 121.0
        var rig = playing(.follower, route: [headphones], at: 50.0, renderOffsetBuffers: -1.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 100)
        rig.speakerTap(at: bar - 0.305)
        rig.callbacks(from: bar - 0.301, count: 40)
        XCTAssertEqual(rig.nextBarMoves, 1, "alla battuta dopo")
        XCTAssertNotNil(rig.followerReturn, "resta armato")
        XCTAssertEqual(rig.volume, 0.0)
        rig.interruptionBegan(at: bar + 0.5)
        XCTAssertNil(rig.followerReturn, "l'inizio dell'interruzione annulla il ritorno")
        XCTAssertFalse(rig.isRunning)
        rig.callbacks(from: bar + 0.6, count: 400)
        XCTAssertEqual(rig.volume, 0.0, "il volume non si scrive")
        XCTAssertNil(rig.raisedAt)
    }

    /// Dopo la verifica indipendente del diff (rilievo 1): il primo campione a volume 1 si misura col ciclo d'uscita (qui 21,33
    /// ms), non col buffer da 512 campioni. Col ciclo lungo e lo scarto -1, per dodici fasi del tocco intorno alla battuta,
    /// nessun campione prima della scadenza; almeno una fase passa alla battuta dopo (col buffer al posto del ciclo la guardia
    /// avrebbe lasciato passare fino a 10,67 ms di coda del click).
    func testTheFirstSampleUsesTheOutputCycleNotTheBuffer() {
        let bar = 30.0 * 4 * 60.0 / 121.0
        let longCycle = 1024.0 / 48_000.0
        var moves = 0
        for k in 0..<12 {
            var rig = playing(.follower, route: [headphones], at: 50.0, cycleSeconds: longCycle, renderOffsetBuffers: -1.0)
            rig.routeChange(at: 55.0, to: [speaker])
            rig.callbacks(from: 55.011, count: 100)
            let tapAt = bar - 0.330 + Double(k) * 0.001
            rig.speakerTap(at: tapAt)
            rig.callbacks(from: tapAt + 0.004, count: 400)
            checkReturnInvariants(rig, "ciclo lungo, fase \(k)")
            moves += rig.nextBarMoves
        }
        XCTAssertGreaterThan(moves, 0, "almeno una fase passa alla battuta dopo: la guardia lavora col ciclo lungo")
    }

    /// L'invariante su tutta la griglia del par. 2.3: il ciclo d'uscita di 5,33, 6,67, 10,67 e 21,33 ms (col buffer del lettore
    /// sempre da 512 campioni), lo scarto fra le due ore da -1 a +2 buffer, il richiamo in ritardo fino a un buffer, la lettura
    /// di riserva; la notizia col buco del 24/10 e il tocco senza buco, a 121 e a 180,5. In ogni caso nessun campione a volume 1
    /// prima della scadenza, e il ritorno al più una battuta dopo l'«uno» scelto all'armo.
    func testNoSampleAtVolumeOneBeforeTheDeadlineAcrossCyclesOffsetsAndLateCallbacks() {
        let cycles = [256.0 / 48_000.0, 320.0 / 48_000.0, 512.0 / 48_000.0, 1024.0 / 48_000.0]
        var cases = 0
        for cycle in cycles {
            for offset in [-1.0, 0.0, 1.0, 2.0] {
                for late in [0.0, 0.5, 1.0] {
                    for fallback in [false, true] {
                        for bpm in [121.0, 180.5] {
                            let tag = "ciclo:\(cycle) scarto:\(offset) ritardo:\(late) riserva:\(fallback) tempo:\(bpm)"
                            // La notizia col buco del 24/10.
                            var notice = playing(.follower, route: [headphones], bpm: bpm, at: 50.0, cycleSeconds: cycle,
                                                 renderOffsetBuffers: offset, fallbackRead: fallback)
                            notice.routeChange(at: 55.0, to: [speaker])
                            notice.callbacks(from: 55.011, count: 30, late: late)
                            notice.routeChange(at: 58.806, to: [headphones])
                            let firstCall = 58.806 + 0.684
                            notice.advance(to: firstCall)
                            notice.scheduleNextBuffer(at: firstCall, gapSeconds: 0.684)
                            notice.callbacks(from: firstCall + notice.bufferSeconds, count: 1200, late: late)
                            checkReturnInvariants(notice, "notizia " + tag)
                            // Il tocco senza buco.
                            var tap = playing(.follower, route: [headphones], bpm: bpm, at: 50.0, cycleSeconds: cycle,
                                              renderOffsetBuffers: offset, fallbackRead: fallback)
                            tap.routeChange(at: 55.0, to: [speaker])
                            tap.callbacks(from: 55.011, count: 30, late: late)
                            tap.speakerTap(at: 56.0)
                            tap.callbacks(from: 56.004, count: 1200, late: late)
                            checkReturnInvariants(tap, "tocco " + tag)
                            cases += 2
                        }
                    }
                }
            }
        }
        XCTAssertEqual(cases, 4 * 4 * 3 * 2 * 2 * 2)
    }

    // MARK: - A421 · SEGUITO 1, par. 3.4: con l'interruzione in corso nessuna ripartenza automatica tocca sessione o motore

    /// (a) Il ritorno del Direttore (uscita_aggiunta) con `setCategory` fatto e un inizio d'interruzione prima del blocco della
    /// `setActive`: niente `setActive`; alla fine il rientro passa dal coordinatore.
    func testTheDirectorReturnWithABeginBeforeTheSetActiveBlock() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.routeChange(at: 11.0, to: [headphones])
        XCTAssertNotNil(rig.directorReturn)
        let setActives = rig.setActiveAttempts
        rig.injectBeginBeforeSetActive = true
        rig.advance(to: 12.0)
        XCTAssertEqual(rig.setActiveAttempts, setActives, "niente setActive con l'interruzione in corso")
        XCTAssertEqual(rig.refusals, 1)
        XCTAssertTrue(rig.systemInterruption)
        XCTAssertTrue(rig.interrupted)
        XCTAssertFalse(rig.pendingResume, "isAudioInterrupted vero: niente da alzare")
        XCTAssertEqual(rig.starts, 1)
        rig.interruptionEnded(at: 13.0)
        rig.advance(to: 17.0)
        XCTAssertEqual(rig.rejoins, 1, "alla fine il rientro dal coordinatore")
        XCTAssertEqual(rig.setActiveAttempts, setActives + 1)
    }

    /// (b) I tentativi ogni 0,5 s di una catena che non è quella del ritorno in primo piano (uscita_aggiunta) con
    /// un'interruzione che comincia in mezzo: il tentativo dopo non scrive niente; alla fine il rientro.
    func testTheRetriesOfAnotherChainWithABeginInBetween() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.setActiveFailures = 3
        rig.routeChange(at: 11.0, to: [headphones])
        rig.advance(to: 11.2)
        XCTAssertEqual(rig.setActiveAttempts, 1, "il tentativo 0 ha provato la setActive")
        XCTAssertNotNil(rig.retry)
        rig.interruptionBegan(at: 11.3)
        rig.advance(to: 12.0)
        XCTAssertEqual(rig.setActiveAttempts, 1, "il tentativo dopo non scrive niente")
        XCTAssertEqual(rig.refusals, 1)
        XCTAssertNil(rig.retry, "la catena finisce li'")
        XCTAssertFalse(rig.pendingResume)
        rig.interruptionEnded(at: 13.0)
        rig.advance(to: 17.0)
        XCTAssertEqual(rig.rejoins, 1)
    }

    /// (c) La ripresa pendente rimasta e un risveglio dentro una seconda interruzione, per il Follower e per il Direttore fuori
    /// da una canzone: il risveglio la toglie, la regola non scrive niente e la rialza (`isAudioInterrupted` falso); alla fine
    /// la recupera.
    func testTheWakeupWithAPendingResumeInsideASecondInterruption() {
        for role in [PlayerRole.follower, .direttore] {
            var rig = playing(role, route: [speaker], at: 10.0)
            if role == .direttore { rig.songInProgress = false }
            // Una catena di ripartenza in volo (la configurazione) col motore già fermo quando l'interruzione comincia.
            rig.setActiveFailures = 2
            rig.systemStopsEngine(at: 11.0)
            rig.configurationNotification(at: 11.1)
            XCTAssertEqual(rig.setActiveAttempts, 1, "\(role)")
            rig.interruptionBegan(at: 11.3)
            XCTAssertFalse(rig.interrupted, "\(role): motore già fermo, isAudioInterrupted resta basso")
            rig.advance(to: 11.7)
            XCTAssertEqual(rig.setActiveAttempts, 1, "\(role): il tentativo dopo non scrive niente")
            XCTAssertTrue(rig.pendingResume, "\(role): la ripresa pendente alzata dalla regola")
            let writes = rig.sessionWrites
            rig.wakeup(at: 12.0)
            XCTAssertEqual(rig.sessionWrites, writes, "\(role): il risveglio dentro l'interruzione non scrive la sessione")
            XCTAssertTrue(rig.pendingResume, "\(role): rialzata")
            XCTAssertFalse(rig.isRunning, "\(role)")
            rig.interruptionEnded(at: 13.0)
            rig.advance(to: 15.0)
            XCTAssertTrue(rig.isRunning, "\(role): alla fine la recupera")
            XCTAssertFalse(rig.pendingResume, "\(role)")
        }
    }

    /// (d) Il Direttore muto in canzone che torna in primo piano con lo stato alto e la fine mai arrivata: la riattivazione
    /// come oggi (l'eccezione D5), e il rientro.
    func testTheSilentDirectorForegroundReturnWithTheStateHighAndNoEnd() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        XCTAssertTrue(rig.silentInSong)
        XCTAssertTrue(rig.systemInterruption)
        rig.wakeup(at: 20.0)
        XCTAssertNotNil(rig.exceptionMark, "il segno dell'eccezione")
        XCTAssertEqual(rig.refusals, 0)
        XCTAssertEqual(rig.setActiveAttempts, 1)
        XCTAssertTrue(rig.isRunning, "la riattivazione come oggi")
        XCTAssertFalse(rig.systemInterruption, "la setActive riuscita abbassa lo stato")
        rig.advance(to: 24.0)
        XCTAssertEqual(rig.rejoins, 1)
    }

    /// (e) La stessa catena con la `setActive` rifiutata ventuno volte (il tentativo 0 e i venti dopo): la rete a 5 s e i
    /// tentativi dopo la rete (la rete fallisce una volta e il tentativo dopo riesce), come oggi, con l'eccezione a ogni
    /// passo; poi il rientro.
    func testTheForegroundChainWithTwentyOneRefusedSetActives() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        rig.setActiveFailures = 22
        rig.wakeup(at: 20.0)
        rig.advance(to: 30.5)
        XCTAssertEqual(rig.setActiveAttempts, 21, "il tentativo 0 e i venti dopo")
        XCTAssertTrue(rig.pendingResume, "i tentativi esauriti: la ripresa pendente")
        XCTAssertNotNil(rig.safetyNet)
        XCTAssertEqual(rig.refusals, 0, "l'eccezione vale a ogni tentativo")
        rig.advance(to: 35.2)
        XCTAssertEqual(rig.safetyNetFired, 1, "la rete a 5 s con lo stesso contatore della catena")
        XCTAssertEqual(rig.setActiveAttempts, 22, "la rete prova la setActive, che fallisce")
        XCTAssertNotNil(rig.retry, "e il tentativo dopo la rete")
        XCTAssertFalse(rig.isRunning)
        rig.advance(to: 36.0)
        XCTAssertEqual(rig.setActiveAttempts, 23, "il tentativo dopo la rete, con l'eccezione")
        XCTAssertEqual(rig.refusals, 0)
        XCTAssertTrue(rig.isRunning)
        rig.advance(to: 40.0)
        XCTAssertEqual(rig.rejoins, 1)
    }

    /// (f) Un inizio d'interruzione fra una `setActive` riuscita e il blocco di `start()`: `start()` non tocca sessione né
    /// motore; alla fine il rientro.
    func testABeginBetweenTheSetActiveAndTheStartBlock() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        rig.injectBeginBeforeStart = true
        rig.interruptionEnded(at: 12.0)
        XCTAssertEqual(rig.setActiveAttempts, 1)
        XCTAssertEqual(rig.starts, 1, "start() non avvia il motore")
        XCTAssertEqual(rig.refusals, 1)
        XCTAssertTrue(rig.systemInterruption)
        XCTAssertTrue(rig.interrupted)
        XCTAssertFalse(rig.pendingResume)
        XCTAssertFalse(rig.isRunning)
        rig.interruptionEnded(at: 13.0)
        rig.advance(to: 17.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.starts, 2)
    }

    /// (g) e par. 3.5: una ripresa pendente alzata dalla regola e la fine che non arriva; il Play del batterista la chiude;
    /// poi, a click in moto: nel modo Pro un'aggiunta e il motore non si ferma; una fine d'interruzione tardiva e niente si
    /// ricostruisce né riparte; la rete a 5 s di una catena vecchia non scatta.
    func testAPlayClosesThePendingResumeRaisedByTheRule() {
        var rig = playing(.follower, route: [usb], at: 10.0)
        rig.proMode = true
        rig.setActiveFailures = 21
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        rig.advance(to: 21.5)
        XCTAssertEqual(rig.setActiveAttempts, 21)
        XCTAssertTrue(rig.pendingResume)
        XCTAssertNotNil(rig.safetyNet)
        rig.interruptionBegan(at: 22.0)
        XCTAssertFalse(rig.interrupted)
        // Il Play del batterista a click fermo, con l'interruzione ancora in corso.
        rig.start(at: 23.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertFalse(rig.pendingResume, "par. 3.5: l'avvio riuscito chiude la ripresa pendente")
        XCTAssertFalse(rig.systemInterruption, "e l'interruzione di sistema")
        let rebuilds = rig.rebuilds
        let starts = rig.starts
        // Nel modo Pro un'aggiunta: il cambio di percorso non recupera nessuna ripresa, il motore non si ferma.
        rig.routeChange(at: 24.0, to: [usb2])
        XCTAssertTrue(rig.engineRunning, "il motore di sistema gira ancora")
        XCTAssertEqual(rig.rebuilds, rebuilds)
        XCTAssertEqual(rig.starts, starts)
        // Una fine d'interruzione tardiva.
        rig.interruptionEnded(at: 25.0)
        XCTAssertEqual(rig.rebuilds, rebuilds, "niente si ricostruisce")
        XCTAssertEqual(rig.starts, starts, "niente riparte")
        XCTAssertTrue(rig.engineRunning)
        // La rete a 5 s della catena vecchia.
        rig.advance(to: 28.0)
        XCTAssertEqual(rig.safetyNetFired, 0)
        XCTAssertEqual(rig.safetyNetSkipped, 1, "la rete non scatta: il contatore della catena e' cambiato")
        XCTAssertTrue(rig.isRunning)
        // La ripresa pendente alzata dalla regola (il no al tentativo dopo, con l'interruzione cominciata in mezzo), non dai
        // tentativi esauriti: il Play la chiude; l'aggiunta nel modo Pro e la fine tardiva non toccano il motore che gira.
        var byRule = playing(.follower, route: [usb], at: 10.0)
        byRule.proMode = true
        byRule.setActiveFailures = 2
        byRule.systemStopsEngine(at: 11.0)
        byRule.configurationNotification(at: 11.1)
        byRule.interruptionBegan(at: 11.3)
        byRule.advance(to: 11.7)
        XCTAssertEqual(byRule.refusals, 1)
        XCTAssertTrue(byRule.pendingResume, "alzata dalla regola")
        XCTAssertNil(byRule.retry)
        byRule.start(at: 12.0, recovery: nil)
        XCTAssertTrue(byRule.isRunning)
        XCTAssertFalse(byRule.pendingResume, "par. 3.5: il Play la chiude")
        XCTAssertFalse(byRule.systemInterruption)
        let rebuildsByRule = byRule.rebuilds
        let startsByRule = byRule.starts
        byRule.routeChange(at: 13.0, to: [usb2])
        XCTAssertTrue(byRule.engineRunning, "l'aggiunta Pro non ferma il motore")
        XCTAssertEqual(byRule.rebuilds, rebuildsByRule)
        byRule.interruptionEnded(at: 14.0)
        XCTAssertEqual(byRule.rebuilds, rebuildsByRule, "la fine tardiva non ricostruisce")
        XCTAssertEqual(byRule.starts, startsByRule, "e non riparte")
        XCTAssertTrue(byRule.engineRunning)
    }

    /// (h) Uno Stop voluto durante l'interruzione con un tentativo in volo, con `isAudioInterrupted` vero (la catena è morta) e
    /// falso (lo Stop non cambia il contatore): in tutti e due i casi nessuna ripresa pendente rinasce.
    func testAWantedStopDuringTheInterruptionWithAnAttemptInFlight() {
        // isAudioInterrupted vero: il Follower fermato dall'interruzione, la fine, la setActive che fallisce, un inizio nuovo.
        var dead = playing(.follower, route: [speaker], at: 10.0)
        dead.interruptionBegan(at: 11.0)
        XCTAssertTrue(dead.interrupted)
        dead.setActiveFailures = 5
        dead.interruptionEnded(at: 12.0)
        XCTAssertNotNil(dead.retry)
        dead.interruptionBegan(at: 12.1)
        XCTAssertTrue(dead.interrupted)
        dead.stop(at: 12.2)
        XCTAssertFalse(dead.interrupted, "lo Stop chiude la ripresa e alza il contatore")
        dead.advance(to: 13.0)
        XCTAssertFalse(dead.pendingResume)
        XCTAssertEqual(dead.refusals, 0, "la catena morta esce prima della regola")
        // isAudioInterrupted falso: una catena della configurazione col motore già fermo quando l'interruzione comincia.
        var alive = playing(.follower, route: [speaker], at: 10.0)
        alive.setActiveFailures = 5
        alive.systemStopsEngine(at: 11.0)
        alive.configurationNotification(at: 11.1)
        alive.interruptionBegan(at: 11.2)
        XCTAssertFalse(alive.interrupted)
        let token = alive.resumeToken
        alive.stop(at: 11.3)
        XCTAssertEqual(alive.resumeToken, token, "lo Stop non cambia il contatore")
        alive.advance(to: 12.0)
        XCTAssertFalse(alive.pendingResume, "nessuna ripresa pendente rinasce")
        XCTAssertEqual(alive.refusals, 1)
    }

    /// (h') Il punto 2 guarda prima il contatore della catena: uno Stop voluto fra l'ingresso e il blocco della `setActive`
    /// (l'interruzione in corso, `isAudioInterrupted` vero: lo Stop alza il contatore) lascia un blocco di una catena morta,
    /// che esce senza `setActive` e senza ripresa pendente; niente riparte.
    func testAWantedStopBetweenTheEntryAndTheSetActiveBlockKillsTheChain() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        XCTAssertTrue(rig.interrupted)
        rig.injectStopBeforeSetActive = true
        rig.interruptionEnded(at: 12.0)
        XCTAssertEqual(rig.deadChainsAtSetActive, 1, "il blocco e' di una catena morta")
        XCTAssertEqual(rig.setActiveAttempts, 0, "nessuna setActive")
        XCTAssertEqual(rig.refusals, 0, "non e' la regola: e' il contatore")
        XCTAssertFalse(rig.pendingResume)
        XCTAssertFalse(rig.interrupted)
        XCTAssertTrue(rig.wantedStop)
        XCTAssertFalse(rig.isRunning)
        rig.advance(to: 20.0)
        XCTAssertEqual(rig.starts, 1, "niente riparte dopo lo Stop voluto")
    }

    /// (i) La catena del ritorno in primo piano partita con lo stato basso e un'interruzione che comincia durante i suoi
    /// tentativi: l'eccezione non vale, e il tentativo dopo non scrive niente.
    func testTheForegroundChainStartedWithTheStateLowLosesAtANewBegin() {
        var rig = playing(.direttore, route: [headphones], at: 10.0)
        rig.routeChange(at: 11.0, to: [speaker])
        XCTAssertTrue(rig.silentInSong)
        XCTAssertFalse(rig.systemInterruption)
        rig.route = [headphones]
        rig.setActiveFailures = 3
        rig.wakeup(at: 12.0)
        XCTAssertNil(rig.exceptionMark, "partita con lo stato basso: nessun segno")
        XCTAssertEqual(rig.setActiveAttempts, 1)
        rig.interruptionBegan(at: 12.2)
        rig.advance(to: 13.0)
        XCTAssertEqual(rig.setActiveAttempts, 1, "il tentativo dopo non scrive niente")
        XCTAssertEqual(rig.refusals, 1)
        XCTAssertNil(rig.retry)
    }

    /// (j) La stessa catena partita con lo stato già alto e un inizio nuovo durante i suoi tentativi: da lì l'eccezione non vale;
    /// alla fine il rientro; senza la fine, il Direttore aspetta il ritorno in primo piano dopo, che passa.
    func testTheForegroundChainWithANewBeginDuringItsRetries() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        rig.setActiveFailures = 3
        rig.wakeup(at: 12.0)
        XCTAssertEqual(rig.exceptionMark, InterruptionActivationException(chainToken: rig.resumeToken, beginsCount: 1))
        XCTAssertEqual(rig.setActiveAttempts, 1)
        rig.interruptionBegan(at: 12.2)
        XCTAssertEqual(rig.beginsCount, 2)
        rig.advance(to: 13.0)
        XCTAssertEqual(rig.setActiveAttempts, 1, "da li' l'eccezione non vale")
        XCTAssertEqual(rig.refusals, 1)
        // Con la fine: il rientro.
        var ended = rig
        ended.setActiveFailures = 0
        ended.interruptionEnded(at: 14.0)
        ended.advance(to: 18.0)
        XCTAssertEqual(ended.rejoins, 1)
        // Senza la fine: il ritorno in primo piano dopo ha il suo segno e passa.
        var again = rig
        again.setActiveFailures = 0
        again.wakeup(at: 20.0)
        XCTAssertEqual(again.exceptionMark?.beginsCount, 2)
        XCTAssertTrue(again.isRunning)
        again.advance(to: 24.0)
        XCTAssertEqual(again.rejoins, 1)
    }

    /// (k) Il Solo con una catena di ripartenza in volo (dopo un cambio di configurazione) e un inizio d'interruzione: nessuna
    /// ripresa pendente, fermo come allo Stop della console, con la causa «interruzione» (`RecoveryDecision`: «niente» a ogni
    /// innesco); alla fine niente riparte; riparte col Play.
    func testTheSoloWithAChainInFlightAndABegin() {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.setActiveFailures = 2
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        XCTAssertEqual(rig.setActiveAttempts, 1)
        rig.interruptionBegan(at: 11.3)
        rig.advance(to: 11.7)
        XCTAssertEqual(rig.setActiveAttempts, 1)
        XCTAssertFalse(rig.pendingResume, "il Solo non alza mai la ripresa pendente")
        XCTAssertTrue(rig.playbackStopped, "fermo come allo Stop della console")
        XCTAssertEqual(rig.crisisCause, .interruption)
        for trigger in RecoveryTrigger.allCases {
            XCTAssertEqual(RecoveryDecision.route(trigger: trigger, playerRole: .solo, silentInSong: false, wantedStopSinceCrisis: rig.wantedStop,
                                                  crisisCause: rig.crisisCause), .noRestart, "\(trigger)")
        }
        rig.interruptionEnded(at: 13.0)
        rig.advance(to: 15.0)
        XCTAssertEqual(rig.starts, 1, "alla fine niente riparte")
        rig.start(at: 16.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "riparte col Play")
    }

    /// (k') Il Solo con la ripresa pendente già alzata dalla sua catena (tentativi esauriti), poi un inizio d'interruzione e la
    /// fine entro i 5 s della rete: la ripresa si perde all'inizio, la causa è «interruzione», niente riparte.
    func testTheSoloWithAPendingResumeAndABeginBeforeTheNet() {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.setActiveFailures = 21
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        rig.advance(to: 21.5)
        XCTAssertTrue(rig.pendingResume)
        XCTAssertNotNil(rig.safetyNet)
        let token = rig.resumeToken
        rig.interruptionBegan(at: 22.0)
        XCTAssertFalse(rig.pendingResume, "la ripresa si perde all'inizio")
        XCTAssertEqual(rig.resumeToken, token + 1, "clearPendingResumeQ alza il contatore")
        XCTAssertEqual(rig.crisisCause, .interruption)
        XCTAssertTrue(rig.playbackStopped)
        rig.interruptionEnded(at: 23.0)
        XCTAssertEqual(rig.starts, 1, "la fine non fa ripartire niente")
        rig.advance(to: 28.0)
        XCTAssertEqual(rig.safetyNetFired, 0)
        XCTAssertEqual(rig.safetyNetSkipped, 1)
        XCTAssertEqual(rig.starts, 1)
    }

    // MARK: - A421 · SEGUITO 1, par. 4.4: il Follower fra una canzone e l'altra (risposta «A» di Mauro)

    /// Follower, canzone nelle cuffie, Stop a fine canzone, tolta a click fermo: la canzone dopo parte a volume 0 con «uscita
    /// mancante» alzata; il tocco: il volume a 1 al primo «uno» dopo le due ore.
    func testTheFollowerBetweenSongsStartsMutedAfterARemovedAtClickStopped() {
        var rig = playing(.follower, route: [headphones], at: 10.0)
        XCTAssertEqual(rig.state.lastOutputExternal, true)
        rig.stop(at: 20.0)
        rig.routeChange(at: 21.0, to: [speaker])
        XCTAssertFalse(rig.state.missing, "a click fermo la tolta non alza «uscita mancante» (U5)")
        rig.start(at: 25.0, recovery: nil)
        XCTAssertTrue(rig.isRunning)
        XCTAssertTrue(rig.state.missing, "la rilettura all'avvio: l'ultima uscita era esterna")
        XCTAssertEqual(rig.volume, 0.0, "la canzone dopo parte muta")
        rig.callbacks(from: 25.011, count: 100)
        XCTAssertEqual(rig.volume, 0.0)
        rig.speakerTap(at: 27.0)
        XCTAssertFalse(rig.state.missing)
        rig.callbacks(from: 27.004, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertGreaterThanOrEqual(rig.restoredUnoAt!, 27.3)
        checkReturnInvariants(rig, "fra due canzoni, il tocco")
    }

    /// Gli altri casi del par. 4.4: la canzone prima dall'altoparlante e la dopo senza cuffie (volume 1); tolta e riattacco a
    /// click fermo (volume 1); la chiusura dello show azzera la memoria e il primo avvio dello show dopo è come oggi; un click
    /// a volume 1 dalle cuffie fra due show (nel Solo) e poi START SHOW come Follower senza cuffie (come oggi); un cambio di
    /// ruolo in Follower dentro uno show con la memoria «esterna» e senza cuffie (l'avvio dopo è muto).
    func testTheFollowerBetweenSongsOtherCases() {
        var fromSpeaker = playing(.follower, route: [speaker], at: 10.0)
        fromSpeaker.stop(at: 20.0)
        fromSpeaker.start(at: 25.0, recovery: nil)
        XCTAssertEqual(fromSpeaker.volume, 1.0, "la canzone prima dall'altoparlante: come oggi")
        XCTAssertFalse(fromSpeaker.state.missing)
        var reattached = playing(.follower, route: [headphones], at: 10.0)
        reattached.stop(at: 20.0)
        reattached.routeChange(at: 21.0, to: [speaker])
        reattached.routeChange(at: 22.0, to: [headphones])
        reattached.start(at: 25.0, recovery: nil)
        XCTAssertEqual(reattached.volume, 1.0, "tolta e riattacco a click fermo: volume 1")
        var closed = playing(.follower, route: [headphones], at: 10.0)
        closed.stop(at: 20.0)
        closed.closeShow(at: 21.0)
        XCTAssertNil(closed.state.lastOutputExternal, "la chiusura dello show azzera la memoria")
        closed.routeChange(at: 22.0, to: [speaker])
        closed.openShow(at: 30.0)
        closed.songInProgress = true
        closed.start(at: 31.0, recovery: nil)
        XCTAssertEqual(closed.volume, 1.0, "il primo avvio dello show dopo e' come oggi")
        var between = playing(.solo, route: [headphones], at: 10.0)
        between.showOpen = false
        between.stop(at: 20.0)
        XCTAssertEqual(between.state.lastOutputExternal, true)
        between.roleChange(to: .follower, at: 21.0)
        XCTAssertEqual(between.state.lastOutputExternal, true, "il cambio di ruolo tiene la memoria")
        between.routeChange(at: 22.0, to: [speaker])
        between.openShow(at: 30.0)
        between.songInProgress = true
        between.start(at: 31.0, recovery: nil)
        XCTAssertEqual(between.volume, 1.0, "START SHOW come Follower senza cuffie: come oggi")
        XCTAssertFalse(between.state.missing)
        var inside = playing(.direttore, route: [headphones], at: 10.0)
        inside.stop(at: 20.0)
        inside.routeChange(at: 21.0, to: [speaker])
        inside.roleChange(to: .follower, at: 22.0)
        XCTAssertEqual(inside.state.lastOutputExternal, true)
        inside.start(at: 25.0, recovery: nil)
        XCTAssertEqual(inside.volume, 0.0, "il cambio di ruolo dentro lo show con la memoria esterna: l'avvio e' muto")
        XCTAssertTrue(inside.state.missing)
    }

    /// Dentro un'interruzione (BOX5 :1735, seconda parte): la rilettura all'avvio del Follower è una lettura del percorso e uno
    /// stato puro, nessuna scrittura della sessione; il Play della sessione Link che arriva con l'interruzione in corso parte
    /// muto se la memoria dice un'esterna che non c'è più.
    func testTheFollowerRereadAtStartInsideAnInterruptionIsAPureRead() {
        var rig = playing(.follower, route: [headphones], at: 10.0)
        rig.stop(at: 20.0)
        rig.routeChange(at: 20.5, to: [speaker])
        XCTAssertFalse(rig.state.missing, "a click fermo, senza una crisi, la tolta non alza «uscita mancante» (U5)")
        rig.interruptionBegan(at: 21.0)
        let writes = rig.sessionWrites
        rig.start(at: 22.0, recovery: nil)
        XCTAssertEqual(rig.sessionWrites, writes, "nessuna scrittura della sessione dalla rilettura")
        XCTAssertTrue(rig.state.missing, "la rilettura all'avvio: l'ultima uscita era esterna")
        XCTAssertEqual(rig.volume, 0.0)
        // La tolta dopo l'inizio dell'interruzione col motore fermo: la regola delle crisi ha ricordato «interruzione» (anche
        // per il Follower, «come oggi»), il motore è «fermo per una crisi» e la tolta alza «uscita mancante» da sola (U5).
        var crisis = playing(.follower, route: [headphones], at: 10.0)
        crisis.stop(at: 20.0)
        crisis.interruptionBegan(at: 21.0)
        crisis.routeChange(at: 21.5, to: [speaker])
        XCTAssertTrue(crisis.state.missing, "fermo per la crisi dell'interruzione: la tolta alza «uscita mancante»")
        XCTAssertEqual(crisis.crisisCause, .interruption)
    }

    // MARK: - A421 · SEGUITO 2, par. 2.3: il margine del rientro con le uscite lente e il lettore lento

    /// La cassa Bluetooth del 29/10 (latenza 111,6 ms: D circa 165 ms nel rig a 48 kHz, 169,6 sul telefono a 44,1): il primo
    /// tentativo col lettore da 337,3 ms. Col margine di oggi (150 ms fisso) l'armamento gira dopo l'ora chiesta al lettore:
    /// cinque fuochi in ritardo e il rientro non eseguito; col margine max(150, D + 80) il fuoco arriva circa 80 ms prima,
    /// nessun salto, un rientro solo.
    func testTheBluetoothSpeakerOfOctober29FirstAttempt() {
        for fixed in [true, false] {
            var rig = playing(.direttore, route: [bluetooth], at: 10.0, cycleSeconds: 512.0 / 44_100.0)
            rig.latency = 0.1116
            rig.useFixedMargin = fixed
            XCTAssertEqual(rig.firstBufferDistance, 5 * rig.bufferSeconds + 0.1116, accuracy: 1e-9)
            XCTAssertEqual(rig.margin, rig.firstBufferDistance + 0.080, accuracy: 1e-9)
            XCTAssertGreaterThan(rig.margin, 0.2)
            rig.engineStartDuration = 0.3373
            rig.routeChange(at: 20.0, to: [bluetooth, usb])
            XCTAssertTrue(rig.silentInSong)
            rig.advance(to: 30.0)
            if fixed {
                XCTAssertEqual(rig.rejoins, 0, "col margine fisso il fuoco e' sempre in ritardo: non-certo(ritardo-oltre-i-salti)")
                XCTAssertEqual(rig.lateSkips, 5, "cinque fuochi in ritardo")
                XCTAssertFalse(rig.isRunning)
            } else {
                XCTAssertEqual(rig.rejoins, 1)
                XCTAssertEqual(rig.lateSkips, 0, "nessun salto")
                XCTAssertEqual(rig.slowPlayerFires, 0)
                let bars = rig.firstClickAt! / rig.barSeconds
                XCTAssertEqual(bars, bars.rounded(), accuracy: 1e-6, "a una battuta")
            }
        }
    }

    /// Il lettore da 528,3 ms con la cassa e un bersaglio a circa 1,29 s dalla decisione: l'armamento col margine di 245 ms cade
    /// dopo la fine di `start()`, il fuoco e' in tempo, nessun segno e nessun salto.
    func testTheSlowPlayerWithTheSpeakerAndAFarTarget() {
        var rig = playing(.direttore, route: [bluetooth], at: 10.0, cycleSeconds: 512.0 / 44_100.0)
        rig.latency = 0.1116
        rig.engineStartDuration = 0.5283
        // Il bersaglio: la battuta a 21,82 s (121 BPM, 4/4, dall'avvio a 10,0); la decisione 1,294 s prima.
        let bar = rig.nextBarTime(atOrAfter: 21.5)
        rig.routeChange(at: bar - 1.294 - 0.1, to: [bluetooth, usb])
        rig.advance(to: 30.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.firstClickAt!, bar, accuracy: 1e-6)
        XCTAssertEqual(rig.lateSkips, 0)
        XCTAssertEqual(rig.slowPlayerFires, 0)
    }

    /// Il 30/10: il lettore da 684,9 ms col bersaglio a 413,1 ms dalla decisione (l'altoparlante): all'armamento il ritardo e'
    /// gia' certo, il segno «lettore-lento» manda il coordinatore senza consumare un salto e il primo click esce alla battuta
    /// dopo; i salti restano quattro. Senza il segno (com'era) un fuoco in ritardo e un salto.
    func testTheSlowPlayerAfterACallTakesTheNextBarWithoutASkip() {
        for mark in [true, false] {
            var rig = playing(.direttore, route: [speaker], at: 10.0)
            rig.useSlowPlayerMark = mark
            rig.engineStartDuration = 0.6849
            let bar = rig.nextBarTime(atOrAfter: 21.5)
            rig.routeChange(at: bar - 0.4131 - 0.1, to: [headphones])
            rig.advance(to: 30.0)
            XCTAssertEqual(rig.rejoins, 1, "segno:\(mark)")
            XCTAssertEqual(rig.firstClickAt!, bar + rig.barSeconds, accuracy: 1e-6, "la battuta dopo segno:\(mark)")
            if mark {
                XCTAssertEqual(rig.slowPlayerFires, 1)
                XCTAssertEqual(rig.lateSkips, 0, "nessun salto consumato")
                XCTAssertEqual(rig.lastRejoinSkipsLeft, 4, "i salti restano quattro")
            } else {
                XCTAssertEqual(rig.lateSkips, 1, "com'era: un fuoco in ritardo e un salto")
                XCTAssertEqual(rig.lastRejoinSkipsLeft, 3)
            }
        }
    }

    /// L'altoparlante con un lettore da 140 ms e un bersaglio a 160 ms dalla decisione: fino al seguito un fuoco in ritardo e un
    /// salto; da qui il segno e nessun salto tolto. E il segno con un fuoco che per le copie non e' in ritardo: si suona.
    func testTheSlowPlayerNearTargetAndTheMarkThatIsNotLateForTheCopies() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.engineStartDuration = 0.140
        let bar = rig.nextBarTime(atOrAfter: 21.5)
        rig.routeChange(at: bar - 0.160 - 0.1, to: [headphones])
        rig.advance(to: 30.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.slowPlayerFires, 1)
        XCTAssertEqual(rig.lateSkips, 0)
        XCTAssertEqual(rig.firstClickAt!, bar + rig.barSeconds, accuracy: 1e-6)
        // Il segno, ma le copie dicono una distanza più corta (la sola latenza): al fuoco non e' in ritardo, si suona al bersaglio.
        var copies = playing(.direttore, route: [speaker], at: 10.0)
        copies.engineStartDuration = 0.100
        copies.copiesDistance = 0.0233
        let bar2 = copies.nextBarTime(atOrAfter: 21.5)
        copies.routeChange(at: bar2 - 0.160 - 0.1, to: [headphones])
        copies.advance(to: 30.0)
        XCTAssertEqual(copies.rejoins, 1)
        XCTAssertEqual(copies.slowPlayerFires, 0, "il fuoco non e' in ritardo per le copie: si suona")
        XCTAssertEqual(copies.firstClickAt!, bar2, accuracy: 1e-6)
    }

    /// Con le uscite veloci e il lettore del 28/10 (27,7-78,9 ms) nessun cambio di bersaglio ne' di armamento rispetto a oggi.
    func testFastOutputsKeepTodaysTargetAndArming() {
        for route in [[speaker], [headphones]] {
            for fixed in [true, false] {
                var rig = playing(.direttore, route: route, at: 10.0)
                rig.latency = route == [speaker] ? 0.0126 : 0.0027
                rig.useFixedMargin = fixed
                XCTAssertEqual(rig.margin, 0.150, accuracy: 1e-9)
                rig.engineStartDuration = 0.079
                rig.routeChange(at: 20.0, to: route == [speaker] ? [headphones] : [speaker, usb])
                rig.advance(to: 30.0)
                XCTAssertEqual(rig.rejoins, 1, "\(route) fisso:\(fixed)")
                XCTAssertEqual(rig.slowPlayerFires, 0)
                XCTAssertEqual(rig.lateSkips, 0)
                XCTAssertEqual(rig.firstClickAt!, rig.nextBarTime(atOrAfter: 20.1 + 0.150), accuracy: 1e-6, "\(route) fisso:\(fixed)")
            }
        }
    }

    // MARK: - A421 · SEGUITO 2, par. 3.5: l'àncora tenuta dal rientro

    /// La seconda prova del 29/10 sull'iPad: la crisi da misuratore, il rientro, e 175 ms dopo il fuoco una seconda crisi nella
    /// scorta, prima dell'«uno». Com'era: l'àncora chiusa al fuoco, nessun battito contato uscito, «non-certo(nessuna-ancora)»,
    /// muto fino a fine canzone. Da qui: l'àncora tenuta dal rientro, la seconda crisi la trova viva e il coordinatore rientra
    /// alla battuta dopo.
    func testTheSecondCrisisInTheLeadInFindsTheHeldAnchor() {
        for held in [true, false] {
            var rig = playing(.direttore, route: [speaker], at: 10.0, cycleSeconds: 2 * 512.0 / 48_000.0)
            rig.useHeldAnchor = held
            rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
            XCTAssertTrue(rig.silentInSong)
            XCTAssertTrue(rig.anchor)
            rig.advance(to: 20.1)
            XCTAssertTrue(rig.isRunning, "il ritorno dopo 100 ms ha fatto ripartire il motore")
            let fireAt = rig.rejoin!.fireAt
            rig.advance(to: fireAt)
            XCTAssertEqual(rig.rejoins, 1)
            XCTAssertEqual(rig.anchorHeld, held)
            XCTAssertEqual(rig.anchor, held, "l'àncora resta viva solo tenuta dal rientro")
            XCTAssertTrue(rig.inLeadIn)
            // La seconda crisi nella scorta, al buffer 4 della catena nuova, prima dell'«uno».
            rig.callbacks(from: fireAt + rig.bufferSeconds, count: 1)
            XCTAssertTrue(rig.inLeadIn)
            let gapAt = fireAt + 2 * rig.bufferSeconds + 0.082
            rig.advance(to: gapAt)
            rig.scheduleNextBuffer(at: gapAt, gapSeconds: 0.082)
            XCTAssertEqual(rig.leadInCrises, 1, "nella scorta ogni buco e' una crisi (held:\(held))")
            XCTAssertTrue(rig.silentInSong)
            XCTAssertFalse(rig.anchorHeld)
            rig.advance(to: gapAt + 10.0)
            if held {
                XCTAssertEqual(rig.rejoins, 2, "il coordinatore conta dall'àncora tenuta e rientra")
                XCTAssertEqual(rig.uncertainRejoins, 0)
                XCTAssertFalse(rig.silentInSong)
            } else {
                XCTAssertEqual(rig.rejoins, 1, "com'era: nessuna àncora, resta muto")
                XCTAssertEqual(rig.uncertainRejoins, 1)
                XCTAssertTrue(rig.silentInSong)
            }
        }
    }

    /// Senza una crisi l'àncora tenuta si chiude quando il primo battito contato del rientro e' uscito; uno Stop voluto e la
    /// chiusura dello show nella finestra la chiudono prima.
    func testTheHeldAnchorClosesAtTheFirstCountedBeatOrAtAStop() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        rig.advance(to: 20.1)
        let fireAt = rig.rejoin!.fireAt
        let target = rig.rejoin!.targetAt
        rig.advance(to: fireAt)
        XCTAssertTrue(rig.anchorHeld)
        rig.callbacks(from: fireAt + rig.bufferSeconds, count: 40)
        XCTAssertFalse(rig.anchorHeld)
        XCTAssertFalse(rig.anchor)
        XCTAssertGreaterThanOrEqual(rig.anchorClosedAt!, target)
        XCTAssertLessThan(rig.anchorClosedAt!, target + 2 * rig.bufferSeconds)
        var stopped = playing(.direttore, route: [speaker], at: 10.0)
        stopped.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        stopped.advance(to: 20.1)
        stopped.advance(to: stopped.rejoin!.fireAt)
        XCTAssertTrue(stopped.anchorHeld)
        stopped.stop(at: stopped.now + 0.001)
        XCTAssertFalse(stopped.anchorHeld)
        XCTAssertFalse(stopped.anchor)
        var closed = playing(.direttore, route: [speaker], at: 10.0)
        closed.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        closed.advance(to: 20.1)
        closed.advance(to: closed.rejoin!.fireAt)
        closed.closeShow(at: closed.now + 0.001)
        XCTAssertFalse(closed.anchorHeld)
        XCTAssertFalse(closed.anchor)
    }

    // MARK: - A421 · SEGUITO 2, par. 4.7: il guardiano, la soglia, il ritorno dopo il buco

    /// L'iPad Direttore col Centro di Controllo (29/10): i buchi a pezzi, 83,4 · 98,6 · 116,5 ms, nessuna crisi (la soglia e' 150 a
    /// 121 BPM), il guardiano zittisce durante il buco, il volume torna al primo campione alla scadenza o dopo, e nel silenzio cade
    /// al piu' un battito per gesto.
    func testTheIPadDirectorWithTheControlCenterGoesOn() {
        var rig = playing(.direttore, route: [speaker], at: 10.0, cycleSeconds: 2 * 512.0 / 48_000.0, guardian: true)
        var gestures = 0
        for hole in [0.0834, 0.0986, 0.1165] {
            gestures += 1
            let lastCall = rig.now
            let resumeAt = lastCall + rig.bufferSeconds + hole
            rig.advance(to: resumeAt)
            XCTAssertEqual(rig.guardianFires, gestures, "il guardiano zittisce durante il buco \(hole)")
            XCTAssertEqual(rig.guardianFiredAt!, lastCall + 4 * rig.bufferSeconds, accuracy: 1e-6)
            XCTAssertEqual(rig.volume, 0.0)
            rig.scheduleNextBuffer(at: resumeAt, gapSeconds: hole)
            XCTAssertTrue(rig.isRunning, "nessuna crisi sotto la soglia \(hole)")
            XCTAssertFalse(rig.silentInSong)
            XCTAssertTrue(rig.followsLink)
            XCTAssertNotNil(rig.gapReturn, "il ritorno dopo il buco armato")
            rig.callbacks(from: resumeAt + rig.bufferSeconds, count: 60, correction: 0.001)
            XCTAssertEqual(rig.gapReturnRestores, gestures, "il volume torna \(hole)")
            XCTAssertEqual(rig.volume, 1.0)
            XCTAssertGreaterThanOrEqual(rig.gapFirstSampleAt!, rig.gapDeadlineAt! - 1e-9, "nessun campione a volume 1 prima della scadenza")
            // Il silenzio: dal guardiano al primo campione a volume 1: al piu' un battito dentro.
            let silenceStart = rig.guardianFiredAt!
            let silenceEnd = rig.gapFirstSampleAt!
            XCTAssertLessThan(silenceEnd - silenceStart, 60.0 / rig.bpm, "il silenzio dura meno di un battito")
            let beatsInside = Int(rig.linkBeat(at: silenceEnd).rounded(.down)) - Int(rig.linkBeat(at: silenceStart).rounded(.up)) + 1
            XCTAssertLessThanOrEqual(beatsInside, 1, "al piu' un battito contato e non suonato per gesto \(hole)")
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 100)
        }
        XCTAssertEqual(rig.rejoins, 0)
    }

    /// Un secondo pezzo di buco subito dopo la chiamata del buco (il misuratore lo mette nella base): la scadenza del ritorno
    /// dopo il buco si sposta con lui, e il volume non torna prima della fine dei buffer riprogrammati.
    func testASecondPieceAfterTheHoleMovesTheDeadline() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        let resumeAt = rig.now + rig.bufferSeconds + 0.0833
        rig.advance(to: resumeAt)
        rig.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.0833)
        let firstEnd = rig.gapReturn!.programmedEndAt
        // Il pezzo nella base: il richiamo dopo arriva 41 ms tardi, e il misuratore non lo conta.
        let late = resumeAt + rig.bufferSeconds + 0.041
        rig.absorbedPiece(0.041)
        rig.advance(to: late)
        rig.scheduleNextBuffer(at: late)
        XCTAssertEqual(rig.gapReturn!.programmedEndAt, firstEnd + 0.041, accuracy: 1e-6, "la scadenza si sposta col pezzo")
        rig.callbacks(from: late + rig.bufferSeconds, count: 60)
        XCTAssertEqual(rig.gapReturnRestores, 1)
        XCTAssertGreaterThanOrEqual(rig.gapFirstSampleAt!, firstEnd + 0.041 + 0.040 - 1e-9)
    }

    /// Lo stacco 1 del 30/10: il buco di 119,3 ms visto dal misuratore un millisecondo prima della notizia. Alla chiamata del buco
    /// il percorso dice gia' l'altoparlante e la memoria dice esterna: la crisi per l'uscita sparita; la tolta trova il Direttore
    /// gia' muto in canzone e alza «uscita mancante»; niente riparte da solo.
    func testTheCableRemovalSeenByTheMeterBeforeTheNotice() {
        var rig = playing(.direttore, route: [headphones], at: 10.0)
        XCTAssertEqual(rig.state.lastOutputExternal, true)
        let resumeAt = rig.now + rig.bufferSeconds + 0.1193
        rig.physicalRoute = [speaker]
        rig.advance(to: resumeAt)
        rig.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.1193)
        XCTAssertEqual(rig.vanishedCrises, 1, "la crisi per l'uscita sparita, sotto la soglia di 150")
        XCTAssertTrue(rig.silentInSong)
        XCTAssertFalse(rig.isRunning)
        XCTAssertEqual(rig.volume, 0.0)
        rig.routeChange(at: resumeAt + 0.001, to: [speaker])
        XCTAssertTrue(rig.state.missing, "la tolta alza «uscita mancante»")
        XCTAssertNil(rig.directorReturn, "la tolta annulla il ritorno")
        rig.advance(to: resumeAt + 5.0)
        XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
        XCTAssertEqual(rig.volume, 0.0)
    }

    /// Lo stesso stacco con la notizia in ritardo di 200 ms e di 3 s, sul Direttore in canzone, fuori da una canzone e sul
    /// Follower: nessun campione a volume 1 dall'altoparlante, poi lo stato della tolta.
    func testTheCableRemovalWithALateNotice() {
        for delay in [0.2, 3.0] {
            // Il Direttore in canzone: la crisi per l'uscita sparita; il ritorno dopo 100 ms rilegge il percorso e da' niente.
            var inSong = playing(.direttore, route: [headphones], at: 10.0)
            let resumeAt = inSong.now + inSong.bufferSeconds + 0.1193
            inSong.physicalRoute = [speaker]
            inSong.advance(to: resumeAt)
            inSong.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.1193)
            XCTAssertEqual(inSong.vanishedCrises, 1)
            inSong.advance(to: resumeAt + delay - 0.001)
            XCTAssertEqual(inSong.starts, 1, "il ritorno rilegge il percorso e da' niente (ritardo \(delay))")
            XCTAssertTrue(inSong.state.missing, "la rilettura di U5 ha alzato «uscita mancante»")
            XCTAssertEqual(inSong.volume, 0.0)
            inSong.routeChange(at: resumeAt + delay, to: [speaker])
            XCTAssertTrue(inSong.state.missing)
            XCTAssertEqual(inSong.volume, 0.0)
            // Il Direttore fuori da una canzone: l'arresto locale come la tolta, il player a fermo, nessun ritorno.
            var outOfSong = playing(.direttore, route: [headphones], at: 10.0)
            outOfSong.songInProgress = false
            let resume2 = outOfSong.now + outOfSong.bufferSeconds + 0.1193
            outOfSong.physicalRoute = [speaker]
            outOfSong.advance(to: resume2)
            outOfSong.scheduleNextBuffer(at: resume2, gapSeconds: 0.1193)
            XCTAssertEqual(outOfSong.vanishedCrises, 1)
            XCTAssertFalse(outOfSong.isRunning)
            XCTAssertFalse(outOfSong.silentInSong)
            XCTAssertTrue(outOfSong.playbackStopped, "il player a fermo")
            XCTAssertNil(outOfSong.directorReturn, "nessun ritorno del Direttore")
            outOfSong.advance(to: resume2 + delay - 0.001)
            XCTAssertEqual(outOfSong.starts, 1)
            outOfSong.routeChange(at: resume2 + delay, to: [speaker])
            XCTAssertTrue(outOfSong.state.missing, "la tolta col motore fermo per la crisi alza «uscita mancante»")
            // Il Follower: la riga, il silenzio, il ritorno dopo il buco che alla scadenza trova l'esterna sparita e aspetta; la
            // notizia (o la riserva di 2 s) lo lascia muto con «uscita mancante».
            var follower = playing(.follower, route: [headphones], at: 10.0)
            let resume3 = follower.now + follower.bufferSeconds + 0.1193
            follower.physicalRoute = [speaker]
            follower.advance(to: resume3)
            follower.scheduleNextBuffer(at: resume3, gapSeconds: 0.1193)
            XCTAssertTrue(follower.isRunning)
            XCTAssertEqual(follower.volume, 0.0)
            XCTAssertNotNil(follower.gapReturn)
            follower.callbacks(from: resume3 + follower.bufferSeconds, count: Int(min(delay, 2.5) / follower.bufferSeconds))
            XCTAssertEqual(follower.volume, 0.0, "nessun campione a volume 1 dall'altoparlante (ritardo \(delay))")
            XCTAssertEqual(follower.gapVanishedWaits, 1, "il ritorno ha trovato l'esterna sparita")
            if delay > 2.0 {
                XCTAssertEqual(follower.gapVanishedFired, 1, "la riserva di 2 s: la rilettura di U5")
                XCTAssertTrue(follower.state.missing)
                XCTAssertNil(follower.gapReturn)
            }
            follower.routeChange(at: resume3 + delay, to: [speaker])
            XCTAssertTrue(follower.state.missing)
            XCTAssertNil(follower.gapReturn)
            XCTAssertEqual(follower.volume, 0.0)
            follower.callbacks(from: resume3 + delay + 0.004, count: 100)
            XCTAssertEqual(follower.volume, 0.0, "muto con la sua strada di ritorno (l'aggiunta o il tocco)")
        }
    }

    /// Lo stesso stacco col percorso che alla chiamata del buco dice ancora l'uscita di prima: niente crisi per l'uscita sparita;
    /// sul Follower il ritorno dopo il buco rimette il volume, poi la tolta lo zittisce e alza «uscita mancante».
    func testTheCableRemovalWithTheRouteStillOld() {
        var director = playing(.direttore, route: [headphones], at: 10.0)
        let resumeAt = director.now + director.bufferSeconds + 0.1193
        director.advance(to: resumeAt)
        director.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.1193)
        XCTAssertEqual(director.vanishedCrises, 0)
        XCTAssertTrue(director.isRunning)
        XCTAssertTrue(director.followsLink)
        director.routeChange(at: resumeAt + 0.2, to: [speaker])
        XCTAssertTrue(director.silentInSong)
        XCTAssertTrue(director.state.missing)
        var follower = playing(.follower, route: [headphones], at: 10.0)
        let resume2 = follower.now + follower.bufferSeconds + 0.1193
        follower.advance(to: resume2)
        follower.scheduleNextBuffer(at: resume2, gapSeconds: 0.1193)
        follower.callbacks(from: resume2 + follower.bufferSeconds, count: 18)
        XCTAssertEqual(follower.gapReturnRestores, 1, "col percorso di prima il volume torna")
        follower.routeChange(at: resume2 + 0.2, to: [speaker])
        XCTAssertEqual(follower.volume, 0.0)
        XCTAssertTrue(follower.state.missing)
    }

    /// Un'aggiunta fuori da una canzone a click in moto (U16: come oggi, il volume resta a 1 e la memoria prende l'esterna, E.7), poi
    /// lo stacco con la notizia in ritardo: alla chiamata del buco la crisi per l'uscita sparita, niente dall'altoparlante.
    func testAnAddedOutOfASongThenARemovalWithALateNotice() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.songInProgress = false
        rig.routeChange(at: 15.0, to: [headphones])
        XCTAssertTrue(rig.isRunning, "fuori da una canzone un'aggiunta e' come oggi")
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertEqual(rig.state.lastOutputExternal, true, "E.7: la memoria prende l'esterna")
        rig.callbacks(from: 15.004, count: 20)
        let resumeAt = rig.now + rig.bufferSeconds + 0.1193
        rig.physicalRoute = [speaker]
        rig.advance(to: resumeAt)
        rig.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.1193)
        XCTAssertEqual(rig.vanishedCrises, 1)
        XCTAssertFalse(rig.isRunning)
        XCTAssertEqual(rig.volume, 0.0)
        XCTAssertTrue(rig.playbackStopped)
    }

    /// Un buco nella finestra dopo un cambio di sezione, sul Direttore e sul Follower: nessuna crisi sotto la soglia, nessun
    /// campione a volume 1 prima della prima correzione dopo la finestra.
    func testAHoleInTheWindowWaitsForTheFirstCorrectionAfterTheWindow() {
        for role in [PlayerRole.direttore, .follower] {
            var rig = playing(role, route: [speaker], at: 10.0)
            rig.followsLink = role == .direttore
            rig.sectionChange(at: rig.now + 0.001)
            XCTAssertEqual(rig.syncSkip, 100)
            let resumeAt = rig.now + rig.bufferSeconds + 0.060
            rig.advance(to: resumeAt)
            rig.scheduleNextBuffer(at: resumeAt, gapSeconds: 0.060)
            XCTAssertTrue(rig.isRunning, "\(role): nella finestra la salita di 60 ms e' sotto la soglia")
            XCTAssertEqual(rig.windowCrises, 0)
            XCTAssertEqual(rig.volume, 0.0)
            XCTAssertNotNil(rig.gapReturn)
            // La finestra: 99 chiamate ancora senza correzione.
            rig.callbacks(from: resumeAt + rig.bufferSeconds, count: 99, correction: 0.03)
            XCTAssertEqual(rig.volume, 0.0, "\(role): il volume non torna nella finestra")
            XCTAssertEqual(rig.syncSkip, 0)
            let windowEnd = rig.now
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 60, correction: 0.03)
            XCTAssertEqual(rig.firstCorrectionRearms, 1, "\(role): la prima correzione dopo la finestra sposta e riarma")
            XCTAssertEqual(rig.gapReturnRestores, 1, "\(role)")
            XCTAssertGreaterThan(rig.gapRestoredAt!, windowEnd)
            XCTAssertGreaterThanOrEqual(rig.gapFirstSampleAt!, rig.gapDeadlineAt! - 1e-9)
        }
    }

    /// Due buchi del Centro di Controllo nella finestra a 180,5 BPM, 98,6 e 83,4 ms (182,0 insieme, sopra mezzo battito meno tre
    /// buffer, 134,2): la crisi alla chiamata del secondo. E un pezzo messo nella base dopo l'ultimo buco che porta la somma alla
    /// soglia: la crisi alla prima chiamata dopo la finestra, senza la correzione.
    func testTwoHolesInTheWindowSumToACrisisAndAPieceInTheBaseAtTheClose() {
        var rig = playing(.direttore, route: [speaker], bpm: 180.5, at: 10.0)
        rig.followsLink = true
        rig.sectionChange(at: rig.now + 0.001)
        let first = rig.now + rig.bufferSeconds + 0.0986
        rig.advance(to: first)
        rig.scheduleNextBuffer(at: first, gapSeconds: 0.0986)
        XCTAssertTrue(rig.isRunning, "il primo da solo sotto la soglia")
        rig.callbacks(from: first + rig.bufferSeconds, count: 10)
        let second = rig.now + rig.bufferSeconds + 0.0834
        rig.advance(to: second)
        rig.scheduleNextBuffer(at: second, gapSeconds: 0.0834)
        XCTAssertEqual(rig.windowCrises, 1, "la somma arriva alla soglia")
        XCTAssertFalse(rig.isRunning)
        XCTAssertTrue(rig.silentInSong)
        // Il pezzo nella base alla chiusura.
        var piece = playing(.direttore, route: [speaker], bpm: 180.5, at: 10.0)
        piece.followsLink = true
        piece.sectionChange(at: piece.now + 0.001)
        let hole = piece.now + piece.bufferSeconds + 0.0986
        piece.advance(to: hole)
        piece.scheduleNextBuffer(at: hole, gapSeconds: 0.0986)
        piece.absorbedPiece(0.036)
        piece.callbacks(from: hole + piece.bufferSeconds, count: 99)
        XCTAssertTrue(piece.isRunning, "nella finestra niente crisi")
        XCTAssertEqual(piece.syncSkip, 0)
        let correctionsBefore = piece.corrections
        piece.callbacks(from: piece.now + piece.bufferSeconds, count: 1, correction: 0.03)
        XCTAssertEqual(piece.windowCrises, 1, "la crisi alla prima chiamata dopo la finestra")
        XCTAssertEqual(piece.corrections, correctionsBefore, "senza la correzione")
        XCTAssertFalse(piece.isRunning)
    }

    /// Il guardiano scattato, poi Stop e Play: il primo click suona (il volume lo riscrive l'avvio); il guardiano col motore
    /// fermato dal sistema: il silenzio, poi la rete riparte e l'avvio riscrive il volume; un inizio d'interruzione fra lo scatto
    /// del guardiano e la chiamata dopo: la fine riparte a volume 1; dentro un'interruzione il guardiano non scrive niente.
    func testTheGuardianWithStopAndPlaySystemStopInterruptionAndInsideAnInterruption() {
        var stopped = playing(.follower, route: [speaker], at: 10.0, guardian: true)
        stopped.advance(to: stopped.now + 0.2)
        XCTAssertEqual(stopped.guardianFires, 1)
        XCTAssertEqual(stopped.volume, 0.0)
        stopped.stop(at: stopped.now + 0.01)
        XCTAssertNil(stopped.guardian)
        stopped.start(at: stopped.now + 1.0, recovery: nil)
        XCTAssertEqual(stopped.volume, 1.0, "il primo click suona")
        XCTAssertNil(stopped.gapReturn)
        var system = playing(.direttore, route: [speaker], at: 10.0, guardian: true)
        system.systemStopsEngine(at: system.now + 0.001)
        system.callbacks(from: system.now + system.bufferSeconds, count: 5)
        XCTAssertEqual(system.stoppedCallbacks, 5)
        XCTAssertEqual(system.guardianFires, 1, "il guardiano scatta col motore fermato dal sistema (quattro buffer dopo l'ultima chiamata)")
        XCTAssertEqual(system.volume, 0.0)
        system.advance(to: system.now + 2.5)
        XCTAssertEqual(system.netFired, 1)
        XCTAssertTrue(system.isRunning)
        XCTAssertEqual(system.volume, 1.0, "il volume lo riscrive l'avvio")
        var interrupted = playing(.follower, route: [speaker], at: 10.0, guardian: true)
        interrupted.advance(to: interrupted.now + 0.1)
        XCTAssertEqual(interrupted.guardianFires, 1)
        interrupted.interruptionBegan(at: interrupted.now + 0.001)
        XCTAssertNil(interrupted.guardianSilenceChain, "l'inizio toglie il segno")
        XCTAssertFalse(interrupted.isRunning)
        interrupted.interruptionEnded(at: interrupted.now + 2.0)
        XCTAssertTrue(interrupted.isRunning)
        XCTAssertEqual(interrupted.volume, 1.0)
        var inside = playing(.follower, route: [speaker], at: 10.0, guardian: true)
        inside.systemInterruption = true
        inside.advance(to: inside.now + 0.2)
        XCTAssertEqual(inside.guardianFires, 0, "dentro un'interruzione il guardiano non scrive niente")
        XCTAssertEqual(inside.volume, 1.0)
    }

    /// La riga della «B»: il requisito del par. 4.4, fuori dalla finestra e dalla scorta, fino a 200 BPM, a 48 e a 44,1 kHz, col
    /// ciclo d'uscita fino a 21,33 e 23,2 ms: il silenzio dopo un buco alla soglia dura meno di un battito, quindi al piu' un
    /// battito per buco cade nel silenzio.
    func testAtMostOneBeatFallsInTheSilenceUpTo200BPM() {
        var worstFromHoleStart = 0.0
        for nodeRate in [48_000.0, 44_100.0] {
            for bpm in [121.0, 165.0, 180.0, 200.0] {
                for cycle in [512.0 / nodeRate, 1024.0 / 48_000.0, 1024.0 / 44_100.0] {
                    let tag = "nodi:\(nodeRate) bpm:\(bpm) ciclo_ms:\(cycle * 1000)"
                    var rig = playing(.direttore, route: [speaker], bpm: bpm, at: 10.0, cycleSeconds: cycle, guardian: true,
                                      nodeRate: nodeRate)
                    rig.followsLink = true
                    let threshold = RenderGapMeter.crisisThresholdSeconds(bpm: bpm, bufferFrames: 512, sampleRate: nodeRate,
                                                                          projectionSeconds: 0)
                    let hole = threshold - 0.001
                    let lastCall = rig.now
                    // La coda vecchia: i tre buffer in coda suonano ancora; da qui il render è fermo (il guardiano scatta qui).
                    let queueEnd = lastCall + 3 * rig.bufferSeconds
                    let resumeAt = lastCall + rig.bufferSeconds + hole
                    rig.advance(to: resumeAt)
                    rig.scheduleNextBuffer(at: resumeAt, gapSeconds: hole)
                    XCTAssertTrue(rig.isRunning, tag)
                    rig.callbacks(from: resumeAt + rig.bufferSeconds, count: 60, correction: 0.001)
                    XCTAssertEqual(rig.gapReturnRestores, 1, tag)
                    guard let restored = rig.gapFirstSampleAt else { continue }
                    let silenceFromHoleStart = restored - lastCall
                    worstFromHoleStart = max(worstFromHoleStart, silenceFromHoleStart)
                    XCTAssertLessThan(silenceFromHoleStart, 60.0 / bpm, "\(tag) silenzio dall'inizio del buco: \(silenceFromHoleStart)")
                    // I battiti caduti nel silenzio: dalla fine della coda vecchia al primo campione a volume 1.
                    let beatsInside = Int(rig.linkBeat(at: restored).rounded(.down)) - Int(rig.linkBeat(at: queueEnd).rounded(.up)) + 1
                    XCTAssertLessThanOrEqual(beatsInside, 1, tag)
                }
            }
        }
        // Il limite di tempo vero del banco (par. 4.4): sotto il battito a 200 BPM (300 ms).
        XCTAssertLessThan(worstFromHoleStart, 0.300)
        XCTAssertGreaterThan(worstFromHoleStart, 0.150, "il caso peggiore sta sopra la soglia piu' alta: la misura e' viva")
    }

    /// Un buco nella scorta (par. 4.7): la crisi, motivo «scorta».
    func testAHoleInTheLeadInIsACrisis() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        rig.advance(to: 20.1)
        let fireAt = rig.rejoin!.fireAt
        rig.advance(to: fireAt)
        XCTAssertTrue(rig.inLeadIn)
        let gapAt = fireAt + rig.bufferSeconds + 0.040
        rig.advance(to: gapAt)
        rig.scheduleNextBuffer(at: gapAt, gapSeconds: 0.040)
        XCTAssertEqual(rig.leadInCrises, 1)
        XCTAssertTrue(rig.silentInSong)
    }

    // MARK: - A421 · SEGUITO 2, par. 5.6: F1, E.1, E.7, E.9, F2

    /// F1: il riattacco subito dopo un cambio di sezione a 180,5 BPM (la finestra aperta): il volume non torna nella finestra;
    /// alla prima correzione dopo la finestra che sposta il ritorno si riarma e il volume torna all'«uno» dopo.
    func testTheReattachRightAfterASectionChangeWaitsForTheWindow() {
        var rig = playing(.follower, route: [headphones], bpm: 180.5, at: 10.0)
        rig.routeChange(at: 15.0, to: [speaker])
        rig.callbacks(from: 15.004, count: 50)
        rig.sectionChange(at: rig.now + 0.001)
        rig.routeChange(at: rig.now + 0.002, to: [headphones])
        XCTAssertTrue(rig.followerReturn!.armPending)
        // A 180,5 BPM un buffer è 0,0321 battiti: la correzione di 0,04 sposta di più di un buffer (0,03 no).
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 99, correction: 0.04)
        XCTAssertEqual(rig.volume, 0.0, "nella finestra il volume non torna")
        let windowEnd = rig.now
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 400, correction: 0.04)
        XCTAssertEqual(rig.firstCorrectionRearms, 1)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertGreaterThan(rig.raisedAt!, windowEnd)
        checkReturnInvariants(rig, "F1", oneBarAtMost: false)
        // Un cambio di metro col battito di Link che cambia solo nome (una correzione di un intero): nessun riarmo da F1.
        var meter = playing(.follower, route: [headphones], at: 10.0)
        meter.routeChange(at: 15.0, to: [speaker])
        meter.callbacks(from: 15.004, count: 50)
        meter.sectionChange(at: meter.now + 0.001)
        meter.routeChange(at: meter.now + 0.002, to: [headphones])
        meter.callbacks(from: meter.now + meter.bufferSeconds, count: 99)
        meter.callbacks(from: meter.now + meter.bufferSeconds, count: 1, correction: 4.0)
        XCTAssertEqual(meter.firstCorrectionRearms, 0, "il battito cambia solo nome")
    }

    /// E.1: DA-SOLO, il ritorno armato sull'«uno» proprio fra 1,2 s, la sezione che cambia tempo 0,3 s dopo: la linea propria manca,
    /// l'«uno» non si rilegge, il ritorno resta prenotato e le due ore si rifanno dopo la ri-àncora; il volume torna su un «uno»
    /// proprio, non a meta' battuta. Il limite: senza contatore ne' accenti (nessun «uno» uscito) una battuta dopo la scadenza
    /// vale la regola di oggi.
    func testWithoutAComputableUnoTheReturnStaysPendingUntilTheUnoIsBack() {
        var rig = playing(.follower, route: [headphones], at: 10.0)
        rig.routeChange(at: 15.0, to: [speaker])
        rig.callbacks(from: 15.004, count: 50)
        rig.goOwnClock(at: rig.now + 0.001)
        rig.routeChange(at: rig.now + 0.002, to: [headphones])
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 2)
        XCTAssertFalse(rig.followerReturn!.armPending)
        XCTAssertEqual(rig.followerReturn!.uno?.clock, .own)
        rig.ownSectionTempoChange(to: 140, at: rig.now + 0.3)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1)
        XCTAssertTrue(rig.followerReturn!.armPending, "la linea propria manca: si riarma e resta prenotato")
        // La ri-àncora al buffer dopo: l'«uno» torna calcolabile e le due ore si rifanno.
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        let timeline = rig.ownTimeline!
        let restoredBeat = timeline.beat(atTicks: rig.ticks(rig.restoredUnoAt!), ticksPerSecond: OutputRig.tps)
        let fromUno = (restoredBeat - rig.lastUnoBeat!) / Double(rig.beatsPerBar)
        XCTAssertEqual(fromUno, fromUno.rounded(), accuracy: 1e-6, "su un uno proprio, non a meta' battuta")
        // Il limite: nessun «uno» uscito (una sezione senza contatore e senza accenti).
        var limit = playing(.follower, route: [headphones], at: 10.0)
        limit.routeChange(at: 15.0, to: [speaker])
        limit.callbacks(from: 15.004, count: 50)
        limit.goOwnClock(at: limit.now + 0.001)
        limit.lastUnoBeat = nil
        limit.routeChange(at: limit.now + 0.002, to: [headphones])
        let noticeAt = limit.now
        limit.callbacks(from: limit.now + limit.bufferSeconds, count: 60)
        XCTAssertTrue(limit.followerReturn!.armPending, "senza un uno resta prenotato")
        XCTAssertEqual(limit.volume, 0.0)
        limit.callbacks(from: limit.now + limit.bufferSeconds, count: 400)
        XCTAssertEqual(limit.volume, 1.0, "una battuta dopo la scadenza vale la regola di oggi")
        XCTAssertGreaterThanOrEqual(limit.raisedAt!, noticeAt + 0.3 + limit.barSeconds - 0.02)
        XCTAssertNil(limit.restoredUnoAt)
    }

    /// E.7: START SHOW a click in moto in cuffia: la memoria dice esterna. E.9: un cambio di metro fra l'armo e l'«uno» riarma
    /// («metro-cambiato»). F2: una notizia «nessuna» che cambia la latenza sposta la scadenza riletta.
    func testShowOpenInHeadphonesMeterChangeAndALatencyChange() {
        var show = playing(.follower, route: [headphones], at: 10.0)
        show.state = OutputSilenceState(muted: false, missing: false, lastOutputExternal: nil)
        show.openShow(at: 15.0)
        XCTAssertEqual(show.state.lastOutputExternal, true, "E.7: la memoria prende l'uscita di adesso")
        var stoppedShow = playing(.follower, route: [headphones], at: 10.0)
        stoppedShow.stop(at: 14.0)
        stoppedShow.openShow(at: 15.0)
        XCTAssertNil(stoppedShow.state.lastOutputExternal, "a motore fermo nulla, come prima")
        var meter = playing(.follower, route: [headphones], at: 10.0)
        meter.routeChange(at: 15.0, to: [speaker])
        meter.callbacks(from: 15.004, count: 50)
        meter.routeChange(at: meter.now + 0.002, to: [headphones])
        meter.callbacks(from: meter.now + meter.bufferSeconds, count: 2)
        XCTAssertEqual(meter.followerReturn!.uno?.beatsPerBar, 4)
        let rearmsBefore = meter.rearms
        meter.meterChange(to: 3, at: meter.now + 0.001)
        meter.callbacks(from: meter.now + meter.bufferSeconds, count: 1)
        XCTAssertEqual(meter.rearms, rearmsBefore + 1, "E.9: metro cambiato, si riarma")
        XCTAssertEqual(meter.followerReturn!.uno?.beatsPerBar, 3, "l'uno nuovo col quantum nuovo")
        meter.callbacks(from: meter.now + meter.bufferSeconds, count: 400)
        checkReturnInvariants(meter, "E.9", oneBarAtMost: false)
        var latency = playing(.follower, route: [headphones], at: 10.0)
        latency.routeChange(at: 15.0, to: [speaker])
        latency.callbacks(from: 15.004, count: 50)
        latency.routeChange(at: latency.now + 0.002, to: [headphones])
        // L'armo nel buco (la prima chiamata 0,68 s dopo la notizia): vince la fine dei buffer, che la latenza nuova sposta.
        let firstCall = latency.now + 0.68
        latency.advance(to: firstCall)
        latency.scheduleNextBuffer(at: firstCall, gapSeconds: 0.68)
        let deadlineBefore = latency.deadlineAt!
        XCTAssertGreaterThan(deadlineBefore, latency.followerReturn!.noticeAt + 0.3, "vince la fine dei buffer")
        latency.latency = 0.0233 + 0.030
        latency.routeChange(at: latency.now + 0.001, to: [headphones])
        latency.callbacks(from: latency.now + latency.bufferSeconds, count: 1)
        XCTAssertGreaterThan(latency.deadlineAt!, deadlineBefore, "F2: la scadenza riletta con la latenza nuova")
        latency.callbacks(from: latency.now + latency.bufferSeconds, count: 400)
        checkReturnInvariants(latency, "F2", oneBarAtMost: false)
    }

    // MARK: - A421 · SEGUITO 2, par. 6.5: il Solo all'inizio di un'interruzione

    /// m2: il Solo fermo su «Resume from» (uno Stop voluto) con la ripresa pendente in piedi e un inizio d'interruzione entro i 5 s
    /// della rete: la ripresa si perde, il contatore sale, nessun secondo Stop.
    func testTheSoloOnResumeFromLosesOnlyThePendingResume() {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.stop(at: 12.0)
        XCTAssertTrue(rig.wantedStop)
        rig.pendingResume = true
        let token = rig.resumeToken
        let stops = rig.soloStops
        rig.interruptionBegan(at: 13.0)
        XCTAssertFalse(rig.pendingResume)
        XCTAssertEqual(rig.resumeToken, token + 1)
        XCTAssertEqual(rig.soloStops, stops, "nessun secondo Stop: lo schermo resta su Resume from")
        XCTAssertNil(rig.crisisCause, "m2: solo lo sgombero, la causa ricordata non cambia (correzione B9)")
    }

    /// m4: la sequenza del verificatore: la setActive fallita a 11,1 s, l'interruzione da 11,3 a 11,5 s, il tentativo a 11,6 s:
    /// niente riparte, il Solo fermo come allo Stop della console. E il Solo appena aperto, o gia' fermo per una crisi: niente Stop.
    func testTheSoloWithAShortInterruptionDuringTheRetriesDoesNotRestart() {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.setActiveFailures = 1
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        XCTAssertEqual(rig.setActiveAttempts, 1)
        XCTAssertNotNil(rig.retry)
        let token = rig.resumeToken
        rig.interruptionBegan(at: 11.3)
        XCTAssertEqual(rig.chainsClosedAtBegin, 1)
        XCTAssertEqual(rig.resumeToken, token + 1, "la catena chiusa")
        XCTAssertEqual(rig.soloStops, 1, "una ripartenza era in corso: fermo come allo Stop della console")
        XCTAssertEqual(rig.crisisCause, .interruption)
        rig.interruptionEnded(at: 11.5)
        rig.advance(to: 12.0)
        XCTAssertEqual(rig.setActiveAttempts, 1, "il tentativo a 11,6 s e' di una catena morta")
        XCTAssertEqual(rig.starts, 1, "niente riparte")
        XCTAssertFalse(rig.isRunning)
        var fresh = OutputRig(role: .solo, route: [speaker])
        fresh.interruptionBegan(at: 1.0)
        XCTAssertEqual(fresh.soloStops, 0, "mai suonato: niente Stop")
        XCTAssertEqual(fresh.crisisCause, .interruption)
        var afterCrisis = playing(.solo, route: [speaker], at: 10.0)
        afterCrisis.interruptionBegan(at: 12.0)
        XCTAssertEqual(afterCrisis.soloStops, 1)
        afterCrisis.interruptionEnded(at: 13.0)
        afterCrisis.interruptionBegan(at: 14.0)
        XCTAssertEqual(afterCrisis.soloStops, 1, "gia' fermo per una crisi: niente Stop")
    }

    // MARK: - A421 · SEGUITO 2, par. 7: il segno della mappa per il prossimo avvio

    /// Il segno non sopravvive alla canzone a cui appartiene: il Follower senza una sessione che suona esce da `start()` senza
    /// consumarlo; lo abbassano il fuoco dell'ingresso, il cambio di ruolo e la chiusura dello show; un avvio che prosegue lo consuma.
    func testTheSongMapMarkDoesNotSurviveItsSong() {
        var rig = OutputRig(role: .follower, route: [speaker])
        rig.songInProgress = false
        rig.followerSessionPlaying = false
        rig.setSongMap()
        rig.start(at: 10.0, recovery: nil)
        XCTAssertFalse(rig.isRunning)
        XCTAssertTrue(rig.songMapPending, "stayStopped: il segno resta")
        XCTAssertFalse(rig.songInProgress)
        var fired = rig
        fired.followerJoinFired()
        XCTAssertFalse(fired.songMapPending)
        var role = rig
        role.roleChange(to: .direttore, at: 11.0)
        XCTAssertFalse(role.songMapPending)
        var closed = rig
        closed.closeShow(at: 11.0)
        XCTAssertFalse(closed.songMapPending)
        var consumed = rig
        consumed.followerSessionPlaying = true
        consumed.start(at: 12.0, recovery: nil)
        XCTAssertTrue(consumed.isRunning)
        XCTAssertTrue(consumed.songInProgress, "l'avvio che prosegue lo consuma")
        XCTAssertFalse(consumed.songMapPending)
        // Senza il segno lo Start del DEBUG a show chiuso non e' «canzone in corso».
        var debug = OutputRig(role: .direttore, route: [speaker])
        debug.showOpen = false
        debug.songInProgress = false
        debug.start(at: 10.0, recovery: nil)
        XCTAssertFalse(debug.songInProgress)
    }
// MARK: - A421 · SEGUITO 2, le correzioni dopo il verificatore del diff (commit 3: B2, B3, B4)

/// Correzione B2: l'esterna sparita vista dal ritorno dopo il buco, poi una finestra «sync skip» che tiene il volume, l'esterna
/// di nuovo presente senza notizia e la riserva di 2 s che scatta dentro la finestra: il percorso si rilegge, il ritorno resta
/// e il volume torna per la sua regola; nessuna crisi sul Direttore, nessun Follower a volume 0 senza strada.
func testTheReserveFindsTheExternalOutputBackAndKeepsTheReturn() {
    for role in [PlayerRole.follower, .direttore] {
        var rig = playing(role, route: [headphones], at: 10.0)
        rig.followsLink = true
        let holeAt = rig.now + rig.bufferSeconds + 0.060
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060)
        XCTAssertNotNil(rig.gapReturn, "\(role)")
        XCTAssertEqual(rig.volume, 0.0, "\(role)")
        // Il cavo si stacca prima della scadenza, senza la notizia: la chiamata che rimetterebbe il volume trova l'esterna sparita.
        rig.physicalRoute = [speaker]
        rig.callbacks(from: holeAt + rig.bufferSeconds, count: 12)
        XCTAssertEqual(rig.gapVanishedWaits, 1, "\(role): la riga e la riserva di 2 s")
        XCTAssertNotNil(rig.gapReturn, "\(role)")
        // Una finestra «sync skip» (un cambio di sezione): nessuna chiamata puo' rimettere il volume.
        rig.sectionChange(at: rig.now + rig.bufferSeconds)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 20)
        // L'esterna torna senza notizia; la riserva scatta dentro la finestra.
        rig.physicalRoute = nil
        rig.advance(to: rig.now + 2.1)
        XCTAssertEqual(rig.gapVanishedBack, 1, "\(role): allo scatto il percorso si rilegge e l'esterna c'e'")
        XCTAssertEqual(rig.gapVanishedFired, 0, "\(role): niente «quello che farebbe la tolta»")
        XCTAssertEqual(rig.vanishedCrises, 0, "\(role)")
        XCTAssertNotNil(rig.gapReturn, "\(role): il ritorno resta")
        XCTAssertTrue(rig.isRunning, "\(role)")
        // Dopo la finestra il volume torna per la regola del ritorno.
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 150, correction: 0.0)
        XCTAssertEqual(rig.volume, 1.0, "\(role)")
        XCTAssertEqual(rig.gapReturnRestores, 1, "\(role)")
    }
}

/// Correzione B3: la finestra «sync skip» e' della catena. Uno Stop e un Play dentro la finestra: la catena nuova parte senza
/// finestra (nessun verdetto di chiusura con la base vecchia, nessun riarmo alla prima correzione); un rientro del Direttore
/// dopo una crisi con la finestra aperta: la catena del rientro parte senza finestra.
func testAStopOrARejoinInsideTheWindowLeavesNoWindowToTheNextChain() {
    var rig = playing(.direttore, route: [speaker], at: 10.0)
    rig.followsLink = true
    rig.sectionChange(at: 20.0)
    XCTAssertTrue(rig.windowOpen)
    rig.callbacks(from: 20.011, count: 10)
    rig.stop(at: 20.2)
    XCTAssertFalse(rig.windowOpen, "lo Stop chiude la finestra senza verdetto")
    rig.start(at: 21.0, recovery: nil)
    rig.callbacks(from: 21.011, count: 120, correction: 0.03)
    XCTAssertFalse(rig.windowOpen)
    XCTAssertFalse(rig.firstCorrectionPending)
    XCTAssertEqual(rig.windowCrises, 0)
    XCTAssertEqual(rig.firstCorrectionRearms, 0)
    var muted = playing(.direttore, route: [speaker], at: 10.0)
    let crisisAt = muted.now + muted.bufferSeconds + 0.300
    muted.advance(to: crisisAt)
    muted.scheduleNextBuffer(at: crisisAt, gapSeconds: 0.300)
    XCTAssertTrue(muted.silentInSong)
    muted.sectionChange(at: crisisAt + 0.5)
    XCTAssertTrue(muted.windowOpen)
    muted.advance(to: 30.0)
    XCTAssertEqual(muted.rejoins, 1)
    XCTAssertFalse(muted.windowOpen, "il fuoco del rientro apre una catena nuova senza finestra")
    XCTAssertEqual(muted.windowCrises, 0)
}

/// Par. 4.4 e 4.7, «un padrone solo»: il ritorno del Follower che si prenota (un'aggiunta, il tocco «altoparlante») mentre il
/// ritorno dopo il buco aspetta lo toglie, e il volume lo rimette lui.
func testTheFollowerReturnTakesOverTheGapReturn() {
    for tap in [false, true] {
        var rig = playing(.follower, route: tap ? [headphones] : [speaker], at: 10.0)
        rig.followsLink = true
        let holeAt = rig.now + rig.bufferSeconds + 0.060
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060)
        XCTAssertNotNil(rig.gapReturn, "tocco:\(tap)")
        XCTAssertNil(rig.followerReturn, "tocco:\(tap)")
        if tap {
            rig.speakerTap(at: holeAt + 0.010)
        } else {
            rig.routeChange(at: holeAt + 0.010, to: [headphones])
        }
        XCTAssertNil(rig.gapReturn, "tocco:\(tap): un padrone solo")
        XCTAssertNotNil(rig.followerReturn, "tocco:\(tap)")
        XCTAssertEqual(rig.gapReturnsDroppedForFollower, 1, "tocco:\(tap)")
        rig.callbacks(from: holeAt + 0.020, count: 400)
        XCTAssertEqual(rig.volume, 1.0, "tocco:\(tap)")
        XCTAssertEqual(rig.gapReturnRestores, 0, "tocco:\(tap): il volume lo rimette il ritorno del Follower")
    }
}

/// Par. 2.3: il lettore da 528,3 ms con la cassa e un bersaglio a circa 0,6 s dalla decisione: all'armamento il bersaglio non e'
/// piu' raggiungibile → il segno «lettore-lento», il fuoco subito, il coordinatore sceglie la battuta dopo con lo stesso conto dei
/// salti (nessun salto tolto), poi il fuoco in tempo.
func testTheSlowPlayerWithTheSpeakerAndANearTarget() {
    var rig = playing(.direttore, route: [bluetooth], at: 10.0, cycleSeconds: 512.0 / 44_100.0)
    rig.latency = 0.1116
    rig.engineStartDuration = 0.5283
    let bar = rig.nextBarTime(atOrAfter: 21.5)
    rig.routeChange(at: bar - 0.600 - 0.1, to: [bluetooth, usb])
    rig.advance(to: 30.0)
    XCTAssertEqual(rig.slowPlayerFires, 1, "il segno al bersaglio irraggiungibile")
    XCTAssertEqual(rig.lateSkips, 0, "nessun salto tolto")
    XCTAssertEqual(rig.rejoins, 1)
    XCTAssertEqual(rig.firstClickAt!, bar + rig.barSeconds, accuracy: 1e-6, "la battuta dopo")
    XCTAssertEqual(rig.lastRejoinSkipsLeft, DirectorRejoinDecision.maxLateSkips, "i salti restano tutti")
}

/// Par. 2.3: il segno sull'ultimo bersaglio dei salti: nessun «non certo» per il lettore, il coordinatore con lo stesso conto.
func testTheSlowPlayerMarkOnTheLastTargetOfTheSkipsIsNotUncertain() {
    var rig = playing(.direttore, route: [bluetooth], at: 10.0, cycleSeconds: 512.0 / 44_100.0)
    rig.latency = 0.1116
    rig.routeChange(at: 20.0, to: [bluetooth, usb])
    rig.advance(to: 20.2)   // il ritorno dell'aggiunta (0,1 s) e l'avvio: il rientro armato
    XCTAssertTrue(rig.isRunning)
    XCTAssertNotNil(rig.rejoin)
    rig.armRejoin(targetAt: rig.now + 0.100, skips: DirectorRejoinDecision.maxLateSkips)
    XCTAssertTrue(rig.rejoin!.slowPlayer, "il bersaglio troppo vicino: il segno")
    rig.advance(to: 30.0)
    XCTAssertEqual(rig.slowPlayerFires, 1)
    XCTAssertEqual(rig.uncertainRejoins, 0, "nessun «non certo» per il lettore")
    XCTAssertEqual(rig.rejoins, 1)
    XCTAssertTrue(rig.isRunning)
}

/// Par. 2.3: una decisione dentro un'interruzione: solo letture, il margine con la latenza letta (anche zero → 150 ms), nessuna
/// scrittura della sessione.
func testADecisionInsideAnInterruptionOnlyReads() {
    var rig = playing(.direttore, route: [speaker], at: 10.0)
    rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
    XCTAssertTrue(rig.silentInSong)
    rig.directorReturn = nil
    rig.interruptionBegan(at: 20.5)
    rig.latency = 0.0
    XCTAssertEqual(rig.margin, 0.150, accuracy: 1e-9, "la latenza letta zero: il margine di base")
    let writes = rig.sessionWrites
    rig.start(at: 21.0, recovery: nil)
    XCTAssertEqual(rig.sessionWrites, writes, "solo letture")
    XCTAssertNotNil(rig.rejoin, "la decisione: il bersaglio col margine letto adesso")
}

/// Par. 5.6 (F1): senza «uno» (il ritorno dopo il buco) il volume aspetta la finestra; sulla chiamata che consuma l'ultimo salto
/// (contatore 1 → 0: all'inizio della chiamata e' ancora > 0) il volume non torna; torna alla chiamata dopo, se la prima
/// correzione dopo la finestra non sposta di un buffer.
func testF1WithoutAnUnoAndOnTheLastSkipCall() {
    var rig = playing(.follower, route: [headphones], bpm: 180.5, at: 10.0)
    rig.followsLink = true
    rig.sectionChange(at: 20.0)
    let holeAt = 20.0 + rig.bufferSeconds + 0.050
    rig.advance(to: holeAt)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.050)
    XCTAssertNotNil(rig.gapReturn)
    XCTAssertNil(rig.followerReturn)
    var t = holeAt + rig.bufferSeconds
    var calls = 0
    while rig.syncSkip > 0 {
        let skipBefore = rig.syncSkip
        rig.callbacks(from: t, count: 1, correction: 0.0)
        XCTAssertEqual(rig.volume, 0.0, "salti all'inizio della chiamata: \(skipBefore)")
        t += rig.bufferSeconds
        calls += 1
    }
    XCTAssertGreaterThan(calls, 50)
    XCTAssertEqual(rig.volume, 0.0, "la chiamata che consuma l'ultimo salto non rimette il volume")
    rig.callbacks(from: t, count: 1, correction: 0.0005)
    XCTAssertEqual(rig.volume, 1.0, "la chiamata dopo, con una correzione sotto un buffer")
    XCTAssertEqual(rig.firstCorrectionRearms, 0)
}

/// Par. 5.6 (F1): un cambio di metro 4/4 → 3/4 e 3/4 → 4/4 col battito di Link che cambia solo nome: la prima correzione dopo
/// la finestra e' di un numero intero di battiti e non riarma il ritorno (la regola «a meno di un intero»).
func testAMeterChangeRenamesTheBeatWithoutRearmingTheReturn() {
    for (from, to, renaming) in [(4, 3, -1.0), (3, 4, 1.0), (4, 3, 3.0)] {
        var rig = playing(.follower, route: [headphones], bpm: 121, beatsPerBar: from, at: 10.0)
        rig.followsLink = true
        rig.sectionChange(at: 20.0)
        rig.meterChange(to: to, at: 20.0)
        let holeAt = 20.0 + rig.bufferSeconds + 0.050
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.050)
        XCTAssertNotNil(rig.gapReturn, "\(from)/4 → \(to)/4")
        var t = holeAt + rig.bufferSeconds
        while rig.syncSkip > 0 {
            rig.callbacks(from: t, count: 1)
            t += rig.bufferSeconds
        }
        rig.callbacks(from: t, count: 1, correction: renaming)
        XCTAssertEqual(rig.firstCorrectionRearms, 0, "\(from)/4 → \(to)/4: la rinomina di \(renaming) battiti non riarma")
        XCTAssertEqual(rig.volume, 1.0, "\(from)/4 → \(to)/4")
    }
}

/// Par. 4.7: il buco di 70,0 ms del 29/10 coi suoi richiami dopo: segue Link, la prima correzione (il buco piu' P) sotto mezzo
/// battito; poi tre pezzi del Centro di Controllo messi nella base (41,0 · 53,3 · 48,2 ms), senza crisi.
func testTheSeventyMsHoleWithItsCallbacksAndThePiecesInTheBase() {
    var rig = playing(.direttore, route: [speaker], bpm: 121, at: 10.0)
    let projection = rig.latency + rig.cycleSeconds
    let holeAt = rig.now + rig.bufferSeconds + 0.070
    rig.advance(to: holeAt)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.070)
    XCTAssertTrue(rig.isRunning)
    XCTAssertTrue(rig.followsLink, "sotto la soglia: segue Link")
    let firstCorrectionBeats = (0.070 + projection) * 121.0 / 60.0
    XCTAssertLessThan(firstCorrectionBeats, 0.5, "il buco piu' P sotto mezzo battito: \(firstCorrectionBeats)")
    rig.callbacks(from: holeAt + rig.bufferSeconds, count: 3, correction: firstCorrectionBeats)
    for piece in [0.0410, 0.0533, 0.0482] {
        rig.absorbedPiece(piece)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 2)
    }
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 200, correction: 0.0)
    XCTAssertEqual(rig.vanishedCrises + rig.windowCrises + rig.leadInCrises, 0)
    XCTAssertTrue(rig.isRunning)
    XCTAssertEqual(rig.volume, 1.0)
}
}
