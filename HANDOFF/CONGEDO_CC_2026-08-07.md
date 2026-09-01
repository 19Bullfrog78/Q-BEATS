# CONGEDO CC — sessione 2026-08-07

**Emesso:** `2026-08-07T14:02:42Z` (locale `2026-08-07 16:02:42 +0200`).
Ora **misurata** con `date -u '+%Y-%m-%dT%H:%M:%SZ'` al momento della scrittura. Non dedotta dal
nome del file, non copiata dalla data dell'ID. È il difetto esatto che ho isolato in A75 su
A71/A72, e questa riga esiste per non ripeterlo.

**ID mandato:** A77. **Referti della giornata:** A75, A76.
**Scritto senza aver letto il congedo del referee.** Non l'ho chiesto e non mi è arrivato.
Se domani divergiamo su qualcosa, quella divergenza è un puntatore utile — non un errore da
appianare in anticipo.

---

## 0. Marcatori di provenienza

Ogni affermazione di questo documento porta uno di questi tre marcatori. Un congedo senza
marcatori viene ereditato come fatto: in questo progetto è già successo.

- **[M]** = misurato da me oggi, con il comando indicato.
- **[R]** = riportato o asserito da altri (mandato, canonico, referto precedente), **non**
  verificato da me in questa sessione.
- **[I]** = mia inferenza a partire da misure. Può essere sbagliata anche se le misure sono giuste.

---

## 1. Dove va questo file — e un buco documentale

**[M] Nessuna regola scritta stabilisce dove vanno congedi e referti.** Misurato a fonte sui due
canonici che potrebbero contenerla:

- `BOX3_QBEATS.md` a HEAD → occorrenze di `CONGEDO` = **0**, di `congedo` = **0**.
  Controllo positivo nella forma identica sullo stesso blob: `HANDOFF` = **26**. La forma cerca.
- `LIBRO_MASTRO_QBEATS.md` a HEAD → `congedo` = **13**, ma **nessuna** è una regola di
  collocazione: tutte e 13 parlano del **congedo tastiera Q20** (funzione di UI). Le 3 occorrenze
  `referto … HANDOFF` sono **citazioni** di referti per percorso, non prescrizioni.

