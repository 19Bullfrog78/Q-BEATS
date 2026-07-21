# RISPOSTE CD — 27/05/2026

**Da**: CD (Claude Design)
**Per**: CC chat principale, via Mauro
**Riferimento**: `BRIEF_CD_27_05_2026.md` (4 domande aperte per Fase 6-7 Bug 4 fix + ratifica ex-post Problema A)
**Apertura R1**: Letto `LIBRO_MASTRO_QBEATS.md` v13 del 27/05/2026 + brief CD 27/05 + memoria CD, procedo da lì.

---

## Risposte sintetiche R4

```
CD-Q1 = B (indicatore visivo Follower/Director nell'HEAD)
CD-Q2 = B con escape "START LOCAL" sempre visibile → nuovo deliverable CD-6
CD-Q3 = A (switch immediato al downbeat, zero animazione)
CD-Q4 = A (behavior confermato, nessuna osservazione di merito)
```

---

## CD-Q1 = B — Indicatore visivo persistente di ruolo cross-device

**Perché non A**: counter `bar 2 di N` da solo è un'**asimmetria silenziosa**. Il batterista Follower, in penombra a 2m, vede partire un counter "in avanti" senza segnale di contesto. Viola **Glanceability** (principio 1 CLAUDE.md): l'informazione del ruolo non deve richiedere inferenza ("perché parte da 2? ah giusto, sono Follower"). Sotto stress, l'inferenza salta.

**Perché non C**: ridisegnare il counter (es. "Director • bar 3 / Follower • bar 2") sovraccarica una zona dati già densa (bar counter + BPM + TS + lucchetto 🔒 dopo CD-0).

**Proposta B — badge `FOLLOWER` / `DIRECTOR` in HEAD**, *persistente* per tutta la durata della Vista LIVE quando un peer è attivo.

| Elemento | Spec |
|---|---|
| Posizione | HEAD top-left, accanto al cluster LED (Wi-Fi / BT / Link) |
| Tipografia | JBMono uppercase, letterspacing 2px, ~12pt × scaleFactor (stesso peso di "NEXT:") |
| Colore | Bianco opacity 0.55 (info neutra, **non alert**) |
| Stati | `FOLLOWER` / `DIRECTOR` / *(assente)* se Standalone |
| Composizione con LED Link | Il LED Link verde `#00c96e` esistente resta — il badge è label semantica del LED, non duplicato |

**Non usare arancio Q-Live né ambra**: arancio = "in play", ambra = ALERT. Il ruolo cross-device è **stato informativo**, non transizione critica — palette ruoli sezione 6 CLAUDE.md.

---

## CD-Q2 = B con escape — Vista WAITING FOR DIRECTOR + bottone START LOCAL

**Perché non A** (parte locale silenziosa): rompe il modello mentale. Se ho impostato mode Collaborative, il device deve **comportarsi da Collaborative**. Parte standalone in silenzio è il bug attuale travestito da feature — viola **Predictability** (principio 3 CLAUDE.md).

**Perché non C** (modal/popup): bloccare con un dialog al tap PLAY in contesto palco è inaccettabile. Il drummer ha bacchette in mano e luci in faccia; non legge un popup. Viola **Forgiveness + Stress-degradation** (principi 2 e 4).

**Proposta B con escape esplicito**:

```
┌─────────────────────────────────────┐
│         [LED Link pulsa lento]      │  ← cluster HEAD top
│                                     │
│                                     │
│      WAITING FOR DIRECTOR…          │  ← Inter-Black 52pt × scaleFactor
│                                     │     pulse 2.2s (stesso di .standby)
│         {song.name}                 │  ← song che parte appena Director arriva
│         (NEXT: prima sezione)       │
│                                     │
│                                     │
│        [  START LOCAL  ]            │  ← pillola outline 25px, secondaria
│        [    CANCEL    ]             │  ← torna a Select Setlist
└─────────────────────────────────────┘
```

Specifiche merito UX:
- **Background**: `#0e0e10` (Q-Live ambient, stessa famiglia di `.standby`)
- **Pulse** stesso ritmo del CD-1 cerimoniale (continuità linguistica visiva)
- **`START LOCAL`** sempre visibile, tap unico, niente conferma — il drummer ha potere di sblocco immediato se il Director non risponde (cavo audio saltato, batteria scarica, etc.)
- **Auto-transizione**: appena il Director parte, la Vista WAITING transiziona seamless in `.countIn` (4 click) o direttamente `.playing` allineata via Link
- **LED Link**: pulsa (cercando peer), diventa fisso quando connesso

**Nota su CD-1 cerimoniale**: la Vista WAITING FOR DIRECTOR è cugina di CD-1 ma **NON è CD-1**. CD-1 = pre-Play standalone con swipe-vetrina (Q10=A). CD-6 = pre-Play Collaborative bloccato in attesa. Restano due schermate distinte con UX simile ma trigger diverso — coerente con la logica R-CD5-01 (non fondere stati distinti).

---

## CD-Q3 = A — Switch immediato al downbeat, zero animazione

