# MISURE CC — A144-REV6-DEPOSITO-E-BASELINE

**ID ricevuto e verificato: `A144-REV6-DEPOSITO-E-BASELINE`.**
Da: CC · A: referee, + Mauro · 21/08/2026
Ancoraggio: **HEAD = `981e109477937523fc8fe00c7e6d62f6c2dd8902`**, locale = remoto.

⛔ **NESSUN COMMIT.** Diff in `HANDOFF/DIFF_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.txt`.
Aspetto ratifica del referee e **poi** l'OK di Mauro.

🔎 **Integrità del mandato: PASSA.** Visti §0 · §1 · §2 · §3 · §4 · §5 · §6 e la
chiusura `FINE MANDATO A144`. Nessun taglio. **A143 trattato come annullato:**
non ho ripreso nulla, ho rifatto tutto da capo.

⚠️ **A139 preso in carico come collaudato device 7/7 il 21/08**, tasto «Shows»
compreso. Non lo riporto più pendente. Resta solo l'iPad.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Nessuna condizione di stop del §6 è scattata.** ID libero · HEAD combacia ·
peso/sha/righe/CR/NUL tornano tutti · **una sola** corrispondenza per peso · la
riga d'indice di CD c'è ed è utilizzabile · la riga del livello 1 è **esattamente**
quella dichiarata · il rename non ha cambiato un byte.

**2. ⚠️ Ho preso UNA decisione di collocazione, e la dichiaro.** CD scrive «da
aggiungere **in coda**». Ho messo la riga rev6 **prima** della riga catch-all
`| gli altri |`, non dopo. Motivo e alternativa sotto: si sposta in una riga.

**3. 🚨 Il debito che avevo alzato in A143 è ora PEGGIORATO, e non l'ho riparato
(non è autorizzato).** `readOnlyBadge` era già una seconda copia della specifica;
da oggi anche la **regola di ancoraggio** vive in due punti e può divergere.

---

## §0 · L'ID

**[M]** Sonda stretta (perimetro documentale, `*.md`/`*.txt`, binari esclusi,
confine di parola), due supporti:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A144** | **0** | **0** | **0** | **0** | ⇒ **LIBERO** |
| A145 | 0 | 0 | 0 | 0 | controllo negativo |
| A141 | 3 | 3 | 3 | 3 | controllo positivo |
| A142 | 2 | 2 | 2 | 2 | controllo positivo |
| A143 | 0 | 1 | 0 | 1 | (il mandato annullato, citato nel referto A142) |

⛔ **Ispezione del contesto:** `A144` rende **zero anche per contenuto** su
entrambi i supporti — non c'è nemmeno una menzione da interpretare. È il caso più
pulito dei sei giri di oggi.

---

## §1 · LO STATO

**[M]** Letto con `git rev-parse HEAD` e `git ls-remote origin master`, **mai**
`rev-parse origin/master`:

```
locale : 981e109477937523fc8fe00c7e6d62f6c2dd8902
remoto : 981e109477937523fc8fe00c7e6d62f6c2dd8902
atteso : 981e109477937523fc8fe00c7e6d62f6c2dd8902
```

---

## §2 · SELEZIONE DEL FILE — PER PESO

### Il percorso, dichiarato da me

**[M] Sorgente:**
```
I:\Il mio Drive\Qbeats_IN_CD\2026-08-21_QLive-Shows_rev6__SUPERSEDE-rev5-SU-2-SELETTORI__anco.html
```

### (a)(b) Selezione per peso — UNA SOLA corrispondenza

**[M]** `find … -maxdepth 1 -type f -size 87570c` dentro la sola cartella
sorgente:

```
87570 byte  2026-08-21_QLive-Shows_rev6__SUPERSEDE-rev5-SU-2-SELETTORI__anco.html
CORRISPONDENZE = 1
```

✅ **Una sola.** Non zero, non più di una: non ho dovuto scegliere.

