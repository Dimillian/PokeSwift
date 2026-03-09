import Foundation
import PokeDataModel

func extractGameplayManifest(source: SourceTree) throws -> GameplayManifest {
    let mapSizes = try parseMapSizes(repoRoot: source.repoRoot)
    let collisionSets = try parseCollisionSets(repoRoot: source.repoRoot)
    let mapHeaders = try parseMapHeaders(repoRoot: source.repoRoot)
    let eventFlags = try parseEventFlags(repoRoot: source.repoRoot)

    let maps = try [
        makeMapManifest(
            repoRoot: source.repoRoot,
            mapID: "REDS_HOUSE_2F",
            displayName: "Red's House 2F",
            objectFile: "data/maps/objects/RedsHouse2F.asm",
            blockFile: "maps/RedsHouse2F.blk",
            size: mapSizes["REDS_HOUSE_2F"] ?? TileSize(width: 4, height: 4),
            tileset: mapHeaders["REDS_HOUSE_2F"] ?? "REDS_HOUSE_2",
            collisionBlockIDs: collisionSets[collisionKey(for: mapHeaders["REDS_HOUSE_2F"] ?? "REDS_HOUSE_2")] ?? [],
            triggerRegions: []
        ),
        makeMapManifest(
            repoRoot: source.repoRoot,
            mapID: "REDS_HOUSE_1F",
            displayName: "Red's House 1F",
            objectFile: "data/maps/objects/RedsHouse1F.asm",
            blockFile: "maps/RedsHouse1F.blk",
            size: mapSizes["REDS_HOUSE_1F"] ?? TileSize(width: 4, height: 4),
            tileset: mapHeaders["REDS_HOUSE_1F"] ?? "REDS_HOUSE_1",
            collisionBlockIDs: collisionSets[collisionKey(for: mapHeaders["REDS_HOUSE_1F"] ?? "REDS_HOUSE_1")] ?? [],
            triggerRegions: []
        ),
        makeMapManifest(
            repoRoot: source.repoRoot,
            mapID: "PALLET_TOWN",
            displayName: "Pallet Town",
            objectFile: "data/maps/objects/PalletTown.asm",
            blockFile: "maps/PalletTown.blk",
            size: mapSizes["PALLET_TOWN"] ?? TileSize(width: 10, height: 9),
            tileset: mapHeaders["PALLET_TOWN"] ?? "OVERWORLD",
            collisionBlockIDs: collisionSets[collisionKey(for: mapHeaders["PALLET_TOWN"] ?? "OVERWORLD")] ?? [],
            triggerRegions: [
                .init(id: "north_exit", origin: .init(x: 0, y: 1), size: .init(width: 20, height: 1), scriptID: "pallet_town_oak_intro"),
            ]
        ),
        makeMapManifest(
            repoRoot: source.repoRoot,
            mapID: "OAKS_LAB",
            displayName: "Oak's Lab",
            objectFile: "data/maps/objects/OaksLab.asm",
            blockFile: "maps/OaksLab.blk",
            size: mapSizes["OAKS_LAB"] ?? TileSize(width: 5, height: 6),
            tileset: mapHeaders["OAKS_LAB"] ?? "DOJO",
            collisionBlockIDs: collisionSets[collisionKey(for: mapHeaders["OAKS_LAB"] ?? "DOJO")] ?? [],
            triggerRegions: []
        ),
    ]

    return GameplayManifest(
        maps: maps,
        tilesets: buildTilesets(),
        overworldSprites: buildOverworldSprites(),
        dialogues: try buildDialogues(repoRoot: source.repoRoot),
        eventFlags: EventFlagManifest(flags: eventFlags),
        scripts: buildScripts(),
        species: try buildSpecies(repoRoot: source.repoRoot),
        moves: try buildMoves(repoRoot: source.repoRoot),
        trainerBattles: buildTrainerBattles(),
        playerStart: .init(
            mapID: "REDS_HOUSE_2F",
            position: .init(x: 4, y: 4),
            facing: .down,
            playerName: "RED",
            rivalName: "BLUE",
            initialFlags: []
        )
    )
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

private func parseEventFlags(repoRoot: URL) throws -> [EventFlagDefinition] {
    let requiredFlags = [
        "EVENT_FOLLOWED_OAK_INTO_LAB",
        "EVENT_FOLLOWED_OAK_INTO_LAB_2",
        "EVENT_OAK_ASKED_TO_CHOOSE_MON",
        "EVENT_GOT_STARTER",
        "EVENT_BATTLED_RIVAL_IN_OAKS_LAB",
        "EVENT_OAK_APPEARED_IN_PALLET",
    ]
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/event_constants.asm"))

    return try requiredFlags.map { flagID in
        guard contents.contains("const \(flagID)") else {
            throw ExtractorError.invalidArguments("missing event flag \(flagID)")
        }
        return EventFlagDefinition(id: flagID, sourceConstant: flagID)
    }
}

private func parseMapHeaders(repoRoot: URL) throws -> [String: String] {
    let pairs = [
        ("REDS_HOUSE_2F", "data/maps/headers/RedsHouse2F.asm"),
        ("REDS_HOUSE_1F", "data/maps/headers/RedsHouse1F.asm"),
        ("PALLET_TOWN", "data/maps/headers/PalletTown.asm"),
        ("OAKS_LAB", "data/maps/headers/OaksLab.asm"),
    ]

    return try pairs.reduce(into: [:]) { result, pair in
        let contents = try String(contentsOf: repoRoot.appendingPathComponent(pair.1))
        if let match = contents.firstMatch(of: /map_header\s+\w+,\s+[A-Z0-9_]+,\s+([A-Z0-9_]+)/) {
            result[pair.0] = String(match.output.1)
        }
    }
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
    default: return "Overworld_Coll"
    }
}

