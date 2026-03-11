import Foundation

public struct GameSaveMetadata: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let variant: GameVariant
    public let playthroughID: String
    public let playerName: String
    public let locationName: String
    public let badgeCount: Int
    public let playTimeSeconds: Int
    public let savedAt: String

    public init(
        schemaVersion: Int,
        variant: GameVariant,
        playthroughID: String,
        playerName: String,
        locationName: String,
        badgeCount: Int,
        playTimeSeconds: Int,
        savedAt: String
    ) {
        self.schemaVersion = schemaVersion
        self.variant = variant
        self.playthroughID = playthroughID
        self.playerName = playerName
        self.locationName = locationName
        self.badgeCount = badgeCount
        self.playTimeSeconds = playTimeSeconds
        self.savedAt = savedAt
    }
}

public struct GameSaveEnvelope: Codable, Equatable, Sendable {
    public let metadata: GameSaveMetadata
    public let snapshot: GameSaveSnapshot

    public init(metadata: GameSaveMetadata, snapshot: GameSaveSnapshot) {
        self.metadata = metadata
        self.snapshot = snapshot
    }
}

public struct GameSaveSnapshot: Codable, Equatable, Sendable {
    public let mapID: String
    public let playerPosition: TilePoint
    public let facing: FacingDirection
    public let objectStates: [String: GameSaveObjectState]
    public let activeFlags: [String]
    public let money: Int
    public let inventory: [GameSaveInventoryItem]
    public let earnedBadgeIDs: [String]
    public let playerName: String
    public let rivalName: String
    public let playerParty: [GameSavePokemon]
    public let chosenStarterSpeciesID: String?
    public let rivalStarterSpeciesID: String?
    public let pendingStarterSpeciesID: String?
    public let activeMapScriptTriggerID: String?
    public let activeScriptID: String?
    public let activeScriptStep: Int?
    public let acquisitionRNGState: UInt64
    public let encounterStepCounter: Int
    public let playTimeSeconds: Int

    public init(
        mapID: String,
        playerPosition: TilePoint,
        facing: FacingDirection,
        objectStates: [String: GameSaveObjectState],
        activeFlags: [String],
        money: Int,
        inventory: [GameSaveInventoryItem],
        earnedBadgeIDs: [String],
        playerName: String,
        rivalName: String,
        playerParty: [GameSavePokemon],
        chosenStarterSpeciesID: String?,
        rivalStarterSpeciesID: String?,
        pendingStarterSpeciesID: String?,
        activeMapScriptTriggerID: String?,
        activeScriptID: String?,
        activeScriptStep: Int?,
        acquisitionRNGState: UInt64,
        encounterStepCounter: Int,
        playTimeSeconds: Int
    ) {
        self.mapID = mapID
        self.playerPosition = playerPosition
        self.facing = facing
        self.objectStates = objectStates
        self.activeFlags = activeFlags
        self.money = money
        self.inventory = inventory
        self.earnedBadgeIDs = earnedBadgeIDs
        self.playerName = playerName
        self.rivalName = rivalName
        self.playerParty = playerParty
        self.chosenStarterSpeciesID = chosenStarterSpeciesID
        self.rivalStarterSpeciesID = rivalStarterSpeciesID
        self.pendingStarterSpeciesID = pendingStarterSpeciesID
        self.activeMapScriptTriggerID = activeMapScriptTriggerID
        self.activeScriptID = activeScriptID
        self.activeScriptStep = activeScriptStep
        self.acquisitionRNGState = acquisitionRNGState
        self.encounterStepCounter = encounterStepCounter
        self.playTimeSeconds = playTimeSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case playerPosition
        case facing
        case objectStates
        case activeFlags
        case money
        case inventory
        case earnedBadgeIDs
        case playerName
        case rivalName
        case playerParty
        case chosenStarterSpeciesID
        case rivalStarterSpeciesID
        case pendingStarterSpeciesID
        case activeMapScriptTriggerID
        case activeScriptID
        case activeScriptStep
        case acquisitionRNGState
        case encounterStepCounter
        case playTimeSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        playerPosition = try container.decode(TilePoint.self, forKey: .playerPosition)
        facing = try container.decode(FacingDirection.self, forKey: .facing)
        objectStates = try container.decode([String: GameSaveObjectState].self, forKey: .objectStates)
        activeFlags = try container.decode([String].self, forKey: .activeFlags)
        money = try container.decode(Int.self, forKey: .money)
        inventory = try container.decodeIfPresent([GameSaveInventoryItem].self, forKey: .inventory) ?? []
        earnedBadgeIDs = try container.decode([String].self, forKey: .earnedBadgeIDs)
        playerName = try container.decode(String.self, forKey: .playerName)
        rivalName = try container.decode(String.self, forKey: .rivalName)
        playerParty = try container.decode([GameSavePokemon].self, forKey: .playerParty)
        chosenStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .chosenStarterSpeciesID)
        rivalStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .rivalStarterSpeciesID)
        pendingStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .pendingStarterSpeciesID)
        activeMapScriptTriggerID = try container.decodeIfPresent(String.self, forKey: .activeMapScriptTriggerID)
        activeScriptID = try container.decodeIfPresent(String.self, forKey: .activeScriptID)
        activeScriptStep = try container.decodeIfPresent(Int.self, forKey: .activeScriptStep)
        acquisitionRNGState = try container.decodeIfPresent(UInt64.self, forKey: .acquisitionRNGState) ?? 0
        encounterStepCounter = try container.decodeIfPresent(Int.self, forKey: .encounterStepCounter) ?? 0
        playTimeSeconds = try container.decode(Int.self, forKey: .playTimeSeconds)
    }
}

