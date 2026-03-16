import Foundation

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
