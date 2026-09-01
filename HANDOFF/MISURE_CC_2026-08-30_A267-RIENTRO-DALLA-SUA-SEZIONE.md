# MISURE CC — A267 — IL RIENTRO RIPARTE DALLA SUA SEZIONE — 30/08/2026

**ID `A267`** — sonde (R-δ.8/9/10): nome C: 0 · nome E: 0 · contenuto C: 0 · contenuto E: 9 file tutti in `LOG/RUN/`, aperti come obbliga R-δ.8 — match reali `DA267`/`5A267`/`0A267`, frammenti di UUID nei log di sistema, citazioni-per-caso ⇒ non occupano · `git log --all --grep`: 0, **positivo su `A240` (committato): 3 commit visti**. Gamba contenuto con `--exclude-dir=DESIGN` (R-δ.10; equivalente per effetto a `':!DESIGN'` su filesystem non-git). Candidati scartati descritti per relazione, non per cifra (R-δ.9). Prenotato con segnaposto su due gambe (`cmp` 0) PRIMA di questo referto, solitudine ri-misurata dopo la scrittura.

**HEAD di misura e di modifica:** `b1b4c1fd0864b1713eec7cda5a4d142fac431339` — working tree pulito all'apertura del mandato; ora porta le SOLE tre modifiche di questo diff, **non committate, non in stage**.

⛔ **Zero commit. Zero push. Fermo al CANCELLO 1** (diff → ratifica referee), come prescrive il mandato.

---

## §1 — Premesse del mandato, rimisurate a fonte

Tutte le premesse tecniche del referee **reggono** a `b1b4c1f`, rimisurate una per una:
- `currentSectionIdx` sopravvive all'uscita (`SetlistRunner.swift:31`; runner posseduto da `QLiveSession`, distrutto solo da `endShow()`, `QLiveSession.swift:209-213`). ✅
- `primeDisplay` converte `.stopped` → `.standby` (`SetlistRunner.swift:361-362`) **senza toccare gli indici**. ✅
- Il tap sul velo chiamava `startCurrentSong` (`LiveView.swift:193` pre-diff) che azzera la sezione (`SetlistRunner.swift:142`). ✅
- `startCurrentSection` conserva nel percorso normale ed è la terza partenza di A240 (`:166-185`). ✅

🚨 **La MINA è CONFERMATA, e smentisce il mio referto A265**: `startCurrentSection` NON è privo di scritture — alle `:179-180`, dentro la guardia `if currentSection == nil` (fallback A240), azzera ENTRAMBI gli indici. Il mio A265 §1.3 diceva «nessuna scrittura»: **falso**. Corretto oggi stesso con marcatura dove morde, in entrambe le copie di A265 (repo + E:, ri-verificate `cmp` 0). **Perché la guardia NON scatta nel percorso riparato:** `catalog` è `private let`, copia risolta all'init (`store.resolve(setlist)`, `SetlistRunner.swift:62-64`) — immutabile per la vita del runner, insensibile a modifiche dello store a show vivo; gli indici al tap provengono da uno stato di riproduzione valido; il ramo avanza incrementa solo sotto `!isLastSectionInSong` (`:380→:390`), mai fuori range ⇒ `currentSection` risolve e il fallback resta inerte.

[R] non verificabili da me: la riproduzione sul telefono di Mauro (device), il foglio CD del 27/08 (non letto in questo turno). La coerenza col cartello A240/opzione B è invece misurata (`SetlistRunner.swift:148-165`).

---

## §2 — La riparazione (minima: un solo punto di comportamento)

**Un solo sito comportamentale**: il tap sul velo standby, `LiveView.swift` (era `:193`). Da:

```swift
runner.startCurrentSong(audioEngine: audioEngine, session: session)
```

a:

```swift
if runner.currentSectionIdx > 0 {
    runner.startCurrentSection(audioEngine: audioEngine, session: session)
} else {
    runner.startCurrentSong(audioEngine: audioEngine, session: session)
}
```

