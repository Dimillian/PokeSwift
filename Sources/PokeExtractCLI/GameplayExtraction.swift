import Foundation
import PokeDataModel

func extractGameplayManifest(source: SourceTree) throws -> GameplayManifest {
    let mapSizes = try parseMapSizes(repoRoot: source.repoRoot)
    let mapHeadersByID = try parseMapHeaders(repoRoot: source.repoRoot)
    let mapMusic = try parseMapMusic(repoRoot: source.repoRoot)
    let tilesets = try buildTilesets(repoRoot: source.repoRoot)
    let mapScriptMetadataByMapID = try parseSelectedMapScriptMetadata(repoRoot: source.repoRoot)
    let martStockLabels = try Set(parseMartStocks(repoRoot: source.repoRoot).keys)

    let mapDrafts = try gameplayCoverageMaps.map { definition in
        try makeMapManifestDraft(
            repoRoot: source.repoRoot,
            definition: definition,
            size: mapSizes[definition.mapID] ?? fallbackMapSize(for: definition.mapID),
            defaultMusicID: mapMusic[definition.mapID] ?? fallbackMusicID(for: definition.mapID),
            mapSizes: mapSizes,
            mapHeadersByID: mapHeadersByID,
            tilesets: tilesets,
            mapScriptMetadata: mapScriptMetadataByMapID[definition.mapID],
            martStockLabels: martStockLabels
        )
    }
    let maps = try resolveMapWarps(mapDrafts, tilesets: tilesets)
    let playerStart = try buildPlayerStart(repoRoot: source.repoRoot)
    let dialogues = try buildDialogues(repoRoot: source.repoRoot, mapScriptMetadataByMapID: mapScriptMetadataByMapID)
    let fieldInteractions = try buildFieldInteractions(maps: maps, repoRoot: source.repoRoot)
    let mapScripts = buildMapScripts()
    let scripts = try buildScripts(repoRoot: source.repoRoot, maps: maps)
    let items = try buildItems(repoRoot: source.repoRoot)
    let marts = try buildMarts(repoRoot: source.repoRoot, mapScriptMetadataByMapID: mapScriptMetadataByMapID)
    let species = try buildSpecies(repoRoot: source.repoRoot)
    let moves = try buildMoves(repoRoot: source.repoRoot)
    let typeEffectiveness = try buildTypeEffectiveness(repoRoot: source.repoRoot)
    let wildEncounterTables = try buildWildEncounterTables(repoRoot: source.repoRoot)
    let trainerAIMoveChoiceModifications = try buildTrainerAIMoveChoiceModifications(repoRoot: source.repoRoot)
    let trainerBattles = try buildTrainerBattles(repoRoot: source.repoRoot, mapScriptMetadataByMapID: mapScriptMetadataByMapID)
    let eventFlags = try parseEventFlags(
        repoRoot: source.repoRoot,
        maps: maps,
        mapScripts: mapScripts,
        scripts: scripts,
        trainerBattles: trainerBattles,
        playerStart: playerStart
    )
    let commonBattleText = try buildCommonBattleText(repoRoot: source.repoRoot)

    return GameplayManifest(
        maps: maps,
        tilesets: tilesets,
        overworldSprites: buildOverworldSprites(),
        dialogues: dialogues,
        fieldInteractions: fieldInteractions,
        eventFlags: EventFlagManifest(flags: eventFlags),
        mapScripts: mapScripts,
        scripts: scripts,
        items: items,
        marts: marts,
        species: species,
        moves: moves,
        typeEffectiveness: typeEffectiveness,
        wildEncounterTables: wildEncounterTables,
        trainerAIMoveChoiceModifications: trainerAIMoveChoiceModifications,
        trainerBattles: trainerBattles,
        commonBattleText: commonBattleText,
        playerStart: playerStart
    )
}

private struct ParsedTilesetCollisionData {
    let passableTilesByKey: [String: [Int]]
    let warpTilesByLabel: [String: [Int]]
    let doorTilesByLabel: [String: [Int]]
    let grassTilesByLabel: [String: Int?]
    let tilePairCollisionsByTileset: [String: [TilePairCollisionManifest]]
    let ledges: [LedgeCollisionManifest]
}

private struct RawWarpEntry {
    let origin: TilePoint
    let rawTargetMapID: String
    let targetWarp: Int
}

private struct ParsedMapHeader {
    let symbolName: String
    let id: String
    let tileset: String
    let connections: [RawMapConnection]
}

private struct RawMapConnection {
    let direction: MapConnectionDirection
    let targetMapID: String
    let offset: Int
}

private struct StandardTrainerHeaderMetadata {
    let defeatFlagID: String
    let engageDistance: Int
    let battleTextLabel: String
    let endBattleTextLabel: String
    let afterBattleTextLabel: String
}

private struct MapScriptMetadata {
    let textLabelByTextID: [String: String]
    let pickupTextIDs: Set<String>
    let farTextLabelByLocalLabel: [String: String]
    let referencedFarTextLabels: Set<String>
    let trainerHeadersByLabel: [String: StandardTrainerHeaderMetadata]
    let trainerHeaderLabelByTextLabel: [String: String]
    let usesStandardTrainerLoop: Bool
}

