import Foundation

public enum PokemonGrowthRate: String, Codable, Equatable, Sendable, CaseIterable {
    case mediumFast = "GROWTH_MEDIUM_FAST"
    case slightlyFast = "GROWTH_SLIGHTLY_FAST"
    case slightlySlow = "GROWTH_SLIGHTLY_SLOW"
    case mediumSlow = "GROWTH_MEDIUM_SLOW"
    case fast = "GROWTH_FAST"
    case slow = "GROWTH_SLOW"
}

public struct PokemonDVs: Codable, Equatable, Sendable {
    public static let zero = PokemonDVs(attack: 0, defense: 0, speed: 0, special: 0)

    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int

    public var hp: Int {
        ((attack & 1) << 3) | ((defense & 1) << 2) | ((speed & 1) << 1) | (special & 1)
    }

    public init(attack: Int, defense: Int, speed: Int, special: Int) {
        self.attack = min(15, max(0, attack))
        self.defense = min(15, max(0, defense))
        self.speed = min(15, max(0, speed))
        self.special = min(15, max(0, special))
    }
}

public struct PokemonStatExp: Codable, Equatable, Sendable {
    public static let zero = PokemonStatExp(hp: 0, attack: 0, defense: 0, speed: 0, special: 0)

    public let hp: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int

    public init(hp: Int, attack: Int, defense: Int, speed: Int, special: Int) {
        self.hp = min(65_535, max(0, hp))
        self.attack = min(65_535, max(0, attack))
        self.defense = min(65_535, max(0, defense))
        self.speed = min(65_535, max(0, speed))
        self.special = min(65_535, max(0, special))
    }
}

public struct SpeciesManifest: Codable, Equatable, Sendable {
    public let primaryType: String
    public let secondaryType: String?
    public let battleSprite: BattleSpriteManifest?
    public let battlePaletteID: String?
    public let id: String
    public let displayName: String
    public let catchRate: Int
    public let baseExp: Int
    public let growthRate: PokemonGrowthRate
    public let baseHP: Int
    public let baseAttack: Int
    public let baseDefense: Int
    public let baseSpeed: Int
    public let baseSpecial: Int
    public let startingMoves: [String]
    public let evolutions: [EvolutionManifest]
    public let levelUpLearnset: [LevelUpMoveManifest]
    public let crySoundEffectID: String?
    public let cryPitch: Int?
    public let cryLength: Int?
    public let dexNumber: Int?
    public let speciesCategory: String?
    public let heightFeet: Int?
    public let heightInches: Int?
    public let weightTenths: Int?
    public let pokedexEntryText: String?

    public init(
        id: String,
        displayName: String,
        primaryType: String = "NORMAL",
        secondaryType: String? = nil,
        battleSprite: BattleSpriteManifest? = nil,
        battlePaletteID: String? = nil,
        catchRate: Int = 0,
        baseExp: Int = 0,
        growthRate: PokemonGrowthRate = .mediumFast,
        baseHP: Int,
        baseAttack: Int,
        baseDefense: Int,
        baseSpeed: Int,
        baseSpecial: Int,
        startingMoves: [String],
        evolutions: [EvolutionManifest] = [],
        levelUpLearnset: [LevelUpMoveManifest] = [],
        crySoundEffectID: String? = nil,
        cryPitch: Int? = nil,
        cryLength: Int? = nil,
        dexNumber: Int? = nil,
        speciesCategory: String? = nil,
        heightFeet: Int? = nil,
        heightInches: Int? = nil,
        weightTenths: Int? = nil,
        pokedexEntryText: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.battleSprite = battleSprite
        self.battlePaletteID = battlePaletteID
        self.catchRate = catchRate
        self.baseExp = baseExp
        self.growthRate = growthRate
        self.baseHP = baseHP
        self.baseAttack = baseAttack
        self.baseDefense = baseDefense
        self.baseSpeed = baseSpeed
        self.baseSpecial = baseSpecial
        self.startingMoves = startingMoves
        self.evolutions = evolutions
        self.levelUpLearnset = levelUpLearnset
        self.crySoundEffectID = crySoundEffectID
        self.cryPitch = cryPitch
        self.cryLength = cryLength
        self.dexNumber = dexNumber
        self.speciesCategory = speciesCategory
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weightTenths = weightTenths
        self.pokedexEntryText = pokedexEntryText
    }

