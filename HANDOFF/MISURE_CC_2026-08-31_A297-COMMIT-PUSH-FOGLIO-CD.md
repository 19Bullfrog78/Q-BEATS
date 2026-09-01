# MISURE CC — A297 — 31/08/2026

Da: CC · A: referee.

**Orologio**: 31/08/2026, 13:26 locale (UTC+2) — da `date` di sistema.

Marcatura: **[M]** misurato ORA · **[R]** riportato, non verificato ora · **[A]** giudizio mio.

---

**[M] APERTURA**: LIBRO v69. `git worktree list` invariato (Desktop + `qb_fixB`). Pre-commit: HEAD locale = `origin/master` = `597961eee7b4046815f580e406a40d2d96512a51`.

**[M] Cancello ID**: `A297` libero su sei gambe (nomi C:/E:, git grep, disco C:/E:, git log --all --grep), zero collisioni. Controlli positivi `A296`/`A295` visti.

**[M] Riverifica pre-commit, con assert espliciti** — tutti passati: HEAD=origin/master coincidente; `git status` esattamente **una** riga `A`; sha256 del file in `DESIGN/QLive_Nav/` misurato **ora** (non richiamato) = `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f`, 64/64 caratteri, coincidente.

## Commit + push

sha (40 caratteri): **`5eb18c7de46dba72483710feb18416c8a9eed0a9`**
Autore = committer = `Mauro Martintoni <di_tutto@icloud.com>`. Corpo commit: solo il soggetto `DESIGN: archiviato foglio CD 30/08 (A295)`, **zero trailer**. 1 file, 393 inserzioni, 0 cancellazioni.

Push: `597961e..5eb18c7 master -> master`. `origin/master` post-push = HEAD locale = `5eb18c7de46dba72483710feb18416c8a9eed0a9`.

## Verifica a destinazione — dal blob, non dal disco

`git show 5eb18c7de46dba72483710feb18416c8a9eed0a9:DESIGN/QLive_Nav/2026-08-30_QLive-Player_...390x844.html` → **59659 byte**, sha256 **`0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f`**. ASSERT PASSATO su entrambi, carattere per carattere. ⇒ L'impronta presa da CD alla partenza è ora verificata anche all'arrivo.

## CI

Run `33386656280` — **iOS Signed Build** — su SHA pieno a 40 caratteri (non corto). Esito: **success**. Tempo totale osservato dal push: ~2 minuti.

## Propagazione E: — R-δ §2 «contratti e freeze CD»

Cartella `DA_CD_PER_CC/30_08_2026/` **non esisteva**: creata ora. Depositato il file, `cmp` contro la fonte del commit (repo) → **IDENTICI**. sha256 sulla copia `E:` = `0b11c2263e977bde1d5665feabb10e0953a227f4837d8462683518e8558e5c3f`, coincide.

⚠️ **Residuo in `_TRANSITO_DA_VERIFICARE/A275_foglio-CD-30-08/`**: verificato **invariato** (stessi timestamp, stesso file, stesso sha256) — **non toccato**, come da perimetro. Resta lì: il riordino di quella cartella è lavoro suo, non di questo mandato.

## Perimetro negativo

Nessun canonico toccato (BUGS/LIBRO/BOX3/BOX5/SCALETTA). Nessun codice. Nessun altro file archiviato. Nessuna scrittura su Drive. `E:` non riordinato — solo creata la cartella datata che R-δ prescrive come destinazione nuova.

---

*MISURE_CC A297 — FINE. Lavoro chiuso: commit `5eb18c7de46dba72483710feb18416c8a9eed0a9` pushato, CI verde, verificato a destinazione, propagato su E:.*
