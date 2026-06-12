# BUGS_QBEATS — Tracker centralizzato bug e tech debt

**Versione:** 7
**Ultima modifica:** 2026-06-12
**Autore iniziale:** CC chat principale 26/05/2026 sera
**Repo:** `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\`

---

## Scopo e ambito

Documento di riferimento **UNICO** per tutti i bug e tech debt (TD) Q-BEATS. Aggrega in un unico posto ciò che prima era distribuito tra `project_qbeats.md` (memoria CC), `LIBRO_MASTRO_QBEATS.md` (libro mastro), `BOX3` (briefing sessione), e chat sparse.

**Regola d'oro:** se un bug non è qui non esiste come voce tracciata. Se compare in una chat ma non finisce qui, viene perso.

**Cosa entra qui:**
- Bug funzionali (sintomo visibile utente)
- Tech debt (codice/architettura da pulire)
- Anomalie diagnostiche aperte
- Bug chiusi (per riferimento storico, non si cancellano mai)
- Bug scartati / smentiti (per evitare ri-aperture)

**Cosa NON entra qui:**
- Deliverable di prodotto / UX (vivono in `LIBRO_MASTRO_QBEATS.md` Sezione 3)
- Decisioni cross-team ratificate (vivono in `LIBRO_MASTRO_QBEATS.md` Sezione 2)
- Lezioni di processo (vivono in memoria CC `feedback_qbeats_*.md`)
- Cronologia commit operativa (vive in memoria CC `project_qbeats.md`)

---

## Convenzioni

### ID bug
- `TD #N` — numerazione storica esistente (non riassegnare)
- `TD-<short>` — bug non numerati (sintomo descrittivo)
- `Bug N` — bug funzionali numerati separatamente (es. Bug 4 Link sleep/wake)

### Stato
- 🔴 **OPEN ALTA** — bloccante palco o richiesto entro 2 settimane
- 🟠 **OPEN MEDIA** — non bloccante palco, da chiudere pre-release v1
- 🟡 **OPEN BASSA / SOSPESO** — backlog post-v1 o sospeso in attesa di dati / decisione
- 🟢 **CHIUSO** — fixato e validato su device (regola `feedback_qbeats_chiuso_solo_dopo_device`)
- ⚫ **SCARTATO** — diagnosi smentita o causa fuori controllo Q-BEATS

### Priorità palco
- 🚨 **BLOCCANTE PALCO** — non possiamo suonare live con questo bug aperto
- ⚠️ **NON BLOCCANTE** — fastidio ma palco fattibile
- 📦 **BACKLOG** — pre-release v1 o post-v1

### Workflow aggiornamento
1. Nuovo bug emerge in chat → CC lo aggiunge qui PRIMA di proporre fix
2. Bug viene fixato → CC aggiorna stato a 🟢 CHIUSO con commit di riferimento
3. Diagnosi smentita → CC sposta in Sezione "Scartati / smentiti" con motivazione
4. Modifiche al file → diff letterale in chat, commit `BUGS_QBEATS.md: vN — [decisione]`

---

# Sezione 1 — Bug APERTI

## 🚨 1.1 — Bloccanti palco (🔴 OPEN ALTA)

### TD-follower-rejoin — Aggancio Follower difettoso al ri-Play / cambio setlist (audio)
- **Sintomo (per run, NON fusi):** sul device **Collaborative/Follower**, al **ri-Play** (Play→Stop→Play) o al **cambio setlist**, l'avvio è difettoso. **Director pulito.** Casi osservati su device:
  - **3/4 Long, ri-Play:** sbaglia **solo la prima battuta**, poi il `sync_phase` raddrizza.
  - **BPB Mixed, ri-Play:** disallineamento **per tutta la canzone**.
  - **Stop in 5/4 + idle lungo → Play:** prompter **riparte da sezione 0 (corretto)**, metronomo **resta a 5/4 (stale)**.
  - iPhone **"non ingrana"** (display popolato, barretta/LED fermi); avvio talvolta **abortito**.
  - striscia segmenti metronomo **stale** (es. 3 invece di 4 dopo cambio setlist).
