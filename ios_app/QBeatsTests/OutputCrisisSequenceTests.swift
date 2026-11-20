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
// === A425 (04/11/2026, mandato «USCITA AUDIO PASSO 2a PEZZO 3a», par. 2.2, 2.4, 2.5) — il rig più vicino al motore ===
// La soglia della correzione di fase di Link (una correzione di al più 0,01 battiti fa il ramo «nessuna correzione» del motore);
// l'assert del Direttore ripreso a ogni avvio che passa da `prepareNormalStartQ` (B.1 del seguito 4); il battito zero del Play nel
// primo buffer, come il DSP (B.2); la Reset senza Lost (B.10); la mappa consegnata a un avvio in corso, consumata (P4); la causa
// ricordata e lo Stop voluto azzerati al fuoco del rientro (P14). Ognuno col suo interruttore, acceso di base (spento = il rig di
// prima). Il rig non ha il tasto del Direttore né le scritture verso Link: la regola del tocco (P13) e il valore scritto alla
// ripresa (P1) stanno nel banco dei tipi puri (`DirectorTransportDecisionTests`, `ResumeSnapDecisionTests`).

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
    /// A437 — di chi è il ritorno: lo stato è in comune, il Solo ha la sua guardia allo scatto (`fireSoloReturn`).
    var kind: OutputReturnKind = .director
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
/// A437 — il fuoco armato della ripresa del Solo: il bersaglio, l'ora dello scatto, i salti rimasti, il «lettore lento».
private struct SoloFireWait {
    let aim: SoloResumeAim
    let fireAt: Double
    let skipsLeft: Int
    let slowPlayer: Bool
}

private struct RetryWait {
    let fireAt: Double
    let trigger: RecoveryTrigger
    let attempt: Int
    let token: Int
}

/// A437 · PARTE 2 — la rete a 1 s della fine dell'interruzione senza `shouldResume` (`safety_net_noresume`): scatta solo con la
/// ripresa pendente ancora alta e lo stesso contatore della catena.
private struct NoResumeNet {
    let fireAt: Double
    let token: Int
}

/// A421 · SEGUITO 4 (par. 3.1) — la scorta del rientro come il motore: il DSP in campioni (`MetronomeDSP`) con l'origine dei
/// battiti (`_startAbsoluteBeat`, l'«uno»), il cursore al primo campione del buffer che viene (`_absoluteSamplePosition`) e il
/// battito pendente (`_exactNextBeatSample`); e le correzioni fatte nella scorta (`RejoinLeadIn.corrections`).
private struct RigLeadIn {
    let startBeat: Double
    let samplesPerBeat: Double
    var cursor: Double
    var pendingBeatSample: Double
    var corrections = 0

    /// Il fuoco del rientro: `metronome_reset_for_start(uno)` (core_engine/MetronomeDSP.cpp:235-242).
    init(unoBeat: Double, samplesPerBeat: Double) {
        startBeat = unoBeat
        self.samplesPerBeat = samplesPerBeat
        cursor = (unoBeat * samplesPerBeat).rounded()
        pendingBeatSample = unoBeat * samplesPerBeat
    }

    /// `metronome_set_beat_position_time_only` (core_engine/MetronomeDSP.cpp:307-353): il cursore sul battito nuovo, il battito
    /// pendente con la sua etichetta e, se la posizione lo ha scavalcato, al primo campione del buffer di questa chiamata.
    mutating func setBeatPositionTimeOnly(_ beat: Double) {
        guard beat >= 0 else { return }
        let ahead = min(max((pendingBeatSample - cursor) / samplesPerBeat, 0), 1.5)
        cursor = (beat * samplesPerBeat).rounded()
        pendingBeatSample = (startBeat + (beat - startBeat + ahead).rounded()) * samplesPerBeat
        if pendingBeatSample < cursor { pendingBeatSample = cursor }
    }

    /// Il buffer che comincia al cursore porta il battito pendente: il suo campione arrotondato fra il primo campione del buffer e
    /// l'ultimo (core_engine/MetronomeDSP.cpp:435-439).
    func carriesPendingBeat(frames: Int) -> Bool {
        let beatSample = pendingBeatSample.rounded()
        return beatSample >= cursor && beatSample < cursor + Double(frames)
    }
}

private struct OutputRig {
    static let tps = 24_000_000.0
    /// A425 (par. 2.5) — la soglia della correzione di fase di Link (`phaseJumpThresholdBeats_`, ios_app/QBeats/LinkEngine.mm:16;
    /// il confronto `fabs(delta) > threshold`, :647): una correzione di al più 0,01 battiti il motore non la applica.
    static let phaseJumpThresholdBeats = 0.01
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
    /// A432 · parte 2b (voce i) — il conto del Follower sulla band (`_followerBandCountQ`): `nil` = nessun conto, e l'«uno»
    /// del ritorno è quello di sempre. La numerazione della sessione è la linea di Link del rig (`linkBeat(at:)`).
    var bandCount: FollowerBandCount? = nil
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
    /// A421 · SEGUITO 4 (par. 3.1): la scorta come il motore (`rejoinLeadIn`, il DSP in campioni) e il buffer della catena che ha
    /// portato l'«uno» (contando da 0, come `chainIndex`); `leadInBuffersLeft` e' la scorta del rig di prima (interruttore spento).
    var rejoinLeadIn: RigLeadIn? = nil
    var leadInUnoBuffer: Int? = nil
    var leadInBuffersLeft = 0
    var anchor = false
    var anchorHeld = false
    var firstBeatOutAt: Double? = nil
    /// Un battito contato è già uscito in questo avvio (l'àncora si prende solo così, `takeSilenceAnchorQ`).
    var countedBeatOut = false
    /// A421 · SEGUITO 4 (par. 3.1, dopo il verificatore): l'ora d'uscita dell'«uno» del rientro quando la scorta lo ha contato (il
    /// bersaglio). Resta dopo la chiusura dell'àncora tenuta, come `_lastCountedBeatQ` nel motore (`closeSilenceAnchorQ` toglie
    /// solo l'àncora): una crisi dopo la sua uscita prende l'àncora da lui.
    /// ⚠️ A432 · parte 2c: «(il bersaglio)» qui sopra vale solo senza correzioni nella scorta. L'ora è quella del buffer della catena
    /// che porta l'«uno» più lo scostamento dell'«uno» nel buffer (`useEngineRejoinUnoOutTime`; spento: il bersaglio, com'era).
    var rejoinUnoOutAt: Double? = nil
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
    // A421 · SEGUITO 3: i contatori del seguito. La memoria della crisi tenuta (par. 2, le righe «invariati»); il segno
    // «lettore-lento» all'armamento (par. 8.3); il segno della prima correzione dopo la finestra abbassato senza correzione (par. 4);
    // il silenzio in vigore e chi l'ha scritto (par. 5), con le due misure (il buco, la tolta); il motivo dell'ultima chiusura
    // dell'àncora e gli Stop di fine canzone (par. 8.1).
    var memoryKeptLines = 0
    var slowPlayerArms = 0
    var firstCorrectionLoweredWithoutCorrection = 0
    var lastSilenceWrite: (reason: String, at: Double)? = nil
    var lastHoleMeasure: (writtenBy: String, before: Bool)? = nil
    var lastRemovalMeasure: (writtenBy: String, writtenNow: Bool)? = nil
    var anchorCloseReason: String? = nil
    var songEndStops = 0
    /// Le regole del seguito 3, spegnibili per il banco: la memoria della crisi del Solo (par. 2), il segno abbassato senza
    /// correzione (par. 4), il silenzio in vigore (par. 5: spento, ogni 0 riscrive il ricordo e la misura del buco guarda solo le
    /// scritture nate dopo l'inizio del buco, com'era).
    var useCrisisMemoryRule = true
    var useFirstCorrectionMarkLowering = true
    var useSilenceWriterMemory = true
    /// A421 · SEGUITO 4 (par. 3): il rig come il motore, spegnibile per il banco. La scorta del rientro (par. 3.1: al fuoco la
    /// posizione sul seme, la scorta finisce nella chiamata del buffer che porta l'«uno» col bordo del DSP, dopo la prima
    /// correzione nessuna correzione e il segno che resta; spento: la posizione sull'«uno», la scorta per `leadInBuffers` chiamate,
    /// ogni correzione applicata e il segno tenuto a ogni chiamata senza correzione). «Canzone in corso» (par. 3.2: giu' a ogni
    /// `stopSync`, all'arresto locale del cambio di ruolo e alla Reset del Follower, e all'avvio la mappa di quell'avvio; spento: giu'
    /// solo alla fine della canzone e alla chiusura dello show, e all'avvio alzata solo con la mappa).
    var useEngineLeadIn = true
    var useEngineSongInProgress = true
    /// A425 (mandato A425, par. 2.2, 2.4, 2.5): il rig come il motore, spegnibile per il banco (spenti = il rig di prima).
    ///  · `useEngineSyncThreshold` — una correzione di al più 0,01 battiti fa il ramo «nessuna correzione» del motore (il ramo `else`
    ///    di `link_engine_sync_phase` in `scheduleNextBuffer`): non si applica, non si conta (nemmeno nella scorta), e il segno della
    ///    prima correzione dopo la finestra si consuma senza spostare (`noteCorrectionAfterWindowQ` con prima = dopo);
    ///  · `useEngineAssertAtStart` (B.1 del seguito 4) — l'avvio che passa da `prepareNormalStartQ` riporta il Direttore all'assert
    ///    (`_directorFollowsLinkQ = false`);
    ///  · `useEngineBeatZero` (B.2) — un buffer porta i battiti fra il suo primo campione, compreso, e l'ultimo, escluso, come il DSP:
    ///    il battito zero del Play sta nel primo buffer (il rig di prima non lo contava); la sua ora d'uscita resta `firstBeatOutAt`,
    ///    quindi non alza `countedBeatOut`;
    ///  · `useRunningStartConsumesMap` (P4) — col rig della «canzone in corso» del motore, la mappa consegnata a un avvio che trova il
    ///    motore in moto è di quell'avvio: alla guardia di `start()` e al fuoco dell'ingresso del Follower;
    ///  · `useRejoinFireClearsMemory` (P14) — al fuoco del rientro la causa ricordata e lo Stop voluto si azzerano.
    var useEngineSyncThreshold = true
    var useEngineAssertAtStart = true
    var useEngineBeatZero = true
    var useRunningStartConsumesMap = true
    var useRejoinFireClearsMemory = true
    /// A437 · PARTE 2 (C.8; VERIFICA_REFEREE_A425, par. 3.1) — LA ROTTURA VOLUTA: l'azzeramento della causa ricordata e dello Stop
    /// voluto in cima al fuoco del rientro, prima delle uscite del fuoco che non parte. Spento di base: acceso è il rig sbagliato
    /// che `testARejoinFireThatDoesNotStartClearsNothing` deve vedere.
    var rejoinFireClearsMemoryAtTheTop = false
    /// A437 · PARTE 2 (§B.8 del seguito 4 di A421) — il controllo «in ritardo» del fuoco del rientro come il motore: senza piano
    /// della scorta (`DirectorRejoinDecision.leadIn` nullo) l'ora del render è il bersaglio meno la sola latenza
    /// (`fireDirectorRejoinQ`: `leadIn?.firstBufferRenderTicks ?? firstBufferRenderTicks(…)`). Spento: il rig di prima, sempre D
    /// con la scorta.
    var useEngineLateCheckWithoutLeadIn = true
    /// A437 · PARTE 2 (§B.4 del seguito 4 di A421) — le chiamate della scorta del rientro arrivate col segno della prima
    /// correzione dopo la finestra alto: nel motore non succede (il segno lo abbassano l'arresto e ogni catena nuova); nel banco
    /// il segno nella scorta si mette a mano, e questo contatore dice che nessuna sequenza vera ci arriva.
    var leadInCallsWithTheMarkUp = 0
    /// A425: le correzioni sotto la soglia non applicate, le mappe consumate dall'avvio in corso, gli azzeramenti al fuoco.
    var correctionsUnderThreshold = 0
    var mapsConsumedByRunningStart = 0
    var memoryClearedAtRejoinFire = 0
    /// A432 · parte 2c: il rig come il motore, spegnibile per il banco (spenti = la rottura voluta).
    ///  · `useOwnClockForTheBandUno` — DA-SOLO l'«uno» del conto sulla band prende il posto dal righello dei secondi e l'ora dalla
    ///    mappa portata sulla linea propria (i rami DA-SOLO di `nextBandUnoQ` e di `unoTicksQ(for:)`); spento, anche DA-SOLO fa come
    ///    IN SYNC: il posto e l'ora da Link, che DA-SOLO non è la sessione della band;
    ///  · `useEngineRejoinUnoOutTime` — l'ora d'uscita dell'«uno» contato nella scorta del rientro è quella del buffer che lo porta
    ///    più il suo scostamento nel buffer, come per ogni battito nel motore (`_lastBeatOutTicksQ`); spento, è sempre il bersaglio
    ///    (`firstClickAt`), com'era.
    var useOwnClockForTheBandUno = true
    var useEngineRejoinUnoOutTime = true
    /// A432 · parte 2d (K2): il rig come il motore, spegnibile per il banco (spento = la rottura voluta).
    ///  · `useEngineHeldAnchorClose` — l'àncora tenuta dal rientro si chiude come nel motore (`checkAnchorHeldByRejoinQ`, a ogni
    ///    chiamata di `scheduleNextBuffer`: l'ultimo battito contato di questo avvio c'è e la sua ora d'uscita è passata): alla
    ///    prima chiamata dopo che l'«uno» del rientro è stato contato, con la sua ora d'uscita vera passata (`rejoinUnoOutAt`, che
    ///    con una correzione nella scorta non è il bersaglio; finché la scorta è viva l'«uno» non è contato e l'àncora resta
    ///    tenuta, anche oltre il bersaglio); spento, si chiude alla prima chiamata dal bersaglio in poi (`firstBeatOutAt`), che
    ///    l'«uno» sia contato o no, com'era.
    var useEngineHeldAnchorClose = true

    // A437 — LA RIPRESA DEL SOLO SULLA CANZONE (mandato A437, par. 2 e 3; seguito 1). La mappa della canzone del Solo e la
    // sua griglia (l'ora d'uscita vera di ogni battito: dal Play, e dopo una ripresa dal bersaglio); l'àncora (il conto
    // dall'ultimo battito uscito prima della crisi), tenuta dalla ripresa fino al primo battito uscito; il segno della pausa;
    // il fuoco armato; Δ (di quanto l'uscita vera segue la convenzione del motore) e le sue letture valide della catena.
    var soloMap: SongMap? = nil
    var soloSongIdx = 0
    var soloGrid: ShowClock? = nil
    var soloAnchor: ShowClock? = nil
    var soloAnchorSongIdx = 0
    var soloAnchorHeld = false
    var soloResumePending = false
    var soloFire: SoloFireWait? = nil
    var soloDeltaSeconds = 0.0
    var soloDeltaReadings: [SoloDeltaReading] = []
    var soloRenderFresh = true
    // === A437 · SEGUITO 5 (19/11/2026) — LE LETTURE DI Δ DALLA REGOLA PURA, COME IL MOTORE (`noteSoloDeltaQ`) ===
    // Fino al seguito 4 il rig aggiungeva le letture da sé, col solo segno `soloRenderFresh`, senza passare dalla regola: nessuna
    // sequenza aveva mai giocato una lettura scartata. Ora il rig conta i richiami della catena, tiene la convenzione di ogni
    // buffer in una memoria di otto posti e passa da `SoloResumeDecision.deltaReadingGate` e `deltaReading`. Due modi (decisione
    // del referee, par. 4 del seguito 5):
    //  · REALISTICO (`renderAheadSeconds` e `renderPhaseSeconds` dati: «a» e «ψ» del telefono). L'ora dell'ultimo render è
    //    l'inizio del rendering del buffer di confronto più ψ; adesso è l'ora della chiamata: nei richiami puntuali adesso =
    //    L − a, e un richiamo in ritardo sposta adesso e non L [scelta del rig, come `renderNext`; Ipotesi che sul telefono sia
    //    così]. L'uscita vera di ogni buffer sta sulla linea della catena (il buffer 0 di un Play esce a t + latenza + a − ψ):
    //    Δ non è data, si ricava (`soloTrueDeltaSeconds`);
    //  · DI PRIMA (i due non dati): l'uscita vera è la convenzione più `soloDeltaSeconds`, com'era, e L si ricava dalla Δ data
    //    (L = convenzione + Δ + ciclo/2 − latenza, adesso = L − 2 cicli): la regola pura rende la stessa Δ di prima, e le prove
    //    di prima vedono gli stessi numeri. Nei tre buffer della catena ancorata la convenzione è l'ora vera, come nel motore.
    // `soloRenderFresh` falso è il render fermo: L resta `soloRenderBehindSeconds` prima di adesso (motivo «indietro»).
    // Il modello del Follower (`renderNext`, in `scheduleNextBuffer`) resta com'è: i due convivono.
    var renderAheadSeconds: Double? = nil
    var renderPhaseSeconds: Double? = nil
    var soloRenderBehindSeconds = 0.001
    /// I richiami della catena (`_chainCallbacksQ`): ogni chiamata di `scheduleNextBuffer` che non è una delle tre della partenza.
    var chainCallbacks = 0
    var soloOutRingIndex: [Int] = Array(repeating: -1, count: SoloResumeDecision.deltaMemory)
    var soloOutRingTicks: [UInt64] = Array(repeating: 0, count: SoloResumeDecision.deltaMemory)
    /// I contatori della riga `letture di delta` (`_soloDeltaTallyQ`), e quelli scritti all'ultima presa dell'àncora (la riga).
    var soloDeltaTally = SoloDeltaTally()
    var soloLastTally: SoloDeltaTally? = nil
    /// L'epoca delle letture (`_soloDeltaEpochQ`) e l'indice nella catena del primo buffer prodotto dopo l'ultimo azzeramento.
    var soloDeltaEpoch = 0
    var soloEpochFirstBuffer = 0
    /// L'uscita vera del buffer 0 della catena corrente; se la catena è ancorata; la convenzione di ogni suo buffer.
    var soloChainOutStart: Double? = nil
    var soloChainAnchored = false
    var soloChainConventions: [Double] = []
    /// Gli azzeramenti a catena viva (par. 3 g del seguito 5), col motivo.
    var soloDeltaResets: [String] = []
    var soloRealRender: Bool { renderAheadSeconds != nil && renderPhaseSeconds != nil }
    /// Nel modo realistico la griglia vera parte a − ψ dopo l'ora di prima (t + latenza); nel modo di prima 0.
    var soloRenderShift: Double {
        guard let ahead = renderAheadSeconds, let phase = renderPhaseSeconds else { return 0 }
        return ahead - phase
    }
    /// L'uscita vera meno la convenzione di un buffer di regime: nel modo realistico 2B − ciclo + a − ψ (par. 2.1 del seguito
    /// 5), nel modo di prima `soloDeltaSeconds`.
    var soloTrueDeltaSeconds: Double {
        guard let ahead = renderAheadSeconds, let phase = renderPhaseSeconds else { return soloDeltaSeconds }
        return 2 * bufferSeconds - cycleSeconds + ahead - phase
    }
    /// Le strade che finiscono senza avvio: `setCategory` che fallisce, `engine.start()` che fallisce (`hardwareBusy` c'è già).
    var setCategoryFails = false
    var engineStartFails = false
    /// A437 · PARTE 2 (seguito 2 di A437, §1 voce 4 h) — gli ingressi delle tre uscite E2 «per difesa» di `start()`: il
    /// metronomo che manca (la prima guardia), lo stato dei servizi audio all'avvio (`MediaServicesResetDecision`, evento
    /// `.start`: «servizi persi» rifiuta, «da ricostruire» ricostruisce) e la ricostruzione che fallisce.
    var metronomeMissing = false
    var servicesAtStart: MediaServicesState = .normal
    var rebuildFails = false
    /// A437 · PARTE 2 — C.1 (referto A431, par. 2.7): il segno «tolta dentro l'interruzione» (`_removalDuringInterruptionQ`),
    /// quante volte si è alzato e con che motivo si è abbassato (play | ruolo | link | rientro).
    /// ⚠️ CORRETTO A437 · SEGUITO 3 (19/11/2026): «ruolo» e «link» non ci sono più (il cambio di ruolo e Link spento non abbassano
    /// più il segno, come il motore); i motivi sono play | rientro.
    var removalDuringInterruption = false
    var removalsRemembered = 0
    var removalsForgotten: [String] = []
    /// A437 · PARTE 2 — la fine dell'interruzione senza `shouldResume`: la rete a 1 s (col contatore della catena di allora).
    var noResumeNet: NoResumeNet? = nil
    var noResumeNetFired = 0
    // I contatori della ripresa.
    var engineStartFailures = 0
    var runnerArmNext = 0
    var runnerRejoins: [Int] = []
    var soloAnchorsTaken = 0
    var soloLastDelta: SoloDelta? = nil
    var soloE2: [String] = []
    var soloE3: [String] = []
    var soloResumes = 0
    var soloFirstClickAt: Double? = nil
    var soloFirstAim: SoloResumeAim? = nil
    var soloLateFires = 0
    var soloLateTargets: [Double] = []
    var soloClosures: [String] = []
    var soloPreChecks = 0
    var soloReturnsFired = 0
    var soloReturnsNotFired = 0

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
    /// I campioni di un battito per il DSP (`(_sampleRate * 60.0) / _bpm`), alla frequenza dei nodi.
    var samplesPerBeat: Double { nodeRate * 60.0 / bpm }

    /// Il primo «uno» di battuta di Link non prima di `t`.
    func nextBarTime(atOrAfter t: Double) -> Double {
        let beat = OutputReturnDecision.nextBarBeat(atOrAfter: linkBeat(at: t), quantum: Double(beatsPerBar))!
        return time(ofBeat: beat)
    }

    /// A421 · SEGUITO 1 — il primo «uno» non prima di `t`, come battito col suo orologio e la sua ora (`nextUnoQ`): Link, o la
    /// linea propria DA-SOLO (dall'ultimo «uno» uscito); `nil` = «uno non calcolabile».
    /// A432 · parte 2b (voce i): prima il conto sulla band, se è certo (`nextBandUnoQ`); se non dà un «uno», la regola di sempre.
    func nextUno(atOrAfter t: Double) -> (uno: FollowerReturnUno, at: Double)? {
        if let fromCount = nextBandUno(atOrAfter: t) { return fromCount }
        switch followerClock {
        case .band:
            // Non è un valore di `followsLinkQ`: l'orologio di sempre è Link o la linea propria.
            return nil
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
        case .band:
            // A432 · parte 2b (voce i), come `unoTicksQ(for:)`: prima la conferma del conto; IN SYNC l'ora di Link nella
            // numerazione della sessione; DA-SOLO l'ora della mappa portata sulla linea propria.
            guard let count = bandCount, FollowerBandUno.confirms(count: count, uno: uno) else { return nil }
            // A432 · parte 2c: spento `useOwnClockForTheBandUno`, anche DA-SOLO l'ora di Link (la rottura voluta).
            if followerClock == .link || !useOwnClockForTheBandUno {
                return time(ofBeat: uno.beat)
            }
            guard let timeline = ownTimeline, let lastUno = lastUnoBeat,
                  let mapTicks = FollowerBandUno.mapTicks(count: count, uno: uno, ticksPerSecond: OutputRig.tps),
                  let ownBeat = FollowerBandUno.ownBeat(mapTicks: mapTicks, timeline: timeline, lastUnoBeat: lastUno,
                                                        ticksPerSecond: OutputRig.tps),
                  let at = OutputReturnDecision.ownTicks(atBeat: ownBeat, timeline: timeline, ticksPerSecond: OutputRig.tps) else { return nil }
            return seconds(at)
        }
    }

    /// A432 · parte 2b (P38) — il getter del DSP di questo rig (`metronome_pending_beat` subito dopo la correzione): il DSP qui è
    /// la griglia «origine più interi», e il battito in attesa dopo una correzione è quello di prima più la parte intera
    /// arrotondata della correzione (il re-map di `setBeatPositionTimeOnly`).
    func rigPendingBeatAfterCorrection(before: Double, after: Double) -> Double {
        LateBeatDecision.pendingBeatAfter(origin: dspOrigin, before: before, after: after)
    }

    /// A432 · parte 2b (voce i) — `nextBandUnoQ`: l'«uno» dal conto certo, col posto alla scadenza da Link (IN SYNC) o dal
    /// righello dei secondi (DA-SOLO). `nil` senza conto, col conto chiuso, o se il conto non dà un «uno».
    func nextBandUno(atOrAfter t: Double) -> (uno: FollowerReturnUno, at: Double)? {
        guard let count = bandCount, FollowerBandUno.isCertain(count) else { return nil }
        let chosen: FollowerReturnUno?
        // A432 · parte 2c: spento `useOwnClockForTheBandUno`, anche DA-SOLO il posto da Link (la rottura voluta).
        if followerClock == .link || !useOwnClockForTheBandUno {
            chosen = FollowerBandUno.next(count: count, atOrAfterLinkBeat: linkBeat(at: t))
        } else {
            chosen = FollowerBandUno.next(count: count, atOrAfterTicks: ticks(t), ticksPerSecond: OutputRig.tps)
        }
        guard let uno = chosen, let at = unoTime(for: uno) else { return nil }
        return (uno, at)
    }

    /// A432 · parte 2b (voce i) — `nextBarUnoQ(after:)`: per un «uno» del conto la prossima battuta della canzone.
    func nextBarUno(after uno: FollowerReturnUno) -> FollowerReturnUno? {
        if uno.clock == .band {
            guard let count = bandCount else { return nil }
            return FollowerBandUno.nextBar(count: count, after: uno)
        }
        return OutputReturnDecision.nextBarUno(uno)
    }

    var externalPresent: Bool { OutputRouteDecision.hasExternal(physicalRoute ?? route) }
    var stoppedByCrisis: Bool { !isRunning && ((crisisCause != nil && !wantedStop) || interrupted) }

    // MARK: - Lo stato e le attese

    mutating func apply(_ event: OutputSilenceEvent) {
        let before = state
        state = OutputRouteDecision.state(after: event, from: state, playerRole: role)
        // A421 · SEGUITO 3 (par. 5): il ricordo del silenzio in vigore se ne va a ogni passaggio di `muted` da vero a falso (il volume
        // a 1, la chiusura dello show, il cambio di ruolo), come `noteSilenceLiftedQ`.
        if useSilenceWriterMemory && before.muted && !state.muted {
            lastSilenceWrite = nil
        }
    }

    /// `writeOutputVolumeQ(0, reason:)`: lo stato e, A421 · SEGUITO 3 (par. 5), il silenzio in vigore e chi l'ha scritto: solo se lo
    /// 0 trova lo stato non muto; com'era (regola spenta), ogni 0 riscriveva il ricordo.
    mutating func silenceNow(reason: String, at writeTime: Double? = nil) {
        if !useSilenceWriterMemory || !state.muted {
            lastSilenceWrite = (reason, writeTime ?? now)
        }
        volume = 0.0
        apply(.silenced)
    }

    /// `writeOutputVolumeQ(1, …)`: il volume a 1 (il ricordo del silenzio se ne va in `apply`).
    mutating func restoreVolume() {
        volume = 1.0
        apply(.volumeRestored(externalPresent: externalPresent))
    }

    /// La riga della misura del buco (`logRenderGapMeasureQ`): chi ha scritto il silenzio in vigore e se prima di questa chiamata.
    /// Com'era (regola spenta): solo una scrittura nata dopo l'inizio del buco meno un buffer.
    func holeMeasure(at t: Double, hole: Double) -> (writtenBy: String, before: Bool) {
        guard let write = lastSilenceWrite else { return ("nessuno", false) }
        if !useSilenceWriterMemory && write.at < t - hole - bufferSeconds { return ("nessuno", false) }
        return (write.reason, write.at < t)
    }

    /// La riga della misura della tolta (`logRemovedMeasureQ`): chi ha scritto il silenzio in vigore.
    var removalWrittenBy: String { lastSilenceWrite?.reason ?? "nessuno" }

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

    mutating func publishIsPlaying() {
        isPlaying = TransportStateDecision.isPlaying(engineRunning: isRunning)
    }

    /// `clearPendingResumeQ`: la ripresa pendente, l'interruzione e il contatore della catena che sale.
    mutating func clearPendingResume() {
        pendingResume = false
        interrupted = false
        resumeToken += 1
    }

    /// La regola di ogni crisi, con la causa ricordata. A421 · SEGUITO 3 (par. 2): la memoria passa da `CrisisMemoryDecision`: il
    /// Solo a motore fermo con una causa che non lo ferma la tiene (con la riga: `memoryKeptLines`); com'era (regola spenta) ogni
    /// esito diverso da «niente» la riscriveva.
    mutating func crisis(_ cause: CrisisCause) -> CrisisStopOutcome {
        // A437 (P35): per il Solo la regola e la memoria ricevono «in moto per il player» (il motore gira, o la ripresa aspetta).
        let inMotion = role == .solo
            ? SoloResumeDecision.inMotionForPlayer(engineRunning: isRunning, resumePending: soloResumePending)
            : isRunning
        let outcome = CrisisStopDecision.outcome(playerRole: role, cause: cause, showOpen: showOpen,
                                                 songInProgress: songInProgress, engineRunning: inMotion,
                                                 silentInSong: silentInSong)
        var memoryStep = CrisisMemoryDecision.step(playerRole: role, cause: cause, engineRunning: inMotion, outcome: outcome)
        if !useCrisisMemoryRule && memoryStep == .keep { memoryStep = .rewrite }
        let memory = CrisisMemoryDecision.memoryAfter(step: memoryStep, previousCause: crisisCause, wantedStopSinceCrisis: wantedStop,
                                                      cause: cause, playerRole: role)
        crisisCause = memory.cause
        wantedStop = memory.wantedStopSinceCrisis
        if memoryStep == .keep { memoryKeptLines += 1 }
        // A421 · SEGUITO 2 (par. 3): il Direttore che entra nel silenzio col motore in moto prende l'àncora come il motore
        // (`takeSilenceAnchorQ`: l'ultimo battito contato già uscito): il primo battito della catena è uscito (al Play il
        // primo buffer porta il battito zero, al fuoco il bersaglio porta l'«uno») o un richiamo ha già portato un battito.
        // Un'àncora tenuta dal rientro torna del silenzio.
        if outcome == .silentInSong {
            let firstBeatOut = firstBeatOutAt.map { now >= $0 } ?? false
            // A421 · SEGUITO 4 (par. 3.1, dopo il verificatore): anche l'«uno» del rientro contato nella scorta e gia' uscito.
            let rejoinUnoOut = rejoinUnoOutAt.map { now >= $0 } ?? false
            if isRunning && !anchor && (countedBeatOut || firstBeatOut || rejoinUnoOut) { anchor = true }
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
        soloFire = nil   // A437: `cancelPendingJoin` annulla anche il fuoco armato della ripresa del Solo
        netAt = nil
        leadInBuffersLeft = 0
        rejoinLeadIn = nil
        cancelGuardian()
        if drainPending {
            drainPending = false
            drainDelivered += 1
        }
        publishIsPlaying()
    }

    /// A421 · SEGUITO 2 (par. 3): l'àncora si chiude (Stop, show chiuso, cambio di ruolo, avvio, il primo battito del rientro); con lei
    /// se ne va il segno «tenuta dal rientro» (`closeSilenceAnchorQ`). `reason`: il motivo della riga «ancora chiusa».
    mutating func closeAnchor(at t: Double, reason: String = "-") {
        if anchor {
            anchorClosedAt = t
            anchorCloseReason = reason
        }
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
        // A421 · SEGUITO 4 (par. 3.2): `stopSync` abbassa «canzone in corso» per ogni origine, anche a motore gia' fermo.
        if useEngineSongInProgress { songInProgress = false }
        wantedStop = true
        // A437: ogni Stop chiude la ripresa del Solo (l'àncora, il segno, e col segno alto il contatore della catena).
        closeSoloResume(reason: "stop")
        soloFire = nil
        cancelReturns()
        cancelGuardian()
        rejoin = nil
        windowOpen = false
        firstCorrectionPending = false
        closeAnchor(at: t, reason: "stop")
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

    /// A421 · SEGUITO 3 (par. 8.1) — la fine della canzone del Direttore. Col Direttore muto a motore fermo è lo Stop di fine canzone
    /// armato durante il silenzio (`fireDirectorSongEndStopQ`): lo Stop a Link, «canzone in corso» e lo Stop voluto, i ritorni
    /// annullati, l'àncora chiusa col motivo «fine-canzone» (`leaveDirectorSilenceQ(closeAnchor: true)`); se il silenzio è già finito
    /// (il rientro ha suonato) quello Stop non si manda («Stop non inviato») e la canzone finisce col motore in moto: lo Stop voluto
    /// del runner (`stop()` → `stopSync`), che chiude l'àncora — anche tenuta dal rientro — col motivo «stop». Tutte e due le strade
    /// passano da `closeSilenceAnchorQ`, che toglie il segno «tenuta».
    mutating func songEnd(at t: Double) {
        advance(to: t)
        if role == .direttore && silentInSong && !isRunning && rejoin == nil {
            songEndStops += 1
            linkStops += 1
            songInProgress = false
            wantedStop = true
            silentInSong = false
            if pendingResume || interrupted { clearPendingResume() }
            apply(.directorStop)
            cancelReturns()
            publishIsPlaying()
            closeAnchor(at: t, reason: "fine-canzone")
            playbackStopped = true
            return
        }
        // `stopSync` abbassa «canzone in corso» a ogni arresto: da A421 · SEGUITO 4 (par. 3.2) lo fa `stop(at:)`; questa riga resta per
        // il rig di prima (interruttore spento), dove la fine della canzone la abbassava gia'. ⚠️ RISCRITTO A421 · SEGUITO 4: diceva «il
        // rig lo fa qui, non in `stop(at:)` (le sequenze di prima lo lasciano).».
        songInProgress = false
        stop(at: t)
    }

    /// Il Solo fermo come allo Stop della console (`stopForSoloCrisis` → `stopSync(.soloCrisis)`).
    mutating func soloStop() {
        soloStops += 1
        // A437: `stopSync(.soloCrisis)` chiude la ripresa del Solo come ogni Stop.
        closeSoloResume(reason: "crisi-solo")
        soloFire = nil
        // A421 · SEGUITO 4 (par. 3.2): `stopSync(.soloCrisis)` abbassa «canzone in corso».
        if useEngineSongInProgress { songInProgress = false }
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

    /// Il fuoco dell'ingresso del Follower. A425 (P4): col rig della «canzone in corso» del motore la mappa si consuma
    /// (`consumeSongMapForRunningStartQ`, «fuoco-ingresso-follower»); il rig di prima la abbassava senza consumarla.
    mutating func followerJoinFired() {
        if useEngineSongInProgress && useRunningStartConsumesMap {
            consumeMapForRunningStart()
        } else {
            songMapPending = false
        }
    }

    /// A425 (P4) — `consumeSongMapForRunningStartQ`: col segno alto la mappa è dell'avvio in corso: «canzone in corso» vera e il segno
    /// giù (`SongInProgressDecision.runningStart`); col segno basso niente.
    mutating func consumeMapForRunningStart() {
        let step = SongInProgressDecision.runningStart(SongMapMark(mapForNextStart: songMapPending, songInProgress: songInProgress))
        guard step.consumed else { return }
        songMapPending = step.mark.mapForNextStart
        songInProgress = step.mark.songInProgress
        mapsConsumedByRunningStart += 1
    }

    /// A421 · SEGUITO 4 (par. 3.2) — il Play come il motore, dal ruolo. Direttore e Solo dal runner: la mappa prima dell'avvio
    /// (`SetlistRunner.prepareAndStartCurrentSection`: `setSongMap`, poi `start`). Il Follower dalla sessione Link
    /// (`followerRun(.start)`): prima `start()`, poi la mappa del runner e il suo `start()`, che trova il motore in moto, poi il fuoco
    /// dell'ingresso che abbassa il segno: sul Follower «canzone in corso» resta falsa.
    /// ⚠️ RISCRITTO A425 (P4). «il fuoco dell'ingresso che abbassa il segno: sul Follower «canzone in corso» resta falsa» non è più vero:
    /// il secondo `start()`, che trova il motore in moto, consuma la mappa e «canzone in corso» è vera; il fuoco trova il segno basso.
    /// Col rig di prima (`useEngineSongInProgress` o `useRunningStartConsumesMap` spenti) come prima.
    mutating func runnerPlay(at t: Double) {
        if role == .follower {
            start(at: t, recovery: nil)
            setSongMap()
            start(at: t, recovery: nil)
            if isRunning { followerJoinFired() }
        } else {
            setSongMap()
            start(at: t, recovery: nil)
        }
    }

    mutating func closeShow(at t: Double) {
        advance(to: t)
        showOpen = false
        songInProgress = false
        silentInSong = false
        songMapPending = false
        closeAnchor(at: t, reason: "show-chiuso")
        closeSoloResumeAtRest(reason: "show-chiuso")   // A437
        cancelReturns()
        if isRunning && state.muted && mediaServicesNormal {
            restoreVolume()
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
                                            stoppedByCrisis: stoppedByCrisis, inInterruption: systemInterruption,
                                            soloResumePending: soloResumePending, directorSilentInSong: silentInSong)
        // L'ordine del par. 2.3 a (alla lettera, dopo la verifica del diff): `mediaResetSkipsQ`; il silenzio (U3); lo stato
        // puro «uscita mancante» e, a una tolta, l'annullo dei ritorni (anche nel rimando dentro un'interruzione, che poi
        // esce); la crisi e l'arresto; i ritorni; la ripresa pendente; i rami di oggi. Fra la Lost e la Reset niente, nemmeno
        // lo stato: la tolta persa la rilegge l'avvio del Follower dopo la ricostruzione (la rilettura a ogni avvio, par. 4.3).
        guard mediaServicesNormal else { return }
        // A421 · SEGUITO 3 (par. 5): la misura della tolta (`logRemovedMeasureQ`), col click in moto, dopo il silenzio della notizia:
        // se il silenzio lo scrive la notizia o c'era già, e chi l'ha scritto (il silenzio in vigore).
        let silenceWrittenNow = step.silences && !state.muted
        if useRouteCrisis && step.silences { silenceNow(reason: "percorso-\(routeClass.rawValue)") }
        if routeClass == .removed && isRunning {
            lastRemovalMeasure = (removalWrittenBy, silenceWrittenNow)
        }
        if step.raisesMissing { apply(.removed) }
        // A437 · PARTE 2 — C.1: la tolta dentro un'interruzione, col Direttore non muto in canzone, si ricorda a parte (uno stato
        // puro, prima del rimando che esce più sotto).
        if step.remembersRemoval && !removalDuringInterruption {
            removalDuringInterruption = true
            removalsRemembered += 1
        }
        // A421 · SEGUITO 2 (E.7): col motore in moto e il volume a 1 che resta, la memoria prende l'esterna.
        if step.lowersMissing { apply(.externalPresent(playingAtVolumeOne: isRunning && !state.muted)) }
        if routeClass == .removed { cancelReturns() }
        guard !systemInterruption else { return }
        // Il Solo si ferma sul principale (`stopForSoloCrisis`, mai da audioQueue): dopo il blocco della coda, cioè dopo i
        // rami della frequenza e del modo qui sotto.
        var deferredSoloStop = false
        var soloResumeCrisis = false
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
                case .soloResumeOnSong:
                    // A437 (P23, la strada unica): l'àncora prima dell'arresto, l'arresto locale; senza àncora E2.
                    let take = takeSoloAnchor(cause: cause)
                    if isRunning { crisisStop() }
                    afterSoloCrisisStop(take)
                    soloResumeCrisis = true
                case .asToday, .nothing:
                    break
                }
            }
            switch step.armsReturn {
            case .solo?:
                // A437: il ritorno del Solo, dopo l'annullo di quello che c'era, con la stessa attesa del Direttore.
                if soloResumeCrisis && soloResumePending {
                    cancelReturns()
                    let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: hardwareRate != copyRate)
                    directorReturn = DirectorReturn(wait: wait, fireAt: t + OutputReturnDecision.directorWaitSeconds(wait),
                                                    trigger: .outputAdded, armedAt: t, kind: .solo)
                }
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
            let modeOutcome = crisis(.mode)
            if modeOutcome == .silentInSong { silentInSong = true }
            // A437: il Solo in canzone prende l'àncora prima dell'arresto (nella pausa è già viva e resta quella).
            let soloModeTake: SoloAnchorTake? = modeOutcome == .soloResumeOnSong ? takeSoloAnchor(cause: .mode) : nil
            if isRunning { crisisStop() }
            if let soloModeTake { afterSoloCrisisStop(soloModeTake) }
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
        let rateOutcome = crisis(.configuration)
        if rateOutcome == .silentInSong { silentInSong = true }
        // A437: il Solo in canzone prende l'àncora prima dell'arresto; la ripartenza passa dal pre-controllo.
        let soloRateTake: SoloAnchorTake? = rateOutcome == .soloResumeOnSong ? takeSoloAnchor(cause: .configuration) : nil
        crisisStop()
        cancelReturns()
        copyRate = hardwareRate
        if let soloRateTake { afterSoloCrisisStop(soloRateTake) }
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
                                           wantedStopSinceCrisis: wantedStop, crisisCause: crisisCause, outputMissing: missing,
                                           removalDuringInterruption: removalDuringInterruption)
        if first == .noRestart {
            noteNoRestart(trigger: trigger, missing: missing)
            return
        }
        // A437: il pre-controllo della ripresa del Solo, in un punto solo, prima di ogni scrittura della sessione, per il
        // primo tentativo e per ogni tentativo vivo della catena (un tentativo di una catena morta lo uccide il contatore).
        if attempt == 0 || token == resumeToken {
            if !soloPreCheck(at: t) { return }
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
            // A437 · seguito 1 (voce 2): `setCategory` fallito e hardware occupato con la ripresa del Solo in attesa: E2 al
            // posto della ripresa pendente; per gli altri come oggi.
            if setCategoryFails {
                if endSoloResumeRoad(reason: "setCategory-fallito") { return }
                pendingResume = true
                return
            }
            sessionWrites += 1
            if hardwareBusy {
                if endSoloResumeRoad(reason: "hardware-occupato") { return }
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
                                            outputMissing: recoveryRead(), removalDuringInterruption: removalDuringInterruption)
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
                                                      outputMissing: missing, removalDuringInterruption: removalDuringInterruption)
        // A437 · PARTE 2 — C.1 (mandato A437, par. 2.8, C-1; seguito 2, §2 voce 1): col motivo «direttore-tolta-nella-chiamata» lo
        // stesso stato fermo (il player a «fermo»; l'interruzione giù con l'hardware libero), e la ripresa pendente NON resta
        // alzata, nemmeno con l'hardware occupato (lì per l'uscita mancante si rialza, qui sotto).
        if reason == .directorRemovalInCall {
            playbackStopped = true
            pendingResume = false
            if !systemInterruption && !hardwareBusy { interrupted = false }
            return
        }
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
        guard !isRunning else {
            // A425 (P4): la guardia «avvio-gia-in-moto» col motore in moto consuma la mappa di questo avvio.
            if useEngineSongInProgress && useRunningStartConsumesMap { consumeMapForRunningStart() }
            return
        }
        // A437 · PARTE 2 (h): la stessa guardia, col metronomo che manca e il motore fermo: con la ripresa del Solo in attesa E2.
        if metronomeMissing {
            endSoloResumeRoad(reason: "avvio-senza-metronomo")
            publishIsPlaying()
            return
        }
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
        // A437 · PARTE 2 (h): i servizi audio all'avvio, come `start()`: l'avvio rifiutato («servizi persi») e la ricostruzione
        // fallita («da ricostruire») sono uscite senza avvio; con la ripresa del Solo in attesa E2.
        switch MediaServicesResetDecision.transition(state: servicesAtStart, event: .start).action {
        case .refuseStart:
            if !(role == .direttore && silentInSong) { playbackStopped = true }
            publishIsPlaying()
            endSoloResumeRoad(reason: "avvio-rifiutato-servizi-persi")
            return
        case .rebuildThenStart:
            if rebuildFails {
                if !(role == .direttore && silentInSong) { playbackStopped = true }
                publishIsPlaying()
                endSoloResumeRoad(reason: "ricostruzione-fallita")
                return
            }
            servicesAtStart = .normal
        default:
            break
        }
        // `prepareNormalStartQ`: l'avvio che non passa dal coordinatore azzera causa e Stop voluto, consuma il segno della mappa
        // e chiude l'àncora. (Come il motore, `start()` non annulla i ritorni: li annullano le strade che fermano e ripartono.)
        // A437: il coordinatore del Solo. Una ripartenza automatica con la ripresa in attesa decide qui (il bersaglio, oppure
        // E3 o E2 e l'avvio si ferma); ogni altro avvio passa da `prepareNormalStartQ`, che chiude la ripresa.
        var soloAim: SoloResumeAim? = nil
        if role == .solo && recovery != nil && soloResumePending {
            guard let aim = coordinateSoloResume(phase: "avvio", at: t) else {
                publishIsPlaying()
                return
            }
            soloAim = aim
        } else if !(role == .direttore && silentInSong) {
            closeSoloResume(reason: "avvio")
            crisisCause = nil
            wantedStop = false
            forgetRemovalDuringInterruption(reason: "play")   // A437 · PARTE 2 — C.1
            // A425 (B.1 del seguito 4): `prepareNormalStartQ` riporta il Direttore all'assert se dopo un rientro seguiva Link.
            if useEngineAssertAtStart { followsLink = false }
            // A421 · SEGUITO 4 (par. 3.2): «canzone in corso» diventa la mappa di questo avvio, falsa senza mappa, anche per le
            // ripartenze automatiche; il rig di prima (interruttore spento) la alzava con la mappa e senza la lasciava com'era.
            if useEngineSongInProgress {
                songInProgress = songMapPending
                songMapPending = false
            } else if songMapPending {
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
        // A421 · SEGUITO 4 (par. 3.1): ogni avvio che prosegue toglie la scorta di un rientro di prima (il blocco `do` di `start()`).
        rejoinLeadIn = nil
        // A421 · SEGUITO 1 (par. 4.3): a ogni avvio del Follower che prosegue, la rilettura del percorso con la memoria.
        if role == .follower { _ = recoveryRead() }
        // `applyStartVolumeQ`: lo 0 «avvio» sul mixer nuovo con lo stato già muto non cambia chi ha scritto (par. 5).
        if OutputRouteDecision.volumeForStart(playerRole: role, state: state) == 0.0 {
            silenceNow(reason: "avvio")
        } else {
            restoreVolume()
        }
        // A437 · seguito 1 (voce 1): `engine.start()` che fallisce con la ripresa del Solo in attesa: E2.
        if engineStartFails {
            engineStartFails = false
            engineStartFailures += 1
            publishIsPlaying()
            endSoloResumeRoad(reason: "avvio-fallito")
            return
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
        rejoinUnoOutAt = nil
        // A437: le letture di Δ sono della catena. ⚠️ A437 · SEGUITO 5: qui c'era `soloDeltaReadings = []`; ora, come
        // `openBufferChainQ`, i richiami, la memoria delle convenzioni, i contatori e l'epoca delle letture ripartono con la catena.
        // Il Play parte a beat zero: il primo buffer porta il primo battito, che esce circa una latenza dopo l'avvio (nel modo
        // realistico del seguito 5, a − ψ più tardi: `soloRenderShift`, che nel modo di prima vale 0).
        let firstOut = t + latency + soloRenderShift
        openChainForSoloDelta(outStart: firstOut, anchored: false)
        firstBeatOutAt = firstOut
        starts += 1
        publishIsPlaying()
        playbackStopped = false
        now = t + engineStartDuration
        if let target {
            armRejoin(targetAt: target, skips: 0)
        } else if let soloAim {
            // A437: il motore è in moto e muto, senza buffer; la catena la apre il fuoco della ripresa.
            armSoloResume(soloAim, skipsLeft: DirectorRejoinDecision.maxLateSkips, fromSlowPlayer: false)
        } else {
            // A437: la griglia della canzone del Solo parte dal primo battito di questo avvio (in canzone e con la mappa).
            if role == .solo {
                soloGrid = (songInProgress ? soloMap : nil).map {
                    ShowClock(map: $0, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 0, ticks: ticks(firstOut)))
                }
            }
            dspOrigin = 0
            position = 0
            syncSkip = 3
            scheduleNextBuffer(at: now, chainStart: true)
            scheduleNextBuffer(at: now, chainStart: true)
            scheduleNextBuffer(at: now, chainStart: true)
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
        // A421 · SEGUITO 3 (par. 8.3): il segno si conta all'armamento (la riga «armato … lettoreLento:1»).
        if slow { slowPlayerArms += 1 }
        rejoin = RejoinWait(targetAt: targetAt, fireAt: slow ? now : max(targetAt - marginNow, now), skips: skips,
                            slowPlayer: slow, fromSlowPlayer: fromSlowPlayer)
        lastRejoinSkipsLeft = DirectorRejoinDecision.maxLateSkips - skips
    }

    /// Il fuoco del rientro (T5): in ritardo si salta al bersaglio dopo, fino a quattro volte; col segno «lettore-lento» il
    /// coordinatore con lo stesso conto dei salti, senza la guardia. Al fuoco la scorta muta, l'àncora resta tenuta dal rientro.
    mutating func fireRejoin(at t: Double) {
        // A437 · PARTE 2 (C.8): la rottura voluta, l'azzeramento salito in cima (spento di base).
        if useRejoinFireClearsMemory && rejoinFireClearsMemoryAtTheTop {
            crisisCause = nil
            wantedStop = false
            memoryClearedAtRejoinFire += 1
        }
        guard let wait = rejoin, isRunning else { rejoin = nil; return }
        rejoin = nil
        // A437 · PARTE 2 (§B.8): come il motore, il piano della scorta si conosce PRIMA del controllo «in ritardo»; senza piano
        // l'ora del render è il bersaglio meno la sola latenza, col piano il bersaglio meno D (la scorta e la latenza).
        let noLeadInPlan = useEngineLeadIn
            && DirectorRejoinDecision.leadIn(targetOutputTicks: ticks(wait.targetAt), outputLatencyTicks: ticks(latency),
                                             unoBeat: linkBeat(at: wait.targetAt), bpm: bpm, bufferFrames: 512, sampleRate: nodeRate,
                                             ioBufferSeconds: cycleSeconds, ticksPerSecond: OutputRig.tps) == nil
        let renderDistance = (useEngineLateCheckWithoutLeadIn && noLeadInPlan) ? latency : firstBufferDistance
        let renderAt = wait.targetAt - (copiesDistance ?? renderDistance)
        if t + DirectorRejoinDecision.minLeadSeconds > renderAt {
            if wait.slowPlayer {
                slowPlayerFires += 1
                armRejoin(targetAt: nextBarTime(atOrAfter: wait.targetAt + 0.5 * 60.0 / bpm), skips: wait.skips, fromSlowPlayer: true)
                return
            }
            lateSkips += 1
            guard wait.skips < DirectorRejoinDecision.maxLateSkips else {
                // «non-certo(ritardo-oltre-i-salti)»: A421 · SEGUITO 3 (par. 8.3), il rig lo conta su ogni «non certo».
                uncertainRejoins += 1
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
        leadInUnoBuffer = nil
        if useEngineLeadIn {
            // A421 · SEGUITO 4 (par. 3.1): come il motore al fuoco (`fireDirectorRejoinQ`): l'origine del DSP sull'«uno» e la
            // posizione sul seme, l'«uno» meno la scorta, quando il piano della scorta c'e' (`DirectorRejoinDecision.leadIn`); senza
            // piano la posizione sull'«uno» e nessuna scorta. La scorta finisce nella chiamata del buffer che porta l'«uno».
            if let plan = DirectorRejoinDecision.leadIn(targetOutputTicks: ticks(wait.targetAt), outputLatencyTicks: ticks(latency),
                                                        unoBeat: dspOrigin, bpm: bpm, bufferFrames: 512, sampleRate: nodeRate,
                                                        ioBufferSeconds: cycleSeconds, ticksPerSecond: OutputRig.tps) {
                var dsp = RigLeadIn(unoBeat: dspOrigin, samplesPerBeat: samplesPerBeat)
                dsp.setBeatPositionTimeOnly(plan.seedBeat)
                rejoinLeadIn = dsp
                position = plan.seedBeat
            } else {
                rejoinLeadIn = nil
                position = dspOrigin
            }
        } else {
            // Il rig di prima: la posizione sull'«uno» e la scorta per `leadInBuffers` chiamate.
            position = dspOrigin
            leadInBuffersLeft = leadInBuffers
        }
        chain += 1
        cancelGuardian()
        bufferCount = 0
        meterScarto = 0
        countedBeatOut = false
        rejoinUnoOutAt = nil
        openChainForSoloDelta(outStart: nil, anchored: true)   // A437 · SEGUITO 5: come `openBufferChainQ`
        syncSkip = DirectorRejoinDecision.uncorrectedFireBuffers
        scheduleNextBuffer(at: t, chainStart: true)
        scheduleNextBuffer(at: t, chainStart: true)
        scheduleNextBuffer(at: t, chainStart: true)
        // A425 (P14): dopo la catena del fuoco, il rientro è fatto: la causa ricordata e lo Stop voluto si azzerano, come il Play
        // (`fireDirectorRejoinQ`, prima di `leaveDirectorSilenceQ`). Il fuoco che non parte (più sopra, `crisisStop`) non azzera niente.
        if useRejoinFireClearsMemory && !rejoinFireClearsMemoryAtTheTop {
            crisisCause = nil
            wantedStop = false
            forgetRemovalDuringInterruption(reason: "rientro")   // A437 · PARTE 2 — C.1, per simmetria
            memoryClearedAtRejoinFire += 1
        }
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

    /// La scorta del rientro e' viva: dal fuoco alla chiamata del buffer che porta l'«uno», compresa (A421 · SEGUITO 4, par. 3.1:
    /// `_rejoinLeadInQ != nil`, letto dal verdetto del buco e dal blocco della fase); spento l'interruttore, la scorta di prima.
    var inLeadIn: Bool { useEngineLeadIn ? rejoinLeadIn != nil : leadInBuffersLeft > 0 }
    var skipsCorrectionNow: Bool { syncSkip > 0 }

    /// A432 · parte 2d (K2) — l'ora dopo la quale l'àncora tenuta dal rientro si chiude, come `checkAnchorHeldByRejoinQ` nel motore:
    /// l'ora d'uscita del primo battito contato del rientro, l'«uno»; `nil` finché l'«uno» non è contato (nel motore
    /// `_lastCountedBeatQ` è `nil` dall'avvio del rientro fino al buffer che porta l'«uno»: la scorta è muta e più corta di mezzo
    /// battito). Con la scorta del motore: `nil` finché la scorta è viva, poi `rejoinUnoOutAt`, l'ora vera (col bersaglio solo
    /// senza correzioni nella scorta). Senza il piano della scorta, o col rig di prima (`useEngineLeadIn` spento), l'«uno» sta nel
    /// primo buffer della catena, contato al fuoco, ed esce al bersaglio (`firstBeatOutAt`). Spento `useEngineHeldAnchorClose`:
    /// sempre il bersaglio, com'era.
    /// La differenza che resta col motore: il motore guarda l'ULTIMO battito contato, il rig l'«uno». Sono lo stesso battito
    /// finché il battito dopo l'«uno» non si programma, e di regola si programma quando l'«uno» è uscito da un pezzo (un battito
    /// meno la coda dei buffer) e l'àncora tenuta è già chiusa. Solo se si programmasse PRIMA che l'ora dell'«uno» sia passata
    /// (una correzione in avanti di quasi un battito fra il buffer dell'«uno» e la sua uscita) nel motore l'àncora tenuta
    /// aspetterebbe l'uscita di quel battito; il rig non tiene l'ora d'uscita dei battiti dopo l'«uno» (`countedBeatOut` dice
    /// solo che uno si è programmato) e chiude all'uscita dell'«uno».
    var heldAnchorCloseAt: Double? {
        guard useEngineHeldAnchorClose else { return firstBeatOutAt }
        if useEngineLeadIn {
            if rejoinLeadIn != nil { return nil }
            if let unoOut = rejoinUnoOutAt { return unoOut }
        }
        return firstBeatOutAt
    }

    /// A421 · SEGUITO 2 (par. 4.2): il guardiano scatta: le condizioni dell'armo, poi il silenzio se il volume è a 1.
    mutating func fireGuardian(at t: Double) {
        guard let armed = guardian else { return }
        guardian = nil
        guard armed.chain == chain, armed.bufferCount == bufferCount, isRunning, !systemInterruption, mediaServicesNormal,
              RenderGapDecision.guardsAgainstHoles(playerRole: role, showOpen: showOpen, songInProgress: songInProgress) else { return }
        guard !state.muted else { return }
        silenceNow(reason: "buco-in-corso")
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
        // `handleRenderGapCrisisQ`: lo 0 «buco-del-render» trova di norma lo stato già muto (lo 0 «buco» della chiamata): il ricordo
        // resta «buco» (par. 5).
        silenceNow(reason: "buco-del-render", at: t)
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
        case .soloResumeOnSong:
            // A437 · PARTE 2 (P6, P25, P32): con l'uscita sparita E2 con la causa «uscita-tolta»; se no l'àncora prima
            // dell'arresto, l'arresto locale, l'annullo dei ritorni e il ritorno del Solo con l'innesco `renderGap`.
            if reason == .outputVanished {
                abandonSoloResume(reason: "uscita-sparita-al-buco", cause: .outputRemoved)
            } else {
                let take = takeSoloAnchor(cause: .renderGap)
                if isRunning { crisisStop() }
                afterSoloCrisisStop(take)
                cancelReturns()
                if soloResumePending {
                    let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: hardwareRate != copyRate)
                    directorReturn = DirectorReturn(wait: wait, fireAt: t + OutputReturnDecision.directorWaitSeconds(wait),
                                                    trigger: .renderGap, armedAt: t, kind: .solo)
                }
            }
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

    /// A421 · SEGUITO 3 (par. 4) — `lowerFirstCorrectionMarkWithoutCorrectionQ`: nei rami senza correzione (il Solo, l'assert) il segno
    /// della prima correzione dopo la finestra si abbassa, senza riarmo, una volta per finestra (la riga «segno abbassato, nessun
    /// riarmo»). Com'era (regola spenta): nel Solo e nell'assert il segno restava alto.
    mutating func lowerFirstCorrectionMarkWithoutCorrection() {
        guard useFirstCorrectionMarkLowering, firstCorrectionPending else { return }
        firstCorrectionPending = false
        firstCorrectionLoweredWithoutCorrection += 1
    }

    /// `scheduleNextBuffer`: la guardia, il motore di sistema fermo (par. 2.2 a), il drenaggio, il misuratore (U7, U8), il
    /// ritorno del Follower (par. 2.2 c; seguito 1, par. 2.2: le due ore, la rilettura dell'«uno», la guardia del primo
    /// campione, la battuta dopo), l'assert o la correzione (U9), il buffer.
    /// ⚠️ A437 · SEGUITO 5: `chainStart` dice le tre chiamate della partenza di una catena; ogni altra chiamata è un richiamo e
    /// si conta (`_chainCallbacksQ`, che nel motore sale in `bufferCallbackQ` prima di questa funzione).
    mutating func scheduleNextBuffer(at t: Double, idealAt: Double? = nil, gapSeconds: Double? = nil, correction: Double? = nil,
                                     chainStart: Bool = false) {
        guard isRunning else { return }
        if !chainStart { chainCallbacks += 1 }
        // A421 · SEGUITO 2 (par. 3.3): l'àncora tenuta dal rientro si chiude quando il primo battito contato del rientro è uscito.
        // ⚠️ A432 · parte 2d (K2): l'ora non è più sempre il bersaglio (`firstBeatOutAt`, com'era e come resta con
        // `useEngineHeldAnchorClose` spento): è l'ora d'uscita vera dell'«uno» contato (`heldAnchorCloseAt`).
        if anchorHeld, let out = heldAnchorCloseAt, t >= out {
            closeAnchor(at: t)
        }
        checkSoloAnchorHeld(at: t)   // A437
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
        // ⚠️ A437 · SEGUITO 5 (19/11/2026): qui c'era «A437: la lettura di Δ del Solo in canzone, a regime (non nella chiamata di
        // un buco, e solo col render fresco)», con la lettura aggiunta dal rig senza passare dalla regola. Ora la lettura sta in
        // fondo alla chiamata, dopo che il buffer è prodotto, come nel motore, e passa dalla regola pura (`noteSoloDelta`).
        // Come nel motore (`soloDeltaInRegime`) la lettura non è a regime nella chiamata di un buco né in quella dopo uno scatto
        // del guardiano (nota C1 del verificatore V2 del seguito 5: la prima stesura guardava solo il buco).
        var soloDeltaInRegime = gapSeconds == nil
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
                // Come il motore: lo 0 «buco» prima della crisi (par. 5).
                if RenderGapDecision.guardsAgainstHoles(playerRole: role, showOpen: showOpen, songInProgress: songInProgress)
                    && !state.muted { silenceNow(reason: "buco", at: t) }
                renderGapCrisis(at: t, reason: .window)
                return
            }
        }
        if let hole = gapSeconds, useMeterCrisis {
            let guards = RenderGapDecision.guardsAgainstHoles(playerRole: role, showOpen: showOpen, songInProgress: songInProgress)
            guardianSilenceChain = nil
            // Par. 4.3: il silenzio prima della lettura del percorso e della decisione, se il guardiano non è arrivato prima.
            if guards && !state.muted { silenceNow(reason: "buco", at: t) }
            // A421 · SEGUITO 3 (par. 5): la misura del buco (`logRenderGapMeasureQ`), dopo il silenzio di questa chiamata.
            lastHoleMeasure = holeMeasure(at: t, hole: hole)
            let verdict = RenderGapDecision.verdict(RenderGapDecision.Situation(
                holeSeconds: hole, playerRole: role, showOpen: showOpen, songInProgress: songInProgress, engineRunning: isRunning,
                followsLink: followsLink, inLeadIn: inLeadIn,
                // A437 · PARTE 2: anche il Solo in canzone (P32).
                externalVanished: (role == .direttore || (role == .solo && guards)) && externalVanishedNow,
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
            soloDeltaInRegime = false
            guardianSilenceChain = nil
            let guardsNow = RenderGapDecision.guardsAgainstHoles(playerRole: role, showOpen: showOpen, songInProgress: songInProgress)
            if silenceChain == chain && guardsNow && role == .solo {
                // A437 · PARTE 2: nel Solo in canzone il silenzio del guardiano non ha un «ritorno dopo il buco»: è la crisi, e la
                // ripresa sulla canzone; con l'uscita sparita il Solo si ferma come allo Stop. Il buffer non si programma.
                renderGapCrisis(at: t, reason: externalVanishedNow ? .outputVanished : .hole)
                return
            }
            if silenceChain == chain && guardsNow {
                armGapReturn(at: t, renderNext: renderNext)
            }
        }
        // Par. 2.3 b: un ritorno armato con una catena che non è più quella corrente si riarma con la stessa regola.
        if let armed = followerReturn, !armed.armPending, armed.chain != chain {
            rearmFollowerReturn()
        }
        // Seguito 1, par. 2.2: la rilettura dell'«uno», a ogni chiamata col ritorno armato e un «uno» scelto; seguito 2 (E.9): e il metro.
        if var armed = followerReturn, !armed.armPending, let uno = armed.uno {
            // A432 · parte 2b (voce i): un «uno» del conto resta del conto finché il conto è certo (`unoClockNow`).
            let clockNow = OutputReturnDecision.unoClockNow(saved: uno.clock, followsLink: followerClock == .link,
                                                            bandCountCertain: FollowerBandUno.isCertain(bandCount))
            switch OutputReturnDecision.refreshUno(saved: uno, clockNow: clockNow, beatsPerBarNow: beatsPerBar,
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
        var ownFirstPinThisCall = false
        if ownRepinPending && followerClock == .own {
            ownRepinPending = false
            let beatNow = ownBeatAtChange + (t - ownChangeTime) * ownTimelineBPM / 60.0
            ownTimeline = OwnClockTimeline(anchorTicks: ticks(t), anchorBeat: beatNow, bpm: ownTimelineBPM)
            ownFirstPinThisCall = true
        }
        // La finestra «sync skip»: il contatore scende; la correzione di fase non gira.
        if syncSkip > 0 { syncSkip -= 1 }
        let skipsCorrection = skipAtCallStart > 0
        // Il blocco della fase, PRIMA dei controlli dei ritorni, come nel motore (A421 · SEGUITO 3, par. 8.2: `checkFollowerReturnQ`
        // e `checkGapReturnQ` stanno in fondo a `scheduleNextBuffer`, dopo la correzione): così un riarmo fatto dalla prima correzione
        // dopo la finestra sposta la scadenza prima che la chiamata decida se il volume torna.
        // A437 · PARTE 2 (§B.4): una chiamata della scorta del rientro col segno della prima correzione dopo la finestra alto.
        if inLeadIn && firstCorrectionPending { leadInCallsWithTheMarkUp += 1 }
        var mutedThisBuffer = false
        if skipsCorrection {
            // La finestra: né assert né correzione.
        } else if role == .solo {
            // A421 · SEGUITO 3 (par. 4): nel Solo nessuna correzione arriva mai (il ramo di `soloLockPassesQ(.phaseCorrection)`): il
            // segno della prima correzione dopo la finestra si abbassa alla prima chiamata dopo la finestra, senza riarmo.
            lowerFirstCorrectionMarkWithoutCorrection()
        } else if role == .direttore && !followsLink {
            asserts += 1
            // A421 · SEGUITO 3 (par. 4): l'assert non è una correzione: il segno si abbassa qui, senza riarmo.
            lowerFirstCorrectionMarkWithoutCorrection()
        } else if useEngineLeadIn, let lead = rejoinLeadIn,
                  !DirectorRejoinDecision.leadInAllowsCorrection(correctionsSoFar: lead.corrections) {
            // A421 · SEGUITO 4 (par. 3.1): nella scorta, dopo la prima correzione, nessuna correzione (quella che il banco passa non si
            // applica) e il segno resta fino alla fine della scorta, come il motore. A zero correzioni la scorta fa come la chiamata di
            // Link, qui sotto: una correzione si applica, si conta nella scorta e consuma il segno; senza correzione il segno si
            // consuma. ⚠️ RISCRITTO A421 · SEGUITO 4: qui c'era `inLeadIn && correction == nil`, «la scorta del rientro senza
            // correzione (`leadInAllowsCorrection` falso): il segno resta», per ogni chiamata della scorta senza correzione, e ogni
            // correzione passata si applicava; resta col rig di prima, qui sotto.
        } else if !useEngineLeadIn && inLeadIn && correction == nil {
            // Il rig di prima (interruttore spento): ogni chiamata della scorta senza correzione teneva il segno.
        } else if ownFirstPinThisCall {
            // L'orologio proprio appena ancorato (`ownClockPinQ` senza la linea): nessuna correzione, il segno resta.
        } else if let delta = correction,
                  !(useEngineSyncThreshold && abs(delta) <= OutputRig.phaseJumpThresholdBeats) {
            // A425 (par. 2.5): solo una correzione sopra la soglia di Link (`fabs(delta) > threshold`, LinkEngine.mm:647) arriva qui;
            // quelle di al più 0,01 battiti fanno il ramo «nessuna correzione» qui sotto, come il motore.
            corrections += 1
            // A432 · parte 2b (P38) — come `noteLateBeatCorrectionQ` da A432: il battito in attesa lo dice il DSP dopo la correzione
            // (`metronome_pending_beat`), poi `lateBeats(pendingBeat:after:)` e `mutesLateBeat`. In questo rig il DSP è la griglia
            // «origine più interi» (`rigPendingBeatAfterCorrection`): nessun salto frazionario fa saltare un battito al DSP, e il
            // getter coincide con la ricostruzione di prima (`LateBeatDecision.mutes(origin:…)`, che stava qui); il caso in cui
            // non coincidono è nel rig del conto, col modello del DSP (`FollowerBandRigTests`).
            let pendingAfter = rigPendingBeatAfterCorrection(before: position, after: position + delta)
            if LateBeatDecision.mutesLateBeat(lateBeats: LateBeatDecision.lateBeats(pendingBeat: pendingAfter, after: position + delta),
                                              bpm: bpm, bufferFrames: 512, sampleRate: nodeRate) {
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
            // A421 · SEGUITO 4 (par. 3.1): la prima correzione nella scorta si conta e sposta il DSP (`metronome_set_beat_position_time_only`).
            if useEngineLeadIn, var lead = rejoinLeadIn {
                lead.corrections += 1
                lead.setBeatPositionTimeOnly(position + delta)
                rejoinLeadIn = lead
            }
            position += delta
        } else {
            // A425 (par. 2.5): una correzione passata dal banco ma sotto la soglia non si applica: si conta a parte.
            if correction != nil { correctionsUnderThreshold += 1 }
            if firstCorrectionPending {
                // La chiamata di Link senza correzione: il segno si consuma come oggi (`noteCorrectionAfterWindowQ` con prima = dopo).
                firstCorrectionPending = false
            }
        }
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
                } else if let uno = pending.uno, let next = nextBarUno(after: uno) {
                    pending.uno = next
                    pending.unoAt = unoTime(for: next)
                    if pending.unoAt == nil { pending.armPending = true }
                    followerReturn = pending
                    nextBarMoves += 1
                } else if let uno = pending.uno, uno.clock == .band {
                    // A432 · parte 2b (voce i): la battuta dopo non data dal conto riarma con la stessa regola.
                    rearmFollowerReturn()
                }
            case .restore:
                followerReturn = nil
                if conditions {
                    restoreVolume()
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
                        restoreVolume()
                        gapReturnRestores += 1
                        gapRestoredAt = t
                        gapFirstSampleAt = firstSample
                        gapDeadlineAt = deadline
                    }
                }
            }
        }
        let beatInBuffer: Bool
        if useEngineLeadIn, var lead = rejoinLeadIn {
            // A421 · SEGUITO 4 (par. 3.1): nella scorta il bordo del DSP, in campioni interi. La scorta e' muta fino all'«uno» e finisce
            // nella chiamata il cui buffer, dopo la correzione di quella chiamata, porta l'«uno» (anche al primo campione, quando la
            // correzione lo ha scavalcato), dopo il verdetto del buco e il blocco della fase: `noteRejoinFirstClickQ`, dal ciclo dei
            // battiti. L'«uno» si conta qui, con la sua ora d'uscita (il bersaglio, `firstClickAt`): l'àncora lo prende solo dopo
            // che e' uscito (`takeSilenceAnchorQ` vuole un battito contato gia' uscito), anche dopo la chiusura dell'àncora tenuta
            // (`rejoinUnoOutAt`). `countedBeatOut`, che il rig alza quando un battito si programma, nella scorta non si alza:
            // l'«uno» si programma prima di uscire.
            // ⚠️ A432 · parte 2c: «(il bersaglio, `firstClickAt`)» qui sopra vale solo senza correzioni nella scorta. L'ora d'uscita
            // dell'«uno» si conta come quella di ogni battito nel motore (`scheduleNextBuffer`: `_lastBeatOutTicksQ`, l'ora d'uscita
            // del buffer in cui cade più il suo scostamento nel buffer). I buffer della catena escono uno dietro l'altro e quello
            // d'indice `leadInBuffers` esce al bersaglio (il primo, ancorato, esce al bersaglio meno la scorta:
            // `DirectorRejoinDecision.leadIn`); questo, d'indice `bufferCount`, esce `bufferCount - leadInBuffers` buffer dopo il
            // bersaglio (prima, se il numero è negativo). Un «uno» scavalcato da una correzione esce al primo campione del buffer di
            // questa chiamata (scostamento 0), prima del bersaglio; uno portato avanti, nel buffer prima col suo scostamento. Senza
            // correzioni: indice `leadInBuffers`, scostamento 0, cioè il bersaglio alla lettera. L'ora del buffer qui è quella della
            // catena (la `oraCatena` della riga «primo click» del motore), non la convenzione «adesso + latenza + ciclo» di
            // `_bufferOutTicksQ`: i richiami del banco nella scorta non seguono il passo del lettore. Spento l'interruttore
            // (`useEngineRejoinUnoOutTime`): il bersaglio, com'era.
            let unoHere = lead.carriesPendingBeat(frames: 512)
            // Lo scostamento dell'«uno» nel buffer di questa chiamata, in campioni: il suo campione arrotondato meno il cursore,
            // prima che il cursore avanzi.
            let unoOffsetSamples = lead.pendingBeatSample.rounded() - lead.cursor
            lead.cursor += 512
            rejoinLeadIn = unoHere ? nil : lead
            if unoHere {
                leadInUnoBuffer = bufferCount
                if useEngineRejoinUnoOutTime, let targetOut = firstClickAt {
                    rejoinUnoOutAt = targetOut + Double(bufferCount - leadInBuffers) * bufferSeconds + unoOffsetSamples / nodeRate
                } else {
                    rejoinUnoOutAt = firstClickAt
                }
            }
            beatInBuffer = unoHere
        } else {
            if leadInBuffersLeft > 0 { leadInBuffersLeft -= 1 }
            if useEngineBeatZero {
                // A425 (B.2 del seguito 4): come il DSP, il buffer porta i battiti dal suo primo campione, compreso, all'ultimo,
                // escluso (core_engine/MetronomeDSP.cpp:435-439, il battito arrotondato in [cursore, cursore + 512)): il battito zero
                // del Play sta nel primo buffer. Il primo battito del primo buffer di una catena esce a `firstBeatOutAt` (al Play una
                // latenza dopo, al fuoco il bersaglio): non alza `countedBeatOut`, che il rig alza quando un battito si programma.
                let firstBeat = (position - dspOrigin).rounded(.up)
                beatInBuffer = firstBeat < position + bufferBeats - dspOrigin || mutedThisBuffer
                if beatInBuffer && bufferCount > 0 { countedBeatOut = true }
            } else {
                beatInBuffer = (position + bufferBeats - dspOrigin).rounded(.down) > (position - dspOrigin).rounded(.down)
                    || mutedThisBuffer
                if beatInBuffer { countedBeatOut = true }
            }
        }
        if beatInBuffer && !mutedThisBuffer {
            clickSamplesWritten += 1
        }
        position += bufferBeats
        bufferCount += 1
        queued.append(RigBuffer(outputStart: outputStart, outputEnd: outputEnd, chain: chain))
        if queued.count > 3 { queued.removeFirst() }
        // A437 · SEGUITO 5: la lettura di Δ dopo che il buffer è prodotto (`noteSoloDeltaQ`, dopo `bufferCount += 1`): non a
        // regime nella chiamata di un buco né in quella dopo uno scatto del guardiano, e mai nelle chiamate che escono prima per
        // una crisi. `bufferCount` riparte da zero a ogni catena: `bufferCount - 1` è l'indice del buffer nella catena.
        noteSoloDelta(at: t, chainIndex: bufferCount - 1, regimeConvention: outputStart, inRegime: soloDeltaInRegime)
        // Seguito 2 (par. 4.2): il guardiano, a ogni chiamata che programma, col misuratore in regime (dalla quarta chiamata
        // della catena, con la base presente: non alla chiamata del buco): quattro buffer dall'ultima chiamata.
        if useGuardian && RenderGapDecision.guardsAgainstHoles(playerRole: role, showOpen: showOpen, songInProgress: songInProgress)
            && bufferCount >= 4 && gapSeconds == nil {
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
        // A437: il ritorno del Solo ha la sua guardia; il ramo del Direttore resta com'è.
        if waiting.kind == .solo {
            fireSoloReturn(waiting, at: t)
            return
        }
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

    /// A437 · PARTE 2 — la rete a 1 s della fine senza `shouldResume`: solo con la ripresa pendente ancora alta e lo stesso
    /// contatore della catena; abbassa la ripresa e riparte con l'innesco `safety_net_noresume`.
    mutating func fireNoResumeNet(at t: Double) {
        guard let net = noResumeNet else { return }
        noResumeNet = nil
        guard pendingResume, resumeToken == net.token else { return }
        noResumeNetFired += 1
        pendingResume = false
        activateSessionAndStart(trigger: .safetyNetNoResume, at: t)
    }

    mutating func fireSafetyNet(_ wait: RetryWait, at t: Double) {
        guard pendingResume, resumeToken == wait.token else {
            safetyNetSkipped += 1
            // A437 · seguito 1 (voce 2): la catena finisce qui senza avvio; se è ancora quella della ripresa del Solo, E2.
            if resumeToken == wait.token { endSoloResumeRoad(reason: "rete-senza-ripresa-pendente") }
            return
        }
        safetyNetFired += 1
        pendingResume = false
        activateSessionAndStart(trigger: .safetyNet, at: t, attempt: 1, token: wait.token)
    }

    /// Il tempo passa fino a `t`: le attese scadute scattano nell'ordine.
    mutating func advance(to t: Double) {
        guard t > now else { return }
        // A437 · seguito 1 (voce 2): l'invariante «nessuna pausa senza una strada in volo» lo guarda il rig stesso, in ogni
        // sequenza: quando il tempo riparte (lo stato lasciato dall'azione di prima) e dopo ogni attesa scattata.
        let pauseHadARoad = soloPauseInvariantHolds
        XCTAssertTrue(pauseHadARoad, "pausa senza una strada in volo prima di avanzare")
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
            if let f = soloFire, f.fireAt <= t { due.append((f.fireAt, 8)) }   // A437: il fuoco della ripresa del Solo
            if let n = noResumeNet, n.fireAt <= t { due.append((n.fireAt, 9)) }   // A437 · PARTE 2: la rete a 1 s senza shouldResume
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
            case 8: fireSoloResume(at: next.0)
            case 9: fireNoResumeNet(at: next.0)
            default:
                let wait = safetyNet!
                safetyNet = nil
                fireSafetyNet(wait, at: next.0)
            }
            let pauseHasARoad = soloPauseInvariantHolds
            XCTAssertTrue(pauseHasARoad, "pausa senza una strada in volo dopo un'attesa scattata")
        }
        now = t
    }

    // MARK: - A437 — la ripresa del Solo sulla posizione della canzone (mandato A437, par. 2 e 3; seguito 1)

    /// Una strada che fa ripartire la ripresa o la chiude è in volo: il ritorno del Solo armato, un tentativo della catena,
    /// la rete a 5 s, il fuoco armato.
    var soloRoadInFlight: Bool {
        (directorReturn?.kind == .solo) || retry != nil || safetyNet != nil || soloFire != nil
    }

    /// L'invariante del seguito 1, voce 2: nessuna pausa senza una strada in volo.
    var soloPauseInvariantHolds: Bool { !soloResumePending || soloRoadInFlight }

    /// Lo stato della ripresa dai tre valori che il motore tiene; `nil` = una combinazione che non esiste.
    var soloResumeState: SoloResumeState? {
        SoloResumeDecision.state(anchorAlive: soloAnchor != nil, pending: soloResumePending, heldByResume: soloAnchorHeld,
                                 engineRunning: isRunning)
    }

    /// La faccia della console del Solo: Stop col click che suona o nella pausa della ripresa (`LiveView.liveConsoleFaces`).
    var soloConsoleShowsStop: Bool { isPlaying || soloResumePending }

    /// L'ultimo battito della canzone già uscito all'ora `t` (l'ultimo battito contato con l'ora d'uscita non dopo adesso):
    /// dalla griglia della canzone del Solo. `nil` prima del primo battito, oltre la fine, senza griglia.
    func soloLastCountedBeat(at t: Double) -> (section: Int, beat: Int, outAt: Double)? {
        guard let grid = soloGrid, ticks(t) >= grid.anchor.ticks else { return nil }
        guard case .inSong(let section, let x) = grid.bySeconds(nowTicks: ticks(t), ticksPerSecond: OutputRig.tps).place else {
            return nil
        }
        let beat = Int((x + 1e-9).rounded(.down))
        guard let out = grid.ticks(section: section, beatInSection: beat, ticksPerSecond: OutputRig.tps) else { return nil }
        return (section, beat, seconds(out))
    }

    /// `closeSoloResumeQ`: il segno giù (e, se era alto, il contatore della catena sale: seguito 1, voce 3), l'àncora chiusa.
    mutating func closeSoloResume(reason: String) {
        if soloResumePending {
            soloResumePending = false
            resumeToken += 1
        }
        if soloAnchor != nil {
            soloAnchor = nil
            soloAnchorHeld = false
            soloClosures.append(reason)
        }
    }

    /// `deliveringDrain` (A437 · PARTE 2, seguito 2 §1 voce 4 g): E2 ed E3, come il motore (`closeDrainOnCrisisStopQ` dentro
    /// `abandonSoloResumeAsConsoleQ` e `endSoloSongOnResumeQ`), consegnano la chiusura di fine sezione rimasta aperta; la
    /// chiusura a fermo (`closeSoloResumeAtRestQ`) no.
    mutating func stopSoloEngineIfRunning(deliveringDrain: Bool = false) {
        guard isRunning else { return }
        isRunning = false
        engineRunning = false
        queued = []
        netAt = nil
        if deliveringDrain && drainPending {
            drainPending = false
            drainDelivered += 1
        }
    }

    /// E2 (`abandonSoloResumeAsConsoleQ`): il Solo si ferma come allo Stop della console, con lo Stop voluto alzato.
    mutating func abandonSoloResume(reason: String, cause: CrisisCause?) {
        soloE2.append(reason)
        soloFire = nil
        cancelReturns()
        stopSoloEngineIfRunning(deliveringDrain: true)
        if pendingResume { clearPendingResume() }
        closeSoloResume(reason: reason)
        if let cause {
            crisisCause = CrisisStopDecision.rememberedCause(previous: crisisCause, new: cause, playerRole: .solo)
        }
        wantedStop = true
        publishIsPlaying()
        soloStop()
    }

    /// `endSoloResumeRoadQ`: una strada della ripartenza finisce senza avvio con la ripresa in attesa: E2.
    @discardableResult
    mutating func endSoloResumeRoad(reason: String) -> Bool {
        guard role == .solo, soloResumePending else { return false }
        abandonSoloResume(reason: reason, cause: nil)
        return true
    }

    /// E3 (`endSoloSongOnResumeQ`): la canzone finisce prima del primo «uno» utile; il runner arma la successiva.
    mutating func endSoloSong(phase: String) {
        soloE3.append(phase)
        soloFire = nil
        cancelReturns()
        stopSoloEngineIfRunning(deliveringDrain: true)
        if pendingResume { clearPendingResume() }
        closeSoloResume(reason: "canzone-finita")
        songInProgress = false
        wantedStop = true
        stopCleanup()
        publishIsPlaying()
        runnerArmNext += 1
        playbackStopped = true
    }

    /// `closeSoloResumeAtRestQ`: il cambio di ruolo e lo show chiuso; col segno alto il player a «fermo».
    mutating func closeSoloResumeAtRest(reason: String) {
        let wasPending = soloResumePending
        closeSoloResume(reason: reason)
        guard wasPending else { return }
        soloFire = nil
        cancelReturns()
        stopSoloEngineIfRunning()
        songInProgress = false
        wantedStop = true
        stopCleanup()
        publishIsPlaying()
        playbackStopped = true
    }

    // MARK: - A437 · SEGUITO 5 — le letture di Δ dalla regola pura

    /// `resetSoloDeltaQ`: le letture, la memoria delle convenzioni e i contatori si svuotano, l'epoca sale.
    mutating func resetSoloDelta() {
        soloDeltaReadings = []
        soloDeltaTally = SoloDeltaTally()
        soloDeltaEpoch += 1
        soloEpochFirstBuffer = bufferCount
        for slot in 0..<SoloResumeDecision.deltaMemory { soloOutRingIndex[slot] = -1 }
    }

    /// `openBufferChainQ`, per quello che serve alle letture: i richiami ripartono e le letture si azzerano. Si chiama dopo
    /// `bufferCount = 0`. `outStart`: l'uscita vera del buffer 0 della catena; `anchored`: la catena del fuoco di una ripresa.
    mutating func openChainForSoloDelta(outStart: Double?, anchored: Bool) {
        chainCallbacks = 0
        soloChainOutStart = outStart
        soloChainAnchored = anchored
        soloChainConventions = []
        resetSoloDelta()
    }

    /// `noteSoloDeltaQ`: la convenzione del buffer appena prodotto va in memoria; a regime, la lettura dalla regola pura in due
    /// passi, e un esito nei contatori. `regimeConvention`: adesso + latenza + ciclo (`_bufferOutTicksQ`).
    mutating func noteSoloDelta(at t: Double, chainIndex: Int, regimeConvention: Double, inRegime: Bool) {
        var convention = regimeConvention
        if soloChainAnchored, chainIndex < SoloResumeDecision.chainStartBuffers, let start = soloChainOutStart {
            // I tre buffer ancorati: l'ora vera della catena (`_anchoredOutputTicksQ + indice × buffer`).
            convention = start + Double(chainIndex) * bufferSeconds
        }
        soloChainConventions.append(convention)
        guard role == .solo, showOpen, songInProgress else { return }
        let memory = SoloResumeDecision.deltaMemory
        soloOutRingIndex[chainIndex % memory] = chainIndex
        soloOutRingTicks[chainIndex % memory] = ticks(convention)
        guard inRegime else { return }
        let wanted = chainCallbacks
        let cycleTicks = ticks(cycleSeconds)
        if let early = SoloResumeDecision.deltaReadingGate(wantedIndex: wanted,
                                                           wantedInChainMemory: soloOutRingIndex[wanted % memory] == wanted,
                                                           cycleTicks: cycleTicks, sampleRate: nodeRate,
                                                           ticksPerSecond: OutputRig.tps, bufferFrames: 512) {
            soloDeltaTally.noteBeforeRead(early)
            return
        }
        let conventionTicks = soloOutRingTicks[wanted % memory]
        let latencyTicks = ticks(latency)
        let lastRender: UInt64
        let nowTicks: UInt64
        if !soloRenderFresh {
            // Il render fermo: L resta indietro.
            nowTicks = ticks(t)
            lastRender = nowTicks - ticks(soloRenderBehindSeconds)
        } else if soloRealRender, let phase = renderPhaseSeconds, let start = soloChainOutStart {
            // Il modo realistico: L = l'inizio del rendering di `wanted` sulla linea della catena + ψ; adesso = la chiamata.
            nowTicks = ticks(t)
            lastRender = ticks(start - latency + Double(wanted) * bufferSeconds + phase)
        } else {
            // Il modo di prima: L ricavata dalla Δ data, due cicli avanti.
            lastRender = conventionTicks + ticks(soloDeltaSeconds) + cycleTicks / 2 - latencyTicks
            nowTicks = lastRender - 2 * cycleTicks
        }
        let outcome = SoloResumeDecision.deltaReading(renderTimeValid: true, lastRenderTicks: lastRender, nowTicks: nowTicks,
                                                      cycleTicks: cycleTicks, latencyTicks: latencyTicks,
                                                      conventionTicks: conventionTicks, bufferTicks: ticks(bufferSeconds),
                                                      queuedAheadBuffers: OutputReturnDecision.queuedAheadBuffers)
        soloDeltaTally.noteAfterRead(outcome, renderTimeValid: true, lastRenderTicks: lastRender, nowTicks: nowTicks)
        guard case .valid(let delta) = outcome else { return }
        soloDeltaReadings.append(SoloDeltaReading(deltaTicks: delta, readTicks: ticks(t)))
        if soloDeltaReadings.count > SoloResumeDecision.deltaMemory { soloDeltaReadings.removeFirst() }
    }

    /// L'indice nella catena del buffer che ha portato un battito uscito a `outAt` (i buffer escono uno dietro l'altro da
    /// `soloChainOutStart`); `nil` senza l'ora della catena.
    func soloBeatBufferIndex(outAt: Double) -> Int? {
        guard let start = soloChainOutStart else { return nil }
        return max(Int(((outAt - start) / bufferSeconds + 1e-6).rounded(.down)), 0)
    }

    /// L'ora della convenzione di un battito uscito a `outAt` (`_lastBeatOutTicksQ`: la convenzione del suo buffer più lo
    /// scostamento). Nel modo realistico dalla convenzione scritta per quel buffer; nel modo di prima l'uscita vera meno
    /// `soloDeltaSeconds`, salvo nei tre buffer della catena ancorata, dove è l'uscita vera.
    func soloBeatConvention(outAt: Double, bufferIndex: Int?) -> Double {
        if soloRealRender {
            if let index = bufferIndex, index < soloChainConventions.count, let start = soloChainOutStart {
                return soloChainConventions[index] + (outAt - (start + Double(index) * bufferSeconds))
            }
            return outAt - soloTrueDeltaSeconds
        }
        if soloChainAnchored, let index = bufferIndex, index < SoloResumeDecision.chainStartBuffers { return outAt }
        return outAt - soloDeltaSeconds
    }

    /// Par. 3 g del seguito 5 (`handleRouteChange`, «Path senza cambio né SR né mode», e `resetSoloDeltaOnTimingChangeQ`): una
    /// notizia di percorso di classe «nessuna», senza cambio di frequenza né di modo, riscrive latenza e ciclo a catena viva.
    /// Le letture si azzerano solo se uno dei due cambia davvero.
    mutating func routeNewsRewritesTiming(at t: Double, latency newLatency: Double? = nil, cycleSeconds newCycle: Double? = nil) {
        advance(to: t)
        guard mediaServicesNormal, !systemInterruption, !pendingResume else { return }
        let latencyBefore = ticks(latency)
        let cycleBefore = ticks(cycleSeconds)
        if let newLatency { latency = newLatency }
        if let newCycle { cycleSeconds = newCycle }
        guard let reason = SoloResumeDecision.deltaResetReason(latencyBeforeTicks: latencyBefore, latencyNowTicks: ticks(latency),
                                                               cycleBeforeTicks: cycleBefore, cycleNowTicks: ticks(cycleSeconds)) else {
            return
        }
        resetSoloDelta()
        if isRunning && role == .solo { soloDeltaResets.append(reason) }
    }

    /// `takeSoloAnchorQ`: l'àncora alla crisi, prima dell'arresto. L'ora vera è quella della convenzione (nel rig l'ora
    /// d'uscita vera meno `soloDeltaSeconds`) più Δ dalle letture valide.
    /// ⚠️ CORRETTO A437 · SEGUITO 5 (19/11/2026): «nel rig l'ora d'uscita vera meno `soloDeltaSeconds`» vale nel modo di prima e
    /// per un battito di regime (`soloBeatConvention`); e Δ si somma solo a un battito di regime (par. 2.3): un battito di uno dei
    /// tre buffer della partenza, o di prima di un azzeramento, prende Δ = 0 e la lettura «avvio». Alla presa si tengono i
    /// contatori delle letture, come la riga `letture di delta` (`soloLastTally`).
    mutating func takeSoloAnchor(cause: CrisisCause) -> SoloAnchorTake {
        let last = soloLastCountedBeat(at: now)
        let take = SoloResumeDecision.anchorTake(playerRole: role, showOpen: showOpen, songInProgress: songInProgress,
                                                 stoppingCauseRemembered: crisisCause?.stopsSolo ?? false,
                                                 engineRunning: isRunning, drainOpen: drainPending,
                                                 anchorAlive: soloAnchor != nil, mapValid: soloMap?.isValid ?? false,
                                                 countedBeatOut: last != nil, beatInCycle: false)
        switch take {
        case .taken:
            guard let last, let grid = soloGrid else { return .notTaken(.noMap) }
            let beatBuffer = soloBeatBufferIndex(outAt: last.outAt)
            let beatIndex = beatBuffer ?? -1
            let beatEpoch = SoloResumeDecision.beatDeltaEpoch(
                bufferChainIndex: beatIndex, epoch: beatIndex >= soloEpochFirstBuffer ? soloDeltaEpoch : soloDeltaEpoch - 1)
            let delta = SoloResumeDecision.anchorDelta(
                fromReadings: SoloResumeDecision.delta(readings: soloDeltaReadings),
                beatOnRegimeConvention: SoloResumeDecision.beatOnRegimeConvention(beatEpoch: beatEpoch, currentEpoch: soloDeltaEpoch))
            let trueTicks = SoloResumeDecision.anchorTicks(
                conventionTicks: ticks(soloBeatConvention(outAt: last.outAt, bufferIndex: beatBuffer)), delta: delta)
            soloAnchor = ShowClock(map: grid.map, anchor: ShowClockAnchor(section: last.section, beatInSection: last.beat,
                                                                          linkBeat: 0, ticks: trueTicks))
            soloAnchorSongIdx = soloSongIdx
            soloAnchorHeld = false
            soloAnchorsTaken += 1
            soloLastDelta = delta
            soloLastTally = soloDeltaTally
            soloResumePending = true
        case .alreadyAlive:
            soloAnchorHeld = false
            soloResumePending = true
        case .drainDelivered:
            closeSoloResume(reason: "drenaggio")
        case .notTaken:
            break
        }
        return take
    }

    /// `afterSoloCrisisStopQ`: senza àncora E2; con una causa che ferma il Solo già ricordata niente (lo Stop è in arrivo).
    mutating func afterSoloCrisisStop(_ take: SoloAnchorTake) {
        if case .notTaken(let why) = take, why != .stoppingCause {
            abandonSoloResume(reason: "ancora-non-presa(\(why.rawValue))", cause: nil)
        }
    }

    /// `soloResumePlanQ`: il conto adesso; l'àncora di un'altra canzone vale come assente.
    func soloPlan(at t: Double, notBeforeTicks: UInt64 = 0) -> SoloResumePlan {
        let clock: ShowClock? = (soloAnchor != nil && soloAnchorSongIdx == soloSongIdx) ? soloAnchor : nil
        return SoloResumeDecision.plan(clock: clock, nowTicks: ticks(t), ticksPerSecond: OutputRig.tps, marginSeconds: margin,
                                       notBeforeTicks: notBeforeTicks)
    }

    /// `soloResumePreCheckQ`: all'ingresso di `activateSessionAndStart`, prima di ogni scrittura della sessione.
    mutating func soloPreCheck(at t: Double) -> Bool {
        guard role == .solo, soloResumePending else { return true }
        soloPreChecks += 1
        switch soloPlan(at: t) {
        case .resume:
            return true
        case .songEnded:
            endSoloSong(phase: "pre-controllo")
            return false
        case .uncertain:
            abandonSoloResume(reason: "non-certo", cause: nil)
            return false
        }
    }

    /// `coordinateSoloResumeQ`: il bersaglio, oppure E3 o E2 già eseguiti (`nil`).
    mutating func coordinateSoloResume(phase: String, at t: Double, notBeforeTicks: UInt64 = 0) -> SoloResumeAim? {
        switch soloPlan(at: t, notBeforeTicks: notBeforeTicks) {
        case .resume(let aim):
            return aim
        case .songEnded:
            endSoloSong(phase: phase)
            return nil
        case .uncertain:
            abandonSoloResume(reason: "non-certo", cause: nil)
            return nil
        }
    }

    /// `armSoloResumeQ`: il timer del fuoco, col margine e col «lettore lento» come il rientro del Direttore.
    mutating func armSoloResume(_ aim: SoloResumeAim, skipsLeft: Int, fromSlowPlayer: Bool) {
        let targetAt = seconds(aim.targetTicks)
        let slow = !fromSlowPlayer
            && DirectorRejoinDecision.slowPlayerAtArming(nowTicks: ticks(now), targetOutputTicks: aim.targetTicks,
                                                         distanceTicks: ticks(firstBufferDistance),
                                                         minLeadTicks: ticks(DirectorRejoinDecision.minLeadSeconds))
        soloFire = SoloFireWait(aim: aim, fireAt: slow ? now : max(targetAt - margin, now), skipsLeft: skipsLeft, slowPlayer: slow)
    }

    /// `fireSoloResumeQ`: la guardia, il ritardo coi salti (il bersaglio nuovo sempre dopo quello mancato), l'ingresso.
    mutating func fireSoloResume(at t: Double) {
        guard let wait = soloFire, isRunning else {
            soloFire = nil
            return
        }
        soloFire = nil
        let sameSong = soloAnchor != nil && soloAnchorSongIdx == soloSongIdx
        let sectionInMap = soloAnchor.map { wait.aim.section >= 0 && wait.aim.section < $0.map.sections.count } ?? false
        if let refusal = SoloResumeDecision.fireRefusal(playerRole: role, systemInterruption: systemInterruption,
                                                        servicesNormal: mediaServicesNormal, anchorAlive: soloAnchor != nil,
                                                        sameSong: sameSong, sectionInMap: sectionInMap, handlesPresent: true) {
            abandonSoloResume(reason: refusal.rawValue, cause: nil)
            return
        }
        guard let anchor = soloAnchor,
              let targetTicks = anchor.ticks(section: wait.aim.section, beatInSection: wait.aim.beatInSection,
                                             ticksPerSecond: OutputRig.tps) else {
            abandonSoloResume(reason: "non-certo", cause: nil)
            return
        }
        let targetAt = seconds(targetTicks)
        let renderAt = targetAt - (copiesDistance ?? firstBufferDistance)
        if t + DirectorRejoinDecision.minLeadSeconds > renderAt {
            soloLateFires += 1
            soloLateTargets.append(targetAt)
            switch SoloResumeDecision.lateStep(slowPlayer: wait.slowPlayer, lateSkipsLeft: wait.skipsLeft) {
            case .giveUp:
                abandonSoloResume(reason: "non-certo(ritardo-oltre-i-salti)", cause: nil)
            case .recount(let skipsLeft, _):
                if let next = coordinateSoloResume(phase: "ritardo", at: t, notBeforeTicks: targetTicks + 1) {
                    armSoloResume(next, skipsLeft: skipsLeft, fromSlowPlayer: wait.slowPlayer)
                }
            }
            return
        }
        soloResumes += 1
        soloFirstClickAt = targetAt
        soloFirstAim = wait.aim
        firstBeatOutAt = targetAt
        soloGrid = ShowClock(map: anchor.map, anchor: ShowClockAnchor(section: wait.aim.section, beatInSection: wait.aim.beatInSection,
                                                                      linkBeat: 0, ticks: targetTicks))
        runnerRejoins.append(wait.aim.section)
        rejoinLeadIn = nil
        chain += 1
        cancelGuardian()
        bufferCount = 0
        meterScarto = 0
        countedBeatOut = false
        // ⚠️ A437 · SEGUITO 5: qui c'era `soloDeltaReadings = []`. La catena della ripresa è ancorata: il suo buffer 0 esce al
        // bersaglio (il rig non gioca la scorta del Solo), e i primi tre hanno per convenzione l'ora vera della catena.
        openChainForSoloDelta(outStart: targetAt, anchored: true)
        dspOrigin = 0
        position = 0
        syncSkip = DirectorRejoinDecision.uncorrectedFireBuffers
        scheduleNextBuffer(at: t, chainStart: true)
        scheduleNextBuffer(at: t, chainStart: true)
        scheduleNextBuffer(at: t, chainStart: true)
        crisisCause = nil
        wantedStop = false
        soloResumePending = false
        soloAnchorHeld = true
    }

    /// `fireSoloReturnQ`: la guardia del Solo, l'uscita sparita (come la tolta), la ripartenza col suo innesco.
    mutating func fireSoloReturn(_ waiting: DirectorReturn, at t: Double) {
        let sameSong = soloAnchor != nil && soloAnchorSongIdx == soloSongIdx
        switch SoloResumeDecision.returnStep(engineRunning: isRunning, systemInterruption: systemInterruption,
                                             servicesNormal: mediaServicesNormal, playerRole: role, pending: soloResumePending,
                                             anchorAlive: soloAnchor != nil, sameSong: sameSong,
                                             externalVanished: externalVanishedNow) {
        case .notFired:
            soloReturnsNotFired += 1
            if soloResumePending && !isRunning {
                abandonSoloResume(reason: "ritorno-non-eseguito", cause: nil)
            }
        case .asRemoved:
            abandonSoloResume(reason: "uscita-sparita", cause: .outputRemoved)
        case .fire:
            soloReturnsFired += 1
            activateSessionAndStart(trigger: waiting.trigger, at: t)
        }
    }

    /// `checkSoloAnchorHeldQ`: l'àncora tenuta dalla ripresa si chiude al primo battito contato della ripresa uscito.
    mutating func checkSoloAnchorHeld(at t: Double) {
        if soloAnchorHeld, let out = firstBeatOutAt, t >= out {
            closeSoloResume(reason: "ripresa")
        }
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
        case .localStop, .asToday, .nothing, .soloResumeOnSong:
            break
        }
        guard isRunning else { return }
        interrupted = true
        crisisStop()
    }

    /// La fine dell'interruzione: la ripresa pendente, la guardia, l'hardware occupato, la ricostruzione del grafo e la ripartenza.
    /// A437 · PARTE 2 — `shouldResume` falso (la strada che il rig non aveva): come il motore, dopo il recupero della ripresa
    /// pendente e PRIMA della guardia e dell'hardware: con un'interruzione attiva e nessuno Stop voluto
    /// (`RecoveryDecision.raisesPendingOnEndedWithoutResume`) la ripresa pendente si rialza e si arma la rete a 1 s; se no niente.
    mutating func interruptionEnded(at t: Double, hardwareBusy busy: Bool = false, shouldResume: Bool = true) {
        advance(to: t)
        systemInterruption = false
        hardwareBusy = busy
        if pendingResume {
            pendingResume = false
            activateSessionAndStart(trigger: .pendingRecovery, at: t)
            return
        }
        if !shouldResume {
            guard RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: interrupted,
                                                                     wantedStopSinceCrisis: wantedStop) else { return }
            pendingResume = true
            noResumeNet = NoResumeNet(fireAt: t + 1.0, token: resumeToken)
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
        case .asToday, .nothing, .soloResumeOnSong:
            break
        }
        pendingResume = false
        interrupted = false
    }

    /// A421 · SEGUITO 4 (par. 3.2) — la Reset dei servizi audio dopo la Lost (la strada del rig: `servicesLost`, poi `rebuiltAndPlay`),
    /// per quello che tocca «canzone in corso»: sul Follower ferma con `stopSync(.followerReset)`, che la abbassa; sul Direttore non
    /// chiama `stopSync` (l'arresto locale non la tocca); il Solo in moto alla Lost l'ha gia' abbassata li' (`soloStop`). Il Solo in
    /// moto a una Reset senza Lost la abbassa con `stopForSoloCrisis` → `stopSync`: il rig la Reset senza Lost non la ha.
    mutating func mediaReset() {
        if useEngineSongInProgress && role == .follower { songInProgress = false }
    }

    /// A425 (B.10 del seguito 4) — la Reset dei servizi audio senza la Lost (`handleMediaReset`, esito «da ricostruire»): la crisi
    /// «reset-senza-lost» con la sua regola (il Solo in moto si ferma come allo Stop della console, `stopForSoloCrisis` →
    /// `stopSync(.soloCrisis)`, che abbassa «canzone in corso»; il Direttore in canzone muto, fuori canzone l'arresto locale; il
    /// Follower come oggi), la ripresa pendente sgomberata, i ritorni annullati; fino alla ricostruzione del primo avvio niente lavoro
    /// audio automatico (`mediaResetSkipsQ`: lo stato non è «normale»), qui `mediaServicesNormal` falso. Il Play è `rebuiltAndPlay`.
    mutating func mediaResetWithoutLost(at t: Double) {
        advance(to: t)
        switch crisis(.resetWithoutLost) {
        case .silentInSong:
            silentInSong = true
            if isRunning { crisisStop() }
        case .localStop:
            if isRunning { crisisStop() }
        case .soloStopAsConsole:
            soloStop()
        case .asToday, .nothing, .soloResumeOnSong:
            break
        }
        clearPendingResume()
        cancelReturns()
        mediaServicesNormal = false
    }

    /// La ricostruzione al Play dopo il reset (la rilettura del Follower la fa `start()`, a ogni avvio: par. 4.3).
    /// A421 · SEGUITO 4 (par. 3.2): prima la Reset (`mediaReset`). Le prove la usano sul Follower: il Play dopo e' il suo `start()`
    /// dalla sessione Link (`followerRun(.start)`), senza mappa. ⚠️ RISCRITTO A425 (P4), c'era «la mappa del runner, che arriva dopo, la
    /// abbassa il fuoco dell'ingresso.»: da A425 la consuma l'avvio in corso (il secondo `start()` del runner, o il fuoco se viene prima).
    mutating func rebuiltAndPlay(at t: Double) {
        mediaReset()
        mediaServicesNormal = true
        isRunning = false
        engineRunning = false
        start(at: t, recovery: nil)
    }

    /// A437 · PARTE 2 — C.1: il segno della tolta dentro la chiamata si abbassa (`forgetRemovalDuringInterruptionQ`).
    mutating func forgetRemovalDuringInterruption(reason: String) {
        guard removalDuringInterruption else { return }
        removalDuringInterruption = false
        removalsForgotten.append(reason)
    }

    /// A437 · PARTE 2 (seguito 2 di A437, §2 voce 2) — la levetta di Link ACCESA (`noteUserLinkSwitchQ`, il ramo nuovo): se il
    /// ruolo effettivo cambia (da Solo a Direttore o a Follower) «canzone in corso» giù e la ripresa del Solo chiusa.
    /// Nient'altro su questa strada: i ritorni, il segno della mappa, lo stato dell'uscita restano.
    mutating func userLinkSwitchedOn(to newRole: PlayerRole, at t: Double) {
        advance(to: t)
        if newRole != role {
            closeSoloResumeAtRest(reason: "link-utente-acceso")
            if useEngineSongInProgress { songInProgress = false }
        }
        role = newRole
    }

    /// `applySettings` (il cambio del ruolo scelto) e la levetta SPENTA: `handleRoleOrLinkChangeQ`. Nel rig il ruolo è già quello
    /// effettivo: «il ruolo effettivo cambia» è `newRole != role` (da Solo a Solo no).
    mutating func roleChange(to newRole: PlayerRole, at t: Double) {
        advance(to: t)
        cancelReturns()
        songMapPending = false
        closeAnchor(at: t)
        closeSoloResumeAtRest(reason: "cambio-di-ruolo")   // A437
        // A437 · PARTE 2 (seguito 2, §2 voce 2): col ruolo effettivo che cambia «canzone in corso» giù, anche col motore in moto
        // al volume 1 (col rig di prima, `useEngineSongInProgress` spento, «canzone in corso» non segue il motore: resta).
        if newRole != role && useEngineSongInProgress { songInProgress = false }
        if isRunning && state.muted {
            isRunning = false
            engineRunning = false
            queued = []
            rejoin = nil
            // A421 · SEGUITO 4 (par. 3.2): l'arresto locale di `handleRoleOrLinkChangeQ` abbassa «canzone in corso».
            if useEngineSongInProgress { songInProgress = false }
            wantedStop = true
            stopCleanup()
            publishIsPlaying()
            playbackStopped = true
        }
        apply(.roleChange)
        silentInSong = false
        followsLink = false
        // ⚠️ CORRETTO A437 · SEGUITO 3 (19/11/2026): qui c'era `forgetRemovalDuringInterruption(reason: "ruolo")`, con la coda
        // «A437 · PARTE 2 — C.1 (il cambio di ruolo e Link spento)»: tolta, come le due chiamate del motore (in `applySettings`
        // e in `noteUserLinkSwitchQ`). Il cambio di ruolo e Link spento non abbassano più il segno della tolta dentro la chiamata.
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

    /// A437 · PARTE 2 (mandato A437, par. 2.8, C-1) — quello che legge il pedale Stop (`PedalPressDecision.decide`): `engineMoving`
    /// è lo stato del player (`transportInMotion`: `.playing` o `.countIn`), qui «non a fermo». Dopo un arresto locale dentro una
    /// chiamata il player resta `.playing` e lo Stop del pedale ferma (verso la band); col player a «fermo» dà niente («fermo»).
    func pedalStopPress() -> PedalPress {
        PedalPressDecision.decide(role: role, directorSilent: role == .direttore && silentInSong, action: .stop,
                                  isPlaying: isPlaying, startRequested: false, engineMoving: !playbackStopped,
                                  screen: .noDoor, soloResumePending: role == .solo && soloResumePending)
    }

    /// Il pedale playPause fuori dal silenzio del Direttore: `isPlaying ? stop() : start()`.
    mutating func pedalPlayPause(at t: Double) {
        // A437: la regola del pedale col segno della pausa della ripresa del Solo (nella pausa ferma, non avvia).
        let inMotion = PedalPressDecision.inMotion(action: .playPause, isPlaying: isPlaying, startRequested: false,
                                                   engineMoving: false, soloResumePending: role == .solo && soloResumePending)
        if inMotion { stop(at: t) } else { start(at: t, recovery: nil) }
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

    /// Un rig col click in moto, sul percorso dato, partito col Play del suo ruolo (A421 · SEGUITO 4, par. 3.2: `runnerPlay`):
    /// Direttore e Solo in canzone, il Follower con «canzone in corso» falsa, come il motore. ⚠️ RISCRITTO A421 · SEGUITO 4: diceva
    /// «Un rig col click in moto in canzone» e partiva con `start` senza mappa, in canzone solo per il valore iniziale del rig.
    /// ⚠️ RISCRITTO A425 (P4): «il Follower con «canzone in corso» falsa» non è più vero: la mappa del runner la consuma il secondo
    /// `start()`, che trova il motore in moto, e il Follower è in canzone come il motore. Nessuna decisione del rig legge la canzone del
    /// Follower (`CrisisStopDecision`, `RenderGapDecision`, `OutputRouteDecision` la guardano solo per il Direttore).
    /// `engineLeadIn` e `engineSongInProgress`: gli interruttori del par. 3, messi prima del Play (spenti: il rig di prima).
    private func playing(_ role: PlayerRole, route: [OutputPort], bpm: Double = 121, beatsPerBar: Int = 4,
                         at t: Double = 10.0, cycleSeconds: Double = 512.0 / 48_000.0, renderOffsetBuffers: Double = 0.0,
                         fallbackRead: Bool = false, guardian: Bool = false, nodeRate: Double = 48_000.0,
                         engineLeadIn: Bool = true, engineSongInProgress: Bool = true) -> OutputRig {
        var rig = OutputRig(role: role, route: route, bpm: bpm, beatsPerBar: beatsPerBar, cycleSeconds: cycleSeconds,
                            renderOffsetBuffers: renderOffsetBuffers, fallbackRead: fallbackRead)
        rig.useGuardian = guardian
        rig.nodeRate = nodeRate
        rig.useEngineLeadIn = engineLeadIn
        rig.useEngineSongInProgress = engineSongInProgress
        rig.runnerPlay(at: t)
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
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
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
        // ⚠️ A425 (par. 2.5): le 200 correzioni erano da 0,0009 battiti, sotto la soglia di Link (0,01): il motore non le applica, e
        // con la soglia nel rig `corrections` restava 0 e l'attesa qui sotto cadeva (una differenza fra rig e motore trovata). Una
        // correzione normale del motore sta sopra la soglia: 0,015, meno di un buffer (0,0215 battiti a 121), che non zittisce.
        rig.callbacks(from: 12.0, count: 200, correction: 0.015)
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

    /// Dentro un'interruzione (la regola del referee del 21/10, seconda parte; BOX5, capitolo «L'USCITA AUDIO»): un ritorno passato alla battuta dopo e un inizio d'interruzione
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
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
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
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
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
        // A421 · SEGUITO 4 (par. 3.2): i due avvii del Follower seguono la strada vera (`runnerPlay`: prima `start()`, poi la mappa e
        // il fuoco dell'ingresso). Qui c'era `songInProgress = true`, messo a mano prima di `start(at:recovery:)`: sul Follower la
        // canzone resta falsa, come nel motore; col rig di prima (interruttore spento) il Follower di `between` la teneva vera.
        for engine in [true, false] {
            var closed = playing(.follower, route: [headphones], at: 10.0, engineSongInProgress: engine)
            closed.stop(at: 20.0)
            closed.closeShow(at: 21.0)
            XCTAssertNil(closed.state.lastOutputExternal, "la chiusura dello show azzera la memoria")
            closed.routeChange(at: 22.0, to: [speaker])
            closed.openShow(at: 30.0)
            closed.runnerPlay(at: 31.0)
            XCTAssertEqual(closed.volume, 1.0, "il primo avvio dello show dopo e' come oggi (motore:\(engine))")
            // ⚠️ A425 (P4): col rig del motore la mappa del runner, consegnata col motore in moto, è dell'avvio in corso: il secondo
            // `start()` la consuma e «canzone in corso» è vera. Qui c'era `XCTAssertFalse(closed.songInProgress, …)`, che vale ancora col
            // rig di prima.
            XCTAssertEqual(closed.songInProgress, engine,
                           engine ? "la mappa consumata dall'avvio in corso (P4)"
                                  : "motore:\(engine): la chiusura dello show l'ha abbassata, l'avvio del Follower non la alza")
            var between = playing(.solo, route: [headphones], at: 10.0, engineSongInProgress: engine)
            between.showOpen = false
            between.stop(at: 20.0)
            XCTAssertEqual(between.state.lastOutputExternal, true)
            between.roleChange(to: .follower, at: 21.0)
            XCTAssertEqual(between.state.lastOutputExternal, true, "il cambio di ruolo tiene la memoria")
            between.routeChange(at: 22.0, to: [speaker])
            between.openShow(at: 30.0)
            between.runnerPlay(at: 31.0)
            XCTAssertEqual(between.volume, 1.0, "START SHOW come Follower senza cuffie: come oggi (motore:\(engine))")
            XCTAssertFalse(between.state.missing)
            // ⚠️ A425 (P4): col rig del motore la mappa consegnata al secondo `start()` è dell'avvio in corso: «canzone in corso» vera
            // (prima: «sul Follower resta falsa, come il motore»); col rig di prima vera lo stesso, perché lo Stop e l'avvio senza mappa
            // la lasciavano com'era.
            XCTAssertTrue(between.songInProgress, engine ? "la mappa consumata dall'avvio in corso (P4)"
                                                         : "il rig di prima: lo Stop e l'avvio senza mappa la lasciavano vera")
        }
        var inside = playing(.direttore, route: [headphones], at: 10.0)
        inside.stop(at: 20.0)
        inside.routeChange(at: 21.0, to: [speaker])
        inside.roleChange(to: .follower, at: 22.0)
        XCTAssertEqual(inside.state.lastOutputExternal, true)
        inside.start(at: 25.0, recovery: nil)
        XCTAssertEqual(inside.volume, 0.0, "il cambio di ruolo dentro lo show con la memoria esterna: l'avvio e' muto")
        XCTAssertTrue(inside.state.missing)
    }

    /// Dentro un'interruzione (la regola del referee del 21/10, seconda parte; BOX5, capitolo «L'USCITA AUDIO»): la rilettura all'avvio del Follower è una lettura del percorso e uno
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
    func testTheSlowPlayerNearTargetAndTheMarkThatIsNotLateForTheCopies() throws {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.engineStartDuration = 0.140
        let bar = rig.nextBarTime(atOrAfter: 21.5)
        rig.routeChange(at: bar - 0.160 - 0.1, to: [headphones])
        rig.advance(to: 30.0)
        XCTAssertEqual(rig.rejoins, 1)
        XCTAssertEqual(rig.slowPlayerArms, 1, "il segno all'armamento")
        XCTAssertEqual(rig.slowPlayerFires, 1)
        XCTAssertEqual(rig.lateSkips, 0)
        XCTAssertEqual(try XCTUnwrap(rig.firstClickAt), bar + rig.barSeconds, accuracy: 1e-6)
        // Com'era (senza il segno): lo stesso bersaglio finale con un fuoco in ritardo e un salto consumato.
        var noMark = playing(.direttore, route: [speaker], at: 10.0)
        noMark.useSlowPlayerMark = false
        noMark.engineStartDuration = 0.140
        noMark.routeChange(at: bar - 0.160 - 0.1, to: [headphones])
        noMark.advance(to: 30.0)
        XCTAssertEqual(noMark.rejoins, 1)
        XCTAssertEqual(noMark.slowPlayerArms, 0, "senza la regola nessun segno")
        XCTAssertEqual(noMark.lateSkips, 1, "com'era: un fuoco in ritardo e un salto")
        XCTAssertEqual(noMark.lastRejoinSkipsLeft, 3)
        XCTAssertEqual(try XCTUnwrap(noMark.firstClickAt), bar + noMark.barSeconds, accuracy: 1e-6, "lo stesso bersaglio finale")
        // Il segno, ma le copie dicono una distanza più corta (la sola latenza): al fuoco non e' in ritardo, si suona al bersaglio.
        var copies = playing(.direttore, route: [speaker], at: 10.0)
        copies.engineStartDuration = 0.100
        copies.copiesDistance = 0.0233
        let bar2 = copies.nextBarTime(atOrAfter: 21.5)
        copies.routeChange(at: bar2 - 0.160 - 0.1, to: [headphones])
        copies.advance(to: 30.0)
        XCTAssertEqual(copies.rejoins, 1)
        // A421 · SEGUITO 3 (par. 8.3): il segno si e' alzato all'armamento (la riga «armato … lettoreLento:1»), anche se al fuoco le
        // copie non dicono ritardo: senza il segno il test cade qui.
        XCTAssertEqual(copies.slowPlayerArms, 1, "il segno all'armamento, letto da D")
        XCTAssertEqual(copies.slowPlayerFires, 0, "il fuoco non e' in ritardo per le copie: si suona")
        XCTAssertEqual(copies.lateSkips, 0)
        XCTAssertEqual(try XCTUnwrap(copies.firstClickAt), bar2, accuracy: 1e-6)
    }

    /// Con le uscite veloci e il lettore del 28/10 (27,7-78,9 ms) nessun cambio di bersaglio ne' di armamento rispetto a oggi.
    func testFastOutputsKeepTodaysTargetAndArming() throws {
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
                XCTAssertEqual(try XCTUnwrap(rig.firstClickAt), rig.nextBarTime(atOrAfter: 20.1 + 0.150), accuracy: 1e-6, "\(route) fisso:\(fixed)")
            }
        }
        // A421 · SEGUITO 3 (par. 8.4): il bersaglio appena oltre i 150 ms del margine (151 ms dall'avvio), col lettore del 28/10 a
        // 78,9 ms. D e' la scorta intera piu' la latenza: cinque buffer (53,3 ms) + 12,6 ms = 65,9 ms con l'altoparlante, + 2,7 ms =
        // 56,0 ms con le cuffie (i numeri del seguito 2). All'armamento, 79 ms dopo l'avvio, restano 72 ms al bersaglio e l'ora del
        // rendering (bersaglio - D) e' gia' a 6 ms (altoparlante) o 16 ms (cuffie): meno dei 30 ms minimi, quindi il segno
        // «lettore-lento» scatta dove com'era (senza il segno) c'era un fuoco in ritardo e un salto. Il bersaglio finale e' lo
        // stesso, la battuta dopo, con un salto in meno: i salti restano quattro.
        for mark in [true, false] {
            for (route, latency, other) in [([speaker], 0.0126, [headphones]), ([headphones], 0.0027, [speaker, usb])] {
                var rig = playing(.direttore, route: route, at: 10.0)
                rig.latency = latency
                rig.useSlowPlayerMark = mark
                rig.engineStartDuration = 0.079
                XCTAssertEqual(rig.margin, 0.150, accuracy: 1e-9, "\(route)")
                XCTAssertEqual(rig.firstBufferDistance, route == [speaker] ? 0.0659 : 0.0560, accuracy: 0.0001, "\(route): D del seguito 2")
                let bar = rig.nextBarTime(atOrAfter: 21.5)
                rig.routeChange(at: bar - 0.151 - 0.1, to: other)
                rig.advance(to: 30.0)
                XCTAssertEqual(rig.rejoins, 1, "\(route) segno:\(mark)")
                XCTAssertEqual(try XCTUnwrap(rig.firstClickAt), bar + rig.barSeconds, accuracy: 1e-6, "\(route) segno:\(mark): la battuta dopo, con e senza il segno")
                XCTAssertEqual(rig.slowPlayerArms, mark ? 1 : 0, "\(route) segno:\(mark): il segno all'armamento")
                XCTAssertEqual(rig.slowPlayerFires, mark ? 1 : 0, "\(route) segno:\(mark)")
                XCTAssertEqual(rig.lateSkips, mark ? 0 : 1, "\(route) segno:\(mark): col segno un salto in meno")
                XCTAssertEqual(rig.lastRejoinSkipsLeft, mark ? 4 : 3, "\(route) segno:\(mark): i salti restano quattro")
            }
        }
    }

    // MARK: - A421 · SEGUITO 2, par. 3.5: l'àncora tenuta dal rientro

    /// La seconda prova del 29/10 sull'iPad: la crisi da misuratore, il rientro, e 175 ms dopo il fuoco una seconda crisi nella
    /// scorta, prima dell'«uno». Com'era: l'àncora chiusa al fuoco, nessun battito contato uscito, «non-certo(nessuna-ancora)»,
    /// muto fino a fine canzone. Da qui: l'àncora tenuta dal rientro, la seconda crisi la trova viva e il coordinatore rientra
    /// alla battuta dopo.
    func testTheSecondCrisisInTheLeadInFindsTheHeldAnchor() throws {
        for held in [true, false] {
            var rig = playing(.direttore, route: [speaker], at: 10.0, cycleSeconds: 2 * 512.0 / 48_000.0)
            rig.useHeldAnchor = held
            rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
            XCTAssertTrue(rig.silentInSong)
            XCTAssertTrue(rig.anchor)
            rig.advance(to: 20.1)
            XCTAssertTrue(rig.isRunning, "il ritorno dopo 100 ms ha fatto ripartire il motore")
            let fireAt = try XCTUnwrap(rig.rejoin, "il rientro armato (held:\(held))").fireAt
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
            if held {
                // A421 · SEGUITO 3 (par. 8.4): un rientro dopo un altro rientro: anche il secondo fuoco tiene l'àncora, fino al suo
                // primo battito contato uscito.
                rig.advance(to: gapAt + 0.2)
                XCTAssertTrue(rig.isRunning, "il ritorno dopo la seconda crisi ha fatto ripartire il motore")
                let secondFireAt = try XCTUnwrap(rig.rejoin, "il secondo rientro armato").fireAt
                rig.advance(to: secondFireAt)
                XCTAssertEqual(rig.rejoins, 2)
                XCTAssertTrue(rig.anchorHeld, "l'àncora tenuta anche dal secondo rientro")
                XCTAssertTrue(rig.anchor)
                XCTAssertFalse(rig.silentInSong)
                let secondTarget = try XCTUnwrap(rig.firstClickAt, "il primo click del secondo rientro")
                rig.callbacks(from: secondFireAt + rig.bufferSeconds, count: 1)
                XCTAssertTrue(rig.anchorHeld, "tenuta fino al primo battito contato uscito")
                // I richiami fino a oltre il bersaglio del secondo rientro: l'àncora si chiude al primo battito contato uscito.
                rig.callbacks(from: rig.now + rig.bufferSeconds, count: 200)
                XCTAssertFalse(rig.anchorHeld)
                XCTAssertFalse(rig.anchor)
                XCTAssertGreaterThanOrEqual(try XCTUnwrap(rig.anchorClosedAt), secondTarget - 1e-9, "chiusa al primo battito contato del secondo rientro")
                rig.advance(to: gapAt + 10.0)
            } else {
                rig.advance(to: gapAt + 10.0)
            }
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
    func testAHoleInTheWindowWaitsForTheFirstCorrectionAfterTheWindow() throws {
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
            // A421 · SEGUITO 3 (par. 8.2): la chiamata della prima correzione dopo la finestra, quella che sposta di un buffer (0,03
            // battiti a 121 BPM = 14,9 ms): il ritorno si riarma da questa chiamata e il volume NON torna qui (il controllo del ritorno
            // viene dopo il blocco della fase, come nel motore).
            let firstCallAfterWindow = rig.now + rig.bufferSeconds
            rig.callbacks(from: firstCallAfterWindow, count: 1, correction: 0.03)
            XCTAssertEqual(rig.firstCorrectionRearms, 1, "\(role): la prima correzione dopo la finestra sposta e riarma")
            XCTAssertEqual(rig.volume, 0.0, "\(role): nella chiamata della prima correzione il volume non torna")
            XCTAssertEqual(rig.gapReturnRestores, 0, "\(role)")
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 59, correction: 0.03)
            XCTAssertEqual(rig.firstCorrectionRearms, 1, "\(role)")
            XCTAssertEqual(rig.gapReturnRestores, 1, "\(role)")
            let restoredAt = try XCTUnwrap(rig.gapRestoredAt, "\(role): il volume e' tornato")
            XCTAssertGreaterThan(restoredAt, windowEnd)
            XCTAssertGreaterThan(restoredAt, firstCallAfterWindow, "\(role): il volume torna dopo la chiamata della prima correzione")
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(rig.gapFirstSampleAt), try XCTUnwrap(rig.gapDeadlineAt) - 1e-9)
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
    func testTheReattachRightAfterASectionChangeWaitsForTheWindow() throws {
        // A437 · PARTE 2 (§B.7 del seguito 4 di A421): la rottura della riga del ritorno prenotato, provata nel banco. Senza la
        // difesa della notizia (`useRouteCrisis` spento) la tolta non zittisce e l'aggiunta non prenota niente: la riga con
        // `XCTUnwrap`, più sotto, cadrebbe.
        var broken = playing(.follower, route: [headphones], bpm: 180.5, at: 10.0)
        broken.useRouteCrisis = false
        broken.routeChange(at: 15.0, to: [speaker])
        broken.callbacks(from: 15.004, count: 50)
        broken.sectionChange(at: broken.now + 0.001)
        broken.routeChange(at: broken.now + 0.002, to: [headphones])
        XCTAssertNil(broken.followerReturn, "senza la difesa della notizia nessun ritorno prenotato")
        XCTAssertEqual(broken.volume, 1.0, "e nessun silenzio da cui tornare")
        var rig = playing(.follower, route: [headphones], bpm: 180.5, at: 10.0)
        rig.routeChange(at: 15.0, to: [speaker])
        rig.callbacks(from: 15.004, count: 50)
        // A421 · SEGUITO 3 (par. 8.4): il cambio di sezione 0,6 s prima di un «uno» di Link: la scadenza (notizia + 300 ms) cade prima
        // dell'«uno», e l'«uno» cade dentro la finestra (1,067 s): il ritorno va alla battuta dopo (`.nextBarInWindow`).
        let barInWindow = rig.nextBarTime(atOrAfter: rig.now + 0.8)
        let callsToBar = Int((barInWindow - 0.6 - rig.now) / rig.bufferSeconds)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: callsToBar)
        rig.sectionChange(at: rig.now + 0.001)
        rig.routeChange(at: rig.now + 0.002, to: [headphones])
        XCTAssertTrue(try XCTUnwrap(rig.followerReturn, "il ritorno del Follower prenotato alla notizia").armPending)
        // A 180,5 BPM un buffer è 0,0321 battiti: la correzione di 0,04 sposta di più di un buffer (0,03 no).
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 99, correction: 0.04)
        XCTAssertEqual(rig.volume, 0.0, "nella finestra il volume non torna")
        XCTAssertEqual(try XCTUnwrap(rig.armedUnoAt), barInWindow, accuracy: 1e-6, "l'uno dell'armo e' quello nella finestra")
        XCTAssertEqual(rig.nextBarMoves, 1, "l'uno nella finestra: la battuta dopo (.nextBarInWindow)")
        let windowEnd = rig.now
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 400, correction: 0.04)
        XCTAssertEqual(rig.firstCorrectionRearms, 1)
        XCTAssertEqual(rig.volume, 1.0)
        XCTAssertGreaterThan(try XCTUnwrap(rig.raisedAt), windowEnd)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(rig.restoredUnoAt), barInWindow + rig.barSeconds - 1e-6, "il volume torna a un uno dopo quello nella finestra")
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
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
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
    /// ⚠️ A425 (P4): il fuoco dell'ingresso non lo abbassa più senza consumarlo: lo consuma (la mappa è dell'avvio in corso). L'attesa
    /// qui (il segno giù dopo il fuoco) vale ancora.
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
/// A421 · SEGUITO 3 (par. 8.3): il rig conta «non certo» anche sulla strada «ritardo-oltre-i-salti»: senza il segno l'ultimo bersaglio
/// in ritardo e' un «non certo» e il motore si ferma.
func testTheSlowPlayerMarkOnTheLastTargetOfTheSkipsIsNotUncertain() throws {
    for mark in [true, false] {
        var rig = playing(.direttore, route: [bluetooth], at: 10.0, cycleSeconds: 512.0 / 44_100.0)
        rig.latency = 0.1116
        rig.useSlowPlayerMark = mark
        rig.routeChange(at: 20.0, to: [bluetooth, usb])
        rig.advance(to: 20.2)   // il ritorno dell'aggiunta (0,1 s) e l'avvio: il rientro armato
        XCTAssertTrue(rig.isRunning, "segno:\(mark)")
        XCTAssertNotNil(rig.rejoin, "segno:\(mark)")
        rig.armRejoin(targetAt: rig.now + 0.100, skips: DirectorRejoinDecision.maxLateSkips)
        XCTAssertEqual(try XCTUnwrap(rig.rejoin).slowPlayer, mark, "il bersaglio troppo vicino: il segno (segno:\(mark))")
        rig.advance(to: 30.0)
        if mark {
            XCTAssertEqual(rig.slowPlayerFires, 1)
            XCTAssertEqual(rig.uncertainRejoins, 0, "nessun «non certo» per il lettore")
            XCTAssertEqual(rig.rejoins, 1)
            XCTAssertTrue(rig.isRunning)
        } else {
            XCTAssertEqual(rig.slowPlayerFires, 0)
            XCTAssertEqual(rig.lateSkips, 1)
            XCTAssertEqual(rig.uncertainRejoins, 1, "com'era: «non-certo(ritardo-oltre-i-salti)»")
            XCTAssertEqual(rig.rejoins, 0)
            XCTAssertFalse(rig.isRunning)
        }
    }
}

/// A421 · SEGUITO 4 (par. 2, M1): il Direttore muto in canzone; un'interruzione comincia con la latenza dell'altoparlante del rig
/// (23,3 ms: D 76,6 ms, il margine 156,6 ms); dentro l'interruzione la latenza letta diventa quella della cassa Bluetooth (111,6 ms:
/// D 164,9 ms, il margine 244,9 ms = max(150 ms, D + 80 ms)); poi l'avvio, dentro l'interruzione: il coordinatore del rig sceglie il
/// bersaglio col margine letto in quel momento. Una battuta cade 200 ms dopo l'avvio, fra i due margini: col margine della cassa il
/// bersaglio e' la battuta dopo; col margine fisso (150 ms, `useFixedMargin`) e con quello letto all'inizio dell'interruzione sarebbe
/// quella battuta. Il rig non ha le due decisioni del motore dentro un'interruzione (al secondo e del tasto): qui c'e' l'avvio.
/// ⚠️ RISCRITTO A421 · SEGUITO 4: si chiamava `testADecisionInsideAnInterruptionTakesTheMarginReadNow` e decideva con la latenza a 0
/// (il margine di base, lo stesso del margine fisso); la riga con la cassa controllava solo la formula, senza decisione, con una
/// latenza (0,1696 s) che era D sul telefono a 44,1 kHz.
/// ⚠️ A437 · PARTE 2 (mandato A437, par. 2.11; §B.3 del seguito 4 di A421): si chiamava
/// `testARejoinStartInsideAnInterruptionTakesTheMarginWithTheBluetoothLatencyReadAtTheStart`. Il nome nuovo dice che il test prova
/// la decisione del rig all'avvio del rientro (non le due del motore dentro un'interruzione, al secondo e del tasto, che il rig
/// non ha), e «AtTheRejoinStart» non si può più leggere «all'inizio dell'interruzione». Il corpo non cambia.
func testTheStartDecisionOfARejoinInsideAnInterruptionTakesTheMarginWithTheBluetoothLatencyReadAtTheRejoinStart() throws {
    for fixed in [false, true] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useFixedMargin = fixed
        rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        XCTAssertTrue(rig.silentInSong, "fisso:\(fixed)")
        XCTAssertNotNil(rig.directorReturn, "fisso:\(fixed): il ritorno dopo 100 ms")
        // L'interruzione comincia prima del ritorno, con la latenza dell'altoparlante: il ritorno si annulla.
        rig.interruptionBegan(at: 20.05)
        XCTAssertNil(rig.directorReturn, "fisso:\(fixed)")
        XCTAssertTrue(rig.systemInterruption, "fisso:\(fixed)")
        XCTAssertEqual(rig.latency, 0.0233, accuracy: 1e-12)
        let marginAtBegin = rig.margin
        XCTAssertEqual(rig.firstBufferDistance, 5 * rig.bufferSeconds + 0.0233, accuracy: 1e-9, "D con l'altoparlante: 76,6 ms")
        XCTAssertEqual(marginAtBegin, rig.firstBufferDistance + 0.080, accuracy: 1e-9, "il margine con l'altoparlante: 156,6 ms")
        // Dentro l'interruzione la latenza letta diventa quella della cassa: lo stesso percorso, nessun cambio di percorso.
        rig.latency = 0.1116
        XCTAssertEqual(rig.firstBufferDistance, 5 * rig.bufferSeconds + 0.1116, accuracy: 1e-9, "D con la cassa: 164,9 ms")
        XCTAssertEqual(rig.margin, rig.firstBufferDistance + 0.080, accuracy: 1e-9, "il margine con la cassa: 244,9 ms")
        // L'avvio 200 ms prima di una battuta: la battuta cade fra i due margini, estremi esclusi.
        let bar = rig.nextBarTime(atOrAfter: 21.0)
        let startAt = bar - 0.200
        XCTAssertGreaterThan(bar, startAt + marginAtBegin)
        XCTAssertLessThan(bar, startAt + rig.margin)
        XCTAssertTrue(rig.systemInterruption, "fisso:\(fixed): la decisione e' dentro l'interruzione")
        rig.start(at: startAt, recovery: nil)
        let target = try XCTUnwrap(rig.rejoin, "fisso:\(fixed): il bersaglio armato").targetAt
        if fixed {
            XCTAssertEqual(target, bar, accuracy: 1e-6, "col margine fisso di 150 ms la battuta fra i due margini")
        } else {
            XCTAssertEqual(target, bar + rig.barSeconds, accuracy: 1e-6, "col margine letto adesso, la cassa: la battuta dopo")
            XCTAssertEqual(target, rig.nextBarTime(atOrAfter: startAt + rig.margin), accuracy: 1e-6)
        }
        // Col margine letto all'inizio dell'interruzione il bersaglio sarebbe la battuta fra i due margini (il conto).
        XCTAssertEqual(rig.nextBarTime(atOrAfter: startAt + marginAtBegin), bar, accuracy: 1e-6)
    }
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
func testAMeterChangeRenamesTheBeatWithoutRearmingTheReturn() throws {
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
        // A421 · SEGUITO 3 (par. 8.2): il volume torna in QUESTA chiamata (col riarmo la scadenza slitterebbe di tre buffer e 40 ms,
        // e il volume resterebbe a 0 qui: il controllo del ritorno viene dopo il blocco della fase, come nel motore).
        XCTAssertEqual(rig.volume, 1.0, "\(from)/4 → \(to)/4")
        XCTAssertEqual(rig.gapReturnRestores, 1, "\(from)/4 → \(to)/4")
        XCTAssertEqual(try XCTUnwrap(rig.gapRestoredAt), t, accuracy: 1e-9, "\(from)/4 → \(to)/4: nella chiamata della rinomina")
        XCTAssertEqual(rig.gapReturnArms, 1, "\(from)/4 → \(to)/4: nessun riarmo")
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

// MARK: - A421 · SEGUITO 3, par. 2.4: la memoria della crisi del Solo a motore fermo

/// (a) Il Solo fermo con lo Stop della console («Resume from»), un cambio di percorso che cambia il modo senza cambiare la frequenza
/// (la scheda USB multicanale), poi un inizio d'interruzione: da qui la causa ricordata e lo Stop voluto restano (la riga «invariati»,
/// `fermoPerCrisi:0`), m4 dice «niente Stop, era gia' fermo» e lo schermo resta su «Resume from»; com'era (regola spenta) la causa
/// diventava «modo», lo Stop voluto falso (`fermoPerCrisi:1`), e m4 fermava il Solo una seconda volta. Nessuna ripartenza fino al
/// Play. E lo stesso cambio di modo dentro un'interruzione: rimandato, niente tocca la memoria (la regola del referee del 21/10; BOX5, capitolo «L'USCITA AUDIO»).
func testTheSoloOnResumeFromKeepsItsMemoryThroughAModeChangeAndACall() {
    for rule in [true, false] {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.useCrisisMemoryRule = rule
        rig.stop(at: 12.0)
        XCTAssertTrue(rig.wantedStop, "regola:\(rule)")
        XCTAssertNil(rig.crisisCause, "regola:\(rule)")
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
        let stops = rig.soloStops
        rig.routeChange(at: 13.0, to: [usb], modeChanges: true)
        XCTAssertFalse(rig.isRunning, "regola:\(rule): il ramo del modo a motore fermo non riparte")
        XCTAssertEqual(rig.starts, 1, "regola:\(rule)")
        if rule {
            XCTAssertNil(rig.crisisCause, "la causa ricordata invariata")
            XCTAssertTrue(rig.wantedStop, "lo Stop voluto invariato")
            XCTAssertEqual(rig.memoryKeptLines, 1, "la riga «invariati»")
            XCTAssertFalse(rig.stoppedByCrisis, "fermoPerCrisi:0")
        } else {
            XCTAssertEqual(rig.crisisCause, .mode, "com'era: la causa riscritta")
            XCTAssertFalse(rig.wantedStop, "com'era: lo Stop voluto perso")
            XCTAssertEqual(rig.memoryKeptLines, 0)
            XCTAssertTrue(rig.stoppedByCrisis, "com'era: fermoPerCrisi:1")
        }
        rig.interruptionBegan(at: 14.0)
        XCTAssertEqual(rig.chainsClosedAtBegin, 1, "regola:\(rule)")
        XCTAssertEqual(rig.crisisCause, .interruption, "regola:\(rule): m4 ricorda «interruzione»")
        XCTAssertEqual(rig.soloStops, stops + (rule ? 0 : 1), rule ? "niente secondo Stop: lo schermo resta su Resume from" : "com'era: il secondo Stop")
        rig.interruptionEnded(at: 15.0)
        rig.advance(to: 20.0)
        XCTAssertEqual(rig.starts, 1, "regola:\(rule): nessuna ripartenza fino al Play")
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
        rig.start(at: 21.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "regola:\(rule): riparte col Play")
    }
    // Dentro un'interruzione: il cambio di percorso e' rimandato e la memoria non si tocca.
    var inside = playing(.solo, route: [speaker], at: 10.0)
    inside.stop(at: 12.0)
    inside.interruptionBegan(at: 13.0)
    XCTAssertEqual(inside.soloStops, 0)
    XCTAssertEqual(inside.crisisCause, .interruption)
    XCTAssertTrue(inside.wantedStop)
    inside.routeChange(at: 13.5, to: [usb], modeChanges: true)
    XCTAssertEqual(inside.crisisCause, .interruption, "rimandato: la memoria non si tocca")
    XCTAssertTrue(inside.wantedStop)
    XCTAssertEqual(inside.memoryKeptLines, 0, "nessuna crisi dentro l'interruzione")
    inside.interruptionEnded(at: 14.0)
    inside.advance(to: 20.0)
    XCTAssertEqual(inside.starts, 1)
    XCTAssertEqual(inside.soloStops, 0)
}

/// (b) Il Solo mai partito (nessuna causa, nessuno Stop voluto), un cambio di modo, un inizio d'interruzione: da qui la memoria resta
/// e m4 dice «mai suonato: niente Stop, niente riga di Stop»; com'era la causa diventava «modo» e il Solo si fermava come allo Stop
/// della console senza essere mai partito. Lo schermo resta «fermo».
func testTheSoloNeverStartedIsNotStoppedByAModeChangeAndACall() {
    for rule in [true, false] {
        var rig = OutputRig(role: .solo, route: [speaker])
        rig.useCrisisMemoryRule = rule
        rig.routeChange(at: 1.0, to: [usb], modeChanges: true)
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
        XCTAssertEqual(rig.starts, 0, "regola:\(rule)")
        if rule {
            XCTAssertNil(rig.crisisCause, "la causa ricordata invariata (nessuna)")
            XCTAssertFalse(rig.wantedStop)
            XCTAssertEqual(rig.memoryKeptLines, 1)
            XCTAssertFalse(rig.stoppedByCrisis, "fermoPerCrisi:0")
        } else {
            XCTAssertEqual(rig.crisisCause, .mode, "com'era")
            XCTAssertTrue(rig.stoppedByCrisis, "com'era: fermoPerCrisi:1")
        }
        rig.interruptionBegan(at: 2.0)
        XCTAssertEqual(rig.chainsClosedAtBegin, 1, "regola:\(rule)")
        XCTAssertEqual(rig.crisisCause, .interruption, "regola:\(rule)")
        XCTAssertEqual(rig.soloStops, rule ? 0 : 1, rule ? "mai suonato: niente Stop" : "com'era: lo Stop falso")
        XCTAssertEqual(rig.playbackStopped, !rule, "regola:\(rule): lo schermo resta «fermo» senza una riga di Stop")
        rig.interruptionEnded(at: 3.0)
        rig.advance(to: 8.0)
        XCTAssertEqual(rig.starts, 0, "regola:\(rule): niente riparte")
    }
    // Dentro un'interruzione: rimandato.
    var inside = OutputRig(role: .solo, route: [speaker])
    inside.interruptionBegan(at: 1.0)
    inside.routeChange(at: 1.5, to: [usb], modeChanges: true)
    XCTAssertEqual(inside.crisisCause, .interruption)
    XCTAssertEqual(inside.soloStops, 0)
    XCTAssertEqual(inside.memoryKeptLines, 0)
    inside.interruptionEnded(at: 2.0)
    inside.advance(to: 8.0)
    XCTAssertEqual(inside.starts, 0)
}

/// (c) Il Solo con una catena di ripartenza in volo (la crisi «configurazione» col motore in moto per l'app, la `setActive` fallita,
/// il tentativo fra 0,5 s), fermato dall'utente con lo Stop della console (lo Stop voluto alzato, la catena non chiusa fuori da
/// un'interruzione), poi un cambio di modo a motore fermo prima del tentativo dopo: da qui la memoria resta («configurazione», Stop
/// voluto) e il tentativo si ferma all'ingresso della regola («niente»); com'era lo Stop voluto tornava falso, la causa «modo», e il
/// tentativo passava («avvio-come-oggi»): il Solo fermato dall'utente ripartiva da solo. Con un inizio d'interruzione dopo lo Stop,
/// prima del cambio di modo, la catena si chiude (m4) e niente riparte, con e senza la regola.
func testTheSoloStoppedDuringTheRetriesDoesNotRestartAfterAModeChange() {
    for rule in [true, false] {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
        rig.useCrisisMemoryRule = rule
        rig.setActiveFailures = 1
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        XCTAssertEqual(rig.crisisCause, .configuration, "regola:\(rule): la crisi col motore in moto riscrive come oggi")
        XCTAssertFalse(rig.wantedStop, "regola:\(rule)")
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
        XCTAssertEqual(rig.setActiveAttempts, 1, "regola:\(rule)")
        XCTAssertNotNil(rig.retry, "regola:\(rule): il tentativo a 11,6 s")
        rig.stop(at: 11.3)
        XCTAssertTrue(rig.wantedStop, "regola:\(rule): lo Stop della console")
        XCTAssertNotNil(rig.retry, "regola:\(rule): fuori da un'interruzione lo Stop non chiude la catena")
        let token = rig.resumeToken
        rig.routeChange(at: 11.4, to: [usb], modeChanges: true)
        XCTAssertEqual(rig.resumeToken, token, "regola:\(rule): il ramo del modo non chiude la catena")
        if rule {
            XCTAssertEqual(rig.crisisCause, .configuration, "la causa ricordata invariata")
            XCTAssertTrue(rig.wantedStop, "lo Stop voluto invariato")
            XCTAssertEqual(rig.memoryKeptLines, 1)
            XCTAssertFalse(rig.stoppedByCrisis, "fermoPerCrisi:0")
        } else {
            XCTAssertEqual(rig.crisisCause, .mode, "com'era")
            XCTAssertFalse(rig.wantedStop, "com'era: lo Stop voluto perso")
            XCTAssertTrue(rig.stoppedByCrisis, "com'era: fermoPerCrisi:1")
        }
        rig.advance(to: 12.5)
        if rule {
            XCTAssertEqual(rig.setActiveAttempts, 1, "il tentativo a 11,6 s si ferma all'ingresso della regola")
            XCTAssertEqual(rig.starts, 1, "il Solo fermato dall'utente non riparte")
            XCTAssertFalse(rig.isRunning)
        } else {
            XCTAssertEqual(rig.setActiveAttempts, 2, "com'era: il tentativo passava")
            XCTAssertEqual(rig.starts, 2, "com'era: il Solo ripartiva da solo")
            XCTAssertTrue(rig.isRunning)
        }
    }
    for rule in [true, false] {
        // Dentro un'interruzione cominciata dopo lo Stop: m4 chiude la catena; il cambio di modo e' rimandato; niente riparte.
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
        rig.useCrisisMemoryRule = rule
        rig.setActiveFailures = 1
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        rig.stop(at: 11.3)
        let token = rig.resumeToken
        rig.interruptionBegan(at: 11.35)
        XCTAssertEqual(rig.resumeToken, token + 1, "regola:\(rule): m4 chiude la catena")
        XCTAssertEqual(rig.soloStops, 0, "regola:\(rule): gia' fermo per uno Stop: niente Stop")
        rig.routeChange(at: 11.4, to: [usb], modeChanges: true)
        XCTAssertEqual(rig.crisisCause, .interruption, "regola:\(rule): rimandato")
        XCTAssertTrue(rig.wantedStop, "regola:\(rule)")
        rig.interruptionEnded(at: 11.5)
        rig.advance(to: 12.5)
        XCTAssertEqual(rig.setActiveAttempts, 1, "regola:\(rule): il tentativo e' di una catena morta")
        XCTAssertEqual(rig.starts, 1, "regola:\(rule)")
    }
}

/// La catena viva senza Stop: la crisi «configurazione» col motore in moto, un cambio di modo a motore fermo fra due tentativi:
/// riparte come oggi; la causa ricordata resta «configurazione» (com'era diventava «modo»: stesso esito, `RecoveryDecision`), più la
/// riga «invariati»; `fermoPerCrisi` resta 1 come oggi.
func testTheLiveChainRestartsAfterAModeChangeAtEngineStoppedAndKeepsTheCause() {
    for rule in [true, false] {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
        rig.useCrisisMemoryRule = rule
        rig.setActiveFailures = 1
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        XCTAssertNotNil(rig.retry, "regola:\(rule)")
        rig.routeChange(at: 11.4, to: [usb], modeChanges: true)
        XCTAssertEqual(rig.crisisCause, rule ? .configuration : .mode, "regola:\(rule)")
        XCTAssertFalse(rig.wantedStop, "regola:\(rule)")
        XCTAssertEqual(rig.memoryKeptLines, rule ? 1 : 0, "regola:\(rule)")
        XCTAssertTrue(rig.stoppedByCrisis, "regola:\(rule): fermoPerCrisi:1 come oggi")
        rig.advance(to: 12.5)
        XCTAssertEqual(rig.starts, 2, "regola:\(rule): riparte come oggi")
        XCTAssertTrue(rig.isRunning, "regola:\(rule)")
        XCTAssertNil(rig.crisisCause, "regola:\(rule): l'avvio azzera la causa")
    }
    // Dentro un'interruzione cominciata durante la catena (la sequenza di m4 del seguito 1, piu' il cambio di modo): m4 chiude la
    // catena e ferma il Solo; il cambio di modo e' rimandato e non tocca la memoria; niente riparte, con e senza la regola.
    for rule in [true, false] {
        var rig = playing(.solo, route: [speaker], at: 10.0)
        rig.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
        rig.useCrisisMemoryRule = rule
        rig.setActiveFailures = 1
        rig.systemStopsEngine(at: 11.0)
        rig.configurationNotification(at: 11.1)
        rig.interruptionBegan(at: 11.3)
        XCTAssertEqual(rig.chainsClosedAtBegin, 1, "regola:\(rule)")
        XCTAssertEqual(rig.soloStops, 1, "regola:\(rule): la ripartenza era in corso: fermo come allo Stop della console")
        XCTAssertEqual(rig.crisisCause, .interruption, "regola:\(rule)")
        rig.routeChange(at: 11.4, to: [usb], modeChanges: true)
        XCTAssertEqual(rig.crisisCause, .interruption, "regola:\(rule): rimandato, la memoria non si tocca")
        XCTAssertEqual(rig.memoryKeptLines, 0, "regola:\(rule)")
        rig.interruptionEnded(at: 11.5)
        rig.advance(to: 12.5)
        XCTAssertEqual(rig.starts, 1, "regola:\(rule): niente riparte")
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
    }
}

/// Il Solo in moto con un cambio di modo (riscrive e riparte come oggi), e una causa che ferma il Solo a motore fermo (la Lost, la
/// tolta): «niente», la memoria non si tocca come oggi, nessuna riga «invariati».
func testTheSoloInMotionWithAModeChangeAndAStoppingCauseAtEngineStoppedAreAsToday() {
    var inMotion = playing(.solo, route: [usb], at: 10.0)
    inMotion.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
    inMotion.routeChange(at: 12.0, to: [usb2], modeChanges: true)
    XCTAssertEqual(inMotion.starts, 2, "il ramo del modo col motore in moto riparte come oggi")
    XCTAssertTrue(inMotion.isRunning)
    XCTAssertEqual(inMotion.memoryKeptLines, 0, "col motore in moto la memoria si riscrive, nessuna riga")
    var lost = playing(.solo, route: [speaker], at: 10.0)
    lost.stop(at: 12.0)
    lost.servicesLost(at: 13.0)
    XCTAssertNil(lost.crisisCause, "«niente»: la memoria come oggi")
    XCTAssertTrue(lost.wantedStop)
    XCTAssertEqual(lost.memoryKeptLines, 0)
    XCTAssertEqual(lost.soloStops, 0)
    var removed = playing(.solo, route: [usb], at: 10.0)
    removed.stop(at: 12.0)
    removed.routeChange(at: 13.0, to: [speaker])
    XCTAssertNil(removed.crisisCause, "la tolta a motore fermo: «niente», la memoria come oggi")
    XCTAssertTrue(removed.wantedStop)
    XCTAssertEqual(removed.memoryKeptLines, 0)
    XCTAssertEqual(removed.soloStops, 0)
    XCTAssertEqual(removed.starts, 1)
    // Dentro un'interruzione: il Solo in moto si ferma all'inizio come allo Stop della console (la regola delle crisi, come
    // oggi); il cambio di modo che arriva durante l'interruzione e' rimandato e non tocca la memoria; alla fine niente riparte.
    var inside = playing(.solo, route: [usb], at: 10.0)
    inside.interruptionBegan(at: 12.0)
    XCTAssertEqual(inside.soloStops, 1, "il Solo in moto si ferma all'inizio")
    XCTAssertEqual(inside.crisisCause, .interruption)
    inside.routeChange(at: 12.5, to: [usb2], modeChanges: true)
    XCTAssertEqual(inside.crisisCause, .interruption, "rimandato: la memoria non si tocca")
    XCTAssertFalse(inside.wantedStop)
    XCTAssertEqual(inside.memoryKeptLines, 0)
    inside.interruptionEnded(at: 13.0)
    inside.advance(to: 20.0)
    XCTAssertEqual(inside.starts, 1, "niente riparte: la causa «interruzione» tiene il Solo fermo fino al Play")
    XCTAssertFalse(inside.isRunning)
}

// MARK: - A421 · SEGUITO 3, par. 4: il segno della prima correzione dopo la finestra, solo dove una correzione c'e'

/// Il Direttore che fa l'assert e il Solo abbassano il segno alla prima chiamata dopo la finestra, con la riga, una volta per
/// finestra; com'era (regola spenta) il segno restava alto. Nessun riarmo.
func testTheFirstCallAfterTheWindowWithoutACorrectionLowersTheMarkOnTheAssertAndTheSolo() {
    for role in [PlayerRole.direttore, .solo] {
        for lowering in [true, false] {
            var rig = playing(role, route: [speaker], at: 10.0)
            rig.useFirstCorrectionMarkLowering = lowering
            XCTAssertFalse(rig.followsLink, "\(role): il Direttore fa l'assert")
            rig.sectionChange(at: rig.now + 0.001)
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 100)
            XCTAssertEqual(rig.syncSkip, 0, "\(role)")
            XCTAssertTrue(rig.windowOpen, "\(role): la finestra si chiude alla prima chiamata col contatore a zero")
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1)
            XCTAssertFalse(rig.windowOpen, "\(role)")
            XCTAssertEqual(rig.firstCorrectionLoweredWithoutCorrection, lowering ? 1 : 0, "\(role) regola:\(lowering): la riga «segno abbassato»")
            XCTAssertEqual(rig.firstCorrectionPending, !lowering, "\(role) regola:\(lowering)")
            rig.callbacks(from: rig.now + rig.bufferSeconds, count: 50)
            XCTAssertEqual(rig.firstCorrectionLoweredWithoutCorrection, lowering ? 1 : 0, "\(role): una riga per finestra")
            XCTAssertEqual(rig.firstCorrectionRearms, 0, "\(role): nessun riarmo")
            XCTAssertEqual(rig.volume, 1.0, "\(role)")
        }
    }
}

/// Sul Direttore che fa l'assert: una finestra, poi un buco sotto la soglia molto dopo (3 s), senza un cambio di sezione o di
/// tempo in mezzo: da qui nessun riarmo «prima correzione dopo la finestra» e una sola riga «armato» del ritorno dopo il buco;
/// com'era la correzione della chiamata del buco consumava il segno vecchio e riarmava, con le due righe che ingannano. Il volume
/// torna per la regola del buco in tutti e due i casi.
func testAHoleLongAfterTheWindowOnTheAssertingDirectorDoesNotRearmForTheFirstCorrection() {
    for lowering in [true, false] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useFirstCorrectionMarkLowering = lowering
        rig.sectionChange(at: rig.now + 0.001)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 101)
        XCTAssertFalse(rig.windowOpen, "regola:\(lowering)")
        XCTAssertEqual(rig.firstCorrectionPending, !lowering, "regola:\(lowering)")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 280)
        XCTAssertGreaterThan(rig.asserts, 300, "regola:\(lowering): il Direttore fa l'assert")
        let projection = rig.latency + rig.cycleSeconds
        let holeAt = rig.now + rig.bufferSeconds + 0.060
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060, correction: (0.060 + projection) * 121.0 / 60.0)
        XCTAssertTrue(rig.isRunning, "regola:\(lowering): sotto la soglia")
        XCTAssertTrue(rig.followsLink, "regola:\(lowering): segue Link")
        XCTAssertEqual(rig.corrections, 1, "regola:\(lowering): la prima correzione dopo il buco")
        if lowering {
            XCTAssertEqual(rig.firstCorrectionRearms, 0, "nessun riarmo di F1: il segno era gia' basso")
            XCTAssertEqual(rig.gapReturnArms, 1, "una sola riga «armato», nessun «riarmato … prima correzione dopo la finestra»")
        } else {
            XCTAssertEqual(rig.firstCorrectionRearms, 1, "com'era: il segno vecchio consumato dalla correzione del buco")
            XCTAssertEqual(rig.gapReturnArms, 2, "com'era: la riga «riarmato … prima correzione dopo la finestra», con F1 che non c'entra")
        }
        XCTAssertFalse(rig.firstCorrectionPending, "regola:\(lowering)")
        rig.callbacks(from: holeAt + rig.bufferSeconds, count: 30, correction: 0.0)
        XCTAssertEqual(rig.gapReturnRestores, 1, "regola:\(lowering): il volume torna per la regola del buco")
        XCTAssertEqual(rig.volume, 1.0, "regola:\(lowering)")
    }
}

/// Un buco sotto la soglia proprio nella prima chiamata dopo la finestra, sul Direttore che fa l'assert: la chiamata passa a seguire
/// Link prima del blocco della fase, la sua correzione e' davvero la prima dopo la finestra e F1 vale come oggi (il riarmo), con e
/// senza la regola nuova.
func testAHoleInTheFirstCallAfterTheWindowStillCountsAsF1OnTheAssertingDirector() {
    for lowering in [true, false] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useFirstCorrectionMarkLowering = lowering
        rig.sectionChange(at: rig.now + 0.001)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 100)
        XCTAssertTrue(rig.windowOpen, "regola:\(lowering)")
        let projection = rig.latency + rig.cycleSeconds
        let holeAt = rig.now + rig.bufferSeconds + 0.060
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060, correction: (0.060 + projection) * 121.0 / 60.0)
        XCTAssertFalse(rig.windowOpen, "regola:\(lowering): la finestra si e' chiusa in questa chiamata")
        XCTAssertTrue(rig.isRunning, "regola:\(lowering)")
        XCTAssertTrue(rig.followsLink, "regola:\(lowering)")
        XCTAssertEqual(rig.firstCorrectionLoweredWithoutCorrection, 0, "regola:\(lowering): il ramo dell'assert non si e' percorso")
        XCTAssertEqual(rig.firstCorrectionRearms, 1, "regola:\(lowering): F1 come oggi")
        XCTAssertEqual(rig.gapReturnArms, 2, "regola:\(lowering): armato al buco e riarmato dalla prima correzione")
        // A421 · SEGUITO 4 (par. 5, B2): qui c'era «il volume non torna nella chiamata della prima correzione» (il volume a 0), vera per
        // costruzione: il ritorno dopo il buco e' armato in questa stessa chiamata, con la scadenza nel futuro, e il volume non sarebbe
        // tornato nemmeno coi controlli dei ritorni prima del blocco della fase. L'ordine lo prova
        // `testAHoleInTheWindowWaitsForTheFirstCorrectionAfterTheWindow`; il caso senza riarmo `testAMeterChangeRenamesTheBeatWithoutRearmingTheReturn`.
        rig.callbacks(from: holeAt + rig.bufferSeconds, count: 30, correction: 0.0)
        XCTAssertEqual(rig.gapReturnRestores, 1, "regola:\(lowering)")
    }
}

/// A421 · SEGUITO 4 — il Direttore in canzone a 121 BPM, la crisi di un buco di 300 ms a 20 s, il ritorno dopo 100 ms e il rientro: il
/// rig subito dopo il fuoco (i tre buffer del fuoco programmati, senza correzione).
private func rejoined(engineLeadIn: Bool = true) throws -> OutputRig {
    var rig = playing(.direttore, route: [speaker], at: 10.0, engineLeadIn: engineLeadIn)
    rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
    rig.advance(to: 20.1)
    let fireAt = try XCTUnwrap(rig.rejoin, "il rientro armato").fireAt
    rig.advance(to: fireAt)
    XCTAssertEqual(rig.rejoins, 1, "il rientro")
    XCTAssertEqual(rig.bufferCount, 3, "i tre buffer del fuoco")
    return rig
}

/// La scorta del rientro come il motore (A421 · SEGUITO 4, par. 3.1), coi due stati del segno della prima correzione dopo la finestra.
/// A zero correzioni la chiamata della scorta fa come la chiamata di Link: senza correzione il segno si consuma; con una correzione la
/// correzione si applica, si conta nella scorta e consuma il segno (qui col riarmo: sposta di piu' di un buffer). Dopo la prima
/// correzione nessuna correzione e il segno resta fino alla fine della scorta, compresa la chiamata dell'«uno»; la prima correzione
/// dopo la scorta lo consuma. Il segno nella scorta si mette a mano: nel motore una finestra non si apre e non si chiude dentro una
/// scorta (referto del seguito 4, inventario del par. 3.1), quindi qui si prova la regola del ramo. Col rig di prima (interruttore
/// spento) ogni chiamata della scorta senza correzione teneva il segno e ogni correzione si applicava. E, come prima: l'orologio
/// proprio appena ancorato tiene il segno; la chiamata di Link senza correzione lo consuma.
/// ⚠️ RISCRITTO A421 · SEGUITO 4: si chiamava `testTheLeadInAndTheOwnClockFirstPinKeepTheMarkAfterTheWindow` e costruiva una scorta a
/// zero correzioni coi buffer messi a mano (`leadInBuffersLeft = 2`), controllando che tenesse il segno: a zero correzioni il motore lo
/// consuma.
func testTheLeadInAfterItsFirstCorrectionAndTheOwnClockFirstPinKeepTheMarkAfterTheWindow() throws {
    for engine in [true, false] {
        // A zero correzioni, la prima chiamata dopo i tre buffer del fuoco, senza correzione.
        var plain = try rejoined(engineLeadIn: engine)
        XCTAssertEqual(plain.leadInCallsWithTheMarkUp, 0, "motore:\(engine): il rientro vero non arriva alla scorta col segno alto (A437, §B.4)")
        plain.firstCorrectionPending = true
        plain.callbacks(from: plain.now + plain.bufferSeconds, count: 1)
        XCTAssertEqual(plain.leadInCallsWithTheMarkUp, 1, "motore:\(engine): la sonda vede il segno messo a mano (A437, §B.4)")
        XCTAssertTrue(plain.inLeadIn, "motore:\(engine)")
        XCTAssertEqual(plain.firstCorrectionPending, !engine, engine ? "a zero correzioni senza correzione il segno si consuma, come Link"
                                                                     : "il rig di prima: la scorta senza correzione teneva il segno")
        XCTAssertEqual(plain.corrections, 0, "motore:\(engine)")
        XCTAssertEqual(plain.firstCorrectionRearms, 0, "motore:\(engine)")
        // A zero correzioni, una correzione all'indietro di 0,03 battiti (14,9 ms a 121 BPM: piu' di un buffer).
        var corrected = try rejoined(engineLeadIn: engine)
        corrected.firstCorrectionPending = true
        let before = corrected.position
        corrected.callbacks(from: corrected.now + corrected.bufferSeconds, count: 1, correction: -0.03)
        XCTAssertFalse(corrected.firstCorrectionPending, "motore:\(engine): la prima correzione consuma il segno")
        XCTAssertEqual(corrected.firstCorrectionRearms, 1, "motore:\(engine): sposta di piu' di un buffer, il riarmo")
        XCTAssertEqual(corrected.position, before - 0.03 + corrected.bufferBeats, accuracy: 1e-9, "motore:\(engine): applicata")
        XCTAssertTrue(corrected.inLeadIn, "motore:\(engine)")
        if engine {
            XCTAssertEqual(try XCTUnwrap(corrected.rejoinLeadIn).corrections, 1, "contata nella scorta")
        }
        // Dopo la prima correzione (0,02 battiti all'indietro): il segno resta fino alla fine della scorta.
        // ⚠️ A425 (par. 2.5): era −0,005, sotto la soglia di Link (0,01, LinkEngine.mm:16): il motore non l'avrebbe applicata né
        // contata nella scorta; −0,02 è la prima correzione della scorta, all'indietro, col significato di prima.
        var held = try rejoined(engineLeadIn: engine)
        held.callbacks(from: held.now + held.bufferSeconds, count: 1, correction: -0.02)
        XCTAssertEqual(held.corrections, 1, "motore:\(engine): la prima correzione")
        held.firstCorrectionPending = true
        let beforeSecond = held.position
        held.callbacks(from: held.now + held.bufferSeconds, count: 1, correction: 0.03)
        if engine {
            XCTAssertTrue(held.firstCorrectionPending, "dopo la prima correzione il segno resta")
            XCTAssertEqual(held.corrections, 1, "la correzione passata non si applica")
            XCTAssertEqual(held.position, beforeSecond + held.bufferBeats, accuracy: 1e-9)
            XCTAssertTrue(held.inLeadIn)
            // La chiamata dell'«uno»: ancora nella scorta, il segno resta; la scorta finisce qui.
            held.callbacks(from: held.now + held.bufferSeconds, count: 1, correction: 0.03)
            XCTAssertFalse(held.inLeadIn, "la scorta finisce nella chiamata dell'uno")
            XCTAssertEqual(held.leadInUnoBuffer, 5)
            XCTAssertTrue(held.firstCorrectionPending, "fino alla fine della scorta")
            XCTAssertEqual(held.corrections, 1)
            // La prima correzione dopo la scorta lo consuma (0,03 battiti: il riarmo).
            held.callbacks(from: held.now + held.bufferSeconds, count: 1, correction: 0.03)
            XCTAssertFalse(held.firstCorrectionPending, "la prima correzione dopo la scorta lo consuma")
            XCTAssertEqual(held.corrections, 2)
            XCTAssertEqual(held.firstCorrectionRearms, 1)
        } else {
            XCTAssertFalse(held.firstCorrectionPending, "il rig di prima: la correzione si applicava e consumava il segno")
            XCTAssertEqual(held.corrections, 2)
            XCTAssertEqual(held.position, beforeSecond + 0.03 + held.bufferBeats, accuracy: 1e-9)
            XCTAssertEqual(held.firstCorrectionRearms, 1)
        }
    }
    var own = playing(.follower, route: [headphones], at: 10.0)
    own.goOwnClock(at: own.now + 0.001)
    own.sectionChange(at: own.now + 0.001)
    own.callbacks(from: own.now + own.bufferSeconds, count: 100)
    own.ownSectionTempoChange(to: 130.0, at: own.now + 0.001)
    own.callbacks(from: own.now + own.bufferSeconds, count: 1)
    XCTAssertFalse(own.windowOpen)
    XCTAssertTrue(own.firstCorrectionPending, "l'orologio proprio appena ancorato tiene il segno")
    XCTAssertEqual(own.firstCorrectionLoweredWithoutCorrection, 0)
    own.callbacks(from: own.now + own.bufferSeconds, count: 1)
    XCTAssertFalse(own.firstCorrectionPending, "la chiamata dopo, senza correzione, lo consuma come oggi")
    var link = playing(.follower, route: [headphones], at: 10.0)
    link.sectionChange(at: link.now + 0.001)
    link.callbacks(from: link.now + link.bufferSeconds, count: 101)
    XCTAssertFalse(link.firstCorrectionPending, "la chiamata di Link senza correzione consuma il segno come oggi")
    XCTAssertEqual(link.firstCorrectionLoweredWithoutCorrection, 0, "senza la riga nuova")
}

// MARK: - A421 · SEGUITO 3, par. 5: il silenzio in vigore e chi l'ha scritto

/// La «misura tolta» dice chi ha scritto il silenzio in vigore: il guardiano («buco-in-corso»), la chiamata del buco («buco») o la
/// notizia stessa («percorso-tolta», col silenzio scritto ora). Com'era (regola spenta) diceva sempre «percorso-tolta».
func testWhoWroteTheSilenceInForceAtTheRemoval() {
    for rule in [true, false] {
        var guardianRig = playing(.direttore, route: [headphones], at: 10.0, guardian: true)
        guardianRig.useSilenceWriterMemory = rule
        guardianRig.advance(to: guardianRig.now + 4 * guardianRig.bufferSeconds + 0.001)
        XCTAssertEqual(guardianRig.guardianFires, 1, "regola:\(rule)")
        XCTAssertEqual(guardianRig.lastSilenceWrite?.reason, "buco-in-corso", "regola:\(rule)")
        guardianRig.routeChange(at: guardianRig.now + 0.010, to: [speaker])
        XCTAssertEqual(guardianRig.lastRemovalMeasure?.writtenBy, rule ? "buco-in-corso" : "percorso-tolta", "regola:\(rule): la tolta dopo lo scatto del guardiano")
        XCTAssertEqual(guardianRig.lastRemovalMeasure?.writtenNow, false, "regola:\(rule): silenzio:gia-scritto")
        var holeRig = playing(.direttore, route: [headphones], at: 10.0)
        holeRig.useSilenceWriterMemory = rule
        let holeAt = holeRig.now + holeRig.bufferSeconds + 0.060
        holeRig.advance(to: holeAt)
        holeRig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060)
        XCTAssertTrue(holeRig.isRunning, "regola:\(rule): sotto la soglia, l'uscita c'e' ancora")
        XCTAssertEqual(holeRig.lastHoleMeasure?.writtenBy, "buco", "regola:\(rule): la misura del buco")
        XCTAssertEqual(holeRig.lastHoleMeasure?.before, false, "regola:\(rule): scritto da questa chiamata")
        holeRig.routeChange(at: holeAt + 0.005, to: [speaker])
        XCTAssertEqual(holeRig.lastRemovalMeasure?.writtenBy, rule ? "buco" : "percorso-tolta", "regola:\(rule): la tolta dopo la chiamata del buco")
        XCTAssertEqual(holeRig.lastRemovalMeasure?.writtenNow, false, "regola:\(rule)")
        var noticeRig = playing(.direttore, route: [headphones], at: 10.0)
        noticeRig.useSilenceWriterMemory = rule
        noticeRig.routeChange(at: noticeRig.now + 0.100, to: [speaker])
        XCTAssertEqual(noticeRig.lastRemovalMeasure?.writtenBy, "percorso-tolta", "regola:\(rule): senza silenzio prima")
        XCTAssertEqual(noticeRig.lastRemovalMeasure?.writtenNow, true, "regola:\(rule): silenzio:scritto-ora")
    }
}

/// Dopo una crisi «buco» si prova lo stato (la crisi ferma il motore e la riga della tolta esce solo a motore in moto): lo 0
/// «buco-del-render» trova lo stato muto e il ricordo resta «buco»; com'era lo riscriveva.
func testTheCrisisAfterTheHoleKeepsTheHoleAsTheWriter() {
    for rule in [true, false] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useSilenceWriterMemory = rule
        rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        XCTAssertTrue(rig.silentInSong, "regola:\(rule)")
        XCTAssertFalse(rig.isRunning, "regola:\(rule)")
        XCTAssertEqual(rig.lastHoleMeasure?.writtenBy, "buco", "regola:\(rule)")
        XCTAssertEqual(rig.lastSilenceWrite?.reason, rule ? "buco" : "buco-del-render", "regola:\(rule): il ricordo dopo la crisi")
        // La finestra chiusa alla soglia: lo stesso, lo 0 «buco» prima della crisi.
        var window = playing(.direttore, route: [speaker], bpm: 180.5, at: 10.0)
        window.useSilenceWriterMemory = rule
        window.followsLink = true
        window.sectionChange(at: window.now + 0.001)
        window.callbacks(from: window.now + window.bufferSeconds, count: 50)
        window.absorbedPiece(0.140)
        window.callbacks(from: window.now + window.bufferSeconds, count: 51)
        XCTAssertEqual(window.windowCrises, 1, "regola:\(rule): la crisi alla chiusura della finestra")
        XCTAssertEqual(window.lastSilenceWrite?.reason, rule ? "buco" : "buco-del-render", "regola:\(rule)")
    }
}

/// Il Follower muto per l'uscita mancante con una ricostruzione del motore: lo 0 «avvio» sul mixer nuovo trova lo stato muto e non
/// cambia chi ha scritto; un buco dopo, col silenzio in vigore da prima del buco, lo misura («percorso-tolta», silenzioPrima:1).
/// Com'era: lo 0 «avvio» riscriveva il ricordo, e la misura del buco guardava solo le scritture nate dopo l'inizio del buco: il
/// Follower gia' muto usciva «scrittoDa:nessuno» con volume:0.
func testTheMutedFollowerRebuiltKeepsTheWriterAndTheHoleMeasuresTheSilenceFromBefore() {
    for rule in [true, false] {
        var rig = playing(.follower, route: [headphones], at: 10.0)
        rig.useSilenceWriterMemory = rule
        rig.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(rig.state.muted, "regola:\(rule)")
        XCTAssertTrue(rig.state.missing, "regola:\(rule)")
        XCTAssertEqual(rig.lastSilenceWrite?.reason, "percorso-tolta", "regola:\(rule)")
        rig.callbacks(from: 12.004, count: 20)
        rig.systemStopsEngine(at: 13.0)
        rig.configurationNotification(at: 13.1)
        XCTAssertEqual(rig.starts, 2, "regola:\(rule): la ricostruzione riparte")
        XCTAssertEqual(rig.volume, 0.0, "regola:\(rule): lo 0 «avvio» col Follower muto per l'uscita mancante")
        XCTAssertEqual(rig.lastSilenceWrite?.reason, rule ? "percorso-tolta" : "avvio", "regola:\(rule): lo 0 «avvio» non cambia chi ha scritto")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 50)
        let holeAt = rig.now + rig.bufferSeconds + 0.045
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.045)
        XCTAssertTrue(rig.isRunning, "regola:\(rule)")
        if rule {
            XCTAssertEqual(rig.lastHoleMeasure?.writtenBy, "percorso-tolta", "il silenzio in vigore da prima del buco")
            XCTAssertEqual(rig.lastHoleMeasure?.before, true, "silenzioPrima:1")
        } else {
            XCTAssertEqual(rig.lastHoleMeasure?.writtenBy, "nessuno", "com'era: scrittoDa:nessuno con volume:0")
        }
        XCTAssertEqual(rig.volume, 0.0, "regola:\(rule)")
    }
}

// MARK: - A421 · SEGUITO 3, par. 7: la strada vera della mappa sul Follower

/// Sul Follower la mappa arriva DOPO il primo `start()`: `followerRun(.start)` chiama `start()` (il blocco in coda), poi
/// `linkStartedSubject.send()` porta al runner, che chiama `setSongMap` e il secondo `start()`, che trova il motore in moto. Il
/// primo `start()` passa da `prepareNormalStartQ` senza il segno; il segno sale dopo; lo abbassa il fuoco dell'ingresso. Con
/// l'attesa d'ingresso zero il fuoco puo' passare prima del blocco di `setSongMap`: il segno resta alto fino al prossimo avvio che
/// passa da `prepareNormalStartQ`, che lo prende per «canzone in corso» (Aperto del referto).
/// ⚠️ RISCRITTO A425 (P4: mandato A425, par. 2.2). Le attese di questa prova erano il difetto che P4 cura: il secondo `start()` usciva
/// alla guardia senza consumare la mappa, il fuoco la abbassava, e col fuoco prima della mappa il segno restava alto fino all'avvio
/// dopo. Da A425 la mappa consegnata a un avvio in corso è di quell'avvio: la consuma il secondo `start()`, o il fuoco se viene dopo il
/// blocco di `setSongMap`; «canzone in corso» è vera per la canzone dove il Follower entra, e l'avvio dopo senza una mappa nuova è fuori
/// canzone. Col rig di prima (`useRunningStartConsumesMap` spento) le attese di prima.
func testTheFollowerMapArrivesAfterTheFirstStartAndTheFireLowersTheMark() {
    for consume in [true, false] {
        let tag = "regola:\(consume)"
        var rig = OutputRig(role: .follower, route: [speaker])
        rig.useRunningStartConsumesMap = consume
        rig.songInProgress = false
        rig.followerSessionPlaying = true
        rig.start(at: 10.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "\(tag): il primo start(): entra nella sessione che suona")
        XCTAssertFalse(rig.songInProgress, "\(tag): prepareNormalStartQ senza la mappa")
        XCTAssertFalse(rig.songMapPending, tag)
        rig.setSongMap()
        XCTAssertTrue(rig.songMapPending, "\(tag): il blocco di setSongMap, dopo quello del primo start()")
        rig.start(at: 10.0, recovery: nil)
        XCTAssertEqual(rig.starts, 1, "\(tag): il secondo start() esce alla guardia del motore in moto")
        XCTAssertEqual(rig.songMapPending, !consume, consume ? "il secondo start() consuma la mappa (P4)" : "senza consumare il segno")
        XCTAssertEqual(rig.songInProgress, consume, tag)
        rig.followerJoinFired()
        XCTAssertFalse(rig.songMapPending, consume ? "il fuoco trova il segno basso" : "il fuoco dell'ingresso lo abbassa")
        XCTAssertEqual(rig.songInProgress, consume, consume ? "canzone in corso per la canzone dove entra (P4)" : "sul Follower canzone: resta 0")
        XCTAssertEqual(rig.mapsConsumedByRunningStart, consume ? 1 : 0, tag)
        // L'attesa zero nell'ordine «fuoco prima della mappa».
        var zero = OutputRig(role: .follower, route: [speaker])
        zero.useRunningStartConsumesMap = consume
        zero.songInProgress = false
        zero.followerSessionPlaying = true
        zero.start(at: 10.0, recovery: nil)
        zero.followerJoinFired()
        XCTAssertFalse(zero.songInProgress, "\(tag): il fuoco prima della mappa trova il segno basso")
        zero.setSongMap()
        zero.start(at: 10.0, recovery: nil)
        XCTAssertEqual(zero.songMapPending, !consume, consume ? "il secondo start() la consuma (P4)" : "il segno resta alto")
        XCTAssertEqual(zero.songInProgress, consume, tag)
        zero.stop(at: 20.0)
        zero.start(at: 21.0, recovery: nil)
        XCTAssertEqual(zero.songInProgress, !consume, consume ? "l'avvio dopo, senza una mappa nuova, è fuori canzone"
                                                             : "l'avvio dopo, anche senza una mappa nuova, lo prende per «canzone in corso»")
        XCTAssertFalse(zero.songMapPending, tag)
        // L'attesa zero nell'ordine «fuoco dopo il blocco di setSongMap e prima del secondo start()»: lo consuma il fuoco.
        var fireFirst = OutputRig(role: .follower, route: [speaker])
        fireFirst.useRunningStartConsumesMap = consume
        fireFirst.songInProgress = false
        fireFirst.followerSessionPlaying = true
        fireFirst.start(at: 10.0, recovery: nil)
        fireFirst.setSongMap()
        fireFirst.followerJoinFired()
        fireFirst.start(at: 10.0, recovery: nil)
        XCTAssertFalse(fireFirst.songMapPending, tag)
        XCTAssertEqual(fireFirst.songInProgress, consume, consume ? "lo consuma il fuoco (P4)" : "il fuoco lo abbassa senza consumarlo")
    }
}

// MARK: - A421 · SEGUITO 3, par. 8.1: la fine della canzone dentro la finestra dell'àncora tenuta

/// La fine della canzone fra il fuoco del rientro e il primo battito contato uscito: l'àncora si chiude (col motore in moto e il
/// silenzio gia' finito e' lo Stop voluto del runner, motivo «stop»; lo Stop di fine canzone armato durante il silenzio,
/// `fireDirectorSongEndStopQ`, non si manda), il segno «tenuta» si toglie, nessun rientro dopo, lo Stop a Link come oggi. E la fine
/// della canzone col Direttore ancora muto a motore fermo: lo Stop di fine canzone chiude l'àncora col motivo «fine-canzone» e
/// annulla il ritorno armato: niente rientra.
func testTheSongEndInsideTheHeldAnchorWindowClosesTheAnchor() throws {
    var rig = playing(.direttore, route: [speaker], at: 10.0, cycleSeconds: 2 * 512.0 / 48_000.0)
    rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
    XCTAssertTrue(rig.silentInSong)
    rig.advance(to: 20.1)
    XCTAssertTrue(rig.isRunning)
    let fireAt = try XCTUnwrap(rig.rejoin, "il rientro armato").fireAt
    rig.advance(to: fireAt)
    XCTAssertEqual(rig.rejoins, 1)
    XCTAssertTrue(rig.anchorHeld)
    XCTAssertTrue(rig.anchor)
    let target = try XCTUnwrap(rig.firstClickAt, "il primo click del rientro")
    rig.callbacks(from: fireAt + rig.bufferSeconds, count: 1)
    XCTAssertTrue(rig.anchorHeld, "prima del primo battito contato uscito")
    let endAt = rig.now + 0.002
    XCTAssertLessThan(endAt, target, "dentro la finestra")
    let linkStops = rig.linkStops
    rig.songEnd(at: endAt)
    XCTAssertFalse(rig.anchorHeld, "il segno «tenuta» si toglie")
    XCTAssertFalse(rig.anchor, "l'àncora si chiude")
    XCTAssertEqual(try XCTUnwrap(rig.anchorClosedAt), endAt, accuracy: 1e-9)
    XCTAssertEqual(rig.anchorCloseReason, "stop", "col motore in moto e' lo Stop voluto del runner che la chiude")
    XCTAssertEqual(rig.songEndStops, 0, "lo Stop di fine canzone del silenzio non si manda: il silenzio e' gia' finito")
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.linkStops, linkStops + 1, "lo Stop di fine canzone a Link come oggi")
    XCTAssertFalse(rig.songInProgress)
    XCTAssertTrue(rig.wantedStop)
    rig.advance(to: endAt + 10.0)
    XCTAssertEqual(rig.rejoins, 1, "nessun rientro dopo")
    XCTAssertEqual(rig.starts, 2)
    XCTAssertNil(rig.rejoin)
    XCTAssertNil(rig.directorReturn)
    // Il Direttore ancora muto a motore fermo: lo Stop di fine canzone armato durante il silenzio.
    var silent = playing(.direttore, route: [speaker], at: 10.0)
    silent.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
    XCTAssertTrue(silent.silentInSong)
    XCTAssertTrue(silent.anchor)
    XCTAssertNotNil(silent.directorReturn)
    silent.songEnd(at: 20.05)
    XCTAssertEqual(silent.songEndStops, 1, "lo Stop di fine canzone inviato")
    XCTAssertEqual(silent.anchorCloseReason, "fine-canzone")
    XCTAssertFalse(silent.anchor)
    XCTAssertFalse(silent.anchorHeld)
    XCTAssertFalse(silent.silentInSong)
    XCTAssertNil(silent.directorReturn, "il ritorno annullato")
    silent.advance(to: 30.0)
    XCTAssertEqual(silent.starts, 1, "niente rientra")
    XCTAssertEqual(silent.rejoins, 0)
}

// MARK: - A421 · SEGUITO 3, par. 8.4 (seguito 2, par. 5.6): l'«uno» sulla chiamata che consuma l'ultimo salto

/// F1 col ritorno del Follower: l'«uno» cade nel buffer della chiamata che consuma l'ultimo salto (contatore 1 → 0: all'inizio della
/// chiamata e' ancora > 0, la correzione non gira): il volume non torna e il ritorno va alla battuta dopo; alla chiamata dopo la
/// prima correzione dopo la finestra non sposta di un buffer: nessun riarmo, e il volume torna sull'«uno» della battuta dopo.
func testF1TheUnoOnTheCallThatConsumesTheLastSkipMovesToTheNextBar() throws {
    var rig = playing(.follower, route: [headphones], bpm: 180.5, at: 10.0)
    rig.routeChange(at: 15.0, to: [speaker])
    rig.callbacks(from: 15.004, count: 50)
    let t0 = rig.now + 0.001
    // La griglia di Link messa in modo che un «uno» cada nel buffer della 100ª chiamata dopo la notizia (il contatore a 1).
    let lastSkipCallAt = t0 + 0.001 + 100 * rig.bufferSeconds
    let unoAt = lastSkipCallAt + rig.latency + rig.cycleSeconds + rig.bufferSeconds / 2
    rig.linkAnchorBeat = 0
    rig.linkAnchorTime = unoAt
    rig.sectionChange(at: t0)
    rig.routeChange(at: t0 + 0.001, to: [headphones])
    XCTAssertTrue(try XCTUnwrap(rig.followerReturn, "il ritorno del Follower prenotato").armPending)
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 99, correction: 0.0005)
    XCTAssertEqual(rig.syncSkip, 1)
    XCTAssertEqual(try XCTUnwrap(rig.armedUnoAt), unoAt, accuracy: 1e-6, "l'uno dell'armo e' quello della chiamata dell'ultimo salto")
    XCTAssertEqual(rig.nextBarMoves, 0)
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: 0.0005)
    XCTAssertEqual(rig.syncSkip, 0, "la chiamata che consuma l'ultimo salto")
    XCTAssertEqual(rig.volume, 0.0, "l'uno in questa chiamata non rimette il volume")
    XCTAssertEqual(rig.nextBarMoves, 1, "la battuta dopo (.nextBarInWindow)")
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: 0.0005)
    XCTAssertFalse(rig.windowOpen)
    XCTAssertEqual(rig.firstCorrectionRearms, 0, "la prima correzione dopo la finestra non sposta di un buffer")
    XCTAssertEqual(rig.volume, 0.0, "si aspetta l'uno della battuta dopo")
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 200, correction: 0.0005)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertEqual(try XCTUnwrap(rig.restoredUnoAt), unoAt + rig.barSeconds, accuracy: 1e-6, "sull'uno della battuta dopo")
    checkReturnInvariants(rig, "F1 uno sull'ultimo salto", oneBarAtMost: true)
}

// MARK: - A432 · parte 2b (voce i): l'«uno» del ritorno del Follower dal conto sulla band

/// A424, Aperto A.14, in sequenza: la canzone è 4/4 per due battute e poi 3/4 (a 120), l'àncora del conto al battito 96 della
/// sessione (un multiplo di 12): gli «uno» del 3/4 sono 104, 107, 110… (resto 2 a dividere per 3), le battute di Link col quanto 3
/// sono i multipli di 3. La cuffia tolta e rimessa nel 3/4: col conto certo il ritorno sceglie un «uno» della canzone, con
/// l'orologio del conto, e il volume torna su un «uno» della canzone; la regola di prima avrebbe scelto la battuta di Link, che è
/// il secondo battito di una battuta della canzone.
func testTheFollowerReturnAfterAMeterChangeIsOnADownbeatOfTheSong() throws {
    var rig = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 3, at: 50.0)
    let map = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 120),
                                 SongMapSection(beatsPerBar: 3, repetitions: 100, bpm: 120)])
    rig.bandCount = FollowerBandCount(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 96,
                                                                        ticks: rig.ticks(48.0)))
    rig.routeChange(at: 55.0, to: [speaker])
    rig.callbacks(from: 55.681, count: 30)
    rig.routeChange(at: 58.806, to: [headphones])
    XCTAssertTrue(try XCTUnwrap(rig.followerReturn, "il ritorno del Follower prenotato").armPending)
    let firstCall = 58.806 + 0.684
    rig.callbacks(from: firstCall, count: 1)
    let armed = try XCTUnwrap(rig.followerReturn)
    let uno = try XCTUnwrap(armed.uno)
    let unoAt = try XCTUnwrap(armed.unoAt)
    let deadline = try XCTUnwrap(rig.deadlineAt)
    XCTAssertEqual(uno.clock, .band, "l'«uno» viene dal conto")
    XCTAssertEqual(uno.beatsPerBar, 3)
    XCTAssertEqual((uno.beat - 104).truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-9, "un «uno» della canzone")
    XCTAssertEqual(uno.beat.truncatingRemainder(dividingBy: 3), 2, accuracy: 1e-9, "che non è una battuta di Link col quanto 3")
    XCTAssertEqual(unoAt, rig.time(ofBeat: uno.beat), accuracy: 1e-9, "la sua ora è quella di Link per quel battito")
    XCTAssertGreaterThanOrEqual(unoAt, deadline - 1e-9)
    XCTAssertLessThan(unoAt, deadline + rig.barSeconds, "il primo «uno» della canzone dopo la scadenza")
    let old = try XCTUnwrap(OutputReturnDecision.nextBarBeat(atOrAfter: rig.linkBeat(at: deadline), quantum: 3))
    XCTAssertEqual((old - 104).truncatingRemainder(dividingBy: 3), 1, accuracy: 1e-9,
                   "la regola di prima: il secondo battito di una battuta della canzone")
    rig.callbacks(from: firstCall + rig.bufferSeconds, count: 400)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertNil(rig.followerReturn)
    let restored = try XCTUnwrap(rig.restoredUnoAt)
    XCTAssertEqual((rig.linkBeat(at: restored) - 104).truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-6,
                   "il volume è tornato su un «uno» della canzone")
    // Il gemello senza conto, stessa sequenza: gli stessi riarmi (il metro del motore e l'orologio non riarmano un «uno» del conto).
    var twin = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 3, at: 50.0)
    twin.routeChange(at: 55.0, to: [speaker])
    twin.callbacks(from: 55.681, count: 30)
    twin.routeChange(at: 58.806, to: [headphones])
    twin.callbacks(from: firstCall, count: 1)
    twin.callbacks(from: firstCall + twin.bufferSeconds, count: 400)
    XCTAssertEqual(twin.volume, 1.0)
    XCTAssertEqual(rig.rearms, twin.rearms, "il metro del motore e l'orologio non riarmano un «uno» del conto")
    checkReturnInvariants(rig, "A.14")
}

/// Lo stesso buco: il conto si chiude (o si azzera) fra l'armo e l'«uno». L'orologio di adesso non è più quello salvato: il ritorno
/// si riarma con la stessa regola, che senza il conto è quella di sempre (la battuta di Link), e il volume torna.
func testTheFollowerReturnFromTheCountRearmsOnTheLinkBarWhenTheCountGoesAway() throws {
    var rig = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 3, at: 50.0)
    let map = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 120),
                                 SongMapSection(beatsPerBar: 3, repetitions: 100, bpm: 120)])
    rig.bandCount = FollowerBandCount(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 96,
                                                                        ticks: rig.ticks(48.0)))
    rig.routeChange(at: 55.0, to: [speaker])
    rig.callbacks(from: 55.681, count: 30)
    rig.routeChange(at: 58.806, to: [headphones])
    let firstCall = 58.806 + 0.684
    rig.callbacks(from: firstCall, count: 1)
    XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(rig.followerReturn).uno).clock, .band)
    let rearmsBefore = rig.rearms
    rig.bandCount = nil
    rig.callbacks(from: firstCall + rig.bufferSeconds, count: 1)
    XCTAssertEqual(rig.rearms, rearmsBefore + 1, "l'orologio non è più quello salvato: si riarma")
    let again = try XCTUnwrap(try XCTUnwrap(rig.followerReturn).uno)
    XCTAssertEqual(again.clock, .link, "senza il conto: l'«uno» di Link, come prima")
    XCTAssertEqual(again.beat.truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-9)
    rig.callbacks(from: firstCall + 2 * rig.bufferSeconds, count: 400)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertNil(rig.followerReturn)
    checkReturnInvariants(rig, "A.14 senza conto", oneBarAtMost: false)
}

/// Senza conto (com'era fino a qui) lo stesso buco sceglie la battuta di Link: il rig di prima non cambia.
func testWithoutACountTheFollowerReturnIsOnTheLinkBarAsBefore() throws {
    var rig = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 3, at: 50.0)
    rig.routeChange(at: 55.0, to: [speaker])
    rig.callbacks(from: 55.681, count: 30)
    rig.routeChange(at: 58.806, to: [headphones])
    rig.callbacks(from: 58.806 + 0.684, count: 1)
    let uno = try XCTUnwrap(try XCTUnwrap(rig.followerReturn).uno)
    XCTAssertEqual(uno.clock, .link)
    XCTAssertEqual(uno.beat.truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-9)
}

/// Dopo la nota N1 del verificatore V3 (referto della 2b, §8): lo stesso buco PRIMA del confine. La canzone è 4/4 per sei battute
/// (24 battiti) e poi 3/4; l'àncora al battito 96 della sessione, il confine a 120 (60 s). Il motore è ancora nel 4/4 (il suo metro
/// è 4); la scadenza cade nell'ultima battuta del 4/4 e l'«uno» del conto è il primo del 3/4: porta i 3 battiti per battuta della
/// SUA sezione, non i 4 del motore. Il metro del motore non riarma un «uno» del conto (`refreshUno`): gli stessi riarmi del gemello
/// senza conto, e l'«uno» resta quello. Senza quella regola il ritorno si riarmerebbe a ogni chiamata («metro-cambiato»).
func testTheMeterOfTheEngineDoesNotRearmAnUnoOfTheCount() throws {
    var rig = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 4, at: 50.0)
    let map = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 6, bpm: 120),
                                 SongMapSection(beatsPerBar: 3, repetitions: 100, bpm: 120)])
    rig.bandCount = FollowerBandCount(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 96,
                                                                        ticks: rig.ticks(48.0)))
    var twin = playing(.follower, route: [headphones], bpm: 120, beatsPerBar: 4, at: 50.0)
    let firstCall = 58.806 + 0.684
    rig.routeChange(at: 55.0, to: [speaker])
    rig.callbacks(from: 55.681, count: 30)
    rig.routeChange(at: 58.806, to: [headphones])
    rig.callbacks(from: firstCall, count: 1)
    twin.routeChange(at: 55.0, to: [speaker])
    twin.callbacks(from: 55.681, count: 30)
    twin.routeChange(at: 58.806, to: [headphones])
    twin.callbacks(from: firstCall, count: 1)
    let uno = try XCTUnwrap(try XCTUnwrap(rig.followerReturn).uno)
    XCTAssertEqual(uno.clock, .band)
    XCTAssertEqual(uno.beat, 120, accuracy: 1e-9, "il primo «uno» del 3/4")
    XCTAssertEqual(uno.beatsPerBar, 3, "i battiti per battuta della sua sezione")
    XCTAssertEqual(rig.beatsPerBar, 4, "il metro del motore è ancora quello di prima del confine")
    XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(twin.followerReturn).uno).clock, .link)
    rig.callbacks(from: firstCall + rig.bufferSeconds, count: 5)
    twin.callbacks(from: firstCall + twin.bufferSeconds, count: 5)
    XCTAssertEqual(rig.rearms, twin.rearms, "il metro del motore non riarma un «uno» del conto")
    XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(rig.followerReturn, "il ritorno è ancora armato").uno), uno, "l'«uno» resta quello")
    rig.callbacks(from: firstCall + 6 * rig.bufferSeconds, count: 400)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertNil(rig.followerReturn)
    let restored = try XCTUnwrap(rig.restoredUnoAt)
    XCTAssertEqual((rig.linkBeat(at: restored) - 120).truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-6,
                   "il volume è tornato su un «uno» della canzone")
    checkReturnInvariants(rig, "A.14 prima del confine")
}

// MARK: - A421 · SEGUITO 4, par. 3.1: la scorta del rientro come il motore

/// Il fuoco del rientro come il motore: l'origine del DSP sull'«uno» e la posizione sul seme, l'«uno» meno la scorta
/// (`DirectorRejoinDecision.leadIn`). La scorta finisce nella chiamata il cui buffer porta l'«uno», col bordo del DSP in campioni
/// interi: senza correzione il buffer d'indice `leadInBuffers` (l'«uno» al suo primo campione); con una prima correzione in avanti il
/// buffer prima; con una correzione che scavalca l'«uno» il buffer di quella chiamata (il DSP lo fa uscire al primo campione), e
/// zittito se esce in ritardo di almeno un buffer. Dopo la prima correzione le correzioni non si applicano. Un buco nella chiamata
/// dell'«uno» e' ancora nella scorta: la crisi «scorta». Col rig di prima (interruttore spento): la posizione sull'«uno», la scorta per
/// `leadInBuffers` chiamate (una prima del motore), l'«uno» mai contato, ogni correzione applicata, e il buco nella chiamata
/// dell'«uno» fuori dalla scorta: segue Link.
func testTheLeadInEndsInTheCallThatCarriesTheUnoLikeTheDSP() throws {
    for engine in [true, false] {
        let tag = "motore:\(engine)"
        // Senza correzione.
        var plain = try rejoined(engineLeadIn: engine)
        let uno = plain.dspOrigin
        let buffers = plain.leadInBuffers
        XCTAssertEqual(buffers, 5, "\(tag): il ciclo di base, cinque buffer")
        XCTAssertEqual(plain.position, (engine ? uno - Double(buffers) * plain.bufferBeats : uno) + 3 * plain.bufferBeats,
                       accuracy: 1e-9, engine ? "il seme, piu' i tre buffer del fuoco" : "il rig di prima: la posizione sull'uno")
        let clicks = plain.clickSamplesWritten
        var calls = 3
        while plain.inLeadIn && calls < 40 {
            plain.callbacks(from: plain.now + plain.bufferSeconds, count: 1)
            calls += 1
        }
        if engine {
            XCTAssertEqual(calls, buffers + 1, "la scorta finisce nella chiamata del buffer d'indice leadInBuffers")
            XCTAssertEqual(plain.leadInUnoBuffer, buffers, "l'uno al primo campione del buffer d'indice leadInBuffers")
            XCTAssertEqual(plain.clickSamplesWritten, clicks + 1, "l'uno si conta e suona nel suo buffer")
        } else {
            XCTAssertEqual(calls, buffers, "il rig di prima: la scorta finiva una chiamata prima")
            XCTAssertNil(plain.leadInUnoBuffer)
            XCTAssertEqual(plain.clickSamplesWritten, clicks, "il rig di prima: l'uno sul bordo del primo buffer non si contava")
        }
        // Una prima correzione in avanti di mezzo buffer: l'«uno» nel buffer prima.
        var forward = try rejoined(engineLeadIn: engine)
        forward.callbacks(from: forward.now + forward.bufferSeconds, count: 1, correction: 0.5 * forward.bufferBeats)
        XCTAssertTrue(forward.inLeadIn, tag)
        forward.callbacks(from: forward.now + forward.bufferSeconds, count: 1)
        XCTAssertFalse(forward.inLeadIn, tag)
        XCTAssertEqual(forward.leadInUnoBuffer, engine ? buffers - 1 : nil, tag)
        // Una prima correzione che scavalca l'«uno» di mezzo buffer: il DSP lo fa uscire al primo campione del buffer di questa
        // chiamata, e la scorta finisce qui; esce in ritardo di mezzo buffer, quindi suona.
        var over = try rejoined(engineLeadIn: engine)
        let overClicks = over.clickSamplesWritten
        over.callbacks(from: over.now + over.bufferSeconds, count: 1, correction: 2.5 * over.bufferBeats)
        XCTAssertEqual(over.inLeadIn, !engine, tag)
        XCTAssertEqual(over.leadInUnoBuffer, engine ? 3 : nil, tag)
        XCTAssertEqual(over.lateBeatsMuted, 0, tag)
        XCTAssertEqual(over.clickSamplesWritten, overClicks + (engine ? 1 : 0), tag)
        // La stessa, scavalcato di un buffer e mezzo: l'«uno» esce in ritardo di piu' di un buffer, si conta e non suona (U9).
        var late = try rejoined(engineLeadIn: engine)
        let lateClicks = late.clickSamplesWritten
        late.callbacks(from: late.now + late.bufferSeconds, count: 1, correction: 3.5 * late.bufferBeats)
        XCTAssertEqual(late.leadInUnoBuffer, engine ? 3 : nil, tag)
        XCTAssertEqual(late.lateBeatsMuted, engine ? 1 : 0, "\(tag): il battito del fire-asap zittito")
        XCTAssertEqual(late.clickSamplesWritten, lateClicks, tag)
        // Dopo la prima correzione le correzioni non si applicano.
        // ⚠️ A425 (par. 2.5): erano −0,005 e +0,004, sotto la soglia di Link (0,01): il motore non le avrebbe applicate, e nella scorta
        // la prima correzione si conta solo se applicata; −0,02 e +0,015, sopra la soglia, col significato di prima (la prima
        // correzione della scorta indietro, la seconda in avanti).
        var second = try rejoined(engineLeadIn: engine)
        second.callbacks(from: second.now + second.bufferSeconds, count: 1, correction: -0.02)
        let beforeSecond = second.position
        second.callbacks(from: second.now + second.bufferSeconds, count: 1, correction: 0.015)
        XCTAssertEqual(second.position, beforeSecond + (engine ? 0 : 0.015) + second.bufferBeats, accuracy: 1e-9, tag)
        XCTAssertEqual(second.corrections, engine ? 1 : 2, tag)
        // Un buco di 40 ms nella chiamata dell'«uno» (la sesta della catena): ancora nella scorta, la crisi «scorta»; col rig di prima la
        // scorta era finita: sotto la soglia, segue Link.
        var hole = try rejoined(engineLeadIn: engine)
        hole.callbacks(from: hole.now + hole.bufferSeconds, count: 2)
        XCTAssertEqual(hole.inLeadIn, engine, "\(tag): dopo cinque chiamate")
        let holeAt = hole.now + hole.bufferSeconds + 0.040
        hole.advance(to: holeAt)
        hole.scheduleNextBuffer(at: holeAt, gapSeconds: 0.040)
        XCTAssertEqual(hole.leadInCrises, engine ? 1 : 0, tag)
        XCTAssertEqual(hole.isRunning, !engine, tag)
        XCTAssertEqual(hole.silentInSong, engine, tag)
    }
}

/// L'àncora dopo il rientro, come il motore (A421 · SEGUITO 4, par. 3.1; il rilievo BL-1 del verificatore): chiusa l'àncora tenuta
/// (il primo battito contato del rientro, l'«uno», è uscito), una crisi prima del battito dopo prende l'àncora dall'«uno» contato —
/// `takeSilenceAnchorQ` legge `_lastCountedBeatQ`, che `closeSilenceAnchorQ` non tocca — e il coordinatore rientra di nuovo. Col rig
/// di prima (interruttore spento) l'«uno» non si contava: nessuna àncora fino al battito dopo, e la stessa crisi finiva «non certo».
func testACrisisAfterTheHeldAnchorClosesTakesTheAnchorFromTheUno() throws {
    for engine in [true, false] {
        let tag = "motore:\(engine)"
        var rig = try rejoined(engineLeadIn: engine)
        let target = try XCTUnwrap(rig.firstClickAt, "\(tag): il primo click del rientro")
        // I richiami fino a 100 ms dopo il bersaglio: l'àncora tenuta si chiude alla prima chiamata dopo il bersaglio.
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: Int((target + 0.100 - rig.now) / rig.bufferSeconds))
        XCTAssertFalse(rig.anchorHeld, tag)
        XCTAssertFalse(rig.anchor, tag)
        XCTAssertFalse(rig.countedBeatOut, "\(tag): il battito dopo l'uno non e' ancora programmato")
        // Un buco di 300 ms: la crisi in canzone.
        let holeAt = rig.now + rig.bufferSeconds + 0.300
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.300)
        XCTAssertTrue(rig.silentInSong, tag)
        XCTAssertEqual(rig.anchor, engine, engine ? "l'àncora dall'uno contato e uscito" : "il rig di prima: nessuna àncora")
        rig.advance(to: holeAt + 5.0)
        XCTAssertEqual(rig.rejoins, engine ? 2 : 1, tag)
        XCTAssertEqual(rig.uncertainRejoins, engine ? 0 : 1, tag)
    }
}

// MARK: - A421 · SEGUITO 4, par. 3.2: «canzone in corso» come il motore

/// «Canzone in corso» nei punti del motore che la scrivono. Il Play dal runner: Direttore e Solo in canzone, con la mappa prima dell'avvio;
/// il Follower anche (⚠️ RISCRITTO A425, P4, c'era «no (… e la abbassa il fuoco dell'ingresso)»: la mappa, dopo il primo `start()`, la
/// consuma il secondo). Lo Stop voluto e l'arresto della crisi del Solo (`stopSync`), l'arresto locale del cambio di ruolo col volume a 0 e
/// la Reset del Follower la abbassano; un avvio senza mappa, anche una ripartenza automatica, la lascia falsa (`prepareNormalStartQ`); la
/// fine della canzone e la chiusura dello show come prima. Il Direttore ripartito col pedale dopo uno Stop (un avvio senza mappa) e' fuori
/// canzone come nel motore: un buco di 300 ms segue Link, senza il silenzio in canzone. Col rig di prima (interruttore spento) restava vera
/// dopo lo Stop, l'arresto del Solo, il cambio di ruolo e la Reset, e un avvio senza mappa la lasciava com'era.
func testSongInProgressFollowsTheEngineAtEveryStopAndStart() {
    for engine in [true, false] {
        let tag = "motore:\(engine)"
        // Il Play dal runner.
        let director = playing(.direttore, route: [speaker], at: 10.0, engineSongInProgress: engine)
        XCTAssertTrue(director.songInProgress, "\(tag): il Direttore dal runner, con la mappa")
        XCTAssertTrue(playing(.solo, route: [speaker], at: 10.0, engineSongInProgress: engine).songInProgress, "\(tag): il Solo")
        let follower = playing(.follower, route: [headphones], at: 10.0, engineSongInProgress: engine)
        // ⚠️ A425 (P4): qui c'era `XCTAssertEqual(follower.songInProgress, !engine, …)`: col rig del motore la mappa, che arriva dopo
        // il primo `start()`, la consuma il secondo `start()` che trova il motore in moto, e «canzone in corso» è vera; col rig di
        // prima vera per il valore iniziale del rig.
        XCTAssertTrue(follower.songInProgress, engine ? "\(tag): il Follower, la mappa consumata dall'avvio in corso (P4)"
                                                      : "\(tag): il rig di prima, il valore iniziale")
        XCTAssertFalse(follower.songMapPending, "\(tag): il segno giù (consumato, o abbassato dal fuoco col rig di prima)")
        // Lo Stop voluto, poi il pedale (un avvio senza mappa) e un buco di 300 ms.
        var pedal = director
        pedal.stop(at: 15.0)
        XCTAssertEqual(pedal.songInProgress, !engine, "\(tag): lo Stop voluto")
        pedal.pedalPlayPause(at: 16.0)
        XCTAssertTrue(pedal.isRunning, tag)
        XCTAssertEqual(pedal.songInProgress, !engine, "\(tag): il pedale, un avvio senza mappa")
        pedal.callbacks(from: 16.0 + pedal.bufferSeconds, count: 50)
        let holeAt = pedal.now + pedal.bufferSeconds + 0.300
        pedal.advance(to: holeAt)
        pedal.scheduleNextBuffer(at: holeAt, gapSeconds: 0.300)
        XCTAssertEqual(pedal.isRunning, engine, engine ? "fuori canzone un buco segue Link" : "il rig di prima: la crisi in canzone")
        XCTAssertEqual(pedal.silentInSong, !engine, tag)
        // Il Play dal runner dopo lo Stop: di nuovo in canzone.
        var runner = director
        runner.stop(at: 15.0)
        runner.runnerPlay(at: 16.0)
        XCTAssertTrue(runner.songInProgress, "\(tag): il runner consegna la mappa prima dell'avvio")
        // L'arresto della crisi del Solo: la tolta delle cuffie.
        var soloCrisis = playing(.solo, route: [headphones], at: 10.0, engineSongInProgress: engine)
        soloCrisis.routeChange(at: 12.0, to: [speaker])
        XCTAssertEqual(soloCrisis.soloStops, 1, tag)
        XCTAssertEqual(soloCrisis.songInProgress, !engine, "\(tag): l'arresto della crisi del Solo")
        // Una ripartenza automatica senza mappa nuova: la configurazione col Solo in moto.
        var restart = playing(.solo, route: [speaker], at: 10.0, engineSongInProgress: engine)
        restart.showOpen = false   // A437: a show chiuso il Solo resta com'era (in canzone, da 3b, riprende sulla canzone)
        restart.systemStopsEngine(at: 11.0)
        restart.configurationNotification(at: 11.1)
        XCTAssertEqual(restart.starts, 2, "\(tag): la ripartenza come oggi")
        XCTAssertEqual(restart.songInProgress, !engine, "\(tag): la ripartenza passa da prepareNormalStartQ senza mappa")
        // L'arresto locale del cambio di ruolo col volume a 0: il Follower muto con «canzone in corso» vera, messa a mano (sul Follower
        // la lascia vera solo l'ordine dell'attesa zero: referto del seguito 3, Aperto §A.3). A425 (P4): col rig del motore è gia' vera
        // (la mappa consumata dall'avvio in corso); la riga a mano resta per il rig di prima.
        var role = follower
        role.songInProgress = true
        role.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(role.state.muted, tag)
        role.roleChange(to: .solo, at: 13.0)
        XCTAssertFalse(role.isRunning, "\(tag): l'arresto locale")
        XCTAssertEqual(role.songInProgress, !engine, "\(tag): l'arresto locale del cambio di ruolo")
        // La Reset del Follower (`stopSync(.followerReset)`), provata prima del Play, e il suo avvio dopo la ricostruzione (un avvio
        // senza mappa, che da solo la lascerebbe falsa anche senza la Reset).
        var reset = follower
        reset.songInProgress = true
        reset.servicesLost(at: 12.0)
        var resetOnly = reset
        resetOnly.mediaReset()
        XCTAssertEqual(resetOnly.songInProgress, !engine, "\(tag): la Reset del Follower")
        reset.rebuiltAndPlay(at: 20.0)
        XCTAssertTrue(reset.isRunning, tag)
        XCTAssertEqual(reset.songInProgress, !engine, "\(tag): l'avvio dopo la ricostruzione")
        // La fine della canzone e la chiusura dello show, come prima.
        var end = director
        end.songEnd(at: 15.0)
        XCTAssertFalse(end.songInProgress, "\(tag): la fine della canzone")
        var closed = director
        closed.closeShow(at: 15.0)
        XCTAssertFalse(closed.songInProgress, "\(tag): la chiusura dello show")
    }
}

// MARK: - A421 · SEGUITO 4, par. 4: il ricordo del silenzio in vigore se ne va a ogni passaggio di `muted` da vero a falso

/// Il volume a 1 (`writeOutputVolumeQ(1, …)`): il ritorno dopo il buco rimette il volume e il ricordo del silenzio in vigore («buco»)
/// se ne va. Senza la regola (`useSilenceWriterMemory` spento) restava.
func testTheVolumeBackToOneLiftsTheSilenceInForce() {
    for rule in [true, false] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useSilenceWriterMemory = rule
        let holeAt = rig.now + rig.bufferSeconds + 0.060
        rig.advance(to: holeAt)
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060)
        XCTAssertTrue(rig.isRunning, "regola:\(rule): sotto la soglia")
        XCTAssertTrue(rig.state.muted, "regola:\(rule)")
        XCTAssertEqual(rig.lastSilenceWrite?.reason, "buco", "regola:\(rule)")
        rig.callbacks(from: holeAt + rig.bufferSeconds, count: 30, correction: 0.0)
        XCTAssertEqual(rig.gapReturnRestores, 1, "regola:\(rule): il volume torna")
        XCTAssertFalse(rig.state.muted, "regola:\(rule)")
        if rule {
            XCTAssertNil(rig.lastSilenceWrite, "il volume a 1: il ricordo se ne va")
        } else {
            XCTAssertEqual(rig.lastSilenceWrite?.reason, "buco", "senza la regola il ricordo restava")
        }
    }
}

/// La chiusura dello show (`noteOutputStateQ(.showClosed, …)`), dove e' proprio lei a portare `muted` da vero a falso: il Direttore muto a
/// motore fermo dopo una crisi, e il Follower muto coi servizi audio persi; la chiusura non scrive il volume (a motore fermo, o sul
/// motore morto). Col motore in moto, muto e coi servizi normali il volume a 1 viene prima e la chiusura trova `muted` gia' falso (il
/// test del volume). Il ricordo se ne va; senza la regola restava.
func testTheShowCloseLiftsTheSilenceInForceAtEngineStoppedOrWithTheServicesLost() {
    for rule in [true, false] {
        var stopped = playing(.direttore, route: [speaker], at: 10.0)
        stopped.useSilenceWriterMemory = rule
        stopped.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        XCTAssertTrue(stopped.silentInSong, "regola:\(rule)")
        XCTAssertFalse(stopped.isRunning, "regola:\(rule)")
        XCTAssertTrue(stopped.state.muted, "regola:\(rule)")
        XCTAssertEqual(stopped.lastSilenceWrite?.reason, rule ? "buco" : "buco-del-render", "regola:\(rule)")
        stopped.closeShow(at: 20.05)
        XCTAssertFalse(stopped.state.muted, "regola:\(rule): la chiusura dello show")
        XCTAssertEqual(stopped.volume, 0.0, "regola:\(rule): a motore fermo nessuna scrittura del volume")
        if rule {
            XCTAssertNil(stopped.lastSilenceWrite, "la chiusura dello show: il ricordo se ne va")
        } else {
            XCTAssertEqual(stopped.lastSilenceWrite?.reason, "buco-del-render", "senza la regola il ricordo restava")
        }
        var lost = playing(.follower, route: [headphones], at: 10.0)
        lost.useSilenceWriterMemory = rule
        lost.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(lost.state.muted, "regola:\(rule)")
        XCTAssertEqual(lost.lastSilenceWrite?.reason, "percorso-tolta", "regola:\(rule)")
        lost.servicesLost(at: 12.5)
        XCTAssertTrue(lost.isRunning, "regola:\(rule): il Follower resta in moto fino alla Reset")
        lost.closeShow(at: 13.0)
        XCTAssertFalse(lost.state.muted, "regola:\(rule): la chiusura dello show")
        XCTAssertEqual(lost.volume, 0.0, "regola:\(rule): coi servizi persi nessuna scrittura del volume")
        if rule {
            XCTAssertNil(lost.lastSilenceWrite, "la chiusura dello show: il ricordo se ne va")
        } else {
            XCTAssertEqual(lost.lastSilenceWrite?.reason, "percorso-tolta", "senza la regola il ricordo restava")
        }
    }
}

/// Il cambio di ruolo (e Link spento dall'utente): `handleRoleOrLinkChangeQ` non scrive il volume, il ricordo lo toglie l'evento
/// `.roleChange`, a motore in moto (il Follower muto: l'arresto locale) e a motore fermo (il Direttore muto dopo una crisi). Senza la
/// regola restava.
func testTheRoleChangeLiftsTheSilenceInForceInMotionAndAtEngineStopped() {
    for rule in [true, false] {
        var moving = playing(.follower, route: [headphones], at: 10.0)
        moving.useSilenceWriterMemory = rule
        moving.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(moving.isRunning, "regola:\(rule)")
        XCTAssertTrue(moving.state.muted, "regola:\(rule)")
        XCTAssertEqual(moving.lastSilenceWrite?.reason, "percorso-tolta", "regola:\(rule)")
        moving.roleChange(to: .solo, at: 13.0)
        XCTAssertFalse(moving.isRunning, "regola:\(rule): l'arresto locale col volume a 0")
        XCTAssertFalse(moving.state.muted, "regola:\(rule): il cambio di ruolo")
        XCTAssertEqual(moving.volume, 0.0, "regola:\(rule): il cambio di ruolo non scrive il volume")
        if rule {
            XCTAssertNil(moving.lastSilenceWrite, "a motore in moto: il ricordo se ne va")
        } else {
            XCTAssertEqual(moving.lastSilenceWrite?.reason, "percorso-tolta", "senza la regola il ricordo restava")
        }
        var stopped = playing(.direttore, route: [speaker], at: 10.0)
        stopped.useSilenceWriterMemory = rule
        stopped.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        XCTAssertFalse(stopped.isRunning, "regola:\(rule)")
        XCTAssertTrue(stopped.state.muted, "regola:\(rule)")
        stopped.roleChange(to: .solo, at: 20.05)
        XCTAssertFalse(stopped.state.muted, "regola:\(rule): il cambio di ruolo")
        XCTAssertEqual(stopped.volume, 0.0, "regola:\(rule)")
        if rule {
            XCTAssertNil(stopped.lastSilenceWrite, "a motore fermo: il ricordo se ne va")
        } else {
            XCTAssertEqual(stopped.lastSilenceWrite?.reason, "buco-del-render", "senza la regola il ricordo restava")
        }
    }
}

// MARK: - A425 (mandato «USCITA AUDIO PASSO 2a PEZZO 3a», par. 2.4 e 2.5): il rig più vicino al motore, U16 e il fuoco del rientro

/// La soglia di Link nel rig (par. 2.5): una correzione di al più 0,01 battiti fa il ramo «nessuna correzione» del motore — non
/// sposta, non si conta, consuma il segno della prima correzione dopo la finestra; sopra la soglia si applica; proprio sulla soglia no
/// (il confronto del motore è «maggiore di»). Nella scorta, a zero correzioni, una correzione sotto la soglia non è la prima della
/// scorta e quella dopo si applica. Col rig di prima (interruttore spento) ogni correzione si applicava.
func testTheLinkThresholdInTheRigLikeTheEngine() throws {
    for threshold in [true, false] {
        let tag = "soglia:\(threshold)"
        var rig = playing(.follower, route: [speaker], at: 10.0)
        rig.useEngineSyncThreshold = threshold
        rig.sectionChange(at: rig.now + 0.001)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 100)
        XCTAssertTrue(rig.windowOpen, "\(tag): la finestra dei 100 buffer")
        let positionBefore = rig.position
        let correctionsBefore = rig.corrections
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: 0.005)
        XCTAssertFalse(rig.windowOpen, tag)
        XCTAssertFalse(rig.firstCorrectionPending, "\(tag): il segno della prima correzione si consuma")
        XCTAssertEqual(rig.firstCorrectionRearms, 0, tag)
        XCTAssertEqual(rig.corrections, correctionsBefore + (threshold ? 0 : 1), tag)
        XCTAssertEqual(rig.correctionsUnderThreshold, threshold ? 1 : 0, tag)
        XCTAssertEqual(rig.position, positionBefore + (threshold ? 0 : 0.005) + rig.bufferBeats, accuracy: 1e-9, tag)
        let positionAbove = rig.position
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: 0.02)
        XCTAssertEqual(rig.corrections, correctionsBefore + (threshold ? 1 : 2), "\(tag): sopra la soglia si applica")
        XCTAssertEqual(rig.position, positionAbove + 0.02 + rig.bufferBeats, accuracy: 1e-9, tag)
        let positionAt = rig.position
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: OutputRig.phaseJumpThresholdBeats)
        XCTAssertEqual(rig.position, positionAt + (threshold ? 0 : OutputRig.phaseJumpThresholdBeats) + rig.bufferBeats,
                       accuracy: 1e-9, "\(tag): proprio sulla soglia")
        // Nella scorta.
        var lead = try rejoined()
        lead.useEngineSyncThreshold = threshold
        lead.callbacks(from: lead.now + lead.bufferSeconds, count: 1, correction: 0.005)
        XCTAssertEqual(try XCTUnwrap(lead.rejoinLeadIn, "\(tag): ancora nella scorta").corrections, threshold ? 0 : 1, tag)
        let leadBefore = lead.position
        lead.callbacks(from: lead.now + lead.bufferSeconds, count: 1, correction: -0.02)
        XCTAssertEqual(lead.position, leadBefore + (threshold ? -0.02 : 0) + lead.bufferBeats, accuracy: 1e-9,
                       threshold ? "la prima correzione della scorta si applica" : "il rig di prima: la seconda della scorta no")
    }
}

/// B.2 del seguito 4: il battito zero del Play sta nel primo buffer, come il DSP (il rig di prima non lo contava); la sua ora d'uscita
/// resta una latenza dopo il Play (`firstBeatOutAt`): una crisi in canzone prima che esca non trova l'àncora, una dopo sì.
func testThePlayBeatZeroIsInTheFirstBufferLikeTheDSP() {
    for beatZero in [true, false] {
        let tag = "regola:\(beatZero)"
        var rig = OutputRig(role: .direttore, route: [speaker])
        rig.useEngineBeatZero = beatZero
        rig.runnerPlay(at: 10.0)
        XCTAssertEqual(rig.clickSamplesWritten, beatZero ? 1 : 0, "\(tag): i tre buffer del Play")
        XCTAssertFalse(rig.countedBeatOut, "\(tag): il battito zero esce a firstBeatOutAt, non alza countedBeatOut")
        rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
        XCTAssertEqual(rig.clickSamplesWritten, beatZero ? 2 : 1, "\(tag): il battito 1, a 0,496 s")
        XCTAssertTrue(rig.countedBeatOut, tag)
    }
    var early = OutputRig(role: .direttore, route: [headphones])
    early.runnerPlay(at: 10.0)
    early.routeChange(at: 10.005, to: [speaker])
    XCTAssertTrue(early.silentInSong)
    XCTAssertFalse(early.anchor, "il battito zero non e' ancora uscito: nessuna àncora")
    early.start(at: 11.0, recovery: nil)
    XCTAssertEqual(early.uncertainRejoins, 1, "senza àncora il conto non e' certo")
    var late = OutputRig(role: .direttore, route: [headphones])
    late.runnerPlay(at: 10.0)
    late.callbacks(from: 10.0 + late.bufferSeconds, count: 3)
    late.routeChange(at: late.now + 0.001, to: [speaker])
    XCTAssertTrue(late.silentInSong)
    XCTAssertTrue(late.anchor, "il battito zero e' uscito: l'àncora")
}

/// B.10 del seguito 4: la Reset dei servizi audio senza la Lost col Solo in moto lo ferma come allo Stop della console (`stopsSolo`),
/// «canzone in corso» giù e la causa «reset-senza-lost»; niente lo fa ripartire da solo (il risveglio, un'aggiunta, un'interruzione e la
/// sua fine), riparte col Play dopo la ricostruzione. Il Direttore in canzone resta muto; il Follower come oggi.
func testTheResetWithoutLostStopsTheSoloAndNothingRestartsItByItself() {
    var solo = playing(.solo, route: [speaker], at: 10.0)
    XCTAssertTrue(solo.songInProgress)
    solo.mediaResetWithoutLost(at: 12.0)
    XCTAssertEqual(solo.soloStops, 1, "come allo Stop della console")
    XCTAssertFalse(solo.isRunning)
    XCTAssertFalse(solo.songInProgress, "stopSync(.soloCrisis) la abbassa")
    XCTAssertEqual(solo.crisisCause, .resetWithoutLost)
    XCTAssertTrue(CrisisCause.resetWithoutLost.stopsSolo)
    solo.wakeup(at: 13.0)
    solo.routeChange(at: 14.0, to: [headphones])
    solo.interruptionBegan(at: 15.0)
    solo.interruptionEnded(at: 16.0)
    solo.advance(to: 20.0)
    XCTAssertFalse(solo.isRunning, "nessuna ripartenza da sola")
    XCTAssertEqual(solo.starts, 1)
    XCTAssertEqual(solo.soloStops, 1)
    solo.rebuiltAndPlay(at: 21.0)
    XCTAssertTrue(solo.isRunning, "riparte col Play, dopo la ricostruzione")
    XCTAssertNil(solo.crisisCause, "il Play azzera la causa")
    var director = playing(.direttore, route: [speaker], at: 10.0)
    director.mediaResetWithoutLost(at: 12.0)
    XCTAssertTrue(director.silentInSong, "il Direttore in canzone resta muto")
    XCTAssertFalse(director.isRunning)
    XCTAssertTrue(director.anchor)
    var follower = playing(.follower, route: [speaker], at: 10.0)
    follower.mediaResetWithoutLost(at: 12.0)
    XCTAssertTrue(follower.isRunning, "il Follower come oggi")
}

/// U16 (P14): il Direttore fuori da una canzone fermato da una tolta, con una ripresa pendente lasciata dall'hardware occupato: alle
/// cuffie che tornano la ripresa si recupera e `RecoveryDecision` dice «niente» («direttore-fermo-dalla-tolta»); il Play lo fa
/// ripartire. La ripresa pendente si mette con la strada del rig per l'uscita mancante e l'hardware occupato (`noteNoRestart`, come
/// `noteNoRestartQ`), con un tentativo chiamato a mano: nel motore, dopo l'arresto locale della tolta, nessuna strada automatica arriva
/// a quel tentativo da sola (referto A425, Aperto). Prima di A425 il click ripartiva da solo all'aggiunta.
func testU16TheDirectorStoppedByARemovalOutOfASongWaitsForThePlay() {
    var rig = playing(.direttore, route: [headphones], at: 10.0)
    rig.songInProgress = false
    rig.routeChange(at: 11.0, to: [speaker])
    XCTAssertFalse(rig.isRunning, "U16: l'arresto locale")
    XCTAssertEqual(rig.crisisCause, .outputRemoved)
    XCTAssertTrue(rig.state.missing)
    rig.hardwareBusy = true
    rig.activateSessionAndStart(trigger: .appWakeup, at: 11.5)
    XCTAssertTrue(rig.pendingResume, "la ripresa pendente lasciata dall'hardware occupato")
    XCTAssertFalse(rig.isRunning)
    rig.hardwareBusy = false
    rig.routeChange(at: 12.0, to: [headphones])
    XCTAssertFalse(rig.state.missing)
    XCTAssertFalse(rig.pendingResume, "la ripresa recuperata dal cambio di percorso")
    XCTAssertFalse(rig.isRunning, "nessun avvio: direttore-fermo-dalla-tolta")
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(RecoveryDecision.noRestartReason(trigger: .pendingRecovery, playerRole: .direttore, silentInSong: rig.silentInSong,
                                                    wantedStopSinceCrisis: rig.wantedStop, crisisCause: rig.crisisCause,
                                                    outputMissing: rig.state.missing),
                   .directorStoppedByRemoval)
    rig.wakeup(at: 13.0)
    rig.advance(to: 15.0)
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.starts, 1)
    rig.start(at: 16.0, recovery: nil)
    XCTAssertTrue(rig.isRunning, "riparte col Play")
    XCTAssertNil(rig.crisisCause, "il Play azzera la causa")
}

/// P14 e la sequenza di VR2 punto 3 d: una tolta in canzone, il Direttore muto, il Play che rientra; al fuoco del rientro la causa
/// ricordata e lo Stop voluto si azzerano. Poi la canzone finisce, il pedale fa ripartire il click fuori da una canzone, un'aggiunta,
/// una tolta, l'hardware occupato e un'aggiunta: U16 decide sulla causa nuova (la seconda tolta): niente. Senza l'azzeramento al fuoco
/// la causa del rientro restava «uscita-tolta».
func testTheRejoinFireClearsTheMemoryAndU16DecidesOnTheNewCause() throws {
    for clears in [true, false] {
        let tag = "regola:\(clears)"
        var rig = playing(.direttore, route: [headphones], at: 10.0)
        rig.useRejoinFireClearsMemory = clears
        rig.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(rig.silentInSong, tag)
        XCTAssertEqual(rig.crisisCause, .outputRemoved, tag)
        rig.start(at: 13.0, recovery: nil)
        XCTAssertEqual(rig.crisisCause, .outputRemoved, "\(tag): il Play del Direttore muto passa dal coordinatore, non da prepareNormalStartQ")
        let fireAt = try XCTUnwrap(rig.rejoin, "\(tag): il rientro armato").fireAt
        // A425 (nota 1 del verificatore V3): nel rig un fuoco con lo Stop voluto alto non si raggiunge (lo alzano `stop`, che chiude il
        // silenzio e toglie il rientro, la fine della canzone e il cambio di ruolo): lo si alza a mano, come la ripresa pendente del
        // test di U16, perché la prova cada anche senza l'altra metà dell'azzeramento al fuoco.
        rig.wantedStop = true
        rig.advance(to: fireAt)
        XCTAssertEqual(rig.rejoins, 1, tag)
        XCTAssertFalse(rig.silentInSong, tag)
        XCTAssertEqual(rig.crisisCause, clears ? nil : .outputRemoved, "\(tag): al fuoco del rientro")
        XCTAssertEqual(rig.wantedStop, !clears, "\(tag): lo Stop voluto al fuoco del rientro")
        XCTAssertEqual(rig.memoryClearedAtRejoinFire, clears ? 1 : 0, tag)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 100)
        rig.songEnd(at: rig.now + 0.01)
        XCTAssertFalse(rig.isRunning, tag)
        rig.pedalPlayPause(at: rig.now + 1.0)
        XCTAssertTrue(rig.isRunning, tag)
        XCTAssertFalse(rig.songInProgress, "\(tag): fuori canzone")
        XCTAssertNil(rig.crisisCause, "\(tag): il Play azzera la causa")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 50)
        rig.routeChange(at: rig.now + 0.01, to: [headphones])
        XCTAssertTrue(rig.isRunning, "\(tag): fuori da una canzone un'aggiunta e' come oggi")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 10)
        rig.routeChange(at: rig.now + 0.01, to: [speaker])
        XCTAssertFalse(rig.isRunning, "\(tag): U16, l'arresto locale")
        XCTAssertEqual(rig.crisisCause, .outputRemoved, "\(tag): la causa nuova")
        rig.hardwareBusy = true
        rig.activateSessionAndStart(trigger: .appWakeup, at: rig.now + 0.1)
        XCTAssertTrue(rig.pendingResume, tag)
        rig.hardwareBusy = false
        let starts = rig.starts
        rig.routeChange(at: rig.now + 0.5, to: [headphones])
        XCTAssertFalse(rig.isRunning, "\(tag): U16 decide sulla causa nuova: niente")
        XCTAssertEqual(rig.starts, starts, tag)
    }
}

// MARK: - A432 · parte 2c: il conto sulla band DA-SOLO in sequenza, e l'ora d'uscita dell'«uno» del rientro

/// Il ritorno del Follower col conto sulla band E l'orologio proprio (DA-SOLO) nella stessa sequenza: i rami DA-SOLO di
/// `nextBandUno(atOrAfter:)` e di `unoTime(for:)` (nel motore `nextBandUnoQ` e `unoTicksQ(for:)`), che i quattro test della parte 2b
/// percorrono solo IN SYNC. La canzone ha la forma di quella della 2b (4/4 per due battute, poi 3/4), a 121: un tempo non tondo
/// (A432 · parte 2d, K8: era a 120, e ogni numero qui sotto è rifatto a 121; le ore degli eventi sono le stesse). L'àncora del
/// conto è il battito 96 della sessione, uscito a 47,633306 s: 30 ms dopo la griglia di Link del rig (96 × 60 ÷ 121 = 47,603306 s),
/// dentro l'ottavo di battito del conto. Gli «uno» del 3/4 sono 104, 107, 110… e sulla mappa cadono a 51,600248 s più 1,487603 s
/// per battuta. La cuffia tolta a 55 s. A 56,9 s il Follower va DA-SOLO: la linea propria nasce sulla griglia di Link di quel
/// momento (battito 114,748333: i suoi click interi cadono 30 ms prima delle ore della mappa) e l'ultimo «uno» della canzone
/// uscito è il 113 (a 56,033058 s); da lì la sessione di Link non è più quella della band: 3,5 battiti avanti. La cuffia rimessa a
/// 58,806 s, la prima chiamata a 59,490 s: la scadenza è 59,595967 s (la fine dei buffer programmati, 59,490 + 0,0233 di latenza +
/// un ciclo e tre buffer da 10,667 ms = 59,555967 s, più la coda di 40 ms).
///  · Col rig come il motore: il posto alla scadenza dal righello dei secondi, (59,595967 − 47,633306) × 121 ÷ 60 = 24,124699
///    battiti dall'àncora, cioè 120,124699 nella numerazione del conto: il primo «uno» della canzone dopo è il 122, con l'orologio
///    del conto. La sua ora sulla mappa è 47,633306 + (122 − 96) × 60 ÷ 121 = 60,525868 s; a quell'ora la linea propria è al battito
///    114,748333 + (60,525868 − 56,9) × 121 ÷ 60 = 122,0605: il click intero più vicino è il 122, che esce a
///    56,9 + (122 − 114,748333) × 60 ÷ 121 = 60,495868 s. Il volume torna lì: tre battute dopo il 113.
///  · Con l'interruttore girato (`useOwnClockForTheBandUno` spento: anche DA-SOLO come IN SYNC): il posto da Link,
///    59,595967 × 121 ÷ 60 + 3,5 = 123,685199: l'«uno» scelto è il 125, e la sua ora è quella di Link,
///    (125 − 3,5) × 60 ÷ 121 = 60,247934 s: sulla linea propria è il battito 121,5, a metà fra due click, e 1,765537 s prima
///    dell'ora della mappa di quell'«uno» (47,633306 + 29 × 60 ÷ 121 = 62,013471 s).
/// I conti sono rifatti a macchina in doppia precisione, con un modello in Python del rig (fuori dal deposito), convalidato prima
/// sui numeri che questo test asseriva a 120.
func testOnItsOwnTheFollowerReturnFromTheCountIsOnADownbeatOfTheSongOnTheOwnLine() throws {
    for ownRuler in [true, false] {
        let tag = "righelloProprio:\(ownRuler)"
        var rig = playing(.follower, route: [headphones], bpm: 121, beatsPerBar: 3, at: 50.0)
        rig.useOwnClockForTheBandUno = ownRuler
        let map = SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 2, bpm: 121),
                                     SongMapSection(beatsPerBar: 3, repetitions: 100, bpm: 121)])
        // Il battito 96 sulla griglia di Link del rig (96 × 60 ÷ 121 s) più 30 ms: 47,633306 s.
        let count = FollowerBandCount(map: map, anchor: ShowClockAnchor(section: 0, beatInSection: 0, linkBeat: 96,
                                                                        ticks: rig.ticks(96 * 60.0 / 121.0 + 0.030)))
        rig.bandCount = count
        rig.routeChange(at: 55.0, to: [speaker])
        rig.callbacks(from: 55.681, count: 30)
        // DA-SOLO. La soglia del rig mette come ultimo «uno» la battuta di Link (114), che dopo il cambio di metro non è un «uno»
        // della canzone: qui si mette quello uscito davvero, il 113. Poi Link passa a un'altra sessione, 3,5 battiti avanti.
        rig.goOwnClock(at: 56.9)
        rig.lastUnoBeat = 113
        rig.linkAnchorBeat = 3.5
        let timeline = try XCTUnwrap(rig.ownTimeline, "\(tag): la linea propria")
        XCTAssertEqual(timeline.anchorBeat, 114.748333333, accuracy: 1e-9, tag)
        rig.routeChange(at: 58.806, to: [headphones])
        XCTAssertTrue(try XCTUnwrap(rig.followerReturn, "\(tag): il ritorno del Follower prenotato").armPending, tag)
        let firstCall = 58.806 + 0.684
        rig.callbacks(from: firstCall, count: 1)
        let armed = try XCTUnwrap(rig.followerReturn, "\(tag): il ritorno armato")
        let uno = try XCTUnwrap(armed.uno, "\(tag): l'«uno» scelto")
        let unoAt = try XCTUnwrap(armed.unoAt, "\(tag): l'ora dell'«uno»")
        let deadline = try XCTUnwrap(rig.deadlineAt, "\(tag): la scadenza")
        XCTAssertEqual(deadline, 59.595967, accuracy: 1e-5, tag)
        XCTAssertEqual(uno.clock, .band, "\(tag): l'«uno» viene dal conto")
        XCTAssertEqual(uno.beatsPerBar, 3, tag)
        XCTAssertEqual((uno.beat - 104).truncatingRemainder(dividingBy: 3), 0, accuracy: 1e-9,
                       "\(tag): un inizio di battuta della canzone, nella numerazione del conto")
        XCTAssertGreaterThanOrEqual(unoAt, deadline - 1e-9, tag)
        XCTAssertLessThan(unoAt, deadline + rig.barSeconds, tag)
        let mapTicks = try XCTUnwrap(FollowerBandUno.mapTicks(count: count, uno: uno, ticksPerSecond: OutputRig.tps),
                                     "\(tag): l'ora dell'«uno» sulla mappa")
        let mapAt = rig.seconds(mapTicks)
        let ownBeatAtUno = timeline.beat(atTicks: rig.ticks(unoAt), ticksPerSecond: OutputRig.tps)
        if ownRuler {
            XCTAssertEqual(uno.beat, 122, accuracy: 1e-9, "il primo «uno» della canzone dopo la scadenza, dal righello dei secondi")
            XCTAssertEqual(mapAt, 60.5258678, accuracy: 1e-6, "la sua ora sulla mappa")
            XCTAssertEqual(ownBeatAtUno, 122, accuracy: 1e-6, "sulla linea propria: un click intero")
            XCTAssertEqual(unoAt, 60.4958678, accuracy: 1e-6, "l'ora della mappa portata sul click più vicino della linea propria")
            XCTAssertEqual(mapAt - unoAt, 0.030, accuracy: 1e-6, "30 ms prima dell'ora della mappa: meno di mezzo battito")
        } else {
            XCTAssertEqual(uno.beat, 125, accuracy: 1e-9, "la rottura: il posto letto da Link, che non è più la sessione della band")
            XCTAssertEqual(unoAt, rig.time(ofBeat: 125), accuracy: 1e-9, "la rottura: l'ora di Link per quel battito")
            XCTAssertEqual(unoAt, 60.2479339, accuracy: 1e-6, "la rottura: (125 − 3,5) × 60 ÷ 121")
            XCTAssertEqual(ownBeatAtUno, 121.5, accuracy: 1e-6, "la rottura: a metà fra due click della linea propria")
            XCTAssertEqual(mapAt - unoAt, 1.7655372, accuracy: 1e-6, "la rottura: 1,765537 s prima dell'ora della mappa di quell'«uno»")
        }
        rig.callbacks(from: firstCall + rig.bufferSeconds, count: 400)
        XCTAssertEqual(rig.volume, 1.0, tag)
        XCTAssertNil(rig.followerReturn, tag)
        XCTAssertEqual(rig.rearms, 0, "\(tag): nessun riarmo: l'«uno» del conto resta del conto anche DA-SOLO")
        XCTAssertEqual(rig.nextBarMoves, 0, tag)
        let restored = try XCTUnwrap(rig.restoredUnoAt, "\(tag): l'«uno» del ritorno")
        XCTAssertEqual(restored, unoAt, accuracy: 1e-6, "\(tag): il volume è tornato sull'«uno» dell'armo")
        // Sulla linea propria: le battute da 3 dall'ultimo «uno» uscito (il 113) al click del ritorno.
        let barsFromLastUno = (timeline.beat(atTicks: rig.ticks(restored), ticksPerSecond: OutputRig.tps) - 113) / 3
        if ownRuler {
            XCTAssertEqual(barsFromLastUno, 3, accuracy: 1e-6, "il volume è tornato su un «uno» della canzone, sulla linea propria")
        } else {
            XCTAssertEqual(abs(barsFromLastUno - barsFromLastUno.rounded()), 1.0 / 6.0, accuracy: 1e-6,
                           "la rottura: il volume torna a mezzo battito da un «uno» della linea propria, fra due click")
        }
        checkReturnInvariants(rig, "il conto DA-SOLO \(tag)")
    }
}

/// L'ora d'uscita dell'«uno» del rientro contato nella scorta (`rejoinUnoOutAt`), come il motore conta l'ora d'uscita di ogni
/// battito: l'ora d'uscita del buffer in cui cade più il suo scostamento nel buffer. Il rientro è quello di `rejoined()`: a 121 BPM
/// il bersaglio è il battito 44, a 44 × 60 ÷ 121 = 21,818182 s; la scorta è di cinque buffer da 10,667 ms, e i buffer della catena
/// escono uno dietro l'altro: quello d'indice 5 esce al bersaglio, quello d'indice b esce (b − 5) buffer dopo.
///  · Senza correzione: l'«uno» al primo campione del buffer d'indice 5: il bersaglio, alla lettera (com'era).
///  · Una prima correzione in avanti di mezzo buffer: l'«uno» al campione 256 del buffer d'indice 4: 21,818182 − 0,010667 +
///    256 ÷ 48000 = 21,812848 s, mezzo buffer prima del bersaglio.
///  · Una prima correzione che scavalca l'«uno» (due buffer e mezzo in avanti): il DSP lo fa uscire al primo campione del buffer
///    di quella chiamata, d'indice 3: 21,818182 − 2 × 0,010667 = 21,796848 s, due buffer prima del bersaglio.
/// Con l'interruttore girato (`useEngineRejoinUnoOutTime` spento) l'ora è sempre il bersaglio, com'era.
/// I conti sono rifatti a macchina in doppia precisione, con un modello in Python del rig (fuori dal deposito).
func testTheRejoinUnoSetAtOnceIsOutAtTheFirstSampleOfItsBuffer() throws {
    for engineOut in [true, false] {
        let tag = "oraDelMotore:\(engineOut)"
        // Senza correzione.
        var plain = try rejoined()
        plain.useEngineRejoinUnoOutTime = engineOut
        let target = try XCTUnwrap(plain.firstClickAt, "\(tag): il bersaglio del rientro")
        let buffers = plain.leadInBuffers
        XCTAssertEqual(target, 44 * 60.0 / 121.0, accuracy: 1e-9, "\(tag): il battito 44")
        XCTAssertEqual(buffers, 5, tag)
        XCTAssertNil(plain.rejoinUnoOutAt, "\(tag): dopo i tre buffer del fuoco l'«uno» non è ancora contato")
        plain.callbacks(from: plain.now + plain.bufferSeconds, count: buffers - 2)
        XCTAssertEqual(plain.leadInUnoBuffer, buffers, tag)
        XCTAssertEqual(try XCTUnwrap(plain.rejoinUnoOutAt, "\(tag): l'«uno» contato"), target,
                       "\(tag): senza correzione l'ora resta il bersaglio, alla lettera")
        // Una prima correzione in avanti di mezzo buffer: l'«uno» a metà del buffer prima.
        var forward = try rejoined()
        forward.useEngineRejoinUnoOutTime = engineOut
        forward.callbacks(from: forward.now + forward.bufferSeconds, count: 1, correction: 0.5 * forward.bufferBeats)
        XCTAssertNil(forward.rejoinUnoOutAt, "\(tag): il buffer d'indice 3 non porta l'«uno»")
        forward.callbacks(from: forward.now + forward.bufferSeconds, count: 1)
        XCTAssertEqual(forward.leadInUnoBuffer, buffers - 1, tag)
        XCTAssertEqual(try XCTUnwrap(forward.rejoinUnoOutAt, "\(tag): l'«uno» contato"),
                       engineOut ? target - 0.5 * forward.bufferSeconds : target, accuracy: 1e-9,
                       engineOut ? "il buffer d'indice 4 più 256 campioni: mezzo buffer prima del bersaglio" : "la rottura: il bersaglio")
        // Una prima correzione che scavalca l'«uno»: esce al primo campione del buffer di quella chiamata, prima del bersaglio.
        var over = try rejoined()
        over.useEngineRejoinUnoOutTime = engineOut
        over.callbacks(from: over.now + over.bufferSeconds, count: 1, correction: 2.5 * over.bufferBeats)
        XCTAssertEqual(over.leadInUnoBuffer, 3, tag)
        let overOut = try XCTUnwrap(over.rejoinUnoOutAt, "\(tag): l'«uno» contato")
        XCTAssertEqual(overOut, engineOut ? target - 2 * over.bufferSeconds : target, accuracy: 1e-9,
                       engineOut ? "il primo campione del buffer d'indice 3: due buffer prima del bersaglio" : "la rottura: il bersaglio")
        XCTAssertEqual(overOut, engineOut ? 21.796848 : 21.818182, accuracy: 1e-5, tag)
        XCTAssertEqual((overOut < target), engineOut, "\(tag): prima del bersaglio solo con l'ora del motore")
    }
}

/// La crisi «muto in canzone» fra l'uscita dell'«uno» scavalcato (21,796848 s) e il bersaglio (21,818182 s): chi legge
/// `rejoinUnoOutAt` è la regola dell'àncora (`crisis`, come `takeSilenceAnchorQ`: un battito contato già uscito).
///  · Senza l'àncora tenuta dal rientro (`useHeldAnchor` spento: il fuoco la chiude) `rejoinUnoOutAt` decide da solo: con l'ora
///    del motore l'«uno» è già uscito e l'àncora si prende da lui (il Play dopo rientra); con l'interruttore girato l'ora è il
///    bersaglio, non ancora passato: nessuna àncora, e il Play dopo finisce «non certo».
///  · Con l'àncora tenuta dal rientro (il rig di base, come il motore) in quell'istante l'àncora c'è comunque, con tutte e due le
///    ore: il rig la chiude alla prima chiamata dopo il bersaglio, e la crisi la trova ancora tenuta. Lì l'interruttore non si
///    vede: il test lo dice, perché non si legga questa prova come una prova del rig di base.
///    ⚠️ CORRETTO A432 · parte 2d (K2). «Il rig la chiude alla prima chiamata dopo il bersaglio, e la crisi la trova ancora
///    tenuta» era il rig di prima, e nel motore è falso: `checkAnchorHeldByRejoinQ` chiude l'àncora tenuta alla prima chiamata
///    di `scheduleNextBuffer` con l'ora d'uscita dell'«uno» contato passata, e l'«uno» scavalcato esce due buffer prima del
///    bersaglio. Col rig di base (`useEngineHeldAnchorClose` acceso, l'ora del motore) l'àncora tenuta si chiude al dodicesimo
///    richiamo (21,800215 s, il primo dopo l'uscita dell'«uno»; l'undicesimo, a 21,789548 s, è prima), e la crisi dopo prende
///    l'àncora dall'«uno» già uscito, come senza l'àncora tenuta. L'àncora resta tenuta fino alla crisi, com'era, in due giri:
///    con `useEngineHeldAnchorClose` spento (la chiusura al bersaglio), e con l'ora dell'«uno» girata (`useEngineRejoinUnoOutTime`
///    spento: per il rig l'«uno» esce al bersaglio, che nessuna chiamata ha passato). In tutti i giri con l'àncora tenuta la crisi
///    ha l'àncora e il Play dopo rientra: cambia da dove viene.
/// Il Direttore è in cuffia; il rientro è quello di `rejoined()` (il bersaglio a 21,818182 s, il fuoco a 21,661548 s). La chiamata
/// dello scavalco a 21,672215 s, poi dodici richiami, l'ultimo a 21,800215 s (dopo l'uscita dell'«uno», prima del bersaglio); la
/// cuffia tolta a 21,807515 s, a metà fra le due ore. Il battito dopo l'«uno» viene 0,496 s dopo: non è ancora programmato.
func testACrisisBetweenTheUnoSetAtOnceAndTheTargetTakesTheAnchorFromTheUnoWhenTheRejoinDoesNotHoldIt() throws {
    for held in [true, false] {
        for engineOut in [true, false] {
            for engineClose in [true, false] {
                let tag = "tenuta:\(held) oraDelMotore:\(engineOut) chiusuraDelMotore:\(engineClose)"
                var rig = playing(.direttore, route: [headphones], at: 10.0)
                rig.useHeldAnchor = held
                rig.useEngineRejoinUnoOutTime = engineOut
                rig.useEngineHeldAnchorClose = engineClose
                rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
                XCTAssertTrue(rig.silentInSong, tag)
                rig.advance(to: 20.1)
                let fireAt = try XCTUnwrap(rig.rejoin, "\(tag): il rientro armato").fireAt
                rig.advance(to: fireAt)
                XCTAssertEqual(rig.rejoins, 1, tag)
                XCTAssertEqual(rig.anchor, held, "\(tag): dopo il fuoco l'àncora resta viva solo tenuta dal rientro")
                let target = try XCTUnwrap(rig.firstClickAt, "\(tag): il bersaglio del rientro")
                XCTAssertEqual(target, 44 * 60.0 / 121.0, accuracy: 1e-9, tag)
                rig.callbacks(from: fireAt + rig.bufferSeconds, count: 1, correction: 2.5 * rig.bufferBeats)
                XCTAssertEqual(rig.leadInUnoBuffer, 3, tag)
                let unoOut = target - 2 * rig.bufferSeconds
                XCTAssertEqual(try XCTUnwrap(rig.rejoinUnoOutAt, "\(tag): l'«uno» contato"), engineOut ? unoOut : target,
                               accuracy: 1e-9, tag)
                XCTAssertEqual(rig.anchorHeld, held, "\(tag): la chiamata dello scavalco è prima dell'uscita dell'«uno»: ancora tenuta")
                rig.callbacks(from: rig.now + rig.bufferSeconds, count: 12)
                XCTAssertGreaterThanOrEqual(rig.now, unoOut, "\(tag): l'ultimo richiamo dopo l'uscita dell'«uno»")
                XCTAssertLessThan(rig.now, target, "\(tag): l'ultimo richiamo prima del bersaglio")
                XCTAssertFalse(rig.countedBeatOut, "\(tag): il battito dopo l'«uno» non è ancora programmato")
                // K2: come il motore, l'àncora tenuta si chiude alla prima chiamata dopo l'uscita vera dell'«uno» contato. Qui solo
                // con l'àncora tenuta, l'ora del motore e la chiusura del motore; negli altri giri con l'àncora tenuta nessuna
                // chiamata ha passato l'ora a cui il rig la chiude (il bersaglio), e resta tenuta.
                let closedAtTheUno = held && engineOut && engineClose
                XCTAssertEqual(rig.anchor, held && !closedAtTheUno,
                               closedAtTheUno ? "\(tag): l'«uno» scavalcato è uscito: la chiamata dopo ha chiuso l'àncora tenuta, prima del bersaglio"
                                              : "\(tag): nessuna chiamata dopo l'ora di chiusura: l'àncora tenuta non si è chiusa")
                XCTAssertEqual(rig.anchorHeld, held && !closedAtTheUno, "\(tag): il segno «tenuta» va con l'àncora")
                if closedAtTheUno {
                    let closedAt = try XCTUnwrap(rig.anchorClosedAt, "\(tag): l'ora della chiusura dell'àncora tenuta")
                    XCTAssertEqual(closedAt, rig.now, accuracy: 1e-9, "\(tag): chiusa dal dodicesimo richiamo, il primo dopo l'uscita dell'«uno»")
                    XCTAssertGreaterThanOrEqual(closedAt, unoOut, "\(tag): non prima dell'uscita dell'«uno»")
                    XCTAssertLessThan(closedAt, unoOut + rig.bufferSeconds, "\(tag): alla prima chiamata dopo: entro un buffer")
                    XCTAssertLessThan(closedAt, target, "\(tag): prima del bersaglio")
                } else if held {
                    XCTAssertNil(rig.anchorClosedAt, "\(tag): l'àncora tenuta non si è mai chiusa")
                }
                let crisisAt = (unoOut + target) / 2
                XCTAssertGreaterThan(crisisAt, rig.now, tag)
                rig.routeChange(at: crisisAt, to: [speaker])
                XCTAssertTrue(rig.silentInSong, tag)
                XCTAssertFalse(rig.isRunning, tag)
                XCTAssertFalse(rig.anchorHeld, "\(tag): dopo la crisi l'àncora è del silenzio")
                let anchorMessage: String
                if held {
                    anchorMessage = closedAtTheUno
                        ? "\(tag): l'àncora tenuta è già chiusa: la crisi la prende dall'«uno» già uscito, come il motore"
                        : "\(tag): la crisi trova l'àncora ancora tenuta dal rientro"
                } else {
                    anchorMessage = engineOut
                        ? "l'«uno» è già uscito: l'àncora si prende da lui"
                        : "la rottura: per il rig l'«uno» esce al bersaglio, nessuna àncora"
                }
                XCTAssertEqual(rig.anchor, held || engineOut, anchorMessage)
                rig.start(at: crisisAt + 1.0, recovery: nil)
                rig.advance(to: crisisAt + 5.0)
                XCTAssertEqual(rig.uncertainRejoins, (held || engineOut) ? 0 : 1, tag)
                XCTAssertEqual(rig.rejoins, (held || engineOut) ? 2 : 1, tag)
            }
        }
    }
}

// MARK: - A437 (mandato A437, par. 3; seguito 1, par. 1 e 2): la ripresa del Solo sulla posizione della canzone
//
// Le canzoni sono quelle della scaletta di prova «COLLAUDO 3B»: «1 Two sections» (4/4 a 121,5 per 16 battute, poi 4/4 a 91,5
// per 16) e «3 Short» (4/4 a 131,5 per 4). Il Play è a 10,0 s: il primo battito esce una latenza dopo (10,0233 s), e da lì
// la griglia della canzone. L'atteso di ogni ripresa è il primo «uno» di battuta con l'ora non prima della decisione più il
// margine, calcolato qui a mano dalla mappa (`soloBar`), non dal tipo. Ogni sequenza della pausa guarda l'invariante del
// seguito 1, voce 2 («nessuna pausa senza una strada in volo») e che lo stato della ripresa esista (`checkSolo`).
// Le stesse sequenze, con le rotture volute, girano nel modello Python del mandato (prove_rig.py).

private var soloTwoSections: SongMap {
    SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 16, bpm: 121.5),
                       SongMapSection(beatsPerBar: 4, repetitions: 16, bpm: 91.5)])
}

private var soloShort: SongMap {
    SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 4, bpm: 131.5)])
}

/// Il primo «uno» della canzone con l'ora non prima di `t`, a mano dalla mappa: l'ora, la sezione (da 0), la battuta (da 1).
private func soloBar(_ map: SongMap, atOrAfter t: Double) -> (at: Double, section: Int, bar: Int)? {
    var at = 10.0 + 0.0233
    for (index, section) in map.sections.enumerated() {
        let barSeconds = Double(section.beatsPerBar) * 60.0 / section.bpm
        var bar = 1
        while bar <= section.repetitions {
            if at >= t - 1e-9 { return (at, index, bar) }
            at += barSeconds
            bar += 1
        }
    }
    return nil
}

private func checkSolo(_ rig: OutputRig, _ tag: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(rig.soloPauseInvariantHolds, "pausa senza una strada in volo: \(tag)", file: file, line: line)
    XCTAssertNotNil(rig.soloResumeState, "uno stato della ripresa che non esiste: \(tag)", file: file, line: line)
}

/// Il Solo in canzone col click in moto: la mappa, il Play a 10,0 s, cinquanta richiami (e le letture di Δ a regime).
private func soloInSong(_ map: SongMap? = nil, route: [OutputPort]? = nil, delta: Double = 0.0213) -> OutputRig {
    var rig = OutputRig(role: .solo, route: route ?? [speaker])
    rig.soloMap = map ?? soloTwoSections
    rig.soloDeltaSeconds = delta
    rig.runnerPlay(at: 10.0)
    rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
    return rig
}

/// A437 · PARTE 2 — il Solo in canzone col guardiano acceso e i richiami che continuano fino a poco prima di `until` (col
/// guardiano acceso i richiami non possono fermarsi: quattro buffer dopo l'ultimo il guardiano scatta, come nel motore).
private func soloInSongUnderGuardian(route: [OutputPort]? = nil, until: Double = 13.0) -> OutputRig {
    var rig = OutputRig(role: .solo, route: route ?? [speaker])
    rig.soloMap = soloTwoSections
    rig.soloDeltaSeconds = 0.0213
    rig.useGuardian = true
    rig.runnerPlay(at: 10.0)
    let count = Int(((until - 10.0) / rig.bufferSeconds).rounded(.down)) - 1
    rig.callbacks(from: 10.0 + rig.bufferSeconds, count: count)
    return rig
}

/// La pausa più lunga: la cassa Bluetooth a 44,1 kHz a canzone in corso, il ritorno che aspetta la configurazione.
private func soloPausedByBluetooth() -> OutputRig {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [bluetooth], rateChanges: true)
    rig.advance(to: 13.5)
    return rig
}

/// C6 — le cuffie col filo attaccate a canzone in corso: il silenzio subito, la crisi «uscita-aggiunta», l'àncora, l'arresto, il
/// ritorno del Solo dopo l'assestamento; la ripartenza muta e il primo click sull'«uno» della battuta giusta. Nella pausa il motore
/// è fermo, `isPlaying` è falso e la faccia della console resta Stop. E il margine: una decisione che cade 74 ms prima di un «uno»
/// non lo sceglie.
func testTheSoloWithWiredHeadphonesAddedInSongComesBackOnTheRightBar() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [headphones])
    checkSolo(rig, "dopo la notizia")
    XCTAssertEqual(rig.volume, 0.0, "il silenzio subito")
    XCTAssertFalse(rig.isRunning)
    XCTAssertFalse(rig.isPlaying, "isPlaying resta lo specchio del motore")
    XCTAssertTrue(rig.soloResumePending)
    XCTAssertTrue(rig.soloConsoleShowsStop, "nella pausa la faccia resta Stop")
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.soloResumeState, .waiting)
    XCTAssertEqual(rig.directorReturn?.wait, .settle)
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    XCTAssertFalse(rig.playbackStopped, "lo schermo resta quello del player")
    XCTAssertEqual(rig.setActiveAttempts, 0)
    rig.advance(to: 13.05)
    XCTAssertEqual(rig.starts, 1, "prima dell'assestamento niente riparte")
    rig.advance(to: 13.2)
    checkSolo(rig, "nella scorta")
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(rig.setActiveAttempts, 1)
    XCTAssertEqual(rig.soloResumeState, .armed)
    XCTAssertEqual(rig.volume, 1.0, "il volume dell'avvio dallo scrittore unico")
    XCTAssertTrue(rig.isPlaying)
    XCTAssertTrue(rig.soloResumePending, "nella scorta il segno è ancora alto")
    XCTAssertEqual(rig.soloResumes, 0)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + rig.margin))
    XCTAssertEqual(want.section, 0)
    XCTAssertEqual(want.bar, 3)
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.soloResumes, 1)
    XCTAssertFalse(rig.soloResumePending, "al fuoco riuscito il segno scende")
    XCTAssertEqual(rig.soloResumeState, .held)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6, "il primo click sull'uno della battuta 3")
    let aim = try XCTUnwrap(rig.soloFirstAim)
    XCTAssertEqual(aim.section, 0)
    XCTAssertEqual(aim.bar, 3)
    XCTAssertEqual(aim.unoBeat, 8)
    XCTAssertEqual(rig.runnerRejoins, [0])
    XCTAssertNil(rig.crisisCause)
    XCTAssertFalse(rig.wantedStop)
    XCTAssertEqual(rig.soloLastDelta?.fromHardware, true, "lettura:hardware")
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 8)
    XCTAssertEqual(rig.soloResumeState, .idle, "l'àncora tenuta si chiude al primo battito uscito")
    XCTAssertEqual(rig.soloClosures, ["ripresa"])
    XCTAssertEqual(rig.soloStops, 0)
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.soloE3, [])
    XCTAssertTrue(rig.songInProgress)
    XCTAssertEqual(rig.state.lastOutputExternal, true)
    // Il margine: la decisione a 13,9 s cade 74 ms prima dell'«uno» della battuta 3, che non è più raggiungibile: la 4.
    var close = soloInSong()
    close.routeChange(at: 13.8, to: [headphones])
    let next = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.9 + close.margin))
    XCTAssertEqual(next.bar, 4)
    close.advance(to: next.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(close.soloFirstClickAt), next.at, accuracy: 1e-6)
    XCTAssertEqual(close.soloLateFires, 0, "nessun fuoco in ritardo: il margine ha scelto la battuta giusta")
}

/// C7 — la cassa Bluetooth a 44,1 kHz: il ritorno aspetta la configurazione (l'assestamento non basta), il ramo della frequenza
/// a motore fermo ricollega soltanto; la notifica di configurazione fa scattare il ritorno. Senza la notifica, la riserva a 2 s.
func testTheSoloWithABluetoothSpeakerWaitsTheConfigurationThenComesBack() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [bluetooth], rateChanges: true)
    checkSolo(rig, "dopo la notizia")
    XCTAssertEqual(rig.directorReturn?.wait, .configuration)
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(rig.copyRate, 44_100, "il ramo della frequenza a motore fermo ricollega soltanto")
    rig.advance(to: 13.2)
    XCTAssertEqual(rig.starts, 1, "l'assestamento non basta: aspetta la configurazione")
    checkSolo(rig, "in attesa della configurazione")
    rig.configurationNotification(at: 13.25)
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(rig.soloResumeState, .armed)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.25 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    var late = soloInSong()
    late.routeChange(at: 13.0, to: [bluetooth], rateChanges: true)
    late.advance(to: 14.9)
    XCTAssertEqual(late.starts, 1)
    checkSolo(late, "prima della riserva")
    late.advance(to: 15.05)
    XCTAssertEqual(late.starts, 2, "la riserva a 2 s")
    let wantLate = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 15.0 + late.margin))
    late.advance(to: wantLate.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(late.soloFirstClickAt), wantLate.at, accuracy: 1e-6)
}

/// C8 — la scheda USB (l'aggiunta e il cambio di modo nella stessa notizia): la strada unica (P23). La crisi dell'aggiunta ferma
/// e arma il ritorno; il ramo del modo trova l'àncora già viva, non riparte, e il ritorno armato prima resta.
func testTheSoloWithAUSBCardTheModeBranchFindsTheAnchorAliveAndDoesNotRestart() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [usb], modeChanges: true)
    checkSolo(rig, "dopo la notizia")
    XCTAssertEqual(rig.soloAnchorsTaken, 1, "il ramo del modo trova l'àncora già viva")
    XCTAssertEqual(rig.starts, 1, "nessuna ripartenza dal ramo del modo")
    XCTAssertEqual(rig.directorReturn?.kind, .solo, "il ritorno armato prima resta")
    XCTAssertEqual(rig.setActiveAttempts, 0)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloResumes, 1)
}

/// C9 — una ripartenza senza un'uscita nuova: la configurazione del motore a canzone in corso. L'àncora, l'arresto, e il
/// pre-controllo che conta di nuovo a ogni tentativo della `setActive`: la battuta 3 passa durante i tentativi, si torna sulla 4.
func testTheSoloWithAConfigurationChangeInSongComesBackAndThePreCheckCountsAtEveryAttempt() throws {
    var rig = soloInSong()
    rig.setActiveFailures = 2
    rig.systemStopsEngine(at: 13.0)
    rig.configurationNotification(at: 13.1)
    checkSolo(rig, "dopo la configurazione")
    XCTAssertTrue(rig.soloResumePending)
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.crisisCause, .configuration)
    XCTAssertEqual(rig.setActiveAttempts, 1)
    XCTAssertEqual(rig.soloPreChecks, 1)
    XCTAssertEqual(rig.starts, 1)
    rig.advance(to: 13.7)
    checkSolo(rig, "fra i tentativi")
    XCTAssertEqual(rig.setActiveAttempts, 2)
    XCTAssertEqual(rig.soloPreChecks, 2)
    rig.advance(to: 14.2)
    XCTAssertEqual(rig.setActiveAttempts, 3)
    XCTAssertEqual(rig.soloPreChecks, 3)
    XCTAssertEqual(rig.starts, 2)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 14.1 + rig.margin))
    XCTAssertEqual(want.bar, 4, "la battuta 3 è passata durante i tentativi: si torna sulla 4")
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloStops, 0)
}

/// C9 — il motore fermato dal sistema senza nessuna notifica: la rete a 2 s riparte e la ripresa torna sulla canzone.
func testTheSoloWithTheEngineStoppedBySystemComesBackFromTheNet() throws {
    var rig = soloInSong()
    rig.systemStopsEngine(at: 13.0)
    rig.callbacks(from: 13.0 + rig.bufferSeconds, count: 2)
    XCTAssertEqual(rig.stoppedCallbacks, 2)
    rig.advance(to: 15.1)
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.0 + rig.bufferSeconds + 2.0 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    checkSolo(rig, "dopo il fuoco")
}

/// C6 — vicino alla fine di una sezione il primo «uno» utile è l'inizio della sezione dopo; a cavallo del confine e del cambio
/// di tempo (121,5 -> 91,5) è la seconda battuta del Chorus, al tempo nuovo. Il runner va sulla sezione d'arrivo.
func testNearTheEndOfASectionAndAcrossTheTempoChangeTheTargetIsInTheNextSection() throws {
    var rig = soloInSong()
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: Int(30.4 / rig.bufferSeconds))
    rig.routeChange(at: 41.0, to: [headphones])
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 41.1 + rig.margin))
    XCTAssertEqual(want.section, 1)
    XCTAssertEqual(want.bar, 1, "il primo uno utile è l'inizio del Chorus")
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.runnerRejoins, [1])
    XCTAssertEqual(rig.soloFirstAim?.unoBeat, 64)
    var across = soloInSong()
    across.callbacks(from: across.now + across.bufferSeconds, count: Int(30.9 / across.bufferSeconds))
    across.routeChange(at: 41.5, to: [headphones])
    let second = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 41.6 + across.margin))
    XCTAssertEqual(second.section, 1)
    XCTAssertEqual(second.bar, 2, "a cavallo del confine: la seconda battuta del Chorus, al tempo nuovo")
    across.advance(to: second.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(across.soloFirstClickAt), second.at, accuracy: 1e-6)
    XCTAssertEqual(across.runnerRejoins, [1])
    XCTAssertEqual(across.soloFirstAim?.unoBeat, 68)
}

/// C21 — «canzone finita» (E3). In «3 Short» l'ultimo «uno» (la battuta 4) esce a 15,4986 s. Al primo pre-controllo è ancora
/// raggiungibile; al tentativo dopo la canzone finisce prima: il runner arma la successiva una volta, nessun avvio, la sessione
/// non si tocca, niente riparte dopo. E con E3 già al primo pre-controllo: nessuna scrittura della sessione.
func testTheSongThatEndsBeforeTheFirstUsefulBarArmsTheNextOneAndNothingStarts() {
    var rig = soloInSong(soloShort)
    rig.setActiveFailures = 5
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: Int(4.6 / rig.bufferSeconds))
    rig.routeChange(at: 15.2, to: [headphones])
    rig.advance(to: 15.35)
    XCTAssertEqual(rig.setActiveAttempts, 1, "al primo pre-controllo la battuta 4 è ancora raggiungibile")
    XCTAssertEqual(rig.soloE3, [])
    checkSolo(rig, "fra i tentativi")
    rig.advance(to: 15.9)
    XCTAssertEqual(rig.soloE3, ["pre-controllo"], "al tentativo dopo la canzone finisce prima")
    XCTAssertEqual(rig.setActiveAttempts, 1, "E3: la sessione non si tocca")
    XCTAssertEqual(rig.runnerArmNext, 1)
    XCTAssertEqual(rig.starts, 1)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertFalse(rig.songInProgress)
    XCTAssertEqual(rig.soloResumeState, .idle)
    XCTAssertEqual(rig.drainDelivered, 0, "nessuna chiusura di fine sezione consegnata da qui")
    XCTAssertEqual(rig.soloStops, 0)
    rig.wakeup(at: 17.0)
    rig.routeChange(at: 18.0, to: [speaker])
    rig.advance(to: 25.0)
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(rig.runnerArmNext, 1, "una sola azione al runner")
    var direct = soloInSong(soloShort)
    direct.callbacks(from: direct.now + direct.bufferSeconds, count: Int(4.85 / direct.bufferSeconds))
    direct.routeChange(at: 15.45, to: [headphones])
    let writes = direct.sessionWrites
    direct.advance(to: 15.6)
    XCTAssertEqual(direct.soloE3, ["pre-controllo"])
    XCTAssertEqual(direct.sessionWrites, writes, "nessuna scrittura della sessione")
    XCTAssertEqual(direct.setActiveAttempts, 0)
    XCTAssertEqual(direct.runnerArmNext, 1)
    XCTAssertEqual(direct.starts, 1)
}

/// C21 e seguito 1, voce 6 — col drenaggio aperto la canzone finisce come finita suonando: l'arresto consegna la chiusura una
/// volta, nessuna àncora, nessuna ripresa, nessuna E3. Anche con un'àncora ancora viva (tenuta dalla ripresa): si chiude lei.
/// E a motore fermo senza una ripresa in attesa una crisi che non ferma il Solo resta «come oggi».
func testWithTheDrainOpenTheSongEndsAsPlayedWithOneDeliveryAndNoResume() throws {
    var rig = soloInSong()
    rig.drainPending = true
    rig.routeChange(at: 13.0, to: [headphones])
    XCTAssertEqual(rig.drainDelivered, 1)
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertNil(rig.directorReturn)
    XCTAssertEqual(rig.soloE3, [])
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.runnerArmNext, 0)
    XCTAssertFalse(rig.isRunning)
    checkSolo(rig, "dopo il drenaggio")
    rig.routeChange(at: 14.0, to: [headphones, usb], modeChanges: true)
    XCTAssertEqual(rig.soloE2, [], "a motore fermo e senza ripresa in attesa: come oggi")
    XCTAssertEqual(rig.soloStops, 0)
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    XCTAssertEqual(rig.starts, 1)
    var held = soloInSong()
    held.routeChange(at: 13.0, to: [headphones])
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + held.margin))
    held.advance(to: want.at - 0.02)
    XCTAssertEqual(held.soloResumeState, .held)
    held.drainPending = true
    held.systemStopsEngine(at: want.at - 0.015)
    held.configurationNotification(at: want.at - 0.01)
    XCTAssertEqual(held.drainDelivered, 1, "una sola chiusura consegnata")
    XCTAssertEqual(held.soloClosures, ["drenaggio"], "l'àncora viva si chiude")
    XCTAssertEqual(held.soloE3, [], "nessuna E3")
    XCTAssertEqual(held.runnerArmNext, 0)
    XCTAssertFalse(held.soloResumePending)
    XCTAssertNil(held.soloAnchor)
    XCTAssertEqual(held.soloAnchorsTaken, 1)
}

/// C22 — il conto non certo (E2): le cuffie attaccate subito dopo il Play, prima che esca il primo battito contato. Il Solo si
/// ferma come allo Stop della console, niente riparte da solo, il Play riparte.
func testWithNoCountedBeatOutTheSoloStopsAsTheConsoleAndWaitsThePlay() {
    var rig = OutputRig(role: .solo, route: [speaker])
    rig.soloMap = soloTwoSections
    rig.runnerPlay(at: 10.0)
    rig.routeChange(at: 10.01, to: [headphones])
    XCTAssertEqual(rig.soloE2, ["ancora-non-presa(nessun-battito-contato-gia-uscito)"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertTrue(rig.playbackStopped, "«Resume from»")
    XCTAssertTrue(rig.wantedStop, "lo Stop voluto alzato")
    XCTAssertFalse(rig.isRunning)
    XCTAssertNil(rig.directorReturn)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertFalse(rig.soloConsoleShowsStop)
    rig.wakeup(at: 11.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    rig.runnerPlay(at: 21.0)
    XCTAssertTrue(rig.isRunning, "riparte col Play")
    XCTAssertFalse(rig.wantedStop)
}

/// C20 — il tasto e il pedale nella pausa (con la cassa Bluetooth, la pausa più lunga): la faccia resta Stop; un tocco ferma e
/// chiude la ripresa (il contatore della catena sale, il ritorno si annulla), niente riparte da solo. Il pedale Play/Pause fa lo
/// stesso (ferma, non avvia). Un avvio a mano (il debug) chiude la ripresa e parte normale.
func testInThePauseTheKeyStaysStopAndATouchStopsAndClosesTheResume() {
    var rig = soloPausedByBluetooth()
    XCTAssertEqual(rig.soloResumeState, .waiting)
    XCTAssertTrue(rig.soloConsoleShowsStop, "la faccia resta Stop")
    XCTAssertFalse(rig.isPlaying)
    let token = rig.resumeToken
    rig.stop(at: 13.6)
    XCTAssertEqual(rig.resumeToken, token + 1, "la chiusura alza il contatore della catena")
    XCTAssertNil(rig.directorReturn)
    XCTAssertEqual(rig.soloClosures, ["stop"])
    XCTAssertEqual(rig.soloResumeState, .idle)
    XCTAssertFalse(rig.soloConsoleShowsStop)
    XCTAssertTrue(rig.playbackStopped)
    rig.configurationNotification(at: 13.7)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    var manual = soloPausedByBluetooth()
    manual.start(at: 13.6, recovery: nil)
    XCTAssertEqual(manual.soloClosures, ["avvio"])
    XCTAssertFalse(manual.soloResumePending)
    XCTAssertTrue(manual.isRunning)
    XCTAssertEqual(manual.soloResumes, 0)
    XCTAssertEqual(manual.starts, 2)
    XCTAssertNil(manual.soloFire)
    var pedal = soloPausedByBluetooth()
    pedal.pedalPlayPause(at: 13.6)
    XCTAssertEqual(pedal.starts, 1, "il pedale nella pausa ferma, non avvia")
    XCTAssertTrue(pedal.wantedStop)
    XCTAssertEqual(pedal.soloClosures, ["stop"])
    XCTAssertTrue(pedal.playbackStopped)
    pedal.advance(to: 20.0)
    XCTAssertEqual(pedal.starts, 1)
}

/// Seguito 1, voce 3 — la chiusura accodata prima del blocco della `setActive`: lo Stop arriva nella finestra di un giro di
/// coda, il contatore della catena sale e il blocco già accodato muore al suo controllo. Zero attivazioni.
func testAStopQueuedBeforeTheSetActiveKillsTheAttempt() {
    var rig = soloInSong()
    rig.systemStopsEngine(at: 13.0)
    rig.injectStopBeforeSetActive = true
    rig.configurationNotification(at: 13.1)
    XCTAssertEqual(rig.deadChainsAtSetActive, 1, "il blocco già accodato muore al controllo del contatore")
    XCTAssertEqual(rig.setActiveAttempts, 0, "zero attivazioni")
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(rig.soloClosures, ["stop"])
    XCTAssertTrue(rig.wantedStop)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.setActiveAttempts, 0)
    XCTAssertEqual(rig.starts, 1)
}

/// Seguito 1, voce 2 — `setCategory` fallito e hardware occupato con la ripresa in attesa: E2 al posto della ripresa pendente
/// (zero ripresa pendente). Fuori da una canzone resta come oggi: la ripresa pendente si alza.
func testASetCategoryFailureOrABusyHardwareInThePauseStopsAsTheConsole() {
    var rig = soloInSong()
    rig.setCategoryFails = true
    rig.systemStopsEngine(at: 13.0)
    rig.configurationNotification(at: 13.1)
    XCTAssertEqual(rig.soloE2, ["setCategory-fallito"])
    XCTAssertFalse(rig.pendingResume, "zero ripresa pendente")
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertTrue(rig.wantedStop)
    checkSolo(rig, "dopo E2")
    rig.wakeup(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
    var busy = soloInSong()
    busy.hardwareBusy = true
    busy.routeChange(at: 13.0, to: [headphones])
    busy.advance(to: 13.2)
    XCTAssertEqual(busy.soloE2, ["hardware-occupato"])
    XCTAssertFalse(busy.pendingResume)
    XCTAssertEqual(busy.soloStops, 1)
    checkSolo(busy, "dopo E2")
    busy.hardwareBusy = false
    busy.wakeup(at: 14.0)
    busy.advance(to: 20.0)
    XCTAssertEqual(busy.starts, 1)
    var out = soloInSong()
    out.showOpen = false
    out.hardwareBusy = true
    out.systemStopsEngine(at: 13.0)
    out.configurationNotification(at: 13.1)
    XCTAssertTrue(out.pendingResume, "fuori da una canzone come oggi")
    XCTAssertEqual(out.soloE2, [])
    XCTAssertEqual(out.soloStops, 0)
}

/// Seguito 1, voce 1 — `engine.start()` che fallisce con la ripresa in attesa: E2, il Solo si ferma come allo Stop della
/// console e aspetta il Play; niente pausa col tasto su Stop e niente in volo.
func testAnEngineStartThatFailsInThePauseStopsAsTheConsole() {
    var rig = soloInSong()
    rig.engineStartFails = true
    rig.routeChange(at: 13.0, to: [headphones])
    rig.advance(to: 13.2)
    XCTAssertEqual(rig.engineStartFailures, 1)
    XCTAssertEqual(rig.soloE2, ["avvio-fallito"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertEqual(rig.soloResumeState, .idle)
    XCTAssertEqual(rig.starts, 1)
    checkSolo(rig, "dopo E2")
    rig.wakeup(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
}

/// Seguito 1, voce 2 — la catena dei tentativi (venti da 0,5 s, la rete a 5 s che rientra dal primo tentativo, e di nuovo) non
/// lascia mai la pausa senza una strada in volo, e il pre-controllo conta a ogni tentativo. Con una canzone corta finisce da
/// sola quando la canzone finisce (E3). La rete che trova la ripresa pendente abbassata da altri finisce senza avvio: E2.
func testTheRetryChainNeverLeavesThePauseWithoutARoadAndEndsWithTheSong() {
    var rig = soloInSong()
    rig.setActiveFailures = 1000
    rig.systemStopsEngine(at: 13.0)
    rig.configurationNotification(at: 13.1)
    var t = 13.1
    while t < 40.0 {
        t += 0.25
        rig.advance(to: t)
        checkSolo(rig, "t:\(t)")
    }
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.soloE3, [])
    XCTAssertTrue(rig.soloResumePending)
    XCTAssertGreaterThanOrEqual(rig.safetyNetFired, 1)
    XCTAssertGreaterThan(rig.setActiveAttempts, 40)
    XCTAssertEqual(rig.soloPreChecks, rig.setActiveAttempts, "il pre-controllo conta a ogni tentativo")
    var short = soloInSong(soloShort)
    short.setActiveFailures = 1000
    short.systemStopsEngine(at: 13.0)
    short.configurationNotification(at: 13.1)
    t = 13.1
    while t < 20.0 {
        t += 0.25
        short.advance(to: t)
        checkSolo(short, "corta t:\(t)")
    }
    XCTAssertEqual(short.soloE3, ["pre-controllo"], "la catena finisce con la canzone")
    XCTAssertEqual(short.starts, 1)
    XCTAssertEqual(short.runnerArmNext, 1)
    let attempts = short.setActiveAttempts
    short.advance(to: 40.0)
    XCTAssertEqual(short.setActiveAttempts, attempts, "dopo E3 la catena è morta")
    var net = soloInSong()
    net.setActiveFailures = 1000
    net.systemStopsEngine(at: 13.0)
    net.configurationNotification(at: 13.1)
    net.advance(to: 23.5)
    XCTAssertNotNil(net.safetyNet)
    XCTAssertTrue(net.pendingResume)
    net.pendingResume = false
    net.advance(to: 30.0)
    XCTAssertEqual(net.safetyNetSkipped, 1)
    XCTAssertEqual(net.soloE2, ["rete-senza-ripresa-pendente"], "la catena che finisce senza avvio: E2")
    XCTAssertEqual(net.soloStops, 1)
    checkSolo(net, "dopo E2")
}

/// La regola del 21/10 (BOX5), le due prove del referto A424 par. 2.1 h: l'interruzione che comincia nell'attesa del ritorno
/// (il ritorno annullato, la catena chiusa, il Solo fermo come la console) e nella scorta (il fuoco annullato); e il fuoco che
/// scatta fra i due passaggi sulla coda dell'inizio di un'interruzione (la guardia del fuoco: E2). Alla fine niente riparte.
func testAnInterruptionInTheWaitOfTheReturnAndInTheLeadInStopsAsTheConsole() {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [headphones])
    rig.interruptionBegan(at: 13.05)
    XCTAssertNil(rig.directorReturn)
    XCTAssertEqual(rig.chainsClosedAtBegin, 1)
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertEqual(rig.crisisCause, .interruption)
    XCTAssertEqual(rig.soloResumeState, .idle)
    XCTAssertTrue(rig.playbackStopped)
    checkSolo(rig, "dopo l'inizio")
    rig.interruptionEnded(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "alla fine il Solo non riparte")
    var lead = soloInSong()
    lead.routeChange(at: 13.0, to: [headphones])
    lead.advance(to: 13.2)
    XCTAssertEqual(lead.soloResumeState, .armed)
    lead.interruptionBegan(at: 13.3)
    XCTAssertEqual(lead.soloStops, 1)
    XCTAssertNil(lead.soloFire)
    XCTAssertEqual(lead.soloResumeState, .idle)
    XCTAssertFalse(lead.isRunning)
    lead.interruptionEnded(at: 14.0)
    lead.advance(to: 20.0)
    XCTAssertEqual(lead.starts, 2)
    XCTAssertEqual(lead.soloResumes, 0)
    var between = soloInSong()
    between.routeChange(at: 13.0, to: [headphones])
    between.advance(to: 13.2)
    between.systemInterruption = true
    between.advance(to: 14.5)
    XCTAssertEqual(between.soloE2, ["interruzione"], "la guardia del fuoco")
    XCTAssertEqual(between.soloResumes, 0)
    XCTAssertEqual(between.soloStops, 1)
    XCTAssertFalse(between.isRunning)
}

/// Lo stacco nella pausa: la notizia della tolta ferma il Solo come la console anche a motore fermo (P35: in moto per il player).
/// L'uscita sparita prima della sua notizia (P32): allo scatto del ritorno la memoria dice esterna e un'esterna non c'è: E2 con
/// la causa «uscita-tolta», nessuna attivazione. E un ritorno che non può scattare con la ripresa in attesa era l'ultima strada: E2.
func testARemovalOrAVanishedOutputInThePauseStopsAsAtTheRemoval() {
    var rig = soloInSong(route: [headphones])
    rig.routeChange(at: 13.0, to: [headphones, bluetooth], rateChanges: true)
    rig.advance(to: 13.5)
    XCTAssertEqual(rig.soloResumeState, .waiting)
    rig.routeChange(at: 13.6, to: [speaker])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertEqual(rig.crisisCause, .outputRemoved)
    XCTAssertNil(rig.directorReturn)
    XCTAssertEqual(rig.soloResumeState, .idle)
    XCTAssertTrue(rig.playbackStopped)
    checkSolo(rig, "dopo lo stacco")
    rig.configurationNotification(at: 13.7)
    rig.wakeup(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "dopo lo stacco aspetta il Play")
    var vanished = soloInSong(route: [headphones])
    XCTAssertEqual(vanished.state.lastOutputExternal, true)
    vanished.routeChange(at: 13.0, to: [headphones, bluetooth])
    XCTAssertEqual(vanished.directorReturn?.wait, .settle)
    vanished.physicalRoute = [speaker]
    vanished.advance(to: 13.2)
    XCTAssertEqual(vanished.soloE2, ["uscita-sparita"])
    XCTAssertEqual(vanished.crisisCause, .outputRemoved)
    XCTAssertEqual(vanished.soloStops, 1)
    XCTAssertEqual(vanished.starts, 1)
    XCTAssertEqual(vanished.setActiveAttempts, 0)
    vanished.wakeup(at: 14.0)
    vanished.advance(to: 20.0)
    XCTAssertEqual(vanished.starts, 1)
    var other = soloInSong()
    other.routeChange(at: 13.0, to: [headphones])
    other.soloSongIdx = 1
    other.advance(to: 13.2)
    XCTAssertEqual(other.soloReturnsNotFired, 1)
    XCTAssertEqual(other.soloE2, ["ritorno-non-eseguito"], "era l'ultima strada")
    XCTAssertEqual(other.soloStops, 1)
    XCTAssertEqual(other.starts, 1)
    checkSolo(other, "dopo E2")
}

/// I servizi audio persi e il reset senza Lost nella pausa: fermo come la console (in moto per il player), niente riparte.
func testServicesLostAndResetInThePauseStopAsTheConsole() {
    var lost = soloPausedByBluetooth()
    lost.servicesLost(at: 13.6)
    XCTAssertEqual(lost.soloStops, 1)
    XCTAssertEqual(lost.crisisCause, .servicesLost)
    XCTAssertEqual(lost.soloResumeState, .idle)
    checkSolo(lost, "dopo la Lost")
    lost.advance(to: 20.0)
    XCTAssertEqual(lost.starts, 1)
    var reset = soloPausedByBluetooth()
    reset.mediaResetWithoutLost(at: 13.6)
    XCTAssertEqual(reset.soloStops, 1)
    XCTAssertEqual(reset.crisisCause, .resetWithoutLost)
    XCTAssertEqual(reset.soloResumeState, .idle)
    checkSolo(reset, "dopo il reset")
    reset.advance(to: 20.0)
    XCTAssertEqual(reset.starts, 1)
}

/// Il cambio di ruolo e lo show chiuso nella pausa (per difesa: dal player, nella pausa, il ruolo non si cambia): la ripresa
/// chiusa, il contatore della catena alzato, il player a «fermo», niente riparte. Nella scorta il motore muto si ferma.
func testARoleChangeOrTheShowClosedInThePauseCloseTheResume() {
    var role = soloPausedByBluetooth()
    let token = role.resumeToken
    role.roleChange(to: .direttore, at: 13.6)
    XCTAssertFalse(role.soloResumePending)
    XCTAssertNil(role.soloAnchor)
    XCTAssertEqual(role.resumeToken, token + 1)
    XCTAssertTrue(role.playbackStopped)
    XCTAssertTrue(role.wantedStop)
    XCTAssertNil(role.directorReturn)
    role.configurationNotification(at: 13.7)
    role.advance(to: 20.0)
    XCTAssertEqual(role.starts, 1)
    var show = soloPausedByBluetooth()
    show.closeShow(at: 13.6)
    XCTAssertFalse(show.soloResumePending)
    XCTAssertNil(show.soloAnchor)
    XCTAssertTrue(show.playbackStopped)
    show.configurationNotification(at: 13.7)
    show.advance(to: 20.0)
    XCTAssertEqual(show.starts, 1)
    var armed = soloInSong()
    armed.routeChange(at: 13.0, to: [headphones])
    armed.advance(to: 13.2)
    XCTAssertEqual(armed.soloResumeState, .armed)
    armed.roleChange(to: .direttore, at: 13.3)
    XCTAssertFalse(armed.isRunning)
    XCTAssertNil(armed.soloFire)
    XCTAssertEqual(armed.soloResumes, 0)
    armed.advance(to: 20.0)
    XCTAssertEqual(armed.soloResumes, 0)
}

/// Un'uscita che compare nella pausa di una configurazione (il motore è fermo, il volume è a 1): la crisi e il ritorno sì, il
/// silenzio non si scrive. Il ritorno apre una catena nuova e il tentativo della catena di prima muore.
func testAnAddedOutputInThePauseOfAConfigurationArmsTheReturnWithoutWritingTheSilence() throws {
    var rig = soloInSong()
    rig.setActiveFailures = 1000
    rig.systemStopsEngine(at: 13.0)
    rig.configurationNotification(at: 13.1)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertEqual(rig.soloResumeState, .waiting)
    let token = rig.resumeToken
    rig.routeChange(at: 13.3, to: [headphones])
    XCTAssertEqual(rig.volume, 1.0, "a motore fermo il silenzio non si scrive")
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    checkSolo(rig, "dopo la notizia")
    rig.setActiveFailures = 0
    rig.advance(to: 13.45)
    XCTAssertGreaterThan(rig.resumeToken, token, "il ritorno apre una catena nuova: il tentativo di prima muore")
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(rig.setActiveAttempts, 2)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.4 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloResumes, 1)
    rig.advance(to: 30.0)
    XCTAssertEqual(rig.starts, 2, "il tentativo della catena di prima non riparte")
}

/// Fuori da una canzone (a show chiuso, o senza una canzone del runner) il Solo resta com'è oggi: l'uscita che compare non fa
/// niente, la configurazione riparte come oggi, nessuna àncora e nessuna ripresa.
func testOutOfASongTheSoloIsAsToday() {
    for withoutShow in [true, false] {
        var rig = OutputRig(role: .solo, route: [speaker])
        rig.soloMap = soloTwoSections
        if withoutShow {
            rig.showOpen = false
            rig.runnerPlay(at: 10.0)
        } else {
            rig.start(at: 10.0, recovery: nil)
            XCTAssertFalse(rig.songInProgress)
        }
        rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
        rig.routeChange(at: 13.0, to: [headphones])
        XCTAssertTrue(rig.isRunning, "senzaShow:\(withoutShow)")
        XCTAssertEqual(rig.volume, 1.0, "senzaShow:\(withoutShow)")
        XCTAssertNil(rig.directorReturn, "senzaShow:\(withoutShow)")
        rig.systemStopsEngine(at: 14.0)
        rig.configurationNotification(at: 14.1)
        XCTAssertEqual(rig.starts, 2, "senzaShow:\(withoutShow): la ripartenza come oggi")
        XCTAssertEqual(rig.soloAnchorsTaken, 0, "senzaShow:\(withoutShow)")
        XCTAssertFalse(rig.soloResumePending, "senzaShow:\(withoutShow)")
        XCTAssertEqual(rig.soloResumes, 0, "senzaShow:\(withoutShow)")
        XCTAssertTrue(rig.isRunning, "senzaShow:\(withoutShow)")
    }
}

// MARK: - A437 · SEGUITO 5 (19/11/2026): le letture di Δ del Solo dalla regola pura, coi numeri del telefono
//
// Sul telefono l'ora dell'ultimo render sta circa 22,9 ms dopo adesso («a»), e l'inizio del rendering del buffer di confronto
// cade fra 0,19 e 10,56 ms prima di quell'ora («ψ»; referto A437, par. 45-46). Nel modo realistico del rig (`soloOnThePhone`)
// l'uscita vera di ogni buffer sta sulla linea della catena, e Δ non è data: la regola deve ritrovarla. Queste sequenze provano
// che la regola, il motivo di ogni scarto e l'àncora tornano DATI quei due fatti: i fatti li prova il WAV del collaudo C6.
// Le stesse sequenze, con le rotture volute, girano nel modello Python del seguito (prove5.py).

private var soloSlow: SongMap {
    SongMap(sections: [SongMapSection(beatsPerBar: 4, repetitions: 24, bpm: 71.5)])
}

/// Il Solo in canzone nel modo realistico: «a» e «ψ» del telefono, il Play a 10,0 s, i richiami puntuali. Di base i richiami
/// continuano fin poco prima della crisi delle 13,0 (nel motore la catena non si ferma): così la convenzione del battito
/// dell'àncora è quella scritta per il buffer che lo porta, non la formula di ripiego del rig (nota N5 del verificatore V2).
private func soloOnThePhone(phase: Double, ahead: Double = 0.0229, nodeRate: Double = 48_000.0, cycleFrames: Double = 512,
                            callbacks: Int? = nil, map: SongMap? = nil, renderFresh: Bool = true,
                            renderBehind: Double = 0.001) -> OutputRig {
    var rig = OutputRig(role: .solo, route: [speaker], cycleSeconds: cycleFrames / nodeRate)
    rig.nodeRate = nodeRate
    rig.soloMap = map ?? soloTwoSections
    rig.renderAheadSeconds = ahead
    rig.renderPhaseSeconds = phase
    rig.soloRenderFresh = renderFresh
    rig.soloRenderBehindSeconds = renderBehind
    rig.runnerPlay(at: 10.0)
    let count = callbacks ?? Int(((12.99 - 10.0) / rig.bufferSeconds).rounded(.down))
    rig.callbacks(from: 10.0 + rig.bufferSeconds, count: count)
    return rig
}

/// Il primo «uno» della griglia VERA non prima di `t`: nel modo realistico la griglia parte a − ψ dopo quella di `soloBar`.
private func soloTrueBar(_ rig: OutputRig, _ map: SongMap, atOrAfter t: Double) -> (at: Double, section: Int, bar: Int)? {
    guard let bar = soloBar(map, atOrAfter: t - rig.soloRenderShift) else { return nil }
    return (bar.at + rig.soloRenderShift, bar.section, bar.bar)
}

/// Le cuffie attaccate a `crisisAt`, il ritorno dopo l'assestamento, la ripresa: rende l'ora vera dell'«uno» atteso.
private func soloResumeAfterHeadphones(_ rig: inout OutputRig, crisisAt: Double = 13.0, map: SongMap? = nil,
                                       file: StaticString = #filePath, line: UInt = #line) throws -> Double {
    rig.routeChange(at: crisisAt, to: [headphones])
    let want = try XCTUnwrap(soloTrueBar(rig, map ?? soloTwoSections, atOrAfter: crisisAt + 0.1 + rig.margin),
                             file: file, line: line)
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.soloResumes, 1, "la ripresa", file: file, line: line)
    return want.at
}

/// P24, la (a) — l'ora vera dell'àncora ha bisogno delle letture di Δ.
/// ⚠️ RISCRITTA A437 · SEGUITO 5 (19/11/2026). Fino al seguito 4 la prova dava Δ al rig (21,3 ms) e le letture non passavano
/// dalla regola: non poteva vedere che sul telefono la regola le scartava tutte. Ora gioca i numeri del telefono: con otto
/// letture valide (lettura:hardware) il click torna entro mezzo ciclo dalla griglia di prima, e l'errore è ψ meno mezzo ciclo;
/// col render fermo (L indietro, anche di un solo millisecondo) nessuna lettura vale, la lettura è «riserva» e il click
/// anticipa della Δ vera (22-34 ms: quello che faceva il telefono fino al seguito 4); con due sole letture ancora la riserva.
func testTheTrueTimeOfTheAnchorNeedsTheReadingsOfDelta() throws {
    for phase in [0.00019, 0.00533, 0.01056] {
        var rig = soloOnThePhone(phase: phase)
        let want = try soloResumeAfterHeadphones(&rig)
        let delta = try XCTUnwrap(rig.soloLastDelta)
        XCTAssertEqual(delta.readings, 8, "psi:\(phase)")
        XCTAssertTrue(delta.fromHardware, "psi:\(phase)")
        XCTAssertEqual(delta.sourceName, "hardware", "psi:\(phase)")
        let half = rig.cycleSeconds / 2
        let click = try XCTUnwrap(rig.soloFirstClickAt)
        XCTAssertEqual(click - want, phase - half, accuracy: 2e-6, "psi:\(phase): l'errore e' psi meno mezzo ciclo")
        XCTAssertLessThanOrEqual(abs(click - want), half + 2e-6, "psi:\(phase): entro mezzo ciclo dalla griglia")
        XCTAssertEqual(Double(delta.ticks) / OutputRig.tps, 0.0229 + rig.bufferSeconds / 2, accuracy: 2e-6,
                       "psi:\(phase): Delta letta = a + mezzo buffer (28,23 ms)")
    }
    for behind in [0.5, 0.001] {
        var blind = soloOnThePhone(phase: 0.00533, renderFresh: false, renderBehind: behind)
        let want = try soloResumeAfterHeadphones(&blind)
        XCTAssertEqual(blind.soloLastDelta?.readings, 0, "indietro:\(behind)")
        XCTAssertEqual(blind.soloLastDelta?.fromHardware, false, "lettura:riserva indietro:\(behind)")
        XCTAssertEqual(blind.soloLastDelta?.sourceName, "riserva", "indietro:\(behind)")
        let tally = try XCTUnwrap(blind.soloLastTally)
        XCTAssertEqual(tally.behind, tally.calls - 5, "indietro:\(behind): tutte «indietro» dopo le cinque d'avvio")
        let click = try XCTUnwrap(blind.soloFirstClickAt)
        XCTAssertEqual(click - want, -blind.soloTrueDeltaSeconds, accuracy: 2e-6,
                       "indietro:\(behind): la riserva, il click anticipa della Delta vera")
    }
    var two = soloOnThePhone(phase: 0.00533, callbacks: 48, renderFresh: false)
    two.soloRenderFresh = true
    two.callbacks(from: two.now + two.bufferSeconds, count: 2)
    two.routeChange(at: 13.0, to: [headphones])
    XCTAssertEqual(two.soloLastDelta?.readings, 2)
    XCTAssertEqual(two.soloLastDelta?.fromHardware, false, "con due letture ancora la riserva")
    XCTAssertEqual(two.soloLastDelta?.sourceName, "riserva")
}

/// Lo stesso a 44,1 kHz (la cassa Bluetooth): il buffer e il ciclo durano 11,61 ms, Δ letta 28,7 ms, l'errore entro ±5,80 ms.
func testAt44100TheAnchorIsWithinHalfACycleOfTheGrid() throws {
    for phase in [0.00019, 0.00533, 0.01056] {
        var rig = soloOnThePhone(phase: phase, nodeRate: 44_100.0)
        let want = try soloResumeAfterHeadphones(&rig)
        let delta = try XCTUnwrap(rig.soloLastDelta)
        XCTAssertEqual(delta.readings, 8, "psi:\(phase)")
        XCTAssertEqual(delta.sourceName, "hardware", "psi:\(phase)")
        let half = rig.cycleSeconds / 2
        let click = try XCTUnwrap(rig.soloFirstClickAt)
        XCTAssertEqual(click - want, phase - half, accuracy: 2e-6, "psi:\(phase)")
        XCTAssertLessThanOrEqual(abs(click - want), half + 2e-6, "psi:\(phase)")
        XCTAssertEqual(Double(delta.ticks) / OutputRig.tps, 0.0229 + rig.bufferSeconds / 2, accuracy: 2e-6, "psi:\(phase)")
    }
}

/// Il ciclo d'I/O di 256 campioni col buffer di 512 [Ipotesi del referee: il fatto F1 è misurato solo col ciclo uguale al
/// buffer]: la regola si applica, e l'errore segue il posto di ψ. (i) F1 com'è, a = due cicli: entro mezzo ciclo; (ii) F1
/// spostato di un ciclo, ψ in (ciclo, 2 cicli]: il click più tardi del vero, da mezzo ciclo a un ciclo e mezzo; (iii) a che
/// resta 22,9 ms: oltre il tetto di tre cicli (16 ms), «avanti», e vale la riserva; (iv) F1 spostato all'indietro, ψ in
/// (−ciclo, 0]: il click fino a un ciclo e mezzo in anticipo.
func testWithACycleOf256FramesTheRuleAppliesAndItsErrorFollowsThePhase() throws {
    let cycle = 256.0 / 48_000.0
    for phase in [0.0002, 0.00267, 0.0052] {
        var rig = soloOnThePhone(phase: phase, ahead: 2 * cycle, cycleFrames: 256)
        let want = try soloResumeAfterHeadphones(&rig)
        XCTAssertEqual(rig.soloLastDelta?.sourceName, "hardware", "(i) psi:\(phase)")
        let click = try XCTUnwrap(rig.soloFirstClickAt)
        XCTAssertEqual(click - want, phase - cycle / 2, accuracy: 2e-6, "(i) psi:\(phase)")
        XCTAssertLessThanOrEqual(abs(click - want), cycle / 2 + 2e-6, "(i) psi:\(phase)")
    }
    var shifted = soloOnThePhone(phase: cycle + 0.001, ahead: 2 * cycle, cycleFrames: 256)
    var want = try soloResumeAfterHeadphones(&shifted)
    XCTAssertEqual(shifted.soloLastDelta?.sourceName, "hardware", "(ii)")
    XCTAssertEqual(try XCTUnwrap(shifted.soloFirstClickAt) - want, 0.001 + cycle / 2, accuracy: 2e-6, "(ii): +3,67 ms")
    var far = soloOnThePhone(phase: 0.00267, ahead: 0.0229, cycleFrames: 256)
    want = try soloResumeAfterHeadphones(&far)
    XCTAssertEqual(far.soloLastDelta?.readings, 0, "(iii)")
    XCTAssertEqual(far.soloLastDelta?.sourceName, "riserva", "(iii)")
    let farTally = try XCTUnwrap(far.soloLastTally)
    XCTAssertEqual(farTally.ahead, farTally.calls - 5, "(iii): tutte «avanti» dopo le cinque d'avvio")
    XCTAssertEqual(try XCTUnwrap(far.soloFirstClickAt) - want, -far.soloTrueDeltaSeconds, accuracy: 2e-6, "(iii): la riserva")
    var back = soloOnThePhone(phase: -0.002, ahead: 2 * cycle, cycleFrames: 256)
    want = try soloResumeAfterHeadphones(&back)
    XCTAssertEqual(back.soloLastDelta?.sourceName, "hardware", "(iv)")
    XCTAssertEqual(try XCTUnwrap(back.soloFirstClickAt) - want, -0.002 - cycle / 2, accuracy: 2e-6, "(iv): -4,67 ms")
}

/// Il ciclo d'I/O di 1024 campioni, più lungo del buffer del lettore: ogni lettura si scarta col motivo «ciclo», prima ancora
/// di leggere `lastRenderTime`, e vale la riserva.
func testWithACycleOf1024FramesTheReadingsAreDiscardedAndTheReserveHolds() throws {
    var rig = soloOnThePhone(phase: 0.00533, cycleFrames: 1024)
    let want = try soloResumeAfterHeadphones(&rig)
    XCTAssertEqual(rig.soloLastDelta?.readings, 0)
    XCTAssertEqual(rig.soloLastDelta?.sourceName, "riserva")
    let tally = try XCTUnwrap(rig.soloLastTally)
    XCTAssertEqual(tally.cycle, tally.calls - 5, "tutte «ciclo» dopo le cinque d'avvio")
    XCTAssertEqual(tally.valid, 0)
    XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: OutputRig.tps), "-", "lastRenderTime non si legge nemmeno")
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt) - want, -rig.soloTrueDeltaSeconds, accuracy: 2e-6, "la riserva")
}

/// Una crisi subito dopo la partenza della catena: le letture «avvio» sono cinque (le tre chiamate della partenza e i richiami
/// 1 e 2), e il battito contato è il primo del Play, nel buffer 0. Anche con quattro letture di regime già valide Δ non si somma
/// a quel battito (niente mescolanza: una Δ sola vale per una convenzione sola): la lettura è «avvio», Δ = 0.
func testACrisisRightAfterTheChainStartsTakesNoDeltaOnTheStartupBeat() throws {
    let phase = 0.00533
    for (count, valid) in [(6, 4), (4, 2)] {
        var rig = soloOnThePhone(phase: phase, callbacks: count)
        let want = try soloResumeAfterHeadphones(&rig, crisisAt: 10.07)
        let tally = try XCTUnwrap(rig.soloLastTally)
        XCTAssertEqual(tally.startup, 5, "richiami:\(count): le tre chiamate della partenza e i richiami 1 e 2")
        XCTAssertEqual(tally.valid, valid, "richiami:\(count)")
        XCTAssertEqual(tally.calls, count + 3, "richiami:\(count)")
        let delta = try XCTUnwrap(rig.soloLastDelta)
        XCTAssertEqual(delta.readings, valid, "richiami:\(count): le letture della catena come sono")
        XCTAssertEqual(delta.sourceName, "avvio", "richiami:\(count)")
        XCTAssertEqual(delta.ticks, 0, "richiami:\(count)")
        XCTAssertFalse(delta.fromHardware, "richiami:\(count)")
        // L'ora del battito è la convenzione dei tre della partenza (adesso + latenza + ciclo): l'errore è ciclo − a + ψ.
        XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt) - want, rig.cycleSeconds - 0.0229 + phase, accuracy: 2e-6,
                       "richiami:\(count)")
    }
}

/// Par. 2.3 — nella prima battuta dopo un Play a tempo lento (71,5: il secondo battito esce 0,84 s dopo il primo) l'ultimo
/// battito uscito è ancora quello del buffer 0, mentre le letture di regime sono già otto: l'àncora non gli somma Δ. Dopo il
/// secondo battito l'àncora è su un battito di regime, e Δ torna.
func testInTheFirstBarAfterAPlayAtASlowTempoTheAnchorTakesNoDelta() throws {
    let phase = 0.00533
    var rig = soloOnThePhone(phase: phase, callbacks: 60, map: soloSlow)
    var want = try soloResumeAfterHeadphones(&rig, crisisAt: 10.70, map: soloSlow)
    XCTAssertEqual(rig.soloLastDelta?.readings, 8, "le letture di regime ci sono")
    XCTAssertEqual(rig.soloLastDelta?.sourceName, "avvio")
    XCTAssertEqual(rig.soloLastDelta?.ticks, 0)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt) - want, rig.cycleSeconds - 0.0229 + phase, accuracy: 2e-6,
                   "il battito della partenza: senza Delta")
    var later = soloOnThePhone(phase: phase, callbacks: 90, map: soloSlow)
    want = try soloResumeAfterHeadphones(&later, crisisAt: 10.97, map: soloSlow)
    XCTAssertEqual(later.soloLastDelta?.sourceName, "hardware")
    XCTAssertEqual(try XCTUnwrap(later.soloFirstClickAt) - want, phase - later.cycleSeconds / 2, accuracy: 2e-6,
                   "il battito di regime: con Delta")
}

/// Par. 2.4 — i contatori della riga `letture di delta` alla presa dell'àncora: cinque «avvio», il resto valide, nessun altro
/// scarto; i due «ultimi» (l'ultimo render meno adesso, l'ultima Δ). Un richiamo in ritardo sposta adesso e non L. La catena
/// nuova della ripresa riparte da zero.
func testTheCountersOfTheReadingsAreWrittenAtTheAnchor() throws {
    var rig = soloOnThePhone(phase: 0.00533)
    _ = try soloResumeAfterHeadphones(&rig)
    let tally = try XCTUnwrap(rig.soloLastTally)
    XCTAssertEqual(tally.startup, 5)
    XCTAssertEqual(tally.calls, 283, "tre chiamate della partenza e duecentottanta richiami")
    XCTAssertEqual(tally.valid, 278)
    XCTAssertEqual(tally.discarded, 5)
    XCTAssertEqual([tally.render, tally.chain, tally.behind, tally.ahead, tally.cycle, tally.limits], [0, 0, 0, 0, 0, 0])
    XCTAssertEqual(tally.lastRenderMinusNowText(ticksPerSecond: OutputRig.tps), "22.9")
    XCTAssertEqual(tally.lastDeltaText(ticksPerSecond: OutputRig.tps), "28.2")
    var late = soloOnThePhone(phase: 0.00533, callbacks: 49)
    let lateAt = 10.0 + 50 * late.bufferSeconds + 0.004
    late.advance(to: lateAt)
    late.scheduleNextBuffer(at: lateAt)
    XCTAssertEqual(late.soloDeltaTally.lastRenderMinusNowText(ticksPerSecond: OutputRig.tps), "18.9", "4 ms di ritardo: 22,9 - 4")
    XCTAssertEqual(late.soloDeltaTally.valid, 48)
    XCTAssertEqual(rig.soloDeltaTally.calls, 3, "le tre chiamate della partenza della catena della ripresa")
    XCTAssertEqual(rig.soloDeltaTally.startup, 3)
}

/// Par. 3 g — una notizia di percorso che non cambia né frequenza né modo riscrive latenza e ciclo a catena viva. Con gli
/// stessi valori le letture restano; se la latenza (o il ciclo) cambia davvero si azzerano, le due letture dopo cadono su
/// «catena» (la memoria delle convenzioni è vuota), e un battito contato di un buffer di prima dell'azzeramento prende Δ = 0
/// («avvio»); con un battito di dopo, Δ torna. Nel modo di prima del rig (l'uscita vera segue la convenzione di 21,3 ms).
func testTheReadingsAreResetOnlyWhenLatencyOrCycleReallyChangeWithTheChainAlive() throws {
    var rig = soloInSong()
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 184)
    let validBefore = rig.soloDeltaTally.valid
    rig.routeNewsRewritesTiming(at: 12.5)
    XCTAssertEqual(rig.soloDeltaResets, [], "gli stessi valori riscritti: niente azzeramento")
    XCTAssertEqual(rig.soloDeltaTally.valid, validBefore)
    XCTAssertEqual(rig.soloDeltaReadings.count, 8)
    rig.routeNewsRewritesTiming(at: 12.5, latency: 0.0300)
    XCTAssertEqual(rig.soloDeltaResets, ["latenza"])
    XCTAssertEqual(rig.soloDeltaTally.calls, 0, "i contatori ripartono")
    XCTAssertEqual(rig.soloDeltaReadings.count, 0)
    rig.callbacks(from: 12.5 + rig.bufferSeconds, count: 5)
    XCTAssertEqual(rig.soloDeltaTally.chain, 2, "le due letture dopo: la memoria delle convenzioni e' vuota")
    XCTAssertEqual(rig.soloDeltaTally.valid, 3)
    XCTAssertEqual(rig.soloDeltaTally.startup, 0, "la catena e' la stessa: nessuna lettura d'avvio")
    rig.routeChange(at: 12.57, to: [headphones])
    XCTAssertEqual(rig.soloLastDelta?.readings, 3)
    XCTAssertEqual(rig.soloLastDelta?.sourceName, "avvio")
    var want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 12.67 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at - 0.0213, accuracy: 2e-6,
                   "un battito di prima dell'azzeramento: senza Delta")
    var other = soloInSong()
    other.callbacks(from: other.now + other.bufferSeconds, count: 184)
    other.routeNewsRewritesTiming(at: 12.5, cycleSeconds: 256.0 / 48_000.0)
    XCTAssertEqual(other.soloDeltaResets, ["ciclo"])
    other.callbacks(from: 12.5 + other.bufferSeconds, count: 55)
    other.routeChange(at: 13.1, to: [headphones])
    XCTAssertEqual(other.soloLastDelta?.sourceName, "hardware")
    want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.2 + other.margin))
    other.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(other.soloFirstClickAt), want.at, accuracy: 2e-6, "un battito di dopo: con Delta")
}

/// Par. 2.3, la catena ancorata — dopo una ripresa il primo battito sta nel buffer 0 della catena ancorata, e la sua ora è
/// quella vera della catena. Una crisi prima del secondo battito prende l'àncora da lui: anche con le letture di regime già
/// valide Δ non si somma (la lettura è «avvio»), e la seconda ripresa torna sulla griglia. Nel modo di prima del rig.
func testAfterAResumeACrisisOnTheFirstBeatOfTheAnchoredChainTakesNoDelta() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [headphones])
    let first = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + rig.margin))
    rig.advance(to: first.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), first.at, accuracy: 1e-6)
    rig.callbacks(from: rig.now + rig.bufferSeconds, count: 30)
    XCTAssertEqual(rig.soloClosures, ["ripresa"])
    XCTAssertGreaterThanOrEqual(rig.soloDeltaTally.valid, 3, "le letture di regime della catena della ripresa ci sono")
    let holeAt = rig.now + rig.bufferSeconds + 0.05
    XCTAssertLessThan(holeAt, first.at + 60.0 / 121.5, "prima del secondo battito della ripresa")
    rig.advance(to: holeAt)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.05)
    XCTAssertEqual(rig.soloAnchorsTaken, 2)
    XCTAssertEqual(rig.soloLastDelta?.sourceName, "avvio", "il battito e' del buffer 0 della catena ancorata")
    XCTAssertEqual(rig.soloLastDelta?.ticks, 0)
    let second = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: holeAt + 0.1 + rig.margin))
    rig.advance(to: second.at - 0.01)
    XCTAssertEqual(rig.soloResumes, 2)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), second.at, accuracy: 1e-6,
                   "l'ora vera della catena, senza Delta: sulla griglia")
    checkSolo(rig, "dopo la seconda ripresa")
}

/// Mai un click in ritardo (LIBRO 2026-09-20): col lettore che parte troppo tardi ogni fuoco è in ritardo, salta al bersaglio
/// dopo (mai allo stesso) coi salti contati, e senza salti il Solo si ferma come allo Stop. Col «lettore lento» già certo
/// all'armamento il salto non si consuma e il click torna sulla prima battuta raggiungibile.
func testALateFireSkipsToTheNextBarAndAfterTheSkipsStopsAsTheConsole() throws {
    var rig = soloInSong()
    rig.copiesDistance = 0.5
    rig.routeChange(at: 13.0, to: [headphones])
    rig.advance(to: 30.0)
    XCTAssertEqual(rig.soloResumes, 0, "mai un click in ritardo")
    XCTAssertEqual(rig.soloLateFires, 5)
    XCTAssertEqual(rig.soloE2, ["non-certo(ritardo-oltre-i-salti)"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertFalse(rig.isRunning)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertEqual(rig.soloLateTargets.count, 5)
    for (earlier, later) in zip(rig.soloLateTargets, rig.soloLateTargets.dropFirst()) {
        XCTAssertGreaterThan(later, earlier + 1.0, "ogni salto va al bersaglio dopo, mai allo stesso")
    }
    var slow = soloInSong()
    slow.engineStartDuration = 0.9
    slow.routeChange(at: 13.0, to: [headphones])
    slow.advance(to: 13.2)
    XCTAssertEqual(slow.soloFire?.slowPlayer, true, "armato per adesso col segno lettore-lento")
    let first = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + slow.margin))
    slow.advance(to: 14.05)
    XCTAssertEqual(slow.soloLateFires, 1)
    XCTAssertEqual(slow.soloFire?.skipsLeft, 4, "il lettore lento non consuma un salto")
    slow.advance(to: 30.0)
    XCTAssertEqual(slow.soloResumes, 1)
    XCTAssertEqual(slow.soloLateFires, 1)
    let click = try XCTUnwrap(slow.soloFirstClickAt)
    XCTAssertGreaterThan(click, first.at + 1.0, "non la battuta già persa")
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 14.0 + slow.margin))
    XCTAssertEqual(click, want.at, accuracy: 1e-6)
}

/// Una seconda crisi nella pausa (un'altra uscita che compare, col cambio di modo): l'àncora resta quella, il ritorno si riarma
/// con l'attesa della notizia nuova, e la ripresa conta dalla stessa àncora.
func testASecondCrisisInThePauseKeepsTheAnchorAndRearmsTheReturn() throws {
    var rig = soloPausedByBluetooth()
    let firstArmed = try XCTUnwrap(rig.directorReturn?.armedAt)
    rig.routeChange(at: 13.6, to: [bluetooth, usb], modeChanges: true)
    checkSolo(rig, "dopo la seconda notizia")
    XCTAssertEqual(rig.soloAnchorsTaken, 1, "l'àncora resta quella")
    XCTAssertEqual(rig.soloResumeState, .waiting)
    XCTAssertGreaterThan(try XCTUnwrap(rig.directorReturn?.armedAt), firstArmed, "il ritorno si riarma con la notizia nuova")
    XCTAssertEqual(rig.starts, 1)
    rig.configurationNotification(at: 13.8)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.8 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloResumes, 1)
}

/// C13 — dentro un'interruzione (la regola del referee del 21/10): il Solo fermo da una chiamata, le cuffie attaccate durante la
/// chiamata: niente àncora, niente ritorno, niente riparte. E una notizia arrivata con lo stato «interruzione» già alzato e la
/// ripresa ancora in attesa aggiorna solo lo stato: il ritorno non si riarma.
func testInsideAnInterruptionAnAddedOutputOnlyUpdatesTheState() throws {
    var rig = soloInSong()
    rig.interruptionBegan(at: 13.0)
    XCTAssertEqual(rig.soloStops, 1)
    rig.routeChange(at: 13.5, to: [headphones])
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    XCTAssertNil(rig.directorReturn)
    XCTAssertFalse(rig.soloResumePending)
    rig.interruptionEnded(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
    XCTAssertTrue(rig.playbackStopped)
    var mid = soloPausedByBluetooth()
    let armed = try XCTUnwrap(mid.directorReturn?.armedAt)
    mid.systemInterruption = true
    mid.routeChange(at: 13.6, to: [bluetooth, usb])
    XCTAssertEqual(mid.directorReturn?.armedAt, armed, "solo lo stato: il ritorno non si riarma")
    XCTAssertEqual(mid.soloAnchorsTaken, 1)
    XCTAssertEqual(mid.starts, 1)
}

/// Una scheda USB staccata a canzone in corso («uscita-tolta» e il cambio di modo nella stessa notizia): il Solo si ferma come
/// la console e la ripresa non comincia (la causa che lo ferma è già ricordata: nessuna àncora, nessun segno).
func testAUSBCardRemovedInSongStopsAsTheConsoleAndNoResumeBegins() {
    var rig = soloInSong(route: [usb])
    rig.routeChange(at: 13.0, to: [speaker], modeChanges: true)
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertEqual(rig.soloAnchorsTaken, 0, "la ripresa non comincia mentre il Solo si ferma come la console")
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(rig.crisisCause, .outputRemoved)
    XCTAssertTrue(rig.playbackStopped)
    checkSolo(rig, "dopo lo stacco")
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
}

// MARK: - A437 · PARTE 2 (mandato A437, par. 4 a; seguito 2, par. 1 voce 4): il Solo in canzone sotto il guardiano
//
// Col guardiano acceso i richiami continuano fino al buco (`soloInSongUnderGuardian`): quattro buffer dopo l'ultimo richiamo
// il guardiano scatta e zittisce, come nel motore. Il buco è il tempo in più oltre il passo di un buffer. L'atteso di ogni
// ripresa resta il primo «uno» di battuta non prima della decisione (lo scatto del ritorno, 100 ms dopo la crisi) più il margine,
// calcolato a mano dalla mappa (`soloBar`).

/// C19 — il buco piccolo (33,2 ms, il più piccolo misurato col Centro di Controllo): nel Solo in canzone è una crisi. Il
/// guardiano zittisce durante il buco; alla chiamata del buco l'àncora, l'arresto locale, il ritorno del Solo con l'innesco
/// «buco del render»; il buffer del buco non si programma; poi la ripresa sull'«uno» della battuta giusta. Nessun «ritorno dopo
/// il buco»: il Solo non ha una correzione che rimetta la griglia.
func testASmallHoleInTheSoloInSongIsACrisisAndTheSoloComesBackOnTheRightBar() throws {
    var rig = soloInSongUnderGuardian()
    XCTAssertNotNil(rig.guardian, "in canzone il guardiano si arma anche nel Solo")
    let holeAt = rig.now + rig.bufferSeconds + 0.0332
    rig.advance(to: holeAt)
    XCTAssertEqual(rig.guardianFires, 1, "il guardiano zittisce durante il buco")
    XCTAssertEqual(rig.volume, 0.0)
    XCTAssertTrue(rig.isRunning, "il guardiano non ferma niente: decide la chiamata dopo")
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.0332)
    XCTAssertFalse(rig.isRunning, "la crisi a ogni buco sopra la soglia della riga, anche sotto i 75 e i 150 ms")
    XCTAssertTrue(rig.queued.isEmpty, "il buffer del buco non si programma")
    XCTAssertTrue(rig.soloResumePending)
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    XCTAssertEqual(rig.directorReturn?.trigger, .renderGap)
    XCTAssertEqual(rig.directorReturn?.wait, .settle)
    XCTAssertEqual(rig.gapReturnArms, 0, "nel Solo nessun ritorno dopo il buco")
    XCTAssertNil(rig.gapReturn)
    XCTAssertEqual(rig.vanishedCrises, 0)
    XCTAssertFalse(rig.playbackStopped, "lo schermo resta quello del player")
    XCTAssertTrue(rig.soloConsoleShowsStop)
    checkSolo(rig, "dopo la crisi")
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: holeAt + 0.1 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.starts, 2)
    XCTAssertEqual(rig.soloResumes, 1)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6, "il primo click sull'uno della battuta giusta")
    XCTAssertEqual(rig.volume, 1.0, "il volume dell'avvio dallo scrittore unico")
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.soloStops, 0)
    XCTAssertEqual(rig.soloLateFires, 0)
}

/// C6 col render che riparte prima o dopo la notizia — il buco delle cuffie (835,4 ms, il 24/10). (a) Il render riparte prima
/// che la notizia si legga: il guardiano ha già zittito, la chiamata del buco fa la crisi; la notizia «aggiunta», 50 ms dopo,
/// trova il Solo fermo con la ripresa in attesa: l'àncora resta quella e il ritorno si riarma con l'attesa della notizia. Una
/// ripartenza sola. (b) La notizia dentro il buco (154,8 ms dopo l'inizio, come il 24/10): il guardiano ha già zittito, la crisi
/// è quella del percorso (parte 1) e il segno del guardiano se ne va coi ritorni annullati.
func testTheHoleOfTheHeadphonesInTheSoloInSongWithTheNoticeAfterOrInsideTheHole() throws {
    var rig = soloInSongUnderGuardian()
    let holeAt = rig.now + rig.bufferSeconds + 0.8354
    rig.advance(to: holeAt)
    XCTAssertEqual(rig.guardianFires, 1)
    XCTAssertEqual(rig.volume, 0.0)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.8354)
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.directorReturn?.trigger, .renderGap)
    rig.routeChange(at: holeAt + 0.05, to: [headphones])
    XCTAssertEqual(rig.soloAnchorsTaken, 1, "l'àncora resta quella del buco")
    XCTAssertEqual(rig.directorReturn?.trigger, .outputAdded, "il ritorno si riarma con l'attesa della notizia")
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    checkSolo(rig, "dopo la notizia")
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: holeAt + 0.05 + 0.1 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.starts, 2, "una ripartenza sola")
    XCTAssertEqual(rig.soloResumes, 1)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    XCTAssertEqual(rig.state.lastOutputExternal, true, "il click torna dalle cuffie")
    var inside = soloInSongUnderGuardian()
    let begin = inside.now
    inside.routeChange(at: begin + 0.1548, to: [headphones])
    XCTAssertEqual(inside.guardianFires, 1, "il guardiano ha zittito prima della notizia")
    XCTAssertEqual(inside.soloAnchorsTaken, 1)
    XCTAssertFalse(inside.isRunning)
    XCTAssertEqual(inside.directorReturn?.trigger, .outputAdded)
    XCTAssertNil(inside.guardianSilenceChain, "il segno del guardiano se ne va coi ritorni annullati")
    checkSolo(inside, "dopo la notizia dentro il buco")
    let wantInside = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: begin + 0.1548 + 0.1 + inside.margin))
    inside.advance(to: wantInside.at - 0.01)
    XCTAssertEqual(inside.starts, 2)
    XCTAssertEqual(try XCTUnwrap(inside.soloFirstClickAt), wantInside.at, accuracy: 1e-6)
    XCTAssertEqual(inside.volume, 1.0)
}

/// Il segno del guardiano senza buco del misuratore: il guardiano scatta (quattro buffer dall'ultima chiamata) e la chiamata
/// dopo arriva prima della soglia della riga. Nel Solo in canzone è la crisi e la ripresa, non il «ritorno dopo il buco»; sul
/// Follower, lo stesso segno arma il ritorno dopo il buco, com'era.
func testTheGuardianMarkWithoutAMeterHoleInTheSoloInSongIsACrisisNotAGapReturn() throws {
    var rig = soloInSongUnderGuardian()
    let callAt = rig.now + 4.5 * rig.bufferSeconds
    rig.advance(to: callAt)
    XCTAssertEqual(rig.guardianFires, 1)
    XCTAssertNotNil(rig.guardianSilenceChain)
    rig.scheduleNextBuffer(at: callAt)
    XCTAssertNil(rig.guardianSilenceChain)
    XCTAssertEqual(rig.gapReturnArms, 0, "nel Solo in canzone nessun ritorno dopo il buco")
    XCTAssertNil(rig.gapReturn)
    XCTAssertFalse(rig.isRunning)
    XCTAssertTrue(rig.queued.isEmpty, "il buffer di quella chiamata non si programma")
    XCTAssertEqual(rig.soloAnchorsTaken, 1)
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    XCTAssertEqual(rig.directorReturn?.trigger, .renderGap)
    checkSolo(rig, "dopo la crisi")
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: callAt + 0.1 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(rig.soloResumes, 1)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    var follower = playing(.follower, route: [speaker], at: 10.0, guardian: true)
    let followerCallAt = follower.now + 4.5 * follower.bufferSeconds
    follower.advance(to: followerCallAt)
    XCTAssertEqual(follower.guardianFires, 1)
    follower.scheduleNextBuffer(at: followerCallAt)
    XCTAssertEqual(follower.gapReturnArms, 1, "il Follower: il ritorno dopo il buco, com'era")
    XCTAssertTrue(follower.isRunning)
}

/// P32 alla crisi da misuratore — lo stacco visto prima della notizia: il click usciva dalle cuffie, alla chiamata del buco il
/// percorso dice già l'altoparlante. Il Solo si ferma come allo Stop della console con la causa «uscita-tolta» (E2): nessuna
/// àncora, nessun ritorno, niente riparte da solo, nemmeno quando la notizia della tolta arriva. Lo stesso alla prima chiamata
/// dopo uno scatto del guardiano senza buco del misuratore.
func testAVanishedOutputAtTheHoleInTheSoloInSongStopsAsTheConsole() {
    var rig = soloInSongUnderGuardian(route: [headphones])
    XCTAssertEqual(rig.state.lastOutputExternal, true)
    let holeAt = rig.now + rig.bufferSeconds + 0.1193
    rig.physicalRoute = [speaker]
    rig.advance(to: holeAt)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.1193)
    XCTAssertEqual(rig.vanishedCrises, 1)
    XCTAssertEqual(rig.soloE2, ["uscita-sparita-al-buco"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertEqual(rig.crisisCause, .outputRemoved)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertFalse(rig.isRunning)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    XCTAssertNil(rig.directorReturn)
    checkSolo(rig, "dopo lo stacco")
    rig.routeChange(at: holeAt + 0.001, to: [speaker])
    rig.advance(to: holeAt + 5.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    XCTAssertEqual(rig.soloResumes, 0)
    var mark = soloInSongUnderGuardian(route: [headphones])
    mark.physicalRoute = [speaker]
    let callAt = mark.now + 4.5 * mark.bufferSeconds
    mark.advance(to: callAt)
    XCTAssertEqual(mark.guardianFires, 1)
    mark.scheduleNextBuffer(at: callAt)
    XCTAssertEqual(mark.vanishedCrises, 1)
    XCTAssertEqual(mark.soloE2, ["uscita-sparita-al-buco"])
    XCTAssertEqual(mark.soloAnchorsTaken, 0)
    mark.advance(to: callAt + 5.0)
    XCTAssertEqual(mark.starts, 1)
}

/// Il buco nella scorta della ripresa: dopo il fuoco riuscito l'àncora è tenuta dalla ripresa fino al primo battito uscito. Un
/// buco prima di quel battito è una crisi: l'àncora resta quella (già viva, non se ne prende un'altra), l'arresto, il ritorno del
/// Solo, e una seconda ripresa sulla battuta dopo, contata sulla stessa griglia.
func testAHoleInTheLeadInOfTheSoloResumeKeepsTheAnchorAndResumesOnALaterBar() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [headphones])
    let first = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + rig.margin))
    rig.advance(to: first.at - 0.12)
    XCTAssertEqual(rig.soloResumes, 1)
    XCTAssertEqual(rig.soloResumeState, .held, "il fuoco è riuscito e l'àncora è tenuta dalla ripresa")
    XCTAssertTrue(rig.isRunning)
    let holeAt = first.at - 0.10
    rig.advance(to: holeAt)
    rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.05)
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.soloAnchorsTaken, 1, "l'àncora resta quella: già viva")
    XCTAssertTrue(rig.soloResumePending)
    XCTAssertEqual(rig.soloResumeState, .waiting)
    XCTAssertEqual(rig.soloClosures, [], "l'àncora tenuta non si è chiusa")
    XCTAssertEqual(rig.directorReturn?.kind, .solo)
    XCTAssertEqual(rig.directorReturn?.trigger, .renderGap)
    checkSolo(rig, "dopo il buco nella scorta")
    let second = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: holeAt + 0.1 + rig.margin))
    XCTAssertEqual(second.bar, first.bar + 1, "la battuta dopo quella mancata")
    rig.advance(to: second.at - 0.01)
    XCTAssertEqual(rig.soloResumes, 2)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), second.at, accuracy: 1e-6)
    XCTAssertEqual(rig.soloE2, [])
    XCTAssertEqual(rig.soloStops, 0)
}

/// Fuori da una canzone il Solo resta com'era: il guardiano non si arma, un buco è solo la riga (nessun silenzio, nessuna crisi,
/// nessuna àncora), e il click va avanti.
func testOutOfASongTheSoloIsNotUnderTheGuardianAndAHoleIsOnlyTheLine() {
    for withoutShow in [true, false] {
        var rig = OutputRig(role: .solo, route: [speaker])
        rig.soloMap = soloTwoSections
        rig.useGuardian = true
        if withoutShow {
            rig.showOpen = false
            rig.runnerPlay(at: 10.0)
        } else {
            rig.start(at: 10.0, recovery: nil)
            XCTAssertFalse(rig.songInProgress)
        }
        rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
        XCTAssertNil(rig.guardian, "senzaShow:\(withoutShow): fuori da una canzone il guardiano non si arma nel Solo")
        let holeAt = rig.now + rig.bufferSeconds + 0.8354
        rig.advance(to: holeAt)
        XCTAssertEqual(rig.guardianFires, 0, "senzaShow:\(withoutShow)")
        rig.scheduleNextBuffer(at: holeAt, gapSeconds: 0.8354)
        XCTAssertTrue(rig.isRunning, "senzaShow:\(withoutShow)")
        XCTAssertEqual(rig.volume, 1.0, "senzaShow:\(withoutShow)")
        XCTAssertEqual(rig.soloAnchorsTaken, 0, "senzaShow:\(withoutShow)")
        XCTAssertFalse(rig.soloResumePending, "senzaShow:\(withoutShow)")
        XCTAssertNil(rig.directorReturn, "senzaShow:\(withoutShow)")
        XCTAssertNil(rig.gapReturn, "senzaShow:\(withoutShow): nessun ritorno dopo il buco")
        XCTAssertEqual(rig.starts, 1, "senzaShow:\(withoutShow)")
    }
}

// MARK: - A437 · PARTE 2 (seguito 2, par. 1 voce 4): le differenze (g) e (h) fra rig e motore, portate nel rig

/// (g) — E2 col motore in moto consegna la chiusura di fine sezione rimasta aperta, una volta sola (`closeDrainOnCrisisStopQ` in
/// `abandonSoloResumeAsConsoleQ`). Lo stato «chiusura aperta nella scorta della ripresa» qui è messo a mano: nel motore non si
/// raggiunge (ogni arresto di crisi chiude il drenaggio, e nella scorta muta il DSP non arriva a una fine sezione). Lo Stop
/// della console che segue non consegna una seconda volta. Lo stesso per E3 (`endSoloSongOnResumeQ`).
func testE2AndE3WithTheEngineRunningDeliverAnOpenSectionEndOnce() throws {
    var rig = soloInSong()
    rig.routeChange(at: 13.0, to: [headphones])
    rig.advance(to: 13.2)
    XCTAssertEqual(rig.soloResumeState, .armed)
    XCTAssertTrue(rig.isRunning)
    let deliveredBefore = rig.drainDelivered
    rig.drainPending = true
    rig.systemInterruption = true
    rig.advance(to: 14.5)
    XCTAssertEqual(rig.soloE2, ["interruzione"], "la guardia del fuoco: E2 col motore in moto")
    XCTAssertFalse(rig.isRunning)
    XCTAssertEqual(rig.drainDelivered, deliveredBefore + 1, "una consegna")
    XCTAssertFalse(rig.drainPending)
    XCTAssertEqual(rig.soloStops, 1)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.drainDelivered, deliveredBefore + 1, "una sola")
    var ended = soloInSong()
    ended.routeChange(at: 13.0, to: [headphones])
    ended.advance(to: 13.2)
    XCTAssertTrue(ended.isRunning)
    let endedBefore = ended.drainDelivered
    ended.drainPending = true
    ended.endSoloSong(phase: "ritardo")
    XCTAssertEqual(ended.soloE3, ["ritardo"])
    XCTAssertFalse(ended.isRunning)
    XCTAssertEqual(ended.drainDelivered, endedBefore + 1, "una consegna")
    XCTAssertEqual(ended.runnerArmNext, 1)
}

/// (h), la prima — `start()` senza il metronomo con la ripresa in attesa: E2 (il Solo si ferma come allo Stop della console),
/// niente riparte da solo. Senza la ripresa in attesa la stessa uscita non ferma niente e non dichiara niente.
func testAStartWithoutTheMetronomeInThePauseStopsAsTheConsole() {
    var rig = soloPausedByBluetooth()
    XCTAssertTrue(rig.soloResumePending)
    rig.metronomeMissing = true
    rig.start(at: 13.6, recovery: .pendingRecovery)
    XCTAssertEqual(rig.soloE2, ["avvio-senza-metronomo"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertNil(rig.directorReturn)
    XCTAssertEqual(rig.starts, 1)
    checkSolo(rig, "dopo l'avvio senza metronomo")
    rig.metronomeMissing = false
    rig.configurationNotification(at: 13.7)
    rig.wakeup(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    var plain = OutputRig(role: .solo, route: [speaker])
    plain.metronomeMissing = true
    plain.start(at: 10.0, recovery: nil)
    XCTAssertEqual(plain.soloE2, [], "senza la ripresa in attesa nessun E2")
    XCTAssertEqual(plain.soloStops, 0)
    XCTAssertFalse(plain.isRunning)
}

/// (h), la seconda — `start()` rifiutato coi servizi audio persi, con la ripresa in attesa: E2.
func testAStartRefusedForLostServicesInThePauseStopsAsTheConsole() {
    var rig = soloPausedByBluetooth()
    rig.servicesAtStart = .servicesLost
    rig.start(at: 13.6, recovery: .pendingRecovery)
    XCTAssertEqual(rig.soloE2, ["avvio-rifiutato-servizi-persi"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertEqual(rig.starts, 1)
    checkSolo(rig, "dopo l'avvio rifiutato")
    rig.servicesAtStart = .normal
    rig.configurationNotification(at: 13.7)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    var plain = OutputRig(role: .solo, route: [speaker])
    plain.servicesAtStart = .servicesLost
    plain.start(at: 10.0, recovery: nil)
    XCTAssertEqual(plain.soloE2, [])
    XCTAssertTrue(plain.playbackStopped, "il Play rifiutato: il player a fermo, come oggi")
    XCTAssertFalse(plain.isRunning)
}

/// (h), la terza — la ricostruzione dopo la Reset che fallisce al primo avvio, con la ripresa in attesa: E2. Con la
/// ricostruzione riuscita l'avvio prosegue e la ripresa parte.
func testARebuildThatFailsAtTheStartInThePauseStopsAsTheConsole() throws {
    var rig = soloPausedByBluetooth()
    rig.servicesAtStart = .needsRebuild
    rig.rebuildFails = true
    rig.start(at: 13.6, recovery: .pendingRecovery)
    XCTAssertEqual(rig.soloE2, ["ricostruzione-fallita"])
    XCTAssertEqual(rig.soloStops, 1)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertTrue(rig.wantedStop)
    XCTAssertEqual(rig.starts, 1)
    checkSolo(rig, "dopo la ricostruzione fallita")
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "niente riparte da solo")
    var rebuilt = soloPausedByBluetooth()
    rebuilt.servicesAtStart = .needsRebuild
    rebuilt.configurationNotification(at: 13.6)
    XCTAssertEqual(rebuilt.soloE2, [])
    XCTAssertEqual(rebuilt.starts, 2, "la ricostruzione riuscita: l'avvio prosegue")
    XCTAssertEqual(rebuilt.servicesAtStart, .normal)
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.6 + rebuilt.margin))
    rebuilt.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rebuilt.soloFirstClickAt), want.at, accuracy: 1e-6)
}

// MARK: - A437 · PARTE 2 (mandato A437, par. 2.8 e 4 b; seguito 2, par. 2 voce 1): C.1, la tolta dentro una chiamata
//
// La scena (referto A431, par. 2.7): il Direttore fuori da una canzone col click in moto dalle cuffie (un Play senza mappa);
// arriva una chiamata; il batterista stacca le cuffie dentro la chiamata. Le cinque sequenze del banco di A431, più la N-1
// (l'hardware ancora occupato quando scatta la rete a 1 s). In ognuna: nessuna ripartenza automatica, lo stato fermo dopo il
// «niente» (il player a «fermo», l'interruzione, la ripresa pendente, quello che legge il pedale), e il Play che riparte.

/// Il Direttore fuori da una canzone col click in moto dalle cuffie, la chiamata e le cuffie staccate dentro la chiamata.
private func directorInACallWithTheHeadphonesRemoved() -> OutputRig {
    var rig = OutputRig(role: .direttore, route: [headphones])
    rig.start(at: 10.0, recovery: nil)
    rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
    rig.interruptionBegan(at: 11.0)
    rig.routeChange(at: 11.5, to: [speaker])
    return rig
}

/// Lo stato dopo l'inizio della chiamata e la tolta: l'arresto locale, il segno alzato una volta, il player ancora «in moto»
/// (lo Stop del pedale ferma: è la metà di A429-3 che resta al passo 2b).
func testARemovalInsideACallIsRememberedByTheDirectorOutOfASong() {
    var rig = OutputRig(role: .direttore, route: [headphones])
    rig.start(at: 10.0, recovery: nil)
    XCTAssertFalse(rig.songInProgress, "un Play senza mappa: fuori da una canzone")
    rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
    rig.interruptionBegan(at: 11.0)
    XCTAssertFalse(rig.isRunning, "l'arresto locale")
    XCTAssertFalse(rig.silentInSong)
    XCTAssertTrue(rig.interrupted)
    XCTAssertEqual(rig.crisisCause, .interruption)
    XCTAssertFalse(rig.removalDuringInterruption)
    rig.routeChange(at: 11.5, to: [speaker])
    XCTAssertTrue(rig.removalDuringInterruption, "la tolta dentro l'interruzione si ricorda")
    XCTAssertEqual(rig.removalsRemembered, 1)
    XCTAssertTrue(rig.state.missing)
    XCTAssertEqual(rig.crisisCause, .interruption, "la memoria delle crisi non si tocca")
    XCTAssertFalse(rig.playbackStopped, "durante la chiamata il player resta com'era")
    XCTAssertEqual(rig.pedalStopPress().command, .stop, "durante la chiamata lo Stop del pedale ferma: resta al passo 2b")
    rig.routeChange(at: 11.6, to: [speaker])
    XCTAssertEqual(rig.removalsRemembered, 1, "una volta sola")
    XCTAssertEqual(rig.starts, 1)
    XCTAssertEqual(rig.setActiveAttempts, 0, "dentro l'interruzione niente attiva la sessione")
}

/// Sequenza 1 — la fine con `shouldResume` e le cuffie ancora staccate, poi riattaccate: nessuna ripartenza (com'era: «uscita
/// mancante» viene prima, e il motivo resta quello); il segno resta alto finché non arriva il Play, che riparte e lo abbassa.
func testC1TheEndWithShouldResumeAndTheHeadphonesStillRemovedThenBack() {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.interruptionEnded(at: 12.0)
    XCTAssertFalse(rig.isRunning)
    XCTAssertTrue(rig.playbackStopped, "il «niente» per l'uscita mancante: il player a fermo")
    XCTAssertFalse(rig.interrupted)
    XCTAssertFalse(rig.pendingResume)
    XCTAssertTrue(rig.removalDuringInterruption, "un «niente» non abbassa il segno")
    rig.routeChange(at: 13.0, to: [headphones])
    XCTAssertFalse(rig.state.missing)
    XCTAssertTrue(rig.removalDuringInterruption, "le cuffie riattaccate non abbassano il segno")
    rig.advance(to: 15.0)
    XCTAssertEqual(rig.starts, 1, "nessuna ripartenza")
    XCTAssertEqual(rig.pedalStopPress().reason, "fermo")
    rig.start(at: 16.0, recovery: nil)
    XCTAssertTrue(rig.isRunning, "riparte col Play")
    XCTAssertFalse(rig.removalDuringInterruption)
    XCTAssertEqual(rig.removalsForgotten, ["play"])
    XCTAssertFalse(rig.playbackStopped)
}

/// Sequenza 2 — la fine senza `shouldResume`, le cuffie riattaccate prima della rete a 1 s: la ripresa pendente recuperata dalla
/// notizia trova l'uscita, e la regola dice «niente» col motivo nuovo (prima di A437 ripartiva da solo). La ripresa pendente va
/// giù, il player a «fermo», l'interruzione giù; la rete a 1 s poi non trova niente da fare.
func testC1TheEndWithoutShouldResumeAndTheHeadphonesBackBeforeTheNet() {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.interruptionEnded(at: 12.0, shouldResume: false)
    XCTAssertTrue(rig.pendingResume, "la fine senza shouldResume rialza la ripresa pendente e arma la rete a 1 s")
    XCTAssertNotNil(rig.noResumeNet)
    XCTAssertFalse(rig.playbackStopped)
    rig.routeChange(at: 12.5, to: [headphones])
    XCTAssertEqual(rig.starts, 1, "«niente» col motivo nuovo: il click aspetta il Play")
    XCTAssertFalse(rig.isRunning)
    XCTAssertFalse(rig.pendingResume, "la ripresa pendente non resta alzata")
    XCTAssertTrue(rig.playbackStopped, "il player a fermo")
    XCTAssertFalse(rig.interrupted, "l'interruzione giù: l'hardware è libero")
    XCTAssertEqual(rig.pedalStopPress().command, nil)
    XCTAssertEqual(rig.pedalStopPress().reason, "fermo", "lo Stop del pedale non ferma più niente")
    XCTAssertEqual(rig.setActiveAttempts, 0, "il «niente» è all'ingresso, prima di ogni scrittura della sessione")
    rig.advance(to: 14.0)
    XCTAssertEqual(rig.noResumeNetFired, 0, "la rete a 1 s non trova la ripresa pendente")
    XCTAssertEqual(rig.starts, 1)
    XCTAssertTrue(rig.removalDuringInterruption)
    rig.start(at: 16.0, recovery: nil)
    XCTAssertTrue(rig.isRunning)
    XCTAssertEqual(rig.removalsForgotten, ["play"])
}

/// Sequenza 3 e la N-1 — la fine senza `shouldResume`, la rete a 1 s che scatta con le cuffie ancora staccate, poi riattaccate.
/// Con l'hardware libero: «niente» per l'uscita mancante, poi niente riparte. Con l'hardware ancora occupato alla rete (N-1): il
/// «niente» per l'uscita mancante rialza la ripresa pendente (com'era); alle cuffie riattaccate la ripresa recuperata trova il
/// motivo nuovo e va giù, anche con l'hardware occupato; l'interruzione lì resta alta, e scende col «niente» a hardware libero.
func testC1TheNetFiresWithTheHeadphonesRemovedThenBackAlsoWithTheHardwareBusy() {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.interruptionEnded(at: 12.0, shouldResume: false)
    rig.advance(to: 13.5)
    XCTAssertEqual(rig.noResumeNetFired, 1)
    XCTAssertFalse(rig.pendingResume)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertFalse(rig.interrupted)
    rig.routeChange(at: 14.0, to: [headphones])
    rig.advance(to: 16.0)
    XCTAssertEqual(rig.starts, 1, "nessuna ripartenza")
    // N-1: l'hardware ancora occupato quando scatta la rete.
    var busy = directorInACallWithTheHeadphonesRemoved()
    busy.interruptionEnded(at: 12.0, hardwareBusy: true, shouldResume: false)
    busy.advance(to: 13.5)
    XCTAssertEqual(busy.noResumeNetFired, 1)
    XCTAssertTrue(busy.pendingResume, "per l'uscita mancante con l'hardware occupato la ripresa pendente resta in piedi, com'era")
    XCTAssertTrue(busy.playbackStopped)
    XCTAssertTrue(busy.interrupted)
    XCTAssertEqual(busy.pedalStopPress().reason, "fermo")
    busy.routeChange(at: 14.0, to: [headphones])
    XCTAssertFalse(busy.pendingResume, "col motivo nuovo la ripresa pendente va giù anche con l'hardware occupato")
    XCTAssertTrue(busy.playbackStopped)
    XCTAssertTrue(busy.interrupted, "con l'hardware occupato l'interruzione resta alta")
    XCTAssertEqual(busy.pedalStopPress().command, nil)
    XCTAssertEqual(busy.pedalStopPress().reason, "fermo")
    XCTAssertEqual(busy.starts, 1)
    busy.hardwareBusy = false
    busy.routeChange(at: 15.0, to: [headphones, bluetooth])
    busy.wakeup(at: 16.0)
    busy.advance(to: 20.0)
    XCTAssertEqual(busy.starts, 1, "le cuffie riattaccate e l'hardware liberato: nessuna ripartenza")
    XCTAssertFalse(busy.pendingResume)
    XCTAssertTrue(busy.removalDuringInterruption)
    busy.start(at: 21.0, recovery: nil)
    XCTAssertTrue(busy.isRunning, "riparte col Play")
    XCTAssertFalse(busy.interrupted)
}

/// Sequenza 4 — la fine con l'hardware ancora occupato (la ripresa pendente si alza), poi l'hardware libero e le cuffie
/// riattaccate: la ripresa recuperata dalla notizia trova il motivo nuovo: «niente» (prima di A437 ripartiva da solo).
func testC1TheEndWithTheHardwareBusyThenTheHeadphonesBack() {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.interruptionEnded(at: 12.0, hardwareBusy: true)
    XCTAssertTrue(rig.pendingResume)
    XCTAssertTrue(rig.interrupted)
    XCTAssertFalse(rig.playbackStopped)
    rig.hardwareBusy = false
    rig.routeChange(at: 13.0, to: [headphones])
    XCTAssertEqual(rig.starts, 1, "«niente» col motivo nuovo")
    XCTAssertFalse(rig.pendingResume)
    XCTAssertTrue(rig.playbackStopped)
    XCTAssertFalse(rig.interrupted)
    XCTAssertEqual(rig.pedalStopPress().reason, "fermo")
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
    // Una ripresa pendente già alta (qui rimessa a mano: chi la recupera di norma l'ha già abbassata prima di chiedere la
    // ripartenza) va giù al primo «niente» col motivo nuovo, da qualunque innesco.
    rig.pendingResume = true
    rig.activateSessionAndStart(trigger: .engineConfigChange, at: 20.5)
    XCTAssertFalse(rig.pendingResume, "la ripresa pendente già alta va giù al «niente» col motivo nuovo")
    XCTAssertEqual(rig.starts, 1)
}

/// Sequenza 5 — le cuffie staccate e riattaccate dentro la stessa chiamata: «uscita mancante» si abbassa alla seconda notizia,
/// il segno resta. Alla fine, con `shouldResume` e senza (la rete a 1 s): «niente» col motivo nuovo (prima ripartiva da solo).
func testC1TheHeadphonesRemovedAndBackInsideTheSameCall() {
    for shouldResume in [true, false] {
        var rig = directorInACallWithTheHeadphonesRemoved()
        rig.routeChange(at: 11.8, to: [headphones])
        XCTAssertFalse(rig.state.missing, "shouldResume:\(shouldResume)")
        XCTAssertTrue(rig.removalDuringInterruption, "shouldResume:\(shouldResume)")
        rig.interruptionEnded(at: 12.0, shouldResume: shouldResume)
        rig.advance(to: 14.0)
        XCTAssertEqual(rig.starts, 1, "shouldResume:\(shouldResume): nessuna ripartenza")
        XCTAssertFalse(rig.isRunning, "shouldResume:\(shouldResume)")
        XCTAssertTrue(rig.playbackStopped, "shouldResume:\(shouldResume)")
        XCTAssertFalse(rig.pendingResume, "shouldResume:\(shouldResume)")
        XCTAssertFalse(rig.interrupted, "shouldResume:\(shouldResume)")
        XCTAssertEqual(rig.noResumeNetFired, shouldResume ? 0 : 1, "shouldResume:\(shouldResume)")
        rig.start(at: 16.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "shouldResume:\(shouldResume): riparte col Play")
    }
}

/// Il Solo, fuori e dentro una canzone, le stesse cinque sequenze: nessuna ripartenza, com'era. La chiamata lo ferma come allo
/// Stop della console; la tolta dentro la chiamata non alza né «uscita mancante» né il segno.
func testC1TheSoloNeverRestartsAfterACallWithARemoval() {
    for inSong in [false, true] {
        for sequence in 1...5 {
            var rig = OutputRig(role: .solo, route: [headphones])
            if inSong {
                rig.soloMap = soloTwoSections
                rig.runnerPlay(at: 10.0)
            } else {
                rig.start(at: 10.0, recovery: nil)
            }
            rig.callbacks(from: 10.0 + rig.bufferSeconds, count: 50)
            let tag = "inCanzone:\(inSong) sequenza:\(sequence)"
            rig.interruptionBegan(at: 11.0)
            XCTAssertEqual(rig.soloStops, 1, tag)
            rig.routeChange(at: 11.5, to: [speaker])
            XCTAssertFalse(rig.removalDuringInterruption, tag)
            XCTAssertFalse(rig.state.missing, tag)
            switch sequence {
            case 1:
                rig.interruptionEnded(at: 12.0)
                rig.routeChange(at: 13.0, to: [headphones])
            case 2:
                rig.interruptionEnded(at: 12.0, shouldResume: false)
                rig.routeChange(at: 12.5, to: [headphones])
            case 3:
                rig.interruptionEnded(at: 12.0, shouldResume: false)
                rig.advance(to: 13.5)
                rig.routeChange(at: 14.0, to: [headphones])
            case 4:
                rig.interruptionEnded(at: 12.0, hardwareBusy: true)
                rig.hardwareBusy = false
                rig.routeChange(at: 13.0, to: [headphones])
            default:
                rig.routeChange(at: 11.8, to: [headphones])
                rig.interruptionEnded(at: 12.0)
            }
            rig.advance(to: 20.0)
            XCTAssertEqual(rig.starts, 1, tag)
            XCTAssertFalse(rig.isRunning, tag)
            XCTAssertFalse(rig.pendingResume, tag)
            XCTAssertEqual(rig.soloAnchorsTaken, 0, tag)
            XCTAssertEqual(rig.removalsRemembered, 0, tag)
        }
    }
}

/// I casi che non devono cambiare. (a) La chiamata senza cuffie staccate: con `shouldResume` il Direttore fuori da una canzone
/// riparte come oggi, senza la rete a 1 s riparte come oggi. (b) Il Direttore muto in canzone con la chiamata e la tolta: il
/// segno non nasce; «niente» con le cuffie staccate, il ritorno quando si riattaccano. (c) La tolta fuori da una chiamata (U16):
/// l'arresto locale e il motivo di U16, il segno non nasce.
func testC1TheCasesThatDoNotChange() {
    for shouldResume in [true, false] {
        var plain = OutputRig(role: .direttore, route: [headphones])
        plain.start(at: 10.0, recovery: nil)
        plain.callbacks(from: 10.0 + plain.bufferSeconds, count: 50)
        plain.interruptionBegan(at: 11.0)
        plain.interruptionEnded(at: 12.0, shouldResume: shouldResume)
        plain.advance(to: 14.0)
        XCTAssertEqual(plain.starts, 2, "shouldResume:\(shouldResume): la chiamata senza cuffie staccate riparte come oggi")
        XCTAssertTrue(plain.isRunning, "shouldResume:\(shouldResume)")
        XCTAssertEqual(plain.removalsRemembered, 0, "shouldResume:\(shouldResume)")
        XCTAssertEqual(plain.noResumeNetFired, shouldResume ? 0 : 1, "shouldResume:\(shouldResume)")
    }
    var silent = playing(.direttore, route: [headphones])
    silent.interruptionBegan(at: 11.0)
    XCTAssertTrue(silent.silentInSong)
    silent.routeChange(at: 11.5, to: [speaker])
    XCTAssertFalse(silent.removalDuringInterruption, "col Direttore muto in canzone il segno non nasce")
    XCTAssertTrue(silent.state.missing)
    silent.interruptionEnded(at: 12.0)
    XCTAssertFalse(silent.isRunning, "«niente» con le cuffie staccate")
    XCTAssertTrue(silent.silentInSong)
    silent.routeChange(at: 14.0, to: [headphones])
    silent.advance(to: 18.0)
    XCTAssertEqual(silent.rejoins, 1, "il ritorno quando le cuffie si riattaccano, come oggi")
    var removed = OutputRig(role: .direttore, route: [headphones])
    removed.start(at: 10.0, recovery: nil)
    removed.callbacks(from: 10.0 + removed.bufferSeconds, count: 50)
    removed.routeChange(at: 11.0, to: [speaker])
    XCTAssertFalse(removed.isRunning, "U16: l'arresto locale")
    XCTAssertEqual(removed.crisisCause, .outputRemoved)
    XCTAssertFalse(removed.removalDuringInterruption, "fuori da una chiamata il segno non nasce")
    removed.routeChange(at: 12.0, to: [headphones])
    removed.wakeup(at: 13.0)
    removed.advance(to: 16.0)
    XCTAssertEqual(removed.starts, 1, "U16, com'era: riparte col Play")
}

/// Chi abbassa il segno senza un Play: il cambio di ruolo (e Link spento). Le ripartenze automatiche e le cuffie riattaccate no.
/// ⚠️ CORRETTO A437 · SEGUITO 3 (19/11/2026): qui c'era `testC1TheRoleChangeForgetsTheRemovalInsideTheCall`, che col cambio di
/// ruolo asseriva il segno giù e `removalsForgotten == ["ruolo"]`. Il cambio di ruolo (e Link spento, che nel rig è la stessa
/// `roleChange`) non abbassa più il segno: resta alto, nessun motivo nell'elenco, nessuna ripartenza.
func testC1TheRoleChangeKeepsTheRemovalInsideTheCall() {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.interruptionEnded(at: 12.0)
    XCTAssertTrue(rig.removalDuringInterruption)
    rig.roleChange(to: .solo, at: 13.0)
    XCTAssertTrue(rig.removalDuringInterruption, "il cambio di ruolo non abbassa il segno")
    XCTAssertEqual(rig.removalsForgotten, [])
    XCTAssertEqual(rig.starts, 1)
}

// MARK: - A437 · SEGUITO 3 (19/11/2026): la tolta dentro la chiamata resta ricordata al cambio di ruolo e a Link spento
//
// Il fatto (seguito 3, par. 1): col segno alto un cambio di ruolo andata e ritorno, o la levetta spenta e riaccesa, lo
// abbassavano, e alla ripartenza dopo il click del Direttore ripartiva da solo, in due forme: (a) dopo la chiamata, con la
// ripresa pendente alta (la fine con l'hardware occupato; la fine senza `shouldResume`); (b) dentro la chiamata, con la fine con
// `shouldResume` e l'hardware libero. In ogni sequenza, quando arriva la ripartenza, le cuffie sono attaccate e l'hardware è
// libero: decide il segno, non «uscita mancante» né l'hardware occupato. Il rig non registra il motivo del «niente»: si calcola
// dallo stato con `RecoveryDecision.noRestartReason`, e con lo stesso stato col segno giù dà «avvio come oggi».

/// Il motivo del «niente» calcolato dallo stato del rig, come `noteNoRestart`; con `removal` dato, lo stesso stato col segno a
/// quel valore.
private func noRestartReasonNow(_ rig: OutputRig, trigger: RecoveryTrigger, removal: Bool? = nil) -> NoRestartReason? {
    RecoveryDecision.noRestartReason(trigger: trigger, playerRole: rig.role, silentInSong: rig.silentInSong,
                                     wantedStopSinceCrisis: rig.wantedStop, crisisCause: rig.crisisCause,
                                     outputMissing: rig.state.missing,
                                     removalDuringInterruption: removal ?? rig.removalDuringInterruption)
}

/// Sequenza 1 fino alla ripartenza — forma (a) con l'hardware occupato alla fine: la tolta, le cuffie riattaccate dentro la
/// chiamata, la fine con l'hardware occupato (la ripresa pendente si alza), Direttore → Follower → Direttore, l'hardware libero,
/// un'uscita Bluetooth che si aggiunge (le cuffie restano attaccate).
private func removalThenHardwareBusyEndThenARoleRoundTrip() -> OutputRig {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.routeChange(at: 11.8, to: [headphones])
    XCTAssertFalse(rig.state.missing)
    XCTAssertTrue(rig.removalDuringInterruption)
    rig.interruptionEnded(at: 12.0, hardwareBusy: true)
    XCTAssertTrue(rig.pendingResume, "la fine con l'hardware occupato alza la ripresa pendente")
    XCTAssertTrue(rig.interrupted)
    XCTAssertFalse(rig.playbackStopped)
    rig.roleChange(to: .follower, at: 12.5)
    rig.roleChange(to: .direttore, at: 12.8)
    rig.hardwareBusy = false
    rig.routeChange(at: 13.0, to: [headphones, bluetooth])
    return rig
}

/// Sequenza 2 fino alla ripartenza — forma (a) con la levetta: la tolta, le cuffie riattaccate dentro la chiamata, la fine
/// senza `shouldResume` (la ripresa pendente e la rete a 1 s), la levetta spenta (`roleChange`, `handleRoleOrLinkChangeQ`) e
/// riaccesa (`userLinkSwitchedOn`) prima che scatti la rete, poi la rete.
private func removalThenEndWithoutResumeThenTheLinkSwitchOffAndOn() -> OutputRig {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.routeChange(at: 11.8, to: [headphones])
    rig.interruptionEnded(at: 12.0, shouldResume: false)
    XCTAssertTrue(rig.pendingResume)
    XCTAssertNotNil(rig.noResumeNet)
    rig.roleChange(to: .solo, at: 12.3)
    rig.userLinkSwitchedOn(to: .direttore, at: 12.6)
    XCTAssertEqual(rig.noResumeNetFired, 0, "la levetta spenta e riaccesa prima della rete")
    rig.advance(to: 13.5)
    XCTAssertEqual(rig.noResumeNetFired, 1)
    return rig
}

/// Sequenza 3 fino alla ripartenza — forma (b): dentro la chiamata la tolta e le cuffie riattaccate, Direttore → Solo →
/// Direttore, la fine con `shouldResume` e l'hardware libero (la ripresa pendente non è alta).
private func removalAndARoleRoundTripInsideTheCallThenTheEnd() -> OutputRig {
    var rig = directorInACallWithTheHeadphonesRemoved()
    rig.routeChange(at: 11.8, to: [headphones])
    rig.roleChange(to: .solo, at: 11.9)
    rig.roleChange(to: .direttore, at: 11.95)
    XCTAssertFalse(rig.pendingResume)
    rig.interruptionEnded(at: 12.0)
    return rig
}

/// Il «niente» deciso dal segno: nessuna ripartenza, zero attivazioni, le cuffie attaccate e l'hardware libero, il motivo
/// «direttore-tolta-nella-chiamata» (col segno giù lo stesso stato darebbe «avvio come oggi»), lo stato fermo di C-1.
private func assertNoRestartByTheMark(_ rig: OutputRig, trigger: RecoveryTrigger, _ tag: String) {
    XCTAssertEqual(rig.starts, 1, "\(tag): nessuna ripartenza")
    XCTAssertFalse(rig.isRunning, tag)
    XCTAssertEqual(rig.setActiveAttempts, 0, "\(tag): zero attivazioni della sessione")
    XCTAssertFalse(rig.state.missing, "\(tag): le cuffie sono attaccate")
    XCTAssertFalse(rig.hardwareBusy, "\(tag): l'hardware è libero")
    XCTAssertEqual(noRestartReasonNow(rig, trigger: trigger), .directorRemovalInCall, tag)
    XCTAssertNil(noRestartReasonNow(rig, trigger: trigger, removal: false), "\(tag): senza il segno l'avvio sarebbe come oggi")
    XCTAssertTrue(rig.removalDuringInterruption, "\(tag): il segno resta fino al Play")
    XCTAssertTrue(rig.playbackStopped, "\(tag): il player a fermo")
    XCTAssertFalse(rig.pendingResume, "\(tag): la ripresa pendente giù")
}

/// Sequenza 1 — dopo la fine con l'hardware occupato, un cambio di ruolo andata e ritorno e l'hardware libero, la notizia del
/// percorso recupera la ripresa pendente e dice «niente» col motivo della tolta nella chiamata (prima ripartiva da solo).
func testC1TheEndWithTheHardwareBusyThenARoleRoundTripThenTheNoticeWaitsForThePlay() {
    var rig = removalThenHardwareBusyEndThenARoleRoundTrip()
    assertNoRestartByTheMark(rig, trigger: .pendingRecovery, "sequenza 1")
    XCTAssertEqual(rig.pedalStopPress().command, nil)
    XCTAssertEqual(rig.pedalStopPress().reason, "fermo")
    rig.wakeup(at: 14.0)
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1, "nemmeno il risveglio")
}

/// Sequenza 2 — la levetta spenta e riaccesa prima della rete a 1 s: la rete dice «niente» col motivo della tolta nella chiamata
/// (prima ripartiva da sola).
func testC1TheLinkSwitchOffAndOnBeforeTheOneSecondNetThenTheNetWaitsForThePlay() {
    var rig = removalThenEndWithoutResumeThenTheLinkSwitchOffAndOn()
    assertNoRestartByTheMark(rig, trigger: .safetyNetNoResume, "sequenza 2")
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
}

/// Sequenza 3 — la forma (b): il cambio di ruolo andata e ritorno dentro la chiamata, poi la fine con `shouldResume` e
/// l'hardware libero: «niente» all'ingresso, zero attivazioni (prima ripartiva da sola). La cura del referto par. 27 voce 1 (la
/// ripresa pendente giù quando il segno cade) questa forma non la chiudeva: qui la ripresa pendente non è alta.
func testC1ARoleRoundTripInsideTheCallThenTheEndWithShouldResumeWaitsForThePlay() {
    var rig = removalAndARoleRoundTripInsideTheCallThenTheEnd()
    assertNoRestartByTheMark(rig, trigger: .interruptionEnded, "sequenza 3")
    XCTAssertFalse(rig.interrupted, "l'interruzione giù: l'hardware è libero")
    rig.advance(to: 20.0)
    XCTAssertEqual(rig.starts, 1)
}

/// Sequenza 4 — dopo ognuna delle tre, il Play: il segno giù col motivo «play» e l'avvio come oggi.
func testC1AfterEachOfTheThreeThePlayForgetsTheMarkAndStartsAsToday() {
    let sequences: [(String, () -> OutputRig)] = [
        ("sequenza 1", removalThenHardwareBusyEndThenARoleRoundTrip),
        ("sequenza 2", removalThenEndWithoutResumeThenTheLinkSwitchOffAndOn),
        ("sequenza 3", removalAndARoleRoundTripInsideTheCallThenTheEnd),
    ]
    for (tag, build) in sequences {
        var rig = build()
        rig.advance(to: 20.0)
        XCTAssertEqual(rig.starts, 1, tag)
        XCTAssertEqual(rig.removalsForgotten, [], tag)
        rig.start(at: 21.0, recovery: nil)
        XCTAssertTrue(rig.isRunning, "\(tag): riparte col Play")
        XCTAssertEqual(rig.starts, 2, tag)
        XCTAssertFalse(rig.removalDuringInterruption, tag)
        XCTAssertEqual(rig.removalsForgotten, ["play"], tag)
        XCTAssertFalse(rig.playbackStopped, tag)
        XCTAssertFalse(rig.interrupted, tag)
    }
}

/// Sequenza 5 — il segno alto e il ruolo cambiato dentro la chiamata, tenuto fino alla fine. Il Follower: l'esito di oggi
/// («avvio come oggi»: il segno per lui non decide); alla sua ripartenza il segno giù col motivo «play», solo se l'avvio parte
/// davvero (la sessione della band che suona; senza, `start()` esce prima di `prepareNormalStartQ` e il segno resta). Il Solo:
/// l'esito di oggi, nessuna ripartenza per la causa che lo ferma («solo-dopo-la-crisi»); gli altri valori sono quelli che il
/// rig dà oggi, misurati sul modello, non uno Stop della console.
func testC1TheRoleChangedInsideTheCallAndKeptToTheEndRestartsAsTodayForTheFollowerAndNotForTheSolo() {
    for sessionPlaying in [false, true] {
        let tag = "follower sessioneCheSuona:\(sessionPlaying)"
        var rig = directorInACallWithTheHeadphonesRemoved()
        rig.routeChange(at: 11.8, to: [headphones])
        rig.roleChange(to: .follower, at: 11.9)
        rig.followerSessionPlaying = sessionPlaying
        XCTAssertEqual(RecoveryDecision.route(trigger: .interruptionEnded, playerRole: rig.role, silentInSong: rig.silentInSong,
                                              wantedStopSinceCrisis: rig.wantedStop, crisisCause: rig.crisisCause,
                                              outputMissing: rig.state.missing,
                                              removalDuringInterruption: rig.removalDuringInterruption),
                       .startAsToday, tag)
        rig.interruptionEnded(at: 12.0)
        XCTAssertEqual(rig.setActiveAttempts, 1, tag)
        if sessionPlaying {
            XCTAssertEqual(rig.starts, 2, "\(tag): riparte come oggi")
            XCTAssertTrue(rig.isRunning, tag)
            XCTAssertFalse(rig.removalDuringInterruption, tag)
            XCTAssertEqual(rig.removalsForgotten, ["play"], tag)
        } else {
            XCTAssertEqual(rig.starts, 1, "\(tag): senza una sessione che suona il Follower resta fermo, come oggi")
            XCTAssertFalse(rig.isRunning, tag)
            XCTAssertTrue(rig.removalDuringInterruption, "\(tag): l'avvio non è partito: il segno resta")
            XCTAssertEqual(rig.removalsForgotten, [], tag)
        }
    }
    var solo = directorInACallWithTheHeadphonesRemoved()
    solo.routeChange(at: 11.8, to: [headphones])
    solo.roleChange(to: .solo, at: 11.9)
    solo.interruptionEnded(at: 12.0)
    solo.advance(to: 20.0)
    XCTAssertEqual(solo.starts, 1, "il Solo: nessuna ripartenza, come oggi")
    XCTAssertFalse(solo.isRunning)
    XCTAssertEqual(solo.setActiveAttempts, 0)
    XCTAssertEqual(noRestartReasonNow(solo, trigger: .interruptionEnded), .soloAfterCrisis)
    XCTAssertEqual(solo.crisisCause, .interruption)
    XCTAssertTrue(solo.removalDuringInterruption, "il segno resta: lo legge solo il Direttore")
    XCTAssertEqual(solo.removalsForgotten, [])
    // Quello che il rig fa oggi, misurato (sul modello Python, con lo stesso rig): il «niente» per «solo-dopo-la-crisi» non
    // tocca il player né l'interruzione.
    XCTAssertFalse(solo.playbackStopped)
    XCTAssertTrue(solo.interrupted)
    XCTAssertFalse(solo.pendingResume)
}

// MARK: - A437 · PARTE 2 (mandato A437, par. 2.9 e 4 c; seguito 2, par. 2 voce 2): «canzone in corso» al cambio del ruolo effettivo

/// Da Follower a Direttore col motore in moto al volume 1: il click va avanti e «canzone in corso» va giù. Dopo, per il resto di
/// quella canzone, valgono le regole di oggi fuori da una canzone: una crisi dà l'arresto locale, non il «muto in canzone».
func testFromFollowerToDirectorWithTheEngineRunningTheSongInProgressGoesDown() {
    var rig = playing(.follower, route: [speaker])
    XCTAssertTrue(rig.songInProgress)
    XCTAssertEqual(rig.volume, 1.0)
    rig.roleChange(to: .direttore, at: 12.0)
    XCTAssertTrue(rig.isRunning, "col volume a 1 il motore resta in moto")
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertFalse(rig.songInProgress, "il ruolo effettivo cambia: «canzone in corso» giù")
    XCTAssertFalse(rig.playbackStopped)
    rig.interruptionBegan(at: 13.0)
    XCTAssertFalse(rig.isRunning)
    XCTAssertFalse(rig.silentInSong, "fuori da una canzone la crisi del Direttore è l'arresto locale")
    XCTAssertNil(rig.directorReturn)
}

/// Da Solo a Direttore con la levetta di Link accesa, col motore in moto al volume 1 e la canzone in corso: «canzone in corso»
/// giù; la crisi dopo è l'arresto locale del Direttore fuori da una canzone, non la ripresa del Solo né il «muto in canzone».
func testFromSoloToDirectorWithTheLinkSwitchOnTheSongInProgressGoesDown() {
    var rig = soloInSong(route: [headphones])
    XCTAssertTrue(rig.songInProgress)
    rig.userLinkSwitchedOn(to: .direttore, at: 12.0)
    XCTAssertTrue(rig.isRunning)
    XCTAssertEqual(rig.volume, 1.0)
    XCTAssertFalse(rig.songInProgress, "il ruolo effettivo cambia: «canzone in corso» giù")
    rig.routeChange(at: 13.0, to: [speaker])
    XCTAssertFalse(rig.isRunning, "U16: l'arresto locale")
    XCTAssertFalse(rig.silentInSong)
    XCTAssertEqual(rig.soloAnchorsTaken, 0)
    XCTAssertFalse(rig.soloResumePending)
    XCTAssertTrue(rig.playbackStopped)
    // Con la levetta accesa nella pausa della ripresa: la ripresa si chiude e il player va a fermo.
    var paused = soloPausedByBluetooth()
    paused.userLinkSwitchedOn(to: .direttore, at: 13.6)
    XCTAssertFalse(paused.soloResumePending)
    XCTAssertFalse(paused.songInProgress)
    XCTAssertTrue(paused.playbackStopped)
    XCTAssertEqual(paused.soloClosures, ["link-utente-acceso"])
    paused.configurationNotification(at: 13.7)
    paused.advance(to: 20.0)
    XCTAssertEqual(paused.starts, 1, "niente riparte da solo")
}

/// Da Solo a Solo (il ruolo scelto che cambia a levetta spenta): il ruolo effettivo non cambia. Col motore in moto in canzone,
/// fuori dalla pausa, «canzone in corso» resta e il Solo riprende ancora sulla canzone. Nella pausa la chiusura della ripresa
/// resta (l'annullo dei ritorni toglie la strada in volo): il player a fermo, niente riparte da solo.
func testFromSoloToSoloTheSongInProgressStaysAndInThePauseTheResumeIsClosed() throws {
    var rig = soloInSong()
    rig.roleChange(to: .solo, at: 12.0)
    XCTAssertTrue(rig.isRunning)
    XCTAssertTrue(rig.songInProgress, "da Solo a Solo «canzone in corso» non si tocca")
    rig.routeChange(at: 13.0, to: [headphones])
    XCTAssertEqual(rig.soloAnchorsTaken, 1, "in canzone il Solo riprende ancora")
    let want = try XCTUnwrap(soloBar(soloTwoSections, atOrAfter: 13.1 + rig.margin))
    rig.advance(to: want.at - 0.01)
    XCTAssertEqual(try XCTUnwrap(rig.soloFirstClickAt), want.at, accuracy: 1e-6)
    var paused = soloPausedByBluetooth()
    paused.roleChange(to: .solo, at: 13.6)
    XCTAssertFalse(paused.soloResumePending, "nella pausa la ripresa si chiude anche senza un cambio del ruolo effettivo")
    XCTAssertNil(paused.directorReturn)
    XCTAssertTrue(paused.playbackStopped)
    checkSolo(paused, "dopo il cambio da Solo a Solo nella pausa")
    paused.configurationNotification(at: 13.7)
    paused.advance(to: 20.0)
    XCTAssertEqual(paused.starts, 1)
}

// MARK: - A437 · PARTE 2 (mandato A437, par. 2.11 e 4 e): il banco del Direttore e le voci che restavano

/// C.8 (VERIFICA_REFEREE_A425, par. 3.1): il fuoco del rientro che non parte non azzera niente. La causa ricordata e lo Stop
/// voluto restano quando il fuoco esce dal ritardo (il salto al bersaglio dopo; «non certo» oltre i salti; il segno
/// «lettore-lento») o è scartato alla guardia. Lo Stop voluto si alza a mano prima del fuoco, come in
/// `testTheRejoinFireClearsTheMemoryAndU16DecidesOnTheNewCause`: nel rig un fuoco con lo Stop voluto alto non si raggiunge. In
/// ciclo sulla rottura voluta (`rejoinFireClearsMemoryAtTheTop`: l'azzeramento salito in cima al fuoco): col rig giusto la
/// memoria resta, col rig rotto si azzera a ogni fuoco, anche a quelli che non partono. Le uscite del motore che il rig non ha
/// (stato mancante, mappa e ponte, Link spento, sessione ferma, avvio cambiato) passano dalla stessa `stopRejoinEngineQ` di
/// «non certo» oltre i salti.
func testARejoinFireThatDoesNotStartClearsNothing() throws {
    for atTheTop in [false, true] {
        let tag = "azzeramentoInCima:\(atTheTop)"
        // 1. In ritardo: salta al bersaglio dopo, poi «non certo» oltre i salti.
        var late = playing(.direttore, route: [headphones], at: 10.0)
        late.rejoinFireClearsMemoryAtTheTop = atTheTop
        late.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(late.silentInSong, tag)
        XCTAssertEqual(late.crisisCause, .outputRemoved, tag)
        late.copiesDistance = 0.5
        late.start(at: 13.0, recovery: nil)
        let firstFire = try XCTUnwrap(late.rejoin, "il rientro armato").fireAt
        late.wantedStop = true
        late.advance(to: firstFire)
        XCTAssertEqual(late.lateSkips, 1, "\(tag): il primo fuoco è in ritardo")
        XCTAssertNotNil(late.rejoin, "\(tag): riarmato al bersaglio dopo")
        XCTAssertEqual(late.rejoins, 0, tag)
        XCTAssertEqual(late.crisisCause, atTheTop ? nil : .outputRemoved, "\(tag): il fuoco che salta non azzera la causa")
        XCTAssertEqual(late.wantedStop, !atTheTop, "\(tag): né lo Stop voluto")
        XCTAssertEqual(late.memoryClearedAtRejoinFire, atTheTop ? 1 : 0, tag)
        late.advance(to: 30.0)
        XCTAssertEqual(late.lateSkips, 5, "\(tag): cinque fuochi in ritardo")
        XCTAssertEqual(late.uncertainRejoins, 1, "\(tag): non-certo(ritardo-oltre-i-salti)")
        XCTAssertEqual(late.rejoins, 0, tag)
        XCTAssertFalse(late.isRunning, tag)
        XCTAssertTrue(late.silentInSong, tag)
        XCTAssertEqual(late.crisisCause, atTheTop ? nil : .outputRemoved, "\(tag): il fuoco che non parte non azzera la causa")
        XCTAssertEqual(late.wantedStop, !atTheTop, tag)
        XCTAssertEqual(late.memoryClearedAtRejoinFire, atTheTop ? 5 : 0, tag)

        // 2. Col segno «lettore-lento»: il fuoco in ritardo riarma senza azzerare; il fuoco dopo parte, e solo quello azzera.
        var slow = playing(.direttore, route: [speaker], at: 10.0)
        slow.rejoinFireClearsMemoryAtTheTop = atTheTop
        slow.engineStartDuration = 0.6849
        let bar = slow.nextBarTime(atOrAfter: 21.5)
        slow.routeChange(at: bar - 0.4131 - 0.1, to: [headphones])
        XCTAssertTrue(slow.silentInSong, tag)
        let returnAt = try XCTUnwrap(slow.directorReturn, "il ritorno dopo l'assestamento").fireAt
        slow.advance(to: returnAt)
        let armed = try XCTUnwrap(slow.rejoin, "il rientro armato dall'avvio del ritorno")
        XCTAssertTrue(armed.slowPlayer, "\(tag): armato per adesso col segno lettore-lento")
        let causeBeforeFire = slow.crisisCause
        XCTAssertNotNil(causeBeforeFire, tag)
        slow.wantedStop = true
        slow.advance(to: armed.fireAt)
        XCTAssertEqual(slow.slowPlayerFires, 1, tag)
        XCTAssertEqual(slow.rejoins, 0, tag)
        XCTAssertEqual(slow.crisisCause, atTheTop ? nil : causeBeforeFire, "\(tag): il fuoco col segno non azzera la causa")
        XCTAssertEqual(slow.wantedStop, !atTheTop, tag)
        XCTAssertEqual(slow.memoryClearedAtRejoinFire, atTheTop ? 1 : 0, tag)
        slow.advance(to: 30.0)
        XCTAssertEqual(slow.rejoins, 1, "\(tag): il fuoco dopo parte")
        XCTAssertNil(slow.crisisCause, "\(tag): e solo quello azzera la causa")
        XCTAssertFalse(slow.wantedStop, tag)
        XCTAssertEqual(slow.memoryClearedAtRejoinFire, atTheTop ? 2 : 1, tag)

        // 3. Il fuoco scartato: un'interruzione ha tolto il rientro e fermato il motore; il timer di prima scatta lo stesso.
        var stale = playing(.direttore, route: [headphones], at: 10.0)
        stale.rejoinFireClearsMemoryAtTheTop = atTheTop
        stale.routeChange(at: 12.0, to: [speaker])
        stale.start(at: 13.0, recovery: nil)
        let staleFire = try XCTUnwrap(stale.rejoin, "il rientro armato").fireAt
        XCTAssertLessThan(13.2, staleFire, "\(tag): la scena è quella: l'interruzione prima del fuoco")
        stale.interruptionBegan(at: 13.2)
        XCTAssertNil(stale.rejoin, tag)
        XCTAssertFalse(stale.isRunning, tag)
        let causeAfterBegin = stale.crisisCause
        XCTAssertNotNil(causeAfterBegin, tag)
        stale.wantedStop = true
        stale.fireRejoin(at: staleFire)
        XCTAssertEqual(stale.rejoins, 0, tag)
        XCTAssertEqual(stale.crisisCause, atTheTop ? nil : causeAfterBegin, "\(tag): il fuoco scartato non azzera la causa")
        XCTAssertEqual(stale.wantedStop, !atTheTop, tag)
        XCTAssertEqual(stale.memoryClearedAtRejoinFire, atTheTop ? 1 : 0, tag)

        // 4. Il controllo: la scena 1 senza il ritardo. Il fuoco parte e azzera, una volta.
        var fires = playing(.direttore, route: [headphones], at: 10.0)
        fires.rejoinFireClearsMemoryAtTheTop = atTheTop
        fires.routeChange(at: 12.0, to: [speaker])
        fires.start(at: 13.0, recovery: nil)
        fires.wantedStop = true
        fires.advance(to: 30.0)
        XCTAssertEqual(fires.rejoins, 1, tag)
        XCTAssertNil(fires.crisisCause, tag)
        XCTAssertFalse(fires.wantedStop, tag)
        XCTAssertEqual(fires.memoryClearedAtRejoinFire, 1, tag)
    }
}

/// B.1 (VERIFICA_REFEREE_A425, par. 3.2): dopo un rientro il Direttore segue Link fino all'avvio dopo; lo Stop non cambia niente,
/// il Play (un avvio che passa da `prepareNormalStartQ`) riporta l'assert. Col rig di prima (`useEngineAssertAtStart` spento) il
/// Direttore dopo il Play seguiva ancora Link: nessun assert, e la correzione di fase spostava lui invece di dare la fase alla
/// band. Lo stesso dopo l'altra strada che alza «segue Link»: un buco sotto la soglia, in canzone.
func testAfterARejoinTheStopAndThePlayBringTheAssertBack() throws {
    for assertAtStart in [true, false] {
        let tag = "regola:\(assertAtStart)"
        var rig = try rejoined()
        rig.useEngineAssertAtStart = assertAtStart
        XCTAssertTrue(rig.followsLink, "\(tag): dal fuoco del rientro il Direttore segue Link")
        let assertsAtFire = rig.asserts
        XCTAssertGreaterThan(assertsAtFire, 0, "\(tag): prima della crisi il Direttore dava la fase")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 60)
        XCTAssertFalse(rig.inLeadIn, "\(tag): la scorta è finita")
        XCTAssertEqual(rig.asserts, assertsAtFire, "\(tag): mentre segue Link nessun assert")
        XCTAssertEqual(rig.leadInCallsWithTheMarkUp, 0, "\(tag): nessuna chiamata della scorta col segno alto (§B.4)")
        rig.stop(at: rig.now + 0.5)
        XCTAssertFalse(rig.isRunning, tag)
        XCTAssertTrue(rig.followsLink, "\(tag): lo Stop non riporta l'assert, lo fa l'avvio")
        rig.runnerPlay(at: rig.now + 1.0)
        XCTAssertTrue(rig.isRunning, tag)
        XCTAssertFalse(rig.silentInSong, tag)
        XCTAssertEqual(rig.followsLink, !assertAtStart, "\(tag): il Play riporta il Direttore all'assert")
        let assertsAtPlay = rig.asserts
        let correctionsAtPlay = rig.corrections
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 20)
        XCTAssertEqual(rig.asserts, assertsAtPlay + (assertAtStart ? 20 : 0), "\(tag): un assert a richiamo dopo il Play")
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 1, correction: 0.02)
        XCTAssertEqual(rig.asserts, assertsAtPlay + (assertAtStart ? 21 : 0), tag)
        XCTAssertEqual(rig.corrections, correctionsAtPlay + (assertAtStart ? 0 : 1),
                       "\(tag): chi fa l'assert non si corregge su Link; il rig di prima sì")

        var hole = playing(.direttore, route: [headphones], at: 10.0)
        hole.useEngineAssertAtStart = assertAtStart
        let holeAt = hole.now + hole.bufferSeconds + 0.060
        hole.advance(to: holeAt)
        hole.scheduleNextBuffer(at: holeAt, gapSeconds: 0.060)
        XCTAssertTrue(hole.isRunning, "\(tag): sotto la soglia")
        XCTAssertTrue(hole.followsLink, "\(tag): segue Link fino al Play dopo")
        hole.stop(at: hole.now + 0.5)
        hole.runnerPlay(at: hole.now + 1.0)
        XCTAssertEqual(hole.followsLink, !assertAtStart, tag)
        let holeAsserts = hole.asserts
        hole.callbacks(from: hole.now + hole.bufferSeconds, count: 20)
        XCTAssertEqual(hole.asserts, holeAsserts + (assertAtStart ? 20 : 0), tag)
    }
}

/// La crisi del Direttore a metà canzone senza assert (referto A431, par. 2.4 b): dopo una crisi a canzone in corso (un buco del
/// render, le cuffie attaccate) e il rientro, il Direttore segue Link: nessun assert e nessuno Stop a Link dai richiami dopo la
/// scorta, da un cambio di sezione e dai richiami dopo la finestra, fino allo Stop; si corregge lui su Link, come un Follower.
/// Poi lo Stop e il Play riportano l'assert (B.1). Le scritture W2 dei confini con cambio di tempo il rig non le ha (il rig non
/// modella le scritture verso Link): qui si provano l'assert e lo Stop a Link.
/// La coda gira con `useEngineAssertAtStart` acceso e spento: col rig di prima il Play lascia il Direttore a seguire Link e
/// nessun assert torna. Fino allo Stop l'interruttore non conta: il rientro non passa da `prepareNormalStartQ`.
func testACrisisOfTheDirectorInMidSongAndItsRejoinNeverAssertUntilThePlay() throws {
    for (crisis, assertAtStart) in [("buco", true), ("cuffie", true), ("buco", false), ("cuffie", false)] {
        var rig = playing(.direttore, route: [speaker], at: 10.0)
        rig.useEngineAssertAtStart = assertAtStart
        let assertsBefore = rig.asserts
        let linkStopsBefore = rig.linkStops
        XCTAssertGreaterThan(assertsBefore, 0, "\(crisis): prima della crisi il Direttore dà la fase")
        if crisis == "buco" {
            rig.scheduleNextBuffer(at: 20.0, gapSeconds: 0.300)
        } else {
            rig.routeChange(at: 20.0, to: [headphones])
        }
        XCTAssertTrue(rig.silentInSong, crisis)
        XCTAssertFalse(rig.isRunning, crisis)
        rig.advance(to: 30.0)
        XCTAssertEqual(rig.rejoins, 1, crisis)
        XCTAssertTrue(rig.followsLink, "\(crisis): dal rientro il Direttore segue Link")
        let correctionsBefore = rig.corrections
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 300)
        XCTAssertFalse(rig.inLeadIn, crisis)
        rig.sectionChange(at: rig.now + 0.001)
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 150, correction: 0.02)
        XCTAssertEqual(rig.asserts, assertsBefore, "\(crisis): dalla crisi allo Stop nessun assert")
        XCTAssertEqual(rig.linkStops, linkStopsBefore, "\(crisis): nessuna crisi manda Stop a Link")
        XCTAssertGreaterThan(rig.corrections, correctionsBefore, "\(crisis): segue Link: si corregge lui")
        XCTAssertEqual(rig.leadInCallsWithTheMarkUp, 0, "\(crisis): nessuna chiamata della scorta col segno alto (§B.4)")
        rig.stop(at: rig.now + 0.5)
        rig.runnerPlay(at: rig.now + 1.0)
        XCTAssertEqual(rig.followsLink, !assertAtStart, "\(crisis) regola:\(assertAtStart): il Play riporta l'assert")
        let assertsAtPlay = rig.asserts
        rig.callbacks(from: rig.now + rig.bufferSeconds, count: 20)
        XCTAssertEqual(rig.asserts, assertsAtPlay + (assertAtStart ? 20 : 0),
                       "\(crisis) regola:\(assertAtStart): dopo il Play un assert a richiamo")
    }
}

/// §B.8 del seguito 4 di A421 — il controllo «in ritardo» del fuoco senza piano della scorta. A 400 BPM col ciclo d'uscita di 2048
/// campioni la scorta (otto buffer, 85,3 ms) è più di mezzo battito: il piano non c'è, e il motore guarda il bersaglio meno la
/// sola latenza. Il lettore da 150 ms arma col segno «lettore-lento» (all'armamento conta D con la scorta, nel motore e nel rig) e
/// scatta subito, 100 ms prima del bersaglio: per il motore non è in ritardo (l'ora del render è 23,3 ms prima del bersaglio) e
/// il click entra su quella battuta; il rig di prima guardava D con la scorta (108,6 ms), lo dava in ritardo e andava alla
/// battuta dopo.
func testWithoutALeadInPlanTheLateCheckOfTheFireLooksAtTheTargetMinusTheLatencyOnly() throws {
    for engine in [true, false] {
        let tag = "comeIlMotore:\(engine)"
        var rig = playing(.direttore, route: [headphones], bpm: 400, at: 10.0, cycleSeconds: 2048.0 / 48_000.0)
        rig.useEngineLateCheckWithoutLeadIn = engine
        XCTAssertEqual(rig.leadInBuffers, 8, tag)
        rig.routeChange(at: 12.0, to: [speaker])
        XCTAssertTrue(rig.silentInSong, tag)
        let bar = rig.nextBarTime(atOrAfter: 13.0)
        rig.engineStartDuration = 0.150
        rig.start(at: bar - 0.250, recovery: nil)
        let armed = try XCTUnwrap(rig.rejoin, "il rientro armato")
        XCTAssertEqual(armed.targetAt, bar, accuracy: 1e-6, "\(tag): il bersaglio è quella battuta")
        XCTAssertTrue(armed.slowPlayer, "\(tag): all'armamento conta D con la scorta: il segno lettore-lento")
        XCTAssertNil(DirectorRejoinDecision.leadIn(targetOutputTicks: rig.ticks(bar), outputLatencyTicks: rig.ticks(rig.latency),
                                                   unoBeat: rig.linkBeat(at: bar), bpm: 400, bufferFrames: 512, sampleRate: 48_000,
                                                   ioBufferSeconds: 2048.0 / 48_000.0, ticksPerSecond: OutputRig.tps),
                     "\(tag): la scena è quella: a 400 BPM con otto buffer di scorta il piano non c'è")
        rig.advance(to: bar + 1.0)
        XCTAssertEqual(rig.rejoins, 1, tag)
        XCTAssertEqual(rig.slowPlayerArms, 1, tag)
        XCTAssertEqual(rig.lateSkips, 0, tag)
        if engine {
            XCTAssertEqual(rig.slowPlayerFires, 0, "senza piano il fuoco non è in ritardo: il bersaglio meno la sola latenza")
            XCTAssertEqual(try XCTUnwrap(rig.firstClickAt), bar, accuracy: 1e-6, "il click entra su quella battuta")
        } else {
            XCTAssertEqual(rig.slowPlayerFires, 1, "il rig di prima: D con la scorta, il fuoco in ritardo")
            XCTAssertEqual(try XCTUnwrap(rig.firstClickAt), bar + rig.barSeconds, accuracy: 1e-6, "la battuta dopo")
        }
    }
}

/// §B.5 del seguito 4 di A421, rifatta col Solo in canzone sotto il guardiano — (a) in canzone la riga della misura del buco dice
/// lo stesso con la regola del ricordo (`useSilenceWriterMemory`) e senza: col guardiano scattato «buco-in-corso», scritto prima
/// della chiamata; senza guardiano «buco», scritto dalla chiamata. Questa metà NON distingue la regola: lo dice a prova, come il
/// referto del seguito 4 lo diceva a parole. (b) Una scena dove la riga cambia c'è: il guardiano zittisce, lo show si chiude
/// dentro il buco (il volume torna a 1: `muted` da vero a falso), e la chiamata del buco arriva col Solo fuori da una canzone,
/// che non scrive lo 0: con la regola la riga dice «nessuno», senza diceva «buco-in-corso» col volume a 1 (una riga falsa). Sul
/// telefono la chiusura dello show arriva di norma dopo lo Stop: è una scena di banco.
func testTheHoleMeasureOfTheSoloUnderTheGuardianWithAndWithoutTheLiftRule() {
    for rule in [true, false] {
        let tag = "regola:\(rule)"
        var guarded = soloInSongUnderGuardian()
        guarded.useSilenceWriterMemory = rule
        let last = guarded.now
        guarded.advance(to: last + 4 * guarded.bufferSeconds + 0.001)
        XCTAssertEqual(guarded.guardianFires, 1, tag)
        XCTAssertEqual(guarded.lastSilenceWrite?.reason, "buco-in-corso", tag)
        let holeAt = last + guarded.bufferSeconds + 0.300
        guarded.advance(to: holeAt)
        guarded.scheduleNextBuffer(at: holeAt, gapSeconds: 0.300)
        XCTAssertEqual(guarded.lastHoleMeasure?.writtenBy, "buco-in-corso", "\(tag): (a) col guardiano")
        XCTAssertEqual(guarded.lastHoleMeasure?.before, true, "\(tag): (a) scritto prima di questa chiamata")
        XCTAssertFalse(guarded.isRunning, "\(tag): nel Solo in canzone il buco è una crisi")

        var plain = soloInSong()
        plain.useSilenceWriterMemory = rule
        let plainHoleAt = plain.now + plain.bufferSeconds + 0.300
        plain.advance(to: plainHoleAt)
        plain.scheduleNextBuffer(at: plainHoleAt, gapSeconds: 0.300)
        XCTAssertEqual(plain.lastHoleMeasure?.writtenBy, "buco", "\(tag): (a) senza guardiano")
        XCTAssertEqual(plain.lastHoleMeasure?.before, false, "\(tag): (a) scritto da questa chiamata")

        var closed = soloInSongUnderGuardian()
        closed.useSilenceWriterMemory = rule
        let closedLast = closed.now
        closed.advance(to: closedLast + 4 * closed.bufferSeconds + 0.001)
        XCTAssertEqual(closed.guardianFires, 1, "\(tag): la scena è quella: il guardiano è scattato nel Solo in canzone")
        closed.closeShow(at: closed.now + 0.010)
        XCTAssertFalse(closed.state.muted, tag)
        XCTAssertEqual(closed.volume, 1.0, tag)
        XCTAssertEqual(closed.lastSilenceWrite?.reason, rule ? nil : "buco-in-corso", "\(tag): (b) il ricordo dopo la chiusura dello show")
        let closedHoleAt = closedLast + closed.bufferSeconds + 0.300
        closed.advance(to: closedHoleAt)
        closed.scheduleNextBuffer(at: closedHoleAt, gapSeconds: 0.300)
        XCTAssertTrue(closed.isRunning, "\(tag): fuori da una canzone il buco è solo la riga")
        XCTAssertEqual(closed.volume, 1.0, tag)
        XCTAssertEqual(closed.lastHoleMeasure?.writtenBy, rule ? "nessuno" : "buco-in-corso", "\(tag): (b) la riga della misura")
        XCTAssertEqual(closed.lastHoleMeasure?.before, !rule, "\(tag): (b)")
    }
}
}
