import Foundation

// === A421 · SEGUITO 1 (26/10/2026) — CON L'INTERRUZIONE DI SISTEMA IN CORSO NESSUNA RIPARTENZA AUTOMATICA TOCCA SESSIONE O
// MOTORE (mandato del referee «A421 · SEGUITO 1», par. 3) ===
// Il fatto (par. 3.1). La regola del 21/10 (BOX5 :1735): «durante un'interruzione niente che possa attivare la sessione; e un
// ramo nuovo che tocca sessione o motore si prova anche dentro un'interruzione.» `activateSessionAndStart` lo stato
// «interruzione di sistema» non lo guardava: il risveglio di A421 riparte con la ripresa pendente per ogni ruolo, e la
// ripresa pendente può essere alzata dentro un'interruzione o restare da una fine con l'hardware occupato; al risveglio
// dentro un'altra interruzione faceva `setCategory` e, con `isOtherAudioPlaying` falso, la `setActive`. La finestra: i
// ritorni guardano lo stato allo scatto, poi `setCategory` è sincrono e la `setActive` è in un `audioQueue.async` che non
// lo guarda; un inizio d'interruzione arrivato in mezzo (`audioQueue.sync`) passa prima della `setActive`. Un passo dopo:
// `start()` gira in un suo `audioQueue.async` chiamato dal blocco della `setActive`, quando una `setActive` riuscita ha già
// abbassato lo stato; un inizio notificato in mezzo lavora poi con lo stato alto (il rimandato, `applySampleRateQ`,
// `reconnectGraphQ` con `prepare()`, `engine.start()`). I tentativi ogni 0,5 s e la rete a 5 s rientrano senza guardarlo.
// Il 21/10 (prova B1 del collaudo di A416) la richiesta della durata del buffer e `prepare()` sono bastate [Probabile] perché
// iOS dichiarasse attiva la nostra sessione e non mandasse più la fine: la regola vale per ogni scrittura della sessione e
// per il lavoro sul motore, non solo per la `setActive`.
//
// La regola (par. 3.2): con lo stato «interruzione di sistema» alto (`_interruptionRouteQ.systemInterruption`) una
// ripartenza automatica non scrive la sessione (`setCategory`, la preferenza degli avvisi, i canali preferiti, la durata del
// buffer, `setActive`) e non lavora sul motore (`prepare`, `start`). Una sola eccezione, quella di oggi: la catena del
// ritorno in primo piano del Direttore muto in canzone (D5, referto A409 par. 8.14, LIBRO :488; costruita in A412) quando il
// suo tentativo 0 trova lo stato già alto (la fine non è arrivata, o la chiamata è ancora in corso), coi tentativi e con la
// rete a 5 s che quella catena fa partire. Per riconoscerla: un contatore degli inizi d'interruzione (un intero su
// audioQueue, alzato a ogni inizio e mai azzerato) e il segno dell'eccezione, preso al tentativo 0 di `app_wakeup` o
// `wakeup_pending_recovery` con lo stato già alto, il ruolo Direttore e il Direttore muto in canzone: il contatore della
// catena (`currentResumeToken`) e quello degli inizi. Ai punti 1 e 2 (l'ingresso e la testa del blocco della `setActive`),
// a ogni tentativo e alla rete a 5 s, l'eccezione vale se il segno è di questa catena, il contatore degli inizi non è
// cambiato, e in quel momento il ruolo è Direttore e il Direttore è muto in canzone. Al punto 3 (`start()`) mai: lì la
// `setActive` riuscita ha già abbassato lo stato, e uno stato di nuovo alto vuol dire un'interruzione cominciata dopo. Un
// inizio nuovo dopo il tentativo 0 (anche con lo stato già alto) è un'interruzione nuova: da lì vale la regola. È la strada
// d'uscita quando la fine non arriva (22/10: quattro interruzioni senza fine; BUGS v93,
// `TD-sessione-audio-spenta-dopo-interruzione-o-sfondo`); il suo prezzo resta l'Aperto C.15 di A421.
//
// Con la regola che dice no (par. 3.3): nessuna scrittura della sessione e nessun lavoro sul motore, poi: se
// `isAudioInterrupted` è vero la fine dell'interruzione ha già la sua strada e non si alza niente; se è falso e non c'è
// uno Stop voluto dopo la crisi, la ripresa pendente si alza (la recupera la fine); il Solo invece non alza mai la ripresa
// pendente: si ferma come allo Stop della console, sul principale, con la causa ricordata «interruzione»
// (`CrisisStopDecision.rememberedCause`), così fino al suo Play `RecoveryDecision` dice «niente». E all'inizio di
// un'interruzione il Solo con una ripresa pendente già alzata dalla sua catena la perde (`clearPendingResumeQ`) e si ferma
// come allo Stop della console, con la stessa causa.
//
// Par. 3.5: un avvio riuscito (`engine.start()`) chiude ogni ripresa in sospeso: `pendingResume`, `pendingResumeBeat` e
// `isAudioInterrupted` giù e il contatore della catena che sale di uno, così i tentativi in volo e le reti a 1 s e a 5 s si
// spengono da sole; con la ripresa o l'interruzione alzata lo fa `clearPendingResumeQ(reason: "avvio-riuscito")` con la sua
// riga, se no solo il contatore sale, senza riga.
// Solo Foundation: il banco `QBeatsTests` compila QBeats/Models e nient'altro.

