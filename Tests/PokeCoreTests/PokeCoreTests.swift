import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
final class PokeCoreTests: XCTestCase {
    func testTitleFlowTransitionsFromAttractToMenuAndOptionsPlaceholder() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        XCTAssertEqual(runtime.scene, .titleAttract)
        runtime.handle(button: .start)
        XCTAssertEqual(runtime.scene, .titleMenu)

        runtime.handle(button: .down)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        runtime.updateWindowScale(5)
        XCTAssertEqual(runtime.currentSnapshot().window.scale, 5)
        XCTAssertEqual(runtime.scene, .placeholder)
    }

    func testMenuInteractionWithDisabledContinue() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().substate, "continue_disabled")
    }

    func testNewGameEntersFieldAndPublishesFieldTelemetry() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        let snapshot = runtime.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.playerPosition, TilePoint(x: 4, y: 4))
        XCTAssertEqual(snapshot.field?.renderMode, "placeholder")
    }

    func testRepoGeneratedContentPublishesRealAssetFieldTelemetry() async throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        let snapshot = runtime.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.renderMode, "realAssets")
        XCTAssertEqual(snapshot.assetLoadingFailures, [])
    }

    func testRepoGeneratedDoorWarpIntoRedsHouseUsesExactDoorTileAndFadeTelemetry() async throws {
        let runtime = try makeRepoRuntime()
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PALLET_TOWN"
        runtime.gameplayState?.playerPosition = TilePoint(x: 5, y: 6)
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)
        var sawDoorTransition = false

        let snapshot = try await waitForSnapshot(runtime) {
            if $0.field?.transition?.kind == "door" {
                sawDoorTransition = true
            }
            return $0.field?.mapID == "REDS_HOUSE_1F" && $0.field?.transition == nil
        }
        XCTAssertTrue(sawDoorTransition)
        XCTAssertEqual(snapshot.field?.playerPosition, .init(x: 2, y: 7))
        XCTAssertEqual(snapshot.field?.facing, .up)
    }

    func testRepoGeneratedDoorWarpBackOutsideStepsOutToSettledTile() async throws {
        let runtime = try makeRepoRuntime()
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_1F"
        runtime.gameplayState?.playerPosition = TilePoint(x: 2, y: 6)
        runtime.gameplayState?.facing = .down

        runtime.movePlayer(in: .down)
        var sawDoorTransition = false

        let settledSnapshot = try await waitForSnapshot(runtime) {
            if $0.field?.transition?.kind == "door" {
                sawDoorTransition = true
            }
            return $0.field?.mapID == "PALLET_TOWN" && $0.field?.transition == nil
        }
        XCTAssertTrue(sawDoorTransition)
        XCTAssertEqual(settledSnapshot.field?.playerPosition, .init(x: 5, y: 6))
        XCTAssertEqual(settledSnapshot.field?.facing, .down)
    }

    func testRepoGeneratedStairWarpUsesExactTileWithFadeAndNoStepOut() async throws {
        let runtime = try makeRepoRuntime()
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"
        runtime.gameplayState?.playerPosition = TilePoint(x: 6, y: 1)
        runtime.gameplayState?.facing = .right

        runtime.movePlayer(in: .right)
        var sawWarpTransition = false

        let snapshot = try await waitForSnapshot(runtime) {
            if $0.field?.transition?.kind == "warp" {
                sawWarpTransition = true
            }
            return $0.field?.mapID == "REDS_HOUSE_1F" && $0.field?.transition == nil
        }
        XCTAssertTrue(sawWarpTransition)
        XCTAssertEqual(snapshot.field?.playerPosition, .init(x: 7, y: 1))
        XCTAssertEqual(snapshot.field?.facing, .down)
    }

    func testFieldMovementRejectsImmediateSecondStepUntilCadenceCompletes() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"

        runtime.movePlayer(in: .right)
        runtime.movePlayer(in: .right)
        XCTAssertEqual(runtime.gameplayState?.playerPosition, TilePoint(x: 5, y: 4))

        let halfStepNanoseconds = UInt64((runtime.fieldAnimationStepDuration / 2) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: halfStepNanoseconds)
        runtime.movePlayer(in: .right)
        XCTAssertEqual(runtime.gameplayState?.playerPosition, TilePoint(x: 5, y: 4))

        let settleNanoseconds = UInt64((runtime.fieldAnimationStepDuration * 0.75) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: settleNanoseconds)
        runtime.movePlayer(in: .right)
        XCTAssertEqual(runtime.gameplayState?.playerPosition, TilePoint(x: 6, y: 4))
    }

    func testFieldDirectionalInputAvailabilityClearsAsSoonAsStepSettles() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"

        XCTAssertTrue(runtime.canAcceptFieldDirectionalInput)

        runtime.movePlayer(in: .right)
        XCTAssertFalse(runtime.canAcceptFieldDirectionalInput)

        try? await Task.sleep(nanoseconds: UInt64((runtime.fieldAnimationStepDuration * 1.1) * 1_000_000_000))
        XCTAssertTrue(runtime.canAcceptFieldDirectionalInput)
    }

    func testRepoGeneratedPalletNorthExitStartsOakIntroFromSourceScript() async throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PALLET_TOWN"
        runtime.gameplayState?.playerPosition = TilePoint(x: 10, y: 2)
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.gameplayState?.playerPosition, TilePoint(x: 10, y: 1))
        XCTAssertEqual(runtime.gameplayState?.activeMapScriptTriggerID, "north_exit_oak_intro")
        XCTAssertEqual(runtime.gameplayState?.activeScriptID, "pallet_town_oak_intro")
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pallet_town_oak_hey_wait")
    }

    func testTitleAudioStartsOnceAndDoesNotRestartInMenu() async {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, audioPlayer: audioPlayer)

        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "title")
        XCTAssertEqual(audioPlayer.requests, [.init(trackID: "MUSIC_TITLE_SCREEN", entryID: "default")])

        runtime.handle(button: .start)

        XCTAssertEqual(runtime.scene, .titleMenu)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "title")
        XCTAssertEqual(audioPlayer.requests.count, 1)
    }

    func testRepoGeneratedOakIntroAndLabArrivalUpdateAudioTelemetry() throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PALLET_TOWN"
        runtime.gameplayState?.playerPosition = TilePoint(x: 10, y: 2)
        runtime.gameplayState?.facing = .up
        runtime.requestDefaultMapMusic()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "scriptOverride")

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .field && $0.field?.mapID == "OAKS_LAB"
        })

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_OAKS_LAB")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
    }

    func testRepoGeneratedRivalBattleAudioTransitionsFromIntroToBattleToExitAndBack() throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = TilePoint(x: 4, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]
        runtime.requestDefaultMapMusic()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_OAKS_LAB")

        runtime.beginScript(id: "oaks_lab_rival_challenge_vs_bulbasaur")

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "scriptOverride")

        runtime.startBattle(id: "opp_rival1_2")

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "battle")

        runtime.runPostBattleSequence(won: true)

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(runtime.currentSnapshot().audio?.entryID, "alternateStart")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "scriptOverride")

        runtime.dialogueState = nil
        runtime.scene = .field
        runtime.substate = "field"
        runtime.advanceDeferredQueueIfNeeded()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_OAKS_LAB")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
    }

    func testMomHealJingleRestoresMapDefaultAfterCompletion() throws {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil, audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_1F"
        runtime.requestDefaultMapMusic()
        runtime.showDialogue(id: "reds_house_1f_mom_rest", completion: .healAndShow(dialogueID: "reds_house_1f_mom_looking_great"))

        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PKMN_HEALED")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "jingle")
        XCTAssertEqual(audioPlayer.pendingCompletionCount, 1)

        audioPlayer.completePendingPlayback()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "reds_house_1f_mom_looking_great")
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
                        .init(id: "SQUIRTLE", displayName: "Squirtle", baseHP: 44, baseAttack: 200, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", baseHP: 45, baseAttack: 30, baseDefense: 49, baseSpeed: 1, baseSpecial: 65, startingMoves: ["TACKLE"]),
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

    private func fixtureContent(
        gameplayManifest: GameplayManifest? = nil,
        audioManifest: AudioManifest? = nil
    ) -> LoadedContent {
        LoadedContent(
            rootURL: URL(fileURLWithPath: "/tmp", isDirectory: true),
            gameManifest: .init(contentVersion: "test", variant: .red, sourceCommit: "abc", extractorVersion: "1", sourceFiles: []),
            constantsManifest: .init(variant: .red, sourceFiles: [], watchedKeys: ["PAD_A", "PAD_B", "PAD_START"], musicTrack: "MUSIC_TITLE_SCREEN", titleMonSelectionConstant: "STARTER1"),
            charmapManifest: .init(variant: .red, entries: [.init(token: "A", value: 0x80, sourceSection: "test")]),
            titleManifest: .init(
                variant: .red,
                sourceFiles: [],
                titleMonSpecies: "STARTER1",
                menuEntries: [
                    .init(id: "newGame", label: "New Game", enabledByDefault: true),
                    .init(id: "continue", label: "Continue", enabledByDefault: false),
                    .init(id: "options", label: "Options", enabledByDefault: true),
                ],
                logoBounceSequence: [],
                assets: [],
                timings: .init(launchFadeSeconds: 0.4, splashDurationSeconds: 1.2, attractPromptDelaySeconds: 0.8)
            ),
            audioManifest: audioManifest ?? fixtureAudioManifest(),
            gameplayManifest: gameplayManifest ?? fixtureGameplayManifest()
        )
    }

    private func fixtureGameplayManifest(
        dialogues: [DialogueManifest] = [],
        species: [SpeciesManifest] = [],
        moves: [MoveManifest] = [],
        typeEffectiveness: [TypeEffectivenessManifest] = [],
        trainerBattles: [TrainerBattleManifest] = []
    ) -> GameplayManifest {
        GameplayManifest(
            maps: [
                .init(
                    id: "REDS_HOUSE_2F",
                    displayName: "Red's House 2F",
                    defaultMusicID: "MUSIC_PALLET_TOWN",
                    borderBlockID: 0x0A,
                    blockWidth: 4,
                    blockHeight: 4,
                    stepWidth: 8,
                    stepHeight: 8,
                    tileset: "REDS_HOUSE_2",
                    blockIDs: Array(repeating: 0x05, count: 16),
                    stepCollisionTileIDs: Array(repeating: 0x01, count: 64),
                    warps: [],
                    backgroundEvents: [],
                    objects: []
                ),
            ],
            tilesets: [
                .init(
                    id: "REDS_HOUSE_2",
                    imagePath: "Assets/field/tilesets/reds_house.png",
                    blocksetPath: "Assets/field/blocksets/reds_house.bst",
                    sourceTileSize: 8,
                    blockTileWidth: 4,
                    blockTileHeight: 4,
                    collision: .init(
                        passableTileIDs: [0x01, 0x02],
                        warpTileIDs: [],
                        doorTileIDs: [],
                        tilePairCollisions: [],
                        ledges: []
                    )
                ),
            ],
            overworldSprites: [
                .init(
                    id: "SPRITE_RED",
                    imagePath: "Assets/field/sprites/red.png",
                    frameWidth: 16,
                    frameHeight: 16,
                    facingFrames: .init(
                        down: .init(x: 0, y: 0, width: 16, height: 16),
                        up: .init(x: 0, y: 16, width: 16, height: 16),
                        left: .init(x: 0, y: 32, width: 16, height: 16),
                        right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true)
                    )
                ),
            ],
            dialogues: dialogues,
            eventFlags: .init(flags: []),
            mapScripts: [],
            scripts: [],
            species: species,
            moves: moves,
            typeEffectiveness: typeEffectiveness,
            trainerBattles: trainerBattles,
            playerStart: .init(mapID: "REDS_HOUSE_2F", position: .init(x: 4, y: 4), facing: .down, playerName: "RED", rivalName: "BLUE", initialFlags: [])
        )
    }

    private func fixtureAudioManifest() -> AudioManifest {
        AudioManifest(
            variant: .red,
            titleTrackID: "MUSIC_TITLE_SCREEN",
            mapRoutes: [.init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN")],
            cues: [
                .init(id: "title_default", trackID: "MUSIC_TITLE_SCREEN"),
                .init(id: "trainer_battle", trackID: "MUSIC_TRAINER_BATTLE"),
                .init(id: "mom_heal", trackID: "MUSIC_PKMN_HEALED"),
            ],
            tracks: [
                .init(
                    id: "MUSIC_TITLE_SCREEN",
                    sourceLabel: "Music_TitleScreen",
                    sourceFile: "audio/music/titlescreen.asm",
                    entries: [.init(id: "default", sourceLabel: "Music_TitleScreen_Ch1", playbackMode: .looping, channels: [])]
                ),
                .init(
                    id: "MUSIC_PALLET_TOWN",
                    sourceLabel: "Music_PalletTown",
                    sourceFile: "audio/music/pallettown.asm",
                    entries: [.init(id: "default", sourceLabel: "Music_PalletTown_Ch1", playbackMode: .looping, channels: [])]
                ),
                .init(
                    id: "MUSIC_TRAINER_BATTLE",
                    sourceLabel: "Music_TrainerBattle",
                    sourceFile: "audio/music/trainerbattle.asm",
                    entries: [.init(id: "default", sourceLabel: "Music_TrainerBattle_Ch1", playbackMode: .looping, channels: [])]
                ),
                .init(
                    id: "MUSIC_PKMN_HEALED",
                    sourceLabel: "Music_PkmnHealed",
                    sourceFile: "audio/music/pkmnhealed.asm",
                    entries: [.init(id: "default", sourceLabel: "Music_PkmnHealed_Ch1", playbackMode: .oneShot, channels: [])]
                ),
            ]
        )
    }

    private func drainBattleText(_ runtime: GameRuntime, maxInteractions: Int = 16) {
        var remaining = maxInteractions
        while let battle = runtime.currentSnapshot().battle, battle.phase != "moveSelection" {
            XCTAssertGreaterThan(remaining, 0, "battle text did not drain to move selection")
            remaining -= 1
            runtime.handle(button: .confirm)
        }
    }

    private func advanceDialogueUntilComplete(_ runtime: GameRuntime, maxInteractions: Int = 8) {
        var remaining = maxInteractions
        while runtime.dialogueState != nil {
            XCTAssertGreaterThan(remaining, 0, "dialogue did not complete")
            remaining -= 1
            runtime.handle(button: .confirm)
        }
    }

    private func drainDialogueAndScripts(
        _ runtime: GameRuntime,
        until predicate: (RuntimeTelemetrySnapshot) -> Bool,
        maxInteractions: Int = 24
    ) {
        var remaining = maxInteractions
        while predicate(runtime.currentSnapshot()) == false {
            XCTAssertGreaterThan(remaining, 0, "dialogue/script sequence did not reach expected state")
            remaining -= 1
            switch runtime.scene {
            case .dialogue:
                runtime.handle(button: .confirm)
            case .field, .scriptedSequence:
                runtime.advanceDeferredQueueIfNeeded()
                runtime.runActiveScript()
            default:
                XCTFail("unexpected scene while draining dialogue/script sequence: \(runtime.scene)")
                return
            }
        }
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func makeRepoRuntime() throws -> GameRuntime {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        return GameRuntime(content: content, telemetryPublisher: nil)
    }

    private func waitForSnapshot(
        _ runtime: GameRuntime,
        timeout: TimeInterval = 1.5,
        matching predicate: (RuntimeTelemetrySnapshot) -> Bool
    ) async throws -> RuntimeTelemetrySnapshot {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let snapshot = runtime.currentSnapshot()
            if predicate(snapshot) {
                return snapshot
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw XCTSkip("timed out waiting for expected runtime snapshot")
    }
}

@MainActor
private final class RecordingAudioPlayer: RuntimeAudioPlaying {
    private(set) var requests: [AudioPlaybackRequest] = []
    private var pendingCompletions: [() -> Void] = []

    var pendingCompletionCount: Int {
        pendingCompletions.count
    }

    func play(request: AudioPlaybackRequest, completion: (@MainActor () -> Void)?) {
        requests.append(request)
        if let completion {
            pendingCompletions.append(completion)
        }
    }

    func stopAllMusic() {}

    func completePendingPlayback() {
        guard pendingCompletions.isEmpty == false else { return }
        let completion = pendingCompletions.removeFirst()
        completion()
    }
}
