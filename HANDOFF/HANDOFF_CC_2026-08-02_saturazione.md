# HANDOFF CC — chiusura per saturazione, 2026-08-02

**Chi scrive:** CC. **Prompt:** `QB-2026-08-02-Z1-HANDOFF-CC-AUTONOMO`.
**Che cos'è:** un **deposito**, non una ratifica. Niente qui è ratificato dal solo fatto di
stare scritto qui. È il file **non tracciato** che il CC successivo legge per ripartire.

**Convenzione di marcatura, applicata riga per riga:**

- `[V]` — **misurato adesso**, al disco o al blob, in questa sessione, prima di scrivere.
- `[R]` — **so che è vero ma non l'ho potuto misurare adesso** (sta in un messaggio, in un
  prompt, in una risposta del referee: non su un supporto che io possa leggere ora).
- **NON RICORDO** — non lo so con certezza. Scritto così, non aggiustato.

⛔ **Nessun path, commit, sha o numero di riga è scritto a memoria.** Ciò che non ho
verificato ora al disco, non è qui.
⛔ **INDIRIZZO, NON COPIA.** Questo file dice **dove** stanno le cose. Non le riassume: un
riassunto invecchia e mente, un indirizzo no.
⛔ **Questo file non contiene la propria impronta.** Un documento non può contenere il proprio
sha256: quella viaggia fuori, nel messaggio di consegna. Convenzione ratificata 01/08/2026.

Tutti gli indirizzi ai canonici qui sotto sono presi a
`HEAD = 0ee9543d45d638df061c5a48872aaefeb8a88f26` `[V]`.

---

## §0 — LA CODA: cosa è arrivato, cosa è stato fatto, cosa manca

| ID prompt | ricevuto | eseguito | referto |
|---|---|---|---|
| `QB-2026-08-02-S1-DRIVE-SICUREZZA-E-CENSIMENTO` | SÌ `[R]` | **SÌ** | `MISURE_CC_2026-08-02_S1-DRIVE-SICUREZZA.txt` `[V]` |
| `QB-2026-08-02-S2-CREDENZIALI-PERIMETRO-REPO` | SÌ `[R]` | **SÌ** | `MISURE_CC_2026-08-02_S2-PERIMETRO-REPO.txt` `[V]` |
| `QB-2026-08-02-S3` | **MAI RICEVUTO** `[R]` | — | — |
| `QB-2026-08-02-R1-VERIFICA-BLOB` | SÌ `[R]` | **NO — interrotto** | nessuno |
| `QB-2026-08-02-Z1-HANDOFF-CC-AUTONOMO` | SÌ | in corso | **questo file** |

**Tre cose che il prompt Z1 chiede di dire esplicitamente, e le dico:**

1. **`R1-VERIFICA-BLOB` è stato RICEVUTO e NON è stato ESEGUITO.** Mauro ha interrotto la
   richiesta prima che partisse una sola misura. Non esiste referto R1 e non deve esisterne
   uno finto. È il debito più concreto che lascio → §3.
2. **`S2-CREDENZIALI-PERIMETRO-REPO` è stato RICEVUTO ed ESEGUITO.** Il referto esiste, su
   entrambi i supporti `[V]`. **Il referee ha però dichiarato di non averlo mai visto** `[R]`.
   ⚠️ Questa è la firma del **guasto di trasporto**, non di un lavoro mancato: il file c'è ed
   è integro, ma la consegna non è atterrata. Il CC successivo **non lo rifaccia**: lo
   riconsegni, e si faccia confermare la lettura.
3. **`QB-2026-08-02-S3` non è mai arrivato.** Il prompt R1 lo nominava come se fosse già stato
   inviato `[R]`. Non lo è. Se il referee dà per scontato un S3, sta contando su qualcosa che
   non esiste.

---

## §1 — GLI ID ESEGUITI E I LORO REFERTI

**Impronte rimisurate ADESSO dal file su disco** — non riportate dai messaggi in cui le avevo
scritte `[V]`. Tutti in `HANDOFF/`, tutti **non tracciati**, tutti presenti anche nel mirror
`E:` con `cmp` a **exit 0** `[V]`.

