# MISURE CC — A155-LIBRO-v58-COLLAUDO-DEVICE

**ID ricevuti e verificati: `A155` · `A156` · `A157`.**
Un lavoro solo in tre mandati: A155 ha inciso, A156 ha riletto, A157 ha misurato
e chiuso. Il referto porta il nome di A155 perche' il diff esiste gia' a quel
nome e i due devono stare insieme.
⚠️ **A156 e A157 rendono per CONTENUTO in questo file, non per nome.** Chi li
cerca con la sola sonda per nome non li trova: e' la cecita' strutturale nota.

Da: CC · A: referee, + Mauro · 21/08/2026

🔎 **Integrita' dei mandati: PASSA su tutti e tre.** A155: visti §0 §0bis §1 §2 §3
§4 §5 e `FINE MANDATO A155`. A156: visti §1 §2 §3 §4 e `FINE MANDATO A156`.
A157: visti §0 §1 §2 §3 §4 e `FINE MANDATO A157`. Nessun taglio.

⛔ **NESSUN COMMIT. Un solo file tracciato modificato: `LIBRO_MASTRO_QBEATS.md`.**

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. 🚨 UNA SECONDA SESSIONE CC ERA VIVA OGGI, E ME NE SONO ACCORTO PER CASO.**
**[M]** Aprendo la sessione ho letto la cartella `HANDOFF/` alle ~15:19; due minuti
dopo, rimisurando, e' comparso `MISURE_CC_2026-08-21_A151-...md`, scritto alle
**15:21:20**. Quella sessione ha poi prodotto **A152** (15:31) e **A153** (15:39).
⇒ **Il congedo che avevo in mano firmava «A149-FINE» ed era superato di due
mandati.** Nessun meccanismo me lo ha segnalato: l'ho visto perche' ho rimisurato
invece di rileggere. ✅ **Cura, poi diventata il §0bis di A155:** prima di
scrivere un byte, quattro cancelli — HEAD locale e remoto, mtime del file
bersaglio, working tree pulito, nessun file nuovo comparso.

**2. ⛔ IL MANDATO A150 PORTAVA UN ID GIA' BRUCIATO, E LA SOLA SONDA NUMERICA
NON BASTAVA A DIRLO.**
**[M]** `A150` rendeva **0 per nome** su entrambi i supporti e **4 per contenuto**.
Il conteggio da solo era ambiguo: quattro hit possono essere quattro menzioni.
**E' stata l'ispezione del contesto a decidere**, e ha trovato molto peggio di una
menzione: A150 era stato **emesso, annullato da Mauro, e aveva lasciato tre file
orfani** su `E:`, gia' censiti da A152 e in via di riparazione da A153.
⇒ **A150 annullato, sostituito da A155.** ⚠️ **Il numero non era la prova: il
contesto lo era.**

**3. ⛔ LA MIA RILETTURA IN CHAT SI E' CORROTTA IN TRANSITO, E IL FILE ERA
SANO.** **[M]** In A156, incollando la riga di Sez.6, ho scritto `«8/8**` dove il
file porta `«8/8»`. Il file **non** e' mai stato sbagliato: lo sha256 era
invariato e il gate di A157 lo ha dimostrato. ⇒ **Una rilettura passata attraverso
il modello non e' una prova sul file.** ✅ **Cura, che e' il §1 di A157:** si
ratifica su una **misura**, mai su una trascrizione. Una misura non si corrompe in
transito.

---

## §0 · GLI ID — sonda a due forme, due supporti, piu' contesto

**[M]** Perimetro documentale (`*.md`, `*.txt`), binari esclusi, confine di parola,
**e sempre un controllo negativo oltre a quello positivo.**

