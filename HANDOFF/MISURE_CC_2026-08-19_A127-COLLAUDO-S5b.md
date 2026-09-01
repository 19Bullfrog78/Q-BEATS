# COLLAUDO DEVICE ⟦S5b⟧ — istruzioni per Mauro

Da: CC · Mandato **A127** · Data: **19/08/2026**
Commit: **`7c04beaf17e15c5e8d16a791e6bf18c2ff82cd76`** · CI: **`iOS Signed Build` run
`32259878138` = success**, 2026-08-19T13:47:48Z.

⚠️ **«CI verde» qui significa `iOS Signed Build`, e nient'altro.** `F1 — Build Check` **non è
un cancello**: non gira dal 31/07, le sue ultime due run sono fallite, e la decisione se
contarlo è ancora tua. Finché non decidi, ogni «CI verde» di questo progetto va letto come
parziale.

⇒ **Primo cancello passato. Questo documento è il secondo, ed è quello che chiude l'atomo.**
I passi sono presi **dalla scheda ⟦S5b⟧ a `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`**
(sha256 `d1d8b396…`, invariata dal commit), non dalla memoria.

---

## ⛔ PRIMA DI COMINCIARE — DUE AVVERTENZE, ENTRAMBE BLOCCANTI

**① UNO SHOW ALLA VOLTA. Fra uno show e il successivo, CHIUDI L'APP dal multitasking.**
Non è pignoleria: finché ⟦S6F⟧ non esiste, si può arrivare al player **con l'audio del primo
show ancora acceso e l'armamento bloccato**. Se lo fai in sequenza senza chiudere, quello che
vedi **non è un difetto di ⟦S5b⟧** — e rischi di segnalare come guasto una cosa già nota e già
assegnata a un altro atomo.

**② Se usi il percorso DEBUG con i dati di test: NON toccare NESSUNA canzone** mentre i dati di
test sono in memoria (`BUGS:143`, `TD-injecttestdata-sovrascrive-dati-reali`). Sovrascriverebbe
i tuoi dati veri.

---

## I QUATTRO PASSI

### Passo (1) — È QUESTO CHE DISTINGUE «ARMATO» DA «FERMO»

Da un dettaglio show **con brani risolti** (non uno show vuoto, non uno tutto-orfano),
tocca **START SHOW**.

✅ **DEVE SUCCEDERE:**

- compare il **titolo della PRIMA canzone**, grande e centrato in alto;
- **pulsa lentamente**, e continua a pulsare all'infinito;
- il player sotto è **visibilmente oscurato**, quasi spento;
- ⛔ **non deve suonare NULLA.**

⛔ **È FALLITO SE:** la videata è **piena e nitida** (niente oscuramento) · il titolo **manca** ·
il titolo c'è ma è **immobile**. In tutti e tre i casi il player è **fermo, non armato**, ed è
esattamente il difetto che questo atomo esiste per togliere.

**I segni sono misurati e si vedono a occhio** — non serve nessun disegno di CD per giudicare:

| segno | valore atteso | da dove |
|---|---|---|
| oscuramento del player | opacità **0,10** (quasi nero) | `LiveView.swift:129` |
| titolo | **52 pt**, al **27 %** dell'altezza schermo | `StandbyOverlayView.swift:18-24` |
| pulsazione | da **0,45 a 1,0 in 2,2 secondi**, avanti e indietro, senza fermarsi | `StandbyOverlayView.swift:31-35` |

### Passo (2) — il secondo tocco

Tocca lo schermo **in un punto qualsiasi**.
✅ Il click deve partire **da quella canzone** — la prima, quella il cui nome stavi guardando.

### Passo (3) — la fine, e il gate arretrato di ⟦S5x⟧

Arriva a **fine setlist** → compare **END SHOW** → tocca **BACK TO SHOWS**.
✅ Deve tornare alla **lista degli show**.
⚠️ Questo passo chiude un cancello **rimasto aperto dal 06/08**: ⟦S5x⟧ era «chiuso a codice,
validazione device differita a ⟦S5b⟧», perché END SHOW era irraggiungibile finché lo slot non
aveva un mutatore. Ora è raggiungibile.

### Passo (4) — l'uscita dalla stanza

Esci dalla stanza Q-Live.
✅ **L'audio deve fermarsi.**

---

## ⛔ I DUE NON-DIFETTI — NON SEGNALARLI COME GUASTI

**① Al tocco la musica parte SUBITO, senza conto alla rovescia.**
È così di proposito: `startCountIn` è uno **stub** vuoto (`AudioEngine.swift:1561-1563`).
**Non è una regressione di ⟦S5b⟧**: è una porta che non è mai stata costruita, ed è tracciata
in un ticket a parte.

**② Fra una canzone e l'altra non c'è conto.**
Idem: il rinvio è **dichiarato nel codice** (`SetlistRunner.swift:232`). Porta mancante, non
guasto nuovo.

⚠️ **Se al gate segnali questi due come difetti, il gate risulta fallito per una cosa che
⟦S5b⟧ non doveva fare.** Per questo sono scritti qui.

---

## COSA CHIUDE QUESTO COLLAUDO — TRE CANCELLI IN UN COLPO

La scheda lo dice in chiaro, ed è il motivo per cui **non si può collaudare a metà**:

1. **il proprio** — lo Start arma e il player si monta fermo;
2. **quello DIFFERITO di ⟦S5x⟧** — END SHOW ora è raggiungibile (`SCALETTA:324`);
3. **l'armamento di `TD-mixer-copre-endshow`** — «SI ARMA CON ⟦S5b⟧, NON PRIMA» (`BUGS:158`).

⇒ **Se passi tutti e quattro i passi, si chiudono tutti e tre.** Se ne fermi uno a metà, non se
ne chiude nessuno.

---

## COME RIFERIRE L'ESITO

Per ogni passo: **PASSA** o **FALLITO**, e se fallito **che cosa hai visto**, non che cosa
pensi sia rotto. Per il Passo (1) serve in particolare sapere quale dei tre modi di fallire:
videata non oscurata · titolo assente · titolo immobile.

⛔ **Finché non arriva il tuo esito, ⟦S5b⟧ resta APERTA.** CI verde non è «chiuso»: in questo
progetto «chiuso» lo dici tu, dopo il device.

---

*A127-FINE*
