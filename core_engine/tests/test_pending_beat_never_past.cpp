// === A432, parte 2a (12/11/2026) — IL BATTITO IN ATTESA MAI NEL PASSATO (VERIFICA_REFEREE_A432_PARTE1, par. 3.2) ===
// processBuffer fa uscire un battito solo quando il cursore e' uguale al suo campione arrotondato, e lo fa
// avanzare solo li': un battito scritto col campione arrotondato PRIMA del cursore non esce piu', e nemmeno
// quelli dopo, finche' una correzione col «subito» o un riavvio non lo riscrivono. Due scritture lo mettevano
// li' (misurato sul DSP di b0136e38):
// - setBPM: riscala la distanza fra cursore e battito; se il battito sta meno di mezzo campione sotto il
//   cursore (arrotondato uguale: dopo resetForStart con un battito non intero di campioni, o col battito al
//   primo campione del buffer dopo) e il tempo rallenta, la distanza riscalata passa il mezzo campione;
// - setBeatPosition: il cursore e' round(posizione), il battito in attesa e' quello entro mezzo campione prima
//   della posizione: con la posizione fra 0,40 e 0,49 campioni dopo il battito i due arrotondamenti si separano.
// La cura (nei due setter, dopo la scrittura del campione): se il campione ARROTONDATO e' prima del cursore, il
// campione va al cursore; l'identita' non cambia. Qui: la sonda dell'auditor, i casi di bordo.cpp, il battito a
// cavallo del buffer, un controllo che i battiti che uscivano gia' non si spostano, una prova a tappeto dopo
// ogni setter, le suddivisioni e lo swing dopo la cura.
// Gli oracoli non usano il getter: il campione di un click e' l'offset dell'evento che processBuffer rende.
// I banchi di core_engine segnalano gli errori solo con assert(): con NDEBUG definito questo file non si compila.
#ifdef NDEBUG
#error "test_pending_beat_never_past: NDEBUG definito, gli assert() sarebbero spenti - compilare in Debug (-DCMAKE_BUILD_TYPE=Debug)"
#endif

#include "MetronomeDSP.h"

#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <memory>
#include <vector>

// Solo per una compilazione locale su Windows con la CRT di debug di MSVC: un assert() fallito andrebbe in una
// finestra modale e il banco resterebbe appeso; qui va su stderr e il processo esce, come su macOS. Nessun effetto
// sul runner della CI.
#if defined(_MSC_VER) && defined(_DEBUG)
#include <crtdbg.h>
#include <cstdlib>
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

double   spbOf(double bpm) { return kRate * 60.0 / bpm; }
// Il cursore dopo resetForStart / setBeatPosition: round(beat * spb), la stessa espressione del DSP.
uint64_t cursorOf(double beat, double spb) { return (uint64_t)std::round(beat * spb); }

struct Ev { uint64_t sample; bool isBeat; bool accent; };

// Suona `buffers` buffer da `buf` campioni a partire da `cursor`; rende gli eventi coi campioni assoluti.
std::vector<Ev> play(MetronomeDSP& d, uint64_t& cursor, int buffers, uint32_t buf = kBuf) {
    std::vector<Ev> out;
    for (int b = 0; b < buffers; ++b) {
        for (const auto& e : d.processBuffer(buf)) out.push_back({ cursor + e.offset, e.isBeat, e.accent });
        cursor += buf;
    }
    return out;
}

int countBeats(const std::vector<Ev>& ev) { int n = 0; for (const Ev& e : ev) if (e.isBeat) ++n; return n; }
int countSubdiv(const std::vector<Ev>& ev) { return (int)ev.size() - countBeats(ev); }

// ─────────────────────────── 1: la sonda dell'auditor (setBPM dopo resetForStart) ───────────────────────────

