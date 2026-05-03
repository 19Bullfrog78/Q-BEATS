import Foundation

@MainActor
final class AppNavigationState: ObservableObject {
    @Published var showLive = false
}
