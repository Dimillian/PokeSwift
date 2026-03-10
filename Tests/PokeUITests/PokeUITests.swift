import XCTest
import ImageIO
@testable import PokeUI
import PokeDataModel
import PokeCore

@MainActor
final class PokeUITests: XCTestCase {
    func testTitleMenuPanelCanBeConstructed() {
        let view = TitleMenuPanel(entries: [.init(id: "newGame", label: "New Game", enabledByDefault: true)], focusedIndex: 0)
        XCTAssertNotNil(view)
    }

    func testBlocksetDecoderBuilds4x4BlocksFromRepoData() throws {
        let blocksetURL = repoRoot().appendingPathComponent("gfx/blocksets/overworld.bst")
        let data = try Data(contentsOf: blocksetURL)
        let blockset = try FieldBlockset.decode(data: data)

        XCTAssertEqual(blockset.blockTileWidth, 4)
        XCTAssertEqual(blockset.blockTileHeight, 4)
        XCTAssertEqual(blockset.blocks.count, 128)
        XCTAssertEqual(blockset.blocks.first?.count, 16)
    }

    func testTileAtlasUsesTopLeftOriginForRepoPNGExports() throws {
        let image = try loadImage(repoRoot().appendingPathComponent("gfx/tilesets/overworld.png"))
        let tileZero = try cropTopLeftTile(from: image, tileSize: 8, index: 0)
        XCTAssertGreaterThan(averageGrayscale(for: tileZero), 240)
    }

    func testTileAtlasPreparesTilesForFlippedFieldContext() throws {
        let sourceTile = try makeTestTileImage(topHalf: 0, bottomHalf: 255)
        let atlas = FieldSceneRenderer.TileAtlas(image: sourceTile, tileSize: 8)

        let preparedTile = try atlas.tile(at: 0)

        XCTAssertGreaterThan(averageGrayscale(forTopRowsOf: preparedTile, rowCount: 4), 240)
        XCTAssertLessThan(averageGrayscale(forBottomRowsOf: preparedTile, rowCount: 4), 15)
    }

    func testSpriteFrameLookupUsesExplicitFacingFrames() {
        let definition = FieldSpriteDefinition(
            id: "SPRITE_RED",
            imageURL: URL(fileURLWithPath: "/tmp/red.png"),
            facingFrames: [
                .down: .init(x: 0, y: 0, width: 16, height: 16),
                .up: .init(x: 0, y: 16, width: 16, height: 16),
                .left: .init(x: 0, y: 32, width: 16, height: 16),
                .right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true),
            ]
        )

        XCTAssertEqual(definition.frame(for: .down), .init(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(definition.frame(for: .right), .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true))
    }

    func testRendererCanCompositeRealFieldAssets() throws {
        let root = repoRoot()
        let assets = FieldRenderAssets(
            tileset: .init(
                id: "OVERWORLD",
                imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
                blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": spriteDefinition(id: "SPRITE_RED", filename: "red.png"),
                "SPRITE_OAK": spriteDefinition(id: "SPRITE_OAK", filename: "oak.png"),
            ]
        )
        let map = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0x0B,
            blockWidth: 2,
            blockHeight: 2,
            stepWidth: 4,
            stepHeight: 4,
            tileset: "OVERWORLD",
            blockIDs: [0, 1, 2, 3],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 16),
            warps: [],
            backgroundEvents: [],
            objects: []
        )
        let objects = [
            FieldObjectRenderState(
                id: "oak",
                displayName: "Oak",
                sprite: "SPRITE_OAK",
                position: .init(x: 1, y: 1),
                facing: .left,
                interactionDialogueID: nil,
                trainerBattleID: nil
            ),
        ]

        let image = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: objects,
            assets: assets
        )

        XCTAssertEqual(image.width, 64)
        XCTAssertEqual(image.height, 64)
    }

    private func spriteDefinition(id: String, filename: String) -> FieldSpriteDefinition {
        let root = repoRoot()
        return FieldSpriteDefinition(
            id: id,
            imageURL: root.appendingPathComponent("gfx/sprites/\(filename)"),
            facingFrames: [
                .down: .init(x: 0, y: 0, width: 16, height: 16),
                .up: .init(x: 0, y: 16, width: 16, height: 16),
                .left: .init(x: 0, y: 32, width: 16, height: 16),
                .right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true),
            ]
        )
    }

    private func loadImage(_ url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw XCTSkip("Unable to decode image at \(url.path)")
        }
        return image
    }

    private func averageGrayscale(for image: CGImage) -> Double {
        guard let provider = image.dataProvider,
              let data = provider.data else {
            return 0
        }
        let bytes = CFDataGetBytePtr(data)!
        let length = CFDataGetLength(data)
        guard length > 0 else { return 0 }
        let sum = (0..<length).reduce(0) { partial, index in
            partial + Int(bytes[index])
        }
        return Double(sum) / Double(length)
    }

    private func averageGrayscale(forTopRowsOf image: CGImage, rowCount: Int) -> Double {
        averageGrayscale(in: image, startRow: 0, rowCount: rowCount)
    }

    private func averageGrayscale(forBottomRowsOf image: CGImage, rowCount: Int) -> Double {
        averageGrayscale(in: image, startRow: image.height - rowCount, rowCount: rowCount)
    }

    private func averageGrayscale(in image: CGImage, startRow: Int, rowCount: Int) -> Double {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0
        }

        let bytesPerRow = image.bytesPerRow
        let clampedStartRow = max(0, min(image.height - 1, startRow))
        let clampedRowCount = max(1, min(rowCount, image.height - clampedStartRow))
        var sum = 0
        var count = 0

        for row in clampedStartRow..<(clampedStartRow + clampedRowCount) {
            let rowStart = row * bytesPerRow
            for column in 0..<image.width {
                sum += Int(bytes[rowStart + column])
                count += 1
            }
        }

        guard count > 0 else { return 0 }
        return Double(sum) / Double(count)
    }

    private func makeTestTileImage(topHalf: UInt8, bottomHalf: UInt8) throws -> CGImage {
        let width = 8
        let height = 8
        let bytesPerRow = width
        let topRows = Array(repeating: topHalf, count: width * 4)
        let bottomRows = Array(repeating: bottomHalf, count: width * 4)
        let data = Data(topRows + bottomRows) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw XCTSkip("Unable to create synthetic tile image")
        }
        return image
    }

    private func cropTopLeftTile(from image: CGImage, tileSize: Int, index: Int) throws -> CGImage {
        let columns = max(1, image.width / tileSize)
        let x = (index % columns) * tileSize
        let y = (index / columns) * tileSize
        guard let tile = image.cropping(to: CGRect(x: x, y: y, width: tileSize, height: tileSize)) else {
            throw XCTSkip("Unable to crop tile \(index)")
        }
        return tile
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
