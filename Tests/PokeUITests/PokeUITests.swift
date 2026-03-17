import ImageIO
import CoreGraphics
import XCTest

@testable import PokeUI

@MainActor
final class PokeUITests: XCTestCase {
  private let shellDefaultsKey = "pokemac.gameBoyShellStyle"
  private var originalShellStyleRawValue: String?

  override func setUp() {
    super.setUp()
    originalShellStyleRawValue = UserDefaults.standard.string(forKey: shellDefaultsKey)
    UserDefaults.standard.set(GameBoyShellStyle.classic.rawValue, forKey: shellDefaultsKey)
  }

  override func tearDown() {
    if let originalShellStyleRawValue {
      UserDefaults.standard.set(originalShellStyleRawValue, forKey: shellDefaultsKey)
    } else {
      UserDefaults.standard.removeObject(forKey: shellDefaultsKey)
    }
    super.tearDown()
  }

  func testGameplayViewportScaleUsesGBSnapPolicy() {
    XCTAssertEqual(
      GameplayViewportScale.snappedScale(
        for: CGSize(width: 320, height: 288),
        viewportPixelSize: CGSize(width: 160, height: 144)
      ),
      2
    )
    XCTAssertEqual(
      GameplayViewportScale.snappedScale(
        for: CGSize(width: 410, height: 370),
        viewportPixelSize: CGSize(width: 160, height: 144)
      ),
      2
    )
    XCTAssertEqual(
      GameplayViewportScale.snappedScale(
        for: CGSize(width: 120, height: 108),
        viewportPixelSize: CGSize(width: 160, height: 144)
      ),
      0.75,
      accuracy: 0.0001
    )
    XCTAssertEqual(
      GameplayViewportScale.snappedScale(
        for: CGSize(width: .zero, height: 144),
        viewportPixelSize: CGSize(width: 160, height: 144)
      ),
      1
    )
  }
}
