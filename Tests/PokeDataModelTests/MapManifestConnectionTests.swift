import XCTest
@testable import PokeDataModel

final class MapManifestConnectionTests: XCTestCase {
    func testMapManifestResolvesNorthConnectionBlocksUsingGBOffsetRules() {
        let map = MapManifest(
            id: "PALLET_TOWN",
            displayName: "Pallet Town",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 11,
            blockWidth: 2,
            blockHeight: 2,
            stepWidth: 4,
            stepHeight: 4,
            tileset: "OVERWORLD",
            blockIDs: [1, 2, 3, 4],
            stepCollisionTileIDs: Array(repeating: 0, count: 16),
            warps: [],
            backgroundEvents: [],
            objects: [],
            connections: [
                .init(
                    direction: .north,
                    targetMapID: "ROUTE_1",
                    offset: 0,
                    targetBlockWidth: 3,
                    targetBlockHeight: 4,
                    targetBlockIDs: [
                        20, 21, 22,
                        23, 24, 25,
                        26, 27, 28,
                        29, 30, 31,
                    ]
                ),
            ]
        )

        XCTAssertEqual(map.blockID(atBlockX: 0, blockY: -1), 29)
        XCTAssertEqual(map.blockID(atBlockX: 2, blockY: -3), 25)
        XCTAssertEqual(map.blockID(atBlockX: -1, blockY: -1), 11)
    }

    func testMapManifestResolvesEastConnectionBlocksUsingVerticalOffsets() {
        let map = MapManifest(
            id: "ROUTE_7",
            displayName: "Route 7",
            defaultMusicID: "MUSIC_ROUTES2",
            borderBlockID: 7,
            blockWidth: 2,
            blockHeight: 2,
            stepWidth: 4,
            stepHeight: 4,
            tileset: "OVERWORLD",
            blockIDs: [1, 2, 3, 4],
            stepCollisionTileIDs: Array(repeating: 0, count: 16),
            warps: [],
            backgroundEvents: [],
            objects: [],
            connections: [
                .init(
                    direction: .east,
                    targetMapID: "SAFFRON_CITY",
                    offset: 1,
                    targetBlockWidth: 3,
                    targetBlockHeight: 4,
                    targetBlockIDs: [
                        40, 41, 42,
                        43, 44, 45,
                        46, 47, 48,
                        49, 50, 51,
                    ]
                ),
            ]
        )

        XCTAssertEqual(map.blockID(atBlockX: 2, blockY: 1), 40)
        XCTAssertEqual(map.blockID(atBlockX: 4, blockY: 4), 51)
        XCTAssertEqual(map.blockID(atBlockX: 2, blockY: 0), 7)
    }
}
