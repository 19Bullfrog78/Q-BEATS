# REFERTO CC — A222, giro documenti 26/08/2026

Da: CC · A: referee + Mauro · Mandato: **A222** (referee), otto punti.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio. ⛔ Mai mescolati in una frase.

⚠️ **Tutte le misure sono state scattate PRIMA del deposito di questo file.**
Orologio: apertura del giro **11:36:16**, chiusura **11:49:44** del 26/08/2026.

---

## 0 · ID A222 — misurato, non scelto a occhio

**[M]** Sonda su due supporti (NOME e CONTENUTO), tracciati e non tracciati, su
entrambe le gambe. Gamba CONTENUTO-git con `-- ':!DESIGN'`, per `R-δ.10`.

| ID | NOME git / discoC / discoE | CONT git / hoffC / hoffE |
|---|---|---|
| **A222** (preso) | 0 / 0 / 0 | 0 / 0 / 0 |
| A220 (positivo: congedo di oggi) | **1** / **1** / **1** | **1** / **1** / **1** |
| A218 (positivo: lavoro vero) | 0 / 0 / 0 | **2** / **2** / **2** |
| A211 (positivo: storico) | **2** / **2** / **2** | **5** / **10** / **9** |

✅ **[M] I tre controlli positivi rendono tutti non-zero: la sonda funziona.**
A222 è pulito **anche senza** l'esclusione di `DESIGN/`.
⛔ **[M] I candidati scartati non sono nominati per cifra**, per `R-δ.9`.

---

## 1 · PUNTO 1 — stato del mirror `E:` del LIBRO

**[M] ADESSO È ALLINEATO.** Misurato alle 11:36:16:

    HEAD (git)  = **Versione:** 64 (26/08/2026)
    C: disco    = **Versione:** 64 (26/08/2026)
    E: mirror   = **Versione:** 64 (26/08/2026)
    byte 300 590 su entrambe le gambe · sha256 64e88ea7…d393 · cmp exit 0

⚠️ **[M] Ma lo è da stamattina, e prima non lo era: era fermo a `**Versione:** 56
(18/08/2026)`, 275 470 byte.** L'ho allineato io nel mandato A221, alle 09:2x.
⇒ **Il divario era di SETTE versioni** — 57, 58, 59, 60, 61, 62, 63 mai
propagate, otto giorni di consegne passate ciascuna col proprio `cmp` verde.

⇒ **[A] Il dato che conta non è il divario, è come è potuto restare invisibile:
ogni consegna verificava `cmp` SUL FILE CHE STAVA SCRIVENDO, e nessuna
guardava gli altri.** Un `cmp` a exit 0 è una prova locale, non una prova di
allineamento del mirror.

**[M] Secondo dato, perché chi cerca «il LIBRO su E:» trova DUE file:** esiste
una seconda copia in `DA_CD_PER_CC/11_07_2026/1Q-BEATS/uploads/`, ferma a
`**Versione:** 13`. **Non è un mirror: è un upload storico dell'11/07.**

---

## 2 · PUNTO 2 — dove vive la frase sul `2>/dev/null`. MISURA, NESSUNA DECISIONE

⛔ **[A] Non decido come chiamarla, né rinumero alcuna serie.** Riporto quattro
misure e mi fermo, perché la tassonomia è materia del referee.

**[M] (a) La frase vive in UN solo documento del repo**, ed è
`HANDOFF/CONGEDO_CC_2026-08-26_A220.md` (tracciato da stamattina, commit
`bf211b6`), §1.2 e §8. Verbatim dal file, righe 109-125 e 379-381:

> «**[M] Causa:** l'ambiente **rifiuta** gli endpoint `/contents/` di `gh api`
> … Il mio `2>/dev/null` l'ha nascosto, `--jq` su un errore rende stringa
> vuota, e la variabile vuota e' diventata «ASSENTE».»
>
> «⛔ **Mai `2>/dev/null` su una sonda la cui risposta finisce in un referto.**»