private func makeMapManifest(
    repoRoot: URL,
    mapID: String,
    displayName: String,
    objectFile: String,
    blockFile: String,
    size: TileSize,
    tileset: String,
    collisionBlockIDs: [Int],
    triggerRegions: [TriggerRegionManifest]
) throws -> MapManifest {
    let objectURL = repoRoot.appendingPathComponent(objectFile)
    let contents = try String(contentsOf: objectURL)
    let blockData = try Data(contentsOf: repoRoot.appendingPathComponent(blockFile))
    let borderBlockID = try parseBorderBlockID(contents: contents)

    return MapManifest(
        id: mapID,
        displayName: displayName,
        borderBlockID: borderBlockID,
        blockWidth: size.width,
        blockHeight: size.height,
        stepWidth: size.width * 2,
        stepHeight: size.height * 2,
        tileset: tileset,
        collisionBlockIDs: collisionBlockIDs,
        blockIDs: blockData.map(Int.init),
        warps: parseWarps(mapID: mapID, contents: contents),
        backgroundEvents: parseBackgroundEvents(mapID: mapID, contents: contents),
        objects: parseObjects(mapID: mapID, contents: contents),
        triggerRegions: triggerRegions
    )
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

private func buildTilesets() -> [TilesetManifest] {
    [
        .init(
            id: "REDS_HOUSE_1",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4
        ),
        .init(
            id: "REDS_HOUSE_2",
            imagePath: "Assets/field/tilesets/reds_house.png",
            blocksetPath: "Assets/field/blocksets/reds_house.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4
        ),
        .init(
            id: "OVERWORLD",
            imagePath: "Assets/field/tilesets/overworld.png",
            blocksetPath: "Assets/field/blocksets/overworld.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4
        ),
        .init(
            id: "DOJO",
            imagePath: "Assets/field/tilesets/gym.png",
            blocksetPath: "Assets/field/blocksets/gym.bst",
            sourceTileSize: 8,
            blockTileWidth: 4,
            blockTileHeight: 4
        ),
    ]
}

private func buildOverworldSprites() -> [OverworldSpriteManifest] {
    [
        buildCharacterSprite(id: "SPRITE_RED", imagePath: "Assets/field/sprites/red.png", includesRightFrame: true),
        buildCharacterSprite(id: "SPRITE_OAK", imagePath: "Assets/field/sprites/oak.png", includesRightFrame: true),
        buildCharacterSprite(id: "SPRITE_BLUE", imagePath: "Assets/field/sprites/blue.png", includesRightFrame: true),
        buildCharacterSprite(id: "SPRITE_MOM", imagePath: "Assets/field/sprites/mom.png", includesRightFrame: false),
        buildCharacterSprite(id: "SPRITE_GIRL", imagePath: "Assets/field/sprites/girl.png", includesRightFrame: true),
        buildCharacterSprite(id: "SPRITE_FISHER", imagePath: "Assets/field/sprites/fisher.png", includesRightFrame: true),
        buildCharacterSprite(id: "SPRITE_SCIENTIST", imagePath: "Assets/field/sprites/scientist.png", includesRightFrame: true),
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

private func buildCharacterSprite(id: String, imagePath: String, includesRightFrame: Bool) -> OverworldSpriteManifest {
    _ = includesRightFrame
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
        )
    )
}

private func parseWarps(mapID: String, contents: String) -> [WarpManifest] {
    let regex = try! NSRegularExpression(pattern: #"warp_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+(\d+)"#)
    let nsrange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    return regex.matches(in: contents, range: nsrange).enumerated().compactMap { index, match in
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

        let rawTarget = String(contents[targetRange])
        let resolved = resolveWarp(mapID: mapID, rawTargetMapID: rawTarget, targetWarp: targetWarp)
        return WarpManifest(
            id: "\(mapID.lowercased())_warp_\(index)",
            origin: .init(x: x, y: y),
            targetMapID: resolved.mapID,
            targetPosition: resolved.position,
            targetFacing: resolved.facing
        )
    }
}

private func resolveWarp(mapID: String, rawTargetMapID: String, targetWarp: Int) -> (mapID: String, position: TilePoint, facing: FacingDirection) {
    switch (mapID, rawTargetMapID, targetWarp) {
    case ("REDS_HOUSE_2F", "REDS_HOUSE_1F", 3):
        return ("REDS_HOUSE_1F", .init(x: 6, y: 2), .down)
    case ("REDS_HOUSE_1F", "REDS_HOUSE_2F", 1):
        return ("REDS_HOUSE_2F", .init(x: 6, y: 2), .down)
    case ("PALLET_TOWN", "REDS_HOUSE_1F", 1):
        return ("REDS_HOUSE_1F", .init(x: 2, y: 6), .down)
    case ("REDS_HOUSE_1F", "LAST_MAP", 1):
        return ("PALLET_TOWN", .init(x: 5, y: 6), .down)
    case ("REDS_HOUSE_1F", "LAST_MAP", 2):
        return ("PALLET_TOWN", .init(x: 5, y: 6), .down)
    case ("PALLET_TOWN", "OAKS_LAB", 2):
        return ("OAKS_LAB", .init(x: 4, y: 10), .up)
    case ("OAKS_LAB", "LAST_MAP", 3):
        return ("PALLET_TOWN", .init(x: 12, y: 12), .down)
    default:
        return (rawTargetMapID, .init(x: 0, y: 0), .down)
    }
}

private func parseBackgroundEvents(mapID: String, contents: String) -> [BackgroundEventManifest] {
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
            dialogueID: dialogueID(for: mapID, textID: textID)
        )
    }
}

