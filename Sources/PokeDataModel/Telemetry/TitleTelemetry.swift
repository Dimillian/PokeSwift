import Foundation

public struct TitleMenuEntryState: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let isEnabled: Bool
    public let detail: String?

    public init(id: String, label: String, isEnabled: Bool, detail: String? = nil) {
        self.id = id
        self.label = label
        self.isEnabled = isEnabled
        self.detail = detail
    }
}

public struct TitleMenuTelemetry: Codable, Equatable, Sendable {
    public let entries: [TitleMenuEntryState]
    public let focusedIndex: Int

    public init(entries: [TitleMenuEntryState], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }
}
