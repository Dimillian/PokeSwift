import XCTest

@testable import PokeUI
import PokeDataModel

@MainActor
extension PokeUITests {
  func testBattleSendOutTimelineResolvesGBStylePhases() {
    XCTAssertEqual(BattleSendOutAnimationTimeline.state(at: nil), .idle)
    XCTAssertEqual(BattleSendOutAnimationTimeline.state(at: 0), .toss(progress: 0))

    guard case let .toss(progress) = BattleSendOutAnimationTimeline.state(
      at: BattleSendOutAnimationTimeline.tossDuration / 2
    ) else {
      return XCTFail("Expected toss progress midway through the toss window")
    }
    XCTAssertEqual(progress, 0.5, accuracy: 0.0001)

    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.tossDuration + 0.01
      ),
      .releaseHold
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.tossDuration +
          BattleSendOutAnimationTimeline.releaseHoldDuration +
          0.01
      ),
      .poof(frameIndex: 0)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.tossDuration +
          BattleSendOutAnimationTimeline.releaseHoldDuration +
          BattleSendOutAnimationTimeline.poofFrameDuration +
          0.01
      ),
      .poof(frameIndex: 1)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.tossDuration +
          BattleSendOutAnimationTimeline.releaseHoldDuration +
          (BattleSendOutAnimationTimeline.poofFrameDuration * 2) +
          0.01
      ),
      .poof(frameIndex: 2)
    )

    let revealStep1Start =
      BattleSendOutAnimationTimeline.tossDuration +
      BattleSendOutAnimationTimeline.releaseHoldDuration +
      (BattleSendOutAnimationTimeline.poofFrameDuration * 3)
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(at: revealStep1Start + 0.01),
      .revealStep1
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: revealStep1Start +
          BattleSendOutAnimationTimeline.revealStep1Duration +
          0.01
      ),
      .revealStep2
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.defaultTotalDuration + 0.01
      ),
      .revealFinal
    )
  }

  func testBattleSendOutTimelineUsesGBScaleSteps() {
    XCTAssertEqual(BattleSendOutVisualState.revealStep1.pokemonScale, 3.0 / 7.0, accuracy: 0.0001)
    XCTAssertEqual(BattleSendOutVisualState.revealStep2.pokemonScale, 5.0 / 7.0, accuracy: 0.0001)
    XCTAssertEqual(BattleSendOutVisualState.revealFinal.pokemonScale, 1.0, accuracy: 0.0001)
    XCTAssertEqual(BattleSendOutVisualState.poof(frameIndex: 2).poofFrameIndex, 2)
    XCTAssertEqual(BattleSendOutVisualState.toss(progress: 1).ballOpacity, 1)
    XCTAssertEqual(BattleSendOutVisualState.revealStep1.ballOpacity, 0)
  }

  func testBattleSendOutRevealUsesCenteredScaleAnchor() {
    XCTAssertEqual(
      BattleViewportCanvas.pokemonScaleAnchor(
        stage: .enemySendOut,
        activeSide: .enemy,
        side: .enemy
      ),
      .center
    )
    XCTAssertEqual(
      BattleViewportCanvas.pokemonScaleAnchor(
        stage: .enemySendOut,
        activeSide: .player,
        side: .player
      ),
      .center
    )
    XCTAssertEqual(
      BattleViewportCanvas.pokemonScaleAnchor(
        stage: .attackImpact,
        activeSide: .enemy,
        side: .enemy
      ),
      .center
    )
  }

  func testBattleSendOutDisablesRevisionDrivenPokemonAnimation() {
    XCTAssertFalse(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .enemySendOut,
        activeSide: .enemy,
        attackAnimation: nil,
        hidePlayerPokemon: false,
        side: .enemy
      )
    )
    XCTAssertFalse(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .enemySendOut,
        activeSide: .player,
        attackAnimation: nil,
        hidePlayerPokemon: false,
        side: .player
      )
    )
    XCTAssertTrue(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .attackImpact,
        activeSide: .enemy,
        attackAnimation: nil,
        hidePlayerPokemon: false,
        side: .enemy
      )
    )
    XCTAssertFalse(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .resultText,
        activeSide: .player,
        attackAnimation: nil,
        hidePlayerPokemon: true,
        side: .player
      )
    )
  }

  func testWildBattlePlayerHUDStaysHiddenUntilSendOutReveal() {
    XCTAssertEqual(
      BattleViewportCanvas.playerHudOpacity(
        battleKind: .wild,
        stage: .introReveal,
        activeSide: nil,
        hidePlayerPokemon: false,
        sendOutPokemonOpacity: 0
      ),
      0
    )
    XCTAssertEqual(
      BattleViewportCanvas.playerHudOpacity(
        battleKind: .wild,
        stage: .enemySendOut,
        activeSide: .player,
        hidePlayerPokemon: false,
        sendOutPokemonOpacity: 0.42
      ),
      0.42,
      accuracy: 0.0001
    )
    XCTAssertEqual(
      BattleViewportCanvas.playerHudOpacity(
        battleKind: .wild,
        stage: .commandReady,
        activeSide: nil,
        hidePlayerPokemon: false,
        sendOutPokemonOpacity: 0
      ),
      1
    )
    XCTAssertEqual(
      BattleViewportCanvas.playerHudOpacity(
        battleKind: .wild,
        stage: .resultText,
        activeSide: .player,
        hidePlayerPokemon: true,
        sendOutPokemonOpacity: 1
      ),
      0
    )
  }

  func testTrainerBattlePartyIndicatorTracksIntroAndEnemySendOut() {
    XCTAssertEqual(
      BattleViewportCanvas.trainerPartyIndicatorOpacity(
        battleKind: .trainer,
        stage: .introReveal,
        activeSide: nil,
        sendOutPokemonOpacity: 0
      ),
      1
    )
    XCTAssertEqual(
      BattleViewportCanvas.trainerPartyIndicatorOpacity(
        battleKind: .trainer,
        stage: .enemySendOut,
        activeSide: .enemy,
        sendOutPokemonOpacity: 0.35
      ),
      0.65,
      accuracy: 0.0001
    )
    XCTAssertEqual(
      BattleViewportCanvas.trainerPartyIndicatorOpacity(
        battleKind: .trainer,
        stage: .commandReady,
        activeSide: nil,
        sendOutPokemonOpacity: 0
      ),
      0
    )
    XCTAssertEqual(
      BattleViewportCanvas.trainerPartyIndicatorOpacity(
        battleKind: .wild,
        stage: .introReveal,
        activeSide: nil,
        sendOutPokemonOpacity: 0
      ),
      0
    )
  }

  func testTrainerPartyIndicatorSlotStatesMarkFaintedStatusedAndEmptySlots() {
    let slotStates = BattleTrainerPartyIndicator.slotStates(
      enemyParty: [
        .init(
          speciesID: "PIDGEY",
          displayName: "Pidgey",
          level: 9,
          currentHP: 20,
          maxHP: 20,
          attack: 12,
          defense: 10,
          speed: 14,
          special: 9,
          moves: ["TACKLE"]
        ),
        .init(
          speciesID: "RATTATA",
          displayName: "Rattata",
          level: 8,
          currentHP: 0,
          maxHP: 18,
          attack: 13,
          defense: 9,
          speed: 15,
          special: 8,
          moves: ["TACKLE"]
        ),
        .init(
          speciesID: "EKANS",
          displayName: "Ekans",
          level: 10,
          currentHP: 23,
          maxHP: 23,
          attack: 14,
          defense: 11,
          speed: 12,
          special: 10,
          majorStatus: .sleep,
          moves: ["WRAP"]
        ),
      ],
      enemyPartyCount: 3,
      totalCount: 6
    )

    XCTAssertEqual(
      slotStates,
      [.occupied, .fainted, .statused, .empty, .empty, .empty]
    )
  }

  func testTrainerPartyIndicatorSlotStatesFallbackToReportedPartyCount() {
    let slotStates = BattleTrainerPartyIndicator.slotStates(
      enemyParty: [],
      enemyPartyCount: 2,
      totalCount: 6
    )

    XCTAssertEqual(
      slotStates,
      [.occupied, .occupied, .empty, .empty, .empty, .empty]
    )
  }

  func testBattlePlayerSpriteHidesWhenPresentationRequestsIt() {
    XCTAssertEqual(
      BattleViewportCanvas.playerPokemonOpacity(
        battleKind: .wild,
        stage: .resultText,
        activeSide: .player,
        hidePlayerPokemon: true,
        playerCurrentHP: 10,
        sendOutPokemonOpacity: 1
      ),
      0
    )
    XCTAssertEqual(
      BattleViewportCanvas.playerPokemonOpacity(
        battleKind: .wild,
        stage: .enemySendOut,
        activeSide: .player,
        hidePlayerPokemon: false,
        playerCurrentHP: 10,
        sendOutPokemonOpacity: 0.5
      ),
      0.5,
      accuracy: 0.0001
    )
  }

  func testBattleAttackTimelineBuildsOverlayFramesAndScreenEffects() {
    let frames = BattleAttackAnimationTimeline.sequence(
      for: makeAttackPlayback(),
      manifest: makeAttackAnimationManifest()
    )

    XCTAssertFalse(frames.isEmpty)
    XCTAssertEqual(frames.first?.state.overlayPlacements.first?.tilesetID, "MOVE_ANIM_TILESET_0")
    XCTAssertEqual(frames.first?.state.overlayPlacements.first?.x, 80)
    XCTAssertEqual(frames.first?.state.overlayPlacements.first?.y, 56)
    XCTAssertTrue(frames.contains { $0.state.flashOpacity > 0 })
  }

  func testBattleAttackTimelineBuildsNativeParticlesForMissingSourceEffects() {
    let particleEffects = [
      "SE_WATER_DROPLETS_EVERYWHERE",
      "SE_SPIRAL_BALLS_INWARD",
      "SE_LEAVES_FALLING",
      "SE_PETALS_FALLING",
      "SE_SHOOT_BALLS_UPWARD",
      "SE_SHOOT_MANY_BALLS_UPWARD",
    ]

    for effectID in particleEffects {
      let frames = BattleAttackAnimationTimeline.sequence(
        for: makeAttackPlayback(moveID: effectID),
        manifest: makeSpecialEffectAnimationManifest(moveID: effectID, effectID: effectID)
      )

      XCTAssertFalse(frames.isEmpty, "\(effectID) should produce keyframes")
      XCTAssertTrue(
        frames.contains { $0.state.particlePlacements.isEmpty == false },
        "\(effectID) should emit native particle placements"
      )
    }
  }

  func testBattleAttackTimelineBuildsTransformVisualStateForTransformEffect() {
    let frames = BattleAttackAnimationTimeline.sequence(
      for: makeAttackPlayback(moveID: "TRANSFORM"),
      manifest: makeSpecialEffectAnimationManifest(
        moveID: "TRANSFORM",
        effectID: "SE_TRANSFORM_MON"
      )
    )

    XCTAssertTrue(frames.contains { $0.state.playerScale != 1 })
    XCTAssertTrue(frames.contains { $0.state.flashOpacity > 0 })
  }

  func testBattleAttackTimelineBuildsEnemyHUDShakeState() {
    let frames = BattleAttackAnimationTimeline.sequence(
      for: makeAttackPlayback(moveID: "HUD_SHAKE"),
      manifest: makeSpecialEffectAnimationManifest(
        moveID: "HUD_SHAKE",
        effectID: "SE_SHAKE_ENEMY_HUD"
      )
    )

    XCTAssertTrue(frames.contains { abs($0.state.enemyHUDOffset.width) > 0.1 })
  }

  func testBattleAttackAnimationDisablesRevisionDrivenAnimationForActiveSide() {
    let playback = makeAttackPlayback()

    XCTAssertFalse(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .attackWindup,
        activeSide: .player,
        attackAnimation: playback,
        hidePlayerPokemon: false,
        side: .player
      )
    )
    XCTAssertTrue(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .attackWindup,
        activeSide: .player,
        attackAnimation: playback,
        hidePlayerPokemon: false,
        side: .enemy
      )
    )
  }

  func testBattleAttackStateResolvesToIdleWhenAnimationKeyIsStale() {
    XCTAssertEqual(
      BattleViewportCanvas.resolvedAttackAnimationState(
        attackAnimation: makeAttackPlayback(playbackID: "attack-2"),
        attackAnimationVisualState: .init(
          playerOffset: .zero,
          enemyOffset: .zero,
          playerScale: 1,
          enemyScale: 1,
          playerOpacity: 1,
          enemyOpacity: 1,
          overlayPlacements: [.init(tilesetID: "MOVE_ANIM_TILESET_0", x: 80, y: 56, tileID: 0, flipH: false, flipV: false)],
          screenShake: .zero,
          flashOpacity: 0,
          darknessOpacity: 0
        ),
        animationTriggerKey: "attack-3",
        activeAnimationKey: "attack-2"
      ),
      .idle
    )
  }

  func testApplyingHitEffectTimelineBuildsGBBlinkSequence() {
    let frames = BattleApplyingHitEffectTimeline.sequence(for: makeApplyingHitEffect())

    XCTAssertEqual(frames.count, 12)
    XCTAssertEqual(frames.first?.state.enemyOpacity, 0)
    XCTAssertEqual(try XCTUnwrap(frames.first?.duration), 5.0 / 60.0, accuracy: 0.0001)
    XCTAssertEqual(frames.dropFirst().first?.state.enemyOpacity, 1)
    XCTAssertEqual(try XCTUnwrap(frames.dropFirst().first?.duration), 8.0 / 60.0, accuracy: 0.0001)
  }

  func testApplyingHitEffectTimelineBuildsVerticalShakeSequence() {
    let frames = BattleApplyingHitEffectTimeline.sequence(
      for: makeApplyingHitEffect(playbackID: "hit-2", kind: .shakeScreenVertical, totalDuration: 48.0 / 60.0)
    )

    XCTAssertEqual(frames.count, 16)
    XCTAssertEqual(Double(try XCTUnwrap(frames.first?.state.screenShake.height)), 8, accuracy: 0.0001)
    XCTAssertEqual(Double(try XCTUnwrap(frames.dropFirst().first?.state.screenShake.height)), 0, accuracy: 0.0001)
  }

  func testApplyingHitEffectStateResolvesToIdleWhenAnimationKeyIsStale() {
    XCTAssertEqual(
      BattleViewportCanvas.resolvedApplyingHitEffectState(
        applyingHitEffect: makeApplyingHitEffect(playbackID: "hit-2"),
        applyingHitEffectVisualState: .init(
          playerOpacity: 1,
          enemyOpacity: 0,
          screenShake: .init(width: 2, height: 0)
        ),
        animationTriggerKey: "hit-3",
        activeAnimationKey: "hit-2"
      ),
      .idle
    )
  }

  func testBattleSendOutStateResolvesToIdleWhenAnimationKeyIsStale() {
    XCTAssertEqual(
      BattleViewportCanvas.resolvedSendOutState(
        stage: .enemySendOut,
        sendOutVisualState: .revealFinal,
        animationTriggerKey: "enemySendOut-player-2",
        activeAnimationKey: "enemySendOut-enemy-1"
      ),
      .idle
    )
  }

  func testBattleSendOutStatePreservesMatchingAnimationKey() {
    XCTAssertEqual(
      BattleViewportCanvas.resolvedSendOutState(
        stage: .enemySendOut,
        sendOutVisualState: .revealStep2,
        animationTriggerKey: "enemySendOut-player-2",
        activeAnimationKey: "enemySendOut-player-2"
      ),
      .revealStep2
    )
  }

  func testBattleSendOutStateResolvesToIdleOutsideSendOutStage() {
    XCTAssertEqual(
      BattleViewportCanvas.resolvedSendOutState(
        stage: .commandReady,
        sendOutVisualState: .revealFinal,
        animationTriggerKey: "commandReady-player-3",
        activeAnimationKey: "commandReady-player-3"
      ),
      .idle
    )
  }

  func testBattleSendOutTimelineUsesExpandedEnemyPoofSequence() {
    let enemyPoofStart =
      BattleSendOutAnimationTimeline.tossDuration +
      BattleSendOutAnimationTimeline.releaseHoldDuration

    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: enemyPoofStart + BattleSendOutAnimationTimeline.poofFrameDuration + 0.01,
        side: .enemy
      ),
      .poof(frameIndex: 1)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: enemyPoofStart + (BattleSendOutAnimationTimeline.poofFrameDuration * 2) + 0.01,
        side: .enemy
      ),
      .poof(frameIndex: 2)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: enemyPoofStart + (BattleSendOutAnimationTimeline.poofFrameDuration * 3) + 0.01,
        side: .enemy
      ),
      .poof(frameIndex: 3)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: enemyPoofStart + (BattleSendOutAnimationTimeline.poofFrameDuration * 4) + 0.01,
        side: .enemy
      ),
      .poof(frameIndex: 4)
    )
    XCTAssertEqual(
      BattleSendOutAnimationTimeline.state(
        at: BattleSendOutAnimationTimeline.totalDuration(for: .enemy) + 0.01,
        side: .enemy
      ),
      .revealFinal
    )
  }

  func testBattleSendOutTimelineUsesSideSpecificPoofFrameStrips() {
    XCTAssertEqual(BattleSendOutAnimationTimeline.enemyPoofFrames.count, 5)
    XCTAssertEqual(BattleSendOutAnimationTimeline.playerPoofFrames.count, 3)
    XCTAssertEqual(BattleSendOutAnimationTimeline.enemyPoofFrames.first?.canvasSize, .init(width: 48, height: 48))
    XCTAssertEqual(BattleSendOutAnimationTimeline.playerPoofFrames.first?.canvasSize, .init(width: 40, height: 40))
    XCTAssertFalse(BattleSendOutAnimationTimeline.enemyPoofFrames.first?.placements.isEmpty ?? true)
    XCTAssertFalse(BattleSendOutAnimationTimeline.playerPoofFrames.first?.placements.isEmpty ?? true)
  }

  func testBattleViewportLayoutUsesBattlefieldAnchorsForSendOut() {
    let layout = BattleViewportLayout(size: .init(width: 160, height: 144))

    XCTAssertEqual(layout.enemySendOutAnchor, layout.enemySpriteCenter)
    XCTAssertEqual(layout.playerSendOutAnchor, layout.playerSpriteCenter)
    XCTAssertLessThan(layout.enemyTrainerPokeballOrigin.x, layout.enemySendOutAnchor.x)
    XCTAssertGreaterThan(layout.playerTrainerPokeballOrigin.x, layout.playerSendOutAnchor.x)
  }

  func testBattleViewportLayoutUsesMatchingPokemonSpriteSlots() {
    let layout = BattleViewportLayout(size: .init(width: 160, height: 144))

    XCTAssertEqual(layout.enemySpriteSize, layout.playerSpriteSize)
    XCTAssertGreaterThan(layout.playerTrainerCenter.y, layout.playerSpriteCenter.y)
  }

  private func makeAttackPlayback(
    playbackID: String = "attack-1",
    moveID: String = "TACKLE"
  ) -> BattleAttackAnimationPlaybackTelemetry {
    .init(
      playbackID: playbackID,
      moveID: moveID,
      attackerSide: .player,
      totalDuration: 0.2
    )
  }

  private func makeApplyingHitEffect(
    playbackID: String = "hit-1",
    kind: BattleApplyingHitEffectKind = .blinkDefender,
    totalDuration: TimeInterval = 78.0 / 60.0
  ) -> BattleApplyingHitEffectTelemetry {
    .init(
      playbackID: playbackID,
      kind: kind,
      attackerSide: .player,
      totalDuration: totalDuration
    )
  }

  private func makeAttackAnimationManifest() -> BattleAnimationManifest {
    .init(
      variant: .red,
      moveAnimations: [
        .init(
          moveID: "TACKLE",
          commands: [
            .init(
              kind: .subanimation,
              soundMoveID: "TACKLE",
              subanimationID: "SUBANIM_TEST",
              specialEffectID: nil,
              tilesetID: "MOVE_ANIM_TILESET_0",
              delayFrames: 2
            ),
            .init(
              kind: .specialEffect,
              soundMoveID: nil,
              subanimationID: nil,
              specialEffectID: "SE_DARK_SCREEN_FLASH",
              tilesetID: nil,
              delayFrames: nil
            ),
          ]
        ),
      ],
      subanimations: [
        .init(
          id: "SUBANIM_TEST",
          transform: .normal,
          steps: [
            .init(frameBlockID: "FRAMEBLOCK_TEST", baseCoordinateID: "BASECOORD_TEST", frameBlockMode: .mode00),
          ]
        ),
      ],
      frameBlocks: [
        .init(id: "FRAMEBLOCK_TEST", tiles: [.init(x: 0, y: 0, tileID: 0)]),
      ],
      baseCoordinates: [
        .init(id: "BASECOORD_TEST", x: 80, y: 56),
      ],
      specialEffects: [
        .init(id: "SE_DARK_SCREEN_FLASH", routine: "AnimationFlashScreen"),
      ],
      tilesets: [
        .init(id: "MOVE_ANIM_TILESET_0", tileCount: 79, imagePath: "Assets/battle/animations/move_anim_0.png"),
      ]
    )
  }

  private func makeSpecialEffectAnimationManifest(
    moveID: String,
    effectID: String
  ) -> BattleAnimationManifest {
    .init(
      variant: .red,
      moveAnimations: [
        .init(
          moveID: moveID,
          commands: [
            .init(
              kind: .specialEffect,
              soundMoveID: nil,
              subanimationID: nil,
              specialEffectID: effectID,
              tilesetID: nil,
              delayFrames: nil
            ),
          ]
        ),
      ],
      subanimations: [],
      frameBlocks: [],
      baseCoordinates: [],
      specialEffects: [
        .init(id: effectID, routine: "TestRoutine"),
      ],
      tilesets: []
    )
  }
}
