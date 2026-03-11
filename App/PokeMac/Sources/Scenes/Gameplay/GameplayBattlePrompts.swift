enum GameplayBattlePrompts {
    static let moveSelection = "Pick the next move."
    static let partySelection = "Bring out which #MON?"

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
        textLines.isEmpty ? [defaultPrompt(for: phase)] : textLines
    }
}