void test_sonda_setBPM_piu_lento_dopo_resetForStart() {
    // resetForStart(s) a 121 con s = 1, 4, 7: il battito s sta a s * 23801,65 campioni, il cursore al suo
    // arrotondamento per eccesso (0,35 / 0,39 / 0,43 campioni sopra). setBPM(60) prima di processBuffer
    // raddoppia quella distanza: sul DSP di b0136e38 il getter dice -1 e in 300 buffer (3,2 s) non esce nessun
    // battito. Dopo la cura: mai negativo, la stessa identita', il battito al campione 0 del buffer dopo, poi
    // uno per battito (a 60 ogni 48000 campioni esatti).
    const double starts[] = { 1.0, 4.0, 7.0 };
    for (double s : starts) {
        auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        d.resetForStart(s);
        uint64_t cursor = cursorOf(s, spbOf(121.0));
        const uint64_t c0 = cursor;
        const int64_t aheadPrima = d.getPendingSamplesAhead();
        const double  nomePrima  = d.getPendingBeat();
        d.setBPM(60.0);
        const int64_t aheadDopo = d.getPendingSamplesAhead();
        const double  nomeDopo  = d.getPendingBeat();
        const std::vector<Ev> ev = play(d, cursor, 300);
        std::printf("  sonda s=%.0f: campioni prima=%lld dopo setBPM(60)=%lld nome prima=%.1f dopo=%.1f battiti in 300 buffer=%d\n",
                    s, (long long)aheadPrima, (long long)aheadDopo, nomePrima, nomeDopo, countBeats(ev));
        assert(aheadPrima == 0);
        assert(aheadDopo >= 0);                          // mai nel passato
        assert(nomePrima == s && nomeDopo == nomePrima); // la stessa identita'
        assert(ev.size() == 4);                          // 153600 campioni a 60: il battito s e i tre dopo
        for (size_t i = 0; i < ev.size(); ++i) {
            assert(ev[i].isBeat);
            assert(ev[i].sample == c0 + (uint64_t)i * 48000);   // il primo al campione 0 del buffer dopo, poi uno per battito
        }
        assert(d.getPendingBeat() == s + 4.0);           // quattro battiti usciti, l'identita' e' salita di quattro
    }
    std::printf("PASS test_sonda_setBPM_piu_lento_dopo_resetForStart\n");
}

// ─────────────────────────── 2: il battito al primo campione del buffer dopo (la strada del palco) ───────────────────────────

void test_setBPM_col_battito_a_cavallo_del_buffer() {
    // Lo stesso stato raggiunto suonando, senza resetForStart(s): a 121 dopo 23802 campioni (46 buffer da 512 e
    // uno da 250) il battito 1 (a 23801,65) e' al primo campione del buffer dopo, 0,35 campioni sotto il cursore.
    // E' il caso del Follower che riceve un tempo piu' lento dal richiamo di Link proprio in quell'istante.
    auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
    MetronomeDSP& d = *box;
    d.resetForStart(0.0);
    uint64_t cursor = 0;
    std::vector<Ev> prima = play(d, cursor, 46);
    for (const auto& e : d.processBuffer(250)) prima.push_back({ cursor + e.offset, e.isBeat, e.accent });
    cursor += 250;
    assert(cursor == 23802 && countBeats(prima) == 1 && prima[0].sample == 0);
    assert(d.getPendingSamplesAhead() == 0 && d.getPendingBeat() == 1.0);
    d.setBPM(60.0);
    const int64_t aheadDopo = d.getPendingSamplesAhead();
    const double  nomeDopo  = d.getPendingBeat();
    const std::vector<Ev> ev = play(d, cursor, 300);
    std::printf("  a cavallo: campioni dopo setBPM(60)=%lld nome=%.1f battiti in 300 buffer=%d\n",
                (long long)aheadDopo, nomeDopo, countBeats(ev));
    assert(aheadDopo >= 0);
    assert(nomeDopo == 1.0);
    assert(ev.size() == 4);
    for (size_t i = 0; i < ev.size(); ++i) assert(ev[i].isBeat && ev[i].sample == 23802 + (uint64_t)i * 48000);
    std::printf("PASS test_setBPM_col_battito_a_cavallo_del_buffer\n");
}

// ─────────────────────────── 3: i casi di bordo.cpp (setBeatPosition nel suo mezzo campione) ───────────────────────────

