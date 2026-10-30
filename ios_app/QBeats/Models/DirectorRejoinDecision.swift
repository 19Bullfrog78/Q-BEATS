import Foundation

// === A410 (16/10/2026) — IL RIENTRO DEL DIRETTORE: COSA FAREBBE, DECISO DA UN TIPO PURO ===
// Il fatto (referto A409, §4 e §6.3-§6.4). Fino ad A411 il Direttore il cui motore ha taciuto senza
// Stop ripartiva, da solo o al primo tocco, dalla battuta 1 della sua sezione, e spostava la griglia
// di tutti. La cura è il rientro: il Direttore legge dove sta la band (`ShowClock`) e rientra al
// prossimo «uno» utile senza scrivere niente su Link. Il passo 1 (A410) ha costruito questa decisione
// e la usava solo per scrivere nel registro cosa farebbe.
// ⚠️ A412 (18/10/2026) — DA QUI LA DECISIONE AGISCE (mandato «DIRETTORE-IN-CRISI-PASSO-2», §2.2). Il
//    coordinatore sta nel motore, su audioQueue, dentro `AudioEngine.start()`: col Direttore muto in
//    canzone ogni avvio (le ripartenze automatiche, il tocco della fascia, il pedale, il debug) passa
//    da `coordinate(clock:situation:)`, e l'esito decide: rientra (ingresso al bersaglio, senza
//    scrivere su Link), canzone finita (Stop di fine canzone, solo col conto certo), non certo (resta
//    muto, nessuno Stop), sessione ferma da altri (velo della stessa canzone, nessun avvio). Senza
//    àncora il Direttore muto è non certo (`Uncertain.noAnchor`). All'armamento del primo buffer
//    mappa e ponte si rileggono (`armingCheck`): oltre 1/8 di battito il rientro diventa non certo.
//
// Gli esiti:
//  · rientra: sezione, battuta e battito di Link del bersaglio. L'ora la dà la mappa
//    (`ShowClock.ticks(section:beatInSection:ticksPerSecond:)`); il ponte (`link_engine_time_at_beat`) è
//    il controllo (A412: fino ad A410 l'ora veniva dal solo ponte, che ignora un cambio di tempo fra la
//    decisione e il bersaglio: collaudo A410, prova P4, 0,40 s);
//  · canzone finita: solo se il conto è certo (D1, decisione di Mauro del 16/10/2026: lo Stop di
//    fine canzone lo manda il telefono del Direttore, solo con un conteggio certo). `alreadyOver`
//    falso = la canzone non è ancora finita ma finisce prima del primo «uno» utile;
//  · non certo: resta muto solo il click del Direttore, gli iPad continuano, NESSUNO Stop (D4 = (a),
//    decisione di Mauro del 16/10/2026 come corretta dal referee);
//  · sessione ferma da altri: la sessione Link non suona (scelta T6 del referee: il Direttore resta
//    muto sul velo della stessa canzone, con una riga di registro, e non avvia niente);
//  · fuori dal coordinatore: chi non è Direttore (Solo, Follower, Direttore con Link spento
//    dall'utente: la regola di `DirectorSongCloseDecision.closesSongOnStop`), show chiuso, nessuna
//    àncora. Il Solo e il Follower non entrano MAI nel coordinatore.
//
// Le regole d'ingresso (progetto A376, §2.2-§2.3):
//  · STESSO AVVIO giudicato in battiti (P6): il battito dell'avvio della sessione letto all'àncora e
//    adesso, con la tolleranza di un ottavo di battito (P7). ⚠️ RISCRITTO A412 · SEGUITO 2 (18/10/2026).
//    Il testo di prima diceva «il battito dell'avvio della sessione (quantum 1) letto all'àncora e adesso
//    […] L'ora dell'avvio si sposta quando la griglia viene forzata; il battito, se la sessione tiene
//    l'avvio in battiti, no. È un'ipotesi di A376 da misurare: il passo 1 la scrive nel registro». Il
//    collaudo di A412 delle 16:24 l'ha misurata: a quantum 1 la parte intera è dell'apparecchio, e un
//    cambio di tempo fatto da un altro può rinumerarla di un battito intero con la sessione ferma
//    (`ABLLink.h:280-286`; mandato «A412 · SEGUITO 2», par. 2). Il battito si legge ora nella
//    numerazione della sessione (`sessionQuantum`), che non salta; l'ora dell'avvio si sposta anche a
//    ogni cambio di tempo (la sessione tiene l'avvio in battiti), il battito no;
//  · MARGINE: il bersaglio cade almeno `marginSeconds` dopo adesso (A376 P9: 150 ms), contati al
//    tempo della sessione;
//  · FINESTRA DEL CAMBIO DI SEZIONE (P6; LIBRO 2026-09-20 «RIENTRO A METÀ CANZONE CHE CADE SUL
//    CAMBIO DI SEZIONE: SI ASPETTA UNA BATTUTA E SI ENTRA GIUSTO»): un «uno» che cade entro
//    `windowSeconds` dall'inizio della sua sezione — i 100 buffer in cui, dopo lo scambio di sezione,
//    il motore non corregge la fase — non è un bersaglio: si passa alla battuta dopo, finché serve.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.
enum DirectorRejoinDecision {

