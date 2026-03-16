import Foundation

public struct MartManifest: Codable, Equatable, Sendable {
    public let id: String
    public let mapID: String
    public let clerkObjectID: String
    public let stockItemIDs: [String]

    public init(
        id: String,
        mapID: String,
        clerkObjectID: String,
        stockItemIDs: [String]
    ) {
        self.id = id
        self.mapID = mapID
        self.clerkObjectID = clerkObjectID
        self.stockItemIDs = stockItemIDs
    }
}
