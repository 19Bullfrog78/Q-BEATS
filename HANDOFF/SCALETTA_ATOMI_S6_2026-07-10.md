# Q-BEATS — Mini-piano §6 + Scaletta atomi (RATIFICATA)

**Versione:** 12 (22/08/2026)  ·  **Ratificata dal referee:** 13/07/2026 (v1) · **⟦NODO A⟧ CHIUSO device 17/07** (v2) · **sdoppiamento ⟦S4L⟧ in tre atomi 28/07** (v3) · **re-instradamento ⟦S4R⟧ CONFERMATO 30/07** (v4) · **reperto tipi runner nella scheda ⟦S5⟧ 02/08** (v5) · **ordine §6 emendato 31/07 atterrato in sez.C + vincolo ObservableObject in scheda ⟦S5⟧ 02/08** (v6) · **cancello END SHOW in scheda ⟦S5⟧ 02/08** (v7) · **variante `.segMini` ABOLITA dal freeze consolidato 06/08, marcata nella scheda ⟦S5⟧** (v8) · **⟦S5⟧ spezzata in tre in sez.C + ⟦S-EXIT⟧ senza scheda + reperto tipi runner SEPARATO in premessa e domanda aperta + cancello END SHOW al singolare + sez.F marcata stale 07/08** (v9) · **A3 empty-state cancellata + ⟦S5a⟧ chiuso device + destinazione ⟦S6⟧ ribadita, 18/08** (v10) · **scheda ⟦S5b⟧ INCISA in sezione B (13 atomi, titolo marcato) + clausola «zero citazioni nude ≥320» di sez.C marcata SCADUTA, 18/08** (v11) · **⟦S-EXIT⟧ RIFORMULATO E SCOMPOSTO in sei punti (a)-(f) — marcatura additiva in coda a sez.C, ordine 31/07 INVARIATO, 22/08** (v12)
> Prima versione numerata. Prima d'ora la scaletta era identificata solo dalla data nel
> nome-file (`_2026-07-10`), che è più vecchia del contenuto reale (riscrittura S3 del
> 12/07). D'ora in poi la fonte di verità è QUESTO campo Versione, non la data nel nome.

- **Freeze contratto (IN GIT):** contratto vivo `DESIGN/QLive_Nav/2026-07-11_Q7-Q16.html @ 9994bc0` (taglio +Q7-Q16). Riferimenti al freeze per SELETTORE, mai per riga. R7: nessuno sha256 inciso.
- **HEAD repo:** `6fca624` (in-sync origin/master, 12/07). Verifica a source per SIMBOLO poi riga, ancorata `@ 6fca624` — MAI a un commit storico (regola «pushato≠propagato» §7 BOX3 V92, R7 LIBRO v31).
- **⚠️ STATO 12/07 — ⟦S3⟧ RISCRITTO su questa versione** (vedi sotto; la 10/07 prescriveva un «+» morto vietato da CD-Q7). Atomi GIÀ COMMITTATI (CI-verdi, NON device-chiusi): S0 `995a3bf` · S1 `87a8280` · S2F `f91533f` · S2 `ed11f65` · poi il ciclo CD-decisioni NON previsto nella scaletta 10/07: S2b `8d7c7d1` · S2c `9bb4ef6` · S2e `7550476` (allineamento commenti R7 + gate reali) · S2d `ab6b553` (estrazione `EmptyStateKit`). RESTANO: **S3** (prossimo) · NODO A · S4 · S4L · S5 · S6.
- **Stato:** impianto §6 + scaletta RATIFICATI dal referee (impianto 10/07). ⟦S3⟧ è stato RISCRITTO il 12/07 dal contratto ratificato e **RE-RATIFICATO dal referee il 13/07** → S3 può essere guidato da questa scaletta. Ogni atomo passa comunque il cancello (source→diff verbatim→referee→OK Mauro→device dove segnato→commit Mauro/0-CoAuth).
- **Depositato in:** `E:\HOBBY\MUSICA - BATTERIA -SISTA\Q-BEATS\FILE X CLAUDE.MD\HANDOFF\` (untracked, NON repo).
  ⚠️ **MARCATURA v4** — «untracked» era vero alla stesura e NON lo è più: il file è **tracciato** nel
  repo (blob OID presente, `git ls-files --eol` lo rende `i/lf w/lf`). La riga resta come scritta, si
  marca e non si riscrive.
- **⚠️ BUMP v5 TARDIVO — R7 rispettata in ritardo, NON contenuto nuovo.** Il contenuto è cambiato con `07e09260bffa446a3fba1893267c2567aed88616` (voce «OPEN — tipo del runner» aggiunta alla scheda ⟦S5⟧); la versione è bumpata QUI, in un commit successivo e separato. **R7** — registro Sez.6 del LIBRO, voce 31 — prescrive il bump di versione quando il contenuto cambia, e in quel commit non fu fatto: difetto rilevato da CC dopo il push, durante la propagazione R-δ. ⛔ Il commit `07e09260bffa446a3fba1893267c2567aed88616` **NON si riscrive e non si emenda**: è pushato, è storia, il repo è pubblico — R7 si ripara **AGGIUNGENDO**. ⚠️ **v5 non introduce contenuto nuovo:** registra la versione di contenuto già committato. ✅ Difetto **isolato, non di famiglia**: misurato a fonte che ogni commit su `BOX3_QBEATS.md` e `BOX5_QBEATS.md` ha bumpato la propria riga di versione nello stesso commit che ne cambiava il contenuto.

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

## B · Scaletta 12 atomi (erano 10 fino alla v2 — lo sdoppiamento 28/07 ha portato ⟦S4L⟧ da una scheda a tre)
⚠️ **MARCATURA 18/08 — GLI ATOMI DI QUESTA SEZIONE SONO TREDICI, NON DODICI. Il titolo qui sopra resta come scritto: si marca, non si riscrive.** L'aggiunta è **⟦S5b⟧**, incisa in questo stesso giro subito dopo ⟦S5⟧, per ratifica del referee + OK di Mauro del 18/08/2026. Il conteggio «12» era esatto fino a questa riga e va letto come **storia**. ⚠️ Chi ricontasse le intestazioni `###` di sezione B e trovasse 13 **non ha trovato un difetto**: ha trovato questa marcatura.


Legenda: **flip** PRE (Nodo-A-indipendente) / POST (richiede `.qLive`) / SPINE · **gate** CI / CI+DEVICE / DEVICE. I path write `moveSetlists :105-108` e `addSetlist :89-91` restano deliberatamente NON cablati. ⚠️ **La clausola «nessun atomo scrive dati utente» NON vale più per l'intera scaletta**: cade per il solo ⟦S4L⟧ (prima scrittura, vedi la sua scheda) per ratifica `LIBRO_MASTRO_QBEATS.md:306 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`. Per **ogni altro atomo** la clausola resta in vigore — ⟦S4K⟧ e ⟦S4R⟧ compresi.

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
- **Cond:** E; D (slot MetroFAB); A (forward-flag: "Go to Q-Stage"/MetroFAB = uscite → seam N0). ⚠️ Frame-E "onesto" metà qui: kill `makeDefault` sta in **S4R** (era «S4L» prima dello sdoppiamento 28/07) → non marcare E "fatto" dopo S2. Dip: S0 prima.

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