⛔ **CONTROLLO POSITIVO nella forma esatta della sonda.** La stessa
`find -size` interrogata su un peso noto-presente rende:
```
66667c -> _RITIRATA-NUMERI__non-usare__2026-08-21_QLive-Shows_rev6__attendere-versione-corretta-21-08.html
```
⇒ la sonda **vede**. Un «uno» reso da una sonda cieca varrebbe quanto uno zero.

⚠️ **CONTROPROVA CHE MOSTRA PERCHÉ IL NOME NON POTEVA BASTARE.** La sonda per
nome vietata dal mandato — `-iname '*rev6*'` — rende **DUE** file, e il secondo
si chiama letteralmente *«RITIRATA-NUMERI \_\_ non-usare \_\_ … attendere
versione corretta»*. **[A] Non è un rischio teorico: è il caso in cui una sonda
per nome avrebbe consegnato al repo un file che CD ha esplicitamente ritirato.**

### (c) I sette valori — tutti tornano

**[M]**

| grandezza | misurato | atteso | esito |
|---|---:|---:|---|
| byte | **87 570** | 87 570 | ✅ |
| righe | **542** | 542 | ✅ |
| CR | **0** | 0 | ✅ |
| NUL | **0** | 0 | ✅ |
| apre | `<!doctype html>` | idem | ✅ |
| chiude | `…</body></html>` | `</html>` | ✅ |
| sha256 | `ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3` | idem | ✅ |

⛔ **CONTROLLO POSITIVO SUGLI ZERI di CR e NUL**, perché uno zero non misurato non
è un fatto: la **stessa** sonda `tr -cd` rende **542 LF** sullo stesso file, e
**526 CR** su `QLiveShowDetailView.swift` (che è CRLF). ⇒ La sonda non è cieca:
gli zeri sono veri.

✅ **[A] Tre misure indipendenti sullo stesso file, tre attori.** Il sha256 che ho
letto in A143, quello che il referee ha verificato, e quello che ho rimisurato
oggi coincidono. Il transito è pulito, e non è un'inferenza: è la stessa impronta
prodotta tre volte.

### (d) La ritirata — non toccata

**[M]** `_RITIRATA-NUMERI__non-usare__…html` esiste, **66 667 byte**, sha
`4687df3647caeda9…`, **invariata**. Non copiata, non cancellata, non rinominata.
Resta come atto.

---

## §3 · DEPOSITO

**[M] Destinazione, dichiarata da me:**
```
C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\DESIGN\QLive_Nav\
  2026-08-21_QLive-Shows_rev6__SUPERSEDE-rev5-SU-2-SELETTORI__ancoraggio-Read-only-e-ritiro-4px_390x844.html
```

**[M] Verificato PRIMA di copiare che il nome di destinazione non esistesse**:
non esisteva, nessuna sovrascrittura alla cieca.

**[M] `cmp` sorgente↔deposito: exit 0 — byte identici.**

**[M] Rimisura DOPO la copia e il rename** — il punto che il §3 chiede
esplicitamente:

| grandezza | dopo il deposito | atteso (§2) |
|---|---:|---:|
| byte | **87 570** | 87 570 |
| righe | **542** | 542 |
| CR | **0** | 0 |
| NUL | **0** | 0 |
| sha256 | `ceeeb015edd0ebe83d94f928e9e009c43828e5891be39222a4e30c97e409f8e3` | identico |

✅ **Il rename NON ha cambiato un byte.** Rinominare non è emendare, e ora è
misurato, non asserito.

⛔ **Contenuto intatto: non ho emendato nulla del foglio di CD.** Le cinque
autocitazioni errate che CD stesso dichiara nel pannello ④ restano **dentro il
foglio come le ha scritte**: si superano con una nota, non si modificano a valle.

---

## §4 · INDICE NORMATIVO — `DESIGN/QLive_Nav/README.md`

**[M] Faccia dichiarata:** `DESIGN/**` è `-text` in `.gitattributes` ⇒
**disco = blob**. Misurato prima: 6 872 byte, **CR = 0**, LF = 86. Dopo la
modifica: 8 892 byte, **CR = 0**, LF = 96. **Scritto in LF**, coerente con
`-text`. *(Diverso dai file Swift, che portano CRLF — vedi §5.)*

