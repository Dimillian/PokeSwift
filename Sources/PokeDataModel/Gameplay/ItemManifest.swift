import Foundation

public struct ItemManifest: Codable, Equatable, Sendable {
    public enum BagSection: String, Codable, Equatable, Sendable, CaseIterable {
        case items
        case balls
        case keyItems
        case tmhm
    }

    public struct MedicineAttributes: Codable, Equatable, Sendable {
        public enum HPMode: String, Codable, Equatable, Sendable {
            case none
            case fixed
            case healToFull
            case reviveHalfMax
            case reviveFull
        }

        public enum StatusMode: String, Codable, Equatable, Sendable {
            case none
            case poison
            case burn
            case freeze
            case sleep
            case paralysis
            case all
        }

        public let hpMode: HPMode
        public let hpAmount: Int?
        public let statusMode: StatusMode

        public init(
            hpMode: HPMode = .none,
            hpAmount: Int? = nil,
            statusMode: StatusMode = .none
        ) {
            self.hpMode = hpMode
            self.hpAmount = hpAmount
            self.statusMode = statusMode
        }
    }

    public enum BattleUseKind: String, Codable, Equatable, Sendable {
        case none
        case ball
        case medicine
    }

    public let id: String
    public let displayName: String
    public let price: Int
    public let isKeyItem: Bool
    public let bagSection: BagSection
    public let shortDescription: String?
    public let iconAssetPath: String?
    public let tmhmMoveID: String?
    public let battleUse: BattleUseKind
    public let medicine: MedicineAttributes?

    public init(
        id: String,
        displayName: String,
        price: Int = 0,
        isKeyItem: Bool = false,
        bagSection: BagSection = .items,
        shortDescription: String? = nil,
        iconAssetPath: String? = nil,
        tmhmMoveID: String? = nil,
        battleUse: BattleUseKind = .none,
        medicine: MedicineAttributes? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.price = price
        self.isKeyItem = isKeyItem
        self.bagSection = bagSection
        self.shortDescription = shortDescription
        self.iconAssetPath = iconAssetPath
        self.tmhmMoveID = tmhmMoveID
        self.battleUse = battleUse
        self.medicine = medicine
    }
}