🚨 **[M] RETTIFICA A222→A223 — QUESTE DUE RIGHE ERANO FALSE, E LE HO SCRITTE IO.
Il referto non era tracciato quando l'errore è stato trovato, quindi si CORREGGE
e non si marca; ma l'errore resta scritto qui, perché la sua forma è la lezione.**

**[M] Diceva:** «*In quel congedo la frase NON è numerata. La parola «sesta» non
compare: la sonda su `sesta forma|SESTA FORMA` rende zero su quel file.*» e
«*L'ordinale «sesta» esiste solo FUORI dal repo … non c'è nulla da rinumerare in
un canonico: non ci è mai entrata.*»

**[M] Rilevato dal referee sul tarball pubblico a `bf211b6`, e RIMISURATO da me
alla fonte prima di correggere — le due misure coincidono alla cifra:**

| sonda su `HANDOFF/CONGEDO_CC_2026-08-26_A220.md` | esito |
|---|---|
| `sesta forma\|SESTA FORMA` — **quella che ho ESEGUITO** | **0** |
| `sesta` nuda — **quella che ho DICHIARATO** | **1**, alla riga **439** |
| `sesta` case-insensitive | **1** |
| controllo positivo `falso-zero` | **3** ⇒ la sonda vede |

**[M] Verbatim della riga 439, identica su disco e nel blob a `bf211b6`:**

> `**E' la sesta faccia del falso-zero da filtro, e stavolta l'ho pagata io.**`

⇒ **[A] La forma esatta dell'errore: ho eseguito una sonda STRETTA e ne ho
dichiarato una LARGA.** Il numero era vero per `sesta forma`; l'ho riportato come
se valesse per `sesta`. **Non è un errore di misura — la misura era giusta — è un
errore di DESCRIZIONE della misura**, e nessuna sonda lo intercetta: intercetta i
numeri, non le didascalie. ⛔ **Una sonda si cita con la stringa esatta che le
hai dato, mai con una sua parafrasi più comoda.** È la prima forma di falso-zero
già censita in casa — la notazione del filtro — prodotta stavolta **nel referto e
non nel terminale**.

**[M] (b) L'ordinale «sesta» È NEL REPO, tracciato in git dal commit `bf211b6`
di stamattina.** ⛔ **Questo cambia la natura del problema: non è una cosa da
recuperare, è una cosa da RICONCILIARE.**

⚠️ **[M] E la riconciliazione è più larga di così: ci sono TRE «sesta» diverse,
in tre sedi, e due sono in git.**

| sede | in git? | a cosa si riferisce «sesta» |
|---|---|---|
| `CONGEDO_CC_2026-08-26_A220.md:439` (`bf211b6`) | **sì** | `grep` conta **righe**, non occorrenze |
| memoria privata di CC, sezione «(6)» | **no** | `2>/dev/null` su endpoint **rifiutato** |
| `LIBRO_MASTRO_QBEATS.md:323` | **sì** | l'operatore **`&&`** che tronca il controllo positivo |

⇒ **[M] Le prime due divergono fra loro, e la divergenza è nata lo stesso
giorno:** nella memoria privata il difetto del `grep` è la **(7) SETTIMA**, e la
**(6)** è il `2>/dev/null`. Ho scritto il congedo **prima** di aggiornare la
memoria, e quando ho aggiunto la sesta forma lì, il congedo portava già «sesta»
a significare un'altra cosa. **Nessuno dei due documenti sa dell'altro.**
⇒ **[A] Non c'è una numerazione da riparare: ce ne sono tre, e due sono
pubblicate. La decisione su quale sopravviva è del referee, non mia.**

**[M] (c) `LIBRO:323` incide una «SESTA FORMA DI FALSO-NEGATIVO» che è un bug
DIVERSO**, datata 2026-07-30. Verbatim dell'apertura:

> «**SESTA FORMA DI FALSO-NEGATIVO — l'operatore `&&` che TRONCA il controllo
> positivo.** Un comando della forma `grep <pattern> <path> && echo "controllo
> positivo" && grep -c <stringa-nota-presente>` **non stampa il controllo
> positivo proprio quando il grep rende zero** …»