private func parseObjects(mapID: String, contents: String) -> [MapObjectManifest] {
    let regex = try! NSRegularExpression(pattern: #"object_event\s+(\d+),\s+(\d+),\s+([A-Z0-9_]+),\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z0-9_]+)(?:,\s+([A-Z0-9_]+),\s+(\d+))?"#)
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
        let objectID = objectIDFor(mapID: mapID, index: index, textID: textID)
        let trainerBattleID = trainerBattleIDFor(mapID: mapID, textID: textID)

        return MapObjectManifest(
            id: objectID,
            displayName: displayNameForObject(objectID: objectID, textID: textID),
            sprite: sprite,
            position: .init(x: x, y: y),
            facing: facing,
            interactionDialogueID: dialogueID(for: mapID, textID: textID),
            movementType: movement,
            trainerBattleID: trainerBattleID,
            visibleByDefault: defaultVisibility(for: objectID)
        )
    }
}

private func objectIDFor(mapID: String, index: Int, textID: String) -> String {
    switch (mapID, textID) {
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_OAK"): return "pallet_town_oak"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_GIRL"): return "pallet_town_girl"
    case ("PALLET_TOWN", "TEXT_PALLETTOWN_FISHER"): return "pallet_town_fisher"
    case ("REDS_HOUSE_1F", "TEXT_REDSHOUSE1F_MOM"): return "reds_house_1f_mom"
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival"
    case ("OAKS_LAB", "TEXT_OAKSLAB_CHARMANDER_POKE_BALL"): return "oaks_lab_poke_ball_charmander"
    case ("OAKS_LAB", "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL"): return "oaks_lab_poke_ball_squirtle"
    case ("OAKS_LAB", "TEXT_OAKSLAB_BULBASAUR_POKE_BALL"): return "oaks_lab_poke_ball_bulbasaur"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK1"): return "oaks_lab_oak_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_OAK2"): return "oaks_lab_oak_2"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX1"): return "oaks_lab_pokedex_1"
    case ("OAKS_LAB", "TEXT_OAKSLAB_POKEDEX2"): return "oaks_lab_pokedex_2"
    default: return "\(mapID.lowercased())_object_\(index)"
    }
}

