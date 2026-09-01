# MISURE CC — A105, SI PUÒ COLLAUDARE ⟦S5b⟧ IN SICUREZZA?

Da: CC · A: Mauro + referee · 18/08/2026
Perimetro rispettato: **zero righe sotto `ios_app/`, zero commit, zero push, HEAD invariato.**
Scrittura: due referti in `HANDOFF/` (questo e il verbale retroattivo di A104) + R-δ.

Marcatura: **[M]** misurato ora, da me · **[R]** riportato, non rimisurato · **[A]** giudizio mio.

**[M]** HEAD = `44fea3e378414c300ffd50fcac527c683740735b`. Tutto estratto con `git show <sha>:<path>`,
**mai dal disco**. Aggancio, forma a token su due supporti: `\bA104\b` → **0/0**, `\bA105\b` →
**0/0**; controllo positivo `\bA103\b` → **1/1**.

---

# B1 · SI PUÒ COPIARE FUORI IL CATALOGO PRIMA DI COLLAUDARE?

## 1 · I tre file del catalogo — percorso esatto, dal codice che li scrive

**[M]** I nomi e la cartella si leggono in `save()`, `ios_app/QBeats/Store/QBeatsStore.swift:65-77`:

```text
65	    func save() async throws {
66	        let songsSnapshot = songs
67	        let setlistsSnapshot = setlists
68	        let backtracksSnapshot = backtracks
69	        try await Task.detached(priority: .utility) { [songsSnapshot, setlistsSnapshot, backtracksSnapshot] in
70	            let base = QBeatsStore.resolveBaseURL()
71	            try QBeatsStore.ensureDirectory(base)
72	            try QBeatsStore.coordinatedWrite(songsSnapshot, to: base.appendingPathComponent("songs.json"))
73	            try QBeatsStore.coordinatedWrite(setlistsSnapshot, to: base.appendingPathComponent("setlists.json"))
74	            try QBeatsStore.coordinatedWrite(backtracksSnapshot, to: base.appendingPathComponent("backtracks.json"))
75	        }.value
76	        logger.info("save — songs: \(self.songs.count), setlists: \(self.setlists.count), backtracks: \(self.backtracks.count)")
77	    }
```


**[M]** E la cartella la decide `resolveBaseURL()`, `ios_app/QBeats/Store/QBeatsStore.swift:207-213`:

```text
204	
205	    // MARK: - Private
206	
207	    nonisolated private static func resolveBaseURL() -> URL {
208	        if let container = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerID) {
209	            return container.appendingPathComponent("Documents", isDirectory: true)
210	        }
211	        logger.warning("iCloud container unavailable — using local Documents")
212	        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
213	    }
```


⛔ **QUI C'È UN BIVIO, ed è già risolto — ma non nel file che sembrerebbe.** La prima riga tenta
il **container iCloud** `iCloud.com.bullfrog.qbeats` (`ios_app/QBeats/Store/QBeatsStore.swift:5`). Se ci riuscisse, i tre file
starebbero in iCloud Drive e non nella sandbox. **Non ci riesce**, e la prova sta negli
entitlements — `ios_app/project.yml:79-89`:

```text
79	    entitlements:
80	      path: QBeats/QBeats.entitlements
81	      properties:
82	        # iCloud entitlements rimosse temporaneamente per sbloccare TD #44:
83	        # exportArchive falliva perché QBeats_Dev_Profile su Apple Developer
84	        # Portal non ha la capability iCloud abilitata. Q-BEATS ha fallback
85	        # automatico a Documents locale in QBeatsStore.swift:130-134, quindi
86	        # l'app funziona senza iCloud (solo sync cross-device disabilitato).
87	        # Ri-aggiungere quando la capability iCloud sarà abilitata nel profile.
88	        com.apple.developer.networking.multicast: true
89	        get-task-allow: true
```


⚠️ **Lo dichiara il commento stesso**: «iCloud entitlements rimosse temporaneamente per sbloccare
TD #44 … Q-BEATS ha fallback automatico a Documents locale». Senza l'entitlement,
`url(forUbiquityContainerIdentifier:)` rende `nil` e si prende il ramo `.documentDirectory`.