    /// Tolleranza del giudice «stesso avvio»: un ottavo di battito (A376 P7).
    static let sameStartToleranceBeats: Double = 0.125
    /// Oltre questi spostamenti per la finestra il bersaglio non si trova (rete di sicurezza: con
    /// battute più lunghe della finestra ne basta uno).
    static let maxWindowShifts: Int = 1024

    /// Perché il Direttore non passa dal coordinatore.
    enum NotCoordinated: Equatable {
        /// Solo, Follower, o ruolo Direttore con Link spento dall'utente.
        case notDirector
        case showClosed
        /// Nessuna àncora: il motore non ha taciuto senza Stop.
        case noAnchor
    }

    /// Perché il conto non basta per decidere: resta muto, nessuno Stop.
    enum Uncertain: Equatable {
        /// Il ponte di Link è spento: la sessione non si legge.
        case linkOff
        /// L'avvio della sessione non è più quello dell'àncora.
        case startChanged
        /// Il conto non dà un posto (un ciclo, valori non validi).
        case clock(ShowClockUnknown)
        /// I due righelli si discostano oltre la tolleranza.
        case rulersDisagree
        /// La finestra non si chiude entro `maxWindowShifts` battute.
        case noTarget
        /// A412 — Direttore muto in canzone senza àncora (A410: «ancora non presa»): il conto non è
        /// certo (mandato §2, «Parole»).
        case noAnchor
        /// A412 — all'armamento del primo buffer l'ora della mappa e quella del ponte distano più di
        /// 1/8 di battito al tempo della sezione d'arrivo (`armingCheck`, scelta T2).
        case mapBridgeDisagree
        /// A412 — il blocco dell'armamento gira in ritardo sul bersaglio più volte di fila
        /// (`maxLateSkips`): nessun ingresso.
        case lateTooManyTimes
    }

    enum Outcome: Equatable {
        case notCoordinated(NotCoordinated)
        /// Rientra al bersaglio: sezione (da 0), battuta (da 1), battito di Link.
        case rejoin(section: Int, bar: Int, linkBeat: Double)
        /// Canzone finita (solo con un conto certo): il battito di Link della fine.
        case songEnded(endLinkBeat: Double, alreadyOver: Bool)
        case uncertain(Uncertain)
        case sessionStoppedElsewhere

        /// Manderebbe uno Stop alla band: solo la canzone finita (D1, con un conto certo).
        var wouldSendStop: Bool {
            if case .songEnded = self { return true }
            return false
        }

        /// Farebbe partire il motore: solo il rientro.
        var wouldStartEngine: Bool {
            if case .rejoin = self { return true }
            return false
        }
    }

    /// Quello che il motore sa adesso, su audioQueue.
    struct Situation: Equatable {
        let role: LinkMode
        let userLinkEnabled: Bool
        let showOpen: Bool
        /// Il ponte di Link acceso (`enabled_`): la sessione si legge.
        let linkEnabled: Bool
        /// La sessione Link suona (`ABLLinkIsPlaying`).
        let sessionPlaying: Bool
        /// Il giudice «stesso avvio» (`sameStart(anchorStartBeat:nowStartBeat:)`).
        let sameStart: Bool
        /// Il battito di Link di adesso, nella numerazione dell'àncora del conto, e l'ora di adesso.
        /// ⚠️ RISCRITTO A412 · SEGUITO 2: diceva «(quantum 1)»; il motore passa ora il battito nella
        /// numerazione della sessione (`sessionQuantum`). Il tipo non lo sa: confronta battiti della
        /// stessa numerazione.
        let nowLinkBeat: Double
        let nowTicks: UInt64
        let ticksPerSecond: Double
        /// Il tempo della sessione; se non è valido il margine si conta col tempo della mappa.
        let sessionTempo: Double
        let marginSeconds: Double
        let windowSeconds: Double
    }