| # | file (in `HANDOFF/`) | byte | sha256 | E: |
|---|---|---|---|---|
| 1 | `MISURE_CC_2026-08-01_M1-M4.txt` | 34844 | `f0927c2171d5ec67b97885d98e973f023cb102fdd072906279cde975092e4ed5` | cmp 0 |
| 2 | `MISURE_CC_2026-08-01_M0-M5.txt` | 60478 | `b304387ac4c9d50f025213b4997fb541d8aca1e72d4b4acaac5b9a481860a53c` | cmp 0 |
| 3 | `MISURE_CC_2026-08-01_N1-N5.txt` | 46406 | `3988a121d300af1bd5a42bfc928b95197d70b04f61ad0899cf1c68b79c5455d7` | cmp 0 |
| 4 | `MISURE_CC_2026-08-01_P1-P4.txt` | 33289 | `1970d61f557cef42cfd60bbe1921fc850f525cb67afc8790226afa11a7553254` | cmp 0 |
| 5 | `MISURE_CC_2026-08-01_Q1-Q3.txt` | 24277 | `3b9b2007589741c476fd859dd6e0a683a437972c41c9bc308bc59929d2224a28` | cmp 0 |
| 6 | `MISURE_CC_2026-08-01_R1.txt` | 17789 | `d0775422dbce1eabb0d1f11408e5dcdbca830538c603e75a5d26ac450bffa671` | cmp 0 |
| 7 | `MISURE_CC_2026-08-01_S1-S3.txt` | 50526 | `e164d4dc90d288b0bfc7bc299d8db2557025795a340585e8ca9384fc1f321518` | cmp 0 |
| 8 | `ESITO_COMMIT_BUGSv47-LIBROv49_2026-08-01.txt` | 30556 | `ee3a033e7d3e71a8f381b87b0e3aad64873967a16503babbbc764478a9be1127` | cmp 0 |
| 9 | `MISURE_CC_2026-08-01_T1-COPIA-UNICA.txt` | 17127 | `6adc666bd3256fc9649fc80d54dc130667b22a5ae44dc34d1fb7b4bf059520c5` | cmp 0 |
| 10 | `MATERIE_REFEREE_2026-08-01_perimetro-device.md` | 7010 | `f46e7c21e44c65829855fc6322618de4731f1cc44ab02bf9bbf84722d11a9157` | cmp 0 |
| 11 | `MANIFESTO_DRIVE_2026-08-01.md` | 116433 | `6a4794b2cbfa8f49a6e40b73fa2f6ce107abdfa1f146162e535d7f61493904d8` | cmp 0 |
| 12 | `MISURE_CC_2026-08-01_W3-CHIUSURA-DRIVE.txt` | 6394 | `68c99f975da4a58fd0fe79db650879033d946adf4273e98e268215405a5f6074` | cmp 0 |
| 13 | `MISURE_CC_2026-08-02_S1-DRIVE-SICUREZZA.txt` | 11191 | `3e890bd36719626a8e0a4a82b2d78298df9d0f6b99587a98f2de52e533fb264e` | cmp 0 |
| 14 | `MISURE_CC_2026-08-02_S2-PERIMETRO-REPO.txt` | 10675 | `a5886916057be4b17e7194f62f7651b95d44489b1efef1e7e51de68b26012d1b` | cmp 0 |

**Non li riassumo.** Chi riparte legge il file, non questa riga. Quello che serve sapere per
scegliere quale aprire, in una riga ciascuno:

- **1–7** — il giro di misure che ha preparato le otto marcature del commit di §1-bis.
- **8** — il verbale del commit: cosa è entrato, dove, con quali impronte prima e dopo.
- **9** — inventario delle **copie uniche** e triage di ciò che non deve diventare pubblico.
- **10** — le nove **materie del referee** sul perimetro-device, trascritte verbatim.
- **11** — il **MANIFESTO** per Drive: elenco e impronte di ciò che deve esistere su Drive.
- **12–14** — Drive: chiusura del canale, sicurezza, perimetro credenziali del repo pubblico.

### §1-bis — il commit di questa sessione

`0ee9543d45d638df061c5a48872aaefeb8a88f26` `[V]` — `docs: giro indirizzi e proprietari — BUGS
v47 + LIBRO v49 (doc-only, zero codice)`. Due file, zero codice. Il verbale è il referto **8**.
Regola incisa in quel commit e da rispettare da qui in avanti: **ogni nuovo indirizzo a un
sorgente `.swift` si scrive per SIMBOLO**; un numero di riga, se c'è, deve portare
`@ <commit a 40>`. Sta in `LIBRO_MASTRO_QBEATS.md:335` `[V]`.

