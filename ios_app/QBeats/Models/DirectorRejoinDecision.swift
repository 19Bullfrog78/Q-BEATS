import Foundation

// === A410 (16/10/2026) — IL RIENTRO DEL DIRETTORE: COSA FAREBBE, DECISO DA UN TIPO PURO ===
// Il fatto (referto A409, §4 e §6.3-§6.4). Oggi il Direttore il cui motore ha taciuto senza Stop
// riparte, da solo o al primo tocco, dalla battuta 1 della sua sezione, e sposta la griglia di
// tutti. La cura (passo 2) è il rientro: il Direttore legge dove sta la band (`ShowClock`) e rientra
// al prossimo «uno» utile senza scrivere niente su Link. Il passo 1 (mandato A410, §2.5) costruisce
// questa decisione e la usa SOLO per scrivere nel registro cosa farebbe: `AudioEngine.start()`
// continua identico a oggi.
//
// Gli esiti:
//  · rientra: sezione, battuta e battito di Link del bersaglio (l'ora la chiede il motore al ponte,
//    `link_engine_time_at_beat`);
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
//  · STESSO AVVIO giudicato in battiti (P6): il battito dell'avvio della sessione (quantum 1) letto
//    all'àncora e adesso, con la tolleranza di un ottavo di battito (P7). L'ora dell'avvio si sposta
//    quando la griglia viene forzata; il battito, se la sessione tiene l'avvio in battiti, no. È
//    un'ipotesi di A376 da misurare: il passo 1 la scrive nel registro;
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
        /// Il battito di Link di adesso (quantum 1) e l'ora di adesso.
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

    /// Il giudice «stesso avvio», in battiti: il battito dell'avvio (quantum 1) letto all'àncora e
    /// adesso, dentro la tolleranza. Un valore non finito non è lo stesso avvio.
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
}
