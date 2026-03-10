import XCTest
import ImageIO
import UniformTypeIdentifiers
import SwiftUI
@testable import PokeUI
import PokeDataModel
import PokeCore

@MainActor
final class PokeUITests: XCTestCase {
    func testTitleMenuPanelCanBeConstructed() {
        let view = TitleMenuPanel(entries: [.init(id: "newGame", label: "New Game", enabledByDefault: true)], focusedIndex: 0)
        XCTAssertNotNil(view)
    }

    func testGameBoyPixelTextCanBeConstructed() {
        let view = GameBoyPixelText(
            "TRAINER",
            scale: 2,
            color: .black,
            fallbackFont: .system(size: 12, weight: .bold, design: .monospaced)
        )

        XCTAssertNotNil(view)
    }

    func testDialogueBoxCanBeConstructedWithPixelText() {
        let view = DialogueBoxView(
            title: "Oak",
            lines: ["Hello there!", "Welcome to the world of Pokemon!"]
        )

        XCTAssertNotNil(view)
    }

    func testGameplayFieldShellCanBeConstructed() {
        let view = GameplayFieldShell(
            profile: .init(
                trainerName: "RED",
                locationName: "Pallet Town",
                portrait: .init(label: "RED", spriteURL: nil, spriteFrame: nil),
                badges: [],
                badgeSummaryText: "0/8",
                moneyText: "¥3,000",
                statusItems: ["FIELD", "X4 Y6", "DOWN"]
            ),
            party: .init(
                pokemon: [
                    .init(
                        id: "bulbasaur-0",
                        speciesID: "BULBASAUR",
                        displayName: "Bulbasaur",
                        level: 5,
                        currentHP: 19,
                        maxHP: 19,
                        isLead: true
                    ),
                ]
            ),
            inventory: GameplaySidebarPropsBuilder.makeInventory(),
            save: GameplaySidebarPropsBuilder.makeSaveSection(),
            options: GameplaySidebarPropsBuilder.makeOptionsSection()
        ) {
            FieldMapStage {
                Color.black
            } footer: {
                Text("Dialogue")
            } overlayContent: {
                Text("Overlay")
            }
        }

        XCTAssertNotNil(view)
    }

    func testSidebarPropBuilderMapsEmptyPartyProfile() {
        let profile = GameplaySidebarPropsBuilder.makeProfile(
            trainerName: "RED",
            locationName: "Red's House",
            scene: .field,
            playerPosition: .init(x: 4, y: 4),
            facing: .down,
            portrait: .init(label: "RED", spriteURL: nil, spriteFrame: nil),
            money: 3000,
            ownedBadgeIDs: []
        )
        let party = GameplaySidebarPropsBuilder.makeParty(from: nil)
        let inventory = GameplaySidebarPropsBuilder.makeInventory()

        XCTAssertEqual(profile.moneyText, "¥3,000")
        XCTAssertEqual(profile.badgeSummaryText, "0/8")
        XCTAssertEqual(profile.badges.count, 8)
        XCTAssertEqual(profile.statusItems, ["FIELD", "X4 Y4", "DOWN"])
        XCTAssertTrue(party.pokemon.isEmpty)
        XCTAssertEqual(inventory.emptyStateTitle, "No items yet")
    }

    func testSidebarPropBuilderMapsPartyAfterStarterSelection() {
        let party = PartyTelemetry(
            pokemon: [
                .init(
                    speciesID: "BULBASAUR",
                    displayName: "Bulbasaur",
                    level: 5,
                    currentHP: 19,
                    maxHP: 19,
                    moves: ["TACKLE", "GROWL"]
                ),
            ]
        )
        let speciesDetailsByID = [
            "BULBASAUR": PartySidebarSpeciesDetails(
                spriteURL: URL(fileURLWithPath: "/tmp/bulbasaur.png"),
                primaryType: "GRASS",
                secondaryType: "POISON",
                baseHP: 45,
                baseAttack: 49,
                baseDefense: 49,
                baseSpeed: 45,
                baseSpecial: 65
            ),
        ]
        let moveDisplayNamesByID = [
            "TACKLE": "Tackle",
            "GROWL": "Growl",
        ]

        let profile = GameplaySidebarPropsBuilder.makeProfile(
            trainerName: "RED",
            locationName: "Oak's Lab",
            scene: .starterChoice,
            playerPosition: .init(x: 5, y: 6),
            facing: .up,
            portrait: .init(
                label: "RED",
                spriteURL: URL(fileURLWithPath: "/tmp/red.png"),
                spriteFrame: .init(x: 0, y: 16, width: 16, height: 16)
            ),
            money: 4242,
            ownedBadgeIDs: ["cascade", "boulder"]
        )
        let sidebarParty = GameplaySidebarPropsBuilder.makeParty(
            from: party,
            speciesDetailsByID: speciesDetailsByID,
            moveDisplayNamesByID: moveDisplayNamesByID
        )

        XCTAssertEqual(profile.locationName, "Oak's Lab")
        XCTAssertEqual(profile.moneyText, "¥4,242")
        XCTAssertEqual(profile.badgeSummaryText, "2/8")
        XCTAssertEqual(profile.badges.prefix(2).map(\.isEarned), [true, true])
        XCTAssertEqual(profile.portrait.spriteURL?.path, "/tmp/red.png")
        XCTAssertEqual(sidebarParty.pokemon.count, 1)
        XCTAssertEqual(sidebarParty.pokemon.first?.displayName, "Bulbasaur")
        XCTAssertEqual(sidebarParty.pokemon.first?.level, 5)
        XCTAssertEqual(sidebarParty.pokemon.first?.currentHP, 19)
        XCTAssertEqual(sidebarParty.pokemon.first?.maxHP, 19)
        XCTAssertEqual(sidebarParty.pokemon.first?.isLead, true)
        XCTAssertEqual(sidebarParty.pokemon.first?.typeLabels, ["GRASS", "POISON"])
        XCTAssertEqual(sidebarParty.pokemon.first?.moveNames, ["Tackle", "Growl"])
        XCTAssertEqual(sidebarParty.pokemon.first?.spriteURL?.path, "/tmp/bulbasaur.png")
    }

