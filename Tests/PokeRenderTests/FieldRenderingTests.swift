import ImageIO
import PokeDataModel
import PokeRender
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeRender

@MainActor
extension PokeRenderTests {
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
      FieldRenderableObjectState(
        id: "oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        movementMode: nil
      )
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
  func testRendererCanCompositeRealFieldAssetsAsRawGrayscale() throws {
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
      FieldRenderableObjectState(
        id: "oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        movementMode: nil
      )
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
    XCTAssertFalse(grayscaleValues(in: image).isEmpty)
  }
  func testRendererPreservesExactPixelsForOverworldBlockEight() throws {
    let root = repoRoot()
    let assets = FieldRenderAssets(
      tileset: .init(
        id: "OVERWORLD",
        imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
        blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
      ),
      overworldSprites: [:]
    )
    let map = makeFieldRegressionMap(
      id: "BLOCK_EIGHT",
      blockWidth: 1,
      blockHeight: 1,
      stepWidth: 2,
      stepHeight: 2,
      borderBlockID: 0,
      tileset: "OVERWORLD",
      blockIDs: [8]
    )

    let image = try FieldSceneRenderer.render(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    let expectedPixels = try assembleReferenceFieldPixels(
      map: map,
      tilesetURL: assets.tileset.imageURL,
      blocksetURL: assets.tileset.blocksetURL,
      paddingBlocks: .init(width: 0, height: 0),
      includeConnections: false
    )

    XCTAssertEqual(grayscalePixels(in: image), expectedPixels)
  }
  func testRenderSceneMatchesReferenceAssemblyForPalletTownBackground() throws {
    let root = repoRoot()
    let assets = FieldRenderAssets(
      tileset: .init(
        id: "OVERWORLD",
        imageURL: root.appendingPathComponent("gfx/tilesets/overworld.png"),
        blocksetURL: root.appendingPathComponent("gfx/blocksets/overworld.bst")
      ),
      overworldSprites: [:]
    )
    let map = try makePalletTownRegressionMap()

    let scene = try FieldSceneRenderer.renderScene(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    let paddingBlocks = FieldPixelSize(
      width: scene.metrics.paddingPixels.width / FieldSceneRenderer.blockPixelSize,
      height: scene.metrics.paddingPixels.height / FieldSceneRenderer.blockPixelSize
    )
    let expectedPixels = try assembleReferenceFieldPixels(
      map: map,
      tilesetURL: assets.tileset.imageURL,
      blocksetURL: assets.tileset.blocksetURL,
      paddingBlocks: paddingBlocks
    )

    XCTAssertEqual(grayscalePixels(in: scene.backgroundImage), expectedPixels)
  }
  func testRenderSceneBuildsBorderPaddedBackgroundAndLayeredActors() throws {
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
        )
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

    let scene = try FieldSceneRenderer.renderScene(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(scene.backgroundImage.width, scene.metrics.contentPixelSize.width)
    XCTAssertEqual(scene.backgroundImage.height, scene.metrics.contentPixelSize.height)
    XCTAssertEqual(scene.actors.count, 1)
    XCTAssertEqual(
      scene.actors.first?.worldPosition,
      FieldSceneRenderer.playerWorldPosition(for: .init(x: 0, y: 0), metrics: scene.metrics))
    XCTAssertEqual(grayscaleValues(in: scene.backgroundImage), Set([85]))
  }
  func testFieldSceneRenderIdentityIgnoresPurePositionChanges() {
    let map = makePaletteMap(blockWidth: 2, blockHeight: 2)
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
    let objects = [
      FieldRenderableObjectState(
        id: "oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        movementMode: nil
      )
    ]
    let movedObjects = [
      FieldRenderableObjectState(
        id: "oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 0, y: 0),
        facing: .left,
        movementMode: nil
      )
    ]

    XCTAssertEqual(
      FieldSceneRenderIdentity(
        map: map,
        playerFacing: .down,
        playerSpriteID: "SPRITE_RED",
        objects: objects,
        assets: assets
      ),
      FieldSceneRenderIdentity(
        map: map,
        playerFacing: .down,
        playerSpriteID: "SPRITE_RED",
        objects: movedObjects,
        assets: assets
      )
    )
  }
  func testFieldSceneRenderIdentityTracksFacingChanges() {
    let map = makePaletteMap(blockWidth: 2, blockHeight: 2)
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
    let objects = [
      FieldRenderableObjectState(
        id: "oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        movementMode: nil
      )
    ]

    XCTAssertNotEqual(
      FieldSceneRenderIdentity(
        map: map,
        playerFacing: .down,
        playerSpriteID: "SPRITE_RED",
        objects: objects,
        assets: assets
      ),
      FieldSceneRenderIdentity(
        map: map,
        playerFacing: .up,
        playerSpriteID: "SPRITE_RED",
        objects: objects,
        assets: assets
      )
    )
  }
  func testRenderScenePreSortsActorsForStablePresentationOrder() throws {
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
        "SPRITE_OAK": FieldSpriteDefinition(
          id: "SPRITE_OAK",
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

    let scene = try FieldSceneRenderer.renderScene(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [
        .init(
          id: "oak",
          sprite: "SPRITE_OAK",
          position: .init(x: 0, y: 1),
          facing: .left,
          movementMode: nil
        )
      ],
      assets: assets
    )

    XCTAssertEqual(scene.actors.map(\.id), ["player", "oak"])
  }
  func testRenderSceneOverlaysConnectedMapStripsInsideBorderPadding() throws {
    let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [10, 80, 160])
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
      ),
      overworldSprites: [:]
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
      blockIDs: [1],
      stepCollisionTileIDs: Array(repeating: 0x00, count: 4),
      warps: [],
      backgroundEvents: [],
      objects: [],
      connections: [
        .init(
          direction: .north,
          targetMapID: "TEST_ROUTE",
          offset: 0,
          targetBlockWidth: 1,
          targetBlockHeight: 3,
          targetBlockIDs: [2, 2, 2]
        )
      ]
    )

    let scene = try FieldSceneRenderer.renderScene(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(grayscaleValues(in: scene.backgroundImage), Set([10, 80, 160]))
  }
  func testRendererProducesByteStableRawOutputAcrossRepeatedCalls() throws {
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
        )
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

    let firstImage = try FieldSceneRenderer.render(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [],
      assets: assets
    )
    let secondImage = try FieldSceneRenderer.render(
      map: map,
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(grayscaleValues(in: firstImage), grayscaleValues(in: secondImage))
    XCTAssertEqual(alphaValues(in: firstImage), alphaValues(in: secondImage))
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
        )
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
  func testRendererPreservesRawGrayscaleThresholdBuckets() throws {
    let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [32, 96, 160, 224])
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
      ),
      overworldSprites: [:]
    )

    let image = try FieldSceneRenderer.render(
      map: makePaletteMap(blockWidth: 2, blockHeight: 2),
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(grayscaleValues(in: image), Set([32, 96, 160, 224]))
  }
  func testRendererPreservesDistinctGrayscaleShades() throws {
    let fixtureRoot = try makeSyntheticPaletteFixture(tileValues: [0, 64, 128, 192, 255])
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst")
      ),
      overworldSprites: [:]
    )

    let image = try FieldSceneRenderer.render(
      map: makePaletteMap(blockWidth: 5, blockHeight: 1),
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(grayscaleValues(in: image), Set([0, 64, 128, 192, 255]))
  }
  func testRendererKeepsWhiteSpritePixelsTransparentInRawOutput() throws {
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
        )
      ]
    )

    let image = try FieldSceneRenderer.render(
      map: MapManifest(
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
      ),
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(grayscaleValues(in: image), Set([85, 170]))
  }
  func testRenderSceneKeepsSpriteTransparencyInRawOutput() throws {
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
        )
      ]
    )

    let scene = try FieldSceneRenderer.renderScene(
      map: MapManifest(
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
      ),
      playerPosition: .init(x: 0, y: 0),
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: [],
      assets: assets
    )

    guard let playerActor = scene.actors.first else {
      return XCTFail("Expected layered player actor")
    }

    XCTAssertTrue(alphaValues(in: playerActor.image).contains(0))
    XCTAssertEqual(
      visibleRGBValues(in: playerActor.image),
      Set([RGBTriplet(red: 170, green: 170, blue: 170)])
    )
    XCTAssertNotNil(playerActor.walkingImage)
  }
}

