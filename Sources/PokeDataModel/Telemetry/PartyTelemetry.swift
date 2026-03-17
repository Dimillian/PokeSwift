import Foundation

public struct PartyMoveTelemetry: Codable, Equatable, Sendable {
    public let id: String
    public let currentPP: Int?

    public init(id: String, currentPP: Int? = nil) {
        self.id = id
        self.currentPP = currentPP
    }
}

public struct PartyPokemonTelemetry: Codable, Equatable, Sendable {
    public let experience: ExperienceProgressTelemetry
    public let speciesID: String
    public let displayName: String
    public let level: Int
    public let currentHP: Int
    public let maxHP: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int
    public let growthOutlook: PokemonGrowthOutlookTelemetry
    public let majorStatus: MajorStatusCondition
    public let moves: [String]
    public let moveStates: [PartyMoveTelemetry]

    public init(
        speciesID: String,
        displayName: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        attack: Int,
        defense: Int,
        speed: Int,
        special: Int,
        majorStatus: MajorStatusCondition = .none,
        moves: [String],
        moveStates: [PartyMoveTelemetry]? = nil,
        experience: ExperienceProgressTelemetry = .init(total: 0, levelStart: 0, nextLevel: 1),
        growthOutlook: PokemonGrowthOutlookTelemetry = .neutral
    ) {
        self.experience = experience
        self.speciesID = speciesID
        self.displayName = displayName
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
        self.growthOutlook = growthOutlook
        self.majorStatus = majorStatus
        self.moves = moves
        self.moveStates = moveStates ?? moves.map { PartyMoveTelemetry(id: $0) }
    }

    public init(
        speciesID: String,
        displayName: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        attack: Int,
        defense: Int,
        speed: Int,
        special: Int,
        majorStatus: MajorStatusCondition = .none,
        moveStates: [PartyMoveTelemetry],
        experience: ExperienceProgressTelemetry = .init(total: 0, levelStart: 0, nextLevel: 1),
        growthOutlook: PokemonGrowthOutlookTelemetry = .neutral
    ) {
        self.init(
            speciesID: speciesID,
            displayName: displayName,
            level: level,
            currentHP: currentHP,
            maxHP: maxHP,
            attack: attack,
            defense: defense,
            speed: speed,
            special: special,
            majorStatus: majorStatus,
            moves: moveStates.map(\.id),
            moveStates: moveStates,
            experience: experience,
            growthOutlook: growthOutlook
        )
    }

    private enum CodingKeys: String, CodingKey {
        case experience
        case speciesID
        case displayName
        case level
        case currentHP
        case maxHP
        case attack
        case defense
        case speed
        case special
        case growthOutlook
        case majorStatus
        case moves
        case moveStates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        experience = try container.decode(ExperienceProgressTelemetry.self, forKey: .experience, default: .init(total: 0, levelStart: 0, nextLevel: 1))
        speciesID = try container.decode(String.self, forKey: .speciesID)
        displayName = try container.decode(String.self, forKey: .displayName)
        level = try container.decode(Int.self, forKey: .level)
        currentHP = try container.decode(Int.self, forKey: .currentHP)
        maxHP = try container.decode(Int.self, forKey: .maxHP)
        attack = try container.decode(Int.self, forKey: .attack, default: 0)
        defense = try container.decode(Int.self, forKey: .defense, default: 0)
        speed = try container.decode(Int.self, forKey: .speed, default: 0)
        special = try container.decode(Int.self, forKey: .special, default: 0)
        growthOutlook = try container.decode(PokemonGrowthOutlookTelemetry.self, forKey: .growthOutlook, default: .neutral)
        majorStatus = try container.decode(MajorStatusCondition.self, forKey: .majorStatus, default: .none)

        let decodedLegacyMoves: [String]
        let decodedMoveStates: [PartyMoveTelemetry]
        if let legacyMoveIDs = try? container.decode([String].self, forKey: .moves) {
            decodedLegacyMoves = legacyMoveIDs
        } else if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moves) {
            decodedLegacyMoves = structuredMoves.map(\.id)
        } else {
            decodedLegacyMoves = []
        }

        if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moveStates) {
            decodedMoveStates = structuredMoves
        } else if let structuredMoves = try? container.decode([PartyMoveTelemetry].self, forKey: .moves) {
            decodedMoveStates = structuredMoves
        } else {
            decodedMoveStates = decodedLegacyMoves.map { PartyMoveTelemetry(id: $0) }
        }

        moveStates = decodedMoveStates
        moves = decodedLegacyMoves.isEmpty ? decodedMoveStates.map(\.id) : decodedLegacyMoves
    }
}

public struct ExperienceProgressTelemetry: Codable, Equatable, Sendable {
    public let total: Int
    public let levelStart: Int
    public let nextLevel: Int

    public init(total: Int, levelStart: Int, nextLevel: Int) {
        self.total = total
        self.levelStart = levelStart
        self.nextLevel = nextLevel
    }
}

public enum PokemonStatGrowthTelemetry: String, Codable, Equatable, Sendable {
    case favored
    case neutral
    case lagging
}

public struct PokemonGrowthOutlookTelemetry: Codable, Equatable, Sendable {
    public static let neutral = PokemonGrowthOutlookTelemetry(
        hp: .neutral,
        attack: .neutral,
        defense: .neutral,
        speed: .neutral,
        special: .neutral
    )

    public let hp: PokemonStatGrowthTelemetry
    public let attack: PokemonStatGrowthTelemetry
    public let defense: PokemonStatGrowthTelemetry
    public let speed: PokemonStatGrowthTelemetry
    public let special: PokemonStatGrowthTelemetry

    public init(
        hp: PokemonStatGrowthTelemetry,
        attack: PokemonStatGrowthTelemetry,
        defense: PokemonStatGrowthTelemetry,
        speed: PokemonStatGrowthTelemetry,
        special: PokemonStatGrowthTelemetry
    ) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
    }
}

public struct PartyTelemetry: Codable, Equatable, Sendable {
    public let pokemon: [PartyPokemonTelemetry]

    public init(pokemon: [PartyPokemonTelemetry]) {
        self.pokemon = pokemon
    }
}
