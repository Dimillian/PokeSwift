import Foundation
import PokeDataModel

public enum GameplaySidebarExpandedSection: String, Equatable, Sendable, CaseIterable {
    case trainer
    case pokedex
    case battleCombat
    case party
    case bag
    case save
    case options
}

public struct GameplaySidebarExpansionState: Equatable, Sendable {
    public private(set) var expandedSection: GameplaySidebarExpandedSection

    public init(expandedSection: GameplaySidebarExpandedSection = .trainer) {
        self.expandedSection = expandedSection
    }

    public mutating func activate(_ section: GameplaySidebarExpandedSection) {
        expandedSection = section
    }
}

public struct TrainerPortraitProps: Equatable, Sendable {
    public let label: String
    public let spriteURL: URL?
    public let spriteFrame: PixelRect?

    public init(label: String, spriteURL: URL?, spriteFrame: PixelRect?) {
        self.label = label
        self.spriteURL = spriteURL
        self.spriteFrame = spriteFrame
    }
}

public struct TrainerBadgeProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let shortLabel: String
    public let isEarned: Bool

    public init(id: String, shortLabel: String, isEarned: Bool) {
        self.id = id
        self.shortLabel = shortLabel
        self.isEarned = isEarned
    }
}

public struct TrainerProfileProps: Equatable, Sendable {
    public let trainerName: String
    public let locationName: String
    public let portrait: TrainerPortraitProps
    public let badges: [TrainerBadgeProps]
    public let badgeSummaryText: String
    public let moneyText: String
    public let statusItems: [String]

    public init(
        trainerName: String,
        locationName: String,
        portrait: TrainerPortraitProps,
        badges: [TrainerBadgeProps],
        badgeSummaryText: String,
        moneyText: String,
        statusItems: [String]
    ) {
        self.trainerName = trainerName
        self.locationName = locationName
        self.portrait = portrait
        self.badges = badges
        self.badgeSummaryText = badgeSummaryText
        self.moneyText = moneyText
        self.statusItems = statusItems
    }
}

public struct PartySidebarMoveDetails: Equatable, Sendable {
    public let displayName: String
    public let typeLabel: String?
    public let maxPP: Int?
    public let power: Int?
    public let accuracy: Int?

    public init(
        displayName: String,
        typeLabel: String? = nil,
        maxPP: Int? = nil,
        power: Int? = nil,
        accuracy: Int? = nil
    ) {
        self.displayName = displayName
        self.typeLabel = typeLabel
        self.maxPP = maxPP
        self.power = power
        self.accuracy = accuracy
    }
}

public struct PartySidebarMoveProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let moveID: String
    public let displayName: String
    public let typeLabel: String?
    public let currentPP: Int?
    public let maxPP: Int?
    public let power: Int?
    public let accuracy: Int?

    public init(
        id: String,
        moveID: String,
        displayName: String,
        typeLabel: String? = nil,
        currentPP: Int? = nil,
        maxPP: Int? = nil,
        power: Int? = nil,
        accuracy: Int? = nil
    ) {
        self.id = id
        self.moveID = moveID
        self.displayName = displayName
        self.typeLabel = typeLabel
        self.currentPP = currentPP
        self.maxPP = maxPP
        self.power = power
        self.accuracy = accuracy
    }
}

public struct PartySidebarMoveMetadataProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let value: String

    public var displayText: String {
        "\(label) \(value)"
    }

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

extension PartySidebarMoveProps {
    public var typeChipText: String? {
        typeLabel?.uppercased()
    }

    public var metadataChips: [PartySidebarMoveMetadataProps] {
        [
            .init(id: "\(id)-pp", label: "PP", value: ppDisplayText),
            .init(id: "\(id)-power", label: "POW", value: powerDisplayText),
            .init(id: "\(id)-accuracy", label: "ACC", value: accuracyDisplayText),
        ]
    }

    public var ppDisplayText: String {
        switch (currentPP, maxPP) {
        case let (currentPP?, maxPP?):
            return "\(currentPP)/\(maxPP)"
        case let (currentPP?, nil):
            return "\(currentPP)"
        case let (nil, maxPP?):
            return "\(maxPP)"
        case (nil, nil):
            return "--"
        }
    }

    public var powerDisplayText: String {
        power.map(String.init) ?? "--"
    }

    public var accuracyDisplayText: String {
        accuracy.map(String.init) ?? "--"
    }
}

