# REGISTRO TEST AUDACITY GROUND TRUTH V1

**Scopo**: documento persistente che cataloga **tutti i test ground truth Audacity** eseguiti su Q-BEATS per il bug Link sync L1.b e affini. Risultati VALIDATI da non rieseguire. Ogni futuro test va aggiunto qui con risultati. Versionato V1, V2, V3, etc.

**Regola d'uso**:
- Prima di proporre un nuovo test, **consultare questo registro** per evitare ripetizioni.
- I test marcati ✅ VALIDATO sono CERTI. Non rieseguire senza motivo specifico (es. regression check post-fix).
- I test marcati ⚠️ INTERPRETATO MALE hanno valore storico ma dati non affidabili numericamente. Re-interpretare con metodologia corretta se servono.
- I test marcati ❌ ROSSO sono test che hanno identificato un problema. Risultati validi, problema da risolvere.

---

## METODOLOGIA VALIDATA — Come fare un test ground truth Audacity

**Setup hardware/software**:
1. iPhone con Q-BEATS installato (IPA da CI iOS Signed Build su HEAD specifico)
2. Secondo dispositivo iOS/Android con app Link peer (Soundbrenner di default — vedi note peer in fondo)
3. Q-B e peer entrambi via Link nello stesso network WiFi (no Bluetooth)
4. PC/Mac con Audacity installato, microfono mono in stanza
5. Q-B e peer entrambi in altoparlante (volume udibile dal mic)

**Procedura**:
1. Carica setlist test in Q-B da DebugView (`#if DEBUG` build, bottoni dedicati)
2. Connetti peer Link nella sessione (verificare "1 peer connesso" in entrambi)
3. Audacity: avvia registrazione mono
4. Q-B: Play
5. Aspetta che il setlist finisca naturalmente
6. Audacity: ferma registrazione

**Interpretazione waveform**:
- Ogni beat appare come **un cluster compatto** che contiene attacco simultaneo dei due click (SB + Q-B) + **coda lunga risonante** (decay del campanaccio SB).
- Click Q-B = transiente "potente" (broadband, attacco secco)
- Click SB = transiente "piatto" (timbro campanaccio, attacco con coda risonante lunga 50-100ms)
- **In sync**: i due click si sovrappongono nell'attacco → cluster compatto singolo + coda
- **Fuori sync**: i due click si separano visibilmente → DUE PEAK distinti, ognuno con la propria coda (peak Q-B "secco" + peak SB "con coda lunga")

**Misurazione offset**:
- Per offset >50ms: visibile direttamente (doppio peak distinto)
- Per offset 20-50ms: usare cursore Audacity sui due peak per timestamp esatti (in ms)
- Per offset <20ms: cluster appare compatto, offset non distinguibile a vista. Usare zoom estremo + filtro coda SB se serve precisione

**Convenzione segno**:
- `offset = SB_onset - Q-B_onset`
- **Positivo** = SB suona PRIMA del master Q-B (SB in anticipo)
- **Negativo** = SB suona DOPO del master Q-B (SB in ritardo)
- In modalità Direttore: Q-B è il master, dichiara la timeline via Link, peer dovrebbe seguirlo sample-accurate. Qualsiasi offset ≠ 0 è disallineamento.

---

## STRUMENTI DIAGNOSTICI DISPONIBILI

Tutte le setlist test sono in `DebugView.swift` sotto `#if DEBUG`. Bottoni dedicati nella sezione "Pulsanti test".

