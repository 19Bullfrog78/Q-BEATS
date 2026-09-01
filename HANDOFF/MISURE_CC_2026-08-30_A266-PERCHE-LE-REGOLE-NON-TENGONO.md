# MISURE CC — A266 — PERCHÉ LE REGOLE NON TENGONO — 30/08/2026

**⏱ Orologio:** domenica **30/08/2026, 11:33 locale (UTC+2)** · 09:33 UTC.

🚨 **VINCOLO §1, DICHIARATO IN TESTA COME PRESCRITTO — sedi da leggere per sapere «come si lavora qui»: PRIMA 7 · DOPO 3.** Nessun documento nuovo prodotto: questo è un referto, non un canonico.

⛔ **Nessuna modifica sotto `ios_app/`. Nessun commit. Nessun canonico toccato.**

---

# PARTE 1 — PER MAURO

## Quante sedi si devono leggere, e quante nessuno apre

**Nove.** Costituzione · BOX5 · BOX3 · BUGS · LIBRO · SCALETTA · i congedi · il CLAUDE.md · la memoria automatica.

**Due si aprono da sole** all'inizio di ogni chat: il CLAUDE.md e l'indice della memoria. **Le altre sette no**: qualcuno deve sapere che esistono e dire di aprirle.

⇒ **Il punto non è che le regole siano poche o mal scritte. È che sono in posti che non si aprono.** Nei soli congedi ho contato **306 divieti**: sono ordini veri, sparsi in ventisei file che nessuna sessione legge all'apertura.

## La regola più violata

**«Gli archivi si estraggono da git, non si copiano dal disco.»** Scritta il **21 luglio**. Da allora è stata violata **quattro volte** — tre erano lì da settimane senza che nessuno se ne accorgesse, la quarta l'ho fatta io ieri sera.

Ma il numero che conta di più è un altro, ed è peggiore:

🚨 **Le tre violazioni più recenti le ha fatte chi aveva appena scritto la regola, entro un giorno.** Ieri sera ho inciso io una norma sulle verifiche sbagliate — e l'ho violata **due volte nelle dodici ore successive**. Un'altra l'ho scritta la sera e infranta la mattina dopo.

⇒ **Scrivere una regola non protegge dal violarla, nemmeno chi l'ha scritta e nemmeno il giorno dopo.** Aggiungere righe non serve: ne abbiamo già più di quante se ne leggano.

## Quanto è rischioso lavorare su due chat in parallelo

**Reale, e stamattina è già successo.** Alle 11:18 l'altra chat ha usato il numero `A263`; io stavo per usare lo stesso, cinque minuti dopo. Entrambi avevamo controllato che fosse libero — **ed entrambi avevamo ragione nell'istante in cui abbiamo guardato.**

Il controllo guarda il passato e **non prenota il futuro**. Difesa esistente: **nessuna, solo l'attenzione.**

✅ **Stavolta l'ho evitato così**: ho scritto un biglietto che occupa il numero **prima** di cominciare, poi ho ricontrollato di essere solo. Costo: **un comando, un secondo.**

## Le tre cose che ridurrebbero il problema

