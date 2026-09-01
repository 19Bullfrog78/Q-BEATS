# MISURE CC — A190 · DATA REALE E DUE REGOLE

Da: CC · A: **referee** (+ Mauro)
Mandato: `A190-DATA-REALE-E-DUE-REGOLE` · **COMMIT AUTORIZZATO — ESEGUITO**
Completezza: **5 sezioni (§0→§4), ultima riga `A190-FINE-MANDATO` — integro.**
**[M] Modello: intestazione Opus 5, interfaccia Opus 5 — coincidono.**
**[M] A189: mai ricevuto, mai eseguito — verificato, 0 righe di Sez.2 datate 23/08 e 0 menzioni di A189 nei cinque canonici prima di scrivere.**

Marcatura: **[M]** misurato da me alla fonte oggi · **[R]** riportato · **[A]** giudizio mio.
⛔ **Zero tocchi a `ios_app/` e `core_engine/`. Nessun file rinominato. BOX3, BUGS e SCALETTA non toccati.**

---

# ✅ COMMIT `91809bb1cf9b914c070f4a0f315982021b3cbb59` — ONLINE

Due file, `+34 −4`. LIBRO **v61**, BOX5 **V31**. Locale e remoto verificati con `ls-remote`.
Due stampe depositate su `E:`, entrambe **byte-identiche al blob**.

---

## §0 · ID `A190` — LIBERO

**[M] Per NOME (potata):** 0 su repo, 0 su E:. Trappola ① **morde** (1 hit non potato).
Controllo positivo (`A188`, copiato dal file): 1 per gamba.

**[M] Per CONTENUTO, su testo APPIATTITO:** 1 hit su repo, 9 su E:.
L'unico hit reale è **classe ④**: `HANDOFF/MISURE_CC_2026-08-21_A158-COMMIT-LIBRO-v58.md:56`
lo tabula come controllo negativo — `| A190 | 0 | 0 | 0 | 0 | controllo **negativo** |`.
Gli altri sono classe ② (log di device).

🚨 **[M] E qui la trappola ha morso mentre stavo per inciderne la regola.** La sonda
`grep -o '.\{60\}A190.\{60\}'` sullo stesso file ha reso **niente**: la riga di tabella che
contiene l'hit **va a capo**, e il contesto fisso non entra su una riga sola. La ricerca sul
testo **appiattito** l'ha trovato subito. ⇒ **quarto morso in due giorni**, e la prova che la
regola del §2(b) serve anche alle **sonde ID**, non solo ai controlli d'integrità.

**[M] Negativo tarato:** 0.

---

## §1 · I FATTI, MISURATI DA ME

### (a) Date dei due commit

**[M] Comando:** `git show -s --format='%H%n%ad%n%cd' --date=iso-strict <sha>`

```
9edc120eafd2999bf915f974e8b204492e7931f5
  author    : 2026-08-23T09:46:57+02:00
  committer : 2026-08-23T09:46:57+02:00

4629ee9ec943a1ebb8a16a49164aa457a8b99514
  author    : 2026-08-22T10:58:38+02:00
  committer : 2026-08-22T10:58:38+02:00
```
⇒ **[M] Ventitré ore esatte fra i due.** Author e committer coincidono su entrambi.

✅ **[M] La cifra del referee combacia con la mia:** il commit è delle **09:46 del 23/08**.
⛔ **[A] E conferma che «è mezzanotte passata» non reggeva:** 09:46 è mattina inoltrata.
La segnalazione di A188 era giusta, la spiegazione era inventata — **è la stessa famiglia
che questa catena ripara da A176, e stavolta l'ha commessa il referee sulla mia misura.**

### (b) Date dei referti A172→A188

**[M] Comando:** `stat -c '%y|%n'` su ciascuno, ordinati per tempo.

| referto | mtime |
|---|---|
| A172 | 2026-08-22 12:02:23 |
| A173 | 2026-08-22 13:40:08 |
| A176 | 2026-08-22 15:36:17 |
| A178 | 2026-08-22 16:11:38 |
| A180 | 2026-08-22 16:27:17 |
| A181 | 2026-08-22 16:46:34 |
| A182 | 2026-08-22 17:08:22 |
| **A184** | **2026-08-23 08:52:39** |
| A185 | 2026-08-23 09:19:29 |
| A186 | 2026-08-23 09:28:28 |
| A187 | 2026-08-23 09:39:26 |
| A188 | 2026-08-23 09:55:32 |

