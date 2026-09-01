# MISURE CC — A90, CONTRADDITTORIO SULLA ROADMAP (sola lettura)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: **zero modifiche sotto `ios_app/`**, zero commit, zero push, zero checkout,
zero riclassificazioni, zero modifiche ai canonici, roadmap non riscritta.
Scritture eseguite: **solo questo file**, in `HANDOFF/` + propagazione R-δ.

Marcatura: **[M]** misurato ora da CC · **[R]** riportato, non rimisurato.

---

## AGGANCIO — A90 non collide, ma il primo controllo era sbagliato

**[M]** Nomi file, due supporti, entrambe le casse: `A90` → **0** in `HANDOFF/` (repo) e **0** in
`…/FILE X CLAUDE.MD/HANDOFF/` (E:). Controllo positivo `A87` → **1** su entrambi.

⚠️ **Autocorrezione, prima di andare avanti.** Il mio primo controllo sui CONTENUTI ha reso `A90` in
**28** file, che sembrava una collisione grave. Era un **falso positivo di forma**: `grep -icE 'a90'`
cattura `a90` dentro gli sha — per esempio `25056b66eda40ad76d91a886ace442b7064ca900`. Con la forma
corretta `grep -rlE '\bA90\b'` i file sono **2**, e sono `HANDOFF/ROADMAP_CC_2026-08-18.md` e
`HANDOFF/STATO_FINALE_2026-08-07_321293e.txt`: entrambi **dichiarano che A90 è libero**, nessuno dei
due è un artefatto di A90. Controllo positivo `\bA87\b` → **3** file.

⇒ **A90 è libero.** Non mi fermo. Ma la forma nuda del grep va in conto ai falsi-zero/falsi-positivi
già censiti: è la stessa famiglia, con polarità opposta.

---

## ① F1 ≠ `iOS Signed Build` — **ACCETTO**

**[M]** Sono due workflow distinti nello stesso repo:

| | `f1_build_check.yml` | `ios_build.yml` |
|---|---|---|
| nome | «F1 — Build Check (zero errors, zero warnings)» | «iOS Signed Build» |
| innesco | `workflow_dispatch` — **solo manuale** | **push** |
| cosa fa | build Debug **senza firma**, `:20-27` | build + firma + archive + IPA, `:75-84` |
| ultime run | 31/07 ×2 → **entrambe `failure`** | tutte `success` |

**[M]** Le ultime quattro run di F1 in assoluto: `30639169986` (31/07, failure), `30638276963`
(31/07, failure), `24935301504` (25/04, success), `24935244603` (25/04, failure). **Non gira dal
31/07.**

⇒ Confermo: **«CI verde» sul secondo non implica NULLA sul primo.** E confermo il corollario che
proponi: va scritto disambiguato ogni volta. Aggiungo un rilievo che rafforza il tuo autoreferto —
`LIBRO:330` cita la run `30639169986` come prova a sostegno di ⟦S4R⟧ («Errors 0, 6 warning identici
alla baseline»): l'affermazione sul **contenuto** è vera, ma la run ha **conclusione `failure`**,
perché il cancello è zero-warning e i warning erano 6. Chi rilegge quella riga può concludere che F1
fosse verde. **Non lo era.**

---

## ② EMPTY-STATE DEL METRONOMO — **ACCETTO, contro me stesso**

Avevi ragione su tutta la linea, e il mio errore è più grave di come lo poni.

**[M] Il file esiste.** `/i/Il mio Drive/Qbeats_IN_CD/2026-08-02_QLive-Metronome-EmptyState_390x844.html`
· **28 721 byte** (coincide esattamente col tuo numero) · 229 righe ·
sha256 `293fae04e9560489d01bc921199c0c10bd881f5e578c7cab765d9d3eff61a805` · mtime **2026-08-02 20:39**
locale (tu dicevi 18:39 — è lo stesso istante letto in UTC, non una discordanza).

**[M] Contenuto verificato verbatim**, non per fiducia:
- copy EN: «No show running» · «The metronome runs with a show. Nothing is playing right now.»
- «⛔ ZERO PULSANTI NEL CORPO — nessuna CTA, nessun Start, nemmeno disabilitato.»
- «Corpo = pattern `EmptyStateLayout` (badge + titolo + descrizione)»
- «Footer = ASSENTE… ⇒ Questa schermata = pattern Ⓕ/Ⓖ MENO `.startfoot`. Nessun componente nuovo.»

