import Foundation

public enum TilesetAnimationKind: String, Codable, Equatable, Sendable {
    case none
    case water
    case waterFlower
}

public struct TilesetAnimatedTileManifest: Codable, Equatable, Sendable {
    public let tileID: Int
    public let frameImagePaths: [String]

    public init(tileID: Int, frameImagePaths: [String] = []) {
        self.tileID = tileID
        self.frameImagePaths = frameImagePaths
    }
}

public struct TilesetAnimationManifest: Codable, Equatable, Sendable {
    public let kind: TilesetAnimationKind
    public let animatedTiles: [TilesetAnimatedTileManifest]

    public init(kind: TilesetAnimationKind, animatedTiles: [TilesetAnimatedTileManifest] = []) {
        self.kind = kind
        self.animatedTiles = animatedTiles
    }

    public static let none = TilesetAnimationManifest(kind: .none)
}
