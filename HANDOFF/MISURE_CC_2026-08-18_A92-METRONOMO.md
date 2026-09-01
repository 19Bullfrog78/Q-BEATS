# MISURE CC — A92, CHIUSURA DELL'EQUIVOCO «METRONOMO» (doc-only)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: **zero righe sotto `ios_app/`**, zero commit, zero push, albero pulito sui
tracciati. Scritture: **solo** questo referto e il file di diff, in `HANDOFF/` + propagazione R-δ.

Marcatura: **[M]** misurato ora da CC · **[D]** dichiarazione di Mauro (autorità di prodotto, non da
verificare) · **[I]** inferenza di CC.

---

## AGGANCIO — A92 libero

**[M]** Nomi, due supporti, entrambe le casse: `A92` → **0** in `HANDOFF/` (repo) e **0** su E:.
Controllo positivo `A90` → **1** su entrambi. Contenuti in forma a token: `\bA92\b` → **0** file;
controllo positivo `\bA90\b` → **4** file. **Non collide.**

---

## ⚠️ IL RILIEVO CHE VIENE PRIMA DEI SETTE FATTI

Il mandato dice: «da nessuna parte è scritto in chiaro cosa c'è dietro il pulsante METRONOME».

**[M] Misurato: è falso per due dei sette fatti.**

| fatto | dove era GIÀ scritto | dal |
|---|---|---|
| ① le due vie d'ingresso | `LIBRO_MASTRO_QBEATS.md:271` — «metronomo-libero = uscita metrofab (anche 0-show)» **e** `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:22` — elenco CONGELATO, «③ METROFAB=uscita metronomo» | **10/07**, due sedi |
| ③ il meccanismo | `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:32` — «**Riuso-LiveView-su-vuota:** `SetlistRunner:140-148` — setlist vuota → `guard currentSection nil` → `.fineSetlist` immediato (NON un metronomo). Il free-metronome richiede **Opzione 1**…» | **10/07** |

⇒ **[I] Questo cambia la diagnosi, e quindi il rimedio.** L'equivoco non è nato dall'assenza del
fatto: è nato **nonostante** il fatto fosse scritto, in un caso due volte. La causa misurabile è la
**dispersione**:

- a `LIBRO:271` il fatto vive come **inciso subordinato** dentro una riga che parla d'altro (il freeze
  di navigazione e il Nodo A). Chi cerca «cosa c'è dietro METRONOME» non arriva lì.
- a `SCALETTA:22` e `:32` vive in **sezione A di un documento di piano**, che si scrive una volta e
  non si rilegge — ed è lo stesso documento la cui sezione F è ancorata a un commit di 85 commit fa.

⇒ **Il rimedio non è «incidere una volta», è «consolidare in una sede che un lettore cross-team
colpisca».** Il diff proposto fa esattamente questo, e lo dichiara nella riga stessa invece di
fingere che il fatto sia nuovo. **Se avessi inciso ① e ③ come fatti nuovi avrei creato un terzo posto
dove cercarli, cioè peggiorato la causa.**

---

## I SETTE FATTI — verdetto uno per uno

### ① LE DUE VIE D'INGRESSO — **[D] acquisita · ancore [M] TROVATE ENTRAMBE**

**[M]** Le due ratifiche esistono, cercate per contenuto e non per riga:
`LIBRO_MASTRO_QBEATS.md:271` (riga datata 2026-07-10) e
`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:22`. ⇒ La dichiarazione di Mauro **conferma e non cambia**
nulla di ratificato. Inciso come **consolidamento dichiarato**, non come novità.

### ② RISPOSTA A R2 DI CD — **[D] acquisita · [M] la domanda esiste ed è aperta**

**[M]** Nel file CD del 02/08 la domanda c'è, verbatim: «`metronomo» vs «uscita metronomo`», con la
clausola con cui CD si dichiara pronta a rifare il lavoro: «**Se la lettura giusta e' quella del
brief, questa schermata cambia e torno a rifarla.**» ⇒ La risposta di Mauro **chiude** quella
clausola. Inciso.

### ③ PERCHÉ NON ESISTE ANCORA — **[M] CONFERMATO A HEAD, e già inciso dal 10/07**

**[M]** Verificato per simbolo poi per riga, ancorato a 40, a
`321293e18094d9d4f1c167bfc921be1ad216e3ac`:

- `ios_app/QBeats/SetlistRunner.swift:109` — `func startSetlist(…)` → chiama `prepareAndStartCurrentSection`
- `:142` — `guard let section = currentSection else {`, con commento verbatim: «*Stato degenerato:
  setlist vuota o currentSongIdx fuori range. Trattato come fineSetlist immediato.*»