⇒ **[M] I TRE FILE, percorso esatto:**

```text
<container dell'app>/Documents/songs.json
<container dell'app>/Documents/setlists.json
<container dell'app>/Documents/backtracks.json
```

cioè la **Documents della sandbox dell'app**, sul telefono. Non iCloud, non una cartella condivisa.

⚠️ **[M] Un difetto minore trovato passando:** il commento a `ios_app/project.yml:85` indirizza il fallback a
«`QBeatsStore.swift:130-134`», ma a HEAD quel fallback vive a **`:207-213`**. Puntatore stale,
registrato e non corretto (perimetro di sola lettura sul codice).

## 2 · Le due chiavi — assenti, e assenti nel posto che conta

**[M]** `UIFileSharingEnabled` → **ZERO occorrenze in tutto il repo**.
**[M]** `LSSupportsOpeningDocumentsInPlace` → **ZERO occorrenze in tutto il repo**.
Ricerca su **tutti** i file tracciati a HEAD, senza filtro di percorso.

**[M] Controlli positivi, forma identica sugli stessi file:**

| controllo | esito |
|---|---|
| altre chiavi `UI*` in `Info.plist` + `project.yml` | **9** — `UIAppFonts`, `UIBackgroundModes`, `UIColorName`, `UIInterfaceOrientationPortrait`, `UILaunchScreen`, `UIRequiredDeviceCapabilities`, `UIRequiresFullScreen`, `UISupportedInterfaceOrientations`, `UIUserInterfaceStyle` |
| altre chiavi `LS*` negli stessi file | **2** — `LSHandlerRank`, `LSItemContentTypes` |
| chiave nota presente, `CFBundleVersion` | trovata (`Info.plist:10`) |

⇒ La forma di ricerca funziona: trova nove `UI*` e due `LS*`. **Le due chiave cercate non ci sono.**

⛔ **E VANNO CERCATE NEL POSTO GIUSTO, altrimenti la misura non vale.** `ios_app/QBeats/Info.plist`
**non è il file che spedisce**: XcodeGen lo **rigenera** da `ios_app/project.yml`. Non lo deduco — è già inciso in
`LIBRO_MASTRO_QBEATS.md:322`, caso (b): il file fisico dice `CFBundleVersion` **142**, il prodotto
reale porta **`'1'`**, «prova per **contro-esempio** che XcodeGen SOVRASCRIVE». ⇒ La fonte
autorevole è `ios_app/project.yml`, blocco `info.properties`, `:15-66`:

```text
15	    info:
16	      path: QBeats/Info.plist
17	      properties:
18	        # DARK-DECL (device 29/07/2026): senza questa chiave gli elementi di sistema
19	        # (tastiera, pannello Ableton Link) seguono lo stile del device, non l'app —
20	        # tutta cablata scura. Apple, UIUserInterfaceStyle, iOS 13.0+: "Dark" forza lo
21	        # stile scuro ignorando l'impostazione di sistema.
22	        UIUserInterfaceStyle: Dark
23	        NSLocalNetworkUsageDescription: "Q-BEATS uses the local network to connect to Network MIDI sessions on other devices."
24	        ABLLinkStartStopSyncSupported: true
25	        ABLLinkPeerName: "Q-BEATS"
26	        NSBluetoothAlwaysUsageDescription: "Q-BEATS richiede l'accesso al Bluetooth per connettere controller e tastiere MIDI Bluetooth LE."
27	        NSBluetoothPeripheralUsageDescription: "Q-BEATS richiede l'accesso al Bluetooth per connettere controller e tastiere MIDI Bluetooth LE."
28	        NSBonjourServices:
29	          - "_apple-midi._tcp."
30	          - "_link-peers._tcp"
31	        UIBackgroundModes:
32	          - audio
33	        UILaunchScreen:
34	          UIColorName: ""
35	        # Portrait-only su tutti (LIBRO v24) + iPad sempre full-screen: disabilita
36	        # Slide Over/Split View, che altrimenti forzano il supporto a TUTTE le orientazioni.
37	        UISupportedInterfaceOrientations:
38	          - UIInterfaceOrientationPortrait
39	        UISupportedInterfaceOrientations~ipad:
40	          - UIInterfaceOrientationPortrait
41	        UIRequiresFullScreen: true
42	        UIAppFonts:
43	          - JetBrainsMono-Regular.ttf
44	          - JetBrainsMono-Medium.ttf
45	          - JetBrainsMono-SemiBold.ttf
46	          - JetBrainsMono-Bold.ttf
47	          - Inter-Regular.ttf
48	          - Inter-Medium.ttf
49	          - Inter-SemiBold.ttf
50	          - Inter-Bold.ttf
51	          - Inter-ExtraBold.ttf
52	          - Inter-Black.ttf
53	        CFBundleDocumentTypes:
54	          - CFBundleTypeName: Q-BEATS Backup
55	            CFBundleTypeRole: Editor
56	            LSHandlerRank: Owner
57	            LSItemContentTypes:
58	              - com.bullfrog.qbeats.backup
59	        UTExportedTypeDeclarations:
60	          - UTTypeIdentifier: com.bullfrog.qbeats.backup
61	            UTTypeDescription: Q-BEATS Backup
62	            UTTypeConformsTo:
63	              - public.zip-archive
64	            UTTypeTagSpecification:
65	              public.filename-extension:
66	                - qbeats
```


