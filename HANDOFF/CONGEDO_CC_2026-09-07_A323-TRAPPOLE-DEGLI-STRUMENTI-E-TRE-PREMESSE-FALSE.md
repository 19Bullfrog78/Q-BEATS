# CONGEDO CC — 07/09/2026 · A323

Scritto da me, CC della sessione che si chiude, per il CC che apre la prossima senza niente in mano.

⛔ **Questo documento non e' una fonte.** Ogni numero ha il suo indirizzo: vai a vederlo. Se una mia affermazione e il repo non concordano, ha ragione il repo. Nulla e' ratificato per il fatto di stare scritto qui.

**Marcature:** `[M]` = misurato da me alla fonte in questa sessione · `[R]` = riportato da altri, non verificato da me · `[A]` = mio giudizio.

⛔ **Qui dentro non c'e' lo stato del progetto.** Versioni, ticket, roadmap vivono nei canonici: si leggono li', non qui. Un congedo che li ricopia nasce gia' stantio.

---

## PARTE 1 — Le trappole degli strumenti

**Questa e' la parte che vale.** Sono inciampi in cui sono caduto io, in questa sessione, con la loro meccanica. Non sono scuse: sono buche segnate sulla mappa.

### 1 · Non verificare mai un oggetto contro il suo strumento di stampa

`[M]` Ho confrontato un messaggio di commit col file da cui l'avevo dettato usando `git log -1 --format=%B`. Rendeva **1793 byte contro 1792**: uno scarto apparente, e per un momento ho creduto che il commit fosse sporco.

Non era il commit. **`git log` aggiunge un `\n` in stampa.** Il messaggio dentro l'oggetto e' esattamente 1792.

```
git cat-file commit HEAD | sed -n '/^$/,$p' | tail -c +2   <- la fonte
git log -1 --format=%B                                      <- lo strumento di stampa
```

⇒ **Per l'identita' di un messaggio di commit la fonte e' `git cat-file`.** Vale oltre git: ogni volta che confronti due cose e una passa da un formattatore, il formattatore e' un sospetto.

### 2 · `ls | tail` ordina alfabeticamente, e le versioni non sono alfabetiche

`[M]` Cercavo la stampa piu' alta di BOX3 su `E:` con `ls -1 | sort | tail -5`. Ho concluso che fosse `V99` e che `V100` mancasse.

**`V100` c'era.** In ordine alfabetico `BOX3_V100` viene **prima** di `BOX3_V96`, perche' `1` < `9` al secondo carattere. Il `tail -5` lo tagliava fuori.

⇒ **Per i numeri di versione serve `sort -n` su un campo estratto**, mai l'ordine naturale di `ls`. Famiglia **P2**: fatto-che-sembra-vuoto.

### 3 · `git ls-files | grep <nome>.swift` pesca la stampa, non la fonte

`[M]` `git ls-files | grep -i 'AudioEngine.swift' | head -1` rende **`HANDOFF/STAMPA_A240_d0225ef_AudioEngine.swift`**, non `ios_app/QBeats/AudioEngine.swift`. Alfabeticamente `H` viene prima di `i`.

Ho letto dieci righe della copia sbagliata prima di accorgermene — e quelle righe **sembravano sensate**, il che e' la parte pericolosa: la stampa e' un vero file Swift di un altro commit.

⇒ **In questo repo `HANDOFF/` contiene copie di sorgenti.** Qualunque ricerca di un file di codice va filtrata: `grep -v HANDOFF` o path esatto. Se il contenuto ti sembra plausibile ma le righe non tornano con quelle attese, sospetta di aver aperto una stampa.

### 4 · Il heredoc di bash si rompe sui documenti lunghi

