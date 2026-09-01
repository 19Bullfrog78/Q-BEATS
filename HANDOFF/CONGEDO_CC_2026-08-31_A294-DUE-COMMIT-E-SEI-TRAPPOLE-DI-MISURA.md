# CONGEDO CC — A294 — 31/08/2026

Da: CC · A: il CC che apre dopo di me.

**Orologio**: 31/08/2026, **12:09 locale (UTC+2)** — da `date` di sistema di questa macchina.

Marcatura: **[M]** misurato da me ORA, alla fonte · **[R]** riportato da altri, non verificato da me · **[A]** giudizio mio.

---

## 🚨 LEGGI QUESTO PRIMA DI USARE UNA SOLA RIGA DI QUI SOTTO

⛔ **Questo documento è un PUNTATORE, non una FONTE.** Ogni cosa che dice va rimisurata prima di essere usata. Gli indirizzi di riga si spostano a ogni commit; i numeri scadono; le mie conclusioni possono essere sbagliate come quelle di chiunque.

⚠️ **Non è una cautela di forma.** In questa sessione ho ereditato un congedo che conteneva affermazioni imprecise e le ho scoperte solo rimisurando — e il referee dichiara di aver ereditato affermazioni **false** allo stesso modo. **Un congedo letto e creduto è il modo più veloce per propagare un errore.**

⛔ **Non copio qui lo stato del progetto** — versioni, HEAD, quali ticket sono aperti, quali cancelli chiusi. Quelle cose vivono nei canonici e **soltanto** lì: un congedo che le copia mente entro un'ora. Qui trovi **dove guardare**, non cosa c'è scritto.

---

## (a) ID — `A294`

**[M]** Cancello a sei gambe, misurato ORA: **0 su tutte e sei** (nomi su `C:` e `E:`, contenuto tracciato con `git grep`, contenuto su disco `C:` untracked compresi, contenuto su `E:` in `.md`/`.txt`, `git log --all --grep`).

✅ **Controlli positivi su tre ID bruciati in questa sessione** — `A293`, `A292`, `A290` rendono tutti `1` nome su `C:`, `1` su `E:`, `1` commit. **Le sonde vedono.**

⚠️ Il mandato mi avvertiva di non dare `A294` per buono. L'ho verificato: era libero.

---

## (b) COSA HO FATTO — due commit, e dove stanno le prove

**[M]** Perimetro della sessione: da `da7deb03c491f71a684207aad10f842837c3738a` (che ho trovato) a `597961eee7b4046815f580e406a40d2d96512a51` (dove chiudo).

```
597961eee7b4046815f580e406a40d2d96512a51   2026-08-31 11:55:04   (A293)
6f8e50e6e66833935d446e65b644e6d443969bda   2026-08-31 11:08:56   (A290+A291+A292)
```

**Entrambi doc-only, zero file sotto `ios_app/`, autore `Mauro Martintoni <di_tutto@icloud.com>`.** CI verde su entrambi: run `33376249503` e `33380012574`.

⛔ **Non riassumo il contenuto: sta nei messaggi di commit e nei diff.** I quattro diff sono in `HANDOFF/` su **entrambe** le gambe, e da `E:` sono arrivati su Drive:

```
DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A290_2026-08-30_CC.txt
DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A291_2026-08-31_CC.txt
DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A292_2026-08-31_CC.txt
DIFF_TRE-CODE-DICHIARATE_A293_2026-08-31_CC.txt
```

**[M]** Le sei stampe R-δ dei canonici (due giri × tre file) sono in `BOX5_Test/`, `BUGS_QBEATS/`, `LIBRO_MASTRO/` su `E:`, estratte **dal blob** con `git show`, e verificate su Drive alle 09:58 UTC.

⚠️ **Trappola di percorso, [M]: le cartelle di deposito su `E:` NON si chiamano come i file.** Sono `BOX5_Test/` e `BUGS_QBEATS/`, non `BOX5/` e `BUGS/`. Ci ho sbattuto: le avevo assunte per analogia e non esistevano.

---

## (c) LE SEI TRAPPOLE DI MISURA — è la parte che ti risparmia tempo

⛔ **Sono tutte mie, tutte di questa sessione, e cinque su sei le ho scoperte solo perché un controllo indipendente non tornava.** Scrivo il **meccanismo**, non il rimorso.

### ① La scrittura che tronca prima di fallire — ha azzerato un canonico

**[M]** `open(P, "wb").write(t.encode("utf-8"))`. Python valuta **`open(P,"wb")` per primo**, e quello **tronca il file all'apertura**. Se `encode()` solleva dopo, il file resta a **zero byte**. Mi è successo su `BUGS_QBEATS.md`: recuperato da HEAD e riapplicato, ma **se non fosse stato tracciato il lavoro sarebbe andato perso**.

