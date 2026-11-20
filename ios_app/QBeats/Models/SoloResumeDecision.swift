import Foundation

// === A437 (18/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3b: LA RIPRESA DEL SOLO SULLA POSIZIONE DELLA CANZONE ===
// Il fatto (BUGS, `TD-accento-e-grafica-dopo-una-ripartenza-automatica`, la (b); collaudo del 17/11, referto A435
// par. 9.1). Nel Solo, a canzone in corso, quando il click si ferma da solo (le cuffie o una cassa attaccate, la
// scheda USB, un cambio della configurazione audio, il motore fermato dal sistema) il motore ripartiva dal battito
// dov'era rimasto: il click tornava spostato rispetto alla canzone, con accento e grafica fuori posto (il 17/11, con
// le cuffie col filo, un buco di 848,6 ms e poi il click in ritardo).
//
// La regola (referto A424, par. 3.1 b, 3.2 e 2.1 a-l; mandato A437, par. 2 e 3; LIBRO, la «B» di Mauro del 24/10 e
// la «A» del 02/11):
//  · L'ÀNCORA. Alla crisi, prima di fermare il motore, si prende un battito contato già uscito (sezione, battito
//    nella sezione, la sua ora). L'ora vera è quella della convenzione più Δ, la mediana delle ultime letture valide
//    fatte a regime prima della crisi (`delta`); con meno di tre letture Δ = 0 e la lettura è «riserva»;
//  · IL CONTO. Dall'àncora, col solo righello dei secondi sulla mappa (`ShowClock`), si cerca il primo «uno» di
//    battuta con l'ora non prima di adesso più il margine (`plan`): il click tace e torna lì, sulla battuta giusta.
//    Il Solo non ha Link: niente qui lo legge (il lucchetto, `SoloInertDecision`);
//  · CANZONE FINITA: se la canzone finisce prima di quel primo «uno», il runner arma la successiva e niente parte;
//  · NON CERTO: senza àncora, con un ciclo sul cammino o una mappa non valida, il Solo si ferma come allo Stop della
//    sua console e aspetta il Play (Mauro, 02/11, la «A»). Mai un click in ritardo (LIBRO 2026-09-20): il fuoco in
//    ritardo salta al bersaglio dopo coi salti contati (`lateStep`), poi si ferma come allo Stop;
//  · LA PAUSA. Fra l'arresto e il fuoco riuscito il Solo è «in moto per il player» col motore fermo: lo dice un
//    segno a parte (`pending`), e `isPlaying` resta lo specchio del motore (decisione del referee su P22, la (b)).
// La vita della ripresa (`lifecycle`) ha nascita e fine scritte: nasce alla crisi con l'àncora presa; finisce al
// primo battito contato uscito dopo il fuoco, e a ogni Stop, Play a mano, show chiuso, cambio di ruolo, stacco,
// interruzione, servizi audio persi, conto non certo, canzone finita, canzone cambiata.
// Il motore tiene lo stato su audioQueue (`AudioEngine`); qui le regole, pure.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Perché l'àncora del Solo non si prende, col nome che va nella riga `[SOLO-RIPRESA] ancora non presa`.
enum SoloAnchorRefusal: String, Equatable, CaseIterable {
    case notSolo = "non-solo"
    case showClosed = "show-chiuso"
    case noSong = "nessuna-canzone-in-corso"
    /// Una causa che ferma il Solo è già ricordata (la tolta e il cambio di modo nello stesso blocco: una scheda USB
    /// staccata): il Solo si sta fermando come la console, e la ripresa non comincia.
    case stoppingCause = "il-solo-si-ferma-come-la-console"
    case engineStopped = "motore-fermo"
    case noMap = "mappa-assente-o-non-valida"
    case noCountedBeat = "nessun-battito-contato-gia-uscito"
    case cycle = "ciclo"
}

/// L'esito della presa dell'àncora.
enum SoloAnchorTake: Equatable {
    /// Presa adesso: la ripresa aspetta.
    case taken
    /// Un'àncora è già viva (una crisi nuova nella pausa, nella scorta, o prima che il primo battito contato della
    /// ripresa sia uscito): resta quella, e il segno «tenuta dalla ripresa» si toglie. La ripresa aspetta.
    case alreadyAlive
    /// Il drenaggio è aperto all'arresto: la canzone è finita suonando e la sua chiusura la consegna l'arresto, una
    /// volta. Nessuna àncora, nessuna ripresa: la canzone finisce come finita suonando.
    case drainDelivered
    /// Non presa: la ripresa non è possibile, il Solo si ferma come allo Stop della console.
    case notTaken(SoloAnchorRefusal)

    /// La ripresa aspetta dopo questo esito.
    var resumeWaits: Bool {
        switch self {
        case .taken, .alreadyAlive: return true
        case .drainDelivered, .notTaken: return false
        }
    }
}

/// Perché il conto della ripresa non è certo.
enum SoloResumeUncertain: Equatable {
    /// La ripresa aspetta ma l'àncora non c'è.
    case noAnchor
    /// Il conto non dà un posto (mappa non valida, àncora fuori mappa, un ciclo sul cammino, valori non validi).
    case clock(ShowClockUnknown)
    /// Il conto dà un «uno» ma non la sua ora o il suo posto dall'inizio della canzone.
    case noTarget
    /// Il fuoco è arrivato in ritardo più volte dei salti concessi.
    case lateTooManyTimes
}

