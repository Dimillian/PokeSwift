import Foundation
import PokeDataModel

func fallbackMapSize(for mapID: String) -> TileSize {
    switch mapID {
    case
        "REDS_HOUSE_2F",
        "REDS_HOUSE_1F",
        "VIRIDIAN_MART",
        "CERULEAN_MART",
        "BIKE_SHOP",
        "CERULEAN_TRADE_HOUSE",
        "CERULEAN_BADGE_HOUSE",
        "CERULEAN_TRASHED_HOUSE":
        return .init(width: 4, height: 4)
    case "PALLET_TOWN":
        return .init(width: 10, height: 9)
    case "ROUTE_1":
        return .init(width: 10, height: 18)
    case "ROUTE_2":
        return .init(width: 10, height: 36)
    case "VIRIDIAN_CITY":
        return .init(width: 20, height: 18)
    case "VIRIDIAN_POKECENTER", "CERULEAN_POKECENTER":
        return .init(width: 7, height: 4)
    case "VIRIDIAN_SCHOOL_HOUSE", "VIRIDIAN_NICKNAME_HOUSE":
        return .init(width: 4, height: 4)
    case "VIRIDIAN_FOREST_SOUTH_GATE", "VIRIDIAN_FOREST_NORTH_GATE":
        return .init(width: 5, height: 4)
    case "VIRIDIAN_FOREST":
        return .init(width: 17, height: 24)
    case "OAKS_LAB":
        return .init(width: 5, height: 6)
    default:
        return .init(width: 4, height: 4)
    }
}

func fallbackMusicID(for mapID: String) -> String {
    switch mapID {
    case "PALLET_TOWN", "REDS_HOUSE_1F", "REDS_HOUSE_2F":
        return "MUSIC_PALLET_TOWN"
    case "ROUTE_1", "ROUTE_2":
        return "MUSIC_ROUTES1"
    case
        "VIRIDIAN_CITY",
        "VIRIDIAN_SCHOOL_HOUSE",
        "VIRIDIAN_NICKNAME_HOUSE",
        "CERULEAN_CITY",
        "CERULEAN_TRADE_HOUSE",
        "CERULEAN_TRASHED_HOUSE":
        return "MUSIC_CITIES1"
    case "VIRIDIAN_POKECENTER", "VIRIDIAN_MART", "CERULEAN_POKECENTER", "CERULEAN_MART":
        return "MUSIC_POKECENTER"
    case "BIKE_SHOP":
        return "MUSIC_CITIES2"
    case "CERULEAN_BADGE_HOUSE":
        return "MUSIC_CITIES1"
    case "VIRIDIAN_FOREST_SOUTH_GATE", "VIRIDIAN_FOREST_NORTH_GATE":
        return "MUSIC_CITIES1"
    case "VIRIDIAN_FOREST":
        return "MUSIC_DUNGEON2"
    case "OAKS_LAB":
        return "MUSIC_OAKS_LAB"
    default:
        return "MUSIC_PALLET_TOWN"
    }
}

func parseMapSizes(repoRoot: URL) throws -> [String: TileSize] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/map_constants.asm"))
    let regex = try NSRegularExpression(pattern: #"map_const\s+([A-Z0-9_]+),\s+(\d+),\s+(\d+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).reduce(into: [:]) { result, match in
        guard
            let idRange = Range(match.range(at: 1), in: contents),
            let widthRange = Range(match.range(at: 2), in: contents),
            let heightRange = Range(match.range(at: 3), in: contents),
            let width = Int(contents[widthRange]),
            let height = Int(contents[heightRange])
        else {
            return
        }
        result[String(contents[idRange])] = TileSize(width: width, height: height)
    }
}

func parseMapHeaders(repoRoot: URL) throws -> [String: ParsedMapHeader] {
    let headersURL = repoRoot.appendingPathComponent("data/maps/headers", isDirectory: true)
    let headerFiles = try FileManager.default.contentsOfDirectory(
        at: headersURL,
        includingPropertiesForKeys: nil
    )
    let connectionRegex = try NSRegularExpression(
        pattern: #"connection\s+(north|south|west|east),\s+([A-Za-z0-9_]+),\s+([A-Z0-9_]+),\s+(-?\d+)"#
    )

    return try headerFiles
        .filter { $0.pathExtension == "asm" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
        .reduce(into: [:]) { result, headerURL in
            let contents = try String(contentsOf: headerURL)
            guard let match = contents.firstMatch(of: /map_header\s+([A-Za-z0-9_]+),\s+([A-Z0-9_]+),\s+([A-Z0-9_]+)/) else {
                return
            }

            let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
            let connections: [RawMapConnection] = connectionRegex.matches(in: contents, range: nsRange).compactMap { match in
                guard
                    let directionRange = Range(match.range(at: 1), in: contents),
                    let targetIDRange = Range(match.range(at: 3), in: contents),
                    let offsetRange = Range(match.range(at: 4), in: contents),
                    let direction = MapConnectionDirection(rawValue: String(contents[directionRange])),
                    let offset = Int(contents[offsetRange])
                else {
                    return nil
                }

                return RawMapConnection(
                    direction: direction,
                    targetMapID: String(contents[targetIDRange]),
                    offset: offset
                )
            }

            let header = ParsedMapHeader(
                symbolName: String(match.output.1),
                id: String(match.output.2),
                tileset: String(match.output.3),
                connections: connections
            )
            result[header.id] = header
        }
}

func parseMapMusic(repoRoot: URL) throws -> [String: String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/maps/songs.asm"))
    let regex = try NSRegularExpression(pattern: #"db\s+(MUSIC_[A-Z0-9_]+),\s+BANK\([A-Za-z0-9_]+\)\s*;\s*([A-Z0-9_]+)"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var result: [String: String] = [:]

    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let musicRange = Range(match.range(at: 1), in: contents),
            let mapRange = Range(match.range(at: 2), in: contents)
        else {
            continue
        }
        result[String(contents[mapRange])] = String(contents[musicRange])
    }

    return result
}

func parseSelectedMapScriptMetadata(repoRoot: URL) throws -> [String: MapScriptMetadata] {
    try gameplayCoverageMaps.reduce(into: [:]) { result, definition in
        let scriptPath = scriptPathForMap(definition)
        let scriptURL = repoRoot.appendingPathComponent(scriptPath)
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            return
        }
        let contents = try String(contentsOf: scriptURL)
        result[definition.mapID] = parseMapScriptMetadata(contents: contents)
    }
}

