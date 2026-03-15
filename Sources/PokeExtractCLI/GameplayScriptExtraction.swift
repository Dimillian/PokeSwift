import Foundation
import PokeDataModel

func buildMapScripts() -> [MapScriptManifest] {
    [
        MapScriptManifest(
            mapID: "PALLET_TOWN",
            triggers: [
                .init(
                    id: "north_exit_oak_intro",
                    scriptID: "pallet_town_oak_intro",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                        .init(kind: "playerYEquals", intValue: 1),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "VIRIDIAN_CITY",
            triggers: [
                .init(
                    id: "gym_locked_pushback",
                    scriptID: "viridian_city_gym_locked_pushback",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_VIRIDIAN_GYM_OPEN"),
                        .init(kind: "playerYEquals", intValue: 8),
                        .init(kind: "playerXEquals", intValue: 32),
                    ]
                ),
                .init(
                    id: "old_man_blocks_north_exit",
                    scriptID: "viridian_city_old_man_blocks_north_exit",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_POKEDEX"),
                        .init(kind: "playerYEquals", intValue: 9),
                        .init(kind: "playerXEquals", intValue: 19),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "VIRIDIAN_MART",
            triggers: [
                .init(
                    id: "oaks_parcel_entry",
                    scriptID: "viridian_mart_oaks_parcel",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_OAKS_PARCEL"),
                        .init(kind: "playerYEquals", intValue: 7),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "MUSEUM_1F",
            triggers: [
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
        ),
        MapScriptManifest(
            mapID: "PEWTER_CITY",
            triggers: [
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
        ),
        MapScriptManifest(
            mapID: "ROUTE_22",
            triggers: [
                .init(
                    id: "first_rival_upper_after_charmander",
                    scriptID: "route_22_rival_1_challenge_4_upper",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "chosenStarterEquals", stringValue: "CHARMANDER"),
                    ]
                ),
                .init(
                    id: "first_rival_upper_after_squirtle",
                    scriptID: "route_22_rival_1_challenge_5_upper",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "chosenStarterEquals", stringValue: "SQUIRTLE"),
                    ]
                ),
                .init(
                    id: "first_rival_upper_after_bulbasaur",
                    scriptID: "route_22_rival_1_challenge_6_upper",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 4),
                        .init(kind: "chosenStarterEquals", stringValue: "BULBASAUR"),
                    ]
                ),
                .init(
                    id: "first_rival_lower_after_charmander",
                    scriptID: "route_22_rival_1_challenge_4_lower",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 5),
                        .init(kind: "chosenStarterEquals", stringValue: "CHARMANDER"),
                    ]
                ),
                .init(
                    id: "first_rival_lower_after_squirtle",
                    scriptID: "route_22_rival_1_challenge_5_lower",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 5),
                        .init(kind: "chosenStarterEquals", stringValue: "SQUIRTLE"),
                    ]
                ),
                .init(
                    id: "first_rival_lower_after_bulbasaur",
                    scriptID: "route_22_rival_1_challenge_6_lower",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                        .init(kind: "flagSet", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                        .init(kind: "playerXEquals", intValue: 29),
                        .init(kind: "playerYEquals", intValue: 5),
                        .init(kind: "chosenStarterEquals", stringValue: "BULBASAUR"),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "ROUTE_22_GATE",
            triggers: [
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
        ),
        MapScriptManifest(
            mapID: "OAKS_LAB",
            triggers: [
                .init(
                    id: "dont_go_away_before_starter",
                    scriptID: "oaks_lab_dont_go_away",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON"),
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "playerYEquals", intValue: 6),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_charmander",
                    scriptID: "oaks_lab_rival_challenge_vs_squirtle",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "CHARMANDER"),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_squirtle",
                    scriptID: "oaks_lab_rival_challenge_vs_bulbasaur",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "SQUIRTLE"),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_bulbasaur",
                    scriptID: "oaks_lab_rival_challenge_vs_charmander",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "BULBASAUR"),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "MT_MOON_B2F",
            triggers: [
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
        ),
    ]
}