public struct PartySidebarPokemonProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let speciesID: String
    public let displayName: String
    public let level: Int
    public let totalExperience: Int
    public let levelStartExperience: Int
    public let nextLevelExperience: Int
    public let currentHP: Int
    public let maxHP: Int
    public let statHP: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int
    public let hpGrowthOutlook: PokemonStatGrowthTelemetry
    public let attackGrowthOutlook: PokemonStatGrowthTelemetry
    public let defenseGrowthOutlook: PokemonStatGrowthTelemetry
    public let speedGrowthOutlook: PokemonStatGrowthTelemetry
    public let specialGrowthOutlook: PokemonStatGrowthTelemetry
    public let isLead: Bool
    public let isSelectable: Bool
    public let isFocused: Bool
    public let isSelected: Bool
    public let selectionAnnotation: String?
    public let spriteURL: URL?
    public let typeLabels: [String]
    public let moves: [PartySidebarMoveProps]

    public var moveNames: [String] {
        moves.map(\.displayName)
    }

    public init(
        id: String,
        speciesID: String,
        displayName: String,
        level: Int,
        totalExperience: Int = 0,
        levelStartExperience: Int = 0,
        nextLevelExperience: Int = 1,
        currentHP: Int,
        maxHP: Int,
        statHP: Int? = nil,
        attack: Int = 0,
        defense: Int = 0,
        speed: Int = 0,
        special: Int = 0,
        hpGrowthOutlook: PokemonStatGrowthTelemetry = .neutral,
        attackGrowthOutlook: PokemonStatGrowthTelemetry = .neutral,
        defenseGrowthOutlook: PokemonStatGrowthTelemetry = .neutral,
        speedGrowthOutlook: PokemonStatGrowthTelemetry = .neutral,
        specialGrowthOutlook: PokemonStatGrowthTelemetry = .neutral,
        isLead: Bool,
        isSelectable: Bool = false,
        isFocused: Bool = false,
        isSelected: Bool = false,
        selectionAnnotation: String? = nil,
        spriteURL: URL? = nil,
        typeLabels: [String] = [],
        moves: [PartySidebarMoveProps] = []
    ) {
        self.id = id
        self.speciesID = speciesID
        self.displayName = displayName
        self.level = level
        self.totalExperience = totalExperience
        self.levelStartExperience = levelStartExperience
        self.nextLevelExperience = nextLevelExperience
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.statHP = statHP ?? maxHP
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
        self.hpGrowthOutlook = hpGrowthOutlook
        self.attackGrowthOutlook = attackGrowthOutlook
        self.defenseGrowthOutlook = defenseGrowthOutlook
        self.speedGrowthOutlook = speedGrowthOutlook
        self.specialGrowthOutlook = specialGrowthOutlook
        self.isLead = isLead
        self.isSelectable = isSelectable
        self.isFocused = isFocused
        self.isSelected = isSelected
        self.selectionAnnotation = selectionAnnotation
        self.spriteURL = spriteURL
        self.typeLabels = typeLabels
        self.moves = moves
    }
}

public struct PartySidebarSpeciesDetails: Equatable, Sendable {
    public let spriteURL: URL?
    public let primaryType: String
    public let secondaryType: String?

    public init(
        spriteURL: URL?,
        primaryType: String,
        secondaryType: String?
    ) {
        self.spriteURL = spriteURL
        self.primaryType = primaryType
        self.secondaryType = secondaryType
    }
}

public enum PartySidebarInteractionMode: String, Equatable, Sendable {
    case passive
    case fieldReorderSource
    case fieldReorderDestination
    case battleSwitch
}

public struct PartySidebarProps: Equatable, Sendable {
    public let pokemon: [PartySidebarPokemonProps]
    public let totalSlots: Int
    public let mode: PartySidebarInteractionMode
    public let promptText: String?

    public init(
        pokemon: [PartySidebarPokemonProps],
        totalSlots: Int = 6,
        mode: PartySidebarInteractionMode = .passive,
        promptText: String? = nil
    ) {
        self.pokemon = pokemon
        self.totalSlots = totalSlots
        self.mode = mode
        self.promptText = promptText
    }
}

enum PartySidebarRowDensity: Equatable, Sendable {
    case standard
    case compact
}

extension PartySidebarProps {
    var rowDensity: PartySidebarRowDensity {
        pokemon.count >= GameplayFieldMetrics.compactPartyThreshold ? .compact : .standard
    }
}

