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
        runtime.handle(button: .down)

        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedMoveIndex, 2)

        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.currentSnapshot().battle, nil)
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
    func testBattleAdvancesAcrossExtractedEnemyParty() async {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 200, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 30, baseDefense: 49, baseSpeed: 1, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
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
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_2")
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPartyCount, 2)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyActiveIndex, 0)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "introText")

        drainBattleText(runtime)
        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
        drainBattleText(runtime)

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
    func testBattleTelemetrySequencesQueuedTextAcrossIntroAndTurns() async throws {
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
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_1")

        var snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "introText")
        XCTAssertEqual(snapshot.textLines, ["BLUE challenges you!"])

        runtime.handle(button: .confirm)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.textLines, ["BLUE sent out Bulbasaur!"])

        drainBattleText(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
        XCTAssertEqual(snapshot.moveSlots.map(\.displayName), ["SCRATCH"])

        runtime.battleRandomOverrides = [0, 255, 0]
        runtime.handle(button: .confirm)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "turnText")
        XCTAssertEqual(snapshot.textLines, ["Charmander used SCRATCH!"])

        runtime.handle(button: .confirm)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.textLines, ["Bulbasaur used GROWL!"])

        runtime.handle(button: .confirm)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.textLines, ["Charmander's Attack fell!"])

        drainBattleText(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
    }
}
