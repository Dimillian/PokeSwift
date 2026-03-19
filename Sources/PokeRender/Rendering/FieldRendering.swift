import Foundation
import SwiftUI
import CoreGraphics
import ImageIO
import PokeDataModel

public enum FieldDisplayStyle: Equatable, Hashable, Sendable {
    case rawGrayscale
    case dmgAuthentic
    case dmgTinted
    case gbcCompatibility

    public static let defaultGameplayStyle: FieldDisplayStyle = .dmgTinted

    public var sidebarSummaryLabel: String {
        switch self {
        case .rawGrayscale:
            return "RAW"
        case .dmgAuthentic:
            return "DMG"
        case .dmgTinted:
            return "TINTED"
        case .gbcCompatibility:
            return "GBC"
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
        case .gbcCompatibility:
            return "GBC Compat"
        }
    }

    public var preferenceValue: String {
        switch self {
        case .rawGrayscale:
            return "rawGrayscale"
        case .dmgAuthentic:
            return "dmgAuthentic"
        case .dmgTinted:
            return "dmgTinted"
        case .gbcCompatibility:
            return "gbcCompatibility"
        }
    }

    var shaderPresetValue: Float {
        switch self {
        case .rawGrayscale:
            return 0
        case .dmgAuthentic:
            return 1
        case .dmgTinted:
            return 2
        case .gbcCompatibility:
            return 3
        }
    }

