# MISURE CC — A111, RI-DERIVAZIONE DELLA FORMA

Da: CC · A: Mauro + referee · 18/08/2026
⛔ **QUESTO GIRO PROPONE, NON INCIDE.** Nessun canonico modificato, zero righe sotto `ios_app/`,
zero commit, zero push, HEAD invariato a `44fea3e378414c300ffd50fcac527c683740735b`.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato · **[A]** giudizio o proposta mia.

---

## RITIRO — l'argomento di A110 §② è caduto, e l'errore è mio

**[M] Il blocco del referee è fondato.** La mia sonda era `**Gate:**` — cercava i **due punti**.
⟦S4L⟧ scrive il campo così, `SCALETTA:254`:

```text
254	- **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE SCRIVE DATI UTENTE.** Per ratifica
```


⇒ **La cella `—` che avevo messo su ⟦S4L⟧/Gate era FALSA**, e con lei cade tutto ciò che ci
avevo costruito sopra.

⛔ **E il difetto peggiore non è lo zero: è il controllo positivo.** Avevo scelto ⟦S4R⟧, che usa
**la forma della sonda** (`- **Gate:**`). Un controllo positivo così non può fallire: **confermava
la sonda su un bersaglio che non poteva smentirla.** Un controllo che non può dare NO non è un
controllo, è un'eco. ⚠️ **Ed è esattamente la regola che avevo scritto in A102 e riviolato in A103
sul «pushat»**: la terza volta nella stessa settimana, e stavolta l'ho fatta sul campo che decideva
la proposta.

**[A] Ritiro esplicitamente due cose, e non le riformulo altrove:**

1. la riga della tabella A110 che dava ⟦S4L⟧ privo di `Gate:`;
2. il ragionamento che ne seguiva — «non è un caso che ⟦S4L⟧ sia anche l'atomo sospeso: è la
   scheda che non ha mai dovuto dire quando sarebbe stata finita». **È falso due volte.**
   **[M]** ⟦S4L⟧ il suo Gate ce l'ha, ed è **il più perentorio del corpus** — l'unico che dichiara
   una proprietà esclusiva dell'atomo in maiuscolo dentro il nome del campo. E **[M]** è sospeso per
   **tre pendenze nominate** in `SCALETTA:323` — «atomo della pillola ▶ · forma tecnica del campo
   di persistenza · procedura di rollback dati» — nessuna delle quali riguarda la sua scheda.
   Avevo legato la sospensione a un difetto di forma che non esiste.

---

# B1 · IL CENSIMENTO RIFATTO, CIECO ALLA FORMA

## La sonda

**[A]** Trova il campo comunque sia punteggiato: bullet a qualunque indentazione, grassetto
obbligatorio, **emoji ammesse prima o dopo l'apertura**, **prefisso ordinale ammesso**
(«6 · GATE»), nome del campo chiuso dal primo fra **due punti**, **lineetta lunga o breve**, o
**fine del grassetto**; confronto insensibile alle maiuscole.

## La validazione — su TRE forme diverse fra loro

⛔ **Un controllo positivo che usi la forma della sonda non prova nulla.** Ho quindi validato su
tre righe reali che usano **tre punteggiature diverse**, nessuna delle quali è «quella cercata»:

| riga | forma | esito |
|---|---|---|
| `SCALETTA:196` | due punti — `- **File:**` | **trova** «File» |
| `SCALETTA:254` | emoji + lineetta — `- **🔴 Gate — …**` | **trova** «Gate» |
| `SCALETTA:108` | ordinale — `- **6 · GATE:**` | **trova** «GATE» |

⚠️ **[M] E la validazione ha fatto il suo mestiere: ha bocciato anche la mia sonda NUOVA.**
La prima versione trovava le prime due forme ma **non** la terza — mancava il prefisso ordinale, e
dava un falso `—` sul Gate di ⟦S3⟧. L'ho corretta e rifatta. ⇒ Il referee aveva ragione anche nel
sospetto generale: *se la sonda era cieca su una cella, poteva esserlo su altre*, **e lo era**.

