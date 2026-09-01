# MISURE CC — A253 — L'USCITA DAL DETTAGLIO — 29/08/2026

Da: CC · A: referee (ratifica del diff) + Mauro + CD

**ID ESEGUITO: A253, versione «1a · L'USCITA DAL DETTAGLIO» ricevuta in questo turno** — quella che ANNULLA E SOSTITUISCE le due precedenti. Nessuna versione precedente di A253 è mai arrivata a questa chat.

**⏱ Orologio, verificato prima di procedere:** sab 29/08/2026 **16:49 locale (UTC+2)** · 14:49 UTC — coerente col fuso e con la CI (ultima run `edf38d3` alle 13:56Z).

Marcatura: **[M]** misurato da me a fonte in questo turno · **[V]** misurato da un verificatore avversario indipendente e da me letto · **[A]** giudizio mio. ⛔ Mai mescolati in una frase.

⛔ **NESSUN COMMIT, NESSUN PUSH, NESSUNO STAGING.** `HEAD` invariato a `edf38d3102ab227f003e23d91d5bd5d0b8aac306`, `git diff --cached` vuoto. Il diff vive nel working tree e in `HANDOFF/DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt` (373 righe, 21 240 byte, `sha256 6f97ce5b0271…`), depositato su ENTRAMBE le gambe, `cmp` identici.

---

## §0 — CANCELLO ID — QUATTRO GAMBE, CON POSITIVI CHE VEDONO

**[M]** `A253` prima di questo referto:

| gamba | sonda | esito |
|---|---|---|
| nome | `git ls-files` + `find` su C: (untracked inclusi) | **0 · 0** |
| contenuto | `git grep -- ':!DESIGN'` + `grep -r` su disco C: (untracked inclusi, no .git/DESIGN) | **0 · 0** |
| disco E: | `find` per nome + `grep -r` in `FILE X CLAUDE.MD` | **0 · 0** |
| storia | `git log --all --grep` | **0** |

Positivi che vedono, sulle stesse sonde: **A250** → nomeC 2 · contC 6 · nomeE 2 · contE 4 · log 1 · **A252** → 1 · 1 · 1 · 1 · 0. **Nessuna collisione su nessun supporto: l'ID regge.**

⚠️ Sonda cieca nota (dal congedo A252, riconfermata): `git grep` NON vede gli untracked — per questo la gamba contenuto è doppia (git + disco).

## §1 — LE FONTI, LETTE PRIMA DI TOCCARE UNA RIGA

**[M]** I tre fogli in `DESIGN/QLive_Nav/`, estratti dal loro HTML e letti per intero:

- **29/08 `USCITA-DA-UNO-SHOW-VIVO`** — §B: i due posti («Da fuori — dettaglio dello show: END SHOW, un tap. Nessun passaggio da STOP»), i **due stati** della sottoriga; §C: «Nessuna conferma su END SHOW, in nessuno dei due posti».
- **27/08 `Bivio-tre-vie-e-TERZA-FACCIA`** — §②: la terza faccia; CSS `.vrow`/`.vrow.end` (i token della voce); **R4**: la riga di Link «compare con Link acceso e almeno un apparecchio collegato», altezza variabile **56/64 dichiarata**.
- **28/08 `rev3-LA-PORTA-E-IL-SEGNALE-BUGIARDO`** — §D, la sentenza: «Finché l'esecutore non onora la sezione, **Resume from [section] non va a schermo**. Non "con copy più prudente": **assente**» · «**La terza faccia eredita il blocco**».

**[M]** La premessa del mandato sul codice, verificata prima di crederci: `QLiveSession.endShow()` era `runner = nil; liveSession.playbackState = .stopped` — **nessuno stop**. Vera.

**[M]** La misura del referee (punto 4 del mandato), rimisurata: `guard self.isRunning else { return }` a `AudioEngine.swift:1694`, `link_engine_stop` a `:1701` **dentro** il blocco protetto, dentro `audioQueue.sync` ⇒ **a motore fermo nessun evento alla band. Regge.** **[V]** Il verificatore ha aggiunto: `link_engine_stop` ha **una sola occorrenza reale** in tutto `ios_app` (la `:1701`); la parte PRE-guard cancella solo un'eventuale partenza-pendente Link, senza eventi.

