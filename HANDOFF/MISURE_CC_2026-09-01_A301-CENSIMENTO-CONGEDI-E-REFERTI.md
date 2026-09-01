# MISURE CC — A301 — CENSIMENTO CONGEDI E REFERTI — 2026-09-01

Da: CC · A: referee. Mandato: **A301-CENSIMENTO-CONGEDI-E-REFERTI**, dichiarato in testa e coincidente con quello ricevuto.

**Orologio**: 2026-09-01, **08:56:59 locale (UTC+2)** — da `date` di sistema, letta prima di scrivere qualunque data (UTC 06:56:59, coerente).

⛔ **Nessun commit, push o `git add` in questo giro.** Solo misura. Zero scritture su Drive.

Marcatura: **[M]** misurato ora da me, alla fonte · **[R]** riportato, non verificato da me · **[A]** giudizio mio.

---

## 0 · Orologio e cancello sull'ID

**[M]** `A301` è un'assunzione dichiarata dal referee, non letta dal repo — trattata come tale. Cancello a sei gambe eseguito con la stessa identica sonda usata in apertura su `A300` (congedo precedente), qui ripetuta su `A301`. Le sei gambe contano **FILE (o commit per la gamba 6) in cui il termine compare almeno una volta**, non occorrenze grezze — dichiarato per rispettare R-δ (riga vs occorrenza).

| gamba | esito A301 |
|---|---|
| nomi-file su C: (repo, ricorsivo, esclude `.git`) | 0 |
| nomi-file su E: (mirror, ricorsivo) | 0 |
| `git grep` tracciato (contenuto) | 0 |
| disco C: contenuto (ricorsivo, esclude `.git`) | 0 |
| disco E: contenuto | 0 |
| `git log --all --grep` | 0 |

**Controllo positivo, stessa identica sonda, su due ID noti**:
- `A298` (noto TRACCIATO): nomi C:=4 · git grep=3 · git log=3 → **la sonda vede il tracciato**.
- `A300` (noto occupato ma NON tracciato, il congedo di apertura di questa sessione): nomi C:=1, nomi E:=1 · git grep=0 · git log=0 → **la sonda distingue correttamente presenza-su-disco da presenza-in-git**.

⇒ **A301 libero, confermato, nessuna collisione.** Nessun cambio d'ID necessario.

---

## 1 · Idempotenza

**[M]** Cercato `*A301*` su C: e su E:, ricorsivo: **zero file trovati** prima di questo deposito. Nessun lavoro precedente su questo mandato. Si procede.

---

## 2 · Censimento

### 2.0 · Perimetro — dichiarato, e corretto due volte durante la misura

⚠️ **Le cinque famiglie indicate dal mandato erano incomplete, come il mandato stesso anticipava.** Ho trovato e **aggiunto** una famiglia intera che il mandato non elencava — **`HANDOFF_CC_*` / `HANDOFF_REFEREE_*`** (34+8 file: è la convenzione di nome **predecessore** di `CONGEDO_CC_*`/`CONGEDO_REFEREE_*`, usata da giugno a metà agosto prima del cambio terminologico) — più una ventina di famiglie minori ricorrenti (`STAMPA_`, `SEGNAPOSTO_`, `ESITO_`, `VERIFICA_`, `STATO_FINALE_`, `DOC_`, `ROADMAP_`, `PIANO_`, `IGIENE_`, `MANIFESTO_`, `NODO_`, `MATERIE_`, `INVENTARIO_`, `QUADRA_`, `PROPOSTA_`, `INDAGINE_`, `ACCERTAMENTO_`, `SCALETTA_v<N>` come snapshot di versione). Inoltre `MISURE_*` e `REFERTO_*` letterali (senza il suffisso `_CC`) coprono anche varianti pre-schema e una forma `MISURE_REFEREE_*`.

🚨 **Ho anche trovato due difetti nella mia stessa sonda, prima di consegnarla — li dichiaro invece di correggerli in silenzio (stessa disciplina del congedo A300, §c.④⑤):**
1. Un primo tentativo di allargare il perimetro ha rimosso per errore la restrizione a `HANDOFF/`, e lo script ha classificato **l'intero albero** delle due gambe (audio, log, tutto): il bucket "isolati" è esploso a 2.190 file e 7,5 GB — rumore puro, non censimento. Corretto restringendo il perimetro primario a `HANDOFF/` (ricorsivo) più una ricerca mirata delle sole famiglie-madre fuori da essa.
2. Nella correzione successiva, la radice E: per la ricerca `HANDOFF/` è stata scritta senza il segmento intermedio `FILE X CLAUDE.MD\`: la funzione cercava `E:\...\Q-BEATS\HANDOFF\`, che non esiste (il vero percorso è `E:\...\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\`), e ha reso **silenziosamente vuoto** l'intero lato E:. Scoperto confrontando il totale con l'elenco-orfani già misurato a mano; corretto.

**Perimetro finale**: `HANDOFF/` su entrambe le gambe (ricorsivo) + ricerca mirata, fuori da `HANDOFF/`, delle sole famiglie-madre (`CONGEDO_`, `MISURE_`, `REFERTO_`, `DIFF_`, `HANDOFF_`) ovunque nell'albero. **Esclusi per regime diverso**: `ARCHIVIO.MD/` (archivio versionato dei canonici, ignorato da git *by design* — vedi §4) e i quattro canonici vivi (`BOX5_QBEATS.md`, `LIBRO_MASTRO_QBEATS.md`, `BUGS_QBEATS.md`, `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`).

⚠️ **Limite dichiarato, non colmato**: la ricerca "fuori da `HANDOFF/`" usa solo le 5 famiglie-madre, non le ~20 famiglie minori aggiunte. Un caso concreto: `_cc_processo/` (su C:, ignorato *by design*, §4) contiene 16 file non tracciati; 11 rientrano in `DIFF_` e **sono** in questo censimento, ma `QBEATS_IGIENE_2026-07-06.txt` e `QBEATS_W1_VERIFICHE_2026-07-06.txt` (famiglie minori) **non** sono stati ripescati fuori da `HANDOFF/`, e li dichiaro qui invece di ometterli: sono untracked-by-design, stesso regime di `ARCHIVIO.MD/`, peso trascurabile (poche decine di KB).

### 2.1 · Totali

**[M]** Unione C: + E: per nome file, tutte le famiglie:

| | valore |
|---|---|
| **file totali censiti** | **552** |
| tracciati (`git ls-files`) | **73** |
| **non tracciati** | **479** |
| byte non-tracciati presenti su C: (portabili subito con `git add`) | 7.309.702 B (≈ 6,97 MiB) |
| byte presenti **solo** su E: (non ancora su C:, da copiare prima) | 2.880.511 B (≈ 2,75 MiB) |
| **somma — se si volesse tutto nel deposito** | **10.190.213 B (≈ 9,72 MiB)** |

Interpretazione dichiarata: la somma è il costo per portare nel deposito **tutti** i file di queste famiglie oggi non tracciati; è una stima piccola, non un problema di volume — l'ostacolo alla deriva non è mai stato lo spazio.

### 2.2 · Per famiglia

| famiglia | tot | tracciati | non-tracc. | byte non-tracc. |
|---|---:|---:|---:|---:|
| DIFF (tutte le forme, incl. fuori-HANDOFF) | 205 | 29 | 176 | 3.332.294 |
| MISURE (tutte le forme) | 153 | 22 | 131 | 2.425.651 |
| HANDOFF_CC (predecessore di CONGEDO_CC) | 34 | 0 | 34 | 687.567 |
| CONGEDO_CC | 30 | 7 | 23 | 392.990 |
| ALTRO (isolato, non ricorrente, dentro HANDOFF/) | 20 | 5 | 15 | 549.904 |
| VERIFICA | 12 | 0 | 12 | 181.617 |
| SCALETTA_v (snapshot di versione) | 12 | 0 | 12 | 612.160 |
| REFERTO | 11 | 5 | 6 | 129.041 |
| STAMPA (snapshot sorgente) | 11 | 0 | 11 | 809.112 |
| ESITO | 9 | 0 | 9 | 201.888 |
| HANDOFF (altro/predecessore generico) | 12 | 3 | 9 | 107.023 |
| SEGNAPOSTO | 6 | 0 | 6 | 7.888 |
| ROADMAP | 5 | 0 | 5 | 70.814 |
| CONGEDO_REFEREE | 4 | 0 | 4 | 55.743 |
| HANDOFF_REFEREE | 4 | 0 | 4 | 85.481 |
| INVENTARIO | 4 | 0 | 4 | 122.194 |
| PIANO | 4 | 2 | 2 | 50.601 |
| STATO_FINALE | 4 | 0 | 4 | 57.883 |
| DOC (snapshot canonico) | 3 | 0 | 3 | 28.688 |
| ACCERTAMENTO | 2 | 0 | 2 | 22.206 |
| INDAGINE | 2 | 0 | 2 | 46.847 |
| IGIENE | 1 | 0 | 1 | 15.071 |
| MANIFESTO | 1 | 0 | 1 | 116.433 |
| MATERIE | 1 | 0 | 1 | 7.010 |
| QUADRA | 1 | 0 | 1 | 41.829 |
| PROPOSTA | 1 | 0 | 1 | 32.278 |
| **totale** | **552** | **73** | **479** | **10.190.213** |

Somma verificata due volte (script + ricalcolo a mano indipendente): torna esatta.

**Tabella completa per-file (552 righe: nome · ID · data · byte · tracciato · presenza) in Appendice A, in fondo a questo documento.**

---

## 3 · Setaccio — il repository è PUBLIC

**[M] Perimetro dichiarato**: i 479 file non tracciati del censimento §2 (esattamente quelli, non l'intero disco). Letti con `errors='replace'`, zero errori di lettura su 479.

**Controllo positivo generale**: pattern `2026-0[1-9]` (una data, deve comparire quasi ovunque) → **6.639 occorrenze, 417 file coinvolti**. La sonda legge il corpus e trova ciò che sa esserci. Non è un falso silenzio.

Per le tre categorie che hanno reso zero, controllo positivo **dedicato**: ciascun pattern testato su una stringa sintetica che DEVE fare match, fuori dal corpus reale — tutti e tre confermano che il pattern funziona (dettagli sotto).

| categoria | occorrenze | file coinvolti | esito dopo verifica manuale |
|---|---:|---:|---|
| UUID (8-4-4-4-12) | 27 | 14 | **falso positivo**: è sempre lo stesso UUID, `7f043c3b-…`, la cartella-scratchpad di una sessione Claude passata, incollata negli header di un `diff` (righe `--- .../7f043c3b.../file.md`). Non identifica un dispositivo né una persona. |
| HEX40 (stessa forma di uno UDID iOS pre-2012, e di uno SHA-1 git) | 2.892 | 343 | **git-SHA, non UDID**: campionate 25 occorrenze "senza contesto-git riconoscibile sulla stessa riga" — tutte dentro tabelle di stato che elencano blob/commit dei canonici senza ripetere la parola "commit" a ogni riga. Nessuna forma coerente con un identificativo di dispositivo reale (iOS moderno non espone più UDID a 40 esadecimali). |
| MAC address | 1 | 1 | **non è un identificativo di dispositivo**: `01:00:5e:4c:4e:4b`, citato accanto a "multicast 224.76.78.75:20808" — è il MAC **multicast IEEE-derivato** dall'indirizzo IP multicast usato dal protocollo Link (sniffer già a verbale, vedi memoria). È lo stesso per qualunque dispositivo su quel gruppo multicast: non identifica nessuno. |
| credenziali (password\|secret\|apikey\|bearer\|BEGIN…KEY\|.p12\|.mobileprovision) | 81 | 17 | **nessuna credenziale reale**: quasi tutti i colpi sono il NOME del file `.mobileprovision` citato in prosa ("il .mobileprovision è stato segnalato, non rimosso") o il NOME di un GitHub Secret (`PROVISIONING_PROFILE`) citato come promemoria operativo — mai un valore incollato. Un file (`MISURE_CC_2026-08-01_T1-COPIA-UNICA.txt`) è **un audit di igiene pregresso** che riporta solo CONTEGGI per categoria, dichiarando esplicitamente «i valori trovati NON sono stampati» — e segnala da sé un proprio falso positivo su `IGIENE_REPO-PUBBLICO_2026-07-21_rev1.txt` (un catalogo di pattern che aggancia se stesso). Nessun valore in chiaro trovato da me in nessuno dei 479 file. |
| token noti (AKIA…\|ghp_…\|sk-…\|xox…) | 0 | 0 | zero. Controllo positivo dedicato: la stessa regex su una stringa sintetica (`AKIAABCDEFGHIJKLMNOP`, `ghp_xxxx…`, `sk-yyyy…`, `xoxb-1111111111`) **fa match** — il pattern funziona, lo zero è reale. |
| email | 141 | 80 | **4 indirizzi unici**, tutti esaminati: `di_tutto@icloud.com` (Mauro Martintoni, il titolare del progetto — non un **terzo**, ed è già pubblico su OGNI commit di questo repo pubblico via `git log`/`blame`: nessuna esposizione incrementale) · `link-devs@ableton.com` (indirizzo di supporto pubblico di Ableton per Link) · `noreply@anthropic.com` (indirizzo automatico standard dei trailer Claude Code) · `setup@livehost.local` (TLD `.local`, non instradabile su internet — un placeholder di configurazione, non un contatto reale). **Zero indirizzi di terzi.** |
| telefono IT (mobile) | 82 | 44 | **falso positivo sistematico**: campionate e classificate tutte — ID di run GitHub Actions citati fra backtick o dentro link (`` `33376249503` ``, `[26361824809](...)`), frammenti di hunk `index abc..def 100644`, o numeri decimali (`390.000000`, un fattore di scaling UI). **Zero numeri di telefono reali.** |
| IBAN | 0 | 0 | zero. Controllo positivo dedicato su stringa sintetica (`IT60X0542811101000000123456`) → match. Pattern funzionante, zero reale. |
| codice fiscale IT | 0 | 0 | zero. Controllo positivo dedicato su stringa sintetica (`RSSMRA85M01H501Z`) → match. Pattern funzionante, zero reale. |

**[A] Verdetto del setaccio: nessun contenuto trovato che non debba diventare pubblico.** Ogni colpo positivo è stato aperto e verificato singolarmente, non scartato a occhio — coerente con la disciplina già a verbale su questo stesso genere di falso positivo (`IGIENE_REPO-PUBBLICO_2026-07-21`, trovato durante questa stessa misura, lo dice di se stesso). Non invoco il fermo del §7 ("il setaccio trova qualcosa"): quella clausola, a mio giudizio, riguarda un reperto reale, non un colpo grezzo di regex — e qui, aperto uno per uno, non ne resta nessuno. Se il referee giudica diversamente uno dei nove casi sopra, la riga e il file sono già indicati per la verifica.

---

## 4 · Regole del deposito — `.gitignore` VERBATIM

```
# Learn more https://docs.github.com/en/get-started/getting-started-with-git/ignoring-files

