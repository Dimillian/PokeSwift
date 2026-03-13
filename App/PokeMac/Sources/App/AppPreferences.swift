import Observation
import PokeCore
import PokeUI

@MainActor
@Observable
final class AppPreferences {
    var appearanceMode: AppAppearanceMode
    var gameplayHDREnabled: Bool
    var musicEnabled: Bool

    private let settingsStore: AppSettingsStore
    private weak var runtime: GameRuntime?

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        appearanceMode = settingsStore.appearanceMode
        gameplayHDREnabled = settingsStore.gameplayHDREnabled
        musicEnabled = settingsStore.musicEnabled
    }

    func attachRuntime(_ runtime: GameRuntime?) {
        self.runtime = runtime
        runtime?.setMusicEnabled(musicEnabled)
    }

    func cycleAppearanceMode() {
        let nextMode = appearanceMode.nextOptionMode
        appearanceMode = nextMode
        settingsStore.appearanceMode = nextMode
    }

    func toggleGameplayHDREnabled() {
        gameplayHDREnabled.toggle()
        settingsStore.gameplayHDREnabled = gameplayHDREnabled
    }

    func toggleMusicEnabled() {
        let nextValue = musicEnabled == false
        musicEnabled = nextValue
        settingsStore.musicEnabled = nextValue
        runtime?.setMusicEnabled(nextValue)
    }
}
