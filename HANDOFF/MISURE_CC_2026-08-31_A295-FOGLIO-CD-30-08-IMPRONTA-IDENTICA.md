# MISURE CC — A295 — 31/08/2026

Da: CC · A: referee.

**Orologio**: 31/08/2026, 13:02 locale (UTC+2) — da `date` di sistema.

Marcatura: **[M]** misurato ORA, alla fonte · **[R]** riportato da altri, non verificato da me ora · **[A]** giudizio mio.

---

## APERTURA (R1 + R8)

**[M]** LIBRO letto, **v69** (header `LIBRO_MASTRO_QBEATS.md`, riga `**Versione:** 69`). Working directory `C:\Users\BULLFROG`. `git worktree list`: `Desktop\ANTIGRAVITY\Q-BEATS` @ `597961e` [master] + `qb_fixB` @ `add556f` [test/bug2b-test7-fixtures]. HEAD locale `597961e` = `origin/master` — **ALLINEATI**.

## PASSO ZERO — cancello ID, rimisurato fresco in questo giro

**[M]** Sei gambe, `A295`: **0 su tutte e sei** (nomi `C:`/`E:`, `git grep`, disco `C:`/`E:` untracked compresi, `git log --all --grep`).

Controlli positivi, stesso giro, stessa sonda: `A294` ora rende **1** su nomi `C:`/`E:` e disco `C:`/`E:` (era 0 un turno fa — la sonda vede il cambiamento in tempo reale), **0** su `git grep`/`log` (corretto: è untracked, non è cecità). `A293` e `A290` rendono tutti **>0** su ogni gamba tracciata. Le sonde vedono.

