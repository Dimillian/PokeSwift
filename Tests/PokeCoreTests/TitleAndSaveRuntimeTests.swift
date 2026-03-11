import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
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
}