private func fallbackMapSize(for mapID: String) -> TileSize {
    switch mapID {
    case "REDS_HOUSE_2F", "REDS_HOUSE_1F", "VIRIDIAN_MART":
        return .init(width: 4, height: 4)
    case "PALLET_TOWN":
        return .init(width: 10, height: 9)
    case "ROUTE_1":
        return .init(width: 10, height: 18)
    case "ROUTE_2":
        return .init(width: 10, height: 36)
    case "VIRIDIAN_CITY":
        return .init(width: 20, height: 18)
    case "VIRIDIAN_POKECENTER":
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

private func fallbackMusicID(for mapID: String) -> String {
    switch mapID {
    case "PALLET_TOWN", "REDS_HOUSE_1F", "REDS_HOUSE_2F":
        return "MUSIC_PALLET_TOWN"
    case "ROUTE_1", "ROUTE_2":
        return "MUSIC_ROUTES1"
    case "VIRIDIAN_CITY", "VIRIDIAN_SCHOOL_HOUSE", "VIRIDIAN_NICKNAME_HOUSE":
        return "MUSIC_CITIES1"
    case "VIRIDIAN_POKECENTER", "VIRIDIAN_MART":
        return "MUSIC_POKECENTER"
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

private struct MapManifestDraft {
    let id: String
    let displayName: String
    let parentMapID: String?
    let isOutdoor: Bool
    let defaultMusicID: String
    let borderBlockID: Int
    let blockWidth: Int
    let blockHeight: Int
    let stepWidth: Int
    let stepHeight: Int
    let tileset: String
    let blockIDs: [Int]
    let stepCollisionTileIDs: [Int]
    let rawWarps: [RawWarpEntry]
    let backgroundEvents: [BackgroundEventManifest]
    let objects: [MapObjectManifest]
    let connections: [MapConnectionManifest]
}

private func parseMapSizes(repoRoot: URL) throws -> [String: TileSize] {
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

private func parseEventFlags(
    repoRoot: URL,
    maps: [MapManifest],
    mapScripts: [MapScriptManifest],
    scripts: [ScriptManifest],
    trainerBattles: [TrainerBattleManifest],
    playerStart: PlayerStartManifest
) throws -> [EventFlagDefinition] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/event_constants.asm"))
    let requiredFlags = referencedEventFlagIDs(
        maps: maps,
        mapScripts: mapScripts,
        scripts: scripts,
        trainerBattles: trainerBattles,
        playerStart: playerStart
    )

    return try requiredFlags.map { flagID in
        guard contents.contains("const \(flagID)") else {
            throw ExtractorError.invalidArguments("missing event flag \(flagID)")
        }
        return EventFlagDefinition(id: flagID, sourceConstant: flagID)
    }
}

private func referencedEventFlagIDs(
    maps: [MapManifest],
    mapScripts: [MapScriptManifest],
    scripts: [ScriptManifest],
    trainerBattles: [TrainerBattleManifest],
    playerStart: PlayerStartManifest
) -> [String] {
    let objectTriggerFlags = maps.flatMap { map in
        map.objects.flatMap { object in
            object.interactionTriggers.flatMap { $0.conditions.compactMap(\.flagID) }
        }
    }
    let mapScriptFlags = mapScripts.flatMap { $0.triggers.flatMap { $0.conditions.compactMap(\.flagID) } }
    let scriptStepFlags = scripts.flatMap { script in
        script.steps.compactMap(\.flagID) + script.steps.flatMap { step in
            (step.movement?.variants ?? []).flatMap { $0.conditions.compactMap(\.flagID) }
        }
    }
    let trainerBattleFlags = trainerBattles.map(\.completionFlagID)

    return Set(
        playerStart.initialFlags
        + objectTriggerFlags
        + mapScriptFlags
        + scriptStepFlags
        + trainerBattleFlags
    )
    .sorted()
}

private func parseMapHeaders(repoRoot: URL) throws -> [String: ParsedMapHeader] {
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

private func parseMapMusic(repoRoot: URL) throws -> [String: String] {
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

private func parseSelectedMapScriptMetadata(repoRoot: URL) throws -> [String: MapScriptMetadata] {
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

private func mapFileStem(for definition: GameplayCoverageMapDefinition) -> String {
    URL(fileURLWithPath: definition.objectFile).deletingPathExtension().lastPathComponent
}

private func scriptPathForMap(_ definition: GameplayCoverageMapDefinition) -> String {
    "scripts/\(mapFileStem(for: definition)).asm"
}

private func buildTextContentsByMapID(repoRoot: URL) throws -> [String: String] {
    let textDirectoryURL = repoRoot.appendingPathComponent("text", isDirectory: true)
    let textFiles = try FileManager.default.contentsOfDirectory(
        at: textDirectoryURL,
        includingPropertiesForKeys: nil
    )
    .filter { $0.pathExtension == "asm" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

    return try gameplayCoverageMaps.reduce(into: [:]) { result, definition in
        let stem = mapFileStem(for: definition)
        let candidateURLs = textFiles
            .filter { url in
                url.deletingPathExtension().lastPathComponent == stem ||
                url.deletingPathExtension().lastPathComponent.hasPrefix("\(stem)_")
            }

        guard candidateURLs.isEmpty == false else {
            return
        }

        result[definition.mapID] = try candidateURLs
            .map { try String(contentsOf: $0) }
            .joined(separator: "\n")
    }
}

private func parseMapScriptMetadata(contents: String) -> MapScriptMetadata {
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
        usesStandardTrainerLoop: usesStandardTrainerLoop
    )
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
    case "REDS_HOUSE_1": return "RedsHouse1_Coll"
    case "REDS_HOUSE_2": return "RedsHouse2_Coll"
    case "DOJO": return "Dojo_Coll"
    case "GYM": return "Gym_Coll"
    case "FOREST": return "Forest_Coll"
    case "FOREST_GATE": return "ForestGate_Coll"
    case "MUSEUM": return "Museum_Coll"
    case "HOUSE": return "House_Coll"
    case "MART": return "Mart_Coll"
    case "POKECENTER": return "Pokecenter_Coll"
    default: return "Overworld_Coll"
    }
}

private func tilesetLabel(for tileset: String) -> String {
    switch tileset {
    case "OVERWORLD": return "Overworld"
    case "REDS_HOUSE_1": return "RedsHouse1"
    case "REDS_HOUSE_2": return "RedsHouse2"
    case "DOJO": return "Dojo"
    case "GYM": return "Gym"
    case "FOREST": return "Forest"
    case "FOREST_GATE": return "ForestGate"
    case "MUSEUM": return "Museum"
    case "HOUSE": return "House"
    case "MART": return "Mart"
    case "POKECENTER": return "Pokecenter"
    default: return "Overworld"
    }
}

private func parseTilesetCollisionData(repoRoot: URL) throws -> ParsedTilesetCollisionData {
    ParsedTilesetCollisionData(
        passableTilesByKey: try parseCollisionSets(repoRoot: repoRoot),
        warpTilesByLabel: try parseTilesetTileTable(repoRoot: repoRoot, path: "data/tilesets/warp_tile_ids.asm"),
        doorTilesByLabel: try parseTilesetTileTable(repoRoot: repoRoot, path: "data/tilesets/door_tile_ids.asm"),
        grassTilesByLabel: try parseGrassTiles(repoRoot: repoRoot),
        tilePairCollisionsByTileset: try parseTilePairCollisions(repoRoot: repoRoot),
        ledges: try parseLedgeRules(repoRoot: repoRoot)
    )
}

private func parseGrassTiles(repoRoot: URL) throws -> [String: Int?] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/tilesets/tileset_headers.asm"))
    let regex = try NSRegularExpression(
        pattern: #"tileset\s+([A-Za-z0-9_]+),\s+[^,]+,\s+[^,]+,\s+[^,]+,\s+(-?\$?[0-9A-Fa-f]+)"#
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var result: [String: Int?] = [:]

    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let labelRange = Range(match.range(at: 1), in: contents),
            let grassRange = Range(match.range(at: 2), in: contents)
        else {
            continue
        }
        result[String(contents[labelRange])] = parseSignedHexOrDecimal(String(contents[grassRange]))
    }

    return result
}

private func makeMapManifestDraft(
    repoRoot: URL,
    definition: GameplayCoverageMapDefinition,
    size: TileSize,
    defaultMusicID: String,
    mapSizes: [String: TileSize],
    mapHeadersByID: [String: ParsedMapHeader],
    tilesets: [TilesetManifest],
    mapScriptMetadata: MapScriptMetadata?,
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
            martStockLabels: martStockLabels
        ),
        connections: connections
    )
}

private func resolveMapWarps(
    _ drafts: [MapManifestDraft],
    tilesets: [TilesetManifest]
) throws -> [MapManifest] {
    let draftsByID = Dictionary(uniqueKeysWithValues: drafts.map { ($0.id, $0) })
    let tilesetsByID = Dictionary(uniqueKeysWithValues: tilesets.map { ($0.id, $0) })

    return try drafts.map { draft in
        let warps = try draft.rawWarps.enumerated().map { index, rawWarp in
            let targetMapID = resolveTargetMapID(from: draft, rawTargetMapID: rawWarp.rawTargetMapID)
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
                targetFacing: targetFacing
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

private func resolveTargetMapID(from currentMap: MapManifestDraft, rawTargetMapID: String) -> String {
    guard rawTargetMapID == "LAST_MAP" else {
        return rawTargetMapID
    }

    return currentMap.parentMapID ?? rawTargetMapID
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

private func buildTilesets(repoRoot: URL) throws -> [TilesetManifest] {
    let collisionData = try parseTilesetCollisionData(repoRoot: repoRoot)
    return [
        .init(
            id: "REDS_HOUSE_1",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "REDS_HOUSE_1", parsed: collisionData)
        ),
        .init(
            id: "REDS_HOUSE_2",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "REDS_HOUSE_2", parsed: collisionData)
        ),
        .init(
            id: "OVERWORLD",
            imagePath: "Assets/field/tilesets/overworld.png",
            blocksetPath: "Assets/field/blocksets/overworld.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "OVERWORLD", parsed: collisionData)
        ),
        .init(
            id: "DOJO",
            imagePath: "Assets/field/tilesets/gym.png",
            blocksetPath: "Assets/field/blocksets/gym.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "DOJO", parsed: collisionData)
        ),
        .init(
            id: "GYM",
            imagePath: "Assets/field/tilesets/gym.png",
            blocksetPath: "Assets/field/blocksets/gym.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "GYM", parsed: collisionData)
        ),
        .init(
            id: "FOREST",
            imagePath: "Assets/field/tilesets/forest.png",
            blocksetPath: "Assets/field/blocksets/forest.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "FOREST", parsed: collisionData)
        ),
        .init(
            id: "FOREST_GATE",
            imagePath: "Assets/field/tilesets/gate.png",
            blocksetPath: "Assets/field/blocksets/gate.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "FOREST_GATE", parsed: collisionData)
        ),
        .init(
            id: "MUSEUM",
            imagePath: "Assets/field/tilesets/gate.png",
            blocksetPath: "Assets/field/blocksets/gate.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "MUSEUM", parsed: collisionData)
        ),
        .init(
            id: "HOUSE",
            imagePath: "Assets/field/tilesets/house.png",
            blocksetPath: "Assets/field/blocksets/house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "HOUSE", parsed: collisionData)
        ),
        .init(
            id: "MART",
            imagePath: "Assets/field/tilesets/pokecenter.png",
            blocksetPath: "Assets/field/blocksets/pokecenter.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "MART", parsed: collisionData)
        ),
        .init(
            id: "POKECENTER",
            imagePath: "Assets/field/tilesets/pokecenter.png",
            blocksetPath: "Assets/field/blocksets/pokecenter.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4,
            collision: tilesetCollisionManifest(for: "POKECENTER", parsed: collisionData)
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

private func buildOverworldSprites() -> [OverworldSpriteManifest] {
    [
        buildCharacterSprite(id: "SPRITE_RED", imagePath: "Assets/field/sprites/red.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_OAK", imagePath: "Assets/field/sprites/oak.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_BLUE", imagePath: "Assets/field/sprites/blue.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_MOM", imagePath: "Assets/field/sprites/mom.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_GIRL", imagePath: "Assets/field/sprites/girl.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_FISHER", imagePath: "Assets/field/sprites/fisher.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_SCIENTIST", imagePath: "Assets/field/sprites/scientist.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_YOUNGSTER", imagePath: "Assets/field/sprites/youngster.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_GAMBLER", imagePath: "Assets/field/sprites/gambler.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_GAMBLER_ASLEEP", imagePath: "Assets/field/sprites/gambler_asleep.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_BRUNETTE_GIRL", imagePath: "Assets/field/sprites/brunette_girl.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_COOLTRAINER_F", imagePath: "Assets/field/sprites/cooltrainer_f.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_BALDING_GUY", imagePath: "Assets/field/sprites/balding_guy.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_LITTLE_GIRL", imagePath: "Assets/field/sprites/little_girl.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_BIRD", imagePath: "Assets/field/sprites/bird.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_CLIPBOARD", imagePath: "Assets/field/sprites/clipboard.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_CLERK", imagePath: "Assets/field/sprites/clerk.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_COOLTRAINER_M", imagePath: "Assets/field/sprites/cooltrainer_m.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_NURSE", imagePath: "Assets/field/sprites/nurse.png", hasWalkingFrames: false),
        buildCharacterSprite(id: "SPRITE_GENTLEMAN", imagePath: "Assets/field/sprites/gentleman.png", hasWalkingFrames: true),
        buildCharacterSprite(id: "SPRITE_LINK_RECEPTIONIST", imagePath: "Assets/field/sprites/link_receptionist.png", hasWalkingFrames: false),
        .init(
            id: "SPRITE_POKE_BALL",
            imagePath: "Assets/field/sprites/poke_ball.png",
            frameWidth: 16,
            frameHeight: 16,
            facingFrames: .init(
                down: .init(x: 0, y: 0, width: 16, height: 16),
                up: .init(x: 0, y: 0, width: 16, height: 16),
                left: .init(x: 0, y: 0, width: 16, height: 16),
                right: .init(x: 0, y: 0, width: 16, height: 16)
            )
        ),
        .init(
            id: "SPRITE_POKEDEX",
            imagePath: "Assets/field/sprites/pokedex.png",
            frameWidth: 16,
            frameHeight: 16,
            facingFrames: .init(
                down: .init(x: 0, y: 0, width: 16, height: 16),
                up: .init(x: 0, y: 0, width: 16, height: 16),
                left: .init(x: 0, y: 0, width: 16, height: 16),
                right: .init(x: 0, y: 0, width: 16, height: 16)
            )
        ),
    ]
}

private func buildCharacterSprite(id: String, imagePath: String, hasWalkingFrames: Bool) -> OverworldSpriteManifest {
    let leftFrame = PixelRect(x: 0, y: 32, width: 16, height: 16)
    return OverworldSpriteManifest(
        id: id,
        imagePath: imagePath,
        frameWidth: 16,
        frameHeight: 16,
        facingFrames: .init(
            down: .init(x: 0, y: 0, width: 16, height: 16),
            up: .init(x: 0, y: 16, width: 16, height: 16),
            left: leftFrame,
            right: .init(x: leftFrame.x, y: leftFrame.y, width: leftFrame.width, height: leftFrame.height, flippedHorizontally: true)
        ),
        walkingFrames: hasWalkingFrames ? .init(
            down: .init(x: 0, y: 48, width: 16, height: 16),
            up: .init(x: 0, y: 64, width: 16, height: 16),
            left: .init(x: 0, y: 80, width: 16, height: 16),
            right: .init(x: 0, y: 80, width: 16, height: 16, flippedHorizontally: true)
        ) : nil
    )
}

private func parseRawWarps(contents: String) -> [RawWarpEntry] {
    let regex = try! NSRegularExpression(pattern: #"warp_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+(\d+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).compactMap { match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let targetRange = Range(match.range(at: 3), in: contents),
            let targetWarpRange = Range(match.range(at: 4), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange]),
            let targetWarp = Int(contents[targetWarpRange])
        else {
            return nil
        }

        return RawWarpEntry(
            origin: .init(x: x, y: y),
            rawTargetMapID: String(contents[targetRange]),
            targetWarp: targetWarp
        )
    }
}

private func parseBackgroundEvents(
    mapID: String,
    contents: String,
    mapScriptMetadata: MapScriptMetadata?
) -> [BackgroundEventManifest] {
    let regex = try! NSRegularExpression(pattern: #"bg_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).enumerated().compactMap { index, match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let textRange = Range(match.range(at: 3), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange])
        else {
            return nil
        }
        let textID = String(contents[textRange])
        return BackgroundEventManifest(
            id: "\(mapID.lowercased())_bg_\(index)",
            position: .init(x: x, y: y),
            dialogueID: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata)
        )
    }
}

private func parseObjects(
    mapID: String,
    contents: String,
    mapScriptMetadata: MapScriptMetadata?,
    martStockLabels: Set<String>
) -> [MapObjectManifest] {
    let regex = try! NSRegularExpression(
        pattern: #"(?m)^\s*object_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z0-9_]+)(.*)$"#,
        options: [.anchorsMatchLines]
    )
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).enumerated().compactMap { index, match in
        guard
            let xRange = Range(match.range(at: 1), in: contents),
            let yRange = Range(match.range(at: 2), in: contents),
            let spriteRange = Range(match.range(at: 3), in: contents),
            let movementRange = Range(match.range(at: 4), in: contents),
            let facingRange = Range(match.range(at: 5), in: contents),
            let textRange = Range(match.range(at: 6), in: contents),
            let x = Int(contents[xRange]),
            let y = Int(contents[yRange])
        else {
            return nil
        }

        let sprite = String(contents[spriteRange])
        let movement = String(contents[movementRange])
        let facing = facingDirection(from: String(contents[facingRange]))
        let textID = String(contents[textRange])
        let extraTokens = Range(match.range(at: 7), in: contents)
            .map { parseObjectExtraTokens(from: String(contents[$0])) } ?? []
        let trainerClass = extraTokens.count >= 2 ? extraTokens[0] : nil
        let trainerNumber = extraTokens.count >= 2 ? Int(extraTokens[1]) : nil
        let trainerBattleID = trainerBattleIDFor(trainerClass: trainerClass, trainerNumber: trainerNumber)
        let textLabel = mapScriptMetadata?.textLabelByTextID[textID]
        let trainerHeader = textLabel
            .flatMap { mapScriptMetadata?.trainerHeaderLabelByTextLabel[$0] }
            .flatMap { mapScriptMetadata?.trainerHeadersByLabel[$0] }
        let pickupItemID =
            sprite == "SPRITE_POKE_BALL" &&
            (mapScriptMetadata?.pickupTextIDs.contains(textID) ?? false) &&
            extraTokens.isEmpty == false
                ? extraTokens[0]
                : nil
        let position = TilePoint(x: x, y: y)
        let objectID = objectIDFor(
            mapID: mapID,
            index: index,
            textID: textID,
            pickupItemID: pickupItemID,
            mapScriptMetadata: mapScriptMetadata
        )

        return MapObjectManifest(
            id: objectID,
            displayName: displayNameForObject(objectID: objectID, textID: textID, sprite: sprite, pickupItemID: pickupItemID),
            sprite: sprite,
            position: position,
            facing: facing,
            interactionReach: interactionReach(for: objectID, sprite: sprite),
            interactionTriggers: interactionTriggers(
                for: objectID,
                mapID: mapID,
                sprite: sprite,
                textLabel: textLabel,
                martStockLabels: martStockLabels
            ),
            interactionDialogueID: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata),
            interactionScriptID: interactionScriptID(for: objectID, mapID: mapID, sprite: sprite),
            movementBehavior: movementBehavior(
                movementToken: movement,
                facingToken: String(contents[facingRange]),
                home: position
            ),
            trainerBattleID: trainerBattleID,
            trainerClass: trainerClass,
            trainerNumber: trainerNumber,
            trainerEngageDistance: trainerHeader?.engageDistance,
            trainerIntroDialogueID: trainerHeader.map { dialogueID(forScriptLabel: $0.battleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            trainerEndBattleDialogueID: trainerHeader.map { dialogueID(forScriptLabel: $0.endBattleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            trainerAfterBattleDialogueID: trainerHeader.map { dialogueID(forScriptLabel: $0.afterBattleTextLabel, mapScriptMetadata: mapScriptMetadata) },
            pickupItemID: pickupItemID,
            visibleByDefault: defaultVisibility(for: objectID)
        )
    }
}

private func parseObjectExtraTokens(from suffix: String) -> [String] {
    let trimmed = suffix
        .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        .first?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard trimmed.isEmpty == false else {
        return []
    }
    return trimmed
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { $0.isEmpty == false }
}

private func dialogueID(forScriptLabel label: String, mapScriptMetadata: MapScriptMetadata?) -> String {
    let resolvedLabel = mapScriptMetadata?.farTextLabelByLocalLabel[label] ?? label
    return normalizedDialogueID(from: resolvedLabel)
}

private func normalizedDialogueID(from label: String) -> String {
    let trimmed = label
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        .replacingOccurrences(of: ".", with: "_")
    let withoutTextSuffix =
        trimmed.hasSuffix("Text")
            ? String(trimmed.dropLast(4))
            : trimmed

    return withoutTextSuffix
        .unicodeScalars
        .reduce(into: "") { partialResult, scalar in
            let character = Character(scalar)
            if CharacterSet.uppercaseLetters.contains(scalar), partialResult.isEmpty == false, partialResult.last != "_" {
                partialResult.append("_")
            }
            if CharacterSet.alphanumerics.contains(scalar) {
                partialResult.append(String(character).lowercased())
            } else if partialResult.last != "_" {
                partialResult.append("_")
            }
        }
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
}

private func movementBehavior(
    movementToken: String,
    facingToken: String,
    home: TilePoint
) -> ObjectMovementBehavior {
    switch movementToken {
    case "WALK":
        let axis: ObjectMovementAxis
        switch facingToken {
        case "ANY_DIR":
            axis = .any
        case "UP_DOWN":
            axis = .upDown
        case "LEFT_RIGHT":
            axis = .leftRight
        default:
            axis = .any
        }
        return .init(idleMode: .walk, axis: axis, home: home)
    default:
        return .init(idleMode: .stay, axis: .none, home: home, maxDistanceFromHome: 0)
    }
}

private func objectIDFor(
    mapID: String,
    index: Int,
    textID: String,
    pickupItemID: String?,
    mapScriptMetadata: MapScriptMetadata?
) -> String {
    switch (mapID, textID) {
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAK"): return "pallet_town_oak"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_GIRL"): return "pallet_town_girl"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_FISHER"): return "pallet_town_fisher"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM"): return "reds_house_1f_mom"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER1"): return "route_1_youngster_1"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER2"): return "route_1_youngster_2"
    case ("ROUTE_2", "TEXT_ROUTE2_MOON_STONE"): return "route_2_moon_stone"
    case ("ROUTE_2", "TEXT_ROUTE2_HP_UP"): return "route_2_hp_up"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_SLEEPY"): return "viridian_city_old_man_sleepy"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN"): return "viridian_city_old_man_awake"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL"): return "viridian_city_girl"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER1"): return "viridian_city_youngster_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER2"): return "viridian_city_youngster_2"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GAMBLER1"): return "viridian_city_gambler"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_FISHER"): return "viridian_city_fisher"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_BRUNETTE_GIRL"): return "viridian_school_house_brunette_girl"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_COOLTRAINER_F"): return "viridian_school_house_cooltrainer_f"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY"): return "viridian_nickname_house_balding_guy"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_LITTLE_GIRL"): return "viridian_nickname_house_little_girl"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEAROW"): return "viridian_nickname_house_spearow"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEARY_SIGN"): return "viridian_nickname_house_speary_sign"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_CLERK"): return "viridian_mart_clerk"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_YOUNGSTER"): return "viridian_mart_youngster"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_COOLTRAINER_M"): return "viridian_mart_cooltrainer"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_GIRL"): return "viridian_forest_south_gate_girl"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_LITTLE_GIRL"): return "viridian_forest_south_gate_little_girl"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER1"): return "viridian_forest_youngster_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER2"): return "viridian_forest_bug_catcher_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER3"): return "viridian_forest_bug_catcher_2"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER4"): return "viridian_forest_bug_catcher_3"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_ANTIDOTE"): return "viridian_forest_antidote"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_POTION"): return "viridian_forest_potion"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_POKE_BALL"): return "viridian_forest_poke_ball"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER5"): return "viridian_forest_youngster_5"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_SUPER_NERD"): return "viridian_forest_north_gate_super_nerd"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_GRAMPS"): return "viridian_forest_north_gate_gramps"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_NURSE"): return "viridian_pokecenter_nurse"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_GENTLEMAN"): return "viridian_pokecenter_gentleman"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_COOLTRAINER_M"): return "viridian_pokecenter_cooltrainer"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_LINK_RECEPTIONIST"): return "viridian_pokecenter_link_receptionist"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival"
    case ("OAKS_LAB", "TEXT_OAKSLAB_CHARMANDER_POKE_BALL"): return "oaks_lab_poke_ball_charmander"
    case ("OAKS_LAB", "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL"): return "oaks_lab_poke_ball_squirtle"
    case ("OAKS_LAB", "TEXT_OAKSLAB_BULBASAUR_POKE_BALL"): return "oaks_lab_poke_ball_bulbasaur"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK1"): return "oaks_lab_oak_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK2"): return "oaks_lab_oak_2"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX1"): return "oaks_lab_pokedex_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX2"): return "oaks_lab_pokedex_2"
    default:
        if let pickupItemID {
            return "\(mapID.lowercased())_\(pickupItemID.lowercased())"
        }
        if let fallbackObjectID = fallbackObjectID(for: textID, mapScriptMetadata: mapScriptMetadata) {
            return fallbackObjectID
        }
        return "\(mapID.lowercased())_object_\(index)"
    }
}

private func fallbackObjectID(for textID: String, mapScriptMetadata: MapScriptMetadata?) -> String? {
    guard
        let mapScriptMetadata,
        let baseID = fallbackObjectIDBase(for: textID, mapScriptMetadata: mapScriptMetadata)
    else {
        return nil
    }

    let matchingTextIDs = mapScriptMetadata.textLabelByTextID.keys
        .filter { fallbackObjectIDBase(for: $0, mapScriptMetadata: mapScriptMetadata) == baseID }
        .sorted()

    guard matchingTextIDs.count > 1, let matchingIndex = matchingTextIDs.firstIndex(of: textID) else {
        return baseID
    }

    return "\(baseID)_\(matchingIndex + 1)"
}

private func fallbackObjectIDBase(for textID: String, mapScriptMetadata: MapScriptMetadata) -> String? {
    guard let localLabel = mapScriptMetadata.textLabelByTextID[textID] else {
        return nil
    }

    return dialogueID(forScriptLabel: localLabel, mapScriptMetadata: mapScriptMetadata)
}

private func interactionReach(for objectID: String, sprite: String) -> ObjectInteractionReach {
    switch objectID {
    case "viridian_mart_clerk", "viridian_pokecenter_nurse":
        return .overCounter
    default:
        switch sprite {
        case "SPRITE_CLERK", "SPRITE_NURSE":
            return .overCounter
        default:
            return .adjacent
        }
    }
}

private func interactionScriptID(for objectID: String, mapID: String, sprite: String) -> String? {
    switch objectID {
    case "viridian_pokecenter_nurse":
        return "viridian_pokecenter_nurse_heal"
    default:
        if sprite == "SPRITE_NURSE" {
            return pokemonCenterHealScriptID(for: mapID)
        }
        return nil
    }
}

private func interactionTriggers(
    for objectID: String,
    mapID: String,
    sprite: String,
    textLabel: String?,
    martStockLabels: Set<String>
) -> [ObjectInteractionTriggerManifest] {
    switch objectID {
    case "reds_house_1f_mom":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                scriptID: "reds_house_1f_mom_heal"
            ),
        ]
    case "oaks_lab_rival":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                dialogueID: "oaks_lab_rival_my_pokemon_looks_stronger"
            ),
            .init(dialogueID: "oaks_lab_rival_gramps_isnt_around"),
        ]
    case "oaks_lab_oak_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POKEDEX")],
                dialogueID: "oaks_lab_oak_how_is_your_pokedex_coming"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                    .init(kind: "flagSet", flagID: "EVENT_GOT_OAKS_PARCEL"),
                    .init(kind: "flagUnset", flagID: "EVENT_OAK_GOT_PARCEL"),
                ],
                scriptID: "oaks_lab_parcel_handoff"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB")],
                dialogueID: "oaks_lab_oak_raise_your_young_pokemon"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
                dialogueID: "oaks_lab_oak_raise_your_young_pokemon"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON")],
                dialogueID: "oaks_lab_oak_which_pokemon_do_you_want"
            ),
            .init(dialogueID: "oaks_lab_oak_choose_mon"),
        ]
    case "route_1_youngster_1":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POTION_SAMPLE")],
                dialogueID: "route_1_youngster_1_after_sample"
            ),
            .init(scriptID: "route_1_potion_sample"),
        ]
    case "viridian_city_girl":
        return [
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_POKEDEX")],
                dialogueID: "viridian_city_girl_after_pokedex"
            ),
        ]
    case "viridian_mart_clerk":
        return [
            .init(
                conditions: [.init(kind: "flagUnset", flagID: "EVENT_GOT_OAKS_PARCEL")],
                scriptID: "viridian_mart_oaks_parcel"
            ),
            .init(
                conditions: [
                    .init(kind: "flagSet", flagID: "EVENT_GOT_OAKS_PARCEL"),
                    .init(kind: "flagUnset", flagID: "EVENT_OAK_GOT_PARCEL"),
                ],
                dialogueID: "viridian_mart_clerk_after_parcel"
            ),
            .init(
                conditions: [.init(kind: "flagSet", flagID: "EVENT_OAK_GOT_PARCEL")],
                martID: "viridian_mart"
            ),
        ]
    case "oaks_lab_poke_ball_charmander":
        return starterBallInteractionTriggers(speciesID: "CHARMANDER", scriptID: "oaks_lab_choose_charmander")
    case "oaks_lab_poke_ball_squirtle":
        return starterBallInteractionTriggers(speciesID: "SQUIRTLE", scriptID: "oaks_lab_choose_squirtle")
    case "oaks_lab_poke_ball_bulbasaur":
        return starterBallInteractionTriggers(speciesID: "BULBASAUR", scriptID: "oaks_lab_choose_bulbasaur")
    default:
        if sprite == "SPRITE_CLERK", let textLabel, martStockLabels.contains(textLabel) {
            return [.init(martID: martID(for: mapID))]
        }
        return []
    }
}

