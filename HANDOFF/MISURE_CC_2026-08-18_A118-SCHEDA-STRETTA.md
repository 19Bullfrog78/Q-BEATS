# MISURE CC — A118, LA SCHEDA ⟦S5b⟧ STRETTA

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **SOLA LETTURA.** Nessun canonico modificato, zero righe sotto `ios_app/`, zero commit, zero
push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ FERMATA OBBLIGATORIA — A117 È STATO ESEGUITO, non è «mai eseguito»

**[M] Il mandato A118 dichiara che A116 e A117 non sono mai stati eseguiti. Per A116 è vero. Per
A117 no: l'ho eseguito e consegnato, e l'artefatto esiste su tutte e tre le gambe.**

| gamba | esito |
|---|---|
| repo `HANDOFF/MISURE_CC_2026-08-18_A117-PORTE.md` | **esiste** · 18 302 B |
| E: `…\FILE X CLAUDE.MD\HANDOFF\` | **esiste** · 18 302 B |
| Drive `Qbeats\` | **esiste** · 18 302 B |

sha256 identico sulle tre: `43e40e76363f038e05f39f0a1ab4ee423c253b2d661c1dcdfef310cf7d71b386`.
**[M]** `\bA116\b` in `HANDOFF/` → **1**, ed è la sola **menzione** dentro il referto A117 —
nessun artefatto A116 esiste. `\bA117\b` → **1 file**, che è l'artefatto stesso.

⇒ **[A] Lo dico invece di procedere in silenzio, perché il registro direbbe il falso in due modi:**
un artefatto orfano su tre supporti, e un ID bruciato che risulterebbe libero. **Non lo cancello e
non lo rinomino: non è mio compito deciderlo.** Il referee scelga se tenerlo agli atti o dichiararlo
nullo — ma la decisione va presa, non ereditata per distrazione.

⚠️ **Cosa contiene, perché conti nella scelta:** oltre al censimento (che questo mandato manda
giustamente fuori), A117 porta **due falsificazioni misurate su `BUGS_QBEATS.md`** — `:167`
(«il sesto è l'unico muto»: i tasti muti sono **quattro su sei**, perché `prevSection`,
`nextSection` e `toggleLoop` sono funzioni **vuote**) e `:288` («equivalente UI mid-play ESISTE»:
esiste il tap, non l'effetto). **Quelle due misure non dipendono dal censimento** e sopravvivono
alla scelta, comunque vada.

⇒ **In questo giro non rifaccio nulla di A117.** Eseguo A118 come chiesto: scheda, due ticket,
una riga.

---

# B1 · LA SCHEDA ⟦S5b⟧ — forma più stretta possibile

⚠️ **[A] Collocazione:** dopo ⟦S5⟧ (`SCALETTA:312`), prima di ⟦S6⟧. Porta la sezione B da **12**
a **13** intestazioni: il titolo «12 atomi» **va marcato, non riscritto**.

> ### ⟦S5b⟧ Start del dettaglio → player col primo brano ARMATO · POST · CI+DEVICE
>
> - **Scopo:** costruire **una porta sola** — dallo `.startfoot` del dettaglio al player, col primo
>   brano **armato in standby**. ⛔ **Finisce lì: cosa accade dopo il tocco dell'utente non è di
>   questo atomo.** Contratto: `BOX5_QBEATS.md:331` (QL-SHOWS-07 — «l'ingresso in uno show è
>   SEMPRE arma + standby, qualunque sia il flag standby della prima canzone») e
>   `BOX5_QBEATS.md:354` (§3 — «Start = arma + standby sulla prima canzone. Il click parte al
>   **secondo** tap (schermo ovunque) o via MIDI»).
>
> - **File — QUATTRO:**
>   - `UI/QLive/QLiveSession.swift` **EDIT** — il **mutatore dello slot**; è il file stesso ad
>     assegnarlo a questo atomo (`:14-15`).
>   - `UI/QLive/QLiveShowDetailView.swift` **EDIT** — costruire il runner (`setlist` a `:78`,
>     `store` a `:81`; `SetlistRunner.init(setlist:store:)` non chiede altro,
>     `SetlistRunner.swift:61`) e **chiudere il tocco** — `Cond (d)`.
>   - `UI/QLive/QLiveRootView.swift` **EDIT** — closure `() -> Void` iniettata al dettaglio nella
>     forma di `onBack` (`:104`): riempie lo slot, **poi** naviga. La closure non può essere
>     tipizzata sulla pagina: `QLivePage` è `private` (`:44`), `navigate(to:)` è `private` (`:88`).
>   - `SetlistRunner.swift` **EDIT** — accendere lo standby d'ingresso dentro `primeDisplay`
>     (`:271`), che ha **un solo chiamante** in tutto il corpus, già dentro l'`onAppear` del player
>     (`LiveView.swift:231`). ⛔ **Così `LiveView.swift` NON si tocca** e `LiveSession` resta privata.
>
> - **Reversibilità: PULITA.** `store.resolve(_:)` è puro (`QBeatsStore.swift:152-164`), l'`init`
>   del runner legge e logga, il mutatore assegna un `@Published` in RAM, `navigate` assegna uno
>   `@State`. **Zero disco, zero `UserDefaults`, zero iCloud, nessun cambio di formato dati** ⇒ un
>   revert dei quattro file non lascia nulla sul device. Dipendenza dura: ⟦S4R⟧. Ordine: dopo
>   ⟦S5a⟧ e ⟦S5x⟧.
>
> - **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE CHIUDE TRE CANCELLI DEVICE IN UN COLPO SOLO.**
>   Non è enfasi: è il motivo per cui non si può collaudare a metà.
>   - **il proprio** — lo Start arma e il player si monta fermo;
>   - **quello DIFFERITO di ⟦S5x⟧** — «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧»
>     (`SCALETTA:324`): END SHOW è irraggiungibile finché lo slot non ha mutatori;
>   - **l'armamento di `TD-mixer-copre-endshow`** — «SI ARMA CON ⟦S5b⟧, NON PRIMA» (`BUGS:158`).
>   - **CI:** verde su `iOS Signed Build`. ⚠️ `F1 — Build Check` non gira dal 31/07 e le ultime due
>     run sono fallite: **non conta come cancello finché Mauro non decide**.
>   - **Passo (1) — e distingue «armato» da «fermo»:** da un dettaglio con brani risolti, tocca
>     **START SHOW**. ✅ Deve comparire il **titolo della PRIMA canzone**, grande e centrato in
>     alto, **che pulsa lentamente**, sopra il player **visibilmente oscurato**; **non deve suonare
>     nulla**. ⛔ Se la videata è piena e nitida, o il titolo manca, o c'è ma **immobile**:
>     **FALLITO** — il player è fermo, non armato.
>     *(Segni misurati, verificabili a occhio senza alcun disegno CD: `LiveView.swift:129`
>     opacità **0,10** sul player · `StandbyOverlayView.swift:18-24` titolo **52 pt** al **27 %**
>     dell'altezza · `:31-35` pulse **0,45↔1,0 in 2,2 s**, all'infinito.)*
>   - **Passo (2):** tocca lo schermo **in un punto qualsiasi** → il click parte **da quella
>     canzone** (`LiveView.swift:134-137`, `.contentShape(Rectangle())` + `onTapGesture` →
>     `runner.startCurrentSong`).
>   - **Passo (3):** fine setlist → END SHOW → **BACK TO SHOWS** torna alla lista (gate di ⟦S5x⟧).
>   - **Passo (4):** esci dalla stanza → l'audio si ferma (`AppRootView.swift:74`).
>   - ⛔ **NON-DIFETTI — da NON segnalare come guasti:** al tocco la musica parte **subito, senza
>     conto**. `startCountIn` è uno **stub** (`AudioEngine.swift:1561-1563`) e fra le canzoni il
>     rinvio è **dichiarato nel codice** (`SetlistRunner.swift:232`). ⇒ È una porta già mancante,
>     **non una regressione di ⟦S5b⟧**.
>   - ⚠️ Col percorso DEBUG vale la procedura sicura di
>     `TD-injecttestdata-sovrascrive-dati-reali` (`BUGS:143`): **non toccare NESSUNA Song** mentre i
>     dati di test sono in RAM.
>
> - **Cond — cinque, tutte necessarie:**
>   - **(a) ORDINE OBBLIGATO: riempi lo slot, POI naviga.** Invertendo si apre un frame con
>     `page == .metronome` e `runner == nil`, e il ramo `else` **si vede**. L'irraggiungibilità di
>     quel ramo è **conseguenza di questa condizione**, non un fatto indipendente.
>   - **(b) STATO D'INGRESSO = arma + standby sulla PRIMA canzone**, non `.stopped`.
>     ⚠️ Il payload esiste già e regge, **misurato**: `nextSongName` è calcolato **dopo**
>     `currentSongIdx += 1` (`SetlistRunner.swift:343-345`), quindi significa «la canzone che
>     partirà al prossimo tap» — all'ingresso, con indice 0, **è la prima**. E l'obiezione storica
>     non si applica: `LiveSession.swift:30-34` tolse lo standby d'ingresso il 17/05 (TD #28)
>     perché mostrava un **em-dash**, cioè uno standby **senza nome vero**; con un runner armato il
>     nome c'è.
>   - **(c) GUARDIA SUL RI-ARMAMENTO.** `primeDisplay` gira a **ogni** `onAppear`, non solo al
>     primo. Senza guardia si potrebbe rimettere in standby uno show **già in esecuzione** a una
>     ricomparsa della vista. ⚠️ **È qui che lo stato armato guadagna il suo posto:** distinguere
>     «armato e mai partito» da «già partito».
>   - **(d) IL TOCCO SI CHIUDE quando `resolve().songs` è VUOTO.** Oggi `isEnabled`
>     (`QLiveShowDetailView.swift:288`) pilota **solo** ombra (`:323`), bordo (`:326-331`) e
>     opacità (`:333`): `.disabled(` nel file rende **0**, mentre il corpus lo usa in **6 file**.
>     Senza questa condizione un tocco su una scaletta orfana costruisce un runner a catalogo vuoto,
>     `primeDisplay` esce al primo `guard` (`SetlistRunner.swift:272`) e **il player si monta bianco**.
>   - **(e) NIENTE STOP AUDIO AGGANCIATO ALLA NAVIGAZIONE MENTRE IL CLICK GIRA**
>     (`QLiveRootView.swift:78-85`, decisione CD 18/07). ✅ Non vieta l'azzeramento di **stato** a
>     END SHOW, dove il playback è già finito (`LiveView.swift:161`): **igiene, non transport**.
>
> - **Modello raccomandato alla costruzione:** Opus — quattro file e due regole (`Cond (a)` ordine,
>   `Cond (c)` guardia) che il compilatore non può verificare.
>
> - **OPEN — fuori da questa porta, nominati perché il cancello non erediti un vuoto:**
>   - **`QL-SHOWS-08` — stato prodotto IDENTICO.** `BOX5:333`: la **pillola ▶** della lista e lo
>     Start del dettaglio devono produrre **la stessa cosa** — «stessa azione, modalità di default,
>     nessuna domanda». ⇒ ⟦S5b⟧ costruisce **un** ingresso; il secondo dovrà **riusarlo**, non
>     replicarlo. ⚠️ E `BOX5:362` tiene la pillola **gated** («tratteggiata, icona spenta,
>     inerte») finché l'avvio non è cablato: ⟦S5b⟧ è ciò che **permette** di togliere quel gate,
>     **ma toglierlo non è in questa porta**.
>   - **Lo stato «sessione armata»** (`BOX5:324`, `BOX5:404`) lo **produce** questo atomo — «nasce
>     insieme all'arma + standby» — e il suo **consumatore** è ⟦S4L⟧ (QL-SHOWS-04, Remove
>     inerte a sessione armata). La **forma tecnica** è scelta CC, per simmetria con `BOX5:401`.
>   - **Il count-in NON entra.** Ratificato con **tre** punti d'attivazione (`LIBRO:166`) e
>     **nessuno dei tre è costruito**. ⛔ Non c'è nulla da spezzare: c'è una funzione da scrivere,
>     che è altro. Ticket proposto in B2.
>   - **⟦S6F⟧ e ⟦S-EXIT⟧ non hanno scheda**, entrambi ratificati (`SCALETTA:325` registra il
>     secondo buco).
>   - **Il ramo `else` resta `EmptyView()`**, guardia difensiva, **nessun lavoro CD** — precedente
>     identico nello stesso `switch` (`QLiveRootView.swift:105-107`). ⚠️ Il commento a `:162-169`
>     chiede ancora un empty-state a ⟦S5⟧: superato dalla cancellazione dell'A3 (`LIBRO:355`),
>     **va marcato, non riscritto**.

---

# B2 · DUE TICKET — misurato prima cosa è già tracciato

## ① Il count-in — **non c'è nulla da allargare: è NUOVO**

**[M] Ricerca preventiva, con controlli positivi nella forma identica:**

| ricerca | dove | esito |
|---|---|---:|
| `startCountIn` | `BUGS_QBEATS.md` | **0** |
| `countIn` | `BUGS_QBEATS.md` | **0** |
| `count-in` | `BUGS_QBEATS.md` | **1** — e sta a `:364`, dentro un ticket di **altro argomento** (scarto silenzioso di un draft in `SongEditorView`) |
| `count-in` | `SCALETTA` | **0** |
| **controllo positivo** `backtrack` | `BUGS_QBEATS.md` | **20** |
| **controllo positivo** `standby` | `BUGS_QBEATS.md` | **17** |

⇒ La ricerca trova gli argomenti che il tracker segue davvero. **Il count-in non è fra loro, e
non esiste alcun rinvio tracciato da allargare.**

**[M] E la capacità È RATIFICATA, con tre punti d'attivazione** — `LIBRO_MASTRO_QBEATS.md:166`:

```text
166	| `.countIn` | Count-in pre-canzone (4 click). Attivato in: (1) inizio prima song setlist, (2) tra canzoni, (3) Resume dopo STOP a metà song (ratificato 21/05 Q3=A — ri-sincronizzazione mentale batterista con band) | attivo |
```


**[M] Nessuno dei tre è costruito:**
**(1)** l'inizio setlist non esiste affatto — è ciò che ⟦S5b⟧ costruisce;
**(2)** fra le canzoni il rinvio è **dichiarato nel codice**:

```text
231	        // 6: parte la catena audio.
232	        // L1.b v1: niente count-in tra canzoni. Da aggiungere in iterazione successiva.
233	        audioEngine.start()
```


**(3)** il Resume dopo stop passa da `startCountIn`, che è **uno stub**:

```text
1560	    // L3 stub — sostituito da Layer 3 quando disponibile.
1561	    private func startCountIn(for section: String?) {
1562	        start()
1563	    }
```


⚠️ **[M] E il numero «4 click» spiega una costante che in A115 avevo dato per arbitraria:** il
`countdown: 4` di `LiveView.swift:271` **è il valore ratificato**. Viene **mostrato** e non
**suonato**. **Correggo la mia lettura:** non è un numero inventato, è il numero giusto senza suono.

**[A] Titolo proposto:** `TD-countin-ratificato-mai-costruito` — «il count-in è ratificato con tre
punti d'attivazione e nessuno dei tre suona; il campo per-canzone si imposta e non viene mai letto».
**[A] Severità: PROPOSTA, non assegnata** — precedente `TD-mixer-copre-endshow` (`BUGS:159`).
La mia proposta è 🟠 **OPEN MEDIA**: non c'è perdita di dati né silenzio sul palco. ⚠️ Ma
`LIBRO:225` registra che il motivo è **di palco** — «ri-sincronizzazione mentale del batterista con
la band, necessaria per partenza uniforme» — e questo può valere più di quanto pesi io.
**Dominio:** CC.

## ② Il puntatore stale di `BOX5:324` — **classe non tracciata: è NUOVO**

**[M] Il fatto, rimisurato a HEAD:** `BOX5_QBEATS.md:324` cita
`ios_app/QBeats/Audio/AudioEngine.swift:370`.

| misura | esito |
|---|---|
| il percorso **citato** esiste a HEAD? | **0 file** |
| il percorso **reale** `ios_app/QBeats/AudioEngine.swift` | **1 file** |
| e la riga `:370` di quel file dice | `    private var backtrackArmed: Bool = false` |

⇒ **Riga e contenuto sono GIUSTI; è sbagliato il solo percorso** — un segmento `Audio/` di
troppo. Non intacca la sostanza della riga (lo stato armato non esiste a HEAD): **manda fuori strada
chi va a verificare**.

**[M] Già tracciato?** In `BUGS_QBEATS.md`: `Audio/AudioEngine` → **0**, `BOX5:324` → **0**.
Esistono **tre** ticket col lemma «stale» nel titolo e **nessuno è di questa classe**:
`TD-link-indicator-stale` (indicatore **runtime**), `TD-linkkit-commenti-versione-stale`
(**commenti nel codice**), `TD-doccomment-navigate-zero-chiamanti` (**commenti nel codice**).
⇒ **La classe «puntatore stale dentro un CANONICO» non ha ticket.**

**[A] Due strade, e non scelgo io:**
**(i)** aprire `TD-box5-puntatore-audioengine-stale`, oppure
**(ii)** **allargare** `TD-doccomment-navigate-zero-chiamanti` da «commenti stale» a «puntatori
stale» — che avrebbe il pregio di raccogliere anche **le ancore stale di quel ticket stesso**
(cita `:85` e `:145`; a HEAD il bersaglio è `:87`).
**[A] Severità: PROPOSTA** — 🟡 **OPEN BASSA**: zero effetto sul comportamento, ma è in un
canonico e i canonici sono ciò su cui si verifica. **Dominio:** CC.

---

# B3 · UNA RIGA PER MAURO

**Cosa vedrai sul telefono dopo aver premuto START.** Lo schermo del metronomo si apre già pieno dei
dati del primo brano, ma **spento e in attesa**: tutto il pannello si abbassa di luminosità, e al
centro-alto compare il **nome della prima canzone in caratteri grandi, che respira** — si schiarisce
e si spegne piano, ogni due secondi circa. **Non suona niente, ed è giusto così: lo Start carica, non
parte.** Quando sei pronto tocchi lo schermo **in un punto qualsiasi** e il click parte da quella
canzone — **subito, senza conto alla rovescia**, perché il count-in non è ancora costruito
(è il ticket qui sopra, non un guasto).
⇒ **Se invece vedi la videata nitida e ferma, senza il nome che pulsa, il collaudo è FALLITO:**
vuol dire che il player si è aperto ma lo show non è stato armato.

---

## COSA NON HO FATTO

⛔ Nessun codice, nessun canonico toccato, nessuna ratifica chiesta. **Il censimento delle porte
non l'ho rifatto**, come disposto — e non l'ho nemmeno citato oltre la fermata in testa.
Non ho assegnato severità. Non ho scritto le schede di ⟦S6F⟧ e ⟦S-EXIT⟧.

⚠️ **Lacuna dichiarata:** nessuna verifica indipendente.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `54be36395970781cff4dd58f1c1ecf3297d10f76e29ac5965a2d0e11a89f80f2`
- **byte** (file completo): `16899`
- **righe** (file completo): `283`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A118-SCHEDA-STRETTA-FINE*