public struct GameSaveInventoryItem: Codable, Equatable, Sendable {
    public let itemID: String
    public let quantity: Int

    public init(itemID: String, quantity: Int) {
        self.itemID = itemID
        self.quantity = quantity
    }
}

public struct GameSaveObjectState: Codable, Equatable, Sendable {
    public let position: TilePoint
    public let facing: FacingDirection
    public let visible: Bool

    public init(position: TilePoint, facing: FacingDirection, visible: Bool) {
        self.position = position
        self.facing = facing
        self.visible = visible
    }
}

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
    public let accuracyStage: Int
    public let evasionStage: Int
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
        accuracyStage: Int,
        evasionStage: Int,
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
        self.accuracyStage = accuracyStage
        self.evasionStage = evasionStage
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
        case accuracyStage
        case evasionStage
        case moves
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        speciesID = try container.decode(String.self, forKey: .speciesID)
        nickname = try container.decode(String.self, forKey: .nickname)
        level = try container.decode(Int.self, forKey: .level)
        experience = try container.decodeIfPresent(Int.self, forKey: .experience) ?? 0
        dvs = try container.decodeIfPresent(PokemonDVs.self, forKey: .dvs) ?? .zero
        statExp = try container.decodeIfPresent(PokemonStatExp.self, forKey: .statExp) ?? .zero
        maxHP = try container.decode(Int.self, forKey: .maxHP)
        currentHP = try container.decode(Int.self, forKey: .currentHP)
        attack = try container.decode(Int.self, forKey: .attack)
        defense = try container.decode(Int.self, forKey: .defense)
        speed = try container.decode(Int.self, forKey: .speed)
        special = try container.decode(Int.self, forKey: .special)
        attackStage = try container.decode(Int.self, forKey: .attackStage)
        defenseStage = try container.decode(Int.self, forKey: .defenseStage)
        accuracyStage = try container.decode(Int.self, forKey: .accuracyStage)
        evasionStage = try container.decode(Int.self, forKey: .evasionStage)
        moves = try container.decode([GameSaveMove].self, forKey: .moves)
    }
}

public struct TitleMenuEntryState: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let isEnabled: Bool
    public let detail: String?

    public init(id: String, label: String, isEnabled: Bool, detail: String? = nil) {
        self.id = id
        self.label = label
        self.isEnabled = isEnabled
        self.detail = detail
    }
}

public struct RuntimeSaveResult: Codable, Equatable, Sendable {
    public let operation: String
    public let succeeded: Bool
    public let message: String?
    public let timestamp: String

    public init(operation: String, succeeded: Bool, message: String?, timestamp: String) {
        self.operation = operation
        self.succeeded = succeeded
        self.message = message
        self.timestamp = timestamp
    }
}
