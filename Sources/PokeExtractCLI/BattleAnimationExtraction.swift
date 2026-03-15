import Foundation
import PokeDataModel

private let battleAnimationSourceFiles = [
    "data/moves/animations.asm",
    "data/battle_anims/subanimations.asm",
    "data/battle_anims/frame_blocks.asm",
    "data/battle_anims/base_coords.asm",
    "data/battle_anims/special_effect_pointers.asm",
    "constants/move_animation_constants.asm",
    "engine/battle/animations.asm",
    "gfx/battle/move_anim_0.png",
    "gfx/battle/move_anim_1.png",
]

func extractBattleAnimationManifest(source: SourceTree) throws -> BattleAnimationManifest {
    let repoRoot = source.repoRoot
    let constantsContents = try String(
        contentsOf: repoRoot.appendingPathComponent("constants/move_animation_constants.asm")
    )

    let moveIDs = try parseMoveIDsForAnimationOrder(repoRoot: repoRoot)
    let moveAnimationPointerLabels = try parseAttackAnimationPointerLabels(repoRoot: repoRoot)
    guard moveIDs.count == moveAnimationPointerLabels.count else {
        throw ExtractorError.invalidArguments(
            "move animation pointer count \(moveAnimationPointerLabels.count) did not match move count \(moveIDs.count)"
        )
    }

    let commandStreamsByLabel = try parseMoveAnimationCommandStreams(repoRoot: repoRoot)
    let moveAnimations = zip(moveIDs, moveAnimationPointerLabels).map { moveID, label in
        BattleMoveAnimationManifest(
            moveID: moveID,
            commands: commandStreamsByLabel[label] ?? []
        )
    }

    let subanimationIDs = parseAnimationConstantSection(
        contents: constantsContents,
        startMarker: "; subanimations that are part of move animations",
        endMarker: "DEF NUM_SUBANIMS",
        prefix: "SUBANIM_"
    )
    let subanimationPointerLabels = try parsePointerLabels(
        at: repoRoot.appendingPathComponent("data/battle_anims/subanimations.asm"),
        tableLabel: "SubanimationPointers"
    )
    guard subanimationIDs.count == subanimationPointerLabels.count else {
        throw ExtractorError.invalidArguments(
            "subanimation id count \(subanimationIDs.count) did not match pointer count \(subanimationPointerLabels.count)"
        )
    }
    let subanimationBodies = try parseSubanimationBodies(repoRoot: repoRoot)
    let subanimations = try zip(subanimationIDs, subanimationPointerLabels).map { id, label in
        guard let body = subanimationBodies[label] else {
            throw ExtractorError.invalidArguments("missing subanimation body for \(label)")
        }
        return BattleSubanimationManifest(
            id: id,
            transform: body.transform,
            steps: body.steps
        )
    }

    let frameBlockIDs = parseAnimationConstantSection(
        contents: constantsContents,
        startMarker: "; frame blocks that are part of subanimations",
        endMarker: "DEF NUM_FRAMEBLOCKS",
        prefix: "FRAMEBLOCK_"
    )
    let frameBlockPointerLabels = try parsePointerLabels(
        at: repoRoot.appendingPathComponent("data/battle_anims/frame_blocks.asm"),
        tableLabel: "FrameBlockPointers"
    )
    guard frameBlockIDs.count == frameBlockPointerLabels.count else {
        throw ExtractorError.invalidArguments(
            "frame block id count \(frameBlockIDs.count) did not match pointer count \(frameBlockPointerLabels.count)"
        )
    }
    let frameBlockBodies = try parseFrameBlockBodies(repoRoot: repoRoot)
    let frameBlocks = try zip(frameBlockIDs, frameBlockPointerLabels).map { id, label in
        guard let tiles = frameBlockBodies[label] else {
            throw ExtractorError.invalidArguments("missing frame block body for \(label)")
        }
        return BattleAnimationFrameBlockManifest(id: id, tiles: tiles)
    }

    let baseCoordinates = try parseBaseCoordinates(repoRoot: repoRoot)
    let specialEffects = try parseSpecialEffects(repoRoot: repoRoot)
    let tilesets = try parseBattleAnimationTilesets(repoRoot: repoRoot)

    return BattleAnimationManifest(
        variant: .red,
        sourceFiles: battleAnimationSourceFiles,
        moveAnimations: moveAnimations,
        subanimations: subanimations,
        frameBlocks: frameBlocks,
        baseCoordinates: baseCoordinates,
        specialEffects: specialEffects,
        tilesets: tilesets
    )
}

