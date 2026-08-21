# MISURE CC — A147-CORREZIONI-SU-A146

**ID ricevuto e verificato: `A147-CORREZIONI-SU-A146`.**
Da: CC · A: referee, + Mauro · 21/08/2026
Ancoraggio: **HEAD = `a83353c382877037d27b35912f6d3bdda6ee1988`**, locale = remoto.

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 · §4 e la chiusura
`FINE MANDATO A147`. Nessun taglio.

⛔ **NESSUN COMMIT.** Diff in `HANDOFF/DIFF_2026-08-21_A147-CORREZIONI-SU-A146.txt`.
⛔ **DOC-ONLY:** un solo file, `BUGS_QBEATS.md`.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE DUE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Tutti e sei i controlli del §4 chiudono**, incluso il (c) — quello che non si
può automatizzare. E ha trovato qualcosa che la sonda per lemma non vedeva.

**2. ⚠️ Il mio conteggio del controllo positivo DIVERGE dal referee: misuro
CINQUE titoli, non sei.** Non ho adattato il mio numero al suo. La conclusione
non cambia. Dettaglio sotto.

---

## §0 · L'ID

**[M]** Sonda stretta, due supporti, due forme:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A147** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A148 | 0 | 0 | 0 | 0 | controllo negativo |
| A144 | 3 | 7 | 3 | 5 | controllo positivo |
| A145 | 1 | 3 | 1 | 3 | controllo positivo |
| A146 | 2 | 2 | 2 | 2 | controllo positivo |

⛔ **Ispezione del contesto** — l'unico hit, identico sui due supporti:

```
HANDOFF/MISURE_CC_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.md:44:| A147 | 0 | 0 | 0 | 0 | controllo negativo |
```

Menzione come controllo negativo, non uso. Nessuna collisione.

---

## §1 · LO STATO

**[M]**

```
HEAD locale : a83353c382877037d27b35912f6d3bdda6ee1988
HEAD remoto : a83353c382877037d27b35912f6d3bdda6ee1988
atteso      : a83353c382877037d27b35912f6d3bdda6ee1988
```

**[M] Il lavoro di A146 era ancora sul disco e non committato:**
`git status` rende **solo** ` M BUGS_QBEATS.md`.

**[M] Impronta del diff rigenerato PRIMA di toccare qualcosa:**

```
atteso (consegnato in A146) : 89f897ab51de0c09e4b38d07e685bb86f477f755cf873beaa6974f5ef97e3f4b
rigenerato ora              : 89f897ab51de0c09e4b38d07e685bb86f477f755cf873beaa6974f5ef97e3f4b
```

**Identico.** Nessuno aveva toccato il file fra A146 e A147.

---

## §2 · LA SEVERITÀ RATIFICATA — TRE PUNTI

**[M] I tre bersagli, letti prima di sostituire:**

| # | bersaglio | dove |
|---|---|---|
| (a) | il titolo del ticket | `:472` |
| (b) | il bullet della severità | `:481` |
| (c) | il segmento dentro la riga `| 58 |` | tabella di Sezione 5 |

Ogni sostituzione ancorata su stringa **unica** (assert `count == 1` nello
script, che si nega la scrittura se non torna).

### (a) Titolo — sostituito

```
da : ### TD-qlive-non-scalata-ipad — … (⚠️ SEVERITÀ PROPOSTA 🟠 MEDIA — DECIDE MAURO)
a  : ### TD-qlive-non-scalata-ipad — … (🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — da chiudere PRIMA della v1)
```

### (b) Bullet della severità — sostituito per intero

**Il testo che c'era, e che era FALSO dal 21/08:**
```
- ⚠️ **Severità NON assegnata dal referee.** Dipende da se l'iPad sia device di palco o solo di prova: **decide Mauro.**
```

Sostituito col testo ratificato del mandato, verbatim.

### (c) Riga `| 58 |` — segmento allineato

**Il segmento che c'era:**
```
⚠️ **Severità PROPOSTA 🟠 MEDIA, NON assegnata**: dipende da se l'iPad sia device di palco o solo di prova, **decide Mauro**.
```