void test_bordo_setBeatPosition_mezzo_campione() {
    // 121 col battito 40 (griglia 952066,116) e 91 col battito 12 (379780,220): con la posizione fra 0,40 e 0,49
    // campioni dopo il battito il cursore va a round(posizione) = un campione oltre l'arrotondamento del battito.
    // Sul DSP di b0136e38: getter -1, nessun battito in 150 buffer. Dopo la cura: mai negativo, il battito k (lo
    // stesso nome, l'«uno»: 40 e 12 sono multipli di 4) al campione 0 del buffer dopo, poi uno per battito a
    // partire da quel campione (la griglia resta spostata di meno di un campione finche' una scrittura non la riporta).
    struct Caso { double bpm; double k; };
    const Caso casi[] = { { 121.0, 40.0 }, { 91.0, 12.0 } };
    int provati = 0;
    for (const Caso& c : casi) {
        const double spb = spbOf(c.bpm);
        for (int f = 40; f <= 49; ++f) {
            const double oltre = (double)f / 100.0;   // campioni dopo il battito
            auto box = std::make_unique<MetronomeDSP>(kRate, c.bpm);   // sullo heap, come metronome_create
            MetronomeDSP& d = *box;
            d.setBeatsPerBar(4);
            d.resetForStart(0.0);
            const double pos = c.k + oltre / spb;
            d.setBeatPosition(pos);
            uint64_t cursor = cursorOf(pos, spb);
            const uint64_t c0 = cursor;
            const int64_t ahead = d.getPendingSamplesAhead();
            const double  nome  = d.getPendingBeat();
            const uint32_t etichetta = d.getCurrentBeatInBar();
            const std::vector<Ev> ev = play(d, cursor, 150);   // 76800 campioni: piu' di tre battiti a 121, piu' di due a 91
            if (f == 40 || f == 45 || f == 49)
                std::printf("  bordo %.0f battito %.0f, %.2f campioni dopo: cursore=%llu campioni=%lld nome=%.1f battiti in 150 buffer=%d\n",
                            c.bpm, c.k, oltre, (unsigned long long)c0, (long long)ahead, nome, countBeats(ev));
            assert(c0 == (uint64_t)std::llround(c.k * spb) + 1);   // il caso e' quello: il cursore un campione oltre il battito
            assert(ahead >= 0);                                     // mai nel passato
            assert(nome == c.k && etichetta == 0);                  // la stessa identita', l'«uno»
            const int attesi = (c.bpm == 121.0) ? 4 : 3;
            assert((int)ev.size() == attesi);
            double exact = (double)c0;                              // il campione scritto dalla cura: il cursore
            for (size_t i = 0; i < ev.size(); ++i) {
                assert(ev[i].isBeat);
                assert(ev[i].sample == (uint64_t)std::llround(exact));
                assert(ev[i].accent == (i == 0));                   // l'«uno» accentato, poi 1, 2, 3
                exact += spb;
            }
            assert(ev[0].sample == c0);                             // al campione 0 del buffer dopo
            ++provati;
        }
    }
    assert(provati == 20);
    std::printf("PASS test_bordo_setBeatPosition_mezzo_campione\n");
}

// ─────────────────────────── 4: i battiti che uscivano gia' non si spostano ───────────────────────────

void test_chi_usciva_gia_non_si_sposta() {
    // La cura confronta il campione ARROTONDATO, come processBuffer e come il getter: scatta solo su un battito
    // che non uscirebbe piu'. Un battito scritto meno di mezzo campione sotto il cursore (arrotondato uguale) esce
    // gia' al campione 0, e i battiti dopo partono dal suo campione esatto: non deve cambiare niente. L'oracolo
    // rifa' la scrittura del setter e conta i battiti dal campione esatto; se la cura confrontasse il valore
    // esatto (come il «subito» di setBeatPositionTimeOnly) i casi «sani sotto il cursore» partirebbero dal
    // cursore, e una parte dei battiti dopo cadrebbe un campione piu' in la'.
    int casi = 0, curati = 0, sani = 0, saniSottoIlCursore = 0, diversi = 0;
    // (a) setBPM dopo resetForStart(s): x2 = c + (s*spbA - c) * (A/B), la riga di setBPM
    const double coppie[][2] = { { 121.0, 60.0 }, { 121.0, 141.0 }, { 121.0, 91.0 }, { 91.0, 121.0 }, { 141.0, 101.3 },
                                 { 60.5, 180.5 }, { 180.5, 60.5 }, { 300.0, 30.0 }, { 101.0, 100.0 } };
    for (const auto& cp : coppie) {
        const double A = cp[0], B = cp[1];
        const double spbA = spbOf(A), spbB = spbOf(B);
        for (int i = 0; i < 59; ++i) {
            const double s = (i < 8) ? (double)i : (double)(i - 7) * 0.37;   // partenze intere e non intere
            auto box = std::make_unique<MetronomeDSP>(kRate, A);   // sullo heap, come metronome_create
            MetronomeDSP& d = *box;
            d.resetForStart(s);
            const uint64_t c = cursorOf(s, spbA);
            d.setBPM(B);
            const double x  = s * spbA;
            const double x2 = (double)c + (x - (double)c) * (A / B);
            const bool   nelPassato = std::round(x2) < (double)c;
            double exact = nelPassato ? (double)c : x2;
            ++casi;
            if (nelPassato) ++curati; else { ++sani; if (x2 < (double)c) ++saniSottoIlCursore; }
            if (d.getPendingSamplesAhead() != (int64_t)(std::round(exact) - (double)c)) ++diversi;
            if (d.getPendingBeat() != s) ++diversi;
            uint64_t cursor = c;
            int visti = 0;
            for (int b = 0; b < 4000 && visti < 12; ++b) {
                for (const auto& e : d.processBuffer(kBuf)) {
                    if (!e.isBeat) continue;
                    if (cursor + e.offset != (uint64_t)std::llround(exact)) ++diversi;
                    exact += spbB;
                    ++visti;
                }
                cursor += kBuf;
            }
            if (visti != 12) ++diversi;
        }
    }
    // (b) setBeatPosition vicino a un battito: il battito in attesa e' ceil(posizione - mezzo campione), a n * spb
    const double tempi[] = { 121.0, 91.0, 101.0, 120.0, 141.0, 180.5 };
    const double battiti[] = { 12.0, 40.0, 42.0, 44.0, 57.0 };
    const double oltre[] = { 0.0, 0.1, 0.2, 0.3, 0.4, 0.45, 0.49, 0.6, 0.9 };
    for (double bpm : tempi) {
        const double spb = spbOf(bpm);
        const double eps = 0.5 / kRate * (bpm / 60.0);
        for (double k : battiti) {
            for (double o : oltre) {
                auto box = std::make_unique<MetronomeDSP>(kRate, bpm);   // sullo heap, come metronome_create
                MetronomeDSP& d = *box;
                d.resetForStart(0.0);
                const double pos = k + o / spb;
                d.setBeatPosition(pos);
                const uint64_t c = cursorOf(pos, spb);
                const double n  = std::ceil(pos - eps);
                const double x  = n * spb;
                const bool   nelPassato = std::round(x) < (double)c;
                double exact = nelPassato ? (double)c : x;
                ++casi;
                if (nelPassato) ++curati; else { ++sani; if (x < (double)c) ++saniSottoIlCursore; }
                if (d.getPendingSamplesAhead() != (int64_t)(std::round(exact) - (double)c)) ++diversi;
                if (d.getPendingBeat() != n) ++diversi;
                uint64_t cursor = c;
                int visti = 0;
                for (int b = 0; b < 4000 && visti < 40; ++b) {
                    for (const auto& e : d.processBuffer(kBuf)) {
                        if (!e.isBeat) continue;
                        if (cursor + e.offset != (uint64_t)std::llround(exact)) ++diversi;
                        exact += spb;
                        ++visti;
                    }
                    cursor += kBuf;
                }
                if (visti != 40) ++diversi;
            }
        }
    }
    std::printf("  non si sposta: casi:%d curati:%d sani:%d saniSottoIlCursore:%d diversiDallOracolo:%d\n",
                casi, curati, sani, saniSottoIlCursore, diversi);
    assert(diversi == 0);
    assert(curati > 0);               // dentro ci sono casi che la cura tocca...
    assert(saniSottoIlCursore > 0);   // ... e casi sotto il cursore che non deve toccare
    std::printf("PASS test_chi_usciva_gia_non_si_sposta\n");
}

