# MISURE CC — A91, ANATOMIA DI `tmp_fix.ps1` (sola lettura)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: **il file NON è stato eseguito**, in nessuna forma, né in copia né in sandbox.
Non cancellato, non rinominato, non spostato. Zero modifiche sotto `ios_app/`, zero commit, zero push.
Scritture eseguite: **solo questo referto**, in `HANDOFF/` + propagazione R-δ.

Marcatura: **[M]** misurato ora da CC · **[I]** inferenza dichiarata come tale.

---

## AGGANCIO — A91 libero

**[M]** Nomi file, due supporti indipendenti, entrambe le casse: `A91` → **0** in `HANDOFF/` (repo) e
**0** in `…/FILE X CLAUDE.MD/HANDOFF/` (E:). Controllo positivo `A90` → **1** su entrambi.
Contenuti, forma a token (non nuda, per non ripetere il falso positivo di A90): `\bA91\b` → **0**
file; controllo positivo `\bA90\b` → **3** file. **Non collide.**

---

## ⓪ IL VERDETTO IN UNA RIGA

**[M] Non è un'arma dimenticata: è un cerotto committato insieme alla ferita, e non è mai stato
usato.** Lo script ripara una **corruzione di codifica** di `AudioEngine.swift` avvenuta il 07/04. La
riparazione è poi stata fatta a mano il giorno dopo, per un'altra strada, e lo script è rimasto lì.

⚠️ **E questo corregge la mia stessa roadmap**, §Fase 0.1 — vedi la sezione finale.

---

## ① COSA FA DAVVERO

**[M]** `tmp_fix.ps1` — 146 righe, **5 820 byte**, blob `060f5c7a488dba97cea81fd686c1641c6db1fbda`.

**Struttura, misurata riga per riga.** Solo **cinque** righe sono PowerShell eseguibile; le altre 141
sono un blocco di testo inerte:

| riga | cosa fa |
|---|---|
| 1 | `$content = @'` — apre una stringa letterale (here-string **a apici singoli**: niente interpolazione, niente esecuzione) |
| 2-142 | **il carico**: 141 righe di codice Swift, testo puro |
| 143 | `'@` — chiude la stringa |
| **144** | `[System.IO.File]::WriteAllText("$PWD\ios_app\QBeats\AudioEngine.swift", $content, [System.Text.Encoding]::UTF8)` |
| 145 | `Write-Host "--- VERIFICA FINALE ---"` |
| 146 | `Get-Content ios_app/QBeats/AudioEngine.swift | Select-String "offsets"` — rilettura di controllo |

**Cosa succederebbe se qualcuno lo lanciasse, in italiano piano:** sovrascriverebbe per intero
`ios_app/QBeats/AudioEngine.swift` con 141 righe di codice di aprile, buttando via le **3 079** righe
di oggi. Poi stamperebbe «VERIFICA FINALE» e rileggerebbe il file cercando la parola `offsets`, per
mostrare che la scrittura è andata a buon fine.

**[M] Quanti file tocca: UNO SOLO.** Un'unica operazione di scrittura in tutto il file, a `:144`. Le
altre righe che un grep di scritture cattura (`:81`, `:98`) sono **codice Swift dentro il carico**,
non comandi.

**[M] Guardie: nessuna.** Misurate una per una in tutto il file:

| controllo cercato | occorrenze |
|---|---|
| `Test-Path` · `Read-Host` · `Confirm` · `WhatIf` · `ShouldProcess` · `Copy-Item` · `backup` · `exit` | **0** ciascuno |
| controllo positivo `WriteAllText` | **1** |

Nessuna verifica di esistenza, nessuna richiesta di conferma, nessuna copia di sicurezza, nessuna via
d'uscita. `WriteAllText` non chiede e non avvisa: crea o tronca.

⚠️ **TRAPPOLA DI MISURA, che segnalo perché ci si cade in un secondo.** Un grep di `try` rende **5** e
di `catch` rende **2**, e sembrano protezioni. **Non lo sono:** stanno tutte **dentro il carico
Swift** (`do { try engine.start() } catch { … }`), cioè dentro il testo inerte. In PowerShell quel
file non ha **nessun** `try`/`catch`. Chi contasse i token senza guardare dove stanno concluderebbe
che lo script è protetto, e sarebbe il contrario del vero.