**[M] La ratifica esiste**, cercata per contenuto: `LIBRO_MASTRO_QBEATS.md:351`, riga datata
`2026-08-06`, «R3 — LA `.navbar` DELL'EMPTY-STATE DEL METRONOMO RESTA», che dichiara testualmente
«**su questo punto ⟦S5⟧ NON è più bloccato**» e «Nessuna modifica al file del 02/08: la ratifica
**CONFERMA** il disegno esistente».

**[M] Il pannello del freeze rev3 esiste** al blob `430c9894…` che mi hai dato: contiene
«B · La schermata che il referee dà per mancante», il percorso
`DA_CD_PER_CC/02_08_2026/DESIGN/QLive_Nav/2026-08-02_QLive-Metronome-EmptyState_390x844.html`
e la frase «Il buco non è nel disegno: è nelle liste».

**[M] La mia fonte era stale, e lo posso datare.** `QLiveRootView.swift:160-172` è tutto un unico
blocco introdotto da `bfc92285` del **31/07** (`git blame -L 160,172` → 13 righe su 13, un solo
commit). La ratifica è del **06/08**: il commento è **più vecchio di sei giorni** e non poteva
saperlo.

⇒ **La mia D3 è sbagliata e va ritirata**, e con essa la frase «non esiste freeze» in §2 della
roadmap. Confermo anche il principio che chiedi: **un commento nel codice non è una fonte sullo stato
di un documento fuori dal codice.** Il commento descrive l'intenzione di chi scriveva quel giorno;
non si aggiorna da solo quando il mondo cambia. Va **marcato**, non creduto.

⚠️ **E l'errore mio è peggiore di così.** La mia prima ricerca del file ha reso **zero su tutti i
supporti** — e ho scritto «non esiste» basandomi su quello. Era un **falso-zero da radice sbagliata**:
avevo cercato in `/i/Il mio Drive/Qbeats`, e il file sta in `/i/Il mio Drive/**Qbeats_IN_CD**`, una
cartella sorella. È **esattamente** la trappola già censita per il mirror E: («cercarlo alla radice
rende un falso assente»), e ci sono ricascato in undici giorni. Questo non è un dettaglio: è il
motivo per cui il tuo punto ⑧ è più forte di come lo poni tu.

---

## ③ IL PREREQUISITO DI CONTRASTO — **ACCETTO la catena · CORREGGO un dato**

**[M] La dipendenza è dichiarata da CD, testuale**, dentro il file del 02/08: «…che quel ticket sia
chiuso, perché oggi il kit renderebbe 0,30. Il ticket chiede di promuovere…». E il token divergente
c'è: `--text2r:rgba(255,255,255,0.60)` con il commento «UNICA divergenza di token dal kit: `--text2r`
(0.60) al posto di `text3` (0.30)», usato da `.ed{… color:var(--text2r) …}`.

**[M] Il tuo conto del contrasto è esatto.** L'ho rifatto io, composito su `#0e0e10` con la formula
WCAG:
- white 0.30 → luminanza relativa 0,0939 · **contrasto 2,64 : 1** (sotto il pavimento 4,5)
- white 0.60 → luminanza relativa 0,3452 · **contrasto 7,26 : 1**

Entrambi coincidono con i tuoi due numeri alla seconda cifra. **Non ho trovato nulla da smontare.**
E il rilievo che ne fai è quello giusto: su questa schermata quella riga non è secondaria, è
**l'unico contenuto**.

**[M] I due ticket esistono**, cercati per contenuto:
- `TD-qlive-token-text2r-non-onorato` → **`BUGS:623`**, titolo «🟡 OPEN BASSA / violazione di
  contratto CD» — **§1.3**. ✅ come dici tu.
- `TD-emptystatekit-theme-dep` → **`BUGS:579`**, 🔵 COSMETICO — **§1.3, non §1.2.**

**CORREZIONE [M]:** i confini misurati sono §1.2 → `:173`, §1.3 → `:398`, §1.4 → `:668`. Poiché
`398 < 579 < 668`, il ticket è in **§1.3**. La tua scheda lo dà in §1.2 — ma i confini che tu stesso
mi fornisci fra parentesi lo collocano in §1.3: è la tua etichetta a contraddire i tuoi numeri, non i
numeri a essere sbagliati. Correzione di forma, **la sostanza non cambia**: resta una voce 🔵
cosmetica in fondo al backlog.

