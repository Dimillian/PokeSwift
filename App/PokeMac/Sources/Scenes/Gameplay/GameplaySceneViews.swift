import SwiftUI
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

struct GameplayScene: View {
    @Environment(AppPreferences.self) private var preferences
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
            BattleStageView(
                props: battleProps,
                fieldDisplayStyle: fieldDisplayStyle
            )
        }
    }

    func handleSidebarAction(_ actionID: String) {
        if actionID == "load" {
            isLoadConfirmationPresented = true
            return
        }

        switch actionID {
        case "appearanceMode":
            preferences.cycleAppearanceMode()
            return
        case "gameplayHDR":
            preferences.toggleGameplayHDREnabled()
            return
        case "music":
            preferences.toggleMusicEnabled()
            return
        default:
            break
        }

        props.onSidebarAction?(actionID)
    }
}

// MARK: - Stage Views

private struct FieldStageView: View {
    let props: GameplayFieldViewportProps
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        FieldMapStage(screenDisplayStyle: fieldDisplayStyle) {
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
            .foregroundStyle(PokeThemePalette.secondaryText)
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
        if let fieldHealing = props.fieldHealing {
            PokemonCenterHealingOverlay(healing: fieldHealing)
                .frame(width: 320)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 108)
                .offset(x: -252)
        } else if let fieldPrompt = props.fieldPrompt {
            FieldPromptOverlay(prompt: fieldPrompt)
                .frame(width: 100)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 306)
                .offset(x: -100)
        } else if let shop = props.shop {
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
    let fieldDisplayStyle: FieldDisplayStyle

    var body: some View {
        BattleViewportStage(screenDisplayStyle: fieldDisplayStyle) {
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

private struct FieldPromptOverlay: View {
    let prompt: FieldPromptTelemetry

    var body: some View {
        GameplayHoverCardSurface(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(prompt.options.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 10) {
                        Text(index == prompt.focusedIndex ? "▶" : " ")
                        Text(option.uppercased())
                        Spacer(minLength: 8)
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(index == prompt.focusedIndex ? 1 : 0.78))
                }
            }
        }
    }
}

private struct PokemonCenterHealingOverlay: View {
    let healing: FieldHealingTelemetry

    var body: some View {
        GameplayHoverCardSurface(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("HEALING MACHINE")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)

                HStack(alignment: .center, spacing: 16) {
                    PokemonCenterBallWell(healing: healing)

                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(monitorFill)
                            .overlay {
                                VStack(spacing: 5) {
                                    Capsule()
                                        .fill(GameplayFieldStyleTokens.ink.opacity(0.82))
                                        .frame(width: 58, height: 6)
                                    HStack(spacing: 5) {
                                        ForEach(0..<4, id: \.self) { index in
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .fill(signalFill(for: index))
                                                .frame(width: 10, height: 8)
                                        }
                                    }
                                }
                            }
                            .frame(width: 104, height: 68)

                        Text(statusText)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.72))

                        Text(progressText)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.88))
                    }
                }
            }
        }
    }

    private var monitorFill: Color {
        switch healing.phase {
        case "healedJingle":
            return GameplayFieldStyleTokens.ink.opacity(0.78)
        case "machineActive":
            return healing.pulseStep.isMultiple(of: 2) ? PokeThemePalette.fieldLeadSlotFill.opacity(0.92) : PokeThemePalette.fieldCardFill
        default:
            return PokeThemePalette.fieldCardFill
        }
    }

    private func signalFill(for index: Int) -> Color {
        if healing.phase == "healedJingle" {
            return (index + healing.pulseStep).isMultiple(of: 2)
                ? GameplayFieldStyleTokens.ink.opacity(0.88)
                : PokeThemePalette.fieldLeadSlotFill.opacity(0.8)
        }

        let litCount = min(4, max(1, healing.activeBallCount))
        return index < litCount
            ? PokeThemePalette.fieldLeadSlotFill.opacity(index == litCount - 1 ? 0.94 : 0.72)
            : GameplayFieldStyleTokens.ink.opacity(0.2)
    }

    private var statusText: String {
        switch healing.phase {
        case "priming":
            return "PREPARING"
        case "machineActive":
            return "ADDING PARTY BALLS"
        case "healedJingle":
            return "POKeMON HEALED"
        default:
            return "HEALING"
        }
    }

    private var progressText: String {
        switch healing.phase {
        case "machineActive", "healedJingle":
            return "\(healing.activeBallCount)/\(healing.totalBallCount) LOADED"
        default:
            return "STANDBY"
        }
    }
}

private struct PokemonCenterBallWell: View {
    let healing: FieldHealingTelemetry

