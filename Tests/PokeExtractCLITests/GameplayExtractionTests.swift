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
            "ROUTE_22",
            "ROUTE_22_GATE",
            "ROUTE_2",
            "VIRIDIAN_SCHOOL_HOUSE",
            "VIRIDIAN_NICKNAME_HOUSE",
            "VIRIDIAN_POKECENTER",
            "VIRIDIAN_MART",
            "VIRIDIAN_FOREST_SOUTH_GATE",
            "VIRIDIAN_FOREST",
            "VIRIDIAN_FOREST_NORTH_GATE",
            "OAKS_LAB",
            "PEWTER_CITY",
            "PEWTER_POKECENTER",
            "PEWTER_MART",
            "PEWTER_NIDORAN_HOUSE",
            "PEWTER_SPEECH_HOUSE",
            "MUSEUM_1F",
            "MUSEUM_2F",
            "PEWTER_GYM",
            "ROUTE_3",
            "ROUTE_4",
            "CERULEAN_CITY",
            "CERULEAN_POKECENTER",
            "CERULEAN_MART",
            "BIKE_SHOP",
            "CERULEAN_TRADE_HOUSE",
            "CERULEAN_BADGE_HOUSE",
            "CERULEAN_TRASHED_HOUSE",
            "CERULEAN_GYM",
            "ROUTE_24",
            "ROUTE_25",
            "BILLS_HOUSE",
            "MT_MOON_POKECENTER",
            "MT_MOON_1F",
            "MT_MOON_B1F",
            "MT_MOON_B2F",
        ])
        XCTAssertEqual(manifest.playerStart.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(manifest.playerStart.position, .init(x: 4, y: 4))
        XCTAssertEqual(manifest.playerStart.playerName, "RED")
        XCTAssertEqual(manifest.playerStart.rivalName, "BLUE")
        XCTAssertEqual(
            manifest.tilesets.map(\.id),
            ["REDS_HOUSE_1", "REDS_HOUSE_2", "OVERWORLD", "CAVERN", "DOJO", "GYM", "FOREST", "FOREST_GATE", "GATE", "MUSEUM", "HOUSE", "INTERIOR", "MART", "CLUB", "POKECENTER", "SHIP"]
        )
        XCTAssertEqual(manifest.tilesets.first { $0.id == "HOUSE" }?.imagePath, "Assets/field/tilesets/house.png")
        XCTAssertEqual(manifest.tilesets.first { $0.id == "HOUSE" }?.blocksetPath, "Assets/field/blocksets/house.bst")
        XCTAssertEqual(manifest.tilesets.first { $0.id == "GYM" }?.imagePath, "Assets/field/tilesets/gym.png")
        XCTAssertEqual(manifest.tilesets.first { $0.id == "MUSEUM" }?.blocksetPath, "Assets/field/blocksets/gate.bst")
        XCTAssertEqual(manifest.tilesets.first { $0.id == "OVERWORLD" }?.animation.kind, .waterFlower)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "DOJO" }?.animation.kind, .waterFlower)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "GYM" }?.animation.kind, .waterFlower)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "FOREST" }?.animation.kind, .water)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "REDS_HOUSE_1" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "REDS_HOUSE_2" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "HOUSE" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "GATE" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "MART" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(manifest.tilesets.first { $0.id == "POKECENTER" }?.animation.kind, TilesetAnimationKind.none)
        XCTAssertEqual(
            manifest.tilesets.first { $0.id == "OVERWORLD" }?.animation.animatedTiles,
            [
                .init(tileID: 0x14),
                .init(
                    tileID: 0x03,
                    frameImagePaths: [
                        "Assets/field/tileset_animations/flower/flower1.png",
                        "Assets/field/tileset_animations/flower/flower2.png",
                        "Assets/field/tileset_animations/flower/flower3.png",
                    ]
                ),
            ]
        )
        XCTAssertEqual(
            manifest.tilesets.first { $0.id == "FOREST" }?.animation.animatedTiles,
            [.init(tileID: 0x14)]
        )
        let overworldSpriteIDs = manifest.overworldSprites.map(\.id)
        XCTAssertEqual(Set(overworldSpriteIDs).count, overworldSpriteIDs.count)
        let referencedSpriteIDs = Set(manifest.maps.flatMap(\.objects).map(\.sprite))
        for map in manifest.maps {
            XCTAssertEqual(Set(map.objects.map(\.id)).count, map.objects.count, "duplicate object ids in \(map.id)")
        }
        let missingSpriteIDs = referencedSpriteIDs.subtracting(overworldSpriteIDs)
        XCTAssertTrue(
            missingSpriteIDs.isEmpty,
            "missing overworld sprite manifests for current-slice objects: \(missingSpriteIDs.sorted())"
        )

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
        XCTAssertEqual(Set(oaksLab.objects.map(\.id)).count, oaksLab.objects.count)
        XCTAssertEqual(
            oaksLab.objects.filter { $0.id.hasPrefix("oaks_lab_poke_ball_") }.map(\.id),
            ["oaks_lab_poke_ball_charmander", "oaks_lab_poke_ball_squirtle", "oaks_lab_poke_ball_bulbasaur"]
        )
        XCTAssertEqual(
            oaksLab.objects.filter { $0.id.hasPrefix("oaks_lab_scientist") }.map(\.id),
            ["oaks_lab_scientist_1", "oaks_lab_scientist_2"]
        )
        let extractedFlagIDs = manifest.eventFlags.flags.map(\.id)
        XCTAssertEqual(Set(extractedFlagIDs).count, extractedFlagIDs.count)
        XCTAssertTrue(
            Set([
                "EVENT_BEAT_BROCK",
                "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD",
                "EVENT_BEAT_CERULEAN_RIVAL",
                "EVENT_BEAT_CERULEAN_ROCKET_THIEF",
                "EVENT_BEAT_ROUTE24_ROCKET",
                "EVENT_BEAT_MISTY",
                "EVENT_GOT_NUGGET",
                "EVENT_GOT_TM11",
                "EVENT_GOT_SS_TICKET",
                "EVENT_MET_BILL",
                "EVENT_MET_BILL_2",
                "EVENT_BILL_SAID_USE_CELL_SEPARATOR",
                "EVENT_USED_CELL_SEPARATOR_ON_BILL",
            ]).isSubset(of: Set(extractedFlagIDs))
        )
        let extractedScriptIDs = manifest.scripts.map(\.id)
        XCTAssertEqual(Set(extractedScriptIDs).count, extractedScriptIDs.count)
        XCTAssertTrue(
            Set([
                "pallet_town_oak_intro",
                "oaks_lab_rival_exit_after_battle",
                "pewter_gym_brock_reward",
                "cerulean_gym_misty_battle",
                "cerulean_gym_misty_reward",
                "mt_moon_b2f_take_dome_fossil",
                "cerulean_city_rival_vs_squirtle",
                "cerulean_city_rival_vs_bulbasaur",
                "cerulean_city_rival_vs_charmander",
                "cerulean_city_rival_after_battle",
                "cerulean_city_rocket_battle_upper",
                "cerulean_city_rocket_battle_lower",
                "cerulean_city_rocket_reward",
                "bike_shop_offer_purchase",
                "bike_shop_exchange_voucher",
                "route24_nugget_bridge_reward",
                "route24_after_rocket_battle",
                "bills_house_bill_pokemon_interaction",
                "bills_house_bill_ss_ticket",
            ]).isSubset(of: Set(extractedScriptIDs))
        )
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
                .init(
                    id: "pewter_pokecenter_pokemon_center_healing",
                    kind: .pokemonCenterHealing,
                    introDialogueID: "pokemon_center_welcome",
                    prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
                    acceptedDialogueID: "pokemon_center_need_your_pokemon",
                    successDialogueID: "pokemon_center_fighting_fit",
                    farewellDialogueID: "pokemon_center_farewell",
                    healingSequence: .init(
                        nurseObjectID: "pewter_pokecenter_nurse",
                        machineSoundEffectID: "SFX_HEALING_MACHINE",
                        healedAudioCueID: "pokemon_center_healed",
                        blackoutCheckpoint: .init(
                            mapID: "PEWTER_CITY",
                            position: .init(x: 13, y: 26),
                            facing: .down
                        )
                    )
                ),
                .init(
                    id: "cerulean_pokecenter_pokemon_center_healing",
                    kind: .pokemonCenterHealing,
                    introDialogueID: "pokemon_center_welcome",
                    prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
                    acceptedDialogueID: "pokemon_center_need_your_pokemon",
                    successDialogueID: "pokemon_center_fighting_fit",
                    farewellDialogueID: "pokemon_center_farewell",
                    healingSequence: .init(
                        nurseObjectID: "cerulean_pokecenter_nurse",
                        machineSoundEffectID: "SFX_HEALING_MACHINE",
                        healedAudioCueID: "pokemon_center_healed",
                        blackoutCheckpoint: .init(
                            mapID: "CERULEAN_CITY",
                            position: .init(x: 19, y: 18),
                            facing: .down
                        )
                    )
                ),
                .init(
                    id: "mt_moon_pokecenter_pokemon_center_healing",
                    kind: .pokemonCenterHealing,
                    introDialogueID: "pokemon_center_welcome",
                    prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
                    acceptedDialogueID: "pokemon_center_need_your_pokemon",
                    successDialogueID: "pokemon_center_fighting_fit",
                    farewellDialogueID: "pokemon_center_farewell",
                    healingSequence: .init(
                        nurseObjectID: "mt_moon_pokecenter_nurse",
                        machineSoundEffectID: "SFX_HEALING_MACHINE",
                        healedAudioCueID: "pokemon_center_healed",
                        blackoutCheckpoint: .init(
                            mapID: "ROUTE_4",
                            position: .init(x: 11, y: 6),
                            facing: .down
                        )
                    )
                ),
                .init(
                    id: "museum_1f_admission",
                    kind: .paidAdmission,
                    introDialogueID: "museum1_f_scientist1_would_you_like_to_come_in",
                    prompt: .init(kind: .yesNo, dialogueID: "museum1_f_scientist1_would_you_like_to_come_in"),
                    acceptedDialogueID: "museum1_f_scientist1_thank_you",
                    successDialogueID: "museum1_f_scientist1_take_plenty_of_time",
                    declinedDialogueID: "museum1_f_scientist1_come_again",
                    farewellDialogueID: "museum1_f_scientist1_come_again",
                    paidAdmission: .init(
                        price: 50,
                        successFlagID: "EVENT_BOUGHT_MUSEUM_TICKET",
                        insufficientFundsDialogueID: "museum1_f_scientist1_dont_have_enough_money",
                        purchaseSoundEffectID: "SFX_PURCHASE",
                        deniedExitPath: [.down]
                    )
                ),
                .init(
                    id: "bike_shop_purchase_offer",
                    kind: .dialogueChoice,
                    introDialogueID: "bike_shop_clerk_welcome",
                    prompt: .init(kind: .yesNo, dialogueID: "bike_shop_clerk_do_you_like_it"),
                    acceptedDialogueID: "bike_shop_cant_afford",
                    successDialogueID: "bike_shop_come_again",
                    farewellDialogueID: "bike_shop_come_again"
                ),
            ]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "viridian_pokecenter_nurse_heal" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "pokemon_center_healing")]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "pewter_pokecenter_nurse_heal" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "pewter_pokecenter_pokemon_center_healing")]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "cerulean_pokecenter_nurse_heal" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "cerulean_pokecenter_pokemon_center_healing")]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "mt_moon_pokecenter_nurse_heal" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "mt_moon_pokecenter_pokemon_center_healing")]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "bike_shop_offer_purchase" }?.steps,
            [.init(action: "startFieldInteraction", fieldInteractionID: "bike_shop_purchase_offer")]
        )
        XCTAssertEqual(
            manifest.scripts.first { $0.id == "bike_shop_exchange_voucher" }?.steps.map(\.action),
            ["showDialogue", "giveItem", "removeItem"]
        )
        XCTAssertEqual(
            oaksLab.objects.first { $0.id == "oaks_lab_girl" }?.movementBehavior,
            .init(idleMode: .walk, axis: .upDown, home: .init(x: 1, y: 9))
        )
        let ceruleanCity = try XCTUnwrap(manifest.maps.first { $0.id == "CERULEAN_CITY" })
        XCTAssertEqual(ceruleanCity.connections.map(\.targetMapID), ["ROUTE_24", "ROUTE_5", "ROUTE_4", "ROUTE_9"])
        XCTAssertEqual(ceruleanCity.connections.map(\.offset), [5, 5, 4, 4])
        XCTAssertEqual(
            ceruleanCity.objects.filter { $0.id == "cerulean_city_rival" || $0.id == "cerulean_city_rocket" }.map(\.id),
            ["cerulean_city_rival", "cerulean_city_rocket"]
        )
        XCTAssertEqual(ceruleanCity.objects.first { $0.id == "cerulean_city_rival" }?.visibleByDefault, false)
        XCTAssertEqual(ceruleanCity.objects.first { $0.id == "cerulean_city_rocket" }?.visibleByDefault, true)
        XCTAssertEqual(manifest.mapScripts.first { $0.mapID == "CERULEAN_CITY" }?.triggers.count, 8)
        XCTAssertEqual(
            manifest.maps.first { $0.id == "CERULEAN_POKECENTER" }?.objects.map(\.id),
            [
                "cerulean_pokecenter_nurse",
                "cerulean_pokecenter_super_nerd",
                "cerulean_pokecenter_gentleman",
                "cerulean_pokecenter_link_receptionist",
            ]
        )
        XCTAssertEqual(
            manifest.maps.first { $0.id == "CERULEAN_MART" }?.objects.map(\.id),
            ["cerulean_mart_clerk", "cerulean_mart_cooltrainer_m", "cerulean_mart_cooltrainer_f"]
        )
        XCTAssertEqual(
            manifest.maps.first { $0.id == "BIKE_SHOP" }?.objects.map(\.id),
            ["bike_shop_clerk", "bike_shop_middle_aged_woman", "bike_shop_youngster"]
        )
        XCTAssertEqual(
            manifest.maps.first { $0.id == "BIKE_SHOP" }?.objects.first { $0.id == "bike_shop_clerk" }?.interactionReach,
            .overCounter
        )
        XCTAssertEqual(
            manifest.maps.first { $0.id == "CERULEAN_TRASHED_HOUSE" }?.backgroundEvents.map(\.dialogueID),
            ["cerulean_trashed_house_wall_hole"]
        )
        let route24 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_24" })
        XCTAssertEqual(route24.connections.map(\.targetMapID), ["CERULEAN_CITY", "ROUTE_25"])
        XCTAssertEqual(
            route24.objects.map(\.id),
            [
                "route24_nugget_bridge_guy",
                "route24_cooltrainer_m_2",
                "route24_cooltrainer_m_3",
                "route24_cooltrainer_f_1",
                "route24_youngster_1",
                "route24_cooltrainer_f_2",
                "route24_youngster_2",
                "route_24_tm_thunder_wave",
            ]
        )
        XCTAssertEqual(route24.objects.first { $0.id == "route24_nugget_bridge_guy" }?.trainerBattleID, nil)
        XCTAssertEqual(route24.objects.first { $0.id == "route24_nugget_bridge_guy" }?.interactionTriggers.count, 2)
        XCTAssertEqual(route24.objects.first { $0.id == "route24_cooltrainer_m_2" }?.trainerBattleID, "opp_jr_trainer_m_2")
        XCTAssertEqual(route24.objects.first { $0.id == "route24_cooltrainer_m_3" }?.trainerBattleID, "opp_jr_trainer_m_3")
        XCTAssertEqual(route24.objects.first { $0.id == "route24_cooltrainer_f_1" }?.trainerBattleID, "opp_lass_7")
        XCTAssertEqual(route24.objects.first { $0.id == "route24_youngster_2" }?.trainerBattleID, "opp_bug_catcher_9")
        XCTAssertEqual(route24.objects.first { $0.id == "route_24_tm_thunder_wave" }?.pickupItemID, "TM_THUNDER_WAVE")
        XCTAssertEqual(manifest.mapScripts.first { $0.mapID == "ROUTE_24" }?.triggers.map(\.scriptID), ["route24_nugget_bridge_reward"])
        let route25 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_25" })
        XCTAssertEqual(route25.connections.map(\.targetMapID), ["ROUTE_24"])
        XCTAssertEqual(route25.warps.first?.targetMapID, "BILLS_HOUSE")
        XCTAssertEqual(route25.backgroundEvents.map(\.dialogueID), ["route25_bill_sign"])
        XCTAssertEqual(route25.objects.count, 10)
        XCTAssertEqual(route25.objects.first { $0.id == "route25_youngster_1" }?.trainerBattleID, "opp_youngster_5")
        XCTAssertEqual(route25.objects.first { $0.id == "route25_hiker_1" }?.trainerBattleID, "opp_hiker_2")
        XCTAssertEqual(route25.objects.first { $0.id == "route_25_tm_seismic_toss" }?.pickupItemID, "TM_SEISMIC_TOSS")
        let billsHouse = try XCTUnwrap(manifest.maps.first { $0.id == "BILLS_HOUSE" })
        XCTAssertEqual(billsHouse.tileset, "INTERIOR")
        XCTAssertEqual(
            billsHouse.objects.map(\.id),
            ["bills_house_bill_pokemon", "bills_house_bill_1", "bills_house_bill_2"]
        )
        XCTAssertEqual(billsHouse.objects.first { $0.id == "bills_house_bill_pokemon" }?.interactionScriptID, "bills_house_bill_pokemon_interaction")
        XCTAssertEqual(billsHouse.objects.first { $0.id == "bills_house_bill_1" }?.visibleByDefault, false)
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
            charmander.evolutions,
            [
                .init(
                    trigger: .init(kind: .level, level: 16),
                    targetSpeciesID: "CHARMELEON"
                ),
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
        XCTAssertEqual(
            squirtle.evolutions,
            [
                .init(
                    trigger: .init(kind: .level, level: 16),
                    targetSpeciesID: "WARTORTLE"
                ),
            ]
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
        let pikachu = try XCTUnwrap(manifest.species.first { $0.id == "PIKACHU" })
        XCTAssertEqual(
            pikachu.evolutions,
            [
                .init(
                    trigger: .init(kind: .item, itemID: "THUNDER_STONE", minimumLevel: 1),
                    targetSpeciesID: "RAICHU"
                ),
            ]
        )
        let kadabra = try XCTUnwrap(manifest.species.first { $0.id == "KADABRA" })
        XCTAssertEqual(
            kadabra.evolutions,
            [
                .init(
                    trigger: .init(kind: .trade, minimumLevel: 1),
                    targetSpeciesID: "ALAKAZAM"
                ),
            ]
        )
        XCTAssertEqual(manifest.moves.count, 165)
        XCTAssertNotNil(manifest.moves.first { $0.id == "CUT" })
        XCTAssertNotNil(manifest.moves.first { $0.id == "SURF" })
        XCTAssertNotNil(manifest.moves.first { $0.id == "THUNDERBOLT" })
        XCTAssertEqual(manifest.items.count, 106)
        XCTAssertFalse(manifest.items.contains { $0.id.contains("\\") })
        XCTAssertEqual(manifest.items.first?.id, "MASTER_BALL")
        XCTAssertEqual(manifest.items.first?.displayName, "MASTER BALL")
        XCTAssertEqual(manifest.items.first?.price, 0)
        let pokeBall = try XCTUnwrap(manifest.items.first { $0.id == "POKE_BALL" })
        XCTAssertEqual(pokeBall.displayName, "POKé BALL")
        XCTAssertEqual(pokeBall.price, 200)
        XCTAssertEqual(pokeBall.battleUse, .ball)
        XCTAssertEqual(pokeBall.bagSection, .balls)
        XCTAssertEqual(pokeBall.shortDescription, "A standard Ball used to catch wild Pokemon.")
        XCTAssertEqual(pokeBall.iconAssetPath, "Assets/items/ball/poke.png")
        let boulderBadge = try XCTUnwrap(manifest.items.first { $0.id == "BOULDERBADGE" })
        XCTAssertEqual(boulderBadge.isKeyItem, true)
        XCTAssertEqual(boulderBadge.price, 0)
        XCTAssertEqual(boulderBadge.bagSection, .keyItems)
        XCTAssertEqual(boulderBadge.iconAssetPath, "Assets/items/key-item/surge-badge.png")
        let cascadeBadge = try XCTUnwrap(manifest.items.first { $0.id == "CASCADEBADGE" })
        XCTAssertEqual(cascadeBadge.isKeyItem, true)
        XCTAssertEqual(cascadeBadge.price, 0)
        let oaksParcel = try XCTUnwrap(manifest.items.first { $0.id == "OAKS_PARCEL" })
        XCTAssertEqual(oaksParcel.displayName, "OAK's PARCEL")
        XCTAssertEqual(oaksParcel.isKeyItem, true)
        XCTAssertEqual(oaksParcel.price, 0)
        XCTAssertEqual(oaksParcel.shortDescription, "A parcel that needs to be delivered to Professor Oak.")
        let tmBide = try XCTUnwrap(manifest.items.first { $0.id == "TM_BIDE" })
        XCTAssertEqual(tmBide.displayName, "TM34")
        XCTAssertFalse(tmBide.isKeyItem)
        XCTAssertEqual(tmBide.price, 2000)
        XCTAssertEqual(tmBide.bagSection, .tmhm)
        XCTAssertEqual(tmBide.tmhmMoveID, "BIDE")
        XCTAssertEqual(tmBide.shortDescription, "A technical machine that teaches BIDE.")
        XCTAssertEqual(tmBide.iconAssetPath, "Assets/items/tm/normal.png")
        let tmBubblebeam = try XCTUnwrap(manifest.items.first { $0.id == "TM_BUBBLEBEAM" })
        XCTAssertEqual(tmBubblebeam.displayName, "TM11")
        XCTAssertFalse(tmBubblebeam.isKeyItem)
        XCTAssertEqual(tmBubblebeam.price, 2000)
        XCTAssertEqual(tmBubblebeam.tmhmMoveID, "BUBBLEBEAM")
        XCTAssertEqual(tmBubblebeam.iconAssetPath, "Assets/items/tm/water.png")
        XCTAssertEqual(manifest.items.last?.id, "TM_WHIRLWIND")
        XCTAssertEqual(manifest.items.last?.displayName, "TM04")
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
        let trainerBattleIDs = manifest.trainerBattles.map(\.id)
        XCTAssertEqual(Set(trainerBattleIDs).count, trainerBattleIDs.count)
        XCTAssertTrue(
            Set([
                "opp_brock_1",
                "opp_misty_1",
                "opp_super_nerd_2",
                "opp_rocket_5",
                "opp_rocket_6",
                "cerulean_city_rival_7",
                "cerulean_city_rival_8",
                "cerulean_city_rival_9",
                "route_22_rival_1_4_lower",
                "route_22_rival_1_4_upper",
            ]).isSubset(of: Set(trainerBattleIDs))
        )
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
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rival1_1" }?.runsPostBattleScriptOnLoss, true)
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_brock_1" }?.party,
            [.init(speciesID: "GEODUDE", level: 12), .init(speciesID: "ONIX", level: 14)]
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_brock_1" }?.trainerSpritePath, "Assets/battle/trainers/brock.png")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_brock_1" }?.completionFlagID, "EVENT_BEAT_BROCK")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_brock_1" }?.postBattleScriptID, "pewter_gym_brock_reward")
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_misty_1" }?.party,
            [.init(speciesID: "STARYU", level: 18), .init(speciesID: "STARMIE", level: 21)]
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_misty_1" }?.trainerSpritePath, "Assets/battle/trainers/misty.png")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_misty_1" }?.completionFlagID, "EVENT_BEAT_MISTY")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_misty_1" }?.postBattleScriptID, "cerulean_gym_misty_reward")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rocket_5" }?.completionFlagID, "EVENT_BEAT_CERULEAN_ROCKET_THIEF")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rocket_5" }?.postBattleScriptID, "cerulean_city_rocket_reward")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rocket_6" }?.completionFlagID, "EVENT_BEAT_ROUTE24_ROCKET")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_rocket_6" }?.postBattleScriptID, "route24_after_rocket_battle")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "cerulean_city_rival_7" }?.completionFlagID, "EVENT_BEAT_CERULEAN_RIVAL")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "cerulean_city_rival_7" }?.postBattleScriptID, "cerulean_city_rival_after_battle")
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_super_nerd_2" }?.party,
            [.init(speciesID: "GRIMER", level: 12), .init(speciesID: "VOLTORB", level: 12), .init(speciesID: "KOFFING", level: 12)]
        )
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "opp_super_nerd_2" }?.trainerSpritePath,
            "Assets/battle/trainers/supernerd.png"
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_super_nerd_2" }?.completionFlagID, "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "route_22_rival_1_4_upper" }?.party,
            [.init(speciesID: "PIDGEY", level: 9), .init(speciesID: "SQUIRTLE", level: 8)]
        )
        XCTAssertEqual(
            manifest.trainerBattles.first { $0.id == "route_22_rival_1_4_upper" }?.postBattleScriptID,
            "route_22_rival_1_exit_upper"
        )
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_jr_trainer_m_1" }?.trainerSpritePath, "Assets/battle/trainers/jr.trainerm.png")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_lass_1" }?.trainerSpritePath, "Assets/battle/trainers/lass.png")
        XCTAssertEqual(manifest.trainerBattles.first { $0.id == "opp_youngster_1" }?.trainerSpritePath, "Assets/battle/trainers/youngster.png")
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

        let route22 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_22" })
        let route22Rival1 = try XCTUnwrap(route22.objects.first { $0.id == "route_22_rival_1" })
        let route22Rival2 = try XCTUnwrap(route22.objects.first { $0.id == "route_22_rival_2" })
        XCTAssertEqual(route22.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(route22.connections.map(\.targetMapID), ["ROUTE_23", "VIRIDIAN_CITY"])
        XCTAssertEqual(route22.objects.map(\.id), ["route_22_rival_1", "route_22_rival_2"])
        XCTAssertEqual(route22.objects.first?.visibleByDefault, false)
        XCTAssertNil(route22Rival1.trainerBattleID)
        XCTAssertEqual(route22Rival1.interactionDialogueID, "route_22_rival_before_battle_1")
        XCTAssertEqual(
            route22Rival1.interactionTriggers,
            [.init(conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE")], dialogueID: "route_22_rival_after_battle_1")]
        )
        XCTAssertEqual(route22Rival2.interactionDialogueID, "route_22_rival_before_battle_2")
        XCTAssertEqual(
            route22Rival2.interactionTriggers,
            [.init(conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_ROUTE22_RIVAL_2ND_BATTLE")], dialogueID: "route_22_rival_after_battle_2")]
        )
        XCTAssertEqual(route22.backgroundEvents.map(\.dialogueID), ["route_22_pokemon_league_sign"])
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "ROUTE_22" }?.triggers.map(\.scriptID),
            [
                "route_22_rival_1_challenge_4_upper",
                "route_22_rival_1_challenge_5_upper",
                "route_22_rival_1_challenge_6_upper",
                "route_22_rival_1_challenge_4_lower",
                "route_22_rival_1_challenge_5_lower",
                "route_22_rival_1_challenge_6_lower",
            ]
        )

        let route22UpperChallenge = try XCTUnwrap(manifest.scripts.first { $0.id == "route_22_rival_1_challenge_4_upper" })
        XCTAssertEqual(route22UpperChallenge.steps.filter { $0.action == "faceObject" }.compactMap(\.stringValue), ["right"])
        XCTAssertEqual(route22UpperChallenge.steps.filter { $0.action == "facePlayer" }.compactMap(\.stringValue), ["left"])

        let route22LowerChallenge = try XCTUnwrap(manifest.scripts.first { $0.id == "route_22_rival_1_challenge_4_lower" })
        XCTAssertEqual(route22LowerChallenge.steps.filter { $0.action == "faceObject" }.compactMap(\.stringValue), ["up"])
        XCTAssertEqual(route22LowerChallenge.steps.filter { $0.action == "facePlayer" }.compactMap(\.stringValue), ["down"])

        let route22Gate = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_22_GATE" })
        let route22GateGuard = try XCTUnwrap(route22Gate.objects.first { $0.id == "route_22_gate_guard" })
        XCTAssertEqual(route22Gate.defaultMusicID, "MUSIC_DUNGEON2")
        XCTAssertEqual(route22Gate.objects.map(\.id), ["route_22_gate_guard"])
        XCTAssertEqual(route22GateGuard.interactionDialogueID, "route_22_gate_guard_no_boulder_badge")
        XCTAssertEqual(
            route22GateGuard.interactionTriggers,
            [.init(conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK")], dialogueID: "route_22_gate_guard_go_right_ahead")]
        )
        XCTAssertEqual(route22Gate.warps.map(\.targetMapID), ["ROUTE_22", "ROUTE_22", "ROUTE_23", "ROUTE_23"])
        XCTAssertEqual(route22Gate.warps[0].targetPosition, .init(x: 8, y: 5))
        XCTAssertEqual(route22Gate.warps[1].targetPosition, .init(x: 8, y: 5))
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "ROUTE_22_GATE" }?.triggers,
            [
                .init(
                    id: "guard_blocks_upper_lane_without_boulder_badge",
                    scriptID: "route_22_gate_guard_blocks_northbound_upper_lane",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BEAT_BROCK"),
                        .init(kind: "playerXEquals", intValue: 4),
                        .init(kind: "playerYEquals", intValue: 2),
                    ]
                ),
                .init(
                    id: "guard_blocks_lower_lane_without_boulder_badge",
                    scriptID: "route_22_gate_guard_blocks_northbound_lower_lane",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BEAT_BROCK"),
                        .init(kind: "playerXEquals", intValue: 5),
                        .init(kind: "playerYEquals", intValue: 2),
                    ]
                ),
            ]
        )

        let route22GateUpperBlock = try XCTUnwrap(manifest.scripts.first { $0.id == "route_22_gate_guard_blocks_northbound_upper_lane" })
        XCTAssertEqual(route22GateUpperBlock.steps.map(\.action), ["showDialogue", "movePlayer"])
        XCTAssertEqual(route22GateUpperBlock.steps.first?.dialogueID, "route_22_gate_guard_no_boulder_badge")
        XCTAssertEqual(route22GateUpperBlock.steps.last?.path, [.down])

        let route22GateLowerBlock = try XCTUnwrap(manifest.scripts.first { $0.id == "route_22_gate_guard_blocks_northbound_lower_lane" })
        XCTAssertEqual(route22GateLowerBlock.steps.map(\.action), ["showDialogue", "movePlayer"])
        XCTAssertEqual(route22GateLowerBlock.steps.first?.dialogueID, "route_22_gate_guard_no_boulder_badge")
        XCTAssertEqual(route22GateLowerBlock.steps.last?.path, [.down])

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
                    id: "cerulean_mart",
                    mapID: "CERULEAN_MART",
                    clerkObjectID: "cerulean_mart_clerk",
                    stockItemIDs: ["POKE_BALL", "POTION", "REPEL", "ANTIDOTE", "BURN_HEAL", "AWAKENING", "PARLYZ_HEAL"]
                ),
                .init(
                    id: "pewter_mart",
                    mapID: "PEWTER_MART",
                    clerkObjectID: "pewter_mart_clerk",
                    stockItemIDs: ["POKE_BALL", "POTION", "ESCAPE_ROPE", "ANTIDOTE", "BURN_HEAL", "AWAKENING", "PARLYZ_HEAL"]
                ),
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

        let pewterCity = try XCTUnwrap(manifest.maps.first { $0.id == "PEWTER_CITY" })
        XCTAssertEqual(pewterCity.defaultMusicID, "MUSIC_CITIES1")
        XCTAssertEqual(pewterCity.connections.map(\.targetMapID), ["ROUTE_2", "ROUTE_3"])
        XCTAssertEqual(pewterCity.backgroundEvents.map(\.dialogueID), [
            "pewter_city_trainer_tips",
            "pewter_city_police_notice_sign",
            "pewter_city_mart_sign",
            "pewter_city_pokecenter_sign",
            "pewter_city_museum_sign",
            "pewter_city_gym_sign",
            "pewter_city_sign",
        ])
        XCTAssertNotNil(manifest.dialogues.first { $0.id == "pewter_city_mart_sign" })
        XCTAssertNotNil(manifest.dialogues.first { $0.id == "pewter_city_pokecenter_sign" })
        XCTAssertNil(manifest.dialogues.first { $0.id == "pewter_city_text_pewtercity_mart_sign" })
        XCTAssertNil(manifest.dialogues.first { $0.id == "pewter_city_text_pewtercity_pokecenter_sign" })

        let pewterPokecenter = try XCTUnwrap(manifest.maps.first { $0.id == "PEWTER_POKECENTER" })
        XCTAssertEqual(pewterPokecenter.tileset, "POKECENTER")
        XCTAssertEqual(pewterPokecenter.objects.first { $0.id == "pewter_pokecenter_nurse" }?.interactionReach, .overCounter)
        XCTAssertEqual(pewterPokecenter.objects.first { $0.id == "pewter_pokecenter_nurse" }?.interactionScriptID, "pewter_pokecenter_nurse_heal")

        let pewterMart = try XCTUnwrap(manifest.maps.first { $0.id == "PEWTER_MART" })
        XCTAssertEqual(pewterMart.tileset, "MART")
        XCTAssertEqual(pewterMart.objects.first { $0.id == "pewter_mart_clerk" }?.interactionTriggers, [.init(martID: "pewter_mart")])

        let museum1F = try XCTUnwrap(manifest.maps.first { $0.id == "MUSEUM_1F" })
        XCTAssertEqual(museum1F.tileset, "MUSEUM")
        XCTAssertEqual(museum1F.objects.map(\.id), [
            "museum1_f_scientist1_come_again",
            "museum1_f_gambler",
            "museum1_f_scientist2_take_this_to_a_pokemon_lab",
            "museum1_f_scientist3",
            "museum1_f_old_amber",
        ])
        XCTAssertEqual(museum1F.objects.first { $0.id == "museum1_f_scientist1_come_again" }?.interactionReach, .overCounter)
        XCTAssertEqual(
            museum1F.objects.first { $0.id == "museum1_f_scientist1_come_again" }?.interactionTriggers,
            [
                .init(
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "playerXEquals", intValue: 10),
                    ],
                    scriptID: "museum_1f_scientist1_interaction"
                ),
                .init(
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "playerXEquals", intValue: 11),
                    ],
                    scriptID: "museum_1f_scientist1_interaction"
                ),
                .init(
                    conditions: [.init(kind: "flagSet", flagID: "EVENT_BOUGHT_MUSEUM_TICKET")],
                    dialogueID: "museum1_f_scientist1_take_plenty_of_time"
                ),
                .init(
                    conditions: [.init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET")],
                    dialogueID: "museum1_f_scientist1_go_to_other_side"
                ),
            ]
        )

        XCTAssertEqual(manifest.fieldInteractions.first { $0.id == "museum_1f_admission" }?.kind, .paidAdmission)
        XCTAssertEqual(
            manifest.fieldInteractions.first { $0.id == "museum_1f_admission" }?.paidAdmission,
            .init(
                price: 50,
                successFlagID: "EVENT_BOUGHT_MUSEUM_TICKET",
                insufficientFundsDialogueID: "museum1_f_scientist1_dont_have_enough_money",
                purchaseSoundEffectID: "SFX_PURCHASE",
                deniedExitPath: [.down]
            )
        )
        XCTAssertEqual(
            museum1F.objects.first { $0.id == "museum1_f_old_amber" }?.interactionDialogueID,
            "museum1_f_old_amber"
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "museum1_f_old_amber" }?.pages.first?.lines,
            ["The AMBER is", "clear and gold!"]
        )
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "MUSEUM_1F" }?.triggers,
            [
                .init(
                    id: "museum_admission_entry_left",
                    scriptID: "museum_1f_entrance_admission",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "playerXEquals", intValue: 9),
                    ]
                ),
                .init(
                    id: "museum_admission_entry_right",
                    scriptID: "museum_1f_entrance_admission",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "playerXEquals", intValue: 10),
                    ]
                ),
            ]
        )

        let museum2F = try XCTUnwrap(manifest.maps.first { $0.id == "MUSEUM_2F" })
        XCTAssertEqual(museum2F.tileset, "MUSEUM")
        XCTAssertEqual(
            museum2F.backgroundEvents.map(\.dialogueID),
            ["museum2_f_space_shuttle_sign", "museum2_f_moon_stone_sign"]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "museum2_f_space_shuttle_sign" }?.pages.first?.lines,
            ["SPACE SHUTTLE", "COLUMBIA"]
        )
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "museum2_f_moon_stone_sign" }?.pages.first?.lines,
            ["Meteorite that", "fell on MT.MOON.", "(MOON STONE?)"]
        )

        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "PEWTER_CITY" }?.triggers,
            [
                .init(
                    id: "museum_exit_resets_ticket_main",
                    scriptID: "pewter_city_reset_museum_ticket",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 8),
                        .init(kind: "playerXEquals", intValue: 14),
                    ]
                ),
                .init(
                    id: "museum_exit_resets_ticket_back",
                    scriptID: "pewter_city_reset_museum_ticket",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "playerXEquals", intValue: 19),
                    ]
                ),
            ]
        )
        XCTAssertTrue(manifest.eventFlags.flags.contains { $0.id == "EVENT_BOUGHT_MUSEUM_TICKET" })
        XCTAssertNotNil(manifest.scripts.first { $0.id == "museum_1f_scientist1_interaction" })
        XCTAssertNotNil(manifest.scripts.first { $0.id == "museum_1f_entrance_admission" })
        XCTAssertNotNil(manifest.scripts.first { $0.id == "pewter_city_reset_museum_ticket" })

        let pewterGym = try XCTUnwrap(manifest.maps.first { $0.id == "PEWTER_GYM" })
        XCTAssertEqual(pewterGym.tileset, "GYM")
        XCTAssertEqual(
            pewterGym.objects.first { $0.id == "pewter_gym_brock" }?.interactionTriggers,
            [
                .init(
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK"),
                        .init(kind: "flagSet", flagID: "EVENT_GOT_TM34"),
                    ],
                    dialogueID: "pewter_gym_brock_post_battle_advice"
                ),
                .init(
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BEAT_BROCK"),
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_TM34"),
                    ],
                    scriptID: "pewter_gym_brock_reward"
                ),
                .init(scriptID: "pewter_gym_brock_battle"),
            ]
        )
        XCTAssertNil(pewterGym.objects.first { $0.id == "pewter_gym_brock" }?.trainerBattleID)
        XCTAssertEqual(pewterGym.objects.first { $0.id == "pewter_gym_cooltrainer_m" }?.trainerBattleID, "opp_jr_trainer_m_1")

        let ceruleanGym = try XCTUnwrap(manifest.maps.first { $0.id == "CERULEAN_GYM" })
        XCTAssertEqual(ceruleanGym.tileset, "GYM")
        XCTAssertEqual(ceruleanGym.defaultMusicID, "MUSIC_GYM")
        XCTAssertEqual(ceruleanGym.warps.map(\.targetMapID), ["CERULEAN_CITY", "CERULEAN_CITY"])
        XCTAssertEqual(
            ceruleanGym.objects.map(\.id),
            ["cerulean_gym_misty", "cerulean_gym_cooltrainer_f", "cerulean_gym_swimmer", "cerulean_gym_gym_guide"]
        )
        XCTAssertEqual(
            ceruleanGym.objects.first { $0.id == "cerulean_gym_misty" }?.interactionTriggers,
            [
                .init(
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY"),
                        .init(kind: "flagSet", flagID: "EVENT_GOT_TM11"),
                    ],
                    dialogueID: "cerulean_gym_misty_tm11_explanation"
                ),
                .init(
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY"),
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_TM11"),
                    ],
                    scriptID: "cerulean_gym_misty_reward"
                ),
                .init(scriptID: "cerulean_gym_misty_battle"),
            ]
        )
        XCTAssertNil(ceruleanGym.objects.first { $0.id == "cerulean_gym_misty" }?.trainerBattleID)
        XCTAssertEqual(ceruleanGym.objects.first { $0.id == "cerulean_gym_cooltrainer_f" }?.trainerBattleID, "opp_jr_trainer_f_1")
        XCTAssertEqual(ceruleanGym.objects.first { $0.id == "cerulean_gym_swimmer" }?.trainerBattleID, "opp_swimmer_1")
        XCTAssertEqual(
            ceruleanGym.objects.first { $0.id == "cerulean_gym_gym_guide" }?.interactionTriggers,
            [
                .init(
                    conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_MISTY")],
                    dialogueID: "cerulean_gym_gym_guide_beat_misty"
                ),
                .init(dialogueID: "cerulean_gym_gym_guide_champ_in_making"),
            ]
        )

        let route3 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_3" })
        XCTAssertEqual(route3.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(route3.connections.map(\.targetMapID), ["ROUTE_4", "PEWTER_CITY"])
        XCTAssertEqual(route3.backgroundEvents.map(\.dialogueID), ["route3_sign"])
        XCTAssertEqual(route3.objects.count, 9)
        XCTAssertEqual(route3.objects.first { $0.id == "route3_youngster2" }?.trainerBattleID, "opp_youngster_1")
        XCTAssertEqual(route3.objects.first { $0.id == "route3_cooltrainer_f1" }?.trainerBattleID, "opp_lass_1")

        let route1Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_1" })
        XCTAssertEqual(route1Encounters.grassEncounterRate, 25)
        XCTAssertEqual(route1Encounters.waterEncounterRate, 0)
        XCTAssertEqual(route1Encounters.grassSlots.first, .init(speciesID: "PIDGEY", level: 3))
        XCTAssertEqual(route1Encounters.grassSlots.last, .init(speciesID: "PIDGEY", level: 5))
        XCTAssertEqual(Set(route1Encounters.grassSlots.map(\.speciesID)), Set(["PIDGEY", "RATTATA"]))

        let route2Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_2" })
        XCTAssertEqual(route2Encounters.grassEncounterRate, 25)
        XCTAssertEqual(Set(route2Encounters.grassSlots.map(\.speciesID)), Set(["PIDGEY", "RATTATA", "WEEDLE", "CATERPIE"]))

        let route22Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_22" })
        XCTAssertEqual(route22Encounters.grassEncounterRate, 25)
        XCTAssertEqual(Set(route22Encounters.grassSlots.map(\.speciesID)), Set(["RATTATA", "NIDORAN_M", "NIDORAN_F", "SPEAROW"]))

        let viridianForestEncounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "VIRIDIAN_FOREST" })
        XCTAssertEqual(viridianForestEncounters.grassEncounterRate, 8)
        XCTAssertTrue(Set(viridianForestEncounters.grassSlots.map(\.speciesID)).isSuperset(of: Set(["WEEDLE", "CATERPIE", "KAKUNA", "METAPOD", "PIKACHU"])))

        let route3Encounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "ROUTE_3" })
        XCTAssertEqual(route3Encounters.grassEncounterRate, 20)
        XCTAssertEqual(route3Encounters.waterEncounterRate, 0)
        XCTAssertTrue(Set(route3Encounters.grassSlots.map(\.speciesID)).isSuperset(of: Set(["PIDGEY", "SPEAROW", "JIGGLYPUFF"])))

        let route4 = try XCTUnwrap(manifest.maps.first { $0.id == "ROUTE_4" })
        XCTAssertEqual(route4.defaultMusicID, "MUSIC_ROUTES3")
        XCTAssertEqual(route4.connections.map(\.targetMapID), ["ROUTE_3", "CERULEAN_CITY"])
        XCTAssertEqual(route4.warps.first?.targetMapID, "MT_MOON_POKECENTER")
        XCTAssertEqual(route4.warps[1].targetMapID, "MT_MOON_1F")
        XCTAssertEqual(route4.warps[2].targetMapID, "MT_MOON_B1F")
        XCTAssertEqual(route4.objects.map(\.id), ["route4_cooltrainer_f1", "route4_cooltrainer_f2", "route_4_tm_whirlwind"])
        XCTAssertEqual(route4.objects.first { $0.id == "route4_cooltrainer_f2" }?.trainerBattleID, "opp_lass_4")
        XCTAssertEqual(route4.objects.first { $0.id == "route_4_tm_whirlwind" }?.pickupItemID, "TM_WHIRLWIND")

        let mtMoonPokecenter = try XCTUnwrap(manifest.maps.first { $0.id == "MT_MOON_POKECENTER" })
        XCTAssertEqual(mtMoonPokecenter.tileset, "POKECENTER")
        XCTAssertTrue(mtMoonPokecenter.warps.allSatisfy { $0.usesPreviousMapTarget == false })
        XCTAssertEqual(mtMoonPokecenter.objects.first { $0.id == "mt_moon_pokecenter_nurse" }?.interactionScriptID, "mt_moon_pokecenter_nurse_heal")

        let mtMoon1F = try XCTUnwrap(manifest.maps.first { $0.id == "MT_MOON_1F" })
        XCTAssertEqual(mtMoon1F.tileset, "CAVERN")
        XCTAssertTrue(mtMoon1F.warps.prefix(2).allSatisfy(\.usesPreviousMapTarget))
        XCTAssertEqual(mtMoon1F.objects.first { $0.id == "mt_moon1_f_hiker" }?.trainerBattleID, "opp_hiker_1")
        XCTAssertEqual(mtMoon1F.objects.first { $0.id == "mt_moon1_f_super_nerd" }?.trainerBattleID, "opp_super_nerd_1")
        XCTAssertEqual(mtMoon1F.objects.first { $0.id == "mt_moon_1f_tm_water_gun" }?.pickupItemID, "TM_WATER_GUN")

        let mtMoonB1F = try XCTUnwrap(manifest.maps.first { $0.id == "MT_MOON_B1F" })
        XCTAssertEqual(mtMoonB1F.tileset, "CAVERN")
        XCTAssertTrue(mtMoonB1F.warps.last?.usesPreviousMapTarget ?? false)

        let redsHouse1F = try XCTUnwrap(manifest.maps.first { $0.id == "REDS_HOUSE_1F" })
        XCTAssertTrue(redsHouse1F.warps.prefix(2).allSatisfy { $0.usesPreviousMapTarget == false })

        let mtMoonB2F = try XCTUnwrap(manifest.maps.first { $0.id == "MT_MOON_B2F" })
        XCTAssertEqual(mtMoonB2F.tileset, "CAVERN")
        XCTAssertEqual(mtMoonB2F.objects.map(\.id), [
            "mt_moon_b2f_super_nerd",
            "mt_moon_b2f_rocket_1",
            "mt_moon_b2f_rocket_2",
            "mt_moon_b2f_rocket_3",
            "mt_moon_b2f_rocket_4",
            "mt_moon_b2f_dome_fossil",
            "mt_moon_b2f_helix_fossil",
            "mt_moon_b2f_hp_up",
            "mt_moon_b2f_tm_mega_punch",
        ])
        XCTAssertEqual(mtMoonB2F.objects.first { $0.id == "mt_moon_b2f_super_nerd" }?.interactionScriptID, "mt_moon_b2f_super_nerd_battle")
        XCTAssertEqual(mtMoonB2F.objects.first { $0.id == "mt_moon_b2f_dome_fossil" }?.interactionScriptID, "mt_moon_b2f_take_dome_fossil")
        XCTAssertEqual(mtMoonB2F.objects.first { $0.id == "mt_moon_b2f_helix_fossil" }?.interactionScriptID, "mt_moon_b2f_take_helix_fossil")
        XCTAssertEqual(
            manifest.mapScripts.first { $0.mapID == "MT_MOON_B2F" }?.triggers,
            [
                .init(
                    id: "super_nerd_claims_fossils",
                    scriptID: "mt_moon_b2f_super_nerd_battle",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD"),
                        .init(kind: "playerXEquals", intValue: 13),
                        .init(kind: "playerYEquals", intValue: 8),
                    ]
                ),
            ]
        )

        let mtMoon1FEncounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "MT_MOON_1F" })
        XCTAssertEqual(mtMoon1FEncounters.landEncounterSurface, .floor)
        XCTAssertEqual(mtMoon1FEncounters.grassEncounterRate, 10)
        XCTAssertTrue(Set(mtMoon1FEncounters.grassSlots.map(\.speciesID)).isSuperset(of: Set(["ZUBAT", "GEODUDE", "PARAS", "CLEFAIRY"])))

        let mtMoonB1FEncounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "MT_MOON_B1F" })
        XCTAssertEqual(mtMoonB1FEncounters.landEncounterSurface, .floor)
        XCTAssertEqual(mtMoonB1FEncounters.grassEncounterRate, 10)

        let mtMoonB2FEncounters = try XCTUnwrap(manifest.wildEncounterTables.first { $0.mapID == "MT_MOON_B2F" })
        XCTAssertEqual(mtMoonB2FEncounters.landEncounterSurface, .floor)
        XCTAssertEqual(mtMoonB2FEncounters.grassEncounterRate, 10)
        XCTAssertEqual(mtMoonB2FEncounters.suppressionZones.map(\.id), ["mt_moon_b2f_post_super_nerd_fossil_area"])
        XCTAssertEqual(
            mtMoonB2FEncounters.suppressionZones.first?.conditions,
            [.init(kind: "flagSet", flagID: "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")]
        )
        XCTAssertEqual(mtMoonB2FEncounters.suppressionZones.first?.positions.first, .init(x: 11, y: 5))
        XCTAssertEqual(mtMoonB2FEncounters.suppressionZones.first?.positions.last, .init(x: 14, y: 8))

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
        XCTAssertEqual(manifest.dialogues.first { $0.id == "evolution_evolved" }?.pages.first?.lines, ["{pokemon} evolved"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "evolution_into" }?.pages.first?.lines, ["into {evolvedPokemon}!"])
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "evolution_into" }?.pages.first?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_2")]
        )
        XCTAssertEqual(manifest.dialogues.first { $0.id == "evolution_is_evolving" }?.pages.first?.lines, ["What? {pokemon}", "is evolving!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "evolution_stopped" }?.pages.first?.lines, ["Huh? {pokemon}", "stopped evolving!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "route_22_rival_before_battle_1" }?.pages.count, 5)
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pewter_gym_received_tm34" }?.pages.first?.lines, ["<PLAYER> received", "TM34!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "pewter_gym_tm34_no_room" }?.pages.first?.lines, ["You don't have", "room for this!"])
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "pewter_gym_brock_received_boulder_badge" }?.pages[2].lines,
            ["<PLAYER> received", "the BOULDERBADGE!"]
        )
        XCTAssertEqual(manifest.dialogues.first { $0.id == "cerulean_gym_misty_received_tm11" }?.pages.first?.lines, ["<PLAYER> received", "TM11!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "cerulean_gym_misty_tm11_no_room" }?.pages.first?.lines, ["You better make", "room for this!"])
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "cerulean_gym_misty_received_cascade_badge" }?.pages[2].lines,
            ["You can have the", "CASCADEBADGE to", "show you beat me!"]
        )
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_caught" }?.pages.first?.lines, ["All right!", "{capturedPokemon} was", "caught!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_caught" }?.pages.first?.events, [.init(kind: .soundEffect, soundEffectID: "SFX_CAUGHT_MON")])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_dex_added" }?.pages.first?.lines, ["New POKéDEX data", "will be added for", "{capturedPokemon}!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_dex_added" }?.pages.first?.events, [.init(kind: .soundEffect, soundEffectID: "SFX_DEX_PAGE_ADDED")])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_transferred_bill_pc" }?.pages.first?.lines, ["{capturedPokemon} was", "transferred to", "BILL's PC!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "capture_transferred_someone_pc" }?.pages.first?.lines, ["{capturedPokemon} was", "transferred to", "someone's PC!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "mt_moon_b2f_dome_fossil_you_want" }?.pages.first?.lines, ["You want the", "DOME FOSSIL?"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "mt_moon_b2f_received_fossil" }?.pages.first?.lines, ["<PLAYER> got the", "{wStringBuffer}!"])
        XCTAssertEqual(
            manifest.dialogues.first { $0.id == "mt_moon_b2f_received_fossil" }?.pages.first?.events,
            [.init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")]
        )
        XCTAssertEqual(manifest.dialogues.first { $0.id == "mt_moon_b2f_super_nerd_ok_ill_share" }?.pages.first?.lines, ["OK!", "I'll share!"])
        XCTAssertEqual(manifest.dialogues.first { $0.id == "mt_moon_b2f_super_nerd_each_take_one" }?.pages.first?.lines, ["We'll each take", "one!", "No being greedy!"])

        let extractedDialogueIDs = Set(manifest.dialogues.map(\.id))
        let parcelHandoff = try XCTUnwrap(manifest.scripts.first { $0.id == "oaks_lab_parcel_handoff" })
        let missingDialogueReferences = parcelHandoff.steps
            .compactMap(\.dialogueID)
            .filter { extractedDialogueIDs.contains($0) == false }
        XCTAssertEqual(missingDialogueReferences, [])

        let declaredTrainerBattleIDs = Set(manifest.trainerBattles.map(\.id))
        let missingTrainerBattleReferences = manifest.maps
            .flatMap(\.objects)
            .compactMap(\.trainerBattleID)
            .filter { declaredTrainerBattleIDs.contains($0) == false }
        XCTAssertEqual(missingTrainerBattleReferences, [])

        let eventFlagIDs = Set(manifest.eventFlags.flags.map(\.id))
        let missingCompletionFlags = manifest.trainerBattles
            .map(\.completionFlagID)
            .filter { $0.isEmpty == false }
            .filter { eventFlagIDs.contains($0) == false }
        XCTAssertEqual(missingCompletionFlags, [])
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
        XCTAssertEqual(decoded.maps.count, 41)
        XCTAssertEqual(decoded.tilesets.count, 16)
        XCTAssertEqual(decoded.overworldSprites.count, 40)
        XCTAssertEqual(decoded.items.count, 106)
        XCTAssertEqual(decoded.marts.count, 3)
        XCTAssertEqual(decoded.wildEncounterTables.count, 11)
        XCTAssertEqual(decoded.fieldInteractions.count, 6)
        XCTAssertEqual(decoded.trainerBattles.count, 57)
        XCTAssertEqual(decoded.eventFlags.flags.count, 74)
        XCTAssertGreaterThan(decoded.dialogues.count, 250)
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_gramps" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "oaks_lab_rival_ill_take_you_on" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "pewter_gym_brock_pre_battle" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "cerulean_gym_misty_received_cascade_badge" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "route3_youngster1_battle" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "pokemon_center_welcome" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "viridian_forest_youngster2_battle" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "cerulean_city_rival_pre_battle" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "route24_cooltrainer_m1_contest_prize" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "bills_house_ss_ticket_received" })
        XCTAssertNotNil(decoded.dialogues.first { $0.id == "pickup_found_moon_stone" })
        XCTAssertNotNil(decoded.fieldInteractions.first { $0.id == "pokemon_center_healing" })
        XCTAssertNotNil(decoded.fieldInteractions.first { $0.id == "pewter_pokecenter_pokemon_center_healing" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "OAKS_LAB" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "VIRIDIAN_CITY" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "CERULEAN_CITY" })
        XCTAssertNotNil(decoded.mapScripts.first { $0.mapID == "ROUTE_24" })
        XCTAssertNotNil(decoded.maps.first { $0.id == "CERULEAN_GYM" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_rival1_1" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_bug_catcher_1" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_rocket_5" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "cerulean_city_rival_7" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_brock_1" })
        XCTAssertNotNil(decoded.trainerBattles.first { $0.id == "opp_misty_1" })
        XCTAssertEqual(decoded.trainerBattles.first { $0.id == "opp_bug_catcher_1" }?.trainerSpritePath, "Assets/battle/trainers/bugcatcher.png")
        XCTAssertEqual(decoded.trainerBattles.first { $0.id == "opp_brock_1" }?.trainerSpritePath, "Assets/battle/trainers/brock.png")
        XCTAssertEqual(decoded.trainerBattles.first { $0.id == "opp_misty_1" }?.trainerSpritePath, "Assets/battle/trainers/misty.png")
        XCTAssertEqual(decoded.commonBattleText.trainerSentOut, "{trainerName} sent out {enemyPokemon}!")
        XCTAssertGreaterThan(decoded.typeEffectiveness.count, 0)
        XCTAssertFalse(decoded.items.contains { $0.id.contains("\\") })
        XCTAssertEqual(decoded.tilesets.first?.imagePath, "Assets/field/tilesets/reds_house.png")
        XCTAssertEqual(decoded.tilesets.first?.blocksetPath, "Assets/field/blocksets/reds_house.bst")
        XCTAssertEqual(decoded.tilesets.first { $0.id == "OVERWORLD" }?.animation.kind, .waterFlower)
        XCTAssertEqual(decoded.tilesets.first { $0.id == "FOREST" }?.animation.kind, .water)
        XCTAssertEqual(
            decoded.tilesets.first { $0.id == "OVERWORLD" }?.animation.animatedTiles.last?.frameImagePaths,
            [
                "Assets/field/tileset_animations/flower/flower1.png",
                "Assets/field/tileset_animations/flower/flower2.png",
                "Assets/field/tileset_animations/flower/flower3.png",
            ]
        )
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

    func testBattleAnimationExtractorBuildsSourceDrivenMoveAnimationsAndSupportTables() throws {
        let manifest = try extractBattleAnimationManifest(source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()))

        XCTAssertEqual(manifest.variant, .red)
        XCTAssertEqual(
            manifest.sourceFiles,
            [
                "data/moves/animations.asm",
                "data/battle_anims/subanimations.asm",
                "data/battle_anims/frame_blocks.asm",
                "data/battle_anims/base_coords.asm",
                "data/battle_anims/special_effect_pointers.asm",
                "constants/move_animation_constants.asm",
                "engine/battle/animations.asm",
                "gfx/battle/move_anim_0.png",
                "gfx/battle/move_anim_1.png",
            ]
        )
        XCTAssertEqual(
            manifest.tilesets,
            [
                .init(id: "MOVE_ANIM_TILESET_0", tileCount: 79, imagePath: "Assets/battle/animations/move_anim_0.png"),
                .init(id: "MOVE_ANIM_TILESET_1", tileCount: 79, imagePath: "Assets/battle/animations/move_anim_1.png"),
                .init(id: "MOVE_ANIM_TILESET_2", tileCount: 64, imagePath: "Assets/battle/animations/move_anim_0.png"),
            ]
        )
        XCTAssertEqual(
            manifest.moveAnimations.first { $0.moveID == "POUND" }?.commands,
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
            manifest.moveAnimations.first { $0.moveID == "THUNDERPUNCH" }?.commands,
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
        XCTAssertEqual(
            manifest.subanimations.first { $0.id == "SUBANIM_0_STAR_TWICE" },
            .init(
                id: "SUBANIM_0_STAR_TWICE",
                transform: .hFlip,
                steps: [
                    .init(frameBlockID: "FRAMEBLOCK_01", baseCoordinateID: "BASECOORD_0F", frameBlockMode: .mode00),
                    .init(frameBlockID: "FRAMEBLOCK_01", baseCoordinateID: "BASECOORD_1D", frameBlockMode: .mode00),
                ]
            )
        )
        XCTAssertEqual(
            manifest.frameBlocks.first { $0.id == "FRAMEBLOCK_06" }?.tiles.first,
            .init(x: 8, y: 0, tileID: 0x23, flipH: false, flipV: false)
        )
        XCTAssertEqual(
            manifest.baseCoordinates.first { $0.id == "BASECOORD_30" },
            .init(id: "BASECOORD_30", x: 0x28, y: 0x58)
        )
        XCTAssertEqual(
            manifest.specialEffects.first { $0.id == "SE_SHAKE_SCREEN" },
            .init(id: "SE_SHAKE_SCREEN", routine: "AnimationShakeScreen")
        )
    }
}
