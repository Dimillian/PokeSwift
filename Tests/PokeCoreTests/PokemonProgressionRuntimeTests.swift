import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

private func fixtureEvolutionDialogues() -> [DialogueManifest] {
    [
        .init(id: "evolution_evolved", pages: [.init(lines: ["{pokemon} evolved"], waitsForPrompt: true)]),
        .init(
            id: "evolution_into",
            pages: [.init(
                lines: ["into {evolvedPokemon}!"],
                waitsForPrompt: true,
                events: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_2")]
            )]
        ),
        .init(id: "evolution_is_evolving", pages: [.init(lines: ["What? {pokemon}", "is evolving!"], waitsForPrompt: true)]),
        .init(id: "evolution_stopped", pages: [.init(lines: ["Huh? {pokemon}", "stopped evolving!"], waitsForPrompt: true)]),
    ]
}

@MainActor
extension PokeCoreTests {
    func testMakePokemonSeedsTotalExperienceFromGrowthRate() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.acquisitionRandomOverrides = [0xAB, 0xCD]
        let squirtle = runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")

        XCTAssertEqual(squirtle.experience, 135)
        XCTAssertEqual(squirtle.dvs, PokemonDVs(attack: 10, defense: 11, speed: 12, special: 13))
        XCTAssertEqual(squirtle.dvs.hp, 5)
        XCTAssertEqual(squirtle.statExp, .zero)
        XCTAssertEqual(squirtle.maxHP, 19)
        XCTAssertEqual(squirtle.attack, 10)
        XCTAssertEqual(squirtle.defense, 12)
        XCTAssertEqual(squirtle.speed, 10)
        XCTAssertEqual(squirtle.special, 11)
        XCTAssertEqual(runtime.experienceRequired(for: 6, speciesID: "SQUIRTLE"), 179)
    }
    func testPartyTelemetryPublishesCurrentStatsAndGrowthOutlook() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.acquisitionRandomOverrides = [0xAB, 0xCD]
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        let partyPokemon = try! XCTUnwrap(runtime.currentSnapshot().party?.pokemon.first)

        XCTAssertEqual(partyPokemon.maxHP, 19)
        XCTAssertEqual(partyPokemon.attack, 10)
        XCTAssertEqual(partyPokemon.defense, 12)
        XCTAssertEqual(partyPokemon.speed, 10)
        XCTAssertEqual(partyPokemon.special, 11)
        XCTAssertEqual(partyPokemon.moves, ["TACKLE"])
        XCTAssertEqual(partyPokemon.moveStates, [PartyMoveTelemetry(id: "TACKLE", currentPP: 35)])
        XCTAssertEqual(partyPokemon.growthOutlook.hp, .lagging)
        XCTAssertEqual(partyPokemon.growthOutlook.special, .favored)
        XCTAssertEqual(partyPokemon.growthOutlook.attack, .neutral)
    }

    func testPartyTelemetryGrowthOutlookStaysBoundToDVsWhenStatExpChanges() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.gameplayState?.playerParty = [
            runtime.makeConfiguredPokemon(
                speciesID: "CHARMANDER",
                nickname: "Charmander",
                level: 6,
                experience: 205,
                dvs: .init(attack: 15, defense: 2, speed: 11, special: 2),
                statExp: .init(hp: 44, attack: 48, defense: 65, speed: 43, special: 50),
                currentHP: 21,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                moves: nil
            )
        ]

        let partyPokemon = try! XCTUnwrap(runtime.currentSnapshot().party?.pokemon.first)

        XCTAssertEqual(partyPokemon.growthOutlook.attack, .favored)
        XCTAssertEqual(partyPokemon.growthOutlook.defense, .lagging)
        XCTAssertEqual(partyPokemon.growthOutlook.special, .lagging)
        XCTAssertEqual(partyPokemon.growthOutlook.hp, .neutral)
        XCTAssertEqual(partyPokemon.growthOutlook.speed, .neutral)
    }
    func testDerivedHPDVAndCeilSquareRootMatchGen1Behavior() {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)

        XCTAssertEqual(PokemonDVs(attack: 10, defense: 11, speed: 12, special: 13).hp, 5)
        XCTAssertEqual(runtime.ceilSquareRoot(of: 0), 0)
        XCTAssertEqual(runtime.ceilSquareRoot(of: 1), 1)
        XCTAssertEqual(runtime.ceilSquareRoot(of: 2), 2)
        XCTAssertEqual(runtime.ceilSquareRoot(of: 4), 2)
        XCTAssertEqual(runtime.ceilSquareRoot(of: 65_535), 255)
    }
    func testTrainerBattlePokemonUsesFixedTrainerDVs() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let squirtle = runtime.makeTrainerBattlePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")

        XCTAssertEqual(squirtle.dvs, PokemonDVs(attack: 9, defense: 8, speed: 8, special: 8))
        XCTAssertEqual(squirtle.statExp, .zero)
        XCTAssertEqual(squirtle.maxHP, 20)
        XCTAssertEqual(squirtle.attack, 10)
        XCTAssertEqual(squirtle.defense, 12)
        XCTAssertEqual(squirtle.speed, 10)
        XCTAssertEqual(squirtle.special, 10)
    }

    func testMakePokemonLearnsLevelAppropriateWildMovesOnSpawn() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["GUST"],
                            levelUpLearnset: [
                                .init(level: 5, moveID: "SAND_ATTACK"),
                                .init(level: 12, moveID: "QUICK_ATTACK"),
                            ]
                        ),
                    ],
                    moves: [
                        .init(id: "GUST", displayName: "GUST", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "FLYING"),
                        .init(id: "SAND_ATTACK", displayName: "SAND-ATTACK", power: 0, accuracy: 100, maxPP: 15, effect: "ACCURACY_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "QUICK_ATTACK", displayName: "QUICK ATTACK", power: 40, accuracy: 100, maxPP: 30, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let lowLevelPidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 4, nickname: "Pidgey")
        let route1LevelFivePidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 5, nickname: "Pidgey")

        XCTAssertEqual(lowLevelPidgey.moves.map(\.id), ["GUST"])
        XCTAssertEqual(route1LevelFivePidgey.moves.map(\.id), ["GUST", "SAND_ATTACK"])
    }

    func testSpawnedPokemonKeepLatestFourMovesFromLevelUpLearnset() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH", "GROWL"],
                            levelUpLearnset: [
                                .init(level: 9, moveID: "EMBER"),
                                .init(level: 15, moveID: "LEER"),
                                .init(level: 22, moveID: "RAGE"),
                                .init(level: 30, moveID: "SLASH"),
                            ]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "NO_ADDITIONAL_EFFECT", type: "FIRE"),
                        .init(id: "LEER", displayName: "LEER", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "RAGE", displayName: "RAGE", power: 20, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "SLASH", displayName: "SLASH", power: 70, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let charmander = runtime.makeTrainerBattlePokemon(speciesID: "CHARMANDER", level: 30, nickname: "Charmander")

        XCTAssertEqual(charmander.moves.map(\.id), ["EMBER", "LEER", "RAGE", "SLASH"])
    }

    func testBattleExperienceRewardLevelsUpStarterAndUpdatesTelemetry() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        var playerPokemon = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeatedPokemon,
            to: &playerPokemon,
            isTrainerBattle: true
        )
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [playerPokemon]

        let partyPokemon = try XCTUnwrap(runtime.currentSnapshot().party?.pokemon.first)
        XCTAssertEqual(partyPokemon.level, 6)
        XCTAssertEqual(partyPokemon.experience.total, 202)
        XCTAssertEqual(partyPokemon.experience.levelStart, 179)
        XCTAssertEqual(partyPokemon.experience.nextLevel, 236)
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertTrue(rewardResult.messages.contains("Charmander gained 67 EXP!"))
        XCTAssertTrue(rewardResult.messages.contains("Charmander grew to Lv6!"))
        XCTAssertNil(rewardResult.pendingLearnMove)
    }

    func testBattleExperienceRewardQueuesPendingLevelEvolution() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: fixtureEvolutionDialogues(),
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 65,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH"],
                            evolutions: [.init(trigger: .init(kind: .level, level: 16), targetSpeciesID: "CHARMELEON")]
                        ),
                        .init(
                            id: "CHARMELEON",
                            displayName: "Charmeleon",
                            primaryType: "FIRE",
                            baseExp: 142,
                            growthRate: .mediumSlow,
                            baseHP: 58,
                            baseAttack: 64,
                            baseDefense: 58,
                            baseSpeed: 80,
                            baseSpecial: 65,
                            startingMoves: ["SCRATCH"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseExp: 50,
                            growthRate: .mediumSlow,
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var playerPokemon = runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Blaze",
            level: 15,
            experience: runtime.experienceRequired(for: 16, speciesID: "CHARMANDER") - 1,
            dvs: .init(attack: 10, defense: 11, speed: 12, special: 13),
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "PIDGEY", level: 1, nickname: "Pidgey")

        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeatedPokemon,
            to: &playerPokemon,
            isTrainerBattle: false
        )

        XCTAssertEqual(playerPokemon.level, 16)
        XCTAssertEqual(rewardResult.pendingEvolution?.partyIndex, 0)
        XCTAssertEqual(rewardResult.pendingEvolution?.originalSpeciesID, "CHARMANDER")
        XCTAssertEqual(rewardResult.pendingEvolution?.targetSpeciesID, "CHARMELEON")
        XCTAssertNil(rewardResult.pendingLearnMove)
    }

    func testBattleExperienceRewardUsesOriginalSpeciesForTransformEvolution() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 65,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH"],
                            evolutions: [.init(trigger: .init(kind: .level, level: 16), targetSpeciesID: "CHARMELEON")]
                        ),
                        .init(
                            id: "CHARMELEON",
                            displayName: "Charmeleon",
                            primaryType: "FIRE",
                            baseExp: 142,
                            growthRate: .mediumSlow,
                            baseHP: 58,
                            baseAttack: 64,
                            baseDefense: 58,
                            baseSpeed: 80,
                            baseSpecial: 65,
                            startingMoves: ["SCRATCH"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseExp: 50,
                            growthRate: .mediumSlow,
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var playerPokemon = runtime.makeConfiguredPokemon(
            speciesID: "PIDGEY",
            nickname: "Blaze",
            level: 15,
            experience: runtime.experienceRequired(for: 16, speciesID: "CHARMANDER") - 1,
            dvs: .init(attack: 10, defense: 11, speed: 12, special: 13),
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        playerPokemon.battleEffects.transformedState = RuntimeTransformState(
            originalSpeciesID: "CHARMANDER",
            originalAttack: 20,
            originalDefense: 18,
            originalSpeed: 22,
            originalSpecial: 19,
            originalAttackStage: 0,
            originalDefenseStage: 0,
            originalSpeedStage: 0,
            originalSpecialStage: 0,
            originalAccuracyStage: 0,
            originalEvasionStage: 0,
            originalMoves: [RuntimeMoveState(id: "SCRATCH", currentPP: 35)]
        )
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "PIDGEY", level: 1, nickname: "Pidgey")

        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeatedPokemon,
            to: &playerPokemon,
            isTrainerBattle: false
        )

        XCTAssertEqual(rewardResult.pendingEvolution?.originalSpeciesID, "CHARMANDER")
        XCTAssertEqual(rewardResult.pendingEvolution?.targetSpeciesID, "CHARMELEON")
    }

    func testWildBattleWinBranchesIntoEvolutionSceneAndResumesFieldAfterCompletion() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: fixtureEvolutionDialogues(),
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 65,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH"],
                            evolutions: [.init(trigger: .init(kind: .level, level: 16), targetSpeciesID: "CHARMELEON")]
                        ),
                        .init(
                            id: "CHARMELEON",
                            displayName: "Charmeleon",
                            primaryType: "FIRE",
                            baseExp: 142,
                            growthRate: .mediumSlow,
                            baseHP: 58,
                            baseAttack: 64,
                            baseDefense: 58,
                            baseSpeed: 80,
                            baseSpecial: 65,
                            startingMoves: ["SCRATCH"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseExp: 50,
                            growthRate: .mediumSlow,
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"

        let startingPokemon = runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Blaze",
            level: 15,
            experience: runtime.experienceRequired(for: 16, speciesID: "CHARMANDER") - 1,
            dvs: .init(attack: 10, defense: 11, speed: 12, special: 13),
            statExp: .zero,
            currentHP: 28,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [startingPokemon]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 1)
        guard var battle = runtime.gameplayState?.battle else {
            XCTFail("Expected a wild battle")
            return
        }

        var rewardedPokemon = battle.playerPokemon
        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: battle.enemyPokemon,
            to: &rewardedPokemon,
            isTrainerBattle: false
        )
        battle.playerPokemon = rewardedPokemon
        battle.pendingEvolution = rewardResult.pendingEvolution
        runtime.gameplayState?.battle = battle

        let expectedEvolved = runtime.makeConfiguredPokemon(
            speciesID: "CHARMELEON",
            nickname: rewardedPokemon.nickname,
            level: rewardedPokemon.level,
            experience: rewardedPokemon.experience,
            dvs: rewardedPokemon.dvs,
            statExp: rewardedPokemon.statExp,
            currentHP: nil,
            attackStage: rewardedPokemon.attackStage,
            defenseStage: rewardedPokemon.defenseStage,
            speedStage: rewardedPokemon.speedStage,
            specialStage: rewardedPokemon.specialStage,
            accuracyStage: rewardedPokemon.accuracyStage,
            evasionStage: rewardedPokemon.evasionStage,
            majorStatus: rewardedPokemon.majorStatus,
            statusCounter: rewardedPokemon.statusCounter,
            isBadlyPoisoned: rewardedPokemon.isBadlyPoisoned,
            moves: rewardedPokemon.moves
        )
        let expectedCurrentHP = min(
            expectedEvolved.maxHP,
            max(0, rewardedPokemon.currentHP + (expectedEvolved.maxHP - rewardedPokemon.maxHP))
        )

        runtime.finishWildBattle(battle: battle, won: true)

        XCTAssertEqual(runtime.scene, .evolution)
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.phase, "intro")
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.textLines, ["What? Blaze", "is evolving!"])
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.animationStep, 0)
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.showsEvolvedSprite, false)
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.speciesID, "CHARMANDER")

        runtime.handle(button: .confirm)

        waitUntil(
            (runtime.currentEvolutionSceneState()?.animationStep ?? 0) > 0,
            message: "evolution animation did not begin alternating sprites",
            maxTicks: 180
        )
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.phase, "animating")

        waitUntil(
            runtime.currentEvolutionSceneState()?.phase == "evolved",
            message: "evolution did not finish animating",
            maxTicks: 900
        )

        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.speciesID, "CHARMELEON")
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.nickname, "Blaze")
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.currentHP, expectedCurrentHP)
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.textLines, ["Blaze evolved"])
        XCTAssertTrue(runtime.ownedSpeciesIDs.contains("CHARMELEON"))
        XCTAssertTrue(runtime.seenSpeciesIDs.contains("CHARMELEON"))

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.phase, "into")
        XCTAssertEqual(runtime.currentEvolutionSceneState()?.textLines, ["into Charmeleon!"])

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.substate, "field")
        XCTAssertNil(runtime.gameplayState?.battle)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")
    }

    func testEvolutionUpdatesDefaultSpeciesNicknameToEvolvedSpeciesName() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: fixtureEvolutionDialogues(),
                    species: [
                        .init(
                            id: "SQUIRTLE",
                            displayName: "Squirtle",
                            primaryType: "WATER",
                            baseExp: 66,
                            growthRate: .mediumSlow,
                            baseHP: 44,
                            baseAttack: 48,
                            baseDefense: 65,
                            baseSpeed: 43,
                            baseSpecial: 50,
                            startingMoves: ["TACKLE"],
                            evolutions: [.init(trigger: .init(kind: .level, level: 16), targetSpeciesID: "WARTORTLE")]
                        ),
                        .init(
                            id: "WARTORTLE",
                            displayName: "Wartortle",
                            primaryType: "WATER",
                            baseExp: 143,
                            growthRate: .mediumSlow,
                            baseHP: 59,
                            baseAttack: 63,
                            baseDefense: 80,
                            baseSpeed: 58,
                            baseSpecial: 65,
                            startingMoves: ["TACKLE"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseExp: 50,
                            growthRate: .mediumSlow,
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"
        runtime.gameplayState?.playerParty = [
            runtime.makeConfiguredPokemon(
                speciesID: "SQUIRTLE",
                nickname: "Squirtle",
                level: 15,
                experience: runtime.experienceRequired(for: 16, speciesID: "SQUIRTLE") - 1,
                dvs: .zero,
                statExp: .zero,
                currentHP: 30,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                moves: nil
            )
        ]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 1)
        guard var battle = runtime.gameplayState?.battle else {
            XCTFail("Expected a wild battle")
            return
        }

        var rewardedPokemon = battle.playerPokemon
        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: battle.enemyPokemon,
            to: &rewardedPokemon,
            isTrainerBattle: false
        )
        battle.playerPokemon = rewardedPokemon
        battle.pendingEvolution = rewardResult.pendingEvolution
        runtime.gameplayState?.battle = battle

        runtime.finishWildBattle(battle: battle, won: true)
        runtime.handle(button: .confirm)

        waitUntil(
            runtime.currentEvolutionSceneState()?.phase == "evolved",
            message: "default-name evolution did not finish animating",
            maxTicks: 900
        )

        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.speciesID, "WARTORTLE")
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.nickname, "Wartortle")
        XCTAssertTrue(runtime.ownedSpeciesIDs.contains("WARTORTLE"))
        XCTAssertTrue(runtime.seenSpeciesIDs.contains("WARTORTLE"))
    }
    func testBattleRewardAccumulatesStatExpWithoutVisibleStatRecalc() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseExp: 50, growthRate: .mediumSlow, baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 95, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        var playerPokemon = runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Charmander",
            level: 5,
            experience: 135,
            dvs: PokemonDVs(attack: 10, defense: 11, speed: 12, special: 13),
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "PIDGEY", level: 1, nickname: "Pidgey")
        let previousVisibleStats = (playerPokemon.maxHP, playerPokemon.attack, playerPokemon.defense, playerPokemon.speed, playerPokemon.special)

        let rewardResult = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 5)
        XCTAssertEqual(playerPokemon.experience, 145)
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 40, attack: 45, defense: 40, speed: 56, special: 35))
        XCTAssertEqual(playerPokemon.maxHP, previousVisibleStats.0)
        XCTAssertEqual(playerPokemon.attack, previousVisibleStats.1)
        XCTAssertEqual(playerPokemon.defense, previousVisibleStats.2)
        XCTAssertEqual(playerPokemon.speed, previousVisibleStats.3)
        XCTAssertEqual(playerPokemon.special, previousVisibleStats.4)
        XCTAssertEqual(rewardResult.messages, ["Charmander gained 10 EXP!"])
        XCTAssertNil(rewardResult.pendingLearnMove)
    }
    func testExperienceRewardRaisesCurrentHPByLevelUpDelta() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        var playerPokemon = runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Charmander",
            level: 5,
            experience: 135,
            dvs: PokemonDVs(attack: 10, defense: 11, speed: 12, special: 13),
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        playerPokemon.currentHP = max(1, playerPokemon.currentHP - 7)
        let hpBefore = playerPokemon.currentHP
        let previousMaxHP = playerPokemon.maxHP
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")

        let rewardResult = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 6)
        XCTAssertGreaterThan(playerPokemon.currentHP, hpBefore)
        XCTAssertEqual(playerPokemon.currentHP, hpBefore + (playerPokemon.maxHP - previousMaxHP))
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertTrue(rewardResult.messages.contains("Charmander gained 67 EXP!"))
        XCTAssertTrue(rewardResult.messages.contains("Charmander grew to Lv6!"))
        XCTAssertNil(rewardResult.pendingLearnMove)
    }
    func testLevel100PokemonStillGainsStatExpWhileExperienceStaysCapped() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        var playerPokemon = runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Charmander",
            level: 100,
            experience: runtime.maximumExperience(for: "CHARMANDER"),
            dvs: PokemonDVs(attack: 10, defense: 10, speed: 10, special: 10),
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")

        let rewardResult = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 100)
        XCTAssertEqual(playerPokemon.experience, runtime.maximumExperience(for: "CHARMANDER"))
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertEqual(rewardResult.messages, ["Charmander gained 67 EXP!"])
        XCTAssertNil(rewardResult.pendingLearnMove)
    }
    func testBattleExperienceRewardLearnsLevelUpMoveWhenOpenSlot() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 65,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH"],
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
                            baseSpeed: 45,
                            baseSpecial: 65,
                            startingMoves: ["GROWL"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "BURN_SIDE_EFFECT1", type: "FIRE"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var playerPokemon = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")

        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeatedPokemon,
            to: &playerPokemon,
            isTrainerBattle: true
        )

        XCTAssertEqual(playerPokemon.level, 6)
        XCTAssertEqual(playerPokemon.moves.map(\.id), ["SCRATCH", "EMBER"])
        XCTAssertEqual(playerPokemon.moves.last?.currentPP, 25)
        XCTAssertTrue(rewardResult.messages.contains("Charmander learned EMBER!"))
        XCTAssertNil(rewardResult.pendingLearnMove)
    }
    func testBattleExperienceRewardQueuesLearnPromptWhenMoveSlotsAreFull() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseExp: 65,
                            growthRate: .mediumSlow,
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH", "GROWL", "LEER", "CUT"],
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
                            baseSpeed: 45,
                            baseSpecial: 65,
                            startingMoves: ["GROWL"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "LEER", displayName: "LEER", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "CUT", displayName: "CUT", power: 50, accuracy: 95, maxPP: 30, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "BURN_SIDE_EFFECT1", type: "FIRE"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var playerPokemon = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        let originalMoves = playerPokemon.moves
        let defeatedPokemon = runtime.makeTrainerBattlePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")

        let rewardResult = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeatedPokemon,
            to: &playerPokemon,
            isTrainerBattle: true
        )

        XCTAssertEqual(playerPokemon.level, 6)
        XCTAssertEqual(playerPokemon.moves.map(\.id), originalMoves.map(\.id))
        XCTAssertEqual(rewardResult.pendingLearnMove?.moveID, "EMBER")
        XCTAssertTrue(rewardResult.messages.contains("Charmander is trying to learn EMBER!"))
        XCTAssertTrue(rewardResult.messages.contains("But Charmander can't learn more than 4 moves."))
    }
    func testLosingBattleDoesNotGrantExperience() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 10, baseDefense: 1, baseSpeed: 1, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 200, baseDefense: 49, baseSpeed: 65, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: "lose",
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
        runtime.gameplayState?.playerParty[0].currentHP = 1
        let startingExperience = runtime.gameplayState?.playerParty[0].experience

        runtime.startBattle(id: "opp_rival1_1")
        runtime.cancelBattlePresentation()
        runtime.gameplayState?.battle?.phase = .moveSelection
        runtime.gameplayState?.battle?.message = "Pick the next move."
        runtime.gameplayState?.battle?.queuedMessages = []
        runtime.gameplayState?.battle?.pendingAction = .moveSelection
        runtime.gameplayState?.battle?.pendingPresentationBatches = []
        runtime.gameplayState?.battle?.presentation = .init(
            stage: .commandReady,
            revision: 1,
            uiVisibility: .visible,
            activeSide: nil,
            transitionStyle: .none
        )

        runtime.battleRandomOverrides = [0, 255]
        var battle = try XCTUnwrap(runtime.gameplayState?.battle)
        let batches = runtime.makeTurnPresentationBatches(for: &battle)
        for batch in batches {
            for beat in batch {
                runtime.applyBattlePresentationBeat(beat, battleID: battle.battleID)
            }
        }

        XCTAssertEqual(runtime.currentSnapshot().party?.pokemon.first?.experience.total, startingExperience)
        XCTAssertEqual(runtime.currentSnapshot().party?.pokemon.first?.level, 5)
    }
}
