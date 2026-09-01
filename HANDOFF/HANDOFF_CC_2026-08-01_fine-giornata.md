# HANDOFF CC — fine giornata, 2026-08-01

**Chi scrive:** CC. **Prompt:** `QB-2026-08-01-Z4-HANDOFF-CC-FINE-GIORNATA`.
**Che cos'è:** un **deposito**, non una ratifica. È il mio handoff sul mio lavoro; quello
del referee è un file a parte. Niente qui è ratificato dal fatto di starci scritto.

**Marcatura, riga per riga:** `[V]` misurato adesso al disco o al blob · `[R]` so che è
vero ma non l'ho potuto misurare · **NON RICORDO** scritto così, non aggiustato.
⛔ **Nessun path, commit, sha o numero di riga a memoria.**

⚠️ **TRAPPOLA DI ORDINAMENTO, dichiarata perché non se ne crei una nuova.** La data vera è
**2026-08-01**. Il file `HANDOFF/HANDOFF_CC_2026-08-02_saturazione.md` porta `08-02` per un
errore del referee e **NON va rinominato**: quel file **PRECEDE** questo, benché il nome lo
faccia ordinare dopo. Questo documento porta la data vera. È la stessa famiglia della
coppia ROADMAP trovata stamattina — due nomi che dichiarano stati incoerenti.

⛔ **INDIRIZZO, NON COPIA**, e qui vale tre volte:
- **catalogo delle trappole di strumento** → §4 di `HANDOFF/HANDOFF_CC_2026-08-02_saturazione.md`
  `[V]` 20675 B, sha256 `792860286d0d41294d3a4e9cebf94b7550588b444609813c3a30a2344ef3bab4`
  (rimisurato adesso: **MATCH**). Il §5 dello stesso file porta le decisioni di Mauro.
- **congedo del referee** → `HANDOFF/CONGEDO_REFEREE_2026-08-01.md` (deposito `Z3`). È suo,
  non mio: non lo riscrivo e non lo riassumo.
- **referti di oggi** → §3 qui sotto, per path e impronta.

---

## §1 — STATO REPO ADESSO `[V]`

```
HEAD                     7ec6c1b86a7acb869c1f927fa4833374ffabb0cc
branch                   master
origin/master            7ec6c1b86a7acb869c1f927fa4833374ffabb0cc
```

L'allineamento è verificato **interrogando il remoto**, non l'output di un comando locale:
`git ls-remote origin master` → `7ec6c1b86a7acb869c1f927fa4833374ffabb0cc refs/heads/master`.
E il contenuto, non solo il commit: `origin/master:LIBRO_MASTRO_QBEATS.md` →
`82d17fcaef8947efc239985cb50e813f98a2c838`, lo stesso OID del commit e dello snapshot su E:.

```
staging                  VUOTO (0 file)
tracciati modificati     0
stash                    0
porcelain totale         109   -> untracked 109, tracciati 0
untracked in HANDOFF/    105
file totali in HANDOFF/  109   di cui tracciati 4
worktree                 C:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS  7ec6c1b [master]
                         C:/Users/BULLFROG/qb_fixB                      add556f [test/bug2b-test7-fixtures]
```

⚠️ **I conteggi sono presi PRIMA che questo file e il deposito `Z3` esistessero**, quindi
**escludono entrambi per costruzione**: con i due file diventano **111** e **107**. È la
lezione del §4.5 di `Z1` — chi conta una cartella scrivendoci dentro sbaglia.
Due forme indipendenti concordi sui 105: `git status --porcelain | grep '^?? HANDOFF/'` e
`find HANDOFF -type f` meno `git ls-files HANDOFF`.

⚠️ **Il secondo worktree esiste e non è stato toccato oggi.** Chi fa sweep sul «repo»
fermandosi alla cartella principale misura meno di quello che c'è.

---

## §2 — VERIFICA AUTOMATICA DI GITHUB