Causa prossima: avevo scritto un'emoji in sorgente Python come **coppia surrogata** (`🚨`). Python non le ricombina, e `encode("utf-8")` le rifiuta. ⚠️ Lo stesso schema era negli script di `BOX5` e `LIBRO`: **è sopravvissuto solo perché quei testi non contenevano surrogati** — per caso, non per metodo.

✅ **Rimedio:** `dati = t.encode("utf-8")` come **riga a sé**, e si apre il file solo se non solleva; più un `assert` che rifiuta scritture sospettosamente corte. Per le emoji: `\U0001F6A8`, mai la coppia surrogata.

**Inciso** in `BOX5_QBEATS.md`, capitolo TASSONOMIA DEI DIFETTI DI MISURA, al commit `597961eee7b4046815f580e406a40d2d96512a51`.

### ② Lo zero che non era cecità della sonda ma distruzione del bersaglio

**[M]** Subito dopo ①, ho cercato una parola nel file e ho ottenuto **zero**. **L'ho letto come «il frammento non c'è» invece che come «il file non c'è».** L'ho scoperto due passi dopo, misurando i byte.

🚨 **Il controllo positivo canonico non lo smaschera**, ed è il punto: prova che la sonda **vede**, non che il bersaglio **esiste**.

✅ **Rimedio:** davanti a uno zero inatteso, misurare **prima** che il bersaglio esista — byte, dimensione — e solo poi leggere lo zero come assenza del contenuto cercato. **Inciso nella stessa sede di ①.**

### ③ La sonda che contava se stessa — e la quadratura diceva «TORNA»

**[M]** Ho inciso in `BUGS_QBEATS.md` una sonda `awk` che cerca il marcatore dei bloccanti. **Il suo stesso codice contiene la stringa che cerca.** Alla prima incisione ha contato **quattro righe proprie**.

🚨 **E la quadratura tornava lo stesso** — perché il difetto entrava in **entrambi** i membri della somma. Si è visto solo confrontando i **nomi** attesi, non i numeri.

⇒ **Una quadratura che torna non dimostra che i numeri siano giusti: dimostra che sono coerenti fra loro.** ⚠️ Questa conseguenza **NON è incisa in BOX5**: sta solo nella marcatura accanto alla sonda. **[A] Meriterebbe di stare nella tassonomia.**

✅ **Rimedio:** la sonda salta i blocchi di codice (guardia sui delimitatori di fence), e **si rilegge DAL DOCUMENTO**, mai dal file di lavoro.

### ④ Il pattern degenere — colto oggi, mentre scrivevo questo congedo

**[M]** Per contare i sorgenti con disco ≠ deposito ho scritto `git ls-files --eol | awk '$1!=$2'`. I due campi sono `i/lf` e `w/lf`: **come stringhe non sono mai uguali** ⇒ il filtro **rende il totale**, 281, non i divergenti.

La sonda corretta confronta la parte **dopo** il prefisso e rende **30** — che coincide col ticket `TD-eol-sorgenti-divergenti-disco-deposito`. Smascherata dalla quadratura sull'istogramma: `223 lf→lf` + `30 lf→crlf` + `28 -text→-text` = **281**.

⛔ **NON INCISO.** Trovato **dopo** il commit `597961e`, e il mandato A294 vieta modifiche ai canonici. **La classe generale (PATTERN DEGENERE) è già in BOX5; questa forma — confronto fra campi che portano un prefisso — no.** ⇒ **È lavoro per te, se il referee lo ratifica.**

### ⑤ Ho citato dalla memoria invece che dalla fonte — tre volte

**[M]** (a) la coda esatta di una riga di registro di `LIBRO`, che avevo in testa scambiata con quella di `BUGS`; (b) le cartelle di deposito su `E:` (vedi §b); (c) in una verifica d'integrità di tabella ho controllato la riga **371** invece della **366** — misuravo il posto sbagliato e il risultato sembrava buono.

✅ **Nessuna delle tre è arrivata al commit**, perché gli `assert` sul frammento esatto e la guardia le hanno fermate. **[A] È l'unica ragione: non me ne sono accorto da solo.**

✅ **Rimedio:** nessun indirizzo e nessuna stringa dalla memoria. `sed -n` / `grep -n` **prima** di ogni sostituzione, e un `assert` sul frammento letterale che stai per sostituire.

### ⑥ Le tabelle rotte — due volte, e la seconda è la più istruttiva

**[M]** (a) Quattro righe scritte in `LIBRO_MASTRO_QBEATS.md` Sezione 2 con **due colonne invece di sei**. (b) La voce di registro nuova in `BUGS_QBEATS.md` conteneva **caratteri separatori letterali fra backtick** — **riproducendo esattamente il difetto che quella riga stessa stava descrivendo**.

✅ Entrambe fermate dalla stessa guardia: **contare i separatori di ogni riga di tabella e confrontarli con le righe vicine**. La (b) è dichiarata dentro la riga stessa, perché succederà ancora.