**[M] La frontiera:** ultimo del 22/08 = **A182, 17:08:22** · primo del 23/08 = **A184,
08:52:39**. **[M] Fra i due corrono 15h44m senza alcun artefatto.**
✅ **[M] Il fatto del referee regge:** A184→A188 portano `2026-08-22` nel nome e sono del 23/08.

### ⚠️ Dove la mia misura PRECISA la formulazione del referee

Il mandato dice che le ratifiche di Mauro «cadono in una finestra fra l'ultimo referto del
22 e il primo del 23». **[M] Misurato, non è così:** le ratifiche incise come «22/08/2026»
compaiono in referti scritti il **22/08 fra le 15:36 e le 16:46** (A176, A178, A180, A181),
cioè **prima** della finestra, non dentro.
⚠️ **[A] Ma la conclusione del referee resta vera per un'altra ragione, e l'ho scritta così
in LIBRO:** nessun documento registra **quando Mauro le ha pronunciate** — l'evento di
ratifica vive in chat, non in un artefatto datato. **Non sorgentata: sì. Collocata nella
finestra notturna: no.**

### La riga incisa in LIBRO Sez.2 — verbatim

```
| 2026-08-23 | **LA SESSIONE A166→A190 STA A CAVALLO DI DUE GIORNI — date misurate da CC, non asserite.** ⚠️ **Le date dei nomi NON sono state cambiate e nessun file e' stato rinominato: la discrepanza si dichiara qui.** **(1) Commit dei documenti:** `9edc120eafd2999bf915f974e8b204492e7931f5`, author = committer = **2026-08-23T09:46:57+02:00** (`git show -s --format=%ad --date=iso-strict`); il commit precedente `4629ee9` e' del **2026-08-22T10:58:38+02:00** — **ventitre ore esatte** fra i due. **(2) Referti:** A172→A182 sono del **22/08** (da 12:02:23 a 17:08:22); **A184→A188 sono del 23/08** (da 08:52:39 a 09:55:32) **pur portando `2026-08-22` nel nome**. Fra l'ultimo del 22 e il primo del 23 corrono **15h44m** senza alcun artefatto. **(3)** ⚠️ **NON SORGENTATO, e si dichiara invece di colmarlo:** le ratifiche di Mauro incise come «22/08/2026» compaiono in referti scritti il 22/08 fra le 15:36 e le 16:46, cioe' **prima** di quella finestra — ma **nessun documento registra QUANDO Mauro le ha pronunciate**: l'evento di ratifica vive in chat, non in un artefatto datato. ⛔ **La data resta come scritta; il referee non l'ha chiesta a Mauro e CC non la inventa.** | CC (misure) + referee (rilievo) | `git show -s` su `9edc120` e `4629ee9` · `stat` sui referti in `HANDOFF/` · `HANDOFF/MISURE_CC_2026-08-23_A190-DATA-REALE-E-DUE-REGOLE.md` | attiva | — |
```

---

## §2 · BOX5 — due regole che prima non esistevano

### (a) La data nei nomi d'archivio — inserita in coda a R-δ §3

```
⚠️ QUANDO LA DATA DELLA VERSIONE E QUELLA DEL COMMIT DIVERGONO —
ratificato dal referee 23/08/2026, prima occorrenza `9edc120`.
Nel nome della stampa d'archivio va LA DATA CHE IL DOCUMENTO DICHIARA DI
SE', non la data di estrazione ne' quella del commit: lo sha7 nel nome
identifica gia' il commit. ⇒ un nome non deve mai contraddire l'intestazione
del file che nomina.
```

### (b) Le stringhe di controllo — nuova sezione R-δ §4-bis