**[M]** In quel blocco: **nessuna** delle due chiavi. Ci sono invece `CFBundleDocumentTypes` e
`UTExportedTypeDeclarations` — e servono al punto B3.

⇒ **[M] CONSEGUENZA:** l'app **non espone** la sua `Documents` né all'app **File** di iOS né alla
condivisione file di iTunes/Finder. Da quelle due strade i tre `.json` **non sono raggiungibili**.

## 3 · Verdetto su iMazing

⛔ **NON DETERMINABILE A FONTE. Non lo indovino.**

**[M] Quello che il repo determina:**

- le due chiavi di condivisione file sono **assenti** ⇒ File.app e iTunes/Finder **non** vedono quei file;
- l'app è firmata in sviluppo: `get-task-allow: true` (`ios_app/project.yml:89`);
- l'export **in-app** esiste ma è **codice morto** — vedi B3.

**[A] Quello che il repo NON determina, e nessuna lettura del codice può determinare:** se iMazing
riesca a leggere il **container** di un'app di terze parti quando `UIFileSharingEnabled` è assente.
Quella è una proprietà dei **servizi di lockdown di iOS** e del programma iMazing, **non di questo
codice**. ⛔ Non la deduco da `get-task-allow`, e non la copio da ricordi: sarebbe esattamente la
forma d'errore che questo giro deve evitare.

⇒ **[A] Come si determina, in due minuti e senza rischio:** Mauro apre iMazing col telefono
collegato, va su **App → Q-BEATS**, e guarda **se compare una cartella `Documents` con dentro
`songs.json`, `setlists.json`, `backtracks.json`.** Se li vede, la risposta è sì e può copiarli
fuori; se non li vede, è no. **È una lettura, non scrive nulla: provarla non può rompere niente.**

⚠️ **E la buona notizia, misurata: la risposta a questa domanda NON blocca il collaudo.** Vedi B4.

---

# B2 · COSA FA ESATTAMENTE `injectTestData`

**[M] Corpo verbatim**, `ios_app/QBeats/Store/QBeatsStore.swift:191-203`:

```text
191	    // MARK: - Test data injection (DEBUG only)
192	
193	    #if DEBUG
194	    /// Inietta dati di test direttamente in RAM, bypassa coordinated read/write.
195	    /// Usato da DebugView per popolare lo store senza dipendere da iCloud
196	    /// container o file su disco. Nessuna persistenza — i dati spariscono al
197	    /// kill dell'app. Pensato per validazione L1.b su device.
198	    func injectTestData(songs: [Song], setlists: [Setlist]) {
199	        self.songs = songs
200	        self.setlists = setlists
201	        logger.info("injectTestData — songs: \(self.songs.count), setlists: \(self.setlists.count)")
202	    }
203	    #endif
```


