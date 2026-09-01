================================================================================
HANDOFF CC — 2026-07-30 sera — LIBRO v44 scritto, committato, propagato
================================================================================
Scritto da CC a chiusura sessione, per la PROSSIMA sessione CC. Indipendente
dall'handoff del referee per esplicita richiesta di Mauro: non l'ho letto, non
l'ho cercato, non ho allineato nulla di quanto segue a un'aspettativa su cosa
lui possa aver scritto. Se i due divergono, la divergenza è essa stessa un dato:
uno dei due ricorda male, meglio scoperto ora che fra tre sessioni.

**[V]** = misurato da me, in questo turno, con l'output a supporto.
**[R]** = riferito (da un prompt, da terzi, o da mia memoria di turni precedenti
in questa stessa chat) — non rimisurato adesso. Un [R] non è un errore: è
onestà su cosa non ho ri-toccato.

**Notazione:** `byte(disco)` vs `byte(blob)`; `righe (wc -l)`; **CR sempre con
`tr -cd '\r' | wc -c`, MAI con `grep -c`** (sottoconta sui multi-CR-per-riga).
Ogni zero porta il proprio controllo positivo nella stessa forma di comando, e
**il controllo positivo NON è concatenato con `&&`** — regola ratificata oggi
in v44, nata da un mio errore (vedi (e.1)).

================================================================================
(a) STATO DEL REPO A FONTE — tutto [V], misurato in questo turno
================================================================================

**HEAD = origin/master = `4d1f9741f5947e7677c84d3f31a586e34b7709f3`**
(confermato con `git fetch origin master` prima del confronto, non con un
`rev-parse` locale dato per buono).

`git status --porcelain -uno`: **vuoto** — nessun file tracciato modificato.
Controllo positivo, stessa forma: `git status --porcelain` nudo → **64 righe**,
tutte `??`. Il comando funziona; lo zero di `-uno` è un'assenza vera.
Di quelle 64, **62 sono in `HANDOFF/`**; le altre 2 sono i due piani in root
(`QBEATS_A5C_PIANO_2026-07-04.md`, `QBEATS_ATOMC_PIANO_2026-07-06.md`).
⚠️ **Fra le 62 c'è QUESTO handoff**: si conta da sé. Chi rimisura dopo che un
handoff è stato scritto troverà un numero diverso da chi misura prima, e non è
una discrepanza — è lo stesso fenomeno già visto ieri sera (59 vs 60).

**Canonici tracciati — ENTRAMBE le facce dove il file ne ha due:**

| file | versione dichiarata | sha256(disco) | byte(disco) | righe | CR | sha256(blob) | byte(blob) |
|---|---|---|---|---|---|---|---|
| `LIBRO_MASTRO_QBEATS.md` | **44 (30/07/2026)** | `b7e63741…508e038a` | 181705 | 471 | **471** | `18b6bc2b…75340fef` | 181234 |
| `BUGS_QBEATS.md` | **44** | `74fc8057…c9ea0773` | 208814 | 911 | **911** | `bef02dd6…0010095e` | 207903 |
| `BOX3_QBEATS.md` | **V99 — 2026-07-22** | `c728bacc…4d29fb3c` | 89457 | 803 | **0** | `c728bacc…4d29fb3c` | 89457 |
| `BOX5_QBEATS.md` | **V28 — 28/07/2026** | `cf425ff0…d184ff5b` | 57158 | 596 | **0** | `cf425ff0…d184ff5b` | 57158 |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | **3 (28/07/2026)** | `700d7caa…5549c0e14` | 35661 | 333 | **0** | `700d7caa…5549c0e14` | 35661 |

**Tre letture obbligate di questa tabella**, che il colpo d'occhio non dà:
1. **LIBRO e BUGS hanno DUE facce.** Disco CRLF, blob LF, e la differenza è
   esattamente il numero di CR: 181705−471=181234, 208814−911=207903.
   L'aritmetica chiude al byte su entrambi. **Chi confronta un'impronta DEVE
   dichiarare da quale faccia viene**, o il confronto è privo di significato.
2. **BOX3, BOX5 e SCALETTA hanno UNA faccia sola**: le colonne disco e blob
   sono identiche, sha e byte. CR=0, e il controllo positivo è nella stessa
   tabella — la stessa forma di comando rende 471 e 911 sugli altri due.
3. **BUGS è a v44 e NON è stato toccato oggi.** Le sue impronte sono identiche
   a quelle già agli atti dal 28/07. L'unico canonico scritto oggi è LIBRO.

