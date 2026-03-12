import ImageIO
import PokeCore
import PokeDataModel
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeUI

@MainActor
extension PokeUITests {
  func testFieldDisplayStyleLabelsRemainStableForSidebarSwitcher() {
    XCTAssertEqual(FieldDisplayStyle.defaultGameplayStyle, .dmgTinted)
    XCTAssertEqual(FieldDisplayStyle.dmgAuthentic.sidebarSummaryLabel, "DMG")
    XCTAssertEqual(FieldDisplayStyle.dmgTinted.sidebarSummaryLabel, "TINTED")
    XCTAssertEqual(FieldDisplayStyle.rawGrayscale.sidebarSummaryLabel, "RAW")
    XCTAssertEqual(FieldDisplayStyle.dmgAuthentic.sidebarOptionTitle, "Authentic DMG")
    XCTAssertEqual(FieldDisplayStyle.dmgTinted.sidebarOptionTitle, "Tinted")
    XCTAssertEqual(FieldDisplayStyle.rawGrayscale.sidebarOptionTitle, "Raw Gray")
  }
  func testFieldSceneRenderTaskIdentityIgnoresPurePositionChanges() {
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
      FieldObjectRenderState(
        id: "oak",
        displayName: "Oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        interactionDialogueID: nil,
        trainerBattleID: nil
      )
    ]

    let movedObjects = [
      FieldObjectRenderState(
        id: "oak",
        displayName: "Oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 0, y: 0),
        facing: .left,
        interactionDialogueID: nil,
        trainerBattleID: nil
      )
    ]

    let initialIdentity = FieldMapView.sceneRenderTaskIdentity(
      map: map,
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: objects,
      renderAssets: assets
    )
    let movedIdentity = FieldMapView.sceneRenderTaskIdentity(
      map: map,
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: movedObjects,
      renderAssets: assets
    )

