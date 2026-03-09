import Foundation

public enum FacingDirection: String, Codable, Equatable, Sendable, CaseIterable {
    case up
    case down
    case left
    case right
}

public struct TilePoint: Codable, Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct TileSize: Codable, Equatable, Hashable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct WarpManifest: Codable, Equatable, Sendable {
    public let id: String
    public let origin: TilePoint
    public let targetMapID: String
    public let targetPosition: TilePoint
    public let targetFacing: FacingDirection

    public init(id: String, origin: TilePoint, targetMapID: String, targetPosition: TilePoint, targetFacing: FacingDirection) {
        self.id = id
        self.origin = origin
        self.targetMapID = targetMapID
        self.targetPosition = targetPosition
        self.targetFacing = targetFacing
    }
}

public struct BackgroundEventManifest: Codable, Equatable, Sendable {
    public let id: String
    public let position: TilePoint
    public let dialogueID: String

    public init(id: String, position: TilePoint, dialogueID: String) {
        self.id = id
        self.position = position
        self.dialogueID = dialogueID
    }
}

public struct MapObjectManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let interactionDialogueID: String?
    public let movementType: String
    public let trainerBattleID: String?
    public let visibleByDefault: Bool

    public init(
        id: String,
        displayName: String,
        sprite: String,
        position: TilePoint,
        facing: FacingDirection,
        interactionDialogueID: String?,
        movementType: String,
        trainerBattleID: String?,
        visibleByDefault: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.sprite = sprite
        self.position = position
        self.facing = facing
        self.interactionDialogueID = interactionDialogueID
        self.movementType = movementType
        self.trainerBattleID = trainerBattleID
        self.visibleByDefault = visibleByDefault
    }
}

public struct TriggerRegionManifest: Codable, Equatable, Sendable {
    public let id: String
    public let origin: TilePoint
    public let size: TileSize
    public let scriptID: String

    public init(id: String, origin: TilePoint, size: TileSize, scriptID: String) {
        self.id = id
        self.origin = origin
        self.size = size
        self.scriptID = scriptID
    }

    public func contains(point: TilePoint) -> Bool {
        let xRange = origin.x..<(origin.x + size.width)
        let yRange = origin.y..<(origin.y + size.height)
        return xRange.contains(point.x) && yRange.contains(point.y)
    }
}

public struct MapManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let blockWidth: Int
    public let blockHeight: Int
    public let tileWidth: Int
    public let tileHeight: Int
    public let tileset: String
    public let collisionBlockIDs: [Int]
    public let blockIDs: [Int]
    public let warps: [WarpManifest]
    public let backgroundEvents: [BackgroundEventManifest]
    public let objects: [MapObjectManifest]
    public let triggerRegions: [TriggerRegionManifest]

    public init(
        id: String,
        displayName: String,
        blockWidth: Int,
        blockHeight: Int,
        tileWidth: Int,
        tileHeight: Int,
        tileset: String,
        collisionBlockIDs: [Int],
        blockIDs: [Int],
        warps: [WarpManifest],
        backgroundEvents: [BackgroundEventManifest],
        objects: [MapObjectManifest],
        triggerRegions: [TriggerRegionManifest]
    ) {
        self.id = id
        self.displayName = displayName
        self.blockWidth = blockWidth
        self.blockHeight = blockHeight
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.tileset = tileset
        self.collisionBlockIDs = collisionBlockIDs
        self.blockIDs = blockIDs
        self.warps = warps
        self.backgroundEvents = backgroundEvents
        self.objects = objects
        self.triggerRegions = triggerRegions
    }
}

public struct DialoguePage: Codable, Equatable, Sendable {
    public let lines: [String]
    public let waitsForPrompt: Bool

    public init(lines: [String], waitsForPrompt: Bool) {
        self.lines = lines
        self.waitsForPrompt = waitsForPrompt
    }
}

public struct DialogueManifest: Codable, Equatable, Sendable {
    public let id: String
    public let pages: [DialoguePage]

    public init(id: String, pages: [DialoguePage]) {
        self.id = id
        self.pages = pages
    }
}

public struct EventFlagDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let sourceConstant: String

    public init(id: String, sourceConstant: String) {
        self.id = id
        self.sourceConstant = sourceConstant
    }
}

public struct EventFlagManifest: Codable, Equatable, Sendable {
    public let flags: [EventFlagDefinition]

    public init(flags: [EventFlagDefinition]) {
        self.flags = flags
    }
}

public struct ScriptStep: Codable, Equatable, Sendable {
    public let action: String
    public let stringValue: String?
    public let secondaryStringValue: String?
    public let point: TilePoint?
    public let path: [FacingDirection]
    public let flagID: String?
    public let objectID: String?
    public let dialogueID: String?
    public let battleID: String?
    public let visible: Bool?

