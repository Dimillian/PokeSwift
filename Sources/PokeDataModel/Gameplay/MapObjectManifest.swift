import Foundation

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