**Perché non B/C**: fade 300ms sul cambio sezione **viola le invarianti già ratificate per la Vista LIVE locale**:

- CLAUDE.md §14 (Slot metronomo): *"Flash ON/OFF netto, singolo frame (~16ms). Nessuna animazione, nessun decay."*
- CLAUDE.md §14 (Teleprompter): *"Il clock C++ conta le battute e cambia il testo gigante automaticamente al confine esatto. **Flash secco, nessuna dissolvenza.**"*

Il batterista Follower, al downbeat della nuova sezione, deve **leggere il nome nuovo nello stesso frame** in cui suona la prima nota. 300ms = ~1.5 battute a 200 BPM. Un fade copre proprio il momento in cui la lettura serve di più. Lo stesso vale per la microbar (cambia segmenti) e accent pattern (cambia LED downbeat) — devono switchare secchi al sample del downbeat.

**Principio UX coerente con il fade fine-setlist**:
- Fade 300-500ms a **fine vera** (L1.b rule) = OK, è un evento "fine", il drummer sta scaricando
- Switch sezione runtime = NON è fine, è **continuità musicale critica** — niente animazione

**Asimmetria locale vs cross-device sarebbe disorientante**: se in modalità Standalone il cambio sezione è flash secco e in modalità Collaborative è fade smooth, il drummer ha due esperienze diverse della stessa azione. Viola **Predictability**.

**Integrazione con CD-1 esteso swipe `<< X / Y >>`**: lo swipe è un'altra cosa (gesture utente, nav esplicita inter-song). Il sync sezione runtime è automatico (clock C++). Restano **entry separate** — usano linguaggi visivi diversi perché sono azioni diverse. Nessuna sovrapposizione.

---

## CD-Q4 = A — Behavior Problema A confermato come UX corretta

Il fix `441d543` fa esattamente quello che serve, e si **integra naturalmente** con CD-1 cerimoniale già ratificato (Q9/Q10 del 21/05). Sono lo stesso problema visto da due angoli:
- Problema A = "all'apertura Vista LIVE pre-Play, mostra il contenuto della setlist" (livello dato)
- CD-1 cerimoniale = "all'apertura Vista LIVE pre-Play, vesti la schermata con pulse + swipe + indicatore" (livello chrome)

Compongono. Non c'è conflitto.

**Sulle 3 osservazioni B che CC ha proposto**:

| Proposta CC | Ponderazione CD |
|---|---|
| Teleprompter grigio invece di bianco pre-Play | **No**. Il drummer deve leggere il nome della sezione in penombra a 2m. Abbassare contrasto pre-Play = peggiorare leggibilità per comunicare uno stato che è già comunicato dall'assenza di flash metronomo e dal pulse "TAP TO PLAY" del CD-1 cerimoniale |
| Counter `bar 0 di N` invece di `bar 1 di N` | **No**. `bar 1` è la battuta che sta per essere suonata — convenzione musicale standard (lo spartito ha bar 1 = prima battuta, mai bar 0). `bar 0` introdurrebbe un'invenzione semantica con nessun guadagno |
| Microbar invisibile pre-Play | **No**. La microbar **segmentata visibile** comunica `Section.repetitions` ("questa sezione ha 8 battute") già prima di partire. È informazione preziosa per il drummer che si prepara mentalmente. La differenza pre-Play vs playing è: segmenti visibili statici → segmenti che si accendono uno per uno. Già sufficiente |

**Confermo behavior corrente come UX congelata**.

---

## Implicazioni cross-team — diff letterali proposti per libro mastro v14

### Sez. 1 naming canonico — voci nuove da aggiungere

**"Componenti UI Vista LIVE"** (1 riga nuova):

| Termine | Definizione |
|---|---|
| `FOLLOWER` / `DIRECTOR` (badge HEAD ruolo) | Badge testuale persistente in HEAD top-left della Vista LIVE che comunica il ruolo del device quando un peer Link è attivo. Stati: `FOLLOWER` (segue Director via Link) / `DIRECTOR` (questo device è leader) / *(assente)* in Standalone. JBMono uppercase, ~12pt × scaleFactor, bianco opacity 0.55. Affianca semanticamente il LED Link verde esistente. Ratificato 27/05 CD-Q1=B |

**"App e modalità"** (1 riga nuova):

| Termine | Definizione |
|---|---|
| Vista WAITING FOR DIRECTOR | Schermata Q-Live cugina di CD-1 cerimoniale, attivata quando l'utente Follower tap PLAY senza Director peer attivo. Full-screen `#0e0e10`, "WAITING FOR DIRECTOR…" pulse 2.2s, bottoni `START LOCAL` + `CANCEL`. Transiziona seamless in `.countIn` / `.playing` appena Director si attiva. Ratificato 27/05 CD-Q2=B |

**"Tasti / azioni"** (2 righe nuove):

