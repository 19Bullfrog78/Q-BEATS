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
}

private struct FollowerReturn {
    let noticeAt: Double
    var armPending: Bool
    var unoAt: Double?
    var chain: Int
    let fromTap: Bool
}

private struct RejoinWait {
    let targetAt: Double
    let fireAt: Double
    let skips: Int
}

private struct OutputRig {
    static let tps = 24_000_000.0
    let bufferSeconds = 512.0 / 48_000.0
    let latency = 0.0233
    let margin = 0.150
    let bpm: Double
    let beatsPerBar: Int

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

    // Le crisi e le riprese.
    var silentInSong = false
    var crisisCause: CrisisCause? = nil
    var wantedStop = false
    var followsLink = false
    var interrupted = false
    var systemInterruption = false
    var pendingResume = false
    var hardwareBusy = false

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
    var raiseAt: Double? = nil
    var raiseChain = 0
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

    init(role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4) {
        self.role = role
        self.route = route
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
    }

    // MARK: - Aritmetica

    func ticks(_ seconds: Double) -> UInt64 { UInt64((seconds * OutputRig.tps).rounded()) }
    func seconds(_ t: UInt64) -> Double { Double(t) / OutputRig.tps }
    func linkBeat(at t: Double) -> Double { t * bpm / 60.0 }
    func time(ofBeat beat: Double) -> Double { beat * 60.0 / bpm }
    var bufferBeats: Double { bufferSeconds * bpm / 60.0 }

    /// Il primo «uno» di battuta di Link non prima di `t`.
    func nextBarTime(atOrAfter t: Double) -> Double {
        let beat = OutputReturnDecision.nextBarBeat(atOrAfter: linkBeat(at: t), quantum: Double(beatsPerBar))!
        return time(ofBeat: beat)
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
        raiseAt = nil
    }

    mutating func silenceNow() {
        volume = 0.0
        apply(.silenced)
    }

    mutating func publishIsPlaying() {
        isPlaying = TransportStateDecision.isPlaying(engineRunning: isRunning)
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

    /// Lo Stop voluto (`stopSync(.wanted)`).
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
        // Lo stato puro, anche fuori da «normale» e dentro un'interruzione.
        if step.raisesMissing {
            apply(.removed)
            cancelReturns()
        }
        if step.lowersMissing { apply(.externalPresent) }
        guard mediaServicesNormal, !systemInterruption else { return }
        // Il Solo si ferma sul principale (`stopForSoloCrisis`, mai da audioQueue): dopo il blocco della coda, cioè dopo i
        // rami della frequenza e del modo qui sotto.
        var deferredSoloStop = false
        if useRouteCrisis {
            if step.silences { silenceNow() }
            if let cause = step.crisisCause {
                switch crisis(cause) {
                case .silentInSong:
                    silentInSong = true
                    if isRunning { crisisStop() }
                case .localStop:
                    crisisStop()
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
                                                    trigger: .outputAdded)
                }
            case .follower?:
                followerReturn = FollowerReturn(noticeAt: t, armPending: true, unoAt: nil, chain: chain, fromTap: false)
            case nil:
                break
            }
        }
        // I rami di oggi: la frequenza, il modo.
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
            if wasRunning { activateSessionAndStart(trigger: .modeChange, at: t) }
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

    /// `restartForRateChangeQ`.
    mutating func restartForRateChange(trigger: RecoveryTrigger, at t: Double) {
        if crisis(.configuration) == .silentInSong { silentInSong = true }
        crisisStop()
        copyRate = hardwareRate
        activateSessionAndStart(trigger: trigger, at: t)
    }

    /// La rilettura del percorso a un rientro automatico (U5).
    mutating func recoveryRead() -> Bool {
        apply(.recoveryRead(externalPresent: externalPresent))
        return state.missing
    }

