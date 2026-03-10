import SwiftUI
import CoreGraphics
import ImageIO
import PokeCore
import PokeDataModel

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

    public init(
        id: String,
        imageURL: URL,
        frameWidth: Int = 16,
        frameHeight: Int = 16,
        facingFrames: [FacingDirection: FieldSpriteFrame]
    ) {
        self.id = id
        self.imageURL = imageURL
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.facingFrames = facingFrames
    }

    public func frame(for facing: FacingDirection) -> FieldSpriteFrame? {
        facingFrames[facing]
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

struct FieldSceneRenderer {
    static let tilePixelSize = 8
    static let blockTileWidth = 4
    static let blockTileHeight = 4
    static let stepPixelSize = 16
    static let blockPixelSize = tilePixelSize * blockTileWidth

    static func render(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        objects: [FieldObjectRenderState],
        assets: FieldRenderAssets
    ) throws -> CGImage {
        let tilesetImage = try loadImage(from: assets.tileset.imageURL, invalidError: .invalidTilesetImage(assets.tileset.imageURL))
        let spriteImages = try Dictionary(
            uniqueKeysWithValues: assets.overworldSprites.values.map { definition in
                let image = try loadImage(from: definition.imageURL, invalidError: .invalidSpriteImage(definition.imageURL))
                return (definition.id, image)
            }
        )
        let blocksetData = try Data(contentsOf: assets.tileset.blocksetURL)
        let blockset = try FieldBlockset.decode(
            data: blocksetData,
            blockTileWidth: assets.tileset.blockTileWidth,
            blockTileHeight: assets.tileset.blockTileHeight
        )
        let atlas = TileAtlas(image: tilesetImage, tileSize: assets.tileset.sourceTileSize)

        let width = max(1, map.blockWidth) * blockPixelSize
        let height = max(1, map.blockHeight) * blockPixelSize
        guard let context = bitmapContext(width: width, height: height) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }

        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        try drawBackground(map: map, atlas: atlas, blockset: blockset, into: context)
        try drawActors(
            objects: objects,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            assets: assets,
            spriteImages: spriteImages,
            into: context
        )

        guard let image = context.makeImage() else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        return image
    }

    private static func loadImage(from url: URL, invalidError: FieldRendererError) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw invalidError
        }
        return image
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
        atlas: TileAtlas,
        blockset: FieldBlockset,
        into context: CGContext
    ) throws {
        for blockY in 0..<map.blockHeight {
            for blockX in 0..<map.blockWidth {
                let mapIndex = (blockY * map.blockWidth) + blockX
                guard map.blockIDs.indices.contains(mapIndex) else { continue }
                let blockID = map.blockIDs[mapIndex]
                guard blockset.blocks.indices.contains(blockID) else {
                    throw FieldRendererError.invalidBlockIndex(blockID)
                }

                let block = blockset.blocks[blockID]
                for tileRow in 0..<blockset.blockTileHeight {
                    for tileColumn in 0..<blockset.blockTileWidth {
                        let tileIndex = Int(block[(tileRow * blockset.blockTileWidth) + tileColumn])
                        let tileImage = try atlas.tile(at: tileIndex)
                        let x = (blockX * blockPixelSize) + (tileColumn * tilePixelSize)
                        let y = (blockY * blockPixelSize) + (tileRow * tilePixelSize)
                        context.draw(tileImage, in: CGRect(x: x, y: y, width: tilePixelSize, height: tilePixelSize))
                    }
                }
            }
        }
    }

    private static func drawActors(
        objects: [FieldObjectRenderState],
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        playerSpriteID: String,
        assets: FieldRenderAssets,
        spriteImages: [String: CGImage],
        into context: CGContext
    ) throws {
        for object in objects {
            try drawSprite(
                spriteID: object.sprite,
                facing: object.facing,
                position: object.position,
                assets: assets,
                spriteImages: spriteImages,
                into: context
            )
        }

        try drawSprite(
            spriteID: playerSpriteID,
            facing: playerFacing,
            position: playerPosition,
            assets: assets,
            spriteImages: spriteImages,
            into: context
        )
    }

    private static func drawSprite(
        spriteID: String,
        facing: FacingDirection,
        position: TilePoint,
        assets: FieldRenderAssets,
        spriteImages: [String: CGImage],
        into context: CGContext
    ) throws {
        guard let definition = assets.spriteDefinition(for: spriteID),
              let sourceImage = spriteImages[spriteID],
              let frame = definition.frame(for: facing) else {
            return
        }

        let spriteImage = try prepareImageForFieldContext(
            crop(sourceImage, topLeftFrame: frame)
        )
        let x = position.x * stepPixelSize
        let y = position.y * stepPixelSize
        context.saveGState()
        context.setBlendMode(.multiply)
        if frame.flippedHorizontally {
            context.translateBy(x: CGFloat(x + frame.width), y: 0)
            context.scaleBy(x: -1, y: 1)
            context.draw(spriteImage, in: CGRect(x: 0, y: y, width: frame.width, height: frame.height))
        } else {
            context.draw(spriteImage, in: CGRect(x: x, y: y, width: frame.width, height: frame.height))
        }
        context.restoreGState()
    }

    private static func crop(_ image: CGImage, topLeftFrame frame: FieldSpriteFrame) throws -> CGImage {
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

    private static func prepareImageForFieldContext(_ image: CGImage) throws -> CGImage {
        guard let context = bitmapContext(width: image.width, height: image.height) else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        context.translateBy(x: 0, y: CGFloat(image.height))
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let flipped = context.makeImage() else {
            throw FieldRendererError.bitmapContextCreationFailed
        }
        return flipped
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
            return try FieldSceneRenderer.prepareImageForFieldContext(tile)
        }
    }
}
