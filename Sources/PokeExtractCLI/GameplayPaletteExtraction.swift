import Foundation
import PokeDataModel

func buildFieldPalettes(repoRoot: URL) throws -> [FieldPaletteManifest] {
    let paletteIDs = try parseFieldPaletteIDs(repoRoot: repoRoot)
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/sgb/sgb_palettes.asm"), encoding: .utf8)
    let regex = try NSRegularExpression(
        pattern: #"RGB\s+(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*;\s*([A-Z0-9_]+)"#
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    let matches = regex.matches(in: contents, range: nsRange)
    var colorsByPaletteID: [String: [FieldPaletteColorManifest]] = [:]

    for match in matches {
        guard let paletteIDRange = Range(match.range(at: 13), in: contents) else {
            continue
        }
        let paletteID = String(contents[paletteIDRange])
        if colorsByPaletteID[paletteID] != nil {
            continue
        }

        let colorComponents = try (1...12).map { componentIndex -> Int in
            guard let range = Range(match.range(at: componentIndex), in: contents),
                  let value = Int(contents[range]) else {
                throw ExtractorError.invalidArguments("invalid RGB component for palette \(paletteID)")
            }
            return value
        }
        colorsByPaletteID[paletteID] = stride(from: 0, to: colorComponents.count, by: 3).map { startIndex in
            FieldPaletteColorManifest(
                red: colorComponents[startIndex],
                green: colorComponents[startIndex + 1],
                blue: colorComponents[startIndex + 2]
            )
        }
    }

    return try paletteIDs.map { paletteID in
        guard let colors = colorsByPaletteID[paletteID] else {
            throw ExtractorError.invalidArguments("missing RGB definition for palette \(paletteID)")
        }
        return FieldPaletteManifest(id: paletteID, colors: colors)
    }
}

func parseFieldPaletteRules(repoRoot: URL) throws -> ParsedFieldPaletteRules {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/map_constants.asm"), encoding: .utf8)
    var mapIndexByID: [String: Int] = [:]
    var indoorGroupIDByMapID: [String: String] = [:]
    var currentIndex = 0
    var numCityMaps: Int?
    var parsingIndoorGroups = false
    var pendingIndoorGroupMapIDs: [String] = []

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if line.isEmpty {
            continue
        }
        if line == "DEF NUM_CITY_MAPS EQU const_value" {
            numCityMaps = currentIndex
            continue
        }
        if line == "DEF FIRST_INDOOR_MAP EQU const_value" {
            parsingIndoorGroups = true
            continue
        }
        guard let match = line.firstMatch(of: /map_const\s+([A-Z0-9_]+)/) else {
            if parsingIndoorGroups,
               let indoorGroupMatch = line.firstMatch(of: /end_indoor_group\s+([A-Z0-9_]+)/) {
                let indoorGroupID = String(indoorGroupMatch.output.1)
                for mapID in pendingIndoorGroupMapIDs {
                    indoorGroupIDByMapID[mapID] = indoorGroupID
                }
                pendingIndoorGroupMapIDs.removeAll(keepingCapacity: true)
            }
            continue
        }
        let mapID = String(match.output.1)
        mapIndexByID[mapID] = currentIndex
        if parsingIndoorGroups {
            pendingIndoorGroupMapIDs.append(mapID)
        }
        currentIndex += 1
    }

    guard let numCityMaps else {
        throw ExtractorError.invalidArguments("missing NUM_CITY_MAPS in map constants")
    }

    return ParsedFieldPaletteRules(
        paletteIDsInOrder: try parseFieldPaletteIDs(repoRoot: repoRoot),
        mapIndexByID: mapIndexByID,
        numCityMaps: numCityMaps,
        indoorGroupIDByMapID: indoorGroupIDByMapID
    )
}