## La tabella vera — tutte e dodici le schede

**[M]** Ogni cella piena porta il numero di riga dove il campo è scritto.

| scheda | corsia · gate | Scopo | File | Revers. | Gate | Cond |
|---|---|---|---|---|---|---|
| ⟦S0⟧ | PRE · CI | `:43` | `:44` | `:45` | **—** | `:46` |
| ⟦S1⟧ | PRE · CI | `:49` | `:50` | `:51` | **—** | `:52` |
| ⟦S2F⟧ | PRE · CI | `:55` | `:56` | `:57` | **—** | `:58` |
| ⟦S2⟧ | PRE · CI | `:61` | `:62` | `:63` | **—** | `:64` |
| ⟦S3⟧ | PRE · CI + 🔴 device | `:70` | **—** | `:118` | `:108` | `:119` |
| ⟦NODO A⟧ | SPINE · CI+DEVICE | `:126` | `:127` | **—** | `:128` | `:129` |
| ⟦S4⟧ | POST · CI+DEVICE | `:133` | `:134` | `:135` | `:136` | `:137` |
| ⟦S4K⟧ | POST · CI+DEVICE | `:166` | `:173` | `:179` | `:181` | `:187` |
| ⟦S4R⟧ | POST · CI+DEVICE | `:195` | `:196` | `:232` | `:235` | `:236` |
| **⟦S4L⟧** | POST · CI+DEVICE | `:248` | `:272` | `:276` | **`:254`** | **—** |
| ⟦S5⟧ | POST · CI+DEVICE | `:299` | `:300` | `:302` | `:303` | `:304` |
| ⟦S6⟧ | POST · CI | `:314` | `:315` | `:316` | **—** | `:317` |

## Ogni cella `—`, documentata

**[M] Sette celle vuote. Nessuna è un caso: sei sono STRUTTURALI, una è una rinomina, due sono
assenze vere.**

- **Gate in ⟦S0⟧ · ⟦S1⟧ · ⟦S2F⟧ · ⟦S2⟧ · ⟦S6⟧ — ASSENTE PER CORSIA, non per omissione.**
  Le loro intestazioni dichiarano gate **solo CI**. ⇒ **[M] Il criterio, verificato su tutte e
  dodici: il campo `Gate` c'è SE E SOLO SE l'atomo ha un cancello device.** Le sette schede con
  device (⟦S3⟧, ⟦NODO A⟧, ⟦S4⟧, ⟦S4K⟧, ⟦S4R⟧, ⟦S4L⟧, ⟦S5⟧) ce l'hanno **tutte e sette**;
  le cinque senza device **nessuna**. Zero eccezioni.
  ⚠️ **La conferma più forte è ⟦S3⟧:** è in corsia **PRE** ma la sua intestazione porta
  «CI + 🔴 PRIMO GATE DEVICE di §6» — e infatti **ha** il campo Gate, a `:108`. Se il criterio
  fosse la corsia, ⟦S3⟧ sarebbe l'eccezione; col criterio giusto è la prova.

- **File in ⟦S3⟧ — NON assente: RINOMINATO.** `SCALETTA:72` porta
  `- **INNESTO (verificato a HEAD):**` e fa esattamente il lavoro di `File:` (dice dove il codice
  entra). ⚠️ Qui la cecità non è di punteggiatura ma **di nome**: nessuna sonda sul nome del campo
  può trovarlo. ⇒ Si conta come **presente in sostanza, assente in forma**.

- **Reversibilità in ⟦NODO A⟧ — ASSENZA VERA.** I suoi bullet di primo livello sono cinque:
  `Scopo` (`:126`), `File` (`:127`), `Gate` (`:128`), `Cond A` (`:129`), `⚠️ PREREQ` (`:130`).
  **Nessuno porta la reversibilità, sotto alcun nome.**