    /// L'esito, la lettura del conto (se c'è stata) e quante battute ha spostato la finestra.
    struct Plan: Equatable {
        let outcome: Outcome
        let reading: ShowClockReading?
        let windowShifts: Int
    }

    /// L'àncora si prende? Il motore del Direttore (ruolo Direttore, Link acceso dall'utente) tace
    /// senza Stop a show aperto, mentre era in moto, e la mappa della canzone c'è (mandato A410 §2.3).
    static func takesAnchor(role: LinkMode, userLinkEnabled: Bool, showOpen: Bool,
                            engineRunning: Bool, hasSongMap: Bool) -> Bool {
        DirectorSongCloseDecision.closesSongOnStop(role: role, userLinkEnabled: userLinkEnabled)
            && showOpen && engineRunning && hasSongMap
    }

    /// Il giudice «stesso avvio», in battiti: il battito dell'avvio letto all'àncora e adesso, dentro la
    /// tolleranza. Un valore non finito non è lo stesso avvio. ⚠️ RISCRITTO A412 · SEGUITO 2: diceva «il
    /// battito dell'avvio (quantum 1)»; i due battiti vanno letti nella stessa numerazione, e il motore
    /// passa ora quella della sessione (`sessionQuantum`, `deviceOffset`).
    static func sameStart(anchorStartBeat: Double, nowStartBeat: Double,
                          toleranceBeats: Double = sameStartToleranceBeats) -> Bool {
        guard anchorStartBeat.isFinite, nowStartBeat.isFinite, toleranceBeats.isFinite, toleranceBeats >= 0 else {
            return false
        }
        return abs(nowStartBeat - anchorStartBeat) <= toleranceBeats
    }

    /// La decisione. L'ordine è la precedenza: chi è fuori dal coordinatore non legge niente; poi il
    /// ponte, la sessione ferma, l'avvio cambiato; poi il conto (non so, righelli in disaccordo);
    /// poi la fine; poi il bersaglio col margine e la finestra.
    static func plan(clock: ShowClock?, situation: Situation) -> Plan {
        guard DirectorSongCloseDecision.closesSongOnStop(role: situation.role,
                                                         userLinkEnabled: situation.userLinkEnabled) else {
            return Plan(outcome: .notCoordinated(.notDirector), reading: nil, windowShifts: 0)
        }
        guard situation.showOpen else {
            return Plan(outcome: .notCoordinated(.showClosed), reading: nil, windowShifts: 0)
        }
        guard let clock else {
            return Plan(outcome: .notCoordinated(.noAnchor), reading: nil, windowShifts: 0)
        }
        guard situation.linkEnabled else {
            return Plan(outcome: .uncertain(.linkOff), reading: nil, windowShifts: 0)
        }
        guard situation.sessionPlaying else {
            return Plan(outcome: .sessionStoppedElsewhere, reading: nil, windowShifts: 0)
        }
        guard situation.sameStart else {
            return Plan(outcome: .uncertain(.startChanged), reading: nil, windowShifts: 0)
        }
        let reading = clock.read(nowLinkBeat: situation.nowLinkBeat,
                                 nowTicks: situation.nowTicks,
                                 ticksPerSecond: situation.ticksPerSecond)
        switch reading.outcome {
        case .unknown(let why):
            return Plan(outcome: .uncertain(.clock(why)), reading: reading, windowShifts: 0)
        case .songEnded(let endLinkBeat, _):
            guard reading.certain else {
                return Plan(outcome: .uncertain(.rulersDisagree), reading: reading, windowShifts: 0)
            }
            return Plan(outcome: .songEnded(endLinkBeat: endLinkBeat, alreadyOver: true),
                        reading: reading, windowShifts: 0)
        case .inSong(let section, _, _, _):
            guard reading.certain else {
                return Plan(outcome: .uncertain(.rulersDisagree), reading: reading, windowShifts: 0)
            }
            let tempo = (situation.sessionTempo.isFinite && situation.sessionTempo > 0)
                ? situation.sessionTempo
                : clock.map.sections[section].bpm
            let marginSeconds = (situation.marginSeconds.isFinite && situation.marginSeconds > 0)
                ? situation.marginSeconds : 0
            var search = clock.downbeat(atOrAfterLinkBeat: situation.nowLinkBeat + marginSeconds * tempo / 60.0)
            var shifts = 0
            while case .found(let candidate) = search,
                  clock.secondsIntoSection(candidate) < situation.windowSeconds {
                shifts += 1
                guard shifts <= maxWindowShifts else {
                    return Plan(outcome: .uncertain(.noTarget), reading: reading, windowShifts: shifts)
                }
                // Mezzo battito dopo questo «uno»: il prossimo inizio di battuta.
                search = clock.downbeat(atOrAfterLinkBeat: candidate.linkBeat + 0.5)
            }
            switch search {
            case .found(let target):
                return Plan(outcome: .rejoin(section: target.section, bar: target.bar, linkBeat: target.linkBeat),
                            reading: reading, windowShifts: shifts)
            case .songEndsFirst:
                return Plan(outcome: .songEnded(endLinkBeat: clock.endLinkBeat ?? situation.nowLinkBeat,
                                                alreadyOver: false),
                            reading: reading, windowShifts: shifts)
            case .unknown(let why):
                return Plan(outcome: .uncertain(.clock(why)), reading: reading, windowShifts: shifts)
            }
        }
    }

