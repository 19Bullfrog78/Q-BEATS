# CONGEDO CC — sessione del 26/08/2026, pomeriggio-sera

Da: CC · A: **la chat CC che apre dopo di me**, + Mauro + referee

⛔ **Scritto senza vedere il congedo del referee e senza chiederlo**, per mandato.
Se convergiamo, la convergenza vale perche' e' indipendente. Se divergiamo,
misurate la divergenza invece di appianarla.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato da altri, non
rimisurato · **[A]** giudizio mio. ⛔ Mai mescolati in una frase.

⚠️ **La prima cosa che ti dico e' di non credermi: marca questo file [R] e
rimisura.** Io ho aperto la sessione facendo esattamente questo col congedo del
mattino, e ho trovato quattro divergenze — **una delle quali era mia, non sua.**

⚠️ **TUTTE LE MISURE DI QUESTO FILE SONO STATE SCATTATE PRIMA DI DEPOSITARLO.**
Il deposito le cambia, e dove le cambia lo dico riga per riga.

---

## 0 · ID A225 — misurato, non scelto

**[M]** Sonda su due supporti (NOME e CONTENUTO), tracciati e non tracciati, su
entrambe le gambe. Gamba CONTENUTO-git con `-- ':!DESIGN'`, per `R-δ.10`.

| ID | NOME git / hoffC / hoffE | CONT git / hoffC / hoffE |
|---|---|---|
| **A225** (preso) | 0 / 0 / 0 | 0 / 0 / 0 |
| A224 (positivo: il giro di oggi) | 0 / 0 / 0 | **2** / **1** / **1** |
| A223 (positivo) | 0 / 0 / 0 | **1** / **1** / **1** |
| A222 (positivo) | **1** / **1** / **1** | **1** / **1** / **1** |
| A211 (positivo storico) | **2** / **2** / **2** | **6** / **11** / **10** |

✅ **[M] Quattro positivi, tutti non-zero: la sonda vede.** A225 e' pulito **anche
senza** l'esclusione di `DESIGN/`, per il corollario di `R-δ.10`.
⛔ **[M] I candidati scartati non sono nominati per cifra**, per `R-δ.9`.

---

## 1 · I MIEI ERRORI — sette, e due non li ha notati nessuno

### 1.1 — Stavo per dichiarare falso il congedo del mattino, e sbagliavo io

**[M]** Il congedo A220 dava `iOS Signed Build` a **579 success**. La mia prima
sonda — `?status=success&per_page=1` letta una volta sola su `.total_count` — ha
reso **173**. Stavo per scrivere che sbagliava di quattrocento.

✅ **[M] Mi ha salvato la controprova a due forme**, che e' regola di casa:
l'enumerazione completa delle conclusioni rende **580**, e la somma quadra col
totale. **Il congedo aveva ragione; la mia sonda mentiva.**

⇒ **[A] Da qui e' nata la voce nuova della tassonomia di oggi**, ma per arrivarci
ho dovuto prima **sbagliare la diagnosi**: l'avevo chiamata «numero non
riproducibile» perche' la stessa query rendeva 173, poi 494. **Rimisurata prima
di inciderla, come imponeva il mandato: sei chiamate identiche rendono 582
stabile.** La caratterizzazione era falsa e non e' entrata.

⛔ **[M] Cio' che e' entrato e' un'altra cosa, dimostrata per controprova:** un
parametro **inventato di sana pianta** rende lo stesso numero di
`?conclusion=success`, cioe' il totale ⇒ i parametri sconosciuti **vengono
scartati in silenzio**. ⇒ **[A] Il difetto vero non era quello che credevo, e
l'ho trovato solo perche' il mandato mi ha obbligato a rimisurare.**

### 1.2 — Ho ripetuto l'errore di perimetro del congedo che stavo correggendo

