import XCTest
import PokeDataModel

final class GameplayExtractionTests: XCTestCase {
    func testGameplayExtractorBuildsEarlyM4ManifestFromRepoSources() throws {
        let manifest = try extractGameplayManifest(source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()))

        XCTAssertEqual(manifest.maps.map(\.id), [
            "REDS_HOUSE_2F",
            "REDS_HOUSE_1F",
            "PALLET_TOWN",
            "ROUTE_1",
            "VIRIDIAN_CITY",
            "ROUTE_2",
            "VIRIDIAN_SCHOOL_HOUSE",
            "VIRIDIAN_NICKNAME_HOUSE",
            "VIRIDIAN_POKECENTER",
            "VIRIDIAN_MART",
            "VIRIDIAN_FOREST_SOUTH_GATE",
            "VIRIDIAN_FOREST",
            "VIRIDIAN_FOREST_NORTH_GATE",
            "OAKS_LAB",
        ])
        XCTAssertEqual(manifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(manifest.playerStart.position, .init(x: 4, y: 4))
        XCTAssertEqual(manifest.playerStart.playerName, "RED")
        XCTAssertEqual(manifest.playerStart.rivalName, "BLUE")
        XCTAssertEqual(manifest.tilesets.map(\.id), ["REDS_HOUSE_1", "REDS_HOUSE_2", "OVERWORLD", "DOJO", "FOREST", "FOREST_GATE", "HOUSE", "MART", "POKECENTER"])
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
                "EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_0",
                "EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_1",
                "EVENT_BEAT_VIRIDIAN_FOREST_TRAINER_2",
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
            manifest.fieldInteractions,
            [
                .init(
                    id: "pokemon_center_healing",
                    kind: .pokemonCenterHealing,
                    introDialogueID: "pokemon_center_welcome",
                    prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
                    acceptedDialogueID: "pokemon_center_need_your_pokemon",
                    successDialogueID: "pokemon_center_fighting_fit",
                    farewellDialogueID: "pokemon_center_farewell",
                    healingSequence: .init(
                        nurseObjectID: "viridian_pokecenter_nurse",
                        machineSoundEffectID: "SFX_HEALING_MACHINE",
                        healedAudioCueID: "pokemon_center_healed",
                        blackoutCheckpoint: .init(
                            mapID: "VIRIDIAN_CITY",
                            position: .init(x: 23, y: 26),
                            facing: .down
                        )
                    )
                ),
            ]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "viridian_pokecenter_nurse_heal" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "pokemon_center_healing")]
        )
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
        XCTAssertEqual(
            manifest.trainerAIMoveChoiceModifications.first { $0.trainerClass == "RIVAL1" }?.modifications,
            [1]
        )
        XCTAssertEqual(
            manifest.trainerAIMoveChoiceModifications.first { $0.trainerClass == "LORELEI" }?.modifications,
            [1, 2, 3]
        )
        XCTAssertEqual(manifest.species.count, 151)
        XCTAssertEqual(manifest.species.prefix(10).map(\.id), [
            "BULBASAUR",
            "IVYSAUR",
            "VENUSAUR",
            "CHARMANDER",
            "CHARMELEON",
            "CHARIZARD",
            "SQUIRTLE",
            "WARTORTLE",
            "BLASTOISE",
            "CATERPIE",
        ])
        XCTAssertNotNil(manifest.species.first { $0.id == "MEW" })
        let charmander = try XCTUnwrap(manifest.species.first { $0.id == "CHARMANDER" })
        XCTAssertEqual(charmander.primaryType, "FIRE")
        XCTAssertNil(charmander.secondaryType)
        XCTAssertEqual(charmander.baseExp, 65)
        XCTAssertEqual(charmander.growthRate, .mediumSlow)
        XCTAssertEqual(charmander.startingMoves, ["SCRATCH", "GROWL"])
        XCTAssertEqual(
            charmander.levelUpLearnset,
            [
                .init(level: 9, moveID: "EMBER"),
                .init(level: 15, moveID: "LEER"),
                .init(level: 22, moveID: "RAGE"),
                .init(level: 30, moveID: "SLASH"),
                .init(level: 38, moveID: "FLAMETHROWER"),
                .init(level: 46, moveID: "FIRE_SPIN"),
            ]
        )
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
        XCTAssertEqual(
            Array(squirtle.levelUpLearnset.prefix(2)),
            [.init(level: 8, moveID: "BUBBLE"), .init(level: 15, moveID: "WATER_GUN")]
        )
        let bulbasaur = try XCTUnwrap(manifest.species.first { $0.id == "BULBASAUR" })
        XCTAssertEqual(bulbasaur.primaryType, "GRASS")
        XCTAssertEqual(bulbasaur.secondaryType, "POISON")
        XCTAssertEqual(bulbasaur.baseExp, 64)
        XCTAssertEqual(bulbasaur.growthRate, .mediumSlow)
        XCTAssertEqual(
            Array(bulbasaur.levelUpLearnset.prefix(2)),
            [.init(level: 7, moveID: "LEECH_SEED"), .init(level: 13, moveID: "VINE_WHIP")]
        )
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
        let mrMime = try XCTUnwrap(manifest.species.first { $0.id == "MR_MIME" })
        XCTAssertEqual(mrMime.displayName, "Mr. Mime")
        XCTAssertEqual(
            mrMime.battleSprite,
            .init(
                frontImagePath: "Assets/battle/pokemon/front/mr.mime.png",
                backImagePath: "Assets/battle/pokemon/back/mr.mime.png"
            )
        )
        XCTAssertEqual(manifest.moves.count, 165)
        XCTAssertNotNil(manifest.moves.first { $0.id == "CUT" })
        XCTAssertNotNil(manifest.moves.first { $0.id == "SURF" })
        XCTAssertNotNil(manifest.moves.first { $0.id == "THUNDERBOLT" })
        XCTAssertEqual(manifest.items.map(\.id), ["POKE_BALL", "POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL", "MOON_STONE", "HP_UP", "OAKS_PARCEL"])
        XCTAssertEqual(manifest.items.first?.displayName, "POKé BALL")
        XCTAssertEqual(manifest.items.first?.price, 200)
        XCTAssertEqual(manifest.items.first?.battleUse, .ball)
        XCTAssertEqual(manifest.items.last?.displayName, "OAK's PARCEL")
        XCTAssertEqual(manifest.items.last?.isKeyItem, true)
        XCTAssertEqual(manifest.items.last?.price, 0)
        XCTAssertEqual(charmander.catchRate, 45)
        XCTAssertEqual(pidgey.catchRate, 255)
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
            "opp_bug_catcher_1",
            "opp_bug_catcher_2",
            "opp_bug_catcher_3",
            "opp_rival1_1",
            "opp_rival1_2",
            "opp_rival1_3",
        ])
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.party,
            [.init(speciesID: "WEEDLE", level: 6), .init(speciesID: "CATERPIE", level: 6)]
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.encounterAudioCueID, "trainer_intro_male")
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.trainerSpritePath,
            "Assets/battle/trainers/bugcatcher.png"
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.baseRewardMoney, 10)
        XCTAssertNil(manifest.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.playerLoseDialogueID)
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rival1_1" }?.party, [.init(speciesID: "SQUIRTLE", level: 5)])
        XCTAssertNil(manifest.trainerBattles.first { $0.id == "opp_rival1_1" }?.encounterAudioCueID)
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_rival1_1" }?.trainerSpritePath,
            "Assets/battle/trainers/rival1.png"
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rival1_1" }?.baseRewardMoney, 35)
        XCTAssertEqual(manifest.commonBattleText.wantsToFight, "{trainerName} wants to fight!")
        XCTAssertEqual(manifest.commonBattleText.moneyForWinning, "{playerName} got ¥{money} for winning!")
        XCTAssertEqual(
            manifest.commonBattleText.playerBlackedOut,
            "{playerName} is out of useable POKéMON! {playerName} blacked out!"
        )
        XCTAssertEqual(
            manifest.playerStart.defaultBlackoutCheckpoint,
            .init(mapID: "PALLET_TOWN", position: .init(x: 5, y: 6), facing: .down)
        )
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

        let route2 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_2" })
        XCTAssertEqual(route2.defaultMusicID, "MUSIC_ROUTES1")
        XCTAssertEqual(route2.connections.map(\.targetMapID), ["PEWTER_CITY", "VIRIDIAN_CITY"])
        XCTAssertEqual(route2.objects.map(\.id), ["route_2_moon_stone", "route_2_hp_up"])
        XCTAssertEqual(route2.objects.map(\.pickupItemID), ["MOON_STONE", "HP_UP"])
        XCTAssertEqual(route2.warps.first { $0.origin == .init(x: 3, y: 43) }?.targetMapID, "VIRIDIAN_FOREST_SOUTH_GATE")
        XCTAssertEqual(route2.warps.first { $0.origin == .init(x: 3, y: 11) }?.targetMapID, "VIRIDIAN_FOREST_NORTH_GATE")

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
        XCTAssertEqual(
            viridianMart.objects.first { $0.id == "viridian_mart_clerk" }?.interactionTriggers,
            [
                .init(
                    conditions: [.init(kind: "flagUnset", flagID: "EVENT_GOT_OAKS_PARCEL")],
                    scriptID: "viridian_mart_oaks_parcel"
                ),
                .init(
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_OAKS_PARCEL"),
                        .init(kind: "flagUnset", flagID: "EVENT_OAK_GOT_PARCEL"),
                    ],
                    dialogueID: "viridian_mart_clerk_after_parcel"
                ),
                .init(
                    conditions: [.init(kind: "flagSet", flagID: "EVENT_OAK_GOT_PARCEL")],
                    martID: "viridian_mart"
                ),
            ]
        )
        XCTAssertEqual(viridianMart.objects.map(\.id), [
            "viridian_mart_clerk",
            "viridian_mart_youngster",
            "viridian_mart_cooltrainer",
        ])
        XCTAssertEqual(
            manifest.marts,
            [
                .init(
                    id: "viridian_mart",
                    mapID: "VIRIDIAN_MART",
                    clerkObjectID: "viridian_mart_clerk",
                    stockItemIDs: ["POKE_BALL", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL"]
                )
            ]
        )

        let viridianForestSouthGate = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_FOREST_SOUTH_GATE" })
        XCTAssertEqual(viridianForestSouthGate.objects.map(\.id), [
            "viridian_forest_south_gate_girl",
            "viridian_forest_south_gate_little_girl",
        ])

        let viridianForest = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_FOREST" })
        XCTAssertEqual(viridianForest.defaultMusicID, "MUSIC_DUNGEON2")
        XCTAssertEqual(viridianForest.objects.map(\.id), [
            "viridian_forest_youngster_1",
            "viridian_forest_bug_catcher_1",
            "viridian_forest_bug_catcher_2",
            "viridian_forest_bug_catcher_3",
            "viridian_forest_antidote",
            "viridian_forest_potion",
            "viridian_forest_poke_ball",
            "viridian_forest_youngster_5",
        ])
        XCTAssertEqual(viridianForest.objects.first { $0.id == "viridian_forest_antidote" }?.pickupItemID, "ANTIDOTE")
        XCTAssertEqual(viridianForest.objects.first { $0.id == "viridian_forest_bug_catcher_1" }?.trainerEngageDistance, 4)
        XCTAssertEqual(viridianForest.objects.first { $0.id == "viridian_forest_bug_catcher_1" }?.trainerIntroDialogueID, "viridian_forest_youngster2_battle")
        XCTAssertEqual(viridianForest.objects.first { $0.id == "viridian_forest_bug_catcher_1" }?.trainerEndBattleDialogueID, "viridian_forest_youngster2_end_battle")
        XCTAssertEqual(viridianForest.objects.first { $0.id == "viridian_forest_bug_catcher_1" }?.trainerAfterBattleDialogueID, "viridian_forest_youngster2_after_battle")
        XCTAssertEqual(viridianForest.backgroundEvents.map(\.dialogueID), [
            "viridian_forest_trainer_tips_1",
            "viridian_forest_use_antidote_sign",
            "viridian_forest_trainer_tips_2",
            "viridian_forest_trainer_tips_3",
            "viridian_forest_trainer_tips_4",
            "viridian_forest_leaving_sign",
        ])

        let viridianForestNorthGate = try XCTUnwrap(manifest.maps.first { $0.id == "VIRIDIAN_FOREST_NORTH_GATE" })
        XCTAssertEqual(viridianForestNorthGate.objects.map(\.id), [
            "viridian_forest_north_gate_super_nerd",
            "viridian_forest_north_gate_gramps",
        ])

        let route1Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_1" })
        XCTAssertEqual(route1Encounters.grassEncounterRate, 25)
        XCTAssertEqual(route1Encounters.waterEncounterRate, 0)
        XCTAssertEqual(route1Encounters.grassSlots.first, .init(speciesID: "PIDGEY", level: 3))
        XCTAssertEqual(route1Encounters.grassSlots.last, .init(speciesID: "PIDGEY", level: 5))
        XCTAssertEqual(Set(route1Encounters.grassSlots.map(\.speciesID)), Set(["PIDGEY", "RATTATA"]))

        let route2Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_2" })
        XCTAssertEqual(route2Encounters.grassEncounterRate, 25)
        XCTAssertEqual(Set(route2Encounters.grassSlots.map(\.speciesID)), Set(["PIDGEY", "RATTATA", "WEEDLE", "CATERPIE"]))

        let viridianForestEncounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "VIRIDIAN_FOREST" })
        XCTAssertEqual(viridianForestEncounters.grassEncounterRate, 8)
        XCTAssertTrue(Set(viridianForestEncounters.grassSlots.map(\.speciesID)).isSuperset(of: Set(["WEEDLE", "CATERPIE", "KAKUNA", "METAPOD", "PIKACHU"])))

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
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pokemon_center_welcome" }?.pages.first?.lines, ["Welcome to our", "POKéMON CENTER!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pokemon_center_shall_we_heal" }?.pages.first?.lines, ["Shall we heal your", "POKéMON?"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pokemon_center_need_your_pokemon" }?.pages.first?.lines, ["OK. We'll need", "your POKéMON."])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pokemon_center_fighting_fit" }?.pages.first?.lines, ["Thank you!", "Your POKéMON are", "fighting fit!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pokemon_center_farewell" }?.pages.first?.lines, ["We hope to see", "you again!"])

        let extractedDialogueIDs = Set(manifest.dialogues.map(\.id))
        let parcelHandoff = try XCTUnwrap(manifest.scripts.first { $0.id == "oaks_lab_parcel_handoff" })
        let missingDialogueReferences = parcelHandoff.steps
            .compactMap(\.dialogueID)
            .filter { extractedDialogueIDs.contains($0) == false }
        XCTAssertEqual(missingDialogueReferences, [])
    }

    func testExtractorWritesDeterministicGameplayManifestJSON() throws {
        let repoRoot = PokeExtractCLITestSupport.repoRoot()
        let firstOutputRoot = try PokeExtractCLITestSupport.temporaryDirectory()
        let secondOutputRoot = try PokeExtractCLITestSupport.temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: firstOutputRoot)
        )
        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: secondOutputRoot)
        )

        let first = try Data(contentsOf: firstOutputRoot.appendingPathComponent("Red/gameplay_manifest.json"))
        let second = try Data(contentsOf: secondOutputRoot.appendingPathComponent("Red/gameplay_manifest.json"))
        XCTAssertEqual(first, second)

        let decoded = try JSONDecoder().decode(GameplayManifest.self, from: first)
        XCTAssertEqual(decoded.maps.count, 14)
        XCTAssertEqual(decoded.tilesets.count, 9)
        XCTAssertEqual(decoded.overworldSprites.count, 23)
        XCTAssertEqual(decoded.items.count, 8)
        XCTAssertEqual(decoded.marts.count, 1)
        XCTAssertEqual(decoded.wildEncounterTables.count, 3)
        XCTAssertGreaterThan(decoded.dialogues.count, 100)
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_gramps" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_ill_take_you_on" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "pokemon_center_welcome" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "viridian_forest_youngster2_battle" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "pickup_found_moon_stone" })
        XCTAssertNotNil(decoded.fieldInteractions.first { $0.id == "pokemon_center_healing" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "OAKS_LAB" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "VIRIDIAN_CITY" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_rival1_1" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_bug_catcher_1" })
        XCTAssertEqual(decoded.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.trainerSpritePath, "Assets/battle/trainers/bugcatcher.png")
        XCTAssertEqual(decoded.commonBattleText.trainerSentOut, "{trainerName} sent out {enemyPokemon}!")
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

    func testGameplayExtractorPreservesCurrentSliceDialogueSoundCommandsAndMoveAudio() throws {
        let manifest = try extractGameplayManifest(source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()))

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
}