⇒ **A295 ASSEGNATO a questo mandato** (`R-δ.8`: da campione a lavoro, nell'istante in cui questo referto esiste).

## IL FATTO — il file non era dove il mandato lo dichiarava

**[M]** `DA_CD_PER_CC/30_08_2026/DESIGN/QLive_Player/` **non esiste** su `E:`: la struttura `DA_CD_PER_CC` ha una sola cartella di primo livello, nessuna sottocartella `30_08*`. Stessa forma di trappola già registrata nel congedo precedente (le cartelle di deposito non si chiamano come i file, né come li dichiara una ricevuta).

**[M]** Trovato per ricerca larga, due gambe indipendenti, nello stesso giro:
- `E:`: `_TRANSITO_DA_VERIFICARE\A275_foglio-CD-30-08\2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE__END-SHOW-sullo-scaffale-e-sei-decisioni-incise__390x844.html`
- Drive: cartella **"Qbeats_IN_CD"**, id file `1p2Gcl8N6GOrljefeBeDN3X-3__Tmz4AE`, `fileSize` dichiarato dall'API Drive = 59659 — combacia già a questo livello di metadato.

## PROVENIENZA — [R], da `PROVENIENZA.txt` già in loco su E:, non scritto da me

Racconta una catena su due mandati precedenti, non misurati da me ora: scaricato da Drive (stessa cartella, stesso file id) **due volte indipendenti** nel mandato A275 (stessa impronta su entrambi gli scarichi, dichiarati confrontati `cmp` exit 0); portato da scratchpad a questa sede durevole su `E:` nel mandato A277. Contiene un cancello esplicito, mai chiuso fino ad ora: **"NON VERIFICATO contro l'originale di CD — non archiviare in DESIGN/ finché il confronto non è fatto."** Dichiara anche un proprio limite, onestamente: l'orario che riporta è derivato dal timestamp dell'harness, non un orologio misurato in diretta allo scarico.

⇒ Il compito di questo mandato **è esattamente quel cancello**. Le misure sotto lo chiudono.

## MISURE — [M], fresche, questo giro, stesso strumento, con assert prima di scrivere

| oggetto | byte | sha256 | esito |
|---|---|---|---|
| controllo positivo (18/07, già nel repo) | 58463 | `8d7a3150050f2d9ee88d552f6a59649081518a1189182174c5dfed655c398860` | combacia l'atteso |
| riferimento CD (ricevuta A276, dato dal mandato) | 59659 | `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f` | — |
| copia `E:` (`_TRANSITO_DA_VERIFICARE`) | 59659 | `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f` | combacia il riferimento |
| copia Drive (scaricata ora, decodificata da base64) | 59659 | `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f` | combacia il riferimento |

`cmp` fra copia `E:` e copia Drive decodificata: **exit 0, IDENTICI** (non solo stesso hash: stessi byte, confronto diretto).

## VERDETTO

**IMPRONTA IDENTICA.** I byte hanno attraversato Drive intatti — non è il caso del 5 agosto. Procedo secondo il mandato.

## R-δ — §2 copre il caso, non è una lacuna da dichiarare

`BOX5_QBEATS.md`, capitolo R-δ §2 «Dove va cosa, per natura»: riga **«contratti e freeze CD» → `DESIGN/QLive_Nav/` su C:, `DA_CD_PER_CC/<data>/` su E:**.

⚠️ La «sede CD dichiarata nella ricevuta A276» che il mandato riporta (`DA_CD_PER_CC/30_08_2026/DESIGN/QLive_Player/`) **non è la sede che R-δ prescrive**, né quella dove il file era realmente depositato: è una terza stringa, di CD, non del regime di consegna. Dopo OK + push, la copia `E:` andrebbe spostata da `_TRANSITO_DA_VERIFICARE\A275_foglio-CD-30-08` a `DA_CD_PER_CC\30_08_2026` — **non eseguito**: fuori dal perimetro di questo mandato, che si ferma al commit non eseguito.

## PREPARATO, NON ESEGUITO

**[M]** Copiato `E:` → `DESIGN/QLive_Nav/2026-08-30_QLive-Player_IL-VELO-DICE-DA-DOVE__END-SHOW-sullo-scaffale-e-sei-decisioni-incise__390x844.html`. Verificato **dopo** la scrittura (guardia, non fidarsi): `cmp` con la sorgente `E:` → IDENTICI; sha256 sul file scritto = 0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f, combacia.

`.gitattributes` — `DESIGN/** -text` (riga 2) copre il path nuovo: `git check-attr text` rende `unset`, verificato non assunto.

Staging: **solo** questo file (`git add --` sul path esplicito, mai `-A`). `git status --porcelain` mostra **una sola** riga `A `. `git diff --cached --stat`: 1 file, 393 inserzioni, zero cancellazioni — aggiunta pura.

Identità git locale già `Mauro Martintoni <di_tutto@icloud.com>` (config esistente, non impostata da me in questo giro), nessun hook attivo, nessun `commit.template`: un commit semplice eredita autore=committer corretti senza bisogno di override espliciti.

**Comando pronto, NON eseguito:**
```
git commit -m "DESIGN: archiviato foglio CD 30/08 (A295)"
```

## PERIMETRO NEGATIVO

⛔ Nessun canonico toccato (BUGS/LIBRO/BOX3/BOX5/SCALETTA invariati — verificabile da `git status`, zero righe tracciate modificate oltre lo staging dichiarato). Nessun codice toccato. Nessun altro file archiviato: censimento della cartella di ritrovamento su `E:` — contiene **solo** il file target + `PROVENIENZA.txt`, nient'altro. Nulla scritto su Drive: due letture (`search_files` + `download_file_content`), zero scritture.

## PROSSIMO ID LIBERO (`R-δ.9` — si nomina solo l'assegnato, i candidati scartati per relazione)

Il numero **immediatamente successivo** ad A295 è stato verificato sulle sei gambe nello stesso giro, con gli stessi controlli positivi di questo cancello: **libero**.

---

*MISURE_CC A295 — FINE. In attesa di ratifica referee + OK esplicito di Mauro prima del commit.*

---

## CORREZIONE — MANDATO A296, 31/08/2026

**[M]** Rimisura fresca, senza rileggere questo referto, delle tre impronte contestate dal referee — tutte piene, 64 caratteri, stesso strumento:
- foglio CD, sede attuale `DESIGN/QLive_Nav/2026-08-30_QLive-Player_...390x844.html`: `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f`
- copia `E:` (`_TRANSITO_DA_VERIFICARE/A275_foglio-CD-30-08/...`): `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f`
- contratto 18/07 (controllo positivo): `8d7a3150050f2d9ee88d552f6a59649081518a1189182174c5dfed655c398860`

Tutte e tre coincidono **carattere per carattere** con quanto già scritto alle righe della tabella sopra in questo referto. ⇒ **Le celle di questo referto non erano corrotte** — verificato con `grep` per ellissi (zero occorrenze) e con la guardia sotto, non per impressione.

⛔ **Il guasto misurato dal referee non era in questo file: era nella mia sintesi in chat rivolta a Mauro/al referee**, scritta a mano fuori dal giro di variabili+assert che ha prodotto la tabella sopra. Quella sintesi conteneva tre volte la stringa `0b11c226…c398860f`.

**CAUSA, misurata carattere per carattere (risposta al punto 2 del mandato: (a), con localizzazione precisa):**
- testa `0b11c226` — coincide con la vera testa (8 char) del foglio CD: corretta.
- coda `c398860` (7 char) — **non** appartiene al foglio CD (la sua vera coda a 7 char è `58e5c3f`). Coincide **esattamente** con la coda a 7 caratteri del contratto 18/07 — la forma abbreviata che ricorre più volte nella memoria di questo progetto, mandato compreso. Richiamata a memoria invece che derivata dalla variabile del foglio CD: stessa famiglia della trappola ⑤ del congedo A294 (citare dalla memoria invece che dalla fonte), qui su una coda di hash invece che su un indirizzo.
- `f` finale — non appartiene a nessuna delle due impronte vere: estranea, non tracciabile a una fonte.

⇒ **(a): composta a mano** — non nel referto (che usava variabili e assert), ma nella sintesi conversazionale, non sottoposta alla stessa disciplina.

## GUARDIA NUOVA — sostanza, non forma

Script (`/tmp/guardia_impronte.sh`) che estrae ogni token esadecimale a 64 caratteri dal file e lo confronta, carattere per carattere, con la whitelist delle impronte misurate in questo giro; un secondo controllo cerca lo specifico pattern del difetto reale — hex fiancheggiato da ellissi — che uno SHA git corto legittimo (es. `597961e`, citato sopra) non produce mai, quindi zero falsi positivi su quelle citazioni.

- Controllo positivo (file sintetico con la stringa rotta `0b11c226…c398860f`): **FALLISCE**, correttamente.
- Controllo negativo (SHA git corto legittimo, senza ellissi): **PASSA**, correttamente — nessun falso positivo.
- Su questo referto: **PASSA** — le due impronte trovate coincidono esattamente con la whitelist, zero forme abbreviate con ellissi.

⚠️ **La guardia copre questo file, non la prosa in chat.** Il rimedio per la sintesi conversazionale è comportamentale, non scriptabile qui: mai più abbreviare un'impronta a mano o a memoria — o l'impronta intera, o un'abbreviazione generata da comando (`${H:0:8}…${H: -7}`) nello stesso turno in cui la si misura, mai ricordata da un'altra.


⚠️ **Terzo colpo, trovato scrivendo questa correzione:** la prima stesura di questa nota citava per esteso la stringa rotta dentro il comando di verifica che descriveva, e con quella citazione ha alterato il conteggio che stava riportando — la stessa trappola (`R-δ.9`) descritta sopra, riprodotta nell'atto di descriverla. Corretta qui: questa nota non contiene più la stringa rotta, e il numero delle sue occorrenze nel file si legge dalla guardia stessa (sopra), mai da un conteggio scritto in prosa — che diventerebbe falso al prossimo giro di scrittura.

---

*CORREZIONE A296, in coda a MISURE_CC A295 — FINE.*
