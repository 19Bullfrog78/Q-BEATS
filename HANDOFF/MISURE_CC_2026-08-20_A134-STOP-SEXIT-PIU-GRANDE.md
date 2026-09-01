# REFERTO A134 — ⛔ MI FERMO: ⟦S-EXIT⟧ È PIÙ GRANDE DEL MANDATO

Da: CC · A: referee, + Mauro · Data: **20/08/2026** · HEAD: `178042b8786cf51c01bd5e56f4881537f5d02fa6`
Mandato: **A134** (scheda di ⟦S-EXIT⟧).

⛔ **LA SCHEDA NON È STATA SCRITTA. ZERO MODIFICHE A QUALUNQUE FILE.** `git status` sui
tracciati: **vuoto**. Nessun canonico toccato, nessun `ios_app/`, nemmeno una riga.

**Motivo:** il mandato chiude con *«se leggendo il contratto trovi che ⟦S-EXIT⟧ è più grande di
quanto questo mandato presume, o che va spezzato in due come è successo a ⟦S5⟧, **DILLO E
FERMATI**»*. **La condizione si è verificata.** Questo referto porta la misura che lo dimostra,
più tutto il lavoro preparatorio già fatto — che resta valido e non va rifatto.

Marcatura: **[M]** misurato da me · **[A]** giudizio mio.

---

## ⛔ IL REPERTO CHE MI FERMA — L'AMBRA «BAND» NON È COSTRUIBILE A HEAD

Il contratto CD prescrive che il modale mostri un apparato ambra **solo quando è vera** questa
condizione, verbatim dalla truth-table: **«Start/Stop Sync ON _e_ ≥1 peer connesso (le due cose
insieme)»**. Ho misurato entrambi i termini.

### Termine 1 — Start/Stop Sync: l'API ESISTE in Ableton, ma NON È CABLATA da noi

**[M]** Alla fonte più profonda, non al primo file: l'header ufficiale del framework nel repo,
`Vendors/AbletonLink/LinkKit.xcframework/ios-arm64/Headers/ABLLink.h`, **riga 83**:

```c
bool ABLLinkIsStartStopSyncEnabled(ABLLinkRef);
```

e **riga 164**, il callback per i cambi di stato:

```c
void ABLLinkSetIsStartStopSyncEnabledCallback(…)
```

**[M] Occorrenze di `ABLLinkIsStartStopSyncEnabled` in tutto `ios_app/`: ZERO.**
⛔ **Controllo positivo sulla stessa sonda, per non prendere un falso-zero:**
`ABLLinkSetStartStopCallback` → 1 · `ABLLinkIsConnected` → 3+2. **La sonda vede le API ABLLink
presenti: lo zero è reale.**

⚠️ **E c'è un omonimo che inganna, dichiarato perché non si ripeta l'errore:**
`link_engine_set_start_stop_callback` **esiste** ed è cablato (`LinkEngine.mm:498-514`). Ma
notifica **quando il transport parte/si ferma** — è la propagazione, **non** lo stato del toggle
per-peer. Chi cercasse «start_stop» nel nostro codice lo troverebbe e concluderebbe che SSS è
già disponibile. **Non lo è.**

**[M]** L'unica altra occorrenza di «StartStopSync» nel corpus è
`ABLLinkStartStopSyncSupported` in `Info.plist:45` e `project.yml:24` — cioè la **capability
dichiarata dall'app**, non lo **stato corrente del toggle**. Due cose diverse con nomi quasi
identici.

⇒ **Metà del trigger dell'ambra non è leggibile a HEAD.** Non è impossibile: è **non
costruito**. Il cablaggio va da `LinkEngine.mm` → `MIDIEngineBridge.h` → `AudioEngine.swift`.

### Termine 2 — il peer-count: il dato c'è, ma il campo che lo porta ha DUE SCRITTORI IN CONFLITTO