- **Cond in ⟦S4L⟧ — ASSENZA VERA.** I suoi bullet di primo livello sono otto: `Scopo` (`:248`),
  `🔴 Gate` (`:254`), `Dipendenze (entrambe dure)` (`:262`), `File` (`:272`),
  `Reversibilità` (`:276`), più tre bullet `⚠️` che sono **pendenze e definizioni**, non condizioni
  di correttezza. **Nessuno porta il contenuto di `Cond:`.**

⚠️ **[M] Un terzo punto cieco, e stavolta l'ho trovato io nel mio stesso strumento.** Estraendo
corsia e gate dalle intestazioni con uno split sul carattere `·`, la riga di ⟦S4L⟧ tornava vuota:
il suo titolo contiene **«···»** (i puntini del menu), che lo split scambia per separatori.
L'intestazione vera è `SCALETTA:247`, e dice `POST · CI+DEVICE`. Lo registro perché è la **stessa
classe** dell'errore che il referee mi ha bloccato: uno strumento che assume una forma.

---

# B2 · IL MODELLO, RI-DERIVATO

**[A] Il vecchio argomento è morto e non lo rianimo.** Con la tabella vera, «quale scheda ha più
campi» non discrimina più: **quattro schede POST hanno tutti e cinque i campi** (⟦S4⟧, ⟦S4K⟧,
⟦S4R⟧, ⟦S5⟧), e la quinta ne ha quattro. Serve un criterio diverso.

**[A] Il criterio nuovo: la forma NON si eredita da una scheda, si eredita dalla CORSIA.**
La tabella dice che i campi non sono una scelta di chi scrive ma una funzione di ciò che l'atomo
fa: cinque campi se ha un cancello device, quattro se no. ⇒ **⟦S5b⟧ ha cancello device, quindi
porta i cinque campi.** Non perché li porti ⟦S4R⟧: perché li porta **la sua corsia**, e la regola
non ha eccezioni su dodici schede.

⇒ **[A] Resto su ⟦S4R⟧ come scheda di riferimento, ma per una ragione che non c'entra col
conteggio dei campi — la CONTINUITÀ DI CONTENUTO:**

- **[M]** ⟦S4R⟧ ha costruito lo **slot** che ⟦S5b⟧ deve riempire, e ha lasciato fuori il mutatore
  **apposta**, assegnandolo per nome a chi costruisce lo Start: «Chi costruisce lo Start ⟦S5⟧
  aggiunge qui il mutatore, ed è il solo posto in cui il runner può nascere»
  (`ios_app/QBeats/UI/QLive/QLiveSession.swift:14-15`).
- ⇒ Le due schede sono **le due metà di un unico contratto**, e verranno lette in coppia. Una
  divergenza di forma fra loro sarebbe rumore proprio dove serve continuità.
- **[A]** Ne prendo anche il campo extra `Modello raccomandato alla costruzione:`, perché è
  l'unico posto in cui la SCALETTA registra **come** si costruisce e non solo cosa.

**[A] E prendo una cosa da ⟦S4L⟧ — la scheda che avevo scartato a torto: il REGISTRO del suo
Gate.** ⟦S4L⟧ non scrive «Gate: device»; scrive **cosa rende quel cancello diverso da tutti gli
altri**, in maiuscolo, dentro il nome del campo. ⟦S5b⟧ ha una proprietà altrettanto singolare e
oggi non scritta da nessuna parte: **è l'atomo che chiude TRE cancelli device in un colpo solo.**
⇒ Il suo `Gate` va scritto in quel registro, non in quello neutro.

---

# B3 · LE TRE DECISIONI DEL REFEREE — applicate

**[A] Nessuna delle tre mi sembra sbagliata. Le applico, e la ③ l'ho verificata sul codice
prima di accettarla.**

- **① Sezione C — FUORI da questo giro.** Non la ripropongo. ⚠️ Resta agli atti in A110 che
  l'ordine operativo vero si ricompone da quattro righe, e che il rimedio è **di processo**: qui
  non se ne parla più.