`[M]` Due volte in questa sessione, su referti di ~180 righe con apostrofi italiani, `cat > file <<'EOF'` e' morto con `unexpected EOF while looking for matching '`. Il delimitatore era quotato, quindi il quoting interno non c'entra.

⚠️ **Buona notizia, verificata:** muore **in parsing**, quindi **non scrive niente e non danneggia niente**. Ho controllato entrambe le volte (`ls` sul file, `git status`): nessun file creato, repo pulito.

⇒ **Per un documento lungo usa lo strumento di scrittura, non il heredoc.** Il heredoc va bene per poche righe. (Anche il giro A321 c'era gia' inciampato: non e' un caso isolato.)

### 5 · Cancellare una classe di caratteri li cancella tutti

`[M]` Per verificare che i puntatori dell'indice di memoria fossero risolvibili ho estratto i nomi con `tr -d '](.)'`. Quel `tr` cancella **anche il punto di `.md`**: ogni nome diventava `xxxmd`, poi ci riattaccavo `.md`, e la sonda rendeva **162 puntatori rotti su 162**.

Erano rotti zero. Rifatta con `sed 's/^](//; s/)$//'`: **162 su 162 risolvono.**

⇒ **`tr -d` con una classe cancella ogni occorrenza ovunque, non solo agli estremi.** Per togliere delimitatori serve `sed` ancorato. E il segnale d'allarme era li': **una sonda che dichiara il 100% rotto sta quasi sempre misurando se stessa.**

### 6 · Python qui e' quello di Windows

`[M]` Due inciampi distinti nella stessa riga di comando:

- **Non capisce i path MSYS.** `open('/c/Users/...')` rende `FileNotFoundError`. Servono path nativi: `r'C:\Users\...'`.
- **Il backslash non sopravvive a `python -c` dentro bash.** Un `'\\\\'` nel sorgente arrivava all'interprete come `'\'` e produceva `SyntaxError: unterminated string literal`.

⇒ **Per qualunque script Python non banale, scrivilo in un `.py` nello scratchpad ed eseguilo.** Niente `python -c` con path o escape.

### 7 · `gh run list --commit <sha40>` rende `[]` subito dopo il push

`[M]` Non e' un errore e non significa «nessun workflow e' partito»: e' **ritardo di registrazione**. Il run c'era, l'ho trovato con `gh run list --branch master --limit 3` e un attimo dopo compariva anche per commit.

⇒ **Non concludere niente da un `[]` immediato.** Rileggi per ramo. (⚠️ Distinto dal difetto gia' noto e diverso: con lo **sha corto** `--commit` rende `[]` **stabilmente** — li' e' l'sha a 40 che serve.)

### 8 · `grep -c` che rende 0 esce 1, e l'ambiente lo chiama errore

`[M]` `git diff --name-only | grep -cE '\.swift$|^DESIGN/'` ha reso **`0`** — la risposta giusta, il perimetro era pulito — ma con **exit 1**, e la chiamata e' comparsa come fallita.

⇒ **Su un `grep -c` usato come cancello, lo zero e' l'esito desiderato.** Aggiungi `|| true`, oppure metti quel conteggio da solo e leggilo, senza incatenarlo con `&&` a comandi che devono seguire.

### 9 · `grep -c $'\r'` mente sui CRLF

`[R, gia' inciso in CLAUDE.md]` `[M, riconfermato]` Non l'ho usato per misurare, ma lo scrivo perche' e' la trappola piu' citata e la piu' facile da riprendere per abitudine.

⇒ **I fine-riga si contano sui byte**, con Python, su `b'\r\n'`. Ed e' un caso particolare della trappola 1: contava le righe, non i CR.

---

## PARTE 2 — Misure gia' fatte: non rifarle

`[M]` Tutte alla fonte in questa sessione. Portano il loro indirizzo: verificale se ti servono per decidere, non ripeterle per abitudine.

### I sei warning di F1 — non sono debito da azzerare, sono tre famiglie deliberate

Letti a `871de34`, e **preesistenti almeno dal 31/07** (stessi sei, stessa identita', nel run `30638276963` su `master`; solo le righe sono slittate perche' i file sono cresciuti).

| warning | cos'e' davvero |
|---|---|
| `QBeats-Bridging-Header.h:1` — `#pragma once in main file` | cosmetico |
| `AudioEngine.swift:2066,2067,2068` — `handle`/`tbNumer`/`tbDenom` mai usati | resti di una migrazione **dichiarata nel codice**: il broadcast Link e' passato al beat callback il 15/05/2026, e il commento dice che la pulizia va in **un commit separato post-device-verde** |
| `QLiveShowsView.swift:306,310` — `will never be executed` | conseguenza di **`let isPick = false`** a **riga 282**, dichiarato in testa al file a **righe 31-34** come flag in attesa di ratifica: «il ramo di stile e' implementato ma `isPick` resta false per OGNI riga: niente evidenza finta» |

⛔ **«Ripararli» e' un danno, non una pulizia.** Su `QLiveShowsView` significa cancellare rami di stile che aspettano un modello; su `AudioEngine` significa fare oggi una pulizia che il codice stesso dice di rimandare. `[A]`

### Le «due facce» CRLF di LIBRO e BUGS **non esistono piu'**

