# PIANO NODO A (step 1 §6) — atomizzato in step REVERSIBILI — per RATIFICA REFEREE
**anchor:** HEAD `e141295` · **R1 verde** (HEAD fermo, a→g validi a source, CI verde, freeze `Q-BEATS Freeze Q-Live Nav (standalone).html` presente/completo) · rifinito dopo review avversariale a fonte

**OBIETTIVO:** assorbire Q-Live in `AppRootView.Screen` (enum) + ritirare la modale UIKit + entry-point unico su `.qLive`, **SENZA cambiare la destinazione** (resta il metronomo; la destinazione→Shows è lo step 2). Nodo A cambia **solo il meccanismo di navigazione**.

## STATO ATTUALE (a fonte, e141295) — corretto post-review
- `AppRootView.swift:13` enum `Screen {home, qStage}`; `:27-33` switch (`.home`→HomeRootView, `.qStage`→QStageRootView con `.environmentObject(audioEngine)` a `:32`).
- `HomeRootView.swift:72` porta Q-Live → `presentLive()`; `:77-88` `presentLive` = `UIHostingController(LiveRootView().environmentObject(audioEngine))` modale `.overFullScreen` su rootViewController; `:79` `triggerDNDReminderIfNeeded()`; `:40` `.onAppear{audioEngine.stop()}`.
- **USCITA Q-Live = SOLO 2 call-site reali di `dismiss()`:** `LiveHeaderView.swift:6/26` (back) + `WaitingForDirectorView.swift:27/67` (CANCEL). ⚠️ `TransportView:46` e `LiveView:154/156` sono **commenti**, non codice. I due leaf sono costruiti **dentro `LiveView`** (`LiveHeaderView` a `LiveView:92`, `WaitingForDirectorView` a `LiveView:160`); `LiveView` oggi **non ha `onExit`**, creato nudo `LiveView()` a `LiveRootView:13`.
- `LiveRootView:7-16` = `@StateObject runner` (dev-fallback `first??makeDefault`) → `LiveView()`. `LiveView:6` `@EnvironmentObject runner` (**crash se assente**); `LiveView:84` `ignoresSafeArea(.all)`; `LiveView:187` `.onDisappear{audioEngine.stop()}`.

