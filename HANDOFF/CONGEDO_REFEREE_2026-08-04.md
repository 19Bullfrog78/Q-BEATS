# CONGEDO REFEREE — 2026-08-04

> **Scritto dal referee (Claude Chat). Deposito, NON ratifica.**
>
> ⚠️ **VERIFICARE, NON EREDITARE.** Ogni riga va rimisurata prima di costruirci sopra.
>
> ⚠️ **Pretendi ENTRAMBI i documenti di passaggio: questo E l'handoff di CC.** Il 03/08 la
> sessione si è aperta con uno solo, e mancava metà del quadro.

---

## §0 · IN QUATTRO RIGHE

- **Lotto `TD-fineshow-bottoni-morti` committato e PUSHATO.** Tre commit monoscopo,
  HEAD `ea3f94a4a11153a2f4c9f08ab8e1cd73d55d00ae`, verificato su `origin/master`.
- **Il pericolo è agli atti:** i due bottoni morti di `FineSetlistView` sono un ticket 🔴 ALTA /
  🚨 BLOCCANTE PALCO, e ⟦S5⟧ porta un cancello che ne vieta la chiusura device.
- **Scoperta strutturale della sessione: quattro ancore su quattro campionate erano rotte**, e due
  strumenti di misura mentono (`grep -c $'\r'`, `sed`).
- **Google Drive NON è un backup**: è un sync live di C: ed E:. La quarta destinazione è ora un
  **NAS Synology**, copia manuale, cadenza settimanale.

---

## §1 · STATO

### `[V]` — misurato dal referee stesso

| cosa | esito |
|---|---|
| Data reale | **2026-08-04**, tre orologi indipendenti (container `10:37:07Z`, macchina CC `12:02:34+02:00`, contesto di sistema) |
| Copie nel Progetto Claude | **LIBRO v51 · BUGS v47 · SCALETTA v5** — generazione VECCHIA. OID `06caa750…`, `c896f919…`, `4bacc529…` = **esattamente il lato «old»** dei diff ratificati il 02/08 |
| `LIBRO v51:153/:154/:155` | verbatim letti: `:155` dice «**Bottone** fine setlist (FineSetlistView)», **attivo** |
| Registro versioni BUGS v47 | **47 righe, 1→47, zero buchi, zero duplicati** (regex con controllo positivo e negativo) |
| Registro versioni LIBRO v51 | 49 righe, 1→51, **mancano 25 e 26**; righe v24 e v27 fisicamente adiacenti |
| Ticket `LIBRO-sez6-buco-v25-v26` | **esiste ed è 🟢 CHIUSO dal 01/08** — 3 occorrenze in BUGS v47 |
| Aritmetica delle due facce | **284 897 − 1 039 = 283 858**, e 1 039 CR su 1 039 righe = un CR per riga |
| Su Drive | v52/v48/v6 presenti coi byte dichiarati · gli oggetti sciolti di `.git` presenti · **A22 era stato eseguito** (tre diff, `2026-08-02T19:49:09Z`, in due alberi) |

### `[R]` — riportato, mai misurato dal referee

HEAD e allineamento remoto · **tutte le misure sul codice** · lo stato di C:, E: e del NAS · il
contenuto di v52/v48/v6 · le CI · i conteggi untracked (147 in `HANDOFF/`, 4 tracciati) · l'esito
dei tre commit e del push.

⚠️ **Il referee non ha mai potuto leggere Drive dopo il 04/08 mattina** (accesso negato due volte).
Le ratifiche dei tre diff poggiano su **verbatim trasportato da CC dal mirror E:**, e questo è
scritto dentro le ratifiche stesse come **grado leggermente inferiore**.

---

## §2 · DECISIONI DI MAURO — 04/08

1. **Severità `TD-fineshow-bottoni-morti` = 🔴 ALTA / 🚨 BLOCCANTE PALCO.** Firmata. Incisa in
   titolo, campo Stato e voce di registro.
2. **OK al commit** dei tre diff. **OK al push.**
3. **Quarta destinazione R-δ = NAS Synology**, copia manuale, **nessuna sincronizzazione**.
   La chiavetta è **superata** — «un qualcosa in più», non una destinazione viva.
4. **Cadenza settimanale**, non dopo ogni blocco. *(Correzione di Mauro a una regola del referee
   che era tarata su un rischio più grande di quello reale — vedi §5.)*
5. **Niente fronti nuovi il 04/08.**

---

## §3 · IL FRONTE — cosa riparte

### La coda doc, in ordine di urgenza

1. ⚠️ **`LIBRO:336` dice «la chiavetta».** La realtà è il NAS. Non era falsa quando fu scritta il
   01/08: è **superata**, e si marca, non si riscrive. **È il primo della coda perché è l'unico
   debito che, letto oggi, manda qualcuno a cercare la copia di sicurezza nel posto sbagliato.**
   ⚠️ *Che la riga stia in Sez.2 (storia immutabile) il referee NON l'ha verificato alla fonte.*
