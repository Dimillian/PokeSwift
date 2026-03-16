import Foundation

public struct MapManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let defaultMusicID: String
    public let borderBlockID: Int
    public let blockWidth: Int
    public let blockHeight: Int
    public let stepWidth: Int
    public let stepHeight: Int
    public let tileset: String
    public let blockIDs: [Int]
    public let stepCollisionTileIDs: [Int]
    public let warps: [WarpManifest]
    public let backgroundEvents: [BackgroundEventManifest]
    public let objects: [MapObjectManifest]
    public let connections: [MapConnectionManifest]

    public init(
        id: String,
        displayName: String,
        defaultMusicID: String,
        borderBlockID: Int,
        blockWidth: Int,
        blockHeight: Int,
        stepWidth: Int,
        stepHeight: Int,
        tileset: String,
        blockIDs: [Int],
        stepCollisionTileIDs: [Int],
        warps: [WarpManifest],
        backgroundEvents: [BackgroundEventManifest],
        objects: [MapObjectManifest],
        connections: [MapConnectionManifest] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.defaultMusicID = defaultMusicID
        self.borderBlockID = borderBlockID
        self.blockWidth = blockWidth
        self.blockHeight = blockHeight
        self.stepWidth = stepWidth
        self.stepHeight = stepHeight
        self.tileset = tileset
        self.blockIDs = blockIDs
        self.stepCollisionTileIDs = stepCollisionTileIDs
        self.warps = warps
        self.backgroundEvents = backgroundEvents
        self.objects = objects
        self.connections = connections
    }
}
