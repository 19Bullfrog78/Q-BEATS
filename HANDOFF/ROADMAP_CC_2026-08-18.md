# ROADMAP Q-BEATS — rientro dalla pausa, 18/08/2026

Scritta da CC su mandato di Mauro al rientro (pausa 07/08 → 18/08, undici giorni).
Stato **misurato a fonte** a HEAD `321293e18094d9d4f1c167bfc921be1ad216e3ac`, non ereditato da nessun documento.

Marcatura: **[M]** misurato in questa sessione · **[R]** riportato da altri e non rimisurato · **[I]** inferenza/giudizio di CC.

> ⚠️ Questo documento è una **proposta di ordine di lavoro**, non una ratifica. Nessuna riga qui dentro
> è ratificata finché non atterra in un canonico. Non è un canonico ombra: dove cita uno stato, cita
> anche l'indirizzo per riverificarlo.

---

## 0 · Il fatto che riordina tutto

**[M] A HEAD l'app non può far partire uno show.** Non è un guasto ed è uno stato deliberato, ma non
è mai stato scritto in questi termini in nessun documento, e cambia l'ordine di tutto il resto.

La catena, misurata su quattro anelli indipendenti:

| # | anello | indirizzo |
|---|---|---|
| 1 | `SetlistRunner` non viene **mai** costruito — zero siti in tutto il progetto | `grep -rn 'SetlistRunner(' ios_app/` → vuoto |
| 2 | Lo slot che dovrebbe ospitarlo è in sola lettura, **senza mutatore** | `ios_app/QBeats/UI/QLive/QLiveSession.swift:35` |
| 3 | La pagina del player non è raggiungibile: **nessuno** chiama `navigate(to: .metronome)` | `ios_app/QBeats/UI/QLive/QLiveRootView.swift:88-90`, tre soli chiamanti a `:97` `:104` `:157` |
| 4 | Il bottone **START SHOW** del dettaglio ha la closure vuota | `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:289-292` |

**Conseguenza [M]:** `LiveView`, `TransportView`, `FineSetlistView`, `MixerOverlayView`,
`WaitingForDirectorView`, `StandbyOverlayView`, `OverlayStopView` — **1040 righe misurate** — sono
oggi codice non eseguibile dall'app.

**Cosa fa l'app oggi, nella build installabile [M]:** Home → Q-STAGE (lista + editor canzoni/sezioni)
oppure Q-LIVE → lista Shows → scheda dettaglio → indietro. Più un metronomo nudo funzionante dietro
la porta ⚙ DEBUG (`ios_app/QBeats/ContentView.swift:49-54`), che esiste solo perché la CI archivia in
`-configuration Debug` (`.github/workflows/ios_build.yml:78`).

**Perché è successo [M]:** è voluto. ⟦S4R⟧ (`bfc9228`, 31/07) ha cancellato `LiveRootView` e il
"runner phantom" apposta, perché nessuno potesse entrare nel player senza un runner nato come si
deve. Il mutatore manca **per scelta**, e il commento a `QLiveSession.swift:12-15` lo dichiara. La
chirurgia però è aperta **dal 31/07**, cioè da diciotto giorni.

---

## 1 · Dove siamo — le misure che contano

### 1.1 Il prodotto

**[M]** I due strati bassi sono chiusi e collaudati: Layer 1 audio C++ e Layer 2 MIDI + Ableton Link
(`BOX5_QBEATS.md:94-102`). Il motore funziona: il click nasce in `scheduleNextBuffer()`
(`AudioEngine.swift:2195`), il tempo lo tiene `MetronomeDSP` contando campioni
(`core_engine/MetronomeDSP.cpp:383-533`), tre orologi vengono riallineati a ogni buffer
(`AudioEngine.swift:2260-2307`).