/// Il bersaglio della ripresa: un inizio di battuta della canzone.
struct SoloResumeAim: Equatable {
    /// Indice della sezione, da 0.
    let section: Int
    /// Battuta nella sezione, da 1.
    let bar: Int
    /// Indice del battito nella sezione, da 0: (bar − 1) × battiti per battuta.
    let beatInSection: Int
    /// L'ora d'uscita del bersaglio sulla mappa, in tick.
    let targetTicks: UInt64
    /// L'«uno» per il DSP: i battiti della canzone dall'inizio fino al bersaglio (almeno 1).
    let unoBeat: Double
}

/// L'esito del conto della ripresa.
enum SoloResumePlan: Equatable {
    case resume(SoloResumeAim)
    case songEnded
    case uncertain(SoloResumeUncertain)
}

/// Una lettura valida di Δ: l'ora d'uscita di un buffer letta dal rendering meno l'ora della convenzione dello
/// stesso buffer, in tick col segno, e l'ora della lettura.
struct SoloDeltaReading: Equatable {
    let deltaTicks: Int64
    let readTicks: UInt64
}

/// Δ per un'àncora.
struct SoloDelta: Equatable {
    /// Δ in tick col segno: 0 con la riserva, e 0 con «avvio» (A437 · SEGUITO 5: il battito contato non è di regime).
    let ticks: Int64
    /// Le letture valide usate (con «avvio»: le letture della catena come sono, anche se Δ non si applica).
    let readings: Int
    /// `true` = la mediana delle letture («hardware»); `false` = meno di tre letture, Δ = 0 («riserva»), oppure
    /// (A437 · SEGUITO 5) il battito contato non è di regime, Δ = 0 («avvio»), qualunque sia il numero delle letture.
    let fromHardware: Bool
    /// L'ora della lettura più recente fra quelle usate, o `nil` senza letture.
    let newestReadTicks: UInt64?
    /// A437 · SEGUITO 5 (decisione del referee, par. 2.3 del seguito) — `true` = Δ non si applica a questo battito
    /// contato: il suo buffer non è stato prodotto da un richiamo della catena corrente dopo l'ultimo azzeramento delle
    /// letture (è uno dei tre buffer della partenza, o è di prima di un azzeramento). Una Δ sola vale per una
    /// convenzione sola. Una `var` col valore di base: chi costruiva `SoloDelta` coi quattro campi di prima non cambia.
    var beatOffRegime: Bool = false

    /// Il nome per la riga (`lettura:hardware|riserva|avvio`): «avvio» vince su «hardware» e su «riserva».
    var sourceName: String { beatOffRegime ? "avvio" : (fromHardware ? "hardware" : "riserva") }
}

/// A437 · SEGUITO 5 — perché una lettura di Δ si scarta, col nome che va nella riga `[SOLO-RIPRESA] letture di delta`.
/// L'ordine dei casi è quello della riga; l'ordine in cui si controllano è un altro (`deltaReadingGate`, `deltaReading`).
enum SoloDeltaDiscard: String, Equatable, CaseIterable {
    /// Il buffer di confronto è uno dei tre della partenza della catena (non l'ha prodotto un richiamo).
    case startup = "avvio"
    /// L'ora dell'ultimo render non è valida.
    case render = "render"
    /// Il buffer di confronto non è nella memoria della catena corrente.
    case chain = "catena"
    /// L'ora dell'ultimo render è prima di adesso: il render è fermo o in ritardo.
    case behind = "indietro"
    /// L'ora dell'ultimo render è più di tre cicli dopo adesso.
    case ahead = "avanti"
    /// Il ciclo d'I/O dell'hardware è più lungo del buffer del lettore.
    case cycle = "ciclo"
    /// Δ fuori da −1 ciclo … (buffer in coda + 2) × un buffer.
    case limits = "limiti"
}

/// A437 · SEGUITO 5 — l'esito di una lettura di Δ arrivata alla lettura di `lastRenderTime`.
enum SoloDeltaReadingOutcome: Equatable {
    /// La lettura vale: Δ in tick col segno.
    case valid(deltaTicks: Int64)
    /// Scartata, col motivo; con «limiti» anche la Δ calcolata (per la riga), se no `nil`.
    case discarded(SoloDeltaDiscard, deltaTicks: Int64?)
}

/// A437 · SEGUITO 5 — i contatori delle letture di Δ della catena corrente, per la riga `[SOLO-RIPRESA] letture di
/// delta` (un evento: la presa dell'àncora). Solo interi e due segni: nessuna allocazione a contare; le due stringhe
/// si fanno solo quando la riga si scrive (Costituzione V6, par. 4).
struct SoloDeltaTally: Equatable {
    /// Le chiamate a regime arrivate alla lettura di Δ: le valide più tutte le scartate.
    var calls: Int = 0
    var valid: Int = 0
    var startup: Int = 0
    var render: Int = 0
    var chain: Int = 0
    var behind: Int = 0
    var ahead: Int = 0
    var cycle: Int = 0
    var limits: Int = 0
    /// L'ora dell'ultimo render meno adesso, in tick col segno, della chiamata più recente che ha letto un'ora valida
    /// (valida o scartata dopo); `hasLastRenderMinusNow` falso = nessuna chiamata della catena l'ha letta.
    var lastRenderMinusNowTicks: Int64 = 0
    var hasLastRenderMinusNow: Bool = false
    /// La Δ di quella stessa chiamata, se è arrivata ai limiti (valida o scartata dai limiti); `hasLastDelta` falso =
    /// quella chiamata è caduta su «indietro» o «avanti» (Δ non si calcola), o nessuna chiamata ha letto.
    var lastDeltaTicks: Int64 = 0
    var hasLastDelta: Bool = false

