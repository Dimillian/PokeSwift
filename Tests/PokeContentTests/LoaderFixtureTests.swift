import XCTest
@testable import PokeContent

final class LoaderFixtureTests: XCTestCase {
    func testLoaderReadsGeneratedContentShape() throws {
        let root = try PokeContentTestSupport.makeFixtureRoot()
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        XCTAssertEqual(loaded.gameManifest.variant, .red)
        XCTAssertEqual(loaded.titleManifest.menuEntries.count, 3)
        XCTAssertEqual(loaded.gameplayManifest.maps.count, 1)
        XCTAssertEqual(loaded.gameplayManifest.dialogues.count, 1)
        XCTAssertEqual(loaded.gameplayManifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_2F")?.displayName, "Red's House 2F")
        XCTAssertEqual(loaded.dialogue(id: "hello")?.pages.first?.lines, ["Hi"])
        XCTAssertEqual(loaded.script(id: "oak_intro")?.steps.map(\.action), ["showDialogue"])
        XCTAssertEqual(loaded.mapScript(for: "REDS_HOUSE_2F")?.triggers.first?.scriptID, "oak_intro")
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.startingMoves, ["TACKLE", "TAIL_WHIP"])
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.primaryType, "WATER")
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.baseExp, 66)
        XCTAssertEqual(loaded.species(id: "SQUIRTLE")?.growthRate, .mediumSlow)
        XCTAssertEqual(
            loaded.species(id: "SQUIRTLE")?.levelUpLearnset,
            [.init(level: 8, moveID: "BUBBLE"), .init(level: 15, moveID: "WATER_GUN")]
        )
        XCTAssertEqual(
            loaded.species(id: "SQUIRTLE")?.battleSprite,
            .init(
                frontImagePath: "Assets/battle/pokemon/front/squirtle.png",
                backImagePath: "Assets/battle/pokemon/back/squirtle.png"
            )
        )
        XCTAssertEqual(loaded.move(id: "TACKLE")?.power, 35)
        XCTAssertEqual(loaded.move(id: "BUBBLE")?.maxPP, 30)
        XCTAssertEqual(loaded.typeEffectiveness(attackingType: "WATER", defendingType: "FIRE")?.multiplier, 20)
        XCTAssertEqual(loaded.trainerBattle(id: "opp_rival1_2")?.party.first?.speciesID, "BULBASAUR")
        XCTAssertEqual(loaded.tileset(id: "REDS_HOUSE_2")?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(loaded.tileset(id: "REDS_HOUSE_2")?.collision.passableTileIDs, [0x01, 0x02])
        XCTAssertEqual(loaded.overworldSprite(id: "SPRITE_RED")?.frameHeight, 16)
    }
}
