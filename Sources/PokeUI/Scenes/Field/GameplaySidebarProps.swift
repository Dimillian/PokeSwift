import Foundation
import PokeDataModel

public enum GameplaySidebarExpandedSection: String, Equatable, Sendable, CaseIterable {
    case trainer
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
    public let moveNames: [String]

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
        moveNames: [String] = []
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
        self.moveNames = moveNames
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

public struct OptionsSidebarProps: Equatable, Sendable {
    public let title: String
    public let rows: [SidebarActionRowProps]

    public init(title: String, rows: [SidebarActionRowProps]) {
        self.title = title
        self.rows = rows
    }
}

public struct GameplayFieldSidebarProps: Equatable, Sendable {
    public let profile: TrainerProfileProps
    public let party: PartySidebarProps
    public let inventory: InventorySidebarProps
    public let save: SaveSidebarProps
    public let options: OptionsSidebarProps

    public init(
        profile: TrainerProfileProps,
        party: PartySidebarProps,
        inventory: InventorySidebarProps,
        save: SaveSidebarProps,
        options: OptionsSidebarProps
    ) {
        self.profile = profile
        self.party = party
        self.inventory = inventory
        self.save = save
        self.options = options
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
            phase == "learnMoveDecision" ||
            phase == "learnMoveSelection"
        )
    }

    public var showsInterface: Bool {
        presentation.uiVisibility == .visible
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
                        kind: .forget
                    )
                }
            }
        }

        let moveRows = moveSlots.enumerated().map { index, slot in
            BattleSidebarActionRowProps(
                id: "move-\(index)",
                title: slot.displayName,
                detail: "\(slot.currentPP)/\(slot.maxPP)",
                isSelectable: slot.isSelectable,
                isFocused: shouldForceCombatSectionOpen && index == focusedMoveIndex,
                kind: .move
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
    }

    public let id: String
    public let title: String
    public let detail: String?
    public let isSelectable: Bool
    public let isFocused: Bool
    public let kind: Kind

    public init(
        id: String,
        title: String,
        detail: String?,
        isSelectable: Bool,
        isFocused: Bool,
        kind: Kind
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isSelectable = isSelectable
        self.isFocused = isFocused
        self.kind = kind
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
        case .fieldLike:
            return .trainer
        case .battle:
            return .battleCombat
        }
    }

    public var requiredExpandedSection: GameplaySidebarExpandedSection? {
        switch self {
        case .fieldLike:
            return nil
        case let .battle(props):
            if props.party.mode == .battleSwitch {
                return .party
            }
            return props.shouldForceCombatSectionOpen ? .battleCombat : nil
        }
    }

    public func supports(_ section: GameplaySidebarExpandedSection) -> Bool {
        switch self {
        case .fieldLike:
            switch section {
            case .trainer, .party, .bag, .save, .options:
                return true
            case .battleCombat:
                return false
            }
        case .battle:
            switch section {
            case .battleCombat, .party:
                return true
            case .trainer, .bag, .save, .options:
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
        moveDisplayNamesByID: [String: String] = [:],
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
            let moveNames = pokemon.moves.map { moveDisplayNamesByID[$0] ?? $0 }

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
                moveNames: moveNames
            )
        } ?? []

        return PartySidebarProps(
            pokemon: mappedPokemon,
            totalSlots: totalSlots,
            mode: mode,
            promptText: promptText
        )
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
        appearanceMode: AppAppearanceMode
    ) -> OptionsSidebarProps {
        OptionsSidebarProps(
            title: "Options",
            rows: [
                .init(id: "appearanceMode", title: "Appearance", detail: appearanceMode.optionsLabel, isEnabled: true),
                .init(id: "textSpeed", title: "Text Speed", detail: "Medium", isEnabled: false),
                .init(id: "battleScene", title: "Battle Scene", detail: "On", isEnabled: false),
                .init(id: "battleStyle", title: "Battle Style", detail: "Shift", isEnabled: false),
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
        case .placeholder:
            "PLACEHOLDER"
        }
    }

    private static func makeBadges(ownedBadgeIDs: Set<String>) -> [TrainerBadgeProps] {
        badgeDefinitions.map { definition in
            TrainerBadgeProps(
                id: definition.id,
                shortLabel: definition.shortLabel,
                isEarned: ownedBadgeIDs.contains(definition.id)
            )
        }
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
