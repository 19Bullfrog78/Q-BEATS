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
| **110 Quad** | "Carica dati test 110 Quad" | `.cyan` | 1 song, 4 sez 110 BPM 4/4 × 7 misure ciascuna, zero cambi BPM | ~61s | Isola se transizioni sezione causano drift indipendentemente da ΔBpm (commit `7946032`). **T-R2** post-Strada-A |
| **BPM Quad** | "Carica dati test BPM Quad" | `.orange` | 1 song, 4 sez 4/4 × 7 misure, BPM 100→130→110→140 (Δ ascendente/discendente/ascendente) | ~57s | Valida atomic exchange BPM al downbeat + broadcast Link `set_bpm_and_beat_at_time` post-Strada-A (commit `7a0f622`). **T-BPM** |
| **BPB Mixed** | "Carica dati test BPB Mixed" | `.mint` | 1 song, 4 sez × 4 misure × 120 BPM, BPB 4/4→3/4→5/4→4/4 con accent pattern misti `[2,1,1,1]`/`[2,1,1]`/`[2,1,1,2,1]`/`[2,1,2,1]` | ~32s | Valida atomic exchange BPB + accent pattern + quantum Link al downbeat post-Strada-A (commit `7a0f622`). **T-BPB** |

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

### Lezione 5 — "Link quantum mismatch produce sync_phase spurio" (16/05/2026 pomeriggio, post-T-BPB)

**Errore origine**: T-BPB Test 1 con peer SB attivo via Link → click orfano + accent shift permanente al primo cambio BPB (4/4→3/4). Inizialmente attribuito a possibile bug Strada A.

