import ImageIO
import PokeDataModel
import PokeRender
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeRender

@MainActor
extension PokeRenderTests {
  func testPixelAssetMaskKeepsInteriorWhiteHighlightsOpaque() throws {
    let image = try makeRGBAImage(
      width: 5,
      height: 5,
      pixels: [
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255,
        255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255,
      ]
    )

    guard let maskedImage = PixelAssetMasking.applyWhiteTransparencyMask(to: image) else {
      return XCTFail("Expected white background masking to succeed")
    }

    let background = RGBTriplet(red: 255, green: 0, blue: 0)
    let compositedImage = try renderRGBAImage(maskedImage, background: background)
    let corner = rgbValue(in: compositedImage, x: 0, y: 0)

    XCTAssertEqual(alphaValue(in: maskedImage, x: 0, y: 0), 0)
    XCTAssertEqual(rgbValue(in: maskedImage, x: 0, y: 0), .init(red: 0, green: 0, blue: 0))
    XCTAssertGreaterThan(Int(corner.red), 200)
    XCTAssertLessThan(Int(corner.green), 64)
    XCTAssertLessThan(Int(corner.blue), 16)
    XCTAssertEqual(rgbValue(in: compositedImage, x: 1, y: 1), .init(red: 0, green: 0, blue: 0))
    XCTAssertEqual(
      rgbValue(in: compositedImage, x: 2, y: 2), .init(red: 255, green: 255, blue: 255))
  }

  func testSimpleWhiteMaskClearsInteriorWhitePixelsToo() throws {
    let image = try makeRGBAImage(
      width: 3,
      height: 3,
      pixels: [
        0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 255,
        0, 0, 0, 255, 255, 255, 255, 255, 0, 0, 0, 255,
      ]
    )

    guard
      let maskedImage = PixelAssetMasking.applyWhiteTransparencyMask(
        to: image,
        strategy: .allWhitePixels
      )
    else {
      return XCTFail("Expected simple white masking to succeed")
    }

    XCTAssertEqual(alphaValue(in: maskedImage, x: 1, y: 1), 0)
    XCTAssertEqual(alphaValue(in: maskedImage, x: 1, y: 0), 0)
    XCTAssertEqual(alphaValue(in: maskedImage, x: 0, y: 0), 255)
  }
}