## 3 RISCHI D'AVVIO (dal decreto) — dove si esercitano
- **A** (runner-prima-o-crash): **non si esercita STRUTTURALMENTE a N1b** — `LiveRootView:15 .environmentObject(runner)` inietta il `@StateObject runner` (`:7`) in `LiveView`, e `QLiveRootView` renderizza `LiveRootView` (mai `LiveView` diretto) → al flip il runner è già presente, niente crash `@EnvironmentObject`. Il rischio-A vero (LiveView runner-less) è a **step 2** (dove `LiveRootView` è rimpiazzato dall'entry lista-Shows e `LiveView` è a valle della scelta). MA — dato che `LiveView` È live al flip — **check A cheap aggiunto al gate N1b** (entrata `.qLive` a freddo → metronomo, nessun crash).
- **B** (import-sotto-modale): **risolto in N1b** (ritiro modale → sheet import `QBeatsApp:26` su AppRootView, sopra). Test B = **gate N1b** (in N0/N1a la modale c'è ancora → B non risolto prima).
- **C** (audio-stop su transizione): lo stop **canonico** è `AppRootView.onChange(of: screen)` → `audioEngine.stop()` quando lascia `.qLive` (deterministico, punto-di-mutazione, copre ogni uscita incl. step-3 RoomSwitchBar). **NON** delegato a `LiveView:187 .onDisappear` (non-deterministico: può non sparare su view riusata/cachata = «il click a volte non si ferma» = il bug C). `:187` resta ridondanza innocua, non ci si appoggia. Pre-piazzato N1a (inerte), attivo N1b.
  ⚠️ **SUPERATO da E1 (11/07) — vedi EMENDAMENTI POST-RATIFICA in coda.**

---

## ATOMO N0 — SEAM D'USCITA (behavior-preserving, zero cambio-nav) · 5 file
**COSA:** introdurre `onExit: () -> Void` come **parametro fornito dal PRESENTER**, filato per la catena reale:
`LiveRootView(onExit:)` → `LiveView(onExit:)` → `{ LiveHeaderView(onExit:), WaitingForDirectorView(onExit:) }`.
- `LiveView` **acquista** `onExit:()->Void` (stored) e lo inoltra ai due figli a `:92` e `:160`.
- `LiveHeaderView:26` e `WaitingForDirectorView:67`: chiamano `onExit()` invece di `dismiss()`; si rimuove `@Environment(\.dismiss)` (`:6`, `:27`).
- `HomeRootView.presentLive:80`: fornisce `onExit: { [weak vc] in vc?.dismiss(animated: false) }` (il presenter dismissa lo UIHostingController) → **comportamento IDENTICO**. ⚠️ **`[weak vc]` OBBLIGATORIO** (rigore-1): senza, il closure cattura `vc` forte → `vc`→rootView(`LiveRootView`)→closure→`vc` = **retain cycle** → leak dello UIHostingController. Concern **solo-N0** (a N1b non c'è più `vc`; `onExit` diventa `{ screen = .home }` che muta `@State` di AppRootView, nessun ciclo).
- `TransportView` **non si tocca** (`:46` è un commento; l'unica sua futura-uscita è la closure `emerg` vuota `:90-92`, fuori Nodo A).

**PERCHÉ `onExit` da presenter e non `@Environment(\.dismiss)`:** (a) evita il `dismiss` alla radice di uno UIHostingController presentato imperativamente (non contrattualmente garantito); (b) tiene la **firma di `LiveRootView` STABILE** per N1a/N1b (N1a diventa davvero additivo); (c) rende N1b un puro cambio-chiamante.
**PRESERVA:** uscita-a-Bivio, back + CANCEL, DND-call, stop. **ROLLBACK:** ripristina `@Environment(\.dismiss)` nei 2 leaf + togli i param `onExit` (5 file). **INTERMEDIO:** app identica, Q-Live ancora modale, back/CANCEL dismissano. **BENCH:** compila; entra/esce come prima.

## ATOMO N1a — SCAFFOLD + PRE-STAGE DEAD CODE (pura aggiunta, irraggiungibile)
**COSA:** (1) `case .qLive` in `AppRootView.Screen`; (2) `QLiveRootView` (container) montato via il **`switch screen`** (arm condizionale, come `.qStage` a `:30-32`) che renderizza `LiveRootView(onExit: { screen = .home })` — **destinazione = metronomo, invariata**; (3) pre-piazza (inerte) `triggerDNDReminderIfNeeded()` all'ingresso `.qLive` + lo **stop-su-transizione CANONICO** = un `.onChange(of: screen)` in `AppRootView` (fratello di `:39 .onChange(of: scenePhase)`) che chiama `audioEngine.stop()` quando la transizione **lascia** `.qLive` (traccia il valore precedente via `@State private var previousScreen`, perché il target **iOS 16** dà solo il nuovo valore). **Punto-di-mutazione dell'enum, DETERMINISTICO** — NON `.onDisappear` (non-deterministico) né `LiveView:187`. Inerte finché `.qLive` è irraggiungibile (N1a), attivo da N1b, e **copre lo step-3 RoomSwitchBar automaticamente**; (4) plumbing `onOpenQLive` in HomeRootView. **MA la porta resta su `presentLive()`** → tutto il path `.qLive` è **dead code**.
- **INVARIANTI (gate):** `QLiveRootView` renderizza **`LiveRootView`** (non `LiveView` diretto) e resta **in-tree** (mai reintrodurre uno `UIHostingController`): così `audioEngine` è **ereditato da `QBeatsApp:16`** (provato da `HomeRootView` a `AppRootView:29`, che NON re-inietta eppure lo usa) e il `runner @StateObject` (`LiveRootView:7`) è iniettato → niente crash. Montaggio via `switch` (condizionale) = `LiveRootView` **distrutto all'uscita** → **runner fresco ad ogni entrata** (identico al ciclo-vita modale, `SetlistRunner:7`). *(NON un overlay always-on: persisterebbe un runner stale.)*

**PRESERVA:** tutto (dead code). **ROLLBACK:** cancella `.qLive` + `QLiveRootView` + plumbing. **INTERMEDIO:** identico. **BENCH:** compila e gira identico.

## ATOMO N1b — FLIP (esattamente 2 edit accoppiati, il pezzo isolato rischioso)
⚠️ **SUPERATO da E1 (11/07) — vedi EMENDAMENTI POST-RATIFICA in coda.**
**COSA:** (1) porta Q-Live `HomeRootView:72` → `onOpenQLive()` (AppRootView passa `{ screen = .qLive }`), specchio di `onOpenQStage`; (2) **elimina `presentLive()`** (`:77-88`) + la modale + la sua `triggerDNDReminderIfNeeded` (ora pre-piazzata in N1a).
**PRESERVA:** destinazione metronomo, uscita, stop, DND-parità. **INDIRIZZA:** rischio B (modale sparita). **ROLLBACK:** ripristina porta→`presentLive` + `presentLive()` (**~15 righe, 2 file**). **INTERMEDIO:** Q-Live via screen-swap → metronomo; back/CANCEL → `.home`; audio si ferma. **BENCH:** compila. **DEVICE (gate N1b):** **B** (import con Q-Live aperta = sheet visibile, non persa) · **C** (uscita `.qLive→.home` col click attivo → **tace**, via `AppRootView.onChange(of:screen)`) · **A-cheap** (entrata `.qLive` a freddo NON crasha). C-pieno (Home-bypass) = step 3; A-strutturale = step 2.

---

## ORDINE: N0 → N1a → N1b — **forzato dalle dipendenze** (N1a renderizza `LiveRootView(onExit:)`, quindi il seam N0 deve precedere). Nessun ordine alternativo isola meglio il rischio. Ogni atomo compila + gira + si annulla da solo.

## APERTI / FLAG PER IL REFEREE
- ⚠️ **DND: Nodo A è NEUTRO (no-op prima e dopo).** L'`.alert(isPresented: $audioEngine.shouldShowDNDReminder)` è **solo** a `ContentView:85` (path `#if DEBUG`), non antenato di LiveRootView/LiveView → sul Q-Live di produzione `triggerDNDReminderIfNeeded()` (`HomeRootView:79`) setta un `@Published` che **nessuno osserva**. Nodo A sposta/mantiene una call **inerte**, non cambia comportamento. **La domanda vera — FEATURE-PERSA (ricordo DND pre-gig finito solo in DEBUG) o no-op voluto? → mini-TD dedicato, FUORI da Nodo A.** (Aggiornato a verbale della ratifica referee.)
- **Full-screen** come schermo in-tree: benigno — `QStageRootView` rende full-screen nello stesso ZStack, `LiveView:84 ignoresSafeArea(.all)`.
- **Nessun coupling di stato-modale:** niente legge `presentedViewController`/`isPresented`/un coordinator per Q-Live (present fire-and-forget, `HomeRootView:80` unico presenter → verificato).
- `idle-timer`/`scenePhase` (`AppRootView:36-41`, `QBeatsApp:47`) stanno sopra lo swap, non toccati. `fullScreenCover` DEBUG (`HomeRootView:43`) separato.

**INVARIANTI decreto (gate review):** entry-point canonico unico (un solo `.qLive`; ogni ingresso fa `screen=.qLive`) · pick/next cosmetico (non tocca Nodo A) · niente `.onMove` (non tocca Nodo A).

---

## RISPOSTE ALLA RATIFICA CONDIZIONALE (5 punti referee, a fonte)
**BLOCCANTI**
- **C — CONFORME.** Lo stop è al PUNTO-DI-MUTAZIONE dell'enum: `AppRootView.onChange(of: screen)` (fratello del `:39 .onChange(of: scenePhase)`; `audioEngine` a `AppRootView:5`) → `audioEngine.stop()` quando lascia `.qLive`, deterministico. **NON** delegato a `LiveView:187 .onDisappear` (non-deterministico). Traccia `previousScreen` via `@State` (iOS 16 dà solo il nuovo valore). Installato inerte in N1a, attivo N1b, copre step-3 automaticamente.
- **A — RI-CLASSIFICATO, ma NON crasha a N1b.** A fonte: `LiveRootView:15 .environmentObject(runner)` inietta il `@StateObject runner` (`LiveRootView:7`) in `LiveView`. `QLiveRootView` renderizza `LiveRootView` (mai `LiveView` diretto, invariante N1a) → al flip il runner È presente → niente crash. Il rischio-A STRUTTURALE (LiveView runner-less) resta a **step 2** (LiveRootView rimpiazzato dal picker). Concordo però che LiveView è live al flip → **check A-cheap (entrata `.qLive` a freddo non crasha) aggiunto al gate device N1b**.

**RIGORE**
1. **Retain cycle — CONFERMATO + fixato.** `HomeRootView:80 let vc = UIHostingController(...)`. `onExit: { vc.dismiss() }` cattura `vc` forte → ciclo `vc`↔closure → **`[weak vc]` obbligatorio** (già in N0). Solo-N0 (a N1b niente `vc`).
2. **Enum esaustivo — CONFERMATO, resta pura aggiunta.** `AppRootView.Screen` è `private enum` (`:13`) → switchabile SOLO in `AppRootView.swift`; l'UNICO `switch screen` è `:27-33` (grep: nessun altro riferimento a `Screen`/`switch screen`; l'hit `UIScreen` è estraneo). Aggiungere `.qLive` tocca SOLO quel switch (l'arm che N1a aggiunge) → N1a scoped a `AppRootView.swift`.
3. **Sequenza test B — CONFERMATO.** B risolto solo da N1b (ritiro modale); in N0/N1a la modale c'è → test B agganciato a **N1b**, non prima.

**DND** — riformulato: Nodo A **NEUTRO** (no-op prima/dopo). Feature-persa-vs-voluto → **mini-TD dedicato, fuori Nodo A**.

**Zero codice finché il referee non ratifica-pieno questo piano.**

---

## EMENDAMENTI POST-RATIFICA

### E1 (11/07/2026) — N1b RIMUOVE `LiveView.swift:187 .onDisappear{ audioEngine.stop() }`
**Ratificato:** referee + Mauro, 11/07/2026. Emenda l'ATOMO N1b e **supera** la nota «`:187` resta ridondanza innocua, non ci si appoggia» in «3 RISCHI D'AVVIO → C» (sopra) e il conteggio «esattamente 2 edit accoppiati» di N1b.

**Cosa cambia:** in N1b si **rimuove** `LiveView.swift:187 .onDisappear{ audioEngine.stop() }` (verificato a fonte 11/07: `LiveView.swift:187` = `.onDisappear { audioEngine.stop() }`). N1b passa **da 2 a 3 file**: ai 2 edit già previsti (porta Q-Live `HomeRootView:72` → `onOpenQLive()`, con `AppRootView` che passa `{ screen = .qLive }`; `presentLive()` `:77-88` rimosso) si aggiunge la rimozione di `LiveView:187`.

**Motivazione — NON «l'ombra è pericolosa».** La doppia chiamata a `stop()` (nuovo `onChange` + vecchio `.onDisappear`) **È PROVATA SICURA a fonte**: doppia guardia — interna `guard self.isRunning else { return }` `AudioEngine.swift:1638` (dentro `audioQueue.sync`); esterna `guard wasRunning else { return }` `AudioEngine.swift:1705` (fuori dal blocco). Quindi «`:187` è innocua per il motore» è **VERO — ma vero e IRRILEVANTE**. Il problema è il **TEST**: lasciando `:187` in piedi, il **GATE C di N1b** (esci da `.qLive` col click attivo → il metronomo tace) **NON DISCRIMINA** — se tace, non sappiamo se l'ha fermato il **nuovo** `AppRootView.onChange(of: screen)` (il meccanismo che stiamo validando) o il **vecchio** `.onDisappear` (quello che stiamo rimpiazzando). Un test che non separa il meccanismo nuovo dal vecchio **NON PROVA NULLA**. E allo **step 3** (RoomSwitchBar) `.onDisappear` **NON copre** l'uscita → lo stop rotto si scoprirebbe sul palco.

**Copertura (nessun path scoperto):** le uniche 2 uscite reali da Q-Live — `LiveHeaderView` back + `WaitingForDirectorView` CANCEL — passano **ENTRAMBE** da `onExit()` → `screen = .home` → `AppRootView.onChange(of: screen)` → `stop()`. Rimuovere `:187` non lascia scoperta nessuna uscita.

**Fonti (verify-at-source 11/07):** `LiveView.swift:187` · `AudioEngine.swift:1638` · `AudioEngine.swift:1705`.

### E2 (17/07/2026) — struttura onExit/QLiveRootView per N1a (disambigua riga 32)
**Ratificato:** referee 17/07/2026. Specchio esatto di QStageRootView:
- AppRootView, arm switch: `case .qLive: QLiveRootView(onExit: { screen = .home }).environmentObject(audioEngine)`. La closure è costruita QUI — obbligatorio, `Screen` è `private enum` in AppRootView.swift.
- QLiveRootView.swift (separato): possiede il seam `onExit` (hookpoint unico riusato da S4 = Cond A) e lo INOLTRA a LiveRootView; non costruisce mai `{ screen = .home }`.
- **Fonti (verify-at-source 17/07):** AppRootView.swift arm .qStage; QStageRootView.swift.

### ESITO (17/07/2026) — NODO A CHIUSO
N0 `a2fb816` · N1a `beb9e08` · N1b `152445e`, CI verdi. Gate device B+C+A-cheap PASSATO (Mauro, 17/07). Caveat gate C registrato in BOX3 V96: `HomeRootView.swift:43 .onAppear{stop()}` pre-esistente copre le uscite verso Home → il gate C non isola il nuovo handler; il discriminante vero è la prima uscita che non passa dalla Home (RoomSwitchBar, S4).