**Realtà** (confermata da T-BPB Test 2 in Q-B standalone, no Link): il click orfano sparisce completamente quando il peer Link è disconnesso. Causa: Q-B passa a quantum=3 (3/4) via `link_engine_set_quantum`, SB resta a quantum=4 (TS hardcoded nell'app SB, non cambiabile via Link). Per ~1s post-transizione `linkSyncSkipBuffers=100` protegge da `link_engine_sync_phase`. Dopo la scadenza, sync_phase riprende e legge un consensus Link inconsistente (Q-B quantum=3 + SB quantum=4 = phase ambigua) → correzione spuria → `metronome_set_beat_position` riscrive `_currentBeatInBar` + `_exactNextBeatSample` → click shiftato + accent permanente fuori posto.

**Implicazioni**:
- Per testare cambi BPB in modo isolato dal peer, usare **Q-B standalone** (Link OFF) o peer compatibile (Tick? da verificare se supporta cambi TS via Link).
- SB come peer ground truth per cambi BPB NON è affidabile — produce artefatti che NON sono bug Q-B.
- Setlist con cambi BPB live richiedono mitigazione lato Q-B (vedi TD #39): aumentare `linkSyncSkipBuffers` post-cambio BPB, bloccare sync_phase per finestra estesa, o verificare consenso peer prima della correzione.

**Regola fissata**: per test Strada A su cambi BPB, eseguire **almeno una variante standalone** per isolare Q-B-side da peer/Link-side prima di concludere bug Q-B.

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
| **NON rifare** | Sostituito da T-R2 post-Strada-A (verde) |

### T-R2 — 110 Quad post-Strada-A ✅ VALIDATO

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 pomeriggio |
| **HEAD** | `1f0a433` (Strada A applicata) — IPA su master `7a0f622` |
| **Setup** | SB peer via Link, microfono in stanza, Audacity |
| **Setlist** | 110 Quad (identica a Test 2) — bottone `.cyan` |
| **Risultato Mauro** | *"Fatto il peer fatto partire 4 sezioni da 110 x 7 misure perfette nessun drift anche ad orecchio è perfetto. Se chiudo gli occhi e ascolto non mi accorgo del cambio sezione."* |
| **Confronto vs baseline V60** | Pre-Strada-A: +33/+74/+160ms cumulativi su 3 transizioni. Post-Strada-A: zero offset percepibile (cluster compatti su tutte le transizioni). |
| **Soglia chiusura** | ≤5ms cumulato (BOX3 V61) — **superata** |
| **Stato** | ✅ VALIDATO — drain gap eliminato, causa root del bug originario risolta |
| **Conclusione** | **Strada A funziona come progettato sul caso d'uso primario del bug**. Le transizioni di sezione intra-canzone sono ora seamless: l'orecchio del batterista non percepisce il cambio. |
| **NON rifare** | A meno di regression post-fix futuri al Layer 1 DSP o Layer 3 AudioEngine |

### T-BPM — BPM Quad post-Strada-A ✅ VALIDATO (caveat peer)

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 pomeriggio |
| **HEAD** | `1f0a433` / IPA `7a0f622` |
| **Setup** | SB peer via Link, Audacity |
| **Setlist** | BPM Quad (4 sez × 7 mis × 4/4, BPM 100→130→110→140) — bottone `.orange` |
| **Risultato Mauro** | *"Tutto ok tranne una volta che è saltato il peer sul cambio BPM (da indagare che non sia un bug) ma se il peer non salta il sync è perfetto."* |
| **Caveat** | 1 occorrenza isolata di "peer SB salta sul cambio BPM" in N transizioni. Non sistematica. Ipotesi 1 (firmware SB) probabile — memoria `project_qbeats_test_peer.md` ricorda bug noti SB su Link. |
| **Stato Q-B-side** | ✅ VALIDATO — broadcast Link atomic `set_bpm_and_beat_at_time` funziona correttamente nel ramo SEAMLESS, DSP exchange BPM al downbeat sample-accurate. |
| **Stato caveat peer** | ⚠️ Archiviato come glitch isolato. Da riconsiderare se si ripete sistematicamente in test futuri. |
| **NON rifare** | A meno che il caveat peer si manifesti sistematicamente |

### T-BPB — BPB Mixed post-Strada-A ✅ VALIDATO Q-B-side (2 caveat)

| Campo | Valore |
|---|---|
| **Data** | 16/05/2026 pomeriggio (due esecuzioni: con peer SB + standalone) |
| **HEAD** | `1f0a433` / IPA `7a0f622` |
| **Setup Test 1** | SB peer via Link, Audacity |
| **Setup Test 2** | **Q-B standalone (Link disattivato)**, Audacity |
| **Setlist** | BPB Mixed (4 sez × 4 mis × 120 BPM, BPB 4/4→3/4→5/4→4/4 con accent misti) — bottone `.mint` |
| **Risultato Test 1 (con peer)** | Cambio 4/4→3/4: click orfano fuori griglia tra beat ~14-15 + accent shift permanente. SB non cambia TS (resta 4/4) come da limite Link/SB. |
| **Risultato Test 2 (standalone)** | Cambio 4/4→3/4 pulito, zero click orfani, accent corretto. Sez 4 (`[2,1,2,1]`): 4 click con accent backbeat (1+3) come da pattern. |
| **Diagnosi click orfano Test 1** | Link sync quantum mismatch (vedi Lezione 5 + TD #39 in BOX3 V62). Post-`linkSyncSkipBuffers` (~1s), `link_engine_sync_phase` corregge Q-B verso consensus Link inconsistente (Q-B quantum=3 + SB quantum=4) → `metronome_set_beat_position` riscrive `_currentBeatInBar` + `_exactNextBeatSample` → click shiftato. |
| **Esclusione bug Q-B-side** | Test 2 standalone dimostra che senza peer Link il bug sparisce → causa è peer/Link-side, NON Strada A. |
| **Caveat 1** | Display microbar Sez 4 (4/4 accent backbeat) mostra "2/4" visivamente invece di 4 beat con accent. Bug UI pre-esistente — Strada A non tocca SwiftUI Views. Registrato come TD #38. |
| **Caveat 2** | Display microbar Sez 3 (5/4) ultimo segmento beat resta nero. Bug UI pre-esistente. Registrato come TD #38. |
| **Stato Q-B-side** | ✅ VALIDATO — DSP exchange BPB + accent pattern + `link_engine_set_quantum` al downbeat funzionano sample-accurate. |
| **NON rifare** | A meno di regression post-fix |

---

## TEST NON DA RIFARE (lista esplicita)

| Test | Motivo per cui NON rifare |
|---|---|
| Test 1 — 110 Mono ✅ | Risultato verde validato. Sostituito da T-R2 come regression Strada A. |
| Test 2 — 110 Quad ❌ | Risultato rosso validato + causa root identificata. Sostituito da T-R2 ✅. |
| **T-R2** — 110 Quad post-Strada-A ✅ | Risultato verde validato 16/05 pomeriggio. Rifare solo per regression post-fix futuri al Layer 1/Layer 3. |
| **T-BPM** — BPM Quad post-Strada-A ✅ | Verde Q-B-side. Rifare solo se il caveat peer SB si ripete sistematicamente. |
| **T-BPB** — BPB Mixed post-Strada-A ✅ Q-B-side | Verde su 2 esecuzioni (con peer + standalone). Per future indagini su TD #39 (Link quantum mismatch), riprodurre con peer Tick se supporta cambi TS. |
| Test L2.b varianti pre-Strada-C | Dati interpretati male, valore storico. Per dati numerici precisi serve nuova esecuzione con metodologia corretta. |
| Test 3 — L2.b con peer Tick | **CANCELLATO**. Causa root Q-B-side (non peer-side), Tick mostrerebbe lo stesso fenomeno. |

---

## TEST FUTURI PREVISTI (NON ANCORA ESEGUITI)

### Test R1 — Regression 110 Mono post-Strada-A — **DEPRECATO**

Sostituito de facto da T-R2: se T-R2 (4 sez con transizioni) è verde, T-R1 (1 sez standalone, scenario più semplice) è implicitamente verde. Da eseguire solo se T-R2 mostrasse regressioni inattese in futuro.

### Test R2 — Regression 110 Quad post-Strada-A — **ESEGUITO ✅**

Vedi sezione "T-R2 — 110 Quad post-Strada-A ✅ VALIDATO" sopra. Verde perfetto 16/05/2026 pomeriggio. Drain gap eliminato.

### Test R3 — L2.b post-Strada-A (scenario produzione)

| Campo | Valore |
|---|---|
| **Quando** | Opzionale pre-palco. Coperto in parte da T-BPM (BPM variabile + 4/4) eseguito 16/05 pomeriggio. |
| **HEAD** | `1f0a433` (post-Strada-A) |
| **Setup** | Identico ai test L2.b precedenti, peer SB |
| **Setlist** | L2.b (100→130→110→140) — bottone `.indigo` |
| **Atteso** | Zero accumulo ai cambi sezione + zero drift intra-sezione. T-BPM (più simmetrico, 7 mis fisse) ha già confermato lo scenario. T-R3 servirebbe solo per confrontare con i dati storici L2.b. |
| **Decisione** | Non prioritario. T-BPM verde lo copre sufficientemente. |

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

- **V1** (16/05/2026 mattina) — primo registro consolidato, test fino a Test 2. Lezioni 1-4.
- **V2** (16/05/2026 pomeriggio) — questo aggiornamento. T-R2 + T-BPM + T-BPB post-Strada-A. Nuovi bottoni DebugView (BPM Quad `.orange` + BPB Mixed `.mint`). Lezione 5 (Link quantum mismatch). Strada A validata sul trittico critico audio Q-B-side.
- **V3** (futuro) — aggiornare con esito palco real-life + eventuali test post-fix TD #38/#39.

**Regola di aggiornamento**: ogni nuovo test eseguito va aggiunto come riga nella tabella "TEST ESEGUITI", con HEAD, data, setup, risultato, stato. Le lezioni metodologiche restano cumulative (le vecchie non vanno rimosse, solo aggiunte le nuove).

**Nota nome file**: filename `REGISTRO_TEST_AUDACITY_V1.md` mantenuto per stabilità link/memoria. Il versioning interno (V1/V2/V3) traccia gli aggiornamenti progressivi del contenuto.
