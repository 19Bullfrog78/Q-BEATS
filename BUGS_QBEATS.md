# BUGS_QBEATS — Tracker centralizzato bug e tech debt

**Versione:** 38
**Ultima modifica:** 2026-07-17
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

### TD #17 — Perdita peer cross-banda (🟠 ROOT CAUSE CIRCOSCRITTA 22/06 — H388X-specifico, VR2800 pulito)
- **AGG 22/06/2026 — ROOT CAUSE CIRCOSCRITTA (device + sniffer):** la perdita peer accade con i due device su **bande Wi-Fi diverse**: alcuni router non fanno transitare il multicast di Link (`224.76.78.75:20808`, ALIVE continuo ~250 ms/peer, cattura diretta) tra le due radio. **NON universale: H388X-specifico.** Prova: **H388X** iPad-2.4 + iPhone-5GHz → 0 peer 3-4 min, reversibile su una banda; **VR2800** stessa prova → **peer STABILE 10+ min** (device-confermato Mauro 22/06, bande verificate). Sniffer validato (eth0 cablato + IGMP join socat; monitor mode scartato). **Meccanismo interno H388X = IPOTESI non isolata** (candidato IGMP snooping; "no bridge" declassato a ipotesi) — MOOT perché il VR2800 risolve. Doc finale: `LOG\roam_evidence\TD17_ROOT_CAUSE_FINALE_22_06_2026.md`. **Nota declassata (22/06):** un desync visivo/uditivo durante un roam fu osservato in un **test invalidato** (SSID misto BULLFROG/BULLFROG5 + peer instabile, scoperti dopo) — **NON un fenomeno stabilito**, NON un sotto-ticket; da riconfermare solo se ricompare in un test pulito. *(Voce da ricollocare in §1.2: non più bloccante — lasciata qui per continuità fino al prossimo riordino.)*
- **SCOPING (23/06) — qualifica «pulito»:** «VR2800 pulito» = **cross-banda STATICO** (device fermi, 10+ min). Il comportamento **sotto roam / perdita-banda** è in **indagine separata**: la run 23/06 era confondata da Smart Connect (probabile stessa banda) → il cross-banda **sotto roam NON è ancora ri-testato pulito** e **NON chiude TD#17**; re-test = caratterizzazione in coda (single-band sempre imponibile sul palco di Mauro → blocco palco già sciolto). «Pulito» ≠ «sicuro al 100% sul palco, roam compreso».
- **Sintomo:** dopo sessioni lunghe Link smette di vedere peer. Recovery: toggle Link OFF/ON, oppure uscire/rientrare dalla vista.
- **CONFERMATO 11/06/2026 (TEST7 RUN9, 121 BPM):** peer perso a metà giro dopo ~2h15 in foreground attivo, **WiFi vivo**, zero eventi ScenePhase sul Follower. Il **tempo NON è andato fuori** (free-run −11 ms tenuto 16,6 s senza peer); danno **solo finale** (lo stop del Direttore non si propaga → il Follower finisce la propria setlist da solo ~1,5 s). **Recovery = uscire/rientrare dalla vista Direttore** (ri-init Link) → peer ri-formato all'istante.
- **Caratterizzazione — run overnight dual-capture 15→16/06 (~6h45, iPad Direttore + iPhone Follower):** un solo evento vero = **peer perso MUTUO ~10 min @ ~00:59** (real `00:59:00`→`01:09:11`); entrambi hanno continuato a suonare, **auto-riparato** (≠ pomeriggio 15/06 dove non tornava). **Confondenti esclusi su entrambi i device:** no background (`isAnyAppInFG:no`=0), no chiamata/interruzione audio (=0), Direttore mai fermo (SYNC UDP gapMax 2,2 s). Firma del guasto = **freeze della sola RX** (il Follower smette di RICEVERE dal Direttore, la TX continua).
- **Causa = IPOTESI LEAD (meccanismo plausibile, n=1 sul differenziatore → NON «confermata/inchiodata»):** iPhone Follower con WiFi debole (22,7% campioni RSSI ≤ −82 dBm) → **roam BSSID @ ~`00:58:54`** → si rompe la scoperta-peer multicast di Link → **re-join Link lentissimo ~10 min** (IP/WiFi sani tutto il tempo). ❌ **«Direttore non emette» FALSIFICATA.** **Cambio-sezione = CO-FATTORE possibile** (il roam fatale è ~1 s dopo un cambio sezione, ma il roam-da-solo non basta: 7/8 roam della notte sono innocui), **non causa unica**.
- **Verifica avversariale 16/06 (workflow 6 agenti):** tabella 8 roam confermata da re-scan indipendente; **«buco di rete lungo → peer cade» FALSIFICATO** (roam innocuo #3 = buco 7,9 s e peer su; roam fatale #4 = buco 0,5 s); **escluse 7/7** «re-assoc dura / nuovo PRIVATE MAC» e «cross-banda 2.4↔5 GHz» (le fanno tutti i roam → non separano). **Unico separatore pulito = vicinanza al cambio-sezione** (solo #4 entro ≤2 s) **MA a n=1 è inscindibile dall'RX-freeze e può essere coincidenza** (8 roam vs centinaia di cambi-sezione). Confidenza giudice = **media**.
- **Reperto sorgente (Strategia 1, codice congelato `e608f7d`, sola lettura):** l'app **non ha socket UDP propri** — tutta la sync cross-device è **Ableton Link** (LinkKit, binario chiuso; `LinkEngine.mm`), `numPeers` dal solo booleano `ABLLinkIsConnected`; entitlement multicast presente/necessario alla **discovery**. Il **canale privato dell'app = roadmap futura, non esiste oggi** (conferma Mauro). Quindi «SYNC UDP sopravvissuto» = flussi **unicast** di Link (TX) vivi mentre crolla la **presenza/discovery multicast** (RX-freeze). LinkKit chiuso → l'analisi stringe sul multicast ma non lo chiude.
- **Mitigazione rete (run dedicata 17-18/06 ~9 h, router dedicato banda-singola 2.4 GHz, roam=0) — è una MITIGAZIONE, NON un fix:** con roam=0 il **peer non è MAI stato perso, catastrofe NON riprodotta** in 9 h (Direttore pulito) → per un concerto **2-3 h** il **router dedicato a banda singola = cura di palco sufficiente** (tesi Mauro). Restano micro-dip RX roam-indipendenti (grappoli ~ogni 15 min, ipotesi GTK-rekey/DTIM) che **NON rompono** la sessione. ⚠️ **NON chiude TD#17:** è un palliativo operativo, il difetto di re-join resta.
- **Stato:** 🟠 **OPEN MEDIA — ROOT CAUSE CIRCOSCRITTA + MITIGATO (22/06).** Non più bloccante operativo: causa = router-specifico H388X (multicast non transita cross-banda); il VR2800 (router di palco) è pulito (dual-band cross-band stabile 10+ min, device 22/06) + workaround single-band universale. **NON 🟢 CHIUSO:** restano caso roam reale sul VR2800 + run palco 2-3h; fix strutturale = Soluzione C (Fase 6-7). Storia: confermato 11/06, caratterizzato 16/06, Strategia 1 esaurita 20/06. Copertura background/foreground via Bug 4 (`6d1dbbf`) invariata.
- **[SUPERATO 22/06 — sniffer costruito, root cause circoscritta H388X, VR2800 pulito; vedi AGG sopra.]** NEXT STEP (storico) — Strategia 1 ESAURITA (analisi 20/06, log esistenti, ANALISI-ONLY): verdetto (B) NULL-su-differenziatore.** **n=1 BLINDATO** — unico evento genuino = #4 (`00:59:00`); il secondo `numPeers→0` (#8 @ `05:12:04`) è **stop manuale del test alle 05:12** (Mauro), NON un guasto. **Tutti i separatori falsificati o coincidenza-compatibili:** durata buco RX (#4 ha il PIÙ CORTO, 0,5 s), direzione di banda, RSSI d'atterraggio, atterraggio marginale 5 GHz/«Valid: NO» (lo fa anche il #6 innocuo), settling re-assoc, Data Stall, intervallo inter-roam; l'AUTO-JOIN storm di #4 è **conseguenza** (3/5 trigger DOPO il drop); resta solo la **vicinanza al cambio-sezione (#4 = 1,3 s) ma coincidenza-compatibile** (cambi-sezione ~10% del tempo → ~0,8 roam «vicini» attesi su 8 per caso). **Coppia minima #4 vs #6** (gemelli 2.4→5 marginali, differiscono solo per la vicinanza al cambio-sezione) = esatto A/B da rifare al banco. Cecità dei log DIMOSTRATA: su #4 il drop cade +5,78 s dopo il roam = firma del prune peer a timeout fisso di Link — n=1 sul dato (solo #4), corroborato da sorgente aperta (discovery/PeerGateway.hpp: TTL annunciato 5 s, ALIVE ogni 250 ms, + 1 s di padding nello scheduling del prune "to avoid over-eager timeouts" → prune effettivo ~6 s dall'ultimo ALIVE); il +5,78 s misurato corrisponde ai ~6 s effettivi entro la cadenza ALIVE di 250 ms → valore dal codice, indipendente dalla nostra misura, NON circolare; #8 NON è un secondo dato pulito: il suo drop è lo stop manuale del test; la variabile causale = durata del freeze RX dei beacon multicast, che i log device NON espongono. → **Strategia 2 (banco), obbligatoria.** 🚧 HARDWARE BANCO (verificato sull'unità reale 20/06): (i) transizione 2.4↔5 controllabile = RISOLTO — il pannello dell'H388X provisioned "BULLFROG" (fw AGZHP_1.4.4) espone Band Steering on/off, radio per-banda on/off, canale per banda, potenza TX (dropdown %) → è l'AP di test a costo zero (smentita la riga "TIM non controllabile"); VR2800 non band-steera; OpenWRT = piano B solo per roam "morbido" 802.11v a comando. (ii) cattura multicast = APERTO — il router non fa packet-capture, serve sniffer monitor-mode/mirror/peer-testimone, da risolvere PRIMA del banco. Dettagli: H388X_RIFERIMENTO_ROUTER_TEST.md. **Spec A/B:** roam **2.4→5 marginale entro ≤2 s da un cambio-sezione** vs **lontano (>10 s)**, n≫1; se A≫B la co-occorrenza conta, se A≈B era coincidenza. **Niente fix Layer 2 sui soli log.**
- **Dominio:** CC (+ rete).

## ⚠️ 1.2 — Non bloccanti palco, da chiudere pre-release v1 (🟠 OPEN MEDIA)

### TD-link-indicator-stale — Indicatore peer/LED Direttore "stale" se Link attivato con peer già presente (🔵 COSMETICO — SOSPESO 24/06)
- **Sintomo (device-confermato 23/06):** sul **Direttore** l'indicatore Q-BEATS mostra **"standalone" / LED spento** mentre il peer **È** collegato — visibile nel **pannello Ableton nativo** e con **sync precisa** (il Follower segue corretto). Il **Follower** mostra "Peer"/LED verde. **Recovery device-confermato:** aprire+chiudere il pannello Ableton nativo (o toggle Link OFF/ON) sul Direttore → LED verde.
- **NON è TD #17:** nessuna perdita reale di peer (baseline `peers:1` stabile, sniffer pulito). È **solo l'indicatore** rimasto indietro; la sessione Link è viva (per questo suona in sync).
- **Asimmetria NON di ruolo (verificato):** lo stesso `linkIsConnected` governa entrambi i ruoli — nessun ramo lo tratta diversamente per `.direttore`/`.collaborativa`; il ramo `.direttore` di `start()` (`AudioEngine.swift:967`) NON pilota l'indicatore (depistaggio escluso dai verificatori). **Osservato:** Follower (Link acceso per primo, da solo) → LED verde; Direttore → indicatore spento. **Perché il Direttore differisca dal Follower non è risolto:** segue il sotto-meccanismo (a|b) in Causa — sotto **(a)** è l'ordine d'accensione (peer già presente all'enable del Direttore), sotto **(b)** l'ordine è identico per entrambi e la differenza resta nel **fronte soppresso**.
- **Percorso di codice (citato VERBATIM, master `f5c6dea`):**
  - `AudioEngine.swift:38` — `@Published var linkIsConnected: Bool = false` = **unica** fonte di LED + testo (letta da `SettingsView.swift:41`, `LiveHeaderView.swift:94`, `ContentView.swift:71`).
  - `AudioEngine.swift:441-448` — callback IsConnected: `engine.linkIsConnected = isConnected` (aggiorna **solo a fronti**).
  - `AudioEngine.swift:464-500` (callback IsEnabled) **e** `:1285-1325` (`setLinkEnabled`) — **entrambi** i rami enable seminano dallo stato vivo (`link_engine_is_connected`) + **un SOLO re-check a +2s** (`asyncAfter .now()+2.0`) se `!isConn`. L'enable iniziale passa di qui via `LinkEngine.mm:344` (`isEnabledCallback_(true)` da `link_engine_activate`). → **non esiste un ramo enable "senza semina".**
  - `LinkEngine.mm:353-364` — poll diagnostico **one-shot** a +5s: **scrive solo `os_log`, NON aggiorna lo stato**.