| Setlist | Bottone | Tint | Composizione | Durata | Scopo |
|---|---|---|---|---|---|
| **L1.b** | "Carica dati test L1.b" | `.purple` | 2 song, 5 sezioni totali, cambi BPM + cambi time signature (3/4 incluso) | ~variabile | Validazione L1.b multi-section originale (verde 14/05/2026) |
| **L2.b** | "Carica dati test L2.b" | `.indigo` | 1 song, 4 sez 4/4 puro, BPM 100/130/110/140, ripetizioni 4/6/12/4 | ~54s | Isola problema BPM puro dal mismatch quantum (commit `52fe1f9`) |
| **110 Mono** | "Carica dati test 110 Mono" | `.teal` | 1 song, 1 sez 110 BPM 4/4 × 45 misure | ~98s | Isola BPM-intrinsic vs cambio-driven (commit `7946032`) |
| **110 Quad** | "Carica dati test 110 Quad" | `.cyan` | 1 song, 4 sez 110 BPM 4/4 × 7 misure ciascuna, zero cambi BPM | ~61s | Isola se transizioni sezione causano drift indipendentemente da ΔBpm (commit `7946032`) |

**Setlist da NON cancellare**: sono strumenti regression. Pulizia log diagnostici a fine bug Link sync NON deve toccare le setlist test.

---

## LEZIONI METODOLOGICHE (correzioni cumulative)

### Lezione 1 — "Due cluster ≠ Due onset" (16/05/2026 mattina)

**Errore origine**: dal 15/05/2026 notte al 16/05 mattina, quando vedevamo un waveform con "attacco compatto + lungo decay oscillante" in L2.b, interpretavamo le due regioni come "due click separati di SB e Q-B" → conclusioni numeriche errate sull'offset (es. "+100ms drift intra-sezione 110").

**Realtà** (verificata da Mauro 16/05 mattina con zoom + filtro coda): il "secondo cluster" era in realtà la **coda risonante del campanaccio SB** (timbro tipico SB con sustain lungo). I due click SB+Q-B IN SYNC producono UN solo attacco compatto seguito dalla coda SB.

**Implicazioni**:
- Tutti i dati numerici L2.b pre-Test-1 (es. "Sez 130 +50ms costante", "Sez 110 fine +150ms drift") sono GONFIATI dall'interpretazione errata.
- Test L2.b precedenti (vedi sezione "TEST ESEGUITI") sono ⚠️ INTERPRETATO MALE → valore qualitativo (trend "accumulo ai cambi" reale) ma numerico inattendibile.
- I dati di Test 1 e Test 2 (16/05 mattina post-correzione metodologica) sono CERTI.

### Lezione 2 — "SB in anticipo sul master Q-B" (16/05/2026 notte)

**Errore origine** (mio, CC): inizialmente descrivevo i dati come "Q-B in ritardo".

**Correzione (Mauro)**: in modalità Direttore, **Q-B è il master**. SB è slave. Quando l'offset SB→Q-B è positivo, è **SB che suona PRIMA del master**, non Q-B che suona dopo. Framing causale corretto: SB sta seguendo una dichiarazione Link errata trasmessa da Q-B.

**Implicazioni**: leggere sempre i dati in chiave "il master dovrebbe dettare il tempo, il peer dovrebbe seguirlo". Qualsiasi anticipazione del peer = il master sta trasmettendo qualcosa di sbagliato O il master ha audio che ritarda rispetto a quanto trasmette.

### Lezione 3 — "SB segue Link giusto, Q-B audio si ferma al cambio sezione" (16/05/2026 mattina, post-Test-2)

**Inversione causale critica** (osservazione Mauro): *"SB anche se Slave batte giusto a 0.480 di distanza... ci stiamo accanendo su SB ma forse abbiamo un problema con Q-B"*.

**Realtà**: SB segue il consensus Link correttamente. Q-B audio (il master) introduce ritardo accumulativo a ogni cambio sezione perché il drain mode del playerNode si svuota e l'audio Q-B si ferma per ~30-50ms mentre Link state continua nominalmente.

**Implicazioni**: il problema NON è peer-side. Tutti i test futuri con peer diversi (Tick, etc.) mostrerebbero lo stesso fenomeno. Cancellato Test 3 (peer alternativo) dal piano.

