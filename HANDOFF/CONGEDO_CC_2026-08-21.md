# CONGEDO CC — sessione 20-21/08/2026, mandati A135 → A138

Da: CC · A: **la chat CC che apre dopo di me**, + Mauro
Scritto **alla cieca**: non ho letto il congedo del referee, non gli ho chiesto
cosa metterci. E' il protocollo, e serve a non farci convergere sulla stessa
versione dei fatti.

Marcatura: **[M]** misurato da me alla fonte in questa sessione · **[R]**
riportato da altri, non rimisurato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Il congedo che trovi in contesto NON l'ha scritto la chat che stai leggendo.**
Io stesso ho aperto questa sessione ereditando `CONGEDO_CC_2026-08-20.md`, l'ho
marcato **[R]** e l'ho rimisurato prima di appoggiarmici. **Fai lo stesso con
questo.** Regge quasi tutto, ma non tutto: sotto trovi cosa gli ho trovato di
sbagliato.

**2. In questa sessione il referee mi ha dato TRE percorsi su disco, tutti e tre
SBAGLIATI, e nessuno era stato misurato prima di scrivermelo.** Mi sono fermato
ogni volta senza copiare nulla, e ogni volta avevo ragione. ⛔ **Fermarsi e' il
comportamento atteso, non un intralcio.** Dettaglio piu' sotto.

**3. La sessione ha toccato SOLO `DESIGN/QLive_Nav/`.** Zero codice, zero
canonici. Chi arriva non eredita nessun lavoro a meta' nel codice.

---

## PARTE MECCANICA

### 1 · HEAD e albero

**[M]** HEAD locale **=** HEAD remoto **=**

```
f17aa7c3e90ae03bfbaf2edb1322708e7850fb9a
```

