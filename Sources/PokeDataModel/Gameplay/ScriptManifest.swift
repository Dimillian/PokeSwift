import Foundation

public struct ScriptManifest: Codable, Equatable, Sendable {
    public let id: String
    public let steps: [ScriptStep]

    public init(id: String, steps: [ScriptStep]) {
        self.id = id
        self.steps = steps
    }
}
