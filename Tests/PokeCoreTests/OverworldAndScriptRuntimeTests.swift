import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
    func testRepoGeneratedContentPublishesRealAssetFieldTelemetry() async throws {
        let content = try loadRepoContent()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil)

        runtime.beginNewGame()
        completeOakIntro(runtime)

        let snapshot = runtime.currentSnapshot()
        XCTAssertEqual(snapshot.scene, .field)
        XCTAssertEqual(snapshot.field?.mapID, "REDS_HOUSE_2F")
        XCTAssertEqual(snapshot.field?.renderMode, .realAssets)
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

    func testRepoGeneratedRoute2NorthConnectionCrossesIntoPewterCity() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "ROUTE_2",
            moving: .up,
            expecting: "PEWTER_CITY"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.gameplayState?.mapID, "PEWTER_CITY")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "PEWTER_CITY")
    }

    func testRepoGeneratedPewterCitySouthConnectionCrossesIntoRoute2() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "PEWTER_CITY",
            moving: .down,
            expecting: "ROUTE_2"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PEWTER_CITY"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .down

        runtime.movePlayer(in: .down)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_2")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_2")
    }

    func testRepoGeneratedPewterCityEastConnectionCrossesIntoRoute3() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "PEWTER_CITY",
            moving: .right,
            expecting: "ROUTE_3"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PEWTER_CITY"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .right

        runtime.movePlayer(in: .right)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_3")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_3")
    }

    func testRepoGeneratedRoute3WestConnectionCrossesIntoPewterCity() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "ROUTE_3",
            moving: .left,
            expecting: "PEWTER_CITY"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_3"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .left

        runtime.movePlayer(in: .left)

        XCTAssertEqual(runtime.gameplayState?.mapID, "PEWTER_CITY")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "PEWTER_CITY")
    }

    func testRepoGeneratedRoute3NorthConnectionCrossesIntoRoute4() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "ROUTE_3",
            moving: .up,
            expecting: "ROUTE_4"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_3"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_4")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_4")
    }

    func testRepoGeneratedRoute4EastConnectionCrossesIntoCeruleanCity() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "ROUTE_4",
            moving: .right,
            expecting: "CERULEAN_CITY"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_4"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .right

        runtime.movePlayer(in: .right)

        XCTAssertEqual(runtime.gameplayState?.mapID, "CERULEAN_CITY")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "CERULEAN_CITY")
    }

    func testRepoGeneratedCeruleanCityNorthConnectionCrossesIntoRoute24() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "CERULEAN_CITY",
            moving: .up,
            expecting: "ROUTE_24"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_CITY"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_24")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_24")
    }

    func testRepoGeneratedRoute24EastConnectionCrossesIntoRoute25() throws {
        let runtime = try makeRepoRuntime()
        let start = try findConnectionStart(
            from: "ROUTE_24",
            moving: .right,
            expecting: "ROUTE_25"
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_24"
        runtime.gameplayState?.playerPosition = start
        runtime.gameplayState?.facing = .right

        runtime.movePlayer(in: .right)

        XCTAssertEqual(runtime.gameplayState?.mapID, "ROUTE_25")
        XCTAssertEqual(runtime.currentSnapshot().field?.mapID, "ROUTE_25")
    }

    func testRepoGeneratedRoute25WarpEntersBillsHouse() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_25"
        runtime.gameplayState?.playerPosition = .init(x: 45, y: 4)
        runtime.gameplayState?.facing = .up

        runtime.movePlayer(in: .up)

        let snapshot = try await waitForSnapshot(runtime) { runtime in
            runtime.field?.mapID == "BILLS_HOUSE" && runtime.field?.transition == nil
        }

        XCTAssertEqual(snapshot.field?.mapID, "BILLS_HOUSE")
        XCTAssertEqual(runtime.gameplayState?.mapID, "BILLS_HOUSE")
    }

    func testRepoGeneratedCeruleanCityInteriorDoorsEnterExpectedMaps() async throws {
        let cases: [(start: TilePoint, targetMapID: String)] = [
            (.init(x: 27, y: 12), "CERULEAN_TRASHED_HOUSE"),
            (.init(x: 13, y: 16), "CERULEAN_TRADE_HOUSE"),
            (.init(x: 19, y: 18), "CERULEAN_POKECENTER"),
            (.init(x: 13, y: 26), "BIKE_SHOP"),
            (.init(x: 25, y: 26), "CERULEAN_MART"),
            (.init(x: 9, y: 12), "CERULEAN_BADGE_HOUSE"),
        ]

        for testCase in cases {
            let runtime = try makeRepoRuntime()

            runtime.gameplayState = runtime.makeInitialGameplayState()
            runtime.scene = .field
            runtime.substate = "field"
            runtime.gameplayState?.mapID = "CERULEAN_CITY"
            runtime.gameplayState?.playerPosition = testCase.start
            runtime.gameplayState?.facing = .up

            runtime.movePlayer(in: .up)

            let snapshot = try await waitForSnapshot(runtime) { runtime in
                runtime.field?.mapID == testCase.targetMapID && runtime.field?.transition == nil
            }

            XCTAssertEqual(snapshot.field?.mapID, testCase.targetMapID)
            XCTAssertEqual(runtime.gameplayState?.mapID, testCase.targetMapID)
        }
    }

    func testRepoGeneratedMuseum1FOldAmberExhibitShowsDialogue() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_1F"
        runtime.gameplayState?.playerPosition = .init(x: 15, y: 2)
        runtime.gameplayState?.facing = .right

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_old_amber")
    }

    func testRepoGeneratedMuseum2FSpaceShuttleExhibitShowsDialogue() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_2F"
        runtime.gameplayState?.playerPosition = .init(x: 11, y: 3)
        runtime.gameplayState?.facing = .up

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum2_f_space_shuttle_sign")
    }

    func testRepoGeneratedMuseum2FMoonStoneExhibitShowsDialogue() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_2F"
        runtime.gameplayState?.playerPosition = .init(x: 2, y: 6)
        runtime.gameplayState?.facing = .up

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum2_f_moon_stone_sign")
    }

    func testRepoGeneratedRoute1GrassCanTriggerWildEncounterAndEscapeForFixedRandomBytes() throws {
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

    func testRepoGeneratedMtMoonFloorCanTriggerWildEncounterAndEscapeForFixedRandomBytes() throws {
        let runtime = try makeRepoRuntime()
        let encounterTile = try findLandEncounterFloorTile(in: runtime, mapID: "MT_MOON_1F")

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MT_MOON_1F"
        runtime.gameplayState?.playerPosition = encounterTile
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 12, nickname: "Squirtle")]
        runtime.setAcquisitionRandomOverrides([0, 0])

        runtime.evaluateWildEncounterIfNeeded()

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.currentSnapshot().battle?.kind, .wild)
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPokemon.speciesID, "ZUBAT")
        XCTAssertEqual(runtime.currentSnapshot().battle?.enemyPokemon.level, 8)

        drainBattleText(runtime)
        runtime.handle(button: .cancel)
        drainBattleUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.gameplayState?.mapID, "MT_MOON_1F")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, encounterTile)
    }
    func testRepoGeneratedMtMoonB2FFossilAreaSuppressesEncountersAfterSuperNerd() throws {
        let runtime = try makeRepoRuntime()
        let fossilAreaPositions = (5...8).flatMap { y in
            (11...14).map { x in TilePoint(x: x, y: y) }
        }
        let outsideEncounterTile = try findLandEncounterFloorTile(
            in: runtime,
            mapID: "MT_MOON_B2F",
            excluding: fossilAreaPositions
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MT_MOON_B2F"
        runtime.gameplayState?.playerPosition = .init(x: 11, y: 5)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 12, nickname: "Squirtle")]
        runtime.gameplayState?.activeFlags.insert("EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")
        runtime.setAcquisitionRandomOverrides([0, 0, 0, 0])

        runtime.evaluateWildEncounterIfNeeded()

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.currentSnapshot().battle)
        XCTAssertEqual(runtime.gameplayState?.encounterStepCounter, 0)

        runtime.gameplayState?.playerPosition = outsideEncounterTile
        runtime.evaluateWildEncounterIfNeeded()

        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertEqual(runtime.currentSnapshot().battle?.kind, .wild)
    }
    func testWildEncounterSlotThresholdsMatchGBTableForFixedRolls() {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        let slots = (0..<10).map { index in
            WildEncounterSlotManifest(speciesID: "SPECIES_\(index)", level: index + 2)
        }
        let thresholdRolls = [0, 50, 51, 101, 102, 140, 141, 165, 166, 190, 191, 215, 216, 228, 229, 241, 242, 252, 253, 255]
        let expectedSlots = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]

        for (roll, expectedSlot) in zip(thresholdRolls, expectedSlots) {
            runtime.setAcquisitionRandomOverrides([roll])
            let encounter = runtime.selectWildEncounter(from: slots)
            XCTAssertEqual(encounter?.speciesID, "SPECIES_\(expectedSlot)", "roll \(roll) should resolve to slot \(expectedSlot)")
            XCTAssertEqual(encounter?.level, expectedSlot + 2, "roll \(roll) should preserve the slot level")
        }
    }
    func testRepoGeneratedViridianPokecenterNurseHealingFlowMatchesPromptAndFarewell() async throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_POKECENTER"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]
        runtime.gameplayState?.playerParty[0].currentHP = 7
        runtime.requestDefaultMapMusic()

        let nurse = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" })
        runtime.interact(with: nurse)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_welcome")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_welcome")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_shall_we_heal")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.focusedIndex, 0)

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_need_your_pokemon")

        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.fieldHealing?.phase == .healedJingle
        }

        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.currentHP, runtime.gameplayState?.playerParty.first?.maxHP)
        XCTAssertEqual(audioPlayer.soundEffectRequests.map(\.soundEffectID).last, "SFX_HEALING_MACHINE")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_PKMN_HEALED", entryID: "default"))
        XCTAssertEqual(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" }?.facing, .right)

        audioPlayer.completePendingPlayback()
        _ = try await waitForSnapshot(runtime) {
            $0.dialogue?.dialogueID == "pokemon_center_fighting_fit"
        }

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_farewell")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.currentSnapshot().dialogue)
        XCTAssertNil(runtime.currentSnapshot().fieldPrompt)
        XCTAssertNil(runtime.currentSnapshot().fieldHealing)
        XCTAssertEqual(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" }?.facing, .down)
        XCTAssertEqual(runtime.currentSnapshot().audio?.trackID, "MUSIC_POKECENTER")
        XCTAssertEqual(runtime.currentSnapshot().audio?.reason, "mapDefault")
    }

    func testRepoGeneratedViridianPokecenterHealingUpdatesBlackoutCheckpointOnAcceptance() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_POKECENTER"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "PALLET_TOWN", position: .init(x: 5, y: 6), facing: .down)
        )

        let nurse = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_pokecenter_nurse" })
        runtime.interact(with: nurse)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.fieldHealing?.phase == .priming || $0.fieldHealing?.phase == .machineActive
        }

        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "VIRIDIAN_CITY", position: .init(x: 23, y: 26), facing: .down)
        )
    }

    func testRepoGeneratedViridianPokecenterNoChoiceSkipsHealing() throws {
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
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .right)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_farewell")
        XCTAssertEqual(runtime.gameplayState?.playerParty.first?.currentHP, 7)
        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "PALLET_TOWN", position: .init(x: 5, y: 6), facing: .down)
        )

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.currentSnapshot().fieldPrompt)
        XCTAssertNil(runtime.currentSnapshot().fieldHealing)
    }

    func testRepoGeneratedCeruleanPokecenterHealingUpdatesBlackoutCheckpointOnAcceptance() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_POKECENTER"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Squirtle")]

        let nurse = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_pokecenter_nurse" })
        runtime.interact(with: nurse)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_welcome")
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "pokemon_center_shall_we_heal")

        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.fieldHealing?.phase == .priming || $0.fieldHealing?.phase == .machineActive
        }

        XCTAssertEqual(
            runtime.gameplayState?.blackoutCheckpoint,
            .init(mapID: "CERULEAN_CITY", position: .init(x: 19, y: 18), facing: .down)
        )
    }

    func testRepoGeneratedMuseumScientistSupportsOverCounterAdmissionTalk() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_1F"
        runtime.gameplayState?.playerPosition = .init(x: 10, y: 4)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.money = 100

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_would_you_like_to_come_in")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.focusedIndex, 0)
    }

    func testRepoGeneratedMuseumEntryPromptChargesTicketAndSetsFlag() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_1F"
        runtime.gameplayState?.playerPosition = .init(x: 9, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.money = 100

        runtime.evaluateMapScriptsIfNeeded()

        XCTAssertEqual(runtime.gameplayState?.activeMapScriptTriggerID, "museum_admission_entry_left")
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_would_you_like_to_come_in")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_thank_you")

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.currentSnapshot().dialogue)
        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_BOUGHT_MUSEUM_TICKET") ?? false)
        XCTAssertEqual(runtime.gameplayState?.money, 50)
        XCTAssertTrue(audioPlayer.soundEffectRequests.contains { $0.soundEffectID == "SFX_PURCHASE" })
    }

    func testRepoGeneratedMuseumDecliningAdmissionPushesPlayerBack() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_1F"
        runtime.gameplayState?.playerPosition = .init(x: 10, y: 4)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.money = 100

        runtime.interactAhead()
        runtime.handle(button: .right)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_come_again")

        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.field?.playerPosition == .init(x: 10, y: 5)
        }

        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_BOUGHT_MUSEUM_TICKET") ?? false)
        XCTAssertEqual(runtime.gameplayState?.money, 100)
    }

    func testRepoGeneratedMuseumInsufficientFundsPushesPlayerBack() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MUSEUM_1F"
        runtime.gameplayState?.playerPosition = .init(x: 10, y: 4)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.money = 40

        runtime.interactAhead()
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_dont_have_enough_money")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "museum1_f_scientist1_come_again")

        runtime.handle(button: .confirm)

        _ = try await waitForSnapshot(runtime) {
            $0.field?.playerPosition == .init(x: 10, y: 5)
        }

        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_BOUGHT_MUSEUM_TICKET") ?? false)
        XCTAssertEqual(runtime.gameplayState?.money, 40)
    }

    func testRepoGeneratedPewterMuseumExitResetsTicketFlag() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PEWTER_CITY"
        runtime.gameplayState?.playerPosition = .init(x: 14, y: 8)
        runtime.gameplayState?.facing = .down
        runtime.gameplayState?.activeFlags.insert("EVENT_BOUGHT_MUSEUM_TICKET")

        runtime.evaluateMapScriptsIfNeeded()

        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_BOUGHT_MUSEUM_TICKET") ?? false)
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

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.mapID = "CERULEAN_TRADE_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 4)
        runtime.gameplayState?.facing = .right
        let granny = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_trade_house_granny" })
        runtime.interact(with: granny)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_trade_house_granny")

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.playerPosition = .init(x: 2, y: 2)
        runtime.gameplayState?.facing = .left
        let gambler = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_trade_house_gambler" })
        runtime.interact(with: gambler)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_trade_house_gambler")

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.mapID = "CERULEAN_BADGE_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 3)
        runtime.gameplayState?.facing = .right
        let badgeHouseGuide = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_badge_house_middle_aged_man" })
        runtime.interact(with: badgeHouseGuide)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_badge_house_middle_aged_man")

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.mapID = "CERULEAN_TRASHED_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .left
        let girl = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_trashed_house_girl" })
        runtime.interact(with: girl)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_trashed_house_girl")
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

    func testRepoGeneratedViridianMartClerkOpensShopAfterParcelHandoff() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_OAKS_PARCEL")
        runtime.gameplayState?.activeFlags.insert("EVENT_OAK_GOT_PARCEL")

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_mart_clerk" })
        runtime.interact(with: clerk)

        let shop = try XCTUnwrap(runtime.currentSnapshot().shop)
        XCTAssertEqual(shop.martID, "viridian_mart")
        XCTAssertEqual(shop.phase, .mainMenu)
        XCTAssertEqual(shop.menuOptions, ["BUY", "SELL", "QUIT"])
        XCTAssertEqual(shop.buyItems.map(\.itemID), ["POKE_BALL", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL"])
        XCTAssertEqual(shop.buyItems.first?.unitPrice, 200)
        XCTAssertEqual(runtime.content.item(id: "POKE_BALL")?.battleUse, .ball)
        XCTAssertEqual(runtime.substate, "shop_viridian_mart")
    }

    func testViridianMartPurchaseDeductsMoneyAndAddsInventory() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_OAKS_PARCEL")
        runtime.gameplayState?.activeFlags.insert("EVENT_OAK_GOT_PARCEL")

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_mart_clerk" })
        runtime.interact(with: clerk)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, .result)
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 1)
        XCTAssertEqual(runtime.playerMoney, 2800)
        XCTAssertEqual(runtime.currentSnapshot().inventory?.items.first { $0.itemID == "POKE_BALL" }?.quantity, 1)
    }

    func testViridianMartDirectionalKeyBridgePathNavigatesMainMenu() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_OAKS_PARCEL")
        runtime.gameplayState?.activeFlags.insert("EVENT_OAK_GOT_PARCEL")

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_mart_clerk" })
        runtime.interact(with: clerk)

        XCTAssertEqual(runtime.currentSnapshot().shop?.focusedMainMenuIndex, 0)

        runtime.setDirectionalButton(.right, isPressed: true)

        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, .mainMenu)
        XCTAssertEqual(runtime.currentSnapshot().shop?.focusedMainMenuIndex, 1)
        XCTAssertEqual(runtime.substate, "shop_viridian_mart")
    }

    func testViridianMartQuitClosesShopUI() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_OAKS_PARCEL")
        runtime.gameplayState?.activeFlags.insert("EVENT_OAK_GOT_PARCEL")

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_mart_clerk" })
        runtime.interact(with: clerk)
        runtime.handle(button: .right)
        runtime.handle(button: .right)
        runtime.handle(button: .confirm)

        XCTAssertNil(runtime.currentSnapshot().shop)
        XCTAssertNil(runtime.shopState)
        XCTAssertEqual(runtime.substate, "field")
    }

    func testViridianMartSellFlowRemovesItemAndAddsHalfPrice() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_OAKS_PARCEL")
        runtime.gameplayState?.activeFlags.insert("EVENT_OAK_GOT_PARCEL")
        runtime.gameplayState?.inventory = [.init(itemID: "ANTIDOTE", quantity: 2)]

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "viridian_mart_clerk" })
        runtime.interact(with: clerk)
        runtime.handle(button: .right)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, .result)
        XCTAssertEqual(runtime.itemQuantity("ANTIDOTE"), 1)
        XCTAssertEqual(runtime.playerMoney, 3050)
    }

    func testRepoGeneratedCeruleanMartClerkOpensSharedShopWithCeruleanStock() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_MART"
        runtime.gameplayState?.playerPosition = .init(x: 3, y: 7)
        runtime.gameplayState?.facing = .up

        let clerk = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_mart_clerk" })
        runtime.interact(with: clerk)

        let shop = try XCTUnwrap(runtime.currentSnapshot().shop)
        XCTAssertEqual(shop.martID, "cerulean_mart")
        XCTAssertEqual(shop.phase, .mainMenu)
        XCTAssertEqual(shop.menuOptions, ["BUY", "SELL", "QUIT"])
        XCTAssertEqual(
            shop.buyItems.map(\.itemID),
            ["POKE_BALL", "POTION", "REPEL", "ANTIDOTE", "BURN_HEAL", "AWAKENING", "PARLYZ_HEAL"]
        )
        XCTAssertEqual(runtime.substate, "shop_cerulean_mart")
    }

    func testRepoGeneratedBikeShopVoucherExchangeAwardsBicycleAndConsumesVoucher() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "BIKE_SHOP"
        runtime.gameplayState?.playerPosition = .init(x: 6, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.inventory = [.init(itemID: "BIKE_VOUCHER", quantity: 1)]

        runtime.interactAhead()

        drainDialogueAndScripts(runtime) {
            $0.scene == .field && $0.inventory?.items.contains(where: { $0.itemID == "BICYCLE" && $0.quantity == 1 }) == true
        }

        XCTAssertEqual(runtime.itemQuantity("BIKE_VOUCHER"), 0)
        XCTAssertEqual(runtime.itemQuantity("BICYCLE"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_BICYCLE"))
    }

    func testRepoGeneratedBikeShopBagFullKeepsVoucherAndBlocksBicycle() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "BIKE_SHOP"
        runtime.gameplayState?.playerPosition = .init(x: 6, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.inventory = [
            .init(itemID: "BIKE_VOUCHER", quantity: 1),
            .init(itemID: "POKE_BALL", quantity: 1),
            .init(itemID: "POTION", quantity: 1),
            .init(itemID: "ANTIDOTE", quantity: 1),
            .init(itemID: "BURN_HEAL", quantity: 1),
            .init(itemID: "AWAKENING", quantity: 1),
            .init(itemID: "PARLYZ_HEAL", quantity: 1),
            .init(itemID: "ESCAPE_ROPE", quantity: 1),
            .init(itemID: "REPEL", quantity: 1),
            .init(itemID: "TM_BIDE", quantity: 1),
            .init(itemID: "TM_DIG", quantity: 1),
            .init(itemID: "TM_BUBBLEBEAM", quantity: 1),
            .init(itemID: "TM_WHIRLWIND", quantity: 1),
            .init(itemID: "TM_THUNDER_WAVE", quantity: 1),
            .init(itemID: "TM_SEISMIC_TOSS", quantity: 1),
            .init(itemID: "MOON_STONE", quantity: 1),
            .init(itemID: "NUGGET", quantity: 1),
            .init(itemID: "S_S_TICKET", quantity: 1),
            .init(itemID: "HELIX_FOSSIL", quantity: 1),
            .init(itemID: "DOME_FOSSIL", quantity: 1),
        ]

        runtime.interactAhead()

        drainDialogueAndScripts(runtime) {
            $0.scene == .field && $0.dialogue == nil
        }

        XCTAssertEqual(runtime.itemQuantity("BIKE_VOUCHER"), 1)
        XCTAssertEqual(runtime.itemQuantity("BICYCLE"), 0)
        XCTAssertFalse(runtime.hasFlag("EVENT_GOT_BICYCLE"))
    }

    func testRepoGeneratedBikeShopOfferWithoutVoucherShowsBlockedPurchaseFlow() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "BIKE_SHOP"
        runtime.gameplayState?.playerPosition = .init(x: 6, y: 4)
        runtime.gameplayState?.facing = .up

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bike_shop_clerk_welcome")
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bike_shop_clerk_do_you_like_it")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bike_shop_cant_afford")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bike_shop_come_again")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.itemQuantity("BICYCLE"), 0)
        XCTAssertFalse(runtime.hasFlag("EVENT_GOT_BICYCLE"))
    }

    func testRepoGeneratedCeruleanTrashedHouseFishingGuruDialogueChangesAfterReceivingTMDig() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_TRASHED_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 2, y: 2)
        runtime.gameplayState?.facing = .up

        let fishingGuru = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_trashed_house_fishing_guru" })
        runtime.interact(with: fishingGuru)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_trashed_house_fishing_guru_they_stole_a_t_m")

        runtime.scene = .field
        runtime.substate = "field"
        runtime.dialogueState = nil
        runtime.gameplayState?.inventory = [.init(itemID: "TM_DIG", quantity: 1)]
        runtime.interact(with: fishingGuru)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "cerulean_trashed_house_fishing_guru_whats_lost_is_lost")
    }

    func testSellFlowRejectsUnsellableItemsAndReturnsToMartLoop() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    dialogues: [
                        .init(id: "pokemart_greeting", pages: [.init(lines: ["Hi there! May I help you?"], waitsForPrompt: true)]),
                        .init(id: "pokemart_selling_greeting", pages: [.init(lines: ["What would you like to sell?"], waitsForPrompt: true)]),
                        .init(id: "pokemart_unsellable_item", pages: [.init(lines: ["I can't put a price on that."], waitsForPrompt: true)]),
                        .init(id: "pokemart_anything_else", pages: [.init(lines: ["Is there anything else I can do?"], waitsForPrompt: true)]),
                    ],
                    items: [
                        .init(id: "HM_CUT", displayName: "HM01"),
                    ],
                    marts: [
                        .init(
                            id: "test_mart",
                            mapID: "REDS_HOUSE_2F",
                            clerkObjectID: "clerk",
                            stockItemIDs: []
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.inventory = [.init(itemID: "HM_CUT", quantity: 1)]

        runtime.openMart(id: "test_mart")
        runtime.handle(button: .right)
        runtime.handle(button: .confirm)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.itemQuantity("HM_CUT"), 1)
        XCTAssertEqual(runtime.playerMoney, 3000)
        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, .result)
        XCTAssertEqual(runtime.currentSnapshot().shop?.promptText, "I can't put a price on that.")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, .mainMenu)
    }

    func testFieldPartyReorderSwapsSelectedPokemon() {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
            runtime.makePokemon(speciesID: "RATTATA", level: 4, nickname: "Fang"),
        ]

        runtime.handlePartySidebarSelection(0)
        XCTAssertEqual(runtime.fieldPartyReorderState?.selectedIndex, 0)

        runtime.handlePartySidebarSelection(2)

        XCTAssertNil(runtime.fieldPartyReorderState)
        XCTAssertEqual(runtime.gameplayState?.playerParty[0].nickname, "Fang")
        XCTAssertEqual(runtime.gameplayState?.playerParty[2].nickname, "Lead")
    }

    func testFieldPartyReorderSelectionClearsAfterFieldInput() {
        let runtime = GameRuntime(content: fixtureContent(), telemetryPublisher: nil)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.playerPosition = .init(x: 1, y: 1)
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
            runtime.makePokemon(speciesID: "RATTATA", level: 4, nickname: "Fang"),
        ]

        runtime.handlePartySidebarSelection(0)
        XCTAssertEqual(runtime.fieldPartyReorderState?.selectedIndex, 0)

        runtime.handle(button: .right)
        XCTAssertNil(runtime.fieldPartyReorderState)

        runtime.handlePartySidebarSelection(2)
        XCTAssertEqual(runtime.fieldPartyReorderState?.selectedIndex, 2)
        XCTAssertEqual(runtime.gameplayState?.playerParty[0].nickname, "Lead")
        XCTAssertEqual(runtime.gameplayState?.playerParty[2].nickname, "Fang")
    }

    func testFieldMedicineSelectionAppliesPotionAndShowsDialogue() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
        ]
        let wingMaxHP = runtime.gameplayState?.playerParty[1].maxHP ?? 12
        runtime.gameplayState?.playerParty[1].currentHP = max(
            1,
            wingMaxHP - 5
        )
        runtime.gameplayState?.inventory = [.init(itemID: "POTION", quantity: 1)]

        runtime.handleInventorySidebarSelection("POTION")

        XCTAssertEqual(runtime.fieldItemUseItemID, "POTION")

        runtime.handlePartySidebarSelection(1)

        XCTAssertNil(runtime.fieldItemUseItemID)
        XCTAssertEqual(runtime.itemQuantity("POTION"), 0)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(
            runtime.currentDialoguePage?.lines.joined(separator: " "),
            "Wing recovered by 5!"
        )

        advanceDialogueUntilComplete(runtime)
        XCTAssertEqual(runtime.scene, .field)
    }

    func testFieldMedicineSelectionShowsNoEffectWithoutEnteringTargeting() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "POTION", quantity: 1)]

        runtime.handleInventorySidebarSelection("POTION")

        XCTAssertNil(runtime.fieldItemUseItemID)
        XCTAssertEqual(runtime.itemQuantity("POTION"), 1)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(
            runtime.currentDialoguePage?.lines.joined(separator: " "),
            "It won't have any effect."
        )
    }

    func testFieldItemUseModalBlocksHeldMovementAndSaveability() throws {
        let runtime = try makeRepoRuntime()

        var gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        gameplayState.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
        ]
        let leadMaxHP = gameplayState.playerParty[0].maxHP
        gameplayState.playerParty[0].currentHP = max(
            1,
            leadMaxHP - 5
        )
        gameplayState.inventory = [.init(itemID: "POTION", quantity: 1)]
        runtime.gameplayState = gameplayState

        let originalPosition = runtime.playerPosition
        runtime.handleInventorySidebarSelection("POTION")

        XCTAssertEqual(runtime.currentFieldModalKind, .itemUse)
        XCTAssertEqual(runtime.fieldItemUseItemID, "POTION")
        XCTAssertTrue(runtime.isFieldInputLocked)
        XCTAssertFalse(runtime.canSaveGame)
        XCTAssertFalse(runtime.canContinueHeldFieldMovement)

        runtime.setDirectionalButton(.right, isPressed: true)

        XCTAssertEqual(runtime.playerPosition, originalPosition)
        XCTAssertEqual(runtime.fieldItemUseItemID, "POTION")
    }

    func testPromptModalKindTakesPriorityOverPlainDialogueAndBlocksSidebarSelection() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .dialogue
        runtime.substate = "dialogue_prompt"
        runtime.dialogueState = DialogueState(
            dialogueID: "field_prompt_dialogue",
            pages: [.init(lines: ["Use the machine?"], waitsForPrompt: true)],
            replacements: [:],
            pageIndex: 0,
            completionAction: .continueScript
        )
        runtime.fieldPromptState = RuntimeFieldPromptState(
            interactionID: "field_prompt",
            kind: .yesNo,
            completionAction: .continueScript,
            focusedIndex: 0
        )
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Shell"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "TM_BIDE", quantity: 1)]

        let gameplayState = try? XCTUnwrap(runtime.gameplayState)

        XCTAssertEqual(runtime.currentFieldModalKind, .prompt)
        XCTAssertEqual(runtime.currentFieldInteractionPolicy.modalKind, .prompt)
        XCTAssertTrue(runtime.currentFieldInteractionPolicy.blocksPartySidebarSelection)
        XCTAssertTrue(runtime.currentFieldInteractionPolicy.blocksInventorySidebarSelection)
        XCTAssertEqual(runtime.currentDialoguePage?.lines, ["Use the machine?"])
        XCTAssertFalse(
            runtime.canHandleFieldInventorySidebarSelection(
                itemID: "TM_BIDE",
                gameplayState: gameplayState ?? runtime.makeInitialGameplayState()
            )
        )
        XCTAssertFalse(
            runtime.canHandleFieldPartySidebarSelection(
                index: 0,
                gameplayState: gameplayState ?? runtime.makeInitialGameplayState()
            )
        )
    }

    func testFieldTMHMSelectionAppliesTMAndConsumesOnSuccessfulTeach() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Shell"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "TM_BIDE", quantity: 1)]

        runtime.handleInventorySidebarSelection("TM_BIDE")

        XCTAssertEqual(runtime.currentFieldItemUseMode, .tmhm)
        XCTAssertEqual(runtime.fieldItemUseItemID, "TM_BIDE")

        runtime.handlePartySidebarSelection(0)

        XCTAssertNil(runtime.fieldItemUseItemID)
        XCTAssertNil(runtime.currentFieldLearnMoveState)
        XCTAssertEqual(runtime.itemQuantity("TM_BIDE"), 0)
        XCTAssertTrue(runtime.gameplayState?.playerParty[0].moves.contains(where: { $0.id == "BIDE" }) == true)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.currentDialoguePage?.lines.joined(separator: " "), "Shell learned BIDE!")
    }

    func testFieldTMHMSelectionShowsNoEffectWhenNoPartyCanLearnMove() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Flare"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "HM_SURF", quantity: 1)]

        runtime.handleInventorySidebarSelection("HM_SURF")

        XCTAssertNil(runtime.fieldItemUseItemID)
        XCTAssertNil(runtime.currentFieldLearnMoveState)
        XCTAssertEqual(runtime.itemQuantity("HM_SURF"), 1)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.currentDialoguePage?.lines.joined(separator: " "), "It won't have any effect.")
    }

    func testFieldItemUseTargetingCanCancelWithEscape() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Shell"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "TM_BIDE", quantity: 1)]

        runtime.handleInventorySidebarSelection("TM_BIDE")

        XCTAssertEqual(runtime.currentFieldModalKind, .itemUse)
        XCTAssertEqual(runtime.fieldItemUseItemID, "TM_BIDE")

        runtime.handle(button: .cancel)

        XCTAssertNil(runtime.fieldItemUseItemID)
        XCTAssertNil(runtime.currentFieldModalKind)
        XCTAssertEqual(runtime.itemQuantity("TM_BIDE"), 1)
        XCTAssertEqual(runtime.scene, .field)
    }

    func testFieldTMHMLearnOverlayBlocksForgettingHMAndRetainsHMItem() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Flare"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "HM_STRENGTH", quantity: 1)]

        runtime.handleInventorySidebarSelection("HM_STRENGTH")
        runtime.handlePartySidebarSelection(0)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .confirm)

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .replace)

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.currentDialoguePage?.lines.joined(separator: " "), "Cut can't be forgotten.")
        XCTAssertEqual(runtime.itemQuantity("HM_STRENGTH"), 1)

        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .replace)

        runtime.handle(button: .down)
        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.itemQuantity("HM_STRENGTH"), 1)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertTrue(runtime.currentDialoguePage?.lines.joined(separator: " ").contains("Flare forgot Scratch.") == true)
        XCTAssertTrue(runtime.gameplayState?.playerParty[0].moves.map(\.id).contains("STRENGTH") == true)
        XCTAssertFalse(runtime.gameplayState?.playerParty[0].moves.map(\.id).contains("SCRATCH") == true)

        advanceDialogueUntilComplete(runtime)

        XCTAssertNil(runtime.currentFieldLearnMoveState)
    }

    func testFieldTMHMDecliningLearnPromptKeepsTMAndKnownMovesUnchanged() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Shell"),
        ]
        runtime.gameplayState?.playerParty[0].moves.append(.init(id: "WATER_GUN", currentPP: 25))
        runtime.gameplayState?.inventory = [.init(itemID: "TM_BIDE", quantity: 1)]

        let originalMoves = runtime.gameplayState?.playerParty[0].moves.map(\.id)

        runtime.handleInventorySidebarSelection("TM_BIDE")
        runtime.handlePartySidebarSelection(0)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .confirm)

        runtime.handle(button: .cancel)

        XCTAssertNil(runtime.currentFieldLearnMoveState)
        XCTAssertEqual(runtime.itemQuantity("TM_BIDE"), 1)
        XCTAssertEqual(runtime.gameplayState?.playerParty[0].moves.map(\.id), originalMoves)
        XCTAssertEqual(runtime.scene, .dialogue)
        XCTAssertEqual(runtime.currentDialoguePage?.lines.joined(separator: " "), "Shell did not learn BIDE.")
    }

    func testFieldTMHMLearnOverlayDirectionalBridgeNavigatesConfirmAndReplaceStages() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Flare"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "HM_STRENGTH", quantity: 1)]

        runtime.handleInventorySidebarSelection("HM_STRENGTH")
        runtime.handlePartySidebarSelection(0)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .confirm)
        XCTAssertEqual(runtime.currentFieldLearnMoveState?.focusedIndex, 0)

        runtime.setDirectionalButton(.down, isPressed: true)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .confirm)
        XCTAssertEqual(runtime.currentFieldLearnMoveState?.focusedIndex, 1)

        runtime.setDirectionalButton(.up, isPressed: true)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.focusedIndex, 0)

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .replace)
        XCTAssertEqual(runtime.currentFieldLearnMoveState?.focusedIndex, 0)

        runtime.setDirectionalButton(.down, isPressed: true)

        XCTAssertEqual(runtime.currentFieldLearnMoveState?.stage, .replace)
        XCTAssertEqual(runtime.currentFieldLearnMoveState?.focusedIndex, 1)
    }

    func testLearnMoveModalKindTakesPriorityOverItemUseTargeting() {
        let runtime = makeTMHMFieldRuntime()

        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "CHARMANDER", level: 5, nickname: "Flare"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "HM_STRENGTH", quantity: 1)]

        runtime.handleInventorySidebarSelection("HM_STRENGTH")
        XCTAssertEqual(runtime.currentFieldModalKind, .itemUse)

        runtime.handlePartySidebarSelection(0)

        XCTAssertEqual(runtime.currentFieldModalKind, .learnMove)
        XCTAssertEqual(runtime.currentFieldModalItemID, "HM_STRENGTH")
        XCTAssertTrue(runtime.currentFieldInteractionPolicy.blocksInventorySidebarSelection)
        XCTAssertTrue(runtime.currentFieldInteractionPolicy.blocksPartySidebarSelection)
    }

    private func makeTMHMFieldRuntime() -> GameRuntime {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    species: [
                        .init(
                            id: "SQUIRTLE",
                            displayName: "Squirtle",
                            primaryType: "WATER",
                            baseHP: 44,
                            baseAttack: 48,
                            baseDefense: 65,
                            baseSpeed: 43,
                            baseSpecial: 50,
                            startingMoves: ["TACKLE", "TAIL_WHIP", "BUBBLE"],
                            tmhmLearnset: ["BIDE", "SURF"]
                        ),
                        .init(
                            id: "CHARMANDER",
                            displayName: "Charmander",
                            primaryType: "FIRE",
                            baseHP: 39,
                            baseAttack: 52,
                            baseDefense: 43,
                            baseSpeed: 65,
                            baseSpecial: 50,
                            startingMoves: ["CUT", "SCRATCH", "GROWL", "EMBER"],
                            tmhmLearnset: ["STRENGTH"]
                        ),
                    ],
                    items: [
                        .init(id: "TM_BIDE", displayName: "TM34", bagSection: .tmhm, tmhmMoveID: "BIDE"),
                        .init(id: "HM_SURF", displayName: "HM03", bagSection: .tmhm, tmhmMoveID: "SURF"),
                        .init(id: "HM_STRENGTH", displayName: "HM04", bagSection: .tmhm, tmhmMoveID: "STRENGTH"),
                    ],
                    moves: [
                        .init(id: "TACKLE", displayName: "Tackle", power: 40, accuracy: 100, maxPP: 35, effect: "damage", type: "NORMAL"),
                        .init(id: "TAIL_WHIP", displayName: "Tail Whip", power: 0, accuracy: 100, maxPP: 30, effect: "defenseDown", type: "NORMAL"),
                        .init(id: "BUBBLE", displayName: "Bubble", power: 20, accuracy: 100, maxPP: 30, effect: "damage", type: "WATER"),
                        .init(id: "WATER_GUN", displayName: "Water Gun", power: 40, accuracy: 100, maxPP: 25, effect: "damage", type: "WATER"),
                        .init(id: "CUT", displayName: "Cut", power: 50, accuracy: 95, maxPP: 30, effect: "damage", type: "NORMAL"),
                        .init(id: "SCRATCH", displayName: "Scratch", power: 40, accuracy: 100, maxPP: 35, effect: "damage", type: "NORMAL"),
                        .init(id: "GROWL", displayName: "Growl", power: 0, accuracy: 100, maxPP: 40, effect: "attackDown", type: "NORMAL"),
                        .init(id: "EMBER", displayName: "Ember", power: 40, accuracy: 100, maxPP: 25, effect: "damage", type: "FIRE"),
                        .init(id: "BIDE", displayName: "BIDE", power: 0, accuracy: 100, maxPP: 10, effect: "bide", type: "NORMAL"),
                        .init(id: "SURF", displayName: "Surf", power: 95, accuracy: 100, maxPP: 15, effect: "damage", type: "WATER"),
                        .init(id: "STRENGTH", displayName: "Strength", power: 80, accuracy: 100, maxPP: 15, effect: "damage", type: "NORMAL"),
                    ]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        return runtime
    }

    func testPurchaseItemRejectsNewSlotWhenBagIsFull() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    items: [.init(id: "POKE_BALL", displayName: "POKé BALL", price: 200, battleUse: .ball)]
                )
            ),
            telemetryPublisher: nil
        )
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.inventory = (0..<GameRuntime.bagItemCapacity).map { index in
            .init(itemID: "ITEM_\(index)", quantity: 1)
        }

        XCTAssertFalse(runtime.purchaseItem("POKE_BALL", quantity: 1))
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 0)
        XCTAssertEqual(runtime.playerMoney, 3000)
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
    func testRepoGeneratedViridianForestTrainerAutoEngagesOnLineOfSight() async throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "VIRIDIAN_FOREST"
        runtime.gameplayState?.playerPosition = TilePoint(x: 25, y: 33)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 8, nickname: "Squirtle")]

        runtime.movePlayer(in: .right)

        let alertSnapshot = try await waitForSnapshot(runtime, timeout: 0.5) {
            $0.field?.alert?.objectID == "viridian_forest_bug_catcher_1"
        }

        XCTAssertEqual(alertSnapshot.field?.alert, .init(objectID: "viridian_forest_bug_catcher_1", kind: .exclamation))
        XCTAssertEqual(alertSnapshot.audio?.trackID, "MUSIC_MEET_MALE_TRAINER")
        XCTAssertEqual(alertSnapshot.audio?.reason, "trainerEncounter")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_MEET_MALE_TRAINER", entryID: "default"))

        let snapshot = try await waitForSnapshot(runtime, timeout: 2.0) {
            $0.battle?.battleID == "opp_bug_catcher_1"
        }

        XCTAssertEqual(snapshot.battle?.battleID, "opp_bug_catcher_1")
        XCTAssertEqual(runtime.scene, .battle)
        XCTAssertNil(snapshot.field?.alert)

        XCTAssertEqual(snapshot.audio?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(snapshot.audio?.reason, "battle")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_TRAINER_BATTLE", entryID: "default"))
    }
    func testRepoGeneratedPalletNorthExitStartsOakIntroFromSourceScript() async throws {
        let content = try loadRepoContent()
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

    func testRepoGeneratedFirstRoute22RivalTriggerStartsBattleAndClearsFlagsAfterWin() throws {
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

        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "SQUIRTLE", level: 18, nickname: "Squirtle")]
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "OAKS_LAB"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 5)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.activeFlags.insert("EVENT_BATTLED_RIVAL_IN_OAKS_LAB")
        runtime.beginScript(id: "oaks_lab_parcel_handoff")

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .field
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_POKEDEX") ?? false)
                && ($0.eventFlags?.activeFlags.contains("EVENT_1ST_ROUTE22_RIVAL_BATTLE") ?? false)
                && ($0.eventFlags?.activeFlags.contains("EVENT_ROUTE22_RIVAL_WANTS_BATTLE") ?? false)
        })

        XCTAssertTrue(runtime.gameplayState?.objectStates["route_22_rival_1"]?.visible ?? false)

        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_22"
        runtime.gameplayState?.playerPosition = .init(x: 29, y: 4)
        runtime.gameplayState?.facing = .right

        runtime.evaluateMapScriptsIfNeeded()

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .battle
        })

        XCTAssertEqual(runtime.gameplayState?.activeMapScriptTriggerID, "first_rival_upper_after_squirtle")
        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "route_22_rival_1_5_upper")
        XCTAssertEqual(battle.postBattleScriptID, "route_22_rival_1_exit_upper")

        runtime.finishBattle(battle: battle, won: true)

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE") ?? false)
        })

        XCTAssertTrue(runtime.hasFlag("EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE"))
        XCTAssertFalse(runtime.hasFlag("EVENT_1ST_ROUTE22_RIVAL_BATTLE"))
        XCTAssertFalse(runtime.hasFlag("EVENT_ROUTE22_RIVAL_WANTS_BATTLE"))
        XCTAssertFalse(runtime.gameplayState?.objectStates["route_22_rival_1"]?.visible ?? true)
        XCTAssertFalse(runtime.currentFieldObjects.contains(where: { $0.id == "route_22_rival_1" }))
    }

    func testRepoGeneratedRoute22GatePushesPlayerBackWithoutBoulderBadge() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_22_GATE"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 2)
        runtime.gameplayState?.facing = .up

        runtime.evaluateMapScriptsIfNeeded()

        advanceDialogueUntilComplete(runtime, maxInteractions: 4)
        _ = try await waitForSnapshot(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && runtime.gameplayState?.playerPosition == .init(x: 4, y: 3)
        }

        XCTAssertEqual(runtime.gameplayState?.activeMapScriptTriggerID, "guard_blocks_upper_lane_without_boulder_badge")
        XCTAssertEqual(runtime.gameplayState?.playerPosition, .init(x: 4, y: 3))
        XCTAssertFalse(runtime.hasFlag("EVENT_BEAT_BROCK"))
    }

    func testRepoGeneratedBrockInteractionStartsBattleAndAwardsBadgeAndTM() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PEWTER_GYM"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 4)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 24, nickname: "Wartortle")]

        let brock = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "pewter_gym_brock" })
        runtime.interact(with: brock)

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .battle
        })

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_brock_1")
        XCTAssertEqual(battle.postBattleScriptID, "pewter_gym_brock_reward")

        runtime.finishBattle(battle: battle, won: true)

        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_TM34") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["boulder"]))
        XCTAssertTrue(runtime.hasFlag("EVENT_BEAT_BROCK"))
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_TM34"))
        XCTAssertEqual(runtime.itemQuantity("TM_BIDE"), 1)
    }

    func testRepoGeneratedBrockRewardScriptRetriesTMUntilBagHasRoomAndKeepsBadgeNormalized() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "PEWTER_GYM"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 3)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.inventory = Array(
            runtime.content.gameplayManifest.items
                .map(\.id)
                .filter { $0 != "TM_BIDE" }
                .prefix(GameRuntime.bagItemCapacity)
                .enumerated()
                .map { index, itemID in
                    RuntimeInventoryItemState(itemID: itemID, quantity: index == 0 ? 2 : 1)
                }
        )

        runtime.beginScript(id: "pewter_gym_brock_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_BEAT_BROCK") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["boulder"]))
        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_BEAT_BROCK") ?? false)
        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_GOT_TM34") ?? true)
        XCTAssertNil(runtime.gameplayState?.inventory.first { $0.itemID == "TM_BIDE" })
        XCTAssertFalse(runtime.gameplayState?.objectStates["pewter_city_youngster"]?.visible ?? true)
        XCTAssertFalse(runtime.gameplayState?.objectStates["route_22_rival_1"]?.visible ?? true)

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "pewter_gym_brock_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_TM34") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["boulder"]))
        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_GOT_TM34") ?? false)
        XCTAssertEqual(runtime.gameplayState?.inventory.first { $0.itemID == "TM_BIDE" }?.quantity, 1)
    }

    func testRepoGeneratedMistyInteractionStartsBattleAndAwardsCascadeBadgeAndTM11() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_GYM"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 3)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "BULBASAUR"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "IVYSAUR", level: 26, nickname: "Ivysaur")]

        let misty = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "cerulean_gym_misty" })
        runtime.interact(with: misty)

        drainDialogueAndScripts(runtime, until: {
            $0.scene == .battle
        })

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_misty_1")
        XCTAssertEqual(battle.postBattleScriptID, "cerulean_gym_misty_reward")

        runtime.finishBattle(battle: battle, won: true)

        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_TM11") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["cascade"]))
        XCTAssertTrue(runtime.hasFlag("EVENT_BEAT_MISTY"))
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_TM11"))
        XCTAssertEqual(runtime.itemQuantity("TM_BUBBLEBEAM"), 1)
    }

    func testRepoGeneratedMistyRewardScriptRetriesTMUntilBagHasRoomAndPersistsCascadeBadge() throws {
        let saveStore = InMemorySaveStore()
        let content = try loadRepoContent()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_GYM"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 3)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.inventory = fullBagInventory(for: runtime, excluding: ["TM_BUBBLEBEAM"])

        runtime.beginScript(id: "cerulean_gym_misty_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_BEAT_MISTY") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["cascade"]))
        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_BEAT_MISTY") ?? false)
        XCTAssertFalse(runtime.gameplayState?.activeFlags.contains("EVENT_GOT_TM11") ?? true)
        XCTAssertNil(runtime.gameplayState?.inventory.first { $0.itemID == "TM_BUBBLEBEAM" })

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "cerulean_gym_misty_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_TM11") ?? false)
        }

        XCTAssertEqual(runtime.gameplayState?.earnedBadgeIDs, Set(["cascade"]))
        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_GOT_TM11") ?? false)
        XCTAssertEqual(runtime.gameplayState?.inventory.first { $0.itemID == "TM_BUBBLEBEAM" }?.quantity, 1)

        let envelope = try runtime.makeSaveEnvelope()
        saveStore.envelope = envelope

        let resumed = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertTrue(resumed.continueFromTitleMenu())
        XCTAssertEqual(resumed.earnedBadgeIDs, Set(["cascade"]))
        XCTAssertTrue(resumed.hasFlag("EVENT_BEAT_MISTY"))
        XCTAssertTrue(resumed.hasFlag("EVENT_GOT_TM11"))
        XCTAssertEqual(resumed.itemQuantity("TM_BUBBLEBEAM"), 1)
    }

    func testRepoGeneratedCaptainRewardScriptGrantsHM01AndPersistsAcrossSaveLoad() throws {
        let saveStore = InMemorySaveStore()
        let content = try loadRepoContent()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"

        runtime.beginScript(id: "ss_anne_captains_room_captain_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_HM01") ?? false)
        }

        XCTAssertTrue(runtime.hasFlag("EVENT_RUBBED_CAPTAINS_BACK"))
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_HM01"))
        XCTAssertEqual(runtime.itemQuantity("HM_CUT"), 1)

        let envelope = try runtime.makeSaveEnvelope()
        saveStore.envelope = envelope

        let resumed = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertTrue(resumed.continueFromTitleMenu())
        XCTAssertTrue(resumed.hasFlag("EVENT_RUBBED_CAPTAINS_BACK"))
        XCTAssertTrue(resumed.hasFlag("EVENT_GOT_HM01"))
        XCTAssertEqual(resumed.itemQuantity("HM_CUT"), 1)
    }

    func testRepoGeneratedCaptainRewardScriptPlaysHealJingleThenRestoresMapMusic() throws {
        let audioPlayer = RecordingAudioPlayer()
        let runtime = try makeRepoRuntime(audioPlayer: audioPlayer)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"

        runtime.beginScript(id: "ss_anne_captains_room_captain_reward")

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "ss_anne_captains_room_rub_captains_back")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "ss_anne_captains_room_rub_captains_back")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "ss_anne_captains_room_rub_captains_back")
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_PKMN_HEALED", entryID: "default"))

        audioPlayer.completePendingPlayback()
        XCTAssertEqual(audioPlayer.musicRequests.last, .init(trackID: "MUSIC_ROUTES1", entryID: "default"))

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "ss_anne_captains_room_captain_i_feel_much_better")
    }

    func testRepoGeneratedCaptainRewardScriptRetriesHMUntilBagHasRoom() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.inventory = fullBagInventory(for: runtime, excluding: ["HM_CUT"])

        runtime.beginScript(id: "ss_anne_captains_room_captain_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_RUBBED_CAPTAINS_BACK") ?? false)
        }

        XCTAssertTrue(runtime.hasFlag("EVENT_RUBBED_CAPTAINS_BACK"))
        XCTAssertFalse(runtime.hasFlag("EVENT_GOT_HM01"))
        XCTAssertEqual(runtime.itemQuantity("HM_CUT"), 0)

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "ss_anne_captains_room_captain_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_HM01") ?? false)
        }

        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_HM01"))
        XCTAssertEqual(runtime.itemQuantity("HM_CUT"), 1)
    }

    func testRepoGeneratedCaptainRewardScriptDoesNotGrantDuplicateHM01AfterRewardFlag() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.activeFlags.insert("EVENT_GOT_HM01")
        runtime.gameplayState?.inventory = [.init(itemID: "HM_CUT", quantity: 1)]

        runtime.beginScript(id: "ss_anne_captains_room_captain_reward")

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "ss_anne_captains_room_captain_not_sick_anymore")
        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.itemQuantity("HM_CUT"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_HM01"))
    }

    func testRepoGeneratedRoute2CutObstacleRequiresCascadeBadge() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"

        let setup = try route2CutInteractionSetup(for: runtime)
        runtime.gameplayState?.playerPosition = setup.position
        runtime.gameplayState?.facing = setup.facing

        XCTAssertFalse(runtime.canMove(from: setup.position, to: setup.target, in: setup.map, facing: setup.facing))

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "field_move_new_badge_required")
        XCTAssertNil(runtime.currentSnapshot().fieldPrompt)
    }

    func testRepoGeneratedRoute2CutObstacleRequiresPokemonKnowingCut() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"
        runtime.gameplayState?.earnedBadgeIDs = ["cascade"]
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "PIDGEY", level: 16, nickname: "Pidgey")]

        let setup = try route2CutInteractionSetup(for: runtime)
        runtime.gameplayState?.playerPosition = setup.position
        runtime.gameplayState?.facing = setup.facing

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "field_move_nothing_to_cut")
        XCTAssertNil(runtime.currentSnapshot().fieldPrompt)
    }

    func testRepoGeneratedRoute2CutObstacleUsesFirstEligiblePokemonAndOpensTraversal() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"
        runtime.gameplayState?.earnedBadgeIDs = ["cascade"]

        var lead = runtime.makePokemon(speciesID: "PIDGEY", level: 16, nickname: "Lead")
        lead.moves = [.init(id: "GUST", currentPP: 35)]
        var cutterA = runtime.makePokemon(speciesID: "ODDISH", level: 18, nickname: "Leafy")
        cutterA.moves = [.init(id: "CUT", currentPP: 30)]
        var cutterB = runtime.makePokemon(speciesID: "FARFETCHD", level: 20, nickname: "Twig")
        cutterB.moves = [.init(id: "CUT", currentPP: 30)]
        runtime.gameplayState?.playerParty = [lead, cutterA, cutterB]

        let setup = try route2CutInteractionSetup(for: runtime)
        runtime.gameplayState?.playerPosition = setup.position
        runtime.gameplayState?.facing = setup.facing

        XCTAssertFalse(runtime.canMove(from: setup.position, to: setup.target, in: setup.map, facing: setup.facing))

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "field_obstacle_cut_prompt")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])

        runtime.handle(button: .confirm)

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "field_move_used_cut")
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.lines, ["Leafy hacked", "away with CUT!"])
        XCTAssertEqual(
            runtime.currentMapManifest?.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x],
            setup.obstacle.replacementBlockID
        )
        XCTAssertTrue(
            runtime.canMove(
                from: setup.position,
                to: setup.target,
                in: try XCTUnwrap(runtime.currentMapManifest),
                facing: setup.facing
            )
        )

        advanceDialogueUntilComplete(runtime)
        runtime.movePlayer(in: setup.facing)
        XCTAssertEqual(runtime.gameplayState?.playerPosition, setup.target)
    }

    func testRepoGeneratedRoute2CutObstacleDoesNotTriggerFromNonCutQuadrant() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"
        runtime.gameplayState?.earnedBadgeIDs = ["cascade"]

        var cutter = runtime.makePokemon(speciesID: "ODDISH", level: 18, nickname: "Leafy")
        cutter.moves = [.init(id: "CUT", currentPP: 30)]
        runtime.gameplayState?.playerParty = [cutter]

        let setup = try route2NonCutQuadrantInteractionSetup(for: runtime)
        runtime.gameplayState?.playerPosition = setup.position
        runtime.gameplayState?.facing = setup.facing

        runtime.interactAhead()

        XCTAssertNil(runtime.currentSnapshot().dialogue)
        XCTAssertNil(runtime.currentSnapshot().fieldPrompt)
        XCTAssertEqual(
            runtime.currentMapManifest?.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x],
            setup.map.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x]
        )
    }

    func testRepoGeneratedRoute2CutObstacleResetAfterLoadAndIsNotSerialized() throws {
        let saveStore = InMemorySaveStore()
        let content = try loadRepoContent()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_2"
        runtime.gameplayState?.earnedBadgeIDs = ["cascade"]

        var cutter = runtime.makePokemon(speciesID: "ODDISH", level: 18, nickname: "Leafy")
        cutter.moves = [.init(id: "CUT", currentPP: 30)]
        runtime.gameplayState?.playerParty = [cutter]

        let setup = try route2CutInteractionSetup(for: runtime)
        runtime.gameplayState?.playerPosition = setup.position
        runtime.gameplayState?.facing = setup.facing

        runtime.interactAhead()
        runtime.handle(button: .confirm)
        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(
            runtime.currentMapManifest?.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x],
            setup.obstacle.replacementBlockID
        )

        let envelope = try runtime.makeSaveEnvelope()
        saveStore.envelope = envelope

        let resumed = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertTrue(resumed.continueFromTitleMenu())

        resumed.gameplayState?.playerPosition = setup.position
        resumed.gameplayState?.facing = setup.facing

        XCTAssertEqual(
            resumed.currentMapManifest?.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x],
            setup.map.blockIDs[(setup.obstacle.blockPosition.y * setup.map.blockWidth) + setup.obstacle.blockPosition.x]
        )
        XCTAssertFalse(
            resumed.canMove(
                from: setup.position,
                to: setup.target,
                in: try XCTUnwrap(resumed.currentMapManifest),
                facing: setup.facing
            )
        )
    }

    func testRepoGeneratedCeruleanGymSwimmerSightlineStartsBattle() async throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_GYM"
        runtime.gameplayState?.playerPosition = .init(x: 5, y: 8)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 26, nickname: "Wartortle")]

        runtime.movePlayer(in: .up)

        _ = try await waitForSnapshot(runtime, timeout: 2.5) { _ in
            runtime.dialogueState != nil || runtime.gameplayState?.battle != nil
        }

        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_swimmer_1")
    }

    func testRepoGeneratedMtMoonSuperNerdBattleThenDomeFossilChoiceUpdatesState() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "MT_MOON_B2F"
        runtime.gameplayState?.playerPosition = .init(x: 13, y: 8)
        runtime.gameplayState?.facing = .left
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 28, nickname: "Wartortle")]

        runtime.evaluateMapScriptsIfNeeded()
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_super_nerd_2")

        runtime.finishBattle(battle: battle, won: true)
        advanceDialogueUntilComplete(runtime)

        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.dialogueState)
        XCTAssertNil(runtime.gameplayState?.activeScriptID)
        XCTAssertNil(runtime.gameplayState?.activeScriptStep)
        XCTAssertTrue(runtime.hasFlag("EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD"))
        XCTAssertTrue(runtime.isReadyForFreeFieldStep)
        runtime.gameplayState?.playerPosition = .init(x: 12, y: 7)
        runtime.gameplayState?.facing = .up

        runtime.interactAhead()

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "mt_moon_b2f_dome_fossil_you_want")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])

        runtime.handle(button: .confirm)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_DOME_FOSSIL") ?? false)
        }

        XCTAssertEqual(runtime.itemQuantity("DOME_FOSSIL"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_DOME_FOSSIL"))
        XCTAssertFalse(runtime.currentFieldObjects.contains(where: { $0.id == "mt_moon_b2f_dome_fossil" }))
        XCTAssertFalse(runtime.currentFieldObjects.contains(where: { $0.id == "mt_moon_b2f_helix_fossil" }))
        XCTAssertTrue(runtime.currentFieldObjects.contains(where: { $0.id == "mt_moon_b2f_super_nerd" }))
        XCTAssertEqual(runtime.scene, .field)
        XCTAssertNil(runtime.dialogueState)
        XCTAssertNil(runtime.gameplayState?.activeScriptID)
        XCTAssertNil(runtime.gameplayState?.activeScriptStep)
        XCTAssertTrue(runtime.isReadyForFreeFieldStep)
    }

    func testRepoGeneratedRoute4TrainerAndPickupResolveInField() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_4"
        runtime.gameplayState?.playerPosition = .init(x: 62, y: 3)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 24, nickname: "Wartortle")]

        let trainer = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "route4_cooltrainer_f2" })
        runtime.interact(with: trainer)
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_lass_4")
        let completionFlagID = try XCTUnwrap(runtime.content.trainerBattle(id: battle.battleID)?.completionFlagID)

        runtime.finishBattle(battle: battle, won: true)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && runtime.hasFlag(completionFlagID)
        }

        let pickup = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "route_4_tm_whirlwind" })
        runtime.interact(with: pickup)

        XCTAssertEqual(runtime.itemQuantity("TM_WHIRLWIND"), 1)
        XCTAssertFalse(runtime.currentFieldObjects.contains(where: { $0.id == "route_4_tm_whirlwind" }))
    }

    func testRepoGeneratedRoute24GenericTrainerBattleCompletes() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_24"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 20)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 26, nickname: "Wartortle")]

        let trainer = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "route24_cooltrainer_m_2" })
        runtime.interact(with: trainer)
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_jr_trainer_m_2")
        let completionFlagID = try XCTUnwrap(runtime.content.trainerBattle(id: battle.battleID)?.completionFlagID)

        runtime.finishBattle(battle: battle, won: true)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && runtime.hasFlag(completionFlagID)
        }
    }

    func testRepoGeneratedRoute25GenericTrainerBattleCompletes() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_25"
        runtime.gameplayState?.playerPosition = .init(x: 13, y: 2)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 26, nickname: "Wartortle")]

        let trainer = try XCTUnwrap(runtime.currentFieldObjects.first { $0.id == "route25_youngster_1" })
        runtime.interact(with: trainer)
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_youngster_5")
        let completionFlagID = try XCTUnwrap(runtime.content.trainerBattle(id: battle.battleID)?.completionFlagID)

        runtime.finishBattle(battle: battle, won: true)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && runtime.hasFlag(completionFlagID)
        }
    }

    func testRepoGeneratedCeruleanRivalTriggerStartsBattleAndHidesRivalAfterWin() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_CITY"
        runtime.gameplayState?.playerPosition = .init(x: 20, y: 6)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 26, nickname: "Wartortle")]

        runtime.evaluateMapScriptsIfNeeded()
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "cerulean_city_rival_8")
        XCTAssertEqual(battle.postBattleScriptID, "cerulean_city_rival_after_battle")

        runtime.finishBattle(battle: battle, won: true)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_BEAT_CERULEAN_RIVAL") ?? false)
        }

        XCTAssertTrue(runtime.hasFlag("EVENT_BEAT_CERULEAN_RIVAL"))
        XCTAssertFalse(runtime.gameplayState?.objectStates["cerulean_city_rival"]?.visible ?? true)
        XCTAssertFalse(runtime.currentFieldObjects.contains(where: { $0.id == "cerulean_city_rival" }))
    }

    func testRepoGeneratedCeruleanRocketRewardRetriesTMUntilBagHasRoom() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "CERULEAN_CITY"
        runtime.gameplayState?.playerPosition = .init(x: 29, y: 8)
        runtime.gameplayState?.facing = .right
        runtime.gameplayState?.inventory = fullBagInventory(for: runtime, excluding: ["TM_DIG"])

        runtime.beginScript(id: "cerulean_city_rocket_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
        }

        XCTAssertEqual(runtime.itemQuantity("TM_DIG"), 0)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_1"]?.visible, false)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_2"]?.visible, true)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_rocket"]?.visible, true)

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "cerulean_city_rocket_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && runtime.itemQuantity("TM_DIG") == 1
        }

        XCTAssertEqual(runtime.itemQuantity("TM_DIG"), 1)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_1"]?.visible, true)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_2"]?.visible, false)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_rocket"]?.visible, false)
    }

    func testRepoGeneratedRoute24RewardStopsOnBagFullAndResumesBattleAfterRetry() throws {
        let runtime = try makeRepoRuntime()

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "ROUTE_24"
        runtime.gameplayState?.playerPosition = .init(x: 10, y: 15)
        runtime.gameplayState?.facing = .up
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [runtime.makePokemon(speciesID: "WARTORTLE", level: 28, nickname: "Wartortle")]
        runtime.gameplayState?.inventory = fullBagInventory(for: runtime, excluding: ["NUGGET"])

        runtime.beginScript(id: "route24_nugget_bridge_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
        }

        XCTAssertEqual(runtime.itemQuantity("NUGGET"), 0)
        XCTAssertFalse(runtime.hasFlag("EVENT_GOT_NUGGET"))
        XCTAssertNil(runtime.gameplayState?.battle)

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "route24_nugget_bridge_reward")
        drainDialogueAndScripts(runtime) {
            $0.scene == .battle
        }

        let battle = try XCTUnwrap(runtime.gameplayState?.battle)
        XCTAssertEqual(battle.battleID, "opp_rocket_6")

        runtime.finishBattle(battle: battle, won: true)
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_NUGGET") ?? false)
        }

        XCTAssertEqual(runtime.itemQuantity("NUGGET"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_NUGGET"))
    }

    func testRepoGeneratedBillSequenceAndSSTicketUnlockPersistAcrossSave() throws {
        let saveStore = InMemorySaveStore()
        let content = try loadRepoContent()
        let runtime = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.mapID = "BILLS_HOUSE"
        runtime.gameplayState?.playerPosition = .init(x: 4, y: 5)
        runtime.gameplayState?.facing = .up

        runtime.beginScript(id: "bills_house_bill_pokemon_interaction")

        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bills_house_bill_im_not_a_pokemon")
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.options, ["YES", "NO"])

        runtime.handle(button: .right)
        XCTAssertEqual(runtime.currentSnapshot().fieldPrompt?.focusedIndex, 1)
        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().dialogue?.dialogueID, "bills_house_bill_no_you_gotta_help")

        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_MET_BILL") ?? false)
        }

        XCTAssertTrue(runtime.hasFlag("EVENT_BILL_SAID_USE_CELL_SEPARATOR"))
        XCTAssertTrue(runtime.hasFlag("EVENT_USED_CELL_SEPARATOR_ON_BILL"))
        XCTAssertTrue(runtime.hasFlag("EVENT_MET_BILL"))
        XCTAssertTrue(runtime.hasFlag("EVENT_MET_BILL_2"))
        XCTAssertEqual(runtime.gameplayState?.objectStates["bills_house_bill_pokemon"]?.visible, false)
        XCTAssertEqual(runtime.gameplayState?.objectStates["bills_house_bill_1"]?.visible, true)

        runtime.gameplayState?.inventory = fullBagInventory(for: runtime, excluding: ["S_S_TICKET"])
        runtime.beginScript(id: "bills_house_bill_ss_ticket")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
        }

        XCTAssertEqual(runtime.itemQuantity("S_S_TICKET"), 0)
        XCTAssertFalse(runtime.hasFlag("EVENT_GOT_SS_TICKET"))
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_1"]?.visible, false)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_2"]?.visible, true)
        XCTAssertEqual(runtime.gameplayState?.objectStates["route24_nugget_bridge_guy"]?.visible, true)

        runtime.gameplayState?.inventory.removeLast()
        runtime.beginScript(id: "bills_house_bill_ss_ticket")
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_GOT_SS_TICKET") ?? false)
        }

        XCTAssertEqual(runtime.itemQuantity("S_S_TICKET"), 1)
        XCTAssertTrue(runtime.hasFlag("EVENT_GOT_SS_TICKET"))
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_1"]?.visible, true)
        XCTAssertEqual(runtime.gameplayState?.objectStates["cerulean_city_guard_2"]?.visible, false)
        XCTAssertEqual(runtime.gameplayState?.objectStates["route24_nugget_bridge_guy"]?.visible, false)

        let envelope = try runtime.makeSaveEnvelope()
        saveStore.envelope = envelope

        let resumed = GameRuntime(content: content, telemetryPublisher: nil, saveStore: saveStore)
        XCTAssertTrue(resumed.continueFromTitleMenu())
        XCTAssertTrue(resumed.hasFlag("EVENT_MET_BILL"))
        XCTAssertTrue(resumed.hasFlag("EVENT_GOT_SS_TICKET"))
        XCTAssertEqual(resumed.itemQuantity("S_S_TICKET"), 1)
        XCTAssertEqual(resumed.gameplayState?.objectStates["bills_house_bill_pokemon"]?.visible, false)
        XCTAssertEqual(resumed.gameplayState?.objectStates["bills_house_bill_1"]?.visible, true)
        XCTAssertEqual(resumed.gameplayState?.objectStates["cerulean_city_guard_1"]?.visible, true)
        XCTAssertEqual(resumed.gameplayState?.objectStates["cerulean_city_guard_2"]?.visible, false)
        XCTAssertEqual(resumed.gameplayState?.objectStates["route24_nugget_bridge_guy"]?.visible, false)
    }

    func testLossCanContinueIntoConfiguredPostBattleScript() {
        let runtime = GameRuntime(
            content: fixtureContent(
                gameplayManifest: fixtureGameplayManifest(
                    scripts: [
                        .init(
                            id: "loss_followup",
                            steps: [.init(action: "setFlag", flagID: "EVENT_LOSS_FOLLOWUP")]
                        ),
                    ]
                )
            ),
            telemetryPublisher: nil
        )

        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"

        runtime.completeTrainerBattleDialogue(
            won: false,
            preventsBlackoutOnLoss: true,
            postBattleScriptID: "loss_followup",
            runsPostBattleScriptOnLoss: true,
            sourceTrainerObjectID: nil
        )

        drainDialogueAndScripts(runtime) {
            $0.scene == .field && ($0.eventFlags?.activeFlags.contains("EVENT_LOSS_FOLLOWUP") ?? false)
        }

        XCTAssertTrue(runtime.gameplayState?.activeFlags.contains("EVENT_LOSS_FOLLOWUP") ?? false)
    }

    private func fullBagInventory(for runtime: GameRuntime, excluding excludedItemIDs: Set<String>) -> [RuntimeInventoryItemState] {
        Array(
            runtime.content.gameplayManifest.items
                .map(\.id)
                .filter { excludedItemIDs.contains($0) == false }
                .prefix(GameRuntime.bagItemCapacity)
                .enumerated()
                .map { index, itemID in
                    RuntimeInventoryItemState(itemID: itemID, quantity: index == 0 ? 2 : 1)
                }
        )
    }

    private func route2CutInteractionSetup(
        for runtime: GameRuntime
    ) throws -> (map: MapManifest, obstacle: FieldObstacleManifest, position: TilePoint, facing: FacingDirection, target: TilePoint) {
        let map = try XCTUnwrap(runtime.currentMapManifest)
        let tileset = try XCTUnwrap(runtime.content.tileset(id: map.tileset))
        let passableTileIDs = Set(tileset.collision.passableTileIDs)
        let cutTreeCollisionTileID = 0x3D

        for obstacle in map.fieldObstacles where obstacle.kind == .cutTree {
            let target = TilePoint(
                x: (obstacle.blockPosition.x * 2) + obstacle.triggerStepOffset.x,
                y: (obstacle.blockPosition.y * 2) + obstacle.triggerStepOffset.y
            )
            let candidates: [(position: TilePoint, facing: FacingDirection, target: TilePoint)] = [
                (.init(x: target.x - 1, y: target.y), .right, target),
                (.init(x: target.x + 1, y: target.y), .left, target),
                (.init(x: target.x, y: target.y - 1), .down, target),
                (.init(x: target.x, y: target.y + 1), .up, target),
            ]

            for candidate in candidates {
                guard let playerTileID = runtime.collisionTileID(at: candidate.position, in: map),
                      passableTileIDs.contains(playerTileID) else {
                    continue
                }
                guard runtime.collisionTileID(at: candidate.target, in: map) == cutTreeCollisionTileID else {
                    continue
                }
                guard runtime.canMove(from: candidate.position, to: candidate.target, in: map, facing: candidate.facing) == false else {
                    continue
                }

                return (map, obstacle, candidate.position, candidate.facing, candidate.target)
            }
        }

        XCTFail("Expected to find a Route 2 cut obstacle with an adjacent interaction tile.")
        throw NSError(domain: "PokeCoreTests", code: 1)
    }

    private func route2NonCutQuadrantInteractionSetup(
        for runtime: GameRuntime
    ) throws -> (map: MapManifest, obstacle: FieldObstacleManifest, position: TilePoint, facing: FacingDirection, target: TilePoint) {
        let validSetup = try route2CutInteractionSetup(for: runtime)
        let map = validSetup.map
        let obstacle = validSetup.obstacle
        let tileset = try XCTUnwrap(runtime.content.tileset(id: map.tileset))
        let passableTileIDs = Set(tileset.collision.passableTileIDs)

        let stepOrigin = TilePoint(x: obstacle.blockPosition.x * 2, y: obstacle.blockPosition.y * 2)
        let stepOffsets = [
            TilePoint(x: 0, y: 0),
            TilePoint(x: 1, y: 0),
            TilePoint(x: 0, y: 1),
            TilePoint(x: 1, y: 1),
        ]

        for offset in stepOffsets where offset != obstacle.triggerStepOffset {
            let target = TilePoint(x: stepOrigin.x + offset.x, y: stepOrigin.y + offset.y)
            guard let targetTileID = runtime.collisionTileID(at: target, in: map), targetTileID != 0x3D else {
                continue
            }

            let candidates: [(position: TilePoint, facing: FacingDirection)] = [
                (.init(x: target.x - 1, y: target.y), .right),
                (.init(x: target.x + 1, y: target.y), .left),
                (.init(x: target.x, y: target.y - 1), .down),
                (.init(x: target.x, y: target.y + 1), .up),
            ]

            for candidate in candidates {
                guard let playerTileID = runtime.collisionTileID(at: candidate.position, in: map),
                      passableTileIDs.contains(playerTileID) else {
                    continue
                }
                guard runtime.canMove(from: candidate.position, to: target, in: map, facing: candidate.facing) == false else {
                    continue
                }

                return (map, obstacle, candidate.position, candidate.facing, target)
            }
        }

        XCTFail("Expected to find a non-cut blocked quadrant adjacent to a Route 2 cut obstacle.")
        throw NSError(domain: "PokeCoreTests", code: 1)
    }
}
