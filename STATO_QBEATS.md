# STATO_QBEATS — Libro mastro cross-team

**Versione:** 7
**Ultima modifica:** 2026-05-21
**Edit author:** CC chat principale 21/05/2026 sera (rollback A su v6 — rimosse righe operative CD interne mescolate per errore: "Roadmap batch CD" in sez. 2 + tag "Batch CD 21/05 — posizione N" in sez. 3. Mantenuta sola riga cross-team "Semantica Layout congelato stretta")
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
| Vista LIVE | Schermata principale Q-Live (HEAD, teleprompter, microbar, LED, BPM, KILL TRACK, ...) |
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
| `<< X / Y >>` | Indicatore posizione corrente nella setlist + segnale visivo possibilità swipe orizzontale (attivo, ratificato 21/05 Q8=A / Q9=A) |

### Tasti / azioni
| Termine | Definizione | Stato |
|---|---|---|
| KILL BASE | Tasto che zittisce il backtrack (label italiana storica) | superseded da Q5=B / R-CD5-07 (21/05) |
| KILL TRACK | Tasto che zittisce il backtrack (rinomina di KILL BASE) | attivo (ratificato 21/05 Q5=B / R-CD5-07) |
| PROSSIMA | Tasto avanza canzone (label italiana storica) | superseded da Q11=A (21/05) |
| NEXT | Tasto avanza canzone (rinomina di PROSSIMA) | attivo (ratificato 21/05 Q11=A). Nota: PROSSIMA mai entrata in codice Swift — Grep mirato 21/05 zero match, niente cascading rename codice |
| STOP | Tasto stop esecuzione | attivo |
| FINE SHOW | Bottone fine setlist (FineSetlistView), label italiana storica | superseded da R-CD5-10 (21/05, UI tutta inglese) |
| TORNA AGLI SHOWS | Bottone fine setlist (FineSetlistView), label italiana storica | superseded da R-CD5-10 (21/05, UI tutta inglese) |
| Resume from {section.name} | Bottone schermo STOP a metà song: riparte da inizio sezione bookmarkata | attivo (ratificato 21/05 Q8=A) |
| Restart {song.name} | Bottone schermo STOP a metà song: ricomincia song corrente | attivo (ratificato 21/05 Q8=A) |
| Restart Setlist | Bottone CD-3 in `.fineSetlist`: ricomincia la setlist appena suonata | proposto (CD-3) |
| BACK TO SHOWS | Bottone fine setlist (FineSetlistView): torna alla libreria SHOWS | attivo (ratificato 21/05 R-CD5-10) |
| END SHOW | Bottone fine setlist (FineSetlistView): marca fine performance | attivo (ratificato 21/05 R-CD5-10) |
| EMERGENZA (BR pulsantiera CD-4) | Sigla italiana storica, rinominata EMERGENCY 21/05 per coerenza R-CD5-10 | superseded da Q12=A (21/05) |
| EMERGENCY (BR pulsantiera CD-4) | Bottone in basso-destra della pulsantiera CD-4 che fa switch da Vista Q-Live a Vista LISTA (ex Vista Emergenza). Sempre visibile durante `.playing` / `.standby`, nascosto durante `.stoppedMidSong` (Q7=A) | attivo (brief Fase 4 19/05, label inglese ratificata 21/05 Q12=A) |