`[V]` Run **`30719488436`** — `iOS Signed Build`, innescata dal push di v50:

```
status      completed
conclusion  success
durata      2m13s
chiusa      2026-08-01T21:38:31Z
```

Misurata con lo **sha a 40** (`gh run list --commit 7ec6c1b86a7acb869c1f927fa4833374ffabb0cc`),
mai col corto. **Controllo positivo nella stessa forma:** il commit precedente `0ee9543…`,
anch'esso doc-only, rende una run `success` in 2m15s — quindi la forma della ricerca è
provata e uno zero sarebbe stato uno zero vero.

`[V]` Il workflow si innesca su **ogni** push a `master` (`.github/workflows/ios_build.yml`,
`on: push: branches: ["master"]`), doc-only compresi: un commit senza codice **non** salta
la CI.

⇒ **v50: committato, pubblicato, CI verde.** Ma «verde» qui significa *build firmata
riuscita*, non *comportamento provato*: per un commit doc-only con zero righe di codice non
poteva dire altro. **«push ≠ chiuso» resta in piedi** per tutto ciò che tocca il prodotto.

---

## §3 — COSA HO CONSEGNATO OGGI — indirizzi e impronte, non contenuto

Tutti in `HANDOFF/`, tutti **untracked**. **sha256 rimisurato adesso dal file**, non
riportato dal messaggio in cui l'avevo scritto. `cmp` contro E: **exit 0 su tutti**.

| # | file | byte | sha256 | stato |
|---|---|---|---|---|
| 1 | `MISURE_CC_2026-08-01_D1-GEOMETRIA-RDELTA.txt` | 15064 | `ed233a1f6daa50477d760334e9c726afd54b38ca9292074c1fbaa49ad4ac482b` | ⚠️ **SUPERATO da D1b** — marcato in testa, non riscritto |
| 2 | `MISURE_CC_2026-08-01_D1b-CORREZIONI.txt` | 11366 | `896b1266c8eb9f6a7d6df0e814e000d9f91c5a9eeecdd43681c4314d0013218e` | vivo |
| 3 | `DIFF_LIBRO-v50_2026-08-01.txt` (rev1) | 21316 | `4c994e95ecd035dcf5dd60b845d702d8f963da56d7e12d7a65ec547fabffaa13` | ⚠️ **SUPERATO da rev3** |
| 4 | `DIFF_LIBRO-v50_2026-08-01_rev2.txt` | 31022 | `2537412cc1ccf363f4645576cf454dcbb9345bb7132d787f98f2af10bf7b36fa` | ⚠️ **SUPERATO da rev3** — è però **quello ratificato dal referee** |
| 5 | `DIFF_LIBRO-v50_2026-08-01_rev3.txt` | 31022 | `33892dba9d93719376404520dc3558ab1355a0303170dedb125900e11305374a` | **vivo — è ciò che è entrato nel commit** |
| 6 | `ESITO_COMMIT_LIBRO-v50_2026-08-01.txt` | 6419 | `a72d70c82e984d66b5a00bdfd3876e0604dd8dec66bfe1227e1843e8091ee011` | vivo |

Fuori da `HANDOFF/`, snapshot per-versione:
`E:\…\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_V50_2026-08-01_7ec6c1b.md`
`[V]` 235589 B, sha256 `142c0c8b31241c430638f43106ddbceafd95b885c89b07ef9a77038af1f213b3`,
estratto **dal blob** con `git show`. Controprova di **identità di oggetto**:
`git hash-object` sullo snapshot rende `82d17fca…`, lo stesso OID del commit.

⚠️ **Il referto R1b di stamattina non ha un file:** il prompt chiedeva risposta in linea.
Le sue misure (OID di BOX3, riga 314 verbatim, assenza di X1/X2) sopravvivono solo nella
chat e nei giri successivi che le citano. **NON RICORDO** se sia stato deciso di depositarlo.

### Presenza sulle tre destinazioni `[V]`