**[M]** Cercando i canonici sulla gamba `E:` ho dichiarato **quattro ASSENTI**.
Non erano assenti: su `E:` vivono come **snapshot per versione**
(`BOX5_V33_2026-08-26_c89832b.md`), non col nome canonico.

⇒ **[A] E' la §1.3 del congedo A220 — la ricerca larga con perimetro incompleto —
ripetuta da me tre ore dopo averla letta e censita.** ✅ L'ha presa il controllo
positivo.

### 1.3 — `grep` mi ha rifiutato una sonda e ha reso zero su sei file

**[M]** Per contare i separatori U+202F ho lanciato `grep -P` con la notazione
`\x{202F}`. **`grep` l'ha rifiutato** — *character value too large* — e ha reso
**0 su tutti e sei i file interrogati**, LIBRO compreso, che ne contiene **due**.

✅ **[M] L'ho presa solo perche' non ho soffocato stderr.** Rimisurato per byte
(`E2 80 AF`): due occorrenze, righe 371 e 533 del LIBRO, zero altrove.
⇒ **[A] E' la voce STDERR SOFFOCATO della tassonomia, capitata a me, su uno
strumento diverso da quello del congedo. La regola non e' una massima: mi ha
salvato oggi.**

### 1.4 — Ho soffocato stderr mentre incidevo la regola che lo vieta

**[M]** Misurando le citazioni nude a `BOX5:NN` ho lanciato la sonda scartando
stderr, cioe' **esattamente cio' che il capitolo che stavo scrivendo proibisce.**
L'ho rifatta pulita — e la versione pulita ha reso il rilievo su `:564`/`:566`
che quella sporca aveva nascosto.

⇒ **[A] Scrivere una regola non protegge dal violarla mezz'ora dopo.**

### 1.5 — Un falso zero mio su una sezione che avevo sotto gli occhi

**[M]** La sonda sulle intestazioni della sezione B della SCALETTA ha reso **0**.
La sezione si chiama `## B · Scaletta 12 atomi`, non «Sezione B», e la mia regex
cercava la seconda forma. ✅ Preso col controllo positivo: **14** intestazioni
`###` nel file. La misura vera e' **13 in sezione B, nessuna e' ⟦S-EXIT⟧**.

### 1.6 — 🚨 IL PIU' GRAVE, ED E' DURATO TUTTA LA SESSIONE: la SCALETTA su `E:`

**[M]** In apertura ho scritto nel referto «SCALETTA **15**». **Vero su `C:`.** Ma
su `E:` avevo verificato **solo gli snapshot**, mai la copia viva.

🚨 **[M] La copia viva su `E:` era ferma alla `**Versione:** 10 (18/08/2026)`:
56 791 byte contro 89 757, cinque versioni e 32 966 byte di divario, otto
giorni.** Il suo mtime — 18/08 16:30, tre minuti dopo il commit `44fea3e` —
dice la data esatta dell'ultima propagazione.

⛔ **[M] Non l'ho trovata io con una sonda: l'ha trovata Mauro con una domanda.**
Ha chiesto perche' non trovava la v15 in HANDOFF su `E:`, e la risposta era che
non c'era **per due motivi diversi**, non uno.

⇒ **[A] Questo e' l'errore peggiore della giornata, e non perche' sia il piu'
grosso: perche' e' sopravvissuto a tre referti miei che si dichiaravano
completi.** Avevo misurato la stessa cartella quattro volte senza mai
confrontare i byte del file vivo.

### 1.7 — Due errori che NESSUNO ha notato, e che dichiaro qui per primo

**[M] (a) Ho inciso in BOX5 due citazioni nude a numeri di riga del LIBRO —
`LIBRO:323` e `LIBRO:352` — senza dichiarare che sono soggette a slittamento.**
Tutta la giornata di ieri e di oggi ruota attorno alle citazioni nude che
slittano, e io ne ho **create due nuove** nel canonico senza una riga di
avvertimento. ⚠️ **[M] Il rischio oggi e' basso e misurato:** la Sezione 2 del
LIBRO e' in ordine cronologico crescente e le righe nuove entrano **in coda**
(l'ultima e' la `2026-08-25` alla riga 371, oltre entrambe). ⛔ **Ma «basso» non
e' «nullo», e la dichiarazione andava fatta nel capitolo, non qui.**