    // MARK: - A412 — il coordinatore che agisce (mandato §2.2 e §2.3)

    /// Il coordinatore chiede solo per un Direttore muto in canzone. È `plan(clock:situation:)` con una
    /// differenza: senza àncora (`clock` `nil`) il Direttore a show aperto è «non certo», non «fuori dal
    /// coordinatore» (mandato §2, «Parole»: senza àncora il Direttore è muto in canzone lo stesso, e il
    /// conto è non certo).
    static func coordinate(clock: ShowClock?, situation: Situation) -> Plan {
        let result = plan(clock: clock, situation: situation)
        if case .notCoordinated(.noAnchor) = result.outcome {
            return Plan(outcome: .uncertain(.noAnchor), reading: nil, windowShifts: 0)
        }
        return result
    }

    /// Quante volte di fila il blocco dell'armamento può girare in ritardo, saltando ogni volta al primo
    /// «uno» successivo, prima che il rientro diventi non certo (LIBRO 2026-09-20 «MOTORE IN RITARDO SUL
    /// BERSAGLIO: SI SALTA AL BERSAGLIO SUCCESSIVO»).
    static let maxLateSkips: Int = 4

    /// L'anticipo minimo fra il blocco dell'armamento e l'ora chiesta al primo buffer: sotto, il lettore
    /// lo suonerebbe in ritardo. 30 ms: circa tre cicli d'uscita da 512 campioni a 48 kHz.
    static let minLeadSeconds: Double = 0.030

    /// Il controllo mappa-ponte all'armamento (mandato §2.2, scelta T2).
    struct ArmingCheck: Equatable {
        /// Ora della mappa meno ora del ponte, in secondi; `nil` se una delle due manca.
        let gapSeconds: Double?
        /// Lo stesso scarto in battiti, al tempo della sezione d'arrivo; `nil` se non si può contare.
        let gapBeats: Double?
        /// Le due ore ci sono e distano al più la tolleranza.
        let agree: Bool
    }

    /// L'ora della mappa e quella del ponte (0 = ponte spento) dello stesso «uno», al tempo della sezione
    /// d'arrivo: d'accordo se distano al più `toleranceBeats` (1/8 di battito, T2).
    static func armingCheck(mapTicks: UInt64?, bridgeTicks: UInt64, sectionBPM: Double,
                            ticksPerSecond: Double,
                            toleranceBeats: Double = ShowClock.defaultToleranceBeats) -> ArmingCheck {
        guard let mapTicks, bridgeTicks > 0, ticksPerSecond > 0, ticksPerSecond.isFinite else {
            return ArmingCheck(gapSeconds: nil, gapBeats: nil, agree: false)
        }
        let seconds: Double = mapTicks >= bridgeTicks
            ? Double(mapTicks - bridgeTicks) / ticksPerSecond
            : -Double(bridgeTicks - mapTicks) / ticksPerSecond
        guard sectionBPM > 0, sectionBPM.isFinite else {
            return ArmingCheck(gapSeconds: seconds, gapBeats: nil, agree: false)
        }
        let beats = seconds * sectionBPM / 60.0
        return ArmingCheck(gapSeconds: seconds, gapBeats: beats,
                           agree: beats.isFinite && abs(beats) <= toleranceBeats)
    }