**[M]** Layer 3 (l'interfaccia SwiftUI) è il cantiere, ed è aperto a metà: la stanza Q-Live ha due
schermate raggiungibili su tre.

### 1.2 Il collaudo su device

**[M] L'ultima validazione su un iPad vero è del 29/07** — ⟦S4K⟧ congedo tastiera e DARK-DECL, Mauro
su iPad + iPhone (`LIBRO_MASTRO_QBEATS.md:318-319`).

Da allora **tre commit di codice** sono su master con la CI verde e **nessuno è mai stato provato**:

| commit | data | atomo | stato dichiarato |
|---|---|---|---|
| `bfc9228` | 31/07 | ⟦S4R⟧ — la proprietà del runner sale alla stanza | «⛔ NON è chiuso device» (`LIBRO:330`) |
| `25056b6` | 05/08 | ⟦S5a⟧ — `QLiveShowDetailView`, frame ③ | «⛔ NON validata su device» (`SCALETTA:323`) |
| `4e4c241` | 06/08 | ⟦S5x⟧ — cablaggio BACK TO SHOWS | «chiuso a codice, validazione device DIFFERITA» |

⚠️ **[M] I congedi nominano due atomi non validati. Sono tre.** ⟦S4R⟧ è il terzo ed è il più rischioso
dei tre, perché è l'unico che ha cambiato la **proprietà del motore di trasporto**, non una vista.

### 1.3 Il divario fra ciò che è ratificato e ciò che è costruito

**[M] È il problema di fondo del progetto in questo momento**, e non è nominato in nessun canonico.

Il LIBRO porta **156 decisioni ratificate**, di cui **149 con stato «attiva»**. Ma la colonna Stato
dice se la decisione è viva *come decisione*, non se è finita nel codice. Misurate **almeno 15 righe
«attiva» senza alcun riscontro nel codice**, e **tre in cui il codice fa il contrario**:

| ratificata il | cosa dice la ratifica | cosa c'è nel codice |
|---|---|---|
| 07/08 | RESTART SETLIST si toglie da END SHOW (`LIBRO:353`) | c'è ancora, closure vuota — `FineSetlistView.swift:31` |
| 27/07 | chip «Read-only» RIMOSSO, Mauro: «TOGLILA E BASTA» (`LIBRO:313`) | vivo in due punti — `QLiveShowsView.swift:145,160` · `QLiveShowDetailView.swift:181` |
| 06/08 | nome show 23px → **29px**, max 2 righe (`LIBRO:349`) | ancora 23 e `lineLimit(1)` — `QLiveShowDetailView.swift:152,155` |
| 06/08 | variante `.seg-mini` **ABOLITA** (`LIBRO:349`) | viva e in uso — `RoomSwitchBar.swift:30,65,129` |
| 21/05 | KILL BASE → **KILL TRACK** (`LIBRO:222`) | ancora `"KILL\nBASE"` — `TransportView.swift:78` |
| 21/05 | «emerg» → **EMERGENCY** (`LIBRO:239`) | ancora «emerg», e la closure è vuota — `TransportView.swift:90-92` |
| 21/05 | UI tutta in inglese, bottoni STOP (`LIBRO:219,224`) | in italiano — `OverlayStopView.swift:16,21` |
| 21/05 | rename `.overlayStop` → `.stoppedMidSong` (`LIBRO:232`) | `.stoppedMidSong` = **0 occorrenze**; `.overlayStop` è l'unico che esiste |
| 29/04 | tasto LOOP con stato `LOOP·N`/`LOOP·∞` (`LIBRO:198`) | etichetta fissa «loop» su `func toggleLoop() {}` vuota |
| 01/07 | in Standalone il Link **non si aggancia mai** (`LIBRO:268`) | si aggancia: il motore distingue solo `.direttore` |
| 01/07 | ruolo Link **mai memorizzato** fra un avvio e l'altro (`LIBRO:268`) | salvato su disco a ogni cambio — `AppSettings.swift:22,28-38` |

Il caso più netto: la ratifica del **07/08** su RESTART SETLIST è passata da due cancelli distinti
(referee + Mauro) — e **l'ultimo commit che tocca `ios_app/` è del 06/08**, cioè del giorno prima.
Undici giorni, zero righe.

### 1.4 Il rapporto fra documenti e codice — misurato

**[M]** Nessun documento lo dichiara. Commit per settimana, e quanti toccano `ios_app/`:

| settimana | commit | di cui codice | quota codice | righe .swift nette |
|---|---:|---:|---:|---:|
| 29/06 | 37 | 22 | **59 %** | — |
| 06/07 | 22 | 9 | 41 % | +931 / −210 |
| 13/07 | 20 | 8 | 40 % | +1167 / −142 |
| 20/07 | 12 | 1 | **8 %** | +19 / −5 |
| 27/07 | 25 | 3 | 12 % | +241 / −36 |
| 03/08 | 11 | 2 | 18 % | +477 / −7 |

**[I] Lettura di CC:** l'apparato documentale non è spreco — è il sistema che tiene allineati CD, CC e
referee, e ha evitato errori veri. Ma il rapporto si è rovesciato: da giugno a oggi la quota di lavoro
che tocca il prodotto è passata da tre quinti a un sesto, e il divario ratificato-vs-costruito della
§1.3 è la conseguenza diretta. **Ogni nuova ratifica che non atterra allarga il buco che stiamo già
cercando di chiudere.**

### 1.5 Il tracker

**[M]** 70 ticket aperti, 34 chiusi. Ripartizione dei 70: 🔴 ALTA 5 · 🟠 MEDIA 18 · 🟡 BASSA 20 ·
🔵 COSMETICO 3 · SOSPESO 1 · **23 senza alcuna severità dichiarata**.

Dichiarati BLOCCANTE PALCO: **due soli** — `TD-qlive-exit-unconfirmed-stop` (`BUGS:128`) e
`TD-fineshow-bottoni-morti` (`BUGS:351`). Il secondo **sta fisicamente dentro §1.2**, la sezione il
cui titolo promette «non bloccanti» (§1.2 apre a `:173`, §1.3 a `:398`, il ticket è a `:344`).

---

## 2 · Il cardine — ⟦S5b⟧, cablare lo Start

**[I] È l'unico lavoro che restituisce all'app la sua ragione di esistere**, e da esso dipende quasi
tutto il resto. Non è «il prossimo atomo della lista»: è il tappo.

Cosa sblocca, misurato uno per uno:

- rende raggiungibile **END SHOW** → rende collaudabile ⟦S5x⟧, consegnato il 06/08 e mai visto funzionare;
- rende raggiungibile la **pulsantiera** → i ticket `emerg` e i tre comandi vuoti diventano reali, oggi non lo sono;
- rende raggiungibile il **mixer** → `TD-mixer-copre-endshow` diventa verificabile;
- prova le due metà di ⟦S4R⟧ — «il runner nasce allo Start, muore al bordo-stanza» — ratificate il 18/07 e **mai provate** (`LIBRO:330`);
- è il presupposto di ⟦S-EXIT⟧, che oggi non ha né ticket né scheda.

**⚠️ Blocco reale da sciogliere prima [M]:** il codice stesso dispone che **⟦S5⟧ non parte senza
l'empty-state onesto della pagina metronomo**, e dichiara che quel disegno è **materia CD** e che
**non esiste freeze** per quella pagina (`QLiveRootView.swift:162-169`). Serve una consegna di CD.
È l'unica dipendenza esterna del cardine, e va chiesta subito perché il resto non può partire senza.

---

## 3 · Le fasi

### FASE 0 — Oggi, mezz'ora, e una delle due è a costo zero

| # | cosa | perché adesso | chi |
|---|---|---|---|
| 0.1 | `git rm tmp_fix.ps1` | **[M]** file **tracciato** nella radice di un repo **pubblico** che, se eseguito, sovrascrive `AudioEngine.swift` (3079 righe) con un prototipo di 142 righe — `tmp_fix.ps1:144` | CC, previa autorizzazione |
| 0.2 | **Gate device ⟦S5a⟧** | **[M]** l'IPA firmata della punta esiste ed è viva (artifact `QBeats-IPA`, 4 825 493 B, run `31213490430`, non scaduto). Percorso: Home → Q-LIVE → tap-riga → dettaglio. Dieci minuti. Segnalato in dieci referti su dieci e mai raccolto | **Mauro** |

⚠️ **[M] Nota onesta sul 0.2:** il freeze CD del 06/08 ha reso **fuori-contratto** parte di ciò che
⟦S5a⟧ ha messo su master (titolo 23 invece di 29, `.seg-mini` abolita ma viva). Il gate va fatto
**sul comportamento** — navigazione, tap, ritorno, dati mostrati — non sulla tipografia, che è un
delta già noto e tracciato in §1.3.

### FASE 1 — Il cardine

| # | cosa | note |
|---|---|---|
| 1.1 | **CD consegna l'empty-state della pagina metronomo** | dipendenza bloccante, vedi §2 |
| 1.2 | ⟦S5b⟧ — mutatore su `QLiveSession`, costruzione del `SetlistRunner` allo Start, `navigate(to: .metronome)` | un solo bottone: lo Start diviso vive sulla card della lista, il `.startfoot` del dettaglio resta invariato (freeze 06/08) |
| 1.3 | **Gate device di ⟦S5b⟧ + ⟦S4R⟧ + ⟦S5x⟧ insieme** | tre atomi arretrati si chiudono in una sola sessione su device: è il momento di massimo ritorno di tutto il piano |

### FASE 2 — Il grappolo END SHOW *(diventa bloccante-palco nel momento in cui la Fase 1 atterra)*

| # | cosa | dimensione [M] |
|---|---|---|
| 2.1 | Togliere **RESTART SETLIST** — già ratificato il 07/08, mai atterrato | due righe |
| 2.2 | **Chiudere il mixer al cambio di stato.** `showMixer` è scritto in 5 punti, tutti gesti utente, **nessuno legato a `playbackState`** → un mixer aperto nell'ultima sezione arriva aperto a END SHOW | piccola |
| 2.3 | **Il velo del mixer copre l'uscita.** Il blocco mixer è l'**ultimo figlio** dello ZStack (disegna sopra END SHOW, tinta opaca) e sopra c'è un velo alto il 49 % dello schermo, tappabile e con hit-testing attivo, proprio sopra BACK TO SHOWS — `LiveView.swift:194-207` vs `:144-164` | media |
| 2.4 | **Gli slider del mixer scrivono su disco.** `MixerOverlayView.swift:62` → `AudioEngine.swift:1441-1471` → salvataggio a `:1468`. Un dito al buio può **azzerare il canale CLICK per sempre**, senza segnale. ⚠️ Chi risolve solo la sovrapposizione crede di aver chiuso il ticket e non l'ha chiuso | media |
| 2.5 | **Decidere `emerg`**: toglierlo (tre righe) o cablarlo (serve prima che CD dica *a cosa*, mai ratificato) | decisione |
| 2.6 | Dare a **⟦S-EXIT⟧** un ticket in BUGS e una scheda nella SCALETTA — oggi è una freccia dentro una riga d'ordine, senza scopo, senza file, senza cancello | doc |

### FASE 3 — Perdita dati *(corsia parallela: non dipende dalla Fase 1, si può fare in qualunque momento)*

**[I] Sono gli unici difetti che distruggono il lavoro dell'utente. Nessuno è bloccante-palco, e per
questo nessuno li guarda — ma sono gli unici irreversibili.**

| # | cosa | prova [M] |
|---|---|---|
| 3.1 | **`injectTestData` può sovrascrivere il catalogo vero.** Sostituisce l'intero catalogo in RAM; tutte e dieci le operazioni CRUD chiamano `save()`; `save()` fotografa la RAM e la scrive sui tre file. Basta **una** modifica dopo aver caricato i dati di test. 8 siti di chiamata in `DebugView.swift`, e la porta DEBUG **viaggia nell'IPA** | `QBeatsStore.swift:198-202`, `:66-74`, `:81-123` |
| 3.2 | **Errore di lettura → catalogo vuoto silenzioso**, e il primo salvataggio lo rende definitivo | `QBeatsStore.swift:241-249` · `QBeatsApp.swift:18-24` |
| 3.3 | **Le impostazioni si azzerano al primo campo nuovo**: `try?` con fallback ai default su una struct di dieci campi → volumi, mute e canali persi in silenzio | `AppSettings.swift:28-33` |
| 3.4 | **La freccia indietro dell'editor canzone scarta le modifiche senza avviso** | `BUGS:360` |

### FASE 4 — Il fronte sincronizzazione *(serve la Fase 1 fatta e due device)*

**[M] Quattro difetti confermati a codice, tutti invisibili con un device solo e tutti visibili sul palco.**

| # | cosa | prova |
|---|---|---|
| 4.1 | **Standalone non è implementato.** Le modalità dichiarate sono tre, il default è Standalone, ma nel motore **solo `.direttore`** cambia comportamento: Standalone e Follower cadono nello stesso ramo. Con Link acceso un device Standalone **adotta il BPM del peer e parte/si ferma ai suoi comandi** | confronti solo con `.direttore` a `AudioEngine.swift:428,533,971,2271`; `linkMode == .standalone` → 0 occorrenze |
| 4.2 | **Standalone non è nemmeno selezionabile**: il selettore ha due sole voci, Director e Follower. Scelto un ruolo, il default di fabbrica è irraggiungibile senza reinstallare | `SettingsView.swift:33-34` |
| 4.3 | **Il ruolo è ricordato fra un avvio e l'altro**, contro la ratifica. Due device possono ritrovarsi entrambi Direttore senza che nessuno abbia toccato niente quella sera | `AppSettings.swift:22` · `AudioEngine.swift:109-114` |
| 4.4 | **Lo stop di un Follower parla a Link come quello del Direttore**: nessun ramo di modalità attorno al comando di stop, mentre la partenza è differenziata | `AudioEngine.swift:1625-1646`, comando a `:1645` |
| 4.5 | Solo dopo: `TD-follower-rejoin`, `TD#17`, `TD#A` — **[M]** non decidibili leggendo il codice, servono log su device che non esistono più | |

⚠️ **[M]** Il disegno giusto per 4.1+4.2 esiste già: è il **foglio a tre porte** ratificato il 02/07
(CD-7, `LIBRO`), mai costruito. Non serve inventare, serve costruire quello.

### FASE 5 — Riallineare i documenti alla realtà *(un giro solo, chiuso, non un rituale ricorrente)*

**[I] Da fare *dopo* la Fase 1, non prima.** Farlo prima significa aggiungere un piano sopra un
cancello che nessuno ha chiuso.

| # | cosa | prova [M] |
|---|---|---|
| 5.1 | Convertire la §1.3 di questa roadmap in **ticket veri** in BUGS — è l'unico modo perché il divario smetta di crescere | |
| 5.2 | Spostare `TD-fineshow-bottoni-morti` in §1.1, e **correggerne il testo**: descrive come vuoti due bottoni, ma BACK TO SHOWS è cablato dal 06/08. `4e4c241` → **0 occorrenze** in tutto BUGS | il tracker non sa che quel lavoro è stato fatto |
| 5.3 | `LIBRO:447` dichiara BUGS **v7**; è alla **51**. `LIBRO:437` dichiara l'ultimo commit di codice `6c7352a`; ce ne sono **tre** più recenti — e viola la convenzione che la riga stessa scrive | |
| 5.4 | `LIBRO:376` (CD-8) dichiara «da decidere» il chip Read-only, **deciso a `LIBRO:313`** nello stesso documento | |
| 5.5 | **Sezione F della SCALETTA**: dichiara «~14 commit fa», sono **85** (`git rev-list --count fa64832..HEAD`). Ricostruirla o cancellarla | |
| 5.6 | **`BOX3:398-399`** manda a scrivere i canonici in `CC MEMORIA\`, che contiene **un solo file estraneo** del 19/06. Regola misurata falsa il 07/08, ancora lì | |
| 5.7 | BOX3 è fermo al 22/07, **38 commit indietro**: la riga «S4/S4L/S5/S6 non aperti» è falsa su quattro nomi su quattro | |
| 5.8 | Le **26 citazioni nude** alla SCALETTA che bloccano ogni inserzione in testa: ancorarle a commit o convertirle a simbolo | |
| 5.9 | Scrivere **dove vanno congedi e referti**: «congedo» in BOX3 → **0 occorrenze** (controllo positivo «HANDOFF» → 11). Non esiste regola | |
| 5.10 | Consegnare l'arretrato R-δ su Drive (12 stampe + 5 congedi + i referti) **e capire perché la gamba si è fermata** — mai misurato | |

### FASE 6 — Prerequisiti di distribuzione *(non ora, ma vanno nominati)*

| # | cosa | prova [M] |
|---|---|---|
| 6.1 | **La CI archivia in `-configuration Debug`** (`ios_build.yml:78`). Il giorno che passa a Release spariscono insieme la porta ⚙ DEBUG, le Impostazioni **e l'unico metronomo funzionante** | trappola latente |
| 6.2 | Il cancello qualità **F1** (zero errori, zero warning) è stato eseguito l'ultima volta il **31/07** ed è **fallito** (6 warning). È manuale: non gira da 18 giorni | run `30639169986` e `30638276963`, entrambe `failure` |
| 6.3 | `CFBundleVersion` bloccato a 1 — innocuo in sideload, morde a TestFlight/Store | **[R]** da rimisurare |
| 6.4 | `TARGETED_DEVICE_FAMILY` / `UIDeviceFamily` **mai dichiarati**: il perimetro dei device è solo implicato | `LIBRO:333` |
| 6.5 | **12 rami non mergiati**, quattro con lavoro vero mai portato a casa (20, 19, 18, 17 commit unici, maggio-giugno). Triage per-ramo, mai alla cieca | |
| 6.6 | TD #22 · #30 · #31 · #32 (infrastruttura CI) tutti ancora aperti in §1.3 | |

---

## 4 · Cosa NON fare adesso

- **[M] Non ri-committare e non ri-pushare** i tre commit del 07/08: sono su origin, CI verde.
- **[M] I file `HANDOFF/DIFF_*_2026-08-07_*` sono storia della proposta**, non lavoro pendente. Riapplicarli fallisce, ed è giusto così.
- **[M] Non cercare gli artefatti dei 36 ID mancanti**: un ID assente non è una consegna persa. A88 è annullato, A77 produsse un congedo e non un referto. Prossimo ID libero: **A90**.
- **[I] Non aprire un altro giro documentale prima della Fase 1.** È la raccomandazione che pesa di più in tutto questo documento.

---

## 5 · Decisioni che servono, e a chi

| # | decisione | a chi |
|---|---|---|
| D1 | Autorizzare il gate device ⟦S5a⟧ — dieci minuti, IPA già pronta | **Mauro** |
| D2 | Severità dei due ticket nuovi (`TD-mixer-copre-endshow`, `TD-emerg-bottone-morto`): oggi **PROPOSTA e non assegnata** | **Mauro** |
| D3 | Empty-state della pagina metronomo — **blocca ⟦S5b⟧**, nessun freeze esiste | **CD** |
| D4 | `emerg`: si toglie o si cabla? E se si cabla, a cosa? Mai ratificato | **CD + Mauro** |
| D5 | CD-Q5, CD-Q6b, CD-Q17, CD-Q18: campo risposta ancora vuoto | **CD** |
| D6 | Il congedo referee del 07/08 non è mai arrivato: senza, il confronto R1 fra due voci indipendenti non è possibile | **referee** |

---

## 6 · Come è stato misurato

**[M]** Verifica d'apertura: `git fetch` + `git rev-parse HEAD` + `git ls-remote origin master` →
coincidono su `321293e18094d9d4f1c167bfc921be1ad216e3ac`. `git status --porcelain=v1` → righe non-`??`
= **0**. Mirror E: senza file modificati dopo il 07/08 (`find -newermt 2026-08-08` → vuoto). Drive
oggi montato su `I:` — lettera **non stabile**, ricercata a fonte, da non scrivere in nessun canonico.
Nessuno ha lavorato durante la pausa.

**[M]** CI del commit di punta: run `31213490430`, `iOS Signed Build`, **success**; artifact
`QBeats-IPA` 4 825 493 B non scaduto. `gh auth status`: loggato, quindi nessun falso-zero da canale.

Lettura: undici agenti su documenti e codice più tre passaggi di verifica avversariale, 483 comandi
a fonte. Due affermazioni dei documenti sono state **smentite** e sono riportate come tali in §5.2 e
in §3 (il ticket `emerg` dichiara una raggiungibilità che a HEAD non esiste). Gli anelli della catena
del §0 e i due reperti di Fase 6 sono stati **rimisurati personalmente da CC**, non ereditati dagli
agenti.

---

*Fine. Documento di proposta — nessuna riga qui è ratificata.
Vive in `HANDOFF/` nel repo e sul mirror E:. Non è un canonico.*