### Stati LiveSession
| Stato | Definizione | Note |
|---|---|---|
| `.stopped` | Stato CD-1 cerimoniale (apertura Vista LIVE + swipe-vetrina di Q10=A). Distinto da `.stoppedMidSong` (R-CD5-01 / R-CD5-04) | attivo (ratificato 21/05) |
| `.standby` | Overlay tra canzoni (transizione standard tra song N e song N+1). NON entrato durante swipe in CD-1 per Q10=A | attivo |
| `.countIn` | Count-in pre-canzone (4 click). Attivato in: (1) inizio prima song setlist, (2) tra canzoni, (3) Resume dopo STOP a metà song (ratificato 21/05 Q3=A — ri-sincronizzazione mentale batterista con band) | attivo |
| `.playing` | Esecuzione in corso | attivo |
| `.loopActive` | Loop attivo su sezione. Cancellato (reset) su STOP intra-sessione per R-CD5-05 (21/05) | attivo |
| `.stoppedMidSong` | Stato STOP a metà song con bookmark. Distinto da `.stopped` (R-CD5-01). Nome canonico ratificato 21/05 da R-CD5-02 (era `.overlayStop` solo proposto, mai entrato in codice) | attivo (ratificato 21/05 Q4=A + R-CD5-01 + R-CD5-02) |

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
| 2026-05-21 | Q7=A — Schermo STOP a metà song è full-screen modale che sostituisce Vista Q-Live (NON overlay parziale), con pulsantiera CD-4 nascosta durante questo stato (eccezione esplicita a CD-4 del 19/05) | Mauro + CD | sez. 4 Q7 v2 + questa chat 21/05 | attiva | — |
| 2026-05-21 | Q8=A — Layout schermo STOP: bottone "Resume from {section.name}" + bottone "Restart {song.name}" + zona swipe orizzontale + indicatore `<< X / Y >>` (mockup grezzo 20/05) | Mauro + CD | sez. 4 Q8 v2 + questa chat 21/05 | attiva | — |
| 2026-05-21 | Q9=A — CD-1 originale (17/05) viene esteso con zona swipe orizzontale + indicatore `<< X / Y >>` per discoverability | Mauro + CD | sez. 4 Q9 v2 + questa chat 21/05 | attiva | — |
| 2026-05-21 | Q10=A — Dopo swipe in CD-1: resta CD-1 cerimoniale, cambia solo nome song (vetrina che si sfoglia, NON entra in `.standby`) | Mauro + CD | sez. 4 Q10 v2 + questa chat 21/05 | attiva | — |
| 2026-05-21 | Q5=B / R-CD5-07 — Tasto che zittisce il backtrack si chiama KILL TRACK (rinomina di KILL BASE). Supersede parziale ratifica 19/05 punto 5 brief Fase 4 limitatamente alla label del tasto | Mauro + CD | sez. 4 Q5 v2 + R-CD5-07 + questa chat | attiva | — |
| 2026-05-21 | Q6=A — Gerarchia 3 ruoli (Mauro / CD / CC), "referee" incluso in CC. Non figura separata | Mauro | sez. 4 Q6 v2 + questa chat | attiva | — |
| 2026-05-21 | R-CD5-10=A — UI tutta in inglese (universale, anche label future Settings / MIDI Learn / ecc.). Implica rename FINE SHOW → END SHOW, TORNA AGLI SHOWS → BACK TO SHOWS. Supersede parziale ratifica 19/05 (pulsantiera CD-4 FineSetlistView) limitatamente alle label | Mauro + CD | sez. 4 R-CD5-10 v2 + questa chat | attiva | — |
| 2026-05-21 | Q3=A — Count-in (4 click) sempre al Resume dopo STOP a metà song. Motivo Mauro: ri-sincronizzazione mentale del batterista con la band, necessaria per partenza uniforme | Mauro | sez. 4 Q3 v2 + questa chat | attiva | — |
| 2026-05-21 | Q2=A — Bookmark v1 a granularità sezione: solo `(songID, sectionID)`. NO `barInSection` (no modifica Layer 1 / C++ DSP) | Mauro | sez. 4 Q2 v2 + questa chat | attiva | — |
| 2026-05-21 | Q1=A — Le 10 ratifiche dichiarate in spec CD-5 sono confermate. Ratificate individualmente in questa sessione (R-CD5-01...10 sotto) | Mauro | sez. 4 Q1 v2 + questa chat | attiva | — |
| 2026-05-21 | Q4=A — `.stoppedMidSong` introdotto come stato distinto da `.stopped` (NON discriminator/flag su `.stopped`). Decisione tecnica delegata a CC, ratificata da Mauro come scelta architetturale | Mauro + CC | sez. 4 Q4 v2 + questa chat | attiva | — |
| 2026-05-21 | β.1=A — Bookmark cancellato all'uscita da Vista Q-Live (no stato latente persistito) | Mauro + CD | sez. 4 β.1 v2 + questa chat | attiva | — |
| 2026-05-21 | β.2=A — Bookmark cancellato al cambio setlist (anche moot per R-CD5-06: swipe nav non cambia mai setlist, quindi cambio setlist richiede uscita Q-Live → β.1 copre già il caso) | Mauro + CD | sez. 4 β.2 v2 + questa chat | attiva | — |
| 2026-05-21 | R-CD5-01 — NON fondere `.stopped` e `.stoppedMidSong`: restano stati distinti nel codice e nell'UX | CD | spec CD-5 sez. 3 (girata da Mauro in chat 21/05) | attiva | — |
| 2026-05-21 | R-CD5-02 — Rename codice (mai entrato in produzione) `.overlayStop` → `.stoppedMidSong` come nome canonico | CD | spec CD-5 sez. 3 | attiva | — |
| 2026-05-21 | R-CD5-04 — CD-1 (apertura Vista Q-Live) resta schermata distinta da `.stoppedMidSong`: sono due stati con UX diverse, non si fondono | CD | spec CD-5 sez. 3 | attiva | — |
| 2026-05-21 | R-CD5-05 — Loop reset su STOP intra-sessione: STOP cancella `.loopActive` (loop counter azzerato) | CD | spec CD-5 sez. 3 | attiva | — |
| 2026-05-21 | R-CD5-06 — Swipe nav song avviene sempre dentro la setlist corrente, mai cambia setlist | CD | spec CD-5 sez. 3 | attiva | — |
| 2026-05-21 | R-CD5-08 — CD-5 (schermata STOP a metà song) è formalmente nuovo deliverable del brief Fase 4 (era stato aggiunto nella sessione 20/05 ma non era nel brief 19/05) | CD | spec CD-5 sez. 3. ⚠️ Implica aggiornamento documento `ARCHIVIO.MD/19_05_2026/QBEATS_CD_Brief_Fase4_19_05_2026.md` (dominio CD) | attiva | — |
| 2026-05-21 | R-CD5-09 — Bookmark cross-song = β: conservato in RAM per la sessione, sopravvive cross-song dentro stessa setlist, cancellato a uscita Q-Live (β.1) e cambio setlist (β.2) | CD | spec CD-5 sez. 3 | attiva | — |
| 2026-05-21 | Q11=A — Tasto avanza canzone rinominato PROSSIMA → NEXT (coerente con R-CD5-10 UI tutta inglese). PROSSIMA mai entrata in codice Swift (Grep mirato 21/05 zero match), niente cascading rename codice | Mauro | sez. 4 Q11 v3 + questa chat 21/05 | attiva | — |
| 2026-05-21 | Q12=A — Cascading rename Swift R-CD5-10 completo: 30 stringhe italiane in 4 file produzione (`BackupView.swift`, `ImportView.swift`, `SettingsView.swift`, `BarCounterView.swift`) rinominate in inglese. DebugView escluso (scaffold dev). Sigla EMERGENZA → EMERGENCY in sez. 1 libro mastro. Implementato in commit Swift `cf3f0b5` | Mauro + CD + CC | sez. 4 Q12 v4 + questa chat 21/05 + commit `cf3f0b5` | attiva | — |
| 2026-05-21 sera | Semantica colonna "Layout congelato" (sez. 1 sotto-tabella "Schermate ratificate") resta stretta: "mockup approvato Mauro, CC autorizzato a implementare senza rework UX". Niente colonna aggiuntiva "Stato draft". Schermate in stato draft 1 / draft 2 / in review NON entrano in sotto-tabella finché non congelate | Mauro + CD + CC | questa chat 21/05 sera, decisione Extra=A | attiva | — |

