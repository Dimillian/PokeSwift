import Foundation
import PokeCore
import PokeDataModel
import PokeRender
import PokeUI

struct GameplaySceneProps {
    let viewport: GameplayViewportProps
    let sidebarMode: GameplaySidebarMode
    let onSidebarAction: ((String) -> Void)?
    let onPartyRowSelected: ((Int) -> Void)?
    let initialFieldDisplayStyle: FieldDisplayStyle
}

enum GameplayViewportProps {
    case field(GameplayFieldViewportProps)
    case battle(BattleViewportProps)
}

struct GameplayFieldViewportProps {
    let map: MapManifest?
    let playerPosition: TilePoint?
    let playerFacing: FacingDirection
    let playerStepDuration: TimeInterval
    let objects: [FieldRenderableObjectState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let fieldTransition: FieldTransitionTelemetry?
    let fieldAlert: FieldAlertTelemetry?
    let dialogueLines: [String]?
    let fieldPrompt: FieldPromptTelemetry?
    let fieldHealing: FieldHealingTelemetry?
    let shop: ShopTelemetry?
    let starterChoiceOptions: [SpeciesManifest]
    let starterChoiceFocusedIndex: Int
}

struct BattleViewportProps {
    let trainerName: String
    let kind: BattleKind
    let phase: String
    let textLines: [String]
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?
    let bagItems: [InventoryItemTelemetry]
    let focusedBagItemIndex: Int
    let presentation: BattlePresentationTelemetry
}

struct PlaceholderSceneProps {
    let title: String?
}
