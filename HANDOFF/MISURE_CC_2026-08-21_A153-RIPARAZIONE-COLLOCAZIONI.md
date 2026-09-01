# MISURE CC — A153-RIPARAZIONE-COLLOCAZIONI

**ID ricevuto e verificato: `A153-RIPARAZIONE-COLLOCAZIONI`.**
Da: CC · A: Mauro, + referee · 21/08/2026

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 · §4 · §5 e la
chiusura `FINE MANDATO A153`. Nessun taglio.

⛔ **NESSUN COMMIT. ZERO modifiche a file tracciati.** HEAD invariato a
`638b73835f7ac52fdcd01dd94dc23f81ce818b2d`.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE DUE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. ✅ RIPARATO. Ogni stampa sta ora dove stanno le sue sorelle**, su E: e su
Drive, e **zero copie sono rimaste fuori posto** — verificato con sonda e
controllo positivo. Le tre cartelle che avevo inventato non esistono più.

**2. ⛔ NESSUNA RIMOZIONE È AVVENUTA PRIMA DELLA SUA VERIFICA.** Dieci operazioni
distruttive in questo giro — 4 spostamenti, 3 orfani, 3 file su C:, 2 cartelle — e
**ognuna preceduta da un `cmp` exit 0 più byte e sha256 contro i valori di A151**.
Nessuna in blocco, nessuna alla cieca.

---

## §0 · L'ID · §1 · LO STATO

**[M]** Sonda stretta, due supporti, due forme:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A153** | **0** | **0** | **0** | **0** | ⇒ **LIBERO** |
| A154 | 0 | 0 | 0 | 0 | controllo negativo |
| A150 | 0 | 3 | 0 | 3 | controllo positivo |
| A151 | 1 | 2 | 1 | 2 | controllo positivo |
| A152 | 1 | 2 | 1 | 2 | controllo positivo |

⛔ **`A153` rende zero anche per contenuto**, su entrambi i supporti.

**[M]** `HEAD locale = HEAD remoto = 638b73835f7ac52fdcd01dd94dc23f81ce818b2d`.

---

## §4(b) · IL RILIEVO PRIMA DI TOCCARE — nessuna sorpresa

**[A] Il mandato dice di fermarmi se dentro le cartelle c'è qualcosa di inatteso.
Non l'ho dato per scontato: l'ho contato.**

