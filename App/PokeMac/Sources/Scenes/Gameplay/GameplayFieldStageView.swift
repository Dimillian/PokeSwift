import SwiftUI
import PokeRender
import PokeUI

private enum GameplayFieldStageLayout {
    static let dialogueMaxWidth: CGFloat = 760
    static let healingOverlayWidth: CGFloat = 320
    static let healingOverlayTopInset: CGFloat = 108
    static let healingOverlayXOffset: CGFloat = -252
    static let learnMoveOverlayWidth: CGFloat = 420
    static let promptOverlayWidth: CGFloat = 100
    static let promptOverlayTopInset: CGFloat = 306
    static let promptOverlayXOffset: CGFloat = -100
    static let shopOverlayWidth: CGFloat = 420
    static let starterChoiceOverlayWidth: CGFloat = 420
}

struct FieldStageView: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let props: GameplayFieldViewportProps
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        ZStack {
            FieldMapStage(screenDisplayStyle: fieldDisplayStyle) {
                mapContent
            } footer: {
                footerContent
            } overlayContent: {
                overlayContent
            }

            if case let .naming(namingProps) = props.screenModalContent {
                Color.black
                    .ignoresSafeArea()
                NamingOverlayPanel(props: namingProps)
                    .frame(width: 420)
            }
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        if let map = props.map,
           let playerPosition = props.playerPosition {
            FieldMapView(
                map: map,
                fieldPalette: props.fieldPalette,
                playerPosition: playerPosition,
                playerFacing: props.playerFacing,
                playerStepDuration: props.playerStepDuration,
                objects: props.objects,
                playerSpriteID: props.playerSpriteID,
                renderAssets: props.renderAssets,
                transition: props.fieldTransition,
                alert: props.fieldAlert,
                displayStyle: fieldDisplayStyle
            )
        } else {
            VStack(spacing: 14) {
                Text("Field data unavailable")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("The runtime has not produced a map payload for this scene yet.")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(palette.secondaryText.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        switch props.footerContent {
        case let .nicknameConfirmation(confirmation):
            NicknameConfirmationFooter(confirmation: confirmation)
        case let .dialogue(dialogueLines, instantReveal, onFullyRevealed):
            DialogueBoxView(
                lines: dialogueLines,
                instantReveal: instantReveal,
                onFullyRevealed: onFullyRevealed
            )
            .frame(maxWidth: GameplayFieldStageLayout.dialogueMaxWidth)
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch props.overlayContent {
        case let .healing(fieldHealing):
            PokemonCenterHealingOverlay(healing: fieldHealing)
                .frame(width: GameplayFieldStageLayout.healingOverlayWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, GameplayFieldStageLayout.healingOverlayTopInset)
                .offset(x: GameplayFieldStageLayout.healingOverlayXOffset)
        case let .learnMove(fieldLearnMove):
            FieldLearnMoveOverlay(props: fieldLearnMove)
                .frame(width: GameplayFieldStageLayout.learnMoveOverlayWidth)
        case let .prompt(fieldPrompt):
            FieldPromptOverlay(prompt: fieldPrompt)
                .frame(width: GameplayFieldStageLayout.promptOverlayWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, GameplayFieldStageLayout.promptOverlayTopInset)
                .offset(x: GameplayFieldStageLayout.promptOverlayXOffset)
        case let .shop(shop):
            ShopOverlayPanel(shop: shop)
                .frame(width: GameplayFieldStageLayout.shopOverlayWidth)
        case let .starterChoice(options, focusedIndex):
            StarterChoicePanel(
                options: options,
                focusedIndex: focusedIndex
            )
            .frame(width: GameplayFieldStageLayout.starterChoiceOverlayWidth)
        case nil:
            EmptyView()
        }
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}