    public init(
        action: String,
        stringValue: String? = nil,
        secondaryStringValue: String? = nil,
        point: TilePoint? = nil,
        path: [FacingDirection] = [],
        flagID: String? = nil,
        objectID: String? = nil,
        dialogueID: String? = nil,
        battleID: String? = nil,
        visible: Bool? = nil
    ) {
        self.action = action
        self.stringValue = stringValue
        self.secondaryStringValue = secondaryStringValue
        self.point = point
        self.path = path
        self.flagID = flagID
        self.objectID = objectID
        self.dialogueID = dialogueID
        self.battleID = battleID
        self.visible = visible
    }
}

public struct ScriptManifest: Codable, Equatable, Sendable {
    public let id: String
    public let steps: [ScriptStep]

    public init(id: String, steps: [ScriptStep]) {
        self.id = id
        self.steps = steps
    }
}

public struct MoveManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let power: Int
    public let accuracy: Int
    public let maxPP: Int
    public let effect: String
    public let type: String

    public init(id: String, displayName: String, power: Int, accuracy: Int, maxPP: Int, effect: String, type: String) {
        self.id = id
        self.displayName = displayName
        self.power = power
        self.accuracy = accuracy
        self.maxPP = maxPP
        self.effect = effect
        self.type = type
    }
}

public struct SpeciesManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let baseHP: Int
    public let baseAttack: Int
    public let baseDefense: Int
    public let baseSpeed: Int
    public let baseSpecial: Int
    public let startingMoves: [String]

    public init(
        id: String,
        displayName: String,
        baseHP: Int,
        baseAttack: Int,
        baseDefense: Int,
        baseSpeed: Int,
        baseSpecial: Int,
        startingMoves: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.baseHP = baseHP
        self.baseAttack = baseAttack
        self.baseDefense = baseDefense
        self.baseSpeed = baseSpeed
        self.baseSpecial = baseSpecial
        self.startingMoves = startingMoves
    }
}

public struct TrainerBattleManifest: Codable, Equatable, Sendable {
    public let id: String
    public let trainerClass: String
    public let trainerNumber: Int
    public let displayName: String
    public let enemySpeciesID: String
    public let enemyLevel: Int
    public let winDialogueID: String
    public let loseDialogueID: String
    public let healsPartyAfterBattle: Bool
    public let preventsBlackoutOnLoss: Bool
    public let completionFlagID: String

    public init(
        id: String,
        trainerClass: String,
        trainerNumber: Int,
        displayName: String,
        enemySpeciesID: String,
        enemyLevel: Int,
        winDialogueID: String,
        loseDialogueID: String,
        healsPartyAfterBattle: Bool,
        preventsBlackoutOnLoss: Bool,
        completionFlagID: String
    ) {
        self.id = id
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.displayName = displayName
        self.enemySpeciesID = enemySpeciesID
        self.enemyLevel = enemyLevel
        self.winDialogueID = winDialogueID
        self.loseDialogueID = loseDialogueID
        self.healsPartyAfterBattle = healsPartyAfterBattle
        self.preventsBlackoutOnLoss = preventsBlackoutOnLoss
        self.completionFlagID = completionFlagID
    }
}

public struct PlayerStartManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let playerName: String
    public let rivalName: String
    public let initialFlags: [String]

    public init(mapID: String, position: TilePoint, facing: FacingDirection, playerName: String, rivalName: String, initialFlags: [String]) {
        self.mapID = mapID
        self.position = position
        self.facing = facing
        self.playerName = playerName
        self.rivalName = rivalName
        self.initialFlags = initialFlags
    }
}

public struct GameplayManifest: Codable, Equatable, Sendable {
    public let maps: [MapManifest]
    public let dialogues: [DialogueManifest]
    public let eventFlags: EventFlagManifest
    public let scripts: [ScriptManifest]
    public let species: [SpeciesManifest]
    public let moves: [MoveManifest]
    public let trainerBattles: [TrainerBattleManifest]
    public let playerStart: PlayerStartManifest

    public init(
        maps: [MapManifest],
        dialogues: [DialogueManifest],
        eventFlags: EventFlagManifest,
        scripts: [ScriptManifest],
        species: [SpeciesManifest],
        moves: [MoveManifest],
        trainerBattles: [TrainerBattleManifest],
        playerStart: PlayerStartManifest
    ) {
        self.maps = maps
        self.dialogues = dialogues
        self.eventFlags = eventFlags
        self.scripts = scripts
        self.species = species
        self.moves = moves
        self.trainerBattles = trainerBattles
        self.playerStart = playerStart
    }
}