private func starterBallInteractionTriggers(speciesID _: String, scriptID: String) -> [ObjectInteractionTriggerManifest] {
    return [
        .init(
            conditions: [.init(kind: "flagUnset", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON")],
            dialogueID: "oaks_lab_those_are_pokeballs"
        ),
        .init(
            conditions: [.init(kind: "flagSet", flagID: "EVENT_GOT_STARTER")],
            dialogueID: "oaks_lab_last_mon"
        ),
        .init(scriptID: scriptID),
    ]
}

private func displayNameForObject(
    objectID: String,
    textID: String,
    sprite: String,
    pickupItemID: String?
) -> String {
    switch objectID {
    case "pallet_town_oak": return "Oak"
    case "pallet_town_girl": return "Girl"
    case "pallet_town_fisher": return "Fisher"
    case "reds_house_1f_mom": return "Mom"
    case "route_1_youngster_1", "route_1_youngster_2": return "Youngster"
    case "route_2_moon_stone": return "Moon Stone"
    case "route_2_hp_up": return "HP Up"
    case "viridian_city_old_man_sleepy", "viridian_city_old_man_awake": return "Old Man"
    case "viridian_city_girl": return "Girl"
    case "viridian_city_youngster_1", "viridian_city_youngster_2": return "Youngster"
    case "viridian_city_gambler": return "Gambler"
    case "viridian_city_fisher": return "Fisher"
    case "viridian_school_house_brunette_girl": return "Brunette Girl"
    case "viridian_school_house_cooltrainer_f": return "Cooltrainer"
    case "viridian_nickname_house_balding_guy": return "Balding Guy"
    case "viridian_nickname_house_little_girl": return "Little Girl"
    case "viridian_nickname_house_spearow": return "Spearow"
    case "viridian_nickname_house_speary_sign": return "Speary Sign"
    case "viridian_mart_clerk": return "Clerk"
    case "viridian_mart_youngster": return "Youngster"
    case "viridian_mart_cooltrainer": return "Cooltrainer"
    case "viridian_forest_south_gate_girl": return "Girl"
    case "viridian_forest_south_gate_little_girl": return "Little Girl"
    case "viridian_forest_youngster_1", "viridian_forest_youngster_5": return "Youngster"
    case "viridian_forest_bug_catcher_1", "viridian_forest_bug_catcher_2", "viridian_forest_bug_catcher_3":
        return "Bug Catcher"
    case "viridian_forest_antidote": return "Antidote"
    case "viridian_forest_potion": return "Potion"
    case "viridian_forest_poke_ball": return "Poke Ball"
    case "viridian_forest_north_gate_super_nerd": return "Super Nerd"
    case "viridian_forest_north_gate_gramps": return "Gramps"
    case "viridian_pokecenter_nurse": return "Nurse"
    case "viridian_pokecenter_gentleman": return "Gentleman"
    case "viridian_pokecenter_cooltrainer": return "Cooltrainer"
    case "viridian_pokecenter_link_receptionist": return "Receptionist"
    case "oaks_lab_rival": return "Blue"
    case "oaks_lab_poke_ball_charmander": return "Charmander"
    case "oaks_lab_poke_ball_squirtle": return "Squirtle"
    case "oaks_lab_poke_ball_bulbasaur": return "Bulbasaur"
    case "oaks_lab_oak_1", "oaks_lab_oak_2": return "Oak"
    case "oaks_lab_pokedex_1", "oaks_lab_pokedex_2": return "Pokedex"
    default:
        if let pickupItemID {
            return humanizedIdentifier(pickupItemID)
        }
        if let spriteDisplayName = displayName(forSprite: sprite) {
            return spriteDisplayName
        }
        return humanizedIdentifier(objectID.isEmpty ? textID : objectID)
    }
}

private func trainerBattleIDFor(trainerClass: String?, trainerNumber: Int?) -> String? {
    guard let trainerClass, let trainerNumber else { return nil }
    return "\(trainerClass.lowercased())_\(trainerNumber)"
}

private func defaultVisibility(for objectID: String) -> Bool {
    switch objectID {
    case "pallet_town_oak", "oaks_lab_oak_2", "viridian_city_old_man_awake":
        return false
    default:
        return true
    }
}

private func dialogueID(for mapID: String, textID: String, mapScriptMetadata: MapScriptMetadata?) -> String {
    switch (mapID, textID) {
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAK"): return "pallet_town_oak_its_unsafe"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_GIRL"): return "pallet_town_girl"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_FISHER"): return "pallet_town_fisher"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAKSLAB_SIGN"): return "pallet_town_oaks_lab_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_SIGN"): return "pallet_town_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_PLAYERSHOUSE_SIGN"): return "pallet_town_players_house_sign"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_RIVALSHOUSE_SIGN"): return "pallet_town_rivals_house_sign"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM"): return "reds_house_1f_mom_wakeup"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_TV"): return "reds_house_1f_tv"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER1"): return "route_1_youngster_1_after_sample"
    case ("ROUTE_1", "TEXT_ROUTE1_YOUNGSTER2"): return "route_1_youngster_2"
    case ("ROUTE_1", "TEXT_ROUTE1_SIGN"): return "route_1_sign"
    case ("ROUTE_2", "TEXT_ROUTE2_SIGN"): return "route_2_sign"
    case ("ROUTE_2", "TEXT_ROUTE2_DIGLETTS_CAVE_SIGN"): return "route_2_digletts_cave_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER1"): return "viridian_city_youngster_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GAMBLER1"): return "viridian_city_gambler"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER2"): return "viridian_city_youngster_2_prompt"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GIRL"): return "viridian_city_girl_before_pokedex"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_SLEEPY"): return "viridian_city_old_man_private_property"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_FISHER"): return "viridian_city_fisher"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN"): return "viridian_city_old_man_had_coffee"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_SIGN"): return "viridian_city_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_TRAINER_TIPS1"): return "viridian_city_trainer_tips_1"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_TRAINER_TIPS2"): return "viridian_city_trainer_tips_2"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_MART_SIGN"): return "viridian_city_mart_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_POKECENTER_SIGN"): return "viridian_city_pokecenter_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GYM_SIGN"): return "viridian_city_gym_sign"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_GYM_LOCKED"): return "viridian_city_gym_locked"
    case ("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_OLD_MAN_YOU_NEED_TO_WEAKEN_THE_TARGET"): return "viridian_city_old_man_weaken_target"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_BRUNETTE_GIRL"): return "viridian_school_house_brunette_girl"
    case ("VIRIDIAN_SCHOOL_HOUSE", "TEXT_VIRIDIANSCHOOLHOUSE_COOLTRAINER_F"): return "viridian_school_house_cooltrainer_f"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_BALDING_GUY"): return "viridian_nickname_house_balding_guy"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_LITTLE_GIRL"): return "viridian_nickname_house_little_girl"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEAROW"): return "viridian_nickname_house_spearow"
    case ("VIRIDIAN_NICKNAME_HOUSE", "TEXT_VIRIDIANNICKNAMEHOUSE_SPEARY_SIGN"): return "viridian_nickname_house_speary_sign"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_CLERK"): return "viridian_mart_clerk_after_parcel"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_YOUNGSTER"): return "viridian_mart_youngster"
    case ("VIRIDIAN_MART", "TEXT_VIRIDIANMART_COOLTRAINER_M"): return "viridian_mart_cooltrainer"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_GIRL"): return "viridian_forest_south_gate_girl"
    case ("VIRIDIAN_FOREST_SOUTH_GATE", "TEXT_VIRIDIANFORESTSOUTHGATE_LITTLE_GIRL"): return "viridian_forest_south_gate_little_girl"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER1"): return "viridian_forest_youngster_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_YOUNGSTER5"): return "viridian_forest_youngster_5"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS1"): return "viridian_forest_trainer_tips_1"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_USE_ANTIDOTE_SIGN"): return "viridian_forest_use_antidote_sign"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS2"): return "viridian_forest_trainer_tips_2"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS3"): return "viridian_forest_trainer_tips_3"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_TRAINER_TIPS4"): return "viridian_forest_trainer_tips_4"
    case ("VIRIDIAN_FOREST", "TEXT_VIRIDIANFOREST_LEAVING_SIGN"): return "viridian_forest_leaving_sign"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_SUPER_NERD"): return "viridian_forest_north_gate_super_nerd"
    case ("VIRIDIAN_FOREST_NORTH_GATE", "TEXT_VIRIDIANFORESTNORTHGATE_GRAMPS"): return "viridian_forest_north_gate_gramps"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_GENTLEMAN"): return "viridian_pokecenter_gentleman"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_COOLTRAINER_M"): return "viridian_pokecenter_cooltrainer"
    case ("VIRIDIAN_POKECENTER", "TEXT_VIRIDIANPOKECENTER_LINK_RECEPTIONIST"): return "viridian_pokecenter_link_receptionist"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival_gramps_isnt_around"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL_GRAMPS"): return "oaks_lab_rival_gramps"
    case ("OAKS_LAB", "TEXT_OAKSLAB_CHARMANDER_POKE_BALL"),
         ("OAKS_LAB", "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL"),
         ("OAKS_LAB", "TEXT_OAKSLAB_BULBASAUR_POKE_BALL"):
        return "oaks_lab_those_are_pokeballs"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK1"): return "oaks_lab_oak_which_pokemon_do_you_want"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX1"), ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX2"):
        return "oaks_lab_pokedex"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK2"): return "oaks_lab_oak_choose_mon"
    case ("OAKS_LAB", "TEXT_OAKSLAB_GIRL"): return "oaks_lab_girl"
    case ("OAKS_LAB", "TEXT_OAKSLAB_SCIENTIST1"), ("OAKS_LAB", "TEXT_OAKSLAB_SCIENTIST2"):
        return "oaks_lab_girl"
    default:
        if let localLabel = mapScriptMetadata?.textLabelByTextID[textID] {
            switch localLabel {
            case "MartSignText":
                return "\(mapID.lowercased())_mart_sign"
            case "PokeCenterSignText":
                return "\(mapID.lowercased())_pokecenter_sign"
            default:
                break
            }
            return dialogueID(forScriptLabel: localLabel, mapScriptMetadata: mapScriptMetadata)
        }
        return "\(mapID.lowercased())_\(textID.lowercased())"
    }
}

private func martID(for mapID: String) -> String {
    mapID.lowercased()
}

private func pokemonCenterFieldInteractionID(for mapID: String) -> String {
    mapID == "VIRIDIAN_POKECENTER" ? "pokemon_center_healing" : "\(mapID.lowercased())_pokemon_center_healing"
}

private func pokemonCenterHealScriptID(for mapID: String) -> String {
    mapID == "VIRIDIAN_POKECENTER" ? "viridian_pokecenter_nurse_heal" : "\(mapID.lowercased())_nurse_heal"
}

private func wildEncounterPath(for definition: GameplayCoverageMapDefinition, repoRoot: URL) -> String? {
    let stem = URL(fileURLWithPath: definition.objectFile).deletingPathExtension().lastPathComponent
    let path = "data/wild/maps/\(stem).asm"
    let url = repoRoot.appendingPathComponent(path)
    return FileManager.default.fileExists(atPath: url.path) ? path : nil
}

private func humanizedIdentifier(_ identifier: String) -> String {
    identifier
        .lowercased()
        .split(separator: "_")
        .map { $0.capitalized }
        .joined(separator: " ")
}

private func displayName(forSprite sprite: String) -> String? {
    switch sprite {
    case "SPRITE_CLERK": return "Clerk"
    case "SPRITE_NURSE": return "Nurse"
    case "SPRITE_GENTLEMAN": return "Gentleman"
    case "SPRITE_LINK_RECEPTIONIST": return "Receptionist"
    case "SPRITE_YOUNGSTER": return "Youngster"
    case "SPRITE_SUPER_NERD": return "Super Nerd"
    case "SPRITE_COOLTRAINER_F": return "Cooltrainer"
    case "SPRITE_COOLTRAINER_M": return "Cooltrainer"
    case "SPRITE_GAMBLER": return "Gambler"
    case "SPRITE_GIRL": return "Girl"
    case "SPRITE_LITTLE_GIRL": return "Little Girl"
    case "SPRITE_MIDDLE_AGED_MAN": return "Middle Aged Man"
    case "SPRITE_MONSTER": return "Monster"
    case "SPRITE_FAIRY": return "Jigglypuff"
    case "SPRITE_SCIENTIST": return "Scientist"
    case "SPRITE_OLD_AMBER": return "Old Amber"
    case "SPRITE_HIKER": return "Hiker"
    case "SPRITE_GRAMPS": return "Gramps"
    case "SPRITE_GYM_GUIDE": return "Gym Guide"
    default:
        return nil
    }
}

