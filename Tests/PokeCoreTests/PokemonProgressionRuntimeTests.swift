import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
    func testMakePokemonSeedsTotalExperienceFromGrowthRate() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
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
    func testBattleExperienceRewardLevelsUpStarterAndUpdatesTelemetry() async throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseExp: 65, growthRate: .mediumSlow, baseHP: 39, baseAttack: 200, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["GROWL"]),
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
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)

        var battleSnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(battleSnapshot.textLines, ["Charmander used SCRATCH!"])

        var sawGainMessage = false
        var sawLevelMessage = false
        var remaining = 8
        while runtime.currentSnapshot().battle != nil {
            battleSnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
            sawGainMessage = sawGainMessage || battleSnapshot.textLines.contains(where: { $0.contains("gained 67 EXP") })
            sawLevelMessage = sawLevelMessage || battleSnapshot.textLines.contains(where: { $0.contains("grew to Lv6") })
            XCTAssertGreaterThan(remaining, 0)
            remaining -= 1
            runtime.handle(button: .confirm)
        }

        let partyPokemon = try XCTUnwrap(runtime.currentSnapshot().party?.pokemon.first)
        XCTAssertEqual(partyPokemon.level, 6)
        XCTAssertEqual(partyPokemon.experience.total, 202)
        XCTAssertEqual(partyPokemon.experience.levelStart, 179)
        XCTAssertEqual(partyPokemon.experience.nextLevel, 236)
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertTrue(sawGainMessage)
        XCTAssertTrue(sawLevelMessage)
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

        let messages = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 5)
        XCTAssertEqual(playerPokemon.experience, 145)
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 40, attack: 45, defense: 40, speed: 56, special: 35))
        XCTAssertEqual(playerPokemon.maxHP, previousVisibleStats.0)
        XCTAssertEqual(playerPokemon.attack, previousVisibleStats.1)
        XCTAssertEqual(playerPokemon.defense, previousVisibleStats.2)
        XCTAssertEqual(playerPokemon.speed, previousVisibleStats.3)
        XCTAssertEqual(playerPokemon.special, previousVisibleStats.4)
        XCTAssertEqual(messages, ["Charmander gained 10 EXP!"])
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

        let messages = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 6)
        XCTAssertGreaterThan(playerPokemon.currentHP, hpBefore)
        XCTAssertEqual(playerPokemon.currentHP, hpBefore + (playerPokemon.maxHP - previousMaxHP))
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertTrue(messages.contains("Charmander gained 67 EXP!"))
        XCTAssertTrue(messages.contains("Charmander grew to Lv6!"))
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

        let messages = runtime.applyBattleExperienceReward(defeatedPokemon: defeatedPokemon, to: &playerPokemon, isTrainerBattle: true)

        XCTAssertEqual(playerPokemon.level, 100)
        XCTAssertEqual(playerPokemon.experience, runtime.maximumExperience(for: "CHARMANDER"))
        XCTAssertEqual(playerPokemon.statExp, PokemonStatExp(hp: 45, attack: 49, defense: 49, speed: 45, special: 65))
        XCTAssertEqual(messages, ["Charmander gained 67 EXP!"])
    }
    func testLosingBattleDoesNotGrantExperience() async throws {
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
        runtime.gameplayState?.playerParty[0].currentHP = 1
        let startingExperience = runtime.gameplayState?.playerParty[0].experience

        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)

        var remaining = 8
        while runtime.currentSnapshot().battle != nil {
            XCTAssertGreaterThan(remaining, 0)
            remaining -= 1
            runtime.handle(button: .confirm)
        }

        XCTAssertEqual(runtime.currentSnapshot().party?.pokemon.first?.experience.total, startingExperience)
        XCTAssertEqual(runtime.currentSnapshot().party?.pokemon.first?.level, 5)
    }
}
