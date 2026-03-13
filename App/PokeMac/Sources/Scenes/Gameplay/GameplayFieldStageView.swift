import SwiftUI
import PokeRender
import PokeUI

private enum GameplayFieldStageLayout {
    static let dialogueMaxWidth: CGFloat = 760
    static let healingOverlayWidth: CGFloat = 320
    static let healingOverlayTopInset: CGFloat = 108
    static let healingOverlayXOffset: CGFloat = -252
    static let promptOverlayWidth: CGFloat = 100
    static let promptOverlayTopInset: CGFloat = 306
    static let promptOverlayXOffset: CGFloat = -100
    static let shopOverlayWidth: CGFloat = 420
    static let starterChoiceOverlayWidth: CGFloat = 420
}

struct FieldStageView: View {
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

            if let namingProps = props.namingProps {
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
            .foregroundStyle(PokeThemePalette.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        if let confirmation = props.nicknameConfirmation {
            NicknameConfirmationFooter(confirmation: confirmation)
        } else if let dialogueLines = props.dialogueLines {
            DialogueBoxView(lines: dialogueLines)
                .frame(maxWidth: GameplayFieldStageLayout.dialogueMaxWidth)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let fieldHealing = props.fieldHealing {
            PokemonCenterHealingOverlay(healing: fieldHealing)
                .frame(width: GameplayFieldStageLayout.healingOverlayWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, GameplayFieldStageLayout.healingOverlayTopInset)
                .offset(x: GameplayFieldStageLayout.healingOverlayXOffset)
        } else if let fieldPrompt = props.fieldPrompt {
            FieldPromptOverlay(prompt: fieldPrompt)
                .frame(width: GameplayFieldStageLayout.promptOverlayWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, GameplayFieldStageLayout.promptOverlayTopInset)
                .offset(x: GameplayFieldStageLayout.promptOverlayXOffset)
        } else if let shop = props.shop {
            ShopOverlayPanel(shop: shop)
                .frame(width: GameplayFieldStageLayout.shopOverlayWidth)
        } else if props.starterChoiceOptions.isEmpty == false {
            StarterChoicePanel(
                options: props.starterChoiceOptions,
                focusedIndex: props.starterChoiceFocusedIndex
            )
            .frame(width: GameplayFieldStageLayout.starterChoiceOverlayWidth)
        }
    }
}