**[M] (b) Ho scritto «la §5 del congedo e' scaduta di due versioni» intendendo
due canonici avanzati di una versione ciascuno.** Letto da chi arriva, «scaduta
di due versioni» dice un'altra cosa. ⇒ **[A] E' la classe «sonda eseguita, sonda
dichiarata» del referto A222 applicata a un conteggio: la misura era giusta, la
didascalia no.**

---

## 2 · COSA HO FATTO, E DOVE VIVE — [M]

**[M] Un solo commit mio in tutta la sessione:**
**`88acb3116cee0f600e70d60212094e30fe56853b`** (mandato A224), due file,
`110 insertions(+), 1 deletion(-)`, pushato `c57a00f..88acb31` senza `--force`.

| dove | cosa | in git? |
|---|---|---|
| `BOX5_QBEATS.md` V33→**V34** | capitolo **TASSONOMIA DEI DIFETTI DI MISURA** — cinque voci, tre polarita' | **SI** |
| `HANDOFF/REFERTO_…A222…md` | marcatura additiva della riga 478 | **SI** |
| `E:` `BOX5_V34_2026-08-26_88acb31.md` | snapshot per versione | no (mirror) |
| `E:` `HANDOFF/REFERTO_…A222…md` | gamba allineata | no (mirror) |
| `E:` `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **v10 → v15**, allineata su decisione di Mauro | no (mirror) |
| memoria privata di CC | cartello: la sede canonica e' BOX5, la numerazione locale non e' quella di alcun canonico | **no, e va saputo** |

⛔ **[A] La riga piu' importante di quella tabella e' l'ultima.** La terza
«sesta» viveva in un posto che **nessuno tranne me puo' leggere**. L'ho
riconciliata puntando al canonico, ma **chi arriva non ha modo di verificarlo**:
deve fidarsi di questa riga. E' l'unico punto del giro che non regge alla regola
di casa «cio' che non e' verificabile non e' consegnato».

**[M] Tre giri prima di quello, senza scrivere una riga:** rimisura del congedo
A220 (quattro divergenze), rimisura del referto A222/A223 (una divergenza), e un
mandato che **era gia' stato eseguito** e che ho dimostrato tale invece di
rifarlo.

---

## 3 · LO STATO — tutto [M], misurato PRIMA di depositare questo file

    HEAD locale = HEAD remoto = 88acb3116cee0f600e70d60212094e30fe56853b
    0 tracciati modificati · 0 in stage · 1075 non tracciati

⚠️ **[M] I 1075 diventano 1076 nell'istante in cui deposito questo file, e 1075
di nuovo quando lo committo.** Lo dichiaro qui invece di lasciarlo scoprire.
Composizione: **790** `.tmp.driveupload` + **281** `HANDOFF` + **4** sparsi.

**[M] I cinque canonici, misurati uno per uno alla fonte:**
BOX3 **V100** · BOX5 **V34** · BUGS **63** · LIBRO **64** · SCALETTA **15**.
⚠️ **[M] La SCALETTA non e' in radice e il suo nome non porta la versione:** e'
`HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, e la data nel nome e' **piu' vecchia
del contenuto di sei settimane**. ⛔ **Si cerca per contenuto, mai per nome.**

**[M] La costruzione automatica, per ENUMERAZIONE e mai per `total_count`
filtrato** — che oggi ho imparato a mie spese a non usare:

| workflow | totale | enumerazione | su HEAD `88acb31` |
|---|---|---|---|
| iOS Signed Build | 647 | **583** success · 63 failure · 1 cancelled | ✅ **success** |
| F1 — Build Check | 4 | **1** success (25/04) · 3 failure | ⛔ non partito |
| Build LinkHut Diagnostic | 4 | 3 success · 1 failure | ⛔ non partito |

