import Foundation

public struct TilesetManifest: Codable, Equatable, Sendable {
    public let id: String
    public let imagePath: String
    public let blocksetPath: String
    public let sourceTileSize: Int
    public let blockTileWidth: Int
    public let blockTileHeight: Int
    public let collision: TilesetCollisionManifest
    public let animation: TilesetAnimationManifest

    public init(
        id: String,
        imagePath: String,
        blocksetPath: String,
        sourceTileSize: Int,
        blockTileWidth: Int,
        blockTileHeight: Int,
        collision: TilesetCollisionManifest,
        animation: TilesetAnimationManifest = .none
    ) {
        self.id = id
        self.imagePath = imagePath
        self.blocksetPath = blocksetPath
        self.sourceTileSize = sourceTileSize
        self.blockTileWidth = blockTileWidth
        self.blockTileHeight = blockTileHeight
        self.collision = collision
        self.animation = animation
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case imagePath
        case blocksetPath
        case sourceTileSize
        case blockTileWidth
        case blockTileHeight
        case collision
        case animation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imagePath = try container.decode(String.self, forKey: .imagePath)
        blocksetPath = try container.decode(String.self, forKey: .blocksetPath)
        sourceTileSize = try container.decode(Int.self, forKey: .sourceTileSize)
        blockTileWidth = try container.decode(Int.self, forKey: .blockTileWidth)
        blockTileHeight = try container.decode(Int.self, forKey: .blockTileHeight)
        collision = try container.decode(TilesetCollisionManifest.self, forKey: .collision)
        animation = try container.decodeIfPresent(TilesetAnimationManifest.self, forKey: .animation) ?? .none
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imagePath, forKey: .imagePath)
        try container.encode(blocksetPath, forKey: .blocksetPath)
        try container.encode(sourceTileSize, forKey: .sourceTileSize)
        try container.encode(blockTileWidth, forKey: .blockTileWidth)
        try container.encode(blockTileHeight, forKey: .blockTileHeight)
        try container.encode(collision, forKey: .collision)
        try container.encode(animation, forKey: .animation)
    }
}
