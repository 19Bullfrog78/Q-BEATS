import AVFoundation
import Combine
import Network
import os
import UIKit

// Regole thread — inviolabili:
// 1. isRunning, clickPlayhead, accentPlayhead, bufferCount, beatTotal,
//    clickSamples, accentedClickSamples, offsets, accents
//    sono accedute ESCLUSIVAMENTE su audioQueue.
// 2. clickStatus, isPlaying, beatsPerBar sono @Published:
//    ogni write avviene su DispatchQueue.main.async.
//    beatsPerBar è scritto dalla UI (main thread) tramite Picker;
//    setBeatsPerBar() dispatcha solo su audioQueue, non riscrive @Published.
// 3. audioMode è @Published e scritto SOLO su DispatchQueue.main.async.
//    applyChannelRouting(for:) riceve il mode come parametro, non legge self.audioMode.

// MARK: - AudioMode (Fase 1.5a)
enum AudioMode: Equatable {
    case base
    case pro
}

// MARK: - PlaybackState (UX-3)
enum PlaybackState {
    case stopped
    case countIn
    case playing
    case pausedAwaitingChoice(sectionName: String, songName: String)
}

// A386 · FASE B2A (2D) — cosa la macchina del Follower chiede al runner, via la stanza
// (`followerRunnerActionSubject` → `QLiveSession` → `SetlistRunner`).
enum FollowerRunnerAction: Equatable {
    /// Chiudi la canzone e arma la successiva (`armNextSong`, idempotente).
    case armNext
    /// D7-bis: riarma la stessa canzone (`armSong(currentSongIdx)`).
    case rearmSame
    /// B2b: armamento accettato dalla lista d'ingresso o da RIENTRA — arma l'inizio della canzone
    /// scelta (`armSong(index:)`); la misura l'ha già scritta il motore, nello stesso passo.
    case armSong(songIdx: Int)
}

// A412 · DIRETTORE IN CRISI, PASSO 2 (18/10/2026) — cosa il Direttore muto in canzone chiede al runner, via la
// stanza (`directorRunnerActionSubject` → `QLiveSession` → `SetlistRunner`), come `FollowerRunnerAction`.
enum DirectorRunnerAction: Equatable {
    /// Il rientro: il runner va a (canzone, sezione) senza avvio, e la sessione si aggiorna come a un avvio di
    /// sezione (mandato §2.2).
    case rejoin(songIdx: Int, sectionIdx: Int)
    /// La canzone è finita durante il silenzio e lo Stop di fine canzone è uscito: si arma la successiva
    /// (`armNextSong`), come a una fine canzone propria (mandato §2.3, D1).
    case songEndedArmNext
    /// La sessione si è fermata senza uno Stop del Direttore (scelta T6): il velo della stessa canzone.
    case rearmSame
}

// A386 · B2b-BIS (2D) — STATO E RAGIONE DELLA MACCHINA DEL FOLLOWER, PUBBLICATI INSIEME.
/// Lo specchio unico di `_followerSyncQ` e `_followerOutReasonQ` per lo schermo e la stanza: UN
/// `@Published` (`AudioEngine.followerSync`), scritto una volta per transizione in `followerApply`,
/// su main, DOPO le azioni sul runner. Con due `@Published` separati ogni transizione emetteva due
/// volte, e la prima emissione portava lo stato nuovo con la ragione vecchia: la stanza calcolava
/// una proposta falsa, con la sua riga di log (mandato del referee «A386 · B2b-BIS», 30/09/2026,
/// §3.a, dalla ratifica della B2b).
/// A386 · B2c (§3.f) — NELLO STESSO VALORE ANCHE IL SEGNALE: «sento il Direttore», «Searching…»
/// e «band playing» (la sessione Link in moto). Fino alla B2b-BIS erano tre `@Published` a
/// parte, scritti ognuno col suo passo su main: fra un passo e l'altro lo schermo calcolava una
/// faccia con valori misti (collaudo, log `A386_A1_iPad.txt`: al Play la riga del velo
/// «faccia:ready … slotE:signalOKBandPlaying» usciva prima di «inSync»). Ora stato, ragione e
/// segnale arrivano allo schermo insieme: un valore, un'emissione per passo.
struct FollowerSyncSnapshot: Equatable {
    let state: FollowerSyncState
    let outReason: FollowerOutReason?
    /// «Sento il Direttore» (`DirectorHeardTracker`: battito a 1 s, soglia 3 s, e da B2c ogni Play
    /// o Stop ricevuto dalla sessione).
    /// ⚠️ B2d: «battito a 1 s» non vale più per l'ascolto. Il Follower ascolta ogni 0,25 s col
    ///    battito suo (`followerListenQ`, `DirectorSignalCadence`); la soglia resta 3 s.
    let directorHeard: Bool
    /// «Searching…»: dal primo campione dopo che Link si accende (o dall'avvio) fino al primo
    /// verdetto — il primo colpo, o una soglia senza colpi — mai oltre la soglia
    /// (`DirectorHeardTracker.Verdict.searching`, correzione del referee al congedo 26/09 §3.3).
    let directorSearching: Bool
    /// La sessione Link è in moto («band playing — wait for the stop»): è il dato che R1 legge
    /// all'armamento, portato dal battito e dal richiamo avvio/stop.
    let linkSessionPlaying: Bool
}

// A412 · DIRETTORE IN CRISI, PASSO 2 — chi chiama `stopSync`: uno Stop voluto (ogni porta che passa da `stop()` e
// `handleStop`), l'arresto del Solo a una crisi della sessione audio (come lo Stop della sua console, ma non è uno
// Stop voluto: `RecoveryDecision` legge la causa), o la Reset dopo la Lost sul Follower (arresto locale, A360).
private enum StopOrigin {
    case wanted
    case soloCrisis
    case followerReset
}

class AudioEngine: ObservableObject {
    static let shared = AudioEngine()

    @Published var clickStatus : String  = "non caricato"
    @Published var currentBPM: Double = 120.0
    // A411 · SOLO-INERTE (18/10/2026) — LINK IN RETE: lo specchio dell'accensione (`ABLLinkSetActive`,
    // `enabled_` del ponte). Lo scrive UNA mano sola, `applyLinkActivationQ`, con l'esito della regola
    // `LinkActivationDecision` (levetta E ruolo Direttore o Follower E non sospeso dallo sfondo E l'app non
    // si chiude). In Solo è spento anche a levetta accesa. Fino ad A410 lo scrivevano due mani: il
    // richiamo del pannello Link e `setLinkEnabled` (sfondo, chiusura del pannello, Debug), che non c'è più.
    @Published private(set) var linkEnabled: Bool = false
    // A360 (16/09/2026) — L'INTERRUTTORE DI LINK DELL'UTENTE, e solo quello.
    // Il ruolo Follower (`FollowerDecision`) deve leggere la mano dell'UTENTE — `ABLLinkIsEnabled`,
    // «only controllable by the user via the Link settings dialog» (ABLLink.h) — e non
    // cambiare quando l'app va in background e torna. Questo mirror lo scrivono il
    // callback `link_engine_set_is_enabled_callback` (utente nel pannello, e la
    // riconciliazione all'avvio in `link_engine_activate` che passa dallo stesso
    // callback) e, da A411, la lettura all'avvio e la chiusura del pannello (`linkPanelClosed`), che
    // lo rileggono dal ponte. L'accensione non lo tocca: `ABLLinkSetActive` non muove
    // `ABLLinkIsEnabled`. Copia su audioQueue: `_linkUserEnabledQ`.
    @Published private(set) var linkUserEnabled: Bool = false
    @Published var linkIsConnected: Bool = false
    @Published var linkPeers: Int = 0
    // === A386 · FASE B2A (2D) — VALORI PER LO SCHERMO (B2b), SOLO MAIN ===
    // Specchi di stato che vive su audioQueue; li scrive solo il motore, la vista li legge.
    /// Numero di apparecchi collegati dalla notifica non documentata di LinkKit
    /// («ABLLink.NumberOfPeersChanged»: l'`object` è un NSNumber, nessun userInfo, su main,
    /// solo a Link acceso). `nil` = non arrivato: lo schermo lo nasconde. ⛔ Mai letto da
    /// una decisione (D5): la sincronia usa «sento il Direttore», non i peer.
    @Published private(set) var linkPeerCount: Int? = nil
    /// Start Stop Sync acceso dall'utente nel pannello Link (`ABLLinkIsStartStopSyncEnabled`).
    @Published private(set) var linkStartStopSyncEnabled: Bool = false
    /// Lo stato della macchina del Follower (`FollowerSyncDecision`) e la ragione dell'ultima
    /// uscita FUORI (o del rifiuto di un armamento), per il velo e per `RientraProposal`.
    /// B2b-BIS: UN valore solo (`FollowerSyncSnapshot`), scritto una volta per transizione:
    /// nessun lettore può vedere lo stato nuovo con la ragione vecchia.
    /// B2c (§3.f): nello stesso valore anche «sento il Direttore», «Searching…» e «band playing»,
    /// che prima erano tre `@Published` a parte (`directorHeard`, `directorSearching`,
    /// `linkSessionPlaying`: usciti). Lo scrive solo `followerPublishQ`, una volta per passo.
    @Published private(set) var followerSync = FollowerSyncSnapshot(state: FollowerSyncDecision.initial,
                                                                    outReason: nil,
                                                                    directorHeard: false,
                                                                    directorSearching: false,
                                                                    linkSessionPlaying: false)
    // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — WI-FI COLLEGATO, per la spia (A393 §6.2) ===
    // Un `NWPathMonitor` costruito per il solo Wi-Fi (Apple, `init(requiredInterfaceType:)`:
    // «Initializes a path monitor to observe a specific interface type.»), membro privato con la
    // sua coda seriale; da lì `main.async` e questo `@Published` semplice (BOX5, «Invarianti
    // tecnici Layer 3», riga «`@Published` assignment»). Collegato = `path.status == .satisfied`
    // (Apple: «The path is available to establish connections and send data.»). Non è un oggetto
    // osservabile annidato (CLAUDE.md, invariante 1). Niente ponte, niente Layer 2, niente
    // audioQueue: il monitor consegna sulla coda che gli si dà (`start(queue:)`, in `startWifiMonitor`).
    @Published private(set) var wifiConnected: Bool = false
    private let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let wifiQueue = DispatchQueue(label: "com.bullfrog.qbeats.wifi", qos: .utility)
    /// La prima consegna del monitor si logga anche se non cambia niente (il copione di collaudo
    /// vuole vedere da dove si parte); solo main.
    private var wifiReported = false
    // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — «MIDI COLLEGATO», per la spia (A393 §6.3) ===
    // Vero se l'ultimo riconto del motore MIDI ha trovato almeno una sorgente fisica presente
    // (`midi_engine_set_scan_done_callback`, registrato in `init` prima di `midi_engine_start`).
    // Scritto solo su main dal richiamo «riconto finito», che arriva sulla coda del riconto.
    @Published private(set) var midiDeviceConnected: Bool = false
    /// L'ultimo numero di apparecchi scritto nel log (-1 = mai): una riga a ogni cambio, e alla prima.
    private var midiDeviceCountReported: Int = -1
    @Published var isWaitingForLinkDownbeat: Bool = false
    // CD-Q1=B mirror UI (libro mastro v14, 28/05/2026) — Mirror @Published di
    // `_linkMode` audio-queue per consumo da UI (LiveView calcola
    // `linkRoleBadge` per LiveHeaderView). Sync nel blocco `main.async` di
    // `applySettings(_)`. Fonte di verità autoritativa resta
    // `appSettings.linkMode` (settato da SettingsView). Q-D1 ratificato:
    // AppSettings è struct, non ObservableObject → mirror obbligatorio.
    //
    // NOMENCLATURA: `currentLinkMode` (non `linkMode`) per evitare collisione
    // con la property privata `_linkMode: LinkMode` (audio-queue copy, riga
    // ~264): `@Published var linkMode` sintetizzerebbe un backing
    // `_linkMode: Published<LinkMode>` che collide letteralmente col nome
    // esistente → CI failure run 26581236612 28/05/2026 sera. Naming allineato
    // con `currentBPM`, `currentAccentPattern`, `currentSectionRepetitions`
    // già esistenti nel file (linea "current* = mirror UI di stato audio").
    @Published var currentLinkMode: LinkMode = .standalone

    // A360 — LA REGOLA DEL FOLLOWER, letta da tutti i punti della mappa (fascia, velo,
    // badge, freccia del player, RESUME, riga ambra del dettaglio, pedale MIDI):
    // Follower = ruolo `.collaborativa` E Link acceso dall'utente. L'interruttore
    // dell'app entra per essere ignorato (background e ritorno non cambiano il ruolo);
    // «almeno un collegato» decide lo slot E del velo. Solo main: legge i mirror
    // @Published. Su audioQueue lo stop del motore usa la forma nuda
    // (`FollowerDecision.isFollower(role:userLinkEnabled:)`) sulle copie di coda.
    var followerDecision: FollowerDecision {
        FollowerDecision(role: currentLinkMode,
                         userLinkEnabled: linkUserEnabled,
                         appLinkEnabled: linkEnabled,
                         anyPeerConnected: linkIsConnected)
    }

    // A411 · SOLO-INERTE — IL LUCCHETTO DEL SOLO letto su main, dagli specchi, come `followerDecision`:
    // lo legge il richiamo avvio/stop di Link, che gira su main. Su audioQueue: `soloLockPassesQ`.
    var soloInertMain: Bool {
        SoloInertDecision.isInert(role: currentLinkMode, userLinkEnabled: linkUserEnabled)
    }

    @Published var isPlaying   : Bool    = false
    @Published var beatsPerBar : UInt32  = 4 {
        didSet {
            // Strada A — Guard suppress PRIMA di guard oldValue.
            // Il ramo SEAMLESS setta _suppressBeatsPerBarDidSet=true su main
            // prima di assegnare self.beatsPerBar, per evitare che il didSet
            // chiami metronome_setBeatsPerBar (immediato, resetta
            // _currentBeatInBar nel DSP — distruggerebbe il sample-accurate
            // exchange al downbeat). L'ordine è critico: con il guard oldValue
            // prima, due sezioni con stesso BPB (es. 4/4 → 4/4) lascerebbero
            // il flag bruciato per i didSet successivi.
            if _suppressBeatsPerBarDidSet {
                os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → SKIP (suppress flag attivo)",
                       log: .default, type: .default, Int(beatsPerBar), Int(oldValue))
                _suppressBeatsPerBarDidSet = false
                return
            }
            guard beatsPerBar != oldValue else {
                os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → SKIP (valore uguale, nessun push al motore)",
                       log: .default, type: .default, Int(beatsPerBar), Int(oldValue))
                return
            }
            guard let h = metronomeHandle else { return }
            let bpb = beatsPerBar
            let oldBpb = oldValue
            let pattern = defaultAccentPattern(for: bpb)
            let mappedPattern: [UInt8] = pattern.map { $0 > 0 ? 2 : 1 }
            DispatchQueue.main.async { self.currentAccentPattern = mappedPattern }
            audioQueue.async { [h, pattern, bpb, oldBpb] in
                self._beatsPerBarQ = bpb
                metronome_setBeatsPerBar(h, bpb)
                if let lh = self.linkEngineHandle {
                    link_engine_set_quantum(lh, Double(bpb))
                }
                pattern.withUnsafeBufferPointer { ptr in
                    metronome_setAccentPattern(h, ptr.baseAddress, UInt32(pattern.count))
                }
                // RIENTRO-P2A (20/09/2026; referto A376 §2.5) — la riga «PUSH al motore» sta
                // QUI, dopo le scritture vere e sulla loro stessa coda. Prima stava nel
                // `didSet`, sul thread del chiamante, PRIMA che questo blocco fosse accodato:
                // nel log compariva prima di scritture non ancora avvenute, e un
                // `armSharedJoin` accodato prima di questo blocco leggeva ancora il
                // `_beatsPerBarQ` vecchio con la riga già stampata. Testo della riga invariato.
                os_log("[Q-BEATS][Bug2b-BPB] setBeatsPerBar req:%d old:%d → PUSH al motore (DSP + Link quantum)",
                       log: .default, type: .default, Int(bpb), Int(oldBpb))
            }
        }
    }
    @Published var currentAccentPattern: [UInt8] = [2, 1, 1, 1]
    @Published var currentSectionRepetitions: Int = 0
    @Published var channelVolumes: [Float] = [1.0, 1.0, 0.0, 0.0]
    
    // --- Variabili per DebugView (Fase 1.5a) ---
    @Published var audioMode: AudioMode = .base
    @Published var sampleRateInfo: Double = 48000.0
    @Published var currentBeat: Double = 0.0
    @Published var debugLogs: [String] = []
    // -------------------------------------------------------

    // Fase VOL — settings globali
    @Published var appSettings: AppSettings = AppSettings.load() {
        didSet {
            appSettings.save()
            applySettings(appSettings)
        }
    }

    // Fase 1.6 — MIDI Learn
    @Published var midiLearnStore: MIDILearnStore = MIDILearnStore.load()
    @Published var midiLearnPendingAction: MIDIAction? = nil

    // Beat tick discreto — PassthroughSubject, no coalescing
    let beatTickSubject = PassthroughSubject<Int, Never>()
    // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — IL LAMPO DEL PEDALE (A393 §6.4) ===
    // Emesso sul main dentro `executeMIDIAction`, dopo il passaggio al main che c'è già
    // (`handleMIDIInput`), solo quando l'azione agisce davvero (`MIDILampDecision`, punto 98 del
    // foglio Solo REV17). Stessa forma del battito (BOX5 «Feedback visivo beat»): un
    // `PassthroughSubject`, mai un `@Published` per un impulso. Porta l'azione che ha agito.
    // In M1 nessuna vista lo ascolta ancora.
    let midiActionLampSubject = PassthroughSubject<MIDIAction, Never>()
    private var beatTickCounter: Int = 0

    // === Strada A — Flag suppress per didSet di beatsPerBar ===
    // Single-shot: settato dal ramo SEAMLESS prima di assegnare
    // self.beatsPerBar. Il didSet lo legge e auto-resetta.
    // Accesso esclusivamente su main thread.
    private var _suppressBeatsPerBarDidSet: Bool = false

    // === CD-6 / Bug 4 fix (28/05/2026) — Gate anti double-emit linkStartedSubject ===
    // Settato `true` nel branch `isPlaying && !engine.isPlaying` del callback
    // Link `set_start_stop_callback`, resettato `false` in
    // `DispatchQueue.main.async` di `start()` (righe ~745-750) dove
    // `self.isPlaying = true`. Tra `engine.start()` e il flip di `isPlaying`
    // ci sono ≥3 hop di dispatch (audioQueue.async + main.async annidato) —
    // questa finestra è vulnerabile a doppio callback Link (burst peer
    // reannounce) che ri-passerebbe il guard `!engine.isPlaying`.
    // Q-D4 esteso ratificato libro mastro v15. Accesso ESCLUSIVAMENTE su main.
    private var _linkStartEmitInFlight: Bool = false

    // === Task D — Section BPM broadcast su Link ===
    // Pattern identico a L1.a (closure single-shot a beat-target).
    // Quando scheduleBPMChange viene chiamato:
    //   - il C++ DSP arma _bpmChangeDirty e applicherà _pendingBPM al prossimo
    //     downbeat (sample-accurate, atomic exchange in processBuffer);
    //   - Swift memorizza qui il valore target e il tick atteso del downbeat.
    // Nel beat-tick callback di scheduleNextBuffer, quando beatTickCounter ==
    // _pendingBPMTargetTick, propaga link_engine_set_bpm + _audioBPM +
    // midi_engine_set_bpm + currentBPM UI, in sincrono col cambio DSP.
    // Reset su setBPM (path immediato), stopSync, e auto-reset post-scatto.
    // Accesso SOLO su audioQueue.
    private var _pendingBPMValue: Double? = nil
    private var _pendingBPMTargetTick: Int = 0

    // L1.a/L1.b — segnale "fine vera della performance".
    // Esposto da AudioEngine ma emesso ESCLUSIVAMENTE dal callsite di
    // loadSection(onEnd:), che ha contesto setlist e può discriminare fine
    // intermedia da fine vera (TD #16, refactor L1.b).
    //   L1.a (DebugView): callsite emette subject prima di stop() — singola
    //     sezione di test, "fine vera" coincide con "fine sezione".
    //   L1.b (Layer 3): callsite emette subject solo nel ramo `fineSetlist`
    //     della closure end-of-section. Transizioni intermedie NON emettono.
    // LiveView ascolta per il fade del LED ultimo beat (durata pari a un
    // beat al BPM corrente, poi spegnimento). Stop manuale chiama stop()
    // senza emettere il subject — LED spento netto.
    let sectionEndedSubject = PassthroughSubject<Void, Never>()

    // CD-6 / Bug 4 fix (28/05/2026) — Opzione C orchestrazione cross-device.
    // Emesso dal callback Link `set_start_stop_callback` (chiamata a `link_engine_set_start_stop_callback`)
    // quando `engine.isPlaying` flippa false→true a causa di un Director
    // peer che ha premuto Play. LiveView observer chiama
    // `runner.startSetlist(...)` per orchestrare la sezione corrente sul
    // Follower: prima del fix, il callback Link chiamava solo
    // `engine.start()` ignorando il runner → `_sectionTotalBeats=0` su
    // Follower → check `_sectionTotalBeats > 0` non passava → counter
    // macrobar all'infinito + nome canzone non mostrato (Problema B / Bug 4).
    // ⚠️ MARCATURA A240 (28/08) — l'observer oggi sceglie `startCurrentSong`
    //    (standby) o `startCurrentSection` (conserva il punto): `startSetlist`
    //    non è più su questo percorso. Testo sopra invariato.
    // Gate anti double-emit: `_linkStartEmitInFlight` (vedi callback).
    // Gate idempotenza observer: `guard session.playbackState != .playing`
    // in LiveView (Q-D3 ratificato). NB: in modalità Direttore (linkMode ==
    // .direttore) il guard early-return riga ~432 del callback impedisce
    // di entrare nel branch — il Subject NON viene emesso quando Q-BEATS è
    // sorgente. Q-D2/Q-D3/Q-D4 ratificati libro mastro v15.
    let linkStartedSubject = PassthroughSubject<Void, Never>()

    // === A386 · FASE B2A (2D) — DUE SOGGETTI PER LA STANZA, emessi su main ===
    /// La macchina del Follower chiede al runner di armare: la stanza (`QLiveSession`) lo
    /// ascolta accanto a `linkStartedSubject`.
    let followerRunnerActionSubject = PassthroughSubject<FollowerRunnerAction, Never>()
    /// Il Direttore ha fermato a canzone in corso (D3): porta `falseStart` (D7-bis) calcolato
    /// sui numeri di Link. Emesso PRIMA del `.stopped` del motore: la stanza decide cosa fare
    /// del runner (`DirectorSongCloseDecision.onStop`) e scrive `.standby` prima che lo
    /// specchio di `LiveView` veda il `.stopped`.
    let directorStoppedSubject = PassthroughSubject<Bool, Never>()
    // === A412 · DIRETTORE IN CRISI, PASSO 2 (18/10/2026) — IL DIRETTORE MUTO IN CANZONE, per la stanza ===
    /// Il Direttore muto in canzone chiede al runner: la sezione d'arrivo del rientro, la canzone finita durante il
    /// silenzio, il velo della stessa canzone (`DirectorRunnerAction`). Emesso su main; la stanza (`QLiveSession`)
    /// lo ascolta accanto a `followerRunnerActionSubject`.
    let directorRunnerActionSubject = PassthroughSubject<DirectorRunnerAction, Never>()
    /// Il tasto della fascia (e il pedale playPause) col Direttore muto in canzone: l'esito di
    /// `DirectorTransportDecision` (Play = rientra, Stop = ferma la band e chiude la canzone); `nil` = nessun
    /// silenzio, il tasto com'è oggi. Solo main: lo scrivono `publishDirectorSilenceQ` (da audioQueue, con
    /// `main.async`) e lo Stop voluto (`stopSync`). La stanza lo porta nella sessione (`LiveSession.directorSilence`).
    @Published private(set) var directorSilence: DirectorSilence? = nil

    // UX-3 — state machine playback
    @Published var playbackState: PlaybackState = .stopped

    // UX-2 — DND Reminder
    @Published var shouldShowDNDReminder: Bool = false
    private var dndReminderShownThisSession = false
    /// A405 — la chiusura dell'avviso già scritta da SwiftUI nel binding (`setDNDReminderPresented`), finché il
    /// `@Published` non si abbassa sul main. Non pubblica: la legge solo `isDNDReminderPresented`.
    private var dndReminderClosing = false

    // Placeholder L3 — sostituiti dalla song/section model di Layer 3
    var currentSection: String? = nil
    var currentSong: String? = nil

    private var tapTempoEngine = TapTempoEngine()

    private func applySettings(_ s: AppSettings) {
        audioQueue.async { [weak self] in
            guard let self = self,
                  let mh = self.metronomeHandle else { return }
            self.accentVolume = s.accentVolume
            self.beatVolume   = s.beatVolume
            self.subdivVolume = s.subdivVolume
            metronome_set_accent_volume(mh, s.accentVolume)
            metronome_set_beat_volume(mh, s.beatVolume)
            metronome_set_subdiv_volume(mh, s.subdivVolume)
            self._clickMuted = s.clickMuted
            // A386 · FASE B2A (2D) — un cambio di ruolo azzera la macchina del Follower.
            // A411 · SOLO-INERTE — e ricalcola l'accensione di Link (mano «ruolo»): Link va in rete alla
            // scelta di Director o Follower, ne esce tornando a Solo.
            if self._linkMode != s.linkMode {
                // A421 — prima del ruolo nuovo: col motore in moto a volume 0 l'arresto locale come lo Stop, e lo stato
                // dell'uscita giù (mandato A421, par. 2.3 c).
                self.handleRoleOrLinkChangeQ(reason: "cambio-di-ruolo")
                self._linkMode = s.linkMode
                self.followerResetQ(reason: "cambio-di-ruolo")
                // A412 — un cambio di ruolo chiude il silenzio del Direttore (il coordinatore è solo suo) e il
                // «segue Link» dopo un rientro.
                self.leaveDirectorSilenceQ(reason: "cambio-di-ruolo", closeAnchor: true)
                self._directorFollowsLinkQ = false
                self.applyLinkActivationQ(trigger: .role)
            } else {
                self._linkMode = s.linkMode
            }
            // Layer 1 non riceve mai il mute — beat events continuano a scattare.
            self.ch1Volume = s.ch1Volume
            self.ch2Volume = s.ch2Volume
            self.ch3Volume = s.ch3Volume
            self.ch4Volume = s.ch4Volume
            self.ch1MixerNode.outputVolume = s.ch1Volume
            self.ch2MixerNode.outputVolume = s.ch2Volume
            self.ch3MixerNode.outputVolume = s.ch3Volume
            self.ch4MixerNode.outputVolume = s.ch4Volume
            let vols = [s.ch1Volume, s.ch2Volume, s.ch3Volume, s.ch4Volume]
            let linkModeMirror = s.linkMode
            DispatchQueue.main.async {
                self.channelVolumes = vols
                // CD-Q1=B mirror UI — sync @Published `currentLinkMode` dal
                // valore appena applicato a `_linkMode` audio-queue. Cattura
                // locale per evitare read di `s` su main (s.linkMode è copia
                // di valore struct, ma `linkModeMirror` rende l'intent esplicito).
                self.currentLinkMode = linkModeMirror
            }
            os_log("applySettings accent=%.2f beat=%.2f subdiv=%.2f muted=%{public}@ ch=[%.2f,%.2f,%.2f,%.2f]",
                   log: .default, type: .default,
                   s.accentVolume, s.beatVolume, s.subdivVolume, "\(s.clickMuted)",
                   s.ch1Volume, s.ch2Volume, s.ch3Volume, s.ch4Volume)
        }
    }

    private var metronomeHandle      : MetronomeHandle?
    private var midiEngineHandle     : MIDIEngineHandle? = nil
    // === MODIFICATO 6A ===
    private var linkEngineHandle     : LinkEngineHandle? = nil
    private(set) var linkSettingsPresenter: LinkSettingsPresenter?

    // === Task D refactor #18 — Atomic pending + sink node audio-thread ===
    // linkPending: ponte lockfree fra audioQueue (arming) e render thread
    // (sink block). Allocato in init(), distrutto in deinit() DOPO detach
    // del sink node (Correzione 1 referee — evita use-after-free).
    // Vedi QBeatsAtomics.h per dettagli RT-safety.
    private let linkPending: OpaquePointer
    // === Task D refactor #18c ===
    // AVAudioSinkNode (refactor #18) sostituito da installTap su
    // engine.mainMixerNode (refactor #18c) perche' il sink in
    // multi-destination da playerNode non veniva mai invocato dal
    // render thread (diagnosi #18b: zero log A/B/C/D). Vedi
    // installLinkTap() per setup del tap RT-equivalente.

    // === AGGIUNTO 6C — timebase cachato all'avvio ===
    private let machTimebase: mach_timebase_info_data_t = {
        var tbi = mach_timebase_info_data_t()
        mach_timebase_info(&tbi)
        return tbi
    }()

    // === A408 (15/10/2026) — MOTORE E NODI SI RICREANO DOPO IL RESET DEI SERVIZI AUDIO ===
    // `engine`, `playerNode` e, più sotto, `backtrackPlayerNode`, `ch1MixerNode`…`ch4MixerNode`,
    // `ch3PlayerNode`, `ch4PlayerNode` sono `var`: la ricostruzione al primo avvio dopo il reset
    // (`rebuildAfterMediaResetQ`, chiamata da `start()`) li sostituisce con oggetti nuovi.
    // Dopo la nascita (gli inizializzatori qui sotto) si SCRIVONO SOLO su audioQueue, lì dentro.
    // ⚠️ RISCRITTO A420 (23/10/2026). Il testo di prima diceva «Si leggono su audioQueue; fuori da audioQueue si usano solo
    // le copie prese dentro un `audioQueue.sync` (`stopSync`, inizio di un'interruzione).»: lo `stopSync` e l'inizio di
    // un'interruzione fermavano lettore e motore fuori dalla coda, sulle copie. Da A420 si fermano sulla coda, nello stesso
    // blocco che abbassa `isRunning` (`stopPlayerAndEngineQ`, mandato A420, par. 2.1), e quelle copie non ci sono più. Si
    // leggono su audioQueue. `deinit` non gira mai: `shared` è una `static let`.
    private var engine               = AVAudioEngine()
    private var playerNode           = AVAudioPlayerNode()
    // ⚠️ RISCRITTO A416 (21/10/2026). Il testo di prima diceva «Fase 1.5a: sampleRate dinamico — aggiornato da
    // AVAudioSession dopo setActive(true)»: la scrivevano `setupSession`, `setupGraph` e il cambio di percorso, dalla
    // sessione, e il DSP restava indietro. Da A416 la scrive solo `applySampleRateQ`, dalla fonte unica
    // (`SampleRateDecision`: il nodo d'uscita, poi la sessione), insieme al DSP, ai campioni del click e alla durata del
    // buffer chiesta (mandato «USCITA-AUDIO-PASSO-1», §2.1). Nasce 48000, come la preferita della sessione.
    private var sampleRate           : Double = 48000.0
    private let bufferSize           : AVAudioFrameCount = 512
    private let maxBeats             : Int = 16

    // --- Stato audio: accesso SOLO su audioQueue ---
    private var clickSamples              : [Float] = []
    private var accentedClickSamples      : [Float] = []
    private var subdivisionClickSamples   : [Float] = []
    private var isRunning            = false
    private var bufferCount          : Int = 0
    private var beatTotal            : Int = 0
    private var clickPlayhead        : Int = -1
    private var accentPlayhead       : Int = -1
    private var subdivPlayhead       : Int = -1
    private var _clickMuted: Bool = false   // accesso SOLO su audioQueue
    private var _linkMode: LinkMode = .standalone   // accesso SOLO su audioQueue
    // A360 — copia su audioQueue di `linkUserEnabled` (la mano dell'utente): la legge
    // `stopSync()` dentro `audioQueue.sync` per decidere se lo stop parte verso Link.
    private var _linkUserEnabledQ: Bool = false   // accesso SOLO su audioQueue
    // === A411 · SOLO-INERTE (18/10/2026) — L'ACCENSIONE DI LINK, accesso SOLO su audioQueue ===
    // I due ingressi della regola d'accensione (`LinkActivationDecision`) che non hanno già una copia di
    // coda (la levetta è `_linkUserEnabledQ`, il ruolo `_linkMode`): la sospensione decisa dalla politica
    // dello sfondo e la chiusura dell'app (`disableLinkOnTerminate`). E l'ultimo esito dato al ponte (`nil` =
    // mai, prima dell'avvio). ⚠️ A412: la politica dello sfondo la valuta il motore (`sceneEnteredBackground`,
    // `sceneBecameActive`, chiamati da `QBeatsApp`); prima la valutava `QBeatsApp` e la passava con
    // `setLinkBackgroundSuspended`, uscita. `_linkBackgroundSuspendedQ` è anche il segno «sospeso da noi».
    private var _linkBackgroundSuspendedQ: Bool = false
    private var _linkTerminatingQ: Bool = false
    private var _linkActiveAppliedQ: Bool? = nil
    /// Le righe del lucchetto quando scarta qualcosa che arriva da Link: una per strada, a frequenza
    /// limitata (`SoloInertDiscardLog`, al più una ogni `kSoloInertLogIntervalSeconds`).
    private var _soloInertTempoLogQ: SoloInertDiscardLog = .start
    private var _soloInertTransportLogQ: SoloInertDiscardLog = .start
    private static let kSoloInertLogIntervalSeconds: Double = 2.0
    // === A400 · R1 (10/10/2026) — IL SEGNO DEL PROPRIO AVVIO, accesso SOLO su audioQueue ===
    // Dice «ho scritto io». Si alza subito prima di ognuna delle tre scritture con cui questo
    // apparecchio annuncia «suona» a Link (`link_engine_start_at_beat_zero`,
    // `link_engine_start_at_beat`, `link_engine_join_running_session`); lo consuma il richiamo
    // avvio/stop di Link quando gli torna indietro il proprio avvio (passo di coda del richiamo,
    // in `init`; regola e banco: `LinkTransportCallbackDecision`). Così un avvio comandato da
    // questo apparecchio non gli torna indietro come avvio di un altro: prima il Solo con Link
    // acceso partiva due volte, e il secondo avvio riazzerava il contatore di sezione dopo il
    // primo colpo (referto A399 §5).
    // Per costruzione, non per tempi: non legge `isPlaying` e non confronta ore; chi lo alza e
    // chi lo consuma stanno su questa coda, nell'ordine dei fatti.
    // Se l'eco non arriva resta alzato fino all'arresto. Lo abbassano `stopSync`, i tre arresti
    // che non passano da `stopSync` (inizio di un'interruzione, cambio di topologia, cambio di
    // configurazione) e il `catch` di `start()`: ogni blocco di coda che scrive `isRunning = false`
    // lo abbassa prima di finire (`lowerOwnTransportStartQ`).
    // ⚠️ A416 (21/10/2026): gli arresti che non passano da `stopSync` sono anche, da A412, quelli locali della Lost e
    // del reset (`beginLocalStopQ`) e, da A416, il cambio di frequenza dal percorso a motore in moto
    // (`handleRouteChange`, motivo «frequenza»); la regola qui sopra vale anche per loro.
    // ⚠️ A411 · SOLO-INERTE — nel Solo il segno si alza lo stesso, come a Link spento (inerte fino allo
    //    stop), ma la scrittura «suona» non esce (lucchetto, `SoloInertDecision`), e il richiamo avvio/stop
    //    nel Solo si scarta in testa: da A411 il passo di coda che lo consumava non lo raggiunge nessuno.
    private var _ownTransportStartPendingQ: Bool = false
    // === A408 (15/10/2026) — IL RESET DEI SERVIZI AUDIO, accesso SOLO su audioQueue ===
    // Tre stati: «normale», «servizi persi» (fra la Lost e la Reset), «da ricostruire» (dopo la
    // Reset, fino alla ricostruzione al primo avvio, in `start()`). Regola e banco:
    // `MediaServicesResetDecision` (Models/).
    private var _mediaServicesQ: MediaServicesState = MediaServicesResetDecision.initial
    // Quante Lost e quante Reset sono arrivate dall'avvio dell'app: il numero delle righe [RESET].
    private var _mediaLostCountQ: Int = 0
    private var _mediaResetCountQ: Int = 0
    // Alzato da una ricostruzione riuscita, abbassato dal primo `engine.start()` riuscito dopo:
    // la riga «primo avvio dopo il reset» esce una volta.
    private var _firstStartAfterMediaResetQ: Bool = false
    // === A410 (16/10/2026) — DIRETTORE IN CRISI, PASSO 1: IL CONTEGGIO IN SILENZIO, accesso SOLO su audioQueue ===
    // Il motore conta i battiti sulla mappa della canzone; quando il motore del Direttore in canzone tace
    // senza Stop prende un'àncora; finché l'àncora vive scrive una riga al secondo con la posizione della
    // band. ⚠️ RISCRITTO A412 (18/10/2026). Il testo di prima diceva «Solo misure: niente di quello che segue
    // cambia cosa esce verso Link, i rami di `start()`, lo `stopSync` [...]» e «al primo `start()` scrive cosa
    // farebbe il rientro»: era vero del passo 1. Da A412 l'àncora è l'ingresso del coordinatore del rientro
    // (`coordinateDirectorRejoinQ`, dentro `start()`), che decide e agisce: rientro, Stop di fine canzone,
    // silenzio. Tipi puri e banchi: `ShowClock`, `DirectorRejoinDecision` (Models/). Le funzioni stanno prima di
    // `start(resumeAtBeat:trigger:)`, blocchi «A410» e «A412».
    /// La mappa della canzone che parte e il suo indice nella scaletta: le consegna il runner a ogni
    /// avvio di canzone (`setSongMap`, accanto a `setSongFirstBeatsPerBar`). Copia di coda.
    private var _songMapQ: SongMap? = nil
    private var _songMapSongIdxQ: Int = -1
    /// La sezione della mappa che il motore sta contando (da 0): quella di partenza alla consegna,
    /// +1 a ogni scambio SEAMLESS di `scheduleNextBuffer`. -1 = nessuna mappa.
    private var _songMapSectionQ: Int = -1
    /// Un battito contato: sezione della mappa, battito nella sezione (da 0: il contatore di sezione
    /// prima del suo incremento; -1 in un ciclo, dove il contatore non conta) e ora d'uscita.
    private struct CountedBeat: Equatable {
        let section: Int
        let beatInSection: Int
        let outTicks: UInt64
    }
    /// Gli ultimi due battiti contati: l'àncora prende il più recente già uscito, non uno solo
    /// accodato (mandato A410, §2.3). Li azzera ogni avvio del motore.
    private var _lastCountedBeatQ: CountedBeat? = nil
    private var _prevCountedBeatQ: CountedBeat? = nil
    /// L'àncora del silenzio del Direttore e l'avvio della sessione letto all'àncora (per il giudice
    /// «stesso avvio»). Il resto di quello che Link diceva all'àncora sta nella riga che la prende.
    /// A412 — e le sezioni della canzone della mappa: al rientro il motore carica da qui la sezione d'arrivo
    /// e la successiva. (Fino ad A411 c'era anche `ownStopSent`, «uno Stop è uscito verso Link con l'àncora
    /// viva»: lo `stopSync` della Reset dopo la Lost. Da A412 nessuna crisi manda Stop a Link, e uno Stop
    /// voluto chiude l'àncora prima di uscire: il campo non aveva più niente da dire.)
    /// A412 · SEGUITO 2 — `startBeatQBig`: il battito dell'avvio nella numerazione della sessione
    /// (`DirectorRejoinDecision.sessionQuantum`), quello che il giudice «stesso avvio» confronta; `startBeatQ1`
    /// resta per le righe, accanto. Il conto (`clock`) ha l'àncora nella numerazione della sessione.
    private struct SilenceAnchor {
        let clock: ShowClock
        let songIdx: Int
        let sections: [SongSection]
        let cause: String
        let takenTicks: UInt64
        let startTicks: UInt64
        let startBeatQ1: Double
        let startBeatQBig: Double
    }
    /// L'àncora viva; `nil` = niente da contare. ⚠️ RISCRITTO A412: la prende solo il Direttore che entra nel
    /// silenzio in canzone (`enterDirectorSilenceQ`); la chiudono il rientro riuscito, uno Stop voluto
    /// (`stop()`, `stopSync`), lo Stop di fine canzone, la sessione ferma da altri (T6), l'uscita dal
    /// coordinatore, il cambio di ruolo, la levetta spenta e la chiusura dello show. Prima diceva «la chiudono
    /// il primo `start()` che prosegue [...]; lo `stopSync` della Reset no»: era il passo 1.
    private var _silenceAnchorQ: SilenceAnchor? = nil
    /// Il margine del bersaglio del rientro (progetto A376, P9) e la finestra del cambio di sezione,
    /// in buffer: i 100 del passo (f) del ramo SEAMLESS di `scheduleNextBuffer`.
    private static let kRejoinMarginSeconds: Double = 0.150
    private static let kRejoinSectionWindowBuffers: Int = 100
    // === A412 (18/10/2026) — DIRETTORE IN CRISI, PASSO 2: IL SILENZIO CHE AGISCE, accesso SOLO su audioQueue ===
    // Mandato del referee «DIRETTORE-IN-CRISI-PASSO-2». Le regole sono pure e col loro banco in Models/
    // (`CrisisStopDecision`, `DirectorRejoinDecision`, `DirectorTransportDecision`, `RecoveryDecision`,
    // `LinkActivationDecision.suspendsOnBackground`); qui lo stato, il collegamento nel blocco «A412».
    /// Le sezioni della canzone della mappa (`setSongMap`), per l'àncora: al rientro la sezione d'arrivo.
    private var _songSectionsQ: [SongSection] = []
    /// La mappa è arrivata per il prossimo avvio (`setSongMap`, subito prima di `start()` nel runner): quell'avvio
    /// è l'avvio di una canzone. Lo consuma l'avvio che non passa dal coordinatore (`prepareNormalStartQ`).
    private var _songMapForNextStartQ: Bool = false
    /// «Canzone in corso» per `CrisisStopDecision`: il motore è partito per una canzone del runner e nessuno Stop
    /// lo ha fermato dopo. Lo abbassano `stopSync`, lo Stop di fine canzone, la sessione ferma da altri e la
    /// chiusura dello show; un rientro lo lascia alzato.
    private var _songInProgressQ: Bool = false
    /// Il Direttore è muto in canzone (`CrisisStopOutcome.silentInSong`), dalla crisi fino al rientro riuscito, a
    /// uno Stop voluto, allo Stop di fine canzone, alla sessione ferma da altri, all'uscita dal coordinatore, al
    /// cambio di ruolo, alla levetta spenta, alla chiusura dello show.
    private var _directorSilentInSongQ: Bool = false
    /// La causa dell'ultima crisi dall'ultimo avvio che non passa dal coordinatore (`RecoveryDecision`).
    private var _crisisCauseQ: CrisisCause? = nil
    /// Uno Stop voluto (o lo Stop di fine canzone, o la sessione ferma da altri) dopo l'ultima crisi: nessuna
    /// ripartenza automatica (`RecoveryDecision`).
    private var _wantedStopSinceCrisisQ: Bool = false
    /// Dopo un rientro il Direttore segue Link — la correzione di fase del Follower in `scheduleNextBuffer` —
    /// invece dell'assert, fino all'avvio dopo (scelta T4); il richiamo del tempo di Link non rilancia `_audioBPM`.
    private var _directorFollowsLinkQ: Bool = false
    /// Il rientro è armato e non ancora suonato (`armDirectorRejoinQ` → `fireDirectorRejoinQ`): il tasto, in
    /// attesa, dice Stop.
    private var _rejoinArmedQ: Bool = false
    /// La chiusura di fine sezione del runner, l'ultima consegnata (`loadSection`, `preloadNextSection`): è una
    /// sola per la vita del runner e legge gli indici al momento dell'esecuzione (`SetlistRunner`, in testa).
    private var _songSectionEndClosureQ: (() -> Void)? = nil
    /// Lo Stop di fine canzone armato durante il silenzio, e la sua ora d'invio.
    private var _songEndStopWorkQ: DispatchWorkItem? = nil
    private var _songEndStopPlannedTicksQ: UInt64? = nil
    /// A412 · SEGUITO 3 — LE DUE ATTESE CHE MIRANO A UN'ORA: l'armamento del rientro (`armDirectorRejoinQ`, il work
    /// item in `pendingLinkStart`) e lo Stop di fine canzone (`scheduleDirectorSongEndStopQ`, il work item in
    /// `_songEndStopWorkQ`). Le aspetta `StrictOneShotTimer` (colpo singolo, flag `.strict`, margine di 1 ms) invece
    /// di `asyncAfter`, che al collaudo dell'IPA #776 ha fatto scattare l'armamento fino a 135,7 ms dopo l'ora chiesta.
    /// Il work item è quello di prima e il timer lo esegue su questa coda; ogni percorso che annulla o azzera il
    /// work item ferma anche il timer. Solo su audioQueue.
    private lazy var _rejoinArmTimerQ = StrictOneShotTimer(queue: audioQueue)
    private lazy var _songEndStopTimerQ = StrictOneShotTimer(queue: audioQueue)
    /// La riga «Stop di fine canzone NON inviato» esce una volta per silenzio.
    private var _songEndNotSentLoggedQ: Bool = false
    /// L'ultimo esito del tasto mandato allo specchio `directorSilence`: la riga [DIR-TASTO] esce ai cambi.
    private var _directorSilencePublishedQ: DirectorSilence? = nil
    /// Il primo buffer della scorta muta del rientro, all'ora chiesta al lettore (`scheduleBuffer(_:at:)`, scelta T5);
    /// `nil` = nessuno in attesa. E l'ora d'uscita dei tre buffer accodati al fuoco, per l'ora dei battiti contati.
    /// ⚠️ RISCRITTO A412 · SEGUITO 2 (2/2) (18/10/2026). Il testo di prima diceva «Il primo buffer del rientro, all'ora
    /// chiesta al lettore (`scheduleBuffer(_:at:)`, scelta T5); `nil` = nessuno in attesa. E l'ora d'uscita dei tre
    /// buffer del rientro, per l'ora dei battiti contati.»: il buffer ancorato era quello del bersaglio. Da qui è il
    /// primo della scorta (`DirectorRejoinDecision.leadIn`), `scorta` buffer prima dell'ora del bersaglio, e i tre
    /// buffer del fuoco sono muti; senza scorta resta quello del bersaglio.
    private var _anchoredFirstBufferQ: AVAudioTime? = nil
    private var _anchoredOutputTicksQ: UInt64 = 0
    private var _anchoredPreRollLeftQ: Int = 0
    /// A412 · SEGUITO 2 (2/2) — LA SCORTA MUTA DEL RIENTRO, viva dal fuoco al primo click (l'«uno»): il piano
    /// (`DirectorRejoinDecision.LeadIn`), l'ora del bersaglio, un buffer in battiti al tempo della sezione d'arrivo, le
    /// correzioni di fase fatte prima del click (al più una: `leadInAllowsCorrection`) e la loro somma in battiti, e
    /// il MIDI tenuto zitto finché l'«uno» non cade nel buffer (`leadInHoldsMIDI`). Nella scorta il motore non suona
    /// niente prima dell'«uno» (`scheduleNextBuffer`). La chiude il primo click (`noteRejoinFirstClickQ`), un rientro
    /// fermato (`stopRejoinEngineQ`) o un avvio (`start()`). Solo su audioQueue.
    private struct RejoinLeadIn {
        let plan: DirectorRejoinDecision.LeadIn
        let targetTicks: UInt64
        let bufferBeats: Double
        var corrections: Int = 0
        var correctionBeats: Double = 0
        var midiHeld: Bool = true
    }
    private var _rejoinLeadInQ: RejoinLeadIn? = nil
    // === A386 · FASE B2A (2D) — LO STATO DEL 2D, accesso SOLO su audioQueue ===
    // La macchina del Follower, il segnale «sento il Direttore», la ripetizione del Direttore
    // e la fase di avvio per la falsa partenza vivono qui; gli specchi @Published sopra.
    private var _startStopSyncEnabledQ: Bool = false
    private var _followerSyncQ: FollowerSyncState = FollowerSyncDecision.initial
    private var _followerOutReasonQ: FollowerOutReason? = nil
    private var _heardTrackerQ: DirectorHeardTracker = .start
    private var _directorHeardQ: Bool = false
    private var _lastTimelineWriteCountQ: UInt64 = 0
    /// B2d — il giro a quattro valori della ripetizione (`DirectorReannounceDecision.Cycle`): prima
    /// era il segno alternato. Avanza solo quando il ponte ha scritto davvero.
    private var _reannounceCycleQ: DirectorReannounceDecision.Cycle = .start
    private var _reannounceCountQ: UInt64 = 0
    private var _lastReannouncedIsPlayingQ: Bool? = nil
    private var _lastReannounceSkipQ: String? = nil
    private var _pulseCountQ: UInt64 = 0
    /// Fase di sessione (quantum 1e6) dell'ultimo avvio agito (Follower) o scritto (Direttore):
    /// il primo termine della falsa partenza (D7-bis). `nil` = nessun avvio in corso.
    private var _startPhaseQ: Double? = nil
    /// Battiti per battuta della PRIMA sezione della canzone armata/in corso (Q10, D7-bis):
    /// lo scrive il runner, non il motore (che al richiamo porta ancora la sezione precedente).
    private var _songFirstBeatsPerBarQ: UInt32 = 4
    /// B2b (A2): «show aperto» = il runner nello slot della stanza. Lo alza `QLiveSession.install`,
    /// lo abbassano END SHOW e l'uscita dalla stanza (`setShowOpen`). Il Direttore ripete solo a
    /// show aperto. Copia di coda; nessuno specchio: lo legge solo `directorPulse`.
    private var _showOpenQ: Bool = false
    /// B2b — le copie di coda di «Searching…» e «band playing». B2c: con `_directorHeardQ`,
    /// `_followerSyncQ` e `_followerOutReasonQ` sono i cinque campi di `FollowerSyncSnapshot`.
    private var _directorSearchingQ: Bool = false
    private var _linkSessionPlayingQ: Bool = false
    // === A386 · FASE B2c (2D) — DA SOLO IL FOLLOWER SUONA LA SUA CANZONE, accesso SOLO su audioQueue ===
    /// L'orologio proprio fino all'arresto (`FollowerLinkFollowDecision`): si alza entrando in DA
    /// SOLO (`followerTransitionQ`), lo abbassano `stopSync`, `start()` e un `reset` della
    /// macchina. Copre la coda fra l'uscita da DA SOLO e l'arresto vero del motore, che arriva
    /// da main.
    private var _ownClockUntilStopQ: Bool = false
    /// Il tempo di sessione adottato dal richiamo del tempo di Link DOPO l'ultimo tempo dato dalla
    /// propria canzone (`applyBPM`, cambio di sezione al battere). `nil` = il tempo in corso è
    /// della propria canzone. Alla soglia di DA SOLO dice se c'è un tempo da ridare al motore.
    private var _linkTempoAdoptedQ: Double? = nil
    /// Il tempo che il metronomo sta suonando ADESSO: lo scrive chi dà un tempo al DSP
    /// (`applyBPM`, il cambio di sezione al battere, il richiamo del tempo di Link quando adotta,
    /// il ritorno al tempo della sezione alla soglia di DA SOLO). Diverso da `_audioBPM` solo nel
    /// battito fra lo scambio di sezione e il battere, e quando il tempo viene da Link. È il
    /// tempo con cui si àncora la linea propria.
    private var _engineTempoQ: Double = 120.0
    /// LA LINEA DEL TEMPO PROPRIA (`OwnClockTimeline`): in DA SOLO prende il posto di quella di
    /// Link nella correzione a ogni buffer, e tiene il click sull'ora dell'apparecchio anche
    /// quando i buffer arrivano in ritardo. `nil` = da ancorare al prossimo buffer del tratto:
    /// all'ingresso in DA SOLO e a ogni cambio di tempo della propria canzone. Attraversa
    /// un'interruzione (è fatta di ore); la butta `stopSync`.
    private var _ownTimelineQ: OwnClockTimeline? = nil
    /// L'ora d'uscita del buffer in corso (`scheduleNextBuffer`), per l'ora dell'ultimo battito.
    private var _bufferOutTicksQ: UInt64 = 0
    /// Per la riga al secondo di DA SOLO: dove è caduto l'ultimo battito — il campione del flusso
    /// d'uscita (indice del buffer × 512 + scostamento) e l'ora d'uscita — scritti a ogni battito;
    /// e il riferimento (battito, campione, ora) della riga precedente, da cui si misura il tempo.
    private var _lastBeatSampleQ: Int64 = 0
    private var _lastBeatOutTicksQ: UInt64 = 0
    private var _ownClockLogRefTickQ: Int = 0
    private var _ownClockLogRefSampleQ: Int64 = 0
    private var _ownClockLogRefOutTicksQ: UInt64 = 0
    /// Dall'ultima riga al secondo: quanti buffer riportati sulla linea propria, il ritardo più
    /// grande riassorbito (ms), quanti cambi di tempo di sessione ignorati.
    private var _ownClockPinsQ: Int = 0
    private var _ownClockMaxLagMsQ: Double = 0.0
    private var _ownClockIgnoredTempoQ: Int = 0
    /// B2c-BIS — il tempo della sessione Link letto dall'ultimo battito a 1 s del Follower (0 a
    /// ponte spento). Solo per la riga di log di W2 saltata in DA SOLO: così al confine di
    /// sezione non serve una cattura di Link in più.
    private var _sessionTempoSeenQ: Double = 0.0
    private var transportPulseTimer: DispatchSourceTimer? = nil
    // === A386 · FASE B2d (2D) — L'ASCOLTO DEL FOLLOWER, accesso SOLO su audioQueue ===
    /// Il battito d'ascolto a 0,25 s (`startFollowerListen`): sorgente GCD su audioQueue.
    private var followerListenTimer: DispatchSourceTimer? = nil
    /// Le letture d'ascolto fatte da Follower dall'avvio dell'app (campo `letture` dei log).
    private var _listenCountQ: UInt64 = 0
    /// Il conto dei vuoti dell'ascolto (`DirectorHeardGapMeter`): solo per le righe di log.
    private var _heardGapMeterQ: DirectorHeardGapMeter = .start
    private var peerCountObserver: NSObjectProtocol? = nil   // solo main
#if DEBUG
    // RIENTRO-P1 (A366, 17/09/2026) — INTERRUTTORE SOLO DEBUG PER LA PROVA A/B DELLA
    // DECISIONE 9.1 (referto A364, §5.e e §9.1): «chi porta i cambi di tempo quando il
    // Direttore tace». Acceso (default) = comportamento di oggi: il Follower scrive il tempo
    // su Link al proprio confine di sezione (W2). Spento = il Follower salta W2.
    // ⛔ ESISTE SOLO SOTTO `#if DEBUG`: in Release W2 resta identico a oggi, e nessuna
    //    decisione di prodotto lo legge. Non è una regola: è uno strumento di misura, da
    //    togliere quando Mauro ha deciso la 9.1.
    // Il valore NON si conserva: vive finché l'app non si chiude, e nasce sempre acceso.
    // Due copie, come `linkUserEnabled`/`_linkUserEnabledQ`: questo mirror lo legge la
    // `DebugView` su main; la copia di coda qui sotto la legge `scheduleNextBuffer` su
    // audioQueue. Tutte e due le scrive solo `setDebugFollowerBoundaryTempoWrite`.
    @Published private(set) var debugFollowerBoundaryTempoWrite: Bool = true
    private var _debugFollowerBoundaryTempoWriteQ: Bool = true   // accesso SOLO su audioQueue
    // A416 (21/10/2026) — IL CAMPIONATORE DEL TIMBRO DIETRO L'INTERRUTTORE (mandato «USCITA-AUDIO-PASSO-1», §2.5), sulla
    // forma di W2 qui sopra: esiste solo in DEBUG, nasce spento a ogni avvio e non si conserva. Questo specchio lo legge
    // la `DebugView` su main; il timer vive su `startStampQueue`. Lo scrive solo `setDebugStartStampSampler`.
    @Published private(set) var debugStartStampSampler: Bool = false
#endif
    private var _audioBPM: Double = 120.0   // accesso SOLO su audioQueue
    // DEFAULT DEVE COINCIDERE con @Published var beatsPerBar (didSet non scatta in init)
    private var _beatsPerBarQ: UInt32 = 4   // accesso SOLO su audioQueue
    // === L1.a — Sezione corrente (mirror su audioQueue) ===
    // Sincronizzati via loadSection(beatsPerBar:repetitions:onEnd:).
    // _sectionTotalBeats = 0 → nessun limite (loop infinito o sezione non caricata).
    // _onSectionEnd è single-shot: consumata (settata nil) sull'ultimo beat per evitare double-fire.
    private var _sectionTotalBeats: Int = 0
    private var _sectionBeatCounter: Int = 0
    private var _onSectionEnd: (() -> Void)? = nil
    // === L1.a — Drain mode dopo fine sezione ===
    // Quando il counter raggiunge il totale, _sectionEndPending viene settato.
    // I buffer successivi NON chiamano metronome_processBuffer (no beat fantasma)
    // ma continuano a drenare clickPlayhead/accentPlayhead/subdivPlayhead esistenti.
    // Quando tutti i playhead sono < 0 → dispatch _pendingEndClosure → stop reale.
    // Sample-accurate: il dispatch arriva quando l'ultimo click è stato riprodotto
    // integralmente, non con timer arbitrari su main thread.
    private var _sectionEndPending: Bool = false
    private var _pendingEndClosure: (() -> Void)? = nil

    // === Strada A — Pre-load nuova sezione (audioQueue-private) ===
    // Riempiti da preloadNextSection() chiamato dal SetlistRunner all'inizio
    // della sezione corrente con i parametri della sezione N+1. Consumati e
    // azzerati nel ramo SEAMLESS del beat callback quando
    // _sectionBeatCounter >= _sectionTotalBeats. Tutti nil → ramo DRAIN.
    private var _pendingNextBPM: Double? = nil
    private var _pendingNextBPB: UInt32? = nil
    private var _pendingNextAccentPattern: [UInt8]? = nil
    private var _pendingNextSectionTotalBeats: Int? = nil
    private var _pendingNextOnSectionEnd: (() -> Void)? = nil
    private var _pendingNextRepetitions: Int? = nil
    // ATOM C — subdivision/swing della sezione N+1 (viaggiano col preload,
    // armate al downbeat nel ramo SEAMLESS via metronome_schedule_subdivision).
    private var _pendingNextSubdivisionMultiplier: UInt8? = nil
    private var _pendingNextSwingRatio: Double? = nil

    private var offsets              : [UInt32]
    private var accents              : [UInt8]
    private var isBeats              : [UInt8]

    // Fase VOL — volumi su audioQueue
    private var accentVolume: Double = 1.0
    private var beatVolume:   Double = 0.8
    private var subdivVolume: Double = 0.4

    // === AGGIUNTO 6C — Link phase sync (accesso solo su audioQueue) ===
    private var outputLatencyTicks : UInt64 = 0
    private var bufferDurationTicks: UInt64 = 0

#if QB_DIAG_SPY
    // === Bug 2.b — SPIA passiva L3 (asse CONTATORE + griglia). OFF salvo QB_DIAG_SPY. ===
    // Marker in SOLA LETTURA: gridBeat (engine, sync a Link) al 1° beat di sezione.
    // Mai variabile di produzione, mai scritto nel path audio di emissione.
    // La round()/modulo della fase derivata-griglia si calcola al FLUSH (offline).
    private var _spySectionStartMarker: Double = 0.0
    private var _spySectionInstanceIdx: Int = 0
    private var _spyMarkerPending: Bool = true   // cattura il marker al 1° beat di sezione
#endif

    // QA-1 drift analysis — eseguito su audioQueue
    private var qa1BeatCounter: UInt64 = 0
    private var qa1StartTime: UInt64 = 0  // mach_absolute_time al beat 0

    // === Blocco 7 — Silent Ticking (accesso SOLO su audioQueue) ===
    // Il clock C++ (metronome, MIDI, Link) non si ferma mai durante le interruzioni.
    // Solo l'audio layer (AVAudioEngine + playerNode) viene sospeso.
    private var isAudioInterrupted:  Bool = false
    private var clockLinkWasEnabled: Bool = false
    // A416 (21/10/2026) — qui c'era `lastInterruptionResumeTime`, l'ora dell'ultima ripresa da un'interruzione: la
    // leggevano solo i 20 s del cambio di configurazione, usciti con la regola di stato (`EngineConfigChangeDecision`).
    private var pendingResume: Bool = false
    private var pendingResumeBeat: Double? = nil
    private var currentResumeToken: Int = 0
    // Beat assoluto di clock al momento del Play originale — usato per snap relativo.
    private var _startAbsoluteBeat: Double = 0.0
    // Bug 2.b ramo X — offset d'ingresso del Follower in BEAT (multiplo di bpb
    // su downbeat); 0 per Director/standalone/resume. Seminato nel work item
    // SHARED prima del pre-roll; letto da LiveView al primo tick per allineare
    // sectionStartTick (visivo). Accesso scrittura su audioQueue, lettura su main.
    private(set) var startBeatOffset: Int = 0
    // Opzione B — Link downbeat wait (accesso SOLO su audioQueue)
    private var pendingLinkStart: DispatchWorkItem? = nil
    // RIENTRO-P1 (17/09/2026) — GENERAZIONE DELL'INGRESSO PENDENTE (accesso SOLO su
    // audioQueue). Ogni armamento di `armSharedJoin` e ogni annullo (`cancelPendingJoin`)
    // la alzano di uno; il work item cattura il valore con cui è nato e al fuoco lo
    // ricontrolla: se non coincide è un fuoco ORFANO e non tocca né il motore né Link.
    // Nasce dal collaudo del 17/09/2026 (referto A364, §3.d e §4.3): un cambio di
    // configurazione durante l'attesa d'ingresso lasciava DUE work item armati, e il
    // secondo fuoco azzerava il seme appena scritto dal primo.
    private var joinGeneration: Int = 0
    // Build 303 — salta sync Link nei primi 3 buffer dopo fresh play
    private var linkSyncSkipBuffers: Int = 0
    // L1.b sync investigation — conta 3 buffer dopo cambio BPM per log DIRECTOR-ASSERT
    private var _linkSyncLogBuffers: Int = 0
    // === A420 (23/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 1: LA CATENA DEI BUFFER HA UN NUMERO, accesso SOLO su audioQueue ===
    // Mandato A420, par. 2.2, con la risposta del referee (par. 1-2); regola e banco in `BufferChainGeneration` (Models/).
    // ⚠️ NON è `joinGeneration` (qui sopra): quella numera gli armamenti dell'ingresso e del rientro, e scarta un fuoco
    // orfano; questa numera le catene dei buffer del lettore del click, e scarta il richiamo di un buffer di una catena
    // finita. Le righe di `joinGeneration` dicono «generazione:», quella dello scarto dice «catena:».
    /// La generazione corrente della catena: nasce 0; sale a ogni passaggio di `isRunning` da falso a vero (`start()`) e
    /// prima del primo buffer di ogni catena che comincia (`openBufferChainQ`).
    private var _bufferChainGenerationQ: Int = BufferChainGeneration.initial
    /// I richiami scartati dall'avvio dell'app: il numero della riga `[SCHED] richiamo di un'altra catena scartato`.
    private var _bufferChainDiscardedQ: Int = 0
    // === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: LE CUFFIE E IL BUCO DEL RENDER, accesso SOLO su audioQueue ===
    // Mandato del referee «USCITA AUDIO PASSO 2a PEZZO 2». Le regole sono pure, col loro banco, in Models/
    // (`OutputRouteDecision`, `OutputReturnDecision`, `RenderGapDecision`, `LateBeatDecision`, `TransportStateDecision`; le
    // cause e gli inneschi nuovi in `CrisisStopDecision` e `RecoveryDecision`); qui lo stato, e il collegamento nel blocco
    // «A421» prima di `start()`. Il volume del mixer principale ha un solo padrone: `_outputSilenceQ.muted`.
    /// «Uscita zittita» (il volume del mixer principale a 0), «uscita mancante» e la memoria dell'ultima uscita da cui il
    /// click è uscito a volume 1 (U3, U5).
    private var _outputSilenceQ = OutputSilenceState.initial
    /// Il ritorno del Direttore in attesa (U6, par. 2.2 b): l'innesco, che cosa aspetta, l'ora dell'armamento; il suo timer.
    private struct DirectorReturnWaitQ {
        let trigger: RecoveryTrigger
        let wait: DirectorReturnWait
        let armedTicks: UInt64
    }
    private var _directorReturnQ: DirectorReturnWaitQ? = nil
    private lazy var _directorReturnTimerQ = StrictOneShotTimer(queue: audioQueue)
    /// Il ritorno del Follower (par. 2.2 c, g): l'ora della notizia (o del tocco), l'armamento alla prima chiamata di
    /// `scheduleNextBuffer` dopo, la catena dei buffer con cui è armato. Il volume torna nella chiamata che produce il
    /// buffer dell'«uno», prima di calcolarlo (U3 c): nessun timer.
    /// A421 · SEGUITO 1 (par. 2.2): porta la scadenza (le due ore, anche per il tocco), il battito dell'«uno» col suo
    /// orologio (`FollowerReturnUno`; `nil` = «uno non calcolabile»: il volume torna alla prima chiamata col primo campione
    /// a volume 1 alla scadenza o dopo) e l'ora dell'«uno» riletta a ogni chiamata dal battito (`unoTicks`). Fino al
    /// seguito portava la sola ora dell'«uno», con `?? scadenza` che fondeva l'«uno» e la scadenza.
    private struct FollowerReturnQ {
        let noticeTicks: UInt64
        let fromTap: Bool
        var armPending: Bool
        var chain: Int
        var deadlineTicks: UInt64 = 0
        var uno: FollowerReturnUno? = nil
        var unoTicks: UInt64? = nil
    }
    private var _followerReturnQ: FollowerReturnQ? = nil
    /// La rete del motore fermo dal sistema (par. 2.2 a): il timer, la catena con cui è armata, i richiami contati e
    /// l'ora dell'ultimo buffer programmato.
    private lazy var _stoppedEngineNetTimerQ = StrictOneShotTimer(queue: audioQueue)
    private var _stoppedEngineNetChainQ: Int? = nil
    private var _stoppedEngineCallbacksQ: Int = 0
    private var _lastScheduledTicksQ: UInt64 = 0
    /// L'origine del DSP, il battito passato a `metronome_reset_for_start` (U9: la griglia dei battiti è l'origine più un
    /// intero); il battito zittito in questo buffer; i battiti zittiti dall'avvio del motore (azzerato a ogni `start()`).
    private var _dspOriginBeatQ: Double = 0
    private var _muteLateBeatThisBufferQ: Bool = false
    private var _lateBeatsMutedQ: Int = 0
    /// Il battito (del sequencer) dell'ultimo «uno» uscito: l'«uno» della linea propria del Follower DA-SOLO (par. 2.2 c).
    private var _lastUnoBeatQ: Double? = nil
    // RIENTRO-P2A (20/09/2026) — campionatore diagnostico del timbro dell'avvio (solo log):
    // vedi `startStartStampSampler`. Il timer e l'ultimo campione scritto vivono su
    // `startStampQueue`; su audioQueue gira solo la lettura.
    // ⚠️ A416 (21/10/2026): la funzione è `startStartStampSamplerQ`, solo DEBUG, e la chiama l'interruttore
    // (`setDebugStartStampSampler`); il timer si crea e si annulla su `startStampQueue`.
    private let startStampQueue = DispatchQueue(label: "com.bullfrog.qbeats.timbro", qos: .utility)
    private var startStampTimer: DispatchSourceTimer? = nil
    private var lastSampledStartStamp: StartStampSample? = nil   // accesso SOLO su startStampQueue

    // === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: LA FREQUENZA DA UNA FONTE SOLA, IL BUCO DEL RENDER ===
    // Mandato del referee «USCITA-AUDIO-PASSO-1». Le regole sono pure, col loro banco, in Models/ (`SampleRateDecision`,
    // `EngineConfigChangeDecision`, `RenderGapMeter`, `AudioErrorText`); qui lo stato, accesso SOLO su audioQueue. Il
    // collegamento sta nel blocco «A416» accanto a `setupGraph`.
    /// Lo specchio della frequenza del DSP: la scrive solo `applySampleRateQ`, insieme a `metronome_set_sample_rate`.
    /// Nasce col valore di `metronome_create` in `init` (la copia del motore alla nascita, 48000): il DSP non si rilegge,
    /// core_engine non cambia.
    private var _dspSampleRateQ: Double = 48000.0
    /// La frequenza con cui sono stati fatti i campioni del click, e quella dell'ultima durata del buffer chiesta alla
    /// sessione (0 = mai).
    private var _clickSampleRateQ: Double = 0
    private var _ioBufferRequestRateQ: Double = 0
    /// Il misuratore del buco del render, a ogni `scheduleNextBuffer` (solo registro, mandato §2.3).
    private lazy var _renderGapMeterQ = RenderGapMeter(bufferFrames: Int(bufferSize), sampleRate: sampleRate,
                                                       ticksPerSecond: ticksPerSecond)
    /// L'ultimo cambio di percorso (l'ora d'arrivo, letta nel gestore prima del salto su audioQueue, e il motivo) e
    /// l'ora dell'ultimo cambio di configurazione del motore corrente: la riga del buco li confronta col buco.
    private struct RouteChangeMark {
        let ticks: UInt64
        let reason: String
    }
    private var _lastRouteChangeQ: RouteChangeMark? = nil
    private var _lastConfigChangeTicksQ: UInt64? = nil
    /// La riga del tempo del click ogni 32 battiti: il battito, l'ora d'uscita e il campione del battito della riga di
    /// prima (preso di nuovo al primo battito di ogni avvio).
    private var _tempoLogRefTickQ: Int = 0
    private var _tempoLogRefOutTicksQ: UInt64 = 0
    private var _tempoLogRefSampleQ: Int64 = 0
    /// A416 · SEGUITO 2 (21/10/2026) — l'interruzione di sistema in corso e il cambio di percorso rimandato
    /// (`InterruptionRouteDecision`, mandato del referee «A416 · SEGUITO 2», §2). Separato da `isAudioInterrupted`, che è lo
    /// stato della ripresa. Accesso SOLO su audioQueue; lo cambiano `noteSystemInterruptionQ`, il cambio di percorso e chi
    /// esegue il rimandato (la fine dell'interruzione, `start()`).
    private var _interruptionRouteQ = InterruptionRouteState.initial
    /// A421 · SEGUITO 1 (par. 3.2) — il contatore degli inizi d'interruzione (alzato a ogni inizio, mai azzerato) e il segno
    /// dell'eccezione: la catena del ritorno in primo piano del Direttore muto in canzone partita con lo stato già alto
    /// (`InterruptionActivationDecision`). Accesso SOLO su audioQueue.
    private var _interruptionBeginsQ: Int = 0
    private var _interruptionExceptionQ: InterruptionActivationException? = nil

    // --- Backtrack state: accesso SOLO su audioQueue ---
    // A408 — `var`: si ricrea dopo il reset dei servizi audio (cartello su `engine`).
    private var backtrackPlayerNode = AVAudioPlayerNode()
    private var backtrackBuffer: AVAudioPCMBuffer? = nil
    private var backtrackArmed: Bool = false

    // --- Mixer 4 canali ---
    // A408 — `var`, come i due lettori qui sotto: si ricreano dopo il reset dei servizi audio
    // (cartello su `engine`).
    private var ch1MixerNode = AVAudioMixerNode()   // Click / Metronomo
    private var ch2MixerNode = AVAudioMixerNode()   // Backtrack musicale
    private var ch3MixerNode = AVAudioMixerNode()   // Guide vocals (disabilitato senza HW Pro)
    private var ch4MixerNode = AVAudioMixerNode()   // FX ambientali (disabilitato senza HW Pro)

    private var ch3PlayerNode = AVAudioPlayerNode()
    private var ch4PlayerNode = AVAudioPlayerNode()

    // Volumi indipendenti per canale — accesso SOLO su audioQueue
    private var ch1Volume: Float = 1.0
    private var ch2Volume: Float = 1.0
    private var ch3Volume: Float = 0.0   // disabilitato di default
    private var ch4Volume: Float = 0.0   // disabilitato di default

    // ------------------------------------------------

    private let audioQueue = DispatchQueue(label: "com.bullfrog.qbeats.audio", qos: .userInteractive)

    init() {
        offsets  = [UInt32](repeating: 0, count: maxBeats)
        accents  = [UInt8](repeating: 0, count: maxBeats)
        isBeats  = [UInt8](repeating: 0, count: maxBeats)

        // === Task D refactor #18 — alloca atomic pending struct ===
        // Una sola malloc, mai dal render thread. RT-safe per design.
        guard let pending = qbeats_link_pending_create() else {
            fatalError("[Q-BEATS] qbeats_link_pending_create failed (OOM)")
        }
        self.linkPending = pending

        metronomeHandle = metronome_create(sampleRate, 120.0)
        midiEngineHandle = midi_engine_create()
        // midi_engine_start() sta più sotto, dopo link_engine_create() e link_engine_activate() —
        // Link registra il suo listener UDP multicast prima che CoreMIDI
        // apra virtual ports e scan queue. Previene contesa rete al boot.
        // A408 — prima qui c'era «spostato dopo setupGraph()», vero fino ad A405: da A406
        // setupGraph() gira su audioQueue e midi_engine_start() sul thread principale, senza un
        // ordine fra loro (referto A406, §8.1).
        // === MODIFICATO 6A ===
        linkEngineHandle = link_engine_create()
        if let lh = linkEngineHandle {
            linkSettingsPresenter = LinkSettingsPresenter(linkHandle: lh)
        }

        if let lh = linkEngineHandle {
            link_engine_set_tempo_callback(lh, { bpm, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async {
                    // A411 · SOLO-INERTE — IL LUCCHETTO, prima di tutto: nel Solo il tempo della sessione non
                    // entra nel motore (niente metronomo, MIDI, `currentBPM`), e il ruolo Direttore con la
                    // levetta spenta non lo ribatte su Link. Una riga a frequenza limitata.
                    if !engine.soloLockPassesQ(.sessionTempo) {
                        engine.noteSoloInertDiscardQ(.sessionTempo, detail: String(format: "bpm:%.4f", bpm))
                        return
                    }
                    // Modalità Direttore: non subisce MAI il BPM del peer (Bug 5-BPM chiuso).
                    // ⚠️ RISCRITTO A412 · SEGUITO 1 (18/10/2026). Il testo di prima diceva: «Affinamento
                    // 29/05/2026 (test R2/R6 su device): - In play: re-broadcasta _audioBPM e vince la
                    // negoziazione Link (check bpm != _audioBPM evita loop quando il peer rimanda il valore
                    // Q-B). - In stop: NON adotta il BPM del peer e NON combatte la sessione, così un Follower
                    // in START LOCAL (CD-6) può seguire il tempo della propria setlist. Il return (sotto)
                    // garantisce entrambi: il Direttore esce sempre prima del blocco di adozione interna
                    // (metronome / MIDI / currentBPM, righe seguenti).» Il codice leggeva «in play» come
                    // «motore in moto» (`isRunning`), e il motore è in moto anche mentre il Direttore muto in
                    // canzone aspetta il rientro (A412, da `start()` col bersaglio al fuoco): lì ribatteva il
                    // tempo della sezione di prima e la band lo adottava (collaudo di A412, prova P2-bis, la
                    // sezione a 110 suonata a 90). Da qui decide `DirectorTempoRebroadcastDecision`: il
                    // Direttore ribatte `_audioBPM` solo se suona davvero la sua linea — motore in moto, non
                    // muto in canzone (attesa del rientro compresa), non «segue Link» dopo un rientro (T4) — e
                    // se il richiamo porta un tempo diverso dal suo (il controllo contro il rimpallo, com'era).
                    // In ogni altro caso niente verso Link. Come prima, il Direttore esce sempre qui, prima del
                    // blocco di adozione interna (metronomo, MIDI, `currentBPM`).
                    if engine._linkMode == .direttore {
                        let role = PlayerRoleDecision.playerRole(role: engine._linkMode,
                                                                 userLinkEnabled: engine._linkUserEnabledQ)
                        let echo = DirectorTempoRebroadcastDecision.outcome(playerRole: role,
                                                                            engineRunning: engine.isRunning,
                                                                            silentInSong: engine._directorSilentInSongQ,
                                                                            followsLink: engine._directorFollowsLinkQ,
                                                                            callbackTempo: bpm,
                                                                            ownTempo: engine._audioBPM)
                        switch echo {
                        case .rebroadcast:
                            if let lh = engine.linkEngineHandle {
                                link_engine_set_bpm(lh, engine._audioBPM)
                            }
                        case .hold(.silentInSong):
                            // A412 · SEGUITO 1 — muto in canzone (attesa del rientro compresa) il Direttore non
                            // ribatte il tempo: una riga a richiamo, col tempo del richiamo, `_audioBPM` e il rientro
                            // armato o no.
                            os_log("[Q-BEATS][DIR-RIENTRO] muto in canzone - tempo della sessione bpm:%.4f non ribattuto (motore:%.4f) rientroArmato:%d",
                                   log: .default, type: .default, bpm, engine._audioBPM, engine._rejoinArmedQ ? 1 : 0)
                        case .hold(.followsLink):
                            // A412 — dopo un rientro il Direttore segue Link fino all'avvio dopo (scelta T4): il tempo
                            // della sessione non si ribatte con `_audioBPM` e non entra nel motore (il tempo delle
                            // sezioni lo porta la canzone, al confine). Una riga a richiamo.
                            os_log("[Q-BEATS][DIR-RIENTRO] segue Link - tempo della sessione bpm:%.4f non ribattuto (motore:%.4f)",
                                   log: .default, type: .default, bpm, engine._audioBPM)
                        case .hold:
                            // Motore fermo senza crisi, o lo stesso tempo: niente, senza riga (com'era).
                            break
                        }
                        return
                    }
                    // A386 · FASE B2c (2D) — DA SOLO IL TEMPO DELLA SESSIONE NON ENTRA NEL MOTORE.
                    // È una delle due strade da cui la sessione Link arriva al click del Follower
                    // (l'altra è la correzione di fase in `scheduleNextBuffer`). La decisione è
                    // una, pura (`FollowerLinkFollowDecision`), letta qui su audioQueue dalla copia
                    // della macchina: Follower in DA SOLO (o nella coda prima dell'arresto) ⇒ il
                    // cambio di tempo si ignora — niente metronomo, niente MIDI, niente
                    // `currentBPM` — con una riga di log. IN SYNC e FUORI: il blocco qui sotto,
                    // identico a prima. Il Solo e il ruolo Follower con la levetta spenta da A411 non
                    // arrivano qui: li ferma il lucchetto in testa al blocco.
                    if !engine.followsLinkQ() {
                        engine.logSessionTempoIgnoredQ(bpm)
                        return
                    }
                    // A400 · R1 — una riga di registro, nessun cambio di comportamento: il tempo che
                    // il richiamo porta, quello che il motore suonava (`_engineTempoQ`, letto prima che
                    // il blocco sotto lo riscriva) e se sono diversi (`adottato:1`: il motore cambia
                    // tempo; `adottato:0`: aveva già quello). Fino a oggi questo ramo era muto
                    // (referto A399 §5.4, il «secondo eco»).
                    os_log("[Q-BEATS][LINK][TEMPO] richiamo bpm:%.4f motore:%.4f adottato:%d",
                           log: .default, type: .default,
                           bpm, engine._engineTempoQ, bpm != engine._engineTempoQ ? 1 : 0)
                    // Il tempo in corso viene dalla sessione: alla soglia di DA SOLO il motore
                    // torna a quello della propria sezione (`followerEnterOwnClockQ`).
                    engine._linkTempoAdoptedQ = bpm
                    engine._engineTempoQ = bpm
                    if let h = engine.metronomeHandle {
                        metronome_setBPM(h, bpm)
                    }
                    if let mh = engine.midiEngineHandle {
                        midi_engine_set_bpm(mh, bpm)
                    }
                    DispatchQueue.main.async { engine.currentBPM = bpm }
                }
            }, Unmanaged.passUnretained(self).toOpaque())

            link_engine_set_is_connected_callback(lh, { isConnected, ctx in
                guard let ctx = ctx else { return }
                // Callback su main thread (LinkKit 3.2.2)
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                // RIENTRO-P2A — TIMBRO a ogni fronte del collegato: che cosa riporta Link
                // (si suona, ora dell'avvio, battito dell'avvio) nel momento in cui la
                // connessione cade o torna, accanto a quello che crede il motore. Solo
                // lettura, solo log. Va su audioQueue perché la cattura dello stato di Link
                // vive lì (vedi `logStartStamp`); è un `async` senza attesa.
                engine.audioQueue.async {
                    engine.logStartStamp(isConnected ? "fronte-collegato-si" : "fronte-collegato-no")
                }
                DispatchQueue.main.async {
                    engine.linkIsConnected = isConnected
                }
            }, Unmanaged.passUnretained(self).toOpaque())

            link_engine_set_peers_changed_callback(lh, { ctx, count in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                // già su main thread (LinkKit 3.2.2)
                engine.linkPeers = Int(count)
            }, Unmanaged.passUnretained(self).toOpaque())

            // === Reattività pane Ableton — ABLLinkSetIsEnabledCallback ===
            // Callback main-thread quando l'utente flicca toggle Link nel pane
            // Ableton (ABLLink.h:153-159).
            // A411 · SOLO-INERTE — il richiamo porta la levetta, e basta. Fino ad A410 il C++ accendeva Link
            // da sé (`enabled_` + `ABLLinkSetActive`) e qui `linkEnabled` si scriveva come la levetta: con la
            // levetta accesa il telefono entrava in rete anche in Solo. Ora la levetta è un ingresso della
            // regola d'accensione: `noteUserLinkSwitchQ` la scrive (e, se si spegne, azzera la macchina del
            // Follower e nasconde il numero dei collegati, come prima), poi la funzione unica
            // (`applyLinkActivationQ`, mano «levetta») decide e scrive `linkEnabled`, `linkIsConnected` e
            // `linkPeers`.
            link_engine_set_is_enabled_callback(lh, { isEnabled, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async { [weak engine] in
                    guard let engine = engine else { return }
                    if engine.noteUserLinkSwitchQ(isEnabled, source: "pannello Link / avvio") {
                        engine.applyLinkActivationQ(trigger: .userSwitch)
                    }
                }
            }, Unmanaged.passUnretained(self).toOpaque())

            // === A386 · FASE B2A (2D) — Start Stop Sync: il richiamo di cambio ===
            // LinkKit lo invoca sul thread principale quando l'utente muove l'interruttore nel
            // pannello Link (ABLLink.h:161-167). Copia di coda per le decisioni
            // (`_startStopSyncEnabledQ`), specchio su main per lo schermo — lo schema di
            // `_linkUserEnabledQ`/`linkUserEnabled` qui sopra. La prima lettura, col getter,
            // sta dopo `link_engine_activate` (il richiamo arriva solo ai cambi).
            link_engine_set_start_stop_sync_enabled_callback(lh, { isEnabled, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                engine.audioQueue.async { [weak engine] in
                    guard let engine = engine else { return }
                    engine._startStopSyncEnabledQ = isEnabled
                    DispatchQueue.main.async { engine.linkStartStopSyncEnabled = isEnabled }
                    os_log("[Q-BEATS][2D][STARTSTOPSYNC] enabled:%d (pannello Link) - ruolo:%{public}@",
                           log: .default, type: .default,
                           isEnabled ? 1 : 0, String(describing: engine._linkMode))
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        // === AGGIUNTO 6D — Start/Stop sync callback da peer Link ===
        //
        // CD-6 / Bug 4 fix (28/05/2026) — Opzione C: oltre a propagare lo
        // start/stop al motore audio locale, emette `linkStartedSubject` per
        // far orchestrare LiveView (→ runner.startSetlist). Senza emit il
        // Follower partirebbe audio ma con `_sectionTotalBeats=0` → counter
        // all'infinito + nome canzone non mostrato (Bug 4 / Problema B).
        // ⚠️ MARCATURA A240 (28/08) — oggi l'orchestrazione va a
        //    `startCurrentSong`/`startCurrentSection` (conserva il punto):
        //    `startSetlist` non è più su questo percorso. Testo sopra invariato.
        //
        // Doppia protezione anti race:
        //  (1) Gate `_linkStartEmitInFlight` lato AudioEngine (qui sotto):
        //      evita doppia emissione se il callback arriva 2 volte ravvicinato
        //      prima che `engine.isPlaying` flippi a true (≥3 hop dispatch fra
        //      `engine.start()` audioQueue.async e `main.async` riga ~745).
        //  (2) Gate `playbackState != .playing` lato LiveView observer
        //      (Q-D3 ratificato).
        // Q-D4 esteso ratificato libro mastro v15.
        if let lh = linkEngineHandle {
            link_engine_set_start_stop_callback(lh, { isPlaying, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>
                    .fromOpaque(ctx).takeUnretainedValue()
                // A411 · SOLO-INERTE — IL LUCCHETTO, prima di tutto: nel Solo il richiamo avvio/stop di Link non
                // fa partire né fermare niente (niente sonde di registro, niente macchina, niente `start()` o
                // `stop()`). Si legge dagli specchi di main, come `followerDecision` più sotto: il richiamo gira
                // su main. Una riga a frequenza limitata, su audioQueue.
                if engine.soloInertMain {
                    engine.audioQueue.async {
                        engine.noteSoloInertDiscardQ(.sessionTransport, detail: "suona:\(isPlaying ? 1 : 0)")
                    }
                    return
                }
                // Modalità Direttore: ignora SEMPRE start/stop da peer in qualsiasi
                // stato (sorgente unica autoritativa).
                // Bug 5 fix 28/05/2026 — pre-fix richiedeva isRunning: Director in
                // stop accettava start da peer Collab via START LOCAL (CD-6).
                // Lettura _linkMode da non-audioQueue: Swift enum è safe per lettura concorrente.
                if engine._linkMode == .direttore { return }
                // RIENTRO-P1 (f) — SONDA: a ogni scatto del callback avvio/stop il Follower
                // logga l'ora dell'ultimo avvio/stop che Link riporta. Solo lettura, solo
                // log. Va su audioQueue perché le letture App-thread di Link di questo file
                // vivono tutte lì. È un `async` senza attesa: il cartello qui sotto vieta di
                // chiamare `stop()` DA DENTRO audioQueue, non di accodarle un lavoro.
                engine.audioQueue.async {
                    engine.logTransportStampIfFollower(isPlaying ? "callback avvio" : "callback stop")
                    // RIENTRO-P2A — TIMBRO: oltre all'ora, il battito dell'avvio, da una
                    // cattura sola (la riga RIENTRO-P1 qui sopra resta com'è, per confronto
                    // coi collaudi già fatti: sono due catture a pochi microsecondi).
                    engine.logStartStamp(isPlaying ? "callback-avvio" : "callback-stop")
                }
                // A386 · FASE B2A (2D) — IL CANCELLO DEL FOLLOWER. Chi è Follower (ruolo E Link
                // acceso dall'utente) passa dalla macchina, su audioQueue, PRIMA di `engine.start()`
                // e NON dentro `start()`, che è anche la porta del rientro dopo un'interruzione:
                // mezza battuta (D6, `HalfBarWindow`), falsa partenza (D7-bis,
                // `FalseStartDecision`), tabella `FollowerSyncDecision`. Chi non era Follower (Solo,
                // o ruolo Follower con Link spento dall'utente) teneva il ramo di sempre, sotto; da
                // A411 non arriva qui: lo ferma il lucchetto in testa al richiamo.
                // B2A-bis: questo richiamo gira su main, quindi la decisione si legge
                // dalla copia di main (`followerDecision`, la stessa di `handleStop`), non dalle
                // copie di coda; la lettura di `_linkMode` alla riga sopra è pre-esistente.
                if engine.followerDecision.isFollower {
                    engine.audioQueue.async {
                        engine.followerHandleLinkTransport(isPlaying: isPlaying)
                    }
                    return
                }
                // A400 · R1 — CHI NON È DIRETTORE NÉ FOLLOWER.
                // ⚠️ A411 · SOLO-INERTE — da qui non passa più nessuno: «né Direttore né Follower» è il Solo
                //    (`PlayerRoleDecision`), e il lucchetto in testa al richiamo lo ferma prima. Il blocco
                //    resta com'era (toglierlo non è di questo mandato: referto A411, Aperti); il testo qui
                //    sotto descrive la strada fino ad A410.
                // Regola (`LinkTransportCallbackDecision`, Models/, col suo banco): un avvio comandato
                // da questo apparecchio non gli torna indietro come avvio di un altro.
                // Il richiamo «suona» fa due passi. Passo di coda, su audioQueue: se il segno del
                // proprio avvio è alzato (`_ownTransportStartPendingQ`) è l'eco — il segno si abbassa,
                // una riga di registro, fine; altrimenti passa a main, dove decide la tabella di
                // sempre (`mainStep`).
                // Il richiamo «non suona» va DRITTO a main, com'era prima di A400, e lì decide la
                // stessa tabella (ferma solo a motore in moto). Dalla coda NON passa: lo stop
                // leggerebbe `isPlaying` in ritardo rispetto ai comandi locali, e quattro ordini si
                // rovescerebbero contro il comportamento di prima (referto A400 §8.2, V1-V4;
                // decisione del referee del 10/10/2026). Così l'eco del proprio stop resta inerte,
                // com'era.
                // CRITICO, com'era: `stop()` NON si chiama da dentro audioQueue — `stopSync()` ha
                // `audioQueue.sync` dentro e sarebbe un deadlock. Il passo di coda non avvia e non
                // ferma niente: accoda soltanto un lavoro su main, senza attesa, ed è quel lavoro,
                // su main, a chiamare `start()` e `stop()`.
                let mainWork: () -> Void = {
                    switch LinkTransportCallbackDecision.mainStep(
                        isPlaying: isPlaying,
                        engineIsPlaying: engine.isPlaying,
                        startEmitInFlight: engine._linkStartEmitInFlight) {
                    case .start:
                        // Q-D4 esteso — Gate anti double-emit (vedi commento su
                        // `_linkStartEmitInFlight` decl): `.start` esce solo a lucchetto giù.
                        engine._linkStartEmitInFlight = true
                        engine.start()
                        engine.linkStartedSubject.send()
                    case .stop:
                        engine.stop()
                    case .none:
                        break
                    }
                }
                if isPlaying {
                    engine.audioQueue.async {
                        if LinkTransportCallbackDecision.queueStep(
                            isPlaying: isPlaying,
                            ownStartPending: engine._ownTransportStartPendingQ) == .consumeOwnEcho {
                            engine._ownTransportStartPendingQ = false
                            os_log("[Q-BEATS][LINK][ECO-PROPRIO] avvio ignorato (isPlaying:%d)",
                                   log: .default, type: .default, isPlaying ? 1 : 0)
                            return
                        }
                        DispatchQueue.main.async { mainWork() }
                    }
                } else {
                    DispatchQueue.main.async { mainWork() }
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        // A411 · SOLO-INERTE — L'AVVIO. Il ruolo è Solo (non si salva più: `AppSettings`, §2.1 del mandato);
        // la levetta si legge dal ponte (`ablIsEnabled`, `ABLLinkIsEnabled`, sul thread principale come
        // `link_engine_activate`); la regola d'accensione si applica una prima volta (mano «avvio»): con il
        // ruolo Solo Link resta fuori rete, qualunque cosa dica la levetta. Il ponte nasce già spento
        // (`link_engine_create`, `ABLLinkSetActive(false)` subito dopo `ABLLinkNew`): nessuna finestra.
        // Tutto questo PRIMA di `link_engine_activate`, così la riga dell'avvio ha già la levetta vera, e il
        // richiamo che `activate` passa a Swift a levetta accesa la trova scritta e non ricalcola niente.
        // `link_engine_activate()` da A411 non accende più niente: legge la levetta, la passa al richiamo
        // (se accesa) e avvia il poll diagnostico #293. Vedi commento in LinkEngine.mm.
        if let lh = linkEngineHandle {
            let userEnabledAtBoot = linkSettingsPresenter?.ablIsEnabled() ?? false
            let savedRole = AppSettings.savedRoleInDefaults()
            let imposedRole = appSettings.linkMode
            audioQueue.async { [weak self] in
                guard let self else { return }
                os_log("[Q-BEATS][SOLO-INERTE] avvio - ruolo nel salvataggio:%{public}@ - ruolo imposto:%{public}@ - levetta:%d",
                       log: .default, type: .default,
                       savedRole ?? "nessuno", imposedRole.rawValue, userEnabledAtBoot ? 1 : 0)
                self._linkUserEnabledQ = userEnabledAtBoot
                self.applyLinkActivationQ(trigger: .boot)
            }
            DispatchQueue.main.async { [weak self] in self?.linkUserEnabled = userEnabledAtBoot }
            link_engine_activate(lh)
        }
        // RIENTRO-P2A — campionatore diagnostico del timbro dell'avvio (solo log).
        // ⚠️ A416 (21/10/2026): qui partiva il campionatore (`startStartStampSampler()`), e non si fermava più. Da A416
        // (mandato «USCITA-AUDIO-PASSO-1», §2.5) è spento a ogni avvio: lo accende e lo spegne l'interruttore solo DEBUG
        // della `DebugView` (`setDebugStartStampSampler`). Le altre righe [TIMBRO], a evento, restano accese.
        // A386 · FASE B2A (2D) — la prima lettura di Start Stop Sync (il richiamo arriva solo
        // ai cambi), la notifica del numero dei collegati e il battito di trasporto a 1 s.
        if let lh = linkEngineHandle {
            let startStopSync = link_engine_is_start_stop_sync_enabled(lh)
            audioQueue.async { [weak self] in self?._startStopSyncEnabledQ = startStopSync }
            DispatchQueue.main.async { [weak self] in self?.linkStartStopSyncEnabled = startStopSync }
        }
        registerPeerCountNotification()
        startTransportPulse()
        // A386 · FASE B2d (2D) — l'ascolto del Follower a 0,25 s: parte con l'app, come il battito.
        startFollowerListen()

        // A416 (21/10/2026) — qui la copia della frequenza nel ponte del tap («Task D refactor #18c — pending atomic
        // init»: `qbeats_link_pending_set_sample_rate`, prima che il tap potesse girare). Nessuno la leggeva (dal A406 il
        // tap conta i buffer e basta): è uscita dal ponte con le sue scritture (mandato «USCITA-AUDIO-PASSO-1», §2.1).

        // A406 — la sessione audio si attiva su audioQueue, non sul thread principale. Su iOS 27
        // l'attivazione dal thread principale scrive a ogni avvio il Fault «AVAudioSession_iOS.mm:978
        // This method can lead to UI unresponsiveness if called on the main thread»; l'SDK
        // (AVAudioSession.h): «activating an audio session is a synchronous (blocking) operation».
        // L'attivazione resta sincrona e cambia coda: audioQueue è la coda seriale di start(),
        // rebuildGraph, della ripresa e di handleRouteChange, e un Play o un evento che arriva
        // durante l'attivazione si mette in coda dietro di lei. Nel blocco niente audioQueue.sync,
        // niente DispatchQueue.main.sync.
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.setupSession()
            // A416 (21/10/2026) — la frequenza dalla fonte unica arriva a tutte le copie dentro `setupGraph`
            // (`applySampleRateQ`): anche ai tre campioni del click, che fino ad A415 si facevano qui sotto, e allo
            // schermo, che qui prendeva la frequenza della sessione (`sampleRateInfo`) e ora mostra quella che si usa.
            self.setupGraph(context: "avvio-app")
        }
        // MIDI engine avvia DOPO Link — ordine intenzionale (commento a midi_engine_create qui
        // sopra). Resta sul thread principale: CoreMIDI chiama la notifica del client «on the same
        // run loop that you created the client on» (Apple, MIDIClientCreate), e audioQueue non ha
        // un run loop. midi_engine_start non usa né la sessione né il grafo, che ora si
        // costruiscono su audioQueue (blocco qui sopra).
        if let mh = midiEngineHandle {
            // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — «MIDI COLLEGATO» (A393 §6.3) ===
            // Il richiamo «riconto finito» va registrato PRIMA di midi_engine_start: il primo riconto
            // è sincrono lì dentro (dispatch_sync sulla coda del riconto) e deve consegnare anche lui.
            // Arriva sulla coda del riconto (`com.qbeats.midi.scan`), mai sul thread di CoreMIDI né
            // sul render callback; da qui solo `main.async` e lo specchio `midiDeviceConnected`.
            midi_engine_set_scan_done_callback(mh, { count, ctx in
                guard let ctx = ctx else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                let n = Int(count)
                DispatchQueue.main.async {
                    let connected = n > 0
                    if engine.midiDeviceConnected != connected {
                        engine.midiDeviceConnected = connected
                    }
                    if engine.midiDeviceCountReported != n {
                        engine.midiDeviceCountReported = n
                        os_log("[Q-BEATS][SOLO-M1][MIDI] apparecchi:%d collegato:%d (riconto finito)",
                               log: .default, type: .default, n, connected ? 1 : 0)
                    }
                }
            }, Unmanaged.passUnretained(self).toOpaque())
            midi_engine_start(mh)
        }
        setupNotifications()
        os_log("AppSettings loaded: accent=%.2f beat=%.2f subdiv=%.2f muted=%d",
               log: .default, type: .default,
               appSettings.accentVolume, appSettings.beatVolume, appSettings.subdivVolume,
               appSettings.clickMuted ? 1 : 0)
        applySettings(appSettings)

        if let mh = midiEngineHandle {
            midi_engine_set_receive_callback(mh, { data, length, ctx in
                guard let data = data, let ctx = ctx, length >= 2 else { return }
                let engine = Unmanaged<AudioEngine>.fromOpaque(ctx).takeUnretainedValue()
                let bytes = Array(UnsafeBufferPointer(start: data, count: Int(length)))
                engine.audioQueue.async {
                    engine.handleMIDIInput(bytes)
                }
            }, Unmanaged.passUnretained(self).toOpaque())
        }
        // SOLO-G1-PEZZO-1-M1 · A394 — il monitor del Wi-Fi parte col motore (ultimo passo di init).
        startWifiMonitor()
    }

    // Aggiunge log al ring buffer visivo (ultimi 10 eventi) per la DebugView
    func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logMessage = "[\(timestamp)] \(message)"
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.debugLogs.insert(logMessage, at: 0)
            if self.debugLogs.count > 10 {
                self.debugLogs.removeLast()
            }
        }
    }

    deinit {
        // RIENTRO-P2A — il campionatore del timbro si ferma col motore.
        startStampTimer?.cancel()
        transportPulseTimer?.cancel()
        followerListenTimer?.cancel()
        wifiMonitor.cancel()   // SOLO-G1-PEZZO-1-M1 · A394 — il monitor del Wi-Fi si ferma col motore.
        if let observer = peerCountObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        stopSync()
        // === Task D refactor #18c — Correzione 1 referee adattata a installTap ===
        // 1. stopSync() — sopra
        // 2. engine.stop() — ferma render thread (blocking, sincrono per Apple docs)
        //    ⚠️ MARCATURA 23/08 — «per Apple docs» NON È SORGENTATO: la
        //    documentazione Apple non dichiara `stop()` bloccante/sincrono. Il
        //    comportamento resta quello osservato, l'attribuzione no. Non
        //    cambiare l'ordine dei passi su questa base.
        // 3. mainMixerNode.removeTap(onBus: 0) — release del tap block ref
        // 4. destroy degli handle C (incluso qbeats_link_pending_destroy)
        // Senza questo ordine, free(linkPending) potrebbe race col render
        // thread che sta ancora eseguendo il tap block → use-after-free.
        engine.stop()
        engine.mainMixerNode.removeTap(onBus: 0)
        if let h = metronomeHandle {
#if QB_DIAG_SPY
            metronome_flush_diag(h)   // SPIA passiva: ultimo flush prima del destroy
#endif
            metronome_destroy(h)
        }
        if let mh = midiEngineHandle { midi_engine_destroy(mh) }
        // === MODIFICATO 6A ===
        if let lh = linkEngineHandle { link_engine_destroy(lh) }
        qbeats_link_pending_destroy(linkPending)
    }

    // MARK: - Public API (chiamabile da qualsiasi thread)

    // === Bug 2.b / Ferita A — Ingresso SHARED finalizzato AL FIRE (10/06/2026) ===
    // Diagnosi ratificata (referee + Mauro): nel flusso cross-device il
    // callback Link avvia start() PRIMA del setup del runner (ordine
    // deliberato Opzione C, vedi set_start_stop_callback). L'attesa
    // d'ingresso era calcolata UNA volta, al probe, con stato potenzialmente
    // pre-start: (i) quantum stantio del giro precedente (TEST5 RUN1/6:
    // attesa=5−fase con prima sezione in 4/4), (ii) timeline ri-azzerata dal
    // Director DOPO il probe (TEST5 RUN2/7). Esito: atterraggio fuori barra,
    // WARN aggancio, seed fallback, Follower sfasato per tutta la canzone.
    //
    // Fix (direzione BUGS_QBEATS.md:95 "ri-legge la fase AL FIRE / attende
    // il beat-zero del Director"): l'istante d'ingresso è FINALIZZATO AL
    // FIRE. Ogni arm ri-legge fase/quantum/tempo correnti; al fire il work
    // item ri-valida il target contro lo stato corrente e, se non è più su
    // un confine di barra, ri-arma (bounded da kSharedJoinMaxRearms). A
    // regime (stato già fresco) il percorso è identico al precedente:
    // stesso join_running_session, stesso seed, stessi log d'ingresso.
    // SOLO L3 (nessuna nuova API bridge/DSP). Gira esclusivamente su
    // audioQueue (chiamata dal blocco start() + asyncAfter su audioQueue):
    // _beatsPerBarQ e pendingLinkStart restano queue-confined.
    // ⚠️ A412 · SEGUITO 3 (18/10/2026): dal fuoco del rientro del Direttore (ramo «in ritardo») la chiamata
    // arriva dal timer `StrictOneShotTimer`, anche lui su audioQueue; l'asyncAfter qui sopra resta quello
    // dell'ingresso del Follower.
    private static let kSharedJoinPhaseTolBeats = 0.1   // allineata alla soglia WARN del seed
    private static let kSharedJoinMaxRearms     = 2     // copre (i)+(ii) anche combinate

    private func armSharedJoin(retriesLeft: Int, rejoin: RejoinTarget? = nil) {
        guard let lh = self.linkEngineHandle else { return }
        // RIENTRO-P1 (a) — UN SOLO INGRESSO PENDENTE ALLA VOLTA. Prima di armare si annulla
        // quello che c'era (fino a oggi l'assegnazione più sotto lo SOVRASCRIVEVA senza
        // annullarlo: l'annullo viveva solo in `stopSync`) e si alza la generazione: un work
        // item nato prima, se mai scattasse, si scarta da solo al fuoco. Quando a ri-armare
        // è il work item stesso (ramo «fire NON su barra»), `pendingLinkStart` è già nil.
        self.pendingLinkStart?.cancel()
        // A412 · SEGUITO 3 — col work item si ferma il timer del rientro del Direttore (`_rejoinArmTimerQ`); per un
        // ingresso del Follower è vuoto.
        self._rejoinArmTimerQ.cancel()
        self.joinGeneration += 1
        let generation = self.joinGeneration
        // A412 · DIRETTORE IN CRISI, PASSO 2 — L'INGRESSO COL BERSAGLIO (mandato §2.2, T3). Col bersaglio del
        // rientro del Direttore (`RejoinTarget`: sezione e battuta d'arrivo, battito di Link, ora della mappa; il
        // quantum e il seme del contatore vengono dalla sezione d'arrivo) l'ingresso prende il suo ramo QUI,
        // prima di ogni lettura del ramo condiviso: stessa generazione e stesso annullo qui sopra, nessuna
        // scrittura su Link (niente «si suona», niente battito). Senza bersaglio — il Follower e chi comanda in
        // una sessione condivisa — tutto quello che segue è identico a prima.
        if let rejoin {
            self.armDirectorRejoinQ(rejoin, generation: generation)
            return
        }
        // RIENTRO-P1 (e) — W4: il Follower entra in una sessione che suona GIÀ (A361), quindi
        // al fuoco non scrive «si suona» su Link (`link_engine_join_running_session` →
        // `ABLLinkSetIsPlaying`): il valore non cambierebbe, ma l'ora dello stato avvio/stop
        // sì, per tutti. Chi comanda il trasporto ed entra in una sessione condivisa (Solo con
        // Link acceso) scrive come oggi. Regola e banco: `FollowerLinkWriteDecision`.
        let writesPlayToLink = FollowerLinkWriteDecision.writesIsPlayingAtJoin(
            role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ)
        // === SESSIONE CONDIVISA — solo LinkMode.collaborativa ===
        // Q-BEATS si adegua alla timeline Link esistente: quantized
        // launch al prossimo downbeat via join_running_session.
        // Pattern aderente alla doc Ableton: "chi entra si adegua,
        // chi c'è già non si muove".
        // (Il ramo .direttore non arriva mai qui — gestito sopra.)
        // Bug 2.b / Ferita A — stato CORRENTE, ri-letto a OGNI arm: il probe
        // di branching in start() può essere pre-setup (quantum stantio).
        // Qui e nella ri-validazione al fire si usa SOLO stato fresco.
        let hostNow = mach_absolute_time()
        let quantum = Double(self._beatsPerBarQ)
        let probe = link_engine_probe_session(lh, hostNow, quantum)
        let peersCount = link_engine_num_peers(lh)
        let bpm = probe.tempo > 0.0 ? probe.tempo : self.currentBPM
        let phase = probe.phaseAtHost
        // Se phase ≈ 0 o ≈ quantum siamo già sul downbeat → no wait.
        // Altrimenti aspettiamo (quantum - phase) beat.
        let beatsToWait = (phase < 0.001 || phase > quantum - 0.001)
                          ? 0.0
                          : (quantum - phase)
        let delaySecondsBase = beatsToWait * (60.0 / bpm)
#if DIAG_FORCE_BORN_OFFSET
        // === HARNESS forzatura born — SEPARATO dalla spia passiva ===
        // Modifica di COMPORTAMENTO (NON osservazione): aggiunge 0.5 beat
        // all'attesa così l'aggancio cade FUORI dal downbeat
        // (round(startBeat)≠0) → riproduce il born oltre N=1.
        // Dati TAGGATI [Bug2b-SPY-FORCED] = distinti dai giri passivi.
        // Compilato SOLO con DIAG_FORCE_BORN_OFFSET (config dedicata, MAI
        // il build di default; si usa insieme a QB_DIAG_SPY per osservare).
        let delaySeconds = delaySecondsBase + 0.5 * (60.0 / bpm)
        os_log("[Q-BEATS][Bug2b-SPY-FORCED] born forzato +0.5 beat (delay %.3f→%.3f s)",
               log: .default, type: .default, delaySecondsBase, delaySeconds)
#else
        let delaySeconds = delaySecondsBase
#endif

        // Conversione delaySeconds → mach ticks per
        // futureHostTime esatto (timestamp Link insensibile
        // al jitter dispatch).
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let delayNs = delaySeconds * 1_000_000_000.0
        let delayTicks = UInt64(delayNs
                                * Double(timebase.denom)
                                / Double(timebase.numer))
        let futureHostTime = hostNow + delayTicks

        os_log("[Q-BEATS][LINK][SHARED] peers:%u isPlaying:%d phase:%.4f attesa:%.4f beat (%.3f s) bpm:%.2f quantum:%.1f retriesLeft:%d",
               log: .default, type: .default,
               peersCount, probe.isPlaying ? 1 : 0,
               phase, beatsToWait, delaySeconds, bpm, quantum, retriesLeft)

        DispatchQueue.main.async {
            self.isWaitingForLinkDownbeat = true
        }

        // RIENTRO-P1 (f) — SONDA, prima dell'ingresso del Follower: l'ora dell'ultimo
        // avvio/stop che Link riporta ADESSO. La lettura gemella sta in fondo al work item.
        if !writesPlayToLink {
            self.logTransportStamp("prima dell'ingresso")
        }

        // ROTTA α (Build #307→#309): l'annuncio Link è DENTRO
        // il work item. Se l'utente preme stop prima del fire,
        // pendingLinkStart?.cancel() impedisce ogni
        // pubblicazione di stato a Link → atomicità by design.
        // Timestamp = futureHostTime catturato in closure,
        // NON mach_absolute_time() rileggiuto al fire.
        let lhCaptured = self.linkEngineHandle
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // RIENTRO-P2A — L'ORA VERA DEL FUOCO, letta per prima cosa. Una lettura
            // dell'orologio e basta: la riga [FUOCO] si scrive più sotto, a ingresso fatto
            // (o a ri-armo fatto), per non mettere lavoro davanti al primo buffer.
            let firedAt = mach_absolute_time()
            // RIENTRO-P1 (a) — FUOCO SCARTATO. Questo work item vale solo se è ancora
            // l'ULTIMO armato (la generazione con cui è nato è quella corrente) e se il
            // motore è ancora in moto. Se no è un fuoco orfano — un arresto che non passa
            // da `stopSync`, o un secondo armamento, sono arrivati nel frattempo — e qui
            // si esce PRIMA di toccare Link, il DSP, il seme e `_startAbsoluteBeat`.
            guard generation == self.joinGeneration, self.isRunning else {
                os_log("[Q-BEATS][RIENTRO-P1] fuoco scartato - generazione:%d attuale:%d motore:%{public}@",
                       log: .default, type: .default,
                       generation, self.joinGeneration, self.isRunning ? "in moto" : "fermo")
                return
            }
            // È in esecuzione: non è più «pendente» (e un ri-armo qui sotto non ha niente
            // da annullare).
            self.pendingLinkStart = nil
            // === Ferita A — RI-VALIDAZIONE AL FIRE (stato post-setup/post-rezero) ===
            // Il target calcolato all'arm vale solo se, ADESSO, cade ancora su
            // un confine di barra dello stato corrente della sessione. Se nel
            // frattempo il setup ha corretto il metro (sotto-faccia i) o il
            // Director ha ri-azzerato la timeline (sotto-faccia ii), si ri-arma
            // una nuova attesa calcolata dallo stato corrente. Bound: esauriti
            // i re-arm si entra col comportamento precedente (WARN del seed
            // compreso) — mai peggio della baseline.
            if let lhNow = lhCaptured {
                let qNow = Double(self._beatsPerBarQ)
                let probeNow = link_engine_probe_session(lhNow, futureHostTime, qNow)
                let distToBar = min(probeNow.phaseAtHost, qNow - probeNow.phaseAtHost)
                if distToBar > AudioEngine.kSharedJoinPhaseTolBeats {
                    if retriesLeft > 0 {
                        os_log("[Q-BEATS][LINK][SHARED] fire NON su barra (dist:%.4f quantum:%.1f) → re-arm, residui:%d",
                               log: .default, type: .default,
                               distToBar, qNow, retriesLeft - 1)
                        self.armSharedJoin(retriesLeft: retriesLeft - 1)
                        // RIENTRO-P2A — [FUOCO] anche per il fuoco che ri-arma: scritta DOPO
                        // che il nuovo ingresso è già armato, così non gli sta davanti.
                        self.logJoinFire(outcome: "riarmo", expected: futureHostTime,
                                         actual: firedAt, waitSeconds: delaySeconds,
                                         generation: generation, retriesLeft: retriesLeft)
                        return
                    }
                    os_log("[Q-BEATS][LINK][SHARED] WARN re-arm esauriti (dist:%.4f quantum:%.1f) — ingresso con comportamento pre-fix",
                           log: .default, type: .error, distToBar, qNow)
                }
            }
            DispatchQueue.main.async {
                self.isWaitingForLinkDownbeat = false
            }
            if let lh = lhCaptured {
                if writesPlayToLink {
                    // A400 · R1 — IL SEGNO DEL PROPRIO AVVIO si alza subito prima della scrittura
                    // «suona» di chi comanda il trasporto ed entra in una sessione condivisa. Se la
                    // sessione era ferma, Link richiama per questo avvio (misurato, referto A399
                    // §5.1) e il richiamo consuma il segno (`init`, passo di coda). Dove Link suona
                    // già l'eco non arriva — il richiamo scatta solo ai cambi di «suona» (misura di
                    // A399 §13-bis.1) — e non arriva a ponte spento: il segno resta alzato, inerte,
                    // fino allo stop. A motore in moto un avvio altrui non fa niente comunque
                    // (`LinkTransportCallbackDecision.mainStep` avvia solo a motore fermo).
                    self._ownTransportStartPendingQ = true
                    link_engine_join_running_session(lh, futureHostTime)
                } else {
                    // RIENTRO-P1 (e) — W4: vedi `writesPlayToLink` in testa ad `armSharedJoin`.
                    os_log("[Q-BEATS][RIENTRO-P1] ingresso del Follower - 'si suona' NON scritto su Link (W4) - la sessione suona gia'",
                           log: .default, type: .default)
                }
            }
            if let h = self.metronomeHandle {
                metronome_reset_for_start(h, 0.0)
                // A421 — la copia dell'origine del DSP (U9).
                self._dspOriginBeatQ = 0
            }
            // === Bug 2.b ramo X — SEED contatore sezione del Follower ===
            // Il Follower entra dopo il count-in del Director (≥1 bar).
            // _sectionBeatCounter è già stato azzerato da loadSection (936-944)
            // e da start() (~634), ENTRAMBI prima di questo work item ritardato.
            // Seminiamo QUI, PRIMA del pre-roll sottostante: il primo
            // scheduleNextBuffer emette già il primo beat (resetForStart fissa
            // _exactNextBeatSample=0 → beat al sample 0) che fa
            // _sectionBeatCounter += 1. Seminare dopo il pre-roll = off-by-one.
            //
            // ⚠️ RISCRITTO RIENTRO-P2A (20/09/2026; referto A376 §2.1). Il testo di prima
            // diceva «startBeat = fase allineata alla sessione Link al momento del join»:
            // era falso. Quello che il codice fa:
            // `startBeat` NON viene da Link. `midi_engine_get_beat_at_time` legge il
            // sequencer MIDI LOCALE (MIDIEngine.mm: proietta l'ora chiesta sull'ultimo punto
            // di `midi_engine_sync_clock` e chiede `sequencer.getBeatPosition`), e `start()`
            // quel sequencer l'ha azzerato — `midi_engine_sync_clock(mh, 0,
            // mach_absolute_time(), …)` e `midi_engine_set_beat_position(mh, 0.0)` — PRIMA
            // di chiamare `armSharedJoin`. Quindi `startBeat` = i battiti trascorsi da
            // `start()` all'ora d'uscita prevista del fuoco = l'attesa d'ingresso, più la
            // latenza d'uscita, più un buffer. Non dice a che punto della canzone è la band.
            // Con i ri-armi le attese si sommano: il ramo «fire NON su barra» esce prima dei
            // tre `scheduleNextBuffer` qui sotto, che sono gli unici a riancorare il
            // sequencer; con `kSharedJoinMaxRearms` = 2 le attese sono al più tre, ciascuna
            // di al più una battuta del quantum letto a quell'armamento.
            // ⚠️ RISCRITTO RIENTRO-P2A. Il testo di prima diceva «Variabile LOCALE: NON
            // tocchiamo _startAbsoluteBeat (snap resume)»: vero solo di questo blocco.
            // `startBeat` è locale al blocco del seme, ma questo stesso work item
            // `_startAbsoluteBeat` lo SCRIVE poco più sotto, dopo i tre `scheduleNextBuffer`.
            if let mh = self.midiEngineHandle {
                let startBeat = midi_engine_get_beat_at_time(
                    mh,
                    futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks)
                // Spia: aggancio non sul downbeat (frazione in valore assoluto).
                // Problema a monte da non mascherare — log, non correzione.
                if abs(startBeat - startBeat.rounded()) > 0.1 {
                    os_log("[Q-BEATS][Bug2b] WARN aggancio non su downbeat — startBeat:%.4f frazione:%.3f",
                           log: .default, type: .error,
                           startBeat, startBeat - startBeat.rounded())
                }
                // Bug 2.b faccia D — SNAP-TO-BAR. L'attesa quantizza l'aggancio al
                // confine di BARRA (wait = quantum − phase, quantum = _beatsPerBarQ,
                // :745/:795) → il Follower entra su un downbeat → il seme è un
                // multiplo intero di beatsPerBar. round() al BEAT era la granularità
                // sbagliata (scatter osservato 3,27–3,87 ribaltava 3↔4 a metà-beat).
                let bpb = Int(self._beatsPerBarQ)
                let offset = bpb > 0
                    ? Int((startBeat / Double(bpb)).rounded()) * bpb
                    : Int(startBeat.rounded())
                // Rete portante: semina SOLO se l'offset è coerente con la
                // sezione. Fuori (0, _sectionTotalBeats) → no-op = comportamento
                // di oggi (counter da bar 1), niente swap immediato né brano rotto.
                if offset > 0 && offset < self._sectionTotalBeats {
                    self.startBeatOffset = offset
                    self._sectionBeatCounter = offset
                } else {
                    self.startBeatOffset = 0
                    self._sectionBeatCounter = 0
                    // Il ramo SHARED si aspetta SEMPRE offset > 0 (il Follower
                    // entra dopo il count-in del Director): qualsiasi else —
                    // incluso offset == 0 — è un'anomalia da loggare sempre.
                    os_log("[Q-BEATS][Bug2b] seed SKIP su SHARED — offset:%d fuori range [1,%d) — no-op safe (atteso >0)",
                           log: .default, type: .error,
                           offset, self._sectionTotalBeats)
                }
            }
            // RIENTRO-P2A — FINESTRA: quanti buffer di sospensione della correzione di fase
            // restavano a QUESTO motore al momento dell'ingresso (li aprono lo scambio di
            // sezione e `scheduleBPMChange`, a 100). Si legge qui perché la riga sotto li
            // sovrascrive con 3; la riga di log si scrive dopo i tre `scheduleNextBuffer`.
            let skipBuffersAtFire = self.linkSyncSkipBuffers
            self.linkSyncSkipBuffers = 3
            // A420 — la catena dell'ingresso comincia qui: una generazione nuova prima del primo dei tre buffer (mandato A420,
            // par. 2.2). Un richiamo della catena di prima arrivato fra l'avvio del motore e questo fuoco si è già scartato:
            // `start()` ha aperto una generazione alzando `isRunning` (risposta del referee, par. 1).
            self.openBufferChainQ()
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
            // ⚠️ RISCRITTO RIENTRO-P2A (20/09/2026; referto A376 §2.1 e §2.4). Il testo di
            // prima diceva «il primo sample audio reale parte a futureHostTime»: era falso.
            // Quello che il codice fa: il primo campione esce quando GIRA questo blocco,
            // perché `scheduleNextBuffer` consegna il buffer con
            // `playerNode.scheduleBuffer(buffer)` SENZA `at:` — il player lo suona appena
            // può, non a un'ora. `futureHostTime` è l'ora PREVISTA del fuoco; l'ora vera la
            // scrive la riga [FUOCO] qui sotto.
            // Qui `_startAbsoluteBeat` viene sovrascritto col battito del sequencer MIDI
            // locale all'ora d'uscita prevista (`futureHostTime` + latenza + un buffer). I tre
            // `scheduleNextBuffer` qui sopra hanno appena riancorato il sequencer ad ADESSO
            // (`midi_engine_sync_clock`): se il fuoco è in ritardo di più di latenza + un
            // buffer, l'ora chiesta precede l'àncora e `midi_engine_get_beat_at_time` ripiega
            // sulla posizione corrente del sequencer (MIDIEngine.mm, guardia
            // `hostTime < engine->lastMachTime`), che è l'inizio del terzo buffer.
            if let mh = self.midiEngineHandle {
                self._startAbsoluteBeat = midi_engine_get_beat_at_time(
                    mh,
                    futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks)
            }
            os_log("[Q-BEATS][LINK][SHARED] downbeat raggiunto — avvio motore startBeat:%.4f",
                   log: .default, type: .default,
                   self._startAbsoluteBeat)
            // A400 · R1 — la riga del segno alzato, a buffer accodati (`logOwnTransportStartRaisedQ`).
            if writesPlayToLink && lhCaptured != nil {
                self.logOwnTransportStartRaisedQ(write: "ingresso")
            }
            // RIENTRO-P2A — [FUOCO]: ora prevista e ora vera del fuoco, con la differenza.
            self.logJoinFire(outcome: "ingresso", expected: futureHostTime,
                             actual: firedAt, waitSeconds: delaySeconds,
                             generation: generation, retriesLeft: retriesLeft)
            // RIENTRO-P2A — [FINESTRA]: solo se l'ingresso è caduto a finestra aperta. In
            // questo passo si misura e basta: nessun rinvio.
            if skipBuffersAtFire > 0 {
                os_log("[Q-BEATS][RIENTRO-P2A][FINESTRA] ingresso-in-finestra bufferRimasti:%d generazione:%d",
                       log: .default, type: .default, skipBuffersAtFire, generation)
            }
            // RIENTRO-P1 (f) — SONDA, dopo l'ingresso del Follower: se l'ora è la stessa letta
            // «prima dell'ingresso», l'ingresso non l'ha toccata (è quello che W4 tolta promette).
            if !writesPlayToLink {
                self.logTransportStamp("dopo l'ingresso")
            }
            // RIENTRO-P2A — [TIMBRO] dopo l'ingresso (gemella di «callback-avvio»: stessa
            // riga, una cattura sola). Per chiunque entri di qui, Follower o no: il ruolo è
            // nella riga.
            self.logStartStamp("dopo-ingresso")

#if QB_DIAG_SPY
            // SPIA passiva — TRE sorgenti all'aggancio (campo concomitante,
            // letture PASSIVE su audioQueue, nessun cambio di comportamento):
            //  linkPhase_schedule = Link ABLLinkPhaseAtTime @hostNow (R1, già usata da prod)
            //  linkPhase_fire     = Link ABLLinkPhaseAtTime @fireHostTime (probe passiva)
            //  midiBeat_fire      = MIDI engine @fireHostTime (R2/R3, usata da prod)
            // Coerenza Link↔MIDI osservabile: linkPhase_fire vs (midiBeat_fire mod quantum).
            if let lhSpy = lhCaptured, let mhSpy = self.midiEngineHandle {
                let fireHostTime = futureHostTime + self.outputLatencyTicks + self.bufferDurationTicks
                let probeFire = link_engine_probe_session(lhSpy, fireHostTime, quantum)
                let midiBeatFire = midi_engine_get_beat_at_time(mhSpy, fireHostTime)
                os_log("[Q-BEATS][Bug2b-SPY-ATTACH] linkPhase_schedule:%.4f linkPhase_fire:%.4f midiBeat_fire:%.4f quantum:%.1f startAbs:%.4f",
                       log: .default, type: .default,
                       phase, probeFire.phaseAtHost, midiBeatFire, quantum, self._startAbsoluteBeat)
            }
#endif
        }
        self.pendingLinkStart = work
        self.audioQueue.asyncAfter(deadline: .now() + delaySeconds, execute: work)
    }

    // RIENTRO-P1 (a) — L'ANNULLO DELL'INGRESSO PENDENTE, per gli arresti che NON passano da
    // `stopSync`. Chiamare SOLO su audioQueue.
    // `stopSync` annulla da sé (e resta com'è). Ma tre percorsi mettono `isRunning = false`
    // senza passarci — inizio di un'interruzione (`handleInterruption`, `.began`), cambio di
    // configurazione del motore (`handleEngineConfigChange`), cambio di topologia
    // (`handleRouteChange`, ramo `modeChanged`) — e fino a oggi lasciavano il work item
    // armato: scattava a motore fermo, oppure in doppio col work item dell'avvio successivo
    // (collaudo 17/09/2026, giro G3, 10:19:39-41: due «downbeat raggiunto» con un
    // «seed SKIP» in mezzo; referto A364, §3.d e §4.3).
    // Alza la generazione: anche un work item che `cancel()` non facesse in tempo a fermare
    // si scarta da solo al fuoco. Abbassa `isWaitingForLinkDownbeat`, come fa `stopSync`.
    // ⚠️ A416 (21/10/2026): «tre percorsi» oggi sono di più: da A412 gli arresti locali della Lost e del reset
    // (`beginLocalStopQ`), da A416 il cambio di frequenza dal percorso a motore in moto (`handleRouteChange`, motivo
    // «cambio di frequenza»). Anche loro annullano qui l'ingresso pendente.
    private func cancelPendingJoin(reason: String) {
        // A412 · SEGUITO 3 — col work item si ferma il timer del rientro del Direttore (`_rejoinArmTimerQ`); qui, prima
        // del `guard`, così non dipende da `pendingLinkStart`. Senza attesa armata non fa niente.
        self._rejoinArmTimerQ.cancel()
        guard let pending = self.pendingLinkStart else { return }
        pending.cancel()
        self.pendingLinkStart = nil
        self.joinGeneration += 1
        os_log("[Q-BEATS][RIENTRO-P1] ingresso pendente annullato - motivo:%{public}@ generazione:%d",
               log: .default, type: .default, reason, self.joinGeneration)
        DispatchQueue.main.async {
            self.isWaitingForLinkDownbeat = false
        }
    }

    // A400 · R1 — IL SEGNO DEL PROPRIO AVVIO: la riga «alzato». Chiamare SOLO su audioQueue.
    // Il segno si alza in linea, subito prima della scrittura in Link (un `Bool`: niente lavoro
    // davanti alla scrittura); la riga che lo dice si scrive dopo, a buffer accodati, per non
    // mettere lavoro davanti al primo buffer (come la riga [FUOCO] di `armSharedJoin`).
    private func logOwnTransportStartRaisedQ(write: String) {
        os_log("[Q-BEATS][LINK][SEGNO-AVVIO] alzato (scrittura:%{public}@)",
               log: .default, type: .default, write)
    }

    // A400 · R1 — IL SEGNO DEL PROPRIO AVVIO SI ABBASSA SENZA ECO. Chiamare SOLO su audioQueue.
    // Il consumo vero sta nel richiamo avvio/stop di Link (`init`, passo di coda). Qui il segno
    // si abbassa quando l'eco non è arrivato e il motore si ferma o non parte: `stopSync`
    // (motivo «stop»), i tre arresti che non passano da `stopSync` («interruzione»,
    // «topologia», «configurazione») e il `catch` di `start()` («catch»). NON sta dentro
    // `cancelPendingJoin`, che esce subito quando non c'è un ingresso pendente: cioè sempre,
    // nel Solo senza collegati. La riga si scrive solo se il segno era alzato: nel registro ogni
    // «alzato» ha una sola chiusura, «avvio ignorato» oppure questa.
    // ⚠️ A416 (21/10/2026): fra gli arresti che non passano da `stopSync` anche il cambio di frequenza dal percorso a
    // motore in moto (motivo «frequenza»).
    private func lowerOwnTransportStartQ(reason: String) {
        guard _ownTransportStartPendingQ else { return }
        _ownTransportStartPendingQ = false
        os_log("[Q-BEATS][LINK][SEGNO-AVVIO] abbassato senza eco (motivo:%{public}@)",
               log: .default, type: .default, reason)
    }

    // RIENTRO-P1 (f) — SONDA DI SOLA LETTURA: l'ora dell'ultimo avvio/stop che Link riporta
    // (`ABLLinkTimeForIsPlaying`), nell'orologio di questo apparecchio. Chiamare SOLO su
    // audioQueue. Si LOGGA e basta: nessuna decisione legge questo valore in questo passo.
    // Serve a misurare su device la domanda rimasta aperta nel referto A364 (§3.k, §4.2): sul
    // Follower, l'ora che arriva col Play del Direttore resta quella dopo l'ingresso?
    // `trascorsi_ms` è «adesso − ora»: negativo se l'ora è nel futuro.
    private func logTransportStamp(_ context: String) {
        guard let lh = self.linkEngineHandle else { return }
        var sessionPlaying = false
        let stamp = link_engine_time_for_is_playing(lh, &sessionPlaying)
        let now = mach_absolute_time()
        let elapsedMs: Double
        if stamp == 0 {
            elapsedMs = 0.0
        } else if now >= stamp {
            elapsedMs = self.machTicksToSeconds(now - stamp) * 1000.0
        } else {
            elapsedMs = -self.machTicksToSeconds(stamp - now) * 1000.0
        }
        os_log("[Q-BEATS][RIENTRO-P1] ora ultimo avvio/stop - contesto:%{public}@ sessioneSuona:%d oraLink:%llu adesso:%llu trascorsi_ms:%.1f",
               log: .default, type: .default,
               context, sessionPlaying ? 1 : 0, stamp, now, elapsedMs)
    }

    // RIENTRO-P1 (f) — la stessa sonda, per il callback avvio/stop: logga solo sul Follower
    // (ruolo E Link acceso dall'utente, copie di coda — `FollowerDecision`). Chiamare SOLO su
    // audioQueue.
    private func logTransportStampIfFollower(_ context: String) {
        guard FollowerDecision.isFollower(role: self._linkMode,
                                          userLinkEnabled: self._linkUserEnabledQ) else { return }
        self.logTransportStamp(context)
    }

    // RIENTRO-P2A (20/09/2026) — [FUOCO]: ora prevista (`futureHostTime` dell'armamento) e ora
    // vera (letta in testa al work item) del fuoco dell'ingresso, con la differenza. Solo log.
    // Chiamare SOLO su audioQueue, a ingresso (o ri-armo) già fatto.
    // Formato fisso, campi `chiave:valore` separati da uno spazio:
    //   esito       ingresso | riarmo
    //   previsto    mach ticks
    //   vero        mach ticks
    //   ritardo_ms  vero − previsto, in millisecondi (negativo = fuoco in anticipo)
    //   attesa_s    l'attesa chiesta a `asyncAfter` per questo armamento, in secondi
    //   generazione `joinGeneration` con cui il work item è nato
    //   residui     `retriesLeft` di questo armamento
    private func logJoinFire(outcome: String, expected: UInt64, actual: UInt64,
                             waitSeconds: Double, generation: Int, retriesLeft: Int) {
        let lateMs: Double
        if actual >= expected {
            lateMs = self.machTicksToSeconds(actual - expected) * 1000.0
        } else {
            lateMs = -self.machTicksToSeconds(expected - actual) * 1000.0
        }
        os_log("[Q-BEATS][RIENTRO-P2A][FUOCO] esito:%{public}@ previsto:%llu vero:%llu ritardo_ms:%.3f attesa_s:%.3f generazione:%d residui:%d",
               log: .default, type: .default,
               outcome, expected, actual, lateMs, waitSeconds, generation, retriesLeft)
    }

    // RIENTRO-P2A (20/09/2026) — [TIMBRO]: il timbro dell'avvio che Link riporta, accanto a
    // quello che crede il motore. Solo lettura, solo log: nessuna decisione legge questi
    // valori in questo passo. Che cosa rende ciascuna lettura di Link: MIDIEngineBridge.h,
    // `LinkStartStamp`.
    // I valori che si confrontano fra un campione e l'altro (l'ora della cattura no).
    private struct StartStampSample: Equatable {
        let linkEnabled: Bool          // interruttore dell'app (`enabled_` del ponte)
        let sessionPlaying: Bool       // ABLLinkIsPlaying
        let startTime: UInt64          // ABLLinkTimeForIsPlaying, mach ticks
        let beatQ1: Double             // ABLLinkBeatAtTime (T, 1)
        let phaseQBig: Double          // ABLLinkPhaseAtTime(T, 1e6)
        let beatQ0: Double             // ABLLinkBeatAtTime (T, 0)
        let peers: UInt32              // contatore del ponte (0/1)
        let role: LinkMode             // `_linkMode`
        let userLinkEnabled: Bool      // `_linkUserEnabledQ`
        let engineRunning: Bool        // `isRunning`
        let joinPending: Bool          // `pendingLinkStart != nil`
    }

    // Legge il timbro e lo stato del motore. Chiamare SOLO su audioQueue: la cattura dello
    // stato di Link scrive in un membro condiviso dell'istanza ABLLink (MIDIEngineBridge.h,
    // `link_engine_read_start_stamp`), e le altre catture di questo file vivono tutte qui.
    private func readStartStamp() -> (sample: StartStampSample, capturedAt: UInt64)? {
        guard let lh = self.linkEngineHandle else { return nil }
        let stamp = link_engine_read_start_stamp(lh)
        let sample = StartStampSample(linkEnabled: stamp.linkEnabled,
                                      sessionPlaying: stamp.isPlaying,
                                      startTime: stamp.timeForIsPlaying,
                                      beatQ1: stamp.beatAtStampQ1,
                                      phaseQBig: stamp.phaseAtStampQBig,
                                      beatQ0: stamp.beatAtStampQ0,
                                      peers: stamp.numPeers,
                                      role: self._linkMode,
                                      userLinkEnabled: self._linkUserEnabledQ,
                                      engineRunning: self.isRunning,
                                      joinPending: self.pendingLinkStart != nil)
        return (sample, stamp.captureHostTime)
    }

    // Scrive la riga. Non legge stato del motore: chiamabile da qualsiasi coda.
    // Formato fisso, campi `chiave:valore` separati da uno spazio, nessuno spazio nei valori:
    //   contesto     fronte-collegato-si | fronte-collegato-no | callback-avvio |
    //                callback-stop | dopo-ingresso | campione
    //   link         1 = interruttore dell'app acceso; a 0 i cinque campi di Link sono zero
    //   suona        ABLLinkIsPlaying
    //   oraAvvio     T = ABLLinkTimeForIsPlaying, mach ticks
    //   battitoQ1    ABLLinkBeatAtTime (T, 1)
    //   faseQ1e6     ABLLinkPhaseAtTime(T, 1e6)
    //   battitoQ0    ABLLinkBeatAtTime (T, 0)
    //   adesso       mach ticks letti subito prima della cattura
    //   trascorsi_ms adesso − oraAvvio, in millisecondi (negativo = ora nel futuro)
    //   peers        contatore del ponte (0/1)
    //   ruolo        `_linkMode`
    //   linkUtente   `_linkUserEnabledQ`
    //   motore       in-moto | fermo (`isRunning`)
    //   ingresso     pendente | nessuno (`pendingLinkStart`)
    private func writeStartStampLine(_ context: String, _ sample: StartStampSample,
                                     capturedAt: UInt64) {
        let elapsedMs: Double
        if capturedAt >= sample.startTime {
            elapsedMs = self.machTicksToSeconds(capturedAt - sample.startTime) * 1000.0
        } else {
            elapsedMs = -self.machTicksToSeconds(sample.startTime - capturedAt) * 1000.0
        }
        let linkOn: Int = sample.linkEnabled ? 1 : 0
        let sessionPlaying: Int = sample.sessionPlaying ? 1 : 0
        let userLinkOn: Int = sample.userLinkEnabled ? 1 : 0
        let roleText: String = String(describing: sample.role)
        let engineText: String = sample.engineRunning ? "in-moto" : "fermo"
        let joinText: String = sample.joinPending ? "pendente" : "nessuno"
        os_log("[Q-BEATS][RIENTRO-P2A][TIMBRO] contesto:%{public}@ link:%d suona:%d oraAvvio:%llu battitoQ1:%.6f faseQ1e6:%.6f battitoQ0:%.6f adesso:%llu trascorsi_ms:%.1f peers:%u ruolo:%{public}@ linkUtente:%d motore:%{public}@ ingresso:%{public}@",
               log: .default, type: .default,
               context, linkOn, sessionPlaying,
               sample.startTime, sample.beatQ1, sample.phaseQBig, sample.beatQ0,
               capturedAt, elapsedMs, sample.peers,
               roleText, userLinkOn, engineText, joinText)
    }

    // La riga [TIMBRO] a un evento (fronte del collegato, callback avvio/stop, dopo
    // l'ingresso). Chiamare SOLO su audioQueue.
    private func logStartStamp(_ context: String) {
        guard let read = self.readStartStamp() else { return }
        self.writeStartStampLine(context, read.sample, capturedAt: read.capturedAt)
    }

    // RIENTRO-P2A — CAMPIONATORE DIAGNOSTICO DEL TIMBRO. Quattro volte al secondo rilegge il
    // timbro e scrive la riga [TIMBRO] (contesto `campione`) SOLO se uno dei valori di
    // `StartStampSample` è cambiato dall'ultimo campione scritto. Serve a vedere nei log di
    // un collaudo due cose che nessun callback annuncia: se dopo una rete persa e ritrovata
    // il timbro cambia anche quando il callback avvio/stop non scatta, e se resta fermo
    // quando il Direttore forza la griglia.
    // Dove gira: il timer e il confronto su `startStampQueue` (utility); la SOLA lettura su
    // audioQueue — un blocco con una cattura e tre letture, senza log — perché la cattura
    // dello stato di Link non è sicura da un altro thread (vedi `readStartStamp`). La riga,
    // quando si scrive, si scrive su `startStampQueue`.
    // ⚠️ RISCRITTO A416 (21/10/2026). Il testo di prima diceva «Parte in `init` e non si ferma: il motore non sa se c'è
    // uno show in stanza (la sessione vive sopra di lui). A Link spento i campi restano fermi e non si scrive niente.».
    // Da A416 (mandato «USCITA-AUDIO-PASSO-1», §2.5; BUGS `TD-campionatore-del-timbro-acceso`) il campionatore esiste solo
    // in DEBUG ed è spento a ogni avvio: lo accende e lo spegne un comando solo, `setDebugStartStampSampler`
    // (l'interruttore della `DebugView`), che crea e annulla il timer su `startStampQueue`. All'accensione l'ultimo
    // campione scritto si azzera, così la prima riga esce sempre. A Link spento i campi restano fermi e non si scrive
    // niente. La riga dell'interruttore porta l'etichetta [TIMBRO], come quelle del campionatore.
#if DEBUG
    func setDebugStartStampSampler(_ enabled: Bool) {
        os_log("[Q-BEATS][RIENTRO-P2A][TIMBRO] interruttore DEBUG 'Campionatore del timbro (4-06)' -> %{public}@",
               log: .default, type: .default, enabled ? "acceso" : "spento")
        DispatchQueue.main.async { self.debugStartStampSampler = enabled }
        startStampQueue.async { [weak self] in
            guard let self else { return }
            if enabled {
                self.startStartStampSamplerQ()
            } else {
                self.stopStartStampSamplerQ()
            }
        }
    }

    /// Su `startStampQueue`. Già acceso: niente.
    private func startStartStampSamplerQ() {
        guard self.startStampTimer == nil else { return }
        self.lastSampledStartStamp = nil
        let timer = DispatchSource.makeTimerSource(queue: self.startStampQueue)
        timer.schedule(deadline: .now() + 0.25, repeating: 0.25, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.audioQueue.async { [weak self] in
                guard let self, let read = self.readStartStamp() else { return }
                self.startStampQueue.async { [weak self] in
                    guard let self else { return }
                    guard read.sample != self.lastSampledStartStamp else { return }
                    self.lastSampledStartStamp = read.sample
                    self.writeStartStampLine("campione", read.sample, capturedAt: read.capturedAt)
                }
            }
        }
        timer.resume()
        self.startStampTimer = timer
    }

    /// Su `startStampQueue`. Già spento: niente.
    private func stopStartStampSamplerQ() {
        self.startStampTimer?.cancel()
        self.startStampTimer = nil
    }
#endif

    // =====================================================================================
    // === A386 · FASE B2A (25/09/2026) — IL 2D NEL MOTORE: BATTITO A 1 s, MACCHINA, PORTE ===
    // =====================================================================================
    // Le regole sono pure e testate in QBeats/Models (fase B1, commit 54247fc): qui c'è solo il
    // collegamento. Stato su audioQueue, specchi su main, azioni sul runner via la stanza.
    // Costituzione §4: niente di tutto questo tocca il render callback; il timer è una sorgente
    // GCD su audioQueue; ogni cattura di Link sta su audioQueue.

    /// La soglia del «sento il Direttore»: 3,0 s, provvisori (si fissano al collaudo).
    private var heardThresholdTicks: UInt64 { secondsToMachTicks(3.0) }
    /// Lo spostamento della ripetizione del Direttore: 1 ms.
    private var oneMillisecondTicks: UInt64 { secondsToMachTicks(0.001) }
    /// B2d — oltre questo vuoto dall'ultimo colpo una ripetizione è «in ritardo» (solo log).
    private var heardLateAfterTicks: UInt64 { secondsToMachTicks(DirectorSignalCadence.lateAfterSeconds) }
    private var ticksPerSecond: Double {
        guard machTimebase.numer > 0 else { return 0 }
        return 1_000_000_000.0 * Double(machTimebase.denom) / Double(machTimebase.numer)
    }

    // MARK: Il battito di trasporto a 1 s (Q17): il Direttore ripete, il Follower ascolta
    // ⚠️ B2d (mandato «A386 · FASE B2d», 01/10/2026): «il Follower ascolta» in questo battito non
    //    vale più. Il battito a 1 s resta com'è per il Direttore (la ripetizione) e per le cose al
    //    secondo del Follower (`followerSecondQ`); il segnale «sento il Direttore» lo ascolta un
    //    battito suo a 0,25 s (`startFollowerListen`, `followerListenQ`). Due orologi alla stessa
    //    cadenza, quasi in fase, facevano cadere fra due letture zero o due ripetizioni: nessun
    //    colpo per tre secondi a Direttore presente (collaudo dell'01/10, log `A386_D7_iPad.txt`).
    //    I timer su audioQueue sono due: Q17 («un solo timer») è superata, da ratificare.

    private func startTransportPulse() {
        let timer = DispatchSource.makeTimerSource(queue: audioQueue)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            self?.transportPulse()
        }
        timer.resume()
        transportPulseTimer = timer
    }

    /// Su audioQueue. Una cattura (nessun commit); poi il ruolo decide cosa farne.
    private func transportPulse() {
        guard let lh = linkEngineHandle else { return }
        _pulseCountQ += 1
        let snap = link_engine_read_transport_snapshot(lh)
        let isFollower = FollowerDecision.isFollower(role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
        // Una scrittura propria della linea temporale fra due letture (W2 al confine di
        // sezione, o qualunque altra: il ponte le conta tutte) rende il prossimo cambio
        // dell'ora un'eco, non un colpo (`DirectorHeardTracker`).
        // B2d: da Follower il conto lo tiene e lo consuma il battito d'ascolto (`followerListenQ`),
        // che è l'unico a dare letture al segnale: due consumatori si ruberebbero il cambio. Qui
        // lo si tiene in pari solo negli altri ruoli, così al ritorno a Follower il confronto
        // parte da un valore vecchio al più di un secondo, come prima.
        if !isFollower {
            _lastTimelineWriteCountQ = snap.timelineWriteCount
        }
        if _linkMode == .direttore {
            directorPulse(snapshot: snap)
        } else if isFollower {
            followerSecondQ(snapshot: snap)
        }
        // A410 — con l'àncora viva, la riga al secondo del conteggio in silenzio (nessun timer nuovo:
        // questo battito; mandato A410, §2.4).
        if _silenceAnchorQ != nil {
            logSilenceSecondQ()
        }
        // A412 — col Direttore muto in canzone, al secondo: il tasto della fascia (dipende dal conto di adesso) e
        // lo Stop di fine canzone (mandato §2.3-§2.4). Nessun timer nuovo per il tasto: questo battito.
        if _directorSilentInSongQ {
            directorSilenceSecondQ()
        }
    }

    // MARK: B2d — il battito d'ascolto del Follower a 0,25 s

    /// Sorgente GCD su audioQueue, come il battito di trasporto: nessun salto di coda, ogni
    /// cattura di Link resta su audioQueue. Periodo e leeway da `DirectorSignalCadence` (0,25 s,
    /// 50 ms): fra due letture passano al più 0,30 s, meno della distanza fra due ripetizioni
    /// del Direttore, quindi ogni ripetizione è letta da sola, qualunque sia la fase fra i due
    /// apparecchi. Parte in `init` e non si ferma (l'ascolto parte con l'app); chi non è
    /// Follower esce subito dal passo, senza catturare.
    private func startFollowerListen() {
        let timer = DispatchSource.makeTimerSource(queue: audioQueue)
        let period = DirectorSignalCadence.listenPeriodSeconds
        timer.schedule(deadline: .now() + period, repeating: period,
                       leeway: .milliseconds(DirectorSignalCadence.listenLeewayMilliseconds))
        timer.setEventHandler { [weak self] in
            self?.followerListenQ()
        }
        timer.resume()
        followerListenTimer = timer
    }

    /// Il Direttore ripete il proprio stato: `DirectorReannounceDecision` decide se e con che
    /// segno, il ponte scrive `{isPlaying catturato, ora catturata ± 1 ms}` (da fermo l'ora dello
    /// stop). Log Q7: una riga a ogni cambio di «suona» o di motivo di salto, più una ogni 10.
    /// ⚠️ B2d: il segno alternato, «± 1 ms» e «una ogni 10» non valgono più. Lo spostamento gira
    ///    su quattro passi (+1 ms, −2 ms, +3 ms, −2 ms: l'ora fa T+1, T−1, T+2, T) e lo dà il
    ///    tipo puro (`decision.shift`): quello provato dal banco è quello che va al ponte. Il
    ///    giro avanza solo se il ponte ha scritto (`report.linkEnabled`): un passo contato e non
    ///    scritto lascerebbe l'ora spostata. La riga porta in più `passo:` (0, 1, 2, 3) ed esce
    ///    al cambio di «suona» più una ogni 11 ripetizioni: una ogni 10, con un giro di quattro,
    ///    mostrerebbe sempre gli stessi due passi; una ogni 11 li mostra tutti a turno.
    private func directorPulse(snapshot snap: LinkTransportSnapshot) {
        guard let lh = linkEngineHandle else { return }
        let decision = DirectorReannounceDecision(role: _linkMode,
                                                  userLinkEnabled: _linkUserEnabledQ,
                                                  startStopSyncEnabled: _startStopSyncEnabledQ,
                                                  linkEnabled: snap.linkEnabled,
                                                  showOpen: _showOpenQ,
                                                  sessionPlaying: snap.isPlaying,
                                                  capturedTime: snap.timeForIsPlaying,
                                                  shiftTicks: oneMillisecondTicks,
                                                  cycle: _reannounceCycleQ)
        switch decision.outcome {
        case .skip(let reason):
            let text = describe(reason)
            if text != _lastReannounceSkipQ {
                _lastReannounceSkipQ = text
                _lastReannouncedIsPlayingQ = nil
                os_log("[Q-BEATS][2D][DIRETTORE] ripetizione FERMA motivo:%{public}@",
                       log: .default, type: .default, text)
            }
        case .reannounce(let isPlaying, _):
            _lastReannounceSkipQ = nil
            let report = link_engine_reannounce_transport(lh, snap.captureHostTime, decision.shift)
            // Il ponte non ha scritto (spento fra la cattura del battito e questa chiamata): il
            // giro resta dov'è e la ripetizione non si conta.
            guard report.linkEnabled else { return }
            _reannounceCycleQ = decision.nextCycle
            _reannounceCountQ += 1
            let changed = _lastReannouncedIsPlayingQ != isPlaying
            _lastReannouncedIsPlayingQ = isPlaying
            if changed || _reannounceCountQ % 11 == 0 {
                os_log("[Q-BEATS][2D][DIRETTORE] ripetizione suona:%d oraPrima:%llu oraDopo:%llu segno:%{public}@ passo:%d startStopSync:%d ripetizioni:%llu",
                       log: .default, type: .default,
                       report.isPlaying ? 1 : 0, report.timeBefore, report.timeAfter,
                       decision.shift >= 0 ? "+" : "-", decision.step ?? -1,
                       _startStopSyncEnabledQ ? 1 : 0, _reannounceCountQ)
            }
        }
    }

    /// B2d — su audioQueue, dal battito d'ascolto a 0,25 s (`startFollowerListen`). Il Follower
    /// ascolta: la coppia (suona, ora) cambia entro la soglia ⇒ «sento il Direttore». Sul fronte
    /// del segnale, l'evento alla macchina (D1, DA SOLO, R2). È l'ascolto che fino a B2c stava
    /// nel battito a 1 s (`followerPulse`), con la stessa regola (`DirectorHeardTracker.observe`)
    /// e la stessa soglia: cambia solo ogni quanto si legge. Una cattura per lettura, nessun
    /// commit. Chi non è Follower esce prima di catturare.
    /// Il conto delle scritture proprie della linea temporale si consuma QUI e solo qui quando
    /// si è Follower (vedi `transportPulse`).
    /// Log: la riga `direttore-sentito` esce a ogni cambio del sì/no, con in coda da quanto
    /// mancava un colpo (`vuoto_ms`, `fila` = letture senza colpo di fila) e il conto delle
    /// letture. Al posto della riga «una ogni 10 battiti» c'è il riepilogo dell'ascolto ogni 40
    /// letture (10 s); in più una riga quando una ripetizione è in ritardo (vuoto oltre 1,5 s) e
    /// una quando riprende (`DirectorHeardGapMeter`: conta e basta, non decide niente).
    private func followerListenQ() {
        guard let lh = linkEngineHandle else { return }
        guard FollowerDecision.isFollower(role: _linkMode, userLinkEnabled: _linkUserEnabledQ) else {
            // Chi non è Follower non ascolta. Il conto dei vuoti (solo log) riparte da capo, così
            // al ritorno a Follower non misura un vuoto lungo quanto il tempo passato altrove.
            if _heardGapMeterQ != .start { _heardGapMeterQ = .start }
            return
        }
        _listenCountQ += 1
        let snap = link_engine_read_transport_snapshot(lh)
        let ownTimelineWrite = snap.timelineWriteCount != _lastTimelineWriteCountQ
        _lastTimelineWriteCountQ = snap.timelineWriteCount
        let sample = DirectorHeardSample(linkEnabled: snap.linkEnabled,
                                         isPlaying: snap.isPlaying,
                                         timeForIsPlaying: snap.timeForIsPlaying)
        let verdict = _heardTrackerQ.observe(sample: sample,
                                             now: snap.captureHostTime,
                                             thresholdTicks: heardThresholdTicks,
                                             ownTimelineWriteSinceLastSample: ownTimelineWrite)
        _heardTrackerQ = verdict.next
        let changed = verdict.heard != _directorHeardQ
        _directorHeardQ = verdict.heard
        // B2b — «Searching…» per lo slot E. B2c (§3.f): non si specchia da solo: si scrive la
        // copia di coda, e in fondo a questo passo esce UNA pubblicazione con stato, ragione e
        // segnale insieme (`followerPublishQ`).
        let searchingChanged = verdict.searching != _directorSearchingQ
        if searchingChanged {
            _directorSearchingQ = verdict.searching
            os_log("[Q-BEATS][2D][FOLLOWER] cerca-il-direttore:%d battiti:%llu",
                   log: .default, type: .default, verdict.searching ? 1 : 0, _pulseCountQ)
        }
        let gap = _heardGapMeterQ.observe(linkEnabled: snap.linkEnabled,
                                          hit: verdict.hit,
                                          heard: verdict.heard,
                                          now: snap.captureHostTime,
                                          lateAfterTicks: heardLateAfterTicks,
                                          summaryEvery: DirectorSignalCadence.summaryEverySamples)
        _heardGapMeterQ = gap.next
        if changed {
            let gapText: String = gap.gapTicks.map { String(format: "%.0f", machTicksToSeconds($0) * 1000.0) } ?? "-"
            os_log("[Q-BEATS][2D][FOLLOWER] direttore-sentito:%d colpo:%d scritturaPropria:%d suona:%d oraAvvio:%llu soglia_ms:%.0f battiti:%llu vuoto_ms:%{public}@ fila:%d letture:%llu",
                   log: .default, type: .default,
                   verdict.heard ? 1 : 0, verdict.hit ? 1 : 0, ownTimelineWrite ? 1 : 0,
                   snap.isPlaying ? 1 : 0, snap.timeForIsPlaying,
                   machTicksToSeconds(heardThresholdTicks) * 1000.0, _pulseCountQ,
                   gapText, gap.run, _listenCountQ)
        }
        if let late = gap.late {
            os_log("[Q-BEATS][2D][ASCOLTO] ripetizione-in-ritardo vuoto_ms:%.0f fila:%d sento:%d suona:%d oraAvvio:%llu letture:%llu",
                   log: .default, type: .default,
                   machTicksToSeconds(late.gapTicks) * 1000.0, late.run, verdict.heard ? 1 : 0,
                   snap.isPlaying ? 1 : 0, snap.timeForIsPlaying, _listenCountQ)
        }
        if let resumed = gap.resumed {
            os_log("[Q-BEATS][2D][ASCOLTO] ripetizione-ripresa vuoto_ms:%.0f fila:%d origine:lettura sento:%d letture:%llu",
                   log: .default, type: .default,
                   machTicksToSeconds(resumed.gapTicks) * 1000.0, resumed.run, verdict.heard ? 1 : 0, _listenCountQ)
        }
        if let summary = gap.summary {
            os_log("[Q-BEATS][2D][ASCOLTO] riepilogo campioni:%d colpi:%d senzaColpo:%d filaMax:%d vuotoMax_ms:%.0f ritardi:%d sentiti:%d sento:%d suona:%d oraAvvio:%llu periodo_ms:%.0f soglia_ms:%.0f battiti:%llu letture:%llu",
                   log: .default, type: .default,
                   summary.samples, summary.hits, summary.samplesWithoutHit, summary.maxRun,
                   machTicksToSeconds(summary.maxGapTicks) * 1000.0, summary.lates, summary.heardSamples,
                   verdict.heard ? 1 : 0, snap.isPlaying ? 1 : 0, snap.timeForIsPlaying,
                   DirectorSignalCadence.listenPeriodSeconds * 1000.0,
                   machTicksToSeconds(heardThresholdTicks) * 1000.0, _pulseCountQ, _listenCountQ)
        }
        var action: FollowerSyncAction = .none
        if changed {
            let running = isRunning || isAudioInterrupted
            action = followerTransitionQ(.directorHeard(verdict.heard, engineRunning: running)).action
        }
        if changed || searchingChanged {
            followerPublishQ(action)
        }
    }

    /// B2d — su audioQueue, dal battito a 1 s: le cose al secondo del Follower che non sono
    /// l'ascolto, con la cadenza di prima. «Band playing» (la sessione Link in moto, per lo slot
    /// E): la copia di coda e, se è cambiata, una pubblicazione. Il tempo di sessione per la
    /// riga di W2 saltata. In DA SOLO la riga al secondo.
    private func followerSecondQ(snapshot snap: LinkTransportSnapshot) {
        let playingChanged = snap.isPlaying != _linkSessionPlayingQ
        _linkSessionPlayingQ = snap.isPlaying
        if playingChanged {
            followerPublishQ()
        }
        // B2c-BIS — il tempo di sessione di questo battito, per la riga di W2 saltata in DA SOLO.
        _sessionTempoSeenQ = snap.tempo
        // B2c (§3.d) — in DA SOLO, una riga al secondo col tempo misurato e la posizione di battuta.
        logOwnClockSecondQ(sessionTempo: snap.tempo)
    }

    // MARK: Il cancello del Follower nel richiamo avvio/stop (D6, D7-bis)

    /// Su audioQueue, dal richiamo di Link. Play: mezza battuta a due lati sulla misura della
    /// canzone armata e sul tempo di sessione (Q9, Q10); accettato ⇒ si registra la fase di
    /// avvio. Stop: falsa partenza sui battiti di sessione (D7-bis), motore in moto =
    /// `isRunning || isAudioInterrupted` (Q11). `linkPlay` arriva alla macchina SOLO a motore
    /// fermo (a motore in moto un Play non fa niente, come la guardia `!engine.isPlaying`).
    private func followerHandleLinkTransport(isPlaying: Bool) {
        guard let lh = linkEngineHandle else { return }
        let snap = link_engine_read_transport_snapshot(lh)
        let running = isRunning || isAudioInterrupted
        // A386 · B2c (§3.f) — UN PLAY O UNO STOP RICEVUTO È UN COLPO, SUBITO. Chi arriva qui è
        // Follower, e il Follower non scrive mai lo stato avvio/stop su Link (A360 lo stop, A361
        // l'avvio, W4 l'ingresso): questo richiamo nasce da un altro apparecchio della sessione,
        // cioè dalla stessa cosa che il battito a 1 s chiama colpo — solo che il battito la vede
        // fino a un secondo dopo, e in quel secondo lo schermo diceva «No director signal» con lo
        // Stop del Direttore appena ricevuto (collaudo, log `A386_C2_iPad.txt`, 14:17:36). La
        // cattura è la stessa letta qui sopra; diventa l'ultimo campione del segnale, e il
        // battito successivo non conta due volte lo stesso cambio.
        // ⚠️ B2d: «il battito a 1 s» e «fino a un secondo dopo» qui sopra sono di prima: da B2d
        //    le letture del segnale le fa il battito d'ascolto a 0,25 s (`followerListenQ`). Il
        //    colpo del richiamo resta, per la stessa ragione; l'ultimo campione resta uno solo,
        //    scritto su questa coda da qui e dall'ascolto.
        let verdict = _heardTrackerQ.observeTransportEvent(
            sample: DirectorHeardSample(linkEnabled: snap.linkEnabled,
                                        isPlaying: snap.isPlaying,
                                        timeForIsPlaying: snap.timeForIsPlaying),
            now: snap.captureHostTime,
            thresholdTicks: heardThresholdTicks)
        _heardTrackerQ = verdict.next
        // B2d — il colpo del richiamo chiude anche il vuoto in corso nel conto dell'ascolto.
        let gap = _heardGapMeterQ.observeTransportEvent(linkEnabled: snap.linkEnabled,
                                                        now: snap.captureHostTime)
        _heardGapMeterQ = gap.next
        if let resumed = gap.resumed {
            os_log("[Q-BEATS][2D][ASCOLTO] ripetizione-ripresa vuoto_ms:%.0f fila:%d origine:richiamo-%{public}@ sento:%d letture:%llu",
                   log: .default, type: .default,
                   machTicksToSeconds(resumed.gapTicks) * 1000.0, resumed.run,
                   isPlaying ? "avvio" : "stop", verdict.heard ? 1 : 0, _listenCountQ)
        }
        let heardChanged = verdict.heard != _directorHeardQ
        _directorHeardQ = verdict.heard
        if verdict.searching != _directorSearchingQ {
            _directorSearchingQ = verdict.searching
            os_log("[Q-BEATS][2D][FOLLOWER] cerca-il-direttore:%d battiti:%llu",
                   log: .default, type: .default, verdict.searching ? 1 : 0, _pulseCountQ)
        }
        os_log("[Q-BEATS][2D][FOLLOWER] direttore-sentito:%d colpo:%d origine:richiamo-%{public}@ suona:%d oraAvvio:%llu soglia_ms:%.0f battiti:%llu",
               log: .default, type: .default,
               verdict.heard ? 1 : 0, verdict.hit ? 1 : 0, isPlaying ? "avvio" : "stop",
               snap.isPlaying ? 1 : 0, snap.timeForIsPlaying,
               machTicksToSeconds(heardThresholdTicks) * 1000.0, _pulseCountQ)
        // B2b — la sessione Link è in moto (o ferma) da adesso: lo slot E lo sa subito, senza
        // aspettare il battito. B2c: la copia di coda si scrive qui; allo schermo arriva con stato,
        // ragione e segnale nella pubblicazione unica che chiude questo passo.
        _linkSessionPlayingQ = isPlaying
        // Il fronte del segnale va alla macchina PRIMA del Play o dello Stop, come lo avrebbe
        // mandato il battito (un «sento» non cambia stato in nessun ramo della tabella).
        var heardAction: FollowerSyncAction = .none
        if heardChanged {
            heardAction = followerTransitionQ(.directorHeard(verdict.heard, engineRunning: running)).action
        }
        if isPlaying {
            if running {
                os_log("[Q-BEATS][2D][FOLLOWER] play ignorato - motore in moto (isRunning:%d interrotto:%d)",
                       log: .default, type: .default, isRunning ? 1 : 0, isAudioInterrupted ? 1 : 0)
                followerPublishQ(heardAction)
                return
            }
            let halfBar = HalfBarWindow.halfBarTicks(beatsPerBar: _songFirstBeatsPerBarQ,
                                                     bpm: snap.tempo,
                                                     ticksPerSecond: ticksPerSecond)
            let within = HalfBarWindow.isWithin(announced: snap.timeForIsPlaying,
                                                now: snap.captureHostTime,
                                                halfBarTicks: halfBar)
            let gapMs: Double
            if snap.captureHostTime >= snap.timeForIsPlaying {
                gapMs = machTicksToSeconds(snap.captureHostTime - snap.timeForIsPlaying) * 1000.0
            } else {
                gapMs = -machTicksToSeconds(snap.timeForIsPlaying - snap.captureHostTime) * 1000.0
            }
            os_log("[Q-BEATS][2D][FOLLOWER] play annunciata:%llu adesso:%llu scarto_ms:%.1f mezzaBattuta_ms:%.1f bpm:%.2f bpb:%u entro:%d",
                   log: .default, type: .default,
                   snap.timeForIsPlaying, snap.captureHostTime, gapMs,
                   machTicksToSeconds(halfBar) * 1000.0, snap.tempo, _songFirstBeatsPerBarQ, within ? 1 : 0)
            let transition = followerTransitionQ(.linkPlay(withinHalfBar: within))
            if transition.action == .start {
                _startPhaseQ = snap.phaseAtStampQBig
                os_log("[Q-BEATS][2D][AVVIO] fase di avvio registrata contesto:play-direttore fase:%.6f oraAvvio:%llu",
                       log: .default, type: .default, snap.phaseAtStampQBig, snap.timeForIsPlaying)
            }
            followerPublishQ(heardAction, transition.action)
        } else {
            let falseStart = falseStartAgainstRegisteredStart(stopPhase: snap.phaseAtStampQBig,
                                                              context: "stop-direttore-ricevuto")
            _startPhaseQ = nil
            let transition = followerTransitionQ(.linkStop(falseStart: falseStart, engineRunning: running))
            followerPublishQ(heardAction, transition.action)
        }
    }

    /// Su audioQueue. La falsa partenza (D7-bis): `beatDelta` a giro simmetrico fra la fase di
    /// avvio registrata e la fase dello stop, contro una battuta della prima sezione. Senza un
    /// avvio registrato non è una falsa partenza.
    private func falseStartAgainstRegisteredStart(stopPhase: Double, context: String) -> Bool {
        guard let startPhase = _startPhaseQ else {
            os_log("[Q-BEATS][2D][STOP] contesto:%{public}@ faseStop:%.6f nessun avvio registrato - falsaPartenza:0",
                   log: .default, type: .default, context, stopPhase)
            return false
        }
        let delta = FalseStartDecision.beatDelta(startPhase: startPhase, stopPhase: stopPhase, modulus: 1_000_000.0)
        let margin = FalseStartDecision.marginBeats(beatsPerBar: _songFirstBeatsPerBarQ)
        let falseStart = FalseStartDecision.isFalseStart(stopBeat: delta, startBeat: 0.0, marginBeats: margin)
        os_log("[Q-BEATS][2D][STOP] contesto:%{public}@ faseAvvio:%.6f faseStop:%.6f delta_battiti:%.6f margine_battiti:%.1f falsaPartenza:%d",
               log: .default, type: .default, context, startPhase, stopPhase, delta, margin, falseStart ? 1 : 0)
        return falseStart
    }

    /// Su audioQueue, dopo il Play vero scritto su Link dal Direttore (battito zero): la fase di
    /// sessione dell'avvio, primo termine della falsa partenza (D7-bis). La ripresa dopo
    /// un'interruzione NON la registra (B2A-bis): resta la fase del Play.
    private func registerStartPhase(context: String) {
        guard let lh = linkEngineHandle else { return }
        // A411 · SOLO-INERTE — nel Solo il motore non legge la sessione: l'istantanea è quella del ponte
        // spento (tutti zeri), come a Link spento, qualunque cosa dica l'accensione.
        let snap = soloLockPassesQ(.startWrite) ? link_engine_read_transport_snapshot(lh) : LinkTransportSnapshot()
        _startPhaseQ = snap.phaseAtStampQBig
        os_log("[Q-BEATS][2D][AVVIO] fase di avvio registrata contesto:%{public}@ fase:%.6f oraAvvio:%llu suona:%d",
               log: .default, type: .default, context, snap.phaseAtStampQBig, snap.timeForIsPlaying, snap.isPlaying ? 1 : 0)
    }

    // MARK: La macchina del Follower: una transizione, un log, le azioni su main

    /// Su audioQueue. Transizione pura (`FollowerSyncDecision`), log con evento, stati, azione
    /// e ragione; poi su main le azioni: `start()` + `linkStartedSubject` (il ramo di sempre),
    /// `stop()`, e le richieste al runner via la stanza. L'ordine su main è: stop, poi azione
    /// sul runner (`.standby`), poi arriva il `.stopped` del motore, che lo specchio scarta.
    /// B2b-BIS: in coda allo stesso passo su main, lo specchio unico `followerSync` (stato e
    /// ragione insieme, una scrittura per transizione), dopo l'azione sul runner: la stanza
    /// ricalcola la proposta una volta, coi numeri del runner già avanzato.
    /// ⚠️ B2c (§3.f) — DUE METÀ, e questa le chiama in fila: `followerTransitionQ` (la transizione,
    ///    lo stato di coda, la riga di log) e `followerPublishQ` (le azioni su main e la scrittura
    ///    dello specchio). Chi in un passo solo cambia anche il segnale, o passa da due
    ///    transizioni (il battito, il richiamo avvio/stop, il tocco sulla lista), chiama le due
    ///    metà da sé e pubblica UNA volta. Le righe qui sopra descrivono le due metà insieme.
    @discardableResult
    private func followerApply(_ event: FollowerSyncEvent) -> FollowerSyncTransition {
        let transition = followerTransitionQ(event)
        followerPublishQ(transition.action)
        return transition
    }

    /// Su audioQueue. La transizione pura, lo stato di coda e la riga di log. NON pubblica e non
    /// agisce: il passo si chiude con `followerPublishQ`.
    private func followerTransitionQ(_ event: FollowerSyncEvent) -> FollowerSyncTransition {
        let before = _followerSyncQ
        let transition = FollowerSyncDecision.transition(state: before, event: event)
        _followerSyncQ = transition.state
        if let reason = transition.outReason {
            _followerOutReasonQ = reason
        } else if case .out = transition.state {
            // resta la ragione dell'ultima uscita
        } else {
            _followerOutReasonQ = nil
        }
        os_log("[Q-BEATS][2D][FOLLOWER] evento:%{public}@ stato:%{public}@->%{public}@ azione:%{public}@ ragione:%{public}@ motore:%{public}@ sento:%d",
               log: .default, type: .default,
               describe(event), describe(before), describe(transition.state), describe(transition.action),
               describe(_followerOutReasonQ), isRunning ? "in-moto" : "fermo", _directorHeardQ ? 1 : 0)
        // B2c — entrando in DA SOLO il motore passa al proprio orologio (e ci resta fino
        // all'arresto, o a un `reset`: `FollowerLinkFollowDecision.ownClockUntilStop`).
        let ownClockBefore = _ownClockUntilStopQ
        _ownClockUntilStopQ = FollowerLinkFollowDecision.ownClockUntilStop(after: event,
                                                                          state: transition.state,
                                                                          previous: ownClockBefore)
        if ownClockBefore && !_ownClockUntilStopQ {
            os_log("[Q-BEATS][2D][DA-SOLO] orologio proprio FINITO - reset della macchina - stato:%{public}@ battito:%d buffer:%d",
                   log: .default, type: .default,
                   describe(transition.state), beatTickCounter, bufferCount)
        }
        if case .alone = transition.state, before != .alone {
            followerEnterOwnClockQ()
        }
        return transition
    }

    /// Su audioQueue. Chiude un passo della macchina: su main, nell'ordine, le azioni (al più
    /// due: quella del fronte del segnale e quella del Play o dello Stop) e poi UNA scrittura
    /// dello specchio `followerSync`, coi cinque valori letti QUI dalle copie di coda — stato,
    /// ragione, «sento il Direttore», «Searching…», «band playing». Lo schermo non può vedere
    /// uno di loro nuovo e gli altri vecchi (B2b-BIS per stato e ragione; B2c per il segnale).
    private func followerPublishQ(_ first: FollowerSyncAction = .none, _ second: FollowerSyncAction = .none) {
        let snapshot = FollowerSyncSnapshot(state: _followerSyncQ,
                                            outReason: _followerOutReasonQ,
                                            directorHeard: _directorHeardQ,
                                            directorSearching: _directorSearchingQ,
                                            linkSessionPlaying: _linkSessionPlayingQ)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.followerRun(first)
            self.followerRun(second)
            // B2b-BIS: dopo l'azione sul runner (il `send` di `followerRun` è sincrono:
            // `handleFollowerRunnerAction` è già passato). Chi ascolta (`QLiveSession`) calcola
            // la proposta in questo stesso passo; lo schermo legge stato, ragione, segnale e
            // proposta al ridisegno successivo, tutti nuovi.
            self.followerSync = snapshot
        }
    }

    /// Solo main. Un'azione della macchina sul motore e sul runner (via la stanza).
    private func followerRun(_ action: FollowerSyncAction) {
        switch action {
        case .none:
            break
        case .start:
            // Q-D4 esteso — lo stesso lucchetto del ramo di sempre (`_linkStartEmitInFlight`).
            if !self._linkStartEmitInFlight {
                self._linkStartEmitInFlight = true
                self.start()
                self.linkStartedSubject.send()
            }
        case .stop:
            self.stop()
        case .stopAndArmNext:
            self.stop()
            self.followerRunnerActionSubject.send(.armNext)
        case .armNext:
            self.followerRunnerActionSubject.send(.armNext)
        case .stopAndRearmSame:
            self.stop()
            self.followerRunnerActionSubject.send(.rearmSame)
        case .rearmSame:
            self.followerRunnerActionSubject.send(.rearmSame)
        case .armSong(let songIdx):
            // B2b: arriva su main PRIMA di ogni azione decisa dopo su audioQueue (per esempio
            // l'avvio al Play): stessa coda, FIFO.
            self.followerRunnerActionSubject.send(.armSong(songIdx: songIdx))
        }
    }

    // MARK: B2c — DA SOLO il Follower suona la sua canzone: l'orologio proprio

    /// Su audioQueue. La decisione unica letta dalle due strade audio (richiamo del tempo di
    /// Link, correzione di fase in `scheduleNextBuffer`): tre confronti, nessuna allocazione,
    /// nessuna chiamata a Link.
    private func followsLinkQ() -> Bool {
        FollowerLinkFollowDecision.followsLink(role: _linkMode,
                                               userLinkEnabled: _linkUserEnabledQ,
                                               state: _followerSyncQ,
                                               ownClockUntilStop: _ownClockUntilStopQ)
    }

    /// Su audioQueue, alla soglia di DA SOLO. Da qui il click va «ai tempi delle sue sezioni»: se
    /// il tempo in corso era stato adottato dalla sessione dopo l'ultimo tempo della propria
    /// canzone, il motore torna a quello della sezione (`_audioBPM`: lo scrivono solo le strade
    /// proprie — `applyBPM`, il cambio di sezione — mai il richiamo di Link). Stesso passo
    /// immediato di `applyBPM`: metronomo, e sequencer MIDI ri-ancorato alla posizione di prima.
    /// Se un cambio di sezione è già armato non si tocca niente: il tempo proprio arriva al
    /// prossimo battere. Azzera i contatori e il riferimento della riga al secondo.
    private func followerEnterOwnClockQ() {
        let adopted = _linkTempoAdoptedQ
        let restore = FollowerLinkFollowDecision.tempoToRestore(sectionTempo: _audioBPM,
                                                                adoptedFromLink: adopted,
                                                                sectionChangePending: _pendingBPMValue != nil)
        if let bpm = restore {
            if let h = metronomeHandle {
                metronome_setBPM(h, bpm)
            }
            if let mh = midiEngineHandle {
                let preChangeBeatPos = midi_engine_get_beat_position(mh)
                midi_engine_set_bpm(mh, bpm)
                midi_engine_set_beat_position(mh, preChangeBeatPos)
            }
            _linkTempoAdoptedQ = nil
            _engineTempoQ = bpm
            DispatchQueue.main.async { [weak self] in self?.currentBPM = bpm }
        }
        // La linea propria si àncora al primo buffer del tratto (`ownClockPinQ`).
        _ownTimelineQ = nil
        _ownClockPinsQ = 0
        _ownClockMaxLagMsQ = 0.0
        _ownClockIgnoredTempoQ = 0
        _ownClockLogRefTickQ = beatTickCounter
        _ownClockLogRefSampleQ = _lastBeatSampleQ
        _ownClockLogRefOutTicksQ = _lastBeatOutTicksQ
        let adoptedText: String = adopted.map { String(format: "%.4f", $0) } ?? "nessuno"
        os_log("[Q-BEATS][2D][DA-SOLO] orologio proprio DA ADESSO - tempoSezione:%.2f tempoAdottatoDaLink:%{public}@ tempoRidato:%d battito:%d sezione:%d/%d buffer:%d",
               log: .default, type: .default,
               _audioBPM, adoptedText, restore != nil ? 1 : 0,
               beatTickCounter, _sectionBeatCounter, _sectionTotalBeats, bufferCount)
    }

    /// Su audioQueue, dal richiamo del tempo di Link: un cambio di tempo della sessione ignorato
    /// perché il Follower è sul proprio orologio (§3.d).
    private func logSessionTempoIgnoredQ(_ sessionBPM: Double) {
        _ownClockIgnoredTempoQ += 1
        os_log("[Q-BEATS][2D][DA-SOLO] tempo della sessione IGNORATO sessione:%.2f sezione:%.2f stato:%{public}@ battito:%d - il click resta sul tempo della propria canzone",
               log: .default, type: .default,
               sessionBPM, _audioBPM, describe(_followerSyncQ), beatTickCounter)
    }

    /// Su audioQueue, da `scheduleNextBuffer`, al posto della correzione di fase di Link: la
    /// posizione si riporta sulla LINEA DEL TEMPO PROPRIA (`OwnClockTimeline`), non su quella di
    /// Link, che qui non si chiama nemmeno. La meccanica è quella di IN SYNC — a ogni buffer
    /// sequencer e metronomo vanno sul battito previsto per l'ora d'uscita, con le stesse due
    /// chiamate — e serve alla stessa cosa: tenere il click sull'ora dell'apparecchio quando i
    /// buffer arrivano in ritardo (collaudo dell'01/10/2026: 267 ms accumulati in venti secondi
    /// di DA SOLO mentre si apre il Centro di Controllo). Cambia solo la linea: un'àncora e il
    /// tempo della propria sezione, senza rete e senza altri apparecchi.
    /// Al primo buffer del tratto la linea si àncora dove IN SYNC ha lasciato la posizione
    /// (nessun salto), con una riga di log; dal secondo in poi si riporta e si conta. `mh` e `h`
    /// sono gli stessi che usa il ramo di Link.
    private func ownClockPinQ(midi mh: MIDIEngineHandle,
                              metronome h: MetronomeHandle,
                              hostTimeAtOutput: UInt64,
                              currentBeat: Double) {
        guard let timeline = _ownTimelineQ else {
            _ownTimelineQ = OwnClockTimeline(anchorTicks: hostTimeAtOutput,
                                             anchorBeat: currentBeat,
                                             bpm: _engineTempoQ)
            os_log("[Q-BEATS][2D][DA-SOLO] correzione di fase di Link NON ESEGUITA da questo buffer - linea propria ancorata ora:%llu battito:%.4f tempo:%.2f buffer:%d stato:%{public}@",
                   log: .default, type: .default,
                   hostTimeAtOutput, currentBeat, _engineTempoQ, bufferCount, describe(_followerSyncQ))
            return
        }
        let ownBeat = timeline.beat(atTicks: hostTimeAtOutput, ticksPerSecond: ticksPerSecond)
        midi_engine_set_beat_position(mh, ownBeat)
        metronome_set_beat_position_time_only(h, ownBeat)
        // A421 — U9: il secondo punto della correzione (l'orologio proprio): il battito scavalcato che uscirebbe in ritardo di
        // almeno un buffer si conta e non si suona.
        noteLateBeatCorrectionQ(before: currentBeat, after: ownBeat, bpm: timeline.bpm, point: "orologio-proprio")
        _ownClockPinsQ += 1
        let lagMs = abs(OwnClockTimeline.lagMilliseconds(ownBeat: ownBeat, localBeat: currentBeat, bpm: timeline.bpm))
        if lagMs > _ownClockMaxLagMsQ {
            _ownClockMaxLagMsQ = lagMs
        }
    }

    /// Su audioQueue, dal battito a 1 s. In DA SOLO, una riga al secondo per misurare il tempo
    /// al collaudo senza le righe «Phase sync» (§3.d). Formato fisso, campi `chiave:valore`:
    ///   tempoMisurato   battiti al minuto fra l'ultimo battito di questa riga e quello della
    ///                   riga precedente, contati sull'ORA d'uscita dei due battiti
    ///                   (`ClickTempoMeasure`): è il tempo che si sente. Su un secondo oscilla di
    ///                   qualche decimo. `-` se fra le due righe non è uscito nessun battito
    ///   tempoCampioni   lo stesso conto sui campioni consegnati al player: esatto a regime; sale
    ///                   per un attimo quando un buffer arriva in ritardo e il click recupera
    ///   tempoSezione    il tempo della sezione in corso della propria canzone (`_audioBPM`)
    ///   tempoLinea      il tempo della linea propria (`OwnClockTimeline`); `-` se da ancorare
    ///   tempoSessione   il tempo della sessione Link letto dal battito (0 a ponte spento): si
    ///                   legge e basta, per vedere nel log che cosa viene ignorato
    ///   battito         battiti suonati dall'avvio del motore (`beatTickCounter`)
    ///   sezione         battito dentro la sezione / battiti della sezione
    ///   battuta         battuta.battito dentro la sezione; `-` se la sezione non conta
    ///   buffer          buffer consegnati dall'avvio del motore
    ///   riportati       buffer riportati sulla linea propria dall'ultima riga
    ///   ritardoMax_ms   il ritardo più grande dei buffer sull'ora, riassorbito dall'ultima riga
    ///   tempiIgnorati   cambi di tempo della sessione ignorati dall'ultima riga
    ///   motore          in-moto | interrotto | fermo
    private func logOwnClockSecondQ(sessionTempo: Double) {
        guard case .alone = _followerSyncQ else { return }
        // Dopo un riavvio del motore (ripresa da un'interruzione) i contatori ripartono da zero:
        // il riferimento vecchio non vale più.
        if beatTickCounter < _ownClockLogRefTickQ
            || _lastBeatSampleQ < _ownClockLogRefSampleQ
            || _lastBeatOutTicksQ < _ownClockLogRefOutTicksQ {
            _ownClockLogRefTickQ = beatTickCounter
            _ownClockLogRefSampleQ = _lastBeatSampleQ
            _ownClockLogRefOutTicksQ = _lastBeatOutTicksQ
        }
        let beats = beatTickCounter - _ownClockLogRefTickQ
        let measured = ClickTempoMeasure.bpm(beats: beats,
                                             ticks: _lastBeatOutTicksQ - _ownClockLogRefOutTicksQ,
                                             ticksPerSecond: ticksPerSecond)
        let measuredText: String = measured.map { String(format: "%.1f", $0) } ?? "-"
        let bySamples = ClickTempoMeasure.bpm(beats: beats,
                                              samples: _lastBeatSampleQ - _ownClockLogRefSampleQ,
                                              sampleRate: sampleRate)
        let bySamplesText: String = bySamples.map { String(format: "%.2f", $0) } ?? "-"
        let lineText: String = _ownTimelineQ.map { String(format: "%.2f", $0.bpm) } ?? "-"
        let position = ClickTempoMeasure.barPosition(sectionBeat: _sectionBeatCounter,
                                                     beatsPerBar: _beatsPerBarQ)
        let positionText: String = position.map { "\($0.bar).\($0.beatInBar)" } ?? "-"
        let engineText: String = isRunning ? "in-moto" : (isAudioInterrupted ? "interrotto" : "fermo")
        os_log("[Q-BEATS][2D][DA-SOLO] al-secondo tempoMisurato:%{public}@ tempoCampioni:%{public}@ tempoSezione:%.2f tempoLinea:%{public}@ tempoSessione:%.2f battito:%d sezione:%d/%d battuta:%{public}@ buffer:%d riportati:%d ritardoMax_ms:%.1f tempiIgnorati:%d motore:%{public}@",
               log: .default, type: .default,
               measuredText, bySamplesText, _audioBPM, lineText, sessionTempo,
               beatTickCounter, _sectionBeatCounter, _sectionTotalBeats, positionText,
               bufferCount, _ownClockPinsQ, _ownClockMaxLagMsQ, _ownClockIgnoredTempoQ, engineText)
        _ownClockLogRefTickQ = beatTickCounter
        _ownClockLogRefSampleQ = _lastBeatSampleQ
        _ownClockLogRefOutTicksQ = _lastBeatOutTicksQ
        _ownClockPinsQ = 0
        _ownClockMaxLagMsQ = 0.0
        _ownClockIgnoredTempoQ = 0
    }

    /// Su audioQueue. `reset` solo se c'è qualcosa da azzerare: prima di ogni show la macchina è
    /// già FUORI non armato, e un Direttore non deve produrre righe di Follower.
    private func followerResetQ(reason: String) {
        _startPhaseQ = nil
        if _followerSyncQ == FollowerSyncDecision.initial && _followerOutReasonQ == nil { return }
        os_log("[Q-BEATS][2D][FOLLOWER] reset motivo:%{public}@", log: .default, type: .default, reason)
        followerApply(.reset)
    }

    // MARK: Le porte (chiamabili da main): armare, fine canzone propria, Stop del musicista, reset

    /// La misura della PRIMA sezione della canzone armata/in corso (la scrive il runner).
    func setSongFirstBeatsPerBar(_ beatsPerBar: UInt32) {
        audioQueue.async { [weak self] in
            self?._songFirstBeatsPerBarQ = max(beatsPerBar, 1)
        }
    }

    /// A410 — la mappa della canzone che parte, per il conteggio in silenzio (`ShowClock`): la
    /// consegna il runner a ogni avvio di canzone, accanto alla misura qui sopra, con l'indice della
    /// canzone e la sezione da cui parte il click. Qui diventa una copia di coda. Una riga a ogni
    /// consegna, con un'etichetta sua ([CONTEGGIO]): esce a ogni avvio di canzone, anche senza crisi.
    /// ⚠️ A412 — la consegna porta le sezioni della canzone (la mappa si fa qui, dalle stesse sezioni): al
    /// rientro il motore carica da lì la sezione d'arrivo. E dice che il prossimo avvio è l'avvio di una
    /// canzone («canzone in corso», `CrisisStopDecision`). Prima diceva «nient'altro la legge fuori dal
    /// blocco A410»: da A412 la legge il coordinatore del rientro.
    func setSongMap(sections: [SongSection], songIdx: Int, startSection: Int) {
        let map = SongMap(songSections: sections)
        audioQueue.async { [weak self] in
            guard let self else { return }
            self._songMapQ = map
            self._songSectionsQ = sections
            self._songMapSongIdxQ = songIdx
            self._songMapSectionQ = startSection
            self._songMapForNextStartQ = true
            os_log("[Q-BEATS][CONTEGGIO] mappa songIdx:%d sezioni:%d partenza:%d valida:%d",
                   log: .default, type: .default,
                   songIdx, map.sections.count, startSection, map.isValid ? 1 : 0)
        }
    }

    /// Un tocco sulla lista d'ingresso (A1) o su RIENTRA (R1): «sento il Direttore» e «la sessione
    /// è ferma» si leggono qui, nell'istante dell'armamento, su audioQueue. Su chi non è Follower
    /// non fa niente.
    /// B2b (decisione del referee — l'armamento cambia runner e misura SOLO se la macchina lo
    /// accetta): la decisione viene PRIMA; accettata, la misura della canzone scelta si scrive
    /// qui, nello stesso passo, e il runner si arma su main con l'azione `armSong` della macchina
    /// (che arriva su main prima di ogni azione decisa dopo, per esempio l'avvio al Play);
    /// rifiutata o ignorata, runner e misura non si toccano. Ogni Play o Stop legge la misura su
    /// QUESTA coda, dopo questo passo: è sempre quella della canzone armata nella macchina, anche
    /// dopo due tocchi ravvicinati, che qui si serializzano. `entry` («join» / «rejoin») serve
    /// solo alla riga di log del tocco.
    func followerArm(songIdx: Int, songFirstBeatsPerBar: UInt32, entry: String) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard FollowerDecision.isFollower(role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ) else {
                os_log("[Q-BEATS][2D][TOCCO] lista canzone:%d %{public}@ esito:ignorato - non Follower (ruolo:%{public}@ linkUtente:%d)",
                       log: .default, type: .default,
                       songIdx, entry, String(describing: self._linkMode), self._linkUserEnabledQ ? 1 : 0)
                return
            }
            var sessionPlaying = false
            if let lh = self.linkEngineHandle {
                sessionPlaying = link_engine_read_transport_snapshot(lh).isPlaying
            }
            // B2c: «band playing» si scrive sulla copia di coda e arriva allo schermo con lo stato
            // e la ragione di questo stesso tocco, nella pubblicazione unica di `followerApply`.
            self._linkSessionPlayingQ = sessionPlaying
            let arming = FollowerArming(source: .rientra(songIdx: songIdx),
                                        directorHeard: self._directorHeardQ,
                                        sessionPlaying: sessionPlaying)
            let transition = self.followerApply(.armed(arming))
            let outcome: String
            if case .armSong(let armed) = transition.action {
                // Accettato: la misura della canzone scelta, nello stesso passo, prima di ogni
                // Play o Stop che la leggerà su questa coda.
                self._songFirstBeatsPerBarQ = max(songFirstBeatsPerBar, 1)
                outcome = "accettato(armato:\(armed) bpb:\(self._songFirstBeatsPerBarQ))"
            } else if let reason = transition.outReason {
                outcome = "rifiutato(\(self.describe(reason)))"
            } else {
                outcome = "ignorato(\(self.describe(transition.state)))"
            }
            os_log("[Q-BEATS][2D][TOCCO] lista canzone:%d %{public}@ esito:%{public}@",
                   log: .default, type: .default, songIdx, entry, outcome)
        }
    }

    /// B2b (A2) — «show aperto»: il runner sta nello slot della stanza. Lo alza
    /// `QLiveSession.install`, lo abbassano `QLiveSession.endShow` (END SHOW) e l'uscita dalla
    /// stanza (`AppRootView`, accanto a `followerReset`): non i bottoni, e non la morte
    /// dell'oggetto. Il Direttore ripete il proprio stato solo a show aperto
    /// (`DirectorReannounceDecision`, motivo di salto `showClosed`): a show chiuso, allo scadere
    /// della soglia, i Follower vanno FUORI. Una riga di log a ogni cambio.
    func setShowOpen(_ open: Bool, origin: String) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard self._showOpenQ != open else { return }
            self._showOpenQ = open
            os_log("[Q-BEATS][2D][SHOW] show aperto:%d origine:%{public}@ ruolo:%{public}@",
                   log: .default, type: .default, open ? 1 : 0, origin, String(describing: self._linkMode))
            // A421 · SEGUITO 1 (par. 4.3) — l'apertura dello show azzera la memoria dell'ultima uscita a volume 1 (come la
            // chiusura) senza toccare «uscita mancante» né «uscita zittita»: il primo avvio di ogni show è come oggi, qualunque
            // uscita abbia usato il click prima dello show (anche nel Solo). La riga esce qui: `noteOutputStateQ` scrive solo
            // quando «uscita mancante» cambia.
            if open {
                let memoryBefore: String = self._outputSilenceQ.lastOutputExternal.map { $0 ? "esterna" : "interna" } ?? "-"
                self.noteOutputStateQ(.showOpened, from: "show-aperto")
                os_log("[Q-BEATS][USCITA] memoria dell'ultima uscita azzerata da:show-aperto prima:%{public}@ - il primo avvio dello show e' come oggi",
                       log: .default, type: .default, memoryBefore)
            }
            // A410 — la chiusura dello show chiude l'àncora del conteggio in silenzio.
            // A412 — e il silenzio del Direttore e la canzone in corso (di norma li ha già chiusi lo Stop
            // voluto che END SHOW e l'uscita dalla stanza mandano prima).
            if !open {
                self.closeSilenceAnchorQ(reason: "show-chiuso")
                self._songInProgressQ = false
                self.leaveDirectorSilenceQ(reason: "show-chiuso", closeAnchor: false)
                // A421 — la chiusura dello show abbassa «uscita mancante» e «uscita zittita» (U5) e annulla i ritorni
                // (par. 2.3 b). Col motore in moto a volume 0 (il Follower muto) il volume torna qui, coi servizi audio
                // normali (A408: sul motore morto non si scrive niente): stato «uscita zittita» e mixer restano una cosa sola.
                self.cancelOutputReturnsQ(reason: "show-chiuso")
                if self.isRunning && self._outputSilenceQ.muted && MediaServicesResetDecision.allowsAudioWork(self._mediaServicesQ) {
                    self.writeOutputVolumeQ(1, reason: "show-chiuso")
                }
                self.noteOutputStateQ(.showClosed, from: "show-chiuso")
            }
        }
    }

    /// La propria canzone è finita (il runner ha già armato la successiva): D2 in DA SOLO.
    func followerOwnSongEnded() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard FollowerDecision.isFollower(role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ) else { return }
            self.followerApply(.ownSongEnded)
        }
    }

    /// Lo Stop del musicista (la striscia DA SOLO, B2b): il solo punto d'ingresso.
    func followerMusicianStop() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            guard FollowerDecision.isFollower(role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ) else { return }
            self.followerApply(.musicianStop)
        }
    }

    /// END SHOW, uscita dalla stanza (la stanza e il runner muoiono): la macchina si azzera.
    func followerReset(reason: String) {
        audioQueue.async { [weak self] in
            self?.followerResetQ(reason: reason)
        }
    }

    // MARK: La notifica del numero dei collegati (solo schermo)

    /// «ABLLink.NumberOfPeersChanged» ([R] ABLLink.mm LinkKit-4.0:176-177, mandata su main
    /// dallo stesso richiamo che decide il collegato ufficiale, solo a Link acceso): l'`object`
    /// è un NSNumber, nessun userInfo. ⚠️ Interfaccia NON documentata: se un aggiornamento di
    /// LinkKit la cambia, il numero resta `nil` — cioè nascosto, che è il ripiego dichiarato.
    private func registerPeerCountNotification() {
        peerCountObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("ABLLink.NumberOfPeersChanged"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            let count = (note.object as? NSNumber)?.intValue
            self?.linkPeerCount = count
            os_log("[Q-BEATS][2D][PEERS] numero:%{public}@",
                   log: .default, type: .default, count.map { String($0) } ?? "nil")
        }
    }

    // MARK: Le parole dei log

    private func describe(_ state: FollowerSyncState) -> String {
        switch state {
        case .inSync(let songClosed): return songClosed ? "IN-SYNC(chiusa)" : "IN-SYNC(aperta)"
        case .alone: return "DA-SOLO"
        case .out(let armed):
            if let armed { return "FUORI(armato:\(armed))" }
            return "FUORI"
        }
    }

    private func describe(_ event: FollowerSyncEvent) -> String {
        switch event {
        case .linkPlay(let within): return within ? "play-entro-mezza-battuta" : "play-oltre-mezza-battuta"
        case .linkStop(let falseStart, let running): return "stop(falsaPartenza:\(falseStart ? 1 : 0) motore:\(running ? "in-moto" : "fermo"))"
        case .directorHeard(let heard, let running): return "direttore-sentito:\(heard ? 1 : 0)(motore:\(running ? "in-moto" : "fermo"))"
        case .ownSongEnded: return "fine-canzone-propria"
        case .musicianStop: return "stop-musicista"
        case .armed(let arming): return "armato(\(describe(arming.source)) sento:\(arming.directorHeard ? 1 : 0) sessione:\(arming.sessionPlaying ? "in-moto" : "ferma"))"
        case .reset: return "reset"
        }
    }

    private func describe(_ source: FollowerArming.Source) -> String {
        switch source {
        case .rientra(let songIdx): return "rientra:\(songIdx)"
        }
    }

    private func describe(_ action: FollowerSyncAction) -> String {
        switch action {
        case .none: return "nessuna"
        case .start: return "parti"
        case .stop: return "fermati"
        case .stopAndArmNext: return "fermati+arma-successiva"
        case .armNext: return "arma-successiva"
        case .stopAndRearmSame: return "fermati+riarma-stessa"
        case .rearmSame: return "riarma-stessa"
        case .armSong(let songIdx): return "arma-scelta:\(songIdx)"
        }
    }

    private func describe(_ reason: FollowerOutReason?) -> String {
        guard let reason else { return "-" }
        switch reason {
        case .playLate: return "play-oltre-mezza-battuta"
        case .lostWhileStopped: return "non-sento-da-fermo(D1)"
        case .lostWhileArmed(let chosen): return "non-sento-da-armato(R2 scelta:\(chosen))"
        case .aloneSongEnded: return "fine-canzone-da-solo(D2)"
        case .directorStoppedWhileAlone: return "direttore-fermo-da-solo(D2)"
        case .directorFalseStartWhileAlone: return "falsa-partenza-da-solo(D7-bis)"
        case .musicianStop: return "stop-musicista"
        case .armRefusedNotHeard(let chosen): return "armamento-rifiutato:non-sento(R1 scelta:\(chosen))"
        case .armRefusedSessionPlaying(let chosen): return "armamento-rifiutato:sessione-in-moto(R1 scelta:\(chosen))"
        case .reset: return "reset"
        }
    }

    private func describe(_ reason: DirectorReannounceDecision.SkipReason) -> String {
        switch reason {
        case .notDirector: return "non-direttore"
        case .userLinkOff: return "link-utente-spento"
        case .startStopSyncOff: return "start-stop-sync-spento"
        case .linkUnavailable: return "ponte-spento"
        case .showClosed: return "show-chiuso"
        }
    }

    // =====================================================================================
    // === A410 (16/10/2026) — DIRETTORE IN CRISI, PASSO 1: IL CONTEGGIO IN SILENZIO ==========
    // =====================================================================================
    // L'àncora, la riga al secondo; più lo sgombero della ripresa pendente alla Lost e alla Reset (A410
    // §2.8). Tutto su audioQueue; le letture di Link sono catture senza commit
    // (`link_engine_read_session_at`, `link_engine_time_at_beat`, MIDIEngineBridge.h). Le righe:
    // [Q-BEATS][CONTEGGIO] (la mappa, a ogni avvio di canzone, `setSongMap`) e [Q-BEATS][DIR-SILENZIO]
    // (àncora, riga al secondo, chiusura dell'àncora: solo nel silenzio del Direttore).
    // ⚠️ RISCRITTO A412 (18/10/2026). Il testo di prima diceva «Solo misure (mandato A410, §2)» e
    // «[Q-BEATS][DIR-RIENTRO] (cosa farebbe il rientro: SOLO REGISTRO)»: era il passo 1. Da A412 la riga
    // [DIR-RIENTRO] è la decisione del coordinatore che agisce (blocco «A412» qui sotto), e la funzione che
    // scriveva «cosa farebbe» (`logDirectorRejoinPlanQ`) non c'è più. Indici come nel runner:
    // `songIdx` e `sectionIdx` da 0, battuta e battito da 1; una posizione si scrive
    // `sectionIdx.battuta.battito`. Il testo delle righe è senza accenti, per le ricerche nei
    // registri esportati.
    // ⚠️ A412 · SEGUITO 2 (18/10/2026) — LA NUMERAZIONE DELLA SESSIONE. Fino al seguito 1 l'àncora, i due
    // righelli, «stesso avvio», il bersaglio, il ponte e la fine canzone leggevano Link a quantum 1: la parte
    // intera di quei battiti è dell'apparecchio, e un cambio di tempo fatto da un altro col Direttore muto può
    // rinumerarla di un battito intero con la sessione ferma (collaudo di A412 delle 16:24: rientro rifiutato,
    // «avvio cambiato», «mappa e ponte in disaccordo»). Da qui leggono la numerazione della sessione
    // (`DirectorRejoinDecision.sessionQuantum`, i campi `…QBig` di `LinkSessionReading`); le righe scrivono
    // accanto anche i valori a quantum 1 (`…Q1`, quelli di prima, e i campi `…Q1e6` per i nuovi).

    /// L'àncora del conteggio, nel punto in cui il motore del Direttore tace senza Stop. Chiamare SOLO
    /// su audioQueue, PRIMA che `isRunning` vada a falso. ⚠️ A412: la chiama solo `enterDirectorSilenceQ`,
    /// a ogni crisi del Direttore in canzone (da A412 alla Lost e alla Reset senza Lost il motore si ferma in
    /// locale subito dopo; prima restava com'era). Il battito è
    /// l'ultimo contato già uscito, non uno solo accodato; il battito di Link si legge all'ora di quel
    /// battito e nel conto entra l'intero più vicino (la griglia della sessione). Non è
    /// il battito di ripresa del motore: quello resta dell'orologio MIDI.
    /// ⚠️ RISCRITTO A412 · SEGUITO 2 (18/10/2026). Il testo di prima diceva «il battito di Link si legge
    /// all'ora di quel battito con quantum 1, e nel conto entra l'intero più vicino (la griglia della
    /// sessione)»: a quantum 1 la parte intera è dell'apparecchio e può saltare di uno (collaudo delle 16:24).
    /// Nel conto entra ora l'intero più vicino del battito nella numerazione della sessione
    /// (`beatAtHostTimeQBig`); la riga scrive anche quello a quantum 1, accanto.
    private func takeSilenceAnchorQ(cause: String) {
        guard DirectorRejoinDecision.takesAnchor(role: _linkMode,
                                                 userLinkEnabled: _linkUserEnabledQ,
                                                 showOpen: _showOpenQ,
                                                 engineRunning: isRunning,
                                                 hasSongMap: _songMapQ != nil) else {
            if _linkMode == .direttore {
                os_log("[Q-BEATS][DIR-SILENZIO] ancora non presa causa:%{public}@ - linkUtente:%d show:%d motore:%{public}@ mappa:%d",
                       log: .default, type: .default,
                       cause, _linkUserEnabledQ ? 1 : 0, _showOpenQ ? 1 : 0,
                       isRunning ? "in-moto" : "fermo", _songMapQ != nil ? 1 : 0)
            }
            return
        }
        if let alive = _silenceAnchorQ {
            os_log("[Q-BEATS][DIR-SILENZIO] ancora gia' viva (causa:%{public}@) - causa nuova:%{public}@ ignorata",
                   log: .default, type: .default, alive.cause, cause)
            return
        }
        guard let map = _songMapQ, let lh = linkEngineHandle else { return }
        let now = mach_absolute_time()
        let beat: CountedBeat
        let which: String
        if let last = _lastCountedBeatQ, last.outTicks <= now {
            beat = last
            which = "ultimo"
        } else if let previous = _prevCountedBeatQ, previous.outTicks <= now {
            beat = previous
            which = "penultimo"
        } else {
            os_log("[Q-BEATS][DIR-SILENZIO] ancora non presa causa:%{public}@ - nessun battito contato gia' uscito",
                   log: .default, type: .default, cause)
            return
        }
        let read = link_engine_read_session_at(lh, beat.outTicks, 1.0)
        guard read.linkEnabled else {
            os_log("[Q-BEATS][DIR-SILENZIO] ancora non presa causa:%{public}@ - ponte di Link spento",
                   log: .default, type: .default, cause)
            return
        }
        let grid = read.beatAtHostTime.rounded()
        // A412 · SEGUITO 2 — la griglia del conto nella numerazione della sessione (`grid` resta per la riga).
        let gridSession = read.beatAtHostTimeQBig.rounded()
        let clock = ShowClock(map: map,
                              anchor: ShowClockAnchor(section: beat.section,
                                                      beatInSection: beat.beatInSection,
                                                      linkBeat: gridSession,
                                                      ticks: beat.outTicks))
        _silenceAnchorQ = SilenceAnchor(clock: clock, songIdx: _songMapSongIdxQ, sections: _songSectionsQ,
                                        cause: cause, takenTicks: now, startTicks: read.timeForIsPlaying,
                                        startBeatQ1: read.beatAtStartQ1, startBeatQBig: read.beatAtStartQBig)
        let position = clock.barAndBeat(section: beat.section, beatInSection: Double(max(beat.beatInSection, 0)))
        let total: Int = (beat.section >= 0 && beat.section < map.sections.count)
            ? (map.sections[beat.section].totalBeats ?? 0) : 0
        let check: String = clock.invalidity.map { describe($0) } ?? "ok"
        os_log("[Q-BEATS][DIR-SILENZIO] ancora presa causa:%{public}@ songIdx:%d posizione:%d.%d.%d indice:%d/%d battito:%{public}@ oraBattito:%llu adesso:%llu battitoLinkQ1:%.6f griglia:%.0f scartoGriglia:%.4f battitoLinkQ1e6:%.6f grigliaQ1e6:%.0f tempoSessione:%.3f tempoMotore:%.3f suona:%d oraAvvio:%llu battitoAvvio:%.6f battitoAvvioQ1e6:%.6f conto:%{public}@",
               log: .default, type: .default,
               cause, _songMapSongIdxQ, beat.section, position.bar, position.beat,
               beat.beatInSection, total, which, beat.outTicks, now,
               read.beatAtHostTime, grid, read.beatAtHostTime - grid,
               read.beatAtHostTimeQBig, gridSession, read.tempo, _audioBPM,
               read.isPlaying ? 1 : 0, read.timeForIsPlaying, read.beatAtStartQ1, read.beatAtStartQBig, check)
    }

    /// L'àncora si chiude. Chiamare SOLO su audioQueue. `reason`: avvio | stop | show-chiuso, e da A412 rientro |
    /// fine-canzone | sessione-ferma | fuori-coordinatore | cambio-di-ruolo | link-utente-spento. (Il campo
    /// `stopProprio` della riga è uscito con `SilenceAnchor.ownStopSent`, A412.)
    private func closeSilenceAnchorQ(reason: String) {
        guard let anchor = _silenceAnchorQ else { return }
        _silenceAnchorQ = nil
        os_log("[Q-BEATS][DIR-SILENZIO] ancora chiusa motivo:%{public}@ causa:%{public}@ vissuta_s:%.1f",
               log: .default, type: .default,
               reason, anchor.cause, secondsSince(anchor.takenTicks))
    }

    /// La riga al secondo dell'àncora viva, dal battito a 1 s (`transportPulse`): la posizione dai
    /// due righelli, lo scarto, il tempo della sessione, «suona», l'avvio della sessione (mandato A410,
    /// §2.4). La fase della scena la scrive già la riga [LIFECYCLE] (`QBeatsApp`). Chiamare SOLO su
    /// audioQueue. Una cattura senza commit.
    private func logSilenceSecondQ() {
        guard let anchor = _silenceAnchorQ, let lh = linkEngineHandle else { return }
        let now = mach_absolute_time()
        let clock = anchor.clock
        let read = link_engine_read_session_at(lh, now, 1.0)
        guard read.linkEnabled else {
            let bySeconds = clock.bySeconds(nowTicks: now, ticksPerSecond: ticksPerSecond)
            os_log("[Q-BEATS][DIR-SILENZIO] al-secondo songIdx:%d battiti:- secondi:%{public}@ link:0 dallAncora_s:%.1f",
                   log: .default, type: .default,
                   anchor.songIdx, describe(place: bySeconds.place, in: clock), secondsSince(anchor.takenTicks))
            return
        }
        // A412 · SEGUITO 2 — il conto e «stesso avvio» nella numerazione della sessione; quella a quantum 1 resta
        // nella riga, accanto (il prossimo «uno» anche nella numerazione di prima, con la distanza di questa cattura).
        let reading = clock.read(nowLinkBeat: read.beatAtHostTimeQBig, nowTicks: now, ticksPerSecond: ticksPerSecond)
        let same = DirectorRejoinDecision.sameStart(anchorStartBeat: anchor.startBeatQBig,
                                                    nowStartBeat: read.beatAtStartQBig)
        let gapText: String = reading.gapBeats.map { String(format: "%.4f", $0) } ?? "-"
        let offset = DirectorRejoinDecision.deviceOffset(beatQuantumOne: read.beatAtHostTime,
                                                         beatSession: read.beatAtHostTimeQBig)
        var nextText = "-"
        var nextSessionText = "-"
        if case .inSong(_, _, _, let next?) = reading.outcome {
            nextSessionText = String(format: "%.0f", next.linkBeat)
            if let offset {
                nextText = String(format: "%.0f", next.linkBeat + offset)
            }
        }
        var sinceSectionText = "-"
        if case .inSong(_, let beatInSection) = reading.byLinkBeats.place, read.tempo > 0, read.tempo.isFinite {
            sinceSectionText = String(format: "%.0f", beatInSection * 60_000.0 / read.tempo)
        }
        os_log("[Q-BEATS][DIR-SILENZIO] al-secondo songIdx:%d battiti:%{public}@ secondi:%{public}@ scarto_battiti:%{public}@ certo:%d daInizioSezione_ms:%{public}@ prossimoUno:%{public}@ prossimoUnoQ1e6:%{public}@ battitoLinkQ1:%.4f battitoLinkQ1e6:%.4f tempoSessione:%.3f suona:%d oraAvvio:%llu battitoAvvio:%.6f battitoAvvioQ1e6:%.6f stessoAvvio:%d link:1 dallAncora_s:%.1f",
               log: .default, type: .default,
               anchor.songIdx,
               describe(place: reading.byLinkBeats.place, in: clock),
               describe(place: reading.bySeconds.place, in: clock),
               gapText, reading.certain ? 1 : 0, sinceSectionText, nextText, nextSessionText,
               read.beatAtHostTime, read.beatAtHostTimeQBig, read.tempo, read.isPlaying ? 1 : 0,
               read.timeForIsPlaying, read.beatAtStartQ1, read.beatAtStartQBig, same ? 1 : 0,
               secondsSince(anchor.takenTicks))
    }

    // =====================================================================================
    // === A412 (18/10/2026) — DIRETTORE IN CRISI, PASSO 2: IL SILENZIO CHE AGISCE ==============
    // =====================================================================================
    // Mandato del referee «DIRETTORE-IN-CRISI-PASSO-2». Quando il click si ferma senza che nessuno abbia
    // premuto Stop (interruzione, servizi audio persi, reset, cambio di configurazione o di modo), il telefono
    // del Direttore in canzone non manda niente alla band e non chiude la canzone: tace, conta dove sta la band
    // (l'àncora e la riga al secondo, blocco «A410») e rientra alla battuta giusta senza spostare nessuno. Se
    // non è certo tace solo lui; se la canzone finisce durante il silenzio manda lo Stop di fine canzone, solo
    // col conto certo. Il Solo, dopo una crisi della sessione audio, si ferma come allo Stop della sua console e
    // aspetta il Play. Le regole sono pure, col loro banco, in Models/: `CrisisStopDecision` (ogni crisi),
    // `DirectorRejoinDecision` (coordinatore, armamento, Stop di fine canzone), `DirectorTransportDecision` (il
    // tasto e il pedale), `RecoveryDecision` (le ripartenze automatiche), `LinkActivationDecision` (lo sfondo).
    // Qui il collegamento, tutto su audioQueue salvo dove è detto. Le letture di Link sono catture senza commit
    // (`link_engine_read_session_at`, `link_engine_time_at_beat`); l'unica scrittura verso Link di questo blocco
    // è lo Stop di fine canzone (`link_engine_stop`, la stessa dello Stop voluto). Niente nel render callback.
    // Le righe (testo senza accenti): [Q-BEATS][CRISI] la decisione a ogni crisi, l'arresto locale, il
    // silenzio; [Q-BEATS][DIR-RIENTRO] decisione, bersaglio (alla decisione e all'armamento), fuoco, primo
    // buffer, «segue Link», Stop di fine canzone; [Q-BEATS][DIR-TASTO] il tasto e il pedale; [Q-BEATS][RESUME]
    // ogni ripartenza automatica instradata.

    /// Il bersaglio del rientro: lo decide il coordinatore, lo consuma l'ingresso (`armSharedJoin`, T3).
    /// Sezione da 0, battuta da 1, battito nella sezione da 0; battito di Link; il quantum della
    /// sezione d'arrivo (A376 P10: passato col bersaglio, non letto dal motore, che porta ancora la sezione del
    /// silenzio); ora d'uscita dalla mappa e dal ponte alla decisione (0 = ponte spento); quanti salti per
    /// ritardo restano.
    /// ⚠️ RISCRITTO A412 · SEGUITO 2 (18/10/2026): diceva «battito di Link a quantum 1». `linkBeat` è ora nella
    /// numerazione della sessione (`DirectorRejoinDecision.sessionQuantum`), e il ponte lo legge con quel
    /// quantum; `linkBeatQ1` è lo stesso battito nella numerazione a quantum 1 della decisione, solo per le
    /// righe (il ponte come lo leggeva A412, accanto a quello nuovo).
    private struct RejoinTarget {
        let songIdx: Int
        let section: Int
        let bar: Int
        let beatInSection: Int
        let linkBeat: Double
        let linkBeatQ1: Double
        let quantum: Double
        let mapTicks: UInt64
        let bridgeTicks: UInt64
        let trigger: String
        let lateSkipsLeft: Int
    }

    /// Cosa fa `start()` dopo il coordinatore.
    private enum CoordinatorStep {
        /// Il ramo del rientro, col bersaglio.
        case rejoin(RejoinTarget)
        /// Resta muto: conto non certo, canzone finita (Stop armato), sessione ferma da altri (T6). Nessun avvio.
        case stayMuted
        /// Fuori dal coordinatore: il silenzio è chiuso e l'avvio prosegue come oggi.
        case proceedAsToday
    }

    /// La regola di ogni crisi (`CrisisStopDecision`) dalle copie di coda, con la sua riga. Chiamare SOLO su
    /// audioQueue, PRIMA di toccare `isRunning`. Una crisi che trova qualcosa da fermare (o il Direttore già
    /// muto) ricorda la sua causa per le ripartenze (`RecoveryDecision`) e azzera «Stop voluto dopo la crisi».
    private func crisisOutcomeQ(cause: CrisisCause) -> CrisisStopOutcome {
        let role = PlayerRoleDecision.playerRole(role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
        let outcome = CrisisStopDecision.outcome(playerRole: role,
                                                 cause: cause,
                                                 showOpen: _showOpenQ,
                                                 songInProgress: _songInProgressQ,
                                                 engineRunning: isRunning,
                                                 silentInSong: _directorSilentInSongQ)
        if outcome != .nothing {
            // A421 — la causa ricordata: per il Solo una causa che lo ferma resta finché non riparte col Play (U4).
            _crisisCauseQ = CrisisStopDecision.rememberedCause(previous: _crisisCauseQ, new: cause, playerRole: role)
            _wantedStopSinceCrisisQ = false
        }
        os_log("[Q-BEATS][CRISI] decisione causa:%{public}@ ruolo:%{public}@ show:%d canzone:%d motore:%{public}@ muto:%d -> esito:%{public}@ stopALink:%d",
               log: .default, type: .default,
               cause.rawValue, role.rawValue, _showOpenQ ? 1 : 0, _songInProgressQ ? 1 : 0,
               isRunning ? "in-moto" : "fermo", _directorSilentInSongQ ? 1 : 0, outcome.rawValue,
               outcome.sendsStopToLink ? 1 : 0)
        return outcome
    }

    /// Il Direttore entra nel silenzio in canzone, o ci resta a una crisi nuova: l'àncora del conteggio (se il
    /// motore suona ancora) e lo stato; un rientro armato non vale più (l'ingresso lo annulla chi ferma). Chiamare
    /// SOLO su audioQueue, PRIMA di `isRunning = false`: l'àncora prende l'ultimo battito contato già uscito. Il
    /// tasto lo pubblica chi chiama, a stato finito (`publishDirectorSilenceQ`).
    private func enterDirectorSilenceQ(cause: CrisisCause) {
        if isRunning {
            takeSilenceAnchorQ(cause: cause.rawValue)
        }
        _rejoinArmedQ = false
        guard !_directorSilentInSongQ else {
            os_log("[Q-BEATS][CRISI] Direttore gia' muto in canzone - causa nuova:%{public}@ - resta muto, ancora:%d",
                   log: .default, type: .default, cause.rawValue, _silenceAnchorQ != nil ? 1 : 0)
            return
        }
        _directorSilentInSongQ = true
        _songEndNotSentLoggedQ = false
        os_log("[Q-BEATS][CRISI] Direttore muto in canzone causa:%{public}@ songIdx:%d ancora:%d - nessuno Stop a Link, la canzone resta aperta",
               log: .default, type: .default, cause.rawValue, _songMapSongIdxQ, _silenceAnchorQ != nil ? 1 : 0)
    }

    /// Il silenzio finisce (rientro, Stop di fine canzone, sessione ferma da altri, uscita dal coordinatore,
    /// cambio di ruolo, levetta spenta, chiusura dello show; lo Stop voluto lo chiude in `stopSync`). Chiamare
    /// SOLO su audioQueue.
    private func leaveDirectorSilenceQ(reason: String, closeAnchor: Bool) {
        if closeAnchor {
            closeSilenceAnchorQ(reason: reason)
        }
        _songEndStopWorkQ?.cancel()
        _songEndStopWorkQ = nil
        _songEndStopPlannedTicksQ = nil
        // A412 · SEGUITO 3 — col work item si ferma il timer dello Stop di fine canzone.
        _songEndStopTimerQ.cancel()
        guard _directorSilentInSongQ else { return }
        _directorSilentInSongQ = false
        _rejoinArmedQ = false
        os_log("[Q-BEATS][CRISI] silenzio del Direttore finito motivo:%{public}@",
               log: .default, type: .default, reason)
        publishDirectorSilenceQ(context: "fine:\(reason)")
    }

    /// L'esito del tasto della fascia e del pedale playPause (`DirectorTransportDecision`) allo specchio
    /// `directorSilence`, con la riga [DIR-TASTO] a ogni cambio. «Un rientro adesso è possibile» = il
    /// coordinatore, letto adesso, dice «rientra» e nessun rientro è già armato. `plan`: il conto già letto da
    /// chi chiama (il battito a 1 s), per non catturare due volte. Chiamare SOLO su audioQueue.
    private func publishDirectorSilenceQ(context: String, plan: DirectorRejoinDecision.Plan? = nil) {
        let role = PlayerRoleDecision.playerRole(role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
        var possible = false
        if _directorSilentInSongQ && !_rejoinArmedQ {
            let current = plan ?? currentRejoinPlanQ().plan
            if case .rejoin = current.outcome { possible = true }
        }
        let interrupted = isAudioInterrupted
        let lost = _mediaServicesQ == .servicesLost
        let silence = DirectorTransportDecision.silence(playerRole: role,
                                                        silentInSong: _directorSilentInSongQ,
                                                        rejoinPossibleNow: possible,
                                                        interruptionActive: interrupted,
                                                        servicesLost: lost)
        guard silence != _directorSilencePublishedQ else { return }
        _directorSilencePublishedQ = silence
        let reason = DirectorTransportDecision.reason(playerRole: role,
                                                      silentInSong: _directorSilentInSongQ,
                                                      rejoinPossibleNow: possible,
                                                      interruptionActive: interrupted,
                                                      servicesLost: lost)
        let key: String = silence.map { $0.showsPlay ? "play" : "stop" } ?? "come-oggi"
        os_log("[Q-BEATS][DIR-TASTO] tasto:%{public}@ tocco:%{public}@ motivo:%{public}@ rientroArmato:%d contesto:%{public}@ - fascia e pedale playPause",
               log: .default, type: .default,
               key, silence?.tap.rawValue ?? "-", reason?.rawValue ?? "-", _rejoinArmedQ ? 1 : 0, context)
        DispatchQueue.main.async {
            self.directorSilence = silence
        }
    }

    /// Il coordinatore letto adesso (`DirectorRejoinDecision.coordinate`): una cattura di Link senza commit. Rende
    /// anche la lettura della sessione e l'ora, per le righe. Chiamare SOLO su audioQueue.
    /// A412 · SEGUITO 2 — conto e «stesso avvio» nella numerazione della sessione (`…QBig`); la cattura dà anche
    /// i battiti a quantum 1, che restano per le righe.
    private func currentRejoinPlanQ() -> (plan: DirectorRejoinDecision.Plan, read: LinkSessionReading, now: UInt64) {
        let now = mach_absolute_time()
        var read = LinkSessionReading()
        if let lh = linkEngineHandle {
            read = link_engine_read_session_at(lh, now, 1.0)
        }
        let anchor = _silenceAnchorQ
        let same: Bool = anchor.map {
            DirectorRejoinDecision.sameStart(anchorStartBeat: $0.startBeatQBig, nowStartBeat: read.beatAtStartQBig)
        } ?? false
        let windowSeconds = sampleRate > 0
            ? Double(AudioEngine.kRejoinSectionWindowBuffers * Int(bufferSize)) / sampleRate
            : 0
        let situation = DirectorRejoinDecision.Situation(role: _linkMode,
                                                         userLinkEnabled: _linkUserEnabledQ,
                                                         showOpen: _showOpenQ,
                                                         linkEnabled: read.linkEnabled,
                                                         sessionPlaying: read.isPlaying,
                                                         sameStart: same,
                                                         nowLinkBeat: read.beatAtHostTimeQBig,
                                                         nowTicks: now,
                                                         ticksPerSecond: ticksPerSecond,
                                                         sessionTempo: read.tempo,
                                                         marginSeconds: AudioEngine.kRejoinMarginSeconds,
                                                         windowSeconds: windowSeconds)
        return (DirectorRejoinDecision.coordinate(clock: anchor?.clock, situation: situation), read, now)
    }

    /// IL COORDINATORE (mandato §2.2). Chiamare SOLO su audioQueue: da `start()`, col Direttore muto in canzone,
    /// dopo i rifiuti e la ricostruzione del reset; e dal fuoco del rientro in ritardo (il bersaglio dopo). La
    /// decisione si scrive sempre; poi l'esito:
    ///  · rientra: il bersaglio con l'ora della mappa e quella del ponte (`.rejoin`);
    ///  · canzone finita: lo Stop di fine canzone, armato all'ora giusta (`scheduleDirectorSongEndStopQ`);
    ///  · non certo: resta muto, nessuno Stop (D4 (a));
    ///  · sessione ferma da altri (T6): il velo della stessa canzone, nessun avvio;
    ///  · fuori dal coordinatore: il silenzio si chiude e l'avvio prosegue come oggi.
    private func coordinateDirectorRejoinQ(trigger: String, resume: Bool, lateSkipsLeft: Int) -> CoordinatorStep {
        let current = currentRejoinPlanQ()
        let plan = current.plan
        logCoordinatorDecisionQ(plan: plan, read: current.read, trigger: trigger, resume: resume)
        switch plan.outcome {
        case .rejoin(let section, let bar, let linkBeat):
            guard let anchor = _silenceAnchorQ,
                  section >= 0, section < anchor.clock.map.sections.count,
                  section < anchor.sections.count else {
                os_log("[Q-BEATS][DIR-RIENTRO] rientro non eseguito motivo:stato-mancante - resta muto, nessuno Stop a Link",
                       log: .default, type: .default)
                publishDirectorSilenceQ(context: "decisione", plan: plan)
                return .stayMuted
            }
            let bpb = max(anchor.clock.map.sections[section].beatsPerBar, 1)
            let beatInSection = (bar - 1) * bpb
            guard let mapTicks = anchor.clock.ticks(section: section, beatInSection: beatInSection,
                                                    ticksPerSecond: ticksPerSecond) else {
                os_log("[Q-BEATS][DIR-RIENTRO] rientro non eseguito motivo:ora-della-mappa-mancante - resta muto, nessuno Stop a Link",
                       log: .default, type: .default)
                publishDirectorSilenceQ(context: "decisione", plan: plan)
                return .stayMuted
            }
            // A412 · SEGUITO 2 — il ponte nella numerazione della sessione; accanto, per la riga, il ponte come lo
            // leggeva A412 (lo stesso battito nella numerazione a quantum 1 di questa decisione, quantum 1).
            let offset = DirectorRejoinDecision.deviceOffset(beatQuantumOne: current.read.beatAtHostTime,
                                                             beatSession: current.read.beatAtHostTimeQBig)
            let linkBeatQ1: Double = offset.map { linkBeat + $0 } ?? .nan
            var bridgeTicks: UInt64 = 0
            var bridgeTicksQ1: UInt64 = 0
            if let lh = linkEngineHandle {
                let time = link_engine_time_at_beat(lh, linkBeat, DirectorRejoinDecision.sessionQuantum)
                if time.linkEnabled { bridgeTicks = time.hostTime }
                if linkBeatQ1.isFinite {
                    let timeQ1 = link_engine_time_at_beat(lh, linkBeatQ1, 1.0)
                    if timeQ1.linkEnabled { bridgeTicksQ1 = timeQ1.hostTime }
                }
            }
            let sectionBPM = anchor.clock.map.sections[section].bpm
            let check = DirectorRejoinDecision.armingCheck(mapTicks: mapTicks, bridgeTicks: bridgeTicks,
                                                           sectionBPM: sectionBPM,
                                                           ticksPerSecond: ticksPerSecond)
            let checkQ1 = DirectorRejoinDecision.armingCheck(mapTicks: mapTicks, bridgeTicks: bridgeTicksQ1,
                                                             sectionBPM: sectionBPM,
                                                             ticksPerSecond: ticksPerSecond)
            logRejoinTargetQ(phase: "decisione", section: section, bar: bar, linkBeat: linkBeat, linkBeatQ1: linkBeatQ1,
                             mapTicks: mapTicks, bridgeTicks: bridgeTicks, check: check,
                             bridgeTicksQ1: bridgeTicksQ1, checkQ1: checkQ1, nowTicks: current.now)
            return .rejoin(RejoinTarget(songIdx: anchor.songIdx, section: section, bar: bar,
                                        beatInSection: beatInSection, linkBeat: linkBeat, linkBeatQ1: linkBeatQ1,
                                        quantum: Double(bpb),
                                        mapTicks: mapTicks, bridgeTicks: bridgeTicks, trigger: trigger,
                                        lateSkipsLeft: lateSkipsLeft))
        case .songEnded(let endLinkBeat, _):
            scheduleDirectorSongEndStopQ(endLinkBeat: endLinkBeat, read: current.read, context: "decisione")
            publishDirectorSilenceQ(context: "decisione", plan: plan)
            return .stayMuted
        case .uncertain:
            os_log("[Q-BEATS][DIR-RIENTRO] resta muto - conto non certo, nessuno Stop a Link (D4 a); a fine pezzo serve lo Stop del batterista",
                   log: .default, type: .default)
            publishDirectorSilenceQ(context: "decisione", plan: plan)
            return .stayMuted
        case .sessionStoppedElsewhere:
            applySessionStoppedElsewhereQ(context: "decisione")
            return .stayMuted
        case .notCoordinated:
            os_log("[Q-BEATS][DIR-RIENTRO] fuori dal coordinatore - il silenzio finisce, l'avvio prosegue come oggi",
                   log: .default, type: .default)
            leaveDirectorSilenceQ(reason: "fuori-coordinatore", closeAnchor: true)
            return .proceedAsToday
        }
    }

    /// La riga della decisione del coordinatore: gli stessi campi della riga di A410, senza «SOLO REGISTRO» e con
    /// l'innesco (chi ha chiesto l'avvio). Senza àncora, la riga corta. Chiamare SOLO su audioQueue.
    private func logCoordinatorDecisionQ(plan: DirectorRejoinDecision.Plan, read: LinkSessionReading,
                                         trigger: String, resume: Bool) {
        guard let anchor = _silenceAnchorQ else {
            os_log("[Q-BEATS][DIR-RIENTRO] decisione esito:%{public}@ innesco:%{public}@ ripresa:%d suona:%d link:%d tempoSessione:%.3f ancora:0",
                   log: .default, type: .default,
                   describe(plan.outcome), trigger, resume ? 1 : 0, read.isPlaying ? 1 : 0,
                   read.linkEnabled ? 1 : 0, read.tempo)
            return
        }
        let clock = anchor.clock
        // A412 · SEGUITO 2 — «stesso avvio» nella numerazione della sessione; la riga scrive i due avvii a quantum 1
        // (com'era) e, accanto, i due nella numerazione della sessione.
        let same = DirectorRejoinDecision.sameStart(anchorStartBeat: anchor.startBeatQBig,
                                                    nowStartBeat: read.beatAtStartQBig)
        let beatsText: String = plan.reading.map { describe(place: $0.byLinkBeats.place, in: clock) } ?? "-"
        let secondsText: String = plan.reading.map { describe(place: $0.bySeconds.place, in: clock) } ?? "-"
        let gapText: String = plan.reading?.gapBeats.map { String(format: "%.4f", $0) } ?? "-"
        let rulersText: String = plan.reading.map { $0.certain ? "accordo" : "disaccordo" } ?? "-"
        os_log("[Q-BEATS][DIR-RIENTRO] decisione esito:%{public}@ innesco:%{public}@ ripresa:%d suona:%d stessoAvvio:%d battitoAvvio:%.6f->%.6f battitoAvvioQ1e6:%.6f->%.6f oraAvvio:%llu->%llu battiti:%{public}@ secondi:%{public}@ scarto_battiti:%{public}@ righelli:%{public}@ finestra:%d link:%d tempoSessione:%.3f causa:%{public}@ dallAncora_s:%.1f",
               log: .default, type: .default,
               describe(plan.outcome), trigger, resume ? 1 : 0, read.isPlaying ? 1 : 0, same ? 1 : 0,
               anchor.startBeatQ1, read.beatAtStartQ1, anchor.startBeatQBig, read.beatAtStartQBig,
               anchor.startTicks, read.timeForIsPlaying,
               beatsText, secondsText, gapText, rulersText, plan.windowShifts,
               read.linkEnabled ? 1 : 0, read.tempo, anchor.cause, secondsSince(anchor.takenTicks))
    }

    /// La riga del bersaglio, alla decisione e all'armamento (mandato §2.9): l'ora della mappa, quella del ponte,
    /// lo scarto in millisecondi e in battiti al tempo della sezione d'arrivo, l'accordo (1/8 di battito, T2; alla
    /// decisione solo registro: il ponte non conosce i cambi di tempo davanti).
    /// A412 · SEGUITO 2 — `battitoLink` resta il battito nella numerazione a quantum 1 della decisione (com'era);
    /// accanto `battitoLinkQ1e6`, quello nella numerazione della sessione che il ponte legge e l'accordo usa. In
    /// coda il ponte come lo leggeva A412 (`oraPonteQ1`, `mappaMenoPonteQ1_ms`: lo stesso battito a quantum 1),
    /// solo per vedere le due cose insieme: non decide niente.
    private func logRejoinTargetQ(phase: String, section: Int, bar: Int, linkBeat: Double, linkBeatQ1: Double,
                                  mapTicks: UInt64, bridgeTicks: UInt64,
                                  check: DirectorRejoinDecision.ArmingCheck,
                                  bridgeTicksQ1: UInt64, checkQ1: DirectorRejoinDecision.ArmingCheck,
                                  nowTicks: UInt64) {
        let gapMs: String = check.gapSeconds.map { String(format: "%.1f", $0 * 1000.0) } ?? "-"
        let gapBeats: String = check.gapBeats.map { String(format: "%.4f", $0) } ?? "-"
        let gapMsQ1: String = checkQ1.gapSeconds.map { String(format: "%.1f", $0 * 1000.0) } ?? "-"
        let linkBeatQ1Text: String = linkBeatQ1.isFinite ? String(format: "%.0f", linkBeatQ1) : "-"
        os_log("[Q-BEATS][DIR-RIENTRO] bersaglio fase:%{public}@ sectionIdx:%d battuta:%d battitoLink:%{public}@ battitoLinkQ1e6:%.0f oraMappa:%llu oraPonte:%llu mappaMenoPonte_ms:%{public}@ scarto_battiti:%{public}@ accordo:%d daAdesso_ms:%.1f oraPonteQ1:%llu mappaMenoPonteQ1_ms:%{public}@",
               log: .default, type: .default,
               phase, section, bar, linkBeatQ1Text, linkBeat, mapTicks, bridgeTicks, gapMs, gapBeats,
               check.agree ? 1 : 0, signedMilliseconds(from: nowTicks, to: mapTicks), bridgeTicksQ1, gapMsQ1)
    }

    /// T6 — la sessione Link non suona più: il Direttore resta muto sul velo della stessa canzone, con una riga,
    /// e non avvia niente (`.rearmSame` alla stanza). Niente riparte da solo dopo. Chiamare SOLO su audioQueue,
    /// a motore fermo.
    private func applySessionStoppedElsewhereQ(context: String) {
        os_log("[Q-BEATS][DIR-RIENTRO] sessione ferma da altri - il Direttore resta muto sul velo della stessa canzone, nessun avvio (T6) contesto:%{public}@",
               log: .default, type: .default, context)
        _songInProgressQ = false
        _wantedStopSinceCrisisQ = true
        if pendingResume || isAudioInterrupted {
            clearPendingResumeQ(reason: "sessione-ferma")
        }
        DispatchQueue.main.async {
            self.directorRunnerActionSubject.send(.rearmSame)
            self.playbackState = .stopped
        }
        // A421 — lo specchio di `isRunning` (par. 2.2 e: qui il motore è fermo) e i ritorni annullati.
        cancelOutputReturnsQ(reason: "sessione-ferma")
        publishIsPlayingQ(context: "sessione-ferma")
        leaveDirectorSilenceQ(reason: "sessione-ferma", closeAnchor: true)
    }

    /// L'ARMAMENTO DEL RIENTRO, dal ramo col bersaglio di `armSharedJoin` (T3). Il blocco che arma il primo
    /// buffer gira 150 ms prima dell'ora d'uscita del bersaglio (A376 P9, scelta T5): il work item nasce con la
    /// generazione dell'ingresso, come quello del Follower, e un arresto o un ingresso nuovo lo scartano. Il
    /// contatore e il LED si spengono durante l'attesa (`isWaitingForLinkDownbeat`, i pezzi di oggi). Chiamare
    /// SOLO su audioQueue.
    private func armDirectorRejoinQ(_ target: RejoinTarget, generation: Int) {
        let armAt = DirectorRejoinDecision.armingTicks(targetOutputTicks: target.mapTicks,
                                                       marginSeconds: AudioEngine.kRejoinMarginSeconds,
                                                       ticksPerSecond: ticksPerSecond)
        let now = mach_absolute_time()
        let delaySeconds = armAt > now ? machTicksToSeconds(armAt - now) : 0
        _rejoinArmedQ = true
        DispatchQueue.main.async {
            self.isWaitingForLinkDownbeat = true
        }
        // A412 · SEGUITO 2 — `battitoLink` a quantum 1 della decisione (com'era), accanto quello della sessione.
        let linkBeatQ1Text: String = target.linkBeatQ1.isFinite ? String(format: "%.0f", target.linkBeatQ1) : "-"
        // A412 · SEGUITO 3 — in coda il timer dell'attesa: `timer:stretto leeway_ms:1` (`StrictOneShotTimer`).
        os_log("[Q-BEATS][DIR-RIENTRO] armato sectionIdx:%d battuta:%d battitoLink:%{public}@ battitoLinkQ1e6:%.0f oraMappa:%llu armamento:%llu attesa_s:%.3f generazione:%d salti:%d innesco:%{public}@ timer:stretto leeway_ms:%d",
               log: .default, type: .default,
               target.section, target.bar, linkBeatQ1Text, target.linkBeat, target.mapTicks, armAt, delaySeconds,
               generation, target.lateSkipsLeft, target.trigger, StrictOneShotTimer.leewayMilliseconds)
        let work = DispatchWorkItem { [weak self] in
            self?.fireDirectorRejoinQ(target, generation: generation, armedFor: armAt)
        }
        pendingLinkStart = work
        // A412 · SEGUITO 3 — l'attesa sul timer all'ora chiesta (`StrictOneShotTimer`: colpo singolo, `.strict`, margine
        // di 1 ms) e non più su `asyncAfter`, che lascia al sistema un margine che cresce con l'attesa (al collaudo
        // dell'IPA #776, 135,7 ms su 3,538 s: il fuoco in ritardo e il rientro due battute dopo). Stesso work item,
        // stessa coda; un armamento nuovo, anche dal fuoco in ritardo, annulla quello di prima.
        _rejoinArmTimerQ.arm(afterSeconds: delaySeconds, work: work)
        publishDirectorSilenceQ(context: "rientro-armato")
    }

    /// IL FUOCO DEL RIENTRO. Chiamare SOLO su audioQueue, dal work item di `armDirectorRejoinQ`. Nell'ordine:
    ///  1. il fuoco vale solo se è l'ultimo armato e il motore è in moto (come l'ingresso del Follower);
    ///  2. mappa e ponte si rileggono (T2): oltre 1/8 di battito al tempo della sezione d'arrivo, non certo; la
    ///     sessione deve suonare (altrimenti T6) e avere lo stesso avvio;
    ///  3. in ritardo sul bersaglio (LIBRO 2026-09-20 «MOTORE IN RITARDO SUL BERSAGLIO: SI SALTA AL BERSAGLIO
    ///     SUCCESSIVO»): il coordinatore rifà il conto e si arma il bersaglio dopo, fino a `maxLateSkips` volte;
    ///  4. la sezione d'arrivo, come la carica il runner all'avvio di una sezione (battiti per battuta, accenti,
    ///     suddivisione, battute, tempo; la successiva precaricata) ma senza W1; il contatore seminato a
    ///     (battuta − 1) × battiti per battuta; metronomo e MIDI al battito di Link del bersaglio;
    ///  5. il primo buffer della scorta muta all'ora chiesta al lettore (`scheduleBuffer(_:at:)`, T5), gli altri come
    ///     oggi; il motore parte dal seme della scorta e l'«uno» esce dopo, dove la prima correzione di fase lo tiene;
    ///     da qui il Direttore segue Link (T4). Il runner va alla sezione d'arrivo senza avvio (`.rejoin`).
    ///     ⚠️ RISCRITTO A412 · SEGUITO 2 (2/2) (18/10/2026). Il testo di prima diceva «5. il primo buffer all'ora
    ///     chiesta al lettore (`scheduleBuffer(_:at:)`, T5), gli altri come oggi; da qui il Direttore segue Link (T4).
    ///     Il runner va alla sezione d'arrivo senza avvio (`.rejoin`).»: il primo buffer era quello del bersaglio, e il
    ///     primo click usciva 26-31 ms prima della griglia che la correzione tiene dal quarto buffer.
    /// Nessuna scrittura su Link: niente battito zero, ripresa, «si suona», W1, W4, fase d'avvio.
    private func fireDirectorRejoinQ(_ target: RejoinTarget, generation: Int, armedFor: UInt64) {
        let firedAt = mach_absolute_time()
        guard generation == joinGeneration, isRunning else {
            os_log("[Q-BEATS][DIR-RIENTRO] fuoco scartato - generazione:%d attuale:%d motore:%{public}@",
                   log: .default, type: .default,
                   generation, joinGeneration, isRunning ? "in moto" : "fermo")
            return
        }
        pendingLinkStart = nil
        // A412 · SEGUITO 3 — il timer si è già rilasciato allo scatto, prima di questo lavoro (`StrictOneShotTimer`):
        // qui non c'è niente da fermare, la riga lo rende esplicito.
        _rejoinArmTimerQ.cancel()
        guard _directorSilentInSongQ, let anchor = _silenceAnchorQ, let lh = linkEngineHandle,
              let h = metronomeHandle, let mh = midiEngineHandle,
              target.section >= 0, target.section < anchor.sections.count,
              target.section < anchor.clock.map.sections.count else {
            stopRejoinEngineQ(reason: "stato-mancante")
            return
        }
        let tps = ticksPerSecond
        let arrival = anchor.sections[target.section]
        let bpb: UInt32 = max(arrival.beatsPerBar, 1)

        // 2. Mappa e ponte all'armamento, e la sessione all'ora del bersaglio.
        // A412 · SEGUITO 2 — il ponte nella numerazione della sessione; accanto, per la riga, il ponte come lo
        // leggeva A412 (il battito a quantum 1 della decisione, quantum 1): non decide niente.
        let mapTicks = anchor.clock.ticks(section: target.section, beatInSection: target.beatInSection,
                                          ticksPerSecond: tps)
        let time = link_engine_time_at_beat(lh, target.linkBeat, DirectorRejoinDecision.sessionQuantum)
        let bridgeTicks: UInt64 = time.linkEnabled ? time.hostTime : 0
        var bridgeTicksQ1: UInt64 = 0
        if target.linkBeatQ1.isFinite {
            let timeQ1 = link_engine_time_at_beat(lh, target.linkBeatQ1, 1.0)
            if timeQ1.linkEnabled { bridgeTicksQ1 = timeQ1.hostTime }
        }
        let sectionBPM = anchor.clock.map.sections[target.section].bpm
        let check = DirectorRejoinDecision.armingCheck(mapTicks: mapTicks, bridgeTicks: bridgeTicks,
                                                       sectionBPM: sectionBPM,
                                                       ticksPerSecond: tps)
        let checkQ1 = DirectorRejoinDecision.armingCheck(mapTicks: mapTicks, bridgeTicks: bridgeTicksQ1,
                                                         sectionBPM: sectionBPM,
                                                         ticksPerSecond: tps)
        logRejoinTargetQ(phase: "armamento", section: target.section, bar: target.bar, linkBeat: target.linkBeat,
                         linkBeatQ1: target.linkBeatQ1, mapTicks: mapTicks ?? 0, bridgeTicks: bridgeTicks, check: check,
                         bridgeTicksQ1: bridgeTicksQ1, checkQ1: checkQ1, nowTicks: firedAt)
        guard check.agree, let targetTicks = mapTicks else {
            stopRejoinEngineQ(reason: "non-certo(\(describe(DirectorRejoinDecision.Uncertain.mapBridgeDisagree)))")
            return
        }
        let session = link_engine_read_session_at(lh, targetTicks, target.quantum)
        guard session.linkEnabled else {
            stopRejoinEngineQ(reason: "non-certo(\(describe(DirectorRejoinDecision.Uncertain.linkOff)))")
            return
        }
        guard session.isPlaying else {
            stopRejoinEngineQ(reason: "sessione-ferma")
            applySessionStoppedElsewhereQ(context: "armamento")
            return
        }
        // A412 · SEGUITO 2 — «stesso avvio» nella numerazione della sessione (il battito che semina il motore,
        // `session.beatAtHostTime`, resta col quantum della sezione d'arrivo).
        guard DirectorRejoinDecision.sameStart(anchorStartBeat: anchor.startBeatQBig,
                                               nowStartBeat: session.beatAtStartQBig) else {
            stopRejoinEngineQ(reason: "non-certo(\(describe(DirectorRejoinDecision.Uncertain.startChanged)))")
            return
        }

        // 3. In ritardo?
        // A412 · SEGUITO 2 (2/2) — prima la scorta muta (mandato «A412 · SEGUITO 2 (2/2)», par. 2): quanti buffer muti,
        // l'ora vera del primo (quello chiesto al lettore) e il seme del motore (`DirectorRejoinDecision.leadIn`). Il
        // controllo «in ritardo» guarda l'ora del primo buffer muto (par. 2.3). Se la scorta non si può fare, il rientro
        // entra come prima, col primo buffer all'ora del bersaglio, con una riga.
        let unoBeat = session.beatAtHostTime
        let ioSeconds = machTicksToSeconds(bufferDurationTicks)
        let leadIn = DirectorRejoinDecision.leadIn(targetOutputTicks: targetTicks,
                                                   outputLatencyTicks: outputLatencyTicks,
                                                   unoBeat: unoBeat, bpm: arrival.bpm,
                                                   bufferFrames: Int(bufferSize), sampleRate: sampleRate,
                                                   ioBufferSeconds: ioSeconds, ticksPerSecond: tps)
        let renderTicks = leadIn?.firstBufferRenderTicks
            ?? DirectorRejoinDecision.firstBufferRenderTicks(targetOutputTicks: targetTicks,
                                                             outputLatencyTicks: outputLatencyTicks)
        let firstOutputTicks = leadIn?.firstBufferOutputTicks ?? targetTicks
        if leadIn == nil {
            os_log("[Q-BEATS][DIR-RIENTRO] scorta non possibile - battitoUno:%.4f tempo:%.1f io_ms:%.2f - primo buffer all'ora del bersaglio, come prima",
                   log: .default, type: .default, unoBeat, arrival.bpm, ioSeconds * 1000.0)
        }
        let checkedAt = mach_absolute_time()
        if DirectorRejoinDecision.isLate(nowTicks: checkedAt, renderTicks: renderTicks,
                                         minLeadTicks: secondsToMachTicks(DirectorRejoinDecision.minLeadSeconds)) {
            os_log("[Q-BEATS][DIR-RIENTRO] fuoco in ritardo sul bersaglio oraRender:%llu adesso:%llu anticipo_ms:%.1f minimo_ms:%.1f salti:%d",
                   log: .default, type: .default,
                   renderTicks, checkedAt, signedMilliseconds(from: checkedAt, to: renderTicks),
                   DirectorRejoinDecision.minLeadSeconds * 1000.0, target.lateSkipsLeft)
            guard target.lateSkipsLeft > 0 else {
                stopRejoinEngineQ(reason: "non-certo(\(describe(DirectorRejoinDecision.Uncertain.lateTooManyTimes)))")
                return
            }
            switch coordinateDirectorRejoinQ(trigger: "ritardo", resume: false, lateSkipsLeft: target.lateSkipsLeft - 1) {
            case .rejoin(let next):
                armSharedJoin(retriesLeft: 0, rejoin: next)
            case .stayMuted:
                stopRejoinEngineQ(reason: "ritardo")
            case .proceedAsToday:
                stopRejoinEngineQ(reason: "ritardo-fuori-coordinatore")
            }
            return
        }

        // 4. La sezione d'arrivo (passi 1-4 del runner e il precarico, senza W1).
        let closure = _songSectionEndClosureQ
        metronome_cancel_pending_bpm(h)
        metronome_cancel_pending_bpb(h)
        metronome_cancel_pending_subdivision(h)
        _pendingBPMValue = nil
        _pendingBPMTargetTick = 0
        _pendingNextBPM = nil
        _pendingNextBPB = nil
        _pendingNextAccentPattern = nil
        _pendingNextSectionTotalBeats = nil
        _pendingNextOnSectionEnd = nil
        _pendingNextRepetitions = nil
        _pendingNextSubdivisionMultiplier = nil
        _pendingNextSwingRatio = nil
        _sectionEndPending = false
        _pendingEndClosure = nil
        metronome_setBPM(h, arrival.bpm)
        metronome_setBeatsPerBar(h, bpb)
        let dspPattern: [UInt8] = arrival.accentPattern.map { $0 == 2 ? UInt8(1) : UInt8(0) }
        dspPattern.withUnsafeBufferPointer { ptr in
            metronome_setAccentPattern(h, ptr.baseAddress, UInt32(dspPattern.count))
        }
        metronome_setSubdivision(h, arrival.subdivisionMultiplier, arrival.swingRatio)
        _audioBPM = arrival.bpm
        _engineTempoQ = arrival.bpm
        _linkTempoAdoptedQ = nil
        _ownTimelineQ = nil
        _beatsPerBarQ = bpb
        link_engine_set_quantum(lh, target.quantum)
        let totalBeats = arrival.repetitions > 0 ? arrival.repetitions * Int(bpb) : 0
        let seed = (target.bar - 1) * Int(bpb)
        _sectionTotalBeats = totalBeats
        _onSectionEnd = totalBeats > 0 ? closure : nil
        if totalBeats > 0 && seed >= 0 && seed < totalBeats {
            _sectionBeatCounter = seed
            startBeatOffset = seed
        } else {
            _sectionBeatCounter = 0
            startBeatOffset = 0
        }
        _songMapSectionQ = target.section
        if target.section + 1 < anchor.sections.count, let closure {
            let following = anchor.sections[target.section + 1]
            _pendingNextBPM = following.bpm
            _pendingNextBPB = following.beatsPerBar
            _pendingNextAccentPattern = following.accentPattern
            _pendingNextSectionTotalBeats = following.repetitions * Int(following.beatsPerBar)
            _pendingNextOnSectionEnd = closure
            _pendingNextRepetitions = following.repetitions
            _pendingNextSubdivisionMultiplier = following.subdivisionMultiplier
            _pendingNextSwingRatio = following.swingRatio
        }
        // Le posizioni: il battito di Link all'ora del bersaglio, col quantum della sezione d'arrivo, è l'«uno»,
        // l'origine dei click (`metronome_reset_for_start`: battito 0 della battuta, quindi accentato).
        // ⚠️ RISCRITTO A412 · SEGUITO 2 (2/2) (18/10/2026). Il testo di prima diceva «Il primo campione del primo
        // buffer è quel battito, ed è un «uno» (`metronome_reset_for_start`).»: con la scorta il primo campione è
        // l'«uno» meno la scorta. `metronome_set_beat_position_time_only`, la chiamata della correzione di fase,
        // sposta indietro la sola linea a campioni e lascia l'«uno» come battito pendente; il MIDI parte dallo stesso
        // seme. Senza scorta, metronomo e MIDI partono dall'«uno» come prima.
        let startBeat = unoBeat
        metronome_reset_for_start(h, startBeat)
        // A421 — la copia dell'origine del DSP (U9): l'«uno» del rientro.
        _dspOriginBeatQ = startBeat
        let seedBeat = leadIn?.seedBeat ?? startBeat
        if leadIn != nil {
            metronome_set_beat_position_time_only(h, seedBeat)
        }
        midi_engine_set_bpm(mh, arrival.bpm)
        midi_engine_sync_clock(mh, 0, mach_absolute_time(), sampleRate)
        midi_engine_set_beat_position(mh, seedBeat)
        _startAbsoluteBeat = startBeat

        // 5. Il primo buffer all'ora chiesta, poi i due di sempre; il runner e gli specchi su main.
        // A412 · SEGUITO 2 (2/2) — il primo buffer è il primo della scorta (muto); la scorta resta viva fino all'«uno»
        // (`_rejoinLeadInQ`: correzioni, MIDI, silenzio, riga del primo click).
        linkSyncSkipBuffers = DirectorRejoinDecision.uncorrectedFireBuffers
        _directorFollowsLinkQ = true
        _anchoredFirstBufferQ = AVAudioTime(hostTime: renderTicks)
        _anchoredOutputTicksQ = firstOutputTicks
        _anchoredPreRollLeftQ = 3
        _rejoinLeadInQ = leadIn.map {
            RejoinLeadIn(plan: $0, targetTicks: targetTicks,
                         bufferBeats: Double(bufferSize) / sampleRate * arrival.bpm / 60.0)
        }
        let songIdx = target.songIdx
        let sectionIdx = target.section
        let pattern = arrival.accentPattern
        let repetitions = arrival.repetitions
        let bpm = arrival.bpm
        DispatchQueue.main.async {
            self.isWaitingForLinkDownbeat = false
            self.directorRunnerActionSubject.send(.rejoin(songIdx: songIdx, sectionIdx: sectionIdx))
            // Come il ramo SEAMLESS (passo h): il DSP ha già la misura, il `didSet` non la rimanda.
            self._suppressBeatsPerBarDidSet = true
            self.beatsPerBar = bpb
            self.currentAccentPattern = pattern
            self.currentSectionRepetitions = repetitions
            self.currentBPM = bpm
        }
        // A420 — la catena del rientro comincia qui (il primo dei tre è il buffer ancorato): una generazione nuova prima del
        // primo (mandato A420, par. 2.2). Un richiamo della catena di prima arrivato fra l'avvio del motore e questo fuoco si
        // è già scartato: `start()` ha aperto una generazione alzando `isRunning` (risposta del referee, par. 1).
        openBufferChainQ()
        scheduleNextBuffer()
        scheduleNextBuffer()
        scheduleNextBuffer()
        let scheduledAt = mach_absolute_time()
        _rejoinArmedQ = false
        leaveDirectorSilenceQ(reason: "rientro", closeAnchor: true)
        // A412 · SEGUITO 2 (2/2) — in coda la scorta: buffer muti, ora d'uscita del primo, seme del motore. `oraRender` e
        // `anticipo_ms` sono quelli del primo buffer muto (l'ora chiesta al lettore); `oraUscita` resta quella dell'«uno».
        os_log("[Q-BEATS][DIR-RIENTRO] fuoco esito:ingresso innesco:%{public}@ sectionIdx:%d battuta:%d seme:%d battitoLink:%.4f oraUscita:%llu oraRender:%llu armamentoPrevisto:%llu armamentoVero:%llu ritardo_ms:%.3f anticipo_ms:%.1f latenza_ms:%.1f generazione:%d salti:%d scorta:%d oraUscitaScorta:%llu semeMotore:%.4f",
               log: .default, type: .default,
               target.trigger, target.section, target.bar, seed, startBeat, targetTicks, renderTicks,
               armedFor, firedAt, signedMilliseconds(from: armedFor, to: firedAt),
               signedMilliseconds(from: scheduledAt, to: renderTicks),
               machTicksToSeconds(outputLatencyTicks) * 1000.0, generation, target.lateSkipsLeft,
               leadIn?.buffers ?? 0, firstOutputTicks, seedBeat)
        os_log("[Q-BEATS][DIR-RIENTRO] segue Link - correzione di fase come il Follower al posto dell'assert, fino all'avvio dopo (T4); il richiamo del tempo non rilancia _audioBPM; W2 del Direttore ai confini com'e'",
               log: .default, type: .default)
    }

    /// Il rientro non parte (stato mancante, non certo all'armamento, troppi ritardi, sessione ferma): il motore
    /// acceso per il rientro si ferma in locale e il Direttore resta muto (il tasto si ricalcola). Nessuno Stop a
    /// Link. Chiamare SOLO su audioQueue.
    private func stopRejoinEngineQ(reason: String) {
        _rejoinArmedQ = false
        _anchoredFirstBufferQ = nil
        _anchoredPreRollLeftQ = 0
        _rejoinLeadInQ = nil
        DispatchQueue.main.async {
            self.isWaitingForLinkDownbeat = false
        }
        var stopped = false
        if isRunning {
            isRunning = false
            stopPlayerAndEngineQ(context: "rientro")
            stopped = true
            // A421 — il drenaggio (par. 2.2 j) e lo specchio di `isRunning` (par. 2.2 e), sulla coda.
            closeDrainOnCrisisStopQ(context: "rientro")
            publishIsPlayingQ(context: "rientro")
        }
        os_log("[Q-BEATS][DIR-RIENTRO] rientro non eseguito motivo:%{public}@ motore:%{public}@ muto:%d - nessuno Stop a Link",
               log: .default, type: .default,
               reason, stopped ? "fermato" : "gia-fermo", _directorSilentInSongQ ? 1 : 0)
        if _directorSilentInSongQ {
            publishDirectorSilenceQ(context: "rientro-non-eseguito")
        }
    }

    /// Il primo buffer del rientro è stato consumato dal lettore: l'ora chiesta e l'ultimo ciclo di rendering
    /// che Apple dà (`lastRenderTime`), per vedere nel registro se l'ancoraggio è stato rispettato (un buffer
    /// suonato subito avrebbe l'ultimo ciclo ben prima dell'ora chiesta). Chiamare SOLO su audioQueue.
    /// A421 — in coda `richiamoMenoAtteso_ms`: il richiamo del primo buffer della catena del rientro contro l'ora attesa
    /// (l'ora chiesta più un buffer: la convenzione del misuratore, che in questa catena non vede un buco prima della
    /// quarta chiamata). Una riga passiva (mandato A421, par. 2.2 d).
    private func anchoredBufferConsumedQ(requestedRenderTicks: UInt64) {
        var lastText = "non-valida"
        var gapText = "-"
        if let renderTime = playerNode.lastRenderTime, renderTime.isHostTimeValid {
            lastText = String(renderTime.hostTime)
            gapText = String(format: "%.1f", signedMilliseconds(from: requestedRenderTicks, to: renderTime.hostTime))
        }
        // La convenzione del misuratore: il buffer del lettore (512 campioni alla copia), non il buffer d'I/O della sessione.
        let (expected, overflow) = requestedRenderTicks.addingReportingOverflow(secondsToMachTicks(Double(bufferSize) / max(sampleRate, 1)))
        let callbackLateMs = overflow ? 0.0 : signedMilliseconds(from: expected, to: mach_absolute_time())
        os_log("[Q-BEATS][DIR-RIENTRO] primo buffer consumato oraChiesta:%llu ultimoRender:%{public}@ ultimoRenderMenoChiesta_ms:%{public}@ buffer_ms:%.1f richiamoMenoAtteso_ms:%.1f - ancorato con scheduleBuffer(at:)",
               log: .default, type: .default,
               requestedRenderTicks, lastText, gapText, Double(bufferSize) / max(sampleRate, 1) * 1000.0, callbackLateMs)
    }

    /// A412 · SEGUITO 2 (2/2) — IL PRIMO CLICK DEL RIENTRO, DOPO LA SCORTA MUTA (mandato «A412 · SEGUITO 2 (2/2)», par.
    /// 2.5). Chiamare SOLO su audioQueue, dal ciclo degli eventi di `scheduleNextBuffer`, al primo battito dopo il fuoco
    /// (l'«uno»), prima del suo conteggio. La riga: i buffer della scorta (previsti, e quelli passati davvero prima del
    /// click), la correzione fatta prima del click (in battiti, e quante), il battito dell'«uno» secondo il motore e
    /// quello del piano, l'ora d'uscita dell'«uno» secondo il motore (la convenzione d'ora della correzione: l'ora del
    /// buffer più lo scostamento) e quella della catena ancorata (l'ora del primo buffer muto più i campioni passati),
    /// tutte e due anche come scarto dall'ora del bersaglio. La riga [LINK] Phase sync della prima correzione viene
    /// prima di questa. Poi la scorta finisce e le correzioni di regime ripartono col buffer dopo.
    private func noteRejoinFirstClickQ(offset: Int) {
        guard let lead = _rejoinLeadInQ else { return }
        _rejoinLeadInQ = nil
        var beatNow = Double.nan
        if let mh = midiEngineHandle {
            beatNow = midi_engine_get_beat_position(mh) + Double(offset) / Double(bufferSize) * lead.bufferBeats
        }
        let engineOutTicks = _bufferOutTicksQ + secondsToMachTicks(Double(offset) / sampleRate)
        let samplesSinceFirst = Double(bufferCount - 1) * Double(bufferSize) + Double(offset)
        let chainTicks = ShowClock.ticks(lead.plan.firstBufferOutputTicks, plusSeconds: samplesSinceFirst / sampleRate,
                                         ticksPerSecond: ticksPerSecond)
        os_log("[Q-BEATS][DIR-RIENTRO] primo click scorta:%d bufferMuti:%d correzionePrimaDelClick:%.4f correzioni:%d battitoUno:%.4f uno:%.4f oraUscitaUno:%llu oraBersaglio:%llu motoreMenoBersaglio_ms:%.1f oraCatena:%llu catenaMenoBersaglio_ms:%.1f",
               log: .default, type: .default,
               lead.plan.buffers, bufferCount - 1, lead.correctionBeats, lead.corrections, beatNow, lead.plan.unoBeat,
               engineOutTicks, lead.targetTicks, signedMilliseconds(from: lead.targetTicks, to: engineOutTicks),
               chainTicks, signedMilliseconds(from: lead.targetTicks, to: chainTicks))
    }

    /// Al battito a 1 s col Direttore muto in canzone: il tasto (dipende dal conto di adesso) e lo Stop di fine
    /// canzone (mandato §2.3). Scelta: il battito a 1 s ARMA un timer unico all'ora giusta, e lo riarma a ogni
    /// battito finché l'ora si sposta (nell'ultima sezione l'ora del ponte non ha più cambi di tempo davanti):
    /// col solo battito lo Stop uscirebbe fino a un secondo in ritardo. Chiamare SOLO su audioQueue.
    private func directorSilenceSecondQ() {
        let current = currentRejoinPlanQ()
        publishDirectorSilenceQ(context: "al-secondo", plan: current.plan)
        guard !_rejoinArmedQ, !isRunning else { return }
        if case .songEnded(let endLinkBeat, _) = current.plan.outcome {
            scheduleDirectorSongEndStopQ(endLinkBeat: endLinkBeat, read: current.read, context: "al-secondo")
        } else {
            noteSongEndNotSentQ(plan: current.plan, nowTicks: current.now)
        }
    }

    /// La riga «Stop di fine canzone NON inviato», una volta per silenzio, quando il conto non è certo e la canzone
    /// sarebbe finita secondo la mappa (senza àncora: subito). D4 (a): nessuno Stop automatico, a fine pezzo il
    /// batterista preme Stop. Chiamare SOLO su audioQueue.
    private func noteSongEndNotSentQ(plan: DirectorRejoinDecision.Plan, nowTicks: UInt64) {
        guard !_songEndNotSentLoggedQ, case .uncertain(let why) = plan.outcome else { return }
        let mapEnd: UInt64? = _silenceAnchorQ?.clock.endTicks(ticksPerSecond: ticksPerSecond)
        if let mapEnd, nowTicks < mapEnd { return }
        _songEndNotSentLoggedQ = true
        os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop NON inviato motivo:non-certo(%{public}@) oraMappa:%llu adesso:%llu - serve lo Stop del batterista",
               log: .default, type: .default, describe(why), mapEnd ?? 0, nowTicks)
    }

    /// LO STOP DI FINE CANZONE (mandato §2.3, D1): armato all'ora più tarda fra quella della mappa e quella del
    /// ponte, più 1/8 di battito al tempo dell'ultima sezione (`DirectorRejoinDecision.songEndStopTicks`): mai
    /// prima che la band abbia finito. Si riarma solo se l'ora si sposta di 5 ms o più. Chiamare SOLO su
    /// audioQueue, col conto certo (l'esito «canzone finita» del coordinatore).
    /// A412 · SEGUITO 2 — `endLinkBeat` è nella numerazione della sessione e il ponte lo legge con quel quantum;
    /// `read` (la cattura del coordinatore) serve solo alla riga, per scrivere lo stesso battito a quantum 1.
    private func scheduleDirectorSongEndStopQ(endLinkBeat: Double, read: LinkSessionReading, context: String) {
        guard let anchor = _silenceAnchorQ else { return }
        let tps = ticksPerSecond
        let mapEnd = anchor.clock.endTicks(ticksPerSecond: tps)
        var bridgeEnd: UInt64 = 0
        if let lh = linkEngineHandle {
            let time = link_engine_time_at_beat(lh, endLinkBeat, DirectorRejoinDecision.sessionQuantum)
            if time.linkEnabled { bridgeEnd = time.hostTime }
        }
        let offset = DirectorRejoinDecision.deviceOffset(beatQuantumOne: read.beatAtHostTime,
                                                         beatSession: read.beatAtHostTimeQBig)
        let endQ1Text: String = offset.map { String(format: "%.0f", endLinkBeat + $0) } ?? "-"
        let lastBPM = anchor.clock.map.sections.last?.bpm ?? 0
        let now = mach_absolute_time()
        guard let sendAt = DirectorRejoinDecision.songEndStopTicks(mapEndTicks: mapEnd, bridgeEndTicks: bridgeEnd,
                                                                   lastSectionBPM: lastBPM, ticksPerSecond: tps) else {
            if !_songEndNotSentLoggedQ {
                _songEndNotSentLoggedQ = true
                os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop NON inviato motivo:ore-mancanti oraMappa:%llu oraPonte:%llu adesso:%llu - serve lo Stop del batterista",
                       log: .default, type: .default, mapEnd ?? 0, bridgeEnd, now)
            }
            return
        }
        if _songEndStopWorkQ != nil, let planned = _songEndStopPlannedTicksQ,
           abs(signedMilliseconds(from: planned, to: sendAt)) < 5.0 {
            return
        }
        _songEndStopWorkQ?.cancel()
        // A412 · SEGUITO 3 — col work item si ferma il timer (lo farebbe anche `arm` qui sotto).
        _songEndStopTimerQ.cancel()
        let delaySeconds = sendAt > now ? machTicksToSeconds(sendAt - now) : 0
        let work = DispatchWorkItem { [weak self] in
            self?.fireDirectorSongEndStopQ(planned: sendAt, endLinkBeat: endLinkBeat)
        }
        _songEndStopWorkQ = work
        _songEndStopPlannedTicksQ = sendAt
        // A412 · SEGUITO 3 — in coda il timer dell'attesa: `timer:stretto leeway_ms:1` (`StrictOneShotTimer`).
        os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop armato battitoLink:%{public}@ battitoLinkQ1e6:%.0f oraMappa:%llu oraPonte:%llu mappaMenoPonte_ms:%.1f invio:%llu tra_ms:%.1f margine_battiti:%.3f contesto:%{public}@ timer:stretto leeway_ms:%d",
               log: .default, type: .default,
               endQ1Text, endLinkBeat, mapEnd ?? 0, bridgeEnd,
               bridgeEnd > 0 ? signedMilliseconds(from: bridgeEnd, to: mapEnd ?? 0) : 0.0,
               sendAt, signedMilliseconds(from: now, to: sendAt), ShowClock.defaultToleranceBeats, context,
               StrictOneShotTimer.leewayMilliseconds)
        // A412 · SEGUITO 3 — l'attesa sul timer all'ora chiesta (`StrictOneShotTimer`), non più su `asyncAfter`.
        _songEndStopTimerQ.arm(afterSeconds: delaySeconds, work: work)
    }

    /// Il timer dello Stop di fine canzone. All'ora d'invio il conto si rilegge: se dice ancora «canzone finita»
    /// lo Stop esce verso Link (la stessa scrittura dello Stop voluto) e la stanza arma la successiva; se no,
    /// niente, con la riga. Dopo, niente riparte da solo (come dopo uno Stop voluto). Chiamare SOLO su audioQueue.
    private func fireDirectorSongEndStopQ(planned: UInt64, endLinkBeat: Double) {
        let firedAt = mach_absolute_time()
        _songEndStopWorkQ = nil
        _songEndStopPlannedTicksQ = nil
        // A412 · SEGUITO 3 — il timer si è già rilasciato allo scatto, prima di questo lavoro (`StrictOneShotTimer`):
        // qui non c'è niente da fermare, la riga lo rende esplicito.
        _songEndStopTimerQ.cancel()
        guard _directorSilentInSongQ, !isRunning, !_rejoinArmedQ else {
            os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop non inviato: il silenzio e' gia' finito o un rientro e' in corso (muto:%d motore:%{public}@)",
                   log: .default, type: .default,
                   _directorSilentInSongQ ? 1 : 0, isRunning ? "in-moto" : "fermo")
            return
        }
        let current = currentRejoinPlanQ()
        guard case .songEnded = current.plan.outcome else {
            _songEndNotSentLoggedQ = true
            os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop NON inviato motivo:%{public}@ - all'ora d'invio il conto non dice piu' canzone finita",
                   log: .default, type: .default, describe(current.plan.outcome))
            return
        }
        guard let lh = linkEngineHandle else { return }
        let sentAt = mach_absolute_time()
        link_engine_stop(lh, sentAt)
        _startPhaseQ = nil
        _songInProgressQ = false
        _wantedStopSinceCrisisQ = true
        // A412 · SEGUITO 2 — il battito della fine nella numerazione della sessione; a quantum 1, accanto, con la
        // distanza della cattura del coordinatore qui sopra.
        let offset = DirectorRejoinDecision.deviceOffset(beatQuantumOne: current.read.beatAtHostTime,
                                                         beatSession: current.read.beatAtHostTimeQBig)
        let endQ1Text: String = offset.map { String(format: "%.0f", endLinkBeat + $0) } ?? "-"
        os_log("[Q-BEATS][DIR-RIENTRO] fine canzone - Stop INVIATO a Link battitoLink:%{public}@ battitoLinkQ1e6:%.0f previsto:%llu fuoco:%llu inviato:%llu ritardo_ms:%.1f - la stanza arma la successiva",
               log: .default, type: .default,
               endQ1Text, endLinkBeat, planned, firedAt, sentAt, signedMilliseconds(from: planned, to: sentAt))
        DispatchQueue.main.async {
            self.directorRunnerActionSubject.send(.songEndedArmNext)
            self.playbackState = .stopped
        }
        if pendingResume || isAudioInterrupted {
            clearPendingResumeQ(reason: "fine-canzone")
        }
        // A421 — a fine canzone il Direttore abbassa «uscita mancante» (U5), i ritorni si annullano (par. 2.3 b) e lo
        // specchio si pubblica (par. 2.2 e: il motore è fermo).
        noteOutputStateQ(.directorStop, from: "fine-canzone")
        cancelOutputReturnsQ(reason: "fine-canzone")
        publishIsPlayingQ(context: "fine-canzone")
        leaveDirectorSilenceQ(reason: "fine-canzone", closeAnchor: true)
    }

    /// Un avvio che non passa dal coordinatore (mandato §2.2, T4): torna l'assert del Direttore se dopo un rientro
    /// seguiva Link; «canzone in corso» se la mappa è arrivata per questo avvio; la crisi è alle spalle. Chiamare
    /// SOLO su audioQueue, da `start()`.
    private func prepareNormalStartQ(trigger: String) {
        if _directorFollowsLinkQ {
            _directorFollowsLinkQ = false
            os_log("[Q-BEATS][DIR-RIENTRO] assert ripreso all'avvio innesco:%{public}@ - il Direttore torna a dare la fase a Link (T4)",
                   log: .default, type: .default, trigger)
        }
        _songInProgressQ = _songMapForNextStartQ
        _songMapForNextStartQ = false
        _crisisCauseQ = nil
        _wantedStopSinceCrisisQ = false
        closeSilenceAnchorQ(reason: "avvio")
    }

    /// LE RIPARTENZE AUTOMATICHE (mandato §2.6): dove va ognuna (`RecoveryDecision`), con la riga. Chiamare SOLO
    /// su audioQueue, all'ingresso di `activateSessionAndStart` e subito prima del suo `start()`.
    /// A421 — U5: a ogni rientro automatico (compreso il ritorno dallo sfondo) si rilegge il percorso di adesso, dalla memoria
    /// dell'ultima uscita (`refreshOutputMissingQ`): così regge la notizia che arriva tardi o non arriva con l'app sospesa
    /// (il 24/10 alle 13:55:42). Il Direttore con l'uscita mancante non riparte da nessun innesco; a quel «niente» il tasto si
    /// ripubblica (`noteNoRestartQ`).
    private func recoveryRouteQ(trigger: RecoveryTrigger, stage: String) -> RecoveryRoute {
        let role = playerRoleQ
        let outputMissing = refreshOutputMissingQ()
        let route = RecoveryDecision.route(trigger: trigger,
                                           playerRole: role,
                                           silentInSong: _directorSilentInSongQ,
                                           wantedStopSinceCrisis: _wantedStopSinceCrisisQ,
                                           crisisCause: _crisisCauseQ,
                                           outputMissing: outputMissing)
        os_log("[Q-BEATS][RESUME] ripartenza automatica innesco:%{public}@ fase:%{public}@ ruolo:%{public}@ muto:%d stopVoluto:%d crisi:%{public}@ uscitaMancante:%d -> %{public}@",
               log: .default, type: .default,
               trigger.rawValue, stage, role.rawValue, _directorSilentInSongQ ? 1 : 0,
               _wantedStopSinceCrisisQ ? 1 : 0, _crisisCauseQ?.rawValue ?? "-", outputMissing ? 1 : 0, route.rawValue)
        if route == .noRestart {
            noteNoRestartQ(trigger: trigger, stage: stage,
                           reason: RecoveryDecision.noRestartReason(trigger: trigger,
                                                                    playerRole: role,
                                                                    silentInSong: _directorSilentInSongQ,
                                                                    wantedStopSinceCrisis: _wantedStopSinceCrisisQ,
                                                                    crisisCause: _crisisCauseQ,
                                                                    outputMissing: outputMissing))
        }
        return route
    }

    /// L'arresto locale di una crisi (servizi persi, reset senza Lost): lo stato su audioQueue; rende `true` se il motore
    /// girava. Alla Lost è un'operazione nuova (A412): fino ad A411 il motore restava com'era fino alla Reset, che lo
    /// fermava con lo `stopSync` (e lo Stop alla band). Chiamare SOLO su audioQueue.
    /// ⚠️ RISCRITTO A420 (23/10/2026). Il testo di prima diceva «lo stato su audioQueue, e la coppia lettore-motore da
    /// fermare, che chi chiama ferma dove serve (come l'inizio di un'interruzione)», e la funzione rendeva la coppia: la Reset
    /// la fermava sul principale, dopo il suo `sync`. Da A420 chi chiama ferma lettore e motore sulla coda, nello stesso
    /// blocco (`stopPlayerAndEngineQ`, mandato A420, par. 2.1): la Lost subito, la Reset in fondo al suo `sync`.
    private func beginLocalStopQ(context: String) -> Bool {
        guard isRunning else { return false }
        isRunning = false
        cancelPendingJoin(reason: context)
        lowerOwnTransportStartQ(reason: context)
        _rejoinArmedQ = false
        // A421 — un arresto di crisi consegna il drenaggio aperto (par. 2.2 j) e pubblica lo specchio (par. 2.2 e).
        closeDrainOnCrisisStopQ(context: context)
        publishIsPlayingQ(context: context)
        return true
    }

    /// La riga dell'arresto locale di una crisi, dopo `stop()` di lettore e motore. `server`: com'era il server
    /// dei servizi audio (alla Lost assente: un'operazione nuova, A412).
    private func logLocalStop(context: String, server: String) {
        os_log("[Q-BEATS][CRISI] arresto locale contesto:%{public}@ serverAudio:%{public}@ - nessuno Stop a Link",
               log: .default, type: .default, context, server)
    }

    /// A420 (23/10/2026) — L'ARRESTO SULLA CODA (mandato A420, par. 2.1; U10 (B) del referto A419; BOX5, scelta 4 dell'uscita
    /// audio): lettore e motore si fermano qui, su audioQueue, nello stesso blocco che abbassa `isRunning`, per ogni strada
    /// (`stopSync`, inizio di un'interruzione, Reset, Lost, cambio di modo, ripartenza per la frequenza, rientro che non
    /// parte). Così «`isRunning` falso sulla coda» vuol dire «lettore e motore fermi», e un blocco della coda che passa dopo
    /// non trova un motore che si sta fermando su un altro thread (BUGS, `TD-finestra-dell-arresto-fuori-dalla-coda`). Una
    /// riga [ARRESTO] col contesto e i millisecondi dei due stop. Chiamare SOLO su audioQueue, e mai da dentro un richiamo di
    /// fine buffer (Apple, `AVAudioPlayerNode`: lì lo stop del lettore può bloccarsi; i nostri richiami accodano e tornano).
    private func stopPlayerAndEngineQ(context: String) {
        // A421 — ogni arresto fa cadere la condizione della rete del motore fermo dal sistema (par. 2.3 b).
        cancelStoppedEngineNetQ()
        let stopStart = mach_absolute_time()
        playerNode.stop()
        engine.stop()
        let stopEnd = mach_absolute_time()
        os_log("[Q-BEATS][ARRESTO] sulla coda contesto:%{public}@ ms:%.3f",
               log: .default, type: .default,
               context, machTicksToSeconds(stopEnd - stopStart) * 1000.0)
    }

    /// A412 — il Solo a una crisi della sessione audio col click in moto (mandato §2.7): come lo Stop della sua
    /// console — `stopSync` e lo stato fermo, lo schermo dopo lo Stop — ma non è uno Stop voluto
    /// (`StopOrigin.soloCrisis`). Niente verso Link (lucchetto A411). Non riparte da solo: aspetta il Play
    /// (`RecoveryDecision`). NON chiamare da audioQueue (come `stopSync`).
    private func stopForSoloCrisis(cause: CrisisCause) {
        os_log("[Q-BEATS][CRISI] Solo fermo come allo Stop della console causa:%{public}@ - non riparte da solo, aspetta il Play",
               log: .default, type: .default, cause.rawValue)
        stopSync(origin: .soloCrisis)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    }

    /// A412 — IL TOCCO DEL TASTO DELLA FASCIA (O DEL PEDALE playPause) COL DIRETTORE MUTO IN CANZONE (mandato §2.4,
    /// D2, D3): l'esito l'ha deciso il motore (`directorSilence`) e la vista lo porta qui. Play = rientra, passando
    /// dal coordinatore dentro `start()` (mai `runner.startCurrentSection`, W1 o il ramo fresco); Stop = lo Stop
    /// voluto (`stop()`), che col Direttore muto manda lo Stop a Link e chiude la canzone anche a motore fermo.
    /// Solo main.
    func directorTransportTapped(_ tap: DirectorTransportTap, origin: String) {
        os_log("[Q-BEATS][DIR-TASTO] tocco:%{public}@ origine:%{public}@",
               log: .default, type: .default, tap.rawValue, origin)
        switch tap {
        case .rejoin:
            start(trigger: origin)
        case .stopBand:
            stop()
        }
    }

    /// A412 — LA POLITICA DELLO SFONDO, valutata qui sulle copie di coda (mandato §2.8): al passaggio in sfondo Link
    /// si sospende se è in rete, il click non suona e il Direttore non è muto in canzone
    /// (`LinkActivationDecision.suspendsOnBackground`); il suo esito è l'ingresso «sospeso dallo sfondo» della regola
    /// d'accensione, e la strada resta una (`applyLinkActivationQ`). Niente `beginBackgroundTask` (T9). Fino ad
    /// A411 la politica stava in `QBeatsApp` col suo segno, e leggeva solo «il click suona». Chiamabile da main.
    func sceneEnteredBackground(clickPlaying: Bool) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            let linkActive = self._linkActiveAppliedQ ?? false
            let suspends = LinkActivationDecision.suspendsOnBackground(linkActive: linkActive,
                                                                       clickPlaying: clickPlaying,
                                                                       directorSilentInSong: self._directorSilentInSongQ)
            os_log("[Q-BEATS][SOLO-INERTE] sfondo - politica linkAttivo:%d click:%d mutoInCanzone:%d -> sospende:%d",
                   log: .default, type: .default,
                   linkActive ? 1 : 0, clickPlaying ? 1 : 0, self._directorSilentInSongQ ? 1 : 0, suspends ? 1 : 0)
            guard suspends else { return }
            self._linkBackgroundSuspendedQ = true
            self.applyLinkActivationQ(trigger: .background)
        }
    }

    /// A412 — il ritorno in primo piano: si riprende solo ciò che la politica dello sfondo ha sospeso. Chiamabile da
    /// main.
    func sceneBecameActive() {
        audioQueue.async { [weak self] in
            guard let self, self._linkBackgroundSuspendedQ else { return }
            self._linkBackgroundSuspendedQ = false
            self.applyLinkActivationQ(trigger: .foreground)
        }
    }

    /// §2.8 — l'unico cambio di comportamento del passo 1: alla Lost e alla Reset, in tutti i rami,
    /// la ripresa pendente si sgombera — pendente giù, battito di ripresa via, interruzione giù, token
    /// +1 — come fa `stopSync` durante un'interruzione. Così nessun recupero (cambio di percorso, di
    /// configurazione, risveglio, rete di sicurezza, tentativo in volo) fa ripartire il click da solo
    /// dopo il reset dei servizi audio (Apple: niente ripartenza senza un'azione dell'utente, referto
    /// A407 §1.5; A408 §7 punto 7; A409 §7.3). Una riga sempre, coi valori di prima. Chiamare SOLO su
    /// audioQueue.
    private func clearPendingResumeQ(reason: String) {
        let hadPending = pendingResume
        let hadBeat = pendingResumeBeat
        let wasInterrupted = isAudioInterrupted
        pendingResume = false
        pendingResumeBeat = nil
        isAudioInterrupted = false
        currentResumeToken += 1
        let beatText: String = hadBeat.map { String(format: "%.4f", $0) } ?? "-"
        os_log("[Q-BEATS][RESUME] ripresa pendente sgomberata motivo:%{public}@ - prima: pendente:%d battito:%{public}@ interruzione:%d - token:%d",
               log: .default, type: .default,
               reason, hadPending ? 1 : 0, beatText, wasInterrupted ? 1 : 0, currentResumeToken)
    }

    /// I secondi da `ticks` ad adesso (0 se `ticks` è nel futuro).
    private func secondsSince(_ ticks: UInt64) -> Double {
        let now = mach_absolute_time()
        return now >= ticks ? machTicksToSeconds(now - ticks) : 0
    }

    /// Da `start` a `end`, in millisecondi col segno (negativo = `end` prima di `start`).
    private func signedMilliseconds(from start: UInt64, to end: UInt64) -> Double {
        end >= start ? machTicksToSeconds(end - start) * 1000.0 : -machTicksToSeconds(start - end) * 1000.0
    }

    private func describe(_ outcome: DirectorRejoinDecision.Outcome) -> String {
        switch outcome {
        case .notCoordinated(let why):
            switch why {
            case .notDirector: return "fuori(non-direttore)"
            case .showClosed: return "fuori(show-chiuso)"
            case .noAnchor: return "fuori(nessuna-ancora)"
            }
        case .rejoin:
            return "rientra"
        case .songEnded(_, let alreadyOver):
            return alreadyOver ? "canzone-finita" : "canzone-finisce-prima"
        case .uncertain(let why):
            return "non-certo(\(describe(why)))"
        case .sessionStoppedElsewhere:
            return "sessione-ferma"
        }
    }

    private func describe(_ why: DirectorRejoinDecision.Uncertain) -> String {
        switch why {
        case .linkOff: return "link-spento"
        case .startChanged: return "avvio-cambiato"
        case .clock(let unknown): return "conto:\(describe(unknown))"
        case .rulersDisagree: return "righelli-in-disaccordo"
        case .noTarget: return "nessun-bersaglio"
        // A412 — i tre motivi nuovi del coordinatore che agisce.
        case .noAnchor: return "nessuna-ancora"
        case .mapBridgeDisagree: return "mappa-e-ponte-in-disaccordo"
        case .lateTooManyTimes: return "ritardo-oltre-i-salti"
        }
    }

    private func describe(_ why: ShowClockUnknown) -> String {
        switch why {
        case .invalidMap: return "mappa-non-valida"
        case .invalidAnchor: return "ancora-fuori-mappa"
        case .invalidInput: return "valori-non-validi"
        case .cycle: return "ciclo"
        case .beforeAnchorSection: return "prima-della-sezione"
        }
    }

    private func describe(place: ShowClockPlace, in clock: ShowClock) -> String {
        switch place {
        case .inSong(let section, let beatInSection):
            let position = clock.barAndBeat(section: section, beatInSection: beatInSection)
            return "\(section).\(position.bar).\(position.beat)"
        case .pastEnd(let beats):
            return String(format: "oltre-fine+%.2f", beats)
        case .unknown(let why):
            return "non-so(\(describe(why)))"
        }
    }

    // =====================================================================================
    // === A421 (24/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 2: LE CUFFIE E IL BUCO DEL RENDER (P11) ===============
    // =====================================================================================
    // Mandato del referee «USCITA AUDIO PASSO 2a PEZZO 2» (base `9b8803b5`; disegno dal referto A419, par. 3.1-3.2, e dal
    // collaudo di A420 del 24/10). Quando un'uscita esterna (cuffie col filo o Bluetooth, cassa, USB, uscita di linea,
    // AirPlay: tutte come le cuffie, risposta 2 di Mauro del 23/10) si stacca o si attacca a canzone in corso, o il render si
    // ferma per un buco da 75 ms in su, il click tace subito e niente arriva all'altoparlante; la band va avanti; il
    // Direttore rientra da solo alla battuta giusta quando l'uscita torna (il coordinatore di A412), il Follower torna da
    // solo sulla battuta di Link, il Solo si ferma come allo Stop e riparte col Play. Mai un click in ritardo (LIBRO
    // 2026-09-20). Le regole sono pure, col loro banco, in Models/ (`OutputRouteDecision`, `OutputReturnDecision`,
    // `RenderGapDecision`, `LateBeatDecision`, `TransportStateDecision`; le cause e gli inneschi nuovi in
    // `CrisisStopDecision` e `RecoveryDecision`); qui il collegamento, tutto su audioQueue salvo dove è detto. Nessuna
    // scrittura nuova verso Link; niente nel render callback né nel tap; niente in core_engine.
    // Le righe (testo senza accenti): [Q-BEATS][USCITA] percorso · silenzio subito · mancante · volume · ritorno · tocco
    // altoparlante · battito in ritardo zittito; [Q-BEATS][SCHED] motore fermo dal sistema, e `volume:0|1` ogni 100
    // buffer; [Q-BEATS][RENDER] con l'esito vero; [Q-BEATS][START] tempi e avvio fallito; [Q-BEATS][DRAIN] chiusura
    // consegnata dall'arresto; [Q-BEATS][RESUME] con `uscitaMancante:`.

    /// Le porte d'uscita di un percorso, col tipo e l'identificativo (U2; Apple: `portType`, `uid`). Sul thread della
    /// notizia, sulle uscite che il gestore legge già; l'identificativo non si scrive mai nel registro.
    private static func outputPorts(_ route: AVAudioSessionRouteDescription?) -> [OutputPort] {
        guard let route else { return [] }
        return route.outputs.map { OutputPort(type: $0.portType.rawValue, uid: $0.uid) }
    }

    /// Un'uscita esterna c'è adesso: una lettura del percorso della sessione (come `detectAudioMode`). Chiamare SOLO su
    /// audioQueue.
    private func hasExternalOutputNowQ() -> Bool {
        OutputRouteDecision.hasExternal(AudioEngine.outputPorts(AVAudioSession.sharedInstance().currentRoute))
    }

    /// Il ruolo del player sulle copie di coda (la regola delle crisi; par. 2.3 c: il Direttore con Link spento è il Solo).
    private var playerRoleQ: PlayerRole {
        PlayerRoleDecision.playerRole(role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
    }

    /// Il motore è fermo per una crisi o un'interruzione, non per uno Stop (l'ingresso `stoppedByCrisis` di U5): una
    /// causa viva senza uno Stop voluto dopo, o la ripresa d'interruzione in corso.
    private var stoppedByCrisisQ: Bool {
        !isRunning && ((_crisisCauseQ != nil && !_wantedStopSinceCrisisQ) || isAudioInterrupted)
    }

    /// Lo stato dell'uscita dopo un evento (`OutputRouteDecision`), con la riga `[USCITA] mancante:` quando «uscita
    /// mancante» cambia. Chiamare SOLO su audioQueue.
    /// `externalPresent`: l'uscita di adesso già letta da chi chiama (il cambio di percorso la porta dalla classe: così qui non
    /// si legge la sessione prima del silenzio di U3); `nil` = si legge qui.
    private func noteOutputStateQ(_ event: OutputSilenceEvent, from: String, externalPresent: Bool? = nil) {
        let before = _outputSilenceQ
        _outputSilenceQ = OutputRouteDecision.state(after: event, from: before, playerRole: playerRoleQ)
        guard before.missing != _outputSilenceQ.missing else { return }
        let memoryText: String = _outputSilenceQ.lastOutputExternal.map { $0 ? "esterna" : "interna" } ?? "-"
        let external = externalPresent ?? hasExternalOutputNowQ()
        os_log("[Q-BEATS][USCITA] mancante:%d da:%{public}@ esterna:%d ruolo:%{public}@ memoria:%{public}@ motore:%{public}@",
               log: .default, type: .default,
               _outputSilenceQ.missing ? 1 : 0, from, external ? 1 : 0, playerRoleQ.rawValue, memoryText,
               isRunning ? "in-moto" : "fermo")
    }

    /// U5: la rilettura del percorso a ogni rientro automatico (anche il ritorno dallo sfondo) e, da A421 · SEGUITO 1 (par.
    /// 4.3), a ogni avvio del Follower che prosegue (`from: "avvio-follower"`; fino al seguito solo al primo avvio dopo la
    /// ricostruzione): dalla memoria e dall'uscita di adesso. Rende «uscita mancante» dopo. Chiamare SOLO su audioQueue.
    private func refreshOutputMissingQ(from: String = "lettura") -> Bool {
        noteOutputStateQ(.recoveryRead(externalPresent: hasExternalOutputNowQ()), from: from)
        return _outputSilenceQ.missing
    }

    /// Il volume del mixer principale sul motore corrente, dallo stato puro (U3 b; Apple, `AVAudioMixerNode.outputVolume`:
    /// da 0 a 1). Lo scrivono solo questa funzione e, per lei, `silenceOutputNowQ`, `applyStartVolumeQ` e il ritorno del
    /// Follower: `muted` ha un solo padrone. Chiamare SOLO su audioQueue.
    private func writeOutputVolumeQ(_ volume: Float, reason: String) {
        engine.mainMixerNode.outputVolume = volume
        if volume == 0 {
            _outputSilenceQ = OutputRouteDecision.state(after: .silenced, from: _outputSilenceQ, playerRole: playerRoleQ)
        } else {
            _outputSilenceQ = OutputRouteDecision.state(after: .volumeRestored(externalPresent: hasExternalOutputNowQ()),
                                                        from: _outputSilenceQ, playerRole: playerRoleQ)
        }
        os_log("[Q-BEATS][USCITA] volume:%d motivo:%{public}@ ruolo:%{public}@ mancante:%d motore:%{public}@",
               log: .default, type: .default,
               volume == 0 ? 0 : 1, reason, playerRoleQ.rawValue, _outputSilenceQ.missing ? 1 : 0,
               isRunning ? "in-moto" : "fermo")
    }

    /// U3: il silenzio subito, prima di ogni lettura della sessione (il cambio di percorso) o prima dell'assert e della
    /// correzione (il buco del render). Chiamare SOLO su audioQueue.
    private func silenceOutputNowQ(reason: String) {
        writeOutputVolumeQ(0, reason: reason)
        os_log("[Q-BEATS][USCITA] silenzio subito motivo:%{public}@ ruolo:%{public}@ canzone:%d motore:%{public}@",
               log: .default, type: .default,
               reason, playerRoleQ.rawValue, _songInProgressQ ? 1 : 0, isRunning ? "in-moto" : "fermo")
    }

    /// U3 b: il volume che `start()` scrive sul mixer principale del motore corrente subito prima di `engine.start()` (anche
    /// sul motore nuovo del reset dei servizi, di cui Apple non dice il volume di partenza): 0 solo per il Follower con
    /// l'uscita mancante.
    private func applyStartVolumeQ() {
        writeOutputVolumeQ(OutputRouteDecision.volumeForStart(playerRole: playerRoleQ, state: _outputSilenceQ), reason: "avvio")
    }

    /// Par. 2.3 b: ogni ritorno in attesa si annulla a una tolta, uno Stop, la fine della canzone, la chiusura dello show,
    /// l'inizio di un'interruzione, la Lost e il reset dei servizi, un cambio di ruolo o Link spento, una ripartenza del
    /// motore. Chiamare SOLO su audioQueue.
    private func cancelOutputReturnsQ(reason: String) {
        let hadDirector = _directorReturnQ != nil
        let hadFollower = _followerReturnQ != nil
        _directorReturnQ = nil
        _directorReturnTimerQ.cancel()
        _followerReturnQ = nil
        guard hadDirector || hadFollower else { return }
        os_log("[Q-BEATS][USCITA] ritorno annullato motivo:%{public}@ direttore:%d follower:%d",
               log: .default, type: .default, reason, hadDirector ? 1 : 0, hadFollower ? 1 : 0)
    }

    /// L'arresto locale di una crisi dell'uscita (le cuffie tolte o aggiunte col Direttore, in canzone o fuori; il buco del
    /// render): lettore e motore sulla coda, l'ingresso pendente e il segno del proprio avvio, il drenaggio (par. 2.2 j), lo
    /// specchio (par. 2.2 e). Come gli altri arresti che non passano da `stopSync`. Chiamare SOLO su audioQueue, con
    /// `isRunning` vero.
    private func stopForOutputCrisisQ(context: String) {
        isRunning = false
        stopPlayerAndEngineQ(context: context)
        cancelPendingJoin(reason: context)
        lowerOwnTransportStartQ(reason: context)
        _rejoinArmedQ = false
        closeDrainOnCrisisStopQ(context: context)
        publishIsPlayingQ(context: context)
        logLocalStop(context: context, server: "presente")
    }

    /// Par. 2.2 j: un arresto di crisi che trova il drenaggio aperto consegna la chiusura di fine sezione una volta, sul
    /// principale, come il drenaggio, e lo chiude (la canzone era finita mentre suonava: sul Direttore lo Stop che ne viene
    /// è quello di fine canzone, col conto certo). Uno Stop voluto lo chiude senza consegnarla (`cleanupAfterStopQ`).
    /// Chiamare SOLO su audioQueue, dentro l'arresto.
    private func closeDrainOnCrisisStopQ(context: String) {
        guard _sectionEndPending else { return }
        _sectionEndPending = false
        let endClosure = _pendingEndClosure
        _pendingEndClosure = nil
        os_log("[Q-BEATS][DRAIN] chiusura di fine sezione consegnata dall'arresto contesto:%{public}@",
               log: .default, type: .default, context)
        DispatchQueue.main.async {
            endClosure?()
        }
    }

    /// Par. 2.2 e: `isPlaying` è lo specchio di `isRunning` (`TransportStateDecision`), pubblicato da una mano sola, dalla
    /// coda, a ogni passaggio di `isRunning` e a ogni uscita di `start()` senza avvio. Chiamare SOLO su audioQueue.
    private func publishIsPlayingQ(context: String) {
        let value = TransportStateDecision.isPlaying(engineRunning: isRunning)
        DispatchQueue.main.async {
            if self.isPlaying != value {
                self.isPlaying = value
            }
        }
    }

    /// La pulizia dello Stop (`stopSync`): i contatori, i cambi armati nel DSP e in Swift, i `_pendingNext*`, il drenaggio
    /// senza consegna, il lettore della base. Par. 2.2 e: anche a motore già fermo. Chiamare SOLO su audioQueue.
    private func cleanupAfterStopQ() {
        // QA-1 drift analysis reset
        qa1BeatCounter  = 0
        qa1StartTime    = 0
        beatTickCounter = 0
        // L1.a — reset counter sezione per replay corretto.
        // _sectionTotalBeats e _onSectionEnd RESTANO registrati: la sezione
        // caricata deve persistere tra stop/play (es. utente preme Stop a
        // metà sezione e poi Play — la sezione ricomincia da capo, non
        // viene "scaricata"). Solo il counter va azzerato.
        _sectionBeatCounter = 0
        // Bug 2.b ramo X — nessun offset d'ingresso stale al prossimo play.
        startBeatOffset = 0
        // Task D — Stop manuale o autostop: annulla cambio BPM pending.
        // Senza questo, un cambio armato pre-stop scatterebbe al replay
        // (DSP riapplicherebbe _pendingBPM al primo downbeat post-Play).
        // Cancel DSP + reset Swift, sempre simmetrico.
        if let mh = metronomeHandle {
            if _pendingBPMValue != nil {
                metronome_cancel_pending_bpm(mh)
            }
            // Strada A — Cancel BPB INCONDIZIONATO.
            // Dopo il ramo seamless tutti i _pendingNext* sono nil, ma
            // _bpbChangeDirty nel DSP è ancora true (armato in step d).
            // Se lo stop arriva tra lo swap e il downbeat, il cancel
            // condizionale non scatterebbe e il BPB pendente verrebbe
            // applicato al replay successivo.
            // No-op se _bpbChangeDirty già false — zero costo.
            metronome_cancel_pending_bpb(mh)
            // ATOM C (B1) — Cancel subdivision INCONDIZIONATO, stesso
            // rationale del BPB qui sopra: il canale scheduled
            // (_subdivScheduleDirty) NON è risanato dal reload — il
            // prepare usa il setter secco (canale _subdivDirty) — quindi
            // un pending armato in step d e mai scattato applicherebbe
            // al primo downbeat del replay la suddivisione della
            // transizione morta, sovrascrivendo quella corretta.
            metronome_cancel_pending_subdivision(mh)
        }
        _pendingBPMValue = nil
        _pendingBPMTargetTick = 0
        // Strada A — Reset tutti i _pendingNext* a nil.
        // Accent pattern NON richiede cancel: _patternDirty viene
        // sovrascritto dal prossimo setAccentPattern al reload.
        _pendingNextBPM = nil
        _pendingNextBPB = nil
        _pendingNextAccentPattern = nil
        _pendingNextSectionTotalBeats = nil
        _pendingNextOnSectionEnd = nil
        _pendingNextRepetitions = nil
        _pendingNextSubdivisionMultiplier = nil
        _pendingNextSwingRatio = nil
        // L1.a — Stop manuale durante drain: aborta dispatch pending.
        // Non chiamiamo la closure: stopSync sta già facendo il lavoro che
        // la closure di L1.a avrebbe fatto (stop motore + reset). Lasciarla
        // pending la farebbe scattare al prossimo Play, scenario indesiderato.
        _sectionEndPending = false
        _pendingEndClosure = nil
        backtrackPlayerNode.stop()
    }

    /// Par. 2.3 c: un cambio di ruolo, o Link spento dall'utente, col motore in moto a volume 0: arresto locale come lo Stop,
    /// nessuno Stop a Link, «uscita mancante» e «uscita zittita» giù, i ritorni annullati; il click riparte col Play, nel
    /// ruolo nuovo. Col volume a 1 il motore resta com'è (oggi). Chiamare SOLO su audioQueue: in `applySettings` prima del
    /// ruolo nuovo, in `noteUserLinkSwitchQ` dopo la levetta (la logica non dipende dal ruolo: cambia solo il campo `ruolo:`
    /// delle righe).
    private func handleRoleOrLinkChangeQ(reason: String) {
        cancelOutputReturnsQ(reason: reason)
        if isRunning && _outputSilenceQ.muted {
            isRunning = false
            stopPlayerAndEngineQ(context: reason)
            cancelPendingJoin(reason: reason)
            lowerOwnTransportStartQ(reason: reason)
            _rejoinArmedQ = false
            _songInProgressQ = false
            _wantedStopSinceCrisisQ = true
            cleanupAfterStopQ()
            publishIsPlayingQ(context: reason)
            DispatchQueue.main.async { self.playbackState = .stopped }
            os_log("[Q-BEATS][USCITA] arresto locale col volume a 0 motivo:%{public}@ - nessuno Stop a Link, il click riparte col Play nel ruolo nuovo",
                   log: .default, type: .default, reason)
        }
        if _outputSilenceQ.muted || _outputSilenceQ.missing {
            noteOutputStateQ(.roleChange, from: reason)
        }
    }

    /// U6, par. 2.2 b e d: il ritorno del Direttore dopo il silenzio. Aspetta 100 ms d'assestamento, oppure la notifica di
    /// configurazione (la frequenza della sessione già diversa dalla copia) con la riserva a 2 s; poi
    /// `activateSessionAndStart` → `RecoveryDecision` → il coordinatore → il rientro (T4, T5). Sul timer stretto, un'attesa
    /// sola alla volta. Chiamare SOLO su audioQueue.
    private func armDirectorReturnQ(trigger: RecoveryTrigger, sessionRateDiffers: Bool) {
        let wait = OutputReturnDecision.directorWait(sessionRateDiffersFromCopy: sessionRateDiffers)
        let seconds = OutputReturnDecision.directorWaitSeconds(wait)
        _directorReturnQ = DirectorReturnWaitQ(trigger: trigger, wait: wait, armedTicks: mach_absolute_time())
        os_log("[Q-BEATS][USCITA] ritorno del Direttore armato innesco:%{public}@ attesa:%{public}@ ms:%.0f timer:stretto leeway_ms:%d",
               log: .default, type: .default, trigger.rawValue, wait.rawValue, seconds * 1000.0,
               StrictOneShotTimer.leewayMilliseconds)
        let reason = (wait == .settle) ? "assestamento" : "scaduta"
        let work = DispatchWorkItem { [weak self] in
            self?.fireDirectorReturnQ(reason: reason)
        }
        _directorReturnTimerQ.arm(afterSeconds: seconds, work: work)
    }

    /// Lo scatto del ritorno del Direttore (il timer, o la notifica «ignorato»): riguarda le condizioni con cui è stato armato
    /// (par. 2.3 b: motore fermo, interruzione di sistema bassa, Direttore muto in canzone, uscita non mancante) e, se
    /// reggono, la ripartenza col suo innesco. Chiamare SOLO su audioQueue.
    private func fireDirectorReturnQ(reason: String) {
        guard let waiting = _directorReturnQ else { return }
        _directorReturnQ = nil
        _directorReturnTimerQ.cancel()
        let elapsedMs = machTicksToSeconds(mach_absolute_time() &- waiting.armedTicks) * 1000.0
        guard !isRunning, !_interruptionRouteQ.systemInterruption, _directorSilentInSongQ, !_outputSilenceQ.missing else {
            os_log("[Q-BEATS][USCITA] ritorno del Direttore non eseguito attesa:%{public}@ innesco:%{public}@ motore:%{public}@ interruzione:%d muto:%d mancante:%d ms:%.0f",
                   log: .default, type: .default,
                   reason, waiting.trigger.rawValue, isRunning ? "in-moto" : "fermo",
                   _interruptionRouteQ.systemInterruption ? 1 : 0, _directorSilentInSongQ ? 1 : 0,
                   _outputSilenceQ.missing ? 1 : 0, elapsedMs)
            return
        }
        os_log("[Q-BEATS][USCITA] ritorno innesco:%{public}@ attesa:%{public}@ ms:%.0f",
               log: .default, type: .default, waiting.trigger.rawValue, reason, elapsedMs)
        activateSessionAndStart(resumeAtBeat: nil, trigger: waiting.trigger)
    }

    /// Par. 2.2 b: la notifica di configurazione «ignorato» (il motore l'abbiamo già fermato noi) è il segnale del ritorno
    /// che aspetta la configurazione. Chiamare SOLO su audioQueue, dal gestore della configurazione.
    private func noteConfigurationIgnoredQ() {
        guard let waiting = _directorReturnQ, waiting.wait == .configuration else { return }
        os_log("[Q-BEATS][USCITA] la notifica di configurazione e' il segnale del ritorno innesco:%{public}@",
               log: .default, type: .default, waiting.trigger.rawValue)
        fireDirectorReturnQ(reason: "configurazione")
    }

    /// Par. 2.2 c, g: il ritorno del Follower si prenota alla notizia (o al tocco «altoparlante») e si arma alla prima chiamata
    /// di `scheduleNextBuffer` dopo, con la catena dei buffer di quel momento (durante l'attesa d'ingresso del Follower non
    /// ci sono chiamate: si arma al fuoco). Chiamare SOLO su audioQueue.
    private func armFollowerReturnQ(noticeTicks: UInt64, fromTap: Bool) {
        _followerReturnQ = FollowerReturnQ(noticeTicks: noticeTicks, fromTap: fromTap, armPending: true,
                                           chain: _bufferChainGenerationQ)
        os_log("[Q-BEATS][USCITA] ritorno del Follower prenotato da:%{public}@ - si arma alla prossima chiamata della catena",
               log: .default, type: .default, fromTap ? "tocco" : "notizia")
    }

    /// A421 · SEGUITO 1 (par. 2.2) — il ritorno armato si riarma con la stessa regola (`armPending` vero, come al cambio di
    /// catena, par. 2.3 b): le due ore si rifanno alla prossima chiamata (quella in corso, se chiamato da
    /// `armFollowerReturnIfPendingQ` o dal misuratore prima di lei). Chiamare SOLO su audioQueue.
    private func rearmFollowerReturnQ(reason: String) {
        guard var armed = _followerReturnQ, !armed.armPending else { return }
        armed.armPending = true
        _followerReturnQ = armed
        os_log("[Q-BEATS][USCITA] ritorno del Follower: %{public}@ - si riarma con la stessa regola",
               log: .default, type: .default, reason)
    }

    /// Il primo «uno» di battuta non prima di `ticks`, come battito col suo orologio (`FollowerReturnUno`) e la sua ora: di
    /// Link (la cattura senza commit, T11: `link_engine_read_session_at`, `link_engine_time_at_beat`) quando il Follower segue
    /// Link; DA-SOLO dalla linea propria e dall'ultimo «uno» uscito. `nil` se non si può calcolare (A421 · SEGUITO 1, par.
    /// 2.2: il segno «uno non calcolabile»). Chiamare SOLO su audioQueue.
    private func nextUnoQ(atOrAfter ticks: UInt64) -> (uno: FollowerReturnUno, ticks: UInt64)? {
        let quantum = Double(max(_beatsPerBarQ, 1))
        if followsLinkQ() {
            guard let lh = linkEngineHandle else { return nil }
            let reading = link_engine_read_session_at(lh, ticks, quantum)
            guard reading.linkEnabled,
                  let bar = OutputReturnDecision.nextBarBeat(atOrAfter: reading.beatAtHostTime, quantum: quantum) else {
                return nil
            }
            let uno = FollowerReturnUno(beat: bar, clock: .link)
            guard let time = unoTicksQ(for: uno) else { return nil }
            return (uno, time)
        }
        guard let timeline = _ownTimelineQ, let lastUno = _lastUnoBeatQ else { return nil }
        let beatAtDeadline = timeline.beat(atTicks: ticks, ticksPerSecond: ticksPerSecond)
        guard let unoBeat = OutputReturnDecision.nextOwnUnoBeat(atOrAfter: beatAtDeadline, lastUnoBeat: lastUno,
                                                                beatsPerBar: Int(max(_beatsPerBarQ, 1))) else { return nil }
        let uno = FollowerReturnUno(beat: unoBeat, clock: .own)
        guard let time = unoTicksQ(for: uno) else { return nil }
        return (uno, time)
    }

    /// A421 · SEGUITO 1 (par. 2.2) — l'ora dell'«uno» riletta dal battito salvato: Link con `link_engine_time_at_beat` (la
    /// lettura di A421, T11: nessuna scrittura); DA-SOLO con `ownTicks` sulla linea propria. `nil` se non si può rileggere
    /// (Link spento nella lettura; la linea propria assente, come dopo un cambio di tempo della sezione fino alla ri-àncora).
    /// Chiamare SOLO su audioQueue.
    private func unoTicksQ(for uno: FollowerReturnUno) -> UInt64? {
        switch uno.clock {
        case .link:
            guard let lh = linkEngineHandle else { return nil }
            let time = link_engine_time_at_beat(lh, uno.beat, Double(max(_beatsPerBarQ, 1)))
            return time.linkEnabled ? time.hostTime : nil
        case .own:
            guard let timeline = _ownTimelineQ else { return nil }
            return OutputReturnDecision.ownTicks(atBeat: uno.beat, timeline: timeline, ticksPerSecond: ticksPerSecond)
        }
    }

    /// Alla prima chiamata di `scheduleNextBuffer` dopo la notizia o il tocco (par. 2.2 c, g; A421 · SEGUITO 1, par. 2.1: la
    /// stessa regola per tutti e due): le due ore — 0,3 s dalla notizia (o dal tocco), e la fine d'uscita dei buffer
    /// programmati fino a questa chiamata (compreso quello che produce) più la coda del click (40 ms), latenza compresa — e il
    /// primo «uno» di battuta dopo tutte e due, come battito col suo orologio; senza un «uno» calcolabile, il segno (il volume
    /// torna alla prima chiamata col primo campione a volume 1 alla scadenza o dopo). Prima, col ritorno già armato: il cambio
    /// di catena (par. 2.3 b) e la rilettura dell'«uno» (A421 · SEGUITO 1, par. 2.2): se l'orologio non è più quello salvato, o
    /// l'ora dell'«uno» non si rilegge, si riarma con la stessa regola in questa stessa chiamata; se no l'ora dell'«uno» è
    /// quella riletta adesso (un cambio di tempo fra l'armo e l'«uno» lo tiene sulla battuta). Le ore si leggono senza la riga
    /// [L1bSync] (`nextBufferOutputReadQ`). ⚠️ RISCRITTO A421 · SEGUITO 1: fino al seguito il tocco aveva la sola ora «0,3 s
    /// dopo il tocco» (dentro un buco del render la prima chiamata dopo il tocco è quella dopo il buco: la scadenza era già
    /// passata e i buffer programmati prima del buco uscivano a volume 1), e senza un «uno» calcolabile l'«uno» era la
    /// scadenza stessa. Chiamare SOLO su audioQueue.
    private func armFollowerReturnIfPendingQ(nowTicks: UInt64) {
        // Par. 2.3 b: un ritorno armato con una catena che non è più quella corrente (il motore in moto, il volume a 0,
        // «uscita mancante» giù) si riarma con la stessa regola: le due ore si rifanno da questa chiamata.
        if let armed = _followerReturnQ, !armed.armPending, armed.chain != _bufferChainGenerationQ {
            rearmFollowerReturnQ(reason: "catena cambiata \(armed.chain) -> \(_bufferChainGenerationQ)")
        }
        // A421 · SEGUITO 1 (par. 2.2): l'orologio e l'ora dell'«uno», a ogni chiamata col ritorno armato e un «uno» scelto.
        if var armed = _followerReturnQ, !armed.armPending, let uno = armed.uno {
            let clockNow = OutputReturnDecision.unoClock(followsLink: followsLinkQ())
            switch OutputReturnDecision.refreshUno(saved: uno, clockNow: clockNow, rereadTicks: unoTicksQ(for: uno)) {
            case .rearm(let reason):
                rearmFollowerReturnQ(reason: "\(reason) orologio:\(uno.clock.rawValue) adesso:\(clockNow.rawValue) battito:\(String(format: "%.2f", uno.beat))")
            case .ticks(let ticks):
                armed.unoTicks = ticks
                _followerReturnQ = armed
            }
        }
        guard var pending = _followerReturnQ, pending.armPending else { return }
        let bufferTicks = secondsToMachTicks(Double(bufferSize) / max(sampleRate, 1))
        let read = nextBufferOutputReadQ()
        let end = OutputReturnDecision.programmedEndOutputTicks(nextBufferOutputTicks: read.ticks,
                                                                queuedAhead: OutputReturnDecision.queuedAheadBuffers,
                                                                bufferTicks: bufferTicks)
        let deadline = OutputReturnDecision.followerDeadlineTicks(noticeTicks: pending.noticeTicks, programmedEndOutputTicks: end,
                                                                  ticksPerSecond: ticksPerSecond)
        let next = nextUnoQ(atOrAfter: deadline)
        pending.armPending = false
        pending.deadlineTicks = deadline
        pending.uno = next?.uno
        pending.unoTicks = next?.ticks
        pending.chain = _bufferChainGenerationQ
        _followerReturnQ = pending
        os_log("[Q-BEATS][USCITA] ritorno del Follower armato da:%{public}@ scadenza_ms:%.1f uno_ms:%{public}@ orologio:%{public}@ battito:%{public}@ lettura:%{public}@ catena:%d - il volume torna al calcolo del buffer dell'uno, se il primo campione a volume 1 non e' prima della scadenza",
               log: .default, type: .default,
               pending.fromTap ? "tocco" : "notizia",
               signedMilliseconds(from: nowTicks, to: deadline),
               next.map { String(format: "%.1f", signedMilliseconds(from: nowTicks, to: $0.ticks)) } ?? "-",
               next?.uno.clock.rawValue ?? "uno-non-calcolabile",
               next.map { String(format: "%.2f", $0.uno.beat) } ?? "-",
               read.fallback ? "riserva" : "hardware",
               pending.chain)
    }

    /// A ogni buffer prodotto da `scheduleNextBuffer`, prima di `metronome_processBuffer`: se il buffer porta l'«uno» (la sua
    /// fine d'uscita è oltre), il volume torna ADESSO, prima che si calcoli il battito dell'«uno» (U3 c: circa due buffer
    /// prima del suo rendering, i due già programmati davanti), se le condizioni con cui il ritorno è stato armato reggono
    /// (par. 2.3 b: motore in moto, interruzione di sistema bassa, uscita non mancante, volume ancora a 0, servizi audio
    /// normali) e — A421 · SEGUITO 1 (par. 2.2) — se il primo campione che può uscire a volume 1, letto in questa chiamata dal
    /// rendering nel caso peggiore (`firstSampleAtVolumeOneTicks`), non è prima della scadenza; se è prima, il ritorno passa
    /// all'«uno» della battuta dopo (lo stesso battito più una battuta, stessa scadenza, stessa catena) e resta armato. Senza
    /// un «uno» calcolabile il volume torna alla prima chiamata col primo campione alla scadenza o dopo, con le stesse
    /// condizioni. Se mancano le condizioni il ritorno si toglie, come prima; se manca solo la guardia del primo campione,
    /// resta armato. ⚠️ RISCRITTO A421 dopo la verifica indipendente del diff (la prima stesura rimetteva il volume al
    /// rendering stimato su un timer) e A421 · SEGUITO 1 (la scadenza era scritta per l'«uno»: coi buffer già programmati
    /// davanti il primo campione a volume 1 poteva cadere prima della scadenza, dentro la coda di un click partito prima del
    /// buco). Chiamare SOLO su audioQueue.
    private func checkFollowerReturnQ(bufferOutputTicks: UInt64) {
        guard var pending = _followerReturnQ, !pending.armPending else { return }
        let bufferTicks = secondsToMachTicks(Double(bufferSize) / max(sampleRate, 1))
        if let uno = pending.unoTicks {
            guard OutputReturnDecision.bufferReachesUno(bufferOutputTicks: bufferOutputTicks, bufferTicks: bufferTicks,
                                                        unoTicks: uno) else { return }
        }
        let read = nextBufferOutputReadQ()
        // Il ciclo d'uscita della sessione (`bufferDurationTicks`, quello che `nextBufferOutputHostTime` somma), non il buffer da
        // 512 campioni del lettore (`bufferTicks`, che vale per `bufferReachesUno` e per la fine dei buffer programmati): con
        // un ciclo di 21,33 ms la differenza è 10,67 ms di guardia (dopo la verifica indipendente del diff).
        let firstSample = OutputReturnDecision.firstSampleAtVolumeOneTicks(nextBufferOutputTicks: read.ticks,
                                                                           cycleTicks: bufferDurationTicks,
                                                                           fallbackRead: read.fallback)
        let step = OutputReturnDecision.followerReturnStep(bufferOutputTicks: bufferOutputTicks, bufferTicks: bufferTicks,
                                                           unoTicks: pending.unoTicks, deadlineTicks: pending.deadlineTicks,
                                                           firstSampleTicks: firstSample)
        if pending.unoTicks == nil && step == .wait {
            // Senza un «uno» calcolabile: il primo campione a volume 1 è ancora prima della scadenza, si aspetta.
            return
        }
        guard isRunning, !_interruptionRouteQ.systemInterruption, !_outputSilenceQ.missing, _outputSilenceQ.muted,
              MediaServicesResetDecision.allowsAudioWork(_mediaServicesQ) else {
            _followerReturnQ = nil
            os_log("[Q-BEATS][USCITA] ritorno del Follower non eseguito motore:%{public}@ interruzione:%d mancante:%d zittito:%d servizi:%{public}@",
                   log: .default, type: .default,
                   isRunning ? "in-moto" : "fermo", _interruptionRouteQ.systemInterruption ? 1 : 0,
                   _outputSilenceQ.missing ? 1 : 0, _outputSilenceQ.muted ? 1 : 0, describe(_mediaServicesQ))
            return
        }
        switch step {
        case .wait:
            return
        case .nextBar(let earlyTicks):
            guard let uno = pending.uno,
                  let next = OutputReturnDecision.nextBarUno(uno, beatsPerBar: Int(max(_beatsPerBarQ, 1))) else {
                return
            }
            pending.uno = next
            pending.unoTicks = unoTicksQ(for: next)
            if pending.unoTicks == nil {
                // L'ora dell'«uno» dopo non si rilegge: si riarma con la stessa regola alla prossima chiamata.
                pending.armPending = true
            }
            _followerReturnQ = pending
            os_log("[Q-BEATS][USCITA] ritorno del Follower alla battuta dopo - primo campione a volume 1 %.1f ms prima della scadenza battito:%.2f orologio:%{public}@ uno_ms:%{public}@ lettura:%{public}@",
                   log: .default, type: .default,
                   machTicksToSeconds(earlyTicks) * 1000.0, next.beat, next.clock.rawValue,
                   pending.unoTicks.map { String(format: "%.1f", signedMilliseconds(from: bufferOutputTicks, to: $0)) } ?? "non-rileggibile",
                   read.fallback ? "riserva" : "hardware")
        case .restore:
            _followerReturnQ = nil
            if let uno = pending.unoTicks {
                os_log("[Q-BEATS][USCITA] ritorno del Follower: il buffer dell'uno si calcola adesso uscita:%llu uno:%llu primoCampione_ms:%.1f lettura:%{public}@ - volume a 1 prima del calcolo (U3 c)",
                       log: .default, type: .default, bufferOutputTicks, uno,
                       signedMilliseconds(from: pending.deadlineTicks, to: firstSample), read.fallback ? "riserva" : "hardware")
            } else {
                os_log("[Q-BEATS][USCITA] ritorno del Follower senza un uno calcolabile: il primo campione a volume 1 e' %.1f ms dopo la scadenza lettura:%{public}@ - volume a 1",
                       log: .default, type: .default,
                       signedMilliseconds(from: pending.deadlineTicks, to: firstSample), read.fallback ? "riserva" : "hardware")
            }
            writeOutputVolumeQ(1, reason: "ritorno-follower")
        }
    }

    /// Par. 2.2 g: il tocco «altoparlante» del Follower (oggi il tasto della vista di debug; il tasto di CD chiamerà questa
    /// stessa funzione). Abbassa «uscita mancante» e, col motore in moto a volume 0, il click torna dall'altoparlante al
    /// primo «uno» di battuta almeno 0,3 s dopo il tocco. Chiamabile da main.
    func followerSpeakerTapped() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            let now = mach_absolute_time()
            guard self.playerRoleQ == .follower else {
                os_log("[Q-BEATS][USCITA] tocco altoparlante ignorato - ruolo:%{public}@",
                       log: .default, type: .default, self.playerRoleQ.rawValue)
                return
            }
            os_log("[Q-BEATS][USCITA] tocco altoparlante mancante:%d zittito:%d motore:%{public}@",
                   log: .default, type: .default,
                   self._outputSilenceQ.missing ? 1 : 0, self._outputSilenceQ.muted ? 1 : 0,
                   self.isRunning ? "in-moto" : "fermo")
            self.noteOutputStateQ(.speakerTap, from: "tocco")
            guard MediaServicesResetDecision.allowsAudioWork(self._mediaServicesQ) else {
                // A408: sul motore morto non si scrive niente; il volume lo riscrive `start()` dopo il reset (par. 2.3 b).
                os_log("[Q-BEATS][USCITA] tocco altoparlante coi servizi audio persi - solo lo stato, il volume lo riscrive l'avvio dopo il reset",
                       log: .default, type: .default)
                return
            }
            if self.isRunning && self._outputSilenceQ.muted {
                self.armFollowerReturnQ(noticeTicks: now, fromTap: true)
            }
        }
    }

    /// Par. 2.2 a: un richiamo trova il motore di sistema fermo con `isRunning` vero (il motore l'ha fermato il sistema, come
    /// alle 12:35:23.005 del 24/10): niente buffer, quindi niente assert e niente correzione; una riga coi millisecondi
    /// dall'ultimo buffer programmato (la prima volta, poi una ogni dieci); la rete a 2 s, se non è già armata. Chiamare
    /// SOLO su audioQueue, da `scheduleNextBuffer`.
    private func noteSystemStoppedEngineQ() {
        _stoppedEngineCallbacksQ += 1
        let sinceMs: Double = _lastScheduledTicksQ > 0
            ? machTicksToSeconds(mach_absolute_time() &- _lastScheduledTicksQ) * 1000.0 : -1
        // A421 · SEGUITO 1 (par. 5.3) — al primo richiamo prima l'armo, poi la riga: `rete:1` (fino al seguito la riga veniva
        // prima dell'armo e scriveva `rete:0`). La riga resta fuori dalla guardia dell'armo: la prima volta e poi una ogni dieci.
        if _stoppedEngineNetChainQ == nil {
            _stoppedEngineNetChainQ = _bufferChainGenerationQ
            let work = DispatchWorkItem { [weak self] in
                self?.fireStoppedEngineNetQ()
            }
            _stoppedEngineNetTimerQ.arm(afterSeconds: OutputReturnDecision.stoppedEngineNetSeconds, work: work)
        }
        if OutputReturnDecision.writesStoppedEngineLine(callbacks: _stoppedEngineCallbacksQ) {
            os_log("[Q-BEATS][SCHED] motore fermo dal sistema - nessun buffer programmato dallUltimoBuffer_ms:%.1f richiami:%d catena:%d rete:%d",
                   log: .default, type: .default,
                   sinceMs, _stoppedEngineCallbacksQ, _bufferChainGenerationQ, _stoppedEngineNetChainQ == nil ? 0 : 1)
        }
    }

    /// La rete del motore fermo dal sistema si annulla solo quando cade la sua condizione: `isRunning` falso, una catena
    /// nuova, il motore di sistema di nuovo in moto (par. 2.3 b). Chiamare SOLO su audioQueue.
    private func cancelStoppedEngineNetQ() {
        guard _stoppedEngineNetChainQ != nil else { return }
        _stoppedEngineNetChainQ = nil
        _stoppedEngineNetTimerQ.cancel()
    }

    /// La rete (par. 2.2 a): se lo stato è ancora quello (la stessa catena, `isRunning` vero, il motore di sistema fermo) usa
    /// la decisione della notifica di configurazione (`EngineConfigChangeDecision`) con le sue guardie (motore corrente,
    /// lavoro audio permesso: niente sul grafo di un motore morto, A408), non il corpo del gestore: non segna l'ora della
    /// configurazione; con la ripresa pendente la toglie come fa il gestore; e se la decisione dà una ripartenza va alla
    /// strada della configurazione (`restartForRateChangeQ`) con la sua fonte e il suo innesco. Chiamare SOLO su audioQueue.
    private func fireStoppedEngineNetQ() {
        let armedChain = _stoppedEngineNetChainQ
        _stoppedEngineNetChainQ = nil
        _stoppedEngineNetTimerQ.cancel()
        guard armedChain == _bufferChainGenerationQ, isRunning, !engine.isRunning else {
            os_log("[Q-BEATS][SCHED] rete del motore fermo: condizione caduta catena:%{public}@ corrente:%d isRunning:%d motoreGira:%d",
                   log: .default, type: .default,
                   armedChain.map { String($0) } ?? "-", _bufferChainGenerationQ, isRunning ? 1 : 0, engine.isRunning ? 1 : 0)
            return
        }
        let step = EngineConfigChangeDecision.outcome(senderIsCurrent: true,
                                                      stateRunning: isRunning,
                                                      engineRunning: engine.isRunning,
                                                      audioWorkAllowed: MediaServicesResetDecision.allowsAudioWork(_mediaServicesQ),
                                                      pendingResume: pendingResume)
        os_log("[Q-BEATS][SCHED] rete del motore fermo scattata richiami:%d esito:%{public}@ - nessun gestore in %.0f s",
               log: .default, type: .default,
               _stoppedEngineCallbacksQ, step.rawValue, OutputReturnDecision.stoppedEngineNetSeconds)
        switch step {
        case .recoverPending, .restart:
            if step == .recoverPending {
                pendingResume = false
                pendingResumeBeat = nil
                os_log("[Q-BEATS][RESUME] pendingResume recuperato dalla rete del motore fermo - arresto esplicito e ricostruzione prima",
                       log: .default, type: .default)
            }
            restartForRateChangeQ(source: .stoppedEngineNet, trigger: .engineStoppedBySystem, mode: detectAudioMode())
        case .mediaReset:
            _ = mediaResetSkipsQ("rete del motore fermo")
        case .ignored, .notCurrentEngine:
            break
        }
    }

    /// U7: la crisi da misuratore. Il silenzio, la crisi «buco-del-render», l'arresto locale sulla coda, il tasto, il ritorno
    /// con l'attesa di U6 (`renderGap`); il buffer del buco non si programma: né assert né correzione. Chiamare SOLO su
    /// audioQueue, da `scheduleNextBuffer`, con `isRunning` vero.
    private func handleRenderGapCrisisQ(_ gap: RenderGapMeter.Gap) {
        os_log("[Q-BEATS][USCITA] crisi da misuratore buco_ms:%.1f soglia_ms:%.0f buffer:%d - silenzio, arresto locale, il buffer del buco non si programma (U7)",
               log: .default, type: .default,
               gap.holeSeconds * 1000.0, RenderGapMeter.crisisThresholdSeconds * 1000.0, gap.bufferCount)
        silenceOutputNowQ(reason: "buco-del-render")
        if crisisOutcomeQ(cause: .renderGap) == .silentInSong {
            enterDirectorSilenceQ(cause: .renderGap)
        }
        stopForOutputCrisisQ(context: "buco-del-render")
        publishDirectorSilenceQ(context: "buco-del-render")
        cancelOutputReturnsQ(reason: "buco-del-render")
        // Come U6: se la frequenza della sessione è già diversa dalla copia si aspetta la configurazione (la lettura della
        // sessione viene dopo il silenzio).
        armDirectorReturnQ(trigger: .renderGap,
                           sessionRateDiffers: !SampleRateDecision.same(AVAudioSession.sharedInstance().sampleRate, sampleRate))
    }

    /// U9 — ai due punti della correzione (la fase di Link; l'orologio proprio del Follower DA-SOLO), prima di
    /// `metronome_processBuffer`: se la correzione scavalca il battito pendente e il battito del fire-asap uscirebbe in
    /// ritardo di almeno un buffer (`LateBeatDecision`, sull'origine che Swift ha passato al DSP), il primo battito di
    /// questo buffer si conta e non si suona (il ciclo dei battiti in `scheduleNextBuffer`). Una riga. Chiamare SOLO su
    /// audioQueue.
    private func noteLateBeatCorrectionQ(before: Double, after: Double, bpm: Double, point: String) {
        let late = LateBeatDecision.lateBeats(origin: _dspOriginBeatQ, before: before, after: after)
        guard LateBeatDecision.mutesLateBeat(lateBeats: late, bpm: bpm, bufferFrames: Int(bufferSize), sampleRate: sampleRate) else {
            return
        }
        _muteLateBeatThisBufferQ = true
        os_log("[Q-BEATS][USCITA] correzione che scavalca il battito punto:%{public}@ prima:%.4f dopo:%.4f origine:%.4f ritardo_ms:%.1f tempo:%.2f buffer:%d - il battito di questo buffer si conta e non si suona (U9)",
               log: .default, type: .default,
               point, before, after, _dspOriginBeatQ, LateBeatDecision.lateMilliseconds(lateBeats: late, bpm: bpm), bpm,
               bufferCount)
    }

    /// Par. 2.2 h: una riga per avvio coi millisecondi da `[START] ENTRY` (sul thread del chiamante) all'inizio del blocco
    /// della coda, alla fine di `engine.start()`, alla fine di `playerNode.play()` e a `hostNow` (solo il ramo fresco: la
    /// ripresa e il rientro non ce l'hanno). Nessun cambio di comportamento. Chiamare SOLO su audioQueue.
    private func logStartTimingQ(trigger: String, branch: String, entry: UInt64, block: UInt64, engineStarted: UInt64,
                                 played: UInt64, hostNow: UInt64?) {
        let hostNowText: String = hostNow.map { String(format: "%.1f", signedMilliseconds(from: entry, to: $0)) } ?? "-"
        os_log("[Q-BEATS][START] tempi innesco:%{public}@ ramo:%{public}@ coda_ms:%.1f motore_ms:%.1f lettore_ms:%.1f hostNow_ms:%{public}@ - da [START] ENTRY",
               log: .default, type: .default,
               trigger, branch,
               signedMilliseconds(from: entry, to: block), signedMilliseconds(from: entry, to: engineStarted),
               signedMilliseconds(from: entry, to: played), hostNowText)
    }

    /// La condizione «hardware ancora occupato» della fine dell'interruzione (la stessa del suo gestore): la sessione in un
    /// modo di chiamata, o il suggerimento di silenzio. Chiamare SOLO su audioQueue.
    private func hardwareBusyForResumeQ() -> Bool {
        let session = AVAudioSession.sharedInstance()
        let isCallActive = session.mode == .voiceChat ||
                           session.mode == .videoChat ||
                           session.mode == .voicePrompt ||
                           session.category == .record ||
                           session.category == .playAndRecord
        return isCallActive || session.secondaryAudioShouldBeSilencedHint
    }

    /// U5: a ogni «niente» per l'uscita mancante, con l'interruzione di sistema bassa e l'hardware libero,
    /// `isAudioInterrupted` si abbassa e il tasto si ripubblica (come dopo un reset): senza, il tasto del Direttore resterebbe
    /// «ferma la band» e il pedale fermerebbe la band. Con l'hardware ancora occupato la ripresa pendente resta in piedi,
    /// perché chi la recupera l'ha già tolta: così una notizia dopo la riprova. Chiamare SOLO su audioQueue.
    private func noteNoRestartQ(trigger: RecoveryTrigger, stage: String, reason: NoRestartReason?) {
        guard reason == .outputMissing else { return }
        // A421 · SEGUITO 1 (par. 5.2) — col Direttore fuori da una canzone `playbackState` restava `.playing` (lo leggono
        // LiveView e `transportInMotion`): il player a «fermo» sul principale, come fa la tolta (U16); il Direttore muto in
        // canzone tiene lo stato del tasto col silenzio.
        if playerRoleQ == .direttore && !_directorSilentInSongQ {
            os_log("[Q-BEATS][USCITA] player a fermo - Direttore fuori da una canzone, niente ripartenza per l'uscita mancante innesco:%{public}@",
                   log: .default, type: .default, trigger.rawValue)
            DispatchQueue.main.async { self.playbackState = .stopped }
        }
        let busy = hardwareBusyForResumeQ()
        if !_interruptionRouteQ.systemInterruption && !busy {
            if isAudioInterrupted {
                isAudioInterrupted = false
                os_log("[Q-BEATS][USCITA] niente ripartenza per l'uscita mancante innesco:%{public}@ fase:%{public}@ - interruzione abbassata, il tasto si ripubblica",
                       log: .default, type: .default, trigger.rawValue, stage)
            }
            publishDirectorSilenceQ(context: "uscita-mancante")
        } else if busy {
            pendingResume = true
            pendingResumeBeat = nil
            os_log("[Q-BEATS][USCITA] niente ripartenza per l'uscita mancante innesco:%{public}@ fase:%{public}@ - hardware occupato, ripresa pendente in piedi",
                   log: .default, type: .default, trigger.rawValue, stage)
        }
    }

    /// A421 · SEGUITO 1 (par. 3.2-3.3) — la regola: con l'interruzione di sistema in corso una ripartenza automatica non
    /// scrive la sessione e non lavora sul motore, salvo l'eccezione della catena del ritorno in primo piano del Direttore
    /// muto in canzone (`InterruptionActivationDecision`: il segno di questa catena, il contatore degli inizi non cambiato, il
    /// Direttore muto in canzone adesso; al punto `start` mai). `chainToken`: il contatore della catena di chi chiede.
    /// Chiamare SOLO su audioQueue.
    private func interruptionActivationAllowedQ(point: InterruptionActivationPoint, chainToken: Int) -> Bool {
        InterruptionActivationDecision.allowsActivation(point: point,
                                                        systemInterruption: _interruptionRouteQ.systemInterruption,
                                                        mark: _interruptionExceptionQ,
                                                        chainToken: chainToken,
                                                        beginsCount: _interruptionBeginsQ,
                                                        playerRole: playerRoleQ,
                                                        silentInSong: _directorSilentInSongQ)
    }

    /// A421 · SEGUITO 1 (par. 3.3) — con la regola che dice no: nessuna scrittura della sessione e nessun lavoro sul motore,
    /// poi: con `isAudioInterrupted` vero niente (la fine dell'interruzione ha già la sua strada); se no, senza uno Stop
    /// voluto dopo la crisi, la ripresa pendente (la recupera la fine); il Solo non alza mai la ripresa pendente: si ferma come
    /// allo Stop della console, sul principale (`stopForSoloCrisis` fa `audioQueue.sync`), con la causa ricordata
    /// «interruzione» (`CrisisStopDecision.rememberedCause`: fino al suo Play `RecoveryDecision` dice «niente»). Una riga e si
    /// esce; `pendente:` è la ripresa pendente dopo. `attempt` nullo al punto `start`. Chiamare SOLO su audioQueue.
    private func refuseActivationInInterruptionQ(trigger: RecoveryTrigger, attempt: Int?, point: InterruptionActivationPoint) {
        let refusal = InterruptionActivationDecision.refusal(playerRole: playerRoleQ,
                                                             isAudioInterrupted: isAudioInterrupted,
                                                             wantedStopSinceCrisis: _wantedStopSinceCrisisQ)
        switch refusal {
        case .nothing:
            break
        case .raisePending:
            pendingResume = true
            pendingResumeBeat = nil
        case .soloStop:
            _crisisCauseQ = CrisisStopDecision.rememberedCause(previous: _crisisCauseQ, new: .interruption, playerRole: .solo)
            DispatchQueue.main.async { [weak self] in
                self?.stopForSoloCrisis(cause: .interruption)
            }
        }
        os_log("[Q-BEATS][RESUME] niente sessione - interruzione di sistema in corso innesco:%{public}@ tentativo:%{public}@ fase:%{public}@ pendente:%d",
               log: .default, type: .default,
               trigger.rawValue, attempt.map { String($0) } ?? "-", point.rawValue, pendingResume ? 1 : 0)
        if refusal == .soloStop {
            os_log("[Q-BEATS][RESUME] il Solo si ferma come allo Stop della console - causa ricordata:%{public}@ - niente ripresa pendente, riparte col Play",
                   log: .default, type: .default, _crisisCauseQ?.rawValue ?? "-")
        }
    }

    /// A412 — `trigger`: chi chiede l'avvio, per la riga del coordinatore (le ripartenze automatiche passano il
    /// loro innesco, il tasto e il pedale la loro origine; tutti gli altri «comando»).
    /// A421 — `recovery`: l'innesco tipizzato delle ripartenze automatiche (`activateSessionAndStart`), `nil` per il tasto
    /// della fascia, il pedale e il comando: solo con lui `start()` riguarda «uscita mancante» (U5).
    func start(resumeAtBeat: Double? = nil, trigger: String = "comando", recovery: RecoveryTrigger? = nil) {
        // A421 — par. 2.2 h: l'ora di [START] ENTRY, sul thread del chiamante.
        let entryTicks = mach_absolute_time()
        os_log("[Q-BEATS][START] ENTRY resumeAtBeat=%{public}@ _startAbsoluteBeat=%.6f innesco:%{public}@",
               log: .default, type: .default,
               resumeAtBeat.map { String(format: "%.6f", $0) } ?? "nil",
               self._startAbsoluteBeat, trigger)

        audioQueue.async { [weak self] in
            guard let self else { return }
            let blockStartTicks = mach_absolute_time()
            guard !self.isRunning, let _ = self.metronomeHandle else {
                os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                       log: .default, type: .default)
                // A421 — par. 2.2 e: lo specchio a ogni uscita di `start()` senza avvio.
                self.publishIsPlayingQ(context: "avvio-gia-in-moto")
                return
            }

            // === A421 (24/10/2026) — U5 NEL BLOCCO DELLA CODA: le ripartenze automatiche riguardano «uscita mancante»; il
            // Play del batterista (tasto della fascia, pedale, comando: `recovery` nullo) sceglie l'uscita che c'è (D2) ===
            // Fra l'ultima lettura di `RecoveryDecision` in `activateSessionAndStart` e questo blocco può arrivare una tolta:
            // il Direttore con l'uscita mancante resta com'è, lo specchio si pubblica, il tasto si ricalcola. Mai per il tasto,
            // il pedale o il comando: il Play del Direttore abbassa «uscita mancante» (la memoria diventa l'uscita che c'è) e
            // rientra dal coordinatore, più sotto.
            if let recovery {
                if self.recoveryRouteQ(trigger: recovery, stage: "start") == .noRestart {
                    self.publishIsPlayingQ(context: "avvio-niente")
                    DispatchQueue.main.async {
                        self._linkStartEmitInFlight = false
                    }
                    if self._directorSilentInSongQ {
                        self.publishDirectorSilenceQ(context: "avvio-niente")
                    }
                    return
                }
                // A421 · SEGUITO 1 (par. 3.3, punto 3) — con l'interruzione di sistema in corso nessun lavoro sul motore: qui
                // la regola senza eccezione (la `setActive` riuscita della catena ha già abbassato lo stato: uno stato di nuovo
                // alto è un'interruzione cominciata dopo), prima della decisione del Follower, della ricostruzione, del
                // rimandato e di `engine.start()`. Se dice no, anche quello che fa il «niente» di U5 qui sopra.
                if !self.interruptionActivationAllowedQ(point: .start, chainToken: self.currentResumeToken) {
                    self.refuseActivationInInterruptionQ(trigger: recovery, attempt: nil, point: .start)
                    self.publishIsPlayingQ(context: "avvio-niente-interruzione")
                    DispatchQueue.main.async {
                        self._linkStartEmitInFlight = false
                    }
                    if self._directorSilentInSongQ {
                        self.publishDirectorSilenceQ(context: "avvio-niente-interruzione")
                    }
                    return
                }
            } else if self.playerRoleQ == .direttore {
                self.noteOutputStateQ(.directorPlay(externalPresent: self.hasExternalOutputNowQ()), from: "play")
            }

            // A361 (16/09/2026) — LA DECISIONE D'AVVIO DEL FOLLOWER, PRIMA DI TUTTO.
            // Questo è il punto unico di avvio del motore: ogni innesco (Play del
            // Direttore via callback, runner, pedale, ripresa dopo un'interruzione di
            // sistema, cambio di configurazione, risveglio,
            // recupero pendente, schermata di debug) passa di qui, e la regola sta qui —
            // non porta per porta. Il Follower (ruolo E Link acceso dall'utente,
            // `FollowerDecision`) non manda avvio a Link: entra SOLO in una sessione che
            // suona (`joinRunningSession`, il ramo condiviso di sempre), anche se l'innesco
            // portava un beat di ripresa; altrimenti il motore NON parte (`stayStopped`).
            // Da un Follower non escono mai `link_engine_start_at_beat_zero` né
            // `link_engine_start_at_beat`. Chi comanda il trasporto (Direttore, Solo) parte
            // come oggi, ripresa compresa; da A411 il Solo parte senza scrivere niente su Link
            // (lucchetto, `SoloInertDecision`). Tipo puro `FollowerStartDecision` (Models/), col
            // suo banco.
            // ⚠️ A362 — «almeno un collegato» (`link_engine_num_peers`) NON decide: è la spia
            //    dei collegati, che può restare indietro (`TD-link-indicator-stale`); prima di
            //    A361 un Follower con la spia a zero e la sessione che suona entrava comunque
            //    nel ramo condiviso. Si legge solo per la riga di log.
            let startDecision: FollowerStartDecision = {
                var connected = false
                var sessionPlaying = false
                // A411 · SOLO-INERTE — nel Solo niente probe (cattura E commit): i valori sono quelli del
                // ponte spento. Per chi non è Follower l'esito è comunque «comanda il trasporto».
                // A412 — e niente probe col Direttore muto in canzone: il suo avvio passa dal coordinatore,
                // che legge Link senza committare (T11), e l'esito qui non dipende dalla probe.
                if let lh = self.linkEngineHandle, self.soloLockPassesQ(.sessionProbe), !self._directorSilentInSongQ {
                    let probe = link_engine_probe_session(lh, mach_absolute_time(),
                                                          Double(self._beatsPerBarQ))
                    connected = link_engine_num_peers(lh) > 0
                    sessionPlaying = probe.isPlaying
                }
                return FollowerStartDecision(role: self._linkMode,
                                             userLinkEnabled: self._linkUserEnabledQ,
                                             anyPeerConnected: connected,
                                             sessionPlaying: sessionPlaying,
                                             isResume: resumeAtBeat != nil)
            }()
            if startDecision.outcome == .stayStopped {
                os_log("[Q-BEATS][A361] avvio NON eseguito - apparecchio Follower senza sessione che suona - collegato:%{public}@ sessione:%{public}@ ripresa:%{public}@ - motore fermo",
                       log: .default, type: .default,
                       startDecision.anyPeerConnected ? "si" : "no",
                       startDecision.sessionPlaying ? "si" : "no",
                       startDecision.isResume ? "si" : "no")
                DispatchQueue.main.async {
                    // Coerenza del player: mai «playing» a motore spento (dopo un'interruzione
                    // il motore resta a `.playing` finché qualcuno non lo allinea) e mai un
                    // Play del Direttore inghiottito dal gate anti double-emit.
                    self.playbackState = .stopped
                    self._linkStartEmitInFlight = false
                }
                // A421 — par. 2.2 e: lo specchio a ogni uscita di `start()` senza avvio.
                self.publishIsPlayingQ(context: "avvio-follower-fermo")
                return
            }
            if startDecision.outcome == .joinRunningSession {
                os_log("[Q-BEATS][A361] avvio del Follower - entra nella sessione che suona (join) - ripresa:%{public}@ (beat di ripresa ignorato)",
                       log: .default, type: .default, startDecision.isResume ? "si" : "no")
            }
            // Il beat di ripresa e' di chi comanda il trasporto: il Follower entra sempre come
            // partenza fresca (`usesResumeBeat` e' falso per costruzione sul Follower).
            // A412 — e non vale per il rientro del Direttore (lo azzera il coordinatore, più sotto).
            var resumeBeatForStart: Double? = startDecision.usesResumeBeat ? resumeAtBeat : nil

            // === A408 (15/10/2026) — IL RESET DEI SERVIZI AUDIO, AL PRIMO AVVIO DOPO ===
            // Dopo la guardia e dopo l'uscita `stayStopped` del Follower, prima del `do` che
            // contiene `engine.start()`. Sta qui perché questa è la porta unica dell'avvio (A361,
            // qui sopra): console, velo, pedale, Link e riprese passano tutti di qui. Il cartello
            // A361 contava fra gli inneschi anche «reset dei servizi media»: da A408 il reset non
            // avvia più il motore (`handleMediaReset`), il click riparte solo da un avvio, e in A410
            // quell'innesco è uscito dal cartello.
            //  · «servizi persi» (fra la Lost e la Reset): l'avvio è rifiutato e non si ricorda;
            //    niente `engine.start()` su un motore agganciato al server morto;
            //  · «da ricostruire» (dopo la Reset): motore e nodi nuovi, sessione e grafo
            //    (`rebuildAfterMediaResetQ`), poi l'avvio prosegue. Se la sessione non si attiva,
            //    l'avvio finisce come un avvio fallito (il `catch` qui sotto), fermo, e il Play dopo
            //    riprova;
            //  · «normale»: tutto come prima.
            // Tipo puro e banco: `MediaServicesResetDecision` (Models/).
            switch MediaServicesResetDecision.transition(state: self._mediaServicesQ, event: .start).action {
            case .refuseStart:
                os_log("[Q-BEATS][RESET] Play non avviato: servizi audio persi - motore fermo",
                       log: .default, type: .default)
                // A412 — col Direttore muto in canzone la sessione resta com'è (il silenzio, mandato §2.5):
                // niente `.stopped`, e il tasto si ricalcola.
                let silentRefused = self._directorSilentInSongQ
                DispatchQueue.main.async {
                    // Come l'uscita `stayStopped` qui sopra.
                    if !silentRefused { self.playbackState = .stopped }
                    self._linkStartEmitInFlight = false
                }
                if silentRefused { self.publishDirectorSilenceQ(context: "avvio-rifiutato") }
                // A421 — par. 2.2 e: lo specchio a ogni uscita di `start()` senza avvio.
                self.publishIsPlayingQ(context: "avvio-rifiutato")
                return
            case .rebuildThenStart:
                guard self.rebuildAfterMediaResetQ() else {
                    // Come il `catch` qui sotto: l'avvio è fallito prima di `engine.start()`. Il
                    // segno del proprio avvio qui non è alzato: la chiamata è per simmetria. (Fino ad
                    // A411 qui si diceva «lo abbassa lo stopSync della Reset»: da A412 lo stopSync della
                    // Reset gira solo sul Follower.)
                    os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                           log: .default, type: .default)
                    self.lowerOwnTransportStartQ(reason: "catch")
                    // A412 — col Direttore muto in canzone niente `.stopped`, come qui sopra.
                    let silentFailed = self._directorSilentInSongQ
                    DispatchQueue.main.async {
                        if !silentFailed { self.playbackState = .stopped }
                        self._linkStartEmitInFlight = false
                    }
                    if silentFailed { self.publishDirectorSilenceQ(context: "ricostruzione-fallita") }
                    // A421 — par. 2.2 e: lo specchio a ogni uscita di `start()` senza avvio.
                    self.publishIsPlayingQ(context: "ricostruzione-fallita")
                    return
                }
                self._firstStartAfterMediaResetQ = true
                // A421 — fra la Lost e la Reset il cambio di percorso esce a `mediaResetSkipsQ` (par. 2.3 a): una tolta in
                // quella finestra non ha aggiornato «uscita mancante». A421 · SEGUITO 1 (par. 4.3): la rilettura del Follower
                // che stava qui (A.2, solo al primo avvio dopo la ricostruzione) è uscita: la sostituisce la rilettura a ogni
                // avvio del Follower, prima di `applyStartVolumeQ`, più sotto.
            default:
                break
            }

            // === A416 (21/10/2026) — LA FREQUENZA PRIMA DELL'AVVIO (mandato «USCITA-AUDIO-PASSO-1», §2.1) ===
            // Prima di `engine.start()`, e prima del coordinatore (che con la copia fa la finestra del cambio di sezione):
            // la fonte unica si rilegge (`applySampleRateQ`, una riga [FORMATO] a ogni avvio). Se dice una frequenza
            // diversa dalla copia, copia, DSP e campioni del click si portano lì adesso, a motore fermo (`isRunning` è
            // falso: la guardia qui sopra), e il grafo si ricollega coi formati nuovi; poi si parte. Ogni ramo qui sotto
            // riscrive la posizione del DSP dopo (`metronome_reset_for_start`, `metronome_set_beat_position`, il fuoco del
            // rientro e dell'ingresso). ⚠️ RISCRITTO A420 (23/10/2026): qui si diceva «Se il motore di sistema gira ancora
            // (lo `stopSync` lo ferma fuori dalla coda, dopo aver abbassato `isRunning`) si ferma prima di ricollegare.». Da
            // A420 lo `stopSync` ferma lettore e motore sulla coda, nello stesso blocco che abbassa `isRunning`, e la guardia
            // sta in testa a `reconnectGraphQ`, per chiunque ricolleghi (mandato A420, par. 2.1). Se il cambio arriva lo
            // stesso con l'avvio (il 19/10 alle 10:50:59 l'iPad è partito coi nodi a 44100 e l'uscita a 48000), lo prende il
            // cambio di configurazione (`handleEngineConfigChange`).
            // A416 · SEGUITO 2 (21/10/2026) — IL CAMBIO DI PERCORSO RIMANDATO durante un'interruzione, se la fine non l'ha
            // eseguito (non passava dalla ricostruzione del grafo, o non è arrivata): qui, prima della frequenza, una volta
            // (mandato «A416 · SEGUITO 2», §2.2). L'avvio tocca comunque sessione e motore. Oltre alla frequenza, che si
            // rilegge qui sotto, si rileggono modo e instradamento: se il modo è cambiato il grafo si ricollega per il modo
            // nuovo anche a frequenza uguale; poi instradamento e schermo, come nel cambio di percorso di oggi. La regola delle
            // crisi del suo ramo del modo (`crisisOutcomeQ(.mode)`) non si ripete: a un avvio non c'è una crisi da dichiarare,
            // il motore è fermo (`isRunning` falso, la guardia in testa), le regole di A412 non cambiano, e subito dopo
            // `prepareNormalStartQ` (o il coordinatore, per il Direttore muto) azzera causa e Stop voluto.
            let deferredAtStart = InterruptionRouteDecision.runDeferred(at: .start, state: self._interruptionRouteQ)
            self._interruptionRouteQ = deferredAtStart.state
            var deferredMode: AudioMode? = nil
            if let reason = deferredAtStart.reason {
                deferredMode = self.detectAudioMode()
                os_log("[Q-BEATS][ROUTE] rimandato eseguito contesto:%{public}@ motivo:%{public}@",
                       log: .default, type: .default, DeferredRouteRunner.start.rawValue, reason)
            }
            let startFormat = self.applySampleRateQ(context: "avvio")
            let deferredModeChanged = deferredMode.map { $0 != self.audioMode } ?? false
            if startFormat.reconnectsGraph || deferredModeChanged {
                // A420 — la guardia sul motore di sistema che gira ancora, che stava qui, sta in testa a `reconnectGraphQ`,
                // per chiunque ricolleghi (mandato A420, par. 2.1).
                let startMode = deferredMode ?? self.detectAudioMode()
                self.reconnectGraphQ(for: startMode, caller: "avvio")
                self.applyChannelRouting(for: startMode)
                let rateForScreen = self.sampleRate
                DispatchQueue.main.async {
                    self.audioMode = startMode
                    self.sampleRateInfo = rateForScreen
                }
            } else if let mode = deferredMode {
                self.applyChannelRouting(for: mode)
                let rateForScreen = self.sampleRate
                DispatchQueue.main.async {
                    self.audioMode = mode
                    self.sampleRateInfo = rateForScreen
                }
            }

            // === A412 (18/10/2026) — IL COORDINATORE DEL RIENTRO, PRIMA DEL RAMO ===
            // Qui, dopo i rifiuti e la ricostruzione e prima del `do`: il primo punto in cui l'avvio
            // prosegue davvero. Col Direttore muto in canzone OGNI avvio — le ripartenze automatiche
            // (`RecoveryDecision`), il tasto della fascia e il pedale (`directorTransportTapped`), il
            // debug — passa dal coordinatore (`coordinateDirectorRejoinQ`) e MAI dal ramo fresco o dalla
            // ripresa: rientra (il ramo del rientro, più sotto, senza scritture su Link) oppure resta
            // muto e l'avvio si ferma qui (non certo, canzone finita, sessione ferma da altri). Gli altri
            // avvii passano da `prepareNormalStartQ` e proseguono come prima.
            // ⚠️ RISCRITTO A412. Qui c'era il passo 1 (A410): «cosa farebbe il rientro», scritto nel
            // registro e basta, e «da qui in giù start() è identico a oggi»; per il Direttore muto in
            // canzone non è più vero.
            var rejoinTarget: RejoinTarget? = nil
            if self._directorSilentInSongQ {
                switch self.coordinateDirectorRejoinQ(trigger: trigger, resume: resumeAtBeat != nil,
                                                      lateSkipsLeft: DirectorRejoinDecision.maxLateSkips) {
                case .rejoin(let target):
                    rejoinTarget = target
                    resumeBeatForStart = nil
                case .stayMuted:
                    DispatchQueue.main.async {
                        self._linkStartEmitInFlight = false
                    }
                    // A421 — par. 2.2 e: lo specchio a ogni uscita di `start()` senza avvio.
                    self.publishIsPlayingQ(context: "avvio-resta-muto")
                    return
                case .proceedAsToday:
                    self.prepareNormalStartQ(trigger: trigger)
                }
            } else {
                self.prepareNormalStartQ(trigger: trigger)
            }

            // Build #309: rimosso il vecchio DOWNBEAT WAIT (Opzione B) e il
            // parametro skipLinkWait. La distinzione standalone/master-con-peer/
            // follower avviene ora esplicitamente dentro il blocco do { ... }
            // qui sotto via probe atomica + lettura num_peers, secondo il
            // modello a 3 rami (vedi BOX3_V43_07_05_2026.md).

            // A421 — par. 2.2 h: le ore della riga dei tempi dell'avvio, e il ramo preso.
            var engineStartedTicks: UInt64 = 0
            var playedTicks: UInt64 = 0
            var freshHostNow: UInt64? = nil
            // A421 · SEGUITO 1 (par. 5.1) — parte da «nessuno»: l'unico `try` del blocco è `engine.start()`, prima di ogni
            // ramo, e la riga del catch diceva sempre «ramo:fresco»; ogni ramo che arriva alla riga dei tempi scrive il suo nome.
            var startBranch = "nessuno"
            do {
                self.bufferCount      = 0
                self.beatTotal        = 0
                self.beatTickCounter  = 0
                // A421 — i contatori del pezzo 2 ripartono da questo avvio: i battiti zittiti (U9), l'«uno» uscito (par.
                // 2.2 c), i richiami a motore fermo (par. 2.2 a).
                self._lateBeatsMutedQ = 0
                self._muteLateBeatThisBufferQ = false
                self._lastUnoBeatQ = nil
                self._stoppedEngineCallbacksQ = 0
                // L1.a — coerenza con stopSync(): replay safe.
                // Vedi commento in stopSync() per la motivazione di non
                // toccare _sectionTotalBeats e _onSectionEnd.
                self._sectionBeatCounter = 0
                self.clickPlayhead    = -1
                self.accentPlayhead   = -1
                self.subdivPlayhead   = -1
                // A386 · B2c — ogni avvio del motore abbassa l'orologio proprio (la coda di uno
                // stop dopo DA SOLO è finita) e azzera il campione dell'ultimo battito, che conta
                // dal primo buffer di questo avvio. Chi è ancora DA SOLO (ripresa dopo
                // un'interruzione) resta sul proprio orologio per lo stato della macchina.
                self._ownClockUntilStopQ = false
                self._lastBeatSampleQ = 0
                // A410 — i battiti contati per l'àncora ripartono da questo avvio.
                self._lastCountedBeatQ = nil
                self._prevCountedBeatQ = nil
                // A412 — il primo buffer ancorato e i suoi tre buffer appartengono a un rientro solo: li
                // arma il fuoco del rientro, dopo questo avvio. A412 · SEGUITO 2 (2/2) — anche la scorta muta.
                self._anchoredFirstBufferQ = nil
                self._anchoredPreRollLeftQ = 0
                self._rejoinLeadInQ = nil

                // A421 · SEGUITO 1 (par. 4.3, risposta «A» di Mauro del 25/10) — a ogni avvio del Follower che prosegue il
                // percorso si rilegge con la memoria dell'ultima uscita a volume 1 (U5): se era esterna e adesso un'esterna non
                // c'è, «uscita mancante» si alza e l'avvio scrive 0. Fra una canzone e l'altra a click fermo la tolta non alza
                // «uscita mancante» (U5): senza questa rilettura la canzone dopo usciva dall'altoparlante. Una lettura del
                // percorso e uno stato puro: nessuna scrittura della sessione, anche dentro un'interruzione. Il Direttore no:
                // il suo Play sceglie l'uscita che c'è (D2); il Solo non ha «uscita mancante».
                if self.playerRoleQ == .follower {
                    _ = self.refreshOutputMissingQ(from: "avvio-follower")
                }
                // A421 — U3 b: il volume del mixer principale dallo stato puro, sul motore corrente, subito prima di
                // `engine.start()` (anche sul motore nuovo del reset dei servizi): 0 solo per il Follower con l'uscita mancante.
                self.applyStartVolumeQ()
                try self.engine.start()
                engineStartedTicks = mach_absolute_time()
                // A416 · SEGUITO 2 — un avvio riuscito del motore chiude l'interruzione di sistema (mandato §2.1; Apple:
                // `start()` avvia l'hardware audio): se la fine non arriva mai, è il primo Play dopo che la chiude.
                self.noteSystemInterruptionQ(.engineStarted)
                // A421 · SEGUITO 1 (par. 3.5) — un avvio riuscito chiude ogni ripresa in sospeso: la ripresa pendente e
                // l'interruzione giù, il contatore della catena che sale (i tentativi in volo e le reti a 1 s e a 5 s si
                // spengono da soli). Fino al seguito nessun avvio le toglieva, salvo quelli che passano dalla `setActive`
                // riuscita: dopo il Play del batterista a click in moto, un'aggiunta nel modo Pro, una fine d'interruzione
                // tardiva o una rete vecchia ricostruivano o fermavano il motore che girava.
                if InterruptionActivationDecision.startClearsPendingWithLine(pendingResume: self.pendingResume,
                                                                            isAudioInterrupted: self.isAudioInterrupted) {
                    self.clearPendingResumeQ(reason: "avvio-riuscito")
                } else {
                    self.currentResumeToken += 1
                }
                self.playerNode.reset()
                self.playerNode.play()
                playedTicks = mach_absolute_time()
                self.isRunning = true
                // A421 — par. 2.2 e: lo specchio di `isRunning`, dalla coda, a ogni passaggio.
                self.publishIsPlayingQ(context: "avvio")
                // A420 — OGNI PASSAGGIO DI `isRunning` DA FALSO A VERO APRE UNA GENERAZIONE DELLA CATENA (risposta del referee
                // al mandato A420, par. 1): qui, nello stesso blocco, dopo `engine.start()` riuscito; il `catch` non la tocca.
                // L'ingresso del Follower e il rientro del Direttore programmano i loro buffer al fuoco, più tardi: senza questa
                // salita un richiamo della catena di prima, arrivato nell'attesa, avrebbe fatto partire una catena prima del
                // fuoco, e sul Direttore anche l'assert su Link (referto A420, §1).
                self.openBufferChainQ()
                // A408 — la riga del primo avvio riuscito dopo una ricostruzione, una volta.
                if self._firstStartAfterMediaResetQ {
                    self._firstStartAfterMediaResetQ = false
                    os_log("[Q-BEATS][RESET] primo avvio dopo il reset riuscito motore:0x%lx",
                           log: .default, type: .default,
                           Int(bitPattern: Unmanaged.passUnretained(self.engine).toOpaque()))
                }

#if QB_DIAG_SPY
                // SPIA passiva: abilita il ring L1 (seq azzerato → join con beatTick L3)
                // e ri-arma i marker di sezione. Drain/flush solo allo stop (audio fermo).
                if let h = self.metronomeHandle { metronome_set_diag_enabled(h, true) }
                self._spySectionInstanceIdx = 0
                self._spyMarkerPending = true
                os_log("[Q-BEATS][Bug2b-SPY] enabled — start (ring L1 ON, marker pending)",
                       log: .default, type: .default)
#endif

                if let mh = self.midiEngineHandle {
                    let resumeBeat: Double? = resumeBeatForStart

                    midi_engine_sync_clock(mh, 0, mach_absolute_time(), self.sampleRate)

                    if let beat = resumeBeat {
                        // CALCOLO SNAP RELATIVO ALLA FASE DEL PLAY
                        let beatsPerBarD = Double(self._beatsPerBarQ)

                        // 1. Distanza dal beat di inizio del Playback originale
                        let relativePhase = beat - self._startAbsoluteBeat
                        // 2. Snappa alla prossima misura relativa
                        let snappedRelative = ceil(relativePhase / beatsPerBarD) * beatsPerBarD
                        // 3. Torna al beat assoluto del clock di sistema
                        let snappedBeat = self._startAbsoluteBeat + snappedRelative

                        os_log("[Q-BEATS][RESUME] Snap: %.4f -> %.4f (startBeat:%.4f)",
                               log: .default, type: .default, beat, snappedBeat, self._startAbsoluteBeat)

                        midi_engine_set_beat_position(mh, snappedBeat)
                        if let h = self.metronomeHandle {
                            metronome_set_beat_position(h, snappedBeat)
                            os_log("[Q-BEATS][START] -> metronome_set_beat_position(%.6f)",
                                   log: .default, type: .default, snappedBeat)
                        } else {
                            os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                                   log: .default, type: .default)
                        }
                    } else {
                        midi_engine_set_beat_position(mh, 0.0)
                    }
                    if let lh = self.linkEngineHandle {
                        link_engine_set_quantum(lh, Double(self._beatsPerBarQ))
                    }

                    // === Build #309 — Start API semantica (Opzione 2, modello a 3 rami) ===
                    // Branching corretto rispetto a #307: distingue standalone puro
                    // (peers==0) da sessione condivisa (peers>0). Lo standalone è
                    // l'unico caso in cui Q-BEATS può sovrascrivere la timeline Link.
                    if resumeBeatForStart != nil {
                        startBranch = "ripresa"
                        // RESUME: ripartiamo da snappedBeat (calcolato sopra).
                        // Q-BEATS detta la timeline a beat noto. snappedBeat è in
                        // scope sopra dentro l'`if let beat = resumeBeat`,
                        // qui lo ricalcoliamo coerentemente per il branch link.
                        // Bug 2.b ramo X — resume non semina: snap già gestito da
                        // _startAbsoluteBeat. Offset azzerato.
                        self.startBeatOffset = 0
                        let beatsPerBarD = Double(self._beatsPerBarQ)
                        let relativePhase = (resumeBeatForStart ?? 0.0) - self._startAbsoluteBeat
                        let snappedRelative = ceil(relativePhase / beatsPerBarD) * beatsPerBarD
                        let snappedBeatLocal = self._startAbsoluteBeat + snappedRelative
                        self.linkSyncSkipBuffers = 3
                        if let lh = self.linkEngineHandle {
                            // A400 · R1 — IL SEGNO DEL PROPRIO AVVIO si alza subito prima della scrittura
                            // «suona» della ripresa. Dove Link suona già l'eco non arriva — il richiamo
                            // scatta solo ai cambi di «suona» (misura di A399 §13-bis.1), e a una ripresa
                            // Link di norma suona già, perché l'arresto che la precede non gli manda lo
                            // stop — e non arriva a ponte spento: il segno resta alzato, inerte, fino allo
                            // stop. A motore in moto un avvio altrui non fa niente comunque
                            // (`LinkTransportCallbackDecision.mainStep` avvia solo a motore fermo).
                            self._ownTransportStartPendingQ = true
                            // A411 · SOLO-INERTE — nel Solo il segno si alza come a Link spento (inerte fino
                            // allo stop), ma «suona» non esce verso Link.
                            if self.soloLockPassesQ(.startWrite) {
                                link_engine_start_at_beat(lh, mach_absolute_time(), snappedBeatLocal)
                            } else {
                                self.logSoloInertWriteSkippedQ(.startWrite, detail: String(format: "ripresa battito:%.4f", snappedBeatLocal))
                            }
                            // A386 · FASE B2A-BIS (2D) — LA RIPRESA NON È UN PLAY: la fase di avvio
                            // resta quella del Play vero (battito zero, `registerStartPhase`). Sui
                            // Follower la ripresa non fa scattare nessun richiamo (la loro copia dice
                            // già «suona»), quindi tengono la fase del Play originale: il Direttore
                            // deve fare lo stesso, o uno Stop entro una battuta dalla ripresa darebbe
                            // falsa partenza qui (riarma la stessa) e chiusura là (armano la
                            // successiva) — D7-bis vuole la stessa formula sugli stessi numeri.
                            if let phase = self._startPhaseQ {
                                os_log("[Q-BEATS][2D][AVVIO] ripresa - fase di avvio invariata fase:%.6f",
                                       log: .default, type: .default, phase)
                            } else {
                                os_log("[Q-BEATS][2D][AVVIO] ripresa - nessun avvio registrato",
                                       log: .default, type: .default)
                            }
                        }
                        // A420 — la catena comincia: una generazione nuova prima del primo dei tre buffer (mandato A420,
                        // par. 2.2). Cade nello stesso blocco di quella di `isRunning` qui sopra, senza niente in mezzo.
                        self.openBufferChainQ()
                        self.scheduleNextBuffer()
                        self.scheduleNextBuffer()
                        self.scheduleNextBuffer()
                        os_log("[Q-BEATS][LINK][START] resume avviato a beat:%.4f",
                               log: .default, type: .default, snappedBeatLocal)
                        // A400 · R1 — la riga del segno alzato, a buffer accodati.
                        if self.linkEngineHandle != nil {
                            self.logOwnTransportStartRaisedQ(write: "ripresa")
                        }
                    } else if let target = rejoinTarget {
                        startBranch = "rientro"
                        // === A412 — IL RAMO DEL RIENTRO DEL DIRETTORE (mandato §2.2, T3) ===
                        // Il motore è in moto e muto; l'ingresso al bersaglio lo arma `armSharedJoin` col
                        // bersaglio: stessa generazione e stesso annullo dell'ingresso del Follower, nessuna
                        // scrittura su Link (niente battito zero né ripresa, niente «si suona», W1, W4, fase
                        // d'avvio). I buffer, il seme del contatore e la sezione d'arrivo arrivano al fuoco.
                        self.startBeatOffset = 0
                        self.armSharedJoin(retriesLeft: 0, rejoin: target)
                    } else {
                        // FRESH PLAY: probe + num_peers per distinguere i 3 scenari.
                        let hostNow = mach_absolute_time()
                        freshHostNow = hostNow
                        let quantum = Double(self._beatsPerBarQ)
                        var probe = LinkSessionProbe(isPlaying: false,
                                                     phaseAtHost: 0.0,
                                                     tempo: 0.0)
                        var peersCount: UInt32 = 0
                        // RIENTRO-P1 (c) — l'interruttore dell'APP (`enabled_`).
                        // ⚠️ A411 · SOLO-INERTE — fino ad A410 lo spegnevano sia l'utente dal pannello Link sia
                        //    l'app in secondo piano; da A411 lo muove solo la regola d'accensione
                        //    (`applyLinkActivationQ`: levetta, ruolo, sfondo, chiusura). Qui entra come lo vede il
                        //    motore (`SoloInertDecision.engineSeesLinkOn`): nel Solo spento anche col ponte
                        //    acceso, e niente probe (cattura E commit). Così il Solo va sempre nel ramo standalone,
                        //    quello del Solo a Link spento (A364 P1 c). `peersCount` è il contatore del ponte,
                        //    nessuna chiamata a LinkKit: si legge come prima.
                        var linkOn = false
                        if let lh = self.linkEngineHandle {
                            if self.soloLockPassesQ(.sessionProbe) {
                                probe = link_engine_probe_session(lh, hostNow, quantum)
                            }
                            peersCount = link_engine_num_peers(lh)
                            linkOn = SoloInertDecision.engineSeesLinkOn(role: self._linkMode,
                                                                        userLinkEnabled: self._linkUserEnabledQ,
                                                                        linkActive: link_engine_is_enabled(lh))
                        }

                        // A361 — il Follower e' gia' stato deciso in testa a `start()`: se e'
                        // qui, entra nella sessione che suona (join) e basta, qualunque cosa
                        // dica `peersCount` (A362: la spia dei collegati non decide). Il ramo
                        // standalone/Direttore e il ramo condiviso di chi comanda restano
                        // quelli di sempre.
                        // RIENTRO-P1 (c) — la scelta fra i tre rami esce dal tipo puro
                        // `FreshStartBranchDecision` (Models/, col suo banco). La tabella è quella
                        // di sempre — `(peersCount == 0 && !probe.isPlaying) || .direttore` —
                        // con UNA riga in più: A LINK SPENTO SI VA SEMPRE NEL RAMO STANDALONE.
                        // `peersCount` è il contatore C++ `numPeers_`, che quando l'utente spegne
                        // Link dal pannello resta a 1 (collaudo 17/09/2026, giro G7): senza questa
                        // riga un apparecchio che suona da solo passava dal ramo condiviso.
                        let branch = FreshStartBranchDecision(
                            followerJoins: startDecision.outcome == .joinRunningSession,
                            role: self._linkMode,
                            linkEnabled: linkOn,
                            anyPeerConnected: peersCount > 0,
                            sessionPlaying: probe.isPlaying)
                        if branch.linkOffOverridesStalePeers {
                            os_log("[Q-BEATS][RIENTRO-P1] Link spento - ramo standalone (la tabella di sempre avrebbe scelto il ramo condiviso: peers:%u sessione:%d)",
                                   log: .default, type: .default,
                                   peersCount, probe.isPlaying ? 1 : 0)
                        }
                        if branch.outcome == .followerJoin {
                            startBranch = "ingresso-follower"
                            self.armSharedJoin(retriesLeft: AudioEngine.kSharedJoinMaxRearms)
                        } else if branch.outcome == .standaloneOrDirector {
                            startBranch = "fresco"
                            // === STANDALONE PURO o DIRETTORE (sorgente unica autoritativa) ===
                            // Bug 2.b ramo X — sorgente autoritativa parte da bar 1: nessun
                            // offset d'ingresso. Garantisce Director/standalone bit-identici.
                            self.startBeatOffset = 0
                            // Director forza la timeline indipendentemente dallo stato dei
                            // peer: start_at_beat_zero mappa beat 0 a hostNow.
                            // I peer ricevono la nuova timeline via Link e si allineano a
                            // beat 0 — partenza musicalmente corretta dall'inizio del brano.
                            // Fix 1.j 28/05/2026 — pre-fix Director con peer in stop prendeva
                            // ramo SHARED → join → latenza fino a ~1s + avvio a metà battuta.
                            // Edge case (peer già in play): Director forza comunque beat 0,
                            // peer si riallinea. Progettato e ratificato.
                            // (Standalone puro: stesso ramo. Fino ad A410, a Link acceso, scriveva
                            // anche lui la timeline su Link; da A411 dal Solo non esce niente verso
                            // Link: lucchetto qui sotto.)
                            if let h = self.metronomeHandle {
                                metronome_reset_for_start(h, 0.0)
                                // A421 — la copia dell'origine del DSP (U9).
                                self._dspOriginBeatQ = 0
                            }
                            self.linkSyncSkipBuffers = 3
                            if let lh = self.linkEngineHandle {
                                // A400 · R1 — IL SEGNO DEL PROPRIO AVVIO si alza subito prima della
                                // scrittura «suona». Quando Link richiama per questo avvio, il richiamo
                                // consuma il segno invece di far ripartire il motore (`init`, passo di
                                // coda). Dove Link suona già l'eco non arriva — il richiamo scatta solo ai
                                // cambi di «suona» (misura di A399 §13-bis.1) — e non arriva a ponte
                                // spento: il segno resta alzato, inerte, fino allo stop. A motore in moto
                                // un avvio altrui non fa niente comunque
                                // (`LinkTransportCallbackDecision.mainStep` avvia solo a motore fermo).
                                self._ownTransportStartPendingQ = true
                                // A411 · SOLO-INERTE — nel Solo il segno si alza come a Link spento, «suona»
                                // non esce, e la fase d'avvio è quella del ponte spento (`registerStartPhase`).
                                if self.soloLockPassesQ(.startWrite) {
                                    link_engine_start_at_beat_zero(lh, hostNow)
                                } else {
                                    self.logSoloInertWriteSkippedQ(.startWrite, detail: "battito-zero")
                                }
                                self.registerStartPhase(context: "battito-zero")
                            }
                            // A420 — la catena comincia: una generazione nuova prima del primo dei tre buffer (mandato A420,
                            // par. 2.2). Cade nello stesso blocco di quella di `isRunning` qui sopra, senza niente in mezzo.
                            self.openBufferChainQ()
                            self.scheduleNextBuffer()
                            self.scheduleNextBuffer()
                            self.scheduleNextBuffer()
                            os_log("[Q-BEATS][LINK][START] standalone/direttore avviato (mode:%{public}@ peers:%u)",
                                   log: .default, type: .default,
                                   self._linkMode == .direttore ? "direttore" : "standalone",
                                   peersCount)
                            // A400 · R1 — la riga del segno alzato, a buffer accodati.
                            if self.linkEngineHandle != nil {
                                self.logOwnTransportStartRaisedQ(write: "battito-zero")
                            }
                        } else {
                            // === SESSIONE CONDIVISA — solo LinkMode.collaborativa ===
                            // Bug 2.b / Ferita A (10/06/2026): l'ingresso quantizzato è
                            // armato e FINALIZZATO da armSharedJoin — l'attesa viene
                            // ri-validata AL FIRE su stato post-setup/post-rezero e
                            // ri-armata se il target non è più su un confine di barra.
                            // Logica, commenti storici e seed: vedi armSharedJoin.
                            startBranch = "ingresso-condiviso"
                            self.armSharedJoin(retriesLeft: AudioEngine.kSharedJoinMaxRearms)
                        }
                    }

                    if UserDefaults.standard.bool(forKey: "networkMIDIEnabled") {
                        midi_engine_network_enable(mh)
                    } else {
                        midi_engine_network_disable(mh)
                    }
                } else {
                    os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                           log: .default, type: .default)
                }

                // ⚠️ RISCRITTO A420 (23/10/2026) — U14 (mandato A420, par. 2.4). La riga di stato leggeva la sessione: «let sr  =
                // AVAudioSession.sharedInstance().sampleRate» e «let buf = AVAudioSession.sharedInstance().ioBufferDuration *
                // sr». Da A416 la frequenza che si usa è la copia del motore (`applySampleRateQ`): la riga dice quella, il buffer
                // è la durata della sessione in campioni della copia, e se la sessione dice un'altra frequenza lo scrive in coda.
                // Testo della vista di debug («Click: …»).
                let statusSession = AVAudioSession.sharedInstance()
                let sr  = self.sampleRate
                let buf = statusSession.ioBufferDuration * sr
                let sessionNote = SampleRateDecision.same(statusSession.sampleRate, sr)
                    ? "" : " sessione:\(Int(statusSession.sampleRate))"
                let statusStr = "started SR:\(Int(sr)) buf:\(Int(buf)) samples:\(self.clickSamples.count)\(sessionNote)"
                // A421 — `isPlaying = true` non sta più qui: lo specchio l'ha pubblicato la coda subito dopo `isRunning = true`
                // (par. 2.2 e), prima di questo blocco sulla stessa coda principale.
                DispatchQueue.main.async {
                    self.playbackState        = .playing
                    self.clickStatus          = statusStr
                    // Bug 1 (faccia visiva di Bug 2.b, BUGS §1.2) — NON ripubblicare
                    // qui currentAccentPattern da _beatsPerBarQ. Al join cross-device
                    // start() gira col _beatsPerBarQ della sezione PRECEDENTE (stantio)
                    // e questo publish, differito su main.async, atterrava DOPO il
                    // pattern corretto del runner → la striscia segmenti (MetSlotStripView)
                    // disegnava il conteggio vecchio (es. 3 invece di 4), mentre
                    // beatActive — calcolato da displayBpb/$beatsPerBar, che start() NON
                    // tocca — restava a 4: il 4° beat non aveva segmento da accendere.
                    // Il pattern è già pubblicato dalla via autoritativa (setBeatsPerBar
                    // didSet in Studio; runner/sezione + ramo SEAMLESS in Live), quindi
                    // il republish era ridondante oltre che dannoso. Rimosso il vecchio
                    // fix 282e8d8 (03/05, pre-runner/pre-join), oggi superato.
                    // CD-6 / Bug 4 fix (Q-D4 esteso) — Reset gate anti
                    // double-emit linkStartedSubject. Da qui `isPlaying == true`
                    // → il guard `!engine.isPlaying` del callback Link
                    // protegge da double-start senza più bisogno del flag.
                    self._linkStartEmitInFlight = false
                }

                let avSession = AVAudioSession.sharedInstance()
                self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                if let lh = self.linkEngineHandle {
                    link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                }

                // Registra il beat di partenza (solo fresh play, latenza inclusa).
                // Build #309: per il ramo "sessione condivisa" (peers > 0) questo
                // valore verrà sovrascritto al fire del work item (vedi flow sopra),
                // perché il primo sample reale parte a futureHostTime, non a "now".
                // Per standalone resta corretto.
                // A412 — non per il rientro: lo scrive il suo fuoco (il battito di Link del bersaglio).
                if resumeBeatForStart == nil, rejoinTarget == nil, let mh = self.midiEngineHandle {
                    let hostTimeAtFirstSample = mach_absolute_time()
                                                + self.outputLatencyTicks
                                                + self.bufferDurationTicks
                    self._startAbsoluteBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
                }

                // Build #309: rimosso il scheduleNextBuffer × 3 ridondante per il
                // resume (ora è già chiamato esplicitamente dentro il branch RESUME
                // sopra, con la nuova API link_engine_start_at_beat).

                // A421 — par. 2.2 h: la riga dei tempi dell'avvio, una per avvio, nessun cambio di comportamento.
                self.logStartTimingQ(trigger: trigger, branch: startBranch, entry: entryTicks, block: blockStartTicks,
                                     engineStarted: engineStartedTicks, played: playedTicks, hostNow: freshHostNow)
            } catch {
                os_log("[Q-BEATS][START] -> NO METRONOME CALL in this branch",
                       log: .default, type: .default)
                // A421 — par. 2.2 h: l'errore dell'avvio fallito (dominio, codice e quattro lettere), e lo specchio.
                // A421 · SEGUITO 1 (par. 5.1) — e il ramo previsto, da `resumeBeatForStart` e `rejoinTarget`: ripresa, rientro
                // o altro (il fresco e gli ingressi del Follower si decidono dopo `engine.start()`).
                let expectedBranch: String = rejoinTarget != nil ? "rientro" : (resumeBeatForStart != nil ? "ripresa" : "altro")
                os_log("[Q-BEATS][START] avvio fallito innesco:%{public}@ ramo:%{public}@ previsto:%{public}@ errore:%{public}@ coda_ms:%.1f",
                       log: .default, type: .error,
                       trigger, startBranch, expectedBranch, AudioEngine.describeAudioError(error),
                       self.signedMilliseconds(from: entryTicks, to: blockStartTicks))
                self.publishIsPlayingQ(context: "avvio-fallito")
                // A400 · R1 — l'avvio è fallito prima delle tre scritture «suona» (l'unico `try` del
                // blocco è `engine.start()`, e sta sopra di loro): questo avvio il segno non l'ha
                // alzato. Si abbassa lo stesso, per simmetria con gli altri arresti.
                self.lowerOwnTransportStartQ(reason: "catch")
                let errStr = "start fallito: \(error)"
                DispatchQueue.main.async {
                    self.clickStatus = errStr
                    // A400 · R1 — come l'uscita `stayStopped` più sopra: mai un avvio altrui
                    // inghiottito dal gate anti double-emit. Fino a oggi, dopo un avvio fallito, il
                    // lucchetto restava alzato fino al primo avvio riuscito (referto A399 §5.5).
                    self._linkStartEmitInFlight = false
                }
                // A412 — un rientro che non parte: il Direttore resta muto, il tasto si ricalcola.
                if self._directorSilentInSongQ {
                    self.publishDirectorSilenceQ(context: "avvio-fallito")
                }
            }
        }
    }

    func stop() {
        // A410 — uno Stop voluto (tasto, pedale, END SHOW, fine canzone propria, uscita dalla stanza:
        // passano tutti di qui) chiude l'àncora del conteggio in silenzio. Accodato PRIMA del `sync` di
        // `stopSync`, quindi gira prima di lui.
        // ⚠️ RISCRITTO A412. Il testo di prima diceva «Lo `stopSync` della Reset non passa di qui e
        // l'àncora resta. Solo stato di coda: lo Stop resta quello di oggi (passo 2)». Da A412 la Reset non
        // ferma più il Direttore (lo `stopSync` della Reset gira solo sul Follower), e lo Stop voluto col
        // Direttore muto in canzone manda lo Stop a Link e chiude la canzone anche a motore fermo
        // (`stopSync`, origine `.wanted`).
        audioQueue.async { [weak self] in
            self?.closeSilenceAnchorQ(reason: "stop")
        }
        stopSync()
#if QB_DIAG_SPY
        // SPIA passiva: flush finale del ring L1 (audio già fermo da stopSync → no race).
        if let h = metronomeHandle { metronome_flush_diag(h) }
#endif
        // P1+P3 fix: allinea playbackState all'isPlaying su ogni percorso di stop.
        // Pattern già usato in handleStop() (.countIn/.playing) e restartFromBeginning().
        // Senza questo dispatch, lo stop manuale lasciava playbackState=.playing
        // mentre isPlaying=false → desincronizzazione UI (segmento bloccato bianco,
        // TransportView label/glyph fuori sync — TransportView re-render solo su
        // session.playbackState, non su audioEngine.isPlaying).
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    }

    func setBPM(_ bpm: Double) {
        applyBPM(bpm, orchestratedSectionStart: false)
    }

    // RIENTRO-P1 (e) — W1: IL TEMPO DI SEZIONE ALL'AVVIO ORCHESTRATO.
    // Unico chiamante: `SetlistRunner.prepareAndStartCurrentSection` (ogni avvio e ogni
    // ripartenza di sezione guidati dal runner). Fa tutto ciò che fa `setBPM` — DSP, mirror
    // `_audioBPM`, ri-àncora MIDI, `currentBPM` — ma SUL FOLLOWER NON SCRIVE IL TEMPO SU LINK:
    // all'ingresso il Follower prende il tempo della sessione, non lo dà. Fino a oggi lo
    // scriveva a ogni Play del Direttore e a ogni rientro, anche dalla sezione sbagliata
    // (collaudo 17/09/2026, giro G3; referto A364, §3.f e §5.e). Il Direttore scrive come
    // oggi: `FollowerLinkWriteDecision`. Il Solo (e il ruolo Follower o Direttore con la levetta
    // spenta) da A411 non scrive: lo ferma prima il lucchetto (`SoloInertDecision`).
    // ⚠️ `setBPM` qui sopra NON cambia (metronomo di Q-Studio, tap tempo): scrive sempre, salvo nel
    //    Solo da A411 (stesso lucchetto, in `applyBPM`).
    func setSectionBPM(_ bpm: Double) {
        applyBPM(bpm, orchestratedSectionStart: true)
    }

    private func applyBPM(_ bpm: Double, orchestratedSectionStart: Bool) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            // Task D — Annulla cambio BPM schedulato non ancora scattato.
            // setBPM è path immediato: il valore di bpm sostituisce qualunque
            // valore pending. Cancel Layer 1 PRIMA di metronome_setBPM evita
            // che un downbeat appena successivo applichi il valore vecchio
            // (race-free: tutto su audioQueue).
            if self._pendingBPMValue != nil {
                metronome_cancel_pending_bpm(h)
                self._pendingBPMValue = nil
                self._pendingBPMTargetTick = 0
            }
            metronome_setBPM(h, bpm)
            self._audioBPM = bpm
            // A386 · B2c — il tempo in corso è di nuovo quello della propria canzone; una linea
            // propria ancorata col tempo di prima non vale più.
            self._linkTempoAdoptedQ = nil
            self._engineTempoQ = bpm
            self._ownTimelineQ = nil
            if let mh = self.midiEngineHandle {
                // Strada E (Task D fix #2) — re-anchor MIDI engine beat position
                // attraverso il cambio BPM. MIDISequencer::setBPM ricalcola
                // _samplesPerTick ma NON aggiorna _sampleBaseAdj → la posizione
                // tracciata salta proporzionalmente a currentSample (verificato
                // sui log 11/05/2026: beat_proj=22.23 con beatTickCounter=20).
                // Leggi posizione PRIMA del cambio, applica setBPM (che salta),
                // ri-ancora alla stessa posizione col nuovo BPM.
                let preChangeBeatPos = midi_engine_get_beat_position(mh)
                midi_engine_set_bpm(mh, bpm)
                midi_engine_set_beat_position(mh, preChangeBeatPos)
            }
            if let lh = self.linkEngineHandle {
                // RIENTRO-P1 (e) — W1: vedi `setSectionBPM`.
                // A411 · SOLO-INERTE — nel Solo il tempo non esce verso Link, né all'avvio di sezione né da
                // `setBPM` (lucchetto, prima della regola del Follower).
                if !self.soloLockPassesQ(.tempoWrite) {
                    self.logSoloInertWriteSkippedQ(.tempoWrite, detail: String(format: "bpm:%.1f", bpm))
                } else if orchestratedSectionStart && self._directorSilentInSongQ {
                    // A412 — col Direttore muto in canzone W1 non esce: il suo Play passa dal coordinatore, mai
                    // da `runner.startCurrentSection` (mandato §2.4). È una rete per una strada sconosciuta, con
                    // la sua riga: le strade note non arrivano qui.
                    os_log("[Q-BEATS][DIR-RIENTRO] tempo di sezione %.1f NON scritto su Link (W1) - Direttore muto in canzone",
                           log: .default, type: .default, bpm)
                } else if orchestratedSectionStart,
                   !FollowerLinkWriteDecision.writesTempoAtOrchestratedStart(
                        role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ) {
                    os_log("[Q-BEATS][RIENTRO-P1] tempo di sezione %.1f impostato in locale - NON scritto su Link (W1) - apparecchio Follower",
                           log: .default, type: .default, bpm)
                } else {
                    link_engine_set_bpm(lh, bpm)
                }
            }
            DispatchQueue.main.async { self.currentBPM = bpm }
        }
    }

#if DEBUG
    // RIENTRO-P1 (A366) — il comando dell'interruttore solo DEBUG «Follower: tempo al confine
    // (W2)» (`DebugView`). Chiamabile da qualunque thread: il mirror si scrive su main, la
    // copia di coda su audioQueue con un `async` — nessun lock, e niente sul percorso audio
    // oltre alla lettura di un Bool già sulla coda. Cartello completo sulla dichiarazione di
    // `debugFollowerBoundaryTempoWrite`.
    func setDebugFollowerBoundaryTempoWrite(_ enabled: Bool) {
        os_log("[Q-BEATS][RIENTRO-P1] interruttore DEBUG 'Follower: tempo al confine (W2)' -> %{public}@",
               log: .default, type: .default, enabled ? "acceso" : "spento")
        DispatchQueue.main.async { self.debugFollowerBoundaryTempoWrite = enabled }
        audioQueue.async { self._debugFollowerBoundaryTempoWriteQ = enabled }
    }

    // A416 (21/10/2026) — LA PROVA DELLA FREQUENZA (mandato «USCITA-AUDIO-PASSO-1», §2.6, scelta 15 del referee): i due
    // pulsanti solo DEBUG della `DebugView` chiedono al sistema una frequenza d'uscita (la preferita della sessione).
    // Apple (`AVAudioSession.setPreferredSampleRate(_:)`): chiede il cambio, l'effetto si legge in `sampleRate`, e si può
    // chiedere prima o dopo l'attivazione della sessione; la preferita si rilegge in `preferredSampleRate`. Il sistema
    // decide se darla: la riga scrive la chiesta, la preferita riletta, l'ottenuta (la frequenza della sessione subito
    // dopo) e il nodo d'uscita. Niente si conserva: all'avvio `setupSession` chiede 48000. Se l'uscita cambia, il resto lo
    // fanno le strade di sempre (il cambio di configurazione a motore in moto, l'avvio dopo a motore fermo), con le loro
    // righe [FORMATO]. Su audioQueue, come ogni chiamata alla sessione (A406).
    func debugRequestPreferredSampleRate(_ hz: Double) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            let session = AVAudioSession.sharedInstance()
            var errorText = "-"
            do {
                try session.setPreferredSampleRate(hz)
            } catch {
                errorText = AudioEngine.describeAudioError(error)
            }
            os_log("[Q-BEATS][PROVA-FREQUENZA] chiesta:%.0f preferita:%.0f ottenuta:%.0f uscita:%.0f copia:%.0f motore:%{public}@ errore:%{public}@",
                   log: .default, type: .default,
                   hz, session.preferredSampleRate, session.sampleRate, self.outputSampleRateQ(), self.sampleRate,
                   self.isRunning ? "in-moto" : "fermo", errorText)
        }
    }
#endif

    // RIENTRO-P1 (A366) — W2 SI SALTA? Chiamare SOLO su audioQueue, dal ramo del cambio di
    // sezione di `scheduleNextBuffer`, subito prima di `link_engine_set_bpm_and_beat_at_time`.
    // In Release rende SEMPRE falso: W2 resta identica a oggi, per tutti i ruoli.
    // In DEBUG rende vero in UN caso solo: apparecchio Follower (ruolo E Link acceso
    // dall'utente, copie di coda — `FollowerDecision`) E interruttore spento. Direttore e Solo
    // non sono toccati, qualunque cosa dica l'interruttore. E logga l'esito a ogni confine,
    // con ruolo, bpm e stato dell'interruttore: è la riga che la prova A/B deve leggere.
    // ⚠️ MARCATURA A386 · B2c-BIS (01/10/2026) — «In Release rende SEMPRE falso» NON VALE PIÙ.
    //    Decisione di Mauro dell'01/10/2026: da solo il Follower non scrive niente in Link; in
    //    sync resta la decisione 9.1. W2 si salta anche — in ogni configurazione — quando il
    //    Follower è sul proprio orologio: DA SOLO, e la coda prima dell'arresto. La domanda «W2
    //    si salta?» resta UNA e resta QUI, perché questo è già l'unico cancello davanti a
    //    `link_engine_set_bpm_and_beat_at_time`: un secondo cancello accanto avrebbe messo la
    //    stessa decisione in due posti. La regola è pura e testata
    //    (`FollowerLinkWriteDecision.boundaryTempoWrite`), letta dalle stesse copie di coda
    //    della macchina che leggono le due strade d'ingresso (`followsLinkQ`).
    //    L'interruttore solo DEBUG funziona come prima e si combina: sul Follower W2 scrive
    //    solo se lo permettono tutti e due. Fuori da DEBUG l'interruttore non esiste: vale acceso.
    //    La riga [RIENTRO-P1] resta solo in DEBUG, col testo di prima; la sua prima parola
    //    («saltata»/«eseguita») è l'esito VERO, anche quando a saltare è l'orologio proprio. In
    //    quel caso esce in più, in ogni configurazione, la riga [2D][DA-SOLO] qui sotto, col
    //    tempo della sezione nuova, il tempo della sessione letto dall'ultimo battito a 1 s
    //    (nessuna chiamata a Link in più) e lo stato della macchina.
    // ⚠️ A411 · SOLO-INERTE — davanti a W2 il chiamante legge prima il lucchetto del Solo: è un'altra
    //    regola (`SoloInertDecision`, la stessa di ogni strada del Solo), non questa in due posti. Nel Solo
    //    questa funzione non si chiama, e la riga [RIENTRO-P1] non esce.
    private func followerBoundaryTempoWriteSkipped(bpm: Double) -> Bool {
#if DEBUG
        let switchOn = self._debugFollowerBoundaryTempoWriteQ
#else
        let switchOn = true
#endif
        let outcome = FollowerLinkWriteDecision.boundaryTempoWrite(role: self._linkMode,
                                                                   userLinkEnabled: self._linkUserEnabledQ,
                                                                   state: self._followerSyncQ,
                                                                   ownClockUntilStop: self._ownClockUntilStopQ,
                                                                   debugSwitchOn: switchOn)
        let skipped = outcome != .writes
#if DEBUG
        let isFollower = FollowerDecision.isFollower(role: self._linkMode,
                                                     userLinkEnabled: self._linkUserEnabledQ)
        os_log("[Q-BEATS][RIENTRO-P1] W2 %{public}@ - ruolo:%{public}@ follower:%{public}@ bpm:%.1f interruttore:%{public}@",
               log: .default, type: .default,
               skipped ? "saltata" : "eseguita",
               String(describing: self._linkMode),
               isFollower ? "si" : "no",
               bpm,
               switchOn ? "acceso" : "spento")
#endif
        if outcome == .skippedOwnClock {
            os_log("[Q-BEATS][2D][DA-SOLO] tempo di sezione NON scritto su Link (W2) - sezione:%.2f sessione:%.2f stato:%{public}@ battito:%d - da solo il Follower non scrive in Link",
                   log: .default, type: .default,
                   bpm, self._sessionTempoSeenQ, self.describe(self._followerSyncQ), self.beatTickCounter)
        }
        return skipped
    }

    // === L1.a — Caricamento sezione + closure end-of-section ===
    // Chiamabile da qualunque thread. Internamente:
    //   - audioQueue per i 3 mirror privati (_sectionTotalBeats, _sectionBeatCounter, _onSectionEnd)
    //   - main per currentSectionRepetitions @Published (display Vista LIVE)
    // Semantica:
    //   repetitions > 0  → registra closure single-shot, scatterà sull'ultimo beat
    //                       della sezione (totalBeats = repetitions × beatsPerBar)
    //   repetitions <= 0 → nessun limite (loop infinito esplicito -1 o reset 0),
    //                       closure NON registrata, nessun stop automatico
    // Il display Vista LIVE riflette il valore passato (positivo, 0, o -1) — la
    // distinzione 0 vs -1 è preservata per coerenza con SongSection.repetitions.
    func loadSection(beatsPerBar: UInt32,
                     repetitions: Int,
                     onEnd: @escaping () -> Void) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            // A412 — la chiusura di fine sezione resta anche per il rientro del Direttore, che carica la sezione
            // d'arrivo senza passare dal runner (`fireDirectorRejoinQ`).
            self._songSectionEndClosureQ = onEnd
            if repetitions > 0 {
                self._sectionTotalBeats = repetitions * Int(beatsPerBar)
                self._sectionBeatCounter = 0
                self._onSectionEnd = onEnd
            } else {
                self._sectionTotalBeats = 0
                self._sectionBeatCounter = 0
                self._onSectionEnd = nil
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.currentSectionRepetitions = repetitions
        }
    }

    // === ⟦SYNC-ISTANTANEA⟧ A247+A248 (29/08/2026) — Snapshot posizione di sezione ===
    // Consegna su main la terna (posizione dentro la sezione, totale della
    // sezione, tick assoluto), catturata IN UNA SOLA closure su audioQueue:
    // la coda è seriale (:392), quindi la terna è coerente per costruzione —
    // nessun beat può scorrere fra le letture. Catturarle in hop separati
    // sarebbe una corsa.
    //
    // PERCHÉ ESISTE: al rientro nel player la grafica non ha l'ancora di
    // sezione e resta spenta fino al confine (6deea52). Il numero che manca
    // È `_sectionBeatCounter` — l'asse CONTATORE, quello del seeding Follower
    // e dello stop-a-fine-sezione — ma vive su audioQueue e la UI non può
    // leggerlo direttamente. Questo è il ponte, one-shot al montaggio.
    //
    // ⛔ ZERO SUL CONTATORE HA DUE SIGNIFICATI, e per questo si consegna anche
    //    il TOTALE (A248 — collisione trovata da CD, misurata dal referee):
    //    · `sectionTotal == 0` → «nessuna sezione da contare»: LOOP
    //      (l'incremento sta sotto la guardia `_sectionTotalBeats > 0` e
    //      `loadSection` con repetitions <= 0 mette il totale a 0 — decisione
    //      Mauro 29/08: i loop restano ciechi, NON si tocca il cuore audio)
    //      oppure nessuna sezione caricata. Qui zero è davvero non-lo-so.
    //    · `sectionTotal > 0 && sectionBeat == 0` → «sezione partita, primo
    //      beat non ancora arrivato»: lo swap SEAMLESS azzera il contatore
    //      DENTRO il beat che chiude la sezione vecchia, avendo già caricato
    //      il totale nuovo — per un beat intero il contatore vale 0 con
    //      l'audio che suona. Qui la posizione SI CONOSCE: è l'inizio.
    //    · a motore fermo il contatore è comunque 0 (stop azzera) — è il
    //      consumatore a escludere quel caso, con la sua guardia isPlaying.
    //
    // ⛔ NESSUN BLOCCO, NESSUNA ATTESA, su nessun thread: due dispatch
    //    asincroni (audioQueue → main). Non gira sul render thread; aggiunge
    //    alla coda audio una cattura di tre Int, una volta per montaggio del
    //    player — zero lavoro periodico.
    //
    // ⚠️ FORMA NUOVA DICHIARATA: è il primo accessor del file che fa hop e
    //    RENDE un valore — il pattern esistente usa audioQueue.async solo per
    //    scrivere. La forma a closure ricalca `loadSection(onEnd:)` qui sopra.
    func snapshotSectionPosition(_ deliver: @escaping (_ sectionBeat: Int, _ sectionTotal: Int, _ tick: Int) -> Void) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            let sectionBeat  = self._sectionBeatCounter
            let sectionTotal = self._sectionTotalBeats
            let tick         = self.beatTickCounter
            DispatchQueue.main.async { deliver(sectionBeat, sectionTotal, tick) }
        }
    }

    // === Strada A — Pre-load parametri sezione successiva ===
    // Salva i parametri della prossima sezione nei _pendingNext* SENZA
    // toccare la sezione corrente e SENZA chiamare alcuna C-API DSP.
    // Le C-API metronome_schedule_* partono SOLO nel beat callback
    // all'ultimo beat della sezione corrente (ramo SEAMLESS in
    // scheduleNextBuffer).
    //
    // Parametro accentPattern: convenzione UI (2=accent, 1=beat, 0=subdiv),
    // coerente con setAccentPattern. La conversione UI→DSP avviene nello
    // step d del ramo SEAMLESS.
    //
    // Calcolo critico: _pendingNextSectionTotalBeats = repetitions * Int(beatsPerBar)
    // USANDO IL NUOVO beatsPerBar PARAMETRO, MAI _beatsPerBarQ corrente.
    func preloadNextSection(bpm: Double,
                            beatsPerBar: UInt32,
                            accentPattern: [UInt8],
                            subdivisionMultiplier: UInt8,
                            swingRatio: Double,
                            repetitions: Int,
                            onEnd: @escaping () -> Void) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self._pendingNextBPM = bpm
            self._pendingNextBPB = beatsPerBar
            self._pendingNextAccentPattern = accentPattern
            self._pendingNextSectionTotalBeats = repetitions * Int(beatsPerBar)
            self._pendingNextOnSectionEnd = onEnd
            self._songSectionEndClosureQ = onEnd   // A412 — vedi `loadSection`.
            self._pendingNextRepetitions = repetitions
            // ATOM C — la suddivisione della sezione entrante viaggia col
            // preload e si arma al downbeat (step d), come bpm/bpb/accent.
            self._pendingNextSubdivisionMultiplier = subdivisionMultiplier
            self._pendingNextSwingRatio = swingRatio
        }
    }

    /// ⚠️ RISCRITTO A420 (23/10/2026) (risposta del referee al mandato A420, par. 4). Il testo di prima diceva: «Riavvia la
    /// catena di completion handler del playerNode dopo un drain di sezione. Il branch drain fa `return` senza schedulare un
    /// nuovo buffer al playerNode. Le sezioni lunghe (steady-state buffer al minimo) lasciano la coda vuota dopo il drain, e
    /// la catena di completion handler si esaurisce naturalmente. Sezioni brevi sopravvivono per buffer residui del pre-roll
    /// iniziale non ancora consumati. Questo metodo ripristina 3 buffer in coda incondizionatamente, eliminando la
    /// dipendenza dalla fortuna. Pattern identico al pre-roll iniziale (righe 586-588). Chiamare SOLO dal ramo avanza di
    /// SetlistRunner, dopo scheduleBPMChange. Wrappa in audioQueue.async perché il chiamante gira su main thread (closure end
    /// dispatchata da DispatchQueue.main.async).»
    /// Tre cose non reggono più. Nessuno la chiama: il ramo avanza di `SetlistRunner` non la chiama più dal commit `1f0a433`
    /// («Strada A», i cambi di sezione senza drenaggio), e il suo commento lo dice. Le «righe 586-588» non sono più i tre
    /// buffer d'avvio, che stanno nei rami di `start()`. E al drenaggio la catena non si esaurisce: il richiamo che entra nel
    /// drenaggio non programma niente e abbassa `_sectionEndPending`, gli altri buffer in volo, ai loro richiami, programmano
    /// come sempre, e la catena va avanti con un anello in meno finché qualcuno non ferma il motore (alla fine dell'ultima
    /// sezione di una canzone, la chiusura del runner: `audioEngine.stop()`). La funzione resta: è del ticket
    /// `TD-kickscheduling-morto-e-doccomment-falso` (BUGS). Se qualcuno la richiama, i suoi tre buffer sono una catena nuova,
    /// con una generazione nuova prima del primo (mandato A420, par. 2.2).
    func kickScheduling() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            // A420 — una catena nuova: una generazione nuova prima del primo dei tre buffer (mandato A420, par. 2.2).
            self.openBufferChainQ()
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
            self.scheduleNextBuffer()
        }
    }

    func tapTempo() {
        guard let bpm = tapTempoEngine.tap() else { return }
        let rounded = (bpm * 10).rounded() / 10
        setBPM(rounded)
        os_log("Tap tempo: %{public}.1f BPM", log: .default, type: .default, rounded)
    }

    func handleStop() {
        // A386 · FASE B2A (2D) — Q12: sul Follower la stessa guardia del pedale (chiamanti:
        // pedale `.stop` e STOP della schermata di debug, tutti e due su main).
        if followerDecision.isFollower {
            os_log("[Q-BEATS][2D][STOP] handleStop ignorato - apparecchio Follower",
                   log: .default, type: .default)
            return
        }
        // D3: in Direttore ogni porta che ferma passa da `stop()` — niente velo UX-3.
        if DirectorSongCloseDecision.closesSongOnStop(role: currentLinkMode, userLinkEnabled: linkUserEnabled) {
            os_log("[Q-BEATS][2D][STOP] handleStop in Direttore -> stop() (D3, niente velo UX-3)",
                   log: .default, type: .default)
            stop()
            return
        }
        switch playbackState {
        case .playing:
            stopSync()
            let sectionName = currentSection ?? ""
            let songName = currentSong ?? ""
            os_log("[Q-BEATS][UX-3] handleStop: playing → pausedAwaitingChoice section:%{public}@ song:%{public}@",
                   log: .default, type: .default, sectionName, songName)
            DispatchQueue.main.async { [weak self] in
                self?.playbackState = .pausedAwaitingChoice(sectionName: sectionName, songName: songName)
            }
        case .countIn:
            stopSync()
            resetToSongStart()
            os_log("[Q-BEATS][UX-3] handleStop: countIn → stopped",
                   log: .default, type: .default)
            DispatchQueue.main.async { [weak self] in
                self?.playbackState = .stopped
            }
        default:
            break
        }
    }

    func resumeFromCurrentSection() {
        os_log("[Q-BEATS][UX-3] resumeFromCurrentSection → countIn",
               log: .default, type: .default)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .countIn
        }
        startCountIn(for: currentSection)
    }

    func restartFromBeginning() {
        resetToSongStart()
        os_log("[Q-BEATS][UX-3] restartFromBeginning → stopped",
               log: .default, type: .default)
        DispatchQueue.main.async { [weak self] in
            self?.playbackState = .stopped
        }
    }

    // Stub — implementazione in Fase Backtrack
    func restartCurrentSong() { restartFromBeginning() }
    func prevSection() {}
    func nextSection() {}
    func toggleLoop() {}

    func triggerDNDReminderIfNeeded() {
        guard appSettings.showDNDReminder,
              !dndReminderShownThisSession else { return }
        dndReminderShownThisSession = true
        DispatchQueue.main.async {
            self.shouldShowDNDReminder = true
        }
    }

    func dismissDNDReminder(permanent: Bool) {
        DispatchQueue.main.async {
            self.shouldShowDNDReminder = false
            if permanent {
                self.appSettings.showDNDReminder = false
                self.appSettings.save()
            }
        }
    }

    /// A405 — il binding dell'avviso del promemoria (`ContentView`). Su iOS 27 la chiusura dell'avviso arriva nel
    /// binding mentre SwiftUI aggiorna la vista, subito dopo `_didHideAlertController`: scritta nel `@Published` era
    /// una pubblicazione dentro l'aggiornamento («Publishing changes from within view updates is not allowed», quattro
    /// righe a ogni chiusura nei registri del collaudo A403). Qui la chiusura si segna senza pubblicare, l'avviso
    /// risulta subito chiuso, e il `@Published` si abbassa sul main al giro dopo, come in `dismissDNDReminder`.
    /// Quando e dove compare l'avviso non cambia.
    var isDNDReminderPresented: Bool {
        shouldShowDNDReminder && !dndReminderClosing
    }

    func setDNDReminderPresented(_ presented: Bool) {
        guard !presented else { return }
        dndReminderClosing = true
        DispatchQueue.main.async {
            self.shouldShowDNDReminder = false
            self.dndReminderClosing = false
        }
    }

    func setShowDNDReminder(_ value: Bool) {
        appSettings.showDNDReminder = value
        appSettings.save()
    }

    // =====================================================================================
    // === A411 · SOLO-INERTE (18/10/2026) — L'ACCENSIONE DI LINK E IL LUCCHETTO DEL SOLO ===
    // =====================================================================================
    // Mandato del referee «SOLO-INERTE · EMISSIONE 2», §2.2-§2.4 e §2.7. Le regole sono pure e col loro
    // banco in Models/ (`LinkActivationDecision`, `SoloInertDecision`); qui il collegamento.
    // Fino ad A410 Link si accendeva da tre parti: il richiamo del pannello nel C++, `link_engine_activate`
    // all'avvio e `setLinkEnabled` (sfondo, chiusura del pannello, Debug), e con la levetta accesa il
    // telefono entrava in rete anche in Solo. `setLinkEnabled` non c'è più: ogni mano cambia un ingresso e
    // chiama `applyLinkActivationQ`, unica a chiamare `link_engine_set_enabled` e a scrivere `linkEnabled`.

    /// Le mani che cambiano un ingresso dell'accensione, col nome che va nella riga [SOLO-INERTE].
    private enum LinkActivationTrigger: String {
        case boot = "avvio"
        case userSwitch = "levetta"
        case role = "ruolo"
        case background = "sfondo"
        case foreground = "primo-piano"
        case panelClosed = "chiusura-pannello"
        case debugToggle = "debug"
        case appTermination = "chiusura-app"
    }

    /// LA FUNZIONE UNICA DELL'ACCENSIONE. Su audioQueue. La regola (`LinkActivationDecision`) dagli
    /// ingressi di coda; una riga [SOLO-INERTE] a ogni chiamata (le chiamano solo le mani, mai un timer);
    /// se l'esito cambia, o al primo giro, il ponte (`link_engine_set_enabled`: `enabled_` +
    /// `ABLLinkSetActive`) e gli specchi `linkEnabled`, `linkIsConnected`, `linkPeers`, con la rilettura
    /// del collegato a 2 s, come faceva `setLinkEnabled`.
    private func applyLinkActivationQ(trigger: LinkActivationTrigger) {
        guard let lh = linkEngineHandle else { return }
        let decision = LinkActivationDecision(userLinkEnabled: _linkUserEnabledQ,
                                              role: _linkMode,
                                              backgroundSuspended: _linkBackgroundSuspendedQ,
                                              appTerminating: _linkTerminatingQ)
        let previous = _linkActiveAppliedQ
        let changed = previous != decision.active
        // A412 — in coda alla riga l'ingresso nuovo della politica dello sfondo: il Direttore muto in canzone.
        os_log("[Q-BEATS][SOLO-INERTE] accensione mano:%{public}@ levetta:%d ruolo:%{public}@ player:%{public}@ sfondo:%d click:%d chiusura:%d -> attivo:%d prima:%{public}@ cambio:%d motivo:%{public}@ mutoInCanzone:%d",
               log: .default, type: .default,
               trigger.rawValue,
               decision.userLinkEnabled ? 1 : 0,
               decision.role.rawValue,
               decision.playerRole.rawValue,
               decision.backgroundSuspended ? 1 : 0,
               isRunning ? 1 : 0,
               decision.appTerminating ? 1 : 0,
               decision.active ? 1 : 0,
               previous.map { $0 ? "1" : "0" } ?? "mai",
               changed ? 1 : 0,
               decision.offReason?.rawValue ?? "-",
               _directorSilentInSongQ ? 1 : 0)
        guard changed else { return }
        _linkActiveAppliedQ = decision.active
        link_engine_set_enabled(lh, decision.active)
        if decision.active {
            let isConn = link_engine_is_connected(lh)
            DispatchQueue.main.async {
                self.linkEnabled = true
                self.linkIsConnected = isConn
                self.linkPeers = isConn ? 1 : 0
            }
            if !isConn {
                audioQueue.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self = self, let lh = self.linkEngineHandle else { return }
                    guard link_engine_is_enabled(lh) else { return }
                    let isConn2 = link_engine_is_connected(lh)
                    os_log("[Q-BEATS][LINK][SWIFT] check 2s post-enable — isConn:%{public}@",
                           log: .default, type: .default, isConn2 ? "true" : "false")
                    if isConn2 {
                        DispatchQueue.main.async {
                            self.linkIsConnected = true
                            self.linkPeers = 1
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.linkEnabled = false
                self.linkIsConnected = false
                self.linkPeers = 0
            }
        }
    }

    /// La levetta del pannello. Su audioQueue. Scrive la copia di coda e lo specchio e la riga [A360] di
    /// sempre; se si spegne, azzera la macchina del Follower e nasconde il numero dei collegati (A386 B2A,
    /// com'era). Rende `true` se la levetta è cambiata: chi chiama ricalcola allora l'accensione.
    @discardableResult
    private func noteUserLinkSwitchQ(_ isEnabled: Bool, source: String) -> Bool {
        let changed = _linkUserEnabledQ != isEnabled
        _linkUserEnabledQ = isEnabled
        DispatchQueue.main.async { self.linkUserEnabled = isEnabled }
        os_log("[Q-BEATS][A360] Link dell'utente:%{public}@ (%{public}@) - ruolo:%{public}@",
               log: .default, type: .default,
               isEnabled ? "acceso" : "spento", source, String(describing: _linkMode))
        if changed && !isEnabled {
            // A421 — Follower e Direttore diventano il Solo: col motore in moto a volume 0 l'arresto locale come lo
            // Stop, e lo stato dell'uscita giù (mandato A421, par. 2.3 c).
            handleRoleOrLinkChangeQ(reason: "link-utente-spento")
            followerResetQ(reason: "link-utente-spento")
            DispatchQueue.main.async { self.linkPeerCount = nil }
            // A412 — a levetta spenta il ruolo Direttore è un Solo: il silenzio del Direttore e il «segue Link»
            // dopo un rientro finiscono qui.
            leaveDirectorSilenceQ(reason: "link-utente-spento", closeAnchor: true)
            _directorFollowsLinkQ = false
        }
        return changed
    }

    // ⚠️ A412 — `setLinkBackgroundSuspended(_:)` è uscita: la politica dello sfondo si valuta nel motore
    //    (`sceneEnteredBackground`, `sceneBecameActive`, blocco «A412»), perché ha un ingresso nuovo che vive su
    //    audioQueue (il Direttore muto in canzone). La strada resta una: `applyLinkActivationQ`.

    /// La chiusura del pannello Link (`SettingsView`): la levetta riletta dal ponte, se il richiamo del
    /// pannello non l'avesse già portata, e la regola. Fino ad A410 qui Link si accendeva come la levetta,
    /// anche in Solo. Chiamabile da qualunque thread.
    func linkPanelClosed(userEnabled: Bool) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if self._linkUserEnabledQ != userEnabled {
                self.noteUserLinkSwitchQ(userEnabled, source: "chiusura del pannello")
            }
            self.applyLinkActivationQ(trigger: .panelClosed)
        }
    }

    /// Il toggle «Ableton Link» della schermata di debug passa dalla stessa regola: il tocco la ricalcola
    /// e non forza niente. La levetta la muove solo l'utente nel pannello (ABLLink.h:64-69), il ruolo si
    /// sceglie nel menu Mode; il toggle mostra lo specchio, quindi resta dov'era se la regola non cambia.
    /// Chiamabile da qualunque thread.
    func debugLinkToggleTouched(requested: Bool) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            os_log("[Q-BEATS][SOLO-INERTE] toggle Debug 'Ableton Link' toccato - chiesto:%{public}@ - decide la regola",
                   log: .default, type: .default, requested ? "acceso" : "spento")
            self.applyLinkActivationQ(trigger: .debugToggle)
        }
    }

    /// La chiusura dell'app (`AppDelegate.applicationWillTerminate`): l'ingresso «chiusura» e la regola,
    /// nello stesso `audioQueue.sync` di prima.
    func disableLinkOnTerminate() {
        audioQueue.sync {
            _linkTerminatingQ = true
            applyLinkActivationQ(trigger: .appTermination)
        }
    }

    /// Il lucchetto del Solo su una strada (`SoloInertDecision`), dalle copie di coda. Su audioQueue.
    /// `true` = il motore passa da Link come oggi; `false` = Solo, strada chiusa.
    private func soloLockPassesQ(_ path: SoloInertDecision.Path) -> Bool {
        SoloInertDecision.passes(path, role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
    }

    /// Una scrittura verso Link che il lucchetto non lascia uscire: una riga a ogni scrittura saltata (sono
    /// eventi rari: avvio, stop, tempo di sezione). Su audioQueue.
    private func logSoloInertWriteSkippedQ(_ path: SoloInertDecision.Path, detail: String) {
        os_log("[Q-BEATS][SOLO-INERTE] non scritto su Link strada:%{public}@ %{public}@ - ruolo:%{public}@ levetta:%d ponte:%d",
               log: .default, type: .default,
               path.rawValue, detail, _linkMode.rawValue, _linkUserEnabledQ ? 1 : 0,
               linkEngineHandle.map { link_engine_is_enabled($0) ? 1 : 0 } ?? 0)
    }

    /// W2 al confine di sezione: il lucchetto del Solo, con la sua riga. Su audioQueue.
    private func soloInertSkipsBoundaryTempoWriteQ(bpm: Double) -> Bool {
        guard !soloLockPassesQ(.boundaryTempoWrite) else { return false }
        logSoloInertWriteSkippedQ(.boundaryTempoWrite, detail: String(format: "bpm:%.1f", bpm))
        return true
    }

    /// Qualcosa che arriva da Link e il lucchetto scarta (§2.7): una riga a frequenza limitata per strada
    /// (`SoloInertDiscardLog`), col numero degli scarti dall'ultima riga. Su audioQueue.
    private func noteSoloInertDiscardQ(_ path: SoloInertDecision.Path, detail: String) {
        let now = mach_absolute_time()
        let interval = secondsToMachTicks(AudioEngine.kSoloInertLogIntervalSeconds)
        let count: Int?
        switch path {
        case .sessionTempo:
            count = _soloInertTempoLogQ.noteDiscard(now: now, intervalTicks: interval)
        default:
            count = _soloInertTransportLogQ.noteDiscard(now: now, intervalTicks: interval)
        }
        guard let n = count else { return }
        os_log("[Q-BEATS][SOLO-INERTE] scartato da Link strada:%{public}@ %{public}@ scarti:%d - ruolo:%{public}@ levetta:%d ponte:%d",
               log: .default, type: .default,
               path.rawValue, detail, n, _linkMode.rawValue, _linkUserEnabledQ ? 1 : 0,
               linkEngineHandle.map { link_engine_is_enabled($0) ? 1 : 0 } ?? 0)
    }

    func enableNetworkMIDI() {
        UserDefaults.standard.set(true, forKey: "networkMIDIEnabled")
        audioQueue.async { [weak self] in
            guard let self = self, let h = self.midiEngineHandle else { return }
            midi_engine_network_enable(h)
        }
    }

    func disableNetworkMIDI() {
        UserDefaults.standard.set(false, forKey: "networkMIDIEnabled")
        audioQueue.async { [weak self] in
            guard let self = self, let h = self.midiEngineHandle else { return }
            midi_engine_network_disable(h)
        }
    }

    // Wrapper thin per callsite non-UI. Tutta la logica DSP vive nel didSet
    // della @Published beatsPerBar (tech debt #14 — V53).
    func setBeatsPerBar(_ bpb: UInt32) {
        self.beatsPerBar = bpb
    }

    func setAccentPattern(_ pattern: [UInt8]) {
        guard let h = metronomeHandle else { return }
        // L1.b — `pattern` arriva in convenzione UI/SongSection:
        //   0 = subdiv, 1 = beat normale, 2 = accent.
        // Display @Published `currentAccentPattern` usa stessa convenzione
        // UI (MetSlotStripView mappa 2→accent, 1→beat, 0→subdiv) — passa
        // pattern RAW, senza mapping.
        DispatchQueue.main.async { self.currentAccentPattern = pattern }
        // DSP C++ usa convenzione propria: 1 = accent, 0 = beat normale.
        // Converti UI → DSP prima di passare a metronome_setAccentPattern.
        // Coerente con setBeatsPerBar didSet che alimenta il DSP con
        // l'output RAW di defaultAccentPattern (già in convenzione DSP).
        let dspPattern: [UInt8] = pattern.map { $0 == 2 ? 1 : 0 }
        audioQueue.async { [h, dspPattern] in
            dspPattern.withUnsafeBufferPointer { ptr in
                metronome_setAccentPattern(h, ptr.baseAddress, UInt32(dspPattern.count))
            }
        }
    }

    func setSubdivision(multiplier: UInt8, swingRatio: Double = 0.5) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_setSubdivision(h, multiplier, swingRatio)
        }
    }

    func scheduleBPMChange(_ newBPM: Double, atNextBeat: Bool = false) {
        guard let h = metronomeHandle else { return }
        audioQueue.async {
            metronome_schedule_bpm_change(h, newBPM)
            // === Step 3 (rev.2) — disabilita DIRECTOR-ASSERT durante transizione tempo ===
            // linkSyncSkipBuffers settato QUI (audioQueue.async, FIFO prima di
            // kickScheduling nel ramo avanza SetlistRunner) anzichè nel beat callback
            // target tick. Motivo: i 3 buffer di kickScheduling girano su audioQueue
            // PRIMA che il beat target sia processato. Senza skip pre-armato,
            // link_engine_assert_session_state scatta con il vecchio BPM durante i
            // kick buffer (osservato a 19:21:17 sul commit d29c4b7: DIRECTOR-ASSERT
            // bpm:100.00 PRIMA del broadcast TaskD-AQ a bpm:130.0). 100 buffer ~1s
            // coprono sia la finestra pre-broadcast (kick buffer con vecchio BPM)
            // sia la finestra post-broadcast (downbeat applicato + margine residuo
            // convergenza fase). max() evita di ridurre uno skip già più lungo se
            // due cambi BPM si sovrappongono.
            self.linkSyncSkipBuffers = max(self.linkSyncSkipBuffers, 100)
            // Task D — calcola il tick del prossimo downbeat in scala
            // beatTickCounter (1-based: tick=1 è il primo downbeat al play,
            // poi tick=1+beatsPerBar, 1+2*beatsPerBar, ...).
            // Formula: downbeat sse (tick-1) % beatsPerBar == 0.
            // Caso beatTickCounter == 0 (pre-play): target=1, scatterà al play.
            // Altrimenti: primo downbeat strettamente > beatTickCounter.
            //
            // L1.b Opzione A — atNextBeat:true bypassa la formula bpb-dipendente.
            // Usato dal ramo avanza di SetlistRunner: a fine sezione, il prossimo
            // beat coincide col primo beat (= primo downbeat) della nuova sezione,
            // indipendentemente da cambi di time signature. Evita il bug noto
            // della formula quando _beatsPerBarQ è già stato aggiornato al nuovo
            // bpb da setBeatsPerBar prima della chiamata.
            let bpb = Int(self._beatsPerBarQ)
            let target: Int
            if atNextBeat {
                target = self.beatTickCounter + 1
            } else if self.beatTickCounter == 0 {
                target = 1
            } else {
                target = ((self.beatTickCounter - 1) / bpb + 1) * bpb + 1
            }
            self._pendingBPMValue = newBPM
            self._pendingBPMTargetTick = target
            os_log("[Q-BEATS][TaskD] scheduleBPMChange %.1f BPM — target tick:%d (current:%d, bpb:%d, atNextBeat:%d)",
                   log: .default, type: .default,
                   newBPM, target, self.beatTickCounter, bpb, atNextBeat ? 1 : 0)
        }
    }

    func setChannelVolume(_ channel: Int, volume: Float) {
        guard (1...4).contains(channel) else { return }
        let v = max(0.0, min(1.0, volume))
        audioQueue.async { [weak self] in
            guard let self else { return }
            switch channel {
            case 1:
                self.ch1Volume = v
                self.ch1MixerNode.outputVolume = v
            case 2:
                self.ch2Volume = v
                self.ch2MixerNode.outputVolume = v
            case 3:
                self.ch3Volume = v
                self.ch3MixerNode.outputVolume = v
            case 4:
                self.ch4Volume = v
                self.ch4MixerNode.outputVolume = v
            default: break
            }
            let vols = [self.ch1Volume, self.ch2Volume, self.ch3Volume, self.ch4Volume]
            let v1 = self.ch1Volume
            let v2 = self.ch2Volume
            let v3 = self.ch3Volume
            let v4 = self.ch4Volume
            DispatchQueue.main.async {
                self.channelVolumes = vols
                self.appSettings.updateChannelVolumes(ch1: v1, ch2: v2, ch3: v3, ch4: v4)
            }
        }
    }

    func armBacktrack(url: URL) {
        audioQueue.async { [weak self] in
            guard let self else { return }
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                ) else {
                    os_log("[Q-BEATS][BACKTRACK] armBacktrack: buffer alloc fallito",
                           log: .default, type: .error)
                    return
                }
                try file.read(into: buffer)
                self.backtrackBuffer = buffer
                self.backtrackArmed  = true
                os_log("[Q-BEATS][BACKTRACK] armed — frames:%d SR:%.0f",
                       log: .default, type: .default,
                       buffer.frameLength,
                       file.processingFormat.sampleRate)
            } catch {
                self.backtrackBuffer = nil
                self.backtrackArmed  = false
                os_log("[Q-BEATS][BACKTRACK] armBacktrack error: %{public}@",
                       log: .default, type: .error,
                       error.localizedDescription)
            }
        }
    }

    func playBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            // A408 — fuori da «normale» il lettore della base è del motore vecchio: niente avvio.
            if self.mediaResetSkipsQ("play della base") { return }
            guard self.backtrackArmed, let buffer = self.backtrackBuffer else {
                os_log("[Q-BEATS][BACKTRACK] playBacktrack: non armato — noop",
                       log: .default, type: .default)
                return
            }
            self.backtrackPlayerNode.stop()
            self.backtrackPlayerNode.scheduleBuffer(buffer, at: nil, options: []) {
                os_log("[Q-BEATS][BACKTRACK] playback completato",
                       log: .default, type: .default)
            }
            self.backtrackPlayerNode.play()
            os_log("[Q-BEATS][BACKTRACK] play avviato",
                   log: .default, type: .default)
        }
    }

    func stopBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.backtrackPlayerNode.stop()
            os_log("[Q-BEATS][BACKTRACK] stop emergenza",
                   log: .default, type: .default)
        }
    }

    func disarmBacktrack() {
        audioQueue.async { [weak self] in
            guard let self else { return }
            self.backtrackPlayerNode.stop()
            self.backtrackBuffer = nil
            self.backtrackArmed  = false
            os_log("[Q-BEATS][BACKTRACK] disarmato",
                   log: .default, type: .default)
        }
    }

    private func defaultAccentPattern(for beatsPerBar: UInt32) -> [UInt8] {
        switch beatsPerBar {
        case 2:  return [1,0]
        case 3:  return [1,0,0]
        case 4:  return [1,0,0,0]
        case 5:  return [1,0,0,1,0]
        case 6:  return [1,0,0,1,0,0]
        case 7:  return [1,0,0,1,0,1,0]
        case 12: return [1,0,0,1,0,0,1,0,0,1,0,0]
        default:
            var p = [UInt8](repeating: 0, count: Int(beatsPerBar))
            if !p.isEmpty { p[0] = 1 }
            return p
        }
    }

    // MARK: - Private

    // L3 stub — sostituito da Layer 3 quando disponibile.
    private func startCountIn(for section: String?) {
        start()
    }

    // L3 stub — sostituito da Layer 3 quando disponibile.
    private func resetToSongStart() {}

    // Chiamare SOLO su audioQueue.
    private func handleMIDIInput(_ bytes: [UInt8]) {
        guard bytes.count >= 2 else { return }
        let status  = bytes[0] & 0xF0
        let channel = (bytes[0] & 0x0F) + 1  // 1-based
        let number  = bytes[1]

        let eventType: MIDIEventType
        switch status {
        case 0xB0:
            eventType = .cc
        case 0x90:
            guard bytes.count >= 3, bytes[2] > 0 else { return }  // filtra Note Off (velocity=0)
            eventType = .note
        default:
            return  // ignora SysEx, PitchBend, AfterTouch, ecc.
        }

        DispatchQueue.main.async {
            if let pendingAction = self.midiLearnPendingAction {
                let mapping = MIDILearnMapping(channel: channel, type: eventType, number: number)
                self.midiLearnStore.setMapping(mapping, for: pendingAction)
                self.midiLearnPendingAction = nil
                os_log("[Q-BEATS][MIDI LEARN] Mappato %{public}@ → type:%{public}@ ch:%d num:%d",
                       log: .default, type: .default,
                       pendingAction.rawValue, eventType.rawValue,
                       channel, number)
                self.addLog("LEARN OK: \(pendingAction.rawValue) → \(eventType.rawValue) ch:\(channel) num:\(number)")
                return
            }
            if let action = self.midiLearnStore.action(for: eventType, channel: channel, number: number) {
                self.executeMIDIAction(action)
                self.addLog("MIDI ACTION: \(action.rawValue)")
            }
        }
    }

    // Chiamare SOLO su main thread.
    private func executeMIDIAction(_ action: MIDIAction) {
        // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — IL LAMPO: «questa azione agisce?» ===
        // Decide `MIDILampDecision` (Models/, col suo banco) sugli specchi di main: il ruolo del
        // player (`PlayerRoleDecision`, composta da `FollowerDecision` e `DirectorSongCloseDecision`),
        // il trasporto in moto (`playbackState` `.playing` o `.countIn`: la condizione di
        // `handleStop`) e la base che suona. La base nel player non parte (A387 §2.2): solo la
        // schermata di debug la fa suonare (`DebugView`, `playBacktrack`). Decisione di Mauro del
        // 05/10/2026: Stop Backtrack spento, come dopo lo Stop, finché la base non arriva nel player;
        // quindi l'ingresso è falso, con l'eccezione del debug dichiarata qui. Il comportamento delle
        // azioni qui sotto NON cambia: si aggiunge solo il segnale, mandato dove l'azione agisce.
        let lampRole = PlayerRoleDecision.playerRole(role: currentLinkMode, userLinkEnabled: linkUserEnabled)
        let lampMoving = transportInMotion
        let lampFires = MIDILampDecision.fires(action: action,
                                               role: lampRole,
                                               transportInMotion: lampMoving,
                                               backtrackPlaying: false)
        os_log("[Q-BEATS][SOLO-M1][LAMPO] azione:%{public}@ ruolo:%{public}@ in-moto:%d lampo:%d",
               log: .default, type: .default,
               action.rawValue, lampRole.rawValue, lampMoving ? 1 : 0, lampFires ? 1 : 0)
        // A360 (16/09/2026) — SUL FOLLOWER IL PEDALE NON AVVIA, NON FERMA E NON SPOSTA LO
        // SHOW, e non ferma la base (KILL BASE, se assegnato). Resta il muto.
        // A361 — anche il tap tempo non fa niente: `tapTempo()` → `setBPM` →
        // `link_engine_set_bpm`, cioe' un tempo che dal Follower uscirebbe verso Link.
        // Stessa regola della fascia e del velo (`followerDecision`); Direttore e Solo non
        // cambiano in niente. Elenco per azione nel referto A361.
        if followerDecision.isFollower {
            switch action {
            case .playPause, .stop, .nextSection, .prevSection, .nextSong, .startSong,
                 .loopToggle, .stopBacktrack, .tapTempo:
                os_log("[Q-BEATS][A360] pedale MIDI %{public}@ ignorato - apparecchio Follower",
                       log: .default, type: .default, action.rawValue)
                return
            case .muteClickToggle:
                break
            }
        }
        // SOLO-G1-PEZZO-1-M1 · A394 — il lampo, dove l'azione agisce (già su main).
        if lampFires {
            midiActionLampSubject.send(action)
        }
        switch action {
        case .playPause:
            // A412 — col Direttore muto in canzone il pedale segue la regola del tasto della fascia (mandato §2.4):
            // Play = rientra, Stop = ferma la band e chiude la canzone (`directorSilence`, deciso dal motore). Fuori
            // dal silenzio com'è oggi. Il pedale stop resta sempre Stop (`handleStop` → `stop()` sul Direttore).
            if let silence = directorSilence {
                directorTransportTapped(silence.tap, origin: "pedale")
            } else if isPlaying { stop() } else { start() }
        case .stop:
            handleStop()
        case .muteClickToggle:
            appSettings.clickMuted.toggle()
        case .stopBacktrack:
            stopBacktrack()
        case .tapTempo:
            tapTempo()
        case .nextSection, .prevSection, .nextSong, .startSong, .loopToggle:
            os_log("[Q-BEATS][MIDI ACTION] %{public}@ — richiede Layer 3",
                   log: .default, type: .default, action.rawValue)
        }
    }

    // SOLO-G1-PEZZO-1-M1 · A394 — il trasporto è in moto: suona o conta. È la condizione sotto cui
    // `handleStop` agisce (`.playing`, `.countIn`); solo main (legge lo specchio `playbackState`).
    private var transportInMotion: Bool {
        switch playbackState {
        case .playing, .countIn:
            return true
        case .stopped, .pausedAwaitingChoice:
            return false
        }
    }

    // === SOLO-G1-PEZZO-1-M1 · A394 (05/10/2026) — IL MONITOR DEL WI-FI ===
    // Apple, `NWPathMonitor.start(queue:)`: «Starts monitoring path changes, and sets a queue on
    // which to deliver path events.» La coda è `wifiQueue`, seriale e privata; da lì solo
    // `main.async`. Una riga di log alla prima consegna e a ogni cambio.
    private func startWifiMonitor() {
        wifiMonitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let status = String(describing: path.status)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let changed = self.wifiConnected != connected
                if changed { self.wifiConnected = connected }
                if changed || !self.wifiReported {
                    self.wifiReported = true
                    os_log("[Q-BEATS][SOLO-M1][WIFI] collegato:%d (stato:%{public}@)",
                           log: .default, type: .default,
                           connected ? 1 : 0, status)
                }
            }
        }
        wifiMonitor.start(queue: wifiQueue)
    }

    // NON chiamare dall'interno di audioQueue (deadlock).
    // A412 — `origin`: chi ferma (`StopOrigin`). Uno Stop voluto (ogni porta che passa da `stop()` e `handleStop`)
    // chiude il silenzio del Direttore e ferma le ripartenze automatiche; l'arresto del Solo a una crisi e quello
    // del Follower alla Reset dopo la Lost no.
    private func stopSync(origin: StopOrigin = .wanted) {
        var wasRunning = false
        var bc = 0
        var bt = 0
        var directorStopped = false
        var directorFalseStart = false
        var silenceCleared = false
        // ⚠️ RISCRITTO A420 (23/10/2026). Qui c'era «A408 — `playerNode` ed `engine` si scrivono su audioQueue (la
        // ricostruzione dopo il reset dei servizi audio): qui fuori si fermano le copie prese dentro il `sync`.», con le due
        // copie, fermate dopo il `sync`, sul principale. Da A420 lettore e motore si fermano sulla coda, in fondo al `sync`
        // (mandato A420, par. 2.1): niente copie.
        audioQueue.sync {
            // A400 · R1 — ogni arresto abbassa il segno del proprio avvio, se l'eco non l'ha già
            // consumato. In testa al blocco, prima del `guard` più sotto: vale anche a motore già
            // fermo.
            self.lowerOwnTransportStartQ(reason: "stop")
            // A421 — ogni Stop annulla i ritorni in attesa (par. 2.3 b); lo Stop voluto del Direttore abbassa «uscita
            // mancante» (U5; per il Follower lo stato resta: risposta 3 di Mauro del 23/10).
            self.cancelOutputReturnsQ(reason: origin == .wanted ? "stop" : (origin == .soloCrisis ? "crisi-solo" : "reset-follower"))
            if origin == .wanted {
                self.noteOutputStateQ(.directorStop, from: "stop")
            }
            // A386 · FASE B2A — Q18: uno stop durante un'interruzione CHIUDE la ripresa
            // pendente, su tutti e due i ruoli: lo show è andato avanti (Stop del Direttore,
            // END SHOW, uscita dalla stanza) o il musicista ha fermato, e alla fine
            // dell'interruzione il click non deve ripartire da solo. Si azzera lo stato
            // dell'interruzione e si alza il token, così i tentativi di ripresa già in volo si
            // scartano da soli (`activateSessionAndStart`, «Zombie retry ucciso»); `.ended`
            // troverà «nessuna interruzione attiva, noop».
            if self.isAudioInterrupted {
                self.isAudioInterrupted = false
                self.pendingResume = false
                self.pendingResumeBeat = nil
                self.currentResumeToken += 1
                os_log("[Q-BEATS][2D][STOP] stop durante un'interruzione - ripresa pendente CHIUSA - token:%d",
                       log: .default, type: .default, self.currentResumeToken)
            }
            // A386 · B2c — ogni arresto abbassa l'orologio proprio: da qui il motore è fermo (o lo
            // era già), e a motore fermo il Follower FUORI segue Link come sempre
            // (`FollowerLinkFollowDecision`). Prima del `guard` qui sotto: vale anche se il motore
            // era già fermo. Con lui finisce la linea propria.
            self._ownTimelineQ = nil
            if self._ownClockUntilStopQ {
                self._ownClockUntilStopQ = false
                os_log("[Q-BEATS][2D][DA-SOLO] orologio proprio FINITO - arresto del motore - stato:%{public}@ battito:%d buffer:%d",
                       log: .default, type: .default,
                       self.describe(self._followerSyncQ), self.beatTickCounter, self.bufferCount)
            }
            pendingLinkStart?.cancel()
            pendingLinkStart = nil
            // A412 · SEGUITO 3 — col work item si ferma il timer del rientro del Direttore.
            self._rejoinArmTimerQ.cancel()
            self._rejoinArmedQ = false
            if isWaitingForLinkDownbeat {
                DispatchQueue.main.async {
                    self.isWaitingForLinkDownbeat = false
                }
            }
            // === A412 (18/10/2026) — LO STOP VOLUTO CHIUDE IL SILENZIO DEL DIRETTORE (mandato §2.4, D3) ===
            // Ogni arresto chiude «canzone in corso». Uno Stop voluto, in più: niente ripartenze automatiche
            // dopo (`RecoveryDecision`), via lo Stop di fine canzone armato, e col Direttore muto in canzone il
            // silenzio si chiude. Se il suo motore è già fermo (il `guard` qui sotto uscirebbe) lo Stop alla
            // band esce QUI, con la stessa scrittura del ramo di sempre, e la stanza chiude la canzone
            // (`directorStoppedSubject`, D7-bis sugli stessi numeri). Il tasto torna com'è oggi DOPO quell'avviso
            // (`silenceCleared`, più sotto): così la stanza vede ancora il silenzio quando decide.
            self._songInProgressQ = false
            var silentDirectorStop = false
            if origin == .wanted {
                self._wantedStopSinceCrisisQ = true
                self._songEndStopWorkQ?.cancel()
                self._songEndStopWorkQ = nil
                self._songEndStopPlannedTicksQ = nil
                // A412 · SEGUITO 3 — col work item si ferma il timer dello Stop di fine canzone.
                self._songEndStopTimerQ.cancel()
                if self._directorSilentInSongQ {
                    silentDirectorStop = !self.isRunning
                    self._directorSilentInSongQ = false
                    self._directorSilencePublishedQ = nil
                    silenceCleared = true
                    self.closeSilenceAnchorQ(reason: "stop")
                    os_log("[Q-BEATS][CRISI] Stop voluto col Direttore muto in canzone motore:%{public}@ - Stop a Link, la stanza chiude la canzone",
                           log: .default, type: .default, self.isRunning ? "in-moto" : "fermo")
                }
            }
            if silentDirectorStop, let lh = self.linkEngineHandle {
                link_engine_stop(lh, mach_absolute_time())
                let snap = link_engine_read_transport_snapshot(lh)
                directorStopped = true
                if snap.linkEnabled {
                    directorFalseStart = self.falseStartAgainstRegisteredStart(stopPhase: snap.phaseAtStampQBig,
                                                                                context: "stop-direttore-muto")
                } else {
                    os_log("[Q-BEATS][2D][STOP] contesto:stop-direttore-muto ponte spento - falsaPartenza:0",
                           log: .default, type: .default)
                }
                self._startPhaseQ = nil
            }
            wasRunning = self.isRunning
            // ⚠️ RISCRITTO A421 (24/10/2026). Qui c'era «guard self.isRunning else { return }»: a motore già fermo lo Stop
            // voluto saltava la pulizia (contatori, cambi armati, `_pendingNext*`, drenaggio, base) e `isPlaying` restava com'era
            // (il ticket `TD-isplaying-resta-vero-dopo-lo-stop-del-direttore-muto`). Da A421 (mandato, par. 2.2 e) la pulizia
            // gira anche a motore fermo (`cleanupAfterStopQ`, in fondo) e lo specchio si pubblica sempre; restano sotto la
            // guardia, cioè solo col motore in moto, `isRunning = false`, lo Stop a Link di chi suonava, l'arresto di lettore e
            // motore e la riga «stopped». (Il Direttore muto ha il suo Stop a Link qui sopra, prima della guardia.)
            if self.isRunning {
                self.isRunning = false
                bc = self.bufferCount
                bt = self.beatTotal

                // Build #309: notifica Link che la riproduzione è ferma — API semantica.
                // A360 (16/09/2026) — IL FOLLOWER NON MANDA STOP A LINK, DA NESSUNA PORTA.
                // Questa è l'UNICA riga da cui uno stop esce dall'apparecchio (mappa A360 §3):
                // ogni `stop()`, `handleStop()`, fine canzone, fine scaletta, END SHOW, uscita
                // dalla stanza e pedale MIDI passano di qui. La regola sta QUI e non tasto per
                // tasto, così una porta aggiunta domani non la riapre. Il Follower continua a
                // RICEVERE lo stop del Direttore (callback di `link_engine_set_start_stop_callback`
                // in `init`, ramo `!isPlaying && engine.isPlaying`) e a fermarsi in locale; il
                // Direttore continua a ignorare quelli dei peer (stesso callback, guardia
                // `engine._linkMode == .direttore`). Ratifiche: LIBRO
                // `2026-09-09/11` «IL TRASPORTO È DEL DIRETTORE» · `2026-09-11` «CRITERIO
                // GENERALE DEL PERIMETRO DEL FOLLOWER»; ticket `TD-follower-stop-propaga`.
                // Regola nuda su copie di coda: ruolo E Link acceso dall'utente
                // (`FollowerDecision`). Il ponte (`link_engine_stop`) non si tocca.
                // ⚠️ A412 (18/10/2026) — «L'UNICA riga da cui uno stop esce» NON VALE PIÙ alla lettera: le righe
                //    `link_engine_stop` sono tre, tutte del Direttore e nessuna del Follower né del Solo. Questa; lo
                //    Stop voluto col Direttore muto in canzone a motore fermo, qui sopra prima del `guard` (stesso
                //    `stopSync`, stesse porte); lo Stop di fine canzone durante il silenzio
                //    (`fireDirectorSongEndStopQ`, mandato §2.3, D1: lo manda il telefono del Direttore, solo col conto
                //    certo). La regola del Follower resta vera per tutte e tre.
                if let lh = linkEngineHandle {
                    if FollowerDecision.isFollower(role: self._linkMode, userLinkEnabled: self._linkUserEnabledQ) {
                        os_log("[Q-BEATS][A360] stop NON inviato a Link - apparecchio Follower (ruolo:collaborativa linkUtente:acceso) - il motore si ferma solo in locale",
                               log: .default, type: .default)
                    } else if !self.soloLockPassesQ(.stopWrite) {
                        // A411 · SOLO-INERTE — il Solo non manda lo Stop a Link: il motore si ferma in locale.
                        // Prima di A411 lo Stop del Solo con Link acceso fermava gli altri apparecchi.
                        self.logSoloInertWriteSkippedQ(.stopWrite, detail: "stopSync")
                    } else {
                        link_engine_stop(lh, mach_absolute_time())
                        // A410 segnava qui lo Stop mandato a Link con l'àncora viva (lo `stopSync` della Reset,
                        // `TD-media-reset-del-direttore-ferma-la-band`). ⚠️ A412: la Reset non passa più di qui sul
                        // Direttore e uno Stop voluto chiude l'àncora prima di arrivare qui; la marca è uscita
                        // con `SilenceAnchor.ownStopSent`.
                        // A386 · FASE B2A — D3/D7-bis: il Direttore ha fermato a canzone in corso. La
                        // falsa partenza si decide con la STESSA formula e sugli STESSI numeri di Link
                        // che usano i Follower: fase di sessione dell'avvio registrata al proprio
                        // Play (`registerStartPhase`), fase dello stop dalla cattura DOPO il proprio
                        // stop, differenza a giro simmetrico, margine = una battuta della prima
                        // sezione. Cosa fare del runner lo decide la stanza
                        // (`DirectorSongCloseDecision.onStop`, su `directorStoppedSubject`).
                        if self._linkMode == .direttore && self._linkUserEnabledQ {
                            let snap = link_engine_read_transport_snapshot(lh)
                            directorStopped = true
                            if snap.linkEnabled {
                                directorFalseStart = self.falseStartAgainstRegisteredStart(stopPhase: snap.phaseAtStampQBig,
                                                                                            context: "stop-direttore")
                            } else {
                                // Ponte spento dal sistema (sfondo): l'istantanea porta zeri, niente
                                // falsa partenza su una fase a zero. La canzone si chiude lo stesso.
                                os_log("[Q-BEATS][2D][STOP] contesto:stop-direttore ponte spento - falsaPartenza:0",
                                       log: .default, type: .default)
                            }
                            self._startPhaseQ = nil
                        }
                    }
                }
            }
            // A421 — par. 2.2 j: l'arresto del Solo a una crisi e quello del Follower alla Reset sono arresti di crisi: un
            // drenaggio aperto si consegna una volta; lo Stop voluto lo chiude senza consegnarlo (`cleanupAfterStopQ`).
            if origin != .wanted {
                self.closeDrainOnCrisisStopQ(context: origin == .soloCrisis ? "crisi-solo" : "reset-follower")
            }
            // A421 — par. 2.2 e: la pulizia dello Stop (contatori, cambi armati nel DSP e in Swift, `_pendingNext*`,
            // drenaggio, lettore della base) anche a motore già fermo, per lo Stop voluto e per quello come la console del Solo:
            // il testo di prima sta in `cleanupAfterStopQ`. Per la Reset del Follower a motore già fermo no (il mandato non la
            // nomina, e `backtrackPlayerNode.stop()` toccherebbe un nodo del motore morto, A408): com'era.
            if origin != .followerReset || wasRunning {
                self.cleanupAfterStopQ()
            }
            if wasRunning {
                // === A420 (23/10/2026) — L'ARRESTO SULLA CODA (mandato A420, par. 2.1; U10 (B) del referto A419) ===
                // Lettore e motore si fermano qui, in fondo al blocco che ha abbassato `isRunning`, e solo a motore in moto (la
                // guardia più sopra). Lo Stop a Link resta prima, più sopra: la band non si ferma in ritardo della durata
                // dell'arresto. Il thread che chiama aspetta anche i due stop; la riga [ARRESTO] ne dà i millisecondi.
                self.stopPlayerAndEngineQ(context: "stop")
            }
            // A421 — par. 2.2 e: `isPlaying` è lo specchio di `isRunning`, anche a motore già fermo.
            self.publishIsPlayingQ(context: "stop")
        }
        if directorStopped {
            // Su main, PRIMA del `.stopped` che `stop()` accoda dopo di noi (stessa coda, FIFO).
            let falseStart = directorFalseStart
            DispatchQueue.main.async { [weak self] in
                self?.directorStoppedSubject.send(falseStart)
            }
        }
        // A412 — il tasto torna com'è oggi, DOPO l'avviso alla stanza qui sopra (stessa coda, FIFO).
        if silenceCleared {
            DispatchQueue.main.async { [weak self] in
                self?.directorSilence = nil
            }
            os_log("[Q-BEATS][DIR-TASTO] tasto:come-oggi motivo:stop-voluto - fascia e pedale playPause",
                   log: .default, type: .default)
        }
        guard wasRunning else { return }
        let statusStr = "stopped buf:\(bc) beats:\(bt)"
        // A421 — `isPlaying = false` non sta più qui: lo specchio si pubblica dalla coda, nel `sync` (par. 2.2 e).
        DispatchQueue.main.async {
            self.clickStatus = statusStr
        }
    }

    private func activateSessionAndStart(
        resumeAtBeat: Double?,
        trigger: RecoveryTrigger,
        mode: AudioMode? = nil,
        attempt: Int = 0,
        token: Int = -1
    ) {
        // A408 — fuori da «normale» niente riattivazione e niente ripartenza: la sessione la
        // riattiva solo la ricostruzione, al primo avvio dopo il reset (`start()`), e il click non
        // riparte da solo. Tutti i chiamanti girano su audioQueue; i tentativi e la rete di
        // sicurezza rientrano da qui, e qui si fermano.
        if mediaResetSkipsQ("riattivazione - trigger:\(trigger.rawValue)") { return }
        // A412 — LE RIPARTENZE AUTOMATICHE, UNA REGOLA (mandato §2.6, `RecoveryDecision`): tutte le strade del
        // referto A409 §4.1 passano di qui. Il Direttore muto in canzone va al coordinatore (`start()` lo porta
        // lì: mai ramo fresco né ripresa); dopo uno Stop voluto, e per il Solo dopo una crisi della sessione
        // audio, niente; il resto come oggi. Una riga a ogni passaggio. L'innesco ora è un tipo
        // (`RecoveryTrigger`), coi nomi che le righe [RESUME] scrivevano già.
        if recoveryRouteQ(trigger: trigger, stage: "ingresso") == .noRestart { return }

        // — Token anti-zombie —
        var activeToken = token
        if attempt == 0 {
            currentResumeToken += 1
            activeToken = currentResumeToken
            // A421 · SEGUITO 1 (par. 3.2) — il segno dell'eccezione, al tentativo 0: solo la catena del ritorno in primo piano
            // del Direttore muto in canzone che trova lo stato «interruzione di sistema» già alto (D5: la fine non è arrivata,
            // o la chiamata è ancora in corso); `nil` per ogni altra catena.
            _interruptionExceptionQ = InterruptionActivationDecision.exceptionMark(
                trigger: trigger, attempt: attempt, systemInterruption: _interruptionRouteQ.systemInterruption,
                playerRole: playerRoleQ, silentInSong: _directorSilentInSongQ,
                chainToken: activeToken, beginsCount: _interruptionBeginsQ)
            if let mark = _interruptionExceptionQ {
                os_log("[Q-BEATS][RESUME] eccezione: il ritorno in primo piano del Direttore muto in canzone con l'interruzione in corso innesco:%{public}@ catena:%d inizi:%d - la riattivazione come oggi (D5)",
                       log: .default, type: .default, trigger.rawValue, mark.chainToken, mark.beginsCount)
            }
            // A421 · SEGUITO 1 (par. 3.3, punto 1) — con l'interruzione di sistema in corso nessuna scrittura della sessione:
            // prima di `setCategory`, della preferenza degli avvisi, dei canali preferiti e di `isOtherAudioPlaying`.
            guard interruptionActivationAllowedQ(point: .entry, chainToken: activeToken) else {
                refuseActivationInInterruptionQ(trigger: trigger, attempt: attempt, point: .entry)
                return
            }

            // — Reset sessione e hardware gate (solo al primo tentativo) —
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [])
            } catch {
                os_log("[Q-BEATS][RESUME] setCategory fallito: %{public}@. Pending=true.",
                       log: .default, type: .error, error.localizedDescription)
                self.pendingResume = true
                self.pendingResumeBeat = nil
                return
            }
            // RIENTRO-P1 (d) — subito dopo `setCategory`, con `do/catch` proprio: un
            // fallimento qui NON deve far scattare il ramo Pending qui sopra.
            self.applyNoSystemAlertInterruptionsPreference(session, site: "riattivazione")

            // Sequenza iOS obbligatoria: setCategory → setPreferredOutputNumberOfChannels → setActive.
            // mode passato dal call site quando noto; nil = rileva ora.
            let targetMode = mode ?? detectAudioMode()
            configureSessionChannels(for: targetMode)

            if session.isOtherAudioPlaying {
                os_log("[Q-BEATS][RESUME] Hardware ancora occupato (isOtherAudioPlaying). Pending=true.",
                       log: .default, type: .default)
                self.pendingResume = true
                self.pendingResumeBeat = nil
                return
            }
        } else if activeToken != currentResumeToken {
            os_log("[Q-BEATS][RESUME] Zombie retry ucciso (token %d vs %d) trigger:%{public}@",
                   log: .default, type: .default, activeToken, currentResumeToken, trigger.rawValue)
            return
        } else {
            // A421 · SEGUITO 1 (par. 3.3, punto 1) — ai tentativi dopo, dopo il controllo della catena morta (che esce come
            // oggi, senza la riga nuova e senza ripresa pendente): la regola con l'eccezione (i tentativi e la rete a 5 s della
            // catena del ritorno in primo piano, finché vale).
            guard interruptionActivationAllowedQ(point: .entry, chainToken: activeToken) else {
                refuseActivationInInterruptionQ(trigger: trigger, attempt: attempt, point: .entry)
                return
            }
        }

        os_log("[Q-BEATS][RESUME] trigger:%{public}@ attempt:%d token:%d",
               log: .default, type: .default, trigger.rawValue, attempt, activeToken)

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            // A408 — di nuovo qui: una Lost può essere arrivata fra il controllo in testa e questo blocco.
            if self.mediaResetSkipsQ("riattivazione - trigger:\(trigger.rawValue)") { return }
            // A421 · SEGUITO 1 (par. 3.3, punto 2) — prima il contatore della catena: se è cambiato il blocco è di una catena
            // morta (per esempio uno Stop voluto durante l'interruzione) e si esce senza `setActive` e senza ripresa pendente,
            // come la catena morta in testa; poi la regola con l'eccezione: un inizio d'interruzione arrivato fra `setCategory`
            // e questo blocco (`audioQueue.sync`) passa prima della `setActive`.
            guard activeToken == self.currentResumeToken else {
                os_log("[Q-BEATS][RESUME] Zombie retry ucciso prima della setActive (token %d vs %d) trigger:%{public}@ attempt:%d",
                       log: .default, type: .default, activeToken, self.currentResumeToken, trigger.rawValue, attempt)
                return
            }
            guard self.interruptionActivationAllowedQ(point: .setActive, chainToken: activeToken) else {
                self.refuseActivationInInterruptionQ(trigger: trigger, attempt: attempt, point: .setActive)
                return
            }
            do {
                try AVAudioSession.sharedInstance().setActive(true,
                    options: .notifyOthersOnDeactivation)

                // SOLO QUI: reset stato interruzione
                self.isAudioInterrupted = false
                self.pendingResume = false
                self.pendingResumeBeat = nil
                // A416 · SEGUITO 2 — una `setActive(true)` riuscita chiude anche l'interruzione di sistema (mandato §2.1),
                // prima dell'uscita di `recoveryRouteQ` qui sotto.
                self.noteSystemInterruptionQ(.sessionActivated)

                os_log("[Q-BEATS][RESUME] setActive OK dopo %d tentativi (token:%d trigger:%{public}@)",
                       log: .default, type: .default, attempt, activeToken, trigger.rawValue)

                // Rebuild grafo Pro DOPO setActive(true) — il formato 4ch è disponibile solo ora.
                // In Base mode il grafo è già corretto (setupGraph usa sempre Base).
                let currentMode = mode ?? self.detectAudioMode()
                if currentMode == .pro {
                    self.rebuildGraph(for: .pro, context: "pro")
                    os_log("[Q-BEATS][RESUME] rebuildGraph Pro eseguito post-setActive (trigger:%{public}@)",
                           log: .default, type: .default, trigger.rawValue)
                }

                // A412 — la regola si rilegge subito prima dell'avvio: fra l'ingresso e qui (fino a venti
                // tentativi) può essere arrivato uno Stop voluto.
                if self.recoveryRouteQ(trigger: trigger, stage: "avvio") == .noRestart { return }
                // A421 — l'innesco tipizzato: `start()` riguarda «uscita mancante» nel suo blocco (U5).
                self.start(resumeAtBeat: resumeAtBeat, trigger: trigger.rawValue, recovery: trigger)

            } catch {
                let maxAttempts = 20
                let retryDelay = 0.5
                // A416 (21/10/2026) — l'errore della `setActive` nelle due righe qui sotto: dominio, codice e quattro
                // lettere (mandato «USCITA-AUDIO-PASSO-1», §2.4; referto A415 §5.6). Fino ad A415 non c'era.
                let errorText = AudioEngine.describeAudioError(error)

                guard attempt < maxAttempts else {
                    self.pendingResume = true
                    self.pendingResumeBeat = nil
                    os_log("[Q-BEATS][RESUME] setActive esaurito — pendingResume=true beat:%.4f trigger:%{public}@ errore:%{public}@",
                           log: .default, type: .default, resumeAtBeat ?? -1.0, trigger.rawValue, errorText)

                    // Safety net a 5 secondi (non 3)
                    self.audioQueue.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                        guard let self = self else { return }
                        guard self.pendingResume,
                              self.currentResumeToken == activeToken else {
                            os_log("[Q-BEATS][RESUME] Safety net annullato — token cambiato o pendingResume cleared",
                                   log: .default, type: .default)
                            return
                        }
                        self.pendingResume = false
                        self.pendingResumeBeat = nil
                        self.activateSessionAndStart(
                            resumeAtBeat: resumeAtBeat,
                            trigger: .safetyNet,
                            attempt: 1,
                            token: activeToken
                        )
                    }
                    return
                }

                os_log("[Q-BEATS][RESUME] retry attempt %d/20 in 500ms (token:%d) errore:%{public}@",
                       log: .default, type: .default, attempt + 1, activeToken, errorText)

                self.audioQueue.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
                    self?.activateSessionAndStart(
                        resumeAtBeat: resumeAtBeat,
                        trigger: trigger,
                        attempt: attempt + 1,
                        token: activeToken
                    )
                }
            }
        }
    }

    // RIENTRO-P1 (d) — LA PREFERENZA APPLE «NIENTE INTERRUZIONI DAGLI AVVISI DI SISTEMA».
    // `AVAudioSession.setPrefersNoInterruptionsFromSystemAlerts(_:)`, iOS/iPadOS 14.5+ (il
    // target è 16.0: nessun controllo di versione). Documentazione Apple, riletta il
    // 17/09/2026: con le chiamate in arrivo mostrate a BANNER «prevents the system from
    // interrupting the audio session with incoming call notifications … The system only
    // interrupts the audio session if the user accepts the call»; e «This preference has
    // no effect if the device uses the full-screen display style». Apple la indica per le
    // app «that you use for music performance».
    // ⛔ NON ferma Siri, né le sveglie, né la chiamata a schermo intero o ACCETTATA: toglie
    //    un'interruzione sola, quella dello squillo a banner.
    // Si imposta subito dopo `setCategory`, nei due punti che la impostano (`setupSession`
    // e `activateSessionAndStart`), per tutti i ruoli. `do/catch` proprio: un errore qui si
    // logga e basta, non ferma né l'avvio della sessione né una ripresa.
    private func applyNoSystemAlertInterruptionsPreference(_ session: AVAudioSession, site: String) {
        do {
            try session.setPrefersNoInterruptionsFromSystemAlerts(true)
            os_log("[Q-BEATS][RIENTRO-P1] preferenza niente-interruzioni-dagli-avvisi impostata - punto:%{public}@",
                   log: .default, type: .default, site)
        } catch {
            os_log("[Q-BEATS][RIENTRO-P1] preferenza niente-interruzioni-dagli-avvisi NON impostata - punto:%{public}@ errore:%{public}@",
                   log: .default, type: .error, site, error.localizedDescription)
        }
    }

    // A408 — rende `true` se la sessione si è attivata. La legge la ricostruzione dopo il reset dei
    // servizi audio (`rebuildAfterMediaResetQ`); `init` la ignora, come prima.
    @discardableResult
    private func setupSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            // RIENTRO-P1 (d) — subito dopo `setCategory` (il `do/catch` è dentro la funzione).
            applyNoSystemAlertInterruptionsPreference(session, site: "setupSession")
            // A416 (21/10/2026) — la preferita resta 48000, il valore con cui nasce la copia del motore, e non si prende
            // più dalla copia (mandato «USCITA-AUDIO-PASSO-1», §2.1): alla ricostruzione dopo il reset la copia poteva
            // valere la frequenza di un'uscita di passaggio. Anche la durata del buffer qui si chiede per 48000 (512
            // campioni); dopo la `setActive`, `applySampleRateQ` (in `setupGraph`) la chiede di nuovo alla frequenza vera,
            // se è diversa (Apple: preferita e durata si possono chiedere prima o dopo l'attivazione).
            try session.setPreferredSampleRate(SampleRateDecision.preferredSampleRate)
            try session.setPreferredIOBufferDuration(Double(bufferSize) / SampleRateDecision.preferredSampleRate)
            _ioBufferRequestRateQ = SampleRateDecision.preferredSampleRate
            // Sequenza iOS obbligatoria: setCategory → setPreferredOutputNumberOfChannels → setActive
            configureSessionChannels(for: detectAudioMode())
            let setActiveStart = mach_absolute_time()
            try session.setActive(true)
            // A416 · SEGUITO 2 — una `setActive(true)` riuscita chiude l'interruzione di sistema (mandato §2.1), anche dentro
            // la ricostruzione dopo il reset dei servizi audio (`rebuildAfterMediaResetQ`). Su audioQueue: l'avvio dell'app
            // e la ricostruzione girano lì.
            noteSystemInterruptionQ(.sessionActivated)
            // A406 — il thread della setActive (all'avvio e al reset dei servizi audio: main:0) e la
            // durata della sola setActive.
            os_log("[Q-BEATS][SESSIONE] setActive main:%d ms:%.1f",
                   log: .default, type: .default,
                   Thread.isMainThread ? 1 : 0,
                   machTicksToSeconds(mach_absolute_time() - setActiveStart) * 1000.0)
            // A416 (21/10/2026) — qui la copia del motore prendeva la frequenza della sessione, il DSP la riceveva
            // (`metronome_set_sample_rate`, l'unica scrittura del DSP fino ad A415, solo qui) e il ponte del tap ne teneva una
            // copia che nessuno leggeva; la riga «QA-3 sampleRate aggiornato». Da A416 lo fa `applySampleRateQ`, in
            // `setupGraph` subito dopo (all'avvio dell'app e alla ricostruzione dopo il reset), dalla fonte unica e per
            // tutte le copie insieme; la riga è [FORMATO].
            return true
        } catch {
            // A416 — l'errore nel registro, con dominio, codice e quattro lettere (mandato §2.4): fino ad A415 andava solo
            // allo stato a schermo.
            os_log("[Q-BEATS][SESSIONE] setupSession fallita - errore:%{public}@",
                   log: .default, type: .error, AudioEngine.describeAudioError(error))
            DispatchQueue.main.async { self.clickStatus = "session fallita: \(error)" }
            return false
        }
    }

    // A408 — rende il modo usato per il grafo (la riga «grafo pronto» della ricostruzione).
    // A416 (21/10/2026) — `context`: chi costruisce, per la riga [FORMATO] («avvio-app», «reset»).
    @discardableResult
    private func setupGraph(context: String) -> AudioMode {
        // ⚠️ RISCRITTO A416 (21/10/2026). Qui c'era `self.sampleRate = AVAudioSession.sharedInstance().sampleRate` e,
        // col commento «Task D refactor #18 — propaga sampleRate al pending atomic.», la copia nel ponte del tap: la
        // copia del motore seguiva la sessione, il DSP no, e il ponte non lo leggeva nessuno. Da A416 la frequenza viene
        // dalla fonte unica e arriva a tutte le copie insieme (`applySampleRateQ`, mandato «USCITA-AUDIO-PASSO-1», §2.1).
        applySampleRateQ(context: context)
        let detectedMode = detectAudioMode()
        // A416 — lo schermo prende una costante letta qui: il blocco su main leggeva `self.sampleRate` quando girava, e
        // la copia si scrive su audioQueue (referto A406, §8 punto 3).
        let rateForScreen = self.sampleRate
        DispatchQueue.main.async {
            self.audioMode = detectedMode
            self.sampleRateInfo = rateForScreen
        }
        os_log("setupGraph sampleRate=%.1f audioMode=%{public}@",
               log: .default, type: .default,
               self.sampleRate, "\(detectedMode)")

        engine.attach(playerNode)
        engine.attach(backtrackPlayerNode)
        engine.attach(ch3PlayerNode)
        engine.attach(ch4PlayerNode)
        engine.attach(ch1MixerNode)
        engine.attach(ch2MixerNode)
        engine.attach(ch3MixerNode)
        engine.attach(ch4MixerNode)
        connectAllNodes(for: detectedMode)
        // === Task D refactor #18c — installTap su mainMixerNode ===
        // Sostituisce engine.attach(linkSinkNode) di refactor #18.
        // Il tap richiede mainMixerNode presente nel graph (connectAllNodes
        // lo configura). Idempotente — vedi installLinkTap().
        installLinkTap()
        applyChannelRouting(for: detectedMode)
        return detectedMode
    }

    /// Costruisce la topologia del grafo AVAudioEngine in base alla modalità hardware.
    /// Base: tutti i mixer al mainMixerNode (stereo), coi volumi salvati; Ch3/Ch4 le silenzia `applyChannelRouting`
    ///       (outputVolume a 0), non questa funzione.
    /// Pro: anche qui i quattro mixer passano dal mainMixerNode, col formato d'uscita a 4 canali; il mainMixerNode si collega
    ///      all'outputNode con quel formato, e un channelMap manda ogni mixer al suo canale. Guardia sui canali del formato
    ///      d'uscita del nodo d'uscita: sotto 4, topologia Base con una riga d'errore.
    /// ⚠️ RISCRITTO A420 (23/10/2026). La riga del Base diceva «Base: tutti i mixer al mainMixerNode (stereo). Ch3/Ch4
    /// silenziate via outputVolume.», e quelle del Pro «Pro:  connessione diretta a outputNode su bus fisici separati.» e
    /// «Guard su maximumOutputNumberOfChannels — se l'hardware non supporta 4 canali, fallback automatico a topologia Base
    /// con log di errore.»: il codice qui sotto non lo fa (precisazione (3) del referee sul referto A419, mandato A420,
    /// par. 1; la riga del Base l'ha trovata il verificatore del diff di A420).
    /// Chiamare solo con engine fermo.
    private func connectAllNodes(for mode: AudioMode) {
        let monoFormat   = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Player → ch1Mixer (singola destination, identico in Base e Pro)
        // === Task D refactor #18c ===
        // Multi-destination [ch1Mixer, linkSinkNode] di refactor #18 era
        // architetturalmente corretto ma AVAudioEngine non onorava il sink
        // come secondo consumer (sink block mai invocato — diagnosi #18b).
        // Sostituito da installTap su mainMixerNode (vedi installLinkTap).
        engine.connect(playerNode, to: ch1MixerNode, format: monoFormat)
        engine.connect(backtrackPlayerNode, to: ch2MixerNode, format: nil)
        engine.connect(ch3PlayerNode,       to: ch3MixerNode, format: nil)
        engine.connect(ch4PlayerNode,       to: ch4MixerNode, format: nil)

        ch1MixerNode.outputVolume = ch1Volume
        ch2MixerNode.outputVolume = ch2Volume
        ch3MixerNode.outputVolume = ch3Volume
        ch4MixerNode.outputVolume = ch4Volume

        switch mode {
        case .base:
            engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: monoFormat)
            engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: stereoFormat)
            os_log("connectAllNodes: topologia BASE",
                   log: .default, type: .default)

        case .pro:
            // Formato reale dell'outputNode — disponibile SOLO dopo setActive(true).
            // Questo metodo viene chiamato da rebuildGraph() che è chiamato
            // dentro activateSessionAndStart dopo setActive OK — mai prima.
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            let outputChannels = outputFormat.channelCount

            guard outputChannels >= 4 else {
                os_log("connectAllNodes: Pro richiesto ma outputChannels=%d < 4 — fallback Base",
                       log: .default, type: .error, outputChannels)
                engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: monoFormat)
                engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: stereoFormat)
                return
            }

            // Connessione esplicita mainMixerNode → outputNode con formato 4ch.
            // Senza questa connessione esplicita il channelMap non è efficace.
            // Fonte: Apple Developer Forums thread/713983.
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)

            // Ogni ch mixer → mainMixerNode con outputFormat (4ch).
            // Necessario per attivare il channelMap — con formato mono non funziona.
            engine.connect(ch1MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch2MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch3MixerNode, to: engine.mainMixerNode, format: outputFormat)
            engine.connect(ch4MixerNode, to: engine.mainMixerNode, format: outputFormat)

            // channelMap: [NSNumber] — indice = canale output 4ch, valore = canale input (-1 = silenzio).
            ch1MixerNode.auAudioUnit.channelMap = [0, -1, -1, -1]   // click → out 0
            ch2MixerNode.auAudioUnit.channelMap = [-1, 0, -1, -1]   // backtrack → out 1
            ch3MixerNode.auAudioUnit.channelMap = [-1, -1, 0, -1]   // guide vocals → out 2
            ch4MixerNode.auAudioUnit.channelMap = [-1, -1, -1, 0]   // FX → out 3

            os_log("connectAllNodes: topologia PRO — channelMap attivo (outputChannels:%d SR:%.0f)",
                   log: .default, type: .default,
                   outputChannels, outputFormat.sampleRate)
        }
    }

    /// Ricostruisce il grafo: disconnette tutti i nodi, riconnette per la modalità
    /// indicata, prepara l'engine.
    /// Chiamare solo con engine e playerNode già fermi.
    /// A416 (21/10/2026) — prima di ricollegare porta la frequenza dalla fonte unica a tutte le copie (`applySampleRateQ`,
    /// mandato «USCITA-AUDIO-PASSO-1», §2.1): i formati dei nodi seguono la copia del motore. `context`: chi ricostruisce,
    /// per la riga [FORMATO] («pro», «fine-interruzione», «modo», «configurazione»). Il ricollegamento da solo è
    /// `reconnectGraphQ`. ⚠️ A420 (23/10/2026): «configurazione» non più; il cambio di configurazione passa dalla
    /// ripartenza per la frequenza (`restartForRateChangeQ`), che chiama da sé `applySampleRateQ` e `reconnectGraphQ`
    /// (mandato A420, par. 2.3).
    private func rebuildGraph(for mode: AudioMode, context: String) {
        applySampleRateQ(context: context)
        reconnectGraphQ(for: mode, caller: context)
    }

    /// Il ricollegamento di `rebuildGraph` (fino ad A415 era tutto `rebuildGraph`), coi formati della copia del motore.
    /// Lo chiamano da soli l'avvio e il cambio di percorso, che la frequenza l'hanno già portata. Chiamare SOLO su
    /// audioQueue, con engine e playerNode già fermi.
    /// ⚠️ A420 (23/10/2026): da solo lo chiama anche la ripartenza per la frequenza (`restartForRateChangeQ`, mandato A420,
    /// par. 2.3), dopo aver portato la frequenza.
    /// A420 (23/10/2026) — LA RETE, IN TESTA, PER CHIUNQUE RICOLLEGHI (mandato A420, par. 2.1): se il motore di sistema gira
    /// ancora, lettore e motore si fermano prima di ricollegare. Fino ad A419 era la guardia del solo `start()`. Dopo il
    /// pezzo 1 non dovrebbe scattare mai (l'invariante del mandato: «isRunning falso su audioQueue ⇒ lettore e motore
    /// fermi»): se scatta, una riga col chiamante (`caller`: «avvio», «percorso», «configurazione», o il contesto di
    /// `rebuildGraph`).
    private func reconnectGraphQ(for mode: AudioMode, caller: String) {
        if engine.isRunning {
            let stopStart = mach_absolute_time()
            playerNode.stop()
            engine.stop()
            os_log("[Q-BEATS][ARRESTO] rete del ricollegamento chiamante:%{public}@ isRunning:%d ms:%.3f - il motore girava: fermati lettore e motore prima di ricollegare",
                   log: .default, type: .default,
                   caller, isRunning ? 1 : 0, machTicksToSeconds(mach_absolute_time() - stopStart) * 1000.0)
        }
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(backtrackPlayerNode)
        engine.disconnectNodeOutput(ch3PlayerNode)
        engine.disconnectNodeOutput(ch4PlayerNode)
        engine.disconnectNodeOutput(ch1MixerNode)
        engine.disconnectNodeOutput(ch2MixerNode)
        engine.disconnectNodeOutput(ch3MixerNode)
        engine.disconnectNodeOutput(ch4MixerNode)
        connectAllNodes(for: mode)
        // === Task D refactor #18c — re-install tap dopo rebuild ===
        // disconnectNodeOutput non rimuove il tap installato su mainMixerNode,
        // ma per safety reinstalliamo (idempotente: removeTap precede installTap).
        installLinkTap()
        engine.prepare()
        os_log("rebuildGraph completato — mode: %{public}@",
               log: .default, type: .default, "\(mode)")
    }

    // =====================================================================================
    // === A416 (21/10/2026) — USCITA AUDIO, PASSO 1: LA FREQUENZA DA UNA FONTE SOLA ==========
    // =====================================================================================
    // Mandato del referee «USCITA-AUDIO-PASSO-1», §2.1 e §2.7 (righe 4 e 6). La regola è pura, col suo banco
    // (`SampleRateDecision`); qui la lettura della fonte, la scrittura delle copie e la riga. Tutto su audioQueue.
    // Chi la chiama: `setupGraph` (avvio dell'app, ricostruzione dopo il reset), `rebuildGraph` (il Pro dopo la
    // `setActive`, la fine di un'interruzione, il cambio di modo, il cambio di configurazione), il cambio di percorso
    // (`handleRouteChange`) e l'avvio (`start()`, prima di `engine.start()`).
    // ⚠️ A420 (23/10/2026): il cambio di configurazione non passa più da `rebuildGraph`; la chiama la ripartenza per la
    // frequenza (`restartForRateChangeQ`), la funzione sola del cambio di configurazione e del cambio di percorso a motore in
    // moto (mandato A420, par. 2.3).

    /// La frequenza del formato d'uscita del nodo d'uscita del motore (Apple: il formato dell'hardware; zero = uscita non
    /// abilitata). Chiamare SOLO su audioQueue.
    private func outputSampleRateQ() -> Double {
        engine.outputNode.outputFormat(forBus: 0).sampleRate
    }

    /// LA FREQUENZA, UNA FONTE SOLA, A TUTTE LE COPIE. Legge la fonte (il nodo d'uscita, poi la sessione) e le copie,
    /// decide (`SampleRateDecision`) e, a motore fermo, riscrive nello stesso momento quelle diverse: la copia del motore
    /// (`sampleRate`: i formati dei nodi e dei buffer la seguono, il sequencer MIDI la riceve a ogni buffer), il DSP
    /// (`metronome_set_sample_rate`, col suo specchio), i tre campioni del click, la durata del buffer chiesta (512
    /// campioni). A motore in moto con una copia diversa non scrive niente («fermare-e-ricostruire»): ferma chi chiama.
    /// Una riga [FORMATO] a ogni chiamata. Chi ricollega i nodi è chi chiama (`reconnectsGraph`). Chiamare SOLO su
    /// audioQueue.
    @discardableResult
    private func applySampleRateQ(context: String) -> SampleRateDecision.Outcome {
        let session = AVAudioSession.sharedInstance()
        let reading = SampleRateDecision.Reading(output: outputSampleRateQ(),
                                                 session: session.sampleRate,
                                                 copy: sampleRate,
                                                 dsp: _dspSampleRateQ,
                                                 click: _clickSampleRateQ,
                                                 ioBuffer: _ioBufferRequestRateQ,
                                                 engineRunning: isRunning)
        let outcome = SampleRateDecision.outcome(reading)
        if outcome.rewritesCopy {
            sampleRate = outcome.rate
        }
        if outcome.rewritesDSP, let mh = metronomeHandle {
            metronome_set_sample_rate(mh, outcome.rate)
            _dspSampleRateQ = outcome.rate
        }
        if outcome.regeneratesClick {
            clickSamples            = generateClickSamples(frequency: 1000.0)
            accentedClickSamples    = generateClickSamples(frequency: 1500.0)
            subdivisionClickSamples = generateClickSamples(frequency: 800.0)
            _clickSampleRateQ = sampleRate
        }
        if outcome.requestsIOBuffer, let duration = SampleRateDecision.ioBufferDuration(rate: outcome.rate) {
            do {
                try session.setPreferredIOBufferDuration(duration)
                _ioBufferRequestRateQ = outcome.rate
            } catch {
                os_log("[Q-BEATS][FORMATO] durata del buffer non chiesta contesto:%{public}@ frequenza:%.0f - errore:%{public}@",
                       log: .default, type: .error, context, outcome.rate, AudioEngine.describeAudioError(error))
            }
        }
        os_log("[Q-BEATS][FORMATO] contesto:%{public}@ uscita:%.0f sessione:%.0f preferita:%.0f fonte:%{public}@ copia:%.0f->%.0f dsp:%.0f->%.0f click:%d bufferIO_ms:%.2f -> esito:%{public}@",
               log: .default, type: .default,
               context, reading.output, reading.session, session.preferredSampleRate, outcome.source.rawValue,
               reading.copy, sampleRate, reading.dsp, _dspSampleRateQ, outcome.regeneratesClick ? 1 : 0,
               session.ioBufferDuration * 1000.0, outcome.action.rawValue)
        return outcome
    }

    /// Dominio, codice e quattro lettere di un errore della sessione audio, per le righe (`AudioErrorText`, mandato §2.4).
    private static func describeAudioError(_ error: Error) -> String {
        let ns = error as NSError
        return AudioErrorText.line(domain: ns.domain, code: ns.code)
    }

    /// A416 · SEGUITO 2 (21/10/2026) — lo stato «interruzione di sistema in corso» (`InterruptionRouteDecision`, mandato del
    /// referee «A416 · SEGUITO 2», §2.1): lo alza l'inizio di ogni interruzione; lo abbassano la fine, una `setActive(true)`
    /// riuscita e un `engine.start()` riuscito. Il rimandato non lo tocca. Una riga [INTERRUZIONE-SISTEMA] quando cambia, e
    /// nei due casi di confine (un inizio con lo stato già alzato, una fine con lo stato già basso). Chiamare SOLO su
    /// audioQueue.
    private func noteSystemInterruptionQ(_ event: InterruptionRouteDecision.Event) {
        let before = _interruptionRouteQ
        _interruptionRouteQ = InterruptionRouteDecision.state(after: event, from: before)
        let boundary = (event == .began && before.systemInterruption) || (event == .ended && !before.systemInterruption)
        guard boundary || before.systemInterruption != _interruptionRouteQ.systemInterruption else { return }
        os_log("[Q-BEATS][INTERRUZIONE-SISTEMA] %{public}@ da:%{public}@ prima:%d rimandato:%{public}@",
               log: .default, type: .default,
               _interruptionRouteQ.systemInterruption ? "alzato" : "abbassato", event.rawValue,
               before.systemInterruption ? 1 : 0, _interruptionRouteQ.deferredReason ?? "-")
    }

    /// La riga del buco del render (mandato §2.3, §2.7 riga 7): il buco (scarto meno base), i buffer consegnati, lo
    /// scarto e la base; ruolo, show, canzone, Direttore muto; il cambio di percorso «vicino» (arrivato fra un secondo
    /// prima dell'inizio stimato del buco e adesso: `RenderGapMeter.isNear`) col suo motivo e i millisecondi dall'inizio
    /// del buco; un cambio di configurazione vicino. In questo passo nessuna azione. Chiamare SOLO su audioQueue, da
    /// `scheduleNextBuffer`.
    /// ⚠️ A421 (24/10/2026): «In questo passo nessuna azione» era il passo 1; da A421 la riga porta l'esito vero
    /// (`RenderGapDecision`: solo-riga, segue-link, crisi), e la crisi la fa `scheduleNextBuffer` (mandato A421, U7, U8).
    private func logRenderGapQ(_ gap: RenderGapMeter.Gap, nowTicks: UInt64, outcome: RenderGapOutcome) {
        let role = PlayerRoleDecision.playerRole(role: _linkMode, userLinkEnabled: _linkUserEnabledQ)
        var routeText = "nessuno"
        var routeMsText = "-"
        if let mark = _lastRouteChangeQ,
           RenderGapMeter.isNear(eventTicks: mark.ticks, holeStartTicks: gap.startTicks, nowTicks: nowTicks,
                                 ticksPerSecond: ticksPerSecond) {
            routeText = mark.reason
            routeMsText = String(format: "%.1f", signedMilliseconds(from: gap.startTicks, to: mark.ticks))
        }
        var configNear = false
        if let configTicks = _lastConfigChangeTicksQ {
            configNear = RenderGapMeter.isNear(eventTicks: configTicks, holeStartTicks: gap.startTicks,
                                               nowTicks: nowTicks, ticksPerSecond: ticksPerSecond)
        }
        os_log("[Q-BEATS][RENDER] buco ms:%.1f buffer:%d scarto_ms:%.1f base_ms:%.1f ruolo:%{public}@ show:%d canzone:%d muto:%d percorso:%{public}@ percorso_ms:%{public}@ configurazione:%d -> esito:%{public}@",
               log: .default, type: .default,
               gap.holeSeconds * 1000.0, gap.bufferCount, gap.gapSeconds * 1000.0, gap.baseSeconds * 1000.0,
               role.rawValue, _showOpenQ ? 1 : 0, _songInProgressQ ? 1 : 0, _directorSilentInSongQ ? 1 : 0,
               routeText, routeMsText, configNear ? 1 : 0, outcome.rawValue)
    }

    /// La riga del tempo del click ogni 32 battiti, accanto a [SinkDiag-AQ] (mandato §2.7, riga 5): il tempo misurato dai
    /// battiti e dalle loro ore d'uscita (`ClickTempoMeasure`: l'ora d'uscita del buffer più lo scostamento del battito),
    /// lo stesso sui campioni consegnati al lettore (alla frequenza della copia del motore), e il tempo della sezione
    /// (`_audioBPM`). È la riga che mostrerebbe il 91,9 % (DSP a 48000, nodi a 44100): `tempoMisurato` 110,3 con la
    /// sezione a 120. `-` sulla prima riga dopo l'avvio se non c'è un riferimento. Chiamare SOLO su audioQueue.
    private func logClickTempoQ() {
        let beats = beatTickCounter - _tempoLogRefTickQ
        var measuredText = "-"
        var bySamplesText = "-"
        if _tempoLogRefTickQ > 0, beats > 0, _lastBeatOutTicksQ > _tempoLogRefOutTicksQ {
            measuredText = ClickTempoMeasure.bpm(beats: beats, ticks: _lastBeatOutTicksQ - _tempoLogRefOutTicksQ,
                                                 ticksPerSecond: ticksPerSecond).map { String(format: "%.2f", $0) } ?? "-"
            bySamplesText = ClickTempoMeasure.bpm(beats: beats, samples: _lastBeatSampleQ - _tempoLogRefSampleQ,
                                                  sampleRate: sampleRate).map { String(format: "%.2f", $0) } ?? "-"
        }
        os_log("[Q-BEATS][TEMPO-CLICK] battiti:%d tempoMisurato:%{public}@ tempoCampioni:%{public}@ tempoSezione:%.2f copiaSR:%.0f dspSR:%.0f",
               log: .default, type: .default,
               beats, measuredText, bySamplesText, _audioBPM, sampleRate, _dspSampleRateQ)
        _tempoLogRefTickQ = beatTickCounter
        _tempoLogRefOutTicksQ = _lastBeatOutTicksQ
        _tempoLogRefSampleQ = _lastBeatSampleQ
    }

    /// Il nome del motivo di un cambio di percorso (Apple, `AVAudioSession.RouteChangeReason`), per le righe.
    private static func routeChangeReasonName(_ reason: AVAudioSession.RouteChangeReason) -> String {
        switch reason {
        case .unknown: return "unknown"
        case .newDeviceAvailable: return "newDeviceAvailable"
        case .oldDeviceUnavailable: return "oldDeviceUnavailable"
        case .categoryChange: return "categoryChange"
        case .override: return "override"
        case .wakeFromSleep: return "wakeFromSleep"
        case .noSuitableRouteForCategory: return "noSuitableRouteForCategory"
        case .routeConfigurationChange: return "routeConfigurationChange"
        @unknown default: return "sconosciuto-\(reason.rawValue)"
        }
    }

    /// Le uscite di un percorso col loro tipo (`AVAudioSessionPortDescription.portType`), unite da «+»; «nessuna» se non
    /// ce ne sono, «-» se il percorso non c'è. Solo il tipo, mai il nome dell'apparecchio (che può portare un nome di
    /// persona e degli accenti).
    private static func describeOutputs(_ route: AVAudioSessionRouteDescription?) -> String {
        guard let route else { return "-" }
        let types = route.outputs.map { $0.portType.rawValue.replacingOccurrences(of: " ", with: "_") }
        return types.isEmpty ? "nessuna" : types.joined(separator: "+")
    }

    // === Task D refactor #18c — installTap su mainMixerNode ===
    // Sostituisce AVAudioSinkNode (refactor #18) che non veniva mai
    // invocato come secondo consumer multi-destination di playerNode.
    //
    // installTap su mainMixerNode opera con priorita' RT equivalente al
    // rendering AVAudioEngine (NON e' il "vero" render thread Core Audio
    // in senso stretto, ma scheduling RT garantito ad ogni render del
    // mainMixer — sempre attivo durante engine running).
    //
    // A406 — il blocco conta i buffer resi e nient'altro. Il contatore lo legge
    // la riga [SinkDiag-AQ] relay, su audioQueue, nel richiamo del battito di
    // scheduleNextBuffer, da dove parte anche la trasmissione a Link (dal 15/05,
    // e77d6e8).
    //
    // Vincoli del block (identici al sink originario):
    // - niente self / weak / class Swift (no ARC)
    // - niente ObjC messaging
    // - niente lock / I/O
    // - solo C function su atomic
    //
    // Cattura esplicita: pendingPtr, opaque C pointer stabile per lifecycle.
    //
    // Idempotente: removeTap precede installTap per sopravvivere a
    // rebuildGraph (cambio modalita' Base/Pro).
    private func installLinkTap() {
        engine.mainMixerNode.removeTap(onBus: 0)

        let pendingPtr: OpaquePointer = self.linkPending

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 512, format: nil) { _, _ in
            // Tap block — conta i buffer resi per la riga [SinkDiag-AQ] relay.
            // Vincoli: no self/weak/class, no ObjC msg, no lock, no I/O.
            _ = qbeats_link_pending_increment_render_buffer(pendingPtr)
        }
    }

    // MARK: - Fase 1.5a — Hardware Detection

    private func detectAudioMode() -> AudioMode {
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .usbAudio && (output.channels?.count ?? 0) > 2 {
                return .pro
            }
        }
        return .base
    }

    /// Imposta il numero di canali output preferiti su AVAudioSession.
    /// Chiamare DOPO setCategory e PRIMA di setActive — invariante iOS.
    /// Non throwing: errore loggato, non propagato.
    private func configureSessionChannels(for mode: AudioMode) {
        let session = AVAudioSession.sharedInstance()
        do {
            switch mode {
            case .pro:
                try session.setPreferredOutputNumberOfChannels(4)
                os_log("configureSessionChannels: Pro — 4 canali richiesti (max hardware: %d)",
                       log: .default, type: .default,
                       session.maximumOutputNumberOfChannels)
            case .base:
                try session.setPreferredOutputNumberOfChannels(2)
                os_log("configureSessionChannels: Base — 2 canali",
                       log: .default, type: .default)
            }
        } catch {
            os_log("configureSessionChannels error: %{public}@",
                   log: .default, type: .error, error.localizedDescription)
        }
    }

    private func applyChannelRouting(for mode: AudioMode) {
        switch mode {
        case .base:
            ch1MixerNode.pan = -1.0
            ch2MixerNode.pan =  1.0
            ch3MixerNode.outputVolume = 0.0
            ch4MixerNode.outputVolume = 0.0
            os_log("routing BASE: Ch1 pan L, Ch2 pan R, Ch3/Ch4 muted",
                   log: .default, type: .default)
        case .pro:
            ch1MixerNode.pan = 0.0
            ch2MixerNode.pan = 0.0
            ch3MixerNode.outputVolume = ch3Volume
            ch4MixerNode.outputVolume = ch4Volume
            os_log("routing PRO: Ch1-Ch4 active, pan center",
                   log: .default, type: .default)
        }
    }

    // Genera click sintetico alla frequenza indicata.
    // Chiamare SOLO su audioQueue.
    private func generateClickSamples(frequency: Double) -> [Float] {
        let freq       : Float = Float(frequency)
        let durationMs : Float = 40.0
        let frameCount = Int(Float(sampleRate) * durationMs / 1000.0)
        let decayRate  : Float = 80.0
        var samples = [Float](repeating: 0.0, count: frameCount)
        for i in 0..<frameCount {
            let t        = Float(i) / Float(sampleRate)
            let envelope = expf(-decayRate * t)
            samples[i]   = sinf(2.0 * Float.pi * freq * t) * envelope * 0.8
        }
        return samples
    }

    // === AGGIUNTO 6C ===
    // Converte secondi in mach ticks usando timebase cachata.
    // Chiamabile da qualsiasi thread.
    private func secondsToMachTicks(_ seconds: Double) -> UInt64 {
        guard seconds > 0, machTimebase.numer > 0 else { return 0 }
        let nanos = seconds * 1_000_000_000.0
        return UInt64(nanos) * UInt64(machTimebase.denom) / UInt64(machTimebase.numer)
    }

    private func machTicksToSeconds(_ ticks: UInt64) -> Double {
        guard machTimebase.denom > 0 else { return 0.0 }
        let nanos = Double(ticks) * Double(machTimebase.numer) / Double(machTimebase.denom)
        return nanos / 1_000_000_000.0
    }

    // === Fix #4 — vero hostTime di output del prossimo buffer ===
    // playerNode.lastRenderTime è hardware-accurate, ancorato al clock audio
    // del sistema, non a mach_absolute_time(). Indica l'orario in cui
    // l'ULTIMO buffer è stato renderizzato. Il buffer corrente (quello in
    // scheduleNextBuffer) sarà renderizzato ~bufferDuration dopo, e l'output
    // udibile arriva ~outputLatency dopo il rendering.
    //
    // Il fallback (now + outputLatency + bufferDuration) sottostima di
    // ~15ms perché non include il pre-roll AVAudioPlayerNode (1-2 buffer
    // in coda). Verificato 12/05/2026 da test su device: SB anticipava di
    // ~15ms = 0.035 beat a 140 BPM. Sotto soglia DIRECTOR-ASSERT 0.04 →
    // nessuna correzione automatica, ma percettibile all'orecchio.
    //
    // Chiamabile da audioQueue.
    private func nextBufferOutputHostTime() -> UInt64 {
        let now = mach_absolute_time()
        if let renderTime = self.playerNode.lastRenderTime,
           renderTime.isHostTimeValid {
            let result = renderTime.hostTime
                       + self.bufferDurationTicks
                       + self.outputLatencyTicks
            os_log("[Q-BEATS][L1bSync] nextBufferOutputHostTime HARDWARE — lastRender:%llu now:%llu bufDur:%llu outLat:%llu result:%llu deltaFromNow:%lld",
                   log: .default, type: .default,
                   renderTime.hostTime, now, self.bufferDurationTicks, self.outputLatencyTicks,
                   result, Int64(result) - Int64(now))
            return result
        }
        // Fallback: playerNode non running, oppure hostTime non valido.
        // Errore residuo come fix #3 (~15ms sottostimato).
        let fallback = now + self.outputLatencyTicks + self.bufferDurationTicks
        os_log("[Q-BEATS][L1bSync] nextBufferOutputHostTime FALLBACK — lastRender:nil-or-invalid now:%llu bufDur:%llu outLat:%llu result:%llu deltaFromNow:%lld",
               log: .default, type: .default,
               now, self.bufferDurationTicks, self.outputLatencyTicks,
               fallback, Int64(fallback) - Int64(now))
        return fallback
    }

    /// A420 — una generazione nuova della catena dei buffer (`BufferChainGeneration`): a ogni passaggio di `isRunning` da
    /// falso a vero (`start()`) e prima del primo buffer di ogni catena che comincia. Chiamare SOLO su audioQueue.
    private func openBufferChainQ() {
        _bufferChainGenerationQ = BufferChainGeneration.opened(after: _bufferChainGenerationQ)
        // A421 — una catena nuova fa cadere la condizione della rete del motore fermo dal sistema (par. 2.3 b).
        cancelStoppedEngineNetQ()
        // A421 · SEGUITO 1 (par. 5.3) — l'ora dell'ultimo buffer programmato si azzera a ogni catena nuova: `dallUltimoBuffer_ms`
        // dice -1 finché la catena non ha programmato.
        _lastScheduledTicksQ = 0
    }

    /// A421 · SEGUITO 1 (par. 2.2) — la stessa lettura di `nextBufferOutputHostTime`, senza la riga [L1bSync]: per le due ore
    /// del ritorno del Follower (la fine dei buffer programmati all'armo; il primo campione a volume 1 nella chiamata
    /// dell'«uno»): una riga sola, quella del ritorno. `fallback`: `lastRenderTime` non valido (la lettura di riserva, che
    /// sottostima di circa un ciclo: `firstSampleAtVolumeOneTicks` toglie un ciclo in più). Chiamare SOLO su audioQueue.
    private func nextBufferOutputReadQ() -> (ticks: UInt64, fallback: Bool) {
        if let renderTime = self.playerNode.lastRenderTime, renderTime.isHostTimeValid {
            return (renderTime.hostTime + self.bufferDurationTicks + self.outputLatencyTicks, false)
        }
        return (mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks, true)
    }

    /// A420 — IL RICHIAMO DI FINE BUFFER, SULLA CODA (mandato A420, par. 2.2): `chain` è la generazione con cui il buffer è
    /// stato programmato. Se non è la corrente, il buffer è di una catena finita (tolto da uno stop, di un lettore vecchio,
    /// o arrivato fra l'avvio del motore e il fuoco di un ingresso o di un rientro): il richiamo si scarta senza programmare
    /// niente, si conta, e scrive una riga al primo scarto e poi una ogni dieci. È la guardia che lavora, non un errore.
    /// Con la generazione corrente fa quello di sempre: la riga del buffer ancorato del rientro (`anchoredRenderTicks`),
    /// poi il buffer dopo. Chiamare SOLO su audioQueue.
    private func bufferCallbackQ(chain: Int, anchoredRenderTicks: UInt64?) {
        guard BufferChainGeneration.accepts(callbackGeneration: chain, current: _bufferChainGenerationQ) else {
            _bufferChainDiscardedQ += 1
            if BufferChainGeneration.writesDiscardLine(discarded: _bufferChainDiscardedQ) {
                os_log("[Q-BEATS][SCHED] richiamo di un'altra catena scartato catena:%d corrente:%d scartati:%d",
                       log: .default, type: .default,
                       chain, _bufferChainGenerationQ, _bufferChainDiscardedQ)
            }
            return
        }
        if let requestedRenderTicks = anchoredRenderTicks {
            anchoredBufferConsumedQ(requestedRenderTicks: requestedRenderTicks)
        }
        scheduleNextBuffer()
    }

    // Chiamare SOLO su audioQueue.
    private func scheduleNextBuffer() {
        guard isRunning, let h = metronomeHandle else { return }

        // === A421 (24/10/2026) — IL RICHIAMO TARDIVO DOPO L'ARRESTO DEL SISTEMA (mandato, par. 2.2 a) ===
        // Subito dopo la guardia, prima del drenaggio e del misuratore: se il motore di sistema non gira mentre `isRunning` è
        // vero, il motore l'ha fermato il sistema (il 24/10 alle 12:35:23.005, la cassa Bluetooth: 11 ms dopo, un richiamo
        // della catena corrente ha programmato un buffer e fatto l'assert che ha spostato la band). Niente buffer, quindi
        // niente assert e niente correzione; la riga e la rete a 2 s (`noteSystemStoppedEngineQ`); decide il gestore che
        // arriva (configurazione, interruzione, servizi persi). Che il valore sia già falso in quel momento è [Probabile]
        // (Apple non dice quando cambia): restano U1 e U7.
        if !self.engine.isRunning {
            self.noteSystemStoppedEngineQ()
            return
        }
        if self._stoppedEngineCallbacksQ > 0 {
            // La condizione della rete è caduta: il motore di sistema gira di nuovo (par. 2.3 b).
            os_log("[Q-BEATS][SCHED] motore di sistema di nuovo in moto dopo richiami a vuoto:%d catena:%d - rete annullata",
                   log: .default, type: .default, self._stoppedEngineCallbacksQ, self._bufferChainGenerationQ)
            self._stoppedEngineCallbacksQ = 0
            self.cancelStoppedEngineNetQ()
        }
        // A421 — U9: il battito in ritardo si decide a ogni buffer, ai due punti della correzione qui sotto.
        self._muteLateBeatThisBufferQ = false

        // === Task D refactor #18 — esponi bufferCount al render thread ===
        // Atomic snapshot del bufferCount audioQueue. Il sink block lo legge
        // per calibrare delta = sched - render al primo invocation. Pattern
        // self-calibrating, no modifica Layer 1.
        qbeats_link_pending_set_sched_buffer_count(self.linkPending,
                                                    UInt64(self.bufferCount))

        // === L1.a — Drain mode check ===
        // Se in drain (sezione finita) e tutti i playhead sono esauriti, il
        // click è stato riprodotto integralmente: dispatch closure stop ora.
        // Sample-accurate: il completion handler dell'ultimo buffer ci ha
        // svegliato esattamente quando l'audio era esaurito.
        if self._sectionEndPending
            && self.clickPlayhead < 0
            && self.accentPlayhead < 0
            && self.subdivPlayhead < 0 {
            os_log("[Q-BEATS][DRAIN] entered — bufCount:%d beatTick:%d",
                   log: .default, type: .default,
                   self.bufferCount, self.beatTickCounter)
            self._sectionEndPending = false
            let endClosure = self._pendingEndClosure
            self._pendingEndClosure = nil
            let renderInfo: String
            if let rt = self.playerNode.lastRenderTime, rt.isHostTimeValid {
                renderInfo = "valid hostTime=\(rt.hostTime)"
            } else {
                renderInfo = "INVALID"
            }
            os_log("[Q-BEATS][L1bSync] drain completato → onSectionEnd dispatch — lastRenderTime:%{public}@",
                   log: .default, type: .default,
                   renderInfo)
            // TD #16: l'engine NON emette più sectionEndedSubject. Limita
            // l'azione a dispatch della closure end-of-section registrata
            // dal callsite (DebugView in L1.a, Layer 3 in L1.b). È il
            // callsite a decidere se emettere il subject prima di stop()
            // — solo quando si tratta di fine vera della performance, non
            // di transizione fra sezioni intermedie.
            DispatchQueue.main.async { [weak self] in
                endClosure?()
            }
            os_log("[Q-BEATS][DRAIN] return — no buffer scheduled to playerNode",
                   log: .default, type: .default)
            // ⚠️ RISCRITTO A420 (23/10/2026) (risposta del referee al mandato A420, par. 4). Il testo di prima diceva «A416
            // (21/10/2026) — la catena dei buffer si ferma qui e la riprende `kickScheduling` coi suoi tre buffer: il
            // misuratore del buco riprende il riferimento dopo di loro, così la pausa non è un buco (`RenderGapMeter`).». Qui
            // si ferma un anello solo: questo richiamo non programma niente e abbassa `_sectionEndPending`, e gli altri buffer
            // in volo, ai loro richiami, programmano come sempre; la catena va avanti con un anello in meno finché qualcuno
            // non ferma il motore. `kickScheduling` non ha chiamanti dal commit `1f0a433` (BUGS,
            // `TD-kickscheduling-morto-e-doccomment-falso`).
            // ⚠️ RISCRITTO A421 (24/10/2026) — Aperto 3 di A420 (mandato A421, par. 2.2 i). Qui c'era «Il misuratore riprende
            // il riferimento qui, com'era: senza una pausa, le tre chiamate di scorta e il riferimento nuovo cadono sulla
            // catena che continua (referto A420, Aperto).» e `self._renderGapMeterQ.restart(sampleRate: self.sampleRate)`. Da
            // A421 la ripartenza del misuratore al drenaggio non c'è più: la catena non si ferma, e il misuratore resta sveglio
            // fino allo Stop (`RenderGapMeterTests`, il drenaggio con più richiami in volo: nessun buco finto).
            return
        }

        // === Task D fix #1 pre-apply RIMOSSO (refactor #18) ===
        // Il pre-apply non conosceva l'offset del downbeat nel buffer
        // (metronome_processBuffer non ancora chiamato). L'arming pending
        // audio-thread richiede l'offset preciso, che è disponibile SOLO
        // nel beat callback DOPO metronome_processBuffer (vedi loop beat
        // più sotto). L'arming è ora unificato nel beat callback.

        // === A416 (21/10/2026) — IL BUCO DEL RENDER (mandato «USCITA-AUDIO-PASSO-1», §2.3) ===
        // Prima del blocco della fase: lo scarto fra l'orologio e i campioni programmati (`RenderGapMeter`). Aritmetica su
        // numeri che il motore ha già, su questa coda.
        // ⚠️ RISCRITTO A421 (24/10/2026). Qui si diceva «SOLO REGISTRO [...] Un buco scrive una riga [RENDER] e basta:
        // l'assert del Direttore e la correzione del Follower restano come sono (la cura è del passo 2).». Da A421 (mandato
        // A421, U7 e U8; `RenderGapDecision`) il buco decide: col Direttore a show aperto, in canzone e in moto, da 75 ms in
        // su è una crisi («buco-del-render»: il silenzio, l'arresto locale, il ritorno dopo l'assestamento) e il buffer del
        // buco non si programma, né assert né correzione; sotto la soglia in canzone, e fuori da una canzone per ogni buco
        // sopra la soglia della riga, il Direttore segue Link fino al Play dopo (`_directorFollowsLinkQ`) e la correzione nel
        // buffer del buco resta; Follower e Solo: la riga e basta. La riga [RENDER] scrive l'esito vero.
        let gapNowTicks = mach_absolute_time()
        if case .gap(let renderGap) = self._renderGapMeterQ.observe(nowTicks: gapNowTicks, bufferCount: self.bufferCount,
                                                                    sampleRate: self.sampleRate) {
            let gapOutcome = RenderGapDecision.outcome(holeSeconds: renderGap.holeSeconds,
                                                       playerRole: self.playerRoleQ,
                                                       showOpen: self._showOpenQ,
                                                       songInProgress: self._songInProgressQ,
                                                       engineRunning: self.isRunning,
                                                       followsLink: self._directorFollowsLinkQ,
                                                       silentInSong: self._directorSilentInSongQ)
            self.logRenderGapQ(renderGap, nowTicks: gapNowTicks, outcome: gapOutcome)
            switch gapOutcome {
            case .crisis:
                self.handleRenderGapCrisisQ(renderGap)
                return
            case .followLink:
                if !self._directorFollowsLinkQ {
                    self._directorFollowsLinkQ = true
                    os_log("[Q-BEATS][DIR-RIENTRO] segue Link innesco:%{public}@ buco_ms:%.1f - niente assert fino al Play dopo (U8)",
                           log: .default, type: .default,
                           RenderGapDecision.followLinkTrigger(showOpen: self._showOpenQ, songInProgress: self._songInProgressQ),
                           renderGap.holeSeconds * 1000.0)
                }
            case .lineOnly:
                break
            }
            // A421 · SEGUITO 1 (par. 2.2) — un buco visto dal misuratore con un ritorno del Follower armato: si riarma con la
            // stessa regola, e le due ore si rifanno da questa chiamata, la prima dopo il buco (senza, un buco cominciato dopo
            // la chiamata dell'armo faceva uscire a volume 1 i buffer programmati prima del buco: LIBRO :447).
            self.rearmFollowerReturnQ(reason: String(format: "buco del render %.1f ms", renderGap.holeSeconds * 1000.0))
        }

        // A421 — par. 2.2 c: il ritorno del Follower prenotato alla notizia (o al tocco) si arma alla prima chiamata dopo: qui,
        // coi buffer programmati fino a questa chiamata, compreso quello che produce.
        self.armFollowerReturnIfPendingQ(nowTicks: gapNowTicks)

        // A416 — in più la frequenza del DSP (lo specchio di `applySampleRateQ`) e quella del nodo d'uscita (mandato §2.7,
        // riga 3). `hardwareSR` resta la frequenza della sessione, com'era. A421 — e `volume:0|1`, lo stato «uscita zittita»
        // (U3 b), e `battitiZittiti:` (U9: il conto dall'avvio del motore; in una canzone senza buchi, zero).
        if bufferCount == 0 || bufferCount % 100 == 0 {
            os_log("[Q-BEATS][SCHED] bufCount:%d hardwareSR:%.0f nodeSR:%.0f dspSR:%.0f uscitaSR:%.0f volume:%d battitiZittiti:%d",
                   log: .default, type: .default,
                   bufferCount, AVAudioSession.sharedInstance().sampleRate, self.sampleRate,
                   self._dspSampleRateQ, self.outputSampleRateQ(), self._outputSilenceQ.muted ? 0 : 1, self._lateBeatsMutedQ)
        }
        // A421 — l'ora d'uscita di questo buffer (la convenzione della correzione di fase, `_bufferOutTicksQ`) e il battito del
        // DSP al suo inizio: per il buffer dell'«uno» del ritorno del Follower (par. 2.2 c) e per l'«uno» uscito DA-SOLO.
        var thisBufferOutTicks: UInt64 = gapNowTicks + outputLatencyTicks + bufferDurationTicks
        var bufferStartBeat: Double = 0
        if let mh = midiEngineHandle {
            midi_engine_sync_clock(mh,
                UInt64(bufferCount) * UInt64(bufferSize),
                mach_absolute_time(),
                sampleRate)
            // === Phase sync Link (Phase Correction Policy v1.2) + diagnostica restart ===
            if let lh = linkEngineHandle, let mh = midiEngineHandle {
                let hostTimeAtOutput = mach_absolute_time()
                                     + outputLatencyTicks
                                     + bufferDurationTicks
                let currentBeat = midi_engine_get_beat_position(mh)
                var newBeat: Double = 0.0
                // A386 · B2c — l'ora d'uscita di questo buffer, per l'ora dell'ultimo battito
                // (riga al secondo di DA SOLO). Una scrittura di un intero, su questa coda.
                self._bufferOutTicksQ = hostTimeAtOutput
                // A412 — i tre buffer del rientro escono dall'ora chiesta al lettore (il primo ancorato, gli
                // altri due di seguito), non dalla convenzione qui sopra: l'ora dei loro battiti è quella vera,
                // per un'àncora presa subito dopo. La correzione di fase in quei buffer non gira (salto di 3).
                if self._anchoredPreRollLeftQ > 0 {
                    let index = UInt64(3 - self._anchoredPreRollLeftQ)
                    let bufferTicks = self.secondsToMachTicks(Double(self.bufferSize) / self.sampleRate)
                    self._bufferOutTicksQ = self._anchoredOutputTicksQ + index * bufferTicks
                    self._anchoredPreRollLeftQ -= 1
                }
                thisBufferOutTicks = self._bufferOutTicksQ
                if self.linkSyncSkipBuffers > 0 {
                    self.linkSyncSkipBuffers -= 1
                    os_log("[Q-BEATS][LINK] sync skip — buffer rimanenti:%d",
                           log: .default, type: .default, self.linkSyncSkipBuffers)
                } else if !self.soloLockPassesQ(.phaseCorrection) {
                    // A411 · SOLO-INERTE — nel Solo nessuna correzione di fase, né l'assert del ruolo
                    // Direttore con la levetta spenta né `link_engine_sync_phase`: il click va col suo
                    // orologio, come a Link spento (dove `sync_phase` esce senza correggere). Nessuna riga:
                    // gira a ogni buffer.
                } else if _linkMode == .direttore && !self._directorFollowsLinkQ {
                    // A412 — dopo un rientro il Direttore segue Link (il ramo `link_engine_sync_phase` qui
                    // sotto) fino all'avvio dopo (scelta T4): niente assert, che riscriverebbe la griglia di
                    // tutti con la posizione del rientro.
                    // Modalità Direttore in play (siamo dentro scheduleNextBuffer,
                    // quindi isRunning è già garantito true dal guard a riga 1359).
                    // Q-BEATS impone BPM e fase al session state in un singolo
                    // capture/commit atomico — vedi rationale in
                    // link_engine_assert_session_state. Risolve il drift di fase
                    // post-deviazione peer (test D2, build #333).
                    if self._linkSyncLogBuffers > 0 {
                        self._linkSyncLogBuffers -= 1
                        os_log("[Q-BEATS][AssertSync] hostTimeAtOutput:%llu audioBPM:%.1f beatTick:%d",
                               log: .default, type: .default,
                               hostTimeAtOutput, self._audioBPM, self.beatTickCounter)
                    }
                    link_engine_assert_session_state(lh, hostTimeAtOutput,
                                                    currentBeat, _audioBPM)
                } else if !self.followsLinkQ() {
                    // A386 · FASE B2c (2D) — DA SOLO LA CORREZIONE DI FASE DI LINK NON SI ESEGUE.
                    // È la seconda delle due strade da cui la sessione Link arriva al click del
                    // Follower, ed è quella che ne fa il tempo: in IN SYNC `link_engine_sync_phase`
                    // (ramo qui sotto) riporta la posizione sulla linea del tempo di Link a ogni
                    // buffer, e il click va al tempo della SESSIONE qualunque sia il tempo del
                    // metronomo (collaudo dell'01/10/2026: 4851 correzioni su 4867 buffer, e 141
                    // al posto di 121 dal ricollegamento). In DA SOLO — e nella coda prima
                    // dell'arresto — Link non si chiama nemmeno: la posizione si riporta, con la
                    // stessa meccanica, sulla LINEA DEL TEMPO PROPRIA (`ownClockPinQ`,
                    // `OwnClockTimeline`), fatta dell'ora dell'apparecchio e del tempo della
                    // propria sezione. Il contatore di sezione continua a contare i battiti che
                    // escono. Decisione pura `FollowerLinkFollowDecision`, letta dalla copia di
                    // coda della macchina.
                    self.ownClockPinQ(midi: mh, metronome: h,
                                      hostTimeAtOutput: hostTimeAtOutput, currentBeat: currentBeat)
                } else if let lead = self._rejoinLeadInQ,
                          !DirectorRejoinDecision.leadInAllowsCorrection(correctionsSoFar: lead.corrections) {
                    // A412 · SEGUITO 2 (2/2) — nella scorta muta la correzione di fase gira una volta sola: la prima, che
                    // la scorta copre. Quelle di regime ripartono col buffer dopo l'«uno»: una di regime qui, con
                    // l'«uno» appena dopo l'inizio di un buffer, lo scavalcherebbe. Nessuna riga a buffer: il conto
                    // sta nella riga del primo click.
                } else if link_engine_sync_phase(lh, hostTimeAtOutput, currentBeat, &newBeat) {
                    midi_engine_set_beat_position(mh, newBeat)
                    // Bug 2.b — solo timeline a campioni: la fase di battuta resta
                    // governata dal contatore di sezione (no riscrittura _currentBeatInBar).
                    metronome_set_beat_position_time_only(h, newBeat)
                    // A421 — U9: il primo punto della correzione (la fase di Link): il battito scavalcato che uscirebbe in
                    // ritardo di almeno un buffer si conta e non si suona.
                    self.noteLateBeatCorrectionQ(before: currentBeat, after: newBeat, bpm: self._engineTempoQ, point: "fase-link")
                    os_log("[Q-BEATS][LINK] Phase sync: %.4f → %.4f beats",
                           log: .default, type: .default,
                           currentBeat, newBeat)
                    // A412 · SEGUITO 2 (2/2) — la correzione fatta nella scorta, per la riga del primo click.
                    if var lead = self._rejoinLeadInQ {
                        lead.corrections += 1
                        lead.correctionBeats += newBeat - currentBeat
                        self._rejoinLeadInQ = lead
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.currentBeat = newBeat
                    }
                    if bufferCount <= 2 {
                        os_log("[Q-BEATS][LINK][RESTART] buffer #%d: correction %.4f → %.4f (delta=%.4f)",
                               log: .default, type: .default,
                               bufferCount, currentBeat, newBeat, newBeat - currentBeat)
                    }
                } else if bufferCount <= 2 {
                    os_log("[Q-BEATS][LINK][RESTART] buffer #%d: beat=%.4f — no correction",
                           log: .default, type: .default,
                           bufferCount, currentBeat)
                }
            }

            // A412 · SEGUITO 2 (2/2) — nella scorta muta il MIDI (clock e pattern) tace finché l'«uno» non cade in questo
            // buffer (`DirectorRejoinDecision.leadInHoldsMIDI`): i buffer prima della prima correzione hanno la
            // posizione di prima, e quelli dopo ripasserebbero sugli stessi impulsi. La posizione del motore resta
            // quella di sempre: il sequencer calcola ogni buffer dalla posizione (`MIDISequencer::processBuffer`).
            // A421 — il battito del DSP all'inizio di questo buffer, dopo le correzioni (per l'«uno» uscito, più sotto).
            bufferStartBeat = midi_engine_get_beat_position(mh)
            var midiHeld = false
            if var lead = self._rejoinLeadInQ, lead.midiHeld {
                if DirectorRejoinDecision.leadInHoldsMIDI(bufferStartBeat: midi_engine_get_beat_position(mh),
                                                          bufferBeats: lead.bufferBeats,
                                                          unoBeat: lead.plan.unoBeat) {
                    midiHeld = true
                } else {
                    lead.midiHeld = false
                    self._rejoinLeadInQ = lead
                }
            }
            if !midiHeld {
                midi_engine_process(mh, UInt32(bufferSize))
            }
        }
        // A421 — par. 2.2 c: se questo buffer porta l'«uno» del ritorno del Follower, il volume torna adesso, prima che il DSP
        // calcoli il battito (U3 c).
        self.checkFollowerReturnQ(bufferOutputTicks: thisBufferOutTicks)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        guard let dst = buffer.floatChannelData?[0] else { return }
        for i in 0..<Int(bufferSize) { dst[i] = 0.0 }

        // === L1.a — Drain mode: skip metronome_processBuffer ===
        // Durante il drain non chiediamo nuovi beat events al motore C++:
        // questo evita che vengano generati click "fantasma" in attesa che
        // il drain finisca. I playhead esistenti (clickPlayhead/accent/subdiv)
        // continuano comunque a essere drenati nel buffer corrente sotto.
        let beatCount: UInt32
        if self._sectionEndPending {
            beatCount = 0
        } else {
            beatCount = metronome_processBuffer(h, UInt32(bufferSize), &offsets, &accents, &isBeats, UInt32(maxBeats))
        }
        bufferCount += 1
        beatTotal   += Int(beatCount)

        let muteGain: Float = self._clickMuted ? 0.0 : 1.0

        if clickPlayhead >= 0 && !clickSamples.isEmpty {
            let remaining = clickSamples.count - clickPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(beatVolume) * muteGain
            for j in 0..<writeLen { dst[j] += clickSamples[clickPlayhead + j] * gain }
            clickPlayhead += writeLen
            if clickPlayhead >= clickSamples.count { clickPlayhead = -1 }
        }

        if accentPlayhead >= 0 && !accentedClickSamples.isEmpty {
            let remaining = accentedClickSamples.count - accentPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(accentVolume) * muteGain
            for j in 0..<writeLen { dst[j] += accentedClickSamples[accentPlayhead + j] * gain }
            accentPlayhead += writeLen
            if accentPlayhead >= accentedClickSamples.count { accentPlayhead = -1 }
        }

        if subdivPlayhead >= 0 && !subdivisionClickSamples.isEmpty {
            let remaining = subdivisionClickSamples.count - subdivPlayhead
            let writeLen  = min(remaining, Int(bufferSize))
            let gain      = Float(subdivVolume) * muteGain
            for j in 0..<writeLen { dst[j] += subdivisionClickSamples[subdivPlayhead + j] * gain }
            subdivPlayhead += writeLen
            if subdivPlayhead >= subdivisionClickSamples.count { subdivPlayhead = -1 }
        }

        if beatCount > 0 {
            if let mh = midiEngineHandle {
                let currentBeatNow = midi_engine_get_beat_position(mh)
                DispatchQueue.main.async { [weak self] in
                    self?.currentBeat = currentBeatNow
                }
            }
            for i in 0..<Int(beatCount) {
                let offset   = Int(offsets[i])
                let isAccent = accents[i]  != 0
                let isBeat   = isBeats[i]  != 0

                // A412 · SEGUITO 2 (2/2) — LA SCORTA È MUTA: prima dell'«uno» nessun click e niente da contare. Una
                // suddivisione del battito prima può cadere nella scorta (tempo veloce e swing): si salta. Il primo
                // battito è l'«uno»: la sua riga, poi tutto come sempre (contatore, LED, campioni).
                if self._rejoinLeadInQ != nil {
                    if !isBeat { continue }
                    self.noteRejoinFirstClickQ(offset: offset)
                }

                // A421 — U9: dopo una correzione che scavalca il battito pendente, il DSP fa uscire quel battito al primo
                // campione di questo buffer (il fire-asap): se uscirebbe in ritardo di almeno un buffer
                // (`noteLateBeatCorrectionQ`) si conta — contatore, LED, sezione — e non si suona: niente campioni e niente
                // coda armata, più sotto. Il contatore di sospetto: la correzione ha alzato il segno ma il primo evento non è
                // un battito al primo campione.
                let muteThisEvent = self._muteLateBeatThisBufferQ && i == 0 && isBeat && offset == 0
                if self._muteLateBeatThisBufferQ && i == 0 {
                    if muteThisEvent {
                        self._lateBeatsMutedQ += 1
                        os_log("[Q-BEATS][USCITA] battito in ritardo zittito n:%d battito:%d buffer:%d - contato, non suonato (U9)",
                               log: .default, type: .default, self._lateBeatsMutedQ, self.beatTickCounter + 1, self.bufferCount)
                    } else {
                        os_log("[Q-BEATS][USCITA] correzione che scavalca ma il primo evento non e' un battito al primo campione battito:%d scostamento:%d buffer:%d - niente da zittire",
                               log: .default, type: .default, isBeat ? 1 : 0, offset, self.bufferCount)
                    }
                }

                if isBeat {
                    // A421 — l'«uno» uscito, sulla griglia del DSP (il battito all'inizio del buffer più lo scostamento), per il
                    // ritorno del Follower DA-SOLO (par. 2.2 c): il primo battito di una battuta del contatore di sezione, o
                    // l'accento dove la sezione non conta.
                    let unoByCounter = self._sectionTotalBeats > 0
                        && self._sectionBeatCounter % Int(max(self._beatsPerBarQ, 1)) == 0
                    if unoByCounter || (self._sectionTotalBeats <= 0 && isAccent) {
                        self._lastUnoBeatQ = bufferStartBeat + Double(offset) / self.sampleRate * self._audioBPM / 60.0
                    }
                    self.beatTickCounter += 1
                    // A386 · B2c — il campione del flusso d'uscita su cui cade questo battito
                    // (i buffer vanno al player uno dietro l'altro: indice × 512 + scostamento;
                    // `bufferCount` è già stato alzato per questo buffer). Lo legge la riga al
                    // secondo di DA SOLO per misurare il tempo che esce davvero. Una scrittura
                    // di un intero, su questa coda. E la sua ora d'uscita: l'ora d'uscita del
                    // buffer più lo scostamento del battito dentro il buffer.
                    self._lastBeatSampleQ = Int64(self.bufferCount - 1) * Int64(self.bufferSize) + Int64(offset)
                    self._lastBeatOutTicksQ = self._bufferOutTicksQ
                        + self.secondsToMachTicks(Double(offset) / self.sampleRate)
                    // A416 — il riferimento della riga del tempo del click (ogni 32 battiti, più sotto), al primo battito
                    // di ogni avvio.
                    if self.beatTickCounter == 1 {
                        self._tempoLogRefTickQ = 1
                        self._tempoLogRefOutTicksQ = self._lastBeatOutTicksQ
                        self._tempoLogRefSampleQ = self._lastBeatSampleQ
                    }
                    // A410 — il battito appena contato, per l'àncora del conteggio in silenzio: la
                    // sezione della mappa e il battito nella sezione (da 0: il contatore di sezione
                    // PRIMA del suo incremento, più sotto; -1 in un ciclo, dove il contatore non
                    // conta), con l'ora d'uscita qui sopra. Due scritture di valore, su questa coda.
                    self._prevCountedBeatQ = self._lastCountedBeatQ
                    self._lastCountedBeatQ = CountedBeat(section: self._songMapSectionQ,
                                                         beatInSection: self._sectionTotalBeats > 0 ? self._sectionBeatCounter : -1,
                                                         outTicks: self._lastBeatOutTicksQ)
                    let tickN = self.beatTickCounter
                    DispatchQueue.main.async { [weak self] in
                        self?.beatTickSubject.send(tickN)
                    }

#if QB_DIAG_SPY
                    // SPIA passiva L3 — per OGNI beat: asse CONTATORE + riferimento griglia
                    // (gridBeat = engine beat, sincronizzato a Link). Campi GREZZI: la fase
                    // derivata round(gridBeat − sectionStartMarker) % bpbQ si calcola al FLUSH.
                    // L'asse ACCENTO (_currentBeatInBar) arriva dal ring L1 (join beatTick↔seq).
                    if let mhSpy = self.midiEngineHandle {
                        let gridBeat = midi_engine_get_beat_position(mhSpy)
                        if self._spyMarkerPending {
                            self._spySectionStartMarker = gridBeat   // SOLA LETTURA, marker passivo
                            self._spyMarkerPending = false
                        }
                        os_log("[Q-BEATS][Bug2b-SPY-L3] beatTick:%d sectionBeatCounter:%d sectionInstance:%d bpbQ:%u gridBeat:%.4f sectionStartMarker:%.4f offset:%d",
                               log: .default, type: .default,
                               self.beatTickCounter, self._sectionBeatCounter,
                               self._spySectionInstanceIdx, self._beatsPerBarQ,
                               gridBeat, self._spySectionStartMarker, offset)
                    }
#endif

                    if self.beatTickCounter % 32 == 0 {
                        let sinkCount = qbeats_link_pending_get_render_buffer_id(self.linkPending)
                        os_log("[Q-BEATS][SinkDiag-AQ] relay — renderBufferId:%llu beatTick:%d",
                               log: .default, type: .default, sinkCount, self.beatTickCounter)
                        // A416 — accanto, il tempo del click misurato (mandato «USCITA-AUDIO-PASSO-1», §2.7, riga 5).
                        self.logClickTempoQ()
                    }

                    // === Task D — Propagazione BPM al downbeat target (refactor #18) ===
                    // Il DSP C++ ha appena applicato _pendingBPM a _bpm
                    // (atomic exchange in processBuffer, sample-accurate a
                    // _currentBeatInBar==0). Ora propaghiamo:
                    //   1. _audioBPM mirror (Nota 1 referee — PRIMA di tutto: il
                    //      render thread può leggere il pending tra qui e l'arming,
                    //      _audioBPM deve già contenere il nuovo valore per il
                    //      Direttore re-broadcast del tempo callback Link)
                    //   2. MIDI engine re-anchor (Strada E fix #2 invariato)
                    //   3. Branch esplicito audio-thread vs fallback warm-up
                    //      (Nota 3 referee — niente silent no-op)
                    //   4. UI dispatch
                    if let pending = self._pendingBPMValue,
                       self.beatTickCounter == self._pendingBPMTargetTick {
                        // [Nota 1] _audioBPM PRIMA di tutto
                        self._audioBPM = pending
                        // A386 · B2c — il DSP ha appena preso il tempo della sezione nuova: il
                        // tempo in corso è quello della propria canzone, non uno adottato da Link.
                        // La linea propria, se c'è, aveva il tempo di prima: si butta, e si
                        // ri-àncora col tempo nuovo al primo buffer dopo la finestra di sospensione
                        // del cambio di sezione (`ownClockPinQ`).
                        self._linkTempoAdoptedQ = nil
                        self._engineTempoQ = pending
                        self._ownTimelineQ = nil
                        // L1.b sync investigation — abilita log DIRECTOR-ASSERT per 3 buffer
                        self._linkSyncLogBuffers = 3

                        // MIDI re-anchor (Strada E fix #2 invariato)
                        if let mh = self.midiEngineHandle {
                            let preChangeBeatPos = midi_engine_get_beat_position(mh)
                            midi_engine_set_bpm(mh, pending)
                            midi_engine_set_beat_position(mh, preChangeBeatPos)
                        }

                        // === Step 2 — broadcast Link da audioQueue ===
                        // Il path tap broadcast è disattivato (vedi installLinkTap):
                        // il design del delta non regge l'asimmetria sched-vs-render
                        // rate (~100/s vs ~10/s in pratica), il match buffer-id non
                        // scatta mai. Broadcast diretto qui, single-threaded, con
                        // hostTime sample-accurate = nextBufferOutputHostTime +
                        // ticksOffset del downbeat dentro il buffer.
                        // === Step 4 (15/05/2026) — broadcast atomic tempo + fase ===
                        // Sostituisce link_engine_set_bpm_at_time (solo tempo) con
                        // link_engine_set_bpm_and_beat_at_time (tempo + fase nello
                        // stesso session commit). Risolve drift sistemico 0.02-0.09
                        // beat ai cambi BPM (test L2.b 15/05/2026 sera, riprodotto
                        // su Tick e Metronome Pro, numeri identici entro 20%).
                        // RIENTRO-P1 (A366) — la terza condizione è l'interruttore SOLO DEBUG
                        // della prova A/B (decisione 9.1): in Release rende sempre falso e
                        // questo blocco è quello di sempre; in DEBUG salta W2 solo sul Follower
                        // con l'interruttore spento. Vedi `followerBoundaryTempoWriteSkipped`.
                        // ⚠️ MARCATURA A386 · B2c-BIS — la stessa condizione salta W2, in ogni
                        //    configurazione, anche quando il Follower è sul proprio orologio (DA
                        //    SOLO, e la coda prima dell'arresto): da solo non scrive in Link.
                        // ⚠️ A411 · SOLO-INERTE — in testa il lucchetto del Solo: nel Solo W2 non esce
                        //    (`soloInertSkipsBoundaryTempoWriteQ` scrive la riga), e la regola del Follower
                        //    qui sotto non si chiede nemmeno.
                        if let lh = self.linkEngineHandle, let mh = self.midiEngineHandle,
                           !self.soloInertSkipsBoundaryTempoWriteQ(bpm: pending),
                           !self.followerBoundaryTempoWriteSkipped(bpm: pending) {
                            let sampleOffset = UInt32(offset)
                            let nanosOffset = Double(sampleOffset) / self.sampleRate * 1.0e9
                            let ticksOffset = UInt64(nanosOffset * Double(self.machTimebase.denom) / Double(self.machTimebase.numer))
                            // Step 2.5 — pre-roll AVAudioPlayerNode: ~2 buffer in coda davanti
                            // al buffer che stiamo riempiendo (pre-roll iniziale 3 buffer
                            // righe 586-588 + completion handler scheduleNextBuffer mantengono
                            // steady-state ~2 in coda). nextBufferOutputHostTime punta al
                            // prossimo buffer da renderizzare; il nostro è dietro di preRollTicks.
                            let preRollTicks = 2 * self.bufferDurationTicks
                            let hostTime = self.nextBufferOutputHostTime() + preRollTicks + ticksOffset
                            let currentBeat = midi_engine_get_beat_position(mh)
                            link_engine_set_bpm_and_beat_at_time(lh, pending, currentBeat, hostTime)
                            os_log("[Q-BEATS][TaskD-AQ] broadcast — bpm:%.1f beatNow:%.4f sampleOffset:%d ticksOffset:%llu preRollTicks:%llu bufDurTicks:%llu hostTime:%llu",
                                   log: .default, type: .default,
                                   pending, currentBeat, sampleOffset, ticksOffset, preRollTicks, self.bufferDurationTicks, hostTime)
                        }

                        // UI dispatch (invariato)
                        let valueForMain = pending
                        DispatchQueue.main.async { [weak self] in
                            self?.currentBPM = valueForMain
                        }

                        // Reset stato pending Swift
                        self._pendingBPMValue = nil
                        self._pendingBPMTargetTick = 0
                    }

                    // QA-1 drift analysis — eseguito su audioQueue
                    if self.qa1BeatCounter == 0 {
                        self.qa1StartTime = mach_absolute_time()
                    }
                    self.qa1BeatCounter += 1

                    if self.qa1BeatCounter % 100 == 0 {
                        let elapsed = self.machTicksToSeconds(mach_absolute_time() - self.qa1StartTime)
                        let expected = Double(self.qa1BeatCounter - 1) * 60.0 / self.currentBPM
                        let deltams = (elapsed - expected) * 1000.0
                        os_log("QA1 beat=%{public}llu expected=%.3fs elapsed=%.3fs delta=%{public}.2fms",
                               log: .default, type: .default,
                               self.qa1BeatCounter, expected, elapsed, deltams)
                    }

                    // === L1.a — Stop a fine ultima ripetizione (drain-based) ===
                    // _sectionTotalBeats > 0 → sezione con limite caricata via loadSection.
                    // Incremento contatore + check fine. NESSUN dispatch immediato:
                    // settare _sectionEndPending attiva il drain mode, che skippa
                    // metronome_processBuffer (no beat fantasma) e drena clickPlayhead
                    // residuo nei buffer successivi. Quando tutti i playhead sono
                    // esauriti (controllo all'inizio di scheduleNextBuffer), il
                    // dispatch della closure arriva sample-accurate.
                    if self._sectionTotalBeats > 0 {
                        self._sectionBeatCounter += 1
                        if self._sectionBeatCounter >= self._sectionTotalBeats {
                            // Strada A — Distingue ramo SEAMLESS (transizione
                            // intra-canzone con preload) da ramo DRAIN
                            // (standby / fineSetlist).
                            if self._pendingNextSectionTotalBeats != nil {
                                // === RAMO SEAMLESS ===
                                os_log("[Q-BEATS][SEAMLESS] fine sezione — swap atomico (Strada A)",
                                       log: .default, type: .default)

                                // (a) Cattura locali — prima di qualsiasi reset.
                                let closureToDispatch    = self._onSectionEnd
                                let pendingBPB           = self._pendingNextBPB!
                                let pendingBPM           = self._pendingNextBPM!
                                let pendingAccentPattern = self._pendingNextAccentPattern!
                                let pendingTotalBeats    = self._pendingNextSectionTotalBeats!
                                let pendingOnSectionEnd  = self._pendingNextOnSectionEnd
                                let pendingRepetitions   = self._pendingNextRepetitions!
                                // ATOM C — sempre valorizzati insieme agli altri
                                // (stessa preloadNextSection), stesso force-unwrap.
                                let pendingSubdivMult    = self._pendingNextSubdivisionMultiplier!
                                let pendingSwing         = self._pendingNextSwingRatio!

                                // (b) Reset _pendingNext* (safe — locali già catturati).
                                self._pendingNextBPB = nil
                                self._pendingNextBPM = nil
                                self._pendingNextAccentPattern = nil
                                self._pendingNextSectionTotalBeats = nil
                                self._pendingNextOnSectionEnd = nil
                                self._pendingNextRepetitions = nil
                                self._pendingNextSubdivisionMultiplier = nil
                                self._pendingNextSwingRatio = nil

                                // (c) Swap contatori Swift.
                                // _sectionEndPending resta false — il ramo SEAMLESS
                                // non entra mai in drain mode.
                                // _audioBPM assegnato presto per coerenza col bypass
                                // DIRECTOR-ASSERT via linkSyncSkipBuffers (step f).
                                self._sectionTotalBeats = pendingTotalBeats
                                self._sectionBeatCounter = 0
                                // A410 — la sezione della mappa che il motore conta passa alla dopo.
                                if self._songMapSectionQ >= 0 {
                                    self._songMapSectionQ += 1
                                }
                                self._onSectionEnd = pendingOnSectionEnd
                                self._beatsPerBarQ = pendingBPB
                                self._audioBPM = pendingBPM

#if QB_DIAG_SPY
                                // SPIA passiva: nuova sezione → ri-cattura il marker griglia
                                // al 1° beat della sezione e incrementa l'indice di sezione.
                                self._spySectionInstanceIdx += 1
                                self._spyMarkerPending = true
#endif

                                // (d) Arm DSP Layer 1 — atomic exchange al downbeat
                                // di transizione. Conversione accent UI→DSP:
                                // UI usa 2=accent, 1=beat, 0=subdiv;
                                // DSP usa 1=accent, 0=beat (no subdiv).
                                let dspPattern: [UInt8] = pendingAccentPattern.map {
                                    $0 == 2 ? UInt8(1) : UInt8(0)
                                }
                                metronome_schedule_bpb_change(h, pendingBPB)
                                dspPattern.withUnsafeBufferPointer { ptr in
                                    metronome_schedule_accent_pattern_change(
                                        h, ptr.baseAddress, UInt32(dspPattern.count))
                                }
                                metronome_schedule_bpm_change(h, pendingBPM)
                                // ATOM C — subdivision armata allo STESSO downbeat
                                // di bpb/accent/bpm: la 1ª sub-nota della sezione
                                // entrante è sample-accurate (chiude il lag W1).
                                metronome_schedule_subdivision(h, pendingSubdivMult, pendingSwing)

                                // (e) Arm Link — quantum aggiornato per il nuovo BPB.
                                if let lh = self.linkEngineHandle {
                                    link_engine_set_quantum(lh, Double(pendingBPB))
                                }

                                // (f) Disabilita DIRECTOR-ASSERT per 100 buffer (~1s)
                                // durante la transizione, coerente con scheduleBPMChange.
                                self.linkSyncSkipBuffers = max(self.linkSyncSkipBuffers, 100)

                                // (g) Arm Swift BPM — il broadcast Link/MIDI/UI
                                // al downbeat target viene fatto al prossimo beat
                                // (dal blocco "if let pending = self._pendingBPMValue"
                                // più sopra in questo stesso loop, alla prossima
                                // invocazione di scheduleNextBuffer).
                                self._pendingBPMValue = pendingBPM
                                self._pendingBPMTargetTick = self.beatTickCounter + 1

                                // (h) Dispatch @Published su main.
                                // Invariante architetturale: in Studio non esistono
                                // _pendingNext* armati (niente setlist), quindi
                                // _suppressBeatsPerBarDidSet non viene mai settato.
                                // In Live la UI Studio non è accessibile.
                                // Nessun conflitto possibile.
                                DispatchQueue.main.async { [weak self] in
                                    guard let self else { return }
                                    self._suppressBeatsPerBarDidSet = true
                                    self.beatsPerBar = pendingBPB
                                    self.currentAccentPattern = pendingAccentPattern
                                    self.currentSectionRepetitions = pendingRepetitions
                                }

                                // (i) Dispatch closure SetlistRunner su main.
                                // Se stopSync arriva tra lo swap (audioQueue) e
                                // questo dispatch, la closure può eseguire dopo lo
                                // stop — gli effetti vengono usati al resume o
                                // sovrascritti al restart (vedi tech debt OSS2
                                // su epoch counter, fix post-validazione device).
                                DispatchQueue.main.async {
                                    closureToDispatch?()
                                }

                            } else {
                                // === RAMO DRAIN (invariato) — standby / fineSetlist ===
                                os_log("[Q-BEATS][L1.a] fine ultima ripetizione — beat:%d/%d → drain mode",
                                       log: .default, type: .default,
                                       self._sectionBeatCounter, self._sectionTotalBeats)
                                // Salva closure corrente per dispatch a fine drain.
                                // _sectionTotalBeats e _onSectionEnd RESTANO registrati:
                                // la sezione caricata persiste tra play/replay (utente
                                // ascolta sezione 4 battute → stop automatico → ripreme
                                // Play → si aspetta che la stessa sezione ricominci).
                                // Solo _sectionBeatCounter va azzerato per il replay.
                                // Niente double-fire durante il drain: metronome_processBuffer
                                // skippato → beatCount=0 → hook non scatta.
                                self._pendingEndClosure = self._onSectionEnd
                                self._sectionEndPending = true
                                self._sectionBeatCounter = 0
                            }
                        }
                    }
                }

                let samples: [Float]
                let gain: Float
                if isAccent    { samples = accentedClickSamples; gain = Float(accentVolume) * muteGain }
                else if isBeat { samples = clickSamples; gain = Float(beatVolume) * muteGain }
                else           { samples = subdivisionClickSamples; gain = Float(subdivVolume) * muteGain }
                // A421 — U9: il battito zittito non scrive campioni e non arma la coda del click.
                guard offset < Int(bufferSize), !samples.isEmpty, !muteThisEvent else { continue }
                let writeLen = min(samples.count, Int(bufferSize) - offset)
                for j in 0..<writeLen { dst[offset + j] += samples[j] * gain }
                if writeLen < samples.count {
                    if isAccent    { accentPlayhead = writeLen }
                    else if isBeat { clickPlayhead  = writeLen }
                    else           { subdivPlayhead = writeLen }
                }
            }
        }

        // A412 — IL PRIMO BUFFER DELLA SCORTA MUTA DEL RIENTRO, ALL'ORA (scelta T5): `scheduleBuffer(_:at:)` con un'ora di
        // host, che il lettore rispetta quando l'ora in campioni non è valida (Apple, `AVAudioPlayerNode`). I buffer
        // dopo vanno in coda come sempre. Al consumo, la riga con l'ora chiesta e l'ultimo ciclo di rendering.
        // ⚠️ RISCRITTO A412 · SEGUITO 2 (2/2) (18/10/2026). Il testo di prima diceva «A412 — IL PRIMO BUFFER DEL RIENTRO,
        // ALL'ORA (scelta T5): `scheduleBuffer(_:at:)` con un'ora di host, che il lettore rispetta quando l'ora in
        // campioni non è valida (Apple, `AVAudioPlayerNode`). I buffer dopo vanno in coda come sempre. Al consumo, la
        // riga con l'ora chiesta e l'ultimo ciclo di rendering.»: il buffer ancorato era quello del bersaglio; da qui
        // è il primo della scorta, muto, e l'«uno» esce qualche buffer dopo (`_rejoinLeadInQ`).
        // A420 — LA CATENA DEI BUFFER HA UN NUMERO (mandato A420, par. 2.2): il richiamo porta la generazione della catena
        // che ha programmato il buffer, un intero copiato qui; il confronto si fa sulla coda (`bufferCallbackQ`). Il
        // richiamo fa solo l'accodamento di sempre.
        // A421 — l'ora dell'ultimo buffer programmato, per la riga del motore fermo dal sistema (par. 2.2 a).
        self._lastScheduledTicksQ = mach_absolute_time()
        let chain = self._bufferChainGenerationQ
        if let anchoredAt = self._anchoredFirstBufferQ {
            self._anchoredFirstBufferQ = nil
            let requestedRenderTicks = anchoredAt.hostTime
            playerNode.scheduleBuffer(buffer, at: anchoredAt, options: [], completionHandler: { [weak self] in
                self?.audioQueue.async {
                    self?.bufferCallbackQ(chain: chain, anchoredRenderTicks: requestedRenderTicks)
                }
            })
            return
        }
        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.audioQueue.async { self?.bufferCallbackQ(chain: chain, anchoredRenderTicks: nil) }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification, object: nil)
        // A408 — la Lost: fra lei e la Reset il server dei servizi audio non c'è (referto A407, §3).
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaLost),
            name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaReset),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        // A408 — `object: nil`: dopo un reset dei servizi audio il motore è un'altra istanza, e un
        // osservatore legato alla prima non vedrebbe la nuova (referto A407, §2c). Il filtro sul
        // motore corrente sta in `handleEngineConfigChange`, su audioQueue.
        NotificationCenter.default.addObserver(self, selector: #selector(handleEngineConfigChange),
            name: .AVAudioEngineConfigurationChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWakeUp),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            var shouldStop = false
            var soloStop = false
            // ⚠️ RISCRITTO A420 (23/10/2026). Qui c'era «A408 — come in `stopSync`: le copie di `playerNode` ed `engine` si
            // prendono nel `sync`.», con le due copie, fermate dopo il `sync`, sul principale. Da A420 lettore e motore si
            // fermano sulla coda, in fondo al `sync` (mandato A420, par. 2.1): niente copie.
            // A412 — il motivo che il sistema dà dell'interruzione, come numero grezzo e solo per il registro
            // (Aperto del referto A412: un inizio tardivo dopo un rientro). Non si legge la chiave
            // `AVAudioSessionInterruptionWasSuspendedKey`, deprecata da iOS 14.5, e i casi del motivo non si
            // nominano. «-» = assente.
            let systemReason: String = (info[AVAudioSessionInterruptionReasonKey] as? UInt).map { String($0) } ?? "-"
            audioQueue.sync {
                // A416 · SEGUITO 2 (21/10/2026) — prima di tutto, per ogni ruolo e prima della regola delle crisi
                // (mandato «A416 · SEGUITO 2», §2.1): l'interruzione di sistema è in corso, e fino alla sua fine un cambio di
                // percorso non tocca né la sessione né il motore (`handleRouteChange`). Vale anche per il Solo, che esce
                // qui sotto senza alzare `isAudioInterrupted`, e col motore già fermo.
                self.noteSystemInterruptionQ(.began)
                // A421 · SEGUITO 1 (par. 3.2) — il contatore degli inizi, a ogni inizio (anche con lo stato già alto), prima
                // delle uscite del Solo e del Direttore già muto, mai azzerato: un inizio nuovo dopo il tentativo 0 della catena
                // del ritorno in primo piano toglie l'eccezione (`InterruptionActivationDecision`).
                self._interruptionBeginsQ += 1
                os_log("[Q-BEATS][CRISI] interruzione iniziata motivoSistema:%{public}@ inizi:%d",
                       log: .default, type: .default, systemReason, self._interruptionBeginsQ)
                // A421 — l'inizio di un'interruzione annulla i ritorni in attesa, anche col Direttore già muto (par. 2.3 b).
                self.cancelOutputReturnsQ(reason: "inizio-interruzione")
                // A421 · SEGUITO 1 (par. 3.3) — il Solo con una ripresa pendente già alzata dalla sua catena (tentativi esauriti,
                // `isOtherAudioPlaying`, `setCategory` fallito) la perde (`clearPendingResumeQ` alza anche il contatore della
                // catena e spegne la rete a 5 s) e si ferma come allo Stop della console, per la strada del Solo qui sotto, con
                // la causa ricordata «interruzione»: senza, la fine la recuperava e `RecoveryDecision` lo faceva ripartire (la
                // causa restava «configurazione»). Prima della regola delle crisi, che a motore già fermo direbbe «niente».
                if InterruptionActivationDecision.soloLosesPendingAtBegin(playerRole: self.playerRoleQ,
                                                                          pendingResume: self.pendingResume) {
                    self.clearPendingResumeQ(reason: "inizio-interruzione-solo")
                    self._crisisCauseQ = CrisisStopDecision.rememberedCause(previous: self._crisisCauseQ, new: .interruption,
                                                                            playerRole: .solo)
                    os_log("[Q-BEATS][CRISI] interruzione col Solo e la ripresa pendente in piedi - ripresa persa, causa ricordata:%{public}@, fermo come allo Stop della console",
                           log: .default, type: .default, self._crisisCauseQ?.rawValue ?? "-")
                    soloStop = true
                    return
                }
                // ⚠️ A416 · SEGUITO 2: «prima di tutto», qui sotto, vuol dire prima di ogni decisione dell'arresto; prima
                // della regola ora c'è lo stato dell'interruzione di sistema (qui sopra), che della crisi non decide niente.
                // A412 — LA REGOLA DI OGNI CRISI, prima di tutto (`CrisisStopDecision`): il Solo col click in moto
                // si ferma come allo Stop della sua console (qui sotto, fuori dal `sync`); il Direttore già muto
                // (o che aspetta il rientro a motore fermo) non ha niente da fermare; per tutti gli altri
                // l'inizio dell'interruzione di sempre, col silenzio del Direttore in canzone.
                let outcome = self.crisisOutcomeQ(cause: .interruption)
                switch outcome {
                case .soloStopAsConsole:
                    soloStop = true
                    return
                case .silentInSong where !self.isRunning:
                    // L'interruzione si segna — il tasto dice Stop, e alla fine la ripartenza passa dal
                    // coordinatore — e un ingresso armato si annulla.
                    self.isAudioInterrupted = true
                    self.cancelPendingJoin(reason: "inizio interruzione")
                    self._rejoinArmedQ = false
                    os_log("[Q-BEATS][CRISI] interruzione col Direttore gia' muto - segnata, niente da fermare",
                           log: .default, type: .default)
                    self.publishDirectorSilenceQ(context: "interruzione")
                    return
                default:
                    break
                }
                guard self.isRunning else {
                    os_log("[Q-BEATS][INTERRUPTION] began — engine già fermo, noop",
                           log: .default, type: .default)
                    return
                }
                // Salva stato Link PRIMA di fermare l'audio layer.
                // CRITICO: NON chiamare midi_engine_stop() — il sequencer C++ continua a
                // mantenere la beat position corrente. NON notificare stop a Link.
                if let lh = self.linkEngineHandle {
                    // A411 · SOLO-INERTE — Link come lo vede il motore: nel Solo spento.
                    // ⚠️ RISCRITTO A412: qui si diceva «così a fine interruzione il Solo riprende col suo
                    // battito, come a Link spento. Se il Solo debba ripartire da solo non si decide qui (passo 2
                    // del Direttore in crisi)». Deciso: il Solo a un'interruzione non arriva qui, si ferma come
                    // allo Stop della console e non riparte da solo (`CrisisStopDecision`, `RecoveryDecision`).
                    self.clockLinkWasEnabled = SoloInertDecision.engineSeesLinkOn(role: self._linkMode,
                                                                                  userLinkEnabled: self._linkUserEnabledQ,
                                                                                  linkActive: link_engine_is_enabled(lh))
                } else {
                    self.clockLinkWasEnabled = false
                }
                // CRITICO: NON salvare beat/timestamp — midi_engine_get_beat_at_time()
                // calcola la posizione corretta al momento del resume usando lastMachTime
                // e lastSamplePosition aggiornati dall'ultimo sync_clock.
                // A410 — l'àncora del conteggio in silenzio, prima che `isRunning` vada a falso.
                // A412 — solo col Direttore muto in canzone (`enterDirectorSilenceQ`, che la prende).
                if outcome == .silentInSong {
                    self.enterDirectorSilenceQ(cause: .interruption)
                }
                self.isAudioInterrupted = true
                self.isRunning          = false
                shouldStop              = true
                // RIENTRO-P1 (a) — questo arresto non passa da `stopSync`: se l'interruzione
                // cade durante l'attesa d'ingresso, l'ingresso pendente si annulla QUI.
                self.cancelPendingJoin(reason: "inizio interruzione")
                // A400 · R1 — questo arresto non passa da `stopSync`: anche il segno del proprio
                // avvio, se l'eco non è arrivato, si abbassa QUI.
                self.lowerOwnTransportStartQ(reason: "interruzione")
                // A412 — il tasto, a stato finito (interruzione in corso: Stop).
                if self._directorSilentInSongQ {
                    self.publishDirectorSilenceQ(context: "interruzione")
                }
                // A420 — L'ARRESTO SULLA CODA (mandato A420, par. 2.1): lettore e motore, qui in fondo al `sync`, nel solo
                // ramo che ferma. Fino ad A419 si fermavano qui sotto, fuori dalla coda, sulle copie prese qui dentro. Il
                // Solo si ferma con `stopSync`, qui sotto, come allo Stop della sua console.
                self.stopPlayerAndEngineQ(context: "interruzione")
                // A421 — il drenaggio consegnato (par. 2.2 j) e lo specchio di `isRunning` (par. 2.2 e), sulla coda.
                self.closeDrainOnCrisisStopQ(context: "interruzione")
                self.publishIsPlayingQ(context: "interruzione")
            }
            if soloStop {
                stopForSoloCrisis(cause: .interruption)
                return
            }
            guard shouldStop else { return }
            // A421 — `isPlaying = false` non sta più qui: lo specchio si pubblica dalla coda (par. 2.2 e).
            DispatchQueue.main.async {
                self.clickStatus = "audio muted — clock running"
            }
            os_log("[Q-BEATS][INTERRUPTION] began — audio stopped, MIDI/Link clock running",
                   log: .default, type: .default)

        case .ended:
            audioQueue.async { [weak self] in
                guard let self = self else { return }

                // A416 · SEGUITO 2 (21/10/2026) — la fine dell'interruzione di sistema, qualunque siano le opzioni, prima
                // di ogni altra strada (mandato «A416 · SEGUITO 2», §2.1). Un cambio di percorso rimandato si esegue più
                // sotto solo se questa fine passa dalla ricostruzione del grafo; se no lo esegue l'avvio (`start()`).
                self.noteSystemInterruptionQ(.ended)

                // A408 — fuori da «normale» niente ripresa e niente rebuildGraph sul motore vecchio:
                // la sessione la riattiva solo la ricostruzione, al primo avvio dopo il reset.
                if self.mediaResetSkipsQ("fine interruzione") {
                    // A412 — col Direttore muto in canzone l'interruzione è finita anche se dopo un reset non si
                    // riparte da soli: il tasto torna a dire Play se il rientro è possibile (il tocco ricostruisce
                    // e rientra, D2), invece di restare su «interruzione in corso».
                    if self._directorSilentInSongQ && self.isAudioInterrupted {
                        self.isAudioInterrupted = false
                        self.publishDirectorSilenceQ(context: "fine-interruzione-dopo-reset")
                    }
                    return
                }

                // Recovery pendingResume
                if self.pendingResume {
                    self.pendingResume = false
                    self.pendingResumeBeat = nil
                    let recoveryBeat: Double?
                    if let mh = self.midiEngineHandle {
                        let hostTime = mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks
                        recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                    } else {
                        recoveryBeat = nil
                    }
                    os_log("[Q-BEATS][RESUME] pendingResume recuperato da InterruptionEnded beat:%.4f",
                           log: .default, type: .default, recoveryBeat ?? -1.0)
                    self.activateSessionAndStart(resumeAtBeat: recoveryBeat, trigger: .pendingRecovery)
                    return
                }

                // Filtro shouldResume
                let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let shouldResume = AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
                if !shouldResume {
                    // A412 — la ripresa pendente (e la sua rete a 1 s) si rialza solo con un'interruzione attiva e
                    // nessuno Stop voluto dopo la crisi (`RecoveryDecision`; referto A410, Aperto 4): prima si
                    // rialzava sempre, anche dopo uno Stop voluto durante l'interruzione, e il click ripartiva.
                    guard RecoveryDecision.raisesPendingOnEndedWithoutResume(interruptionActive: self.isAudioInterrupted,
                                                                             wantedStopSinceCrisis: self._wantedStopSinceCrisisQ) else {
                        os_log("[Q-BEATS][RESUME] .ended senza shouldResume - ripresa pendente NON rialzata (interruzione:%d stopVoluto:%d)",
                               log: .default, type: .default,
                               self.isAudioInterrupted ? 1 : 0, self._wantedStopSinceCrisisQ ? 1 : 0)
                        return
                    }
                    os_log("[Q-BEATS][RESUME] .ended ricevuto ma shouldResume=false — Pending=true.",
                           log: .default, type: .default)
                    self.pendingResumeBeat = nil
                    self.pendingResume = true

                    // Safety net autonomo: iOS non manda eventi successivi in questo path.
                    // Dopo 2s triggeriamo recovery via activateSessionAndStart se ancora pending.
                    let capturedToken = self.currentResumeToken
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self else { return }
                        self.audioQueue.async { [weak self] in
                            guard let self = self else { return }
                            guard self.pendingResume else { return }
                            guard self.currentResumeToken == capturedToken else { return }
                            os_log("[Q-BEATS][RESUME] safety_net_shouldResume_false triggered (token:%d)",
                                   log: .default, type: .default, capturedToken)
                            self.pendingResume = false
                            self.pendingResumeBeat = nil
                            var recoveryBeat: Double? = nil
                            if let mh = self.midiEngineHandle {
                                let hostTime = mach_absolute_time()
                                             + self.outputLatencyTicks
                                             + self.bufferDurationTicks
                                recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                            }
                            self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                                         trigger: .safetyNetNoResume)
                        }
                    }
                    return
                }

                guard self.isAudioInterrupted else {
                    os_log("[Q-BEATS][INTERRUPTION] ended — nessuna interruzione attiva, noop",
                           log: .default, type: .default)
                    return
                }

                // Guardia hardware: se ancora occupato non ripartire
                let session = AVAudioSession.sharedInstance()
                let isCallActive = session.mode == .voiceChat ||
                                   session.mode == .videoChat ||
                                   session.mode == .voicePrompt ||
                                   session.category == .record ||
                                   session.category == .playAndRecord
                let silenceHint = session.secondaryAudioShouldBeSilencedHint

                if isCallActive || silenceHint {
                    os_log("[Q-BEATS][INTERRUPTION] ended — hardware ancora occupato (isCallActive:%d silenceHint:%d) — skip",
                           log: .default, type: .default, isCallActive ? 1 : 0, silenceHint ? 1 : 0)
                    if let _ = self.midiEngineHandle {
                        self.pendingResumeBeat = nil
                        self.pendingResume = true
                    }
                    return
                }

                // NON resettare isAudioInterrupted qui — lo fa activateSessionAndStart dopo setActive OK
                let linkWasEnabled = self.clockLinkWasEnabled

                // 1. Graph rebuild
                // A416 — con la frequenza dalla fonte unica, a tutte le copie (`applySampleRateQ` in `rebuildGraph`).
                // A416 · SEGUITO 2 (21/10/2026) — se durante l'interruzione un cambio di percorso è stato rimandato, si
                // esegue qui, una volta (mandato «A416 · SEGUITO 2», §2.2). La ricostruzione rilegge già frequenza e modo e
                // non si ricollega due volte; si aggiungono l'instradamento dei canali e i valori per lo schermo, come nel
                // cambio di percorso di oggi.
                let endMode = self.detectAudioMode()
                let deferredAtEnd = InterruptionRouteDecision.runDeferred(at: .interruptionEnd,
                                                                          state: self._interruptionRouteQ)
                self._interruptionRouteQ = deferredAtEnd.state
                if let reason = deferredAtEnd.reason {
                    os_log("[Q-BEATS][ROUTE] rimandato eseguito contesto:%{public}@ motivo:%{public}@",
                           log: .default, type: .default, DeferredRouteRunner.interruptionEnd.rawValue, reason)
                }
                self.rebuildGraph(for: endMode, context: "fine-interruzione")
                if deferredAtEnd.reason != nil {
                    self.applyChannelRouting(for: endMode)
                    let rateForScreen = self.sampleRate
                    DispatchQueue.main.async {
                        self.audioMode = endMode
                        self.sampleRateInfo = rateForScreen
                    }
                }

                // 2. Calcola resumeBeat DOPO setActive — il più tardi possibile
                let resumeBeat: Double?
                if let mh = self.midiEngineHandle {
                    let avSession = AVAudioSession.sharedInstance()
                    self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
                    self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
                    if let lh = self.linkEngineHandle {
                        link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
                    }
                    let hostTimeAtFirstSample = mach_absolute_time()
                                                + self.outputLatencyTicks
                                                + self.bufferDurationTicks
                    resumeBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
                } else {
                    resumeBeat = nil
                }

                // 3. Log
                os_log("[Q-BEATS][INTERRUPTION] ended — resumeBeat:%.4f link:%d",
                       log: .default, type: .default,
                       resumeBeat ?? -1.0, linkWasEnabled ? 1 : 0)

                // 4. ⚠️ RISCRITTO A416 (21/10/2026). Qui c'era «Aggiorna timestamp resume — blocca
                //    handleEngineConfigChange post-interruzione» (`lastInterruptionResumeTime`): per 20 s dopo la ripresa
                //    il cambio di configurazione usciva, e se il motore era fermo restava fermo con `isRunning` vero. Da
                //    A416 il cambio di configurazione legge solo lo stato (`EngineConfigChangeDecision`): niente da segnare.

                // 5. Start — Con Link attivo passa nil: phase sync automatica nei primi buffer
                self.activateSessionAndStart(
                    resumeAtBeat: linkWasEnabled ? nil : resumeBeat,
                    trigger: .interruptionEnded
                )
            }

        @unknown default: break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        // A416 (21/10/2026) — l'ora d'arrivo, letta qui prima del salto su audioQueue: la riga del buco del render la
        // confronta col buco (`RenderGapMeter`, mandato «USCITA-AUDIO-PASSO-1», §2.3).
        let arrivedTicks = mach_absolute_time()
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // ⚠️ RISCRITTO A416 (21/10/2026). Qui c'era `os_log("routeChange reason=%{public}@", …, "\(reason)")`, che
        // scriveva il tipo col numero e basta («…(rawValue: 1)»). Da A416 (mandato §2.7, riga 2) il nome del motivo
        // (Apple, `AVAudioSession.RouteChangeReason`), il numero, le uscite di prima (la chiave
        // `AVAudioSessionRouteChangePreviousRouteKey`) e di adesso (`currentRoute`) col loro tipo, e l'ora d'arrivo.
        // L'inizio della riga resta «routeChange reason=».
        let reasonName = AudioEngine.routeChangeReasonName(reason)
        // A421 — le uscite di prima e di adesso si leggono una volta, qui: per la riga di A416 e per la classe di U2 (il tipo e
        // l'identificativo di ogni porta; `OutputRouteDecision`), sul thread della notizia.
        let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let previousOutputs = AudioEngine.describeOutputs(previousRoute)
        let currentOutputs = AudioEngine.describeOutputs(currentRoute)
        os_log("routeChange reason=%{public}@ rawValue:%lu prima:%{public}@ adesso:%{public}@ arrivo:%llu",
               log: .default, type: .default, reasonName, reasonValue, previousOutputs, currentOutputs, arrivedTicks)
        // === A421 (24/10/2026) — LA CLASSE DELL'USCITA (mandato A421, U2): tolta | aggiunta | nessuna, dalle porte di prima
        // e di adesso, qualunque sia il motivo (il 24/10 alle 13:55:42 un attacco delle cuffie col filo è arrivato con
        // `unknown`). L'identificativo non va nel registro; `identita:` dice al collaudo se le porte tengono lo stesso
        // identificativo fra i due percorsi ([Probabile]).
        let currentPorts = AudioEngine.outputPorts(currentRoute)
        let classification = OutputRouteDecision.classify(previous: AudioEngine.outputPorts(previousRoute),
                                                           current: currentPorts)
        let externalNow = OutputRouteDecision.hasExternal(currentPorts)
        os_log("[Q-BEATS][USCITA] percorso motivo:%{public}@ prima:%{public}@ adesso:%{public}@ identita:%{public}@ -> classe:%{public}@ esterna:%d",
               log: .default, type: .default,
               reasonName, previousOutputs, currentOutputs, classification.identity.rawValue,
               classification.routeClass.rawValue, externalNow ? 1 : 0)

        // B1 Hard Sync: clock C++ NON si ferma mai durante route change.
        // MAI chiamare midi_engine_stop() qui.

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // A416 — il segno per la riga del buco del render: l'ora d'arrivo e il motivo.
            self._lastRouteChangeQ = RouteChangeMark(ticks: arrivedTicks, reason: reasonName)

            // === A421 (24/10/2026) — LE CUFFIE: IL BLOCCO DELLA CODA (mandato A421, par. 2.3 a) ===
            // La classe è decisa sul thread della notizia; qui, per il ruolo della regola delle crisi, che cosa fa il blocco
            // (`OutputRouteDecision.step`): il silenzio, la crisi, «uscita mancante», il ritorno. L'ordine del mandato: il
            // segno (qui sopra) e `mediaResetSkipsQ`; il silenzio (U3), prima di ogni lettura della sessione; il rimando
            // dentro un'interruzione, che aggiorna solo lo stato puro ed esce; «uscita mancante» (U5); la crisi e l'arresto
            // (U4, U16); la ripresa pendente (da `RecoveryDecision`, con «uscita mancante»); poi i rami di oggi della
            // frequenza, del modo e dello schermo, che per un ruolo appena fermato da questa crisi aggiornano le copie e non
            // ripartono (la ripartenza è il ritorno, U6, o il Play), e per il Follower, che la crisi zittisce e non ferma,
            // ripartono come oggi col volume dallo stato puro (U3 b). Fra la Lost e la Reset il blocco esce a
            // `mediaResetSkipsQ` anche per lo stato puro, come scritto: la tolta persa in quella finestra la rilegge il primo
            // avvio del Follower dopo la ricostruzione (`start()`, U5).
            let outputStep = OutputRouteDecision.step(routeClass: classification.routeClass,
                                                      playerRole: self.playerRoleQ,
                                                      showOpen: self._showOpenQ,
                                                      songInProgress: self._songInProgressQ,
                                                      engineRunning: self.isRunning,
                                                      stoppedByCrisis: self.stoppedByCrisisQ,
                                                      inInterruption: self._interruptionRouteQ.systemInterruption)
            os_log("[Q-BEATS][USCITA] passo classe:%{public}@ ruolo:%{public}@ show:%d canzone:%d motore:%{public}@ fermoPerCrisi:%d interruzione:%d -> silenzio:%d crisi:%{public}@ alzaMancante:%d abbassaMancante:%d ritorno:%{public}@",
                   log: .default, type: .default,
                   classification.routeClass.rawValue, self.playerRoleQ.rawValue, self._showOpenQ ? 1 : 0,
                   self._songInProgressQ ? 1 : 0, self.isRunning ? "in-moto" : "fermo", self.stoppedByCrisisQ ? 1 : 0,
                   self._interruptionRouteQ.systemInterruption ? 1 : 0, outputStep.silences ? 1 : 0,
                   outputStep.crisisCause?.rawValue ?? "-", outputStep.raisesMissing ? 1 : 0,
                   outputStep.lowersMissing ? 1 : 0, outputStep.armsReturn?.rawValue ?? "-")
            // A408 — fuori da «normale» (dalla Lost alla ricostruzione) niente: né ripresa, né
            // setupGraph o rebuildGraph sul motore vecchio, né frequenza letta da una sessione morta.
            // La ricostruzione al primo avvio rilegge percorso, modo e frequenza dalla sessione.
            if self.mediaResetSkipsQ("cambio di percorso") { return }

            // A421 — U3: IL SILENZIO SUBITO, la prima istruzione dopo il segno e `mediaResetSkipsQ`, prima di ogni lettura
            // della sessione: il volume del mixer principale a 0, col click in moto e fuori da un'interruzione di sistema,
            // quando la classe lo chiede per il ruolo (Direttore in canzone: tolta e aggiunta; Direttore fuori da una
            // canzone e Solo: solo tolta; Follower: tolta e aggiunta). Il ritorno è del Direttore (U6), del Follower (par.
            // 2.2 c) o del Play (il Solo; il Direttore fuori da una canzone).
            if outputStep.silences {
                self.silenceOutputNowQ(reason: "percorso-\(classification.routeClass.rawValue)")
            }
            // A421 — U5: lo stato puro «uscita mancante» (anche dentro un'interruzione: il rimando qui sotto esce dopo), e a una
            // tolta ogni ritorno in attesa si annulla (par. 2.3 b). L'uscita di adesso viene dalla classe: nessuna lettura
            // della sessione.
            if classification.routeClass == .removed {
                self.cancelOutputReturnsQ(reason: "tolta")
            }
            if outputStep.raisesMissing {
                self.noteOutputStateQ(.removed, from: "tolta", externalPresent: externalNow)
            }
            if outputStep.lowersMissing {
                self.noteOutputStateQ(.externalPresent, from: "aggiunta", externalPresent: externalNow)
            }

            // A416 · SEGUITO 2 (21/10/2026) — CON L'INTERRUZIONE DI SISTEMA IN CORSO NON SI TOCCA NIENTE (mandato del
            // referee «A416 · SEGUITO 2», §2.2; `InterruptionRouteDecision`). Il 21/10, durante una telefonata, questo blocco
            // ha chiesto la durata del buffer e ricollegato il grafo (`engine.prepare()`); 28 ms dopo iOS ha dichiarato
            // attiva la nostra sessione, e la fine dell'interruzione non è più arrivata. Con lo stato alzato: niente
            // frequenza (`applySampleRateQ`), niente ricollegamento, niente ramo del modo, niente ripresa pendente. Si segna
            // il rimandato col motivo dell'ultimo arrivato e si scrive una riga con le sole letture della sessione (il
            // formato del nodo d'uscita no: che leggerlo non abbia effetti non ha fonte). Lo esegue una volta la fine
            // dell'interruzione o l'avvio.
            let routeSession = AVAudioSession.sharedInstance()
            let routeStep = InterruptionRouteDecision.routeChange(
                reason: reasonName,
                conditions: InterruptionRouteDecision.RouteConditions(
                    engineRunning: self.isRunning,
                    rateDiffers: !SampleRateDecision.same(routeSession.sampleRate, self.sampleRate),
                    modeDiffers: self.detectAudioMode() != self.audioMode,
                    pendingResume: self.pendingResume),
                state: self._interruptionRouteQ)
            self._interruptionRouteQ = routeStep.state
            if routeStep.outcome == .deferred {
                // A421 — dentro un'interruzione la notizia ha già aggiornato «uscita mancante», qui sopra (par. 2.3 a); la riga
                // lo scrive. Niente volume, crisi, ritorno.
                os_log("[Q-BEATS][ROUTE] rimandato motivo:%{public}@ sessione:%.0f preferita:%.0f mancante:%d -> esito:interruzione-in-corso",
                       log: .default, type: .default,
                       reasonName, routeSession.sampleRate, routeSession.preferredSampleRate,
                       self._outputSilenceQ.missing ? 1 : 0)
                return
            }

            // === A421 — LA CRISI E L'ARRESTO (U4, U16, par. 2.2 f): la regola di ogni crisi con la causa della classe ===
            // Direttore in canzone: tolta e aggiunta (muto in canzone, l'arresto locale sulla coda); Direttore fuori da una
            // canzone e Solo: solo tolta (l'arresto locale; il Solo come allo Stop della sua console, sul principale, come
            // alla Lost); Follower: mai (la crisi lo zittisce, qui sopra, e non lo ferma). Poi il ritorno: il Direttore dopo
            // un'aggiunta in canzone (U6: l'assestamento, o la configurazione se la frequenza della sessione è già diversa
            // dalla copia), il Follower dopo ogni silenzio col motore in moto (par. 2.2 c).
            var soloStopCause: CrisisCause? = nil
            if let cause = outputStep.crisisCause {
                let outcome = self.crisisOutcomeQ(cause: cause)
                switch outcome {
                case .silentInSong:
                    self.enterDirectorSilenceQ(cause: cause)
                    if self.isRunning {
                        self.stopForOutputCrisisQ(context: "percorso-\(classification.routeClass.rawValue)")
                    }
                    self.publishDirectorSilenceQ(context: "percorso-\(classification.routeClass.rawValue)")
                case .localStop:
                    if self.isRunning {
                        self.stopForOutputCrisisQ(context: "percorso-\(classification.routeClass.rawValue)")
                        // U16: il Direttore fuori da una canzone riparte col Play: il player a «fermo», come allo Stop del Solo
                        // (fuori da una canzone non c'è il silenzio del Direttore a tenere lo stato del tasto).
                        DispatchQueue.main.async { self.playbackState = .stopped }
                    }
                case .soloStopAsConsole:
                    soloStopCause = cause
                case .asToday, .nothing:
                    break
                }
                if outputStep.armsReturn == .director && outcome == .silentInSong {
                    self.cancelOutputReturnsQ(reason: "percorso-aggiunta")
                    self.armDirectorReturnQ(trigger: .outputAdded,
                                            sessionRateDiffers: !SampleRateDecision.same(routeSession.sampleRate, self.sampleRate))
                }
            }
            if outputStep.armsReturn == .follower && self.isRunning && self._outputSilenceQ.muted {
                self.armFollowerReturnQ(noticeTicks: arrivedTicks, fromTap: false)
            }
            if let cause = soloStopCause {
                // Il Solo si ferma come allo Stop della sua console, sul principale (`stopSync` non gira da audioQueue): i rami
                // qui sotto trovano il motore ancora in moto e aggiornano le copie; lo Stop arriva dopo, con la pulizia (par.
                // 2.2 e, anche a motore già fermo), e il Solo va allo schermo «Resume from».
                DispatchQueue.main.async {
                    self.stopForSoloCrisis(cause: cause)
                }
            }

            // --- pendingResume recovery (path esistente preservato) ---
            // A421 — la ripresa pendente passa da `RecoveryDecision` con «uscita mancante» (`recoveryRouteQ`): il Direttore con
            // l'uscita mancante non riparte (U5), e il tasto si ripubblica. Se questa notizia ha appena armato il ritorno del
            // Direttore (U6), la ripresa pendente è assorbita dal ritorno: una ripartenza sola, dopo l'assestamento o la
            // configurazione, non subito nel mezzo del buco (dopo la verifica del diff).
            if self.pendingResume, let armed = self._directorReturnQ, armed.armedTicks >= arrivedTicks {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                os_log("[Q-BEATS][RESUME] pendingResume assorbito dal ritorno del Direttore armato da questa notizia",
                       log: .default, type: .default)
            }
            if self.pendingResume {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time() + self.outputLatencyTicks + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }
                os_log("[Q-BEATS][RESUME] pendingResume recuperato da RouteChange — beat:%.4f",
                       log: .default, type: .default, recoveryBeat ?? -1.0)
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat, trigger: .pendingRecovery)
                return
            }

            // --- Fase 1.5a: hardware detection e routing dinamico ---
            // ⚠️ RISCRITTO A416 (21/10/2026). Fino ad A415 qui la frequenza era quella della sessione (`newSampleRate`),
            // «cambiata» se diversa dalla copia del motore; la copia e il ponte del tap la prendevano subito («Task D
            // refactor #18 — propaga sampleRate al pending atomic su route change»), il DSP no; col motore acceso
            // `setupGraph()` ricollegava i nodi a motore in moto, e la ripartenza usciva alla guardia di `start()`
            // (`isRunning` ancora vero): il motore poteva restare fermo con `isRunning` vero (referto A415, §4.7). Da
            // A416 la frequenza viene dalla fonte unica (`applySampleRateQ`, una riga [FORMATO]). Col motore in moto e una
            // frequenza diversa (esito «fermare-e-ricostruire») prima l'arresto esplicito, come al cambio di
            // configurazione, poi la frequenza e il grafo, poi la ripartenza dalla regola (mandato «USCITA-AUDIO-PASSO-1»,
            // §2.2); a motore fermo la frequenza è già arrivata a tutte le copie e si ricollegano i nodi.
            let detectedMode = self.detectAudioMode()
            let modeChanged = detectedMode != self.audioMode
            let format = self.applySampleRateQ(context: "percorso")
            let sampleRateChanged = format.action == .stopAndRebuild || format.reconnectsGraph

            os_log("routeChange newSampleRate=%.1f detectedMode=%{public}@ srChanged=%{public}@ modeChanged=%{public}@",
                   log: .default, type: .default,
                   format.rate, "\(detectedMode)",
                   "\(sampleRateChanged)", "\(modeChanged)")

            if format.action == .stopAndRebuild {
                // ⚠️ RISCRITTO A420 (23/10/2026). Qui c'era la strada «fermare-e-ricostruire» di A416, scritta a parte: «A416 —
                // L'ARRESTO ESPLICITO, come al cambio di configurazione (`handleEngineConfigChange`): la regola di ogni crisi
                // (`CrisisStopDecision`) con la causa «configurazione» [...]; poi `isRunning` a falso, lettore e motore fermi,
                // l'ingresso pendente annullato, il segno del proprio avvio abbassato.», poi la frequenza, il grafo,
                // l'instradamento e lo schermo, il battito (con le latenze di prima), la riga «sampleRateChanged —
                // recoveryBeat» e la ripartenza `sample_rate_change`. Da A420 è la funzione sola, la stessa del cambio di
                // configurazione (`restartForRateChangeQ`, mandato A420, par. 2.3). L'ordine dei due eventi non conta: se arriva
                // prima questo, la configurazione trova `isRunning` basso, o il motore in moto, e si ignora; se arriva prima la
                // configurazione, qui la copia è già uguale al nodo e non si ferma niente.
                self.restartForRateChangeQ(source: .route, trigger: .sampleRateChange, mode: detectedMode)
                return
            }
            if format.reconnectsGraph {
                // A416 — motore fermo: la frequenza è già arrivata a tutte le copie (qui sopra); si ricollegano i nodi coi
                // formati nuovi, e niente riparte (com'era).
                self.reconnectGraphQ(for: detectedMode, caller: "percorso")
                self.applyChannelRouting(for: detectedMode)
                os_log("[Q-BEATS][ROUTE] sampleRateChanged — engine fermo, no restart",
                       log: .default, type: .default)
                let rateForScreen = self.sampleRate
                DispatchQueue.main.async {
                    self.audioMode = detectedMode
                    self.sampleRateInfo = rateForScreen
                }
                return
            } else if modeChanged {
                // Topologia grafo cambia tra Base e Pro — rebuild completo obbligatorio.
                // B1 Hard Sync: clock C++ non si ferma — MAI midi_engine_stop() qui.
                let wasRunning = self.isRunning
                // A410 — l'àncora del conteggio in silenzio, prima che `isRunning` vada a falso.
                // A412 — dentro la regola di ogni crisi (`CrisisStopDecision`): col Direttore muto in canzone
                // l'àncora e il silenzio, e la ripartenza qui sotto passa dal coordinatore
                // (`RecoveryDecision`); per tutti gli altri come oggi.
                if self.crisisOutcomeQ(cause: .mode) == .silentInSong {
                    self.enterDirectorSilenceQ(cause: .mode)
                }
                self.isRunning = false
                // A420 — l'arresto sulla coda, con la sua riga (mandato A420, par. 2.1).
                self.stopPlayerAndEngineQ(context: "modo")
                // A421 — il drenaggio consegnato (par. 2.2 j) e lo specchio di `isRunning` (par. 2.2 e: il buco del ticket). I
                // ritorni in attesa si annullano solo se questo ramo riparte, più sotto (par. 2.3 b).
                self.closeDrainOnCrisisStopQ(context: "modo")
                self.publishIsPlayingQ(context: "modo")
                // RIENTRO-P1 (a) — arresto che non passa da `stopSync`: l'ingresso
                // pendente, se c'è, si annulla qui.
                self.cancelPendingJoin(reason: "cambio di topologia")
                // A400 · R1 — arresto che non passa da `stopSync`: si abbassa qui anche il segno
                // del proprio avvio.
                self.lowerOwnTransportStartQ(reason: "topologia")

                // A416 — con la frequenza dalla fonte unica (`applySampleRateQ` in `rebuildGraph`, a motore fermo).
                self.rebuildGraph(for: detectedMode, context: "modo")
                self.applyChannelRouting(for: detectedMode)

                let recoveryBeat: Double?
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time()
                                 + self.outputLatencyTicks
                                 + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                } else {
                    recoveryBeat = nil
                }

                os_log("[Q-BEATS][ROUTE] modeChanged %{public}@ → %{public}@ — recoveryBeat:%.4f",
                       log: .default, type: .default,
                       "\(self.audioMode)", "\(detectedMode)", recoveryBeat ?? -1.0)

                // A416 — lo schermo mostra la frequenza che si usa (la copia, letta qui), non quella della sessione.
                let rateForScreen = self.sampleRate
                DispatchQueue.main.async {
                    self.audioMode = detectedMode
                    self.sampleRateInfo = rateForScreen
                }
                if self._directorSilentInSongQ {
                    self.publishDirectorSilenceQ(context: "modo")
                }

                guard wasRunning else {
                    os_log("[Q-BEATS][ROUTE] modeChanged — engine fermo, no restart",
                           log: .default, type: .default)
                    return
                }

                // A421 — par. 2.3 b: la ripartenza del motore annulla i ritorni in attesa (il volume lo riscrive `start()`, U3 b).
                // ⚠️ RISCRITTO dopo la verifica indipendente del diff: la prima stesura annullava anche a motore già fermo da
                // questa crisi (un'aggiunta che cambia il modo: la scheda USB a quattro canali), e il ritorno del Direttore appena
                // armato moriva qui, contro U6.
                self.cancelOutputReturnsQ(reason: "modo")
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                             trigger: .modeChange,
                                             mode: detectedMode)
                return
            }

            // Path senza cambio né SR né mode
            // A416 — lo schermo mostra la frequenza che si usa (la copia, letta qui), non quella della sessione.
            let rateForScreen = self.sampleRate
            DispatchQueue.main.async {
                self.audioMode = detectedMode
                self.sampleRateInfo = rateForScreen
            }

            // --- Aggiornamento latency ticks ---
            let avSession = AVAudioSession.sharedInstance()
            self.outputLatencyTicks  = self.secondsToMachTicks(avSession.outputLatency)
            self.bufferDurationTicks = self.secondsToMachTicks(avSession.ioBufferDuration)
            if let lh = self.linkEngineHandle {
                link_engine_set_output_latency_ticks(lh, self.outputLatencyTicks)
            }

        }
    }

    // === A408 (15/10/2026) — IL RESET DEI SERVIZI AUDIO ===
    // Lost e Reset le posta iOS sul thread principale (Apple, referto A407, §1.1-§1.2), una volta per
    // ogni sessione del processo: nel collaudo di A406 tre di ciascuna, una dell'app e due delle
    // sessioni aptiche di UIKit (referto A407, §4). Gli osservatori restano con `object: nil`: un
    // filtro sull'oggetto non ha fonte (referto A407, §1.8). Lo stato vive su audioQueue
    // (`_mediaServicesQ`); regola e banco in `MediaServicesResetDecision` (Models/). Nessun gestore
    // chiama setActive, setupSession, setupGraph o activateSessionAndStart: la sessione si riattiva
    // al primo avvio dopo il reset (`start()` → `rebuildAfterMediaResetQ`), e il click non riparte da
    // solo (decisioni del referee sul referto A407, punti 2 e 4; QA1749).

    // La Lost: lo stato va a «servizi persi», da qualunque stato. A410 — la ripresa pendente si sgombera
    // (§2.8).
    // ⚠️ RISCRITTO A412 (18/10/2026). Il testo di prima diceva «Il motore resta com'è: se il click suona, lo
    // ferma la Reset» e «il Direttore in canzone prende l'àncora (il motore resta com'è: nessun arresto locale
    // nel passo 1)». Da A412 decide la regola di ogni crisi (`CrisisStopDecision`): il Direttore (muto in
    // canzone, con l'àncora, o senza canzone) si ferma QUI in locale, un'operazione nuova sul server dei servizi
    // audio che non c'è più (gli errori si ignorano, come nella ricostruzione: QA1749; una riga); il Solo col
    // click in moto si ferma come allo Stop della console (sul principale: `stopSync` non gira da audioQueue);
    // il Follower come oggi (resta com'è fino alla Reset).
    @objc private func handleMediaLost(_ notification: Notification) {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self._mediaLostCountQ += 1
            let from = self._mediaServicesQ
            self._mediaServicesQ = MediaServicesResetDecision.transition(state: from, event: .lost).next
            os_log("[Q-BEATS][RESET] servizi audio persi n:%d stato:%{public}@ -> %{public}@",
                   log: .default, type: .default,
                   self._mediaLostCountQ, self.describe(from), self.describe(self._mediaServicesQ))
            let outcome = self.crisisOutcomeQ(cause: .servicesLost)
            switch outcome {
            case .silentInSong, .localStop:
                if outcome == .silentInSong {
                    self.enterDirectorSilenceQ(cause: .servicesLost)
                    // Il tasto prima dello specchio «non suona»: un tocco in mezzo trova già il silenzio.
                    self.publishDirectorSilenceQ(context: "servizi-persi")
                }
                if self.beginLocalStopQ(context: "servizi-persi") {
                    self.stopPlayerAndEngineQ(context: "servizi-persi")
                    // A421 — `isPlaying = false` lo pubblica `beginLocalStopQ`, dalla coda (par. 2.2 e).
                    self.logLocalStop(context: "servizi-persi", server: "assente(operazione-nuova)")
                }
            case .soloStopAsConsole:
                DispatchQueue.main.async {
                    self.stopForSoloCrisis(cause: .servicesLost)
                }
            case .asToday, .nothing:
                break
            }
            self.clearPendingResumeQ(reason: "lost")
            // A421 — la Lost annulla i ritorni in attesa (par. 2.3 b); il volume lo riscrive `start()` dopo il reset (U3 b).
            self.cancelOutputReturnsQ(reason: "servizi-persi")
            if self._directorSilentInSongQ {
                self.publishDirectorSilenceQ(context: "servizi-persi")
            }
        }
    }

    // La Reset.
    //  · da «servizi persi»: lo stopSync del Follower sul principale (vedi sotto), poi, su audioQueue, «da
    //    ricostruire». Fra la lettura e il passaggio lo stato resta «servizi persi»: un avvio che arriva in
    //    mezzo è rifiutato;
    //  · da «da ricostruire»: notifica ripetuta, ignorata;
    //  · da «normale» (Reset senza Lost): «da ricostruire», senza stopSync.
    // A410 — dentro il `sync`, in tutti i rami: la ripresa pendente si sgombera (§2.8).
    // ⚠️ RISCRITTO A412 (18/10/2026). Il testo di prima diceva: «da servizi persi: stopSync sul principale» per
    // tutti, con «⚠️ DIFETTO APERTO (A410): sul Direttore questo stopSync manda lo Stop alla band, e chiude la
    // canzone» (`TD-media-reset-del-direttore-ferma-la-band`, contro LIBRO 2026-09-17 «IL PRINCIPIO DELLA
    // BAND»); e «con la Reset senza Lost il motore resta com'è e tace [...] il Direttore in canzone prende lì
    // l'àncora». Da A412 decide la regola di ogni crisi (`CrisisStopDecision`), e nessuna crisi manda Stop a
    // Link:
    //  · Reset dopo la Lost: il Direttore si è già fermato in locale alla Lost (muto in canzone, o senza
    //    canzone): niente stopSync, niente Stop alla band, la canzone resta aperta. Lo stopSync resta solo sul
    //    Follower, perché è il suo comportamento di oggi (mandato: il Follower non cambia) e lì non scrive su Link
    //    (A360): ferma in locale il motore agganciato al server morto. Il Solo, fermo dalla Lost, non ha niente
    //    da fermare;
    //  · Reset senza Lost: il motore tace agganciato al server morto. Il Direttore si ferma qui in locale (muto
    //    in canzone, con l'àncora presa qui; o senza canzone); il Solo col click in moto come allo Stop della
    //    console; il Follower come oggi (resta com'è).
    // Il `sync` dal principale è quello di prima.
    @objc private func handleMediaReset(_ notification: Notification) {
        var followerStopSync = false
        var soloStop: CrisisCause? = nil
        var stoppedLocally = false
        var stoppedContext = ""
        let action: MediaServicesAction = audioQueue.sync {
            self._mediaResetCountQ += 1
            let from = self._mediaServicesQ
            let step = MediaServicesResetDecision.transition(state: from, event: .reset)
            self._mediaServicesQ = step.next
            os_log("[Q-BEATS][RESET] notifica di reset n:%d stato:%{public}@ esito:%{public}@",
                   log: .default, type: .default,
                   self._mediaResetCountQ, self.describe(from), self.describe(step.action))
            if step.action == .stopThenMarkRebuild || step.action == .markRebuild {
                let cause: CrisisCause = step.action == .stopThenMarkRebuild ? .resetAfterLost : .resetWithoutLost
                let outcome = self.crisisOutcomeQ(cause: cause)
                switch outcome {
                case .silentInSong, .localStop:
                    if outcome == .silentInSong {
                        self.enterDirectorSilenceQ(cause: cause)
                    }
                    stoppedContext = cause.rawValue
                    stoppedLocally = self.beginLocalStopQ(context: cause.rawValue)
                case .soloStopAsConsole:
                    soloStop = cause
                case .asToday:
                    followerStopSync = step.action == .stopThenMarkRebuild
                case .nothing:
                    break
                }
            }
            self.clearPendingResumeQ(reason: "reset")
            // A421 — la Reset annulla i ritorni in attesa (par. 2.3 b).
            self.cancelOutputReturnsQ(reason: "reset")
            if self._directorSilentInSongQ {
                self.publishDirectorSilenceQ(context: "reset")
            }
            // A420 — L'ARRESTO SULLA CODA, in fondo al `sync` (mandato A420, par. 2.1): fino ad A419 la coppia di
            // `beginLocalStopQ` si fermava qui sotto, sul principale, dopo il `sync`.
            if stoppedLocally {
                self.stopPlayerAndEngineQ(context: "reset")
            }
            return step.action
        }
        if stoppedLocally {
            // A421 — `isPlaying = false` lo pubblica `beginLocalStopQ`, dalla coda (par. 2.2 e).
            logLocalStop(context: stoppedContext, server: "ripartito-sotto-un-motore-vecchio")
        }
        if let cause = soloStop {
            stopForSoloCrisis(cause: cause)
        }
        guard action == .stopThenMarkRebuild else { return }
        if followerStopSync {
            stopSync(origin: .followerReset)
        } else {
            os_log("[Q-BEATS][RESET] stopSync della Reset non eseguito - non Follower - nessuno Stop alla band, la canzone del Direttore resta aperta",
                   log: .default, type: .default)
        }
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self._mediaServicesQ = MediaServicesResetDecision.transition(state: self._mediaServicesQ,
                                                                        event: .stoppedAfterReset).next
            // A412 — da «da ricostruire» il tocco ricostruisce e rientra: il tasto si ricalcola (D2).
            if self._directorSilentInSongQ {
                self.publishDirectorSilenceQ(context: "da-ricostruire")
            }
        }
    }

    // La ricostruzione, al primo avvio dopo il reset. Chiamare SOLO su audioQueue, da `start()` in
    // «da ricostruire», dopo la guardia (motore fermo) e dopo l'uscita `stayStopped` del Follower.
    // Come all'avvio dell'app (`init`), nell'ordine:
    //  1. motore vecchio: stop e poi removeTap, come in `deinit`. Gli errori si ignorano (QA1749);
    //  2. motore nuovo e 8 nodi nuovi (referto A407, §6.1);
    //  3. `setupSession()`: categoria, preferenze, canali, setActive. Se la sessione non si attiva
    //     la ricostruzione si ferma qui: i nuovi si lasciano andare senza essere mai stati attaccati,
    //     restano in uso motore e nodi vecchi, fermi e ancora attaccati, e lo stato resta «da
    //     ricostruire». Così nessuna strada trova un nodo staccato, che Apple dice inutilizzabile
    //     finché non lo si attacca (`AVAudioEngine.attach(_:)`). Il Play dopo riprova;
    //  4. i nuovi entrano in uso, e il motore vecchio si lascia andare qui, su audioQueue (non in un
    //     gestore del cambio di configurazione: referto A407, §1.3); `setupGraph()` (attach ×8,
    //     collegamenti, tap di Link, instradamento), poi `prepare()`;
    //  5. i tre campioni del click; la base si scarta, come al reset di prima. Volumi, pan e
    //     channelMap dei nodi nuovi li rimette `setupGraph` coi valori salvati (`connectAllNodes`,
    //     `applyChannelRouting`): niente `applySettings`;
    //     ⚠️ A416 (21/10/2026): i tre campioni del click non si rifanno più qui. Li rifà `applySampleRateQ`, dentro
    //     `setupGraph` (passo 4), se la frequenza dalla fonte unica è diversa da quella con cui sono stati fatti; con la
    //     stessa frequenza sono gli stessi numeri. Qui resta la base che si scarta;
    //  6. «normale», e la riga col motore vecchio, il nuovo e i millisecondi della ricostruzione.
    // Rende `false` se la sessione non si è attivata. Niente audioQueue.sync, niente
    // DispatchQueue.main.sync.
    private func rebuildAfterMediaResetQ() -> Bool {
        let rebuildStart = mach_absolute_time()
        let oldEngine = Int(bitPattern: Unmanaged.passUnretained(engine).toOpaque())
        // 1.
        autoreleasepool {
            engine.stop()
            engine.mainMixerNode.removeTap(onBus: 0)
        }
        // 2.
        let newEngine          = AVAudioEngine()
        let newPlayer          = AVAudioPlayerNode()
        let newBacktrackPlayer = AVAudioPlayerNode()
        let newCh1Mixer        = AVAudioMixerNode()
        let newCh2Mixer        = AVAudioMixerNode()
        let newCh3Mixer        = AVAudioMixerNode()
        let newCh4Mixer        = AVAudioMixerNode()
        let newCh3Player       = AVAudioPlayerNode()
        let newCh4Player       = AVAudioPlayerNode()
        // 3.
        guard setupSession() else {
            _mediaServicesQ = MediaServicesResetDecision.transition(state: _mediaServicesQ,
                                                                   event: .rebuilt(sessionActivated: false)).next
            os_log("[Q-BEATS][RESET] ricostruzione non finita: sessione non attivata - motore:0x%lx invariato - stato:%{public}@",
                   log: .default, type: .default, oldEngine, describe(_mediaServicesQ))
            return false
        }
        // 4.
        autoreleasepool {
            engine              = newEngine
            playerNode          = newPlayer
            backtrackPlayerNode = newBacktrackPlayer
            ch1MixerNode        = newCh1Mixer
            ch2MixerNode        = newCh2Mixer
            ch3MixerNode        = newCh3Mixer
            ch4MixerNode        = newCh4Mixer
            ch3PlayerNode       = newCh3Player
            ch4PlayerNode       = newCh4Player
        }
        let mode = setupGraph(context: "reset")
        engine.prepare()
        os_log("[Q-BEATS][RESET] grafo pronto modo:%{public}@ sr:%.0f",
               log: .default, type: .default, "\(mode)", sampleRate)
        // 5.
        backtrackBuffer = nil
        backtrackArmed  = false
        // 6.
        _mediaServicesQ = MediaServicesResetDecision.transition(state: _mediaServicesQ,
                                                               event: .rebuilt(sessionActivated: true)).next
        os_log("[Q-BEATS][RESET] motore nuovo vecchio:0x%lx nuovo:0x%lx ms:%.1f stato:%{public}@",
               log: .default, type: .default,
               oldEngine, Int(bitPattern: Unmanaged.passUnretained(engine).toOpaque()),
               machTicksToSeconds(mach_absolute_time() - rebuildStart) * 1000.0,
               describe(_mediaServicesQ))
        return true
    }

    // Fuori da «normale» le strade che farebbero lavoro di grafo o d'avvio sul motore vecchio, o
    // chiamerebbero setActive, si saltano: rende `true` e scrive la riga. Chiamare SOLO su audioQueue.
    private func mediaResetSkipsQ(_ path: String) -> Bool {
        guard !MediaServicesResetDecision.allowsAudioWork(_mediaServicesQ) else { return false }
        os_log("[Q-BEATS][RESET] %{public}@ saltato - stato:%{public}@",
               log: .default, type: .default, path, describe(_mediaServicesQ))
        return true
    }

    private func describe(_ state: MediaServicesState) -> String {
        switch state {
        case .normal:       return "normale"
        case .servicesLost: return "servizi-persi"
        case .needsRebuild: return "da-ricostruire"
        }
    }

    private func describe(_ action: MediaServicesAction) -> String {
        switch action {
        case .none:                return "nessuna"
        case .stopThenMarkRebuild: return "stop-poi-da-ricostruire"
        case .markRebuild:         return "da-ricostruire-senza-stop"
        case .ignoreRepeatedReset: return "ignorata"
        case .startAsToday:        return "avvio"
        case .refuseStart:         return "avvio-rifiutato"
        case .rebuildThenStart:    return "ricostruzione-poi-avvio"
        case .failStart:           return "avvio-fallito"
        }
    }

    // =====================================================================================
    // === A420 (23/10/2026) — USCITA AUDIO, PASSO 2a, PEZZO 1: LA RIPARTENZA PER LA FREQUENZA, UNA STRADA SOLA ===
    // =====================================================================================
    // Mandato A420, par. 2.3 (U12 del referto A419, §3.5; BUGS, `TD-nodo-d-uscita-con-la-frequenza-vecchia`). Fino ad A419
    // erano due strade scritte a parte, che fermavano e ripartivano per lo stesso evento in un ordine che Apple non
    // documenta: il cambio di configurazione del motore (`handleEngineConfigChange`, la strada documentata: il motore si
    // ferma da solo e lo notifica) e il cambio di percorso col nodo d'uscita già alla frequenza nuova a motore in moto
    // (`handleRouteChange`, esito «fermare-e-ricostruire» di `SampleRateDecision`, la riserva). Da qui una funzione sola, che
    // fa quello che facevano tutte e due: dalla configurazione le latenze rilette prima del battito (la ripresa pendente la
    // decide il gestore, e arriva qui come innesco); dal percorso lo stop anche del motore, l'instradamento dei canali e lo
    // schermo. L'ordine dei due eventi non conta: se arriva prima il percorso, la configurazione trova `isRunning` basso, o
    // il motore in moto, e si ignora (`EngineConfigChangeDecision`); se arriva prima la configurazione, il percorso trova la
    // copia già uguale al nodo e non fa niente (`SampleRateDecision`). Gli inneschi restano quelli di oggi.

    /// Chi chiama la ripartenza per la frequenza, coi nomi di oggi nelle righe.
    private enum RateRestartSource {
        /// Il cambio di configurazione del motore (`handleEngineConfigChange`).
        case configuration
        /// Il cambio di percorso col nodo d'uscita già alla frequenza nuova, a motore in moto (`handleRouteChange`).
        case route
        /// A421 — la rete del motore fermo dal sistema (par. 2.2 a): nessun gestore in 2 s (`fireStoppedEngineNetQ`).
        case stoppedEngineNet

        /// La riga [ARRESTO], il segno del proprio avvio e il tasto del Direttore muto.
        var stopContext: String {
            switch self {
            case .configuration: return "configurazione"
            case .route: return "frequenza"
            case .stoppedEngineNet: return "rete-motore-fermo"
            }
        }

        /// La riga [FORMATO], il chiamante di `reconnectGraphQ` e la riga della ripartenza.
        var formatContext: String {
            switch self {
            case .configuration: return "configurazione"
            case .route: return "percorso"
            case .stoppedEngineNet: return "rete-motore-fermo"
            }
        }

        /// Il motivo dell'annullo dell'ingresso pendente.
        var joinReason: String {
            switch self {
            case .configuration: return "cambio di configurazione"
            case .route: return "cambio di frequenza"
            case .stoppedEngineNet: return "rete del motore fermo"
            }
        }
    }

    /// LA RIPARTENZA PER LA FREQUENZA: la regola delle crisi con la causa «configurazione», l'arresto sulla coda, la
    /// frequenza a tutte le copie, il grafo, l'instradamento e lo schermo, il battito di ripresa, la ripartenza dalla regola
    /// (`activateSessionAndStart`, `RecoveryDecision`). `mode`: il modo letto da chi chiama. Chiamare SOLO su audioQueue.
    private func restartForRateChangeQ(source: RateRestartSource, trigger: RecoveryTrigger, mode: AudioMode) {
        // A410 — l'àncora del conteggio in silenzio, prima che `isRunning` vada a falso.
        // A412 — dentro la regola di ogni crisi (`CrisisStopDecision`), con la causa «configurazione»: per Apple un cambio
        // di frequenza dell'hardware è un cambio di configurazione del motore. Col Direttore muto in canzone l'àncora e il
        // silenzio, e la ripartenza qui sotto passa dal coordinatore (`RecoveryDecision`); per tutti gli altri come oggi.
        if crisisOutcomeQ(cause: .configuration) == .silentInSong {
            enterDirectorSilenceQ(cause: .configuration)
        }
        // L'arresto sulla coda (mandato A420, par. 2.1): lettore e motore, anche quando il motore l'ha già fermato il sistema
        // (cambio di configurazione: lo stop libera le risorse preparate, e il ricollegamento qui sotto le riprepara).
        isRunning = false
        stopPlayerAndEngineQ(context: source.stopContext)
        // A421 — un arresto di crisi consegna il drenaggio aperto (par. 2.2 j), pubblica lo specchio (par. 2.2 e: il buco del
        // ticket `TD-isplaying-resta-vero-dopo-lo-stop-del-direttore-muto`) e annulla i ritorni in attesa (par. 2.3 b).
        closeDrainOnCrisisStopQ(context: source.stopContext)
        publishIsPlayingQ(context: source.stopContext)
        cancelOutputReturnsQ(reason: source.stopContext)
        // RIENTRO-P1 (a) — arresto che non passa da `stopSync`: l'ingresso pendente, se c'è, si annulla qui. È il caso del
        // collaudo del 17/09/2026 (G3, 10:19:39): cambio di configurazione durante l'attesa d'ingresso, e il riavvio armava
        // un SECONDO ingresso accanto al primo.
        cancelPendingJoin(reason: source.joinReason)
        // A400 · R1 — arresto che non passa da `stopSync`: si abbassa qui anche il segno del proprio avvio.
        lowerOwnTransportStartQ(reason: source.stopContext)
        // La frequenza dalla fonte unica a tutte le copie, a motore fermo, e il grafo coi formati nuovi (A416: fino ad A415
        // la ricostruzione della configurazione prendeva la copia del motore, e alle 10:51 del 19/10 l'iPad è ripartito coi
        // nodi a 44100 e l'uscita a 48000).
        applySampleRateQ(context: source.formatContext)
        reconnectGraphQ(for: mode, caller: source.formatContext)
        applyChannelRouting(for: mode)
        let rateForScreen = sampleRate
        DispatchQueue.main.async {
            self.audioMode = mode
            self.sampleRateInfo = rateForScreen
        }
        // Il battito di ripresa (Backlog #15), con le latenze rilette dalla sessione e copiate nel ponte, come faceva il
        // cambio di configurazione: `link_engine_set_output_latency_ticks` scrive un numero atomico nel nostro ponte, non
        // nella sessione di Link (`LinkEngine.mm`), e `start()` lo riscrive poco dopo.
        let resumeBeat: Double?
        if let mh = midiEngineHandle {
            let avSession = AVAudioSession.sharedInstance()
            outputLatencyTicks  = secondsToMachTicks(avSession.outputLatency)
            bufferDurationTicks = secondsToMachTicks(avSession.ioBufferDuration)
            if let lh = linkEngineHandle {
                link_engine_set_output_latency_ticks(lh, outputLatencyTicks)
            }
            let hostTimeAtFirstSample = mach_absolute_time() + outputLatencyTicks + bufferDurationTicks
            resumeBeat = midi_engine_get_beat_at_time(mh, hostTimeAtFirstSample)
        } else {
            resumeBeat = nil
        }
        os_log("[Q-BEATS][ENGINE] ripartenza per la frequenza innesco:%{public}@ contesto:%{public}@ modo:%{public}@ battito:%.4f",
               log: .default, type: .default,
               trigger.rawValue, source.formatContext, "\(mode)", resumeBeat ?? -1.0)
        // Il tasto a stato finito, e la ripartenza dalla regola: il Direttore muto in canzone va al coordinatore.
        if _directorSilentInSongQ {
            publishDirectorSilenceQ(context: source.stopContext)
        }
        activateSessionAndStart(resumeAtBeat: resumeBeat, trigger: trigger)
    }

    @objc private func handleEngineConfigChange(_ notification: Notification) {
        // A416 (21/10/2026) — l'ora d'arrivo, letta qui prima del salto su audioQueue: la riga del buco del render la
        // confronta col buco (`RenderGapMeter`, mandato «USCITA-AUDIO-PASSO-1», §2.3).
        let arrivedTicks = mach_absolute_time()
        audioQueue.async { [weak self] in
            guard let self = self else { return }

            // A408 — l'osservatore è registrato con `object: nil` (`setupNotifications`): dopo la
            // ricostruzione il motore è un'altra istanza. Qui, su audioQueue, dove il motore si
            // scrive, passa solo il cambio di configurazione del motore corrente.
            // ⚠️ RISCRITTO A416 (21/10/2026). Fino ad A415, dopo il filtro sul motore corrente qui sopra, la guardia di
            // stato usciva muta, e dopo il reset dei servizi altre due uscite lasciavano il motore fermo con `isRunning`
            // vero, senza crisi e senza ripartenza (referto A415, §4.3, §4.7, §4.9): «SR mismatch … skip» (la frequenza
            // della sessione diversa dalla copia del motore) e, nei 20 s dopo la ripresa da un'interruzione, «Config
            // change post-interruption skip» (`lastInterruptionResumeTime`). L'origine dei 20 s: commit `7c0a8aa6` del
            // 22/04/2026, «[BUILD #148] AudioEngine: Temporal guard for anti-double snap», per non far ripartire il click
            // una seconda volta, con un secondo scatto alla battuta, al secondo cambio di configurazione che iOS manda
            // alla fine di una chiamata (BOX4 V3 del 23/04/2026, Blocco 7, fuori dal deposito). Ma qui si arriva solo col
            // motore già fermo: saltare non evitava una ripartenza doppia, lasciava il click muto. Da A416 una regola di
            // stato, pura e col suo banco (`EngineConfigChangeDecision`; mandato «USCITA-AUDIO-PASSO-1», §2.2): motore
            // fermo con `isRunning` vero, motore corrente e servizi audio «normali» ⇒ si riparte sempre, la ripresa
            // pendente compresa. L'arresto esplicito qui sotto abbassa `isRunning` prima di ripartire: una seconda
            // notifica per lo stesso arresto si ignora con la sua riga; i tentativi ripetuti hanno il gettone di
            // `activateSessionAndStart`. La frequenza la prende la ricostruzione dalla fonte unica (`rebuildGraph` →
            // `applySampleRateQ`).
            // ⚠️ A420 (23/10/2026): l'arresto esplicito, la ricostruzione e la ripartenza stanno nella funzione sola della
            // frequenza (`restartForRateChangeQ`, mandato A420, par. 2.3), che ferma lettore e motore sulla coda; la frequenza
            // la prende lì `applySampleRateQ`, non più `rebuildGraph`.
            let senderIsCurrent = (notification.object as? AVAudioEngine).map { $0 === self.engine } ?? false
            if senderIsCurrent {
                self._lastConfigChangeTicksQ = arrivedTicks
            }
            let step = EngineConfigChangeDecision.outcome(
                senderIsCurrent: senderIsCurrent,
                stateRunning: self.isRunning,
                engineRunning: self.engine.isRunning,
                audioWorkAllowed: MediaServicesResetDecision.allowsAudioWork(self._mediaServicesQ),
                pendingResume: self.pendingResume)
            switch step {
            case .notCurrentEngine:
                os_log("[Q-BEATS][ENGINE] cambio di configurazione di un motore non corrente, ignorato - mittente:%{public}@",
                       log: .default, type: .default,
                       notification.object.map { "\($0)" } ?? "nil")
                return
            case .ignored:
                // A416 — fino ad A415 questa uscita era muta (mandato §2.7, riga 1).
                os_log("[Q-BEATS][ENGINE] cambio di configurazione ignorato - isRunning:%d motoreGira:%d",
                       log: .default, type: .default, self.isRunning ? 1 : 0, self.engine.isRunning ? 1 : 0)
                // A421 — par. 2.2 b: col Direttore fermato dalla crisi delle cuffie, la notifica «ignorato» è il segnale del
                // ritorno che aspetta la configurazione (il 24/10 alle 12:35:50.637 è arrivata a motore fermo).
                self.noteConfigurationIgnoredQ()
                return
            case .mediaReset:
                // A408 — fuori da «normale» niente rebuildGraph sul motore vecchio e niente ripartenza (la riga la
                // scrive `mediaResetSkipsQ`).
                _ = self.mediaResetSkipsQ("cambio di configurazione")
                return
            case .recoverPending, .restart:
                break
            }

            // A416 — la ripresa pendente prende la stessa strada della ripartenza: prima l'arresto esplicito e la
            // ricostruzione, poi `activateSessionAndStart` con l'innesco di sempre («pending_recovery»). Fino ad A415
            // ripartiva da qui senza abbassare `isRunning`, e `start()` usciva alla sua guardia.
            let recoverPending = step == .recoverPending
            if recoverPending {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                os_log("[Q-BEATS][RESUME] pendingResume recuperato da EngineConfigChange - arresto esplicito e ricostruzione prima",
                       log: .default, type: .default)
            }

            os_log("[Q-BEATS][ENGINE] Config change detected — rebuilding graph and restarting",
                   log: .default, type: .default)

            // ⚠️ RISCRITTO A420 (23/10/2026). Da qui alla fine del blocco c'era il corpo di questa strada, scritto a parte: la
            // regola delle crisi con la causa «configurazione», `isRunning` a falso e il solo `playerNode.stop()` (il motore
            // l'aveva fermato il sistema), l'ingresso pendente annullato e il segno del proprio avvio abbassato,
            // `rebuildGraph(for: self.detectAudioMode(), context: "configurazione")`, le latenze rilette e copiate nel ponte, il
            // battito di ripresa, il tasto e la ripartenza, con l'innesco della ripresa pendente o del cambio di
            // configurazione. Da A420 è la funzione sola `restartForRateChangeQ` (mandato A420, par. 2.3), la stessa del cambio
            // di percorso con la frequenza nuova a motore in moto: in più ferma anche il motore sulla coda e rimette
            // l'instradamento dei canali e lo schermo. Gli esiti di `EngineConfigChangeDecision` e gli inneschi restano quelli
            // di oggi.
            self.restartForRateChangeQ(source: .configuration,
                                       trigger: recoverPending ? .pendingRecovery : .engineConfigChange,
                                       mode: self.detectAudioMode())
        }
    }

    @objc private func handleAppWakeUp() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            // A412 — anche il Direttore muto in canzone (il click non suona, `isPlaying` è falso): il ritorno dalla
            // sospensione passa dal coordinatore (mandato §2.2, D5; `RecoveryDecision`).
            // ⚠️ RISCRITTO A421 (24/10/2026). La guardia era «guard self.isPlaying || self._directorSilentInSongQ,
            // !self.isRunning»: leggeva `isPlaying` vero a motore fermo come «il click suonava», e vero a motore fermo lo
            // lasciavano solo due buchi (la ripartenza per la frequenza e il ramo del modo: il ticket
            // `TD-isplaying-resta-vero-dopo-lo-stop-del-direttore-muto`). Da A421 `isPlaying` è lo specchio di `isRunning`
            // e la guardia dice quello che serve davvero: il motore è fermo e c'è una strada che ci contava — la ripresa
            // pendente, o il Direttore muto in canzone (`TransportStateDecision`, mandato A421, par. 2.2 e). Una causa di
            // crisi viva non basta (dopo la verifica indipendente del diff): il Direttore fuori da una canzone fermato da una
            // tolta riparte col Play (U16), il Solo aspetta il Play, il Follower fermato da una chiamata lo riprende la fine.
            guard TransportStateDecision.wakeupRecovers(engineRunning: self.isRunning,
                                                        pendingResume: self.pendingResume,
                                                        silentInSong: self._directorSilentInSongQ) else { return }

            if self.pendingResume {
                self.pendingResume = false
                self.pendingResumeBeat = nil
                var recoveryBeat: Double? = nil
                if let mh = self.midiEngineHandle {
                    let hostTime = mach_absolute_time()
                                 + self.outputLatencyTicks
                                 + self.bufferDurationTicks
                    recoveryBeat = midi_engine_get_beat_at_time(mh, hostTime)
                }
                self.activateSessionAndStart(resumeAtBeat: recoveryBeat,
                                             trigger: .wakeupPendingRecovery)
                return
            }

            var resumeBeat: Double? = nil
            if let mh = self.midiEngineHandle {
                let hostTime = mach_absolute_time()
                             + self.outputLatencyTicks
                             + self.bufferDurationTicks
                resumeBeat = midi_engine_get_beat_at_time(mh, hostTime)
            }
            self.activateSessionAndStart(resumeAtBeat: resumeBeat, trigger: .appWakeup)
        }
    }
}