✅ **[M] 583 + 63 + 1 = 647: la somma quadra col totale.** E' la sola verifica
che smaschera la polarita' P3, perche' li' la sonda risponde e l'oggetto c'e'.

---

## 4 · CHIUSO E NON CHIUSO — la distinzione che conta e' «dov'e' scritto»

**[M] Chiuse OGGI e verificabili in git:** la tassonomia dei difetti di misura
(BOX5 V34) · la marcatura della riga 478 del referto A222 · e, dal giro del
mattino che non e' mio, il ticket `kickScheduling` in BUGS 63 e il deposito
della nota di correzione al 18/07.

**[M] Chiuse OGGI ma NON in git — vivono solo su disco:** l'allineamento della
SCALETTA sulla gamba `E:` · lo snapshot `BOX5_V34` su `E:` · l'allineamento del
referto A222 su `E:`.

**[M] Chiusa OGGI e NON verificabile da nessuno tranne me:** la riconciliazione
della terza «sesta» nella memoria privata di CC.

⇒ **[A] Tre livelli di esistenza diversi, e solo il primo sopravvive a chi apre
domani senza accesso a questa macchina.** ⛔ **Chi legge «chiuso» in un congedo
deve chiedersi sempre: chiuso DOVE.**

---

## 5 · LE PENDENZE — rimisurate una per una a HEAD `88acb31`, non ereditate

| # | pendenza | stato |
|---|---|---|
| 1 | **[M] `tmp_fix.ps1` e' TRACCIATO** in un repo pubblico. Segnalato il 23/08 | 🔴 aperto |
| 2 | **[M] `.tmp.driveupload/` — 790 file** non tracciati: un `git add -A` li pubblicherebbe | 🔴 aperto |
| 3 | **[M] `F1 — Build Check` non passa dal 25/04**: 4 run, 1 success, **3 failure**. Non partito su HEAD | 🟠 aperto |
| 4 | **[M] Debito doc: `HANDOFF/` ha 330 file, 49 tracciati, 281 no.** Diventano 282 col deposito di questo file, e 281 di nuovo col suo commit | 🔴 aperto |
| 5 | **[M] `⟦S-EXIT⟧` non ha scheda**: 13 intestazioni `###` in sezione B, **nessuna e' la sua** | aperta |
| 6 | **[M] RESTART SETLIST inerte**: `FineSetlistView.swift:39`, closure con solo un commento. Ratificato il 07/08 — **diciannove giorni** | 🔴 aperto |
| 7 | **[M] Buchi di registro**: LIBRO **25, 26, 60, 61** (max 64) · BUGS **48** (max 63) | aperta |
| 8 | **[M] Nessuno snapshot SCALETTA v15 su `E:`** — e **[M] manca anche la v10**: la catena salta da v9 a v11. ⚠️ Il regime di esportazione e' dichiarato **APERTO in BOX3 da luglio**: non e' una copia dimenticata, e' una regola mai decisa | 🟠 aperta |
| 9 | **[M] `kickScheduling`**: 1 definizione, 3 commenti, **zero callsite**. ✅ Ora ha un ticket in BUGS 63 | 🟡 tracciata |
| 10 | **[M] Nota di correzione al 18/07** — ✅ **CHIUSA**: depositata su `C:` e su `E:` | ✅ chiusa |
| 11 | **[M] Il mirror `E:` va indietro senza che nessuno se ne accorga.** ⚠️ **Non era un caso isolato: prima il LIBRO (7 versioni), oggi la SCALETTA (5 versioni, 8 giorni).** Sanate entrambe; **il controllo periodico continua a non esistere** | 🔴 aperta |
| 12 | **[M] Divergenze incise a meta'**: `R-δ.8/9/10` sono in BOX5 V33, ma il debito doc e le tre letture di «comportamento» **non sono in alcun canonico** | 🟠 aperta |
| 13 | **[M] I due OPEN della scheda G**, rimisurati da me e non piu' [R]: teardown grafo/Link allo STOP, e giro CD sulla copy del chip peer | 🟠 aperti |
| 14 | **[M] Il disegno CD del 25/08 non e' collaudato su device**: il LIBRO lo dichiara **«APPROVATO, NON ratificato»** in due punti | 🟠 aperta |

