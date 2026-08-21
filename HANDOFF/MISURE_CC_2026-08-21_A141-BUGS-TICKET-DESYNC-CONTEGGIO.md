# MISURE CC — A141-BUGS-TICKET-DESYNC-CONTEGGIO

**ID ricevuto e verificato: `A141-BUGS-TICKET-DESYNC-CONTEGGIO`.**
Da: CC · A: referee, + Mauro · 21/08/2026
Ancoraggio: **HEAD = `baaa172895cfafba57b187356ed8ae1036eee17e`**, locale **=** remoto.

⛔ **NESSUN COMMIT.** Diff in `HANDOFF/DIFF_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.txt`.
Aspetto ratifica del referee e **poi** l'OK di Mauro.

⛔ **DOC-ONLY:** un solo file toccato, `BUGS_QBEATS.md`. Zero codice.
⛔ **NON HO INDAGATO IL DIFETTO.** Nessun file di codice aperto, nessuna causa
cercata, nessun fix proposto. Nessuna mia ipotesi è finita nel ticket.

Marcatura: **[M]** misurato da me alla fonte · **[R]** riportato · **[A]** giudizio mio.

---

## ⛔ LE TRE RIGHE DA LEGGERE PRIMA DI TUTTO

**1. Nessuna condizione di stop del §6 è scattata.** ID libero · il testo delle
regole di casa **conferma** il punto 1 · nessuno dei cinque è un doppione esatto
sui tre assi · il ticket entra in coda a §1.1 senza spostare nulla.

**2. ⚠️ Ho lasciato il testo del referee con gli apostrofi NON accentati**
(`e'`, `gravita'`, `piu'`, `cio'`, `perche'`, `modalita'`, `se'`, `li'`), mentre
il resto del file usa `è`, `già`, `più`. **Non è una svista: normalizzarli
sarebbe stato alterare un testo dichiarato RATIFICATO.** Se il referee vuole la
forma accentata, è una riga di istruzione e la applico.

**3. ⚠️ «Bug 2.b» rende DUE intestazioni nel file, non una.** Ho riportato quella
che il mandato nomina — *(faccia visiva/counter)*, in §1.2. L'altra è un ticket
diverso in Sezione 2. Dettaglio sotto.

---

## §0 · L'ID

**[M]** Sonda stretta (perimetro documentale, solo `*.md`/`*.txt`, binari esclusi
con `-I`, pattern con confine di parola), due supporti:

| ID | NOME repo | CONT repo | NOME E: | CONT E: | lettura |
|---|---:|---:|---:|---:|---|
| **A141** | **0** | **1** | **0** | **1** | ⇒ **LIBERO** |
| A142 | 0 | 0 | 0 | 0 | controllo negativo |
| A139 | 3 | 4 | 3 | 4 | controllo positivo |
| A140 | 1 | 2 | 1 | 2 | controllo positivo |
| A134 | 1 | 6 | 1 | 6 | controllo positivo |

⛔ **Ispezione del contesto** — l'unico hit, identico sui due supporti:

```
HANDOFF/MISURE_CC_2026-08-21_A140-COMMIT-A139.md:36:| A141 | 0 | 0 | 0 | 0 | controllo negativo |
```

È la riga del mio referto di A140 dove l'avevo citato **come controllo negativo**.
Menzione, non uso. Nessuna collisione.

---

## §1 · LE REGOLE DI CASA — VERBATIM

### La faccia che ho misurato

**[M]** `BUGS_QBEATS.md`, prima della modifica:

| faccia | byte | sha256 |
|---|---:|---|
| blob a HEAD | 327 759 | `48dbff2af22f9dce736454ccb549c05db06b038c…` |
| disco | 328 891 | `4e128eee9144d8c81438874d7ef4e22a0c892596…` |

**Disco: CR-byte = 1132, LF-byte = 1132** ⇒ **CRLF su ogni riga**, LF nel blob.
Lo scarto di 1 132 byte è esattamente il numero di righe. **Non è un guasto.**

**[M] Confermo il perché indicato dal mandato, misurato:** `.gitattributes`
contiene quattro sole voci — `HANDOFF/** -text`, `DESIGN/** -text`,
`BOX3_QBEATS.md -text`, `BOX5_QBEATS.md -text`. **`BUGS_QBEATS.md` NON compare**,
quindi cade sotto `core.autocrlf = true` che normalizza. BOX3 e BOX5 sono
esentati, BUGS e LIBRO no.

⚠️ **Ho misurato con `tr -cd '\r' | wc -c`, NON con `grep -c`**: il grep di
MSYS scarta i CR in modo testo e renderebbe **0** su un file CRLF — falso zero
già registrato in A139.

