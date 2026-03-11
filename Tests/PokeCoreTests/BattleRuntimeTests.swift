import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
    func testWildBattleCursorCanReachRunAndConfirmEscape() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        drainBattleText(runtime)

        runtime.handle(button: .down)

        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedMoveIndex, 1)

        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.currentSnapshot().battle, nil)
    }

    func testWildBattleBagSelectionConsumesPokeBallOnFailedCapture() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.gameplayState?.inventory = [.init(itemID: "POKE_BALL", quantity: 1)]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "bagSelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.bagItems.map(\.itemID), ["POKE_BALL"])
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedBagItemIndex, 0)

        runtime.setBattleRandomOverrides([255])
        runtime.handle(button: .confirm)
        advanceBattleTextUntilMoveSelection(runtime)

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 0)
        XCTAssertFalse(runtime.gameplayState?.ownedSpeciesIDs.contains("PIDGEY") ?? true)
    }

    func testWildBattleCaptureAddsPokemonToPartyAndEndsBattle() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.gameplayState?.inventory = [.init(itemID: "POKE_BALL", quantity: 1)]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.setBattleRandomOverrides([0])
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 0)
        XCTAssertEqual(runtime.gameplayState?.playerParty.count, 2)
        XCTAssertEqual(runtime.gameplayState?.playerParty.last?.speciesID, "PIDGEY")
        XCTAssertTrue(runtime.gameplayState?.ownedSpeciesIDs.contains("PIDGEY") ?? false)
    }

    func testWildBattleCaptureSendsPokemonToCurrentBoxWhenPartyIsFull() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.currentBoxIndex = 0
        runtime.gameplayState?.playerParty = (0..<6).map { index in
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle\(index)")
        }
        runtime.gameplayState?.inventory = [.init(itemID: "POKE_BALL", quantity: 1)]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.setBattleRandomOverrides([0])
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.playerParty.count, 6)
        XCTAssertEqual(runtime.gameplayState?.boxedPokemon[0].pokemon.count, 1)
        XCTAssertEqual(runtime.gameplayState?.boxedPokemon[0].pokemon.first?.speciesID, "PIDGEY")
    }

    func testWildBattleCaptureIsBlockedWhenCurrentBoxIsFull() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.currentBoxIndex = 0
        runtime.gameplayState?.playerParty = (0..<6).map { index in
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle\(index)")
        }
        runtime.gameplayState?.boxedPokemon[0].pokemon = (0..<GameRuntime.storageBoxCapacity).map { index in
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "BoxMon\(index)")
        }
        runtime.gameplayState?.inventory = [.init(itemID: "POKE_BALL", quantity: 1)]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 1)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "turnText")
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "The #MON BOX is full! Can't use that item!")

        advanceBattleTextUntilMoveSelection(runtime)
        XCTAssertEqual(runtime.gameplayState?.boxedPokemon[0].pokemon.count, GameRuntime.storageBoxCapacity)
    }
    func testTrainerBattleCursorDoesNotExposeRunAction() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)

        XCTAssertEqual(runtime.currentSnapshot().battle?.kind, .trainer)
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedMoveIndex, 1)
    }
    func testBattleAdvancesAcrossExtractedEnemyParty() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 255, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 30, baseDefense: 49, baseSpeed: 1, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 500, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_2",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 2,
                            displayName: "BLUE",
                            party: [
                                .init(speciesID: "BULBASAUR", level: 5),
                                .init(speciesID: "SQUIRTLE", level: 5),
                            ],
                            winDialogueID: "win",
                            loseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: true,
                            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_2")
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPartyCount, 2)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyActiveIndex, 0)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "introText")

        drainBattleText(runtime)
        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
        advanceBattlePresentationBatch(runtime)
        advanceBattleUntilPhase(runtime, phase: "moveSelection")

        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyActiveIndex, 1)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPartyCount, 2)
    }
    func testApplyMoveRespectsAccuracyEvasionAndOnlyAppliesEffectOnHit() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TAIL_WHIP"]),
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                    ],
                    moves: [
                        .init(id: "TAIL_WHIP", displayName: "TAIL WHIP", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var attacker = runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")
        var defender = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        defender.evasionStage = 6

        runtime.battleRandomOverrides = [255]
        let missedMove = runtime.applyMove(attacker: &attacker, defender: &defender, moveIndex: 0)
        XCTAssertEqual(defender.defenseStage, 0)
        XCTAssertEqual(missedMove.messages, ["Squirtle used TAIL WHIP!", "But it missed!"])

        defender.evasionStage = 0
        runtime.battleRandomOverrides = [0]
        let landedMove = runtime.applyMove(attacker: &attacker, defender: &defender, moveIndex: 0)
        XCTAssertEqual(defender.defenseStage, -1)
        XCTAssertEqual(landedMove.messages, ["Squirtle used TAIL WHIP!", "Charmander's Defense fell!"])
    }
    func testApplyMoveUsesStabTypeEffectivenessAndCriticalHits() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["EMBER", "TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "NO_ADDITIONAL_EFFECT", type: "FIRE"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    typeEffectiveness: [
                        .init(attackingType: "FIRE", defendingType: "GRASS", multiplier: 20),
                        .init(attackingType: "FIRE", defendingType: "POISON", multiplier: 10),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var fireAttacker = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        var fireDefender = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        runtime.battleRandomOverrides = [0, 255]
        let fireMove = runtime.applyMove(attacker: &fireAttacker, defender: &fireDefender, moveIndex: 0)

        var normalAttacker = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        var normalDefender = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        runtime.battleRandomOverrides = [0, 255]
        let normalMove = runtime.applyMove(attacker: &normalAttacker, defender: &normalDefender, moveIndex: 1)

        var criticalAttacker = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        var criticalDefender = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        runtime.battleRandomOverrides = [0, 0]
        let criticalMove = runtime.applyMove(attacker: &criticalAttacker, defender: &criticalDefender, moveIndex: 0)

        XCTAssertGreaterThan(fireMove.dealtDamage, normalMove.dealtDamage)
        XCTAssertGreaterThan(criticalMove.dealtDamage, fireMove.dealtDamage)
        XCTAssertEqual(fireMove.typeMultiplier, 20)
        XCTAssertTrue(fireMove.messages.contains("It's super effective!"))
        XCTAssertTrue(criticalMove.messages.contains("Critical hit!"))
    }
    func testEnemyAIPrefersUsefulSetupButAvoidsNoOpDebuff() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL", "TACKLE"]),
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let enemy = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        var player = runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")

        XCTAssertEqual(runtime.selectEnemyMoveIndex(enemyPokemon: enemy, playerPokemon: player), 0)

        player.attackStage = -6
        XCTAssertEqual(runtime.selectEnemyMoveIndex(enemyPokemon: enemy, playerPokemon: player), 1)
    }
    func testBattleIntroPresentationAutoRevealsHudAndMoveSelection() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_1")

        let introSnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(introSnapshot.phase, "introText")
        XCTAssertEqual(introSnapshot.presentation.stage, .introFlash1)
        XCTAssertEqual(introSnapshot.presentation.uiVisibility, .hidden)

        waitUntil(
            runtime.currentSnapshot().battle?.phase == "moveSelection",
            message: "battle intro did not settle into move selection"
        )
        let readySnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(readySnapshot.presentation.stage, .commandReady)
        XCTAssertEqual(readySnapshot.presentation.uiVisibility, .visible)
    }

    func testWildBattleIntroUsesSharedFlashSpiralRevealSequence() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)

        var snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.stage, .introFlash1)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.textLines, [])

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introFlash2,
            message: "wild battle intro did not advance to the second flash"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)
        XCTAssertEqual(snapshot.textLines, [])

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introFlash3,
            message: "wild battle intro did not advance to the third flash"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)
        XCTAssertEqual(snapshot.textLines, [])

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introSpiral,
            message: "wild battle intro did not advance to the spiral beat"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)
        XCTAssertEqual(snapshot.textLines, [])

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introCrossing,
            message: "wild battle intro did not advance to the crossing beat"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)
        XCTAssertEqual(snapshot.textLines, [])

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introReveal,
            message: "wild battle intro did not advance to the reveal beat"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .spiral)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .visible)
        XCTAssertEqual(snapshot.textLines, ["Wild Pidgey appeared!"])
        XCTAssertEqual(snapshot.phase, "turnText")

        advanceBattleTextUntilMoveSelection(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.stage, .commandReady)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .none)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .visible)
    }

    func testWildBattleRNGDoesNotResetFromEncounterIdentity() {
        let content = fixtureContent(
            gameplayManifest: fixtureGameplayManifest(
                species: [
                    .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                ],
                moves: [
                    .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                ]
            )
        )
        let sharedSeed: UInt64 = 0x0123_4567_89ab_cdef

        let first = GameRuntime(
            content: content,
            telemetryPublisher: nil,
            runtimeRNGSeedSource: { sharedSeed }
        )
        first.gameplayState = first.makeInitialGameplayState()
        first.scene = .field
        first.substate = "field"
        first.gameplayState?.mapID = "ROUTE_1"
        first.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        first.gameplayState?.playerParty = [
            first.makeConfiguredPokemon(
                speciesID: "SQUIRTLE",
                nickname: "Squirtle",
                level: 5,
                experience: 135,
                dvs: .zero,
                statExp: .zero,
                currentHP: nil,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                moves: nil
            )
        ]
        first.startWildBattle(speciesID: "PIDGEY", level: 3)
        let firstBattleRoll = first.nextBattleRandomByte()

        let second = GameRuntime(
            content: content,
            telemetryPublisher: nil,
            runtimeRNGSeedSource: { sharedSeed }
        )
        second.gameplayState = second.makeInitialGameplayState()
        second.scene = .field
        second.substate = "field"
        second.gameplayState?.mapID = "ROUTE_1"
        second.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        second.gameplayState?.playerParty = [
            second.makeConfiguredPokemon(
                speciesID: "SQUIRTLE",
                nickname: "Squirtle",
                level: 5,
                experience: 135,
                dvs: .zero,
                statExp: .zero,
                currentHP: nil,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                moves: nil
            )
        ]
        _ = second.nextAcquisitionRandomByte()
        second.startWildBattle(speciesID: "PIDGEY", level: 3)
        let secondBattleRoll = second.nextBattleRandomByte()

        XCTAssertNotEqual(firstBattleRoll, secondBattleRoll)
    }

    func testBattleTurnPresentationStagesPlayerThenEnemy() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 35, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            winDialogueID: "win",
                            loseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: true,
                            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255, 0]
        runtime.handle(button: .confirm)
        let timeline = captureBattleTimeline(runtime)
        let playerWindupIndex = timeline.firstIndex {
            $0.presentation.stage == .attackWindup &&
                $0.presentation.activeSide == .player &&
                $0.battleMessage == "Squirtle used TACKLE!"
        }
        XCTAssertNotNil(playerWindupIndex, "player attack windup did not appear")

        let enemyWindupIndex = timeline.firstIndex {
            $0.presentation.stage == .attackWindup &&
                $0.presentation.activeSide == .enemy &&
                $0.battleMessage == "Bulbasaur used GROWL!"
        }
        XCTAssertNil(enemyWindupIndex, "enemy attack should wait for confirm after the player action")

        runtime.handle(button: .confirm)
        let resumedTimeline = captureBattleTimeline(runtime)
        let resumedEnemyWindupIndex = resumedTimeline.firstIndex {
            $0.presentation.stage == .attackWindup &&
                $0.presentation.activeSide == .enemy &&
                $0.battleMessage == "Bulbasaur used GROWL!"
        }
        XCTAssertNotNil(
            resumedEnemyWindupIndex,
            "enemy attack did not start after confirming the next action"
        )

        let enemyResultIndex = resumedTimeline.firstIndex {
            $0.presentation.stage == .resultText &&
                $0.battleMessage == "Squirtle's Attack fell!"
        }
        XCTAssertNotNil(
            enemyResultIndex,
            "enemy follow-up effect text did not appear"
        )

        if let resumedEnemyWindupIndex, let enemyResultIndex {
            XCTAssertGreaterThan(enemyResultIndex, resumedEnemyWindupIndex)

            let snapshotBeforeEnemyAction = resumedTimeline[resumedEnemyWindupIndex]
            XCTAssertEqual(snapshotBeforeEnemyAction.playerPokemon.currentHP, snapshotBeforeEnemyAction.playerPokemon.maxHP)
            XCTAssertLessThan(snapshotBeforeEnemyAction.enemyPokemon.currentHP, snapshotBeforeEnemyAction.enemyPokemon.maxHP)
        }
    }

    func testBattleKoPresentationTriggersExperienceWithoutEnemyCounterattack() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 62, growthRate: .mediumSlow, baseHP: 39, baseAttack: 200, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 35, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            winDialogueID: "win",
                            loseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: true,
                            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]
        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
        advanceBattlePresentationBatch(runtime)

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .experience,
            message: "ko flow did not reach the experience presentation stage"
        )
        let experienceSnapshot = runtime.currentSnapshot().battle
        XCTAssertEqual(experienceSnapshot?.presentation.meterAnimation?.kind, .experience)
        XCTAssertEqual(experienceSnapshot?.presentation.activeSide, .player)

        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        XCTAssertNotEqual(runtime.currentSnapshot().battle?.presentation.activeSide, .enemy)
        XCTAssertNotEqual(runtime.currentSnapshot().battle?.presentation.stage, .attackWindup)
    }

    func testBattleLevelUpMovePromptBlocksHmReplacementAndFinishesAfterLearning() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 62,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 200,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH", "CUT", "GROWL", "LEER"],
                            levelUpLearnset: [.init(level: 6, moveID: "EMBER")]
                        ),
                        .init(
                            id: "BULBASAUR",
                            displayName: "Bulbasaur",
                            primaryType: "GRASS",
                            secondaryType: "POISON",
                            baseExp: 64,
                            growthRate: .mediumSlow,
                            baseHP: 45,
                            baseAttack: 49,
                            baseDefense: 49,
                            baseSpeed: 35,
                            baseSpecial: 65,
                            startingMoves: ["GROWL"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "CUT", displayName: "CUT", power: 50, accuracy: 95, maxPP: 30, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "LEER", displayName: "LEER", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "BURN_SIDE_EFFECT1", type: "FIRE"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            winDialogueID: "win",
                            loseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: true,
                            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
        advanceBattlePresentationBatch(runtime)
        advanceBattleUntilPhase(runtime, phase: "learnMoveDecision")

        var snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.learnMovePrompt?.stage, .confirm)
        XCTAssertEqual(snapshot.learnMovePrompt?.moveID, "EMBER")
        XCTAssertEqual(snapshot.battleMessage, "Teach EMBER to Charmander?")

        runtime.handle(button: .confirm)

        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "learnMoveSelection")
        XCTAssertEqual(snapshot.learnMovePrompt?.stage, .replace)

        runtime.handle(button: .down)
        runtime.handle(button: .confirm)

        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "learnMoveSelection")
        XCTAssertEqual(snapshot.battleMessage, "CUT can't be forgotten.")

        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.level, 6)
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.moves.map(\.id), ["SCRATCH", "CUT", "EMBER", "LEER"])
    }

    func testBattleTelemetrySequencesQueuedTextAcrossIntroAndTurns() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            winDialogueID: "win",
                            loseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: true,
                            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.start()
        RunLoop.current.run(until: Date().addingTimeInterval(1.7))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_1")

        var snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "introText")
        XCTAssertEqual(snapshot.textLines, [])
        XCTAssertEqual(snapshot.presentation.stage, .introFlash1)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)

        drainBattleText(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
        XCTAssertEqual(snapshot.moveSlots.map(\.displayName), ["SCRATCH"])
        XCTAssertEqual(snapshot.presentation.uiVisibility, .visible)

        runtime.battleRandomOverrides = [0, 255, 0]
        runtime.handle(button: .confirm)

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .attackWindup &&
                runtime.currentSnapshot().battle?.presentation.activeSide == .player,
            message: "player attack windup did not begin"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "turnText")
        XCTAssertEqual(snapshot.textLines, ["Charmander used SCRATCH!"])

        RunLoop.current.run(until: Date().addingTimeInterval(0.12))
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertFalse(
            snapshot.presentation.stage == .attackWindup &&
                snapshot.presentation.activeSide == .enemy &&
                snapshot.battleMessage == "Bulbasaur used GROWL!"
        )

        advanceBattlePresentationBatch(runtime)
        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .attackWindup &&
                runtime.currentSnapshot().battle?.presentation.activeSide == .enemy,
            message: "enemy attack windup did not begin after confirm"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.textLines, ["Bulbasaur used GROWL!"])

        waitUntil(
            runtime.currentSnapshot().battle?.battleMessage == "Charmander's Attack fell!",
            message: "enemy effect text did not appear"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.textLines, ["Charmander's Attack fell!"])

        advanceBattlePresentationBatch(runtime)
        waitUntil(
            runtime.currentSnapshot().battle?.phase == "moveSelection",
            message: "battle text did not drain to move selection"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
    }
}
