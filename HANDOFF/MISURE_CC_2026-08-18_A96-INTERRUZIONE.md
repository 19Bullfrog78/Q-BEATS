# MISURE CC — A96, TICKET INTERRUZIONE SESSIONE AUDIO (doc-only)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: zero righe sotto `ios_app/` (solo lettura), zero commit, zero diff — il mandato
stesso prevede che il giro possa fermarsi qui. Scrittura: solo questo referto, in `HANDOFF/` + R-δ.

Marcatura: **[M]** misurato ora.

---

## AGGANCIO — A96 libero

**[M]** Forma a token: `\bA96\b` → **0** in `HANDOFF/` e **0** su E:. Controllo positivo `\bA95\b` →
**2** file su entrambi. Non collide. HEAD invariato dal commit A95 (`44fea3e3…`).

---

## ① LA MISURA — e la premessa del mandato non regge

**[M] Nessuno degli zeri è vuoto.** Cercate tutte le forme indicate, con controllo positivo su
`addObserver` (l'elenco reale di cosa l'app ascolta oggi):

| forma cercata | occorrenze |
|---|---|
| `AVAudioSession.interruptionNotification` | 1 |
| `AVAudioSessionInterruptionNotification` (forma Obj-C) | 0 — **atteso**: il progetto usa la forma Swift |
| `interruptionNotification` | 1 |
| `InterruptionType` | 2 |
| `shouldResume` | 5 |
| `InterruptionOptions` | 1 |
| `AVAudioSessionRouteChangeNotification` | 0 — **atteso**: idem, forma Swift |
| `routeChangeNotification` | 1 |
| `AVAudioEngineConfigurationChange` | 1 |

**[M] Controllo positivo — cinque `addObserver` in tutto il progetto, tutti nello stesso posto**,
`ios_app/QBeats/AudioEngine.swift:2648-2658` (`setupNotifications()`): interruzione, cambio rotta,
reset dei servizi media, cambio configurazione del motore, rientro in foreground. Nessun altro file
registra osservatori: la forma di ricerca è corretta e non falso-zero.

⇒ **La premessa del mandato — «se l'app non ascolta la notifica, non se ne accorge» — è
letteralmente vera, e la conclusione che ne segue è falsa: l'app ascolta.**

### Cosa fa davvero, letto per intero (`AudioEngine.swift:2648-3000` circa)

**`.began`** (`:2667-2698`) — sotto lock: salva se Link era attivo, marca `isAudioInterrupted = true`,
ferma player e motore; **aggiorna lo stato visibile**: `isPlaying = false`,
`clickStatus = "audio muted — clock running"`. ⚠️ Nota tecnica di disegno, non un difetto: il clock
MIDI/Link **non si ferma** — commento esplicito nel codice, «NON notificare stop a Link» — perché la
posizione va ricalcolata al resume da `lastMachTime`, non salvata.

**`.ended`** (`:2700-2818`) — percorso a più livelli, non un semplice riavvio:
- **recupero pendente** se un `.ended` precedente aveva già impostato `pendingResume`;
- **filtro `shouldResume`**: se il sistema dice di no, arma un **timer di sicurezza autonomo a 1s**
  che forza comunque il recovery — l'app non resta mai bloccata in attesa di un evento che iOS a
  volte non manda;
- **guardia hardware**: se `session.mode` indica chiamata/registrazione ancora attiva, non riparte e
  richiede un nuovo giro;
- **ricostruzione del grafo**, ricalcolo del beat di ripresa **dopo** la riattivazione della
  sessione («il più tardi possibile», commento esplicito), e riaggancio in fase con Link.

**`handleRouteChange`** (`:2824-2957`) — cuffie staccate/riattaccate, cambio sample-rate, cambio
modalità Base/Pro: rebuild del grafo dove serve, mai fermando il clock C++ («B1 Hard Sync … MAI
`midi_engine_stop()` qui»).

**`handleMediaReset`** / **`handleEngineConfigChange`** (`:2959-3000`) — reset dei servizi media di
sistema e cambi di configurazione del motore, con guardia anti-doppio-trigger nei 20s dopo un resume.

