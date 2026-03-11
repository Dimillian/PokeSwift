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
        runtime.beginNewGame()

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
        XCTAssertEqual(saveStore.envelope?.metadata.schemaVersion, 5)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.experience, 202)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.dvs, savedPokemon?.dvs)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.statExp, savedPokemon?.statExp)
        let encodedSave = try XCTUnwrap(try? JSONEncoder().encode(saveStore.envelope))
        XCTAssertFalse(String(decoding: encodedSave, as: UTF8.self).contains("acquisitionRNGState"))

        let resumed = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertTrue(resumed.menuEntries[1].isEnabled)
        XCTAssertTrue(resumed.continueFromTitleMenu())

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
        runtime.beginNewGame()

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
                encounterStepCounter: 0,
                playTimeSeconds: 12
            )
        )

        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertFalse(runtime.continueFromTitleMenu())

        XCTAssertNotEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.currentLastSaveResult?.operation, "continue")
        XCTAssertEqual(runtime.currentLastSaveResult?.succeeded, false)
        XCTAssertEqual(runtime.currentSaveErrorMessage, "Save schema 2 is not supported.")
    }

    func testNewGameSeedsRuntimeRNGFromInjectedEntropy() {
        let expectedSeed: UInt64 = 0x0123_4567_89ab_cdef
        let runtime = GameRuntime(
            content: fixtureContent(),
            telemetryPublisher: nil,
            runtimeRNGSeedSource: { expectedSeed }
        )

        runtime.beginNewGame()

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.nextAcquisitionRandomByte(), expectedRuntimeRandomByte(afterSeedingWith: expectedSeed))
    }

    func testLegacySchemaThreeSaveIgnoresPersistedRNGStateOnContinue() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 3,
            acquisitionRNGState: 1
        )

        let expectedSeed: UInt64 = 0x0123_4567_89ab_cdef
        let runtime = GameRuntime(
            content: fixtureContent(),
            telemetryPublisher: nil,
            saveStore: saveStore,
            runtimeRNGSeedSource: { expectedSeed }
        )

        XCTAssertTrue(runtime.continueFromTitleMenu())

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.nextAcquisitionRandomByte(), expectedRuntimeRandomByte(afterSeedingWith: expectedSeed))
    }

    func testLegacySchemaFourSaveIgnoresPersistedRNGStateOnContinue() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 4,
            acquisitionRNGState: 1
        )

        let expectedSeed: UInt64 = 0x0123_4567_89ab_cdef
        let runtime = GameRuntime(
            content: fixtureContent(),
            telemetryPublisher: nil,
            saveStore: saveStore,
            runtimeRNGSeedSource: { expectedSeed }
        )

        XCTAssertTrue(runtime.continueFromTitleMenu())

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.nextAcquisitionRandomByte(), expectedRuntimeRandomByte(afterSeedingWith: expectedSeed))
    }

    func testLoadingSameSaveWithDifferentSeedsChangesNextEncounterOutcome() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 4,
            acquisitionRNGState: 0x0000_0000_0000_0001,
            mapID: "ROUTE_1",
            playerPosition: .init(x: 0, y: 0),
            facing: .up
        )

        let routeMap = MapManifest(
            id: "ROUTE_1",
            displayName: "Route 1",
            defaultMusicID: "MUSIC_PALLET_TOWN",
            borderBlockID: 0x0A,
            blockWidth: 1,
            blockHeight: 1,
            stepWidth: 1,
            stepHeight: 1,
            tileset: "OVERWORLD",
            blockIDs: [0x05],
            stepCollisionTileIDs: [0x09],
            warps: [],
            backgroundEvents: [],
            objects: []
        )
        let overworldTileset = TilesetManifest(
            id: "OVERWORLD",
            imagePath: "Assets/field/tilesets/overworld.png",
            blocksetPath: "Assets/field/blocksets/overworld.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: .init(
                passableTileIDs: [0x09],
                warpTileIDs: [],
                doorTileIDs: [],
                grassTileID: 0x09,
                tilePairCollisions: [],
                ledges: []
            )
        )
        let content = fixtureContent(
            gameplayManifest: fixtureGameplayManifest(
                species: [
                    .init(id: "SQUIRTLE", displayName: "Squirtle", primaryType: "WATER", baseHP: 44, baseAttack: 48, baseDefense: 65, baseSpeed: 43, baseSpecial: 50, startingMoves: ["TACKLE"]),
                    .init(id: "PIDGEY", displayName: "Pidgey", primaryType: "NORMAL", secondaryType: "FLYING", baseHP: 40, baseAttack: 45, baseDefense: 40, baseSpeed: 56, baseSpecial: 35, startingMoves: ["TACKLE"]),
                    .init(id: "RATTATA", displayName: "Rattata", primaryType: "NORMAL", baseHP: 30, baseAttack: 56, baseDefense: 35, baseSpeed: 72, baseSpecial: 25, startingMoves: ["TACKLE"]),
                ],
                moves: [
                    .init(id: "TACKLE", displayName: "TACKLE", power: 35, accuracy: 100, maxPP: 35, effect: "NO_ADDITIONAL_EFFECT", type: "NORMAL"),
                ],
                wildEncounterTables: [
                    .init(
                        mapID: "ROUTE_1",
                        grassEncounterRate: 255,
                        waterEncounterRate: 0,
                        grassSlots: [
                            .init(speciesID: "PIDGEY", level: 3),
                            .init(speciesID: "RATTATA", level: 4),
                        ],
                        waterSlots: []
                    ),
                ],
                maps: [routeMap],
                tilesets: [overworldTileset]
            )
        )

        let firstRuntime = GameRuntime(
            content: content,
            telemetryPublisher: nil,
            saveStore: saveStore,
            runtimeRNGSeedSource: { 0x0000_0000_0000_0003 }
        )
        XCTAssertTrue(firstRuntime.continueFromTitleMenu())
        firstRuntime.evaluateWildEncounterIfNeeded()
        let firstEncounter = try XCTUnwrap(firstRuntime.currentSnapshot().battle?.enemyPokemon)

        let secondRuntime = GameRuntime(
            content: content,
            telemetryPublisher: nil,
            saveStore: saveStore,
            runtimeRNGSeedSource: { 0x0000_0000_0000_0002 }
        )
        XCTAssertTrue(secondRuntime.continueFromTitleMenu())
        secondRuntime.evaluateWildEncounterIfNeeded()
        let secondEncounter = try XCTUnwrap(secondRuntime.currentSnapshot().battle?.enemyPokemon)

        XCTAssertNotEqual(firstEncounter.speciesID, secondEncounter.speciesID)
        XCTAssertNotEqual(firstEncounter.level, secondEncounter.level)
    }
}