private func parseMoveIDsForAnimationOrder(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/moves.asm"))
    return contents
        .split(separator: "\n")
        .compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("move ") else { return nil }
            return line
                .replacingOccurrences(of: "move", with: "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first
        }
}

private func parseAttackAnimationPointerLabels(repoRoot: URL) throws -> [String] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/animations.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var collecting = false
    var labels: [String] = []

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line == "AttackAnimationPointers:" {
            collecting = true
            continue
        }
        guard collecting else { continue }
        if line.hasPrefix("assert_table_length NUM_ATTACKS") || line.hasPrefix("MACRO battle_anim") {
            break
        }
        guard let match = line.firstMatch(of: /dw\s+([A-Za-z0-9_]+)/) else {
            continue
        }
        labels.append(String(match.output.1))
    }

    return labels
}

private func parseMoveAnimationCommandStreams(repoRoot: URL) throws -> [String: [BattleAnimationCommandManifest]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/moves/animations.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var streams: [String: [BattleAnimationCommandManifest]] = [:]
    var pendingLabels: [String] = []
    var pendingCommands: [BattleAnimationCommandManifest]?

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if let match = line.firstMatch(of: /^([A-Za-z0-9_]+):$/) {
            pendingLabels.append(String(match.output.1))
            continue
        }
        guard line.hasPrefix("battle_anim ") || line.hasPrefix("db -1") else {
            continue
        }
        if line.hasPrefix("battle_anim ") {
            if pendingCommands == nil {
                pendingCommands = []
            }
            pendingCommands?.append(try parseBattleAnimationCommand(line: line))
            continue
        }
        if let commands = pendingCommands {
            for label in pendingLabels {
                streams[label] = commands
            }
        }
        pendingLabels = []
        pendingCommands = nil
    }

    return streams
}

private func parseBattleAnimationCommand(line: String) throws -> BattleAnimationCommandManifest {
    guard let match = line.firstMatch(
        of: /battle_anim\s+([^,]+),\s*([^,]+)(?:,\s*([^,]+),\s*([^,]+))?/
    ) else {
        throw ExtractorError.invalidArguments("unsupported battle animation command \(line)")
    }

    let firstToken = String(match.output.1).trimmingCharacters(in: .whitespaces)
    let secondToken = String(match.output.2).trimmingCharacters(in: .whitespaces)
    let soundMoveID = firstToken == "NO_MOVE" ? nil : firstToken

    if let tilesetToken = match.output.3,
       let delayToken = match.output.4 {
        let rawTilesetID = String(tilesetToken).trimmingCharacters(in: .whitespaces)
        let delayFrames = try parseNumericToken(String(delayToken).trimmingCharacters(in: .whitespaces))
        return BattleAnimationCommandManifest(
            kind: .subanimation,
            soundMoveID: soundMoveID,
            subanimationID: secondToken,
            tilesetID: "MOVE_ANIM_TILESET_\(rawTilesetID)",
            delayFrames: delayFrames
        )
    }

    return BattleAnimationCommandManifest(
        kind: .specialEffect,
        soundMoveID: soundMoveID,
        specialEffectID: secondToken
    )
}

private func parseAnimationConstantSection(
    contents: String,
    startMarker: String,
    endMarker: String,
    prefix: String
) -> [String] {
    var collecting = false
    var constants: [String] = []

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if collecting == false {
            if line == startMarker {
                collecting = true
            }
            continue
        }
        if line.hasPrefix(endMarker) {
            break
        }
        let targetPrefix = "const \(prefix)"
        guard line.hasPrefix(targetPrefix) else {
            continue
        }
        let identifier = line.replacingOccurrences(of: "const ", with: "")
        let token = identifier
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces)
        if let token {
            constants.append(token)
        }
    }

    return constants
}

