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

    func testGameplayExtractorBuildsEarlyM4ManifestFromRepoSources() throws {
        let manifest = try extractGameplayManifest(source: SourceTree(repoRoot: repoRoot()))

        XCTAssertEqual(manifest.maps.map(\.id), [
            "REDS_HOUSE_2F",
            "REDS_HOUSE_1F",
            "PALLET_TOWN",
            "ROUTE_1",
            "VIRIDIAN_CITY",
            "VIRIDIAN_SCHOOL_HOUSE",
            "VIRIDIAN_NICKNAME_HOUSE",
            "VIRIDIAN_POKECENTER",
            "VIRIDIAN_MART",
            "OAKS_LAB",
        ])
        XCTAssertEqual(manifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(manifest.playerStart.position, .init(x: 4, y: 4))
        XCTAssertEqual(manifest.playerStart.playerName, "RED")
        XCTAssertEqual(manifest.playerStart.rivalName, "BLUE")
        XCTAssertEqual(manifest.tilesets.map(\.id), ["REDS_HOUSE_1", "REDS_HOUSE_2", "OVERWORLD", "DOJO", "HOUSE", "MART", "POKECENTER"])
        XCTAssertEqual(manifest.tilesets.first { $0.id == "HOUSE" }?.imagePath, "Assets/field/tilesets/house.png")
        XCTAssertEqual(manifest.tilesets.first { $0.id == "HOUSE" }?.blocksetPath, "Assets/field/blocksets/house.bst")
        XCTAssertEqual(manifest.overworldSprites.map(\.id), [
            "SPRITE_RED",
            "SPRITE_OAK",
            "SPRITE_BLUE",
            "SPRITE_MOM",
            "SPRITE_GIRL",
            "SPRITE_FISHER",
            "SPRITE_SCIENTIST",
            "SPRITE_YOUNGSTER",
            "SPRITE_GAMBLER",
            "SPRITE_GAMBLER_ASLEEP",
            "SPRITE_BRUNETTE_GIRL",
            "SPRITE_COOLTRAINER_F",
            "SPRITE_BALDING_GUY",
            "SPRITE_LITTLE_GIRL",
            "SPRITE_BIRD",
            "SPRITE_CLIPBOARD",
            "SPRITE_CLERK",
            "SPRITE_COOLTRAINER_M",
            "SPRITE_NURSE",
            "SPRITE_GENTLEMAN",
            "SPRITE_LINK_RECEPTIONIST",
            "SPRITE_POKE_BALL",
            "SPRITE_POKEDEX",
        ])

        let palletTown = try XCTUnwrap(manifest.maps.first { $0.id == "PALLET_TOWN" })
        XCTAssertEqual(palletTown.borderBlockID, 0x0B)
        XCTAssertEqual(palletTown.stepCollisionTileIDs.count, palletTown.stepWidth * palletTown.stepHeight)
        XCTAssertEqual(palletTown.connections.map(\.direction), [.north, .south])
        XCTAssertEqual(palletTown.connections.map(\.targetMapID), ["ROUTE_1", "ROUTE_21"])
        XCTAssertEqual(palletTown.connections.map(\.offset), [0, 0])
        XCTAssertEqual(palletTown.connections.first?.targetBlockWidth, 10)
        XCTAssertEqual(palletTown.connections.first?.targetBlockHeight, 18)
        XCTAssertEqual(palletTown.warps.count, 3)
        XCTAssertEqual(palletTown.warps[0].targetMapID, "REDS_HOUSE_1F")
        XCTAssertEqual(palletTown.warps[0].targetPosition, .init(x: 2, y: 7))
        XCTAssertEqual(palletTown.warps[0].targetFacing, .up)
        XCTAssertEqual(palletTown.warps[2].targetMapID, "OAKS_LAB")
        XCTAssertEqual(palletTown.warps[2].targetPosition, .init(x: 5, y: 11))
        XCTAssertEqual(palletTown.warps[2].targetFacing, .up)
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
        XCTAssertEqual(
            palletTown.objects.first { $0.id == "pallet_town_girl" }?.movementBehavior,
            .init(idleMode: .walk, axis: .any, home: .init(x: 3, y: 8))
        )
        XCTAssertEqual(
            palletTown.objects.first { $0.id == "pallet_town_fisher" }?.movementBehavior,
            .init(idleMode: .walk, axis: .any, home: .init(x: 11, y: 14))
        )

        let oaksLab = try XCTUnwrap(manifest.maps.first { $0.id == "OAKS_LAB" })
        XCTAssertEqual(oaksLab.borderBlockID, 0x03)
        XCTAssertEqual(oaksLab.warps.map(\.targetPosition), [.init(x: 12, y: 11), .init(x: 12, y: 11)])
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
                "EVENT_GOT_POTION_SAMPLE",
                "EVENT_GOT_OAKS_PARCEL",
                "EVENT_OAK_GOT_PARCEL",
                "EVENT_GOT_POKEDEX",
                "EVENT_VIRIDIAN_GYM_OPEN",
                "EVENT_1ST_ROUTE22_RIVAL_BATTLE",
                "EVENT_2ND_ROUTE22_RIVAL_BATTLE",
                "EVENT_ROUTE22_RIVAL_WANTS_BATTLE",
            ]
        )
        XCTAssertEqual(manifest.scripts.map(\.id), [
            "reds_house_1f_mom_heal",
            "viridian_pokecenter_nurse_heal",
            "route_1_potion_sample",
            "viridian_city_old_man_blocks_north_exit",
            "viridian_city_gym_locked_pushback",
            "viridian_mart_oaks_parcel",
            "oaks_lab_parcel_handoff",
            "oaks_lab_choose_charmander",
            "oaks_lab_choose_squirtle",
            "oaks_lab_choose_bulbasaur",
            "pallet_town_oak_intro",
            "oaks_lab_dont_go_away",
            "oaks_lab_rival_picks_after_charmander",
            "oaks_lab_rival_picks_after_squirtle",
            "oaks_lab_rival_picks_after_bulbasaur",
            "oaks_lab_rival_challenge_vs_squirtle",
            "oaks_lab_rival_challenge_vs_bulbasaur",
            "oaks_lab_rival_challenge_vs_charmander",
            "oaks_lab_rival_exit_after_battle",
        ])
        XCTAssertEqual(
            oaksLab.objects.first { $0.id == "oaks_lab_object_8" }?.movementBehavior,
            .init(idleMode: .walk, axis: .upDown, home: .init(x: 1, y: 9))
        )
        let oakIntroScript = try XCTUnwrap(manifest.scripts.first { $0.id == "pallet_town_oak_intro" })
        XCTAssertEqual(
            oakIntroScript.steps.compactMap { $0.movement?.kind },
            [.fixedPath, .pathToPlayerAdjacent, .palletEscort, .fixedPath, .fixedPath]
        )
        let palletEscortMovement = try XCTUnwrap(oakIntroScript.steps.first { $0.movement?.kind == .palletEscort }?.movement)
        let leftLaneEscort = try XCTUnwrap(palletEscortMovement.variants.first { $0.id == "player_left_lane" })
        XCTAssertEqual(
            leftLaneEscort.actors.first { $0.actorID == "player" }?.path,
            [.down, .down, .down, .down, .down, .down, .left, .down, .down, .down, .down, .down, .right, .right, .right, .up, .up]
        )
        let rivalBulbasaurPickup = try XCTUnwrap(manifest.scripts.first { $0.id == "oaks_lab_rival_picks_after_squirtle" })
        XCTAssertEqual(rivalBulbasaurPickup.steps.map(\.action), ["performMovement", "showDialogue", "setObjectVisibility", "showDialogue"])
        XCTAssertEqual(rivalBulbasaurPickup.steps[2].objectID, "oaks_lab_poke_ball_bulbasaur")
        let rivalExitScript = try XCTUnwrap(manifest.scripts.first { $0.id == "oaks_lab_rival_exit_after_battle" })
        XCTAssertEqual(rivalExitScript.steps.compactMap(\.movement?.kind), [.fixedPath])
        XCTAssertEqual(rivalExitScript.steps.last?.action, "restoreMapMusic")
        XCTAssertEqual(manifest.species.map(\.id), ["CHARMANDER", "SQUIRTLE", "BULBASAUR", "PIDGEY", "RATTATA"])
        let charmander = try XCTUnwrap(manifest.species.first { $0.id == "CHARMANDER" })
        XCTAssertEqual(charmander.primaryType, "FIRE")
        XCTAssertNil(charmander.secondaryType)
        XCTAssertEqual(charmander.baseExp, 65)
        XCTAssertEqual(charmander.growthRate, .mediumSlow)
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
        XCTAssertEqual(squirtle.baseExp, 66)
        XCTAssertEqual(squirtle.growthRate, .mediumSlow)
        let bulbasaur = try XCTUnwrap(manifest.species.first { $0.id == "BULBASAUR" })
        XCTAssertEqual(bulbasaur.primaryType, "GRASS")
        XCTAssertEqual(bulbasaur.secondaryType, "POISON")
        XCTAssertEqual(bulbasaur.baseExp, 64)
        XCTAssertEqual(bulbasaur.growthRate, .mediumSlow)
        let pidgey = try XCTUnwrap(manifest.species.first { $0.id == "PIDGEY" })
        XCTAssertEqual(pidgey.primaryType, "NORMAL")
        XCTAssertEqual(pidgey.secondaryType, "FLYING")
        XCTAssertEqual(pidgey.baseExp, 55)
        XCTAssertEqual(
            pidgey.battleSprite,
            .init(
                frontImagePath: "Assets/battle/pokemon/front/pidgey.png",
                backImagePath: "Assets/battle/pokemon/back/pidgey.png"
            )
        )
        let rattata = try XCTUnwrap(manifest.species.first { $0.id == "RATTATA" })
        XCTAssertEqual(rattata.primaryType, "NORMAL")
        XCTAssertNil(rattata.secondaryType)
        XCTAssertEqual(rattata.baseExp, 57)
        XCTAssertEqual(rattata.growthRate, .mediumFast)
        XCTAssertEqual(manifest.moves.map(\.id), ["SCRATCH", "GUST", "TACKLE", "TAIL_WHIP", "GROWL"])
        XCTAssertEqual(manifest.items.map(\.id), ["POTION", "OAKS_PARCEL"])
        XCTAssertEqual(manifest.items.first?.displayName, "POTION")
        XCTAssertEqual(manifest.items.last?.displayName, "OAK's PARCEL")
        XCTAssertEqual(manifest.items.last?.isKeyItem, true)
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
        XCTAssertEqual(manifest.maps.first { $0.id == "REDS_HOUSE_2F" }?.warps.first?.targetPosition, .init(x: 7, y: 1))
        XCTAssertEqual(manifest.maps.first { $0.id == "REDS_HOUSE_1F" }?.warps.first?.targetPosition, .init(x: 5, y: 5))
        XCTAssertNil(manifest.mapScripts.first { $0.mapID == "ROUTE_1" })
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "VIRIDIAN_CITY" }?.triggers.map(\.scriptID),
            ["viridian_city_gym_locked_pushback", "viridian_city_old_man_blocks_north_exit"]
        )
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "VIRIDIAN_MART" }?.triggers.map(\.scriptID),
            ["viridian_mart_oaks_parcel"]
        )

        let route1 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_1" })
        XCTAssertEqual(route1.defaultMusicID, "MUSIC_ROUTES1")
        XCTAssertEqual(route1.connections.map(\.targetMapID), ["VIRIDIAN_CITY", "PALLET_TOWN"])
        XCTAssertEqual(route1.objects.map(\.id), ["route_1_youngster_1", "route_1_youngster_2"])

        let viridianCity = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_CITY" })
        XCTAssertEqual(viridianCity.defaultMusicID, "MUSIC_CITIES1")
        XCTAssertEqual(viridianCity.warps[0].targetMapID, "VIRIDIAN_POKECENTER")
        XCTAssertEqual(viridianCity.warps[1].targetMapID, "VIRIDIAN_MART")
        XCTAssertEqual(viridianCity.warps[2].targetMapID, "VIRIDIAN_SCHOOL_HOUSE")
        XCTAssertEqual(viridianCity.warps[3].targetMapID, "VIRIDIAN_NICKNAME_HOUSE")
        XCTAssertEqual(viridianCity.backgroundEvents.map(\.dialogueID), [
            "viridian_city_sign",
            "viridian_city_trainer_tips_1",
            "viridian_city_trainer_tips_2",
            "viridian_city_mart_sign",
            "viridian_city_pokecenter_sign",
            "viridian_city_gym_sign",
        ])

        let viridianPokecenter = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_POKECENTER" })
        XCTAssertEqual(viridianPokecenter.tileset, "POKECENTER")
        XCTAssertEqual(viridianPokecenter.objects.first { $0.id == "viridian_pokecenter_nurse" }?.interactionReach, .overCounter)
        XCTAssertEqual(viridianPokecenter.objects.first { $0.id == "viridian_pokecenter_nurse" }?.interactionScriptID, "viridian_pokecenter_nurse_heal")
        XCTAssertEqual(viridianPokecenter.objects.map(\.id), [
            "viridian_pokecenter_nurse",
            "viridian_pokecenter_gentleman",
            "viridian_pokecenter_cooltrainer",
            "viridian_pokecenter_link_receptionist",
        ])

        let viridianSchoolHouse = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_SCHOOL_HOUSE" })
        XCTAssertEqual(viridianSchoolHouse.tileset, "HOUSE")
        XCTAssertEqual(viridianSchoolHouse.objects.map(\.id), [
            "viridian_school_house_brunette_girl",
            "viridian_school_house_cooltrainer_f",
        ])

        let viridianNicknameHouse = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_NICKNAME_HOUSE" })
        XCTAssertEqual(viridianNicknameHouse.tileset, "HOUSE")
        XCTAssertEqual(viridianNicknameHouse.objects.map(\.id), [
            "viridian_nickname_house_balding_guy",
            "viridian_nickname_house_little_girl",
            "viridian_nickname_house_spearow",
            "viridian_nickname_house_speary_sign",
        ])

        let viridianMart = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_MART" })
        XCTAssertEqual(viridianMart.tileset, "MART")
        XCTAssertEqual(viridianMart.objects.first { $0.id == "viridian_mart_clerk" }?.interactionReach, .overCounter)
        XCTAssertEqual(viridianMart.objects.map(\.id), [
            "viridian_mart_clerk",
            "viridian_mart_youngster",
            "viridian_mart_cooltrainer",
        ])

        let route1Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_1" })
        XCTAssertEqual(route1Encounters.grassEncounterRate, 25)
        XCTAssertEqual(route1Encounters.waterEncounterRate, 0)
        XCTAssertEqual(route1Encounters.grassSlots.first, .init(speciesID: "PIDGEY", level: 3))
        XCTAssertEqual(route1Encounters.grassSlots.last, .init(speciesID: "PIDGEY", level: 5))
        XCTAssertEqual(Set(route1Encounters.grassSlots.map(\.speciesID)), Set(["PIDGEY", "RATTATA"]))

        let redSprite = try XCTUnwrap(manifest.overworldSprites.first { $0.id == "SPRITE_RED" })
        XCTAssertEqual(redSprite.walkingFrames?.down, .init(x: 0, y: 48, width: 16, height: 16))
        XCTAssertEqual(redSprite.walkingFrames?.up, .init(x: 0, y: 64, width: 16, height: 16))
        XCTAssertEqual(redSprite.walkingFrames?.left, .init(x: 0, y: 80, width: 16, height: 16))
        XCTAssertEqual(redSprite.walkingFrames?.right, .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true))
        XCTAssertNil(manifest.overworldSprites.first { $0.id == "SPRITE_MOM" }?.walkingFrames)

        let oakDialogue = try XCTUnwrap(manifest.dialogues.first { $0.id == "pallet_town_oak_its_unsafe" })
        XCTAssertEqual(oakDialogue.pages.first?.lines.first, "OAK: It's unsafe!")
        XCTAssertEqual(oakDialogue.pages.last?.lines.last, "me!")
        XCTAssertNotNil(manifest.dialogues.first { $0.id == "oaks_lab_rival_gramps" })

        let extractedDialogueIDs = Set(manifest.dialogues.map(\.id))
        let parcelHandoff = try XCTUnwrap(manifest.scripts.first { $0.id == "oaks_lab_parcel_handoff" })
        let missingDialogueReferences = parcelHandoff.steps
            .compactMap(\.dialogueID)
            .filter { extractedDialogueIDs.contains($0) == false }
        XCTAssertEqual(missingDialogueReferences, [])
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
        XCTAssertEqual(decoded.maps.count, 10)
        XCTAssertEqual(decoded.tilesets.count, 7)
        XCTAssertEqual(decoded.overworldSprites.count, 23)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.wildEncounterTables.count, 1)
        XCTAssertGreaterThan(decoded.dialogues.count, 85)
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_gramps" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_ill_take_you_on" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "viridian_pokecenter_nurse_heal" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "OAKS_LAB" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "VIRIDIAN_CITY" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_rival1_1" })
        XCTAssertGreaterThan(decoded.typeEffectiveness.count, 0)
        XCTAssertEqual(decoded.tilesets.first?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(decoded.tilesets.first?.blocksetPath, "Assets/field/blocksets/reds_house.bst")
        XCTAssertEqual(decoded.overworldSprites.first?.facingFrames.down, .init(x: 0, y: 0, width: 16, height: 16))
        XCTAssertEqual(decoded.overworldSprites.first?.walkingFrames?.down, .init(x: 0, y: 48, width: 16, height: 16))
        XCTAssertEqual(
            decoded.species.first { $0.id == "CHARMANDER" }?.battleSprite?.frontImagePath,
            "Assets/battle/pokemon/front/charmander.png"
        )
        XCTAssertEqual(
            decoded.species.first { $0.id == "PIDGEY" }?.battleSprite?.frontImagePath,
            "Assets/battle/pokemon/front/pidgey.png"
        )
    }

    func testAudioExtractorBuildsEarlyM4ManifestFromRepoSources() throws {
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
                .init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "VIRIDIAN_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_NICKNAME_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_SCHOOL_HOUSE", musicID: "MUSIC_CITIES1"),
            ]
        )

        let cueByID = Dictionary(uniqueKeysWithValues: manifest.cues.map { ($0.id, $0) })
        XCTAssertEqual(cueByID["title_default"]?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(cueByID["oak_intro"]?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(cueByID["rival_intro"]?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(cueByID["rival_exit"]?.entryID, "alternateStart")
        XCTAssertEqual(cueByID["trainer_battle"]?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(cueByID["mom_heal"]?.trackID, "MUSIC_PKMN_HEALED")
        XCTAssertEqual(cueByID["mom_heal"]?.waitForCompletion, true)
        XCTAssertEqual(cueByID["mom_heal"]?.resumeMusicAfterCompletion, true)

        let requiredTrackIDs: Set<String> = [
            "MUSIC_TITLE_SCREEN",
            "MUSIC_PALLET_TOWN",
            "MUSIC_OAKS_LAB",
            "MUSIC_ROUTES1",
            "MUSIC_CITIES1",
            "MUSIC_POKECENTER",
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

        let soundEffectsByID = Dictionary(uniqueKeysWithValues: manifest.soundEffects.map { ($0.id, $0) })
        XCTAssertEqual(soundEffectsByID["SFX_PRESS_AB"]?.requestedChannels, [5])
        XCTAssertEqual(soundEffectsByID["SFX_COLLISION"]?.requestedChannels, [5])
        XCTAssertEqual(soundEffectsByID["SFX_GO_INSIDE"]?.requestedChannels, [8])
        XCTAssertEqual(soundEffectsByID["SFX_GO_OUTSIDE"]?.requestedChannels, [8])
        XCTAssertEqual(soundEffectsByID["SFX_LEVEL_UP"]?.requestedChannels, [5, 6, 7])
        XCTAssertEqual(soundEffectsByID["SFX_POUND"]?.requestedChannels, [8])
    }

    func testGameplayExtractorPreservesCurrentSliceDialogueSoundCommandsAndMoveAudio() throws {
        let manifest = try extractGameplayManifest(source: SourceTree(repoRoot: repoRoot()))

        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "route_1_youngster_1_got_potion" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "viridian_mart_clerk_parcel_quest" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "oaks_lab_oak_deliver_parcel" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "oaks_lab_received_mon_charmander" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "oaks_lab_rival_received_mon_bulbasaur" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "oaks_lab_oak_got_pokedex" }?.pages.last?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )

        XCTAssertEqual(
            manifest.moves.first { $0.id == "SCRATCH" }?.battleAudio,
            .init(kind: .soundEffect, soundEffectID: "SFX_DAMAGE", frequencyModifier: 0, tempoModifier: 128)
        )
        XCTAssertEqual(
            manifest.moves.first { $0.id == "TACKLE" }?.battleAudio,
            .init(kind: .soundEffect, soundEffectID: "SFX_SUPER_EFFECTIVE", frequencyModifier: 16, tempoModifier: 160)
        )
        XCTAssertEqual(
            manifest.moves.first { $0.id == "GROWL" }?.battleAudio,
            .init(kind: .cry, soundEffectID: nil, frequencyModifier: 0, tempoModifier: 192)
        )
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

    func testAudioExtractorIncludesTitleScreenDrumPreludeEvents() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let titleTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_TITLE_SCREEN" })
        let channelFour = try XCTUnwrap(
            titleTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 4 }
        )
        let firstEvent = try XCTUnwrap(channelFour.prelude.first)

        XCTAssertFalse(channelFour.prelude.isEmpty)
        XCTAssertEqual(firstEvent.waveform, .noise)
        XCTAssertGreaterThan(try XCTUnwrap(firstEvent.frequencyHz), 0)
        XCTAssertNotNil(firstEvent.noiseShortMode)
        XCTAssertGreaterThan(firstEvent.duration, 0)
    }

    func testAudioExtractorCarriesPitchSlideTargetsIntoPkmnHealedLead() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let healTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_PKMN_HEALED" })
        let channelOne = try XCTUnwrap(
            healTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let opening = Array(channelOne.prelude.prefix(3))
        let firstSlideTarget = try XCTUnwrap(opening[0].pitchSlideTargetHz)
        let firstFrequency = try XCTUnwrap(opening[0].frequencyHz)
        let secondSlideTarget = try XCTUnwrap(opening[1].pitchSlideTargetHz)
        let secondFrequency = try XCTUnwrap(opening[1].frequencyHz)
        let thirdSlideTarget = try XCTUnwrap(opening[2].pitchSlideTargetHz)
        let slideFrames = opening.compactMap(\.pitchSlideFrameCount)

        XCTAssertEqual(opening.count, 3)
        XCTAssertEqual(slideFrames, [14, 13, 14])
        XCTAssertEqual(firstSlideTarget, firstFrequency, accuracy: 0.000_001)
        XCTAssertLessThan(secondSlideTarget, secondFrequency)
        XCTAssertEqual(thirdSlideTarget, 661.979_797_979_798, accuracy: 0.000_001)
    }

    func testAudioExtractorUsesASMFrequencyTableForPerfectPitchSquareChannel() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelOne = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let firstEvent = try XCTUnwrap(channelOne.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 370.259_887_005_649_7, accuracy: 0.000_001)
    }

    func testAudioExtractorUsesWaveChannelFrequencyFormulaForOakIntroCounterline() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelThree = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 3 }
        )
        let firstEvent = try XCTUnwrap(channelThree.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 368.179_775_280_898_87, accuracy: 0.000_001)
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
        XCTAssertEqual(decoded.mapRoutes.count, 10)
        XCTAssertEqual(decoded.cues.count, 6)
        XCTAssertEqual(decoded.tracks.count, 10)
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