    XCTAssertEqual(initialIdentity, movedIdentity)
  }
  func testFieldSceneRenderTaskIdentityTracksFacingChanges() {
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
      FieldObjectRenderState(
        id: "oak",
        displayName: "Oak",
        sprite: "SPRITE_OAK",
        position: .init(x: 1, y: 1),
        facing: .left,
        interactionDialogueID: nil,
        trainerBattleID: nil
      )
    ]

    let downIdentity = FieldMapView.sceneRenderTaskIdentity(
      map: map,
      playerFacing: .down,
      playerSpriteID: "SPRITE_RED",
      objects: objects,
      renderAssets: assets
    )
    let upIdentity = FieldMapView.sceneRenderTaskIdentity(
      map: map,
      playerFacing: .up,
      playerSpriteID: "SPRITE_RED",
      objects: objects,
      renderAssets: assets
    )

    XCTAssertNotEqual(downIdentity, upIdentity)
  }
  func testFieldSceneMetricsUseFixedGameplayViewportPadding() {
    let metrics = FieldSceneRenderer.sceneMetrics(
      for: makePaletteMap(blockWidth: 2, blockHeight: 2))

    XCTAssertEqual(FieldSceneRenderer.viewportPixelSize, .init(width: 160, height: 144))
    XCTAssertEqual(metrics.mapPixelSize, .init(width: 64, height: 64))
    XCTAssertEqual(metrics.paddingPixels, .init(width: 160, height: 160))
    XCTAssertEqual(metrics.contentPixelSize, .init(width: 384, height: 384))
  }
  func testFieldCameraTargetsCenteredPlayerInFixedViewport() {
    let map = makePaletteMap(blockWidth: 10, blockHeight: 9)
    let metrics = FieldSceneRenderer.sceneMetrics(for: map)
    let playerWorld = FieldSceneRenderer.playerWorldPosition(
      for: .init(x: 8, y: 7), metrics: metrics)

    let camera = FieldCameraState.target(
      playerWorldPosition: playerWorld,
      contentPixelSize: metrics.contentPixelSize
    )

    XCTAssertEqual(camera.origin, .init(x: 216, y: 208))
    XCTAssertEqual(camera.viewportSize, FieldSceneRenderer.viewportPixelSize)
  }
  func testFieldCameraKeepsSmallMapsInsideBorderPaddedScene() {
    let map = makePaletteMap(blockWidth: 1, blockHeight: 1)
    let metrics = FieldSceneRenderer.sceneMetrics(for: map)
    let playerWorld = FieldSceneRenderer.playerWorldPosition(
      for: .init(x: 0, y: 0), metrics: metrics)

    let camera = FieldCameraState.target(
      playerWorldPosition: playerWorld,
      contentPixelSize: metrics.contentPixelSize
    )

    XCTAssertGreaterThan(camera.origin.x, 0)
    XCTAssertGreaterThan(camera.origin.y, 0)
    XCTAssertLessThanOrEqual(
      camera.origin.x + camera.viewportSize.width, metrics.contentPixelSize.width)
    XCTAssertLessThanOrEqual(
      camera.origin.y + camera.viewportSize.height, metrics.contentPixelSize.height)
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
    XCTAssertEqual(
      definition.frame(for: .right),
      .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true))
  }
  func testSpriteFrameLookupUsesWalkingFramesWhenRequested() {
    let definition = spriteDefinition(id: "SPRITE_RED", filename: "red.png")

    XCTAssertEqual(
      definition.frame(for: .down, isWalking: true), .init(x: 0, y: 48, width: 16, height: 16))
    XCTAssertEqual(
      definition.frame(for: .up, isWalking: true), .init(x: 0, y: 64, width: 16, height: 16))
    XCTAssertEqual(
      definition.frame(for: .right, isWalking: true),
      .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true))
  }
  func testPlayerWalkFrameUsesSourceFourPhaseCadence() {
    let stepDuration = 16.0 / 60.0

    XCTAssertEqual(FieldMapView.playerWalkAnimationPhase(elapsed: 0, stepDuration: stepDuration), 0)
    XCTAssertEqual(
      FieldMapView.playerWalkAnimationPhase(
        elapsed: stepDuration * 0.30, stepDuration: stepDuration), 1)
    XCTAssertEqual(
      FieldMapView.playerWalkAnimationPhase(
        elapsed: stepDuration * 0.55, stepDuration: stepDuration), 2)
    XCTAssertEqual(
      FieldMapView.playerWalkAnimationPhase(
        elapsed: stepDuration * 0.80, stepDuration: stepDuration), 3)
    XCTAssertNil(
      FieldMapView.playerWalkAnimationPhase(elapsed: stepDuration, stepDuration: stepDuration))

    XCTAssertFalse(FieldMapView.playerUsesWalkingFrame(phase: 0))
    XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 1))
    XCTAssertFalse(FieldMapView.playerUsesWalkingFrame(phase: 2))
    XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 3))
  }
  func testChainedWalkPhaseOffsetStartsHeldStrideOnVisibleWalkFrame() {
    let stepDuration = 16.0 / 60.0
    let now = Date()
    let previousStartedAt = now.addingTimeInterval(-stepDuration)

    let phaseOffset = FieldMapView.chainedWalkPhaseOffset(
      previousDirection: .right,
      nextDirection: .right,
      previousStartedAt: previousStartedAt,
      now: now,
      stepDuration: stepDuration
    )

    XCTAssertEqual(phaseOffset, 1)
    XCTAssertEqual(
      FieldMapView.playerWalkAnimationPhase(
        elapsed: 0,
        stepDuration: stepDuration,
        phaseOffset: phaseOffset
      ),
      1
    )
    XCTAssertTrue(FieldMapView.playerUsesWalkingFrame(phase: 1))
  }
  func testChainedWalkPhaseOffsetDoesNotCarryAcrossTurnsOrDelayedSteps() {
    let stepDuration = 16.0 / 60.0
    let now = Date()

    XCTAssertEqual(
      FieldMapView.chainedWalkPhaseOffset(
        previousDirection: .right,
        nextDirection: .up,
        previousStartedAt: now.addingTimeInterval(-stepDuration),
        now: now,
        stepDuration: stepDuration
      ),
      0
    )

    XCTAssertEqual(
      FieldMapView.chainedWalkPhaseOffset(
        previousDirection: .right,
        nextDirection: .right,
        previousStartedAt: now.addingTimeInterval(-(stepDuration * 2)),
        now: now,
        stepDuration: stepDuration
      ),
      0
    )
  }
  func testPlayerStepAnimationIsRetainedDuringNpcOnlyUpdatesWhileStepIsActive() {
    let stepDuration = 16.0 / 60.0
    let now = Date()

    XCTAssertTrue(
      FieldMapView.shouldRetainPlayerStepAnimation(
        currentDestinationPosition: .init(x: 10, y: 7),
        startedAt: now.addingTimeInterval(-(stepDuration * 0.5)),
        nextPlayerPosition: .init(x: 10, y: 7),
        now: now,
        stepDuration: stepDuration
      )
    )
  }
  func testPlayerStepAnimationIsNotRetainedAfterStepFinishesOrPlayerChangesTile() {
    let stepDuration = 16.0 / 60.0
    let now = Date()

    XCTAssertFalse(
      FieldMapView.shouldRetainPlayerStepAnimation(
        currentDestinationPosition: .init(x: 10, y: 7),
        startedAt: now.addingTimeInterval(-(stepDuration * 1.1)),
        nextPlayerPosition: .init(x: 10, y: 7),
        now: now,
        stepDuration: stepDuration
      )
    )

    XCTAssertFalse(
      FieldMapView.shouldRetainPlayerStepAnimation(
        currentDestinationPosition: .init(x: 10, y: 7),
        startedAt: now.addingTimeInterval(-(stepDuration * 0.5)),
        nextPlayerPosition: .init(x: 11, y: 7),
        now: now,
        stepDuration: stepDuration
      )
    )
  }
  func testPlayerWalkFrameMirrorsSecondStepForVerticalMovement() {
    XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .left, phase: 3))
    XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .right, phase: 3))
    XCTAssertFalse(FieldMapView.playerUsesMirroredWalkingFrame(facing: .down, phase: 1))
    XCTAssertTrue(FieldMapView.playerUsesMirroredWalkingFrame(facing: .down, phase: 3))
    XCTAssertTrue(FieldMapView.playerUsesMirroredWalkingFrame(facing: .up, phase: 3))
  }
  func testConnectedStepDirectionResolvesNorthBoundaryCrossing() {
    let route1 = MapManifest(
      id: "ROUTE_1",
      displayName: "Route 1",
      defaultMusicID: "MUSIC_ROUTES1",
      borderBlockID: 0,
      blockWidth: 5,
      blockHeight: 4,
      stepWidth: 10,
      stepHeight: 8,
      tileset: "TEST",
      blockIDs: Array(repeating: 0, count: 20),
      stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
      warps: [],
      backgroundEvents: [],
      objects: []
    )
    let palletTown = MapManifest(
      id: "PALLET_TOWN",
      displayName: "Pallet Town",
      defaultMusicID: "MUSIC_PALLET_TOWN",
      borderBlockID: 0,
      blockWidth: 5,
      blockHeight: 4,
      stepWidth: 10,
      stepHeight: 8,
      tileset: "TEST",
      blockIDs: Array(repeating: 0, count: 20),
      stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
      warps: [],
      backgroundEvents: [],
      objects: [],
      connections: [
        .init(
          direction: .north,
          targetMapID: "ROUTE_1",
          offset: 1,
          targetBlockWidth: route1.blockWidth,
          targetBlockHeight: route1.blockHeight,
          targetBlockIDs: route1.blockIDs
        )
      ]
    )

    XCTAssertEqual(
      FieldMapView.connectedStepDirection(
        from: palletTown,
        previousPosition: .init(x: 6, y: 0),
        to: route1,
        nextPosition: .init(x: 4, y: 7)
      ),
      .up
    )
  }
  func testConnectedStepDirectionRejectsNonMatchingBoundarySwap() {
    let route1 = makePaletteMap(blockWidth: 5, blockHeight: 4)
    let palletTown = MapManifest(
      id: "PALLET_TOWN",
      displayName: "Pallet Town",
      defaultMusicID: "MUSIC_PALLET_TOWN",
      borderBlockID: 0,
      blockWidth: 5,
      blockHeight: 4,
      stepWidth: 10,
      stepHeight: 8,
      tileset: "TEST",
      blockIDs: Array(repeating: 0, count: 20),
      stepCollisionTileIDs: Array(repeating: 0x00, count: 80),
      warps: [],
      backgroundEvents: [],
      objects: [],
      connections: [
        .init(
          direction: .north,
          targetMapID: route1.id,
          offset: 0,
          targetBlockWidth: route1.blockWidth,
          targetBlockHeight: route1.blockHeight,
          targetBlockIDs: route1.blockIDs
        )
      ]
    )

    XCTAssertNil(
      FieldMapView.connectedStepDirection(
        from: palletTown,
        previousPosition: .init(x: 4, y: 1),
        to: route1,
        nextPosition: .init(x: 4, y: route1.stepHeight - 1)
      )
    )
  }
  func testConnectedStepOriginPositionPlacesStartOneTileBehindDestination() {
    XCTAssertEqual(
      FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 4, y: 7), direction: .up),
      .init(x: 4, y: 8)
    )
    XCTAssertEqual(
      FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 4, y: 0), direction: .down),
      .init(x: 4, y: -1)
    )
    XCTAssertEqual(
      FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 9, y: 3), direction: .left),
      .init(x: 10, y: 3)
    )
    XCTAssertEqual(
      FieldMapView.connectedStepOriginPosition(nextPosition: .init(x: 0, y: 3), direction: .right),
      .init(x: -1, y: 3)
    )
  }
}
