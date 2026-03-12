import PokeDataModel

public struct GameplayFieldSceneState: Equatable, Sendable {
    public let party: PartyTelemetry?
    public let inventory: InventoryTelemetry?
    public let shop: ShopTelemetry?
    public let fieldPrompt: FieldPromptTelemetry?
    public let fieldHealing: FieldHealingTelemetry?
    public let fieldAlert: FieldAlertTelemetry?
    public let transition: FieldTransitionTelemetry?

    public init(
        party: PartyTelemetry?,
        inventory: InventoryTelemetry?,
        shop: ShopTelemetry?,
        fieldPrompt: FieldPromptTelemetry?,
        fieldHealing: FieldHealingTelemetry?,
        fieldAlert: FieldAlertTelemetry?,
        transition: FieldTransitionTelemetry?
    ) {
        self.party = party
        self.inventory = inventory
        self.shop = shop
        self.fieldPrompt = fieldPrompt
        self.fieldHealing = fieldHealing
        self.fieldAlert = fieldAlert
        self.transition = transition
    }
}

public struct GameplayBattleSceneState: Equatable, Sendable {
    public let party: PartyTelemetry?
    public let battle: BattleTelemetry?

    public init(
        party: PartyTelemetry?,
        battle: BattleTelemetry?
    ) {
        self.party = party
        self.battle = battle
    }
}

extension GameRuntime {
    public func currentFieldSceneState() -> GameplayFieldSceneState {
        GameplayFieldSceneState(
            party: makePartyTelemetry(),
            inventory: makeInventoryTelemetry(),
            shop: makeShopTelemetry(),
            fieldPrompt: makeFieldPromptTelemetry(),
            fieldHealing: makeFieldHealingTelemetry(),
            fieldAlert: makeFieldAlertTelemetry(),
            transition: makeFieldTransitionTelemetry()
        )
    }

    public func currentBattleSceneState() -> GameplayBattleSceneState {
        GameplayBattleSceneState(
            party: makePartyTelemetry(),
            battle: makeBattleTelemetry()
        )
    }

    func makeFieldTransitionTelemetry() -> FieldTransitionTelemetry? {
        fieldTransitionState.map {
            .init(kind: $0.kind.rawValue, phase: $0.phase.rawValue)
        }
    }

    func makeFieldAlertTelemetry() -> FieldAlertTelemetry? {
        fieldAlertState.map {
            .init(objectID: $0.objectID, kind: $0.kind)
        }
    }
}