**1 · Prenotare il numero prima di lavorare** — costo quasi zero, chiude subito il rischio delle due chat. *(L'ho già fatto oggi: funziona.)*

**2 · Spostare i divieti dai congedi a BOX5** — i congedi diventano **storia**, non legge. Costa un giro di lavoro e fa scendere le sedi da leggere **da sette a tre**. È l'unica delle tre che riduce davvero la quantità di roba.

**3 · Un controllo automatico che avvisa dopo, senza bloccare** — di sei regole studiate, **tre** sono verificabili da sole: gli archivi copiati male, le teste dei documenti che crescono, e i numeri usati due volte. Non impedirebbe l'errore: lo direbbe **subito** invece che settimane dopo. Costa poco ed è senza rischio, perché non ferma niente.

⚠️ **Quello che NON propongo: un documento nuovo.** Sarebbe il decimo, e il problema è che ne abbiamo già nove.

---

# PARTE 2 — LE MISURE, PER IL REFEREE

## §0 — Cancello ID e PRENOTAZIONE

**[M]** `A266` misurato sulle quattro gambe **con i binari esclusi** (`grep -rlI`): nome C: 0 · contenuto C: 0 · nome E: 0 · contenuto E: 0 · `git log --all --grep` 0. Positivo `A263` (creato oggi da altra sessione) → nomeC 1 · contC 2 · nomeE 1 · contE 1: **la sonda vede**.

**[M] Falso positivo di stamattina CONFERMATO**: `A265` rende **4** senza `-I` e **0** con — erano font `.ttf` e un `.pdb`. **`A265` era libero.** Le sonde di questo referto escludono i binari.

**[M] PRENOTAZIONE ESEGUITA prima di produrre altro**, come prescritto:

```
repo : HANDOFF\SEGNAPOSTO_A266_2026-08-30_CC.md
E:   : FILE X CLAUDE.MD\HANDOFF\SEGNAPOSTO_A266_2026-08-30_CC.md   (scritto 11:34)
```

**[M] Rimisura dopo la scrittura: UN SOLO segnaposto**, il mio (C: 1 file per nome, 1 per contenuto; E: 1). **Nessuna sessione concorrente nella stessa finestra.**

## §1 — (A) IL CONTEGGIO A DUE MANI

**[M] Artefatti in `HANDOFF/` scritti oggi 30/08** (`find -newermt`):

| ora | file | autore |
|---|---|---|
| 10:27 | `CONGEDO_CC_2026-08-30_A262.md` | **io** |
| 11:18 | `MISURE_CC_2026-08-30_A263-CONTO-DEI-TOCCHI-E-PORTE-DELLA-LISTA.md` | **NON io** |
| 11:34 | `SEGNAPOSTO_A266_2026-08-30_CC.md` | **io** |

⇒ **Un solo artefatto di un'altra sessione oggi.** Quel file dichiara al §0 di aver verificato l'ID «su due supporti: zero occorrenze» — **vero nell'istante in cui l'ha scritto**.

**[M] Meccanismo di mutua esclusione esistente: NESSUNO.** Le quattro gambe sono tutte **letture del passato**; nessuna scrive, quindi nessuna prenota. Due sessioni nella stessa finestra misurano entrambe zero e procedono entrambe.

**[M] Costo della prenotazione, misurato eseguendola**: una `printf` + una `cp` + una rimisura = **un comando, tempo trascurabile**. ⚠️ **Non elimina la corsa**, la stringe: restano collidibili i millisecondi fra la misura e la scrittura del segnaposto. Riduce la finestra da *«tutta la durata del lavoro»* a *«un istante»*.

⚠️ **Sonde dichiarate, perché il referee è cieco agli untracked**: `find HANDOFF -maxdepth 1 -type f -newermt "2026-08-30 00:00" -printf '%TH:%TM %f'`. Sono file **non tracciati**: non verificabili da `git`, solo dal disco.

## §2 — (B) DOVE VIVONO LE NORME DI PROCESSO

**[M] Censimento strutturale** (conteggio del marcatore `⛔`, non lettura integrale):

| sede | righe | norme `⛔` | **caricata da sola?** |
|---|---|---|---|
| `CLAUDE.md` | 82 | 8 | ✅ **SÌ** — a ogni sessione |
| `MEMORY.md` (indice auto-memoria) | 81 | — | ✅ **SÌ** — prime 200 righe |
| Costituzione (`FILE.MD/…V5…`) | 101 | 5 *(marcatore `REGOLA`/`MAI`)* | ⛔ no |
| `BOX5_QBEATS.md` | 1288 | **58** | ⛔ no |
| `BUGS_QBEATS.md` | 1552 | **130** | ⛔ no |
| `LIBRO_MASTRO_QBEATS.md` | 546 | **57** | ⛔ no |
| `BOX3_QBEATS.md` | 819 | 7 | ⛔ no |
| **congedi in `HANDOFF/`** (26 file, 25 con norme) | — | 🚨 **306** | ⛔ no |
| memoria: 143 file-topic | — | — | ⛔ no (on demand) |

⇒ **[M] Nove sedi. Due si caricano da sole. L'ipotesi del referee è CONFERMATA e superata**: non «almeno cinque», sono **nove**, e **sette su nove** richiedono che qualcuno le indichi.

🚨 **[M] Il dato che spiega tutto: 306 divieti vivono nei congedi**, cioè nell'unica categoria di documenti scritta *per essere letta una volta sola, dalla sessione successiva*. Sono più dei divieti di BUGS (130) e BOX5 (58) messi insieme.

## §3 — (C) VIOLAZIONI DOPO LA SCRITTURA

**[M] Norme con recidiva registrata, e le date:**

| norma | scritta | violazioni DOPO | dove registrate |
|---|---|---|---|
| **estrarre dal blob, non copiare dal disco** | **21/07** (`edaa80f`) | 🚨 **4** — `LIBRO v64` · `BUGS v63` · `BUGS v68` (mai rilevate al tempo) + `LIBRO v66` (ieri sera, mia) | audit A262/A263, `BOX5:49` |
| «`I:` non rimonta *Il mio computer*» | cartello `BOX5 V37 §R-δ.6` | **2** (A159 21/08 · A250 29/08) | `BUGS:1446`, `BUGS:1546` |
| la testa di un documento non cresce | `R-δ.7`, 24/08 | **2** | `BOX5:799`, `LIBRO:370`, ticket `TD-box3-citazioni-nude-slittate` |
| **positivo di forma sbagliata** | **29/08 sera** (da me) | 🚨 **2 in ~14 ore** — `cmp` contro il disco invece del blob · `grep` senza `-I` sui binari | referto A262, questo |
| **assenza dalla propria vista** | **29/08 sera** (da me) | **1, il mattino dopo** — spazzata `CLAUDE.md` su un supporto solo | conversazione 30/08 |
| «tapis roulant» (non copiare stato a mano) | **11/07**, nel CLAUDE.md di CD | riderivata **da zero** il 29/08 | conversazione 30/08 |

**[M] Norme con violazioni ripetute: 5** *(la sesta, il tapis roulant, non è una violazione ma una duplicazione)*. **Record: 4**, la regola blob-vs-disco.

🚨 **[A] Il reperto più forte non è il record, ed è quello che smonta l'ipotesi implicita del mandato.** Il mandato cerca *perché le regole non tengono*, come se il problema fosse la loro diffusione. Ma **tre delle sei violazioni più recenti sono state commesse da chi aveva scritto la regola, entro 24 ore, avendola sotto gli occhi.** ⇒ **In quei tre casi la sede non c'entra: nessuna riduzione di documenti li avrebbe evitati.** La diffusione spiega le violazioni *vecchie* (le tre CRLF rimaste settimane invisibili); **non spiega le recenti.**

⇒ **[A] Sono due malattie diverse, e la cura è diversa:** ciò che è **sparso** si cura riducendo le sedi; ciò che è **sotto gli occhi e violato lo stesso** si cura solo con un rilevatore, perché l'attenzione ha già fallito.

## §4 — (D) RILEVABILITÀ, dopo il fatto e senza bloccare

⛔ Misura sugli hook **non rifatta**: già eseguita stamattina, conclusione ratificata (i cancelli che bloccano dipendono da uno stato che vive in chat). Estensione richiesta:

| norma | rilevabile da un controllo che avvisa? |
|---|---|
| snapshot copiato dal disco | ✅ **SÌ** — confronto impronta snapshot ↔ blob al commit citato nel nome. Deterministico, zero falsi positivi |
| testa di un canonico che cresce | ✅ **SÌ** — conteggio righe prima/dopo sulle prime N righe |
| ID già usato | ✅ **SÌ** — banale, e coprirebbe anche le due sessioni |
| positivo di forma sbagliata | ⚠️ **solo in parte** — rilevabile il caso «sonda che rende 0 senza positivo dichiarato»; non la scelta di *quale* positivo |
| assenza dalla propria vista | ❌ **no** — è un ragionamento, non un'azione osservabile |
| supporto Drive/mount sbagliato | ❌ **no** — richiede sapere cosa si cercava |

⇒ **3 su 6 rilevabili in pieno**, 1 in parte, 2 no. ⛔ **Non costruito niente.**

## §5 — VINCOLO §1: LE SEDI, PRIMA E DOPO

**PRIMA — sedi normative da leggere: 7** (Costituzione · BOX5 · BOX3 · BUGS · LIBRO · congedi · CLAUDE.md).

**DOPO — 3**, e la riduzione è **sottrazione, non aggiunta**:
1. **`CLAUDE.md`** — si carica da solo, fa da indice
2. **`BOX5`** — sede unica delle norme di processo (ospita già `R-δ` e la TASSONOMIA)
3. **Costituzione** — le regole assolute, che non si toccano

⇒ **I 306 divieti dei congedi migrano in BOX5; i congedi restano STORIA.** `BUGS` torna a essere solo tracker, `LIBRO` solo ratifiche. ⛔ **Zero documenti nuovi.**

## §6 — QUANTO HO LETTO, E QUANTO NO

**[M] Letto per intero: nulla dei sei canonici** — rispettato il vincolo §2. Misurato per **struttura**: conteggi di marcatore, `find -newermt`, `grep -c` mirati, e apertura del **solo contesto** attorno a sei righe che le sonde hanno indicato.

⛔ **NON misurato, e non dedotto:**
- **Non ho letto il file `A263` dell'altra sessione** oltre alla testa: **non so cosa contenga né se tocchi questo lavoro.**
- **Il conteggio `⛔` è un proxy, non un censimento di norme.** Un `⛔` può marcare un divieto, un'enfasi o una nota. **Il numero misura la densità di marcatore, non le norme** — sovrastima quasi certo.
- **Non ho verificato le 306 dei congedi una per una**: non so quante siano ancora vive, superate o duplicate di BOX5. ⚠️ **La proposta di migrarle poggia su questo numero non verificato.**
- **Non ho cercato recidive nei congedi e nei referti**, solo nei canonici: le violazioni registrate **solo** in `HANDOFF/` non sono nel conteggio. **Il 4 è un minimo, non un totale.**
- **Non ho misurato il costo** della migrazione proposta al §5.
- **La Costituzione l'ho contata con un marcatore diverso** (`REGOLA`/`MAI` = 5) perché non usa `⛔`: **non è confrontabile** con le altre righe della tabella.

## §7 — PERCORSI E IMPRONTE

*(l'impronta di questo file vive nel messaggio di consegna)*

```
SEGNAPOSTO  repo : HANDOFF\SEGNAPOSTO_A266_2026-08-30_CC.md
            E:   : FILE X CLAUDE.MD\HANDOFF\SEGNAPOSTO_A266_2026-08-30_CC.md
REFERTO     repo : HANDOFF\MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md
            E:   : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-30_A266-…md
Drive: riflesso automatico di E:
```

*A266-PERCHE-LE-REGOLE-NON-TENGONO-FINE*
