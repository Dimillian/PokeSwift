import SwiftUI
import PokeCore

@main
struct PokeMacApp: App {
    private static let windowSize = CGSize(width: 1150, height: 800)
    @State private var preferences: AppPreferences
    @State private var coordinator: AppCoordinator

    init() {
        let preferences = AppPreferences()
        _preferences = State(initialValue: preferences)
        _coordinator = State(initialValue: AppCoordinator(preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
                .environment(preferences)
        }
        .defaultSize(width: Self.windowSize.width, height: Self.windowSize.height)
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("PokeSwift") {
                Button("Toggle Debug Panel") {
                    coordinator.toggleDebugPanel()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
