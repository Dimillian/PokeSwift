import Foundation
import XCTest
@testable import PokeDataModel

final class SaveCompatibilityTests: XCTestCase {
    func testGameSaveMetadataDefaultsMissingPlayTimeSeconds() throws {
        let payload = Data(
            """
            {
              "schemaVersion": 10,
              "variant": "red",
              "playthroughID": "legacy",
              "playerName": "RED",
              "locationName": "Pallet Town",
              "badgeCount": 1,
              "savedAt": "2026-03-17T12:00:00Z"
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(GameSaveMetadata.self, from: payload)
        XCTAssertEqual(decoded.playTimeSeconds, 0)
    }

    func testGameSaveSnapshotDefaultsLegacyOptionalFields() throws {
        let payload = Data(
            """
            {
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
            """.utf8
        )

        let decoded = try JSONDecoder().decode(GameSaveSnapshot.self, from: payload)

        XCTAssertEqual(decoded.currentBoxIndex, 0)
        XCTAssertEqual(decoded.boxedPokemon, [])
        XCTAssertEqual(decoded.ownedSpeciesIDs, ["SQUIRTLE"])
        XCTAssertEqual(decoded.seenSpeciesIDs, ["SQUIRTLE"])
        XCTAssertEqual(decoded.speciesEncounterCounts, [:])
        XCTAssertEqual(decoded.totalStepCount, 0)
        XCTAssertEqual(decoded.wildEncounterCount, 0)
        XCTAssertEqual(decoded.trainerBattleCount, 0)
        XCTAssertEqual(decoded.playTimeSeconds, 0)
    }

    func testGameSavePokemonDefaultsLegacyProgressAndStatusFields() throws {
        let payload = Data(
            """
            {
              "speciesID": "SQUIRTLE",
              "nickname": "Squirtle",
              "level": 5,
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
            """.utf8
        )

        let decoded = try JSONDecoder().decode(GameSavePokemon.self, from: payload)

        XCTAssertEqual(decoded.experience, 0)
        XCTAssertEqual(decoded.dvs, .zero)
        XCTAssertEqual(decoded.statExp, .zero)
        XCTAssertEqual(decoded.speedStage, 0)
        XCTAssertEqual(decoded.specialStage, 0)
        XCTAssertEqual(decoded.majorStatus, .none)
        XCTAssertEqual(decoded.statusCounter, 0)
    }

    func testRuntimeSaveResultDecodesLegacyOperationString() throws {
        let payload = Data(
            """
            {
              "operation": "continue",
              "succeeded": false,
              "message": "No save file is available.",
              "timestamp": "2026-03-17T12:00:00Z"
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(RuntimeSaveResult.self, from: payload)

        XCTAssertEqual(decoded.operation, .continue)
        XCTAssertFalse(decoded.succeeded)
        XCTAssertEqual(decoded.message, "No save file is available.")
    }

    func testSaveEnumRawValuesRemainStable() {
        XCTAssertEqual(RuntimeSaveOperation.save.rawValue, "save")
        XCTAssertEqual(RuntimeSaveOperation.load.rawValue, "load")
        XCTAssertEqual(RuntimeSaveOperation.continue.rawValue, "continue")
    }
}
