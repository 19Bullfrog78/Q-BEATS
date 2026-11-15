// === A432 (09/11/2026) — USCITA AUDIO, PASSO 2a, PEZZO 3c-1: IL BATTITO IN ATTESA DETTO DAL DSP (P26, P36) ===
// Il banco dei dieci casi del referto A431, par. 2.1 (la strada (a): l'indice _pendingBeatIdx e i due getter
// getPendingBeat / getPendingSamplesAhead), col caso 4 esteso come chiede VERIFICA_REFEREE_A431, par. 3.1 (P36):
// dopo un battito messo a «subito» le chiamate che seguono senza correzione, anche fuori griglia.
//
// Gli oracoli non usano mai il getter:
// - il CAMPIONE del click e' l'offset dell'evento che processBuffer rende, nel buffer in cui esce;
// - l'IDENTITA' del click e' quella della band: col Follower in sync l'origine del DSP e quella della band
//   coincidono (0) e le correzioni tengono il cursore del DSP sulla posizione della band, quindi il battito
//   intero piu' vicino al campione del click (llround(campione / spb)) e' il suo nome vero; dove non ci sono
//   correzioni (casi 6, 7, 8) l'identita' e' il numero dei click usciti dall'origine;
// - l'ETICHETTA e' _currentBeatInBar letta prima del processBuffer che fa uscire il click (al piu' un battito
//   per buffer: spb > bufferSize a ogni tempo di qui).
// Il modello del Follower in sync e' quello di A424 par. 2.2 a e del verificatore VR-3c: la band avanza di un
// buffer per chiamata; la lettura di Link porta la sua posizione con uno scarto alternato di ±0,006 battiti;
// la correzione (setBeatPositionTimeOnly) gira quando lo scarto dalla posizione del DSP supera 0,01, la
// soglia di link_engine_sync_phase; un buco fa saltare la band di G battiti alla chiamata gapBuffer. Il
// cursore del DSP (_absoluteSamplePosition) si segue con la formula di setBeatPositionTimeOnly,
// round(beatPosition * spb). La regola Swift di oggi (LateBeatDecision, origine 0) e' il controllo negativo.
// I banchi di core_engine segnalano gli errori solo con assert(): con NDEBUG definito questo file non si compila.
#ifdef NDEBUG
#error "test_pending_beat: NDEBUG definito, gli assert() sarebbero spenti - compilare in Debug (-DCMAKE_BUILD_TYPE=Debug)"
#endif

#include "MetronomeDSP.h"

#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>   // std::llabs: fuori dal blocco per MSVC, cosi' il banco compila con ogni compilatore
#include <cstring>
#include <memory>
#include <new>
#include <vector>

// Solo per una compilazione locale su Windows con la CRT di debug di MSVC: un assert() fallito andrebbe in una
// finestra modale e il banco resterebbe appeso; qui va su stderr e il processo esce, come su macOS. Nessun effetto
// sul runner della CI.
#if defined(_MSC_VER) && defined(_DEBUG)
#include <crtdbg.h>
static void assertSuStderr() {
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
}
#else
static void assertSuStderr() {}
#endif

