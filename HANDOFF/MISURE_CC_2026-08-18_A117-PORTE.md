# MISURE CC — A117, ⟦S5b⟧ PORTA SOLA + CENSIMENTO DELLE PORTE

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **SOLA LETTURA.** Nessun canonico modificato, zero righe sotto `ios_app/`, zero commit, zero
push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`. A114 cancellato, A116 mai
eseguito.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

# B1 · LA SCHEDA ⟦S5b⟧ — forma più stretta possibile

⚠️ **[A] Collocazione:** dopo ⟦S5⟧ (`SCALETTA:312`), prima di ⟦S6⟧. Porta la sezione B da **12**
a **13** intestazioni: il titolo «12 atomi» **va marcato, non riscritto**.

> ### ⟦S5b⟧ Start del dettaglio → player col primo brano ARMATO · POST · CI+DEVICE
>
> - **Scopo:** costruire **una porta sola**. Dallo `.startfoot` del dettaglio al player, con il
>   primo brano **armato in standby**. ⛔ **Finisce lì: cosa accade dopo il tocco dell'utente non
>   è di questo atomo.** Contratto: `BOX5_QBEATS.md:331` (QL-SHOWS-07, «l'ingresso in uno show è
>   SEMPRE arma + standby») e `BOX5_QBEATS.md:354` (§3, «Start = arma + standby sulla prima
>   canzone; il click parte al secondo tap o via MIDI»).
>
> - **File — QUATTRO:**
>   - `UI/QLive/QLiveSession.swift` **EDIT** — mutatore dello slot; il file lo assegna a questo
>     atomo (`:14-15`).
>   - `UI/QLive/QLiveShowDetailView.swift` **EDIT** — costruire il runner (`setlist` è a `:78`,
>     `store` a `:81`) e chiudere il tocco quando `resolve().songs` è vuoto.
>   - `UI/QLive/QLiveRootView.swift` **EDIT** — closure `() -> Void` iniettata al dettaglio nella
>     forma di `onBack` (`:104`): riempie lo slot, **poi** naviga.
>   - `SetlistRunner.swift` **EDIT** — accendere lo standby d'ingresso dentro `primeDisplay`
>     (`:271`), che ha **un solo chiamante**, già dentro l'`onAppear` del player
>     (`LiveView.swift:231`). ⛔ **Così `LiveView.swift` NON si tocca** e `LiveSession` resta privata.
>
> - **Reversibilità: PULITA.** Zero scritture su disco, `UserDefaults`, iCloud; nessun cambio di
>   formato dati. Dipendenza dura: ⟦S4R⟧. Ordine: dopo ⟦S5a⟧ e ⟦S5x⟧.
>
> - **🔴 Gate — UNICO ATOMO CHE CHIUDE TRE CANCELLI DEVICE IN UN COLPO SOLO:** il proprio · quello
>   **differito** di ⟦S5x⟧ (`SCALETTA:324`) · l'**armamento** di `TD-mixer-copre-endshow`
>   (`BUGS:158`). **CI:** verde su `iOS Signed Build`; `F1` non conta finché Mauro non decide.
>   - **Passo (1) — e distingue «armato» da «fermo»:** da un dettaglio con brani risolti, tocca
>     **START SHOW**. ✅ Deve comparire il **titolo della PRIMA canzone**, grande e centrato in
>     alto, **che pulsa lentamente**, sopra il player **visibilmente oscurato**; **non deve suonare
>     nulla**. ⛔ Se la videata è piena e nitida, o il titolo manca, o c'è ma **immobile**:
>     **FALLITO** — il player è fermo, non armato. (Segni misurati: `LiveView.swift:129`
>     opacità 0,10 · `StandbyOverlayView.swift:19-24` titolo 52 pt al 27 % · `:31-35` pulse
>     0,45↔1,0 in 2,2 s.)
>   - **Passo (2):** tocca lo schermo in un punto qualsiasi → il click parte da quella canzone.
>   - **Passo (3):** fine setlist → END SHOW → BACK TO SHOWS torna alla lista (gate di ⟦S5x⟧).
>   - **Passo (4):** esci dalla stanza → l'audio si ferma (`AppRootView.swift:74`).
>   - ⛔ **NON-DIFETTI — da NON segnalare come guasti al collaudo:**
>     **(a)** al tocco la musica parte **subito, senza conto**: `startCountIn` è uno stub
>     (`AudioEngine.swift:1561-1563`) e fra le canzoni il rinvio è **dichiarato nel codice**
>     (`SetlistRunner.swift:232`). **(b)** `prev sez`, `next sez` e `loop` della pulsantiera **non
>     fanno nulla**: chiamano funzioni vuote (`AudioEngine.swift:1267-1269`). **(c)** `emerg` non fa
>     nulla (`TD-emerg-bottone-morto`). **(d)** a END SHOW `RESTART SETLIST` non fa nulla
>     (`TD-fineshow-bottoni-morti`). ⇒ **Sono porte mancanti già note, non regressioni di ⟦S5b⟧.**
>   - ⚠️ Col percorso DEBUG vale la procedura sicura di `TD-injecttestdata-sovrascrive-dati-reali`
>     (`BUGS:143`).
>
> - **Cond — cinque:**
>   - **(a) ORDINE OBBLIGATO:** riempi lo slot, **poi** naviga. L'inverso apre un frame con
>     `runner == nil` e mostra il ramo `else`.
>   - **(b) STATO D'INGRESSO = arma + standby sulla PRIMA canzone**, non `.stopped`.
>     `BOX5:331` + `BOX5:354`. Il payload esiste già e regge: `nextSongName` è calcolato **dopo**
>     `currentSongIdx += 1` (`SetlistRunner.swift:343-345`), quindi significa «la canzone che
>     partirà» — all'ingresso, con indice 0, **è la prima**.
>   - **(c) GUARDIA SUL RI-ARMAMENTO:** `primeDisplay` gira a **ogni** `onAppear`, non solo al
>     primo. Senza guardia si potrebbe rimettere in standby uno show **già in esecuzione**.
>   - **(d) IL TOCCO SI CHIUDE** quando `resolve().songs` è vuoto: `.disabled(` nel dettaglio rende
>     **0**, contro **6 file** che lo usano nel corpus.
>   - **(e) NIENTE STOP AUDIO AGGANCIATO ALLA NAVIGAZIONE MENTRE IL CLICK GIRA**
>     (`QLiveRootView.swift:78-85`). ✅ Non vieta l'azzeramento di **stato** a END SHOW, dove il
>     playback è già finito (`LiveView.swift:161`): **igiene, non transport**.
>
> - **Modello raccomandato alla costruzione:** Opus — quattro file e due regole (ordine, guardia)
>   che il compilatore non verifica.
>
> - **OPEN — fuori dalla porta, nominati perché il cancello non erediti un vuoto:**
>   - **`QL-SHOWS-08` — stato prodotto IDENTICO.** `BOX5:333`: la pillola ▶ della lista e lo Start
>     del dettaglio devono produrre **la stessa cosa**. ⟦S5b⟧ costruisce **un** ingresso; il secondo
>     dovrà riusare questo, non replicarlo. ⚠️ E `BOX5:362` tiene la pillola **gated** finché
>     l'avvio non è cablato: ⟦S5b⟧ è ciò che toglie quel gate, **ma toglierlo non è in questa porta**.
>   - **Lo stato «sessione armata»** (`BOX5:324`, `BOX5:404`) lo **produce** questo atomo; il suo
>     **consumatore** è ⟦S4L⟧ (QL-SHOWS-04, Remove inerte). La forma tecnica è scelta CC.
>   - **Il count-in NON entra.** `LIBRO:166` lo ratifica con **tre** punti d'attivazione e **nessuno
>     dei tre è costruito**: non c'è nulla da spezzare, c'è una funzione da scrivere.
>   - **⟦S6F⟧ e ⟦S-EXIT⟧ non hanno scheda** (ratificati; `SCALETTA:325` registra il secondo buco).
>   - **Il ramo `else` resta `EmptyView()`**, guardia difensiva, nessun lavoro CD — precedente
>     identico nello stesso `switch` (`QLiveRootView.swift:105-107`).

---

# B2 · IL CENSIMENTO DELLE PORTE MANCANTI

## Il metodo, dichiarato prima dell'esito

**[A]** Non si può cercare «ciò che manca». Si cercano le **forme** in cui, in questo progetto, una
porta mancante si manifesta nel codice. Quattro sonde indipendenti su **62** file `.swift` dell'app
(test esclusi), ciascuna col suo controllo positivo:

| sonda | che cosa trova | esito | controllo positivo (forma diversa dall'esito cercato) |
|---|---|---:|---|
| **S1** | closure d'azione **vuota** dentro un `Button` | **1** | **12** bottoni con azione piena ⇒ la sonda distingue |
| **S2** | seam `var onX: () -> Void = {}` **mai valorizzato** | **1 su 5** | 4 seam su 5 **sono** valorizzati ⇒ non è un falso positivo di forma |
| **S3** | marcatori di rinvio (`stub`, `differit*`, `da aggiungere`, `richiede Layer 3`, `Fase successiva`, `non ancora`) | **29 righe su 15 file** | — |
| **S4** | `struct X: View` con **zero** siti di costruzione | **1 su 40** | **39** viste montate ⇒ la sonda trova i montaggi |

⚠️ **[A] Limite dichiarato del metodo:** S1–S4 trovano le porte che il **codice** tradisce. Una
capacità dichiarata da un canonico e **mai nemmeno abbozzata** nel codice non lascia traccia e
sfugge a tutte e quattro. Per quelle ho incrociato a mano `LIBRO`/`BOX5`, ed è così che è emerso il
count-in. **Il censimento sotto è completo rispetto alle quattro forme, non rispetto all'universo.**

## Le porte, una per riga

**[M]** «Raggiungibile col dito» = esiste un percorso di tocchi che produce l'effetto dichiarato.

| # | capacità dichiarata | dove è dichiarata | cosa manca, e dove | già tracciata |
|---|---|---|---|---|
| 1 | **avviare uno show** | `BOX5:331`, `BOX5:354` | closure vuota, `QLiveShowDetailView.swift:289` | **SÌ** — è ⟦S5b⟧ |
| 2 | **metronomo libero** dal pulsante METRONOME | `LIBRO:355` (modello a 5 punti), scheda ⟦S6⟧ | **entrambi** i montaggi inerti: `QLiveShowsView.swift:255` `MetroFAB()` → default `{}` (`MetroFAB.swift:20`); `QLiveEmptyStates.swift:168` passa `onMetroTap`, a sua volta `= {}` con **0** valorizzatori (`:146`) | **SÌ** — ⟦S6⟧ |
| 3 | **sezione precedente** in play | pulsantiera Vista LIVE, `BOX5` §Transport | `func prevSection() {}` — `AudioEngine.swift:1267` | ⛔ **NO** |
| 4 | **sezione successiva** in play | idem | `func nextSection() {}` — `AudioEngine.swift:1268` | ⛔ **NO** |
| 5 | **loop di sezione** | idem | `func toggleLoop() {}` — `AudioEngine.swift:1269` | ⛔ **NO** |
| 6 | **uscita d'emergenza** (`emerg`) | pulsantiera | closure vuota, `TransportView.swift:92` | **SÌ** — `TD-emerg-bottone-morto` |
| 7 | **RESTART SETLIST** a END SHOW | `LIBRO:153` (CD-3) | closure vuota, `FineSetlistView.swift:31` | **SÌ** — `TD-fineshow-bottoni-morti` (⚠️ e `LIBRO:353` ne ratifica la **rimozione**) |
| 8 | **RESTART** dall'overlay di stop | `LIBRO:225` (Q3=A) | `restartCurrentSong()` → `restartFromBeginning()` → `resetToSongStart()` **vuota** (`AudioEngine.swift:1566`) | ⛔ **NO** |
| 9 | **count-in**, tre punti d'attivazione | `LIBRO:166` | `startCountIn` stub (`:1561-1563`) + rinvio dichiarato (`SetlistRunner.swift:232`) | ⛔ **NO** |
| 10 | **export del backup** dall'app | capitolo backup | `BackupView` **mai montata** — 0 siti su 40 viste | **SÌ** — `TD-backup-restore-no-ui` |
| 11 | **MIDI azioni-contenuto** (Next/Prev Section, Next Song, Start Song, Loop) | MIDI Learn ratificato | log «richiede Layer 3», `AudioEngine.swift:1618-1620` | **SÌ** — `BUGS:283` |

⇒ **[M] UNDICI porte. Quattro non sono tracciate da nessuna parte: #3, #4, #5, #8, #9.**
(Sono cinque righe, quattro delle quali — #3, #4, #5, #8 — vivono **dentro la Vista LIVE**, cioè
sul palco.)

⚠️ **[M] Fuori tabella, e va detto perché non è lo stesso difetto:** §8 (creare/modificare uno
show) e le tab Shows/Media di Q-Stage sono **assenti dichiarate**, non porte morte — il «+» è
**omesso** per CD-Q7 (`QLiveShowsView.swift:20`, `ShowsListView.swift:42`) e le tab montano un
`QStagePlaceholderTab` (`QStageKit.swift:73-74`). **Una capacità assente e dichiarata tale non
inganna il dito.** Sono l'esatto contrario delle undici sopra.

## ⛔ E il censimento ha falsificato DUE righe di un canonico

**[M]** `BUGS_QBEATS.md:167`, dentro `TD-emerg-bottone-morto`, verbatim:

```text
167	- **Perimetro misurato:** la pulsantiera è fatta di **sei** `RubberBtnView` (`TransportView.swift:26`, `:30`, `:66`, `:72`, `:76`, `:90`), letti uno per uno con la propria azione. I primi cinque chiamano codice reale (`prevSection`, stop/`waitingForDirector`/`startSetlist`, `nextSection`, `toggleLoop`, `stopBacktrack`). **Il ses …[troncata, riga integrale a fonte]
```


**[M] Tre dei cinque «chiamano codice reale» chiamano funzioni VUOTE:**

```text
1265	    // Stub — implementazione in Fase Backtrack
1266	    func restartCurrentSong() { restartFromBeginning() }
1267	    func prevSection() {}
1268	    func nextSection() {}
1269	    func toggleLoop() {}
```


Controllo positivo, forma identica sullo stesso file: `stopBacktrack` (uno dei cinque) **ha un
corpo vero** — `AudioEngine.swift:1522-1526`, `audioQueue.async` + `backtrackPlayerNode.stop()`.
⇒ La sonda distingue le funzioni piene da quelle vuote; **tre delle cinque sono vuote.**

⇒ **La pulsantiera ha QUATTRO tasti muti su sei, non uno.** ⚠️ Resta vera una distinzione di
**forma** — `emerg` ha la closure vuota *sul posto*, gli altri tre chiamano una funzione *nominata
e vuota* — ma **per il dito l'effetto è identico**. La frase «Il sesto è l'unico muto» è
falsificata.

**[M]** E `BUGS_QBEATS.md:288` afferma: «`nextSection`/`prevSection` = equivalente UI mid-play
**ESISTE** … ⇒ MIDI = **mirror del TAP**». ⇒ **Falsificata dalla stessa misura:** il tap esiste,
l'effetto no. Cablare il MIDI a quei comandi lo farebbe **specchiare il vuoto**.

---

# B3 · DUE TICKET — misurato prima cosa è già tracciato

## ① Il count-in — **NON esiste nulla da allargare: è un ticket NUOVO**

**[M] Ricerca preventiva, con controllo positivo:** in `BUGS_QBEATS.md` → `startCountIn` **0**,
`countIn` **0**, `count-in` **1** e quella sola occorrenza sta in un ticket **di altro argomento**
(`:364`, scarto di un draft in `SongEditorView`). In `SCALETTA` → **0**.
Controllo positivo, forma identica su `BUGS`: `backtrack` → **20**. ⇒ La ricerca trova gli
argomenti tracciati. **Il count-in non è fra loro.**

**[M] E la capacità È RATIFICATA, con tre punti d'attivazione** — `LIBRO_MASTRO_QBEATS.md:166`:

```text
166	| `.countIn` | Count-in pre-canzone (4 click). Attivato in: (1) inizio prima song setlist, (2) tra canzoni, (3) Resume dopo STOP a metà song (ratificato 21/05 Q3=A — ri-sincronizzazione mentale batterista con band) | attivo |
```


⇒ **[M] Nessuno dei tre è costruito:** (1) l'inizio setlist non esiste affatto (è ⟦S5b⟧);
(2) fra le canzoni il rinvio è dichiarato (`SetlistRunner.swift:232`); (3) il Resume passa da
`startCountIn`, che è **uno stub**.
⚠️ **E il numero «4 click» spiega una costante che avevo dato per arbitraria in A115:** il
`countdown: 4` di `LiveView.swift:271` **è il valore ratificato** — viene **mostrato** e non
**suonato**. Correggo la mia lettura: non è un numero inventato, è il numero giusto senza il suono.

**[A] Titolo proposto:** `TD-countin-ratificato-mai-costruito` — «il count-in è ratificato con tre
punti d'attivazione e nessuno dei tre suona; il campo per-canzone si imposta e non viene mai letto».
**[A] Severità: PROPOSTA, non assegnata** — precedente `TD-mixer-copre-endshow` (`BUGS:159`).
La mia proposta è 🟠 **OPEN MEDIA**: non c'è perdita di dati e non c'è silenzio, ma
`LIBRO:225` registra che il motivo è **di palco** — «ri-sincronizzazione mentale del batterista con
la band» — e questo potrebbe valere di più di quanto pesi io. **Dominio:** CC (motore) + una metà
di prodotto, perché il punto (1) dipende da come ⟦S5b⟧ definisce l'ingresso.

## ② Il puntatore stale di `BOX5:324` — **nessun ticket di questa classe: è NUOVO**

**[M] Il fatto:** `BOX5_QBEATS.md:324` cita `ios_app/QBeats/Audio/AudioEngine.swift:370`. A HEAD
quel percorso rende **0 file**; il file vero è `ios_app/QBeats/AudioEngine.swift` (**1**), senza il
segmento `Audio/`. Riga e numero sono giusti, **il percorso no**.

**[M] Ricerca preventiva:** in `BUGS` → `Audio/AudioEngine` **0**, `BOX5:324` **0**. Esistono **tre**
ticket col lemma «stale» nel titolo, e **nessuno è di questa classe**: `TD-link-indicator-stale`
(indicatore runtime), `TD-linkkit-commenti-versione-stale` (**commenti nel codice**),
`TD-doccomment-navigate-zero-chiamanti` (**commenti nel codice**).
⇒ **La classe «puntatore stale dentro un CANONICO» non ha ticket.**

**[A] Due strade, e non scelgo io:** aprire `TD-box5-puntatore-audioengine-stale`, oppure
**allargare** `TD-doccomment-navigate-zero-chiamanti` a «puntatori stale» in genere — che avrebbe
il pregio di raccogliere anche **le ancore stale di quel ticket stesso**, misurate in A110
(cita `:85` e `:145`, a HEAD sono `:87` e altro).
**[A] Severità: PROPOSTA** — 🟡 **OPEN BASSA**: non tocca il comportamento, ma manda fuori strada
chi verifica, ed è in un canonico. **Dominio:** CC.

---

# B4 · DUE RIGHE PER MAURO

**Quante porte mancano: undici.** Sono le cose che il prodotto **dichiara di saper fare** e che oggi,
col dito, non si fanno: avviare uno show · il metronomo libero · sezione precedente · sezione
successiva · loop · emerg · restart a fine show · restart dopo uno stop · il count-in · l'export del
backup · i comandi MIDI di contenuto. **Sette erano già tracciate, quattro no** — e delle quattro non
tracciate **tre sono tasti della pulsantiera**, cioè roba che si tocca sul palco: `prev sez`,
`next sez` e `loop` **chiamano funzioni vuote**. ⚠️ Un canonico afferma il contrario
(`BUGS:167`, «il sesto è l'unico muto»): i muti sono **quattro su sei**.

**Quali stanno sul percorso di ⟦S5b⟧ e quali no.** Sul percorso ce n'è **una sola: la #1, avviare
uno show** — ed è esattamente ciò che l'atomo costruisce. Tutte le altre dieci **stanno a valle**:
si incontrano *dopo* che lo Start funziona, perché oggi nessuno può arrivarci. ⇒ **⟦S5b⟧ non le
causa e non le ripara: le rende raggiungibili**, ed è il motivo per cui al collaudo vanno riconosciute
come porte già mancanti e **non segnalate come guasti nuovi**.

---

## COSA NON HO FATTO

⛔ Nessun codice, nessun canonico toccato. Nel censimento **non ho proposto atomi, né ordine, né
tempi**, come disposto. Non ho assegnato severità. Non ho corretto i due difetti trovati in `BUGS`
(`:167`, `:288`): li ho misurati e li lascio al referee.

⚠️ **Lacuna dichiarata:** nessuna verifica indipendente, e il limite del metodo di B2 è scritto
sopra invece che taciuto — le quattro sonde trovano le porte che il **codice** tradisce, non quelle
che non ha mai nemmeno abbozzato.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `d00b9de698c8aa62bc1a438889fdbb3c41b5e2000667e0d282ab62bbd9691132`
- **byte** (file completo): `18302`
- **righe** (file completo): `277`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A117-PORTA-SOLA-CENSIMENTO-FINE*