    /// Tutte le scartate.
    var discarded: Int { startup + render + chain + behind + ahead + cycle + limits }

    private mutating func bump(_ why: SoloDeltaDiscard) {
        switch why {
        case .startup: startup += 1
        case .render: render += 1
        case .chain: chain += 1
        case .behind: behind += 1
        case .ahead: ahead += 1
        case .cycle: cycle += 1
        case .limits: limits += 1
        }
    }

    /// Una chiamata fermata prima della lettura di `lastRenderTime` (`deltaReadingGate`): i due «ultimi» restano.
    mutating func noteBeforeRead(_ why: SoloDeltaDiscard) {
        calls += 1
        bump(why)
    }

    /// Una chiamata che ha letto `lastRenderTime` (`deltaReading`). Con l'ora non valida i due «ultimi» restano.
    mutating func noteAfterRead(_ outcome: SoloDeltaReadingOutcome, renderTimeValid: Bool,
                                lastRenderTicks: UInt64, nowTicks: UInt64) {
        calls += 1
        if renderTimeValid {
            lastRenderMinusNowTicks = lastRenderTicks >= nowTicks
                ? Int64(clamping: lastRenderTicks - nowTicks)
                : -Int64(clamping: nowTicks - lastRenderTicks)
            hasLastRenderMinusNow = true
            hasLastDelta = false
        }
        switch outcome {
        case .valid(let deltaTicks):
            valid += 1
            if renderTimeValid {
                lastDeltaTicks = deltaTicks
                hasLastDelta = true
            }
        case .discarded(let why, let deltaTicks):
            bump(why)
            if renderTimeValid, let deltaTicks {
                lastDeltaTicks = deltaTicks
                hasLastDelta = true
            }
        }
    }

    private func milliseconds(_ ticks: Int64, _ present: Bool, _ ticksPerSecond: Double) -> String {
        guard present, ticksPerSecond > 0, ticksPerSecond.isFinite else { return "-" }
        return String(format: "%.1f", Double(ticks) / ticksPerSecond * 1000.0)
    }

    /// Il testo di `ultimoRenderMenoAdesso_ms`: i millisecondi a un decimale, o «-». Solo all'evento della riga.
    func lastRenderMinusNowText(ticksPerSecond: Double) -> String {
        milliseconds(lastRenderMinusNowTicks, hasLastRenderMinusNow, ticksPerSecond)
    }

    /// Il testo di `ultimoDelta_ms`: i millisecondi a un decimale, o «-». Solo all'evento della riga.
    func lastDeltaText(ticksPerSecond: Double) -> String {
        milliseconds(lastDeltaTicks, hasLastDelta, ticksPerSecond)
    }
}

/// Perché lo scatto del ritorno del Solo non riparte, col nome che va nella riga.
enum SoloReturnRefusal: String, Equatable, CaseIterable {
    case engineRunning = "motore-in-moto"
    case interruption = "interruzione"
    case services = "servizi-audio"
    case notSolo = "ruolo"
    case notPending = "nessuna-ripresa-in-attesa"
    case noAnchor = "ancora-assente"
    case otherSong = "altra-canzone"
}

/// Che cosa fa lo scatto del ritorno del Solo.
enum SoloReturnStep: Equatable {
    /// La guardia regge e l'uscita c'è: si passa al pre-controllo del conto e alla ripartenza.
    case fire
    /// La guardia non regge: niente riparte da qui.
    case notFired(SoloReturnRefusal)
    /// L'ultima uscita da cui il click è uscito era esterna e adesso un'esterna non c'è: è lo stacco visto prima
    /// della sua notizia. Il Solo si ferma come allo Stop della console, con la causa «uscita-tolta».
    case asRemoved
}

/// Perché il fuoco della ripresa non entra, col nome che va nella riga `[SOLO-RIPRESA] fuoco non eseguito`.
enum SoloFireRefusal: String, Equatable, CaseIterable {
    case notSolo = "ruolo"
    case interruption = "interruzione"
    case services = "servizi-audio"
    case noAnchor = "ancora-assente"
    case otherSong = "altra-canzone"
    case sectionOutOfMap = "sezione-fuori-mappa"
    case handlesMissing = "stato-mancante"
}

/// Che cosa fa il fuoco arrivato in ritardo sul bersaglio.
enum SoloLateStep: Equatable {
    /// Si rifà il conto per il bersaglio dopo, coi salti rimasti e l'innesco per la riga.
    case recount(skipsLeft: Int, trigger: String)
    /// I salti sono finiti: il Solo si ferma come allo Stop della console.
    case giveUp
}

/// Lo stato della ripresa, col nome per le righe.
enum SoloResumeState: String, Equatable, CaseIterable {
    /// Nessuna ripresa: nessuna àncora, niente in attesa.
    case idle = "nessuna"
    /// L'àncora è viva e la ripresa aspetta col motore fermo (la pausa).
    case waiting = "in-attesa"
    /// L'àncora è viva, il motore è ripartito muto e il fuoco è armato (la scorta): la ripresa aspetta ancora.
    case armed = "armata"
    /// Il fuoco è riuscito: la ripresa non aspetta più, e l'àncora resta tenuta finché il primo battito contato
    /// della ripresa non è uscito.
    case held = "tenuta"
}