// ─────────────────────────── 5: a tappeto, dopo ogni setter ───────────────────────────

struct Lcg {
    uint64_t s;
    uint32_t next() { s = s * 6364136223846793005ULL + 1442695040888963407ULL; return (uint32_t)(s >> 33); }
    int      pick(int n) { return (int)(next() % (uint32_t)n); }
    double   unit() { return (double)next() / 2147483648.0; }   // [0, 1)
};

enum Setter {
    kSetBPM, kSetBeatPosition, kSetBeatPositionTimeOnly, kResetForStart, kSetAbsolutePositionForTesting,
    kSetSampleRate, kSetBeatsPerBar, kSetAccentPattern, kSetSubdivision, kScheduleBPMChange, kCancelPendingBPM,
    kScheduleBeatsPerBarChange, kCancelPendingBPB, kScheduleAccentPatternChange, kScheduleSubdivisionChange,
    kCancelPendingSubdivision, kSetAccentVolume, kSetBeatVolume, kSetSubdivVolume, kSetMuted, kRenamePendingBeat,
    kSetTempoMap, kClearTempoMap, kSetDiagEnabled, kProcessBuffer, kSetterCount
};
const char* const kSetterName[kSetterCount] = {
    "setBPM", "setBeatPosition", "setBeatPositionTimeOnly", "resetForStart", "setAbsolutePositionForTesting",
    "setSampleRate", "setBeatsPerBar", "setAccentPattern", "setSubdivision", "scheduleBPMChange", "cancelPendingBPM",
    "scheduleBeatsPerBarChange", "cancelPendingBPB", "scheduleAccentPatternChange", "scheduleSubdivisionChange",
    "cancelPendingSubdivision", "setAccentVolume", "setBeatVolume", "setSubdivVolume", "setMuted", "renamePendingBeat",
    "setTempoMap", "clearTempoMap", "setDiagEnabled", "processBuffer"
};

struct Tappeto {
    long long chiamate[kSetterCount] = {};
    long long negativi[kSetterCount] = {};   // la scrittura ha portato il getter sotto zero (prima non lo era)
    long long ereditati = 0;                 // il getter era gia' sotto zero prima della scrittura
    long long nomeCambiato = 0;              // un setter che non deve toccare l'identita' l'ha cambiata
    long long annunciatiNonUsciti = 0;       // 0 <= campioni < buffer e nel buffer il battito non c'e' a quell'offset
    long long uscitiSenzaAnnuncio = 0;       // un battito uscito in un buffer che il getter non annunciava
    long long battiti = 0;
};

