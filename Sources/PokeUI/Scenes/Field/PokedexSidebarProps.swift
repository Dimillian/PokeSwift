import Foundation

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
