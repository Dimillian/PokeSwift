import SwiftUI
import PokeCore

@main
struct PokeMacApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
        }
        .commands {
            CommandMenu("PokeMac") {
                Button("Toggle Debug Panel") {
                    coordinator.toggleDebugPanel()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}