(`git rev-parse HEAD` e `git ls-remote origin master`, **mai** `rev-parse
origin/master` — quello legge una copia locale che puo' essere vecchia.)

**[M]** Tutto cio' che questa sessione ha cambiato, da `178042b` a HEAD —
**quattro file, tutti in una sola cartella**:

```
DESIGN/QLive_Nav/2026-08-20_QLive-Shows_rev4__...390x844.html
DESIGN/QLive_Nav/2026-08-20_QLive-Shows_rev5__...390x844.html
DESIGN/QLive_Nav/2026-08-21_QLive-Shows_NOTA-DI-CORREZIONE-rev5__...html
DESIGN/QLive_Nav/README.md
```

### 2 · I due commit della sessione

**[M]** Entrambi autore `Mauro Martintoni <di_tutto@icloud.com>`, **zero trailer**,
verificato leggendo il corpo del messaggio.

| sha (40) | data | cosa |
|---|---|---|
| `1f8ddad88ba58fecce38b331e3ff848b12a1ae65` | 20/08 19:47 | deposito rev4+rev5 + indice normativo nel README |
| `f17aa7c3e90ae03bfbaf2edb1322708e7850fb9a` | 21/08 08:25 | nota di correzione CD + riga di rimando |

### 3 · CI — per NOME, mai «verde» secco

**[M]** Rimisurato oggi:

| workflow | run id | sha | esito |
|---|---|---|---|
| `iOS Signed Build` | `32454319236` | `f17aa7c3…` | **success** |
| `iOS Signed Build` | `32399773355` | `1f8ddad8…` | **success** |
| `F1 — Build Check` | — | — | **non partito** |

⛔ **`F1` non e' «fallito» e non e' «verde»: e' NON PARTITO.** In tutta la sua
storia parte solo da `workflow_dispatch` manuale, mai da push.

⚠️ **[M] E un dato che vale la pena non perdere: l'ultima run VERDE di F1 e' del
25 APRILE 2026.** F1 ha **quattro run in tutto**, una sola riuscita. Non «non gira
dal 31/07»: non funziona da quattro mesi. Se qualcuno decide che F1 conta come
cancello, sta decidendo di riparare qualcosa di fermo da aprile.

⚠️ **Il nome vero di F1 e' piu' lungo di come viene citato:**
`F1 — Build Check (zero errors, zero warnings)`. Interrogandolo con la forma
abbreviata, `gh` risponde *«could not find any workflows named»* ⇒ **falso zero**.
Si interroga per **ID** (`266323994`) o col nome intero.

### 4 · I cinque canonici — NESSUNO toccato

**[M]** Impronte dei blob a HEAD, invariate rispetto all'inizio sessione:

| canonico | byte | righe | versione |
|---|---:|---:|---|
| `LIBRO_MASTRO_QBEATS.md` | 276 359 | 519 | registro fermo alla voce **57** (18/08) |
| `BUGS_QBEATS.md` | 327 759 | 1 132 | **v56** (ultima voce 19/08) |
| `BOX3_QBEATS.md` | 89 457 | 803 | — |
| `BOX5_QBEATS.md` | 57 158 | 596 | — |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | 66 467 | 457 | — |

⚠️ **CR=0 su tutti perche' sono impronte del BLOB.** La faccia **disco** di LIBRO
e BUGS porta CRLF. Se misuri su disco e non torna, **non e' un guasto**: e'
questo. **Dichiara sempre quale faccia stai misurando.**

⛔ **[A] Il fatto piu' importante di questa tabella:** in **tre giorni** non e'
stata incisa una riga in nessuno dei cinque canonici. Il debito documentale
ereditato dal congedo precedente **non e' stato smaltito, e' cresciuto**.

### 5 · Prossimo ID libero

**[M]** Sonda a **DUE FORME** su **DUE SUPPORTI** — per NOME e per CONTENUTO,
su `HANDOFF/` nel repo e su `HANDOFF/` in E:.

| ID | nome-repo | cont-repo | nome-E: | cont-E: | lettura |
|---|---:|---:|---:|---:|---|
| A135 | 0 | 1 | 0 | 1 | congedo 20/08 |
| A136 | 0→1 | 1 | 0→1 | 1 | deposito rev4+rev5 |
| A137 | 0→1 | 1 | 0→1 | 1 | nota di correzione |
| A138 | 0→1 | 0→1 | 0→1 | 0→1 | **questo giro** |
| **A139** | **0** | **0** | **0** | **0** | ⇒ **PROSSIMO LIBERO** |

⛔ **Controllo positivo** nella forma esatta della sonda, su ID noto-usati:
`A133` → 2 e 2 · `A134` → 1 e 1.

⚠️ **AUTORIFERIMENTO dichiarato:** le colonne `0→1` sono «prima di questo giro» →
«dopo». I referti di A136, A137 e questo congedo nascono adesso.

### 6 · 🚨 LA SONDA PER NOME E' STRUTTURALMENTE CIECA — non fidartene da sola

**[M] E' la scoperta piu' utile che lascio.** La sonda dichiarata nei congedi
precedenti (`ls HANDOFF/ | grep -c 'A1NN'`, **criterio = nome di file**) **non
vede un'intera classe di artefatti**.

Prova, misurata: **zero congedi su nove** portano l'ID nel nome. Quindi:

| ID | per NOME | per CONTENUTO | verita' |
|---|---:|---:|---|
| `A114` | **0** | 3 | **usato** |
| `A123` | **0** | 5 | **usato** |

⇒ La sonda per nome avrebbe dichiarato **liberi** due ID indiscutibilmente usati.
E' la stessa collisione che ha gia' bruciato `A128` una volta.

⛔ **Ma la sonda per CONTENUTO ha l'errore OPPOSTO: conta anche le menzioni.**
`A136` e `A137` rendevano 1 per contenuto solo perche' il congedo del 20/08 li
nominava **come liberi**.

✅ **La regola che propongo, e che ho usato in tutti i giri di questa sessione:
due forme + ISPEZIONE DEL CONTESTO.** Nessuna delle due sonde da sola basta, e
l'aritmetica sui conteggi non sostituisce il guardare *dove* compare l'ID.

---

## ⛔ COSA NON CREDERE — le mie ipotesi sbagliate, per nome

**[M] 1. «I file spuri su Drive sono spariti, probabilmente sync completato.»
FALSO.** In `Qbeats_IN_CD` c'erano due copie ri-salvate da browser (67 812 B con
nome troncato e estensione `.htm`; un rev5 da 79 121 B). Al giro dopo non
c'erano piu' e **ho attribuito la sparizione a un sync automatico**.
**[R] Li aveva CESTINATI CD**, dopo che gli e' stato chiesto conto — misurato dal
referee su Drive, non da me.

⚠️ **Perche' e' grave se resta agli atti:** «Drive si sistema da solo» porta a non
controllare piu' i byte. E' **il contrario**: sono spariti perche' qualcuno li ha
guardati e buttati.

✅ **Cosa l'ha resa innocua: l'avevo dichiarata come IPOTESI, non come misura.**
Ho scritto «probabilmente», e questo ha permesso a chi sapeva di correggermi in
un giro. **[A] E' la lezione vera: un'ipotesi etichettata come tale costa una
riga di rettifica; la stessa ipotesi spacciata per misura sarebbe diventata una
regola falsa.**

