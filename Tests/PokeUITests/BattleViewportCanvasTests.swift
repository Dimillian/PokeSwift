import XCTest

@testable import PokeUI

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
        side: .enemy
      )
    )
    XCTAssertFalse(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .enemySendOut,
        activeSide: .player,
        side: .player
      )
    )
    XCTAssertTrue(
      BattleViewportCanvas.usesImplicitPokemonRevisionAnimation(
        stage: .attackImpact,
        activeSide: .enemy,
        side: .enemy
      )
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
}