⚠️ **[M] Sull'equilibrio: oggi non e' stata toccata una riga di codice, e non era
compito di nessuno — i quattro mandati erano di documentazione.** L'ultimo commit
che cambia **logica** resta `7c04bea` del 19/08: **sette giorni**.

---

## 6 · [A] COSA DEVE SAPERE CHI APRE DOMANI, E OGGI LO SA SOLO IO

⛔ **Misura HEAD PRIMA di eseguire un mandato.** Uno dei quattro che ho ricevuto
oggi era **gia' stato eseguito per intero** quando mi e' arrivato. Se l'avessi
eseguito alla lettera avrei rifatto un push gia' fatto e riscritto una
correzione gia' scritta. **Il mandato non e' una fonte:
e' un'ipotesi sullo stato del mondo, e va misurata come tutte le altre.**

⛔ **Il mirror `E:` mente in DUE modi diversi, e il secondo e' quello che uccide.**
Primo: i canonici non ci sono **col nome canonico** — vivono come snapshot per
versione, e una sonda per nome li dichiara assenti. Secondo, e peggiore:
**la copia viva puo' essere vecchia di versioni** e nessuno se ne accorge,
perche' ogni consegna verifica il `cmp` **sul file che sta scrivendo**, e mai
sugli altri.

✅ **La cura sta in due righe, e oggi le ho scritte:** per ogni file tracciato di
`HANDOFF/` presente su entrambe le gambe, `cmp` e stampa i divergenti. **Ha
trovato in tre secondi un divario rimasto invisibile otto giorni.** Prima
dell'allineamento: **1 divergente su 49**. Dopo: **0 su 49**.

⛔ **`total_count` con un filtro non e' una misura.** Su GitHub Actions rende
numeri sbagliati senza alcun segnale, e i parametri che non conosce **li scarta
in silenzio** invece di rifiutarli. **Enumera e quadra la somma col totale.**

⛔ **Un documento che parla di se' si smentisce nell'atto di pubblicarsi, ed e'
successo DUE volte in ventiquattro ore** — al congedo del mattino sul conteggio
dei non tracciati, e al referto A222 con la riga «questo referto NON e'
committato» pubblicata **dentro il commit che la committava**. **Non e'
sbadataggine: e' strutturale.** Dichiara le misure come scattate **prima** del
deposito, e ricontrolla a file chiuso ogni frase che parla del file stesso.

⛔ **Le stringhe dell'auto-test si copiano da UNA RIGA SOLA.** Non e' una
clausola di forma: e' la condizione perche' `grep` e il conteggio appiattito
diano lo stesso numero. Nel congedo del mattino **quattro** stringhe su nove
divergevano fra le due sonde, e il documento ne dichiarava **una**.

---

## 7 · [A] IL REFEREE DI OGGI — senza sconti, perche' me lo ha chiesto

**⛔ Mi ha fatto perdere un giro intero su un lavoro gia' fatto.** Il mandato che
ordinava push, rettifica e snapshot era **integralmente eseguito** quando mi e'
arrivato: il push era nel remoto, la rettifica era in git, lo snapshot era su
`E:`. Ho speso il giro a **dimostrarlo con misure** invece di lavorare.
⇒ **[A] La causa non e' distrazione: e' che il mandato e' stato scritto senza
misurare HEAD prima.** E' lo stesso difetto che il referee rimprovera a noi.