più il cartello A267 sopra (visibile nel diff). **Nessuna funzione nuova, nessuno stato nuovo, nessun campo nuovo**: instrada fra due partenze che esistono già, entrambe con contratto documentato. Le altre due modifiche del diff sono **sole marcature su commenti** che il fix rende stantii (cartello A228 in `SetlistRunner`, marcatura A240 in `TransportView`) — «si marca, non si riscrive», nessun effetto sul compilato.

**Perché l'ingresso normale NON cambia (vincolo 2 del mandato):**
- show appena aperto → runner appena installato (`QLiveRootView`, `roomSession.install(SetlistRunner(...))`) → indici 0/0 di default (`:30-31`) → ramo `else` → `startCurrentSong`, byte-identico a oggi;
- standby fra due canzoni → il ramo standby di `makeSectionEndedClosure` azzera la sezione (`:432`) PRIMA di armare (`:436`) → indice 0 al tap → ramo `else`, identico a oggi;
- la lista di permessi dell'armamento (`primeDisplay`, Cond (c)) **non è toccata**: il diff non contiene alcuna riga di `primeDisplay`.
- rientro dopo STOP nella PRIMA sezione → indice 0 → ramo `else` → azzera (no-op, già 0) → riparte dalla sezione 0 **= la sezione dov'era**: esito corretto anche qui.

**Vincoli 3-5**: conto alla rovescia non toccato · `handleStop()`/`stop()`/stub non toccati · il diff vive interamente in Layer 3 (`UI/Live/` + `SetlistRunner`), L1/L2 intatti — nessuna delle tre righe comportamentali parla col motore se non attraverso le partenze esistenti.

---

## §3 — Dichiarazione A: Link da Direttore

**Il meccanismo di banda è INVARIATO.** Entrambe le partenze (`startCurrentSong` e `startCurrentSection`) convergono sulla stessa `prepareAndStartCurrentSection` → stesso `audioEngine.start()` — il punto dove il ramo Direttore esegue `link_engine_start_at_beat_zero` e fa ripartire i Follower. Stesso evento, stesso trigger, stesso callsite: il diff non cambia QUANDO e SE la banda riparte, cambia solo QUALE sezione il device locale carica (BPM/BPB/accenti della sezione conservata invece della prima).

⚠️ **Residuo dichiarato, NON riparato — decisione non mia:** l'observer `linkStartedSubject` (`LiveView.swift`, ramo `.standby` → `startCurrentSong`) **non è toccato** e conserva il difetto gemello: un Follower fermo in re-entry-standby che riceve lo start del Direttore azzera ancora la sezione. Scenario: Direttore riprende via tap dalla sezione 8 → un Follower in quello stato parte dalla sezione 0 → **contenuti locali disallineati** (il click resta sincrono: Link allinea il beat, non la sezione). Questo disallineamento **non nasce col fix**: esiste già a HEAD in forma speculare (Follower rimasto in `.stopped` → A240 lo fa riprendere da dov'era, mentre il Direttore in re-entry azzerava — oggi era il Direttore quello indietro). Il fix sposta la combinazione che lo produce, non ne crea la categoria. Sanare anche l'observer userebbe lo stesso segnale (`currentSectionIdx > 0`), **ma cambierebbe il comportamento del Follower = decisione di banda = di Mauro**. Non fatta qui; la porto come voce aperta.

---

## §4 — Dichiarazione B: il segnale, e la sua onestà

**Segnale usato: `runner.currentSectionIdx > 0` all'istante del tap.** Provato a fonte, caso per caso:

| situazione | indice al tap | perché, a fonte | ramo preso | esito |
|---|---|---|---|---|
| show appena aperto | 0 | init non tocca gli indici (`:30-31` default) | else | invariato |
| standby fra due canzoni | 0 | ramo standby azzera prima di armare (`:432`→`:436`) | else | invariato |
| rientro dopo STOP a metà (sezione ≥2) | >0 | nessuno scrittore sul percorso STOP/uscita (A265 §1.3, che su QUESTO punto regge); `primeDisplay` non tocca gli indici | **if** | **conserva — il bersaglio** |
| rientro dopo STOP nella prima sezione | 0 | l'indice era già 0 | else | azzera un indice già a 0 → riparte dalla sezione dov'era: **corretto** |