namespace {

const double   kRate = 48000.0;
const uint32_t kBuf  = 512;

struct Pending { double beat; int64_t ahead; };

Pending readPending(const MetronomeDSP& d) { return { d.getPendingBeat(), d.getPendingSamplesAhead() }; }

long long ll(double x) { return std::llround(x); }
double    spbOf(double bpm) { return kRate * 60.0 / bpm; }
// Il cursore dopo setBeatPositionTimeOnly / setBeatPosition / resetForStart: round(beat * spb).
uint64_t  cursorOf(double beat, double spb) { return (uint64_t)std::round(beat * spb); }
// LateBeatDecision.pendingBeat(origin: 0, beat:): il primo battito della griglia non prima della posizione.
double    swiftCeil(double pos) { return std::ceil(pos - 1e-9); }

// Avanza il DSP a buffer da kBuf, senza correzioni, finche' il cursore non raggiunge targetBeat (origine 0).
// Rende il numero dei battiti usciti nel tratto.
int advanceUntil(MetronomeDSP& dsp, uint64_t& cursor, double spb, double targetBeat) {
    int n = 0;
    while ((double)cursor / spb < targetBeat) {
        for (const auto& e : dsp.processBuffer(kBuf)) if (e.isBeat) ++n;
        cursor += kBuf;
    }
    return n;
}

// Avanza finche' non esce un battito; rende il campione assoluto del click, l'offset e il getter letto prima
// del buffer in cui e' uscito (per i casi senza correzioni).
struct Click { uint64_t sample; uint32_t offset; Pending before; uint32_t label; bool accent; };
Click nextClick(MetronomeDSP& dsp, uint64_t& cursor, int maxBuffers = 100000) {
    for (int b = 0; b < maxBuffers; ++b) {
        const Pending g = readPending(dsp);
        const uint32_t label = dsp.getCurrentBeatInBar();
        const auto evs = dsp.processBuffer(kBuf);
        for (const auto& e : evs) {
            if (!e.isBeat) continue;
            Click c = { cursor + e.offset, e.offset, g, label, e.accent };
            cursor += kBuf;
            return c;
        }
        // nessun battito in questo buffer: il getter deve dirlo
        assert(g.ahead >= (int64_t)kBuf);
        cursor += kBuf;
    }
    assert(false && "nessun battito");
    return Click();
}

// ─────────────────────────── casi 1, 2, 3: il Follower in sync coi buchi ───────────────────────────

// Come si rinomina nel modello: mai («oggi»); col getter a ogni chiamata dal buco in poi; con la regola Swift a
// ogni chiamata dal buco in poi; una volta sola nella chiamata del buco (col getter) e una seconda volta due
// chiamate dopo con la regola Swift (la «prova3» di VR-3c: la seconda lettura nella finestra).
enum class Rename { none, getterEvery, swiftEvery, swiftOnceAfter };

struct SyncResult {
    int beats = 0, corrections = 0, atSampleZero = 0;
    int asapAfterOvertake = 0;    // record che annunciavano un campione, poi scavalcato da una correzione: uscito a «subito»
    // A432 parte 2a (VERIFICA_REFEREE_A432_PARTE1 par. 3.1, A.4) — il controllo stretto degli scavalchi: ogni
    // scavalco contato qui sopra dev'essere uno scavalco vero (vedi runSync), e chi passa solo il controllo
    // largo fa cadere il test.
    int overtakeStrict = 0;       // scavalchi veri: correzione nella chiamata d'uscita, cursore oltre l'annuncio, campione mai suonato
    int overtakeLaxOnly = 0;      // usciti al campione 0 piu' tardi dell'annuncio SENZA uno scavalco vero: devono essere zero
    int annNotGrid = 0;           // scavalcati il cui campione annunciato non era quello di griglia del battito: devono essere zero
    int getterWrong = 0;          // identita' del getter diversa dal click uscito, o campione diverso senza scavalco
    int swiftWrongGapCall = 0;    // la regola Swift (pendingBeatAfter) nella chiamata del buco
    int swiftWrongOther = 0;      // la regola Swift (ceil della posizione) nelle chiamate dopo il buco
    int labelWrongPerCall = 0;    // chiamate in cui l'etichetta del DSP non e' (battito in attesa vero mod bpb)
    int labelWrongEmitted = 0;    // click usciti con l'etichetta sbagliata (quello che si sente)
    int doubles = 0;              // due click con lo stesso nome
};

SyncResult runSync(double bpm, uint32_t bpb, double gapBeats, int gapBuffer, int totalBuffers, Rename rename) {
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, bpm);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setBeatsPerBar(bpb);
    dsp.resetForStart(0.0);
    const double spb = spbOf(bpm);
    assert(spb > (double)kBuf);
    uint64_t cursor = 0;
    SyncResult r;
    // Ogni chiamata lascia un record finche' non esce il click che quel record annunciava. Nel modello solo la
    // correzione del buco cambia l'identita' del battito in attesa (le altre sono sotto mezzo battito e lo
    // lasciano sulla griglia): i record di prima del buco annunciano un battito che il buco fa sparire, e si
    // scartano li'; ogni altro record deve dire il click che esce: nome e campione.
    struct Rec { double swiftP; double gBeat; int64_t gAhead; uint64_t cursor; uint32_t label; bool gapCall; bool corrected; };
    std::vector<Rec> pend;
    long long lastIdentity = -1;
    int sign = +1;
    for (int n = 0; n < totalBuffers; ++n) {
        const double bandBeat = (double)n * kBuf / spb + (n >= gapBuffer ? gapBeats : 0.0);
        const double reading  = bandBeat + sign * 0.006;
        sign = -sign;
        const double before = (double)cursor / spb;
        double swiftP;
        bool corrected = false;   // in questa chiamata c'e' stata una correzione
        if (std::fabs(reading - before) > 0.01) {
            corrected = true;
            dsp.setBeatPositionTimeOnly(reading);
            cursor = cursorOf(reading, spb);
            swiftP = swiftCeil(before) + std::round(reading - before);   // LateBeatDecision.pendingBeatAfter
            ++r.corrections;
        } else {
            swiftP = swiftCeil(before);                                    // LateBeatDecision.pendingBeat
        }
        if (n == gapBuffer) pend.clear();
        const Pending g = readPending(dsp);
        if (g.ahead == 0) ++r.atSampleZero;
        if (n >= gapBuffer) {
            switch (rename) {
            case Rename::none: break;
            case Rename::getterEvery: dsp.renamePendingBeat((uint32_t)(ll(g.beat) % (long long)bpb)); break;
            case Rename::swiftEvery:  dsp.renamePendingBeat((uint32_t)(ll(swiftP) % (long long)bpb)); break;
            case Rename::swiftOnceAfter:
                if (n == gapBuffer)     dsp.renamePendingBeat((uint32_t)(ll(g.beat) % (long long)bpb));
                if (n == gapBuffer + 2) dsp.renamePendingBeat((uint32_t)(ll(swiftP) % (long long)bpb));
                break;
            }
        }
        const uint32_t labelBefore = dsp.getCurrentBeatInBar();
        pend.push_back({ swiftP, g.beat, g.ahead, cursor, labelBefore, n == gapBuffer, corrected });
        const auto evs = dsp.processBuffer(kBuf);
        bool none = true;
        for (const auto& e : evs) {
            if (!e.isBeat) continue;
            assert(none);   // al piu' un battito per buffer
            none = false;
            ++r.beats;
            const uint64_t  s = cursor + e.offset;
            const long long k = ll((double)s / spb);   // la band: il battito intero piu' vicino al click
            if (k == lastIdentity) ++r.doubles;
            lastIdentity = k;
            for (size_t pi = 0; pi < pend.size(); ++pi) {
                const Rec& p = pend[pi];
                if (ll(p.gBeat) != k) ++r.getterWrong;
                // Il campione: uguale a quello annunciato, salvo il fire-asap di FIX-B: se la correzione di una
                // chiamata dopo scavalca il battito in attesa di pochi campioni (lo scarto della lettura), il
                // DSP lo fa uscire al primo campione di quel buffer, piu' tardi di quanto annunciato. Nella
                // chiamata d'uscita il getter e' comunque esatto (l'ultimo record).
                const int64_t announced = (int64_t)p.cursor + p.gAhead;
                if (announced != (int64_t)s) {
                    if (e.offset == 0 && (int64_t)s > announced) {
                        ++r.asapAfterOvertake;
                        // Il controllo stretto (A.4): e' uno scavalco vero solo se la chiamata d'uscita ha avuto
                        // una correzione, se il suo cursore sta oltre il campione annunciato, e se quel campione
                        // non e' mai caduto in un buffer suonato fra l'annuncio e l'uscita (la linea a campioni lo
                        // ha saltato). Un click uscito al campione 0 piu' tardi dell'annuncio per un altro motivo
                        // (un annuncio troppo presto, un battito rinviato) passa solo il controllo largo.
                        const Rec& ult = pend.back();
                        bool maiSuonato = true;
                        for (size_t q = pi; q + 1 < pend.size(); ++q)
                            if ((int64_t)pend[q].cursor <= announced && announced < (int64_t)pend[q].cursor + (int64_t)kBuf)
                                maiSuonato = false;
                        if (ult.corrected && (int64_t)ult.cursor > announced && maiSuonato) ++r.overtakeStrict;
                        else ++r.overtakeLaxOnly;
                        if (announced != (int64_t)std::llround((double)k * spb)) ++r.annNotGrid;
                    }
                    else ++r.getterWrong;
                }
                if (ll(p.swiftP) != k) { if (p.gapCall) ++r.swiftWrongGapCall; else ++r.swiftWrongOther; }
                if ((uint32_t)(k % (long long)bpb) != p.label) ++r.labelWrongPerCall;
            }
            if (!pend.empty()) {
                const Rec& last = pend.back();   // la chiamata d'uscita: nome e campione esatti
                if (ll(last.gBeat) != k || (int64_t)last.cursor + last.gAhead != (int64_t)s) ++r.getterWrong;
            }
            pend.clear();
            if ((uint32_t)(k % (long long)bpb) != labelBefore) ++r.labelWrongEmitted;
        }
        if (none && g.ahead < (int64_t)kBuf) ++r.getterWrong;   // annunciato in questo buffer e non uscito
        cursor += kBuf;
    }
    return r;
}

