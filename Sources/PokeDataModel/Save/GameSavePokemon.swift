import Foundation

public struct GameSaveMove: Codable, Equatable, Sendable {
    public let id: String
    public let currentPP: Int

    public init(id: String, currentPP: Int) {
        self.id = id
        self.currentPP = currentPP
    }
}

public struct GameSavePokemon: Codable, Equatable, Sendable {
    public let speciesID: String
    public let nickname: String
    public let level: Int
    public let experience: Int
    public let dvs: PokemonDVs
    public let statExp: PokemonStatExp
    public let maxHP: Int
    public let currentHP: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let special: Int
    public let attackStage: Int
    public let defenseStage: Int
    public let speedStage: Int
    public let specialStage: Int
    public let accuracyStage: Int
    public let evasionStage: Int
    public let majorStatus: MajorStatusCondition
    public let statusCounter: Int
    public let moves: [GameSaveMove]

    public init(
        speciesID: String,
        nickname: String,
        level: Int,
        experience: Int = 0,
        dvs: PokemonDVs = .zero,
        statExp: PokemonStatExp = .zero,
        maxHP: Int,
        currentHP: Int,
        attack: Int,
        defense: Int,
        speed: Int,
        special: Int,
        attackStage: Int,
        defenseStage: Int,
        speedStage: Int = 0,
        specialStage: Int = 0,
        accuracyStage: Int,
        evasionStage: Int,
        majorStatus: MajorStatusCondition = .none,
        statusCounter: Int = 0,
        moves: [GameSaveMove]
    ) {
        self.speciesID = speciesID
        self.nickname = nickname
        self.level = level
        self.experience = experience
        self.dvs = dvs
        self.statExp = statExp
        self.maxHP = maxHP
        self.currentHP = currentHP
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.special = special
        self.attackStage = attackStage
        self.defenseStage = defenseStage
        self.speedStage = speedStage
        self.specialStage = specialStage
        self.accuracyStage = accuracyStage
        self.evasionStage = evasionStage
        self.majorStatus = majorStatus
        self.statusCounter = statusCounter
        self.moves = moves
    }

    private enum CodingKeys: String, CodingKey {
        case speciesID
        case nickname
        case level
        case experience
        case dvs
        case statExp
        case maxHP
        case currentHP
        case attack
        case defense
        case speed
        case special
        case attackStage
        case defenseStage
        case speedStage
        case specialStage
        case accuracyStage
        case evasionStage
        case majorStatus
        case statusCounter
        case moves
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        speciesID = try container.decode(String.self, forKey: .speciesID)
        nickname = try container.decode(String.self, forKey: .nickname)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decode(Int.self, forKey: .experience, default: 0)
        dvs = try container.decode(PokemonDVs.self, forKey: .dvs, default: .zero)
        statExp = try container.decode(PokemonStatExp.self, forKey: .statExp, default: .zero)
        maxHP = try container.decode(Int.self, forKey: .maxHP)
        currentHP = try container.decode(Int.self, forKey: .currentHP)
        attack = try container.decode(Int.self, forKey: .attack)
        defense = try container.decode(Int.self, forKey: .defense)
        speed = try container.decode(Int.self, forKey: .speed)
        special = try container.decode(Int.self, forKey: .special)
        attackStage = try container.decode(Int.self, forKey: .attackStage)
        defenseStage = try container.decode(Int.self, forKey: .defenseStage)
        speedStage = try container.decode(Int.self, forKey: .speedStage, default: 0)
        specialStage = try container.decode(Int.self, forKey: .specialStage, default: 0)
        accuracyStage = try container.decode(Int.self, forKey: .accuracyStage)
        evasionStage = try container.decode(Int.self, forKey: .evasionStage)
        majorStatus = try container.decode(MajorStatusCondition.self, forKey: .majorStatus, default: .none)
        statusCounter = try container.decode(Int.self, forKey: .statusCounter, default: 0)
        moves = try container.decode([GameSaveMove].self, forKey: .moves)
    }
}
