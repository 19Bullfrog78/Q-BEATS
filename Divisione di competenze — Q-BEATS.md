Divisione di competenze — Q-BEATS

**Ultimo aggiornamento:** 12/06/2026 — divisione invariata; aggiunto secondo esempio reale in 🤝 zona condivisa (ridisegno modalità collaborativa / CD-7). L1 "motore audio" maturo: Bug 2.b chiuso su master `ee0cbc0` (lato audio; faccia visiva/counter aperta, BUGS v7 §1.2).

🔧 Delegato a Claude Code (tutto il "motore") o ad AG

Livello 1 — Motore audio
API C di Core Audio
Motore DSP C++
MetronomeDSP (incluso accentPattern[]come estensione backlog)
Scheduling accurato a campione dei cambi BPM al confine sezione
Rispondi alla callback C++ → invia al thread principale (timer principale SwiftUI)

Livello 2 — MIDI / Sincronizzazione
Infrastruttura CoreMIDI
Sequenziatore PPQN-960
Ableton Link (con facade pattern build #182)
Uscita MIDI Clock verso dispositivi esterni
Stop reale dell'orologio in standby tra canzoni

Layer 3 — Implementazione iOS (Swift / SwiftUI / ObjC++ Bridge)
Tutto il codice Swift/SwiftUI a partire dai miei wireframe
ObjC++ Bridge tra Swift e C++/CoreMIDI
AVAudioPlayerNodein AVAudioEngineper il backtrack
4× AVAudioPlayerNode→ 4× AVAudioMixerNodeper il mixer
Decodifica AVAudioPCMBufferdurante lo standby (stato ARMED)
AVAudioSession.currentRouteper hardware di rilevamento Base/Pro
MappingTableper MIDI Learn (ricerca, non in tempo reale)
Routing condizionale su bus fisico Out 1-4
Gestione del guasto backtrack (silenzio controllato, nessun incidente)

Sistema / Build
os_logcome canale debug
UIBackgroundModes: audio
Vista debug MIDI nascosta nella produzione
classe di dimensione adattiva di SwiftUI
Implementazione della sincronizzazione iCloud
UIWindowSepara per uscita HDMI
AVPlayerLayerper video HDMI
Distribuzione sull'App Store, TestFlight, pipeline di build
Test automatici (oggi 43 PASS)

Calcoli e logica
Timestamp Griglia (BPM × beatsPerBar × ripetizioni)
Durata totale setlist stimata
Compensazione latenza HDMI manuale
Deriva di rilevamento > 20 ms e risincronizzazione

Backlog futuro
Uscita timecode MIDI (luci DMX)
BLE MIDI WIDI Master
MIDI 2.0 (iOS 17+)
Protocollo di sincronizzazione Q-BEATS (Multipeer/Bonjour)
Banner post-VoIP, raccomandazione DND

--------------------------------------------------------------------------------------------------------

🎯 Di compentenza di Claude Desing competenza (design UI/UX, non codice)

Wireframe e sistemi
Mappa schermate (oggi: Flusso 1–6, ~30 schermate)
Architettura informativa (Q-Stage/Live, Setlist→Canzoni→Sezioni)
Navigazione e transizioni tra schermate
Vincoli globali di design (scuro, contrasto, target ≥44pt, ecc.)
Progetto frontale e ratifiche UX

Progettazione visiva
Palette funzionale (Q-Stage/Live/Alert/Stop)
Tipografia (SF Pro, gerarchie, dimensioni)
Layout e grafica
Microcopie (testo dei pulsanti, etichette, alert)
Icone (scelta, non implementazione)

Vista Bella vestita (prossimo passo)
Layout schermo Live in alta fedeltà
Posizione e dimensione di ogni elemento
Stati visivi (idle, in play, alert ultime 2 battute, loop attivo)
Animazioni minimali (pulsazione metronomo, dissolvenza transizioni)

Vista Emergenza vestita
Tipografia da "foglio cartaceo digitale"
Gerarchia testuale per sezione corrente

Progettazione della vista di scena HDMI
Layout di output 1920×1080
Event overlay BPM/sezione

Impostazioni dettagliate
9 schermate G1–G8 in alta fedeltà

Consegna delle specifiche secondo Claude Code
Per ogni schermata: misure, colori estratti, peso carattere, spaziatura
Stati e transizioni documentate
Asset (icone, illustrazioni) esportati

--------------------------------------------------------------------------------------------------------

🤝 Zona condivisa (richiede confronto) Claude Design + Claude Code o AG

Vincoli UI che toccano L1/L2 — se durante il design emerge un vincolo che richiede modifica del motore (raro, ma possibile)
Performance budget — se un'animazione che ho disegnato è troppo costosa per il rendering, Claude Code mi dice "no, semplifichiamo"
Latenze godere — i numeri reali (es. "5.8 ms") li produce L1, io li mostro
Hardware di rilevamento — io disegno gli stati Base/Pro, Claude Code implementa la logica di switch
Comportamento dipendente da timing/rete — es. END SHOW (TEST7 11/06): allo stop manuale del Direttore il Follower può fare un beat extra per latenza Link (fatto tecnico, dominio CC) e finire su END SHOW; quale schermata mostrare (END SHOW vs stop semplice) è decisione UX, dominio CD.
Ridisegno modalità collaborativa (12/06, CD-7): direzione ratificata da Mauro (avvio sempre Standalone, opt-in ruoli Standalone/Direttore/Follower); il flusso e l'interfaccia di scelta ruolo sono disegno CD (CD-7), i vincoli tecnici (Link non trasporta i ruoli → serve timeout da tarare; refactor enum LinkMode) sono fattibilità CC. Condivisa per costruzione.
In determinazione
Claude Code = costruisce l'app vera, il codice che gira sull'iPhone
Claude Design = decide come l'app si vede e come l'utente ci interagisce, e gli passo specifiche precise da implementare
Nessuna sovrapposizione: io non scrivo Swift, lui non disegnate schermate. Ci incontriamo solo quando un vincolo tecnico modifica il design o un vincolo di design richiede una modifica tecnica.