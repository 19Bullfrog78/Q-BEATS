# SEGNAPOSTO — A265 OCCUPATO

ID `A265` prenotato da CC (questa chat, la stessa che ha depositato `A263` e il congedo `A264`) prima di produrre il referto che la riemissione del mandato — dopo l'annullamento di `A264` per collisione, ratificato dal referee — chiede.

**Perché A265 e non un altro numero:** `A264` è annullato per collisione (misurata da questa chat, ratificata dal referee). Il nuovo mandato assegna a CC la scelta dell'ID, a partire dal primo libero da A265 in su.

Verifica eseguita prima di questa prenotazione, binari esclusi (`grep -rlI`):
- nome file: C: 0 · E: 0
- contenuto: C: 2 (due documenti che *citano* «A265» come esempio di trappola grep-su-binari, non lo usano come ID — `CONGEDO_CC_2026-08-30_A264-IN-AUTONOMIA.md` §e.1 e `MISURE_CC_2026-08-30_A266-PERCHE-LE-REGOLE-NON-TENGONO.md` §0) · E: stessi due + rumore in log TD17 (`LOG/RUN/TEST LUNGA DISTANZA/*.log`), spot-verificato: il match reale è `FA265`/`A2654`, frammento di UUID WiFi (`corewifi`/`QoS`), non l'ID isolato — stesso pattern del falso positivo sui font già documentato.
- `git log --all --grep="A265"`: 0.
- Positivo `A240` (committato, noto): `git log` → 3 hit. Positivo di forma disco (`A263`/`A266`): entrambi visti su nome e contenuto, entrambe le gambe. Sonda provata vedente su entrambe le forme.
- Convergenza indipendente: il referto `A266` (altra sessione) aveva già misurato — [R] per questa chat — «A265 rende 4 senza -I e 0 con — erano font .ttf e un .pdb. A265 era libero» alle 11:33 di oggi.

`A265` era libero all'istante di questa misura, su entrambe le forme (nome+contenuto) ed entrambe le gambe (C:/E:).

**Motivo della prenotazione:** collisione fra sessioni concorrenti già accaduta due volte oggi su questo stesso disco (`A263` alle 11:18, raccontata sia dal congedo `A264` sia dal referto `A266`). Il cancello a quattro gambe guarda solo il passato e non ha mutua esclusione (`CLAUDE.md`, sezione Processo, oggi aggiornata a dirlo esplicitamente). Prenotare stringe la finestra di collisione a un istante.

Se stai leggendo questo file da un'altra sessione: **A265 è preso**. Prendi il primo ID libero successivo e scrivi anche tu un segnaposto prima di lavorare.

Referto finale atteso: `MISURE_CC_2026-08-30_A265-RIENTRO-CONTO-ALLA-ROVESCIA-DUE-PORTE-DELLO-STOP.md`