================================================================================
(b) COSA È ENTRATO IN MASTER — tutto [V]
================================================================================

⚠️ **AVVERTIMENTO SULLE DATE, o il prossimo CC ci sbatte contro.** I timestamp
git dei tre commit dicono **2026-07-29**, ma le righe che il LIBRO v44 aggiunge
sono datate **2026-07-30**, e questo handoff pure. **Non è un'incoerenza.**
Convenzione verificata a fonte oggi: `LIBRO_MASTRO_QBEATS.md:297` è una riga
datata `2026-07-22` il cui titolo dice «**decisa il 21/07** e mai messa agli
atti». ⇒ **la data di una riga è il giorno in cui ENTRA NEL REGISTRO, non il
giorno del fatto.** I fatti restano datati dentro il testo.

| # | sha40 | subject | autore = committer | CI (run · n°) | esito |
|---|---|---|---|---|---|
| 1 | `b9f4e5f0c806a40938136cd8bb076f590c5e851d` | S4K: congedo tastiera Q-Live (contratto Q20) — barra propria via safeAreaInset | Mauro Martintoni `<di_tutto@icloud.com>` | `30456740570` · #596 | **success** |
| 2 | `6c7352a19b0dc6edadca8c14d34939ca30711369` | DARK-DECL: UIUserInterfaceStyle=Dark — la UI di sistema segue l'app, non il device | Mauro Martintoni | `30463659772` · #597 | **success** |
| 3 | `4d1f9741f5947e7677c84d3f31a586e34b7709f3` | LIBRO v44: giornate 29-30/07 — … | Mauro Martintoni | `30477440486` · #598 | **success** |

