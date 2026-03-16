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
            $0.fieldHealing?.phase == "healedJingle"
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
            $0.fieldHealing?.phase == "priming" || $0.fieldHealing?.phase == "machineActive"
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
        XCTAssertEqual(shop.phase, "mainMenu")
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

        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, "result")
        XCTAssertEqual(runtime.itemQuantity("POKE_BALL"), 1)
        XCTAssertEqual(runtime.playerMoney, 2800)
        XCTAssertEqual(runtime.currentSnapshot().inventory?.items.first { $0.itemID == "POKE_BALL" }?.quantity, 1)
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

        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, "result")
        XCTAssertEqual(runtime.itemQuantity("ANTIDOTE"), 1)
        XCTAssertEqual(runtime.playerMoney, 3050)
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
        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, "result")
        XCTAssertEqual(runtime.currentSnapshot().shop?.promptText, "I can't put a price on that.")

        runtime.handle(button: .confirm)
        XCTAssertEqual(runtime.currentSnapshot().shop?.phase, "mainMenu")
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
        drainDialogueAndScripts(runtime) {
            $0.scene == .field
                && $0.dialogue == nil
                && runtime.gameplayState?.activeScriptID == nil
                && runtime.gameplayState?.activeScriptStep == nil
                && ($0.eventFlags?.activeFlags.contains("EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD") ?? false)
        }

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
}
