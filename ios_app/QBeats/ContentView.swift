import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MetronomeViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Q-Beats")
                .font(.largeTitle)
                .bold()
            
            Text("\(Int(viewModel.bpm)) BPM")
                .font(.system(size: 48, weight: .thin, design: .monospaced))
            
            Slider(value: $viewModel.bpm, in: 40...240, step: 1)
                .padding(.horizontal, 32)
                .onChange(of: viewModel.bpm) { newBPM in
                    viewModel.updateBPM(newBPM)
                }
            
            Button(action: viewModel.togglePlayback) {
                Text(viewModel.isPlaying ? "Stop" : "Start")
                    .font(.title2)
                    .bold()
                    .frame(width: 120, height: 120)
                    .background(viewModel.isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

class MetronomeViewModel: ObservableObject {
    @Published var bpm: Double = 120.0
    @Published var isPlaying: Bool = false
    private let audioEngine = AudioEngine()

    func togglePlayback() {
        if isPlaying {
            audioEngine.stop()
        } else {
            audioEngine.start()
        }
        isPlaying.toggle()
    }

    func updateBPM(_ bpm: Double) {
        audioEngine.setBPM(bpm)
    }
}