Sostituito con la forma ratificata + ragione in forma breve. ⛔ **Il resto della
riga non è stato riscritto**: la sostituzione è chirurgica su quel solo segmento.

---

## §3 · LA MARCATURA SU `TD #23`

⛔ **Non riscritto: MARCATO.** Una sola riga aggiunta **in coda**, nessuna delle
sue righe esistenti toccata.

**[M] Il controllo positivo del referee, RIFATTO da me** — e qui c'è una
divergenza che dichiaro invece di appianare:

| grandezza | mio numero | numero del referee |
|---|---:|---:|
| titoli di Sezione 2 che portano `CHIUSO` | **5** | 6 |
| titoli totali in Sezione 2 | 28 | — |
| `TD #23` porta `CHIUSO`? | **0** | 0 ✅ concorde |

⚠️ **[A] Non ho adattato il mio conteggio al suo.** I cinque, elencati perché il
numero sia ispezionabile e non da credere sulla parola:
`TD-qstage-tab-reset` · `TD-qstage-pill-qlive-morta` · `TD-ipad-editor-fontsize` ·
`TD-editor-bpm-typeable` · `TD-ipad-home`.

⚠️ **[M] E dichiaro anche perché il primo tentativo sarebbe stato sbagliato:** ho
misurato usando i confini di sezione **pre-A146** (822-997), ma l'inserimento del
ticket nuovo ha slittato tutto di **13 righe**. Rimisurato coi confini veri
(`835-1010`, ricavati per contenuto con `grep "^# Sezione"`) il numero è 5 in
entrambi i casi — ma il primo era **giusto per caso**, ed è esattamente il tipo di
errore che il §4(c) esiste per intercettare.

✅ **La sostanza non cambia:** `TD #23` rende **0** e la sonda **vede** (rende 5
sugli altri). La conclusione del mandato regge, qualunque sia il conteggio esatto.

---

## §4 · I CONTROLLI

### (a) Le stringhe vietate — ZERO, nel blocco e nella riga

| stringa | blocco | riga `| 58 |` |
|---|---:|---:|
| `PROPOSTA` | **0** | **0** |
| `decide Mauro` | **0** | **0** |
| `NON assegnata` | **0** | **0** |
| `DECIDE MAURO` | **0** | **0** |

### (b) ⛔ CONTROLLO POSITIVO nella forma ESATTA della sonda

La **stessa** `grep -o -F` che rende zero sopra deve **rendere** su stringhe che
ci sono davvero:

| stringa | blocco | riga `| 58 |` |
|---|---:|---:|
| `RATIFICATA` | 1 | 1 |
| `Mauro` | **4** | **3** |
| `OPEN MEDIA` | 1 | 1 |
| `NON BLOCCANTE PALCO` | 1 | 1 |
| `device di palco` | 1 | 1 |

✅ **`Mauro` rende 4 e 3** ⇒ la sonda non è cieca sul lemma critico: **gli zeri
di (a) sono veri**, non artefatti del filtro.

### (c) ⛔ IL CONTROLLO SULL'OBIETTIVO — e ha trovato qualcosa

**[A] Il mandato ha ragione sul principio, e l'ho preso alla lettera:** un cancello
che enumera ciò che intendevo fare non può vedere ciò che non ho pensato. Quindi
**non mi sono fermato alle quattro stringhe**: ho fatto uno sweep su **tutta la
famiglia dei costrutti che rimandano una decisione** —
`decid*` · `decision*` · `spett*` · `assegn*` · `propost*` · `dipend*` ·
`valut*` · `attend*` · `rinviat*` · `da stabilir*` · `resta a …`.

**[M] Lo sweep ha trovato TRE residui che la sonda per lemma non copriva.** Li ho
letti nel contesto uno per uno:

| # | dove | testo | verdetto |
|---|---|---|---|
| 1 | blocco | «La gravità non **si decide** su chi c'è nella stanza» | ✅ **legittimo** — è la **ragione ratificata**, un'affermazione, non un rimando |
| 2 | riga `| 58 |` | stessa frase | ✅ **legittimo**, stesso motivo |
| 3 | riga `| 58 |` | «la **decisione** se siano lo stesso difetto è del referee ed è RINVIATA» | ✅ **legittimo, e DA NON RIMUOVERE** |

⛔ **Il terzo merita una riga a sé.** Riguarda la **riconciliazione**, che è una
decisione **diversa** da quella ratificata e **genuinamente ancora aperta** —
dichiarata tale nel mandato A146, nel ticket stesso e nel §3 di A147.
**[A] Un cancello che avesse cancellato ogni «decisione» avrebbe cancellato anche
questa, e avrebbe prodotto una regressione mentre chiudeva verde.** È il rovescio
esatto della trappola del §4(c): non solo «non vedere ciò che non hai pensato», ma
anche «vedere troppo e distruggere ciò che era giusto».

✅ **(c) CHIUDE: nel blocco e nella riga non resta nessuna frase che rimandi a
Mauro una decisione già presa**, né con le parole elencate né con altre.

### (d) `TD #23` — una riga aggiunta, zero modificate

**[M] Dall'hunk del diff:** `@@ -957,0 +971 @@` — la forma `-N,0` significa
**zero righe rimosse**; `+971` significa **una riga aggiunta**. Nessuna riga
esistente del ticket è stata toccata.

### (e) A-capo — CR = LF, zero righe miste

**[M]** `CR = 1170`, `LF = 1170`, misurati con `tr -cd` e **mai con `grep -c`**
(che su CRLF renderebbe zero — falso zero registrato in A139).

### (f) Riletti dal file e incollati verbatim

Sotto, tutti e tre.

---

## (f1) IL BLOCCO DEL TICKET — riletto dal file, per intero

```
### TD-qlive-non-scalata-ipad — la strategia iPad non è mai stata applicata a Q-Live (🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO — da chiudere PRIMA della v1)
- **Osservato:** Mauro, 21/08/2026, collaudo device su iPad 7a gen. DUE facce, stessa causa.
  - **(i)** nel dettaglio show il TITOLO è circa il doppio di tutto il resto della stanza.
  - **(ii)** passando da Shows al dettaglio il badge «Read-only» SCIVOLA VERSO IL BASSO. Su iPhone resta fermo (gate A144 verde).
- **Causa misurata dal referee a HEAD `a83353c`:** nel dettaglio il titolo è `29 * scaleFactor`; il badge è `9.5` fisso. Al livello 1 il titolo è `29` fisso. ⇒ su iPad il titolo del solo dettaglio cresce, la sua riga di scrittura scende, e il badge — ancorato al baseline da A144 — scende con lei.
- ⛔ **A144 NON È LA CAUSA e non va revertito.** Fa esattamente il suo mestiere, su un titolo di misura sbagliata. Su iPhone è collaudato verde.
- **Il difetto vero è di PERIMETRO:** la strategia iPad (Strada A, scala proporzionale, BOX5 «Layout strategy v1») è ratificata e device-validata su Vista Live, Q-Stage e Home. **Su Q-Live non è mai stata applicata.** Censimento del referee a HEAD: `QLiveShowsView` 8 font, **0** scalati · `QLiveShowDetailView` 8 font, **1** scalato · `ShowsListView` 11 font, **0** scalati. ⇒ **1 font su 27.** L'isolamento di quell'uno è il SINTOMO, non la causa.
- ⛔ **NON rimuovere lo scaling dal titolo.** Sarebbe il ribaltamento di `TD #23` e `TD-ipad-editor-fontsize`, entrambi CHIUSI e device-validati — il secondo confermato da Mauro in persona («ok tutto bene», 01/07). **La riparazione è ESTENDERE la scala al resto di Q-Live**, non toglierla.
- **Effetto atteso della riparazione:** quando titolo e badge crescono insieme la geometria resta proporzionale ⇒ **entrambe le facce si chiudono da sole.** ⚠️ Atteso, non verificato.
- **Severità RATIFICATA da Mauro 21/08**, e la ragione va incisa perché è più forte del giudizio: **l'app non è per Mauro, è per gli utenti; iPhone e iPad sono ENTRAMBI device di palco.** La gravità non si decide su chi c'è nella stanza. ⇒ Non è rifinitura: è un **requisito di distribuzione** — una stanza intera che si vede sbagliata su metà dei device non esce. ⚠️ NON è però bloccante palco: su iPad si legge, si avvia e si suona. **È sgraziato, non rotto.**
- ⛔ **RICONCILIAZIONE NON FATTA** con `TD #23`, `TD-ipad-editor-fontsize`, `TD-ipad-home` (tutti Sez.2, chiusi). Chi apre questo ticket li legge PRIMA di scrivere una riga.
- **Non è un atomo da una riga:** due schermate, sedici testi, più spaziature e altezze card.
```

## (f2) LA CODA DI `TD #23` — riletta dal file