Tutti e tre: **autore = committer = Mauro**, `%b` = **1 byte** (il solo
newline), `grep -ci "co-authored"` sul messaggio pieno = **0**.
Controllo positivo dello stesso `grep -ci`, su stringa certamente presente
(«LIBRO» nel messaggio di #3) → **1**: il comando conta, e lo zero è vero.
Tutte le CI lette con **sha a 40 caratteri** — con lo sha corto `gh run list
--commit` rende `[]` con exit 0 (falso-zero, BOX3 V99 (d)).

**Solo il #3 è stato scritto in questa sessione**; #1 e #2 sono di ieri e oggi
sono stati soltanto verificati.

**ANATOMIA DEL COMMIT #3** — è il numero che il cancello ha interrogato:
`git show --stat` → `1 file changed, 20 insertions(+), 4 deletions(-)`.
· le **4 rimozioni sono tutte su campi VIVI** (header r.5/6/7 + Sez.5 r.393);
  **ZERO righe storiche toccate** — è l'invariante di questo documento e regge;
· le **20 inserzioni** = 4 righe riscritte + 16 nuove (7 righe Sez.2 + 8 righe
  Sez.4 + 1 riga di registro);
· netto 455+16 = **471**, che chiude con le righe misurate in (a).

⚠️ **Lo scarto 19 vs 20 sollevato dal referee è SCIOLTO, e va ricordato perché
è istruttivo.** L'artefatto ratificato mostrava 19 righe `+`, il commit ne
applica 20. La ventesima è la **riga 395**: VUOTA. Verificata con
`sed -n '395p' … | cat -A` → rende il solo `$`, zero caratteri e zero spazi
nascosti; la 396 è `### Voci risolte come moot …`. È il **separatore markdown
obbligatorio** prima di un `###`, altrimenti l'intestazione non si rende.
**Nessun contenuto è entrato nel canonico senza passare il cancello.**

**PROPAGAZIONE ESEGUITA** — «pushato ≠ propagato»:
`E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\LIBRO_MASTRO\LIBRO_MASTRO_QBEATS_V44_2026-07-30_4d1f974.md`
**181234 byte** · sha256 `18B6BC2B7EE053B14F0E211E5C080775F7A47F07886AAE4E804CFFFA75340FEF`
⚠️ Lo snapshot è la **faccia BLOB**, e coincide col blob del repo al carattere.
È il regime in vigore, non una scelta mia: lo snapshot V43 pesa 162712 =
163167−455 e porta l'impronta del blob di v43. Il prompt diceva «confrontalo
con la faccia disco: devono coincidere» — ho seguito il regime e dichiarato lo
scarto. **Chi propaga domani faccia lo stesso, o rompe la serie V39→V44.**
⛔ **Nessuna copia a nome vivo creata**, solo il nome per-versione: sarebbe
stato ricreare, nel commit che lo denuncia, il difetto che il commit denuncia.

**[R] — non fatto da me, da ricordare a Mauro:** il caricamento dello snapshot
nel Progetto Claude. Path e impronta sono quelli sopra.

================================================================================
(c) COSA HO MISURATO CHE NON È IN NESSUN CANONICO — materiale per BUGS v45
================================================================================

È la parte che pesa. Tutto quanto segue esiste **solo in questa chat**:
**zero righe di questo materiale sono incise in BOX3/BOX5/BUGS/LIBRO.**

--------------------------------------------------------------------------------
**1. L'ICONA DELL'APP — il ticket più maturo, misure complete.**
--------------------------------------------------------------------------------
Tutte **[V] rimisurate in questo turno** sull'artifact della run `30463659772`
già estratto (NON riscaricato — vive nello scratchpad della sessione
`33ffa7bc-…`, che NON è quella corrente; vedi trappola (g.3)).

· **File icona nel prodotto reale: ZERO.**
  `find <QBeats.app> -iname "*icon*" -type f` → nessun risultato.
  Controllo positivo: `.png` totali nel bundle → **0**.
  Controllo positivo 2 (che `find` non sia rotto): file totali → **35**.
  Il bundle NON è vuoto: `click.wav`, `embedded.mobileprovision`, `Info.plist`,
  6 `Inter-*.ttf`, 16 `JetBrainsMono-*.ttf`, `PkgInfo`, il binario `QBeats`
  (9.846.032 byte), `test_backtrack.mp3`, `ZIPFoundation.bundle` (6 file),
  `_CodeSignature`. **Font, audio, binario, firma: presenti. Icona: assente.**

· **Chiavi icona nell'`Info.plist` BINARIO del prodotto: 4 su 4 ASSENTI.**
  `CFBundleIcons` · `CFBundleIcons~ipad` · `CFBundleIconFiles` · `CFBundleIconName`
  Controllo positivo: **36 chiavi totali** nel plist — non vuoto, non troncato.
  (Nello stesso plist, riconfermati oggi: `CFBundleIdentifier` =
  `'com.bullfrog.qbeats'`, `CFBundleVersion` = **`'1'`**, `UIUserInterfaceStyle`
  = **`'Dark'`**.)

· **Riferimenti nel repo: ZERO.**
  `grep -rn "APPICON\|AppIcon\|ICON_NAME" ios_app/ .github/` → 0 righe, exit 1.
  Controllo positivo: `grep -c "QBeats" ios_app/project.yml` → **17**.

· **NESSUN CATALOGO GRAFICO ESISTE.** `.xcassets` **0** · `.colorset` **0** ·
  `.imageset` **0**. Controllo positivo: `.swift` nel repo → **66**.
  ⇒ Non è «zero varianti chiare dentro il catalogo»: **il catalogo non c'è.**

· **[R], dichiarato da Mauro il 30/07 — cambia la natura del ticket:**
  l'artefatto grafico dell'icona **esiste già, ma è fuori dal progetto.**
  ⇒ Il ticket NON è «disegnare l'icona». È **un'INTEGRAZIONE MAI FATTA**:
  reperire il file · verificarne la conformità (dimensioni, formato, alpha) ·
  **creare il catalogo grafico oggi inesistente** · dichiararlo in `project.yml`
  (NON nel file fisico `Info.plist`, che il prodotto ignora — vedi (g.5)).
  Classificazione già decisa dal referee: **debito tecnico → BUGS**, non materia
  LIBRO. Test di scope applicato: «CD deve saperlo o coordinarsi?» → **no**.

--------------------------------------------------------------------------------
**2. TERZA COPIA LIBRO A NOME VIVO — REPERTO, non candidata alla cancellazione.**
--------------------------------------------------------------------------------
**[V]** rimisurata in questo turno, dopo la pulizia:
`E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\DA_CD_PER_CC\11_07_2026\1Q-BEATS\uploads\LIBRO_MASTRO_QBEATS.md`
**46939 byte** · sha256 `B7A39593A72161E45FA6FE10B41FC2C879A8821911E26BBB66ED4582F558A0E3`
riga di versione letta **dal file**: `**Versione:** 13 (proposta, in attesa
ratifica esplicita Mauro …)` — contro il canonico **44**. Trentuno versioni
indietro, col nome che promette lo stato corrente.

⚠️ **LA SUA NATURA NON È QUELLA DEI DUE MIRROR RIMOSSI, e la differenza è
sostanziale, non burocratica.** Vive dentro `DA_CD_PER_CC\11_07_2026\…\uploads\`:
una cartella di consegna **datata nel path**, cioè l'archivio di ciò che fu
consegnato quel giorno. Una copia d'archivio che porta il nome che aveva allora
è **coerente col proprio contenitore** — il path stesso dichiara «11_07_2026»,
quindi il lettore sa a cosa sta guardando. Un mirror stale in `LIBRO_MASTRO\`
non ha nulla che lo dichiari: quello mente, questo no.

⛔ **NON l'ho toccata e NON propongo di cancellarla.** Chi la trattasse come i
due mirror distruggerebbe un reperto di consegna. **La domanda giusta non è
«cancellare?» ma «un archivio di consegna deve portare il nome vivo?»** — e la
risposta plausibile è sì, perché è ciò che fu consegnato. Va deciso a parte.
⚠️ Precisazione di onestà: ho misurato **dove sta e cosa contiene**; la lettura
«archivio di consegna» è un mio ragionamento sul path, **non un fatto misurato**.

--------------------------------------------------------------------------------
**3. IL CONTRATTO Q20 NON È NEL REPO NÉ NELLA STORIA GIT.**
--------------------------------------------------------------------------------
Il fatto è entrato in LIBRO v44 (riga `2026-07-30` ARTEFATTI NORMATIVI…), ma le
misure complete vivono solo qui. **[V]** rimisurate oggi:
  `find . -iname "*Q20*" -o -iname "*Keyboard-Dismiss*"` → **0**
  `git log --all --diff-filter=A -- "*Q20*" "*Keyboard-Dismiss*"` → **0**
  Controllo positivo della forma `find`: `.html` in `DESIGN/` → **6**.
Unica copia esistente, su E:, mai committata:
`…\FILE X CLAUDE.MD\DA_CD_PER_CC\26_07_2026\2026-07-26_QLive-Shows-Keyboard-Dismiss__Q20-RIEMISSIONE.html`
**37430 byte** · 308 righe · sha256 `5DCFBBFBFEFE7607CFDAC58B73FB2DDB2898012788D75F9827203E1C5AB9D408`
Righe citate dal codice, verificate ieri **[R] oggi**:
  r.32  `--live:#d43f00; --live-l:#ff8a5c; --amber:#f5b820;`
  r.103 `.kbtoolbar{height:46px; background:#1c1c20; …}`
  r.104 `.kbdone{… color:var(--live-l); … min-height:44px; …}`

--------------------------------------------------------------------------------
**4. CENSIMENTO NOME-VIVO SU E: — esito per-canonico.**
--------------------------------------------------------------------------------
Solo la conclusione è in v44; i numeri per-canonico stanno qui. Nome esatto,
ricorsivo sotto `FILE X CLAUDE.MD\`:
  · `BOX3_QBEATS.md` → **0**   · wildcard `*BOX3*` → **94 file, TUTTI versionati**
  · `BOX5_QBEATS.md` → **0**   · wildcard `*BOX5*` → 35, tutti versionati
  · `SCALETTA_ATOMI_S6_2026-07-10.md` → **0** · wildcard → 5, tutti versionati
  · `BUGS_QBEATS.md` → era **2**, oggi **0** (cancellate, punto 5)
⇒ **L'archivio non è malato: è tenuto bene.** Novantaquattro file BOX3 su
novantaquattro, per mesi, senza una scivolata. Il difetto riguardava i **soli
due canonici che in git vivono a NOME NUDO** (LIBRO e BUGS): chi li ha copiati
su E: ha portato con sé il nome del repo. BOX3/BOX5/SCALETTA sono nati
nell'archivio, dove la regola del suffisso c'era già.

--------------------------------------------------------------------------------
**5. PULIZIA E: ESEGUITA — e un debito di nomenclatura che nessuno dichiara.**
--------------------------------------------------------------------------------
Autorizzata da Mauro **in chiaro nel turno stesso** (non dedotta da messaggi
precedenti). Pre-controllo: `BUGS_QBEATS43.md` presente e intatto.
Cancellate: `BUGS_QBEATS\BUGS_QBEATS.md` e `CC MEMORIA\BUGS_QBEATS.md` —
identiche fra loro, contenuto **v43** contro canonico **v44**.
Post-controllo **[V] rimisurato ora**: nome vivo `BUGS_QBEATS.md` → **0**;
controllo positivo stessa forma `BUGS_QBEATS43.md` → **1**, 195668 byte,
sha256 `2FCF1D0659E313A9245AE5E458E259BD9035033665A44D24865A9E4D238F438F`
— **byte e impronta invariati: nessun contenuto perso.**

⚠️ **DEBITO MISURATO E NON RISOLTO, buon candidato per BUGS v45:** su E: esiste
**un solo** file in forma `BUGS_QBEATS_V*`, ed è `BUGS_QBEATS_V44_2026-07-28_4b55686.md`
(207903 byte). **Tutte** le versioni precedenti vivono nella convenzione VECCHIA
(`BUGS_QBEATS43.md`, senza `_V` e senza data/commit). Non è un guasto: è una
**discontinuità di nomenclatura che nessun canonico dichiara**, e che rende
falso-negativa qualunque ricerca futura fatta con la sola forma nuova.

--------------------------------------------------------------------------------
**6. ALTRE MISURE [V] DI OGGI, nessuna incisa.**
--------------------------------------------------------------------------------
· **LinkKit — tre commenti dicono ancora 3.x** mentre il vendor è a 4.0 dal
  commit `42424ef` (05/05/2026, **[R]**): `ios_app/QBeats/AudioEngine.swift:447`
  e `:457` («LinkKit 3.2.2»), `ios_app/QBeats/LinkEngine.mm:55` («LinkKit 3.x»).
  Controllo positivo: `grep -c "LinkKit" AudioEngine.swift` → **2** (sono
  esattamente quelle due righe).
· **`isPick` cablato a false**: `ios_app/QBeats/UI/QLive/QLiveShowsView.swift:274`
  → `let isPick = false`. È il motivo per cui «il congedo conserva la selezione»
  (contratto Q20) **non è testabile a HEAD**, ed è dichiarato così in v44.
· **ZERO diagnostica di guasto in tutto il progetto**: `grep -rn
  "Crashlytics\|Sentry\|Bugsnag\|MetricKit\|NSSetUncaughtExceptionHandler"
  ios_app/` → 0 righe, exit 1. Controllo positivo: file che usano
  `os_log`/`Logger(` → **17**. ⇒ La strumentazione esiste, ma è **leggibile solo
  con device fisico + iMazing**: di un guasto sul palco di un cliente non
  arriverebbe nulla. Su un'app che si vende, è il fatto più pesante di questa
  lista dopo l'icona.
· **[R], non rimisurati oggi**, dal censimento commerciale del 29/07:
  entitlement multicast e `get-task-allow` dichiarati incondizionatamente in
  entrambi i file · la CI produce solo build development-signed · il pannello
  Ableton è un bottone permanente, non un one-time · `CFBundleVersion` 142 nel
  file fisico contro `'1'` nel prodotto.

================================================================================
(d) COSA NON HO VERIFICATO — dichiarato in chiaro
================================================================================

- **[R] La documentazione Apple su `UIUserInterfaceStyle`.** TRE tentativi di
  fetch, tutti falliti: la pagina restituisce il solo titolo, corpo non
  recuperabile. **Non l'ho tradotto in «non documentato»**: è un fallimento di
  lettura mio, e la differenza conta. In LIBRO v44 la citazione è scritta
  marcata **[R]**. La chiusura di DARK-DECL **non ne dipende**: poggia sulla
  misura diretta sul prodotto e sul gate device. Mauro può convertirla in [V]
  aprendo la pagina a mano.
- **[R] Il gate DEVICE di entrambi gli atomi** (⟦S4K⟧ sulla UX reale, DARK-DECL
  sul colore su schermo). Non ho un device: non è qualcosa che io possa
  misurare. Lo riporto perché Mauro l'ha dichiarato, ma **nessuna riga di questo
  handoff certifica il device al posto suo.**
- **[R] Il portale Apple Developer.** Le 4 coincidenze incise in v44 valgono
  quanto vale la lettura di Mauro: io ho misurato solo il lato repo.
- **[R] Che l'entitlement multicast sopravviva alla firma su un profilo di
  DISTRIBUZIONE.** Nessuna build Distribution è mai stata costruita in questo
  repo. Inciso in v44 come non verificato, col precedente TD#44 (il permesso
  c'era sul portale e si perse **comunque** nella firma).
- **NON ho riletto la SCALETTA v3 per intero**, oltre l'intestazione e le schede
  ⟦S4K⟧/⟦S4R⟧. Chi riprende non dia per letto il resto.
- **NON ho verificato se la riga 141 della SCALETTA sia stata corretta.** Non
  l'ho toccata, quindi l'allarme falso è ragionevolmente ancora lì — ma
  «ragionevolmente» non è una misura.
- **NON ho misurato la natura archivistica** della terza copia LIBRO (c.2): ho
  misurato dove sta e cosa contiene; l'interpretazione è un ragionamento.
- **NON ho rimisurato** i sette punti del censimento commerciale del 29/07 né
  la versione di LinkKit alla sorgente (nessun marcatore indipendente trovato
  ieri dentro l'SDK).

================================================================================
(e) DOVE HO SBAGLIATO IO, E COME ME NE SONO ACCORTO
================================================================================

1. **Ho concatenato un controllo positivo con `&&`, e l'ho perso.** Nel blocco
   icona ho scritto `grep <pattern> … && echo … && grep -c <nota-presente>`: il
   grep ha reso zero, quindi **exit 1**, quindi la catena si è fermata **prima**
   di stampare il controllo positivo. Per un istante ho consegnato uno zero
   nudo — la forma esatta che questo progetto vieta, prodotta però dallo
   strumento e non da me. **Me ne sono accorto da solo**, rileggendo il mio
   output prima di scriverne il referto, e ho rifatto la misura con `;`.
   L'errore è diventato la **sesta forma di falso-negativo** ratificata in v44.
   Nota: la mia formulazione ha **prevalso** su quella del referee, che l'ha
   ritirata, perché conteneva un elemento che la sua non aveva — la **polarità
   opposta** rispetto al falso-zero di BOX3 V99 (d): exit **0** che fa sembrare
   un fatto un vuoto, contro exit **1** che sopprime la prova. Si **sommano**,
   non si sostituiscono. Chi cerca la prima non riconosce la seconda.
2. **Ho scritto un path duplicato dentro un diff già consegnato**:
   `ios_app/QBeats/QBeats/Info.plist` invece di `ios_app/QBeats/Info.plist`, nel
   caso (b) della regola nuova. Corretto prima di dare l'impronta, ma il file
   era già su disco con l'errore dentro: se il referee avesse letto in
   quell'istante, avrebbe ratificato un indirizzo inesistente. **L'impronta
   protegge dall'alterazione, non dall'errore.**
3. **Ho scritto «QUATTRO casi dello stesso stampo»** nella riga INDIRIZZO, NON
   COPIA, mentre nella stessa riga definivo il caso (d) «meccanismo distinto» —
   due affermazioni incompatibili nella stessa frase. **Non me ne sono accorto
   io**: è stato il referee a chiedere che (d) fosse dichiarato come meccanismo
   distinto, e solo applicando la sua correzione ho visto che la mia apertura
   la contraddiceva.
4. **Ho lanciato un `find /` sull'intero filesystem** per un controllo positivo
   che non ne aveva bisogno: timeout a 120s, finito in background. Errore di
   proporzione — il controllo scoped al repo (66 `.swift`) bastava e costava un
   istante.
5. **Ho affermato quale modello mi stesse eseguendo** («per questo turno Sonnet
   5 era adeguato») come se fosse un fatto: era un'inferenza dall'output di un
   comando `/model`, non una misura. Andava marcata **[R]**. Non ho introspezione
   sui pesi e nessun tool riporta il modello servente: **è un [R] strutturale**,
   non un buco colmabile. Nel giorno in cui abbiamo ratificato una regola sul
   non dichiarare stati che non si possiedono, è lo scivolone che quella regola
   descrive. Me l'ha fatto notare Mauro.

================================================================================
(f) DOVE HO CORRETTO IL REFEREE, O DOVE PENSO SI SBAGLI ANCORA
================================================================================

**Correzioni fatte oggi, tutte con misura a supporto:**
- **La SCALETTA porta un allarme oggi FALSO.** `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md:141`
  dichiara «RATIFICA NON ANCORA ATTERRATA IN LIBRO — pendenza aperta». Era vero
  su v42; **è atterrata in v43** (`LIBRO:317`; misurato: «S4K» 3 righe, «S4R» 3
  righe, controllo positivo «Mauro» 162). L'allarme è rimasto acceso su una
  pendenza chiusa → caso (a) della regola nuova.
- **`ee31281` NON è S4b.** La Sez.5 lo descriveva così dal v41: `ee31281…` è
  **⟦FIX-PILL⟧** (23/07), S4b è `6ded4ab…` (19/07). Rilevato da me mentre
  riscrivevo quel campo; il referee ha verificato in proprio e confermato.
  → caso (d) della regola nuova + rettifica applicata in v44.
- **La generalizzazione «il difetto è del sistema di cartelle» era FALSA.** Il
  referee me l'aveva data come premessa e mi aveva messo in allarme su BOX3.
  Misurato: BOX3 **94 su 94** versionati, BOX5 35, SCALETTA 5. Il referee ha
  ritirato la propria diagnosi, e **la falsificazione è incisa in v44**: quella
  riga documenta un errore del referee, ed è giusto che ci sia.
- **La riga delle domande a CD non era una decisione** e stava in una sezione di
  decisioni, con un campo `Stato` che non ammette «non ancora risposta».
  Segnalato; il referee ha riconosciuto l'errore e l'ha spostata in Sez.4.
- **Lo snapshot su E: è la faccia BLOB, non quella disco.** Il prompt diceva
  «devono coincidere» con la faccia disco: eseguirlo alla lettera avrebbe rotto
  la serie V39→V43. Ho seguito il regime misurato e dichiarato lo scarto.
- **La riga icona non esisteva nel mio diff.** È arrivata una correzione per
  rimuoverla: il messaggio che la introduceva non mi era mai stato consegnato.
  Dichiarato invece di fingere di avere quel testo.

**Dove penso — PARERE, non misura — che resti scoperto qualcosa:**
oggi ci sono stati **TRE scarti di conteggio** (14 vs 17 occorrenze, 19 vs 20
inserzioni, 63 vs 64 untracked), e **tutti e tre si sono risolti come artefatti
di misura, nessuno come difetto reale**. Ognuno è costato un giro. Il rischio
non è il singolo scarto: è che l'abitudine a vederli sciogliersi faccia
abbassare la guardia sul quarto, che potrebbe non essere innocuo. **Varrebbe la
pena fissare UNA convenzione di conteggio** — righe-che-contengono vs
occorrenze-totali, e se un documento si conta da sé — e dichiararla in un
canonico, invece di ricostruirla ogni volta a mano.

================================================================================
(g) TRAPPOLE TECNICHE PER IL PROSSIMO CC
================================================================================

1. **`&&` TRONCA IL CONTROLLO POSITIVO.** `grep … && echo … && grep -c …`: se il
   primo grep rende zero esce con **1** e la catena si ferma, quindi lo zero
   arriva **senza la prova**. **Usare `;`.** Ratificato in v44. Vale per ogni
   comando diagnostico, non solo per grep.
2. **`gh run list --commit` SEMPRE con sha a 40.** Con lo sha corto rende `[]`
   con exit **0** (BOX3 V99 (d)). **Polarità opposta** alla trappola 1: le due
   si sommano, e chi conosce solo una delle due non vede l'altra.
3. **Gli scratchpad sono PER-SESSIONE.** L'IPA estratto ieri vive in
   `…/Temp/claude/C--Users-BULLFROG/33ffa7bc-…/scratchpad/ipa_30463659772/`, che
   **non** è la cartella della sessione corrente. È ancora lì e si riusa
   dichiarando che è quello — ma non lo si trova cercandolo nel proprio.
4. **`python3.exe` nativo non capisce i path Git-Bash (`/c/Users/…`)**: serve
   `C:/Users/…`. `ls` e bash li traducono (binari MSYS), un eseguibile Windows
   nativo no — `FileNotFoundError` su un file che esiste.
5. **Il file fisico `ios_app/QBeats/Info.plist` NON comanda il prodotto.**
   `project.yml → info.properties` sì, provato con ground truth (le chiavi
   dichiarate solo lì sono nel prodotto; `CFBundleVersion` è `'1'` nel prodotto
   e 142 nel file fisico). Fonte verbatim, XcodeGen `Docs/ProjectSpec.md`:
   «This is the path where the plist will be written to» — `path:` è dove
   XcodeGen **SCRIVE**. ⛔ **Ogni futura chiave Info.plist va in `project.yml`.**
6. **LIBRO e BUGS hanno DUE facce; BOX3/BOX5/SCALETTA una sola.** Prima di
   confrontare un'impronta, stabilire da quale faccia viene. **Lo snapshot su E:
   è la faccia blob.**
7. **Inserire righe in una tabella markdown esige adiacenza DIRETTA.** Una riga
   vuota fra l'ultima riga esistente e le nuove **spezza la tabella**: in Sez.2 e
   Sez.6 va ancorata la coda dell'ultima riga. In Sez.4, che è prosa, la riga
   vuota serve invece, o il `###` non si rende come titolo. È l'origine dello
   scarto 19/20 di oggi.
8. **`ToolbarItemGroup(placement:.keyboard)` con `Spacer()` dentro `HStack` →
   toolbar VUOTA** su device (bug Apple, forum thread 736040, mai risolto). In
   Q-Live si usa `.safeAreaInset(edge:.bottom)`. ⛔ **Niente `NavigationStack`
   in Q-Live.**
9. **`.ignoresSafeArea(.keyboard, edges:.bottom)` NON annulla un inset aggiunto
   da `.safeAreaInset(edge:.bottom)`**: sono due `SafeAreaRegions` distinte.
10. **La CI produce SOLO IPA development-signed.** «CI verde» ≠ «pronto per lo
    Store»: manca l'intera categoria Distribution (certificato/profilo,
    `get-task-allow:false`, entitlement multicast riverificato sul profilo).

================================================================================
(h) COSA RESTA PRONTO, COSA RESTA BLOCCATO — E DA CHI
================================================================================

**PRONTO — il prossimo documento:**
- **BUGS v45.** È il passo successivo nella sequenza raccomandata dal referee
  (LIBRO v44 → BUGS v45 → seconda ondata SCALETTA / BOX5 V29 / BOX3 V100).
  **Il materiale è tutto in (c), già misurato: NON rimisurarlo.**
  Ticket più maturo: **l'icona** (c.1) — misure complete con controlli positivi,
  classificazione già decisa (debito tecnico, non materia CD), e il [R] di Mauro
  che ne cambia la natura da «disegnare» a «integrare».
  Secondo candidato pronto: **la discontinuità di nomenclatura degli snapshot
  BUGS su E:** (c.5).
  ⚠️ **[R], NON confermato da me:** che BUGS v45 sia stato formalmente aperto.
  Il referee l'ha raccomandato come sequenza; non ho visto un prompt che lo apra.

**BLOCCATO, E DA CHI:**
- **La riclassificazione di severità di TD#17** in ottica commerciale è
  **decisione di MAURO** — non del referee, non mia. Incisa in v44 come pendenza
  aperta, esplicitamente **NON decisa**.
- **CD-Q17 e CD-Q18** (Sez.4 di LIBRO v44): la resa di «Search» (lente su
  iPhone, freccia su iPad) e la **modalità chiara preclusa per sempre** da
  DARK-DECL. Attendono **CD**, che su nessuna delle due è mai stato interpellato.
- **La verifica dell'entitlement multicast sul profilo di DISTRIBUZIONE.** Mauro
  l'ha segnalata come «da fare presto, non dopo il §6». Nessuna misura avviata,
  e serve una build Distribution mai tentata.
- **Il caricamento dello snapshot V44 nel Progetto Claude: MAURO.** Path e
  impronta in (b).
- **Gli artefatti normativi fuori dal controllo di versione** (contratto Q20 +
  icona): incisi in v44 come **buco dichiarato**, esplicitamente **non riparati
  lì**. Atomo doc separato, stesso trattamento del regime della SCALETTA
  (riga `2026-07-22`).
- **La riga 141 della SCALETTA** porta ancora l'allarme falso: non è stata
  toccata. Chi apre la SCALETTA lo legge e ci crede.
- **La terza copia LIBRO a nome vivo** (c.2): **reperto da decidere, NON
  candidata alla cancellazione.**

**FRONTE CODICE — ⟦S4R⟧.**
L'ordine ⟦S4K⟧ → ⟦S4R⟧ → ⟦S4L⟧ è **inciso e obbligatorio** (SCALETTA v3 `:159`,
pipeline `:310`), e ⟦S4K⟧ è ora **chiuso device + CI**. Per l'ordine ratificato
il prossimo è **⟦S4R⟧**: launcher, iniezione della setlist scelta + kill del
phantom `makeDefault` (`ios_app/QBeats/UI/LiveRootView.swift:7-8,:13` — **[R]**,
righe non ri-verificate oggi, da riverificare **per SIMBOLO**, non per riga).
⚠️ **Ma non ho visto un prompt che lo apra: l'ordine è legge, il via no.**
Chi riprende verifichi a fonte prima di assumerlo, e legga la pendenza «coppia
stretta con S4 va ri-tarata» nella scheda ⟦S4R⟧: l'inserimento di ⟦S4K⟧ fra S4 e
il launcher ha rotto la contiguità che la v2 prescriveva.

================================================================================
FINE HANDOFF.
================================================================================
