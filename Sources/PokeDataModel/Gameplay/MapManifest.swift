import Foundation

public struct MapManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let defaultMusicID: String
    public let fieldPaletteID: String?
    public let borderBlockID: Int
    public let blockWidth: Int
    public let blockHeight: Int
    public let stepWidth: Int
    public let stepHeight: Int
    public let tileset: String
    public let blockIDs: [Int]
    public let stepCollisionTileIDs: [Int]
    public let warps: [WarpManifest]
    public let fieldObstacles: [FieldObstacleManifest]
    public let backgroundEvents: [BackgroundEventManifest]
    public let objects: [MapObjectManifest]
    public let connections: [MapConnectionManifest]

    public init(
        id: String,
        displayName: String,
        defaultMusicID: String,
        fieldPaletteID: String? = nil,
        borderBlockID: Int,
        blockWidth: Int,
        blockHeight: Int,
        stepWidth: Int,
        stepHeight: Int,
        tileset: String,
        blockIDs: [Int],
        stepCollisionTileIDs: [Int],
        warps: [WarpManifest],
        fieldObstacles: [FieldObstacleManifest] = [],
        backgroundEvents: [BackgroundEventManifest],
        objects: [MapObjectManifest],
        connections: [MapConnectionManifest] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.defaultMusicID = defaultMusicID
        self.fieldPaletteID = fieldPaletteID
        self.borderBlockID = borderBlockID
        self.blockWidth = blockWidth
        self.blockHeight = blockHeight
        self.stepWidth = stepWidth
        self.stepHeight = stepHeight
        self.tileset = tileset
        self.blockIDs = blockIDs
        self.stepCollisionTileIDs = stepCollisionTileIDs
        self.warps = warps
        self.fieldObstacles = fieldObstacles
        self.backgroundEvents = backgroundEvents
        self.objects = objects
        self.connections = connections
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case defaultMusicID
        case fieldPaletteID
        case borderBlockID
        case blockWidth
        case blockHeight
        case stepWidth
        case stepHeight
        case tileset
        case blockIDs
        case stepCollisionTileIDs
        case warps
        case fieldObstacles
        case backgroundEvents
        case objects
        case connections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        defaultMusicID = try container.decode(String.self, forKey: .defaultMusicID)
        fieldPaletteID = try container.decodeIfPresent(String.self, forKey: .fieldPaletteID)
        borderBlockID = try container.decode(Int.self, forKey: .borderBlockID)
        blockWidth = try container.decode(Int.self, forKey: .blockWidth)
        blockHeight = try container.decode(Int.self, forKey: .blockHeight)
        stepWidth = try container.decode(Int.self, forKey: .stepWidth)
        stepHeight = try container.decode(Int.self, forKey: .stepHeight)
        tileset = try container.decode(String.self, forKey: .tileset)
        blockIDs = try container.decode([Int].self, forKey: .blockIDs)
        stepCollisionTileIDs = try container.decode([Int].self, forKey: .stepCollisionTileIDs)
        warps = try container.decode([WarpManifest].self, forKey: .warps)
        fieldObstacles = try container.decodeIfPresent([FieldObstacleManifest].self, forKey: .fieldObstacles) ?? []
        backgroundEvents = try container.decode([BackgroundEventManifest].self, forKey: .backgroundEvents)
        objects = try container.decode([MapObjectManifest].self, forKey: .objects)
        connections = try container.decodeIfPresent([MapConnectionManifest].self, forKey: .connections) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(defaultMusicID, forKey: .defaultMusicID)
        try container.encodeIfPresent(fieldPaletteID, forKey: .fieldPaletteID)
        try container.encode(borderBlockID, forKey: .borderBlockID)
        try container.encode(blockWidth, forKey: .blockWidth)
        try container.encode(blockHeight, forKey: .blockHeight)
        try container.encode(stepWidth, forKey: .stepWidth)
        try container.encode(stepHeight, forKey: .stepHeight)
        try container.encode(tileset, forKey: .tileset)
        try container.encode(blockIDs, forKey: .blockIDs)
        try container.encode(stepCollisionTileIDs, forKey: .stepCollisionTileIDs)
        try container.encode(warps, forKey: .warps)
        try container.encode(fieldObstacles, forKey: .fieldObstacles)
        try container.encode(backgroundEvents, forKey: .backgroundEvents)
        try container.encode(objects, forKey: .objects)
        try container.encode(connections, forKey: .connections)
    }
}