/// Gli eventi che muovono la ripresa: uno per riga della tabella del referto A424, par. 2.1 b.
enum SoloResumeEvent: String, Equatable, CaseIterable {
    /// Una crisi con l'esito «ripresa sulla canzone» e l'àncora presa o già viva.
    case crisisWaits = "crisi-con-ancora"
    /// Una crisi con l'esito «ripresa sulla canzone» e l'àncora non presa: il Solo si ferma come allo Stop.
    case crisisNotTaken = "crisi-senza-ancora"
    /// Una crisi col drenaggio aperto: la canzone finisce come finita suonando.
    case crisisDrainDelivered = "crisi-col-drenaggio"
    /// Il motore è ripartito per la ripresa e il fuoco è armato.
    case engineStartedForResume = "motore-ripartito"
    /// Il fuoco è riuscito.
    case fired = "fuoco"
    /// Il primo battito contato della ripresa è uscito.
    case firstCountedBeatOut = "primo-battito-uscito"
    /// Lo Stop, da ogni origine (tasto, pedale, END SHOW, uscita dalla stanza).
    case stop = "stop"
    /// Il Play a mano (un avvio senza ripartenza automatica).
    case manualPlay = "avvio"
    /// Lo show chiuso.
    case showClosed = "show-chiuso"
    /// Il cambio di ruolo, Link acceso o spento.
    case roleOrLinkChange = "ruolo"
    /// Lo stacco: l'uscita tolta, o sparita prima della sua notizia.
    case outputRemoved = "uscita-tolta"
    /// Un'interruzione di sistema.
    case interruption = "interruzione"
    /// I servizi audio persi o rifatti.
    case servicesLostOrReset = "servizi-audio"
    /// Il conto non certo, o il fuoco che non può entrare (E2).
    case uncertain = "non-certo"
    /// La canzone finisce prima del primo «uno» utile (E3).
    case songEnded = "canzone-finita"
    /// La mappa di un'altra canzone consegnata con la ripresa in piedi.
    case otherSong = "altra-canzone"
}

enum SoloResumeDecision {

    // MARK: - Il Solo «in moto per il player»

    /// P35 (decisione del referee): il valore che la regola e la memoria delle crisi ricevono per il Solo al posto
    /// del solo `isRunning`. Nella pausa della ripresa il motore è fermo ma il Solo è in moto per il player: lo
    /// stacco, l'interruzione, i servizi persi e il reset lo fermano come la console, come col click che suona.
    static func inMotionForPlayer(engineRunning: Bool, resumePending: Bool) -> Bool {
        engineRunning || resumePending
    }

    // MARK: - L'àncora

    /// La presa dell'àncora, alla crisi, prima che il motore si fermi.
    /// - `stoppingCauseRemembered`: la causa ricordata per le ripartenze ferma il Solo (`CrisisCause.stopsSolo`): una
    ///   crisi che lo ferma è stata dichiarata e il suo Stop «come la console» è in arrivo. La ripresa non comincia:
    ///   chi chiama non fa niente di più (non è un «non certo»: il Solo si sta già fermando).
    /// - `drainOpen`: il drenaggio di fine canzone è aperto (`_sectionEndPending`): l'ultima sezione è finita
    ///   suonando e la sua chiusura aspetta di essere consegnata. Si guarda prima dell'àncora già viva: col
    ///   drenaggio aperto la chiusura la consegna l'arresto, e una ripresa dall'àncora vecchia la consegnerebbe una
    ///   seconda volta (referto A424, par. 2.1 d: la doppia consegna esclusa per costruzione).
    /// - `anchorAlive`: un'àncora del Solo è già viva.
    /// - `countedBeatOut`: c'è un battito contato con l'ora d'uscita non dopo adesso (l'ultimo o il penultimo).
    /// - `beatInCycle`: quel battito sta in un ciclo (la sua sezione non ha un numero di battiti).
    static func anchorTake(playerRole: PlayerRole,
                           showOpen: Bool,
                           songInProgress: Bool,
                           stoppingCauseRemembered: Bool,
                           engineRunning: Bool,
                           drainOpen: Bool,
                           anchorAlive: Bool,
                           mapValid: Bool,
                           countedBeatOut: Bool,
                           beatInCycle: Bool) -> SoloAnchorTake {
        guard playerRole == .solo else { return .notTaken(.notSolo) }
        guard showOpen else { return .notTaken(.showClosed) }
        guard songInProgress else { return .notTaken(.noSong) }
        guard !stoppingCauseRemembered else { return .notTaken(.stoppingCause) }
        if engineRunning && drainOpen { return .drainDelivered }
        if anchorAlive { return .alreadyAlive }
        guard engineRunning else { return .notTaken(.engineStopped) }
        guard mapValid else { return .notTaken(.noMap) }
        guard countedBeatOut else { return .notTaken(.noCountedBeat) }
        guard !beatInCycle else { return .notTaken(.cycle) }
        return .taken
    }

    // MARK: - Δ, l'ora vera dell'àncora

    /// Quante letture di Δ tiene il motore per catena: una memoria fissa.
    static let deltaMemory: Int = 8
    /// Sotto questo numero di letture valide Δ vale 0 e la lettura è «riserva».
    static let deltaMinimumReadings: Int = 3