func parseToggleableObjectDefaultVisibility(repoRoot: URL) throws -> [String: [String: Bool]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/maps/toggleable_objects.asm"))
    var currentMapID: String?
    var visibilityByMapID: [String: [String: Bool]] = [:]

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if let match = line.firstMatch(of: /toggleable_objects_for\s+([A-Z0-9_]+)/) {
            currentMapID = String(match.output.1)
            continue
        }

        guard
            let currentMapID,
            let match = line.firstMatch(of: /toggle_object_state\s+([A-Z0-9_]+),\s+(ON|OFF)/)
        else {
            continue
        }

        visibilityByMapID[currentMapID, default: [:]][String(match.output.1)] = String(match.output.2) == "ON"
    }

    return visibilityByMapID
}

func mapFileStem(for definition: GameplayCoverageMapDefinition) -> String {
    URL(fileURLWithPath: definition.objectFile).deletingPathExtension().lastPathComponent
}

func scriptPathForMap(_ definition: GameplayCoverageMapDefinition) -> String {
    "scripts/\(mapFileStem(for: definition)).asm"
}

func wildEncounterPath(for definition: GameplayCoverageMapDefinition, repoRoot: URL) -> String? {
    let stem = URL(fileURLWithPath: definition.objectFile).deletingPathExtension().lastPathComponent
    let path = "data/wild/maps/\(stem).asm"
    let url = repoRoot.appendingPathComponent(path)
    return FileManager.default.fileExists(atPath: url.path) ? path : nil
}

func parseMapScriptMetadata(contents: String) -> MapScriptMetadata {
    let textLabelByTextID = parseMapTextPointerLabels(contents: contents)
    let pickupTextIDs = Set(textLabelByTextID.compactMap { textID, label in
        label == "PickUpItemText" ? textID : nil
    })
    let farTextLabelByLocalLabel = parseFarTextLabels(contents: contents)
    let referencedFarTextLabels = parseReferencedFarTextLabels(contents: contents)
    let trainerHeadersByLabel = parseStandardTrainerHeaders(contents: contents)
    let trainerHeaderLabelByTextLabel = parseTalkToTrainerBindings(contents: contents)
    let usesStandardTrainerLoop =
        contents.contains("CheckFightingMapTrainers") &&
        contents.contains("DisplayEnemyTrainerTextAndStartBattle") &&
        contents.contains("EndTrainerBattle") &&
        contents.contains("TalkToTrainer")

    return MapScriptMetadata(
        textLabelByTextID: textLabelByTextID,
        pickupTextIDs: pickupTextIDs,
        farTextLabelByLocalLabel: farTextLabelByLocalLabel,
        referencedFarTextLabels: referencedFarTextLabels,
        trainerHeadersByLabel: trainerHeadersByLabel,
        trainerHeaderLabelByTextLabel: trainerHeaderLabelByTextLabel,
        usesStandardTrainerLoop: usesStandardTrainerLoop,
        wildEncounterSuppressionZones: parseWildEncounterSuppressionZones(contents: contents)
    )
}

private func parseWildEncounterSuppressionZones(contents: String) -> [WildEncounterSuppressionZoneManifest] {
    guard
        contents.contains("CheckEvent EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD"),
        contents.contains("set BIT_NO_BATTLES"),
        contents.contains("MtMoonB2FFossilAreaCoords"),
        let positions = parseCoordinateArray(label: "MtMoonB2FFossilAreaCoords", in: contents),
        positions.isEmpty == false
    else {
        return []
    }

    return [
        .init(
            id: "mt_moon_b2f_post_super_nerd_fossil_area",
            conditions: [.init(kind: "flagSet", flagID: "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD")],
            positions: positions
        )
    ]
}