private func makeFieldRegressionMap(
  id: String,
  blockWidth: Int,
  blockHeight: Int,
  stepWidth: Int,
  stepHeight: Int,
  borderBlockID: Int,
  tileset: String,
  blockIDs: [Int]
) -> MapManifest {
  MapManifest(
    id: id,
    displayName: id,
    defaultMusicID: "MUSIC_PALLET_TOWN",
    borderBlockID: borderBlockID,
    blockWidth: blockWidth,
    blockHeight: blockHeight,
    stepWidth: stepWidth,
    stepHeight: stepHeight,
    tileset: tileset,
    blockIDs: blockIDs,
    stepCollisionTileIDs: Array(repeating: 0x00, count: stepWidth * stepHeight),
    warps: [],
    backgroundEvents: [],
    objects: []
  )
}

private func makePalletTownRegressionMap() throws -> MapManifest {
  let blockIDs = try Data(contentsOf: repoRoot().appendingPathComponent("maps/PalletTown.blk"))
    .map(Int.init)
  return makeFieldRegressionMap(
    id: "PALLET_TOWN",
    blockWidth: 10,
    blockHeight: 9,
    stepWidth: 20,
    stepHeight: 18,
    borderBlockID: 0x0B,
    tileset: "OVERWORLD",
    blockIDs: blockIDs
  )
}

