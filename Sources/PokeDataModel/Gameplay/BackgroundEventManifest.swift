import Foundation

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