### (a) La riga della rev6 — scritta da CD, non da me

✅ **C'è ed è utilizzabile.** Sta in fondo al pannello ④ del foglio, in un
`callout` intitolato *«Riga per l'INDICE NORMATIVO (README della cartella, da
aggiungere in coda)»*. **L'ho usata verbatim.**

⛔ **Unico adattamento, di FORMATTAZIONE e non di testo:** i tag `<b>…</b>`
dell'HTML resi come `**…**` markdown, come vuole il documento di destinazione.
Zero parole cambiate, zero aggiunte, zero tolte.

### ⚠️ LA DECISIONE DI COLLOCAZIONE CHE HO PRESO — dichiarata perché la ribalti in una riga

CD scrive «da aggiungere **in coda**». **L'ho messa PRIMA della riga
`| gli altri |`**, non dopo.

**[A] Motivo:** `| gli altri |` non è una riga come le altre, è la **riga
catch-all** della tabella («storico di derivazione — vedi Derivazione più
sotto»). Per costruzione una catch-all sta ultima: mettere un file specifico
**dopo** di essa la trasformerebbe in una riga qualsiasi e la tabella smetterebbe
di chiudere. Leggo «in coda» come «ultima fra le righe di file specifici».

⛔ **Non ho spostato nessuna riga per ottenerlo**: l'inserimento è puramente
additivo. Ordine verificato dopo la scrittura — Q7-Q16 · rev5 · NOTA · rev4 ·
rev3 · rev2-BUONA · Exit-in-Play · **rev6** · gli altri.

**Se il referee legge «in coda» alla lettera**, si sposta di una riga e nient'altro
cambia.

### (b) rev5 — MARCATA superata in parte, NON riscritta

⛔ **Zero parole riscritte sopra: si marca.** Ho aggiunto in coda alla cella
esistente:

> ⛔ **MARCATURA 21/08 (A144) — SUPERATA IN PARTE DALLA rev6, NON ABOLITA.** Zero
> parole riscritte sopra: si marca. La rev6 la supera sui **due soli selettori**
> che nomina — **ancoraggio del badge `.dhrow`** e **ritiro del `padding:0 4px` su
> `.navbar .back`**. **Su tutto il resto la rev5 resta IN VIGORE**, parola per
> parola.

### (c) Nessun'altra riga toccata

**[M] Verificato dopo la scrittura**, con asserzioni nello script:
`rev2-BUONA` è presente e **NON rinominata**; la clausola **«NON RINOMINARE: un
canonico lo cita con questo nome»** è intatta.

### (d) La regola di trasporto verificata oggi

Aggiunta **accanto** al blocco esistente del 20/08 — il cartello va dove morde,
non in fondo al documento:

> ⚠️ **Seconda faccia della stessa regola, verificata il 21/08 sulla rev6.** Il
> download ha troncato il **NOME** (tagliato dentro la parola `ancoraggio`) ma
> **non i BYTE**: il file era integro. ⛔ Una sonda per nome su `*rev6*` rendeva
> **DUE** file, uno dei quali **RITIRATO da CD**; il nome non discriminava. La
> verifica è passata **solo perché CD aveva dichiarato il PESO** (87 570 byte),
> che ha reso **una sola** corrispondenza, confermata poi da sha256, righe, CR e
> NUL. ✅ **I byte sono l'unico giudice, mai il nome.** Rinominare al deposito
> **non è emendare**: i byte non cambiano, e va rimisurato dopo la copia.

---

## §5 · LA RIGA DI CODICE

**[M] Faccia dichiarata:** i file Swift **non** sono coperti da `.gitattributes`
⇒ **CRLF su disco, LF nel blob**. Ho scritto preservando CRLF: dopo la modifica
**CR = LF = 548**, zero righe miste.

### ⛔ IL CANCELLO: la riga del livello 1, RILETTA E INCOLLATA PRIMA DI SCRIVERE