private func buildDialogues(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [DialogueManifest] {
    let scriptDialogueEvents = try buildScriptDialogueEvents(repoRoot: repoRoot)
    let textContentsByMapID = try buildTextContentsByMapID(repoRoot: repoRoot)
    let pallet = try String(contentsOf: repoRoot.appendingPathComponent("text/PalletTown.asm"))
    let oaksLab = try String(contentsOf: repoRoot.appendingPathComponent("text/OaksLab.asm"))
    let redsHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/RedsHouse1F.asm"))
    let route1 = try String(contentsOf: repoRoot.appendingPathComponent("text/Route1.asm"))
    let route2 = try String(contentsOf: repoRoot.appendingPathComponent("text/Route2.asm"))
    let viridianCity = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianCity.asm"))
    let viridianSchoolHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianSchoolHouse.asm"))
    let viridianNicknameHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianNicknameHouse.asm"))
    let viridianMart = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianMart.asm"))
    let viridianForestSouthGate = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForestSouthGate.asm"))
    let viridianForest = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForest.asm"))
    let viridianForestNorthGate = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianForestNorthGate.asm"))
    let viridianPokecenter = try String(contentsOf: repoRoot.appendingPathComponent("text/ViridianPokecenter.asm"))
    let text1 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_1.asm"))
    let text2 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_2.asm"))
    let text4 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_4.asm"))
    let text6 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_6.asm"))
    let itemNamesByID = try parseItemNames(repoRoot: repoRoot)

    var dialogues: [DialogueManifest] = [
        try extractDialogue(id: "pallet_town_oak_hey_wait", label: "_PalletTownOakHeyWaitDontGoOutText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOakHeyWaitDontGoOutText"] ?? []),
        try extractDialogue(id: "pallet_town_oak_its_unsafe", label: "_PalletTownOakItsUnsafeText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOakItsUnsafeText"] ?? []),
        try extractDialogue(id: "pallet_town_girl", label: "_PalletTownGirlText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownGirlText"] ?? []),
        try extractDialogue(id: "pallet_town_fisher", label: "_PalletTownFisherText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownFisherText"] ?? []),
        try extractDialogue(id: "pallet_town_oaks_lab_sign", label: "_PalletTownOaksLabSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownOaksLabSignText"] ?? []),
        try extractDialogue(id: "pallet_town_sign", label: "_PalletTownSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownSignText"] ?? []),
        try extractDialogue(id: "pallet_town_players_house_sign", label: "_PalletTownPlayersHouseSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownPlayersHouseSignText"] ?? []),
        try extractDialogue(id: "pallet_town_rivals_house_sign", label: "_PalletTownRivalsHouseSignText", from: pallet, extraEvents: scriptDialogueEvents["_PalletTownRivalsHouseSignText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_wakeup", label: "_RedsHouse1FMomWakeUpText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomWakeUpText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_rest", label: "_RedsHouse1FMomYouShouldRestText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomYouShouldRestText"] ?? []),
        try extractDialogue(id: "reds_house_1f_mom_looking_great", label: "_RedsHouse1FMomLookingGreatText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FMomLookingGreatText"] ?? []),
        try extractDialogue(id: "reds_house_1f_tv", label: "_RedsHouse1FTVStandByMeMovieText", from: redsHouse, extraEvents: scriptDialogueEvents["_RedsHouse1FTVStandByMeMovieText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_mart_sample", label: "_Route1Youngster1MartSampleText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1MartSampleText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_got_potion", label: "_Route1Youngster1GotPotionText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1GotPotionText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_after_sample", label: "_Route1Youngster1AlsoGotPokeballsText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1AlsoGotPokeballsText"] ?? []),
        try extractDialogue(id: "route_1_youngster_1_no_room", label: "_Route1Youngster1NoRoomText", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster1NoRoomText"] ?? []),
        try extractDialogue(id: "route_1_youngster_2", label: "_Route1Youngster2Text", from: route1, extraEvents: scriptDialogueEvents["_Route1Youngster2Text"] ?? []),
        try extractDialogue(id: "route_1_sign", label: "_Route1SignText", from: route1, extraEvents: scriptDialogueEvents["_Route1SignText"] ?? []),
        try extractDialogue(id: "route_2_sign", label: "_Route2SignText", from: route2),
        try extractDialogue(id: "route_2_digletts_cave_sign", label: "_Route2DiglettsCaveSignText", from: route2),
        try extractDialogue(id: "viridian_city_youngster_1", label: "_ViridianCityYoungster1Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityYoungster1Text"] ?? []),
        try extractDialogue(id: "viridian_city_gambler", label: "_ViridianCityGambler1GymAlwaysClosedText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGambler1GymAlwaysClosedText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_prompt", label: "_ViridianCityYoungster2YouWantToKnowAboutText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityYoungster2YouWantToKnowAboutText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_ok_then", label: "ViridianCityYoungster2OkThenText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityYoungster2OkThenText"] ?? []),
        try extractDialogue(id: "viridian_city_youngster_2_description", label: "ViridianCityYoungster2CaterpieAndWeedleDescriptionText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityYoungster2CaterpieAndWeedleDescriptionText"] ?? []),
        try extractDialogue(id: "viridian_city_girl_before_pokedex", label: "_ViridianCityGirlHasntHadHisCoffeeYetText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGirlHasntHadHisCoffeeYetText"] ?? []),
        try extractDialogue(id: "viridian_city_girl_after_pokedex", label: "_ViridianCityGirlWhenIGoShopText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGirlWhenIGoShopText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_private_property", label: "_ViridianCityOldManSleepyPrivatePropertyText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManSleepyPrivatePropertyText"] ?? []),
        try extractDialogue(id: "viridian_city_fisher", label: "ViridianCityFisherYouCanHaveThisText", from: viridianCity, extraEvents: scriptDialogueEvents["ViridianCityFisherYouCanHaveThisText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_had_coffee", label: "_ViridianCityOldManHadMyCoffeeNowText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManHadMyCoffeeNowText"] ?? []),
        try extractDialogue(id: "viridian_city_old_man_weaken_target", label: "_ViridianCityOldManYouNeedToWeakenTheTargetText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityOldManYouNeedToWeakenTheTargetText"] ?? []),
        try extractDialogue(id: "viridian_city_sign", label: "_ViridianCitySignText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCitySignText"] ?? []),
        try extractDialogue(id: "viridian_city_trainer_tips_1", label: "_ViridianCityTrainerTips1Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityTrainerTips1Text"] ?? []),
        try extractDialogue(id: "viridian_city_trainer_tips_2", label: "_ViridianCityTrainerTips2Text", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityTrainerTips2Text"] ?? []),
        try extractDialogue(id: "viridian_city_gym_sign", label: "_ViridianCityGymSignText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGymSignText"] ?? []),
        try extractDialogue(id: "viridian_city_gym_locked", label: "_ViridianCityGymLockedText", from: viridianCity, extraEvents: scriptDialogueEvents["_ViridianCityGymLockedText"] ?? []),
        DialogueManifest(id: "viridian_city_mart_sign", pages: [.init(lines: ["#MON MART"], waitsForPrompt: true)]),
        DialogueManifest(id: "viridian_city_pokecenter_sign", pages: [.init(lines: ["#MON CENTER"], waitsForPrompt: true)]),
        try extractDialogue(id: "viridian_school_house_brunette_girl", label: "_ViridianSchoolHouseBrunetteGirlText", from: viridianSchoolHouse),
        try extractDialogue(id: "viridian_school_house_cooltrainer_f", label: "_ViridianSchoolHouseCooltrainerFText", from: viridianSchoolHouse),
        try extractDialogue(id: "viridian_nickname_house_balding_guy", label: "_ViridianNicknameHouseBaldingGuyText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_little_girl", label: "_ViridianNicknameHouseLittleGirlText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_spearow", label: "_ViridianNicknameHouseSpearowText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_nickname_house_speary_sign", label: "_ViridianNicknameHouseSpearySignText", from: viridianNicknameHouse),
        try extractDialogue(id: "viridian_mart_clerk_you_came_from_pallet_town", label: "_ViridianMartClerkYouCameFromPalletTownText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkYouCameFromPalletTownText"] ?? []),
        try extractDialogue(id: "viridian_mart_clerk_parcel_quest", label: "_ViridianMartClerkParcelQuestText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkParcelQuestText"] ?? []),
        try extractDialogue(id: "viridian_mart_clerk_after_parcel", label: "_ViridianMartClerkSayHiToOakText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartClerkSayHiToOakText"] ?? []),
        try extractDialogue(id: "viridian_mart_youngster", label: "_ViridianMartYoungsterText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartYoungsterText"] ?? []),
        try extractDialogue(id: "viridian_mart_cooltrainer", label: "_ViridianMartCooltrainerMText", from: viridianMart, extraEvents: scriptDialogueEvents["_ViridianMartCooltrainerMText"] ?? []),
        try extractDialogue(id: "viridian_forest_south_gate_girl", label: "_ViridianForestSouthGateGirlText", from: viridianForestSouthGate),
        try extractDialogue(id: "viridian_forest_south_gate_little_girl", label: "_ViridianForestSouthGateLittleGirlText", from: viridianForestSouthGate),
        try extractDialogue(id: "viridian_forest_youngster_1", label: "_ViridianForestYoungster1Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_youngster_5", label: "_ViridianForestYoungster5Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_1", label: "_ViridianForestTrainerTips1Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_use_antidote_sign", label: "_ViridianForestUseAntidoteSignText", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_2", label: "_ViridianForestTrainerTips2Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_3", label: "_ViridianForestTrainerTips3Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_trainer_tips_4", label: "_ViridianForestTrainerTips4Text", from: viridianForest),
        try extractDialogue(id: "viridian_forest_leaving_sign", label: "_ViridianForestLeavingSignText", from: viridianForest),
        try extractDialogue(id: "viridian_forest_north_gate_super_nerd", label: "_ViridianForestNorthGateSuperNerdText", from: viridianForestNorthGate),
        try extractDialogue(id: "viridian_forest_north_gate_gramps", label: "_ViridianForestNorthGateGrampsText", from: viridianForestNorthGate),
        try extractDialogue(id: "pickup_no_room", label: "_NoMoreRoomForItemText", from: text1),
        try extractDialogue(id: "pokemart_greeting", label: "_PokemartGreetingText", from: text4),
        try extractDialogue(id: "pokemart_buying_greeting", label: "_PokemartBuyingGreetingText", from: text4),
        try extractDialogue(id: "pokemart_bought_item", label: "_PokemartBoughtItemText", from: text4),
        try extractDialogue(id: "pokemart_not_enough_money", label: "_PokemartNotEnoughMoneyText", from: text4),
        try extractDialogue(id: "pokemart_item_bag_full", label: "_PokemartItemBagFullText", from: text4),
        try extractDialogue(id: "pokemart_selling_greeting", label: "_PokemonSellingGreetingText", from: text4),
        try extractDialogue(id: "pokemart_item_bag_empty", label: "_PokemartItemBagEmptyText", from: text4),
        try extractDialogue(id: "pokemart_unsellable_item", label: "_PokemartUnsellableItemText", from: text4),
        try extractDialogue(id: "pokemart_thank_you", label: "_PokemartThankYouText", from: text4),
        try extractDialogue(id: "pokemart_anything_else", label: "_PokemartAnythingElseText", from: text4),
        try extractDialogue(id: "pokemon_center_welcome", label: "_PokemonCenterWelcomeText", from: text4),
        try extractDialogue(id: "pokemon_center_shall_we_heal", label: "_ShallWeHealYourPokemonText", from: text4),
        try extractDialogue(id: "pokemon_center_need_your_pokemon", label: "_NeedYourPokemonText", from: text4),
        try extractDialogue(id: "pokemon_center_fighting_fit", label: "_PokemonFightingFitText", from: text4),
        try extractDialogue(id: "pokemon_center_farewell", label: "_PokemonCenterFarewellText", from: text4),
        try extractDialogue(id: "capture_uncatchable", label: "_ItemUseBallText00", from: text6),
        try extractDialogue(id: "capture_missed", label: "_ItemUseBallText01", from: text6),
        try extractDialogue(id: "capture_broke_free", label: "_ItemUseBallText02", from: text6),
        try extractDialogue(id: "capture_almost", label: "_ItemUseBallText03", from: text6),
        try extractDialogue(id: "capture_so_close", label: "_ItemUseBallText04", from: text6),
        try extractDialogue(id: "viridian_pokecenter_gentleman", label: "_ViridianPokecenterGentlemanText", from: viridianPokecenter, extraEvents: scriptDialogueEvents["_ViridianPokecenterGentlemanText"] ?? []),
        try extractDialogue(id: "viridian_pokecenter_cooltrainer", label: "_ViridianPokecenterCooltrainerMText", from: viridianPokecenter, extraEvents: scriptDialogueEvents["_ViridianPokecenterCooltrainerMText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_gramps_isnt_around", label: "_OaksLabRivalGrampsIsntAroundText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalGrampsIsntAroundText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_go_ahead_and_choose", label: "_OaksLabRivalGoAheadAndChooseText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalGoAheadAndChooseText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_my_pokemon_looks_stronger", label: "_OaksLabRivalMyPokemonLooksStrongerText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalMyPokemonLooksStrongerText"] ?? []),
        try extractDialogue(id: "oaks_lab_those_are_pokeballs", label: "_OaksLabThoseArePokeBallsText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabThoseArePokeBallsText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_charmander", label: "_OaksLabYouWantCharmanderText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantCharmanderText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_squirtle", label: "_OaksLabYouWantSquirtleText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantSquirtleText"] ?? []),
        try extractDialogue(id: "oaks_lab_you_want_bulbasaur", label: "_OaksLabYouWantBulbasaurText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabYouWantBulbasaurText"] ?? []),
        try extractDialogue(id: "oaks_lab_mon_energetic", label: "_OaksLabMonEnergeticText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabMonEnergeticText"] ?? []),
        try extractDialogue(id: "oaks_lab_last_mon", label: "_OaksLabLastMonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabLastMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_which_pokemon_do_you_want", label: "_OaksLabOak1WhichPokemonDoYouWantText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1WhichPokemonDoYouWantText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_raise_your_young_pokemon", label: "_OaksLabOak1RaiseYourYoungPokemonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1RaiseYourYoungPokemonText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_deliver_parcel", label: "_OaksLabOak1DeliverParcelText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1DeliverParcelText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_parcel_thanks", label: "_OaksLabOak1ParcelThanksText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1ParcelThanksText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_pokemon_around_the_world", label: "_OaksLabOak1PokemonAroundTheWorldText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1PokemonAroundTheWorldText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_come_see_me_sometimes", label: "_OaksLabOak1ComeSeeMeSometimesText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1ComeSeeMeSometimesText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_how_is_your_pokedex_coming", label: "_OaksLabOak1HowIsYourPokedexComingText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOak1HowIsYourPokedexComingText"] ?? []),
        try extractDialogue(id: "oaks_lab_pokedex", label: "_OaksLabPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_girl", label: "_OaksLabGirlText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabGirlText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_fed_up_with_waiting", label: "_OaksLabRivalFedUpWithWaitingText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalFedUpWithWaitingText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_choose_mon", label: "_OaksLabOakChooseMonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakChooseMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_what_about_me", label: "_OaksLabRivalWhatAboutMeText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalWhatAboutMeText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_be_patient", label: "_OaksLabOakBePatientText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakBePatientText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_dont_go_away_yet", label: "_OaksLabOakDontGoAwayYetText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakDontGoAwayYetText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_ill_take_this_one", label: "_OaksLabRivalIllTakeThisOneText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIllTakeThisOneText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_charmander", speciesName: "CHARMANDER", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_squirtle", speciesName: "SQUIRTLE", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeReceivedDialogue(id: "oaks_lab_received_mon_bulbasaur", speciesName: "BULBASAUR", events: scriptDialogueEvents["_OaksLabReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_charmander", speciesName: "CHARMANDER", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_squirtle", speciesName: "SQUIRTLE", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_bulbasaur", speciesName: "BULBASAUR", events: scriptDialogueEvents["_OaksLabRivalReceivedMonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_ill_take_you_on", label: "_OaksLabRivalIllTakeYouOnText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIllTakeYouOnText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_i_picked_the_wrong_pokemon", label: "_OaksLabRivalIPickedTheWrongPokemonText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalIPickedTheWrongPokemonText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_am_i_great_or_what", label: "_OaksLabRivalAmIGreatOrWhatText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalAmIGreatOrWhatText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_smell_you_later", label: "_OaksLabRivalSmellYouLaterText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalSmellYouLaterText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_gramps", label: "_OaksLabRivalGrampsText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_what_did_you_call_me_for", label: "_OaksLabRivalWhatDidYouCallMeForText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalWhatDidYouCallMeForText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_i_have_a_request", label: "_OaksLabOakIHaveARequestText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakIHaveARequestText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_my_invention_pokedex", label: "_OaksLabOakMyInventionPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakMyInventionPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_got_pokedex", label: "_OaksLabOakGotPokedexText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakGotPokedexText"] ?? []),
        try extractDialogue(id: "oaks_lab_oak_that_was_my_dream", label: "_OaksLabOakThatWasMyDreamText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabOakThatWasMyDreamText"] ?? []),
        try extractDialogue(id: "oaks_lab_rival_leave_it_all_to_me", label: "_OaksLabRivalLeaveItAllToMeText", from: oaksLab, extraEvents: scriptDialogueEvents["_OaksLabRivalLeaveItAllToMeText"] ?? []),
        try extractDialogue(id: "rival_1_win_text", label: "_Rival1WinText", from: text2, extraEvents: scriptDialogueEvents["_Rival1WinText"] ?? []),
    ]

    dialogues.append(contentsOf: try buildCoverageMapDialogues(
        textContentsByMapID: textContentsByMapID,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID,
        scriptDialogueEvents: scriptDialogueEvents
    ))
    dialogues.append(contentsOf: try buildStandardTrainerDialogues(
        mapIDs: gameplayCoverageMaps.map(\.mapID),
        textContentsByMapID: textContentsByMapID,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID
    ))
    dialogues.append(contentsOf: buildPickupFoundDialogues(
        itemIDs: referencedVisiblePickupItemIDs(repoRoot: repoRoot),
        itemNamesByID: itemNamesByID
    ))

    var dialogueByID: [String: DialogueManifest] = [:]
    for dialogue in dialogues where dialogueByID[dialogue.id] == nil {
        dialogueByID[dialogue.id] = dialogue
    }
    return dialogueByID.values.sorted { $0.id < $1.id }
}

private func buildCoverageMapDialogues(
    textContentsByMapID: [String: String],
    mapScriptMetadataByMapID: [String: MapScriptMetadata],
    scriptDialogueEvents: [String: [DialogueEvent]]
) throws -> [DialogueManifest] {
    var dialogueByID: [String: DialogueManifest] = [:]

    for definition in gameplayCoverageMaps {
        guard
            let metadata = mapScriptMetadataByMapID[definition.mapID],
            let textContents = textContentsByMapID[definition.mapID]
        else {
            continue
        }

        for (textID, localLabel) in metadata.textLabelByTextID.sorted(by: { $0.key < $1.key }) {
            if let specialDialogue = specialCoverageDialogue(
                mapID: definition.mapID,
                textID: textID,
                localLabel: localLabel,
                mapScriptMetadata: metadata
            ) {
                dialogueByID[specialDialogue.id] = specialDialogue
                continue
            }

            let resolvedLabel = metadata.farTextLabelByLocalLabel[localLabel] ?? localLabel
            guard let dialogue = try extractDialogueIfPresent(
                id: dialogueID(for: definition.mapID, textID: textID, mapScriptMetadata: metadata),
                label: resolvedLabel,
                from: textContents,
                extraEvents: scriptDialogueEvents[resolvedLabel] ?? []
            ) else {
                continue
            }
            dialogueByID[dialogue.id] = dialogue
        }

        for farLabel in metadata.referencedFarTextLabels.sorted() {
            let dialogueID = normalizedDialogueID(from: farLabel)
            guard dialogueByID[dialogueID] == nil,
                  let dialogue = try extractDialogueIfPresent(
                      id: dialogueID,
                      label: farLabel,
                      from: textContents,
                      extraEvents: scriptDialogueEvents[farLabel] ?? []
                  ) else {
                continue
            }
            dialogueByID[dialogue.id] = dialogue
        }
    }

    return dialogueByID.values.sorted { $0.id < $1.id }
}

private func specialCoverageDialogue(
    mapID: String,
    textID: String,
    localLabel: String,
    mapScriptMetadata: MapScriptMetadata
) -> DialogueManifest? {
    let line: String
    switch localLabel {
    case "MartSignText":
        line = "#MON MART"
    case "PokeCenterSignText":
        line = "#MON CENTER"
    default:
        return nil
    }

    return DialogueManifest(
        id: dialogueID(for: mapID, textID: textID, mapScriptMetadata: mapScriptMetadata),
        pages: [.init(lines: [line], waitsForPrompt: true)]
    )
}

private func extractDialogueIfPresent(
    id: String,
    label: String,
    from contents: String,
    extraEvents: [DialogueEvent] = []
) throws -> DialogueManifest? {
    guard dialogueLabelExists(label, in: contents) else {
        return nil
    }
    return try extractDialogue(id: id, label: label, from: contents, extraEvents: extraEvents)
}

private func dialogueLabelExists(_ label: String, in contents: String) -> Bool {
    contents.range(of: "\(label)::") != nil || contents.range(of: "\(label):") != nil
}

private func buildFieldInteractions(maps: [MapManifest], repoRoot: URL) throws -> [FieldInteractionManifest] {
    try maps.compactMap { map in
        guard let nurseObject = map.objects.first(where: { $0.sprite == "SPRITE_NURSE" }) else {
            return nil
        }

        return FieldInteractionManifest(
            id: pokemonCenterFieldInteractionID(for: map.id),
            kind: .pokemonCenterHealing,
            introDialogueID: "pokemon_center_welcome",
            prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
            acceptedDialogueID: "pokemon_center_need_your_pokemon",
            successDialogueID: "pokemon_center_fighting_fit",
            farewellDialogueID: "pokemon_center_farewell",
            healingSequence: .init(
                nurseObjectID: nurseObject.id,
                machineSoundEffectID: "SFX_HEALING_MACHINE",
                healedAudioCueID: "pokemon_center_healed",
                blackoutCheckpoint: try blackoutCheckpointForPokemonCenter(
                    mapID: map.id,
                    maps: maps,
                    repoRoot: repoRoot
                )
            )
        )
    }
}

private func blackoutCheckpointForPokemonCenter(
    mapID: String,
    maps: [MapManifest],
    repoRoot: URL
) throws -> BlackoutCheckpointManifest? {
    guard let overworldMapID = maps
        .first(where: { $0.id == mapID })?
        .warps
        .first?
        .targetMapID else {
        return nil
    }

    return try parseFlyWarpCheckpoint(repoRoot: repoRoot, mapID: overworldMapID)
}