- **Causa — tre livelli, tenuti distinti:**
  - **PARZIALMENTE SUPPORTATO / causa NON confermata dal log** (riletto verbatim 24/06):
    - **FATTO stampato:** `zero` `[Q-BEATS][LINK][CONNECTED]` per ~10 min (12:46:31→12:56:33); `numPeers:1` all'enable = cache `numPeers_`, scritta da un `[CONNECTED]` scattato **prima** dell'inizio cattura (12:45:07).
    - **INFERENZA dal codice (NON stampata):** in tutto il log manca la riga `check 2s post-enable`; poiché il re-check +2s parte solo `if !isConn`, sotto il codice attuale la semina avrebbe letto **connesso** → spia **verde** quei 10 min, NON spenta. (Lettura del codice, non un valore loggato.)
    - **NON stampato affatto:** il read vivo (`link_engine_is_connected`) in un istante di stallo — questa build lo legge solo nel +2s condizionale, mai in continuo. Stallo candidato = il **flapping** dalle 12:56 (fronti che *scattano*; perdita-vera vs spia-indietro non separabili senza pannello/read-vivo).
    - **RIMOSSO** il precedente *"semina/re-check letto `false`, LED spento 10 min"*: era il **rovescio** dell'inferenza dal log.
  - **(a)/(b) MOOT per questa cattura:** il framing "fronte mancato all'enable" — (a) peer già a 1 → semina `false`; (b) fronte tardivo soppresso — presupponeva una semina `false` che l'inferenza sopra **non** sostiene qui. Resta **ipotesi generale** solo se un diagnostico mostrasse un enable con read-vivo `false` + peer presente.
  - **IPOTESI (LinkKit closed-source):** la sequenza di `link_engine_activate`, costruita per **"zero transizioni false→true"** (`LinkEngine.mm:343`, fix TD #44), plausibilmente sopprime il primo CONNECTED e/o fa leggere `false` a `link_engine_is_connected` subito dopo l'activate.
  - **Perché il fix POTREBBE tenere (condizionato):** se il read vivo è fedele (Mondo 1) la lettura ricorrente riallinea senza distinguere (a)/(b) — ma "read vivo fedele" è l'assunzione **non ancora provata** (gate-zero, vedi Stato).
- **Direzione fix (proposta, NON ratificata) — lato Swift, NIENTE bridge L2:** l'indicatore legge lo **stato VIVO** della connessione (`link_engine_is_connected` → lo stesso `ABLLinkIsConnected` che mostra il pannello Ableton nativo) in modo **RICORRENTE finché Link è attivo** (ogni 1–2 s) e si adegua in **entrambe le direzioni**: peer compare → verde, peer sparisce → spento. Guidato **sempre** dallo stato vivo, **mai** dal callback a fronti in nessuna delle due direzioni. Vive in `AudioEngine.swift` (timer + lettura del getter già esistente) → **non tocca `LinkEngine.mm`** (niente flag L2, niente audit RT §4).
  - **Principio:** non costruire la cura sull'**unico meccanismo già visto rompersi** (il callback a fronti, interno a LinkKit, codice chiuso). Per questo niente "poi mi fido del callback" in nessuna direzione.
  - ❌ **SCARTATA — "a tempo" (controlla per N secondi poi stop):** buco sull'**arrivo tardivo** — se il peer entra dopo la finestra, ci si appoggia al callback, che nel log ha mancato **proprio il primo arrivo**.
  - ❌ **SCARTATA — "finché disconnesso con tetto" (versione precedente di questo ticket):** **due buchi.** (a) *Uscita:* appena vede il peer il loop si ferma → il distacco torna a dipendere dal callback (la scatola chiusa che ha già mancato un fronte); se mancasse un fronte di distacco, l'indicatore resta **verde-fantasma** e non si auto-corregge più (il loop non riparte, "si crede connesso"). (b) *Arrivo:* il tetto ferma il loop anche se il peer non è ancora entrato → riapre il buco dell'arrivo tardivo.
  - ✅ **SCELTA — "ricorrente in entrambe le direzioni":** **nessuno** dei due buchi (non si fida mai del callback, legge sempre la verità viva) e **costo zero in più** della versione "finché disconnesso" (stesso poll, solo senza condizione di stop).
- **Workaround palco (immediato):** aprire+chiudere il pannello Ableton nativo sul Direttore dopo che il peer è connesso (più gentile del toggle Link: non lascia cadere la sessione).
- **Scope:** indicatore **binario** (verde = peer presente, spento = nessun peer); obiettivo = il Direttore vede l'aggancio. Distinto da `TD linkPeers` (Sez.2): qui il problema è il **booleano stale**.
- **Stato:** 🔵 **COSMETICO — SOSPESO (24/06).** Non bloccante: **il peer NON viene perso**, la sync è sempre corretta — è **solo l'indicatore**, intermittente (prova 24/06: regolare anche col Direttore acceso dopo il Follower; trigger ignoto). Sintomo + recovery **device-confermati 23/06** (resta ground truth). Meccanismo LinkKit = **ipotesi**; questa build **non logga il read vivo** → un eventuale fix va deciso solo dopo un diagnostico (FASE 0). **NON 🟢 CHIUSO, NON inseguito ora:** lavoro fatto (ricognizione + review + direzione fix 129-133 + lean "Mondo 1") **agganciato qui** → se diventa più che cosmetico si riparte da lì. Decisione 24/06: energie su fronti core (Control Center audio). Workaround utente → INFORMATION (Pre-volo).
- **Dominio:** CC.

### TD-control-center-slide-audio — Click rallenta durante l'ANIMAZIONE dello slide del Control Center (🔵 COSMETICO / AMBIENTALE — non bloccante / mitigato)
- **FATTO osservato (device, Mauro 24/06, ground truth):** rallentamento del click **solo durante l'animazione dello slide** (mentre si tira giù la tendina). **Assente** a tendina **completamente aperta e ferma**; **assente** a tendina chiusa. **Recupero pulito** a tempo alla chiusura (nessuno sfasamento residuo). **Solo iPad A10 (iPad 7), NON iPhone.** **Solo con setlist LONG (9h), NON con la L1b normale.**
- **CAUSA verificata alla fonte (master `af2e3bd`, file:line):** il click esce da `AVAudioPlayerNode` (`AudioEngine.swift:263`) via `scheduleBuffer`; la continuità tra buffer è un loop JIT — il completion handler ri-accoda `scheduleNextBuffer` su `audioQueue` (coda GCD **non-RT**, `:2613-14`). **Nessun** `AVAudioSourceNode`/`AURenderCallback`/`manualRenderingMode` (grep negativo) → il click **non** è su un render thread RT vero; l'`installTap` su mainMixerNode è "RT-equivalente, **NON** il vero render thread Core Audio" (`:1966-67`), ed è per il broadcast Link. `scheduleNextBuffer` fa **sync Link per-buffer** sulla stessa `audioQueue` (`:2235+`). **Punto debole = riarmo JIT su `audioQueue` non-RT, NON il render.**
- **INFERENZA (etichettata, NON fatto):** l'**animazione dello slide**, *mentre in corso*, sottrae priorità ai thread non-RT → `audioQueue` resta indietro oltre il cuscinetto di pochi buffer → il playerNode va a secco → il click rallenta; **ad animazione conclusa** (aperta-ferma o chiusa) la priorità rientra e il click **recupera pulito**. Coerente coi fatti device. **→ SOSTITUISCE l'inferenza precedente "Control-Center-aperto-in-sé strozza i thread" (SUPERATA): non è l'overlay aperto, è l'animazione in movimento.**
- **"Solo LONG" → INFERENZA (non fatto):** setlist lunga = più lavoro di stato/rifornimento per-buffer → cuscinetto più fragile sotto il picco dell'animazione. Etichettata, da verificare.
- **RECORDED non-riconfermato (`project_qbeats_control_center_audio_slowdown.md`, 5 gg, point-in-time):** il vecchio claim "rallenta **solo col peer reale**" NON è menzionato nell'osservazione 24/06 (peer non dichiarato in questa prova). Rapporto "LONG" ↔ vecchio "solo col peer" = **dettaglio aperto, NON assunto risolto.** Cuscinetto **~20-32 ms** = RECORDED, non ri-misurato qui.
- **Livello:** vive nel **riarmo/scheduling su `audioQueue`** — coda GCD applicativa **non-RT**, confine **L2/L3**. **NON L3-presentazione**, **NON render RT vero L1.** La cura strutturale toccherebbe **L1/L2**.
- **Mitigazione (dichiarata):** **Accesso Guidato** sul palco rende il gesto quasi impossibile (→ user-facing in INFORMATION); **Direttore su device non-A10** non lo vede; **setlist normale** non lo vede. Transitorio ~1s che recupera da solo.
- **Fix strutturale = opzione FUTURA GRANDE, esplicitamente NON perseguita ora (Strada B, 24/06):** click su **render-callback RT vero** (`AVAudioSourceNode`/`AURenderCallback`, lock-free, **zero** alloc/`os_log`/`main.async` sul cammino RT) → toglie il click dalla coda contesa. **Tocca L1/L2, il cammino RT §4 e il codice Link/sync/Bug 2.b già stabilizzato** → sproporzionato per un transitorio ~1s, non bloccante, gesto raro, device non principale, setlist estrema, con recupero pulito. **Resume-path agganciato:** ricognizione punto-alla-fonte (af2e3bd, sopra) + file-memoria.
- **Stato:** 🔵 **COSMETICO / AMBIENTALE — SOSPESO (Strada B, 24/06).** Non bloccante, mitigato, **NON inseguito**. **NON 🟢 CHIUSO** — se si manifesta su un device capace/sano o con setlist normale, si riparte da qui. Fronte prima **non tracciato in BUGS** (solo memoria) → tracciato ora.
- **Dominio:** CC (+ audio L1/L2 se un giorno si fa il fix).

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

### Bug 2.b (faccia visiva/counter) — desync sezione/time-sig cross-device, SOLO visivo (🟢 faccia i CHIUSA 19/06 / 🟠 faccia ii OPEN)
- **Inquadramento:** Bug 2.b è 🟢 CHIUSO lato **audio + ingresso** (Ferita A+B, TEST7, Sez. 2). Restano APERTE le facce **visive/counter** dello stesso desync sezione/time-sig cross-device: il fix audio non le tocca. Audio corretto, sbagliato solo ciò che si vede. **AGG 19/06: faccia (i) striscia segmenti → 🟢 CHIUSA (blocco sotto); resta aperta solo la faccia (ii) counter.**
- **🟢 FACCIA (i) — STRISCIA SEGMENTI: CHIUSA 19/06/2026 (device-validata + merge su master).** Fix **`dfe758d`** (rimosso il republish stantio di `currentAccentPattern` in `start()`), portato su **master in fast-forward** (`f0a60d1..dfe758d`, push verificato; blob `AudioEngine.swift` = `342edc6` = identico all'IPA testata; autore+committer Mauro, no `Co-Authored-By`). Fixture di verifica (`e1422aa`, solo `DebugView.swift`) lasciate sul branch, fuori da master.
  - **Validazione device 19/06** (IPA CI `27815523191`, 2 device): Test **1** (anti-reg in-sync 4×), **2a** (cold 3/4 standalone), **2b** (cross-device stop/restart 7-8×), **3a** (accenti custom 1&3 al cold Play = repro PRIMARIO), **3b** (accenti dopo telefonata), **4a/4b** (4/4→3/4→7/8 standalone + cross-device) → **TUTTI PASS**.
  - **⚠️ Validazione VIA PROXY, NON sul repro originale.** Il join-a-metà-canzone del repro 12/06 è **irriproducibile** (limite architetturale: Link non trasporta la posizione di scaletta → il Follower riparte sempre da Song A; vedi §1.1 e fronte setlist-gate). Il conteggio è validato sul **percorso proxy stop+restart**, che — verificato in codice (workflow 6 indagini + cross-check, 7 agenti, 19/06) — **esercita lo stesso blocco `start()` del fix** e ricrea la stessa race `_beatsPerBarQ` stantio in **polarità inversa (stale-4 vs corretto-3)**. *Non scrivere "validato sul repro originale".*
  - **Faccia accenti (stessa rimozione = stesso fix, NON voce nuova):** il vecchio republish calcolava `defaultAccentPattern(for: _beatsPerBarQ)` e, accodato su main DOPO `setAccentPattern` (FIFO), **sovrascriveva gli accenti CUSTOM col default a OGNI Play, anche standalone** → il fix li preserva (Test 3a/3b PASS). Prerequisito per gli accenti custom quando esisterà l'editor di Q-Stage.
  - **Epistemica:** causa **fortemente supportata** (fix mirato + device su tutti i percorsi raggiungibili); l'inchiodatura formale della sequenza-publish al join (*"log 23:04:56"*) **NON è stata riaperta → da confermare**, non "vista". Il dettaglio-investigazione qui sotto resta come trail storico, ora corroborato dal comportamento post-fix.
- **Faccia (i) — striscia segmenti metronomo 3 invece di 4 (Slow 90 4/4, Follower con peer):** in Link (iPad Direttore + iPhone Follower) la Slow 90 suona corretta 4/4 ma la striscia segmenti del Follower mostra **3 riquadri invece di 4**. **Sparisce senza peer** (senza Link sono 4) → natura **cross-device** confermata. Codice: `MetSlotStripView` disegna `displayAccentPattern.count` (callsite unico `LiveView.swift:94`); con peer il pattern accenti rispecchiato risulta lungo 3. Osservato su build **474** (`add556f`, branch `test/bug2b-test7-fixtures`) = codice master + sola fixture `DebugView.swift` (+37 righe, setlist test "BPB Mixed 121"); path UI/Link/audio byte-identico a master `ee0cbc0` → faccia visiva su codice di produzione, non artefatto del build di test (475 `ee0cbc0` = squash codice; 476 `3af4c97` = doc-only; entrambe NON installate). Osservazione Mauro 12/06.
  - **Repro preciso (device Mauro 12/06):** percorso **BRIDGE 3/4 → SONG B → SLOW 90 (4/4)**; con peer, entrando in SLOW 90 la striscia mostra **3 segmenti FISSI per tutta la sezione**, fino al cambio tempo successivo (**110 BPM**) che ri-pubblica e sblocca.
  - **Sorgente del "3" (inferenza forte, NON "confermato"):** il 3 **COMBACIA col BPB della sezione 3/4 nel percorso** — il pattern lungo 3 della 3/4 resta esposto nella 4/4 = forte evidenza a favore dell'ipotesi BPB-stantio. La sezione-sorgente esatta e la riga di codice restano da inchiodare in codice/log.
  - **Ipotesi candidata (struttura verificata in codice, causa NON inchiodata):** sul Follower l'ordine di start è invertito — il callback Link chiama `engine.start()` PRIMA che `runner.startSetlist` imposti il pattern della sezione (`AudioEngine.swift:533-539`, ordine inverso del percorso locale `SetlistRunner.swift:135`); `start()` pubblica un pattern DEFAULT lungo `_beatsPerBarQ` (`AudioEngine.swift:1020-1025`) → il 3 della 3/4 precedente resta esposto.
  - **Sotto-domanda momentaneo-vs-persistente: RISOLTA verso il PERSISTENTE per questo repro** (osservazione device diretta 12/06; lo storico 31/05 "per un attimo" resta valido come osservazione di allora). **Ipotesi etichettata come tale finché il log iPhone (`displayAccentPattern`/`currentAccentPattern` con e senza peer) non inchioda la riga.**
  - **Controllo a occhio 4° beat: ✅ ESEGUITO (video Mauro 12/06) — firma CONFERMATA.** Ciclo osservato in SLOW 90 (4/4, audio corretto, il 4° beat viene battuto): beat 1 → 1° segmento verde (accento), beat 2 → 2° bianco, beat 3 → 3° bianco, **beat 4 → niente si accende** (il 3° si spegne), poi riparte dal 1°. = `beatActive`=4 cade fuori dai 3 slot (`MetSlotStripView.swift:10`): la striscia sta letteralmente disegnando la battuta da 3 della sezione precedente mentre l'audio batte 4/4. Video registrato da Mauro = evidenza device (da archiviare in `E:\…\LOG\RUN\`).
  - **Timing del flip (video Mauro 12/06) — FATTI OSSERVATI, CONFERMATI:** sequenza: arrivo da 3/4 → standby "TEST SONG B" → tap → il Direttore fa la prima battuta in solitaria (4 beat, da progetto); in quei 4 beat il display del Follower si popola con **4 segmenti (corretti)** e counter «bar 2 of 3» (da progetto CD-Q1=B: il Follower entra a battuta 2); **il flip 4→3 avviene ESATTAMENTE al momento del join** (ingresso del Follower col Direttore); il 3 persiste fino al cambio successivo (110). Il flip-al-join **scarta il candidato "la correzione non arriva mai"**: il valore corretto c'era, poi è stato sovrascritto.
  - **Lettura CANDIDATA (IPOTESI, riga da inchiodare col log):** al join un publish con `_beatsPerBarQ` stantio=3 (candidato: quello di `engine.start()`, `AudioEngine.swift:1020-1025`) sovrascrive il 4, e niente ripristina il valore corretto fino al cambio successivo (110). Meccanismo candidato che concilierebbe la tensione sotto: il publish di `start()` viaggia su `main.async` (stessa dispatch che setta `isPlaying`) → potrebbe atterrare AL FIRE del join, DOPO il publish del runner fatto al tap → ultima scrittura = stantio. **Da confermare col log, non è un dato.**
  - **QUESTIONE APERTA per il log (sintomo chiuso; resta solo l'inchiodatura forense del log):** la struttura verificata in codice è `engine.start()` chiamato PRIMA di `runner.startSetlist` — presa da sola, l'ultima scrittura sarebbe quella corretta del runner e a vincere sarebbe il 4; invece sul device vince e persiste lo stantio (3). L'esatta sequenza dei publish attorno al join (chi scrive per ultimo, e perché lo stantio non viene ripristinato) è ciò che il log iPhone deve inchiodare.
- **Faccia (ii) — counter "bar 2 di N" offset a partenza pulita (ex faccia D di TD-follower-rejoin §1.1):** il Follower mostra offset di barra (es. "bar 2 di 4") anche ad aggancio pulito. Parte counter di **CD-Q1=B** (deliverable CD, rimandato a Fase 6-7-bis). Origine: BUGS v2 (Bug 2.b "counter offset + desync visivo"). Dato finora: 2 campioni `[SinkDiag-AQ]` a 32 (insufficienti) — serie completa da catturare (vedi §1.1 verifiche residue).
- **Distinta da (NON fondere):** TD-follower-rejoin **faccia B** (§1.1, "segmenti stantii DOPO cambio setlist", audio a volte stale) → **trigger diverso** (cambio setlist vs steady-state; audio stale vs corretto). Stessa firma visiva, meccanismo da falsificare prima di consolidare.
- **Stato:** **faccia (i) striscia segmenti → 🟢 CHIUSA 19/06/2026** (fix `dfe758d` su master, device-validata via proxy — blocco sopra). **Faccia (ii) counter "bar 2 di N" → 🟠 RESTA OPEN** (CD-Q1=B, deliverable CD rimandato a Fase 6-7-bis; il fix accenti non la tocca). Entry mantenuta in §1.2 per la faccia (ii).
- **Dominio:** CC (+ CD per il counter CD-Q1=B).

### Striscia segmenti: conteggio e accensione da due fonti separate — debito strutturale (🟠 OPEN MEDIA / struttura)
- **Origine:** emerso dalla verifica avversariale del fix di Bug 1 (workflow 8 agenti, 18/06/2026 — **pre-filtro di ragionamento di CC, NON device/compilatore, NON verità indipendente**). NON è la causa di Bug 1 (quella = republish stantio di `currentAccentPattern` in `start()`, rimosso): è la **classe** di guasto che resta rappresentabile anche DOPO quel fix.
- **Difetto strutturale:** `MetSlotStripView` ricava il **numero di segmenti** da `displayAccentPattern.count` (`MetSlotStripView.swift:9`, callsite unico `LiveView.swift:94`), mentre il **beat acceso** (`beatActive`) è calcolato da `displayBpb`/`$beatsPerBar` (`LiveView.swift:336-339`). Due fonti `@Published` indipendenti, due buffer pending separati (`pendingBpb`/`pendingAccentPattern`). Se in un qualunque istante `count(pattern) < beatsPerBar`, l'ultimo beat non ha un segmento da accendere → firma "N battiti / N-1 segmenti" (la stessa di Bug 1).
- **Scenario B (SERIO — integrità dati, riproducibile ANCHE STANDALONE, senza Link):** `SongSection.accentPattern` è un `[UInt8]` libero; né `init` né il decoder JSON validano `accentPattern.count == beatsPerBar` (`SongSection.swift:11,15-52`). Una sezione malformata (es. 4 battiti, pattern lungo 3) — salvata/importata/editata male — rifà "4 battiti / 3 segmenti" al Play, **senza join e senza peer**. Buco di integrità dati: morderebbe su una setlist importata o editata male sul palco. ⚠️ Ad oggi nessun fixture/`makeDefault` genera il mismatch (pattern sempre coerente col bpb), quindi non riproducibile coi dati attuali — ma il modello lo permette.
- **Scenario A (MINORE — transitorio):** al cambio sezione i due valori arrivano su due canali `@Published` e in un edge di scheduling possono divergere ~1 tick (non la persistenza a 5 battute di Bug 1). **Stato: solo teorico** — dedotto dal codice dall'agente-architettura, **mai osservato su device né in log**. Da confermare/falsificare prima di trattarlo come reale.
- **Cura proposta (round a sé, dopo Bug 1):** (1) la striscia dimensiona i segmenti dalla **stessa fonte del beat** (`displayBpb`/numero battiti), usando `displayAccentPattern` solo per **colorare** slot-per-slot (con padding/troncamento difensivo se le lunghezze divergono); (2) **invariante** `accentPattern.count == beatsPerBar` imposto in `SongSection` (init + decoder). Combinati, rendono "N battiti / <N segmenti" **impossibile per costruzione** (difesa-in-profondità SOPRA la rimozione di Bug 1, non al posto suo — non maschera la scrittura cattiva, che è già tolta alla radice).
- **Vincolo di processo (ratificato Mauro 18/06):** **NON impacchettare nel diff di Bug 1** (renderebbe il test device non attribuibile — rimozione vs indurimento). Round separato, diff separato, **test device separato**, **DOPO** il verde device di Bug 1. Opzione "tutto in un diff" = ESCLUSA.
- **Stato:** 🟠 OPEN MEDIA per Scenario B (integrità dati); A in attesa di conferma. ⚠️ non bloccante coi dati attuali. Verde solo dopo device.
- **Dominio:** CC.

### MIDI azioni-contenuto non cablate a L3 — pedaliera mani-libere (🟠 OPEN MEDIA / feature-completion, NON cosmetico — dietro TD#17)
- **Cos'è:** transport base **wired** (Play/Pause, Stop, Tap Tempo, Mute Click, Stop Backtrack); la **navigazione del contenuto** è stub che logga «richiede Layer 3» (`AudioEngine.swift:1608`): **Next/Prev Section, Next Song, Start Song (= sblocco standby), Loop**. Promessa-palco: pedaliera/tastiera MIDI **mani-libere** pilota canzoni/sezioni in Q-Live + prova Q-Studio (il batterista a metà brano non tocca lo schermo). NON cosmetico (≠ LED / Control Center parcheggiati 🔵).
- **Thread-safety = già OK** (concesso): `executeMIDIAction` gira su **main** (`handleMIDIInput` → `DispatchQueue.main.async` `AudioEngine.swift:1576`); I/O backtrack già **fuori dal RT** in `armBacktrack` (`audioQueue.async` `:1464`). Il rischio NON è il thread.
- **Lavoro = handoff L2→L3**, rispettando «AudioEngine ignora il setlist» (per design): pubblicare l'azione su un canale engine→L3 (pattern `beatTickSubject`/`@Published`) e far eseguire a L3 ciò che fa il TAP. **Mai** reference diretta engine→`SetlistRunner`. Completa l'handoff a L3 che il codice stesso documenta — non lo bypassa.
- **Audit di build (§4) — il rischio vero = timing della transizione, non il plumbing:** ogni comando deve passare per la stessa transizione del suo equivalente UI. `nextSection`/`prevSection`/`nextSong` a brano in corso → ri-armatura quantizzata al beat tick (finestra SEAMLESS, `LiveView.swift:31-35`/`263-266`), zona race confine-sezione (cfr. §1.3 «Doppio-click Direttore al confine di sezione» / `BUGS:116-124`) — il percorso L3 **non deve saltarla**. `startSong` esente (audio fermo, nessuna finestra seamless).
- **Confermato alla fonte (26/06):** `nextSection`/`prevSection` = equivalente UI mid-play **ESISTE** (`TransportView.swift:28`/`:68` → `prevSection()`/`nextSection()`) ⇒ MIDI = **mirror del TAP**. **`nextSong` = NESSUN controllo UI per saltare canzone a brano in corso** (oggi l'avanzamento canzone è solo: fine sezione → standby [audio fermo] → tap → `startCurrentSong`) ⇒ **`nextSong` mid-play via MIDI = comportamento NUOVO**, non "specchia il TAP" → richiede **design di transizione proprio** (la canzone in corso: taglio netto? finisce la sezione? va a standby?) — da decidere Mauro + CD quando si costruisce. `startSong` = mirror dello standby tap (`LiveView.swift:131`), esente.
- **Priorità:** **dietro TD#17** (affidabilità prima della feature mancante), candidato forte alla prima pausa di Q-Stage. Posizione esatta vs TD#17 = chiamata di Mauro.
- **Validazione:** device, con tastiera/pedaliera MIDI (Mauro). Parte **Q-Studio** = arriva col container (non ancora costruito) → cablare a un controllo di riproduzione **condiviso** (Live + Q-Studio), non setlist-only.
- **Dominio:** CC. **Stato:** 🟠 OPEN MEDIA (feature-completion), schedulato.

### TD-peer-reconnect-button — Riaggancio manuale del peer in Q-Live (🟠 OPEN MEDIA / feature — rete di sicurezza TD#17)
- **Cos'è:** un comando **nella vista Q-Live** che, a peer Link perso, lo **ri-aggancia a mano** — senza uscire dall'app né aprire menu di sistema. Rete di sicurezza operativa per il palco (paracadute a valle della prevenzione-rete di TD#17).
- **Perché (problema reale, non teorico):** l'unico recovery oggi documentato (TD #17, §1.1) è *«toggle Link OFF/ON, oppure uscire/rientrare dalla vista»* → **impraticabile dal vivo** (il batterista con le bacchette in mano non esce dai menu mentre suona). Inoltre, a peer perso, Link può metterci **~10 min** a re-includerlo da solo (caratterizzazione TD#17) → un re-join a comando riduce l'attesa a un gesto.
- **Cosa NON si rompe durante il drop (device-confermato 11/06, `BUGS:103-104`):** il metronomo **continua a suonare** ed entrambi i device proseguono; il tempo **NON va fuori** (free-run −11 ms su 16,6 s senza peer = inudibile). Il danno è **SOLO FINALE**: lo stop del Direttore non si propaga → il Follower finisce la propria setlist da solo (~1,5 s) = **END SHOW desync** già noto.
  - → **SCOPO REALE DEL BOTTONE:** non salva il **tempo** (regge da sé) — **ricuce il collegamento PRIMA che arrivi lo STOP**. Si preme **con calma, guardando la spia, mentre il pezzo continua** — non nel panico. Questo lo rende **meno urgente e più difendibile**.
- **Meccanismo proposto (comportamento, NON implementazione — il codice di re-init è da verificare alla fonte):** replicare lo **stesso ri-init di Link** che oggi avviene uscendo/rientrando dalla vista — documentato in TD #17 §1.1 come *«ri-init Link → peer ri-formato all'istante»* — ma dietro un **pulsante in Q-Live**. **Manuale, a comando dell'operatore.**
- **Distinzioni (NON confondere, NON riaprire decisioni):**
  - ≠ **recovery automatico** (l'app che si riaggancia da sola): questo è **manuale**, a comando dell'operatore. *(Fonte non-canonica: nelle **memorie CC** `project_qbeats_handoff_13_06_2026` risulta che Mauro il 13/06 scartò «NIENTE recovery automatico del socket = pezza spegni-e-riaccendi» — **non tracciato in BUGS/LIBRO**, da riconfermare. Il bottone manuale non contraddice quella direzione.)*
  - ≠ una **spia «peer perso»** (avviso, non azione): la spia **avvisa**, il pulsante **agisce** → coppia di emergenza naturale. *(Fonte non-canonica: la spia risulta proposta nelle **memorie CC** `project_qbeats_td17_analisi_notturna_16_06_2026` / `project_qbeats_handoff_16_06_2026` in un round-fix mai aperto — **non tracciata in BUGS/LIBRO**.)*
  - ≠ **TD #17** (§1.1): quello è causa/prevenzione lato rete; questo è la mitigazione lato-UI a valle.
- **Accortezza critica (perché è lavoro vero, non due righe):** il re-join **non deve disturbare l'audio in corso** (il metronomo continua a suonare mentre Link si ri-aggancia). Da progettare: stato/feedback del bottone, cosa fa il tempo durante il re-init, doppio-tap, comportamento se non c'è alcun peer da riprendere.
- **Priorità:** non bloccante. **TD #17 è 🟠 OPEN MEDIA dal 22/06 — NON più 🚨 bloccante palco** (`BUGS:109`): root cause circoscritta al router **H388X** (non fa passare il multicast Link cross-banda), il **VR2800 di palco è pulito** (`BUGS:100`), la **rete single-band = cura di palco sufficiente** (`BUGS:108-109`). Questo bottone è **rete di sicurezza a valle**, non il fix del bloccante (che bloccante non è più). Posizione vs altri fronti = chiamata di Mauro.
- **Validazione:** device, a peer forzatamente perso (roam / rete sporca), con Mauro.
- **Origine:** discussione Mauro↔CC 11/07 — idea ricordata da Mauro, **non trovata negli atti precedenti** (ricerca in memoria CC + BUGS + LIBRO + BOX3 fino a V87) → **registrata ora per non perderla**. Non ancora in `LIBRO_MASTRO`: sale in Sez. 2/3 solo se ratificata come decisione di prodotto con CD.
- **Dominio:** CC (ri-init Link dietro il comando) + CD (UX del pulsante in Q-Live). **Stato:** 🟠 OPEN MEDIA (feature / mitigazione) — **DA PROGETTARE con CD**.

### Base audio non suona in Live da una Song — cablaggio mancante (🟠 OPEN MEDIA / feature-completion — cantiere Tracce)
- **Cos'è:** una Song si ricorda la sua base (`Song.backtrackFilename`) e l'app sa suonare una base (`armBacktrack` + `backtrackPlayerNode`), ma **nel flusso Live reale la base NON viene caricata/avviata da una Song**: `armBacktrack` è chiamata **solo da `DebugView.swift:186`** (test). Manca quindi il "**un solo START → base + metronomo partono insieme e restano allineati**".
- **Non è una regressione:** non ha mai funzionato nel flusso vero — è feature **da costruire**, non rotta. Loggato per visibilità (non dare per scontato che già funzioni — emerso dal brief Media di CD, 26/06).
- **Sede del lavoro:** **cantiere "Tracce" (Media › Tracks)** — far suonare la base dal vivo è parte integrante di quel cantiere (libreria basi + picker nell'Editor + cablaggio playback sincronizzato al click). Coerente con LIBRO (Media, una base/Song).
- **Scope tecnico (quando si costruisce):** all'avvio canzone caricare la base da `QBeatsStore.backtrackBaseURL()`, avviarla in sync col metronomo (un solo START), gestire stop/standby. Niente streaming (vincolo). `Song` invariato.
- **Validazione:** device (Mauro), con una base reale assegnata a una Song.
- **Dominio:** CC. **Stato:** 🟠 OPEN MEDIA (feature-completion), gated dietro l'apertura del cantiere Tracce.

### Nodo A — Q-Live montata FUORI dal NavigationStack (modale UIKit) — navigazione/plumbing L3 (🟠 OPEN MEDIA / struttura — gate device "parità firing stop")
- **Cos'è:** la radice dell'app commuta tra due schermate (`AppRootView.swift:8,13,27-33`: enum `Screen{home,qStage}`, `HomeRootView`↔`QStageRootView`). **Q-Live NON è in questo enum:** è montata come **modale UIKit** — `UIHostingController(LiveRootView)` + `modalPresentationStyle=.overFullScreen` + `.present()` sul `rootViewController` della window (`HomeRootView.swift:77-88`, func `presentLive()`). Lo dichiara il codice stesso: commento `AppRootView.swift:10-12` "Q-Live resta una modale UIKit … riconciliazione top-level = Nodo A (a verbale)".
- **Sizing (referee 27/06): è L3 navigazione/plumbing, NON ri-architettura.** L'engine NON è accoppiato allo stile di mount: parte su **azione** (`SetlistRunner.swift:222 audioEngine.start()`), si ferma su **ciclo-vita-vista** (`LiveView.swift:187 .onDisappear{audioEngine.stop()}` + `HomeRootView.swift:40 .onAppear{audioEngine.stop()}`). **Framing 15/07:** la ratifica 10/07 (LIBRO Sez.2, riga `2026-07-10`) NON è una conversione present→push — è il **ritiro completo della modale** (Nodo A sciolto, `.qLive` aggiunto a `AppRootView.Screen`, piano `HANDOFF/NODO_A_PIANO_2026-07-10.md`). Il punto tecnico resta valido: l'engine non è accoppiato allo stile di mount, quindi il cambio **non tocca L2/L1** (niente audit RT §4).
- **🔴 GATE DEVICE (quando Nodo A si scioglierà — ritiro modale, ratifica LIBRO 10/07):** **parità del firing dello stop tra modale `.overFullScreen` e la nuova commutazione di schermata (`.qLive`).** In `.overFullScreen` il presenter (Home) **non viene rimosso** → `HomeRootView.swift:40 .onAppear{stop}` può **non** scattare alla dismiss; lo stop primario `LiveView.swift:187 .onDisappear{stop}` va verificato equivalente tra dismiss-modale e la nuova commutazione. Parità **INFERITA, non sourced** → da provare su device ("L3" ≠ "chiuso a CI verde").
- **Stessa radice del DEV-fallback `LiveRootView.swift:6-10`** (Nodo B, selezione setlist incondizionata) e del ticket "Base audio non suona in Live": "Q-Live gira su un percorso provvisorio". Ticket distinti, da affrontare insieme quando si costruisce il ponte **Select Setlist→Live**. Gata SOLO quel ponte; non blocca l'authoring né `b81e3a8`.
- **Dominio:** CC. **Stato:** 🟠 OPEN MEDIA (struttura/plumbing L3), non bloccante; gate device alla costruzione.

### SettingsView — unico ingresso dietro #if DEBUG, nessun ingresso in build Release (🟠 OPEN MEDIA / ingresso latente — accoppiata al fronte ⚙ Settings)
- **Cos'è:** `SettingsView` (config modalità Link, pannello Ableton, promemoria DND) ha **un solo ingresso, dietro `#if DEBUG`**. Catena verificata alla fonte (`b81e3a8`): è una `.sheet` di `ContentView` aperta dal gear in toolbar (`ContentView.swift:76-84`); `ContentView` è montata **solo** dentro `.fullScreenCover(isPresented:$showDebug)` sotto `#if DEBUG` (`BivioBoardView.swift:64-79`), aperta dal bottone "⚙ DEBUG" anch'esso `#if DEBUG` (`BivioBoardView.swift:48-55`).
- **Stato attuale (NON un guasto oggi):** la CI *iOS Signed Build* firma l'IPA in **`-configuration Debug`** con flag `DEBUG` attivo (`.github/workflows/ios_build.yml:48,53`) → sull'IPA che la band usa **adesso** il bottone "⚙ DEBUG" c'è e **Settings È raggiungibile** ("⚙ DEBUG" → `ContentView` → gear → sheet). *(Correzione 28/06: la prima stesura diceva "nessun ingresso in produzione" assumendo una build Release — falso, l'IPA corrente è Debug; assunzione non sourced ritirata.)*
- **Gap LATENTE (morde alla prima build Release):** una build **Release** (App Store / TestFlight / qualunque `-configuration Release`) **compila via** l'unico ingresso → Settings **irraggiungibile**, l'utente non può cambiare `linkMode` (`AudioEngine.swift:45`) né aprire il pannello Ableton → ruoli/collaborativo non raggiungibili. Da risolvere **prima** di spedire una build Release/v1 (per questo 🟠 §1.2, non backlog).
- **Origine:** `ContentView` è il vecchio metronomo standalone, **demansionato a schermata di DEBUG** nel ridisegno Bivio/Q-Stage (`dd0fcaa` + `91897b1`); l'ingresso Settings non è stato ricollocato nella nuova architettura (Bivio / Q-Stage / Q-Live).
- **Accoppiato al fronte ⚙ Settings (CD):** Mauro+CC hanno RINVIATO la ⚙ nell'header; la `SettingsView` esistente **≠** da quella che CD immagina → l'ingresso di produzione va disegnato col fronte Settings, non rattoppato isolato.
- **Dominio:** CC (ingresso) + CD (disegno fronte Settings). **Stato:** 🟠 OPEN MEDIA (latente, pre-release v1).

### TD-qlive-libero-limbo — Q-Live "libero" intrappola l'utente (🟠 OPEN MEDIA / flusso pre-produzione — severità d'uso ALTA)
- **Sintomo (device, collaudo `59ab33e` 28/06, Mauro):** Q-LIVE dalla Home senza Show → videata non popolata ("Bar — of —"); Play → WAITING FOR DIRECTOR; START LOCAL → END SHOW immediato; i bottoni fine-show non rispondono → l'utente DEVE chiudere l'app.
- **Causa sourced (3 pezzi):** (i) DEV fallback `LiveRootView.swift:8` (`setlists.first ?? Setlist.makeDefault()` = setlist degenere) → END SHOW istantaneo; (ii) Play in default `.collaborativa` → waiting (`TransportView.swift:38-58`, ramo senza check peer, commento `:48-51`; fronte Standalone §1.4); (iii) bottoni fine-show vuoti: `FineSetlistView.swift:19` `Button("BACK TO SHOWS") { /* navigazione — Fase successiva */ }` + `:21` RESTART SETLIST idem.
- **NON regressione di `59ab33e`** (`--stat` = 0 file `UI/Live/`): pre-esistente, reso raggiungibile dalla porta Q-LIVE.
- **Ri-confermato sul device (Mauro 15/07/2026):** flusso rivissuto integralmente — Q-Live senza setlist installata → Play → WAITING FOR DIRECTOR → START LOCAL → END SHOW → uscita solo con kill+riavvio dell'app. **Conferma, non nuova diagnosi:** severità (🟠 severità d'uso ALTA) e causa a 3 pezzi invariate. Verbale del turno → changelog v36.
- **Cura:** scelta d'ingresso A) metronomo libero · B) setlist (memoria `project_qbeats_metronomo_libero`) → risolve il limbo alla radice + cablaggio bottoni + ponte Select Setlist→Live. Stessa radice di Nodo A (§1.2) + Nodo B (`LiveRootView.swift:6-10`).
- **Dominio:** CC (+ CD videata, Brief Fronte 2). **Stato:** 🟠 OPEN MEDIA (severità d'uso alta).

### TD-shows-authoring — Shows-lista reale, ma authoring setlist assente (🟠 OPEN MEDIA / feature-completion — fronte grosso, CD+referee)
- **Sintomo (device, collaudo `b1c50ab` 30/06, Mauro):** in Q-Stage la tab **Shows** non crea nulla — nessun `+`, nessuna lista. **NON è "manca il +": è tutta da costruire.** *(Storico al 30/06: la lista non esisteva ancora. Dall'atomo S3 [13-14/07] la lista ESISTE — vedi causa sourced aggiornata sotto; l'authoring resta com'era.)*
- **Causa sourced (aggiornata 15/07 — coordinate stale, sostanza invariata):** `QStageRootView.swift:22` monta oggi `ShowsListView(onExit:)` **REALE** (costruita nell'atomo S3, 13-14/07) — il commento di testata `QStageRootView.swift:7` ("Shows e Media sono placeholder") è esso stesso stale, vale ancora solo per Media (`QStageRootView.swift:26-31`, `QStagePlaceholderTab`). **Ma l'authoring dentro `ShowsListView` non è cablato:** nessun `+` crea-show (`ShowsListView.swift:42`, «§8 differito, nessun path di scrittura cablato»); card **non tappabili/non editabili** (`ShowsListView.swift:213-214`, «editing show = §8 differito»). **Shows-lista (display+search+sort) = reale; Shows-authoring (creare/editare/riordinare) = NON costruito.**
- **≠ "Shows" di Q-Live (palco, Opzione B):** quella è la **vista di esecuzione** della serata; questa è l'**authoring** (creare/ordinare le setlist dalle Songs). Due schermate, **un solo modello dati** (sotto).
- **De-risk (sourced S3+S4):** (a) modello **unico, già esistente** — `struct Setlist` (`Models/Setlist.swift:3`); CRUD store pronto (`QBeatsStore.swift:72-89` + `resolve` `:95`, `setlists.json`); stesso `Setlist` per palco (`SetlistRunner.swift:59`) e backup (`QBeatsBackupManager.swift:27-29`) → niente "due verità". (b) mount **pulito** — tab dentro il `TabView` (`QStageRootView.swift:17`) via commutazione (`AppRootView.swift:27-33`), **NON** eredita Nodo A (modale Q-Live, `HomeRootView.swift:76-88`); monterebbe come Songs (proprio `NavigationStack`, `SongListView.swift:19`).
- **Dominio:** CD (UX/flusso) + referee (architettura) → poi CC. **Stato:** 🟠 OPEN MEDIA.

### TD-editor-back-discard — la freccia indietro dell'editor canzone scarta le modifiche senza avviso (🟠 OPEN MEDIA / perdita-dati silenziosa — pre-esistente)
- **Sintomo (emerso dal collaudo `b1c50ab`, Mauro 30/06):** nell'editor canzone la **freccia indietro** scarta le modifiche del draft **senza avviso**; persiste **solo** il bottone SAVE. Riproduzione: BPM 230 → freccia indietro → riapri → torna a 120 (con SAVE resta).
- **Causa sourced (verbatim):** `SongEditorView.swift:22` `onBack: { dismiss() }` → `dismiss()` **non salva** il draft (`@State draft: Song`, copia di lavoro); il commit reale è **solo** `save()` (`SongEditorView.swift:95-98`, `await store.updateSong(draft)` `:97`), legato al bottone SAVE (`:25` `trailingAction: save`).
- **Perimetro (verificato grep `onBack:`):** `SongEditorView.swift:22` è l'**UNICO** scarto-silenzioso di un draft. `SectionEditorView.swift:29` (`commitBPM(); dismiss()`) committa al draft prima di uscire → nessuna perdita; `SongListView.swift:25` / `QStageKit.swift:85` (`onBack: onExit`) non hanno draft. La perdita è solo al back di livello-canzone, ma butta via **TUTTE** le modifiche pendenti (nome, count-in, sezioni, BPM).
- **Attribuzione: 🟠 PRE-ESISTENTE — NON regressione DIFF B (`9d047e0`).** Verificato: riga `:22` da `dd0fcaa` (27/06); `9d047e0` tocca **solo** `SectionEditorView.swift` (git show --stat).
- **Cura = decisione UX → CD** (es. avviso "salvare le modifiche?" alla dismiss con modifiche pendenti, oppure auto-save). NON implementare qui: fronte CD.
- **Dominio:** CD (UX) → poi CC. **Stato:** 🟠 OPEN MEDIA.

### TD-store-decode-swallow — errore di decode ingoiato in `coordinatedRead` (catalogo vuoto silenzioso) (🟠 OPEN MEDIA / perdita-dati se innescato — pre-esistente)
- **Fatto tecnico (righe verificate a HEAD `b4d3596`):** `QBeatsStore.coordinatedRead` (`ios_app/QBeats/Store/QBeatsStore.swift:148-172`) cattura l'errore di `JSONDecoder.decode` con **solo `logger.error`** e lascia `result` al default (`catch` a `:163-165`); `load()` passa default `[]` per `songs.json`/`setlists.json` (`:22-27`) → il chiamante riceve un catalogo vuoto come se fosse legittimo. **Contrasto preciso:** l'errore del COORDINATOR viene invece PROPAGATO (`throw`, `:167-170`) — l'I/O di coordinamento propaga, il decode no. Precisione: il `catch` copre l'intero blocco coordinato, quindi ingoia anche un'eventuale `Data(contentsOf:)` fallita (`:158`), non solo il decode; il caso "file assente" è invece gestito a monte come default legittimo (`:149-152`).
- **Impatto:** uno schema-break su `songs.json` (o `setlists.json`) si manifesta come **CATALOGO VUOTO IN SILENZIO** — per l'utente è perdita dati. NON è "latente e non osservato" come `TD-rt-vector-beatevent`: è un percorso reale che si INNESCA a ogni cambio di schema non gestito. Nell'uso corrente non si è ancora manifestato (oggi nessuno schema-break in produzione). **Rischio ALTO se innescato; trigger = qualunque modifica di formato senza retro-compat.**
- **Collegamento B7-A5:** A5 MITIGA il caso specifico "campo nuovo mancante" col decoder retro-compat (`decodeIfPresent ?? .fixed`), ma NON risolve il swallow come meccanismo — il decoder di A5 è la difesa per UN campo, il swallow è la crepa generale. Questo TD resta aperto anche a A5 chiusa.
- **Fix possibile (solo annotato, NON in questo commit):** distinguere "file assente/vuoto" = default legittimo (già così, `:149-152`) da "decode fallito" = errore da PROPAGARE al chiamante (o gestire con backup/migrazione), invece di ingoiarlo. Fronte separato con gate pieno.
- **Famiglia (swallow→wipe):** faccia READ (decode ingoiato). Cugine: v30 `TD-backtracks-load-riscrive-vuoto` (`:413`, read-failure riscrive `[]`) + `TD-persist-silent-fail` (§1.3, il `save()` WRITE ingoiato).
- **Priorità:** 🟠 MEDIA (sopra `TD-rt-vector-beatevent` 🟡): impatto = perdita del catalogo utente; non bloccante palco nell'uso normale. **Dominio:** CC.

## 📦 1.3 — Backlog (🟡 OPEN BASSA)

### Ripresa da interruzione (telefonata) riparte da capo — single-device (🟡 OPEN BASSA / da tracciare)
- **Sintomo (device Mauro 19/06):** in standalone, durante il Play arriva una **telefonata** (interruzione audio / app in background); al rientro la **setlist riparte da capo** (Song 1 / sezione 0) invece di riprendere dal punto in cui era. Osservato a margine del Test 3b di Bug 1 (gli accenti custom sopravvivono = quello è il PASS di Bug 1; questo è altro).
- **Attribuzione (ipotesi in POLE, NON verdetto):** buco di **ripresa del ciclo di vita single-device** → **ScenePhase, L3** (in Q-BEATS i callback `UIApplicationDelegate` sono codice morto; ScenePhase è l'unica fonte). Sink condiviso col reset di `startSetlist` (0/0), ma il **percorso esatto è da tracciare in codice** nel turno dedicato.
- **NON è il limite del Test 1 / setlist-gate:** quello = Link che non trasporta la posizione scaletta (**cross-device, L2**). Questo è **single-device, nessun peer, nessun Link** → **fronti separati, NON fondere.** Stesso sintomo (riparte da capo), causa diversa.
- **Priorità/blocco:** **non bloccante** (mitigato sul palco da DND + Accesso Guidato). **Sotto TD#17:** loggato ora, indagine nel suo turno **dopo** TD#17 — non prima.
- **Nota baseline 15/07 (device, single-device, Link attivo):** al resume da chiamata reale il click ha **mantenuto la posizione** (`INTERRUPTION ended resumeBeat:63`, riaggancio in fase) — **NON è ripartito da capo**. Distinto dal sintomo 19/06: quello richiede probabilmente il background prolungato, non la semplice interruzione breve col clock Link in moto. Verbale → changelog v36.
- **Dominio:** CC.

### TD-editor-authoring-polish — 3 micro-attriti editor Q-Stage (🟡 OPEN BASSA / 2 CC CHIUSE device + 1 CD + 1 debito)
- **Add Section non entra in automatico:** `SongEditorView.swift:53-59` appende `SongSection.makeDefault()` e non naviga → secondo tap necessario. Cura = push automatico (nav iOS 16). **🟢 CHIUSO — commit `5839e4f` (`.navigationDestination(isPresented:)`), device-confermato (collaudo `b1c50ab`, Mauro 30/06).**
- **Default "Sezione" (IT) + non si svuota:** `SongSection.swift:59` `name: "Sezione"` → cura `name: ""` (placeholder `"Section name"` già in `SectionEditorView.swift:35`). **🟢 CHIUSO — commit `5839e4f`; gate §7 nome-vuoto PULITO (save id-based, nessun assert/id-da-nome), device-confermato (collaudo `b1c50ab`).**
- **"Reorder" testo non simbolo + nessuna affordance:** l'header Sections mostra la PAROLA "Reorder"/"Done" (toggle `editMode`, `SongEditorView.swift:67`; idem catalogo Songs `SongListView.swift:57`); le maniglie ≡ compaiono SOLO dopo il tap → **prova dal vivo (collaudo `b1c50ab`, Mauro): l'utente non capisce che le sezioni si spostano.** Decisione CD = **drag diretto (Opzione C, no toggle)** (handoff 29/06); `.onMove` già presente (`SongEditorView.swift:52`, `SongListView.swift:123`). **CD→CC, va col mockup CD.**
- **Auto-enter binding per-indice (debito, da `5839e4f`):** `.navigationDestination(isPresented:)` apre `$draft.sections[draft.sections.indices.last]` (per-INDICE). Sicuro oggi per invariante append-adiacente (`append` immediatamente prima di `pushNewSection = true` → `.last` = la sezione nuova). **Da spostare a binding per-ID** se l'editor sezioni evolve (append multipli / riordino concorrente / eliminazioni durante il push). Annotato in-code (`5839e4f`). Dominio CC.
- **Dominio:** CC + CD (drag). **Stato:** 🟡 OPEN BASSA — i **2 item CC CHIUSI device** (`5839e4f`); restano Reorder (CD, drag Opzione C) + debito binding per-indice.

### TD-editor-bpm-spacing — numero BPM troppo vicino ai +/-, il dito copre il valore (🟡 OPEN BASSA / polish layout editor)
- **Sintomo (device, collaudo `51dabab` 30/06, Mauro):** nell'editor sezione il numero BPM è troppo vicino alla pulsantiera +/−; premendo **"−"** il dito **copre fisicamente il numero** che scende → non si vede il valore calare.
- **Causa:** layout `nameTempo` (`SectionEditorView.swift`) — `HStack { Text("BPM"); Spacer(); TextField(bpm); Stepper(+/-) }`: numero e `Stepper` **adiacenti**, nessuno spazio fra i due.
- **Cura (UX/DS → CD):** distanziare numero e +/− (gap fisso fra `TextField` e `Stepper`, o numero più a sinistra) così il dito sul "−" non copre il valore. Misura/posizione = Design System (CD); applicazione = CC.
- **Dominio:** CD (spacing/DS) + CC. **Stato:** 🟡 OPEN BASSA.

### TD-live-pulsantiera-EN — residui bilingui pulsantiera Live (🟡 OPEN BASSA)
- **"prev sez / next sez" (IT):** `TransportView.swift:26,66` → uniformare EN. Lane label = CD (Brief Fronte 2.8).
- **Label ruoli EN:** Director/Follower/Standalone (oggi `direttore` IT interno + EN a video `LiveView.swift:66`/`SettingsView.swift:34`). Va col rename `collaborativa→Follower` (§1.4).
- **Dominio:** CD (label) + CC. **Stato:** 🟡 OPEN BASSA.

### Doppio-click Direttore al confine di sezione (pre-esistente, NON FIX-B)
- **Sintomo:** sul canale Direttore, al cambio di metro, click **sdoppiato** (2 attacchi ripidi, gap **13–18 ms**, 2° lobo 0,5–0,9 del primo). Udibile come leggera distorsione; **non bloccante** (il beat esce in posizione).
- **Pre-esistente, NON introdotto da FIX-B:** stessa firma già in **α-TEST3 (8/06, `63fc3d2`)**; assente nelle baseline 470/472. Correla 4/4 con le build che toccano il DSP del mark (α + FIX-B); **solo a 120 BPM** nei dataset (mai a 121 — ma 121 testato solo su FIX-B). Escluse eco (attacco ripido ≤0,75 ms) e crosstalk (rientro canali 2,7%; offset Dir↔Fol −9 ms).
- **Causa NON inchiodata:** famiglia race `==`-fire / kickScheduling al confine (`BUGS:116-124` / PIVOT-5), sensibile a spb intero. Contraddizione aperta: i callsite provano che FIX-B **non gira** sul Direttore al confine (`setBeatPositionTimeOnly` solo ramo sync `AudioEngine.swift:2260` = Follower; meter-swap `MetronomeDSP.cpp:365-367` intatto da FIX-B), eppure i doppi correlano con le build DSP-modificate.
- **Arbitro = log iPad** (mai catturato). Test decisivo: A/B **TEST7-vs-472 stessa sessione** + log iPad (1 emissione L1 + 2 click WAV = doppio-render pre-esistente; 2 emissioni = doppio-fuoco DSP).
- **Stato:** 🟡 OPEN BASSA. Dominio CC.

### WAITING FOR DIRECTOR entra al Play con Ableton Link OFF — CONFERMATO repro device 06/07 (🟡 OPEN BASSA / flusso — fix in CD-7)
- **Sintomo (repro device Mauro 06/07):** in modalità `.collaborativa`/Follower, tap Play → entra in **WAITING FOR DIRECTOR anche con Ableton Link SPENTO** (blocca lo Stop→Play nei test: rientra in START LOCAL / attesa). Portando la modalità a `.direttore` (menu Ableton) **+ Link OFF** → **Play/Stop liberi**, nessuna videata di attesa. Non è un caso limite: è il default (l'app parte `.collaborativa`, `cb92faa`). Il badge FOLLOWER sparisce correttamente (NON è il problema).
- **Causa CONFERMATA a source (06/07, verbatim `TransportView.swift:36-63`):** il gate del trigger è `else if audioEngine.currentLinkMode == .collaborativa { … session.playbackState = .waitingForDirector }` (`:38`/`:58`) — condizionato sul **LinkMode PERSISTITO**, **NON** su Link-attivo (`ABLLinkIsEnabled`) né su `linkIsConnected` (commento `:48-51` esplicito: «SENZA `&& !linkIsConnected`»). Superata l'ipotesi «da confermare al codice» della versione candidato: gate = `currentLinkMode`, confermato a source + device.
- **Stato:** 🟡 **CONFERMATO con repro-device (06/07)** — perimetro ri-tagliato 12/06 dal ridisegno modalità (§1.4): il lato tecnico (trigger gated su `currentLinkMode` invece che su Link-attivo) è **assorbito dal fix CD-7** (default Standalone + opt-in ruoli, ratificato DIREZIONE 12/06 NON implementato → è la causa di questo bug). Non un fix isolato.
- **Note:** la domanda UX "Link off / no peer = modalità normale" è **RISOLTA 12/06** (sì → standalone; direzione ratificata Mauro, libro mastro Sez. 2 — non più da girare a CD). Il riferimento al default `.collaborativa` "fail-safe corretto" è superseded (default → Standalone, ridisegno 12/06). **CD-Q2=B: regola invariata («il Follower aspetta il Direttore»), ambito ristretto dall'opt-in (vale solo col ruolo Follower assegnato a mano, non più di default) — non riaperta.**
- **Dominio:** CC (gate del trigger) + CD (UX).
- **Osservazione 17/07 (Mauro, device) — DIVERGE dal repro documentato:** scelto ruolo **Director** dal menu Ableton, poi **Link spento**, poi Q-Live > metronomo > Play → **entra comunque in WAITING FOR DIRECTOR**. Il repro 06/07 sopra dichiara l'opposto (`.direttore` + Link OFF → Play libero). Passi esatti non ri-verificati a fonte: possibile **(i)** il ruolo non persiste allo spegnimento del Link (= l'automatismo Standalone-al-Link-OFF non esiste in codice, cfr. §1.4 / ratifica 01/07), oppure **(ii)** il repro 06/07 a sua volta invecchiato. **Registrato come osservazione, NON come conclusione.** Da sciogliere in CD-7.

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

### Fase 5 — B7 metronomo adattivo: scouting librerie BPM/tempo + direzione (📦, 26/06)
- **Obiettivo (direzione Mauro 26/06):** puntare al **vero adattivo** (griglia beat + confidenza, "traccia che respira"), non solo BPM fisso. È il **differenziatore** (Stage Traxx / ShowOne / AbleSet non ce l'hanno — vedi doc B7).
- **Architettura abilitante (riduce il rischio RT):** B7 analizza la base **all'import (offline)** → estrae **mappa-tempo + confidenza** → le **salva**; in riproduzione il click **segue la griglia pre-calcolata**. Quindi **NON è DSP real-time sul thread audio**: l'analisi gira all'import (qualche secondo = accettabile), non durante lo show.
- **Filtro:** C/C++/ObjC/Swift (compilabile iOS); licenza **permissiva (MIT/BSD/Apache) o LGPL**, **MAI GPL/AGPL** (trappola app commerciale chiusa) né "no-license"; on-device/offline; capacità beat-grid + confidenza; manutenzione. Ricerca GitHub diretta (`gh`) 26/06.
- **LEAD → `tillt/BeatIt`** (MIT · C++/ObjC++ · **CoreML** modello "Beat This!" + Accelerate · attivo, v0.3 / 408 commit): dà **BPM + griglia beat/downbeat + confidenza** = lista desideri B7. Caveat: oggi **macOS** → **da portare su iOS** (CoreML è iOS-compatibile; via solo-CoreML evita Torch ~200 MB).
- **RIFERIMENTO algoritmo → `mosynthkey/beat_this_cpp`** (MIT · transformer "Beat This!" SOTA · modello ~97 MB + ONNX): non pronto iOS / pesante → studio dell'approccio, non innesto.
- **FALLBACK leggero → `ryanfrancesconi/spfk-tempo`** (Swift Package · iOS 16+ · MIT · solo Apple Accelerate/AVFoundation · on-device · v1.0.3): dà **solo BPM globale** (modalità Fixed). Rete di sicurezza se il modello AI è troppo pesante per hardware vecchio.
- **DE-RISK prima di costruire (Fase 5):** prototipo BeatIt su iOS + verificare che il modello **CoreML giri on-device sull'iPad vecchio (A10)** in tempo/peso accettabili. Prova-prima-di-costruire.
- **DA EVITARE (qualità ok, licenza no):** `adamstark/BTrack` GPL-3 (422⭐, il più famoso), `teragonaudio/BeatCounter` GPL-2, `nathanstep55/bpm-offset-detector` GPL-3, `Tatsh/bpmdetect` GPL-3, `c4dm/beatroot-vamp` GPL-2; **aubio = GPL** (⚠️ correzione: era citato in watchlist per Fase 5, NON usabile commerciale); **Essentia = AGPL** (o licenza commerciale a pagamento).
- **INUTILIZZABILI (no-license = tutti i diritti riservati):** `Venetian/TempoTracker` (iOS), `yaizudamashii/BPMDetection-iOS`. **Alternative non-open:** SoundTouch (LGPL, solo BPM), Superpowered (SDK commerciale a pagamento).
- **Posizione CC:** direzione full-adaptive condivisa (differenziatore + fattibile via analisi-all'import). BeatIt = lead da de-riskare; beat_this_cpp = riferimento; spfk-tempo = rete di sicurezza. **Niente GPL.** Decisione finale Fase 5 col referee (vincoli on-device).
- **Stato:** 📦 scouting/direzione Fase 5 (nessun lavoro ora). **Dominio:** CC.

### TD-rt-vector-beatevent — allocazione heap nel render path (`vector<BeatEvent>` in `processBuffer`) (🟡 OPEN BASSA / rischio latente — PRE-ESISTENTE, non introdotto da A3)
- **Fatto tecnico (righe verificate a HEAD `4dfa2f8`):** `MetronomeDSP::processBuffer` — il render path, thread audio RT — costruisce un `std::vector<BeatEvent>` locale e lo ritorna per valore (`core_engine/MetronomeDSP.cpp:354`, costruzione `:364`) con `push_back` per ogni evento emesso (`:432`, `:477`) → allocazioni/riallocazioni heap dentro il render callback. La Costituzione §4 vieta malloc/free/new/delete in RT: è una violazione formale.
- **Attribuzione (esplicita):** PRE-ESISTENTE — architettura storica del bridge MetronomeDSP→AudioEngine. **A3 non l'ha introdotto e non l'ha toccato**: l'ha solo reso visibile leggendo §4 alla lettera durante il piano A3 (nota onesta agli atti, sprint 03/07). Il delta A3 in sé è RT-pulito (atomic + binary search su array preallocato). NON attribuire ad A3.
- **Impatto:** rischio LATENTE, NON osservato — l'app gira, il banco è 5/5 (48 verdi), nessun glitch attribuito a questo. Il vector è piccolo (pochi eventi per buffer) e in pratica l'allocatore tende a riusare; resta però un rischio di glitch sotto pressione di memoria / con buffer piccoli. Nessun claim «causa xrun»: non misurato (§7).
- **Fix possibile (solo annotato, NON in questo commit):** sostituire il vector di ritorno con un buffer pre-allocato a capacità fissa + count — il massimo di beat per buffer ha un tetto calcolabile (bpm max × buffer max) — stesso pattern del ring `_diagRing[kDiagRingCap]` già in `MetronomeDSP.h:208-209`. Fronte separato, gate RT pieno quando/se si affronta — decisione referee+Mauro.
- **Priorità:** 🟡 bassa / 📦 non bloccante palco. **Dominio:** CC.

### TD-backtracks-load-riscrive-vuoto — read-failure di `backtracks.json` → `save()` riscrive `[]` (finestra di perdita analisi) (🟡 OPEN BASSA / latente — introdotto da A5c-1, VIVO ad A5c-2, GRAVE all'analyzer)
- **Fatto tecnico (righe verificate a HEAD `ba271ca`):** `QBeatsStore.load()` (`ios_app/QBeats/Store/QBeatsStore.swift:19-48`) legge il terzo catalogo `backtracks.json` in un `do/catch` ISOLATO e NON-FATALE (`:34-41`): su **errore del coordinator** (I/O transiente — NON il decode, che è già ingoiato dallo stesso `coordinatedRead`, vedi `TD-store-decode-swallow` §1.2) il `catch` (`:39-41`) lascia `backtracks = []` in RAM (`:34`). Il successivo `save()` (`:50-60`) riscrive `backtracks.json` con lo snapshot vuoto (`backtracksSnapshot` `:53`, terza `coordinatedWrite`) → un catalogo backtracks già presente su disco verrebbe **sovrascritto con `[]`**. `save()` è innescato da QUALUNQUE CRUD (`try? await save()`, es. `addSong`/`upsertBacktrack`).
- **Attribuzione (esplicita):** introdotto da **A5c-1 (`ba271ca`)** come effetto collaterale del rimedio **m3** (piano A5c v2). La lettura isolata è **CORRETTA e VOLUTA**: l'alternativa (lettura fatale) abortirebbe l'intero `load()` lasciando `songs=[]` in RAM → il primo `save()` = wipe permanente del **catalogo canzoni**, molto peggio. m3 sceglie il male minore (al più delle analisi RI-generabili invece del catalogo utente). Questo TD è la **finestra residua** del trade-off, NON un difetto di m3.
- **Impatto / trigger (graduato):** oggi (post-A5c-1) **INNOCUO** — zero produttori, nessuna analisi vera su disco da perdere. Diventa **VIVO ad A5c-2** (il restore popolerà `backtracks.json` → esisterà un file da rileggere e potenzialmente sovrascrivere). **GRAVE all'atomo analyzer** (quando esisteranno `tempoMap` reali, costose da ricalcolare): un errore I/O transiente sulla lettura + una qualunque modifica successiva = analisi perse in silenzio. Perdita comunque RI-generabile (non irreversibile come il catalogo canzoni).
- **Fix possibile (solo annotato, NON in questo commit — scope ratificato referee):** NON un flag secco. Serve **safety del percorso load-failure + modifica-successiva**: quando la lettura di `backtracks.json` fallisce, marcare il catalogo "non-caricato" e **gate-are la terza `coordinatedWrite`** finché un `load()` pulito non riesce (il `save()` SALTA il write dei backtracks, non li azzera). Da chiudere **all'atomo analyzer** (quando il rischio diventa reale), gate pieno.
- **Famiglia (swallow→wipe):** faccia read-failure. Cugine: v29 `TD-store-decode-swallow` (`:264`, decode ingoiato) + `TD-persist-silent-fail` (§1.3, il `save()` WRITE ingoiato).
- **Priorità:** 🟡 bassa / 📦 non bloccante palco (oggi innocuo). **Dominio:** CC. **Condizione referee:** tracciato PRIMA di spedire A5c-2.

### TD-persist-silent-fail — `save()` fallito ingoiato da `try?` in tutte le CRUD (perdita dati silenziosa) (🟡 OPEN BASSA / pre-esistente — faccia WRITE della famiglia swallow→wipe)
- **Fatto tecnico (righe a HEAD `e141295`):** `save()` è `async throws` (`Store/QBeatsStore.swift:50`) ma ogni mutatore lo chiama con `try? await save()` — il `try?` **scarta** l'errore di `save()`/`coordinatedWrite`. 10 occorrenze: `addSong:68`·`updateSong:74`·`deleteSong:79`·`moveSongs:84`·`addSetlist:91`·`updateSetlist:97`·`deleteSetlist:102`·`moveSetlists:107`·`upsertBacktrack:123`·`deleteBacktrack:128`. `save()` scrive i 3 json insieme (`:57-59`): un throw perde **tutte** le modifiche pendenti (song/setlist/backtrack), in silenzio.
- **Sintomo (potenziale, non riprodotto su device):** la modifica aggiorna RAM+UI ("salvato") ma se `save()` fallisce (I/O, iCloud non disponibile, `replaceItem` fallito) il disco non riceve nulla → riapri = persa, senza avviso. Sull'iPad di test `save()` riesce → il device-test da solo NON lo cattura (il fallimento vive sul campo) → la voce BUGS è la copertura reale.
- **Famiglia (swallow→wipe):** faccia WRITE, cugina di v29 `TD-store-decode-swallow` (`:264`, READ che ingoia il decode) e v30 `TD-backtracks-load-riscrive-vuoto` (`:413`, read-failure che riscrive `[]`). Distinta da v30: lì il `save()` RIESCE e scrive male, qui il `save()` FALLISCE e non scrive affatto.
- **Fix possibile (solo annotato, NON in questo commit):** propagare l'errore a un handler visibile (avviso "salvataggio non riuscito" + retry) o logga-e-segnala invece del `try?` muto. Perimetro = tutte e 10 le CRUD. Fronte separato con gate.
- **Priorità:** 🟡 bassa / 📦 non bloccante palco. **Dominio:** CC.

### LIBRO-sez6-buco-v25-v26 — righe changelog v25/v26 mancanti in LIBRO_MASTRO Sez.6 (🟡 OPEN BASSA / doc-hygiene — pre-esistente)
- **Fatto:** `LIBRO_MASTRO_QBEATS.md` header a v26 (RATIFICATA 02/07) ma la tabella Sezione 6 «Storico versioni» si ferma a **v24** (28/06) → righe **v25/v26 assenti** (stessa categoria del backfill BUGS v11→v14 fatto in BUGS v15).
- **Perché non backfillato:** contenuto reale di v25/v26 non disponibile a memoria → ricostruirlo violerebbe verify-at-source (storia inventata). Debito **onesto**, tracciato qui perché un buco senza ticket = buco dimenticato.
- **Fix:** se si recupera il contenuto reale di v25/v26 (git log del libro mastro), backfill in un commit successivo — MAI a memoria.
- **Priorità:** 🟡 bassa / doc-hygiene. **Dominio:** CC (custode LIBRO).

### TD-backup-restore-no-ui — import/export in-app SOLO in DEBUG (harness `DebugView`); UI di PRODUZIONE assente; `.onOpenURL` device-confermato 17/07 (🟡 OPEN BASSA / feature-completion) ⚠️ RISCRITTO 17/07 (era STALE)
- **⚠️ RISCRITTO 17/07 (verificato a fonte a HEAD `152445e`):** la formulazione precedente («NESSUN pulsante Import né Export raggiungibile dall'utente», reperto 05/07 a HEAD `1008d48`, conservato sotto) è **falsa a HEAD attuale**. Scoperta il 17/07 da riscontro device di Mauro («nel Debug import/export ci sono»). Realtà corrente:
- **Harness di TEST (DEBUG):** `DebugView.swift` monta due bottoni reali — `SwiftUI.Section("Backup / Restore (.qbeats · TEST)")` `:109`, «Export backup (.qbeats)» `:110` (→ `doDebugExport()` `:50` → `QBeatsBackupManager.export` **diretto** → share sheet), «Import backup (.qbeats)» `:117` (→ `showImporter=true` → `.fileImporter` `:487` → `handleImporterResult` `:78` → `ImportView` `:495`). Introdotto `9b6ba10` (05/07/2026 19:40), rifinito `fcf9260` (06/07/2026). **`#if DEBUG`** → **assente dalla build di produzione**.
- **`BackupView` resta ORFANA:** l'harness DEBUG **NON la usa** (chiama `QBeatsBackupManager.export` e `ImportView` direttamente); grep `BackupView` su `ios_app` = 3 occorrenze, tutte nel proprio file, **ZERO call-site** (invariato, ri-verificato 17/07).
- **Import passivo `.onOpenURL` — device-confermato 17/07:** `QBeatsApp.swift:26-28`/`:31` → `parse` → `ImportView` in `.sheet`, **funzionante su device** al **gate B del Nodo A** (Mauro, 17/07): `.qbeats` aperto da app File con Q-Live a schermo → sheet **sopra** Q-Live; le 2 song di test poi ritrovate in Q-Stage›Songs = import andato a fondo.
- **RESTA APERTO (riformulato):** manca l'ingresso import/export nella UI di **PRODUZIONE** (l'harness è solo `#if DEBUG`). Il **fix annotato** (sotto) e la **priorità** sono invariati.
- **Nota di processo:** il ticket è nato il **05/07** (changelog #31) poche ore **PRIMA** del fix (`9b6ba10`, 05/07 19:40) e non è stato aggiornato → una falsità è rimasta in un canonico per **12 giorni**, scoperta il 17/07 solo da riscontro device di Mauro. Promemoria: un ticket che afferma «NESSUN X» va ri-verificato a fonte quando si tocca quell'area.
- **[Reperto 05/07, superseded dal blocco sopra] Fatto tecnico (verificato a HEAD `1008d48`):** **NESSUN pulsante Import né Export raggiungibile dall'utente.** (a) **IMPORT solo PASSIVO:** unico ingresso `QBeatsApp.swift:31` `.onOpenURL { guard url.pathExtension.lowercased() == "qbeats" }` → `QBeatsBackupManager.parse(url)` → `ImportView` in `.sheet` (`:26-30`); nessun `fileImporter`/`UIDocumentPickerViewController` in-app. (b) **EXPORT ORFANO:** `BackupView` (schermata "Export backup", share sheet a `BackupView.swift:108` → `UIActivityViewController`) esiste ma **non è presentata da nessuna schermata** — grep `BackupView` su tutto `ios_app` = **3 occorrenze, TUTTE dentro `BackupView.swift`, ZERO call-site**; nessun bottone la monta (verificato: assente da `SettingsView`/`ContentView`/`DebugView`). Il tipo `.qbeats` È REGISTRATO (`project.yml:48-61`: `CFBundleDocumentTypes` `LSHandlerRank: Owner`, `LSItemContentTypes com.bullfrog.qbeats.backup` + `UTExportedTypeDeclarations` conforms `public.zip-archive`, `public.filename-extension: qbeats`).
- **Limite d'uso (device-confermato Mauro 05/07 «non trovo i pulsanti»):** l'utente **non può esportare** un backup (schermata mai montata) e **non può importarlo** con un bottone; l'unico restore possibile è **aprire un `.qbeats` esistente da fuori** (app "File"/allegato/AirDrop) → "Apri con QBeats". Su device il cui proprietario è su Windows (niente AirDrop), far entrare il file richiede iCloud Drive / email-a-sé / gestore-file = attrito.
- **Attribuzione:** PRE-ESISTENTE — probabile ingresso perso nel ridisegno Bivio/Q-Stage (stessa classe di `SettingsView` demansionata a `#if DEBUG`, §1.2). **NON introdotto da A5c-2** (che tocca il merge/restore a valle di `parse`, non gli ingressi). **NON è un bug di A5c-2.** Fuori scope A5c.
- **Impatto sul gate device di A5c-2 (⚠️ correzione 05/07):** poiché l'export è irraggiungibile, la **prova (ii) export→reimport NON è eseguibile** sul device (rettifica onesta: proposta come "self-contained" assumendo `BackupView` raggiungibile — call-site NON verificato allora). L'**unico** restore cablato = import via `.onOpenURL` ⇒ gate device effettivo = **importare il fixture `.qbeats` sintetico** (aperto da "File"): prova `parse` + import **append non-distruttivo** (CIRCUZ+Alone intatte) + backtracks `?? []` + no-crash. La riga `:219` (metronomeMode su duplicate) e il merge di backtracks reali **non sono esercitabili sul device oggi** (servirebbe l'export, o conoscere gli id reali per la collisione) → restano coperti da CI (24 test) + FS5, chiudibili end-to-end quando esisterà un ingresso backup/restore.
- **Fix possibile (solo annotato, NON in questo commit):** cablare gli ingressi — bottone "Esporta backup" che monta `BackupView` + bottone "Importa backup" con `.fileImporter` (UTType `com.bullfrog.qbeats.backup`) → stesso `parse`→`ImportView`; in una schermata Backup/Settings raggiungibile anche in Release (coordinare col fronte ⚙ Settings / `SettingsView`-latente §1.2). Fronte UX (CD per la collocazione) + nota INFORMATION nel frattempo ("per ripristinare, apri il `.qbeats` da File"). Gate device.
- **Priorità:** 🟡 bassa / 📦 backlog. **Dominio:** CC (+ CD per gli ingressi UI).

### TD-emptystatekit-theme-dep — token condivisi di `EmptyStateKit` dipendono da `QStageKit` (🔵 COSMETICO / struttura — PRE-ESISTENTE, non introdotto da S2d)
- **Fatto tecnico (a HEAD `ab6b553`):** `EmptyStateLayout` (`UI/Components/EmptyStateKit.swift`, `.foregroundColor(QStageTheme.text3)`) usa un token di `QStageKit` — il tema della stanza Q-Stage. Un componente in `UI/Components/`, per natura condiviso Q-Stage/Q-Live (Q13 «No shows yet» di Q-Stage lo riusa), dipende così dal tema di UNA stanza. Compila (stesso modulo Swift), ma è un odore: un "condiviso" legato a una stanza specifica.
- **Attribuzione:** PRE-ESISTENTE — il colore era già `QStageTheme.text3` in `QLiveEmptyStates.swift` PRIMA dell'estrazione (verificato a fonte: `git show 7550476:…QLiveEmptyStates.swift:67`, dentro `EmptyStateLayout`). S2d (move puro, `ab6b553`) ha solo RILOCATO la dipendenza, NON l'ha introdotta. `QLiveEmptyStates` continua a usare lo stesso token nella subview Ⓔ.
- **Fix possibile (solo annotato, NON in questo commit):** un `CoreTheme` neutro che ospiti i token realmente condivisi (`text3` ecc.), da cui attingano sia `QStageKit` sia i componenti di `EmptyStateKit` — così `UI/Components/` non dipende più da un tema di stanza. Valutazione a sé, fuori perimetro S2d.
- **Priorità:** 🔵 cosmetico/struttura, non schedulato. **Dominio:** CC.

## 1.4 — Backlog UX puro (📦, dominio CD)

Riferimento `LIBRO_MASTRO_QBEATS.md` Sezione 3 deliverable per il dettaglio:
- **CD-1 esteso** (zona swipe orizzontale + indicatore `<< X / Y >>`) — proposto, in attesa di implementazione
- **CD-2** (perimetro rosso sfumato pulsante overlay standby) — proposto
- **CD-3** (bottone "Restart Setlist" a fine setlist) — proposto
- **Issue A — Titolo header troncato su iPhone** — il titolo canzone si tronca su iPhone. Proposta Mauro: spostare BPM + time signature sulla riga del bar counter per liberare spazio al titolo. Emersa 29/05.

- **END SHOW prematuro allo stop manuale del Direttore (→ CD-Q5 libro mastro)** — se il Direttore stoppa vicino a fine canzone, il Follower fa 1 beat extra (latenza Link) e, se quel beat chiude l'ultima sezione, scatta su END SHOW (`SetlistRunner.swift:354-361`); provato WAV TEST7 RUN3/4 (RUN6 = nessun extra). **NON è un guasto** (fisica della rete). Domanda design CD: allo stop manuale nell'ultima battuta, END SHOW o stop semplice? Emersa 11/06.

- **Modalità collaborativa — ridisegno avvio (DIREZIONE RATIFICATA Mauro 12/06 → libro mastro Sez. 1/2/3/4)** — assorbe il sintomo segnalato da Mauro 12/06 (iPhone Follower con iPad spento / zero peer → tap Play entra sempre in WAITING FOR DIRECTOR, `TransportView.swift:38-58` — comportamento voluto CD-Q2=B che non copriva il caso zero-peer, aggravato dal default `.collaborativa` `cb92faa`; via d'uscita START LOCAL già esistente → percorso di default sbagliato, non blocco). Direzione: l'app parte **sempre Standalone**; il collaborativo è **opt-in**, con ruoli **Standalone / Direttore / Follower** assegnati a mano dalla band per device. Cambiano il **default di avvio** (`.collaborativa` → Standalone) e il flusso di opt-in. **CD-Q2=B: regola invariata («il Follower aspetta il Direttore»), ambito ristretto dall'opt-in (vale solo col ruolo Follower assegnato a mano, non più di default) — non riaperta.** Scenari senza Direttore (tutto solo con Link attivo; senza peer → standalone): **(i) senza scaletta** = metronomo libero stile Ableton (Link nativo, ruoli opzionali, parte il primo e gli altri seguono); **(ii) con scaletta** = Direttore obbligatorio → popup "nessun Direttore assegnato". **Verifiche di fattibilità (CC — da investigare in codice, NON ancora fatte):** (a) scenario 1: verificare se oggi l'app obbliga la scelta Direttore/Follower anche senza scaletta; se sì, sganciare l'obbligo nel caso puro-Link; (b) scenario 2: Link trasporta solo tempo/avvio, NON i ruoli → nel breve il rilevamento "nessun Direttore" richiede un **timeout** (rischio "Direttore lento a premere Play", da tarare); il rilevamento immediato dei ruoli aspetta il canale proprietario QB↔QB (= **Soluzione C**, backlog Fase 6-7; NB: il TD#44 — entitlement multicast — era un prerequisito di rete già CHIUSO 23/05 `be2f035`, cosa distinta dal protocollo). Via da scegliere; (c) modello modalità: l'enum `LinkMode` oggi è a 2 valori (`.direttore`/`.collaborativa`, `AppSettings.swift`) → tre scelte flat implicano un refactor (definire "Standalone": Link off vs Link on senza ruolo). **Domande di disegno residue → CD-Q6** (libro mastro Sez. 4); deliverable disegno = **CD-7** (Sez. 3). Emersa 12/06. Dominio: CD (disegno) + CC (fattibilità). Nessun fix finché CD-7 non è ratificato — verde solo dopo device.
- **AGG 28/06 (collaudo `59ab33e`):** default `.collaborativa` confermato device = causa del WAITING FOR DIRECTOR nel flusso Q-Live libero (`TransportView.swift:38-58` senza check peer; `AppSettings.swift:20` + `AudioEngine.swift:55`/`:280`; `.standalone` NON è un case, solo log `:994`). **Mauro ratifica: uniformare `collaborativa`→"FOLLOWER"** (nome interno + UI; oggi incoerente `LiveView.swift:66`="FOLLOWER" vs `SettingsView.swift:34`="Collaborative"). Scenario (i) "senza scaletta = metronomo libero" prende faccia UI nel pulsante A/B d'ingresso Q-Live (memoria `project_qbeats_metronomo_libero`). Refactor `LinkMode`→3 stati = motore Link, fronte SERIO (referee+device), NON polish.

Questi NON sono bug ma deliverable UX. Listati qui per completezza visiva del backlog ma il primario è `LIBRO_MASTRO_QBEATS.md` Sezione 3.

---

# Sezione 2 — Bug CHIUSI (storico, non si cancellano)

Per data di chiusura, decrescente.

## 🟢 Luglio 2026

### TD-ipad-editor-fontsize — editor Q-Stage con testo non scalato su iPad — 🟢 CHIUSO 01/07/2026
- **🟢 CHIUSO 01/07/2026 (device-confermato, Mauro «ok tutto bene»):** su HEAD `11e5017`, editor canzone/sezione **scalati su iPad** + **tipografia DS uniforme** — 4 header sezione uniformi (JBMono 10 UPPER) + Repeat&Feel coerente iPhone/iPad. *(Il device ha confermato scaling + tipografia = il bug vero; per il glifo Subdivision vedi PIN ②.)*
- **Implementazione (7 atomi single-purpose, autore Mauro, zero Co-Auth, CI verdi, sopra `3b43627`):** `sf = geo.size.width/390` propagato all'editor via `GeometryReader` (full-mirror Songs-list) — `d7bdc81` (`SectionEditorView`) + `d650ccd` (`SongEditorView`); tipografia DS SF-Pro→JetBrains Mono ×sf, gerarchia neighbor-sourced — `99cc0ce` + `4ba7f42` (Round-2); 4 header sezione uniformi JBMono 10 UPPER + Repeat&Feel convertito — `033f192` + `47906cd`; Subdivision `1×`→`×N` — `11e5017`. `@ScaledMetric`/`preferredFont`/`sizeCategory` non usati (`feedback_qbeats_scaling_responsive`); `accentPattern` non toccato. L3 puro.
- **② Subdivision (PIN, non-derivabile):** display Subdivision = **`×N`** (moltiplicatore, `SectionEditorView.swift:165 Text("×\(section.subdivisionMultiplier)")`). **Àncora primaria = coerenza codice, verificabile a HEAD:** Repeat (`:154`), Subdivision (`:165`) e hint Swing `(×2)` (`:185`) sono **tutti `×N`** → `×N` è coerente, `N×` sarebbe l'anomalia. Scelta **ratificata da Mauro 01/07** (uniformità display, override reco CC+referee). Il **glifo `×N` specifico non è ri-testato a sé sul device** (cambio 1-char di display, zero impatto sullo scaling — immateriale). **NON `N×`.** Eventuale ripensamento notazione = nota-lane CD; `×N` resta baseline.
- **Dominio:** CC. CI verdi (4 run, push a coppie): `28504107176` (`d650ccd`) · `28528804273` (`4ba7f42`) · `28532044151` (`47906cd`) · `28532925786` (`11e5017`).

## 🟢 Giugno 2026

### TD-editor-bpm-typeable — BPM digitabile nell'editor sezione — 🟢 CHIUSO 30/06/2026
- **🟢 CHIUSO 30/06/2026 (device-confermato, check a 5 stati, Mauro):** campo BPM scrivibile + +/− attivi insieme. 5/5 verdi: scrittura sola (+revert su vuoto/"0"/"99999"; numberPad blocca le lettere), +/− soli (video+modello, **hold-to-repeat confermato**), combinazione digito 120→+1→121, combinazione sporca (cancello→+1→riparte dal valido, no crash), Test 3/delta on-exit.
- **Implementazione (3 commit):** `9d047e0` `TextField` digitabile (commit a focus-loss/Done, revert su sporco, range campo `20...400`, write model-only) + `commitBPM()`-on-exit (`SectionEditorView.swift:29`/`:32`); `726246f` decouple +/− (campo e `Stepper` separati — risolve i +/− inerti col campo in focus); `51dabab` `Stepper(onIncrement:onDecrement:)` commit-first + ri-clamp + refresh display (fix combinazione "digito poi +/−"). L3 puro, motore mai toccato.
- **Strascico aperto (ticket a parte):** `TD-editor-bpm-spacing` (§1.3) — numero coperto dal dito sul "−".
- **Dominio:** CC. CI verdi `28433118641` (`9d047e0`) + `28438450967` (`726246f`) + `28463889740` (`51dabab`).

### TD-ipad-home — overflow portrait + landscape iPad — 🟢 CHIUSO 30/06/2026
- **🟢 CHIUSO 30/06/2026 (device-confermato, collaudo `b1c50ab`, Mauro):** "home va benissimo" + "non si gira resta bloccato in verticale".
- **Causa (i) overflow portrait:** altezze-card-fisse × `sf` saturavano lo spazio tra gli Spacer su iPad. **Fix = tetto scaleFactor solo-iPad**, commit `87d22a9` (`HomeRootView.swift`: `sf = .pad ? min(width/390, height*0.92/844) : width/390`; iPhone invariato; `0.92` = manopola di taratura a vista, lasciata com'è per decisione Mauro).
- **Causa (ii) landscape:** mancava `UISupportedInterfaceOrientations~ipad`. **Fix = portrait-only + full-screen**, commit `4b3e91d` (`project.yml`: `~ipad`=Portrait + `UIRequiresFullScreen`); plist verificato dentro l'IPA reale (`~ipad`=Portrait + `UIRequiresFullScreen` + UIAppFonts 10/10). LIBRO v24 ratifica "portrait-only".
- **Dominio:** CC. CI verdi `28368080139` (`87d22a9`) + `28368123438` (`4b3e91d`).

### Bug 2.b — Ferita A + Ferita B (sync runtime cross-device / accento ai cambi sezione)
- **🟢 CHIUSO 11/06/2026 — entrambe le ferite (perimetro = AUDIO + ingresso), device-validate + mergiato su master `ee0cbc0` (squash).**
- **⚠️ Carve-out perimetro (12/06, agg. 19/06):** la chiusura copre l'**audio** (accento ai cambi sezione) e l'**ingresso** (aggancio Follower). Delle facce **VISIVE/counter** dello stesso desync sezione/time-sig cross-device: la **faccia (i) striscia segmenti 3-vs-4 → 🟢 CHIUSA 19/06** (fix `dfe758d`); **resta aperta solo la faccia (ii) counter "bar 2 di N"** (CD-Q1=B) in **§1.2 — "Bug 2.b (faccia visiva/counter)"**; il fix audio non le toccava.
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
- **Validato device:** 31/05/2026 — orchestrazione validata (Follower entra su Slow 90, bar multi-canzone sincronizzati). **NB:** il conteggio segmenti del metronomo stantio all'ingresso di Slow 90 (mostra 3 invece di 4 per un attimo) è la **faccia visiva di Bug 2.b** (desync sezione/time-sig cross-device — vedi **§1.2 "Bug 2.b (faccia visiva/counter)"**: **faccia (i) striscia segmenti → 🟢 CHIUSA 19/06** (fix `dfe758d`); resta aperta solo la faccia (ii) counter "bar 2 di N" (CD-Q1=B); l'audio di Bug 2.b è chiuso, voce sopra), **non** questo bug.
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

### Beat read-only / primo beat bianco (collaudo 28/06) — NON è un bug
- **Segnalato (device):** gli accenti nell'editor sezione non si modificano, il 1° è bianco non verde.
- **Verificato non-bug:** in v1 gli accenti sono sola lettura by-design — lo dichiara la UI (`SectionEditorView.swift:64` "Accents are read-only in v1…"). Il 1° bianco = default `accentPattern: [1,0,0,0]` (`SongSection.swift:65`). Editing + accento downbeat arrivano col nodo encoding accenti (ratifica separata; cfr. §1.2 "Striscia segmenti" Scenario B). NON tracciare come bug.

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
| 8 | 2026-06-19 | CC chat principale 19/06 | Bug 1 faccia (i) striscia segmenti CHIUSA — device-validata Test 1/2a/2b/3a/3b/4a/4b via proxy restart; faccia accenti = stesso fix; faccia (ii) counter resta OPEN. Fix `dfe758d` FF su master; doc-commit `b5b7575` (chiusura §1.2 + sync Sez. 2) + `82aad52` (Scenario A/B + ticket 3b §1.3). Scenario A/B fronte separato (ratificato 18/06). Niente LIBRO_MASTRO. |
| 9 | 2026-06-19 | CC chat principale 19/06 | **TD#17 allineato** (§1.1, doc-only): aggiunto forense run overnight 15→16/06 (peer perso mutuo ~10 min, auto-riparato; firma RX-freeze) + reframe causa = **ipotesi lead** roam-Follower → re-join Link lento (n=1, «Direttore non emette» falsificata, cambio-sezione co-fattore) + verifica avversariale 16/06 (workflow 6 agenti: «buco lungo→peer cade» falsificato, 7/7 piste escluse, separatore cambio-sezione confuso con RX-freeze a n=1) + mitigazione-rete (router dedicato banda-singola 2.4, roam=0, ~9 h → catastrofe non riprodotta = **palliativo, NON fix**) + next step reale = differenziatore 8 roam (Strategia 1 log esistenti / Strategia 2 banco roaming 2-AP; VR2800 single-AP non riproduce). Sostituisce il vecchio next-step «cattura log sessione lunga» (già eseguito). TD#17 resta 🔴 OPEN / 🚨 bloccante. Nessun fix codice. |
| 10 | 2026-06-20 | CC chat principale 20/06 | **TD#17 — esito Strategia 1 (doc-only).** Ri-analisi log esistenti (iPhone 12M righe + iPad): verdetto **(B) NULL-su-differenziatore**. **n=1 blindato** (#8 @05:12 = stop manuale test, confermato Mauro; non guasto). Separatori tutti falsificati o coincidenza-compatibili (coppia minima #4 vs #6); cecità log dimostrata = prune peer a timeout fisso Link (drop di #4 a +5,78 s dal roam; n=1, solo #4; corroborato da sorgente discovery/PeerGateway.hpp: TTL 5 s + 1 s padding = prune effettivo ~6 s, indipendente dai nostri +5,78 s; #8 = stop test, NON secondo dato) + freeze RX beacon multicast sotto risoluzione log. **Reperto sorgente:** sync = solo Ableton Link, nessun socket app (canale privato = roadmap futura). Next-step → **Strategia 2 banco**. Hardware (verificato 20/06, fw AGZHP_1.4.4): **H388X provisioned controllabile = AP di test a costo zero** (band-steering/radio per-banda/canale/potenza TX %); **aperto solo lo sniffer multicast** (monitor-mode CH6/112); OpenWRT = piano B (roam morbido 802.11v). Spec A/B (2.4→5 marginale ≤2 s da cambio-sezione vs lontano, n≫1). Artefatto: `LOG/roam_evidence/TD17_STRATEGIA1_ANALISI_20260620.md`. TD#17 resta 🔴 OPEN / 🚨 BLOCCANTE. Nessun fix codice. |
| 11 | 2026-06-22 | CC chat principale 22/06 | **TD#17 — root cause circoscritta (sessione sniffer 22/06, doc-only).** Sniffer multicast validato (eth0 cablato + IGMP join `socat`; monitor-mode scartato): la perdita peer = **alcuni router non fanno transitare il multicast Link tra le due bande Wi-Fi** — **NON universale, H388X-specifico**; il **VR2800 è pulito** (cross-band stabile 10+ min, device-confermato Mauro). Meccanismo interno H388X = ipotesi non isolata (candidato IGMP snooping). **TD#17 declassato 🚨→🟠** (non più bloccante operativo, NON chiuso: restano caso roam reale VR2800 + run palco). Raccomandazione rete single-band. Commit `6f1a8d0`. Nessun fix codice. |
| 12 | 2026-06-22 | CC chat principale 22/06 | **TD#17 — nota «fenomeno B» declassata (doc-only).** Il desync visivo/uditivo osservato durante un roam era in un **test invalidato** (SSID misto BULLFROG/BULLFROG5 + peer instabile, scoperti dopo) → **NON un fenomeno stabilito**, NON un sotto-ticket; rimosso dai prossimi step (da riconfermare solo se ricompare in un test pulito). Commit `f5c6dea`. Nessun fix codice. |
| 13 | 2026-06-23 | CC chat principale 23/06 | **Nuovo ticket §1.2 `TD-link-indicator-stale` (doc-only).** Sul Direttore l'indicatore peer/LED resta «standalone»/spento mentre il peer È collegato (sync precisa; recovery = aprire/chiudere pannello Ableton o toggle Link) — device-confermato 23/06. Causa (codice + log iPad `td17_IPAD_20260623_124507`, percorso verbatim master `f5c6dea`): `linkIsConnected` (unica fonte LED/testo) aggiornato solo a fronti + un re-check one-shot +2s → con peer già presente all'enable nessun fronte 0→1 → indicatore stale; meccanismo LinkKit = ipotesi (closed-source). NON è TD#17. Fix proposto (NON applicato; lato Swift, no L2): lettura ricorrente dello stato vivo in entrambe le direzioni. 🟠 OPEN MEDIA. Commit `a458c8a`. Nessun fix codice. |
| 14 | 2026-06-23 | CC chat principale 23/06 | **TD#17 — qualifica «pulito» (doc-only).** Bullet SCOPING: «VR2800 pulito» = **cross-banda STATICO** (device fermi, 10+ min); comportamento sotto roam/perdita-banda = indagine separata (run 23/06 confondata da Smart Connect → NON chiude TD#17; re-test = caratterizzazione in coda, blocco palco già sciolto da single-band). Coerente con LIBRO_MASTRO v19. Commit `306097b`. Nessun fix codice. |
| 15 | 2026-06-23 | CC chat principale 23/06 | **Sweep changelog (doc-only, hygiene).** Backfill Sezione 5 delle righe mancanti **v11→v14** (il changelog si era fermato a v10 mentre l'header era avanzato — stessa categoria di divergenza header-vs-storia che stiamo chiudendo altrove). Bump header 14→15; snapshot/mirror allineati a **v15**. Nessun cambiamento ai ticket, nessun fix codice. |
| 16 | 2026-06-24 | CC chat principale 24/06 | LED `TD-link-indicator-stale` declassato 🟠 OPEN MEDIA → 🔵 COSMETICO-SOSPESO + causa-dal-log corretta (`BUGS:125-129`): etichetta "VERIFICATO" → "PARZIALMENTE SUPPORTATO / non confermata dal log", rimosso "seed-false/LED-spento 10 min" (resta solo il fatto stampato: zero `[CONNECTED]` ~10 min). Doc-only. Commit `af2e3bd`. |
| 17 | 2026-06-24 | CC chat principale 24/06 | Nuovo ticket §1.2 `TD-control-center-slide-audio` 🔵 COSMETICO/AMBIENTALE-SOSPESO (Strada B): click rallenta solo durante l'animazione slide Control Center, solo iPad A10 + setlist LONG, recupero pulito; causa verificata alla fonte (`AudioEngine.swift:263`/`:2613-14`, riarmo JIT su `audioQueue` non-RT, no render RT). Fronte prima NON in BUGS. Doc-only. Commit `7c35074`. |
| 18 | 2026-06-26 | CC chat principale 26/06 | Nuovo ticket §1.2 **MIDI azioni-contenuto non cablate a L3** (🟠 feature-completion, NON cosmetico, dietro TD#17): transport base wired; navigazione contenuto (Next/Prev Section, Next Song, Start Song=sblocco standby, Loop) = stub «richiede Layer 3» (`AudioEngine.swift:1608`). Thread-safety già OK (exec main `:1576`, I/O off-RT `:1464`); lavoro = handoff L2→L3 (no reference diretta engine→runner). Confermato alla fonte: `nextSection`/`prevSection` = equivalente UI mid-play (`TransportView:28`/`:68`) → mirror TAP; **`nextSong` mid-play = comportamento NUOVO** (nessun controllo UI oggi); `startSong` = mirror standby tap (`LiveView:131`). Decisioni-bandiere correlate in LIBRO v22. Bump header 17→18. Doc-only, nessun fix codice. |
| 19 | 2026-06-26 | CC chat principale 26/06 | Nuovo ticket §1.2 **Base audio non suona in Live da una Song** (🟠 feature-completion, cantiere Tracce): oggi `armBacktrack` chiamata solo da `DebugView:186`; nel flusso Live reale la base non è caricata/avviata da una Song → manca "un solo START → base + metronomo insieme". Non regressione = feature da costruire col cantiere Tracce. Emerso dal brief Media di CD, verificato alla fonte (26/06). Bump header 18→19. Doc-only, nessun fix codice. |
| 20 | 2026-06-26 | CC chat principale 26/06 | +nota §1.3 backlog **Fase 5 — B7 scouting librerie BPM + direzione** (ricerca GitHub via gh): direzione Mauro = puntare al **vero adattivo** (griglia+confidenza); architettura abilitante = analisi **all'import** (offline, no DSP real-time). **Lead `tillt/BeatIt`** (MIT/CoreML, da portare iOS); riferimento `mosynthkey/beat_this_cpp` (MIT/AI); fallback `ryanfrancesconi/spfk-tempo` (Swift/MIT/Accelerate, solo BPM). De-risk: provare modello CoreML on-device su iPad A10 prima di costruire. Evitare GPL (BTrack/aubio/BeatCounter…)/AGPL(Essentia)/no-license. Header bump 19→20. Doc-only, nessun fix codice. |
| 21 | 2026-06-28 | CC chat principale 28/06 | Due nuovi ticket §1.2 (doc-only): **Nodo A — Q-Live montata fuori dal NavigationStack** (modale UIKit `BivioBoardView.swift:34-41`; root = commutazione `AppRootView.swift:27-33`; engine non accoppiato al mount → sizing referee L3 plumbing; **gate device "parità firing stop modale .overFullScreen↔push"**, stop `LiveView.swift:187`+`BivioBoardView.swift:61`; gata solo il ponte Select Setlist→Live) + **SettingsView: unico ingresso dietro `#if DEBUG`** (gear `ContentView.swift:76-84` → `ContentView` solo in `.fullScreenCover($showDebug)` `BivioBoardView.swift:64-79`); IPA CI = Debug (`ios_build.yml:48,53`) → Settings raggiungibile **oggi**, ma una build **Release** compila via l'ingresso = gap **latente** pre-v1; accoppiata al fronte ⚙ Settings CD. Chiude il debito "gate Nodo A vive solo in memoria CC" (regola d'oro BUGS). Bump header 20→21. Doc-only, nessun fix codice. |
| 22 | 2026-06-28 | CC chat principale 28/06 | **Ticket collaudo device `59ab33e`.** NUOVI §1.2: TD-qlive-libero-limbo (limbo `LiveRootView:8` + waiting default `.collaborativa` `TransportView:38-58` + bottoni fine-show morti `FineSetlistView:19,21`; pre-esistente, raggiungibile dalla porta Home) + TD-ipad-home (overflow = altezze-card-fisse `115·sf×3` × sf saturano lo spazio fra Spacer `HomeRootView:24,26`; landscape = `~ipad` mancante; "portrait-only" NON al LIBRO→confermare). NUOVI §1.3: TD-editor-authoring-polish (Add Section auto-enter + `"Sezione"`→`""` `SongSection:59` + Reorder→simbolo) + TD-live-pulsantiera-EN (`TransportView:26,66`). AGG §1.4: collaudo conferma default `.collaborativa`=causa waiting, naming `collaborativa`→FOLLOWER ratificato Mauro, metronomo-libero A/B = faccia UI scenario (i). §3: beat read-only = non-bug (`SectionEditorView:64`). Citazioni blindate (13 agenti, 17/17 byte). Bump header 21→22. Doc-only, nessun fix codice. |
| 23 | 2026-06-29 | CC chat principale 29/06 | **§1.3 editor-polish committato + debito binding annotato.** TD-editor-authoring-polish: i 2 item CC → **FATTI, commit `5839e4f`** (Add Section auto-enter via `.navigationDestination(isPresented:)`; default `name: "Sezione"`→`""` `SongSection.swift:59`; gate §7 nome-vuoto PULITO — save id-based `QBeatsStore.swift:54`, nessun assert/id-da-nome; CI verde `28366276760`; **device-pending**). +bullet **debito binding auto-enter per-indice** (`$draft.sections[.last]`, sicuro per invariante append-adiacente, → per-ID se l'editor evolve; annotato in-code). Contesto (commit codice a sé, NON in questa riga doc): atomi iPad `TD-ipad-home` = scaleFactor cap `87d22a9` + blocco landscape `4b3e91d`; plist-IPA verificato (`~ipad`=Portrait + `UIRequiresFullScreen` + UIAppFonts 10/10); device-pending. Bump header 22→23. Doc-only, nessun fix codice. |
| 24 | 2026-06-30 | CC chat principale 30/06 | **Collaudo device `b1c50ab` — 3 fix CHIUSI + 4 riscontri.** I 3 commit device-confermati (Mauro 30/06): editor-polish `5839e4f` (Add Section auto-enter + default `""`) → §1.3 i 2 item CC 🟢; iPad-A `87d22a9` (scaleFactor cap) + iPad-B `4b3e91d` (portrait-only) → **TD-ipad-home 🟢 CHIUSO, spostato in Sez.2**. NUOVI §1.2: **TD-shows-authoring** (tab Shows = segnaposto `QStageRootView.swift:7`/`:22-27`, `QStageKit.swift:73`; modello unico `Setlist` `Models/Setlist.swift:3` + mount pulito no-Nodo-A; ≠ Shows-palco Q-Live; 🟠 CD+referee) + **TD-ipad-editor-fontsize** (editor non scala su iPad: misure letterali `SongEditorView.swift:28-29` vs `sf` Home/Songs; 🟠 CC). NUOVO §1.3: **TD-editor-bpm-typeable** (BPM solo +/- `SectionEditorView.swift:38`, manca input scrivibile; range campo `20...400`, motore NO clamp `MetronomeDSP.cpp:35-49`/`AudioEngine.swift:1091-1123`, tre range UI distinti incl. `ContentView.swift:29` 40...240 + `TapTempoEngine.swift:20-21` 40...250; 🟡 CC) + aggiornato bullet Reorder (prova dal vivo, drag Opzione C). Sourcing S1-S5 verificato avversarialmente (workflow 5 agenti: S1 corretto con `ContentView.swift:29`; S3/S4/S5 confermati). Bump header 23→24. Doc-only, nessun fix codice. |
| 25 | 2026-06-30 | CC chat principale 30/06 | **Nuovo ticket §1.2 `TD-editor-back-discard` (doc-only).** Freccia indietro editor canzone (`SongEditorView.swift:22` `onBack: { dismiss() }`) scarta il draft **senza avviso**; persiste solo SAVE (`save()` → `store.updateSong(draft)` `:95-98`, bottone `:25`). **Perimetro verificato (grep onBack):** `:22` = UNICO scarto-silenzioso (`SectionEditorView:29` committa-poi-dismiss; `SongListView:25`/`QStageKit:85` senza draft). 🟠 **PRE-ESISTENTE — NON regressione DIFF B `9d047e0`** (riga `:22` da `dd0fcaa` 27/06; `9d047e0` tocca solo `SectionEditorView`). Emerso dal collaudo `b1c50ab` (BPM 230→back→120). Cura UX → CD. Bump header 24→25. Doc-only, nessun fix codice. |
| 26 | 2026-06-30 | CC chat principale 30/06 | **`TD-editor-bpm-typeable` 🟢 CHIUSO (device 5/5) + nuovo ticket spacing.** Collaudo device `51dabab`: campo BPM scrivibile + +/− insieme, 5 stati verdi (scrittura · +/− soli con hold-to-repeat · combinazione 120→121 · sporco cancella→+1 · Test 3/delta). 3 commit codice: `9d047e0` (TextField digitabile + commit-on-exit `:29/:32`) + `726246f` (decouple +/−) + `51dabab` (`Stepper(onIncrement/onDecrement)` commit-first + ri-clamp). `TD-editor-bpm-typeable` → §2. NUOVO §1.3 **`TD-editor-bpm-spacing`** (numero BPM troppo vicino ai +/− → dito copre il valore sul "−"; layout `nameTempo`; cura UX/DS → CD+CC; 🟡). Bump header 25→26. Doc-only, nessun fix codice. |
| 27 | 2026-07-01 | CC chat principale 01/07 | **`TD-ipad-editor-fontsize` 🟢 CHIUSO (device 01/07, Mauro «ok tutto bene»).** Fix = 7 atomi Mauro/zero-Co-Auth/CI-verdi su HEAD `11e5017` (scaleFactor editor `d7bdc81`+`d650ccd` · tipografia DS JBMono `99cc0ce`+`4ba7f42` · 4 header uniformi + Repeat&Feel `033f192`+`47906cd` · Subdivision `1×`→`×N` `11e5017`). **② pinnata:** Subdivision = `×N` (àncora = coerenza codice `:154`/`:165`/`:185`; scelta Mauro 01/07; glifo non ri-testato a sé), NON `N×` — notazione a baseline, ripensamento = lane-CD. Bump header 26→27. Doc-only, nessun fix codice. |
| 28 | 2026-07-03 | CC chat principale 03/07 | **Nuovo ticket §1.3 `TD-rt-vector-beatevent` (doc-only).** Allocazione heap nel render path: `processBuffer` (thread RT) costruisce `std::vector<BeatEvent>` e fa `push_back` per evento (`MetronomeDSP.cpp:354`/`:364`/`:432`/`:477`, righe verificate a HEAD `4dfa2f8`) = violazione formale §4. **PRE-ESISTENTE (bridge storico MetronomeDSP→AudioEngine), NON introdotto né toccato da A3** — solo reso visibile dal piano A3 (nota onesta agli atti). Rischio latente, NON osservato (banco 48 verdi); fix annotato = buffer pre-allocato a capacità fissa + count (pattern `_diagRing`), fronte separato con gate RT pieno. Bump header 27→28. Doc-only, nessun fix codice. |
| 29 | 2026-07-03 | CC chat principale 03/07 | **Nuovo ticket §1.2 `TD-store-decode-swallow` (doc-only).** Errore di decode ingoiato in `QBeatsStore.coordinatedRead` (`Store/QBeatsStore.swift:163-165` a HEAD `b4d3596`, solo `logger.error` + default `[]` da `:22-27`) mentre l'errore del coordinator viene propagato (`throw :167-170`) — I/O propaga, decode no. Schema-break su songs/setlists = **catalogo vuoto silenzioso** = perdita dati per l'utente: percorso reale che si innesca a ogni cambio di formato non gestito (NON "latente non osservato"; rischio ALTO se innescato, oggi mai manifestato). A5 mitiga il caso "campo nuovo" (decodeIfPresent) ma NON il meccanismo. Fix annotato = propagare il decode-fail (o backup/migrazione), fronte separato. 🟠 MEDIA. Bump header 28→29. Doc-only, nessun fix codice. |
| 30 | 2026-07-05 | CC chat principale 04-05/07 | **Nuovo ticket §1.3 `TD-backtracks-load-riscrive-vuoto` (doc-only) — condizione referee pre-A5c-2.** Finestra di perdita analisi introdotta da A5c-1 (`ba271ca`): `QBeatsStore.load()` legge `backtracks.json` in do/catch isolato non-fatale (`:34-41`, rimedio m3 — evita il wipe di songs); su read-failure del coordinator `backtracks=[]` in RAM e il primo `save()` (`:50-60`) riscrive `backtracks.json` con `[]`. Oggi INNOCUO (zero produttori), VIVO ad A5c-2 (restore popola il file), GRAVE all'analyzer (analisi vere costose). Fix annotato = safety load-failure+modifica-successiva (gate del 3° write finché un load pulito non riesce), NON flag secco; all'atomo analyzer. m3 confermato corretto (male minore vs wipe catalogo). 🟡 bassa. Bump header 29→30. Doc-only, nessun fix codice. |
| 31 | 2026-07-05 | CC chat principale 05/07 | **Nuovo ticket §1.3 `TD-backup-restore-no-ui` (doc-only) — reperto emerso al gate device A5c-2.** NESSUN ingresso UI per import NÉ export: import solo `.onOpenURL` (`QBeatsApp.swift:31` → `parse` → `ImportView` `:26-30`); export ORFANO (`BackupView` mai montata — grep `BackupView`=3 occ. tutte nel file, ZERO call-site; assente da Settings/Content/Debug). Tipo `.qbeats` registrato (`project.yml:48-61`). PRE-ESISTENTE (probabile ingresso perso nel ridisegno Bivio/Q-Stage), NON introdotto da A5c-2, NON bug A5c-2. **Correzione gate device A5c-2:** la prova (ii) export→reimport NON è eseguibile (export irraggiungibile; call-site `BackupView` non verificato nella proposta iniziale) → gate effettivo = import del fixture `.qbeats` via `.onOpenURL` (append non-distruttivo + `?? []` + no-crash); `:219`+merge restano CI(24)/FS5, chiudibili end-to-end col futuro ingresso. Fix annotato = cablare bottoni Esporta (monta `BackupView`) + Importa (`.fileImporter`, UTType `com.bullfrog.qbeats.backup`). 🟡 bassa. Bump header 30→31. Doc-only, nessun fix codice. |
| 32 | 2026-07-06 | CC chat principale 06/07 | **Promozione §1.3 WAIT-DIRECTOR (doc-only) — da "candidato" a CONFERMATO-con-repro-device.** Causa confermata a source (verbatim `TransportView.swift:36-63`): gate `currentLinkMode == .collaborativa` (`:38`/`:58`), LinkMode PERSISTITO, NON Link-attivo (`ABLLinkIsEnabled`)/`linkIsConnected` (commento `:48-51`). Repro device Mauro 06/07: `.collaborativa`/Follower+Link OFF → WAIT DIRECTOR; `.direttore`+Link OFF → Play/Stop liberi. Fix = CD-7 (default Standalone, ratificato DIREZIONE 12/06 non implementato). 🟡 bassa. Bump header 31→32. Doc-only, nessun fix codice. |
| 33 | 2026-07-10 | Mauro + CC + referee | **Doc-commit ratifiche pivot SHOWS + famiglia swallow (doc-only).** Nuovo §1.3 `TD-persist-silent-fail` (faccia WRITE della famiglia swallow→wipe: `save()` `async throws` ingoiato da `try?` in 10 CRUD, `QBeatsStore.swift:50`+`:57-59`; 🟡 CC) + cross-ref reciproco alle cugine v29 `TD-store-decode-swallow` (`:264`) e v30 `TD-backtracks-load-riscrive-vuoto` (`:413`). Nuovo §1.3 `LIBRO-sez6-buco-v25-v26` (doc-hygiene: righe changelog v25/v26 mancanti in LIBRO Sez.6, tracciate come debito onesto, non backfillate a memoria; 🟡 CC). Accompagna il doc-commit LIBRO v27 (ratifiche HYBRID + §6 nav). Bump header 32→33. Doc-only, nessun fix codice. |
| 34 | 2026-07-11 | Mauro + CC | **Nuovo ticket §1.2 `TD-peer-reconnect-button` (doc-only) — pulsante di riaggancio manuale del peer in Q-Live.** Rete di sicurezza a valle di TD#17 (🟠 OPEN MEDIA dal 22/06, NON più 🚨): a peer Link perso il re-join automatico c'è ma è ~10 min (`BUGS:104`), mentre il ri-init manuale (uscire/rientrare dalla vista → «peer ri-formato all'istante», `BUGS:103`) è istantaneo → il bottone lo espone IN Q-Live senza far uscire il batterista. **Scopo preciso (device-confermato 11/06, `BUGS:103`):** durante il drop il tempo NON va fuori e il metronomo continua (−11 ms/16,6 s); il danno è SOLO FINALE (stop non propagato ~1,5 s = END SHOW) → il bottone ricuce PRIMA dello stop, si preme con calma sulla spia. Distinto dal recovery automatico e da una spia «peer perso» (fonti = memorie CC, NON BUGS/LIBRO, qualificate nel ticket). Idea Mauro, non negli atti → registrata. 🟠 OPEN MEDIA, CC+CD, da progettare. Non in LIBRO. Bump header 33→34. Doc-only, nessun fix codice. |
| 35 | 2026-07-12 | Mauro + CC + referee | **Nuovo §1.3 `TD-emptystatekit-theme-dep` (doc-only) — mini-TD 🔵 COSMETICO/struttura, PRE-ESISTENTE.** Emerso da S2d (estrazione `EmptyStateKit`, commit `ab6b553`): `EmptyStateLayout` (ora in `UI/Components/EmptyStateKit.swift`) usa `QStageTheme.text3` via QStageKit → un componente "condiviso" dipende dal tema di una stanza (Q-Stage). Compila (stesso modulo), ma è un odore architetturale. **NON introdotto dal move** — il colore era già `QStageTheme.text3` in `QLiveEmptyStates` prima di S2d (verificato a fonte `7550476:…:67`). Fix futuro: valutare un `CoreTheme` neutro per i token condivisi. 🔵 non schedulato, CC. Bump header 34→35. Doc-only, nessun fix codice. |
| 36 | 2026-07-15 | Mauro + CC + referee | **Verbale esiti device 15/07 (doc-only) — due registrazioni.** **(1)** `TD-qlive-libero-limbo` (§1.2) **RI-CONFERMATO device** (Mauro): flusso rivissuto integralmente (Q-Live senza setlist → Play → WAIT DIRECTOR → START LOCAL → END SHOW → kill+riavvio app); **conferma, non nuova diagnosi** — severità e causa a 3 pezzi invariate. **(2)** **Baseline Parte 2 (interruzioni audio) = PASS 3/3** (device Mauro, iPhone, log iMazing): **A** Control Center → nessuno stop, solo `scenePhase inactive/active`; **B** Notifica → ducking iOS, click continua; **C** Chiamata reale → `[INTERRUPTION] began→ended`, resume automatico su downbeat, click ripartito. **Criterio-bug** (click fermato SENZA riga `[INTERRUPTION]`) **non osservato in nessuno scenario**. **Limite:** vale sul montaggio attuale (Q-Live modale UIKit); da rifare sulla build post-NODO A. **Nota secondaria:** spia `<Error>` r.1361 `[Bug2b] WARN aggancio non su downbeat` (frazione −0.366) al resume-chiamata → auto-corretta dallo snap-to-bar (`AudioEngine.swift:787-795`, motore riparte su downbeat), **non-bloccante**, famiglia Bug2b/TD#39; combacia col riscontro d'orecchio di Mauro (primo colpo lievemente storto poi riallineato) = transitorio di resume, limite Apple (la chiamata sospende l'audio, inevitabile). Bump header 35→36. Doc-only, nessun fix codice. |
| 37 | 2026-07-15 | Mauro + CC + referee | **Fix coordinate stale (doc-hygiene) — 2 ticket, sostanza invariata.** `Nodo A` (§1.2, `BUGS:243-248`): nomi pre-rename `BivioBoardView`/`enum Screen{bivio,qStage}` → `HomeRootView`/`{home,qStage}` (righe verbatim aggiornate a source); framing "conversione present→push" (27/06) → allineato alla ratifica 10/07 (ritiro completo modale, Nodo A sciolto, LIBRO Sez.2). `TD-shows-authoring` (§1.2, `BUGS:266-270`): citazione `QStageRootView.swift:22-27 → QStagePlaceholderTab` per Shows era stale (oggi `:22` monta `ShowsListView` REALE, costruita S3 13-14/07; il placeholder resta solo per Media, `:26-31`) — corretta con le righe reali dell'authoring mancante (`ShowsListView.swift:42` niente `+`; `:213-214` niente tap/editing). Nessun cambio di severità, dominio o causa sostanziale in entrambi i ticket. Bump header 36→37. Doc-only, nessun fix codice. |
| 38 | 2026-07-17 | Mauro + CC + referee | **Verbale Nodo A + 2 ticket (doc-only).** **(1)** `TD-backup-restore-no-ui` **RISCRITTO** (era STALE): la formulazione «nessun ingresso import/export raggiungibile» è falsa a HEAD attuale — esiste un **harness di TEST in DEBUG** (`DebugView.swift` `:109/:110/:117`, `.fileImporter :487`→`handleImporterResult :78`→`ImportView :495`; `doDebugExport :50`→`QBeatsBackupManager.export` diretto; introdotto `9b6ba10` 05/07 19:40, rifinito `fcf9260` 06/07; **`#if DEBUG`**). `BackupView` resta ORFANA (0 call-site, l'harness non la usa). `.onOpenURL` (`QBeatsApp.swift:26-28`) device-confermato 17/07 al **gate B** del Nodo A. RESTA APERTO = manca l'ingresso in UI di **PRODUZIONE**; fix/priorità invariati. **Nota di processo:** ticket nato 05/07 poche ore PRIMA del fix, falsità rimasta in un canonico **12 giorni**, scoperta il 17/07 da riscontro device di Mauro. **(2)** `WAITING FOR DIRECTOR entra al Play con Link OFF` (§1.3): +1 osservazione 17/07 (Director dal menu Ableton + Link OFF → entra comunque in WAITING, DIVERGE dal repro 06/07) — registrata come OSSERVAZIONE non conclusione, da sciogliere in CD-7. Bump header 37→38. Doc-only, nessun fix codice. |

---

**Fine documento.**