func buildScripts(repoRoot: URL, maps: [MapManifest]) throws -> [ScriptManifest] {
    let autoMovement = try String(contentsOf: repoRoot.appendingPathComponent("engine/overworld/auto_movement.asm"))
    let oaksLabScripts = try String(contentsOf: repoRoot.appendingPathComponent("scripts/OaksLab.asm"))
    let route22Scripts = try String(contentsOf: repoRoot.appendingPathComponent("scripts/Route22.asm"))

    let palletOakEscortPath = try parseRepeatedMovementLabel("RLEList_ProfOakWalkToLab", from: autoMovement)
    let palletPlayerEscortPath = try parseSimulatedJoypadMovementLabel("RLEList_PlayerWalkToLab", from: autoMovement)
    let oakEntryPath = try parseMovementLabel("OakEntryMovement", from: oaksLabScripts)
    let playerEntryPath = try parseSimulatedJoypadMovementLabel("PlayerEntryMovementRLE", from: oaksLabScripts)
    let rivalMiddleBall1 = try parseMovementLabel(".MiddleBallMovement1", from: oaksLabScripts)
    let rivalMiddleBall2 = try parseMovementLabel(".MiddleBallMovement2", from: oaksLabScripts)
    let rivalRightBall1 = try parseMovementLabel(".RightBallMovement1", from: oaksLabScripts)
    let rivalRightBall2 = try parseMovementLabel(".RightBallMovement2", from: oaksLabScripts)
    let rivalLeftBall1 = try parseMovementLabel(".LeftBallMovement1", from: oaksLabScripts)
    let rivalLeftBall2 = try parseMovementLabel(".LeftBallMovement2", from: oaksLabScripts)
    let rivalExitPath = try parseMovementLabel(".RivalExitMovement", from: oaksLabScripts)
    let route22Rival1ExitPathLower = try parseMovementLabel("Route22Rival1ExitMovementData1", from: route22Scripts)
    let route22Rival1ExitPathUpper = try parseMovementLabel("Route22Rival1ExitMovementData2", from: route22Scripts)

    var scripts: [ScriptManifest] = [
        ScriptManifest(
            id: "reds_house_1f_mom_heal",
            steps: [
                .init(action: "healParty"),
                .init(action: "showDialogue", dialogueID: "reds_house_1f_mom_looking_great"),
            ]
        ),
        ScriptManifest(
            id: "viridian_pokecenter_nurse_heal",
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: "pokemon_center_healing"),
            ]
        ),
        ScriptManifest(
            id: "museum_1f_scientist1_interaction",
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: museumAdmissionFieldInteractionID(for: "MUSEUM_1F")),
            ]
        ),
        ScriptManifest(
            id: "museum_1f_entrance_admission",
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: museumAdmissionFieldInteractionID(for: "MUSEUM_1F")),
            ]
        ),
        ScriptManifest(
            id: "pewter_city_reset_museum_ticket",
            steps: [
                .init(action: "clearFlag", flagID: "EVENT_BOUGHT_MUSEUM_TICKET"),
            ]
        ),
        ScriptManifest(
            id: "route_1_potion_sample",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_1_youngster_1_mart_sample"),
                .init(action: "addItem", stringValue: "POTION", intValue: 1),
                .init(action: "showDialogue", dialogueID: "route_1_youngster_1_got_potion"),
                .init(action: "setFlag", flagID: "EVENT_GOT_POTION_SAMPLE"),
            ]
        ),
        ScriptManifest(
            id: "viridian_city_old_man_blocks_north_exit",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_city_old_man_private_property"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "viridian_city_gym_locked_pushback",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_city_gym_locked"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "viridian_mart_oaks_parcel",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_mart_clerk_you_came_from_pallet_town"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.left, .up, .up])]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "viridian_mart_clerk_parcel_quest"),
                .init(action: "addItem", stringValue: "OAKS_PARCEL", intValue: 1),
                .init(action: "setFlag", flagID: "EVENT_GOT_OAKS_PARCEL"),
            ]
        ),
        ScriptManifest(
            id: "route_22_gate_guard_blocks_northbound_upper_lane",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_22_gate_guard_no_boulder_badge"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "route_22_gate_guard_blocks_northbound_lower_lane",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_22_gate_guard_no_boulder_badge"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_parcel_handoff",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_deliver_parcel"),
                .init(action: "removeItem", stringValue: "OAKS_PARCEL", intValue: 1),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_parcel_thanks"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 8, y: 3), objectID: "oaks_lab_rival"),
                .init(action: "faceObject", stringValue: "left", objectID: "oaks_lab_rival"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_gramps"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_what_did_you_call_me_for"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_i_have_a_request"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_my_invention_pokedex"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_got_pokedex"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_pokedex_1", visible: false),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_pokedex_2", visible: false),
                .init(action: "setFlag", flagID: "EVENT_GOT_POKEDEX"),
                .init(action: "setFlag", flagID: "EVENT_OAK_GOT_PARCEL"),
                .init(action: "setObjectVisibility", objectID: "viridian_city_old_man_sleepy", visible: false),
                .init(action: "setObjectVisibility", objectID: "viridian_city_old_man_awake", visible: true),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_that_was_my_dream"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_leave_it_all_to_me"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: false),
                .init(action: "setObjectVisibility", objectID: "route_22_rival_1", visible: true),
                .init(action: "setFlag", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                .init(action: "clearFlag", flagID: "EVENT_2ND_ROUTE22_RIVAL_BATTLE"),
                .init(action: "setFlag", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                .init(action: "restoreMapMusic"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_charmander",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_charmander"),
                .init(action: "startStarterChoice", stringValue: "CHARMANDER"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_squirtle",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_squirtle"),
                .init(action: "startStarterChoice", stringValue: "SQUIRTLE"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_bulbasaur",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_bulbasaur"),
                .init(action: "startStarterChoice", stringValue: "BULBASAUR"),
            ]
        ),
        ScriptManifest(
            id: "pallet_town_oak_intro",
            steps: [
                .init(action: "setFlag", flagID: "EVENT_OAK_APPEARED_IN_PALLET"),
                .init(action: "playMusicCue", stringValue: "oak_intro"),
                .init(action: "setObjectVisibility", objectID: "pallet_town_oak", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 8, y: 5), objectID: "pallet_town_oak"),
                .init(action: "faceObject", stringValue: "down", objectID: "pallet_town_oak"),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_hey_wait"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.down])]
                    )
                ),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "pallet_town_oak", path: [])],
                        targetPlayerOffset: .init(x: 0, y: 1)
                    )
                ),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_its_unsafe"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .palletEscort,
                        variants: [
                            .init(
                                id: "player_left_lane",
                                conditions: [.init(kind: "playerXEquals", intValue: 10)],
                                actors: [
                                    .init(actorID: "pallet_town_oak", path: palletOakEscortPath),
                                    .init(actorID: "player", path: palletPlayerEscortPath),
                                ]
                            ),
                            .init(
                                id: "player_right_lane",
                                conditions: [.init(kind: "playerXEquals", intValue: 11)],
                                actors: [
                                    .init(actorID: "pallet_town_oak", path: [.left] + palletOakEscortPath),
                                    .init(actorID: "player", path: [.left] + palletPlayerEscortPath),
                                ]
                            ),
                        ]
                    )
                ),
                .init(action: "setObjectVisibility", objectID: "pallet_town_oak", visible: false),
                .init(action: "setMap", stringValue: "OAKS_LAB", point: .init(x: 5, y: 11)),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_2", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 5, y: 10), objectID: "oaks_lab_oak_2"),
                .init(action: "faceObject", stringValue: "up", objectID: "oaks_lab_oak_2"),
                .init(action: "restoreMapMusic"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "oaks_lab_oak_2", path: oakEntryPath)]
                    )
                ),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_2", visible: false),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_1", visible: true),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_oak_1"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: playerEntryPath)]
                    )
                ),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB_2"),
                .init(action: "faceObject", stringValue: "up", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_fed_up_with_waiting"),
                .init(action: "setFlag", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_choose_mon"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_what_about_me"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_be_patient"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_dont_go_away",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_oak_1"),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_dont_go_away_yet"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.up])]
                    )
                ),
                .init(action: "facePlayer", stringValue: "up"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_charmander",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_below_table",
                                conditions: [.init(kind: "playerYEquals", intValue: 4)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalMiddleBall1)]
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalMiddleBall2)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_squirtle", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_squirtle"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_squirtle",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_below_table",
                                conditions: [.init(kind: "playerYEquals", intValue: 4)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalRightBall1)]
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalRightBall2)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_bulbasaur", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_bulbasaur"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_bulbasaur",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_right_of_table",
                                conditions: [.init(kind: "playerXEquals", intValue: 9)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalLeftBall2)],
                                point: .init(x: 9, y: 8)
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalLeftBall1)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_charmander", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_charmander"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_squirtle",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_1"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_bulbasaur",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_2"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_charmander",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_3"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_exit_after_battle",
            steps: [
                .init(action: "playMusicCue", stringValue: "rival_exit"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_smell_you_later"),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "oaks_lab_rival", path: rivalExitPath)]
                    )
                ),
                .init(action: "facePlayer", stringValue: "down"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: false),
                .init(action: "restoreMapMusic"),
            ]
        ),
    ]

    scripts.append(
        ScriptManifest(
            id: "pewter_gym_brock_battle",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "pewter_gym_brock"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "showDialogue", dialogueID: "pewter_gym_brock_pre_battle"),
                .init(action: "startBattle", battleID: "opp_brock_1"),
            ]
        )
    )
    scripts.append(
        ScriptManifest(
            id: "pewter_gym_brock_reward",
            steps: [
                .init(action: "showDialogue", dialogueID: "pewter_gym_brock_wait_take_this"),
                .init(action: "setFlag", flagID: "EVENT_BEAT_BROCK"),
                .init(
                    action: "giveItem",
                    stringValue: "TM_BIDE",
                    intValue: 1,
                    successDialogueID: "pewter_gym_received_tm34",
                    failureDialogueID: "pewter_gym_tm34_no_room",
                    successFlagID: "EVENT_GOT_TM34"
                ),
                .init(action: "awardBadge", badgeID: "BOULDERBADGE"),
                .init(action: "setObjectVisibility", objectID: "pewter_city_youngster", visible: false),
                .init(action: "setObjectVisibility", objectID: "route_22_rival_1", visible: false),
                .init(action: "clearFlag", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                .init(action: "clearFlag", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                .init(action: "setFlag", flagID: "EVENT_BEAT_PEWTER_GYM_TRAINER_0"),
                .init(action: "restoreMapMusic"),
            ]
        )
    )

    let route22ChallengeVariants: [(scriptID: String, battleID: String, offset: TilePoint, rivalFacing: String, playerFacing: String)] = [
        ("route_22_rival_1_challenge_4_upper", "route_22_rival_1_4_upper", .init(x: 0, y: 1), "right", "left"),
        ("route_22_rival_1_challenge_5_upper", "route_22_rival_1_5_upper", .init(x: 0, y: 1), "right", "left"),
        ("route_22_rival_1_challenge_6_upper", "route_22_rival_1_6_upper", .init(x: 0, y: 1), "right", "left"),
        ("route_22_rival_1_challenge_4_lower", "route_22_rival_1_4_lower", .init(x: -1, y: 0), "up", "down"),
        ("route_22_rival_1_challenge_5_lower", "route_22_rival_1_5_lower", .init(x: -1, y: 0), "up", "down"),
        ("route_22_rival_1_challenge_6_lower", "route_22_rival_1_6_lower", .init(x: -1, y: 0), "up", "down"),
    ]

    for variant in route22ChallengeVariants {
        scripts.append(
            ScriptManifest(
                id: variant.scriptID,
                steps: [
                    .init(action: "playMusicCue", stringValue: "rival_intro"),
                    .init(
                        action: "performMovement",
                        movement: .init(
                            kind: .pathToPlayerAdjacent,
                            actors: [.init(actorID: "route_22_rival_1", path: [])],
                            targetPlayerOffset: variant.offset
                        )
                    ),
                    .init(action: "faceObject", stringValue: variant.rivalFacing, objectID: "route_22_rival_1"),
                    .init(action: "facePlayer", stringValue: variant.playerFacing),
                    .init(action: "showDialogue", dialogueID: "route_22_rival_before_battle_1"),
                    .init(action: "startBattle", battleID: variant.battleID),
                ]
            )
        )
    }

    scripts.append(
        ScriptManifest(
            id: "route_22_rival_1_exit_upper",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_22_rival_after_battle_1"),
                .init(action: "playMusicCue", stringValue: "rival_exit"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "route_22_rival_1", path: route22Rival1ExitPathUpper)]
                    )
                ),
                .init(action: "setFlag", flagID: "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE"),
                .init(action: "setObjectVisibility", objectID: "route_22_rival_1", visible: false),
                .init(action: "clearFlag", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                .init(action: "clearFlag", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                .init(action: "restoreMapMusic"),
            ]
        )
    )
    scripts.append(
        ScriptManifest(
            id: "route_22_rival_1_exit_lower",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_22_rival_after_battle_1"),
                .init(action: "playMusicCue", stringValue: "rival_exit"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "route_22_rival_1", path: route22Rival1ExitPathLower)]
                    )
                ),
                .init(action: "setFlag", flagID: "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE"),
                .init(action: "setObjectVisibility", objectID: "route_22_rival_1", visible: false),
                .init(action: "clearFlag", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                .init(action: "clearFlag", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                .init(action: "restoreMapMusic"),
            ]
        )
    )

    scripts.append(
        ScriptManifest(
            id: "mt_moon_b2f_super_nerd_battle",
            steps: [
                .init(action: "faceObject", stringValue: "right", objectID: "mt_moon_b2f_super_nerd"),
                .init(action: "facePlayer", stringValue: "left"),
                .init(action: "showDialogue", dialogueID: "mt_moon_b2f_super_nerd_theyre_both_mine"),
                .init(action: "startBattle", battleID: "opp_super_nerd_2"),
            ]
        )
    )
    scripts.append(
        ScriptManifest(
            id: "mt_moon_b2f_take_dome_fossil",
            steps: [
                .init(
                    action: "promptItemPickup",
                    stringValue: "DOME_FOSSIL",
                    objectID: "mt_moon_b2f_dome_fossil",
                    dialogueID: "mt_moon_b2f_dome_fossil_you_want",
                    successDialogueID: "mt_moon_b2f_received_fossil",
                    failureDialogueID: "mt_moon_b2f_you_have_no_room",
                    successFlagID: "EVENT_GOT_DOME_FOSSIL"
                ),
                .init(action: "moveObject", path: [.right], objectID: "mt_moon_b2f_super_nerd"),
                .init(action: "showDialogue", dialogueID: "mt_moon_b2f_super_nerd_then_this_is_mine"),
                .init(action: "setObjectVisibility", objectID: "mt_moon_b2f_helix_fossil", visible: false),
            ]
        )
    )
    scripts.append(
        ScriptManifest(
            id: "mt_moon_b2f_take_helix_fossil",
            steps: [
                .init(
                    action: "promptItemPickup",
                    stringValue: "HELIX_FOSSIL",
                    objectID: "mt_moon_b2f_helix_fossil",
                    dialogueID: "mt_moon_b2f_helix_fossil_you_want",
                    successDialogueID: "mt_moon_b2f_received_fossil",
                    failureDialogueID: "mt_moon_b2f_you_have_no_room",
                    successFlagID: "EVENT_GOT_HELIX_FOSSIL"
                ),
                .init(action: "moveObject", path: [.up], objectID: "mt_moon_b2f_super_nerd"),
                .init(action: "showDialogue", dialogueID: "mt_moon_b2f_super_nerd_then_this_is_mine"),
                .init(action: "setObjectVisibility", objectID: "mt_moon_b2f_dome_fossil", visible: false),
            ]
        )
    )

    scripts.append(contentsOf: buildPokemonCenterHealingScripts(maps: maps))
    return scripts
}

