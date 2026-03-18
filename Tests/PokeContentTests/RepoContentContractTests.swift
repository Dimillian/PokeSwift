import XCTest
import ImageIO
@testable import PokeContent

final class RepoContentContractTests: XCTestCase {
    func testLoaderResolvesRepoGeneratedFieldAssets() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let tileset = try XCTUnwrap(loaded.tileset(id: "OVERWORLD"))
        let cavernTileset = try XCTUnwrap(loaded.tileset(id: "CAVERN"))
        let forestTileset = try XCTUnwrap(loaded.tileset(id: "FOREST"))
        let interiorTileset = try XCTUnwrap(loaded.tileset(id: "INTERIOR"))
        let sprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_RED"))
        let rocketSprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_ROCKET"))
        let fossilSprite = try XCTUnwrap(loaded.overworldSprite(id: "SPRITE_FOSSIL"))
        let oaksLab = try XCTUnwrap(loaded.map(id: "OAKS_LAB"))
        let palletPalette = try XCTUnwrap(loaded.fieldPalette(id: "PAL_PALLET"))
        let sendOutPoofURL = root.appendingPathComponent("Assets/battle/effects/send_out_poof.png")
        let moveAnim0URL = root.appendingPathComponent("Assets/battle/animations/move_anim_0.png")
        let moveAnim1URL = root.appendingPathComponent("Assets/battle/animations/move_anim_1.png")
        let flowerAnimationPaths = try XCTUnwrap(
            tileset.animation.animatedTiles.first { $0.tileID == 0x03 }?.frameImagePaths
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(tileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(cavernTileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(cavernTileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(forestTileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(forestTileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(interiorTileset.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(interiorTileset.blocksetPath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(sprite.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(rocketSprite.imagePath).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(fossilSprite.imagePath).path))
        XCTAssertEqual(palletPalette.colors, [
            .init(red: 31, green: 29, blue: 31),
            .init(red: 25, green: 28, blue: 27),
            .init(red: 20, green: 26, blue: 31),
            .init(red: 3, green: 2, blue: 2),
        ])
        XCTAssertEqual(oaksLab.fieldPaletteID, "PAL_PALLET")
        XCTAssertEqual(loaded.map(id: "VIRIDIAN_POKECENTER")?.fieldPaletteID, "PAL_VIRIDIAN")
        XCTAssertEqual(loaded.map(id: "MUSEUM_2F")?.fieldPaletteID, "PAL_PEWTER")
        XCTAssertEqual(loaded.map(id: "BILLS_HOUSE")?.fieldPaletteID, "PAL_ROUTE")
        XCTAssertEqual(loaded.map(id: "MT_MOON_1F")?.fieldPaletteID, "PAL_CAVE")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sendOutPoofURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: moveAnim0URL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: moveAnim1URL.path))
        XCTAssertEqual(tileset.animation.kind, .waterFlower)
        XCTAssertEqual(tileset.animation.animatedTiles.map(\.tileID), [0x14, 0x03])
        XCTAssertEqual(forestTileset.animation.kind, .water)
        let sendOutPoofSource = try XCTUnwrap(CGImageSourceCreateWithURL(sendOutPoofURL as CFURL, nil))
        let sendOutPoofImage = try XCTUnwrap(CGImageSourceCreateImageAtIndex(sendOutPoofSource, 0, nil))
        XCTAssertEqual(sendOutPoofImage.width, 128)
        XCTAssertEqual(sendOutPoofImage.height, 40)
        XCTAssertEqual(loaded.battleAnimationManifest.tilesets.map(\.imagePath), [
            "Assets/battle/animations/move_anim_0.png",
            "Assets/battle/animations/move_anim_1.png",
            "Assets/battle/animations/move_anim_0.png",
        ])
        XCTAssertEqual(
            loaded.battleAnimation(moveID: "POUND")?.commands,
            [
                .init(
                    kind: .subanimation,
                    soundMoveID: "POUND",
                    subanimationID: "SUBANIM_0_STAR_TWICE",
                    specialEffectID: nil,
                    tilesetID: "MOVE_ANIM_TILESET_0",
                    delayFrames: 8
                ),
            ]
        )
        XCTAssertEqual(
            loaded.battleAnimation(moveID: "THUNDERPUNCH")?.commands,
            [
                .init(
                    kind: .subanimation,
                    soundMoveID: "THUNDERPUNCH",
                    subanimationID: "SUBANIM_0_STAR_THRICE",
                    specialEffectID: nil,
                    tilesetID: "MOVE_ANIM_TILESET_0",
                    delayFrames: 6
                ),
                .init(
                    kind: .specialEffect,
                    soundMoveID: nil,
                    subanimationID: nil,
                    specialEffectID: "SE_DARK_SCREEN_PALETTE",
                    tilesetID: nil,
                    delayFrames: nil
                ),
                .init(
                    kind: .subanimation,
                    soundMoveID: nil,
                    subanimationID: "SUBANIM_1_LIGHTNING",
                    specialEffectID: nil,
                    tilesetID: "MOVE_ANIM_TILESET_1",
                    delayFrames: 6
                ),
                .init(
                    kind: .specialEffect,
                    soundMoveID: nil,
                    subanimationID: nil,
                    specialEffectID: "SE_RESET_SCREEN_PALETTE",
                    tilesetID: nil,
                    delayFrames: nil
                ),
            ]
        )
        XCTAssertEqual(loaded.battleAnimationSubanimation(id: "SUBANIM_0_STAR_TWICE")?.steps.count, 2)
        XCTAssertEqual(loaded.battleAnimationFrameBlock(id: "FRAMEBLOCK_06")?.tiles.count, 12)
        XCTAssertEqual(loaded.battleAnimationBaseCoordinate(id: "BASECOORD_30"), .init(id: "BASECOORD_30", x: 0x28, y: 0x58))
        XCTAssertEqual(loaded.battleAnimationSpecialEffect(id: "SE_SHAKE_SCREEN")?.routine, "AnimationShakeScreen")
        for relativePath in flowerAnimationPaths {
            let url = root.appendingPathComponent(relativePath)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
            XCTAssertEqual(image.width, tileset.sourceTileSize)
            XCTAssertEqual(image.height, tileset.sourceTileSize)
        }
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
        let mapRouteIDs = loaded.audioManifest.mapRoutes.map(\.mapID)
        XCTAssertEqual(Set(mapRouteIDs).count, mapRouteIDs.count)
        XCTAssertEqual(loaded.map(id: "ROUTE_4")?.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(loaded.map(id: "CERULEAN_CITY")?.defaultMusicID, "MUSIC_CITIES2")
        XCTAssertEqual(loaded.map(id: "ROUTE_24")?.defaultMusicID, "MUSIC_ROUTES2")
        XCTAssertEqual(loaded.map(id: "ROUTE_25")?.defaultMusicID, "MUSIC_ROUTES2")
        XCTAssertEqual(loaded.map(id: "BILLS_HOUSE")?.defaultMusicID, "MUSIC_CITIES2")
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB")))
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "ROUTE_4", musicID: "MUSIC_ROUTES3")))
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "CERULEAN_CITY", musicID: "MUSIC_CITIES2")))
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "ROUTE_24", musicID: "MUSIC_ROUTES2")))
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "ROUTE_25", musicID: "MUSIC_ROUTES2")))
        XCTAssertTrue(loaded.audioManifest.mapRoutes.contains(.init(mapID: "BILLS_HOUSE", musicID: "MUSIC_CITIES2")))
    }

    func testLoaderReadsRepoGeneratedMartAndCaptureContracts() throws {
        let root = PokeContentTestSupport.repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let loaded = try FileSystemContentLoader(rootURL: root).load()

        let viridianMart = try XCTUnwrap(loaded.mart(id: "viridian_mart"))
        let pewterMart = try XCTUnwrap(loaded.mart(id: "pewter_mart"))
        let oaksLab = try XCTUnwrap(loaded.map(id: "OAKS_LAB"))
        let pokeBall = try XCTUnwrap(loaded.item(id: "POKE_BALL"))
        let potion = try XCTUnwrap(loaded.item(id: "POTION"))
        let antidote = try XCTUnwrap(loaded.item(id: "ANTIDOTE"))
        let fullRestore = try XCTUnwrap(loaded.item(id: "FULL_RESTORE"))
        let boulderBadge = try XCTUnwrap(loaded.item(id: "BOULDERBADGE"))
        let cascadeBadge = try XCTUnwrap(loaded.item(id: "CASCADEBADGE"))
        let floorB2F = try XCTUnwrap(loaded.item(id: "FLOOR_B2F"))
        let tmBide = try XCTUnwrap(loaded.item(id: "TM_BIDE"))
        let pidgey = try XCTUnwrap(loaded.species(id: "PIDGEY"))
        let squirtle = try XCTUnwrap(loaded.species(id: "SQUIRTLE"))
        let brock = try XCTUnwrap(loaded.trainerBattle(id: "opp_brock_1"))
        let misty = try XCTUnwrap(loaded.trainerBattle(id: "opp_misty_1"))
        let route3Youngster = try XCTUnwrap(loaded.trainerBattle(id: "opp_youngster_1"))
        let superNerd = try XCTUnwrap(loaded.trainerBattle(id: "opp_super_nerd_2"))
        let mtMoon1FEncounters = try XCTUnwrap(loaded.wildEncounterTable(mapID: "MT_MOON_1F"))
        let mtMoonB2FEncounters = try XCTUnwrap(loaded.wildEncounterTable(mapID: "MT_MOON_B2F"))

        XCTAssertEqual(viridianMart.mapID, "VIRIDIAN_MART")
        XCTAssertEqual(pidgey.battlePaletteID, "PAL_BROWNMON")
        XCTAssertEqual(squirtle.battlePaletteID, "PAL_CYANMON")
        XCTAssertEqual(loaded.palette(id: "PAL_CYANMON")?.colors.count, 4)
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
        XCTAssertEqual(pokeBall.bagSection, .balls)
        XCTAssertEqual(pokeBall.iconAssetPath, "Assets/items/ball/poke.png")
        XCTAssertEqual(pokeBall.shortDescription, "A standard Ball used to catch wild Pokemon.")
        XCTAssertEqual(potion.battleUse, .medicine)
        XCTAssertEqual(potion.medicine?.hpMode, .fixed)
        XCTAssertEqual(potion.medicine?.hpAmount, 20)
        XCTAssertEqual(antidote.medicine?.statusMode, .poison)
        XCTAssertEqual(fullRestore.medicine?.hpMode, .healToFull)
        XCTAssertEqual(fullRestore.medicine?.statusMode, .all)
        XCTAssertEqual(boulderBadge.isKeyItem, true)
        XCTAssertEqual(boulderBadge.bagSection, .keyItems)
        XCTAssertEqual(cascadeBadge.isKeyItem, true)
        XCTAssertEqual(floorB2F.displayName, "B2F")
        XCTAssertEqual(floorB2F.iconAssetPath, "Assets/items/key-item/elevator-key.png")
        XCTAssertEqual(tmBide.tmhmMoveID, "BIDE")
        XCTAssertEqual(tmBide.iconAssetPath, "Assets/items/tm/normal.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Assets/items/ball/poke.png").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("Assets/items/tm/normal.png").path))
        XCTAssertEqual(pidgey.catchRate, 255)
        XCTAssertTrue(squirtle.tmhmLearnset.contains("SURF"))
        XCTAssertTrue(squirtle.tmhmLearnset.contains("STRENGTH"))
        XCTAssertFalse(squirtle.tmhmLearnset.contains("FLY"))
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
        XCTAssertEqual(misty.party, [.init(speciesID: "STARYU", level: 18), .init(speciesID: "STARMIE", level: 21)])
        XCTAssertEqual(misty.trainerSpritePath, "Assets/battle/trainers/misty.png")
        XCTAssertEqual(misty.completionFlagID, "EVENT_BEAT_MISTY")
        XCTAssertEqual(route3Youngster.trainerSpritePath, "Assets/battle/trainers/youngster.png")
        XCTAssertEqual(superNerd.trainerSpritePath, "Assets/battle/trainers/supernerd.png")
        XCTAssertEqual(superNerd.completionFlagID, "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")
        XCTAssertEqual(mtMoon1FEncounters.landEncounterSurface, .floor)
        XCTAssertEqual(mtMoon1FEncounters.grassEncounterRate, 10)
        XCTAssertEqual(mtMoonB2FEncounters.suppressionZones.map(\.id), ["mt_moon_b2f_post_super_nerd_fossil_area"])
        XCTAssertEqual(mtMoonB2FEncounters.suppressionZones.first?.positions.count, 16)
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
        let ceruleanInteraction = try XCTUnwrap(loaded.fieldInteraction(id: "cerulean_pokecenter_pokemon_center_healing"))
        let mtMoonInteraction = try XCTUnwrap(loaded.fieldInteraction(id: "mt_moon_pokecenter_pokemon_center_healing"))
        let bikeShopInteraction = try XCTUnwrap(loaded.fieldInteraction(id: "bike_shop_purchase_offer"))
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
        XCTAssertEqual(
            ceruleanInteraction.healingSequence?.blackoutCheckpoint,
            .init(mapID: "CERULEAN_CITY", position: .init(x: 19, y: 18), facing: .down)
        )
        XCTAssertEqual(bikeShopInteraction.kind, .dialogueChoice)
        XCTAssertEqual(bikeShopInteraction.introDialogueID, "bike_shop_clerk_welcome")
        XCTAssertEqual(bikeShopInteraction.prompt.dialogueID, "bike_shop_clerk_do_you_like_it")
        XCTAssertEqual(bikeShopInteraction.acceptedDialogueID, "bike_shop_cant_afford")
        XCTAssertEqual(bikeShopInteraction.successDialogueID, "bike_shop_come_again")
        XCTAssertEqual(loaded.map(id: "PEWTER_GYM")?.defaultMusicID, "MUSIC_GYM")
        XCTAssertEqual(loaded.map(id: "ROUTE_3")?.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(loaded.map(id: "CERULEAN_POKECENTER")?.defaultMusicID, "MUSIC_POKECENTER")
        XCTAssertEqual(loaded.map(id: "CERULEAN_MART")?.defaultMusicID, "MUSIC_POKECENTER")
        XCTAssertEqual(loaded.map(id: "BIKE_SHOP")?.defaultMusicID, "MUSIC_CITIES2")
        XCTAssertEqual(loaded.map(id: "CERULEAN_BADGE_HOUSE")?.defaultMusicID, "MUSIC_CITIES1")
        XCTAssertEqual(loaded.map(id: "MT_MOON_POKECENTER")?.warps.allSatisfy { $0.usesPreviousMapTarget == false }, true)
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_1F")?.warps.prefix(2).allSatisfy { $0.usesPreviousMapTarget == false }, true)
        XCTAssertEqual(
            loaded.map(id: "CERULEAN_POKECENTER")?.objects.map(\.id),
            [
                "cerulean_pokecenter_nurse",
                "cerulean_pokecenter_super_nerd",
                "cerulean_pokecenter_gentleman",
                "cerulean_pokecenter_link_receptionist",
            ]
        )
        XCTAssertEqual(
            loaded.map(id: "BIKE_SHOP")?.objects.map(\.id),
            ["bike_shop_clerk", "bike_shop_middle_aged_woman", "bike_shop_youngster"]
        )
        XCTAssertEqual(
            loaded.map(id: "BIKE_SHOP")?.objects.first { $0.id == "bike_shop_clerk" }?.interactionReach,
            .overCounter
        )
        XCTAssertEqual(
            loaded.map(id: "CERULEAN_TRASHED_HOUSE")?.backgroundEvents.map(\.dialogueID),
            ["cerulean_trashed_house_wall_hole"]
        )
        XCTAssertNotNil(loaded.dialogue(id: "cerulean_trade_house_gambler"))
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
            loaded.mapScript(for: "CERULEAN_CITY")?.triggers.count,
            8
        )
        XCTAssertEqual(
            loaded.mapScript(for: "ROUTE_24")?.triggers.map(\.scriptID),
            ["route24_nugget_bridge_reward"]
        )
        XCTAssertEqual(loaded.map(id: "CERULEAN_GYM")?.defaultMusicID, "MUSIC_GYM")
        XCTAssertEqual(
            loaded.map(id: "CERULEAN_GYM")?.objects.map(\.id),
            ["cerulean_gym_misty", "cerulean_gym_cooltrainer_f", "cerulean_gym_swimmer", "cerulean_gym_gym_guide"]
        )
        XCTAssertEqual(loaded.map(id: "ROUTE_4")?.objects.first { $0.id == "route_4_tm_whirlwind" }?.pickupItemID, "TM_WHIRLWIND")
        XCTAssertEqual(loaded.map(id: "ROUTE_24")?.objects.first { $0.id == "route_24_tm_thunder_wave" }?.pickupItemID, "TM_THUNDER_WAVE")
        XCTAssertEqual(loaded.map(id: "ROUTE_25")?.warps.first?.targetMapID, "BILLS_HOUSE")
        XCTAssertEqual(loaded.map(id: "ROUTE_25")?.objects.first { $0.id == "route_25_tm_seismic_toss" }?.pickupItemID, "TM_SEISMIC_TOSS")
        XCTAssertEqual(
            loaded.map(id: "ROUTE_2")?.fieldObstacles.first { $0.id == "route_2_cut_tree_2_5" },
            .init(
                id: "route_2_cut_tree_2_5",
                kind: .cutTree,
                blockPosition: .init(x: 2, y: 5),
                triggerStepOffset: .init(x: 1, y: 0),
                requiredMoveID: "CUT",
                requiredBadgeID: "CASCADEBADGE",
                replacementBlockID: 0x6D,
                replacementStepCollisionTileIDs: [0x50, 0x2C, 0x50, 0x2C]
            )
        )
        XCTAssertEqual(loaded.map(id: "ROUTE_2")?.fieldObstacles.count, 6)
        XCTAssertFalse(loaded.map(id: "ROUTE_2")?.fieldObstacles.contains { $0.replacementBlockID == 0x0A } ?? true)
        XCTAssertEqual(loaded.map(id: "REDS_HOUSE_1F")?.fieldObstacles, [])
        XCTAssertEqual(loaded.map(id: "VIRIDIAN_POKECENTER")?.fieldObstacles, [])
        XCTAssertNotNil(loaded.trainerBattle(id: "opp_lass_4"))
        XCTAssertNotNil(loaded.trainerBattle(id: "opp_jr_trainer_m_2"))
        XCTAssertNotNil(loaded.trainerBattle(id: "opp_youngster_5"))
        XCTAssertEqual(
            loaded.script(id: "cerulean_city_rocket_reward")?.steps.map(\.action),
            ["showDialogue", "giveItem", "setObjectVisibility", "setObjectVisibility", "setObjectVisibility", "showDialogue"]
        )
        XCTAssertEqual(
            loaded.script(id: "route24_nugget_bridge_reward")?.steps.map(\.action),
            ["showDialogue", "giveItem", "showDialogue", "startBattle"]
        )
        XCTAssertEqual(loaded.script(id: "route24_nugget_bridge_reward")?.steps[1].continueOnFailure, false)
        XCTAssertEqual(
            loaded.script(id: "bike_shop_offer_purchase")?.steps.map(\.action),
            ["startFieldInteraction"]
        )
        XCTAssertEqual(
            loaded.script(id: "bike_shop_exchange_voucher")?.steps.map(\.action),
            ["showDialogue", "giveItem", "removeItem"]
        )
        XCTAssertEqual(loaded.script(id: "bike_shop_exchange_voucher")?.steps[1].continueOnFailure, false)
        XCTAssertEqual(
            loaded.dialogue(id: "ss_anne_captains_room_rub_captains_back")?.pages.last?.events,
            [
                .init(kind: .music, trackID: "MUSIC_PKMN_HEALED"),
                .init(kind: .restoreMapMusic, waitForCompletion: false),
            ]
        )
        XCTAssertEqual(
            loaded.script(id: "bills_house_bill_pokemon_interaction")?.steps.map(\.action),
            [
                "promptYesNo",
                "showDialogue",
                "performMovement",
                "setFlag",
                "setFlag",
                "setObjectVisibility",
                "setObjectPosition",
                "setObjectVisibility",
                "moveObject",
                "setFlag",
                "setFlag",
            ]
        )
        XCTAssertEqual(
            loaded.script(id: "bills_house_bill_ss_ticket")?.steps.map(\.action),
            ["showDialogue", "giveItem", "setObjectVisibility", "setObjectVisibility", "setObjectVisibility", "showDialogue"]
        )
        XCTAssertEqual(loaded.script(id: "bills_house_bill_ss_ticket")?.steps[1].continueOnFailure, false)
        XCTAssertEqual(
            loaded.script(id: "ss_anne_captains_room_captain_reward")?.steps.map(\.action),
            ["jumpIfFlagSet", "showDialogue", "setFlag", "showDialogue", "giveItem"]
        )
        XCTAssertEqual(loaded.script(id: "ss_anne_captains_room_captain_reward")?.steps.first?.flagID, "EVENT_GOT_HM01")
        XCTAssertEqual(loaded.script(id: "ss_anne_captains_room_captain_reward")?.steps.first?.stringValue, "ss_anne_captains_room_captain_after_reward")
        XCTAssertEqual(loaded.script(id: "ss_anne_captains_room_captain_reward")?.steps.last?.stringValue, "HM_CUT")
        XCTAssertEqual(loaded.script(id: "ss_anne_captains_room_captain_reward")?.steps.last?.successFlagID, "EVENT_GOT_HM01")
        XCTAssertEqual(
            loaded.script(id: "ss_anne_captains_room_captain_after_reward")?.steps.map(\.action),
            ["showDialogue"]
        )
        XCTAssertEqual(
            loaded.script(id: "cerulean_gym_misty_reward")?.steps.map(\.action),
            ["showDialogue", "setFlag", "giveItem", "awardBadge", "setFlag", "setFlag", "restoreMapMusic"]
        )
        XCTAssertNil(loaded.script(id: "cerulean_gym_misty_reward")?.steps[2].continueOnFailure)
        XCTAssertNotNil(loaded.dialogue(id: "cerulean_city_rival_pre_battle"))
        XCTAssertNotNil(loaded.dialogue(id: "cerulean_gym_misty_received_cascade_badge"))
        XCTAssertNotNil(loaded.dialogue(id: "cerulean_gym_misty_tm11_explanation"))
        XCTAssertNotNil(loaded.dialogue(id: "route24_cooltrainer_m1_contest_prize"))
        XCTAssertNotNil(loaded.dialogue(id: "bills_house_ss_ticket_received"))
        XCTAssertNotNil(loaded.dialogue(id: "field_move_new_badge_required"))
        XCTAssertNotNil(loaded.dialogue(id: "field_move_nothing_to_cut"))
        XCTAssertNotNil(loaded.dialogue(id: "field_move_used_cut"))
        XCTAssertNotNil(loaded.dialogue(id: "ss_anne_captains_room_captain_received_hm01"))
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
