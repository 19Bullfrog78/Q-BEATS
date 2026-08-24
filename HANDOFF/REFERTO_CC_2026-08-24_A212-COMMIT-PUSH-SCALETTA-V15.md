# REFERTO CC — A212 — FERMATO: MANDATO ARRIVATO TRONCATO, GIT NON TOCCATO

Da: CC · A: referee + Mauro · 24/08/2026
Mandato: A212 (referee) — commit e push della SCALETTA v15 + quattro artefatti del giro.
**ESITO: NON ESEGUITO. Zero stage, zero commit, zero push. Nessun file toccato.**
Marcatura: [M] misurato alla fonte · [R] riportato · [A] giudizio mio.

## 1 · Il troncamento — dove, e come lo so

[M] Il testo ricevuto si interrompe subito dopo la riga:
«Messaggio, verbatim (è pubblico e immutabile, quindi non contiene nulla di non misurato):»
Il messaggio di commit NON è arrivato, né alcuna sezione successiva (push · deposito ·
cosa restituire). **Controllo positivo del troncamento:** i quattro mandati precedenti
(A209, A210, A211, e il primo A209) terminano TUTTI con «MARCATORE DI FINE: A2NN-…-FINE»;
questo non ha alcun marcatore.
[A] Un messaggio di commit dichiarato «pubblico e immutabile» non si ricostruisce e non si
inventa: senza il verbatim, il mandato non è eseguibile in nessuna sua parte. Fermato PRIMA
di ogni scrittura, come da regola.

## 2 · Le guardie, eseguite comunque (SOLA LETTURA) — TUTTE VERDI al momento della misura

- **Collisione A212: LIBERO.** Nomi repo/E:/git = 0/0/0 · contenuto repo/E: = 0/0.
  Positivi, stessa forma, su ENTRAMBE le gambe: A168=1 · A209=1 · A210=1 · A211=2
  (referto + diff). Le sonde vedono.
- **G1 ✓** — HEAD locale = `git ls-remote origin master` =
  `8727f8e422e2720b4d5086958684e6cff1ca261a`. Nessuno ha spinto nel frattempo.
- **G2 ✓** — SCALETTA nel working tree: sha256
  `18e2f4d1af7c9bf7b8de04055e8e947023295166cd68ae7d431cfcd8980deb01` · 89 757 byte ·
  LF 750 · CR 0 · NUL 0 · termina `\n`. ESATTAMENTE l'impronta A211 ratificata: il file
  non è stato ritoccato dopo.
- **G3 ✓** — i quattro artefatti esistono su C: e su E:, `cmp` a uscita 0 su tutti e
  quattro (referti A209, A210, A211 + diff A211).
- **Stage = 0** · unico tracciato modificato: ` M HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`.

## 3 · Identità dell'autore — misurata, perché la ritrasmissione non debba specificarla

[M] `git config user.name` = **Mauro Martintoni** · `user.email` = `di_tutto@icloud.com`.
[M] Gli ultimi QUATTRO commit (`8727f8e`, `8ee5485`, `d6e2415`, `203d331`) sono tutti
firmati `Mauro Martintoni <di_tutto@icloud.com>`, e nei loro messaggi `Co-Authored-By`
rende **zero**. ⇒ [A] La prescrizione del mandato («Autore: Mauro Martintoni, zero
Co-Authored-By») coincide con la configurazione del repo e con la pratica di TUTTI i
commit recenti: un `git commit` ordinario la rispetta da solo, nessun override necessario.

## 4 · Cosa deve portare la ritrasmissione

1. **Il messaggio di commit, verbatim** — l'unico pezzo davvero mancante per stage+commit.
2. Le sezioni perse dopo di esso: **push** (sì/no, e la verifica post-push richiesta),
   **deposito del referto**, **cosa restituire**, e il **marcatore di fine**.
3. Nient'altro: guardie, elenco dei cinque file, divieti e procedura di stage uno-per-uno
   sono arrivati integri e sono già verificabili (§2).

⚠️ [A] Questo referto consuma A212, come i referti A209 e A210 hanno consumato i loro ID.
La riemissione la numera il referee.
⚠️ Deposito autorizzato NON dal mandato (la sezione è persa nel troncamento) ma dalla
regola canonica: referti → `HANDOFF/`, due gambe, nell'istante in cui esistono.

*REFERTO-CC-2026-08-24-A212-FINE*