private func displayNameForObject(objectID: String, textID: String) -> String {
    switch objectID {
    case "pallet_town_oak": return "Oak"
    case "pallet_town_girl": return "Girl"
    case "pallet_town_fisher": return "Fisher"
    case "reds_house_1f_mom": return "Mom"
    case "oaks_lab_rival": return "Blue"
    case "oaks_lab_poke_ball_charmander": return "Charmander"
    case "oaks_lab_poke_ball_squirtle": return "Squirtle"
    case "oaks_lab_poke_ball_bulbasaur": return "Bulbasaur"
    case "oaks_lab_oak_1", "oaks_lab_oak_2": return "Oak"
    case "oaks_lab_pokedex_1", "oaks_lab_pokedex_2": return "Pokedex"
    default: return textID
    }
}

private func trainerBattleIDFor(mapID: String, textID: String) -> String? {
    mapID == "OAKS_LAB" && textID == "TEXT_OAKSLAB_RIVAL" ? "AUTO" : nil
}

private func defaultVisibility(for objectID: String) -> Bool {
    switch objectID {
    case "pallet_town_oak", "oaks_lab_oak_2":
        return false
    default:
        return true
    }
}

private func dialogueID(for mapID: String, textID: String) -> String {
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
    case ("OAKS_LAB", "TEXT_OAKSLAB_RIVAL"): return "oaks_lab_rival_gramps_isnt_around"
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
        return "\(mapID.lowercased())_\(textID.lowercased())"
    }
}

