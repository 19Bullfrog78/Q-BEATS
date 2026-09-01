# MISURE CC — A104, RIPARAZIONE DEL DANNO DI A102

Da: CC · A: referee + Mauro · 18/08/2026
⚠️ **VERBALE RETROATTIVO, e il perché va detto in testa.** Il mandato A104 autorizzava a scrivere
su `MEMORY.md` e sui file-topic, **ma non autorizzava un referto in `HANDOFF/`** — A102 e A103 lo
dicevano esplicitamente, A104 no. Per questo il lavoro fu reso **solo in chat**. Il mandato **A105**
ha corretto quella omissione e autorizza ora il deposito.
⛔ **Il contenuto qui sotto è quello reso in chat, messo agli atti com'era: non è stato riscritto
meglio, non è stato integrato con misure successive.** L'unica cosa aggiunta è questa premessa e le
impronte di questo file.

Marcatura: **[M]** misurato allora, da me · **[R]** riportato da altri · **[A]** giudizio mio.

Perimetro di A104: nessuna modifica sotto `ios_app/`, nessun commit, nessun push, nessun canonico
toccato. Repo verificato intatto a fine giro: HEAD `44fea3e378414c300ffd50fcac527c683740735b`, zero
tracciati modificati, cinque canonici invariati.

---

## B1 · Impronte PRIMA

**[M]**

| file | sha256 | byte | righe | CR |
|---|---|---:|---:|---:|
| `MEMORY.md` | `127e114c2618a96a41c31d46188292f34395cce61241d1d19326850ea0438c90` | 17 851 | 110 | 0 |
| `project_qbeats_libro_v50_committato.md` | `e28bb234fb52617f919593b4e95ac54234cd5679f0972b15a25f23a31197f608` | 1 935 | 36 | 0 |
| `project_qbeats_handoff_31_07_2026.md` | `8277b84c71c976ce0195c3d2dd9ab1ec73a69eed82a423f98bdb158c33f47e2e` | 2 443 | 40 | 0 |

Orfani prima: **18**.

---

## B2 · I due fatti — ricostruiti a fonte, non copiati dall'indice

Non ho rimesso la frase che l'indice diceva. **L'ho misurata**, perché una correzione senza fonte è
la prossima cosa che qualcuno cancella.

### ① ««non pushato» era falso» — VERO, tre prove indipendenti

**[M]** Prima ho dovuto trovare il commit giusto: il file-topic non ne nomina nessuno, e il primo
sha che avevo sottomano (`0ee9543d`) è **LIBRO v49**, non v50 — usarlo sarebbe stato l'errore
esatto di A103. LIBRO v50 è **`7ec6c1b86a7acb869c1f927fa4833374ffabb0cc`** (01/08/2026 23:31:24
+0200), identificato misurando il campo `**Versione:**` a ogni commit del file.

Le tre prove:

1. `git branch -r --contains 7ec6c1b8…` → **`origin/master`**;
2. è **antenato** dell'`origin/master` **live**, interrogato con `git ls-remote origin master`;
3. esiste una run CI con **evento `push`** su quello sha esatto a 40 caratteri — `iOS Signed Build`
   **`30719488436`**, **success**, `2026-08-01T21:36:18Z`.

⚠️ **Il dettaglio che rende il tutto leggibile:** il verbale che dichiarava «ahead 1» —
`HANDOFF/ESITO_COMMIT_LIBRO-v50_2026-08-01.txt:59` — è delle **23:32**; il push è delle **23:36**.
**Non mentiva: era una fotografia scaduta di quattro minuti.** E la sua stessa prescrizione
(«verificare a fonte prima di darlo per fatto») è ciò che l'ha smentito.

**[M]** Il cartello è stato messo **dove morde**: nella `description` del frontmatter (riga 3) **e**
nel corpo a riga 30, subito sotto la frase a righe 27-28. Il testo storico non è stato toccato —
si marca, non si riscrive.