struct Scenario { const char* nome; double bpm; uint32_t bpb; double gap; bool saltaUnBattito; };

void test_casi_1_2_3_getter_vero_e_d_accordo_con_la_regola_swift_senza_salto() {
    // Il caso 1 (121 con 1,61; 141 con 1,86; 180,5 in 9/8 con 1,61: FIX-B salta un battito e la regola Swift
    // sbaglia nelle chiamate dopo il buco), il caso 2 (nella chiamata del buco nessun errore, neanche oggi) e
    // il caso 3 (91 con 1,19, 101 in 6/8 con 1,30, i salti interi 1, 2, 3: nessun battito saltato).
    // Che cosa prova il caso 3 (VERIFICA_REFEREE_A432_PARTE1 par. 3.1, A.11): dove il buco non fa saltare un
    // battito, il getter e la regola Swift di oggi (LateBeatDecision: pendingBeat nelle chiamate senza
    // correzione, pendingBeatAfter in quelle con una correzione) dicono lo stesso battito dopo OGNI correzione,
    // ed e' quello che esce. NON prova «identita' = ceil(posizione)»: nelle chiamate con una correzione il ceil
    // della posizione nuova non e' il click che esce (la frase di A431 par. 2.1, caso 3, era imprecisa).
    const Scenario scen[] = {
        { "121 4/4 1,61", 121.0, 4, 1.61, true  },
        { "141 4/4 1,86", 141.0, 4, 1.86, true  },
        { "180,5 9/8 1,61", 180.5, 9, 1.61, true },
        { "91 4/4 1,19",  91.0,  4, 1.19, false },
        { "101 6/8 1,30", 101.0, 6, 1.30, false },
        { "121 4/4 1,00", 121.0, 4, 1.00, false },
        { "121 4/4 2,00", 121.0, 4, 2.00, false },
        { "121 4/4 3,00", 121.0, 4, 3.00, false },
    };
    const int fasi = 61;   // il buco ai buffer 200..260, come VR-3c
    const Rename modes[4] = { Rename::none, Rename::getterEvery, Rename::swiftEvery, Rename::swiftOnceAfter };
    for (const Scenario& s : scen) {
        SyncResult tot[4];
        for (int m = 0; m < 4; ++m) {
            for (int f = 0; f < fasi; ++f) {
                const SyncResult r = runSync(s.bpm, s.bpb, s.gap, 200 + f, 400, modes[m]);
                tot[m].beats += r.beats; tot[m].corrections += r.corrections; tot[m].atSampleZero += r.atSampleZero;
                tot[m].asapAfterOvertake += r.asapAfterOvertake;
                tot[m].overtakeStrict += r.overtakeStrict; tot[m].overtakeLaxOnly += r.overtakeLaxOnly;
                tot[m].annNotGrid += r.annNotGrid;
                tot[m].getterWrong += r.getterWrong; tot[m].swiftWrongGapCall += r.swiftWrongGapCall;
                tot[m].swiftWrongOther += r.swiftWrongOther; tot[m].labelWrongPerCall += r.labelWrongPerCall;
                tot[m].labelWrongEmitted += r.labelWrongEmitted; tot[m].doubles += r.doubles;
            }
        }
        std::printf("  %-16s fasi:%d battiti:%d correzioni:%d alCampione0:%d scavalcati:%d getterSbagliato:%d swiftNelBuco:%d"
                    " swiftDopo:%d etichettePerChiamata[oggi:%d getter:%d swift:%d] etichetteUscite[oggi:%d getter:%d"
                    " swift:%d secondaSwift:%d] doppi:%d\n",
                    s.nome, fasi, tot[0].beats, tot[0].corrections, tot[0].atSampleZero, tot[0].asapAfterOvertake,
                    tot[0].getterWrong, tot[0].swiftWrongGapCall, tot[0].swiftWrongOther, tot[0].labelWrongPerCall,
                    tot[1].labelWrongPerCall, tot[2].labelWrongPerCall, tot[0].labelWrongEmitted,
                    tot[1].labelWrongEmitted, tot[2].labelWrongEmitted, tot[3].labelWrongEmitted,
                    tot[0].doubles + tot[1].doubles + tot[2].doubles + tot[3].doubles);
        std::printf("  %-16s scavalchi[oggi]: stretti:%d soloLarghi:%d annuncioNonDiGriglia:%d | tuttiIModi: stretti:%d"
                    " soloLarghi:%d annuncioNonDiGriglia:%d\n",
                    s.nome, tot[0].overtakeStrict, tot[0].overtakeLaxOnly, tot[0].annNotGrid,
                    tot[0].overtakeStrict + tot[1].overtakeStrict + tot[2].overtakeStrict + tot[3].overtakeStrict,
                    tot[0].overtakeLaxOnly + tot[1].overtakeLaxOnly + tot[2].overtakeLaxOnly + tot[3].overtakeLaxOnly,
                    tot[0].annNotGrid + tot[1].annNotGrid + tot[2].annNotGrid + tot[3].annNotGrid);
        for (int m = 0; m < 4; ++m) {
            assert(tot[m].getterWrong == 0);         // il getter dice il battito che esce: nome e campione, in ogni chiamata
            // A.4 — ogni click uscito piu' tardi dell'annuncio e' uno scavalco vero, e l'annuncio scavalcato era il
            // campione di griglia di quel battito: «allo stesso campione» (mandato, par. 2.1) salvo lo scavalco.
            assert(tot[m].overtakeLaxOnly == 0);
            assert(tot[m].overtakeStrict == tot[m].asapAfterOvertake);
            assert(tot[m].annNotGrid == 0);
            assert(tot[m].swiftWrongGapCall == 0);   // caso 2: nella chiamata del buco la regola Swift e' giusta anche oggi
            assert(tot[m].doubles == 0);
            assert(tot[m].beats > 0);
        }
        assert(tot[0].labelWrongEmitted > 0);    // oggi (nessuna rinomina) i click dopo il buco escono col nome sbagliato
        assert(tot[1].labelWrongPerCall == 0);   // la rinomina col getter: etichetta giusta in ogni chiamata...
        assert(tot[1].labelWrongEmitted == 0);   // ... e su ogni click uscito
        if (s.saltaUnBattito) {
            // caso 1, controllo negativo: la regola Swift di oggi sbaglia nelle chiamate dopo il buco (finche' la
            // posizione non passa il battito saltato), una rinomina fatta con quella regola sbaglia l'etichetta in
            // quelle chiamate, e una seconda rinomina sola nella finestra fa uscire click col nome sbagliato
            assert(tot[0].swiftWrongOther > 0);
            assert(tot[2].labelWrongPerCall > 0);
            assert(tot[3].labelWrongEmitted > 0);
        } else {
            // caso 3: senza salto di battito la regola Swift di oggi dice il click che esce in ogni chiamata, come
            // il getter (zero errori dopo ogni correzione); una rinomina fatta con quella regola da' le etichette giuste
            assert(tot[0].swiftWrongOther == 0);
            assert(tot[2].labelWrongPerCall == 0);
            assert(tot[2].labelWrongEmitted == 0);
            assert(tot[3].labelWrongEmitted == 0);
        }
    }
    std::printf("PASS test_casi_1_2_3_getter_vero_e_d_accordo_con_la_regola_swift_senza_salto\n");
}

