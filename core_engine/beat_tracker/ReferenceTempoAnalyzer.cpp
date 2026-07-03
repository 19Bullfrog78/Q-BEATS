#include "ReferenceTempoAnalyzer.h"

#include <algorithm>
#include <cmath>
#include <vector>

namespace {

// Parametri del banco — fissi e documentati (niente adattività = determinismo).
constexpr size_t kFrame        = 256;    // finestra energia (~5.3 ms @ 48 kHz)
constexpr double kMaxBPM       = 400.0;  // refrattario: sotto quest'IOI non è un nuovo onset
constexpr double kMinBPM       = 30.0;   // intervalli più lenti = non plausibili, scartati
constexpr double kEnergyFloor  = 1e-8;   // sotto questo massimo = silenzio numerico
constexpr double kRelThreshold = 0.1;    // soglia relativa al frame più energico

} // namespace

TempoAnalysis ReferenceTempoAnalyzer::analyze(const float* samples, size_t n,
                                              double sampleRate) {
    TempoAnalysis out{TempoMap{}, 0.0f};
    if (samples == nullptr || sampleRate <= 0.0 || n < kFrame * 2) return out;

    // 1 · Envelope d'energia a frame fissi (somma dei quadrati per frame).
    const size_t frameCount = n / kFrame;
    std::vector<double> energy(frameCount, 0.0);
    for (size_t k = 0; k < frameCount; ++k) {
        double acc = 0.0;
        const float* f = samples + k * kFrame;
        for (size_t i = 0; i < kFrame; ++i) acc += (double)f[i] * (double)f[i];
        energy[k] = acc;
    }
    const double maxE = *std::max_element(energy.begin(), energy.end());
    if (maxE < kEnergyFloor) return out;              // silenzio

    // 2 · Peak-picking: massimo locale sopra soglia relativa, con refrattario.
    const double   thresh     = kRelThreshold * maxE;
    const uint64_t refractory = (uint64_t)(sampleRate * 60.0 / kMaxBPM);
    std::vector<uint64_t> onsets;
    for (size_t k = 0; k < frameCount; ++k) {
        if (energy[k] <= thresh) continue;
        const double prev = (k > 0)              ? energy[k - 1] : -1.0;
        const double next = (k + 1 < frameCount) ? energy[k + 1] : -1.0;
        if (energy[k] < prev || energy[k] < next) continue;   // non è un picco

        // 3 · Raffinamento al campione: argmax |x| nel frame ± 1 frame.
        const size_t from = (k > 0) ? (k - 1) * kFrame : 0;
        const size_t to   = std::min(n, (k + 2) * kFrame);
        size_t best    = from;
        float  bestAbs = 0.0f;
        for (size_t i = from; i < to; ++i) {
            const float a = std::fabs(samples[i]);
            if (a > bestAbs) { bestAbs = a; best = i; }
        }
        const uint64_t onset = (uint64_t)best;
        if (!onsets.empty()) {
            if (onset <= onsets.back()) continue;             // stesso evento (plateau)
            if (onset - onsets.back() < refractory) continue; // dentro il refrattario
        }
        onsets.push_back(onset);
    }
    if (onsets.size() < 2) return out;                // niente intervalli → niente mappa

    // 4 · Inter-onset → un TempoPoint per intervallo (bpm = definizione 60·sr/IOI,
    //     ancorato all'onset di sinistra dell'intervallo).
    std::vector<TempoPoint> points;
    std::vector<double>     iois;
    const size_t totalIntervals = onsets.size() - 1;
    for (size_t i = 0; i + 1 < onsets.size(); ++i) {
        const double ioi = (double)(onsets[i + 1] - onsets[i]);
        const double bpm = 60.0 * sampleRate / ioi;
        if (bpm < kMinBPM || bpm > kMaxBPM) continue;         // non plausibile
        points.push_back({onsets[i], bpm});
        iois.push_back(ioi);
    }
    if (points.empty()) return out;

    TempoMap map;
    if (!TempoMap::make(std::move(points), sampleRate, map)) return out;

    // 5 · Confidence deterministica: quota di intervalli plausibili; tetto 0.3
    //     con pochi onset; penalità per IOI irregolari (coeff. di variazione).
    double conf = (double)iois.size() / (double)totalIntervals;
    if (onsets.size() < 4) conf = std::min(conf, 0.3);
    if (iois.size() >= 2) {
        double mean = 0.0;
        for (double v : iois) mean += v;
        mean /= (double)iois.size();
        double var = 0.0;
        for (double v : iois) var += (v - mean) * (v - mean);
        var /= (double)iois.size();
        const double cv = std::sqrt(var) / mean;
        conf *= std::max(0.0, 1.0 - cv);
    }
    out.map        = std::move(map);
    out.confidence = (float)std::min(std::max(conf, 0.0), 1.0);
    return out;
}
