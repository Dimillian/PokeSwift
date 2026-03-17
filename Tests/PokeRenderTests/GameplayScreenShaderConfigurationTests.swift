import XCTest
import PokeDataModel

@testable import PokeRender

@MainActor
extension PokeRenderTests {
  func testGameplayScreenEffectConfigurationTracksFieldViewportInputs() {
    let configuration = GameplayScreenEffectConfiguration(
      displayStyle: .dmgAuthentic,
      displayScale: 3,
      hdrBoost: 0.14
    )

    XCTAssertEqual(configuration.viewportWidth, 480, accuracy: 0.0001)
    XCTAssertEqual(configuration.viewportHeight, 432, accuracy: 0.0001)
    XCTAssertEqual(configuration.pixelScale, 3, accuracy: 0.0001)
    XCTAssertEqual(configuration.preset, 1, accuracy: 0.0001)
    XCTAssertEqual(configuration.hdrBoost, 0.14, accuracy: 0.0001)
    XCTAssertEqual(configuration.introStyle, 0, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents.count, 12)
    XCTAssertEqual(configuration.fieldArguments.count, 17)
  }

  func testGameplayScreenEffectConfigurationUsesResolvedFieldPaletteForGBCMode() {
    let configuration = GameplayScreenEffectConfiguration(
      displayStyle: .gbcCompatibility,
      displayScale: 2,
      hdrBoost: 0,
      fieldPalette: .init(
        id: "PAL_TEST",
        colors: [
          .init(red: 31, green: 29, blue: 31),
          .init(red: 21, green: 28, blue: 11),
          .init(red: 20, green: 26, blue: 31),
          .init(red: 3, green: 2, blue: 2),
        ]
      )
    )

    XCTAssertEqual(configuration.preset, 3, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldArguments.count, 17)
    XCTAssertEqual(configuration.fieldPaletteComponents[0], 1, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents[1], 29.0 / 31.0, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents[2], 1, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents[9], 3.0 / 31.0, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents[10], 2.0 / 31.0, accuracy: 0.0001)
    XCTAssertEqual(configuration.fieldPaletteComponents[11], 2.0 / 31.0, accuracy: 0.0001)
  }

  func testGameplayScreenEffectConfigurationTracksBattleInputs() {
    let presentation = BattlePresentationTelemetry(
      stage: .introSpiral,
      revision: 7,
      uiVisibility: .visible,
      activeSide: .enemy,
      transitionStyle: .spiral
    )
    let configuration = GameplayScreenEffectConfiguration(
      displayStyle: .dmgTinted,
      displayScale: 2,
      hdrBoost: 0.22,
      presentation: presentation,
      introProgress: 0.5,
      introAmount: 1
    )

    XCTAssertEqual(configuration.preset, 2, accuracy: 0.0001)
    XCTAssertEqual(configuration.introStyle, 2, accuracy: 0.0001)
    XCTAssertEqual(configuration.introProgress, 0.5, accuracy: 0.0001)
    XCTAssertEqual(configuration.introAmount, 1, accuracy: 0.0001)
    XCTAssertEqual(configuration.battleArguments.count, 8)
  }

  func testGameplayScreenEffectConfigurationKeepsGBCPresetForBattleInputs() {
    let presentation = BattlePresentationTelemetry(
      stage: .commandReady,
      revision: 4,
      uiVisibility: .visible
    )
    let configuration = GameplayScreenEffectConfiguration(
      displayStyle: .gbcCompatibility,
      displayScale: 2,
      hdrBoost: 0,
      presentation: presentation
    )

    XCTAssertEqual(configuration.preset, 3, accuracy: 0.0001)
    XCTAssertEqual(configuration.introStyle, 0, accuracy: 0.0001)
    XCTAssertEqual(configuration.battleArguments.count, 8)
  }

  func testGameplayScreenEffectConfigurationLeavesNonSpiralBattleTransitionsUntinted() {
    let presentation = BattlePresentationTelemetry(
      stage: .commandReady,
      revision: 3,
      uiVisibility: .visible,
      activeSide: .player,
      transitionStyle: .circle
    )
    let configuration = GameplayScreenEffectConfiguration(
      displayStyle: .rawGrayscale,
      displayScale: 1,
      hdrBoost: 0,
      presentation: presentation
    )

    XCTAssertEqual(configuration.preset, 0, accuracy: 0.0001)
    XCTAssertEqual(configuration.introStyle, 0, accuracy: 0.0001)
    XCTAssertEqual(configuration.introProgress, 1, accuracy: 0.0001)
    XCTAssertEqual(configuration.introAmount, 0, accuracy: 0.0001)
  }
}