⇒ **Non è codice minimale**: è un sistema con guardie multiple, un percorso di recupero autonomo, e
un'attenzione esplicita a non rompere la sincronizzazione Link durante l'interruzione — più
sofisticato di quanto la regola Apple citata nel mandato richieda come minimo.

### Validato su device — tre volte, non zero

**[M]** Non solo scritto: **provato sul palco**, tre episodi distinti, tutti in `BUGS_QBEATS.md`:

1. **`:401-407`** — ticket esistente (vedi sotto), sintomo osservato il 19/06.
2. **`:255`** — collaudo 19/06, «Test 3b (accenti dopo telefonata)» → **PASS**.
3. **`:1048`, changelog `\| 36 \|` (15/07)** — verbatim: «**Baseline Parte 2 (interruzioni audio) =
   PASS 3/3** (device Mauro, iPhone, log iMazing): **A** Control Center → nessuno stop, solo
   `scenePhase inactive/active`; **B** Notifica → ducking iOS, click continua; **C** Chiamata reale →
   `[INTERRUPTION] began→ended`, resume automatico su downbeat, click ripartito. **Criterio-bug**
   (click fermato SENZA riga `[INTERRUPTION]`) **non osservato in nessuno scenario**.»

⇒ **Il criterio-bug del test del 15/07 è esattamente lo scenario che questo mandato temeva** — «il
click si ferma e l'app non se ne accorge» — e la misura sul device dice che **non è mai successo**,
in tre scenari diversi incluso una chiamata reale.

### Un ticket correlato esiste già, ed è un difetto diverso — non tocco nulla

**[M]** `BUGS_QBEATS.md:400-407`, «Ripresa da interruzione (telefonata) riparte da capo —
single-device», 🟡 OPEN BASSA. Letto per intero: sintomo del 19/06 (in standalone, dopo una
telefonata la setlist «riparte da capo» invece di riprendere dal punto). **Il ticket stesso nota già**
che il test del 15/07 ha dato l'esito opposto sulla stessa famiglia di eventi («al resume da chiamata
reale il click ha mantenuto la posizione … NON è ripartito da capo») e formula l'ipotesi che il
sintomo del 19/06 richieda **background prolungato**, non la semplice interruzione — quindi un fronte
diverso dalla gestione dell'interruzione stessa, già distinto nel ticket da Test 1/Link
(«fronti separati, NON fondere»), già assegnato a CC, già in coda dopo TD#17.

⇒ **Non è lo stesso difetto** che il mandato proponeva di aprire, **è già tracciato**, e la sua
collocazione e priorità sono già motivate nel testo. Non lo tocco: eccede la proporzione di questo
giro, ed è comunque doc-only da riesumare nel suo turno.

---

## CONCLUSIONE — il ticket non si scrive

Come dispone il mandato: **la misura dice che l'app già gestisce le interruzioni.** Ci si ferma qui.
Nessun `TD-audio-interruption-non-gestita`, nessun diff, nessuna incisione in BUGS.

---

## CODA — osservazioni minori, elencate e non toccate

1. **[M]** `clickStatus` (la stringa che si aggiorna a «audio muted — clock running» durante
   un'interruzione) è letta **solo** da `ContentView.swift:23` — il pannello dietro la porta
   ⚙ DEBUG. Nella Vista LIVE reale non ho trovato un consumo dello stesso campo o di
   `isAudioInterrupted` per un segnale visibile all'utente durante la pausa. Non è il difetto che il
   mandato temeva (il motore SA di essere interrotto, e si comporta di conseguenza) — è una domanda
   diversa, "il musicista sul palco lo vede?", che il mandato stesso classifica come «a valle della
   misura», eventualmente di dominio CD. Non indagata oltre, non aperta come ticket.
2. **[M]** Il codice di interruzione è fra i più vecchi del progetto — nato in `b047907` (07/04) e
   corretto in `ccf2272` (08/04, «fix: interruption handler shouldResume»). È maturo, non recente.

---

*A96-INTERRUZIONE-FINE*