/// Il segno dell'eccezione (par. 3.2): la catena del ritorno in primo piano del Direttore muto in canzone che al tentativo 0
/// ha trovato lo stato «interruzione di sistema» già alto.
struct InterruptionActivationException: Equatable {
    /// Il contatore della catena (`currentResumeToken`) al tentativo 0.
    let chainToken: Int
    /// Il contatore degli inizi d'interruzione al tentativo 0.
    let beginsCount: Int
}

/// I tre punti della regola (par. 3.3), col nome che va nella riga `fase:`.
enum InterruptionActivationPoint: String, Equatable, CaseIterable {
    /// `activateSessionAndStart`, dopo la regola delle ripartenze in testa: al tentativo 0 prima di `setCategory`, ai
    /// tentativi dopo il controllo della catena morta.
    case entry = "ingresso"
    /// La testa del blocco della `setActive`, dopo `mediaResetSkipsQ` (e dopo il controllo del contatore della catena).
    case setActive = "setActive"
    /// `start()`, nel blocco della coda, per le sole ripartenze automatiche, dopo la rilettura di U5.
    case start = "start"
}

/// Con la regola che dice no: che cosa resta da fare (par. 3.3).
enum InterruptionActivationRefusal: String, Equatable {
    /// Niente da alzare: `isAudioInterrupted` è vero (la fine dell'interruzione ha già la sua strada) o c'è uno Stop
    /// voluto dopo la crisi.
    case nothing = "niente"
    /// La ripresa pendente si alza (`pendingResume` vero, `pendingResumeBeat` nullo): la recupera la fine.
    case raisePending = "ripresa-pendente"
    /// Il Solo: fermo come allo Stop della console, con la causa ricordata «interruzione»; mai la ripresa pendente.
    case soloStop = "solo-fermo"
}

enum InterruptionActivationDecision {

    /// Gli inneschi della catena del ritorno in primo piano (D5).
    static func isForegroundReturn(_ trigger: RecoveryTrigger) -> Bool {
        trigger == .appWakeup || trigger == .wakeupPendingRecovery
    }

    /// Il segno dell'eccezione, preso al tentativo 0: solo per il ritorno in primo piano con lo stato già alto, il ruolo
    /// Direttore e il Direttore muto in canzone. `nil` per ogni altra catena (e a ogni tentativo che non è lo 0).
    static func exceptionMark(trigger: RecoveryTrigger,
                              attempt: Int,
                              systemInterruption: Bool,
                              playerRole: PlayerRole,
                              silentInSong: Bool,
                              chainToken: Int,
                              beginsCount: Int) -> InterruptionActivationException? {
        guard attempt == 0, isForegroundReturn(trigger), systemInterruption, playerRole == .direttore, silentInSong else {
            return nil
        }
        return InterruptionActivationException(chainToken: chainToken, beginsCount: beginsCount)
    }

    /// L'eccezione vale adesso: il segno è di questa catena, il contatore degli inizi non è cambiato, e il ruolo è Direttore
    /// muto in canzone. Al punto `start` mai.
    static func exceptionHolds(point: InterruptionActivationPoint,
                               mark: InterruptionActivationException?,
                               chainToken: Int,
                               beginsCount: Int,
                               playerRole: PlayerRole,
                               silentInSong: Bool) -> Bool {
        guard point != .start, let mark else { return false }
        return mark.chainToken == chainToken && mark.beginsCount == beginsCount
            && playerRole == .direttore && silentInSong
    }

    /// La regola: con lo stato «interruzione di sistema» basso la ripartenza tocca sessione e motore; con lo stato alto solo
    /// con l'eccezione. L'innesco e il tentativo non entrano: contano solo per il segno (`exceptionMark`).
    static func allowsActivation(point: InterruptionActivationPoint,
                                 systemInterruption: Bool,
                                 mark: InterruptionActivationException?,
                                 chainToken: Int,
                                 beginsCount: Int,
                                 playerRole: PlayerRole,
                                 silentInSong: Bool) -> Bool {
        if !systemInterruption { return true }
        return exceptionHolds(point: point, mark: mark, chainToken: chainToken, beginsCount: beginsCount,
                              playerRole: playerRole, silentInSong: silentInSong)
    }

    /// Con la regola che dice no: il Solo si ferma come allo Stop della console (mai la ripresa pendente; dopo uno Stop
    /// voluto è già fermo e non si tocca); per gli altri ruoli con `isAudioInterrupted` vero niente (la fine ha la sua
    /// strada), se no la ripresa pendente, salvo uno Stop voluto dopo la crisi.
    static func refusal(playerRole: PlayerRole,
                        isAudioInterrupted: Bool,
                        wantedStopSinceCrisis: Bool) -> InterruptionActivationRefusal {
        if playerRole == .solo { return wantedStopSinceCrisis ? .nothing : .soloStop }
        if isAudioInterrupted { return .nothing }
        return wantedStopSinceCrisis ? .nothing : .raisePending
    }

    /// Par. 3.5: dopo `engine.start()` riuscito lo sgombero con la riga, se la ripresa pendente o l'interruzione era alzata;
    /// se no solo il contatore della catena che sale.
    static func startClearsPendingWithLine(pendingResume: Bool, isAudioInterrupted: Bool) -> Bool {
        pendingResume || isAudioInterrupted
    }

    /// Par. 3.3: all'inizio di un'interruzione il Solo con la ripresa pendente già alzata dalla sua catena la perde e si
    /// ferma come allo Stop della console.
    static func soloLosesPendingAtBegin(playerRole: PlayerRole, pendingResume: Bool) -> Bool {
        playerRole == .solo && pendingResume
    }
}
