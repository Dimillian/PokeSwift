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

enum GameplayFieldFooterContent {
    case dialogue(
        lines: [String],
        instantReveal: Bool,
        onFullyRevealed: (() -> Void)?
    )
    case nicknameConfirmation(NicknameConfirmationViewProps)
}

enum GameplayFieldOverlayContent {
    case healing(FieldHealingTelemetry)
    case learnMove(FieldLearnMoveOverlayProps)
    case prompt(FieldPromptTelemetry)
    case shop(ShopTelemetry)
    case starterChoice(options: [SpeciesManifest], focusedIndex: Int)
}

enum GameplayFieldScreenModalContent {
    case naming(NamingOverlayProps)
}

struct GameplayFieldViewportProps {
    let map: MapManifest?
    let fieldPalette: FieldPaletteManifest?
    let playerPosition: TilePoint?
    let playerFacing: FacingDirection
    let playerStepDuration: TimeInterval
    let objects: [FieldRenderableObjectState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let fieldTransition: FieldTransitionTelemetry?
    let fieldAlert: FieldAlertTelemetry?
    let footerContent: GameplayFieldFooterContent?
    let overlayContent: GameplayFieldOverlayContent?
    let screenModalContent: GameplayFieldScreenModalContent?
}

struct BattleViewportProps {
    let trainerName: String
    let kind: BattleKind
    let phase: BattlePhaseTelemetry
    let showsBagOverlay: Bool
    let textLines: [String]
    let playerPokemon: PartyPokemonTelemetry
    let enemyPokemon: PartyPokemonTelemetry
    let enemyParty: [PartyPokemonTelemetry]
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
    let playerBattlePalette: FieldPaletteManifest?
    let enemyBattlePalette: FieldPaletteManifest?
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