**[M] 2. Un dettaglio del congedo che ho ereditato, smentito da me.** Diceva:
*«le unita' F:, G:, H: non contengono alcun albero Q-BEATS»*. **Falso.** `F:`
contiene `QBEATS_PREFLIGHT_A61_2026-08-06\`, che e' un **clone completo e vivo del
repo**, su `master`, **con push configurato verso lo stesso GitHub**, fermo a
`25056b6` del 05/08.

🚨 **[A] E' un rischio ancora aperto:** chi ci lavora dentro legge canonici vecchi
di due settimane **e puo' pushare sul remoto vero**. Non l'ho toccato — fuori da
ogni mandato — ma nessuno l'ha ancora messo in sicurezza.

**[M] 3. La marcatura di A135 non era atterrata.** Il congedo del 20/08 dichiarava
*«da ora A135 rende 1 per NOME su ciascun supporto»*. Misurato: **0 e 0** — il
file si chiama `CONGEDO_CC_2026-08-20.md`, l'ID nel nome non c'e'. E' il caso
particolare che mi ha fatto trovare la cecita' strutturale del §6.

---

## ⛔ I MANDATI CHE MI HANNO DATO PERCORSI SBAGLIATI

**[M] Tre volte, in due giorni, il referee mi ha scritto un percorso su disco
senza averlo misurato. Tutti e tre errati.**

| # | cosa diceva il mandato | cosa ho misurato |
|---|---|---|
| 1 | *«Mauro ha messo in `DESIGN/QLive_Nav/` il file rev4»* | **Non c'era.** Cercato per nome esatto e per pattern largo su C:, E:, OneDrive, iCloudDrive: zero. |
| 2 | `I:\Il mio Drive\Qbeats_IN_CD\..._390x844.html` | **Percorso inesistente.** Il file vero portava un ` (1)` nel nome, che il mandato non menzionava. |
| 3 | *«Mauro scarica in Downloads»* | **Mai passati di li'.** In Downloads c'erano due soli `.html`, entrambi estranei. |

✅ **Ogni volta mi sono fermato senza copiare nulla, e ogni volta avevo ragione.**
Il referee lo ha poi riconosciuto per iscritto: *«gli ultimi due che ti ho dato
erano sbagliati entrambi. Lo risolvi tu e me lo dichiari.»*

⛔ **[A] Quello che il prossimo CC deve portarsi via:** il mandato **non e' una
fonte**, nemmeno quando e' dettagliato, nemmeno quando arriva dal referee.
**Misura la premessa contro la fonte PRIMA di eseguire.** Fermarsi con zero
consegnato e' il comportamento corretto quando la premessa e' falsa — non e'
ostruzionismo, e non e' stato trattato come tale.

⚠️ **Corollario che mi ha morso:** al primo blocco ho eseguito una scansione
larghissima del profilo utente. Era eccessiva, e mi e' stato ristretto il
perimetro. **La risposta giusta a un percorso sbagliato non e' cercare ovunque:
e' risalire l'albero un livello per volta e far dichiarare il percorso vero.**

---

## LE REGOLE DI TRASPORTO — pagate care il 20/08

**[M] 1. Un HTML ri-salvato da un browser NON e' quel file.** Misurato: **793
byte in meno** su un normativo, nome troncato, estensione `.htm` invece di
`.html`, **e nessun avviso**. Da Drive si usa **solo il tasto Scarica**, mai
«salva pagina con nome».

**[M] 2. I BYTE sono l'unico giudice, mai il nome.** Nella stessa cartella
convivevano un rev4 buono (68 605 B) e uno spurio (67 812 B) con nomi che si
somigliano. **La selezione va fatta sul peso, e va imposto che la corrispondenza
sia UNA SOLA**: zero o piu' di una ⇒ fermarsi ed elencare, mai scegliere.

**[M] 3. Un file col nome giusto ma byte diversi puo' essere un SEGNAPOSTO in
streaming**, non il documento: su Drive montato il contenuto puo' non essere sul
disco. Si dichiara e ci si ferma, non si copia.

**[M] 4. Ogni copia si chiude con `cmp` (exit 0) o sha256 su ENTRAMBE le facce.**
Copiare senza verificare e' consegnare senza sapere cosa.

**[R] 5. Nota di canale non risolta:** la rev5 su Drive pesa **79 120** B contro
i **79 121** del sorgente di CD. CD lo attribuisce al troncamento dell'a-capo
finale in upload via API. ⛔ **Non verificato e NON inciso come regola**: la rev3
combacia esattamente fra Drive e repo, quindi il meccanismo **non e' stabilito**.
Se un giorno confronti con la fonte di CD, quello scarto lo trovi: e' dichiarato
nel messaggio di commit di `1f8ddad`, non e' una corruzione.

---

## ⚠️ UNA TRAPPOLA DI AMBIENTE, nuova

**[M]** `python3` su questa macchina e' il **Python nativo Windows**
(`C:\Users\...\pythoncore-3.14-64\python.exe`), non quello di MSYS: **non capisce
i percorsi `/c/...`**. Uno script che apre `/c/Users/.../README.md` fallisce con
`FileNotFoundError` **su un file che esiste**.

✅ Diagnosticato con un controllo a due forme invece che indovinando:
`os.path.exists('/c/...')` → **False**, `os.path.exists('C:/...')` → **True**.

⇒ **Per gli script Python di questo repo servono percorsi `C:/...`.** Bash invece
vuole `/c/...`. Nello stesso comando convivono due convenzioni.

---

## LO STATO DEL PRODOTTO — cosa e' chiuso e cosa no

⛔ **Niente di questa sessione e' stato collaudato su device: la sessione non ha
toccato codice.** «Chiuso» lo dice Mauro dopo il device, e qui non c'e' nulla da
collaudare.

**[R] Ereditate dal congedo precedente, NON toccate da me, NON rimisurate:**

- **Due collaudi device pendenti**, documenti pronti ed esito mai arrivato:
  `HANDOFF/MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md` e
  `HANDOFF/MISURE_CC_2026-08-19_A131-COLLAUDO-TRE-CONFORMITA.md`.
- **⟦S-EXIT⟧ fermo prima della scheda.** Non e' un atomo di sola interfaccia:
  Start/Stop Sync non e' cablato e `linkPeers` ha due scrittori in conflitto.
  ⚠️ **[M] Questo l'ho riverificato all'apertura di sessione e regge**: SSS ha
  zero occorrenze in `ios_app/` (controllo positivo: 133 occorrenze di `ABLLink`),
  e `linkPeers` ha **sette** scritture — una vera piu' sei di ripiego booleano.
  **Tre decisioni restano a Mauro**, e nessuna misura mia le sblocca.
- **🚨 Dal player in standby non si esce.** ⚠️ **[M] Riverificato riga per riga
  all'apertura**: il tasto indietro vive nel `VStack` che in standby va a opacita'
  0,10, e l'overlay standby sta sopra nello `ZStack` con `contentShape` e
  `onTapGesture` ⇒ consuma ogni tocco. Si incontra **a ogni START SHOW**.

**[R] Le quattro voci in coda per un giro doc** del congedo precedente: **nessuna
incisa**, nessuna toccata da me.

---

## LE PENDENZE CHE LASCIO IO

**[M] Dal mio lato, e senza inventarne di nuove:**

1. **Il clone vivo su `F:`** con push verso il remoto vero, fermo al 05/08.
   Nessuno l'ha messo in sicurezza. **[A] E' l'unica pendenza che peggiora da
   sola**, perche' basta che qualcuno ci lavori dentro senza accorgersene.
2. **La regola della sonda a due forme** (§6) non e' incisa in nessun canonico:
   vive solo qui e nei referti. Va in un giro doc.
3. **R-δ:** questa consegna arriva a **due gambe su tre** — repo ed E:. La gamba
   **Drive esiste ed e' raggiungibile** (`I:`, verificata in questa sessione), ma
   **non l'ho usata come destinazione**: il mandato autorizzava solo lettura da
   `I:` e vietava esplicitamente di scriverci. ⇒ **Per la lettera di R-δ questo
   congedo e' SCRITTO, NON CONSEGNATO**, e non lo nascondo dietro un «propagato».
   ⚠️ **Novita' rispetto a ieri:** ieri la gamba Drive era dichiarata
   *irraggiungibile*. **Non e' vero: e' raggiungibile.** Manca solo
   l'autorizzazione a scriverci.
4. **I due difetti noti della rev5** (cita due righe di canonici senza ancoraggio
   a commit; chiama la rev3 con un nome che non ha) sono **superati dalla nota di
   correzione**, non riparati nel file. Corretto cosi': **un file di CD non si
   emenda a valle.**

---

## [A] LA COSA CHE VALE PIU' DI TUTTE

Questa sessione non ha prodotto una riga di codice. Ha prodotto **quattro file di
disegno messi al sicuro** che prima esistevano su **una sola destinazione**, coi
predecessori gia' cestinati — cioe' erano a una cancellazione dalla sparizione.

E ha prodotto tre fermate. **[M] Tre volte ho ricevuto un percorso e tre volte
non c'era.** Nessuna delle tre e' nata da intuizione: sono nate tutte dalla stessa
cosa meccanica — **prima di eseguire, misurare la premessa del mandato contro la
fonte**.

⚠️ **E la seconda, che costa poco e vale molto: distingui sempre l'ipotesi dalla
misura, anche quando sei quasi certo.** L'unico errore mio di questa sessione —
il «sync completato» — e' costato una riga di rettifica **solo perche' l'avevo
scritto come ipotesi**. Se l'avessi scritto come misura sarebbe diventato una
regola falsa dentro un documento che serve a fidarsi.

⛔ **Terza, per chi eredita questo file: NON crederci sulla parola. Rimisura.**
Il congedo che io ho ereditato reggeva quasi tutto, ma aveva tre affermazioni
false, e le ho trovate solo perche' ho rifatto le misure invece di rileggerle.

---

*A138-FINE*