⚠️ **[M] (d) Il fatto che il mandato non nomina, e che pesa sulla decisione:
quell'ordinale è già dichiarato ORFANO agli atti.** `HANDOFF/CONGEDO_CC_2026-08-06.md`,
punto 6, verbatim:

> «**La serie tassonomica «SESTA FORMA» non ha predecessori rintracciabili.** [V]
> `LIBRO:323` si intitola «SESTA FORMA DI FALSO-NEGATIVO», ma «prima|seconda|terza|
> quarta|quinta forma di» rende **ZERO** su LIBRO, BOX3, BOX5 e BUGS. L'ordinale non è
> ancorato a nulla. Registrato nella riga nuova di ieri, **non riparato**: ricostruire
> cinque forme mai scritte sarebbe inventare storia.»

**[M] (e) E nel LIBRO c'è una terza voce della stessa famiglia**, `:352`, del
2026-08-06: «**FALSO-*POSITIVO* DA FILTRO — POLARITÀ NUOVA, PRIMA DELLA SUA
SERIE.**» ⇒ **Nei canonici convivono due serie dichiarate — una «di
falso-negativo» con un solo membro numerato e orfano, una «di falso-positivo»
dichiarata prima della propria — e la numerazione 1-7 della memoria di CC non
appartiene a nessuna delle due.**

---

## 3-5 · BOX5 — tre regole nuove in coda al capitolo R-δ

**[M]** Sede scelta per continuità, non capitolo nuovo: `## R-δ — DOVE VANNO I
FILE` (riga 652), in coda dopo `R-δ.7`. **Innesto alla riga 806.**
✅ **[M] Misurato PRIMA di scrivere: l'inserimento non sposta alcuna citazione
nuda.** Tutte le citazioni `BOX5_QBEATS.md:NN` del corpus puntano a righe
**≤ 390**.

**[M] Verbatim, riletto dal disco dopo la scrittura:**

    ### R-δ.8 — UN ID È OCCUPATO QUANDO È ASSEGNATO A UN LAVORO (ratificata referee, approvata Mauro 26/08/2026)

    ⛔ **REGOLA:** un identificativo di mandato è **occupato** quando è **assegnato a
    un lavoro** — un referto, un congedo, un commit, una riga di canonico che lo
    attribuisce. **NON è occupato** quando compare **nominato come campione** dentro
    un documento che ne sta verificando la disponibilità.

    **Perché:** il cancello ID esiste per impedire che **due lavori diversi portino lo
    stesso numero**. Una citazione dentro una tabella di sonda non è un secondo
    lavoro: non ha artefatti, non ha commit, non ha attribuzione. Trattarla come
    occupazione brucia numeri senza proteggere nulla.

    ✅ **Precedente misurato, e distinzione operativa:** A213 e A214 erano occupati da
    **referti veri** — bruciati, correttamente. A218 compariva **una volta sola**,
    dentro la tabella di controllo del congedo del 25/08, senza alcun lavoro
    attaccato: **libero**, e infatti è stato usato.

    ⚠️ **La sonda non distingue da sola.** Rende un numero; è **chi legge** a stabilire
    se quell'occorrenza è un'assegnazione o una citazione. ⛔ **Un `1` non chiude il
    cancello: obbliga ad aprire il file e guardare cosa c'è su quella riga.**

    ### R-δ.9 — IL DOCUMENTO CHE NOMINA UN CAMPIONE LO CONSUMA (rilievo CC, ratificata referee 26/08/2026)

    ⛔ **REGOLA:** i numeri **candidati** non si scrivono per esteso nei documenti.
    **Si nomina solo quello assegnato.**

    **Perché, misurato:** il congedo del 25/08 dichiarò in tabella un ID «secondo
    campione» a `0 / 0 / 0`, e **con quella riga lo rese `1`**. La misura era vera
    nell'istante in cui fu presa e **falsa nell'istante in cui fu pubblicata**: il
    documento ha invalidato la propria misura nell'atto di scriverla.

    ⇒ **Come si scrive un cancello ID senza consumarlo:** si riporta la tabella del
    solo ID **preso**, più i **controlli positivi** — che sono ID **già occupati**,
    quindi nominarli non costa nulla. I candidati scartati si descrivono **per
    relazione** («quello immediatamente precedente»), mai per cifra.

    ⚠️ **Faccia generale della regola:** un documento che descrive il proprio stato
    **lo altera**. Vale per il conteggio dei non tracciati (un congedo si conta di
    meno finché non si deposita) e per le stringhe di un controllo d'integrità (la
    nota che spiega un conteggio entra nel conteggio). ⇒ **Le misure di un documento
    si dichiarano come scattate PRIMA del suo deposito, e l'auto-test si misura
    sull'ULTIMA stesura, mai sulla penultima.**

    ### R-δ.10 — LA GAMBA CONTENUTO DELLA SONDA ID ESCLUDE `DESIGN/` (misurata referee 26/08/2026)

    ⛔ **REGOLA:** la gamba **CONTENUTO** del cancello ID gira con `-- ':!DESIGN'`. La
    gamba **NOME** non ha bisogno dell'esclusione.

    **Perché, misurato:** la stringa `A219` compare **una sola volta** in tutto il
    repo, e non è un identificativo: è una **sottostringa dentro il base64 di un font
    woff2** in `DESIGN/QLive_Nav/2026-07-09_standalone_b23dfc78.html`. Una sonda
    ingenua dichiara quell'ID **occupato** e lo brucia.

    ⚠️ **È una polarità NUOVA rispetto a quanto già agli atti: un falso-UNO, non un
    falso-zero.** Le forme censite in casa producono un **vuoto** che sembra un fatto;
    questa produce un **riscontro** che sembra un fatto. ⛔ **Non rinumerare le serie
    esistenti su questa riga:** la classificazione tassonomica non è decisa qui.

    ✅ **Corollario operativo:** un ID che risulta pulito **solo grazie
    all'esclusione** è un ID che qualcun altro dichiarerà occupato. **Quando è
    possibile, si prende quello pulito in ENTRAMBE le letture.**