    // === A437 · SEGUITO 5 (19/11/2026) — LA LETTURA DI Δ, LA REGOLA NUOVA (decisioni del referee, par. 2.1-2.3) ===
    // Il fatto (referto A437, par. 45-47). Letta dal richiamo di fine buffer, l'ora di `lastRenderTime` (L) non è
    // un'ora passata: è circa due cicli d'I/O NEL FUTURO (24/05: L − adesso da +21,80 a +21,93 ms in 9 righe su 9;
    // 19/11: da +21,96 a +23,62 ms in 15 riprese su 15, iPhone e iPad; A412 il 18/10: +22,34 e +21,76 ms). Apple lo
    // scrive per il blocco di rendering di una Audio Unit, `AURenderBlock`, parametro `timestamp`: l'ora del livello
    // dell'hardware a cui i dati SARANNO resi (https://developer.apple.com/documentation/audiotoolbox/aurenderblock);
    // che `lastRenderTime` porti la stessa ora è [Probabile]: Apple lo scrive per `AURenderBlock`. Misurato nelle 15
    // catene ancorate del 19/11 (F1, [Probabile] a regime): al richiamo che dà per consumato il buffer n−1,
    // L = l'inizio del rendering del buffer n (`wanted`) + ψ, con ψ fra 0,19 e 10,56 ms, dentro (0, un ciclo].
    // La regola di prima (A424 par. 2.1 g: la funzione delle «quattro condizioni», tolta da questo seguito) voleva L
    // nel passato, 0 ≤ adesso − L ≤ due cicli, e scartava tutte le letture; e la formula di prima (L + ciclo +
    // latenza) contava un ciclo in più.
    // La regola: Δ = (L − ciclo/2 + latenza) − la convenzione di `wanted`. L − ciclo/2 è il centro della finestra
    // (0, ciclo] di ψ: l'errore sta in ± mezzo ciclo (±5,33 ms a 48 kHz, ±5,80 a 44,1 col ciclo di 512 campioni).
    // Le grandezze qui sotto sono DECISIONI DEL REFEREE, non costanti scelte per far tornare i numeri: il mezzo ciclo,
    // il tetto di tre cicli (misurati da 1,89 a 2,21: il tetto non entra nel conto), il confronto del ciclo col
    // buffer in campioni interi, la soglia dei buffer della partenza (strutturale: tre buffer a ogni catena).
    // Due passi, perché tre controlli non dipendono da L e il motore legge `lastRenderTime` solo se passano
    // (Costituzione V6, par. 4: al più UNA lettura per chiamata, e nessuna per niente): `deltaReadingGate` prima della
    // lettura (avvio, catena, ciclo), `deltaReading` dopo (render, indietro, avanti, limiti). Una lettura scartata
    // conta un motivo solo, il primo che cade in quest'ordine.

    /// I buffer della partenza di una catena: `OutputReturnDecision.queuedAheadBuffers + 1`, tre. Ogni catena comincia
    /// con tre chiamate di fila, senza richiamo; il richiamo k produce il buffer k + 2. La convenzione dei tre della
    /// partenza non è quella di regime (i tre della partenza fresca nascono nello stesso blocco, con lo stesso adesso;
    /// quelli della catena ancorata hanno l'ora vera della catena): una Δ sola vale per una convenzione sola.
    static var chainStartBuffers: Int { OutputReturnDecision.queuedAheadBuffers + 1 }
    /// Il tetto di «avanti»: L − adesso al più tre cicli (decisione del referee; misurati 1,89-2,21).
    static let deltaRenderAheadCycles: UInt64 = 3

    /// Il ciclo d'I/O è più lungo del buffer del lettore? In campioni interi (decisione del referee): il ciclo in tick
    /// per la frequenza del motore diviso i tick al secondo (prima la moltiplicazione, poi la divisione), arrotondato
    /// all'intero più vicino con la metà verso l'alto (`.rounded()` di Swift), contro il buffer in campioni. Non in
    /// tick: la conversione dei secondi in tick tronca, e un ciclo appena sopra il buffer può dare un tick in più
    /// (sul telefono a 48 kHz il buffer vale 255.999 tick e un ciclo di 512,0001 campioni 256.000). Con tick al
    /// secondo, frequenza o ciclo a zero (o non finiti) la conversione non si fa e la risposta è «sì»: nessuna
    /// divisione per zero, nessun intero da un infinito (il confronto resta fra `Double`).
    /// [Ipotesi del referee] con un ciclo più lungo del buffer un ciclo di render consuma la fine di più di un buffer,
    /// due richiami possono leggere la stessa L, e la finestra (0, ciclo] di ψ non vale buffer per buffer.
    static func cycleLongerThanBuffer(cycleTicks: UInt64, sampleRate: Double, ticksPerSecond: Double,
                                      bufferFrames: Int) -> Bool {
        guard cycleTicks > 0, sampleRate > 0, sampleRate.isFinite, ticksPerSecond > 0, ticksPerSecond.isFinite else {
            return true
        }
        let cycleFrames = (Double(cycleTicks) * sampleRate / ticksPerSecond).rounded()
        guard cycleFrames.isFinite else { return true }
        return cycleFrames > Double(bufferFrames)
    }