**Onestà del segnale:** non distingue le PORTE («fresco» vs «rientro»), distingue gli STATI. Le due porte che confonde — ingresso fresco e rientro con indice 0 — **condividono lo stesso esito corretto**, quindi la distinzione mancante non produce alcuna differenza osservabile. Non esiste a HEAD un flag «vengo da un rientro» e **non ne ho inventato uno** (vietato dal mandato B): il segnale è stato conservato che già esiste, il minimo che separa i comportamenti dove DEVONO divergere.

Beneficio collaterale misurato, nessuna riga spesa: `primeDisplay` già oggi mostra dietro il velo i dati della sezione conservata (`updateSessionDisplay` da indici conservati + `currentBPM`/`totalBarsInSection` dalla sezione corrente). Prima del fix quel display **mentiva** (mostrava la sezione 8, il tap suonava la 1); dopo, dice il vero.

---

## §5 — Cosa NON ho verificato

⛔ **Nessuna build**: niente Mac/Xcode qui — la compilazione la prova la CI (cancello 2). La sintassi delle tre righe comportamentali è a mio carico visivo.
⛔ **Nessun device**: il collaudo è il cancello 5, di Mauro.
⛔ **Il foglio CD 27/08** citato dal mandato: non letto, [R].
⛔ **L'overlay standby mostra «Next: {canzone}» anche al rientro a metà**: copy di CD, non toccata — segnalo che dopo il fix il testo «Next» sovrasta una ripresa, non un inizio. Voce per CD, non per me.

---

## §6 — Cancelli

**Consegnato al CANCELLO 1**: diff verbatim (file sotto + in chat) + impronte nel messaggio di consegna. **Attendo la ratifica del referee. Non committo, non pusho.** Nota per il cancello 2: la CI di questo repo parte sul push a `master` (`iOS Signed Build`) o manuale (`F1`, fermo da mesi) — «CI verde prima del commit su master» richiede un branch di servizio: decisione di percorso da darmi insieme alla ratifica.

## Percorsi

```
DIFF    repo : HANDOFF\DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC.txt
        E:   : FILE X CLAUDE.MD\HANDOFF\DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC.txt
REFERTO repo : HANDOFF\MISURE_CC_2026-08-30_A267-RIENTRO-DALLA-SUA-SEZIONE.md
        E:   : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-30_A267-RIENTRO-DALLA-SUA-SEZIONE.md
```