// ─────────────────────────── caso 4: il battito messo a «subito», poi fuori griglia ───────────────────────────

void test_caso_4_subito_e_le_chiamate_dopo_senza_correzione() {
    // Una correzione in avanti che scavalca il battito in attesa con distanza sotto 0,5: samplesAhead == 0,
    // identita' = il battito scavalcato, e il primo evento del buffer e' quel battito, al campione 0. Poi
    // (VERIFICA_REFEREE_A431 par. 3.1, P36) le chiamate che seguono senza correzione: il battito dopo sta a
    // (campione del «subito» + spb), FUORI griglia del ritardo dello scavalco, finche' una correzione non lo
    // riporta: comportamento atteso del DSP di oggi (FIX-B), scritto qui perche' un suo cambio faccia cadere il
    // test (la cura, se servira', e' di J.8). Il getter deve dire il vero anche li'.
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.resetForStart(0.0);
    const double spb = spbOf(121.0);
    uint64_t cursor = 0;
    const int usciti = advanceUntil(dsp, cursor, spb, 3.5);   // 0, 1, 2, 3 usciti; in attesa il 4
    assert(usciti == 4);
    Pending g = readPending(dsp);
    assert(ll(g.beat) == 4);
    assert((int64_t)cursor + g.ahead == ll(4.0 * spb));
    // una correzione piccola a 3,7 (|salto| < 0,5: l'identita' resta 4; la distanza al 4 diventa 0,3)
    const double before = (double)cursor / spb;
    assert(std::fabs(3.7 - before) < 0.5);
    dsp.setBeatPositionTimeOnly(3.7);
    cursor = cursorOf(3.7, spb);
    g = readPending(dsp);
    assert(ll(g.beat) == 4);
    assert((int64_t)cursor + g.ahead == ll(4.0 * spb));
    // la correzione in avanti di 0,45 scavalca il 4 (distanza 0,3 < 0,5): pendingRelIdx = round(4,15 + 0,3) = 4,
    // e il suo campione e' nel passato del cursore: «subito»
    dsp.setBeatPositionTimeOnly(4.15);
    cursor = cursorOf(4.15, spb);
    g = readPending(dsp);
    assert(g.ahead == 0);
    assert(ll(g.beat) == 4);
    const uint32_t label4 = dsp.getCurrentBeatInBar();
    assert(label4 == 0);   // 4 % 4: l'etichetta del DSP e' ancora giusta (nessun battito saltato)
    {
        const auto evs = dsp.processBuffer(kBuf);
        assert(!evs.empty() && evs[0].isBeat && evs[0].offset == 0);
        for (size_t i = 1; i < evs.size(); ++i) assert(!evs[i].isBeat);
    }
    const uint64_t subitoSample = cursor;                    // il 4 e' uscito qui, 0,15 battiti dopo la griglia
    assert(subitoSample != (uint64_t)ll(4.0 * spb));
    assert(std::fabs(((double)subitoSample - 4.0 * spb) / spb - 0.15) < 0.001);
    cursor += kBuf;
    // le chiamate dopo, senza correzione: il 5 e il 6 fuori griglia, a subitoSample + spb e + 2 spb
    double exactNext = (double)subitoSample + spb;           // _exactNextBeatSample dopo il «subito» e += spb
    for (long long id = 5; id <= 6; ++id) {
        const uint64_t expected = (uint64_t)ll(exactNext);
        assert(expected != (uint64_t)ll((double)id * spb));   // fuori griglia: il ritardo dello scavalco resta
        bool out = false;
        while (!out) {
            g = readPending(dsp);
            assert(ll(g.beat) == id);                              // identita' vera
            assert((int64_t)cursor + g.ahead == (int64_t)expected); // campione vero, anche fuori griglia
            const auto evs = dsp.processBuffer(kBuf);
            for (const auto& e : evs) {
                if (!e.isBeat) continue;
                assert(cursor + e.offset == expected);
                assert(g.ahead == (int64_t)e.offset);
                out = true;
            }
            if (!out) assert(g.ahead >= (int64_t)kBuf);
            cursor += kBuf;
        }
        exactNext += spb;
    }
    // la prima correzione che tiene l'identita' (|salto| < 0,5) rimette il 7 sulla griglia: 7 * spb
    {
        const double pos = (double)cursor / spb + 0.012;
        dsp.setBeatPositionTimeOnly(pos);
        cursor = cursorOf(pos, spb);
        g = readPending(dsp);
        assert(ll(g.beat) == 7);
        assert((int64_t)cursor + g.ahead == ll(7.0 * spb));
        const Click c = nextClick(dsp, cursor);
        assert(c.sample == (uint64_t)ll(7.0 * spb));
        assert(c.before.ahead == (int64_t)c.offset);
    }
    std::printf("PASS test_caso_4_subito_e_le_chiamate_dopo_senza_correzione\n");
}