private func assembleReferenceFieldPixels(
  map: MapManifest,
  tilesetURL: URL,
  blocksetURL: URL,
  paddingBlocks: FieldPixelSize,
  includeConnections: Bool = true
) throws -> [UInt8] {
  let tilesetImage = try loadImage(tilesetURL)
  let atlasPixels = grayscalePixels(in: tilesetImage)
  let blocksetData = [UInt8](try Data(contentsOf: blocksetURL))
  let atlasColumns = max(1, tilesetImage.width / FieldSceneRenderer.tilePixelSize)
  let tilesPerBlock = FieldSceneRenderer.blockTileWidth * FieldSceneRenderer.blockTileHeight
  let totalBlocksX = map.blockWidth + (paddingBlocks.width * 2)
  let totalBlocksY = map.blockHeight + (paddingBlocks.height * 2)
  let width = totalBlocksX * FieldSceneRenderer.blockPixelSize
  let height = totalBlocksY * FieldSceneRenderer.blockPixelSize
  var pixels = [UInt8](repeating: 0, count: width * height)

  for renderedBlockY in 0..<totalBlocksY {
    for renderedBlockX in 0..<totalBlocksX {
      let mapBlockX = renderedBlockX - paddingBlocks.width
      let mapBlockY = renderedBlockY - paddingBlocks.height
      let blockID = map.blockID(
        atBlockX: mapBlockX,
        blockY: mapBlockY,
        includeConnections: includeConnections
      )
      let blockStart = blockID * tilesPerBlock
      guard blocksetData.indices.contains(blockStart + (tilesPerBlock - 1)) else {
        throw XCTSkip("Missing block \(blockID) in \(blocksetURL.lastPathComponent)")
      }

      for tileRow in 0..<FieldSceneRenderer.blockTileHeight {
        for tileColumn in 0..<FieldSceneRenderer.blockTileWidth {
          let tileIndex = Int(blocksetData[blockStart + (tileRow * FieldSceneRenderer.blockTileWidth) + tileColumn])
          let tileOriginX = (tileIndex % atlasColumns) * FieldSceneRenderer.tilePixelSize
          let tileOriginY = (tileIndex / atlasColumns) * FieldSceneRenderer.tilePixelSize

          for pixelY in 0..<FieldSceneRenderer.tilePixelSize {
            for pixelX in 0..<FieldSceneRenderer.tilePixelSize {
              let sourceIndex = ((tileOriginY + pixelY) * tilesetImage.width) + tileOriginX + pixelX
              let destinationX = (renderedBlockX * FieldSceneRenderer.blockPixelSize)
                + (tileColumn * FieldSceneRenderer.tilePixelSize)
                + pixelX
              let destinationY = (renderedBlockY * FieldSceneRenderer.blockPixelSize)
                + (tileRow * FieldSceneRenderer.tilePixelSize)
                + pixelY
              pixels[(destinationY * width) + destinationX] = atlasPixels[sourceIndex]
            }
          }
        }
      }
    }
  }

  return pixels
}
