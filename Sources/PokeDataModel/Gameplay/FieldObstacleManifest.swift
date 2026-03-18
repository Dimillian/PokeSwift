import Foundation

public enum FieldObstacleKind: String, Codable, Equatable, Sendable {
    case cutTree
}

public struct FieldObstacleManifest: Codable, Equatable, Sendable {
    public let id: String
    public let kind: FieldObstacleKind
    public let blockPosition: TilePoint
    public let triggerStepOffset: TilePoint
    public let requiredMoveID: String
    public let requiredBadgeID: String
    public let replacementBlockID: Int
    public let replacementStepCollisionTileIDs: [Int]

    public init(
        id: String,
        kind: FieldObstacleKind,
        blockPosition: TilePoint,
        triggerStepOffset: TilePoint,
        requiredMoveID: String,
        requiredBadgeID: String,
        replacementBlockID: Int,
        replacementStepCollisionTileIDs: [Int]
    ) {
        self.id = id
        self.kind = kind
        self.blockPosition = blockPosition
        self.triggerStepOffset = triggerStepOffset
        self.requiredMoveID = requiredMoveID
        self.requiredBadgeID = requiredBadgeID
        self.replacementBlockID = replacementBlockID
        self.replacementStepCollisionTileIDs = replacementStepCollisionTileIDs
    }
}
