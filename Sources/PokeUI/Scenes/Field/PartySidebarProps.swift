import Foundation
import PokeDataModel

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
    case itemUseTarget
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