---

## (d) COSA NON HO FATTO, E PERCHÉ

- ⛔ **Non ho verificato l'IPA** prodotta dalla CI: so che i job sono verdi, non ho aperto il binario. Vale per entrambi i commit.
- ⛔ **Non ho riparato le due voci di registro malformate del 30/07** in `BUGS_QBEATS.md` (separatore letterale nella prosa). Sono **preesistenti a `da7deb0`** e le ho verificate byte-identiche a HEAD dopo le mie scritture. **Dichiarate, non toccate**: sono righe di registro storiche, e la riparazione è un atomo suo.
- ⛔ **Non ho riparato i 30 sorgenti con fine-riga divergenti**: ticket aperto, e c'è una build collaudata su device da proteggere.
- ⛔ **Non ho rimosso il ramo `fix/a267-rientro-dalla-sua-sezione`** né toccato i 13 rami non-merged. ⚠️ **[M] Se ne rimisuri l'integrabilità, la prova valida è `git diff master fix/a267-rientro-dalla-sua-sezione -- 'ios_app/'` (vuota); la forma senza il filtro `-- 'ios_app/'` NON è più vuota e ti farà concludere il contrario.**
- ⛔ **Non ho letto alcun congedo del referee in questa sessione.** **[M]** All'ultima misura (12:09) il più recente restava quello del **30/08 delle 17:29**, cioè **anteriore** a tutto il mio lavoro — verificato su **due supporti**, `E:` per data e Drive per titolo, con controllo positivo superato (la sonda vede anche i congedi referee del 04/08 e del 01/08).
- ⛔ **Non ho deciso la convenzione di nome per un diff la cui data di produzione diverge dal soggetto.** Il caso si è presentato ed è **registrato come domanda aperta** in `LIBRO_MASTRO_QBEATS.md` Sezione 2, riga `2026-08-31`. ⚠️ La regola R-δ esistente è scritta per le stampe dei canonici, che hanno una riga `Versione:` — un diff non ce l'ha. **Non l'ho estesa da solo.**
- ⛔ **Una domanda aperta è registrata e NON risolta**: `CD-Q19` in `LIBRO_MASTRO_QBEATS.md` Sezione 4. Riguarda cosa facciano gli **altri** dispositivi quando uno solo rientra da un'interruzione. **Non inventarle una risposta: non ce l'ha nessuno.**

---

## (e) COSA MI È STATO DETTO E NON HO VERIFICATO

⚠️ Distinguo, perché tu non lo erediti come misurato:

- **[R]** La misura su device di Mauro del 30/08 (comportamento alla telefonata in entrata). **Non verificabile da qui**: non ho device. È la gamba su cui poggiano le quattro ratifiche di quel giro.
- **[R]** La riverifica del referee del commit `6f8e50e…` dal tarball pubblico. Le impronte che dichiara coincidono con le mie, **ma il confronto l'ha fatto lui**.
- **[R]** Che l'OK di Mauro ai due commit sia arrivato: mi è stato riferito dal referee, non l'ho letto io.
- **[M] parzialmente** — le fonti Apple citate nei canonici: **ho verificato io** la guida archiviata sulle sessioni audio (esiste, ed è leggibile: dice testualmente che l'interruzione è la disattivazione della sessione audio e che il salvataggio e la ripresa dello stato spettano all'app). ⛔ **Il documento moderno AVFAudio NON è verificabile da qui** — è una pagina a caricamento dinamico e rende solo il titolo. **Nei canonici è citato solo l'archiviato, di proposito.**

---

## (f) SE APRI DOPO DI ME

1. **Rimisura prima di fidarti**, di questo documento come di qualunque altro. Stato, versioni e HEAD si leggono **dalla testa dei canonici e da `git`**, mai da un congedo.
2. **Il lavoro di questa sessione è tutto committato e pushato, tree pulito sui tracciati.** Non c'è niente a metà, e non c'è niente in attesa di un mio ritorno.
3. **Prima di scrivere in un canonico:** conta gli apostrofi curvi e i separatori di tabella **prima e dopo**, e fai girare la guardia. Ti evita ⑥, e a me ha evitato di consegnare due documenti rotti.
4. **Prima di fidarti di uno zero:** verifica che il **bersaglio esista** (②), e che la sonda non stia **contando se stessa** (③) né **rendendo il totale** (④).
5. ⚠️ **Due cose sono note e non incise, e sono il primo lavoro documentale disponibile se il referee lo vuole:** la conseguenza di ③ (una quadratura che torna non prova che i numeri siano giusti) e la forma di ④ (confronto fra campi con prefisso). **[A] Entrambe appartengono alla TASSONOMIA di `BOX5`.**

---

*A294-DUE-COMMIT-E-SEI-TRAPPOLE-DI-MISURA — FINE*
