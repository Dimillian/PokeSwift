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
    let onInventoryItemSelected: ((String) -> Void)?
    let initialFieldDisplayStyle: FieldDisplayStyle
}

enum GameplayViewportProps {
    case field(GameplayFieldViewportProps)
    case battle(BattleViewportProps)
    case evolution(EvolutionViewportProps)
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
    let dialogueInstantReveal: Bool
    let onDialogueRevealed: (() -> Void)?
    let fieldPrompt: FieldPromptTelemetry?
    let fieldHealing: FieldHealingTelemetry?
    let shop: ShopTelemetry?
    let starterChoiceOptions: [SpeciesManifest]
    let starterChoiceFocusedIndex: Int
    let namingProps: NamingOverlayProps?
    let nicknameConfirmation: NicknameConfirmationViewProps?
}

struct BattleViewportProps {
    let trainerName: String
    let kind: BattleKind
    let phase: BattlePhaseTelemetry
    let textLines: [String]
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let enemyPartyCount: Int
    let isEnemySpeciesOwned: Bool
    let trainerSpriteURL: URL?
    let playerTrainerFrontSpriteURL: URL?
    let playerTrainerBackSpriteURL: URL?
    let sendOutPoofSpriteURL: URL?
    let battleAnimationManifest: BattleAnimationManifest
    let battleAnimationTilesetURLs: [String: URL]
    let playerSpriteURL: URL?
    let enemySpriteURL: URL?
    let bag: InventorySidebarProps
    let onBagItemSelected: ((String) -> Void)?
    let presentation: BattlePresentationTelemetry
    let nicknameConfirmation: NicknameConfirmationViewProps?
}

struct EvolutionViewportProps {
    let phase: String
    let animationStep: Int
    let showsEvolvedSprite: Bool
    let textLines: [String]
    let originalDisplayName: String
    let evolvedDisplayName: String
    let originalSpriteURL: URL?
    let evolvedSpriteURL: URL?
}

struct NamingOverlayProps {
    let speciesDisplayName: String
    let enteredText: String
    let maxLength: Int
}

struct NicknameConfirmationViewProps {
    let speciesDisplayName: String
    let focusedIndex: Int
}

struct PlaceholderSceneProps {
    let title: String?
}
