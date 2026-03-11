import SwiftUI

struct GameplaySidebar: View {
    let mode: GameplaySidebarMode
    let onSidebarAction: ((String) -> Void)?
    @Binding var fieldDisplayStyle: FieldDisplayStyle

    @State private var expansionState: GameplaySidebarExpansionState

    init(
        mode: GameplaySidebarMode,
        onSidebarAction: ((String) -> Void)? = nil,
        fieldDisplayStyle: Binding<FieldDisplayStyle>
    ) {
        self.mode = mode
        self.onSidebarAction = onSidebarAction
        _fieldDisplayStyle = fieldDisplayStyle
        _expansionState = State(
            initialValue: GameplaySidebarExpansionState(
                expandedSection: mode.defaultExpandedSection
            )
        )
    }

    var body: some View {
        GlassEffectContainer(spacing: GameplayFieldMetrics.glassMergeSpacing) {
            sidebarContent
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(.snappy(duration: 0.24, extraBounce: 0), value: expansionState.expandedSection)
        .onChange(of: mode) { _, updatedMode in
            syncExpansionState(for: updatedMode)
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        switch mode {
        case let .fieldLike(props):
            FieldModeSidebarContent(
                props: props,
                expansionState: expansionState,
                onSidebarAction: onSidebarAction,
                fieldDisplayStyle: $fieldDisplayStyle
            ) { section in
                expansionState.activate(section)
            }
        case let .battle(props):
            BattleModeSidebarContent(
                props: props,
                expansionState: expansionState
            ) { section in
                expansionState.activate(mode.resolvedExpandedSection(afterRequesting: section))
            }
        }
    }

    private func syncExpansionState(for mode: GameplaySidebarMode) {
        let resolvedSection = mode.resolvedExpandedSection(afterRequesting: expansionState.expandedSection)
        guard resolvedSection != expansionState.expandedSection else { return }
        expansionState.activate(resolvedSection)
    }
}

private struct FieldModeSidebarContent: View {
    let props: GameplayFieldSidebarProps
    let expansionState: GameplaySidebarExpansionState
    let onSidebarAction: ((String) -> Void)?
    @Binding var fieldDisplayStyle: FieldDisplayStyle
    let onActivateSection: (GameplaySidebarExpandedSection) -> Void

    var body: some View {
        VStack(spacing: GameplayFieldMetrics.sidebarSectionSpacing) {
            AccordionSidebarCard(
                title: "Trainer",
                summary: props.profile.locationName,
                isExpanded: expansionState.expandedSection == .trainer
            ) {
                onActivateSection(.trainer)
            } content: {
                TrainerProfileContent(props: props.profile)
            }

            AccordionSidebarCard(
                title: "Party",
                summary: "\(props.party.pokemon.count)/\(props.party.totalSlots)",
                isExpanded: expansionState.expandedSection == .party
            ) {
                onActivateSection(.party)
            } content: {
                PartySidebarContent(props: props.party)
            }

            AccordionSidebarCard(
                title: props.inventory.title,
                summary: props.inventory.items.isEmpty ? "Empty" : "\(props.inventory.items.count)",
                isExpanded: expansionState.expandedSection == .bag
            ) {
                onActivateSection(.bag)
            } content: {
                InventorySidebarContent(props: props.inventory)
            }

            AccordionSidebarCard(
                title: props.save.title,
                summary: props.save.summary,
                isExpanded: expansionState.expandedSection == .save
            ) {
                onActivateSection(.save)
            } content: {
                SaveSidebarContent(
                    props: props.save,
                    onAction: onSidebarAction
                )
            }

            AccordionSidebarCard(
                title: props.options.title,
                summary: fieldDisplayStyle.sidebarSummaryLabel,
                isExpanded: expansionState.expandedSection == .options
            ) {
                onActivateSection(.options)
            } content: {
                OptionsSidebarContent(
                    props: props.options,
                    fieldDisplayStyle: $fieldDisplayStyle
                )
            }

            Spacer(minLength: 0)
        }
    }
}

private struct BattleModeSidebarContent: View {
    let props: BattleSidebarProps
    let expansionState: GameplaySidebarExpansionState
    let onActivateSection: (GameplaySidebarExpandedSection) -> Void

    var body: some View {
        VStack(spacing: GameplayFieldMetrics.sidebarSectionSpacing) {
            AccordionSidebarCard(
                title: "Combat",
                summary: battleSummaryLabel,
                isExpanded: expansionState.expandedSection == .battleCombat
            ) {
                onActivateSection(.battleCombat)
            } content: {
                VStack(alignment: .leading, spacing: 16) {
                    BattleSummaryContent(props: props)
                    BattleActionContent(props: props)
                }
            }

            AccordionSidebarCard(
                title: "Party",
                summary: "\(props.party.pokemon.count)/\(props.party.totalSlots)",
                isExpanded: expansionState.expandedSection == .party
            ) {
                onActivateSection(.party)
            } content: {
                PartySidebarContent(props: props.party)
            }

            Spacer(minLength: 0)
        }
    }

    private var battleSummaryLabel: String {
        switch props.phase {
        case "moveSelection":
            return "Moves"
        case "resolvingTurn":
            return "Resolving"
        case "turnText":
            return "Text"
        case "battleComplete":
            return "Result"
        default:
            return "Battle"
        }
    }
}