**[M] Le tre risposte:**

| domanda | risposta misurata |
|---|---|
| sostituisce, fonde o aggiunge? | **SOSTITUISCE.** `self.songs = songs` e `self.setlists = setlists` sono assegnazioni secche: il catalogo precedente **in RAM** sparisce |
| scrive su disco subito? | **NO.** Nessuna chiamata a `save()`, nessun `FileManager`, nessun `write`. Il commento lo dichiara: «Nessuna persistenza — i dati spariscono al kill dell'app» |
| tocca i backtrack? | **NO.** `backtracks` non è nominato: resta quello caricato da disco |

## Il meccanismo intero, fino alla scrittura

**[M]** L'unica funzione che scrive i tre file è `save()` (`ios_app/QBeats/Store/QBeatsStore.swift:65-77`, già consegnata sopra).
I suoi chiamanti sono **dieci**, tutti dentro `QBeatsStore.swift`, tutti in coda a una CRUD:
`:83`, `:89`, `:94`, `:99`, `:106`, `:112`, `:117`, `:122`, `:138`, `:143`.

**[M] E le CRUD, chi le chiama davvero — censimento completo, fuori da `QBeatsStore.swift`:**

| metodo | chiamanti | dove |
|---|---:|---|
| `addSong` | **2** | `QBeatsBackupManager.swift:228` · **`SongListView.swift:144`** |
| `updateSong` | **1** | **`SongEditorView.swift:102`** |
| `deleteSong` | **1** | **`SongListView.swift:152`** |
| `moveSongs` | **1** | **`SongListView.swift:158`** |
| `addSetlist` | **1** | `QBeatsBackupManager.swift:233` |
| `upsertBacktrack` | **1** | `QBeatsBackupManager.swift:254` |
| `updateSetlist` | **0** | — |
| `deleteSetlist` | **0** | — |
| `moveSetlists` | **0** | — |
| `deleteBacktrack` | **0** | — |

⇒ **[M] Il disco si scrive da DUE posti soli:** la **lista/editor canzoni di Q-Stage**
(`SongListView`, `SongEditorView`) e il **percorso di import** (`QBeatsBackupManager`).
**Nessuna CRUD vive in Q-Live, in `LiveView`, in `TransportView` o in `SetlistRunner`.**

**[M]** E non esiste un salvataggio automatico: cercato `save()` dello store su lifecycle/scenePhase
→ **zero**; controllo positivo `scenePhase` → 3 file (`AppDelegate` 1, `QBeatsApp` 3, `AppRootView` 2).
Letto per intero `ios_app/QBeats/QBeatsApp.swift`: il suo `onChange(of: scenePhase)` tocca **solo** Ableton Link, mai lo store.

## ⛔ IL VERO VETTORE DI RISCHIO, ed è uno solo

**[A]** `injectTestData` da sola è innocua. **Diventa distruttiva in due mosse:**

1. Mauro apre DEBUG e inietta → in **RAM** restano **solo** `Test Song A/B` e `Test Setlist L1.b`;
2. Mauro va in **Q-Stage → lista canzoni** e aggiunge, cancella o riordina anche **una sola**
   canzone → scatta `save()` → **`songs.json` e `setlists.json` vengono riscritti con i dati di
   test**, e il catalogo vero è perso.

**[M]** Quella lista **non è dietro DEBUG**: `#if DEBUG` in `SongListView.swift` → **0**. È UI di
produzione:

```text
141	    private func addSong() {
142	        let new = Song.makeDefault()
143	        Task { @MainActor in
144	            await store.addSong(new)
145	            path.append(new.id)
146	        }
147	    }
148	
149	    private func deleteSongs(_ offsets: IndexSet) {
150	        let ids = offsets.map { store.songs[$0].id }
151	        Task { @MainActor in
152	            for id in ids { await store.deleteSong(id: id) }
153	        }
154	    }
155	
156	    private func moveSongs(_ source: IndexSet, _ destination: Int) {
157	        Task { @MainActor in
158	            await store.moveSongs(from: source, to: destination)
159	        }
```