- `:148` — `session.playbackState = .fineSetlist`

⇒ **Il meccanismo è esattamente quello atteso**: riusare la LiveView su una scaletta vuota **non**
produce un metronomo, produce la schermata di fine show. Serve **Opzione 1**; **Opzione 2** resta
vietata. **Nessuna discrepanza: non mi fermo.**
⚠️ Ma vedi il rilievo sopra: era **già inciso** a `SCALETTA:32`. Non lo re-incido in LIBRO; lo
**rimisuro e lo ri-ancoro** nella marcatura alla scheda ⟦S6⟧, dove serve a chi cabla.

### ④ PERIMETRO DELL'EMPTY-STATE — **[M] CONFERMATO**

**[M]** Il file CD del 02/08 dichiara la copy **«provenienza-agnostica»** (intestazione del pannello
②) e valida «**per entrambe le provenienze**», misurato verbatim nel file. ⇒ Quella metà è superata
da ①. Inciso come **marcatura**: il file non si tocca e a CD **non** si chiede di riemettere.

### ⑤ ⟦B2⟧ CASO Ⓑ — ⛔ **NON REGGE COME FORMULATO. MI FERMO E NON INCIDO.**

Il mandato dispone «Marcato, non rimosso». **[M] Non esiste nulla da marcare.**

| ricerca | risultato |
|---|---|
| `⟦B2⟧` · `\bB2\b` · `Ⓑ` nei **cinque canonici** (LIBRO, BUGS, BOX3, BOX5, SCALETTA) | **0 occorrenze** |
| `>B2<` nel freeze rev3 (blob `430c9894…`) | 1 |
| `Ⓑ` nello stesso blob | 7 |
| **controllo positivo, stesso blob, stessa forma:** `Ⓐ` → 6 · `⑤` → 3 | forma di ricerca **valida** |

⇒ **⟦B2⟧ e il caso Ⓑ vivono SOLO dentro l'HTML del freeze, e in nessun canonico.** «Marcare» presuppone
una riga canonica da marcare: **non c'è**. Inciderlo sarebbe una **inscrizione nuova**, cioè un atto
diverso da quello che il mandato dispone, e su un oggetto che nessun canonico ha mai ospitato.

**[M] La sostanza però è corroborata**, e la riporto perché non vada persa: il testo del caso di
guasto esiste nel freeze, verbatim — «*sintesi della sezione «free» fallita, o motore audio non
disponibile ⇒ pagina metronomo senza runner. È un empty*». ⇒ È lo **stesso oggetto** che il tuo ⑦
chiama «empty del caso FALLIMENTO», e che ho già dichiarato in A90 come disegno a sé che **non blocca
⟦S5b⟧**.

**[I] Proposta, non eseguita:** se lo si vuole agli atti, la forma corretta non è una marcatura ma
**una riga nuova**, e la sede naturale è la stessa domanda a CD di ⑦ — un solo oggetto, non due.
**Attendo disposizione: non l'ho inciso.**

### ⑥ I PULSANTI INERTI SONO UNA SCELTA — **[D] acquisita · [M] la verifica su CD-Q7 REGGE, ed è peggio di così**

**[M] L'origine di CD-Q7 è come la poni:** fu decisa **per un pulsante solo**.
`LIBRO_MASTRO_QBEATS.md:272` (2026-07-11): «**Q7 (risolta)** — Header Q-Stage›Shows: «+» (creazione
show) OMESSO finché §8 … non arriva. Fino ad allora l'header è IDENTICO a Q-Live: stesso componente
`.roombar.center`/`.roomseg`, **nessun bottone morto o disabilitato**…». La formula generale nasce
**dentro** quella decisione di ambito.

**[M] E la generalizzazione è documentata in due passaggi successivi:**
- `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:327` la trasforma in divieto: «NIENTE bottone morto. La
  10/07 diceva "bottone presente, azione off": **ora è VIETATO**».
- `BUGS_QBEATS.md:168` la cita come «**Regola violata**» dentro `TD-emerg-bottone-morto`.

⛔ **[M] E qui c'è il reperto che il mandato non aveva: la generalizzazione HA GIÀ PRODOTTO UNA
PERDITA.** Verbatim a fonte,
`ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:50 @ 321293e18094d9d4f1c167bfc921be1ad216e3ac`:

> `// ⚠️ `.viewtoggle` (Q-Live view / List view) OMESSO: precedente ratificato Q7`

E il freeze consolidato di CD lo registra dal suo lato: «*il `.viewtoggle` del dettaglio NON esiste a
HEAD (**tolto per equivoco**)*».