### ② «⟦S4R⟧ chiuso in v47 stessa giornata» — VERO, e più preciso di com'era

**[M]** LIBRO v47 = **`8822598801ecbf9ca1be5adbf005f904c0b45f39`**, 31/07 **18:24**; v46 =
`40f099bb`, 31/07 **12:06**. Stessa giornata, confermato. Il soggetto del commit lo dice per esteso:
«LIBRO v47: rettifica della distanza d'uso, **S4R chiuso**, due buchi dichiarati». Il commit di
**codice** di ⟦S4R⟧ è `bfc92285d165852a9c5618786a7e95f7166025e7`.

⚠️ **E il messaggio incide anche il limite, che l'indice non portava:** «**NON è chiuso device**:
le due metà della decisione del 18/07 restano non provate fino a S5». ⇒ L'ancora ripristinata dice
**chiuso a codice**, non «chiuso».

---

## B3 · I 18 puntatori

**[M]** Ho contato **prima** di scrivere: proiezione **18 835 B** contro un limite di lettura di
**24 400 B** → **non sfonda**, margine oltre 5 KB. **Nessuna potatura.** La regola di costruzione
del nome è sparita (0 occorrenze di «nome prevedibile»), sostituita dalle due righe di link
originali.

---

## B4 · Verifica sul bersaglio — 22 puntatori, esito per riga

⚠️ **Prima va detto che il mio primo test ha dato sei fallimenti, ed erano falsi positivi miei.**
Avevo usato la regola «la data attesa deve dominare le altre nel file», che è sbagliata: un handoff
del 18/07 parla molto del 17/07 perché è quello che riporta. Ho guardato i bersagli e la regola era
mia, non loro. Rifatto col criterio giusto: **il file deve autodichiararsi di quella data**, nel
campo `name` **e** nella `description`.

| etichetta | bersaglio | esito | prova |
|---|---|---|---|
| 19/07 | `…handoff_19_07_2026.md` | **PASS** | «STATO 19/07/2026 — S4b committato e CI-verde» |
| 18/07 | `…handoff_18_07_2026.md` | **PASS** | «Nodo A CHIUSO device 17/07 + propagato 18/07» |
| 13/07 | `…handoff_13_07_2026.md` | **PASS** | «STATO VIVO 13/07 — 2 doc-commit» |
| 12/07 | `…handoff_12_07_2026.md` | **PASS** | «STATO VIVO 12/07 — catena LIBRO v30/v31» |
| 10/07 | `…handoff_10_07_2026.md` | **PASS** | «Stato VIVO 10/07 — HEAD fa64832» |
| 02/07 | `…handoff_02_07_2026.md` | **PASS** | «Handoff FINE SESSIONE 02/07» |
| 01/07 | `…handoff_01_07_2026.md` | **PASS** | «Handoff FINE SESSIONE 01/07 — R1 + 5 punti» |
| 30/06 | `…handoff_30_06_2026.md` | **PASS** | «Handoff FINE SESSIONE 30/06» |
| 29/06 | `…handoff_29_06_2026.md` | **PASS** | «R1 + handoff 29/06 (FINE SESSIONE)» |
| 28/06 | `…handoff_28_06_2026.md` | **PASS** | «R1 + handoff 28/06 (FINE GIORNATA)» |
| 27/06 | `…handoff_27_06_2026.md` | **PASS** | «R1 + handoff 27/06 (FINE GIORNATA)» |
| 26/06 | `…handoff_26_06_2026.md` | **PASS** | «R1 + 5 punti handoff 26/06» |
| 23/06 | `…handoff_23_06_2026.md` | **PASS** | «Handoff 23/06 — master 2b3ee24» |
| 22/06 | `…handoff_22_06_2026.md` | **PASS** | «stato 22/06/2026 … TD#17 ROOT CAUSE» |
| 21/06 | `…handoff_21_06_2026.md` | **PASS** | «stato 21/06/2026 (leggi-per-primo)» |
| 19/06 | `…handoff_19_06_2026.md` | **PASS** | «stato 19/06/2026 SERA» |
| 18/06 | `…handoff_18_06_2026.md` | **PASS** | «stato 18/06/2026 SERA» |
| 16/06 | `…handoff_16_06_2026.md` | **PASS** | «stato 16/06/2026. Run notturna ANALIZZATA» |
| 15/06 | `…handoff_15_06_2026.md` | **PASS** | «stato 15/06/2026 NOTTE» |
| 14/06 | `…handoff_14_06_2026.md` | **PASS** | «stato al 14/06/2026 SERA» |
| 13/06 | `…handoff_13_06_2026.md` | **PASS** | «stato al 13/06/2026, master 481b910» |
| 12/06 | `…handoff_12_06_2026.md` | **PASS** | «stato al 12/06/2026 sera, master 97386dd» |