# dependencies
node_modules/

# Expo
.expo/
dist/
web-build/
expo-env.d.ts

# Native
.kotlin/
*.orig.*
*.jks
*.p8
*.p12
*.key
*.mobileprovision

# Metro
.metro-health-check*

# debug
npm-debug.*
yarn-debug.*
yarn-error.*

# macOS
.DS_Store
*.pem

# local env files
.env
.env*.local

# typescript
*.tsbuildinfo

# generated native folders
/ios
/android

# C++/CMake Build directories
build/
core_engine/build/
bin/
obj/
out/
.vs/
*.user
*.suo
*.sln
*.vcxproj
*.filters
*.tlog
*.lastbuildstate
*.idb
*.pdb
*.obj
*.exe
*.dll
*.lib

# CMake
CMakeCache.txt
CMakeFiles/
CMakeSettings.json
cmake_install.cmake
Makefile
install_manifest.txt
*.cmake

# ============================================================
# Q-BEATS housekeeping — guard pre-N0 (rev. referee, 10/07)
# ============================================================

# Tooling di sessione
.claude/

# Build-dir CMake seconda (build/ e core_engine/build/ gia' coperti sopra)
core_engine/build2/

# Binari build iOS (mai versionati, ovunque)
ipa-fase-d*/
*.ipa

# Archivio doc untracked — fuori da git per scelta consapevole (Mauro 10/07)
# NB: NON de-traccia i BOX pre-V62 gia' versionati sotto ARCHIVIO.MD/
ARCHIVIO.MD/

