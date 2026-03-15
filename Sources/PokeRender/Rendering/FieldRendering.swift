import Foundation
import SwiftUI
import CoreGraphics
import ImageIO
import PokeDataModel

public enum FieldDisplayStyle: Equatable, Hashable, Sendable {
    case rawGrayscale
    case dmgAuthentic
    case dmgTinted

    public static let defaultGameplayStyle: FieldDisplayStyle = .dmgTinted

    public var sidebarSummaryLabel: String {
        switch self {
        case .rawGrayscale:
            return "RAW"
        case .dmgAuthentic:
            return "DMG"
        case .dmgTinted:
            return "TINTED"
        }
    }

    public var sidebarOptionTitle: String {
        switch self {
        case .rawGrayscale:
            return "Raw Gray"
        case .dmgAuthentic:
            return "Authentic DMG"
        case .dmgTinted:
            return "Tinted"
        }
    }
}

@available(*, deprecated, renamed: "FieldDisplayStyle")
public typealias FieldRenderStyle = FieldDisplayStyle

public struct FieldSpriteFrame: Equatable, Sendable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
    public let flippedHorizontally: Bool

    public init(x: Int, y: Int, width: Int, height: Int, flippedHorizontally: Bool = false) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.flippedHorizontally = flippedHorizontally
    }
}

public struct FieldSpriteDefinition: Equatable, Sendable {
    public let id: String
    public let imageURL: URL
    public let frameWidth: Int
    public let frameHeight: Int
    public let facingFrames: [FacingDirection: FieldSpriteFrame]
    public let walkingFrames: [FacingDirection: FieldSpriteFrame]?

    public init(
        id: String,
        imageURL: URL,
        frameWidth: Int = 16,
        frameHeight: Int = 16,
        facingFrames: [FacingDirection: FieldSpriteFrame],
        walkingFrames: [FacingDirection: FieldSpriteFrame]? = nil
    ) {
        self.id = id
        self.imageURL = imageURL
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.facingFrames = facingFrames
        self.walkingFrames = walkingFrames
    }

    public func frame(for facing: FacingDirection, isWalking: Bool = false) -> FieldSpriteFrame? {
        if isWalking, let walkingFrame = walkingFrames?[facing] {
            return walkingFrame
        }
        return facingFrames[facing]
    }
}

public struct FieldTilesetDefinition: Equatable, Sendable {
    public let id: String
    public let imageURL: URL
    public let blocksetURL: URL
    public let sourceTileSize: Int
    public let blockTileWidth: Int
    public let blockTileHeight: Int

    public init(
        id: String,
        imageURL: URL,
        blocksetURL: URL,
        sourceTileSize: Int = 8,
        blockTileWidth: Int = 4,
        blockTileHeight: Int = 4
    ) {
        self.id = id
        self.imageURL = imageURL
        self.blocksetURL = blocksetURL
        self.sourceTileSize = sourceTileSize
        self.blockTileWidth = blockTileWidth
        self.blockTileHeight = blockTileHeight
    }
}

public struct FieldRenderAssets: Equatable, Sendable {
    public let tileset: FieldTilesetDefinition
    public let overworldSprites: [String: FieldSpriteDefinition]

    public init(tileset: FieldTilesetDefinition, overworldSprites: [String: FieldSpriteDefinition]) {
        self.tileset = tileset
        self.overworldSprites = overworldSprites
    }

    public func spriteDefinition(for spriteID: String) -> FieldSpriteDefinition? {
        overworldSprites[spriteID]
    }
}

enum FieldRendererError: Error, Equatable {
    case invalidTilesetImage(URL)
    case invalidSpriteImage(URL)
    case invalidBlocksetLength(Int)
    case invalidBlockIndex(Int)
    case invalidTileIndex(Int)
    case cropFailed
    case maskCreationFailed
    case bitmapContextCreationFailed
}

struct FieldBlockset: Equatable {
    let blocks: [[UInt8]]
    let blockTileWidth: Int
    let blockTileHeight: Int