---

## Sezione 3 — Deliverable in volo

| ID | Titolo | Stato | Ultima mod | Note |
|---|---|---|---|---|
| CD-0 | Schermata Q-Stage configurazione | draft 1 consegnato a Mauro | 2026-05-20 | In review Mauro |
| CD-1 | Standby "vestito" inizio Vista LIVE — esteso con swipe orizzontale + indicatore `<< X / Y >>` per discoverability (Q9=A) | proposto, estensione ratificata 21/05 | 2026-05-21 | Backlog. Comportamento swipe = vetrina (Q10=A) |
| CD-2 | Perimetro rosso sfumato pulsante in overlay standby | proposto | 2026-05-17 | Backlog |
| CD-3 | Bottone "Ricomincia setlist" a fine setlist | proposto | 2026-05-17 | Backlog |
| CD-4 | Pulsantiera Vista LIVE 4 quadranti + cerchio | draft 1 consegnato | 2026-05-20 | In review Mauro |
| CD-5 | Schermata STOP a metà song | ratificato 21/05 (Q7-Q10 + 9 R-CD5 + β in sez. 2). In attesa di implementazione codice Layer 3 | 2026-05-21 | Deliverable entrato nel brief Fase 4 (R-CD5-08). Aggiornamento documento brief dominio CD |
| Fase 4 | Vista LISTA | brief Fase 4 ratificato 19/05 | 2026-05-19 | Batch 2 dopo CD-0/4 |
| Fase 4 | Vista Emergenza | non iniziato | — | Backlog |
| Fase 6.1 | UI MIDI Learn | non iniziato | — | Backlog |
| Fase 7 | HDMI Stage View | non iniziato | — | Backlog |
| Fase 8 | Settings G1-G8 | non iniziato | — | Backlog |
| TD #44 | Bug Link discovery QB↔QB | email Ableton inviata 19/05, response deadline 27/05/2026 | 2026-05-19 | Workaround v1 attivo. Decisioni architetturali sez. 2 |

