# MISURE CC — A260 — INCIDERE LA SERATA — 29/08/2026

Da: CC · A: referee (ratifica del diff) + Mauro (OK al commit) + CD

**ID ESEGUITO: A260.** **⏱ Orologio:** sab 29/08/2026 **21:52 locale (UTC+2)** · 19:52 UTC. **Aggancio:** risponde ad A258.

**Cancello ID — quattro gambe a zero.** Positivo **`A253`, che vede su CIASCUNA**: nome (C: 3 · E: 3) · contenuto (C: 11 · E: 6) · `git log --all --grep` **1** (`9c3616e`).

⛔ **NESSUNA MODIFICA SOTTO `ios_app/`** (verificato: `git status -- ios_app/` vuoto). **Nessun commit, nessun push, nessuno staging.** `HEAD` = `9c3616e`.

---

## §0 — LE DUE MISURE DEL REFEREE — rimisurate con sonde MIE. Reggono entrambe.

### (i) La spia di stato non esiste — **CONFERMATA**

⛔ **Non ho riusato la sonda del referee**, che cercava `Playing`/`Stopped`/`statusPill` con positivo `isPlaying` = 10 file. Quel positivo **non è della stessa forma** dell'oggetto: `isPlaying` è un **campo di stato**, la spia è un **elemento di UI**. Un positivo di famiglia sbagliata è precisamente il difetto inciso oggi in BOX5.

**[M] Sonda mia — stringhe LETTERALI di UI** (la forma in cui una spia parla):

```
"Playing" 0 · "PLAYING" 0 · "Stopped" 0 · "STOPPED" 0 · "Show stopped" 0 · "NOW" 0 · "NEXT" 0
```

**[M] Controllo positivo NELLA STESSA FORMA** — stringhe di UI che so esistere: `"END SHOW"` **2** · `"START SHOW"` **1** · `"Shows"` **5** · `"Read-only"` **2** · `"BACK TO SHOW"` **1**. **Il positivo vede.**

**[M] E ho verificato anche la forma SENZA TESTO**, perché la spia di CD è «un anello vuoto» e una sonda su stringhe non l'avrebbe mai vista: `LiveHeaderView` **non legge affatto** `isPlaying` né `playbackState`; i suoi tre `Circle` (`:99` · `:106` · `:113`) sono spie di **connessione** — Link verde, e **due MIDI dietro `if false`**. La navbar del **dettaglio** non ha né `Circle` né `Capsule`.

⇒ **Nessuna spia di stato, in nessuna forma. La misura del referee regge.**

### (ii) La freccia va alla lista, `selectedSetlist` scritto solo dalla card — **CONFERMATA**

**[M] Catena completa, letta nodo per nodo:** `LiveHeaderView.swift:30` (`Button { onExit() }`) → `LiveView.swift:154` → `QLiveRootView.swift:324` (`LiveView(onExit: { leavePlayer() }`) → `leavePlayer()` → **`navigate(to: .shows)`**.

**[M] Sweep per EFFETTO su `selectedSetlist`** (non per nome del chiamante): in tutta la stanza **un solo scrittore**, `QLiveRootView.swift:179`, dentro `onSelectShow`. Gli altri hit del repo sono `selectedSetlistIDs` in `BackupView`/`ImportView` — **omonimia, entità diversa**, dichiarata per non farla passare per un secondo scrittore.

⇒ **Regge.** ⚠️ E questo **restringe** una mia affermazione di A258: avevo segnalato che il difetto «porta all'ultimo show aperto» tocca `SHOW DETAILS`. Vero **solo in ipotesi di rev2 onorato**: **oggi la freccia non porta al dettaglio, quindi il difetto non è raggiungibile da lì.** Corretto e inciso nel ticket 2b.

---

## §1 — 🚨 UNA DIVERGENZA DALLA LETTERA DEL MANDATO, dichiarata prima di eseguire

Il punto 1(a) chiede di incidere **«LA DECISIONE 7 DEL 26/08 È SUPERATA»**. ⛔ **In blocco è FALSO, e a dirlo è un canonico**: `BOX5_QBEATS.md`, BLOCCO 3, verbatim — *«La 7 non è "superata" né "riformulata": le sue tre metà hanno sorti diverse, e una riga sola direbbe una cosa falsa qualunque parola si scegliesse»*, e *«"Ratificata e mai costruita" si legge in modo diverso da "superata", e fra sei mesi la differenza conta»*.