**[M] Il «insieme» è verbatim nel tracker**, non una tua inferenza: `BUGS:630` — «⚠️ Da fare
**insieme** al fix di `TD-emptystatekit-theme-dep`, o si tocca due volte lo stesso file.»

⇒ **Confermo la catena e confermo che vanno in Fase 1.** Due voci classificate 🟡 bassa e 🔵
cosmetica sono prerequisiti del cardine: la classificazione misura il *fastidio dell'utente*, non la
*posizione nel grafo delle dipendenze*, e qui le due cose divergono. È il reperto più utile di tutto
il tuo mandato, perché è **strutturale**: nel tracker non esiste alcun asse che dica «questo blocca
altro».

⚠️ **Una tensione che dichiaro invece di nasconderla.** In ② ho appena dichiarato **stale** il
commento `QLiveRootView.swift:160-172`, e in ③ mi appoggio a quello stesso blocco per la clausola
«⟦S5⟧ non parte senza l'empty-state». Non posso dire stale una metà e autorevole l'altra senza una
ragione. La ragione c'è, ed è nella ratifica stessa: `LIBRO:351` è dichiarata «decisione di **ambito**,
non di contenuto» e tocca **solo** lo scoping del divieto «zero pulsanti» al corpo. Non nomina, non
tocca e non supera la clausola di precedenza dell'empty-state. ⇒ Quella clausola **resta in piedi**,
la clausola «non esiste freeze» **cade**. Distinzione di principio, non di comodo.

---

## ④ ORDINE — **CORREGGO: accetto la conclusione, smentisco il meccanismo e la severità**

Questa è l'unica in cui ti smonto qualcosa, e ti chiedo di rimisurarla tu.

**La tua tesi:** con il mixer aperto BACK TO SHOWS è «coperto al 100% più il velo tappabile», «l'unica
uscita sarebbe uccidere l'app», «il collaudo fallisce».

**[M] Geometria misurata a fonte.** `LiveView.swift:194-207`: un `VStack` a tutto schermo con
`Spacer()` in testa; quando `showMixer` è vero seguono **(a)** un `Color.clear` alto
`geo.size.height * 0.49` con `.contentShape(Rectangle())` e `.onTapGesture { session.showMixer = false }`,
**(b)** `MixerOverlayView`, che si dichiara alto `UIScreen.main.bounds.height * **0.21**`
(`MixerOverlayView.swift:24`).

⇒ Dal basso: mixer **opaco** da 79 % a 100 % · velo **trasparente e tappabile** da **30 % a 79 %**.

**[M] Dove sta il bottone.** `FineSetlistView.swift:20-36`: `ZStack` senza `alignment` — quindi
**centrato** — con `VStack(spacing:24){ "END SHOW"; VStack(spacing:12){ BACK TO SHOWS; RESTART SETLIST } }`.
Il gruppo dei pulsanti cade poco **sotto la metà verticale**, cioè in un intorno del **52-62 %**.

⇒ **52-62 % cade dentro il velo (30-79 %), NON sotto il pannello opaco.**

**Conseguenza reale, che è diversa dalla tua:** il velo è `Color.clear`, quindi il bottone **si vede**.
Il primo tocco però colpisce il velo e **chiude il mixer**; il secondo tocco raggiunge il bottone e
funziona. Non è una trappola: è **un primo tocco morto sull'unica uscita**. Nessuno deve uccidere
l'app, e **il gate non fallisce**: si può eseguire col mixer chiuso e validerebbe il cablaggio.

**E ti contesto anche l'uso della citazione.** `LIBRO:329` dice che il controllo procedurale è
«inaccettabile **come stato terminale in un prodotto venduto**». Quella frase vieta di *spedire* un
prodotto che si regge sulla disciplina dell'operatore — non vieta di *condurre un collaudo* con una
procedura controllata. Usarla per dire «il gate è impossibile» la porta fuori dal suo ambito.

**⇒ E ciononostante: ACCETTO la tua conclusione.** 2.1, 2.2 e 2.3 salgono in Fase 1, prima del gate
1.3. Per tre ragioni, nessuna delle quali è quella che hai scritto tu:

1. **[M]** Un primo tocco morto sull'unica uscita, al buio, a fine concerto, è esattamente la classe
   di difetto che questo progetto chiama bloccante-palco. Che sia recuperabile al secondo tocco lo
   rende meno letale, non accettabile.
2. **[M]** Per mia stessa misura il costo è «due righe / piccola / media»: **non sposta la Fase 1 di
   un giorno**, quindi non c'è nulla da bilanciare.
3. **[I] È questa la ragione decisiva, ed è tua:** il tempo-device di Mauro è la risorsa più scarsa
   del progetto — **una sola sessione dal 29/07**. Se il fix precede il gate, quella sessione valida
   END SHOW *come lo incontrerà l'utente*, mixer aperto compreso. Se lo segue, ne servono due.

**[M] Motivo tecnico per cui il fix DEBBA venire dopo lo Start: non esiste.** Legare `showMixer` a
`playbackState` è un osservatore dentro `LiveView`, compila e passa la CI a prescindere dalla
raggiungibilità. Va in cieco — non si può provare finché lo Start non c'è — ma si prova nella stessa
sessione. **Nessuna perdita.** Confermo che non vedo l'ostacolo che chiedevi di cercare.

---

## ⑤ ⟦S-EXIT⟧ — **ACCETTO**

**[M]** Il vincolo esiste ed è verbatim in `LIBRO_MASTRO_QBEATS.md:329`, riga datata `2026-07-31`:
«⛔ **VINCOLO RATIFICATO: nessuna sessione multi-device e nessuna data con band su una build che
contenga ⟦S5⟧ finché ⟦S-EXIT⟧ non è chiuso device.**»

⇒ Hai ragione: **non è debito documentale.** La mia 2.6 lo colloca sotto la colonna «documenti» in
Fase 2, e quella collocazione è sbagliata — nasconde un cancello di palco dietro un'etichetta di
igiene. È lo **stesso identico difetto** che io contesto al tracker in §1.5 della roadmap
(`TD-fineshow-bottoni-morti` bloccante dentro la sezione dei non-bloccanti): l'ho denunciato negli
altri e l'ho rifatto io. Va corretto.

**[M] Confermo che le due cose possono correre insieme senza interferire.** ⟦S5b⟧ tocca
`QLiveSession` (il mutatore), il punto di costruzione del runner e la navigazione in
`QLiveRootView`. ⟦S-EXIT⟧ è materia di uscita-stanza col click attivo: vive su `AppRootView.swift:70-77`
e sul ramo di stop in `AudioEngine`. **Nessuna sovrapposizione di file fra i due**, e la scheda di
⟦S-EXIT⟧ è lavoro di progettazione, non di codice. ⇒ Non mi serve nulla da quel lavoro per fare
⟦S5b⟧, e possono procedere in parallelo.

---

## ⑥ LA MIA §1.3 — **ACCETTO, ed è il rilievo che mi costa di più**

**[M] La cronologia ti dà ragione, con i timestamp.**

| oggetto | commit | istante |
|---|---|---|
| ultimo commit su `ios_app/` | `4e4c241` | **2026-08-06 17:14:11 +0200** |
| ratifiche del 06/08 (font 29px · `.seg-mini` abolita) entrano nel LIBRO | `2960f08` | **2026-08-07 10:51:43** |
| ratifica RESTART SETLIST entra nel LIBRO | `81740e4` | **2026-08-07 20:53:57** |

Tutte e tre le ratifiche sono state **incise dopo** l'ultimo commit di codice. **Nessun commit poteva
portarle**, e contarle come deriva è un errore di categoria.

**[M] E la contraddizione interna che mi contesti è reale.** Nella roadmap, al punto 0.2, chiamo le
due righe del 06/08 «un delta già noto e tracciato» per dire a Mauro di non bocciare il gate ⟦S5a⟧
sulla tipografia; in §1.3 le stesse due righe le conto come prova di deriva. **Non possono essere
entrambe**, e la seconda è quella sbagliata.