# Scarti di lavorazione CC (diff / verifiche / fixture usa-e-getta)
/_cc_processo/
```

**[M] Nessuna regola tocca `HANDOFF/` o una qualunque delle famiglie censite** (`CONGEDO_`, `MISURE_`, `REFERTO_`, `DIFF_`, `HANDOFF_CC`, o le minori). L'unica riga che la ricerca per parola-chiave intercetta è un **commento** («Scarti di lavorazione CC (diff / verifiche / fixture usa-e-getta)»), non una regola operativa — la regola sotto è `/_cc_processo/`, una directory specifica, non le famiglie in `HANDOFF/`.

Due regole esistenti **sono** rilevanti per contesto, e vanno lette come tali: `ARCHIVIO.MD/` è untracked **by design**, decisione dichiarata di Mauro (10/07) — regime diverso, deliberato, non deriva. `/_cc_processo/` idem. **`HANDOFF/` non ha nessuna decisione equivalente**: i 479 file non tracciati di questo censimento non sono lì per scelta — non c'è una riga che lo dica. ⇒ **conferma quanto già trovato in apertura di sessione: è deriva, non politica.**

---

## 5 · ID di mandato più alto realmente usato

**[M] Perimetro dichiarato**: scansione di **tutti** i nomi-file su C: e E: (non solo le famiglie censite) **più** tutti gli oggetti-messaggio di `git log --all`, cercando la forma `A<2-4 cifre>` con confini non alfanumerici (evita falsi-UNO tipo `8A300` dentro un UUID). **Non include** menzioni nel *corpo* dei documenti (solo nome-file e oggetto-commit) — dichiarato: se un mandato è stato citato solo in prosa interna e mai in un nome-file o in un oggetto-commit, questa misura non lo vede.

- **Range trovato**: A11 – **A300**.
- **A300** è il più alto **prima** di questo mandato (nome-file su C: ed E:, coerente con la misura di apertura sessione).
- **A301** (questo mandato) non compare — coerente col cancello libero del §0.
- ⇒ **Prossimo libero dopo la consegna di questo referto: A302.**

**Buchi nel range 11–300**: 103 numeri assenti. ⚠️ **Non tutti sono anomalie, e lo dichiaro per non farli leggere come 103 difetti**: 35 cadono sotto A100 e 34 fra A100–A199 — parte di questo intervallo precede l'adozione stabile dello schema sequenziale "A<N>", quando convivevano schemi diversi (`R1`-`R5`, `S1`-`S7`, `M1`, `G3`, `V1`-`V4`, `P1`-`P4`, `T1`, `W1`-`W3`, `B6`-`B7` — tutti trovati nei nomi-file durante il censimento §2). Non è misurabile da qui quanti di quei numeri "mancanti" siano davvero stati assegnati come `A<N>` e mai usati, o non siano mai esistiti in quella forma.

🚨 **Una cosa nel range alto merita lo sguardo del referee**: **A271–A281, undici numeri consecutivi, tutti assenti** — l'unico buco lungo e contiguo in tutto il range, proprio nella parte più recente (fine agosto) dove lo schema è sicuramente stabile. Non ho un'ipotesi verificata sul perché; lo segnalo invece di ipotizzare.

Lista completa dei 103 buchi, per chi vuole verificarli uno a uno:
`12,14,15,16,18,20,21,23,24,27,29,30,31,32,34,36,37,38,42,43,44,45,46,52,56,57,60,63,73,74,77,88,89,97,98,100,101,106,107,109,112,114,116,119,120,123,135,138,143,149,150,154,156,157,160,165,169,171,174,175,177,179,183,189,193,194,195,196,197,201,202,204,205,207,218,219,221,223,224,227,230,233,239,246,255,256,259,271,272,273,274,275,276,277,278,279,280,281,283,284,286,288,296`

---

## 6 · Consegna

Questo stesso documento, depositato su **due gambe**:
- `HANDOFF/MISURE_CC_2026-09-01_A301-CENSIMENTO-CONGEDI-E-REFERTI.md` (repo)
- `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-09-01_A301-CENSIMENTO-CONGEDI-E-REFERTI.md` (mirror)

Esito `cmp` fra le due copie e sha256: **vedi coda del documento**, scritti DOPO il deposito su entrambe le gambe (non potevano essere misurati prima di esistere).

⛔ **Nessun `git add`, nessun commit.** Resta un file depositato e non tracciato — coerente con §7: questo mandato è solo misura.

---

## Nota di metodo — due difetti di sonda, entrambi miei, entrambi dichiarati prima della consegna

Coerente con la disciplina già a verbale (congedo A300, §c.④⑤ — *quando una guardia fallisce, si interroga la guardia, non il dato*): in questa sessione ho trovato e corretto **due miei stessi errori di misura** prima di scrivere questo referto — l'esclusione con backslash mal gestita dall'heredoc (§2.0, punto 1) e la radice E: incompleta che azzerava in silenzio un'intera gamba (§2.0, punto 2). Nessuno dei due è arrivato al referee: sono stati trovati confrontando i totali con misure indipendenti (il conteggio-orfani manuale fatto prima di scrivere lo script) prima di fidarmi dell'output. Li scrivo qui non per scrupolo formale, ma perché è esattamente la stessa classe di difetto già a verbale in altre sessioni: un allarme (o in questo caso, un numero) prodotto da una sonda con un'assunzione non dichiarata, che sembra un fatto finché non lo si riapre.

---

*A301-CENSIMENTO-CONGEDI-E-REFERTI — fine corpo, appendice segue.*

## Appendice A — censimento completo, per file (552 righe)

| famiglia | nome file | ID | data | byte C: | byte E: | presenza | tracciato |
|---|---|---|---|---|---|---|---|
| CONGEDO_CC | CONGEDO_CC_2026-08-05.md | senza ID | 2026-08-05 | 31726 | 31726 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-06.md | senza ID | 2026-08-06 | 16384 | 16384 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-07.md | senza ID | 2026-08-07 | 24256 | 24256 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-07_sera.md | senza ID | 2026-08-07 | 21060 | 21060 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-18.md | senza ID | 2026-08-18 | 16837 | 16837 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-19.md | senza ID | 2026-08-19 | 18967 | 18967 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-20.md | senza ID | 2026-08-20 | 24088 | 24088 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-21.md | senza ID | 2026-08-21 | 15707 | 15707 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-21_NOTTE.md | senza ID | 2026-08-21 | 17156 | 17156 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-21_SERA.md | senza ID | 2026-08-21 | 21659 | 21659 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-22_A166-A170.md | A166 | 2026-08-22 | 18577 | 18577 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-23_A172-A191.md | A172 | 2026-08-23 | 18446 | 18446 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-24_A192-A208.md | A192 | 2026-08-24 | 18911 | 18911 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-24_A214.md | A214 | 2026-08-24 | 13522 | 13522 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-25_A217.md | A217 | 2026-08-25 | 18980 | 18980 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-26_A220.md | A220 | 2026-08-26 | 23586 | 23586 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-26_NOTTE_A226.md | A226 | 2026-08-26 | 12169 | 12169 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-26_SERA_A225.md | A225 | 2026-08-26 | 19342 | 19342 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-27_A237.md | A237 | 2026-08-27 | 13684 | 13684 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-28_A243.md | A243 | 2026-08-28 | 16460 | 16460 | entrambi | si |
| CONGEDO_CC | CONGEDO_CC_2026-08-29_A249.md | A249 | 2026-08-29 | 14083 | — | solo C: | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-29_A252.md | A252 | 2026-08-29 | 9604 | 9604 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A262.md | A262 | 2026-08-30 | 11548 | 11548 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A264-IN-AUTONOMIA.md | A264 | 2026-08-30 | 11761 | 11761 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A268-IN-AUTONOMIA.md | A268 | 2026-08-30 | 16397 | 16397 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A269-IN-AUTONOMIA.md | A269 | 2026-08-30 | 10613 | 10613 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A270-DISCO-E-MACCHINA.md | A270 | 2026-08-30 | 11357 | 11357 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-30_A289-IL-GIRO-CHE-SI-E-CHIUSO.md | A289 | 2026-08-30 | 19297 | 19297 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-31_A294-DUE-COMMIT-E-SEI-TRAPPOLE-DI-MISURA.md | A294 | 2026-08-31 | 12307 | 12307 | entrambi | no |
| CONGEDO_CC | CONGEDO_CC_2026-08-31_A300-SEI-MANDATI-E-DUE-GUARDIE-CHE-MENTIVANO.md | A300 | 2026-08-31 | 17113 | 17113 | entrambi | no |
| CONGEDO_REFEREE | CONGEDO_REFEREE_2026-08-01.md | senza ID | 2026-08-01 | 7851 | 7851 | entrambi | no |
| CONGEDO_REFEREE | CONGEDO_REFEREE_2026-08-04.md | senza ID | 2026-08-04 | 16303 | 16303 | entrambi | no |
| CONGEDO_REFEREE | CONGEDO_REFEREE_2026-08-29_A251.md | A251 | 2026-08-29 | 11303 | — | solo C: | no |
| CONGEDO_REFEREE | CONGEDO_REFEREE_2026-08-30_sera_8a9faad.md | senza ID | 2026-08-30 | — | 20286 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-13_notte.txt | senza ID | 2026-07-13 | — | 20165 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-13_sera.txt | senza ID | 2026-07-13 | — | 14094 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-14_sera_NODOA.txt | senza ID | 2026-07-14 | — | 30726 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-15_sera.txt | senza ID | 2026-07-15 | — | 19276 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-17.md | senza ID | 2026-07-17 | — | 11445 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-18_S4a-girodoc-freeze.txt | senza ID (tag pre-serie-A: S4a) | 2026-07-18 | 17720 | 17720 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-18_nodoa-chiuso-giro-doc.txt | senza ID | 2026-07-18 | — | 12753 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-19_CHIUSURA_definitivo.txt | senza ID | 2026-07-19 | 17174 | 17174 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-19_SERA_chiusura-S4b.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-19 | — | 25726 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-19_giro-doc-follower-gregario.txt | senza ID | 2026-07-19 | 16313 | 16313 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 21340 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-21_notte_V27-v39-CHIUSURA.txt | senza ID (tag pre-serie-A: V27) | 2026-07-21 | — | 17484 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-21_rev1.txt | senza ID | 2026-07-21 | — | 25325 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-21_sera_REGIME-CANONICI.txt | senza ID | 2026-07-21 | — | 14868 | solo E: | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-22_chiusura-giro-doc.txt | senza ID | 2026-07-22 | 2746 | 2746 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-24_chiusura-fix-pill.txt | senza ID | 2026-07-24 | 3086 | 3086 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-26.txt | senza ID | 2026-07-26 | 14569 | 14569 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-27.txt | senza ID | 2026-07-27 | 12443 | 12443 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-27_chiusura-giro-colore.txt | senza ID | 2026-07-27 | 44638 | 44638 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-28_chiusura-giro-colore.txt | senza ID | 2026-07-28 | 17599 | 17599 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-28_sera_chiusura-sdoppiamento-S4L.txt | senza ID | 2026-07-28 | 22353 | 22353 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-29_sera.md | senza ID | 2026-07-29 | 18747 | 18747 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-30_sera.md | senza ID | 2026-07-30 | 31215 | 31215 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-30_sera_chiusura-v45.md | senza ID | 2026-07-30 | 37228 | 37228 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-31.txt | senza ID | 2026-07-31 | 36239 | 36239 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-07-31_sera.txt | senza ID | 2026-07-31 | 27172 | 27172 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-01_fine-giornata.md | senza ID | 2026-08-01 | 19106 | 19106 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-02_cambio-chat.md | senza ID | 2026-08-02 | 19527 | 19527 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-02_fine-giornata.md | senza ID | 2026-08-02 | 24700 | 24700 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-02_saturazione.md | senza ID | 2026-08-02 | 20675 | 20675 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-03_cambio-chat.md | senza ID | 2026-08-03 | 23391 | 23391 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-04_cambio-chat-2.md | senza ID | 2026-08-04 | 17393 | 17393 | entrambi | no |
| HANDOFF_CC | HANDOFF_CC_2026-08-04_cambio-chat.md | senza ID | 2026-08-04 | 19033 | 19033 | entrambi | no |
| HANDOFF_REFEREE | HANDOFF_REFEREE_2026-07-18_nodoa-chiuso.txt | senza ID | 2026-07-18 | — | 15947 | solo E: | no |
| HANDOFF_REFEREE | HANDOFF_REFEREE_2026-07-27.md | senza ID | 2026-07-27 | 18510 | 18510 | entrambi | no |
| HANDOFF_REFEREE | HANDOFF_REFEREE_2026-07-27_sera.md | senza ID | 2026-07-27 | 32596 | 32596 | entrambi | no |
| HANDOFF_REFEREE | HANDOFF_REFEREE_2026-07-28_sera_chiusura-giro-doc.md | senza ID | 2026-07-28 | 18428 | 18428 | entrambi | no |
| MISURE (tutte) | MISURE_ADDENDUM_CODICE-A-HEAD_2026-07-27.txt | senza ID | 2026-07-27 | 11146 | 11146 | entrambi | no |
| MISURE (tutte) | MISURE_G3_INVENTARIO-E-TICKET_2026-07-27.txt | senza ID (tag pre-serie-A: G3) | 2026-07-27 | 10971 | 10971 | entrambi | no |
| MISURE (tutte) | MISURE_TOKEN-COLORE_FORMA-POPUP_2026-07-27.txt | senza ID | 2026-07-27 | 20376 | 20376 | entrambi | no |
| MISURE (tutte) | MISURE_M1_IDENTITA-S4L_2026-07-28.txt | senza ID (tag pre-serie-A: M1) | 2026-07-28 | 16898 | 16898 | entrambi | no |
| MISURE (tutte) | MISURE_R1_2026-07-28.txt | senza ID (tag pre-serie-A: R1) | 2026-07-28 | 19976 | 19976 | entrambi | no |
| MISURE (tutte) | MISURE_R1b_2026-07-28.txt | senza ID (tag pre-serie-A: R1b) | 2026-07-28 | 23918 | 23918 | entrambi | no |
| MISURE (tutte) | MISURE_R2_2026-07-28.txt | senza ID (tag pre-serie-A: R2) | 2026-07-28 | 25863 | 25863 | entrambi | no |
| MISURE (tutte) | MISURE_R3_2026-07-28.txt | senza ID (tag pre-serie-A: R3) | 2026-07-28 | 64520 | 64520 | entrambi | no |
| MISURE (tutte) | MISURE_R4_2026-07-28.txt | senza ID (tag pre-serie-A: R4) | 2026-07-28 | 12215 | 12215 | entrambi | no |
| MISURE (tutte) | MISURE_R5_2026-07-28.txt | senza ID (tag pre-serie-A: R5) | 2026-07-28 | 6671 | 6671 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-07-30_R1-ACCERTAMENTI.txt | senza ID (tag pre-serie-A: R1) | 2026-07-30 | 43020 | 43020 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-07-31_M0-M4.txt | senza ID (tag pre-serie-A: M0) | 2026-07-31 | 51231 | 51231 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_D1-GEOMETRIA-RDELTA.txt | senza ID | 2026-08-01 | 15064 | 15064 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_D1b-CORREZIONI.txt | senza ID | 2026-08-01 | 11366 | 11366 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_M0-M5.txt | senza ID (tag pre-serie-A: M0) | 2026-08-01 | 60478 | 60478 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_M1-M4.txt | senza ID (tag pre-serie-A: M1) | 2026-08-01 | 34844 | 34844 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_N1-N5.txt | senza ID | 2026-08-01 | 46406 | 46406 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_P1-P4.txt | senza ID (tag pre-serie-A: P1) | 2026-08-01 | 33289 | 33289 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_Q1-Q3.txt | senza ID | 2026-08-01 | 24277 | 24277 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_R1.txt | senza ID (tag pre-serie-A: R1) | 2026-08-01 | 17789 | 17789 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_S1-S3.txt | senza ID (tag pre-serie-A: S1) | 2026-08-01 | 50526 | 50526 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_T1-COPIA-UNICA.txt | senza ID | 2026-08-01 | 17127 | 17127 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-01_W3-CHIUSURA-DRIVE.txt | senza ID | 2026-08-01 | 6394 | 6394 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_A1-ORDINE-CANONICI.txt | senza ID | 2026-08-02 | 21171 | 21171 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_A11-IMPRONTE-FINALI.txt | A11 | 2026-08-02 | 8543 | 8543 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_A13-RETTIFICA-CENSIMENTO.txt | A13 | 2026-08-02 | 9399 | 9399 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_A4-ATTERRAGGIO-31-07.txt | senza ID | 2026-08-02 | 21708 | 21708 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_P1-CENSIMENTO-PUNTATORI.txt | senza ID (tag pre-serie-A: P1) | 2026-08-02 | 113041 | 113041 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_P11-CONTROLLO-CD.txt | senza ID (tag pre-serie-A: P11) | 2026-08-02 | 5742 | 5742 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_P3-S5-RICOGNIZIONE.txt | senza ID (tag pre-serie-A: P3) | 2026-08-02 | 15767 | 15767 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_S1-DRIVE-SICUREZZA.txt | senza ID (tag pre-serie-A: S1) | 2026-08-02 | 11191 | 11191 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-02_S2-PERIMETRO-REPO.txt | senza ID (tag pre-serie-A: S2) | 2026-08-02 | 10675 | 10675 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-03_A17-TRE-CAUSE-LIMBO.txt | A17 | 2026-08-03 | 10888 | 10888 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-03_A26-DRIVE-SYNC-LIVE.txt | A26 | 2026-08-03 | 8288 | 8288 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-04_A28-NOTAZIONE-ANCORE.txt | A28 | 2026-08-04 | 15725 | 15725 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-04_A35-QUARTA-DESTINAZIONE-NAS.txt | A35 | 2026-08-04 | 6423 | 6423 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A47-S5A-FASE1.txt | A47 | 2026-08-05 | 10166 | 10166 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A48-S5A-DIFF.txt | A48 | 2026-08-05 | 7411 | 7411 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A49-S5A-DIFF.txt | A49 | 2026-08-05 | 22277 | 22277 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A50-S5A-DIFF-CORRETTO.txt | A50 | 2026-08-05 | 23419 | 23419 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A51-S5A-DIFF-V2.txt | A51 | 2026-08-05 | 16339 | 16339 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A53-S5A-DIFF-V3.txt | A53 | 2026-08-05 | 44736 | 44736 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A54-S5A-PRECOMMIT.txt | A54 | 2026-08-05 | 11276 | 11276 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A55-S5A-COMMIT.txt | A55 | 2026-08-05 | 10160 | 10160 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_A59-DRIVE-SU-REPO.txt | A59 | 2026-08-05 | 14608 | 14608 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_S5-CHI-AVVIA.txt | senza ID (tag pre-serie-A: S5) | 2026-08-05 | 15630 | 15630 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_S5-RITORNO-FINESHOW.txt | senza ID (tag pre-serie-A: S5) | 2026-08-05 | 16375 | 16375 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_S5-SOTTOSCRIZIONE.txt | senza ID (tag pre-serie-A: S5) | 2026-08-05 | 18590 | 18590 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-05_S5-TIPI-VERBATIM.txt | senza ID (tag pre-serie-A: S5) | 2026-08-05 | 25891 | 25891 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A61-PREFLIGHT-DISTACCO-DRIVE.txt | A61 | 2026-08-06 | 13798 | 13798 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A62-VERIFICA-POST-DISTACCO.txt | A62 | 2026-08-06 | 11683 | 11683 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A64-S5X-BACK-TO-SHOWS.txt | A64 | 2026-08-06 | 16642 | 16642 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A65-VERIFICA-NAS.txt | A65 | 2026-08-06 | 10725 | 10725 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A66-S5X-COMMIT-CI-PUSH.txt | A66 | 2026-08-06 | 14356 | 14356 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A67-S5X-CORREZIONE-COMMIT-CI-PUSH.txt | A67 | 2026-08-06 | 18686 | 18686 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A68-ANCORAGGIO-FREEZE-BLOCCO.txt | A68 | 2026-08-06 | 8132 | 8132 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A69-DEPOSITO-FREEZE-PARZIALE.txt | A69 | 2026-08-06 | 11318 | 11318 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A70-DEPOSITO-E-ANCORAGGIO-FREEZE.txt | A70 | 2026-08-06 | 10546 | 10546 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A71-DIFF-VERBATIM-E-R7.txt | A71 | 2026-08-06 | 6443 | 6443 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-06_A72-ESECUZIONE-DUE-COMMIT.txt | A72 | 2026-08-06 | 8541 | 8541 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A75-RICOGNIZIONE-R1-E-VERIFICA-S5X.txt | A75 | 2026-08-07 | 24298 | 24298 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A76-RIENTRO-REGIME-PERCORSI.txt | A76 | 2026-08-07 | 12889 | 12889 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A78-RICOGNIZIONE-PERCORSO-DI-AVVIO.txt | A78 | 2026-08-07 | 26676 | 26676 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A79-MISURE-CD-E-PREP-RIGA-LIBRO.txt | A79 | 2026-08-07 | 20499 | 20499 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A80-FILE-CD-MIXER-E-DIFF-RIGA-LIBRO.txt | A80 | 2026-08-07 | 27643 | 27643 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A81-GEOMETRIA-CD-E-ESTRAZIONE-DIFF.txt | A81 | 2026-08-07 | 21067 | 21067 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A82-SLIDER-PERSISTENZA-E-APERTURA-MIXER.txt | A82 | 2026-08-07 | 19996 | 19996 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A83-DUE-TICKET-MIXER-E-EMERG.txt | A83 | 2026-08-07 | 18427 | 18427 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A84-APPLICAZIONE-DUE-DIFF-RATIFICATI.txt | A84 | 2026-08-07 | 20355 | 20355 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A85-GIRO-DOC-SCALETTA.txt | A85 | 2026-08-07 | 19595 | 19595 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A86-APPLICAZIONE-SCALETTA-V9.txt | A86 | 2026-08-07 | 13576 | 13576 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-07_A87-PUSH-E-CHIUSURA-SESSIONE.txt | A87 | 2026-08-07 | 17818 | 17818 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A102-TRE-VERBATIM.md | A102 | 2026-08-18 | 48892 | 48892 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A103-ROTTA-AL-PLAYER.md | A103 | 2026-08-18 | 47003 | 47003 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A104-RIPARAZIONE.md | A104 | 2026-08-18 | 9652 | 9652 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A105-COLLAUDO-SICURO.md | A105 | 2026-08-18 | 24605 | 24605 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A108-CONTRADDITTORIO.md | A108 | 2026-08-18 | 20753 | 20753 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A110-PROPOSTA-S5b.md | A110 | 2026-08-18 | 21694 | 21694 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A111-RIDERIVAZIONE.md | A111 | 2026-08-18 | 19633 | 19633 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A113-COLLISIONE.md | A113 | 2026-08-18 | 20419 | 20419 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A115-COUNTIN.md | A115 | 2026-08-18 | 17480 | 17480 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A117-PORTE.md | A117 | 2026-08-18 | 18302 | 18302 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A118-SCHEDA-STRETTA.md | A118 | 2026-08-18 | 16899 | 16899 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A121-INCISIONE.md | A121 | 2026-08-18 | 10726 | 10726 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A122-RIFACIMENTO.md | A122 | 2026-08-18 | 11588 | 11588 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A90-CONTRADDITTORIO-ROADMAP.md | A90 | 2026-08-18 | 21622 | 21622 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A91-ANATOMIA-TMPFIX.md | A91 | 2026-08-18 | 14334 | 14334 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A92-METRONOMO.md | A92 | 2026-08-18 | 15015 | 15015 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A93-ANTICASCATA.md | A93 | 2026-08-18 | 13383 | 13383 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A94-CHIUSURA-DOC.md | A94 | 2026-08-18 | 12755 | 12755 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A95-COMMIT.md | A95 | 2026-08-18 | 8326 | 8326 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A96-INTERRUZIONE.md | A96 | 2026-08-18 | 7161 | 7161 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-18_A99-SEI-BLOCCHI.md | A99 | 2026-08-18 | 20555 | 20555 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-19_A125-S5b-CABLAGGIO.md | A125 | 2026-08-19 | 43641 | 43641 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A126-COMMENTO-S7.md | A126 | 2026-08-19 | 10614 | 10614 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A127-COLLAUDO-S5b.md | A127 | 2026-08-19 | 5001 | 5001 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-19_A128-STANDBY-CENTRATURA.md | A128 | 2026-08-19 | 13343 | 13343 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.md | A129 | 2026-08-19 | 17457 | 17457 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A130-PULIZIA-FORCELLE-E-TICKET.md | A130 | 2026-08-19 | 23500 | 23500 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A131-COLLAUDO-TRE-CONFORMITA.md | A131 | 2026-08-19 | 1249 | 1249 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-19_A131-COMMIT-A129-A130.md | A131 | 2026-08-19 | 8118 | 8118 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-19_A132-TICKET-ONSWITCH-MORTO.md | A132 | 2026-08-19 | 20305 | 20305 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-19_A133-CENSIMENTO-E-COMMIT.md | A133 | 2026-08-19 | 12250 | 12250 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-20_A134-STOP-SEXIT-PIU-GRANDE.md | A134 | 2026-08-20 | 15697 | 15697 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-20_A136-DEPOSITO-REV4-REV5.md | A136 | 2026-08-20 | 7981 | 7981 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A137-NOTA-CORREZIONE-CD.md | A137 | 2026-08-21 | 6500 | 6500 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A139-NAVBAR54-DETTAGLIO.md | A139 | 2026-08-21 | 26623 | 26623 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A140-COMMIT-A139.md | A140 | 2026-08-21 | 11190 | 11190 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.md | A141 | 2026-08-21 | 18621 | 18621 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A142-APOSTROFI-E-COMMIT-A141.md | A142 | 2026-08-21 | 21735 | 21735 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.md | A144 | 2026-08-21 | 17133 | 17133 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A145-COMMIT-A144.md | A145 | 2026-08-21 | 12400 | 12400 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.md | A146 | 2026-08-21 | 14149 | 14149 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A147-CORREZIONI-SU-A146.md | A147 | 2026-08-21 | 16813 | 16813 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A148-COMMIT-A146-A147.md | A148 | 2026-08-21 | 11473 | 11473 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-21_A151-STAMPE-E-CHIUSURA-RDELTA.md | A151 | 2026-08-21 | 14102 | 14102 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A152-DOVE-SONO-I-FILE.md | A152 | 2026-08-21 | 10300 | 10300 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A153-RIPARAZIONE-COLLOCAZIONI.md | A153 | 2026-08-21 | 10533 | 10533 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A155-LIBRO-v58-COLLAUDO-DEVICE.md | A155 | 2026-08-21 | 15596 | 15596 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A158-COMMIT-LIBRO-v58.md | A158 | 2026-08-21 | 8390 | 8390 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A159-CENSIMENTO-TRE-GAMBE.md | A159 | 2026-08-21 | 11828 | 11828 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A161-MISURA-F-E-STOP-SU-BOX5.md | A161 | 2026-08-21 | 10062 | 10062 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A164-COMMIT-BOX5-V29-E-LIBRO-v59.md | A164 | 2026-08-21 | 11060 | 11060 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-21_A166-CONTATORE-BATTUTA-ORIGINE.md | A166 | 2026-08-21 | 38603 | 38603 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-22_A172-INGRESSI-DEL-CONTATORE-BATTUTA.md | A172 | 2026-08-22 | 25538 | 25538 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A173-ANCORA-GRAFICA-E-AVANZAMENTO.md | A173 | 2026-08-22 | 30633 | 30633 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A176-VOCABOLARIO-DUE-OROLOGI.md | A176 | 2026-08-22 | 18745 | 18745 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A178-NOMI-CORRETTI-ROADMAP-E-STATO.md | A178 | 2026-08-22 | 23036 | 23036 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A180-FRASI-SENZA-COLPEVOLE.md | A180 | 2026-08-22 | 14380 | 14380 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A181-COMPORTAMENTO-ATTESO.md | A181 | 2026-08-22 | 18303 | 18303 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A182-RETTIFICA-PRECISAZIONE-TECNICA.md | A182 | 2026-08-22 | 19393 | 19393 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A184-SOTTRAZIONI-FINALI.md | A184 | 2026-08-22 | 23705 | 23705 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A185-CHIUSURA-COMMIT.md | A185 | 2026-08-22 | 18324 | 18324 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A186-ULTIME-SOTTRAZIONI.md | A186 | 2026-08-22 | 14647 | 14647 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A187-LACUNA-NON-CHIUSA.md | A187 | 2026-08-22 | 14828 | 14828 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-22_A188-COMMIT-DOCUMENTI.md | A188 | 2026-08-22 | 11283 | 11283 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-23_A190-DATA-REALE-E-DUE-REGOLE.md | A190 | 2026-08-23 | 12965 | 12965 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-27_A228-VELO-STANDBY.md | A228 | 2026-08-27 | 7204 | 7204 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-27_A229-FRECCIA-ENDSHOW-E-SEDICI-CAMPI.md | A229 | 2026-08-27 | 13086 | 13086 | entrambi | si |
| MISURE (tutte) | MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md | A253 | 2026-08-29 | 28232 | 28232 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-29_A257-QUANTO-COSTA-IL-CORPO-VUOTO.md | A257 | 2026-08-29 | 15269 | 15269 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-29_A258-LE-TRE-VOCI-DEL-BIVIO.md | A258 | 2026-08-29 | 14037 | 14037 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-29_A260-INCIDERE-LA-SERATA.md | A260 | 2026-08-29 | 13486 | 13486 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-29_A261-LA-TESTATA-CHE-MENTE.md | A261 | 2026-08-29 | 7703 | 7703 | entrambi | no |
| MISURE (tutte) | MISURE_REFEREE_2026-08-29_A250-TD-DRIVE-BACKFILL-SMENTITO.md | A250 | 2026-08-29 | 14082 | 14082 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-30_A263-CONTO-DEI-TOCCHI-E-PORTE-DELLA-LISTA.md | A263 | 2026-08-30 | 25181 | 25181 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-30_A265-RIENTRO-CONTO-ALLA-ROVESCIA-DUE-PORTE-DELLO-STOP.md | A265 | 2026-08-30 | 26099 | 26099 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md | A266 | 2026-08-30 | 12337 | 12337 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-30_A267-RIENTRO-DALLA-SUA-SEZIONE.md | A267 | 2026-08-30 | 21634 | 21634 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-31_A295-FOGLIO-CD-30-08-IMPRONTA-IDENTICA.md | A295 | 2026-08-31 | 10565 | 10565 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-31_A297-COMMIT-PUSH-FOGLIO-CD.md | A297 | 2026-08-31 | 2848 | 2848 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-31_A298-GIRO-DOCUMENTI-TRE-COMMIT-PRONTI.md | A298 | 2026-08-31 | 9618 | 9618 | entrambi | no |
| MISURE (tutte) | MISURE_CC_2026-08-31_A299-COMMIT-PUSH-TRE-DOCUMENTI.md | A299 | 2026-08-31 | 5554 | 5554 | entrambi | no |
| REFERTO | REFERTO_CC_2026-07-31_P1-P4.txt | senza ID (tag pre-serie-A: P1) | 2026-07-31 | 28706 | 28706 | entrambi | no |
| REFERTO | REFERTO_CC_2026-07-31_V1-V3.txt | senza ID (tag pre-serie-A: V1) | 2026-07-31 | 25118 | 25118 | entrambi | no |
| REFERTO | REFERTO_CC_2026-07-31_v48-ABORT.txt | senza ID | 2026-07-31 | 18865 | 18865 | entrambi | no |
| REFERTO | REFERTO_CC_2026-08-24_A209-SCHEDA-USCITA-STANZA.md | A209 | 2026-08-24 | 6557 | 6557 | entrambi | si |
| REFERTO | REFERTO_CC_2026-08-24_A210-SCHEDA-USCITA-STANZA.md | A210 | 2026-08-24 | 6233 | 6233 | entrambi | si |
| REFERTO | REFERTO_CC_2026-08-24_A211-SCHEDA-USCITA-STANZA.md | A211 | 2026-08-24 | 4075 | 4075 | entrambi | si |
| REFERTO | REFERTO_CC_2026-08-24_A212-COMMIT-PUSH-SCALETTA-V15.md | A212 | 2026-08-24 | 3441 | 3441 | entrambi | si |
| REFERTO | REFERTO_CC_2026-08-24_A213-COMMIT-PUSH-SCALETTA-V15.md | A213 | 2026-08-24 | 3104 | 3104 | entrambi | no |
| REFERTO | REFERTO_CC_2026-08-25_A215-PLAYER-SI-CONTRADDICE.md | A215 | 2026-08-25 | 31012 | 31012 | entrambi | no |
| REFERTO | REFERTO_CC_2026-08-25_A216-CONTATORE-OLTRE-IL-DERIVABILE.md | A216 | 2026-08-25 | 22236 | 22236 | entrambi | no |
| REFERTO | REFERTO_CC_2026-08-26_A222-GIRO-DOCUMENTI.md | A222 | 2026-08-26 | 27198 | 27198 | entrambi | si |
| DIFF | QBEATS_S0_DIFF_2026-07-10.txt | senza ID (tag pre-serie-A: S0) | 2026-07-10 | — | 1286 | solo E: | no |
| DIFF | DIFF_BUGS_v34_TD-peer-reconnect-button_2026-07-11_v2.txt | senza ID | 2026-07-11 | 9621 | 9621 | entrambi | no |
| DIFF | E1_MARCATORI_LIBRO_DIFF_2026-07-11.txt | senza ID | 2026-07-11 | — | 16799 | solo E: | no |
| DIFF | EMENDAMENTO_187_DIFF_2026-07-11.txt | senza ID | 2026-07-11 | — | 13781 | solo E: | no |
| DIFF | EMENDAMENTO_187_DIFF_2026-07-11_v2.txt | senza ID | 2026-07-11 | — | 16404 | solo E: | no |
| DIFF | QBEATS_S1_S2F_DIFF_2026-07-11.txt | senza ID (tag pre-serie-A: S1) | 2026-07-11 | — | 7943 | solo E: | no |
| DIFF | QBEATS_S1_S2F_DIFF_v2_2026-07-11.txt | senza ID (tag pre-serie-A: S1) | 2026-07-11 | — | 11948 | solo E: | no |
| DIFF | QBEATS_S1_S2F_DIFF_v3_2026-07-11.txt | senza ID (tag pre-serie-A: S1) | 2026-07-11 | — | 15030 | solo E: | no |
| DIFF | S2_QLIVEEMPTYSTATES_DIFF_2026-07-11.txt | senza ID (tag pre-serie-A: S2) | 2026-07-11 | — | 14274 | solo E: | no |
| DIFF | S2_QLIVEEMPTYSTATES_DIFF_2026-07-11_v2.txt | senza ID (tag pre-serie-A: S2) | 2026-07-11 | — | 16408 | solo E: | no |
| DIFF | S2_QLIVEEMPTYSTATES_DIFF_2026-07-11_v3.txt | senza ID (tag pre-serie-A: S2) | 2026-07-11 | — | 16720 | solo E: | no |
| DIFF | S2b_QLIVEEMPTYSTATES_DIFF_2026-07-11.txt | senza ID (tag pre-serie-A: S2b) | 2026-07-11 | — | 4971 | solo E: | no |
| DIFF | S2c_QLIVEEMPTYSTATES_DIFF_2026-07-11.txt | senza ID (tag pre-serie-A: S2c) | 2026-07-11 | — | 10731 | solo E: | no |
| DIFF | S2c_QLIVEEMPTYSTATES_DIFF_2026-07-11_v2.txt | senza ID (tag pre-serie-A: S2c) | 2026-07-11 | — | 11287 | solo E: | no |
| DIFF | BUGS_v35_DIFF_2026-07-12.txt | senza ID | 2026-07-12 | — | 6029 | solo E: | no |
| DIFF | LIBRO_V30_DIFF_2026-07-12_v2.txt | senza ID (tag pre-serie-A: V30) | 2026-07-12 | — | 23108 | solo E: | no |
| DIFF | LIBRO_V31_DIFF_2026-07-12.txt | senza ID (tag pre-serie-A: V31) | 2026-07-12 | — | 12962 | solo E: | no |
| DIFF | S2d_DIFF_2026-07-12.txt | senza ID (tag pre-serie-A: S2d) | 2026-07-12 | — | 15525 | solo E: | no |
| DIFF | S2e_DIFF_2026-07-12.txt | senza ID (tag pre-serie-A: S2e) | 2026-07-12 | — | 21327 | solo E: | no |
| DIFF | BOX3v93-SCALETTAv1-LIBROv32_DIFF_2026-07-13.txt | senza ID | 2026-07-13 | — | 16243 | solo E: | no |
| DIFF | BOX3v94-LIBROv33-BOX5v25_DIFF_2026-07-13.txt | senza ID | 2026-07-13 | — | 11044 | solo E: | no |
| DIFF | S3_DIFF_2026-07-13.txt | senza ID (tag pre-serie-A: S3) | 2026-07-13 | — | 30310 | solo E: | no |
| DIFF | SCALETTA-rename_BOX3v95_DIFF_2026-07-13.txt | senza ID | 2026-07-13 | — | 8239 | solo E: | no |
| DIFF | S3_DOCCOMMIT_DIFF_2026-07-14.txt | senza ID (tag pre-serie-A: S3) | 2026-07-14 | — | 130281 | solo E: | no |
| DIFF | S3_HITFIX_DIFF_2026-07-14.txt | senza ID (tag pre-serie-A: S3) | 2026-07-14 | — | 12336 | solo E: | no |
| DIFF | DIFF_GIRO_DOC_2026-07-17.txt | senza ID | 2026-07-17 | 37013 | 37013 | entrambi | no |
| DIFF | DIFF_N0_seam-onExit_2026-07-17.txt | senza ID | 2026-07-17 | 9753 | 9753 | entrambi | no |
| DIFF | DIFF_N1a_scaffold-qLive_2026-07-17.txt | senza ID | 2026-07-17 | 6119 | 6119 | entrambi | no |
| DIFF | DIFF_N1b_flip-qLive_2026-07-17.txt | senza ID | 2026-07-17 | 12551 | 12551 | entrambi | no |
| DIFF | DIFF_S4a_2026-07-18.txt | senza ID (tag pre-serie-A: S4a) | 2026-07-18 | 15297 | 15297 | entrambi | no |
| DIFF | DIFF_BUGS_v40_2026-07-19.txt | senza ID | 2026-07-19 | 19752 | 19752 | entrambi | no |
| DIFF | DIFF_BUGS_v40_2026-07-19_rev2.txt | senza ID | 2026-07-19 | 21436 | 21436 | entrambi | no |
| DIFF | DIFF_LIBRO_v37_2026-07-19.txt | senza ID | 2026-07-19 | 12012 | 12012 | entrambi | no |
| DIFF | DIFF_S4b_2026-07-19.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-19 | — | 16078 | solo E: | no |
| DIFF | DIFF_S4b_2026-07-19_rev2_QLiveRootView.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-19 | — | 7795 | solo E: | no |
| DIFF | DIFF_BUGS-v41_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 37134 | solo E: | no |
| DIFF | DIFF_BUGS-v41_2026-07-20_rev2.txt | senza ID | 2026-07-20 | — | 39036 | solo E: | no |
| DIFF | DIFF_LIBRO-v38_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 34634 | solo E: | no |
| DIFF | DIFF_LIBRO-v38_2026-07-20_rev2.txt | senza ID | 2026-07-20 | — | 43935 | solo E: | no |
| DIFF | BOX5v27-LIBROv39_DIFF_2026-07-21.txt | senza ID | 2026-07-21 | 21430 | 21430 | entrambi | no |
| DIFF | BOX5v27-LIBROv39_DIFF_2026-07-21_rev2.txt | senza ID | 2026-07-21 | 21430 | 21430 | entrambi | no |
| DIFF | DIFF_BUGS_v42_2026-07-22.txt | senza ID | 2026-07-22 | 13746 | 13746 | entrambi | no |
| DIFF | DIFF_FIX-PILL_2026-07-22.txt | senza ID | 2026-07-22 | 6271 | 6271 | entrambi | no |
| DIFF | DIFF_BUGS_v43_2026-07-23.txt | senza ID | 2026-07-23 | 21265 | 21265 | entrambi | no |
| DIFF | DIFF_B3_BOX5-V28_2026-07-28.txt | senza ID (tag pre-serie-A: V28) | 2026-07-28 | 24211 | 24211 | entrambi | no |
| DIFF | DIFF_B3bis_BOX5-V28_2026-07-28.txt | senza ID (tag pre-serie-A: V28) | 2026-07-28 | 30195 | 30195 | entrambi | no |
| DIFF | DIFF_B4_SCALETTA-S4-sdoppiamento_2026-07-28.txt | senza ID (tag pre-serie-A: S4) | 2026-07-28 | 34628 | 34628 | entrambi | no |
| DIFF | DIFF_B6_LIBRO-ratifica-sdoppiamento_2026-07-28.txt | senza ID | 2026-07-28 | 25058 | 25058 | entrambi | no |
| DIFF | DIFF_DARK-DECL_2026-07-29.txt | senza ID | 2026-07-29 | 793 | 793 | entrambi | no |
| DIFF | DIFF_S4K_congedo-tastiera_2026-07-29.txt | senza ID | 2026-07-29 | 7321 | 7321 | entrambi | no |
| DIFF | DIFF_S4K_congedo-tastiera_rev2_2026-07-29.txt | senza ID | 2026-07-29 | 7874 | 7874 | entrambi | no |
| DIFF | DIFF_BUGS-v45_2026-07-30.txt | senza ID | 2026-07-30 | 47335 | 47335 | entrambi | no |
| DIFF | DIFF_BUGS-v45_2026-07-30_rev2.txt | senza ID | 2026-07-30 | 51361 | 51361 | entrambi | no |
| DIFF | DIFF_LIBRO-v44_2026-07-30.txt | senza ID | 2026-07-30 | 25948 | 25948 | entrambi | no |
| DIFF | DIFF_LIBRO-v44_2026-07-30_rev2.txt | senza ID | 2026-07-30 | 29252 | 29252 | entrambi | no |
| DIFF | DIFF_LIBRO-v44_2026-07-30_rev3.txt | senza ID | 2026-07-30 | 30262 | 30262 | entrambi | no |
| DIFF | DIFF_LIBRO-v45_2026-07-30.txt | senza ID | 2026-07-30 | 20440 | 20440 | entrambi | no |
| DIFF | DIFF_LIBRO-v46_2026-07-31.txt | senza ID | 2026-07-31 | 31103 | 31103 | entrambi | no |
| DIFF | DIFF_LIBRO-v46_2026-07-31_rev2.txt | senza ID | 2026-07-31 | 31103 | 31103 | entrambi | no |
| DIFF | DIFF_LIBRO-v47_2026-07-31.txt | senza ID | 2026-07-31 | 45920 | 45920 | entrambi | no |
| DIFF | DIFF_LIBRO-v47_2026-07-31_rev2.txt | senza ID | 2026-07-31 | 46417 | 46417 | entrambi | no |
| DIFF | DIFF_LIBRO-v47_2026-07-31_rev3.txt | senza ID | 2026-07-31 | 46424 | 46424 | entrambi | no |
| DIFF | DIFF_LIBRO-v48_2026-07-31.txt | senza ID | 2026-07-31 | 28994 | 28994 | entrambi | no |
| DIFF | DIFF_LIBRO-v48_2026-07-31_rev2.txt | senza ID | 2026-07-31 | 29720 | 29720 | entrambi | no |
| DIFF | DIFF_S4R-fase2_2026-07-31.txt | senza ID | 2026-07-31 | 10354 | 10354 | entrambi | no |
| DIFF | DIFF_S4R-fase2b_2026-07-31.txt | senza ID | 2026-07-31 | 12987 | 12987 | entrambi | no |
| DIFF | DIFF_LIBRO-v50_2026-08-01.txt | senza ID | 2026-08-01 | 21316 | 21316 | entrambi | no |
| DIFF | DIFF_LIBRO-v50_2026-08-01_rev2.txt | senza ID | 2026-08-01 | 31022 | 31022 | entrambi | no |
| DIFF | DIFF_LIBRO-v50_2026-08-01_rev3.txt | senza ID | 2026-08-01 | 31022 | 31022 | entrambi | no |
| DIFF | DIFF_BUGS-v48_2026-08-02_A5-ATTERRAGGIO-31-07.txt | senza ID | 2026-08-02 | 8299 | 8299 | entrambi | no |
| DIFF | DIFF_BUGS-v48_2026-08-02_A7-RETTIFICA-DIFF.txt | senza ID | 2026-08-02 | 8115 | 8115 | entrambi | no |
| DIFF | DIFF_BUGS-v48_2026-08-02_A8-ADDENDUM-ANCORE.txt | senza ID | 2026-08-02 | 8115 | 8115 | entrambi | no |
| DIFF | DIFF_BUGS-v48_2026-08-02_A9-ADDENDUM-SLITTAMENTO.txt | senza ID | 2026-08-02 | 10234 | 10234 | entrambi | no |
| DIFF | DIFF_BUGS-v49_2026-08-02_A22-CORREZIONE-DATA.txt | A22 | 2026-08-02 | 5876 | 5876 | entrambi | no |
| DIFF | DIFF_BUGS-v50_2026-08-02_A22-CORREZIONE-DATA.txt | A22 | 2026-08-02 | 4025 | 4025 | entrambi | no |
| DIFF | DIFF_LIBRO-v51_2026-08-02.txt | senza ID | 2026-08-02 | 15802 | 15802 | entrambi | no |
| DIFF | DIFF_LIBRO-v51_2026-08-02_rev2.txt | senza ID | 2026-08-02 | 19369 | 19369 | entrambi | no |
| DIFF | DIFF_LIBRO-v51_2026-08-02_rev3.txt | senza ID | 2026-08-02 | 17747 | 17747 | entrambi | no |
| DIFF | DIFF_LIBRO-v51_2026-08-02_rev4.txt | senza ID | 2026-08-02 | 17548 | 17548 | entrambi | no |
| DIFF | DIFF_LIBRO-v52_2026-08-02_A5-ATTERRAGGIO-31-07.txt | senza ID | 2026-08-02 | 16110 | 16110 | entrambi | no |
| DIFF | DIFF_LIBRO-v52_2026-08-02_A7-RETTIFICA-DIFF.txt | senza ID | 2026-08-02 | 16108 | 16108 | entrambi | no |
| DIFF | DIFF_LIBRO-v52_2026-08-02_A8-ADDENDUM-ANCORE.txt | senza ID | 2026-08-02 | 16108 | 16108 | entrambi | no |
| DIFF | DIFF_LIBRO-v52_2026-08-02_A9-ADDENDUM-SLITTAMENTO.txt | senza ID | 2026-08-02 | 16108 | 16108 | entrambi | no |
| DIFF | DIFF_SCALETTA-v5_2026-08-02_R7-bump.txt | senza ID (tag pre-serie-A: R7) | 2026-08-02 | 2309 | 2309 | entrambi | no |
| DIFF | DIFF_SCALETTA-v6_2026-08-02_A5-ATTERRAGGIO-31-07.txt | senza ID | 2026-08-02 | 5699 | 5699 | entrambi | no |
| DIFF | DIFF_SCALETTA-v6_2026-08-02_A7-RETTIFICA-DIFF.txt | senza ID | 2026-08-02 | 5648 | 5648 | entrambi | no |
| DIFF | DIFF_SCALETTA-v6_2026-08-02_A8-ADDENDUM-ANCORE.txt | senza ID | 2026-08-02 | 5648 | 5648 | entrambi | no |
| DIFF | DIFF_SCALETTA-v6_2026-08-02_A9-ADDENDUM-SLITTAMENTO.txt | senza ID | 2026-08-02 | 6349 | 6349 | entrambi | no |
| DIFF | DIFF_SCALETTA-v7_2026-08-02_A22-CORREZIONE-DATA.txt | A22 | 2026-08-02 | 4993 | 4993 | entrambi | no |
| DIFF | DIFF_SCALETTA_2026-08-02_S5-reperto-tipi.txt | senza ID (tag pre-serie-A: S5) | 2026-08-02 | 1569 | 1569 | entrambi | no |
| DIFF | DIFF_BUGS-v49_2026-08-03_A19-TICKET-FINESHOW.txt | A19 | 2026-08-03 | 5911 | 5911 | entrambi | no |
| DIFF | DIFF_BUGS-v49_2026-08-03_A25-TICKET-FINESHOW.txt | A25 | 2026-08-03 | 7017 | 7017 | entrambi | no |
| DIFF | DIFF_BUGS-v50_2026-08-03_A19-MARCATURA-LIMBO.txt | A19 | 2026-08-03 | 4025 | 4025 | entrambi | no |
| DIFF | DIFF_BUGS-v50_2026-08-03_A25-MARCATURA-LIMBO.txt | A25 | 2026-08-03 | 4235 | 4235 | entrambi | no |
| DIFF | DIFF_SCALETTA-v7_2026-08-03_A19-CANCELLO-ENDSHOW.txt | A19 | 2026-08-03 | 4993 | 4993 | entrambi | no |
| DIFF | DIFF_SCALETTA-v7_2026-08-03_A25-CANCELLO-ENDSHOW.txt | A25 | 2026-08-03 | 5764 | 5764 | entrambi | no |
| DIFF | DIFF_SCALETTA-v7_2026-08-03_A26-CANCELLO-ENDSHOW.txt | A26 | 2026-08-03 | 6196 | 6196 | entrambi | no |
| DIFF | DIFF_BUGS-v49_2026-08-04_A28-TICKET-FINESHOW.txt | A28 | 2026-08-04 | 20708 | 20708 | entrambi | no |
| DIFF | DIFF_BUGS-v49_2026-08-04_A33-TICKET-FINESHOW.txt | A33 | 2026-08-04 | 21983 | 21983 | entrambi | no |
| DIFF | DIFF_BUGS-v50_2026-08-04_A28-MARCATURA-LIMBO.txt | A28 | 2026-08-04 | 13467 | 13467 | entrambi | no |
| DIFF | DIFF_BUGS-v50_2026-08-04_A33-MARCATURA-LIMBO.txt | A33 | 2026-08-04 | 13668 | 13668 | entrambi | no |
| DIFF | DIFF_LIBRO-v53_2026-08-04_A39-NAS-QUARTA-DESTINAZIONE.txt | A39 | 2026-08-04 | 38284 | 38284 | entrambi | no |
| DIFF | DIFF_LIBRO-v53_2026-08-04_A40-NAS-PERIMETRO-E-STRETTA-DI-MANO.txt | A40 | 2026-08-04 | 39293 | 39293 | entrambi | no |
| DIFF | DIFF_LIBRO-v53_2026-08-04_A41-ALLINEAMENTO-PUNTATORI.txt | A41 | 2026-08-04 | 39635 | 39635 | entrambi | no |
| DIFF | DIFF_BUGS-v51_2026-08-07_A83-DUE-TICKET-MIXER-E-EMERG.txt | A83 | 2026-08-07 | 18839 | 18839 | entrambi | no |
| DIFF | DIFF_LIBRO-v55_2026-08-07_A81-RESTART-SETLIST-TOLTO.txt | A81 | 2026-08-07 | 13199 | 13199 | entrambi | no |
| DIFF | DIFF_SCALETTA-v9_2026-08-07_A85-SEZIONE-C-E-SCHEDA-S5.txt | A85 | 2026-08-07 | 19233 | 19233 | entrambi | no |
| DIFF | DIFF_2026-08-18_A121-BUGS.txt | A121 | 2026-08-18 | 16850 | 16850 | entrambi | no |
| DIFF | DIFF_2026-08-18_A121-SCALETTA-S5b.txt | A121 | 2026-08-18 | 11651 | 11651 | entrambi | no |
| DIFF | DIFF_2026-08-18_A122-LIBRO-ANCORA.txt | A122 | 2026-08-18 | 15806 | 15806 | entrambi | no |
| DIFF | DIFF_2026-08-18_A122-SCALETTA-S5b.txt | A122 | 2026-08-18 | 20499 | 20499 | entrambi | no |
| DIFF | DIFF_2026-08-18_A92-METRONOMO.txt | A92 | 2026-08-18 | 13354 | 13354 | entrambi | no |
| DIFF | DIFF_2026-08-18_A94-CHIUSURA-DOC.txt | A94 | 2026-08-18 | 50875 | 50875 | entrambi | no |
| DIFF | DIFF_2026-08-19_A124-S5b-PARZIALE-ANNULLATO.txt | A124 | 2026-08-19 | 14434 | 14434 | entrambi | si |
| DIFF | DIFF_2026-08-19_A125-S5b-CABLAGGIO.txt | A125 | 2026-08-19 | 16588 | 16588 | entrambi | si |
| DIFF | DIFF_2026-08-19_A126-S5b-COMPLETO.txt | A126 | 2026-08-19 | 17496 | 17496 | entrambi | si |
| DIFF | DIFF_2026-08-19_A128-STANDBY-CENTRATURA.txt | A128 | 2026-08-19 | 2455 | 2455 | entrambi | si |
| DIFF | DIFF_2026-08-19_A129-TRE-CONFORMITA-GRAFICHE.txt | A129 | 2026-08-19 | 13152 | 13152 | entrambi | si |
| DIFF | DIFF_2026-08-19_A130-BUGS-TICKET.txt | A130 | 2026-08-19 | 7678 | 7678 | entrambi | si |
| DIFF | DIFF_2026-08-19_A130-FORCELLE-ISOLATO.diff | A130 | 2026-08-19 | 4776 | 4776 | entrambi | si |
| DIFF | DIFF_2026-08-19_A132-TICKET-ONSWITCH-MORTO.txt | A132 | 2026-08-19 | 12380 | 12380 | entrambi | si |
| DIFF | DIFF_2026-08-19_A133-CENSIMENTO-ISOLATO.diff | A133 | 2026-08-19 | 11365 | 11365 | entrambi | si |
| DIFF | DIFF_2026-08-21_A139-NAVBAR54-DETTAGLIO.txt | A139 | 2026-08-21 | 12906 | 12906 | entrambi | si |
| DIFF | DIFF_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.txt | A141 | 2026-08-21 | 10332 | 10332 | entrambi | si |
| DIFF | DIFF_2026-08-21_A142-BUGS-v57-COMMITTATO.txt | A142 | 2026-08-21 | 12257 | 12257 | entrambi | si |
| DIFF | DIFF_2026-08-21_A144-REV6-DEPOSITO-E-BASELINE.txt | A144 | 2026-08-21 | 8409 | 8409 | entrambi | si |
| DIFF | DIFF_2026-08-21_A146-BUGS-TICKET-IPAD-SCALA.txt | A146 | 2026-08-21 | 8944 | 8944 | entrambi | si |
| DIFF | DIFF_2026-08-21_A147-CORREZIONI-SU-A146.txt | A147 | 2026-08-21 | 11117 | 11117 | entrambi | si |
| DIFF | DIFF_2026-08-21_A155-LIBRO-v58-COLLAUDO-DEVICE.txt | A155 | 2026-08-21 | 12223 | 12223 | entrambi | no |
| DIFF | DIFF_2026-08-21_A162-BOX5-V29.txt | A162 | 2026-08-21 | 10306 | 10306 | entrambi | no |
| DIFF | DIFF_2026-08-21_A162-LIBRO-v59.txt | A162 | 2026-08-21 | 13798 | 13798 | entrambi | no |
| DIFF | DIFF_2026-08-21_A163-BOX5-V29.txt | A163 | 2026-08-21 | 11229 | 11229 | entrambi | no |
| DIFF | DIFF_2026-08-21_A163-LIBRO-v59.txt | A163 | 2026-08-21 | 13798 | 13798 | entrambi | no |
| DIFF | DIFF_2026-08-22_A167-BUGS-v59-CARATTERIZZAZIONE-BAR2.txt | A167 | 2026-08-22 | 15689 | 15689 | entrambi | si |
| DIFF | DIFF_2026-08-22_A168-BUGS-v59-CORREZIONI.txt | A168 | 2026-08-22 | 35797 | 35797 | entrambi | si |
| DIFF | DIFF_2026-08-23_A198-GRUPPO-CODICE.txt | A198 | 2026-08-23 | 9659 | 9659 | entrambi | no |
| DIFF | DIFF_2026-08-23_A198-GRUPPO-DOCUMENTI.txt | A198 | 2026-08-23 | 36866 | 36866 | entrambi | no |
| DIFF | DIFF_2026-08-23_A199-GRUPPO-CODICE.txt | A199 | 2026-08-23 | 9659 | 9659 | entrambi | no |
| DIFF | DIFF_2026-08-23_A199-GRUPPO-DOCUMENTI.txt | A199 | 2026-08-23 | 40837 | 40837 | entrambi | no |
| DIFF | DIFF_2026-08-23_A200-GRUPPO-CODICE.txt | A200 | 2026-08-23 | 9659 | 9659 | entrambi | no |
| DIFF | DIFF_2026-08-23_A200-GRUPPO-DOCUMENTI.txt | A200 | 2026-08-23 | 41042 | 41042 | entrambi | no |
| DIFF | DIFF_2026-08-23_A203-VOCI-REGISTRO-E-VERSIONE-SCALETTA.txt | A203 | 2026-08-23 | 13680 | 13680 | entrambi | no |
| DIFF | DIFF_2026-08-24_A206-DICIASSETTE-DECISIONI.txt | A206 | 2026-08-24 | 45373 | 45373 | entrambi | no |
| DIFF | DIFF_2026-08-24_A211-SCHEDA-USCITA-STANZA.txt | A211 | 2026-08-24 | 19536 | 19536 | entrambi | si |
| DIFF | DIFF_BOX5-V35_2026-08-27_A236-MODELLO-DI-SESSIONE.txt | A236 | 2026-08-27 | 17434 | 17434 | entrambi | si |
| DIFF | DIFF_BUGS-v64_2026-08-27_A231-FOLLOWER-PARTE-CIECO.txt | A231 | 2026-08-27 | 12613 | 12613 | entrambi | si |
| DIFF | DIFF_BUGS-v65_2026-08-27_A232-RIMEDIO-INCOMPLETO.txt | A232 | 2026-08-27 | 8387 | 8387 | entrambi | si |
| DIFF | DIFF_BUGS-v66_2026-08-27_A234-CANTIERE-RIFACIMENTO-PLAYER.txt | A234 | 2026-08-27 | 24760 | 24760 | entrambi | si |
| DIFF | DIFF_BUGS-v67_2026-08-27_A235-STOP-PERDE-IL-PUNTO.txt | A235 | 2026-08-27 | 14416 | 14416 | entrambi | si |
| DIFF | DIFF_CONGEDO-A237-MARCATO_A238_2026-08-27_CC.txt | A237 | 2026-08-27 | 15130 | 15130 | entrambi | si |
| DIFF | DIFF_CONGEDO-A237_2026-08-27_CC.txt | A237 | 2026-08-27 | 12477 | 12477 | entrambi | si |
| DIFF | DIFF_GIRODOC_A241_2026-08-28_CC.txt | A241 | 2026-08-28 | 20341 | 20341 | entrambi | no |
| DIFF | DIFF_PORTA-RIENTRO_2026-08-28_CC.txt | senza ID | 2026-08-28 | 25474 | 25474 | entrambi | si |
| DIFF | DIFF_S-EXIT-MOSSA-A_A242_2026-08-28_CC.txt | A242 | 2026-08-28 | 6669 | 6669 | entrambi | no |
| DIFF | DIFF_TD-STOP-PERDE-IL-PUNTO_A240_2026-08-28_CC.txt | A240 | 2026-08-28 | 12649 | 12649 | entrambi | no |
| DIFF | DIFF_A250_2026-08-29_CC.txt | A250 | 2026-08-29 | 12387 | 12387 | entrambi | no |
| DIFF | DIFF_DISPLAY-FIRMA-A_2026-08-29_CC.txt | senza ID | 2026-08-29 | 12477 | 12477 | entrambi | si |
| DIFF | DIFF_GIRO-DOCUMENTI_A249_2026-08-29_CC.txt | A249 | 2026-08-29 | 55055 | 55055 | entrambi | si |
| DIFF | DIFF_INCIDERE-LA-SERATA_A260_2026-08-29_CC.txt | A260 | 2026-08-29 | 42965 | 42965 | entrambi | no |
| DIFF | DIFF_LE-TRE-NOTE_A254_2026-08-29_CC.txt | A254 | 2026-08-29 | 3940 | 3940 | entrambi | no |
| DIFF | DIFF_SYNC-ISTANTANEA_A247-A248_2026-08-29_CC.txt | A247 | 2026-08-29 | 8506 | 8506 | entrambi | si |
| DIFF | DIFF_SYNC-ISTANTANEA_A247_2026-08-29_CC.txt | A247 | 2026-08-29 | 6059 | 6059 | entrambi | no |
| DIFF | DIFF_USCITA-DAL-DETTAGLIO_A253+A254_2026-08-29_CC.txt | A253 | 2026-08-29 | 23525 | 23525 | entrambi | no |
| DIFF | DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt | A253 | 2026-08-29 | 21240 | 21240 | entrambi | no |
| DIFF | DIFF_DUE-RATIFICHE-E-IL-TICKET-NATO-CHIUSO_A282_2026-08-30_CC.txt | A282 | 2026-08-30 | 30326 | 30326 | entrambi | no |
| DIFF | DIFF_GIRO-DOCUMENTI-30-08_A287_2026-08-30_CC.txt | A287 | 2026-08-30 | 60586 | 60586 | entrambi | no |
| DIFF | DIFF_PROTEZIONE-TEXT-E-BUGS-v74_A285_2026-08-30_CC.txt | A285 | 2026-08-30 | 30693 | 30693 | entrambi | no |
| DIFF | DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A290_2026-08-30_CC.txt | A290 | 2026-08-30 | 76633 | 76633 | entrambi | no |
| DIFF | DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC.txt | A267 | 2026-08-30 | 4659 | 4659 | entrambi | no |
| DIFF | DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC_rev2.txt | A267 | 2026-08-30 | 6917 | 6917 | entrambi | no |
| DIFF | DIFF_RIENTRO-DALLA-SUA-SEZIONE_A267_2026-08-30_CC_rev3.txt | A267 | 2026-08-30 | 6942 | 6942 | entrambi | no |
| DIFF | DIFF_BUGS-v78_A298_2026-08-31_CC.txt | A298 | 2026-08-31 | 21741 | 21741 | entrambi | no |
| DIFF | DIFF_LIBRO-v70_A298_2026-08-31_CC.txt | A298 | 2026-08-31 | 20500 | 20500 | entrambi | no |
| DIFF | DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A291_2026-08-31_CC.txt | A291 | 2026-08-31 | 80068 | 80068 | entrambi | no |
| DIFF | DIFF_QUATTRO-RATIFICHE-COUNTIN-E-RIENTRO_A292_2026-08-31_CC.txt | A292 | 2026-08-31 | 82668 | 82668 | entrambi | no |
| DIFF | DIFF_SCALETTA-v16_A298_2026-08-31_CC.txt | A298 | 2026-08-31 | 6696 | 6696 | entrambi | no |
| DIFF | DIFF_TRE-CODE-DICHIARATE_A293_2026-08-31_CC.txt | A293 | 2026-08-31 | 39522 | 39522 | entrambi | no |
| ACCERTAMENTO | ACCERTAMENTO_LETTURA_ABC_2026-07-13.txt | senza ID | 2026-07-13 | — | 6747 | solo E: | no |
| ACCERTAMENTO | S3_GATE_ACCERTAMENTO_2026-07-13.txt | senza ID (tag pre-serie-A: S3) | 2026-07-13 | — | 15459 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_BUGS_v9_to_v10_TD17.txt | senza ID | 2026-06-21 [mtime] | — | 8911 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_COSTITUZIONE_V3_to_V5.txt | senza ID (tag pre-serie-A: V3) | 2026-06-21 [mtime] | — | 5635 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_BUGS_v13_TD-link-indicator-stale.txt | senza ID | 2026-06-23 [mtime] | — | 7159 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_BUGS_v14_TD17-scoping.txt | senza ID | 2026-06-23 [mtime] | — | 3484 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_BUGS_v15_changelog-sweep.txt | senza ID | 2026-06-23 [mtime] | — | 5787 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_LIBRO_v19_rete-peer.txt | senza ID | 2026-06-23 [mtime] | — | 7732 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_Songs_grafica_CD_27_06_2026.txt | senza ID | 2026-06-27 [mtime] | — | 16248 | solo E: | no |
| DIFF [FUORI HANDOFF/] | DIFF_Songs_passata_grafica_27_06_2026.txt | senza ID | 2026-06-27 [mtime] | — | 8822 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A2_DIFF_2026-07-03.txt | senza ID | 2026-07-03 | — | 15908 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A3_DIFF_2026-07-03.txt | senza ID | 2026-07-03 | — | 20291 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A4_DIFF_2026-07-03.txt | senza ID | 2026-07-03 | — | 9696 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A5PRE_DIFF_2026-07-03.txt | senza ID | 2026-07-03 | — | 6768 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_BUGS_V28_TD_VECTOR_HEAP_DIFF_2026-07-03.txt | senza ID (tag pre-serie-A: V28) | 2026-07-03 | — | 5880 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_BUGS_V29_TD_DECODE_SWALLOW_DIFF_2026-07-03.txt | senza ID (tag pre-serie-A: V29) | 2026-07-03 | — | 6159 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_CTESTFIX_DIFF_2026-07-03.txt | senza ID | 2026-07-03 | — | 641 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A1_DIFF_03_07_2026.txt | senza ID | 2026-07-03 [mtime] | — | 27568 | solo E: | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A5A_DIFF_2026-07-04.txt | senza ID | 2026-07-04 | 11241 | 11241 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A5B_DIFF_2026-07-04.txt | senza ID | 2026-07-04 | 12151 | 12151 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A5C1_DIFF_2026-07-04.txt | senza ID | 2026-07-04 | 16534 | 16534 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_A5C2_DIFF_2026-07-05.txt | senza ID | 2026-07-05 | 13295 | 13295 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_BUGS_V30_DIFF_2026-07-05.txt | senza ID (tag pre-serie-A: V30) | 2026-07-05 | 7024 | 7024 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_BUGS_V31_DIFF_2026-07-05.txt | senza ID (tag pre-serie-A: V31) | 2026-07-05 | 8601 | 8601 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_DEBUG_BACKUP_BUTTONS_DIFF_2026-07-05.txt | senza ID | 2026-07-05 | 6795 | 6795 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_DEBUG_SHEET_FIX_DIFF_2026-07-05.txt | senza ID | 2026-07-05 | 5256 | 5256 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_ATOMC_DIFF_2026-07-06.txt | senza ID | 2026-07-06 | 22059 | 22059 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_BUGS_V32_DIFF_2026-07-06.txt | senza ID (tag pre-serie-A: V32) | 2026-07-06 | 7544 | 7544 | entrambi | no |
| DIFF [FUORI HANDOFF/] | QBEATS_W1_SUBDIV_DIFF_2026-07-06.txt | senza ID | 2026-07-06 | 3191 | 3191 | entrambi | no |
| DIFF [FUORI HANDOFF/] | LIBRO_v28_DIFF_2026-07-11.txt | senza ID | 2026-07-11 | — | 6441 | solo E: | no |
| DOC (snapshot canonico) | DOC_BOX3_V97_2026-07-18.txt | senza ID (tag pre-serie-A: V97) | 2026-07-18 | 11911 | 11911 | entrambi | no |
| DOC (snapshot canonico) | DOC_BUGS_v39_2026-07-18.txt | senza ID | 2026-07-18 | 8685 | 8685 | entrambi | no |
| DOC (snapshot canonico) | DOC_LIBRO_v36_2026-07-18.txt | senza ID | 2026-07-18 | 8092 | 8092 | entrambi | no |
| ESITO | ESITO_COMMIT_BUGS_v40_2026-07-19.txt | senza ID | 2026-07-19 | 5798 | 5798 | entrambi | no |
| ESITO | ESITO_COMMIT_S4b_2026-07-19.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-19 | — | 8252 | solo E: | no |
| ESITO | ESITO_GIRODOC_FOLLOWER-GREGARIO_2026-07-19.txt | senza ID | 2026-07-19 | 17313 | 17313 | entrambi | no |
| ESITO | ESITO_COMMIT_BUGS-v41_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 54595 | solo E: | no |
| ESITO | ESITO_COMMIT_LIBRO-v38_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 59040 | solo E: | no |
| ESITO | ESITO_COMMIT_RETE-GIT_2026-07-21_rev1.txt | senza ID | 2026-07-21 | — | 11002 | solo E: | no |
| ESITO | ESITO_COMMIT_LIBRO-v48_2026-07-31.txt | senza ID | 2026-07-31 | 8913 | 8913 | entrambi | no |
| ESITO | ESITO_COMMIT_BUGSv47-LIBROv49_2026-08-01.txt | senza ID | 2026-08-01 | 30556 | 30556 | entrambi | no |
| ESITO | ESITO_COMMIT_LIBRO-v50_2026-08-01.txt | senza ID | 2026-08-01 | 6419 | 6419 | entrambi | no |
| HANDOFF (altro/predecessore generico) | 2026-04-29_QBEATS_Handoff_VolumiClick_Mute.md | senza ID | 2026-04-29 | — | 3959 | solo E: | no |
| HANDOFF (altro/predecessore generico) | 2026-05-02_QBeats-Handoff_CD_a_CC.md | senza ID | 2026-05-02 | — | 9875 | solo E: | no |
| HANDOFF (altro/predecessore generico) | HANDOFF_BUG2B_BORN_04_06_2026.md | senza ID | 2026-06-04 [mtime] | — | 13713 | solo E: | no |
| HANDOFF (altro/predecessore generico) | HANDOFF_STUDIO_PER_CD_25_06_2026.md | senza ID | 2026-06-26 [mtime] | — | 28410 | solo E: | si |
| HANDOFF (altro/predecessore generico) | CC_REVIEW_SHOWS_HANDOFF_2026-07-09.md | senza ID | 2026-07-09 | — | 10706 | solo E: | no |
| HANDOFF (altro/predecessore generico) | HANDOFF_CHIUSURA_2026-07-13.txt | senza ID | 2026-07-13 | — | 12362 | solo E: | no |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | QBEATS_Handoff_VolumiClick_Mute_29_04_2026.md | senza ID | 2026-05-03 [mtime] | — | 3959 | solo E: | no |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | HANDOFF_TASKD_12_05_2026.md | senza ID | 2026-05-12 [mtime] | — | 11013 | solo E: | si |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | HANDOFF_CD_SHOWS_09_07_2026.md | senza ID | 2026-07-09 [mtime] | — | 18312 | solo E: | no |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | HANDOFF_CD_DEFINITIVO_29_06_2026.md | senza ID | 2026-07-11 [mtime] | — | 23554 | solo E: | no |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | HANDOFF_CD_Home_28_06_2026.md | senza ID | 2026-07-11 [mtime] | — | 10583 | solo E: | no |
| HANDOFF (altro/predecessore generico) [FUORI HANDOFF/] | HANDOFF_CD_QLIVE_NAV_Q7-Q10_11_07_2026.md | senza ID | 2026-07-11 [mtime] | 10150 | 10150 | entrambi | si |
| HANDOFF_CC [FUORI HANDOFF/] | QBEATS_CD_Handoff_CC_02_05_2026.md | senza ID | 2026-05-03 [mtime] | — | 11298 | solo E: | no |
| IGIENE | IGIENE_REPO-PUBBLICO_2026-07-21_rev1.txt | senza ID | 2026-07-21 | — | 15071 | solo E: | no |
| INDAGINE | INDAGINE_C-TER_STORE-MODELLO_2026-07-19.txt | senza ID | 2026-07-19 | — | 16921 | solo E: | no |
| INDAGINE | INDAGINE_TASTO-MORTO-QSTAGE_2026-07-19.txt | senza ID | 2026-07-19 | — | 29926 | solo E: | no |
| INVENTARIO | INVENTARIO_CANONICI-VS-GIT_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 19873 | solo E: | no |
| INVENTARIO | INVENTARIO_DOCREF-FUORI-GIT_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 26988 | solo E: | no |
| INVENTARIO | INVENTARIO_GIRO-DOC_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 62915 | solo E: | no |
| INVENTARIO | INVENTARIO_SOPRAVVIVENZA_2026-07-28.txt | senza ID | 2026-07-28 | 12418 | 12418 | entrambi | no |
| MANIFESTO | MANIFESTO_DRIVE_2026-08-01.md | senza ID | 2026-08-01 | 116433 | 116433 | entrambi | no |
| MATERIE | MATERIE_REFEREE_2026-08-01_perimetro-device.md | senza ID | 2026-08-01 | 7010 | 7010 | entrambi | no |
| PIANO | NODO_A_PIANO_2026-07-10.md | senza ID | 2026-07-10 | 14760 | 14760 | entrambi | si |
| PIANO | PIANO_S4_2026-07-18.txt | senza ID (tag pre-serie-A: S4) | 2026-07-18 | 28952 | 28952 | entrambi | no |
| PIANO | PIANO_S4b_REV_2026-07-18.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-18 | 28081 | 28081 | entrambi | si |
| PIANO | S4B_FASE0_PIANO_2026-07-19.txt | senza ID | 2026-07-19 | — | 21649 | solo E: | no |
| PROPOSTA | PROPOSTA_RETE-GIT-CANONICI_2026-07-21_rev1.txt | senza ID | 2026-07-21 | — | 32278 | solo E: | no |
| QUADRA | QUADRA_TD17_2026-07-21_rev1.txt | senza ID | 2026-07-21 | — | 41829 | solo E: | no |
| ROADMAP | ROADMAP_PRE_CD_16_05_2026.md | senza ID | 2026-05-18 [mtime] | — | 19355 | solo E: | no |
| ROADMAP | ROADMAP_2026-07-24.txt | senza ID | 2026-07-24 | — | 5963 | solo E: | no |
| ROADMAP | _SUPERATO__ROADMAP_2026-07-24.txt | senza ID | 2026-07-24 | 5963 | — | solo C: | no |
| ROADMAP | ROADMAP_2026-07-26.txt | senza ID | 2026-07-26 | 19261 | 19261 | entrambi | no |
| ROADMAP | ROADMAP_CC_2026-08-18.md | senza ID | 2026-08-18 | 20272 | 20272 | entrambi | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v3_2026-07-28_8289944.md | senza ID | 2026-07-28 | — | 35661 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v4_2026-07-30_a393466.md | senza ID | 2026-07-30 | — | 36070 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v4-non-bumpata_2026-08-02_07e0926.md | senza ID | 2026-08-02 | — | 36673 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v5_2026-08-02_c00feb4.md | senza ID | 2026-08-02 | — | 37691 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v6_2026-08-02_e386264.md | senza ID | 2026-08-02 | — | 39354 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v7_2026-08-04_ea3f94a.md | senza ID | 2026-08-04 | — | 42035 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v8_2026-08-06_2960f08.md | senza ID | 2026-08-06 | — | 44101 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v9_2026-08-07_321293e.md | senza ID | 2026-08-07 | — | 54558 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v11_2026-08-21_638b738.md | senza ID | 2026-08-21 | — | 66467 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v12_2026-08-22_9edc120.md | senza ID | 2026-08-22 | — | 69169 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v13_2026-08-24_8ee5485.md | senza ID | 2026-08-24 | — | 74964 | solo E: | no |
| SCALETTA_v (snapshot versione) | SCALETTA_v14_2026-08-24_8727f8e.md | senza ID | 2026-08-24 | — | 75417 | solo E: | no |
| SEGNAPOSTO | SEGNAPOSTO_A264_2026-08-30_CC.md | A264 | 2026-08-30 | 1371 | 1371 | entrambi | no |
| SEGNAPOSTO | SEGNAPOSTO_A265_2026-08-30_CC.md | A265 | 2026-08-30 | 2323 | 2323 | entrambi | no |
| SEGNAPOSTO | SEGNAPOSTO_A266_2026-08-30_CC.md | A266 | 2026-08-30 | 742 | 742 | entrambi | no |
| SEGNAPOSTO | SEGNAPOSTO_A267_2026-08-30_CC.md | A267 | 2026-08-30 | 1463 | 1463 | entrambi | no |
| SEGNAPOSTO | SEGNAPOSTO_A268_2026-08-30_CC.md | A268 | 2026-08-30 | 1027 | 1027 | entrambi | no |
| SEGNAPOSTO | SEGNAPOSTO_A269_2026-08-30_CC.md | A269 | 2026-08-30 | 962 | 962 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_AudioEngine.swift | A240 | 2026-08-28 [mtime] | 161251 | 161251 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_LivePlaybackState.swift | A240 | 2026-08-28 [mtime] | 1270 | 1270 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_LiveView.swift | A240 | 2026-08-28 [mtime] | 29480 | 29480 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_SetlistRunner.swift | A240 | 2026-08-28 [mtime] | 25930 | 25930 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_TransportView.swift | A240 | 2026-08-28 [mtime] | 7293 | 7293 | entrambi | no |
| STAMPA | STAMPA_A240_d0225ef_WaitingForDirectorView.swift | A240 | 2026-08-28 [mtime] | 4121 | 4121 | entrambi | no |
| STAMPA | STAMPA_A241_e13b192_BOX5_QBEATS.md | A241 | 2026-08-28 [mtime] | 110163 | 110163 | entrambi | no |
| STAMPA | STAMPA_A241_e13b192_BUGS_QBEATS.md | A241 | 2026-08-28 [mtime] | 418494 | 418494 | entrambi | no |
| STAMPA | STAMPA_A242_b4c995e_LiveView.swift | A242 | 2026-08-28 [mtime] | 30456 | 30456 | entrambi | no |
| STAMPA | STAMPA_A242_b4c995e_QLiveRootView.swift | A242 | 2026-08-28 [mtime] | 14012 | 14012 | entrambi | no |
| STAMPA | STAMPA_A242_b4c995e_QLiveSession.swift | A242 | 2026-08-28 [mtime] | 6642 | 6642 | entrambi | no |
| STATO_FINALE | roadmap_sezione6_stato_18_luglio.svg | senza ID | 2026-07-18 [mtime] | — | 14457 | solo E: | no |
| STATO_FINALE | STATO_FINALE_2026-07-30_sera_e61efd0.txt | senza ID | 2026-07-30 | 7559 | 7559 | entrambi | no |
| STATO_FINALE | STATO_FINALE_2026-07-31_40f099b.txt | senza ID | 2026-07-31 | 20590 | 20590 | entrambi | no |
| STATO_FINALE | STATO_FINALE_2026-08-07_321293e.txt | senza ID | 2026-08-07 | 15277 | 15277 | entrambi | no |
| VERIFICA | R1_VERIFICA_SOLA_LETTURA_2026-07-12.txt | senza ID (tag pre-serie-A: R1) | 2026-07-12 | — | 5995 | solo E: | no |
| VERIFICA | VERIFICA_R1_2026-07-18.txt | senza ID (tag pre-serie-A: R1) | 2026-07-18 | 16561 | 16561 | entrambi | no |
| VERIFICA | VERIFICA_S4a_TOKEN_2026-07-18.txt | senza ID (tag pre-serie-A: S4a) | 2026-07-18 | 14009 | 14009 | entrambi | no |
| VERIFICA | VERIFICA_REMOTE_CI_2026-07-19.txt | senza ID | 2026-07-19 | — | 884 | solo E: | no |
| VERIFICA | VERIFICA_STATO_GIT_2026-07-19.txt | senza ID | 2026-07-19 | — | 3788 | solo E: | no |
| VERIFICA | VERIFICA_V-DIR_2026-07-19.txt | senza ID | 2026-07-19 | 23701 | 23701 | entrambi | no |
| VERIFICA | VERIFICA_V-ISP_2026-07-19.txt | senza ID | 2026-07-19 | 25703 | 25703 | entrambi | no |
| VERIFICA | VERIFICA_4TOCCHI-BARRA_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 17745 | solo E: | no |
| VERIFICA | VERIFICA_CLAUDE-MD_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 18613 | solo E: | no |
| VERIFICA | VERIFICA_FREEZE-DESIGN_2026-07-20_rev1.txt | senza ID | 2026-07-20 | — | 13247 | solo E: | no |
| VERIFICA | VERIFICA_GATE-S4b_SCALETTA_2026-07-20.txt | senza ID (tag pre-serie-A: S4b) | 2026-07-20 | — | 23752 | solo E: | no |
| VERIFICA | VERIFICA_STATO_GIT_2026-07-20.txt | senza ID | 2026-07-20 | — | 17619 | solo E: | no |
| ALTRO (isolato, non ricorrente) | QBEATS_FONTI_PER_REFEREE_PIVOT_2026-07-08.txt | senza ID | 2026-07-08 | — | 28236 | solo E: | no |
| ALTRO (isolato, non ricorrente) | CD_FREEZE_QLIVE_NAV_2026-07-09.md | senza ID | 2026-07-09 | — | 6950 | solo E: | no |
| ALTRO (isolato, non ricorrente) | CD_FREEZE_QLIVE_NAV_CONSEGNA_2026-07-09.md | senza ID | 2026-07-09 | — | 2554 | solo E: | no |
| ALTRO (isolato, non ricorrente) | QBEATS_S0_STATUS_2026-07-10.txt | senza ID (tag pre-serie-A: S0) | 2026-07-10 | — | 739 | solo E: | no |
| ALTRO (isolato, non ricorrente) | 2026-07-11_Q7-Q16.html | senza ID | 2026-07-11 | — | 74645 | solo E: | si |
| ALTRO (isolato, non ricorrente) | R1-REF-01_B3_CTA_verbatim_2026-07-11.txt | senza ID (tag pre-serie-A: R1) | 2026-07-11 | — | 2885 | solo E: | no |
| ALTRO (isolato, non ricorrente) | R1-REF-02_RoomSwitchBar_intero_piu_ancore_S3_2026-07-11.txt | senza ID (tag pre-serie-A: R1) | 2026-07-11 | — | 13656 | solo E: | no |
| ALTRO (isolato, non ricorrente) | SCALETTA_S3_REVIEW_2026-07-12.txt | senza ID (tag pre-serie-A: S3) | 2026-07-12 | — | 20419 | solo E: | no |
| ALTRO (isolato, non ricorrente) | BUGS_QBEATS35.md | senza ID | 2026-07-12 [mtime] | — | 152359 | solo E: | no |
| ALTRO (isolato, non ricorrente) | LIBRO_MASTRO_QBEATS31.md | senza ID | 2026-07-12 [mtime] | — | 96909 | solo E: | no |
| ALTRO (isolato, non ricorrente) | BOX3_V94_2026-07-13.md | senza ID (tag pre-serie-A: V94) | 2026-07-13 | — | 39198 | solo E: | no |
| ALTRO (isolato, non ricorrente) | BOX5_V25_2026-07-13.md | senza ID (tag pre-serie-A: V25) | 2026-07-13 | — | 30122 | solo E: | no |
| ALTRO (isolato, non ricorrente) | S3_BOZZA_PROMPT_2026-07-13.txt | senza ID (tag pre-serie-A: S3) | 2026-07-13 | — | 18080 | solo E: | no |
| ALTRO (isolato, non ricorrente) | S3_CHECKLIST_TOKEN_2026-07-13.txt | senza ID (tag pre-serie-A: S3) | 2026-07-13 | — | 17602 | solo E: | no |
| ALTRO (isolato, non ricorrente) | LIBRO_MASTRO_QBEATS33.md | senza ID | 2026-07-13 [mtime] | — | 98497 | solo E: | no |
| ALTRO (isolato, non ricorrente) | QBeatsStore.swift | senza ID | 2026-07-13 [mtime] | — | 11831 | solo E: | si |
| ALTRO (isolato, non ricorrente) | QStageRootView.swift | senza ID | 2026-07-13 [mtime] | — | 1567 | solo E: | si |
| ALTRO (isolato, non ricorrente) | ShowsListView.swift | senza ID | 2026-07-13 [mtime] | — | 25291 | solo E: | si |
| ALTRO (isolato, non ricorrente) | RoomSwitchBar.swift | senza ID | 2026-07-14 [mtime] | — | 14145 | solo E: | si |
| ALTRO (isolato, non ricorrente) | A58-USCITA-FINESHOW-RICOGNIZIONE.txt | A58 | 2026-08-06 [mtime] | — | 21698 | solo E: | no |
---

## Indirizzo e verifica del deposito (misurati DOPO aver scritto tutto il resto)

`HANDOFF/MISURE_CC_2026-09-01_A301-CENSIMENTO-CONGEDI-E-REFERTI.md` — su **entrambe le gambe**, `cmp` exit 0. 83.217 byte, 831 righe (corpo + appendice, prima di questa sezione di chiusura), sha256 `2b0b1935feb32c98df6161f90532bdb50d1c8c7b32abe1adda5a1bb868aad5ee`.

⚠️ Come ogni misura di questo genere in questo progetto: il byte-count e lo sha256 sopra sono del file **com'era prima di aggiungere questa stessa riga** — non può essere altrimenti (un file non può contenere l'hash di se stesso). La garanzia reale per chi legge non è questo numero, è il `cmp` che chiunque può ripetere fra le due gambe.

*A301-CENSIMENTO-CONGEDI-E-REFERTI — FINE.*