private func buildDialogues(repoRoot: URL) throws -> [DialogueManifest] {
    let pallet = try String(contentsOf: repoRoot.appendingPathComponent("text/PalletTown.asm"))
    let oaksLab = try String(contentsOf: repoRoot.appendingPathComponent("text/OaksLab.asm"))
    let redsHouse = try String(contentsOf: repoRoot.appendingPathComponent("text/RedsHouse1F.asm"))
    let text2 = try String(contentsOf: repoRoot.appendingPathComponent("data/text/text_2.asm"))

    return [
        try extractDialogue(id: "pallet_town_oak_hey_wait", label: "_PalletTownOakHeyWaitDontGoOutText", from: pallet),
        try extractDialogue(id: "pallet_town_oak_its_unsafe", label: "_PalletTownOakItsUnsafeText", from: pallet),
        try extractDialogue(id: "pallet_town_girl", label: "_PalletTownGirlText", from: pallet),
        try extractDialogue(id: "pallet_town_fisher", label: "_PalletTownFisherText", from: pallet),
        try extractDialogue(id: "pallet_town_oaks_lab_sign", label: "_PalletTownOaksLabSignText", from: pallet),
        try extractDialogue(id: "pallet_town_sign", label: "_PalletTownSignText", from: pallet),
        try extractDialogue(id: "pallet_town_players_house_sign", label: "_PalletTownPlayersHouseSignText", from: pallet),
        try extractDialogue(id: "pallet_town_rivals_house_sign", label: "_PalletTownRivalsHouseSignText", from: pallet),
        try extractDialogue(id: "reds_house_1f_mom_wakeup", label: "_RedsHouse1FMomWakeUpText", from: redsHouse),
        try extractDialogue(id: "reds_house_1f_mom_rest", label: "_RedsHouse1FMomYouShouldRestText", from: redsHouse),
        try extractDialogue(id: "reds_house_1f_mom_looking_great", label: "_RedsHouse1FMomLookingGreatText", from: redsHouse),
        try extractDialogue(id: "reds_house_1f_tv", label: "_RedsHouse1FTVStandByMeMovieText", from: redsHouse),
        try extractDialogue(id: "oaks_lab_rival_gramps_isnt_around", label: "_OaksLabRivalGrampsIsntAroundText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_go_ahead_and_choose", label: "_OaksLabRivalGoAheadAndChooseText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_my_pokemon_looks_stronger", label: "_OaksLabRivalMyPokemonLooksStrongerText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_those_are_pokeballs", label: "_OaksLabThoseArePokeBallsText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_you_want_charmander", label: "_OaksLabYouWantCharmanderText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_you_want_squirtle", label: "_OaksLabYouWantSquirtleText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_you_want_bulbasaur", label: "_OaksLabYouWantBulbasaurText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_mon_energetic", label: "_OaksLabMonEnergeticText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_last_mon", label: "_OaksLabLastMonText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_oak_which_pokemon_do_you_want", label: "_OaksLabOak1WhichPokemonDoYouWantText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_oak_raise_your_young_pokemon", label: "_OaksLabOak1RaiseYourYoungPokemonText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_pokedex", label: "_OaksLabPokedexText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_girl", label: "_OaksLabGirlText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_fed_up_with_waiting", label: "_OaksLabRivalFedUpWithWaitingText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_oak_choose_mon", label: "_OaksLabOakChooseMonText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_what_about_me", label: "_OaksLabRivalWhatAboutMeText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_oak_be_patient", label: "_OaksLabOakBePatientText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_oak_dont_go_away_yet", label: "_OaksLabOakDontGoAwayYetText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_ill_take_this_one", label: "_OaksLabRivalIllTakeThisOneText", from: oaksLab),
        makeReceivedDialogue(id: "oaks_lab_received_mon_charmander", speciesName: "CHARMANDER"),
        makeReceivedDialogue(id: "oaks_lab_received_mon_squirtle", speciesName: "SQUIRTLE"),
        makeReceivedDialogue(id: "oaks_lab_received_mon_bulbasaur", speciesName: "BULBASAUR"),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_charmander", speciesName: "CHARMANDER"),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_squirtle", speciesName: "SQUIRTLE"),
        makeRivalReceivedDialogue(id: "oaks_lab_rival_received_mon_bulbasaur", speciesName: "BULBASAUR"),
        try extractDialogue(id: "oaks_lab_rival_ill_take_you_on", label: "_OaksLabRivalIllTakeYouOnText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_i_picked_the_wrong_pokemon", label: "_OaksLabRivalIPickedTheWrongPokemonText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_am_i_great_or_what", label: "_OaksLabRivalAmIGreatOrWhatText", from: oaksLab),
        try extractDialogue(id: "oaks_lab_rival_smell_you_later", label: "_OaksLabRivalSmellYouLaterText", from: oaksLab),
        try extractDialogue(id: "rival_1_win_text", label: "_Rival1WinText", from: text2),
    ]
}