🔴 **SDOPPIAMENTO 28/07 — la scheda ⟦S4L⟧ della v2 è diventata TRE schede.** Motivo: sotto un
solo nome convivevano due contratti opposti — «no write» (v2, questa scheda) e «prima scrittura sui
dati utente» (`LIBRO_MASTRO_QBEATS.md:306 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`). In più
`BOX3_QBEATS.md:34 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` chiede di incidere un vincolo tecnico
«nella scheda ⟦S4L⟧», che riguarda il solo launcher. Decisione Mauro, ratificata referee 28/07.
⚠️ **RATIFICA NON ANCORA ATTERRATA IN LIBRO — pendenza aperta.** Misurato: «S4K» e «S4R» rendono
**0 righe** in `LIBRO_MASTRO_QBEATS.md @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`, in
`BOX3_QBEATS.md @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` e in `BOX5_QBEATS.md` allo stesso commit
(controllo positivo stessa forma: «Mauro» = 160 righe in LIBRO). Per il TEST DI RATIFICA di R-γ
(`LIBRO_MASTRO_QBEATS.md:295 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`) — «è in LIBRO_MASTRO → è
ratificato; altrimenti no» — finché una riga di LIBRO Sez.2 non incide sdoppiamento e ordine,
questa dichiarazione è un'auto-affermazione del documento che ne beneficia. Da incidere: precedente
«ratifica non atterrata = ratifica inesistente».
**Il nome ⟦S4L⟧ resta, ma d'ora in poi indica SOLO la prima scrittura** (terza scheda qui sotto).
**REGOLA DI RILETTURA — si applica per OGGETTO, non per parola.** Ogni citazione di «S4L» anteriore
al 28/07 va riletta come ⟦S4R⟧ se il suo oggetto è il **launcher, il runner, il suo ciclo di vita o
la sua proprietà, l'ingresso live, `LiveRootView`/`SetlistRunner`, il phantom `makeDefault`**, oppure
un'**enumerazione d'ordine** degli atomi §6 (dove «S4L» va espanso in «S4K → S4R → S4L»). Resta
⟦S4L⟧ solo ciò che parla di **Remove / menu «···» / scrittura sui dati utente**. ⚠️ Agganciare la
rilettura a due soli lemmi («launcher», «makeDefault») NON basta e sarebbe peggio dell'ambiguità:
i casi dirimenti non contengono né l'una né l'altra parola — vedi le due decisioni trasportate nella
scheda ⟦S4R⟧ e le sei enumerazioni d'ordine di BOX3 (`r.60`, `:151`, `:212`, `:647`, `:662`, `:676`
@ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3), tutte a 0 occorrenze di entrambi i lemmi.
**ORDINE OBBLIGATORIO: ⟦S4K⟧ → ⟦S4R⟧ → ⟦S4L⟧.**

### ⟦S4K⟧ Congedo tastiera (contratto Q20) · POST · CI+DEVICE
- **Scopo:** costruire il contratto Q20 come inciso in `BOX5_QBEATS.md:366 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`
  (capitolo «Q-Live › Shows», § «Congedo tastiera»): «Done» su toolbar accessoria pinnata, sempre
  visibile, ≥ 44pt, arancio = accento Q-Live; in aggiunta e non al posto, tap fuori e swipe giù
  interattivo; Return = «Search» conferma **e** congeda; il congedo conserva query, filtro, scroll e
  selezione; a svuotare è solo la «×»; MetroFAB occluso e ripristinato senza animazione dedicata;
  iPad hardware/floating coperti. ⛔ Vietato affidare il congedo all'uscita dalla stanza.
  La spec vive in BOX5, non qui: questa scheda **non la duplica**, la indirizza.
- **File:** il campo ricerca vive nella vista creata da ⟦S4⟧ (`UI/QLive/QLiveShowsView.swift`, vedi
  scheda ⟦S4⟧). ⚠️ Righe da ri-verificare per SIMBOLO a HEAD al momento della costruzione (R7):
  a oggi la vista non contiene alcun congedo — misura M1 del 28/07, `FocusState`/`focused`/`.toolbar`/
  `dismissKeyboard`/`resignFirstResponder` = **0 righe su 19 file** di `UI/QLive/` + `UI/Live/`,
  controllo positivo `import SwiftUI` = 19/19 (referto `HANDOFF/MISURE_M1_IDENTITA-S4L_2026-07-28.txt`,
  sha256(disco) `d74b4164…b878dcd6` — file untracked, esiste solo su disco: la faccia è quella e va detta).
- **Reversibilità:** pulita (il congedo è additivo: si rimuove la toolbar accessoria e i modificatori
  di dismiss, la lista resta quella di ⟦S4⟧).
- **Gate:** **NESSUNA scrittura su dati utente** (la clausola di legenda vale piena qui) e **nessun
  tocco al runner**. NON tocca `LiveRootView.swift` né `SetlistRunner`. DEVICE obbligatorio: la
  ratifica stessa lo impone — `LIBRO_MASTRO_QBEATS.md:312 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`
  «Finché il congedo non è nell'app e provato su device…» (verbatim, senza enfasi aggiunta); e i
  punti iPad hardware/floating e
  MetroFAB-occluso non sono determinabili in CI.
- **Cond:** ⚠️ **Vincolo di deployment senza margine, già inciso e già declassato:**
  `scrollDismissesKeyboard(.interactively)` — il minimo del progetto è iOS 16.0 **[V]**
  (`ios_app/project.yml:14 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`), ma la disponibilità dell'API a
  partire da iOS 16.0 è **[R]**, fonte non acquisita (BOX5 V28, PENDENZE DEL CAPITOLO punto 9).
  «Done» e «×» non dipendono da quella API: se la pendenza si chiudesse male, cade il solo
  swipe-giù, non il contratto.

### ⟦S4R⟧ Live launcher: iniezione setlist + kill phantom makeDefault · POST · CI+DEVICE
- **Scopo:** parametrizzare l'ingresso live una volta (`SetlistRunner(setlist: chosen)→LiveView`) + uccidere phantom `LiveRootView:8`; launcher unico per S5 Start e S6.
- **File:** `UI/LiveRootView.swift:7-8,:13` EDIT (rimuovi `first ?? makeDefault()` + runner eager; parametrizza setlist scelta).
  ⚠️ **Ancora viva, ri-misurata il 28/07** (M1, referto `HANDOFF/MISURE_M1_IDENTITA-S4L_2026-07-28.txt`,
  sha256(disco) `d74b4164…b878dcd6`, misurato all'albero `4b55686c04e3bd14ccf06c31b5e89e74a38341ab`;
  riverificata a `0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`):
  `ios_app/QBeats/UI/LiveRootView.swift:13 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` contiene ancora
  `QBeatsStore.shared.setlists.first ?? Setlist.makeDefault()`, e
  `ios_app/QBeats/SetlistRunner.swift:59 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` ha init **non-opzionale**
  `init(setlist: Setlist, store: QBeatsStore)`. ⚠️ **Due path da non sbagliare:** `LiveRootView.swift`
  sta in `UI/` **diretto** (non in `UI/Live/`), e `SetlistRunner.swift` **non sta sotto `UI/` affatto**.
  Entrambi i puntatori portano il commit per R-β (`LIBRO_MASTRO_QBEATS.md:295 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`):
  nessun numero di riga senza ancoraggio.
- **🔴 VINCOLO TECNICO — verbatim da `BOX3_QBEATS.md:34 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`:**
  «Un `ObservableObject` ANNIDATO dentro un altro NON propaga: `QLiveSession.@Published runner`
  notifica solo APPARIZIONE/SCOMPARSA del runner, NON i suoi cambi interni (canzone/sezione/BPM).
  I figli devono osservare **IL RUNNER** (`@ObservedObject`/`@EnvironmentObject` sul runner), NON la
  sessione — pena UI metronomo CONGELATA che sembrerebbe un bug del DSP.»
- **EMENDAMENTO INVARIANTE NODO A** (stessa fonte, `BOX3_QBEATS.md:34 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`):
  l'invariante «renderizza LiveRootView, MAI LiveView diretto» conserva lo **scopo** — mai LiveView
  senza runner iniettato, garantito dal gate `if let runner` — ma ne cambia la **lettera**, perché il
  runner nasce ora dal launcher e non più dal phantom.
- **🔴 PROPRIETÀ DEL RUNNER — decisione Mauro 18/07, ratificata, trasportata qui dallo sdoppiamento.**
  Verbatim da `BOX3_QBEATS.md:30 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`: «la proprietà del runner
  SALE — il runner sopravvive alla navigazione interna e muore SOLO all'uscita da Q-Live. Atterra in
  **S4L**, NON in S4.» Motivo, stessa fonte: oggi `SetlistRunner` è `@StateObject` in
  `ios_app/QBeats/UI/LiveRootView.swift:12-13 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`
  — puntatore di BOX3, riverificato a quell'albero — → muore al pop, mentre `audioEngine` sopravvive; al rientro nascerebbe un
  runner FRESCO (canzone 1) col click già avanti = **UI e clock divergenti sul palco**.
  ⚠️ **Il «S4L» di quella riga è PRE-sdoppiamento e ha per oggetto il runner: ricade quindi su ⟦S4R⟧**
  per la regola di rilettura qui sopra. Il re-instradamento è **CONFERMATO**: lo sdoppiamento è inciso
  in `LIBRO_MASTRO_QBEATS.md:317` (Sez.2, riga `2026-07-28`), che assegna la proprietà del runner a
  ⟦S4R⟧ e ratifica la regola di rilettura.