---

## Sezione 4 — Domande aperte

Le domande sono numerate. Mauro risponde nel formato `Q11=A, ecc.`. Quando una risposta arriva, CC sposta la voce in sezione 2 con la data di ratifica.

### Domande aperte residue (post-v5 21/05)

**Nessuna domanda aperta al 21/05** — tutte le domande Q1-Q12 + β.1-β.2 + R-CD5-01-10 risolte tra v3 e v5. Sezione 4 vive come placeholder per future domande aperte.

### Voci risolte come moot (non ratificate, non più rilevanti)

| ID | Motivo della risoluzione |
|---|---|
| R-CD5-03 | Moot per Q7=A (21/05): la pulsantiera CD-4 è nascosta durante `.stoppedMidSong`, quindi il bottone `▶ PLAY` non è visibile. La proposta CD-5 (PLAY disabled vs raccomandazione CC bottone Resume nominale) diventa irrilevante. |

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
| 3 | 2026-05-21 | CC chat principale 21/05, ratifica batch Mauro | Batch ratifiche post-review CD del v2: 13 risposte chiare (Q1-Q10 + β.1, β.2 + R-CD5-10) + 8 R-CD5 letterali (R-CD5-01, 02, 04, 05, 06, 07, 08, 09 — testo girato da Mauro in chat 21/05 da spec CD-5 sez. 3) + R-CD5-03 marcata moot (risolta da Q7=A). Sigla EMERGENZA aggiunta in sez. 1 "Tasti / azioni" (definizione: bottone BR pulsantiera CD-4, switch a Vista LISTA, nascosto durante `.stoppedMidSong`). Implicazioni a cascata applicate: KILL BASE → `superseded`, KILL TRACK → `attivo`; FINE SHOW e TORNA AGLI SHOWS → `superseded`, END SHOW e BACK TO SHOWS → `attivo`; CD-1 deliverable scope esteso; CD-5 deliverable in attesa implementazione Layer 3. Stati `.stopped` (disambiguato), `.standby` (nota Q10=A), `.countIn` (Q3=A Resume), `.loopActive` (R-CD5-05 reset su STOP), `.stoppedMidSong` (Q4=A + R-CD5-01 + R-CD5-02 attivo). Sez. 4 ripulita: 22 voci risolte rimosse, resta solo Q11 (PROSSIMA→NEXT, non ratificato esplicitamente nel batch 21/05) + tabella R-CD5-03 moot. Vista LISTA / Vista Emergenza lasciate distinte in sez. 1 (fusione "ex Vista Emergenza" non applicata automaticamente per scelta conservativa CC, in attesa eventuale ratifica esplicita Mauro). |
| 4 | 2026-05-21 | CC chat principale 21/05, ratifica Q11=A + apertura Q12 | Ratifica Q11=A (PROSSIMA → NEXT, coerente con R-CD5-10): riga PROSSIMA → `superseded`, riga NEXT → `attivo`. PROSSIMA mai entrata in codice Swift (Grep mirato 21/05 zero match), nessun cascading rename codice. Fix di consistency in sez. 1 "App e modalità": riga `Vista LIVE` aggiornata da "KILL BASE" a "KILL TRACK" nella descrizione descrittiva. Aperta nuova Q12 in sez. 4: cascading rename completo R-CD5-10 — debito tecnico scoperto applicando per la prima volta la regola `feedback_qbeats_grep_generico_pre_cascading_rename.md`. Grep generico rivela 14 stringhe UI italiane in 5 file Swift (`BackupView`, `ImportView`, `SettingsView`, `BarCounterView`, `DebugView`) + sigla `EMERGENZA` nel libro mastro. Mauro deve ratificare scope (tutti i 5 file produzione + EMERGENZA → EMERGENCY? DebugView pure? rimanda come TD?). Sez. 4 ora: Q12 + R-CD5-03 moot. |
| 5 | 2026-05-21 | CC chat principale 21/05, Q12=A + cascading rename Swift completo | Q12=A ratificato (cascading rename Swift R-CD5-10 completo su 4 file produzione, **30 stringhe** italiane rinominate in inglese — Read completo dei file ha rivelato 16 stringhe in ImportView, 8 in BackupView, 4 in SettingsView, 2 in BarCounterView; il Grep regex iniziale aveva stimato solo 14 perché non catturava `Toggle("...")` / `Picker("...")` / `SwiftUI.Section("...")` / stringhe pluralizzate interpolate / label sciolti come `" di "`). DebugView escluso (scaffold dev, no UI utente). Sigla EMERGENZA → EMERGENCY in sez. 1 "Tasti / azioni" (riga superseded + nuova riga attiva). Riga Q12 rimossa da sez. 4 (nessuna domanda aperta residua post-v5). Commit Swift cascading rename: `cf3f0b5`. **Feedback memory `feedback_qbeats_grep_generico_pre_cascading_rename.md` da affinare**: regola corretta = "Grep generico identifica file sospetti, Read completo del file è obbligatorio per inventario letterale (Grep regex sottostima)". |
| 6 | 2026-05-21 sera | CC chat principale 21/05, ratifica roadmap batch CD | Ratificata roadmap operativa batch CD post-v5: D1=A ordine deliverable (CD-5 mockup finale → CD-1 esteso → CD-3 → popolamento sotto-tabella "Schermate ratificate"), D2=A timing sotto-tabella popolata a fine batch, D3=B anticipo CD-3 nel batch (4 punti totali, motivazione coerenza visiva Restart Setlist ↔ Restart {song.name}), Extra=A semantica colonna "Layout congelato" stretta (no colonna Stato draft aggiunta). 2 righe nuove in sez. 2 (ordine batch + Extra=A semantica). Tag "**Batch CD 21/05 — posizione N**" aggiunto in note sez. 3 di CD-1 (pos. 2), CD-3 (pos. 3), CD-5 (pos. 1). "Ultima mod" CD-1/CD-3/CD-5 bumpata al 21/05. Sez. 1 invariata (Extra=A). Sez. 4 invariata (zero domande aperte residue post-v5). |
| 7 | 2026-05-21 sera | CC chat principale 21/05 — rollback A su errore v6 | Riconosciuto errore custode CC in v6: avevo accodato senza filtro R3 le righe operative CD interne proposte nel batch 21/05. Regola libro mastro: "solo ratifiche cross-team prodotto/naming/processo/deliverable/gerarchia, NO piano operativo CD o CC interno". Rollback A applicato: rimossa riga sez. 2 "Roadmap batch CD: ordine deliverable" (operativo interno CD); rimossi 3 tag "**Batch CD 21/05 — posizione N**" da note sez. 3 di CD-1/CD-3/CD-5; "Ultima mod" CD-3 ripristinata al 17/05; descrizione stato CD-5 ripristinata a v5. Mantenuta in sez. 2 la riga "Semantica Layout congelato stretta (Extra=A)" perché regola di processo cross-team del libro mastro stesso (definisce uso sotto-tabella sez. 1, vincolante per ogni chat CD/CC futura). Memoria feedback CC nuova `feedback_qbeats_libro_mastro_solo_cross_team.md` salvata per evitare ripetizione. |

---

**Fine documento.**
