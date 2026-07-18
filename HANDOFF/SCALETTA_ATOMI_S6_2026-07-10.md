# Q-BEATS — Mini-piano §6 + Scaletta atomi (RATIFICATA)

**Versione:** 2 (17/07/2026)  ·  **Ratificata dal referee:** 13/07/2026 (v1) · **⟦NODO A⟧ CHIUSO device 17/07** (v2)
> Prima versione numerata. Prima d'ora la scaletta era identificata solo dalla data nel
> nome-file (`_2026-07-10`), che è più vecchia del contenuto reale (riscrittura S3 del
> 12/07). D'ora in poi la fonte di verità è QUESTO campo Versione, non la data nel nome.

- **Freeze contratto (IN GIT):** contratto vivo `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0` (taglio +Q7-Q16). Riferimenti al freeze per SELETTORE, mai per riga. R7: nessuno sha256 inciso.
- **HEAD repo:** `6fca624` (in-sync origin/master, 12/07). Verifica a source per SIMBOLO poi riga, ancorata `@ 6fca624` — MAI a un commit storico (regola «pushato≠propagato» §7 BOX3 V92, R7 LIBRO v31).
- **⚠️ STATO 12/07 — ⟦S3⟧ RISCRITTO su questa versione** (vedi sotto; la 10/07 prescriveva un «+» morto vietato da CD-Q7). Atomi GIÀ COMMITTATI (CI-verdi, NON device-chiusi): S0 `995a3bf` · S1 `87a8280` · S2F `f91533f` · S2 `ed11f65` · poi il ciclo CD-decisioni NON previsto nella scaletta 10/07: S2b `8d7c7d1` · S2c `9bb4ef6` · S2e `7550476` (allineamento commenti R7 + gate reali) · S2d `ab6b553` (estrazione `EmptyStateKit`). RESTANO: **S3** (prossimo) · NODO A · S4 · S4L · S5 · S6.
- **Stato:** impianto §6 + scaletta RATIFICATI dal referee (impianto 10/07). ⟦S3⟧ è stato RISCRITTO il 12/07 dal contratto ratificato e **RE-RATIFICATO dal referee il 13/07** → S3 può essere guidato da questa scaletta. Ogni atomo passa comunque il cancello (source→diff verbatim→referee→OK Mauro→device dove segnato→commit Mauro/0-CoAuth).
- **Depositato in:** `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` (untracked, NON repo).

---

## A · Mini-piano §6 (mappatura contratto → codice)

**CONGELATO (cabla):** ① Q-Live›Shows read-only (search+METROFAB) · ② Show-detail read-only (Start) · ③ METROFAB=uscita metronomo · ④ RoomSwitchBar `.roomseg` in 2 header · ⑤ empty: no-shows/show-vuoto/all-orphan.
**DIFFERITO (NON cablare):** colori tag (R1-pending) · modello dati tag HYBRID · §8 authoring/Arrange · footer Sync/`--link-grn` · variante iPad + schermata metronomo.

**3 frame → codice (tutto nuovo; nessuna vista Shows/Detail esiste):**
- **① SHOWS·Q-STAGE** (context): oggi la tab Shows in `QStageRootView` (`@ 6fca624`) = `QStagePlaceholderTab(title:"Shows", …)`. → `ShowsListView` (header `RoomSwitchBar[active:.qStage]` · **NIENTE «+»** (CD-Q7) · search · sort sheet Q11 · righe da `QBeatsStore.setlists`). ⚠️ La 10/07 diceva `[Q-Stage,+]`: il «+» è OMESSO finché §8 non arriva, niente bottone morto.
- **② SHOWS·Q-LIVE** read-only: oggi non esiste (Q-Live = `LiveRootView`→`LiveView`). → root di `QLiveRootView` post-Nodo-A (RoomSwitchBar[Q-Live, no+] · search no-sort · METROFAB · pick cosmetico).
- **③ SHOW DETAIL** read-only: → `QLiveShowDetailView` (navbar back+seg-mini · songlist · Start gattato su risolto-non-vuoto).