**[M] `ios_app/QBeats/UI/QLive/QLiveShowsView.swift`, `scrhead`** — verbatim:

```swift
    // MARK: - Header (.scrhead §CSS) — h1 + badge .ro (NON .cnt: Q-Live è read-only)

    private var scrhead: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Shows")
                .font(.custom("Inter-ExtraBold", size: 29))
                .tracking(-0.6)
                .foregroundColor(.white)
            Spacer(minLength: 0)
            roBadge
        }
        .padding(.top, 8)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }
```

✅ **Il livello 1 porta `HStack(alignment: .firstTextBaseline)`. Corrisponde
esattamente a quanto il mandato dichiara. Il cancello passa: non ho dovuto
fermarmi.**

### La modifica — una riga

```
-            HStack(spacing: 10) {
+            HStack(alignment: .firstTextBaseline, spacing: 10) {
```

🚨 **[M] UN'INSIDIA CHE HO TROVATO PRIMA DI SCRIVERE, e che vale la pena non
perdere:** `HStack(spacing: 10)` compare **DUE volte** in
`QLiveShowDetailView.swift`. La seconda (`:398` prima della modifica) è dentro
**`startfoot`**, cioè il pulsante **START SHOW**. Una sostituzione testuale su
quella stringa avrebbe cambiato **anche il pulsante di avvio dello show**, in
silenzio e fuori perimetro.

⛔ **Ancorato invece sulla coppia `VStack(alignment: .leading, spacing: 7)` +
`HStack(spacing: 10)`, che è unica**, e lo script si nega la scrittura se il
conteggio non passa da 2 a 1. **[M] Verificato dopo: `startfoot` è intatto**, la
sua riga è ancora `HStack(spacing: 10) {`.

### La premessa sul badge, misurata invece che assunta

Il mandato dichiara (verificato dal referee) che `readOnlyBadge` ha **solo padding
simmetrico, nessuno scostamento verticale**, e che il `margin-top:4px` del foglio
nel codice non esiste. **[M] Rimisurato**, perché è la premessa su cui poggia
«zero movimento»:

```swift
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
```

⇒ **`.vertical` è simmetrico**, e uno sweep su `offset|padding(.top|margin` dentro
il blocco rende **zero**. **La premessa regge.**

### Cosa NON ho toccato

⛔ `readOnlyBadge` · `spacing: 10` (invariato, = `.dhrow` gap 10) · il titolo ·
la riga `.mt` sotto · il `padding:0 4px` sul `.back`, che la **rev6 RITIRA** e
che quindi **non si costruisce** — chiude la domanda aperta che avevo lasciato in
A139.

### Il commento inciso in loco

Dichiara i tre punti richiesti: provenienza **rev6 citata per SELETTORE `.dhrow`**
(mai per riga, perché il foglio cresce a ogni taglio) · **stessa espressione del
livello 1 citata per simbolo** (`QLiveShowsView.swift`, `scrhead`) · e **la
ragione portante di CD**: con lo stesso ancoraggio sulle due schermate il badge
**non si muove** quando il titolo va a due righe, perché prima a spostarlo era il
**contenuto** — l'allineamento `.center` ricentra il badge sull'altezza del
titolo, che a due righe raddoppia.

✅ E dichiara che **l'esito è ZERO movimento e non dipende da nessuna delle cifre
che CD ha ritirato** (origine y · movimento Ⓓ 13,97 · lh 1.05→1.12): si cancellano
fra loro, il risultato regge anche senza di esse.

---

## 🚨 IL DEBITO — dichiarato, non riparato

**[A] La mia obiezione di A143 era sul debito, non sulla fattibilità, e il
referee ha ragione: è una riga sola e non tocca nulla di `private`.** Ma il debito
non è sparito — **è peggiorato in questo stesso commit**, e voglio che sia agli
atti prima che qualcuno lo scopra a proprie spese.

`readOnlyBadge` in `QLiveShowDetailView` è una **SECONDA COPIA** della specifica:
l'originale in `QLiveShowsView` è `private` e irraggiungibile — il file lo dichiara
già, sopra la dichiarazione del badge.