| ID | NOME repo | NOME E: | CONT repo | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| A150 | 0 | 0 | **4** | **4** | ⛔ **COLLIDE** — annullato |
| **A155** | 0 | 0 | **0** | **0** | ✅ libero, contesto vuoto |
| **A157** | 0 | 0 | **0** | **0** | ✅ libero, contesto vuoto |
| A148 | 1 | 1 | 4 | 4 | controllo positivo |
| A153 | 1 | 1 | 1 | 1 | controllo positivo |
| A194 / A192 | 0 | 0 | 0 | 0 | controllo **negativo** |

⛔ **Ispezione del contesto su A150 — le cinque righe che hanno deciso:**
`CONGEDO_..._SERA.md:120` lo dava «PROSSIMO LIBERO» (menzione) · `A151:4`
«trattato come **ANNULLATO**» · `A151:195` «A150 lo hai annullato tu» ·
`A152:158` «**TRE FILE ORFANI DEL MANDATO A150**» · `A153:85` «GLI ORFANI DI A150
— il gate prima della cancellazione».

⚠️ **[M] Un dato dai controlli positivi che vale come prova indipendente:**
`A155` rende **1 su C: e 0 su E:**. E' la firma di R-delta mai partita — il diff
di A155 esisteva solo sul disco di lavoro. Questo referto la chiude.

---

## §0bis · R2 — CHI TIENE LA PENNA. Il cancello che viene prima di tutto

**[M]** Misurato immediatamente prima di scrivere, tutti e quattro:

| cancello | esito |
|---|---|
| HEAD locale e remoto | `638b73835f7ac52fdcd01dd94dc23f81ce818b2d` = atteso ✅ |
| mtime del LIBRO | `2026-08-19 12:47:17.935634500 +0200` — invariato **al nanosecondo** ✅ |
| working tree / stage | tracciati puliti, stage vuoto ✅ |
| file nuovi in `HANDOFF/` dalle 18:27 | **nessuno**; l'ultimo restava A153 delle 15:39 ✅ |

⇒ **La sessione parallela era quiescente da quasi tre ore. Nessuna collisione.**

---

## §1 · LA PREMESSA — misurata prima di toccare

**[M]** Confini di Sezione **ricavati per contenuto a ogni misura**, mai riusati:
`grep -nE '^## Sezione'` ⇒ Sez.2 = righe **191–362**.

| verifica | reso | atteso |
|---|---:|---|
| `^\| 2026-08-18 \| \*\*FATTO, NON REGOLA` | **1** | 1 ✅ |
| `^\| 57 \| 2026-08-18 \|` | **1** | 1 ✅ |
| `^\*\*Versione:\*\* 57` | **1** | 1 ✅ |
| controllo positivo `^\| 2026-08-18 \|` | **6** | 6 ✅ |
| baseline Sez.2, righe `^\| 2026-` | **162** | 162 ✅ |

**[M] Due premesse che il mandato AFFERMAVA e che ho misurato invece di
accettare** — entrambe reggono: l'ancoraggio a riga **359** e' **davvero l'ultima
riga tabella della Sezione 2** (seguono riga vuota, `---`, `## Sezione 3`), e la
riga `**Edit author:**` **esiste** (riga 7), quindi la testata da sostituire e' di
tre righe e non di due.

**[M] Un cancello di forma che non era chiesto e che mi sono tenuto:** tutte e 162
le righe di Sez.2 hanno **esattamente 7 pipe**. La riga nuova doveva averne 7.

**[M] Un effetto collaterale dichiarato PRIMA di produrlo:** l'unica occorrenza di
`A122` nel LIBRO stava dentro la riga `Edit author:`. Sostituirla la cancella.
⇒ **Il referee ne ha preso atto e l'ha autorizzato** (A155 §2b): e' il
comportamento normale di quel campo, che si sovrascrive a ogni versione.

---

## §2 · LE MODIFICHE — tre, in un file solo

**[M] Metodo: uno script Python scritto come FILE e poi eseguito** — mai heredoc,
che si rompe su tabelle, backtick e apostrofi. **Lo script si nega la scrittura**
se una sola asserzione cade. Ha verificato, prima di toccare il file:

