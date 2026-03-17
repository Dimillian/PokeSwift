import Foundation
import PokeDataModel
import PokeRender
import PokeUI

@MainActor
final class AppSettingsStore {
    private enum Keys {
        static let appearanceMode = "pokemac.appearanceMode"
        static let gameBoyShellStyle = "pokemac.gameBoyShellStyle"
        static let gameplayHDREnabled = "pokemac.gameplayHDREnabled"
        static let musicEnabled = "pokemac.musicEnabled"
        static let textSpeed = "pokemac.textSpeed"
        static let battleAnimation = "pokemac.battleAnimation"
        static let battleStyle = "pokemac.battleStyle"
        static let fieldDisplayStyle = "pokemac.fieldDisplayStyle"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var appearanceMode: AppAppearanceMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.appearanceMode),
                  let appearanceMode = AppAppearanceMode(rawValue: rawValue) else {
                return .system
            }
            return appearanceMode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.appearanceMode)
        }
    }

    var gameplayHDREnabled: Bool {
        get {
            if defaults.object(forKey: Keys.gameplayHDREnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.gameplayHDREnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.gameplayHDREnabled)
        }
    }

    var gameBoyShellStyle: GameBoyShellStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.gameBoyShellStyle),
                  let shellStyle = GameBoyShellStyle(rawValue: rawValue) else {
                return .classic
            }
            return shellStyle
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.gameBoyShellStyle)
        }
    }

    var musicEnabled: Bool {
        get {
            if defaults.object(forKey: Keys.musicEnabled) == nil {
                return true
            }
            return defaults.bool(forKey: Keys.musicEnabled)
        }
        set {
            defaults.set(newValue, forKey: Keys.musicEnabled)
        }
    }

    var textSpeed: TextSpeed {
        get {
            guard let rawValue = defaults.string(forKey: Keys.textSpeed),
                  let value = TextSpeed(rawValue: rawValue) else {
                return .medium
            }
            return value
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.textSpeed)
        }
    }

    var battleAnimation: BattleAnimation {
        get {
            guard let rawValue = defaults.string(forKey: Keys.battleAnimation),
                  let value = BattleAnimation(rawValue: rawValue) else {
                return .on
            }
            return value
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.battleAnimation)
        }
    }

    var battleStyle: BattleStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.battleStyle),
                  let value = BattleStyle(rawValue: rawValue) else {
                return .shift
            }
            return value
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.battleStyle)
        }
    }

    var fieldDisplayStyle: FieldDisplayStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.fieldDisplayStyle),
                  let value = FieldDisplayStyle(preferenceValue: rawValue) else {
                return .defaultGameplayStyle
            }
            return value
        }
        set {
            defaults.set(newValue.preferenceValue, forKey: Keys.fieldDisplayStyle)
        }
    }
}