private func extractDialogue(id: String, label: String, from contents: String) throws -> DialogueManifest {
    guard let range = contents.range(of: "\(label)::") else {
        throw ExtractorError.invalidArguments("missing dialogue label \(label)")
    }

    let tail = contents[range.upperBound...]
    var lines: [String] = []
    var pages: [DialoguePage] = []

    for rawLine in tail.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasSuffix("::"), line.hasPrefix("_"), line.hasPrefix(label) == false {
            break
        }
        if line.hasPrefix("text \"") || line.hasPrefix("line \"") || line.hasPrefix("cont \"") || line.hasPrefix("para \"") {
            let value = extractQuotedString(from: line)
            if line.hasPrefix("para ") && lines.isEmpty == false {
                pages.append(.init(lines: lines, waitsForPrompt: true))
                lines = []
            }
            lines.append(value)
            if lines.count == 4 {
                pages.append(.init(lines: lines, waitsForPrompt: true))
                lines = []
            }
        } else if line.hasPrefix("text_ram") {
            lines.append("<NAME>")
        } else if line == "done" || line == "prompt" || line == "text_end" {
            if lines.isEmpty == false {
                pages.append(.init(lines: lines, waitsForPrompt: true))
                lines = []
            }
            if line == "text_end" || line == "done" || line == "prompt" {
                break
            }
        }
    }

    if lines.isEmpty == false {
        pages.append(.init(lines: lines, waitsForPrompt: true))
    }
    return DialogueManifest(id: id, pages: pages)
}

private func makeReceivedDialogue(id: String, speciesName: String) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<PLAYER> received", speciesName + "!"], waitsForPrompt: true)])
}

private func makeRivalReceivedDialogue(id: String, speciesName: String) -> DialogueManifest {
    DialogueManifest(id: id, pages: [.init(lines: ["<RIVAL> received", speciesName + "!"], waitsForPrompt: true)])
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

private func buildScripts() -> [ScriptManifest] {
    [
        ScriptManifest(
            id: "pallet_town_oak_intro",
            steps: [
                .init(action: "setFlag", flagID: "EVENT_OAK_APPEARED_IN_PALLET"),
                .init(action: "setObjectVisibility", objectID: "pallet_town_oak", visible: true),
                .init(action: "setObjectPosition", point: .init(x: 8, y: 3), objectID: "pallet_town_oak"),
                .init(action: "faceObject", stringValue: "down", objectID: "pallet_town_oak"),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_hey_wait"),
                .init(action: "showDialogue", dialogueID: "pallet_town_oak_its_unsafe"),
                .init(action: "setMap", stringValue: "OAKS_LAB", point: .init(x: 5, y: 10)),
                .init(action: "facePlayer", stringValue: "up"),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB"),
                .init(action: "setFlag", flagID: "EVENT_FOLLOWED_OAK_INTO_LAB_2"),
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
                .init(action: "showDialogue", dialogueID: "oaks_lab_oak_dont_go_away_yet"),
                .init(action: "movePlayer", path: [.up]),
                .init(action: "facePlayer", stringValue: "up"),
            ]
        ),
        ScriptManifest(
            id: "oaks_lab_rival_challenge",
            steps: [
                .init(action: "showDialogue", dialogueID: "oaks_lab_rival_ill_take_you_on"),
                .init(action: "startBattle", battleID: "AUTO"),
            ]
        ),
    ]
}

private func buildSpecies(repoRoot: URL) throws -> [SpeciesManifest] {
    try [
        parseSpecies(repoRoot: repoRoot, file: "data/pokemon/base_stats/charmander.asm", id: "CHARMANDER", displayName: "Charmander"),
        parseSpecies(repoRoot: repoRoot, file: "data/pokemon/base_stats/squirtle.asm", id: "SQUIRTLE", displayName: "Squirtle"),
        parseSpecies(repoRoot: repoRoot, file: "data/pokemon/base_stats/bulbasaur.asm", id: "BULBASAUR", displayName: "Bulbasaur"),
    ]
}

private func parseSpecies(repoRoot: URL, file: String, id: String, displayName: String) throws -> SpeciesManifest {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent(file))
    guard let statsMatch = contents.firstMatch(of: /db\s+(\d+),\s+(\d+),\s+(\d+),\s+(\d+),\s+(\d+)\s*\n\s*;\s*hp\s+atk\s+def\s+spd\s+spc/),
          let moveMatch = contents.firstMatch(of: /db\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z_]+),\s+([A-Z_]+)\s*; level 1 learnset/)
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

    return SpeciesManifest(
        id: id,
        displayName: displayName,
        baseHP: statsValues[safe: 0] ?? 0,
        baseAttack: statsValues[safe: 1] ?? 0,
        baseDefense: statsValues[safe: 2] ?? 0,
        baseSpeed: statsValues[safe: 3] ?? 0,
        baseSpecial: statsValues[safe: 4] ?? 0,
        startingMoves: moveValues.filter { $0 != "NO_MOVE" }
    )
}

