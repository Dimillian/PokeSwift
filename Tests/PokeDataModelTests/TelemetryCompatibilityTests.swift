import Foundation
import XCTest
@testable import PokeDataModel

final class TelemetryCompatibilityTests: XCTestCase {
    func testPartyPokemonTelemetryDecodesLegacyMoveIDs() throws {
        let payload = Data(
            """
            {
              "speciesID": "PIKACHU",
              "displayName": "Pikachu",
              "level": 12,
              "currentHP": 32,
              "maxHP": 32,
              "attack": 18,
              "defense": 15,
              "speed": 22,
              "special": 19,
              "majorStatus": "none",
              "moves": ["THUNDERBOLT", "QUICK_ATTACK"]
            }
            """.utf8
        )

        let pokemon = try JSONDecoder().decode(PartyPokemonTelemetry.self, from: payload)

        XCTAssertEqual(pokemon.moves, ["THUNDERBOLT", "QUICK_ATTACK"])
        XCTAssertEqual(
            pokemon.moveStates,
            [PartyMoveTelemetry(id: "THUNDERBOLT"), PartyMoveTelemetry(id: "QUICK_ATTACK")]
        )
    }

    func testPartyPokemonTelemetryEncodesLegacyMovesAndStructuredMoveStates() throws {
        let pokemon = PartyPokemonTelemetry(
            speciesID: "PIKACHU",
            displayName: "Pikachu",
            level: 12,
            currentHP: 32,
            maxHP: 32,
            attack: 18,
            defense: 15,
            speed: 22,
            special: 19,
            moveStates: [
                PartyMoveTelemetry(id: "THUNDERBOLT", currentPP: 10),
                PartyMoveTelemetry(id: "QUICK_ATTACK", currentPP: 30),
            ]
        )

        let payload = try JSONEncoder().encode(pokemon)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: payload) as? [String: Any])
        let encodedMoves = try XCTUnwrap(json["moves"] as? [String])
        let encodedMoveStates = try XCTUnwrap(json["moveStates"] as? [[String: Any]])

        XCTAssertEqual(encodedMoves, ["THUNDERBOLT", "QUICK_ATTACK"])
        XCTAssertEqual(encodedMoveStates.count, 2)
        XCTAssertEqual(encodedMoveStates.first?["id"] as? String, "THUNDERBOLT")
        XCTAssertEqual(encodedMoveStates.first?["currentPP"] as? Int, 10)
        XCTAssertEqual(encodedMoveStates.last?["id"] as? String, "QUICK_ATTACK")
        XCTAssertEqual(encodedMoveStates.last?["currentPP"] as? Int, 30)
    }

    func testPartyPokemonTelemetryDecodesMoveStatesWithoutLegacyMoves() throws {
        let payload = Data(
            """
            {
              "speciesID": "PIKACHU",
              "displayName": "Pikachu",
              "level": 12,
              "currentHP": 32,
              "maxHP": 32,
              "attack": 18,
              "defense": 15,
              "speed": 22,
              "special": 19,
              "majorStatus": "none",
              "moveStates": [
                { "id": "THUNDERBOLT", "currentPP": 10 },
                { "id": "QUICK_ATTACK", "currentPP": 30 }
              ]
            }
            """.utf8
        )

        let pokemon = try JSONDecoder().decode(PartyPokemonTelemetry.self, from: payload)

        XCTAssertEqual(pokemon.moves, ["THUNDERBOLT", "QUICK_ATTACK"])
        XCTAssertEqual(
            pokemon.moveStates,
            [
                PartyMoveTelemetry(id: "THUNDERBOLT", currentPP: 10),
                PartyMoveTelemetry(id: "QUICK_ATTACK", currentPP: 30),
            ]
        )
    }

    func testBattleTelemetryDecodesLegacyDefaultsAndRawPhaseValues() throws {
        let payload = Data(
            """
            {
              "battleID": "wild_route_1_pidgey_3",
              "trainerName": "PIDGEY",
              "playerPokemon": {
                "speciesID": "SQUIRTLE",
                "displayName": "Squirtle",
                "level": 5,
                "currentHP": 20,
                "maxHP": 20,
                "attack": 10,
                "defense": 11,
                "speed": 9,
                "special": 10,
                "moves": ["TACKLE"]
              },
              "enemyPokemon": {
                "speciesID": "PIDGEY",
                "displayName": "Pidgey",
                "level": 3,
                "currentHP": 12,
                "maxHP": 12,
                "attack": 8,
                "defense": 8,
                "speed": 10,
                "special": 7,
                "moves": ["TACKLE"]
              },
              "focusedMoveIndex": 1,
              "battleMessage": "Wild PIDGEY appeared!"
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(BattleTelemetry.self, from: payload)

        XCTAssertEqual(decoded.kind, .trainer)
        XCTAssertEqual(decoded.enemyPartyCount, 1)
        XCTAssertEqual(decoded.enemyActiveIndex, 0)
        XCTAssertEqual(decoded.focusedBagItemIndex, 0)
        XCTAssertEqual(decoded.focusedPartyIndex, 0)
        XCTAssertEqual(decoded.canRun, false)
        XCTAssertEqual(decoded.canUseBag, false)
        XCTAssertEqual(decoded.canSwitch, false)
        XCTAssertEqual(decoded.phase, .moveSelection)
        XCTAssertEqual(decoded.textLines, [])
        XCTAssertEqual(decoded.moveSlots, [])
        XCTAssertEqual(decoded.bagItems, [])
        XCTAssertEqual(decoded.presentation, .init(stage: .idle, revision: 0, uiVisibility: .visible))

        let phasePayload = Data(
            """
            {
              "battleID": "trainer_oak_lab",
              "trainerName": "BLUE",
              "playerPokemon": {
                "speciesID": "SQUIRTLE",
                "displayName": "Squirtle",
                "level": 5,
                "currentHP": 20,
                "maxHP": 20,
                "attack": 10,
                "defense": 11,
                "speed": 9,
                "special": 10,
                "moves": ["TACKLE"]
              },
              "enemyPokemon": {
                "speciesID": "BULBASAUR",
                "displayName": "Bulbasaur",
                "level": 5,
                "currentHP": 21,
                "maxHP": 21,
                "attack": 10,
                "defense": 10,
                "speed": 9,
                "special": 11,
                "moves": ["TACKLE"]
              },
              "focusedMoveIndex": 0,
              "phase": "trainerAboutToUseDecision",
              "battleMessage": "Will RED change #MON?"
            }
            """.utf8
        )

        XCTAssertEqual(
            try JSONDecoder().decode(BattleTelemetry.self, from: phasePayload).phase,
            .trainerAboutToUseDecision
        )
    }

    func testRuntimeTelemetrySnapshotRoundTripsSplitModels() throws {
        let snapshot = RuntimeTelemetrySnapshot(
            appVersion: "0.3.0",
            contentVersion: "test",
            scene: .field,
            substate: "field",
            titleMenu: nil,
            field: .init(
                mapID: "ROUTE_1",
                mapName: "Route 1",
                playerPosition: .init(x: 5, y: 6),
                facing: .up,
                activeMapScriptTriggerID: nil,
                activeScriptID: nil,
                activeScriptStep: nil,
                renderMode: .placeholder,
                transition: .init(kind: .warp, phase: .fadingIn)
            ),
            dialogue: nil,
            fieldPrompt: .init(interactionID: "oak_prompt", kind: .yesNo, options: ["YES", "NO"], focusedIndex: 0),
            fieldHealing: .init(interactionID: "healing", phase: .machineActive, activeBallCount: 3, totalBallCount: 6, pulseStep: 2),
            starterChoice: nil,
            party: .init(pokemon: []),
            inventory: .init(items: []),
            battle: nil,
            shop: .init(
                martID: "PEWTER_MART",
                title: "Poke Mart",
                phase: .result,
                promptText: "Anything else?",
                focusedMainMenuIndex: 0,
                focusedItemIndex: 0,
                focusedConfirmationIndex: 1,
                selectedQuantity: 1,
                selectedTransactionKind: .buy,
                menuOptions: ["BUY", "SELL", "QUIT"],
                buyItems: [],
                sellItems: []
            ),
            eventFlags: .init(activeFlags: ["EVENT_OAK_LAB"]),
            audio: .init(trackID: "MUSIC_ROUTES1", entryID: "default", reason: "mapDefault", playbackRevision: 1),
            soundEffects: [.init(soundEffectID: "SFX_HEAL_HP", reason: "fieldHealing", playbackRevision: 2, status: .started)],
            save: .init(
                metadata: nil,
                canSave: true,
                canLoad: true,
                lastResult: .init(operation: .save, succeeded: true, message: "Saved", timestamp: "2026-03-17T12:00:00Z"),
                errorMessage: nil
            ),
            recentInputEvents: [.init(button: .confirm, timestamp: "2026-03-17T12:00:01Z")],
            assetLoadingFailures: [],
            window: .init(scale: 4, renderWidth: 160, renderHeight: 144)
        )

        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RuntimeTelemetrySnapshot.self, from: encoded)

        XCTAssertEqual(decoded, snapshot)
    }

    func testRuntimeSessionEventRoundTripsSplitModels() throws {
        let event = RuntimeSessionEvent(
            timestamp: "2026-03-17T12:00:00Z",
            kind: .battleStarted,
            message: "Started wild battle.",
            scene: .battle,
            mapID: "ROUTE_1",
            battleID: "wild_route_1_pidgey_3",
            battleKind: .wild,
            details: ["enemySpecies": "PIDGEY"]
        )

        let encoded = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(RuntimeSessionEvent.self, from: encoded)

        XCTAssertEqual(decoded, event)
    }

    func testTelemetryEnumRawValuesRemainStable() {
        XCTAssertEqual(FieldRenderMode.realAssets.rawValue, "realAssets")
        XCTAssertEqual(FieldTransitionKind.door.rawValue, "door")
        XCTAssertEqual(FieldTransitionPhase.fadingOut.rawValue, "fadingOut")
        XCTAssertEqual(FieldHealingPhase.healedJingle.rawValue, "healedJingle")
        XCTAssertEqual(BattlePhaseTelemetry.learnMoveSelection.rawValue, "learnMoveSelection")
        XCTAssertEqual(ShopPhaseTelemetry.mainMenu.rawValue, "mainMenu")
        XCTAssertEqual(ShopTransactionKindTelemetry.sell.rawValue, "sell")
    }
}