**[M] Testata:** `**Versione:** V33 — 26/08/2026`, aggiornata **dentro la riga**
come consente `R-δ.7`. **Delta V33 in coda**, mai in testa.
**[M] Faccia preservata:** LF, **CR = 0** prima e dopo. 923 → **959** righe.

---

## 6 · README dei disegni — due marcature additive, zero righe riscritte

**[M] Il difetto era reale e l'ho misurato alla fonte prima di toccarlo:** il
file conteneva **tre** occorrenze di **U+202F** (*narrow no-break space*) e
**zero** di U+00A0. I due pesi del 25/08 usavano U+202F; il peso della rev6
(`87 570`) usa lo **spazio normale**.

⚠️ **[M] SCOSTAMENTO DAL PERIMETRO, DICHIARATO: il mandato ne nominava DUE, io
ne ho corrette TRE.** La terza è `27 145` nella riga della nota di correzione,
scritta lo stesso giorno con lo stesso difetto. **[A] Correggerne due su tre
avrebbe lasciato in piedi il medesimo difetto nella riga adiacente, e la
marcatura avrebbe dovuto dichiararlo.** Residuo dopo l'intervento: **zero**.

⚠️ **[M] Restano DUE occorrenze della stessa forma in `LIBRO_MASTRO_QBEATS.md`**
(riga della decisione 25/08 e registro versioni). **Fuori perimetro: dichiarate,
non toccate.** BOX5, BUGS e il congedo A220 rendono **zero**.

**[M] Prima marcatura, verbatim dal disco:**