func resolveFieldPaletteID(
    for draft: MapManifestDraft,
    draftsByID: [String: MapManifestDraft],
    rules: ParsedFieldPaletteRules
) throws -> String {
    switch draft.id {
    case "LORELEIS_ROOM":
        return "PAL_ROUTE"
    case "BRUNOS_ROOM":
        return "PAL_CAVE"
    default:
        break
    }

    switch draft.tileset {
    case "CAVERN":
        return "PAL_CAVE"
    case "CEMETERY":
        return "PAL_GRAYMON"
    default:
        break
    }

    let sourceMapID = try resolveFieldPaletteSourceMapID(
        for: draft,
        draftsByID: draftsByID,
        rules: rules
    )
    guard let mapIndex = rules.mapIndexByID[sourceMapID] else {
        throw ExtractorError.invalidArguments("missing map constant for field palette source \(sourceMapID)")
    }

    if mapIndex < rules.numCityMaps {
        let paletteIndex = mapIndex + 1
        guard rules.paletteIDsInOrder.indices.contains(paletteIndex) else {
            throw ExtractorError.invalidArguments("missing field palette for city map \(sourceMapID)")
        }
        return rules.paletteIDsInOrder[paletteIndex]
    }

    return "PAL_ROUTE"
}

func parseBattlePaletteIDs(repoRoot: URL) throws -> [String: String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/palettes.asm"), encoding: .utf8)
    var paletteIDBySpeciesID: [String: String] = [:]

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard let match = line.firstMatch(of: /db\s+([A-Z0-9_]+)\s*;\s*([A-Z0-9_]+)/) else {
            continue
        }
        paletteIDBySpeciesID[String(match.output.2)] = String(match.output.1)
    }

    return paletteIDBySpeciesID
}

private func resolveFieldPaletteSourceMapID(
    for draft: MapManifestDraft,
    draftsByID: [String: MapManifestDraft],
    rules: ParsedFieldPaletteRules,
    visited: Set<String> = []
) throws -> String {
    guard visited.contains(draft.id) == false else {
        throw ExtractorError.invalidArguments("field palette parent cycle detected for \(draft.id)")
    }
    if draft.isOutdoor {
        return draft.id
    }
    if let parentMapID = draft.parentMapID {
        guard let parentDraft = draftsByID[parentMapID] else {
            return parentMapID
        }
        var nextVisited = visited
        nextVisited.insert(draft.id)
        return try resolveFieldPaletteSourceMapID(
            for: parentDraft,
            draftsByID: draftsByID,
            rules: rules,
            visited: nextVisited
        )
    }
    if let indoorGroupID = rules.indoorGroupIDByMapID[draft.id],
       let normalizedGroupSourceMapID = normalizeIndoorGroupSourceMapID(
           indoorGroupID,
           mapIndexByID: rules.mapIndexByID
       ) {
        return normalizedGroupSourceMapID
    }
    throw ExtractorError.invalidArguments("missing field palette parent for indoor map \(draft.id)")
}

private func parseFieldPaletteIDs(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/palette_constants.asm"), encoding: .utf8)
    var paletteIDs: [String] = []
    var inSGBPaletteSection = false

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmedRawLine = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmedRawLine == "; sgb palettes" {
            inSGBPaletteSection = true
            continue
        }
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        guard inSGBPaletteSection else {
            continue
        }
        if line.hasPrefix("DEF NUM_SGB_PALS") {
            break
        }
        guard let match = line.firstMatch(of: /const\s+([A-Z0-9_]+)/) else {
            continue
        }
        paletteIDs.append(String(match.output.1))
    }

    guard paletteIDs.isEmpty == false else {
        throw ExtractorError.invalidArguments("missing field palette constants")
    }
    return paletteIDs
}

private func normalizeIndoorGroupSourceMapID(
    _ indoorGroupID: String,
    mapIndexByID: [String: Int]
) -> String? {
    if mapIndexByID[indoorGroupID] != nil {
        return indoorGroupID
    }

    var candidate = indoorGroupID
    while let range = candidate.range(of: #"_\d+$"#, options: .regularExpression) {
        candidate.removeSubrange(range)
        if mapIndexByID[candidate] != nil {
            return candidate
        }
    }

    return nil
}
