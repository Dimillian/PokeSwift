import Observation
import SwiftUI
import PokeCore
import PokeUI

struct RootView: View {
    private static let windowSize = CGSize(width: 1150, height: 800)
    @Environment(AppPreferences.self) private var preferences
    @Bindable var coordinator: AppCoordinator
    private let lightPalette = PokeThemePalette.lightPalette

    var body: some View {
        Group {
            if let bootError = coordinator.bootError {
                ContentUnavailableView(
                    "Boot Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(bootError)
                )
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
            } else if let runtime = coordinator.runtime {
                RuntimeSceneRouter(runtime: runtime)
            } else {
                GameBoyScreen {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Bootstrapping PokeMac")
                            .font(.headline)
                    }
                    .foregroundStyle(lightPalette.primaryText.color)
                }
                .preferredColorScheme(.light)
                .pokeAppearanceMode(.light)
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
}
