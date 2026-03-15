import Foundation
import PokeDataModel

func buildSpecies(repoRoot: URL) throws -> [SpeciesManifest] {
    let speciesDefinitions = try parseCanonicalSpeciesDefinitions(repoRoot: repoRoot)
    let progressionBySpeciesID = try parseSpeciesProgression(repoRoot: repoRoot)
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
            evolutions: progressionBySpeciesID[definition.id]?.evolutions ?? [],
            levelUpLearnset: progressionBySpeciesID[definition.id]?.levelUpLearnset ?? [],
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

private func parseSpeciesProgression(repoRoot: URL) throws -> [String: SpeciesProgressionManifest] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/pokemon/evos_moves.asm"))
    var progressionByLabel: [String: SpeciesProgressionManifest] = [:]
    var currentLabel: String?
    var currentEvolutions: [EvolutionManifest] = []
    var currentLearnset: [LevelUpMoveManifest] = []
    var section: SpeciesProgressionSection = .none

    func flushCurrentSpecies() {
        guard let currentLabel else { return }
        progressionByLabel[currentLabel] = SpeciesProgressionManifest(
            evolutions: currentEvolutions,
            levelUpLearnset: currentLearnset
        )
    }

    for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmedLine = rawLine.trimmingCharacters(in: .whitespaces)
        let line = rawLine
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if let match = line.firstMatch(of: /([A-Za-z0-9]+)EvosMoves:/) {
            flushCurrentSpecies()
            currentLabel = String(match.output.1)
            currentEvolutions = []
            currentLearnset = []
            section = .none
            continue
        }
        guard currentLabel != nil else {
            continue
        }
        if trimmedLine == "; Evolutions" {
            section = .evolutions
            continue
        }
        if trimmedLine == "; Learnset" {
            section = .learnset
            continue
        }
        if line == "db 0" {
            section = .none
            continue
        }

        switch section {
        case .none:
            continue
        case .evolutions:
            if let evolution = parseEvolutionManifest(from: line) {
                currentEvolutions.append(evolution)
            }
        case .learnset:
            guard let match = line.firstMatch(of: /db\s+(\d+),\s+([A-Z_]+)/) else {
                continue
            }
            currentLearnset.append(
                LevelUpMoveManifest(
                    level: Int(match.output.1) ?? 1,
                    moveID: String(match.output.2)
                )
            )
        }
    }

    flushCurrentSpecies()

    return Dictionary(uniqueKeysWithValues: try progressionByLabel.map { label, progression in
        let speciesID = try speciesID(forEvosMovesLabel: label)
        return (speciesID, progression)
    })
}

private func parseEvolutionManifest(from line: String) -> EvolutionManifest? {
    let tokens = line
        .replacingOccurrences(of: "db", with: "")
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    guard let kindToken = tokens.first else {
        return nil
    }

    switch kindToken {
    case "EVOLVE_LEVEL":
        guard tokens.count >= 3, let level = Int(tokens[1]) else {
            return nil
        }
        return EvolutionManifest(
            trigger: .init(kind: .level, level: level),
            targetSpeciesID: tokens[2]
        )
    case "EVOLVE_ITEM":
        guard tokens.count >= 4, let minimumLevel = Int(tokens[2]) else {
            return nil
        }
        return EvolutionManifest(
            trigger: .init(kind: .item, itemID: tokens[1], minimumLevel: minimumLevel),
            targetSpeciesID: tokens[3]
        )
    case "EVOLVE_TRADE":
        guard tokens.count >= 3, let minimumLevel = Int(tokens[1]) else {
            return nil
        }
        return EvolutionManifest(
            trigger: .init(kind: .trade, minimumLevel: minimumLevel),
            targetSpeciesID: tokens[2]
        )
    default:
        return nil
    }
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
    evolutions: [EvolutionManifest],
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
        evolutions: evolutions,
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

func buildTypeEffectiveness(repoRoot: URL) throws -> [TypeEffectivenessManifest] {
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

func buildMoves(repoRoot: URL) throws -> [MoveManifest] {
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