**C:** tutti presenti. **E:** tutti presenti, `cmp` exit 0. **Drive:** verificato uno per
uno interrogando il connettore, **non dato per fatto** — è il primo giorno di
sincronizzazione e un fallimento silenzioso vale più di un successo presunto:

```
ESITO_COMMIT_LIBRO-v50_2026-08-01.txt         6419 B   x2 alberi   = locale
DIFF_LIBRO-v50_2026-08-01_rev3.txt           31022 B   x2 alberi   = locale
DIFF_LIBRO-v50_2026-08-01_rev2.txt           31022 B   x2 alberi   = locale
DIFF_LIBRO-v50_2026-08-01.txt (rev1)         21316 B   x2 alberi   = locale
LIBRO_MASTRO_QBEATS_V50_2026-08-01_7ec6c1b.md 235589 B  x1         = locale
```

⇒ **La sincronizzazione funziona e consegna i byte giusti senza che io trasporti nulla.**
⚠️ **Ma la verifica è per DIMENSIONE, non per impronta**: il connettore non espone i
checksum che l'API v3 dichiara, e verificare davvero richiederebbe il riscaricamento. È
esattamente il limite **L1** che v50 ha appena inciso, e va detto invece che taciuto.
⚠️ Sopravvive su Drive **una copia difettosa** del rev1 (21304 B) caricata a mano da me:
non cancellata, dichiarata.

---

## §4 — LAVORO NON FINITO E DEBITI, in ordine di urgenza

**a) 🔴 Puntatori `LIBRO:467` in BUGS — il debito più urgente.** `[V]` rimisurato al blob
di HEAD: **9 occorrenze su 4 righe** (r.360, r.361, r.1023, r.1024); la somma per riga fa 9
e **chiude**. Sonde positive stessa forma: `LIBRO:285` → 3, `LIBRO:317` → 5. Il bersaglio —
la **voce 43 del registro** — sta oggi a **`LIBRO:484`**. **Deriva vera: 17 righe.**
⇒ **Va riparato PRIMA di D2. Il motivo è che il debito matura interesse:** ogni versione
del LIBRO sposta il bersaglio senza rendere la riparazione più facile, e v50 da sola l'ha
allontanato di sette righe. D2 tocca la SCALETTA e ne aggiungerà altre. Ripararlo dopo
significa ripararlo su un bersaglio più lontano, per nessun guadagno.
⚠️ **Trappola da non ripetere:** la citazione è nella forma **corta** `LIBRO:467`; cercarla
col nome pieno rende **zero**. Falso zero già preso oggi e smentito dalla sonda.

**b) 🟠 Giro D2 sulla SCALETTA — non aperto.** `[V]` `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`,
OID `d4306337ffccc0beec3fba595da61f67f1076fb4`, 36070 B. Tre materie: la **sez. C riga 314**
porta ancora l'ordine `S4 → S4K → S4R → S4L → S5 → S6`, che `LIBRO:329` ha **emendato il
31/07 e mai fatto atterrare**; le schede **⟦S-EXIT⟧** e **⟦S6F⟧** rendono **zero**
occorrenze; più il riancoraggio della sez. F.

**c) ✅ `LIBRO-sez6-buco-v25-v26` — NON è un debito: è già chiuso.** `[V]` misurato al blob
di HEAD: `BUGS_QBEATS.md:524` lo dichiara **🟢 CHIUSO 01/08/2026** e `:529` porta la
motivazione («IL TICKET NON HA OGGETTO: le voci 25 e 26 non sono MAI STATE SCRITTE»),
verbalizzato nel registro di BUGS alla voce v47. ⇒ **Non rimetterlo in coda.** Era dato per
aperto sul presupposto che la chiusura vivesse solo in un handoff mai esistito.