private func buildPlayerStart(repoRoot: URL) throws -> PlayerStartManifest {
    PlayerStartManifest(
        mapID: "REDS_HOUSE_2F",
        position: .init(x: 4, y: 4),
        facing: .down,
        playerName: "RED",
        rivalName: "BLUE",
        initialFlags: [],
        defaultBlackoutCheckpoint: try parseFlyWarpCheckpoint(repoRoot: repoRoot, mapID: "PALLET_TOWN")
    )
}

private func parseFlyWarpCheckpoint(repoRoot: URL, mapID: String) throws -> BlackoutCheckpointManifest? {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/maps/special_warps.asm"))
    let labelToken = mapID
        .split(separator: "_")
        .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        .joined()

    let pattern = #"\.\#(labelToken):\s+fly_warp\s+\#(mapID),\s+(\d+),\s+(\d+)"#
    let regex = try NSRegularExpression(pattern: pattern)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    guard let match = regex.firstMatch(in: contents, range: nsRange),
          let xRange = Range(match.range(at: 1), in: contents),
          let yRange = Range(match.range(at: 2), in: contents) else {
        return nil
    }

    return BlackoutCheckpointManifest(
        mapID: mapID,
        position: .init(x: Int(contents[xRange]) ?? 0, y: Int(contents[yRange]) ?? 0),
        facing: .down
    )
}

private func buildScriptDialogueEvents(repoRoot: URL) throws -> [String: [DialogueEvent]] {
    let scriptPaths = gameplayCoverageMaps
        .map(scriptPathForMap)
        .filter { FileManager.default.fileExists(atPath: repoRoot.appendingPathComponent($0).path) }

    var eventsByTextLabel: [String: [DialogueEvent]] = [:]

    for path in scriptPaths {
        let contents = try String(contentsOf: repoRoot.appendingPathComponent(path))
        var currentTextLabel: String?

        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasSuffix(":") {
                currentTextLabel = nil
                continue
            }

            if let match = line.firstMatch(of: /text_far\s+([A-Za-z0-9_\.]+)/) {
                currentTextLabel = String(match.output.1)
                continue
            }

            if let event = dialogueEvent(for: line), let currentTextLabel {
                eventsByTextLabel[currentTextLabel, default: []].append(event)
                continue
            }

            if line == "text_end" || line == "text" {
                currentTextLabel = nil
            }
        }
    }

    return eventsByTextLabel
}

private func extractDialogue(id: String, label: String, from contents: String, extraEvents: [DialogueEvent] = []) throws -> DialogueManifest {
    guard let range = contents.range(of: "\(label)::") ?? contents.range(of: "\(label):") else {
        throw ExtractorError.invalidArguments("missing dialogue label \(label)")
    }

    let tail = contents[range.upperBound...]
    var lines: [String] = []
    var events: [DialogueEvent] = []
    var pages: [DialoguePage] = []

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if let labelMatch = line.firstMatch(of: /^([A-Za-z0-9_\.]+)::?$/),
           String(labelMatch.output.1) != label {
            break
        }
        if line.hasPrefix("text \"") || line.hasPrefix("line \"") || line.hasPrefix("cont \"") || line.hasPrefix("para \"") {
            let value = extractQuotedString(from: line)
            if line.hasPrefix("para ") && lines.isEmpty == false {
                pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
                lines = []
                events = []
            }
            lines.append(value)
            if lines.count == 4 {
                pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
                lines = []
                events = []
            }
        } else if line.hasPrefix("text_ram") {
            lines.append("<NAME>")
        } else if let event = dialogueEvent(for: line) {
            events.append(event)
        } else if line == "done" || line == "prompt" || line == "text_end" {
            if lines.isEmpty == false {
                pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
                lines = []
                events = []
            }
            if line == "text_end" || line == "done" || line == "prompt" {
                break
            }
        }
    }

    if lines.isEmpty == false {
        pages.append(.init(lines: lines, waitsForPrompt: true, events: events))
    }

    if extraEvents.isEmpty == false, pages.isEmpty == false {
        let lastIndex = pages.index(before: pages.endIndex)
        let lastPage = pages[lastIndex]
        pages[lastIndex] = .init(
            lines: lastPage.lines,
            waitsForPrompt: lastPage.waitsForPrompt,
            events: lastPage.events + extraEvents
        )
    }
    return DialogueManifest(id: id, pages: pages)
}

private func makeReceivedDialogue(id: String, speciesName: String, events: [DialogueEvent] = []) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<PLAYER> received", speciesName + "!"], waitsForPrompt: true, events: events)])
}

private func makeRivalReceivedDialogue(id: String, speciesName: String, events: [DialogueEvent] = []) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<RIVAL> received", speciesName + "!"], waitsForPrompt: true, events: events)])
}

private func buildStandardTrainerDialogues(
    mapIDs: [String],
    textContentsByMapID: [String: String],
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [DialogueManifest] {
    var dialogueByID: [String: DialogueManifest] = [:]

    for mapID in mapIDs {
        guard
            let metadata = mapScriptMetadataByMapID[mapID],
            metadata.usesStandardTrainerLoop,
            let textContents = textContentsByMapID[mapID]
        else {
            continue
        }

        for trainerHeader in metadata.trainerHeadersByLabel.values {
            for localLabel in [
                trainerHeader.battleTextLabel,
                trainerHeader.endBattleTextLabel,
                trainerHeader.afterBattleTextLabel,
            ] {
                let farLabel = metadata.farTextLabelByLocalLabel[localLabel] ?? localLabel
                let dialogueID = normalizedDialogueID(from: farLabel)
                if dialogueByID[dialogueID] != nil {
                    continue
                }
                dialogueByID[dialogueID] = try extractDialogue(id: dialogueID, label: farLabel, from: textContents)
            }
        }
    }

    return dialogueByID.values.sorted { $0.id < $1.id }
}

private func referencedVisiblePickupItemIDs(repoRoot: URL) -> [String] {
    var itemIDs: Set<String> = []

    for definition in gameplayCoverageMaps {
        let objectURL = repoRoot.appendingPathComponent(definition.objectFile)
        guard let contents = try? String(contentsOf: objectURL) else { continue }
        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("object_event"), line.contains("SPRITE_POKE_BALL") else { continue }
            let tokens = line
                .replacingOccurrences(of: "object_event", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard tokens.count >= 7 else { continue }
            itemIDs.insert(tokens[6])
        }
    }

    return itemIDs.sorted()
}

private func buildPickupFoundDialogues(
    itemIDs: [String],
    itemNamesByID: [String: String]
) -> [DialogueManifest] {
    itemIDs.map { itemID in
        DialogueManifest(
            id: pickupFoundDialogueID(for: itemID),
            pages: [.init(
                lines: ["<PLAYER> found", "\(itemNamesByID[itemID] ?? itemID)!"],
                waitsForPrompt: true,
                events: [.init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")]
            )]
        )
    }
}

private func pickupFoundDialogueID(for itemID: String) -> String {
    "pickup_found_\(itemID.lowercased())"
}

private func dialogueEvent(for line: String) -> DialogueEvent? {
    switch line {
    case "sound_get_item_1", "sound_level_up":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_1")
    case "sound_get_item_2":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_ITEM_2")
    case "sound_get_key_item":
        return .init(kind: .soundEffect, soundEffectID: "SFX_GET_KEY_ITEM")
    case "sound_caught_mon":
        return .init(kind: .soundEffect, soundEffectID: "SFX_CAUGHT_MON")
    case "sound_dex_page_added":
        return .init(kind: .soundEffect, soundEffectID: "SFX_DEX_PAGE_ADDED")
    case "sound_cry_nidorina":
        return .init(kind: .cry, speciesID: "NIDORINA")
    case "sound_cry_pidgeot":
        return .init(kind: .cry, speciesID: "PIDGEOT")
    case "sound_cry_dewgong":
        return .init(kind: .cry, speciesID: "DEWGONG")
    default:
        return nil
    }
}

private func extractQuotedString(from line: String) -> String {
    guard let firstQuote = line.firstIndex(of: "\""),
          let lastQuote = line.lastIndex(of: "\""),
          firstQuote < lastQuote
    else {
        return line
    }
    let raw = String(line[line.index(after: firstQuote)..<lastQuote])
    return raw
        .replacingOccurrences(of: "@", with: "")
        .replacingOccurrences(of: "#", with: "POKé")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func buildMapScripts() -> [MapScriptManifest] {
    [
        MapScriptManifest(
            mapID: "PALLET_TOWN",
            triggers: [
                .init(
                    id: "north_exit_oak_intro",
                    scriptID: "pallet_town_oak_intro",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                        .init(kind: "playerYEquals", intValue: 1),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "VIRIDIAN_CITY",
            triggers: [
                .init(
                    id: "gym_locked_pushback",
                    scriptID: "viridian_city_gym_locked_pushback",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_VIRIDIAN_GYM_OPEN"),
                        .init(kind: "playerYEquals", intValue: 8),
                        .init(kind: "playerXEquals", intValue: 32),
                    ]
                ),
                .init(
                    id: "old_man_blocks_north_exit",
                    scriptID: "viridian_city_old_man_blocks_north_exit",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_POKEDEX"),
                        .init(kind: "playerYEquals", intValue: 9),
                        .init(kind: "playerXEquals", intValue: 19),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "VIRIDIAN_MART",
            triggers: [
                .init(
                    id: "oaks_parcel_entry",
                    scriptID: "viridian_mart_oaks_parcel",
                    conditions: [
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_OAKS_PARCEL"),
                        .init(kind: "playerYEquals", intValue: 7),
                    ]
                ),
            ]
        ),
        MapScriptManifest(
            mapID: "OAKS_LAB",
            triggers: [
                .init(
                    id: "dont_go_away_before_starter",
                    scriptID: "oaks_lab_dont_go_away",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON"),
                        .init(kind: "flagUnset", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "playerYEquals", intValue: 6),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_charmander",
                    scriptID: "oaks_lab_rival_challenge_vs_squirtle",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "CHARMANDER"),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_squirtle",
                    scriptID: "oaks_lab_rival_challenge_vs_bulbasaur",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "SQUIRTLE"),
                    ]
                ),
                .init(
                    id: "rival_challenge_after_bulbasaur",
                    scriptID: "oaks_lab_rival_challenge_vs_charmander",
                    conditions: [
                        .init(kind: "flagSet", flagID: "EVENT_GOT_STARTER"),
                        .init(kind: "flagUnset", flagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"),
                        .init(kind: "playerYEquals", intValue: 6),
                        .init(kind: "chosenStarterEquals", stringValue: "BULBASAUR"),
                    ]
                ),
            ]
        ),
    ]
}

private func buildScripts(repoRoot: URL, maps: [MapManifest]) throws -> [ScriptManifest] {
    let autoMovement = try String(contentsOf: repoRoot.appendingPathComponent("engine/overworld/auto_movement.asm"))
    let oaksLabScripts = try String(contentsOf: repoRoot.appendingPathComponent("scripts/OaksLab.asm"))

    let palletOakEscortPath = try parseRepeatedMovementLabel("RLEList_ProfOakWalkToLab", from: autoMovement)
    let palletPlayerEscortPath = try parseSimulatedJoypadMovementLabel("RLEList_PlayerWalkToLab", from: autoMovement)
    let oakEntryPath = try parseMovementLabel("OakEntryMovement", from: oaksLabScripts)
    let playerEntryPath = try parseSimulatedJoypadMovementLabel("PlayerEntryMovementRLE", from: oaksLabScripts)
    let rivalMiddleBall1 = try parseMovementLabel(".MiddleBallMovement1", from: oaksLabScripts)
    let rivalMiddleBall2 = try parseMovementLabel(".MiddleBallMovement2", from: oaksLabScripts)
    let rivalRightBall1 = try parseMovementLabel(".RightBallMovement1", from: oaksLabScripts)
    let rivalRightBall2 = try parseMovementLabel(".RightBallMovement2", from: oaksLabScripts)
    let rivalLeftBall1 = try parseMovementLabel(".LeftBallMovement1", from: oaksLabScripts)
    let rivalLeftBall2 = try parseMovementLabel(".LeftBallMovement2", from: oaksLabScripts)
    let rivalExitPath = try parseMovementLabel(".RivalExitMovement", from: oaksLabScripts)

    var scripts: [ScriptManifest] = [
        ScriptManifest(
            id: "reds_house_1f_mom_heal",
            steps: [
                .init(action: "healParty"),
                .init(action: "showDialogue", dialogueID: "reds_house_1f_mom_looking_great"),
            ]
        ),
        ScriptManifest(
            id: "viridian_pokecenter_nurse_heal",
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: "pokemon_center_healing"),
            ]
        ),
        ScriptManifest(
            id: "route_1_potion_sample",
            steps: [
                .init(action: "showDialogue", dialogueID: "route_1_youngster_1_mart_sample"),
                .init(action: "addItem", stringValue: "POTION", intValue: 1),
                .init(action: "showDialogue", dialogueID: "route_1_youngster_1_got_potion"),
                .init(action: "setFlag", flagID: "EVENT_GOT_POTION_SAMPLE"),
            ]
        ),
        ScriptManifest(
            id: "viridian_city_old_man_blocks_north_exit",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_city_old_man_private_property"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "viridian_city_gym_locked_pushback",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_city_gym_locked"),
                .init(action: "movePlayer", path: [.down]),
            ]
        ),
        ScriptManifest(
            id: "viridian_mart_oaks_parcel",
            steps: [
                .init(action: "showDialogue", dialogueID: "viridian_mart_clerk_you_came_from_pallet_town"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.left, .up, .up])]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "viridian_mart_clerk_parcel_quest"),
                .init(action: "addItem", stringValue: "OAKS_PARCEL", intValue: 1),
                .init(action: "setFlag", flagID: "EVENT_GOT_OAKS_PARCEL"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_parcel_handoff",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_deliver_parcel"),
                .init(action: "removeItem", stringValue: "OAKS_PARCEL", intValue: 1),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_parcel_thanks"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 8, y: 3), objectID: "oaks_lab_rival"),
                .init(action: "faceObject", stringValue: "left", objectID: "oaks_lab_rival"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_gramps"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_what_did_you_call_me_for"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_i_have_a_request"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_my_invention_pokedex"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_got_pokedex"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_pokedex_1", visible: false),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_pokedex_2", visible: false),
                .init(action: "setFlag", flagID: "EVENT_GOT_POKEDEX"),
                .init(action: "setFlag", flagID: "EVENT_OAK_GOT_PARCEL"),
                .init(action: "setObjectVisibility", objectID: "viridian_city_old_man_sleepy", visible: false),
                .init(action: "setObjectVisibility", objectID: "viridian_city_old_man_awake", visible: true),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_that_was_my_dream"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_leave_it_all_to_me"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: false),
                .init(action: "setFlag", flagID: "EVENT_1ST_ROUTE22_RIVAL_BATTLE"),
                .init(action: "clearFlag", flagID: "EVENT_2ND_ROUTE22_RIVAL_BATTLE"),
                .init(action: "setFlag", flagID: "EVENT_ROUTE22_RIVAL_WANTS_BATTLE"),
                .init(action: "restoreMapMusic"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_charmander",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_charmander"),
                .init(action: "startStarterChoice", stringValue: "CHARMANDER"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_squirtle",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_squirtle"),
                .init(action: "startStarterChoice", stringValue: "SQUIRTLE"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_choose_bulbasaur",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_you_want_bulbasaur"),
                .init(action: "startStarterChoice", stringValue: "BULBASAUR"),
            ]
        ),
        ScriptManifest(
            id: "pallet_town_oak_intro",
            steps: [
                .init(action: "setFlag", flagID: "EVENT_OAK_APPEARED_IN_PALLET"),
                .init(action: "playMusicCue", stringValue: "oak_intro"),
                .init(action: "setObjectVisibility", objectID: "pallet_town_oak", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 8, y: 5), objectID: "pallet_town_oak"),
                .init(action: "faceObject", stringValue: "down", objectID: "pallet_town_oak"),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_hey_wait"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.down])]
                    )
                ),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "pallet_town_oak", path: [])],
                        targetPlayerOffset: .init(x: 0, y: 1)
                    )
                ),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_its_unsafe"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .palletEscort,
                        variants: [
                            .init(
                                id: "player_left_lane",
                                conditions: [.init(kind: "playerXEquals", intValue: 10)],
                                actors: [
                                    .init(actorID: "pallet_town_oak", path: palletOakEscortPath),
                                    .init(actorID: "player", path: palletPlayerEscortPath),
                                ]
                            ),
                            .init(
                                id: "player_right_lane",
                                conditions: [.init(kind: "playerXEquals", intValue: 11)],
                                actors: [
                                    .init(actorID: "pallet_town_oak", path: [.left] + palletOakEscortPath),
                                    .init(actorID: "player", path: [.left] + palletPlayerEscortPath),
                                ]
                            ),
                        ]
                    )
                ),
                .init(action: "setObjectVisibility", objectID: "pallet_town_oak", visible: false),
                .init(action: "setMap", stringValue: "OAKS_LAB", point: .init(x: 5, y: 11)),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_2", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 5, y: 10), objectID: "oaks_lab_oak_2"),
                .init(action: "faceObject", stringValue: "up", objectID: "oaks_lab_oak_2"),
                .init(action: "restoreMapMusic"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "oaks_lab_oak_2", path: oakEntryPath)]
                    )
                ),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_2", visible: false),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_oak_1", visible: true),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_oak_1"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: playerEntryPath)]
                    )
                ),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB_2"),
                .init(action: "faceObject", stringValue: "up", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_fed_up_with_waiting"),
                .init(action: "setFlag", flagID: "EVENT_OAK_ASKED_TO_CHOOSE_MON"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_choose_mon"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_what_about_me"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_be_patient"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_dont_go_away",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_oak_1"),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_dont_go_away_yet"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "player", path: [.up])]
                    )
                ),
                .init(action: "facePlayer", stringValue: "up"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_charmander",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_below_table",
                                conditions: [.init(kind: "playerYEquals", intValue: 4)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalMiddleBall1)]
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalMiddleBall2)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_squirtle", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_squirtle"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_squirtle",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_below_table",
                                conditions: [.init(kind: "playerYEquals", intValue: 4)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalRightBall1)]
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalRightBall2)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_bulbasaur", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_bulbasaur"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_picks_after_bulbasaur",
            steps: [
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .rivalStarterPickup,
                        variants: [
                            .init(
                                id: "player_right_of_table",
                                conditions: [.init(kind: "playerXEquals", intValue: 9)],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalLeftBall2)],
                                point: .init(x: 9, y: 8)
                            ),
                            .init(
                                id: "default",
                                conditions: [],
                                actors: [.init(actorID: "oaks_lab_rival", path: rivalLeftBall1)]
                            ),
                        ]
                    )
                ),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_this_one"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_poke_ball_charmander", visible: false),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_received_mon_charmander"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_squirtle",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_1"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_bulbasaur",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_2"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge_vs_charmander",
            steps: [
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "playMusicCue", stringValue: "rival_intro"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .pathToPlayerAdjacent,
                        actors: [.init(actorID: "oaks_lab_rival", path: [])],
                        targetPlayerOffset: .init(x: 0, y: -1)
                    )
                ),
                .init(action: "startBattle", battleID: "opp_rival1_3"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_exit_after_battle",
            steps: [
                .init(action: "playMusicCue", stringValue: "rival_exit"),
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_smell_you_later"),
                .init(action: "faceObject", stringValue: "down", objectID: "oaks_lab_rival"),
                .init(
                    action: "performMovement",
                    movement: .init(
                        kind: .fixedPath,
                        actors: [.init(actorID: "oaks_lab_rival", path: rivalExitPath)]
                    )
                ),
                .init(action: "facePlayer", stringValue: "down"),
                .init(action: "setObjectVisibility", objectID: "oaks_lab_rival", visible: false),
                .init(action: "restoreMapMusic"),
            ]
        ),
    ]

    scripts.append(contentsOf: buildPokemonCenterHealingScripts(maps: maps))
    return scripts
}