    /// `activateSessionAndStart`, con le due letture di `RecoveryDecision`.
    mutating func activateSessionAndStart(trigger: RecoveryTrigger, at t: Double) {
        guard mediaServicesNormal else { return }
        let missing = recoveryRead()
        let first = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                           wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause, outputMissing: missing)
        if first == .noRestart {
            noteNoRestart(trigger: trigger, missing: missing)
            return
        }
        if hardwareBusy {
            pendingResume = true
            return
        }
        // La setActive riuscita.
        interrupted = false
        pendingResume = false
        systemInterruption = false
        let second = RecoveryDecision.route(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                            wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause,
                                            outputMissing: recoveryRead())
        if second == .noRestart {
            noteNoRestart(trigger: trigger, missing: state.missing)
            return
        }
        start(at: t, recovery: trigger)
    }

    /// A ogni «niente» per l'uscita mancante (U5): l'interruzione giù se l'hardware è libero, se no la ripresa pendente in piedi.
    mutating func noteNoRestart(trigger: RecoveryTrigger, missing: Bool) {
        let reason = RecoveryDecision.noRestartReason(trigger: trigger, playerRole: role, silentInSong: silentInSong,
                                                      wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause,
                                                      outputMissing: missing)
        guard reason == .outputMissing else { return }
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
        if recovery == nil && role == .direttore {
            apply(.directorPlay(externalPresent: externalPresent))
        }
        // `prepareNormalStartQ`: l'avvio che non passa dal coordinatore azzera causa e Stop voluto.
        if !(role == .direttore && silentInSong) {
            crisisCause = nil
            wantedStop = false
        }
        cancelReturns()
        copyRate = hardwareRate
        // Il coordinatore, prima di `engine.start()`: il bersaglio col margine.
        var target: Double? = nil
        if role == .direttore && silentInSong {
            target = nextBarTime(atOrAfter: t + margin)
        }
        volume = OutputRouteDecision.volumeForStart(playerRole: role, state: state)
        if volume == 0.0 {
            apply(.silenced)
        } else {
            apply(.volumeRestored(externalPresent: externalPresent))
        }
        engineRunning = true
        isRunning = true
        // `engine.start()` riuscito chiude l'interruzione di sistema (A416 · SEGUITO 2).
        systemInterruption = false
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

    /// `scheduleNextBuffer`: la guardia, il motore di sistema fermo (par. 2.2 a), il drenaggio, il misuratore (U7, U8), il
    /// ritorno del Follower (par. 2.2 c), l'assert o la correzione (U9), il buffer.
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
                directorReturn = DirectorReturn(wait: .settle, fireAt: t + OutputReturnDecision.directorSettleSeconds,
                                                trigger: .renderGap)
                return
            case .followLink:
                followsLink = true
            case .lineOnly:
                break
            }
        }
        let outputStart = t + latency + bufferSeconds
        let outputEnd = outputStart + bufferSeconds
        if var pending = followerReturn, pending.armPending {
            let nextOutput = ticks(outputStart)
            let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: nextOutput,
                                                                    queuedAhead: OutputReturnDecision.queuedAheadBuffers,
                                                                    bufferTicks: ticks(bufferSeconds))
            let deadline = pending.fromTap
                ? OutputReturnDecision.tapDeadlineTicks(tapTicks: ticks(pending.noticeAt), ticksPerSecond: OutputRig.tps)
                : OutputReturnDecision.followerDeadlineTicks(noticeTicks: ticks(pending.noticeAt), programmedEndOutputTicks: end,
                                                             ticksPerSecond: OutputRig.tps)
            pending.unoAt = nextBarTime(atOrAfter: seconds(deadline))
            pending.armPending = false
            pending.chain = chain
            followerReturn = pending
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
        if let pending = followerReturn, let uno = pending.unoAt, pending.chain == chain,
           OutputReturnDecision.bufferReachesUno(bufferOutputTicks: ticks(outputStart), bufferTicks: ticks(bufferSeconds),
                                                 unoTicks: ticks(uno)) {
            raiseAt = seconds(OutputReturnDecision.raiseTicks(bufferOutputTicks: ticks(outputStart),
                                                              outputLatencyTicks: ticks(latency), nowTicks: ticks(t)))
            raiseChain = chain
            followerReturn = nil
        }
    }

    /// I richiami a ogni buffer, da `from`, `count` volte.
    mutating func callbacks(from: Double, count: Int, correction: Double? = nil) {
        for i in 0..<count {
            let t = from + Double(i) * bufferSeconds
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

    mutating func fireRaise(at t: Double) {
        raiseAt = nil
        guard isRunning, !systemInterruption, !state.missing, state.muted, raiseChain == chain else { return }
        volume = 1.0
        apply(.volumeRestored(externalPresent: externalPresent))
        raisedAt = t
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

    /// Il tempo passa fino a `t`: le attese scadute scattano nell'ordine.
    mutating func advance(to t: Double) {
        guard t > now else { return }
        while true {
            var due: [(Double, Int)] = []
            if let d = directorReturn, d.fireAt <= t { due.append((d.fireAt, 0)) }
            if let r = raiseAt, r <= t { due.append((r, 1)) }
            if let n = netAt, n <= t { due.append((n, 2)) }
            if let j = rejoin, j.fireAt <= t { due.append((j.fireAt, 3)) }
            guard let next = due.min(by: { $0.0 < $1.0 }) else { break }
            now = max(now, next.0)
            switch next.1 {
            case 0: fireDirectorReturn(at: next.0)
            case 1: fireRaise(at: next.0)
            case 2: fireNet(at: next.0)
            default: fireRejoin(at: next.0)
            }
        }
        now = t
    }

    // MARK: - Interruzioni, servizi, ruolo, tocco, risveglio

    mutating func interruptionBegan(at t: Double) {
        advance(to: t)
        systemInterruption = true
        cancelReturns()
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

    /// La ricostruzione al Play dopo il reset.
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
        if isRunning && state.muted {
            followerReturn = FollowerReturn(noticeAt: t, armPending: true, unoAt: nil, chain: chain, fromTap: true)
        }
    }

    mutating func wakeup(at t: Double) {
        advance(to: t)
        guard TransportStateDecision.wakeupRecovers(engineRunning: isRunning, pendingResume: pendingResume,
                                                    silentInSong: silentInSong, crisisCause: crisisCause) else { return }
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
}

final class OutputCrisisSequenceTests: XCTestCase {

    private let speaker = OutputPort(type: "Speaker", uid: "Speaker")
    private let headphones = OutputPort(type: "Headphones", uid: "Wired Headphones")
    private let bluetooth = OutputPort(type: "BluetoothA2DPOutput", uid: "00:11:22:33:44:55-tacl")
    private let usb = OutputPort(type: "USBAudio", uid: "AppleUSBAudioEngine:Focusrite")

    /// Un rig col click in moto in canzone, sul percorso dato.
    private func playing(_ role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4,
                         at t: Double = 10.0) -> OutputRig {
        var rig = OutputRig(role: role, route: route, bpm: bpm, beatsPerBar: beatsPerBar)
        rig.start(at: t, recovery: nil)
        rig.callbacks(from: t + rig.bufferSeconds, count: 50)
        return rig
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
    /// riparte 684 ms dopo: il volume torna al primo «uno» di Link dopo le due ore, al rendering del suo buffer (U3 c).
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
        XCTAssertGreaterThanOrEqual(uno, deadline)
        let bars = uno / (4 * 60.0 / 121.0)
        XCTAssertEqual(bars, bars.rounded(), accuracy: 1e-6, "un «uno» di battuta di Link")
        rig.callbacks(from: firstCall + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertNotNil(rig.raisedAt)
        XCTAssertLessThanOrEqual(rig.raisedAt!, uno - rig.latency + 1e-9, "prima del rendering dell'«uno»")
        XCTAssertGreaterThanOrEqual(rig.raisedAt!, uno - rig.latency - 2 * rig.bufferSeconds)
        XCTAssertNil(rig.followerReturn)
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

    /// Il Follower dopo la Lost con un ritorno in attesa: nessun riarmo; il volume dopo il reset lo scrive `start()`.
    func testTheFollowerAfterTheLostWithAReturnPendingDoesNotRearm() {
        var rig = playing(.follower, route: [speaker])
        rig.routeChange(at: 11.0, to: [headphones])
        rig.callbacks(from: 11.05, count: 3)
        XCTAssertNotNil(rig.followerReturn)
        rig.servicesLost(at: 11.1)
        XCTAssertNil(rig.followerReturn)
        XCTAssertTrue(rig.isRunning, "il Follower dopo la Lost resta in moto")
        XCTAssertEqual(rig.volume, 0.0)
        rig.routeChange(at: 11.5, to: [speaker])
        XCTAssertTrue(rig.state.missing, "lo stato puro si aggiorna anche coi servizi persi")
        XCTAssertNil(rig.followerReturn)
        rig.rebuiltAndPlay(at: 20.0)
        XCTAssertEqual(rig.volume, 0.0, "il volume lo scrive start(), dallo stato: l'uscita manca")
        rig.routeChange(at: 21.0, to: [headphones])
        rig.callbacks(from: 21.05, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
    }

    /// Il tocco «altoparlante» del Follower (par. 2.2 g): abbassa «uscita mancante» e il volume torna al primo «uno» almeno
    /// 0,3 s dopo il tocco; una tolta dopo rimette la regola.
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
        rig.callbacks(from: 12.01 + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0)
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
}