public struct InventorySidebarItemProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let quantityText: String

    public init(id: String, name: String, quantityText: String) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
    }
}

public struct InventorySidebarProps: Equatable, Sendable {
    public let title: String
    public let items: [InventorySidebarItemProps]
    public let emptyStateTitle: String
    public let emptyStateDetail: String

    public init(
        title: String,
        items: [InventorySidebarItemProps],
        emptyStateTitle: String,
        emptyStateDetail: String
    ) {
        self.title = title
        self.items = items
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDetail = emptyStateDetail
    }
}

public struct SidebarActionRowProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String?
    public let isEnabled: Bool

    public init(id: String, title: String, detail: String? = nil, isEnabled: Bool) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isEnabled = isEnabled
    }
}

public struct SaveSidebarProps: Equatable, Sendable {
    public let title: String
    public let summary: String
    public let actions: [SidebarActionRowProps]

    public init(title: String, summary: String, actions: [SidebarActionRowProps]) {
        self.title = title
        self.summary = summary
        self.actions = actions
    }
}

public struct GameBoyShellStyleOptionProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let shellStyle: GameBoyShellStyle
    public let title: String
    public let isSelected: Bool

    public init(
        id: String,
        shellStyle: GameBoyShellStyle,
        title: String,
        isSelected: Bool
    ) {
        self.id = id
        self.shellStyle = shellStyle
        self.title = title
        self.isSelected = isSelected
    }
}

public struct OptionsSidebarProps: Equatable, Sendable {
    public let title: String
    public let shellPickerTitle: String
    public let shellOptions: [GameBoyShellStyleOptionProps]
    public let rows: [SidebarActionRowProps]

    public init(
        title: String,
        shellPickerTitle: String,
        shellOptions: [GameBoyShellStyleOptionProps],
        rows: [SidebarActionRowProps]
    ) {
        self.title = title
        self.shellPickerTitle = shellPickerTitle
        self.shellOptions = shellOptions
        self.rows = rows
    }
}

public struct PokedexSidebarEvolutionProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let triggerText: String

    public init(id: String, displayName: String, triggerText: String) {
        self.id = id
        self.displayName = displayName
        self.triggerText = triggerText
    }
}

public struct PokedexSidebarLearnedMoveProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let levelText: String
    public let displayName: String

    public init(id: String, levelText: String, displayName: String) {
        self.id = id
        self.levelText = levelText
        self.displayName = displayName
    }
}

public struct PokedexSidebarEntryProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let dexNumber: Int
    public let displayName: String
    public let isOwned: Bool
    public let isSeen: Bool
    public let spriteURL: URL?
    public let primaryType: String?
    public let secondaryType: String?
    public let speciesCategory: String?
    public let heightText: String?
    public let weightText: String?
    public let descriptionText: String?
    public let preEvolution: PokedexSidebarEvolutionProps?
    public let evolutions: [PokedexSidebarEvolutionProps]
    public let learnedMoves: [PokedexSidebarLearnedMoveProps]
    public let detailFields: [PokedexSidebarDetailFieldProps]
    public let baseHP: Int
    public let baseAttack: Int
    public let baseDefense: Int
    public let baseSpeed: Int
    public let baseSpecial: Int

    public init(
        id: String,
        dexNumber: Int,
        displayName: String,
        isOwned: Bool,
        isSeen: Bool = false,
        spriteURL: URL?,
        primaryType: String?,
        secondaryType: String?,
        speciesCategory: String? = nil,
        heightText: String? = nil,
        weightText: String? = nil,
        descriptionText: String? = nil,
        preEvolution: PokedexSidebarEvolutionProps? = nil,
        evolutions: [PokedexSidebarEvolutionProps] = [],
        learnedMoves: [PokedexSidebarLearnedMoveProps] = [],
        detailFields: [PokedexSidebarDetailFieldProps] = [],
        baseHP: Int = 0,
        baseAttack: Int = 0,
        baseDefense: Int = 0,
        baseSpeed: Int = 0,
        baseSpecial: Int = 0
    ) {
        self.id = id
        self.dexNumber = dexNumber
        self.displayName = displayName
        self.isOwned = isOwned
        self.isSeen = isSeen || isOwned
        self.spriteURL = spriteURL
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.speciesCategory = speciesCategory
        self.heightText = heightText
        self.weightText = weightText
        self.descriptionText = descriptionText
        self.preEvolution = preEvolution
        self.evolutions = evolutions
        self.learnedMoves = learnedMoves
        self.detailFields = detailFields
        self.baseHP = baseHP
        self.baseAttack = baseAttack
        self.baseDefense = baseDefense
        self.baseSpeed = baseSpeed
        self.baseSpecial = baseSpecial
    }
}

public struct PokedexSidebarDetailFieldProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let value: String

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

public struct PokedexSidebarProps: Equatable, Sendable {
    public let entries: [PokedexSidebarEntryProps]
    public let ownedCount: Int
    public let seenCount: Int
    public let totalCount: Int
    public let selectedEntryID: String?

    public init(
        entries: [PokedexSidebarEntryProps],
        ownedCount: Int,
        seenCount: Int,
        totalCount: Int,
        selectedEntryID: String? = nil
    ) {
        self.entries = entries
        self.ownedCount = ownedCount
        self.seenCount = seenCount
        self.totalCount = totalCount
        self.selectedEntryID = selectedEntryID
    }
}

public struct GameplayFieldSidebarProps: Equatable, Sendable {
    public let profile: TrainerProfileProps
    public let pokedex: PokedexSidebarProps
    public let party: PartySidebarProps
    public let inventory: InventorySidebarProps
    public let save: SaveSidebarProps
    public let options: OptionsSidebarProps
    public let preferredExpandedSection: GameplaySidebarExpandedSection?

    public init(
        profile: TrainerProfileProps,
        pokedex: PokedexSidebarProps,
        party: PartySidebarProps,
        inventory: InventorySidebarProps,
        save: SaveSidebarProps,
        options: OptionsSidebarProps,
        preferredExpandedSection: GameplaySidebarExpandedSection? = nil
    ) {
        self.profile = profile
        self.pokedex = pokedex
        self.party = party
        self.inventory = inventory
        self.save = save
        self.options = options
        self.preferredExpandedSection = preferredExpandedSection
    }
}

public struct BattleSidebarProps: Equatable, Sendable {
    public let trainerName: String
    public let kind: BattleKind
    public let phase: String
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
        phase: String,
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

    public var shouldForceCombatSectionOpen: Bool {
        guard showsInterface else {
            return false
        }

        if party.mode == .battleSwitch {
            return false
        }

        return (
            phase == "moveSelection" ||
            phase == "bagSelection" ||
            phase == "trainerAboutToUseDecision" ||
            phase == "learnMoveDecision" ||
            phase == "learnMoveSelection"
        )
    }