- il file e' **CRLF uniforme** (519 righe su 519) — verificato, non assunto;
- ognuno dei cinque ancoraggi e' **unico**;
- le tre righe di testata sono **consecutive**;
- **dopo** l'ancoraggio di Sez.2 non esiste nessun'altra riga tabella;
- la riga nuova ha **7 pipe**, la riga di Sez.6 ne ha **5**;
- **zero apostrofi tipografici** `U+2019` nel testo nuovo — il mandato usa solo
  l'apostrofo ASCII, e il transito attraverso il modello e' noto per alterarli;
- **zero lettere greche** — la trappola del refuso unicode a quattro cifre;
- **otto** marcatori `**TEST n**`;
- conteggio righe finale **+2** esatto.

Le modifiche sono state applicate **dal basso verso l'alto** (Sez.6, poi Sez.2,
poi testata) perche' gli indici non slittassero.

---

## §3 · IL CANCELLO SUL BERSAGLIO — non sulle mie operazioni

**[M]** Confini di sezione **ricavati di nuovo** dopo l'edit (Sez.2 = 191–**363**).

| # | misura | reso | atteso |
|---|---|---:|---|
| 1 | `A139` · `A144` · `TEST 8` · `NON ESEGUITO` | **3** ciascuno | ≥1 ✅ |
| 2 | righe Sez.2 `^\| 2026-` | **163** | 162+1 ✅ |
| 3 | `^\*\*Versione:\*\* 58` · `^\| 58 \|` | **1** · **1** | 1 · 1 ✅ |
| 4 | `^\*\*Versione:\*\* 57` | **0** | 0 ✅ (ctrl pos: `58` rende 1) |
| 4 | `^\| 57 \| 2026-08-18 \|` | **1** | 1 — **storia intatta** ✅ |
| 6 | righe totali | **521** | 519+2 ✅ |
| 6 | CR / LF su disco | **521 / 521** | CRLF preservato ✅ |

✅ **[M] LA TARATURA CHE MANCAVA, E CHE IL REFEREE AVEVA PREVISTO DOVE SI SAREBBE
CHIUSA.** In §1 avevo dichiarato uno **zero non tarato**: la forma `TEST [0-9]`
rendeva **0** in tutto il file, quindi non avevo dimostrato che la sonda vedrebbe
un «TEST N» se ci fosse. **Dopo l'edit la stessa forma rende 3.** ⇒ **La sonda e'
dimostrata funzionante, e lo zero di prima era vero.**

**[M] §3.5 — gate largo con lettura in contesto.** `7/7` e `8/8` compaiono in
**tre** righe: la 6 (testata), la 360 (Sez.2), la 518 (Sez.6). ⚠️ **Il mandato
diceva «solo dentro la riga nuova», al singolare: le righe nuove sono tre**, e
tutte e tre erano prescritte dal mandato stesso. **Nessuna riga preesistente le
contiene.** Divergenza dichiarata, non appianata.

**[M] §3.6 — natura del diff:** `--numstat` rende **5 aggiunte / 3 rimozioni**. Le
tre rimozioni sono **esattamente** le tre righe di testata. Nessun altro file
modificato.

**[M] Misure sulla riga inserita:** 2605 caratteri · 7 pipe · 8 marcatori `TEST` ·
**6 occorrenze di `**VERDE**`**, coerenti con i «sei verdi» che il mandato
dichiara · 0 apostrofi tipografici · i due sha a 40 corretti.

---

## §1 di A157 · IL GATE SUL MARKUP — passa interamente

**[M]** Nato dal sospetto che il mio `«8/8**` in chat fosse nel file.

| # | misura | reso | atteso |
|---|---|---:|---|
| (a) | `«8/8»` | **3** | 3 ✅ |
| (b) | `«8/8**` | **0** | 0 ✅ — ctrl pos `«8/8` = 3, **zero tarato** |
| (c) | `«7/7»` | **3** | 3 ✅ — ctrl pos `«7/7` = 3 |
| (d) | `**` in riga Sez.2 | **60** | pari ✅ |
| (e) | `**` in riga Sez.6 | **16** | pari ✅ |
| (f) | `**` testata righe 5·6·7 | **2 · 10 · 2** | pari ✅ |