private func parseCoordinateArray(label: String, in contents: String) -> [TilePoint]? {
    guard let labelRange = contents.range(of: "\(label):") else {
        return nil
    }

    var positions: [TilePoint] = []
    let lines = contents[labelRange.upperBound...].split(separator: "\n", omittingEmptySubsequences: false)
    for rawLine in lines {
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if line == "db -1" {
            return positions
        }

        guard let match = line.firstMatch(of: /dbmapcoord\s+(\d+),\s+(\d+)/) else {
            if line.hasSuffix(":") {
                break
            }
            continue
        }

        positions.append(.init(x: Int(match.output.1) ?? 0, y: Int(match.output.2) ?? 0))
    }

    return positions.isEmpty ? nil : positions
}

private func parseMapTextPointerLabels(contents: String) -> [String: String] {
    let regex = try! NSRegularExpression(pattern: #"dw_const\s+([A-Za-z0-9_\.]+),\s+(TEXT_[A-Z0-9_]+)"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsRange).reduce(into: [:]) { result, match in
        guard
            let labelRange = Range(match.range(at: 1), in: contents),
            let textIDRange = Range(match.range(at: 2), in: contents)
        else {
            return
        }
        result[String(contents[textIDRange])] = String(contents[labelRange])
    }
}

private func parseFarTextLabels(contents: String) -> [String: String] {
    var rootLabel: String?
    var result: [String: String] = [:]

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if let labelMatch = line.firstMatch(of: /^([A-Za-z0-9_]+):$/) {
            rootLabel = String(labelMatch.output.1)
            continue
        }

        guard let rootLabel,
              result[rootLabel] == nil,
              let farMatch = line.firstMatch(of: /text_far\s+([A-Za-z0-9_\.]+)/) else {
            continue
        }

        result[rootLabel] = String(farMatch.output.1)
    }

    return result
}

private func parseReferencedFarTextLabels(contents: String) -> Set<String> {
    let regex = try! NSRegularExpression(pattern: #"text_far\s+([A-Za-z0-9_\.]+)"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return Set(regex.matches(in: contents, range: nsRange).compactMap { match in
        guard let farRange = Range(match.range(at: 1), in: contents) else {
            return nil
        }
        return String(contents[farRange])
    })
}

private func parseStandardTrainerHeaders(contents: String) -> [String: StandardTrainerHeaderMetadata] {
    let regex = try! NSRegularExpression(
        pattern: #"(?ms)^\s*([A-Za-z0-9_\.]+):\s*\n\s*trainer\s+([A-Z0-9_]+),\s+(\d+),\s+([A-Za-z0-9_\.]+),\s+([A-Za-z0-9_\.]+),\s+([A-Za-z0-9_\.]+)"#,
        options: [.anchorsMatchLines]
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsRange).reduce(into: [:]) { result, match in
        guard
            let headerRange = Range(match.range(at: 1), in: contents),
            let flagRange = Range(match.range(at: 2), in: contents),
            let distanceRange = Range(match.range(at: 3), in: contents),
            let battleTextRange = Range(match.range(at: 4), in: contents),
            let endBattleTextRange = Range(match.range(at: 5), in: contents),
            let afterBattleTextRange = Range(match.range(at: 6), in: contents),
            let engageDistance = Int(contents[distanceRange])
        else {
            return
        }

        result[String(contents[headerRange])] = StandardTrainerHeaderMetadata(
            defeatFlagID: String(contents[flagRange]),
            engageDistance: engageDistance,
            battleTextLabel: String(contents[battleTextRange]),
            endBattleTextLabel: String(contents[endBattleTextRange]),
            afterBattleTextLabel: String(contents[afterBattleTextRange])
        )
    }
}

private func parseTalkToTrainerBindings(contents: String) -> [String: String] {
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var result: [String: String] = [:]
    var index = 0

    while index < lines.count {
        let trimmedLine = lines[index].trimmingCharacters(in: .whitespaces)
        guard trimmedLine.hasSuffix(":") else {
            index += 1
            continue
        }

        let textLabel = String(trimmedLine.dropLast())
        var probe = index + 1
        while probe < lines.count, lines[probe].trimmingCharacters(in: .whitespaces).isEmpty {
            probe += 1
        }

        guard probe < lines.count, lines[probe].trimmingCharacters(in: .whitespaces) == "text_asm" else {
            index += 1
            continue
        }

        probe += 1
        var headerLabel: String?
        var foundTalkToTrainer = false

        while probe < lines.count {
            let candidate = lines[probe].trimmingCharacters(in: .whitespaces)
            if candidate.hasSuffix(":") {
                break
            }
            if headerLabel == nil,
               let match = candidate.firstMatch(of: /^ld hl,\s*([A-Za-z0-9_\.]+)$/) {
                headerLabel = String(match.output.1)
            }
            if candidate == "call TalkToTrainer" {
                foundTalkToTrainer = true
                break
            }
            probe += 1
        }

        if foundTalkToTrainer, let headerLabel {
            result[textLabel] = headerLabel
        }
        index = probe
    }

    return result
}

