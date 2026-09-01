# MISURE CC — A115, IL COUNT-IN: MECCANISMO INTERO

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **SOLA LETTURA.** Nessun canonico modificato, zero righe sotto `ios_app/`, zero commit, zero
push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`. A114 non eseguito.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

## L'ERRORE DI METODO — la terza sonda sbagliata di oggi

**[A] Il rilievo è fondato.** In A113 ho misurato **un campo** — `Song.countIn` — e ho concluso
sul **meccanismo**: «il count-in della spec non esiste nel codice». È §7, *meccanismo intero, non
la prima costante*, e l'ho violato.

⚠️ **E va detto per intero, perché è la parte che conta:** la conclusione **regge** — ma per
ragioni che **non avevo misurato**, e sarebbe potuta andare al contrario senza che me ne accorgessi.
Un metodo che arriva alla risposta giusta per caso non è un metodo. È la terza volta oggi, dopo
`Gate:` (sonda cieca alla punteggiatura) e dopo aver risposto a una domanda di spec col codice.

---

# B1 · IL MECCANISMO, DALL'INIZIO ALLA FINE

## Premessa: `countIn` nel corpus è **TRE oggetti diversi**, e in A113 ne avevo censiti due

**[M]**

| # | oggetto | dove | che cos'è |
|---|---|---|---|
| ① | `Song.countIn: Int` | `Models/Song.swift:21` | **dato dell'utente** — «0=nessuno, 1=1 battuta, 2=2 battute» |
| ② | `AudioEngine.PlaybackState.countIn` | `AudioEngine.swift:26` | **stato del motore** |
| ③ | `LivePlaybackState.countIn(countdown: Int)` | `Models/LivePlaybackState.swift:5` | **stato di UI**, con un contatore |

⛔ **In A113 avevo nominato ① e ③ e mi era sfuggito ②** — che è proprio quello da cui parte il
meccanismo. Da lì l'errore.

## 1 · Chi accende lo stato, in quali percorsi, con quali condizioni

**[M] Un solo sito accende ②**, e non ha condizioni: `AudioEngine.swift:1247-1254`

```text
1247	    func resumeFromCurrentSection() {
1248	        os_log("[Q-BEATS][UX-3] resumeFromCurrentSection → countIn",
1249	               log: .default, type: .default)
1250	        DispatchQueue.main.async { [weak self] in
1251	            self?.playbackState = .countIn
1252	        }
1253	        startCountIn(for: currentSection)
1254	    }
```


**[M] `resumeFromCurrentSection` ha esattamente DUE chiamanti in tutto il corpus:**

| chiamante | percorso |
|---|---|
| `UI/Live/OverlayStopView.swift:17` | il bottone **RESUME** dell'overlay di stop (UX-3) |
| `DebugView.swift:198` | un bottone di **debug** |

⇒ **[M] Nessun altro percorso accende il count-in.** In particolare **non lo accende l'avvio di una
canzone**, né il primo né quelli successivi.

## 2 · Che cosa ne determina la DURATA — **niente, perché non c'è durata**

**[M]** `startCountIn` è la funzione che dovrebbe suonarlo. Verbatim, `AudioEngine.swift:1560-1566`:

```text
1560	    // L3 stub — sostituito da Layer 3 quando disponibile.
1561	    private func startCountIn(for section: String?) {
1562	        start()
1563	    }
1564	
1565	    // L3 stub — sostituito da Layer 3 quando disponibile.
1566	    private func resetToSongStart() {}
```


⛔ **È UNO STUB.** Ignora il parametro `section` e chiama `start()`. **Non conta battute, non
emette click di conto, non attende: fa partire l'audio immediatamente.**
Il commento lo dichiara: «L3 stub — sostituito da Layer 3 quando disponibile».

**[M] Controllo positivo in forma LESSICALE DIVERSA dalla sonda** (non la parola «countIn»):
nello **stesso file** ci sono **23** `private func`; le marcate «L3 stub» sono **due**
(`:1560` `startCountIn`, `:1565` `resetToSongStart`), ed entrambe hanno corpo vuoto o di una riga.
⇒ La forma «L3 stub» identifica davvero le funzioni non implementate, e non è un'etichetta
generica: 2 su 23.

⇒ **[M] La durata non viene da `Song.countIn`, né da un default, né da una costante di motore:
NON ESISTE.** L'unico numero che somiglia a una durata è in UI ed è **finto**:
`LiveView.swift:270-271` mappa lo stato di motore su quello di UI con un valore **costante**:

```text
268	                    session.beatActive = 0
269	                }
270	            case .countIn:
271	                session.playbackState = .countIn(countdown: 4)
272	            case .playing:
```


⇒ Quel `4` non conta nulla: è un'etichetta di visualizzazione, non un conteggio.

## 3 · Che cosa ne determina il BPM — l'invariante `BOX5:460` **non ha nulla da governare**

**[M]** L'invariante, verbatim:

```text
460	| Count-in BPM | Prima sezione canzone target |
```


⇒ **[M] Non è verificabile contro il codice, e non perché sia violato: perché non c'è codice che
lo possa violare.** `startCountIn(for:)` riceve `currentSection` e **lo scarta**; `start()` usa il
BPM corrente del motore. Non esiste un ramo che scelga un BPM «di count-in».
⚠️ **È un invariante di INTENTO, non una descrizione dello stato corrente.** Dice quale BPM dovrà
usare il count-in **quando sarà costruito**, ed è esattamente il genere di riga che serve prima di
costruirlo. Non prova che esista.

## 4 · Dove finisce — all'ultimo click di che cosa?

**[M] Non finisce, perché non comincia.** La sequenza reale, per il solo percorso che lo accende:
lo stato ② viene posato su main (`:1250-1252`), poi `startCountIn` chiama `start()` (`:1562`) e
**l'audio parte subito**. Lo stato torna a `.playing` per la normale meccanica del motore, senza
alcun evento di «fine count-in».
**[M]** Non esiste nel corpus alcun simbolo di terminazione del conto: cercati
`countInEnded|countInFinished|endCountIn|countInComplete` → **0 file**; controllo positivo in forma
identica (stesso suffisso `Ended` su un evento che esiste) `sectionEnded` → **4 file**, fra cui la
dichiarazione `let sectionEndedSubject = PassthroughSubject<Void, Never>()`
(`AudioEngine.swift:166`). ⇒ **Lo zero non è della sonda: gli eventi di fine, quando esistono, li
trova.**

---

# B2 · LA DOMANDA CHE DECIDE — la catena si interrompe **DUE volte**

**Domanda:** il count-in fra le canzoni è comandato da `Song.countIn`, o da altro?

**[M] RISPOSTA: da nulla. Il count-in fra le canzoni NON ESISTE, e il codice lo dichiara.**
`SetlistRunner.swift:231-233`, verbatim:

```text
231	        // 6: parte la catena audio.
232	        // L1.b v1: niente count-in tra canzoni. Da aggiungere in iterazione successiva.
233	        audioEngine.start()
```


⇒ «**L1.b v1: niente count-in tra canzoni. Da aggiungere in iterazione successiva.**» — e subito
sotto `audioEngine.start()`, che parte senza conto.

## La catena, anello per anello

| anello | stato | riga |
|---|---|---|
| l'utente imposta il valore | ✅ **c'è** | `UI/QStage/SongEditorView.swift:34`, un `Picker` su `$draft.countIn` |
| il valore si salva e si ricarica | ✅ **c'è** | `Models/Song.swift:60` (decode), `QBeatsBackupManager.swift:217` (backup) |
| **qualcuno lo LEGGE per suonare** | ⛔ **ROTTO** | **0** letture del campo in `SetlistRunner.swift` + `UI/Live/` |
| **la funzione che suonerebbe il conto** | ⛔ **ROTTO** | `AudioEngine.swift:1561` è uno **stub** |

⇒ **[M] Due interruzioni INDIPENDENTI.** Riparare la prima non basterebbe: anche passando il
valore, `startCountIn` lo scarterebbe. **Questo è ciò che in A113 non avevo misurato** — avevo
visto solo il primo anello.

## ⚠️ La sonda che stavo per sbagliare una quarta volta

**[M]** Cercare `countIn` nei percorsi d'avvio rende **4 file** — e sembrerebbe che qualcuno il
campo lo legga. **È un falso positivo:** tutte e quattro le occorrenze sono lo **stato ③**
(`BarCounterView`, `LiveView`, `TeleprompterCapsuleView`, `TransportView`), non il campo.
⇒ Ho separato le due cose con sonde che **non possono confondersi**:

| sonda | forma | esito |
|---|---|---|
| **il CAMPO** | preceduto da un ricevitore: `(song\|currentSong\|draft)\??\.countIn` | **2 siti in tutto il corpus** — `QBeatsBackupManager.swift:217` (backup) e `SongEditorView.swift:34` (il `Picker`) |
| **lo STATO** | `case \.?countIn` oppure `\.countIn\(` | **8 siti su 6 file** |
| **il CAMPO nei percorsi d'avvio** (`SetlistRunner.swift` + `UI/Live/`) | stessa forma del campo | **ZERO** |

**[M] Controllo positivo, forma IDENTICA — stesso ricevitore, altro campo:**
`(song\|currentSong)\??\.sections` → **1** · `(song\|currentSong)\??\.name` → **1**.
⇒ La sonda trova i campi di `Song` che qualcuno legge davvero negli stessi percorsi.
**`countIn` non è fra quelli, e lo zero non è della sonda.**

---

# B3 · LA SETLIST DI TEST — **entrambe le canzoni hanno `countIn: 0`**

**[M]** Verbatim, `DebugView.swift:517-534`:

```text
517	        let songA = Song(id: UUID(), name: "Test Song A",
518	                         sections: [intro, verse, bridge],
519	                         countIn: 0, backtrackFilename: nil)
520	
521	        // Song B — 2 sezioni
522	        let slow  = SongSection(name: "Slow 90",   bpm: 90,  beatsPerBar: 4, beatUnit: 4,
523	                                repetitions: 3,  notes: "", accentPattern: [2,1,1,1],
524	                                subdivisionMultiplier: 1, swingRatio: 0.5)
525	        let build = SongSection(name: "Build 110", bpm: 110, beatsPerBar: 4, beatUnit: 4,
526	                                repetitions: 12, notes: "", accentPattern: [2,1,1,1],
527	                                subdivisionMultiplier: 1, swingRatio: 0.5)
528	        let songB = Song(id: UUID(), name: "Test Song B",
529	                         sections: [slow, build],
530	                         countIn: 0, backtrackFilename: nil)
531	
532	        // Setlist
533	        let setlist = Setlist(id: UUID(), name: "Test Setlist L1.b",
534	                              date: Date(), songIDs: [songA.id, songB.id])
```


**[M]** E non è un caso isolato: **tutte e nove** le occorrenze di `countIn:` in `DebugView.swift`
valgono **`0`** (`:519, 530, 559, 580, 609, 644, 686, 715, 757`). **Nessun dato di test attiva il
campo.**

⇒ **[M] La prova per differenza che il mandato cerca — una canzone con count-in e una senza —
NON È ESEGUIBILE con i dati di test attuali:** non c'è la coppia da confrontare.
⚠️ E anche se ci fosse, non si sentirebbe: il secondo anello è uno stub.

---

## ⚠️ SU CIÒ CHE MAURO HA SENTITO — quello che posso misurare e quello che non posso

**[A] Non posso misurare il device di Mauro, e non dico che ricordi male.** Dico che cosa dice il
codice a HEAD, e offro l'unico candidato misurabile.

**[M] Le quattro fonti citate nel mandato reggono tutte, ma dicono una cosa diversa da «il
count-in suona»:**

- `BOX5:451` — parla del **pattern di allineamento di stato** in `stop()`, e cita `.countIn` come
  uno degli stati che quel pattern già tocca. È sul **dispatch di `playbackState`**, non sul suono.
- `BOX5:460` — è l'**invariante di intento** sul BPM, misurato sopra: non ha implementazione.
- `BOX5:449` — riguarda la **closure di fine sezione** e le tre cose che può decidere; non nomina
  il count-in.
- freeze CD 18/07 — «Solo in play (`playing` + `countIn`)»: è il perimetro del **gate d'uscita**,
  che considera `.countIn` uno stato di play. Corretto, e indipendente dal fatto che suoni.

⇒ **[A] Le fonti stabiliscono che `.countIn` è uno stato RICONOSCIUTO dal disegno.** Non
stabiliscono che un conto si senta. Le due cose sono compatibili, ed è esattamente lo stato dell'app
a HEAD.

**[A] L'unico candidato misurabile per un conto UDIBILE, e non lo affermo:** in configurazione
**due device con Link**, il Follower non entra subito — aspetta il confine di battuta. Il codice lo
descrive così, `AudioEngine.swift:762-763` e `:771-774`:

```text
762	            // === Bug 2.b ramo X — SEED contatore sezione del Follower ===
763	            // Il Follower entra dopo il count-in del Director (≥1 bar).
764	            // _sectionBeatCounter è già stato azzerato da loadSection (936-944)
765	            // e da start() (~634), ENTRAMBI prima di questo work item ritardato.
766	            // Seminiamo QUI, PRIMA del pre-roll sottostante: il primo
767	            // scheduleNextBuffer emette già il primo beat (resetForStart fissa
768	            // _exactNextBeatSample=0 → beat al sample 0) che fa
769	            // _sectionBeatCounter += 1. Seminare dopo il pre-roll = off-by-one.
770	            //
771	            // startBeat = fase allineata alla sessione Link al momento del join
772	            // (≈ bar saltati nel count-in del Director). È within-section e NON
773	            // si accumula tra brani perché il Director rimappa Link a beat 0 a
774	            // ogni canzone (link_engine_start_at_beat_zero, LinkEngine.mm:427-445).
```


⇒ «Il Follower entra **dopo il count-in del Director**» — e nota che dice *del Director*, cioè
dell'**altro** apparecchio o dell'altra app, non di Q-BEATS. Su due device quel ritardo di
allineamento **si sente**, e somiglia molto a un conto. ⚠️ **Resta [A]: non l'ho provato, e per
provarlo serve il device.**

---

# B4 · COSA CADE DI QUANTO GIÀ DETTO

⚠️ **[M] A114 non l'ho mai scritto** — è stato sospeso prima che lo eseguissi, e non esiste alcun
artefatto a mia firma con quell'ID. Elenco quindi solo ciò che cade di **A113**. Se A114 conteneva
decisioni del referee su questa materia, la revisione spetta a lui.

**Da A113, sezione B3:**

1. ⛔ **CADE il METODO**, non la conclusione: «il campo `Song.countIn` è scritto dall'editor e non
   è letto da nulla che avvii l'audio» era **una misura su un anello solo**, presentata come
   verdetto sul meccanismo.
2. ⛔ **CADE il censimento**: avevo scritto che «le occorrenze di `countIn` che restano sono un
   altro oggetto: lo stato di UI». **Gli oggetti sono TRE, non due**, e quello che mi mancava
   (`AudioEngine.PlaybackState.countIn`, `:26`) è il capo del meccanismo. Il censimento era
   **incompleto**, e per questo la frase è fuorviante anche dove non è falsa.
3. ✅ **REGGE, e va RAFFORZATA**: «il count-in configurato per canzone oggi non lo suona nessuno».
   La misura vera è **più netta** di quella che avevo dato: non è solo che il campo non viene
   letto — **la funzione che dovrebbe suonarlo è uno stub** (`AudioEngine.swift:1561`), e fra le
   canzoni il codice dichiara di non farlo affatto (`SetlistRunner.swift:232`).
4. ✅ **REGGE, e ora ha una ragione più forte**: la proposta di **spezzare ⟦S5b⟧** e portare il
   count-in in un atomo suo. In A113 l'argomento era «non è cablaggio, è dominio audio»; ora è
   **misurato**: è implementare uno stub nel motore **e** passare il dato dal Layer 3, cioè due
   lavori in due strati.
5. ⚠️ **RIDIMENSIONATA**: «⟦S5b⟧ la rende soltanto visibile, come per END SHOW». È vero per
   l'ingresso in uno show, ma **incompleto**: il buco esiste già oggi **anche fra le canzoni**, ed
   è **dichiarato nel codice** come rinvio esplicito («da aggiungere in iterazione successiva»),
   non come dimenticanza.

**Da A113, altrove:** nulla d'altro dipende da questa misura. Le conclusioni su arma + standby,
sul quarto file, sullo stato armato e sul cancello cieco **non passano** per il count-in.

---

# B5 · DUE RIGHE PER MAURO

**Il campo che imposti in Q-Stage comanda quello che senti? ⛔ NO.** Il selettore «Count-in»
nell'editor salva il valore e lo conserva anche nei backup, ma **nessuno lo legge quando parte la
musica** — e anche se lo leggesse non cambierebbe nulla, perché la funzione che dovrebbe suonare il
conto è **vuota**: fa partire il click e basta. Fra una canzone e l'altra il codice è ancora più
esplicito: c'è scritto «niente count-in tra canzoni, da aggiungere dopo».

**Cosa lo dimostra.** Tre misure indipendenti, e ognuna basterebbe da sola: **(1)** la funzione
`startCountIn` (`AudioEngine.swift:1561`) ignora ciò che riceve e chiama direttamente l'avvio;
**(2)** `SetlistRunner.swift:232` dichiara per iscritto che fra le canzoni il conto non c'è;
**(3)** le due canzoni della setlist di test hanno **entrambe** count-in **0**, quindi con quei
dati non c'è nemmeno una differenza da ascoltare. ⚠️ Se su due apparecchi in Link hai sentito un
ritardo prima che il secondo entrasse, quello **c'è davvero** ma è un'altra cosa: è l'attesa del
confine di battuta di Link, che il codice chiama «count-in **del Director**».

---

## COSA NON HO FATTO

⛔ Nessun codice, nessun canonico toccato, nessuna proposta di fix. Non ho riscritto le
affermazioni di A113: le ho elencate, come disposto.

⚠️ **Lacuna dichiarata:** nessuna verifica indipendente. E oggi è la terza volta che un mio errore
di sonda viene intercettato dal referee e non da me — su `Gate:`, sulla spec, e qui.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `dcb20c9da516a6d6d0013703f63c7495b513714aa32e46997fc51143337a05bc`
- **byte** (file completo): `17480`
- **righe** (file completo): `347`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A115-COUNTIN-MECCANISMO-FINE*
