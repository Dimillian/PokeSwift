import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
private func fixtureBattleLifecycleAudioManifest() -> AudioManifest {
    let base = fixtureAudioManifest()
    return AudioManifest(
        variant: base.variant,
        titleTrackID: base.titleTrackID,
        mapRoutes: base.mapRoutes,
        cues: base.cues,
        tracks: base.tracks,
        soundEffects: base.soundEffects + [
            .init(
                id: "SFX_CRY_00",
                sourceLabel: "SFX_Cry00_1",
                sourceFile: "audio/sfx/cry00_1.asm",
                bank: 1,
                priority: 90,
                order: 90,
                requestedChannels: [5, 6, 8],
                channels: []
            ),
            .init(
                id: "SFX_CRY_01",
                sourceLabel: "SFX_Cry01_1",
                sourceFile: "audio/sfx/cry01_1.asm",
                bank: 1,
                priority: 91,
                order: 91,
                requestedChannels: [5, 6, 8],
                channels: []
            ),
            .init(
                id: "SFX_FAINT_FALL",
                sourceLabel: "SFX_Faint_Fall",
                sourceFile: "audio/sfx/faint_fall.asm",
                bank: 2,
                priority: 103,
                order: 103,
                requestedChannels: [5],
                channels: []
            ),
            .init(
                id: "SFX_FAINT_THUD",
                sourceLabel: "SFX_Faint_Thud",
                sourceFile: "audio/sfx/faint_thud.asm",
                bank: 2,
                priority: 98,
                order: 98,
                requestedChannels: [5, 8],
                channels: []
            ),
        ]
    )
}

@MainActor
extension PokeCoreTests {
    func testRepoGeneratedWildBattleExitRestoresRouteMusic() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        runtime.requestDefaultMapMusic()
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"))

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishWildBattle(battle: battle, won: true)

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_ROUTES1")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))

        runtime.startWildBattle(speciesID: "RATTATA", level: 3)
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"))