    public var attentionSection: GameplaySidebarExpandedSection? {
        guard showsInterface else {
            return nil
        }

        if party.mode == .battleSwitch {
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

    public var actionRows: [BattleSidebarActionRowProps] {
        guard showsInterface else {
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

        if phase == "trainerAboutToUseDecision" {
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

public enum GameplaySidebarKind: String, Equatable, Sendable {
    case fieldLike
    case battle

    public static func forScene(_ scene: RuntimeScene) -> GameplaySidebarKind {
        switch scene {
        case .battle:
            return .battle
        default:
            return .fieldLike
        }
    }
}

public enum GameplaySidebarMode: Equatable, Sendable {
    case fieldLike(GameplayFieldSidebarProps)
    case battle(BattleSidebarProps)

    public var kind: GameplaySidebarKind {
        switch self {
        case .fieldLike:
            return .fieldLike
        case .battle:
            return .battle
        }
    }

    public var defaultExpandedSection: GameplaySidebarExpandedSection {
        switch self {
        case let .fieldLike(props):
            return props.preferredExpandedSection ?? .trainer
        case .battle:
            return .battleCombat
        }
    }

    public var requiredExpandedSection: GameplaySidebarExpandedSection? {
        switch self {
        case .fieldLike:
            return nil
        case let .battle(props):
            return props.attentionSection
        }
    }

    public func supports(_ section: GameplaySidebarExpandedSection) -> Bool {
        switch self {
        case .fieldLike:
            switch section {
            case .trainer, .pokedex, .party, .bag, .save, .options:
                return true
            case .battleCombat:
                return false
            }
        case .battle:
            switch section {
            case .battleCombat, .party:
                return true
            case .trainer, .pokedex, .bag, .save, .options:
                return false
            }
        }
    }

    public func resolvedExpandedSection(afterRequesting section: GameplaySidebarExpandedSection) -> GameplaySidebarExpandedSection {
        if let requiredExpandedSection {
            return requiredExpandedSection
        }
        return supports(section) ? section : defaultExpandedSection
    }
}

public enum GameplaySidebarPropsBuilder {
    public static func makeProfile(
        trainerName: String,
        locationName: String,
        scene: RuntimeScene,
        playerPosition: TilePoint?,
        facing: FacingDirection?,
        portrait: TrainerPortraitProps,
        money: Int,
        ownedBadgeIDs: Set<String>
    ) -> TrainerProfileProps {
        var statusItems = [sceneStatusLabel(scene)]
        if let playerPosition {
            statusItems.append("X\(playerPosition.x) Y\(playerPosition.y)")
        }
        if let facing {
            statusItems.append(facing.rawValue.uppercased())
        }

        let badges = makeBadges(ownedBadgeIDs: ownedBadgeIDs)

        return TrainerProfileProps(
            trainerName: trainerName,
            locationName: locationName,
            portrait: portrait,
            badges: badges,
            badgeSummaryText: "\(badges.filter(\.isEarned).count)/\(badges.count)",
            moneyText: formatMoney(money),
            statusItems: statusItems
        )
    }

    public static func makeParty(
        from party: PartyTelemetry?,
        speciesDetailsByID: [String: PartySidebarSpeciesDetails] = [:],
        moveDetailsByID: [String: PartySidebarMoveDetails] = [:],
        mode: PartySidebarInteractionMode = .passive,
        focusedIndex: Int? = nil,
        selectedIndex: Int? = nil,
        selectableIndices: Set<Int> = [],
        annotationByIndex: [Int: String] = [:],
        promptText: String? = nil,
        totalSlots: Int = 6
    ) -> PartySidebarProps {
        let mappedPokemon: [PartySidebarPokemonProps] = party?.pokemon.enumerated().map { index, pokemon in
            let speciesDetails = speciesDetailsByID[pokemon.speciesID]
            let moves = pokemon.moveStates.enumerated().map { moveIndex, move -> PartySidebarMoveProps in
                let moveDetails = moveDetailsByID[move.id]

                return PartySidebarMoveProps(
                    id: "\(pokemon.speciesID)-move-\(moveIndex)-\(move.id)",
                    moveID: move.id,
                    displayName: moveDetails?.displayName ?? move.id,
                    typeLabel: moveDetails?.typeLabel,
                    currentPP: move.currentPP,
                    maxPP: moveDetails?.maxPP,
                    power: moveDetails?.power,
                    accuracy: moveDetails?.accuracy
                )
            }

            return PartySidebarPokemonProps(
                id: "\(pokemon.speciesID)-\(index)",
                speciesID: pokemon.speciesID,
                displayName: pokemon.displayName,
                level: pokemon.level,
                totalExperience: pokemon.experience.total,
                levelStartExperience: pokemon.experience.levelStart,
                nextLevelExperience: pokemon.experience.nextLevel,
                currentHP: pokemon.currentHP,
                maxHP: max(1, pokemon.maxHP),
                statHP: max(1, pokemon.maxHP),
                attack: pokemon.attack,
                defense: pokemon.defense,
                speed: pokemon.speed,
                special: pokemon.special,
                hpGrowthOutlook: pokemon.growthOutlook.hp,
                attackGrowthOutlook: pokemon.growthOutlook.attack,
                defenseGrowthOutlook: pokemon.growthOutlook.defense,
                speedGrowthOutlook: pokemon.growthOutlook.speed,
                specialGrowthOutlook: pokemon.growthOutlook.special,
                isLead: index == 0,
                isSelectable: selectableIndices.contains(index),
                isFocused: focusedIndex == index,
                isSelected: selectedIndex == index,
                selectionAnnotation: annotationByIndex[index],
                spriteURL: speciesDetails?.spriteURL,
                typeLabels: [speciesDetails?.primaryType, speciesDetails?.secondaryType].compactMap { $0 },
                moves: moves
            )
        } ?? []

        return PartySidebarProps(
            pokemon: mappedPokemon,
            totalSlots: totalSlots,
            mode: mode,
            promptText: promptText
        )
    }

    public static func makePokedex(
        allSpecies: [PokedexSpeciesData],
        ownedSpeciesIDs: Set<String>,
        seenSpeciesIDs: Set<String>,
        speciesEncounterCounts: [String: Int] = [:],
        selectedEntryID: String? = nil
    ) -> PokedexSidebarProps {
        var ownedCount = 0
        var seenCount = 0
        let entries = allSpecies.map { species -> PokedexSidebarEntryProps in
            let isOwned = ownedSpeciesIDs.contains(species.id)
            let isSeen = seenSpeciesIDs.contains(species.id)
            if isOwned { ownedCount += 1 }
            if isSeen || isOwned { seenCount += 1 }
            return PokedexSidebarEntryProps(
                id: species.id,
                dexNumber: species.dexNumber,
                displayName: species.displayName,
                isOwned: isOwned,
                isSeen: isSeen,
                spriteURL: (isOwned || isSeen) ? species.spriteURL : nil,
                primaryType: (isOwned || isSeen) ? species.primaryType : nil,
                secondaryType: (isOwned || isSeen) ? species.secondaryType : nil,
                speciesCategory: isOwned ? species.speciesCategory : nil,
                heightText: isOwned ? species.heightText : nil,
                weightText: isOwned ? species.weightText : nil,
                descriptionText: isOwned ? species.descriptionText : nil,
                preEvolution: isOwned ? species.preEvolution : nil,
                evolutions: isOwned ? species.evolutions : [],
                learnedMoves: isOwned ? species.learnedMoves : [],
                detailFields: isOwned
                    ? pokedexDetailFields(
                        heightText: species.heightText,
                        weightText: species.weightText,
                        encounterCount: speciesEncounterCounts[species.id] ?? 0
                    )
                    : [],
                baseHP: isOwned ? species.baseHP : 0,
                baseAttack: isOwned ? species.baseAttack : 0,
                baseDefense: isOwned ? species.baseDefense : 0,
                baseSpeed: isOwned ? species.baseSpeed : 0,
                baseSpecial: isOwned ? species.baseSpecial : 0
            )
        }

        return PokedexSidebarProps(
            entries: entries,
            ownedCount: ownedCount,
            seenCount: seenCount,
            totalCount: entries.count,
            selectedEntryID: selectedEntryID
        )
    }

    private static func pokedexDetailFields(
        heightText: String?,
        weightText: String?,
        encounterCount: Int
    ) -> [PokedexSidebarDetailFieldProps] {
        var fields: [PokedexSidebarDetailFieldProps] = []
        if let heightText {
            fields.append(.init(id: "height", label: "HT", value: heightText))
        }
        if let weightText {
            fields.append(.init(id: "weight", label: "WT", value: weightText))
        }
        fields.append(.init(id: "encounters", label: "ENCOUNTERS", value: "\(max(0, encounterCount))"))
        return fields
    }

    public struct PokedexSpeciesData: Sendable {
        public let id: String
        public let dexNumber: Int
        public let displayName: String
        public let primaryType: String
        public let secondaryType: String?
        public let spriteURL: URL?
        public let speciesCategory: String?
        public let heightText: String?
        public let weightText: String?
        public let descriptionText: String?
        public let preEvolution: PokedexSidebarEvolutionProps?
        public let evolutions: [PokedexSidebarEvolutionProps]
        public let learnedMoves: [PokedexSidebarLearnedMoveProps]
        public let baseHP: Int
        public let baseAttack: Int
        public let baseDefense: Int
        public let baseSpeed: Int
        public let baseSpecial: Int

        public init(
            id: String, dexNumber: Int, displayName: String,
            primaryType: String, secondaryType: String?, spriteURL: URL?,
            speciesCategory: String?, heightText: String?, weightText: String?,
            descriptionText: String?,
            preEvolution: PokedexSidebarEvolutionProps? = nil,
            evolutions: [PokedexSidebarEvolutionProps] = [],
            learnedMoves: [PokedexSidebarLearnedMoveProps] = [],
            baseHP: Int, baseAttack: Int, baseDefense: Int, baseSpeed: Int, baseSpecial: Int
        ) {
            self.id = id
            self.dexNumber = dexNumber
            self.displayName = displayName
            self.primaryType = primaryType
            self.secondaryType = secondaryType
            self.spriteURL = spriteURL
            self.speciesCategory = speciesCategory
            self.heightText = heightText
            self.weightText = weightText
            self.descriptionText = descriptionText
            self.preEvolution = preEvolution
            self.evolutions = evolutions
            self.learnedMoves = learnedMoves
            self.baseHP = baseHP
            self.baseAttack = baseAttack
            self.baseDefense = baseDefense
            self.baseSpeed = baseSpeed
            self.baseSpecial = baseSpecial
        }
    }

    public static func makeInventory(items: [InventorySidebarItemProps] = []) -> InventorySidebarProps {
        InventorySidebarProps(
            title: "Bag",
            items: items,
            emptyStateTitle: "No items yet",
            emptyStateDetail: "No items collected in the current save."
        )
    }

    public static func makeSaveSection(summary: String = "Locked", actions: [SidebarActionRowProps]? = nil) -> SaveSidebarProps {
        SaveSidebarProps(
            title: "Save",
            summary: summary,
            actions: actions ?? [
                .init(id: "save", title: "Save Game", detail: "Unavailable", isEnabled: false),
                .init(id: "load", title: "Load Save", detail: "Unavailable", isEnabled: false),
            ]
        )
    }

    public static func makeOptionsSection(
        isMusicEnabled: Bool,
        appearanceMode: AppAppearanceMode,
        gameBoyShellStyle: GameBoyShellStyle,
        gameplayHDREnabled: Bool,
        textSpeed: TextSpeed = .medium,
        battleAnimation: BattleAnimation = .on,
        battleStyle: BattleStyle = .shift
    ) -> OptionsSidebarProps {
        OptionsSidebarProps(
            title: "Options",
            shellPickerTitle: "GB Shell",
            shellOptions: GameBoyShellStyle.allCases.map { shellStyle in
                GameBoyShellStyleOptionProps(
                    id: shellStyle.actionID,
                    shellStyle: shellStyle,
                    title: shellStyle.optionsLabel,
                    isSelected: shellStyle == gameBoyShellStyle
                )
            },
            rows: [
                .init(id: "appearanceMode", title: "Appearance", detail: appearanceMode.optionsLabel, isEnabled: true),
                .init(id: "gameplayHDR", title: "HDR Effects", detail: gameplayHDREnabled ? "On" : "Off", isEnabled: true),
                .init(id: "textSpeed", title: "Text Speed", detail: textSpeed.label, isEnabled: true),
                .init(id: "battleScene", title: "Battle Scene", detail: battleAnimation.label, isEnabled: true),
                .init(id: "battleStyle", title: "Battle Style", detail: battleStyle.label, isEnabled: true),
                .init(id: "music", title: "Music", detail: isMusicEnabled ? "On" : "Off", isEnabled: true),
            ]
        )
    }

    private static func sceneStatusLabel(_ scene: RuntimeScene) -> String {
        switch scene {
        case .field:
            "FIELD"
        case .dialogue:
            "DIALOGUE"
        case .scriptedSequence:
            "SCRIPT"
        case .starterChoice:
            "STARTER"
        case .battle:
            "BATTLE"
        case .evolution:
            "EVOLVE"
        case .titleMenu:
            "MENU"
        case .titleAttract:
            "ATTRACT"
        case .launch:
            "LAUNCH"
        case .splash:
            "SPLASH"
        case .naming:
            "NAMING"
        case .oakIntro:
            "INTRO"
        case .titleOptions:
            "OPTIONS"
        case .placeholder:
            "PLACEHOLDER"
        }
    }

    private static func makeBadges(ownedBadgeIDs: Set<String>) -> [TrainerBadgeProps] {
        let normalizedBadgeIDs = Set(ownedBadgeIDs.map(normalizedBadgeID))
        return badgeDefinitions.map { definition in
            TrainerBadgeProps(
                id: definition.id,
                shortLabel: definition.shortLabel,
                isEarned: normalizedBadgeIDs.contains(definition.id)
            )
        }
    }

    private static func normalizedBadgeID(_ badgeID: String) -> String {
        badgeID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_badge", with: "")
            .replacingOccurrences(of: "badge", with: "")
    }

    private static func formatMoney(_ amount: Int) -> String {
        "¥\(moneyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }

    private static let moneyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let badgeDefinitions: [(id: String, shortLabel: String)] = [
        ("boulder", "B"),
        ("cascade", "C"),
        ("thunder", "T"),
        ("rainbow", "R"),
        ("soul", "S"),
        ("marsh", "M"),
        ("volcano", "V"),
        ("earth", "E"),
    ]
}
