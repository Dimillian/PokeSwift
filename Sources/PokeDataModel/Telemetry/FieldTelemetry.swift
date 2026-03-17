import Foundation

public enum FieldRenderMode: String, Codable, Equatable, Sendable {
    case realAssets
    case placeholder
}

public struct FieldTelemetry: Codable, Equatable, Sendable {
    public let mapID: String
    public let mapName: String
    public let playerPosition: TilePoint
    public let facing: FacingDirection
    public let objects: [FieldObjectTelemetry]
    public let activeMapScriptTriggerID: String?
    public let activeScriptID: String?
    public let activeScriptStep: Int?
    public let renderMode: FieldRenderMode
    public let alert: FieldAlertTelemetry?
    public let transition: FieldTransitionTelemetry?

    public init(
        mapID: String,
        mapName: String,
        playerPosition: TilePoint,
        facing: FacingDirection,
        objects: [FieldObjectTelemetry] = [],
        activeMapScriptTriggerID: String?,
        activeScriptID: String?,
        activeScriptStep: Int?,
        renderMode: FieldRenderMode,
        alert: FieldAlertTelemetry? = nil,
        transition: FieldTransitionTelemetry? = nil
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.playerPosition = playerPosition
        self.facing = facing
        self.objects = objects
        self.activeMapScriptTriggerID = activeMapScriptTriggerID
        self.activeScriptID = activeScriptID
        self.activeScriptStep = activeScriptStep
        self.renderMode = renderMode
        self.alert = alert
        self.transition = transition
    }
}

public struct FieldObjectTelemetry: Codable, Equatable, Sendable {
    public let id: String
    public let position: TilePoint
    public let facing: FacingDirection
    public let movementMode: ActorMovementMode?

    public init(
        id: String,
        position: TilePoint,
        facing: FacingDirection,
        movementMode: ActorMovementMode? = nil
    ) {
        self.id = id
        self.position = position
        self.facing = facing
        self.movementMode = movementMode
    }
}

public enum FieldTransitionKind: String, Codable, Equatable, Sendable {
    case door
    case warp
}

public enum FieldTransitionPhase: String, Codable, Equatable, Sendable {
    case fadingOut
    case fadingIn
    case steppingOut
}

public struct FieldTransitionTelemetry: Codable, Equatable, Sendable {
    public let kind: FieldTransitionKind
    public let phase: FieldTransitionPhase

    public init(kind: FieldTransitionKind, phase: FieldTransitionPhase) {
        self.kind = kind
        self.phase = phase
    }
}

public enum FieldAlertBubbleKind: String, Codable, Equatable, Sendable {
    case exclamation
}

public struct FieldAlertTelemetry: Codable, Equatable, Sendable {
    public let objectID: String
    public let kind: FieldAlertBubbleKind

    public init(objectID: String, kind: FieldAlertBubbleKind) {
        self.objectID = objectID
        self.kind = kind
    }
}

public struct DialogueTelemetry: Codable, Equatable, Sendable {
    public let dialogueID: String
    public let pageIndex: Int
    public let pageCount: Int
    public let lines: [String]

    public init(dialogueID: String, pageIndex: Int, pageCount: Int, lines: [String]) {
        self.dialogueID = dialogueID
        self.pageIndex = pageIndex
        self.pageCount = pageCount
        self.lines = lines
    }
}

public struct FieldPromptTelemetry: Codable, Equatable, Sendable {
    public let interactionID: String
    public let kind: FieldPromptKind
    public let options: [String]
    public let focusedIndex: Int

    public init(interactionID: String, kind: FieldPromptKind, options: [String], focusedIndex: Int) {
        self.interactionID = interactionID
        self.kind = kind
        self.options = options
        self.focusedIndex = focusedIndex
    }
}

public enum FieldHealingPhase: String, Codable, Equatable, Sendable {
    case priming
    case machineActive
    case healedJingle
}

public struct FieldHealingTelemetry: Codable, Equatable, Sendable {
    public let interactionID: String
    public let phase: FieldHealingPhase
    public let activeBallCount: Int
    public let totalBallCount: Int
    public let pulseStep: Int
    public let nurseObjectID: String?

    public init(
        interactionID: String,
        phase: FieldHealingPhase,
        activeBallCount: Int,
        totalBallCount: Int,
        pulseStep: Int,
        nurseObjectID: String? = nil
    ) {
        self.interactionID = interactionID
        self.phase = phase
        self.activeBallCount = activeBallCount
        self.totalBallCount = totalBallCount
        self.pulseStep = pulseStep
        self.nurseObjectID = nurseObjectID
    }
}

public struct StarterChoiceTelemetry: Codable, Equatable, Sendable {
    public let options: [String]
    public let focusedIndex: Int

    public init(options: [String], focusedIndex: Int) {
        self.options = options
        self.focusedIndex = focusedIndex
    }
}

public struct EventFlagTelemetry: Codable, Equatable, Sendable {
    public let activeFlags: [String]

    public init(activeFlags: [String]) {
        self.activeFlags = activeFlags
    }
}