private func buildPokemonCenterHealingScripts(maps: [MapManifest]) -> [ScriptManifest] {
    maps.compactMap { map in
        guard
            map.id != "VIRIDIAN_POKECENTER",
            map.objects.contains(where: { $0.sprite == "SPRITE_NURSE" })
        else {
            return nil
        }
        return ScriptManifest(
            id: pokemonCenterHealScriptID(for: map.id),
            steps: [
                .init(action: "startFieldInteraction", fieldInteractionID: pokemonCenterFieldInteractionID(for: map.id)),
            ]
        )
    }
}

private func parseMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    return expandMovementLines(lines)
}

private func parseRepeatedMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    return expandRepeatedMovementLines(lines)
}

private func parseSimulatedJoypadMovementLabel(_ label: String, from contents: String) throws -> [FacingDirection] {
    let lines = try linesForMovementLabel(label, in: contents)
    // The engine decrements `wSimulatedJoypadStatesIndex` before reading from the decoded buffer,
    // so simulated joypad paths execute from the tail of the RLE list back to the head.
    return Array(expandRepeatedMovementLines(lines).reversed())
}

private func linesForMovementLabel(_ label: String, in contents: String) throws -> [String] {
    let pattern = "(?m)^\\s*\(NSRegularExpression.escapedPattern(for: label))(?::)?\\s*$"
    let regex = try NSRegularExpression(pattern: pattern)
    let fullRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    guard let match = regex.firstMatch(in: contents, range: fullRange),
          let labelRange = Range(match.range, in: contents) else {
        throw ExtractorError.invalidArguments("missing movement label \(label)")
    }

    let tail = contents[labelRange.upperBound...]
    var lines: [String] = []
    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty {
            if lines.isEmpty == false {
                break
            }
            continue
        }
        if line.hasPrefix(".") || line.hasSuffix(":") || line.contains("Script:") || line.contains("Text:") {
            if lines.isEmpty == false {
                break
            }
        }
        lines.append(line)
        if line.contains("db -1") {
            break
        }
    }
    guard lines.isEmpty == false else {
        throw ExtractorError.invalidArguments("movement label \(label) had no data")
    }
    return lines
}

private func expandMovementLines(_ lines: [String]) -> [FacingDirection] {
    var path: [FacingDirection] = []
    for line in lines where line.hasPrefix("db ") {
        let tokens = movementTokens(from: line)
        for token in tokens {
            if token == "-1" {
                return path
            }
            if token == "NPC_CHANGE_FACING" {
                continue
            }
            if let direction = directionToken(token) {
                path.append(direction)
            }
        }
    }
    return path
}

private func expandRepeatedMovementLines(_ lines: [String]) -> [FacingDirection] {
    var path: [FacingDirection] = []
    for line in lines where line.hasPrefix("db ") {
        let tokens = movementTokens(from: line)
        guard let first = tokens.first else { continue }
        if first == "-1" {
            return path
        }
        guard let direction = directionToken(first) else {
            continue
        }
        let repeatCount = tokens.count > 1 ? Int(tokens[1]) ?? 1 : 1
        path.append(contentsOf: Array(repeating: direction, count: repeatCount))
    }
    return path
}

private func movementTokens(from line: String) -> [String] {
    line
        .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        .first?
        .replacingOccurrences(of: "db", with: "")
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
}

private func directionToken(_ token: String) -> FacingDirection? {
    switch token {
    case "NPC_MOVEMENT_UP", "PAD_UP":
        return .up
    case "NPC_MOVEMENT_DOWN", "PAD_DOWN":
        return .down
    case "NPC_MOVEMENT_LEFT", "PAD_LEFT":
        return .left
    case "NPC_MOVEMENT_RIGHT", "PAD_RIGHT":
        return .right
    default:
        return nil
    }
}

private func buildSpecies(repoRoot: URL) throws -> [SpeciesManifest] {
    let speciesDefinitions = try parseCanonicalSpeciesDefinitions(repoRoot: repoRoot)
    let levelUpLearnsetsByID = try parseLevelUpLearnsets(repoRoot: repoRoot)
    let dexNumbersByID = try parsePokedexNumbers(repoRoot: repoRoot)
    let dexEntriesByKey = try parsePokedexEntries(repoRoot: repoRoot)
    let dexTextByKey = try parsePokedexText(repoRoot: repoRoot)

    return try speciesDefinitions.map { definition in
        let dexKey = definition.id.replacingOccurrences(of: "_", with: "").lowercased()
        let dexEntry = dexEntriesByKey[dexKey]
        let pokedexData = dexNumbersByID[definition.id].map { dexNumber in
            PokedexData(
                dexNumber: dexNumber,
                category: dexEntry?.category,
                heightFeet: dexEntry?.heightFeet,
                heightInches: dexEntry?.heightInches,
                weightTenths: dexEntry?.weightTenths,
                entryText: dexTextByKey[dexKey]
            )
        }

        return try parseSpecies(
            repoRoot: repoRoot,
            file: definition.file,
            id: definition.id,
            displayName: definition.displayName,
            cryData: definition.cryData,
            levelUpLearnset: levelUpLearnsetsByID[definition.id] ?? [],
            pokedexData: pokedexData
        )
    }
}

private func parsePokedexNumbers(repoRoot: URL) throws -> [String: Int] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/pokedex_constants.asm"))
    var numbersByID: [String: Int] = [:]
    var currentNumber = 0

    for rawLine in contents.split(separator: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("const_def") {
            if let match = line.firstMatch(of: /const_def\s+(\d+)/) {
                currentNumber = Int(match.output.1) ?? 1
            } else {
                currentNumber = 0
            }
            continue
        }
        guard let match = line.firstMatch(of: /const\s+DEX_([A-Z0-9_]+)/) else {
            continue
        }
        let speciesID = String(match.output.1)
        numbersByID[speciesID] = currentNumber
        currentNumber += 1
    }

    return numbersByID
}

private struct PokedexData {
    let dexNumber: Int
    let category: String?
    let heightFeet: Int?
    let heightInches: Int?
    let weightTenths: Int?
    let entryText: String?
}

private struct PokedexEntryData {
    let category: String
    let heightFeet: Int
    let heightInches: Int
    let weightTenths: Int
}

private func parsePokedexEntries(repoRoot: URL) throws -> [String: PokedexEntryData] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/dex_entries.asm"))
    var entriesByKey: [String: PokedexEntryData] = [:]

    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
    var index = 0

    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)

        guard let labelMatch = line.firstMatch(of: /^([A-Za-z]+)DexEntry:/) else {
            index += 1
            continue
        }

        let key = String(labelMatch.output.1).lowercased()

        var category: String?
        var heightFeet: Int?
        var heightInches: Int?
        var weightTenths: Int?

        for offset in 1...4 where (index + offset) < lines.count {
            let dataLine = lines[index + offset].trimmingCharacters(in: .whitespaces)

            if category == nil, let catMatch = dataLine.firstMatch(of: /db\s+"([^"]+)@?"/) {
                category = String(catMatch.output.1).replacingOccurrences(of: "@", with: "")
            } else if heightFeet == nil, let heightMatch = dataLine.firstMatch(of: /db\s+(\d+),\s*(\d+)/) {
                heightFeet = Int(heightMatch.output.1)
                heightInches = Int(heightMatch.output.2)
            } else if weightTenths == nil, let weightMatch = dataLine.firstMatch(of: /dw\s+(\d+)/) {
                weightTenths = Int(weightMatch.output.1)
            }
        }

        if let category, let heightFeet, let heightInches, let weightTenths {
            entriesByKey[key] = PokedexEntryData(
                category: category,
                heightFeet: heightFeet,
                heightInches: heightInches,
                weightTenths: weightTenths
            )
        }

        index += 1
    }

    return entriesByKey
}

private func parsePokedexText(repoRoot: URL) throws -> [String: String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/dex_text.asm"))
    var textByKey: [String: String] = [:]

    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
    var index = 0

    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)

        guard let labelMatch = line.firstMatch(of: /^_([A-Za-z]+)DexEntry::/) else {
            index += 1
            continue
        }

        let key = String(labelMatch.output.1).lowercased()
        var textParts: [String] = []

        index += 1
        while index < lines.count {
            let dataLine = lines[index].trimmingCharacters(in: .whitespaces)
            if dataLine == "dex" || dataLine.hasPrefix("_") {
                break
            }
            if let textMatch = dataLine.firstMatch(of: /(?:text|next|page)\s+"([^"]*)"/) {
                textParts.append(String(textMatch.output.1))
            }
            index += 1
        }

        if !textParts.isEmpty {
            var joined = ""
            for part in textParts {
                if joined.hasSuffix("-") {
                    joined = String(joined.dropLast()) + part
                } else if !joined.isEmpty {
                    joined += " " + part
                } else {
                    joined = part
                }
            }
            textByKey[key] = joined
                .replacingOccurrences(of: "# ", with: "POKé ")
                .replacingOccurrences(of: "#", with: "POKé")
        }
    }

    return textByKey
}

private struct CanonicalSpeciesDefinition {
    let file: String
    let id: String
    let displayName: String
    let cryData: (soundEffectID: String?, pitch: Int?, length: Int?)
}

private struct PokemonIndexMetadata {
    let id: String
    let displayName: String
    let cryData: (soundEffectID: String?, pitch: Int?, length: Int?)
}

private func parseCanonicalSpeciesDefinitions(repoRoot: URL) throws -> [CanonicalSpeciesDefinition] {
    let metadataByID = try parsePokemonIndexMetadata(repoRoot: repoRoot)
    var files = try canonicalSpeciesBaseStatFiles(repoRoot: repoRoot)
    files.append("data/pokemon/base_stats/mew.asm")
    return try files.map { file in
        let stem = repoRoot
            .appendingPathComponent(file)
            .deletingPathExtension()
            .lastPathComponent
        let id = try speciesID(forBaseStatStem: stem)
        guard let metadata = metadataByID[id] else {
            throw ExtractorError.invalidArguments("missing metadata for species \(id)")
        }
        return CanonicalSpeciesDefinition(
            file: file,
            id: id,
            displayName: metadata.displayName,
            cryData: metadata.cryData
        )
    }
}

private func canonicalSpeciesBaseStatFiles(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/base_stats.asm"))
    return contents
        .split(separator: "\n")
        .compactMap { rawLine -> String? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let match = line.firstMatch(of: /INCLUDE\s+"(data\/pokemon\/base_stats\/[a-z0-9]+\.asm)"/) else {
                return nil
            }
            return String(match.output.1)
        }
}

private func parsePokemonIndexMetadata(repoRoot: URL) throws -> [String: PokemonIndexMetadata] {
    let ids = try parsePokemonIndexIDs(repoRoot: repoRoot)
    let names = try parsePokemonIndexNames(repoRoot: repoRoot)
    let cries = try parsePokemonIndexCries(repoRoot: repoRoot)

    guard ids.count == names.count, names.count == cries.count else {
        throw ExtractorError.invalidArguments("pokemon metadata tables are out of sync")
    }

    var metadataByID: [String: PokemonIndexMetadata] = [:]
    for index in ids.indices {
        guard let id = ids[index] else { continue }
        metadataByID[id] = PokemonIndexMetadata(
            id: id,
            displayName: normalizedPokemonDisplayName(from: names[index]),
            cryData: cries[index]
        )
    }
    return metadataByID
}

private func parsePokemonIndexIDs(repoRoot: URL) throws -> [String?] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/pokemon_constants.asm"))
    var ids: [String?] = []
    var didEnterTable = false

    for rawLine in contents.split(separator: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("const NO_MON") {
            didEnterTable = true
            continue
        }
        guard didEnterTable else { continue }
        if line.hasPrefix("DEF NUM_POKEMON_INDEXES") {
            break
        }
        if line.hasPrefix("const_skip") {
            ids.append(nil)
            continue
        }
        guard let match = line.firstMatch(of: /const\s+([A-Z0-9_]+)/) else {
            continue
        }
        ids.append(String(match.output.1))
    }

    return ids
}

private func parsePokemonIndexNames(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/names.asm"))
    return contents.split(separator: "\n").compactMap { rawLine in
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard let match = line.firstMatch(of: /dname\s+"([^"]+)"/) else {
            return nil
        }
        return String(match.output.1)
    }
}

private func parsePokemonIndexCries(repoRoot: URL) throws -> [(soundEffectID: String?, pitch: Int?, length: Int?)] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/cries.asm"))
    let regex = try NSRegularExpression(
        pattern: #"mon_cry\s+(SFX_[A-Z0-9_]+),\s+\$([0-9A-Fa-f]{2}),\s+\$([0-9A-Fa-f]{2})\s*;"#,
        options: [.anchorsMatchLines]
    )
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsRange).compactMap { match in
        guard
            let idRange = Range(match.range(at: 1), in: contents),
            let pitchRange = Range(match.range(at: 2), in: contents),
            let lengthRange = Range(match.range(at: 3), in: contents)
        else {
            return nil
        }
        return (
            soundEffectID: String(contents[idRange]),
            pitch: Int(contents[pitchRange], radix: 16),
            length: Int(contents[lengthRange], radix: 16)
        )
    }
}