    /// L'ora in cui il lettore comincia il primo buffer: l'ora d'uscita del bersaglio meno la latenza
    /// d'uscita (un campione esce all'ora del suo ciclo più la latenza, come in
    /// `AudioEngine.nextBufferOutputHostTime`). Si ferma a zero.
    static func firstBufferRenderTicks(targetOutputTicks: UInt64, outputLatencyTicks: UInt64) -> UInt64 {
        targetOutputTicks >= outputLatencyTicks ? targetOutputTicks - outputLatencyTicks : 0
    }

    /// L'ora dell'armamento: `marginSeconds` (150 ms, A376 P9) prima dell'ora d'uscita del bersaglio.
    static func armingTicks(targetOutputTicks: UInt64, marginSeconds: Double, ticksPerSecond: Double) -> UInt64 {
        ShowClock.ticks(targetOutputTicks, plusSeconds: -max(marginSeconds, 0), ticksPerSecond: ticksPerSecond)
    }

    /// Il blocco dell'armamento è in ritardo: adesso più l'anticipo minimo supera l'ora chiesta al primo
    /// buffer (LIBRO 2026-09-20: mai un click in ritardo, si salta al bersaglio successivo).
    static func isLate(nowTicks: UInt64, renderTicks: UInt64, minLeadTicks: UInt64) -> Bool {
        let (sum, overflow) = nowTicks.addingReportingOverflow(minLeadTicks)
        return overflow || sum > renderTicks
    }

    // MARK: - A421 · SEGUITO 2 (30/10/2026) — IL MARGINE CON LE USCITE LENTE E IL LETTORE LENTO (mandato «A421 · SEGUITO 2», par. 2.2)
    //
    // Il fatto (par. 2.1, collaudo del 29-30/10). Con la cassa Bluetooth la distanza fra l'ora d'uscita del bersaglio e l'ora
    // chiesta al lettore per il primo buffer (la scorta muta più la latenza della cassa) era 169,6 ms, e l'armamento a 150 ms
    // prima dell'ora d'uscita girava 20,8 ms DOPO l'ora chiesta: cinque fuochi in ritardo di fila e «non-certo(ritardo-oltre-i-
    // salti)»; con le cuffie col filo (56,0 ms) e l'altoparlante (65,9 ms) il fuoco arrivava con 82-91 ms d'anticipo. E dopo una
    // chiamata il lettore è partito in 684,9 ms con un bersaglio a 413,1 ms dalla decisione: un salto consumato per un ritardo
    // che era già certo all'armamento. Da qui il margine è max(150 ms, D + 80 ms), con D la distanza del primo buffer letta
    // dalla sessione in quel momento; e un bersaglio non raggiungibile già all'armamento si arma per adesso col segno
    // «lettore-lento»: al fuoco in ritardo il coordinatore riceve l'innesco «lettore-lento» senza consumare un salto.

    /// Il margine di base del bersaglio e dell'armamento (A376 P9: 150 ms). Fino al seguito 2 era il margine fisso
    /// (`AudioEngine.kRejoinMarginSeconds`).
    static let baseMarginSeconds: Double = 0.150
    /// La riserva sopra la distanza del primo buffer: l'anticipo minimo di oggi (30 ms) più 50 ms per il timer (al più 1,6 ms
    /// nei 24 fuochi del 29-30/10), la coda occupata e una latenza al fuoco diversa da quella letta prima.
    static let marginReserveSeconds: Double = 0.080

    /// D: la distanza fra l'ora d'uscita del bersaglio e l'ora chiesta al lettore per il primo buffer — la scorta intera
    /// (`leadInBuffers` per il buffer del lettore) più la latenza d'uscita, con la latenza (`outputLatency`) e il ciclo d'uscita
    /// (`ioBufferDuration`) letti dalla sessione in quel momento e non dalle copie, che `start()` rinfresca dopo. Senza una
    /// scorta possibile (valori non validi) resta la sola latenza; una latenza non valida vale zero.
    static func firstBufferDistanceSeconds(bufferSeconds: Double, ioBufferSeconds: Double, outputLatencySeconds: Double) -> Double {
        let latency = (outputLatencySeconds.isFinite && outputLatencySeconds > 0) ? outputLatencySeconds : 0
        guard let buffers = leadInBuffers(bufferSeconds: bufferSeconds, ioBufferSeconds: ioBufferSeconds) else { return latency }
        return Double(buffers) * bufferSeconds + latency
    }