## §2 — COSA È COSTRUITO — quattro file, 263 inserzioni, 23 delezioni

| file | cosa |
|---|---|
| `QLiveSession.swift` | `endShow()` → **`endShow(audioEngine:)`**, prima riga **`audioEngine.stop()`** — il terzo effetto, col cartello A253 |
| `QLiveRootView.swift` | dichiarazione `@EnvironmentObject audioEngine` · i due chiamanti passano il motore · **`onEndShow: { endShowAndLeave() }`** al sito di montaggio del dettaglio — stessa funzione, nessun percorso nuovo · 2 marcature |
| `QLiveShowDetailView.swift` | parametro `onEndShow` · dichiarazione del motore · **la voce `endShowRow`** (veste `.vrow.end` verbatim, due stati, un tap, niente conferma) sopra il bottone nel piede («in alto quella che chiude, in basso quella che prendi») · 2 `Shape` per i glifi del freeze · piede diventato contenitore (paddings+gradiente saliti dal bottone) |
| `LiveView.swift` | **solo commenti** (+8/−0): marcatura «OGGI NON COSTRUITO è scaduto» |

⛔ **RESUME NON COSTRUITO** (§D rev3, blocco ereditato — inciso anche nel commento del piede). ⛔ **Bivio a tre vie NON toccato** (lavoro 1b). ⛔ **END SHOW resta irreversibile**: chiude e riporta alla lista via `endShowAndLeave()`, nessun ritorno.

## §3 — IL MECCANISMO D'ARCHITETTURA — proposto, DA RATIFICARE

**[A] Il motore entra in `endShow` come PARAMETRO: `endShow(audioEngine: AudioEngine)`.** Tre ragioni, le prime due misurate:

1. **[M] È l'idioma di casa**: `SetlistRunner` riceve il motore per parametro e non lo conserva (`startSetlist(audioEngine:session:)`, catture `weak`). `QLiveSession` fa lo stesso: non conserva nulla.
2. **[M] Rende l'obbligo strutturale**: il prossimo innesco di END SHOW **non può nascere senza** — non compila. È esattamente il rischio che il vincolo ⛔ del mandato nomina («sul bottone, il prossimo innesco nascerà senza»), spostato dal patto al compilatore.
3. **[A] Alternativa scartata**: `AudioEngine.shared` dentro `endShow()` — ha precedenti solo in codice di ciclo-vita (`QBeatsApp:73`, `AppDelegate:9`), mai nei modelli; nasconderebbe la dipendenza e l'obbligo tornerebbe di sola disciplina.

I chiamanti la ricevono da `@EnvironmentObject` in `QLiveRootView` — **dichiarato, non iniettato**. ⚠️ Asimmetria con lo specchio `QStageRootView` (che resta a 0 occorrenze): dichiarata nel codice — Q-Stage non possiede una sessione da chiudere.

## §4 — DOVE ARRIVA IL MOTORE NEL DETTAGLIO — misurato al sorgente

**[M]** `QBeatsApp.swift:16` `.environmentObject(audioEngine)` su `AppRootView` → `AppRootView.swift:5` lo dichiara e `:53` lo inietta su `QLiveRootView` → propagazione d'ambiente alla gerarchia (catena già provata in-repo dal cartello del gate `.metronome`: `HomeRootView.swift:14` la esercita a ogni avvio) → le due dichiarazioni nuove (`QLiveRootView`, `QLiveShowDetailView`) la leggono. **[V]** Zero `.environmentObject(` nuove nel diff; stesso albero senza confini sheet/cover.

## §5 — I SEGNALI DELLA SOTTORIGA — quali e perché