// MARK: - Relocated helper (internal for GameplayObjectExtraction)

func pokemonCenterHealScriptID(for mapID: String) -> String {
    mapID == "VIRIDIAN_POKECENTER" ? "viridian_pokecenter_nurse_heal" : "\(mapID.lowercased())_nurse_heal"
}

// MARK: - Private helpers

private func buildPokemonCenterHealingScripts(maps: [MapManifest]) -> [ScriptManifest] {
    maps.compactMap { map in
        guard
            map.id != "VIRIDIAN_POKECENTER",
            map.objects.contains(where: { $0.sprite == "SPRITE_NURSE" })
        else {
            return nil
        }
        return ScriptManifest(
            id: pokemonCenterHealScriptID(for: map.id),
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: pokemonCenterFieldInteractionID(for: map.id)),
            ]
        )
    }
}

func parseMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    return expandMovementLines(lines)
}

func parseRepeatedMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    return expandRepeatedMovementLines(lines)
}

func parseSimulatedJoypadMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    // The engine decrements `wSimulatedJoypadStatesIndex` before reading from the decoded buffer,
    // so simulated joypad paths execute from the tail of the RLE list back to the head.
    return Array(expandRepeatedMovementLines(lines).reversed())
}

func linesForMovementLabel(_ label: String, in contents: String) throws -> [String] {
    let pattern = "(?m)^\\s*\(NSRegularExpression.escapedPattern(for: label))(?::)?\\s*$"
    let regex = try NSRegularExpression(pattern: pattern)
    let fullRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    guard let match = regex.firstMatch(in: contents, range: fullRange),
          let labelRange = Range(match.range, in: contents) else {
        throw ExtractorError.invalidArguments("missing movement label \(label)")
    }

    let tail = contents[labelRange.upperBound...]
    var lines: [String] = []
    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty {
            if lines.isEmpty == false {
                break
            }
            continue
        }
        if line.hasPrefix(".") || line.hasSuffix(":") || line.contains("Script:") || line.contains("Text:") {
            if lines.isEmpty == false {
                break
            }
        }
        lines.append(line)
        if line.contains("db -1") {
            break
        }
    }
    guard lines.isEmpty == false else {
        throw ExtractorError.invalidArguments("movement label \(label) had no data")
    }
    return lines
}