⇒ **Un controllo disegnato è stato tolto dalla schermata spedita per una regola nata per un altro
pulsante, e CD stessa lo chiama equivoco.** Questa non è una riga di igiene documentale: è la riga
che impedisce alla prossima rimozione di succedere. **È il fatto più importante del mandato**, e vale
più di come lo poni tu.

**[M] Conseguenza obbligata sul tracker, e la incido:** la voce «Regola violata — CD-Q7» di
`BUGS:168` **diventa falsa** per quel ticket. Il ticket **si scrive lo stesso**, con lo Stato che
cambia in «in attesa di destinazione, **per scelta**», come disponi.

### ⑦ «EMERG» HA UNA DESTINAZIONE NOTA — **[D] acquisita · [M] CORROBORATO IN PIENO**

**[M]** Il commento nel codice porta l'intenzione da prima che fosse ratificata:
`ios_app/QBeats/UI/Live/TransportView.swift:90-92 @ 321293e1…` —
`{ /* navigazione Vista LISTA — Fase successiva */ }`.

**[M] E il legame col `.viewtoggle` regge alla misura, meglio di come lo poni:** non sono «due cose
che si somigliano», sono **la stessa funzione con due controlli**. Il `.viewtoggle` si chiama
letteralmente «**Q-Live view / List view**» (`QLiveShowDetailView.swift:50`), ed «emerg» commuta
Q-Live → Vista LISTA. Stesso passaggio, due schermate. ⇒ **Si progettano e si cablano insieme.**
Inciso.

⚠️ **Una precisazione [M] che tolgo dalla tua formulazione:** `.viewtoggle` rende **0 occorrenze in
tutti e cinque i canonici** (controllo positivo sullo stesso giro: le stesse ricerche rendono valori
non nulli su altri token). Esiste solo **nel codice** (1, il commento di omissione) e **nel freeze
CD**. ⇒ Non potevo inciderlo come rimando a un elemento ratificato, perché ratificato non è: l'ho
inciso come **fatto nuovo, con l'indirizzo del codice a 40**.

---

## SEDE — verificata, non ereditata

Ho misurato le tre regole che il mandato presume, invece di applicarle a memoria.

**LIBRO = ratifiche cross-team.** `LIBRO_MASTRO_QBEATS.md:22` pone la regola d'oro («se una decisione
non è in Sezione 2 con stato attiva, non è ratificata») e lo scopo del documento è dichiarato
cross-team CD↔CC. **Test «CD deve saperlo o coordinarcisi?»** applicato a ognuno:

| fatto | test | sede |
|---|---|---|
| ① + ② | **sì** — cambia cosa esiste dietro un pulsante disegnato da CD, e ② è letteralmente una risposta *a* CD | **LIBRO Sez.2** (una riga sola: sono lo stesso oggetto) |
| ④ | **sì** — marca il perimetro di un file di CD | **LIBRO Sez.2** |
| ⑥ | **sì** — eccettua una regola che CD ha formulato | **LIBRO Sez.2** + marcatura in BUGS |
| ⑦ | **sì** — è una destinazione di disegno | **LIBRO Sez.2** |
| ③ | **no** — meccanismo interno CC, e **già inciso** a `SCALETTA:32` | **marcatura alla scheda ⟦S6⟧**, dove serve a chi cabla |
| ⑤ | — | **non inciso**, vedi sopra |

**SCALETTA sez. C = sede unica dell'ordine degli atomi.** ⇒ **Non tocco la sez. C**: nessuno dei
sette fatti cambia l'ordine degli atomi. La marcatura di ③+④ va sulla **scheda ⟦S6⟧** (`:313-317`),
che è dove vive la destinazione del METROFAB, non nell'ordine.

**BUGS = i ticket.** ⇒ La marcatura di ⑥ va sul ticket `TD-emerg-bottone-morto`.

### Anti-cascata — misurata, non presunta

**[M]** Censite **27** citazioni alla SCALETTA per numero di riga, in **due forme**
(`SCALETTA_ATOMI_S6_2026-07-10.md:NNN` e `SCALETTA:NNN`), su canonici + `ios_app/`.
Righe citate **nude** (senza `@ commit`): 8 · 129 · 130 · 141 · 144 · 210 · 213 · 219 · 234 · 261 ·
272 · 275 · 290 · 297 · **300**. Ancorate (immuni): 141 · 300 · 314 · 322.

