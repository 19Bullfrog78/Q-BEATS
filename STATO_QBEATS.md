# STATO_QBEATS — Libro mastro cross-team

**Versione:** 2
**Ultima modifica:** 2026-05-21
**Edit author:** CC chat principale 21/05/2026 (integrazione review CD del v1)
**Repo:** `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\`

---

## Scopo e ambito

Libro mastro condiviso tra **Mauro** (decisore), **CD** (Claude Design, UX/UI) e **CC** (Claude Code, codice + referee) per il progetto Q-BEATS.

Contiene **solo ratifiche cross-team**: prodotto, naming, processo, deliverable, gerarchia.

Le memorie locali (workspace CC: `feedback_qbeats_*.md`, `project_qbeats*.md`, ecc., e analoghe CD) restano nei rispettivi workspace — riguardano comportamento chat-locale, **non vivono qui**.

**Regola d'oro:** se una decisione non è in sezione 2 con `stato = attiva`, **non è ratificata**. Nessuna chat (CD o CC) può dichiarare ratificato qualcosa che non è qui.

---

## Protocollo di ingaggio (regole obbligatorie)

### R1 — Rituale d'apertura chat
Ogni nuova chat CD o CC che lavora su Q-BEATS apre dichiarando:

> *"Letto STATO_QBEATS.md v[N] del [data], procedo da lì."*

Se la chat propone qualcosa **senza** aver dichiarato la versione letta, Mauro è autorizzato a fermare la conversazione con:

> *"Leggi v[N] prima di proporre."*

Vale per chat CD nuove e chat CC nuove indistintamente.

### R2 — Una sola chat CC attiva alla volta
**Mai due chat CC simultaneamente** sullo stesso giorno su Q-BEATS. Le chat di Antigravity non si vedono fra loro: due chat in parallelo che editano questo file producono race condition con perdita di lavoro (chat A legge v17 → propone diff → applica → v18; chat B aveva letto v17 prima che A scrivesse → propone diff su v17 → applica → sovrascrive v18).

Se serve parallelizzare:
1. Chiudere la chat CC precedente con commit committato sul repo
2. Aprire la chat CC successiva, che dichiara R1 sulla versione aggiornata

Se proprio Mauro vuole parallelizzare (es. mentre CC lavora su CD-5 vuole un'altra chat su Vista LISTA), accetta che una delle due perda lavoro e fa merge manuale lui.

### R3 — Nessuna ratifica senza CC review
Ogni specifica/proposta CD deve passare da CC review prima della ratifica Mauro. CC restituisce review etichettata:
- 🔧 **posizione tecnica autoritativa** (architettura, fattibilità, RT, performance)
- 💡 **suggerimento UX non vincolante** (CD pondera per merito)
- ❓ **domanda Mauro**

Mauro ratifica con la review sotto gli occhi.

**Timeout:** 24h. Se CC non risponde entro 24h, Mauro decide comunque e la voce viene marcata in sezione 2 con `stato = ratificata-no-CC-review`. Rework eventuale dopo.

**Escape `no-CC-needed`:** Mauro può marcare una proposta `no-CC-needed` quando è chiaramente fuori scope tecnico (colori, copy non semantico, scelte cromatiche pure). In quel caso skip CC review e ratifica diretta.

### R4 — Ratifiche atomiche numerate
Proposte CD→Mauro (e CC→Mauro) sempre nel formato:

```
1. Decisione X
   A) opzione | B) opzione | C) opzione
2. Decisione Y
   A) sì | B) no | C) modifica con "..."