- **Causale: IPOTESI FORTE — DA VERIFICARE IN CODICE** (NON dichiarata identificata). Quattro meccanismi candidati **distinti** (non assumere radice unica):
  - **✅ (A) = FERITA A — 🟢 CHIUSA 10/06/2026** (device-validata TEST6 + ratificata Mauro+referee), fix `7904ca8` (`armSharedJoin`, ingresso finalizzato al fire) = implementa la "Direzione fix proposta" sotto. Vedi banner §Bug 2.b. **(A) Corsa di fase all'aggancio.** Ramo SHARED di `start()` (`AudioEngine.swift:751-866`) calcola `attesa = quantum − probe.phaseAtHost` con la fase Link letta **allo schedule** del work item; il Director **resetta la timeline ad ogni Play** (`link_engine_start_at_beat_zero`, `:742`). Se il Follower legge la fase **prima** che il nuovo beat-zero si propaghi, calcola l'attesa sulla **griglia vecchia** → `futureHostTime` cade **fuori dal downbeat**. **Dato (01/06, IPA #466, log iPhone):** 4 avvii, spia `[Q-BEATS][Bug2b] WARN aggancio non su downbeat`, `frazione` = **0.462 / −0.279 / (abortito) / 0.496** (grande e variabile). Wording dei due avvii anomali: **14:46:21** = "frazione −0.279 calcolata allo schedule; confermato: `downbeat raggiunto` assente nel log — aggancio non completato"; **14:46:44** = "abortito, nessuna frazione calcolata".
  - **(B) Gap di propagazione reset L3→L1.** `startSetlist`→`updateSessionDisplay` (sincrono) resetta il prompter a sezione 0, ma la metrica del metronomo (`beatsPerBar`/`_beatsPerBarQ`, applicata **al primo beat tick post-arrivo** quando `isPlaying`) resta stale → prompter sez 0 / metronomo 5/4. Device-confermato 01/06.
  - **(C) Il runner non resetta (`startSetlist` non invocata).** Due percorsi candidati, entrambi **DA CONFERMARE**:
    - **(C-veloce):** Play→Stop→Play **veloce** — `stop()` dispatcha `.stopped` async (`LiveView.swift:224`); se `linkStartedSubject` arriva con stato ancora `.playing`, il guard `LiveView.swift:402` scarta `startSetlist` → reset a sezione 0 mai eseguito.
    - **(C-idle):** ri-Play **dopo attesa lunga** — percorso distinto (dopo minuti `.stopped` è già atterrato, quindi NON è la stessa finestra): possibile re-join con **Link stantio** (famiglia **TD #17**) che non ri-triggera `startSetlist`.
    - Nota: i casi osservati dopo attesa lunga finora mappano sulla **faccia (B)** (prompter resetta a sez 0, metronomo stale) — distinti da (C).
- La **quarta faccia (D — offset di barra / counter "bar 2 di N" a partenza pulita)** è **ri-alloggiata in §1.2 — "Bug 2.b (faccia visiva/counter)"** (faccia ii); dettaglio lì.
- **Relazione con Bug 2.b:** **Ipotesi (non verificata in codice):** queste facce sono state **rese visibili** dal fix Parte 1 (`45faa90`) — prima la ri-derivazione continua in `setBeatPosition` raddrizzava entro pochi sample una partenza storta; rimossa quella (corretto — era la causa dell'accento di Bug 2.b), l'errore di **aggancio all'avvio** emerge. Cosa **distinta** da Bug 2.b: 3/4 Long a **partenza pulita** è verde (l'accento ai cambi di tempo è risolto).
- **Direzione fix (proposta, NON ratificata):** eliminare la corsa — il Follower **ri-legge la fase Link AL FIRE** del work item (non allo schedule) e aggancia al **downbeat reale** della timeline del Director, oppure **attende** che il beat-zero del Director sia visibile prima di calcolare l'attesa. Legato al seme `_sectionBeatCounter` (`0693e39`, **merge-gate** Bug 2.b) e a **TD #36** (quantum al cambio sezione). **Niente pezze sui buffer/skip.**
- **Stato:** **faccia (A) = Ferita A → 🟢 CHIUSA 10/06/2026** (device-validata TEST6 + ratificata Mauro+referee, fix `7904ca8`). **Facce (B) gap-reset L3→L1 [= UI segmenti stantii], (C) runner-non-resetta: 🔴 RESTANO OPEN; (D) offset-barra/counter → ri-alloggiata in §1.2 ("Bug 2.b faccia visiva/counter", 🟠).** Causale (B/C) = ipotesi forte (non identificata). **NON chiuse** (regola `feedback_qbeats_chiuso_solo_dopo_device`).
- **Verifiche residue — log 15:08–15:09 NON più disponibile (né device né chat) → da RI-CATTURARE in un test futuro; il FIX resta gated su questi dati:**
  - riga `startSetlist … sectionIdx:0` (presente/assente = **discriminante della faccia C**);
  - serie completa `[SinkDiag-AQ]` / `beatTick` (faccia D → ora **§1.2 "Bug 2.b (faccia visiva/counter)"**: contatore fermo o no — finora solo 2 campioni a 32, insufficienti);
  - righe `beatsPerBar` / sezione corrente (faccia B; faccia D → ora §1.2 "Bug 2.b (faccia visiva/counter)").
  Registrazione attuale = **sintomi**; fix subordinato alla cattura di questi dati.
- **Dominio:** CC.

### TD #A — First-beat-fuori cross-device
- **Sintomo:** al primo beat dopo `play`, il device Collaborativo entra 30-105ms dopo il Director. Sistematico cross-BPM (non rumore). Misurato cross-play, cross-device.
- **Misura:** ritardo `T4→T5` (calcolo `futureHostTime` → primo render buffer audio post pre-roll) = 98-118ms media ~105ms. Single-sample iniziale 24/05 era ~70ms (sottostima). Timebase iPad confermato = 24 MHz (1 tick ≈ 41,666 ns). startBeat finale 0,032-0,036 beat ≈ 32-36ms a 100 BPM.
- **Causa ipotizzata:** delta tra arrival time del play start callback su iPad Collaborative vs initial Force di iPhone Director. Possibile dispatch chain main→audioQueue→pre-roll dominante.
- **Stato:** in attesa raccolta dati Sessione 1 (vedi sotto). Senza dati nuovi non si può progettare fix.
- **Branch diagnostico:** `feat/diag-first-beat-and-beat-drop-and-3-4-long` (commit `70bb86a` + `31dddbb`). CI run [`26361824809`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/26361824809) ✅ verde, IPA pronto.
- **Test da fare (Mauro su device):** installa IPA, setup 1D+1C (iPad Collaborative, iPhone Director), play, raccogli log iMazing iPad `[Q-BEATS][DIAG-A][T0]→[T9]`. Ripeti 3-4 play per campioni multipli.
- **Analisi delta attesi:** T0→T1 main dispatch jitter; T1→T2 main→audioQueue; T4→T5 dovrebbe match `delaySec` loggato in T4; T8→T9 ~immediato. Discrimina pre-roll latency vs dispatch chain dominante.
- **Vincolo metodologico:** NIENTE fix prima della causale chiarita (regola memoria attiva).
- **Note:** vive sul baseline `cb92faa` indipendentemente dal three-band — esisteva già su master prima del fix three-band. **Generalizzato a "ogni inizio sezione"** (Build 110 entrata 26ms vs regime 13ms = first-beat-fuori intra-setlist, non solo play start).
- **Roadmap:** parte del blocco audio unitario 🔴 referee 24/05 (TD #A + three-band v2 + Test 2 Audacity).

### TD #17 — Link perde peer dopo sessioni lunghe (🚨 BLOCCANTE PALCO — CONFERMATO 11/06)
- **Sintomo:** dopo sessioni lunghe Link smette di vedere peer. Recovery: toggle Link OFF/ON, oppure uscire/rientrare dalla vista.
- **CONFERMATO 11/06/2026 (TEST7 RUN9, 121 BPM):** peer perso a metà giro dopo ~2h15 in foreground attivo, **WiFi vivo**, zero eventi ScenePhase sul Follower. Il **tempo NON è andato fuori** (free-run −11 ms tenuto 16,6 s senza peer); danno **solo finale** (lo stop del Direttore non si propaga → il Follower finisce la propria setlist da solo ~1,5 s). **Recovery = uscire/rientrare dalla vista Direttore** (ri-init Link) → peer ri-formato all'istante.
- **Stato:** 🔴 **OPEN — 🚨 BLOCCANTE PALCO** (non si può avere il Follower che prosegue dopo lo stop). Parzialmente coperto da Bug 4 (`6d1dbbf`) per il ciclo background/foreground; questo scenario è **foreground attivo prolungato**, distinto. Merge Bug 2.b avvenuto 11/06 (`ee0cbc0`) → **round dedicato SBLOCCATO = prossimo step** (cattura log iPad+rete in sessione lunga foreground). **Servono log iPad/rete** (nel log Follower la causa non c'è: zero righe wifid/AWDL/mDNS attorno all'evento).
- **Dominio:** CC (+ rete).

## ⚠️ 1.2 — Non bloccanti palco, da chiudere pre-release v1 (🟠 OPEN MEDIA)

### TD #34 — Race condition `link_engine_set_start_stop_callback`
- **Sintomo:** potenziale crash mid-session su transizioni start/stop rapide.
- **Stato:** da verificare empiricamente. NON consolidare a priori "stessa causa TD beat drop": race su scope diversi (main↔audioQueue vs audioQueue↔audio thread).
- **Test da fare:** stress test start/stop rapidi cross-device.
- **Roadmap:** Item 3 roadmap CC.

### TD #39 — Link sync quantum mismatch peer in TS incompatibile (🟡 SOSPESO post-Step 0)
- **Sintomo:** cambio BPB con peer SB attivo via Link → click orfano + accent shift permanente ~3s dopo transizione. Sparisce in Q-B standalone. Si manifesta SOLO con peer Link + cambio BPB.
- **Causa nota:** post-scadenza `linkSyncSkipBuffers=100`, `link_engine_sync_phase` legge consensus Link inconsistente (Q-B quantum=NEW, SB quantum=OLD hardcoded) → `metronome_set_beat_position` riscrive `_currentBeatInBar`/`_exactNextBeatSample`.
- **Stato:** 🟡 sospeso post-Step 0. Test 3/4 di Step 0 era 2 battute, troppo corto per mismatch progressivo. Step 0 ha misurato 21ms regime su 2 battute = prove of life ma non conclusivo. Per chiudere o riaprire serve test su sezione 3/4 di 8-16 battute.
- **Prerequisito:** Item 5b setlist 3/4 Long DebugView (✅ già committata `70bb86a` sul branch diagnostico, in attesa test device).
- **Test da fare:** Audacity 5 misure dentro sezione 3/4 16 battute (inizio + ¼ + ½ + ¾ + fine). Confronto con baseline 4/4 Intro 100 12ms (Step 0). Se 3/4 lungo drifta progressivamente → TD #39 riaperto 🔴. Se stabile → TD #39 chiuso retroattivamente da `cb92faa`.
- **Possibili fix (se confermato):** estendere `linkSyncSkipBuffers` post-cambio BPB / bloccare `sync_phase` post-quantum-change / verificare consenso peer prima di applicare.
- **Roadmap:** Item 5 roadmap CC. Sblocco condizionato a Item 5b + test.

### Three-band v2 — Riprogettazione smoothing `sync_phase`
- **Contesto:** Step 0 ha misurato Slow 90 baseline `cb92faa` regime = 25ms (fuori target stretch <15ms). Versione three-band originale `c766fd5` peggiora Slow 90 a 30ms → NON mergeata.
- **Design alternativo:** smoothing a valle in `metronome_set_beat_position` + `midi_engine_set_beat_position` (DSP locale), `sync_phase` ritorna `linkBeat` puro.
- **Stato:** in attesa di analisi codice completa PRIMA di qualsiasi implementazione. Branch dedicato `feat/sync-smoothing-downstream` quando attivato.
- **Vincolo metodologico:** smoke test cross-device PRIMA dei test di precisione (lezione three-band v1 24/05).
- **Branch di riferimento storico:** `feat/collab-sync-three-band` (commit `c766fd5`) — open su origin, NON merged, riferimento per design da cui prendere spunto + da evitare.
- **Roadmap:** Item 4 roadmap CC. Motivazione empirica c'è (Slow 90 fuori target stretch).

### Bug 2.b (faccia visiva/counter) — desync sezione/time-sig cross-device, SOLO visivo (🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE)
- **Inquadramento:** Bug 2.b è 🟢 CHIUSO lato **audio + ingresso** (Ferita A+B, TEST7, Sez. 2). Restano APERTE le facce **visive/counter** dello stesso desync sezione/time-sig cross-device: il fix audio non le tocca. Audio corretto, sbagliato solo ciò che si vede.
- **Faccia (i) — striscia segmenti metronomo 3 invece di 4 (Slow 90 4/4, Follower con peer):** in Link (iPad Direttore + iPhone Follower) la Slow 90 suona corretta 4/4 ma la striscia segmenti del Follower mostra **3 riquadri invece di 4**. **Sparisce senza peer** (senza Link sono 4) → natura **cross-device** confermata. Codice: `MetSlotStripView` disegna `displayAccentPattern.count` (callsite unico `LiveView.swift:94`); con peer il pattern accenti rispecchiato risulta lungo 3. Osservato su build **474** (`add556f`, branch `test/bug2b-test7-fixtures`) = codice master + sola fixture `DebugView.swift` (+37 righe, setlist test "BPB Mixed 121"); path UI/Link/audio byte-identico a master `ee0cbc0` → faccia visiva su codice di produzione, non artefatto del build di test (475 `ee0cbc0` = squash codice; 476 `3af4c97` = doc-only; entrambe NON installate). Osservazione Mauro 12/06.
  - **Repro preciso (device Mauro 12/06):** percorso **BRIDGE 3/4 → SONG B → SLOW 90 (4/4)**; con peer, entrando in SLOW 90 la striscia mostra **3 segmenti FISSI per tutta la sezione**, fino al cambio tempo successivo (**110 BPM**) che ri-pubblica e sblocca.
  - **Sorgente del "3" (inferenza forte, NON "confermato"):** il 3 **COMBACIA col BPB della sezione 3/4 nel percorso** — il pattern lungo 3 della 3/4 resta esposto nella 4/4 = forte evidenza a favore dell'ipotesi BPB-stantio. La sezione-sorgente esatta e la riga di codice restano da inchiodare in codice/log.
  - **Ipotesi candidata (struttura verificata in codice, causa NON inchiodata):** sul Follower l'ordine di start è invertito — il callback Link chiama `engine.start()` PRIMA che `runner.startSetlist` imposti il pattern della sezione (`AudioEngine.swift:533-539`, ordine inverso del percorso locale `SetlistRunner.swift:135`); `start()` pubblica un pattern DEFAULT lungo `_beatsPerBarQ` (`AudioEngine.swift:1020-1025`) → il 3 della 3/4 precedente resta esposto.
  - **Sotto-domanda momentaneo-vs-persistente: RISOLTA verso il PERSISTENTE per questo repro** (osservazione device diretta 12/06; lo storico 31/05 "per un attimo" resta valido come osservazione di allora). **Ipotesi etichettata come tale finché il log iPhone (`displayAccentPattern`/`currentAccentPattern` con e senza peer) non inchioda la riga.**
  - **Controllo a occhio 4° beat: ✅ ESEGUITO (video Mauro 12/06) — firma CONFERMATA.** Ciclo osservato in SLOW 90 (4/4, audio corretto, il 4° beat viene battuto): beat 1 → 1° segmento verde (accento), beat 2 → 2° bianco, beat 3 → 3° bianco, **beat 4 → niente si accende** (il 3° si spegne), poi riparte dal 1°. = `beatActive`=4 cade fuori dai 3 slot (`MetSlotStripView.swift:10`): la striscia sta letteralmente disegnando la battuta da 3 della sezione precedente mentre l'audio batte 4/4. Video registrato da Mauro = evidenza device (da archiviare in `E:\…\LOG\RUN\`).
  - **Timing del flip (video Mauro 12/06) — FATTI OSSERVATI, CONFERMATI:** sequenza: arrivo da 3/4 → standby "TEST SONG B" → tap → il Direttore fa la prima battuta in solitaria (4 beat, da progetto); in quei 4 beat il display del Follower si popola con **4 segmenti (corretti)** e counter «bar 2 of 3» (da progetto CD-Q1=B: il Follower entra a battuta 2); **il flip 4→3 avviene ESATTAMENTE al momento del join** (ingresso del Follower col Direttore); il 3 persiste fino al cambio successivo (110). Il flip-al-join **scarta il candidato "la correzione non arriva mai"**: il valore corretto c'era, poi è stato sovrascritto.
  - **Lettura CANDIDATA (IPOTESI, riga da inchiodare col log):** al join un publish con `_beatsPerBarQ` stantio=3 (candidato: quello di `engine.start()`, `AudioEngine.swift:1020-1025`) sovrascrive il 4, e niente ripristina il valore corretto fino al cambio successivo (110). Meccanismo candidato che concilierebbe la tensione sotto: il publish di `start()` viaggia su `main.async` (stessa dispatch che setta `isPlaying`) → potrebbe atterrare AL FIRE del join, DOPO il publish del runner fatto al tap → ultima scrittura = stantio. **Da confermare col log, non è un dato.**
  - **QUESTIONE APERTA per il log (NON chiusa):** la struttura verificata in codice è `engine.start()` chiamato PRIMA di `runner.startSetlist` — presa da sola, l'ultima scrittura sarebbe quella corretta del runner e a vincere sarebbe il 4; invece sul device vince e persiste lo stantio (3). L'esatta sequenza dei publish attorno al join (chi scrive per ultimo, e perché lo stantio non viene ripristinato) è ciò che il log iPhone deve inchiodare.
- **Faccia (ii) — counter "bar 2 di N" offset a partenza pulita (ex faccia D di TD-follower-rejoin §1.1):** il Follower mostra offset di barra (es. "bar 2 di 4") anche ad aggancio pulito. Parte counter di **CD-Q1=B** (deliverable CD, rimandato a Fase 6-7-bis). Origine: BUGS v2 (Bug 2.b "counter offset + desync visivo"). Dato finora: 2 campioni `[SinkDiag-AQ]` a 32 (insufficienti) — serie completa da catturare (vedi §1.1 verifiche residue).
- **Distinta da (NON fondere):** TD-follower-rejoin **faccia B** (§1.1, "segmenti stantii DOPO cambio setlist", audio a volte stale) → **trigger diverso** (cambio setlist vs steady-state; audio stale vs corretto). Stessa firma visiva, meccanismo da falsificare prima di consolidare.
- **Stato:** 🟠 OPEN MEDIA, ⚠️ non bloccante (audio corretto, info visiva sbagliata sul palco), pre-release v1. **Fix subordinato al log iPhone.** Verde solo dopo device.
- **Dominio:** CC (+ CD per il counter CD-Q1=B).

## 📦 1.3 — Backlog (🟡 OPEN BASSA)

### Doppio-click Direttore al confine di sezione (pre-esistente, NON FIX-B)
- **Sintomo:** sul canale Direttore, al cambio di metro, click **sdoppiato** (2 attacchi ripidi, gap **13–18 ms**, 2° lobo 0,5–0,9 del primo). Udibile come leggera distorsione; **non bloccante** (il beat esce in posizione).
- **Pre-esistente, NON introdotto da FIX-B:** stessa firma già in **α-TEST3 (8/06, `63fc3d2`)**; assente nelle baseline 470/472. Correla 4/4 con le build che toccano il DSP del mark (α + FIX-B); **solo a 120 BPM** nei dataset (mai a 121 — ma 121 testato solo su FIX-B). Escluse eco (attacco ripido ≤0,75 ms) e crosstalk (rientro canali 2,7%; offset Dir↔Fol −9 ms).
- **Causa NON inchiodata:** famiglia race `==`-fire / kickScheduling al confine (`BUGS:116-124` / PIVOT-5), sensibile a spb intero. Contraddizione aperta: i callsite provano che FIX-B **non gira** sul Direttore al confine (`setBeatPositionTimeOnly` solo ramo sync `AudioEngine.swift:2260` = Follower; meter-swap `MetronomeDSP.cpp:365-367` intatto da FIX-B), eppure i doppi correlano con le build DSP-modificate.
- **Arbitro = log iPad** (mai catturato). Test decisivo: A/B **TEST7-vs-472 stessa sessione** + log iPad (1 emissione L1 + 2 click WAV = doppio-render pre-esistente; 2 emissioni = doppio-fuoco DSP).
- **Stato:** 🟡 OPEN BASSA. Dominio CC.

### WAITING FOR DIRECTOR persiste con Ableton Link OFF (candidato)
- **Sintomo:** con Ableton Link disattivato, tap Play in modalità Collaborative → resta in WAITING FOR DIRECTOR invece di partire normale. Il badge FOLLOWER sparisce correttamente (NON è il problema); `_linkMode == .collaborativa` resta in memoria (corretto, preferenza utente fail-safe `cb92faa`).
- **Causa ipotizzata (da confermare al codice):** il trigger della Vista WAITING FOR DIRECTOR è gated su `_linkMode` (che persiste) invece che sullo stato **Link-attivo** (`ABLLinkIsEnabled`/`SetActive`) — asimmetria col percorso di start del metronomo, gated correttamente su Link-attivo.
- **Stato:** 🟡 candidato — **perimetro ri-tagliato 12/06 dal ridisegno modalità (§1.4):** resta vivo SOLO il lato tecnico (trigger gated su `_linkMode` invece che su Link-attivo), assorbito dal lavoro CD-7.
- **Note:** la domanda UX "Link off / no peer = modalità normale" è **RISOLTA 12/06** (sì → standalone; direzione ratificata Mauro, libro mastro Sez. 2 — non più da girare a CD). Il riferimento al default `.collaborativa` "fail-safe corretto" è superseded (default → Standalone, ridisegno 12/06). **CD-Q2=B: regola invariata («il Follower aspetta il Direttore»), ambito ristretto dall'opt-in (vale solo col ruolo Follower assegnato a mano, non più di default) — non riaperta.**
- **Dominio:** CC (gate del trigger) + CD (UX).

### Header BPM·tempo errato pre-Play al primo caricamento setlist
- **Sintomo:** al primo caricamento di una setlist dopo l'avvio dell'app, l'header (`Test Song A · 120 · 4/4`) mostra il BPM/tempo di **default del motore (120)** invece di quello della prima sezione (es. Intro 100). Si **auto-corregge premendo Play** e non si ripresenta finché l'app resta aperta.
- **Causa (verificata 29/05):** `primeDisplay` (`SetlistRunner.swift`) setta correttamente `session.currentBPM` alla prima sezione, ma `onReceive(audioEngine.$currentBPM)` in `LiveView.swift` lo **sovrascrive** col valore corrente del motore (default 120 finché non parte il Play). Residuo del "Problema A" (display init pre-Play).
- **Fix probabile:** guardare l'`onReceive` perché aggiorni l'header solo durante il Play, lasciando valido il valore primato pre-Play. Poche righe, modifica separata e dedicata.
- **Stato:** 🟡 cosmetico, non bloccante (audio sempre corretto). Verificato che L1.b (dato setlist) è corretto.

### Issue B — Microbar fantasma pre-Play
- **Sintomo:** tra il tap su Play e la partenza dell'audio, 2-4 microbar bianchi si accendono in modo errato per ~1s, poi si spengono allineandosi quando parte la canzone. Osservato anche al riavvio in START LOCAL.
- **Stato:** 🟡 backlog, investigazione separata. Render gating su stato brano armato.
- **Dominio:** CC.

### TD #19 — Popup "Non Disturbare o Aereo" da aggiornare
- **Sintomo:** popup esistente in app dice "abilita Non Disturbare o Aereo" ma non spiega che Modalità Aereo "pura" spegne WiFi → Link KO.
- **Fix:** aggiornare copy popup con istruzione "Aereo + WiFi manuale ON" per uso live Link-friendly.
- **Dominio:** CD per copy + CC per implementazione.
- **Riferimento:** memoria `project_qbeats_link_aereo_popup.md`.

### TD #20 — Test G doc — codice difensivo non testabile
- **Note:** codice di guard difensivo che non si può testare su device direttamente (richiede condizioni rare). Da documentare per test review futuro.

### TD #21 — `when.isHostTimeValid` guard non implementato
- **Sintomo:** nel tap block manca guard `when.isHostTimeValid` per gestire timing invalidi.
- **Impatto:** non bloccante, edge case raro.

### TD #22 — Pin Xcode runner GitHub Actions
- **Note:** Xcode su runner GitHub Actions usa `xcode-latest`. Per dev install via iMazing OK. Diventa hard requirement quando si apre discorso App Store submission (build determinismo).
- **Insieme a:** TD #31 (Node.js 20 deprecation), TD #32 (Dual entitlements).

### TD #30 — Workflow CI step `Verify entitlements` rotto
- **Sintomo:** comando `codesign -d --entitlements :- ...` usa sintassi `:-` deprecata in macOS toolchain recente. Su `macos-latest` produce silenziosamente `<dict></dict>` vuoto invece dell'output reale.
- **Impatto funzionalità app:** zero — gli entitlements vengono comunque applicati al binary (confermato indirettamente da TD #27 verde su device + multicast preservato post-TD #44 fix).
- **Impatto diagnostica:** alto — perso strumento per verificare regressioni future entitlements.
- **Fix proposto:** sostituire `:-` con path file temp (`codesign -d --entitlements /tmp/ent.xml ... && cat /tmp/ent.xml`) o flag `--xml --entitlements -`. Una riga nel workflow.
- **Priorità:** bassa, da fixare insieme a TD #31 + TD #32.

### TD #31 — Workflow CI Node.js 20 deprecation
- **Sintomo:** warning nelle GitHub Actions per `actions/checkout@v4` e `actions/upload-artifact@v4` su Node.js 20.
- **Impatto:** hard fail prevedibile entro 2-3 mesi.
- **Fix:** aggiornare actions a versioni Node.js 22.

### TD #32 — Dual entitlements file Dev/Distribution
- **Sintomo:** `get-task-allow=true` di TD #27 è compatibile solo con Development profile.
- **Impatto:** pre-submission App Store servirà secondo file entitlements senza la chiave + variante CI.
- **Insieme a:** TD #22 + TD #30 + TD #31.

### TD #33 — Formula bpb-dipendente in `scheduleBPMChange`
- **Sintomo:** bypassata da `atNextBeat:true` ma residua per altri caller.
- **Impatto:** non bloccante finché tutti i caller usano `atNextBeat:true`.

### TD #37 — `currentBeat` unused in firma C `link_engine_set_bpm_and_beat_at_time`
- **Stato:** parametro lasciato in signature C con `(void)currentBeat` per non toccare callsite Swift post-Strada C (commit `6c4a9cc`).
- **Fix:** cleanup firma C + callsite Swift, quando bug Link sync chiuso e validato a regime.

### TD #38(b) — 4/4 con accent backbeat `[2,1,2,1]` visivo "2/4"
- **Sintomo:** accent pattern `[2,1,2,1]` mostra correttamente 2 accenti su 4 beat, ma percezione visiva "2/4" invece di "4/4".
- **Stato:** spostato a **backlog CD** dopo analisi: NON è bug tecnico ma decisione di design.
- **Decisione richiesta:** CD deve decidere se rendere visivamente i 4 beat distinti o se il comportamento attuale è quello voluto.

### TD #38(c) — Potenziale off-by-one rendering 5/4
- **Stato:** non emerso al test 17/05. Solo se rifacciamo 5/4 e vediamo off-by-one rendering separato.

### iCloud Opzione B (Apple Developer Portal)
- **Contesto:** rimossa iCloud capability da `project.yml` (commit `4e9d12f`) per sbloccare exportArchive durante TD #44 fix. Reverse possibile quando serve iCloud sync cross-device.
- **Lavoro Mauro (~15 min):** enable iCloud capability su identifier `com.bullfrog.qbeats` su Apple Developer Portal + regenerate `QBeats_Dev_Profile` + base64 generation via PowerShell + update GitHub Secret `PROVISIONING_PROFILE`.
- **Lavoro CC (~5 min):** reverse del commit `4e9d12f` re-aggiungendo `com.apple.developer.icloud-container-identifiers` + `com.apple.developer.icloud-services` sia in `project.yml.properties` sia in `QBeats.entitlements` checked-in.
- **Scadenza:** prima che serva la feature iCloud sync cross-device. Nessuna deadline.

### Step 2 warning UX SettingsView (post fail-safe LinkMode .collaborativa)
- **Contesto:** commit `cb92faa` 25/05 ha cambiato default LinkMode da `.direttore` a `.collaborativa` come fail-safe vs scenario 2-Q-B sulla stessa rete (tug-of-war su `ABLLinkForceBeatAtTime`). UX warning quando utente sceglie manualmente `.direttore` con peer Q-B connesso.
- **⚠️ Superseded dal ridisegno 12/06 (§1.4):** il default `.collaborativa` è superseded (default → Standalone) e la scelta ruolo diventa opt-in esplicito → il deliverable warning è assorbito dal disegno CD-7 (libro mastro Sez. 3).
- **Dominio:** CD per design warning.

### Step 3 lock cross-device automatico (post fail-safe LinkMode)
- **Contesto:** prevenire scenario 2-Q-B Director automaticamente (lock cross-device che impedisce a 2 device QB di essere entrambi Director simultaneamente).
- **3 strade tecniche identificate:** non esplorate, backlog.
- **Nota 12/06:** premessa fail-safe `cb92faa` superseded dal ridisegno (§1.4: default Standalone). Lo scenario 2-Direttori non è più il default accidentale ma torna possibile come errore utente coi ruoli manuali → la voce resta valida, da riformulare al disegno CD-7.
- **Dominio:** decisione architetturale + CD per UX.

### Dual entitlements warning Node.js 20 + commento dead `currentBeat`
- Vedi TD #30/31/32/37 sopra (raggruppabili in singolo commit "CI cleanup" a release).

## 1.4 — Backlog UX puro (📦, dominio CD)

Riferimento `LIBRO_MASTRO_QBEATS.md` Sezione 3 deliverable per il dettaglio:
- **CD-1 esteso** (zona swipe orizzontale + indicatore `<< X / Y >>`) — proposto, in attesa di implementazione
- **CD-2** (perimetro rosso sfumato pulsante overlay standby) — proposto
- **CD-3** (bottone "Restart Setlist" a fine setlist) — proposto
- **Issue A — Titolo header troncato su iPhone** — il titolo canzone si tronca su iPhone. Proposta Mauro: spostare BPM + time signature sulla riga del bar counter per liberare spazio al titolo. Emersa 29/05.

- **END SHOW prematuro allo stop manuale del Direttore (→ CD-Q5 libro mastro)** — se il Direttore stoppa vicino a fine canzone, il Follower fa 1 beat extra (latenza Link) e, se quel beat chiude l'ultima sezione, scatta su END SHOW (`SetlistRunner.swift:354-361`); provato WAV TEST7 RUN3/4 (RUN6 = nessun extra). **NON è un guasto** (fisica della rete). Domanda design CD: allo stop manuale nell'ultima battuta, END SHOW o stop semplice? Emersa 11/06.

- **Modalità collaborativa — ridisegno avvio (DIREZIONE RATIFICATA Mauro 12/06 → libro mastro Sez. 1/2/3/4)** — assorbe il sintomo segnalato da Mauro 12/06 (iPhone Follower con iPad spento / zero peer → tap Play entra sempre in WAITING FOR DIRECTOR, `TransportView.swift:38-58` — comportamento voluto CD-Q2=B che non copriva il caso zero-peer, aggravato dal default `.collaborativa` `cb92faa`; via d'uscita START LOCAL già esistente → percorso di default sbagliato, non blocco). Direzione: l'app parte **sempre Standalone**; il collaborativo è **opt-in**, con ruoli **Standalone / Direttore / Follower** assegnati a mano dalla band per device. Cambiano il **default di avvio** (`.collaborativa` → Standalone) e il flusso di opt-in. **CD-Q2=B: regola invariata («il Follower aspetta il Direttore»), ambito ristretto dall'opt-in (vale solo col ruolo Follower assegnato a mano, non più di default) — non riaperta.** Scenari senza Direttore (tutto solo con Link attivo; senza peer → standalone): **(i) senza scaletta** = metronomo libero stile Ableton (Link nativo, ruoli opzionali, parte il primo e gli altri seguono); **(ii) con scaletta** = Direttore obbligatorio → popup "nessun Direttore assegnato". **Verifiche di fattibilità (CC — da investigare in codice, NON ancora fatte):** (a) scenario 1: verificare se oggi l'app obbliga la scelta Direttore/Follower anche senza scaletta; se sì, sganciare l'obbligo nel caso puro-Link; (b) scenario 2: Link trasporta solo tempo/avvio, NON i ruoli → nel breve il rilevamento "nessun Direttore" richiede un **timeout** (rischio "Direttore lento a premere Play", da tarare); il rilevamento immediato dei ruoli aspetta il canale proprietario QB↔QB (= **Soluzione C**, backlog Fase 6-7; NB: il TD#44 — entitlement multicast — era un prerequisito di rete già CHIUSO 23/05 `be2f035`, cosa distinta dal protocollo). Via da scegliere; (c) modello modalità: l'enum `LinkMode` oggi è a 2 valori (`.direttore`/`.collaborativa`, `AppSettings.swift`) → tre scelte flat implicano un refactor (definire "Standalone": Link off vs Link on senza ruolo). **Domande di disegno residue → CD-Q6** (libro mastro Sez. 4); deliverable disegno = **CD-7** (Sez. 3). Emersa 12/06. Dominio: CD (disegno) + CC (fattibilità). Nessun fix finché CD-7 non è ratificato — verde solo dopo device.

Questi NON sono bug ma deliverable UX. Listati qui per completezza visiva del backlog ma il primario è `LIBRO_MASTRO_QBEATS.md` Sezione 3.

---

# Sezione 2 — Bug CHIUSI (storico, non si cancellano)

Per data di chiusura, decrescente.

## 🟢 Giugno 2026

### Bug 2.b — Ferita A + Ferita B (sync runtime cross-device / accento ai cambi sezione)
- **🟢 CHIUSO 11/06/2026 — entrambe le ferite (perimetro = AUDIO + ingresso), device-validate + mergiato su master `ee0cbc0` (squash).**
- **⚠️ Carve-out perimetro (12/06):** la chiusura copre l'**audio** (accento ai cambi sezione) e l'**ingresso** (aggancio Follower). Le facce **VISIVE/counter** dello stesso desync sezione/time-sig cross-device (striscia segmenti 3-vs-4, counter "bar 2 di N") **RESTANO OPEN** in **§1.2 — "Bug 2.b (faccia visiva/counter)"**; il fix audio non le tocca.
- **Ferita A** (ingresso SHARED finalizzato al fire, L3): device-validata TEST6 (`7904ca8`, `armSharedJoin`). Storico: memoria CC + BOX3 V71.
- **Ferita B** (click mangiati/ri-sparati a runtime, L1): **FIX-B `508ac52`** — mark-preserving in `setBeatPositionTimeOnly` + ri-scala del mark in `setBPM`. Device-validata **TEST7**: Follower mid-brano **12/12**, caso 121 (spb frazionario) = 5 scavalchi benigni + backward-no-refire ×3, **hunk① 9 cambi di tempo puliti** (giro debug-metronomo), **audit RT §4 pulito**.
- **Chiude anche TD-beat-drop** (click iPad Collaborativo non emesso, osservato maggio) — unificato in Ferita B (vedi §1 riga "TD-beat-drop UNIFICATO qui"): stesso meccanismo (same-thread, eat/dup a runtime), stessa validazione TEST7 (Follower 12/12, zero click mangiati). **⚠️ Caveat:** l'osservazione originale era con l'**iPad nel ruolo Collaborative/Follower**; TEST7 ha validato il ruolo Follower sull'**iPhone** (iPad = Direttore). Il fix è **per-ruolo** (correzione `sync_phase` del Follower), non device-specifico → copre l'iPad-Follower per costruzione, ma quel device specifico **non è stato ri-esercitato** in TEST7.
- **Merge:** squash dell'intera catena Bug 2.b → master `ee0cbc0`, albero byte-identico a `508ac52`, autore Mauro, no Co-Authored-By, CI run `27375013377` verde, *Verify entitlements* ✓.
- **3 residui isolati col dato = NON Bug 2.b → ticket separati:** doppi-click Direttore (§1.3, pre-esistente), END SHOW (§1.4, CD), TD #17/RUN9 (§1.1, bloccante).
- **Memoria correlata:** `project_qbeats_bugs_tracker.md` (addendum 11/06).

## 🟢 Maggio 2026

### Bug cambio-canzone cross-device — Follower riparte da Song A allo standby
- **Sintomo:** in setup cross-device (Director + Follower Collaborativo), allo standby tra una canzone e la successiva (es. fine Song A → standby "next: Song B"), premendo Play su Director il Follower ripartiva da Song A / Intro 100 invece di proseguire con Song B / Slow 90 (tempo corretto da Link, ma contenuto di sezione della canzone sbagliata).
- **Causa root:** gestore `.onReceive(audioEngine.linkStartedSubject)` (`LiveView.swift:400-403`) con guard solo su `.playing` → chiamava `runner.startSetlist(...)` incondizionato anche in `.standby`; `startSetlist` azzera `currentSongIdx = 0` → reset a Song A. Buco nella copertura multi-canzone di **Problema B / Opzione C / CD-6** (l'Opzione C copriva solo il primo start della setlist; il cambio-canzone allo standby no). NON è "Bug 4 — Link sleep/wake".
- **Fix:** branch `fix/bug-2b-visual-section-sync`, commit `2475487` — `if case .standby = session.playbackState → runner.startCurrentSong(...)` (preserva `currentSongIdx`), `else → runner.startSetlist(...)`, guard `!= .playing` invariato. Commento gestore aggiornato (`dbd76a2`); harness test "3/4 Long" rientrato (`7e61958`).
- **Validato device:** 31/05/2026 — orchestrazione validata (Follower entra su Slow 90, bar multi-canzone sincronizzati). **NB:** il conteggio segmenti del metronomo stantio all'ingresso di Slow 90 (mostra 3 invece di 4 per un attimo) è la **faccia visiva di Bug 2.b** (desync sezione/time-sig cross-device — vedi **§1.2 "Bug 2.b (faccia visiva/counter)"**, 🟠 OPEN; l'audio di Bug 2.b è chiuso, voce sopra), **non** questo bug.
- **Merge:** contenuto del fix **arrivato su master via squash `ee0cbc0` (11/06)** — verificato su master (`LiveView.swift:407-408`, ramo `.standby → startCurrentSong` presente). Il ramo `fix/bug-2b-visual-section-sync` resta non mergiato come branch (archeologia; trascinava il seme `0693e39`).

### Problema B — Orchestrazione start cross-device del Follower (alias storico "Bug 4/Problema B" — NON confondere con "Bug 4 — Link sleep/wake")
- **Sintomo:** iPhone Collaborativo + iPad Director in play → iPhone non mostrava il nome canzone e il counter macrobar avanzava all'infinito (oltre `macroBarTotal`).
- **Causa root:** callback Link `set_start_stop_callback` chiamava solo `engine.start()` NON `runner.startSetlist(...)` → su Follower `_sectionTotalBeats=0` → check salta → counter mai incrementato → closure `_onSectionEnd` mai dispatchata → `currentSectionIdx` resta 0.
- **Fix:** Fase D (Opzione C: LiveView observer su `linkStartedSubject` + TransportView check pre-Play). Squash merge `007de87` (ex `8016c97` + rename `b64cf67`).
- **Validato device:** 28/05/2026 (nome canzone presente, counter macrobar avanza fino a `macroBarTotal`).
- **Memoria correlata:** `project_qbeats_problema_b_causa_root.md`.
- **Rimandato a Fase 6-7-bis:** sync sezione runtime cross-device (audio: CHIUSO 11/06 con Bug 2.b, voce sopra) + counter offset (vedi **§1.2 "Bug 2.b (faccia visiva/counter)"**).

### Bug 5 — Direttore fermo parte allo START LOCAL di un peer
- **Sintomo:** iPad Direttore fermo partiva involontariamente quando un peer Collaborativo faceva START LOCAL (CD-6).
- **Causa root:** callback Link start/stop con guard `isRunning && _linkMode == .direttore` → da fermo (`isRunning` falso) non ignorava lo start del peer.
- **Fix:** `007de87` (ex `611d4ee`). Guard → `if engine._linkMode == .direttore { return }` (ignora SEMPRE start/stop da peer, in play e in stop).
- **Validato device:** 29/05/2026 (START LOCAL su iPhone → iPad resta fermo).

### Bug 5-BPM — Direttore fermo adotta il BPM di un peer
- **Sintomo:** iPad Direttore fermo adottava il BPM di un peer Collaborativo (peer a 120 → iPad saltava a 120).
- **Causa root:** callback Link tempo con guard `isRunning && _linkMode == .direttore` → da fermo cadeva nel ramo collaborativo che adotta il BPM del peer.
- **Fix-storia:** `611d4ee` rimuoveva `isRunning` ma era troppo aggressivo (Direttore fermo *dominava* il BPM → inchiodava il Follower in START LOCAL, scoperto al test R2 29/05) → **affinato in `46ba0f3`**: `if engine._linkMode == .direttore { if engine.isRunning { ri-trasmette } return }`. Da fermo non adotta e non domina; in play ri-trasmette il proprio.
- **Validato device:** 29/05/2026 (R2: iPhone in START LOCAL sale a 120 seguendo la setlist; R6: iPad fermo resta a 100 mentre iPhone va a 120, anche in standby).

### 1.j — Latenza Direttore con peer connessi
- **Sintomo:** iPad Direttore con peer connessi → fino a ~1s di latenza all'avvio + partenza a metà battuta.
- **Causa root:** con peer presenti il Direttore prendeva il ramo SHARED (`join_running_session`) invece di forzare la propria timeline.
- **Fix:** `007de87` (ex `611d4ee`). `start()` branching: `if (peersCount == 0 && !probe.isPlaying) || self._linkMode == .direttore` → il Direttore forza sempre `start_at_beat_zero`.
- **Validato device:** 29/05/2026 (R7: iPad in Play, audio parte subito, battono all'unisono col Follower).

### Bug 4 — Link sleep/wake socket refresh
- **Sintomo:** Link perdeva peer dopo lock schermo + sblocco.
- **Causa root:** lifecycle `ABLLinkSetActive(false/true)` non gestito su ScenePhase background/active → socket multicast non rinegoziato dopo lock.
- **Fix:** commit `6d1dbbf` (squash merge branch `fix/bug-4-link-socket-refresh`) 26/05/2026 mattina. Pattern bidirezionale ScenePhase + flag `linkSuspendedByBackground` per preservare preferenza utente.
- **Validato device:** 26/05 mattino test PID 7496 (lock 7s + sblocco → peer ritrovato istantaneo, `isConn:true` a 2s post-enable).
- **Memoria correlata:** `feedback_qbeats_lifecycle_scenephase_only.md` (UIApplicationDelegate non scatta in Q-BEATS SwiftUI, ScenePhase unica fonte).
- **Branch archeologia:** `fix/bug-4-link-socket-refresh` preservato su origin (4 commit storici).
- **Copertura collaterale:** TD #17 caso background/foreground cycle. TD #17 resta aperto per "sessioni lunghe foreground attivo".

### TD linkPeers — Display Settings "Peers" da contatore numerico a stato binario
- **Sintomo:** display "Peers: N" mostrava sempre 0 o 1 anche con N peer connessi → fuorviante per l'utente.
- **Causa root:** LinkKit 4.0 non espone API pubblica peer count. `peers_changed_callback` Swift alimentato da callback C++ `ABLLinkSetIsConnectedCallback` con `peers = isConnected ? 1 : 0`.
- **Tentativo precedente null-op:** commit `72001a5` su branch orfano `fix/td-link-peer-count` chiamava `link_engine_num_peers` — semanticamente equivalente al pattern hardcoded perché `numPeers_` interno C++ è popolato solo dal callback booleano. Branch preservato come archeologia per evitare ri-tentativi.
- **Fix vero:** PR #1 squash merge in commit `0de5aa0` master 26/05/2026 sera. Display cambiato a stato binario "Connected/Standalone" basato su `linkIsConnected` (verde/grigio).
- **Validato device:** 26/05 sera (iPad QB + iPhone QB connessi → "Connected" verde / disconnesso → "Standalone" grigio, transizione OK).
- **Memoria correlata:** `feedback_qbeats_linkkit_peer_count_no_api.md` (lezione doppia: vincolo tecnico permanente + verifica C++ alla sorgente prima di accettare premesse).
- **Ratifica cross-team:** `LIBRO_MASTRO_QBEATS.md` v9 (commit `863bc99`) + v10 (commit `c20f9d9`).

### TD #44 — Bug Link discovery QB↔QB
- **Sintomo:** due istanze Q-BEATS su device diversi non si scoprivano via Ableton Link. Discovery QB↔SB funzionava, solo QB↔QB rotta.
- **Causa root:** `xcodegen generate` su CI sovrascriveva `QBeats.entitlements` con `<dict/>` vuoto perché `project.yml.entitlements` aveva solo `path:` senza `properties:` → binary firmato senza `com.apple.developer.networking.multicast` → kernel iOS scartava annunci Link via `necp_check_restricted_multicast_drop`.
- **Fix:** commit `be2f035` (project.yml properties esplicite) + `4e9d12f` (rimossa iCloud per sbloccare exportArchive) + cleanup `8560443` (rimosso iCloud da QBeats.entitlements checked-in). 23/05/2026.
- **Validato device:** 23/05/2026 sera (peer QB↔QB visibile iPhone+iPad). Falso drop intermedio = WiFi iPhone caduto, non bug Q-B.
- **Diagnosi precedenti smentite:** filtro libLinkKit per bundle ID (Christian/Ableton ha confermato che NON esiste); ABLLinkSetPeerName (E1 cleanup commit `373f0d1`); SetActive sequence (B1'' restano come allineamento canonico ma non causa).
- **Memoria correlata:** `project_qbeats_td44.md` (storia completa).
- **Documento:** `ARCHIVIO.MD/20_05_2026/TD44_REPORT_20_05_2026.md` + `ARCHIVIO.MD/23_05_2026/BOX3_V65_23_05_2026.md`.

### TD-E1 — Cleanup `ABLLinkSetPeerName` codice morto
- **Causa:** symbol undocumented `ABLLinkSetPeerName` rimosso da LinkEngine.mm + MIDIEngineBridge.h + AudioEngine.swift (41 righe rimosse).
- **Fix:** commit `373f0d1` 23/05/2026 sera.
- **CI:** run [`26342746970`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/26342746970) ✅ verde 1m33s. Multicast preservato nel binary IPA (anti-regressione TD #44).
- **Decisione UX:** peer-name Q-BEATS configurabile via campo "Peer Name" editabile del pannello Ableton (`LinkSettingsPresenter`), persistito da LinkKit in NSUserDefaults. Niente runtime override automatico.

### Bug Link sync L1.b — Accumulo offset ai cambi sezione
- **Sintomo:** offset SB→Q-B (SB in anticipo sul master): Sez 1 baseline ~15ms, Sez 2 ~50ms (+35), Sez 3 ~100ms (+50), Sez 4 ~150ms (+50). Accumulo costante ai cambi, dentro sezione offset stabile.
- **Causa root:** `ABLLinkForceBeatAtTime` usato per cambi tempo (`link_engine_set_bpm_and_beat_at_time`). Force per cambi tempo è errore semantico — Force è per reset espliciti beat (es. utente riparte da beat zero), non per cambi BPM. Ogni Force con beat anche minimamente impreciso sovrascrive consensus Link e l'errore resta permanente.
- **Fix:** **Strada C** commit `6c4a9cc` 16/05/2026 notte. Solo `ABLLinkSetTempo`, niente `ForceBeatAtTime`. Pattern canonico LinkHut.
- **Validato:** ground truth Audacity 16/05 (offset costante tra Sez 130/110/140 senza somma).
- **Strade scartate:** Strada A (proiezione OLD BPM, parzialmente efficace), Strada B (Force a NOW, bug semantico), Step 5 (skip 3→30, irrilevante).

### TD #43 — FineSetlistView sfondo opaco
- **Fix:** commit `7e1e4de` 18/05/2026 (rimosso `.opacity(0.95)` da `FineSetlistView.swift:11`, sfondo `#0e0e10` ora copre 100% Vista LIVE sottostante).

### TD #23 — Font responsive iPad (Strada A scaling)
- **Sintomo:** font/spacing non si adattavano a iPad portrait.
- **Fix:** commit `adfcc39` (Fase 1 log baseline 390pt) + `8a5432b` (Fase 2 refactor 11 file, 24 callsite) 18/05/2026.
- **Pattern ratificato:** `pt_originale * scaleFactor` con `scaleFactor: CGFloat = geo.size.width / 390` calcolato in LiveView e propagato come parametro esplicito.
- **Validato:** iPhone 13 + iPad portrait pre-2018.
- **Memoria correlata:** `feedback_qbeats_scaling_responsive.md` (vietati `@ScaledMetric`, `UIFont.preferredFont`, `sizeCategory`).

### TD #28 — Default `.stopped` LiveSession
- **Fix:** commit `224fd78` 17/05/2026 (em-dash all'avvio Vista LIVE rimosso; overlay standby resta dinamico tra canzoni con `nextSongName` reale).

### TD #40 + TD #41 — Cambio sezione SEAMLESS
- **Fix:** commit `d4c9e1f` (v1) + `dc1da0b` (v2, ratificata dopo v1 ROSSO) 17/05/2026.
- **Pattern:** mirror @State `displayBpb`/`displayAccentPattern` letti dal body in LiveView, buffer `pendingBpb`/`pendingAccentPattern`/`pendingReps` applicati al primo beat tick post-arrivo. TD #41 v2: subscribe a `session.$beatActive` filter `==1` invece di `audioEngine.beatTickSubject` con `.receive(on:)` (race FIFO non-deterministica).

### TD #38(a) — Mirror @State pending cambio sezione
- **Fix:** chiuso 17/05/2026 commit `d4c9e1f` (insieme a TD #40 + #41).

### Tap tempo algorithm
- **Refactored:** commit `259a09f` 17/05/2026 (mediana invece di media, finestra 6 era 8, min 4 tap era 2 — allineato Pro Metronome/SB).

### TD #36 — Quantum al cambio sezione
- **Stato:** chiuso de facto da Strada A 16/05 pomeriggio. `link_engine_set_quantum(lh, Double(pendingBPB))` viene chiamato al cambio sezione nel ramo SEAMLESS. Validato in T-BPB.
- **Da verificare:** se restano scenari aperti in modalità Studio.

### TD #25 / TD #26 / TD #27 / TD #29
- **TD #25:** chiuso 14/05/2026 sera commit `3ef30d8` (TeleprompterCapsuleView guard standby).
- **TD #26:** chiuso 14/05/2026 sera commit `a5dea34` (MetSlotStripView accent verde `#28cd41` + token BOX5 conformi).
- **TD #27:** chiuso 14/05/2026 sera commit `81635d0` (get-task-allow entitlements, log iMazing ripristinati).
- **TD #29:** chiuso 14/05/2026 sera commit `06838d5` (MicroSegBarView + MacroBarView guard standby).

### TD #15 / TD #16
- **TD #15:** chiuso 14/05/2026 mattina commit `4ed7171`.
- **TD #16:** chiuso 14/05/2026 mattina commit `3d2dd4c` (sectionEndedSubject spostato al callsite Layer 3).

### TD #18 — Task D refactor audio-thread Link mutations
- **Fix:** chiuso V53. Catena commit: `29afd2a` (base) → `3c8091a` (sample rate) → `bdc01fc` (OpaquePointer) → `1d57216` (diag TEMP) → `9f5e06d` (installTap) → `db07efe` (pulizia DIAG).

### TD #14 — Mirror `_beatsPerBarQ` audioQueue-private
- **Fix:** chiuso V54 commit `13d3c83` (base, build rossa per collisione synthesized backing storage @Published) + `fca5707` (rename `_beatsPerBar`→`_beatsPerBarQ`, build verde).
- **Validato:** test A.2 audio (4 cambi time signature, metronomo fermo: 3/4 → 5/4 → 7/8 → 6/8).

### TD-1 — Rename Section → SongSection
- **Fix:** commit `ef03006`. Riferimento residuo nel commento BOX5 V22 modello dati obsoleto, da pulire alla prossima revisione BOX5.

---

# Sezione 3 — Bug SCARTATI / SMENTITI (per evitare ri-aperture)

### TD #35 — Drift sistemico Q-B↔Link clock
- **Diagnosi originale:** drift sistematico Q-B vs Link consensus.
- **Smentita 16/05/2026:** log post-Strada C mostrano `bpm == lTempo` sempre, delta interno costante. Non c'è divergenza Q-B↔Link in regime.
- **Strade α/β/γ non applicate**, non più rilevanti.

### Drift Q-B↔Link in regime stabile (AI esterna 16/05)
- **Diagnosi originale:** "DIRECTOR-ASSERT continuo causa drift intra-sezione".
- **Smentita 16/05:** log mostrano un solo Force all'avvio, zero in regime. Drift intra-sezione 110 NON è causato da Force.

### Linkkit filtro per bundle ID (diagnosi pre-TD #44 fix vero)
- **Diagnosi originale:** LinkKit filtrava annunci per bundle ID → discovery QB↔QB rotta.
- **Smentita:** risposta Ableton Support 21/05 (Christian, `link-devs@ableton.com`) ha confermato che LinkKit NON filtra per bundle ID.
- **Risolta:** causa vera era multicast entitlement mancante (TD #44 chiuso 23/05).

### `ABLLinkSetPeerName` come causa TD #44
- **Diagnosi originale:** symbol undocumented forzato come fix.
- **Smentita:** Test A (disabilitazione runtime call) ha mostrato che NON era la causa. E1 ha rimosso il codice come cleanup separato (commit `373f0d1`).

### LinkKit `SetActive` sequence come causa TD #44
- **Diagnosi originale:** sequenza `Create→SetActive(false)→callbacks→SetActive(true)` produceva discovery rotta.
- **Smentita:** B1'' (reorder `SetActive` in `link_engine_create`/`link_engine_activate`) restano in vigore come allineamento canonico a `ABLLink.h:57-62` ma NON erano la causa root. Causa vera era entitlement.

### Quantum 3/4 come causa drift Sez 110 (16/05)
- **Diagnosi originale:** quantum 3/4 mismatch causava drift Sez 110 L2.b.
- **Smentita 16/05:** test L2.b è tutto 4/4 (verifica DebugView.swift:386-397).

### `linkSyncSkipBuffers` come fix drift (15/05 sera)
- **Diagnosi originale:** estendere skip-buffers risolve drift.
- **Smentita 15/05 stesso.** Step 5 cassato.

### Strada A (proiezione OLD BPM in `set_bpm_and_beat_at_time`)
- **Stato:** parzialmente efficace ma NON risolutiva. Superata da Strada C 16/05 notte.
- **Branch:** commit `1acdf40` archeologia.

### Strada B (Force a NOW)
- **Diagnosi:** `ABLLinkForceBeatAtTime(state, currentBeat, mach_absolute_time(), quantum)`.
- **Scartata pre-Edit:** bug semantico (`currentBeat` è beat di hostTime futuro, non di NOW). SB avrebbe saltato avanti di ~150ms.

### Step 5 — Skip 3 → 30 buffer post-cambio
- **Cassato:** non c'entra col bug di Force.

### Disable DIRECTOR-ASSERT
- **Rifiutato da Mauro:** 15/05.

### Strade D (re-broadcast periodico), E/F speculative
- **Bloccate:** vincolo "no fix speculativi in fase diagnostica" durante bug Link sync.

### Three-band v1 (`feat/collab-sync-three-band` `c766fd5`)
- **Stato:** scartato. Branch open su origin come riferimento storico — NON merged.
- **Verdetto Opzione α 25/05 sera:** peggiora Slow 90 di +14ms vs baseline `cb92faa` (16ms → 30ms).
- **Causa root regressione "catastrofica" del 24/05 sera:** **riformulata 25/05** — era setup 2-Director tug-of-war (entrambi i device sul vecchio default `.direttore` post-TD #44), NON il design three-band.
- **Memoria correlata:** `feedback_qbeats_sync_phase_smoothing_strutturale.md` (audit trail).
- **Eredità:** design alternativo (smoothing a valle DSP) resta linea guida per three-band v2.

### Android peer Link drift (osservato 26/05 sera test extended)
- **Sintomo:** iPad QB + iPhone QB + Android Soundbrenner → Android fuori-fase ~10-50ms drift.
- **Diagnosi:** NON bug Q-BEATS. Causa fuori dal controllo Q-B (territorio Ableton + Soundbrenner Android: implementazione LinkKit Android, audio stack Android latenza > Core Audio, multicast WiFi Android variabile, power management Android).
- **Verifica controllo:** iPad SB + iPhone QB → in fase ✓ (iOS-only OK).
- **Ratifica cross-team:** `LIBRO_MASTRO_QBEATS.md` v10 — scope Q-BEATS = iOS-only per v1.
- **Implicazione CD:** dichiarare iOS-only in materiale commerciale, FAQ, copy app store.

### Sync Start/Stop Soundbrenner OFF default
- **Diagnosi originale:** regressione start/stop SB durante test Opzione A → codice rotto.
- **Smentita:** era impostazione device Soundbrenner "Sync Start/Stop" OFF di default. Config utente, NON bug Q-B.
- **Memoria correlata:** `project_qbeats_sb_link_sync_config.md`. Vale solo per transport, NON per tempo/fase.

---

# Sezione 4 — Diagnostiche aperte / in attesa di dati

## Sessione 1 (branch `feat/diag-first-beat-and-beat-drop-and-3-4-long`, in attesa test device Mauro)

- **Commit `70bb86a`** (Round 1, Item 5b): setlist 3/4 Long DebugView. Bottone `.brown` "3/4 Long" + factory `loadTestData34Long()`. Setlist 4/4 100 BPM 8 batt → 3/4 100 BPM 16 batt → 4/4 100 BPM 8 batt. BPM costante 100 → isola effetto cambio TS dal cambio BPM.
- **Commit `31dddbb`** (Round 2, Item 1 PARTE A): 10 log `[Q-BEATS][DIAG-A][T0]` → `[T9]` in `AudioEngine.swift`. Misurano timing dispatch chain iPad-side dal callback Link `isPlaying=true` (T0) fino all'entry primo buffer pre-roll (T9).
- **CI:** run [`26361824809`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/26361824809) ✅ verde 50s. IPA pronto.
- **Bloccante:** Mauro raccoglie dati su device. Senza dati nuovi non si può progettare fix TD #A né dare verdetto su TD #39.

## Lezioni metodologiche attive (no fix prima della diagnosi)

- `feedback_log_vs_ground_truth.md` v2: nessun fix Layer 2 motivato da soli log Q-B-side, neanche se inferenza architetturale impeccabile.
- `feedback_qbeats_chiuso_solo_dopo_device.md`: "chiuso" solo dopo validazione device, non al commit/push.
- `feedback_qbeats_linkkit_peer_count_no_api.md`: verificare implementazione C++ alla sorgente PRIMA di accettare premesse fix.
- Setup 1D+1C esplicito in tutti i test cross-device (lezione 25/05: setup 2-Director era causa fantasma).
- Smoke test cross-device PRIMA dei test di precisione su ogni fix Layer 2.

---

# Sezione 5 — Storico versioni file

| Versione | Data | Autore | Modifiche principali |
|---|---|---|---|
| 1 | 2026-05-26 sera | CC chat principale 26/05 sera | Creazione iniziale del file. Aggregazione esaustiva da `project_qbeats.md` (memoria CC), `LIBRO_MASTRO_QBEATS.md` v10 (libro mastro), `BOX3 V67`, memorie `feedback_qbeats_*.md`. Sezione 1 bug aperti (3 categorie: bloccanti palco, non bloccanti pre-v1, backlog). Sezione 2 bug chiusi storici. Sezione 3 bug scartati/smentiti. Sezione 4 diagnostiche aperte (Sessione 1 in attesa test device). Sezione 5 storico. Bug aggregati: 3 bloccanti palco (TD #A, TD beat drop, TD #17), 3 non bloccanti pre-v1 (TD #34, TD #39 sospeso, three-band v2), 14 backlog, ~20 chiusi, ~13 scartati. |
| 2 | 2026-05-29 | CC chat principale 29/05 | Chiusure Fase 6-7 (squash merge `007de87` su master, validato device 28-29/05): Problema B (orchestrazione start cross-device Follower), Bug 5 (START LOCAL non avvia il Direttore), Bug 5-BPM (Direttore conserva il proprio BPM, affinato `46ba0f3`), 1.j (latenza Direttore con peer). Nuove voci APERTE: Bug 2.b (counter offset "bar 2 di N" + desync visivo sezione/time-sig cross-device → Fase 6-7-bis, OPEN MEDIA), header BPM pre-Play primo caricamento (display, backlog), Issue B microbar fantasma (backlog), Issue A titolo header troncato (CD). |
| 3 | 2026-05-30 | CC chat principale 30/05 | Registrazione nuova voce APERTA in Sez. 1.1: "Bug cambio-canzone cross-device — Follower riparte da Song A allo standby" — buco nella copertura multi-canzone di Problema B / Opzione C / CD-6 (l'Opzione C `007de87` copriva solo il primo start della setlist; al cambio-canzone allo standby il Follower veniva resettato a songIdx 0 e ripartiva da Song A invece di proseguire). 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO per il set multi-canzone cross-device (single-device e singola-canzone non affetti). Root: `LiveView.swift:400-403`, gestore `linkStartedSubject` chiama `startSetlist` con guard solo su `.playing`, nessun ramo `.standby`. Registrazione prima del fix (branch `fix/bug-2b-visual-section-sync`). |
| 4 | 2026-05-31 | CC chat principale 31/05 | Esiti validazione device 31/05. **Bug cambio-canzone cross-device → 🟢 CHIUSO** (spostato in Sez. 2): orchestrazione validata (Follower su Slow 90, bar multi-canzone sincronizzati); fix `2475487` (`if case .standby → startCurrentSong`) + `dbd76a2` (commento) + `7e61958` (harness 3/4 Long); branch `fix/bug-2b-visual-section-sync` NON mergiato (HOLD merge fino a chiusura Bug 2.b — trascina il seme `0693e39`). **Bug 2.b → elevato 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO e ricollocato da Sez. 1.2 a Sez. 1.1.** Motivo: accento audio errato (non solo visivo) in Collaborative ai cambi di TS puri (BPM costante) = errore musicale; costrutto comune, soglia di prodotto. Aggiornati: legato al ruolo Collaborative (non al device); radice "confine Follower sfasato / 9-di-8"; discriminante Link-attivo (non `_linkMode`); modello due facce; **asse BPM-vs-BPB corretto** (Verse→Bridge NON "pulito" — trambusto visivo in R7 per BOX3 V69, audio da verificare; R2 pulito su tutti gli assi in standalone Link OFF, ri-test 31/05 4 prove — il desync visivo BOX3 V69 R2 era con Link attivo; 3/4 Long rotto su entrambi); causale in diagnosi (sospetti seme `_sectionBeatCounter` + `sync_phase`). **Nuova voce candidato (Sez. 1.3):** WAITING FOR DIRECTOR persiste con Link OFF (🟡, separato). |
| 5 | 2026-05-31 | CC chat principale 31/05 | **Bug 2.b — causale IDENTIFICATA + fix Parte 1 committato.** Causale: `MetronomeDSP::setBeatPosition` (`cpp:166-180`) ri-derivava `_currentBeatInBar` dal **beat assoluto** di `sync_phase` modulo BPB, con `_startAbsoluteBeat` (origine Play) non ri-ancorata al confine → sfasamento al cambio BPB (`32 % 3 = 2`); seme `_sectionBeatCounter` scagionato dal dato device, Director immune (`assert_session_state`), standalone pulito (no `setBeatPosition`). **Direzione 2** scelta (separare tempo/fase); **Direzione 1** scartata (insegue il sintomo, riapre rischio Resume, accumula su più sezioni). **Forma Parte 1** (commit `45faa90` sul branch): primitiva DSP solo-temporale `setBeatPositionTimeOnly` + bridge, ramo `sync_phase` instradato sulla variante (`AudioEngine.swift:2117`), `setBeatPosition` intatta per il solo Resume, MIDI e Director invariati. Stato Bug 2.b: 🔴 OPEN — fix committato, **in attesa test device (NON chiuso)**. **Follow-up Parte 2** registrata: esposizione latente Resume-in-peer via recovery non gated-Link → hardening "nil sotto Link", subordinato a conferma device. |
| 6 | 2026-06-11 | CC chat principale 11/06 | **Bug 2.b (Ferita A + Ferita B) CHIUSO e mergiato su master `ee0cbc0` (squash, CI `27375013377` verde).** Consolida anche le modifiche di contenuto del branch mai entrate in tabella (TD-follower-rejoin 3 facce `b128536`; Ferita A chiusa `b23b40e`). FIX-B `508ac52` device-validato TEST7 (Follower 12/12, caso 121, hunk① 9 cambi, audit RT §4). Bug 2.b spostato in Sez. 2; **chiude anche TD-beat-drop** (unificato in Ferita B, con caveat iPad-Follower non ri-esercitato). **3 ticket nuovi:** doppi-click Direttore §1.3 (pre-esistente), END SHOW §1.4 (CD), TD #17 §1.1 confermato BLOCCANTE (RUN9). |
| 7 | 2026-06-12 | CC chat principale 12/06 | Carve-out chiusura Bug 2.b reso onesto (perimetro = audio+ingresso; facce visive/counter RESTANO OPEN). Nuova voce §1.2 "Bug 2.b (faccia visiva/counter)": faccia (i) striscia segmenti 3-vs-4 a Slow 90 con peer (oss. build 474 `add556f` = master + sola fixture debug; sparisce senza peer = cross-device; audio corretto; repro device: BRIDGE 3/4 → SLOW 90 4/4 con peer = 3 fissi tutta la sezione fino al cambio 110 → sorgente del 3 = BPB della 3/4, inferenza forte; momentaneo-vs-persistente RISOLTA → PERSISTENTE; controllo 4° beat ESEGUITO su video = firma CONFERMATA, al 4° beat nessun segmento si accende; flip 4→3 ESATTAMENTE al join, display corretto durante la battuta solo-Direttore → ipotesi start-order RAFFINATA: default stantio sovrascrive al join, riga da inchiodare col log) + faccia (ii) counter "bar 2 di N" (ex faccia D). Raddrizzati i puntatori stantii (76, 79, 82-83, 102, 260, 261, 269) + ri-taglio §1.3 WAITING-Link-OFF (domanda UX risolta 12/06; CD-Q2=B regola invariata, ambito ristretto dall'opt-in) + note superseded §1.3 Step 2/3. Nuova voce §1.4 "Modalità collaborativa — ridisegno avvio" (DIREZIONE RATIFICATA Mauro 12/06: default Standalone + opt-in ruoli manuali, supersede default `cb92faa`; fattibilità CC; → libro mastro v17 CD-7/CD-Q6). Header versione allineato (era 5 dal commit v6). Nessun fix codice. |

---

**Fine documento.**