**Ho scritto preservando CRLF.** Dopo la modifica: **CR = LF = 1155**, zero righe
miste.

### Testata del file — VERBATIM, righe 1-6

```
# BUGS_QBEATS — Tracker centralizzato bug e tech debt

**Versione:** 56
**Ultima modifica:** 2026-08-19
**Autore iniziale:** CC chat principale 26/05/2026 sera
**Repo:** `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\`
```

### §Convenzioni › Priorità palco — VERBATIM, righe 45-48

```
### Priorità palco
- 🚨 **BLOCCANTE PALCO** — non possiamo suonare live con questo bug aperto
- ⚠️ **NON BLOCCANTE** — fastidio ma palco fattibile
- 📦 **BACKLOG** — pre-release v1 o post-v1
```

### §Convenzioni › Workflow aggiornamento — VERBATIM E PER INTERO, righe 50-55

```
### Workflow aggiornamento
1. Nuovo bug emerge in chat → CC lo aggiunge qui PRIMA di proporre fix
2. Bug viene fixato → CC aggiorna stato a 🟢 CHIUSO con commit di riferimento
3. Diagnosi smentita → CC sposta in Sezione "Scartati / smentiti" con motivazione
4. Modifiche al file → diff letterale in chat, commit `BUGS_QBEATS.md: vN — [decisione]`
5. Posizione: un ticket nuovo si inserisce IN CODA alla sottosezione di severità che gli compete. La posizione non porta significato: lo porta la severità. (Ratificata referee 20/07 — prima non era scritta e i due casi più recenti si comportavano in modo opposto.)
```

✅ **IL PUNTO 1 DEL MANDATO È CONFERMATO DAL TESTO.** Il referee afferma che la
regola di posizione dice «in coda alla sottosezione di severità che compete». Il
punto 5 recita, alla lettera: *«un ticket nuovo si inserisce IN CODA alla
sottosezione di severità che gli compete»*. **Il testo regge, non lo smentisce.**

⚠️ **[M] Il punto 4 dello stesso Workflow prescrive anche un formato di
messaggio di commit** — `` `BUGS_QBEATS.md: vN — [decisione]` `` — che i commit
recenti su questo file **non usano** (es. `ce07fbd` del 20/08: «Ticket
room-switch morto + censimento dei default silenziosi (doc-only)»). **Non è
materia di questo mandato e non l'ho toccato: lo segnalo e basta.**

### Nota introduttiva in testa a §1.1 sulle due assi — VERBATIM, righe 61-63

```
## 🚨 1.1 — Bloccanti palco o urgenti (🔴 OPEN ALTA)

> *(Le due assi sono indipendenti — vedi Convenzioni: 🔴 OPEN ALTA = «bloccante palco **o** richiesto entro 2 settimane». Un ticket può quindi essere 🔴 ALTA e ⚠️ NON BLOCCANTE: la severità dice quanto è urgente, la priorità palco dice se impedisce di suonare. Titolo allineato alle Convenzioni dal referee, 20/07 — l'incoerenza era latente e l'ha esposta il primo ticket di questo tipo.)*
```

### Le ultime DUE righe della tabella di §Sezione 5 — formato dedotto

**[M]** Righe `| 55 |` e `| 56 |` (troncate qui alla parte che porta il formato;
il diff non le tocca):

```
| 55 | 2026-08-19 | CC + referee | **Un ticket NUOVO in §1.2 + una marcatura additiva, doc-only, zero codice.** `TD-segmini-onswitch-morto` — … Header bump 54→55. |
| 56 | 2026-08-19 | CC + referee | **Censimento additivo su `TD-segmini-onswitch-morto`, doc-only, zero codice.** … Header bump 55→56. |
```

**Formato dedotto e applicato:**
`| <N> | <YYYY-MM-DD> | <attori> | **<titolo in grassetto>** <corpo> Header bump <N-1>→<N>. |`
— tutto su **una riga sola**, attori `CC + referee` come nelle due precedenti,
chiusura con `Header bump`.

---

## §2 · I CINQUE CANDIDATI A DOPPIONE — RIPORTATI, NON GIUDICATI

**[M] Localizzati per NOME, mai per riga** (R-β). I numeri di riga qui sotto sono
lo stato **prima** della mia modifica, e sono indicati solo per tracciabilità.

⛔ **Non concludo nulla sulla riconciliazione.** Sotto c'è solo ciò che i ticket
dicono. L'unica determinazione che faccio è il **cancello del §6** — se uno sia
un doppione **esatto** sui tre assi — e la riporto in fondo, separata.