**[M] La collocazione è quindi PRASSI OSSERVABILE, non regola.** Misurata su due supporti con
ricerca esaustiva (nessun `-maxdepth`): esistono 4 congedi, **con lo stesso identico set di nomi**
in `HANDOFF/` nel repo e in `E:\…\FILE X CLAUDE.MD\HANDOFF\` — `CONGEDO_CC_2026-08-05.md`,
`CONGEDO_CC_2026-08-06.md`, `CONGEDO_REFEREE_2026-08-01.md`, `CONGEDO_REFEREE_2026-08-04.md`.
Su tutto E: non esiste **nessun** congedo fuori da quella cartella.

**[I] Applico la prassi** e deposito in entrambi. **Ma lo dichiaro come buco:** è il terzo buco
documentale della stessa famiglia trovato oggi (gli altri due: BOX5 e SCALETTA in A76). La
`LISTA-TARGET ESPLICITA per documento` di `BOX3:397-401` copre **solo** BUGS, LIBRO e BOX3 —
tutto il resto vive di consuetudine.

⚠️ **Trappola di percorso, da sapere prima di cercare:** il mirror non è
`E:\…\Q-BEATS\HANDOFF\` (non esiste) ma `E:\…\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\`.
Ci sono cascato io per primo, all'apertura di questa sessione.

---

## 2. Stato a chiusura

**[M]** Tutto in questa sezione è misurato adesso.

```
HEAD          = 2960f089225b3c80cf56cb839fde871cf9738b3d
origin/master = 2960f089225b3c80cf56cb839fde871cf9738b3d
remoto vero   = 2960f089225b3c80cf56cb839fde871cf9738b3d   (git ls-remote, non il ref locale)
branch        = master
```

`git status --porcelain=v1`: **191 righe, tutte `??`**, **zero** righe non-`??`.
`git status -- ios_app/` → vuoto. Nessun file tracciato modificato in tutta la giornata.
(Le 191 righe erano 189 in apertura: +1 referto A75, +1 referto A76. Questo congedo porterà a 192.)

### I cinque canonici a HEAD

| documento | versione dichiarata (verbatim) | blob OID | byte | righe | CR blob | CR disco |
|---|---|---|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | `**Versione:** 54 (06/08/2026)` | `f7cd8085023ef0382e8c26e81b802d2a6e3b3274` | 259953 | 509 | 0 | **509** |
| `BUGS_QBEATS.md` | `**Versione:** 50` / `**Ultima modifica:** 2026-08-04` | `2598ae0288aefc29ac3d29c8b2e3b33e4057bb82` | 283858 | 1039 | 0 | **0** |
| `BOX3_QBEATS.md` | `BOX3 V99 — 2026-07-22 (AUTOPORTANTE)…` | `490d6d9b38c355dc53ddc9b31431f9a858f2b342` | 89457 | 803 | 0 | 0 |
| `BOX5_QBEATS.md` | `**Versione:** V28 — 28/07/2026` | `21b23d621ac224c759b53d813196058483e3b056` | 57158 | 596 | 0 | 0 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | `**Versione:** 8 (06/08/2026) · …` | `580e8f3bebc76a2cace02d8e8505aa2ff028fe23` | 44101 | 342 | 0 | 0 |

CR sempre con `tr -cd '\r' | wc -c`, mai con `grep -c $'\r'`.
**Le due righe in grassetto sono il reperto centrale della giornata** — vedi §6.1.

---

## 3. Cosa ho fatto oggi

### A75 — ricognizione R1 + verifica verbatim ⟦S5x⟧ + estrazione canonici

**[M] Verificato il cablaggio ⟦S5x⟧ leggendo i file, non i diff.** Prima però ho misurato **da
quale faccia** stavo leggendo: `FineSetlistView.swift` ha disco == blob (leggibile dal disco),
`LiveView.swift` ha disco ≠ blob (466 CR) — ho provato che la differenza è **solo** di fine-riga
(`blob | tr -d '\r'` e `disco | tr -d '\r'` rendono lo stesso sha256) e ho letto **dal blob**.

Esiti: `FineSetlistView` ha esattamente due proprietà; `onBackToShows: () -> Void` a `:17`
**senza alcun default** (ometterla è errore di compilazione, non un bottone morto silenzioso);
l'ordine a `LiveView:161-162` è `session.playbackState = .stopped` **prima**, `onExit()` **dopo**;
RESTART SETLIST a `:31` è ancora inerte (corpo = solo un commento); `4e4c2411` è `+30/−2`
(11/1 + 19/1) esattamente su quei due file; `SetlistRunner(` = **0** occorrenze con controllo
positivo `SetlistRunner` = 18 — a HEAD il runner non è mai costruito.

**[M] Estratti i cinque canonici dal blob** (`git show HEAD:<path>`, mai dal disco) e verificati a
tre coppie ciascuno (sha256, byte, CR) contro il blob. Tutti e cinque OK.

### A76 — rientro nel regime dei percorsi

**[M] Due file spostati** (`mv`, non copia), verificati contro il blob **dopo** lo spostamento:
`LIBRO_MASTRO_QBEATS_V54_2026-08-06_2960f08.md` → `LIBRO_MASTRO\`;
`SCALETTA_v8_2026-08-06_2960f08.md` → `HANDOFF\`. Entrambi sha256/byte/CR identici al blob.

**[M] Tre file rimossi** — operazione distruttiva, e queste sono le protezioni che ho messo:

1. **Rimisura immediatamente prima.** Non ho riusato le impronte del giro precedente: ho
   ricalcolato il sha256 del gemello a destinazione nella stessa operazione che precedeva la
   rimozione. Tutti e tre identici → rimossi. Se uno fosse diverso, non avrei rimosso.
2. **Verifica di collisione prima di ogni `mv`.** Entrambe le destinazioni erano libere sul nome:
   nessun rischio di sovrascrittura silenziosa.
3. **Manifest sha256 prima/dopo** di entrambe le cartelle di destinazione, confrontati con `diff`:
   **zero righe rimosse o cambiate**, esattamente **+1 riga** per cartella (19→20 in
   `LIBRO_MASTRO\`, 274→275 in `HANDOFF\`). È la prova che nessun preesistente è stato toccato,
   in nessuna delle due direzioni.
4. **Cartella non cancellata.** `PROGETTO_CLAUDE_2026-08-07\` è stata **svuotata**, non rimossa:
   la rimozione è decisione di Mauro.

**[M] Verificata la convenzione del nome contro la regola scritta.** Ho camminato la storia
commit-per-commit (`git log --reverse` + `git show <c>:<path>` a ogni tappa): `2960f089` è il
commit che ha **introdotto** sia LIBRO v54 (53→54) sia SCALETTA v8 (7→8). Coincide con «ultimo
commit» usato in A75 — i nomi erano giusti, per fortuna, non per metodo. Vedi §5.3.

---

## 4. Dove mi sono fermato, e perché

Due volte. Le scrivo entrambe perché è la parte che serve di più alla prossima sessione.

### 4.1 — Mandato A76 arrivato troncato

**[M] Il testo si interrompeva a metà frase: «1.3 Dichiara la».** Mancavano il resto del punto 1
e le sezioni che governavano le scritture — fra cui una **rimozione di file**.

**Cosa ho rifiutato di fare:** eseguire (a) e (b). Non ho ricostruito l'intenzione del referee,
non ho «indovinato» le sezioni mancanti, e in particolare non ho cancellato nulla su un mandato
di cui non vedevo la fine.

**Cosa ho fatto invece:** ho eseguito tutto ciò che era **completamente specificato e in sola
lettura** — l'aggancio e il punto 1 per intero — così che la ripartenza non ripartisse da zero.

**Cosa è successo dopo:** il referee ha riemesso il mandato **integrale**, con in testa un
controllo di integrità esplicito («questo mandato termina con FINE MANDATO A76; se non la vedi,
fermati»). **[I] La fermata ha prodotto una regola di forma nuova che ora protegge tutti i
mandati successivi** — A77 l'ha portata anch'esso. Questo è il rendimento vero di una fermata:
non aver evitato un danno, ma aver cambiato la procedura.

### 4.2 — `CC MEMORIA\` non è un mirror di LIBRO (A76 §3.1)

**[R]** La regola `BOX3:399-400` dice, verbatim: «LIBRO = 2 mirror (`CC MEMORIA\`,
`LIBRO_MASTRO\`) + snapshot referee».

**[M] Misurato a fonte cosa contiene davvero `CC MEMORIA\`:** **un solo file**, `MEMORY.md`,
27 570 byte, mtime `2026-06-19 09:48`. Ne ho letto l'incipit: è un «Memory Index» di **un altro
sistema** (memoria di CC su TD#17, Bug 1, fronti aperti di giugno), che cita persino un
organigramma di squadra superato — «Lavoro a 3: Mauro · CD · CC (codice **+ referee**, = io in
questa chat)», cioè il modello **precedente** a quello attuale a 3+1 con referee separato.
**Nessuna** delle 54 versioni di LIBRO è mai stata lì.

**Cosa ho rifiutato di fare:** depositarci dentro LIBRO v54. Avrebbe significato introdurre un
file estraneo in una cartella che serve ad altro, solo per far tornare formalmente una regola.

**[I] La mia lettura:** non è un'esecuzione mancata, è **la regola scritta a essere stale**. La
stessa frase di `BOX3:399` dichiara `CC MEMORIA\` mirror anche di **BUGS**, e neanche lì il
contenuto corrisponde. Una regola che indirizza a una destinazione sbagliata è peggio di una
regola assente: la prima volta che qualcuno la esegue alla lettera, sporca una cartella e crede
di aver chiuso il giro.

---

## 5. I miei errori

Non quelli altrui. Quelli che nessuno ha notato valgono il doppio, e ce n'è uno.

### 5.1 — Falso allarme sul mirror E:, in apertura di sessione

Verificando il congedo del 06/08 ho annunciato **«⛔ Primo reperto duro: il mirror E: non ha il
file»**. Era **falso**. Il file c'era: avevo assunto io il percorso `E:\…\Q-BEATS\HANDOFF\`, che
non esiste, invece di `E:\…\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\`.

**Causa:** ho costruito il percorso per composizione plausibile («mirror + nome cartella») invece
di misurarlo. **Aggravante:** la mia prima ricerca su E: usava `-Depth 3`, cioè esattamente la
forma di falso-zero già censita in questo progetto. Mi sono corretto con una ricerca esaustiva —
ma la correzione è arrivata **dopo** aver già scritto «reperto duro» in chat. Il difetto non è
l'ipotesi sbagliata: è averla annunciata come reperto prima di averla falsificata.

### 5.2 — In A75 ho cercato il bersaglio all'indirizzo sbagliato

Per il punto 2.3(c) dovevo trovare dove `LiveView` costruisce `FineSetlistView`. Sono andato
**direttamente alle righe 380-402**, perché erano gli indirizzi che il congedo del 06/08 citava
per un *altro* debito (`sectionHold`). La costruzione era a **:160**. Ho dovuto rileggere.

**Causa:** ho usato un numero di riga letto in un documento come se fosse una mappa del file.
Costo basso (un giro), ma è la stessa famiglia del §5.3: fidarsi di un indirizzo di provenienza
documentale invece di localizzare il bersaglio.

### 5.3 — ⚠️ Quello che nessuno mi aveva chiesto di verificare: ho eseguito un mandato senza misurarlo contro la regola scritta

In A75 il mandato prescriveva di nominare i file estratti con «sha7 dell'**ultimo commit** che ha
toccato quel file». L'ho applicato. **[M] Ma `BOX3:794-796` prescrive testualmente il commit
INTRODUTTIVO** — «nome per-versione ancorato al commit **INTRODUTTIVO**» — e quella riga era in un
canonico che **avevo appena letto e citato io stesso** nello stesso referto.

Me ne sono accorto solo il giro dopo, leggendo la stessa riga per un'altra ragione. I nomi erano
comunque corretti (i due commit coincidono, §3), quindi **non c'è stato danno — ma non per merito
del metodo**. Se in mezzo ci fosse stato un commit che tocca il file senza bumparne la versione,
avrei prodotto due nomi sbagliati e li avrei dichiarati verificati.

**[I] La regola che ne ricavo, e che vorrei sopravvivesse a questo congedo:** un mandato non è una
fonte. Quando prescrive una forma che un canonico già norma, va **misurato contro il canonico
prima di eseguirlo**, non solo eseguito bene. Ho fatto verifica-a-fonte su tutto il contenuto e
zero verifica-a-fonte sulla procedura che mi era stata data.

⚠️ Questo è anche l'unico punto in cui, con l'ordine giusto delle operazioni, avrei potuto
evitare la mezza giornata persa: la stessa lettura che smentiva la convenzione del nome stava a
sei righe da quella che descriveva il regime delle cartelle.

---

## 6. Cosa ho trovato che nessuno mi aveva chiesto

Tutto questo è emerso misurando altro. Se non lo scrivo io, non lo scrive nessuno.

### 6.1 — BUGS **non** ha due facce, e il claim canonico è sbagliato **nella causa**

**[R]** `BOX3 V99 (g)(1)` afferma: «su file a **due facce** (CRLF disco / LF blob: **LIBRO e
BUGS**) non si usa un editor».

**[M] Misurato:** LIBRO ha CR disco = 509 (due facce, claim confermato). **BUGS ha CR disco = 0**:
una faccia sola, disco == blob al byte. Il claim è **smentito su BUGS**.

**[M] E la causa invocata non regge:** `.gitattributes` a HEAD copre `HANDOFF/**`, `DESIGN/**`,
`BOX3_QBEATS.md`, `BOX5_QBEATS.md` con `-text` — **LIBRO e BUGS non ci sono**. Entrambi
`text: unspecified`, entrambi sotto lo stesso `core.autocrlf = true`. Stesso attributo, facce
diverse.

**[I] Lettura:** la copia di lavoro di BUGS è stata riscritta da uno strumento che emette LF,
dopo l'ultimo checkout. **[M] E l'asimmetria è invisibile agli strumenti abituali:** `git diff` è
**vuoto** su tutti e cinque i canonici, perché git normalizza in lettura. Si vede solo sui byte
grezzi.

**Conseguenza operativa:** la regola `(g)(1)` oggi si applica a LIBRO ma **non** a BUGS. Chi
scrivesse su BUGS assumendo CRLF ci inietterebbe CR che ora non ci sono. **Non l'ho riallineato:
è una decisione, non una misura.**

### 6.2 — La stessa asimmetria esiste dentro `ios_app/`

**[M]** `LiveView.swift` → disco ≠ blob (466 CR, faccia CRLF). `FineSetlistView.swift` → disco ==
blob (CR 0). Stesso fenomeno del §6.1, nel codice. **[I]** Chiunque legga un file di `ios_app/`
dal disco e ne citi l'impronta senza dichiarare la faccia sta citando un numero che non
corrisponde al blob.

### 6.3 — La propagazione R-δ del 06-07/08 non era mai stata completata

**[M]** LIBRO v54 e SCALETTA v8 non avevano **alcun** omonimo su E: prima di A76 (ricerca
esaustiva). La consegna del giorno precedente si era fermata al commit. Ora è chiusa per
SCALETTA, **parziale per LIBRO** (§8).

### 6.4 — Il deposito a nome fisso della SCALETTA su E: è **stale**

**[M]** `E:\…\HANDOFF\SCALETTA_ATOMI_S6_2026-07-10.md` — il percorso che la riga 12 del documento
indica come proprio deposito — ha sha256 `91e42123d2ef…`, **byte-identico alla stampa v7**, non al
blob v8 (`23665ddfa7a3…`). mtime `2026-08-04 15:16:13`, precedente al commit che ha introdotto v8.
**Non l'ho toccato:** non era fra le scritture autorizzate. Ma la riga «Depositato in», letta alla
lettera, oggi indica un deposito non aggiornato.

### 6.5 — `4e4c2411` ha **tre** run CI, non una

**[M]** Una su `master` (`31115280518`) e **due** `workflow_dispatch` sul branch
`ci-fiammifero/s5x` (`31114985567`, `31114970791`). Tutte `success`. Il branch-fiammifero ha
lasciato traccia in CI: chi conta le run per commit deve aspettarsele.

### 6.6 — A73 e A74 non esistono

**[M]** L'assunzione dichiarata nel mandato A75 («ieri si è arrivati ad A73, forse A74») è
**falsa** su entrambi i supporti e in entrambe le forme di ricerca. L'ultimo ID emesso era **A72**.
La sequenza reale ha già altri buchi (manca A60, manca A63).

### 6.7 — L'indirizzo `:393` del congedo precedente etichetta la guardia, non l'`asyncAfter`

**[R]** Il congedo 06/08 riga 106 scrive: «`LiveView.swift:390` lo alza; l'`asyncAfter` a `:393`
lo riabbasserebbe».
**[M]** A HEAD: `sectionHold = true` è a `:390` (esatto); l'`asyncAfter` è a `:392`; la guardia
`if case .stopped = session.playbackState` è a `:393`; `sectionHold = false` è a `:394`.
**[I]** L'indirizzo `:393` è **giusto** e punta alla guardia — che è il cuore della diagnosi, e la
diagnosi regge. È l'**etichetta** a essere imprecisa. Difetto cosmetico, ma in un progetto che
indirizza per riga vale la pena saperlo.

### 6.8 — Il controllo positivo prescritto può essere esso stesso zero

**[M]** In A75 il mandato prescriveva `S5` come controllo positivo per una riga di zeri. Su
**BOX5** rende **0**: il controllo non validava niente. Rifatto con stringhe realmente presenti
(`BOX5`=15, `Q-Live`=39, `QL-SHOWS`=26). Lo zero originale era comunque un fatto valido, e il file
stesso lo spiega alla riga 12 («Nessun nome d'atomo nel capitolo»).

---

## 7. Trappole e falsi-zero — nuovi e riconfermati oggi

| # | forma che MENTE | forma CORRETTA | controllo che discrimina |
|---|---|---|---|
| 1 | ricerca su E: con `-Depth N` / `-maxdepth N` | ricerca esaustiva senza limite | cercare un file **noto presente** con la stessa forma |
| 2 | percorso mirror composto per plausibilità (`<root>\HANDOFF\`) | `find` sul nome file | il vero percorso ha un livello in più: `FILE X CLAUDE.MD\` |
| 3 | `gh run list --commit <sha7>` → `[]` con exit **0** | sempre sha a **40** | stesso comando su un commit con CI nota |
| 4 | `grep -c $'\r'` per contare i CR | `tr -cd '\r' \| wc -c` | confronto con `byte disco − byte blob` |
| 5 | `git diff` per accorgersi di una divergenza di fine-riga | sha256 **disco vs blob**, separati | `git diff` è **vuoto** anche quando le facce differiscono |
| 6 | **[nuovo]** il controllo positivo prescritto dal mandato | verificare che il controllo **non sia zero** | se rende 0, sceglierne un altro e dichiararlo |
| 7 | **[nuovo]** contare le occorrenze di una parola come prova di una regola | leggerle | 13 «congedo» in LIBRO = 13 volte «congedo **tastiera**» |
| 8 | **[nuovo]** un ID «libero» perché la ricerca per contenuto rende 0 | identificare **ogni** occorrenza | `A75` compariva dentro un sha256 (`…CFFFA75340FEF`) |

---

## 8. Cosa resta aperto — con la mia priorità, che non è quella del referee

Ordino per **rischio sul palco**, non per ordine di apparizione nei mandati.

**1. 🚨 `TD-fineshow-bottoni-morti` è miscategorizzato, e l'ho misurato oggi.**
**[M]** A HEAD il ticket è a `BUGS_QBEATS.md:319` e il suo titolo dice testualmente
`(🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO)`. Ma `## ⚠️ 1.2 — Non bloccanti palco` inizia a `:148` e
`## 📦 1.3` a `:373`: la riga 319 cade **dentro §1.2**. Il tracker si contraddice al proprio
interno. **[R]** È aperto dal 04/08 e riportato in ogni handoff da allora. **[I] Questa è la mia
priorità numero uno**, sopra tutto il lavoro documentale: è l'unico punto in cui un documento
sbagliato può far saltare un concerto, perché chi legge §1.2 legge «non urgente».

**2. ⛔ ⟦S5x⟧ e ⟦S5a⟧ sono CI-verdi e NON validati su device.**
**[M]** CI verde confermata (`31115280518`, `31163491887`). **[R]** Il gate device di Mauro non è
mai stato fatto. **[I]** «CI-verde ≠ chiuso» è la regola del progetto e qui non è stata onorata da
due atomi consecutivi. Nessuna quantità di misure documentali sostituisce quel gate.

**3. La regola `BOX3:399` va riparata, non solo eseguita.** Vedi §4.2. **[I]** La metto alta
perché è una regola che **attivamente indirizza male**: chi la esegue alla lettera crede di aver
completato una propagazione R-δ e non l'ha fatto.

**4. LIBRO v54 — propagazione R-δ parziale.** **[M]** Fatta `LIBRO_MASTRO\`. **Non fatte:**
`CC MEMORIA\` (bloccata di proposito, §4.2) e «snapshot referee» (canale non raggiungibile da
questa sessione).

**5. Le tre decisioni di CD sul freeze consolidato restano [R].** **[R]** Trascritte dal mandato,
**mai verificate contro i due `.html`**. **[M]** Quei due file (`…rev2-BUONA.html`,
`…rev3-NORMATIVA.html`) sono in git da `f0a4462b` e **non sono mai stati aperti da CC** — né ieri
né oggi.

**6. `f0a4462b` non ha alcuna run CI.** **[M]** Riverificato oggi con sha a 40. I due commit sono
stati pushati insieme, quindi solo la punta ha innescato la build: il commit di deposito del
freeze non è mai stato compilato da solo. Doc-only, quindi innocuo — ma detto, non dedotto.

**7. Buchi documentali di collocazione: BOX5, SCALETTA, congedi/referti.** Tre destinazioni che
vivono di prassi. La `LISTA-TARGET` copre solo BUGS/LIBRO/BOX3.

**8. `PROGETTO_CLAUDE_2026-08-07\` è vuota ma esiste.** La rimozione è decisione di Mauro.

**9. La faccia di BUGS.** Da decidere: riallineare a CRLF o incidere la differenza (§6.1).

---

## 9. Dove non sono d'accordo col referee

Lo scrivo perché un congedo che non contraddice mai non serve a niente.

**9.1 — Sull'ordine delle priorità.** Il referee ha impiegato due mandati su tre della giornata
sul regime dei percorsi. **[I] Non è la cosa più rischiosa che abbiamo aperto.** Un canonico nella
cartella sbagliata si sposta in dieci minuti — e infatti l'abbiamo fatto. Un ticket bloccante-palco
archiviato sotto «non bloccante» (§8.1) resta invisibile finché non morde, ed è lì dal 04/08.
Se domani si sceglie un solo fronte, il mio voto è quello, non il regime documentale.

**9.2 — Sulla creazione della cartella fuori regime.** In A75 avevo segnalato **a fonte** che
`PROGETTO_CLAUDE*` non esisteva e che le copie vivevano in cinque sottocartelle tematiche. Il
mandato è stato eseguito lo stesso. Il referee l'ha riconosciuto apertamente in A76 — **[I]** ma la
lezione operativa non è «il referee ha sbagliato»: è che **la mia segnalazione era in fondo a un
referto lungo**, dentro un punto 3.1 fra molti altri. Un rilievo che deve fermare un'esecuzione va
messo **in testa e da solo**, non annegato in una consegna riuscita. Su questo il difetto è anche mio.

**9.3 — Sulla riemissione con lo stesso ID.** A76 è stato riemesso con lo stesso ID dopo il
troncamento. **[I] Ha funzionato ed era la scelta giusta** (non c'erano artefatti da cercare,
perché non avevo scritto nulla) — ma regge **solo** perché la fermata era stata pulita. Se avessi
eseguito metà mandato, oggi avremmo due A76 diversi con lo stesso ID e nessun modo di distinguerli
a posteriori. Vale la pena scriverlo come condizione, non come precedente generale.

---

## 10. Cosa NON ho fatto — dichiarato, non inferito a posteriori

- **Non ho letto il congedo del referee.** Non l'ho chiesto e non mi è stato passato.
- **Non ho aperto i due `.html` del freeze consolidato.** Le tre decisioni di CD restano **[R]**.
- **Non ho verificato su device nulla.** Nessun gate device è stato eseguito oggi.
- **Non ho depositato LIBRO v54 in `CC MEMORIA\`** né nello «snapshot referee» (§4.2, §8.4).
- **Non ho toccato il deposito a nome fisso della SCALETTA su E:**, benché misurato stale (§6.4).
- **Non ho riallineato la faccia di BUGS** (§6.1).
- **Non ho aperto né modificato alcun ticket in BUGS.** **[M]** Il tracker non registra nulla di
  questo giro: occorrenze a HEAD di `S5a`=0, `S5b`=0, `S5x`=0, `FREEZE-CONSOLIDATO`=0, `4e4c2411`=0,
  `2960f089`=0 — con controllo positivo `S5`=16 sullo stesso blob.
- **Non ho cancellato `PROGETTO_CLAUDE_2026-08-07\`**, solo svuotata.
- **Non ho committato, non ho pushato, non ho fatto `git add`.** HEAD invariato tutto il giorno.
- **Non ho verificato le serrature d'ingresso di ⟦S5b⟧ oltre `SetlistRunner(`=0.** **[M]** Ho
  misurato che lo slot a `QLiveSession.swift:35` è `@Published private(set) var runner:
  SetlistRunner? = nil` e che non esiste alcuna costruzione sotto `ios_app/`. **Non ho cercato
  mutatori indiretti** (metodi che assegnino `runner` dall'interno del tipo): se qualcuno vuole
  quella garanzia, va misurata, non dedotta da questi due numeri.

---

**Fine congedo CC — 2026-08-07.**
Emesso `2026-08-07T14:02:42Z`. HEAD a chiusura `2960f089225b3c80cf56cb839fde871cf9738b3d`,
albero di lavoro pulito sui tracciati, nessun commit in tutta la sessione.
