import Observation
import SwiftUI
import PokeCore
import PokeUI

struct RootView: View {
    private static let windowSize = CGSize(width: 1150, height: 800)
    @Environment(AppPreferences.self) private var preferences
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        Group {
            if let bootError = coordinator.bootError {
                legacyPregameChrome {
                    ContentUnavailableView(
                        "Boot Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(bootError)
                    )
                }
            } else if let runtime = coordinator.runtime {
                RuntimeSceneRouter(runtime: runtime)
            } else {
                legacyPregameChrome {
                    GameBoyScreen {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Bootstrapping PokeMac")
                                .font(.headline)
                        }
                        .foregroundStyle(legacyPregamePalette.primaryText.color)
                    }
                }
            }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
        .preferredColorScheme(preferences.appearanceMode.preferredColorSchemeOverride)
        .pokeAppearanceMode(preferences.appearanceMode)
        .pokeGameBoyShellStyle(preferences.gameBoyShellStyle)
        .pokeGameplayHDREnabled(preferences.gameplayHDREnabled)
        .toolbar {
            ToolbarItem {
                Button("Debug") {
                    coordinator.toggleDebugPanel()
                }
            }
        }
        .sheet(isPresented: $coordinator.showDebugPanel) {
            if let runtime = coordinator.runtime {
                DebugPanel(snapshot: runtime.currentSnapshot())
                    .padding(24)
                    .frame(minWidth: 520, minHeight: 320)
            }
        }
        .onAppear {
            coordinator.requestForegroundActivationIfNeeded()
        }
        .onDisappear {
            coordinator.shutdown()
        }
    }

    private var legacyPregamePalette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: .light,
            shellStyle: .classic,
            colorScheme: .light
        )
    }

    func legacyPregameChrome<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .preferredColorScheme(.light)
            .pokeAppearanceMode(.light)
            .pokeGameBoyShellStyle(.classic)
    }
}