// Chiama il setter e conta. `tieneIlNome`: il setter non deve cambiare l'identita' del battito in attesa.
template <typename F>
void scrivi(MetronomeDSP& d, Tappeto& t, Setter quale, bool tieneIlNome, F f) {
    const int64_t prima     = d.getPendingSamplesAhead();
    const double  nomePrima = d.getPendingBeat();
    f();
    ++t.chiamate[quale];
    if (d.getPendingSamplesAhead() < 0) { if (prima >= 0) ++t.negativi[quale]; else ++t.ereditati; }
    if (tieneIlNome && d.getPendingBeat() != nomePrima) ++t.nomeCambiato;
}

void suona(MetronomeDSP& d, Tappeto& t, int buffers, uint32_t buf) {
    for (int b = 0; b < buffers; ++b) {
        const int64_t a = d.getPendingSamplesAhead();
        const auto evs = d.processBuffer(buf);
        ++t.chiamate[kProcessBuffer];
        bool trovato = false;
        int  usciti = 0;
        for (const auto& e : evs) {
            if (!e.isBeat) continue;
            ++usciti;
            ++t.battiti;
            if (a >= 0 && (int64_t)e.offset == a) trovato = true;
        }
        if (a >= 0 && a < (int64_t)buf && !trovato) ++t.annunciatiNonUsciti;
        if ((a < 0 || a >= (int64_t)buf) && usciti > 0) ++t.uscitiSenzaAnnuncio;
        if (d.getPendingSamplesAhead() < 0) { if (a >= 0) ++t.negativi[kProcessBuffer]; else ++t.ereditati; }
    }
}