    /// PRIMO PASSO, prima della lettura di `lastRenderTime`: `nil` = si può leggere; se no il motivo dello scarto.
    /// Nell'ordine: «avvio» (`wantedIndex` sotto i buffer della partenza), «catena» (`wanted` non è nella memoria
    /// della catena corrente), «ciclo» (`cycleLongerThanBuffer`).
    /// - `wantedIndex`: l'indice nella catena del buffer di confronto (i richiami accettati della catena).
    /// - `bufferFrames`: il buffer del lettore in campioni (`AudioEngine.bufferSize`, 512): lo passa il motore.
    static func deltaReadingGate(wantedIndex: Int, wantedInChainMemory: Bool, cycleTicks: UInt64, sampleRate: Double,
                                 ticksPerSecond: Double, bufferFrames: Int) -> SoloDeltaDiscard? {
        guard wantedIndex >= chainStartBuffers else { return .startup }
        guard wantedInChainMemory else { return .chain }
        guard !cycleLongerThanBuffer(cycleTicks: cycleTicks, sampleRate: sampleRate, ticksPerSecond: ticksPerSecond,
                                     bufferFrames: bufferFrames) else { return .cycle }
        return nil
    }

    /// SECONDO PASSO, con l'ora di `lastRenderTime` letta: Δ o il motivo dello scarto. Nell'ordine: «render» (l'ora
    /// non valida), «indietro» (L < adesso, anche di un tick: il render è fermo o in ritardo; è il verso opposto della
    /// guardia di prima), «avanti» (L − adesso > tre cicli), poi Δ = (L − ciclo/2 + latenza) − la convenzione, e
    /// «limiti» se è fuori da −1 ciclo ≤ Δ ≤ (buffer in coda + 2) × un buffer (con «limiti» torna anche la Δ calcolata,
    /// per la riga). Il mezzo ciclo è la divisione intera dei tick (mezzo tick in meno coi cicli dispari).
    /// - `conventionTicks`: l'ora d'uscita che il motore ha dato a `wanted` (la convenzione di `_bufferOutTicksQ`).
    /// - `bufferTicks`: il buffer del lettore in tick, calcolato dal motore.
    static func deltaReading(renderTimeValid: Bool,
                             lastRenderTicks: UInt64,
                             nowTicks: UInt64,
                             cycleTicks: UInt64,
                             latencyTicks: UInt64,
                             conventionTicks: UInt64,
                             bufferTicks: UInt64,
                             queuedAheadBuffers: Int) -> SoloDeltaReadingOutcome {
        guard renderTimeValid else { return .discarded(.render, deltaTicks: nil) }
        guard lastRenderTicks >= nowTicks else { return .discarded(.behind, deltaTicks: nil) }
        let (ceiling, ceilingOverflow) = cycleTicks.multipliedReportingOverflow(by: deltaRenderAheadCycles)
        guard !ceilingOverflow, lastRenderTicks - nowTicks <= ceiling else { return .discarded(.ahead, deltaTicks: nil) }
        let halfCycle = cycleTicks / 2
        let (renderPlusLatency, sumOverflow) = lastRenderTicks.addingReportingOverflow(latencyTicks)
        guard !sumOverflow, renderPlusLatency >= halfCycle else { return .discarded(.limits, deltaTicks: nil) }
        let renderOut = renderPlusLatency - halfCycle
        let delta: Int64 = renderOut >= conventionTicks
            ? Int64(clamping: renderOut - conventionTicks)
            : -Int64(clamping: conventionTicks - renderOut)
        guard queuedAheadBuffers >= 0, cycleTicks <= UInt64(Int64.max) else { return .discarded(.limits, deltaTicks: delta) }
        let (upper, upperOverflow) = bufferTicks.multipliedReportingOverflow(by: UInt64(queuedAheadBuffers) + 2)
        guard !upperOverflow, upper <= UInt64(Int64.max) else { return .discarded(.limits, deltaTicks: delta) }
        guard delta >= -Int64(cycleTicks), delta <= Int64(upper) else { return .discarded(.limits, deltaTicks: delta) }
        return .valid(deltaTicks: delta)
    }

    // A437 · SEGUITO 5 (par. 2.3) — L'ÀNCORA SOMMA Δ SOLO A UN'ORA DI REGIME. Il battito contato porta l'ora della
    // convenzione del suo buffer. Il motore mette su ogni battito contato un segno, `beatDeltaEpoch`: l'epoca delle
    // letture (un numero che sale a ogni azzeramento delle letture: l'apertura di una catena, o un cambio di latenza o
    // di ciclo a catena viva) se il buffer del battito l'ha prodotto un richiamo della catena, se no «nessuna».
    // All'àncora Δ si somma solo se il segno del battito è l'epoca di adesso.

    /// Il segno di un battito a cui Δ non si applica.
    static let noDeltaEpoch: Int = -1

    /// Il segno di un battito contato, quando il motore lo conta: l'epoca delle letture se il suo buffer è stato
    /// prodotto da un richiamo della catena (indice nella catena da tre in su), se no `noDeltaEpoch`.
    static func beatDeltaEpoch(bufferChainIndex: Int, epoch: Int) -> Int {
        bufferChainIndex >= chainStartBuffers ? epoch : noDeltaEpoch
    }

    /// Il battito contato è di regime per le letture di adesso: il suo segno è l'epoca corrente.
    static func beatOnRegimeConvention(beatEpoch: Int, currentEpoch: Int) -> Bool {
        beatEpoch != noDeltaEpoch && beatEpoch == currentEpoch
    }

