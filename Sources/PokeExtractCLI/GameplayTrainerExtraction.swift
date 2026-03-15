import Foundation
import PokeDataModel

func buildTrainerBattles(
    repoRoot: URL,
    mapScriptMetadataByMapID: [String: MapScriptMetadata]
) throws -> [TrainerBattleManifest] {
    let trainerClassMetadataByID = try parseTrainerClassMetadata(repoRoot: repoRoot)
    let trainerEncounterCueByClass = try parseTrainerEncounterCueIDs(repoRoot: repoRoot)
    let rivalClassMetadata = try trainerClassMetadataByID
        .value(for: "OPP_RIVAL1", missingMessage: "missing trainer metadata for OPP_RIVAL1")
    let brockClassMetadata = try trainerClassMetadataByID
        .value(for: "OPP_BROCK", missingMessage: "missing trainer metadata for OPP_BROCK")
    let superNerdClassMetadata = try trainerClassMetadataByID
        .value(for: "OPP_SUPER_NERD", missingMessage: "missing trainer metadata for OPP_SUPER_NERD")

    var battlesByID: [String: TrainerBattleManifest] = [:]

    func makeRivalBattle(
        id: String,
        trainerNumber: Int,
        playerWinDialogueID: String,
        playerLoseDialogueID: String?,
        healsPartyAfterBattle: Bool,
        preventsBlackoutOnLoss: Bool,
        completionFlagID: String,
        postBattleScriptID: String?,
        runsPostBattleScriptOnLoss: Bool = false
    ) throws -> TrainerBattleManifest {
        guard rivalClassMetadata.parties.indices.contains(trainerNumber - 1) else {
            throw ExtractorError.invalidArguments("missing Rival1 trainer party \(trainerNumber)")
        }

        return TrainerBattleManifest(
            id: id,
            trainerClass: "OPP_RIVAL1",
            trainerNumber: trainerNumber,
            displayName: "BLUE",
            party: rivalClassMetadata.parties[trainerNumber - 1],
            trainerSpritePath: rivalClassMetadata.trainerSpritePath,
            baseRewardMoney: rivalClassMetadata.baseRewardMoney,
            encounterAudioCueID: trainerEncounterCueByClass["OPP_RIVAL1"],
            playerWinDialogueID: playerWinDialogueID,
            playerLoseDialogueID: playerLoseDialogueID,
            healsPartyAfterBattle: healsPartyAfterBattle,
            preventsBlackoutOnLoss: preventsBlackoutOnLoss,
            completionFlagID: completionFlagID,
            postBattleScriptID: postBattleScriptID,
            runsPostBattleScriptOnLoss: runsPostBattleScriptOnLoss
        )
    }

    for trainerNumber in 1...3 {
        battlesByID["opp_rival1_\(trainerNumber)"] = try makeRivalBattle(
            id: "opp_rival1_\(trainerNumber)",
            trainerNumber: trainerNumber,
            playerWinDialogueID: "oaks_lab_rival_i_picked_the_wrong_pokemon",
            playerLoseDialogueID: "oaks_lab_rival_am_i_great_or_what",
            healsPartyAfterBattle: true,
            preventsBlackoutOnLoss: true,
            completionFlagID: "EVENT_BATTLED_RIVAL_IN_OAKS_LAB",
            postBattleScriptID: "oaks_lab_rival_exit_after_battle",
            runsPostBattleScriptOnLoss: true
        )
    }

    for (battleID, trainerNumber, postBattleScriptID) in [
        ("route_22_rival_1_4_upper", 4, "route_22_rival_1_exit_upper"),
        ("route_22_rival_1_5_upper", 5, "route_22_rival_1_exit_upper"),
        ("route_22_rival_1_6_upper", 6, "route_22_rival_1_exit_upper"),
        ("route_22_rival_1_4_lower", 4, "route_22_rival_1_exit_lower"),
        ("route_22_rival_1_5_lower", 5, "route_22_rival_1_exit_lower"),
        ("route_22_rival_1_6_lower", 6, "route_22_rival_1_exit_lower"),
    ] {
        battlesByID[battleID] = try makeRivalBattle(
            id: battleID,
            trainerNumber: trainerNumber,
            playerWinDialogueID: "route_22_rival_1_defeated",
            playerLoseDialogueID: "route_22_rival_1_victory",
            healsPartyAfterBattle: false,
            preventsBlackoutOnLoss: false,
            completionFlagID: "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE",
            postBattleScriptID: postBattleScriptID
        )
    }

    guard brockClassMetadata.parties.indices.contains(0) else {
        throw ExtractorError.invalidArguments("missing Brock trainer party 1")
    }

    battlesByID["opp_brock_1"] = TrainerBattleManifest(
        id: "opp_brock_1",
        trainerClass: "OPP_BROCK",
        trainerNumber: 1,
        displayName: brockClassMetadata.displayName,
        party: brockClassMetadata.parties[0],
        trainerSpritePath: brockClassMetadata.trainerSpritePath,
        baseRewardMoney: brockClassMetadata.baseRewardMoney,
        encounterAudioCueID: trainerEncounterCueByClass["OPP_BROCK"],
        playerWinDialogueID: "pewter_gym_brock_received_boulder_badge",
        playerLoseDialogueID: nil,
        healsPartyAfterBattle: false,
        preventsBlackoutOnLoss: false,
        completionFlagID: "EVENT_BEAT_BROCK",
        postBattleScriptID: "pewter_gym_brock_reward"
    )

    guard superNerdClassMetadata.parties.indices.contains(1) else {
        throw ExtractorError.invalidArguments("missing Super Nerd trainer party 2")
    }

    battlesByID["opp_super_nerd_2"] = TrainerBattleManifest(
        id: "opp_super_nerd_2",
        trainerClass: "OPP_SUPER_NERD",
        trainerNumber: 2,
        displayName: superNerdClassMetadata.displayName,
        party: superNerdClassMetadata.parties[1],
        trainerSpritePath: superNerdClassMetadata.trainerSpritePath,
        baseRewardMoney: superNerdClassMetadata.baseRewardMoney,
        encounterAudioCueID: trainerEncounterCueByClass["OPP_SUPER_NERD"],
        playerWinDialogueID: "mt_moon_b2f_super_nerd_ok_ill_share",
        playerLoseDialogueID: nil,
        healsPartyAfterBattle: false,
        preventsBlackoutOnLoss: false,
        completionFlagID: "EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD",
        postBattleScriptID: nil
    )

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

func buildTrainerAIMoveChoiceModifications(repoRoot: URL) throws -> [TrainerAIMoveChoiceModificationManifest] {
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

private extension Dictionary {
    func value(for key: Key, missingMessage: @autoclosure () -> String) throws -> Value {
        guard let value = self[key] else {
            throw ExtractorError.invalidArguments(missingMessage())
        }
        return value
    }
}
