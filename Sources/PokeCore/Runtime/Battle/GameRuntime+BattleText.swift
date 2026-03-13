import Foundation

extension GameRuntime {
    var battleDialogueWrapLimit: Int {
        18
    }

    var battleDialoguePageLineLimit: Int {
        2
    }

    var playerBattleFrontSpritePath: String {
        "Assets/battle/trainers/red.png"
    }

    var playerBattleBackSpritePath: String {
        "Assets/battle/trainers/redb.png"
    }

    func formattedBattleText(_ template: String, replacements: [String: String]) -> String {
        replacements.reduce(template) { partial, replacement in
            partial.replacingOccurrences(of: "{\(replacement.key)}", with: replacement.value)
        }
    }

    func battleDialogueMessages(for dialogueID: String?, trainerName: String? = nil) -> [String] {
        guard let dialogueID, let dialogue = content.dialogue(id: dialogueID) else {
            return []
        }

        return dialogue.pages
            .map { page in
                page.lines
                    .joined(separator: "\n")
                    .replacingOccurrences(of: "<PLAYER>", with: playerName)
                    .replacingOccurrences(of: "<RIVAL>", with: trainerName ?? "RIVAL")
            }
            .filter { $0.isEmpty == false }
    }

    func trainerWantsToFightText(trainerName: String) -> String {
        formattedBattleText(
            content.commonBattleText.wantsToFight,
            replacements: [
                "trainerName": trainerName,
            ]
        )
    }

    func enemyFaintedText(for pokemon: RuntimePokemonState) -> String {
        formattedBattleText(
            content.commonBattleText.enemyFainted,
            replacements: [
                "enemyPokemon": pokemon.nickname,
            ]
        )
    }

    func playerFaintedText(for pokemon: RuntimePokemonState) -> String {
        formattedBattleText(
            content.commonBattleText.playerFainted,
            replacements: [
                "playerPokemon": pokemon.nickname,
            ]
        )
    }

    func playerBlackedOutText() -> String {
        formattedBattleText(
            content.commonBattleText.playerBlackedOut,
            replacements: [
                "playerName": playerName,
            ]
        )
    }

    func trainerDefeatedText(trainerName: String) -> String {
        formattedBattleText(
            content.commonBattleText.trainerDefeated,
            replacements: [
                "playerName": playerName,
                "trainerName": trainerName,
            ]
        )
    }

    func moneyForWinningText(amount: Int) -> String {
        formattedBattleText(
            content.commonBattleText.moneyForWinning,
            replacements: [
                "playerName": playerName,
                "money": String(max(0, amount)),
            ]
        )
    }

    func trainerAboutToUseText(trainerName: String, pokemon: RuntimePokemonState) -> String {
        formattedBattleText(
            content.commonBattleText.trainerAboutToUse,
            replacements: [
                "trainerName": trainerName,
                "enemyPokemon": pokemon.nickname,
                "playerName": playerName,
            ]
        )
    }

    func trainerAboutToUseMessages(trainerName: String, pokemon: RuntimePokemonState) -> [String] {
        let message = trainerAboutToUseText(trainerName: trainerName, pokemon: pokemon)
        let sentenceSeparator = "! "
        guard let separatorRange = message.range(of: sentenceSeparator) else {
            return paginatedBattleMessage(message)
        }

        let intro = String(message[..<separatorRange.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let question = String(message[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return [intro, question].filter { $0.isEmpty == false }
    }

    func trainerSentOutText(trainerName: String, pokemon: RuntimePokemonState) -> String {
        formattedBattleText(
            content.commonBattleText.trainerSentOut,
            replacements: [
                "trainerName": trainerName,
                "enemyPokemon": pokemon.nickname,
            ]
        )
    }

    func playerSendOutText(
        for playerPokemon: RuntimePokemonState,
        against enemyPokemon: RuntimePokemonState
    ) -> String {
        let template: String
        let enemyHPPercent = enemyPokemon.maxHP > 0
            ? (enemyPokemon.currentHP * 100) / enemyPokemon.maxHP
            : 100

        switch enemyHPPercent {
        case 70...:
            template = content.commonBattleText.playerSendOutGo
        case 40..<70:
            template = content.commonBattleText.playerSendOutDoIt
        case 10..<40:
            template = content.commonBattleText.playerSendOutGetm
        default:
            template = content.commonBattleText.playerSendOutEnemyWeak
        }

        return formattedBattleText(
            template,
            replacements: [
                "playerPokemon": playerPokemon.nickname,
            ]
        )
    }

    func paginatedBattleMessages(_ messages: [String]) -> [String] {
        messages.flatMap(paginatedBattleMessage)
    }

    func paginatedBattleMessage(_ message: String) -> [String] {
        let wrappedLines = message
            .components(separatedBy: "\n")
            .flatMap { wrapBattleDialogueLine($0, limit: battleDialogueWrapLimit) }
            .filter { $0.isEmpty == false }

        guard wrappedLines.isEmpty == false else {
            return [message]
        }

        var pages: [String] = []
        var currentPage: [String] = []

        for line in wrappedLines {
            currentPage.append(line)
            if currentPage.count == battleDialoguePageLineLimit {
                pages.append(currentPage.joined(separator: "\n"))
                currentPage.removeAll(keepingCapacity: true)
            }
        }

        if currentPage.isEmpty == false {
            pages.append(currentPage.joined(separator: "\n"))
        }

        return pages
    }

    func wrapBattleDialogueLine(_ line: String, limit: Int) -> [String] {
        guard line.count > limit else { return [line] }

        var wrapped: [String] = []
        var currentLine = ""

        for word in line.split(separator: " ", omittingEmptySubsequences: false) {
            let wordText = String(word)
            let candidate = currentLine.isEmpty ? wordText : "\(currentLine) \(wordText)"
            if candidate.count <= limit {
                currentLine = candidate
                continue
            }

            if currentLine.isEmpty == false {
                wrapped.append(currentLine)
            }

            if wordText.count <= limit {
                currentLine = wordText
                continue
            }

            var remainingWord = wordText[...]
            while remainingWord.count > limit {
                let splitIndex = remainingWord.index(remainingWord.startIndex, offsetBy: limit)
                wrapped.append(String(remainingWord[..<splitIndex]))
                remainingWord = remainingWord[splitIndex...]
            }
            currentLine = String(remainingWord)
        }

        if currentLine.isEmpty == false {
            wrapped.append(currentLine)
        }

        return wrapped.isEmpty ? [line] : wrapped
    }
}