    public init?(preferenceValue: String) {
        switch preferenceValue {
        case "rawGrayscale":
            self = .rawGrayscale
        case "dmgAuthentic":
            self = .dmgAuthentic
        case "dmgTinted":
            self = .dmgTinted
        case "gbcCompatibility":
            self = .gbcCompatibility
        default:
            return nil
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
    public let animation: FieldTilesetAnimationDefinition

    public init(
        id: String,
        imageURL: URL,
        blocksetURL: URL,
        sourceTileSize: Int = 8,
        blockTileWidth: Int = 4,
        blockTileHeight: Int = 4,
        animation: FieldTilesetAnimationDefinition = .none
    ) {
        self.id = id
        self.imageURL = imageURL
        self.blocksetURL = blocksetURL
        self.sourceTileSize = sourceTileSize
        self.blockTileWidth = blockTileWidth
        self.blockTileHeight = blockTileHeight
        self.animation = animation
    }
}

public struct FieldAnimatedTileDefinition: Equatable, Sendable {
    public let tileID: Int
    public let frameImageURLs: [URL]

    public init(tileID: Int, frameImageURLs: [URL] = []) {
        self.tileID = tileID
        self.frameImageURLs = frameImageURLs
    }
}

public struct FieldTilesetAnimationDefinition: Equatable, Sendable {
    public let kind: TilesetAnimationKind
    public let animatedTiles: [FieldAnimatedTileDefinition]

    public init(kind: TilesetAnimationKind, animatedTiles: [FieldAnimatedTileDefinition] = []) {
        self.kind = kind
        self.animatedTiles = animatedTiles
    }

    public static let none = FieldTilesetAnimationDefinition(kind: .none)

    public var isAnimated: Bool {
        kind != .none && animatedTiles.isEmpty == false
    }

    public var waterTileID: Int? {
        switch kind {
        case .none:
            return nil
        case .water, .waterFlower:
            return animatedTiles.first(where: { $0.frameImageURLs.isEmpty })?.tileID
        }
    }

    public var flowerTile: FieldAnimatedTileDefinition? {
        guard kind == .waterFlower else { return nil }
        return animatedTiles.first(where: { $0.frameImageURLs.isEmpty == false })
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
    case invalidTilesetAnimationImage(URL)
    case invalidSpriteImage(URL)
    case invalidBlocksetLength(Int)
    case invalidBlockIndex(Int)
    case invalidTileIndex(Int)
    case cropFailed
    case maskCreationFailed
    case bitmapContextCreationFailed
}

public struct FieldTileAnimationVisualState: Equatable, Hashable, Sendable {
    public let waterFrameIndex: Int
    public let flowerFrameIndex: Int?

    public init(waterFrameIndex: Int, flowerFrameIndex: Int?) {
        self.waterFrameIndex = waterFrameIndex
        self.flowerFrameIndex = flowerFrameIndex
    }
}

private enum WaterShiftDirection {
    case left
    case right
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

public struct FieldRenderedAnimatedTilePlacement: Identifiable, Equatable, Sendable {
    public let id: String
    public let tileID: Int
    public let worldPosition: FieldPixelPoint
    public let size: FieldPixelSize

    public init(tileID: Int, worldPosition: FieldPixelPoint, size: FieldPixelSize) {
        self.tileID = tileID
        self.worldPosition = worldPosition
        self.size = size
        id = "\(tileID)-\(worldPosition.x)-\(worldPosition.y)"
    }
}

public struct FieldRenderedScene: @unchecked Sendable {
    public let mapID: String
    public let tileset: FieldTilesetDefinition
    public let metrics: FieldSceneMetrics
    public let backgroundImage: CGImage
    public let animatedTilePlacements: [FieldRenderedAnimatedTilePlacement]
    public let actors: [FieldRenderedActor]

    public init(
        mapID: String,
        tileset: FieldTilesetDefinition,
        metrics: FieldSceneMetrics,
        backgroundImage: CGImage,
        animatedTilePlacements: [FieldRenderedAnimatedTilePlacement],
        actors: [FieldRenderedActor]
    ) {
        self.mapID = mapID
        self.tileset = tileset
        self.metrics = metrics
        self.backgroundImage = backgroundImage
        self.animatedTilePlacements = animatedTilePlacements
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

private struct PreparedAnimatedTileFrames {
    struct Frame {
        let width: Int
        let height: Int
        let rgbaPixels: [UInt8]
    }

    let waterFrames: [Frame]
    let flowerFrames: [Frame]

    func frame(
        for tileID: Int,
        animation: FieldTilesetAnimationDefinition,
        visualState: FieldTileAnimationVisualState
    ) -> Frame? {
        if tileID == animation.waterTileID {
            guard waterFrames.indices.contains(visualState.waterFrameIndex) else { return nil }
            return waterFrames[visualState.waterFrameIndex]
        }

        if tileID == animation.flowerTile?.tileID,
           let flowerFrameIndex = visualState.flowerFrameIndex,
           flowerFrames.indices.contains(flowerFrameIndex) {
            return flowerFrames[flowerFrameIndex]
        }

        return nil
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

    fileprivate struct AnimatedTileFramesCacheKey: Hashable {
        let tilesetImagePath: String
        let tileSize: Int
        let animationKind: TilesetAnimationKind
        let waterTileID: Int?
        let flowerTileID: Int?
        let flowerImagePaths: [String]

        init(tileset: FieldTilesetDefinition) {
            tilesetImagePath = tileset.imageURL.standardizedFileURL.path
            tileSize = tileset.sourceTileSize
            animationKind = tileset.animation.kind
            waterTileID = tileset.animation.waterTileID
            flowerTileID = tileset.animation.flowerTile?.tileID
            flowerImagePaths = tileset.animation.flowerTile?.frameImageURLs.map(\.standardizedFileURL.path) ?? []
        }
    }

    fileprivate struct AnimatedOverlayCacheKey: Hashable {
        struct PlacementSignature: Hashable {
            let tileID: Int
            let worldPosition: FieldPixelPoint
            let size: FieldPixelSize

            init(_ placement: FieldRenderedAnimatedTilePlacement) {
                tileID = placement.tileID
                worldPosition = placement.worldPosition
                size = placement.size
            }
        }

        let contentPixelSize: FieldPixelSize
        let tilesetFramesKey: AnimatedTileFramesCacheKey
        let visualState: FieldTileAnimationVisualState
        let placements: [PlacementSignature]

        init(
            contentPixelSize: FieldPixelSize,
            tileset: FieldTilesetDefinition,
            visualState: FieldTileAnimationVisualState,
            placements: [FieldRenderedAnimatedTilePlacement]
        ) {
            self.contentPixelSize = contentPixelSize
            tilesetFramesKey = AnimatedTileFramesCacheKey(tileset: tileset)
            self.visualState = visualState
            self.placements = placements.map(PlacementSignature.init)
        }
    }

    static let shared = FieldRendererCaches()

    private let lock = NSLock()
    private let maxRenderedImages = 24
    private let maxAnimatedOverlayImages = 32
    private var decodedImages: [String: CGImage] = [:]
    private var blocksets: [BlocksetCacheKey: FieldBlockset] = [:]
    private var preparedAtlases: [AtlasCacheKey: PreparedTileAtlas] = [:]
    private var preparedSprites: [SpriteFrameCacheKey: CGImage] = [:]
    private var preparedAnimatedTiles: [AnimatedTileFramesCacheKey: PreparedAnimatedTileFrames] = [:]
    private var backgroundImages: [FieldBackgroundSignature: CGImage] = [:]
    private var animatedOverlayImages: [AnimatedOverlayCacheKey: CGImage] = [:]
    private var animatedOverlayOrder: [AnimatedOverlayCacheKey] = []
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

    func animatedOverlayImage(for key: AnimatedOverlayCacheKey) -> CGImage? {
        withLock {
            animatedOverlayImages[key]
        }
    }

    func storeAnimatedOverlayImage(_ image: CGImage, for key: AnimatedOverlayCacheKey) {
        withLock {
            animatedOverlayImages[key] = image
            animatedOverlayOrder.removeAll { $0 == key }
            animatedOverlayOrder.append(key)

            while animatedOverlayOrder.count > maxAnimatedOverlayImages {
                let evictedKey = animatedOverlayOrder.removeFirst()
                animatedOverlayImages.removeValue(forKey: evictedKey)
            }
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

    func preparedAnimatedTileFrames(for tileset: FieldTilesetDefinition) throws -> PreparedAnimatedTileFrames? {
        guard tileset.animation.isAnimated else { return nil }

        let key = AnimatedTileFramesCacheKey(tileset: tileset)
        if let cached = withLock({ preparedAnimatedTiles[key] }) {
            return cached
        }

        let atlas = try preparedAtlas(for: tileset)
        let waterFrames = try tileset.animation.waterTileID.map { waterTileID in
            try FieldSceneRenderer.prepareWaterAnimationFrames(baseTile: atlas.tile(at: waterTileID))
        } ?? []
        let flowerFrames = try tileset.animation.flowerTile?.frameImageURLs.map { frameURL in
            try FieldSceneRenderer.prepareAnimatedTileFrame(
                image(at: frameURL, invalidError: .invalidTilesetAnimationImage(frameURL))
            )
        } ?? []
        let preparedFrames = PreparedAnimatedTileFrames(
            waterFrames: waterFrames,
            flowerFrames: flowerFrames
        )

        withLock {
            preparedAnimatedTiles[key] = preparedFrames
        }
        return preparedFrames
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

    public static func tileAnimationVisualState(
        animation: FieldTilesetAnimationDefinition,
        visibleFieldFrameCount: Int
    ) -> FieldTileAnimationVisualState {
        let clampedFrameCount = max(0, visibleFieldFrameCount)

        switch animation.kind {
        case .none:
            return .init(waterFrameIndex: 0, flowerFrameIndex: nil)
        case .water:
            return .init(
                waterFrameIndex: (clampedFrameCount / 20) % 8,
                flowerFrameIndex: nil
            )
        case .waterFlower:
            let waterUpdateCount = (clampedFrameCount + 1) / 21
            let flowerUpdateCount = clampedFrameCount / 21

            return .init(
                waterFrameIndex: waterUpdateCount % 8,
                flowerFrameIndex: flowerUpdateCount == 0
                    ? nil
                    : flowerFrameIndex(forWaterCounter: flowerUpdateCount % 8)
            )
        }
    }

    public static func animatedOverlayImage(
        for scene: FieldRenderedScene,
        visualState: FieldTileAnimationVisualState
    ) -> CGImage? {
        guard scene.tileset.animation.isAnimated,
              scene.animatedTilePlacements.isEmpty == false else {
            return nil
        }

        let overlayKey = FieldRendererCaches.AnimatedOverlayCacheKey(
            contentPixelSize: scene.metrics.contentPixelSize,
            tileset: scene.tileset,
            visualState: visualState,
            placements: scene.animatedTilePlacements
        )
        if let cached = FieldRendererCaches.shared.animatedOverlayImage(for: overlayKey) {
            return cached
        }
        guard let preparedFrames = try? FieldRendererCaches.shared.preparedAnimatedTileFrames(for: scene.tileset) else {
            return nil
        }
        guard let image = try? renderAnimatedOverlayImage(
            contentPixelSize: scene.metrics.contentPixelSize,
            placements: scene.animatedTilePlacements,
            tileset: scene.tileset,
            preparedFrames: preparedFrames,
            visualState: visualState
        ) else {
            return nil
        }
        FieldRendererCaches.shared.storeAnimatedOverlayImage(image, for: overlayKey)
        return image
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
        let animatedTilePlacements = renderedAnimatedTilePlacements(
            map: map,
            blockset: blockset,
            metrics: metrics,
            tileset: assets.tileset
        )

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
            tileset: assets.tileset,
            metrics: metrics,
            backgroundImage: backgroundImage,
            animatedTilePlacements: animatedTilePlacements,
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
        try enumerateBackgroundTiles(
            map: map,
            blockset: blockset,
            paddingBlocks: .init(width: 0, height: 0),
            includeConnections: false
        ) { tileIndex, x, topY in
            let tileImage = try atlas.tile(at: tileIndex)
            let y = contextY(forTopY: topY, drawHeight: tilePixelSize, canvasHeight: canvasHeight)
            context.draw(tileImage, in: CGRect(x: x, y: y, width: tilePixelSize, height: tilePixelSize))
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
        try enumerateBackgroundTiles(
            map: map,
            blockset: blockset,
            paddingBlocks: .init(width: paddingBlocksX, height: paddingBlocksY)
        ) { tileIndex, x, topY in
            let tileImage = try atlas.tile(at: tileIndex)
            let y = contextY(forTopY: topY, drawHeight: tilePixelSize, canvasHeight: canvasHeight)
            context.draw(tileImage, in: CGRect(x: x, y: y, width: tilePixelSize, height: tilePixelSize))
        }
    }

    private static func renderedAnimatedTilePlacements(
        map: MapManifest,
        blockset: FieldBlockset,
        metrics: FieldSceneMetrics,
        tileset: FieldTilesetDefinition
    ) -> [FieldRenderedAnimatedTilePlacement] {
        guard tileset.animation.isAnimated else { return [] }

        let animatedTileIDs = Set(tileset.animation.animatedTiles.map(\.tileID))
        guard animatedTileIDs.isEmpty == false else { return [] }

        let paddingBlocks = FieldPixelSize(
            width: metrics.paddingPixels.width / blockPixelSize,
            height: metrics.paddingPixels.height / blockPixelSize
        )
        var placements: [FieldRenderedAnimatedTilePlacement] = []
        try? enumerateBackgroundTiles(
            map: map,
            blockset: blockset,
            paddingBlocks: paddingBlocks
        ) { tileIndex, x, topY in
            guard animatedTileIDs.contains(tileIndex) else { return }
            placements.append(
                .init(
                    tileID: tileIndex,
                    worldPosition: .init(x: x, y: topY),
                    size: .init(width: tilePixelSize, height: tilePixelSize)
                )
            )
        }
        return placements
    }

    private static func enumerateBackgroundTiles(
        map: MapManifest,
        blockset: FieldBlockset,
        paddingBlocks: FieldPixelSize,
        includeConnections: Bool = true,
        _ body: (Int, Int, Int) throws -> Void
    ) throws {
        let totalBlocksX = map.blockWidth + (paddingBlocks.width * 2)
        let totalBlocksY = map.blockHeight + (paddingBlocks.height * 2)

        for paddedBlockY in 0..<totalBlocksY {
            for paddedBlockX in 0..<totalBlocksX {
                let mapBlockX = paddedBlockX - paddingBlocks.width
                let mapBlockY = paddedBlockY - paddingBlocks.height
                let blockID = map.blockID(
                    atBlockX: mapBlockX,
                    blockY: mapBlockY,
                    includeConnections: includeConnections
                )
                guard blockset.blocks.indices.contains(blockID) else {
                    throw FieldRendererError.invalidBlockIndex(blockID)
                }

                let block = blockset.blocks[blockID]
                for tileRow in 0..<blockset.blockTileHeight {
                    for tileColumn in 0..<blockset.blockTileWidth {
                        let tileIndex = Int(block[(tileRow * blockset.blockTileWidth) + tileColumn])
                        let x = (paddedBlockX * blockPixelSize) + (tileColumn * tilePixelSize)
                        let topY = (paddedBlockY * blockPixelSize) + (tileRow * tilePixelSize)
                        try body(tileIndex, x, topY)
                    }
                }
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

    private static func renderAnimatedOverlayImage(
        contentPixelSize: FieldPixelSize,
        placements: [FieldRenderedAnimatedTilePlacement],
        tileset: FieldTilesetDefinition,
        preparedFrames: PreparedAnimatedTileFrames,
        visualState: FieldTileAnimationVisualState
    ) throws -> CGImage {
        let bytesPerRow = contentPixelSize.width * 4
        var pixels = [UInt8](repeating: 0, count: contentPixelSize.height * bytesPerRow)

        for placement in placements {
            guard let frame = preparedFrames.frame(
                for: placement.tileID,
                animation: tileset.animation,
                visualState: visualState
            ) else {
                continue
            }
            guard frame.width == placement.size.width,
                  frame.height == placement.size.height else {
                throw FieldRendererError.bitmapContextCreationFailed
            }

            for row in 0..<frame.height {
                let destinationY = placement.worldPosition.y + row
                guard (0..<contentPixelSize.height).contains(destinationY) else { continue }

                let sourceRowStart = row * frame.width * 4
                let destinationRowStart = (destinationY * bytesPerRow) + (placement.worldPosition.x * 4)
                guard destinationRowStart >= 0,
                      destinationRowStart + (frame.width * 4) <= pixels.count else {
                    continue
                }

                pixels.replaceSubrange(
                    destinationRowStart..<(destinationRowStart + (frame.width * 4)),
                    with: frame.rgbaPixels[sourceRowStart..<(sourceRowStart + (frame.width * 4))]
                )
            }
        }

        return try rgbaImage(from: pixels, width: contentPixelSize.width, height: contentPixelSize.height)
    }

    fileprivate static func prepareWaterAnimationFrames(baseTile: CGImage) throws -> [PreparedAnimatedTileFrames.Frame] {
        let width = baseTile.width
        let height = baseTile.height
        var frames: [[UInt8]] = [try grayscalePixels(for: baseTile)]
        guard frames[0].count == width * height else {
            throw FieldRendererError.bitmapContextCreationFailed
        }

        for frameIndex in 1..<8 {
            let previous = frames[frameIndex - 1]
            let direction: WaterShiftDirection = (frameIndex & 0x4) == 0 ? .right : .left
            frames.append(shiftWaterTilePixels(previous, width: width, height: height, direction: direction))
        }

        return frames.map { framePixels in
            PreparedAnimatedTileFrames.Frame(
                width: width,
                height: height,
                rgbaPixels: rgbaPixels(fromGrayscalePixels: framePixels)
            )
        }
    }

    private static func shiftWaterTilePixels(
        _ pixels: [UInt8],
        width: Int,
        height: Int,
        direction: WaterShiftDirection
    ) -> [UInt8] {
        var shifted = pixels
        for row in 0..<height {
            let rowStart = row * width
            switch direction {
            case .left:
                let first = pixels[rowStart]
                for column in 0..<(width - 1) {
                    shifted[rowStart + column] = pixels[rowStart + column + 1]
                }
                shifted[rowStart + width - 1] = first
            case .right:
                let last = pixels[rowStart + width - 1]
                for column in stride(from: width - 1, to: 0, by: -1) {
                    shifted[rowStart + column] = pixels[rowStart + column - 1]
                }
                shifted[rowStart] = last
            }
        }
        return shifted
    }

    fileprivate static func prepareAnimatedTileFrame(_ image: CGImage) throws -> PreparedAnimatedTileFrames.Frame {
        .init(
            width: image.width,
            height: image.height,
            rgbaPixels: try rgbaPixels(for: image)
        )
    }

    private static func rgbaPixels(fromGrayscalePixels pixels: [UInt8]) -> [UInt8] {
        var rgbaPixels = [UInt8]()
        rgbaPixels.reserveCapacity(pixels.count * 4)
        for pixel in pixels {
            rgbaPixels.append(pixel)
            rgbaPixels.append(pixel)
            rgbaPixels.append(pixel)
            rgbaPixels.append(255)
        }
        return rgbaPixels
    }

    private static func rgbaPixels(for image: CGImage) throws -> [UInt8] {
        let bytesPerRow = image.width * 4
        var bytes = [UInt8](repeating: 0, count: image.height * bytesPerRow)
        guard let context = CGContext(
            data: &bytes,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }

    private static func rgbaImage(from pixels: [UInt8], width: Int, height: Int) throws -> CGImage {
        let imageData = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: imageData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }

        return image
    }

    private static func flowerFrameIndex(forWaterCounter waterCounter: Int) -> Int {
        let modFlower = waterCounter & 0x3
        if modFlower < 2 {
            return 0
        }
        if modFlower == 2 {
            return 1
        }
        return 2
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

    private static func transparentBitmapContext(width: Int, height: Int) -> CGContext? {
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
