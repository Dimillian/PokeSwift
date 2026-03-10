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

public struct PixelRect: Codable, Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
    public let flippedHorizontally: Bool

    public init(x: Int, y: Int, width: Int, height: Int, flippedHorizontally: Bool = false) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.flippedHorizontally = flippedHorizontally
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
    public let trainerClass: String?
    public let trainerNumber: Int?
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
        trainerClass: String? = nil,
        trainerNumber: Int? = nil,
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
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.visibleByDefault = visibleByDefault
    }
}

public struct TilePairCollisionManifest: Codable, Equatable, Sendable {
    public let fromTileID: Int
    public let toTileID: Int

    public init(fromTileID: Int, toTileID: Int) {
        self.fromTileID = fromTileID
        self.toTileID = toTileID
    }
}

public struct LedgeCollisionManifest: Codable, Equatable, Sendable {
    public let facing: FacingDirection
    public let standingTileID: Int
    public let ledgeTileID: Int

    public init(facing: FacingDirection, standingTileID: Int, ledgeTileID: Int) {
        self.facing = facing
        self.standingTileID = standingTileID
        self.ledgeTileID = ledgeTileID
    }
}

public struct TilesetCollisionManifest: Codable, Equatable, Sendable {
    public let passableTileIDs: [Int]
    public let warpTileIDs: [Int]
    public let doorTileIDs: [Int]
    public let tilePairCollisions: [TilePairCollisionManifest]
    public let ledges: [LedgeCollisionManifest]

    public init(
        passableTileIDs: [Int],
        warpTileIDs: [Int],
        doorTileIDs: [Int],
        tilePairCollisions: [TilePairCollisionManifest],
        ledges: [LedgeCollisionManifest]
    ) {
        self.passableTileIDs = passableTileIDs
        self.warpTileIDs = warpTileIDs
        self.doorTileIDs = doorTileIDs
        self.tilePairCollisions = tilePairCollisions
        self.ledges = ledges
    }
}

public struct MapManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let defaultMusicID: String
    public let borderBlockID: Int
    public let blockWidth: Int
    public let blockHeight: Int
    public let stepWidth: Int
    public let stepHeight: Int
    public let tileset: String
    public let blockIDs: [Int]
    public let stepCollisionTileIDs: [Int]
    public let warps: [WarpManifest]
    public let backgroundEvents: [BackgroundEventManifest]
    public let objects: [MapObjectManifest]

    public init(
        id: String,
        displayName: String,
        defaultMusicID: String,
        borderBlockID: Int,
        blockWidth: Int,
        blockHeight: Int,
        stepWidth: Int,
        stepHeight: Int,
        tileset: String,
        blockIDs: [Int],
        stepCollisionTileIDs: [Int],
        warps: [WarpManifest],
        backgroundEvents: [BackgroundEventManifest],
        objects: [MapObjectManifest]
    ) {
        self.id = id
        self.displayName = displayName
        self.defaultMusicID = defaultMusicID
        self.borderBlockID = borderBlockID
        self.blockWidth = blockWidth
        self.blockHeight = blockHeight
        self.stepWidth = stepWidth
        self.stepHeight = stepHeight
        self.tileset = tileset
        self.blockIDs = blockIDs
        self.stepCollisionTileIDs = stepCollisionTileIDs
        self.warps = warps
        self.backgroundEvents = backgroundEvents
        self.objects = objects
    }
}

public struct TilesetManifest: Codable, Equatable, Sendable {
    public let id: String
    public let imagePath: String
    public let blocksetPath: String
    public let sourceTileSize: Int
    public let blockTileWidth: Int
    public let blockTileHeight: Int
    public let collision: TilesetCollisionManifest