private func parsePointerLabels(at fileURL: URL, tableLabel: String) throws -> [String] {
    let contents = try String(contentsOf: fileURL)
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var collecting = false
    var labels: [String] = []

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line == "\(tableLabel):" {
            collecting = true
            continue
        }
        guard collecting else { continue }
        if line.hasPrefix("assert_table_length") || line.hasPrefix("MACRO ") {
            break
        }
        guard let match = line.firstMatch(of: /dw\s+([A-Za-z0-9_]+)/) else {
            continue
        }
        labels.append(String(match.output.1))
    }

    return labels
}

private func parseSubanimationBodies(
    repoRoot: URL
) throws -> [String: (transform: BattleAnimationTransform, steps: [BattleAnimationSubanimationStepManifest])] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/battle_anims/subanimations.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var bodies: [String: (transform: BattleAnimationTransform, steps: [BattleAnimationSubanimationStepManifest])] = [:]
    var index = 0
    var currentLabel: String?

    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)
        if let match = line.firstMatch(of: /^([A-Za-z0-9_]+):$/) {
            currentLabel = String(match.output.1)
            index += 1
            continue
        }
        guard let currentLabel,
              let match = line.firstMatch(of: /subanim\s+(SUBANIMTYPE_[A-Z0-9_]+),\s*(\d+)/),
              let transform = BattleAnimationTransform(rawValue: String(match.output.1)),
              let stepCount = Int(String(match.output.2)) else {
            index += 1
            continue
        }

        var steps: [BattleAnimationSubanimationStepManifest] = []
        for offset in 1...stepCount {
            let stepLine = lines[index + offset].trimmingCharacters(in: .whitespaces)
            guard let stepMatch = stepLine.firstMatch(
                of: /db\s+(FRAMEBLOCK_[A-Z0-9_]+),\s+(BASECOORD_[A-Z0-9_]+),\s+(FRAMEBLOCKMODE_[A-Z0-9_]+)/
            ),
            let frameBlockMode = BattleAnimationFrameBlockMode(rawValue: String(stepMatch.output.3)) else {
                throw ExtractorError.invalidArguments("invalid subanimation step \(stepLine)")
            }
            steps.append(
                BattleAnimationSubanimationStepManifest(
                    frameBlockID: String(stepMatch.output.1),
                    baseCoordinateID: String(stepMatch.output.2),
                    frameBlockMode: frameBlockMode
                )
            )
        }
        bodies[currentLabel] = (transform, steps)
        index += stepCount + 1
    }

    return bodies
}

private func parseFrameBlockBodies(repoRoot: URL) throws -> [String: [BattleAnimationFrameTileManifest]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/battle_anims/frame_blocks.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var bodies: [String: [BattleAnimationFrameTileManifest]] = [:]
    var index = 0
    var currentLabel: String?

    while index < lines.count {
        let line = lines[index].trimmingCharacters(in: .whitespaces)
        if let match = line.firstMatch(of: /^([A-Za-z0-9_]+):$/) {
            currentLabel = String(match.output.1)
            index += 1
            continue
        }
        guard let currentLabel,
              let countMatch = line.firstMatch(of: /db\s+(\d+)/),
              let tileCount = Int(String(countMatch.output.1)) else {
            index += 1
            continue
        }

        var tiles: [BattleAnimationFrameTileManifest] = []
        if tileCount > 0 {
            for offset in 1...tileCount {
                let tileLine = lines[index + offset].trimmingCharacters(in: .whitespaces)
                guard let tile = try parseFrameBlockTile(line: tileLine) else {
                    throw ExtractorError.invalidArguments("invalid frame block tile \(tileLine)")
                }
                tiles.append(tile)
            }
        }
        bodies[currentLabel] = tiles
        index += tileCount + 1
    }

    return bodies
}

