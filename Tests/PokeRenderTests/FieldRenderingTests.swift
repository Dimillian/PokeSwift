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
