# MISURE CC — A110, PROPOSTA DELLA SCHEDA ⟦S5b⟧

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **QUESTO GIRO PROPONE, NON INCIDE.** Nessun canonico è stato modificato: zero righe sotto
`ios_app/`, zero commit, zero push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`.
⛔ **Non chiedo ratifica in questo giro.** Il testo qui sotto è una proposta da misurare, non un
diff da applicare.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio o proposta mia.

**[M]** A109 ignorato: la bozza del referee **non è stata letta né ripresa**. Ciò che segue nasce da
A99, A102, A103, A105, A108 e dalle misure di oggi.

---

## ① I CINQUE PALETTI — controllati PRIMA di usarli

Il mandato dice: se un paletto è sbagliato, fermarsi. Li ho verificati tutti e cinque.
**[M] Reggono tutti. Procedo.** Ma quattro li avevo già misurati, e **uno no** — quello lo dichiaro
per esteso, perché fino a stamattina non avevo la fonte.

| paletto | esito | fonte |
|---|---|---|
| ① lo Start carica, non avvia | **REGGE** | coincide col primo ramo del bivio di A103; nessuna delle tre porte di avvio scatta al montaggio (A108 ②) |
| ② `LiveView` intatta, `LiveSession` privata, i due tipi non si riconciliano | **REGGE** | `LiveView.swift:11` la crea `private`; la riconciliazione era già **degradata a domanda aperta** da `SCALETTA:308` |
| ③ il ramo `else` è guardia difensiva | **REGGE** | precedente verbatim nello stesso `switch`, `QLiveRootView.swift:100-107` (A108 ③) |
| ④ non si accorpa RESTART SETLIST | **REGGE** | `LIBRO:353` ratifica il **comportamento**, e `SCALETTA:311` lo dice esplicito |
| ⑤ il secondo show si copre con la fascia PLAYING, non nello Start | **REGGE — e l'ho verificato oggi** | vedi sotto |

### Il paletto ⑤, misurato a fonte perché non l'avevo

**[M]** La ratifica di ⟦S6F⟧ (`LIBRO_MASTRO_QBEATS.md:334`) **non contiene la spec**: dichiara di
possedere «l'ESISTENZA dell'atomo e la sua COLLOCAZIONE, non il disegno» e **indirizza al freeze**.
Quindi il paletto non si verifica in LIBRO: si verifica nel freeze. L'ho aperto.

**[M]** `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html:285`, verbatim — e la frase che decide
è la seconda:

> «Compare **solo in play**, in fondo alle superfici Shows, **al posto** del metrofab (lista) /
> **dello startfoot (dettaglio)**: mentre suona, la porta al metronomo **è ciò che sta suonando**.»

**[M]** `startfoot` rende **1** occorrenza in tutto il freeze, ed è questa. Controlli positivi
stessa forma stesso file: `fascia` → **21**, `Q-LIVE · PLAYING` → **1**, `mini-player` → **1**.
E i sei frame si spartiscono come la ratifica dichiara: quattro «Exit gate over …» + due
«… in play», di cui il secondo è **«Show detail / Q-Live · in play [fascia + switch gated]»**.

⇒ **Il paletto ⑤ è esatto e sorgentato: quando qualcosa suona, lo `.startfoot` NON C'È — al suo
posto c'è la fascia.** Il difetto ⓐ che avevo alzato in A108 (secondo show con l'audio ancora
acceso) **ha già la sua casa, ed è ⟦S6F⟧**: non va riparato dentro lo Start, e ripararlo lì
contraddirebbe «navigazione ≠ transport». **Ritiro la mia implicita richiesta di rimedio; resta
la richiesta di metterlo nel piano di collaudo.**

⚠️ **[M] Ma ⟦S6F⟧ non ha scheda.** Le intestazioni `###` della sezione B sono **12** e si fermano a
⟦S6⟧: ⟦S6F⟧ non c'è, esattamente come ⟦S-EXIT⟧ (buco già registrato a `SCALETTA:325`).
⇒ **⟦S5b⟧ nasce accanto a due atomi ratificati e senza scheda.** Non li scrivo io qui — sarebbe
progettare fuori mandato — ma la scheda ⟦S5b⟧ deve **nominarli**, o il suo cancello device eredita
un vuoto.

---

## ② LA FORMA DELLA SCHEDA — e perché NON prendo ⟦S4L⟧ a modello

