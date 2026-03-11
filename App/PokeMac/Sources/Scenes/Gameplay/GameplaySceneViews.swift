import SwiftUI
import PokeCore
import PokeDataModel
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
    let objects: [FieldObjectRenderState]
    let playerSpriteID: String
    let renderAssets: FieldRenderAssets?
    let fieldTransition: FieldTransitionTelemetry?
    let dialogueLines: [String]?
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

struct GameplayScene: View {
    let props: GameplaySceneProps
    @State private var fieldDisplayStyle: FieldDisplayStyle
    @State private var isLoadConfirmationPresented = false

    init(props: GameplaySceneProps) {
        self.props = props
        _fieldDisplayStyle = State(initialValue: props.initialFieldDisplayStyle)
    }

    var body: some View {
        GameBoyScreen(style: .fieldShell) {
            GameplayShell(
                sidebarMode: props.sidebarMode,
                onSidebarAction: handleSidebarAction(_:),
                onPartyRowSelected: props.onPartyRowSelected,
                fieldDisplayStyle: $fieldDisplayStyle
            ) {
                stage
            }
        }
        .confirmationDialog(
            "Load saved game?",
            isPresented: $isLoadConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Load Save", role: .destructive) {
                props.onSidebarAction?("load")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces the current in-memory progress with the last saved game.")
        }
    }
}

// MARK: - GameplayScene Stage Composition

private extension GameplayScene {
    @ViewBuilder
    var stage: some View {
        ZStack {
            fieldStageLayer
            battleStageLayer
        }
    }

    @ViewBuilder
    var fieldStageLayer: some View {
        if case let .field(fieldProps) = props.viewport {
            FieldStageView(
                props: fieldProps,
                fieldDisplayStyle: fieldDisplayStyle
            )
        }
    }

    @ViewBuilder
    var battleStageLayer: some View {
        if case let .battle(battleProps) = props.viewport {
            BattleStageView(props: battleProps)
        }
    }

    func handleSidebarAction(_ actionID: String) {
        if actionID == "load" {
            isLoadConfirmationPresented = true
            return
        }
        props.onSidebarAction?(actionID)
    }
}

// MARK: - Stage Views

private struct FieldStageView: View {
    let props: GameplayFieldViewportProps
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        FieldMapStage {
            mapContent
        } footer: {
            footerContent
        } overlayContent: {
            overlayContent
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
            .foregroundStyle(.black.opacity(0.78))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        if let dialogueLines = props.dialogueLines {
            DialogueBoxView(lines: dialogueLines)
                .frame(maxWidth: 760)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let shop = props.shop {
            ShopOverlayPanel(shop: shop)
                .frame(width: 420)
        } else if props.starterChoiceOptions.isEmpty == false {
            StarterChoicePanel(
                options: props.starterChoiceOptions,
                focusedIndex: props.starterChoiceFocusedIndex
            )
            .frame(width: 420)
        }
    }
}

private struct BattleStageView: View {
    let props: BattleViewportProps

    var body: some View {
        BattleViewportStage {
            BattlePanel(
                trainerName: props.trainerName,
                playerPokemon: props.playerPokemon,
                enemyPokemon: props.enemyPokemon,
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

    private var footerContent: some View {
        DialogueBoxView(
            title: "Battle",
            lines: GameplayBattlePrompts.textLines(props.textLines, phase: props.phase)
        )
        .frame(maxWidth: 760)
        .opacity(props.presentation.uiVisibility == .visible ? 1 : 0)
        .animation(.easeOut(duration: 0.18), value: props.presentation.revision)
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
            .frame(width: 360)
        }
    }
}

// MARK: - Overlay Panels

private struct ShopOverlayPanel: View {
    let shop: ShopTelemetry

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text(shop.title.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)
                Text(shop.promptText.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.72))

                switch shop.phase {
                case "mainMenu":
                    ForEach(Array(shop.menuOptions.enumerated()), id: \.offset) { index, option in
                        menuRow(
                            title: option,
                            detail: nil,
                            isFocused: index == shop.focusedMainMenuIndex,
                            isSelectable: true
                        )
                    }
                case "buyList":
                    itemRows(shop.buyItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: true)
                case "sellList":
                    itemRows(shop.sellItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: true)
                case "quantity":
                    itemRows(activeItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: true)
                    Text("QTY \(shop.selectedQuantity)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.68))
                case "confirmation":
                    itemRows(activeItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: true)
                    Text("QTY \(shop.selectedQuantity)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.68))
                    menuRow(title: "YES", detail: nil, isFocused: shop.focusedConfirmationIndex == 0, isSelectable: true)
                    menuRow(title: "NO", detail: nil, isFocused: shop.focusedConfirmationIndex == 1, isSelectable: true)
                default:
                    EmptyView()
                }
            }
        }
    }

    private var activeItems: [ShopRowTelemetry] {
        switch shop.selectedTransactionKind {
        case "sell":
            return shop.sellItems
        default:
            return shop.buyItems
        }
    }

    @ViewBuilder
    private func itemRows(_ items: [ShopRowTelemetry], focusedIndex: Int, showsOwnedQuantity: Bool) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.itemID) { index, item in
            menuRow(
                title: item.displayName,
                detail: itemDetail(for: item, showsOwnedQuantity: showsOwnedQuantity),
                isFocused: index == focusedIndex,
                isSelectable: item.isSelectable
            )
        }
    }

    private func itemDetail(for item: ShopRowTelemetry, showsOwnedQuantity: Bool) -> String {
        if shop.selectedTransactionKind == "sell" || shop.phase == "sellList" {
            return showsOwnedQuantity ? "x\(item.ownedQuantity) ¥\(item.transactionPrice)" : "¥\(item.transactionPrice)"
        }
        return showsOwnedQuantity ? "x\(item.ownedQuantity) ¥\(item.unitPrice)" : "¥\(item.unitPrice)"
    }

    private func menuRow(title: String, detail: String?, isFocused: Bool, isSelectable: Bool) -> some View {
        HStack(spacing: 10) {
            Text(isFocused ? "▶" : " ")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Spacer(minLength: 8)
            if let detail {
                Text(detail.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        }
        .foregroundStyle(
            GameplayFieldStyleTokens.ink.opacity(
                isSelectable ? (isFocused ? 1 : 0.78) : 0.38
            )
        )
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

struct PlaceholderScene: View {
    let props: PlaceholderSceneProps

    var body: some View {
        GameBoyScreen {
            GameBoyPanel {
                VStack(spacing: 16) {
                    Text(props.title ?? "Placeholder")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text("This route is intentionally reserved for Milestone 3 and beyond.")
                        .foregroundStyle(.black.opacity(0.64))
                    Text("Press Escape or X to return to the title menu.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .padding(22)
            }
            .frame(width: 580)
        }
    }
}