- **② `TD-startshow-tocco-non-chiuso` — NON si apre.** È `Cond (c)` della scheda: nascerebbe e
  morirebbe nello stesso diff. **[A] La ragione mi convince e la sottoscrivo** — in A110 l'avevo
  già scritto come dubbio («se ⟦S5b⟧ include la `Cond (c)`, il ticket nasce già chiuso») e poi
  l'avevo proposto lo stesso: incoerenza mia, corretta qui.
- **③ `Cond (d)` — precisata. [M] E la precisazione è esatta sul codice.**
  Il divieto ratificato parla di **stop AUDIO**, non di stato:

```text
78	    // DECISIONE CD 18/07 (ratificata — LIBRO Sez.2, riga 18/07/2026):
79	    // navigazione ≠ transport. NESSUNO stop audio va agganciato alle
80	    // transizioni di `page`, in NESSUNA forma (niente `.onChange(of: page)`
81	    // con stop — ruling D1; vietato anche inerte). Il click lo ferma SOLO uno
82	    // STOP esplicito del transport: con Link Director uno stop è un evento di
83	    // BANDA, non può essere il sottoprodotto di un «indietro». Lo stop
84	    // legittimo al bordo-stanza (uscita da `.qLive`) vive in AppRootView
85	    // `.onChange(of: screen)` — FUORI da questo strato.
```


  Ciò che ⟦S5x⟧ fa a END SHOW è un'altra cosa — assegna uno stato di UI, non tocca il motore:

```text
160	                    FineSetlistView(scaleFactor: scaleFactor, onBackToShows: {
161	                        session.playbackState = .stopped
162	                        onExit()
163	                    })
```


  ⇒ `session.playbackState = .stopped` non è uno stop audio: quando quella riga gira, il playback
  è **già finito** (è il runner a portare a `.fineSetlist` e a chiamare `audioEngine.stop()`,
  `SetlistRunner.swift:370` e `:378`). ⇒ **Igiene, non transport.** La precisazione regge.

**[A] Le altre voci di A110 le riporto invariate**, come disposto: i tre file, lo Scopo, la
Reversibilità pulita, i tre cancelli device, `Cond (a)`, `Cond (b)`, `Cond (c)`, il modello
raccomandato, e le tre `OPEN`. La voce BUGS ① (allargare `TD-doccomment-navigate-zero-chiamanti`,
con le sue ancore stale) e la voce ③ (`TD-secondo-show-audio-acceso`, «si arma con ⟦S5b⟧, si
disarma con ⟦S6F⟧») restano come proposte in A110: **questo giro non le tocca**.

---

# B4 · LA SCHEDA ⟦S5b⟧ — completa, aggiornata

⚠️ **[A] Collocazione:** dopo ⟦S5⟧ (che finisce a `SCALETTA:312`), prima di ⟦S6⟧.
⛔ Porta la sezione B da **12** a **13** intestazioni: **il titolo della sezione dice «12 atomi» e
va marcato**, non riscritto.

