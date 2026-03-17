import PokeDataModel

public struct BattleSidebarProps: Equatable, Sendable {
    public let trainerName: String
    public let kind: BattleKind
    public let phase: BattlePhaseTelemetry
    public let promptText: String
    public let playerPokemon: PartyPokemonTelemetry
    public let enemyPokemon: PartyPokemonTelemetry
    public let learnMovePrompt: BattleLearnMovePromptTelemetry?
    public let moveSlots: [BattleMoveSlotTelemetry]
    public let focusedMoveIndex: Int
    public let canRun: Bool
    public let canUseBag: Bool
    public let canSwitch: Bool
    public let bagItemCount: Int
    public let moveDetailsByID: [String: PartySidebarMoveDetails]
    public let party: PartySidebarProps
    public let capture: BattleCaptureTelemetry?
    public let presentation: BattlePresentationTelemetry

    public init(
        trainerName: String,
        kind: BattleKind,
        phase: BattlePhaseTelemetry,
        promptText: String,
        playerPokemon: PartyPokemonTelemetry,
        enemyPokemon: PartyPokemonTelemetry,
        learnMovePrompt: BattleLearnMovePromptTelemetry? = nil,
        moveSlots: [BattleMoveSlotTelemetry],
        focusedMoveIndex: Int,
        canRun: Bool,
        canUseBag: Bool = false,
        canSwitch: Bool = false,
        bagItemCount: Int = 0,
        moveDetailsByID: [String: PartySidebarMoveDetails] = [:],
        party: PartySidebarProps,
        capture: BattleCaptureTelemetry? = nil,
        presentation: BattlePresentationTelemetry = .init(
            stage: .idle,
            revision: 0,
            uiVisibility: .visible
        )
    ) {
        self.trainerName = trainerName
        self.kind = kind
        self.phase = phase
        self.promptText = promptText
        self.playerPokemon = playerPokemon
        self.enemyPokemon = enemyPokemon
        self.learnMovePrompt = learnMovePrompt
        self.moveSlots = moveSlots
        self.focusedMoveIndex = focusedMoveIndex
        self.canRun = canRun
        self.canUseBag = canUseBag
        self.canSwitch = canSwitch
        self.bagItemCount = bagItemCount
        self.moveDetailsByID = moveDetailsByID
        self.party = party
        self.capture = capture
        self.presentation = presentation
    }
}

public struct BattleSidebarActionRowProps: Identifiable, Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case move
        case bag
        case partySwitch
        case run
        case learn
        case skip
        case forget
        case confirm
        case deny
    }

    public let id: String
    public let title: String
    public let detail: String?
    public let isSelectable: Bool
    public let isFocused: Bool
    public let kind: Kind
    public let slotIndex: Int?

    public init(
        id: String,
        title: String,
        detail: String?,
        isSelectable: Bool,
        isFocused: Bool,
        kind: Kind,
        slotIndex: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isSelectable = isSelectable
        self.isFocused = isFocused
        self.kind = kind
        self.slotIndex = slotIndex
    }
}

// MARK: - Computed Behavior

extension BattleSidebarProps {
    public var shouldForceCombatSectionOpen: Bool {
        guard showsInterface else {
            return false
        }

        if party.mode == .battleSwitch || party.mode == .itemUseTarget {
            return false
        }

        return (
            phase == .moveSelection ||
            phase == .bagSelection ||
            phase == .trainerAboutToUseDecision ||
            phase == .learnMoveDecision ||
            phase == .learnMoveSelection
        )
    }

    public var attentionSection: GameplaySidebarExpandedSection? {
        guard showsInterface else {
            return nil
        }

        if party.mode == .battleSwitch || party.mode == .itemUseTarget {
            return .party
        }

        if shouldForceCombatSectionOpen {
            return .battleCombat
        }

        return nil
    }

    public var showsInterface: Bool {
        presentation.uiVisibility == .visible
    }

    public var showsEnemyCombatantStatus: Bool {
        guard showsInterface else {
            return false
        }

        if kind == .trainer, presentation.stage == .introReveal {
            return false
        }

        return true
    }

    public var showsPlayerCombatantStatus: Bool {
        guard showsInterface else {
            return false
        }

        switch presentation.stage {
        case .introReveal:
            return false
        case .enemySendOut where presentation.activeSide == .enemy:
            return false
        default:
            return true
        }
    }

