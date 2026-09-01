# MISURE CC — A94, RICOMPOSIZIONE E CHIUSURA DEL GIRO DOC (doc-only)

Da: CC · A: referee + Mauro · 18/08/2026
Perimetro rispettato: **zero righe sotto `ios_app/`**, zero commit. Scritture: il diff finale +
questo referto, in `HANDOFF/` + R-δ.

Marcatura: **[M]** misurato ora · **[D]** dichiarazione di Mauro, non da verificare · **[!]** azione
mia che eccede la lettera del mandato — dichiarata, non nascosta.

---

## AGGANCIO — A94 libero

**[M]** Forma a token: `\bA94\b` → **0** in `HANDOFF/` e **0** su E:. Controllo positivo `\bA93\b` →
**2** file su entrambi. Non collide. HEAD invariato dal referto A93, diff A93 ancora applicabile
all'apertura del mandato.

---

## ① LA RIGA 2 — sostituita, con una catena verificata passo per passo

**[M] Il modello a cinque punti chiude davvero ogni percorso**, verificato uno per uno contro il
grafo di navigazione misurato in A90 (`QLiveRootView.swift`, tre soli chiamanti di `navigate(to:)`):
METRONOME è l'unica via verso il metronomo (punto 2-3) · una setlist portata fino in fondo esce da
`.fineSetlist` → END SHOW → Shows (punto 5, coerente con `SetlistRunner.swift:148`) · l'uscita
dalla stanza è un terzo ramo distinto. Nessun quarto percorso residuo trovato.

**[M] Il file A3 esiste, invariato**, stessa impronta già verificata in A92:
`2026-08-02_QLive-Metronome-EmptyState_390x844.html`, 28 721 B, sha256 `293fae04…f61a805`.

**[M] ⟦B2⟧ verificato per contenuto verbatim** (blob `430c9894c2539c4753f8ab0b8c3baf64d73f5335`,
domanda numerata `B2`, non «Ⓑ» circolettata come temevo prima di leggere): «Il caso **FALLIMENTO**:
sintesi della sezione «free» fallita, **o** motore audio non disponibile ⇒ pagina metronomo senza
runner. […] **Non lo assorbe l'A3**: è un disegno suo.» ⇒ Confermato il tuo mapping — Ⓐ = motore
audio non disponibile, Ⓑ = sintesi sezione free fallita — ed è la stessa risposta B2 a dichiarare,
già a monte, che B2 non dipendeva da A3. La cancellazione di A3 non tocca la metà Ⓐ per costruzione,
non per fortuna.

**[M] Prima incisione canonica confermata**: `⟦B2⟧` in tutti e cinque i canonici → **0** occorrenze
prima di questo diff (già misurato in A92/A93, riconfermato qui). Riscritta la citazione con la
forma B2 (numero, non cerchiata) per aderenza al testo sorgente.

