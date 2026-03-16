import Foundation

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