Il mandato mi chiede la forma che ricavo io, e di argomentare se ⟦S4L⟧ non fosse la migliore.
**[A] Non lo è, e la ragione è misurabile, non di gusto.**

**[M] Censimento dei campi, scheda per scheda**, forma `- **Campo:**` su tutta la sezione B:

| scheda | Scopo | File | Revers. | Gate | Cond | extra |
|---|:--:|:--:|:--:|:--:|:--:|---|
| ⟦S0⟧ · ⟦S1⟧ · ⟦S2F⟧ · ⟦S2⟧ | ✓ | ✓ | ✓ | — | ✓ | (corsia PRE, gate solo CI) |
| ⟦S4⟧ | ✓ | ✓ | ✓ | ✓ | ✓ | `Referee:` |
| ⟦S4K⟧ | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| **⟦S4R⟧** | ✓ | ✓ | ✓ | ✓ | ✓ | `Modello raccomandato alla costruzione:` |
| **⟦S4L⟧** | ✓ | ✓ | ✓ | **—** | **—** | `Dipendenze (entrambe dure):` |
| ⟦S5⟧ | ✓ | ✓ | ✓ | ✓ | ✓ | due `OPEN:` |

⇒ **[M] ⟦S4L⟧ è l'UNICA scheda POST priva sia di `Gate:` sia di `Cond:`** — misurato: nel suo
blocco (`SCALETTA:247-297`) la forma `**Gate:**` e `**Cond:**` rendono **zero**; controllo positivo
con la forma identica sul blocco di ⟦S4R⟧ (`:194-246`) → **1 e 1**.

**[A] E sono proprio i due campi che rendono una scheda FALSIFICABILE:** `Gate:` dice quando è
finita, `Cond:` dice a quali condizioni è corretta. Una scheda senza quei due campi non si può
bocciare — si può solo commentare. ⚠️ Non è un caso che ⟦S4L⟧ sia anche **l'atomo SOSPESO**: è la
scheda che non ha mai dovuto dire quando sarebbe stata finita.

⇒ **[A] PRENDO ⟦S4R⟧ A MODELLO**, per tre ragioni misurate: (a) ha i cinque campi pieni;
(b) è l'atomo POST **più recente completato** e quindi la convenzione più aggiornata; (c) è il
**predecessore diretto** — ⟦S4R⟧ ha costruito lo slot che ⟦S5b⟧ deve riempire, e le due schede
saranno lette in coppia. Aggiungo un solo campo suo, `Modello raccomandato alla costruzione:`,
perché è l'unico posto in cui la SCALETTA registra **come** si costruisce e non solo cosa.

---

## ③ LA SCHEDA ⟦S5b⟧ — proposta

⚠️ **[A] Collocazione proposta:** subito dopo la scheda ⟦S5⟧ (che oggi finisce a `SCALETTA:312`),
prima di ⟦S6⟧. Motivo: ⟦S5a⟧/⟦S5x⟧/⟦S5b⟧ sono figli di ⟦S5⟧ e la riga d'ordine li tiene
consecutivi. ⛔ Aggiungerla porta la sezione B da **12** a **13** intestazioni: **il titolo della
sezione B dice «12 atomi» e andrà marcato**, non riscritto.

