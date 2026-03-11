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
        XCTAssertEqual(snapshot.field?.objects, [])
    }

    func testSaveAndContinueRestoreGameplayState() async throws {
        let saveStore = InMemorySaveStore()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        runtime.gameplayState?.mapID = "REDS_HOUSE_2F"
        runtime.gameplayState?.playerPosition = TilePoint(x: 2, y: 3)
        runtime.gameplayState?.facing = .left
        runtime.gameplayState?.money = 4242
        runtime.gameplayState?.earnedBadgeIDs = ["BOULDER"]
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        let savedPokemon = runtime.gameplayState?.playerParty.first
        let savedMoves = runtime.gameplayState?.playerParty.first?.moves ?? []
        runtime.gameplayState?.playerParty[0] = runtime.makeConfiguredPokemon(
            speciesID: "SQUIRTLE",
            nickname: "Squirtle",
            level: 6,
            experience: 202,
            dvs: savedPokemon?.dvs ?? .zero,
            statExp: savedPokemon?.statExp ?? .zero,
            currentHP: 19,
            attackStage: 0,
            defenseStage: 0,
            accuracyStage: 0,
            evasionStage: 0,
            moves: savedMoves
        )
        runtime.gameplayState?.objectStates["test_object"] = RuntimeObjectState(position: .init(x: 1, y: 1), facing: .down, visible: false)

        XCTAssertTrue(runtime.saveCurrentGame())
        XCTAssertNotNil(saveStore.envelope)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.experience, 202)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.dvs, savedPokemon?.dvs)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.statExp, savedPokemon?.statExp)

        let resumed = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        resumed.start()
        try? await Task.sleep(for: .milliseconds(1700))
        resumed.handle(button: .start)
        XCTAssertTrue(resumed.menuEntries[1].isEnabled)
        resumed.handle(button: .down)
        resumed.handle(button: .confirm)

        let snapshot = resumed.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.playerPosition, TilePoint(x: 2, y: 3))
        XCTAssertEqual(snapshot.field?.facing, .left)
        XCTAssertEqual(snapshot.party?.pokemon.first?.speciesID, "SQUIRTLE")
        XCTAssertEqual(snapshot.party?.pokemon.first?.level, 6)
        XCTAssertEqual(snapshot.party?.pokemon.first?.experience.total, 202)
        XCTAssertEqual(resumed.gameplayState?.playerParty.first?.dvs, savedPokemon?.dvs)
        XCTAssertEqual(resumed.gameplayState?.playerParty.first?.statExp, savedPokemon?.statExp)
        XCTAssertEqual(snapshot.eventFlags?.activeFlags, [])
        XCTAssertEqual(resumed.playerMoney, 4242)
        XCTAssertEqual(resumed.earnedBadgeIDs, Set(["BOULDER"]))
        XCTAssertFalse(resumed.currentFieldObjects.contains(where: { $0.id == "test_object" }))
    }

    func testUnreadableSaveDisablesContinueAndSurfacesError() {
        let saveStore = InMemorySaveStore()
        saveStore.metadataError = InMemorySaveStoreError.corrupt

        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertFalse(runtime.menuEntries[1].isEnabled)
        XCTAssertNotNil(runtime.currentSaveErrorMessage)
    }

    func testSaveRemainsAvailableDuringFieldMovementAndIdleNPCMotion() async throws {
        let saveStore = InMemorySaveStore()
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .confirm)

        XCTAssertTrue(runtime.saveCurrentGame())

        runtime.gameplayState?.objectStates["test_object"] = RuntimeObjectState(
            position: .init(x: 1, y: 1),
            facing: .left,
            visible: true,
            movementMode: .idle
        )
        runtime.fieldMovementTask = Task { }
        defer {
            runtime.fieldMovementTask?.cancel()
            runtime.fieldMovementTask = nil
        }

        XCTAssertTrue(runtime.canSaveGame)
        XCTAssertTrue(runtime.canLoadGame)
        XCTAssertTrue(runtime.saveCurrentGame())
        XCTAssertTrue(runtime.loadSavedGameFromSidebar())
    }

    func testUnsupportedSaveSchemaFailsDuringContinue() async throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = GameSaveEnvelope(
            metadata: .init(
                schemaVersion: 2,
                variant: .red,
                playthroughID: "legacy",
                playerName: "RED",
                locationName: "Red's House 2F",
                badgeCount: 0,
                playTimeSeconds: 12,
                savedAt: "2026-03-10T20:00:00Z"
            ),
            snapshot: .init(
                mapID: "REDS_HOUSE_2F",
                playerPosition: .init(x: 4, y: 4),
                facing: .down,
                objectStates: [:],
                activeFlags: [],
                money: 3000,
                inventory: [],
                earnedBadgeIDs: [],
                playerName: "RED",
                rivalName: "BLUE",
                playerParty: [
                    .init(
                        speciesID: "SQUIRTLE",
                        nickname: "Squirtle",
                        level: 5,
                        experience: 135,
                        dvs: .zero,
                        statExp: .zero,
                        maxHP: 20,
                        currentHP: 20,
                        attack: 10,
                        defense: 10,
                        speed: 10,
                        special: 10,
                        attackStage: 0,
                        defenseStage: 0,
                        accuracyStage: 0,
                        evasionStage: 0,
                        moves: []
                    ),
                ],
                chosenStarterSpeciesID: "SQUIRTLE",
                rivalStarterSpeciesID: "BULBASAUR",
                pendingStarterSpeciesID: nil,
                activeMapScriptTriggerID: nil,
                activeScriptID: nil,
                activeScriptStep: nil,
                acquisitionRNGState: 1,
                encounterStepCounter: 0,
                playTimeSeconds: 12
            )
        )

        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        runtime.start()
        try? await Task.sleep(for: .milliseconds(1700))
        runtime.handle(button: .start)
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.scene, .titleMenu)
        XCTAssertEqual(runtime.currentLastSaveResult?.operation, "continue")
        XCTAssertEqual(runtime.currentLastSaveResult?.succeeded, false)
        XCTAssertEqual(runtime.currentSaveErrorMessage, "Save schema 2 is not supported.")
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

    func testRepoGeneratedPalletNorthConnectionCrossesIntoRoute1() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "PALLET_TOWN",
            moving: .up,
            expecting: "ROUTE_1",
            requiredFlags: ["EVENT_FOLLOWED_OAK_INTO_LAB"]
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PALLET_TOWN"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_FOLLOWED_OAK_INTO_LAB")

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_1")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_1")
    }

    func testRepoGeneratedRoute1GrassCanTriggerDeterministicWildEncounterAndEscape() throws {
        let runtime = try makeRepoRuntime()
        let grassTile = try findGrassTile(in: runtime, mapID: "ROUTE_1")

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = grassTile
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.setAcquisitionRandomOverrides([0, 0])

        runtime.evaluateWildEncounterIfNeeded()

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.currentSnapshot().battle?.kind, .wild)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPokemon.speciesID, "PIDGEY")
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPokemon.level, 3)

        drainBattleText(runtime)
        runtime.handle(button: .cancel)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_1")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, grassTile)
    }

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
        XCTAssertEqual(audioPlayer.requests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)
        XCTAssertEqual(audioPlayer.requests.last, .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"))

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        runtime.finishWildBattle(battle: battle, won: true)

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_ROUTES1")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.requests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))

        runtime.startWildBattle(speciesID: "RATTATA", level: 3)
        XCTAssertEqual(audioPlayer.requests.last, .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"))

        runtime.finishWildBattleEscape()

        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_ROUTES1")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
        XCTAssertEqual(audioPlayer.requests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))
    }

    func testRepoGeneratedViridianPokecenterNurseHealsParty() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_POKECENTER"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.gameplayState?.playerParty[0].currentHP = 7

        let nurse = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" })
        runtime.interact(with: nurse)

        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.currentHP, runtime.gameplayState?.playerParty.first?.maxHP)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "viridian_pokecenter_nurse_heal")
    }

    func testRepoGeneratedViridianParcelAndOakHandoffAdvanceFlagsAndInventory() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.beginScript(id: "viridian_mart_oaks_parcel")

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .field && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_OAKS_PARCEL") ?? false)
        })

        XCTAssertEqual(runtime.itemQuantity("OAKS_PARCEL"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_OAKS_PARCEL"))

        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_BATTLED_RIVAL_IN_OAKS_LAB")
        runtime.beginScript(id: "oaks_lab_parcel_handoff")

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .field && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_POKEDEX") ?? false)
        })

        XCTAssertEqual(runtime.itemQuantity("OAKS_PARCEL"), 0)
        XCTAssertTrue(runtime.hasFlag("EVENT_OAK_GOT_PARCEL"))
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_POKEDEX"))
        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.gameplayState?.activeScriptID)
        XCTAssertNil(runtime.gameplayState?.activeScriptStep)

        let grassTile = try findGrassTile(in: runtime, mapID: "ROUTE_1")
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_1"
        runtime.gameplayState?.playerPosition = grassTile
        runtime.gameplayState?.facing = .up
        runtime.setAcquisitionRandomOverrides([0, 0])
        runtime.evaluateWildEncounterIfNeeded()

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.currentSnapshot().battle?.kind, .wild)
    }

    func testMissingDialogueDuringScriptFailsCleanlyAndPublishesSessionEvent() async {
        let telemetry = RecordingTelemetryPublisher()
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    scripts: [
                        .init(
                            id: "broken_script",
                            steps: [.init(action: "showDialogue", dialogueID: "missing_dialogue")]
                        ),
                    ]
                )
            ),
            telemetryPublisher: telemetry
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.beginScript(id: "broken_script")

        await telemetry.waitForEventCount(2)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.substate, "field")
        XCTAssertNil(runtime.dialogueState)
        XCTAssertNil(runtime.gameplayState?.activeScriptID)
        XCTAssertNil(runtime.gameplayState?.activeScriptStep)

        let failureEvent = await telemetry.events.last
        XCTAssertEqual(failureEvent?.kind, .scriptFailed)
        XCTAssertEqual(failureEvent?.scriptID, "broken_script")
        XCTAssertEqual(failureEvent?.details["failureKind"], "missingDialogue")
        XCTAssertEqual(failureEvent?.details["missingDialogueID"], "missing_dialogue")
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

    func testFinalizeStarterChoiceSequenceLeavesRivalBallVisibleForDeferredPickupScript() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 7, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.pendingStarterSpeciesID = "SQUIRTLE"

        runtime.finalizeStarterChoiceSequence()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "oaks_lab_received_mon_squirtle")
        XCTAssertFalse(runtime.gameplayState?.objectStates["oaks_lab_poke_ball_squirtle"]?.visible ?? true)
        XCTAssertTrue(runtime.gameplayState?.objectStates["oaks_lab_poke_ball_bulbasaur"]?.visible ?? false)
        XCTAssertEqual(runtime.gameplayState?.rivalStarterSpeciesID, "BULBASAUR")
        XCTAssertEqual(runtime.deferredActions.count, 1)
        guard case let .script(scriptID) = runtime.deferredActions.first else {
            return XCTFail("expected rival pickup script to be queued")
        }
        XCTAssertEqual(scriptID, "oaks_lab_rival_picks_after_squirtle")
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
        scripts: [ScriptManifest] = [],
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
            scripts: scripts,
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

    private func drainBattleUntilComplete(_ runtime: GameRuntime, maxInteractions: Int = 16) {
        var remaining = maxInteractions
        while runtime.scene == .battle {
            XCTAssertGreaterThan(remaining, 0, "battle did not resolve")
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
        maxInteractions: Int = 64
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

    actor RecordingTelemetryPublisher: TelemetryPublisher {
        private(set) var events: [RuntimeSessionEvent] = []

        func publish(snapshot: RuntimeTelemetrySnapshot) async {}

        func publish(event: RuntimeSessionEvent) async {
            events.append(event)
        }

        func waitForEventCount(_ expectedCount: Int, attempts: Int = 40) async {
            for _ in 0..<attempts where events.count < expectedCount {
                try? await Task.sleep(nanoseconds: 5_000_000)
            }
        }
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func makeRepoRuntime(audioPlayer: RuntimeAudioPlaying? = nil) throws -> GameRuntime {
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()
        return GameRuntime(content: content, telemetryPublisher: nil, audioPlayer: audioPlayer)
    }

    private func findConnectionStart(
        from sourceMapID: String,
        moving direction: FacingDirection,
        expecting targetMapID: String,
        requiredFlags: [String] = []
    ) throws -> TilePoint {
        let probe = try makeRepoRuntime()
        let map = try XCTUnwrap(probe.content.map(id: sourceMapID))

        for y in 0..<map.stepHeight {
            for x in 0..<map.stepWidth {
                probe.gameplayState = probe.makeInitialGameplayState()
                probe.scene = .field
                probe.substate = "field"
                probe.gameplayState?.mapID = sourceMapID
                probe.gameplayState?.playerPosition = .init(x: x, y: y)
                probe.gameplayState?.facing = direction
                probe.gameplayState?.activeFlags.formUnion(requiredFlags)
                probe.movePlayer(in: direction)
                if probe.gameplayState?.mapID == targetMapID {
                    return .init(x: x, y: y)
                }
            }
        }

        XCTFail("failed to find a \(direction.rawValue) connection from \(sourceMapID) to \(targetMapID)")
        return .init(x: 0, y: 0)
    }

    private func findGrassTile(in runtime: GameRuntime, mapID: String) throws -> TilePoint {
        let map = try XCTUnwrap(runtime.content.map(id: mapID))
        for y in 0..<map.stepHeight {
            for x in 0..<map.stepWidth {
                let point = TilePoint(x: x, y: y)
                if runtime.isStandingOnGrass(in: map, position: point) {
                    return point
                }
            }
        }

        XCTFail("failed to find grass in \(mapID)")
        return .init(x: 0, y: 0)
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
    private(set) var stopAllMusicCount = 0
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

    func stopAllMusic() {
        stopAllMusicCount += 1
    }

    func completePendingPlayback() {
        guard pendingCompletions.isEmpty == false else { return }
        let completion = pendingCompletions.removeFirst()
        completion()
    }
}

private enum InMemorySaveStoreError: Error {
    case corrupt
}

private final class InMemorySaveStore: @unchecked Sendable, SaveStore {
    var envelope: GameSaveEnvelope?
    var metadataError: Error?

    func hasSaveFile() -> Bool {
        envelope != nil || metadataError != nil
    }

    func loadMetadata() throws -> GameSaveMetadata? {
        if let metadataError {
            throw metadataError
        }
        return envelope?.metadata
    }

    func loadSave() throws -> GameSaveEnvelope? {
        if let metadataError {
            throw metadataError
        }
        return envelope
    }

    func save(_ envelope: GameSaveEnvelope) throws {
        self.envelope = envelope
        metadataError = nil
    }

    func deleteSave() throws {
        envelope = nil
    }
}
