import Foundation

public struct WildEncounterSlotManifest: Codable, Equatable, Sendable {
    public let speciesID: String
    public let level: Int

    public init(speciesID: String, level: Int) {
        self.speciesID = speciesID
        self.level = level
    }
}

public enum WildEncounterSurface: String, Codable, Equatable, Sendable {
    case grass
    case floor
}

public struct WildEncounterSuppressionZoneManifest: Codable, Equatable, Sendable {
    public let id: String
    public let conditions: [ScriptConditionManifest]
    public let positions: [TilePoint]

    public init(
        id: String,
        conditions: [ScriptConditionManifest],
        positions: [TilePoint]
    ) {
        self.id = id
        self.conditions = conditions
        self.positions = positions
    }
}

public struct WildEncounterTableManifest: Codable, Equatable, Sendable {
    public let mapID: String
    public let landEncounterSurface: WildEncounterSurface
    public let grassEncounterRate: Int
    public let waterEncounterRate: Int
    public let grassSlots: [WildEncounterSlotManifest]
    public let waterSlots: [WildEncounterSlotManifest]
    public let suppressionZones: [WildEncounterSuppressionZoneManifest]

    public init(
        mapID: String,
        landEncounterSurface: WildEncounterSurface = .grass,
        grassEncounterRate: Int,
        waterEncounterRate: Int,
        grassSlots: [WildEncounterSlotManifest],
        waterSlots: [WildEncounterSlotManifest],
        suppressionZones: [WildEncounterSuppressionZoneManifest] = []
    ) {
        self.mapID = mapID
        self.landEncounterSurface = landEncounterSurface
        self.grassEncounterRate = grassEncounterRate
        self.waterEncounterRate = waterEncounterRate
        self.grassSlots = grassSlots
        self.waterSlots = waterSlots
        self.suppressionZones = suppressionZones
    }

    private enum CodingKeys: String, CodingKey {
        case mapID
        case landEncounterSurface
        case grassEncounterRate
        case waterEncounterRate
        case grassSlots
        case waterSlots
        case suppressionZones
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mapID = try container.decode(String.self, forKey: .mapID)
        landEncounterSurface = try container.decodeIfPresent(WildEncounterSurface.self, forKey: .landEncounterSurface) ?? .grass
        grassEncounterRate = try container.decode(Int.self, forKey: .grassEncounterRate)
        waterEncounterRate = try container.decode(Int.self, forKey: .waterEncounterRate)
        grassSlots = try container.decode([WildEncounterSlotManifest].self, forKey: .grassSlots)
        waterSlots = try container.decode([WildEncounterSlotManifest].self, forKey: .waterSlots)
        suppressionZones = try container.decodeIfPresent([WildEncounterSuppressionZoneManifest].self, forKey: .suppressionZones) ?? []
    }
}
