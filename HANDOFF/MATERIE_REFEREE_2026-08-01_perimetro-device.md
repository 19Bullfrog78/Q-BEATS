# MATERIE REFEREE — perimetro di prodotto, parco di test, geometria
## 2026-08-01 · DEPOSITO, NON RATIFICA

Prompt di origine: `QB-2026-08-01-U1-DEPOSITO`. Scritto da CC su richiesta del referee.
File **untracked** in `HANDOFF/`.

⛔ **QUESTO FILE NON RATIFICA NULLA.** Nessun canonico è stato toccato, nessun ticket è
stato aperto, nessun commit è stato fatto sui canonici. Esiste perché la voce del referee
non atterra su disco — falla misurata il 01/08/2026 — e queste nove materie vivevano
soltanto in chat.

⛔ Le nove materie che seguono sono trascritte **VERBATIM** dal prompt del referee.
Nessuna riformulazione, nessun giudizio di CC. Dove compare un rilievo, una proposta o una
misura, sono del referee e si dichiarano da sé.

---

═══ 1. PERIMETRO DI PRODOTTO, DICHIARATO DA MAURO IL 01/08/2026
 · iPHONE: dal modello 11 al modello 17 compreso.
 · iPAD: tutto il parco, dal mini 7,9"/8,3" al Pro 13".
 ⛔ ESCLUSO ESPLICITAMENTE il ripiego del «pulsante di ingrandimento»: quel controllo
   esiste SOLO per le app dichiarate iPhone-only, che iOS esegue in finestra con bordi neri
   e raddoppio non nativo. Averlo richiederebbe di RINUNCIARE al supporto iPad e l'app
   diventerebbe «app per iPhone» sull'App Store iPad. Non è un'alternativa: è la resa.
 ⚠️ RILIEVO DEL REFEREE, decisione aperta di Mauro: il perimetro dichiarato parte
   dall'iPhone 11, ma il minimo tecnico è iOS 16.0 che arriva all'iPhone 8. Oggi un
   iPhone 8 PUÒ installare l'app e nessuno garantisce che funzioni. O si alza il
   deployment target, o si estende il perimetro. Non urgente, da non perdere.

═══ 2. ⛔ VINCOLO DI TEST, DICHIARATO FONDAMENTALE DA MAURO
 I test su dispositivo reale si possono fare SOLO su: iPhone 13 (390×844) e
 iPad 7ª generazione 10,2" (810×1080). Nessun altro dispositivo è disponibile, né lo sarà.
 ⛔ Il modello posseduto da Mauro è IRRILEVANTE per il prodotto: l'app non si adegua al
 dispositivo di prova.
 MISURA DEL REFEREE — copertura reale: 2 configurazioni su 15.
   iPhone non coperti: 375 · 393 · 402 · 414 · 428 · 430 · 440  (7 su 8)
   iPad   non coperti: 744 · 768 · 820 · 834 · 1024 · 1032      (6 su 7)
 ⇒ Ma sono i due punti GIUSTI: iPhone 13 è esattamente la baseline (sf 1,000) e iPad 7 è
   esattamente l'altezza peggiore (520pt, la stessa di 8 iPad su 12).

═══ 3. ⚠️ CONSEGUENZA SULLA REGOLA «CHIUSO = DEVICE-VALIDATO» — ruling del referee
 Con questo parco quella regola va SPEZZATA IN DUE CLASSI:
  · CLASSE A — comportamento (audio, timing, Link, navigazione, tocco reale):
    gate sui due dispositivi. REGOLA INVARIATA.
  · CLASSE B — geometria (larghezze, altezze, aree toccabili, traboccamenti):
    NON provabile sul parco. Si chiude PER COSTRUZIONE, con un invariante dimostrato,
    MAI per prova su dispositivo. Il gate fisico resta solo di NON-REGRESSIONE.
 ⛔ Questa distinzione NON è ancora ratificata: è una proposta del referee.