    /// «Δ o 0» per l'àncora: con un battito di regime la Δ delle letture com'è (`delta(readings:)`: «hardware» o
    /// «riserva»); se no Δ = 0 e la lettura è «avvio», qualunque sia il numero delle letture, che la riga scrive come
    /// sono (`readings`, `newestReadTicks`).
    static func anchorDelta(fromReadings delta: SoloDelta, beatOnRegimeConvention: Bool) -> SoloDelta {
        if beatOnRegimeConvention { return delta }
        return SoloDelta(ticks: 0, readings: delta.readings, fromHardware: false,
                         newestReadTicks: delta.newestReadTicks, beatOffRegime: true)
    }

    /// Un cambio di latenza o di ciclo a catena viva (par. 3 g): le convenzioni già in memoria hanno i valori di
    /// prima, e le letture si azzerano SOLO se uno dei due cambia davvero. `nil` = niente è cambiato; se no il motivo
    /// per la riga `[SOLO-RIPRESA] letture di delta azzerate` (`latenza`, `ciclo`, `latenza+ciclo`).
    static func deltaResetReason(latencyBeforeTicks: UInt64, latencyNowTicks: UInt64,
                                 cycleBeforeTicks: UInt64, cycleNowTicks: UInt64) -> String? {
        switch (latencyBeforeTicks != latencyNowTicks, cycleBeforeTicks != cycleNowTicks) {
        case (false, false): return nil
        case (true, false): return "latenza"
        case (false, true): return "ciclo"
        case (true, true): return "latenza+ciclo"
        }
    }

    /// Δ per l'àncora dalle letture valide della catena corrente, le più recenti in coda: la mediana delle ultime
    /// otto se sono almeno tre (con un numero pari, la media delle due di mezzo), se no 0 con la riserva.
    static func delta(readings: [SoloDeltaReading]) -> SoloDelta {
        let used = Array(readings.suffix(deltaMemory))
        guard used.count >= deltaMinimumReadings else {
            return SoloDelta(ticks: 0, readings: used.count, fromHardware: false, newestReadTicks: used.last?.readTicks)
        }
        let sorted = used.map { $0.deltaTicks }.sorted()
        let middle = sorted.count / 2
        let median: Int64
        if sorted.count % 2 == 1 {
            median = sorted[middle]
        } else {
            // ⚠️ CORRETTO A437 · SEGUITO 5 (19/11/2026): qui c'era «Due valori dentro i limiti di `deltaReadingIsValid`
            // (qualche buffer in tick): la somma non trabocca.»; quella funzione non c'è più. Due valori dentro i
            // limiti di `deltaReading` (fra −1 ciclo e qualche buffer, in tick): la somma non trabocca.
            let (sum, overflow) = sorted[middle - 1].addingReportingOverflow(sorted[middle])
            median = overflow ? sorted[middle] : sum / 2
        }
        return SoloDelta(ticks: median, readings: used.count, fromHardware: true, newestReadTicks: used.last?.readTicks)
    }

    /// L'ora vera dell'àncora: l'ora d'uscita della convenzione del battito contato più Δ. Si ferma ai bordi.
    static func anchorTicks(conventionTicks: UInt64, delta: SoloDelta) -> UInt64 {
        if delta.ticks >= 0 {
            let (sum, overflow) = conventionTicks.addingReportingOverflow(UInt64(delta.ticks))
            return overflow ? UInt64.max : sum
        }
        let down = delta.ticks.magnitude
        return conventionTicks >= down ? conventionTicks - down : 0
    }

    // MARK: - Il conto

    /// La decisione della ripresa: il primo «uno» di battuta con l'ora sulla mappa non prima di adesso più il
    /// margine. Nessuna finestra d'inizio sezione (nel Direttore protegge la correzione di Link; il Solo non ha
    /// correzione). `clock`: il conto dall'àncora del Solo, sulla mappa col tempo dell'àncora; `nil` = àncora assente.
    /// `notBeforeTicks`: il conto rifatto dopo un fuoco in ritardo passa l'ora del bersaglio mancato più un tick, così il
    /// bersaglio nuovo è sempre dopo quello mancato (mai lo stesso: il salto «al bersaglio dopo»); se no 0.
    static func plan(clock: ShowClock?, nowTicks: UInt64, ticksPerSecond: Double, marginSeconds: Double,
                     notBeforeTicks: UInt64 = 0) -> SoloResumePlan {
        guard let clock else { return .uncertain(.noAnchor) }
        if let bad = clock.invalidity { return .uncertain(.clock(bad)) }
        guard ticksPerSecond > 0, ticksPerSecond.isFinite, marginSeconds.isFinite else {
            return .uncertain(.clock(.invalidInput))
        }
        let earliest = max(ShowClock.ticks(nowTicks, plusSeconds: max(marginSeconds, 0), ticksPerSecond: ticksPerSecond),
                           notBeforeTicks)
        switch clock.downbeat(atOrAfterTicks: earliest, ticksPerSecond: ticksPerSecond) {
        case .unknown(let why):
            return .uncertain(.clock(why))
        case .songEndsFirst:
            return .songEnded
        case .found(let downbeat):
            guard let targetTicks = clock.ticks(of: downbeat, ticksPerSecond: ticksPerSecond),
                  let beats = clock.songBeatsFromStart(section: downbeat.section, beatInSection: downbeat.beatInSection),
                  beats >= 1 else {
                return .uncertain(.noTarget)
            }
            return .resume(SoloResumeAim(section: downbeat.section,
                                         bar: downbeat.bar,
                                         beatInSection: downbeat.beatInSection,
                                         targetTicks: targetTicks,
                                         unoBeat: Double(beats)))
        }
    }