**RoomSwitchBar `.roomseg`:** 0 in codice (confermato). Componente condiviso, switch = dominio CC. Container `rgba(255,255,255,.05)`+bordo `.10`; attivo tint blu `rgba(42,107,214,.24)`/arancio `rgba(212,63,0,.24)`; inattivo `.30`; pill 34pt, hit 54pt. Switch reale = commutare `AppRootView.screen` `.qStage↔.qLive` → dipende da Nodo A.

**Riuso-LiveView-su-vuota:** `SetlistRunner:140-148` — setlist vuota → `guard currentSection nil` → `.fineSetlist` immediato (NON un metronomo). Il free-metronome richiede **Opzione 1** (sezione sintetica "free", riuso catena invariata); Opzione 2 (`mode:.freeMetronome` nel cuore RT) **vietata** (pezza RT, collide `TD-rt-vector-beatevent §4`). In §6 si cabla **solo la porta METROFAB**, destinazione differita.

**Dipendenza vs Nodo A:** hard, ordine forzato **Nodo A → §6** (i frame ②③ vivono nella shell `QLiveRootView` che Nodo A crea; lo switch RoomSwitchBar richiede l'enum `.qLive`).

---

## B · Scaletta 10 atomi

Legenda: **flip** PRE (Nodo-A-indipendente) / POST (richiede `.qLive`) / SPINE · **gate** CI / CI+DEVICE / DEVICE. Nessun atomo scrive dati utente (i path write `moveSetlists :105-108`, `addSetlist :89-91` sono deliberatamente NON cablati).

### ⟦S0⟧ QLiveTheme — token strutturali · PRE · CI
- **Scopo:** nuovo enum top-level `QLiveTheme` coi 3 token §3; nessuna view.
- **File:** `UI/QLive/QLiveKit.swift` (NUOVO) — `surf=Color(hex:"#16161a")`, `bd=Color.white.opacity(0.06)`, `pick=Color(hex:"#1a1614")`. (Scelta CC: file dedicato, non dentro `QStageTheme` — `QStageKit.swift:4-5` riserva #0e0e10 alla Q-Live. Folder-glob `project.yml:86` → auto-incluso.)
- **Reversibilità:** cancella file.
- **Cond:** E (solo strutturali; swatch tag R1-pending NON qui).

### ⟦S1⟧ RoomSwitchBar — componente INERTE + tipo `Room` · PRE · CI
- **Scopo:** componente `.roomseg` (0 in codice), highlight pilotato dall'esterno, closure iniettate; zero logica switch.
- **File:** `UI/Components/RoomSwitchBar.swift` (NUOVO). `enum Room { case qStage, qLive }` (NON `AppRootView.Screen`). Props: `active: Room` (highlight stateless, no `@State`), `onSwitch` (no-op default), `onHome` (**RICHIESTA**, non-defaulted), `variant full/segMini`. Colori = token esistenti `QStageTheme.blue`/`.orange`/`.text3`; solo container `.05`+bordo `.10` nuovi. ⚠️ FATTO (`87a8280`): la 10/07 elencava anche `showsPlus`/`onAdd?` — CD-Q7 li ha UCCISI e il componente committato NON li ha (props reali a `@ 6fca624` = `active`/`onHome`/`variant`/`onSwitch`).
- **Reversibilità:** cancella file.
- **Cond:** B (inerte + highlight da `active:` = no-illusion), A (onHome richiesta → binding al seam N0 forzato dal compilatore).

### ⟦S2F⟧ MetroFAB — componente condiviso · PRE · CI
- **Scopo:** estrarre il METROFAB in componente proprio (sta in 2 schermate, azione di un 3° atomo).
- **File:** `UI/QLive/MetroFAB.swift` (NUOVO). Bottone "Metronome", `onTap` iniettata (no-op default). Può usare `QLiveTheme` (S0).
- **Reversibilità:** cancella file.
- **Cond:** D (porta free-metronome; solo componente, azione a S6).

### ⟦S2⟧ Empty-state E/F/G (solo corpo) · PRE · CI · FATTO (`ed11f65`, poi rework S2b/S2c/S2e/S2d)
- **Scopo:** 3 corpi empty (no-shows/show-vuoto/all-orphan) + CTA + slot MetroFAB; no header, no routing. ⚠️ La 10/07 diceva «CTA morte»: SUPERATO da CD-Q9 (LIBRO v31) — la CTA «Go to Q-Stage» è ATTIVA low-emphasis, classe `.cta.quiet`, NON disabilitata (implementata S2b `8d7c7d1`, nome corretto S2c `9bb4ef6`). E i 3 blocchi base sono stati poi estratti in `EmptyStateKit` (S2d).
- **File:** `UI/QLive/QLiveEmptyStates.swift` (NUOVO). SOLO CORPO (no RoomSwitchBar). Usa `QLiveTheme` (S0) + MetroFAB (S2F).
- **Reversibilità:** cancella file.
- **Cond:** E; D (slot MetroFAB); A (forward-flag: "Go to Q-Stage"/MetroFAB = uscite → seam N0). ⚠️ Frame-E "onesto" metà qui: kill `makeDefault` sta in S4L → non marcare E "fatto" dopo S2. Dip: S0 prima.

### ⟦S3⟧ Q-Stage Shows list (frame ①) + sort sheet · PRE · CI + 🔴 PRIMO GATE DEVICE di §6
🔴 **RISCRITTO 12/07** dal contratto ratificato (LIBRO v31 sez.2 Q7/Q9-Q16 · BOX3 V92 §3/§4 ·
freeze `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0`). La versione 10/07 prescriveva un
«+» MORTO (vietato da CD-Q7) e la prop inesistente `showsPlus` — CANCELLATI.
- **Scopo:** rimpiazzare il placeholder Shows con lista reale + sort sheet; header RoomSwitchBar
  stato Q-Stage, IDENTICO a Q-Live (nessun «+»).
- **INNESTO (verificato a HEAD):** in `QStageRootView` (`ios_app/QBeats/UI/QStageRootView.swift
  @ 6fca624`) la tab Shows è oggi `QStagePlaceholderTab(title:"Shows", …, onExit: onExit)`;
  `QStageRootView` espone `onExit: () -> Void` → sostituire il placeholder con
  `ShowsListView(onExit: onExit)`. `UI/QStage/ShowsListView.swift` = NUOVO.
- **1 · HEADER:** `RoomSwitchBar[active: .qStage, variant: .full, onHome: onExit, onSwitch: no-op]`.
  NIENTE «+». Il componente (`RoomSwitchBar.swift @ 6fca624`; props REALI `active`/`onHome`/
  `variant`/`onSwitch` — `showsPlus`/`onAdd` NON esistono, li ha uccisi CD-Q7) NON si tocca.
- **2 · LISTA SHOWS:** una card per `setlist` (`QBeatsStore.setlists @ 6fca624`): nome
  (`Setlist.name`) · data (`Setlist.date`, sempre presente — `Date` non-opzionale) · conteggio
  canzoni (`Setlist.songIDs.count`, orfani inclusi) · durata (`QBeatsStore.estimatedDuration(for:)`).
  **Copy plurale (Q12):** `.cnt` «1 show»/«{n} shows» (incluso «0 shows») · `.mt` «1 song»/
  «{n} songs»; suffisso « · {m} min» SOLO se durata > 0 — a durata 0 sparisce ANCHE il «·».
  ⚠️ S2 aveva DELIBERATAMENTE evitato singolare/plurale (scelta N-agnostica di Q10). Qui SERVE:
  è il ramo plurale esplicito di Q12; le due scelte convivono (copy diverse, non si contraddicono).
- **3 · SORT SHEET (Q11):** bottom sheet «Sort shows», selezione singola + toggle Asc/Desc.
  STRINGHE VERBATIM (verificate nel freeze): «Sort shows» · «Name (A–Z)» / «Alphabetical ·
  default» · «Concert date» / «Chronological» · «Ascending» / «Descending». Default = Name (A–Z)
  Ascending. `.sortbtn.active` AMBRA quando ordinamento ≠ default.
  ⚠️ Gradiente di sfondo del foglio `linear-gradient(180deg,#171d3c,#0f1329)` (verbatim dal
  freeze): NON è un token del DS → resta INLINE nel componente sheet, copiato verbatim + commento
  che cita il SELETTORE. NON promuovere a S0 (cancello chiuso).
- **4 · STATO DEL SORT (S3-PRE, BOX3 V92 §4 — ratificato):** `@Published` VOLATILE in
  `QBeatsStore` (`@MainActor final class`, singleton `.shared`, `private init`), ASSENTE da
  `save()`/`load()` → zero disco (Q16), zero passaggio da `AppRootView`. Q-Live lo EREDITA in
  sola lettura (Q15): nessun `.sortbtn` in Q-Live, S4 lo rilegge da `.shared`. Debito dichiarato
  e ACCETTATO (non nascosto): stato di presentazione dentro uno store di dati = lieve odore
  architetturale; alternativa (ViewModel condiviso) costa più superficie.
- **5 · EMPTY-STATE Q13 (0 show):** badge `.eic.dim` · titolo «No shows yet» · corpo «Shows line
  up your songs for a gig, in the order you'll play them.» · NESSUNA CTA · `.searchrow` OMESSA ·
  tab bar resta visibile · `.scrhead` mostra «0 shows». RIUSA `EmptyStateKit`
  (`ios_app/QBeats/UI/Components/EmptyStateKit.swift @ 6fca624`, da S2d): `EmptyStateLayout` +
  `EmptyIconBadge` + `NoShowsIconShape`.
  ⚠️ TRAPPOLA DUE GLIFI: l'icona TAB-BAR «Shows» (path `…M4 18h10`, stroke 1.8) è DIVERSA da
  `NoShowsIconShape` (path `…M4 18h9`, stroke 1.7). NON riusare `NoShowsIconShape` per la tab
  bar — è un glifo a sé; chi li confonde sbaglia di 1 unità e nessuno se ne accorge. La nota è
  già sul simbolo in `EmptyStateKit.swift` (conservata nel move S2d).
- **6 · GATE:** CI + 🔴 **PRIMO GATE DEVICE DI TUTTO §6**. Chiude 3 dei 6 resi VISIVI (BOX3 V92
  §8): hit-area pill 54pt (reso 1) · inner-shadow `.eic` (reso 3, via `EmptyIconBadge`) ·
  lineSpacing (reso 5, via `EmptyStateLayout`).
  ⚠️ L'hit-area 54pt è il gate da cui dipende ANCHE S5 (CD-Q8, gattata): se il `.clipShape` del
  container mangia l'hit-test ereditato, l'espansione è INERTE e il bersaglio resta 30pt SENZA
  ALCUN SEGNALE (compila, gira, sembra a posto). Se passa, sblocca `.seg-mini` a S5 con
  `hitExpansion = (50−30)/2 = 10pt` (navbar 50pt, verificato nel freeze).
  ⚠️ MetroFAB NON è a schermo in S3 (è Q-Live, Frame Ⓔ → S4). Non cercarlo al gate.
  ⚠️ CHECKLIST TOKEN obbligatoria: tabella classe×proprietà → riga Swift o "N/A"+motivo, nessuna
  riga vuota.
- **Reversibilità:** ripristina l'innesto (placeholder in `QStageRootView`) + cancella i file nuovi.
- **Cond:** B (no-illusion via `active:.qStage`); C (sort view-side = ZERO write su disco; il
  sort vive in `@Published` volatile, non tocca `save()`). A NON si applica (onHome = ritorno
  Home Q-Stage, non il seam Nodo A).
- **DIFFERITO (§8, NON in S3):** «+ create show» (`addSetlist` = WRITE) e reorder drag
  (`moveSetlists`) — CD-Q7: nessun «+», nemmeno morto. NON cablare i path write.

### ⟦NODO A⟧ N0→N1a→N1b · SPINE · CI+DEVICE · 🟢 FATTO (17/07/2026, device-validato Mauro — N0 `a2fb816` / N1a `beb9e08` / N1b `152445e`, CI verdi, gate B+C+A-cheap PASS; shippato E1 [rimozione `.onDisappear`] + E2 [struttura onExit/QLiveRootView]). **Prossimo atomo = ⟦S4⟧.**
- **Scopo:** `Screen.qLive`; `QLiveRootView` (root iniziale LiveView, behavior-preserving) proprietario di **un unico seam `onExit`**; threading ai 2 leaf; flip porta Home.
- **File:** `AppRootView.swift:13` (add `.qLive`) · `QLiveRootView.swift` NUOVO (onExit unico hookpoint; audio-stop su transizione) · `LiveHeaderView.swift:6,:26` (`dismiss()`→`onExit()`) · `WaitingForDirectorView.swift:27,:67` (CANCEL→`onExit()`) · `HomeRootView.swift:77-88` (modale→`screen=.qLive`).
- **Gate:** DEVICE-obbligatorio (tocca audio-live: cambia quando scatta `stop()`, oggi `LiveView:187 .onDisappear`).
- **Cond A:** onExit POSSEDUTO da `QLiveRootView` (hookpoint unico, riusato da S4); N0 non deve bypassare la shell. Transition-safety: onExit ri-puntato da `[weak vc].dismiss` a `{ screen=.home }` a N1b.
- **⚠️ PREREQ (bloccanti PRIMA di N1a/S4):** [1] leggere AudioEngine a source (`@ 6fca624`, per SIMBOLO: `stop()` → `stopSync()`, doppia guardia `guard self.isRunning` e `guard wasRunning` — a HEAD `AudioEngine.swift:1638`/`:1705`; ⚠️ il `:503` della 10/07 è MORTO, oggi è la chiusura di un callback Link IsEnabled, non start/stop); [2] riconciliare onExit col piano `HANDOFF/NODO_A_PIANO_2026-07-10.md @ cd02280` (emendamento E1 incluso: N1b rimuove `LiveView:187 .onDisappear{stop()}`) — se il piano mette onExit fuori dalla shell = collisione con Cond A, aggiornare il piano PRIMA.

### ⟦S4⟧ QLiveShowsView (frame ②) = nuova root QLiveRootView · POST · CI+DEVICE
- **Scopo:** Q-Live apre lista Shows read-only invece di LiveView-diretto; header RoomSwitchBar Q-Live.
- **File:** `UI/QLive/QLiveShowsView.swift` NUOVO (righe read-only; search no-sort; il sort è EREDITATO da Q-Stage in sola lettura — Q15, nessun `.sortbtn` qui, riletto da `QBeatsStore.shared`; MetroFAB coda [S2F, solo piazzato]; pick cosmetico `QLiveTheme.pick`, no stato/modello; `RoomSwitchBar[active:.qLive, onHome:QLiveRootView.onExit (Cond A), onSwitch:→screen=.qStage]`) · `QLiveRootView.swift` EDIT (root→QLiveShowsView) · **`AppRootView.swift` EDIT** (inietta `onSwitchToStage:{ screen=.qStage }`; `screen` private; è `.qStage`, non toggle). ⚠️ La 10/07 diceva `showsPlus:false`: la prop NON esiste (RoomSwitchBar reale = `active`/`onHome`/`variant`/`onSwitch`).
- **Reversibilità:** RISCHIO/accoppiata (revert = del view + root a LiveView + revert edit AppRootView; toglie push-target S5).
- **Gate:** no write; DEVICE per nav + lifecycle audio.
- **Cond:** A (home→seam N0; device verifica TUTTE 3 uscite dopo restructure lista→detail→play), B (switch LIVE, closure distinta da onExit), D (MetroFAB coda, dest a S6).
- **Referee:** switch-closure va in S4 (NON in Nodo A); device gate S4 conferma no-crash su tap-riga nella finestra pre-S5.

### ⟦S4L⟧ Live launcher: iniezione setlist + kill phantom makeDefault · POST · CI+DEVICE
- **Scopo:** parametrizzare l'ingresso live una volta (`SetlistRunner(setlist: chosen)→LiveView`) + uccidere phantom `LiveRootView:8`; launcher unico per S5 Start e S6.
- **File:** `UI/LiveRootView.swift:7-8,:13` EDIT (rimuovi `first ?? makeDefault()` + runner eager; parametrizza setlist scelta).
- **Reversibilità:** RISCHIO (`init` non-opzionale `SetlistRunner:59` → `?? makeDefault()` non è delezione pulita: `first` = `Setlist?` → compile error; revert = reinstallare forma eager).
- **Gate:** no write, ma percorso audio-live + comportamento d'ingresso device-osservabile → non CI-solo.
- **Cond:** D/E (empty-state onesto; free-metronome = Opzione 1). **Coppia stretta con S4** (S4L subito dopo S4).

### ⟦S5⟧ QLiveShowDetailView (frame ③) + Start · POST · CI+DEVICE
- **Scopo:** detail read-only pushato da S4, Start gattato su risolto-non-vuoto; consuma empty-states + launcher.
- **File:** `UI/QLive/QLiveShowDetailView.swift` NUOVO (navbar back + RoomSwitchBar `.segMini[active:.qLive]` INERTE; dhead; songlist idx/tag-rail R1-pending SOLO LAYOUT/nome/met; orfani `resolve().missingIDs` = SKIP + conteggio "N unavailable"; Start disabilitato DS opacity 0.4 se `resolve().songs` vuoto; Start→launcher S4L).
- **Reversibilità:** RISCHIO/accoppiata (pushato da S4; dip S4L). Ordine: dopo S4 e S4L.
- **Gate:** no write; DEVICE per Start audio-live.
- **Cond:** E (tag solo layout; iPad/editor differiti); Start su risolto-non-vuoto (F=`songIDs.isEmpty`; G=`!songIDs.isEmpty && resolve().songs.isEmpty`); A (`.segMini` INERTE).
- **OPEN:** badge `⚠ FILE MISSING` (≠ orfani; = esistenza `Song.backtrackFilename:22`, nessun helper oggi) **DIFFERITO**. Referee: quando si farà, esistenza calcolata FUORI dal render path (cache al load), MAI `FileManager.fileExists` per-riga a scroll-time (jank).

### ⟦S6⟧ METROFAB — cablaggio porta (dest differita stub) · POST · CI
- **Scopo:** legare `onTap` MetroFAB (coda lista + empty E) a stub differito.
- **File:** `UI/QLive/QLiveShowsView.swift` (S4) + `UI/QLive/QLiveEmptyStates.swift` (S2) EDIT: bind onTap → stub.
- **Reversibilità:** pulita (revert 2 bind). Kill makeDefault NON qui (è S4L).
- **Cond:** D (agli atti: destinazione = Opzione 1 sezione sintetica, NON opzione 2 RT). **Referee: tenere SEPARATO** (valore documentale).

---

## C · Ordine (2 corsie)
**PRE:** S0 → {S1, S2F} → S2 → S2b → S2c → S2e → S2d → **S3** (indipendente Nodo A; i sub-atomi S2b/S2c/S2e/S2d = ciclo CD-decisioni + estrazione EmptyStateKit, tutti FATTI). → **SPINE NODO A** (N0→N1a→N1b) gattella POST. → **POST:** S4 → **S4L** (coppia stretta) → S5 → **S6** ultimo.

## D · Risposte referee alle 8 domande
1. "+" create → ⚠️ **SUPERATO da CD-Q7 (LIBRO v31):** «+» OMESSO finché §8 non arriva, NIENTE bottone morto. La 10/07 diceva «bottone presente, azione off»: ora è VIETATO. 2. Badge FILE MISSING → DIFFERIRE (esistenza cache al load, no fileExists a scroll). 3. QLiveTheme = enum separato (file: scelta CC). 4. Switch-closure AppRootView → in S4, non Nodo A. 5. onHome non-defaulted → SÌ (Cond A enforced-by-compiler). 6. S6 separato. 7. S4/S4L coppia stretta; device gate S4 = no-crash tap-riga pre-S5. 8. Cross-ref AudioEngine → confluisce in Prereq 1.
+ **Nuova (referee) — RISOLTA da CD-Q13:** l'empty-state di Q-Stage Shows a 0 setlist NON era un buco: CD-Q13 lo definisce (badge `.eic.dim`, «No shows yet», nessuna CTA, searchrow omessa) → implementato in ⟦S3⟧ punto 5, riusando `EmptyStateKit`. Distinto dai Frame Ⓔ/Ⓕ/Ⓖ di Q-Live (S2).

## E · 2 prerequisiti bloccanti (POST-lane, dominio RT)
- **PREREQ 1:** leggere AudioEngine a source (start/stop/isRunning + aggancio lifecycle) PRIMA di N1a/S4. N0 procede (solo seam onExit, behavior-preserving).
- **PREREQ 2:** riconciliare onExit col piano `HANDOFF/NODO_A_PIANO_2026-07-10.md @ cd02280`; se il piano mette onExit fuori dalla shell, aggiornarlo PRIMA di Nodo A (altrimenti Cond A insoddisfacibile).

## F · Anchor a source — ⚠️ ANCORATO A HEAD STORICO `fa64832` (STALE, ~14 commit fa)
🔴 **I numeri di riga sotto sono a `fa64832` e NON sono più affidabili a HEAD `6fca624`**
(S2b/S2c/S2e/S2d + i doc-commit hanno spostato le righe; `Setlist.swift:3-7` ora include
anche `name`/`date`, non "solo songIDs"; `AudioEngine:503` è morto, vedi Prereq NODO A).
Prima di usare QUALSIASI riferimento qui, RI-VERIFICARE a `@ 6fca624` per SIMBOLO poi riga
(R7). Simboli-chiave già ri-verificati altrove in questo file (⟦S3⟧): `QStageRootView.onExit`
· `Setlist.name/date/songIDs` · `QBeatsStore.setlists`/`estimatedDuration(for:)`/`resolve(_:)→missingIDs`
· `EmptyStateKit.{EmptyStateLayout,EmptyIconBadge,NoShowsIconShape}` · `stopSync()` guardie
`:1638`/`:1705`. Lista storica (da rifare per SIMBOLO, non citare a riga com'è):
`AppRootView.Screen{home,qStage}` · `QStageRootView` · `HomeRootView` presentLive modale ·
`LiveHeaderView`/`WaitingForDirectorView` dismiss · `LiveView` #0e0e10 + `.onDisappear stop` ·
`QStageTheme` (blue/orange/text3) · `QBeatsStore` setlist CRUD (`try? save`)/resolve/estimatedDuration ·
`SongListView.onMove→moveSongs` (write) · `SetlistRunner` init non-opz/guard→fineSetlist ·
`Setlist` · `LiveRootView` runner eager+first??makeDefault · `project.yml` sources folder-glob.
