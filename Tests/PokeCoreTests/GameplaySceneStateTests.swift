import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
extension PokeCoreTests {
    func testCurrentFieldSceneStateMatchesSnapshotSlices() {
        let runtime = makeGameplaySceneStateRuntime()
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
        ]
        runtime.gameplayState?.inventory = [
            .init(itemID: "POTION", quantity: 2),
            .init(itemID: "POKE_BALL", quantity: 4),
        ]
        runtime.shopState = RuntimeShopState(
            martID: "TEST_MART",
            phase: .buyList,
            focusedMainMenuIndex: 0,
            focusedItemIndex: 0,
            focusedConfirmationIndex: 0,
            selectedQuantity: 1,
            transaction: nil,
            message: "Welcome!",
            nextPhaseAfterResult: nil
        )
        runtime.fieldTransitionState = .init(kind: .door, phase: .fadingOut)

        let sceneState = runtime.currentFieldSceneState()
        let snapshot = runtime.currentSnapshot()

        XCTAssertEqual(sceneState.party, snapshot.party)
        XCTAssertEqual(sceneState.inventory, snapshot.inventory)
        XCTAssertEqual(sceneState.shop, snapshot.shop)
        XCTAssertEqual(sceneState.transition, snapshot.field?.transition)
    }

    func testCurrentBattleSceneStateMatchesSnapshotSlices() {
        let runtime = makeGameplaySceneStateRuntime()
        runtime.gameplayState = runtime.makeInitialGameplayState()
        runtime.scene = .field
        runtime.substate = "field"
        runtime.gameplayState?.chosenStarterSpeciesID = "SQUIRTLE"
        runtime.gameplayState?.playerParty = [
            runtime.makePokemon(speciesID: "SQUIRTLE", level: 5, nickname: "Lead"),
            runtime.makePokemon(speciesID: "PIDGEY", level: 3, nickname: "Wing"),
        ]
        runtime.gameplayState?.inventory = [.init(itemID: "POKE_BALL", quantity: 2)]

        runtime.startWildBattle(speciesID: "PIDGEY", level: 3)

        let sceneState = runtime.currentBattleSceneState()
        let snapshot = runtime.currentSnapshot()

        XCTAssertEqual(sceneState.party, snapshot.party)
        XCTAssertEqual(sceneState.battle, snapshot.battle)
    }
}

@MainActor
private func makeGameplaySceneStateRuntime() -> GameRuntime {
    GameRuntime(
        content: fixtureContent(
            gameplayManifest: fixtureGameplayManifest(
                species: [
                    .init(
                        id: "SQUIRTLE",
                        displayName: "Squirtle",
                        battleSprite: .init(
                            frontImagePath: "Assets/battle/pokemon/front/squirtle.png",
                            backImagePath: "Assets/battle/pokemon/back/squirtle.png"
                        ),
                        catchRate: 45,
                        baseExp: 63,
                        baseHP: 44,
                        baseAttack: 48,
                        baseDefense: 65,
                        baseSpeed: 43,
                        baseSpecial: 50,
                        startingMoves: ["TACKLE"]
                    ),
                    .init(
                        id: "PIDGEY",
                        displayName: "Pidgey",
                        battleSprite: .init(
                            frontImagePath: "Assets/battle/pokemon/front/pidgey.png",
                            backImagePath: "Assets/battle/pokemon/back/pidgey.png"
                        ),
                        catchRate: 255,
                        baseExp: 55,
                        baseHP: 40,
                        baseAttack: 45,
                        baseDefense: 40,
                        baseSpeed: 56,
                        baseSpecial: 35,
                        startingMoves: ["TACKLE"]
                    ),
                ],
                items: [
                    .init(id: "POTION", displayName: "POTION", price: 300),
                    .init(id: "POKE_BALL", displayName: "POKE BALL", price: 200, battleUse: .ball),
                ],
                moves: [
                    .init(
                        id: "TACKLE",
                        displayName: "TACKLE",
                        power: 35,
                        accuracy: 100,
                        maxPP: 35,
                        effect: "NO_ADDITIONAL_EFFECT",
                        type: "NORMAL"
                    ),
                ],
                marts: [
                    .init(
                        id: "TEST_MART",
                        mapID: "REDS_HOUSE_2F",
                        clerkObjectID: "clerk",
                        stockItemIDs: ["POTION", "POKE_BALL"]
                    ),
                ]
            )
        ),
        telemetryPublisher: nil
    )
}