    /// Il tempo d'arrivo del fuoco. Nella sezione dell'àncora la griglia di prima correva al tempo dell'àncora; se
    /// nella pausa un tap tempo ha cambiato il tempo del motore, dall'«uno» in poi il click va al tempo nuovo (il
    /// bersaglio resta sulla griglia di prima: referto A424, par. 2.1 l, N7). Nelle altre sezioni il tempo della mappa.
    static func arrivalTempo(targetSection: Int, anchorSection: Int, anchorTempo: Double,
                             engineTempoNow: Double, mapTempo: Double) -> Double {
        guard targetSection == anchorSection else { return mapTempo }
        if engineTempoNow.isFinite, engineTempoNow > 0 { return engineTempoNow }
        return anchorTempo
    }

    /// Il fuoco in ritardo sul bersaglio (mai un click in ritardo): col segno «lettore lento» il ritardo era già
    /// certo all'armamento e il conto si rifà senza consumare un salto; se no si consuma un salto, e senza salti il
    /// Solo si ferma. Lo stesso conto dei salti del rientro del Direttore (`DirectorRejoinDecision.maxLateSkips`).
    static func lateStep(slowPlayer: Bool, lateSkipsLeft: Int) -> SoloLateStep {
        if slowPlayer { return .recount(skipsLeft: lateSkipsLeft, trigger: "lettore-lento") }
        guard lateSkipsLeft > 0 else { return .giveUp }
        return .recount(skipsLeft: lateSkipsLeft - 1, trigger: "ritardo")
    }

    // MARK: - Il ritorno e il fuoco

    /// Lo scatto del ritorno del Solo (dopo un'uscita che compare): la guardia, poi l'uscita sparita.
    /// - `externalVanished`: la memoria dell'ultima uscita a volume 1 dice esterna e adesso un'esterna non c'è.
    static func returnStep(engineRunning: Bool,
                           systemInterruption: Bool,
                           servicesNormal: Bool,
                           playerRole: PlayerRole,
                           pending: Bool,
                           anchorAlive: Bool,
                           sameSong: Bool,
                           externalVanished: Bool) -> SoloReturnStep {
        guard !engineRunning else { return .notFired(.engineRunning) }
        guard !systemInterruption else { return .notFired(.interruption) }
        guard servicesNormal else { return .notFired(.services) }
        guard playerRole == .solo else { return .notFired(.notSolo) }
        guard pending else { return .notFired(.notPending) }
        guard anchorAlive else { return .notFired(.noAnchor) }
        guard sameSong else { return .notFired(.otherSong) }
        if externalVanished { return .asRemoved }
        return .fire
    }

    /// La guardia del fuoco della ripresa: `nil` = il fuoco può entrare; se no il motivo, e il Solo si ferma come
    /// allo Stop della console. L'interruzione di sistema c'è perché il fuoco può scattare fra i due passaggi sulla
    /// coda dell'inizio di un'interruzione (referto A424, par. 2.1 h).
    static func fireRefusal(playerRole: PlayerRole,
                            systemInterruption: Bool,
                            servicesNormal: Bool,
                            anchorAlive: Bool,
                            sameSong: Bool,
                            sectionInMap: Bool,
                            handlesPresent: Bool) -> SoloFireRefusal? {
        guard playerRole == .solo else { return .notSolo }
        guard !systemInterruption else { return .interruption }
        guard servicesNormal else { return .services }
        guard anchorAlive else { return .noAnchor }
        guard sameSong else { return .otherSong }
        guard sectionInMap else { return .sectionOutOfMap }
        guard handlesPresent else { return .handlesMissing }
        return nil
    }

    // MARK: - La vita della ripresa

    /// Lo stato dopo un evento.
    static func lifecycle(_ state: SoloResumeState, _ event: SoloResumeEvent) -> SoloResumeState {
        switch event {
        case .crisisWaits:
            return .waiting
        case .engineStartedForResume:
            return state == .waiting ? .armed : state
        case .fired:
            return state == .armed ? .held : state
        case .firstCountedBeatOut:
            return state == .held ? .idle : state
        case .crisisNotTaken, .crisisDrainDelivered, .stop, .manualPlay, .showClosed, .roleOrLinkChange,
             .outputRemoved, .interruption, .servicesLostOrReset, .uncertain, .songEnded, .otherSong:
            return .idle
        }
    }

    /// La ripresa aspetta: il segno pubblicato (`soloResumePending`), vero da quando la ripresa aspetta a quando il
    /// fuoco riesce o la ripresa si chiude.
    static func pending(_ state: SoloResumeState) -> Bool {
        state == .waiting || state == .armed
    }

    /// L'àncora è viva.
    static func anchorAlive(_ state: SoloResumeState) -> Bool {
        state != .idle
    }

    /// L'àncora è tenuta dalla ripresa: aspetta il primo battito contato uscito.
    static func heldByResume(_ state: SoloResumeState) -> Bool {
        state == .held
    }

    /// Lo stato dai tre valori che il motore tiene, o `nil` se la combinazione non esiste (per il banco e per la
    /// riga di controllo): senza àncora niente aspetta e niente è tenuto; un'àncora tenuta non aspetta.
    static func state(anchorAlive: Bool, pending: Bool, heldByResume: Bool, engineRunning: Bool) -> SoloResumeState? {
        switch (anchorAlive, pending, heldByResume) {
        case (false, false, false): return .idle
        case (true, true, false): return engineRunning ? .armed : .waiting
        case (true, false, true): return .held
        default: return nil
        }
    }
}
