import XCTest
import ImageIO
@testable import PokeContent

final class RepoContentContractTests: XCTestCase {
    func testLoaderResolvesRepoGeneratedFieldAssets() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let tileset = try XCTUnwrap(loaded.tileset(id: "OVERWORLD"))
        let cavernTileset = try XCTUnwrap(loaded.tileset(id: "CAVERN"))
        let sprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_RED"))
        let rocketSprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_ROCKET"))
        let fossilSprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_FOSSIL"))
        let oaksLab = try XCTUnwrap(loaded.map(id: "OAKS_LAB"))
        let sendOutPoofURL = root.appendingPathComponent("Assets/battle/effects/send_out_poof.png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(cavernTileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(cavernTileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(sprite.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(rocketSprite.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(fossilSprite.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sendOutPoofURL.path))
        let sendOutPoofSource = try XCTUnwrap(CGImageSourceCreateWithURL(sendOutPoofURL as CFURL, nil))
        let sendOutPoofImage = try XCTUnwrap(CGImageSourceCreateImageAtIndex(sendOutPoofSource, 0, nil))
        XCTAssertEqual(sendOutPoofImage.width, 128)
        XCTAssertEqual(sendOutPoofImage.height, 40)
        XCTAssertTrue(
            loaded.fieldRenderIssues(
                map: oaksLab,
                spriteIDs: ["SPRITE_RED", "SPRITE_OAK", "SPRITE_BLUE", "SPRITE_SCIENTIST", "SPRITE_POKE_BALL", "SPRITE_POKEDEX"]
            ).isEmpty
        )
        for map in loaded.gameplayManifest.maps {
            XCTAssertEqual(Set(map.objects.map(\.id)).count, map.objects.count, "duplicate object ids in \(map.id)")
            let spriteIDs = Array(Set(map.objects.map(\.sprite))).sorted()
            XCTAssertTrue(
                loaded.fieldRenderIssues(map: map, spriteIDs: spriteIDs).isEmpty,
                "field render issues for \(map.id): \(loaded.fieldRenderIssues(map: map, spriteIDs: spriteIDs))"
            )
        }
    }

