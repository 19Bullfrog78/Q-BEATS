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
}

private struct RejoinWait {
    let targetAt: Double
    let fireAt: Double
    let skips: Int
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
    var bufferSeconds = 512.0 / 48_000.0
    let latency = 0.0233
    let margin = 0.150
    var bpm: Double
    let beatsPerBar: Int

    // A421 · SEGUITO 1 — le due ore (par. 2.3): lo scarto fra l'ora del rendering e la convenzione, in buffer (da -1 a +2), e
    // la lettura di riserva; la linea del tempo di Link (àncora e tempo) e la linea propria DA-SOLO.
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

    // Le attese.
    var directorReturn: DirectorReturn? = nil
    var followerReturn: FollowerReturn? = nil
    var netAt: Double? = nil
    var rejoin: RejoinWait? = nil
    var engineStartDuration = 0.0

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
    var sessionWrites = 0
    var setActiveAttempts = 0
    var rebuilds = 0
    var refusals = 0
    var safetyNetFired = 0
    var safetyNetSkipped = 0
    var deadChainsAtSetActive = 0

    init(role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4,
         bufferSeconds: Double = 512.0 / 48_000.0, renderOffsetBuffers: Double = 0.0, fallbackRead: Bool = false) {
        self.role = role
        self.route = route
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.bufferSeconds = bufferSeconds
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
            return (FollowerReturnUno(beat: bar, clock: .link), time(ofBeat: bar))
        case .own:
            guard let timeline = ownTimeline, let last = lastUnoBeat,
                  let beat = OutputReturnDecision.nextOwnUnoBeat(atOrAfter: timeline.beat(atTicks: ticks(t), ticksPerSecond: OutputRig.tps),
                                                                  lastUnoBeat: last, beatsPerBar: beatsPerBar),
                  let at = OutputReturnDecision.ownTicks(atBeat: beat, timeline: timeline, ticksPerSecond: OutputRig.tps) else { return nil }
            return (FollowerReturnUno(beat: beat, clock: .own), seconds(at))
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

    var externalPresent: Bool { OutputRouteDecision.hasExternal(route) }
    var stoppedByCrisis: Bool { !isRunning && ((crisisCause != nil && !wantedStop) || interrupted) }

    // MARK: - Lo stato e le attese

    mutating func apply(_ event: OutputSilenceEvent) {
        state = OutputRouteDecision.state(after: event, from: state, playerRole: role)
    }

    mutating func cancelReturns() {
        directorReturn = nil
        followerReturn = nil
    }

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
        return outcome
    }

    /// L'arresto locale di una crisi sulla coda: lettore e motore, il drenaggio consegnato, lo specchio.
    mutating func crisisStop() {
        isRunning = false
        engineRunning = false
        queued = []
        rejoin = nil
        netAt = nil
        if drainPending {
            drainPending = false
            drainDelivered += 1
        }
        publishIsPlaying()
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
        rejoin = nil
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
        cancelReturns()
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
        apply(.showOpened)
    }