private func normalizedPokemonDisplayName(from rawName: String) -> String {
    switch rawName {
    case "NIDORAN♂":
        return "Nidoran M"
    case "NIDORAN♀":
        return "Nidoran F"
    case "MR.MIME":
        return "Mr. Mime"
    case "FARFETCH'D":
        return "Farfetch'd"
    default:
        return rawName
            .lowercased()
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

private func speciesID(forBaseStatStem stem: String) throws -> String {
    switch stem {
    case "nidoranf":
        return "NIDORAN_F"
    case "nidoranm":
        return "NIDORAN_M"
    case "mrmime":
        return "MR_MIME"
    default:
        return stem.uppercased()
    }
}

private func parseLevelUpLearnsets(repoRoot: URL) throws -> [String: [LevelUpMoveManifest]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/evos_moves.asm"))
    var learnsetsByLabel: [String: [LevelUpMoveManifest]] = [:]
    var currentLabel: String?
    var isParsingLearnset = false

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if let match = line.firstMatch(of: /([A-Za-z0-9]+)EvosMoves:/) {
            currentLabel = String(match.output.1)
            learnsetsByLabel[currentLabel ?? ""] = []
            isParsingLearnset = false
            continue
        }
        guard let currentLabel else {
            continue
        }
        if line == "; Learnset" {
            isParsingLearnset = true
            continue
        }
        guard isParsingLearnset else {
            continue
        }
        if line == "db 0" {
            isParsingLearnset = false
            continue
        }
        guard let match = line.firstMatch(of: /db\s+(\d+),\s+([A-Z_]+)/) else {
            continue
        }
        learnsetsByLabel[currentLabel, default: []].append(
            LevelUpMoveManifest(
                level: Int(match.output.1) ?? 1,
                moveID: String(match.output.2)
            )
        )
    }

    return Dictionary(uniqueKeysWithValues: try learnsetsByLabel.map { label, learnset in
        let speciesID = try speciesID(forEvosMovesLabel: label)
        return (speciesID, learnset)
    })
}

private func speciesID(forEvosMovesLabel label: String) throws -> String {
    switch label {
    case "NidoranF":
        return "NIDORAN_F"
    case "NidoranM":
        return "NIDORAN_M"
    case "MrMime":
        return "MR_MIME"
    default:
        return label
            .unicodeScalars
            .reduce(into: "") { partialResult, scalar in
                if CharacterSet.uppercaseLetters.contains(scalar), partialResult.isEmpty == false {
                    partialResult.append("_")
                }
                partialResult.append(String(scalar).uppercased())
            }
    }
}

private func parseSpecies(
    repoRoot: URL,
    file: String,
    id: String,
    displayName: String,
    cryData: (soundEffectID: String?, pitch: Int?, length: Int?),
    levelUpLearnset: [LevelUpMoveManifest],
    pokedexData: PokedexData? = nil
) throws -> SpeciesManifest {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent(file))
    guard let statsMatch = contents.firstMatch(of: /db\s+(\d+),\s+(\d+),\s+(\d+),\s+(\d+),\s+(\d+)\s*\n\s*;\s*hp\s+atk\s+def\s+spd\s+spc/),
          let typeMatch = contents.firstMatch(of: /db\s+([A-Z_]+),\s+([A-Z_]+)\s*;\s*type/),
          let catchRateMatch = contents.firstMatch(of: /db\s+(\d+)\s*;\s*catch rate/),
          let baseExpMatch = contents.firstMatch(of: /db\s+(\d+)\s*;\s*base exp/),
          let spriteMatch = contents.firstMatch(of: /dw\s+([A-Za-z0-9_]+),\s+([A-Za-z0-9_]+)/),
          let moveMatch = contents.firstMatch(of: /db\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z_]+)\s*; level 1 learnset/),
          let growthRateMatch = contents.firstMatch(of: /db\s+([A-Z_]+)\s*;\s*growth rate/)
    else {
        throw ExtractorError.invalidArguments("missing species data for \(id)")
    }

    let statsValues = [
        Int(statsMatch.output.1) ?? 0,
        Int(statsMatch.output.2) ?? 0,
        Int(statsMatch.output.3) ?? 0,
        Int(statsMatch.output.4) ?? 0,
        Int(statsMatch.output.5) ?? 0,
    ]
    let moveValues = [
        String(moveMatch.output.1),
        String(moveMatch.output.2),
        String(moveMatch.output.3),
        String(moveMatch.output.4),
    ]
    let primaryType = String(typeMatch.output.1)
    let rawSecondaryType = String(typeMatch.output.2)
    let catchRate = Int(catchRateMatch.output.1) ?? 0
    let baseExp = Int(baseExpMatch.output.1) ?? 0
    let growthRateRawValue = String(growthRateMatch.output.1)
    guard let growthRate = PokemonGrowthRate(rawValue: growthRateRawValue) else {
        throw ExtractorError.invalidArguments("unsupported growth rate \(growthRateRawValue) for \(id)")
    }
    let battleSprite = try battleSpriteManifest(
        speciesID: id,
        frontSymbol: String(spriteMatch.output.1),
        backSymbol: String(spriteMatch.output.2)
    )

    return SpeciesManifest(
        id: id,
        displayName: displayName,
        primaryType: primaryType,
        secondaryType: primaryType == rawSecondaryType ? nil : rawSecondaryType,
        battleSprite: battleSprite,
        catchRate: catchRate,
        baseExp: baseExp,
        growthRate: growthRate,
        baseHP: statsValues[safe: 0] ?? 0,
        baseAttack: statsValues[safe: 1] ?? 0,
        baseDefense: statsValues[safe: 2] ?? 0,
        baseSpeed: statsValues[safe: 3] ?? 0,
        baseSpecial: statsValues[safe: 4] ?? 0,
        startingMoves: moveValues.filter { $0 != "NO_MOVE" },
        levelUpLearnset: levelUpLearnset,
        crySoundEffectID: cryData.soundEffectID,
        cryPitch: cryData.pitch,
        cryLength: cryData.length,
        dexNumber: pokedexData?.dexNumber,
        speciesCategory: pokedexData?.category,
        heightFeet: pokedexData?.heightFeet,
        heightInches: pokedexData?.heightInches,
        weightTenths: pokedexData?.weightTenths,
        pokedexEntryText: pokedexData?.entryText
    )
}

private func battleSpriteManifest(speciesID: String, frontSymbol: String, backSymbol: String) throws -> BattleSpriteManifest {
    guard
        let frontStem = spriteStem(from: frontSymbol, suffix: "PicFront"),
        let backStem = spriteStem(from: backSymbol, suffix: "PicBack"),
        frontStem == backStem
    else {
        throw ExtractorError.invalidArguments("missing battle sprite symbols for \(speciesID)")
    }

    return BattleSpriteManifest(
        frontImagePath: "Assets/battle/pokemon/front/\(frontStem).png",
        backImagePath: "Assets/battle/pokemon/back/\(backStem).png"
    )
}

private func spriteStem(from symbol: String, suffix: String) -> String? {
    guard symbol.hasSuffix(suffix) else { return nil }
    let rawStem = String(symbol.dropLast(suffix.count)).lowercased()
    switch rawStem {
    case "mrmime":
        return "mr.mime"
    default:
        return rawStem
    }
}

private func buildTypeEffectiveness(repoRoot: URL) throws -> [TypeEffectivenessManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/types/type_matchups.asm"))
    var entries: [TypeEffectivenessManifest] = []
    var didEnterTable = false

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line == "TypeEffects:" {
            didEnterTable = true
            continue
        }
        guard didEnterTable else { continue }
        if line.hasPrefix("db -1") {
            break
        }
        guard let match = line.firstMatch(of: /db\s+([A-Z0-9_]+),\s+([A-Z0-9_]+),\s+([A-Z0-9_]+)/) else {
            continue
        }
        entries.append(
            TypeEffectivenessManifest(
                attackingType: String(match.output.1),
                defendingType: String(match.output.2),
                multiplier: try resolveTypeEffectivenessMultiplier(String(match.output.3))
            )
        )
    }

    guard entries.isEmpty == false else {
        throw ExtractorError.invalidArguments("missing type effectiveness table")
    }
    return entries
}

private func resolveTypeEffectivenessMultiplier(_ token: String) throws -> Int {
    switch token {
    case "NO_EFFECT":
        return 0
    case "NOT_VERY_EFFECTIVE":
        return 5
    case "EFFECTIVE":
        return 10
    case "MORE_EFFECTIVE":
        return 15
    case "SUPER_EFFECTIVE":
        return 20
    default:
        throw ExtractorError.invalidArguments("unknown type effectiveness multiplier \(token)")
    }
}

private func buildMoves(repoRoot: URL) throws -> [MoveManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/moves.asm"))
    let battleAudioByMoveID = try parseMoveBattleAudio(repoRoot: repoRoot)
    return contents.split(separator: "\n").compactMap { rawLine in
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard line.hasPrefix("move ") else { return nil }
        let parts = line.replacingOccurrences(of: "move", with: "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 6 else { return nil }
        return MoveManifest(
            id: parts[0],
            displayName: parts[0].replacingOccurrences(of: "_", with: " "),
            power: Int(parts[2]) ?? 0,
            accuracy: Int(parts[4]) ?? 100,
            maxPP: Int(parts[5]) ?? 0,
            effect: parts[1],
            type: parts[3],
            battleAudio: battleAudioByMoveID[parts[0]]
        )
    }
}

private func parseMoveBattleAudio(repoRoot: URL) throws -> [String: BattleAudioManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/sfx.asm"))
    let regex = try NSRegularExpression(
        pattern: #"db\s+(SFX_[A-Z0-9_]+),\s+\$([0-9A-Fa-f]{2}),\s+\$([0-9A-Fa-f]{2})\s*;\s*([A-Z0-9_]+)$"#,
        options: [.anchorsMatchLines]
    )
    let cryMoveIDs: Set<String> = ["GROWL", "ROAR"]
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var result: [String: BattleAudioManifest] = [:]

    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let soundRange = Range(match.range(at: 1), in: contents),
            let frequencyRange = Range(match.range(at: 2), in: contents),
            let tempoRange = Range(match.range(at: 3), in: contents),
            let moveRange = Range(match.range(at: 4), in: contents)
        else {
            continue
        }

        let moveID = String(contents[moveRange])
        let frequencyModifier = Int(contents[frequencyRange], radix: 16)
        let tempoModifier = Int(contents[tempoRange], radix: 16)
        if cryMoveIDs.contains(moveID) {
            result[moveID] = .init(
                kind: .cry,
                frequencyModifier: frequencyModifier,
                tempoModifier: tempoModifier
            )
        } else {
            result[moveID] = .init(
                kind: .soundEffect,
                soundEffectID: String(contents[soundRange]),
                frequencyModifier: frequencyModifier,
                tempoModifier: tempoModifier
            )
        }
    }

    return result
}

private func buildItems(repoRoot: URL) throws -> [ItemManifest] {
    let namesByID = try parseItemNames(repoRoot: repoRoot)
    let keyItemIDs = try parseKeyItemIDs(repoRoot: repoRoot)
    let pricesByID = try parseItemPrices(repoRoot: repoRoot)

    return try parseDefinedItemIDs(repoRoot: repoRoot).map { itemID in
        ItemManifest(
            id: itemID,
            displayName: namesByID[itemID] ?? itemID,
            price: pricesByID[itemID] ?? 0,
            isKeyItem: keyItemIDs.contains(itemID),
            battleUse: battleUseKind(for: itemID)
        )
    }
}

private func buildMarts(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [MartManifest] {
    let martsByLabel = try parseMartStocks(repoRoot: repoRoot)
    let regex = try NSRegularExpression(
        pattern: #"(?m)^\s*object_event\s+\d+,\s+\d+,\s+([A-Z0-9_]+),\s+[A-Z_]+,\s+[A-Z_]+,\s+([A-Z0-9_]+)(.*)$"#,
        options: [.anchorsMatchLines]
    )

    return try gameplayCoverageMaps.compactMap { definition in
        guard let metadata = mapScriptMetadataByMapID[definition.mapID] else {
            return nil
        }

        let contents = try String(contentsOf: repoRoot.appendingPathComponent(definition.objectFile))
        let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)

        for (index, match) in regex.matches(in: contents, range: nsRange).enumerated() {
            guard
                let spriteRange = Range(match.range(at: 1), in: contents),
                let textIDRange = Range(match.range(at: 2), in: contents),
                String(contents[spriteRange]) == "SPRITE_CLERK"
            else {
                continue
            }

            let textID = String(contents[textIDRange])
            guard
                let textLabel = metadata.textLabelByTextID[textID],
                let stockItemIDs = martsByLabel[textLabel]
            else {
                continue
            }

            return MartManifest(
                id: martID(for: definition.mapID),
                mapID: definition.mapID,
                clerkObjectID: objectIDFor(
                    mapID: definition.mapID,
                    index: index,
                    textID: textID,
                    pickupItemID: nil,
                    mapScriptMetadata: metadata
                ),
                stockItemIDs: stockItemIDs
            )
        }

        return nil
    }
    .sorted { $0.id < $1.id }
}

private func parseItemNames(repoRoot: URL) throws -> [String: String] {
    let itemIDs = try parseDefinedItemIDs(repoRoot: repoRoot)
    let names = try String(contentsOf: repoRoot.appendingPathComponent("data/items/names.asm"))

    let itemNames = names
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("li \"") else { return nil }
            return extractQuotedString(from: line)
        }

    return Dictionary(uniqueKeysWithValues: zip(itemIDs, itemNames))
}

private func parseKeyItemIDs(repoRoot: URL) throws -> Set<String> {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/items/key_items.asm"))
    let itemIDs = try parseDefinedItemIDs(repoRoot: repoRoot)

    let keyFlags = contents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> Bool? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("dbit ") else { return nil }
            return line.contains("TRUE")
        }

    return Set(zip(itemIDs, keyFlags).compactMap { itemID, isKeyItem in
        isKeyItem ? itemID : nil
    })
}

private func parseItemPrices(repoRoot: URL) throws -> [String: Int] {
    let itemIDs = try parseDefinedItemIDs(repoRoot: repoRoot)
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/items/prices.asm"))
    let prices = contents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> Int? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("bcd3 ") else { return nil }
            return Int(line.replacingOccurrences(of: "bcd3", with: "").trimmingCharacters(in: .whitespaces))
        }
    return Dictionary(uniqueKeysWithValues: zip(itemIDs, prices))
}

private func parseMartStocks(repoRoot: URL) throws -> [String: [String]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/items/marts.asm"))
    var result: [String: [String]] = [:]
    var currentLabel: String?

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasSuffix("::") {
            currentLabel = String(line.dropLast(2))
            continue
        }
        guard let currentLabel, line.hasPrefix("script_mart ") else { continue }
        let itemIDs = line
            .replacingOccurrences(of: "script_mart", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        result[currentLabel] = itemIDs
    }

    return result
}

private func parseDefinedItemIDs(repoRoot: URL) throws -> [String] {
    try String(contentsOf: repoRoot.appendingPathComponent("constants/item_constants.asm"))
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("const ") else { return nil }
            let identifier = line.replacingOccurrences(of: "const", with: "").trimmingCharacters(in: .whitespaces)
            guard
                identifier.isEmpty == false,
                identifier != "NO_ITEM",
                identifier.contains(#"\"#) == false
            else {
                return nil
            }
            return identifier.components(separatedBy: .whitespaces).first
        }
}

private func battleUseKind(for itemID: String) -> ItemManifest.BattleUseKind {
    switch itemID {
    case "MASTER_BALL", "ULTRA_BALL", "GREAT_BALL", "POKE_BALL", "SAFARI_BALL":
        return .ball
    default:
        return .none
    }
}

private func buildWildEncounterTables(repoRoot: URL) throws -> [WildEncounterTableManifest] {
    try gameplayCoverageMaps.compactMap { definition in
        guard let path = wildEncounterPath(for: definition, repoRoot: repoRoot) else {
            return nil
        }
        return try parseWildEncounterTable(
            repoRoot: repoRoot,
            mapID: definition.mapID,
            path: path
        )
    }
}

private func parseWildEncounterTable(repoRoot: URL, mapID: String, path: String) throws -> WildEncounterTableManifest {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent(path))
    return WildEncounterTableManifest(
        mapID: mapID,
        grassEncounterRate: try parseEncounterRate(label: "def_grass_wildmons", in: contents),
        waterEncounterRate: try parseEncounterRate(label: "def_water_wildmons", in: contents),
        grassSlots: parseEncounterSlots(from: contents, startMarker: "def_grass_wildmons", endMarker: "end_grass_wildmons"),
        waterSlots: parseEncounterSlots(from: contents, startMarker: "def_water_wildmons", endMarker: "end_water_wildmons")
    )
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

private func buildTrainerBattles(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [TrainerBattleManifest] {
    let trainerClassMetadataByID = try parseTrainerClassMetadata(repoRoot: repoRoot)
    let trainerEncounterCueByClass = try parseTrainerEncounterCueIDs(repoRoot: repoRoot)
    let rivalClassMetadata = try trainerClassMetadataByID
        .value(for: "OPP_RIVAL1", missingMessage: "missing trainer metadata for OPP_RIVAL1")

    var battlesByID: [String: TrainerBattleManifest] = [:]

    for trainerNumber in 1...3 {
        guard rivalClassMetadata.parties.indices.contains(trainerNumber - 1) else {
            throw ExtractorError.invalidArguments("missing Rival1 trainer party \(trainerNumber)")
        }
        battlesByID["opp_rival1_\(trainerNumber)"] = TrainerBattleManifest(
            id: "opp_rival1_\(trainerNumber)",
            trainerClass: "OPP_RIVAL1",
            trainerNumber: trainerNumber,
            displayName: "BLUE",
            party: rivalClassMetadata.parties[trainerNumber - 1],
            trainerSpritePath: rivalClassMetadata.trainerSpritePath,
            baseRewardMoney: rivalClassMetadata.baseRewardMoney,
            encounterAudioCueID: trainerEncounterCueByClass["OPP_RIVAL1"],
            playerWinDialogueID: "oaks_lab_rival_i_picked_the_wrong_pokemon",
            playerLoseDialogueID: "oaks_lab_rival_am_i_great_or_what",
            healsPartyAfterBattle: true,
            preventsBlackoutOnLoss: true,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB",
            postBattleScriptID: "oaks_lab_rival_exit_after_battle"
        )
    }

    if let brockMetadata = trainerClassMetadataByID["OPP_BROCK"] {
        guard brockMetadata.parties.indices.contains(0) else {
            throw ExtractorError.invalidArguments("missing Brock trainer party 1")
        }

        battlesByID["opp_brock_1"] = TrainerBattleManifest(
            id: "opp_brock_1",
            trainerClass: "OPP_BROCK",
            trainerNumber: 1,
            displayName: brockMetadata.displayName,
            party: brockMetadata.parties[0],
            trainerSpritePath: brockMetadata.trainerSpritePath,
            baseRewardMoney: brockMetadata.baseRewardMoney,
            encounterAudioCueID: trainerEncounterCueByClass["OPP_BROCK"],
            playerWinDialogueID: "pewter_gym_brock_received_boulder_badge",
            playerLoseDialogueID: nil,
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            completionFlagID: "EVENT_BEAT_BROCK",
            postBattleScriptID: nil
        )
    }

    for reference in try referencedSliceTrainerBattles(
        repoRoot: repoRoot,
        mapScriptMetadataByMapID: mapScriptMetadataByMapID
    ) {
        guard battlesByID[reference.id] == nil else {
            continue
        }
        let classMetadata = try trainerClassMetadataByID
            .value(for: reference.trainerClass, missingMessage: "missing trainer metadata for \(reference.trainerClass)")
        guard classMetadata.parties.indices.contains(reference.trainerNumber - 1) else {
            throw ExtractorError.invalidArguments("missing trainer party \(reference.trainerClass) \(reference.trainerNumber)")
        }

        battlesByID[reference.id] = TrainerBattleManifest(
            id: reference.id,
            trainerClass: reference.trainerClass,
            trainerNumber: reference.trainerNumber,
            displayName: classMetadata.displayName,
            party: classMetadata.parties[reference.trainerNumber - 1],
            trainerSpritePath: classMetadata.trainerSpritePath,
            baseRewardMoney: classMetadata.baseRewardMoney,
            encounterAudioCueID: trainerEncounterCueByClass[reference.trainerClass],
            playerWinDialogueID: reference.playerWinDialogueID,
            playerLoseDialogueID: nil,
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            completionFlagID: reference.completionFlagID,
            postBattleScriptID: nil
        )
    }

    return battlesByID.values.sorted { $0.id < $1.id }
}

private func buildTrainerAIMoveChoiceModifications(repoRoot: URL) throws -> [TrainerAIMoveChoiceModificationManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/move_choices.asm"))
    return contents
        .split(separator: "\n")
        .compactMap { rawLine in
            let line = String(rawLine)
            guard line.contains("move_choices") else {
                return nil
            }

            let parts = line.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                return nil
            }

            let trainerClass = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard trainerClass.isEmpty == false else {
                return nil
            }

            let command = parts[0].replacingOccurrences(of: "move_choices", with: "")
            let modifications = command
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

            return TrainerAIMoveChoiceModificationManifest(
                trainerClass: trainerClass,
                modifications: modifications
            )
        }
}

