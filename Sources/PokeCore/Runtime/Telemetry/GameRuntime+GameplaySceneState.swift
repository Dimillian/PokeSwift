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

public struct GameplayEvolutionSceneState: Equatable, Sendable {
    public let party: PartyTelemetry?
    public let phase: String
    public let animationStep: Int
    public let showsEvolvedSprite: Bool
    public let textLines: [String]
    public let originalSpeciesID: String
    public let evolvedSpeciesID: String
    public let originalDisplayName: String
    public let evolvedDisplayName: String

    public init(
        party: PartyTelemetry?,
        phase: String,
        animationStep: Int,
        showsEvolvedSprite: Bool,
        textLines: [String],
        originalSpeciesID: String,
        evolvedSpeciesID: String,
        originalDisplayName: String,
        evolvedDisplayName: String
    ) {
        self.party = party
        self.phase = phase
        self.animationStep = animationStep
        self.showsEvolvedSprite = showsEvolvedSprite
        self.textLines = textLines
        self.originalSpeciesID = originalSpeciesID
        self.evolvedSpeciesID = evolvedSpeciesID
        self.originalDisplayName = originalDisplayName
        self.evolvedDisplayName = evolvedDisplayName
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

    public func currentEvolutionSceneState() -> GameplayEvolutionSceneState? {
        guard let evolutionState else { return nil }
        return GameplayEvolutionSceneState(
            party: makePartyTelemetry(),
            phase: evolutionState.phase.rawValue,
            animationStep: evolutionState.animationStep,
            showsEvolvedSprite: evolutionState.showsEvolvedSprite,
            textLines: currentEvolutionDialogueLines(),
            originalSpeciesID: evolutionState.originalPokemon.speciesID,
            evolvedSpeciesID: evolutionState.evolvedPokemon.speciesID,
            originalDisplayName: content.species(id: evolutionState.originalPokemon.speciesID)?.displayName
                ?? evolutionState.originalPokemon.speciesID.capitalized,
            evolvedDisplayName: content.species(id: evolutionState.evolvedPokemon.speciesID)?.displayName
                ?? evolutionState.evolvedPokemon.speciesID.capitalized
        )
    }

    func makeFieldTransitionTelemetry() -> FieldTransitionTelemetry? {
        fieldTransitionState.map {
            .init(
                kind: FieldTransitionKind(rawValue: $0.kind.rawValue) ?? .warp,
                phase: FieldTransitionPhase(rawValue: $0.phase.rawValue) ?? .fadingOut
            )
        }
    }

    func makeFieldAlertTelemetry() -> FieldAlertTelemetry? {
        fieldAlertState.map {
            .init(objectID: $0.objectID, kind: $0.kind)
        }
    }
}
