import Foundation

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