⇒ **Accetto di separare le due categorie**, e la separazione rafforza il reperto invece di
indebolirlo:
- **«ratificato e mai costruito»** — il divario vero: chip Read-only (27/07, tre settimane), KILL
  TRACK ed EMERGENCY (21/05, **tre mesi**), `.stoppedMidSong` a zero occorrenze mentre il LIBRO
  dichiara che il nome vecchio «non è mai entrato in codice», LOOP (29/04), i bottoni STOP in
  italiano, e le **due righe su Link che il codice contraddice** — che sono la categoria peggiore di
  tutte, perché lì non manca il lavoro: c'è il lavoro sbagliato.
- **«deciso dopo l'ultimo commit»** — arretrato normale, tre righe, nessuna anomalia.

⚠️ **Autodenuncia sul «almeno 15».** Quel numero **non l'ho misurato io**: viene da un agente di
lettura e l'ho relayato senza rimisurarlo. È **[R]**, e la roadmap lo presenta come **[M]**. È
esattamente l'errore che il progetto ha censito sette volte a tuo carico il 07/08, e questa volta è
mio. Il numero va rifatto da zero con il filtro cronologico applicato riga per riga, e finché non è
rifatto **non va citato**.

**Hai ragione sul rischio:** con «il caso più netto» che è in realtà il più debole, la prima persona
che se ne accorge scarta tutta la tabella.

---

## ⑦ L'EMPTY DEL CASO FALLIMENTO — **ACCETTO**

**[M]** Il freeze rev3 (blob `430c9894…`) lo dichiara testualmente: «l'empty del caso **FALLIMENTO**»
· «sintesi della sezione "free" fallita, o **motore audio non disponibile ⇒ pagina metronomo senza
runner**. È un empty…».

⇒ Confermo entrambe le cose: **è un disegno a sé**, e **non blocca ⟦S5b⟧**. Il caso nominale ha il
suo disegno (il file del 02/08) e la sua ratifica (`LIBRO:351`); il caso di guasto è una schermata
diversa, con copy diversa, per una condizione che oggi non è nemmeno producibile. È l'unica domanda
legittima aperta verso CD, e può essere fatta senza fermare nulla.

---

## ⑧ IL FILE IN UNA COPIA SOLA — **ACCETTO, e lo aggravo**

**[M]** Ricerca su tre supporti: il file esiste **solo** in
`/i/Il mio Drive/Qbeats_IN_CD/`. Non nel repo (working tree), **non in git in nessun punto della
storia** (`git log --all --diff-filter=A` su `*Metronome*` non lo rende), non su E:. **Una copia, su
un supporto la cui lettera di unità non è nemmeno stabile.**

⇒ Sì: **il rimedio è un atomo doc, non un promemoria**, e per la ragione che dici — il freeze del
06/08 aveva **previsto** che senza una riga in SCALETTA il file «risulterà mancante a ogni giro».

**E la prova che avevi ragione l'ho fornita io, sedici giorni dopo, in questa stessa sessione:** ho
cercato quel file, ho ottenuto zero, e ho scritto in una consegna a Mauro che il disegno non esiste e
che serviva una consegna di CD. Un documento che vive in una sola copia fuori dal controllo di
versione **non è un rischio teorico**: ha già prodotto un errore in un documento operativo. Il tuo ⑧
non è l'ottavo punto per importanza, è la causa del secondo.

---

## ⑨ «USCITA METRONOMO» — **CORREGGO la premessa: la misura non chiude la domanda**

**[M]** `MetroFAB` è montato in **due** punti, e in **entrambi** è inerte:
- `QLiveShowsView.swift:255` → `MetroFAB()` — **senza argomento**, quindi vale il default
  `var onTap: () -> Void = {}` (`MetroFAB.swift:20`). Corpo vuoto.
- `QLiveEmptyStates.swift:168` → `MetroFAB(onTap: onMetroTap)`, dove `onMetroTap` è a sua volta
  dichiarato `= {}` (`:146`) e **nessun chiamante lo valorizza** (`grep -rn 'onMetroTap'` → 3 sole
  occorrenze, tutte dentro quel file). Corpo vuoto.

Il commento a `QLiveEmptyStates.swift:139` lo dichiara: «Cablaggio (`onGoToQStage` / `onMetroTap`) =
S6, qui restano no-op di default».

⇒ **La misura non chiude la domanda di CD e non la lascia aperta: mostra che non è mai stata posta al
codice.** Il pulsante non punta da nessuna parte in nessuno dei due montaggi, quindi non esiste una
scelta implicita da leggere. La domanda «uscita **verso** il metronomo libero» vs «uscita **dal**
metronomo» resta **integralmente aperta** e la risposta la deve dare CD, non il codice.

