import Foundation

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