    /// Il margine del bersaglio e dell'armamento: max(150 ms, D + 80 ms). Sull'iPhone con le cuffie col filo (56,0 + 80 = 136,0)
    /// e con l'altoparlante (65,9 + 80 = 145,9) resta 150 ms; con la cassa del 29/10 (169,6) è 249,6 ms. Con una distanza non
    /// valida resta il margine di base.
    static func rejoinMarginSeconds(firstBufferDistanceSeconds distance: Double) -> Double {
        guard distance.isFinite, distance > 0 else { return baseMarginSeconds }
        return max(baseMarginSeconds, distance + marginReserveSeconds)
    }

    /// Il bersaglio non raggiungibile già all'armamento (par. 2.2 b): adesso più l'anticipo minimo supera l'ora d'uscita del
    /// bersaglio meno D (la disuguaglianza di `isLate`), cioè il fuoco sarebbe in ritardo comunque. Allora si arma per adesso
    /// (attesa zero) col segno «lettore-lento»; al fuoco, se è in ritardo per le copie, il ramo del ritardo va al coordinatore
    /// con l'innesco «lettore-lento», con lo stesso conto dei salti e senza la guardia dei salti esauriti; il bersaglio scelto
    /// così si arma senza questo controllo. Se al fuoco non è in ritardo, il fuoco è quello di oggi.
    static func slowPlayerAtArming(nowTicks: UInt64, targetOutputTicks: UInt64, distanceTicks: UInt64, minLeadTicks: UInt64) -> Bool {
        let renderTicks = targetOutputTicks >= distanceTicks ? targetOutputTicks - distanceTicks : 0
        return isLate(nowTicks: nowTicks, renderTicks: renderTicks, minLeadTicks: minLeadTicks)
    }

    /// A412 — LO STOP DI FINE CANZONE (mandato §2.3, D1): l'ora a cui il telefono del Direttore lo manda.
    /// Mai prima della fine: la più tarda fra l'ora della mappa e quella del ponte (0 = ponte spento),
    /// più `marginBeats` (1/8 di battito, la tolleranza di T2) al tempo dell'ultima sezione. `nil` se
    /// una delle due ore manca o i valori non sono validi: allora nessuno Stop automatico.
    static func songEndStopTicks(mapEndTicks: UInt64?, bridgeEndTicks: UInt64, lastSectionBPM: Double,
                                 ticksPerSecond: Double,
                                 marginBeats: Double = ShowClock.defaultToleranceBeats) -> UInt64? {
        guard let mapEndTicks, bridgeEndTicks > 0,
              ticksPerSecond > 0, ticksPerSecond.isFinite,
              lastSectionBPM > 0, lastSectionBPM.isFinite,
              marginBeats >= 0, marginBeats.isFinite else { return nil }
        let later = max(mapEndTicks, bridgeEndTicks)
        return ShowClock.ticks(later, plusSeconds: marginBeats * 60.0 / lastSectionBPM,
                               ticksPerSecond: ticksPerSecond)
    }

    // MARK: - A412 · SEGUITO 2 — la numerazione della sessione (mandato «A412 · SEGUITO 2», par. 3)

    /// Il quantum della numerazione della sessione. Il battito di Link con questo quantum
    /// (`ABLLinkBeatAtTime(state, t, 1e6)`) è il battito contato dallo zero della sessione: la sua fase
    /// rispetto a 1e6, cioè il valore stesso finché sta fra 0 e un milione, è condivisa da tutti
    /// (`ABLLink.h:280-286`), e un cambio di tempo fatto da un altro non lo rinumera. Col quantum 1 invece
    /// la parte intera è dell'apparecchio: il collaudo di A412 delle 16:24 l'ha vista saltare di un
    /// battito intero con la sessione ferma (letture all'ora dell'avvio, a quantum 1, 1e6 e 0: 3,4158 →
    /// 2,4158, 1917,4158 → 1917,4158, 2,9245 → 2,9151). L'àncora, i due righelli, «stesso avvio», il
    /// bersaglio, il ponte alla decisione e all'armamento e la fine canzone leggono Link in questa
    /// numerazione (`link_engine_read_session_at`, campi `…QBig`; `link_engine_time_at_beat` con questo
    /// quantum, l'inversa a tempo costante, `ABLLink.h:292-299`). È lo stesso 1e6 di
    /// `link_engine_read_start_stamp` e del 2D (`link_engine_read_transport_snapshot`), che la leggono già
    /// come fase. Il battito che semina il motore al rientro resta col quantum della sezione d'arrivo: la
    /// correzione di fase lo confronta per fase, non per parte intera.
    static let sessionQuantum: Double = 1.0e6