> ⚠️ **MARCATURA 26/08 — DIFETTO DI FORMA NELLE TRE RIGHE DEPOSITATE IL 25/08,
> CORRETTO. Le righe non sono riscritte: si marca qui cosa è cambiato e perché.**
> I pesi delle righe nuove erano scritti col separatore **U+202F** (*narrow
> no-break space*) fra le migliaia — `106<U+202F>024`, `97<U+202F>267`,
> `27<U+202F>145` — mentre la stessa tabella usa lo **spazio normale** per il peso
> della rev6 (`87 570`). ⛔ **Il difetto ne minava la funzione:** quelle righe
> esistono per **distinguere due file omonimi per peso**, e chi cercava `106 024`
> scritto con lo spazio normale **non lo trovava**. Misurato: tre occorrenze in due
> righe, zero altrove in questo file. ✅ **Tutte e tre portate a spazio normale**,
> coerenti col resto della tabella. ⚠️ **Due occorrenze della stessa forma restano
> in `LIBRO_MASTRO_QBEATS.md`** (riga della decisione 25/08 e registro versioni):
> **fuori dal perimetro di questo giro, dichiarate e non toccate.**

🚨 **[M] SECONDA MARCATURA, NON PREVISTA DAL MANDATO — il punto 8 ha smentito
una riga scritta al punto 6.** Depositando la nota, la riga d'indice che
dichiarava «**NON È IN QUESTA CARTELLA … vive solo su Drive**» è diventata
**falsa nello stesso commit che la conteneva**. Verbatim dal disco:

> ⚠️ **MARCATURA 26/08 — LA RIGA DELLA NOTA DI CORREZIONE AL 18/07 È SUPERATA DAL
> DEPOSITO DI OGGI. La riga non si riscrive: si marca qui.** Quella riga dichiara
> «**NON È IN QUESTA CARTELLA … vive solo su Drive** — zero copie in
> `DESIGN/QLive_Nav/`, zero su `E:`», e al momento in cui fu scritta era **vera e
> misurata**. ✅ **Oggi non lo è più:** il file è stato depositato in **questa
> cartella** e su **`E:` in `DA_CD_PER_CC/24_08_2026/`** — 27 145 byte, `cmp` fra le
> due scritture a exit 0, sha256 `b926aaf6…93e8`, identico al sorgente. ⇒ **Della
> riga sopra resta valido tutto tranne la clausola di assenza:** la nota **si legge
> accanto al contratto 18/07** e **chi legge il 18/07 deve leggere anche questa**.
> ⚠️ **Il deposito era materia di un mandato suo, ed è arrivato:** questa marcatura
> lo registra invece di lasciare in piedi una frase che il giro successivo ha
> smentito.

⇒ **[A] Nota di metodo per chi scrive mandati:** due punti dello stesso mandato
possono contraddirsi se uno descrive uno stato e l'altro lo cambia. **Il punto
che cambia lo stato va eseguito PRIMA di quello che lo descrive**, oppure il
descrittore va scritto sapendo che sarà superato.

**[M] Faccia preservata:** LF, **CR = 0**. 98 → **101** righe.

---

## 7 · BUGS — ticket nuovo, e il commento che mente

**[M]** Sede: coda della sezione `## 📦 1.3 — Backlog (🟡 OPEN BASSA)`, innesto
alla riga 861. **Titolo verbatim dal disco:**

    ### TD-kickscheduling-morto-e-doccomment-falso — `AudioEngine.swift:1211` non ha
    chiamanti, e il suo doc-comment PRESCRIVE un chiamante che rifiuta di chiamarlo
    (🟡 OPEN BASSA — **PROPOSTA, non assegnata: decide Mauro**)

**[M] I due cardini del ticket, verbatim:**

> - ⛔ **IL PUNTO NON È IL CODICE MORTO — È CHE IL COMMENTO MENTE SUL PROPRIO
>   RICHIAMO, e chi lo legge lo crede vivo.** Il doc-comment a
>   `AudioEngine.swift:1208` prescrive verbatim: «Chiamare SOLO dal ramo avanza di
>   SetlistRunner, dopo scheduleBPMChange.» Il ramo avanza di
>   `SetlistRunner.swift:333-335` dichiara verbatim l'opposto: «**NESSUNA chiamata a
>   setBeatsPerBar/setAccentPattern/loadSection/scheduleBPMChange/kickScheduling —
>   tutto gestito dallo swap nel beat callback.**» ⇒ **Il presunto unico chiamante è
>   anche l'unico che dichiara di non chiamarlo. Il codice dà ragione al secondo.**
>
> - ⇄ **RIMANDO INCROCIATO con `TD-doccomment-navigate-zero-chiamanti`: i due si
>   citano e NON si fondono, e l'argomento è tecnico.** Quel ticket registra un
>   commento che dichiara **zero chiamanti** dove ne esiste **uno** — falso **per
>   difetto**, e si ripara cancellando una frase. Questo registra un commento che
>   **prescrive** un chiamante dove non ne esiste **nessuno** — falso **per
>   eccesso**, e non si ripara cancellando: chi lo tocca deve **decidere se il
>   metodo va chiamato o rimosso**. ⛔ **Polarità opposta, rimedio diverso,
>   decisione diversa.**

