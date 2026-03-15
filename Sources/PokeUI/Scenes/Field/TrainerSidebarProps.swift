import Foundation
import PokeDataModel

public struct TrainerPortraitProps: Equatable, Sendable {
    public let label: String
    public let spriteURL: URL?
    public let spriteFrame: PixelRect?

    public init(label: String, spriteURL: URL?, spriteFrame: PixelRect?) {
        self.label = label
        self.spriteURL = spriteURL
        self.spriteFrame = spriteFrame
    }
}

public struct TrainerBadgeProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let shortLabel: String
    public let isEarned: Bool

    public init(id: String, shortLabel: String, isEarned: Bool) {
        self.id = id
        self.shortLabel = shortLabel
        self.isEarned = isEarned
    }
}

public struct TrainerProfileProps: Equatable, Sendable {
    public let trainerName: String
    public let locationName: String
    public let portrait: TrainerPortraitProps
    public let badges: [TrainerBadgeProps]
    public let badgeSummaryText: String
    public let moneyText: String
    public let statusItems: [String]

    public init(
        trainerName: String,
        locationName: String,
        portrait: TrainerPortraitProps,
        badges: [TrainerBadgeProps],
        badgeSummaryText: String,
        moneyText: String,
        statusItems: [String]
    ) {
        self.trainerName = trainerName
        self.locationName = locationName
        self.portrait = portrait
        self.badges = badges
        self.badgeSummaryText = badgeSummaryText
        self.moneyText = moneyText
        self.statusItems = statusItems
    }
}