⚠️ **[M] I backtrack sopravvivrebbero comunque** (`injectTestData` non li tocca e `save()` li
riscrive dalla RAM invariata). A morire sarebbero **canzoni e scalette**.

## ⚠️ DUE PRECISAZIONI CHE CAMBIANO LA FORMULAZIONE, non la conclusione

Emerse da una verifica avversariale e **rimisurate da me** prima di scriverle.

**[M] (a) Dentro Q-Live QUALCOSA scrive su disco — ma NON è il catalogo.** Il pulsante mute-click
dell'intestazione del player, `LiveHeaderView.swift:125`, fa
`audioEngine.appSettings.clickMuted.toggle()`; questo accende il `didSet` di
`AudioEngine.swift:109-113`, che a `:111` chiama `appSettings.save()`, che a
`AppSettings.swift:35-38` scrive in **`UserDefaults`**. `LiveHeaderView` è montata dal player
(`LiveView.swift:97`) e **non è dietro `#if DEBUG`**.
⇒ «In Q-Live non si scrive nulla su disco» sarebbe **FALSO**. La formulazione esatta è:
**in Q-Live non si scrive il CATALOGO** — `songs.json`, `setlists.json`, `backtracks.json` sotto
`resolveBaseURL()` restano intoccati. Le preferenze (mute, volumi, LinkMode) sì, e non c'entrano
col catalogo di Mauro.

**[M] (b) Esiste un `backtracks.json` scritto FUORI da `save()`, e non è il catalogo.**
`QBeatsBackupManager.swift:120` scrive un file con quel nome, ma dentro
`FileManager.temporaryDirectory/qbeats_export_<uuid>/` (`:52-54`), cancellata dal
`defer { try? fm.removeItem(at: tempBase) }` a `:55`. ⇒ Non è sotto `resolveBaseURL()`, non è il
catalogo, e per di più è **irraggiungibile**: `export(` ha **zero chiamanti** oltre la propria
dichiarazione (`:34`), perché la sola vista che la userebbe — `BackupView` — non è montata (B3).

---

# B3 · ESISTE UN'ALTRA STRADA, SENZA LA PORTA DI DEBUG?

**[M] SÌ. Esiste, ed è di PRODUZIONE: aprire un file `.qbeats`.**

```text
31	                .onOpenURL { url in
32	                    guard url.pathExtension.lowercased() == "qbeats" else { return }
33	                    os_log("[QBeatsApp] onOpenURL: %{public}@", log: .default, type: .default,
34	                           url.lastPathComponent)
35	                    Task {
36	                        do {
37	                            let manifest = try await QBeatsBackupManager.parse(url)
38	                            pendingImportManifest = manifest
39	                            showImportView = true
40	                        } catch {
41	                            os_log("[QBeatsApp] parse error: %{public}@", log: .default, type: .error,
42	                                   error.localizedDescription)
43	                        }
44	                    }
45	                }
```


**[M]** Il tipo di documento è registrato nella fonte autorevole, `ios_app/project.yml:53-66` (già consegnato al
punto B1.2): `CFBundleDocumentTypes` → `com.bullfrog.qbeats.backup`, `UTTypeConformsTo`
`public.zip-archive`, estensione **`qbeats`**.

**[M] Non è dietro DEBUG:** `ios_app/QBeats/QBeatsApp.swift` non contiene **alcun** `#if DEBUG` — zero occorrenze; controllo
positivo con la forma identica su `DebugView.swift` → **5**.

**[M] E l'import AGGIUNGE, non sostituisce:** applica con `store.addSong`
(`QBeatsBackupManager.swift:228`) e `store.addSetlist` (`:233`) — i due metodi che fanno `append`,
non assegnazione. ⚠️ **Ma scrive su disco**, perché ogni `add*` chiama `save()`.