✅ **[M] Il ticket riusa la classe esistente invece di aprirne una nuova:** in
BUGS esisteva già `TD-doccomment-navigate-zero-chiamanti`, della stessa
famiglia. L'argomento per non fonderli è tecnico, non di comodo, e ricalca il
precedente `TD-canonici-puntatori-path-stale`, che affronta lo stesso dilemma.

**[M] Controllo positivo su due gambe**, perché uno zero su una sonda di
chiamanti è sospetto: `scheduleBPMChange` rende callsite reali
(`MetronomeDSPBridge.mm:112`, `MetronomeDSP.cpp:61`, i test); `scheduleNextBuffer`
rende **25** occorrenze nello stesso `AudioEngine.swift`. ⇒ **lo zero non è un
falso-zero.**

🚨 **[M] UN MIO ERRORE, TROVATO E CORRETTO PRIMA DEL COMMIT.** La prima stesura
della riga sulle conseguenze diceva «**+10 righe**»: **numero scritto a occhio,
non misurato.** Sono **11**. Controprova per contenuto: `## 1.4` stava a `:861`
e sta ora a `:872`. La riga corretta ora dice: slittamento **+11** per NN fra
861 e 1296, **+12** da 1297 (la riga del registro versioni ne aggiunge una in
fondo); **4 indirizzi tracciati in git** (`:1013` · `:1058` · `:1060` · `:1062`,
6 occorrenze, tutte a +11) e **14 su disco** (~39 occorrenze, `:1361` la sola a
+12). ⚠️ **L'errore è dichiarato dentro il ticket stesso, non solo qui.**

**[M] Faccia preservata:** CRLF, **1300 CR / 1300 LF → 1312 / 1312**.
**[M] Testata:** `**Versione:** 63` · `**Ultima modifica:** 2026-08-26` ·
riga nuova nel registro versioni.

---

## 8 · Deposito della nota di correzione — ESEGUITO, ma per un pelo

**[M] Il file è depositato.** 27 145 byte, sha256
`b926aaf6e88294a1a6e500e00ccd1b6f6b191e77ce04757d16239f0489e993e8`.

| dove | byte | esito |
|---|---|---|
| sorgente su Drive | 27 145 | — |
| `C:` `DESIGN/QLive_Nav/` | **27 145** | `cmp` vs sorgente **exit 0** |
| `E:` `DA_CD_PER_CC/24_08_2026/` | **27 145** | `cmp` C: vs E: **exit 0** |

Cartella `24_08_2026/` creata (non esisteva). Su Drive non ho scritto.

🚨 **[M] LA PRIMA SONDA HA DETTO «NON RAGGIUNGIBILE», ED ERA VERO MA NON PER LA
RAGIONE CHE SEMBRAVA.** Stamattina Drive era montato su `L:`; alle 11:36 **non
esiste più una unità `L:`**. Se avessi accettato quel primo esito avrei fermato
il punto 8 dichiarando un file irraggiungibile che invece c'era.

✅ **[M] Cosa l'ha smascherato:** il controllo positivo. Ho cercato i file che
**sapevo** di aver letto stamattina nella stessa cartella: zero anche loro ⇒ non
mancava il file, **mancava il supporto**. Enumerando le unità: `GoogleDriveFS` è
**in esecuzione**, e Drive è ora su **`I:`**. Il file era lì, col peso atteso.

