import Observation
import PokeCore
import PokeDataModel
import PokeRender
import PokeUI

@MainActor
@Observable
final class AppPreferences {
    var appearanceMode: AppAppearanceMode
    var gameBoyShellStyle: GameBoyShellStyle
    var gameplayHDREnabled: Bool
    var musicEnabled: Bool
    var textSpeed: TextSpeed
    var battleAnimation: BattleAnimation
    var battleStyle: BattleStyle
    var fieldDisplayStyle: FieldDisplayStyle

    private let settingsStore: AppSettingsStore
    private weak var runtime: GameRuntime?

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        appearanceMode = settingsStore.appearanceMode
        gameBoyShellStyle = settingsStore.gameBoyShellStyle
        gameplayHDREnabled = settingsStore.gameplayHDREnabled
        musicEnabled = settingsStore.musicEnabled
        textSpeed = settingsStore.textSpeed
        battleAnimation = settingsStore.battleAnimation
        battleStyle = settingsStore.battleStyle
        fieldDisplayStyle = settingsStore.fieldDisplayStyle
    }

    func attachRuntime(_ runtime: GameRuntime?) {
        self.runtime = runtime
        runtime?.setMusicEnabled(musicEnabled)
        runtime?.optionsTextSpeed = textSpeed
        runtime?.optionsBattleAnimation = battleAnimation
        runtime?.optionsBattleStyle = battleStyle
    }

    func cycleAppearanceMode() {
        let nextMode = appearanceMode.nextOptionMode
        appearanceMode = nextMode
        settingsStore.appearanceMode = nextMode
    }

    func setGameBoyShellStyle(_ shellStyle: GameBoyShellStyle) {
        guard gameBoyShellStyle != shellStyle else {
            return
        }

        gameBoyShellStyle = shellStyle
        settingsStore.gameBoyShellStyle = shellStyle
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
        runtime?.optionsTextSpeed = value
    }

    func setBattleAnimation(_ value: BattleAnimation) {
        battleAnimation = value
        settingsStore.battleAnimation = value
        runtime?.optionsBattleAnimation = value
    }

    func setBattleStyle(_ value: BattleStyle) {
        battleStyle = value
        settingsStore.battleStyle = value
        runtime?.optionsBattleStyle = value
    }

    func setFieldDisplayStyle(_ value: FieldDisplayStyle) {
        guard fieldDisplayStyle != value else {
            return
        }

        fieldDisplayStyle = value
        settingsStore.fieldDisplayStyle = value
    }

    func cycleTextSpeed() {
        setTextSpeed(nextOption(after: textSpeed, in: TextSpeed.allCases))
    }

    func cycleBattleAnimation() {
        setBattleAnimation(nextOption(after: battleAnimation, in: BattleAnimation.allCases))
    }

    func cycleBattleStyle() {
        setBattleStyle(nextOption(after: battleStyle, in: BattleStyle.allCases))
    }

    private func nextOption<T: Equatable>(after current: T, in options: [T]) -> T {
        guard let idx = options.firstIndex(of: current) else { return current }
        return options[(idx + 1) % options.count]
    }
}