- **COMMENTI-STALE da bonificare** (`BOX3_QBEATS.md:45 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`): la lista
  «da bonificare in S4L» tocca `SetlistRunner.swift`, `AudioEngine.swift`, `LiveView.swift`,
  `HomeRootView`, `LivePlaybackState.swift`, `TransportView.swift` — zona launcher/live, quindi anche
  questa ricade su ⟦S4R⟧ per oggetto. Solo commenti, zero impatto funzionale; «bonifica in UN giro
  quando si tocca quella zona». Stesso re-instradamento, **CONFERMATO** dalla stessa fonte (`LIBRO:317`).
- **Reversibilità:** RISCHIO (`init` non-opzionale `ios_app/QBeats/SetlistRunner.swift:59 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`
  → `?? makeDefault()` non è delezione pulita: `first` = `Setlist?` → compile error; revert =
  reinstallare forma eager).
- **Gate:** no write, ma percorso audio-live + comportamento d'ingresso device-osservabile → non CI-solo.
- **Cond:** D/E (empty-state onesto; free-metronome = Opzione 1).
- **Modello raccomandato alla costruzione:** Opus 4.8 · effort `xhigh` (tocca launcher/AppRootView e
  il percorso audio-live). ⚠️ **Raccomandazione CC, NON una regola ratificata:** «Opus 4» rende
  **0 righe** in LIBRO v42, BOX3 V99 e BOX5 V28 (misurato), quindi per R-γ non è ratificata. Il nome
  di un modello invecchia: si rilegge come «il tier più capace disponibile», non come questa stringa.
- **⚠️ PENDENZA — «coppia stretta con S4» va ri-tarata.** La v2 prescriveva «S4L subito dopo S4»
  (risposta referee 7 del 10/07, §D) perché finché il phantom vive l'empty-state E è disonesto.
  L'ordine ratificato il 28/07 mette però ⟦S4K⟧ **fra** S4 e S4R, quindi la coppia non è più
  contigua e la finestra di disonestà di E si allunga di un atomo. Nessuna fonte scioglie il punto:
  **si registra, non si decide qui.**

### ⟦S4L⟧ Prima scrittura: «Remove from Q-Live» + menu «···» · POST · CI+DEVICE
- **Scopo:** costruire «Remove from Q-Live» e il menu «···» come incisi in
  `BOX5_QBEATS.md:381 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3` (§ «Menu «···» e «Remove from
  Q-Live»»): entrambe le vie sulla riga — menu «···» a **una sola voce** più **swipe trailing rosso**
  — percorso al danno a due gesti intenzionali, voce disabilitata (visibile, non nascosta) con
  sessione armata o in play, popup di conferma nella forma ②. La spec vive in BOX5: questa scheda
  **non la duplica**, la indirizza.
- **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE SCRIVE DATI UTENTE.** Per ratifica
  `LIBRO_MASTRO_QBEATS.md:306 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`: «La prima scrittura sui dati
  utente entra con ⟦S4L⟧ ed è **limitata allo stato di appartenenza dello show a Q-Live**; ogni
  altra scrittura resta vietata in §6.» La scrittura è **solo** quello stato: `moveSetlists` e
  `addSetlist` restano NON cablati, e nessuna cancellazione vive in Q-Live
  (`LIBRO_MASTRO_QBEATS.md:307 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`). DEVICE obbligatorio: due
  affordance da provare invece di una, e il conflitto fra swipe trailing e gesti di navigazione
  **non è determinabile a fonte** (`LIBRO_MASTRO_QBEATS.md:308 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`).
- **Dipendenze (entrambe dure):** ⟦S4R⟧ — serve il runner iniettato; ⟦S4K⟧ — il congedo tastiera
  dev'essere già costruito e provato, perché questo atomo porta l'utente a operare sulla riga **con la
  ricerca in uso**: `LIBRO_MASTRO_QBEATS.md:312 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` — «Finché il
  congedo non è nell'app e provato su device, a ⟦S4L⟧ l'utente resta con la tastiera alzata e l'unica
  uscita spegne la sessione del metronomo — sul palco.»
  ⛔ **NON si scriva che il popup di conferma collide con la tastiera: i canonici dicono l'opposto.**
  `LIBRO_MASTRO_QBEATS.md:311 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` — «Nessuna collisione col
  congedo-tastiera Q20: lo stesso file marca ② «identico a ①»» — e `BOX5_QBEATS.md:390 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`
  — «Nessuna collisione col congedo tastiera.» La dipendenza regge sulla riga 312, non su una
  collisione che non esiste.
- **File:** la riga e il menu vivono nella vista di ⟦S4⟧ (`UI/QLive/QLiveShowsView.swift`).
  ⚠️ **Il file del campo di persistenza NON si dichiara qui:** la forma tecnica del campo è scelta
  CC ancora aperta (BOX5 V28, QL-SHOWS-01 e PENDENZE DEL CAPITOLO punto 5). Si fissa alla
  costruzione, non a naso adesso.
- **Reversibilità:** ⚠️ **NON pulita come gli altri atomi §6** — è il solo che tocca i dati
  dell'utente: un revert del codice non ripristina da sé gli stati di appartenenza già scritti sul
  device. Nessuna fonte prescrive una procedura di rollback dei dati: **pendenza da sciogliere prima
  della costruzione**, non qui.
- **⚠️ PENDENZA — lo stato «sessione armata» non esiste a HEAD**
  (`LIBRO_MASTRO_QBEATS.md:303 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199`): l'unica occorrenza di `armed`
  è `backtrackArmed`, flag interno al buffer del backtrack, senza rapporto con l'armamento di uno
  show. Lo stato nasce con l'arma + standby: per la lettera della fonte «la dipendenza è soddisfatta
  per costruzione, ma va scritta perché non si perda **se il blocco venisse spezzato**»; l'ancora di
  codice che LIBRO porta è `AudioEngine.swift:370`.
- **⚠️ IL «BLOCCO UNICO» — definizione e indirizzo, perché questo atomo lo eredita.** È `QL-SHOWS-06`
  di `BOX5_QBEATS.md:328 @ 0a6ebafa72dfc8a4ebed6dd5474a99161955d7e3`, ratificato in
  `LIBRO_MASTRO_QBEATS.md:302 @ 8926c2af482dce5f4fa0e0dd36d2ba36eb90c199` (POSTILLA 2): **cinque pezzi,
  un blocco solo** — pillola ▶ · «···» a una sola voce · swipe trailing rosso · popup di conferma ·
  campo di persistenza; «non si separano, e Remove non si stacca dalla pillola».