⇒ **[A] Rilievo per i canonici, che NON incido perché fuori perimetro: la
lettera di Drive non è stabile.** È cambiata in tre ore, senza avviso, mentre il
processo restava vivo. Un percorso Drive inciso in un documento **è un indirizzo
che scade**, e questo rafforza la riga `2026-08-21` del LIBRO che già toglie
Drive dal regime R-δ. ⛔ **La cura non è annotare la lettera giusta: è non
scriverla mai, e cercare per contenuto.**

---

## 9 · Consegna e verifica

**[M] UN commit solo per i punti 3-8**, come prescritto:
**`c89832b9790d9cb4c8d256f8fee814ce44cf8043`** · autore
`Mauro Martintoni <di_tutto@icloud.com>` · nessun `Co-Authored-By` · staged
**file per file** · `4 files changed, 263 insertions(+), 5 deletions(-)`.

| file | byte | sha256 |
|---|---|---|
| `BOX5_QBEATS.md` | 84 243 | `cf1f04d5…cf7d` |
| `BUGS_QBEATS.md` | 382 607 | `7adef796…5c85` |
| `DESIGN/QLive_Nav/README.md` | 12 477 | `ef9bae75…baa0` |
| `…ritiro-chip-N-on-Link.html` | 27 145 | `b926aaf6…93e8` |

**[M] Gambe `E:` allineate, tutte con `cmp` exit 0:**
BUGS file vivo → v63 · snapshot `BUGS_QBEATS_v63_2026-08-26_c89832b.md` ·
snapshot `BOX5_V33_2026-08-26_c89832b.md` in `BOX5_Test/`.

⚠️ **[M] RETTIFICA A UNA FRASE CHE HO GIÀ SCRITTO NEL MESSAGGIO DI COMMIT, e che
non posso correggere lì.** Il messaggio dice che `BUGS_QBEATS/` e `LIBRO_MASTRO/`
«portano il file vivo col nome nudo» mentre `BOX5_Test/` e `BOX3_Codice/`
portano gli snapshot — **vero ma incompleto**, e l'incompletezza nasce dall'aver
letto **le prime sei righe** di `ls` invece di contarle tutte. Il quadro
rimisurato:

| cartella su `E:` | file vivo | snapshot datati |
|---|---|---|
| `BOX5_Test/` | **0** | 5 |
| `BOX3_Codice/` | **0** | 59 |
| `BUGS_QBEATS/` | **1** | 14 |
| `LIBRO_MASTRO/` | **1** | 24 |

⇒ **BUGS e LIBRO hanno ENTRAMBI**, vivo **e** snapshot. **BOX5 e BOX3 hanno solo
snapshot.** La frase del commit suggerisce un'esclusività che non c'è.

⚠️ **[M] Debito misurato e NON riparato, perché di un altro giro:** manca lo
snapshot `LIBRO … v64` su `E:` — l'ultimo è `v63_2026-08-24_8727f8e`. La v64
nasce dai mandati A218/A221 di stamattina. **Un `cp`, ma non è il perimetro di
questo mandato: lo dichiaro e lo lascio al referee.**

✅ **[M] MARCATURA A223 — CHIUSO. La riga sopra resta come scritta: era vera, si
marca e non si riscrive.** Il referee l'ha assegnato nel giro successivo e il
deposito è fatto: `LIBRO_MASTRO/LIBRO_MASTRO_QBEATS_v64_2026-08-26_619be20.md`
su `E:` — 300 590 byte, CRLF 536/536, sha256 `64e88ea7…d393`, `cmp`
contro l'originale su `C:` **exit 0**. **Lo sha7 del nome è `619be20`**, il
commit che ha fissato la v64 nella forma attuale; convenzione verificata sul
precedente (`…v63_2026-08-24_8727f8e` ⇄ commit `8727f8e`, che rende
`**Versione:** 63`). ⚠️ **Il `cmp` è stato controllato non cieco:** rende **1**
contro lo snapshot v63 e **0** contro il file vivo su `E:`, che è la stessa v64.
⚠️ **[M] Precedente da conoscere:** la catena porta **due** snapshot per la v62
(`203d331` e `8ee5485`), perché quella versione passò per due commit. Anche la
v64 è passata per due (`8f415bb` la crea con le quattro date sbagliate,
`619be20` le corregge): **ne ho depositato uno solo, quello finale.** Se il
regime vuole entrambi, manca `…v64_2026-08-26_8f415bb`.