**⛔ Ha sbagliato un indirizzo, e nel punto peggiore possibile.** Il mandato
della tassonomia attribuiva la riga `:439` del congedo A220 alla voce sullo
stderr scartato. **Misurato: la 439 e' la voce «`grep` conta righe»; l'altra vive
alle righe 108, 112, 123 e 350.** ⇒ **[A] Eseguito alla lettera, avrei inciso un
indirizzo falso DENTRO la tassonomia che esiste per impedire esattamente
quello.** ✅ Riconosciuto e accolto quando gliel'ho misurato.

**⛔ Ha riusato una premessa senza rimisurarla.** «Tutte le citazioni nude a
`BOX5:NN` puntano a righe ≤ 390» veniva dal referto A222 ed e' **vera su `C:`,
falsa sull'unione `C:`+`E:`**: ce ne sono due a `:564` e `:566`. La conclusione
reggeva lo stesso, ma **la premessa era misurata su mezzo perimetro e non e'
stata riverificata prima di riusarla.**

**✅ E ora il merito, che e' reale e va scritto con la stessa forza.** Il rilievo
sulla riga 439 — **sonda stretta eseguita, sonda larga dichiarata** — e' il
reperto migliore di tutta la giornata, **e nessuno strumento poteva trovarlo**:
l'ha trovato **rileggendo**. ✅ E ha imposto la regola giusta: *«rimisura tu
stesso prima di correggere: non prendere per buona la mia misura piu' di quanto
io abbia preso per buona la tua»*. **[A] E' esattamente cosi' che si lavora, e
oggi ha funzionato in entrambe le direzioni.**

⚠️ **[M] Un difetto di forma, minore ma sistematico: i mandati dichiarano un
MODELLO in testa, e due su quattro indicavano un modello diverso da quello in
esecuzione.** Non ha cambiato nulla nelle misure.
**[A] Ma un campo che nessuno verifica e' un campo che prima o poi mente**, ed
e' la stessa famiglia dei campi di misura riempiti per inerzia.

---

## 8 · [A] CIO' CHE LASCIO

⛔ **Non credere a questo file. Marcalo [R] e rimisura**, cominciando da §5.
Le pendenze sono le mie misure di oggi: **scadono, come sono scadute quelle di
ieri in meno di due ore.**

⛔ **Il lavoro piu' utile che puoi fare domani non e' in nessuna pendenza:** e'
rendere permanente lo sweep delle due gambe. **Due canonici su due, quando
nessuno guardava, erano indietro sul mirror.** La terza volta non e' una
possibilita': e' una certezza con una data che non conosciamo.

---

### Controllo d'integrita' di QUESTO file — sul CONTENUTO

⚠️ Stringhe **copiate** da una riga sola, senza accenti ne' apostrofi, e
**contate sul testo APPIATTITO** — non riga per riga: `grep` conta righe, e una
frase spezzata da un a-capo gli e' invisibile. E' la voce che ho inciso io stesso
oggi nella tassonomia di BOX5. Attese **2** occorrenze ciascuna, corpo + questa
lista. Il marcatore di fine: **1**, in ultima riga.

`l'ha trovata Mauro con una domanda` ·
`e' un'ipotesi sullo stato del mondo` ·
`la copia viva puo' essere vecchia di versioni` ·
`i parametri che non conosce` ·
`dentro il commit che la committava` ·
`sonda stretta eseguita, sonda larga dichiarata` ·
`un campo che nessuno verifica` ·
`chiuso DOVE` ·
`Si cerca per contenuto, mai per nome` ·
e il marcatore di fine qui sotto.

🚨 **[M] Questa lista e' stata contata A FILE FINITO, non prima**, e le stringhe
sono state **copiate dal corpo**, non riscritte a memoria. **Se un numero non
torna, e' questo file a essere rotto, non la lista.**

---

*A225-CONGEDO-CC-2026-08-26-SERA-FINE*