    private enum CodingKeys: String, CodingKey {
        case primaryType
        case secondaryType
        case battleSprite
        case battlePaletteID
        case id
        case displayName
        case catchRate
        case baseExp
        case growthRate
        case baseHP
        case baseAttack
        case baseDefense
        case baseSpeed
        case baseSpecial
        case startingMoves
        case evolutions
        case levelUpLearnset
        case crySoundEffectID
        case cryPitch
        case cryLength
        case dexNumber
        case speciesCategory
        case heightFeet
        case heightInches
        case weightTenths
        case pokedexEntryText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        primaryType = try container.decodeIfPresent(String.self, forKey: .primaryType) ?? "NORMAL"
        secondaryType = try container.decodeIfPresent(String.self, forKey: .secondaryType)
        battleSprite = try container.decodeIfPresent(BattleSpriteManifest.self, forKey: .battleSprite)
        battlePaletteID = try container.decodeIfPresent(String.self, forKey: .battlePaletteID)
        catchRate = try container.decodeIfPresent(Int.self, forKey: .catchRate) ?? 0
        baseExp = try container.decodeIfPresent(Int.self, forKey: .baseExp) ?? 0
        growthRate = try container.decodeIfPresent(PokemonGrowthRate.self, forKey: .growthRate) ?? .mediumFast
        baseHP = try container.decode(Int.self, forKey: .baseHP)
        baseAttack = try container.decode(Int.self, forKey: .baseAttack)
        baseDefense = try container.decode(Int.self, forKey: .baseDefense)
        baseSpeed = try container.decode(Int.self, forKey: .baseSpeed)
        baseSpecial = try container.decode(Int.self, forKey: .baseSpecial)
        startingMoves = try container.decode([String].self, forKey: .startingMoves)
        evolutions = try container.decodeIfPresent([EvolutionManifest].self, forKey: .evolutions) ?? []
        levelUpLearnset = try container.decodeIfPresent([LevelUpMoveManifest].self, forKey: .levelUpLearnset) ?? []
        crySoundEffectID = try container.decodeIfPresent(String.self, forKey: .crySoundEffectID)
        cryPitch = try container.decodeIfPresent(Int.self, forKey: .cryPitch)
        cryLength = try container.decodeIfPresent(Int.self, forKey: .cryLength)
        dexNumber = try container.decodeIfPresent(Int.self, forKey: .dexNumber)
        speciesCategory = try container.decodeIfPresent(String.self, forKey: .speciesCategory)
        heightFeet = try container.decodeIfPresent(Int.self, forKey: .heightFeet)
        heightInches = try container.decodeIfPresent(Int.self, forKey: .heightInches)
        weightTenths = try container.decodeIfPresent(Int.self, forKey: .weightTenths)
        pokedexEntryText = try container.decodeIfPresent(String.self, forKey: .pokedexEntryText)
    }
}

public enum EvolutionTriggerKind: String, Codable, Equatable, Sendable {
    case level
    case item
    case trade
}

public struct EvolutionTriggerManifest: Codable, Equatable, Sendable {
    public let kind: EvolutionTriggerKind
    public let level: Int?
    public let itemID: String?
    public let minimumLevel: Int?

    public init(
        kind: EvolutionTriggerKind,
        level: Int? = nil,
        itemID: String? = nil,
        minimumLevel: Int? = nil
    ) {
        self.kind = kind
        self.level = level.map { max(1, $0) }
        self.itemID = itemID
        self.minimumLevel = minimumLevel.map { max(1, $0) }
    }
}

public struct EvolutionManifest: Codable, Equatable, Sendable {
    public let trigger: EvolutionTriggerManifest
    public let targetSpeciesID: String

    public init(trigger: EvolutionTriggerManifest, targetSpeciesID: String) {
        self.trigger = trigger
        self.targetSpeciesID = targetSpeciesID
    }
}

public struct LevelUpMoveManifest: Codable, Equatable, Sendable {
    public let level: Int
    public let moveID: String

    public init(level: Int, moveID: String) {
        self.level = max(1, level)
        self.moveID = moveID
    }
}

public struct BattleSpriteManifest: Codable, Equatable, Sendable {
    public let frontImagePath: String
    public let backImagePath: String

    public init(frontImagePath: String, backImagePath: String) {
        self.frontImagePath = frontImagePath
        self.backImagePath = backImagePath
    }
}