═══ 4. PROPOSTA — VERIFICA GEOMETRICA IN CI, non un ripiego
 La CI gira su runner macOS: Xcode e i simulatori sono già disponibili.
 Si possono generare a ogni build le schermate su TUTTE le dimensioni del catalogo
 (iPhone 375/393/402/414/428/430/440 · iPad mini/10,2"/11"/13") e verificare
 automaticamente che nulla trabocchi e che nessuna area toccabile scenda sotto 44pt.
 ⇒ Parco fisico = 2. Parco di verifica = tutto il catalogo.
 ⚠️ NON prova tocco né audio: prova la geometria, che è esattamente la classe B.
 ⛔ Fattibilità NON verificata a fonte: nessuno ha ancora misurato cosa offre il runner.

═══ 5. TD-touch-target-sotto-44 — 🟠 OPEN MEDIA
 `scaleFactor = width/390` (BOX5:68). A 375pt sf=0,9615: un'area toccabile da 44pt rende
 42,3pt. ⚠️ DENTRO IL PERIMETRO DICHIARATO i modelli a 375pt sono TRE, non sette:
 iPhone 11 Pro · 12 mini · 13 mini. (SE 2/3 e 8 restano fuori dal perimetro ma dentro il
 minimo tecnico — vedi materia 1.)
 Precedente in casa: bug hit-area ⟦S3⟧, gate device 14/07, build #564 `c77d69f`.
 Fix candidato NON ratificato: pavimento `max(44, pt × sf)` sulle SOLE aree toccabili —
 parte visibile invariata, formula globale e TD#23 intatti.
 ⚠️ Fonte HIG 44×44 DA ACQUISIRE (§7): oggi [R] su fonti secondarie concordi.
 ⚠️ CLASSE B: nessun 375pt nel parco. Chiude per costruzione; gate su iPhone 13 solo
 di non-regressione.

═══ 6. TD-linea-694-iphone-corto — 🟡 OPEN BASSA
 Foglio CD 390×812. ⚠️ RIVISTO COL PERIMETRO NUOVO: gli iPhone a 693-694pt di altezza
 utile (SE/8/8 Plus) sono FUORI dal perimetro dichiarato. Dentro il perimetro 11-17
 l'altezza utile minima è 844. ⇒ LA SECONDA LINEA A 694 NON SERVE PIÙ.
 ⛔ Resta valida la sola linea 520 (iPad), nella forma «raggiungibile per scroll, o non ci
 sta», e solo sulle schermate a schermo fisso. Dominio: CD.

═══ 7. TD-device-validazione-td23-disallineato — 🟡 OPEN BASSA / doc-hygiene
 BOX5:48 dichiara TD#23 chiuso su «iPad pre-2018 a 768pt»; il dispositivo di prova reale è
 un iPad 7ª gen (810pt). Il numero non cambia — 520pt su 9,7", 10,2", 12,9" — ma la
 tracciabilità sì. Dominio: CC.

═══ 8. RATIFICATE, di CD — non sono ticket
 · iPHONE-FIRST A 390pt (referee, 01/08). CD disegna su 390.
 · CLAMP LOCALE PER SCHERMATA. Precedente device-confermato:
   `sf = .pad ? min(width/390, height*0.92/844) : width/390`, commit `87d22a9`,
   TD-ipad-home 🟢 CHIUSO 30/06/2026. ⚠️ La formula usa 844 NON 812, e lo 0,92 è dichiarato
   «manopola di taratura a vista»: chi la riusa la ri-tara, non la eredita.
 ⛔ RITIRATI da CD e NON da incidere: cap globale `min(w/390,h/812)` e tetto ~1,3×.
   Un ritiro non lascia traccia.

═══ 9. STRADA B — decisione di prodotto in coda, non aperta
 MISURA DEL REFEREE, [R] da sorgentare ad Apple: escursione dentro il parco iPad
 744→1032 = 1,39× · altezza utile 520pt su 8 modelli su 12, 594 sul più generoso = 1,14× ·
 salto iPhone(390)→iPad(744) = 1,91× · escursione dentro il parco iPhone 11-16
 375→440 = 1,17×.
 ⇒ «Tutti gli iPad» NON è la difficoltà: gli iPad si somigliano fra loro più di quanto un
 iPhone somigli a un iPad. L'unico salto vero è iPhone→iPad, ed è tecnicamente superabile
 senza compromessi.
 Strada A (BOX5:68, in vigore, device-validata) funziona ma produce un iPad che è un
 iPhone ingrandito. Strada B («rimandata a v2 reale») è la strada giusta: usare lo spazio
 in più per mostrare PIÙ COSE, non le stesse più grandi.
 ⛔ NON si apre ora: prima ⟦S5⟧ e ⟦S6F⟧ — senza schermate finite non c'è nulla da
 riorganizzare. La porta di CD («se una schermata è irriducibile torna in decisione») si
 apre con RATIFICA DI MAURO, mai con una consegna.

⚠️ MISURE NON ACQUISITE, dichiarate: le dimensioni in punti dell'iPhone 17 — entra nel
perimetro ma non nelle tabelle. Tutte le dimensioni di schermo sopra sono [R] a memoria
del referee e vanno sorgentate ad Apple prima di entrare in un canonico.
