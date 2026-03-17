import Foundation

public struct GameSaveMetadata: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let variant: GameVariant
    public let playthroughID: String
    public let playerName: String
    public let locationName: String
    public let badgeCount: Int
    public let playTimeSeconds: Int
    public let savedAt: String

    public init(
        schemaVersion: Int,
        variant: GameVariant,
        playthroughID: String,
        playerName: String,
        locationName: String,
        badgeCount: Int,
        playTimeSeconds: Int,
        savedAt: String
    ) {
        self.schemaVersion = schemaVersion
        self.variant = variant
        self.playthroughID = playthroughID
        self.playerName = playerName
        self.locationName = locationName
        self.badgeCount = badgeCount
        self.playTimeSeconds = playTimeSeconds
        self.savedAt = savedAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case variant
        case playthroughID
        case playerName
        case locationName
        case badgeCount
        case playTimeSeconds
        case savedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        variant = try container.decode(GameVariant.self, forKey: .variant)
        playthroughID = try container.decode(String.self, forKey: .playthroughID)
        playerName = try container.decode(String.self, forKey: .playerName)
        locationName = try container.decode(String.self, forKey: .locationName)
        badgeCount = try container.decode(Int.self, forKey: .badgeCount)
        playTimeSeconds = try container.decode(Int.self, forKey: .playTimeSeconds, default: 0)
        savedAt = try container.decode(String.self, forKey: .savedAt)
    }
}

public struct GameSaveEnvelope: Codable, Equatable, Sendable {
    public let metadata: GameSaveMetadata
    public let snapshot: GameSaveSnapshot

    public init(metadata: GameSaveMetadata, snapshot: GameSaveSnapshot) {
        self.metadata = metadata
        self.snapshot = snapshot
    }
}