// ─────────────────────────── caso 5: il bordo del buffer ───────────────────────────

void test_caso_5_bordo_del_buffer() {
    // Il battito in attesa al campione 0 e al campione 511 di un buffer da 512: samplesAhead 0 e 511, ed esce li'.
    {
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;              // spb = 24000 esatto
        dsp.setAbsolutePositionForTesting(24000 - 511);
        Pending g = readPending(dsp);
        assert(g.ahead == 511 && ll(g.beat) == 1);
        const auto evs = dsp.processBuffer(512);
        assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 511);
        g = readPending(dsp);
        assert(ll(g.beat) == 2);
        assert(g.ahead == (int64_t)(48000 - (24000 - 511 + 512)));
    }
    {
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        dsp.setAbsolutePositionForTesting(24000);
        Pending g = readPending(dsp);
        assert(g.ahead == 0 && ll(g.beat) == 1);
        const auto evs = dsp.processBuffer(512);
        assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 0);
        g = readPending(dsp);
        assert(ll(g.beat) == 2 && g.ahead == 24000 - 512);
    }
    {
        // resetForStart a motore in moto (il Play fresco, il fuoco del rientro con startBeat): il battito in attesa
        // torna a essere l'origine, al campione 0, con l'etichetta 0
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);
        MetronomeDSP& dsp = *dspBox;
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        assert(advanceUntil(dsp, cursor, spbOf(121.0), 2.5) == 3);
        dsp.renamePendingBeat(2);
        dsp.resetForStart(7.0);
        cursor = cursorOf(7.0, spbOf(121.0));
        Pending g = readPending(dsp);
        assert(std::fabs(g.beat - 7.0) < 1e-12 && g.ahead == 0 && dsp.getCurrentBeatInBar() == 0);
        const auto evs = dsp.processBuffer(512);
        assert(!evs.empty() && evs[0].isBeat && evs[0].offset == 0 && evs[0].accent);
        g = readPending(dsp);
        assert(std::fabs(g.beat - 8.0) < 1e-12);
    }
    {
        // con una durata non intera (121: 23801,65 campioni) vale lo stesso arrotondamento di processBuffer
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        const uint64_t beat1 = (uint64_t)std::round(spbOf(121.0));   // 23802
        dsp.setAbsolutePositionForTesting(beat1 - 511);
        Pending g = readPending(dsp);
        assert(g.ahead == 511 && ll(g.beat) == 1);
        const auto evs = dsp.processBuffer(512);
        assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 511);
    }
    std::printf("PASS test_caso_5_bordo_del_buffer\n");
}

// ─────────────────────────── caso 6: lo swing ───────────────────────────

void test_caso_6_swing() {
    // Crome con swing 0,6 a 120: le suddivisioni ai campioni letterali (14400, 38400, 62400, 86400: la seconda
    // croma di ogni battito cade sul battito e la assorbe), i battiti a 0, 24000, 48000, 72000, 96000;
    // l'identita' sale solo coi battiti, e i campioni del getter contano al battito, non alla suddivisione.
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 120.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setSubdivision(2, 0.6);
    dsp.resetForStart(0.0);
    uint64_t cursor = 0;
    std::vector<uint64_t> beatsOut, subdivOut;
    long long lastBeat = 0;
    for (int b = 0; b < 200; ++b) {
        const Pending g = readPending(dsp);
        assert(ll(g.beat) == (long long)beatsOut.size());        // identita' = battiti usciti dall'origine
        assert((int64_t)cursor + g.ahead == (int64_t)(24000 * beatsOut.size()));
        const auto evs = dsp.processBuffer(kBuf);
        for (const auto& e : evs) {
            if (e.isBeat) beatsOut.push_back(cursor + e.offset);
            else          subdivOut.push_back(cursor + e.offset);
        }
        const Pending after = readPending(dsp);
        if (evs.empty() || !evs.front().isBeat) {
            assert(ll(after.beat) == lastBeat);                   // una suddivisione non muove l'identita'
        }
        lastBeat = ll(after.beat);
        cursor += kBuf;
    }
    const uint64_t attesiB[] = { 0, 24000, 48000, 72000, 96000 };
    const uint64_t attesiS[] = { 14400, 38400, 62400, 86400 };
    assert(beatsOut.size() == 5);
    for (size_t i = 0; i < 5; ++i) assert(beatsOut[i] == attesiB[i]);
    assert(subdivOut.size() == 4);
    for (size_t i = 0; i < 4; ++i) assert(subdivOut[i] == attesiS[i]);
    std::printf("PASS test_caso_6_swing\n");
}

// ─────────────────────────── caso 7: un cambio armato ───────────────────────────