    func testSidebarExpansionStateKeepsExactlyOneSectionOpen() {
        var expansion = GameplaySidebarExpansionState()

        XCTAssertEqual(expansion.expandedSection, .trainer)

        expansion.activate(.bag)
        XCTAssertEqual(expansion.expandedSection, .bag)

        expansion.activate(.save)
        XCTAssertEqual(expansion.expandedSection, .save)

        expansion.activate(.save)
        XCTAssertEqual(expansion.expandedSection, .save)

        expansion.activate(.options)
        XCTAssertEqual(expansion.expandedSection, .options)
    }

    func testSaveAndOptionsBuildersProduceDisabledRows() {
        let save = GameplaySidebarPropsBuilder.makeSaveSection()
        let options = GameplaySidebarPropsBuilder.makeOptionsSection()

        XCTAssertEqual(save.actions.map(\.title), ["Save Game", "Load Save"])
        XCTAssertTrue(save.actions.allSatisfy { $0.isEnabled == false })
        XCTAssertEqual(options.rows.map(\.title), ["Text Speed", "Battle Scene", "Battle Style", "Sound"])
        XCTAssertTrue(options.rows.allSatisfy { $0.isEnabled == false })
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

    func testRendererTreatsWhiteSpritePixelsAsTransparentInsteadOfMultiplying() throws {
        let fixtureRoot = try makeSyntheticFieldFixture(tileValue: 85, spriteBodyValue: 170)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }

        let assets = FieldRenderAssets(
            tileset: .init(
                id: "TEST",
                imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
                blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
            ),
            overworldSprites: [
                "SPRITE_RED": FieldSpriteDefinition(
                    id: "SPRITE_RED",
                    imageURL: fixtureRoot.appendingPathComponent("sprite.png"),
                    facingFrames: [
                        .down: .init(x: 0, y: 0, width: 16, height: 16),
                        .up: .init(x: 0, y: 0, width: 16, height: 16),
                        .left: .init(x: 0, y: 0, width: 16, height: 16),
                        .right: .init(x: 0, y: 0, width: 16, height: 16),
                    ]
                ),
            ]
        )
        let map = MapManifest(
            id: "TEST_MAP",
            displayName: "Test Map",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 2,
            stepHeight: 2,
            tileset: "TEST",
            blockIDs: [0],
            stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
            warps: [],
            backgroundEvents: [],
            objects: []
        )

        let image = try FieldSceneRenderer.render(
            map: map,
            playerPosition: .init(x: 0, y: 0),
            playerFacing: .down,
            playerSpriteID: "SPRITE_RED",
            objects: [],
            assets: assets
        )

        XCTAssertEqual(grayscaleValues(in: image), Set([85, 170]))
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

    private func grayscaleValues(in image: CGImage) -> Set<Int> {
        guard let provider = image.dataProvider,
              let data = provider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        var values: Set<Int> = []
        for row in 0..<image.height {
            let rowStart = row * image.bytesPerRow
            for column in 0..<image.width {
                values.insert(Int(bytes[rowStart + column]))
            }
        }
        return values
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

    private func makeSyntheticFieldFixture(tileValue: UInt8, spriteBodyValue: UInt8) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let tilesetPixels = Array(repeating: tileValue, count: 8 * 8)
        try writeGrayscalePNG(
            width: 8,
            height: 8,
            pixels: tilesetPixels,
            to: root.appendingPathComponent("tileset.png")
        )

        var spritePixels = Array(repeating: UInt8(255), count: 16 * 16)
        for y in 4..<12 {
            for x in 4..<12 {
                spritePixels[(y * 16) + x] = spriteBodyValue
            }
        }
        try writeGrayscalePNG(
            width: 16,
            height: 16,
            pixels: spritePixels,
            to: root.appendingPathComponent("sprite.png")
        )

        try Data(Array(repeating: UInt8(0), count: 16)).write(to: root.appendingPathComponent("test.bst"))
        return root
    }

    private func writeGrayscalePNG(width: Int, height: Int, pixels: [UInt8], to url: URL) throws {
        let bytesPerRow = width
        let data = Data(pixels) as CFData
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
              ),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw XCTSkip("Unable to write grayscale PNG fixture")
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw XCTSkip("Unable to finalize PNG fixture at \(url.path)")
        }
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