2. **`LIBRO:316`** — la regola dice che «exists on disk, but not in \<sha\>» significa *case
   sbagliato nel path*. **Osservato tre volte in tre giorni, tre cause diverse, zero volte il case:**
   un rename, un file spostato, un file non tracciato. E la riga contiene **due criteri che si
   contraddicono fra loro** sullo stesso caso. Dà una diagnosi falsa ogni volta che scatta.
3. **`tools/` dentro git.** Cartella **intera** fuori da git (verificato in tre forme sotto A29),
   incluso `lint_canonici.py` — 12 KB, quattro famiglie di controlli validati, e il suo `C1 pipe`
   ha impedito a un canonico di rompersi il 04/08.
4. **Backfill della voce di registro v48** — il registro salta da 47 a 49. Il buco è **annotato
   dentro la voce 49**, dove chi legge inciampa. Atomo doc a sé.
5. **Ricollocazione del ticket da §1.2** — un 🔴 BLOCCANTE PALCO dentro la sezione «Non bloccanti
   palco». Marcato nel campo Stato con un avviso esplicito; la ricollocazione è un atomo a sé.
6. **Righe 45 e 46 del registro BUGS** — 13 e 11 pipe invece di 5, tabella sfasata. **Divergenza
   aperta e registrata, non risolta**: vedi §4.9.
7. **Costituzione V6.** Vedi §6.

### Proposta del referee per ridurre il costo del metodo

I punti **1, 2 e 4 stanno tutti dentro il LIBRO**. Un atomo solo, un prompt solo, una ratifica sola
— poi commit distinti perché monoscopo. Il lavoro di misura è lo stesso file letto una volta.
**Il cancello si attraversa una volta invece di tre, senza togliere niente al rigore.**
Regola candidata: *gli interventi doc sullo stesso canonico si raggruppano in un atomo.*

### Fronti tecnici invariati

⟦S5⟧ (riconciliazione `LiveSession` ↔ `QLiveSession` — **architettura, non cablaggio**) · ⟦S-EXIT⟧ ·
⟦S4L⟧ sospeso · ⟦S6⟧ ⚠️ **la cui scheda è in contraddizione con la decisione del 02/08**: cabla il
MetroFAB verso una destinazione che Mauro ha escluso. Segnalato, mai risolto.

---

## §4 · MECCANISMI STABILITI — non sono suggerimenti

1. **Orologio verificato PRIMA di scrivere un ID.** Il referee ha scritto `2026-08-03` in un ID
   emesso il 04, avendo uno strumento che legge l'ora e non avendolo mai usato in nove turni.
2. **Un artefatto in attesa di ratifica non si sovrascrive MAI.** Versione nuova = tag nuovo e nome
   nuovo, accanto alla vecchia. *(Nata da un rilievo di CC: con Drive sincronizzato live, un `write`
   su C: cambia sotto il referee il file che sta ratificando.)*
3. **La ratifica è sui BYTE, non sulla sostanza.** Le uniche differenze ammesse fra il ratificato e
   il committato sono i campi d'orologio, e vanno **DIMOSTRATE dopo il commit**, non asserite.
   Il confronto va fatto **fra facce omogenee** (LF contro LF), o rende ogni riga divergente per un
   motivo falso.
4. **Campi data: due domande, due regole.** «Quando è stato scritto questo file» → orologio del
   commit. «Quando è successo questo» → **data d'EVENTO, congelata**. Applicare una regola sola a
   entrambi fabbrica una data falsa.
5. **Un'ancora regge se il commit e il numero di riga vengono dalla stessa lettura.** Blame ti dà il
   commit da una fonte e tu ci accoppi un numero di riga preso dal file di oggi: **il
   disaccoppiamento è per costruzione**. Un'ancora di blame può essere sana, se anche la riga è
   letta a quel commit.
6. **Nessun puntino dentro un verbatim.** Un'elisione su `LIBRO:155` mangiò la parola «Bottone» e
   ribaltò una conclusione per due giorni.
7. **«Completo per enumerazione, parziale per verifica».** L'inferenza non è il difetto: **il
   difetto è l'inferenza vestita da misura.** Dichiararla la rende una misura scoperta.
8. **Guardrail proporzionato al modello.** Con un modello più leggero: «a ogni bivio non scritto,
   fermati e chiedi». Ha funzionato **tre volte su tre**, e ogni volta il bivio era reale.
9. **«Si marca, non si corregge» protegge il SIGNIFICATO, non la TIPOGRAFIA.** Criterio: se la
   modifica cambia ciò che la riga sostiene → riscrittura, si marca. Se cambia solo come viene resa
   → riparazione, si fa. *(Posizione del referee; divergenza con CC registrata, non ratificata.)*