⇒ **Da oggi anche la REGOLA DI ANCORAGGIO vive in due punti.** `.firstTextBaseline`
è scritto in `QLiveShowsView.scrhead` **e** in `QLiveShowDetailView.dhead`.
**Possono divergere senza che il compilatore dica nulla**, esattamente come la
specifica del badge. L'ho segnalato nel commento in loco, **non l'ho riparato**:
non è autorizzato qui, e la cura (rendere non-`private` l'originale, o estrarre un
componente comune) è un atomo suo.

---

## CONTROLLI DI INTEGRITÀ

| controllo | esito |
|---|---|
| file Swift, a-capo | **CR = LF = 548** ⇒ CRLF uniforme, zero righe miste |
| file Swift, graffe | `{` = `}` = 50, delta **0** |
| file Swift, `startfoot` | **intatto** — la sua `HStack(spacing: 10)` c'è ancora |
| README, a-capo | **CR = 0**, LF = 96 ⇒ LF puro, coerente con `-text` |
| README, ordine tabella | nessuna riga spostata; rev6 inserita, `gli altri` resta ultima |
| README, `rev2-BUONA` | presente, **non rinominata**, clausola NON RINOMINARE intatta |
| deposito rev6 | `cmp` exit 0 · sha256 identico prima e dopo il rename |
| ritirata | **non toccata**, 66 667 byte invariati |

⛔ **Non compilato**: niente Xcode qui. La prova è `iOS Signed Build` **dopo** il
commit. I controlli sopra sono **necessari, non sufficienti**.

---

## §6 · CONSEGNA

**Diff:** `HANDOFF/DIFF_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.txt`
· 70 righe · sha256 `e6dab581e308c51ae77229315a6c3cf71530cd29573003a93ead74ee76436557`
· **2 file tracciati, +34 / −2**.

⚠️ **Il file rev6 depositato NON compare nel diff**: è **nuovo e non tracciato**,
e `git diff` non vede gli untracked. Non l'ho stageato — sarebbe una modifica
d'indice in un giro che non committa. **La sua identità è però interamente
verificabile** dai valori del §2/§3, che il referee ha già confermato in modo
indipendente. Al commit del prossimo giro va aggiunto **nominandolo per esteso**.

### Percorsi, dichiarati da me

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.md` e
`DIFF_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.txt`.

### Le facce misurate — sono tre, diverse

| oggetto | faccia | perché |
|---|---|---|
| `DESIGN/QLive_Nav/**` (rev6, README) | **LF, disco = blob** | `DESIGN/** -text` |
| `HANDOFF/**` (questo referto, il diff) | **LF, disco = blob** | `HANDOFF/** -text` |
| `ios_app/**` (il file Swift) | **CRLF su disco, LF nel blob** | non coperto ⇒ `core.autocrlf` |

⚠️ **R-δ: due gambe su tre.** Drive non autorizzato in scrittura ⇒ **scritto, non
consegnato**. La cartella `E:` **non è sincronizzata** verso Drive (rimisurato in
A140: il ramo `Il mio Drive/Qbeats/HANDOFF/` è fermo al 7 agosto).

---

## IN CODA

1. **La collocazione della riga rev6** — «in coda» prima o dopo il catch-all.
   Basta una riga di risposta.
2. **Il debito dell'ancoraggio in due punti** — atomo suo, non riparato qui.
3. **Il collaudo device di A144** (badge fermo a titolo su due righe) — la
   verifica statica non lo prova.
4. **Il §Workflow punto 4 di BUGS** (formato del messaggio di commit) — segnalato
   in A141 e A142, ancora da sanare.
5. **[R] A139 è 7/7 su iPhone: resta l'iPad.** ⚠️ E quell'esito **vive solo in
   chat** — non è in BUGS né in LIBRO. Per la regola «ratificato ≠ inciso», finché
   non atterra in un canonico non esiste per chi arriva dopo.

---

*A144-FINE*