- **SE la riga compare: `audioEngine.linkIsConnected`** — R4 del 27/08 («Link acceso + almeno un apparecchio»; senza, la voce torna a 56 pt). **[V]** `linkIsConnected` ⇔ `ABLLinkIsConnected` = «almeno un peer» (`LinkEngine.mm:54-56`); stesso segnale del chip Link (`LiveHeaderView`). ⚠️ **DIVERGENZA DALLA LETTERA DEL MANDATO, dichiarata:** il mandato non nomina la condizione Link; il canonico R4 sì, ed è ratificato. Senza il cancello, «this will stop other devices too» a zero apparecchi sarebbe **un'etichetta che mente** — la categoria che il §D vieta. Ho seguito il canonico. Se il referee dispone diversamente, il cambio è una riga.
- **QUALE stato dice: `audioEngine.isPlaying`** — lo stato REALE del motore (@Published; **[V]** tre soli scrittori, tutti interni al motore: `:1035` true allo start, `:1766` false allo stop, `:2750` false su interruzione). ⛔ **NON `isShowLive`**, che gattona solo l'ESISTENZA della voce (uno show aperto da chiudere) — mai il testo «playing». ⚠️ Limite noto di `isPlaying` (rev3.1: manca il «terzo interruttore» dell'esaurimento coda), dichiarato nel codice: le due finestre in cui mentiva sono chiuse (show orfano irraggiungibile da ⟦PORTA-RIENTRO⟧; a fine scaletta il runner ferma il motore, `SetlistRunner.swift:466`).
- **COPY**: byte-exact dal §B del 29/08, **[V]** verificata a hexdump, middle dot U+00B7 (`C2 B7`) compreso. ⚠️ Divergenza fra fogli dichiarata nel codice: il 27/08 scrive «the other devices», il 29/08 (posteriore, ed È la spec dei due stati) senza «the» — vince il 29/08.

## §6 — VERIFICA AVVERSARIA — otto refutatori indipendenti, in sola lettura

Ogni tesi è stata data a un agente col compito di **smentirla**. Esiti: **6 PASS · 2 FAIL — ed entrambi i FAIL smentiscono la MIA formulazione di verifica, non il diff:**

