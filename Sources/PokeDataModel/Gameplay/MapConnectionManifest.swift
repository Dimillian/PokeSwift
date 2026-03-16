import Foundation

public enum MapConnectionDirection: String, Codable, Equatable, Sendable, CaseIterable {
    case north
    case south
    case west
    case east
}

public struct MapConnectionManifest: Codable, Equatable, Sendable {
    public let direction: MapConnectionDirection
    public let targetMapID: String
    public let offset: Int
    public let targetBlockWidth: Int
    public let targetBlockHeight: Int
    public let targetBlockIDs: [Int]

    public init(
        direction: MapConnectionDirection,
        targetMapID: String,
        offset: Int,
        targetBlockWidth: Int,
        targetBlockHeight: Int,
        targetBlockIDs: [Int]
    ) {
        self.direction = direction
        self.targetMapID = targetMapID
        self.offset = offset
        self.targetBlockWidth = targetBlockWidth
        self.targetBlockHeight = targetBlockHeight
        self.targetBlockIDs = targetBlockIDs
    }
}