### Lezione 4 — "Log Q-B-side ≠ Sync audio inter-peer" (15/05/2026 notte)

**Errore origine**: dichiaravo "Step 4 fix solido" basandomi solo su log ASSERT-DIAG Q-B-side che mostravano delta crollato.

**Realtà**: i log Q-B-side misurano coerenza state Link condiviso (Q-B con sé stesso), NON sync audio sample-accurate peer-side. Per validare sync inter-peer reale serve ground truth audio.

**Regola fissata** in memoria `feedback_log_vs_ground_truth.md`: validare sync inter-peer SEMPRE con orecchio Mauro su device + Audacity, MAI con soli log Q-B.

---

## TEST ESEGUITI — Cronologia con risultati

### Test L2.b pre-Step-4 (riferimento storico, dati orali Mauro)

| Campo | Valore |
|---|---|
| **Data** | 15/05/2026 sera |
| **HEAD** | pre-`afe6e90` (Step 1/2/3 attivi, no Step 4) |
| **Setup** | SB peer, Audacity |
| **Setlist** | L2.b (100→130→110→140 BPM, 4/4) |
| **Risultato (qualitativo)** | "SB anticipa Q-B di ~30ms costanti, gestito da DIRECTOR-ASSERT" |
| **Stato** | ⚠️ Dati orali, non quantificati con metodologia corretta |
| **Note** | Riferimento per confronto con Step 4 successivo |

### Test L2.b post-Step-4

| Campo | Valore |
|---|---|
| **Data** | 15/05/2026 notte |
| **HEAD** | `afe6e90` (Step 4: atomic SetTempo+ForceBeatAtTime con NEW BPM projection) |
| **Setup** | SB peer, Audacity ground truth (prima sessione metodica) |
| **Setlist** | L2.b |
| **Risultato (interpretazione "due cluster")** | Sez 1: ~15ms baseline. Sez 2 inizio: ~50ms (+35). Sez 3 metà: ~100ms (+50). Sez 4 metà: ~150ms (+50). Accumulo costante ai cambi. |
| **Stato** | ⚠️ INTERPRETATO MALE — numeri gonfiati dalla coda campanaccio SB confusa con secondo onset. Trend qualitativo "accumulo ai cambi" reale. |
| **Conseguenza** | Diagnosi causa root (errata) "sovrastima beat con NEW BPM" → Strada A applicata. |

### Test L2.b post-Strada-A

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 notte |
| **HEAD** | `1acdf40` (Strada A: proiezione OLD BPM letto da ABLLinkGetTempo) |
| **Setup** | SB peer, Audacity |
| **Setlist** | L2.b |
| **Risultato (interpretazione "due cluster")** | 100→130: +35 → **+40ms** (peggiorato 5ms). 130→110: +50 → **+30ms** (migliorato 20ms, segno opposto come predetto). 110→140: SB sganciato (Link disconnect). |
| **Stato** | ⚠️ INTERPRETATO MALE (stessa coda campanaccio). Trend qualitativo: Strada A migliora parzialmente ΔBpm<0, non risolve. |
| **Conseguenza** | Diagnosi "Force fa danno comunque" → ricerca LinkHut → Strada C. |

### Test L2.b post-Strada-C

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 notte |
| **HEAD** | `6c4a9cc` (Strada C: solo SetTempo, pattern LinkHut canonical) |
| **Setup** | SB peer, Audacity |
| **Setlist** | L2.b |
| **Risultato (interpretazione "due cluster")** | Sez 130 inizio: ~50ms costante. Fine 130: ~50ms (stabile intra-sezione). Sez 110 inizio: ~40-50ms. Sez 110 fine: ~150ms ("drift +100ms intra-sezione" — POI SMENTITO). Sez 140 metà: ~150ms (eredita offset Sez 110). |
| **Stato** | ⚠️ INTERPRETATO MALE. "Drift +100ms intra-sezione 110" era artefatto visivo (coda campanaccio SB). Trend qualitativo: Strada C ha eliminato l'accumulo ai cambi rispetto a Step 4/A — i 3 cambi 130→110→140 non aggiungono offset crescente. |
| **Conseguenza** | Falso positivo "drift intra-sezione peer-side" → piano test diagnostici 110 Mono/Quad. |