**d) 🔵 Alberi paralleli su Drive — dichiarato, non chiuso.** `[V]` almeno **tre** cartelle
`HANDOFF` distinte (due dalla sincronizzazione alle 15:47, una creata da CC alle 13:25).
⚠️ **Il censimento NON è chiuso**: l'interrogazione è paginata e non l'ho esaurita. Non
stimo un totale. ⛔ **Non ripulire:** per **L3** la cancellazione su un albero sincronizzato
si propaga. È decisione di Mauro.

**e) Altro iniziato e non finito:**
- `[V]` **Il `.mobileprovision` su Drive è passato da UNA a DUE copie**: la sincronizzazione
  ha propagato anche il file dichiarato «vietato, né ora né mai». La decisione su di esso è
  **ancora aperta** e nel frattempo il file si è duplicato. ✅ Nessun `.p12`/`.key`/`.pem`
  su Drive: la chiave privata **non** è esposta.
- `[V]` **Voci 25 e 26 assenti dal registro Sez.6 del LIBRO**: 48 voci per versioni 1…24 e
  27…50. Stato preesistente, dichiarato in D1b, **non riparato** — le righe storiche non si
  riscrivono, e il ticket relativo è chiuso per accertamento (vedi (c)).
- `[V]` **`tools/lint_canonici.py`** esiste (12076 B) ed è **untracked**: uno strumento che
  nessuno vede. Deciso: no. Aperto: sì.

---

## §5 — COSE CHE SO E NON STANNO IN NESSUN FILE — **solo il delta** da `Z1` §4

Il catalogo delle trappole di strumento è indirizzato in testa e **non si duplica**. Qui
solo ciò che questa giornata ha aggiunto.

- `[V]` **Un rilevatore non è valido finché non lo si prova su un positivo certo — e il
  positivo giusto è il reperto CHE HA MOTIVATO la ricerca.** Il rilevatore di credenziali
  non agganciava proprio il file che aveva motivato la sua stessa classe: il primo «zero»
  era privo di valore, e l'ha smentito il controllo positivo, non la rilettura.
- `[V]` **Quarta forma di falso-zero: cercare su UN SOLO supporto.** Si aggiunge alle tre
  già catalogate. Corollario preso oggi: **anche la FORMA del nome è un supporto.**
  `LIBRO:467` cercato come `LIBRO_MASTRO_QBEATS.md:467` rende **zero** su una cosa che
  esiste **nove** volte. Uno zero senza sonda positiva nella stessa forma non è un risultato.
- `[V]` **Un'àncora automatica ha abortito su un MIO errore di conteggio, non su un difetto
  del file** — avevo previsto 3 occorrenze di un carattere e ne erano 4, perché la mia
  stessa riga ne incollava due. **Rimedio strutturale, non «più attenzione»: in una riga che
  RIPORTA UNA MISURA SUI BYTE il codepoint si NOMINA (`U+1F7E2`), non si incolla.** Così il
  documento non aggiunge superficie al problema che sta descrivendo.
- `[V]` **Il trasporto attraverso il modello riscrive i byte.** Ricopiando un file nel
  parametro testuale del connettore Drive, **sei apostrofi tipografici U+2019 sono diventati
  ASCII**: −12 byte, confermati dal `fileSize` del server e dal confronto byte a byte dopo
  riscaricamento. Il canale Drive era già provato byte-fedele: **l'alterazione è nella
  trascrizione, non nel trasporto.** ⇒ «La copia è una riscrittura» ha ora una misura.
- `[V]` **E quel trasporto era anche INUTILE:** la sincronizzazione aveva già consegnato i
  byte esatti **tre minuti prima** del mio upload manuale. Il difetto non era solo evitabile:
  era superfluo.
- `[V]` **Limiti del connettore Drive emersi alla prova, non dalla documentazione:** una
  sincronizzazione su cartelle omonime da radici diverse **genera alberi paralleli**, e da
  quel momento «il file è su Drive» **non individua più un oggetto** — del diff v50 esistono
  tre copie omonime, due buone e una difettosa. E l'interrogazione per titolo è **paginata**:
  una risposta senza `nextPageToken` esaurito non autorizza a scrivere un totale.