    var body: some View {
        ZStack {
            Circle()
                .fill(GameplayFieldStyleTokens.ink.opacity(0.92))

            Circle()
                .stroke(GameplayFieldStyleTokens.ink.opacity(0.28), lineWidth: 2)
                .padding(5)

            Circle()
                .stroke(PokeThemePalette.fieldLeadSlotFill.opacity(healing.phase == "healedJingle" ? 0.7 : 0.36), lineWidth: 1)
                .padding(12)

            ForEach(0..<max(healing.totalBallCount, 1), id: \.self) { index in
                let point = ballPoint(for: index, total: healing.totalBallCount)
                let isVisible = index < visibleBallCount

                PokemonCenterBallToken(
                    isVisible: isVisible,
                    isFlashing: healing.phase == "healedJingle" && (index + healing.pulseStep).isMultiple(of: 2),
                    isNewest: healing.phase == "machineActive" && index == max(0, healing.activeBallCount - 1)
                )
                .position(point)
            }
        }
        .frame(width: 112, height: 112)
        .animation(.easeInOut(duration: 0.16), value: healing.activeBallCount)
        .animation(.easeInOut(duration: 0.14), value: healing.pulseStep)
    }

    private var visibleBallCount: Int {
        switch healing.phase {
        case "priming":
            return 0
        default:
            return min(healing.activeBallCount, healing.totalBallCount)
        }
    }

    private func ballPoint(for index: Int, total: Int) -> CGPoint {
        let clampedTotal = max(1, min(total, 6))
        let layouts: [[CGPoint]] = [
            [CGPoint(x: 56, y: 56)],
            [CGPoint(x: 40, y: 56), CGPoint(x: 72, y: 56)],
            [CGPoint(x: 56, y: 36), CGPoint(x: 39, y: 70), CGPoint(x: 73, y: 70)],
            [CGPoint(x: 40, y: 40), CGPoint(x: 72, y: 40), CGPoint(x: 40, y: 72), CGPoint(x: 72, y: 72)],
            [CGPoint(x: 56, y: 30), CGPoint(x: 38, y: 49), CGPoint(x: 74, y: 49), CGPoint(x: 44, y: 77), CGPoint(x: 68, y: 77)],
            [CGPoint(x: 38, y: 34), CGPoint(x: 56, y: 34), CGPoint(x: 74, y: 34), CGPoint(x: 38, y: 76), CGPoint(x: 56, y: 76), CGPoint(x: 74, y: 76)],
        ]

        let positions = layouts[clampedTotal - 1]
        return positions[min(index, positions.count - 1)]
    }
}

private struct PokemonCenterBallToken: View {
    let isVisible: Bool
    let isFlashing: Bool
    let isNewest: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(baseOpacity))

            Circle()
                .fill(PokeThemePalette.fieldLeadSlotFill.opacity(topOpacity))
                .mask(
                    Rectangle()
                        .frame(width: 20, height: 10)
                        .offset(y: -5)
                )

            Rectangle()
                .fill(GameplayFieldStyleTokens.ink.opacity(baseOpacity))
                .frame(width: 20, height: 2)

            Circle()
                .fill(Color.white.opacity(baseOpacity))
                .frame(width: 6, height: 6)
                .overlay {
                    Circle()
                        .stroke(GameplayFieldStyleTokens.ink.opacity(baseOpacity), lineWidth: 1)
                }

            Circle()
                .stroke(GameplayFieldStyleTokens.ink.opacity(baseOpacity), lineWidth: 1)
        }
        .frame(width: 20, height: 20)
        .scaleEffect(isNewest ? 1.12 : 1)
        .opacity(isVisible ? 1 : 0.08)
        .shadow(
            color: PokeThemePalette.fieldLeadSlotFill.opacity(isVisible ? (isFlashing ? 0.34 : 0.18) : 0),
            radius: isFlashing ? 8 : 4
        )
    }

    private var baseOpacity: Double {
        isVisible ? 0.98 : 0.18
    }

    private var topOpacity: Double {
        if isFlashing {
            return 0.98
        }
        if isNewest {
            return 0.94
        }
        return isVisible ? 0.82 : 0.12
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
    private let palette = PokeThemePalette.lightPalette

    var body: some View {
        GameBoyScreen {
            GameBoyPanel {
                VStack(spacing: 16) {
                    Text(props.title ?? "Placeholder")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText.color)
                    Text("This route is intentionally reserved for Milestone 3 and beyond.")
                        .foregroundStyle(palette.secondaryText.color)
                    Text("Press Escape or X to return to the title menu.")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(palette.primaryText.color)
                }
                .padding(22)
            }
            .frame(width: 580)
        }
    }
}
