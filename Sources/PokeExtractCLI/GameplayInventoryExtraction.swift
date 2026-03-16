import Foundation
import PokeDataModel

func buildItems(repoRoot: URL) throws -> [ItemManifest] {
    let namesByID = try parseItemNames(repoRoot: repoRoot)
    let keyItemIDs = try parseKeyItemIDs(repoRoot: repoRoot)
    let pricesByID = try parseItemPrices(repoRoot: repoRoot)
    let movesByID = Dictionary(uniqueKeysWithValues: try buildMoves(repoRoot: repoRoot).map { ($0.id, $0) })
    let tmhmMoveIDByItemID = try parseTMHMMoveIDs(repoRoot: repoRoot)

    return try parseDefinedItemIDs(repoRoot: repoRoot).map { itemID in
        let battleUse = battleUseKind(for: itemID)
        let tmhmMoveID = tmhmMoveIDByItemID[itemID]
        let move = tmhmMoveID.flatMap { movesByID[$0] }
        let supplementalMetadata = buildSupplementalItemMetadata(
            itemID: itemID,
            displayName: namesByID[itemID] ?? itemID,
            isKeyItem: keyItemIDs.contains(itemID),
            battleUse: battleUse,
            tmhmMoveID: tmhmMoveID,
            tmhmMoveDisplayName: move?.displayName,
            tmhmMoveType: move?.type
        )
        return ItemManifest(
            id: itemID,
            displayName: namesByID[itemID] ?? itemID,
            price: pricesByID[itemID] ?? 0,
            isKeyItem: keyItemIDs.contains(itemID),
            bagSection: supplementalMetadata.bagSection,
            shortDescription: supplementalMetadata.shortDescription,
            iconAssetPath: supplementalMetadata.iconAssetPath,
            tmhmMoveID: supplementalMetadata.tmhmMoveID,
            battleUse: battleUse
        )
    }
}

func buildMarts(
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

func parseItemNames(repoRoot: URL) throws -> [String: String] {
    let constants = try String(contentsOf: repoRoot.appendingPathComponent("constants/item_constants.asm"))
    let itemIDs = try parseDefinedItemIDs(repoRoot: repoRoot)
    let names = try String(contentsOf: repoRoot.appendingPathComponent("data/items/names.asm"))

    let itemNames = names
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("li \"") else { return nil }
            return extractQuotedString(from: line)
        }

    var result = Dictionary(uniqueKeysWithValues: zip(itemIDs, itemNames))
    result.merge(parseTMHMDisplayNames(constants: constants)) { current, _ in current }
    return result
}

func parseMartStocks(repoRoot: URL) throws -> [String: [String]] {
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
    var result = Dictionary(uniqueKeysWithValues: zip(itemIDs, prices))
    result.merge(try parseTMPrices(repoRoot: repoRoot)) { current, _ in current }
    return result
}

private func parseDefinedItemIDs(repoRoot: URL) throws -> [String] {
    let constants = try String(contentsOf: repoRoot.appendingPathComponent("constants/item_constants.asm"))
    let baseItemIDs = constants
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
    let referencedTMHMItemIDs = try parseReferencedTMHMItemIDs(repoRoot: repoRoot, constants: constants)
    return baseItemIDs + referencedTMHMItemIDs.filter { baseItemIDs.contains($0) == false }
}

private func parseReferencedTMHMItemIDs(repoRoot: URL, constants: String) throws -> [String] {
    let knownTMHMItemIDs = Set(parseTMHMDisplayNames(constants: constants).keys)
    guard knownTMHMItemIDs.isEmpty == false else { return [] }

    var referencedItemIDs: Set<String> = []
    for definition in gameplayCoverageMaps {
        let scriptURL = repoRoot.appendingPathComponent(scriptPathForMap(definition))
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            continue
        }
        let contents = try String(contentsOf: scriptURL)
        for match in contents.matches(of: /(?:TM|HM)_[A-Z0-9_]+/) {
            referencedItemIDs.insert(String(match.output))
        }
    }

    return referencedItemIDs
        .filter { knownTMHMItemIDs.contains($0) }
        .sorted()
}

private func parseTMHMDisplayNames(constants: String) -> [String: String] {
    var result: [String: String] = [:]
    var hmIndex = 1
    var tmIndex = 1

    for rawLine in constants.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if let match = line.firstMatch(of: /add_hm\s+([A-Z0-9_]+)/) {
            result["HM_\(match.output.1)"] = String(format: "HM%02d", hmIndex)
            hmIndex += 1
            continue
        }

        if let match = line.firstMatch(of: /add_tm\s+([A-Z0-9_]+)/) {
            result["TM_\(match.output.1)"] = String(format: "TM%02d", tmIndex)
            tmIndex += 1
        }
    }

    return result
}

private func parseTMPrices(repoRoot: URL) throws -> [String: Int] {
    let constants = try String(contentsOf: repoRoot.appendingPathComponent("constants/item_constants.asm"))
    let tmPriceContents = try String(contentsOf: repoRoot.appendingPathComponent("data/items/tm_prices.asm"))
    let tmIDs = constants
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> String? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard let match = line.firstMatch(of: /add_tm\s+([A-Z0-9_]+)/) else {
                return nil
            }
            return "TM_\(match.output.1)"
        }
    let tmPrices = tmPriceContents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .compactMap { rawLine -> Int? in
            let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            guard let match = line.firstMatch(of: /nybble\s+([0-9]+)/) else {
                return nil
            }
            return (Int(match.output.1) ?? 0) * 1000
        }

    return Dictionary(uniqueKeysWithValues: zip(tmIDs, tmPrices))
}

private func parseTMHMMoveIDs(repoRoot: URL) throws -> [String: String] {
    let constants = try String(contentsOf: repoRoot.appendingPathComponent("constants/item_constants.asm"))
    var result: [String: String] = [:]

    for rawLine in constants.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = rawLine.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false).first?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if let match = line.firstMatch(of: /add_hm\s+([A-Z0-9_]+)/) {
            result["HM_\(match.output.1)"] = String(match.output.1)
            continue
        }

        if let match = line.firstMatch(of: /add_tm\s+([A-Z0-9_]+)/) {
            result["TM_\(match.output.1)"] = String(match.output.1)
        }
    }

    return result
}

private func battleUseKind(for itemID: String) -> ItemManifest.BattleUseKind {
    switch itemID {
    case "MASTER_BALL", "ULTRA_BALL", "GREAT_BALL", "POKE_BALL", "SAFARI_BALL":
        return .ball
    default:
        return .none
    }
}