**[M] Le tre metà, e cosa fa ciascuna oggi:**

| metà della decisione 7 | sorte |
|---|---|
| «STOP nel player è REVERSIBILE» | ✅ **REGGE** — è ciò che il ciclo STOP → Play realizza |
| «con un OVERLAY DI RIPRESA» | ⛔ **SUPERATA — è questa, e solo questa** |
| «nel dettaglio ferma tutto ed esce» | ✅ **REGGE, e ora è COSTRUITA** (A253) |

⇒ **Ho inciso la superazione di UNA metà su tre.** La sostanza del mandato è intatta e viene detta per intero: *stop secco, nessun pannello, il ciclo STOP → Play è definitivo e non un ripiego*. **Scrivere «la 7 è superata» avrebbe messo LIBRO e BOX5 in contraddizione su tre quarti del contenuto** — cioè avrebbe creato la stessa classe di difetto che il progetto già traccia altrove.

---

## §2 — COSA HO SCRITTO, E DOVE

**Tre documenti, cinque incisioni, zero righe di codice.**

**`LIBRO_MASTRO_QBEATS.md` — Sezione 2, +3 righe** (le tre ratifiche 1a/1b/1c), versione **65 → 66**, registro Sez.5 riga **66**.

**`BUGS_QBEATS.md` — §1.1, +2 ticket**, versione **71 → 72**, registro riga **72**:
- **`TD-restart-song-falsa-ricevuta`** — con la catena intera, il fatto che `restartFromBeginning()` **non è vuota**, la guardia che **non protegge** `.overlayStop`, e le **due sole porte** al pannello (debug + azione MIDI assegnabile dall'utente). ⛔ **«La chiusura del pannello è DEDOTTA, non osservata» è scritto nel ticket in grassetto**, come chiesto.
- **`TD-rev2-freccia-e-spia-ratificato-non-costruito`** — le due misure del §0 con le sonde e i positivi, e le **tre conseguenze**: conti di tocchi parziali · 🚨 **la cura della sottoriga poggia sulla spia, quindi l'ordine è obbligato** (prima la spia, o l'informazione **sparisce** invece di spostarsi) · il difetto «ultimo show aperto» **non tocca la freccia oggi**, la toccherebbe a rev2 onorato. ⛔ **Registrato come decisione di Mauro APERTA, non chiuso.**

**`BOX5_QBEATS.md` — versione V37 → V38**, blocco `Delta V38 vs V37`, con **tre incisioni**:
- **BLOCCO 3** — marcatura additiva: la metà «overlay di ripresa» passa a **SUPERATA**; le altre due **non riscritte**. Include la chiusura di un dato scaduto: la marcatura del 28/08 dava il collaudo device di A240 come «NON ancora eseguito» — **è verde dal 28/08**.
- **TASSONOMIA** — le due voci nuove (§3 sotto).
- **La metà mancante del §7** (§3 sotto).

---

## §3 — LE TRE REGOLE: DOVE, E PERCHÉ