### Test 1 — 110 Mono ✅ VALIDATO

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 mattina |
| **HEAD** | `7946032` (Strada C attiva + setlist diagnostiche aggiunte) |
| **Setup** | SB peer via Link, microfono mono in stanza, Audacity mono ~100s |
| **Setlist** | 110 Mono (1 sez 110 BPM 4/4 × 45 misure, ~98s, ZERO cambi) |
| **Bottone** | "Carica dati test 110 Mono" (tint `.teal`) |
| **Metodologia** | Analisi visiva strutturale dei cluster waveform a beat 1, ~49s, ~98s. Verifica "cluster compatto singolo + coda" vs "doppio peak distinto". |
| **Risultato** | **ZERO offset SB↔Q-B per tutta la durata (98 secondi).** Tutti e 3 i punti di campionamento mostrano cluster compatto singolo + coda decay SB. NESSUN doppio onset visibile. |
| **Stato** | ✅ VALIDATO — metodologia corretta (post-Lezione 1) |
| **Conclusione** | 110 BPM standalone NON ha drift. SB hardware affidabile a 110 BPM. Drift Sez 110 di L2.b NON è BPM-intrinsic — è cambio-driven. |
| **NON rifare** | A meno di regression check post-Strada A |

### Test 2 — 110 Quad ❌ ROSSO RIVELATORE

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 mattina |
| **HEAD** | `7946032` |
| **Setup** | SB peer, mono, Audacity |
| **Setlist** | 110 Quad (4 sez × 7 mis × 110 BPM 4/4, ~61s, **3 transizioni di sezione, ZERO cambi BPM**) |
| **Bottone** | "Carica dati test 110 Quad" (tint `.cyan`) |
| **Metodologia** | Analisi visiva dei cluster a inizio + mid di ogni sezione. Misurazione visiva distanza SB→Q-B con Mauro stima Audacity. |
| **Risultato** | Sez 1 regime: ~0ms. **Sez 2 inizio (T1, ~15.3s): +33ms** (SB 0.490 / Q-B 0.523). **Sez 3 mid (~33s): +74ms** (click visibilmente separati). **Sez 4 mid (~50s): +160ms** (doppio picco molto chiaro). Ultimo beat Sez 4: +150ms (Q-B finisce in ritardo, SB ha beat extra). Distanza SB→SB approssimativamente costante ~0.49-0.55s (≈ beat period 545ms a 110 BPM). |
| **Stato** | ✅ VALIDATO (risultato negativo = ROSSO) — metodologia corretta |
| **Conclusione** | **Drift accumulativo ~30-50ms per transizione di sezione**, INDIPENDENTE dal cambio BPM. Causa: **drain gap Q-B-side**. SB segue Link giusto, Q-B audio si ferma momentaneamente al cambio sezione. |
| **NON rifare** | A meno di regression check post-Strada A |

---

## TEST NON DA RIFARE (lista esplicita)

| Test | Motivo per cui NON rifare |
|---|---|
| Test 1 — 110 Mono ✅ | Risultato verde validato. Rifare solo per regression check post-Strada A. |
| Test 2 — 110 Quad ❌ | Risultato rosso validato + causa root identificata. Rifare solo per regression check post-Strada A. |
| Test L2.b varianti pre-Strada-C | Dati interpretati male, valore storico. Per dati numerici precisi serve nuova esecuzione con metodologia corretta. |
| Test 3 — L2.b con peer Tick | **CANCELLATO**. Causa root Q-B-side (non peer-side), Tick mostrerebbe lo stesso fenomeno. |