private func parseFrameBlockTile(line: String) throws -> BattleAnimationFrameTileManifest? {
    guard let match = line.firstMatch(
        of: /dbsprite\s+([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*(\$?[0-9A-Fa-f]+),\s*(.+)$/
    ) else {
        return nil
    }

    let xTile = try parseNumericToken(String(match.output.1).trimmingCharacters(in: .whitespaces))
    let yTile = try parseNumericToken(String(match.output.2).trimmingCharacters(in: .whitespaces))
    let xPixel = try parseNumericToken(String(match.output.3).trimmingCharacters(in: .whitespaces))
    let yPixel = try parseNumericToken(String(match.output.4).trimmingCharacters(in: .whitespaces))
    let tileID = try parseNumericToken(String(match.output.5).trimmingCharacters(in: .whitespaces))
    let flags = String(match.output.6).trimmingCharacters(in: .whitespaces)

    return BattleAnimationFrameTileManifest(
        x: (xTile * 8) + xPixel,
        y: (yTile * 8) + yPixel,
        tileID: tileID,
        flipH: flags.contains("OAM_XFLIP"),
        flipV: flags.contains("OAM_YFLIP")
    )
}

private func parseBaseCoordinates(repoRoot: URL) throws -> [BattleAnimationBaseCoordinateManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/battle_anims/base_coords.asm"))
    var coordinates: [BattleAnimationBaseCoordinateManifest] = []
    for rawLine in contents.split(separator: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        guard let match = line.firstMatch(
            of: /db\s+(\$[0-9A-Fa-f]+),\s*(\$[0-9A-Fa-f]+)\s*;\s*(BASECOORD_[A-Z0-9_]+)/
        ) else {
            continue
        }
        let y = try parseNumericToken(String(match.output.1))
        let x = try parseNumericToken(String(match.output.2))
        coordinates.append(
            BattleAnimationBaseCoordinateManifest(
                id: String(match.output.3),
                x: x,
                y: y
            )
        )
    }
    return coordinates
}

private func parseSpecialEffects(repoRoot: URL) throws -> [BattleAnimationSpecialEffectManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/battle_anims/special_effect_pointers.asm"))
    return contents
        .split(separator: "\n")
        .compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let match = line.firstMatch(
                of: /special_effect\s+(SE_[A-Z0-9_]+),\s+([A-Za-z0-9_]+)/
            ) else {
                return nil
            }
            return BattleAnimationSpecialEffectManifest(
                id: String(match.output.1),
                routine: String(match.output.2)
            )
        }
}

private func parseBattleAnimationTilesets(repoRoot: URL) throws -> [BattleAnimationTilesetManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("engine/battle/animations.asm"))
    let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
    var collecting = false
    var tilesets: [BattleAnimationTilesetManifest] = []

    for rawLine in lines {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line == "MoveAnimationTilesPointers:" {
            collecting = true
            continue
        }
        guard collecting else { continue }
        if line.hasPrefix("MoveAnimationTiles0:") {
            break
        }
        guard let match = line.firstMatch(of: /anim_tileset\s+(\d+),\s+([A-Za-z0-9_]+)/),
              let tileCount = Int(String(match.output.1)) else {
            continue
        }
        let sourceLabel = String(match.output.2)
        let imagePath: String
        switch sourceLabel {
        case "MoveAnimationTiles1":
            imagePath = "Assets/battle/animations/move_anim_1.png"
        default:
            imagePath = "Assets/battle/animations/move_anim_0.png"
        }
        tilesets.append(
            BattleAnimationTilesetManifest(
                id: "MOVE_ANIM_TILESET_\(tilesets.count)",
                tileCount: tileCount,
                imagePath: imagePath
            )
        )
    }

    return tilesets
}

private func parseNumericToken(_ token: String) throws -> Int {
    if token.hasPrefix("$") {
        guard let value = Int(token.dropFirst(), radix: 16) else {
            throw ExtractorError.invalidArguments("invalid hex token \(token)")
        }
        return value
    }
    guard let value = Int(token) else {
        throw ExtractorError.invalidArguments("invalid decimal token \(token)")
    }
    return value
}