    public init(
        id: String,
        imagePath: String,
        blocksetPath: String,
        sourceTileSize: Int,
        blockTileWidth: Int,
        blockTileHeight: Int,
        collision: TilesetCollisionManifest
    ) {
        self.id = id
        self.imagePath = imagePath
        self.blocksetPath = blocksetPath
        self.sourceTileSize = sourceTileSize
        self.blockTileWidth = blockTileWidth
        self.blockTileHeight = blockTileHeight
        self.collision = collision
    }
}

public struct FacingFrameManifest: Codable, Equatable, Sendable {
    public let down: PixelRect
    public let up: PixelRect
    public let left: PixelRect
    public let right: PixelRect

    public init(down: PixelRect, up: PixelRect, left: PixelRect, right: PixelRect) {
        self.down = down
        self.up = up
        self.left = left
        self.right = right
    }
}

public struct OverworldSpriteManifest: Codable, Equatable, Sendable {
    public let id: String
    public let imagePath: String
    public let frameWidth: Int
    public let frameHeight: Int
    public let facingFrames: FacingFrameManifest

    public init(
        id: String,
        imagePath: String,
        frameWidth: Int,
        frameHeight: Int,
        facingFrames: FacingFrameManifest
    ) {
        self.id = id
        self.imagePath = imagePath
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.facingFrames = facingFrames
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
    public let trainerClass: String?
    public let trainerNumber: Int?
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
        trainerClass: String? = nil,
        trainerNumber: Int? = nil,
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
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
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

public struct ScriptConditionManifest: Codable, Equatable, Sendable {
    public let kind: String
    public let flagID: String?
    public let intValue: Int?
    public let stringValue: String?

    public init(kind: String, flagID: String? = nil, intValue: Int? = nil, stringValue: String? = nil) {
        self.kind = kind
        self.flagID = flagID
        self.intValue = intValue
        self.stringValue = stringValue
    }
}

public struct MapScriptTriggerManifest: Codable, Equatable, Sendable {
    public let id: String
    public let scriptID: String
    public let conditions: [ScriptConditionManifest]

    public init(id: String, scriptID: String, conditions: [ScriptConditionManifest]) {
        self.id = id
        self.scriptID = scriptID
        self.conditions = conditions
    }
}

public struct MapScriptManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let triggers: [MapScriptTriggerManifest]

    public init(mapID: String, triggers: [MapScriptTriggerManifest]) {
        self.mapID = mapID
        self.triggers = triggers
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
    public let primaryType: String
    public let secondaryType: String?
    public let battleSprite: BattleSpriteManifest?
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
        primaryType: String = "NORMAL",
        secondaryType: String? = nil,
        battleSprite: BattleSpriteManifest? = nil,
        baseHP: Int,
        baseAttack: Int,
        baseDefense: Int,
        baseSpeed: Int,
        baseSpecial: Int,
        startingMoves: [String]
    ) {
        self.id = id
        self.displayName = displayName
        self.primaryType = primaryType
        self.secondaryType = secondaryType
        self.battleSprite = battleSprite
        self.baseHP = baseHP
        self.baseAttack = baseAttack
        self.baseDefense = baseDefense
        self.baseSpeed = baseSpeed
        self.baseSpecial = baseSpecial
        self.startingMoves = startingMoves
    }

    private enum CodingKeys: String, CodingKey {
        case primaryType
        case secondaryType
        case battleSprite
        case id
        case displayName
        case baseHP
        case baseAttack
        case baseDefense
        case baseSpeed
        case baseSpecial
        case startingMoves
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        primaryType = try container.decodeIfPresent(String.self, forKey: .primaryType) ?? "NORMAL"
        secondaryType = try container.decodeIfPresent(String.self, forKey: .secondaryType)
        battleSprite = try container.decodeIfPresent(BattleSpriteManifest.self, forKey: .battleSprite)
        baseHP = try container.decode(Int.self, forKey: .baseHP)
        baseAttack = try container.decode(Int.self, forKey: .baseAttack)
        baseDefense = try container.decode(Int.self, forKey: .baseDefense)
        baseSpeed = try container.decode(Int.self, forKey: .baseSpeed)
        baseSpecial = try container.decode(Int.self, forKey: .baseSpecial)
        startingMoves = try container.decode([String].self, forKey: .startingMoves)
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

public struct TypeEffectivenessManifest: Codable, Equatable, Sendable {
    public let attackingType: String
    public let defendingType: String
    public let multiplier: Int

    public init(attackingType: String, defendingType: String, multiplier: Int) {
        self.attackingType = attackingType
        self.defendingType = defendingType
        self.multiplier = multiplier
    }
}

public struct TrainerPokemonManifest: Codable, Equatable, Sendable {
    public let speciesID: String
    public let level: Int

    public init(speciesID: String, level: Int) {
        self.speciesID = speciesID
        self.level = level
    }
}

public struct TrainerBattleManifest: Codable, Equatable, Sendable {
    public let id: String
    public let trainerClass: String
    public let trainerNumber: Int
    public let displayName: String
    public let party: [TrainerPokemonManifest]
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
        party: [TrainerPokemonManifest],
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
        self.party = party
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
    public let tilesets: [TilesetManifest]
    public let overworldSprites: [OverworldSpriteManifest]
    public let dialogues: [DialogueManifest]
    public let eventFlags: EventFlagManifest
    public let mapScripts: [MapScriptManifest]
    public let scripts: [ScriptManifest]
    public let species: [SpeciesManifest]
    public let moves: [MoveManifest]
    public let typeEffectiveness: [TypeEffectivenessManifest]
    public let trainerBattles: [TrainerBattleManifest]
    public let playerStart: PlayerStartManifest

    public init(
        maps: [MapManifest],
        tilesets: [TilesetManifest],
        overworldSprites: [OverworldSpriteManifest],
        dialogues: [DialogueManifest],
        eventFlags: EventFlagManifest,
        mapScripts: [MapScriptManifest],
        scripts: [ScriptManifest],
        species: [SpeciesManifest],
        moves: [MoveManifest],
        typeEffectiveness: [TypeEffectivenessManifest] = [],
        trainerBattles: [TrainerBattleManifest],
        playerStart: PlayerStartManifest
    ) {
        self.maps = maps
        self.tilesets = tilesets
        self.overworldSprites = overworldSprites
        self.dialogues = dialogues
        self.eventFlags = eventFlags
        self.mapScripts = mapScripts
        self.scripts = scripts
        self.species = species
        self.moves = moves
        self.typeEffectiveness = typeEffectiveness
        self.trainerBattles = trainerBattles
        self.playerStart = playerStart
    }

    private enum CodingKeys: String, CodingKey {
        case maps
        case tilesets
        case overworldSprites
        case dialogues
        case eventFlags
        case mapScripts
        case scripts
        case species
        case moves
        case typeEffectiveness
        case trainerBattles
        case playerStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maps = try container.decode([MapManifest].self, forKey: .maps)
        tilesets = try container.decode([TilesetManifest].self, forKey: .tilesets)
        overworldSprites = try container.decode([OverworldSpriteManifest].self, forKey: .overworldSprites)
        dialogues = try container.decode([DialogueManifest].self, forKey: .dialogues)
        eventFlags = try container.decode(EventFlagManifest.self, forKey: .eventFlags)
        mapScripts = try container.decode([MapScriptManifest].self, forKey: .mapScripts)
        scripts = try container.decode([ScriptManifest].self, forKey: .scripts)
        species = try container.decode([SpeciesManifest].self, forKey: .species)
        moves = try container.decode([MoveManifest].self, forKey: .moves)
        typeEffectiveness = try container.decodeIfPresent([TypeEffectivenessManifest].self, forKey: .typeEffectiveness) ?? []
        trainerBattles = try container.decode([TrainerBattleManifest].self, forKey: .trainerBattles)
        playerStart = try container.decode(PlayerStartManifest.self, forKey: .playerStart)
    }
}