---

## §5 · TRAPPOLE DI MISURA — costate care, tutte verificate

| strumento | bugia | verità |
|---|---|---|
| `grep -c $'\r'` | conta le righe con la lettera **r** | `tr -cd '\r' \| wc -c` |
| `sed` | **strippa i CR in uscita**, e ne ha scritto uno in ingresso | mai in una catena sui fine-riga |
| pattern `@` + 40 hex | rende **5** ancore in BUGS | pattern largo ne rende **17** |
| sha256 troncato a 40 hex | **indistinguibile da uno SHA-1 git** | due casi reali trovati in BUGS |
| pagina di ricerca troncata | «il file non c'è» | ricerca mirata: c'era |

⚠️ **Sul `grep`: la regola esisteva già.** `tr -cd` obbligatorio, `grep -c $'\r'` **censito come
falso negativo documentato n°1** settimane fa. Non è mancata la regola: **è mancato il suo arrivo
nel punto d'uso.** Controprova, sullo stesso file: `tr -cd '\r'` → **0**, `grep -c $'\r'` → **1039**,
`wc -l` → **1039**. Il valore falso coincide col numero di righe: **rende «tutte le righe hanno un
CR» esattamente quando i CR sono zero.**

**Perimetro delle due facce — misurato, più stretto di quanto assunto:** riguarda **solo BUGS e
LIBRO**. BOX3, BOX5 e tutto `HANDOFF/**` stanno sotto `-text`, una faccia sola. **La SCALETTA NON è
interessata.** Chi generalizzasse «i canonici hanno due facce» sbaglierebbe perimetro in eccesso.

⚠️ **Finché la notazione delle ancore non è normalizzata** (in uso: `@ sha`, `` @ `sha` ``, `: sha`)
**nessun controllo automatico può essere completo per costruzione.** Prima la notazione, poi il
linter — che esiste già e questo buco ce l'ha adesso.

---

## §6 · ERRORI DEL REFEREE — dieci, e la stessa forma dieci volte

1. **ID `A23` riusato** — era già speso dall'handoff di cambio chat. Non ho letto il registro ID.
2. **Mandato C4 troppo stretto** — ha lasciato in piedi una tesi falsa **accanto a un'ancora appena
   corretta a HEAD**, cioè più credibile di prima. Ho peggiorato ciò che stavo riparando.
3. **Ancora `899be2ce` dichiarata «corretta»** senza che nessuno l'avesse aperta. *(Poi si è
   rivelata sana — conclusione giusta per il metodo sbagliato, che resta un errore.)*
4. **Stavo per dichiarare un file assente** da una pagina di ricerca troncata.
5. **Data `2026-08-03` in un ID emesso il 04**, mai guardato l'orologio.
6. **Buco del registro LIBRO annunciato come «mai segnalato da nessuno»** — era tracciato **e
   chiuso dal 01/08**, in un file che avevo nel Progetto e su cui avevo fatto girare un regex senza
   mai leggerne il testo.
7. **Modello di titolo indicato in `TD-qlive-exit-unconfirmed-stop`** — che la severità nel titolo
   **non ce l'ha**. E la «convenzione» su cui avevo costruito l'argomento non l'avevo mai misurata:
   **34 con, 30 senza**. Se CC avesse obbedito, il ticket sarebbe entrato senza severità.
8. **«C:, E: e Drive condividono lo stesso destino»** — falso: C: ed E: sono **dischi fisici
   distinti**. Ho descritto il rischio più grande di quello che è, e ne è uscita una regola di
   backup troppo stretta. **Corretta da Mauro.**
9. **«Il congedo è un file, scaricalo»** — nessun file esisteva. Annunciato un mio atto senza
   compierlo.
10. **NAS preso per la quarta destinazione** senza accorgermi che Mauro aveva nominato **anche** la
    chiavetta, e che il canonico dice chiavetta. Stavo per far incidere una riga in conflitto con
    un'altra a nove righe di distanza.

**La forma è una sola: affermare dalla memoria invece che dalla fonte.**
E **tre volte su dieci la risposta era già scritta in un documento che avevo a portata di mano** —
il ticket chiuso, la regola sul blob a `LIBRO:336`, la regola sul `grep`.

⚠️ **Il problema non è che le regole manchino. È che non arrivano al punto d'uso.** L'ancora di
blame fu corretta in A8 e ricomparve in A19, undici prompt dopo. Il `grep` era censito e si è
ripresentato. **Una regola che vive solo in un documento protegge solo chi lo sta rileggendo in
quel momento.**

