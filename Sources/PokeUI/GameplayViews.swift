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

public struct FieldMapView: View {
    let map: MapManifest
    let playerPosition: TilePoint
    let playerFacing: FacingDirection
    let objects: [FieldObjectRenderState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?

    public init(
        map: MapManifest,
        playerPosition: TilePoint,
        playerFacing: FacingDirection,
        objects: [FieldObjectRenderState],
        playerSpriteID: String = "SPRITE_RED",
        renderAssets: FieldRenderAssets? = nil
    ) {
        self.map = map
        self.playerPosition = playerPosition
        self.playerFacing = playerFacing
        self.objects = objects
        self.playerSpriteID = playerSpriteID
        self.renderAssets = renderAssets
    }

    public var body: some View {
        GeometryReader { proxy in
            let pixelWidth = CGFloat(max(1, map.blockWidth * FieldSceneRenderer.blockPixelSize))
            let pixelHeight = CGFloat(max(1, map.blockHeight * FieldSceneRenderer.blockPixelSize))
            let scale = min(proxy.size.width / pixelWidth, proxy.size.height / pixelHeight)
            let renderWidth = pixelWidth * scale
            let renderHeight = pixelHeight * scale

            ZStack {
                if let renderedField {
                    Image(decorative: renderedField, scale: 1)
                        .interpolation(.none)
                        .resizable()
                } else {
                    placeholderField
                }
            }
            .frame(width: renderWidth, height: renderHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private var renderedField: CGImage? {
        guard let renderAssets else { return nil }
        return try? FieldSceneRenderer.render(
            map: map,
            playerPosition: playerPosition,
            playerFacing: playerFacing,
            playerSpriteID: playerSpriteID,
            objects: objects,
            assets: renderAssets
        )
    }

    @ViewBuilder
    private var placeholderField: some View {
        let stepWidth = max(1, map.stepWidth)
        let stepHeight = max(1, map.stepHeight)
        let tileSize = min(
            CGFloat(map.blockWidth * FieldSceneRenderer.blockPixelSize) / CGFloat(stepWidth),
            CGFloat(map.blockHeight * FieldSceneRenderer.blockPixelSize) / CGFloat(stepHeight)
        )

        ZStack(alignment: .topLeading) {
            ForEach(0..<stepHeight, id: \.self) { y in
                ForEach(0..<stepWidth, id: \.self) { x in
                    Rectangle()
                        .fill(tileColor(x: x, y: y))
                        .frame(width: tileSize, height: tileSize)
                        .position(x: (CGFloat(x) * tileSize) + (tileSize / 2), y: (CGFloat(y) * tileSize) + (tileSize / 2))
                }
            }

            ForEach(objects, id: \.id) { object in
                Rectangle()
                    .fill(objectColor(for: object.sprite))
                    .frame(width: tileSize * 0.88, height: tileSize * 0.88)
                    .overlay {
                        Text(object.displayName.prefix(1))
                            .font(.system(size: tileSize * 0.45, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .position(x: (CGFloat(object.position.x) * tileSize) + (tileSize / 2), y: (CGFloat(object.position.y) * tileSize) + (tileSize / 2))
            }

            Capsule()
                .fill(Color.black)
                .frame(width: tileSize * 0.8, height: tileSize * 0.9)
                .overlay(alignment: overlayAlignment(for: playerFacing)) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: tileSize * 0.18, height: tileSize * 0.18)
                        .offset(directionOffset(for: playerFacing, tileSize: tileSize))
                }
                .position(x: (CGFloat(playerPosition.x) * tileSize) + (tileSize / 2), y: (CGFloat(playerPosition.y) * tileSize) + (tileSize / 2))
        }
    }

    private func tileColor(x: Int, y: Int) -> Color {
        let blockX = max(0, min(map.blockWidth - 1, x / 2))
        let blockY = max(0, min(map.blockHeight - 1, y / 2))
        let index = min(map.blockIDs.count - 1, (blockY * map.blockWidth) + blockX)
        let blockID = map.blockIDs.isEmpty ? 0 : map.blockIDs[index]
        switch map.tileset {
        case "OVERWORLD":
            return (blockID % 5 == 0) ? Color(red: 0.86, green: 0.93, blue: 0.79) : Color(red: 0.79, green: 0.87, blue: 0.73)
        case "DOJO":
            return (blockID % 4 == 0) ? Color(red: 0.96, green: 0.92, blue: 0.83) : Color(red: 0.88, green: 0.84, blue: 0.74)
        default:
            return (blockID % 3 == 0) ? Color(red: 0.93, green: 0.93, blue: 0.9) : Color(red: 0.84, green: 0.84, blue: 0.8)
        }
    }

    private func objectColor(for sprite: String) -> Color {
        switch sprite {
        case _ where sprite.contains("OAK"):
            return Color(red: 0.28, green: 0.43, blue: 0.31)
        case _ where sprite.contains("BLUE"):
            return Color(red: 0.2, green: 0.33, blue: 0.62)
        case _ where sprite.contains("POKE_BALL"):
            return Color(red: 0.75, green: 0.2, blue: 0.18)
        case _ where sprite.contains("MOM"):
            return Color(red: 0.67, green: 0.42, blue: 0.58)
        default:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        }
    }

    private func overlayAlignment(for facing: FacingDirection) -> Alignment {
        switch facing {
        case .up:
            return .top
        case .down:
            return .bottom
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    private func directionOffset(for facing: FacingDirection, tileSize: CGFloat) -> CGSize {
        let amount = tileSize * 0.1
        switch facing {
        case .up:
            return CGSize(width: 0, height: amount)
        case .down:
            return CGSize(width: 0, height: -amount)
        case .left:
            return CGSize(width: amount, height: 0)
        case .right:
            return CGSize(width: -amount, height: 0)
        }
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

public struct DialogueBoxView: View {
    let title: String?
    let lines: [String]

    public init(title: String? = nil, lines: [String]) {
        self.title = title
        self.lines = lines
    }

    public var body: some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 10) {
                if let title {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.55))
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 22, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(6)
        }
    }
}

public struct StarterChoicePanel: View {
    let options: [SpeciesManifest]
    let focusedIndex: Int

    public init(options: [SpeciesManifest], focusedIndex: Int) {
        self.options = options
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose Your Starter")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                ForEach(Array(options.enumerated()), id: \.element.id) { index, species in
                    HStack(spacing: 12) {
                        Text(index == focusedIndex ? "▶" : " ")
                            .frame(width: 18, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.displayName)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                            Text("HP \(species.baseHP)  ATK \(species.baseAttack)  DEF \(species.baseDefense)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(index == focusedIndex ? Color.white.opacity(0.3) : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .foregroundStyle(.black)
        }
    }
}

public struct BattlePanel: View {
    let trainerName: String
    let message: String
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let moveNames: [String]
    let focusedMoveIndex: Int

    public init(
        trainerName: String,
        message: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        moveNames: [String],
        focusedMoveIndex: Int
    ) {
        self.trainerName = trainerName
        self.message = message
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.moveNames = moveNames
        self.focusedMoveIndex = focusedMoveIndex
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                battleCard(title: trainerName, pokemon: enemyPokemon)
                Spacer()
            }
            HStack {
                Spacer()
                battleCard(title: "RED", pokemon: playerPokemon)
            }
            HStack(alignment: .top, spacing: 20) {
                DialogueBoxView(title: "Battle", lines: [message])
                GameBoyPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Moves")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                        ForEach(Array(moveNames.enumerated()), id: \.offset) { index, move in
                            Text("\(index == focusedMoveIndex ? "▶" : " ") \(move)")
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 260, alignment: .leading)
                }
            }
        }
    }

    private func battleCard(title: String, pokemon: PartyPokemonTelemetry) -> some View {
        PlainWhitePanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
                Text("\(pokemon.displayName) Lv\(pokemon.level)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                Text("HP \(pokemon.currentHP)/\(pokemon.maxHP)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.black)
            .frame(width: 240, alignment: .leading)
        }
    }
}