**[M]** Il getter esiste ed è vivo: `link_engine_num_peers` (`MIDIEngineBridge.h:55`,
implementato `LinkEngine.mm:111`, chiamato da `AudioEngine.swift:676` e `:968`). Esiste anche il
callback `link_engine_set_peers_changed_callback`. **Il numero vero è ottenibile.**

⛔ **Ma il campo `@Published var linkPeers: Int` (`AudioEngine.swift:39`) è scritto da DUE
percorsi con semantiche diverse:**

| percorso | riga | cosa scrive |
|---|---|---|
| callback peers-changed | `:458` | `Int(count)` — **il conteggio vero** |
| callback is-enabled (toggle Link nel pane Ableton) | `:479` · `:491` · `:500` | `isConn ? 1 : 0` — **un ripiego booleano** |
| ri-registrazione | `:1310` · `:1322` · `:1331` | `isConn ? 1 : 0` — idem |

⇒ Con tre peer connessi, se l'ultimo aggiornamento arriva dal secondo percorso, `linkPeers`
vale **1**, non 3. **Il chip «N on Link» del contratto mostrerebbe un numero falso**, e non in
modo rilevabile a valle.

⚠️ **Questo non è un difetto introdotto oggi né una scoperta di questo mandato**: è
pre-esistente e imparentato con `TD-link-indicator-stale` già in BUGS. **Non l'ho riparato** —
fuori perimetro, e il mandato vieta ogni modifica.

### E il contratto CD lo sapeva

**[M]** Ultima riga del pannello «Contratto comportamentale», verbatim:

> **Del referee (cablaggio):** peer-count + stato SSS (con TD#17), teardown grafo/Link allo
> STOP, lista Shows col pulsante metronomo condizionale. **Collocazione:** atterra a **S6** —
> nessuna urgenza.

⇒ **CD ha congelato il disegno e delegato esplicitamente tre cablaggi.** Due di quei tre sono
proprio i termini del trigger ambra. Il mandato A134 presume un atomo di sola UI; il contratto
ne descrive uno che **include un cablaggio Layer 2 → ponte C → Swift**.

---

## ⚠️ PERCHÉ NON BASTA SPEZZARLO IN DUE — LA DOMANDA CHE NON È MIA

La divisione naturale sarebbe:

- **⟦S-EXIT⟧a** — il gate: scrim, card, contesto con troncamento, STOP&EXIT / STOP&SWITCH /
  STAY, gate solo in play su lista e dettaglio. **Layer 3 puro, costruibile oggi.**
- **⟦S-EXIT⟧b** — l'ambra: cablaggio di `ABLLinkIsStartStopSyncEnabled` + peer-count affidabile.
  **Tocca il ponte C/C++**, con audit RT e rischio di natura diversa.

⛔ **Ma ⟦S-EXIT⟧a da solo ha un difetto che va deciso da Mauro, non da me.** Senza il termine
SSS, la condizione dell'ambra **non può mai risultare vera per costruzione** ⇒ il modale
mostrerebbe **sempre** la card neutra. Nel caso peggiore — SSS attivo e band collegata —
l'utente legge «Leaving stops the click», preme **Stop & Exit** convinto di fermare solo sé
stesso, e **ferma tutta la band senza alcun avviso**.

⚠️ **È esattamente il difetto che il ruling asimmetrico esisteva per prevenire**, verbatim dal
contratto: *«Aggiungere un avviso è sicuro; toglierlo è la mossa che ti fa premere il rosso
convinto che non faccia male.»* Un'ambra che non compare mai **è** un avviso tolto — non per
scelta, per impossibilità tecnica.

**[A] Tre vie possibili. Non ne scelgo nessuna: sono decisioni di prodotto e di sicurezza.**

1. **A+B insieme**, un atomo unico più grande che tocca anche Layer 2. Nessun rilascio parziale.
2. **A prima, con l'ambra CONSERVATIVA**: finché B non esiste, l'avviso compare **sempre**, con
   copy diversa (del tipo «potrebbe fermare la band»). Si sbaglia dalla parte sicura, coerente
   con la filosofia del ruling — ⛔ **ma contraddice il contratto**, che dice «compare solo
   quando è vera»: mentire nell'altro verso resta mentire, e la copy è congelata. **Serve CD.**
3. **A prima con l'ambra assente**, accettando consapevolmente il rischio, e B subito dopo.

---

## COSA HO GIÀ MISURATO — LAVORO VALIDO, DA NON RIFARE

### Le fonti, con impronte

| fonte | impronta / misura |
|---|---|
| `DESIGN/QLive_Nav/2026-07-18_QLive-Exit-in-Play.html` | sha256 `8d7a3150050f2d9ee88d552f6a59649081518a1189182174c5dfed655c398860` · **58 463 byte** · **536 righe** · CR **0** (LF) · tracciato |
| `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md` | sha256 `d1d8b396cb7eefbe2e979fc9f3ae0a7695ca5031947b035213aeccf1a68f361a` · **66 467 byte** · **457 righe** · CR **0** |

✅ L'impronta del contratto **coincide** con quella ancorata in `LIBRO_MASTRO_QBEATS.md:291`.

### I cinque punti che il referee mi ha chiesto di verificare — TUTTI CONFERMATI

**[M]** Letti nel markup, non nella resa:

1. ✅ Home/segmento col click attivo **non sono un'uscita**: *«l'unica cosa che ferma il click è
   uno STOP deliberato. Home / segmento lo chiamano, non lo aggirano.»*
2. ✅ Gate **solo in play**. ⚠️ **Con una precisazione che il referee non aveva citato**: gli
   stati liberi sono **tre**, non due — *«Da `stopped` / `standby` / `fineSetlist` il clock è già
   fermo → uscita libera, un tocco»*. `fineSetlist` va nella scheda.
3. ✅ Stesso modale, cambia la seconda parola: `STOP & EXIT` (Home, **solo lista**) ·
   `STOP & SWITCH` (segmento). Sul dettaglio «EXIT» **non compare mai**.
4. ✅ Il modale porta il contesto: show · song · section + BPM/TS.
5. ✅ Ruling ambra asimmetrico: compare live, **non sparisce mai** finché il modale è aperto.

**[M] Quattro cose in più, non nell'elenco del referee, che la scheda dovrà portare:**

- **Dismiss / tap sullo scrim = STAY** (contratto, punto 3 «Esiti»).
- **Il troncamento non è opzionale**: è *«il comportamento di default del componente `.ctx`»*,
  con priorità a tre livelli — show ellissi 1 riga · song fino a 2 righe · BPM/TS **pinnati**,
  section cede per prima. *«CC non deve scegliere se applicarlo.»*
- ⛔ **Trappola maiuscolo dichiarata dal contratto stesso**: la copy congelata è **mixed-case**;
  il MAIUSCOLO a schermo è `text-transform:uppercase`. *«Non riscriverla minuscola/maiuscola
  leggendo il solo markup.»*
- **Token: ZERO nuovi.** Sorgente normativa `2026-07-11_Q7-Q16.html`; il `:root` del file
  uscita-in-play è *«una copia di lavoro»*, e se un valore diverge **vince Q7-Q16**.

### Confine (i) — che cosa è ⟦S6F⟧ e non ⟦S-EXIT⟧ · CONFERMATO

**[M]** La fascia «Q-LIVE · PLAYING» è descritta come **via IN**, simmetrica e distinta dalla
via OUT: *«Compare solo in play, in fondo alle superfici Shows, **al posto** del metrofab (lista)
/ dello startfoot (dettaglio)»*, con punto pulsante, `song · section` e chip **Return** ≥44pt.
⇒ **È ⟦S6F⟧.** La scheda di ⟦S-EXIT⟧ dovrà dirlo in una riga esplicita, o si mangia l'altro
atomo — come giustamente avverte il mandato.

### Confine (ii) — IL BUCO DEL PLAYER IN STANDBY · MISURATO E CONFERMATO

**[M] Il caso di Mauro non è coperto da nessuna parte, ed è peggio di quanto il mandato
presume.** Il contratto esclude il player: *«sul player la barra stanze non c'è → nessuna
uscita-stanza, niente gate lì»*. Ma il player in standby **non ha nemmeno l'uscita di
navigazione**. Meccanismo, misurato in `LiveView.swift`:

| riga | fatto |
|---|---|
| `:97` | `LiveHeaderView(… onExit: onExit …)` — il back «‹» vive **dentro** il `VStack` |
| `:129` | quel `VStack` ha `.opacity(isStandby ? 0.10 : 1.0)` — in standby è **quasi invisibile** |
| `:132-138` | l'overlay standby è **dopo** nello `ZStack` ⇒ sta **sopra** |
| `:133` | `StandbyOverlayView` ha un `GeometryReader` come radice ⇒ **greedy, prende tutta l'area** |
| `:134` | `.contentShape(Rectangle())` ⇒ **tutta l'area diventa tappabile**, non solo il testo |
| `:135-137` | `.onTapGesture { runner.startCurrentSong(…) }` ⇒ **ogni tocco diventa «parti»** |

⇒ Il back è **invisibile al 10%** *e* **coperto da un bersaglio a schermo pieno che consuma ogni
tocco**. Verbatim di Mauro, coerente al 100% con la misura: *«Devo toccare, parte il metronomo,
stoppo il metronomo, clicco "<"»*.

⚠️ **E il caso non è marginale: è il caso NORMALE.** Da ⟦S5b⟧ ogni ingresso in uno show è
«arma + standby» ⇒ **si finisce in standby a ogni singolo START SHOW**. Chi cambia idea in quel
momento non ha modo di tornare indietro senza far partire il click.

⛔ **NON RISOLTO, come prescritto.** È una **lacuna di disegno da portare a CD**: il contratto
ha escluso il player dal gate presumendo che non servisse un'uscita lì, senza considerare che
in standby l'uscita di navigazione è materialmente irraggiungibile.

### Le uscite reali oggi, per superficie

**[M]**

| superficie | uscite esistenti | gate oggi |
|---|---|---|
| **lista** (`QLiveShowsView`) | Home (`onExit`) · segmento (`onSwitch: onSwitchToStage`) | **nessuno** — vanno dritte ad `AppRootView` |
| **dettaglio** (`QLiveShowDetailView`) | back → `.shows` (navigazione) · `.segMini` **muto** | **nessuno** — e il segmento non fa nulla (ticket `TD-segmini-onswitch-morto`) |
| **player** (`LiveView`) | back → `navigate(to: .shows)`, navigazione interna | **nessuno**; in standby **irraggiungibile** (sopra) |

**[M] Dove lo stop avviene oggi:** `AppRootView.swift:70-77`, `.onChange(of: screen)` — se si
lascia `.qLive`, `audioEngine.stop()`. È **al bordo-stanza**, dopo che la transizione è già
decisa: nessuna conferma, nessun ritorno indietro. È esattamente ciò che ⟦S-EXIT⟧ deve
anticipare con una domanda.

### PASSO 4 — anti-cascata: CENSIMENTO FATTO, e il punto d'innesto è SICURO

**[M] Punto d'innesto individuato:** subito **prima di `### ⟦S6⟧`** (riga **419**), cioè dopo
⟦S5b⟧ — coerente con l'ordine ratificato `S5 → ⟦S-EXIT⟧ → S4L → S6`. Sezione B va da 44 a 427,
sezione C inizia a **428**.

⛔ **Due sonde, non una — e la prima da sola avrebbe dato un falso zero.** La forma lunga
(`SCALETTA_ATOMI_S6_2026-07-10.md:NNN`) trova 18 citazioni; la forma **abbreviata**
(`SCALETTA:NNN`), che il mandato nomina, ne trova **altre 15 che la prima mancava**.
**Controllo positivo sulla sonda abbreviata:** `BOX5:NNN` → 4 occorrenze nella SCALETTA — vede.

| file | citazioni | la più alta | nude ≥ 419? |
|---|---:|---|---|
| `LIBRO_MASTRO_QBEATS.md` | 19 | `:329` (nuda) · `:329 @ 44fea3e` (ancorata) | **0** |
| `BUGS_QBEATS.md` | 5 | `:322 @ 2960f08` (ancorata) · `:213` (nuda) | **0** |
| `BOX3` / `BOX5` | 0 | — | **0** |
| `SCALETTA` (auto-citazioni) | 7 | `:325` (nuda) · `:322 @ 2960f08` | **0** |

⇒ ✅ **ZERO citazioni nude puntano a riga ≥ 419.** La più alta in assoluto è `:329`, ben sotto
il punto d'innesto. **Nulla da ancorare, nulla si romperebbe.** Il documento crescerebbe solo
sotto la riga 418.

⚠️ **Ma questa è una misura, e le misure scadono** — è la lezione già incisa a `SCALETTA:412`
sulla clausola «zero citazioni nude ≥320», vera al suo commit e falsa poco dopo. **Chi
innesterà davvero la scheda la rimisuri**, non la rilegga da qui.

---

## COSA SERVE PER RIPARTIRE

Tre decisioni, nessuna mia:

1. **⟦S-EXIT⟧ si spezza o no?** Se sì, ⟦S-EXIT⟧a (gate, Layer 3) e ⟦S-EXIT⟧b (SSS + peer-count,
   ponte C/C++) — e con quale ordine reciproco nella riga d'ordine ratificata.
2. **⟦S-EXIT⟧a da solo è rilasciabile sul palco**, sapendo che l'ambra non comparirebbe mai?
   Delle tre vie sopra, quale. **La 2 richiede CD** (la copy è congelata).
3. **Il buco del player in standby** va a CD come lacuna di disegno, o si tratta come difetto e
   si apre un ticket in BUGS?

⇒ **Con una risposta a queste tre, la scheda si scrive in un giro.** Tutto il materiale
preparatorio è in questo referto e non va rifatto.

---

## LIMITI DICHIARATI

1. ⚠️ **Non ho verificato quanto costa il cablaggio SSS.** So che l'API esiste e che non è
   cablata; **non ho misurato** quante righe servano in `LinkEngine.mm`/bridge/Swift, né se
   l'audit RT §4 tocchi quel percorso. Serve prima la decisione (1).
2. ⚠️ **Il «teardown grafo/Link allo STOP»**, terzo cablaggio delegato da CD, l'ho solo
   sfiorato: `AudioEngine.stop()` (`:1078-1093`) chiama `stopSync()` e allinea `playbackState`,
   ma **non ho tracciato** se e dove il grafo/Link venga smontato. Fuori dal perimetro di oggi.
3. ⛔ **Nulla è stato visto a schermo.** Il buco del player in standby è dedotto dal codice e
   **coincide col racconto di Mauro**, ma la sua conferma resta il device.
4. ⚠️ **Non ho letto i frame ③ e ④** (gate su lista/Home, neutra e allarme) riga per riga come
   ho fatto per ⑤/⑥: ho letto il pannello che li governa e la truth-table. Se la scheda entra
   nel dettaglio della resa, quei due frame vanno riletti.

---

## STATO DI CONSEGNA

| | |
|---|---|
| scheda ⟦S-EXIT⟧ | ⛔ **NON SCRITTA** — mi sono fermato come prescritto |
| file modificati | **ZERO**, `git status` sui tracciati vuoto |
| canonici | **zero**, nemmeno un bump di versione |
| `ios_app/` | **zero** |
| commit / push | ⛔ **NESSUNO** |
| HEAD | `178042b8786cf51c01bd5e56f4881537f5d02fa6`, invariato |

---

*A134-FINE*