    static func decode(
        data: Data,
        blockTileWidth: Int = 4,
        blockTileHeight: Int = 4
    ) throws -> FieldBlockset {
        let tilesPerBlock = blockTileWidth * blockTileHeight
        guard data.count.isMultiple(of: tilesPerBlock) else {
            throw FieldRendererError.invalidBlocksetLength(data.count)
        }

        let bytes = [UInt8](data)
        let blocks = stride(from: 0, to: bytes.count, by: tilesPerBlock).map { start in
            Array(bytes[start..<(start + tilesPerBlock)])
        }

        return FieldBlockset(blocks: blocks, blockTileWidth: blockTileWidth, blockTileHeight: blockTileHeight)
    }
}

public struct FieldPixelPoint: Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct FieldPixelSize: Equatable, Hashable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct FieldSceneMetrics: Equatable, Hashable, Sendable {
    public let mapPixelSize: FieldPixelSize
    public let paddingPixels: FieldPixelSize
    public let contentPixelSize: FieldPixelSize

    public init(
        mapPixelSize: FieldPixelSize,
        paddingPixels: FieldPixelSize,
        contentPixelSize: FieldPixelSize
    ) {
        self.mapPixelSize = mapPixelSize
        self.paddingPixels = paddingPixels
        self.contentPixelSize = contentPixelSize
    }
}

public struct FieldCameraState: Equatable, Hashable, Sendable {
    public let origin: FieldPixelPoint
    public let viewportSize: FieldPixelSize

    public init(origin: FieldPixelPoint, viewportSize: FieldPixelSize = FieldSceneRenderer.viewportPixelSize) {
        self.origin = origin
        self.viewportSize = viewportSize
    }

    public static func target(
        playerWorldPosition: FieldPixelPoint,
        contentPixelSize: FieldPixelSize,
        viewportSize: FieldPixelSize = FieldSceneRenderer.viewportPixelSize
    ) -> FieldCameraState {
        let desiredX = playerWorldPosition.x + (FieldSceneRenderer.stepPixelSize / 2) - (viewportSize.width / 2)
        let desiredY = playerWorldPosition.y + (FieldSceneRenderer.stepPixelSize / 2) - (viewportSize.height / 2)
        let maxX = max(0, contentPixelSize.width - viewportSize.width)
        let maxY = max(0, contentPixelSize.height - viewportSize.height)

        return FieldCameraState(
            origin: .init(
                x: max(0, min(maxX, desiredX)),
                y: max(0, min(maxY, desiredY))
            ),
            viewportSize: viewportSize
        )
    }
}

public enum FieldRenderedActorRole: Sendable {
    case player
    case object
}

public struct FieldRenderedActor: Identifiable, @unchecked Sendable {
    public let id: String
    public let role: FieldRenderedActorRole
    public let image: CGImage
    public let walkingImage: CGImage?
    public let worldPosition: FieldPixelPoint
    public let size: FieldPixelSize
    public let flippedHorizontally: Bool

    public init(
        id: String,
        role: FieldRenderedActorRole,
        image: CGImage,
        walkingImage: CGImage?,
        worldPosition: FieldPixelPoint,
        size: FieldPixelSize,
        flippedHorizontally: Bool
    ) {
        self.id = id
        self.role = role
        self.image = image
        self.walkingImage = walkingImage
        self.worldPosition = worldPosition
        self.size = size
        self.flippedHorizontally = flippedHorizontally
    }
}

public struct FieldRenderedScene: @unchecked Sendable {
    public let mapID: String
    public let metrics: FieldSceneMetrics
    public let backgroundImage: CGImage
    public let actors: [FieldRenderedActor]

    public init(
        mapID: String,
        metrics: FieldSceneMetrics,
        backgroundImage: CGImage,
        actors: [FieldRenderedActor]
    ) {
        self.mapID = mapID
        self.metrics = metrics
        self.backgroundImage = backgroundImage
        self.actors = actors
    }
}

struct FieldRenderSignature: Hashable, Sendable {
    struct ObjectSignature: Hashable, Sendable {
        let spriteID: String
        let position: TilePoint
        let facingRawValue: String

        init(object: FieldRenderableObjectState) {
            spriteID = object.sprite
            position = object.position
            facingRawValue = object.facing.rawValue
        }
    }