⛔ **UN LIMITE, e va detto: l'export non c'è.** `BackupView` — la schermata che **produce** il
file `.qbeats` — **non è montata da nessuna parte**. `BackupView` rende **4** occorrenze in tutto
il corpus: la dichiarazione (`BackupView.swift:5`), due sue righe di log, e un commento in
`DebugView.swift:14` che lo dichiara in chiaro — «Gli ingressi export/import sono assenti dall'UI di
produzione». **Zero siti di costruzione.** Controllo positivo con la forma identica: `SettingsView`
→ **3** occorrenze, di cui **una è un montaggio reale** (`ContentView.swift:83`).

⇒ **[A] Quindi la porta `.qbeats` c'è in entrata ma non in uscita:** si può **importare** un
backup, non **crearne** uno dall'app. Per usarla servirebbe un `.qbeats` costruito fuori dall'app,
e **come si costruisca non l'ho misurato**: non era nel mandato e non lo ipotizzo.

**[M] Una terza strada, la più semplice, ed è già aperta:** se sul telefono ci sono **già** scalette
vere, Q-Live le mostra **senza alcuna porta**. La lista Shows legge `store.setlists`, che `load()`
riempie da `setlists.json` all'avvio (`ios_app/QBeats/QBeatsApp.swift:17-25`). ⚠️ **Cosa ci sia oggi sul telefono di Mauro non
è misurabile da qui** — lo sa solo lui, aprendo Q-Live.

---

# B4 · VERDETTO IN ITALIANO PIANO — per Mauro

## 1. Il collaudo di ⟦S5b⟧ su iPhone si può fare in sicurezza: **SÌ.**

E non serve nemmeno un backup, **a una condizione sola**: che tu non entri nella lista canzoni di
Q-Stage finché stai collaudando. Il motivo, misurato: il pulsante di debug **non scrive niente sul
telefono**, mette i dati di prova solo in memoria; e in tutta la stanza Q-Live **non esiste una riga
di codice che salvi su disco**. L'unico posto che salva è la lista canzoni di Q-Stage.

## 2. La procedura, nell'ordine

1. **Prima di tutto, se vuoi la rete di sicurezza:** collega il telefono, apri **iMazing**, vai su
   **App → Q-BEATS** e guarda se vedi una cartella `Documents` con `songs.json`, `setlists.json`,
   `backtracks.json`. **Se li vedi, copiali sul PC** — sono quelli, sono tutto il tuo catalogo.
   Se non li vedi, non insistere: passa al punto 2, la procedura regge lo stesso.
2. **Apri l'app e guarda subito Q-LIVE.** Se le tue scalette vere ci sono già, **non toccare il
   DEBUG**: collauda con quelle e non corri alcun rischio.
3. **Solo se Q-LIVE è vuota**, usa la porta di debug: Home → il pulsantino grigio **⚙ DEBUG** in
   basso → la voce che carica `Test Setlist L1.b`.
4. **Da questo momento e fino alla fine: NON entrare nella lista canzoni di Q-Stage.** Né per
   aggiungere, né per cancellare, né per riordinare. È quella l'unica mossa che sovrascrive.
   Q-Live, il metronomo, il player, END SHOW: tutti sicuri. ⚠️ Il pulsante **mute-click** del
   player salva una preferenza (non il catalogo): puoi usarlo tranquillamente.
5. **Quando hai finito, chiudi l'app dallo switcher** (chiusura vera, non solo Home). I dati di
   prova evaporano e al riavvio l'app rilegge da disco il tuo catalogo vero.

## 3. Cosa manca

**Niente che blocchi il collaudo.** Ma due cose mancano davvero, e le registro senza progettarle:

- ⛔ **Non esiste un modo, dall'app, di tirare fuori un backup.** La schermata c'è nel codice ma
  nessuno la monta. ⇒ **Fix piccolo** — è montare una vista che già esiste e già sa fare il suo
  mestiere, non scriverne una nuova. **Non lo progetto: dico che manca.**
- ⚠️ **Non è determinabile da qui se iMazing veda quei file.** ⇒ Non è un fix: è una **prova da
  fare**, due minuti, senza rischio perché è sola lettura.

