import XCTest
import PokeDataModel

final class AssetCopyingTests: XCTestCase {
    func testExtractorCopiesFieldAndStarterBattleAssetsForM3Slice() throws {
        let outputRoot = try PokeExtractCLITestSupport.temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: PokeExtractCLITestSupport.repoRoot(), outputRoot: outputRoot)
        )

        let variantRoot = outputRoot.appendingPathComponent("Red", isDirectory: true)
        let expectedFieldAssets = [
            "Assets/field/tilesets/reds_house.png",
            "Assets/field/tilesets/overworld.png",
            "Assets/field/tilesets/gym.png",
            "Assets/field/sprites/red.png",
            "Assets/field/sprites/oak.png",
            "Assets/field/sprites/blue.png",
            "Assets/field/sprites/mom.png",
            "Assets/field/sprites/girl.png",
            "Assets/field/sprites/fisher.png",
            "Assets/field/sprites/scientist.png",
            "Assets/field/sprites/poke_ball.png",
            "Assets/field/sprites/pokedex.png",
            "Assets/field/blocksets/reds_house.bst",
            "Assets/field/blocksets/overworld.bst",
            "Assets/field/blocksets/gym.bst",
            "Assets/battle/pokemon/front/charmander.png",
            "Assets/battle/pokemon/front/squirtle.png",
            "Assets/battle/pokemon/front/bulbasaur.png",
            "Assets/battle/pokemon/back/charmander.png",
            "Assets/battle/pokemon/back/squirtle.png",
            "Assets/battle/pokemon/back/bulbasaur.png",
        ]

        for relativePath in expectedFieldAssets {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: variantRoot.appendingPathComponent(relativePath).path),
                "Missing extracted field asset at \(relativePath)"
            )
        }
    }
}