*(l'impronta di questo file vive nel messaggio di consegna, non qui)*

---

# REV3 — SIGLA ⟦SOL-C⟧, RETTIFICA CONTEGGIO, PUSH E BUILD (30/08, sera)

**[M]** Aggiunta la sigla fissa `⟦SOL-C⟧` in entrambi i cartelli (tap velo e observer `linkStartedSubject`), su richiesta referee. Prova meccanica eseguita PRIMA del deposito (`diff` fra `..._rev2.txt` e `..._rev3.txt`): le sole righe cambiate, oltre all'hash di indice del blob git, sono le due righe di commento che guadagnano la sigla. Zero righe di codice toccate — confermato, non solo dichiarato.

**[M]** Rettifica conteggio: vedi nota datata in coda alla sezione REV2 sopra (10+/2− reale, non 9+/2−).

**[M] Push e build — informazione che NON viveva in nessun documento fino a questa riga, solo nella chat:**
- Commit `98c3aa22fdc8b28be55a0242f90f1c4468e7fb69` su ramo **`fix/a267-rientro-dalla-sua-sezione`** (NON master), contenente solo i tre file `ios_app/` di questo diff (rev3).
- Nessuna PR aperta, come da divieto esplicito del mandato.
- CI (`iOS Signed Build`) dispatchata MANUALMENTE (`gh workflow run … --ref fix/a267-rientro-dalla-sua-sezione`): il trigger automatico è solo su push a `master` (`ios_build.yml:1-5`), quindi un push su ramo di servizio non fa partire nulla da solo.
- Run [`33315106030`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/33315106030), job `build` **verde in 2m26s**, tutti gli step passati. Due annotazioni ambientali preesistenti (deprecazione Node.js 20 nelle action, tap Homebrew `aws/tap` non trusted) — non causate da questo diff, non bloccanti.

⛔ **Fermo al cancello di merge**: ramo di servizio pushato, non unito a `master`. Manca il cancello di Mauro + referee per il merge, poi il collaudo device.

---

# REV2 — IL FOLLOWER RIPARTE DA DOV'ERA (completamento, stesso lavoro)

**Perché stesso ID e non uno nuovo (R-δ.8, dichiarato come chiede il mandato):** un ID è occupato quando è assegnato a un LAVORO — questo è il medesimo diff non ancora committato, in revisione dopo la ratifica del rev1 e la decisione di Mauro «INSIEME». Convenzione di casa per le revisioni: suffisso `_rev2` sullo stesso ID (precedenti in `HANDOFF/`: `DIFF_LIBRO-v44_2026-07-30_rev2.txt` e simili). Il diff rev2 SOSTITUISCE il rev1 (stesso working tree, superset).

## 🔴 La domanda che conta — l'indice del Follower è lo stesso del Direttore?

**Misurato a fonte, risposta a due facce:**

**SÌ nel caso d'uso del mandato.** Lo stop del Direttore arriva al Follower dal callback Link (`AudioEngine`, `link_engine_set_start_stop_callback`, ramo `!isPlaying && engine.isPlaying → engine.stop()`) → il motore del Follower si ferma e `stop()` **non tocca il runner** (A265, Blocco 1.3) ⇒ **entrambi i runner congelano i loro indici allo stesso beat**. Gli indici erano uguali mentre suonavano perché l'avanzamento è un CONTO LOCALE sui beat (`_sectionBeatCounter` vs `_sectionTotalBeats`, closure end-of-section): con la stessa struttura di setlist, partenza insieme e beat allineati da Link, i confini di sezione cadono sugli stessi beat sui due device. Stesso conto ⇒ stessi indici ⇒ la riparazione ALLINEA.

**NO in generale, e nessun meccanismo lo garantisce.** Sweep della superficie Link usata in `AudioEngine` (tutte le `link_engine_*` chiamate): create/destroy/activate/enable/is_connected/num_peers/probe_session/**join_running_session**/set_bpm(±at_time/audio_thread)/set_quantum/start_at_beat(_zero)/stop/sync_phase/assert_session_state/output_latency/5 callback (tempo, is_connected, is_enabled, peers_changed, start_stop). **Nessuna trasporta contenuto**: sezione, canzone, setlist non viaggiano. Divergono quindi: join tardivo a sessione in corsa (`link_engine_join_running_session`) · rientro dopo caduta di rete · strutture di setlist diverse sui due device · Follower fermato localmente mentre il Direttore suona. In quei casi la riparazione **non allinea: cambia il modo in cui sono disallineati** — e la marcatura obbligatoria nel codice lo dice, con la riparazione strutturale indicata: **Soluzione C, LIBRO:212** (verificata a fonte in questo turno: riga del 20/05/2026, «protocollo Wi-Fi proprietario master/client = strada commerciale definitiva… no Layer 1-2 changes», stato **attiva**).

## Punto 2 del mandato — i due rami dell'observer collassano?

**NO, e non ho semplificato.** Con sezione 0 le due partenze sono equivalenti solo nel percorso normale; nel degenere `currentSection == nil` **divergono**: `startCurrentSong` conserva `currentSongIdx` e `prepareAndStartCurrentSection` degenera a `fineSetlist` immediato (guard di testa), mentre `startCurrentSection` fa fallback 0/0 e riparte dalla PRIMA canzone della setlist. Due esiti diversi. Il ramo resta doppio, il commento storico resta, e il cartello nuovo nell'observer avverte esplicitamente: «non unificare senza decisione».

## Il diff rev2 — cosa aggiunge al rev1 ratificato

- `LiveView`, observer `linkStartedSubject`, ramo `.standby`: stessa regola del tap — `if runner.currentSectionIdx > 0 → startCurrentSection else startCurrentSong` — con la marcatura obbligatoria del punto 3 (stesso-conto-non-si-parlano · non regge su join tardivo/caduta rete · Soluzione C LIBRO:212) incisa NEL CODICE come ordinato.
- `LiveView`, cartello A267 al tap: aggiornata la coda del cartello («observer non toccato» → «observer segue la stessa regola dal 30/08»). Il cartello era BOZZA di questo stesso diff mai committato: si riscrive nella revisione, non si stratifica.
- **Nessun segnale nuovo, nessun flag, nessuna variabile**: identico segnale del tap (`currentSectionIdx > 0`).
- Invariati dal rev1: marcature `SetlistRunner`/`TransportView`, perimetro (countdown, `handleStop`/`stop`/stub, L1/L2 non toccati — il diff vive in `UI/Live/` + un commento in `SetlistRunner`).

**Diff totale rev2: 3 file, 58+/2−.** Righe di CODICE: 5+/1− al tap (rev1, ratificate) + 4+/1− nell'observer (la riga esistente scende nel ramo `else`); tutto il resto è cartelli.

⚠️ **RETTIFICA 30/08, sera (mandato rev3)** — il conteggio sopra è FALSO: il blocco di codice reale è di **CINQUE** righe in ENTRAMBI i siti (`if …{` · ramo `startCurrentSection` · `} else {` · ramo `startCurrentSong` · `}`), non cinque e quattro. Rimisurato meccanicamente su `DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC_rev2.txt` isolando le righe `+`/`-` che non sono commento puro: **10 righe aggiunte, 2 tolte** (5+/1− per sito × 2 siti), non 9+/2−. Il totale di diff (58+/2−, che include i cartelli) resta invariato — era la sola scomposizione «codice vs cartelli» a contare male. Trovato dal referee, riverificato a fonte da me prima di scrivere questa riga.

⛔ **Fermo di nuovo al CANCELLO 1 del nuovo ordine**: diff rev2 consegnato, attendo ratifica referee → poi OK di Mauro → poi push su ramo di servizio → CI sul ramo → master → device. Zero commit, zero push anche ora.

*A267-REV2-FINE*

---

# COLLAUDO DEVICE — ESITO (30/08/2026, sera — merge su master)

**Data dichiarata**: `date` di sistema al momento di scrivere questa sezione → **2026-08-30, 17:06:59 locale (+0200)**. Stessa data degli altri artefatti di oggi — controllato esplicitamente, non allineato per assunzione: il mandato chiedeva di verificarlo perché il referee non può saperlo da sé.

**[R] Collaudo eseguito da Mauro, due apparecchi (iPhone Direttore + iPad Follower), setlist L1.b da DebugView, Start/Stop Sync acceso su entrambi verificato prima di partire — riportato dal referee, non da me: non ero presente, non ho misura diretta.**

- STOP sul Direttore → il Follower si ferma in automatico. ✅
- Ramo «sezione > 0»: fermata in seconda sezione, uscita dal player e rientro su entrambi, velo con lo stesso nome canzone su entrambi, tap → i due riprendono dal PRIMO BEAT della sezione dove si erano fermati. ✅
- Ripetuto attraversando il cambio canzone fino a Test Song B, stessa procedura: stesso esito, ripartenza dal primo beat della seconda sezione di Song B. ✅
- Ramo «sezione 0» (controprova): fermata dentro la prima sezione → entrambi ripartono dal primo beat della prima sezione. ✅ Comportamento pre-esistente intatto.

**I due cancelli**, verificati da me a fonte prima del merge, non solo dichiarati dal mandato:
- Ratifica referee sul diff rev3: **[M]** riverificato in modo indipendente subito prima di agire — `git diff master fix/a267-rientro-dalla-sua-sezione --stat` → 3 file, 58+/2−; righe non-commento isolate per file → `SetlistRunner.swift` 0, `TransportView.swift` 0, `LiveView.swift` 10 (due blocchi da 5, nei due siti previsti); occorrenze `⟦SOL-C⟧` nel diff → 2. Tutti i numeri del mandato confermati, non solo trascritti.
- OK di Mauro: condizionato, dato in anticipo, condizione ora soddisfatta dal collaudo sopra — [R], riportato dal mandato.

## Il merge

**[M]** Forma usata: **squash**, come da precedente in casa (`ee0cbc0`, «Bug 2.b — Ferita A + Ferita B», stesso autore/committer, nessun trailer). Scelto perché il ramo di servizio portava un solo commit sopra un `master` che non si era mosso (`git rev-parse master origin/master` → entrambi `b1b4c1f…`, verificato prima di agire): uno squash di un solo commit produce lo stesso contenuto di un merge diretto, ma tiene `master` con un log lineare, coerente con la convenzione osservata nella cronologia del repo.

**[M]** Commit di merge: `8a9faad975090410471e071ade90dd4f461a66aa`. Autore = committer = `Mauro Martintoni <di_tutto@icloud.com>` — verificato con `git show -s --format`, non assunto: l'identità locale del repo era già questa (stessa identità del commit rev3 `98c3aa2` e del precedente `ee0cbc0`), non ho impostato nulla io. **Zero trailer**, verificato leggendo il corpo del commit per intero.

**[M]** Push su `origin/master`: `b1b4c1f..8a9faad`. Nessuna PR aperta (non richiesta, non necessaria per un push diretto).

**[M] — Confronto ESATTO fra master-prima e master-dopo**: `git diff b1b4c1f 8a9faad --stat` → identico al diff rev3: **SetlistRunner.swift**, **LiveView.swift**, **TransportView.swift**, 58+/2−, nessun quarto file. Nessuna modifica ai canonici (`BOX5`, `BUGS`, `LIBRO`, `BOX3`) né a `DESIGN/` — verificato dall'assenza dalle tre righe di `--stat`, non da un'assunzione.

## Impronte — dal BLOB, come richiesto, non dal disco

⚠️ **La nuova regola ha appena mostrato perché serve**: l'impronta di `LiveView.swift` letta dal DISCO e quella letta dal BLOB **divergono davvero**, in questo momento, su questo file:

```
BLOB (git show 8a9faad:ios_app/QBeats/UI/Live/LiveView.swift | sha256sum):
  905b2f3ff0a967488061aa77480aec63ea30dc908262796e28eabd17fa8c63e7
  775 righe, 48763 byte

DISCO (sha256sum ios_app/QBeats/UI/Live/LiveView.swift):
  c267ecd1436be57457d186cd8996770a289c9bdc80dce6ce5c969c792125141a
  775 righe, 49538 byte
```

Stesso numero di righe, **775 byte di differenza esatti** = un `\r` in più per riga: il disco (Windows, questa macchina) è CRLF, il blob committato è LF. `ios_app/**` non ha eccezione `-text` in `.gitattributes` (che copre solo `HANDOFF/`, `DESIGN/`, `BOX3_QBEATS.md`, `BOX5_QBEATS.md`) — è normalizzato da git al commit. **L'impronta valida per chiunque legga dal repo (referee incluso) è quella del BLOB, sopra.**

⛔ Non toccati: canonici, `⟦SOL-C⟧` nel BUGS-ticket, la nota sul velo, la correzione BOX5 — dichiarati dal mandato come «materia del giro documenti, commit e chat a sé»: non è competenza di questo merge, non li ho cercati né toccati.

Il ramo `fix/a267-rientro-dalla-sua-sezione` **non è stato cancellato** — nessuna istruzione lo chiedeva.

## Build su master

**[M]** Trigger automatico (push a `master`, non dispatch manuale stavolta): run [`33318807294`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/33318807294), job `build` **verde in 2m44s**, tutti gli step passati (test modello, certificato, provisioning, Build and Archive, `ExportOptions.plist`, codesign, Export IPA, verifica entitlements, upload artifact). Stesse due annotazioni ambientali già viste sulla build del ramo di servizio (deprecazione Node.js 20, tap Homebrew `aws/tap` non trusted) — preesistenti, non introdotte da questo merge.

*A267-MASTER-MERGE-FINE*