func expandMovementLines(_ lines: [String]) -> [FacingDirection] {
    var path: [FacingDirection] = []
    for line in lines where line.hasPrefix("db ") {
        let tokens = movementTokens(from: line)
        for token in tokens {
            if token == "-1" {
                return path
            }
            if token == "NPC_CHANGE_FACING" {
                continue
            }
            if let direction = directionToken(token) {
                path.append(direction)
            }
        }
    }
    return path
}

private func expandRepeatedMovementLines(_ lines: [String]) -> [FacingDirection] {
    var path: [FacingDirection] = []
    for line in lines where line.hasPrefix("db ") {
        let tokens = movementTokens(from: line)
        guard let first = tokens.first else { continue }
        if first == "-1" {
            return path
        }
        guard let direction = directionToken(first) else {
            continue
        }
        let repeatCount = tokens.count > 1 ? Int(tokens[1]) ?? 1 : 1
        path.append(contentsOf: Array(repeating: direction, count: repeatCount))
    }
    return path
}

private func movementTokens(from line: String) -> [String] {
    line
        .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        .first?
        .replacingOccurrences(of: "db", with: "")
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
}

private func directionToken(_ token: String) -> FacingDirection? {
    switch token {
    case "NPC_MOVEMENT_UP", "PAD_UP":
        return .up
    case "NPC_MOVEMENT_DOWN", "PAD_DOWN":
        return .down
    case "NPC_MOVEMENT_LEFT", "PAD_LEFT":
        return .left
    case "NPC_MOVEMENT_RIGHT", "PAD_RIGHT":
        return .right
    default:
        return nil
    }
}