    struct AssetSignature: Hashable, Sendable {
        struct SpriteSignature: Hashable, Sendable {
            struct FrameSignature: Hashable, Sendable {
                let directionRawValue: String
                let x: Int
                let y: Int
                let width: Int
                let height: Int
                let flippedHorizontally: Bool

                init(direction: FacingDirection, frame: FieldSpriteFrame) {
                    directionRawValue = direction.rawValue
                    x = frame.x
                    y = frame.y
                    width = frame.width
                    height = frame.height
                    flippedHorizontally = frame.flippedHorizontally
                }
            }

            let id: String
            let imagePath: String
            let frameWidth: Int
            let frameHeight: Int
            let frames: [FrameSignature]
            let walkingFrames: [FrameSignature]

            init(definition: FieldSpriteDefinition) {
                id = definition.id
                imagePath = definition.imageURL.standardizedFileURL.path
                frameWidth = definition.frameWidth
                frameHeight = definition.frameHeight
                frames = FacingDirection.allCases.compactMap { direction in
                    guard let frame = definition.frame(for: direction, isWalking: false) else { return nil }
                    return FrameSignature(direction: direction, frame: frame)
                }
                walkingFrames = FacingDirection.allCases.compactMap { direction in
                    guard let frame = definition.frame(for: direction, isWalking: true),
                          frame != definition.frame(for: direction, isWalking: false) else {
                        return nil
                    }
                    return FrameSignature(direction: direction, frame: frame)
                }
            }
        }

        let tilesetID: String
        let tilesetImagePath: String
        let blocksetPath: String
        let sourceTileSize: Int
        let blockTileWidth: Int
        let blockTileHeight: Int
        let spriteAssets: [SpriteSignature]

        init(assets: FieldRenderAssets) {
            tilesetID = assets.tileset.id
            tilesetImagePath = assets.tileset.imageURL.standardizedFileURL.path
            blocksetPath = assets.tileset.blocksetURL.standardizedFileURL.path
            sourceTileSize = assets.tileset.sourceTileSize
            blockTileWidth = assets.tileset.blockTileWidth
            blockTileHeight = assets.tileset.blockTileHeight
            spriteAssets = assets.overworldSprites.values
                .sorted { $0.id < $1.id }
                .map(SpriteSignature.init(definition:))
        }
    }

    let mapID: String
    let tilesetID: String
    let blockWidth: Int
    let blockHeight: Int
    let blockIDs: [Int]
    let playerPosition: TilePoint
    let playerFacingRawValue: String
    let playerSpriteID: String
    let objectStates: [ObjectSignature]
    let assetSignature: AssetSignature

    init(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldRenderableObjectState],
        assets: FieldRenderAssets
    ) {
        mapID = map.id
        tilesetID = map.tileset
        blockWidth = map.blockWidth
        blockHeight = map.blockHeight
        blockIDs = map.blockIDs
        self.playerPosition = playerPosition
        playerFacingRawValue = playerFacing.rawValue
        self.playerSpriteID = playerSpriteID
        objectStates = objects.map(ObjectSignature.init(object:))
        assetSignature = AssetSignature(assets: assets)
    }
}

public struct FieldSceneRenderIdentity: Equatable {
    public struct ObjectVisualSignature: Equatable {
        public let id: String
        public let spriteID: String
        public let facingRawValue: String

        public init(object: FieldRenderableObjectState) {
            id = object.id
            spriteID = object.sprite
            facingRawValue = object.facing.rawValue
        }
    }

    public let map: MapManifest
    public let playerFacing: FacingDirection
    public let playerSpriteID: String
    public let objectVisuals: [ObjectVisualSignature]
    public let assets: FieldRenderAssets

    public init(
        map: MapManifest,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldRenderableObjectState],
        assets: FieldRenderAssets
    ) {
        self.map = map
        self.playerFacing = playerFacing
        self.playerSpriteID = playerSpriteID
        objectVisuals = objects
            .map(ObjectVisualSignature.init(object:))
            .sorted { lhs, rhs in lhs.id < rhs.id }
        self.assets = assets
    }
}

private struct FieldBackgroundSignature: Hashable, Sendable {
    let mapID: String
    let blockWidth: Int
    let blockHeight: Int
    let borderBlockID: Int
    let blockIDs: [Int]
    let tilesetID: String
    let tilesetImagePath: String
    let blocksetPath: String
    let blockTileWidth: Int
    let blockTileHeight: Int
    let sourceTileSize: Int
    let paddingBlocks: FieldPixelSize

