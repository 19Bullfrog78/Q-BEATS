# HANDOFF Task D — 12/05/2026

Documento di chiusura sessione 11–12 maggio 2026. Task D non chiuso —
sono stati pushati 4 commit incrementali, il problema "SB anticipa il
passaggio BPM" è stato ristretto alla causa esatta e il fix #4 è
pronto per implementazione nella sessione successiva.

---

## Commit pushati su master

| Commit | Hash | Cosa | Esito test su device |
|---|---|---|---|
| Task D base | `1f2f58a` | Meccanismo broadcast `scheduleBPMChange` a Link/MIDI/_audioBPM/UI al downbeat | Test 1 (Q-B solo) ✅ verde |
| Fix #1 | `4d5b63b` | Pre-apply propagazione PRIMA dell'assert Link Direttore | Test 2 (Q-B+SB) ancora arancione |
| Fix #2 | `23262f7` | Re-anchor MIDI engine via `setBeatPosition` dopo `setBpm` (Strada E) | DIRECTOR-ASSERT delta da 1.5 → < 0.04 ✅ ma SB ancora anticipa di ~15ms |
| Fix #3 | `4b1080c` | Nuova bridge `link_engine_set_bpm_at_time` con `hostTimeAtOutput` invece di "adesso" | Insufficiente — vedi sezione sotto |

Working tree pulito. Master allineato con origin.

---

## Diagnosi attuale

### Sintomo residuo