    public var showsActionRows: Bool {
        guard showsInterface else {
            return false
        }

        if learnMovePrompt != nil || phase == .trainerAboutToUseDecision {
            return true
        }

        guard phase == .moveSelection else {
            return false
        }

        return presentation.stage == .commandReady
    }

    public var actionRows: [BattleSidebarActionRowProps] {
        guard showsActionRows else {
            return []
        }
        if let learnMovePrompt {
            switch learnMovePrompt.stage {
            case .confirm:
                return [
                    BattleSidebarActionRowProps(
                        id: "learn-move",
                        title: "Learn \(learnMovePrompt.moveDisplayName)",
                        detail: nil,
                        isSelectable: true,
                        isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == 0,
                        kind: .learn
                    ),
                    BattleSidebarActionRowProps(
                        id: "skip-move",
                        title: "Skip",
                        detail: nil,
                        isSelectable: true,
                        isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == 1,
                        kind: .skip
                    ),
                ]
            case .replace:
                return moveSlots.enumerated().map { index, slot in
                    BattleSidebarActionRowProps(
                        id: "forget-\(index)",
                        title: slot.displayName,
                        detail: "\(slot.currentPP)/\(slot.maxPP)",
                        isSelectable: slot.isSelectable,
                        isFocused: shouldForceCombatSectionOpen && index == focusedMoveIndex,
                        kind: .forget,
                        slotIndex: index
                    )
                }
            }
        }

        if phase == .trainerAboutToUseDecision {
            return [
                BattleSidebarActionRowProps(
                    id: "trainer-about-to-use-yes",
                    title: "YES",
                    detail: "Switch",
                    isSelectable: true,
                    isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == 0,
                    kind: .confirm
                ),
                BattleSidebarActionRowProps(
                    id: "trainer-about-to-use-no",
                    title: "NO",
                    detail: "Stay in",
                    isSelectable: true,
                    isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == 1,
                    kind: .deny
                ),
            ]
        }

        let moveRows = moveSlots.enumerated().map { index, slot in
            BattleSidebarActionRowProps(
                id: "move-\(index)",
                title: slot.displayName,
                detail: "\(slot.currentPP)/\(slot.maxPP)",
                isSelectable: slot.isSelectable,
                isFocused: shouldForceCombatSectionOpen && index == focusedMoveIndex,
                kind: .move,
                slotIndex: index
            )
        }

        var rows = moveRows

        if canUseBag {
            rows.append(
                BattleSidebarActionRowProps(
                    id: "bag",
                    title: "Bag",
                    detail: "\(bagItemCount)",
                    isSelectable: shouldForceCombatSectionOpen,
                    isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == moveSlots.count,
                    kind: .bag
                )
            )
        }

        if canSwitch {
            rows.append(
                BattleSidebarActionRowProps(
                    id: "switch",
                    title: "Switch",
                    detail: nil,
                    isSelectable: shouldForceCombatSectionOpen,
                    isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == moveSlots.count + (canUseBag ? 1 : 0),
                    kind: .partySwitch
                )
            )
        }

        if canRun {
            rows.append(
                BattleSidebarActionRowProps(
                    id: "run",
                    title: "Run",
                    detail: nil,
                    isSelectable: shouldForceCombatSectionOpen,
                    isFocused: shouldForceCombatSectionOpen && focusedMoveIndex == moveSlots.count + (canUseBag ? 1 : 0) + (canSwitch ? 1 : 0),
                    kind: .run
                )
            )
        }

        return rows
    }

    public func moveCardProps(for actionRow: BattleSidebarActionRowProps) -> PartySidebarMoveProps? {
        guard let slotIndex = actionRow.slotIndex, moveSlots.indices.contains(slotIndex) else {
            return nil
        }

        let slot = moveSlots[slotIndex]
        let moveDetails = moveDetailsByID[slot.moveID]
        return PartySidebarMoveProps(
            id: actionRow.id,
            moveID: slot.moveID,
            displayName: moveDetails?.displayName ?? slot.displayName,
            typeLabel: moveDetails?.typeLabel,
            currentPP: slot.currentPP,
            maxPP: moveDetails?.maxPP ?? slot.maxPP,
            power: moveDetails?.power,
            accuracy: moveDetails?.accuracy
        )
    }
}
