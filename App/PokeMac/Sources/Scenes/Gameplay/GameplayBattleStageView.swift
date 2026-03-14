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
                trainerSpriteURL: props.trainerSpriteURL,
                playerTrainerFrontSpriteURL: props.playerTrainerFrontSpriteURL,
                playerTrainerBackSpriteURL: props.playerTrainerBackSpriteURL,
                sendOutPoofSpriteURL: props.sendOutPoofSpriteURL,
                playerSpriteURL: props.playerSpriteURL,
                enemySpriteURL: props.enemySpriteURL,
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
        if props.phase == "bagSelection" &&
            props.bagItems.isEmpty == false &&
            props.presentation.uiVisibility == .visible {
            BattleBagOverlayPanel(
                items: props.bagItems,
                focusedIndex: props.focusedBagItemIndex
            )
            .frame(width: GameplayBattleStageLayout.bagOverlayWidth)
        }
    }
}

private struct BattleBagOverlayPanel: View {
    let items: [InventoryItemTelemetry]
    let focusedIndex: Int

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("BAG")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)
                ForEach(Array(items.enumerated()), id: \.element.itemID) { index, item in
                    HStack(spacing: 10) {
                        Text(index == focusedIndex ? "▶" : " ")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text(item.displayName.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Spacer(minLength: 8)
                        Text("x\(item.quantity)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(index == focusedIndex ? 1 : 0.78))
                }
            }
        }
    }
}