void test_a_tappeto_dopo_ogni_setter() {
    // Molti stati di partenza (tempi non interi, posizioni nel buffer, frazioni) e, dopo OGNI setter pubblico del
    // DSP e dopo ogni processBuffer, getPendingSamplesAhead() >= 0. Due parti: una griglia sulle due strade note
    // (resetForStart o un tratto suonato, poi setBPM; setBeatPosition vicino a un battito) e sequenze a caso di
    // tutti i setter (generatore fisso: gli stessi numeri a ogni corsa). I conti sono per setter, e un negativo
    // si conta sul setter che l'ha fatto nascere: sul DSP di b0136e38 cadono solo setBPM e setBeatPosition.
    Tappeto t;
    const double tempi[] = { 60.5, 91.0, 101.3, 121.0, 133.7, 141.0, 180.5, 240.1 };
    const uint32_t bufs[] = { 64, 128, 256, 480, 512, 1024 };
    long long stati = 0;

    // --- la griglia sulle due strade ---
    for (double A : tempi) {
        const double spbA = spbOf(A);
        for (double B : tempi) {
            if (A == B) continue;
            for (int i = 0; i < 23; ++i) {
                const double s = (double)i * 0.37 + (double)(i % 4);
                for (uint32_t buf : bufs) {
                    auto box = std::make_unique<MetronomeDSP>(kRate, A);   // sullo heap, come metronome_create
                    MetronomeDSP& d = *box;
                    ++stati;
                    scrivi(d, t, kResetForStart, false, [&] { d.resetForStart(s); });
                    scrivi(d, t, kSetBPM, true, [&] { d.setBPM(B); });
                    suona(d, t, 3, buf);
                    // un tratto suonato che finisce su un battito: il battito dopo al primo campione del buffer dopo
                    scrivi(d, t, kResetForStart, false, [&] { d.resetForStart(0.0); });
                    const uint32_t finoAlBattito = (uint32_t)std::llround((double)((i % 5) + 1) * spbOf(B));
                    suona(d, t, 1, finoAlBattito);
                    scrivi(d, t, kSetBPM, true, [&] { d.setBPM(A); });
                    suona(d, t, 2, buf);
                    // setBeatPosition vicino a un battito, da 0 a 0,95 campioni dopo
                    const double k = (double)(8 + i);
                    const double pos = k + ((double)((i * 7 + (int)buf) % 20) * 0.05) / spbA;
                    scrivi(d, t, kSetBeatPosition, false, [&] { d.setBeatPosition(pos); });
                    scrivi(d, t, kSetBPM, true, [&] { d.setBPM(B); });
                    suona(d, t, 2, buf);
                }
            }
        }
    }

    // --- le sequenze a caso di tutti i setter ---
    Lcg g { 0x432A2026ULL };
    const int corse = 2000, passi = 40;
    for (int r = 0; r < corse; ++r) {
        double   bpm  = tempi[g.pick(8)];
        double   rate = kRate;
        const uint32_t buf = bufs[g.pick(6)];
        auto box = std::make_unique<MetronomeDSP>(rate, bpm);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        ++stati;
        scrivi(d, t, kResetForStart, false, [&] { d.resetForStart((double)g.pick(16) + (g.pick(2) ? g.unit() : 0.0)); });
        for (int p = 0; p < passi; ++p) {
            const double spb = rate * 60.0 / bpm;
            // la posizione di adesso in battiti, per generare posizioni vicine (solo per scegliere gli ingressi)
            const double adesso = d.getPendingBeat() - (double)d.getPendingSamplesAhead() / spb;
            switch (g.pick(30)) {
            case 0: case 1: case 2: case 3: case 4: case 5:
                suona(d, t, 1 + g.pick(40), buf); break;
            case 6: case 7: case 8:
                bpm = tempi[g.pick(8)];
                scrivi(d, t, kSetBPM, true, [&] { d.setBPM(bpm); }); break;
            case 9: case 10: {
                // vicino a un battito della griglia, da 0 a 1 campione dopo; oppure una posizione qualunque
                const double pos = g.pick(3) ? std::floor(adesso + 1.0 + (double)g.pick(8)) + g.unit() / spb
                                             : 1.0 + g.unit() * 64.0;
                scrivi(d, t, kSetBeatPosition, false, [&] { d.setBeatPosition(pos); }); break;
            }
            case 11: case 12: {
                // una correzione piccola intorno alla posizione di adesso, o un salto
                const double base = (adesso < 1.0) ? 1.0 : adesso;
                const double pos  = g.pick(3) ? base + (g.unit() - 0.5) * 0.04 : base + g.unit() * 3.0;
                scrivi(d, t, kSetBeatPositionTimeOnly, false, [&] { d.setBeatPositionTimeOnly(pos); }); break;
            }
            case 13:
                scrivi(d, t, kResetForStart, false, [&] { d.resetForStart((double)g.pick(64) + (g.pick(2) ? g.unit() : 0.0)); }); break;
            case 14:
                scrivi(d, t, kSetAbsolutePositionForTesting, false, [&] { d.setAbsolutePositionForTesting((uint64_t)g.pick(4000000)); }); break;
            case 15:
                rate = (rate == 48000.0) ? 44100.0 : 48000.0;
                scrivi(d, t, kSetSampleRate, true, [&] { d.setSampleRate(rate); }); break;
            case 16: {
                const uint32_t bpb = 1 + (uint32_t)g.pick(16);
                uint8_t pat[16]; for (auto& x : pat) x = (uint8_t)g.pick(2);
                scrivi(d, t, kSetBeatsPerBar, true, [&] { d.setBeatsPerBar(bpb); });
                scrivi(d, t, kSetAccentPattern, true, [&] { d.setAccentPattern(pat, bpb); }); break;
            }
            case 17:
                scrivi(d, t, kSetSubdivision, true, [&] { d.setSubdivision((uint8_t)(1 + g.pick(4)), 0.5 + g.unit() * 0.4); }); break;
            case 18:
                scrivi(d, t, kScheduleBPMChange, true, [&] { d.scheduleBPMChange(tempi[g.pick(8)]); });
                if (g.pick(3) == 0) scrivi(d, t, kCancelPendingBPM, true, [&] { d.cancelPendingBPM(); });
                break;
            case 19:
                scrivi(d, t, kScheduleBeatsPerBarChange, true, [&] { d.scheduleBeatsPerBarChange(1 + (uint32_t)g.pick(16)); });
                if (g.pick(3) == 0) scrivi(d, t, kCancelPendingBPB, true, [&] { d.cancelPendingBPB(); });
                break;
            case 20: {
                uint8_t pat[16]; for (auto& x : pat) x = (uint8_t)g.pick(2);
                scrivi(d, t, kScheduleAccentPatternChange, true, [&] { d.scheduleAccentPatternChange(pat, 1 + (uint32_t)g.pick(16)); }); break;
            }
            case 21:
                scrivi(d, t, kScheduleSubdivisionChange, true, [&] { d.scheduleSubdivisionChange((uint8_t)(1 + g.pick(4)), 0.5 + g.unit() * 0.4); });
                if (g.pick(3) == 0) scrivi(d, t, kCancelPendingSubdivision, true, [&] { d.cancelPendingSubdivision(); });
                break;
            case 22:
                scrivi(d, t, kSetAccentVolume, true, [&] { d.setAccentVolume(g.unit()); });
                scrivi(d, t, kSetBeatVolume,   true, [&] { d.setBeatVolume(g.unit()); });
                scrivi(d, t, kSetSubdivVolume, true, [&] { d.setSubdivVolume(g.unit()); }); break;
            case 23:
                // muto e subito di nuovo in voce: il secondo valore e' quello che processBuffer applica
                scrivi(d, t, kSetMuted, true, [&] { d.setMuted(true); });
                scrivi(d, t, kSetMuted, true, [&] { d.setMuted(false); }); break;
            case 24: case 25:
                scrivi(d, t, kRenamePendingBeat, true, [&] { d.renamePendingBeat((uint32_t)g.pick(20)); }); break;
            case 26: {
                TempoMap m;
                const bool ok = TempoMap::make({ { 0, tempi[g.pick(8)] }, { 480000, tempi[g.pick(8)] }, { 960000, tempi[g.pick(8)] } },
                                               rate, m);
                assert(ok);
                scrivi(d, t, kSetTempoMap, true, [&] { (void)d.setTempoMap(m); }); break;   // puo' rifiutare (guardia dei due buffer)
            }
            case 27:
                scrivi(d, t, kClearTempoMap, true, [&] { d.clearTempoMap(); }); break;
            case 28:
                scrivi(d, t, kSetDiagEnabled, true, [&] { d.setDiagEnabled(g.pick(2) == 0); }); break;
            default:
                suona(d, t, 1, buf); break;
            }
        }
    }

    long long negativiTotali = 0;
    for (int i = 0; i < kSetterCount; ++i) {
        negativiTotali += t.negativi[i];
        std::printf("  tappeto %-30s chiamate:%-8lld negativi:%lld\n", kSetterName[i], t.chiamate[i], t.negativi[i]);
    }
    std::printf("  tappeto stati:%lld battitiUsciti:%lld negativiNati:%lld negativiEreditati:%lld nomeCambiato:%lld"
                " annunciatiNonUsciti:%lld uscitiSenzaAnnuncio:%lld\n", stati, t.battiti, negativiTotali, t.ereditati,
                t.nomeCambiato, t.annunciatiNonUsciti, t.uscitiSenzaAnnuncio);
    for (int i = 0; i < kSetterCount; ++i) assert(t.chiamate[i] > 0);   // ogni setter e' stato provato
    assert(negativiTotali == 0);          // dopo ogni setter il battito in attesa non e' mai nel passato
    assert(t.ereditati == 0);
    assert(t.nomeCambiato == 0);          // e i setter che non rinominano non hanno cambiato l'identita'
    assert(t.annunciatiNonUsciti == 0);   // un battito annunciato dentro il buffer esce a quell'offset
    assert(t.uscitiSenzaAnnuncio == 0);
    assert(t.battiti > 0);
    std::printf("PASS test_a_tappeto_dopo_ogni_setter\n");
}

