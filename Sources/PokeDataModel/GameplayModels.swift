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
    public let targetWarpIndex: Int?
    public let usesPreviousMapTarget: Bool

    public init(
        id: String,
        origin: TilePoint,
        targetMapID: String,
        targetPosition: TilePoint,
        targetFacing: FacingDirection,
        targetWarpIndex: Int? = nil,
        usesPreviousMapTarget: Bool = false
    ) {
        self.id = id
        self.origin = origin
        self.targetMapID = targetMapID
        self.targetPosition = targetPosition
        self.targetFacing = targetFacing
        self.targetWarpIndex = targetWarpIndex
        self.usesPreviousMapTarget = usesPreviousMapTarget
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case origin
        case targetMapID
        case targetPosition
        case targetFacing
        case targetWarpIndex
        case usesPreviousMapTarget
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        origin = try container.decode(TilePoint.self, forKey: .origin)
        targetMapID = try container.decode(String.self, forKey: .targetMapID)
        targetPosition = try container.decode(TilePoint.self, forKey: .targetPosition)
        targetFacing = try container.decode(FacingDirection.self, forKey: .targetFacing)
        targetWarpIndex = try container.decodeIfPresent(Int.self, forKey: .targetWarpIndex)
        usesPreviousMapTarget = try container.decodeIfPresent(Bool.self, forKey: .usesPreviousMapTarget) ?? false
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

public enum ObjectIdleMovementMode: String, Codable, Equatable, Sendable {
    case stay
    case walk
}

public enum ActorMovementMode: String, Codable, Equatable, Sendable {
    case idle
    case scripted
}

public struct FieldRenderableObjectState: Codable, Equatable, Sendable {
    public let id: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let movementMode: ActorMovementMode?

    public init(
        id: String,
        sprite: String,
        position: TilePoint,
        facing: FacingDirection,
        movementMode: ActorMovementMode? = nil
    ) {
        self.id = id
        self.sprite = sprite
        self.position = position
        self.facing = facing
        self.movementMode = movementMode
    }
}

public enum ObjectMovementAxis: String, Codable, Equatable, Sendable {
    case none
    case any
    case upDown
    case leftRight

    public var allowedDirections: [FacingDirection] {
        switch self {
        case .none:
            return []
        case .any:
            return FacingDirection.allCases
        case .upDown:
            return [.up, .down]
        case .leftRight:
            return [.left, .right]
        }
    }
}

public struct ObjectMovementBehavior: Codable, Equatable, Sendable {
    public let idleMode: ObjectIdleMovementMode
    public let axis: ObjectMovementAxis
    public let home: TilePoint
    public let maxDistanceFromHome: Int

    public init(
        idleMode: ObjectIdleMovementMode,
        axis: ObjectMovementAxis,
        home: TilePoint,
        maxDistanceFromHome: Int = 1
    ) {
        self.idleMode = idleMode
        self.axis = axis
        self.home = home
        self.maxDistanceFromHome = maxDistanceFromHome
    }
}

public enum ObjectInteractionReach: String, Codable, Equatable, Sendable {
    case adjacent
    case overCounter
}

public struct ObjectInteractionTriggerManifest: Codable, Equatable, Sendable {
    public let conditions: [ScriptConditionManifest]
    public let dialogueID: String?
    public let scriptID: String?
    public let martID: String?

    public init(
        conditions: [ScriptConditionManifest] = [],
        dialogueID: String? = nil,
        scriptID: String? = nil,
        martID: String? = nil
    ) {
        self.conditions = conditions
        self.dialogueID = dialogueID
        self.scriptID = scriptID
        self.martID = martID
    }
}

public struct MapObjectManifest: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let sprite: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let interactionReach: ObjectInteractionReach
    public let interactionTriggers: [ObjectInteractionTriggerManifest]
    public let interactionDialogueID: String?
    public let interactionScriptID: String?
    public let movementBehavior: ObjectMovementBehavior
    public let trainerBattleID: String?
    public let trainerClass: String?
    public let trainerNumber: Int?
    public let trainerEngageDistance: Int?
    public let trainerIntroDialogueID: String?
    public let trainerEndBattleDialogueID: String?
    public let trainerAfterBattleDialogueID: String?
    public let pickupItemID: String?
    public let visibleByDefault: Bool

    public init(
        id: String,
        displayName: String,
        sprite: String,
        position: TilePoint,
        facing: FacingDirection,
        interactionReach: ObjectInteractionReach = .adjacent,
        interactionTriggers: [ObjectInteractionTriggerManifest] = [],
        interactionDialogueID: String?,
        interactionScriptID: String? = nil,
        movementBehavior: ObjectMovementBehavior,
        trainerBattleID: String?,
        trainerClass: String? = nil,
        trainerNumber: Int? = nil,
        trainerEngageDistance: Int? = nil,
        trainerIntroDialogueID: String? = nil,
        trainerEndBattleDialogueID: String? = nil,
        trainerAfterBattleDialogueID: String? = nil,
        pickupItemID: String? = nil,
        visibleByDefault: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.sprite = sprite
        self.position = position
        self.facing = facing
        self.interactionReach = interactionReach
        self.interactionTriggers = interactionTriggers
        self.interactionDialogueID = interactionDialogueID
        self.interactionScriptID = interactionScriptID
        self.movementBehavior = movementBehavior
        self.trainerBattleID = trainerBattleID
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.trainerEngageDistance = trainerEngageDistance
        self.trainerIntroDialogueID = trainerIntroDialogueID
        self.trainerEndBattleDialogueID = trainerEndBattleDialogueID
        self.trainerAfterBattleDialogueID = trainerAfterBattleDialogueID
        self.pickupItemID = pickupItemID
        self.visibleByDefault = visibleByDefault
    }

    public var movementType: String {
        switch movementBehavior.idleMode {
        case .stay:
            return "STAY"
        case .walk:
            return "WALK"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case sprite
        case position
        case facing
        case interactionReach
        case interactionTriggers
        case interactionDialogueID
        case interactionScriptID
        case movementBehavior
        case movementType
        case trainerBattleID
        case trainerClass
        case trainerNumber
        case trainerEngageDistance
        case trainerIntroDialogueID
        case trainerEndBattleDialogueID
        case trainerAfterBattleDialogueID
        case pickupItemID
        case visibleByDefault
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        sprite = try container.decode(String.self, forKey: .sprite)
        position = try container.decode(TilePoint.self, forKey: .position)
        facing = try container.decode(FacingDirection.self, forKey: .facing)
        interactionReach = try container.decodeIfPresent(ObjectInteractionReach.self, forKey: .interactionReach) ?? .adjacent
        interactionTriggers = try container.decodeIfPresent([ObjectInteractionTriggerManifest].self, forKey: .interactionTriggers) ?? []
        interactionDialogueID = try container.decodeIfPresent(String.self, forKey: .interactionDialogueID)
        interactionScriptID = try container.decodeIfPresent(String.self, forKey: .interactionScriptID)
        if let movementBehavior = try container.decodeIfPresent(ObjectMovementBehavior.self, forKey: .movementBehavior) {
            self.movementBehavior = movementBehavior
        } else {
            let legacyMovementType = try container.decodeIfPresent(String.self, forKey: .movementType) ?? "STAY"
            self.movementBehavior = Self.legacyMovementBehavior(
                movementType: legacyMovementType,
                facing: facing,
                home: position
            )
        }
        trainerBattleID = try container.decodeIfPresent(String.self, forKey: .trainerBattleID)
        trainerClass = try container.decodeIfPresent(String.self, forKey: .trainerClass)
        trainerNumber = try container.decodeIfPresent(Int.self, forKey: .trainerNumber)
        trainerEngageDistance = try container.decodeIfPresent(Int.self, forKey: .trainerEngageDistance)
        trainerIntroDialogueID = try container.decodeIfPresent(String.self, forKey: .trainerIntroDialogueID)
        trainerEndBattleDialogueID = try container.decodeIfPresent(String.self, forKey: .trainerEndBattleDialogueID)
        trainerAfterBattleDialogueID = try container.decodeIfPresent(String.self, forKey: .trainerAfterBattleDialogueID)
        pickupItemID = try container.decodeIfPresent(String.self, forKey: .pickupItemID)
        visibleByDefault = try container.decode(Bool.self, forKey: .visibleByDefault)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(sprite, forKey: .sprite)
        try container.encode(position, forKey: .position)
        try container.encode(facing, forKey: .facing)
        try container.encode(interactionReach, forKey: .interactionReach)
        try container.encode(interactionTriggers, forKey: .interactionTriggers)
        try container.encodeIfPresent(interactionDialogueID, forKey: .interactionDialogueID)
        try container.encodeIfPresent(interactionScriptID, forKey: .interactionScriptID)
        try container.encode(movementBehavior, forKey: .movementBehavior)
        try container.encodeIfPresent(trainerBattleID, forKey: .trainerBattleID)
        try container.encodeIfPresent(trainerClass, forKey: .trainerClass)
        try container.encodeIfPresent(trainerNumber, forKey: .trainerNumber)
        try container.encodeIfPresent(trainerEngageDistance, forKey: .trainerEngageDistance)
        try container.encodeIfPresent(trainerIntroDialogueID, forKey: .trainerIntroDialogueID)
        try container.encodeIfPresent(trainerEndBattleDialogueID, forKey: .trainerEndBattleDialogueID)
        try container.encodeIfPresent(trainerAfterBattleDialogueID, forKey: .trainerAfterBattleDialogueID)
        try container.encodeIfPresent(pickupItemID, forKey: .pickupItemID)
        try container.encode(visibleByDefault, forKey: .visibleByDefault)
    }

    private static func legacyMovementBehavior(
        movementType: String,
        facing: FacingDirection,
        home: TilePoint
    ) -> ObjectMovementBehavior {
        switch movementType {
        case "WALK":
            return .init(idleMode: .walk, axis: .any, home: home)
        case "UP_DOWN":
            return .init(idleMode: .walk, axis: .upDown, home: home)
        case "LEFT_RIGHT":
            return .init(idleMode: .walk, axis: .leftRight, home: home)
        case "NONE":
            return .init(idleMode: .stay, axis: .none, home: home, maxDistanceFromHome: 0)
        case "UP", "DOWN":
            return .init(idleMode: .stay, axis: .none, home: home, maxDistanceFromHome: 0)
        case "ANY_DIR":
            return .init(idleMode: .walk, axis: .any, home: home)
        default:
            let axis: ObjectMovementAxis
            switch facing {
            case .up, .down:
                axis = .upDown
            case .left, .right:
                axis = .leftRight
            }
            return .init(idleMode: .stay, axis: axis, home: home, maxDistanceFromHome: 0)
        }
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
    public let grassTileID: Int?
    public let tilePairCollisions: [TilePairCollisionManifest]
    public let ledges: [LedgeCollisionManifest]

    public init(
        passableTileIDs: [Int],
        warpTileIDs: [Int],
        doorTileIDs: [Int],
        grassTileID: Int? = nil,
        tilePairCollisions: [TilePairCollisionManifest],
        ledges: [LedgeCollisionManifest]
    ) {
        self.passableTileIDs = passableTileIDs
        self.warpTileIDs = warpTileIDs
        self.doorTileIDs = doorTileIDs
        self.grassTileID = grassTileID
        self.tilePairCollisions = tilePairCollisions
        self.ledges = ledges
    }
}

public enum MapConnectionDirection: String, Codable, Equatable, Sendable, CaseIterable {
    case north
    case south
    case west
    case east
}

public struct MapConnectionManifest: Codable, Equatable, Sendable {
    public let direction: MapConnectionDirection
    public let targetMapID: String
    public let offset: Int
    public let targetBlockWidth: Int
    public let targetBlockHeight: Int
    public let targetBlockIDs: [Int]

    public init(
        direction: MapConnectionDirection,
        targetMapID: String,
        offset: Int,
        targetBlockWidth: Int,
        targetBlockHeight: Int,
        targetBlockIDs: [Int]
    ) {
        self.direction = direction
        self.targetMapID = targetMapID
        self.offset = offset
        self.targetBlockWidth = targetBlockWidth
        self.targetBlockHeight = targetBlockHeight
        self.targetBlockIDs = targetBlockIDs
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
    public let connections: [MapConnectionManifest]

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
        objects: [MapObjectManifest],
        connections: [MapConnectionManifest] = []
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
        self.connections = connections
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
    public let walkingFrames: FacingFrameManifest?

    public init(
        id: String,
        imagePath: String,
        frameWidth: Int,
        frameHeight: Int,
        facingFrames: FacingFrameManifest,
        walkingFrames: FacingFrameManifest? = nil
    ) {
        self.id = id
        self.imagePath = imagePath
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.facingFrames = facingFrames
        self.walkingFrames = walkingFrames
    }
}

public struct DialoguePage: Codable, Equatable, Sendable {
    public let lines: [String]
    public let waitsForPrompt: Bool
    public let events: [DialogueEvent]

    public init(lines: [String], waitsForPrompt: Bool, events: [DialogueEvent] = []) {
        self.lines = lines
        self.waitsForPrompt = waitsForPrompt
        self.events = events
    }

    private enum CodingKeys: String, CodingKey {
        case lines
        case waitsForPrompt
        case events
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lines = try container.decode([String].self, forKey: .lines)
        waitsForPrompt = try container.decode(Bool.self, forKey: .waitsForPrompt)
        events = try container.decodeIfPresent([DialogueEvent].self, forKey: .events) ?? []
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

public enum DialogueEventKind: String, Codable, Equatable, Sendable {
    case soundEffect
    case cry
}

public struct DialogueEvent: Codable, Equatable, Sendable {
    public let kind: DialogueEventKind
    public let soundEffectID: String?
    public let speciesID: String?
    public let waitForCompletion: Bool

    public init(
        kind: DialogueEventKind,
        soundEffectID: String? = nil,
        speciesID: String? = nil,
        waitForCompletion: Bool = true
    ) {
        self.kind = kind
        self.soundEffectID = soundEffectID
        self.speciesID = speciesID
        self.waitForCompletion = waitForCompletion
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
    public let intValue: Int?
    public let badgeID: String?
    public let point: TilePoint?
    public let path: [FacingDirection]
    public let movement: ScriptMovementManifest?
    public let flagID: String?
    public let objectID: String?
    public let dialogueID: String?
    public let successDialogueID: String?
    public let failureDialogueID: String?
    public let successFlagID: String?
    public let fieldInteractionID: String?
    public let battleID: String?
    public let trainerClass: String?
    public let trainerNumber: Int?
    public let visible: Bool?

    public init(
        action: String,
        stringValue: String? = nil,
        secondaryStringValue: String? = nil,
        intValue: Int? = nil,
        badgeID: String? = nil,
        point: TilePoint? = nil,
        path: [FacingDirection] = [],
        movement: ScriptMovementManifest? = nil,
        flagID: String? = nil,
        objectID: String? = nil,
        dialogueID: String? = nil,
        successDialogueID: String? = nil,
        failureDialogueID: String? = nil,
        successFlagID: String? = nil,
        fieldInteractionID: String? = nil,
        battleID: String? = nil,
        trainerClass: String? = nil,
        trainerNumber: Int? = nil,
        visible: Bool? = nil
    ) {
        self.action = action
        self.stringValue = stringValue
        self.secondaryStringValue = secondaryStringValue
        self.intValue = intValue
        self.badgeID = badgeID
        self.point = point
        self.path = path
        self.movement = movement
        self.flagID = flagID
        self.objectID = objectID
        self.dialogueID = dialogueID
        self.successDialogueID = successDialogueID
        self.failureDialogueID = failureDialogueID
        self.successFlagID = successFlagID
        self.fieldInteractionID = fieldInteractionID
        self.battleID = battleID
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.visible = visible
    }
}

public enum FieldInteractionKind: String, Codable, Equatable, Sendable {
    case pokemonCenterHealing
    case paidAdmission
}

public enum FieldPromptKind: String, Codable, Equatable, Sendable {
    case yesNo
}

public struct FieldPromptManifest: Codable, Equatable, Sendable {
    public let kind: FieldPromptKind
    public let dialogueID: String

    public init(kind: FieldPromptKind, dialogueID: String) {
        self.kind = kind
        self.dialogueID = dialogueID
    }
}

public struct FieldHealingSequenceManifest: Codable, Equatable, Sendable {
    public let nurseObjectID: String?
    public let machineSoundEffectID: String
    public let healedAudioCueID: String
    public let blackoutCheckpoint: BlackoutCheckpointManifest?

    public init(
        nurseObjectID: String? = nil,
        machineSoundEffectID: String,
        healedAudioCueID: String,
        blackoutCheckpoint: BlackoutCheckpointManifest? = nil
    ) {
        self.nurseObjectID = nurseObjectID
        self.machineSoundEffectID = machineSoundEffectID
        self.healedAudioCueID = healedAudioCueID
        self.blackoutCheckpoint = blackoutCheckpoint
    }
}

public struct FieldPaidAdmissionManifest: Codable, Equatable, Sendable {
    public let price: Int
    public let successFlagID: String
    public let insufficientFundsDialogueID: String
    public let purchaseSoundEffectID: String?
    public let deniedExitPath: [FacingDirection]

    public init(
        price: Int,
        successFlagID: String,
        insufficientFundsDialogueID: String,
        purchaseSoundEffectID: String? = nil,
        deniedExitPath: [FacingDirection] = []
    ) {
        self.price = price
        self.successFlagID = successFlagID
        self.insufficientFundsDialogueID = insufficientFundsDialogueID
        self.purchaseSoundEffectID = purchaseSoundEffectID
        self.deniedExitPath = deniedExitPath
    }
}

public struct FieldInteractionManifest: Codable, Equatable, Sendable {
    public let id: String
    public let kind: FieldInteractionKind
    public let introDialogueID: String
    public let prompt: FieldPromptManifest
    public let acceptedDialogueID: String
    public let successDialogueID: String
    public let declinedDialogueID: String?
    public let farewellDialogueID: String
    public let healingSequence: FieldHealingSequenceManifest?
    public let paidAdmission: FieldPaidAdmissionManifest?

    public init(
        id: String,
        kind: FieldInteractionKind,
        introDialogueID: String,
        prompt: FieldPromptManifest,
        acceptedDialogueID: String,
        successDialogueID: String,
        declinedDialogueID: String? = nil,
        farewellDialogueID: String,
        healingSequence: FieldHealingSequenceManifest? = nil,
        paidAdmission: FieldPaidAdmissionManifest? = nil
    ) {
        self.id = id
        self.kind = kind
        self.introDialogueID = introDialogueID
        self.prompt = prompt
        self.acceptedDialogueID = acceptedDialogueID
        self.successDialogueID = successDialogueID
        self.declinedDialogueID = declinedDialogueID
        self.farewellDialogueID = farewellDialogueID
        self.healingSequence = healingSequence
        self.paidAdmission = paidAdmission
    }
}

public enum ScriptMovementKind: String, Codable, Equatable, Sendable {
    case fixedPath
    case pathToPlayerAdjacent
    case pathToObjectOffset
    case palletEscort
    case rivalStarterPickup
}

public struct ScriptMovementActor: Codable, Equatable, Sendable {
    public let actorID: String
    public let path: [FacingDirection]

    public init(actorID: String, path: [FacingDirection]) {
        self.actorID = actorID
        self.path = path
    }
}

public struct ScriptMovementVariant: Codable, Equatable, Sendable {
    public let id: String
    public let conditions: [ScriptConditionManifest]
    public let actors: [ScriptMovementActor]
    public let point: TilePoint?

    public init(
        id: String,
        conditions: [ScriptConditionManifest],
        actors: [ScriptMovementActor],
        point: TilePoint? = nil
    ) {
        self.id = id
        self.conditions = conditions
        self.actors = actors
        self.point = point
    }
}

public struct ScriptMovementManifest: Codable, Equatable, Sendable {
    public let kind: ScriptMovementKind
    public let actors: [ScriptMovementActor]
    public let targetPlayerOffset: TilePoint?
    public let targetObjectID: String?
    public let targetObjectOffset: TilePoint?
    public let variants: [ScriptMovementVariant]

    public init(
        kind: ScriptMovementKind,
        actors: [ScriptMovementActor] = [],
        targetPlayerOffset: TilePoint? = nil,
        targetObjectID: String? = nil,
        targetObjectOffset: TilePoint? = nil,
        variants: [ScriptMovementVariant] = []
    ) {
        self.kind = kind
        self.actors = actors
        self.targetPlayerOffset = targetPlayerOffset
        self.targetObjectID = targetObjectID
        self.targetObjectOffset = targetObjectOffset
        self.variants = variants
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
    public let battleAudio: BattleAudioManifest?

    public init(
        id: String,
        displayName: String,
        power: Int,
        accuracy: Int,
        maxPP: Int,
        effect: String,
        type: String,
        battleAudio: BattleAudioManifest? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.power = power
        self.accuracy = accuracy
        self.maxPP = maxPP
        self.effect = effect
        self.type = type
        self.battleAudio = battleAudio
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case power
        case accuracy
        case maxPP
        case effect
        case type
        case battleAudio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        power = try container.decode(Int.self, forKey: .power)
        accuracy = try container.decode(Int.self, forKey: .accuracy)
        maxPP = try container.decode(Int.self, forKey: .maxPP)
        effect = try container.decode(String.self, forKey: .effect)
        type = try container.decode(String.self, forKey: .type)
        battleAudio = try container.decodeIfPresent(BattleAudioManifest.self, forKey: .battleAudio)
    }
}

public enum BattleAudioKind: String, Codable, Equatable, Sendable {
    case soundEffect
    case cry
}

public struct BattleAudioManifest: Codable, Equatable, Sendable {
    public let kind: BattleAudioKind
    public let soundEffectID: String?
    public let frequencyModifier: Int?
    public let tempoModifier: Int?

    public init(
        kind: BattleAudioKind,
        soundEffectID: String? = nil,
        frequencyModifier: Int? = nil,
        tempoModifier: Int? = nil
    ) {
        self.kind = kind
        self.soundEffectID = soundEffectID
        self.frequencyModifier = frequencyModifier
        self.tempoModifier = tempoModifier
    }
}

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

public struct BattleTextTemplateManifest: Codable, Equatable, Sendable {
    public let wantsToFight: String
    public let enemyFainted: String
    public let playerFainted: String
    public let playerBlackedOut: String
    public let trainerDefeated: String
    public let moneyForWinning: String
    public let trainerAboutToUse: String
    public let trainerSentOut: String
    public let playerSendOutGo: String
    public let playerSendOutDoIt: String
    public let playerSendOutGetm: String
    public let playerSendOutEnemyWeak: String

    public init(
        wantsToFight: String,
        enemyFainted: String,
        playerFainted: String,
        playerBlackedOut: String,
        trainerDefeated: String,
        moneyForWinning: String,
        trainerAboutToUse: String,
        trainerSentOut: String,
        playerSendOutGo: String,
        playerSendOutDoIt: String,
        playerSendOutGetm: String,
        playerSendOutEnemyWeak: String
    ) {
        self.wantsToFight = wantsToFight
        self.enemyFainted = enemyFainted
        self.playerFainted = playerFainted
        self.playerBlackedOut = playerBlackedOut
        self.trainerDefeated = trainerDefeated
        self.moneyForWinning = moneyForWinning
        self.trainerAboutToUse = trainerAboutToUse
        self.trainerSentOut = trainerSentOut
        self.playerSendOutGo = playerSendOutGo
        self.playerSendOutDoIt = playerSendOutDoIt
        self.playerSendOutGetm = playerSendOutGetm
        self.playerSendOutEnemyWeak = playerSendOutEnemyWeak
    }

    private enum CodingKeys: String, CodingKey {
        case wantsToFight
        case enemyFainted
        case playerFainted
        case playerBlackedOut
        case trainerDefeated
        case moneyForWinning
        case trainerAboutToUse
        case trainerSentOut
        case playerSendOutGo
        case playerSendOutDoIt
        case playerSendOutGetm
        case playerSendOutEnemyWeak
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wantsToFight = try container.decode(String.self, forKey: .wantsToFight)
        enemyFainted = try container.decode(String.self, forKey: .enemyFainted)
        playerFainted = try container.decode(String.self, forKey: .playerFainted)
        playerBlackedOut = try container.decodeIfPresent(String.self, forKey: .playerBlackedOut)
            ?? "{playerName} is out of useable POKéMON! {playerName} blacked out!"
        trainerDefeated = try container.decode(String.self, forKey: .trainerDefeated)
        moneyForWinning = try container.decode(String.self, forKey: .moneyForWinning)
        trainerAboutToUse = try container.decode(String.self, forKey: .trainerAboutToUse)
        trainerSentOut = try container.decode(String.self, forKey: .trainerSentOut)
        playerSendOutGo = try container.decode(String.self, forKey: .playerSendOutGo)
        playerSendOutDoIt = try container.decode(String.self, forKey: .playerSendOutDoIt)
        playerSendOutGetm = try container.decode(String.self, forKey: .playerSendOutGetm)
        playerSendOutEnemyWeak = try container.decode(String.self, forKey: .playerSendOutEnemyWeak)
    }
}

public struct BlackoutCheckpointManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let position: TilePoint
    public let facing: FacingDirection

    public init(mapID: String, position: TilePoint, facing: FacingDirection) {
        self.mapID = mapID
        self.position = position
        self.facing = facing
    }
}

public struct ItemManifest: Codable, Equatable, Sendable {
    public enum BattleUseKind: String, Codable, Equatable, Sendable {
        case none
        case ball
    }

    public let id: String
    public let displayName: String
    public let price: Int
    public let isKeyItem: Bool
    public let battleUse: BattleUseKind

    public init(
        id: String,
        displayName: String,
        price: Int = 0,
        isKeyItem: Bool = false,
        battleUse: BattleUseKind = .none
    ) {
        self.id = id
        self.displayName = displayName
        self.price = price
        self.isKeyItem = isKeyItem
        self.battleUse = battleUse
    }
}

public struct MartManifest: Codable, Equatable, Sendable {
    public let id: String
    public let mapID: String
    public let clerkObjectID: String
    public let stockItemIDs: [String]

    public init(
        id: String,
        mapID: String,
        clerkObjectID: String,
        stockItemIDs: [String]
    ) {
        self.id = id
        self.mapID = mapID
        self.clerkObjectID = clerkObjectID
        self.stockItemIDs = stockItemIDs
    }
}

public struct WildEncounterSlotManifest: Codable, Equatable, Sendable {
    public let speciesID: String
    public let level: Int

    public init(speciesID: String, level: Int) {
        self.speciesID = speciesID
        self.level = level
    }
}

public enum WildEncounterSurface: String, Codable, Equatable, Sendable {
    case grass
    case floor
}

public struct WildEncounterSuppressionZoneManifest: Codable, Equatable, Sendable {
    public let id: String
    public let conditions: [ScriptConditionManifest]
    public let positions: [TilePoint]

    public init(
        id: String,
        conditions: [ScriptConditionManifest],
        positions: [TilePoint]
    ) {
        self.id = id
        self.conditions = conditions
        self.positions = positions
    }
}

public struct WildEncounterTableManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let landEncounterSurface: WildEncounterSurface
    public let grassEncounterRate: Int
    public let waterEncounterRate: Int
    public let grassSlots: [WildEncounterSlotManifest]
    public let waterSlots: [WildEncounterSlotManifest]
    public let suppressionZones: [WildEncounterSuppressionZoneManifest]

    public init(
        mapID: String,
        landEncounterSurface: WildEncounterSurface = .grass,
        grassEncounterRate: Int,
        waterEncounterRate: Int,
        grassSlots: [WildEncounterSlotManifest],
        waterSlots: [WildEncounterSlotManifest],
        suppressionZones: [WildEncounterSuppressionZoneManifest] = []
    ) {
        self.mapID = mapID
        self.landEncounterSurface = landEncounterSurface
        self.grassEncounterRate = grassEncounterRate
        self.waterEncounterRate = waterEncounterRate
        self.grassSlots = grassSlots
        self.waterSlots = waterSlots
        self.suppressionZones = suppressionZones
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case landEncounterSurface
        case grassEncounterRate
        case waterEncounterRate
        case grassSlots
        case waterSlots
        case suppressionZones
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        landEncounterSurface = try container.decodeIfPresent(WildEncounterSurface.self, forKey: .landEncounterSurface) ?? .grass
        grassEncounterRate = try container.decode(Int.self, forKey: .grassEncounterRate)
        waterEncounterRate = try container.decode(Int.self, forKey: .waterEncounterRate)
        grassSlots = try container.decode([WildEncounterSlotManifest].self, forKey: .grassSlots)
        waterSlots = try container.decode([WildEncounterSlotManifest].self, forKey: .waterSlots)
        suppressionZones = try container.decodeIfPresent([WildEncounterSuppressionZoneManifest].self, forKey: .suppressionZones) ?? []
    }
}

public enum BattleKind: String, Codable, Equatable, Sendable {
    case trainer
    case wild
}

public enum MajorStatusCondition: String, Codable, Equatable, Sendable {
    case none
    case sleep
    case poison
    case burn
    case freeze
    case paralysis

    public var captureBonus: Int {
        switch self {
        case .none:
            return 0
        case .poison, .burn, .paralysis:
            return 12
        case .sleep, .freeze:
            return 25
        }
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

public struct TrainerAIMoveChoiceModificationManifest: Codable, Equatable, Sendable {
    public let trainerClass: String
    public let modifications: [Int]

    public init(trainerClass: String, modifications: [Int]) {
        self.trainerClass = trainerClass
        self.modifications = modifications
    }
}

public struct TrainerBattleManifest: Codable, Equatable, Sendable {
    public let id: String
    public let trainerClass: String
    public let trainerNumber: Int
    public let displayName: String
    public let party: [TrainerPokemonManifest]
    public let trainerSpritePath: String?
    public let baseRewardMoney: Int
    public let encounterAudioCueID: String?
    public let playerWinDialogueID: String
    public let playerLoseDialogueID: String?
    public let healsPartyAfterBattle: Bool
    public let preventsBlackoutOnLoss: Bool
    public let completionFlagID: String
    public let postBattleScriptID: String?
    public let runsPostBattleScriptOnLoss: Bool

    public init(
        id: String,
        trainerClass: String,
        trainerNumber: Int,
        displayName: String,
        party: [TrainerPokemonManifest],
        trainerSpritePath: String? = nil,
        baseRewardMoney: Int = 0,
        encounterAudioCueID: String? = nil,
        playerWinDialogueID: String,
        playerLoseDialogueID: String? = nil,
        healsPartyAfterBattle: Bool,
        preventsBlackoutOnLoss: Bool,
        completionFlagID: String,
        postBattleScriptID: String? = nil,
        runsPostBattleScriptOnLoss: Bool = false
    ) {
        self.id = id
        self.trainerClass = trainerClass
        self.trainerNumber = trainerNumber
        self.displayName = displayName
        self.party = party
        self.trainerSpritePath = trainerSpritePath
        self.baseRewardMoney = max(0, baseRewardMoney)
        self.encounterAudioCueID = encounterAudioCueID
        self.playerWinDialogueID = playerWinDialogueID
        self.playerLoseDialogueID = playerLoseDialogueID
        self.healsPartyAfterBattle = healsPartyAfterBattle
        self.preventsBlackoutOnLoss = preventsBlackoutOnLoss
        self.completionFlagID = completionFlagID
        self.postBattleScriptID = postBattleScriptID
        self.runsPostBattleScriptOnLoss = runsPostBattleScriptOnLoss
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case trainerClass
        case trainerNumber
        case displayName
        case party
        case trainerSpritePath
        case baseRewardMoney
        case encounterAudioCueID
        case playerWinDialogueID
        case playerLoseDialogueID
        case healsPartyAfterBattle
        case preventsBlackoutOnLoss
        case completionFlagID
        case postBattleScriptID
        case runsPostBattleScriptOnLoss
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        trainerClass = try container.decode(String.self, forKey: .trainerClass)
        trainerNumber = try container.decode(Int.self, forKey: .trainerNumber)
        displayName = try container.decode(String.self, forKey: .displayName)
        party = try container.decode([TrainerPokemonManifest].self, forKey: .party)
        trainerSpritePath = try container.decodeIfPresent(String.self, forKey: .trainerSpritePath)
        baseRewardMoney = max(0, try container.decodeIfPresent(Int.self, forKey: .baseRewardMoney) ?? 0)
        encounterAudioCueID = try container.decodeIfPresent(String.self, forKey: .encounterAudioCueID)
        playerWinDialogueID = try container.decode(String.self, forKey: .playerWinDialogueID)
        playerLoseDialogueID = try container.decodeIfPresent(String.self, forKey: .playerLoseDialogueID)
        healsPartyAfterBattle = try container.decode(Bool.self, forKey: .healsPartyAfterBattle)
        preventsBlackoutOnLoss = try container.decode(Bool.self, forKey: .preventsBlackoutOnLoss)
        completionFlagID = try container.decode(String.self, forKey: .completionFlagID)
        postBattleScriptID = try container.decodeIfPresent(String.self, forKey: .postBattleScriptID)
        runsPostBattleScriptOnLoss = try container.decodeIfPresent(Bool.self, forKey: .runsPostBattleScriptOnLoss) ?? false
    }
}

public struct PlayerStartManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let playerName: String
    public let rivalName: String
    public let initialFlags: [String]
    public let defaultBlackoutCheckpoint: BlackoutCheckpointManifest?

    public init(
        mapID: String,
        position: TilePoint,
        facing: FacingDirection,
        playerName: String,
        rivalName: String,
        initialFlags: [String],
        defaultBlackoutCheckpoint: BlackoutCheckpointManifest? = nil
    ) {
        self.mapID = mapID
        self.position = position
        self.facing = facing
        self.playerName = playerName
        self.rivalName = rivalName
        self.initialFlags = initialFlags
        self.defaultBlackoutCheckpoint = defaultBlackoutCheckpoint
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case position
        case facing
        case playerName
        case rivalName
        case initialFlags
        case defaultBlackoutCheckpoint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        position = try container.decode(TilePoint.self, forKey: .position)
        facing = try container.decode(FacingDirection.self, forKey: .facing)
        playerName = try container.decode(String.self, forKey: .playerName)
        rivalName = try container.decode(String.self, forKey: .rivalName)
        initialFlags = try container.decode([String].self, forKey: .initialFlags)
        defaultBlackoutCheckpoint = try container.decodeIfPresent(
            BlackoutCheckpointManifest.self,
            forKey: .defaultBlackoutCheckpoint
        )
    }
}

public struct GameplayManifest: Codable, Equatable, Sendable {
    public let maps: [MapManifest]
    public let tilesets: [TilesetManifest]
    public let overworldSprites: [OverworldSpriteManifest]
    public let dialogues: [DialogueManifest]
    public let fieldInteractions: [FieldInteractionManifest]
    public let eventFlags: EventFlagManifest
    public let mapScripts: [MapScriptManifest]
    public let scripts: [ScriptManifest]
    public let items: [ItemManifest]
    public let marts: [MartManifest]
    public let species: [SpeciesManifest]
    public let moves: [MoveManifest]
    public let typeEffectiveness: [TypeEffectivenessManifest]
    public let wildEncounterTables: [WildEncounterTableManifest]
    public let trainerAIMoveChoiceModifications: [TrainerAIMoveChoiceModificationManifest]
    public let trainerBattles: [TrainerBattleManifest]
    public let commonBattleText: BattleTextTemplateManifest
    public let playerStart: PlayerStartManifest

    public init(
        maps: [MapManifest],
        tilesets: [TilesetManifest],
        overworldSprites: [OverworldSpriteManifest],
        dialogues: [DialogueManifest],
        fieldInteractions: [FieldInteractionManifest] = [],
        eventFlags: EventFlagManifest,
        mapScripts: [MapScriptManifest],
        scripts: [ScriptManifest],
        items: [ItemManifest] = [],
        marts: [MartManifest] = [],
        species: [SpeciesManifest],
        moves: [MoveManifest],
        typeEffectiveness: [TypeEffectivenessManifest] = [],
        wildEncounterTables: [WildEncounterTableManifest] = [],
        trainerAIMoveChoiceModifications: [TrainerAIMoveChoiceModificationManifest] = [],
        trainerBattles: [TrainerBattleManifest],
        commonBattleText: BattleTextTemplateManifest = .init(
            wantsToFight: "{trainerName} wants to fight!",
            enemyFainted: "Enemy {enemyPokemon} fainted!",
            playerFainted: "{playerPokemon} fainted!",
            playerBlackedOut: "{playerName} is out of useable POKéMON! {playerName} blacked out!",
            trainerDefeated: "{playerName} defeated {trainerName}!",
            moneyForWinning: "{playerName} got ¥{money} for winning!",
            trainerAboutToUse: "{trainerName} is about to use {enemyPokemon}! Will {playerName} change #MON?",
            trainerSentOut: "{trainerName} sent out {enemyPokemon}!",
            playerSendOutGo: "Go! {playerPokemon}!",
            playerSendOutDoIt: "Do it! {playerPokemon}!",
            playerSendOutGetm: "Get'm! {playerPokemon}!",
            playerSendOutEnemyWeak: "The enemy's weak! Get'm! {playerPokemon}!"
        ),
        playerStart: PlayerStartManifest
    ) {
        self.maps = maps
        self.tilesets = tilesets
        self.overworldSprites = overworldSprites
        self.dialogues = dialogues
        self.fieldInteractions = fieldInteractions
        self.eventFlags = eventFlags
        self.mapScripts = mapScripts
        self.scripts = scripts
        self.items = items
        self.marts = marts
        self.species = species
        self.moves = moves
        self.typeEffectiveness = typeEffectiveness
        self.wildEncounterTables = wildEncounterTables
        self.trainerAIMoveChoiceModifications = trainerAIMoveChoiceModifications
        self.trainerBattles = trainerBattles
        self.commonBattleText = commonBattleText
        self.playerStart = playerStart
    }

    private enum CodingKeys: String, CodingKey {
        case maps
        case tilesets
        case overworldSprites
        case dialogues
        case fieldInteractions
        case eventFlags
        case mapScripts
        case scripts
        case items
        case marts
        case species
        case moves
        case typeEffectiveness
        case wildEncounterTables
        case trainerAIMoveChoiceModifications
        case trainerBattles
        case commonBattleText
        case playerStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maps = try container.decode([MapManifest].self, forKey: .maps)
        tilesets = try container.decode([TilesetManifest].self, forKey: .tilesets)
        overworldSprites = try container.decode([OverworldSpriteManifest].self, forKey: .overworldSprites)
        dialogues = try container.decode([DialogueManifest].self, forKey: .dialogues)
        fieldInteractions = try container.decodeIfPresent([FieldInteractionManifest].self, forKey: .fieldInteractions) ?? []
        eventFlags = try container.decode(EventFlagManifest.self, forKey: .eventFlags)
        mapScripts = try container.decode([MapScriptManifest].self, forKey: .mapScripts)
        scripts = try container.decode([ScriptManifest].self, forKey: .scripts)
        items = try container.decodeIfPresent([ItemManifest].self, forKey: .items) ?? []
        marts = try container.decodeIfPresent([MartManifest].self, forKey: .marts) ?? []
        species = try container.decode([SpeciesManifest].self, forKey: .species)
        moves = try container.decode([MoveManifest].self, forKey: .moves)
        typeEffectiveness = try container.decodeIfPresent([TypeEffectivenessManifest].self, forKey: .typeEffectiveness) ?? []
        wildEncounterTables = try container.decodeIfPresent([WildEncounterTableManifest].self, forKey: .wildEncounterTables) ?? []
        trainerAIMoveChoiceModifications = try container.decodeIfPresent([TrainerAIMoveChoiceModificationManifest].self, forKey: .trainerAIMoveChoiceModifications) ?? []
        trainerBattles = try container.decode([TrainerBattleManifest].self, forKey: .trainerBattles)
        commonBattleText = try container.decodeIfPresent(BattleTextTemplateManifest.self, forKey: .commonBattleText) ?? .init(
            wantsToFight: "{trainerName} wants to fight!",
            enemyFainted: "Enemy {enemyPokemon} fainted!",
            playerFainted: "{playerPokemon} fainted!",
            playerBlackedOut: "{playerName} is out of useable POKéMON! {playerName} blacked out!",
            trainerDefeated: "{playerName} defeated {trainerName}!",
            moneyForWinning: "{playerName} got ¥{money} for winning!",
            trainerAboutToUse: "{trainerName} is about to use {enemyPokemon}! Will {playerName} change #MON?",
            trainerSentOut: "{trainerName} sent out {enemyPokemon}!",
            playerSendOutGo: "Go! {playerPokemon}!",
            playerSendOutDoIt: "Do it! {playerPokemon}!",
            playerSendOutGetm: "Get'm! {playerPokemon}!",
            playerSendOutEnemyWeak: "The enemy's weak! Get'm! {playerPokemon}!"
        )
        playerStart = try container.decode(PlayerStartManifest.self, forKey: .playerStart)
    }
}