    mutating func closeShow(at t: Double) {
        advance(to: t)
        showOpen = false
        songInProgress = false
        silentInSong = false
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
        if step.lowersMissing { apply(.externalPresent) }
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
        // `prepareNormalStartQ`: l'avvio che non passa dal coordinatore azzera causa e Stop voluto. (Come il motore, `start()`
        // non annulla i ritorni: li annullano le strade che fermano e ripartono.)
        if !(role == .direttore && silentInSong) {
            crisisCause = nil
            wantedStop = false
        }
        copyRate = hardwareRate
        // Il coordinatore, prima di `engine.start()`: il bersaglio col margine.
        var target: Double? = nil
        if role == .direttore && silentInSong {
            target = nextBarTime(atOrAfter: t + margin)
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
        starts += 1
        publishIsPlaying()
        playbackStopped = false
        now = t + engineStartDuration
        if let target {
            armRejoin(targetAt: target, skips: 0)
        } else {
            dspOrigin = 0
            position = 0
            scheduleNextBuffer(at: now)
            scheduleNextBuffer(at: now)
            scheduleNextBuffer(at: now)
        }
    }

    mutating func armRejoin(targetAt: Double, skips: Int) {
        rejoin = RejoinWait(targetAt: targetAt, fireAt: max(targetAt - margin, now), skips: skips)
    }

    /// Il fuoco del rientro (T5): in ritardo si salta al bersaglio dopo, fino a quattro volte.
    mutating func fireRejoin(at t: Double) {
        guard let wait = rejoin, isRunning else { rejoin = nil; return }
        rejoin = nil
        let renderAt = wait.targetAt - latency
        if t + DirectorRejoinDecision.minLeadSeconds > renderAt {
            guard wait.skips < DirectorRejoinDecision.maxLateSkips else {
                crisisStop()
                return
            }
            armRejoin(targetAt: nextBarTime(atOrAfter: wait.targetAt + 0.5 * 60.0 / bpm), skips: wait.skips + 1)
            return
        }
        rejoins += 1
        firstClickAt = wait.targetAt
        silentInSong = false
        followsLink = true
        dspOrigin = linkBeat(at: wait.targetAt)
        position = dspOrigin
        scheduleNextBuffer(at: t)
        scheduleNextBuffer(at: t)
        scheduleNextBuffer(at: t)
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
    mutating func scheduleNextBuffer(at t: Double, gapSeconds: Double? = nil, correction: Double? = nil) {
        guard isRunning else { return }
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
        if let hole = gapSeconds, useMeterCrisis {
            let outcome = RenderGapDecision.outcome(holeSeconds: hole, playerRole: role, showOpen: showOpen,
                                                    songInProgress: songInProgress, engineRunning: isRunning,
                                                    followsLink: followsLink, silentInSong: silentInSong)
            switch outcome {
            case .crisis:
                silenceNow()
                if crisis(.renderGap) == .silentInSong { silentInSong = true }
                crisisStop()
                // Come U6: l'attesa dipende dalla frequenza della sessione contro la copia.
                let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: hardwareRate != copyRate)
                directorReturn = DirectorReturn(wait: wait, fireAt: t + OutputReturnDecision.directorWaitSeconds(wait),
                                                trigger: .renderGap, armedAt: t)
                return
            case .followLink:
                followsLink = true
            case .lineOnly:
                break
            }
            // Seguito 1, par. 2.2: un buco visto dal misuratore con un ritorno armato: si riarma con la stessa regola.
            rearmFollowerReturn()
        }
        // La convenzione della correzione di fase (l'ora d'uscita di questo buffer) e l'ora del rendering (il prossimo buffer
        // da rendere, con lo scarto): la prima dà il buffer dell'«uno», la seconda le due ore.
        let outputStart = t + latency + bufferSeconds
        let outputEnd = outputStart + bufferSeconds
        let renderNext = outputStart + renderOffsetBuffers * bufferSeconds
        // Par. 2.3 b: un ritorno armato con una catena che non è più quella corrente si riarma con la stessa regola.
        if let armed = followerReturn, !armed.armPending, armed.chain != chain {
            rearmFollowerReturn()
        }
        // Seguito 1, par. 2.2: la rilettura dell'«uno», a ogni chiamata col ritorno armato e un «uno» scelto.
        if var armed = followerReturn, !armed.armPending, let uno = armed.uno {
            switch OutputReturnDecision.refreshUno(saved: uno, clockNow: followerClock, rereadTicks: unoTime(for: uno).map(ticks)) {
            case .rearm:
                rearmFollowerReturn()
            case .ticks(let at):
                armed.unoAt = seconds(at)
                followerReturn = armed
            }
        }
        if var pending = followerReturn, pending.armPending {
            let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: ticks(renderNext),
                                                                    queuedAhead: OutputReturnDecision.queuedAheadBuffers,
                                                                    bufferTicks: ticks(bufferSeconds))
            let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: ticks(pending.noticeAt), programmedEndOutputTicks: end,
                                                                      ticksPerSecond: OutputRig.tps)
            let next = nextUno(atOrAfter: seconds(deadline))
            pending.deadlineAt = seconds(deadline)
            pending.uno = next?.uno
            pending.unoAt = next?.at
            pending.armPending = false
            pending.chain = chain
            followerReturn = pending
            deadlineAt = pending.deadlineAt
            programmedEndAt = seconds(end)
            armedUnoAt = next?.at
        }
        // DA-SOLO: la linea propria si ri-àncora al buffer dopo il cambio di tempo (`ownClockPinQ`), fra l'armo e la guardia.
        if ownRepinPending && followerClock == .own {
            ownRepinPending = false
            let beatNow = ownBeatAtChange + (t - ownChangeTime) * ownTimelineBPM / 60.0
            ownTimeline = OwnClockTimeline(anchorTicks: ticks(t), anchorBeat: beatNow, bpm: ownTimelineBPM)
        }
        // U3 c e la guardia del primo campione (seguito 1, par. 2.2): se questo buffer porta l'«uno», il volume torna ADESSO, se
        // le condizioni reggono e il primo campione a volume 1 non è prima della scadenza; se no la battuta dopo. Senza un
        // «uno» calcolabile, alla prima chiamata col primo campione alla scadenza o dopo.
        if var pending = followerReturn, !pending.armPending, let deadline = pending.deadlineAt {
            let firstSample = seconds(OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: ticks(renderNext),
                                                                                      bufferTicks: ticks(bufferSeconds),
                                                                                      fallbackRead: fallbackRead))
            let step = OutputReturnDecision.followerReturnStep(bufferOutputTicks: ticks(outputStart), bufferTicks: ticks(bufferSeconds),
                                                               unoTicks: pending.unoAt.map(ticks), deadlineTicks: ticks(deadline),
                                                               firstSampleTicks: ticks(firstSample))
            let conditions = isRunning && !systemInterruption && !state.missing && state.muted && mediaServicesNormal
            switch step {
            case .wait:
                break
            case .nextBar:
                if !conditions {
                    followerReturn = nil
                } else if let uno = pending.uno, let next = OutputReturnDecision.nextBarUno(uno, beatsPerBar: beatsPerBar) {
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
        var mutedThisBuffer = false
        if role == .direttore && !followsLink {
            asserts += 1
        } else if let delta = correction {
            corrections += 1
            if LateBeatDecision.mutes(origin: dspOrigin, before: position, after: position + delta, bpm: bpm,
                                      bufferFrames: 512, sampleRate: 48_000) {
                lateBeatsMuted += 1
                mutedThisBuffer = true
            }
            position += delta
        }
        let beatInBuffer = (position + bufferBeats - dspOrigin).rounded(.down) > (position - dspOrigin).rounded(.down)
            || mutedThisBuffer
        if beatInBuffer && !mutedThisBuffer {
            clickSamplesWritten += 1
        }
        position += bufferBeats
        queued.append(RigBuffer(outputStart: outputStart, outputEnd: outputEnd, chain: chain))
        if queued.count > 3 { queued.removeFirst() }
    }

    /// I richiami a ogni buffer, da `from`, `count` volte; `late`: ogni secondo richiamo in ritardo di tanti buffer.
    mutating func callbacks(from: Double, count: Int, correction: Double? = nil, late: Double = 0.0) {
        for i in 0..<count {
            let t = from + Double(i) * bufferSeconds + (i % 2 == 1 ? late * bufferSeconds : 0.0)
            advance(to: t)
            scheduleNextBuffer(at: t, correction: correction)
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
        if InterruptionActivationDecision.soloLosesPendingAtBegin(playerRole: role, pendingResume: pendingResume) {
            clearPendingResume()
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: .interruption, playerRole: .solo)
            soloStop()
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
                         at t: Double = 10.0, bufferSeconds: Double = 512.0 / 48_000.0, renderOffsetBuffers: Double = 0.0,
                         fallbackRead: Bool = false) -> OutputRig {
        var rig = OutputRig(role: role, route: route, bpm: bpm, beatsPerBar: beatsPerBar, bufferSeconds: bufferSeconds,
                            renderOffsetBuffers: renderOffsetBuffers, fallbackRead: fallbackRead)
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
        let deadline = firstCall + rig.latency + rig.bufferSeconds + 3 * rig.bufferSeconds + 0.040
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
            let end = firstCall + rig.latency + rig.bufferSeconds + offset * rig.bufferSeconds + 3 * rig.bufferSeconds
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
        let end = afterHole + rig.latency + 4 * rig.bufferSeconds
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

    /// L'ora dell'«uno» che non si può rileggere (DA-SOLO, un cambio di tempo della sezione butta la linea propria): il ritorno
    /// si riarma; senza un «uno» calcolabile il volume torna alla prima chiamata col primo campione alla scadenza o dopo.
    func testAnUnreadableUnoRearmsAndFallsBackToTheDeadline() {
        var rig = playing(.follower, route: [headphones], at: 50.0)
        rig.goOwnClock(at: 54.0)
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.011, count: 40)
        rig.routeChange(at: 58.0, to: [headphones])
        rig.callbacks(from: 58.004, count: 2)
        XCTAssertEqual(rig.followerReturn!.uno!.clock, .own)
        rig.ownSectionTempoChange(to: 140, at: 58.05)
        rig.callbacks(from: 58.06, count: 1)
        XCTAssertEqual(rig.rearms, 1, "l'uno non si rilegge: si riarma")
        XCTAssertNil(rig.followerReturn!.uno, "all'armo la linea propria manca: uno non calcolabile")
        XCTAssertNotNil(rig.ownTimeline, "la linea si ri-àncora al buffer dopo")
        XCTAssertEqual(rig.volume, 0.0)
        rig.callbacks(from: 58.06 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertNil(rig.restoredUnoAt, "senza un uno")
        XCTAssertGreaterThanOrEqual(rig.firstSampleAt!, rig.deadlineAt! - 1e-9)
        XCTAssertLessThan(rig.firstSampleAt!, rig.deadlineAt! + 2 * rig.bufferSeconds + 1e-9, "alla prima chiamata dopo la scadenza")
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

    /// L'invariante su tutta la griglia del par. 2.3: il ciclo d'uscita di 5,33, 6,67, 10,67 e 21,33 ms, lo scarto fra le due
    /// ore da -1 a +2 buffer, il richiamo in ritardo fino a un buffer, la lettura di riserva; la notizia col buco del 24/10 e
    /// il tocco senza buco, a 121 e a 180,5. In ogni caso nessun campione a volume 1 prima della scadenza, e il ritorno al più
    /// una battuta dopo l'«uno» scelto all'armo.
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
                            var notice = playing(.follower, route: [headphones], bpm: bpm, at: 50.0, bufferSeconds: cycle,
                                                 renderOffsetBuffers: offset, fallbackRead: fallback)
                            notice.routeChange(at: 55.0, to: [speaker])
                            notice.callbacks(from: 55.011, count: 30, late: late)
                            notice.routeChange(at: 58.806, to: [headphones])
                            let firstCall = 58.806 + 0.684
                            notice.advance(to: firstCall)
                            notice.scheduleNextBuffer(at: firstCall, gapSeconds: 0.684)
                            notice.callbacks(from: firstCall + cycle, count: 1200, late: late)
                            checkReturnInvariants(notice, "notizia " + tag)
                            // Il tocco senza buco.
                            var tap = playing(.follower, route: [headphones], bpm: bpm, at: 50.0, bufferSeconds: cycle,
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

    /// (e) La stessa catena con la `setActive` rifiutata ventuno volte (il tentativo 0 e i venti dopo): la rete a 5 s e il
    /// tentativo dopo, come oggi; poi il rientro.
    func testTheForegroundChainWithTwentyOneRefusedSetActives() {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.interruptionBegan(at: 11.0)
        rig.setActiveFailures = 21
        rig.wakeup(at: 20.0)
        rig.advance(to: 30.5)
        XCTAssertEqual(rig.setActiveAttempts, 21, "il tentativo 0 e i venti dopo")
        XCTAssertTrue(rig.pendingResume, "i tentativi esauriti: la ripresa pendente")
        XCTAssertNotNil(rig.safetyNet)
        XCTAssertEqual(rig.refusals, 0, "l'eccezione vale a ogni tentativo")
        rig.advance(to: 36.0)
        XCTAssertEqual(rig.safetyNetFired, 1, "la rete a 5 s con lo stesso contatore della catena")
        XCTAssertEqual(rig.setActiveAttempts, 22)
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
        rig.interruptionBegan(at: 21.0)
        rig.routeChange(at: 21.5, to: [speaker])
        XCTAssertFalse(rig.state.missing)
        let writes = rig.sessionWrites
        rig.start(at: 22.0, recovery: nil)
        XCTAssertEqual(rig.sessionWrites, writes, "nessuna scrittura della sessione dalla rilettura")
        XCTAssertTrue(rig.state.missing)
        XCTAssertEqual(rig.volume, 0.0)
    }
}