**(3b) «Una sonda che rende zero va mostrata vedere» → `BOX5`, TASSONOMIA DEI DIFETTI DI MISURA. Voce nuova: `POSITIVO DI FORMA SBAGLIATA` (P2).**
⚠️ **Non è un duplicato, e ho verificato prima di scrivere:** la TASSONOMIA dice già *«P1 e P2 rendono entrambe zero, e si distinguono SOLO col controllo positivo»* — cioè **che il positivo ci vuole**. **Non dice che dev'essere della stessa FORMA dell'oggetto**, ed è precisamente lì che si è rotta oggi. La voce incide quel pezzo, con i due casi misurati (`= SetlistRunner(` · i pannelli cercati per modificatore di sistema in un'app che li disegna a mano).

**(3a) «Assenza di fonte non è prova di assenza» → `BOX5`, TASSONOMIA. Voce nuova `ASSENZA DALLA PROPRIA VISTA` (P2) + una nota dedicata che punta al §7.**
⛔ **NON l'ho incisa nella Costituzione, benché il mandato la collochi «§7, la metà mancante» e per contenuto abbia ragione.** La Costituzione è **documento di regime**: ultima modifica `bd70783` di giugno, e **nessun mandato mi ha mai autorizzato a scriverci**. Toccarla di mia iniziativa sarebbe stato il gesto più pesante della serata, preso senza mandato. ⇒ Incisa dove vivono i difetti di misura, **con puntatore esplicito al §7 e il testo pronto in due righe**: se il referee vuole farlo salire in Costituzione, **è un atomo suo e non deve riscrivere niente.**

**(3c) «Il danno di un comando morto non sta nella funzione che chiama» → `BUGS`, sezione «Lezioni metodologiche attive».**
**[M] Verificato che non fosse già incisa** (sonda per contenuto su BUGS e BOX5 → zero). **Perché lì e non in BOX5:** non è un difetto di *misura* — è una regola di **valutazione della gravità**, e la sede delle lezioni di metodo che governano come si classificano i bug è in BUGS, accanto ai ticket che classifica. Ha già prodotto un effetto: è la ragione per cui `TD-restart-song-falsa-ricevuta` **non** è classificato «seccatura».

---

## §4 — ⛔ COSA NON HO MISURATO — dichiarato, non riempito

- ⛔ **Zero device, zero build.** Tutto è lettura a `9c3616e`. **La chiusura del pannello resta DEDOTTA** — è marcata come tale in **tre sedi** (ticket, LIBRO 1c, questo referto).
- ⛔ **Non ho verificato che «Restart song» sia raggiungibile via MIDI su un device reale.** Ho misurato che l'azione `.stop` esiste, che è mappabile e che chiama `handleStop()`; **non ho visto una mappatura reale né l'ho provata.**
- ⛔ **Non ho aperto il rev2 «Attesa e Dettaglio»**, benché il ticket 2b lo riguardi: le misure del ticket sono **sul codice**, la ratifica del freeze la prendo dal mandato e da A258. **Se il rev2 dicesse qualcosa di diverso da come è stato riassunto, il ticket eredita l'errore.**
- ⛔ **Non ho verificato che le tre voci nuove di LIBRO Sez.2 non contraddicano righe più vecchie** della stessa sezione oltre a quelle che ho letto (25/08, 28/08, 29/08 firme B-E). Sez.2 ha ~190 righe: **ne ho lette una decina.**
- ⚠️ **Incoerenza PRE-ESISTENTE trovata e NON riparata:** BOX5 era a **V37 senza un blocco `Delta V37 vs V36`** — l'ultimo scritto era V36. Non l'ho inventato a posteriori (non so cosa contenesse) e non ho rinumerato: **V38 segue la testata**. Dichiarato anche nel delta.
- ⚠️ **Faccia dei file, dichiarata:** `.gitattributes` marca `-text` BOX3/BOX5/HANDOFF/DESIGN; **LIBRO e BUGS no**, quindi per loro vale `core.autocrlf=true` (disco CRLF, blob LF). La mia riscrittura di BUGS l'ha lasciato **LF su disco** — git avverte che lo riporterà a CRLF al prossimo checkout. ✅ **Nessun impatto sul commit**: `git diff --numstat` rende **31/34/5 righe**, cioè solo le modifiche vere, **non un cambio di faccia dell'intero file**.

---

## §5 — I PERCORSI E LE IMPRONTE

```
DIFF    repo: HANDOFF\DIFF_INCIDERE-LA-SERATA_A260_2026-08-29_CC.txt
        E:  : FILE X CLAUDE.MD\HANDOFF\DIFF_INCIDERE-LA-SERATA_A260_2026-08-29_CC.txt
        sha256 10c34f7cc66ac423f879e1fd7d84ce6eec1fd35a… · 166 righe · 42 965 byte · cmp identici

REFERTO repo: HANDOFF\MISURE_CC_2026-08-29_A260-INCIDERE-LA-SERATA.md
        E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A260-INCIDERE-LA-SERATA.md
        (impronta nel messaggio di consegna: il file non può contenere il proprio hash)
```

⛔ **Nessun commit.** Ratifica del referee → OK di Mauro → poi il commit. **Chiuso è solo dopo il device.**

---

## §6 — LA TERZA GAMBA: DRIVE — misurata su richiesta di Mauro, non dedotta

⚠️ **Mauro ha chiesto in corsa di depositare anche su `E:` e su Drive. Aveva ragione a chiederlo: avevo depositato su `E:` i soli diff e referto, e Drive non l'avevo interrogato affatto.**

### ✅ Drive: i due artefatti di A260 CI SONO — interrogato via MCP, non supposto

**[M]** `search_files` su `title contains 'A260' or title contains 'INCIDERE-LA-SERATA'`:

| file | id | peso Drive | peso disco | creato (UTC) |
|---|---|---|---|---|
| `MISURE_CC_2026-08-29_A260-INCIDERE-LA-SERATA.md` | `1chTeRk0…` | **10 381** | **10 381** ✅ | 20:03:55Z |
| `DIFF_INCIDERE-LA-SERATA_A260_2026-08-29_CC.txt` | `1beI448i…` | **42 965** | **42 965** ✅ | 20:02:34Z |

⇒ **[M] Il riflesso di `E:` è vivo e immediato:** copiati su `E:` alle 22:02/22:03 locale, su Drive alle 20:02/20:03 **UTC** — **stesso minuto**. **[A] Il peso coincide su entrambi, ed è il controllo che discrimina: il nome no, il peso sì.**

⛔ **Non ho scritto niente su Drive a mano, ed è corretto così:** la gamba Drive si serve **depositando su `E:`**, che il riflesso propaga da sé. Scrivere nell'albero manuale (`I:\Il mio Drive\Qbeats\`) è **vietato da R-δ.4** ed è il ticket `TD-drive-doppioni-albero-abbandonato`.

### ⛔ I TRE CANONICI NON SONO PROPAGABILI OGGI, e non è una dimenticanza

**[M] La convenzione di `E:`, misurata leggendo le cartelle invece che ricordandola:** i canonici si propagano come **snapshot per-versione col SHA DEL COMMIT nel nome** —

```
BOX5_Test/      BOX5_V37_2026-08-29_2e1d542.md
BUGS_QBEATS/    BUGS_QBEATS_v70_2026-08-29_edf38d3.md
LIBRO_MASTRO/   LIBRO_MASTRO_QBEATS_v65_2026-08-29_2e1d542.md
```

⇒ **Lo sha è parte del nome, e il mio commit non esiste** — il mandato A260 lo vieta esplicitamente. **La propagazione dei canonici appartiene al giro del commit, non a questo.** Depositarli ora significherebbe inventare un nome senza sha, o pubblicare su tre supporti un contenuto **non ancora ratificato dal referee**.

### 🚨 REPERTO NON CERCATO — i file «vivi» senza versione su `E:` sono STANTII

**[M]** Accanto agli snapshot esiste in due cartelle una copia **senza versione nel nome**, e nessuna delle due è aggiornata:

| file | versione su `E:` | versione più recente accanto, nella STESSA cartella |
|---|---|---|
| `BUGS_QBEATS/BUGS_QBEATS.md` | **v68** | snapshot **v70** |
| `LIBRO_MASTRO/LIBRO_MASTRO_QBEATS.md` | **v64** | snapshot **v65** |

**[M] BOX5 non ha alcun file «vivo» su `E:`** — solo snapshot in `BOX5_Test/`. ⇒ **Le tre cartelle non seguono la stessa convenzione.**

⚠️ **[A] Il rischio è di lettura, non di dati:** chi apre `BUGS_QBEATS/BUGS_QBEATS.md` cercando «il file» trova **v68** — due versioni indietro — **senza nulla che glielo dica**, mentre lo snapshot giusto è nella stessa cartella. ⛔ **Debito PRE-ESISTENTE, non introdotto qui e NON riparato in questo giro** (fuori mandato): non so se quelle copie nude siano volute, residui, o l'origine di una convenzione poi cambiata. **Registrato perché non cada.**

*A260-INCIDERE-LA-SERATA-FINE*