⇒ **La citazione nuda più alta è la riga 300.** Le inserzioni del diff cadono a **riga ≥ 318**.
**Nessuna citazione nuda si sposta.** Il vincolo che blocca ogni inserzione *in testa* a quel file
resta intatto e non viene toccato da questo giro.

---

## IL DIFF

`HANDOFF/DIFF_2026-08-18_A92-METRONOMO.txt`
**sha256** ``7e3e8a0e86de477872dd03a7d17ad452f5577bea790a09a394bd5de3610ae4ef``

- **Tutto additivo**: zero parole riscritte, zero righe rimosse, zero righe sotto `ios_app/`.
- **Decorazione di versione nel PREAMBOLO**, sopra le righe `---`/`+++` — forma verificata in A86,
  così `git apply` legge il patch e **non serve GNU `patch`**, che riscriverebbe le fini-riga.
- **[M] Verificato applicabile**: `git apply --check` → **exit 0** su tutti e tre i file, con
  l'albero che resta pulito (`--check` non scrive).
- Hunk: `LIBRO @@ -354,4 +354,8` · `SCALETTA @@ -318,4 +318,5` · `BUGS @@ -171,1 +171,2`.

⚠️ **Omissione dichiarata, non dimenticanza:** i **bump di intestazione** (v55→v56, v51→v52, v9→v10)
e le righe di **Sezione 6 «storico versioni»** **non** sono in questo diff. Si compongono dopo la
ratifica del contenuto, per non rifarli se il contenuto cambia. **Il commit non parte senza di essi.**

---

## CODA — altri difetti trovati, ELENCATI E NON TOCCATI (regola di proporzione)

1. **[M]** `BUGS:163` afferma che «emerg» «è RAGGIUNGIBILE OGGI … sul percorso normale». **Misurato
   falso** il 18/08 (A90): la pulsantiera vive solo dentro `LiveView`, irraggiungibile a HEAD. È la
   frase che dà al ticket la sua urgenza. Non toccata qui.
2. **[M]** `MetroFAB()` a `ios_app/QBeats/UI/QLive/QLiveShowsView.swift:255` è montato **senza
   argomento** → default `{}`: è un **terzo pulsante inerte** nella UI spedita, e **non ha un ticket
   in BUGS**. Con ⑥ non è più un difetto da rimuovere, ma resta da tracciare.
3. **[M]** La rimozione del `.viewtoggle` da ⟦S5a⟧ — che CD chiama «tolto per equivoco» — **non ha un
   ticket**. Con ⑥ diventa un ripristino da programmare, non un debito silenzioso.
4. **[M]** `TD-emerg-bottone-morto` è in §1.1 con severità **PROPOSTA e non assegnata**: resta la
   decisione D2 in capo a Mauro, e ⑥ ne cambia il presupposto.

---

## RIEPILOGO

| # | verdetto |
|---|---|
| ① | **[D]** acquisita · **[M]** entrambe le ancore trovate · **INCISO** come consolidamento dichiarato |
| ② | **[D]** acquisita · **[M]** domanda e clausola di CD trovate verbatim · **INCISO** |
| ③ | **[M] CONFERMATO a HEAD** (`SetlistRunner.swift:142`, `:148`) · **già inciso dal 10/07** a `SCALETTA:32` · **rimisurato e ri-ancorato**, non re-inciso |
| ④ | **[M] CONFERMATO** («provenienza-agnostica», «entrambe le provenienze») · **INCISO come marcatura** |
| ⑤ | ⛔ **NON REGGE COME FORMULATO — NON INCISO.** Zero occorrenze di ⟦B2⟧/Ⓑ in tutti e cinque i canonici, con controllo positivo valido. Nulla da marcare. Sostanza corroborata, forma da rifare |
| ⑥ | **[D]** acquisita · **[M] la verifica su CD-Q7 REGGE** · e **la generalizzazione ha già tolto il `.viewtoggle`**: reperto nuovo, più grave di come posto · **INCISO** in LIBRO + marcatura in BUGS |
| ⑦ | **[D]** acquisita · **[M] corroborato in pieno**, e il legame è più stretto di come posto (stessa funzione, due controlli) · **INCISO**, con la precisazione che `.viewtoggle` non era ratificato da nessuna parte |

**Sei fatti su sette incisi. Uno fermato.** E un rilievo che precede tutti: due dei fatti **erano già
scritti**, quindi la causa dell'equivoco non è l'assenza ma la dispersione — ed è per questo che il
diff consolida invece di duplicare.

⛔ **Nessun commit.** Servono i due cancelli distinti: ratifica del referee sul diff verbatim, poi OK
esplicito di Mauro. Non si fondono.

---

*A92-METRONOMO-FINE*
