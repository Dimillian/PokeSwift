import Foundation
import PokeDataModel

func buildCommonBattleText(repoRoot: URL) throws -> BattleTextTemplateManifest {
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