```
### TD #23 — Font responsive iPad (Strada A scaling)
- **Sintomo:** font/spacing non si adattavano a iPad portrait.
- **Fix:** commit `adfcc39` (Fase 1 log baseline 390pt) + `8a5432b` (Fase 2 refactor 11 file, 24 callsite) 18/05/2026.
- **Pattern ratificato:** `pt_originale * scaleFactor` con `scaleFactor: CGFloat = geo.size.width / 390` calcolato in LiveView e propagato come parametro esplicito.
- **Validato:** iPhone 13 + iPad portrait pre-2018.
- **Memoria correlata:** `feedback_qbeats_scaling_responsive.md` (vietati `@ScaledMetric`, `UIFont.preferredFont`, `sizeCategory`).
- ⚠️ **MARCATURA 21/08 (A147) — QUESTO TICKET È CHIUSO, MA NON LO DICHIARAVA. Zero parole riscritte sopra: si marca.** Che sia chiuso lo dicono le sue righe **`Fix`** (commit `adfcc39` + `8a5432b`, 18/05/2026) e **`Validato`** (iPhone 13 + iPad portrait), e la sua collocazione in **Sezione 2 — Bug CHIUSI**. ⚠️ **Ma l'oggetto non lo portava:** nessun 🟢 `CHIUSO` nel titolo e **nessuna riga di Stato** — unico dei tre ticket iPad (controllo positivo: cinque titoli di Sezione 2 ce l'hanno). ⛔ **La marcatura esiste per una ragione precisa:** `TD-qlive-non-scalata-ipad` (§1.2) lo cita **due volte come prova** che lo scaling non va rimosso. Un fatto vero che l'oggetto citato **non porta** è della stessa classe dei puntatori `file:riga` senza ancora al commit: regge finché qualcuno non lo legge da solo.
```

## (f3) LA RIGA `| 58 |` — riletta dal file