    init(map: MapManifest, assets: FieldRenderAssets, paddingBlocks: FieldPixelSize) {
        mapID = map.id
        blockWidth = map.blockWidth
        blockHeight = map.blockHeight
        borderBlockID = map.borderBlockID
        blockIDs = map.blockIDs
        tilesetID = assets.tileset.id
        tilesetImagePath = assets.tileset.imageURL.standardizedFileURL.path
        blocksetPath = assets.tileset.blocksetURL.standardizedFileURL.path
        blockTileWidth = assets.tileset.blockTileWidth
        blockTileHeight = assets.tileset.blockTileHeight
        sourceTileSize = assets.tileset.sourceTileSize
        self.paddingBlocks = paddingBlocks
    }
}

private struct PreparedTileAtlas {
    let tiles: [CGImage]

    init(image: CGImage, tileSize: Int) throws {
        let atlas = FieldSceneRenderer.TileAtlas(image: image, tileSize: tileSize)
        tiles = try (0..<(atlas.columns * atlas.rows)).map { index in
            try atlas.tile(at: index)
        }
    }

    func tile(at index: Int) throws -> CGImage {
        guard tiles.indices.contains(index) else {
            throw FieldRendererError.invalidTileIndex(index)
        }
        return tiles[index]
    }
}

private final class FieldRendererCaches: @unchecked Sendable {
    private struct BlocksetCacheKey: Hashable {
        let path: String
        let blockTileWidth: Int
        let blockTileHeight: Int
    }

    private struct AtlasCacheKey: Hashable {
        let imagePath: String
        let tileSize: Int
    }

    private struct SpriteFrameCacheKey: Hashable {
        let imagePath: String
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    static let shared = FieldRendererCaches()

    private let lock = NSLock()
    private let maxRenderedImages = 24
    private var decodedImages: [String: CGImage] = [:]
    private var blocksets: [BlocksetCacheKey: FieldBlockset] = [:]
    private var preparedAtlases: [AtlasCacheKey: PreparedTileAtlas] = [:]
    private var preparedSprites: [SpriteFrameCacheKey: CGImage] = [:]
    private var backgroundImages: [FieldBackgroundSignature: CGImage] = [:]
    private var renderedImages: [FieldRenderSignature: CGImage] = [:]
    private var renderedImageOrder: [FieldRenderSignature] = []

    private init() {}

    func renderedImage(for signature: FieldRenderSignature) -> CGImage? {
        withLock {
            renderedImages[signature]
        }
    }

    func storeRenderedImage(_ image: CGImage, for signature: FieldRenderSignature) {
        withLock {
            renderedImages[signature] = image
            renderedImageOrder.removeAll { $0 == signature }
            renderedImageOrder.append(signature)

            while renderedImageOrder.count > maxRenderedImages {
                let evictedSignature = renderedImageOrder.removeFirst()
                renderedImages.removeValue(forKey: evictedSignature)
            }
        }
    }

    func backgroundImage(for signature: FieldBackgroundSignature) -> CGImage? {
        withLock {
            backgroundImages[signature]
        }
    }

    func storeBackgroundImage(_ image: CGImage, for signature: FieldBackgroundSignature) {
        withLock {
            backgroundImages[signature] = image
        }
    }

    func image(at url: URL, invalidError: FieldRendererError) throws -> CGImage {
        let imagePath = url.standardizedFileURL.path
        if let cached = withLock({ decodedImages[imagePath] }) {
            return cached
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw invalidError
        }

        withLock {
            decodedImages[imagePath] = image
        }
        return image
    }

    func blockset(for tileset: FieldTilesetDefinition) throws -> FieldBlockset {
        let key = BlocksetCacheKey(
            path: tileset.blocksetURL.standardizedFileURL.path,
            blockTileWidth: tileset.blockTileWidth,
            blockTileHeight: tileset.blockTileHeight
        )
        if let cached = withLock({ blocksets[key] }) {
            return cached
        }

        let blocksetData = try Data(contentsOf: tileset.blocksetURL)
        let blockset = try FieldBlockset.decode(
            data: blocksetData,
            blockTileWidth: tileset.blockTileWidth,
            blockTileHeight: tileset.blockTileHeight
        )
        withLock {
            blocksets[key] = blockset
        }
        return blockset
    }