...
```

Mauro risponde `1=A, 2=sì, 3=modifica con "..."`. **Mai ratifiche in blocco di pacchetti multi-decisione.**

### R5 — Custode del file = CC, con diff letterali
CC mantiene il file. A fine turno (quando ci sono modifiche da applicare), CC propone diff **letterali** (riga aggiunta `+`, riga rimossa `-`) a Mauro. Mauro conferma con ratifica esplicita → CC scrive → CC committa subito sul repo con messaggio standard `STATO_QBEATS.md: vN — [decisione]`.

**Diff sempre letterali, mai descritti a parole.** Mauro vede esattamente la riga, non la parafrasi del custode. Protegge Mauro dal rischio che il custode mascheri un errore in un diff descritto.

**Contributi CD al file**: CD non ha accesso diretto al filesystem del repo (workspace separato, no tool di scrittura su disk). Quando CD ha contenuti da aggiungere — nuova riga in "Schermate ratificate", nuova sigla in naming UI, nuova domanda UX in sezione 4 — li prepara come testo nella sua chat con Mauro. Mauro li gira a CC. CC li applica come diff letterale a fine turno e committa dopo conferma esplicita Mauro. Stesso flusso vale per ogni nuova decisione di prodotto/UX che nasce in chat CD.

**Contributi CD su processo (R1–R6 e affini)**: CD non vota direttamente sul protocollo (è dominio CC + Mauro). Se CD ha spunti/segnalazioni su processo, li gira a Mauro come osservazione. Mauro decide se girarli a CC per valutazione di merito tecnico.

### R6 — Naming canonico vincolante
La sezione 1 di questo file è la fonte di verità per sigle, stati, nomi UI. Chi introduce una nuova sigla/stato/tasto in una proposta deve **prima aggiungerlo qui in sezione 1** (via diff letterale ratificato), oppure usare solo termini già presenti.

**Niente sigle inventate al volo** in chat. Sigle non in sezione 1 sono motivo valido per CC per fermare una proposta.

---

## Sezione 1 — Naming canonico

### App e modalità
| Termine | Definizione |
|---|---|
| Q-BEATS, Q-B | App iOS per batteristi live (metronomo + setlist teleprompter + backtrack) |
| Q-Stage | Modalità configurazione (contenitore SHOWS + Songs) |
| Q-Live | Modalità esecuzione palco |
| Vista LIVE | Schermata principale Q-Live (HEAD, teleprompter, microbar, LED, BPM, KILL BASE, ...) |
| Vista LISTA | Schermata alternativa Q-Live (lista canzoni — Fase 4) |
| Vista Emergenza | Schermata fallback Q-Live (Fase 4, non iniziata) |
| Bivio, BivioBoard | Schermata scelta Q-Stage / Q-Live all'avvio app |
| Q-Stage > Songs | Sezione di Q-Stage: catalogo canzoni (entità dati = `Song`) |
| Q-Stage > SHOWS | Sezione di Q-Stage: libreria delle setlist (entità dati = `Setlist` dentro `SHOWS`) |
| Q-Stage > MEDIA | Sezione di Q-Stage: libreria backtrack (futuro: video HDMI) |
| Select Setlist | Schermata picker Q-Live per scegliere setlist da caricare |

### Modello dati
| Termine | Definizione |
|---|---|
| SHOWS | Libreria-contenitore di Setlist |
| Setlist | Singola entità dentro SHOWS, contiene Songs in ordine |
| Song | Canzone, contiene Section in ordine |
| Section | Sezione di una canzone (cambio BPM/BPB/accent/teleprompter) |

### Componenti UI Vista LIVE
| Termine | Definizione |
|---|---|
| LED | Luce metronomo che pulsa al beat |
| Teleprompter | Testo gigante centro schermo = `Section.name` della sezione corrente |
| Microbar (trattini / battute / segmenti) | Barretta segmentata sopra teleprompter (N segmenti = N battute della sezione) |
| MacroBar | Barra macro progresso canzone |
| HEAD | Layer alto Vista LIVE (BPM, time signature, nome canzone) |
| FineSetlistView | Schermata fine setlist con bottoni "FINE SHOW" / "TORNA AGLI SHOWS" |
| `<< X / Y >>` | Indicatore posizione corrente nella setlist + segnale visivo possibilità swipe orizzontale (proposto, CD-1 ext + CD-5) |

### Tasti / azioni
| Termine | Definizione | Stato |
|---|---|---|
| KILL BASE | Tasto che zittisce il backtrack | attivo (brief Fase 4 19/05) |
| KILL TRACK | Rinomina proposta in CD-5 di KILL BASE | **proposto — IN CONFLITTO con brief Fase 4 (Q5 sez. 4)** |
| PROSSIMA | Tasto avanza canzone | attivo |
| NEXT | Rinomina proposta in CD-5 di PROSSIMA | **proposto — citato come "ratificato" in CD-5 ma non verificabile in brief 19/05 / CLAUDE.md V23 / memorie CC (Q6 sez. 4)** |
| STOP | Tasto stop esecuzione | attivo |
| FINE SHOW | Bottone fine setlist (FineSetlistView) | attivo (ratificato 19/05) |
| TORNA AGLI SHOWS | Bottone fine setlist (FineSetlistView) | attivo (ratificato 19/05) |
| Resume from {section.name} | Bottone schermo STOP a metà song: riparte da inizio sezione bookmarkata | proposto (CD-5) |
| Restart {song.name} | Bottone schermo STOP a metà song: ricomincia song corrente | proposto (CD-5) |
| Restart Setlist | Bottone CD-3 in `.fineSetlist`: ricomincia la setlist appena suonata | proposto (CD-3) |
| BACK TO SHOWS | Rinomina inglese di "TORNA AGLI SHOWS" | proposto (rename pendente Q5 / R-CD5-10) |
| END SHOW | Rinomina inglese di "FINE SHOW" | proposto (rename pendente Q5 / R-CD5-10) |

### Stati LiveSession
| Stato | Definizione | Note |
|---|---|---|
| `.stopped` | **definizione ambigua** | Doppio significato emerso in CD-5 (Q4 sez. 4): CD-1 iniziale (stato all'apertura Vista LIVE) vs swipe nav post-STOP. Da chiarire con discriminator o flag esterno. |
| `.standby` | Overlay tra canzoni | attivo |
| `.countIn` | Count-in pre-canzone | attivo (oggi solo tra canzoni — Q3 sez. 4 chiede se estendere a resume post-STOP) |
| `.playing` | Esecuzione in corso | attivo |
| `.loopActive` | Loop attivo su sezione | attivo |
| `.stoppedMidSong` | Stato STOP a metà song con bookmark (rinomina proposta da CD-5 di `.overlayStop`, mai entrato in codice) | proposto (CD-5) — possibile risposta a Q4 sez. 4 (introduce stato distinto invece di discriminator/flag su `.stopped`) |

### Schermate ratificate (dominio CD)

Sotto-tabella popolata da CD via flusso R5 ("Contributi CD al file"). Una riga per schermata Q-Live / Q-Stage / overlay. Layout `congelato` = mockup approvato da Mauro, CC autorizzato a implementare senza rework UX.

| Schermata | Stato playback associato | Layout congelato | Mockup ref | Note |
|---|---|---|---|---|
| _(da popolare CD)_ | — | — | — | — |

### Tecnologie / debiti
| Termine | Definizione |
|---|---|
| LinkKit 4.0 | SDK Ableton Link |
| TD #N | Tech debt numerato (vedi memoria CC `project_qbeats.md` per dettaglio) |

---

## Sezione 2 — Decisioni ratificate

Colonna `stato`: `attiva` | `superseded` | `revocata` | `ratificata-no-CC-review`.
**Le righe non si cancellano mai.** Si marcano `superseded` con riferimento alla decisione che le sostituisce.

| Data | Decisione | Proposta da | Doc ref | Stato | Superseded da |
|---|---|---|---|---|---|
| 2026-04-29 | Tasto LOOP display: `LOOP` / `LOOP·N` / `LOOP·∞` | Mauro | memoria CC `project_qbeats.md` | attiva | — |
| 2026-05-07 | Standard quantized launch Link: Q-B parte immediato quando phase=0 (no 1 bar wait) | Mauro + AI esterna | memoria CC `project_qbeats.md` | attiva | — |
| 2026-05-07 | Protocollo review codice: diff testuale completo in chat prima del push su file critici (`LinkEngine.mm`, `AudioEngine.swift`, `MetronomeDSP.cpp`) | Mauro | memoria CC | attiva | — |
| 2026-05-12 | Architettura audio: NO `AVAudioSinkNode` su playerNode, SÌ `installTap` su `mainMixerNode` | Mauro + CC | memoria CC | attiva | — |
| 2026-05-15 | Peer di test L1.b: Tick (non più Soundbrenner) | Mauro | memoria CC `project_qbeats_test_peer.md` | attiva | — |
| 2026-05-17 | Closure `onSectionEnd` resta Layer 3, niente toccare AudioEngine/MetronomeDSP/thread RT per fix UI | Mauro + AI esterna + CC | memoria CC | attiva | — |
| 2026-05-19 | LICENSE proprietario "All Rights Reserved" in root repo (Mauro Martintoni 2024-2026, contatto `di_tutto@icloud.com`) | Mauro | commit `071f4f2` | attiva | — |
| 2026-05-19 | 5 punti UX brief Fase 4: (1) header layout, (2) humanized click V2, (3) standby UI dettagli, (4) countdown configurabile strategia, (5) pulsantiera Vista LIVE CD-4 | Mauro | `ARCHIVIO.MD/19_05_2026/QBEATS_CD_Brief_Fase4_19_05_2026.md` + memoria CC `project_qbeats_brief_19_05_2026.md` | attiva | — |
| 2026-05-19 sera | Rename UI labels: STUDIO → Q-STAGE, LIVE → Q-Live, Setlist → Shows, Canzoni → Songs | Mauro | commit `63831de` | attiva (**in attesa test su device**) | — |
| 2026-05-19 sera | Default name UI: "New Show" / "New Song" | Mauro | commit `63831de` | attiva (in attesa test su device) | — |
| 2026-05-19 sera | Pulsantiera CD-4 FineSetlistView: "FINE SHOW" / "TORNA AGLI SHOWS" | Mauro | commit `63831de` | attiva (in attesa test su device) | — |
| 2026-05-19 sera | Modello dati invariato (struct, JSON, var, metodi, log, commenti) nel rename UI — solo stringhe UI rinominate | Mauro + CC | commit `63831de` | attiva | — |
| 2026-05-20 | TD #44 — causa interna `libLinkKit.a` 4.0 confermata. NON riaprire indagini su codice Q-BEATS | Mauro + CC | memoria CC `project_qbeats_td44.md` + `ARCHIVIO.MD/20_05_2026/TD44_REPORT_20_05_2026.md` (commit `fe17817`) | attiva | — |
| 2026-05-20 | TD #44 — Soluzione B (dual bundle ID) **SCARTATA** commerciale. Ammessa solo per test dev temporanei | Mauro | memoria CC + report committato | attiva | — |
| 2026-05-20 | TD #44 — Soluzione C (protocollo Wi-Fi proprietario master/client) = strada commerciale definitiva, collocazione Fase 6-7 post-v1. Coesiste con Link/BT MIDI/USB. Riusa Task D infrastructure, no Layer 1-2 changes | Mauro | memoria CC + report committato | attiva | — |
| 2026-05-20 | TD #44 — Workaround v1 fino a fix: 1 QB + Soundbrenner come peer Link | Mauro | memoria CC | attiva | — |
| 2026-05-20 | Gerarchia 3 ruoli: Mauro decisore / CD UX-UI / CC codice + referee. CC suggerisce UX con 3 etichette (🔧 tecnico autoritativo / 💡 suggerimento UX non vincolante / ❓ domanda Mauro) ma non vincolante. CD pondera CC per merito tecnico, non per disciplina di processo | Mauro | memoria CC `feedback_qbeats_gerarchia_ruoli.md` | attiva | — |
| 2026-05-20 | Semantica gerarchia dati: `SHOWS → Setlist A/B/C → Song 1/2/...` (SHOWS = contenitore-libreria, Setlist = singola entità dentro SHOWS, Songs = canzoni dentro Setlist) | Mauro | conversazione 20/05/2026 chat CC principale | attiva | — |
| 2026-05-21 | Istituito `STATO_QBEATS.md` come libro mastro cross-team (questo file) | Mauro + CC + CD | questa chat CC 21/05/2026 | attiva | — |
| 2026-05-21 | Protocollo R1–R6 (rituale apertura / 1 chat CC alla volta / CC review obbligatoria con timeout 24h e escape `no-CC-needed` / ratifiche atomiche numerate / custode CC con diff letterali / naming canonico vincolante) | Mauro + CC + CD | questa chat CC 21/05/2026, sezione "Protocollo di ingaggio" sopra | attiva | — |

---

## Sezione 3 — Deliverable in volo

| ID | Titolo | Stato | Ultima mod | Note |
|---|---|---|---|---|
| CD-0 | Schermata Q-Stage configurazione | draft 1 consegnato a Mauro | 2026-05-20 | In review Mauro |
| CD-1 | Standby "vestito" inizio Vista LIVE (esteso 19/05) | proposto | 2026-05-19 | Backlog |
| CD-2 | Perimetro rosso sfumato pulsante in overlay standby | proposto | 2026-05-17 | Backlog |
| CD-3 | Bottone "Ricomincia setlist" a fine setlist | proposto | 2026-05-17 | Backlog |
| CD-4 | Pulsantiera Vista LIVE 4 quadranti + cerchio | draft 1 consegnato | 2026-05-20 | In review Mauro |
| CD-5 | Schermata STOP a metà song | review CC fatta 20/05 (8 domande aperte + 10 ratifiche da confermare) | 2026-05-20 | Bloccato su sezione 4 di questo file |
| Fase 4 | Vista LISTA | brief Fase 4 ratificato 19/05 | 2026-05-19 | Batch 2 dopo CD-0/4 |
| Fase 4 | Vista Emergenza | non iniziato | — | Backlog |
| Fase 6.1 | UI MIDI Learn | non iniziato | — | Backlog |
| Fase 7 | HDMI Stage View | non iniziato | — | Backlog |
| Fase 8 | Settings G1-G8 | non iniziato | — | Backlog |
| TD #44 | Bug Link discovery QB↔QB | email Ableton inviata 19/05, response deadline 27/05/2026 | 2026-05-19 | Workaround v1 attivo. Decisioni architetturali sez. 2 |

---

## Sezione 4 — Domande aperte

Le domande sono numerate. Mauro risponde nel formato `Q1=A, Q2=sì, R-CD5-03=modifica con "..."`. Quando una risposta arriva, CC sposta la voce in sezione 2 con la data di ratifica e marca qui la voce come `risposta data il [data]`.

### Domande CC → Mauro su CD-5 (poste 2026-05-20)

| ID | Domanda | In attesa di |
|---|---|---|
| Q1 | Confermi le 10 ratifiche dichiarate in spec CD-5? Vanno ratificate una per una (vedi sub-voci R-CD5-01 … R-CD5-10 sotto) | Mauro |
| Q2 | Bookmark v1 = solo `(songID, sectionID)` senza `barInSection` (beat-granular)? La forma beat-granular richiederebbe modifica Layer 1 e violerebbe il non-goal di CD-5. A) sì solo (songID, sectionID) / B) include barInSection (con modifica Layer 1) | Mauro |
| Q3 | Resume dopo STOP a metà song passa per count-in oppure direttamente a `.playing`? Memoria CC: count-in oggi è solo tra canzoni. CD-5 sez. 4.2 dichiara "Resume → countIn → playing". A) sì countIn anche al resume (nuova scelta UX) / B) no, bypass diretto a `.playing` / C) errore documentale CD-5 da correggere | Mauro |
| Q4 | Stato `.stopped` con doppio significato (CD-1 iniziale vs swipe nav post-STOP): A) discriminator nell'enum (es. `.stopped(.initial)` / `.stopped(.swipeNav)`) / B) flag esterno separato / C) altra soluzione | Mauro |
| Q5 | KILL BASE vs KILL TRACK: brief Fase 4 (19/05) ratifica "muscle-memory, mantenere KILL BASE". CD-5 propone rename in KILL TRACK. A) tengo KILL BASE / B) passo a KILL TRACK / C) modifica con [altro] | Mauro |
| Q6 | "Referee" citato da CD-5: nella gerarchia ratificata 20/05 io (CC) sono CC + referee combinati. A) CD si semplifica a 3 ruoli (Mauro / CD / CC), referee è incluso in CC / B) tieni referee separato per il futuro | Mauro |

### Domande CC/CD → Mauro su decisioni UX 20-21/05 (formalizzate 2026-05-21 da review CD del file v1)

Queste 4 decisioni sono state ratificate **verbalmente** in chat CD–Mauro nelle sessioni 20-21/05/2026 ma non risultano in sezione 2 di questo file. Per la Regola d'oro vanno riconfermate via R4 prima di considerarle attive.

| ID | Domanda | In attesa di |
|---|---|---|
| Q7 | Schermo STOP a metà song è **full-screen modale** che sostituisce Vista Q-Live (NON overlay parziale), con pulsantiera CD-4 **nascosta** durante questo stato (eccezione esplicita a CD-4 del 19/05)? A) sì / B) no, è overlay parziale / C) modifica con "..." | Mauro |
| Q8 | Layout schermo STOP: bottone "Resume from {section.name}" + bottone "Restart {song.name}" + zona swipe orizzontale + indicatore `<< X / Y >>` (mockup grezzo 20/05)? A) sì come da mockup / B) no, layout diverso (specificare) / C) modifica con "..." | Mauro |
| Q9 | CD-1 originale (proposto 17/05, standby cerimoniale all'apertura Vista LIVE, senza swipe) viene **esteso** con: zona swipe orizzontale + indicatore `<< X / Y >>` per discoverability. Approvi l'estensione? A) sì, applico estensione a CD-1 / B) no, mantengo CD-1 originale senza swipe / C) modifica con "..." | Mauro |
| Q10 | Dopo swipe in CD-1 il sistema cosa fa? A) **Opzione 1** — resta in CD-1 cerimoniale, cambia solo il nome song mostrato (la schermata cerimoniale è una "vetrina" che si sfoglia) / B) **Opzione 2** — esce da CD-1 e entra in `.standby` con overlay nome song (lo swipe agisce come "salto canzone" che porta nello stato di transizione standard tra brani) / C) modifica con "..." | Mauro |

### Domande residue β (di CD originali, da CD-5)

| ID | Domanda | Raccomandazione CD | In attesa di |
|---|---|---|---|
| β.1 | Bookmark sopravvive uscita da Vista Q-Live? | no, cancellato | Mauro |
| β.2 | Bookmark sopravvive cambio setlist? | no, cancellato | Mauro |

### 10 ratifiche dichiarate da spec CD-5 (in attesa conferma Mauro)

Queste sono dichiarate da CD-5 ma **mai confermate in chat con CC**. Vanno ratificate riga per riga prima di considerarle attive. CC non ha accesso al testo letterale del documento CD-5 nella memoria di questa chat.

**Azione richiesta**: Mauro o CD integra il testo letterale delle 10 voci dalla spec CD-5 (sezione "Ratifiche") per consentire ratifica riga per riga. CC aggiornerà la tabella sotto con i testi letterali al prossimo turno con diff letterale.

| ID | Voce CD-5 (paraphrased / da estrarre letterale) | In attesa di |
|---|---|---|
| R-CD5-01 | [testo letterale da estrarre da spec CD-5 — sezione "Ratifiche" voce 01] | Mauro |
| R-CD5-02 | [testo letterale da estrarre — voce 02] | Mauro |
| R-CD5-03 | TL `▶ PLAY` disabled durante STOP a metà song (vs raccomandazione CC = bottone Resume nominale) | Mauro |
| R-CD5-04 | [testo letterale da estrarre — voce 04] | Mauro |
| R-CD5-05 | [testo letterale da estrarre — voce 05] | Mauro |
| R-CD5-06 | [testo letterale da estrarre — voce 06] | Mauro |
| R-CD5-07 | [testo letterale da estrarre — voce 07] | Mauro |
| R-CD5-08 | [testo letterale da estrarre — voce 08] | Mauro |
| R-CD5-09 | [testo letterale da estrarre — voce 09] | Mauro |
| R-CD5-10 | Lingua UI = inglese universale per tutta l'app | Mauro |

### 💡 Note CC su CD-5 — suggerimenti UX non vincolanti

- TL "▶ PLAY" disabled può risultare ambiguo per il batterista in palco: alternativa = bottone Resume nominale (etichetta esplicita invece di stato disabled).
- STOP cancella loop counter durante `.loopActive`: verificare con CD se voluto.

### Conflitti di ratifica già identificati

- **KILL BASE vs KILL TRACK** (vedi Q5). Una delle due ratifiche perde. Mauro decide.
- **PROSSIMA → NEXT**: CD-5 dichiara "già ratificato" ma CC non trova traccia in brief Fase 4 (19/05) / CLAUDE.md V23 / memorie CC. Voce trattata come `proposta`, non ratificata, fino a verifica documentale (vedi Q6 implicito + naming sez. 1 tasti).

---

## Sezione 5 — Riferimenti e collegamenti

- **Memoria CC** (workspace `C:\Users\BULLFROG\.claude\projects\C--Users-BULLFROG\memory\`): contiene `MEMORY.md` index + memorie dedicate (`project_qbeats.md`, `project_qbeats_td44.md`, `project_qbeats_brief_19_05_2026.md`, `feedback_qbeats_gerarchia_ruoli.md`, …). Comportamento chat-locale CC. **Non vive qui.**
- **Memoria CD** (workspace separato): comportamento chat-locale CD. **Non vive qui.**
- **Repo Q-BEATS**: `C:\Users\BULLFROG\Desktop\ANTIGRAVITY\Q-BEATS\` — GitHub: `https://github.com/19Bullfrog78/Q-BEATS` branch `master`. HEAD corrente: `fe17817`.
- **BOX5 più recente**: `ARCHIVIO.MD/18_05_2026/BOX5_V23_18_05_2026.md`.
- **Brief Fase 4**: `ARCHIVIO.MD/19_05_2026/QBEATS_CD_Brief_Fase4_19_05_2026.md` (locale, decidere se committare).
- **Roadmap sblocco app M1-M8**: `ARCHIVIO.MD/19_05_2026/ROADMAP_SBLOCCO_APP_19_05_2026.md` (locale, decidere se committare).
- **TD #44 report**: `ARCHIVIO.MD/20_05_2026/TD44_REPORT_20_05_2026.md` (committato in `fe17817`).
- **Registro test Audacity ground truth**: `ARCHIVIO.MD/SENZA COLLOCAZIONE/REGISTRO_TEST_AUDACITY_V1.md`.

