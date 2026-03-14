import Observation
import PokeCore
import PokeDataModel
import PokeUI

@MainActor
@Observable
final class AppPreferences {
    var appearanceMode: AppAppearanceMode
    var gameplayHDREnabled: Bool
    var musicEnabled: Bool
    var textSpeed: TextSpeed
    var battleAnimation: BattleAnimation
    var battleStyle: BattleStyle

    private let settingsStore: AppSettingsStore
    private weak var runtime: GameRuntime?

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        appearanceMode = settingsStore.appearanceMode
        gameplayHDREnabled = settingsStore.gameplayHDREnabled
        musicEnabled = settingsStore.musicEnabled
        textSpeed = settingsStore.textSpeed
        battleAnimation = settingsStore.battleAnimation
        battleStyle = settingsStore.battleStyle
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

    func setTextSpeed(_ value: TextSpeed) {
        textSpeed = value
        settingsStore.textSpeed = value
    }

    func setBattleAnimation(_ value: BattleAnimation) {
        battleAnimation = value
        settingsStore.battleAnimation = value
    }

    func setBattleStyle(_ value: BattleStyle) {
        battleStyle = value
        settingsStore.battleStyle = value
    }
}