    func preparedAtlas(for tileset: FieldTilesetDefinition) throws -> PreparedTileAtlas {
        let key = AtlasCacheKey(
            imagePath: tileset.imageURL.standardizedFileURL.path,
            tileSize: tileset.sourceTileSize
        )
        if let cached = withLock({ preparedAtlases[key] }) {
            return cached
        }

        let image = try self.image(at: tileset.imageURL, invalidError: .invalidTilesetImage(tileset.imageURL))
        let atlas = try PreparedTileAtlas(image: image, tileSize: tileset.sourceTileSize)
        withLock {
            preparedAtlases[key] = atlas
        }
        return atlas
    }

    func preparedSpriteImage(
        definition: FieldSpriteDefinition,
        facing: FacingDirection,
        isWalking: Bool = false
    ) throws -> CGImage? {
        guard let frame = definition.frame(for: facing, isWalking: isWalking) else {
            return nil
        }

        let key = SpriteFrameCacheKey(
            imagePath: definition.imageURL.standardizedFileURL.path,
            x: frame.x,
            y: frame.y,
            width: frame.width,
            height: frame.height
        )
        if let cached = withLock({ preparedSprites[key] }) {
            return cached
        }

        let sourceImage = try image(at: definition.imageURL, invalidError: .invalidSpriteImage(definition.imageURL))
        let preparedImage = try FieldSceneRenderer.prepareSpriteImageForFieldContext(
            FieldSceneRenderer.crop(sourceImage, topLeftFrame: frame)
        )
        withLock {
            preparedSprites[key] = preparedImage
        }
        return preparedImage
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

public struct FieldSceneRenderer {
    public static let tilePixelSize = 8
    public static let blockTileWidth = 4
    public static let blockTileHeight = 4
    public static let stepPixelSize = 16
    public static let blockPixelSize = tilePixelSize * blockTileWidth
    public static let viewportPixelSize = FieldPixelSize(width: 160, height: 144)

    public static func sceneMetrics(for map: MapManifest) -> FieldSceneMetrics {
        let paddingBlocks = FieldPixelSize(
            width: max(1, Int(ceil(Double(viewportPixelSize.width) / Double(blockPixelSize)))),
            height: max(1, Int(ceil(Double(viewportPixelSize.height) / Double(blockPixelSize))))
        )
        let paddingPixels = FieldPixelSize(
            width: paddingBlocks.width * blockPixelSize,
            height: paddingBlocks.height * blockPixelSize
        )
        let mapPixelSize = FieldPixelSize(
            width: max(1, map.blockWidth) * blockPixelSize,
            height: max(1, map.blockHeight) * blockPixelSize
        )
        let contentPixelSize = FieldPixelSize(
            width: mapPixelSize.width + (paddingPixels.width * 2),
            height: mapPixelSize.height + (paddingPixels.height * 2)
        )

        return FieldSceneMetrics(
            mapPixelSize: mapPixelSize,
            paddingPixels: paddingPixels,
            contentPixelSize: contentPixelSize
        )
    }

    public static func playerWorldPosition(for position: TilePoint, metrics: FieldSceneMetrics) -> FieldPixelPoint {
        FieldPixelPoint(
            x: (position.x * stepPixelSize) + metrics.paddingPixels.width,
            y: (position.y * stepPixelSize) + metrics.paddingPixels.height
        )
    }

    public static func renderScene(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldRenderableObjectState],
        assets: FieldRenderAssets
    ) throws -> FieldRenderedScene {
        let atlas = try FieldRendererCaches.shared.preparedAtlas(for: assets.tileset)
        let blockset = try FieldRendererCaches.shared.blockset(for: assets.tileset)
        let metrics = sceneMetrics(for: map)
        let paddingBlocks = FieldPixelSize(
            width: metrics.paddingPixels.width / blockPixelSize,
            height: metrics.paddingPixels.height / blockPixelSize
        )
        let backgroundSignature = FieldBackgroundSignature(
            map: map,
            assets: assets,
            paddingBlocks: paddingBlocks
        )
        let backgroundImage: CGImage
        if let cachedBackground = FieldRendererCaches.shared.backgroundImage(for: backgroundSignature) {
            backgroundImage = cachedBackground
        } else {
            backgroundImage = try renderBackground(
                map: map,
                atlas: atlas,
                blockset: blockset,
                metrics: metrics
            )
            FieldRendererCaches.shared.storeBackgroundImage(backgroundImage, for: backgroundSignature)
        }

        let actors = try renderedActors(
            objects: objects,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            assets: assets,
            metrics: metrics
        )

        return FieldRenderedScene(
            mapID: map.id,
            metrics: metrics,
            backgroundImage: backgroundImage,
            actors: sortedActorsForPresentation(actors)
        )
    }

    public static func render(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldRenderableObjectState],
        assets: FieldRenderAssets
    ) throws -> CGImage {
        let renderSignature = FieldRenderSignature(
            map: map,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            objects: objects,
            assets: assets
        )
        if let cachedImage = FieldRendererCaches.shared.renderedImage(for: renderSignature) {
            return cachedImage
        }

        let atlas = try FieldRendererCaches.shared.preparedAtlas(for: assets.tileset)
        let blockset = try FieldRendererCaches.shared.blockset(for: assets.tileset)

        let width = max(1, map.blockWidth) * blockPixelSize
        let height = max(1, map.blockHeight) * blockPixelSize
        guard let context = bitmapContext(width: width, height: height) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }

        context.interpolationQuality = .none
        context.setShouldAntialias(false)

        try drawBackground(
            map: map,
            atlas: atlas,
            blockset: blockset,
            canvasHeight: height,
            into: context
        )
        try drawActors(
            objects: objects,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            assets: assets,
            canvasHeight: height,
            into: context
        )

        guard let image = context.makeImage() else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        FieldRendererCaches.shared.storeRenderedImage(image, for: renderSignature)
        return image
    }

    fileprivate static func loadImage(from url: URL, invalidError: FieldRendererError) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw invalidError
        }
        return image
    }

    private static func renderBackground(
        map: MapManifest,
        atlas: PreparedTileAtlas,
        blockset: FieldBlockset,
        metrics: FieldSceneMetrics
    ) throws -> CGImage {
        guard let context = bitmapContext(
            width: metrics.contentPixelSize.width,
            height: metrics.contentPixelSize.height
        ) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }

        context.interpolationQuality = .none
        context.setShouldAntialias(false)

        try drawPaddedBackground(
            map: map,
            atlas: atlas,
            blockset: blockset,
            metrics: metrics,
            canvasHeight: metrics.contentPixelSize.height,
            into: context
        )

        guard let image = context.makeImage() else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        return image
    }

    private static func renderedActors(
        objects: [FieldRenderableObjectState],
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        assets: FieldRenderAssets,
        metrics: FieldSceneMetrics
    ) throws -> [FieldRenderedActor] {
        var actors: [FieldRenderedActor] = []

        for object in objects {
            if let actor = try renderedActor(
                id: object.id,
                role: .object,
                spriteID: object.sprite,
                facing: object.facing,
                position: object.position,
                assets: assets,
                metrics: metrics
            ) {
                actors.append(actor)
            }
        }

        if let playerActor = try renderedActor(
            id: "player",
            role: .player,
            spriteID: playerSpriteID,
            facing: playerFacing,
            position: playerPosition,
            assets: assets,
            metrics: metrics,
            includesWalkingFrame: true
        ) {
            actors.append(playerActor)
        }

        return actors
    }

    private static func sortedActorsForPresentation(_ actors: [FieldRenderedActor]) -> [FieldRenderedActor] {
        actors.sorted { lhs, rhs in
            if lhs.worldPosition.y == rhs.worldPosition.y {
                return lhs.id < rhs.id
            }
            return lhs.worldPosition.y < rhs.worldPosition.y
        }
    }

    private static func renderedActor(
        id: String,
        role: FieldRenderedActorRole,
        spriteID: String,
        facing: FacingDirection,
        position: TilePoint,
        assets: FieldRenderAssets,
        metrics: FieldSceneMetrics,
        includesWalkingFrame: Bool = false
    ) throws -> FieldRenderedActor? {
        guard let definition = assets.spriteDefinition(for: spriteID),
              let frame = definition.frame(for: facing, isWalking: false),
              let spriteImage = try FieldRendererCaches.shared.preparedSpriteImage(
                  definition: definition,
                  facing: facing,
                  isWalking: false
              ) else {
            return nil
        }
        let walkingImage = includesWalkingFrame
            ? try FieldRendererCaches.shared.preparedSpriteImage(
                definition: definition,
                facing: facing,
                isWalking: true
            )
            : nil

        return FieldRenderedActor(
            id: id,
            role: role,
            image: spriteImage,
            walkingImage: walkingImage,
            worldPosition: playerWorldPosition(for: position, metrics: metrics),
            size: .init(width: frame.width, height: frame.height),
            flippedHorizontally: frame.flippedHorizontally
        )
    }

    private static func bitmapContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
    }

    private static func drawBackground(
        map: MapManifest,
        atlas: PreparedTileAtlas,
        blockset: FieldBlockset,
        canvasHeight: Int,
        into context: CGContext
    ) throws {
        for blockY in 0..<map.blockHeight {
            for blockX in 0..<map.blockWidth {
                try drawBlock(
                    blockID: map.blockID(atBlockX: blockX, blockY: blockY, includeConnections: false),
                    mapX: blockX,
                    mapY: blockY,
                    atlas: atlas,
                    blockset: blockset,
                    canvasHeight: canvasHeight,
                    into: context
                )
            }
        }
    }

    private static func drawPaddedBackground(
        map: MapManifest,
        atlas: PreparedTileAtlas,
        blockset: FieldBlockset,
        metrics: FieldSceneMetrics,
        canvasHeight: Int,
        into context: CGContext
    ) throws {
        let paddingBlocksX = metrics.paddingPixels.width / blockPixelSize
        let paddingBlocksY = metrics.paddingPixels.height / blockPixelSize
        let totalBlocksX = map.blockWidth + (paddingBlocksX * 2)
        let totalBlocksY = map.blockHeight + (paddingBlocksY * 2)

        for paddedBlockY in 0..<totalBlocksY {
            for paddedBlockX in 0..<totalBlocksX {
                let mapBlockX = paddedBlockX - paddingBlocksX
                let mapBlockY = paddedBlockY - paddingBlocksY
                try drawBlock(
                    blockID: map.blockID(atBlockX: mapBlockX, blockY: mapBlockY),
                    mapX: paddedBlockX,
                    mapY: paddedBlockY,
                    atlas: atlas,
                    blockset: blockset,
                    canvasHeight: canvasHeight,
                    into: context
                )
            }
        }
    }

    private static func drawBlock(
        blockID: Int,
        mapX: Int,
        mapY: Int,
        atlas: PreparedTileAtlas,
        blockset: FieldBlockset,
        canvasHeight: Int,
        into context: CGContext
    ) throws {
        guard blockset.blocks.indices.contains(blockID) else {
            throw FieldRendererError.invalidBlockIndex(blockID)
        }

        let block = blockset.blocks[blockID]
        for tileRow in 0..<blockset.blockTileHeight {
            for tileColumn in 0..<blockset.blockTileWidth {
                let tileIndex = Int(block[(tileRow * blockset.blockTileWidth) + tileColumn])
                let tileImage = try atlas.tile(at: tileIndex)
                let x = (mapX * blockPixelSize) + (tileColumn * tilePixelSize)
                let topY = (mapY * blockPixelSize) + (tileRow * tilePixelSize)
                let y = contextY(forTopY: topY, drawHeight: tilePixelSize, canvasHeight: canvasHeight)
                context.draw(tileImage, in: CGRect(x: x, y: y, width: tilePixelSize, height: tilePixelSize))
            }
        }
    }

    private static func drawActors(
        objects: [FieldRenderableObjectState],
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        assets: FieldRenderAssets,
        canvasHeight: Int,
        into context: CGContext
    ) throws {
        for object in objects {
            try drawSprite(
                spriteID: object.sprite,
                facing: object.facing,
                position: object.position,
                assets: assets,
                canvasHeight: canvasHeight,
                into: context
            )
        }

        try drawSprite(
            spriteID: playerSpriteID,
            facing: playerFacing,
            position: playerPosition,
            assets: assets,
            canvasHeight: canvasHeight,
            into: context
        )
    }

    private static func drawSprite(
        spriteID: String,
        facing: FacingDirection,
        position: TilePoint,
        assets: FieldRenderAssets,
        canvasHeight: Int,
        into context: CGContext
    ) throws {
        guard let definition = assets.spriteDefinition(for: spriteID),
              let frame = definition.frame(for: facing, isWalking: false),
              let spriteImage = try FieldRendererCaches.shared.preparedSpriteImage(
                definition: definition,
                facing: facing,
                isWalking: false
              ) else {
            return
        }

        let x = position.x * stepPixelSize
        let topY = position.y * stepPixelSize
        let y = contextY(forTopY: topY, drawHeight: frame.height, canvasHeight: canvasHeight)
        context.saveGState()
        if frame.flippedHorizontally {
            context.translateBy(x: CGFloat(x + frame.width), y: CGFloat(y + frame.height))
            context.scaleBy(x: -1, y: -1)
        } else {
            context.translateBy(x: CGFloat(x), y: CGFloat(y + frame.height))
            context.scaleBy(x: 1, y: -1)
        }
        context.draw(spriteImage, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        context.restoreGState()
    }

    fileprivate static func crop(_ image: CGImage, topLeftFrame frame: FieldSpriteFrame) throws -> CGImage {
        let cropRect = CGRect(
            x: frame.x,
            y: frame.y,
            width: frame.width,
            height: frame.height
        )
        guard let cropped = image.cropping(to: cropRect.integral) else {
            throw FieldRendererError.cropFailed
        }
        return cropped
    }

    fileprivate static func prepareSpriteImageForFieldContext(_ image: CGImage) throws -> CGImage {
        let maskedImage = try applySpriteTransparencyMask(to: image)
        guard let context = spriteBitmapContext(width: image.width, height: image.height) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.translateBy(x: 0, y: CGFloat(image.height))
        context.scaleBy(x: 1, y: -1)
        context.draw(maskedImage, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let preparedImage = context.makeImage() else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        return preparedImage
    }

    private static func applySpriteTransparencyMask(to image: CGImage) throws -> CGImage {
        let pixelValues = try grayscalePixels(for: image)
        let maskBytes = pixelValues.map { $0 == 255 ? UInt8(255) : UInt8(0) }
        let maskData = Data(maskBytes) as CFData
        guard let provider = CGDataProvider(data: maskData),
              let mask = CGImage(
                maskWidth: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: image.width,
                provider: provider,
                decode: nil,
                shouldInterpolate: false
              ),
              let maskedImage = image.masking(mask) else {
            throw FieldRendererError.maskCreationFailed
        }
        return maskedImage
    }

    private static func grayscalePixels(for image: CGImage) throws -> [UInt8] {
        let width = image.width
        let height = image.height
        let bytesPerRow = width
        var bytes = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return bytes
    }

    private static func contextY(forTopY topY: Int, drawHeight: Int, canvasHeight: Int) -> Int {
        canvasHeight - topY - drawHeight
    }

    private static func spriteBitmapContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    struct TileAtlas {
        let image: CGImage
        let tileSize: Int
        let columns: Int
        let rows: Int

        init(image: CGImage, tileSize: Int) {
            self.image = image
            self.tileSize = tileSize
            self.columns = max(1, image.width / tileSize)
            self.rows = max(1, image.height / tileSize)
        }

        func tile(at index: Int) throws -> CGImage {
            let totalTiles = columns * rows
            guard (0..<totalTiles).contains(index) else {
                throw FieldRendererError.invalidTileIndex(index)
            }

            let x = (index % columns) * tileSize
            let y = (index / columns) * tileSize
            let cropRect = CGRect(
                x: x,
                y: y,
                width: tileSize,
                height: tileSize
            )
            guard let tile = image.cropping(to: cropRect.integral) else {
                throw FieldRendererError.cropFailed
            }
            return tile
        }
    }
}
