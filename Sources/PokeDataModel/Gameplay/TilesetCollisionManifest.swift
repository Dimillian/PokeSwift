import Foundation

public struct TilePairCollisionManifest: Codable, Equatable, Sendable {
    public let fromTileID: Int
    public let toTileID: Int

    public init(fromTileID: Int, toTileID: Int) {
        self.fromTileID = fromTileID
        self.toTileID = toTileID
    }
}

public struct LedgeCollisionManifest: Codable, Equatable, Sendable {
    public let facing: FacingDirection
    public let standingTileID: Int
    public let ledgeTileID: Int

    public init(facing: FacingDirection, standingTileID: Int, ledgeTileID: Int) {
        self.facing = facing
        self.standingTileID = standingTileID
        self.ledgeTileID = ledgeTileID
    }
}

public struct TilesetCollisionManifest: Codable, Equatable, Sendable {
    public let passableTileIDs: [Int]
    public let warpTileIDs: [Int]
    public let doorTileIDs: [Int]
    public let grassTileID: Int?
    public let tilePairCollisions: [TilePairCollisionManifest]
    public let ledges: [LedgeCollisionManifest]

    public init(
        passableTileIDs: [Int],
        warpTileIDs: [Int],
        doorTileIDs: [Int],
        grassTileID: Int? = nil,
        tilePairCollisions: [TilePairCollisionManifest],
        ledges: [LedgeCollisionManifest]
    ) {
        self.passableTileIDs = passableTileIDs
        self.warpTileIDs = warpTileIDs
        self.doorTileIDs = doorTileIDs
        self.grassTileID = grassTileID
        self.tilePairCollisions = tilePairCollisions
        self.ledges = ledges
    }
}