- **⚠️ PENDENZA — la pillola ▶ non ha atomo assegnato in questa scaletta.** Delle cinque parti del
  blocco unico, questa scheda copre menu, swipe e popup; il campo di persistenza è rimandato (sopra);
  la **pillola ▶ non compare in NESSUNA delle dodici schede** (misurato: «pillola» = 0 righe, `▶` = 0
  righe nell'intero file). Il canonico la dichiara inseparabile da Remove, quindi o entra qui o il
  «blocco unico» è già spezzato dalla scaletta stessa. **Nessuna fonte assegna la pillola a un atomo:
  si registra, non si decide qui.**

### ⟦S5⟧ QLiveShowDetailView (frame ③) + Start · POST · CI+DEVICE
- **Scopo:** detail read-only pushato da S4, Start gattato su risolto-non-vuoto; consuma empty-states + launcher.
- **File:** `UI/QLive/QLiveShowDetailView.swift` NUOVO (navbar back + RoomSwitchBar `.segMini[active:.qLive]` INERTE; dhead; songlist idx/tag-rail R1-pending SOLO LAYOUT/nome/met; orfani `resolve().missingIDs` = SKIP + conteggio "N unavailable"; Start disabilitato DS opacity 0.4 se `resolve().songs` vuoto; Start→launcher **S4R**).
- ⚠️ **SUPERATO — 06/08/2026: la variante `.segMini` NON ESISTE PIÙ.** Le righe di questa scheda che la prescrivono — il **File:** qui sopra e il **Cond:** più sotto («A (`.segMini` INERTE)») — **non si riscrivono** e restano leggibili come sono: si marcano. Il freeze consolidato CD del 06/08 **abolisce** la variante `.seg-mini` (un solo room switch in tutta l'app) e sostituisce `.navbar .seg-mini .o` 9px/30pt con **`.roomseg .opt` 10,5px/34pt**; nello stesso atto `.dhead .nm` passa **23px → 29px** con max 2 righe poi troncamento. ⇒ Chi implementa ⟦S5⟧ cabla contro l'**ARTEFATTO NORMATIVO**, non contro questa riga: `DESIGN/QLive_Nav/2026-08-06_QLive-Shows_FREEZE-CONSOLIDATO_390x844__rev3-NORMATIVA.html`, blob `430c9894c2539c4753f8ab0b8c3baf64d73f5335` — ancorato in `LIBRO_MASTRO_QBEATS.md` Sez.2, riga `2026-08-06` «ARTEFATTO NORMATIVO — Q-LIVE › SHOWS». ⚠️ **L'area tattile resta 50pt**: cambia il chrome visibile, non il bersaglio. ⛔ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (341→342 righe totali). Verificato a fonte prima di scriverlo: la citazione **nuda** a `:300` in `ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift:14` punta alla riga sopra, che **non si sposta**; l'unica citazione a riga ≥301 è `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` (`LIBRO:329`), **ancorata a commit e quindi immune**. Stessa forma di dichiarazione del bullet `⟦S5⟧ CANCELLO` più sotto. ⚠️ **PERIMETRO DI QUESTA MARCATURA, dichiarato:** il termine compare in **cinque** punti del file — `:28` (mappa dei frame), `:50` (scheda ⟦S1⟧, le props del componente), `:113` (gate device ⟦S3⟧, «sblocca `.seg-mini` a S5»), più i due di questa scheda. **Questa marcatura copre SOLO i due di ⟦S5⟧**: marcare da qui le schede altrui sarebbe fuori forma. Gli altri tre **restano non marcati e lo si registra** — materia di un giro doc a sé, non di questo.
- **Reversibilità:** RISCHIO/accoppiata (pushato da S4; dip **S4R** — il launcher). Ordine: dopo S4 e dopo ⟦S4R⟧. ⚠️ Il nome «S4L» che questa riga portava prima del 28/07 indicava il launcher, oggi ⟦S4R⟧: S5 dipende dal launcher, **non** dalla prima scrittura.
- **Gate:** no write; DEVICE per Start audio-live.
- **Cond:** E (tag solo layout; iPad/editor differiti); Start su risolto-non-vuoto (F=`songIDs.isEmpty`; G=`!songIDs.isEmpty && resolve().songs.isEmpty`); A (`.segMini` INERTE).
- **OPEN:** badge `⚠ FILE MISSING` (≠ orfani; = esistenza `Song.backtrackFilename:22`, nessun helper oggi) **DIFFERITO**. Referee: quando si farà, esistenza calcolata FUORI dal render path (cache al load), MAI `FileManager.fileExists` per-riga a scroll-time (jank).
- **OPEN — tipo del runner:** `SetlistRunner.startSetlist(audioEngine:session:)` (`ios_app/QBeats/SetlistRunner.swift`) si aspetta un `LiveSession` (`ios_app/QBeats/Models/LiveSession.swift`), tipo DIVERSO da `QLiveSession` (`ios_app/QBeats/UI/QLive/QLiveSession.swift`) — il contenitore-stanza che ⟦S4R⟧ ha introdotto per possedere lo slot del runner. **⟦S5⟧ deve riconciliare i due tipi: non è cablaggio, è architettura.** Reperto CC (`HANDOFF/MISURE_CC_2026-08-02_P3-S5-RICOGNIZIONE.txt` punto 2), nessuna soluzione decisa qui — il reperto rende visibile la materia, non la scioglie.
- ⚠️ **MARCATURA 07/08 — IL BULLET SOPRA SI SEPARA IN DUE, E LA SUA PRIMA METÀ È CONFERMATA A FONTE. La riga resta come scritta: si marca, non si riscrive.** **PREMESSA — REGGE, rimisurata al blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`:** `SetlistRunner.startSetlist(audioEngine:session:)` (`ios_app/QBeats/SetlistRunner.swift:109 @ 779172e6353d6e51dcee542953725000f48dd05a`) si aspetta davvero un `LiveSession`, ed è davvero un tipo diverso da `QLiveSession`. Su questo il bullet sopra è esatto e non si tocca. **Ciò che la misura AGGIUNGE, e che il bullet non poteva sapere:** `LiveSession` (`ios_app/QBeats/Models/LiveSession.swift @ 779172e6353d6e51dcee542953725000f48dd05a`) porta **16** proprietà `@Published`, zero metodi, zero init, ed è istanziata in **UN SOLO punto di tutto il corpus** — `ios_app/QBeats/UI/Live/LiveView.swift:11 @ 779172e6353d6e51dcee542953725000f48dd05a`, `@StateObject private var session = LiveSession()`: **creata dal player, `private`, non iniettabile e non leggibile da fuori**. `QLiveSession` (`ios_app/QBeats/UI/QLive/QLiveSession.swift @ 779172e6353d6e51dcee542953725000f48dd05a`) porta **un solo campo**, `:35` `@Published private(set) var runner: SetlistRunner? = nil`, zero metodi, zero init; `extension QLiveSession` rende **0** su tutti i `.swift` tracciati (controllo positivo, stessa forma: `extension ` rende 11). Misure del referto `HANDOFF/MISURE_CC_2026-08-07_A78-RICOGNIZIONE-PERCORSO-DI-AVVIO.txt`, dove i quattro file sono stati letti PER INTERO. ⛔ **QUESTA RIGA E LA SEGUENTE SPOSTANO DI DUE RIGHE tutto ciò che le segue** (342→344 righe totali). Verificato a fonte prima di scriverle, con la stessa forma usata dalla marcatura del 06/08: le citazioni **nude** a questo file con riga ≥307 sono **ZERO** su tutti e cinque i canonici più i commenti `.swift`; le uniche citazioni ≥307 sono `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` (due volte, in `LIBRO:329` e in questo stesso file) e `SCALETTA_ATOMI_S6_2026-07-10.md:322 @ 2960f089225b3c80cf56cb839fde871cf9738b3d` (in `BUGS_QBEATS.md`), **tutte ancorate a commit e quindi immuni**.
- ⚠️ **MARCATURA 07/08 — LA SECONDA METÀ DEL BULLET SOPRA È DEGRADATA A DOMANDA APERTA, E NON È NECESSARIA OGGI. Zero parole riscritte.** La frase «**⟦S5⟧ deve riconciliare i due tipi: non è cablaggio, è architettura**» **non è mai stata sorgentata**: il referto che il bullet cita copre la PREMESSA, e il bullet stesso lo ammette due frasi dopo («il reperto rende visibile la materia, non la scioglie»). ⇒ Si legge come **DOMANDA APERTA**, non come prescrizione. **E la misura di oggi dice che oggi non serve:** i due tipi **non si incontrano mai** — `QLiveSession` non nomina `LiveSession` in nessuna delle sue 36 righe; lo Start (⟦S5b⟧) **non può** chiamare `startSetlist`, perché la `LiveSession` che quella firma pretende non esiste ancora quando lo Start viene premuto e nasce `private` dentro `LiveView` solo al montaggio del player; lo Start può soltanto **far nascere il runner** e metterlo nello slot, e l'avvio parte più tardi da dentro `LiveView` (START LOCAL, `ios_app/QBeats/UI/Live/LiveView.swift:190 @ 779172e6353d6e51dcee542953725000f48dd05a`, una delle tre sole chiamate reali di `startSetlist` in tutto il corpus). ⚠️ **RISERVA DI CC, incisa insieme e non soppressa:** è misurato che **oggi** una riconciliazione non serve; **non** è misurato che non possa servire domani — se si volesse che la sessione di display SOPRAVVIVA alla navigazione interna della stanza, servirebbe davvero, e sarebbe una decisione di disegno che nessuno ha preso. ⚠️ **Perimetro della misura, dichiarato:** la fonte citata dal bullet sopra (`HANDOFF/MISURE_CC_2026-08-02_P3-S5-RICOGNIZIONE.txt`) **NON è stata riletta**; questo verdetto poggia sul codice a HEAD, non su un giudizio di quel referto.
- **VINCOLO TECNICO — vedi, nella scheda ⟦S4R⟧ di questo stesso file, il bullet «🔴 VINCOLO TECNICO — verbatim da `BOX3_QBEATS.md:34`»** (INDIRIZZO-NON-COPIA, per SIMBOLO — nessun numero di riga: il bersaglio è nello stesso file che questo diff modifica, un'ancora di commit qui non è possibile): un `ObservableObject` annidato non propaga; i figli devono osservare IL RUNNER, non la sessione — pena UI metronomo congelata. Testo verbatim, motivazione e ancora di commit già incisi lì, non ripetuti qui. ⚠️ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (339→340 righe totali). Verificato a fonte su tutti e cinque i canonici più i commenti `.swift`: l'unica citazione a questo file con numero di riga ≥306 è `LIBRO_MASTRO_QBEATS.md:329`, che cita `SCALETTA_ATOMI_S6_2026-07-10.md:314 @ e61efd0e9bc2f9174b755e5a25e02a611c795cea` — **ancorata**, quindi immune (indirizzo di contenuto a un commit storico, non a HEAD). Nessun'altra citazione nuda sopra quella soglia trovata.
- **CANCELLO — ⟦S5⟧ non chiude device finché i due bottoni di `FineSetlistView` non fanno qualcosa.** BACK TO SHOWS: quanto `LIBRO_MASTRO_QBEATS.md:154 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` dichiara attivo («torna alla libreria SHOWS»). RESTART SETLIST: quanto `LIBRO_MASTRO_QBEATS.md:153 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` propone (CD-3, «ricomincia la setlist appena suonata») — oggi **proposto**, non ratificato: per questo bottone resta aperta anche la domanda «cosa deve fare», non solo il cablaggio. ⚠️ **Deviazione dal testo dettato in prompt, dichiarata:** una prima forma equiparava i due bottoni come se entrambi avessero ratifica attiva — verificato a fonte che `LIBRO_MASTRO_QBEATS.md:155 @ c1556e57b1a81fafa7973b8647741ede9c92e6cf` **non copre l'azione di RESTART SETLIST**; corretto qui prima di scrivere. ⛔ **Che cosa quella riga dichiari, qui NON si qualifica:** vive per INDIRIZZO nel bullet «Contrasto con la ratifica» del ticket `TD-fineshow-bottoni-morti` in `BUGS_QBEATS.md`, dove è riportata in verbatim intero e misurata contro il codice. ⚠️ **SECONDA DEVIAZIONE, dichiarata (giro A25):** il prompt indicava `@ eeb725dd46363d6cdc428a5aa43ede5881389d31` per l'ancora di `:155`; Fase 1-bis dello stesso giro ha verificato che quell'ancora è falsificata anche per `:153` e `:154` (a quei commit il file si chiamava ancora `STATO_QBEATS.md`, per rename confermato con `git log --follow`, e la tabella era ancora `_(da popolare CD)_`) — sostituite tutte e tre le ancore con HEAD, non solo quella nuova. ⚠️ **RETTIFICA A26 (C6), dichiarata:** in A25 la qualifica «`:155` ratifica il titolo/momento «END SHOW»» era stata lasciata scritta com'era, per mandato ristretto di C4. È stata **rimossa qui**: con l'ancora ora corretta a HEAD quella glossa sarebbe stata un'affermazione falsa accanto a un indirizzo verificabile — chi lo apre legge il contrario. Resta il solo punto vero, che `:155` non copre l'azione di RESTART SETLIST; ciò che quella riga dice davvero vive per indirizzo in `BUGS_QBEATS.md`. **Motivo del cancello:** ⟦S5⟧ è ciò che rende raggiungibile END SHOW (`BUGS_QBEATS.md:132 @ 0ee9543d45d638df061c5a48872aaefeb8a88f26` — «⟦S5⟧ apre entrambe le serrature nello stesso atomo»). ⛔ **QUESTO BULLET SPOSTA DI UNA RIGA tutto ciò che lo segue** (340→341 righe totali). Verificato a fonte, stessa forma della verifica sopra: nessuna citazione nuda a questo file con riga ≥307 trovata su cinque canonici più commenti `.swift`; l'unica citazione ≥307 resta la stessa di sopra (`LIBRO:329`→`:314`, ancorata, immune).
- ⚠️ **MARCATURA 07/08 — LA CONDIZIONE DEL CANCELLO VA LETTA AL SINGOLARE, E NON È DICHIARATA SODDISFATTA. Il bullet sopra resta come scritto.** RESTART SETLIST **si toglie** da END SHOW: opzione Ⓐ di CD, ratificata in `LIBRO_MASTRO_QBEATS.md:353 @ 81740e48f24e089703b0199d0ffd20b9b3bfae7c` (proposta e disegno di CD; ratifica tecnica del referee e OK di Mauro, due cancelli distinti passati entrambi). ⇒ La condizione «i **DUE** pulsanti di `FineSetlistView` devono fare qualcosa» si legge da qui in avanti **AL SINGOLARE**: resta **un** pulsante, BACK TO SHOWS, ed è **cablato** — `ios_app/QBeats/UI/Live/FineSetlistView.swift:29 @ 779172e6353d6e51dcee542953725000f48dd05a`, `Button("BACK TO SHOWS") { onBackToShows() }`, atomo ⟦S5x⟧, commit `4e4c24113b21fed53b55c2a6d38a1903e52ecd1f`. ⛔ **QUESTO NON RENDE IL CANCELLO SODDISFATTO, e la distinzione è il punto:** il pulsante è **chiuso a codice** ma la sua validazione su device è **DIFFERITA**, perché END SHOW oggi è irraggiungibile — nessuno l'ha mai visto funzionare. Il cancello si chiude quando quel tocco è stato fatto su un device, non quando la closure smette di essere vuota. ⚠️ Rilievo di **CD**, accolto: era CD a chiedere che la condizione fosse riscritta al singolare e **non** dichiarata soddisfatta. ⛔ **QUESTA RIGA SPOSTA DI UNA RIGA tutto ciò che la segue** (344→345 righe totali). Verifica a fonte identica a quella delle due righe sopra: zero citazioni **nude** a questo file con riga ≥309; le uniche in quella regione sono ancorate a commit, quindi immuni.

### ⟦S5b⟧ Start del dettaglio → player col primo brano ARMATO · POST · CI+DEVICE

- **Scopo:** costruire **una porta sola** — dallo `.startfoot` del dettaglio al player, col primo
  brano **armato in standby**. ⛔ **Finisce lì: cosa accade dopo il tocco dell'utente non è di
  questo atomo.** Contratto: `BOX5_QBEATS.md:331` (QL-SHOWS-07 — «l'ingresso in uno show è
  SEMPRE arma + standby, qualunque sia il flag standby della prima canzone») e
  `BOX5_QBEATS.md:354` (§3 — «Start = arma + standby sulla prima canzone. Il click parte al
  **secondo** tap (schermo ovunque) o via MIDI»).

- **File — QUATTRO:**
  - `UI/QLive/QLiveSession.swift` **EDIT** — il **mutatore dello slot**; è il file stesso ad
    assegnarlo a questo atomo (`:14-15`).
  - `UI/QLive/QLiveShowDetailView.swift` **EDIT** — costruire il runner (`setlist` a `:78`,
    `store` a `:81`; `SetlistRunner.init(setlist:store:)` non chiede altro,
    `SetlistRunner.swift:61`) e **chiudere il tocco** — `Cond (d)`.
  - `UI/QLive/QLiveRootView.swift` **EDIT** — closure `() -> Void` iniettata al dettaglio nella
    forma di `onBack` (`:104`): riempie lo slot, **poi** naviga. La closure non può essere
    tipizzata sulla pagina: `QLivePage` è `private` (`:44`), `navigate(to:)` è `private` (`:88`).
  - `SetlistRunner.swift` **EDIT** — accendere lo standby d'ingresso dentro `primeDisplay`
    (`:271`), che ha **un solo chiamante** in tutto il corpus, già dentro l'`onAppear` del player
    (`LiveView.swift:231`). ⛔ **Così `LiveView.swift` NON si tocca** e `LiveSession` resta privata.

- **Reversibilità: PULITA.** `store.resolve(_:)` è puro (`QBeatsStore.swift:152-164`), l'`init`
  del runner legge e logga, il mutatore assegna un `@Published` in RAM, `navigate` assegna uno
  `@State`. **Zero disco, zero `UserDefaults`, zero iCloud, nessun cambio di formato dati** ⇒ un
  revert dei quattro file non lascia nulla sul device. Dipendenza dura: ⟦S4R⟧. Ordine: dopo
  ⟦S5a⟧ e ⟦S5x⟧.

- **🔴 Gate — UNICO ATOMO DELLA SCALETTA CHE CHIUDE TRE CANCELLI DEVICE IN UN COLPO SOLO.**
  Non è enfasi: è il motivo per cui non si può collaudare a metà.
  - **il proprio** — lo Start arma e il player si monta fermo;
  - **quello DIFFERITO di ⟦S5x⟧** — «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧»
    (`SCALETTA:324`): END SHOW è irraggiungibile finché lo slot non ha mutatori;
  - **l'armamento di `TD-mixer-copre-endshow`** — «SI ARMA CON ⟦S5b⟧, NON PRIMA» (`BUGS:158`).
  - **CI:** verde su `iOS Signed Build`. ⚠️ `F1 — Build Check` non gira dal 31/07 e le ultime due
    run sono fallite: **non conta come cancello finché Mauro non decide**.
  - **Passo (1) — e distingue «armato» da «fermo»:** da un dettaglio con brani risolti, tocca
    **START SHOW**. ✅ Deve comparire il **titolo della PRIMA canzone**, grande e centrato in
    alto, **che pulsa lentamente**, sopra il player **visibilmente oscurato**; **non deve suonare
    nulla**. ⛔ Se la videata è piena e nitida, o il titolo manca, o c'è ma **immobile**:
    **FALLITO** — il player è fermo, non armato.
    *(Segni misurati, verificabili a occhio senza alcun disegno CD: `LiveView.swift:129`
    opacità **0,10** sul player · `StandbyOverlayView.swift:18-24` titolo **52 pt** al **27 %**
    dell'altezza · `:31-35` pulse **0,45↔1,0 in 2,2 s**, all'infinito.)*
  - **Passo (2):** tocca lo schermo **in un punto qualsiasi** → il click parte **da quella
    canzone** (`LiveView.swift:134-137`, `.contentShape(Rectangle())` + `onTapGesture` →
    `runner.startCurrentSong`).
  - **Passo (3):** fine setlist → END SHOW → **BACK TO SHOWS** torna alla lista (gate di ⟦S5x⟧).
  - **Passo (4):** esci dalla stanza → l'audio si ferma (`AppRootView.swift:74`).
  - ⛔ **NON-DIFETTI — da NON segnalare come guasti:** al tocco la musica parte **subito, senza
    conto**. `startCountIn` è uno **stub** (`AudioEngine.swift:1561-1563`) e fra le canzoni il
    rinvio è **dichiarato nel codice** (`SetlistRunner.swift:232`). ⇒ È una porta già mancante,
    **non una regressione di ⟦S5b⟧**.
  - ⚠️ Col percorso DEBUG vale la procedura sicura di
    `TD-injecttestdata-sovrascrive-dati-reali` (`BUGS:143`): **non toccare NESSUNA Song** mentre i
    dati di test sono in RAM.

- **Cond — cinque, tutte necessarie:**
  - **(a) ORDINE OBBLIGATO: riempi lo slot, POI naviga.** Invertendo si apre un frame con
    `page == .metronome` e `runner == nil`, e il ramo `else` **si vede**. L'irraggiungibilità di
    quel ramo è **conseguenza di questa condizione**, non un fatto indipendente.
  - **(b) STATO D'INGRESSO = arma + standby sulla PRIMA canzone**, non `.stopped`.
    ⚠️ Il payload esiste già e regge, **misurato**: `nextSongName` è calcolato **dopo**
    `currentSongIdx += 1` (`SetlistRunner.swift:343-345`), quindi significa «la canzone che
    partirà al prossimo tap» — all'ingresso, con indice 0, **è la prima**. E l'obiezione storica
    non si applica: `LiveSession.swift:30-34` tolse lo standby d'ingresso il 17/05 (TD #28)
    perché mostrava un **em-dash**, cioè uno standby **senza nome vero**; con un runner armato il
    nome c'è.
  - **(c) GUARDIA SUL RI-ARMAMENTO.** `primeDisplay` gira a **ogni** `onAppear`, non solo al
    primo. Senza guardia si potrebbe rimettere in standby uno show **già in esecuzione** a una
    ricomparsa della vista. ⚠️ **È qui che lo stato armato guadagna il suo posto:** distinguere
    «armato e mai partito» da «già partito».
  - **(d) IL TOCCO SI CHIUDE quando `resolve().songs` è VUOTO.** Oggi `isEnabled`
    (`QLiveShowDetailView.swift:288`) pilota **solo** ombra (`:323`), bordo (`:326-331`) e
    opacità (`:333`): `.disabled(` nel file rende **0**, mentre il corpus lo usa in **6 file**.
    Senza questa condizione un tocco su una scaletta orfana costruisce un runner a catalogo vuoto,
    `primeDisplay` esce al primo `guard` (`SetlistRunner.swift:272`) e **il player si monta bianco**.
  - **(e) NIENTE STOP AUDIO AGGANCIATO ALLA NAVIGAZIONE MENTRE IL CLICK GIRA**
    (`QLiveRootView.swift:78-85`, decisione CD 18/07). ✅ Non vieta l'azzeramento di **stato** a
    END SHOW, dove il playback è già finito (`LiveView.swift:161`): **igiene, non transport**.

- **Modello raccomandato alla costruzione:** Opus — quattro file e due regole (`Cond (a)` ordine,
  `Cond (c)` guardia) che il compilatore non può verificare.

- **OPEN — fuori da questa porta, nominati perché il cancello non erediti un vuoto:**
  - **`QL-SHOWS-08` — stato prodotto IDENTICO.** `BOX5:333`: la **pillola ▶** della lista e lo
    Start del dettaglio devono produrre **la stessa cosa** — «stessa azione, modalità di default,
    nessuna domanda». ⇒ ⟦S5b⟧ costruisce **un** ingresso; il secondo dovrà **riusarlo**, non
    replicarlo. ⚠️ E `BOX5:362` tiene la pillola **gated** («tratteggiata, icona spenta,
    inerte») finché l'avvio non è cablato: ⟦S5b⟧ è ciò che **permette** di togliere quel gate,
    **ma toglierlo non è in questa porta**.
  - **Lo stato «sessione armata»** (`BOX5:324`, `BOX5:404`) lo **produce** questo atomo — «nasce
    insieme all'arma + standby» — e il suo **consumatore** è ⟦S4L⟧ (QL-SHOWS-04, Remove
    inerte a sessione armata). La **forma tecnica** è scelta CC, per simmetria con `BOX5:401`.
  - **Il count-in NON entra.** Ratificato con **tre** punti d'attivazione (`LIBRO:166`) e
    **nessuno dei tre è costruito**. ⛔ Non c'è nulla da spezzare: c'è una funzione da scrivere,
    che è altro. Ticket proposto in B2.
  - **⟦S6F⟧ e ⟦S-EXIT⟧ non hanno scheda**, entrambi ratificati (`SCALETTA:325` registra il
    secondo buco).
  - **Il ramo `else` resta `EmptyView()`**, guardia difensiva, **nessun lavoro CD** — precedente
    identico nello stesso `switch` (`QLiveRootView.swift:105-107`). ⚠️ Il commento a `:162-169`
    chiede ancora un empty-state a ⟦S5⟧: superato dalla cancellazione dell'A3 (`LIBRO:355`),
    **va marcato, non riscritto**.

### ⟦S6⟧ METROFAB — cablaggio porta (dest differita stub) · POST · CI
- **Scopo:** legare `onTap` MetroFAB (coda lista + empty E) a stub differito.
- **File:** `UI/QLive/QLiveShowsView.swift` (S4) + `UI/QLive/QLiveEmptyStates.swift` (S2) EDIT: bind onTap → stub.
- **Reversibilità:** pulita (revert 2 bind). Kill makeDefault NON qui (è **S4R**).
- **Cond:** D (agli atti: destinazione = Opzione 1 sezione sintetica, NON opzione 2 RT). **Referee: tenere SEPARATO** (valore documentale).
- ⚠️ **MARCATURA 18/08 — LA DESTINAZIONE DI ⟦S6⟧ È IL METRONOMO LIBERO, NON L'EMPTY-STATE «No show running». Il bullet «Cond: D» sopra resta come scritto: si marca, non si riscrive.** Ratificato in `LIBRO_MASTRO_QBEATS.md`, righe datate `2026-08-18` (due vie d'ingresso · A3 cancellata). ⛔ Chi cabla `onTap` **non** porta all'empty-state A3 del file CD del 02/08: quel file è **cancellato**, non ha più occasione di comparire (modello a cinque punti di Mauro, 18/08) — portarci il pulsante METRONOME sarebbe comunque **una porta che dà su un muro**. ⇒ La destinazione resta quella già agli atti nel bullet sopra — **Opzione 1**, sezione sintetica «free», riuso della catena invariata; **Opzione 2** (`mode: .freeMetronome` nel cuore RT) resta **VIETATA**. ⚠️ **Il meccanismo per cui la destinazione non esiste ancora era GIÀ INCISO in questo stesso file dal 10/07, a `:32`** («setlist vuota → `guard currentSection nil` → `.fineSetlist` immediato (NON un metronomo)»), e **rimisurato a HEAD il 18/08**: `ios_app/QBeats/SetlistRunner.swift:142` (`guard let section = currentSection else {`, col commento «Stato degenerato: setlist vuota … Trattato come fineSetlist immediato») e `:148` (`session.playbackState = .fineSetlist`) `@ 321293e18094d9d4f1c167bfc921be1ad216e3ac`. ⇒ Il fatto **regge invariato**; ciò che mancava non era la misura ma la sua **sede leggibile da CD**, ora in LIBRO.

---

## C · Ordine (2 corsie)
**PRE:** S0 → {S1, S2F} → S2 → S2b → S2c → S2e → S2d → **S3** (indipendente Nodo A; i sub-atomi S2b/S2c/S2e/S2d = ciclo CD-decisioni + estrazione EmptyStateKit, tutti FATTI). → **SPINE NODO A** (N0→N1a→N1b) gattella POST. → **POST — ordine ratificato 31/07:** S4 → **S4K** → **S4R** → **S5** → **⟦S-EXIT⟧** → **S4L** → **S6** ultimo. ⚠️ I tre atomi S4K/S4R/S4L sostituiscono l'unico «S4L» della v2 (sdoppiamento 28/07) e il loro ordine reciproco resta **obbligatorio**: S4K → S4R → S4L. Sulla «coppia stretta» che la v2 prescriveva fra S4 e il launcher, vedi la pendenza nella scheda ⟦S4R⟧. ⛔ **⟦S4L⟧ è SOSPESO** fino a chiusura di tre pendenze (atomo della pillola ▶ · forma tecnica del campo di persistenza · procedura di rollback dati), e **⟦S-EXIT⟧ precede ⟦S4L⟧**, per condizione fisica e non per disciplina dell'operatore — `LIBRO_MASTRO_QBEATS.md:329 @ c00feb43361d01d961fd1e97cf4c1a77a5bf7c7e`. **QUESTA RIGA È LA SEDE UNICA DELL'ORDINE DEGLI ATOMI §6: ogni altra catena d'ordine in un canonico è storia — si legge, non si riscrive.**
⚠️ **MARCATURA 07/08 — ⟦S5⟧ SI È SPEZZATA IN TRE, E LA RIGA D'ORDINE SOPRA NON LO SA. La riga resta come scritta: si marca, non si riscrive.** Misurato sul blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`: `S5a`, `S5b`, `S5x` rendono **ZERO** occorrenze in tutto questo file — in **entrambe le casse**, minuscola e maiuscola — con controllo positivo `S5` = **24** sullo stesso blob; e il commit di ⟦S5a⟧, `25056b66`, rende **ZERO** su tutti e cinque i canonici, con controllo positivo `4e4c2411` = **5** in `LIBRO_MASTRO_QBEATS.md`. La sede unica dell'ordine non registra né i due atomi già consegnati né quello che resta. Si legga così: **(1) ⟦S5a⟧ — `QLiveShowDetailView`, frame ③ read-only. CONSEGNATA su master, commit `25056b66eda40ad76d91a886ace442b7064ca900` (05/08), CI verde. ⛔ NON validata su device.** ⚠️ **È RAGGIUNGIBILE OGGI** e il suo gate device **non dipende da ⟦S5b⟧**: percorso misurato Home → Q-LIVE → pagina `.shows` (che è il default, `ios_app/QBeats/UI/QLive/QLiveRootView.swift:46 @ 779172e6353d6e51dcee542953725000f48dd05a`) → tap-riga → ramo `.detail` (`:103-104`, senza alcun gate). **(2) ⟦S5x⟧ — cablaggio di BACK TO SHOWS in `FineSetlistView`. CONSEGNATO su master, commit `4e4c24113b21fed53b55c2a6d38a1903e52ecd1f` (06/08), CI verde.** ⛔ **Formula esatta, e non se ne usi un'altra: «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧».** Non «chiuso»: END SHOW è irraggiungibile perché lo slot del runner non ha mutatori, quindi nessuno ha mai visto quel bottone funzionare — ed è **impossibilità**, non indisciplina dell'operatore. **(3) ⟦S5b⟧ — cablaggio dello Start. È IL FRONTE.** UN solo bottone: lo Start diviso vive solo sulla card della lista, il `.startfoot` del dettaglio resta invariato (freeze consolidato del 06/08). **ORDINE RECIPROCO: ⟦S5a⟧ → ⟦S5x⟧ → ⟦S5b⟧, poi ⟦S-EXIT⟧ come già ratificato dalla riga sopra.** ⛔ **QUESTA RIGA E LA SEGUENTE SPOSTANO DI DUE RIGHE tutto ciò che le segue** (345→347 righe totali). Verificato a fonte: zero citazioni **nude** a questo file con riga ≥320; l'unica in quella regione è `SCALETTA_ATOMI_S6_2026-07-10.md:322 @ 2960f089225b3c80cf56cb839fde871cf9738b3d`, in `BUGS_QBEATS.md`, **ancorata a commit e quindi immune**.
⚠️ **MARCATURA 18/08 — LA CLAUSOLA «ZERO CITAZIONI NUDE CON RIGA ≥320» DELLA RIGA QUI SOPRA È SCADUTA. La riga resta come scritta: si marca, non si riscrive.** Era **VERA al suo commit** — misurato: al blob `779172e6353d6e51dcee542953725000f48dd05a` le citazioni **nude** a questo file con riga ≥320 erano **0**. È **FALSA a HEAD** `44fea3e378414c300ffd50fcac527c683740735b`: ne esiste **1**, in `LIBRO_MASTRO_QBEATS.md:356`, introdotta **dopo** quella misura dalla riga datata `2026-08-18` sui pulsanti visibili e inerti. ⛔ **Chi si fidasse della clausola per concludere «inserire in sezione B è sicuro» sbaglierebbe.** ✅ Quella citazione è stata **ancorata a commit** nello stesso giro (A122), e da allora è immune allo spostamento. ⚠️ **La clausola non è una proprietà permanente del corpus: è una misura, e le misure scadono.** Chi inserisce righe in questo file la **rimisura**, non la rilegge.
⚠️ **MARCATURA 07/08 — ⟦S-EXIT⟧ È NELL'ORDINE RATIFICATO MA NON HA SCHEDA. Buco registrato, NON colmato in questo giro.** Misurato sul blob a HEAD `779172e6353d6e51dcee542953725000f48dd05a`: `S-EXIT` rende **2** occorrenze in tutto il file, ed **entrambe stanno sulla riga d'ordine qui sopra** — cioè in Sezione C. La **Sezione B**, che si intitola «Scaletta 12 atomi», contiene esattamente **12** intestazioni `###`, contate una per una: ⟦S0⟧ · ⟦S1⟧ · ⟦S2F⟧ · ⟦S2⟧ · ⟦S3⟧ · ⟦NODO A⟧ · ⟦S4⟧ · ⟦S4K⟧ · ⟦S4R⟧ · ⟦S4L⟧ · ⟦S5⟧ · ⟦S6⟧. **Nessuna è ⟦S-EXIT⟧.** ⇒ L'atomo su cui poggia il vincolo duro «niente data con la band» esiste in casa come **sola freccia in una riga d'ordine**: nessuno scopo, nessun file, nessuna reversibilità, nessun gate scritti da nessuna parte. ⛔ **La scheda NON si scrive qui:** scriverla sarebbe progettare un atomo dentro un giro di igiene documentale, ed è materia di un mandato suo. Si registra che manca, e da questo momento chi legge l'ordine sa che una delle sue tappe non ha contenuto.
- ✅ **MARCATURA 18/08 — ⟦S5a⟧ CHIUSO DEVICE, supera il punto (1) della marcatura 07/08 sopra. La marcatura 07/08 resta come scritta: si marca, non si riscrive.** Collaudo Mauro 18/08 su `Test Setlist L1.b`: apertura dettaglio, dati, ritorno a SHOWS, nessun dato stantio — tutti verdi, ancora dietro porta DEBUG (§8 assente). Dettaglio in `LIBRO_MASTRO_QBEATS.md`, riga `2026-08-18` (⟦S5a⟧ chiuso device). ⛔ **⟦S5x⟧ resta invariato: «CHIUSO A CODICE, validazione device DIFFERITA a ⟦S5b⟧»** — il collaudo del 18/08 non lo tocca, END SHOW resta irraggiungibile. **ORDINE RECIPROCO INVARIATO:** ⟦S5a⟧ (ora chiuso) → ⟦S5x⟧ → ⟦S5b⟧, poi ⟦S-EXIT⟧.
⚠️ MARCATURA 22/08 — ⟦S-EXIT⟧ RIFORMULATO E SCOMPOSTO, ratificato Mauro
22/08/2026. Le righe sopra restano come scritte: si marca, non si riscrive.
⛔ L'ORDINE RATIFICATO 31/07 È INVARIATO: ⟦S-EXIT⟧ → ⟦S4L⟧ → ⟦S6⟧.
Questa marcatura scompone SOLO ⟦S-EXIT⟧ e non tocca ciò che viene dopo.
⚠️ Resta aperto il buco registrato il 07/08: ⟦S-EXIT⟧ NON HA SCHEDA in
Sezione B (come ⟦S6F⟧). Il punto (c) qui sotto è ciò che lo colma.

⟦S-EXIT⟧ non è più «cablare l'uscita». È: LO STATO DELLO SHOW DEVE
APPARTENERE ALLO SHOW, NON ALLA SCHERMATA. Motivo misurato 22/08 (A172,
A173): uscendo dal player senza STOP l'OROLOGIO MOTORE AUDIO prosegue e
l'OROLOGIO GRAFICA riparte, con scarto crescente a ogni rientro.

Scomposizione ratificata:
(a) MISURA PRIMA DI TUTTO — che cosa può smontare la schermata del player
    oltre al «<»: telefonata, blocco schermo, recupero memoria di iOS.
    È la domanda che DECIDE se (b) serve: se solo il «<» la smonta, fermare
    l'audio all'uscita è soluzione completa e il resto è sovraingegneria.
(b) quanto pesa spostare lo stato dello show dalla schermata alla stanza.
(c) SCHEDA ⟦S-EXIT⟧, scritta dal referee sul peso misurato — colma il buco
    del 07/08.
(d) decisioni di Mauro sul rientro in uno show che sta suonando.
(e) contratto CD: la schermata di rientro nel player NON è coperta da nessun
    disegno — il contratto del 18/07 esclude il player (misurato).
(f) CODICE + ATOMO DI STRUMENTAZIONE NELLO STESSO COMMIT, chat propria
    (tocca lo stop audio), gate su device.
⚠️ La strumentazione non è un atomo suo: stesso file della riparazione,
passiva, ed è il modo con cui la riparazione si verifica sul device.

TAGLI DI CHAT ratificati: dopo il commit documenti 22/08 · dopo (e) · dopo (f).

LAVORI NON-ATOMI che corrono a fianco, nell'ordine ratificato da Mauro:
1) TD-direttore-parte-da-bar2 — dopo (f) si legge ciò che la strumentazione
   ha catturato. Causa NON ATTRIBUITA, nessuna pista alternativa.
2) resto dell'igiene documenti: registro mandati, congedi fuori da git,
   arretrati, riscrittura piena di BOX3.
3) freeze grafico — corpus normativo STRATIFICATO su più revisioni; la
   sede che dichiara cosa è normativo su cosa è DESIGN/QLive_Nav/README.md,
   da leggere a fonte + decisioni di Mauro ancora aperte sul disegno:
   elenco NON fissato da nessun canonico, da verificare a fonte in
   DESIGN/QLive_Nav/README.md prima di aprire il punto.
⛔ Non sono atomi della scaletta e non entrano nella riga d'ordine.

## D · Risposte referee alle 8 domande
1. "+" create → ⚠️ **SUPERATO da CD-Q7 (LIBRO v31):** «+» OMESSO finché §8 non arriva, NIENTE bottone morto. La 10/07 diceva «bottone presente, azione off»: ora è VIETATO. 2. Badge FILE MISSING → DIFFERIRE (esistenza cache al load, no fileExists a scroll). 3. QLiveTheme = enum separato (file: scelta CC). 4. Switch-closure AppRootView → in S4, non Nodo A. 5. onHome non-defaulted → SÌ (Cond A enforced-by-compiler). 6. S6 separato. 7. S4/S4L coppia stretta; device gate S4 = no-crash tap-riga pre-S5. ⚠️ **PARZIALMENTE SUPERATA dallo sdoppiamento 28/07:** il device gate S4 resta invariato; «S4L» qui indicava il **launcher**, oggi ⟦S4R⟧, e fra i due si è inserito ⟦S4K⟧ — la contiguità non è più garantita (pendenza nella scheda ⟦S4R⟧). 8. Cross-ref AudioEngine → confluisce in Prereq 1.
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
⚠️ **MARCATURA 07/08 — IL MARCATORE DI OBSOLESCENZA DI QUESTA SEZIONE È A SUA VOLTA OBSOLETO. Le righe sopra restano come scritte: si marca, non si riscrive.** L'intestazione a `:329` ancora i numeri di riga a HEAD storico `fa64832`, e la riga `:330` li dichiara «non più affidabili a HEAD `6fca624`». ⇒ **Il termine di paragone è a sua volta scaduto:** `6fca624` non è HEAD da molto prima di oggi — a questo giro HEAD è `779172e6353d6e51dcee542953725000f48dd05a` (e nella sola giornata del 07/08 sono passati `f0a4462bd90742367f438f3dec60b1ca2366b2c4`, `2960f089225b3c80cf56cb839fde871cf9738b3d`, `81740e48f24e089703b0199d0ffd20b9b3bfae7c` e quello corrente). La prescrizione di `:333` — «RI-VERIFICARE a `@ 6fca624` per SIMBOLO poi riga» — va quindi letta come **«ri-verificare a HEAD CORRENTE, per SIMBOLO poi riga»**: il metodo regge, il commit di riferimento no. ⛔ **I riferimenti di questa sezione NON sono stati ricostruiti in questo giro**, e nessuno di essi è stato usato per alcuna misura di A85: ricostruirli è un lavoro a sé, non un sottoprodotto di una marcatura. Chi ne avesse bisogno li rifaccia per SIMBOLO, come `:333` già impone, ancorandoli a un commit a 40 e non al numero nudo. ⚠️ Questa riga è **in coda al file**: non sposta alcuna riga esistente (347→348 righe totali, e il 348 è questa stessa riga).
