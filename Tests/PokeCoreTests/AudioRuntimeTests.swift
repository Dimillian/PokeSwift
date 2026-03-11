import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

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

        _ = try await waitForSnapshot(enterRuntime) {
            $0.field?.mapID == "REDS_HOUSE_1F" && $0.field?.transition == nil
        }

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
    func testTitleAudioStartsOnceAndDoesNotRestartInMenu() async {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, audioPlayer: audioPlayer)

        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "title")
        XCTAssertEqual(audioPlayer.musicRequests, [.init(trackID: "MUSIC_TITLE_SCREEN", entryID: "default")])

        runtime.handle(button: .start)

        XCTAssertEqual(runtime.scene, .titleMenu)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "title")
        XCTAssertEqual(audioPlayer.musicRequests.count, 1)
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
    func testRepoGeneratedRivalBattleAudioTransitionsFromIntroToBattleToExitAndBack() async throws {
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

        XCTAssertTrue(
            audioPlayer.soundEffectRequests.contains {
                $0.soundEffectID == "SFX_DAMAGE" &&
                    $0.frequencyModifier == 0 &&
                    $0.tempoModifier == 128
            }
        )
    }
    func testBattleFinishStopsTrainerMusicBeforePostBattleDialogue() throws {
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
                        .init(id: "SCRATCH", displayName: "SCRATCH", power: 40, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                        .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                    ],
                    trainerBattles: [
                        .init(
                            id: "opp_rival1_2",
                            trainerClass: "OPP_RIVAL1",
                            trainerNumber: 2,
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
            telemetryPublisher: nil,
            audioPlayer: audioPlayer
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "CHARMANDER"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Charmander")]

        runtime.startBattle(id: "opp_rival1_2")

        guard let battle = runtime.gameplayState?.battle else {
            return XCTFail("expected active battle state")
        }

        runtime.finishBattle(battle: battle, won: true)

        XCTAssertNil(runtime.currentSnapshot().audio)
        XCTAssertEqual(audioPlayer.stopAllMusicCount, 1)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "win")
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
}