---

## §2 — STATO DEL REPO, misurato adesso

```
HEAD                        0ee9543d45d638df061c5a48872aaefeb8a88f26
branch                      master
HEAD = origin/master        SÌ
staging                     VUOTO (0 file)
stash                       0
tracciati modificati        0
untracked                   101
worktree                    C:/Users/BULLFROG/Desktop/ANTIGRAVITY/Q-BEATS   0ee9543 [master]
                            C:/Users/BULLFROG/qb_fixB                       add556f [test/bug2b-test7-fixtures]
```

Tutto `[V]`. **L'albero di lavoro è pulito**: nessuna modifica pendente su file tracciati,
niente in staging, niente in stash. Chi riparte non eredita lavoro a metà nell'indice.

**Untracked dentro `HANDOFF/` — conteggio preso PRIMA che questo file esistesse** `[V]`,
per non contarmi da solo (è un errore che ho già commesso in questa sessione, vedi §4):

```
forma 1  git status --porcelain | grep '^?? HANDOFF/'    98
forma 2  find -maxdepth 1 -type f  MENO  git ls-files    98
file totali in HANDOFF/ (find ricorsivo)                102
di cui TRACCIATI                                          4
```

Due forme indipendenti, stesso numero. **Con questo file diventano 99.** Il quarto tracciato
che conta è `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, che è un canonico vivo `[V]`.

⚠️ **Il secondo worktree `C:/Users/BULLFROG/qb_fixB` esiste ed è su un branch di test** `[V]`.
Non è stato toccato in questa sessione. Chi fa sweep sul «repo» e si ferma alla cartella
principale **misura meno di quello che c'è**.

---

## §3 — LAVORO NON FINITO

### 3.1 — `R1-VERIFICA-BLOB`, blocco A: **l'ho di fatto già risolto, senza volerlo**

Il prompt R1 chiedeva di confrontare gli OID che il referee dichiara per le sue copie di
Progetto con quelli veri a HEAD. **Ho misurato gli OID veri adesso** `[V]`:

```
LIBRO_MASTRO_QBEATS.md                  e4c80f23b712c071f61f8d37469059fbe775c9cf
BUGS_QBEATS.md                          c896f919b1ba93437eff56eee3ab592136203337
BOX5_QBEATS.md                          21b23d621ac224c759b53d813196058483e3b056
HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md d4306337ffccc0beec3fba595da61f67f1076fb4
```

`[R]` I due OID che il **prompt R1** attribuisce alle copie del referee **coincidono** con i
primi due qui sopra. ⚠️ Ma questo confronto lo sto facendo contro la mia lettura del prompt,
**non contro il disco**: il prompt R1 va **riaperto e riletto**, e il confronto rifatto sul
testo vero. Se coincidono davvero, il verdetto è **MATCH per entrambi** e le citazioni del
referee (`LIBRO:329`, `:317`, `:330`, `SCALETTA:314`, `BOX5:83`, `BUGS:743`) sono valide alla
riga. **Non chiudere R1 sulla mia parola: la misura è a metà per costruzione.**

⚠️ Urgenza reale: `[R]` `BUGS:743` è già stato mandato a CD come **precedente vincolante**. Se
quell'indirizzo fosse sbagliato, l'errore è già uscito dalla squadra.

### 3.2 — il referto S2 che il referee non ha mai visto

Vedi §0 punto 2. **Non rifarlo. Riconsegnalo**, e non dichiararlo consegnato finché il
destinatario non conferma di averlo **letto**.

### 3.3 — BOX3 V100

`[R]` Dichiarato «prossimo giro» alla chiusura del giro del 01/08. Non aperto. NON RICORDO se
esista un prompt che lo definisce nel dettaglio.

### 3.4 — Drive: il caricamento è fermo quasi all'inizio

`[V]` Su Drive esistono `Qbeats/`, `Qbeats/test/` (con i due file della prova del canale) e
`Qbeats/HANDOFF/` con **un solo** documento caricato. Il MANIFESTO (referto **11**) elenca
tutto il resto: **circa 650 file non ancora caricati** `[R]`.
⛔ **Il motivo per cui si è fermato, ed è ratificato:** il connettore Drive accetta contenuto
**solo in linea**, quindi copiare il mirror significherebbe **riscrivere ogni byte
attraverso di me** — e «la copia è una riscrittura». Ho rifiutato, il referee ha ratificato.
**La via giusta è una sincronizzazione locale** (Drive per desktop, o rclone) con me che
faccio **manifesto e verifica**, non trasporto. → decisione in §5.

---

## §4 — COSE CHE SO E CHE NON STANNO IN NESSUN FILE

Questa è la sezione che si perde se non la scrivo. Sono **trappole degli strumenti**, pagate
con errori veri fatti in questa sessione.

### 4.1 — Falso-zero da filtro: **tre forme misurate, e una quarta trovata oggi**

Comandi che rendono **vuoto con exit 0** su cose che **esistono**. Già a memoria le prime tre;
oggi ne ho pagata una quarta:

- `gh run list --commit <sha corto>` → vuoto. Serve lo **sha a 40**.
- `git log --since=<data nuda>` → vuoto.
- `find -maxdepth N` → vuoto se il bersaglio sta più in fondo (il mirror `E:` sta a
  profondità 5, non 4).
- **NUOVO oggi** `[V]`: **cercare su UN SOLO supporto.** Ho cercato `*ROADMAP_2026-07-24*` su
  `E:` e ho trovato **un file solo**, concludendo che la coppia non esistesse. Cercando su
  `C:` **e** `E:` la coppia c'è ed è **a cavallo dei due supporti**:
  `HANDOFF/_SUPERATO__ROADMAP_2026-07-24.txt` (C:, 5963 B) e `HANDOFF/ROADMAP_2026-07-24.txt`
  (E:, 5963 B), **`cmp` exit 0, sha256 `e3a4feef46fa1e69c92d51396a548202591796647620273ad43015e61a369fc0`** `[V]`.
  **Stessi byte esatti, due nomi che dichiarano stati opposti** — uno dice «superato», l'altro
  no. Nessuno dei due è ticketato.

**Contromisura, sempre: due forme indipendenti prima di scrivere un numero.**

### 4.2 — Strumenti che su questa macchina non esistono

`[V]` **`security` ASSENTE** (è un comando macOS — sostituto usato: `openssl cms -inform DER
-verify -noverify`). `[V]` **`rev` ASSENTE**. Presenti e usabili: `sha256sum`, `openssl`,
`python`, `git`, `gh` `[V]`.

### 4.3 — Chi mente sui CR, e chi no

`[V]` `sed` e `grep` **mangiano i CR** e fanno sembrare a una faccia un file che ne ha due.
Dicono il vero solo: `tr -cd '\r' | wc -c`, `od -c`, e Python che legge **in byte**.
Vale ogni volta che si misura `BUGS_QBEATS.md` o `LIBRO_MASTRO_QBEATS.md`, che hanno **due
facce** (CRLF su disco, LF nel blob) perché `.gitattributes` **non li copre** `[V]`.

### 4.4 — Trappole di scrittura degli script

- `[V]` **`awk` si spezza sui nomi di file con spazi.** Mi ha inventato 10,7 MB di file
  fantasma «senza estensione». Rimedio: `find -printf '%s\t%p\n'` **con tabulazione** + Python.
- `[V]` **Gli heredoc storpiano gli escape** `\0` e `\n` — uno mi ha piazzato un byte NUL
  dentro un sorgente. Rimedio: **scrivere gli script con lo strumento Write**, mai per heredoc.
- `[V]` Le emoji fuori dal piano base vogliono la forma `\U0001F534`; la forma a coppia
  surrogata solleva `UnicodeEncodeError`.
- `[V]` `$var` non quotato in un `for` su path con spazi → risultato spazzatura. Usare
  `while IFS= read -r`.

### 4.5 — **Il redirect crea il file prima che il conteggio giri**

`[V]` Il referto R1 (il **6**) **ha contato sé stesso**: la shell aveva già creato il file di
uscita quando il censimento ha percorso la cartella. L'ho buttato e rifatto **fuori** dall'area
censita. È il motivo per cui il conteggio di §2 qui sopra è stato preso **prima** di scrivere
questo file. **Chi conta una cartella scrivendoci dentro, sbaglia.**

### 4.6 — Il connettore Drive: cosa fa e cosa non fa

- `[V]` `search_files` rende **righe duplicate per lo stesso id** (un file con più genitori).
  **Contare le righe invece degli id distinti dà un numero falso**: mi è successo — 711 righe
  contro **709 file distinti**, e da lì erano nati un falso «16 `.ttf`» e quattro falsi font
  duplicati. Il vero è **12 `.ttf`**, nessun duplicato. **Il referee ha visto l'errore prima
  di me.** Contare **sempre gli id distinti**.
- `[V]` `title contains ' '` **non filtra** sullo spazio.
- `[V]` `get_file_metadata` espone 12 campi e **nessun checksum**, benché l'API v3 di Drive
  dichiari `md5Checksum`/`sha1Checksum`/`sha256Checksum`: **il connettore non li fa passare**.
  Per verificare un file su Drive bisogna **riscaricarlo** e ricalcolare.
- `[V]` `create_file` prende il contenuto **solo in linea** → §3.4.
- `[V]` **Il canale Drive NON altera i byte**: provato all'andata e al ritorno, e poi con nove
  confronti dopo il caricamento da browser. Tutti identici. Quindi se un file su Drive risulta
  diverso, **è successo qualcosa prima**, non nel trasporto.

### 4.7 — I risultati grossi degli strumenti finiscono su disco

`[V]` Le risposte MCP grandi vengono **salvate in un file** e si possono lavorare **in locale**.
È la tecnica che ha reso possibile il censimento byte-esatto **senza far passare il contenuto
attraverso di me**. Chi non lo sa, rinuncia a misure che sono invece alla portata.

### 4.8 — Reperti veri, mai ticketati da nessuno

- `[V]` `.github/workflows/ios_build.yml:57` (a `0ee9543d45d638df061c5a48872aaefeb8a88f26`)
  contiene `KEYCHAIN_PASSWORD="temp_keychain_password"` **in chiaro in un repo pubblico**.
  Gravità **bassa**: è una password di comodo per un portachiavi effimero sul runner, non
  apre nulla. **Ma non è ticketata.**
- `[V]` `E:\…\CERTIFICATI\QBeats-Certs\p12_base64.txt`, 4126 B: **è la chiave privata sotto
  estensione `.txt`**. Oggi non è esposta. **Domani lo sarebbe** davanti a qualunque regola
  che filtri per estensione. Dettaglio nel referto **14**.
- `[V]` `tools/lint_canonici.py` esiste su disco (12076 B) ed è **non tracciato**. Uno
  strumento che nessuno vede.
- `[R]` In `CERTIFICATI/` il profilo è quello **di aprile, superato** (1 UDID), mentre quello
  vivo è un altro (2 UDID). Numeri nel referto **14**.
- `[R]` L'account Drive usato è **diverso** dall'identità che firma i commit. Non è un
  problema, ma nessuno l'ha mai scritto.
- `[V]` Su `E:\…\DA_CD_PER_CC\` esistono **altri due** file col prefisso `_SUPERATO__`
  (24_07 e 26_07). Convenzione di fatto, mai ratificata da nessuna parte.

### 4.9 — Un errore mio di metodo, che vale più dell'errore

`[V]` Il mio rilevatore di credenziali **non agganciava proprio il file che aveva motivato la
sua classe**, e il primo esito «zero» era quindi **privo di valore**. L'ha scoperto il mio
**controllo positivo**, non io. **Ogni rilevatore va provato su positivi certi e su un negativo
certo prima di credere a uno zero.** Nella stessa sessione ho anche misurato **l'artefatto
sbagliato** (gli ancoraggi nel *sorgente* Python invece che nel *testo reso*) e ho scritto un
`grep` così largo da agganciare una tabella di glossario al posto del registro.
**Uno zero non è un risultato finché la forma della ricerca non è stata provata.**

---

## §5 — DECISIONI CHE ASPETTANO MAURO

Sono aperte. **Nessuna è stata decisa da me e nessuna va data per decisa.**

1. **Il `.mobileprovision` che sta su Drive.** Contiene 2 UDID, un certificato **pubblico** e
   gli entitlement; **nessuna chiave privata**. Esposizione **reale ma limitata**. Toglierlo o
   lasciarlo? Elementi nel referto **14**.
2. **I due `.txt` in `CERTIFICATI/`** (`p12_base64.txt`, `provision_base64.txt`): rinominarli,
   spostarli, o lasciarli dove sono? Vedi §4.8.
3. **`.gitattributes`**: oggi copre `HANDOFF/**`, `DESIGN/**`, `BOX3`, `BOX5` — e **non**
   LIBRO e BUGS, che perciò restano **a due facce**. Estenderlo, o tenere la doppia faccia
   come stato dichiarato?
4. **BOX3 V100** — quando.
5. **Il divario di perimetro iOS 16.0 contro iPhone 11** `[R]` — sollevato, mai deciso.
6. **Condividere la cartella Drive col referee**: a quale indirizzo, e in **sola lettura**?
   Finché non è condivisa, il canale esiste ma **non serve a nessuno**.
7. **I ~650 file ancora da caricare su Drive** e con quale via → §3.4. **Raccomandazione mia:
   sincronizzazione locale**, non trasporto attraverso di me.
8. **I file fuori da ogni regola del MANIFESTO** — elencati nel referto **11**, in fondo.
9. **`tools/lint_canonici.py`**: tracciarlo o no.
10. **La coppia ROADMAP a byte identici sotto due nomi in contraddizione** (§4.1): quale dei
    due stati è quello vero.

---

## §6 — DA DOVE SI RIPARTE

**Il prossimo atomo è ⟦S5⟧.** Non è un ricordo: è **verificato a fonte adesso** `[V]`.

- `LIBRO_MASTRO_QBEATS.md:329` `@ 0ee9543d45d638df061c5a48872aaefeb8a88f26` incide l'ordine
  emendato: **S4 ✅ → ⟦S4K⟧ ✅ → ⟦S4R⟧ → ⟦S5⟧ → ⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧**.
- `LIBRO_MASTRO_QBEATS.md:330` `@ 0ee9543d45d638df061c5a48872aaefeb8a88f26` dichiara **⟦S4R⟧
  CHIUSO** a codice — **e in modo esplicito NON chiuso device**: entrambe le metà della
  decisione del 18/07 (nascita del runner allo Start, morte al bordo-stanza) restano **non
  provate fino a ⟦S5⟧**.

⇒ **⟦S5⟧ è il prossimo, e il suo gate device è il gate nominato della proprietà del runner**:
è lì che ⟦S4R⟧ viene finalmente validato. Il percorso di prova è scritto nella riga `:329`.

⛔ **Vincolo ratificato da non violare** (`LIBRO_MASTRO_QBEATS.md:329` `[V]`): **nessuna
sessione multi-device e nessuna data con la band su una build che contenga ⟦S5⟧ finché
⟦S-EXIT⟧ non è chiuso device.**

⚠️ **⟦S4L⟧ è SOSPESO** e non va costruito: la stessa riga `:329` lo blocca su tre pendenze —
(a) atomo assegnato alla pillola ▶, (b) forma tecnica del campo di persistenza, (c) procedura
di rollback dei dati utente. Costruirlo oggi spezzerebbe un blocco che un canonico dichiara
inseparabile.

⚠️ **La SCALETTA è indietro rispetto al LIBRO.** In
`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` a HEAD, **⟦S6F⟧ e ⟦S-EXIT⟧ compaiono ZERO volte**
`[V]` — due atomi che il LIBRO ha ratificato (`:334` e `:327`) e che la scaletta **non
conosce ancora**. Chi legge solo la SCALETTA lavora su una mappa vecchia.

### Le prime tre mosse, in ordine

1. **Rileggere il prompt `R1-VERIFICA-BLOB`** e chiudere il confronto di §3.1 sul testo vero.
   Gli OID a HEAD sono già misurati lì: manca solo l'altra metà.
2. **Riconsegnare il referto S2** e **farsi confermare la lettura** (§0 punto 2).
3. **Chiedere `S3`**, che non è mai arrivato — o accertare che non esista.

### Le regole ferree, che non si rinegoziano a ogni sessione

**Verifica a fonte** · **due cancelli per commit** (ratifica del referee **e** ok esplicito di
Mauro: nessuno dei due sostituisce l'altro) · **`push` ≠ chiuso** · **«chiuso» solo dopo il
device confermato da Mauro** · **si marca, non si riscrive** · **indirizzo, non copia** ·
**l'impronta prova l'identità, non la completezza** · **consegnato solo quando il destinatario
conferma di aver letto**.

---

*Fine del deposito. Non è una ratifica.*
