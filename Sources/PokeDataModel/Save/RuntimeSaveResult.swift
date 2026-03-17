import Foundation

public enum RuntimeSaveOperation: String, Codable, Equatable, Sendable {
    case save
    case load
    case `continue`
}

public struct RuntimeSaveResult: Codable, Equatable, Sendable {
    public let operation: RuntimeSaveOperation
    public let succeeded: Bool
    public let message: String?
    public let timestamp: String

    public init(operation: RuntimeSaveOperation, succeeded: Bool, message: String?, timestamp: String) {
        self.operation = operation
        self.succeeded = succeeded
        self.message = message
        self.timestamp = timestamp
    }
}
