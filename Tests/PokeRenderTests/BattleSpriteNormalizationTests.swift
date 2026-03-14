import XCTest

@testable import PokeRender

@MainActor
extension PokeRenderTests {
    func testBattleFrontSpriteNormalizationCentersSpriteOnSharedCanvas() throws {
        let image = try makeRGBAImage(
            width: 40,
            height: 40,
            pixels: solidPixels(
                width: 40,
                height: 40,
                color: .init(red: 0, green: 0, blue: 0, alpha: 255)
            )
        )

        guard let normalizedImage = PixelAssetImageProcessing.processImage(
            image,
            whiteIsTransparent: false,
            renderMode: .battlePokemonFront
        ) else {
            return XCTFail("Expected front sprite normalization to succeed")
        }

        XCTAssertEqual(normalizedImage.width, 56)
        XCTAssertEqual(normalizedImage.height, 56)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 0, y: 0), 0)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 7, y: 7), 0)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 8, y: 8), 255)
        XCTAssertEqual(rgbValue(in: normalizedImage, x: 8, y: 8), .init(red: 0, green: 0, blue: 0))
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 47, y: 47), 255)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 48, y: 48), 0)
    }

    func testBattleBackSpriteNormalizationCropsAndScalesToSharedCanvas() throws {
        let image = try makeRGBAImage(width: 32, height: 32, pixels: battleBackFixturePixels())

        guard let normalizedImage = PixelAssetImageProcessing.processImage(
            image,
            whiteIsTransparent: false,
            renderMode: .battlePokemonBack
        ) else {
            return XCTFail("Expected back sprite normalization to succeed")
        }

        XCTAssertEqual(normalizedImage.width, 56)
        XCTAssertEqual(normalizedImage.height, 56)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 0, y: 0), 255)
        XCTAssertEqual(alphaValue(in: normalizedImage, x: 55, y: 55), 255)
        XCTAssertEqual(visibleRGBValues(in: normalizedImage), Set([.init(red: 0, green: 0, blue: 0)]))
    }
}

private func solidPixels(width: Int, height: Int, color: RGBAQuad) -> [UInt8] {
    Array(repeating: color.bytes, count: width * height).flatMap(\.self)
}

private func battleBackFixturePixels() -> [UInt8] {
    var pixels: [UInt8] = []
    pixels.reserveCapacity(32 * 32 * 4)

    for y in 0..<32 {
        for x in 0..<32 {
            let color: RGBAQuad
            if x >= 28 {
                color = .init(red: 255, green: 0, blue: 0, alpha: 255)
            } else if y >= 28 {
                color = .init(red: 0, green: 0, blue: 255, alpha: 255)
            } else {
                color = .init(red: 0, green: 0, blue: 0, alpha: 255)
            }
            pixels.append(contentsOf: color.bytes)
        }
    }

    return pixels
}

private struct RGBAQuad {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    var bytes: [UInt8] {
        [red, green, blue, alpha]
    }
}