private func buildMoves(repoRoot: URL) throws -> [MoveManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/moves.asm"))
    let needed = Set(["SCRATCH", "TACKLE", "GROWL", "TAIL_WHIP"])
    return contents.split(separator: "\n").compactMap { rawLine in
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard line.hasPrefix("move ") else { return nil }
        let parts = line.replacingOccurrences(of: "move", with: "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 6, needed.contains(parts[0]) else { return nil }
        return MoveManifest(
            id: parts[0],
            displayName: parts[0].replacingOccurrences(of: "_", with: " "),
            power: Int(parts[2]) ?? 0,
            accuracy: Int(parts[4]) ?? 100,
            maxPP: Int(parts[5]) ?? 0,
            effect: parts[1],
            type: parts[3]
        )
    }
}

private func buildTrainerBattles() -> [TrainerBattleManifest] {
    [
        .init(
            id: "rival_lab_squirtle",
            trainerClass: "OPP_RIVAL1",
            trainerNumber: 1,
            displayName: "BLUE",
            enemySpeciesID: "SQUIRTLE",
            enemyLevel: 5,
            winDialogueID: "oaks_lab_rival_i_picked_the_wrong_pokemon",
            loseDialogueID: "oaks_lab_rival_am_i_great_or_what",
            healsPartyAfterBattle: true,
            preventsBlackoutOnLoss: true,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
        ),
        .init(
            id: "rival_lab_bulbasaur",
            trainerClass: "OPP_RIVAL1",
            trainerNumber: 2,
            displayName: "BLUE",
            enemySpeciesID: "BULBASAUR",
            enemyLevel: 5,
            winDialogueID: "oaks_lab_rival_i_picked_the_wrong_pokemon",
            loseDialogueID: "oaks_lab_rival_am_i_great_or_what",
            healsPartyAfterBattle: true,
            preventsBlackoutOnLoss: true,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
        ),
        .init(
            id: "rival_lab_charmander",
            trainerClass: "OPP_RIVAL1",
            trainerNumber: 3,
            displayName: "BLUE",
            enemySpeciesID: "CHARMANDER",
            enemyLevel: 5,
            winDialogueID: "oaks_lab_rival_i_picked_the_wrong_pokemon",
            loseDialogueID: "oaks_lab_rival_am_i_great_or_what",
            healsPartyAfterBattle: true,
            preventsBlackoutOnLoss: true,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB"
        ),
    ]
}

private func facingDirection(from raw: String) -> FacingDirection {
    switch raw {
    case "UP", "PLAYER_DIR_UP": return .up
    case "DOWN", "PLAYER_DIR_DOWN": return .down
    case "LEFT": return .left
    case "RIGHT": return .right
    default: return .down
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