private func parseCollisionSets(repoRoot: URL) throws -> [String: [Int]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/tilesets/collision_tile_ids.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var currentKeys: [String] = []
    var result: [String: [Int]] = [:]

    for line in lines {
        let stringLine = line.trimmingCharacters(in: .whitespaces)
        if stringLine.hasSuffix("::") {
            currentKeys.append(String(stringLine.dropLast(2)))
            continue
        }
        guard stringLine.hasPrefix("coll_tiles") else { continue }
        let values = stringLine
            .replacingOccurrences(of: "coll_tiles", with: "")
            .split(separator: ",")
            .compactMap { token -> Int? in
                let cleaned = token.trimmingCharacters(in: .whitespaces)
                guard cleaned.isEmpty == false else { return nil }
                return Int(cleaned.replacingOccurrences(of: "$", with: ""), radix: 16)
            }
        for key in currentKeys {
            result[key] = values
        }
        currentKeys = []
    }

    return result
}

private func collisionKey(for tileset: String) -> String {
    switch tileset {
    case "OVERWORLD": return "Overworld_Coll"
    case "CAVERN": return "Cavern_Coll"
    case "REDS_HOUSE_1": return "RedsHouse1_Coll"
    case "REDS_HOUSE_2": return "RedsHouse2_Coll"
    case "DOJO": return "Dojo_Coll"
    case "GYM": return "Gym_Coll"
    case "FOREST": return "Forest_Coll"
    case "FOREST_GATE": return "ForestGate_Coll"
    case "GATE": return "Gate_Coll"
    case "MUSEUM": return "Museum_Coll"
    case "HOUSE": return "House_Coll"
    case "INTERIOR": return "Interior_Coll"
    case "MART": return "Mart_Coll"
    case "POKECENTER": return "Pokecenter_Coll"
    case "CLUB": return "Club_Coll"
    case "SHIP": return "Ship_Coll"
    default: return "Overworld_Coll"
    }
}

private func tilesetLabel(for tileset: String) -> String {
    switch tileset {
    case "OVERWORLD": return "Overworld"
    case "CAVERN": return "Cavern"
    case "REDS_HOUSE_1": return "RedsHouse1"
    case "REDS_HOUSE_2": return "RedsHouse2"
    case "DOJO": return "Dojo"
    case "GYM": return "Gym"
    case "FOREST": return "Forest"
    case "FOREST_GATE": return "ForestGate"
    case "GATE": return "Gate"
    case "MUSEUM": return "Museum"
    case "HOUSE": return "House"
    case "INTERIOR": return "Interior"
    case "MART": return "Mart"
    case "POKECENTER": return "Pokecenter"
    case "CLUB": return "Club"
    case "SHIP": return "Ship"
    default: return "Overworld"
    }
}

private func parseSignedHexOrDecimal(_ token: String) -> Int? {
    let trimmed = token.trimmingCharacters(in: .whitespaces)
    if trimmed == "-1" {
        return nil
    }
    if trimmed.hasPrefix("$") {
        return Int(trimmed.dropFirst(), radix: 16)
    }
    if trimmed.hasPrefix("-$") {
        guard let value = Int(trimmed.dropFirst(2), radix: 16) else { return nil }
        return -value
    }
    return Int(trimmed)
}

private struct ParsedTilesetHeaderData {
    let grassTilesByLabel: [String: Int?]
    let animationKindsByLabel: [String: TilesetAnimationKind]
}

private func parseTilesetCollisionData(repoRoot: URL) throws -> ParsedTilesetCollisionData {
    let headerData = try parseTilesetHeaderData(repoRoot: repoRoot)
    return ParsedTilesetCollisionData(
        passableTilesByKey: try parseCollisionSets(repoRoot: repoRoot),
        warpTilesByLabel: try parseTilesetTileTable(repoRoot: repoRoot, path: "data/tilesets/warp_tile_ids.asm"),
        doorTilesByLabel: try parseTilesetTileTable(repoRoot: repoRoot, path: "data/tilesets/door_tile_ids.asm"),
        grassTilesByLabel: headerData.grassTilesByLabel,
        animationKindsByLabel: headerData.animationKindsByLabel,
        tilePairCollisionsByTileset: try parseTilePairCollisions(repoRoot: repoRoot),
        ledges: try parseLedgeRules(repoRoot: repoRoot)
    )
}

private func parseTilesetHeaderData(repoRoot: URL) throws -> ParsedTilesetHeaderData {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/tilesets/tileset_headers.asm"))
    let regex = try NSRegularExpression(
        pattern: #"tileset\s+([A-Za-z0-9_]+),\s+[^,]+,\s+[^,]+,\s+[^,]+,\s+(-?\$?[0-9A-Fa-f]+),\s+(TILEANIM_[A-Z_]+)"#
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var grassTilesByLabel: [String: Int?] = [:]
    var animationKindsByLabel: [String: TilesetAnimationKind] = [:]

    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let labelRange = Range(match.range(at: 1), in: contents),
            let grassRange = Range(match.range(at: 2), in: contents),
            let animationRange = Range(match.range(at: 3), in: contents)
        else {
            continue
        }
        let label = String(contents[labelRange])
        grassTilesByLabel[label] = parseSignedHexOrDecimal(String(contents[grassRange]))
        animationKindsByLabel[label] = try parseTilesetAnimationKind(rawValue: String(contents[animationRange]))
    }

    return ParsedTilesetHeaderData(
        grassTilesByLabel: grassTilesByLabel,
        animationKindsByLabel: animationKindsByLabel
    )
}

