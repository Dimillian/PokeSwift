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
        XCTAssertEqual(palletTown.stepCollisionTileIDs.count, palletTown.stepWidth * palletTown.stepHeight)
        XCTAssertEqual(palletTown.warps.count, 3)
        XCTAssertEqual(palletTown.backgroundEvents.map(\.dialogueID), [
            "pallet_town_oaks_lab_sign",
            "pallet_town_sign",
            "pallet_town_players_house_sign",
            "pallet_town_rivals_house_sign",
        ])
        XCTAssertEqual(manifest.mapScripts.first { $0.mapID == "PALLET_TOWN" }?.triggers.map(\.scriptID), [
            "pallet_town_oak_intro",
        ])
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "PALLET_TOWN" }?.triggers.first?.conditions,
            [
                .init(kind: "flagUnset", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                .init(kind: "playerYEquals", intValue: 1),
            ]
        )
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
            "oaks_lab_rival_challenge_vs_squirtle",
            "oaks_lab_rival_challenge_vs_bulbasaur",
            "oaks_lab_rival_challenge_vs_charmander",
        ])
        XCTAssertEqual(manifest.species.map(\.id), ["CHARMANDER", "SQUIRTLE", "BULBASAUR"])
        let charmander = try XCTUnwrap(manifest.species.first { $0.id == "CHARMANDER" })
        XCTAssertEqual(charmander.primaryType, "FIRE")
        XCTAssertNil(charmander.secondaryType)
        XCTAssertEqual(
            charmander.battleSprite,
            .init(
                frontImagePath: "Assets/battle/pokemon/front/charmander.png",
                backImagePath: "Assets/battle/pokemon/back/charmander.png"
            )
        )
        let squirtle = try XCTUnwrap(manifest.species.first { $0.id == "SQUIRTLE" })
        XCTAssertEqual(squirtle.primaryType, "WATER")
        XCTAssertNil(squirtle.secondaryType)
        let bulbasaur = try XCTUnwrap(manifest.species.first { $0.id == "BULBASAUR" })
        XCTAssertEqual(bulbasaur.primaryType, "GRASS")
        XCTAssertEqual(bulbasaur.secondaryType, "POISON")
        XCTAssertEqual(manifest.moves.map(\.id), ["SCRATCH", "TACKLE", "TAIL_WHIP", "GROWL"])
        XCTAssertFalse(manifest.typeEffectiveness.isEmpty)
        XCTAssertEqual(
            manifest.typeEffectiveness.first { $0.attackingType == "FIRE" && $0.defendingType == "GRASS" }?.multiplier,
            20
        )
        XCTAssertEqual(
            manifest.typeEffectiveness.first { $0.attackingType == "NORMAL" && $0.defendingType == "GHOST" }?.multiplier,
            0
        )
        XCTAssertEqual(manifest.trainerBattles.map(\.id), [
            "opp_rival1_1",
            "opp_rival1_2",
            "opp_rival1_3",
        ])
        XCTAssertEqual(manifest.trainerBattles.first?.party, [.init(speciesID: "SQUIRTLE", level: 5)])
        XCTAssertEqual(manifest.tilesets.first?.collision.passableTileIDs, [0x01, 0x02, 0x03, 0x11, 0x12, 0x13, 0x14, 0x1c, 0x1a])

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
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "OAKS_LAB" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_rival1_1" })
        XCTAssertGreaterThan(decoded.typeEffectiveness.count, 0)
        XCTAssertEqual(decoded.tilesets.first?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(decoded.tilesets.first?.blocksetPath, "Assets/field/blocksets/reds_house.bst")
        XCTAssertEqual(decoded.overworldSprites.first?.facingFrames.down, .init(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(
            decoded.species.first { $0.id == "CHARMANDER" }?.battleSprite?.frontImagePath,
            "Assets/battle/pokemon/front/charmander.png"
        )
    }

    func testAudioExtractorBuildsBoundedM3ManifestFromRepoSources() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        XCTAssertEqual(manifest.variant, .red)
        XCTAssertEqual(manifest.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(
            manifest.mapRoutes,
            [
                .init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB"),
                .init(mapID: "PALLET_TOWN", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_1F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN"),
            ]
        )

        let cueByID = Dictionary(uniqueKeysWithValues: manifest.cues.map { ($0.id, $0) })
        XCTAssertEqual(cueByID["title_default"]?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(cueByID["oak_intro"]?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(cueByID["rival_intro"]?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(cueByID["rival_exit"]?.entryID, "alternateStart")
        XCTAssertEqual(cueByID["trainer_battle"]?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(cueByID["mom_heal"]?.trackID, "MUSIC_PKMN_HEALED")

        let requiredTrackIDs: Set<String> = [
            "MUSIC_TITLE_SCREEN",
            "MUSIC_PALLET_TOWN",
            "MUSIC_OAKS_LAB",
            "MUSIC_MEET_PROF_OAK",
            "MUSIC_MEET_RIVAL",
            "MUSIC_TRAINER_BATTLE",
            "MUSIC_PKMN_HEALED",
        ]
        XCTAssertTrue(requiredTrackIDs.isSubset(of: Set(manifest.tracks.map(\.id))))

        let rivalTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_RIVAL" })
        XCTAssertNotNil(rivalTrack.entries.first { $0.id == "default" })
        XCTAssertNotNil(rivalTrack.entries.first { $0.id == "alternateStart" })
        XCTAssertEqual(rivalTrack.entries.first { $0.id == "alternateStart" }?.playbackMode, .looping)
    }

    func testAudioExtractorQuantizesOakLabLeadToEngineFrameDurations() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let oakLabTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_OAKS_LAB" })
        let channelOne = try XCTUnwrap(
            oakLabTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let opening = Array(channelOne.prelude.prefix(4))
        XCTAssertEqual(opening.count, 4)

        XCTAssertEqual(opening[0].duration, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[1].duration, 7.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[2].duration, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[3].duration, 7.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[1].startTime, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[2].startTime, 13.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[3].startTime, 19.0 / 60.0, accuracy: 0.000_001)
    }

    func testAudioExtractorAppliesTrackTempoToSecondaryChannels() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let titleTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_TITLE_SCREEN" })
        let channelTwo = try XCTUnwrap(
            titleTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 2 }
        )
        let firstEvent = try XCTUnwrap(channelTwo.prelude.first)

        XCTAssertEqual(firstEvent.duration, 6.0 / 60.0, accuracy: 0.000_001)
    }

    func testExtractorWritesDeterministicAudioManifestJSON() throws {
        let repoRoot = repoRoot()
        let firstOutputRoot = try temporaryDirectory()
        let secondOutputRoot = try temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: firstOutputRoot)
        )
        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: secondOutputRoot)
        )

        let first = try Data(contentsOf: firstOutputRoot.appendingPathComponent("Red/audio_manifest.json"))
        let second = try Data(contentsOf: secondOutputRoot.appendingPathComponent("Red/audio_manifest.json"))
        XCTAssertEqual(first, second)

        let decoded = try JSONDecoder().decode(AudioManifest.self, from: first)
        XCTAssertEqual(decoded.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(decoded.mapRoutes.count, 4)
        XCTAssertEqual(decoded.cues.count, 6)
        XCTAssertEqual(decoded.tracks.count, 7)
        XCTAssertNotNil(decoded.tracks.first { $0.id == "MUSIC_MEET_RIVAL" }?.entries.first { $0.id == "alternateStart" })
    }

    func testExtractorCopiesFieldAndStarterBattleAssetsForM3Slice() throws {
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