| Termine | Definizione | Stato |
|---|---|---|
| START LOCAL | Bottone in Vista WAITING FOR DIRECTOR che bypassa l'attesa e parte standalone | attivo (ratificato 27/05 CD-Q2=B) |
| CANCEL | Bottone in Vista WAITING FOR DIRECTOR che torna a Select Setlist | attivo (ratificato 27/05 CD-Q2=B) |

**"Stati LiveSession"** (1 riga nuova):

| Stato | Definizione | Note |
|---|---|---|
| `.waitingForDirector` | Stato attivato quando Follower tap PLAY senza Director peer attivo via Link. Mostra Vista WAITING FOR DIRECTOR. Transizione automatica a `.countIn` o `.playing` quando Director si attiva; transizione esplicita a `.playing` su `START LOCAL`; uscita a Select Setlist su `CANCEL`. Distinto da `.stopped` (CD-1 standalone) | attivo (ratificato 27/05 CD-Q2=B) |

### Sez. 2 decisioni ratificate — 4 righe nuove

| Data | Decisione | Proposta da | Doc ref | Stato | Superseded da |
|---|---|---|---|---|---|
| 2026-05-27 | CD-Q1=B — Bug 2 counter Collaborativo `bar 2 di N` accettato + introdotto badge HEAD `FOLLOWER` / `DIRECTOR` persistente per comunicare ruolo cross-device. Motivazione UX: counter `bar 2 di N` solo è asimmetria silenziosa che viola Glanceability; badge in HEAD risolve senza sovraccaricare il counter | Mauro + CD | sez. 4 CD-Q1 v13 + risposte CD 27/05 | attiva | — |
| 2026-05-27 | CD-Q2=B — Tap PLAY su Follower senza Director attivo → entra in nuovo stato `.waitingForDirector` con Vista WAITING FOR DIRECTOR + bottone `START LOCAL` (escape esplicito) + `CANCEL`. Motivazione UX: A viola Predictability (mode Collaborative parte standalone in silenzio), C viola Forgiveness/Stress-degradation (modal popup al palco). Nuovo deliverable CD-6 | Mauro + CD | sez. 4 CD-Q2 v13 + risposte CD 27/05 | attiva | — |
| 2026-05-27 | CD-Q3=A — Cambio sezione runtime Director → Follower con switch immediato secco al downbeat, zero animazione. Motivazione UX: fade 300ms violerebbe invarianti Vista LIVE locale (flash secco teleprompter, flash ON/OFF netto slot metronomo); asimmetria local vs cross-device viola Predictability | Mauro + CD | sez. 4 CD-Q3 v13 + risposte CD 27/05 | attiva | — |
| 2026-05-27 | CD-Q4=A — Ratifica ex-post Problema A fix `441d543` confermato come UX corretta senza modifiche. 3 osservazioni B proposte da CC (teleprompter grigio / counter `bar 0` / microbar invisibile) respinte con motivazione: peggiorerebbero leggibilità palco o introdurrebbero invenzioni semantiche senza guadagno. Behavior Problema A si compone naturalmente con CD-1 cerimoniale (Q9/Q10) | Mauro + CD | sez. 4 CD-Q4 v13 + risposte CD 27/05 + commit `441d543` | attiva | — |

### Sez. 3 deliverable in volo — 1 riga nuova

| ID | Titolo | Stato | Ultima mod | Note |
|---|---|---|---|---|
| CD-6 | Vista WAITING FOR DIRECTOR (Follower tap PLAY senza Director attivo via Link) | proposto, wireframe draft 1 da disegnare | 2026-05-27 | Ratificato 27/05 CD-Q2=B. Layout proposto: full-screen `#0e0e10`, pulse 2.2s "WAITING FOR DIRECTOR…", bottoni `START LOCAL` + `CANCEL`. Auto-transizione a `.countIn` / `.playing` su Director attivo |

### Sez. 4 domande aperte — rimuovere CD-Q1, CD-Q2, CD-Q3, CD-Q4

Tutte e 4 le domande risolte → ratificate in sez. 2. Sez. 4 torna placeholder (zero domande aperte post-v14).

---

## Note CC review (R3)

Possibili 🔧 obiezioni tecniche autoritative attese da CC:
- **CD-Q2=B / stato `.waitingForDirector`**: costo implementativo in Fase 6-7 (intreccio con causa root `AudioEngine.swift:442-446` + protocollo Wi-Fi proprietario futuro). Se CC valuta che il deliverable CD-6 va rimandato post-fix Bug 4, accetto rimando — la decisione UX resta congelata, l'implementazione si fa quando si fa.
- **CD-Q1=B / badge HEAD**: se conflitto layout con CD-0 (header redesign in review Mauro), badge va inserito SENZA invadere lo spazio del titolo canzone (vincolo CD-0 Punto 1 UX). Restano dimensioni piccole proprio per questo.
- **CD-Q3=A**: nessuna obiezione attesa, allineato con invarianti Layer 1 già ratificate.
- **CD-Q4=A**: nessuna obiezione attesa, fix già su master validato.

Disponibile a iterare se CC solleva 🔧 o 💡 di merito tecnico.

---

**Fine documento.**