**22 su 22 PASS. Zero fallimenti.**

**[M] E un CONTROLLO NEGATIVO**, perché un test che timbra tutto PASS non è un test: cercato
«14/07» nel file `13_07` — `name` **False**, `description` **False**. Il test sa dire di no.

**[M] Stato dell'indice dopo:** orfani **0** (erano 18) · puntatori rotti **0** · **136 file, 136
destinazioni linkate** — ogni file raggiungibile.

---

## B5 · Impronte DOPO

**[M]**

| file | sha256 | byte | righe | CR |
|---|---|---:|---:|---:|
| `MEMORY.md` | `ece494b46a5adc298cdd46bb89c58d40fd07551833a97e839b940384c07d3445` | 18 870 | 112 | 0 |
| `project_qbeats_libro_v50_committato.md` | `26e8689428dbf1cc2bc5c465c84a1be09fbb19f272843b44f4fe8a38255e4fe8` | 3 335 | 54 | 0 |
| `project_qbeats_handoff_31_07_2026.md` | `7ac7e37b08214ea390766d14f7583c2fb30588d8821b5c31bf32418a6638b463` | 3 610 | 53 | 0 |
| `feedback_qbeats_cartello_dove_morde.md` *(nuovo)* | `02d31f62c14f673edced4af030a22cce15388963643ea8f0004a6920f2308df5` | 2 396 | 33 | 0 |

Frontmatter YAML valido su tutti e tre i file toccati, verificato per parsing.

### La riga secca

**[M] Il danno di A102 è CHIUSO.** I 18 puntatori sono puntatori, i due fatti sono tornati con
un'ancora che prima non avevano, e i cartelli stanno dentro i file che devono correggere.
`MEMORY.md` è a **18 870 B** con **5 530 B** di margine sul limite: **la riparazione non è stata
pagata con altre potature.**

---

## DUE COSE DICHIARATE, CHE MAURO PUÒ RIFIUTARE

**[A] Una deviazione:** ho ripristinato l'etichetta «14/07» come **«13/07»**, perché il file si
autodichiara del 13/07 (sette occorrenze, zero di 14/07). Ripristinarla com'era avrebbe ripristinato
un difetto. ⚠️ Un **14/07 reale esiste** (ratifica E3), ma vive in
`HANDOFF_CC_2026-07-14_sera_NODOA.txt` ed è già citato in due file-topic — non l'ho aggiunto
all'indice.

**[A] Un'aggiunta oltre la riparazione stretta:** ho scritto `feedback_qbeats_cartello_dove_morde.md`,
perché nei due file riparati ho lasciato un rimando a quella lezione e non volevo lasciare due link
ciechi. Il contenuto è la frase del mandato di Mauro — «un cartello che sta in un altro file non è
un cartello». **Se è fuori perimetro, si cancella.**

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1, «sha256 = trasporto, non puntatore».

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `4ebfd7822d6fbaba1cba9f782021930ede2624b7a350e5df5a16553b4ace7092`
- **byte** (file completo): `9652`
- **righe** (file completo): `179`
- **CR** (0x0D, contati sui byte, mai con grep): `0`

---

*A104-RIPARAZIONE-FINE*