⚠️ **[M] Un rilievo di localizzazione, da sapere prima di leggere il 3:**
`Bug 2.b` rende **due** intestazioni distinte nel file, non una —
`### Bug 2.b (faccia visiva/counter) …` (§1.2) e
`### Bug 2.b — Ferita A + Ferita B (sync runtime cross-device / accento ai cambi
sezione)` (Sezione 2). Il mandato nomina la prima, ed è quella che riporto.

### 1 · `TD-follower-rejoin` — §1.1

**Titolo intero:**
```
### TD-follower-rejoin — Aggancio Follower difettoso al ri-Play / cambio setlist (audio)
```

**SINTOMO:**
```
- **Sintomo (per run, NON fusi):** sul device **Collaborative/Follower**, al **ri-Play** (Play→Stop→Play) o al **cambio setlist**, l'avvio è difettoso. **Director pulito.** Casi osservati su device:
```

**STATO:**
```
- **Stato:** **faccia (A) = Ferita A → 🟢 CHIUSA 10/06/2026** (device-validata TEST6 + ratificata Mauro+referee, fix `7904ca8`). **Facce (B) gap-reset L3→L1 [= UI segmenti stantii], (C) runner-non-resetta: 🔴 RESTANO OPEN; (D) offset-barra/counter → ri-alloggiata in §1.2 ("Bug 2.b faccia visiva/counter", 🟠).** Causale (B/C) = ipotesi forte (non identificata). **NON chiuse** (regola `feedback_qbeats_chiuso_solo_dopo_device`).
```

### 2 · `TD #A — First-beat-fuori cross-device` — §1.1

**Titolo intero:**
```
### TD #A — First-beat-fuori cross-device
```

**SINTOMO:**
```
- **Sintomo:** al primo beat dopo `play`, il device Collaborativo entra 30-105ms dopo il Director. Sistematico cross-BPM (non rumore). Misurato cross-play, cross-device.
```

**STATO:**
```
- **Stato:** in attesa raccolta dati Sessione 1 (vedi sotto). Senza dati nuovi non si può progettare fix.
```

### 3 · `Bug 2.b (faccia visiva/counter)` — §1.2

**Titolo intero:**
```
### Bug 2.b (faccia visiva/counter) — desync sezione/time-sig cross-device, SOLO visivo (🟢 faccia i CHIUSA 19/06 / 🟠 faccia ii OPEN)
```

**SINTOMO** — ⚠️ **[M] questo ticket non ha una riga col lemma «Sintomo».** La
riga che porta l'inquadramento del difetto, riportata al suo posto:
```
- **Inquadramento:** Bug 2.b è 🟢 CHIUSO lato **audio + ingresso** (Ferita A+B, TEST7, Sez. 2). Restano APERTE le facce **visive/counter** dello stesso desync sezione/time-sig cross-device: il fix audio non le tocca. Audio corretto, sbagliato solo ciò che si vede. **AGG 19/06: faccia (i) striscia segmenti → 🟢 CHIUSA (blocco sotto); resta aperta solo la faccia (ii) counter.**
```

**STATO:**
```
- **Stato:** **faccia (i) striscia segmenti → 🟢 CHIUSA 19/06/2026** (fix `dfe758d` su master, device-validata via proxy — blocco sopra). **Faccia (ii) counter "bar 2 di N" → 🟠 RESTA OPEN** (CD-Q1=B, deliverable CD rimandato a Fase 6-7-bis; il fix accenti non la tocca). Entry mantenuta in §1.2 per la faccia (ii).
```

### 4 · `TD-countin-ratificato-mai-costruito` — §1.2

**Titolo intero:**
```
### TD-countin-ratificato-mai-costruito — il count-in è ratificato con TRE punti d'attivazione e nessuno dei tre suona (🟠 OPEN MEDIA — **PROPOSTA, non assegnata: decide Mauro**)
```

