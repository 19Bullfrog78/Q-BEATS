# HANDOFF NEXT CHAT — 16/05/2026 mattina

**Scopo**: contesto da leggere come primo messaggio della prossima chat. Sintetizza in 5 punti lo stato corrente del progetto Q-BEATS dopo la sessione mattina del 16/05/2026 (Test diagnostici eseguiti, Strada A ratificata). Da usare per ripartire senza perdere contesto.

---

## 1. STATO REPO

- HEAD `aa7c4f3` su master (ultimo commit: BOX3 V60 + Registro test Audacity V1, solo docs).
- HEAD codice = `7946032` (Strada C `6c4a9cc` attiva + setlist diagnostiche 110 Mono/Quad in DebugView).
- IPA invariata in questa sessione (zero modifiche al codice).
- Working tree pulito.

---

## 2. DIAGNOSI CHIUSA — Causa root identificata

- **Test 1 (110 Mono) ✅ VERDE**: zero drift su 98s a 110 BPM standalone. Bottone DebugView `.teal`.
- **Test 2 (110 Quad) ❌ ROSSO RIVELATORE**: drift accumulativo +33/+74/+160ms su 3 cambi sezione SENZA cambio BPM. Bottone DebugView `.cyan`.
- **Causa root**: drain gap Q-B-side ~30-50ms per transizione sezione. Catena: `_sectionEndPending` → `scheduleNextBuffer` ritorna senza schedulare → playerNode coda vuota → dispatch main → audioQueue serializza 5 blocchi async (setBeatsPerBar, setAccentPattern, loadSection, scheduleBPMChange, kickScheduling) → `kickScheduling()` riprende rendering.
- **Inversione causale**: SB segue Link giusto, è **Q-B audio (master)** che si ferma al cambio sezione. NON peer-side.
- **Test 3 (peer Tick) CANCELLATO**: problema Q-B-side, qualsiasi peer mostrerebbe stesso fenomeno.
- **Correzione metodologica chiave**: "due cluster waveform ≠ due onset" — la coda campanaccio SB era confusa per secondo click in tutti i test L2.b precedenti. Quei dati numerici sono ⚠️ inattendibili.

---

## 3. STRADA FIX RATIFICATA — Strada A

- **Strada A**: estendere pattern `_pendingBPM` + `_pendingBPMTargetTick` (atomic exchange sample-accurate al downbeat) a `_pendingBPB`, `_pendingAccentPattern`, `_pendingSectionTotalBeats`, `_pendingOnSectionEnd`. Drain mode: **VIA per ramo `avanza`**, **RESTA per `fineSetlist` e `standby`**. Layer 1 potenzialmente toccato — da verificare con lettura codice. Layer 2 (AudioEngine.swift) + Layer 3 (SetlistRunner.swift) coinvolti.
- **Strade scartate** (NON RIAPRIRE): B (eliminare drain full rewrite, troppo invasiva), D (pre-chiamate funzioni indipendenti, palliativo). C (buffer silenziosi) non scartata definitivamente ma A preferita per coerenza architetturale.
- **3 criticità design da risolvere durante progettazione**: (1) scope drain esplicito per ogni ramo SetlistRunner, (2) reset `_sectionBeatCounter = 0` deve essere parte dell'atomic exchange al downbeat (non al pre-load), (3) verifica codice per chiarire definitivamente Strada C come fallback.

---

## 4. DOCUMENTI CHIAVE (da consultare prima di tutto in next chat)

- **`ARCHIVIO.MD/16_05_2026/BOX3_V60_16_05_2026.md`** — sessione mattina post-test. Esito Test 1/2, causa root drain gap, valutazione 4 strade, Strada A ratificata + 3 criticità design, prossimi step.
- **`ARCHIVIO.MD/SENZA COLLOCAZIONE/REGISTRO_TEST_AUDACITY_V1.md`** — persistente. Metodologia validata, 4 lezioni metodologiche cumulative (due cluster ≠ due onset / SB in anticipo sul master / SB segue Link Q-B si ferma / log Q-B-side ≠ sync inter-peer), cronologia test eseguiti con stato, lista test NON da rifare, test futuri previsti (R1/R2/R3 + palco). **Consultare PRIMA di proporre nuovi test Audacity**.
- **`ARCHIVIO.MD/16_05_2026/BOX3_V59_16_05_2026.md`** — snapshot pre-test diagnostici, cronologia completa Step 4 → Strada A → Strada C → Step 5 cassato.
- Memoria persistente: `project_qbeats.md` + `reference_qbeats_registro_test_audacity.md` aggiornati.

---

## 5. PROSSIMI STEP (3 sessioni separate)

- **Sessione N+1 (immediata, prossima chat) — Lettura codice approfondita per design Strada A**. Vincolo netto: **codice in chat, NO diff, NO modifica**. File da leggere:
  - `AudioEngine.swift` — `scheduleNextBuffer` (drain ramo), `loadSection`, `kickScheduling`, `setBeatsPerBar` didSet, `setAccentPattern`, `scheduleBPMChange`, beat callback C++ (dove `_sectionEndPending` viene settato), sezione `_pendingBPMValue` (~riga 1999-2053, pattern atomic exchange esistente).
  - `SetlistRunner.swift` — `makeSectionEndedClosure` (ramo avanza/standby/fineSetlist), `loadSection` callsite, `nextSection` getter.
  - `core_engine/MetronomeDSP.cpp/.h` — atomic exchange `_pendingBPM` → `_bpm` al downbeat, beat callback emission, eventuali altri `_pending*`.
  - `core_engine/MetronomeBridge.h` — signature C `metronome_set*` esistenti, pattern da replicare.

  **Domanda esplicita da risolvere durante la lettura**: la closure `onSectionEnd` può essere gestita interamente in Layer 3 senza mai entrare nel thread RT? Se il DSP C++ emette solo un segnale "sezione terminata" (pattern `beatTickSubject` / `PassthroughSubject`) e Swift gestisce la callback, Layer 1 non vede mai la closure e il problema ARC non esiste. Strada A potrebbe restare Layer 3 pura. Rispondere esplicitamente con riferimento al codice letto.

  **Output**: mappa testuale flussi + lista punti di estensione per nuovi pending.

- **Sessione N+2 — Design spec Strada A** con diff in chat, ratifica referee + Mauro prima di toccare codice.
- **Sessione N+3 — Commit chirurgico Strada A** Layer 1+2+3 + test su device + ground truth Audacity 110 Quad (Test R2 = critico, criterio chiusura: zero offset accumulato ai cambi sezione).