void test_caso_7_cambio_armato() {
    // Metro 4 -> 3 e tempo 121 -> 91 armati e scattati al battito con etichetta 0: l'identita' sale di uno per
    // battito attraverso lo scambio; samplesAhead dopo lo scambio e' contato con la durata nuova.
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setBeatsPerBar(4);
    dsp.resetForStart(0.0);
    const double spb121 = spbOf(121.0), spb91 = spbOf(91.0);
    uint64_t cursor = 0;
    assert(advanceUntil(dsp, cursor, spb121, 1.5) == 2);   // 0 e 1 usciti; in attesa il 2 (etichetta 2)
    dsp.scheduleBeatsPerBarChange(3);
    dsp.scheduleBPMChange(91.0);
    const long long ids[]    = { 2, 3, 4, 5, 6, 7 };
    const uint32_t  labels[] = { 2, 3, 0, 1, 2, 0 };       // lo scambio scatta sul 4 (etichetta 0); poi 3/4
    double exact = 2.0 * spb121;                          // _exactNextBeatSample: fino allo scambio in passi di spb121
    for (int i = 0; i < 6; ++i) {
        const Click c = nextClick(dsp, cursor);
        assert(ll(c.before.beat) == ids[i]);
        assert(c.before.ahead == (int64_t)c.offset);
        assert(c.label == labels[i]);
        assert(c.accent == (labels[i] == 0));
        assert(std::llabs((long long)c.sample - ll(exact)) <= 1);
        exact += (ids[i] >= 4) ? spb91 : spb121;          // dal battito dello scambio in poi la durata nuova
        if (ids[i] == 4) {
            // subito dopo il battito dello scambio: il prossimo e' a 4 spb121 + spb91, contato con la durata nuova
            const Pending g = readPending(dsp);
            assert(ll(g.beat) == 5);
            assert(std::llabs(((long long)cursor + g.ahead) - ll(4.0 * spb121 + spb91)) <= 1);
            assert(((long long)cursor + g.ahead) != ll(5.0 * spb121));
        }
    }
    std::printf("PASS test_caso_7_cambio_armato\n");
}

// ─────────────────────────── caso 8: setBPM e setBeatsPerBar fra la lettura e processBuffer ───────────────────────────

void test_caso_8_setter_fra_lettura_e_processBuffer() {
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.setBeatsPerBar(4);
    dsp.resetForStart(0.0);
    const double spb121 = spbOf(121.0);
    uint64_t cursor = 0;
    assert(advanceUntil(dsp, cursor, spb121, 2.5) == 3);   // in attesa il 3
    const Pending g1 = readPending(dsp);
    assert(ll(g1.beat) == 3);
    dsp.setBeatsPerBar(3);                                  // rimette l'etichetta a 0, non tocca il battito in attesa
    const Pending g2 = readPending(dsp);
    assert(g2.beat == g1.beat && g2.ahead == g1.ahead);
    dsp.setBPM(91.0);                                       // riscala la distanza al battito in attesa, tiene l'identita'
    const Pending g3 = readPending(dsp);
    assert(g3.beat == g1.beat);
    assert(g3.ahead != g1.ahead);
    const double exactNew = (double)cursor + (3.0 * spb121 - (double)cursor) * (121.0 / 91.0);
    assert(std::llabs(((long long)cursor + g3.ahead) - ll(exactNew)) <= 1);
    const Click c = nextClick(dsp, cursor);                 // ed esce dove il getter ha detto
    assert(ll(c.before.beat) == 3 && c.before.ahead == (int64_t)c.offset);
    assert(std::llabs((long long)c.sample - ll(exactNew)) <= 1);
    std::printf("PASS test_caso_8_setter_fra_lettura_e_processBuffer\n");
}

// ─────────────────────────── caso 9: A424, Aperto A.10 ───────────────────────────

void test_caso_9_dopo_il_buco_di_1_61_un_battito_non_esce() {
    // Dopo il buco di 1,61 battiti il battito che cadrebbe 0,088 battiti dopo la posizione non esce mai: FIX-B
    // sposta l'identita' del battito in attesa di round(1,61) = 2, e il getter dice gia' il battito dopo.
    // Comportamento atteso del DSP di oggi (la cura, se servira', e' di J.8): un cambio di FIX-B lo fa cadere.
    auto dspBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
    MetronomeDSP& dsp = *dspBox;
    dsp.resetForStart(0.0);
    const double spb = spbOf(121.0);
    uint64_t cursor = 0;
    assert(advanceUntil(dsp, cursor, spb, 4.0) == 5);       // 0..4 usciti; in attesa il 5
    dsp.setBeatPositionTimeOnly(4.302);                     // |salto| < 0,5: il 5 resta in attesa, distanza 0,698
    cursor = cursorOf(4.302, spb);
    Pending g = readPending(dsp);
    assert(ll(g.beat) == 5 && (int64_t)cursor + g.ahead == ll(5.0 * spb));
    dsp.setBeatPositionTimeOnly(4.302 + 1.61);              // il buco: la posizione a 5,912, il 6 a 0,088 davanti
    cursor = cursorOf(5.912, spb);
    g = readPending(dsp);
    assert(ll(g.beat) == 7);                                // il DSP suonera' il 7: il 6 e' saltato
    assert((int64_t)cursor + g.ahead == ll(7.0 * spb));
    // la regola Swift: pendingBeatAfter = ceil(4,302) + round(1,61) = 7 nella chiamata del buco; ceil(5,912) = 6 dopo
    assert(ll(swiftCeil(4.302) + std::round(1.61)) == 7);
    assert(ll(swiftCeil(5.912)) == 6);
    const Click c = nextClick(dsp, cursor);
    assert(c.sample == (uint64_t)ll(7.0 * spb));
    assert(c.sample != (uint64_t)ll(6.0 * spb));
    assert(ll(c.before.beat) == 7 && c.before.ahead == (int64_t)c.offset);
    std::printf("PASS test_caso_9_dopo_il_buco_di_1_61_un_battito_non_esce\n");
}

// ─────────────────────────── caso 10: dspPosition sul DSP vero ───────────────────────────

// ResumeSnapDecision.snappedBeat: dall'origine, la prima battuta intera non prima del battito.
double snappedBeat(double beat, double origin, double bpb) {
    return origin + std::ceil((beat - origin) / bpb) * bpb;
}