⚠️ **Rilievo che aggiungo io, e che tocca la tua ⑨.** Dire che il freeze del 06/08 «dichiara la
schermata costruibile, che è una risposta di fatto» è un passaggio che non regge: la costruibilità
dell'empty-state riguarda la **destinazione**, non la **porta che ci arriva**. Sono due decisioni
diverse. La prima è ratificata, la seconda no. ⇒ E c'è una conseguenza pratica: `MetroFAB()` a
`QLiveShowsView:255` è **un terzo pulsante morto** nella UI spedita, accanto a `emerg` e a RESTART
SETLIST, e **non ha un ticket in BUGS** (`grep -c 'MetroFAB' BUGS_QBEATS.md` da eseguire in un giro
autorizzato — qui non riclassifico nulla).

---

## RIEPILOGO DEI NOVE VERDETTI

| # | oggetto | verdetto |
|---|---|---|
| ① | F1 ≠ `iOS Signed Build` | **ACCETTO** — e `LIBRO:330` cita come prova una run `failure` |
| ② | empty-state metronomo: il freeze esiste | **ACCETTO contro me stesso** — D3 ritirata; mia fonte stale di 6 giorni; mio falso-zero da radice sbagliata |
| ③ | prerequisito di contrasto | **ACCETTO la catena** (conto rifatto: 2,64 / 7,26) · **CORREGGO**: `TD-emptystatekit-theme-dep` è in §1.3, non §1.2 |
| ④ | ordine: mixer prima del gate | **CORREGGO** — conclusione accettata; meccanismo e severità smentiti: velo trasparente 30-79 %, bottone visibile, primo tocco morto, non trappola |
| ⑤ | ⟦S-EXIT⟧ è cancello di palco | **ACCETTO** — vincolo verbatim a `LIBRO:329`; parallelismo confermato, zero file in comune |
| ⑥ | separare le due categorie in §1.3 | **ACCETTO** — cronologia provata; contraddizione interna reale; «almeno 15» declassato a **[R]**, mai misurato da me |
| ⑦ | empty del caso fallimento | **ACCETTO** — disegno a sé, non blocca |
| ⑧ | file in una copia sola | **ACCETTO e aggravo** — la prova l'ho prodotta io oggi sbagliando |
| ⑨ | «uscita metronomo» | **CORREGGO la premessa** — inerte in entrambi i montaggi: la domanda non è mai arrivata al codice, resta aperta |

**Bilancio onesto: su nove punti ne accetto sei senza riserve, ne correggo tre — e di questi solo uno
(④) tocca la sostanza.** Le due correzioni maggiori alla roadmap (② e ⑥) sono **contro di me**, e la
peggiore delle due — il falso-zero di radice — è la stessa trappola che il progetto ha già censito e
che io avevo citato in apertura di sessione.

---

## COSA CAMBIA NELLA ROADMAP — proposta, non esecuzione

Non ho riscritto nulla, come da perimetro. Le modifiche che discendono da questo referto:

1. **Ritirare D3** e la frase «non esiste freeze» in §2. Sostituire con: il disegno esiste
   (02/08, ratificato `LIBRO:351`), e il vero prerequisito è la coppia di ticket di ③.
2. **Fase 1**: aggiungere i due ticket token **prima** di ⟦S5b⟧, e salire 2.1 / 2.2 / 2.3 **prima**
   del gate 1.3.
3. **Spostare ⟦S-EXIT⟧** da «documenti in Fase 2» a corsia parallela alla Fase 1, marcata cancello
   di palco.
4. **Spezzare §1.3 in due categorie** e **togliere «almeno 15»** finché non è rimisurato.
5. **Aggiungere** l'atomo doc di ⑧ (portare il file del 02/08 in `DESIGN/QLive_Nav/` + riga in
   SCALETTA) e la domanda di ⑦ a CD.
6. **Nominare** il terzo pulsante morto (`MetroFAB`) come reperto di ⑨.

⛔ Nessuna di queste è eseguita. Servono i due cancelli distinti: il tuo assenso su questo referto e
l'OK di Mauro.

---

*A90-CONTRADDITTORIO-FINE*
