import Foundation

public struct WarpManifest: Codable, Equatable, Sendable {
    public let id: String
    public let origin: TilePoint
    public let targetMapID: String
    public let targetPosition: TilePoint
    public let targetFacing: FacingDirection
    public let targetWarpIndex: Int?
    public let usesPreviousMapTarget: Bool

    public init(
        id: String,
        origin: TilePoint,
        targetMapID: String,
        targetPosition: TilePoint,
        targetFacing: FacingDirection,
        targetWarpIndex: Int? = nil,
        usesPreviousMapTarget: Bool = false
    ) {
        self.id = id
        self.origin = origin
        self.targetMapID = targetMapID
        self.targetPosition = targetPosition
        self.targetFacing = targetFacing
        self.targetWarpIndex = targetWarpIndex
        self.usesPreviousMapTarget = usesPreviousMapTarget
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case origin
        case targetMapID
        case targetPosition
        case targetFacing
        case targetWarpIndex
        case usesPreviousMapTarget
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        origin = try container.decode(TilePoint.self, forKey: .origin)
        targetMapID = try container.decode(String.self, forKey: .targetMapID)
        targetPosition = try container.decode(TilePoint.self, forKey: .targetPosition)
        targetFacing = try container.decode(FacingDirection.self, forKey: .targetFacing)
        targetWarpIndex = try container.decodeIfPresent(Int.self, forKey: .targetWarpIndex)
        usesPreviousMapTarget = try container.decodeIfPresent(Bool.self, forKey: .usesPreviousMapTarget) ?? false
    }
}
