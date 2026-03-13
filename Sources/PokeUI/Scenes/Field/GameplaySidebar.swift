import SwiftUI
import PokeRender

struct GameplaySidebar: View {
    let mode: GameplaySidebarMode
    let onSidebarAction: ((String) -> Void)?
    let onPartyRowSelected: ((Int) -> Void)?
    @Binding var fieldDisplayStyle: FieldDisplayStyle

    @State private var expansionState: GameplaySidebarExpansionState

    init(
        mode: GameplaySidebarMode,
        onSidebarAction: ((String) -> Void)? = nil,
        onPartyRowSelected: ((Int) -> Void)? = nil,
        fieldDisplayStyle: Binding<FieldDisplayStyle>
    ) {
        self.mode = mode
        self.onSidebarAction = onSidebarAction
        self.onPartyRowSelected = onPartyRowSelected
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
        .gameplayHoverCardHost()
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
                onPartyRowSelected: onPartyRowSelected,
                fieldDisplayStyle: $fieldDisplayStyle
            ) { section in
                expansionState.activate(section)
            }
        case let .battle(props):
            BattleModeSidebarContent(
                props: props,
                expansionState: expansionState,
                onPartyRowSelected: onPartyRowSelected
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
    let onPartyRowSelected: ((Int) -> Void)?
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
                title: "Pokédex",
                summary: "\(props.pokedex.ownedCount)/\(props.pokedex.totalCount)",
                isExpanded: expansionState.expandedSection == .pokedex
            ) {
                onActivateSection(.pokedex)
            } content: {
                PokedexSidebarContent(props: props.pokedex)
            }

            AccordionSidebarCard(
                title: "Party",
                summary: "\(props.party.pokemon.count)/\(props.party.totalSlots)",
                isExpanded: expansionState.expandedSection == .party
            ) {
                onActivateSection(.party)
            } content: {
                PartySidebarSectionContent(props: props.party, onRowSelected: onPartyRowSelected)
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
                    fieldDisplayStyle: $fieldDisplayStyle,
                    onAction: onSidebarAction
                )
            }

            Spacer(minLength: 0)
        }
    }
}

private struct BattleModeSidebarContent: View {
    let props: BattleSidebarProps
    let expansionState: GameplaySidebarExpansionState
    let onPartyRowSelected: ((Int) -> Void)?
    let onActivateSection: (GameplaySidebarExpandedSection) -> Void

    var body: some View {
        VStack(spacing: GameplayFieldMetrics.sidebarSectionSpacing) {
            AccordionSidebarCard(
                title: "Combat",
                summary: battleSummaryLabel,
                isExpanded: expansionState.expandedSection == .battleCombat,
                isHighlighted: props.attentionSection == .battleCombat
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
                isExpanded: expansionState.expandedSection == .party,
                isHighlighted: props.attentionSection == .party
            ) {
                onActivateSection(.party)
            } content: {
                PartySidebarSectionContent(props: props.party, onRowSelected: onPartyRowSelected)
            }

            Spacer(minLength: 0)
        }
    }

    private var battleSummaryLabel: String {
        guard props.showsInterface else {
            return "Intro"
        }
        switch props.phase {
        case "moveSelection":
            return "Moves"
        case "partySelection":
            return "Party"
        case "trainerAboutToUseDecision":
            return "Shift"
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

struct PartySidebarSectionContent: View {
    let props: PartySidebarProps
    let onRowSelected: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PartySidebarPrompt(promptText: props.promptText)

            if props.rowDensity == .compact {
                ScrollView(.vertical) {
                    PartySidebarRowsContent(props: props, onRowSelected: onRowSelected)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: GameplayFieldMetrics.partyExpandedMaxHeight, alignment: .top)
            } else {
                PartySidebarRowsContent(props: props, onRowSelected: onRowSelected)
            }
        }
    }
}