private func parseTilesetAnimationKind(rawValue: String) throws -> TilesetAnimationKind {
    switch rawValue {
    case "TILEANIM_NONE":
        return .none
    case "TILEANIM_WATER":
        return .water
    case "TILEANIM_WATER_FLOWER":
        return .waterFlower
    default:
        throw ExtractorError.invalidArguments("unsupported tileset animation kind \(rawValue)")
    }
}

func makeMapManifestDraft(
    repoRoot: URL,
    definition: GameplayCoverageMapDefinition,
    size: TileSize,
    defaultMusicID: String,
    mapSizes: [String: TileSize],
    mapHeadersByID: [String: ParsedMapHeader],
    tilesets: [TilesetManifest],
    mapScriptMetadata: MapScriptMetadata?,
    objectVisibilityByConstant: [String: Bool],
    martStockLabels: Set<String>
) throws -> MapManifestDraft {
    let mapID = definition.mapID
    guard let mapHeader = mapHeadersByID[mapID] else {
        throw ExtractorError.invalidArguments("missing map header for \(mapID)")
    }

    let objectURL = repoRoot.appendingPathComponent(definition.objectFile)
    let contents = try String(contentsOf: objectURL)
    let blockIDs = try loadBlockIDs(
        repoRoot: repoRoot,
        blockFile: definition.blockFile,
        expectedSize: size
    )
    let borderBlockID = try parseBorderBlockID(contents: contents)
    guard let tilesetManifest = tilesets.first(where: { $0.id == mapHeader.tileset }) else {
        throw ExtractorError.invalidArguments("missing tileset manifest for \(mapHeader.tileset)")
    }
    let resolvedStepCollisionTileIDs = try resolveStepCollisionTileIDs(
        repoRoot: repoRoot,
        tileset: tilesetManifest,
        borderBlockID: borderBlockID,
        blockWidth: size.width,
        blockHeight: size.height,
        blockIDs: blockIDs
    )
    let connections = try buildMapConnections(
        for: mapHeader,
        repoRoot: repoRoot,
        mapSizes: mapSizes,
        mapHeadersByID: mapHeadersByID
    )

    return MapManifestDraft(
        id: mapID,
        displayName: definition.displayName,
        parentMapID: definition.parentMapID,
        isOutdoor: definition.isOutdoor,
        defaultMusicID: defaultMusicID,
        borderBlockID: borderBlockID,
        blockWidth: size.width,
        blockHeight: size.height,
        stepWidth: size.width * 2,
        stepHeight: size.height * 2,
        tileset: mapHeader.tileset,
        blockIDs: blockIDs,
        stepCollisionTileIDs: resolvedStepCollisionTileIDs,
        rawWarps: parseRawWarps(contents: contents),
        backgroundEvents: parseBackgroundEvents(mapID: mapID, contents: contents, mapScriptMetadata: mapScriptMetadata),
        objects: parseObjects(
            mapID: mapID,
            contents: contents,
            mapScriptMetadata: mapScriptMetadata,
            objectVisibilityByConstant: objectVisibilityByConstant,
            martStockLabels: martStockLabels
        ),
        connections: connections
    )
}

func resolveMapWarps(
    _ drafts: [MapManifestDraft],
    tilesets: [TilesetManifest]
) throws -> [MapManifest] {
    let draftsByID = Dictionary(uniqueKeysWithValues: drafts.map { ($0.id, $0) })
    let tilesetsByID = Dictionary(uniqueKeysWithValues: tilesets.map { ($0.id, $0) })

    return try drafts.map { draft in
        let warps = try draft.rawWarps.enumerated().map { index, rawWarp in
            let usesPreviousMapTarget = warpUsesPreviousMapTarget(from: draft, rawWarp: rawWarp)
            let targetMapID = resolveTargetMapID(from: draft, rawWarp: rawWarp, rawTargetMapID: rawWarp.rawTargetMapID)
            let targetPosition = try resolveTargetWarpPosition(
                currentMapID: draft.id,
                targetMapID: targetMapID,
                targetWarp: rawWarp.targetWarp,
                draftsByID: draftsByID
            )
            let targetFacing = resolveTargetFacing(
                sourceDraft: draft,
                targetPosition: targetPosition,
                targetMapID: targetMapID,
                draftsByID: draftsByID,
                tilesetsByID: tilesetsByID
            )

            return WarpManifest(
                id: "\(draft.id.lowercased())_warp_\(index)",
                origin: rawWarp.origin,
                targetMapID: targetMapID,
                targetPosition: targetPosition,
                targetFacing: targetFacing,
                targetWarpIndex: rawWarp.targetWarp - 1,
                usesPreviousMapTarget: usesPreviousMapTarget
            )
        }

        return MapManifest(
            id: draft.id,
            displayName: draft.displayName,
            defaultMusicID: draft.defaultMusicID,
            borderBlockID: draft.borderBlockID,
            blockWidth: draft.blockWidth,
            blockHeight: draft.blockHeight,
            stepWidth: draft.stepWidth,
            stepHeight: draft.stepHeight,
            tileset: draft.tileset,
            blockIDs: draft.blockIDs,
            stepCollisionTileIDs: draft.stepCollisionTileIDs,
            warps: warps,
            backgroundEvents: draft.backgroundEvents,
            objects: draft.objects,
            connections: draft.connections
        )
    }
}

