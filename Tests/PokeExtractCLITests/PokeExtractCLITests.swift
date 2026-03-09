import XCTest
import PokeDataModel

final class PokeExtractCLITests: XCTestCase {
    func testCharmapParserFindsEntries() throws {
        let file = try temporaryFile(contents: """
        ; section
        charmap "A", $80
        charmap "B", $81
        """)
        let manifest = try RedContentExtractor.parseCharmap(at: file)
        XCTAssertEqual(manifest.entries.count, 2)
        XCTAssertEqual(manifest.entries.first?.token, "A")
    }

    func testTitleBounceParserExtractsSteps() throws {
        let contents = """
        .TitleScreenPokemonLogoYScrolls:
        db -4,16
        db 3,4
        db 0
        .ScrollTitleScreenPokemonLogo:
        """
        let steps = try RedContentExtractor.parseLogoBounceSteps(from: contents)
        XCTAssertEqual(steps, [.init(yDelta: -4, frames: 16), .init(yDelta: 3, frames: 4)])
    }

    func testGameplayExtractorBuildsBoundedM3ManifestFromRepoSources() throws {
        let manifest = try extractGameplayManifest(source: SourceTree(repoRoot: repoRoot()))

        XCTAssertEqual(manifest.maps.map(\.id), ["REDS_HOUSE_2F", "REDS_HOUSE_1F", "PALLET_TOWN", "OAKS_LAB"])
        XCTAssertEqual(manifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(manifest.playerStart.position, .init(x: 4, y: 4))
        XCTAssertEqual(manifest.playerStart.playerName, "RED")
        XCTAssertEqual(manifest.playerStart.rivalName, "BLUE")
        XCTAssertEqual(manifest.tilesets.map(\.id), ["REDS_HOUSE_1", "REDS_HOUSE_2", "OVERWORLD", "DOJO"])
        XCTAssertEqual(manifest.tilesets.last?.imagePath, "Assets/field/tilesets/gym.png")
        XCTAssertEqual(manifest.tilesets.last?.blocksetPath, "Assets/field/blocksets/gym.bst")
        XCTAssertEqual(manifest.overworldSprites.map(\.id), [
            "SPRITE_RED",
            "SPRITE_OAK",
            "SPRITE_BLUE",
            "SPRITE_MOM",
            "SPRITE_GIRL",
            "SPRITE_FISHER",
            "SPRITE_SCIENTIST",
            "SPRITE_POKE_BALL",
            "SPRITE_POKEDEX",
        ])

        let palletTown = try XCTUnwrap(manifest.maps.first { $0.id == "PALLET_TOWN" })
        XCTAssertEqual(palletTown.borderBlockID, 0x0B)
        XCTAssertEqual(palletTown.triggerRegions, [
            .init(
                id: "north_exit",
                origin: .init(x: 0, y: 1),
                size: .init(width: 20, height: 1),
                scriptID: "pallet_town_oak_intro"
            ),
        ])
        XCTAssertEqual(palletTown.warps.count, 3)
        XCTAssertEqual(palletTown.backgroundEvents.map(\.dialogueID), [
            "pallet_town_oaks_lab_sign",
            "pallet_town_sign",
            "pallet_town_players_house_sign",
            "pallet_town_rivals_house_sign",
        ])
        XCTAssertEqual(palletTown.objects.map(\.id), [
            "pallet_town_oak",
            "pallet_town_girl",
            "pallet_town_fisher",
        ])

        let oaksLab = try XCTUnwrap(manifest.maps.first { $0.id == "OAKS_LAB" })
        XCTAssertEqual(oaksLab.borderBlockID, 0x03)
        XCTAssertEqual(oaksLab.objects.count, 11)
        XCTAssertEqual(
            oaksLab.objects.filter { $0.id.hasPrefix("oaks_lab_poke_ball_") }.map(\.id),
            ["oaks_lab_poke_ball_charmander", "oaks_lab_poke_ball_squirtle", "oaks_lab_poke_ball_bulbasaur"]
        )
        XCTAssertEqual(
            manifest.eventFlags.flags.map(\.id),
            [
                "EVENT_FOLLOWED_OAK_INTO_LAB",
                "EVENT_FOLLOWED_OAK_INTO_LAB_2",
                "EVENT_OAK_ASKED_TO_CHOOSE_MON",
                "EVENT_GOT_STARTER",
                "EVENT_BATTLED_RIVAL_IN_OAKS_LAB",
                "EVENT_OAK_APPEARED_IN_PALLET",
            ]
        )
        XCTAssertEqual(manifest.scripts.map(\.id), [
            "pallet_town_oak_intro",
            "oaks_lab_dont_go_away",
            "oaks_lab_rival_challenge",
        ])
        XCTAssertEqual(manifest.species.map(\.id), ["CHARMANDER", "SQUIRTLE", "BULBASAUR"])
        XCTAssertEqual(manifest.moves.map(\.id), ["SCRATCH", "TACKLE", "TAIL_WHIP", "GROWL"])
        XCTAssertEqual(manifest.trainerBattles.map(\.id), [
            "rival_lab_squirtle",
            "rival_lab_bulbasaur",
            "rival_lab_charmander",
        ])

        let oakDialogue = try XCTUnwrap(manifest.dialogues.first { $0.id == "pallet_town_oak_its_unsafe" })
        XCTAssertEqual(oakDialogue.pages.first?.lines.first, "OAK: It's unsafe!")
        XCTAssertEqual(oakDialogue.pages.last?.lines.last, "me!")
    }

    func testExtractorWritesDeterministicGameplayManifestJSON() throws {
        let repoRoot = repoRoot()
        let firstOutputRoot = try temporaryDirectory()
        let secondOutputRoot = try temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: firstOutputRoot)
        )
        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: secondOutputRoot)
        )

        let first = try Data(contentsOf: firstOutputRoot.appendingPathComponent("Red/gameplay_manifest.json"))
        let second = try Data(contentsOf: secondOutputRoot.appendingPathComponent("Red/gameplay_manifest.json"))
        XCTAssertEqual(first, second)

        let decoded = try JSONDecoder().decode(
            GameplayManifest.self,
            from: first
        )
        XCTAssertEqual(decoded.maps.count, 4)
        XCTAssertEqual(decoded.tilesets.count, 4)
        XCTAssertEqual(decoded.overworldSprites.count, 9)
        XCTAssertGreaterThan(decoded.dialogues.count, 30)
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_ill_take_you_on" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "rival_lab_squirtle" })
        XCTAssertEqual(decoded.tilesets.first?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(decoded.tilesets.first?.blocksetPath, "Assets/field/blocksets/reds_house.bst")
        XCTAssertEqual(decoded.overworldSprites.first?.facingFrames.down, .init(x: 0, y: 0, width: 16, height: 16))
    }

    func testExtractorCopiesFieldAssetsForM3Slice() throws {
        let outputRoot = try temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot(), outputRoot: outputRoot)
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
        ]

        for relativePath in expectedFieldAssets {
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: variantRoot.appendingPathComponent(relativePath).path),
                "Missing extracted field asset at \(relativePath)"
            )
        }
    }

    private func temporaryFile(contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