```
### 4-bis · STRINGHE DI CONTROLLO D'INTEGRITA'

⚠️ STRINGHE DI CONTROLLO D'INTEGRITA' — regola di CC, ratificata 23/08/2026
dopo tre morsi in un giorno solo (A182, A185, A187).
Una stringa di controllo va scelta COPIANDOLA da UNA RIGA SOLA del file,
corta, senza ritorni a capo — oppure la sonda va eseguita sul testo
APPIATTITO (ritorni a capo sostituiti da spazi) prima di contare.
⛔ Una stringa che cade a cavallo di un a capo rende ZERO su un file
perfettamente integro: e' un falso allarme, non una mutilazione.

⚠️ **Quarto morso, misurato il 23/08 mentre si incideva questa regola:** la sonda
ID per contenuto su `A190` non rendeva l'unico hit reale (`HANDOFF/MISURE_CC_2026-08-21_A158-COMMIT-LIBRO-v58.md`),
perche' la riga di tabella che lo contiene va a capo. La stessa ricerca sul testo
appiattito lo trovava. ⇒ **la regola vale anche per le sonde ID, non solo per i
controlli d'integrita' dei referti.**
```
**[A] Il quarto morso l'ho aggiunto io al testo del mandato**, perché è successo mentre
scrivevo la regola e ne estende la portata alle sonde ID. Lo dichiaro come aggiunta mia.

### (c) ✅ Il documento era GIUSTO, la mia memoria no — non ho toccato nulla