Con fix #3 attivo, su device 12/05/2026 mattina:
- Q-B + SB Link Direttore, cambio 120 → 140 BPM
- Nei log `[Q-BEATS][TaskD] BPM pre-applied for downbeat in current buffer — next tick:33 → 140.0 BPM` (fix #3 scatta correttamente)
- Nessun `[Q-BEATS][LINK][DIRECTOR-ASSERT]` post-cambio (delta < 0.04, fix #2 funziona)
- **SB applica il cambio ~15ms prima di Q-B → "SB anticipa il passaggio a 140"**

### Causa identificata (rivelazione 12/05/2026 sera)

Il fix #3 chiama:

```
hostTimeAtOutput = mach_absolute_time()
                 + self.outputLatencyTicks     // = AVAudioSession.outputLatency ≈ 5ms
                 + self.bufferDurationTicks    // = AVAudioSession.ioBufferDuration ≈ 10.7ms
                 ≈ now + 15.7ms
```

`AVAudioSession.outputLatency` per Apple docs è **solo** la latenza hardware
del dispositivo (DAC + amp + transduzione fino al timpano). **NON include
il pre-roll di AVAudioPlayerNode** — il numero di buffer che il sistema
mantiene in coda per evitare underrun, tipicamente 2-3 buffer.

Quindi il vero hostTime di output del buffer corrente è:

```
vero hostTimeOutput = now + (N × bufferDuration) + outputLatency
                    ≈ now + (2-3 × 10.7ms) + 5ms
                    ≈ now + 26-37ms
```

Q-B passa a Link "il tempo cambia a t=15ms", ma il DSP audio effettivamente
suona il downbeat a t=26-37ms. SB applica al hostTime ricevuto (15ms) →
suona prima di Q-B di 11-22ms → **SB anticipa**, esattamente il sintomo
udito da Mauro.

### Conferma quantitativa

- 15ms a 140 BPM = `15 / (60000/140) = 0.035 beat`
- Soglia `kDirectorPhaseThreshold = 0.04` → **sotto soglia** → nessun
  `ABLLinkForceBeatAtTime` correttivo scatta. Coerente con i log
  (nessun `DIRECTOR-ASSERT` post-cambio).
- Diagnosi al millisecondo coerente con sintomo, log, e firmware SB.

`AVAudioPlayerNode.lastRenderTime` è l'API hardware-accurate che fornisce
l'orario reale dell'ultimo render callback del sistema audio. Q-B **non
usa `lastRenderTime` da nessuna parte** (verificato con grep su tutto il
file `AudioEngine.swift`).

---

## Fix #4 da fare nella sessione successiva

### Strategia

Helper privato `nextBufferOutputHostTime()` su `AudioEngine` che usa
`playerNode.lastRenderTime` invece di `mach_absolute_time()` per il vero
hostTime hardware-accurate.

**Formula:**

```
lastRenderTime.hostTime + bufferDurationTicks + outputLatencyTicks
```

**Logica:**
- `lastRenderTime.hostTime` = orario hardware dell'ultimo buffer renderizzato
- Il buffer corrente (quello che contiene il downbeat target) sarà
  renderizzato ~`bufferDurationTicks` dopo
- L'output udibile arriva `outputLatencyTicks` dopo il rendering
- Somma = hostTime del downbeat udibile, hardware-accurate

**Edge case con fallback al comportamento attuale di fix #3:**
- `playerNode.lastRenderTime == nil` (es. playerNode non running)
- `lastRenderTime.isHostTimeValid == false`
- Fallback: `mach_absolute_time() + outputLatencyTicks + bufferDurationTicks`
  (stessa formula di fix #3, errore residuo ~15ms ma non peggiora)

### Callsite da aggiornare

Due callsite Task D in `AudioEngine.swift`, entrambi dentro
`scheduleNextBuffer` su audioQueue:

1. **Fix #1 pre-apply** (~riga 1577 post fix #3) — `if let pending = self._pendingBPMValue, self.beatTickCounter + 1 == self._pendingBPMTargetTick { ... }`
2. **Fix #1 fallback nel beat callback** (~riga 1660 post fix #3) — `if let pending = self._pendingBPMValue, self.beatTickCounter == self._pendingBPMTargetTick { ... }`

In entrambi, sostituire le 3 righe del calcolo locale:

```swift
let hostTimeAtOutput = mach_absolute_time()
                     + self.outputLatencyTicks
                     + self.bufferDurationTicks
```

con una sola riga:

```swift
let hostTimeAtOutput = self.nextBufferOutputHostTime()
```

`setBPM` (path immediato) **non cambia** — DSP e Link sono già allineati
per costruzione.

### File toccati

Un solo file: `AudioEngine.swift`.

- **Layer 1** (MetronomeDSP.cpp/.h, MetronomeDSPBridge.h/.mm): invariati.
- **Bridge** `MIDIEngineBridge.h`, `LinkEngine.mm`: invariati. Il bridge
  `link_engine_set_bpm_at_time` aggiunto da fix #3 resta usato uguale.
- **MIDIEngine.mm, MIDISequencer.cpp**: invariati. Fix #2 (re-anchor)
  continua a funzionare identicamente.
- **DebugView.swift**: invariata. Sezione test 100/120/140 resta per
  validazione fix #4.

### Verifica architetturale già fatta nella sessione

- `playerNode.lastRenderTime` è documentato Apple come thread-safe.
- `bufferDurationTicks`, `outputLatencyTicks`, `playerNode` sono tutte
  proprietà di istanza accessibili nel contesto dei due callsite (su
  audioQueue, dentro `scheduleNextBuffer`).
- Fallback non introduce regressione (identico a fix #3 attuale).

### Target post-fix #4

- Errore residuo sotto 5ms = 0.012 beat a 140 BPM
- Bene oltre soglia DIRECTOR-ASSERT (0.04), impercettibile all'orecchio
- Test: 5 cambi consecutivi 120 → 140 → 120 → 140 → 120 con 10s tra
  l'uno e l'altro. SB resta allineato a Q-B dopo ogni cambio.

---

## Domanda aperta — RISPOSTA

> "`playerNode` è accessibile come `self.playerNode` in `scheduleNextBuffer`?"

**Sì, confermato.** Verificato con grep su `AudioEngine.swift`:

```
147:    private let playerNode = AVAudioPlayerNode()
```

`private let` come proprietà di istanza di `AudioEngine`. Accessibile come
`self.playerNode` (o anche solo `playerNode`) da qualsiasi metodo di
istanza della classe, incluso `scheduleNextBuffer` e il futuro helper
`nextBufferOutputHostTime()`. Nessuna restrizione di scope o closure.

Inoltre `playerNode.lastRenderTime` non è usato altrove nel codice
(verificato con grep) — niente collisioni o pattern esistenti da
preservare.

---

## Tech debt aperto

### #17 — Ableton Link perde peer dopo sessioni lunghe

**Sintomo osservato 11/05/2026:** dopo ~30 minuti di test continui di Q-B +
SB connessi via Link, SB è scomparso dalla lista peer di sua iniziativa.
Recovery: toggle Link OFF/ON dall'app Q-B per ricreare la session da zero.

**Ipotesi non ancora investigate:**

1. iPhone andato brevemente in background → ABLLink chiude la session
   (esiste fix in `applicationDidBecomeActive` per il ritorno foreground
   ma potrebbe non coprire dip momentaneo)
2. Soundbrenner battery saving / sleep modalità → SB chiude la
   connessione di sua iniziativa
3. Bug latente reconnect Q-B dopo lunga inattività

**Specifica per indagine futura:** Mauro ha confermato che la recovery è
via toggle Link nell'app Q-B (Layer 3 `setLinkEnabled`), non via riavvio
SB né WiFi iPhone.

**Priorità:** non bloccante per Task D né per L1.b. Da indagare prima dei
test palco veri (prima della prima performance live).

### #14, #15, #16 — rimangono dalla sessione 11/05

Vedi `BOX3_V51_11_05_2026.md` sezione "Tech debt" per dettagli:

- **#14** — `beatsPerBar` `@Published` letto su audioQueue in
  `scheduleBPMChange`. Da trasformare in mirror `_beatsPerBar`
  audioQueue-private all'inizio di L1.b.
- **#15** — Sezione "Test Task D" in `DebugView.swift` (3 pulsanti
  100/120/140 BPM). Da rimuovere pre-merge L1.b, quando i veri cambi
  sezione triggereranno `scheduleBPMChange` automaticamente.
- **#16** — Refactor `sectionEndedSubject.send()` da AudioEngine al
  callsite Layer 3 (per discriminazione fine-vera vs intermedia
  in L1.b). Da fare durante L1.b.

---

## Stato documenti

### BOX5 V21 — corrente

`ARCHIVIO.MD/11_05_2026/BOX5_V21_11_05_2026.md` è la fonte autoritativa
delle spec. **Nessuna modifica necessaria** in seguito a fix #1+#2+#3+#4:

- Modello dati invariato
- Token visivi invariati
- Invarianti Layer 3 invariati (la documentazione Task D in BOX5 V21
  resta valida — il sintomo SB-anticipa è un dettaglio implementativo
  di propagazione, non un cambio di specifica)
- Il "limite v1 modalità Direttore" già documentato in BOX5 V20 (ereditato
  in V21) restava aperto come "in regime stabile drift transitorio". Il
  problema fix #3/#4 è uno specifico aspetto di precisione hostTime, che
  rientra in quell'invariante senza richiedere modifica della spec.

### BOX3 V51 — corrente

`ARCHIVIO.MD/11_05_2026/BOX3_V51_11_05_2026.md` documenta la sessione
11/05 con Task D pushato e test su device pendente. Sezione "Test su
device" segnata `🟡 PENDENTE`. **Aggiornamento richiesto** alla prossima
sessione (BOX3 V52 quando Task D verde dopo fix #4).

### Da scrivere nella sessione successiva

- **BOX3 V52** — sessione 12-13/05 con esiti fix #3 (insufficiente) +
  fix #4 (atteso verde) + test 5 cambi consecutivi.

---

## Riapertura sessione successiva

Prompt suggerito:

> "Leggi `ARCHIVIO.MD/12_05_2026/HANDOFF_TASKD_12_05_2026.md` per stato.
> Applichiamo fix #4 (helper `nextBufferOutputHostTime` con
> `playerNode.lastRenderTime`) sui due callsite Task D in
> `AudioEngine.swift`. Diff già architetturalmente ratificato in sessione
> precedente — passare direttamente al diff testuale per review, poi
> commit `Task D fix #4: use playerNode.lastRenderTime for hardware-accurate
> output hostTime`, push, test su device con 5 cambi consecutivi
> 120→140→120→140→120 a 10s di distanza."

---

## Vincoli da custodire (memoria di sessione)

- **Niente pezze.** I 4 fix incrementali documentano un'iterazione
  diagnostica onesta, ognuno risolve una causa reale separata. Nessun
  commit è una toppa cosmetica. Stessa disciplina per fix #4.
- **Layer 1 inviolato fino a ratifica esplicita.** Fix #4 non lo tocca.
  L'eccezione `cancelPendingBPM` in fix #2 commit `23262f7` resta unica
  modifica Layer 1 ratificata per Task D.
- **Protocollo review pre-commit per file critici.** `AudioEngine.swift`
  è file critico — diff testuale completo va in chat per review Mauro +
  Claude Chat prima del push.
- **Test su device obbligatorio prima di chiudere.** Niente fix
  dichiarato "verde" senza esiti su iPhone 13 + Soundbrenner reali. I
  log iMazing sono parte integrante della validazione.