**[M] C'è però una condizione che ne limita la portata, e cambia il rischio — come chiedevi.**
Il percorso è `"$PWD\ios_app\QBeats\AudioEngine.swift"`: **relativo alla cartella corrente**, non
assoluto. Lanciato da qualunque posto che non sia la radice del repo, `WriteAllText` non trova la
cartella e **fallisce senza scrivere nulla**. Morde solo se qualcuno lo lancia **stando esattamente
nella radice del repo**.

---

## ② DA DOVE VIENE

**[M]** Un solo commit in tutta la storia. `git log --follow --diff-filter=A`:

```
COMMIT b047907b5d675f3666f431ff37cae171c98d5892
DATA   2026-04-07 14:15:46 +0200
AUTORE LiveHost Setup <setup@livehost.local>
MSG    feat: Implementazione AudioEngine Swift e UI base
```

**[M] `git log --follow` sul file rende quella riga e basta:** creato il 07/04, **mai più toccato**.
Quattro mesi e undici giorni.

**[M] Il fatto che spiega tutto: è nato nello STESSO commit che ha creato `AudioEngine.swift`.** Non
è uno script arrivato dopo per rimettere le mani su un motore già scritto: è arrivato **insieme** al
motore.

### Perché esiste — misurato, non supposto

**[M]** Ho confrontato il carico dello script (righe 2-142) con `AudioEngine.swift` **alla nascita**
(`b047907b`). Sono **lo stesso file**, con tre sole differenze:

| # | differenza |
|---|---|
| 1 | il file committato ha un **BOM** UTF-8 in testa, il carico no |
| 2 | il file committato ha `print("**ðŸ”´** [AudioEngine] Start fallito…")` — il carico ha `print("**🔴** [AudioEngine] Start fallito…")` (idem per la seconda `print`) |
| 3 | il file committato **non ha newline finale**, il carico sì |

`ðŸ”´` è l'emoji `🔴` scritta in UTF-8 e riletta come codepage ANSI: è **mojibake**, la corruzione
classica di PowerShell quando si scrive un file senza dichiarare la codifica.

⇒ **[M] Lo scopo dello script è ora leggibile dai fatti, non dal nome:** `AudioEngine.swift` era
stato scritto corrotto, e `tmp_fix.ps1` è lo script di riparazione, che riscrive il file **imponendo
`[System.Text.Encoding]::UTF8`** — cioè correggendo esattamente la causa. `tmp_fix` = «riparazione
temporanea», e la riparazione è **di codifica**. La riga 146 che rilegge cercando `offsets` è il suo
collaudo.

⇒ **[I]** La supposizione del referee — «attrezzo temporaneo dimenticato» — **regge alla misura**. Va
solo precisata: non è un attrezzo generico, è un cerotto per un guasto specifico e databile.

---

## ③ È MAI STATO ESEGUITO? — **NO. Misurato, non supposto.**

**[M] Tre prove indipendenti su 244 versioni** di `AudioEngine.swift` presenti nella storia.

**Prova 1 — l'output esatto dello script non compare mai.**
Versioni contenenti la stringa `🔴 [AudioEngine] Start fallito` (che è ciò che lo script scriverebbe):
**0 su 244**. Controllo positivo nella stessa forma, sulle stesse 244 versioni: contenenti
`AudioEngine` → **244 su 244**.

**Prova 2 — nessuna versione ha la lunghezza dell'output.**
Versioni con esattamente **141 righe**: **0**. La più corta di tutta la storia è la nascita a **140**
righe, la più lunga è **3 079**.

**Prova 3 — il file non si accorcia mai.** La crescita è monotòna dalla nascita:
140 → 149 → 165 → 176 → 187 → … → 3 079. **In nessun commit `AudioEngine.swift` torna indietro.**

**[M] E si vede anche COME fu riparato il mojibake davvero.** Al commit successivo, `ccf22722` dell'
**08/04**, il mojibake è già sparito — ma il file è a **149 righe** e l'emoji corretta è a **0**
occorrenze. Cioè: le due righe di `print` incriminate furono **riscritte o rimosse a mano**, non
ripristinate dallo script. Se lo script fosse partito, avremmo una versione da **141 righe con
l'emoji giusta**. Non esiste.