1. **[V] FAIL utile — il censimento che mancava.** Tesi mia: «nessun percorso chiude lo show senza passare da endShow». Controesempio trovato, **pre-esistente e ratificato**: l'uscita di stanza (RoomSwitchBar → `AppRootView` commuta `screen`) smonta `QLiveRootView` ⇒ muore `roomSession` ⇒ muore il runner — e lo stop del motore per quella via vive ad `AppRootView.swift:74` («sessione ≡ stanza»). ⇒ **Censimento completo delle vie che chiudono uno show**: (i) `endShow(audioEngine:)` — 3 inneschi UI: BACK TO SHOWS di fine scaletta, `leavePlayer()` a `.fineSetlist`, e da oggi la voce del dettaglio; (ii) il bordo-stanza, con il suo stop proprio. **[A] Conclusione più forte della tesi: dopo questo diff NESSUNA via chiude uno show lasciando il click vivo.** Tutti gli inneschi ETICHETTATI END SHOW convergono su `endShow` — il vincolo del mandato è rispettato.
2. **[V] FAIL di formulazione.** Tesi mia: «il diff non tocca il comportamento del player» — smentita giustamente: END SHOW ora ferma il motore, che È il punto (3) del mandato. I vincoli operativi reggono: `LiveView` +8/−0 **tutte di commento**; `TransportView`/`LiveHeaderView`/`FineSetlistView`/`SetlistRunner`/`AudioEngine` **non toccati**.
3. **[V] PASS** — nessun percorso di navigazione nuovo: `page` privato, unica scrittura in `navigate(to:)`, zero righe aggiunte con navigate/page/switch.
4. **[V] PASS** — zero re-iniezioni; memberwise init verificato (ordine argomenti = ordine dichiarazioni; `@EnvironmentObject` escluso dall'init, precedente `HomeRootView` esercitato a ogni avvio).
5. **[V] PASS** — stato «playing» mai da `isShowLive`.
6. **[V] PASS** — misura stopSync (§1).
7. **[V] PASS** — compilabilità per analisi statica: chiamanti enumerati, simboli esistenti, shorthand `if let` già in questo stesso file (`:459` pre-esistente), API tutte ≤ iOS 15, XcodeGen per path (nessuna file-list da toccare).
8. **[V] PASS** — conformità ai fogli: copy byte-exact, token `.vrow.end` tutti conformi, glifi punto-per-punto, zero `.alert`/`.confirmationDialog`, zero Resume; **tutte le divergenze trovate erano già dichiarate nei commenti**.

## §7 — COSA NON HO MISURATO — dichiarato, non riempito

- ⛔ **IL DIFF NON È COMPILATO.** Nessun toolchain Swift su questa macchina (misurato: `swiftc` assente) e la CI gira solo a push — che non è autorizzato. «CI-verde ≠ chiuso» e qui non c'è nemmeno il CI. ~~Il punto che una build verificherebbe per primo, indicato dal refutatore 7: `@EnvironmentObject private var` senza valore iniziale — **primo uso nel repo** (il meccanismo SE-0258 è standard, il precedente in-repo è la variante non-private).~~
  ⚠️ **CORREZIONE A254 (referee) — LA FRASE BARRATA ERA SBAGLIATA, non solo imprecisa.** Non si cancella: si marca. **[V] Rimisurato in questo turno**: `@EnvironmentObject` ha **SEI usi preesistenti** a `HEAD` — `AppRootView.swift:5`, `HomeRootView.swift:14`, `LiveHeaderView.swift:5`, `LiveView.swift:5` e `:6`, `TransportView.swift:6` — tutti dichiarazioni reali, zero falsi positivi da commenti. **Nuovo è SOLO il modificatore `private`**, che cambia la visibilità Swift, non la risoluzione dell'ambiente. E l'ambiente è garantito **due volte**, per vie indipendenti: `QBeatsApp.swift:16` inietta su `AppRootView` (quindi su tutto l'albero) e `AppRootView.swift:53` re-inietta su `QLiveRootView`. **⇒ Il rischio di risoluzione NON esiste.** Resta vero, ed è l'unica cosa che restava da dire: il diff non è compilato, nessun device l'ha visto.
- ⛔ **Nessun device l'ha visto.** Ratifica referee → OK Mauro → collaudo device: chiuso è solo dopo il device.
- ⚠️ I raccordi r2 del glifo-porta usano la convenzione `addArc` di `LockShape` (collaudata su device); se la convenzione fosse inversa, l'errore è un dentino da ~1 pt sui due angoli — si vede al collaudo.
- ⚠️ Lo **stato 2** della sottoriga non ha frame disegnato (il 29/08 dà solo la copy): a 390 pt la riga lunga non sta su una riga da 10 pt ⇒ `.lineLimit(2)` dentro i 64 pt. Scelta dichiarata nel codice, attende CD.
- ⚠️ **Eredita la conseguenza (iii-a)** già dichiarata e girata a CD: dal dettaglio dello show B con lo show A vivo, END SHOW chiude lo show DI STANZA (A) senza dirlo — stesso limite del bottone BACK TO SHOW, non risolto qui.

## §8 — I DUE PERCORSI E LE IMPRONTE

```
DIFF   repo: HANDOFF\DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt
       E:  : FILE X CLAUDE.MD\HANDOFF\DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt
       sha256 6f97ce5b02717852… · 373 righe · 21 240 byte · cmp identici

REFERTO repo: HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
        E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
        (impronta nel messaggio di consegna: il file non può contenere il proprio hash)
```

⚠️ **Superato da A254 (§9 sotto): il file `DIFF_USCITA-DAL-DETTAGLIO_A253…` è stato AGGIORNATO** (mandato A254, autorizzato: «aggiornare diff»). L'hash sopra resta agli atti com'era misurato AL MOMENTO DEL DEPOSITO DI A253 — non è falso, è **superato**: quel file oggi contiene anche le tre correzioni. Il puntatore vivo è in §9.

*A253-USCITA-DAL-DETTAGLIO-REFERTO-FINE*

---

## §9 — AGGIORNAMENTO A254 (29/08/2026) — LE TRE NOTE, SOLO COMMENTI

Mandato A254, ricevuto dopo la ratifica del referee sul diff A253. **⏱ Orologio: 19:42 locale (UTC+2) · 17:42 UTC.** Aggancio confermato: l'ultimo referto depositato era questo (A253). **Cancello ID A254**: libero su tutte e quattro le gambe (nome/contenuto × C:/E:/log, tutti 0), positivi A252/A253 che vedono. ⛔ **Solo commenti — zero righe di logica, zero firme, zero rinomine.** Verificato per costruzione: ricostruita la patch A253 in un worktree temporaneo separato (`git apply` sopra `HEAD`, pulita al primo colpo — controprova indipendente che il diff depositato era corretto), diffata contro il working tree corrente: **ogni riga toccata da A254 è `///` o una riga vuota di commento**, in soli due file.

⚠️ **RILIEVO A255 (referee) — «positivi A252/A253 che vedono» qui sopra ERA CIECO sulla gamba `git log --all --grep`, non si cancella.** Nessuno dei due era mai stato committato: `git log --all --grep` rende **0** per entrambi, quindi lì erano zeri come il candidato, non controlli positivi — non dimostravano nulla su quella gamba. **[V] Rimisurato dal referee e riconfermato da me** in A255: A252→0, A253→0, A254→0; i positivi che VEDONO su quella gamba sono i tre ID committati quel giorno — A250→1 (`edf38d3`), A249→1, A244→1. **L'ID A254 restava comunque libero** (le altre tre gambe erano genuinamente a zero, e la gamba cieca non nasconde una collisione), ma **il controllo era incompleto**: un ID mai committato non può mai fare da positivo sulla gamba della storia dei commit. Per A255 il cancello usa un positivo che vede SU CIASCUNA gamba, dichiarato quale-per-quale (§10).

**Le tre note del referee, verificate a fonte prima di scrivere — nessuna smentita, tutte confermate:**

1. **[V] Nota 1 — cartello «⚠️ ORDINE» in `QLiveSession.swift`, riscritto.** Confermato a fonte: `AudioEngine.swift:1100-1101` (`DispatchQueue.main.async { self?.playbackState = .stopped }`) sta FUORI dal `guard self.isRunning` di `stopSync()` (`:1694`) — dispatcha SENZA CONDIZIONE a ogni `stop()`. La protezione vera contro quel `.stopped` tardivo dell'ENGINE che scavalca uno `.standby` appena armato è la guardia in `LiveView.swift:461-466` (`case .standby, .fineSetlist: return`), dichiarata (`LiveView.swift:442-460`) come ciò che tiene in piedi l'armamento d'ingresso di ⟦S5b⟧ — con l'avviso, già presente PRIMA di A253 (`:459-460`), che rimuoverla romperebbe S5b «senza toccarne una riga». Il mio cartello originale nominava una motivazione vera (l'ordine, la sincronia) ma non la protezione reale. **Corretto.**
   ⚠️ *Nota di misura:* i numeri di riga che il referee cita per `LiveView.swift` (453-458, 434-452, 451-452) sono calcolati contro `HEAD` — la mia patch A253 inserisce 8 righe di commento più in alto nello stesso file, quindi sul working tree corrente le stesse righe stanno a **461-466, 442-460, 459-460**. Contenuto identico, indirizzo shiftato di +8: verificato, non un disaccordo.
2. **[V] Nota 2 — la voce «⛔ Non misurato» in questo referto, §7, marcata e corretta** (vedi sopra, in loco). Rimisurato: sei usi preesistenti di `@EnvironmentObject` a `HEAD` (`AppRootView.swift:5` · `HomeRootView.swift:14` · `LiveHeaderView.swift:5` · `LiveView.swift:5,6` · `TransportView.swift:6`), doppia iniezione indipendente (`QBeatsApp.swift:16` → `AppRootView` → tutto l'albero; `AppRootView.swift:53` → `QLiveRootView`). Il rischio che avevo scritto non esiste: `private` è nuovo, la risoluzione no.
3. **[V] Nota 3 — cartello del motore in `QLiveRootView.swift`, esteso.** Confermato: a `HEAD` questa vista aveva **zero** occorrenze reali di `audioEngine` (misurato: solo prosa nei commenti, nessuna dichiarazione — lo stesso «0 occorrenze» che il suo stesso cartello del gate `.metronome` misura su `QStageRootView`). Da A253 la radice osserva il motore: il suo `body` si ridisegna a ogni `@Published`, `currentBeat` (`AudioEngine.swift:104`, scritto a `:2419-2421` dentro il callback di render) compreso — 2-4 volte al secondo a tempi da palco. Aggiunto il costo dichiarato, per simmetria con quello già scritto nella foglia (`QLiveShowDetailView`).

**Diff verbatim delle sole note** (le due sole righe di codice — `func endShow(` e `@EnvironmentObject private var audioEngine` — comparivano già in A253 e non cambiano qui; sotto solo commento):

```diff
diff --git a/ios_app/QBeats/UI/QLive/QLiveSession.swift b/ios_app/QBeats/UI/QLive/QLiveSession.swift
--- a/ios_app/QBeats/UI/QLive/QLiveSession.swift  (post-A253, ratificato)
+++ b/ios_app/QBeats/UI/QLive/QLiveSession.swift  (post-A254)
@@ -181,10 +181,32 @@
     ///    già fermato dal runner, `SetlistRunner.swift:466`) non fa nulla.
     ///
     /// ⚠️ ORDINE: lo stop PRIMA di svuotare lo slot — prima si zittisce la
-    ///    stanza, poi si chiude la sessione. `stop()` dispatcha il SUO
-    ///    `playbackState = .stopped` async su main (coda di `stop()`, per
-    ///    simbolo); la scrittura della sessione qui sotto è sincrona e non
-    ///    dipende da quel dispatch.
+    ///    stanza, poi si chiude la sessione.
+    ///
+    /// ⚠️ CORREZIONE A254 (29/08/2026) — LA FRASE CHE SEGUIVA QUI ERA VERA MA
+    ///    INDICAVA LA PROTEZIONE SBAGLIATA. `stop()` dispatcha `.stopped`
+    ///    SUL MOTORE (`AudioEngine.playbackState`, un `@Published` diverso da
+    ///    quello di questa sessione) async su main SENZA CONDIZIONE —
+    ///    `AudioEngine.swift:1100-1101` sta FUORI dal `guard self.isRunning`
+    ///    di `stopSync()` (:1694): parte a OGNI `stop()`, motore già fermo
+    ///    compreso. Quella scrittura può arrivare TARDI: se nel frattempo si
+    ///    è aperto un secondo show e `primeDisplay` ha già armato
+    ///    `liveSession.playbackState = .standby`, un `.stopped` dell'ENGINE
+    ///    in ritardo la scavalcherebbe. La scrittura sincrona di questo
+    ///    metodo non protegge da questo: è un evento successivo, indipendente,
+    ///    su un campo diverso.
+    ///
+    ///    CIÒ CHE LO IMPEDISCE è la GUARDIA in `LiveView.swift:461-466`
+    ///    (`case .standby, .fineSetlist: return`, dentro
+    ///    `.onReceive(audioEngine.$playbackState)`) — non un ordine scritto
+    ///    qui. Quella stessa guardia è dichiarata (`LiveView.swift:442-460`)
+    ///    come ciò che tiene in piedi l'ARMAMENTO D'INGRESSO DI ⟦S5b⟧, e
+    ///    `:459-460` avverte già, da PRIMA di A253, che togliere `.standby`
+    ///    da quella lista «romperebbe ⟦S5b⟧ senza toccarne una riga». A253
+    ///    non crea questa dipendenza: la EREDITA — e senza questa riga
+    ///    restava una protezione che nessuno sapeva di dover difendere.
+    ///    (Righe citate sul working tree CORRENTE: A253 aggiunge 8 righe di
+    ///    commento in testa a `LiveView.swift`, +8 rispetto a `HEAD`.)
     func endShow(audioEngine: AudioEngine) {
         audioEngine.stop()
         runner = nil

diff --git a/ios_app/QBeats/UI/QLive/QLiveRootView.swift b/ios_app/QBeats/UI/QLive/QLiveRootView.swift
--- a/ios_app/QBeats/UI/QLive/QLiveRootView.swift  (post-A253, ratificato)
+++ b/ios_app/QBeats/UI/QLive/QLiveRootView.swift  (post-A254)
@@ -84,6 +84,17 @@
     ///    `audioEngine` (0 occorrenze) e resta così — Q-Stage non possiede una
     ///    sessione da chiudere. Lo specchio è di struttura, non un vincolo di
     ///    identità riga-per-riga.
+    ///
+    /// ⚠️ COSTO DICHIARATO (A254, 29/08/2026): DA OGGI QUESTA RADICE OSSERVA
+    ///    IL MOTORE, e il suo `body` si ridisegna a ogni `@Published` che
+    ///    pubblica — `currentBeat` (`AudioEngine.swift:104`) compreso,
+    ///    scritto una volta per battuta dentro il callback di render
+    ///    (`:2419-2421`): 2-4 volte al secondo a tempi da palco. Non è un
+    ///    difetto: è un costo nuovo, non una svista. PRIMA di A253 questa
+    ///    view aveva ZERO occorrenze reali di `audioEngine` — lo stesso «0
+    ///    occorrenze» che il cartello del gate `.metronome` più sotto misura
+    ///    su `QStageRootView`, misurato identico anche su questo file a
+    ///    `HEAD`. Da A253 vale solo per lo specchio.
     @EnvironmentObject private var audioEngine: AudioEngine
 
     // DECISIONE CD 18/07 (ratificata — LIBRO Sez.2, riga 18/07/2026):
```

⛔ **NESSUN COMMIT, NESSUN PUSH, NESSUNO STAGING** anche in questo giro. `HEAD` invariato a `edf38d3102ab227f003e23d91d5bd5d0b8aac306`, `git diff --cached` vuoto.

**Depositi di A254:**

```
DIFF (aggiornato, A253+A254 combinato — quello da ratificare per il commit)
  repo: HANDOFF\DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt
  E:  : FILE X CLAUDE.MD\HANDOFF\DIFF_USCITA-DAL-DETTAGLIO_A253_2026-08-29_CC.txt
  (hash nel messaggio di consegna — il file non contiene il proprio hash)

DIFF (isolato — le sole tre note, per la revisione mirata di questo mandato)
  repo: HANDOFF\DIFF_LE-TRE-NOTE_A254_2026-08-29_CC.txt
  E:  : FILE X CLAUDE.MD\HANDOFF\DIFF_LE-TRE-NOTE_A254_2026-08-29_CC.txt

REFERTO — questo stesso file, aggiornato (§7 marcato+corretto, §9 aggiunto)
  repo: HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
  E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
```

*A254-LE-TRE-NOTE-DI-A253-FINE*

---

## §10 — A255: CHIUSURA DELL'ATOMO — COMMIT + PUSH + CI

Mandato A255, ricevuto dopo la ratifica del referee su diff A253 e note A254, con l'OK di Mauro sul commit consegnato dal mandato stesso. **⏱ Orologio: 19:58 locale (UTC+2) · 17:58 UTC.** Aggancio confermato: l'ultimo referto depositato era questo (A254, §9).

**Cancello ID A255**: libero su tutte e quattro le gambe. Positivo dichiarato **per ciascuna gamba**, non riciclato alla cieca: **nome** (C:/E:) → `A254` vede (1/1) · **contenuto** (C:/E:) → `A254` vede (5/3) · **`git log --all --grep`** → `A250` vede (`edf38d3`, l'unico ID di questa serie mai committato prima d'ora).

⚠️ **Rilievo del referee su A254, riverificato e confermato prima di credere:** `git log --all --grep` rende **0** per A252, A253, A254 — nessuno dei tre era mai stato committato, quindi nel referto precedente non erano positivi su quella gamba, erano zeri come il candidato. Marcato in loco al §9.

**Le cinque richieste, in ordine:**

**1 · Il file col nome che mentiva — sanato.** `DIFF_USCITA-DAL-DETTAGLIO_A253_…txt` conteneva A253+A254 sotto il nome di A253 puro. Ricostruito A253 puro in un worktree **fresco** (non dalla mia copia in scratch): `git apply` del diff originale sopra `HEAD`, poi `git diff` **rigenerato** nel worktree patchato — **sha ottenuto `6f97ce5b0271785283577f988c67a79cbfe0035ea9a362f859924aafe7c9624a`, identico byte per byte a quello ratificato.** Coincide: i byte ratificati erano quelli. Depositato al nome originale (sostituendo il contenuto sbagliato con quello giusto — non una cancellazione, una correzione). Il combinato A253+A254 depositato **in aggiunta**, sotto nome che dichiara cosa contiene: `DIFF_USCITA-DAL-DETTAGLIO_A253+A254_2026-08-29_CC.txt`.
⚠️ **Nota che il mandato non chiedeva, ma la sequenza impone:** il punto 2 (sotto) e la marcatura BUGS (punto 4) arrivano DOPO questo passo — nessuno dei due file `DIFF_USCITA-DAL-DETTAGLIO_A253…` include quelle due modifiche. Non è un difetto: sono **istantanee di revisione** (A253 puro; A253+A254 come ratificati), non l'ultima parola. L'ultima parola, da qui in avanti, è il commit `9c3616e` (sotto) — citabile per sha, non serve una terza istantanea.

**2 · La frase che si annullava da sola — corretta.** Il cartello `⚠️ ORDINE` di `QLiveSession.endShow(audioEngine:)` citava «+8 rispetto a `HEAD`»: dopo il commit, `HEAD` contiene A253, lo scarto sarebbe zero e la frase falsa. Sostituita con `(Righe citate sul file DOPO A253.)` — nessun riferimento a `HEAD`, nessun bersaglio mobile.

**3 · Il referto — marcato sul posto.** La riga del cancello ID di A254 (§9) porta ora, in coda e non riscritta, il rilievo del referee: i due positivi citati non vedevano sulla gamba `git log --grep` (zero come il candidato), l'ID restava comunque libero (le altre tre gambe erano genuinamente a zero), ma il controllo era incompleto.

**4 · La marcatura in BUGS — trascritta verbatim, per aggiunta.** In coda a `TD-show-non-abbandonabile` (§1.1, `BUGS_QBEATS.md`), le righe esatte consegnate dal referee — zero righe esistenti toccate. **Versione 70→71**, riga di registro **71** aggiunta in Sezione 5 (Storico versioni file), con la dichiarazione esplicita che questo giro **non è doc-only**: viaggia nello stesso commit del codice.

**5 · Commit, push, CI — fatto e verificato, non dato per buono:**

```
sha completo : 9c3616ee8555a1d35d07e6c98892ec5a0306df3a
branch       : master (origin/master allineato dopo il push — verificato, non presunto)
file nel commit (5, nessuno di più): BUGS_QBEATS.md · ios_app/QBeats/UI/Live/LiveView.swift ·
  ios_app/QBeats/UI/QLive/QLiveRootView.swift · ios_app/QBeats/UI/QLive/QLiveSession.swift ·
  ios_app/QBeats/UI/QLive/QLiveShowDetailView.swift
messaggio    : feat(qlive): END SHOW dal dettaglio — l'uscita da uno show vivo (A253+A254)
```

**CI — nome del workflow e run id, non solo «verde»:**

```
workflow  : iOS Signed Build
run id    : 33267183180
headSha   : 9c3616ee8555a1d35d07e6c98892ec5a0306df3a  (match pieno col commit)
conclusion: success
url       : https://github.com/19Bullfrog78/Q-BEATS/actions/runs/33267183180
durata    : 18:02:21Z → 18:06:04Z (~3m43s)
```

**Warning — confrontati col baseline, non solo contati:**

```
totale: 12 (baseline: 12 — INVARIATO)
composizione: 8 warning DISTINTI, 4 dei quali compaiono due volte — stesso insieme,
stesse righe, nessun warning nuovo introdotto da A253+A254+A255.
```

⚠️ **CHIUSO È SOLO DOPO IL DEVICE.** Questo commit prepara il collaudo di Mauro — non lo sostituisce. `TD-show-non-abbandonabile` resta 🔴 OPEN ALTA / 🚨 BLOCCANTE PALCO.

**Depositi di A255 (oltre ai quattro già a posto per il punto 1):**

```
REFERTO — questo stesso file, aggiornato (§9 marcato, §10 aggiunto)
  repo: HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
  E:  : FILE X CLAUDE.MD\HANDOFF\MISURE_CC_2026-08-29_A253-USCITA-DAL-DETTAGLIO.md
```

⛔ `BUGS_QBEATS.md` non ha un deposito HANDOFF separato in questo giro: è un canonico TRACCIATO, e la sua propagazione è il commit+push stesso (`9c3616e`, già su `origin/master`, pubblico) — non un mirror E:. Se serve uno snapshot per-versione (`STAMPA_…BUGS_QBEATS.md`), è un giro suo, non chiesto qui.

*A255-CHIUSURA-DELL-ATOMO-FINE*
