import PokeDataModel

extension GameRuntime {

    // MARK: - Begin

    func beginOakIntro() {
        oakIntroState = OakIntroState(
            phase: .oakAppears,
            currentPageIndex: 0,
            enteredCharacters: [],
            playerName: nil,
            rivalName: nil,
            namePresetFocusedIndex: 0,
            isTypingCustomName: false
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
    }

    private func handleOakIntroDialogue(button: RuntimeButton, state: inout OakIntroState) {
        guard button == .confirm || button == .start else { return }

        let pages = state.dialoguePages
        if state.currentPageIndex + 1 < pages.count {
            state.currentPageIndex += 1
            return
        }

        advanceOakIntroPhase(state: &state)
    }

    private func handleOakIntroNaming(button: RuntimeButton, state: inout OakIntroState) {
        if state.isTypingCustomName {
            handleOakIntroCustomNameInput(button: button, state: &state)
        } else {
            handleOakIntroPresetSelection(button: button, state: &state)
        }
    }

    private func handleOakIntroPresetSelection(button: RuntimeButton, state: inout OakIntroState) {
        let presets = state.currentPresets
        guard presets.isEmpty == false else { return }

        switch button {
        case .up:
            if state.namePresetFocusedIndex > 0 {
                state.namePresetFocusedIndex -= 1
            }
        case .down:
            if state.namePresetFocusedIndex < presets.count - 1 {
                state.namePresetFocusedIndex += 1
            }
        case .confirm, .start:
            if state.namePresetFocusedIndex == 0 {
                // "NEW NAME" — switch to custom text input
                state.isTypingCustomName = true
                state.enteredCharacters = []
            } else {
                // Preset name selected — apply directly
                let chosenName = presets[state.namePresetFocusedIndex]
                applyOakIntroName(chosenName, state: &state)
            }
        case .cancel:
            break
        default:
            break
        }
    }

    private func handleOakIntroCustomNameInput(button: RuntimeButton, state: inout OakIntroState) {
        switch button {
        case .cancel:
            if state.enteredCharacters.isEmpty {
                // Go back to preset selection
                state.isTypingCustomName = false
            } else {
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
            state.currentPageIndex = 0

        case .nidorinoAppears:
            state.phase = .playerAppears
            state.currentPageIndex = 0

        case .playerAppears:
            state.phase = .namingPlayer
            state.enteredCharacters = []
            state.currentPageIndex = 0
            state.namePresetFocusedIndex = 0
            state.isTypingCustomName = false

        case .namingPlayer:
            break

        case .playerNamed:
            state.phase = .rivalAppears
            state.currentPageIndex = 0

        case .rivalAppears:
            state.phase = .namingRival
            state.enteredCharacters = []
            state.currentPageIndex = 0
            state.namePresetFocusedIndex = 0
            state.isTypingCustomName = false

        case .namingRival:
            break

        case .rivalNamed:
            state.phase = .finalSpeech
            state.currentPageIndex = 0

        case .finalSpeech:
            state.phase = .fadeOut
            finalizeOakIntro()

        case .fadeOut:
            break
        }
    }

    // MARK: - Naming finalization

    private func applyOakIntroName(_ name: String, state: inout OakIntroState) {
        switch state.phase {
        case .namingPlayer:
            state.playerName = name
            state.phase = .playerNamed
            state.currentPageIndex = 0
            state.enteredCharacters = []
        case .namingRival:
            state.rivalName = name
            state.phase = .rivalNamed
            state.currentPageIndex = 0
            state.enteredCharacters = []
        default:
            break
        }
    }

    private func finalizeOakIntroNaming(state: inout OakIntroState) {
        let enteredText = state.enteredText
            .trimmingCharacters(in: .whitespaces)

        switch state.phase {
        case .namingPlayer:
            let name = enteredText.isEmpty ? "RED" : enteredText
            state.playerName = name
            state.phase = .playerNamed
            state.currentPageIndex = 0
            state.enteredCharacters = []

        case .namingRival:
            let name = enteredText.isEmpty ? "BLUE" : enteredText
            state.rivalName = name
            state.phase = .rivalNamed
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

        restartGameplayClock()
        enterSettledFieldState(restoreMapMusic: true)
    }
}