**[M] Controllo di sanita' aggiunto da me:** 120 asterischi in Sez.2 = **esattamente
60 coppie**, **zero** sequenze `***` o piu'. Idem Sez.6: 32 = 16 coppie.
⇒ **Nessun grassetto aperto e non chiuso. Il file era gia' giusto: §2 di A157 non
si applica, non ho toccato niente.**

**[M] sha256 del LIBRO invariato fra le 19:09 e le 19:22:**
`7df3468b518bf0691f680aa51453fb277d9988ef1b016b0249e3248b4a86d114`.

---

## ⛔ COSA NON CREDERE — affermazioni dei mandati che ho SMENTITO alla fonte

**[M] 1. «A150 e' libero».** Falso: 4 hit per contenuto su due supporti, ID emesso
e annullato con tre file orfani. ⇒ Annullato, sostituito da A155.

**[M] 2. «A155 e' chiuso» (premessa di A156 §3.4).** Falso: A155 e' stato
**interrotto**. Il LIBRO era inciso e il diff generato, ma **il referto non
esisteva e R-delta non era mai partita.** Questo referto lo chiude.

**[M] 3. «La stesura precedente di A156 non e' mai stata inviata».** Falso: mi era
arrivata ed ero a meta' esecuzione. Aveva un **§4 diverso** — parlava di «una
seconda cartella `BUGS_QBEATS` in un ramo di Drive», non dei due alberi.
⚠️ **Il referee lo ha riconosciuto in A157.**