// ─────────────────────────── 6: le suddivisioni e lo swing dopo la cura ───────────────────────────

void expectEvents(const std::vector<Ev>& ev, const uint64_t* samples, const bool* isBeat, size_t n) {
    assert(ev.size() == n);
    for (size_t i = 0; i < n; ++i) {
        assert(ev[i].sample == samples[i]);
        assert(ev[i].isBeat == isBeat[i]);
    }
}

void test_suddivisioni_e_swing_dopo_la_cura() {
    // La strada di setBPM (la sonda con s = 1: cursore 23802, poi 60, cioe' 48000 campioni per battito) con le
    // suddivisioni accese. Sul DSP di b0136e38 il difetto lasciava uscire SOLO le suddivisioni, senza nessun
    // battito: la suddivisione si riarma da sola dopo ogni uscita (il ramo isSubdivSample di processBuffer),
    // mentre il battito, rimasto un campione alle spalle del cursore, non scatta piu' (misurato su quel DSP con
    // il primo caso qui sotto, le crome dritte: battiti 0, suddivisioni 6 nei 300 buffer).
    // Dopo la cura il battito esce al campione 0 e riarma il tracker delle suddivisioni da li': in setBPM non
    // serve nessuna riga sul tracker.
    {   // crome dritte
        auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        d.setSubdivision(2, 0.5);
        d.resetForStart(1.0);
        uint64_t cursor = cursorOf(1.0, spbOf(121.0));
        d.setBPM(60.0);
        const std::vector<Ev> ev = play(d, cursor, 300);
        std::printf("  crome dopo setBPM: battiti:%d suddivisioni:%d\n", countBeats(ev), countSubdiv(ev));
        const uint64_t s[] = { 23802, 47802, 71802, 95802, 119802, 143802, 167802 };
        const bool     b[] = { true,  false, true,  false, true,   false,  true   };
        expectEvents(ev, s, b, 7);
    }
    {   // crome con lo swing 0,66: la croma lunga a 0,66 * 48000 = 31680 campioni dal battito
        auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        d.setSubdivision(2, 0.66);
        d.resetForStart(1.0);
        uint64_t cursor = cursorOf(1.0, spbOf(121.0));
        d.setBPM(60.0);
        const std::vector<Ev> ev = play(d, cursor, 300);
        std::printf("  swing 0,66 dopo setBPM: battiti:%d suddivisioni:%d\n", countBeats(ev), countSubdiv(ev));
        const uint64_t s[] = { 23802, 55482, 71802, 103482, 119802, 151482, 167802 };
        const bool     b[] = { true,  false, true,  false,  true,   false,  true   };
        expectEvents(ev, s, b, 7);
    }
    {   // terzine: una suddivisione ogni 16000 campioni
        auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        d.setSubdivision(3, 0.5);
        d.resetForStart(1.0);
        uint64_t cursor = cursorOf(1.0, spbOf(121.0));
        d.setBPM(60.0);
        const std::vector<Ev> ev = play(d, cursor, 300);
        std::printf("  terzine dopo setBPM: battiti:%d suddivisioni:%d\n", countBeats(ev), countSubdiv(ev));
        const uint64_t s[] = { 23802, 39802, 55802, 71802, 87802, 103802, 119802, 135802, 151802, 167802 };
        const bool     b[] = { true,  false, false, true,  false, false,  true,   false,  false,  true   };
        expectEvents(ev, s, b, 10);
    }
    {   // la strada di setBeatPosition con lo swing 0,6 gia' in voce: 121, battito 40, 0,45 campioni dopo. Il
        // battito 40 esce al cursore (952067); la croma lunga di ogni battito sta a round(campione del battito +
        // 0,6 * spb), perche' ogni battito uscito riarma il tracker dal proprio campione.
        auto box = std::make_unique<MetronomeDSP>(kRate, 121.0);   // sullo heap, come metronome_create
        MetronomeDSP& d = *box;
        const double spb = spbOf(121.0);
        d.setBeatsPerBar(4);
        d.setSubdivision(2, 0.6);
        d.resetForStart(0.0);
        uint64_t cursor = 0;
        const std::vector<Ev> avvio = play(d, cursor, 1);          // il battito 0: da qui lo swing e' in voce
        assert(avvio.size() == 1 && avvio[0].isBeat && avvio[0].sample == 0);
        const double pos = 40.0 + 0.45 / spb;
        d.setBeatPosition(pos);
        cursor = cursorOf(pos, spb);
        assert(cursor == 952067);
        assert(d.getPendingSamplesAhead() == 0 && d.getPendingBeat() == 40.0);
        const std::vector<Ev> ev = play(d, cursor, 150);
        std::printf("  swing 0,6 dopo setBeatPosition: battiti:%d suddivisioni:%d\n", countBeats(ev), countSubdiv(ev));
        assert(countBeats(ev) == 4 && countSubdiv(ev) == 3);
        double exact = 952067.0;
        size_t i = 0;
        for (int n = 0; n < 4; ++n) {
            const uint64_t battito = (uint64_t)std::llround(exact);
            assert(i < ev.size() && ev[i].isBeat && ev[i].sample == battito);
            ++i;
            if (n < 3) {
                assert(i < ev.size() && !ev[i].isBeat);
                assert(ev[i].sample == (uint64_t)std::llround((double)battito + 0.6 * spb));
                ++i;
            }
            exact += spb;
        }
        assert(i == ev.size());
    }
    std::printf("PASS test_suddivisioni_e_swing_dopo_la_cura\n");
}

