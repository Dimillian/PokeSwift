import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
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
    func testRepoGeneratedViridianInteriorsLoadNpcDialogue() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"

        runtime.gameplayState?.mapID = "VIRIDIAN_SCHOOL_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 6)
        runtime.gameplayState?.facing = .up
        let brunetteGirl = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_school_house_brunette_girl" })
        runtime.interact(with: brunetteGirl)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "viridian_school_house_brunette_girl")

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.mapID = "VIRIDIAN_NICKNAME_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 4)
        runtime.gameplayState?.facing = .down
        let spearow = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_nickname_house_spearow" })
        runtime.interact(with: spearow)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "viridian_nickname_house_spearow")
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
}