private func loadBlockIDs(
    repoRoot: URL,
    blockFile: String,
    expectedSize: TileSize
) throws -> [Int] {
    let blockData = try Data(contentsOf: repoRoot.appendingPathComponent(blockFile))
    let blockIDs = blockData.map(Int.init)
    let expectedCount = expectedSize.width * expectedSize.height
    guard blockIDs.count == expectedCount else {
        throw ExtractorError.invalidArguments(
            "unexpected block count for \(blockFile): expected \(expectedCount), found \(blockIDs.count)"
        )
    }
    return blockIDs
}

private func buildMapConnections(
    for mapHeader: ParsedMapHeader,
    repoRoot: URL,
    mapSizes: [String: TileSize],
    mapHeadersByID: [String: ParsedMapHeader]
) throws -> [MapConnectionManifest] {
    try mapHeader.connections.map { connection in
        guard let targetHeader = mapHeadersByID[connection.targetMapID] else {
            throw ExtractorError.invalidArguments("missing target header for map connection \(connection.targetMapID)")
        }
        guard let targetSize = mapSizes[connection.targetMapID] else {
            throw ExtractorError.invalidArguments("missing size for map connection \(connection.targetMapID)")
        }

        return MapConnectionManifest(
            direction: connection.direction,
            targetMapID: connection.targetMapID,
            offset: connection.offset,
            targetBlockWidth: targetSize.width,
            targetBlockHeight: targetSize.height,
            targetBlockIDs: try loadBlockIDs(
                repoRoot: repoRoot,
                blockFile: "maps/\(targetHeader.symbolName).blk",
                expectedSize: targetSize
            )
        )
    }
}

private func resolveTargetMapID(
    from currentMap: MapManifestDraft,
    rawWarp: RawWarpEntry,
    rawTargetMapID: String
) -> String {
    guard rawTargetMapID == "LAST_MAP" else {
        return rawTargetMapID
    }

    if currentMap.id == "ROUTE_22_GATE" {
        return rawWarp.origin.y == 7 ? "ROUTE_22" : "ROUTE_23"
    }

    return currentMap.parentMapID ?? rawTargetMapID
}

private func warpUsesPreviousMapTarget(from currentMap: MapManifestDraft, rawWarp: RawWarpEntry) -> Bool {
    guard rawWarp.rawTargetMapID == "LAST_MAP" else {
        return false
    }

    switch currentMap.id {
    case "MT_MOON_1F", "MT_MOON_B1F":
        return true
    default:
        return false
    }
}

private func resolveTargetWarpPosition(
    currentMapID: String,
    targetMapID: String,
    targetWarp: Int,
    draftsByID: [String: MapManifestDraft]
) throws -> TilePoint {
    guard let targetMap = draftsByID[targetMapID] else {
        return .init(x: 0, y: 0)
    }
    let targetIndex = targetWarp - 1
    guard targetMap.rawWarps.indices.contains(targetIndex) else {
        throw ExtractorError.invalidArguments("missing destination warp \(targetWarp) in \(targetMapID) for \(currentMapID)")
    }
    return targetMap.rawWarps[targetIndex].origin
}

private func resolveTargetFacing(
    sourceDraft: MapManifestDraft,
    targetPosition: TilePoint,
    targetMapID: String,
    draftsByID: [String: MapManifestDraft],
    tilesetsByID: [String: TilesetManifest]
) -> FacingDirection {
    guard let targetMap = draftsByID[targetMapID],
          let targetTileset = tilesetsByID[targetMap.tileset],
          let targetTileID = collisionTileID(at: targetPosition, in: targetMap),
          targetTileset.collision.doorTileIDs.contains(targetTileID) else {
        return sourceDraft.isOutdoor ? .up : .down
    }

    return .down
}

private func collisionTileID(at point: TilePoint, in map: MapManifestDraft) -> Int? {
    guard point.x >= 0, point.y >= 0, point.x < map.stepWidth, point.y < map.stepHeight else {
        return nil
    }
    let index = (point.y * map.stepWidth) + point.x
    guard map.stepCollisionTileIDs.indices.contains(index) else {
        return nil
    }
    return map.stepCollisionTileIDs[index]
}

private func parseBorderBlockID(contents: String) throws -> Int {
    guard let match = contents.firstMatch(of: /db\s+\$([0-9A-Fa-f]+)/) else {
        throw ExtractorError.invalidArguments("missing border block in map object data")
    }
    guard let value = Int(match.output.1, radix: 16) else {
        throw ExtractorError.invalidArguments("invalid border block value \(match.output.1)")
    }
    return value
}