**[M] `AudioEngine.swift` a HEAD è integro:** 3 079 righe, blob
`11bdaf4e2b76f1d5aae68e5b32d8ef9dae8f02fa`.

⇒ **Dichiarazione netta, come chiedevi: mai eseguito.** Non è un «forse». Se fosse stato eseguito
anche una sola volta e poi il file fosse stato ricostruito, resterebbe una versione da 141 righe con
l'emoji corretta in mezzo alla storia: **non c'è**, su 244 versioni esaminate una per una, con
controllo positivo non nullo sulla stessa forma.

---

## ④ QUALCOSA LO RICHIAMA? — **NO**

**[M]** `git grep -n 'tmp_fix'` su tutto il repo tracciato → **zero occorrenze** fuori dal file
stesso. Nessun workflow CI, nessun altro script, nessuna documentazione, nessun commento nel codice.

**[M] Controllo positivo nella stessa forma:** `git grep 'ios_build'` → **3** file. La forma di
ricerca funziona.

**[M] Anche fuori dal controllo di versione**, `grep -rl 'tmp_fix'` su tutto l'albero rende **un solo
file**: `HANDOFF/ROADMAP_CC_2026-08-18.md`, cioè **il mio documento di oggi**. Nient'altro nel
progetto lo nomina, in quattro mesi.

⇒ **Toglierlo non rompe niente.** Misurato, non presunto.

---

## ⑤ COSA RESTA DOPO LA RIMOZIONE

**[M] Il repo è PUBBLICO**, verificato a fonte: `gh repo view` →
`{"isPrivate":false,"visibility":"PUBLIC","url":"https://github.com/19Bullfrog78/Q-BEATS"}`.

**[M] CONFERMO: `git rm` + commit NON toglie il file dalla storia pubblica.** Lo toglie
dall'albero di lavoro e da HEAD; il blob resta raggiungibile per sempre a chiunque conosca il commit.

**Controprova eseguita su un caso reale già avvenuto**, per non affermarlo a memoria:
`ios_app/QBeats/UI/LiveRootView.swift` è stato **cancellato** dal commit `bfc9228` il 31/07. Oggi,
diciotto giorni dopo, `git cat-file -p bfc9228~1:ios_app/QBeats/UI/LiveRootView.swift` restituisce
ancora le sue **22 righe** complete. ⇒ Lo stesso varrà per `tmp_fix.ps1` a `b047907b`.

**Cosa si può promettere a Mauro, quindi, e cosa no:**
- ✅ Si può promettere che nessuno se lo ritroverà più in un checkout, e che non potrà lanciarlo per sbaglio dalla radice del repo.
- ⛔ **Non** si può promettere che sparisca da GitHub. Per quello servirebbe una **riscrittura della storia** (`filter-repo`/BFG + force-push), che **cambia OGNI sha del progetto**.

⚠️ **[I] E su questo mi fermo e segnalo, perché è la conseguenza che nessuno ha nominato:** in questo
progetto gli sha **sono l'impianto di citazione dei canonici**. LIBRO, BUGS, BOX3, BOX5 e SCALETTA
citano commit a 40 caratteri come ancore di contenuto. Una riscrittura della storia
**invaliderebbe in blocco tutte quelle ancore**. ⇒ La riscrittura della storia **non va nemmeno messa
sul tavolo** per questo file: il rimedio sarebbe incomparabilmente più distruttivo del difetto.