    /// Quanto la numerazione dell'apparecchio (quantum 1) dista da quella della sessione, dalle due letture
    /// della STESSA cattura: un intero, perché le due letture hanno la stessa fase rispetto a 1
    /// (`ABLLink.h:280-286`). Serve alle righe di registro, per scrivere un battito della sessione anche
    /// nella numerazione di prima, accanto. Cambia di uno quando la numerazione dell'apparecchio salta:
    /// −1914 → −1915 alle 16:24. `nil` se una delle due non è finita.
    static func deviceOffset(beatQuantumOne: Double, beatSession: Double) -> Double? {
        guard beatQuantumOne.isFinite, beatSession.isFinite else { return nil }
        return (beatQuantumOne - beatSession).rounded()
    }

    // MARK: - A412 · SEGUITO 2 (2/2) — la scorta muta del rientro (mandato «A412 · SEGUITO 2 (2/2)», par. 2)
    //
    // Il fatto (collaudo di A412 del 18/10/2026, referto del seguito 2, §4.1): il primo buffer del rientro usciva
    // all'ora della mappa, e la correzione di fase, che dal quarto buffer tiene la griglia con la sua convenzione
    // d'ora («adesso + latenza + un buffer d'I/O»), lo spostava indietro di 0,044 battiti a 100 BPM e 0,057 a 110: il
    // primo click usciva 26-31 ms in anticipo sulla griglia di dopo. Quanto, dipende da quando il lettore consuma il
    // primo buffer, che si sa solo dopo averlo accodato. La strada scelta dal referee (B): il motore riparte qualche
    // buffer prima, MUTO; la prima correzione cade su un buffer che non suona, e l'«uno» esce dove lei lo tiene.
    // Le regole qui sotto: quanti buffer muti, l'ora del primo, il seme del motore, quando la correzione gira e
    // quando il MIDI tace. Il motore (`AudioEngine.fireDirectorRejoinQ`, `scheduleNextBuffer`) le legge.

    /// I buffer che il fuoco del rientro accoda senza correzione di fase (`linkSyncSkipBuffers` del fuoco): la
    /// prima correzione arriva sul buffer dopo, accodato quando il lettore consuma il primo.
    static let uncorrectedFireBuffers: Int = 3

    /// Quanti buffer muti davanti all'«uno». La prima correzione in avanti più grande possibile è minore di un
    /// buffer d'I/O: il buffer che la riceve si accoda prima che il lettore lo renda, e la convenzione gli dà
    /// l'ora «adesso + latenza + un buffer d'I/O» (`AudioEngine.scheduleNextBuffer`), quindi la sua ora secondo la
    /// convenzione supera quella vera al più di un buffer d'I/O meno l'anticipo del rendering (misurato 21,8-22,3
    /// ms: di fatto la prima correzione è sempre all'indietro). Perché non scavalchi mai l'«uno» (il DSP lo farebbe
    /// uscire subito, in ritardo: `MetronomeDSP.cpp:351-353`), all'inizio del buffer della prima correzione l'«uno»
    /// deve stare davanti di PIÙ di un buffer d'I/O: i buffer senza correzione, più ⌊I/O ÷ buffer⌋ + 1. Lo 0,01
    /// assorbe l'arrotondamento in tick dell'I/O (255999 contro 256000). Col buffer d'I/O di 512 campioni
    /// (`setPreferredIOBufferDuration`) sono 5 buffer, 53,3 ms. `nil` con valori non validi.
    static func leadInBuffers(bufferSeconds: Double, ioBufferSeconds: Double) -> Int? {
        guard bufferSeconds > 0, bufferSeconds.isFinite, ioBufferSeconds >= 0, ioBufferSeconds.isFinite else {
            return nil
        }
        let ratio = ioBufferSeconds / bufferSeconds + 0.01
        guard ratio < 1_000 else { return nil }
        return uncorrectedFireBuffers + Int(ratio.rounded(.down)) + 1
    }