`[M]` `.gitattributes` copre **tutti e quattro** i canonici con `-text` dal **30/08**, commit `b962c48` («chore(git): BUGS, LIBRO e .gitattributes protetti con -text»). Misurato a `8ea30ce`: **disco `C:` e blob coincidono byte-per-byte per LIBRO, BUGS, BOX5, BOX3 e SCALETTA, CRLF = 0 ovunque.**

⚠️ **Resta vero, e per una ragione diversa da quella che troverai scritta in giro:** estrarre una stampa **dal blob** (`git show <sha>:<path>`) e' il metodo giusto perche' **non dipende dallo stato del working tree**, non perche' il disco oggi sia sbagliato.

⛔ Se un documento o un mandato ti dice che LIBRO e BUGS hanno due facce, **e' scaduto**. Non andare a «riparare» un pericolo rimosso. `[A]`

### La seconda gamba R-δ: com'e' andata davvero

`[M]` Le stampe dei canonici su `E:` **non mancavano da tre giri**. Contate per `sha7` nel nome, e datate per mtime:

```
v75  scritta 2026-09-03 14:48   <- commit d61e823 delle 14:47:57
v76  scritta 2026-09-04 16:52   <- commit 3329f86 delle 16:52:13
v77  scritta 2026-09-06 13:28   <- commit 871de34 delle 13:28:34
```

Tre giri di fila, depositate **nello stesso minuto del commit**. Il buco era **uno solo**, ad A322.

⚠️ **Esiste una TERZA gamba che io non posso ne' leggere ne' scrivere:** il Project di Claude. I congedi di A315, A317 e A318 portano tutti la nota «DA FARE MAURO: caricare nel Project le stampe nuove». `[A]` Se qualcuno dice che «i canonici non arrivano da tre giri», probabilmente parla di quella — e non la ripari tu.

### Il quinto scarto del piede di END SHOW

`[M]` Il ticket ne elencava quattro. Contati sul diff ratificato: sono **cinque**, e il quinto e' la **posizione verticale** — il codice del 05/09 teneva titolo e pulsante in un `VStack(spacing: 24)` centrato nello `ZStack`, cioe' **il pulsante a meta' schermo**. Ora e' inciso nel ticket.

⇒ La lezione non e' il numero: e' che **davanti a un conteggio dichiarato che non torna con l'elenco, si conta.** Non si aggiusta la parola e non si taglia l'elenco.

---

## PARTE 3 — Cio' che ho misurato e NON ho toccato, e perche'

⚠️ **Leggi questa parte prima di «sistemare» qualcosa.** Ognuna e' una **scelta**, non una svista. Se la cambi, cambiala sapendo cosa costa.

### Il registro versioni di BUGS e' sfalsato di due

`[M]` `BUGS_QBEATS.md` Sezione 5, tabella con intestazione `| Versione | Data | Autore | Modifiche principali |`. **Riga piu' alta: `81`. Testa del documento: `84`.** Il contenuto conferma lo sfasamento: la riga `79` descrive testualmente un «bump tardivo **v80→v81**».

⛔ **Non ho aggiunto la riga del giro nuovo.** Aggiungerla obbliga a **scegliere fra due numeri** — `82`, che consolida lo sfasamento, oppure `84`, che crea un salto visibile — e quella scelta non e' di CC. Correggere le righe storiche significherebbe **rinumerarle**, cioe' la riscrittura retroattiva che la casa vieta.

⇒ **Decisione per Mauro e per il referee.** `[A]`

### L'attribuzione dei commit e' cambiata a meta' sessione

`[M]` Misurato sui quattro commit della catena:

```
871de34  Co-Authored-By assente
479535a  Co-Authored-By assente
8ea30ce  Co-Authored-By PRESENTE
d4dcbc8  Co-Authored-By PRESENTE
```

`[A]` La discontinuita' e' reale e sta in un registro permanente. La ragione: l'istruzione di attribuzione attiva nella sessione lo prescrive e dichiara di sostituire ogni indicazione precedente; i due commit senza trailer avevano il messaggio **dettato verbatim** da un mandato, e li' il verbatim vinceva. Dove il messaggio non era dettato, ha vinto l'istruzione.

⇒ **L'ho dichiarato invece di sceglierlo in silenzio, in entrambe le direzioni.** La convenzione la fissa Mauro. Se vince quella di casa, i prossimi tornano senza trailer.

### Il ramo `build-check/a320-endshow-scratch`

`[M]` Vivo a `2e2f15cf5506eab435466c416e96e88f91c24b1d`, in locale **e** sul remoto. ⛔ **Non cancellarlo:** e' l'ancora della prova citata dentro un messaggio di commit. La cancellazione e' un giro a se', decisione del referee.