        runtime.finishWildBattleEscape()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_ROUTES1")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))
    }
    func testRepoGeneratedDoorAndWarpTransitionsChooseExpectedSoundEffects() async throws {
        let enterAudioPlayer = RecordingAudioPlayer()
        let enterRuntime = try makeRepoRuntime(audioPlayer: enterAudioPlayer)
        enterRuntime.gameplayState = enterRuntime.makeInitialGameplayState()
        enterRuntime.scene = .field
        enterRuntime.substate = "field"
        enterRuntime.gameplayState?.mapID = "PALLET_TOWN"
        enterRuntime.gameplayState?.playerPosition = TilePoint(x: 5, y: 6)
        enterRuntime.gameplayState?.facing = .up

        enterRuntime.movePlayer(in: .up)
        XCTAssertEqual(enterAudioPlayer.soundEffectRequests.last?.soundEffectID, "SFX_GO_INSIDE")

        let warpAudioPlayer = RecordingAudioPlayer()
        let warpRuntime = try makeRepoRuntime(audioPlayer: warpAudioPlayer)
        warpRuntime.gameplayState = warpRuntime.makeInitialGameplayState()
        warpRuntime.scene = .field
        warpRuntime.substate = "field"
        warpRuntime.gameplayState?.mapID = "REDS_HOUSE_2F"
        warpRuntime.gameplayState?.playerPosition = TilePoint(x: 6, y: 1)
        warpRuntime.gameplayState?.facing = .right

        warpRuntime.movePlayer(in: .right)
        XCTAssertEqual(warpAudioPlayer.soundEffectRequests.last?.soundEffectID, "SFX_GO_OUTSIDE")
    }
    func testRepoGeneratedOakIntroAndLabArrivalUpdateAudioTelemetry() throws {
        let content = try loadRepoContent()
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
    func testRepoGeneratedManualTrainerInteractionUsesEncounterMusicThenFieldIntroBeforeBattle() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        var state = runtime.makeInitialGameplayState()
        state.mapID = "VIRIDIAN_FOREST"
        state.playerPosition = TilePoint(x: 29, y: 33)
        state.facing = .right
        state.chosenStarterSpeciesID = "SQUIRTLE"
        state.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 8, nickname: "Squirtle")]
        state.money = 3001
        state.blackoutCheckpoint = .init(
            mapID: "VIRIDIAN_POKECENTER",
            position: .init(x: 3, y: 7),
            facing: .down
        )
        runtime.gameplayState = state
        runtime.scene = .field
        runtime.substate = "field"

        runtime.handle(button: .confirm)

        waitUntil(
            runtime.currentSnapshot().dialogue != nil,
            message: "manual trainer interaction did not show the field intro dialogue"
        )

        XCTAssertNil(runtime.currentSnapshot().battle)
        XCTAssertNil(runtime.currentSnapshot().field?.alert)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_MEET_MALE_TRAINER")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "trainerEncounter")
        XCTAssertEqual(
            Array(audioPlayer.musicRequests.prefix(1)),
            [
                .init(trackID: "MUSIC_MEET_MALE_TRAINER", entryID: "default"),
            ]
        )

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .battle && $0.battle?.battleID == "opp_bug_catcher_1"
        })

        waitUntil(
            runtime.currentSnapshot().battle?.battleID == "opp_bug_catcher_1",
            message: "manual trainer interaction did not start the battle"
        )

        XCTAssertEqual(runtime.currentSnapshot().battle?.battleID, "opp_bug_catcher_1")
        XCTAssertNil(runtime.currentSnapshot().field?.alert)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "battle")
        XCTAssertEqual(
            Array(audioPlayer.musicRequests.prefix(2)),
            [
                .init(trackID: "MUSIC_MEET_MALE_TRAINER", entryID: "default"),
                .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"),
            ]
        )
    }
    func testDialoguePageEventsBlockProgressUntilSoundCompletes() {
        let audioPlayer = RecordingAudioPlayer()
        let audioManifest = AudioManifest(
            variant: .red,
            titleTrackID: "MUSIC_TITLE_SCREEN",
            mapRoutes: [],
            cues: [],
            tracks: [],
            soundEffects: [
                .init(
                    id: "SFX_LEVEL_UP",
                    sourceLabel: "SFX_LevelUp",
                    sourceFile: "audio/sfx/levelup.asm",
                    bank: 2,
                    priority: 95,
                    order: 95,
                    requestedChannels: [5, 6, 7],
                    channels: []
                ),
                .init(
                    id: "SFX_PRESS_AB",
                    sourceLabel: "SFX_PressAB",
                    sourceFile: "audio/sfx/pressab.asm",
                    bank: 1,
                    priority: 62,
                    order: 62,
                    requestedChannels: [5],
                    channels: []
                ),
            ]
        )
        let gameplayManifest = fixtureGameplayManifest(
            dialogues: [
                .init(
                    id: "dialogue_with_audio",
                    pages: [
                        .init(
                            lines: ["You found", "something!"],
                            waitsForPrompt: true,
                            events: [
                                .init(kind: .soundEffect, soundEffectID: "SFX_LEVEL_UP"),
                                .init(kind: .soundEffect, soundEffectID: "SFX_PRESS_AB", waitForCompletion: false),
                            ]
                        ),
                    ]
                ),
            ]
        )
        let runtime = GameRuntime(
            content: fixtureContent(gameplayManifest: gameplayManifest, audioManifest: audioManifest),
            telemetryPublisher: nil,
            audioPlayer: audioPlayer
        )

        runtime.showDialogue(id: "dialogue_with_audio", completion: .returnToField)

        XCTAssertEqual(audioPlayer.soundEffectRequests.map(\.soundEffectID), ["SFX_LEVEL_UP"])
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "dialogue_with_audio")

        audioPlayer.completePendingPlayback()

        XCTAssertEqual(audioPlayer.soundEffectRequests.map(\.soundEffectID), ["SFX_LEVEL_UP", "SFX_PRESS_AB"])
        runtime.handle(button: .confirm)
        XCTAssertNil(runtime.currentSnapshot().dialogue)
    }
    func testBlockedMovementCollisionSoundDoesNotStackUntilPlaybackCompletes() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 0)
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)
        runtime.movePlayer(in: .up)

        XCTAssertEqual(audioPlayer.soundEffectRequests.map(\.soundEffectID), ["SFX_COLLISION"])

        audioPlayer.completePendingPlayback()
        runtime.movePlayer(in: .up)

        XCTAssertEqual(audioPlayer.soundEffectRequests.map(\.soundEffectID), ["SFX_COLLISION", "SFX_COLLISION"])
    }

    func testDialogueWithoutBlockingEventsAdvancesEvenIfBlockingFlagLeaked() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(
                            id: "plain_dialogue",
                            pages: [
                                .init(lines: ["Page 1"], waitsForPrompt: true),
                                .init(lines: ["Page 2"], waitsForPrompt: true),
                            ]
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.showDialogue(id: "plain_dialogue", completion: .returnToField)
        runtime.isDialogueAudioBlockingInput = true

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "plain_dialogue")
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.pageIndex, 1)
    }

    func testRepoGeneratedRivalBattleAudioTransitionsFromIntroToBattleToExitAndBack() async throws {
        let content = try loadRepoContent()
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

        runtime.completeTrainerBattleDialogue(
            won: true,
            preventsBlackoutOnLoss: true,
            postBattleScriptID: "oaks_lab_rival_exit_after_battle",
            sourceTrainerObjectID: nil
        )

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(runtime.currentSnapshot().audio?.entryID, "alternateStart")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "scriptOverride")

        advanceDialogueUntilComplete(runtime)
        let settledSnapshot = try await waitForSnapshot(runtime) {
            $0.audio?.trackID == "MUSIC_OAKS_LAB" &&
                $0.audio?.reason == "mapDefault" &&
                $0.field?.objects.first(where: { $0.id == "oaks_lab_rival" }) == nil
        }

        XCTAssertEqual(settledSnapshot.audio?.trackID, "MUSIC_OAKS_LAB")
        XCTAssertEqual(settledSnapshot.audio?.reason, "mapDefault")
        XCTAssertEqual(settledSnapshot.field?.facing, .down)
    }
    func testRepoGeneratedBattleMoveUsesExtractedMoveSoundEffect() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = TilePoint(x: 4, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_2")
        drainBattleText(runtime)
        runtime.battleRandomOverrides = [0, 255]
        runtime.handle(button: .confirm)
        advanceBattlePresentationBatch(runtime)

        waitUntil(
            audioPlayer.soundEffectRequests.contains {
                $0.soundEffectID == "SFX_DAMAGE" &&
                    $0.frequencyModifier == 0 &&
                    $0.tempoModifier == 128
            },
            message: "battle move did not request the extracted damage sound effect"
        )
    }

    func testWildCaptureUsesCaughtAndDexAddedSoundEffects() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

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
        let confirmCountBeforeThrow = audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count
        runtime.handle(button: .confirm)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(
            audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count,
            confirmCountBeforeThrow
        )
        XCTAssertTrue(audioPlayer.soundEffectRequests.map(\.soundEffectID).contains("SFX_CAUGHT_MON"))
        XCTAssertTrue(audioPlayer.soundEffectRequests.map(\.soundEffectID).contains("SFX_DEX_PAGE_ADDED"))
    }

    func testRepoGeneratedOrdinaryTrainerLossBlackoutsToViridianCityAndRestartsMapMusic() async throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        var state = runtime.makeInitialGameplayState()
        state.mapID = "VIRIDIAN_POKECENTER"
        state.playerPosition = .init(x: 3, y: 4)
        state.facing = .up
        state.chosenStarterSpeciesID = "SQUIRTLE"
        state.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 8, nickname: "Squirtle")]
        state.playerParty[0].currentHP = 7
        state.money = 3001
        runtime.gameplayState = state
        runtime.scene = .field
        runtime.substate = "field"
        runtime.requestDefaultMapMusic()

        let nurse = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" })
        runtime.interact(with: nurse)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.fieldHealing?.phase == .healedJingle
        }
        audioPlayer.completePendingPlayback()
        _ = try await waitForSnapshot(runtime) {
            $0.dialogue?.dialogueID == "pokemon_center_fighting_fit"
        }
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "VIRIDIAN_CITY", position: .init(x: 23, y: 26), facing: .down)
        )

        runtime.gameplayState?.mapID = "VIRIDIAN_FOREST"
        runtime.gameplayState?.playerPosition = TilePoint(x: 29, y: 33)
        runtime.gameplayState?.facing = .right

        runtime.startBattle(id: "opp_bug_catcher_1")
        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishBattle(battle: battle, won: false)
        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.mapID, "VIRIDIAN_CITY")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, TilePoint(x: 23, y: 26))
        XCTAssertEqual(runtime.gameplayState?.facing, .down)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_CITIES1")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_CITIES1", entryID: "default"))
        XCTAssertEqual(runtime.playerMoney, 1500)
        let lead = try XCTUnwrap(runtime.gameplayState?.playerParty.first)
        XCTAssertEqual(lead.currentHP, lead.maxHP)
    }

    func testRepoGeneratedWildLossUsesFallbackBlackoutCheckpointAndMoneyPenalty() async throws {
        let audioPlayer = RecordingAudioPlayer()
        let telemetryPublisher = RecordingTelemetryPublisher()
        let runtime = try makeRepoRuntime(telemetryPublisher: telemetryPublisher, audioPlayer: audioPlayer)

        var state = runtime.makeInitialGameplayState()
        state.mapID = "ROUTE_1"
        state.playerPosition = .init(x: 10, y: 18)
        state.facing = .up
        state.chosenStarterSpeciesID = "SQUIRTLE"
        state.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        state.playerParty[0].currentHP = 1
        state.money = 321
        runtime.gameplayState = state
        runtime.scene = .field
        runtime.substate = "field"

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishWildBattle(battle: battle, won: false)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.mapID, "PALLET_TOWN")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, .init(x: 5, y: 6))
        XCTAssertEqual(runtime.gameplayState?.facing, .down)
        XCTAssertEqual(runtime.playerMoney, 160)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_PALLET_TOWN", entryID: "default"))
        let lead = try XCTUnwrap(runtime.gameplayState?.playerParty.first)
        XCTAssertEqual(lead.currentHP, lead.maxHP)

        await telemetryPublisher.waitForEventCount(4)
        let events = await telemetryPublisher.recordedEvents()
        let battleEnded = try XCTUnwrap(events.first { $0.kind == .battleEnded })
        XCTAssertEqual(battleEnded.battleID, battle.battleID)
        XCTAssertEqual(battleEnded.details["outcome"], "lost")
    }

    func testRepoGeneratedTrainerLossResetsAutoMovedTrainerBeforeBlackout() async throws {
        let runtime = try makeRepoRuntime()

        var state = runtime.makeInitialGameplayState()
        state.mapID = "VIRIDIAN_FOREST"
        state.playerPosition = TilePoint(x: 25, y: 33)
        state.facing = .right
        state.chosenStarterSpeciesID = "SQUIRTLE"
        state.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 8, nickname: "Squirtle")]
        state.blackoutCheckpoint = .init(
            mapID: "VIRIDIAN_POKECENTER",
            position: .init(x: 3, y: 7),
            facing: .down
        )
        runtime.gameplayState = state
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.objectStates["viridian_forest_bug_catcher_1"] = .init(
            position: .init(x: 27, y: 33),
            facing: .left,
            visible: true
        )

        let displacedTrainer = try XCTUnwrap(runtime.gameplayState?.objectStates["viridian_forest_bug_catcher_1"])
        XCTAssertEqual(displacedTrainer.position, TilePoint(x: 27, y: 33))

        runtime.startBattle(
            id: "opp_bug_catcher_1",
            sourceTrainerObjectID: "viridian_forest_bug_catcher_1"
        )

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishBattle(battle: battle, won: false)
        advanceDialogueUntilComplete(runtime)

        let resetTrainer = try XCTUnwrap(runtime.gameplayState?.objectStates["viridian_forest_bug_catcher_1"])
        XCTAssertEqual(resetTrainer.position, TilePoint(x: 30, y: 33))
        XCTAssertEqual(resetTrainer.facing, .left)
        XCTAssertEqual(runtime.gameplayState?.mapID, "VIRIDIAN_POKECENTER")
    }

    func testTrainerVictoryMusicStartsInBattleBeforePostBattleDialogue() {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "win", pages: [.init(lines: ["You win"], waitsForPrompt: true)]),
                        .init(id: "lose", pages: [.init(lines: ["You lose"], waitsForPrompt: true)]),
                    ],
                    species: [
                        .init(id: "CHARMANDER", displayName: "Charmander", baseExp: 62, growthRate: .mediumSlow, baseHP: 39, baseAttack: 52, baseDefense: 43, baseSpeed: 65, baseSpecial: 50, startingMoves: ["SCRATCH"]),
                        .init(id: "BULBASAUR", displayName: "Bulbasaur", baseExp: 64, growthRate: .mediumSlow, baseHP: 45, baseAttack: 49, baseDefense: 49, baseSpeed: 45, baseSpecial: 65, startingMoves: ["TACKLE"]),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 500, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_2",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 2,
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
            telemetryPublisher: nil,
            audioPlayer: audioPlayer
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.gameplayState?.money = 3000
        runtime.scene = .battle
        runtime.substate = "battle"

        var battle = RuntimeBattleState(
            battleID: "opp_rival1_2",
            kind: .trainer,
            trainerName: "BLUE",
            trainerSpritePath: nil,
            baseRewardMoney: 10,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: true,
            playerWinDialogueID: "win",
            playerLoseDialogueID: "lose",
            postBattleScriptID: nil,
            canRun: false,
            trainerClass: "OPP_RIVAL1",
            sourceTrainerObjectID: nil,
            playerPokemon: runtime.makePokemon(speciesID: "CHARMANDER", level: 6, nickname: "Charmander"),
            enemyParty: [runtime.makePokemon(speciesID: "BULBASAUR", level: 5, nickname: "Bulbasaur")],
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
            rewardContinuation: .finishTrainerWin(payout: 60),
            presentation: .init()
        )
        runtime.gameplayState?.battle = battle

        runtime.resumeRewardContinuation(battle: &battle)
        runtime.gameplayState?.battle = battle

        XCTAssertTrue(runtime.currentSnapshot().battle?.battleMessage.contains("defeated") == true)
        XCTAssertTrue(runtime.currentSnapshot().battle?.battleMessage.contains("BLUE") == true)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_DEFEATED_TRAINER")
        XCTAssertEqual(runtime.scene, .battle)

        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_DEFEATED_TRAINER", entryID: "default"))
        XCTAssertEqual(audioPlayer.stopAllMusicCount, 0)

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().battle?.battleMessage, "RED got ¥60 for\nwinning!")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "win")
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_DEFEATED_TRAINER")
    }

    func testMomHealJingleRestoresMapDefaultAfterCompletion() throws {
        let content = try loadRepoContent()
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

    func testWildVictoryMusicStartsBeforeExperienceAndLevelUpSoundUsesLevelMessage() {
        let audioPlayer = RecordingAudioPlayer()
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
                            baseAttack: 255,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["SCRATCH"]
                        ),
                        .init(
                            id: "PIDGEY",
                            displayName: "Pidgey",
                            primaryType: "NORMAL",
                            secondaryType: "FLYING",
                            baseExp: 64,
                            growthRate: .mediumSlow,
                            baseHP: 1,
                            baseAttack: 45,
                            baseDefense: 40,
                            baseSpeed: 56,
                            baseSpecial: 35,
                            startingMoves: ["GUST"]
                        ),
                    ],
                    moves: [
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 120, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "GUST", displayName: "GUST", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "FLYING"),
                    ]
                )
            ),
            telemetryPublisher: nil,
            audioPlayer: audioPlayer
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makeConfiguredPokemon(
            speciesID: "CHARMANDER",
            nickname: "Charmander",
            level: 5,
            experience: 135,
            dvs: .zero,
            statExp: .zero,
            currentHP: nil,
            attackStage: 0,
            defenseStage: 0,
            speedStage: 0,
            specialStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: nil
        )]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 5)
        drainBattleText(runtime)
        runtime.handle(button: .confirm)

        advanceBattleByConfirmingUntil(
            runtime,
            message: "wild battle did not reach the enemy faint text",
            maxTicks: 240
        ) {
            runtime.currentSnapshot().battle?.battleMessage.contains("fainted") == true
        }

        let confirmCountBeforeRewardBatch = audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count
        runtime.handle(button: .confirm)

        advanceBattleByConfirmingUntil(
            runtime,
            message: "wild victory music did not start before the experience text",
            maxTicks: 240
        ) {
            runtime.currentSnapshot().battle?.battleMessage.contains("gained") == true &&
                runtime.currentSnapshot().battle?.battleMessage.contains("EXP") == true &&
                runtime.currentSnapshot().audio?.trackID == "MUSIC_DEFEATED_WILD_MON" &&
                runtime.scene == .battle
        }
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_DEFEATED_WILD_MON", entryID: "default"))
        XCTAssertEqual(
            audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count,
            confirmCountBeforeRewardBatch
        )

        let confirmCountBeforeLevelUpBeat = audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count
        runtime.handle(button: .confirm)

        advanceBattleByConfirmingUntil(
            runtime,
            message: "battle reward did not reach the level-up message",
            maxTicks: 240
        ) {
            runtime.currentSnapshot().battle?.battleMessage.contains("grew to") == true &&
                runtime.currentSnapshot().battle?.battleMessage.contains("Lv6") == true
        }
        XCTAssertEqual(audioPlayer.soundEffectRequests.last?.soundEffectID, "SFX_LEVEL_UP")
        XCTAssertEqual(audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_LEVEL_UP" }.count, 1)
        XCTAssertEqual(
            audioPlayer.soundEffectRequests.filter { $0.soundEffectID == "SFX_PRESS_AB" }.count,
            confirmCountBeforeLevelUpBeat
        )
    }

    func testMusicToggleStopsPlaybackAndResumesCurrentTrack() {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.requestDefaultMapMusic()

        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_PALLET_TOWN", entryID: "default"))
        XCTAssertTrue(runtime.isMusicEnabled)

        runtime.toggleMusicEnabled()

        XCTAssertFalse(runtime.isMusicEnabled)
        XCTAssertEqual(audioPlayer.stopAllMusicCount, 1)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")

        runtime.toggleMusicEnabled()

        XCTAssertTrue(runtime.isMusicEnabled)
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_PALLET_TOWN", entryID: "default"))
    }

    func testDisabledMusicDefersPlaybackUntilReenabled() {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.toggleMusicEnabled()

        runtime.requestDefaultMapMusic()

        XCTAssertEqual(audioPlayer.musicRequests, [])
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_PALLET_TOWN")

        runtime.toggleMusicEnabled()

        XCTAssertEqual(audioPlayer.musicRequests, [.init(trackID: "MUSIC_PALLET_TOWN", entryID: "default")])
    }
}
