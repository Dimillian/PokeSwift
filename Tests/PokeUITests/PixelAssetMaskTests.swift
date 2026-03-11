import ImageIO
import PokeCore
import PokeDataModel
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeUI

@MainActor
extension PokeUITests {
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

    guard let maskedImage = PixelAssetView.applyWhiteTransparencyMask(to: image) else {
      return XCTFail("Expected white background masking to succeed")
    }

    let background = RGBTriplet(red: 255, green: 0, blue: 0)
    let compositedImage = try renderRGBAImage(maskedImage, background: background)
    let corner = rgbValue(in: compositedImage, x: 0, y: 0)

    XCTAssertGreaterThan(Int(corner.red), 200)
    XCTAssertLessThan(Int(corner.green), 64)
    XCTAssertLessThan(Int(corner.blue), 16)
    XCTAssertEqual(rgbValue(in: compositedImage, x: 1, y: 1), .init(red: 0, green: 0, blue: 0))
    XCTAssertEqual(
      rgbValue(in: compositedImage, x: 2, y: 2), .init(red: 255, green: 255, blue: 255))
  }
}
