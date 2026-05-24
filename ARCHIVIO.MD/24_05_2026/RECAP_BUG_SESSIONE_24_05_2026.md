# Recap bug sessione CC 24/05/2026

**Branch attivo:** `feat/diag-first-beat-and-beat-drop-and-3-4-long` (fork da `cb92faa`)
**Commit testati:** `70bb86a` (setlist 3/4 Long DebugView) + `31dddbb` (10 log DIAG-A T0-T9 in AudioEngine)
**IPA testato:** CI run [`26361824809`](https://github.com/19Bullfrog78/Q-BEATS/actions/runs/26361824809) ✅ verde, IPA artifact valido fino al 22/08/2026
**Setlist test:** L1.b (DebugView bottone viola) — Song A `Intro 100 4/4 12 batt` + `Verse 120 4/4 3 batt` + `Bridge 3/4 140 BPM 2 batt`. Song B `Slow 90 4/4 3 batt` + `Build 110 4/4 12 batt`.

---

## Tabella riassuntiva (8 bug)

| # | Bug | Layer | Priorità | Stato | Dato empirico |
|---|---|---|---|---|---|
| **1** | UI iPad Vista LIVE non si aggiorna a `.playing` | Layer 3 SwiftUI iPad | 🔴 BLOCCANTE | **Nuovo** | Screenshot fianco-a-fianco: iPhone in `.playing` (Bar 5/12, INTRO 100, microbar 12 tratti), iPad bloccato in `.stopped` CD-1 (Bar —/—, "100 BPM" big, frecce swipe ancora visibili). **Ipotesi post-lettura codice (24/05 sera CC)**: `SetlistRunner.updateSessionDisplay` (SetlistRunner.swift:227) è l'unico callsite che setta `currentSongName/currentSectionName/nextSectionName/nextSongName/macroBarCurrent/macroBarTotal`. Viene chiamato da `prepareAndStartCurrentSection` (riga 218) attivato SOLO da tap Play locale del transport. Se iPad parte via Link follower (Collaborative) senza tap Play locale, `SetlistRunner` non viene attivato → display fields restano vuoti → teleprompter cade nel fallback "BPM gigante" (TeleprompterCapsuleView:30-37) + Bar —/— + microbar vuota + frecce swipe `< >` ancora visibili. **Potenziale gap architetturale, non bug di codice**: Link standard sincronizza solo tempo/phase, NON il setlist state del Director. **Pendente conferma Mauro**: tap Play premuto su uno o entrambi i device? |
| **2** | LED iPad batte sul 2 invece che sul 1 | Layer 3 binding LED | 🔴 critico | **Nuovo** | Click audio sempre giusti, accent sul 1 all'unisono iPhone/iPad. Solo LED visivo sfasato. "Sussulto / doppio colpo ravvicinato". Frequenza 3/10 play. Va fuori sync nei 3/4. **Nota referee AI esterna (24/05)**: probabilmente cade con Bug 1 — se LiveSession iPad non sa di essere in `.playing`, i guard `audioEngine.isPlaying` nei handler del beat tick si comportano in modo anomalo e il LED rendering è inaffidabile. Fixato Bug 1, LED può tornare a posto da solo. Altrimenti investigare come bug separato dopo |
| **3** | "140 BPM" residuo in `.stopped` su Song B | Layer 3 iPad header | 🟡 medio | **Nuovo** | Song B non ha 140. È il BPM della Bridge 3/4 di Song A (sezione precedente) che resta congelato sull'header iPad. TS invece si aggiorna |
| **4** | Sleep/wake schermo rompe Link | Layer 2 background | 🟠 alto | **Nuovo** | Bug noto iOS: multicast Link sospeso dal kernel quando app va in background. Workaround: restart app peer. **Nota referee AI esterna (24/05)**: il fix `applicationDidBecomeActive` con `setLinkEnabled(true)` esiste GIÀ (commit `9a2e529`, BOX5 V23). MA LinkKit ignora `setLinkEnabled(true)` se lo stato non cambia (già true) → ri-asserzione no-op. Fix vero: **toggle `setLinkEnabled(false)` → `setLinkEnabled(true)`** (spegni e riaccendi la sessione Link) su `didBecomeActive`. CC deve verificare commit `9a2e529` durante lettura codice AudioEngine |
| **5** | TD #A first-beat-fuori (preesistente) → **misura precisa** | Layer 1/2 audio iPad | 🔴 noto | **Riformulato** | T4→T5 = pre-roll 2.2s + **100-118ms ritardo sistematico** cross-play cross-BPM. startBeat finale 0.032-0.036 beat. La hp originale 67-73ms era sottostimata |
| **6** | TD beat drop strutturale | Layer 2 sync_phase | 🔴 noto | **Riconfermato** | Log iPad pieno di `[LINK] Phase sync` decine al secondo. Confermata memoria `feedback_qbeats_sync_phase_smoothing_strutturale` |
| **7** | TD #39 quantum 3/4 fuori sync | Layer 1/2 quantum | 🟡 noto | **Confermato sintomatico, Audacity NON fatto** | Mauro: "VA FUORI SINC NEI 3/4". Bridge 3/4 Song A 140 BPM 2 batt è troppo corta — Test 2 setlist 3/4 Long (16 batt) bloccato dai bug UI |
| **8** | Cascading rename pulsantiera CD-4 incompleto | Layer 3 UI labels | 🟡 medio | **Ereditato da `cf3f0b5`** | KILL BASE → KILL TRACK, PREV SEZ → ?, NEXT SEZ → ?, EMERG → EMERGENCY. Su entrambi i device. File saltato: `TransportView.swift` (5 stringhe: `prev sez`, `next sez`, `emerg`, glyph `KILL\nBASE`, `loop`) |

---

## Cose NON eseguite in questa sessione

- ⏸️ **Test 2 Audacity 3/4 Long** — bloccato dai bug visivi UI iPad (impossibile fare misure pulite con LED off-beat e UI rotta)
- ⏸️ **TD #34** race `start_stop_callback` — mai testato empiricamente, fuori scope di oggi

---

## Decisioni che vanno a CD prima di toccare codice

- **Bug 3**: cosa **dovrebbe** mostrare il teleprompter in `.stopped` CD-1 cerimoniale? "100 BPM" big è feature di CD-1 vetrina o bug? Su iPhone in `.playing` mostra il nome sezione, ma in `.stopped` CD-1 cosa dovrebbe essere?
- **Bug 8**: label esatti — `PREV SECTION` o solo `PREV`? `NEXT SECTION` o solo `NEXT`? `EMERGENCY` confermato. `KILL TRACK` confermato.

---

## Decisioni che restano a CC (tecniche, niente CD)

- Bug 1: come fixare il binding `LiveSession.state` su iPad
- Bug 2: come fixare il publisher LED iPad
- Bug 4: come gestire Link sleep/wake (`ABLLinkSetActive` toggle su `didBecomeActive`)
- Bug 5: dove fixare il dispatch chain iPad (T4→T5 100ms ritardo)
- Bug 6: design alternativo sync_phase + smoothing a valle in DSP
- Bug 7: dopo Test 2 Audacity, verdetto chiusura o riapertura

---

## Ordine intervento proposto

**Prima ondata (subito)** — bug visibili UI bloccanti:
1. **Bug 1 + Bug 8 insieme** (stessa area codice — Vista LIVE iPad + pulsantiera CD-4)
   - Lettura `LiveView.swift`, `LiveRootView.swift`, callsite Grep
   - Grep generico stringhe italiane residue
   - Fix binding `@EnvironmentObject` iPad
   - Fix label cascading rename in `TransportView.swift`
2. **Bug 3** dopo lettura, una volta capito perché publisher residuo non si resetta su navigate

**Seconda ondata (post UI fix)**:
3. **Bug 2** LED off-beat — molto probabilmente cade insieme a Bug 1 (stesso publisher LiveSession), se non cade è bug a parte
4. **Bug 4** Link sleep/wake — fix `ABLLinkSetActive` toggle

**Terza ondata (post UI fix)** — i bug audio:
5. Test 2 Audacity (con UI risanata) → verdetto TD #39 (Bug 7)
6. **Bug 5 (TD #A)** — analisi T4→T5 100ms ritardo (lettura codice pre-roll iPad)
7. **Bug 6 (TD beat drop)** — design three-band v2 o smoothing a valle

---

## Apertura prossima chat (proposta)

> *"Letto memorie CC + recap bug `ARCHIVIO.MD/24_05_2026/RECAP_BUG_SESSIONE_24_05_2026.md`. Partiamo da Bug 1+8 (UI iPad + rename CD-4). Vado a leggere LiveView/BarCounterView/TransportView."*

---

## Stato libro mastro

STATO_QBEATS.md **v8 invariato**. Nessuna ratifica cross-team aperta in questa sessione (sono tutti bug operativi CC interni). Quando si rinomineranno i label CD-4 servirà aggiornamento naming sez. 1 (PREV SEZ → ?, NEXT SEZ → ? — Q8/Q11 R-CD5 chiarimento necessario via CD).

---

## Domande critiche pendenti per prossima chat

1. **Bug 8 — CD: label esatti** dopo `PREV SEZ` e `NEXT SEZ` (parola sola? `PREV SECTION` / `PREV` / altro?). `EMERGENCY` e `KILL TRACK` già confermati nel libro mastro
2. **Bug 3 — CD: in stato `.stopped` CD-1 cerimoniale**, cosa dovrebbe mostrare il teleprompter? Il fallback "BPM gigante" attuale (TeleprompterCapsuleView:30-37) è feature di CD-1 vetrina (TD #25) o bug?

---

## Chiarimento Mauro sul workflow live (24/05 sera) — riformulazione Bug 1

**Confermato da Mauro**: il flusso live previsto è **per design**:
1. iPhone Director parte da solo (1 bar di intro / pickup / count-in per la band)
2. I Collaborativi (iPad / altri device) entrano successivamente premendo Play locale
3. I Collaborativi devono **allinearsi al bar counter del Director** quando entrano (es. "2 di 12" se Director è a bar 2), NON partire da "1 di 12" del proprio counter locale

**Implicazione**: Bug 1 non è "gap architetturale enorme da risolvere con Soluzione C completa", è **feature UX incompleta**. L'intent è giusto, manca solo il broadcast `(songIdx, sectionIdx, currentBar)` dal Director ai Follower.

Bug 2 (LED off-beat) e Bug 3 (140 BPM residuo) **cadono come conseguenza** — sono sintomi dello stesso `currentSectionName / currentBar / playbackState` vuoto su Follower.

Scope tecnico **drasticamente ridotto** vs Soluzione C completa (Fase 6-7):
- ❌ NON serve sincronizzare audio cross-device (già OK via Link standard)
- ❌ NON serve protocollo Wi-Fi proprietario completo
- ✅ SERVE solo broadcast leggero `(songIdx, sectionIdx, currentBar)` Director→Follower via canale ausiliario (LinkKit BeginCustomEncoding se esiste, oppure UDP multicast separato, oppure stato in NWConnection peer-to-peer)
- ✅ Quando Follower preme Play locale, legge l'ultimo broadcast e imposta i suoi counter su quei valori → `SetlistRunner.updateSessionDisplay` viene chiamato con i valori giusti

**Diventa scope medio Layer 2-3**, non scope grande Soluzione C. Va comunque ratificato cross-team (CD + Mauro per UX + naming feature, CC per fattibilità tecnica) prima dell'implementazione.

**Bug 5 (TD #A 100ms) + Bug 6 (TD beat drop) NON contribuiscono a Bug 1** — sono problemi audio precisione locale iPad, indipendenti dal sync inter-device. Restano in coda separata, non bloccanti.

---

## Ricategorizzazione finale (24/05 sera, dopo chiarimento Mauro)

| Gruppo | Bug | Tipo problema | Note |
|---|---|---|---|
| **A — Sync inter-device (UN solo problema)** | Bug 1 + Bug 2 + Bug 3 + Bug 4 | Feature UX incompleta — broadcast section state Director→Follower + Link sleep/wake | Bug 4 sotto-problema separato ma stessa famiglia "Link che rompe il sync inter-device" |
| **B — Precisione audio locale iPad** | Bug 5 + Bug 6 + Bug 7 | Problemi pre-esistenti, già in lista da settimane | Non peggiorati oggi, solo misurati meglio. Iter Sessione 1 originale 25/05 (sospesa per UI iPad) |
| **C — Cosmetica** | Bug 8 | Rename label CD-4 incompleto cf3f0b5 | 30 min lavoro quando CD risponde label `PREV / NEXT` |

Quello che è veramente emerso di nuovo oggi = **Gruppo A**. Tutto il resto era già noto o cosmetico.
