import Foundation

public struct BlackoutCheckpointManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let position: TilePoint
    public let facing: FacingDirection

    public init(mapID: String, position: TilePoint, facing: FacingDirection) {
        self.mapID = mapID
        self.position = position
        self.facing = facing
    }
}