private func decodeLegacySaveEnvelope(
    schemaVersion: Int,
    acquisitionRNGState: UInt64,
    mapID: String = "REDS_HOUSE_2F",
    playerPosition: TilePoint = .init(x: 4, y: 4),
    facing: FacingDirection = .down
) throws -> GameSaveEnvelope {
    let json = """
    {
      "metadata": {
        "schemaVersion": \(schemaVersion),
        "variant": "red",
        "playthroughID": "legacy",
        "playerName": "RED",
        "locationName": "Red's House 2F",
        "badgeCount": 0,
        "playTimeSeconds": 12,
        "savedAt": "2026-03-10T20:00:00Z"
      },
      "snapshot": {
        "mapID": "\(mapID)",
        "playerPosition": { "x": \(playerPosition.x), "y": \(playerPosition.y) },
        "facing": "\(facing.rawValue)",
        "objectStates": {},
        "activeFlags": [],
        "money": 3000,
        "inventory": [],
        "earnedBadgeIDs": [],
        "playerName": "RED",
        "rivalName": "BLUE",
        "playerParty": [
          {
            "speciesID": "SQUIRTLE",
            "nickname": "Squirtle",
            "level": 5,
            "experience": 135,
            "dvs": { "attack": 0, "defense": 0, "speed": 0, "special": 0 },
            "statExp": { "hp": 0, "attack": 0, "defense": 0, "speed": 0, "special": 0 },
            "maxHP": 20,
            "currentHP": 20,
            "attack": 10,
            "defense": 10,
            "speed": 10,
            "special": 10,
            "attackStage": 0,
            "defenseStage": 0,
            "accuracyStage": 0,
            "evasionStage": 0,
            "moves": []
          }
        ],
        "chosenStarterSpeciesID": "SQUIRTLE",
        "rivalStarterSpeciesID": "BULBASAUR",
        "pendingStarterSpeciesID": null,
        "activeMapScriptTriggerID": null,
        "activeScriptID": null,
        "activeScriptStep": null,
        "acquisitionRNGState": \(acquisitionRNGState),
        "encounterStepCounter": 0,
        "playTimeSeconds": 12
      }
    }
    """

    return try JSONDecoder().decode(GameSaveEnvelope.self, from: Data(json.utf8))
}

private func expectedRuntimeRandomByte(afterSeedingWith seed: UInt64) -> Int {
    let nextState = seed &* 6364136223846793005 &+ 1
    return Int((nextState >> 32) & 0xFF)
}
