import PokeDataModel

extension GameRuntime {

    // MARK: - Dialogue builders

    private static func oakAppearsDialogue() -> [[String]] {
        [
            ["Hello there!", "Welcome to the world", "of POKéMON!"],
            ["My name is OAK!", "People call me the", "POKéMON PROF!"],
        ]
    }

    private static func nidorinoAppearsDialogue() -> [[String]] {
        [
            ["This world is", "inhabited by creatures", "called POKéMON!"],
            ["For some people,", "POKéMON are pets.", "Others use them for fights."],
            ["Myself…", "I study POKéMON", "as a profession."],
        ]
    }

    private static func playerAppearsDialogue() -> [[String]] {
        [
            ["First, what is", "your name?"],
        ]
    }

    private static func playerNamedDialogue(name: String) -> [[String]] {
        [
            ["Right! So your", "name is \(name)!"],
        ]
    }

    private static func rivalAppearsDialogue() -> [[String]] {
        [
            ["This is my grand-", "son. He's been your rival", "since you were a baby."],
            ["…Erm, what is", "his name again?"],
        ]
    }

    private static func rivalNamedDialogue(name: String) -> [[String]] {
        [
            ["That's right!", "I remember now!", "His name is \(name)!"],
        ]
    }

    private static func finalSpeechDialogue(playerName: String) -> [[String]] {
        [
            ["\(playerName)!", "Your very own", "POKéMON legend is", "about to unfold!"],
            ["A world of dreams", "and adventures with", "POKéMON awaits!", "Let's go!"],
        ]
    }

    // MARK: - Begin

    func beginOakIntro() {
        oakIntroState = OakIntroState(
            phase: .oakAppears,
            dialoguePages: Self.oakAppearsDialogue(),
            currentPageIndex: 0,
            enteredCharacters: [],
            playerName: nil,
            rivalName: nil
        )
        scene = .oakIntro
        substate = "oak_intro"
        publishSnapshot()
    }

    // MARK: - Handle input

    func handleOakIntro(button: RuntimeButton) {
        guard var state = oakIntroState else { return }

        switch state.phase {
        case .namingPlayer, .namingRival:
            handleOakIntroNaming(button: button, state: &state)
        default:
            handleOakIntroDialogue(button: button, state: &state)
        }

        oakIntroState = state
        publishSnapshot()
    }

    private func handleOakIntroDialogue(button: RuntimeButton, state: inout OakIntroState) {
        guard button == .confirm || button == .start else { return }

        if state.currentPageIndex + 1 < state.dialoguePages.count {
            state.currentPageIndex += 1
            return
        }

        advanceOakIntroPhase(state: &state)
    }

    private func handleOakIntroNaming(button: RuntimeButton, state: inout OakIntroState) {
        switch button {
        case .cancel:
            if state.enteredCharacters.isEmpty == false {
                state.enteredCharacters.removeLast()
            }
        case .confirm, .start:
            finalizeOakIntroNaming(state: &state)
        default:
            break
        }
    }

    // MARK: - Phase transitions

    private func advanceOakIntroPhase(state: inout OakIntroState) {
        switch state.phase {
        case .oakAppears:
            state.phase = .nidorinoAppears
            state.dialoguePages = Self.nidorinoAppearsDialogue()
            state.currentPageIndex = 0

        case .nidorinoAppears:
            state.phase = .playerAppears
            state.dialoguePages = Self.playerAppearsDialogue()
            state.currentPageIndex = 0

        case .playerAppears:
            state.phase = .namingPlayer
            state.enteredCharacters = []
            state.dialoguePages = []
            state.currentPageIndex = 0

        case .namingPlayer:
            break

        case .playerNamed:
            state.phase = .rivalAppears
            state.dialoguePages = Self.rivalAppearsDialogue()
            state.currentPageIndex = 0

        case .rivalAppears:
            state.phase = .namingRival
            state.enteredCharacters = []
            state.dialoguePages = []
            state.currentPageIndex = 0

        case .namingRival:
            break

        case .rivalNamed:
            let playerName = state.playerName ?? "RED"
            state.phase = .finalSpeech
            state.dialoguePages = Self.finalSpeechDialogue(playerName: playerName)
            state.currentPageIndex = 0

        case .finalSpeech:
            state.phase = .fadeOut
            finalizeOakIntro()

        case .fadeOut:
            break
        }
    }

    // MARK: - Naming finalization

    private func finalizeOakIntroNaming(state: inout OakIntroState) {
        let enteredText = String(state.enteredCharacters)
            .trimmingCharacters(in: .whitespaces)

        switch state.phase {
        case .namingPlayer:
            let name = enteredText.isEmpty ? "RED" : enteredText
            state.playerName = name
            state.phase = .playerNamed
            state.dialoguePages = Self.playerNamedDialogue(name: name)
            state.currentPageIndex = 0
            state.enteredCharacters = []

        case .namingRival:
            let name = enteredText.isEmpty ? "BLUE" : enteredText
            state.rivalName = name
            state.phase = .rivalNamed
            state.dialoguePages = Self.rivalNamedDialogue(name: name)
            state.currentPageIndex = 0
            state.enteredCharacters = []

        default:
            break
        }
    }

    // MARK: - Finalize intro → field

    private func finalizeOakIntro() {
        let playerName = oakIntroState?.playerName ?? "RED"
        let rivalName = oakIntroState?.rivalName ?? "BLUE"

        gameplayState?.playerName = playerName
        gameplayState?.rivalName = rivalName
        oakIntroState = nil

        scene = .field
        substate = "field"
        restartGameplayClock()
        requestDefaultMapMusic()
        publishSnapshot()
    }
}
