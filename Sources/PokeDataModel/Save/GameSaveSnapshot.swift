import Foundation

public struct GameSaveSnapshot: Codable, Equatable, Sendable {
    public let mapID: String
    public let previousMapID: String?
    public let playerPosition: TilePoint
    public let facing: FacingDirection
    public let blackoutCheckpoint: BlackoutCheckpointManifest?
    public let objectStates: [String: GameSaveObjectState]
    public let activeFlags: [String]
    public let money: Int
    public let inventory: [GameSaveInventoryItem]
    public let currentBoxIndex: Int
    public let boxedPokemon: [GameSavePokemonBox]
    public let ownedSpeciesIDs: [String]
    public let seenSpeciesIDs: [String]
    public let speciesEncounterCounts: [String: Int]
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
    public let encounterStepCounter: Int
    public let totalStepCount: Int
    public let wildEncounterCount: Int
    public let trainerBattleCount: Int
    public let playTimeSeconds: Int

    public init(
        mapID: String,
        previousMapID: String? = nil,
        playerPosition: TilePoint,
        facing: FacingDirection,
        blackoutCheckpoint: BlackoutCheckpointManifest? = nil,
        objectStates: [String: GameSaveObjectState],
        activeFlags: [String],
        money: Int,
        inventory: [GameSaveInventoryItem],
        currentBoxIndex: Int = 0,
        boxedPokemon: [GameSavePokemonBox] = [],
        ownedSpeciesIDs: [String] = [],
        seenSpeciesIDs: [String] = [],
        speciesEncounterCounts: [String: Int] = [:],
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
        encounterStepCounter: Int,
        totalStepCount: Int = 0,
        wildEncounterCount: Int = 0,
        trainerBattleCount: Int = 0,
        playTimeSeconds: Int
    ) {
        self.mapID = mapID
        self.previousMapID = previousMapID
        self.playerPosition = playerPosition
        self.facing = facing
        self.blackoutCheckpoint = blackoutCheckpoint
        self.objectStates = objectStates
        self.activeFlags = activeFlags
        self.money = money
        self.inventory = inventory
        self.currentBoxIndex = currentBoxIndex
        self.boxedPokemon = boxedPokemon
        self.ownedSpeciesIDs = ownedSpeciesIDs
        self.seenSpeciesIDs = seenSpeciesIDs
        self.speciesEncounterCounts = speciesEncounterCounts
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
        self.encounterStepCounter = encounterStepCounter
        self.totalStepCount = totalStepCount
        self.wildEncounterCount = wildEncounterCount
        self.trainerBattleCount = trainerBattleCount
        self.playTimeSeconds = playTimeSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case previousMapID
        case playerPosition
        case facing
        case blackoutCheckpoint
        case objectStates
        case activeFlags
        case money
        case inventory
        case currentBoxIndex
        case boxedPokemon
        case ownedSpeciesIDs
        case seenSpeciesIDs
        case speciesEncounterCounts
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
        case encounterStepCounter
        case totalStepCount
        case wildEncounterCount
        case trainerBattleCount
        case playTimeSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        previousMapID = try container.decodeIfPresent(String.self, forKey: .previousMapID)
        playerPosition = try container.decode(TilePoint.self, forKey: .playerPosition)
        facing = try container.decode(FacingDirection.self, forKey: .facing)
        blackoutCheckpoint = try container.decodeIfPresent(BlackoutCheckpointManifest.self, forKey: .blackoutCheckpoint)
        objectStates = try container.decode([String: GameSaveObjectState].self, forKey: .objectStates)
        activeFlags = try container.decode([String].self, forKey: .activeFlags)
        money = try container.decode(Int.self, forKey: .money)
        inventory = try container.decodeArray([GameSaveInventoryItem].self, forKey: .inventory, default: [])
        currentBoxIndex = try container.decode(Int.self, forKey: .currentBoxIndex, default: 0)
        boxedPokemon = try container.decodeArray([GameSavePokemonBox].self, forKey: .boxedPokemon, default: [])
        earnedBadgeIDs = try container.decode([String].self, forKey: .earnedBadgeIDs)
        playerName = try container.decode(String.self, forKey: .playerName)
        rivalName = try container.decode(String.self, forKey: .rivalName)
        playerParty = try container.decode([GameSavePokemon].self, forKey: .playerParty)
        ownedSpeciesIDs = try container.decodeArray([String].self, forKey: .ownedSpeciesIDs, default: playerParty.map(\.speciesID))
        seenSpeciesIDs = try container.decodeArray([String].self, forKey: .seenSpeciesIDs, default: ownedSpeciesIDs)
        speciesEncounterCounts = try container.decodeDictionary([String: Int].self, forKey: .speciesEncounterCounts, default: [:])
        chosenStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .chosenStarterSpeciesID)
        rivalStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .rivalStarterSpeciesID)
        pendingStarterSpeciesID = try container.decodeIfPresent(String.self, forKey: .pendingStarterSpeciesID)
        activeMapScriptTriggerID = try container.decodeIfPresent(String.self, forKey: .activeMapScriptTriggerID)
        activeScriptID = try container.decodeIfPresent(String.self, forKey: .activeScriptID)
        activeScriptStep = try container.decodeIfPresent(Int.self, forKey: .activeScriptStep)
        encounterStepCounter = try container.decode(Int.self, forKey: .encounterStepCounter, default: 0)
        totalStepCount = try container.decode(Int.self, forKey: .totalStepCount, default: 0)
        wildEncounterCount = try container.decode(Int.self, forKey: .wildEncounterCount, default: 0)
        trainerBattleCount = try container.decode(Int.self, forKey: .trainerBattleCount, default: 0)
        playTimeSeconds = try container.decode(Int.self, forKey: .playTimeSeconds, default: 0)
    }
}

public struct GameSavePokemonBox: Codable, Equatable, Sendable {
    public let index: Int
    public let pokemon: [GameSavePokemon]

    public init(index: Int, pokemon: [GameSavePokemon]) {
        self.index = index
        self.pokemon = pokemon
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
