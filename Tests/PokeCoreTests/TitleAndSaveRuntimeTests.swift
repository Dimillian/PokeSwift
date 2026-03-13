import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
    func testTitleFlowTransitionsFromAttractToMenuAndOptionsPlaceholder() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        await waitForScene(.titleAttract, in: runtime, message: "title flow did not reach attract mode")
        XCTAssertEqual(runtime.scene, .titleAttract)
        runtime.handle(button: .start)
        await waitForScene(.titleMenu, in: runtime, message: "title flow did not reach the menu")
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
        await waitForScene(.titleAttract, in: runtime, message: "title flow did not reach attract mode")
        runtime.handle(button: .start)
        await waitForScene(.titleMenu, in: runtime, message: "title flow did not reach the menu")
        runtime.handle(button: .down)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().substate, "continue_disabled")
    }
    func testNewGameEntersFieldAndPublishesFieldTelemetry() async {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.start()
        await waitForScene(.titleAttract, in: runtime, message: "title flow did not reach attract mode")
        runtime.handle(button: .start)
        await waitForScene(.titleMenu, in: runtime, message: "title flow did not reach the menu")
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
        runtime.gameplayState?.ownedSpeciesIDs = ["SQUIRTLE", "PIDGEY"]
        runtime.gameplayState?.seenSpeciesIDs = ["SQUIRTLE", "PIDGEY", "RATTATA"]
        runtime.gameplayState?.speciesEncounterCounts = ["SQUIRTLE": 4, "PIDGEY": 2, "RATTATA": 7, "MISSINGNO": 0]
        runtime.gameplayState?.currentBoxIndex = 1
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.blackoutCheckpoint = .init(
            mapID: "VIRIDIAN_POKECENTER",
            position: .init(x: 3, y: 7),
            facing: .down
        )
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
            majorStatus: .paralysis,
            moves: savedMoves
        )
        runtime.gameplayState?.boxedPokemon[1].pokemon = [
            runtime.makeConfiguredPokemon(
                speciesID: "SQUIRTLE",
                nickname: "BoxedMon",
                level: 4,
                experience: 100,
                dvs: .zero,
                statExp: .zero,
                currentHP: 17,
                attackStage: 0,
                defenseStage: 0,
                accuracyStage: 0,
                evasionStage: 0,
                majorStatus: .sleep,
                moves: []
            )
        ]
        runtime.gameplayState?.objectStates["test_object"] = RuntimeObjectState(position: .init(x: 1, y: 1), facing: .down, visible: false)

        XCTAssertTrue(runtime.saveCurrentGame())
        XCTAssertNotNil(saveStore.envelope)
        XCTAssertEqual(saveStore.envelope?.metadata.schemaVersion, 8)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.experience, 202)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.dvs, savedPokemon?.dvs)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.statExp, savedPokemon?.statExp)
        XCTAssertEqual(saveStore.envelope?.snapshot.playerParty.first?.majorStatus, .paralysis)
        XCTAssertEqual(saveStore.envelope?.snapshot.currentBoxIndex, 1)
        XCTAssertEqual(saveStore.envelope?.snapshot.boxedPokemon[1].pokemon.first?.nickname, "BoxedMon")
        XCTAssertEqual(saveStore.envelope?.snapshot.boxedPokemon[1].pokemon.first?.majorStatus, .sleep)
        XCTAssertEqual(saveStore.envelope?.snapshot.ownedSpeciesIDs.sorted(), ["PIDGEY", "SQUIRTLE"])
        XCTAssertEqual(saveStore.envelope?.snapshot.seenSpeciesIDs.sorted(), ["PIDGEY", "RATTATA", "SQUIRTLE"])
        XCTAssertEqual(saveStore.envelope?.snapshot.speciesEncounterCounts, ["SQUIRTLE": 4, "PIDGEY": 2, "RATTATA": 7])
        XCTAssertEqual(
            saveStore.envelope?.snapshot.blackoutCheckpoint,
            .init(mapID: "VIRIDIAN_POKECENTER", position: .init(x: 3, y: 7), facing: .down)
        )
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
        XCTAssertEqual(snapshot.party?.pokemon.first?.majorStatus, .paralysis)
        XCTAssertEqual(resumed.gameplayState?.playerParty.first?.dvs, savedPokemon?.dvs)
        XCTAssertEqual(resumed.gameplayState?.playerParty.first?.statExp, savedPokemon?.statExp)
        XCTAssertEqual(resumed.gameplayState?.currentBoxIndex, 1)
        XCTAssertEqual(resumed.gameplayState?.boxedPokemon[1].pokemon.first?.nickname, "BoxedMon")
        XCTAssertEqual(resumed.gameplayState?.boxedPokemon[1].pokemon.first?.majorStatus, .sleep)
        XCTAssertEqual(resumed.gameplayState?.ownedSpeciesIDs, Set(["SQUIRTLE", "PIDGEY"]))
        XCTAssertEqual(resumed.gameplayState?.seenSpeciesIDs, Set(["SQUIRTLE", "PIDGEY", "RATTATA"]))
        XCTAssertEqual(resumed.gameplayState?.speciesEncounterCounts, ["SQUIRTLE": 4, "PIDGEY": 2, "RATTATA": 7])
        XCTAssertEqual(
            resumed.gameplayState?.blackoutCheckpoint,
            .init(mapID: "VIRIDIAN_POKECENTER", position: .init(x: 3, y: 7), facing: .down)
        )
        XCTAssertEqual(snapshot.eventFlags?.activeFlags, [])
        XCTAssertEqual(resumed.playerMoney, 4242)
        XCTAssertEqual(resumed.earnedBadgeIDs, Set(["BOULDER"]))
        XCTAssertFalse(resumed.currentFieldObjects.contains(where: { $0.id == "test_object" }))
    }

    func testLegacySchemaFiveSaveDefaultsStorageOwnershipAndStatusFields() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 5,
            acquisitionRNGState: 1
        )

        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        XCTAssertEqual(runtime.gameplayState?.currentBoxIndex, 0)
        XCTAssertEqual(runtime.gameplayState?.boxedPokemon.count, GameRuntime.storageBoxCount)
        XCTAssertTrue(runtime.gameplayState?.boxedPokemon.allSatisfy { $0.pokemon.isEmpty } ?? false)
        XCTAssertEqual(runtime.gameplayState?.ownedSpeciesIDs, Set(["SQUIRTLE"]))
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.majorStatus, MajorStatusCondition.none)
    }

    func testSchemaSixSaveDefaultsBlackoutCheckpointFromPlayerStart() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 6,
            acquisitionRNGState: 1
        )

        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "REDS_HOUSE_2F", position: .init(x: 4, y: 4), facing: .down)
        )
    }

    func testLegacySaveWithoutPlayTimeFieldsDefaultsToZeroAndStillLoads() throws {
        let json = """
        {
          "metadata": {
            "schemaVersion": 6,
            "variant": "red",
            "playthroughID": "legacy-no-playtime",
            "playerName": "RED",
            "locationName": "Red's House 2F",
            "badgeCount": 0,
            "savedAt": "2026-03-13T12:00:00Z"
          },
          "snapshot": {
            "mapID": "REDS_HOUSE_2F",
            "playerPosition": { "x": 4, "y": 4 },
            "facing": "down",
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
            "encounterStepCounter": 0
          }
        }
        """

        let envelope = try JSONDecoder().decode(GameSaveEnvelope.self, from: Data(json.utf8))
        XCTAssertEqual(envelope.metadata.playTimeSeconds, 0)
        XCTAssertEqual(envelope.snapshot.playTimeSeconds, 0)

        let saveStore = InMemorySaveStore()
        saveStore.envelope = envelope
 
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        XCTAssertEqual(runtime.gameplayState?.playTimeSeconds, 0)
        XCTAssertEqual(runtime.currentSaveMetadata?.playTimeSeconds, 0)
    }

    func testSchemaSevenSaveDefaultsSpeciesEncounterCountsToZero() throws {
        let saveStore = InMemorySaveStore()
        saveStore.envelope = try decodeLegacySaveEnvelope(
            schemaVersion: 7,
            acquisitionRNGState: 1
        )
 
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        XCTAssertEqual(runtime.gameplayState?.speciesEncounterCounts, [:])
        XCTAssertEqual(runtime.encounterCountsBySpeciesID["SQUIRTLE"] ?? 0, 0)
    }
    func testContinueMergesDefaultObjectStatesSoForestTrainerSightStillWorks() async throws {
        let saveStore = InMemorySaveStore()
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()

        saveStore.envelope = GameSaveEnvelope(
            metadata: .init(
                schemaVersion: GameRuntime.saveSchemaVersion,
                variant: .red,
                playthroughID: "forest-los",
                playerName: "RED",
                locationName: "Viridian Forest",
                badgeCount: 0,
                playTimeSeconds: 120,
                savedAt: "2026-03-12T10:00:00Z"
            ),
            snapshot: .init(
                mapID: "VIRIDIAN_FOREST",
                playerPosition: .init(x: 25, y: 33),
                facing: .right,
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
                        level: 8,
                        experience: 560,
                        dvs: .zero,
                        statExp: .zero,
                        maxHP: 24,
                        currentHP: 24,
                        attack: 13,
                        defense: 15,
                        speed: 12,
                        special: 13,
                        attackStage: 0,
                        defenseStage: 0,
                        accuracyStage: 0,
                        evasionStage: 0,
                        moves: [.init(id: "TACKLE", currentPP: 35)]
                    ),
                ],
                chosenStarterSpeciesID: "SQUIRTLE",
                rivalStarterSpeciesID: "BULBASAUR",
                pendingStarterSpeciesID: nil,
                activeMapScriptTriggerID: nil,
                activeScriptID: nil,
                activeScriptStep: nil,
                encounterStepCounter: 0,
                playTimeSeconds: 120
            )
        )

        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        runtime.movePlayer(in: .right)

        let snapshot = try await waitForSnapshot(runtime, timeout: 2.0) {
            $0.battle?.battleID == "opp_bug_catcher_1"
        }

        XCTAssertEqual(snapshot.battle?.battleID, "opp_bug_catcher_1")
        XCTAssertEqual(runtime.scene, .battle)
    }
    func testContinueMissingObjectStatesStillHidesForestPickupAfterCollection() throws {
        let saveStore = InMemorySaveStore()
        let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
        let content = try FileSystemContentLoader(rootURL: contentRoot).load()

        saveStore.envelope = GameSaveEnvelope(
            metadata: .init(
                schemaVersion: GameRuntime.saveSchemaVersion,
                variant: .red,
                playthroughID: "forest-pickup",
                playerName: "RED",
                locationName: "Viridian Forest",
                badgeCount: 0,
                playTimeSeconds: 120,
                savedAt: "2026-03-12T10:05:00Z"
            ),
            snapshot: .init(
                mapID: "VIRIDIAN_FOREST",
                playerPosition: .init(x: 25, y: 12),
                facing: .up,
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
                        level: 8,
                        experience: 560,
                        dvs: .zero,
                        statExp: .zero,
                        maxHP: 24,
                        currentHP: 24,
                        attack: 13,
                        defense: 15,
                        speed: 12,
                        special: 13,
                        attackStage: 0,
                        defenseStage: 0,
                        accuracyStage: 0,
                        evasionStage: 0,
                        moves: [.init(id: "TACKLE", currentPP: 35)]
                    ),
                ],
                chosenStarterSpeciesID: "SQUIRTLE",
                rivalStarterSpeciesID: "BULBASAUR",
                pendingStarterSpeciesID: nil,
                activeMapScriptTriggerID: nil,
                activeScriptID: nil,
                activeScriptStep: nil,
                encounterStepCounter: 0,
                playTimeSeconds: 120
            )
        )

        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        XCTAssertTrue(runtime.continueFromTitleMenu())
        let antidote = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_forest_antidote" })
        runtime.interact(with: antidote)

        XCTAssertEqual(runtime.itemQuantity("ANTIDOTE"), 1)
        XCTAssertFalse(runtime.currentFieldObjects.contains { $0.id == "viridian_forest_antidote" })
        XCTAssertFalse(runtime.gameplayState?.objectStates["viridian_forest_antidote"]?.visible ?? true)
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

@MainActor
private func waitForScene(
    _ scene: RuntimeScene,
    in runtime: GameRuntime,
    message: String,
    attempts: Int = 60
) async {
    for _ in 0..<attempts {
        if runtime.scene == scene {
            return
        }
        try? await Task.sleep(for: .milliseconds(50))
    }

    XCTAssertEqual(runtime.scene, scene, message)
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