    func testLoaderReadsRepoGeneratedAudioContract() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        XCTAssertEqual(loaded.audioManifest.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_2F")?.defaultMusicID, "MUSIC_PALLET_TOWN")
        XCTAssertEqual(loaded.map(id: "OAKS_LAB")?.defaultMusicID, "MUSIC_OAKS_LAB")
        XCTAssertEqual(loaded.audioCue(id: "oak_intro")?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(loaded.audioCue(id: "rival_exit")?.entryID, "alternateStart")
        XCTAssertEqual(loaded.audioCue(id: "trainer_victory")?.trackID, "MUSIC_DEFEATED_TRAINER")
        XCTAssertEqual(loaded.audioCue(id: "wild_victory")?.trackID, "MUSIC_DEFEATED_WILD_MON")
        XCTAssertEqual(loaded.audioCue(id: "evolution")?.trackID, "MUSIC_SAFARI_ZONE")
        XCTAssertEqual(loaded.audioCue(id: "mom_heal")?.waitForCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "mom_heal")?.resumeMusicAfterCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "pokemon_center_healed")?.waitForCompletion, true)
        XCTAssertEqual(loaded.audioCue(id: "pokemon_center_healed")?.resumeMusicAfterCompletion, true)
        XCTAssertNotNil(loaded.audioTrack(id: "MUSIC_TITLE_SCREEN"))
        XCTAssertNotNil(loaded.audioEntry(trackID: "MUSIC_MEET_RIVAL", entryID: "alternateStart"))
        XCTAssertEqual(
            loaded.audioManifest.mapRoutes,
            [
                .init(mapID: "MT_MOON_1F", musicID: "MUSIC_DUNGEON3"),
                .init(mapID: "MT_MOON_B1F", musicID: "MUSIC_DUNGEON3"),
                .init(mapID: "MT_MOON_B2F", musicID: "MUSIC_DUNGEON3"),
                .init(mapID: "MT_MOON_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "MUSEUM_1F", musicID: "MUSIC_CITIES1"),
                .init(mapID: "MUSEUM_2F", musicID: "MUSIC_CITIES1"),
                .init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB"),
                .init(mapID: "PALLET_TOWN", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "PEWTER_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "PEWTER_GYM", musicID: "MUSIC_GYM"),
                .init(mapID: "PEWTER_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "PEWTER_NIDORAN_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "PEWTER_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "PEWTER_SPEECH_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "REDS_HOUSE_1F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "ROUTE_2", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "ROUTE_22", musicID: "MUSIC_ROUTES3"),
                .init(mapID: "ROUTE_22_GATE", musicID: "MUSIC_DUNGEON2"),
                .init(mapID: "ROUTE_3", musicID: "MUSIC_ROUTES3"),
                .init(mapID: "ROUTE_4", musicID: "MUSIC_ROUTES3"),
                .init(mapID: "VIRIDIAN_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_FOREST", musicID: "MUSIC_DUNGEON2"),
                .init(mapID: "VIRIDIAN_FOREST_NORTH_GATE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_FOREST_SOUTH_GATE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_NICKNAME_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_SCHOOL_HOUSE", musicID: "MUSIC_CITIES1"),
            ]
        )
    }

    func testLoaderReadsRepoGeneratedMartAndCaptureContracts() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let viridianMart = try XCTUnwrap(loaded.mart(id: "viridian_mart"))
        let pewterMart = try XCTUnwrap(loaded.mart(id: "pewter_mart"))
        let oaksLab = try XCTUnwrap(loaded.map(id: "OAKS_LAB"))
        let pokeBall = try XCTUnwrap(loaded.item(id: "POKE_BALL"))
        let boulderBadge = try XCTUnwrap(loaded.item(id: "BOULDERBADGE"))
        let floorB2F = try XCTUnwrap(loaded.item(id: "FLOOR_B2F"))
        let pidgey = try XCTUnwrap(loaded.species(id: "PIDGEY"))
        let squirtle = try XCTUnwrap(loaded.species(id: "SQUIRTLE"))
        let brock = try XCTUnwrap(loaded.trainerBattle(id: "opp_brock_1"))
        let route3Youngster = try XCTUnwrap(loaded.trainerBattle(id: "opp_youngster_1"))
        let superNerd = try XCTUnwrap(loaded.trainerBattle(id: "opp_super_nerd_2"))
        let mtMoon1FEncounters = try XCTUnwrap(loaded.wildEncounterTable(mapID: "MT_MOON_1F"))

        XCTAssertEqual(viridianMart.mapID, "VIRIDIAN_MART")
        XCTAssertEqual(viridianMart.clerkObjectID, "viridian_mart_clerk")
        XCTAssertEqual(viridianMart.stockItemIDs, ["POKE_BALL", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL"])
        XCTAssertEqual(loaded.mart(mapID: "VIRIDIAN_MART", clerkObjectID: "viridian_mart_clerk")?.id, viridianMart.id)
        XCTAssertEqual(pewterMart.mapID, "PEWTER_MART")
        XCTAssertEqual(pewterMart.clerkObjectID, "pewter_mart_clerk")
        XCTAssertEqual(pewterMart.stockItemIDs, ["POKE_BALL", "POTION", "ESCAPE_ROPE", "ANTIDOTE", "BURN_HEAL", "AWAKENING", "PARLYZ_HEAL"])
        XCTAssertEqual(Set(oaksLab.objects.map(\.id)).count, oaksLab.objects.count)
        XCTAssertNotNil(loaded.dialogue(id: "pewter_city_mart_sign"))
        XCTAssertNotNil(loaded.dialogue(id: "pewter_city_pokecenter_sign"))
        XCTAssertNil(loaded.dialogue(id: "pewter_city_text_pewtercity_mart_sign"))
        XCTAssertNil(loaded.dialogue(id: "pewter_city_text_pewtercity_pokecenter_sign"))
        XCTAssertEqual(pokeBall.price, 200)
        XCTAssertEqual(pokeBall.battleUse, .ball)
        XCTAssertEqual(boulderBadge.isKeyItem, true)
        XCTAssertEqual(floorB2F.displayName, "B2F")
        XCTAssertEqual(pidgey.catchRate, 255)
        XCTAssertEqual(
            Array(squirtle.levelUpLearnset.prefix(2)),
            [.init(level: 8, moveID: "BUBBLE"), .init(level: 15, moveID: "WATER_GUN")]
        )
        XCTAssertEqual(
            squirtle.evolutions,
            [
                .init(
                    trigger: .init(kind: .level, level: 16),
                    targetSpeciesID: "WARTORTLE"
                ),
            ]
        )
        XCTAssertEqual(loaded.dialogue(id: "evolution_evolved")?.pages.first?.lines, ["{pokemon} evolved"])
        XCTAssertEqual(loaded.dialogue(id: "evolution_into")?.pages.first?.lines, ["into {evolvedPokemon}!"])
        XCTAssertEqual(brock.party, [.init(speciesID: "GEODUDE", level: 12), .init(speciesID: "ONIX", level: 14)])
        XCTAssertEqual(brock.trainerSpritePath, "Assets/battle/trainers/brock.png")
        XCTAssertEqual(route3Youngster.trainerSpritePath, "Assets/battle/trainers/youngster.png")
        XCTAssertEqual(superNerd.trainerSpritePath, "Assets/battle/trainers/supernerd.png")
        XCTAssertEqual(superNerd.completionFlagID, "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")
        XCTAssertEqual(mtMoon1FEncounters.landEncounterSurface, .floor)
        XCTAssertEqual(mtMoon1FEncounters.grassEncounterRate, 10)
    }

    func testLoaderReadsRepoGeneratedMuseumExhibitContracts() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let museum1F = try XCTUnwrap(loaded.map(id: "MUSEUM_1F"))
        let museum2F = try XCTUnwrap(loaded.map(id: "MUSEUM_2F"))

        XCTAssertEqual(
            museum1F.objects.first { $0.id == "museum1_f_old_amber" }?.interactionDialogueID,
            "museum1_f_old_amber"
        )
        XCTAssertEqual(
            museum2F.backgroundEvents.map(\.dialogueID),
            ["museum2_f_space_shuttle_sign", "museum2_f_moon_stone_sign"]
        )
        XCTAssertEqual(
            loaded.dialogue(id: "museum1_f_old_amber")?.pages.first?.lines,
            ["The AMBER is", "clear and gold!"]
        )
        XCTAssertEqual(
            loaded.dialogue(id: "museum2_f_space_shuttle_sign")?.pages.first?.lines,
            ["SPACE SHUTTLE", "COLUMBIA"]
        )
        XCTAssertEqual(
            loaded.dialogue(id: "museum2_f_moon_stone_sign")?.pages.first?.lines,
            ["Meteorite that", "fell on MT.MOON.", "(MOON STONE?)"]
        )
    }

    func testLoaderReadsRepoGeneratedPokemonCenterInteractionContract() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let interaction = try XCTUnwrap(loaded.fieldInteraction(id: "pokemon_center_healing"))
        let pewterInteraction = try XCTUnwrap(loaded.fieldInteraction(id: "pewter_pokecenter_pokemon_center_healing"))
        let mtMoonInteraction = try XCTUnwrap(loaded.fieldInteraction(id: "mt_moon_pokecenter_pokemon_center_healing"))
        XCTAssertEqual(interaction.kind, .pokemonCenterHealing)
        XCTAssertEqual(interaction.introDialogueID, "pokemon_center_welcome")
        XCTAssertEqual(interaction.prompt.dialogueID, "pokemon_center_shall_we_heal")
        XCTAssertEqual(interaction.acceptedDialogueID, "pokemon_center_need_your_pokemon")
        XCTAssertEqual(interaction.successDialogueID, "pokemon_center_fighting_fit")
        XCTAssertEqual(interaction.farewellDialogueID, "pokemon_center_farewell")
        XCTAssertEqual(interaction.healingSequence?.machineSoundEffectID, "SFX_HEALING_MACHINE")
        XCTAssertEqual(interaction.healingSequence?.healedAudioCueID, "pokemon_center_healed")
        XCTAssertEqual(
            interaction.healingSequence?.blackoutCheckpoint,
            .init(mapID: "VIRIDIAN_CITY", position: .init(x: 23, y: 26), facing: .down)
        )
        XCTAssertEqual(
            pewterInteraction.healingSequence?.blackoutCheckpoint,
            .init(mapID: "PEWTER_CITY", position: .init(x: 13, y: 26), facing: .down)
        )
        XCTAssertEqual(
            mtMoonInteraction.healingSequence?.blackoutCheckpoint,
            .init(mapID: "ROUTE_4", position: .init(x: 11, y: 6), facing: .down)
        )
        XCTAssertEqual(loaded.map(id: "PEWTER_GYM")?.defaultMusicID, "MUSIC_GYM")
        XCTAssertEqual(loaded.map(id: "ROUTE_3")?.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(loaded.map(id: "MT_MOON_POKECENTER")?.warps.allSatisfy(\.usesPreviousMapTarget), true)
        XCTAssertEqual(
            loaded.mapScript(for: "MT_MOON_B2F")?.triggers.map(\.scriptID),
            ["mt_moon_b2f_super_nerd_battle"]
        )
        XCTAssertEqual(
            loaded.script(id: "mt_moon_b2f_take_dome_fossil")?.steps.map(\.action),
            ["promptItemPickup", "moveObject", "showDialogue", "setObjectVisibility"]
        )
        XCTAssertEqual(
            loaded.mapScript(for: "ROUTE_22_GATE")?.triggers.map(\.scriptID),
            [
                "route_22_gate_guard_blocks_northbound_upper_lane",
                "route_22_gate_guard_blocks_northbound_lower_lane",
            ]
        )
        XCTAssertEqual(
            loaded.script(id: "route_22_gate_guard_blocks_northbound_upper_lane")?.steps.map(\.action),
            ["showDialogue", "movePlayer"]
        )
        XCTAssertEqual(
            loaded.gameplayManifest.playerStart.defaultBlackoutCheckpoint,
            .init(mapID: "PALLET_TOWN", position: .init(x: 5, y: 6), facing: .down)
        )
        XCTAssertEqual(
            loaded.commonBattleText.playerBlackedOut,
            "{playerName} is out of useable POKéMON! {playerName} blacked out!"
        )
        XCTAssertTrue(
            Set(loaded.gameplayManifest.trainerBattles.map(\.completionFlagID))
                .isSubset(of: Set(loaded.gameplayManifest.eventFlags.flags.map(\.id)))
        )
    }
}