> ### ⟦S5b⟧ Cablaggio dello Start: nascita del runner + ingresso al player · POST · CI+DEVICE
>
> - **Scopo:** dare allo `.startfoot` del dettaglio l'effetto che oggi non ha — **costruire** il
>   `SetlistRunner` dalla setlist scelta, **depositarlo** nello slot di `QLiveSession`, **navigare**
>   alla pagina `.metronome`. ⛔ **Lo Start CARICA e lascia il player FERMO: non avvia il
>   playback.** Il playback parte dal tocco sul transport, da MIDI, o dal Play del Director —
>   decisione di prodotto di Mauro, 18/08. ✅ Con ⟦S5b⟧ l'app può far partire uno show per la prima
>   volta: oggi non può, e la catena è misurata (A99/A103).
>
> - **File — TRE, e non ne serve un quarto:**
>   - `UI/QLive/QLiveSession.swift` **EDIT** — il **mutatore dello slot**. È il file stesso ad
>     assegnarlo a questo atomo (`:14-15`).
>   - `UI/QLive/QLiveShowDetailView.swift` **EDIT** — costruire il runner e chiamare la closure.
>     Gli ingredienti ci sono già: `setlist` (`:78`), `store` (`:81`), e
>     `SetlistRunner.init(setlist:store:)` non chiede altro (`SetlistRunner.swift:61`).
>     ⛔ **E chiudere il tocco** — `Cond (c)`.
>   - `UI/QLive/QLiveRootView.swift` **EDIT** — iniettare al dettaglio una closure `() -> Void`
>     **nella forma di `onBack`** (`:104`), che riempie lo slot e **poi** naviga. La closure non può
>     essere tipizzata sulla pagina: `QLivePage` è `private` (`:44`), `navigate(to:)` è `private`
>     (`:88`).
>   - ⛔ **`UI/Live/LiveView.swift` NON si tocca**, né `Models/LiveSession.swift`: il montaggio col
>     runner iniettato è già costruito da ⟦S4R⟧ (`QLiveRootView.swift:110`, `:157-158`).
>
> - **Reversibilità: PULITA.** `store.resolve(_:)` è puro (`QBeatsStore.swift:152-164`), l'`init`
>   del runner legge e logga, il mutatore assegna un `@Published` in RAM, `navigate` assegna uno
>   `@State`. **Zero disco, zero `UserDefaults`, zero iCloud, nessun cambio di formato** ⇒ un revert
>   dei tre file non lascia nulla sul device. Dipendenza dura: ⟦S4R⟧. Ordine: dopo ⟦S5a⟧ e ⟦S5x⟧.
>
> - **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE CHIUDE TRE CANCELLI DEVICE IN UN COLPO SOLO.**
>   Non è enfasi: è il motivo per cui non si può collaudare a metà.
>   - **il proprio** — lo Start carica e il player si monta fermo;
>   - **quello DIFFERITO di ⟦S5x⟧** — «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧»
>     (`SCALETTA:324`): END SHOW è irraggiungibile finché lo slot non ha mutatori;
>   - **l'armamento di `TD-mixer-copre-endshow`** — «SI ARMA CON ⟦S5b⟧, NON PRIMA» (`BUGS:158`).
>   - **CI:** verde su `iOS Signed Build`. ⚠️ `F1 — Build Check` non gira dal 31/07 e le ultime due
>     run sono fallite: **non conta come cancello finché Mauro non decide** (pendenza A101).
>   - **Passi del collaudo:** (1) dettaglio con brani risolti → START → **il player si monta, la
>     videata è piena, non suona nulla**; (2) Play del transport → parte il click; (3) fine setlist
>     → END SHOW → BACK TO SHOWS torna alla lista (gate di ⟦S5x⟧); (4) uscita dalla stanza →
>     l'audio si ferma (`AppRootView.swift:74`).
>   - ⚠️ Col percorso DEBUG vale la procedura sicura di
>     `TD-injecttestdata-sovrascrive-dati-reali` (`BUGS:143`): **non toccare NESSUNA Song** mentre i
>     dati di test sono in RAM.
>
> - **Cond — quattro, tutte necessarie:**
>   - **(a) ORDINE OBBLIGATO: riempi lo slot, POI naviga.** Invertendo si apre un frame con
>     `page == .metronome` e `runner == nil`, e il ramo `else` **si vede**. L'irraggiungibilità di
>     quel ramo è conseguenza di questa condizione, non un fatto indipendente.
>   - **(b) STATO DOPO IL MONTAGGIO = `.stopped`, e si scrive così.** ⛔ **Non si usa la parola
>     «standby»:** `.standby` esiste già come stato diverso, con valore associato obbligatorio
>     `nextSongName: String` (`LivePlaybackState.swift:4`) e overlay proprio
>     (`LiveView.swift:132-133`). Il default della sessione è `.stopped` (`LiveSession.swift:35`).
>     ⇒ Lo stato serve già e **⟦S5b⟧ non lo costruisce**; ma la parola è occupata, e usarla
>     creerebbe un puntatore falso.
>   - **(c) IL TOCCO SI CHIUDE QUANDO `resolve().songs` È VUOTO.** Oggi `isEnabled`
>     (`QLiveShowDetailView.swift:288`) pilota **solo** ombra (`:323`), bordo (`:326-331`) e opacità
>     (`:333`): `.disabled(` nel file rende **0**, mentre il corpus lo usa in **6 file** e
>     `TransportView` usa il parametro `disabled:` di `RubberBtnView` **6 volte**. Senza questa
>     condizione un tocco su una scaletta orfana costruisce un runner a catalogo vuoto,
>     `primeDisplay` esce al primo `guard` (`SetlistRunner.swift:272`) e **il player si monta bianco**.
>   - **(d) NIENTE STOP AUDIO AGGANCIATO ALLA NAVIGAZIONE MENTRE IL CLICK GIRA.**
>     Il divieto ratificato (`QLiveRootView.swift:78-85`, CD 18/07) riguarda lo **stop del motore**:
>     un «indietro» non può uccidere il click, che con Link è evento di banda.
>     ✅ **Non vieta invece l'azzeramento di STATO a END SHOW**, dove il playback è già finito —
>     `LiveView.swift:161` assegna `session.playbackState = .stopped` prima di `onExit()`, ed è
>     **igiene, non transport** (a fermare il motore è stato il runner, `SetlistRunner.swift:370`,
>     `:378`). ⛔ Il secondo show della serata **non si ripara qui**: lo copre ⟦S6F⟧.
>
> - **Modello raccomandato alla costruzione:** Opus — il diff tocca tre file e una regola d'ordine
>   (`Cond (a)`) che il compilatore non può verificare.
>
> - **OPEN — non bloccanti, ma vanno nominati o il cancello eredita un vuoto:**
>   - **⟦S6F⟧ non ha scheda.** Ratificato in `LIBRO:334`, assente dalle 12 intestazioni della
>     sezione B. È l'atomo che sostituisce lo `.startfoot` con la fascia quando qualcosa suona
>     (freeze `2026-07-18_QLive-Exit-in-Play.html:285`), cioè **la sede del difetto del secondo show**.
>   - **⟦S-EXIT⟧ non ha scheda.** Buco già registrato a `SCALETTA:325`, mai colmato.
>   - **Il ramo `else` resta `EmptyView()`**, guardia difensiva, **nessun lavoro CD** — precedente
>     identico nello stesso `switch` (`QLiveRootView.swift:105-107`). ⚠️ Il commento a `:162-169`
>     chiede ancora un empty-state a ⟦S5⟧: superato dalla cancellazione dell'A3 (`LIBRO:355`),
>     **va marcato, non riscritto**.

---

## COSA NON HO FATTO

⛔ Nessun codice, nessun canonico toccato, nessuna ratifica chiesta. Non ho riproposto la sezione C.
Non ho aperto `TD-startshow-tocco-non-chiuso`. Non ho scritto le schede di ⟦S6F⟧ e ⟦S-EXIT⟧.

⚠️ **E la lacuna resta quella di A110: nessuna verifica indipendente.** Il censimento di B1 l'ho
rifatto io, con una sonda che ho validato su tre forme e che **ha bocciato se stessa una volta**.
È più robusta di quella di A110, ma **è sempre la mia** — e A110 dimostra che questo non basta.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `a0acc36f6070af7bedcacf49ecab42a7c3c926c0012eedfee7879ee403edf94a`
- **byte** (file completo): `19633`
- **righe** (file completo): `321`
- **CR** (0x0D, contati sui byte, mai con grep): `0`
- **byte NUL** (0x00, controprova sul bersaglio): `0`

---

*A111-RIDERIVAZIONE-FINE*