⛔ **[M] NON HO PUBBLICATO.** HEAD locale `c89832b…`, remoto ancora `bf211b6…`.
⚠️ **[A] E qui c'è una tensione che segnalo invece di risolvere da solo:** il
mandato apre dicendo che misura «due cose che il referee non può vedere dal
tarball pubblico», ma **non chiede il push** — e senza push il referee non vedrà
nemmeno questo commit. **Il push è un'azione verso l'esterno su un repo
pubblico: non estendo a questo giro un'autorizzazione data ieri per un altro.**
Basta una parola.

✅ **[M] MARCATURA A223 — PUBBLICATO. Le righe sopra restano come scritte: erano
vere quando furono scritte, si marcano e non si riscrivono.** Mauro ha
autorizzato esplicitamente la pubblicazione di questo giro e il referee l'ha
mandata: push del 26/08, `bf211b6..c89832b`, senza `--force`.
**[M] Verificato a DUE sonde di natura diversa, entrambe concordi:**

| sonda | natura | esito |
|---|---|---|
| `git ls-remote origin master` | protocollo git, ref del remoto | `c89832b…8043` = HEAD locale |
| `gh api repos/…/commits/c89832b…` | REST/JSON su HTTP | stesso sha, autore `Mauro Martintoni`, `2026-08-26T09:48:15Z`, **4 file** |

**[M] Terza forma, ridondante:** `commits?sha=master` rende `c89832b` in testa
con `bf211b6` come genitore ⇒ **raggiungibile da `master`, non un oggetto
orfano.** ⚠️ **[A] Le due sonde erano richieste proprio perché una sola non
basta:** `ls-remote` legge un ref e l'API legge l'oggetto — se il ref fosse
avanzato senza che i blob arrivassero, la seconda se ne accorgerebbe.

---

## 10 · Cosa lascio al referee, in ordine di urgenza

1. **[A] La decisione tassonomica di §2 — RISCRITTA dopo la rettifica A223, ed è
   più grande di come l'avevo posta.** Non è vero, come avevo scritto, che
   l'ordinale non sia mai entrato in un canonico: **ci sono TRE «sesta» diverse,
   e DUE sono in git** — `CONGEDO_…_A220.md:439` (il `grep` righe-vs-occorrenze)
   e `LIBRO:323` (l'`&&` che tronca), più una terza nella memoria privata di CC
   che chiama «sesta» il `2>/dev/null` e «settima» quella del congedo. ⚠️ E
   l'ordinale del LIBRO è per giunta **già dichiarato orfano agli atti** dal
   congedo del 06/08. ⇒ **Non c'è una serie da aprire: ce ne sono tre da
   riconciliare, e due sono pubblicate.** La decisione è del referee.
2. ✅ **[M] `c89832b` è PUBBLICATO** — push del 26/08, verificato a due sonde
   indipendenti (`ls-remote` e API REST di GitHub).
3. ✅ **[M] Lo snapshot `LIBRO v64` su `E:` — DEPOSITATO** nel giro A223,
   `…v64_2026-08-26_619be20.md`, `cmp` exit 0 e non cieco. ⚠️ Resta la domanda
   se il regime voglia **due** snapshot per la v64 (uno per `8f415bb`, uno per
   `619be20`), come già accadde per la v62.
4. **[M] Le due occorrenze di U+202F residue nel LIBRO**, fuori dal perimetro
   di oggi.
5. **[A] La lettera di Drive che cambia** (§8): se merita una riga in un
   canonico, non l'ho scritta.
6. **[M] Questo referto NON è committato**, come i referti di ieri: si somma ai
   **281** non tracciati di `HANDOFF/`.

---

*A222-REFERTO-CC-2026-08-26-GIRO-DOCUMENTI-FINE*
