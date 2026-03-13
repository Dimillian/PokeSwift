import ImageIO
import PokeDataModel
import PokeRender
import SwiftUI
import UniformTypeIdentifiers
import XCTest

@testable import PokeRender

@MainActor
extension PokeRenderTests {
  func testBlocksetDecoderBuilds4x4BlocksFromRepoData() throws {
    let blocksetURL = repoRoot().appendingPathComponent("gfx/blocksets/overworld.bst")
    let data = try Data(contentsOf: blocksetURL)
    let blockset = try FieldBlockset.decode(data: data)

    XCTAssertEqual(blockset.blockTileWidth, 4)
    XCTAssertEqual(blockset.blockTileHeight, 4)
    XCTAssertEqual(blockset.blocks.count, 128)
    XCTAssertEqual(blockset.blocks.first?.count, 16)
  }
  func testTileAtlasUsesTopLeftOriginForRepoPNGExports() throws {
    let image = try loadImage(repoRoot().appendingPathComponent("gfx/tilesets/overworld.png"))
    let tileZero = try cropTopLeftTile(from: image, tileSize: 8, index: 0)
    XCTAssertGreaterThan(averageGrayscale(for: tileZero), 240)
  }
  func testTileAtlasPreparesTilesForFlippedFieldContext() throws {
    let sourceTile = try makeTestTileImage(topHalf: 0, bottomHalf: 255)
    let atlas = FieldSceneRenderer.TileAtlas(image: sourceTile, tileSize: 8)

    let preparedTile = try atlas.tile(at: 0)

    XCTAssertGreaterThan(averageGrayscale(forTopRowsOf: preparedTile, rowCount: 4), 240)
    XCTAssertLessThan(averageGrayscale(forBottomRowsOf: preparedTile, rowCount: 4), 15)
  }
}