```
| 58 | 2026-08-21 | CC + referee | **Un ticket NUOVO in §1.2, doc-only, zero codice.** `TD-qlive-non-scalata-ipad` — la strategia iPad (Strada A, scala proporzionale) non è mai stata applicata a Q-Live. Osservato da Mauro su **iPad 7a gen** il 21/08 in DUE facce con **una sola causa**: **(i)** nel dettaglio show il titolo è circa il doppio del resto della stanza · **(ii)** passando da Shows al dettaglio il badge «Read-only» scivola verso il basso. Causa misurata dal referee a HEAD `a83353c`: nel dettaglio il titolo è `29 * scaleFactor` mentre il badge è `9.5` fisso, e al livello 1 il titolo è `29` fisso — su iPad cresce il solo titolo del dettaglio, la sua riga di scrittura scende, e il badge ancorato al baseline scende con lei. ⛔ **A144 NON è la causa e non va revertito**: fa il suo mestiere su un titolo di misura sbagliata, ed è verde al gate iPhone. **Il difetto è di PERIMETRO** — censimento del referee: `QLiveShowsView` 0 font scalati su 8 · `QLiveShowDetailView` 1 su 8 · `ShowsListView` 0 su 11, cioè **1 font su 27**; l'isolamento di quell'uno è il sintomo, non la causa. ⛔ **NON si rimuove lo scaling dal titolo**: sarebbe il ribaltamento di `TD #23` e `TD-ipad-editor-fontsize`, entrambi CHIUSI e device-validati — la riparazione è ESTENDERE la scala al resto di Q-Live. ✅ **Severità RATIFICATA da Mauro 21/08: 🟠 OPEN MEDIA / ⚠️ NON BLOCCANTE PALCO**, da chiudere PRIMA della v1. La ragione è incisa nel ticket perché è più forte del giudizio: **l'app non è per Mauro, è per gli utenti, e iPhone e iPad sono ENTRAMBI device di palco** — la gravità non si decide su chi c'è nella stanza. È un **requisito di distribuzione**, non una rifinitura; non è bloccante palco perché su iPad si legge, si avvia e si suona: **sgraziato, non rotto**. ⛔ **RICONCILIAZIONE NON FATTA** con i tre ticket iPad di Sez.2 (`TD #23` · `TD-ipad-editor-fontsize` · `TD-ipad-home`), letti e riportati verbatim in referto, tutti e tre verificati CHIUSI: la decisione se siano lo stesso difetto è **del referee ed è RINVIATA**. Header bump 57→58. Doc-only. |
```

---

## IL DIFF

`HANDOFF/DIFF_2026-08-21_A147-CORREZIONI-SU-A146.txt`
· 48 righe · sha256 `c6b68c0f851e35da5f88557932fc51063076f25d423f7bd21a3d19a990bc4028`
· **1 file, +16 / −1**.

⚠️ **Il diff porta A146 E A147 insieme**, perché A146 non è mai stato committato:
il confronto è verso HEAD. Le correzioni di A147 sono **inline** nel testo del
ticket, non un secondo strato sopra. ⇒ **Non esisterà in cronologia un commit col
ticket nella forma «severità proposta».** Quella versione non entra mai nel repo.

**[M] I quattro hunk:**

| hunk | cosa | origine |
|---|---|---|
| `@@ -3 +3 @@` | `**Versione:** 57 → 58` | A146 |
| `@@ -471,0 +472,13 @@` | il ticket nuovo (13 righe) | A146, **corretto da A147** |
| `@@ -957,0 +971 @@` | la marcatura su `TD #23` | **A147** |
| `@@ -1151,0 +1166 @@` | la riga `| 58 |` | A146, **corretta da A147** |

**[M] L'unica riga rimossa in tutto il diff è `-**Versione:** 57`.** Tutto il
resto è additivo: nessun ticket esistente riscritto.

---

## CONSEGNA

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A147-CORREZIONI-SU-A146.md` e
`DIFF_2026-08-21_A147-CORREZIONI-SU-A146.txt`.

**Facce:** `BUGS_QBEATS.md` è **CRLF su disco, LF nel blob** — `.gitattributes`
esenta solo `HANDOFF/**`, `DESIGN/**`, BOX3 e BOX5, e BUGS non è coperto.
`HANDOFF/**` è `-text` ⇒ **LF, disco = blob**.

⚠️ **R-δ: due gambe su tre.** Drive non autorizzato ⇒ **scritto, non consegnato**.

---

## IN CODA

1. **Il conteggio 5 vs 6** del controllo positivo — dichiarato divergente, non
   appianato. La conclusione regge in entrambi i casi.
2. **Il 7/7 di A139** — il posto è misurato in A146 (`LIBRO` Sezione 2, riga
   datata). Serve un mandato. **Quarta segnalazione.**
3. **L'esito di ⟦S5b⟧** — documento pronto dal 19/08, mai atterrato in un
   canonico.
4. **La riconciliazione dei tre ticket iPad** — del referee, dichiarata rinviata.
5. **Il §Workflow punto 4** (formato del messaggio di commit) — quarta
   segnalazione.
6. **Il collaudo device di A144 su iPad** — è il difetto registrato qui.

---

*A147-FINE*
