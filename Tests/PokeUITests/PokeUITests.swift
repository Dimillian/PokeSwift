import ImageIO
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
}