**[M] 4. «Su Drive esiste l'albero `FILE X CLAUDE.MD`» (A156 §4).** Non su
`I:\Il mio Drive\`. Cercato a profondita' 4 per `*FILE*CLAUDE*` e a profondita' 3
per `*CLAUDE*`: **zero**, con **controllo positivo** (`*LIBRO*` trova
`Qbeats/LIBRO_MASTRO`, quindi la sonda vede). Alla radice le cartelle Q-BEATS sono
**due**: `Qbeats` e `Qbeats_IN_CD`.
✅ **A157 ha ratificato la misura e spiegato la divergenza: quella cartella vive
sotto «Il mio computer», non sotto «Il mio Drive» — e' il backup della gamba E:,
non un terzo albero.**

**[M] 5. «Il congedo del 21/08 sera dichiara HEAD = `c46c0d4`».** Superato: HEAD e'
`638b7383`, e i commit della giornata sono **cinque**, non quattro. Il quinto
contiene il congedo stesso. ⚠️ Il congedo dichiarava l'autoriferimento per `A149`
**ma non per `A150`**, che pure citava nella propria tabella: ed e' proprio `A150`
quello che poi e' stato riusato.

**[M] 6. «F1 non e' mai partito».** Vero sui commit di oggi. ⚠️ **Ma il congedo non
diceva che le due run piu' recenti — 31/07 — sono entrambe FALLITE.** Interrogato
per ID `266323994`: quattro run in tutto, ultima **riuscita** il 25/04/2026.

---

## ⚠️ COSE CHE HO TROVATO E CHE NESSUNO CERCAVA

**[M] 1. Il regime dei congedi e' incoerente su un repo PUBBLICO.** I due congedi
del 21/08 sono **tracciati**; quelli del 05, 06, 07, 07-sera, 18, 19, 20 **e i due
del referee** (01/08, 04/08) **no**. ⇒ Chi legge il repo da GitHub vede la
giornata di oggi e nient'altro. ⚠️ **Non e' un dettaglio d'archivio: la riga che
ho appena inciso nel LIBRO esiste proprio perche' quel congedo non e' tracciato e
nessun canonico smentirebbe i due punteggi falsi.**

**[M] 2. Doppione di stampe su `E:`, e solo li'.** A151 ha stampato a `c46c0d4`
(15:15) e rifatto a `638b738` (15:19), ripulendo **C:** e **Drive** ma **non E:**,
che portava **sei** file dove gli altri due ne portavano tre. `cmp` dice che le due
serie sono **byte-identiche** ⇒ **il rischio e' confusione su quale caricare, non
contenuto sbagliato.** ⚠️ **[A] E' la stessa forma descritta nel congedo:** il
`cmp` sulle tre stampe dichiarate chiude verde e non puo' vedere le tre orfane
rimaste accanto. Un cancello sulle operazioni, non sull'obiettivo. **A152 e A153
li hanno poi censiti e trattati.**

---

## §4 · R-DELTA — le tre gambe

| gamba | destinazione |
|---|---|
| **C:** | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| **E:** | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |
| **Drive** | `I:\Il mio Drive\Qbeats\` — **radice**, coi fratelli di oggi |

⛔ **La destinazione su Drive e' la RADICE, non `Qbeats\HANDOFF\`.** Misurato: i
referti di oggi (A151, A152, A153) sono **tutti in radice**; `Qbeats\HANDOFF\`
porta materiale di fine luglio e inizio agosto piu' la sola stampa SCALETTA v11.
⚠️ **Il §4 di A155 diceva «cartella HANDOFF»: era sbagliato, e A156/A157 lo hanno
corretto sulla mia misura.** E' la trappola che A151 aveva segnalato: **due posti
che sembrano lo stesso, e chi propaga senza misurare finisce in quello morto.**

**Facce:** `HANDOFF/**` e' `-text` ⇒ LF, disco = blob. Il LIBRO nel working tree
resta **CRLF**: se ne servira' una stampa, va estratta dal blob con `git show`,
mai copiata dal disco.

---

## COSA NON HO FATTO — e lo dico

- ⛔ **Nessun commit, nessuno `git add`, nessun push.** Il LIBRO resta ` M`,
  modificato e **non** in stage.
- ⛔ **Nessun altro file tracciato toccato.** Solo `LIBRO_MASTRO_QBEATS.md`.
- ⛔ **Nessuna riga preesistente riscritta**, spostata o corretta: la sola
  riscrittura sono le tre righe di testata, esplicitamente autorizzate.
- ⛔ **Nessuna marcatura nella SCALETTA.** Decisione del referee, dichiarata: A139
  e A144 sono **mandati, non atomi**, e non hanno scheda. **Non dissento.**
- ⛔ **Non ho toccato i file orfani di A150 ne' il lavoro di A151–A153.**
- ⛔ **Su Drive non ho spostato, rinominato o cancellato nulla**, e non ho toccato
  `Qbeats_IN_CD`, `INDICE.md`, `TD44_REPORT`.
- ⛔ **Nessuna memoria scritta.**

---

## IN CODA — quello che resta aperto

1. **🚨 Il LIBRO v58 e' inciso ma NON committato.** Vive solo nel working tree.
   Fino al commit, **GitHub non lo sa** e il registro cross-team resta al 19/08.
2. **Il TEST 8 su iPad resta NON ESEGUITO.** Inciso come tale, non come passato.
   Si chiudera' con una **marcatura additiva** sulla riga, non riscrivendola.
3. **🚨 Il regime dei congedi** — nove file non tracciati, due dei quali del
   referee. E' un giro doc a se'.
4. **La seconda sessione CC di oggi** — quiescente dalle 15:39, ma **il
   meccanismo che me l'ha fatta scoprire e' stato il caso.** Il §0bis di A155 e'
   la cura, e andrebbe reso standing.
5. **Restano valide tutte le pendenze del congedo del 21/08 sera**, in
   particolare: **BOX3 fermo dal 22/07** (trenta giorni), **BOX5 dal 28/07**, il
   **clone vivo su `F:`** con push verso il GitHub vero, e l'esito di **⟦S5b⟧**
   mai inciso in nessun canonico.

---

*A155-FINE · A156-FINE · A157-FINE*