private struct TrainerClassMetadata {
    let displayName: String
    let parties: [[TrainerPokemonManifest]]
    let trainerSpritePath: String?
    let baseRewardMoney: Int
}

private struct ReferencedSliceTrainerBattle {
    let id: String
    let trainerClass: String
    let trainerNumber: Int
    let playerWinDialogueID: String
    let completionFlagID: String
}

private func parseTrainerClassMetadata(repoRoot: URL) throws -> [String: TrainerClassMetadata] {
    let trainerClassIDs = try parseTrainerClassIDs(repoRoot: repoRoot)
    let displayNames = try parseTrainerDisplayNames(repoRoot: repoRoot)
    let partyTableLabels = try parseTrainerPartyTableLabels(repoRoot: repoRoot)
    let rewardMetadata = try parseTrainerRewardMetadata(repoRoot: repoRoot)
    let partiesContents = try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/parties.asm"))

    guard trainerClassIDs.count == displayNames.count,
          displayNames.count == partyTableLabels.count,
          partyTableLabels.count == rewardMetadata.count else {
        throw ExtractorError.invalidArguments("trainer class tables are out of sync")
    }

    return try Dictionary(uniqueKeysWithValues: zip(trainerClassIDs.indices, trainerClassIDs).map { index, trainerClassID in
        (
            "OPP_\(trainerClassID)",
            TrainerClassMetadata(
                displayName: displayNames[index],
                parties: try parseTrainerParties(contents: partiesContents, label: partyTableLabels[index]),
                trainerSpritePath: rewardMetadata[index].trainerSpritePath,
                baseRewardMoney: rewardMetadata[index].baseRewardMoney
            )
        )
    })
}

private func parseTrainerClassIDs(repoRoot: URL) throws -> [String] {
    try String(contentsOf: repoRoot.appendingPathComponent("constants/trainer_constants.asm"))
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard line.hasPrefix("trainer_const ") else { return nil }
            let trainerClassID = line.replacingOccurrences(of: "trainer_const", with: "").trimmingCharacters(in: .whitespaces)
            return trainerClassID == "NOBODY" ? nil : trainerClassID
        }
}

private func parseTrainerDisplayNames(repoRoot: URL) throws -> [String] {
    try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/names.asm"))
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("li \"") else { return nil }
            return extractQuotedString(from: line)
        }
}

private func parseTrainerPartyTableLabels(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/parties.asm"))
    let regex = try NSRegularExpression(pattern: #"^\s*dw\s+([A-Za-z0-9_]+)$"#, options: [.anchorsMatchLines])
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsRange).compactMap { match in
        guard let labelRange = Range(match.range(at: 1), in: contents) else {
            return nil
        }
        return String(contents[labelRange])
    }
}

private func referencedSliceTrainerBattles(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [ReferencedSliceTrainerBattle] {
    let objectRegex = try NSRegularExpression(
        pattern: #"(?m)^\s*object_event\s+\d+,\s+\d+,\s+[A-Z0-9_]+,\s+[A-Z_]+,\s+[A-Z_]+,\s+([A-Z0-9_]+)(.*)$"#,
        options: [.anchorsMatchLines]
    )
    var referencesByID: [String: ReferencedSliceTrainerBattle] = [:]

    for definition in gameplayCoverageMaps {
        guard let metadata = mapScriptMetadataByMapID[definition.mapID], metadata.usesStandardTrainerLoop else {
            continue
        }

        let contents = try String(contentsOf: repoRoot.appendingPathComponent(definition.objectFile))
        let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        for match in objectRegex.matches(in: contents, range: nsRange) {
            guard
                let textIDRange = Range(match.range(at: 1), in: contents),
                let extraRange = Range(match.range(at: 2), in: contents)
            else {
                continue
            }

            let textID = String(contents[textIDRange])
            let extraTokens = parseObjectExtraTokens(from: String(contents[extraRange]))
            guard
                extraTokens.count >= 2,
                let trainerNumber = Int(extraTokens[1]),
                let battleID = trainerBattleIDFor(trainerClass: extraTokens[0], trainerNumber: trainerNumber),
                let textLabel = metadata.textLabelByTextID[textID],
                let trainerHeaderLabel = metadata.trainerHeaderLabelByTextLabel[textLabel],
                let trainerHeader = metadata.trainerHeadersByLabel[trainerHeaderLabel]
            else {
                continue
            }

            referencesByID[battleID] = ReferencedSliceTrainerBattle(
                id: battleID,
                trainerClass: extraTokens[0],
                trainerNumber: trainerNumber,
                playerWinDialogueID: dialogueID(forScriptLabel: trainerHeader.endBattleTextLabel, mapScriptMetadata: metadata),
                completionFlagID: trainerHeader.defeatFlagID
            )
        }
    }

    return referencesByID.values.sorted { $0.id < $1.id }
}

private struct TrainerRewardMetadata {
    let trainerSpritePath: String?
    let baseRewardMoney: Int
}

private func decodeTrainerBaseRewardMoney(_ encodedValue: Int) -> Int {
    // `pic_pointers_money.asm` stores trainer class payout as a padded BCD literal
    // (`3500` for Rival = 35 per level). Runtime money should use the decoded
    // class value, not the literal token.
    max(0, encodedValue / 100)
}

private func parseTrainerRewardMetadata(repoRoot: URL) throws -> [TrainerRewardMetadata] {
    let spritePathBySymbol = try parseTrainerSpritePathBySymbol(repoRoot: repoRoot)

    return try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/pic_pointers_money.asm"))
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> TrainerRewardMetadata? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let match = line.firstMatch(of: /pic_money\s+([A-Za-z0-9_.]+),\s+([0-9]+)/) else {
                return nil
            }

            let spriteSymbol = String(match.output.1)
            guard let trainerSpritePath = spritePathBySymbol[spriteSymbol] else {
                throw ExtractorError.invalidArguments("missing trainer sprite for \(spriteSymbol)")
            }

            return TrainerRewardMetadata(
                trainerSpritePath: trainerSpritePath,
                baseRewardMoney: decodeTrainerBaseRewardMoney(Int(match.output.2) ?? 0)
            )
        }
}

private func parseTrainerSpritePathBySymbol(repoRoot: URL) throws -> [String: String] {
    let spriteFilenames = Set(
        try FileManager.default.contentsOfDirectory(
            atPath: repoRoot.appendingPathComponent("gfx/trainers").path
        )
        .filter { $0.hasSuffix(".png") }
    )
    var spritePathBySymbol: [String: String] = [:]
    var pendingSymbols: [String] = []
    let picsContents = try String(contentsOf: repoRoot.appendingPathComponent("gfx/pics.asm"))

    for rawLine in picsContents.split(separator: "\n", omittingEmptySubsequences: false) {
        var line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        guard line.isEmpty == false else {
            continue
        }

        while let range = line.range(of: "::") {
            let label = line[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            if label.isEmpty == false {
                pendingSymbols.append(label)
            }
            line = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }

        guard let match = line.firstMatch(of: /INCBIN\s+"gfx\/trainers\/([^"]+)\.pic"/) else {
            continue
        }

        let pngFilename = "\(match.output.1).png"
        let spritePath = "Assets/battle/trainers/\(pngFilename)"
        guard spriteFilenames.contains(pngFilename) else {
            throw ExtractorError.invalidArguments("missing trainer sprite asset for \(pngFilename)")
        }

        for symbol in pendingSymbols {
            spritePathBySymbol[symbol] = spritePath
        }
        pendingSymbols.removeAll(keepingCapacity: true)
    }

    return spritePathBySymbol
}

private func buildCommonBattleText(repoRoot: URL) throws -> BattleTextTemplateManifest {
    let text2 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_2.asm"))

    return BattleTextTemplateManifest(
        wantsToFight: try extractBattleTextTemplate(
            label: "_TrainerWantsToFightText",
            from: text2,
            placeholderMap: ["wTrainerName": "trainerName"]
        ),
        enemyFainted: try extractBattleTextTemplate(
            label: "_EnemyMonFaintedText",
            from: text2,
            placeholderMap: ["wEnemyMonNick": "enemyPokemon"]
        ),
        playerFainted: try extractBattleTextTemplate(
            label: "_PlayerMonFaintedText",
            from: text2,
            placeholderMap: ["wBattleMonNick": "playerPokemon"]
        ),
        playerBlackedOut: try extractBattleTextTemplate(
            label: "_PlayerBlackedOutText2",
            from: text2,
            placeholderMap: ["<PLAYER>": "playerName"]
        ),
        trainerDefeated: try extractBattleTextTemplate(
            label: "_TrainerDefeatedText",
            from: text2,
            placeholderMap: ["wTrainerName": "trainerName", "<PLAYER>": "playerName"]
        ),
        moneyForWinning: try extractBattleTextTemplate(
            label: "_MoneyForWinningText",
            from: text2,
            placeholderMap: ["wAmountMoneyWon": "money", "<PLAYER>": "playerName"]
        ),
        trainerAboutToUse: try extractBattleTextTemplate(
            label: "_TrainerAboutToUseText",
            from: text2,
            placeholderMap: [
                "wTrainerName": "trainerName",
                "wEnemyMonNick": "enemyPokemon",
                "<PLAYER>": "playerName",
            ]
        ),
        trainerSentOut: try extractBattleTextTemplate(
            label: "_TrainerSentOutText",
            from: text2,
            placeholderMap: [
                "wTrainerName": "trainerName",
                "wEnemyMonNick": "enemyPokemon",
            ]
        ),
        playerSendOutGo: try extractBattleTextTemplate(
            label: "_GoText",
            from: text2,
            placeholderMap: ["wBattleMonNick": "playerPokemon"]
        ),
        playerSendOutDoIt: try extractBattleTextTemplate(
            label: "_DoItText",
            from: text2,
            placeholderMap: ["wBattleMonNick": "playerPokemon"]
        ),
        playerSendOutGetm: try extractBattleTextTemplate(
            label: "_GetmText",
            from: text2,
            placeholderMap: ["wBattleMonNick": "playerPokemon"]
        ),
        playerSendOutEnemyWeak: try extractBattleTextTemplate(
            label: "_EnemysWeakText",
            from: text2,
            placeholderMap: ["wBattleMonNick": "playerPokemon"]
        )
    )
}

private func extractBattleTextTemplate(
    label: String,
    from contents: String,
    placeholderMap: [String: String]
) throws -> String {
    guard let range = contents.range(of: "\(label)::") else {
        throw ExtractorError.invalidArguments("missing battle text label \(label)")
    }

    let tail = contents[range.upperBound...]
    var segments: [String] = []

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasSuffix("::"), line.hasPrefix("_"), line.hasPrefix(label) == false {
            break
        }

        if line.hasPrefix("text \"") || line.hasPrefix("line \"") || line.hasPrefix("cont \"") || line.hasPrefix("para \"") {
            let value = extractQuotedString(from: line)
            segments.append(replacingBattleTemplateTokens(in: value, placeholderMap: placeholderMap))
            continue
        }

        if line == "text_start" {
            continue
        }

        if line.hasPrefix("text_ram ") {
            let token = line.replacingOccurrences(of: "text_ram ", with: "").trimmingCharacters(in: .whitespaces)
            let placeholder = placeholderMap[token] ?? token
            segments.append("{\(placeholder)}")
            continue
        }

        if line.hasPrefix("text_bcd ") {
            let token = line
                .replacingOccurrences(of: "text_bcd ", with: "")
                .split(separator: ",", maxSplits: 1, omittingEmptySubsequences: true)
                .first
                .map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
            let placeholder = placeholderMap[token] ?? token
            segments.append("{\(placeholder)}")
            continue
        }

        if line == "done" || line == "prompt" || line == "text_end" {
            break
        }
    }

    return segments
        .joined(separator: " ")
        .replacingOccurrences(of: "  ", with: " ")
        .replacingOccurrences(of: " !", with: "!")
        .replacingOccurrences(of: " ?", with: "?")
        .replacingOccurrences(of: " .", with: ".")
        .replacingOccurrences(of: " ,", with: ",")
        .replacingOccurrences(of: " ¥ ", with: " ¥")
        .replacingOccurrences(of: "¥ ", with: "¥")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func replacingBattleTemplateTokens(in value: String, placeholderMap: [String: String]) -> String {
    placeholderMap.reduce(value) { partial, replacement in
        partial.replacingOccurrences(of: replacement.key, with: "{\(replacement.value)}")
    }
}

private func parseTrainerParties(contents: String, label: String) throws -> [[TrainerPokemonManifest]] {
    guard let labelRange = contents.range(of: "\(label):") else {
        throw ExtractorError.invalidArguments("missing trainer party label \(label)")
    }

    let tail = contents[labelRange.upperBound...]
    var parties: [[TrainerPokemonManifest]] = []

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasSuffix(":"), line.hasPrefix(label) == false, line.isEmpty == false {
            break
        }
        guard line.hasPrefix("db ") else { continue }
        let tokens = line
            .replacingOccurrences(of: "db", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard tokens.isEmpty == false else { continue }

        if tokens[0] == "$FF" {
            var party: [TrainerPokemonManifest] = []
            var index = 1
            while index + 1 < tokens.count {
                if tokens[index] == "0" { break }
                guard let level = Int(tokens[index]) else { break }
                let speciesID = tokens[index + 1]
                if speciesID == "0" { break }
                party.append(.init(speciesID: speciesID, level: level))
                index += 2
            }
            if party.isEmpty == false {
                parties.append(party)
            }
            continue
        }

        guard let sharedLevel = Int(tokens[0]) else { continue }
        let speciesIDs = tokens.dropFirst().prefix { $0 != "0" }
        let party = speciesIDs.map { TrainerPokemonManifest(speciesID: $0, level: sharedLevel) }
        if party.isEmpty == false {
            parties.append(party)
        }
    }

    return parties
}

private func parseTrainerEncounterCueIDs(repoRoot: URL) throws -> [String: String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/trainers/encounter_types.asm"))
    let femaleTrainerClasses = try parseTrainerEncounterClassList(contents: contents, label: "FemaleTrainerList")
    let evilTrainerClasses = try parseTrainerEncounterClassList(contents: contents, label: "EvilTrainerList")

    return Dictionary(
        uniqueKeysWithValues: try parseTrainerClassIDs(repoRoot: repoRoot).compactMap { classID in
            let trainerClass = "OPP_\(classID)"
            guard let cueID = trainerEncounterCueID(
                for: trainerClass,
                femaleTrainerClasses: femaleTrainerClasses,
                evilTrainerClasses: evilTrainerClasses
            ) else {
                return nil
            }
            return (trainerClass, cueID)
        }
    )
}

private func parseTrainerEncounterClassList(contents: String, label: String) throws -> Set<String> {
    guard let labelRange = contents.range(of: "\(label):") else {
        throw ExtractorError.invalidArguments("missing trainer encounter list \(label)")
    }

    let tail = contents[labelRange.upperBound...]
    var trainerClasses: Set<String> = []

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if line.hasPrefix("db -1") {
            break
        }
        guard line.hasPrefix("db ") else {
            continue
        }

        let trainerClass = line.replacingOccurrences(of: "db", with: "").trimmingCharacters(in: .whitespaces)
        guard trainerClass.isEmpty == false else {
            continue
        }
        trainerClasses.insert(trainerClass)
    }

    return trainerClasses
}

private func trainerEncounterCueID(
    for trainerClass: String,
    femaleTrainerClasses: Set<String>,
    evilTrainerClasses: Set<String>
) -> String? {
    guard trainerEncounterMusicExcludedClasses.contains(trainerClass) == false else {
        return nil
    }
    if evilTrainerClasses.contains(trainerClass) {
        return "trainer_intro_evil"
    }
    if femaleTrainerClasses.contains(trainerClass) {
        return "trainer_intro_female"
    }
    return "trainer_intro_male"
}

private let trainerEncounterMusicExcludedClasses: Set<String> = [
    "OPP_RIVAL1",
    "OPP_RIVAL2",
    "OPP_RIVAL3",
    "OPP_BROCK",
    "OPP_MISTY",
    "OPP_LT_SURGE",
    "OPP_ERIKA",
    "OPP_KOGA",
    "OPP_BLAINE",
    "OPP_SABRINA",
    "OPP_GIOVANNI",
    "OPP_LORELEI",
    "OPP_BRUNO",
    "OPP_AGATHA",
    "OPP_LANCE",
]

private func facingDirection(from raw: String) -> FacingDirection {
    switch raw {
    case "UP", "PLAYER_DIR_UP", "SPRITE_FACING_UP": return .up
    case "DOWN", "PLAYER_DIR_DOWN", "SPRITE_FACING_DOWN": return .down
    case "LEFT", "SPRITE_FACING_LEFT": return .left
    case "RIGHT", "SPRITE_FACING_RIGHT": return .right
    default: return .down
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Dictionary {
    func value(for key: Key, missingMessage: @autoclosure () -> String) throws -> Value {
        guard let value = self[key] else {
            throw ExtractorError.invalidArguments(missingMessage())
        }
        return value
    }
}
