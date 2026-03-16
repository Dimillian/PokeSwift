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
  func testWaterAnimationFramesFollowSourceShiftSequence() throws {
    let baseRow: [UInt8] = [0, 30, 60, 90, 120, 150, 180, 210]
    let fixtureRoot = try makeAnimatedFieldFixture(
      tilePixelsByIndex: [0x14: repeatedTilePixels(fromRow: baseRow)],
      blockDefinitions: [[UInt8](repeating: 0x14, count: 16)]
    )
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let tileset = FieldTilesetDefinition(
      id: "TEST",
      imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
      blocksetURL: fixtureRoot.appendingPathComponent("test.bst"),
      animation: .init(kind: .water, animatedTiles: [.init(tileID: 0x14)])
    )
    let expectedRows: [[UInt8]] = [
      [0, 30, 60, 90, 120, 150, 180, 210],
      [210, 0, 30, 60, 90, 120, 150, 180],
      [180, 210, 0, 30, 60, 90, 120, 150],
      [150, 180, 210, 0, 30, 60, 90, 120],
      [180, 210, 0, 30, 60, 90, 120, 150],
      [210, 0, 30, 60, 90, 120, 150, 180],
      [0, 30, 60, 90, 120, 150, 180, 210],
      [30, 60, 90, 120, 150, 180, 210, 0],
    ]

    for frameIndex in expectedRows.indices {
      let image = try XCTUnwrap(
        FieldSceneRenderer.animatedOverlayImage(
          for: FieldRenderedScene(
            mapID: "TEST",
            tileset: tileset,
            metrics: .init(
              mapPixelSize: .init(width: 8, height: 8),
              paddingPixels: .init(width: 0, height: 0),
              contentPixelSize: .init(width: 8, height: 8)
            ),
            backgroundImage: try loadImage(fixtureRoot.appendingPathComponent("tileset.png")),
            animatedTilePlacements: [.init(tileID: 0x14, worldPosition: .init(x: 0, y: 0), size: .init(width: 8, height: 8))],
            actors: []
          ),
          visualState: .init(waterFrameIndex: frameIndex, flowerFrameIndex: nil)
        )
      )
      XCTAssertEqual(
        redChannelPixels(in: image),
        repeatedTilePixels(fromRow: expectedRows[frameIndex])
      )
    }
  }
  func testRenderSceneCollectsAnimatedTilePlacementsFromBorderPadding() throws {
    let fixtureRoot = try makeAnimatedFieldFixture(
      tilePixelsByIndex: [
        0: repeatedTilePixels(20),
        0x14: repeatedTilePixels(180),
      ],
      blockDefinitions: [
        [UInt8](repeating: 0, count: 16),
        [UInt8](repeating: 0x14, count: 16),
      ]
    )
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst"),
        animation: .init(kind: .water, animatedTiles: [.init(tileID: 0x14)])
      ),
      overworldSprites: [:]
    )
    let map = MapManifest(
      id: "TEST_MAP",
      displayName: "Test Map",
      defaultMusicID: "MUSIC_PALLET_TOWN",
      borderBlockID: 1,
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
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )

    XCTAssertEqual(scene.animatedTilePlacements.count, 120 * 16)
    XCTAssertTrue(scene.animatedTilePlacements.contains { $0.worldPosition.x < scene.metrics.paddingPixels.width })
    XCTAssertTrue(scene.animatedTilePlacements.contains { $0.worldPosition.y < scene.metrics.paddingPixels.height })
    XCTAssertFalse(
      scene.animatedTilePlacements.contains {
        ($0.worldPosition.x >= scene.metrics.paddingPixels.width)
          && ($0.worldPosition.x < scene.metrics.paddingPixels.width + FieldSceneRenderer.blockPixelSize)
          && ($0.worldPosition.y >= scene.metrics.paddingPixels.height)
          && ($0.worldPosition.y < scene.metrics.paddingPixels.height + FieldSceneRenderer.blockPixelSize)
      }
    )
  }
  func testRenderSceneCollectsAnimatedTilePlacementsFromConnectionPadding() throws {
    let fixtureRoot = try makeAnimatedFieldFixture(
      tilePixelsByIndex: [
        0: repeatedTilePixels(20),
        0x14: repeatedTilePixels(180),
      ],
      blockDefinitions: [
        [UInt8](repeating: 0, count: 16),
        [UInt8](repeating: 0x14, count: 16),
      ]
    )
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst"),
        animation: .init(kind: .water, animatedTiles: [.init(tileID: 0x14)])
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
          targetBlockIDs: [1, 1, 1]
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

    XCTAssertEqual(scene.animatedTilePlacements.count, 64)
    XCTAssertEqual(
      scene.animatedTilePlacements.filter { $0.worldPosition.y < scene.metrics.paddingPixels.height }.count,
      48
    )
    XCTAssertTrue(
      scene.animatedTilePlacements.contains {
        $0.worldPosition.x == scene.metrics.paddingPixels.width
          && $0.worldPosition.y < scene.metrics.paddingPixels.height
      }
    )
  }
  func testAnimatedOverlayImageUsesTransparentBackgroundAndWorldCoordinates() throws {
    let fixtureRoot = try makeAnimatedFieldFixture(
      tilePixelsByIndex: [
        0: repeatedTilePixels(20),
        0x14: repeatedTilePixels(180),
      ],
      blockDefinitions: [
        [UInt8](repeating: 0, count: 16),
        [UInt8](repeating: 0x14, count: 16),
      ]
    )
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let assets = FieldRenderAssets(
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst"),
        animation: .init(kind: .water, animatedTiles: [.init(tileID: 0x14)])
      ),
      overworldSprites: [:]
    )
    let map = MapManifest(
      id: "TEST_MAP",
      displayName: "Test Map",
      defaultMusicID: "MUSIC_PALLET_TOWN",
      borderBlockID: 1,
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
      playerSpriteID: "MISSING",
      objects: [],
      assets: assets
    )
    let image = try XCTUnwrap(
      FieldSceneRenderer.animatedOverlayImage(
        for: scene,
        visualState: .init(waterFrameIndex: 0, flowerFrameIndex: nil)
      )
    )

    XCTAssertEqual(image.width, scene.metrics.contentPixelSize.width)
    XCTAssertEqual(image.height, scene.metrics.contentPixelSize.height)
    XCTAssertEqual(alphaValue(in: image, x: scene.metrics.paddingPixels.width + 1, y: scene.metrics.paddingPixels.height + 1), 0)

    let placement = try XCTUnwrap(scene.animatedTilePlacements.first)
    XCTAssertGreaterThan(alphaValue(in: image, x: placement.worldPosition.x, y: placement.worldPosition.y), 0)
    XCTAssertEqual(
      rgbValue(in: image, x: placement.worldPosition.x, y: placement.worldPosition.y),
      .init(red: 180, green: 180, blue: 180)
    )
  }
  func testAnimatedOverlayImageKeepsFlowerTransparentUntilFlowerFrameStarts() throws {
    let fixtureRoot = try makeAnimatedFieldFixture(
      tilePixelsByIndex: [
        0x03: repeatedTilePixels(20),
        0x14: repeatedTilePixels(180),
      ],
      blockDefinitions: [[UInt8]([0x03] + Array(repeating: 0x14, count: 15))],
      flowerFrames: [40, 80, 120]
    )
    defer { try? FileManager.default.removeItem(at: fixtureRoot) }

    let scene = FieldRenderedScene(
      mapID: "TEST",
      tileset: .init(
        id: "TEST",
        imageURL: fixtureRoot.appendingPathComponent("tileset.png"),
        blocksetURL: fixtureRoot.appendingPathComponent("test.bst"),
        animation: .init(
          kind: .waterFlower,
          animatedTiles: [
            .init(tileID: 0x14),
            .init(
              tileID: 0x03,
              frameImageURLs: [
                fixtureRoot.appendingPathComponent("flower1.png"),
                fixtureRoot.appendingPathComponent("flower2.png"),
                fixtureRoot.appendingPathComponent("flower3.png"),
              ]
            ),
          ]
        )
      ),
      metrics: .init(
        mapPixelSize: .init(width: 8, height: 8),
        paddingPixels: .init(width: 0, height: 0),
        contentPixelSize: .init(width: 8, height: 8)
      ),
      backgroundImage: try loadImage(fixtureRoot.appendingPathComponent("tileset.png")),
      animatedTilePlacements: [.init(tileID: 0x03, worldPosition: .init(x: 0, y: 0), size: .init(width: 8, height: 8))],
      actors: []
    )

    let preFlower = try XCTUnwrap(
      FieldSceneRenderer.animatedOverlayImage(
        for: scene,
        visualState: .init(waterFrameIndex: 0, flowerFrameIndex: nil)
      )
    )
    let activeFlower = try XCTUnwrap(
      FieldSceneRenderer.animatedOverlayImage(
        for: scene,
        visualState: .init(waterFrameIndex: 1, flowerFrameIndex: 1)
      )
    )

    XCTAssertEqual(alphaValue(in: preFlower, x: 0, y: 0), 0)
    XCTAssertGreaterThan(alphaValue(in: activeFlower, x: 0, y: 0), 0)
    XCTAssertEqual(rgbValue(in: activeFlower, x: 0, y: 0), .init(red: 80, green: 80, blue: 80))
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

private func repeatedTilePixels(_ value: UInt8) -> [UInt8] {
  Array(repeating: value, count: FieldSceneRenderer.tilePixelSize * FieldSceneRenderer.tilePixelSize)
}

private func repeatedTilePixels(fromRow row: [UInt8]) -> [UInt8] {
  Array(repeating: row, count: FieldSceneRenderer.tilePixelSize).flatMap { $0 }
}

private func redChannelPixels(in image: CGImage) -> [UInt8] {
  guard let provider = image.dataProvider,
    let data = provider.data,
    let bytes = CFDataGetBytePtr(data)
  else {
    return []
  }

  var pixels: [UInt8] = []
  pixels.reserveCapacity(image.width * image.height)
  for row in 0..<image.height {
    let rowStart = row * image.bytesPerRow
    for column in 0..<image.width {
      pixels.append(bytes[rowStart + (column * 4)])
    }
  }
  return pixels
}

private func makeAnimatedFieldFixture(
  tilePixelsByIndex: [Int: [UInt8]],
  blockDefinitions: [[UInt8]],
  flowerFrames: [UInt8] = []
) throws -> URL {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(
    UUID().uuidString,
    isDirectory: true
  )
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

  let highestTileIndex = max(tilePixelsByIndex.keys.max() ?? 0, 0)
  let atlasWidth = (highestTileIndex + 1) * FieldSceneRenderer.tilePixelSize
  let atlasHeight = FieldSceneRenderer.tilePixelSize
  let tilePixelCount = FieldSceneRenderer.tilePixelSize * FieldSceneRenderer.tilePixelSize
  var atlasPixels = [UInt8](repeating: 0, count: atlasWidth * atlasHeight)
  for tileIndex in 0...highestTileIndex {
    let tilePixels = tilePixelsByIndex[tileIndex] ?? repeatedTilePixels(0)
    guard tilePixels.count == tilePixelCount else {
      throw XCTSkip("Animated tile fixture \(tileIndex) has invalid pixel count \(tilePixels.count)")
    }

    let tileOriginX = tileIndex * FieldSceneRenderer.tilePixelSize
    for pixelY in 0..<FieldSceneRenderer.tilePixelSize {
      let sourceRowStart = pixelY * FieldSceneRenderer.tilePixelSize
      let destinationRowStart = (pixelY * atlasWidth) + tileOriginX
      atlasPixels.replaceSubrange(
        destinationRowStart..<(destinationRowStart + FieldSceneRenderer.tilePixelSize),
        with: tilePixels[sourceRowStart..<(sourceRowStart + FieldSceneRenderer.tilePixelSize)]
      )
    }
  }

  try writeGrayscalePNG(
    width: atlasWidth,
    height: atlasHeight,
    pixels: atlasPixels,
    to: root.appendingPathComponent("tileset.png")
  )

  let blocksetBytes = blockDefinitions.flatMap { $0 }
  try Data(blocksetBytes).write(to: root.appendingPathComponent("test.bst"))

  for (index, value) in flowerFrames.enumerated() {
    try writeGrayscalePNG(
      width: FieldSceneRenderer.tilePixelSize,
      height: FieldSceneRenderer.tilePixelSize,
      pixels: repeatedTilePixels(value),
      to: root.appendingPathComponent("flower\(index + 1).png")
    )
  }

  return root
}
