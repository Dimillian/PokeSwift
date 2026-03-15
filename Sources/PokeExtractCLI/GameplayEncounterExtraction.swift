import Foundation
import PokeDataModel

func buildWildEncounterTables(
    repoRoot: URL,
    maps: [MapManifest],
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [WildEncounterTableManifest] {
    let mapsByID = Dictionary(uniqueKeysWithValues: maps.map { ($0.id, $0) })

    return try gameplayCoverageMaps.compactMap { definition in
        guard let path = wildEncounterPath(for: definition, repoRoot: repoRoot) else {
            return nil
        }
        guard let map = mapsByID[definition.mapID] else {
            throw ExtractorError.invalidArguments("missing map manifest for wild encounters on \(definition.mapID)")
        }
        return try parseWildEncounterTable(
            repoRoot: repoRoot,
            map: map,
            mapScriptMetadata: mapScriptMetadataByMapID[definition.mapID],
            path: path
        )
    }
}

private func parseWildEncounterTable(
    repoRoot: URL,
    map: MapManifest,
    mapScriptMetadata: MapScriptMetadata?,
    path: String
) throws -> WildEncounterTableManifest {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent(path))
    return WildEncounterTableManifest(
        mapID: map.id,
        landEncounterSurface: landEncounterSurface(for: map),
        grassEncounterRate: try parseEncounterRate(label: "def_grass_wildmons", in: contents),
        waterEncounterRate: try parseEncounterRate(label: "def_water_wildmons", in: contents),
        grassSlots: parseEncounterSlots(from: contents, startMarker: "def_grass_wildmons", endMarker: "end_grass_wildmons"),
        waterSlots: parseEncounterSlots(from: contents, startMarker: "def_water_wildmons", endMarker: "end_water_wildmons"),
        suppressionZones: mapScriptMetadata?.wildEncounterSuppressionZones ?? []
    )
}

private func landEncounterSurface(for map: MapManifest) -> WildEncounterSurface {
    map.tileset == "CAVERN" ? .floor : .grass
}

private func parseEncounterRate(label: String, in contents: String) throws -> Int {
    let pattern = try NSRegularExpression(
        pattern: "\(NSRegularExpression.escapedPattern(for: label))\\s+(\\d+)"
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    guard
        let match = pattern.firstMatch(in: contents, range: nsRange),
        let rateRange = Range(match.range(at: 1), in: contents)
    else {
        throw ExtractorError.invalidArguments("missing encounter rate for \(label)")
    }
    return Int(contents[rateRange]) ?? 0
}

private func parseEncounterSlots(from contents: String, startMarker: String, endMarker: String) -> [WildEncounterSlotManifest] {
    guard let startRange = contents.range(of: startMarker),
          let endRange = contents.range(of: endMarker, range: startRange.upperBound..<contents.endIndex) else {
        return []
    }

    let slice = contents[startRange.upperBound..<endRange.lowerBound]
    return slice
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> WildEncounterSlotManifest? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard let match = line.firstMatch(of: /db\s+(\d+),\s+([A-Z0-9_]+)/) else {
                return nil
            }
            return WildEncounterSlotManifest(
                speciesID: String(match.output.2),
                level: Int(match.output.1) ?? 1
            )
        }
}