**[M] Contenuto sensibile: nessuno.** Cercati in tutto il file: percorsi assoluti (`[A-Z]:\`) → 0
(l'unico percorso è `$PWD`-relativo) · `password` · `token` · `secret` · `key` → 0 · URL → 0 · nomi
di persona → 0. Le uniche occorrenze di `@` sono attributi Swift (`@objc`, `@unknown`) dentro il
carico. L'unica identità è nei **metadati del commit** (`LiveHost Setup <setup@livehost.local>`), non
nel corpo del file: toglierlo non cambierebbe quella comunque.

---

## ⚠️ CORREZIONE ALLA MIA ROADMAP — dovuta, e la faccio io

Mi hai invitato a dirlo se il file fosse più innocuo di come è stato descritto. **Lo è, e il primo a
descriverlo male sono stato io.**

La mia roadmap, Fase 0.1, lo mette fra le due cose **da fare oggi**, con questa motivazione: «file
tracciato nella radice di un repo pubblico che, se eseguito, sovrascrive `AudioEngine.swift` (3079
righe) con un prototipo di 142 righe». Ogni singolo fatto in quella frase è vero. **L'insieme è
fuorviante**, per quattro misure che allora non avevo fatto:

| | misura |
|---|---|
| 1 | **[M]** Non è mai stato eseguito in **quattro mesi e undici giorni** — 0 su 244 versioni. |
| 2 | **[M]** **Niente lo richiama**: zero riferimenti in tutto il repo. Non può partire da solo, non c'è nessun percorso automatico. |
| 3 | **[M]** Morde **solo** se una persona lo lancia a mano **dalla radice del repo**: il percorso è relativo. |
| 4 | **[M]** Toglierlo **non lo toglie dalla storia pubblica**, quindi il beneficio «repo pubblico» che avevo implicato **non si ottiene**. |

⇒ **Va comunque tolto** — è un file morto, dal nome fuorviante, che scrive sopra il file più
importante del progetto: tenerlo non porta nulla. Ma **non è urgente e non appartiene alla Fase 0**.
È **igiene**, e la sua sede giusta è la Fase 5 o la Fase 6, insieme agli altri debiti di pulizia.

**Il rischio residuo reale, dichiarato per quello che è:** che una persona — o un agente — apra la
radice del repo, veda un file chiamato «fix», lo lanci per curiosità e perda l'albero di lavoro (non
la storia: `git checkout` recupererebbe tutto). È basso, ed è **conditionale a un gesto umano
deliberato**.

**[I] Una nota che vale più della rimozione stessa:** se anche fosse eseguito, il danno sarebbe
**interamente recuperabile** con `git checkout -- ios_app/QBeats/AudioEngine.swift`, perché il file è
tracciato e pulito. La perdita sarebbe di secondi, non di lavoro. Questo abbassa la severità di un
gradino ancora, e nella roadmap non l'avevo scritto.

---

## RIEPILOGO

| # | domanda | risposta misurata |
|---|---|---|
| ① | cosa fa | riscrive **un solo** file, `AudioEngine.swift`, senza alcuna guardia; 5 righe eseguibili su 146; percorso **relativo**, quindi morde solo dalla radice del repo. ⚠️ i `try`/`catch` che si contano sono **codice Swift inerte**, non protezioni |
| ② | da dove viene | `b047907b`, **07/04/2026 14:15:46**, «LiveHost Setup», msg «feat: Implementazione AudioEngine Swift e UI base». **Un solo commit, mai più toccato.** È lo **script di riparazione di un mojibake** del file appena creato — provato dal diff col blob di nascita |
| ③ | è mai stato eseguito | **NO.** 0 su 244 versioni con l'output esatto (positivo 244/244) · 0 versioni da 141 righe · crescita monotòna 140→3079 · il mojibake fu riparato a mano l'08/04 per altra via |
| ④ | qualcosa lo richiama | **NO.** Zero riferimenti nel repo (positivo `ios_build`→3). L'unica menzione in tutto il progetto è la mia roadmap di oggi |
| ⑤ | cosa resta dopo | il blob **resta pubblico per sempre** (controprova su `LiveRootView.swift`, cancellato il 31/07 e ancora leggibile). Nessun contenuto sensibile nel file. ⛔ La riscrittura della storia **non è un'opzione**: invaliderebbe tutte le ancore-commit dei canonici |

**Correzione alla roadmap: Fase 0.1 → declassato da «oggi/urgente» a igiene di Fase 5-6.** Il difetto
è reale, il rischio è basso e condizionato a un gesto umano, e il beneficio che avevo implicito
(«toglierlo dal repo pubblico») **non si ottiene** con `git rm`.

⛔ **Nessuna rimozione eseguita.** Servono i due cancelli: il tuo assenso e l'OK di Mauro.

---

*A91-TMPFIX-FINE*