void test_caso_10_dspPosition_sul_DSP_vero() {
    // I numeri di ios_app/QBeatsTests/ResumeSnapDecisionTests.swift, letti con getPendingBeat() e
    // getCurrentBeatInBar() dopo setBeatPosition: gli stessi di ResumeSnapDecision.dspPosition.
    {   // il 24/10 con P1: origine 0, 38,5709 a 121 in 4/4 -> 40,0 e l'«uno»
        auto dBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *dBox; d.setBeatsPerBar(4); d.resetForStart(0.0);
        const double snapped = snappedBeat(38.5709, 0.0, 4.0);
        assert(std::fabs(snapped - 40.0) < 1e-9);
        d.setBeatPosition(snapped);
        assert(std::fabs(d.getPendingBeat() - 40.0) < 1e-9 && d.getCurrentBeatInBar() == 0);
    }
    {   // con l'origine del sequencer 0,094321 -> 40,094321, che il DSP mette sul 41: il «due»
        auto dBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *dBox; d.setBeatsPerBar(4); d.resetForStart(0.0);
        const double snapped = snappedBeat(38.5709, 0.094321, 4.0);
        assert(std::fabs(snapped - 40.094321) < 1e-9);
        d.setBeatPosition(snapped);
        assert(std::fabs(d.getPendingBeat() - 41.0) < 1e-9 && d.getCurrentBeatInBar() == 1);
    }
    {   // 3/4 -> 39 («uno»); 6/8 a 101 -> 42 («uno»); con l'origine di prima fuori dall'«uno»
        auto d3Box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d3 = *d3Box; d3.setBeatsPerBar(3); d3.resetForStart(0.0);
        d3.setBeatPosition(snappedBeat(38.5709, 0.0, 3.0));
        assert(std::fabs(d3.getPendingBeat() - 39.0) < 1e-9 && d3.getCurrentBeatInBar() == 0);
        auto d6Box = std::make_unique<MetronomeDSP>(kRate, 101.0);   // sullo heap, come metronome_create
        MetronomeDSP& d6 = *d6Box; d6.setBeatsPerBar(6); d6.resetForStart(0.0);
        d6.setBeatPosition(snappedBeat(38.5709, 0.0, 6.0));
        assert(std::fabs(d6.getPendingBeat() - 42.0) < 1e-9 && d6.getCurrentBeatInBar() == 0);
        auto e3Box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& e3 = *e3Box; e3.setBeatsPerBar(3); e3.resetForStart(0.0);
        e3.setBeatPosition(snappedBeat(38.5709, 0.094321, 3.0));
        assert(std::fabs(e3.getPendingBeat() - 40.0) < 1e-9 && e3.getCurrentBeatInBar() == 1);
        auto e6Box = std::make_unique<MetronomeDSP>(kRate, 101.0);   // sullo heap, come metronome_create
        MetronomeDSP& e6 = *e6Box; e6.setBeatsPerBar(6); e6.resetForStart(0.0);
        e6.setBeatPosition(snappedBeat(38.5709, 0.094321, 6.0));
        assert(std::fabs(e6.getPendingBeat() - 43.0) < 1e-9 && e6.getCurrentBeatInBar() == 1);
    }
    {   // un battito proprio sul confine resta li' ed e' l'«uno»; mezzo campione di tolleranza (l'epsilon del DSP)
        auto dBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *dBox; d.setBeatsPerBar(4); d.resetForStart(0.0);
        d.setBeatPosition(40.0);
        assert(std::fabs(d.getPendingBeat() - 40.0) < 1e-12 && d.getCurrentBeatInBar() == 0);
        const double underHalfSample = 0.4 / kRate * (121.0 / 60.0);
        d.setBeatPosition(40.0 + underHalfSample);
        assert(std::fabs(d.getPendingBeat() - 40.0) < 1e-12 && d.getCurrentBeatInBar() == 0);
        const double overHalfSample = 0.6 / kRate * (121.0 / 60.0);
        d.setBeatPosition(40.0 + overHalfSample);
        assert(std::fabs(d.getPendingBeat() - 41.0) < 1e-12 && d.getCurrentBeatInBar() == 1);
        assert(std::fabs(snappedBeat(40.001, 0.0, 4.0) - 44.0) < 1e-12);
        d.setBeatPosition(44.0);
        assert(std::fabs(d.getPendingBeat() - 44.0) < 1e-12 && d.getCurrentBeatInBar() == 0);
    }
    {   // la griglia di 8 x 4 x 50 casi: il battito scattato meno l'origine del DSP e' un numero intero di battute,
        // il DSP lo mette sull'«uno», e il battito in attesa e' il battito scattato
        int cases = 0;
        const uint32_t bpbs[]    = { 2, 3, 4, 5, 6, 7, 9, 12 };
        const double   origins[] = { 0.0, 12.0, 37.25, 1003.5 };
        for (uint32_t bpb : bpbs) {
            for (double origin : origins) {
                for (int k = 0; k < 50; ++k) {
                    const double beat    = origin + (double)k * 0.731 + 0.013;
                    const double snapped = snappedBeat(beat, origin, (double)bpb);
                    auto dBox = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
                    MetronomeDSP& d = *dBox;
                    d.setBeatsPerBar(bpb);
                    d.resetForStart(origin);
                    d.setBeatPosition(snapped);
                    assert(d.getCurrentBeatInBar() == 0);
                    assert(std::fabs(d.getPendingBeat() - snapped) < 1e-9);
                    assert(snapped >= beat - 1e-9 && snapped - beat < (double)bpb + 1e-9);
                    ++cases;
                }
            }
        }
        assert(cases == 8 * 4 * 50);
    }
    std::printf("PASS test_caso_10_dspPosition_sul_DSP_vero\n");
}

// ─────────────────────────── caso 11: il costruttore sopra una memoria sporca (A.12) ───────────────────────────

void test_caso_11_costruttore_su_memoria_sporca() {
    // (A432 parte 2a; VERIFICA_REFEREE_A432_PARTE1 par. 3.1, A.12.) Il DSP costruito SOPRA una memoria riempita
    // apposta di un valore diverso da zero (placement new su un blocco preso dallo heap: il DSP pesa circa 420 KB
    // e non va sulla pila), e letto prima di ogni altra chiamata: il battito in attesa e' l'origine (0), al primo
    // campione. Senza l'inizializzazione di _pendingBeatIdx nel costruttore il valore sarebbe quello della
    // memoria (0xA5A5...). Un DSP costruito su una memoria appena presa dal sistema, spesso a zero, passerebbe
    // lo stesso: per questo la memoria si sporca prima.
    static_assert(alignof(MetronomeDSP) <= alignof(std::max_align_t),
                  "l'allineamento di operator new non basta per MetronomeDSP");
    const size_t bytes = sizeof(MetronomeDSP);
    void* mem = ::operator new(bytes);
    std::memset(mem, 0xA5, bytes);
    MetronomeDSP* d = new (mem) MetronomeDSP(kRate, 121.0);
    const double  nome  = d->getPendingBeat();            // prima di ogni altra chiamata
    const int64_t ahead = d->getPendingSamplesAhead();
    std::printf("  costruttore sopra %zu byte a 0xA5: nome=%.1f campioni=%lld etichetta=%u origine=%.1f\n",
                bytes, nome, (long long)ahead, d->getCurrentBeatInBar(), d->getStartAbsoluteBeat());
    assert(nome == 0.0);
    assert(ahead == 0);
    assert(d->getCurrentBeatInBar() == 0 && d->getStartAbsoluteBeat() == 0.0);
    const auto evs = d->processBuffer(kBuf);              // e il battito 0 esce al campione 0, accentato
    assert(evs.size() == 1 && evs[0].isBeat && evs[0].offset == 0 && evs[0].accent);
    assert(d->getPendingBeat() == 1.0);
    d->~MetronomeDSP();
    ::operator delete(mem);
    std::printf("PASS test_caso_11_costruttore_su_memoria_sporca\n");
}