- `[R]` **Il connettore del referee rende il testo con escape markdown:** per una ratifica
  verbatim serve il download binario, non la lettura.

---

## §6 — DECISIONI CHE ASPETTANO MAURO

Per indirizzo: l'elenco completo è al **§5** di `HANDOFF/HANDOFF_CC_2026-08-02_saturazione.md`.
Qui solo lo **stato verificato oggi**, perché alcune erano date per chiuse e non lo sono.

1. **`.mobileprovision` su Drive** — **APERTA**, e peggiorata: `[V]` da **una** a **due**
   copie, propagate dalla sincronizzazione.
2. **I due `.txt` in `CERTIFICATI/`** (`p12_base64.txt`, `provision_base64.txt`) — **APERTA**.
   `[V]` I quattro file di credenziale stanno ancora in
   `E:\…\Q-BEATS\CERTIFICATI\QBeats-Certs\`, **con gli stessi nomi**: nulla è stato
   rinominato né spostato. ⚠️ **Il prompt la dava per chiusa («cartella CERTIFICATI spostata
   fuori dal perimetro sincronizzato»): la misura non lo conferma.** `CERTIFICATI` è un ramo
   **parallelo** a `FILE X CLAUDE.MD` — cioè fuori dal perimetro — ma **lo era già** prima
   della sincronizzazione, come il referto S1 aveva descritto. La posizione è invariata: non
   è stata chiusa una decisione, è stato constatato uno stato preesistente. ✅ Il fatto
   positivo, quello sì misurato: **zero credenziali su Drive**.
3. **`.gitattributes`** — **APERTA**: copre `HANDOFF/**`, `DESIGN/**`, BOX3, BOX5, e **non**
   LIBRO e BUGS, che restano a due facce.
4. **BOX3 V100** — **APERTA**, dichiarata «prossimo giro» il 01/08 e non aperta.
5. **Perimetro iOS 16.0 contro iPhone 11** `[R]` — **APERTA**, sollevata e mai decisa.
6. **Condividere la cartella Drive col referee, e in sola lettura** — **APERTA**.
   ⚠️ Ora ha una domanda in più: **quale** dei tre alberi si condivide.
7. **I file ancora da caricare su Drive** — **SUPERATA nei fatti**: la sincronizzazione ha
   sostituito il trasporto manuale. Resta da decidere il **perimetro**, non la via.
8. **File fuori da ogni regola del MANIFESTO** — **APERTA**.
9. **`tools/lint_canonici.py`: tracciarlo o no** — **APERTA**.
10. **La coppia ROADMAP a byte identici sotto due nomi in contraddizione** — **APERTA**.
11. **NUOVA:** gli **alberi paralleli su Drive** e la copia difettosa del rev1 — cosa
    tenere, cosa no. ⛔ Ricordare che la cancellazione si propaga.

---

## §7 — DA DOVE SI RIPARTE

`[V]` **Il prossimo atomo è ⟦S5⟧**, e l'indirizzo che lo dichiara è
**`LIBRO_MASTRO_QBEATS.md:329`** — misurato adesso al blob di HEAD, non ereditato.

⚠️ **Precisazione che vale un giro di lavoro risparmiato.** L'avvertimento «v50 ha inserito
sette righe, TUTTI i numeri di riga successivi sono cambiati» è **vero solo da `:336` in
giù**: le sette righe sono entrate **dopo** la 335, quindi tutto ciò che sta a `:335` o
prima è **invariato**. Rimisurati al blob di HEAD:

```
LIBRO:327   ⟦S-EXIT⟧ — atomo nuovo              (invariata)
LIBRO:329   ORDINE DEGLI ATOMI §6 EMENDATO      (invariata)  <- l'ordine di lavoro
LIBRO:330   ⟦S4R⟧ CHIUSO, non chiuso device     (invariata)
LIBRO:334   ⟦S6F⟧ — atomo nuovo                 (invariata)
LIBRO:335   estensione «per SIMBOLO»            (invariata)
LIBRO:336-342   le sette righe di v50                       <- nuove
LIBRO:491   voce 50 del registro                            <- nuova
righe totali del blob: 495
```

⇒ Ciò che è slittato è il **registro** e tutto ciò che segue Sez.2: la voce 43 è a `:484`.

**Ordine di lavoro:** riparazione puntatori BUGS → **D2** (SCALETTA) → **⟦S5⟧**.
⛔ Vincolo ratificato da non violare, a `LIBRO:329`: **nessuna sessione multi-device e
nessuna data con la band su una build che contenga ⟦S5⟧ finché ⟦S-EXIT⟧ non è chiuso device.**
⚠️ **⟦S4L⟧ resta SOSPESO** su tre pendenze; non va costruito.

### File da caricare nel Progetto del referee nuovo, perché apra con R1 senza essere cieco

Impronte **al blob di HEAD `7ec6c1b`**, faccia LF. `[V]` tutte misurate adesso.

| file | OID (blob) | byte |
|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | `82d17fcaef8947efc239985cb50e813f98a2c838` | 235589 |
| `BUGS_QBEATS.md` | `c896f919b1ba93437eff56eee3ab592136203337` | 272339 |
| `BOX3_QBEATS.md` | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` | 89457 |
| `BOX5_QBEATS.md` | `21b23d621ac224c759b53d813196058483e3b056` | 57158 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `d4306337ffccc0beec3fba595da61f67f1076fb4` | 36070 |
| `FILE.MD/QBEATS_SYSTEM_PROMPT_V5_21_06_2026.md` (Costituzione V5) | *(da misurare al caricamento)* | — |

Più i **due depositi di oggi**, che non sono canonici ma servono a ripartire:
`HANDOFF/CONGEDO_REFEREE_2026-08-01.md` e questo file.

⚠️ **QUALI DI QUESTI SIANO GIÀ NEL PROGETTO DEL REFEREE: NON RICORDO, e non lo invento.**
So `[R]` che il referee uscente aveva copie di LIBRO, BUGS, BOX5 e SCALETTA, perché ne
dichiarò gli OID nel prompt `R1-VERIFICA-BLOB` e quattro su cinque risultarono MATCH; il
quinto, BOX3, fu verificato MATCH stamattina. **Ma il Progetto del referee NUOVO è un
contenitore diverso e non l'ho mai visto: dichiaro il buco invece di colmarlo.**
⇒ **Il referee nuovo verifichi da sé le cinque impronte contro questa tabella. Se una non
combacia, quel file è vecchio e va ricaricato prima di lavorarci.**

---

## §8 — AL CC SUCCESSIVO

- **Non ereditare da riassunti: lo stato vive nei file.** Riapri misurando, non ricordando —
  e vale anche per questo documento.
- **Le non negoziabili:** staging **file per file**, mai `git add -A` (repo **PUBLIC**, oltre
  cento untracked in `HANDOFF/`) · mai `--no-verify` · commit **monoscopo**, autore Mauro,
  zero Co-Auth · **due cancelli separati** (ratifica del referee sul diff verbatim **e** OK
  esplicito di Mauro: nessuno sostituisce l'altro) · ogni prompt porta un **ID** da
  dichiarare in testa · consegnato solo quando il destinatario conferma di aver **letto**.
- **La cosa che oggi ha impedito l'errore più grosso:** non l'attenzione, ma **i controlli
  automatici messi davanti alla scrittura** — le àncore con ABORT hanno fermato il giro due
  volte, e la seconda su un errore mio di conteggio che due riletture non avevano visto.
  **Chi scrive un canonico a mano prima o poi sbaglia; chi ci mette davanti una sonda che
  abortisce, no.**

---

*Fine del deposito. Non è una ratifica.*
