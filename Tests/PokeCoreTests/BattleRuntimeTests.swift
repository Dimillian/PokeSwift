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
        runtime.setBattleRandomOverrides([0, 0])
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .naming)
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 0)
        XCTAssertEqual(runtime.gameplayState?.playerParty.count, 2)
        XCTAssertEqual(runtime.gameplayState?.playerParty.last?.speciesID, "PIDGEY")
        XCTAssertTrue(runtime.gameplayState?.ownedSpeciesIDs.contains("PIDGEY") ?? false)

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.scene, .field)
    }

    func testWildBattleEncounterCountIncrementsOncePerEncounter() throws {
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

        XCTAssertEqual(runtime.gameplayState?.speciesEncounterCounts["PIDGEY"], 1)

        drainBattleText(runtime)
        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.setBattleRandomOverrides([0, 0])
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.gameplayState?.speciesEncounterCounts["PIDGEY"], 1)

        runtime.startWildBattle(speciesID: "PIDGEY", level: 4)
        XCTAssertEqual(runtime.gameplayState?.speciesEncounterCounts["PIDGEY"], 2)
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
        runtime.setBattleRandomOverrides([0, 0])
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
        XCTAssertEqual(
            runtime.currentSnapshot().battle?.battleMessage,
            runtime.paginatedBattleMessage("The #MON BOX is full! Can't use that item!").first
        )

        advanceBattleTextUntilMoveSelection(runtime)
        XCTAssertEqual(runtime.gameplayState?.boxedPokemon[0].pokemon.count, GameRuntime.storageBoxCapacity)
    }

    func testResolveCaptureResultProducesSourceStyleShakeBuckets() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "HARD", displayName: "Hard", catchRate: 45, baseHP: 40, baseAttack: 40, baseDefense: 40, baseSpeed: 40, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "MID", displayName: "Mid", catchRate: 100, baseHP: 40, baseAttack: 40, baseDefense: 40, baseSpeed: 40, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "SOFT", displayName: "Soft", catchRate: 200, baseHP: 40, baseAttack: 40, baseDefense: 40, baseSpeed: 40, baseSpecial: 40, startingMoves: ["TACKLE"]),
                    ],
                    items: [
                        .init(id: "POKE_BALL", displayName: "POKE BALL", price: 200, battleUse: .ball),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        let pokeBall = runtime.content.item(id: "POKE_BALL")!

        var zeroShake = runtime.makePokemon(speciesID: "HARD", level: 5, nickname: "Hard")
        zeroShake.currentHP = zeroShake.maxHP
        runtime.setBattleRandomOverrides([255])
        XCTAssertEqual(runtime.resolveCaptureResult(for: zeroShake, item: pokeBall), .failed(shakes: 0))

        var oneShake = runtime.makePokemon(speciesID: "MID", level: 5, nickname: "Mid")
        oneShake.currentHP = oneShake.maxHP
        runtime.setBattleRandomOverrides([255])
        XCTAssertEqual(runtime.resolveCaptureResult(for: oneShake, item: pokeBall), .failed(shakes: 1))

        var twoShake = runtime.makePokemon(speciesID: "MID", level: 5, nickname: "Mid")
        twoShake.currentHP = max(1, twoShake.maxHP / 4)
        runtime.setBattleRandomOverrides([255])
        XCTAssertEqual(runtime.resolveCaptureResult(for: twoShake, item: pokeBall), .failed(shakes: 2))

        var threeShake = runtime.makePokemon(speciesID: "SOFT", level: 5, nickname: "Soft")
        threeShake.currentHP = max(1, threeShake.maxHP / 4)
        runtime.setBattleRandomOverrides([255])
        XCTAssertEqual(runtime.resolveCaptureResult(for: threeShake, item: pokeBall), .failed(shakes: 3))
    }

    func testBattleSwitchSelectsReservePokemonAndReturnsToMoveSelection() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
        ]

        runtime.startWildBattle(speciesID: "RATTATA", level: 3)
        drainBattleText(runtime)

        let switchIndex = runtime.gameplayState.map { runtime.switchActionIndex(for: $0.battle!) } ?? 0
        for _ in 0..<switchIndex {
            runtime.handle(button: .down)
        }

        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedMoveIndex, switchIndex)

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedPartyIndex, 1)

        runtime.handle(button: .confirm)
        advanceBattleTextUntilMoveSelection(runtime)

        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "moveSelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.playerPokemon.displayName, "Wing")
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.speciesID, "PIDGEY")
    }

    func testBattleSwitchRejectsActiveAndFaintedPokemon() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
            runtime.makePokemon(speciesID: "RATTATA", level: 4, nickname: "Fang"),
        ]
        runtime.gameplayState?.playerParty[2].currentHP = 0

        runtime.startWildBattle(speciesID: "RATTATA", level: 3)
        drainBattleText(runtime)

        let switchIndex = runtime.gameplayState.map { runtime.switchActionIndex(for: $0.battle!) } ?? 0
        for _ in 0..<switchIndex {
            runtime.handle(button: .down)
        }

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedPartyIndex, 1)

        runtime.handlePartySidebarSelection(0)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "Lead is already out!")

        runtime.handlePartySidebarSelection(2)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "There's no will to battle!")
    }

    func testBattleSwitchKnockoutWithHealthyReserveRequiresReplacementWithoutExtraEnemyTurn() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "LEAD", displayName: "Lead", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                        .init(id: "SWAP", displayName: "Swap", baseHP: 35, baseAttack: 30, baseDefense: 30, baseSpeed: 45, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "BACKUP", displayName: "Backup", baseHP: 50, baseAttack: 40, baseDefense: 40, baseSpeed: 40, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "ENEMY", displayName: "Enemy", baseHP: 50, baseAttack: 200, baseDefense: 40, baseSpeed: 30, baseSpecial: 40, startingMoves: ["SLAM"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "SLAM", displayName: "SLAM", power: 500, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "LEAD", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "SWAP", level: 5, nickname: "Swap"),
            runtime.makePokemon(speciesID: "BACKUP", level: 5, nickname: "Backup"),
        ]
        runtime.gameplayState?.playerParty[1].currentHP = 1

        runtime.startWildBattle(speciesID: "ENEMY", level: 5)
        drainBattleText(runtime)

        let switchIndex = runtime.gameplayState.map { runtime.switchActionIndex(for: $0.battle!) } ?? 0
        for _ in 0..<switchIndex {
            runtime.handle(button: .down)
        }

        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        advanceBattleUntilPhase(runtime, phase: "partySelection")

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedPartyIndex, 1)
        XCTAssertEqual(runtime.currentSnapshot().battle?.playerPokemon.currentHP, 0)

        runtime.handle(button: .cancel)
        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "partySelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "Bring out which #MON?")

        let replacementHP = runtime.gameplayState?.playerParty[1].currentHP
        runtime.handle(button: .confirm)
        advanceBattleTextUntilMoveSelection(runtime)

        XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "moveSelection")
        XCTAssertEqual(runtime.currentSnapshot().battle?.playerPokemon.displayName, "Lead")
        XCTAssertEqual(runtime.currentSnapshot().battle?.playerPokemon.currentHP, replacementHP)
    }

    func testBattleTelemetryHidesSwitchWhenNoReservePokemonCanBattle() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
        ]
        runtime.gameplayState?.playerParty[1].currentHP = 0

        runtime.startWildBattle(speciesID: "RATTATA", level: 3)
        drainBattleText(runtime)

        let snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertFalse(snapshot.canSwitch)
        XCTAssertTrue(snapshot.canRun)
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

    func testTrainerBattleIntroUsesSourceStyleWantsToFightAndSendOutCadence() throws {
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

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introReveal &&
                runtime.currentSnapshot().battle?.battleMessage == "BLUE wants to fight!",
            message: "trainer intro text did not appear",
            maxTicks: 240
        )

        advanceBattlePresentationBatch(runtime)
        waitUntil(
            runtime.currentSnapshot().battle?.battleMessage == "BLUE sent out Squirtle!",
            message: "enemy send out text did not appear",
            maxTicks: 240
        )

        advanceBattlePresentationBatch(runtime)
        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .enemySendOut &&
                runtime.currentSnapshot().battle?.presentation.activeSide == .player,
            message: "player send out presentation did not appear",
            maxTicks: 240
        )
        let playerSendOutSnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(playerSendOutSnapshot.battleMessage, "Go!")

        waitUntil(
            runtime.battlePresentationTask == nil,
            message: "player send out presentation did not settle",
            maxTicks: 240
        )
        runtime.handle(button: .confirm)
        waitUntil(
            runtime.currentSnapshot().battle?.phase == "moveSelection",
            message: "trainer intro did not resolve to move selection",
            maxTicks: 240
        )
    }

    func testTrainerEngagementShowsFieldIntroDialogueBeforeBattleTransition() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(
                            id: "trainer_intro",
                            pages: [.init(lines: ["I like shorts!"], waitsForPrompt: true)]
                        ),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_youngster_1",
                            trainerClass: "OPP_YOUNGSTER",
                            trainerNumber: 1,
                            displayName: "YOUNGSTER",
                            party: [.init(speciesID: "RATTATA", level: 5)],
                            trainerSpritePath: "Assets/battle/trainers/youngster.png",
                            baseRewardMoney: 1500,
                            playerWinDialogueID: "trainer_intro",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.gameplayState?.objectStates["trainer_1"] = RuntimeObjectState(
            position: .init(x: 4, y: 2),
            facing: .down,
            visible: true
        )

        runtime.startTrainerEngagement(
            objectID: "trainer_1",
            battleID: "opp_youngster_1",
            introDialogueID: "trainer_intro",
            path: []
        )

        waitUntil(
            runtime.currentSnapshot().dialogue?.dialogueID == "trainer_intro",
            message: "trainer engagement did not show the field intro dialogue",
            maxTicks: 240
        )
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertNil(runtime.currentSnapshot().battle)

        runtime.handle(button: .confirm)

        waitUntil(
            runtime.currentSnapshot().battle?.battleID == "opp_youngster_1",
            message: "trainer encounter did not start the battle after confirming the field intro",
            maxTicks: 240
        )
        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introReveal,
            message: "trainer battle did not reach the opening reveal after the field intro",
            maxTicks: 240
        )
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "YOUNGSTER wants to fight!")
    }

    func testTrainerLossDoesNotSetCompletionFlag() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "CATERPIE", displayName: "Caterpie", baseHP: 45, baseAttack: 30, baseDefense: 35, baseSpeed: 45, baseSpecial: 20, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    maps: [
                        .init(
                            id: "VIRIDIAN_POKECENTER",
                            displayName: "Viridian Pokecenter",
                            defaultMusicID: "MUSIC_CITIES1",
                            borderBlockID: 0,
                            blockWidth: 2,
                            blockHeight: 2,
                            stepWidth: 8,
                            stepHeight: 8,
                            tileset: "POKECENTER",
                            blockIDs: Array(repeating: 0, count: 4),
                            stepCollisionTileIDs: Array(repeating: 1, count: 64),
                            warps: [
                                .init(
                                    id: "viridian_pokecenter_warp_0",
                                    origin: .init(x: 3, y: 7),
                                    targetMapID: "VIRIDIAN_CITY",
                                    targetPosition: .init(x: 23, y: 25),
                                    targetFacing: .down
                                ),
                            ],
                            backgroundEvents: [],
                            objects: []
                        ),
                    ],
                    tilesets: [
                        .init(
                            id: "POKECENTER",
                            imagePath: "Assets/field/tilesets/pokecenter.png",
                            blocksetPath: "Assets/field/blocksets/pokecenter.bst",
                            sourceTileSize: 8,
                            blockTileWidth: 4,
                            blockTileHeight: 4,
                            collision: .init(
                                passableTileIDs: [1],
                                warpTileIDs: [],
                                doorTileIDs: [],
                                tilePairCollisions: [],
                                ledges: []
                            )
                        ),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_bug_catcher_1",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [.init(speciesID: "CATERPIE", level: 6)],
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
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

        runtime.startBattle(id: "opp_bug_catcher_1")
        let battle = runtime.gameplayState?.battle

        XCTAssertNotNil(battle)
        if let battle {
            runtime.finishBattle(battle: battle, won: false)
        }

        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_TEST") ?? true)
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
        advanceBattleUntilPhase(runtime, phase: "trainerAboutToUseDecision")
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        advanceBattleUntilPhase(runtime, phase: "moveSelection")

        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyActiveIndex, 1)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPartyCount, 2)
    }

    func testTrainerAboutToUsePromptTransitionsDirectlyIntoDecisionUI() throws {
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
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_2")
        drainBattleText(runtime)

        var battle = try XCTUnwrap(runtime.gameplayState?.battle)
        battle.rewardContinuation = .aboutToUse(index: 1, previousMoveIndex: 0)
        runtime.resumeRewardContinuation(battle: &battle)

        XCTAssertEqual(battle.phase, .turnText)
        XCTAssertEqual(battle.message, "BLUE is about to\nuse Squirtle!")
        XCTAssertEqual(battle.queuedMessages, [])
        guard case let .enterTrainerAboutToUseDecision(nextIndex)? = battle.pendingAction else {
            return XCTFail("trainer switch prompt did not queue the decision transition")
        }
        XCTAssertEqual(nextIndex, 1)

        runtime.advanceBattleText(battle: &battle)
        XCTAssertEqual(battle.phase, .trainerAboutToUseDecision)
        XCTAssertEqual(battle.message, "Will RED change\n#MON?")
        XCTAssertEqual(battle.focusedMoveIndex, 1)
    }

    func testTrainerAboutToUseNoKeepsPlayerVisibleAndRestoresMoveCursor() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH", "GROWL", "LEER"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            baseHP: 40,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["TACKLE"]
                        ),
                        .init(
                            id: "RATTATA",
                            displayName: "Rattata",
                            baseHP: 30,
                            baseAttack: 56,
                            baseDefense: 35,
                            baseSpeed: 72,
                            baseSpecial: 25,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "LEER", displayName: "LEER", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_test_trainer",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [
                                .init(speciesID: "PIDGEY", level: 5),
                                .init(speciesID: "RATTATA", level: 5),
                            ],
                            trainerSpritePath: "Assets/battle/trainers/bugcatcher.png",
                            baseRewardMoney: 10,
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
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

        runtime.startBattle(id: "opp_test_trainer")
        drainBattleText(runtime)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        XCTAssertEqual(runtime.currentSnapshot().battle?.focusedMoveIndex, 2)

        var gameplayState = try XCTUnwrap(runtime.gameplayState)
        var battle = try XCTUnwrap(gameplayState.battle)
        runtime.enterTrainerAboutToUseDecision(battle: &battle, nextIndex: 1)
        gameplayState.battle = battle
        runtime.gameplayState = gameplayState

        runtime.handle(button: .confirm)

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .enemySendOut &&
                runtime.currentSnapshot().battle?.presentation.activeSide == .enemy,
            message: "trainer did not start the next enemy send out after choosing no",
            maxTicks: 240
        )

        var snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertFalse(snapshot.presentation.hidePlayerPokemon)

        waitUntil(
            runtime.battlePresentationTask == nil,
            message: "enemy send out did not settle after choosing no",
            maxTicks: 240
        )

        runtime.handle(button: .confirm)
        waitUntil(
            runtime.currentSnapshot().battle?.phase == "moveSelection",
            message: "battle did not return to move selection after choosing no",
            maxTicks: 240
        )

        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.focusedMoveIndex, 2)
    }

    func testExperienceAndLevelUpMessagesRequireConfirm() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(
                            id: "SQUIRTLE",
                            displayName: "Squirtle",
                            growthRate: .mediumSlow,
                            baseHP: 44,
                            baseAttack: 48,
                            baseDefense: 65,
                            baseSpeed: 43,
                            baseSpecial: 50,
                            startingMoves: ["TACKLE"]
                        ),
                        .init(
                            id: "CATERPIE",
                            displayName: "Caterpie",
                            baseExp: 255,
                            growthRate: .mediumFast,
                            baseHP: 45,
                            baseAttack: 30,
                            baseDefense: 35,
                            baseSpeed: 45,
                            baseSpecial: 20,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_bug_catcher_1",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [.init(speciesID: "CATERPIE", level: 30)],
                            trainerSpritePath: "Assets/battle/trainers/bugcatcher.png",
                            baseRewardMoney: 10,
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
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

        runtime.startBattle(id: "opp_bug_catcher_1")

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        let resolution = runtime.makeEnemyDefeatResolution(
            battle: battle,
            defeatedEnemy: battle.enemyPokemon,
            playerPokemon: battle.playerPokemon
        )

        XCTAssertEqual(resolution.beats.first?.stage, .experience)
        XCTAssertEqual(resolution.beats.first?.requiresConfirmAfterDisplay, true)
        XCTAssertTrue(
            resolution.beats.contains(where: {
                $0.stage == .levelUp && $0.requiresConfirmAfterDisplay
            })
        )
    }

    func testTrainerVictoryAwardsMoneyAfterWinningTextResolves() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseExp: 66, growthRate: .mediumSlow, baseHP: 44, baseAttack: 255, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "CATERPIE", displayName: "Caterpie", baseExp: 53, growthRate: .mediumFast, baseHP: 45, baseAttack: 30, baseDefense: 35, baseSpeed: 45, baseSpecial: 20, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 500, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_bug_catcher_1",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [.init(speciesID: "CATERPIE", level: 6)],
                            trainerSpritePath: "Assets/battle/trainers/bugcatcher.png",
                            baseRewardMoney: 10,
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.gameplayState?.money = 3000
        runtime.scene = .battle
        runtime.substate = "battle"

        var battle = RuntimeBattleState(
            battleID: "opp_bug_catcher_1",
            kind: .trainer,
            trainerName: "BUG CATCHER",
            trainerSpritePath: "Assets/battle/trainers/bugcatcher.png",
            baseRewardMoney: 10,
            completionFlagID: "EVENT_TEST",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "win",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: false,
            trainerClass: "OPP_BUG_CATCHER",
            sourceTrainerObjectID: nil,
            playerPokemon: runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle"),
            enemyParty: [runtime.makePokemon(speciesID: "CATERPIE", level: 6, nickname: "Caterpie")],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .turnText,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )
        runtime.presentBattleMessages(
            [
                runtime.trainerDefeatedText(trainerName: "BUG CATCHER"),
                runtime.moneyForWinningText(amount: 60),
            ],
            battle: &battle,
            pendingAction: RuntimeBattlePendingAction.completeTrainerVictory(payout: 60)
        )
        runtime.gameplayState?.battle = battle

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "RED got ¥60 for\nwinning!")
        XCTAssertEqual(runtime.playerMoney, 3000)

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.playerMoney, 3060)
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

    func testBattleActionResultMessagesRequireConfirm() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["EMBER"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "NO_ADDITIONAL_EFFECT", type: "FIRE"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    typeEffectiveness: [
                        .init(attackingType: "FIRE", defendingType: "GRASS", multiplier: 20),
                        .init(attackingType: "FIRE", defendingType: "POISON", multiplier: 10),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let attacker = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")
        let defender = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        runtime.battleRandomOverrides = [0, 255]
        let action = runtime.resolveBattleAction(
            side: .player,
            attacker: attacker,
            defender: defender,
            moveIndex: 0,
            defenderCanActLaterInTurn: true
        )

        let beats = runtime.makeBeats(for: action)
        XCTAssertEqual(beats.first?.message, "Charmander used EMBER!")
        XCTAssertEqual(beats.first?.requiresConfirmAfterDisplay, false)
        XCTAssertTrue(
            beats.contains(where: {
                $0.message == "It's super effective!" && $0.requiresConfirmAfterDisplay
            })
        )
    }

    func testSpecialStageChangesOnlySpecialDamageProjection() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", primaryType: "FIRE", baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["EMBER", "SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "NO_ADDITIONAL_EFFECT", type: "FIRE"),
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    typeEffectiveness: [
                        .init(attackingType: "FIRE", defendingType: "GRASS", multiplier: 20),
                        .init(attackingType: "FIRE", defendingType: "POISON", multiplier: 10),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let ember = try! XCTUnwrap(runtime.content.move(id: "EMBER"))
        let scratch = try! XCTUnwrap(runtime.content.move(id: "SCRATCH"))
        let defender = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        let neutralAttacker = runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")

        var stagedAttacker = neutralAttacker
        stagedAttacker.specialStage = 2

        XCTAssertGreaterThan(
            runtime.projectedDamage(move: ember, attacker: stagedAttacker, defender: defender),
            runtime.projectedDamage(move: ember, attacker: neutralAttacker, defender: defender)
        )
        XCTAssertEqual(
            runtime.projectedDamage(move: scratch, attacker: stagedAttacker, defender: defender),
            runtime.projectedDamage(move: scratch, attacker: neutralAttacker, defender: defender)
        )
    }

    func testSleepEffectPreventsTurnAndWakeConsumesTurn() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "ODDISH", displayName: "Oddish", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 50, baseDefense: 55, baseSpeed: 30, baseSpecial: 75, startingMoves: ["SLEEP_POWDER"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SLEEP_POWDER", displayName: "SLEEP POWDER", power: 0, accuracy: 75, maxPP: 15, effect: "SLEEP_EFFECT", type: "GRASS"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var oddish = runtime.makePokemon(speciesID: "ODDISH", level: 10, nickname: "Oddish")
        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 10, nickname: "Pidgey")

        runtime.battleRandomOverrides = [0, 3]
        let result = runtime.applyMove(attacker: &oddish, defender: &pidgey, moveIndex: 0)

        XCTAssertEqual(pidgey.majorStatus, .sleep)
        XCTAssertEqual(pidgey.statusCounter, 3)
        XCTAssertTrue(result.messages.contains("Pidgey fell asleep!"))

        let sleepingAction = runtime.resolveBattleAction(
            side: .enemy,
            attacker: pidgey,
            defender: oddish,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertFalse(sleepingAction.didExecuteMove)
        XCTAssertEqual(sleepingAction.messages, ["Pidgey is fast asleep!"])

        var wakingPidgey = pidgey
        wakingPidgey.statusCounter = 1
        let wakingAction = runtime.resolveBattleAction(
            side: .enemy,
            attacker: wakingPidgey,
            defender: oddish,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertFalse(wakingAction.didExecuteMove)
        XCTAssertEqual(wakingAction.updatedAttacker.majorStatus, .none)
        XCTAssertEqual(wakingAction.updatedAttacker.statusCounter, 0)
        XCTAssertEqual(wakingAction.messages, ["Pidgey woke up!"])
    }

    func testHazeCuresTargetSleepSkipsItsLaterTurnAndClearsBadPoisonFlag() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "KOFFING", displayName: "Koffing", primaryType: "POISON", baseHP: 40, baseAttack: 65, baseDefense: 95, baseSpeed: 35, baseSpecial: 60, startingMoves: ["HAZE"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "HAZE", displayName: "HAZE", power: 0, accuracy: 100, maxPP: 30, effect: "HAZE_EFFECT", type: "ICE"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var koffing = runtime.makePokemon(speciesID: "KOFFING", level: 18, nickname: "Koffing")
        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 18, nickname: "Pidgey")
        koffing.majorStatus = .poison
        koffing.isBadlyPoisoned = true
        koffing.battleEffects.toxicCounter = 3
        pidgey.majorStatus = .sleep
        pidgey.statusCounter = 2

        let hazeResult = runtime.applyMove(
            attacker: &koffing,
            defender: &pidgey,
            moveIndex: 0,
            defenderCanActLaterInTurn: true
        )

        XCTAssertEqual(hazeResult.messages, ["Koffing used HAZE!", "All status changes were eliminated!"])
        XCTAssertEqual(koffing.majorStatus, .poison)
        XCTAssertFalse(koffing.isBadlyPoisoned)
        XCTAssertEqual(koffing.battleEffects.toxicCounter, 0)
        XCTAssertEqual(pidgey.majorStatus, .none)
        XCTAssertEqual(pidgey.statusCounter, 0)
        XCTAssertTrue(pidgey.battleEffects.skipTurnOnce)

        let skippedTurn = runtime.resolveBattleAction(
            side: .enemy,
            attacker: pidgey,
            defender: koffing,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )

        XCTAssertFalse(skippedTurn.didExecuteMove)
        XCTAssertEqual(skippedTurn.messages, [])
        XCTAssertFalse(skippedTurn.updatedAttacker.battleEffects.skipTurnOnce)
    }

    func testDisableBlocksSelectedMoveUntilCounterExpires() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "GASTLY", displayName: "Gastly", primaryType: "GHOST", secondaryType: "POISON", baseHP: 30, baseAttack: 35, baseDefense: 30, baseSpeed: 80, baseSpecial: 100, startingMoves: ["DISABLE"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "DISABLE", displayName: "DISABLE", power: 0, accuracy: 55, maxPP: 20, effect: "DISABLE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var gastly = runtime.makePokemon(speciesID: "GASTLY", level: 10, nickname: "Gastly")
        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 10, nickname: "Pidgey")

        runtime.battleRandomOverrides = [0, 0, 2]
        let result = runtime.applyMove(attacker: &gastly, defender: &pidgey, moveIndex: 0)
        XCTAssertEqual(result.messages, ["Gastly used DISABLE!", "TACKLE was disabled!"])
        XCTAssertEqual(pidgey.battleEffects.disabledMoveID, "TACKLE")
        XCTAssertEqual(pidgey.battleEffects.disabledTurnsRemaining, 3)

        let blockedAction = runtime.resolveBattleAction(
            side: .enemy,
            attacker: pidgey,
            defender: gastly,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertFalse(blockedAction.didExecuteMove)
        XCTAssertEqual(blockedAction.messages, ["TACKLE is disabled!"])

        var expiringPidgey = pidgey
        expiringPidgey.battleEffects.disabledTurnsRemaining = 1
        let expiryAction = runtime.resolveBattleAction(
            side: .enemy,
            attacker: expiringPidgey,
            defender: gastly,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertTrue(expiryAction.didExecuteMove)
        XCTAssertEqual(expiryAction.updatedAttacker.battleEffects.disabledTurnsRemaining, 0)
        XCTAssertNil(expiryAction.updatedAttacker.battleEffects.disabledMoveID)
        XCTAssertEqual(
            expiryAction.messages.prefix(2),
            ["Pidgey's disabled move is no longer disabled!", "Pidgey used TACKLE!"]
        )
    }

    func testPreparePokemonForTurnExpiredDisabledMoveDoesNotBlockAction() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                        .init(id: "GASTLY", displayName: "Gastly", primaryType: "GHOST", secondaryType: "POISON", baseHP: 30, baseAttack: 35, baseDefense: 30, baseSpeed: 80, baseSpecial: 100, startingMoves: ["LICK"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "LICK", displayName: "LICK", power: 20, accuracy: 100, maxPP: 30, effect: "NO_ADDITIONAL_EFFECT", type: "GHOST"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 10, nickname: "Pidgey")
        let gastly = runtime.makePokemon(speciesID: "GASTLY", level: 10, nickname: "Gastly")
        pidgey.battleEffects.disabledMoveID = "TACKLE"
        pidgey.battleEffects.disabledTurnsRemaining = 1

        let preparation = runtime.preparePokemonForTurn(
            pokemon: &pidgey,
            opponent: gastly,
            selectedMoveIndex: 0
        )

        XCTAssertTrue(preparation.canAct)
        XCTAssertEqual(preparation.messages, ["Pidgey's disabled move is no longer disabled!"])
        XCTAssertEqual(pidgey.battleEffects.disabledTurnsRemaining, 0)
        XCTAssertNil(pidgey.battleEffects.disabledMoveID)
    }

    func testPreparePokemonForTurnConfusionSelfHitClearsForcedMultiTurnState() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SLOWBRO", displayName: "Slowbro", primaryType: "WATER", secondaryType: "PSYCHIC_TYPE", baseHP: 95, baseAttack: 75, baseDefense: 110, baseSpeed: 30, baseSpecial: 80, startingMoves: ["TACKLE"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 75, baseAttack: 50, baseDefense: 55, baseSpeed: 40, baseSpecial: 45, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var slowbro = runtime.makePokemon(speciesID: "SLOWBRO", level: 18, nickname: "Slowbro")
        let target = runtime.makePokemon(speciesID: "TARGET", level: 18, nickname: "Target")
        slowbro.battleEffects.confusionTurnsRemaining = 2
        slowbro.battleEffects.bideTurnsRemaining = 2
        slowbro.battleEffects.pendingBideDamage = 12
        slowbro.battleEffects.bideAccumulatedDamage = 12
        slowbro.battleEffects.thrashTurnsRemaining = 1
        slowbro.battleEffects.thrashMoveID = "TACKLE"
        slowbro.battleEffects.chargingMoveID = "DIG"
        slowbro.battleEffects.isInvulnerable = true
        slowbro.battleEffects.trappingTurnsRemaining = 2
        slowbro.battleEffects.trappingMoveID = "BIND"
        slowbro.battleEffects.trappingDamage = 7

        runtime.battleRandomOverrides = [128]
        let preparation = runtime.preparePokemonForTurn(
            pokemon: &slowbro,
            opponent: target,
            selectedMoveIndex: 0
        )

        XCTAssertFalse(preparation.canAct)
        XCTAssertEqual(preparation.messages, ["Slowbro is confused!", "It hurt itself in its confusion!"])
        XCTAssertEqual(slowbro.battleEffects.confusionTurnsRemaining, 1)
        XCTAssertEqual(slowbro.battleEffects.bideTurnsRemaining, 0)
        XCTAssertNil(slowbro.battleEffects.pendingBideDamage)
        XCTAssertEqual(slowbro.battleEffects.bideAccumulatedDamage, 0)
        XCTAssertEqual(slowbro.battleEffects.thrashTurnsRemaining, 0)
        XCTAssertNil(slowbro.battleEffects.thrashMoveID)
        XCTAssertNil(slowbro.battleEffects.chargingMoveID)
        XCTAssertFalse(slowbro.battleEffects.isInvulnerable)
        XCTAssertEqual(slowbro.battleEffects.trappingTurnsRemaining, 0)
        XCTAssertNil(slowbro.battleEffects.trappingMoveID)
        XCTAssertEqual(slowbro.battleEffects.trappingDamage, 0)
    }

    func testApplyMoveEffectFailsAgainstSubstituteForOpponentStatDropMove() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["GROWL"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 10, nickname: "Pidgey")
        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")
        rattata.battleEffects.hasSubstitute = true
        rattata.battleEffects.substituteHP = 10
        var pendingAction: RuntimeBattlePendingAction?
        let growl = try XCTUnwrap(runtime.content.move(id: "GROWL"))

        let messages = runtime.applyMoveEffect(
            growl,
            moveIndex: 0,
            dealtDamage: 0,
            attacker: &pidgey,
            defender: &rattata,
            defenderCanActLaterInTurn: false,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, ["But it failed!"])
        XCTAssertEqual(rattata.attackStage, 0)
        XCTAssertNil(pendingAction)
    }

    func testApplyMoveEffectFailsAgainstMistForOpponentStatDropMove() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TAIL_WHIP"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TAIL_WHIP", displayName: "TAIL WHIP", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 10, nickname: "Pidgey")
        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")
        rattata.battleEffects.isProtectedByMist = true
        var pendingAction: RuntimeBattlePendingAction?
        let tailWhip = try XCTUnwrap(runtime.content.move(id: "TAIL_WHIP"))

        let messages = runtime.applyMoveEffect(
            tailWhip,
            moveIndex: 0,
            dealtDamage: 0,
            attacker: &pidgey,
            defender: &rattata,
            defenderCanActLaterInTurn: false,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, ["But it failed!"])
        XCTAssertEqual(rattata.defenseStage, 0)
        XCTAssertNil(pendingAction)
    }

    func testApplyMoveEffectSleepOverridesExistingStatusWhenTargetNeedsRecharge() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "JIGGLYPUFF", displayName: "Jigglypuff", primaryType: "NORMAL", baseHP: 115, baseAttack: 45, baseDefense: 20, baseSpeed: 20, baseSpecial: 25, startingMoves: ["SING"]),
                        .init(id: "SNORLAX", displayName: "Snorlax", primaryType: "NORMAL", baseHP: 160, baseAttack: 110, baseDefense: 65, baseSpeed: 30, baseSpecial: 65, startingMoves: ["HYPER_BEAM"]),
                    ],
                    moves: [
                        .init(id: "SING", displayName: "SING", power: 0, accuracy: 55, maxPP: 15, effect: "SLEEP_EFFECT", type: "NORMAL"),
                        .init(id: "HYPER_BEAM", displayName: "HYPER BEAM", power: 150, accuracy: 90, maxPP: 5, effect: "HYPER_BEAM_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var jigglypuff = runtime.makePokemon(speciesID: "JIGGLYPUFF", level: 20, nickname: "Jigglypuff")
        var snorlax = runtime.makePokemon(speciesID: "SNORLAX", level: 20, nickname: "Snorlax")
        snorlax.majorStatus = .burn
        snorlax.battleEffects.needsRecharge = true
        var pendingAction: RuntimeBattlePendingAction?
        let sing = try XCTUnwrap(runtime.content.move(id: "SING"))

        runtime.battleRandomOverrides = [3]
        let messages = runtime.applyMoveEffect(
            sing,
            moveIndex: 0,
            dealtDamage: 0,
            attacker: &jigglypuff,
            defender: &snorlax,
            defenderCanActLaterInTurn: false,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, ["Snorlax fell asleep!"])
        XCTAssertEqual(snorlax.majorStatus, .sleep)
        XCTAssertEqual(snorlax.statusCounter, 3)
        XCTAssertFalse(snorlax.battleEffects.needsRecharge)
        XCTAssertNil(pendingAction)
    }

    func testApplyMoveEffectParalyzeDirectMoveCanHitMatchingType() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "ARBOK", displayName: "Arbok", primaryType: "POISON", baseHP: 60, baseAttack: 95, baseDefense: 69, baseSpeed: 80, baseSpecial: 65, startingMoves: ["GLARE"]),
                        .init(id: "CHANSEY", displayName: "Chansey", primaryType: "NORMAL", baseHP: 250, baseAttack: 5, baseDefense: 5, baseSpeed: 50, baseSpecial: 105, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "GLARE", displayName: "GLARE", power: 0, accuracy: 75, maxPP: 30, effect: "PARALYZE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var arbok = runtime.makePokemon(speciesID: "ARBOK", level: 25, nickname: "Arbok")
        var chansey = runtime.makePokemon(speciesID: "CHANSEY", level: 25, nickname: "Chansey")
        var pendingAction: RuntimeBattlePendingAction?
        let glare = try XCTUnwrap(runtime.content.move(id: "GLARE"))

        let messages = runtime.applyMoveEffect(
            glare,
            moveIndex: 0,
            dealtDamage: 0,
            attacker: &arbok,
            defender: &chansey,
            defenderCanActLaterInTurn: false,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, ["Chansey may not attack!"])
        XCTAssertEqual(chansey.majorStatus, .paralysis)
        XCTAssertNil(pendingAction)
    }

    func testApplyMoveEffectParalyzeSideEffectRespectsSameTypeImmunity() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SNORLAX", displayName: "Snorlax", primaryType: "NORMAL", baseHP: 160, baseAttack: 110, baseDefense: 65, baseSpeed: 30, baseSpecial: 65, startingMoves: ["BODY_SLAM"]),
                        .init(id: "CHANSEY", displayName: "Chansey", primaryType: "NORMAL", baseHP: 250, baseAttack: 5, baseDefense: 5, baseSpeed: 50, baseSpecial: 105, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "BODY_SLAM", displayName: "BODY SLAM", power: 85, accuracy: 100, maxPP: 15, effect: "PARALYZE_SIDE_EFFECT2", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var snorlax = runtime.makePokemon(speciesID: "SNORLAX", level: 30, nickname: "Snorlax")
        var chansey = runtime.makePokemon(speciesID: "CHANSEY", level: 30, nickname: "Chansey")
        var pendingAction: RuntimeBattlePendingAction?
        let bodySlam = try XCTUnwrap(runtime.content.move(id: "BODY_SLAM"))

        runtime.battleRandomOverrides = [0]
        let messages = runtime.applyMoveEffect(
            bodySlam,
            moveIndex: 0,
            dealtDamage: 20,
            attacker: &snorlax,
            defender: &chansey,
            defenderCanActLaterInTurn: false,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, [])
        XCTAssertEqual(chansey.majorStatus, .none)
        XCTAssertNil(pendingAction)
    }

    func testSleepMoveAgainstRechargingTargetBypassesAccuracyAndExistingStatusChecks() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "JIGGLYPUFF", displayName: "Jigglypuff", primaryType: "NORMAL", baseHP: 115, baseAttack: 45, baseDefense: 20, baseSpeed: 20, baseSpecial: 25, startingMoves: ["SING"]),
                        .init(id: "SNORLAX", displayName: "Snorlax", primaryType: "NORMAL", baseHP: 160, baseAttack: 110, baseDefense: 65, baseSpeed: 30, baseSpecial: 65, startingMoves: ["HYPER_BEAM"]),
                    ],
                    moves: [
                        .init(id: "SING", displayName: "SING", power: 0, accuracy: 55, maxPP: 15, effect: "SLEEP_EFFECT", type: "NORMAL"),
                        .init(id: "HYPER_BEAM", displayName: "HYPER BEAM", power: 150, accuracy: 90, maxPP: 5, effect: "HYPER_BEAM_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var jigglypuff = runtime.makePokemon(speciesID: "JIGGLYPUFF", level: 20, nickname: "Jigglypuff")
        var snorlax = runtime.makePokemon(speciesID: "SNORLAX", level: 20, nickname: "Snorlax")
        snorlax.majorStatus = .burn
        snorlax.battleEffects.needsRecharge = true

        runtime.battleRandomOverrides = [255]
        let result = runtime.resolveBattleAction(
            side: .player,
            attacker: jigglypuff,
            defender: snorlax,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )

        XCTAssertTrue(result.didExecuteMove)
        XCTAssertEqual(result.updatedDefender.majorStatus, .sleep)
        XCTAssertEqual(result.updatedDefender.statusCounter, 7)
        XCTAssertFalse(result.updatedDefender.battleEffects.needsRecharge)
        XCTAssertEqual(
            result.messages.suffix(2),
            ["Jigglypuff used SING!", "Snorlax fell asleep!"]
        )
    }

    func testApplyMoveEffectHazePreservesRechargeWhileClearingTrackedVolatiles() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "KOFFING", displayName: "Koffing", primaryType: "POISON", baseHP: 40, baseAttack: 65, baseDefense: 95, baseSpeed: 35, baseSpecial: 60, startingMoves: ["HAZE"]),
                        .init(id: "SHELLDER", displayName: "Shellder", primaryType: "WATER", baseHP: 30, baseAttack: 65, baseDefense: 100, baseSpeed: 40, baseSpecial: 45, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "HAZE", displayName: "HAZE", power: 0, accuracy: 100, maxPP: 30, effect: "HAZE_EFFECT", type: "ICE"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var koffing = runtime.makePokemon(speciesID: "KOFFING", level: 22, nickname: "Koffing")
        var shellder = runtime.makePokemon(speciesID: "SHELLDER", level: 22, nickname: "Shellder")
        koffing.attackStage = 3
        koffing.battleEffects.confusionTurnsRemaining = 2
        koffing.battleEffects.disabledMoveID = "HAZE"
        koffing.battleEffects.disabledTurnsRemaining = 4
        koffing.battleEffects.isProtectedByMist = true
        koffing.battleEffects.hasLightScreen = true
        koffing.battleEffects.hasReflect = true
        koffing.battleEffects.isGettingPumped = true
        koffing.battleEffects.isSeeded = true
        koffing.battleEffects.needsRecharge = true
        koffing.battleEffects.isFlinched = true

        shellder.defenseStage = -2
        shellder.majorStatus = .sleep
        shellder.statusCounter = 3
        shellder.battleEffects.confusionTurnsRemaining = 3
        shellder.battleEffects.disabledMoveID = "TACKLE"
        shellder.battleEffects.disabledTurnsRemaining = 2
        shellder.battleEffects.isProtectedByMist = true
        shellder.battleEffects.hasLightScreen = true
        shellder.battleEffects.hasReflect = true
        shellder.battleEffects.isGettingPumped = true
        shellder.battleEffects.isSeeded = true

        var pendingAction: RuntimeBattlePendingAction?
        let haze = try XCTUnwrap(runtime.content.move(id: "HAZE"))

        let messages = runtime.applyMoveEffect(
            haze,
            moveIndex: 0,
            dealtDamage: 0,
            attacker: &koffing,
            defender: &shellder,
            defenderCanActLaterInTurn: true,
            pendingAction: &pendingAction
        )

        XCTAssertEqual(messages, ["All status changes were eliminated!"])
        XCTAssertEqual(koffing.attackStage, 0)
        XCTAssertEqual(koffing.battleEffects.confusionTurnsRemaining, 0)
        XCTAssertNil(koffing.battleEffects.disabledMoveID)
        XCTAssertEqual(koffing.battleEffects.disabledTurnsRemaining, 0)
        XCTAssertFalse(koffing.battleEffects.isProtectedByMist)
        XCTAssertFalse(koffing.battleEffects.hasLightScreen)
        XCTAssertFalse(koffing.battleEffects.hasReflect)
        XCTAssertFalse(koffing.battleEffects.isGettingPumped)
        XCTAssertFalse(koffing.battleEffects.isSeeded)
        XCTAssertTrue(koffing.battleEffects.needsRecharge)
        XCTAssertTrue(koffing.battleEffects.isFlinched)

        XCTAssertEqual(shellder.defenseStage, 0)
        XCTAssertEqual(shellder.majorStatus, .none)
        XCTAssertEqual(shellder.statusCounter, 0)
        XCTAssertEqual(shellder.battleEffects.confusionTurnsRemaining, 0)
        XCTAssertNil(shellder.battleEffects.disabledMoveID)
        XCTAssertEqual(shellder.battleEffects.disabledTurnsRemaining, 0)
        XCTAssertFalse(shellder.battleEffects.isProtectedByMist)
        XCTAssertFalse(shellder.battleEffects.hasLightScreen)
        XCTAssertFalse(shellder.battleEffects.hasReflect)
        XCTAssertFalse(shellder.battleEffects.isGettingPumped)
        XCTAssertFalse(shellder.battleEffects.isSeeded)
        XCTAssertTrue(shellder.battleEffects.skipTurnOnce)
        XCTAssertNil(pendingAction)
    }

    func testSelectEnemyMoveIndexUsesForcedMoveBeforeOtherChoices() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["RAGE", "TACKLE"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "RAGE", displayName: "RAGE", power: 20, accuracy: 100, maxPP: 20, effect: "RAGE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var enemy = runtime.makePokemon(speciesID: "RATTATA", level: 12, nickname: "Rattata")
        let player = runtime.makePokemon(speciesID: "PIDGEY", level: 12, nickname: "Pidgey")
        enemy.battleEffects.isUsingRage = true
        let battle = RuntimeBattleState(
            battleID: "forced_rage",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: player,
            enemyParty: [enemy],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 0)
    }

    func testSelectEnemyMoveIndexFallsBackToDisabledMoveWhenItIsOnlyMoveWithPP() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE", "GROWL"]),
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var enemy = runtime.makePokemon(speciesID: "RATTATA", level: 12, nickname: "Rattata")
        let player = runtime.makePokemon(speciesID: "PIDGEY", level: 12, nickname: "Pidgey")
        enemy.battleEffects.disabledMoveID = "TACKLE"
        enemy.battleEffects.disabledTurnsRemaining = 2
        enemy.moves[1].currentPP = 0

        let battle = RuntimeBattleState(
            battleID: "disabled_only_move",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: player,
            enemyParty: [enemy],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.battleRandomOverrides = [0]
        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 0)
    }

    func testCounterUsesLastCounterableDamageInsteadOfGenericFightingDamage() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "COUNTERMON", displayName: "Countermon", primaryType: "FIGHTING", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 90, baseSpecial: 50, startingMoves: ["COUNTER"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 60, baseAttack: 65, baseDefense: 55, baseSpeed: 35, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "MAGE", displayName: "Mage", primaryType: "FIRE", baseHP: 60, baseAttack: 50, baseDefense: 50, baseSpeed: 35, baseSpecial: 70, startingMoves: ["EMBER"]),
                    ],
                    moves: [
                        .init(id: "COUNTER", displayName: "COUNTER", power: 1, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "FIGHTING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "EMBER", power: 40, accuracy: 100, maxPP: 25, effect: "NO_ADDITIONAL_EFFECT", type: "FIRE"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var countermon = runtime.makePokemon(speciesID: "COUNTERMON", level: 20, nickname: "Countermon")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 20, nickname: "Target")
        runtime.battleRandomOverrides = [0, 255]
        let tackleResult = runtime.applyMove(attacker: &target, defender: &countermon, moveIndex: 0)
        XCTAssertEqual(countermon.battleEffects.lastDamageTaken, tackleResult.dealtDamage)
        let expectedCounterDamage = tackleResult.dealtDamage * 2

        runtime.battleRandomOverrides = [0]
        let counterResult = runtime.applyMove(attacker: &countermon, defender: &target, moveIndex: 0)
        XCTAssertEqual(counterResult.dealtDamage, expectedCounterDamage)
        XCTAssertFalse(counterResult.messages.contains("It's super effective!"))
        XCTAssertFalse(counterResult.messages.contains("Critical hit!"))

        var mage = runtime.makePokemon(speciesID: "MAGE", level: 20, nickname: "Mage")
        countermon.battleEffects.lastDamageTaken = 18
        mage.battleEffects.lastSelectedMoveID = "EMBER"
        mage.battleEffects.lastSelectedMovePower = 40
        mage.battleEffects.lastSelectedMoveType = "FIRE"
        runtime.battleRandomOverrides = [0]
        let failedCounter = runtime.applyMove(attacker: &countermon, defender: &mage, moveIndex: 0)
        XCTAssertEqual(failedCounter.dealtDamage, 0)
        XCTAssertEqual(failedCounter.messages.suffix(1), ["But it failed!"])
    }

    func testCounterUsesExecutedMetronomeMoveMetadata() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "COUNTERMON", displayName: "Countermon", primaryType: "FIGHTING", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 55, baseSpecial: 50, startingMoves: ["COUNTER"]),
                        .init(id: "TRICKSTER", displayName: "Trickster", primaryType: "NORMAL", baseHP: 60, baseAttack: 65, baseDefense: 55, baseSpeed: 35, baseSpecial: 40, startingMoves: ["METRONOME"]),
                    ],
                    moves: [
                        .init(id: "COUNTER", displayName: "COUNTER", power: 1, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "FIGHTING"),
                        .init(id: "METRONOME", displayName: "METRONOME", power: 0, accuracy: 100, maxPP: 10, effect: "METRONOME_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var countermon = runtime.makePokemon(speciesID: "COUNTERMON", level: 20, nickname: "Countermon")
        var trickster = runtime.makePokemon(speciesID: "TRICKSTER", level: 20, nickname: "Trickster")

        runtime.battleRandomOverrides = [1, 0, 255]
        let metronomeResult = runtime.applyMove(attacker: &trickster, defender: &countermon, moveIndex: 0)
        XCTAssertEqual(trickster.battleEffects.lastSelectedMoveID, "TACKLE")
        XCTAssertEqual(trickster.battleEffects.lastSelectedMoveType, "NORMAL")
        XCTAssertGreaterThan(metronomeResult.dealtDamage, 0)

        runtime.battleRandomOverrides = [0]
        let counterResult = runtime.applyMove(attacker: &countermon, defender: &trickster, moveIndex: 0)
        XCTAssertEqual(counterResult.dealtDamage, metronomeResult.dealtDamage * 2)
    }

    func testCounterUsesExecutedMirrorMoveMetadata() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "COUNTERMON", displayName: "Countermon", primaryType: "FIGHTING", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 55, baseSpecial: 50, startingMoves: ["COUNTER"]),
                        .init(id: "COPYCAT", displayName: "Copycat", primaryType: "FLYING", baseHP: 60, baseAttack: 65, baseDefense: 55, baseSpeed: 35, baseSpecial: 40, startingMoves: ["MIRROR_MOVE"]),
                    ],
                    moves: [
                        .init(id: "COUNTER", displayName: "COUNTER", power: 1, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "FIGHTING"),
                        .init(id: "MIRROR_MOVE", displayName: "MIRROR MOVE", power: 0, accuracy: 100, maxPP: 20, effect: "MIRROR_MOVE_EFFECT", type: "FLYING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var countermon = runtime.makePokemon(speciesID: "COUNTERMON", level: 20, nickname: "Countermon")
        var copycat = runtime.makePokemon(speciesID: "COPYCAT", level: 20, nickname: "Copycat")
        countermon.battleEffects.lastMoveID = "TACKLE"

        runtime.battleRandomOverrides = [0, 255]
        let mirrorMoveResult = runtime.applyMove(attacker: &copycat, defender: &countermon, moveIndex: 0)
        XCTAssertEqual(copycat.battleEffects.lastSelectedMoveID, "TACKLE")
        XCTAssertEqual(copycat.battleEffects.lastSelectedMoveType, "NORMAL")
        XCTAssertGreaterThan(mirrorMoveResult.dealtDamage, 0)

        runtime.battleRandomOverrides = [0]
        let counterResult = runtime.applyMove(attacker: &countermon, defender: &copycat, moveIndex: 0)
        XCTAssertEqual(counterResult.dealtDamage, mirrorMoveResult.dealtDamage * 2)
    }

    func testCounterMovesAfterOpposingMoveEvenWhenUserIsFaster() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "COUNTERMON", displayName: "Countermon", primaryType: "FIGHTING", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 90, baseSpecial: 50, startingMoves: ["COUNTER"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 60, baseAttack: 65, baseDefense: 55, baseSpeed: 35, baseSpecial: 40, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "COUNTER", displayName: "COUNTER", power: 1, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "FIGHTING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let playerPokemon = runtime.makePokemon(speciesID: "COUNTERMON", level: 20, nickname: "Countermon")
        let enemyPokemon = runtime.makePokemon(speciesID: "TARGET", level: 20, nickname: "Target")

        var battle = RuntimeBattleState(
            battleID: "counter_priority",
            kind: .wild,
            trainerName: "Wild Target",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        var expectedCounterUser = playerPokemon
        var expectedAttacker = enemyPokemon
        runtime.battleRandomOverrides = [0, 255, 0]
        _ = runtime.resolveActionMoveIndex(
            for: .enemy,
            battle: battle,
            playerPokemon: expectedCounterUser,
            enemyPokemon: expectedAttacker
        )
        _ = runtime.applyMove(attacker: &expectedAttacker, defender: &expectedCounterUser, moveIndex: 0)
        let expectedCounterDamage = expectedCounterUser.battleEffects.lastDamageTaken * 2

        runtime.battleRandomOverrides = [0, 255, 0]
        let batches = runtime.makeTurnPresentationBatches(for: &battle)
        let firstBatchMessages = batches[0].compactMap(\.message)
        let secondBatchMessages = batches[1].compactMap(\.message)
        XCTAssertEqual(firstBatchMessages.first, "Target used TACKLE!")
        XCTAssertEqual(secondBatchMessages.first, "Countermon used COUNTER!")
        guard let counterBeat = batches[1].last else {
            XCTFail("Expected Counter action batch to include a terminal beat")
            return
        }
        XCTAssertEqual(counterBeat.enemyPokemon?.currentHP, enemyPokemon.currentHP - expectedCounterDamage)
    }

    func testBattlePresentationReusesPeekedEnemyMoveForOrderingAndExecution() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SLOWMON", displayName: "Slowmon", primaryType: "NORMAL", baseHP: 60, baseAttack: 65, baseDefense: 60, baseSpeed: 35, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "FASTMON", displayName: "Fastmon", primaryType: "FIGHTING", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 90, baseSpecial: 50, startingMoves: ["COUNTER", "TACKLE"]),
                    ],
                    moves: [
                        .init(id: "COUNTER", displayName: "COUNTER", power: 1, accuracy: 100, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "FIGHTING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let playerPokemon = runtime.makePokemon(speciesID: "SLOWMON", level: 20, nickname: "Slowmon")
        let enemyPokemon = runtime.makePokemon(speciesID: "FASTMON", level: 20, nickname: "Fastmon")

        var battle = RuntimeBattleState(
            battleID: "peeked_enemy_move_reuse",
            kind: .wild,
            trainerName: "Wild Fastmon",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.battleRandomOverrides = [0, 0, 255, 1, 0]
        let batches = runtime.makeTurnPresentationBatches(for: &battle)
        let firstBatchMessages = batches[0].compactMap(\.message)
        let secondBatchMessages = batches[1].compactMap(\.message)
        XCTAssertEqual(firstBatchMessages.first, "Slowmon used TACKLE!")
        XCTAssertEqual(secondBatchMessages.first, "Fastmon used COUNTER!")
    }

    func testBattlePresentationPreservesEnemySelectionRNGConsumption() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SLOWMON", displayName: "Slowmon", primaryType: "NORMAL", baseHP: 60, baseAttack: 65, baseDefense: 60, baseSpeed: 35, baseSpecial: 40, startingMoves: ["TACKLE"]),
                        .init(id: "FASTMON", displayName: "Fastmon", primaryType: "NORMAL", baseHP: 60, baseAttack: 70, baseDefense: 60, baseSpeed: 90, baseSpecial: 50, startingMoves: ["SING", "TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SING", displayName: "SING", power: 0, accuracy: 55, maxPP: 15, effect: "SLEEP_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let playerPokemon = runtime.makePokemon(speciesID: "SLOWMON", level: 20, nickname: "Slowmon")
        let enemyPokemon = runtime.makePokemon(speciesID: "FASTMON", level: 20, nickname: "Fastmon")

        var battle = RuntimeBattleState(
            battleID: "enemy_selection_rng_consumption",
            kind: .wild,
            trainerName: "Wild Fastmon",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.battleRandomOverrides = [0, 255]
        let batches = runtime.makeTurnPresentationBatches(for: &battle)
        let firstBatchMessages = batches[0].compactMap(\.message)
        XCTAssertEqual(firstBatchMessages, ["Fastmon used SING!", "But it missed!"])
    }

    func testChargingMovesConsumePpOnlyOnceAcrossTwoTurnCycle() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "BIRD", displayName: "Bird", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["FLY"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "FLY", displayName: "FLY", power: 70, accuracy: 95, maxPP: 15, effect: "FLY_EFFECT", type: "FLYING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var bird = runtime.makePokemon(speciesID: "BIRD", level: 20, nickname: "Bird")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 20, nickname: "Target")
        let initialPP = bird.moves[0].currentPP

        _ = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 0)
        XCTAssertEqual(bird.moves[0].currentPP, initialPP - 1)

        runtime.battleRandomOverrides = [0, 255]
        let secondFlyTurn = runtime.resolveBattleAction(
            side: .player,
            attacker: bird,
            defender: target,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertEqual(secondFlyTurn.updatedAttacker.moves[0].currentPP, initialPP - 1)
        XCTAssertNil(secondFlyTurn.updatedAttacker.battleEffects.chargingMoveID)
    }

    func testFlyTeleportAndPayDayFamiliesUseBattleState() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["FLY"]),
                        .init(id: "ABRA", displayName: "Abra", primaryType: "PSYCHIC_TYPE", baseHP: 25, baseAttack: 20, baseDefense: 15, baseSpeed: 90, baseSpecial: 105, startingMoves: ["TELEPORT"]),
                        .init(id: "MEOWTH", displayName: "Meowth", primaryType: "NORMAL", baseHP: 40, baseAttack: 45, baseDefense: 35, baseSpeed: 90, baseSpecial: 40, startingMoves: ["PAY_DAY"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "FLY", displayName: "FLY", power: 70, accuracy: 95, maxPP: 15, effect: "FLY_EFFECT", type: "FLYING"),
                        .init(id: "TELEPORT", displayName: "TELEPORT", power: 0, accuracy: 100, maxPP: 20, effect: "SWITCH_AND_TELEPORT_EFFECT", type: "PSYCHIC_TYPE"),
                        .init(id: "PAY_DAY", displayName: "PAY DAY", power: 40, accuracy: 100, maxPP: 20, effect: "PAY_DAY_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var pidgey = runtime.makePokemon(speciesID: "PIDGEY", level: 12, nickname: "Pidgey")
        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")
        let firstFlyTurn = runtime.applyMove(attacker: &pidgey, defender: &rattata, moveIndex: 0)
        XCTAssertEqual(firstFlyTurn.dealtDamage, 0)
        XCTAssertEqual(pidgey.battleEffects.chargingMoveID, "FLY")
        XCTAssertTrue(pidgey.battleEffects.isInvulnerable)
        XCTAssertTrue(firstFlyTurn.messages.contains("Flew up high!"))

        let blockedAction = runtime.resolveBattleAction(
            side: .enemy,
            attacker: rattata,
            defender: pidgey,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertEqual(blockedAction.messages, ["Rattata used TACKLE!", "But it missed!"])

        runtime.battleRandomOverrides = [0, 255]
        let secondFlyTurn = runtime.resolveBattleAction(
            side: .player,
            attacker: pidgey,
            defender: rattata,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertTrue(secondFlyTurn.didExecuteMove)
        XCTAssertNil(secondFlyTurn.updatedAttacker.battleEffects.chargingMoveID)
        XCTAssertFalse(secondFlyTurn.updatedAttacker.battleEffects.isInvulnerable)
        XCTAssertGreaterThan(secondFlyTurn.dealtDamage, 0)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        var wildBattle = RuntimeBattleState(
            battleID: "wild_test",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: runtime.makePokemon(speciesID: "ABRA", level: 20, nickname: "Abra"),
            enemyParty: [runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )
        runtime.gameplayState?.battle = wildBattle
        var teleportAttacker = wildBattle.playerPokemon
        var teleportDefender = wildBattle.enemyPokemon
        let teleportResult = runtime.applyMove(attacker: &teleportAttacker, defender: &teleportDefender, moveIndex: 0)
        if case .escape? = teleportResult.pendingAction {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected TELEPORT to escape from a wild battle")
        }
        XCTAssertTrue(teleportResult.messages.contains("Ran from battle!"))

        wildBattle.playerPokemon = runtime.makePokemon(speciesID: "ABRA", level: 1, nickname: "Abra")
        wildBattle.enemyParty = [runtime.makePokemon(speciesID: "RATTATA", level: 3, nickname: "Rattata")]
        runtime.gameplayState?.battle = wildBattle
        var lowLevelAbra = wildBattle.playerPokemon
        var lowLevelRattata = wildBattle.enemyPokemon
        runtime.battleRandomOverrides = [0, 0]
        let lowLevelTeleport = runtime.applyMove(attacker: &lowLevelAbra, defender: &lowLevelRattata, moveIndex: 0)
        if case .escape? = lowLevelTeleport.pendingAction {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected TELEPORT to escape when the target's level / 4 threshold is zero")
        }
        XCTAssertTrue(lowLevelTeleport.messages.contains("Ran from battle!"))
        XCTAssertEqual(runtime.battleRandomOverrides, [])

        wildBattle.playerPokemon = runtime.makePokemon(speciesID: "ABRA", level: 1, nickname: "Abra")
        wildBattle.enemyParty = [runtime.makePokemon(speciesID: "RATTATA", level: 20, nickname: "Rattata")]
        runtime.gameplayState?.battle = wildBattle
        var underleveledAbra = wildBattle.playerPokemon
        var strongRattata = wildBattle.enemyPokemon
        runtime.battleRandomOverrides = [0, 0, 255]
        let failedTeleport = runtime.applyMove(attacker: &underleveledAbra, defender: &strongRattata, moveIndex: 0)
        XCTAssertNil(failedTeleport.pendingAction)
        XCTAssertEqual(failedTeleport.messages.suffix(1), ["But it failed!"])
        XCTAssertEqual(runtime.battleRandomOverrides, [255])

        var meowth = runtime.makePokemon(speciesID: "MEOWTH", level: 11, nickname: "Meowth")
        var payDayTarget = runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")
        runtime.battleRandomOverrides = [0, 255]
        let payDayResult = runtime.applyMove(attacker: &meowth, defender: &payDayTarget, moveIndex: 0)
        XCTAssertEqual(payDayResult.payDayMoneyGain, 22)

        runtime.gameplayState?.playerName = "RED"
        wildBattle.payDayMoney = payDayResult.payDayMoneyGain
        let awarded = runtime.awardPayDayIfNeeded(battle: &wildBattle, pendingAction: .escape)
        XCTAssertTrue(awarded)
        XCTAssertEqual(runtime.gameplayState?.money, runtime.makeInitialGameplayState().money + 22)
        XCTAssertEqual(wildBattle.payDayMoney, 0)
        if case .escape? = wildBattle.pendingAction {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected Pay Day award flow to preserve the original pending action")
        }
    }

    func testPayDayAwardPersistsThroughBattleInputAdvance() {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .battle
        runtime.substate = "battle"

        let initialMoney = try! XCTUnwrap(runtime.gameplayState?.money)
        runtime.gameplayState?.battle = RuntimeBattleState(
            battleID: "pay_day_award",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: runtime.makePokemon(speciesID: "STARTER1", level: 5, nickname: "Starter"),
            enemyParty: [runtime.makePokemon(speciesID: "STARTER1", level: 5, nickname: "Wildmon")],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 22,
            phase: .turnText,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: .escape,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.handleBattle(button: .confirm)

        XCTAssertEqual(runtime.gameplayState?.money, initialMoney + 22)
        XCTAssertEqual(runtime.gameplayState?.battle?.payDayMoney, 0)
        XCTAssertEqual(runtime.gameplayState?.battle?.message, "RED picked up ¥22!")
        if case .escape? = runtime.gameplayState?.battle?.pendingAction {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected Pay Day payout message to keep the escape continuation queued")
        }
    }

    func testBideAndThrashUseForcedTurnState() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SLOWBRO", displayName: "Slowbro", primaryType: "WATER", secondaryType: "PSYCHIC_TYPE", baseHP: 95, baseAttack: 75, baseDefense: 110, baseSpeed: 30, baseSpecial: 80, startingMoves: ["BIDE", "THRASH"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 75, baseAttack: 50, baseDefense: 55, baseSpeed: 40, baseSpecial: 45, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "BIDE", displayName: "BIDE", power: 0, accuracy: 100, maxPP: 10, effect: "BIDE_EFFECT", type: "NORMAL"),
                        .init(id: "THRASH", displayName: "THRASH", power: 90, accuracy: 100, maxPP: 20, effect: "THRASH_PETAL_DANCE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var bider = runtime.makePokemon(speciesID: "SLOWBRO", level: 18, nickname: "Slowbro")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 18, nickname: "Target")
        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &bider, defender: &target, moveIndex: 0)
        XCTAssertEqual(bider.battleEffects.bideTurnsRemaining, 2)

        bider.battleEffects.bideTurnsRemaining = 1
        bider.battleEffects.bideAccumulatedDamage = 12
        let release = runtime.resolveBattleAction(
            side: .player,
            attacker: bider,
            defender: target,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertTrue(release.didExecuteMove)
        XCTAssertTrue(release.messages.contains("Slowbro unleashed energy!"))
        XCTAssertEqual(release.dealtDamage, 24)
        XCTAssertNil(release.updatedAttacker.battleEffects.pendingBideDamage)

        var thrasher = runtime.makePokemon(speciesID: "SLOWBRO", level: 18, nickname: "Slowbro")
        var thrashTarget = runtime.makePokemon(speciesID: "TARGET", level: 18, nickname: "Target")
        runtime.battleRandomOverrides = [0, 255, 0]
        _ = runtime.applyMove(attacker: &thrasher, defender: &thrashTarget, moveIndex: 1)
        XCTAssertEqual(thrasher.battleEffects.thrashTurnsRemaining, 2)

        runtime.battleRandomOverrides = [0, 255]
        let firstContinuedThrash = runtime.resolveBattleAction(
            side: .player,
            attacker: thrasher,
            defender: thrashTarget,
            moveIndex: 1,
            defenderCanActLaterInTurn: false
        )
        XCTAssertTrue(firstContinuedThrash.didExecuteMove)
        XCTAssertTrue(firstContinuedThrash.messages.contains("Slowbro is thrashing about!"))
        XCTAssertEqual(firstContinuedThrash.updatedAttacker.battleEffects.thrashTurnsRemaining, 1)
        XCTAssertEqual(firstContinuedThrash.updatedAttacker.battleEffects.confusionTurnsRemaining, 0)

        runtime.battleRandomOverrides = [0, 0, 255]
        let finalThrashTurn = runtime.resolveBattleAction(
            side: .player,
            attacker: firstContinuedThrash.updatedAttacker,
            defender: firstContinuedThrash.updatedDefender,
            moveIndex: 1,
            defenderCanActLaterInTurn: false
        )
        XCTAssertTrue(finalThrashTurn.didExecuteMove)
        XCTAssertTrue(finalThrashTurn.messages.contains("Slowbro is thrashing about!"))
        XCTAssertEqual(finalThrashTurn.updatedAttacker.battleEffects.thrashTurnsRemaining, 0)
        XCTAssertGreaterThan(finalThrashTurn.updatedAttacker.battleEffects.confusionTurnsRemaining, 0)
    }

    func testBideAccumulatesDamageTakenDuringStorageTurns() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "SLOWBRO", displayName: "Slowbro", primaryType: "WATER", secondaryType: "PSYCHIC_TYPE", baseHP: 95, baseAttack: 75, baseDefense: 110, baseSpeed: 30, baseSpecial: 80, startingMoves: ["BIDE"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 75, baseAttack: 50, baseDefense: 55, baseSpeed: 40, baseSpecial: 45, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "BIDE", displayName: "BIDE", power: 0, accuracy: 100, maxPP: 10, effect: "BIDE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var bider = runtime.makePokemon(speciesID: "SLOWBRO", level: 18, nickname: "Slowbro")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 18, nickname: "Target")
        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &bider, defender: &target, moveIndex: 0)
        XCTAssertEqual(bider.battleEffects.bideTurnsRemaining, 2)

        runtime.battleRandomOverrides = [0, 255]
        let tackleDamage = runtime.applyMove(attacker: &target, defender: &bider, moveIndex: 0)
        XCTAssertGreaterThan(tackleDamage.dealtDamage, 0)
        XCTAssertEqual(bider.battleEffects.bideAccumulatedDamage, tackleDamage.dealtDamage)

        bider.battleEffects.bideTurnsRemaining = 1
        let release = runtime.resolveBattleAction(
            side: .player,
            attacker: bider,
            defender: target,
            moveIndex: 0,
            defenderCanActLaterInTurn: false
        )
        XCTAssertEqual(release.dealtDamage, tackleDamage.dealtDamage * 2)
    }

    func testSubstituteRageTransformAndConversionMutateBattleState() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "DITTO", displayName: "Ditto", primaryType: "NORMAL", baseHP: 48, baseAttack: 48, baseDefense: 48, baseSpeed: 48, baseSpecial: 48, startingMoves: ["TRANSFORM", "SUBSTITUTE", "CONVERSION"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["RAGE", "TACKLE"]),
                        .init(id: "GASTLY", displayName: "Gastly", primaryType: "GHOST", secondaryType: "POISON", baseHP: 30, baseAttack: 35, baseDefense: 30, baseSpeed: 80, baseSpecial: 100, startingMoves: ["LICK"]),
                    ],
                    moves: [
                        .init(id: "TRANSFORM", displayName: "TRANSFORM", power: 0, accuracy: 100, maxPP: 10, effect: "TRANSFORM_EFFECT", type: "NORMAL"),
                        .init(id: "SUBSTITUTE", displayName: "SUBSTITUTE", power: 0, accuracy: 100, maxPP: 10, effect: "SUBSTITUTE_EFFECT", type: "NORMAL"),
                        .init(id: "CONVERSION", displayName: "CONVERSION", power: 0, accuracy: 100, maxPP: 30, effect: "CONVERSION_EFFECT", type: "NORMAL"),
                        .init(id: "RAGE", displayName: "RAGE", power: 20, accuracy: 100, maxPP: 20, effect: "RAGE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "LICK", displayName: "LICK", power: 20, accuracy: 100, maxPP: 30, effect: "NO_ADDITIONAL_EFFECT", type: "GHOST"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var ditto = runtime.makePokemon(speciesID: "DITTO", level: 20, nickname: "Ditto")
        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 20, nickname: "Rattata")
        _ = runtime.applyMove(attacker: &ditto, defender: &rattata, moveIndex: 1)
        XCTAssertTrue(ditto.battleEffects.hasSubstitute)
        let hpAfterSubstitute = ditto.currentHP

        runtime.battleRandomOverrides = [0, 255]
        _ = runtime.applyMove(attacker: &rattata, defender: &ditto, moveIndex: 1)
        XCTAssertEqual(ditto.currentHP, hpAfterSubstitute)
        XCTAssertLessThan(ditto.battleEffects.substituteHP, max(1, ditto.maxHP / 4))

        runtime.battleRandomOverrides = [0, 255]
        _ = runtime.applyMove(attacker: &rattata, defender: &ditto, moveIndex: 0)
        XCTAssertTrue(rattata.battleEffects.isUsingRage)

        var gastly = runtime.makePokemon(speciesID: "GASTLY", level: 20, nickname: "Gastly")
        runtime.battleRandomOverrides = [0, 255]
        let rageTrigger = runtime.applyMove(attacker: &gastly, defender: &rattata, moveIndex: 0)
        XCTAssertTrue(rageTrigger.messages.contains("Rattata's Rage is building!"))
        XCTAssertEqual(rattata.attackStage, 1)

        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &ditto, defender: &gastly, moveIndex: 2)
        XCTAssertEqual(ditto.battleEffects.typeOverridePrimary, "GHOST")
        XCTAssertEqual(ditto.battleEffects.typeOverrideSecondary, "POISON")

        runtime.battleRandomOverrides = [0, 255]
        _ = runtime.applyMove(attacker: &ditto, defender: &rattata, moveIndex: 0)
        XCTAssertEqual(ditto.speciesID, "RATTATA")
        XCTAssertEqual(ditto.moves.map(\.id), rattata.moves.map(\.id))
        XCTAssertNotNil(ditto.battleEffects.transformedState)
    }

    func testTransformedPokemonLevelUpRestoresOriginalStatsAfterBattle() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "DITTO", displayName: "Ditto", primaryType: "NORMAL", baseExp: 61, growthRate: .mediumFast, baseHP: 48, baseAttack: 48, baseDefense: 48, baseSpeed: 48, baseSpecial: 48, startingMoves: ["TRANSFORM"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseExp: 51, growthRate: .mediumFast, baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                        .init(id: "DEFEATED", displayName: "Defeated", primaryType: "NORMAL", baseExp: 255, growthRate: .mediumFast, baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TRANSFORM", displayName: "TRANSFORM", power: 0, accuracy: 100, maxPP: 10, effect: "TRANSFORM_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let baseDitto = runtime.makePokemon(speciesID: "DITTO", level: 5, nickname: "Ditto")
        let nextLevelExperience = runtime.experienceRequired(for: 6, speciesID: "DITTO") - 1
        var ditto = runtime.makeConfiguredPokemon(
            speciesID: "DITTO",
            nickname: "Ditto",
            level: 5,
            experience: nextLevelExperience,
            dvs: baseDitto.dvs,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: [RuntimeMoveState(id: "TRANSFORM", currentPP: 10)]
        )
        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 6, nickname: "Rattata")
        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &ditto, defender: &rattata, moveIndex: 0)

        let defeated = runtime.makePokemon(speciesID: "DEFEATED", level: 5, nickname: "Defeated")
        let reward = runtime.applyBattleExperienceReward(
            defeatedPokemon: defeated,
            to: &ditto,
            isTrainerBattle: false
        )
        XCTAssertTrue(reward.messages.contains(where: { $0.contains("Ditto grew to Lv") }))

        let restored = runtime.clearBattleStatStages(ditto)
        let expected = runtime.makeConfiguredPokemon(
            speciesID: "DITTO",
            nickname: "Ditto",
            level: restored.level,
            experience: restored.experience,
            dvs: restored.dvs,
            statExp: restored.statExp,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: [RuntimeMoveState(id: "TRANSFORM", currentPP: 10)]
        )

        XCTAssertEqual(restored.speciesID, "DITTO")
        XCTAssertGreaterThan(restored.level, 5)
        XCTAssertEqual(restored.maxHP, expected.maxHP)
        XCTAssertEqual(restored.attack, expected.attack)
        XCTAssertEqual(restored.defense, expected.defense)
        XCTAssertEqual(restored.speed, expected.speed)
        XCTAssertEqual(restored.special, expected.special)
        XCTAssertEqual(restored.moves.map(\.id), ["TRANSFORM"])
    }

    func testTransformedLearnMovePromptUsesOriginalMoveSlots() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "DITTO", displayName: "Ditto", primaryType: "NORMAL", baseHP: 48, baseAttack: 48, baseDefense: 48, baseSpeed: 48, baseSpecial: 48, startingMoves: ["TRANSFORM", "GROWL", "TAIL_WHIP", "SCRATCH"]),
                        .init(id: "ONE_MOVE", displayName: "OneMove", primaryType: "NORMAL", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TRANSFORM", displayName: "TRANSFORM", power: 0, accuracy: 100, maxPP: 10, effect: "TRANSFORM_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TAIL_WHIP", displayName: "TAIL WHIP", power: 0, accuracy: 100, maxPP: 30, effect: "DEFENSE_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "SLAM", displayName: "SLAM", power: 80, accuracy: 75, maxPP: 20, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .battle
        runtime.substate = "battle"

        var ditto = runtime.makePokemon(speciesID: "DITTO", level: 20, nickname: "Ditto")
        var oneMove = runtime.makePokemon(speciesID: "ONE_MOVE", level: 20, nickname: "OneMove")
        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &ditto, defender: &oneMove, moveIndex: 0)

        runtime.gameplayState?.battle = RuntimeBattleState(
            battleID: "transformed_learn_move",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: ditto,
            enemyParty: [oneMove],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .learnMoveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "Choose a move to forget for SLAM.",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: .init(moveID: "SLAM", remainingMoveIDs: []),
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.handleBattle(button: .down)
        runtime.handleBattle(button: .down)
        runtime.handleBattle(button: .down)

        let focusedIndex = try XCTUnwrap(runtime.gameplayState?.battle?.focusedMoveIndex)
        XCTAssertEqual(focusedIndex, 3)

        let snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.moveSlots.map(\.displayName), ["TRANSFORM", "GROWL", "TAIL WHIP", "SCRATCH"])

        runtime.handleBattle(button: .confirm)

        let learnedMoves = try XCTUnwrap(
            runtime.gameplayState?.battle?.playerPokemon.battleEffects.transformedState?.originalMoves.map(\.id)
        )
        XCTAssertEqual(learnedMoves, ["TRANSFORM", "GROWL", "TAIL_WHIP", "SLAM"])
    }

    func testMimicMirrorMoveAndMetronomeCopyMoves() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "BIRD", displayName: "Bird", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["MIRROR_MOVE", "MIMIC", "METRONOME"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE", "GROWL"]),
                    ],
                    moves: [
                        .init(id: "MIRROR_MOVE", displayName: "MIRROR MOVE", power: 0, accuracy: 100, maxPP: 20, effect: "MIRROR_MOVE_EFFECT", type: "FLYING"),
                        .init(id: "MIMIC", displayName: "MIMIC", power: 0, accuracy: 100, maxPP: 10, effect: "MIMIC_EFFECT", type: "NORMAL"),
                        .init(id: "METRONOME", displayName: "METRONOME", power: 0, accuracy: 100, maxPP: 10, effect: "METRONOME_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var bird = runtime.makePokemon(speciesID: "BIRD", level: 15, nickname: "Bird")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 15, nickname: "Target")

        runtime.battleRandomOverrides = [1]
        _ = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 1)
        XCTAssertNotEqual(bird.moves[1].id, "MIMIC")
        XCTAssertTrue(["TACKLE", "GROWL"].contains(bird.moves[1].id))
        XCTAssertNotNil(bird.battleEffects.mimicState)

        target.battleEffects.lastMoveID = "TACKLE"
        runtime.battleRandomOverrides = [0, 255]
        let mirrorMove = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 0)
        XCTAssertEqual(mirrorMove.messages.first, "Bird used TACKLE!")
        XCTAssertGreaterThan(mirrorMove.dealtDamage, 0)

        runtime.battleRandomOverrides = [0, 0, 255]
        let metronome = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 2)
        XCTAssertNotEqual(metronome.messages.first, "Bird used METRONOME!")
        XCTAssertNotEqual(bird.battleEffects.lastMoveID, "METRONOME")
        XCTAssertNotEqual(bird.battleEffects.lastMoveID, "STRUGGLE")
    }

    func testTransformSnapshotPreservesOriginalMimicSlotForBattleCleanup() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "BIRD", displayName: "Bird", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["MIMIC", "TRANSFORM"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE", "GROWL"]),
                    ],
                    moves: [
                        .init(id: "MIMIC", displayName: "MIMIC", power: 0, accuracy: 100, maxPP: 10, effect: "MIMIC_EFFECT", type: "NORMAL"),
                        .init(id: "TRANSFORM", displayName: "TRANSFORM", power: 0, accuracy: 100, maxPP: 10, effect: "TRANSFORM_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var bird = runtime.makePokemon(speciesID: "BIRD", level: 15, nickname: "Bird")
        var target = runtime.makePokemon(speciesID: "TARGET", level: 15, nickname: "Target")

        runtime.battleRandomOverrides = [0]
        _ = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 0)
        XCTAssertEqual(bird.moves[0].id, "TACKLE")

        _ = runtime.applyMove(attacker: &bird, defender: &target, moveIndex: 1)
        let restored = runtime.restoreBattleSpecificPokemonMutations(bird)

        XCTAssertEqual(restored.moves.map(\.id), ["MIMIC", "TRANSFORM"])
    }

    func testFixedDamageDrainAndRecoilEffectsUseGBSemantics() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "ODDISH", displayName: "Oddish", primaryType: "GRASS", secondaryType: "POISON", baseHP: 45, baseAttack: 50, baseDefense: 55, baseSpeed: 30, baseSpecial: 75, startingMoves: ["MEGA_DRAIN"]),
                        .init(id: "VOLTORB", displayName: "Voltorb", primaryType: "ELECTRIC", baseHP: 40, baseAttack: 30, baseDefense: 50, baseSpeed: 100, baseSpecial: 55, startingMoves: ["SONICBOOM"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TAKE_DOWN"]),
                        .init(id: "SANDSHREW", displayName: "Sandshrew", primaryType: "GROUND", baseHP: 50, baseAttack: 75, baseDefense: 85, baseSpeed: 40, baseSpecial: 30, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "MEGA_DRAIN", displayName: "MEGA DRAIN", power: 40, accuracy: 100, maxPP: 10, effect: "DRAIN_HP_EFFECT", type: "GRASS"),
                        .init(id: "SONICBOOM", displayName: "SONICBOOM", power: 1, accuracy: 90, maxPP: 20, effect: "SPECIAL_DAMAGE_EFFECT", type: "NORMAL"),
                        .init(id: "TAKE_DOWN", displayName: "TAKE DOWN", power: 90, accuracy: 85, maxPP: 20, effect: "RECOIL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var voltorb = runtime.makePokemon(speciesID: "VOLTORB", level: 10, nickname: "Voltorb")
        var sandshrew = runtime.makePokemon(speciesID: "SANDSHREW", level: 10, nickname: "Sandshrew")
        runtime.battleRandomOverrides = [0]
        let sonicBoom = runtime.applyMove(attacker: &voltorb, defender: &sandshrew, moveIndex: 0)
        XCTAssertEqual(sonicBoom.dealtDamage, 20)

        var oddish = runtime.makePokemon(speciesID: "ODDISH", level: 10, nickname: "Oddish")
        oddish.currentHP = max(1, oddish.currentHP - 10)
        var drainTarget = runtime.makePokemon(speciesID: "SANDSHREW", level: 10, nickname: "Sandshrew")
        runtime.battleRandomOverrides = [0, 255]
        let drainResult = runtime.applyMove(attacker: &oddish, defender: &drainTarget, moveIndex: 0)
        XCTAssertGreaterThan(oddish.currentHP, oddish.maxHP - 10)
        XCTAssertTrue(drainResult.messages.contains(where: { $0.contains("Sucked health from") }))

        var rattata = runtime.makePokemon(speciesID: "RATTATA", level: 10, nickname: "Rattata")
        let recoilHPBefore = rattata.currentHP
        var recoilTarget = runtime.makePokemon(speciesID: "SANDSHREW", level: 10, nickname: "Sandshrew")
        runtime.battleRandomOverrides = [0, 255]
        let recoilResult = runtime.applyMove(attacker: &rattata, defender: &recoilTarget, moveIndex: 0)
        XCTAssertLessThan(rattata.currentHP, recoilHPBefore)
        XCTAssertTrue(recoilResult.messages.contains("Rattata is hit with recoil!"))
    }

    func testZeroPowerFixedDamageMovesAreAbsorbedBySubstitute() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "GASTLY", displayName: "Gastly", primaryType: "GHOST", secondaryType: "POISON", baseHP: 30, baseAttack: 35, baseDefense: 30, baseSpeed: 80, baseSpecial: 100, startingMoves: ["NIGHT_SHADE"]),
                        .init(id: "ABRA", displayName: "Abra", primaryType: "NORMAL", baseHP: 25, baseAttack: 20, baseDefense: 15, baseSpeed: 90, baseSpecial: 105, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "NIGHT_SHADE", displayName: "NIGHT SHADE", power: 0, accuracy: 100, maxPP: 15, effect: "SPECIAL_DAMAGE_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var gastly = runtime.makePokemon(speciesID: "GASTLY", level: 20, nickname: "Gastly")
        var abra = runtime.makePokemon(speciesID: "ABRA", level: 20, nickname: "Abra")
        abra.battleEffects.hasSubstitute = true
        abra.battleEffects.substituteHP = 30
        let hpBefore = abra.currentHP

        runtime.battleRandomOverrides = [0]
        let nightShade = runtime.applyMove(attacker: &gastly, defender: &abra, moveIndex: 0)

        XCTAssertEqual(nightShade.dealtDamage, 20)
        XCTAssertTrue(nightShade.messages.contains("Substitute took damage!"))
        XCTAssertEqual(abra.currentHP, hpBefore)
        XCTAssertEqual(abra.battleEffects.substituteHP, 10)
        XCTAssertTrue(abra.battleEffects.hasSubstitute)
    }

    func testMultiHitMovesUseGBHitCountsAndProjectedDamage() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "MULTI", displayName: "Multi", primaryType: "NORMAL", baseHP: 60, baseAttack: 75, baseDefense: 60, baseSpeed: 70, baseSpecial: 40, startingMoves: ["DOUBLE_KICK", "FURY_ATTACK"]),
                        .init(id: "WALL", displayName: "Wall", primaryType: "NORMAL", baseHP: 90, baseAttack: 50, baseDefense: 55, baseSpeed: 30, baseSpecial: 40, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "DOUBLE_KICK", displayName: "DOUBLE KICK", power: 30, accuracy: 100, maxPP: 30, effect: "ATTACK_TWICE_EFFECT", type: "FIGHTING"),
                        .init(id: "FURY_ATTACK", displayName: "FURY ATTACK", power: 15, accuracy: 100, maxPP: 20, effect: "TWO_TO_FIVE_ATTACKS_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let attacker = runtime.makePokemon(speciesID: "MULTI", level: 18, nickname: "Multi")
        let defender = runtime.makePokemon(speciesID: "WALL", level: 18, nickname: "Wall")

        let doubleKick = try! XCTUnwrap(runtime.content.move(id: "DOUBLE_KICK"))
        let doubleKickPerHit = runtime.resolvedMoveDamage(
            move: doubleKick,
            attacker: attacker,
            defender: defender,
            adjustedAttack: runtime.adjustedOffenseStat(for: attacker, moveType: doubleKick.type, criticalHit: false),
            adjustedDefense: max(1, runtime.adjustedDefenseStat(for: defender, moveType: doubleKick.type, moveEffect: doubleKick.effect, criticalHit: false)),
            typeMultiplier: runtime.totalTypeMultiplier(for: doubleKick.type, defender: defender),
            criticalHit: false
        )
        XCTAssertEqual(
            runtime.projectedDamage(move: doubleKick, attacker: attacker, defender: defender),
            doubleKickPerHit * 2
        )

        var doubleKickAttacker = attacker
        var doubleKickDefender = defender
        runtime.battleRandomOverrides = [0, 255]
        let doubleKickResult = runtime.applyMove(attacker: &doubleKickAttacker, defender: &doubleKickDefender, moveIndex: 0)
        XCTAssertEqual(doubleKickResult.dealtDamage, doubleKickPerHit * 2)
        XCTAssertTrue(doubleKickResult.messages.contains("Hit 2 times!"))

        let furyAttack = try! XCTUnwrap(runtime.content.move(id: "FURY_ATTACK"))
        let furyAttackPerHit = runtime.resolvedMoveDamage(
            move: furyAttack,
            attacker: attacker,
            defender: defender,
            adjustedAttack: runtime.adjustedOffenseStat(for: attacker, moveType: furyAttack.type, criticalHit: false),
            adjustedDefense: max(1, runtime.adjustedDefenseStat(for: defender, moveType: furyAttack.type, moveEffect: furyAttack.effect, criticalHit: false)),
            typeMultiplier: runtime.totalTypeMultiplier(for: furyAttack.type, defender: defender),
            criticalHit: false
        )
        XCTAssertEqual(
            runtime.projectedDamage(move: furyAttack, attacker: attacker, defender: defender),
            furyAttackPerHit * 3
        )

        var furyAttackAttacker = attacker
        var furyAttackDefender = defender
        runtime.battleRandomOverrides = [0, 2, 3, 255]
        let furyAttackResult = runtime.applyMove(attacker: &furyAttackAttacker, defender: &furyAttackDefender, moveIndex: 1)
        XCTAssertEqual(furyAttackResult.dealtDamage, furyAttackPerHit * 5)
        XCTAssertTrue(furyAttackResult.messages.contains("Hit 5 times!"))
    }

    func testMultiHitMovesRespectSubstituteRouting() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "MULTI", displayName: "Multi", primaryType: "NORMAL", baseHP: 60, baseAttack: 75, baseDefense: 60, baseSpeed: 70, baseSpecial: 40, startingMoves: ["DOUBLE_KICK"]),
                        .init(id: "WALL", displayName: "Wall", primaryType: "NORMAL", baseHP: 90, baseAttack: 50, baseDefense: 55, baseSpeed: 30, baseSpecial: 40, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "DOUBLE_KICK", displayName: "DOUBLE KICK", power: 30, accuracy: 100, maxPP: 30, effect: "ATTACK_TWICE_EFFECT", type: "FIGHTING"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var attacker = runtime.makePokemon(speciesID: "MULTI", level: 18, nickname: "Multi")
        var defender = runtime.makePokemon(speciesID: "WALL", level: 18, nickname: "Wall")
        let doubleKick = try! XCTUnwrap(runtime.content.move(id: "DOUBLE_KICK"))
        let damagePerHit = runtime.resolvedMoveDamage(
            move: doubleKick,
            attacker: attacker,
            defender: defender,
            adjustedAttack: runtime.adjustedOffenseStat(for: attacker, moveType: doubleKick.type, criticalHit: false),
            adjustedDefense: max(1, runtime.adjustedDefenseStat(for: defender, moveType: doubleKick.type, moveEffect: doubleKick.effect, criticalHit: false)),
            typeMultiplier: runtime.totalTypeMultiplier(for: doubleKick.type, defender: defender),
            criticalHit: false
        )

        defender.battleEffects.hasSubstitute = true
        defender.battleEffects.substituteHP = damagePerHit * 2 + 5
        let hpBefore = defender.currentHP

        runtime.battleRandomOverrides = [0, 255]
        let result = runtime.applyMove(attacker: &attacker, defender: &defender, moveIndex: 0)

        XCTAssertEqual(result.dealtDamage, damagePerHit * 2)
        XCTAssertTrue(result.messages.contains("Substitute took damage!"))
        XCTAssertTrue(result.messages.contains("Hit 2 times!"))
        XCTAssertEqual(defender.currentHP, hpBefore)
        XCTAssertEqual(defender.battleEffects.lastDamageTaken, 0)
        XCTAssertTrue(defender.battleEffects.hasSubstitute)
        XCTAssertEqual(defender.battleEffects.substituteHP, 5)
    }

    func testTwineedlePoisonsAfterMultiHitResolution() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "STINGER", displayName: "Stinger", primaryType: "BUG", baseHP: 65, baseAttack: 70, baseDefense: 60, baseSpeed: 75, baseSpecial: 45, startingMoves: ["TWINEEDLE"]),
                        .init(id: "TARGET", displayName: "Target", primaryType: "NORMAL", baseHP: 75, baseAttack: 50, baseDefense: 55, baseSpeed: 40, baseSpecial: 45, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TWINEEDLE", displayName: "TWINEEDLE", power: 25, accuracy: 100, maxPP: 20, effect: "TWINEEDLE_EFFECT", type: "BUG"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var attacker = runtime.makePokemon(speciesID: "STINGER", level: 20, nickname: "Stinger")
        var defender = runtime.makePokemon(speciesID: "TARGET", level: 20, nickname: "Target")

        runtime.battleRandomOverrides = [0, 255, 0]
        let result = runtime.applyMove(attacker: &attacker, defender: &defender, moveIndex: 0)

        XCTAssertEqual(defender.majorStatus, .poison)
        XCTAssertTrue(result.messages.contains("Hit 2 times!"))
        XCTAssertTrue(result.messages.contains("Target was poisoned!"))
        XCTAssertTrue(runtime.battleRandomOverrides.isEmpty)
    }

    func testReflectAndResidualEffectsUseBattleState() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "ABRA", displayName: "Abra", primaryType: "PSYCHIC_TYPE", baseHP: 25, baseAttack: 20, baseDefense: 15, baseSpeed: 90, baseSpecial: 105, startingMoves: ["REFLECT"]),
                        .init(id: "SANDSHREW", displayName: "Sandshrew", primaryType: "GROUND", baseHP: 50, baseAttack: 75, baseDefense: 85, baseSpeed: 40, baseSpecial: 30, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "REFLECT", displayName: "REFLECT", power: 0, accuracy: 100, maxPP: 20, effect: "REFLECT_EFFECT", type: "PSYCHIC_TYPE"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let tackle = try! XCTUnwrap(runtime.content.move(id: "TACKLE"))
        let attacker = runtime.makePokemon(speciesID: "SANDSHREW", level: 12, nickname: "Sandshrew")
        let plainDefender = runtime.makePokemon(speciesID: "ABRA", level: 12, nickname: "Abra")
        var reflectDefender = plainDefender
        reflectDefender.battleEffects.hasReflect = true

        XCTAssertLessThan(
            runtime.projectedDamage(move: tackle, attacker: attacker, defender: reflectDefender),
            runtime.projectedDamage(move: tackle, attacker: attacker, defender: plainDefender)
        )

        var poisonedSeeded = runtime.makePokemon(speciesID: "ABRA", level: 12, nickname: "Abra")
        poisonedSeeded.currentHP = 24
        poisonedSeeded.majorStatus = .poison
        poisonedSeeded.isBadlyPoisoned = true
        poisonedSeeded.battleEffects.isSeeded = true
        var drainingTarget = runtime.makePokemon(speciesID: "SANDSHREW", level: 12, nickname: "Sandshrew")
        drainingTarget.currentHP = max(1, drainingTarget.currentHP - 12)
        let hpBefore = poisonedSeeded.currentHP
        let targetHPBefore = drainingTarget.currentHP

        let messages = runtime.applyResidualBattleEffects(to: &poisonedSeeded, opponent: &drainingTarget)

        XCTAssertEqual(messages, ["Abra is hurt by poison!", "Abra is drained by Leech Seed!"])
        XCTAssertLessThan(poisonedSeeded.currentHP, hpBefore)
        XCTAssertGreaterThan(drainingTarget.currentHP, targetHPBefore)
    }

    func testSpeedStageChangesTurnOrderForPresentationBatches() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PLAYERMON", displayName: "Playermon", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 40, baseSpecial: 65, startingMoves: ["TACKLE"]),
                        .init(id: "ENEMYMON", displayName: "Enemymon", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 60, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var playerPokemon = runtime.makePokemon(speciesID: "PLAYERMON", level: 5, nickname: "Playermon")
        playerPokemon.speedStage = 2
        let enemyPokemon = runtime.makePokemon(speciesID: "ENEMYMON", level: 5, nickname: "Enemymon")
        var battle = RuntimeBattleState(
            battleID: "wild_test",
            kind: .wild,
            trainerName: "",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "",
            playerLoseDialogueID: nil,
            postBattleScriptID: nil,
            canRun: true,
            trainerClass: nil,
            sourceTrainerObjectID: nil,
            playerPokemon: playerPokemon,
            enemyParty: [enemyPokemon],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: .moveSelection,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.battleRandomOverrides = [0, 255, 0, 255]
        let batches = runtime.makeTurnPresentationBatches(for: &battle)
        let firstBeat = try! XCTUnwrap(batches.first?.first)

        XCTAssertEqual(firstBeat.activeSide, .player)
        XCTAssertEqual(firstBeat.message, "Playermon used TACKLE!")
    }

    func testEnemyAIPrefersUsefulSetupButAvoidsNoOpDebuffOnSecondTurn() {
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
                    ],
                    trainerAIMoveChoiceModifications: [
                        .init(trainerClass: "RIVAL1", modifications: [2]),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let enemy = runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")
        var player = runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")
        let battle = RuntimeBattleState(
            battleID: "test",
            kind: .trainer,
            trainerName: "BLUE",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "EVENT_TEST",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "win",
            playerLoseDialogueID: "lose",
            postBattleScriptID: nil,
            canRun: false,
            trainerClass: "OPP_RIVAL1",
            sourceTrainerObjectID: nil,
            playerPokemon: player,
            enemyParty: [enemy],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 1,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 0)

        player.attackStage = -6
        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 1)
    }

    func testEnemyAIResolvesSpacedTrainerClassesAndPrefersSwiftOnSecondTurn() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["SWIFT", "TACKLE"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SWIFT", displayName: "SWIFT", power: 60, accuracy: 0, maxPP: 20, effect: "SWIFT_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerAIMoveChoiceModifications: [
                        .init(trainerClass: "BUG CATCHER", modifications: [2]),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        let enemy = runtime.makePokemon(speciesID: "PIDGEY", level: 5, nickname: "Pidgey")
        let player = runtime.makePokemon(speciesID: "RATTATA", level: 5, nickname: "Rattata")
        var battle = RuntimeBattleState(
            battleID: "test",
            kind: .trainer,
            trainerName: "BUG CATCHER",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "EVENT_TEST",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "win",
            playerLoseDialogueID: "lose",
            postBattleScriptID: nil,
            canRun: false,
            trainerClass: "OPP_BUG_CATCHER",
            sourceTrainerObjectID: nil,
            playerPokemon: player,
            enemyParty: [enemy],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 0,
            payDayMoney: 0,
            phase: .moveSelection,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.battleRandomOverrides = [1]
        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 1)

        battle.aiLayer2Encouragement = 1
        XCTAssertEqual(runtime.selectEnemyMoveIndex(battle: battle, enemyPokemon: enemy, playerPokemon: player), 0)
    }

    func testNextEnemySendOutResetsLayer2AIEncouragementCounter() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["SWIFT", "TACKLE"]),
                        .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SWIFT", displayName: "SWIFT", power: 60, accuracy: 0, maxPP: 20, effect: "SWIFT_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerAIMoveChoiceModifications: [
                        .init(trainerClass: "BUG CATCHER", modifications: [2]),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        var battle = RuntimeBattleState(
            battleID: "test",
            kind: .trainer,
            trainerName: "BUG CATCHER",
            trainerSpritePath: nil,
            baseRewardMoney: 0,
            completionFlagID: "EVENT_TEST",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            playerWinDialogueID: "win",
            playerLoseDialogueID: "lose",
            postBattleScriptID: nil,
            canRun: false,
            trainerClass: "OPP_BUG_CATCHER",
            sourceTrainerObjectID: nil,
            playerPokemon: runtime.makePokemon(speciesID: "RATTATA", level: 5, nickname: "Rattata"),
            enemyParty: [
                runtime.makePokemon(speciesID: "PIDGEY", level: 5, nickname: "Pidgey"),
                runtime.makePokemon(speciesID: "PIDGEY", level: 5, nickname: "Pidgeotto"),
            ],
            enemyActiveIndex: 0,
            aiLayer2Encouragement: 1,
            payDayMoney: 0,
            phase: .turnText,
            focusedMoveIndex: 0,
            focusedBagItemIndex: 0,
            focusedPartyIndex: 0,
            partySelectionMode: .optionalSwitch,
            message: "",
            queuedMessages: [],
            pendingAction: nil,
            lastCaptureResult: nil,
            pendingPresentationBatches: [],
            learnMoveState: nil,
            rewardContinuation: nil,
            presentation: .init()
        )

        runtime.scheduleNextEnemySendOut(battle: &battle, nextIndex: 1)
        runtime.cancelBattlePresentation()

        XCTAssertEqual(battle.aiLayer2Encouragement, 0)
    }

    func testBattleIntroPresentationPausesOnTrainerOpeningTextBeforeMoveSelection() throws {
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
        XCTAssertEqual(introSnapshot.battleMessage, "")

        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .introReveal &&
                runtime.currentSnapshot().battle?.battleMessage == "BLUE wants to fight!",
            message: "trainer intro text did not pause on wants to fight"
        )
        let textSnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(textSnapshot.phase, "turnText")
        XCTAssertEqual(textSnapshot.presentation.stage, .introReveal)

        drainBattleText(runtime)
        let readySnapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(readySnapshot.phase, "moveSelection")
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

        advanceBattlePresentationBatch(runtime)
        waitUntil(
            runtime.currentSnapshot().battle?.presentation.stage == .enemySendOut &&
                runtime.currentSnapshot().battle?.presentation.activeSide == .player,
            message: "wild battle did not advance to the player send out presentation",
            maxTicks: 240
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.battleMessage, "Go!")

        waitUntil(
            runtime.battlePresentationTask == nil,
            message: "wild battle player send out did not settle",
            maxTicks: 240
        )

        advanceBattleTextUntilMoveSelection(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.presentation.stage, .commandReady)
        XCTAssertEqual(snapshot.presentation.transitionStyle, .none)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .visible)
    }

    func testPlayerFaintPresentationShowsFaintBeatBeforeTextAndForcedSwitch() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "TESTMON",
                            displayName: "Testmon",
                            baseHP: 39,
                            baseAttack: 12,
                            baseDefense: 12,
                            baseSpeed: 10,
                            baseSpecial: 12,
                            startingMoves: ["GROWL"]
                        ),
                        .init(
                            id: "BACKMON",
                            displayName: "Backmon",
                            baseHP: 45,
                            baseAttack: 20,
                            baseDefense: 20,
                            baseSpeed: 20,
                            baseSpecial: 20,
                            startingMoves: ["GROWL"]
                        ),
                        .init(
                            id: "FOEMON",
                            displayName: "Foemon",
                            baseHP: 45,
                            baseAttack: 255,
                            baseDefense: 20,
                            baseSpeed: 90,
                            baseSpecial: 20,
                            startingMoves: ["TACKLE"]
                        ),
                    ],
                    moves: [
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "TESTMON"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "TESTMON", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "BACKMON", level: 5, nickname: "Backup"),
        ]
        runtime.gameplayState?.playerParty[0].currentHP = 1

        runtime.startWildBattle(speciesID: "FOEMON", level: 5)
        let history = driveBattleUntil(runtime) { $0.phase == "partySelection" }
        let faintIndex = history.firstIndex {
            $0.presentation.stage == .faint && $0.presentation.activeSide == .player
        }
        let faintTextIndex = history.firstIndex {
            $0.presentation.stage == .resultText && $0.battleMessage == "Lead fainted!"
        }

        XCTAssertNotNil(faintIndex)
        XCTAssertNotNil(faintTextIndex)
        if let faintIndex, let faintTextIndex {
            XCTAssertLessThan(faintIndex, faintTextIndex)
        }
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "Bring out which #MON?")
    }

    func testEnemyFaintPresentationShowsFaintBeatBeforeTextAndTrainerReplacementFlow() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(
                            id: "TESTMON",
                            displayName: "Testmon",
                            baseHP: 39,
                            baseAttack: 255,
                            baseDefense: 12,
                            baseSpeed: 90,
                            baseSpecial: 12,
                            startingMoves: ["TACKLE"]
                        ),
                        .init(
                            id: "FOEMON",
                            displayName: "Foemon",
                            baseHP: 20,
                            baseAttack: 12,
                            baseDefense: 12,
                            baseSpeed: 10,
                            baseSpecial: 12,
                            startingMoves: ["GROWL"]
                        ),
                        .init(
                            id: "NEXTMON",
                            displayName: "Nextmon",
                            baseHP: 20,
                            baseAttack: 12,
                            baseDefense: 12,
                            baseSpeed: 10,
                            baseSpecial: 12,
                            startingMoves: ["GROWL"]
                        ),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "GROWL", power: 0, accuracy: 100, maxPP: 40, effect: "ATTACK_DOWN1_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_test_trainer",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [
                                .init(speciesID: "FOEMON", level: 5),
                                .init(speciesID: "NEXTMON", level: 5),
                            ],
                            playerWinDialogueID: "win",
                            playerLoseDialogueID: nil,
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "TESTMON"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "TESTMON", level: 5, nickname: "Lead")]

        runtime.startBattle(id: "opp_test_trainer")
        let history = driveBattleUntil(runtime) { $0.phase == "trainerAboutToUseDecision" }
        let faintIndex = history.firstIndex {
            $0.presentation.stage == .faint && $0.presentation.activeSide == .enemy
        }
        let faintTextIndex = history.firstIndex {
            $0.presentation.stage == .resultText && $0.battleMessage == "Enemy Foemon fainted!"
        }

        XCTAssertNotNil(faintIndex)
        XCTAssertNotNil(faintTextIndex)
        if let faintIndex, let faintTextIndex {
            XCTAssertLessThan(faintIndex, faintTextIndex)
        }
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "Will RED change\n#MON?")
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
        XCTAssertNotNil(
            enemyWindupIndex,
            "enemy attack did not auto-chain after the player action"
        )

        runtime.handle(button: .confirm)
        let enemyResultTimeline = captureBattleTimeline(runtime)
        let resumedEnemyResultIndex = enemyResultTimeline.firstIndex {
            $0.presentation.stage == .resultText &&
                $0.battleMessage == "Squirtle's Attack fell!"
        }
        XCTAssertNotNil(
            resumedEnemyResultIndex,
            "enemy follow-up effect text did not appear"
        )

        if let playerWindupIndex, let enemyWindupIndex {
            XCTAssertGreaterThan(enemyWindupIndex, playerWindupIndex)

            let snapshotBeforeEnemyAction = timeline[enemyWindupIndex]
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

        runtime.startBattle(id: "opp_rival1_1")
        drainBattleText(runtime)

        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
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
        XCTAssertEqual(snapshot.battleMessage, "")
        XCTAssertEqual(snapshot.presentation.stage, .introFlash1)
        XCTAssertEqual(snapshot.presentation.uiVisibility, .hidden)

        drainBattleText(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
        XCTAssertEqual(snapshot.moveSlots.map(\.displayName), ["SCRATCH"])
        XCTAssertEqual(snapshot.presentation.uiVisibility, .visible)

        runtime.battleRandomOverrides = [0, 255, 0]
        runtime.handle(button: .confirm)

        let timeline = captureBattleTimeline(runtime)
        let playerWindupIndex = timeline.firstIndex {
            $0.presentation.stage == .attackWindup &&
                $0.presentation.activeSide == .player &&
                $0.battleMessage == "Charmander used SCRATCH!"
        }
        XCTAssertNotNil(playerWindupIndex, "player attack windup did not begin")

        let enemyWindupIndex = timeline.firstIndex {
            $0.presentation.stage == .attackWindup &&
                $0.presentation.activeSide == .enemy &&
                $0.battleMessage == "Bulbasaur used GROWL!"
        }
        XCTAssertNotNil(enemyWindupIndex, "enemy attack did not auto-chain after the player action")

        let enemyResultIndex = timeline.firstIndex {
            $0.presentation.stage == .resultText &&
                $0.battleMessage == "Charmander's Attack fell!"
        }
        XCTAssertNotNil(enemyResultIndex, "enemy effect text did not appear")

        if let playerWindupIndex, let enemyWindupIndex, let enemyResultIndex {
            XCTAssertGreaterThan(enemyWindupIndex, playerWindupIndex)
            XCTAssertGreaterThan(enemyResultIndex, enemyWindupIndex)
        }

        waitUntil(
            runtime.currentSnapshot().battle?.battleMessage == "Charmander's Attack fell!",
            message: "enemy effect text did not remain on screen for confirmation"
        )
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "turnText")
        XCTAssertEqual(snapshot.textLines, ["Charmander's Attack fell!"])

        drainBattleText(runtime)
        snapshot = try XCTUnwrap(runtime.currentSnapshot().battle)
        XCTAssertEqual(snapshot.phase, "moveSelection")
    }

    func testTrainerLossFinishActionQueuesOnlyBlackoutText() async throws {
        let telemetryPublisher = RecordingTelemetryPublisher()
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "CATERPIE", displayName: "Caterpie", baseHP: 45, baseAttack: 30, baseDefense: 35, baseSpeed: 45, baseSpecial: 20, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_bug_catcher_1",
                            trainerClass: "OPP_BUG_CATCHER",
                            trainerNumber: 1,
                            displayName: "BUG CATCHER",
                            party: [.init(speciesID: "CATERPIE", level: 6)],
                            playerWinDialogueID: "lose",
                            playerLoseDialogueID: "lose",
                            healsPartyAfterBattle: false,
                            preventsBlackoutOnLoss: false,
                            completionFlagID: "EVENT_TEST"
                        ),
                    ]
                )
            ),
            telemetryPublisher: telemetryPublisher,
            audioPlayer: audioPlayer
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_bug_catcher_1")

        var battle = try XCTUnwrap(runtime.gameplayState?.battle)
        battle.phase = .turnText
        battle.pendingAction = .finish(won: false)
        battle.message = ""
        battle.queuedMessages = []

        runtime.advanceBattleText(battle: &battle)

        let expectedMessages = runtime.paginatedBattleMessages([runtime.playerBlackedOutText()])
        XCTAssertEqual(battle.message, expectedMessages.first)
        XCTAssertEqual(battle.queuedMessages, Array(expectedMessages.dropFirst()))
        XCTAssertEqual(audioPlayer.stopAllMusicCount, 1)

        await telemetryPublisher.waitForEventCount(2)
        let events = await telemetryPublisher.recordedEvents()
        let battleEnded = try XCTUnwrap(events.first { $0.kind == .battleEnded })
        XCTAssertEqual(battleEnded.battleID, "opp_bug_catcher_1")
        XCTAssertEqual(battleEnded.details["outcome"], "lost")
    }

    func testWildLossFinishActionQueuesBlackoutTextWithoutTrainerDialogue() throws {
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

        var battle = try XCTUnwrap(runtime.gameplayState?.battle)
        battle.phase = .turnText
        battle.pendingAction = .finish(won: false)
        battle.message = ""
        battle.queuedMessages = []

        runtime.advanceBattleText(battle: &battle)

        let expectedMessages = runtime.paginatedBattleMessages([runtime.playerBlackedOutText()])
        XCTAssertEqual(battle.message, expectedMessages.first)
        XCTAssertEqual(battle.queuedMessages, Array(expectedMessages.dropFirst()))
    }

    func testTrainerLossWithPreventedBlackoutLeavesMoneyAndMapUntouched() throws {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_1",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 1,
                            displayName: "BLUE",
                            party: [.init(speciesID: "BULBASAUR", level: 5)],
                            playerWinDialogueID: "lose",
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
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.money = 777
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.startBattle(id: "opp_rival1_1")
        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishBattle(battle: battle, won: false)
        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.mapID, "OAKS_LAB")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, .init(x: 5, y: 6))
        XCTAssertEqual(runtime.gameplayState?.facing, .up)
        XCTAssertEqual(runtime.playerMoney, 777)
    }
}