// ─────────────────────────── caso 12: il getter con la mappa adattiva attiva ───────────────────────────

void test_caso_12_getter_con_la_mappa_adattiva() {
    // (A432 parte 2a; il ramo scoperto di NOTE_VERIFICATORI_A432_PARTE1, A par. 5 e, 7.) Col Follower adattivo
    // processBuffer riscrive _bpm a inizio buffer dalla mappa, senza toccare il battito in attesa: il tempo nuovo
    // vale dal battito dopo. Il getter letto prima di ogni processBuffer deve dire lo stesso il battito che
    // esce, nome e campione, in ogni chiamata.
    {   // il gradino di test_adaptive_follower (120 fino a 239999, 60 da 240000; buffer 256), coi suoi campioni
        // letterali: il battito a 240000 era gia' in attesa, il suo passo usa ancora il tempo di prima (264000),
        // poi 48000 campioni per battito
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 90.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        TempoMap m;
        const bool fatta = TempoMap::make({ { 0, 120.0 }, { 239999, 120.0 }, { 240000, 60.0 } }, kRate, m);
        assert(fatta);
        const bool accesa = dsp.setTempoMap(m);
        assert(accesa && dsp.isAdaptiveActive());
        dsp.resetForStart(0.0);
        const uint64_t attesi[15] = { 0, 24000, 48000, 72000, 96000, 120000, 144000, 168000, 192000,
                                      216000, 240000, 264000, 312000, 360000, 408000 };
        uint64_t cursor = 0;
        size_t usciti = 0;
        int letture = 0;
        while (usciti < 15) {
            const Pending g = readPending(dsp);
            assert(ll(g.beat) == (long long)usciti);                          // il nome: i battiti usciti dall'origine
            assert((int64_t)cursor + g.ahead == (int64_t)attesi[usciti]);     // il campione vero, in ogni chiamata
            bool out = false;
            for (const auto& e : dsp.processBuffer(256)) {
                if (!e.isBeat) continue;
                assert(cursor + e.offset == attesi[usciti]);
                assert(g.ahead == (int64_t)e.offset);
                ++usciti;
                out = true;
            }
            if (!out) assert(g.ahead >= 256);
            cursor += 256;
            ++letture;
            assert(letture < 100000);
        }
    }
    {   // una rampa (120 a 0, 150 a dieci secondi): il tempo cambia a ogni buffer; nessun campione letterale, ma
        // ogni lettura fra un battito e l'altro deve annunciare il campione a cui quel battito poi esce
        auto dspBox = std::make_unique<MetronomeDSP>(kRate, 90.0);   // sullo heap, come metronome_create
        MetronomeDSP& dsp = *dspBox;
        TempoMap m;
        const bool fatta = TempoMap::make({ { 0, 120.0 }, { 480000, 150.0 } }, kRate, m);
        assert(fatta);
        const bool accesa = dsp.setTempoMap(m);
        assert(accesa);
        dsp.resetForStart(0.0);
        uint64_t cursor = 0;
        std::vector<int64_t> annunci;
        std::vector<uint64_t> battiti;
        int letture = 0;
        while (battiti.size() < 30) {
            const Pending g = readPending(dsp);
            assert(ll(g.beat) == (long long)battiti.size());
            annunci.push_back((int64_t)cursor + g.ahead);
            bool out = false;
            for (const auto& e : dsp.processBuffer(kBuf)) {
                if (!e.isBeat) continue;
                for (int64_t a : annunci) assert(a == (int64_t)(cursor + e.offset));   // tutte le letture dicevano questo campione
                assert(g.ahead == (int64_t)e.offset);
                battiti.push_back(cursor + e.offset);
                annunci.clear();
                out = true;
            }
            if (!out) assert(g.ahead >= (int64_t)kBuf);
            cursor += kBuf;
            ++letture;
            assert(letture < 100000);
        }
        // la mappa ha davvero cambiato il tempo: il primo passo e' di 24000 campioni (120), l'ultimo e' sotto 20500
        assert(battiti[1] - battiti[0] == 24000);
        assert(battiti[29] - battiti[28] < 20500);
        for (size_t i = 2; i < battiti.size(); ++i)
            assert(battiti[i] - battiti[i - 1] <= battiti[i - 1] - battiti[i - 2] + 1);   // i passi si accorciano
    }
    std::printf("PASS test_caso_12_getter_con_la_mappa_adattiva\n");
}

}  // namespace

int main() {
    assertSuStderr();
    setvbuf(stdout, nullptr, _IONBF, 0);   // le righe PASS subito, anche con l'uscita su un file
    test_casi_1_2_3_getter_vero_e_d_accordo_con_la_regola_swift_senza_salto();
    test_caso_4_subito_e_le_chiamate_dopo_senza_correzione();
    test_caso_5_bordo_del_buffer();
    test_caso_6_swing();
    test_caso_7_cambio_armato();
    test_caso_8_setter_fra_lettura_e_processBuffer();
    test_caso_9_dopo_il_buco_di_1_61_un_battito_non_esce();
    test_caso_10_dspPosition_sul_DSP_vero();
    test_caso_11_costruttore_su_memoria_sporca();
    test_caso_12_getter_con_la_mappa_adattiva();
    std::printf("\nALL TESTS PASSED (test_pending_beat)\n");
    return 0;
}
