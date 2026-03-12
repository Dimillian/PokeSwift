enum GameplayBattlePrompts {
    static let moveSelection = "Pick the next move."
    static let partySelection = "Bring out which #MON?"
    private static let dialogueWrapLimit = 18

    static func defaultPrompt(for phase: String) -> String {
        phase == "partySelection" ? partySelection : moveSelection
    }

    static func promptText(
        textLines: [String],
        battleMessage: String,
        phase: String
    ) -> String {
        textLines.last ?? (battleMessage.isEmpty ? defaultPrompt(for: phase) : battleMessage)
    }

    static func textLines(_ textLines: [String], phase: String) -> [String] {
        let sourceLines = textLines.isEmpty ? [defaultPrompt(for: phase)] : textLines
        return sourceLines.flatMap { message in
            message
                .components(separatedBy: "\n")
                .flatMap { wrapDialogueLine($0, limit: dialogueWrapLimit) }
        }
    }

    private static func wrapDialogueLine(_ line: String, limit: Int) -> [String] {
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
