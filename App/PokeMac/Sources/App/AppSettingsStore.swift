import Foundation
import PokeUI

@MainActor
final class AppSettingsStore {
    private enum Keys {
        static let appearanceMode = "pokemac.appearanceMode"
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
}