func buildTilesets(repoRoot: URL) throws -> [TilesetManifest] {
    let collisionData = try parseTilesetCollisionData(repoRoot: repoRoot)
    return [
        .init(
            id: "REDS_HOUSE_1",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "REDS_HOUSE_1", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "REDS_HOUSE_1", parsed: collisionData)
        ),
        .init(
            id: "REDS_HOUSE_2",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "REDS_HOUSE_2", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "REDS_HOUSE_2", parsed: collisionData)
        ),
        .init(
            id: "OVERWORLD",
            imagePath: "Assets/field/tilesets/overworld.png",
            blocksetPath: "Assets/field/blocksets/overworld.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "OVERWORLD", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "OVERWORLD", parsed: collisionData)
        ),
        .init(
            id: "CAVERN",
            imagePath: "Assets/field/tilesets/cavern.png",
            blocksetPath: "Assets/field/blocksets/cavern.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "CAVERN", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "CAVERN", parsed: collisionData)
        ),
        .init(
            id: "DOJO",
            imagePath: "Assets/field/tilesets/gym.png",
            blocksetPath: "Assets/field/blocksets/gym.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "DOJO", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "DOJO", parsed: collisionData)
        ),
        .init(
            id: "GYM",
            imagePath: "Assets/field/tilesets/gym.png",
            blocksetPath: "Assets/field/blocksets/gym.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "GYM", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "GYM", parsed: collisionData)
        ),
        .init(
            id: "FOREST",
            imagePath: "Assets/field/tilesets/forest.png",
            blocksetPath: "Assets/field/blocksets/forest.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "FOREST", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "FOREST", parsed: collisionData)
        ),
        .init(
            id: "FOREST_GATE",
            imagePath: "Assets/field/tilesets/gate.png",
            blocksetPath: "Assets/field/blocksets/gate.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "FOREST_GATE", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "FOREST_GATE", parsed: collisionData)
        ),
        .init(
            id: "GATE",
            imagePath: "Assets/field/tilesets/gate.png",
            blocksetPath: "Assets/field/blocksets/gate.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "GATE", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "GATE", parsed: collisionData)
        ),
        .init(
            id: "MUSEUM",
            imagePath: "Assets/field/tilesets/gate.png",
            blocksetPath: "Assets/field/blocksets/gate.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "MUSEUM", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "MUSEUM", parsed: collisionData)
        ),
        .init(
            id: "HOUSE",
            imagePath: "Assets/field/tilesets/house.png",
            blocksetPath: "Assets/field/blocksets/house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "HOUSE", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "HOUSE", parsed: collisionData)
        ),
        .init(
            id: "INTERIOR",
            imagePath: "Assets/field/tilesets/interior.png",
            blocksetPath: "Assets/field/blocksets/interior.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "INTERIOR", parsed: collisionData)
        ),
        .init(
            id: "MART",
            imagePath: "Assets/field/tilesets/pokecenter.png",
            blocksetPath: "Assets/field/blocksets/pokecenter.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "MART", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "MART", parsed: collisionData)
        ),
        .init(
            id: "CLUB",
            imagePath: "Assets/field/tilesets/club.png",
            blocksetPath: "Assets/field/blocksets/club.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "CLUB", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "CLUB", parsed: collisionData)
        ),
        .init(
            id: "POKECENTER",
            imagePath: "Assets/field/tilesets/pokecenter.png",
            blocksetPath: "Assets/field/blocksets/pokecenter.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "POKECENTER", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "POKECENTER", parsed: collisionData)
        ),
        .init(
            id: "SHIP",
            imagePath: "Assets/field/tilesets/ship.png",
            blocksetPath: "Assets/field/blocksets/ship.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "SHIP", parsed: collisionData),
            animation: tilesetAnimationManifest(for: "SHIP", parsed: collisionData)
        ),
    ]
}

private func tilesetCollisionManifest(for tileset: String, parsed: ParsedTilesetCollisionData) -> TilesetCollisionManifest {
    let label = tilesetLabel(for: tileset)
    return TilesetCollisionManifest(
        passableTileIDs: parsed.passableTilesByKey[collisionKey(for: tileset)] ?? [],
        warpTileIDs: parsed.warpTilesByLabel["\(label)WarpTileIDs"] ?? [],
        doorTileIDs: parsed.doorTilesByLabel["\(label)DoorTileIDs"] ?? [],
        grassTileID: parsed.grassTilesByLabel[label] ?? nil,
        tilePairCollisions: parsed.tilePairCollisionsByTileset[tileset] ?? [],
        ledges: parsed.ledges
    )
}

private func tilesetAnimationManifest(for tileset: String, parsed: ParsedTilesetCollisionData) -> TilesetAnimationManifest {
    let label = tilesetLabel(for: tileset)
    switch parsed.animationKindsByLabel[label] ?? .none {
    case .none:
        return .none
    case .water:
        return TilesetAnimationManifest(
            kind: .water,
            animatedTiles: [.init(tileID: 0x14)]
        )
    case .waterFlower:
        return TilesetAnimationManifest(
            kind: .waterFlower,
            animatedTiles: [
                .init(tileID: 0x14),
                .init(tileID: 0x03, frameImagePaths: flowerAnimationFramePaths())
            ]
        )
    }
}