### Sette documenti fuori dal deposito — e due li ho aggiunti io

`[M]` `git status --porcelain HANDOFF/` rende **7** file untracked. Verificato uno per uno: **tutti e sette stanno anche su `E:` e sono identici** (`cmp` su ciascuno). ⇒ **Non e' un problema di mirror: e' solo git che non li ha.**

⚠️ **Due sono miei, di questa sessione**, e non e' una dimenticanza: i mandati che li hanno prodotti autorizzavano a **scriverli**, non a **committarli**. Ho fatto cio' che era autorizzato.

⇒ `[A]` Se apri un giro che tocca `HANDOFF/`, mettili dentro per primi: sono le uniche tracce scritte di sette giri di lavoro e vivono su due dischi soltanto.

### Debito lasciato aperto di proposito, gia' registrato altrove

⚠️ **86 citazioni nude storiche + due ancore deboli del LIBRO** — mandato a se', ⛔ non toccarle prima. Non le ho guardate in questa sessione: lo scrivo perche' **non le ho verificate**, non perche' le abbia trovate a posto. `[A]`

---

## PARTE 4 — Tre premesse di mandato che la misura ha smentito

⚠️ **Dati, non critiche.** Li scrivo perche' la contromisura sta nel processo, non nella memoria di chi esegue.

1. `[M]` Un mandato chiedeva di **incidere in BOX5 un rinomino che era gia' inciso** — decisioni **11** e **17** della tabella del 26/08. Mancava la **nota** sul freeze, non il rinomino. **Non ho duplicato**, ho aggiunto solo cio' che mancava.
2. `[M]` Un mandato dichiarava **cinque scarti** dove il ticket ne elencava **quattro**. Contati sul diff: cinque veri, e il quinto non era nell'elenco (vedi Parte 2).
3. `[M]` Un mandato dichiarava che la seconda gamba mancava **«da tre giri»** e che `.gitattributes` **non copriva** LIBRO e BUGS. Misurato: **un giro solo**, e `.gitattributes` **li copre entrambi dal 30/08** (vedi Parte 2).

`[A]` **La lezione che porto io, e non e' sul referee:** in un caso la seconda gamba R-δ non e' stata eseguita **perche' il mandato non la nominava** — ed e' vero, ma **R-δ e' una regola ratificata, e andava applicata comunque**. Il mandato non e' una fonte, e non e' nemmeno un'esenzione. `[A]` La contromisura solida e' una riga fissa nel modello di mandato: **una regola che dipende dalla memoria di un esecutore e' una regola che prima o poi salta.**

---

## PARTE 5 — Dove sta tutto

`[M]` Misurato adesso, prima di scrivere questa riga:

```
ramo          : master
HEAD          : d4dcbc808b9e95c3ac1c901e583f7a6545a376f7
origin/master : d4dcbc808b9e95c3ac1c901e583f7a6545a376f7
tracciati modificati : 0
```

⛔ **Le versioni dei canonici non sono scritte qui di proposito.** Leggile in testa ai file: `LIBRO_MASTRO_QBEATS.md`, `BUGS_QBEATS.md`, `BOX5_QBEATS.md`, `BOX3_QBEATS.md`, `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`. ⚠️ **Il campo si chiama ora `Decisione:` e porta il giorno della decisione, non del deposito** — la data del deposito vive in git.

**I referti di questa sessione**, in `HANDOFF/` e su `E:`, si citano per nome e non si riassumono qui:

- `REFERTO_A320_FASE2_2026-09-06.md`
- `REFERTO_A322_GIRO-DOCUMENTI_2026-09-07.md`
- `REFERTO_A324_R-DELTA-ARRETRATO_2026-09-07.md` — l'unico **tracciato**

**Capacita' della macchina, confermate in questa sessione** `[M]`: `gh` autenticato con scope `workflow` ⇒ CC puo' lanciare un `workflow_dispatch` e far compilare del codice su un ramo senza toccare `master`. ⛔ **Nessuna toolchain Swift in locale**: l'unica compilazione possibile e' quella remota.

---

## L'ultima cosa, ed e' la piu' corta

Le due volte in cui questa sessione ha prodotto qualcosa di utile davvero — il quinto scarto e le tre premesse smentite — **non stavo eseguendo meglio: stavo contando invece di credere.**

`[A]` Quando un mandato ti da' un numero e la fonte te ne da' un altro, il lavoro non e' far tornare il numero. E' dire quale dei due hai misurato, con quale comando, e fermarti li'.