---

## TEST FUTURI PREVISTI (NON ANCORA ESEGUITI)

### Test R1 — Regression 110 Mono post-Strada-A

| Campo | Valore |
|---|---|
| **Quando** | Dopo che Strada A sarà implementata e committata (Layer 1 + 2 + 3) |
| **HEAD** | TBD (commit Strada A) |
| **Setup** | Identico a Test 1 |
| **Setlist** | 110 Mono |
| **Atteso** | Stesso risultato di Test 1: cluster compatto, zero offset. Validare che Strada A non abbia regressioni su scenari standalone. |

### Test R2 — Regression 110 Quad post-Strada-A (test critico)

| Campo | Valore |
|---|---|
| **Quando** | Dopo Strada A |
| **HEAD** | TBD |
| **Setup** | Identico a Test 2 |
| **Setlist** | 110 Quad |
| **Atteso** | **ZERO drift accumulativo ai 3 cambi sezione**. Tutti i punti devono mostrare cluster compatto (come Sez 1 di Test 2). Se persiste anche un solo cambio con doppio peak → Strada A non ha risolto. |
| **Criterio chiusura bug** | Test R2 verde + ground truth Audacity validata |

### Test R3 — L2.b post-Strada-A (test scenario produzione)

| Campo | Valore |
|---|---|
| **Quando** | Dopo R2 verde |
| **HEAD** | TBD |
| **Setup** | Identico ai test L2.b precedenti |
| **Setlist** | L2.b (100→130→110→140) |
| **Atteso** | Zero accumulo ai cambi sezione + zero drift intra-sezione (Strada C già risolveva cambi tempo, Strada A risolve cambi sezione). |

### Test palco real-life

| Campo | Valore |
|---|---|
| **Quando** | Dopo R1/R2/R3 verdi |
| **Setup** | Performance live reale, Q-B + peer SB drummer, eventuale registrazione DAW per analisi posthoc |
| **Atteso** | Validazione finale v1 Modalità Direttore. Se musicalmente OK → v1 chiusa. Se no → fallback Opzione 3 AURenderCallback (costo 2-3x, già documentato come piano B). |

---

## NOTE PEER (Soundbrenner come peer di riferimento)

**Peer attuale**: Soundbrenner (SB). Non più Tick come dichiarato il 15/05 — il 16/05 SB è tornato peer di riferimento per i ground truth Audacity perché:
- Tick non disponibile su tutti i test
- Mauro ha SB sul polso, comodo per setup veloce
- I dati storici sono con SB, mantiene consistenza
- Memoria `project_qbeats_test_peer.md` da aggiornare se questo cambio diventa permanente

**Limiti SB**:
- Click "campanaccio" con coda risonante 50-100ms — confonde visualizzazione waveform se non si applica metodologia corretta (Lezione 1)
- Toggle "Sync Start/Stop" OFF di default — vedi memoria `project_qbeats_sb_link_sync_config.md`. Non confondere con bug Q-B.

**Metronome Pro**: ❌ NON usare come peer di riferimento. Drift hardware Pro-side già documentato — non affidabile per test sync inter-peer.

---

## VERSIONING REGISTRO

- **V1** (questo, 16/05/2026 mattina) — primo registro consolidato, copre tutti i test eseguiti fino a Test 2. Lezioni metodologiche 1-4 incluse.
- **V2** (futuro) — aggiornare con esito Test R1/R2/R3 post-Strada A. Eventuali nuove lezioni emergenti.
- **V3** (futuro) — aggiornare con esito palco real-life.

**Regola di aggiornamento**: ogni nuovo test eseguito va aggiunto come riga nella tabella "TEST ESEGUITI", con HEAD, data, setup, risultato, stato. Le lezioni metodologiche restano cumulative (le vecchie non vanno rimosse, solo aggiunte le nuove).