**[M] R-δ §2 dichiara, verbatim:** `| canonici LIBRO · BUGS · BOX3 · BOX5 | **radice**, in
place | `LIBRO_MASTRO/` `BUGS_QBEATS/` `BOX3_Codice/` `BOX5_Test/` |`
**[M] E le stampe stanno davvero lì:** `BOX5_Test/BOX5_V29_…` e `BOX5_Test/BOX5_V30_…`,
nella radice, senza sottocartella.
⇒ **[A] Il percorso sbagliato («`BOX5_Test\LUGLIO\`») era solo nella mia memoria.
Il documento non si tocca, come prescritto.**

---

## §3 · VERSIONI — regola letta alla sua sede

**[M] Sede: `LIBRO_MASTRO_QBEATS.md`, R7 punto 2**, verbatim:
> «**Versione = puntatore.** Se il contenuto di un documento cambia, il suo numero di
> versione DEVE cambiare. Un numero non bumpato è peggio di un puntatore rotto: sembra
> sano, non lo è.»

⇒ **[M] Applicata:** LIBRO **60 → 61**, BOX5 **V30 → V31**. Nessun altro file toccato,
quindi nessun altro bump.

---

## §4 · CANCELLO, COMMIT, CONSEGNA

### Le misure prima del commit

| file | byte | righe | CR | faccia | sha256 |
|---|---|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | 285405 | 525 | **525** | CRLF puro | `7a93fccffa357e855033bea2ccddb0a81b115f97914fc1696b49d77789be4f55` |
| `BOX5_QBEATS.md` | 72709 | 850 | **0** | LF | `10d5cb1122b6b6a5b29585ec9784dfec7d2256ef5e75126404fc47ff947d9558` |

**[M] I tre file VIETATI: 0 righe di diff ciascuno** — BOX3, BUGS, SCALETTA intatti.

### Il cancello dello stage

**[M] Due `git add` per NOME**, mai `-A`, mai `.`, mai glob.
File in stage: **2**, esattamente i due attesi · estranei: **0** · `ios_app` in stage: **0**
· `core_engine`: **0** · diffstat: **`+34 −4`** · **270 non tracciati rimasti fuori**.

### Il commit

```
sha       : 91809bb1cf9b914c070f4a0f315982021b3cbb59
parent    : 9edc120eafd2999bf915f974e8b204492e7931f5
autore    : Mauro Martintoni <di_tutto@icloud.com>
committer : Mauro Martintoni <di_tutto@icloud.com>
data      : 2026-08-23T10:09:14+02:00
```
```
 BOX5_QBEATS.md         | 31 ++++++++++++++++++++++++++++++-
 LIBRO_MASTRO_QBEATS.md |  7 ++++---
 2 files changed, 34 insertions(+), 4 deletions(-)
```
**[M] `Co-Authored-By` nel messaggio: 0.**

⚠️ **[M] Un dettaglio che dichiaro:** git ha interpretato l'ultima riga del messaggio,
`Referto: HANDOFF/…`, **come un trailer** — ha la forma `Chiave: valore`. Il commit
precedente `9edc120` aveva `trailers: []`. **[A] Non viola la regola di casa, che vieta
`Co-Authored-By` e non i trailer in genere**, ed è anzi un puntatore utile; ma è una
differenza di forma rispetto a tutti i commit precedenti, e non l'avevo prevista.

### Push

```
To https://github.com/19Bullfrog78/Q-BEATS
   9edc120..91809bb  master -> master
```
**[M] Verifica con `ls-remote`, non sulla parola del comando:**
locale `91809bb1cf9b914c070f4a0f315982021b3cbb59` = remoto **✅ COINCIDONO**.

### I depositi su E: — con la regola §2(a) appena incisa

**[M] Applicazione della regola:** LIBRO dichiara di sé `61 (23/08/2026)`, BOX5 dichiara
`V31 — 23/08/2026`. **Qui la data del documento e quella del commit COINCIDONO** (entrambe
23/08), quindi la regola non discrimina — ma è stata applicata come scritta: **la data nel
nome è quella che il documento dichiara**.

**[M] Nomi verificati liberi prima di scrivere**, positivo tarato copiando dal file reale
(il V30 è stato trovato ⇒ la sonda vede). **[M] Estrazione DAL BLOB**, mai dal disco.

| deposito | byte | CR | sha256 |
|---|---|---|---|
| `LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v61_2026-08-23_91809bb.md` | 284880 | 0 | `4ea898b120be981d19203ada6faf71a882d05b82aea4c5537e12a99fb94f84a8` |
| `BOX5_Test\BOX5_V31_2026-08-23_91809bb.md` | 72709 | 0 | `10d5cb1122b6b6a5b29585ec9784dfec7d2256ef5e75126404fc47ff947d9558` |

**[M] Entrambe IDENTICHE AL BLOB byte-per-byte.** ⛔ **Su Drive non ho scritto nulla.**

### CI — per NOME, mai «verde» secco

| workflow | esito su `91809bb` |
|---|---|
| **iOS Signed Build** | ✅ **success** — al momento della prima stesura era `in_progress` (avviato `2026-08-23T08:09:34Z`); **riverificato a esito concluso prima della consegna** |
| **F1 — Build Check** | ⛔ **NON PARTITO** (ultima: `bfc9228`, 31/07, **failure**) |
| **Build LinkHut Diagnostic** | ⛔ **NON PARTITO** (ultima: `a038ee2`, 22/05, success) |

✅ **[M] Riverificato: `iOS Signed Build` è `completed / success` su `91809bb`**, come su
`9edc120`. ⚠️ **[A] «La CI è verde» resterebbe comunque una frase falsa: verde è UN
workflow su tre configurati**, e gli altri due non partono da luglio e da maggio.

### Stato finale

```
HEAD locale : 91809bb1cf9b914c070f4a0f315982021b3cbb59
HEAD remoto : 91809bb1cf9b914c070f4a0f315982021b3cbb59
modificati  : 0 · in stage : 0 · non tracciati : 270
ios_app     : 0 · core_engine : 0
```

---

## Cosa NON ho fatto

⛔ Nessun tocco a `ios_app/` né `core_engine/` · **nessun file rinominato**, né le cinque
stampe di A188 né i referti · **BOX3, BUGS e SCALETTA non toccati** · nessuna data
preesistente riscritta — il misurato è stato **aggiunto accanto** · nessuna scrittura su
Drive · nessun `git add -A`, `.` o glob · non ho letto il congedo del referee.

---

### Controllo d'integrità di QUESTO file

⚠️ **Stringhe scelte secondo la regola incisa oggi: copiate da UNA RIGA SOLA, corte, senza
ritorni a capo.**

`91809bb1cf9b914c070f4a0f315982021b3cbb59` · `9edc120..91809bb` ·
`2026-08-23T09:46:57+02:00` · `15h44m` · `BOX5_V31_2026-08-23_91809bb.md` ·
`quarto morso` · `in_progress` · e il marcatore di fine qui sotto.

---

*A190-FINE — MISURE CC 23/08/2026 COMPLETO*