private func flowerAnimationFramePaths() -> [String] {
    return (1...3).map { frameIndex in
        "Assets/field/tileset_animations/flower/flower\(frameIndex).png"
    }
}

private func parseTilesetTileTable(repoRoot: URL, path: String) throws -> [String: [Int]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent(path))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var labels: [String] = []
    var result: [String: [Int]] = [:]

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix(".") && line.hasSuffix(":") {
            labels.append(String(line.dropFirst().dropLast()))
            continue
        }
        guard line.hasPrefix("warp_tiles") || line.hasPrefix("door_tiles") else { continue }
        let values = line
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true)
            .first?
            .replacingOccurrences(of: "warp_tiles", with: "")
            .replacingOccurrences(of: "door_tiles", with: "")
            .split(separator: ",")
            .compactMap { token -> Int? in
                let cleaned = token.trimmingCharacters(in: .whitespaces)
                guard cleaned.isEmpty == false else { return nil }
                return Int(cleaned.replacingOccurrences(of: "$", with: ""), radix: 16)
            } ?? []
        for label in labels {
            result[label] = values
        }
        labels.removeAll()
    }

    return result
}

private func parseTilePairCollisions(repoRoot: URL) throws -> [String: [TilePairCollisionManifest]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/tilesets/pair_collision_tile_ids.asm"))
    let regex = try NSRegularExpression(pattern: #"db\s+([A-Z0-9_]+),\s+\$([0-9A-Fa-f]+),\s+\$([0-9A-Fa-f]+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var result: [String: [TilePairCollisionManifest]] = [:]

    for match in regex.matches(in: contents, range: nsrange) {
        guard
            let tilesetRange = Range(match.range(at: 1), in: contents),
            let fromRange = Range(match.range(at: 2), in: contents),
            let toRange = Range(match.range(at: 3), in: contents),
            let fromTileID = Int(contents[fromRange], radix: 16),
            let toTileID = Int(contents[toRange], radix: 16)
        else {
            continue
        }

        let tilesetID = String(contents[tilesetRange])
        result[tilesetID, default: []].append(.init(fromTileID: fromTileID, toTileID: toTileID))
    }

    return result
}

private func parseLedgeRules(repoRoot: URL) throws -> [LedgeCollisionManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/tilesets/ledge_tiles.asm"))
    let regex = try NSRegularExpression(pattern: #"db\s+([A-Z0-9_]+),\s+\$([0-9A-Fa-f]+),\s+\$([0-9A-Fa-f]+),\s+[A-Z0-9_]+"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)

    return regex.matches(in: contents, range: nsrange).compactMap { match in
        guard
            let facingRange = Range(match.range(at: 1), in: contents),
            let standingRange = Range(match.range(at: 2), in: contents),
            let ledgeRange = Range(match.range(at: 3), in: contents),
            let standingTileID = Int(contents[standingRange], radix: 16),
            let ledgeTileID = Int(contents[ledgeRange], radix: 16)
        else {
            return nil
        }

        return LedgeCollisionManifest(
            facing: facingDirection(from: String(contents[facingRange])),
            standingTileID: standingTileID,
            ledgeTileID: ledgeTileID
        )
    }
}

private func resolveStepCollisionTileIDs(
    repoRoot: URL,
    tileset: TilesetManifest,
    borderBlockID: Int,
    blockWidth: Int,
    blockHeight: Int,
    blockIDs: [Int]
) throws -> [Int] {
    let blocksetData = try Data(contentsOf: repoRoot.appendingPathComponent(tileset.blocksetPath.replacingOccurrences(of: "Assets/field/", with: "gfx/")))
    let blocks = stride(from: 0, to: blocksetData.count, by: 16).map { start in
        Array(blocksetData[start..<(start + 16)]).map(Int.init)
    }

    func blockIDAt(mapBlockX: Int, mapBlockY: Int) -> Int {
        guard mapBlockX >= 0, mapBlockY >= 0, mapBlockX < blockWidth, mapBlockY < blockHeight else {
            return borderBlockID
        }
        return blockIDs[(mapBlockY * blockWidth) + mapBlockX]
    }

    func collisionTileIDAt(stepX: Int, stepY: Int) -> Int {
        let blockX = stepX / 2
        let blockY = stepY / 2
        let subX = stepX % 2
        let subY = stepY % 2
        let blockID = blockIDAt(mapBlockX: blockX, mapBlockY: blockY)
        guard blocks.indices.contains(blockID) else { return 0 }
        let block = blocks[blockID]
        let tileIndex = ((subY * 2) + 1) * 4 + (subX * 2)
        guard block.indices.contains(tileIndex) else { return 0 }
        return block[tileIndex]
    }

    var result: [Int] = []
    result.reserveCapacity(blockWidth * blockHeight * 4)
    for stepY in 0..<(blockHeight * 2) {
        for stepX in 0..<(blockWidth * 2) {
            result.append(collisionTileIDAt(stepX: stepX, stepY: stepY))
        }
    }
    return result
}