struct Test { const char* nome; void (*f)(); };
const Test kTests[] = {
    { "sonda",       test_sonda_setBPM_piu_lento_dopo_resetForStart },
    { "cavallo",     test_setBPM_col_battito_a_cavallo_del_buffer },
    { "bordo",       test_bordo_setBeatPosition_mezzo_campione },
    { "nonsisposta", test_chi_usciva_gia_non_si_sposta },
    { "tappeto",     test_a_tappeto_dopo_ogni_setter },
    { "suddivisioni", test_suddivisioni_e_swing_dopo_la_cura },
};

}  // namespace

// Senza argomenti esegue tutti i test (cosi' lo lancia CTest). Con un nome ne esegue uno solo: serve alle prove
// locali, per vedere ogni test che cade e non solo il primo.
int main(int argc, char** argv) {
    assertSuStderr();
    setvbuf(stdout, nullptr, _IONBF, 0);   // le righe PASS subito, anche con l'uscita su un file
    int eseguiti = 0;
    for (const Test& t : kTests) {
        if (argc > 1 && std::strcmp(argv[1], t.nome) != 0) continue;
        t.f();
        ++eseguiti;
    }
    if (eseguiti == 0) {
        std::printf("FAIL test_pending_beat_never_past: nessun test col nome chiesto\n");
        return 1;
    }
    if (argc == 1) std::printf("\nALL TESTS PASSED (test_pending_beat_never_past)\n");
    return 0;
}