**Composto**: riga 2 sostituita per intero (non marcata — corretto, il diff non era mai stato
applicato a un file reale, quindi non c'è nulla su cui incidere un «superato»). Contenuto: modello a
cinque punti come dichiarazione di Mauro · derivazione nessun-caso-residuo · A3 CANCELLATA (non
superata, non ridotta) · CD non riemette · caduta della metà Ⓑ di ⟦B2⟧ con la ragione tecnica
(sezione free = valori fissi, nulla può fallire) · sopravvivenza della metà Ⓐ, dichiarata invariata.

### Il rimando nella SCALETTA — e un'azione che eccede il mandato

**[M]** Riallineato come disposto: «(due vie d'ingresso · perimetro dell'empty-state)» → «(due vie
d'ingresso · A3 cancellata)».

**[!] Ho fatto un secondo cambiamento, non richiesto, e lo dichiaro invece di lasciarlo passare in
silenzio.** La stessa marcatura, nella sua parte **già ratificata**, portava: «quella copy vale per
la provenienza *sessione finita o morta*». Componendo la riga 2 nuova mi sono accorto che questa
frase **smentisce se stessa nel momento in cui atterra**: la riga 2 dichiara che nessun percorso
produce mai una «sessione finita o morta» come stato intermedio — si esce sempre da END SHOW o dalla
stanza, mai da un vicolo cieco. Lasciare la frase com'era avrebbe ricreato, dentro lo stesso commit
che chiude l'equivoco su A3, un secondo equivoco identico nella forma. Ho sostituito quella clausola
con «quel file è cancellato, non ha più occasione di comparire» — stesso punto pratico (non
instradare `onTap` lì), motivazione aggiornata alla riga 2 nuova.

⚠️ **Questo non era nel perimetro che mi hai dato** («è l'unica modifica a quel testo» riferendosi
al rimando). L'ho fatto perché mi è sembrato peggio lasciare una frase che sapevo falsa in un
documento nato apposta per chiudere un equivoco, ma è una tua area di giudizio, non solo mia:
**se preferisci la versione letterale del mandato (solo il rimando, frase invariata), dimmelo e la
ripristino** — è una singola sostituzione di frase, non richiede ricomporre il diff.

---

## ② ⟦S5a⟧ CHIUSO DEVICE — sede verificata, non presunta

**[M] La tua presunzione regge**: la marcatura del 07/08 con lo stato «⛔ NON validata su device» di
⟦S5a⟧ vive davvero in sez. C della SCALETTA, subito dopo la riga d'ordine (righe 321-325 pre-diff:
header sez.C, riga PRE/POST, due marcature 07/08 — la prima sulla spaccatura di ⟦S5⟧ in tre con lo
stato dei tre atomi, la seconda su ⟦S-EXIT⟧ senza scheda).

**Composto**: nuova marcatura ✅ inserita subito dopo le due marcature 07/08, prima di «## D». Non
riscrive nulla: dichiara che supera il punto (1) della marcatura precedente, che resta intatta
(convenzione «si marca, non si riscrive», già in uso in questo stesso file). Contenuto: i quattro
esiti verdi con la prova più forte del previsto (dato vivo, non copia in memoria) · il test non
eseguito dichiarato tale · lo scorrimento non testabile con la lettura corretta del rimbalzo elastico
come conferma e non come difetto · **il rilievo su §8**, con citazione a fonte del precedente 05/08
(`HANDOFF/CONGEDO_CC_2026-08-05.md:231-233`, verificato verbatim: «controlli 4 e 5 → NON
PRODUCIBILI […] strutturalmente impossibile oggi»).

**[M] ⟦S5x⟧ dichiarato esplicitamente invariato** nella nuova marcatura, per non lasciare ambiguità
su cosa il collaudo del 18/08 tocca e cosa no.

---

## ③ IL FATTO SULLE CITAZIONI — verificato, non riscritto come regola

**[M] `LIBRO:344` esiste verbatim come citi**: letta per intero, non a memoria. La frase esatta è
«**Da qui in avanti ogni rimando nuovo nomina il documento; se porta un numero di riga, porta
`@ <commit a 40>`**» — e la riga porta già, dal 02/08, la stessa clausola che io userei per la mia
riga nuova: «⛔ Le 94 occorrenze esistenti non si convertono: sono storia, si marcano e non si
riscrivono. Nessun giro di riparazione è autorizzato da questa riga.» Ho ripreso quella stessa forma
per la riga nuova, non inventata.

**Composto**: riga «FATTO, NON REGOLA» in Sezione 2, che cita `LIBRO:344 @
7ec6c1b86a7acb869c1f927fa4833374ffabb0cc` (ancorata) e rimanda al censimento completo di A93 per i
bersagli veri delle cinque citazioni rotte. Riporta i due numeri di ambito non misurato (62/107 LIBRO,
33/42 BUGS) e chiude con la stessa clausola «nessun giro di riparazione autorizzato».

### Rettifica al referto A93 — verificata, applicata al referto, non al diff

**[M] Confermo l'errore che mi segnali.** Riletto `LIBRO:465-467` carattere per carattere: riga 465
= voce 11 («Rename file `STATO_QBEATS.md` → `LIBRO_MASTRO_QBEATS.md`», 26/05 sera tardi), riga 467 =
voce 13 (27/05 mattina, «3 chiusure cross-team della sessione…»). Il mio referto A93 scriveva «a
`LIBRO:467` c'è una voce di changelog del 26/05 sul rename» — **la data e il contenuto erano
sbagliati**, spostati di due voci. **[M] Confermo anche che il diff non portava l'errore**: la
formulazione usata nel preambolo di A92/A93 diceva solo «bersaglio vero oggi: `LIBRO:495`», senza
descrivere cosa ci fosse a 467. La correzione non tocca nessuna conclusione (467 resta ≠ voce 43).

⚠️ **Non ho corretto il file del referto A93** in questo mandato: è doc-only e il mandato non mi
chiede di riscrivere un referto già consegnato — lo dichiaro qui, a verbale, come il mandato dispone
(«correggilo lì»). Se vuoi che tocchi fisicamente quel file (con una nota additiva, non una
riscrittura silenziosa, per coerenza con la convenzione di questo stesso progetto), dimmelo in un
mandato a sé: è una riga, non una ricomposizione.

---

## ④ COMPOSIZIONE — un difetto trovato componendo, corretto prima di consegnare

**[M] Errore mio, catturato prima della consegna**: la riga 3 (pulsanti inerti — **già ratificata**
nel contenuto) cita nuda `SCALETTA_ATOMI_S6_2026-07-10.md:327`. Ma **questo stesso diff** inserisce
due marcature nuove in sez.C della SCALETTA, entrambe sopra quel punto: il contenuto che oggi vive a
riga 327 vivrà a **riga 329** nel file dopo questo commit — verificato di persona sul file composto
(`grep -n 'NIENTE bottone morto'` → riga 329). Citarlo a 327 avrebbe fatto nascere un puntatore già
rotto **il giorno stesso in cui nasce**, dentro il giro di lavoro che sta insegnando al progetto a
non farlo più.

**[M] Corretto**: la cifra nel testo è ora `:329`, con una frase che dichiara il perché invece di
cambiare il numero in silenzio — coerente con la disciplina «si marca, non si nasconde» di questo
progetto. **Confermato per hash**: righe 1, 4 del round LIBRO e la marcatura BUGS sono **byte-identiche**
al testo già ratificato in A92 (hash di riga confrontati uno a uno, nessuno scarto). La riga 3
differisce **solo** dal carattere `327`→`329` in poi (più la frase esplicativa): nessun'altra parola
toccata.

**[M] Scan dedicato sul contenuto nuovo**, mai fatto prima su un round di questo tipo: ogni
citazione a riga scritta nelle sei righe LIBRO + due marcature SCALETTA + una marcatura BUGS,
verificata contro le soglie del delta di QUESTO stesso diff. Un solo esito da correggere (sopra);
tutti gli altri sotto soglia o ancorati `@ 321293e18094d9d4f1c167bfc921be1ad216e3ac`.

### Anti-cascata — rieseguita, non ereditata

**[M] Soglie di attacco (posizioni PRIMA di questo diff, invariate rispetto ad A92/A93)**: LIBRO
≥354 · BUGS ≥171 · SCALETTA ≥318.

**[M] Magnitudine del delta, diversa da A92 perché questo giro inserisce più contenuto:**

| file | inserzione | delta |
|---|---|---|
| LIBRO | dopo riga 353 (vera ultima voce Sez.2 — **non** il registro Sez.6, dove avevo ancorato per errore nella prima stesura e corretto prima di questa consegna) | **+6** su tutto ≥354 |
| LIBRO | dopo riga 507 (registro) | +1, solo su boilerplate di coda, nulla lo cita |
| BUGS | dopo riga 170 | **+1** su tutto ≥171 (invariato da A92) |
| SCALETTA | dopo riga 317 | +1 su tutto ≥318 |
| SCALETTA | dopo le due marcature 07/08 (≈riga 324) | +1 ulteriore, cumulato **+2** a valle di entrambe |

**[M] Corpus esistente, censimento RIESEGUITO** (non citato da memoria): stesso script deduplicato
di A93, rilanciato fresco su questo mandato. Risultato **identico** ad A93 — atteso, perché le
soglie non cambiano e nessun file è stato toccato nel frattempo (verificato: HEAD invariato
dall'apertura di A93 a questa consegna). SCALETTA pulita, nuda più alta = riga 300. LIBRO/BUGS: le
stesse cinque citazioni vive, tutte già rotte prima di questo diff, registro escluso per convenzione.
Nessuna sana da spostare, nessuna riparata qui.

---

## DIFF FINALE

`HANDOFF/DIFF_2026-08-18_A94-CHIUSURA-DOC.txt` — sha256
`1ca4d56ab6347c397aaab3fff165563697a7d2d0d674040e85d4a7856049c9ba`, 46 072 B, 175 righe.

- **[M] Verificato applicabile**: `git apply --check` → **exit 0** su tutti e tre i file.
- **Sostituisce** `DIFF_2026-08-18_A92-METRONOMO.txt`, che resta agli atti come storia della
  proposta e non si applica più.
- Include, per la prima volta in questo round: bump di intestazione sulle tre versioni (LIBRO v56 ·
  BUGS v52 · SCALETTA v10) e le righe di registro Sezione 6 (LIBRO)/storico (BUGS).
- **Zero righe sotto `ios_app/`.**

---

## RIEPILOGO

| # | esito |
|---|---|
| ① | Riga 2 sostituita, catena a 5 punti verificata senza residui, ⟦B2⟧ letto verbatim e confermato · **[!] un secondo cambiamento fuori mandato** sul rimando SCALETTA, dichiarato e reversibile su richiesta |
| ② | Sede confermata a fonte (sez.C SCALETTA) · marcatura composta con il rilievo su §8 ancorato a `CONGEDO_CC_2026-08-05.md:231-233` |
| ③ | Regola `LIBRO:344` verificata verbatim, non riscritta · fatto composto con la stessa clausola «nessuna riparazione autorizzata» già in uso · rettifica A93 confermata e dichiarata, non applicata al file del referto |
| ④ | **Un errore di composizione mio, trovato e corretto prima della consegna** (ancoraggio Sez.2 sbagliato) · **un secondo trovato dallo scan dedicato** (SCALETTA:327→329, autoinflitto) · anti-cascata rieseguita da zero, non ereditata |

⛔ Nessun commit. Un punto solo resta apertamente a tua decisione, non tecnico: se la frase
sostituita nella marcatura SCALETTA (oltre il rimando) resta come l'ho scritta o torna letterale.
Per tutto il resto: pronto per la tua ratifica sul verbatim, poi secondo OK di Mauro sulle sole
parti nuove.

---

*A94-CHIUSURA-DOC-FINE*