**SINTOMO** — ⚠️ **[M] anche questo ticket non ha una riga col lemma «Sintomo»:**
il difetto è enunciato nel titolo stesso («è ratificato con TRE punti
d'attivazione e nessuno dei tre suona»).

**STATO:**
```
- **Stato: PROPOSTA di severità 🟠 OPEN MEDIA — il valore lo assegna MAURO, non è assegnato qui.** Precedente: `TD-mixer-copre-endshow` e `TD-emerg-bottone-morto`, severità proposte il 07/08 e decise da Mauro. Motivo della proposta: non c'è perdita di dati né silenzio sul palco. ⚠️ **Ma il motivo ratificato è di palco** (`LIBRO:225`), e questo può valere più di quanto pesi CC. La collocazione in §1.2 segue la proposta e **va rivista se il valore cambia**.
```

⚠️ **[M] Attenzione a un tranello di delimitazione**, che segnalo perché chi
rileggesse per riga ci cascherebbe: a poche righe di distanza c'è **un secondo
`- **Stato: PROPOSTA di severità…`** che sembra appartenere a questo ticket e
**non gli appartiene** — è di `TD-segmini-hitarea-sotto-44pt`, l'intestazione
successiva. Ho delimitato il blocco cercando il prossimo `###`, non a occhio.

### 5 · `Bug cambio-canzone cross-device` — Sezione 2, CHIUSO

**Titolo intero:**
```
### Bug cambio-canzone cross-device — Follower riparte da Song A allo standby
```

**SINTOMO:**
```
- **Sintomo:** in setup cross-device (Director + Follower Collaborativo), allo standby tra una canzone e la successiva (es. fine Song A → standby "next: Song B"), premendo Play su Director il Follower ripartiva da Song A / Intro 100 invece di proseguire con Song B / Slow 90 (tempo corretto da Link, ma contenuto di sezione della canzone sbagliata).
```

**STATO** — ⚠️ **[M] questo ticket, essendo in Sezione 2 (chiusi), non ha un
campo «Stato»**: porta invece la riga di validazione, che è ciò che ne dichiara
la chiusura. La riporto al suo posto:
```
- **Validato device:** 31/05/2026 — orchestrazione validata (Follower entra su Slow 90, bar multi-canzone sincronizzati). **NB:** il conteggio segmenti del metronomo stantio all'ingresso di Slow 90 (mostra 3 invece di 4 per un attimo) è la **faccia visiva di Bug 2.b** (desync sezione/time-sig cross-device — vedi **§1.2 "Bug 2.b (faccia visiva/counter)"**: **faccia (i) striscia segmenti → 🟢 CHIUSA 19/06** (fix `dfe758d`); resta aperta solo la faccia (ii) counter "bar 2 di N" (CD-Q1=B); l'audio di Bug 2.b è chiuso, voce sopra), **non** questo bug.
```

---

## ⛔ IL CANCELLO DEL §6 — la sola determinazione che faccio

**La domanda del §6 è binaria e stretta:** uno dei cinque è un doppione
**ESATTO** — *stesso sintomo, stesso innesco, stessa configurazione*?

**[M] Risposta: NO, nessuno dei cinque.** Per ciascuno riporto il **solo fatto
discriminante**, citato dal ticket stesso, senza aggiungere lettura mia:

| # | fatto discriminante, dal ticket | asse su cui cade |
|---|---|---|
| 1 | *«Director pulito»* — il sintomo è dichiarato **sul Follower** | attore |
| 2 | *«entra 30-105ms dopo»* — è **latenza di tempo**; il nuovo ticket dichiara *«NON e' un difetto di tempo audio»* | natura |
| 3 | *«SOLO visivo»* nel titolo; il nuovo ticket dichiara che scattano teleprompter e cambi di sezione | natura |
| 4 | il difetto è che il count-in **non suona**; il nuovo ticket non parla di count-in | sintomo |
| 5 | *«ripartiva da Song A»* = **canzone sbagliata**; il nuovo ticket parla di **una battuta** di scarto | sintomo |

⇒ **Il cancello del §6 non scatta. Ho proseduto con la scrittura.**

⛔ **[A] E mi fermo esattamente qui.** «Non è un doppione esatto» **non è** «non
è lo stesso difetto»: sono due domande diverse, e la seconda **non l'ho posta e
non la pongo**. La riconciliazione è del referee ed è dichiarata RINVIATA — sia
nel mandato, sia dentro il ticket stesso.

---

## §3-§4 · COSA HO SCRITTO

**Diff:** `HANDOFF/DIFF_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.txt`
· 51 righe · sha256 `fadf5e2f4ea186aa2fe81d12a1553eef530859f081f8009b5d742fe5c4332306`
· **1 file, +25 / −2**.

| # | cosa | esito |
|---|---|---|
| §3 | ticket `TD-direttore-parte-da-bar2`, **in coda a §1.1** | inserito a `:175`, §1.2 ora a `:197` |
| §4 | `**Versione:**` 56 → **57** | fatto |
| §4 | `**Ultima modifica:**` → **2026-08-21** | fatto |
| §4 | una riga nuova `| 57 |` in coda alla tabella | fatto, formato delle due precedenti |

**[M] Le uniche DUE righe rimosse dal diff** sono le due di testata
(`**Versione:** 56` e `**Ultima modifica:** 2026-08-19`). **Tutto il resto è
puramente additivo.** La riga `| 56 |` è **intatta** (1 109 caratteri, invariata):
la `| 57 |` la segue.

### Il testo del ticket: cosa ho adattato e cosa no

⛔ **Non ho riformulato, abbreviato, né aggiunto nulla.** L'unico adattamento è
quello autorizzato dal §3:

- **Titolo su UNA riga.** Il mandato lo presenta spezzato su due; tutti i ticket
  vicini hanno il titolo su una riga sola (`:148`, `:162` sono lunghissimi e
  intatti). Ricongiunto senza cambiare una parola.

⚠️ **[M] E una cosa che ho deliberatamente NON adattato, perché non è
formattazione:** il testo del referee usa **apostrofi non accentati** —
`e'`, `gravita'`, `piu'`, `cio'`, `perche'`, `modalita'`, `se'`, `li'` — mentre
il resto del file usa `è`, `già`, `più`, `perché`. **Li ho lasciati esattamente
come li ha scritti il referee.** Sostituirli sarebbe stato modificare i
caratteri di un testo dichiarato RATIFICATO, non adattarne la forma. ⚠️ C'è
anche un motivo pratico: l'alterazione degli apostrofi in transito è un guasto
già visto in questo progetto, e non volevo introdurlo io di mia iniziativa.
**Se il referee vuole la forma accentata, è una riga di istruzione e la applico
in un giro.**

### Controlli di integrità

| controllo | esito |
|---|---|
| a-capo dopo la scrittura | **CR = LF = 1155** ⇒ CRLF uniforme, zero righe miste |
| file toccati | **1** (`BUGS_QBEATS.md`), verificato sul diff e su `git status` |
| ticket in coda a §1.1 | `:175`, con `## ⚠️ 1.2` subito dopo a `:197` |
| nessun ticket spostato | §1.1 ha **8** intestazioni `###`: le 7 preesistenti + la nuova |
| riga `| 56 |` intatta | sì — il diff non la tocca, l'inserimento è dopo |

---

## ⚠️ DIFETTI NOTATI ALTROVE — SEGNALATI, NON RIPARATI

**[M] Come impone il §4, li segnalo qui e non li ho toccati.**

1. **Il punto 4 del «Workflow aggiornamento» prescrive un formato di messaggio di
   commit che non viene più usato:** `` `BUGS_QBEATS.md: vN — [decisione]` ``.
   I commit recenti su questo file usano tutt'altra forma (es. `ce07fbd`, 20/08).
   **O la regola è scaduta, o i commit la violano da tempo.** Non è deciso.
2. **`Bug 2.b` è un nome che rende due intestazioni distinte** in due sezioni
   diverse. Chi cerca per nome ne trova due e deve scegliere. Non è un difetto
   del contenuto, è un rischio di indirizzamento.
3. **Due dei cinque candidati (`Bug 2.b faccia visiva/counter` e
   `TD-countin-…`) non hanno una riga col lemma «Sintomo»**, mentre gli altri
   sì. Chi estrae i sintomi per lemma su questo file ottiene un falso zero.

---

## §5 · DOVE HO SCRITTO — dichiarato da me

**[M] Verificato che i file esistono dopo la scrittura.**

| gamba | percorso |
|---|---|
| repo | `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\HANDOFF\` |
| mirror `E:` | `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` |

Due file per gamba: `MISURE_CC_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.md`
e `DIFF_2026-08-21_A141-BUGS-TICKET-DESYNC-CONTEGGIO.txt`.

⚠️ **R-δ: due gambe su tre.** La gamba Drive non è autorizzata in questo
mandato. ⇒ **scritto, non consegnato**, e non lo chiamo «propagato».

⚠️ **[M] Riconferma della misura di A140:** il ramo `Il mio Drive/Qbeats/HANDOFF/`
resta fermo al 7 agosto. La cartella `E:` che uso **non è sincronizzata** verso
Drive.

---

## PER IL COMMIT DEL PROSSIMO GIRO

⛔ **`--author="Mauro Martintoni <di_tutto@icloud.com>"` sulla riga di comando,
MAI `git config`.** Lezione di A140, dove ho toccato la configurazione git prima
di verificare che servisse.

⚠️ **Il punto 4 del Workflow (rilievo 1 sopra) prescriverebbe il messaggio
`BUGS_QBEATS.md: v57 — [decisione]`.** I commit recenti non lo seguono. **Non
scelgo io:** dimmi quale forma vuoi.

---

*A141-FINE*
