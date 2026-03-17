import SwiftUI
import PokeDataModel
import PokeRender
import PokeUI

private enum GameplayBattleStageLayout {
    static let dialogueMaxWidth: CGFloat = 760
    static let bagOverlayWidth: CGFloat = 360
}

struct BattleStageView: View {
    let props: BattleViewportProps
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        BattleViewportStage(screenDisplayStyle: fieldDisplayStyle) {
            BattlePanel(
                trainerName: props.trainerName,
                kind: props.kind,
                playerPokemon: props.playerPokemon,
                enemyPokemon: props.enemyPokemon,
                enemyParty: props.enemyParty,
                enemyPartyCount: props.enemyPartyCount,
                isEnemySpeciesOwned: props.isEnemySpeciesOwned,
                trainerSpriteURL: props.trainerSpriteURL,
                playerTrainerFrontSpriteURL: props.playerTrainerFrontSpriteURL,
                playerTrainerBackSpriteURL: props.playerTrainerBackSpriteURL,
                sendOutPoofSpriteURL: props.sendOutPoofSpriteURL,
                battleAnimationManifest: props.battleAnimationManifest,
                battleAnimationTilesetURLs: props.battleAnimationTilesetURLs,
                playerSpriteURL: props.playerSpriteURL,
                enemySpriteURL: props.enemySpriteURL,
                displayStyle: fieldDisplayStyle,
                presentation: props.presentation
            )
        } footer: {
            footerContent
        } overlayContent: {
            overlayContent
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        if let confirmation = props.nicknameConfirmation {
            NicknameConfirmationFooter(confirmation: confirmation)
        } else {
            DialogueBoxView(
                title: "Battle",
                lines: GameplayBattlePrompts.textLines(props.textLines, phase: props.phase)
            )
            .frame(maxWidth: GameplayBattleStageLayout.dialogueMaxWidth)
            .opacity(props.presentation.uiVisibility == .visible ? 1 : 0)
            .animation(.easeOut(duration: 0.18), value: props.presentation.revision)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if props.showsBagOverlay &&
            props.bag.sections.isEmpty == false &&
            props.presentation.uiVisibility == .visible {
            BattleBagOverlayPanel(
                bag: props.bag,
                onItemSelected: props.onBagItemSelected
            )
            .frame(width: GameplayBattleStageLayout.bagOverlayWidth)
        }
    }
}

private struct BattleBagOverlayPanel: View {
    let bag: InventorySidebarProps
    let onItemSelected: ((String) -> Void)?

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("BAG")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)
                InventorySidebarContent(props: bag, onItemSelected: onItemSelected)
            }
        }
    }
}