⚠️ **E un rischio che c'era già prima e che non riguarda ⟦S5b⟧**, ma che ho incontrato misurando e
non taccio: il codice stesso dichiara a `ios_app/QBeats/Store/QBeatsStore.swift:44-48` che **un `load()` fallito lascia `songs=[]` in
RAM e il primo `save()` renderebbe il vuoto permanente (wipe)**. Il rimedio esiste **solo** per
`backtracks.json`, che ha lettura isolata e non-fatale; **`songs.json` e `setlists.json` non ce
l'hanno**. Non l'ho aperto come ticket — non era il mandato.

⚠️ **Una nota pratica sul punto 5 della procedura:** se al riavvio Q-LIVE ti sembra vuota, **non
dedurne che i dati siano persi** prima di aver guardato: potrebbe essere un `load()` fallito, che
lascia la memoria vuota **senza** aver toccato il disco. In quel caso la cosa da NON fare è
aggiungere o cancellare una canzone — sarebbe proprio quel gesto a rendere il vuoto permanente.

---

## VERIFICA AVVERSARIALE

**[M]** Le affermazioni di ASSENZA sono quelle che questo progetto ha già pagato care. Ho messo
**sei** verificatori indipendenti, ciascuno **istruito a CONFUTARE** una delle sei, con obbligo di
controllo positivo, di variare almeno due volte la forma di ricerca, e di dichiarare **da quale
strato** viene la prova (`project.yml` contro `Info.plist`).

| claim sotto attacco | esito | confidenza | controesempi |
|---|---|---|---:|
| le due chiavi di condivisione file sono assenti **in ogni strato** | **REGGE** | alta | 0 |
| `injectTestData` è solo-RAM, nessuna scrittura | **REGGE** | alta | 0 |
| `BackupView` non è montata da nessuna parte | **REGGE** | alta | 0 |
| **nessun percorso Q-Live scrive il catalogo** | **REGGE** | alta | 0 (2 quasi-controesempi, sopra) |
| la porta `.qbeats` è di produzione e **aggiunge** | **REGGE** | alta | 0 |
| la CI archivia in `-configuration Debug` | **REGGE** | alta | 0 |

**[R] Tre rinforzi che i verificatori hanno portato e che io non avevo misurato:**

- la ricerca delle due chiavi è stata rifatta **sulla storia intera di tutti i branch**
  (`git log --all -S`): **zero commit** le hanno mai introdotte. Controllo positivo con la stessa
  forma: `UIBackgroundModes` → **11 commit**. ⇒ Non sono state «tolte»: **non sono mai esistite**;
- cercate anche le vie **equivalenti** di esposizione — `INFOPLIST_KEY_*`, `PlistBuddy`/`plutil`,
  `UISupportsDocumentBrowser`, `NSExtension`, app group, `DocumentGroup`, `fileExporter`,
  `UIDocumentPickerViewController`: **tutte zero**;
- **nessun `.xcodeproj`/`.pbxproj` è tracciato** (controllo positivo: 67 `.swift`), quindi non
  esiste un secondo strato che possa iniettare chiavi Info.plist fuori da `project.yml`.

⚠️ **[A] Marco [R] il dettaglio dei loro percorsi.** I due quasi-controesempi del quarto
verificatore li ho **rimisurati io** e sono nel referto come **[M]**; il resto delle loro conte
intermedie no.

---

## IMPRONTE DI QUESTO REFERTO

⚠️ Stessa forma dei referti precedenti: **lo sha256 del file completo non può stare dentro il
file**. Si incide lo sha del **CORPO** (tutto ciò che precede il marcatore `## IMPRONTE DI QUESTO REFERTO`); lo sha del
file intero vive nel messaggio di consegna — `LIBRO` R7 §1.

Faccia disco = faccia blob: `git check-attr text` su `HANDOFF/**` → `text: unset` (`-text`).

- **sha256 del CORPO** (fino al marcatore, escluso): `735f12fd283887c8efc259a1f7a97ea7da7a3885e69ede12965556635fa97481`
- **byte** (file completo): `24605`
- **righe** (file completo): `470`
- **CR** (0x0D, contati sui byte, mai con grep): `0`

---

*A105-COLLAUDO-SICURO-FINE*
