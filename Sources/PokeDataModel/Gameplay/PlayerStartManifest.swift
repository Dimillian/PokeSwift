import Foundation

public struct PlayerStartManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let playerName: String
    public let rivalName: String
    public let initialFlags: [String]
    public let defaultBlackoutCheckpoint: BlackoutCheckpointManifest?

    public init(
        mapID: String,
        position: TilePoint,
        facing: FacingDirection,
        playerName: String,
        rivalName: String,
        initialFlags: [String],
        defaultBlackoutCheckpoint: BlackoutCheckpointManifest? = nil
    ) {
        self.mapID = mapID
        self.position = position
        self.facing = facing
        self.playerName = playerName
        self.rivalName = rivalName
        self.initialFlags = initialFlags
        self.defaultBlackoutCheckpoint = defaultBlackoutCheckpoint
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case position
        case facing
        case playerName
        case rivalName
        case initialFlags
        case defaultBlackoutCheckpoint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        position = try container.decode(TilePoint.self, forKey: .position)
        facing = try container.decode(FacingDirection.self, forKey: .facing)
        playerName = try container.decode(String.self, forKey: .playerName)
        rivalName = try container.decode(String.self, forKey: .rivalName)
        initialFlags = try container.decode([String].self, forKey: .initialFlags)
        defaultBlackoutCheckpoint = try container.decodeIfPresent(
            BlackoutCheckpointManifest.self,
            forKey: .defaultBlackoutCheckpoint
        )
    }
}