⚠️ **CC ha fermato il referee cinque volte, e cinque volte aveva ragione.** Due prompt già eseguiti,
un'ancora falsificata, un ID già speso, un modello di titolo inesistente. **Quel meccanismo vale più
di chi occupa questa casella.**

---

## §7 · AL REFEREE NUOVO — sei righe

1. **Apri con R1.** Misura tu le impronte dei cinque canonici. ⚠️ Le copie nel Progetto erano
   **indietro di una generazione** per tutta questa sessione: **verificalo per primo.** Il quinto
   canonico si chiama `HANDOFF/SCALETTA_ATOMI_S6_2026-07-10.md`, **non** `SCALETTA_QBEATS.md`.
2. **Prima di dire che qualcosa non esiste o non è mai stato fatto, cercalo.** Sei errori su dieci
   sarebbero stati evitati da una ricerca invece di un'inferenza. **E cerca dentro i file che hai
   già**, non solo fuori: tre volte la risposta era lì.
3. **Verifica l'orologio prima di ogni ID.** `date -u`. Costa un secondo.
4. **L'aggancio non ha presa attraverso un cambio chat.** Non scrivere «il tuo ultimo referto è X»
   a una chat nuova: rovescialo in «dichiara tu cosa hai prodotto, e fermati se hai già eseguito
   QUESTO ID».
5. **Ratifica solo sui byte, mai su un riepilogo** — nemmeno su uno dettagliato e credibile.
   Se non puoi leggere, **dillo e non ratificare**.
6. **Il costo del metodo è il problema aperto.** Una giornata intera per tre modifiche a due
   documenti non è un ritmo con cui si arriva in fondo a un'app. Il rigore ha trovato cose che
   nessuno avrebbe trovato costruendo — ma va reso più economico, e la prima proposta concreta è
   in §3.

---

## §8 · LA COSA DA FARE PER PRIMA, se se ne fa una sola

**Costituzione V5 → V6, con una sezione sui prompt.**

Misurato: la V5 (5 812 byte, 7 sezioni) **non contiene nulla** sul formato dei prompt — zero
occorrenze di `MODELLO`, `COSA FA`, `COSA TORNA`, `AGGANCIO`, `IDEMPOTENZA`, con controllo positivo
e negativo. Eppure quella regola **esiste**: Mauro l'ha dettata il 01/08. Vive solo nella memoria di
chat — un posto che Mauro non può leggere né correggere, senza versione e senza traccia.

**È lo stesso guasto di §6, applicato al meccanismo che dovrebbe prevenirlo.**

La costituzione è già allegata a ogni chat: **se la regola sta lì, non si ripete mai più.**
Da mettere in V6: intestazione a quattro campi · riga di aggancio (con la variante cambio-chat) ·
dichiarazione di idempotenza · verifica dell'orologio · autosufficienza del prompt e prompt di tutti
gli scenari in anticipo · tabella di instradamento modelli **rifatta a fonte** (quella in uso nomina
«Opus 4.8», che non esiste più) · un prompt pubblicato è vivo · e i meccanismi di §4.

⚠️ **Da misurare prima di scrivere: la costituzione è dentro git?** Se non lo è, ha la stessa
fragilità di `tools/` — **il documento che governa il progetto vivrebbe fuori dal sistema che
protegge tutto il resto.**

---

## §9 · BACKUP — stato al 04/08

| destinazione | natura | copertura |
|---|---|---|
| C: | disco vivo | tutto |
| E: | disco distinto, stessa macchina | canonici, diff, referti, archivi storici |
| Google Drive | ⚠️ **sync live di C: ed E:** — replica le cancellazioni | non è un backup |
| GitHub | fuori sede, automatico | **solo il tracciato** |
| **NAS Synology** | ⚠️ **copia manuale, nessun sync — l'unico backup vero** | fotografia **04/08 ~15:35** |

**La fotografia delle 15:35 copre tutto ciò che questa sessione ha prodotto** — diff A33 (~14:20),
tre commit (15:11-15:15), depositi A35 (dopo le 15:20).

⚠️ **Il rovescio della copia manuale: non si cancella a distanza, ma INVECCHIA.** Cadenza
settimanale, ratificata.

⚠️ **Se un giorno si automatizza: copia ADDITIVA, mai `/MIR`, mai sincronizzazione.** Uno strumento
che «rende la destinazione identica alla sorgente» cancella sul NAS ciò che manca sul PC — e il NAS
diventerebbe **il quarto specchio**, rifacendo l'errore di Drive con hardware migliore.

**Proposta per ridurre il carico manuale:** portare `tools/` in git, e **tracciare i file di
`HANDOFF/` che i canonici citano per nome** — sono prove portanti, non cronaca. Precedente in casa,
mai discusso: `MISURE_CC_2026-07-30_R1-ACCERTAMENTI.txt` **è già tracciato**, unico fra 147.

---

**FINE CONGEDO.**