> ### ⟦S5b⟧ Cablaggio dello Start: nascita del runner + ingresso al player · POST · CI+DEVICE
>
> - **Scopo:** dare allo `.startfoot` del dettaglio l'effetto che oggi non ha — **costruire** il
>   `SetlistRunner` dalla setlist scelta, **depositarlo** nello slot di `QLiveSession`, **navigare**
>   alla pagina `.metronome`. ⛔ **Lo Start CARICA e lascia il player FERMO: non avvia il
>   playback.** Il playback parte dal tocco dell'utente sul transport, da MIDI, o dal Play del
>   Director — decisione di prodotto di Mauro, 18/08. ✅ Con ⟦S5b⟧ l'app può far partire uno show
>   per la prima volta: oggi non può, e la catena è misurata (A99/A103).
>
> - **File — TRE, e non ne serve un quarto** (misurato A108 ①):
>   - `UI/QLive/QLiveSession.swift` **EDIT** — aggiungere il **mutatore dello slot**. È il file
>     stesso ad assegnarlo a questo atomo: «Chi costruisce lo Start (⟦S5⟧) aggiunge qui il
>     mutatore, ed è il solo posto in cui il runner può nascere» (`QLiveSession.swift:14-15`).
>   - `UI/QLive/QLiveShowDetailView.swift` **EDIT** — costruire il runner e chiamare la closure.
>     I due ingredienti sono già in mano alla vista: `setlist` (`:78`) e `store` (`:81`), e
>     `SetlistRunner.init(setlist:store:)` non chiede altro (`SetlistRunner.swift:61`).
>     ⛔ **E chiudere il tocco quando `resolve().songs` è vuoto** — vedi `Cond:` (c).
>   - `UI/QLive/QLiveRootView.swift` **EDIT** — iniettare al dettaglio una closure `() -> Void`
>     **nella stessa forma di `onBack`** (`:104`), che riempie lo slot e **poi** naviga.
>     La closure non può essere tipizzata sulla pagina: `QLivePage` è `private` (`:44`) e
>     `navigate(to:)` è `private` (`:88`) — fuori da quel file il tipo non è nominabile.
>   - ⛔ **`UI/Live/LiveView.swift` NON si tocca**, e nemmeno `Models/LiveSession.swift`: il
>     montaggio col runner iniettato è già costruito da ⟦S4R⟧ (`QLiveRootView.swift:110`, `:157-158`).
>
> - **Reversibilità: PULITA.** Nessuno dei tre passi scrive: `store.resolve(_:)` è puro
>   (`QBeatsStore.swift:152-164`), l'`init` del runner legge e logga, il mutatore assegna un
>   `@Published` in RAM, `navigate` assegna uno `@State`. **Zero disco, zero `UserDefaults`, zero
>   iCloud, nessun cambio di formato dati** ⇒ un revert dei tre file non lascia nulla sul device.
>   Dipendenza dura: ⟦S4R⟧ (lo slot e il gate). Ordine: dopo ⟦S5a⟧ e ⟦S5x⟧.
>
> - **Gate: CI + DEVICE.**
>   - **CI:** verde su `iOS Signed Build`. ⚠️ `F1 — Build Check` non gira dal 31/07 e le sue ultime
>     due run sono fallite: **non conta come cancello finché Mauro non decide** (pendenza A101).
>   - **DEVICE — e questo atomo ne chiude TRE, non uno.** ⟦S5b⟧ è ciò che rende raggiungibile per
>     la prima volta il player: con lui si valida **anche** ⟦S5x⟧ («CHIUSO A CODICE, validazione
>     device DIFFERITA a ⟦S5b⟧», `SCALETTA:324`) e si arma `TD-mixer-copre-endshow` («SI ARMA CON
>     ⟦S5b⟧, NON PRIMA», `BUGS:158`).
>   - **Passi del collaudo, nell'ordine:** (1) da Shows si apre un dettaglio con brani risolti →
>     START → **il player si monta, la videata è piena, e NON suona nulla**; (2) il Play del
>     transport fa partire il click; (3) si arriva a fine setlist → END SHOW → BACK TO SHOWS
>     riporta alla lista (è il gate di ⟦S5x⟧); (4) si esce dalla stanza → l'audio si ferma
>     (`AppRootView.swift:74`).
>   - ⚠️ **Il collaudo va fatto con la procedura sicura di `TD-injecttestdata-sovrascrive-dati-reali`
>     (`BUGS:143`)**: se si passa dalla porta DEBUG, non toccare NESSUNA Song mentre i dati di test
>     sono in RAM.
>
> - **Cond — quattro, tutte necessarie:**
>   - **(a) ORDINE OBBLIGATO: riempi lo slot, POI naviga.** Invertendo si apre un frame con
>     `page == .metronome` e `runner == nil`, e il ramo `else` **si vede**. L'irraggiungibilità del
>     ramo `else` è conseguenza di questa condizione, non un fatto indipendente.
>   - **(b) STATO DOPO IL MONTAGGIO = `.stopped`, e si scrive così.** ⛔ **Non si usa la parola
>     «standby»:** `.standby` esiste già come stato diverso, con valore associato obbligatorio
>     `nextSongName: String` (`LivePlaybackState.swift:4`) e overlay proprio (`LiveView.swift:132-133`),
>     e significa «canzone finita, la prossima è X». Il default della sessione è `.stopped`
>     (`LiveSession.swift:35`), col commento che registra il cambio del 17/05 (TD #28).
>     ⇒ Lo stato che serve **esiste già: ⟦S5b⟧ non lo costruisce.** Ma la parola è occupata, e
>     usarla nella scheda creerebbe un puntatore falso.
>   - **(c) IL TOCCO SI CHIUDE QUANDO `resolve().songs` È VUOTO.** Oggi `isEnabled`
>     (`QLiveShowDetailView.swift:288`) pilota **solo** ombra (`:323`), bordo (`:326-331`) e opacità
>     (`:333`): `.disabled(` nel file rende **0**, mentre il corpus lo usa in **6 file** e
>     `TransportView` usa il parametro `disabled:` di `RubberBtnView` **6 volte**. ⇒ Senza questa
>     condizione un tocco su una scaletta orfana costruisce un runner a catalogo vuoto, `primeDisplay`
>     esce al primo `guard` (`SetlistRunner.swift:272`) e **il player si monta bianco**.
>   - **(d) NIENTE STOP AGGANCIATO ALLA NAVIGAZIONE.** Il divieto è inciso in testa al file
>     (`QLiveRootView.swift:78-85`, decisione CD 18/07 ratificata): lo Start non deve fermare nulla,
>     e il secondo show della serata **non si ripara qui** — lo copre ⟦S6F⟧.
>
> - **Modello raccomandato alla costruzione:** Opus — il diff tocca tre file e una regola d'ordine
>   che non è verificabile dal compilatore.
>
> - **OPEN — non bloccanti per ⟦S5b⟧, ma vanno nominati o il gate eredita un vuoto:**
>   - **⟦S6F⟧ non ha scheda.** Ratificato in `LIBRO:334`, assente dalle 12 intestazioni della
>     sezione B. È l'atomo che copre lo `.startfoot` con la fascia quando qualcosa suona
>     (freeze `2026-07-18_QLive-Exit-in-Play.html:285`), cioè **la sede del difetto del secondo show**.
>   - **⟦S-EXIT⟧ non ha scheda.** Buco già registrato a `SCALETTA:325`, mai colmato.
>   - **Il ramo `else` resta `EmptyView()`**, guardia difensiva, **nessun lavoro CD** — precedente
>     identico due righe sopra nello stesso `switch` (`QLiveRootView.swift:105-107`).
>     ⚠️ Il commento a `:162-169` chiede ancora un empty-state a ⟦S5⟧: quella richiesta è **superata**
>     dalla cancellazione dell'A3 (`LIBRO:355`, 18/08) e **va marcata, non riscritta**.

---

## ④ LA SEZIONE C — come la sistemerei

**[M] Il problema, misurato.** L'ordine operativo vero oggi si ricompone da **quattro** righe:

```text
323	**PRE:** S0 → {S1, S2F} → S2 → S2b → S2c → S2e → S2d → **S3** (indipendente Nodo A; i sub-atomi S2b/S2c/S2e/S2d = ciclo CD-decisioni + estrazione Empt …[troncata, riga integrale a fonte]
324	⚠️ **MARCATURA 07/08 — ⟦S5⟧ SI È SPEZZATA IN TRE, E LA RIGA D'ORDINE SOPRA NON LO SA. La riga resta come scritta: si marca, non si riscrive.** Misurat …[troncata, riga integrale a fonte]
325	⚠️ **MARCATURA 07/08 — ⟦S-EXIT⟧ È NELL'ORDINE RATIFICATO MA NON HA SCHEDA. Buco registrato, NON colmato in questo giro.** Misurato sul blob a HEAD `77 …[troncata, riga integrale a fonte]
326	- ✅ **MARCATURA 18/08 — ⟦S5a⟧ CHIUSO DEVICE, supera il punto (1) della marcatura 07/08 sopra. La marcatura 07/08 resta come scritta: si marca, non si  …[troncata, riga integrale a fonte]
```


⇒ `:323` porta l'ordine ratificato ma **non sa** che ⟦S5⟧ si è spezzata in tre; `:324` lo dice ma
non riscrive; `:325` registra che ⟦S-EXIT⟧ non ha scheda; `:326` chiude ⟦S5a⟧ device.
Chi arriva deve leggere quattro righe e **comporle a mente** per sapere qual è il prossimo atomo.

⛔ **[A] E QUI C'È UNA TENSIONE CHE DICHIARO INVECE DI AGGIRARLA.** La riga `:323` dichiara di sé:
«**QUESTA RIGA È LA SEDE UNICA DELL'ORDINE DEGLI ATOMI §6**». Qualunque riga nuova che *ristabilisca*
l'ordine crea una **seconda sede**, che è il difetto che quella clausola esiste per impedire.
Non si può quindi «aggiungere una riga con l'ordine aggiornato» senza contraddire il canonico.

**[A] La mia proposta è una riga sola, e NON è una sede: è una LETTURA DERIVATA, subordinata.**

> - ⚠️ **LETTURA DERIVATA DELL'ORDINE, AS-OF 18/08 — NON È UNA SEDE.** Questa riga non ratifica
>   nulla e non sostituisce `:323`, che resta **la sede unica**: è la composizione delle quattro
>   righe sopra, messa in un posto solo perché non vada rifatta a mente ogni volta. **Se diverge da
>   `:323`+marcature, vince `:323`+marcature, e questa riga è il difetto.**
>   **Prossimo atomo = ⟦S5b⟧.** Catena POST: S4 → S4K → S4R → **S5a** ✅ device 18/08 →
>   **S5x** (chiuso a codice, device differito a ⟦S5b⟧) → **⟦S5b⟧ ← IL FRONTE** → ⟦S-EXIT⟧
>   (⛔ senza scheda) → ⟦S4L⟧ (⛔ sospeso) → ⟦S6⟧ ultimo.
>   ⚠️ **Fuori catena e senza scheda: ⟦S6F⟧**, collocato «dopo ⟦S5⟧» da `LIBRO:334`.

**[A] Perché questa forma e non un'altra:** dichiara la propria subordinazione **nella prima riga**,
porta un as-of, e nomina i due buchi. È la stessa forma delle marcature che questo file già usa
(«si marca, non si riscrive»), applicata all'ordine invece che a una scheda.
⛔ **Se il referee ritiene che anche una lettura derivata violi la sede unica, la proposta cade e
la sezione C resta com'è** — in quel caso il rimedio non è documentale ma di processo, e non spetta
a me.

---

## ⑤ LE VOCI DI BUGS — e prima, cosa È GIÀ TRACCIATO

**[M] Ho misurato cosa esiste PRIMA di proporre, per non duplicare.** Due delle mie misure di oggi
hanno già un ticket, e uno di quei due è **completo**:

| mia misura | già tracciata? |
|---|---|
| `injectTestData` sostituisce + una CRUD persiste (A105) | ✅ **SÌ, e per intero** — `TD-injecttestdata-sovrascrive-dati-reali`, `BUGS:134-146`, con il meccanismo, la raggiungibilità col dito e **la procedura sicura** (`:143`). **Nessun ticket nuovo: la mia misura lo RICONFERMA a un HEAD più recente.** |
| commento stale sui chiamanti di `navigate` (A108) | ⚠️ **PARZIALMENTE** — `TD-doccomment-navigate-zero-chiamanti`, `BUGS:664-668`, copre il commento «zero chiamanti». **Non copre il secondo**, quello a `:171-172`. |
| START SHOW toccabile da spento | ⛔ **NO** — `START SHOW` e `startfoot` rendono **0** in tutto BUGS |
| secondo show con audio acceso | ⛔ **NO** — `secondo show` e `S6F` rendono **0** in tutto BUGS |

### Voce 1 — **ALLARGARE** un ticket esistente, non aprirne uno nuovo

**[A]** `TD-doccomment-navigate-zero-chiamanti` va allargato, non duplicato: stesso file, stessa
classe di difetto, stesso momento di correzione («si corregge nel primo atomo che apre quel file»,
`BUGS:667` — e quell'atomo è **⟦S5b⟧**).

**[M] Due fatti da aggiungere, entrambi misurati oggi:**
- **una SECONDA istanza nello stesso file**, `QLiveRootView.swift:171-172`: «L'unico chiamante
  dell'imbuto è il back del player qui sopra» — **i chiamanti eseguibili sono TRE**: `:97`
  (`.detail`), `:104` (`.shows`), `:157` (`.shows`);
- ⚠️ **le ancore del ticket stesso sono STALE**: cita `:85` e `:145`, ma a HEAD il commento
  bersaglio sta a **`:87`** e `:145` è diventata una riga di documentazione su `environmentObject`.
  Deriva prodotta da ⟦S5a⟧. ⇒ **Il ticket sui puntatori stale ha i puntatori stale.**

### Voce 2 — **NUOVA**: `TD-startshow-tocco-non-chiuso`

**[A] Titolo proposto:** «START SHOW si dipinge spento ma resta premibile — con ⟦S5b⟧ costruisce un
runner a catalogo vuoto e il player si monta bianco».
**[M] Fatti:** `.disabled(` in `QLiveShowDetailView.swift` → **0**, controllo positivo `.disabled(`
→ **6 file** nel corpus e `disabled:` di `RubberBtnView` → **6** usi nel solo `TransportView.swift`
· `isEnabled` (`:288`) pilota solo `:323`, `:326-331`, `:333` · conseguenza:
`SetlistRunner.init` con catalogo vuoto → `currentSong` nil (`:71-74`) → `primeDisplay` esce al
`guard` (`:272`) → videata vuota.
**[A] Severità: PROPOSTA, non assegnata — la decide Mauro**, precedente `TD-mixer-copre-endshow`
(`BUGS:159`). La mia proposta è 🟠 **OPEN MEDIA**: oggi è **inerte** (il bottone non fa nulla
comunque) e **si arma con ⟦S5b⟧**. ⚠️ Ma se ⟦S5b⟧ include la `Cond:` (c), **il ticket nasce già
chiuso** — e allora vale la pena aprirlo solo come traccia della decisione.
**Dominio:** CC.

### Voce 3 — **NUOVA**: `TD-secondo-show-audio-acceso`

**[A] Titolo proposto:** «Il secondo show della serata parte con l'audio del primo ancora acceso».
**[M] Fatti:** il back del player va all'imbuto interno (`QLiveRootView.swift:157`) e il divieto di
agganciare uno stop alla navigazione è **ratificato** (`:78-85`, CD 18/07) · l'unico stop è al
bordo-stanza (`AppRootView.swift:70-76`) · ⇒ play A → back → apri B → START: la videata mostra B
fermo mentre il click di A suona ancora.
⛔ **E il ticket deve dire dove si ripara, perché non è qui:** lo copre **⟦S6F⟧** — la fascia
sostituisce lo `.startfoot` quando qualcosa suona (freeze `:285`), quindi con ⟦S6F⟧ costruito
**quel tocco non esiste più**. ⇒ Forma consigliata, sullo stampo di `BUGS:158`:
**«si arma con ⟦S5b⟧, si disarma con ⟦S6F⟧»**.
**[A] Severità: PROPOSTA, non assegnata.** La mia proposta è 🟠 **OPEN MEDIA**, non ALTA: non c'è
perdita di dati e non c'è silenzio sul palco — c'è audio **di troppo**. ⚠️ Ma è il tipo di difetto
che sul palco si nota subito e male, e Mauro potrebbe valutarlo diversamente da me.
**Dominio:** CC per la misura, ma **la riparazione è dentro ⟦S6F⟧**, che ha una metà CD.

⚠️ **[A] Una nota di onestà su queste due voci:** entrambe descrivono difetti **che oggi non
esistono ancora**, perché nascono nel momento in cui lo Start funziona. Aprirle **prima** di
⟦S5b⟧ è una scelta — difendibile, perché è il momento in cui si sa — ma va fatta sapendo che
il tracker si popola di cose non ancora accadute. **Non la decido io.**

---

## COSA NON HO FATTO

⛔ Nessun codice. Nessun canonico modificato. Non ho ratificato nulla e non chiedo ratifica in
questo giro. Non ho scritto le schede di ⟦S6F⟧ e ⟦S-EXIT⟧ — le ho **nominate** perché il gate di
⟦S5b⟧ non erediti un vuoto, ma scriverle sarebbe progettare due atomi dentro un mandato che ne
chiede uno.

⚠️ **E una lacuna di questo referto, dichiarata:** la proposta **non ha verifica indipendente**.
Il giro precedente aveva perso otto agenti su otto per limite di sessione e non l'ho rilanciato qui:
tutto ciò che è **[M]** l'ho misurato io, con controllo positivo su ogni zero, ma **nessuno ha
provato a demolire questa scheda**. È esattamente ciò che il cancello del referee deve fare.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `248fb7955303b056a93a63a2adc218a330453acdfcec7deac0cd0c12b12f921c`
- **byte** (file completo): `21694`
- **righe** (file completo): `317`
- **CR** (0x0D, contati sui byte, mai con grep): `0`

---

*A110-CC-PROPONE-FINE*