---

## Sezione 6 — Storico versioni file

| Versione | Data | Edit author | Modifiche principali |
|---|---|---|---|
| 1 | 2026-05-21 | CC chat principale 21/05 | Creazione iniziale del file. Scopo + ambito + Regola d'oro. Protocollo R1–R6 (R5 esteso con "Contributi CD al file" + "Contributi CD su processo" dopo correzione ruoli CD del 21/05). Naming canonico (modalità, modello dati, componenti UI, tasti, stati LiveSession, schermate ratificate scheletro vuoto per popolamento CD, tecnologie). 20 decisioni ratificate (2026-04-29 → 2026-05-21). 12 deliverable in volo. 18 domande aperte (6 Q su CD-5 + 2 β residue + 10 R-CD5 da confermare). Note CC + conflitti di ratifica identificati. |
| 2 | 2026-05-21 | CC chat principale 21/05, integrazione review CD | Naming UI completato post-review CD del v1: aggiunti 9 termini in sez. 1 — `Q-Stage > Songs` / `Q-Stage > SHOWS` / `Q-Stage > MEDIA` / `Select Setlist` in "App e modalità"; `Resume from {section.name}` / `Restart {song.name}` / `Restart Setlist` / `BACK TO SHOWS` / `END SHOW` in "Tasti / azioni"; `<< X / Y >>` in "Componenti UI Vista LIVE"; `.stoppedMidSong` in "Stati LiveSession". Aperte 4 nuove domande Q7-Q10 in sez. 4 per ratificare formalmente le decisioni UX 20-21/05 (schermo STOP full-screen modale + pulsantiera CD-4 nascosta; layout STOP Resume+Restart+swipe+`<< X / Y >>`; CD-1 esteso con swipe + indicatore; opzione 1 dopo swipe = resta CD-1 cambia solo nome song). Nessuna modifica a sez. 2, sez. 3, sez. 5 e protocollo R1-R6. |

---

**Fine documento.**