| cartella | `_638b738` | `_c46c0d4` | **ALTRO** |
|---|---:|---:|---:|
| `E:\…\STAMPE_PER_PROGETTO_2026-08-21\` | 3 | 3 | **0** |
| `C:\…\ANTIGRAVITY\STAMPE_PER_PROGETTO_2026-08-21\` | 3 | 0 | **0** |

✅ **Zero elementi estranei.** Il gate del §4(b) chiude.

**[M] E ho verificato che i tre orfani fossero davvero solo un problema di nome:**
`cmp` fra ciascun `_c46c0d4` e il corrispondente `_638b738` → **contenuto
identico su tutti e tre**. Differiva **solo il nome**.

---

## §4(a) · GLI SPOSTAMENTI — scrivi, verifica, POI rimuovi

**[M] Quattro spostamenti. Per ciascuno: `cp` → `cmp` exit 0 → byte e sha256
contro A151 → `rm` dell'origine, e riverifica che l'origine sia sparita.**

| # | gamba | stampa | da | a | verifica |
|---:|---|---|---|---|---|
| 1 | E: | BUGS | `STAMPE_PER_PROGETTO…\` | `BUGS_QBEATS\` | `cmp` 0 · 338 704 · `6a26367a…` ✅ |
| 2 | E: | LIBRO | `STAMPE_PER_PROGETTO…\` | `LIBRO_MASTRO\` | `cmp` 0 · 276 359 · `ec643df4…` ✅ |
| 3 | E: | SCALETTA | `STAMPE_PER_PROGETTO…\` | `HANDOFF\` | `cmp` 0 · 66 467 · `d1d8b396…` ✅ |
| 4 | Drive | SCALETTA | `Qbeats\` (radice) | `Qbeats\HANDOFF\` | `cmp` 0 · 66 467 · `d1d8b396…` ✅ |

⛔ **BUGS e LIBRO su Drive NON sono stati toccati:** erano già nella collocazione
giusta da A151. Li ho solo **riletti** per confermarne l'integrità.

⚠️ **[M] Ogni destinazione è stata controllata come inesistente PRIMA di
scriverci**, per non sovrascrivere in silenzio qualcosa che non avevo visto.

---

## §4(c) · GLI ORFANI DI A150 — il gate prima della cancellazione

⛔ **Il mandato impone di verificare che le tre buone esistano e siano integre
PRIMA di rimuovere gli orfani. L'ho fatto su SEI copie, non su tre.**

| copia da verificare | esito |
|---|---|
| `E:\…\BUGS_QBEATS\…_638b738.md` | ✅ esiste e integro |
| `E:\…\LIBRO_MASTRO\…_638b738.md` | ✅ esiste e integro |
| `E:\…\HANDOFF\SCALETTA…_638b738.md` | ✅ esiste e integro |
| `I:\…\Qbeats\BUGS_QBEATS\…_638b738.md` | ✅ esiste e integro |
| `I:\…\Qbeats\LIBRO_MASTRO\…_638b738.md` | ✅ esiste e integro |
| `I:\…\Qbeats\HANDOFF\SCALETTA…_638b738.md` | ✅ esiste e integro |

⇒ **SEI SU SEI. Il gate chiude.** Solo allora ho rimosso:

```
E:\…\STAMPE_PER_PROGETTO_2026-08-21\BUGS_QBEATS_v58_2026-08-21_c46c0d4.md
E:\…\STAMPE_PER_PROGETTO_2026-08-21\LIBRO_MASTRO_QBEATS_v57_2026-08-21_c46c0d4.md
E:\…\STAMPE_PER_PROGETTO_2026-08-21\SCALETTA_v11_2026-08-21_c46c0d4.md
```

⚠️ **[A] Perché era giusto toglierli e non archiviarli.** Erano **contenuto
identico** alle stampe buone, ma il nome dichiarava `c46c0d4` invece di
`638b738`. Un file che porta nel nome un commit che non è quello del suo
contenuto **non è una copia di sicurezza: è una trappola a scoppio ritardato**.
Chi li avesse trovati fra sei settimane non avrebbe avuto modo di sapere quale
fosse buono — e i byte, che sono l'unico giudice, in questo caso **non
discriminavano**, perché erano gli stessi.

---

## §4(b) · LE CARTELLE INVENTATE — rimosse solo da vuote

| cartella | contenuto residuo al momento della rimozione | esito |
|---|---:|---|
| `E:\…\FILE X CLAUDE.MD\STAMPE_PER_PROGETTO_2026-08-21\` | **0 elementi** | rimossa ✅ |
| `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\STAMPE_PER_PROGETTO_2026-08-21\` | **0** dopo aver tolto le 3 stampe | rimossa ✅ |

⛔ **Le tre stampe su C: sono state rimosse solo dopo che il gate del §4(c) aveva
già confermato le sei copie integre su E: e Drive.** Non erano nel posto
sbagliato: erano **di troppo**, perché il censimento di A152 ha misurato **zero**
stampe versionate nel repo per tutti e tre i canonici.

---

## §3 · I NOMI — minuscola, come deciso dal referee

⛔ **Non ho rinominato nulla.** `_v58_` e `_v57_` restano minuscoli, e la ragione
è quella del mandato: **i tre file sono già caricati nel Progetto con la
minuscola**, e cambiarli creerebbe una terza convenzione per lo stesso contenuto.

⚠️ **[M] Conseguenza visibile, da sapere e non da riparare:** nella cartella
`BUGS_QBEATS\` il file nuovo `_v58_` sta ora accanto a **otto** stampe `_V…`
maiuscole; in `LIBRO_MASTRO\` accanto a **diciassette**. **È voluto.** La
maiuscola delle storiche è storia: si marca, non si riscrive.

✅ **La SCALETTA non ha questo problema**: le sue otto precedenti in `HANDOFF\`
usano già la **`v` minuscola**. Era solo la cartella a essere sbagliata.

---

## §5 · DOVE SONO ORA — i percorsi completi

### `BUGS_QBEATS_v58_2026-08-21_638b738.md` · **338 704 byte** · `6a26367a8f377420659f0fc3130b2b1d6236457184879bf00de8d95dd1392e49`

```
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\BUGS_QBEATS\BUGS_QBEATS_v58_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\BUGS_QBEATS\BUGS_QBEATS_v58_2026-08-21_638b738.md
```

### `LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md` · **276 359 byte** · `ec643df46209b7ce50feabc3a41860b6f155efa031d7506105d1f8af45fdea8c`

```
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_v57_2026-08-21_638b738.md
```

### `SCALETTA_v11_2026-08-21_638b738.md` · **66 467 byte** · `d1d8b396cb7eefbe2e979fc9f3ae0a7695ca5031947b035213aeccf1a68f361a`

```
E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\SCALETTA_v11_2026-08-21_638b738.md
I:\Il mio Drive\Qbeats\HANDOFF\SCALETTA_v11_2026-08-21_638b738.md
```

**[M] Tutti e sei i byte e gli sha256 combaciano con quelli dichiarati in A151.**
Lo spostamento non ha cambiato un byte.

### ⛔ LA SONDA: esistono copie fuori dalle collocazioni?

**[M]** Cercate tutte le occorrenze di `_638b738` su **E: · Drive · C:**:

```
E:    3      Drive 3      C:    0
FUORI dalle collocazioni del §2 (BUGS_QBEATS\ · LIBRO_MASTRO\ · HANDOFF\):  0
```

⛔ **CONTROLLO POSITIVO nella stessa forma**, perché uno zero non tarato non è uno
zero: la **stessa** sonda rende **6** file **dentro** le collocazioni. **La sonda
vede: lo zero fuori posto è vero.**

**[M] Orfani `_c46c0d4` residui: ZERO**, su tutti e tre i supporti. ⛔ Controllo
positivo: la stessa stringa `c46c0d4` rende **4** file per **contenuto** dentro
`HANDOFF\` (sono i referti che la citano). **La sonda vede quella stringa: lo zero
sui nomi è vero.**

---

## ⛔ IL PERIMETRO — cosa NON è stato toccato, misurato

| oggetto | prima | ora | atteso |
|---|---:|---:|---|
| `E:\…\BUGS_QBEATS\` totale file | 48 | **49** | +1, solo la stampa nuova ✅ |
| `E:\…\LIBRO_MASTRO\` totale file | 21 | **22** | +1 ✅ |
| `E:\…\HANDOFF\` stampe `SCALETTA_v*` | 8 | **9** | +1 ✅ |
| `I:\…\Qbeats\HANDOFF\` stampe `SCALETTA_v*` | 3 | **4** | +1 ✅ |
| cartelle sotto `FILE X CLAUDE.MD\` | 21 | **20** | −1, la mia rimossa ✅ |

**[M] Le stampe storiche sono intatte**, controllate a campione sui tre estremi:
`BUGS_QBEATS_V51` = 297 453 byte · `LIBRO_MASTRO_QBEATS_V55` = 262 964 byte ·
`SCALETTA_v9` = 54 558 byte. **Invariate.**

⛔ **[M] La ritirata di CD su Drive NON è stata toccata:**
`I:\Il mio Drive\Qbeats_IN_CD\_RITIRATA-NUMERI__non-usare…html` — esiste,
**66 667 byte**, sha `4687df3647caeda9…`, **invariata rispetto ad A144**. Non ho
scritto nulla dentro `Qbeats_IN_CD\`.

⛔ **Nessuna cartella nuova creata in nessuna destinazione.**

---

## COSA HO FATTO, IN SINTESI

**Spostati (4):** BUGS, LIBRO e SCALETTA su E: · SCALETTA su Drive.
**Rimossi (8):** 3 orfani `_c46c0d4` · 3 stampe da C: · 2 cartelle inventate.
**Non toccati:** BUGS e LIBRO su Drive (erano già a posto) · le 48+21+8 stampe
storiche · la ritirata di CD · qualunque file tracciato.

---

## IN CODA

1. **La `v` minuscola convive con le `V` maiuscole storiche** — deciso dal
   referee, dichiarato qui perché non venga «uniformato» per igiene. Un giro suo,
   se mai.
2. ⚠️ **Restano valide tutte le pendenze del congedo**
   (`CONGEDO_CC_2026-08-21_SERA.md`), e in particolare: **il LIBRO MASTRO è fermo
   al 19/08**. La stampa `v57` appena collocata porta un registro che **non sa
   cosa è successo dopo il 19** — inclusi i quattro commit di oggi e il collaudo
   device.
3. **Il 7/7 di A139 vive ancora solo in chat** — settima segnalazione. Il posto è
   misurato in A146: `LIBRO` Sezione 2, riga datata.
4. ⚠️ **[A] La lezione di A151, che vale oltre questo giro:** avevo misurato il
   perimetro **su Drive** con cura e **su E: no** — ho applicato la disciplina su
   una gamba e non sull'altra, e ho inventato una cartella dove ne esistevano già
   tre. **Una regola applicata a una sola destinazione non è una regola: è
   un'abitudine locale.**

---

*A153-FINE*
