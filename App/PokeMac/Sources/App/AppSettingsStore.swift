import Foundation
import PokeDataModel
import PokeUI

@MainActor
final class AppSettingsStore {
    private enum Keys {
        static let appearanceMode = "pokemac.appearanceMode"
        static let gameplayHDREnabled = "pokemac.gameplayHDREnabled"
        static let musicEnabled = "pokemac.musicEnabled"
        static let textSpeed = "pokemac.textSpeed"
        static let battleAnimation = "pokemac.battleAnimation"
        static let battleStyle = "pokemac.battleStyle"
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
}