    /// La scorta di un rientro.
    struct LeadIn: Equatable {
        /// Buffer muti davanti all'«uno».
        let buffers: Int
        /// L'ora d'uscita del primo buffer muto: l'ora del bersaglio meno la scorta.
        let firstBufferOutputTicks: UInt64
        /// L'ora chiesta al lettore per il primo buffer muto (`scheduleBuffer(_:at:)`): quella d'uscita meno la latenza.
        let firstBufferRenderTicks: UInt64
        /// La posizione del motore (metronomo e MIDI) al primo campione: l'«uno» meno la scorta in battiti.
        let seedBeat: Double
        /// L'«uno»: il battito di Link all'ora del bersaglio, col quantum della sezione d'arrivo (l'origine dei click).
        let unoBeat: Double
        /// La scorta in battiti, al tempo della sezione d'arrivo.
        let beats: Double
    }

    /// La scorta per un bersaglio. L'«uno» resta il battito pendente del metronomo: la scorta sta sotto mezzo
    /// battito (il DSP riporta il battito pendente arrotondando, `MetronomeDSP.cpp:337-339`) e il seme non è
    /// negativo (sotto zero il DSP non si sposta, `:313`). Se una delle due non regge, `nil`: il motore entra come
    /// prima, col primo buffer all'ora del bersaglio.
    static func leadIn(targetOutputTicks: UInt64, outputLatencyTicks: UInt64, unoBeat: Double, bpm: Double,
                       bufferFrames: Int, sampleRate: Double, ioBufferSeconds: Double,
                       ticksPerSecond: Double) -> LeadIn? {
        guard bufferFrames > 0, sampleRate > 0, sampleRate.isFinite, bpm > 0, bpm.isFinite, unoBeat.isFinite,
              ticksPerSecond > 0, ticksPerSecond.isFinite else { return nil }
        let bufferSeconds = Double(bufferFrames) / sampleRate
        guard let buffers = leadInBuffers(bufferSeconds: bufferSeconds, ioBufferSeconds: ioBufferSeconds) else {
            return nil
        }
        let seconds = Double(buffers) * bufferSeconds
        let beats = seconds * bpm / 60.0
        guard beats < 0.5, unoBeat - beats >= 0 else { return nil }
        let leadTicks = seconds * ticksPerSecond
        guard Double(targetOutputTicks) > leadTicks else { return nil }
        let firstOutput = ShowClock.ticks(targetOutputTicks, plusSeconds: -seconds, ticksPerSecond: ticksPerSecond)
        return LeadIn(buffers: buffers,
                      firstBufferOutputTicks: firstOutput,
                      firstBufferRenderTicks: firstBufferRenderTicks(targetOutputTicks: firstOutput,
                                                                     outputLatencyTicks: outputLatencyTicks),
                      seedBeat: unoBeat - beats,
                      unoBeat: unoBeat,
                      beats: beats)
    }

    /// Dove sta l'«uno», in battiti dall'inizio del buffer della prima correzione, dopo una prima correzione di
    /// `correctionBeats` (positiva = in avanti, la posizione del motore portata avanti). Negativo = la correzione
    /// l'ha scavalcato (il DSP lo farebbe uscire subito, in ritardo). `bufferBeats`: un buffer in battiti.
    static func unoAheadAfterFirstCorrection(_ leadIn: LeadIn, bufferBeats: Double, correctionBeats: Double) -> Double {
        Double(leadIn.buffers - uncorrectedFireBuffers) * bufferBeats - correctionBeats
    }

    /// Durante la scorta la correzione di fase gira una volta sola, la prima: è quella che la scorta copre. Le
    /// correzioni di regime ripartono col buffer dopo l'«uno» (una di regime nella scorta, con l'«uno» appena
    /// dopo l'inizio di un buffer, lo scavalcherebbe di qualche decimo di ms).
    static func leadInAllowsCorrection(correctionsSoFar: Int) -> Bool {
        correctionsSoFar == 0
    }

    /// Durante la scorta il MIDI (il clock e il pattern, `midi_engine_process`) tace finché l'«uno» non cade nel
    /// buffer: i buffer prima hanno la posizione di prima della correzione, e quelli dopo la ripasserebbero. Tace se
    /// l'«uno» viene dopo la fine del buffer che comincia a `bufferStartBeat`.
    static func leadInHoldsMIDI(bufferStartBeat: Double, bufferBeats: Double, unoBeat: Double) -> Bool {
        guard bufferStartBeat.isFinite, bufferBeats.isFinite, unoBeat.isFinite else { return false }
        return unoBeat >= bufferStartBeat + bufferBeats
    }
}
