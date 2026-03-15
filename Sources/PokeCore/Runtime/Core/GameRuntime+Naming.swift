import PokeDataModel

extension GameRuntime {

    // MARK: - Nickname Confirmation (on-field Yes/No prompt)

    func beginNicknameConfirmation(
        speciesID: String,
        defaultName: String,
        completion: RuntimeNamingCompletionAction
    ) {
        clearHeldFieldDirections()
        nicknameConfirmation = RuntimeNicknameConfirmationState(
            speciesID: speciesID,
            defaultName: defaultName,
            focusedIndex: 0,
            completionAction: completion
        )
        publishSnapshot()
    }

    func handleNicknameConfirmation(button: RuntimeButton) {
        guard var confirmation = nicknameConfirmation else { return }

        switch button {
        case .up:
            guard confirmation.focusedIndex != 0 else { return }
            confirmation.focusedIndex = 0
        case .down:
            guard confirmation.focusedIndex != 1 else { return }
            confirmation.focusedIndex = 1
        case .confirm, .start:
            playUIConfirmSound()
            if confirmation.focusedIndex == 0 {
                let speciesID = confirmation.speciesID
                let defaultName = confirmation.defaultName
                let completionAction = confirmation.completionAction
                nicknameConfirmation = nil
                beginNaming(
                    speciesID: speciesID,
                    defaultName: defaultName,
                    completion: completionAction
                )
            } else {
                resolveNicknameConfirmationNo(confirmation)
            }
            return
        default:
            return
        }

        nicknameConfirmation = confirmation
        publishSnapshot()
    }

    private func resolveNicknameConfirmationNo(_ confirmation: RuntimeNicknameConfirmationState) {
        nicknameConfirmation = nil

        switch confirmation.completionAction {
        case .returnToFieldAfterCapture:
            applyNicknameToLastPartyMember(confirmation.defaultName)
            returnToFieldAfterCapture()
            traceEvent(
                .nicknameApplied,
                "Named \(confirmation.speciesID) as \(confirmation.defaultName).",
                details: [
                    "speciesID": confirmation.speciesID,
                    "nickname": confirmation.defaultName,
                    "wasDefault": "true",
                ]
            )

        case .returnToFieldAfterStarter:
            finalizeStarterChoiceSequence(nickname: confirmation.defaultName)
        case let .continueCaptureAftermath(aftermath):
            applyNicknameToLastPartyMember(confirmation.defaultName)
            continueCaptureAftermath(aftermath)
            traceEvent(
                .nicknameApplied,
                "Named \(confirmation.speciesID) as \(confirmation.defaultName).",
                details: [
                    "speciesID": confirmation.speciesID,
                    "nickname": confirmation.defaultName,
                    "wasDefault": "true",
                ]
            )
        }
    }

    func beginNicknameConfirmationAfterCapture(_ aftermath: RuntimeCaptureAftermathState) {
        beginNicknameConfirmation(
            speciesID: aftermath.speciesID,
            defaultName: aftermath.defaultName,
            completion: .continueCaptureAftermath(aftermath)
        )
    }

    func continueCaptureAftermath(_ aftermath: RuntimeCaptureAftermathState) {
        switch aftermath.step {
        case .showDexEntry:
            guard aftermath.isNewlyOwned else {
                continueCaptureAftermath(advanceCaptureAftermath(aftermath))
                return
            }
            captureAftermathPokedexSelectionID = aftermath.speciesID
            showDialogue(
                id: "capture_dex_added",
                replacements: captureDialogueReplacements(pokemonName: aftermath.pokemonName),
                completion: .continueCaptureAftermath(advanceCaptureAftermath(aftermath))
            )
        case .promptForNickname:
            guard aftermath.addedToParty else {
                continueCaptureAftermath(advanceCaptureAftermath(aftermath))
                return
            }
            scene = .field
            substate = "field"
            beginNicknameConfirmationAfterCapture(advanceCaptureAftermath(aftermath))
        case .showDestination:
            showCaptureDestinationDialogue(aftermath)
        case .finish:
            returnToFieldAfterCapture()
        }
    }

    func advanceCaptureAftermath(_ aftermath: RuntimeCaptureAftermathState) -> RuntimeCaptureAftermathState {
        var updated = aftermath
        switch aftermath.step {
        case .showDexEntry:
            updated.step = .promptForNickname
        case .promptForNickname:
            updated.step = .showDestination
        case .showDestination:
            updated.step = .finish
        case .finish:
            break
        }
        return updated
    }

    func showCaptureDestinationDialogue(_ aftermath: RuntimeCaptureAftermathState) {
        if let dialogueID = aftermath.destinationDialogueID {
            showDialogue(
                id: dialogueID,
                replacements: captureDialogueReplacements(pokemonName: aftermath.pokemonName),
                completion: .continueCaptureAftermath(advanceCaptureAftermath(aftermath))
            )
            return
        }

        showInlineDialogue(
            id: "capture_destination_party",
            pages: [
                .init(
                    lines: [
                        "\(aftermath.pokemonName) was added",
                        "to your party.",
                    ],
                    waitsForPrompt: true
                ),
            ],
            completion: .continueCaptureAftermath(advanceCaptureAftermath(aftermath))
        )
    }

    // MARK: - Naming Screen (text input on black screen)

    func beginNaming(
        speciesID: String,
        defaultName: String,
        completion: RuntimeNamingCompletionAction
    ) {
        clearHeldFieldDirections()
        namingState = RuntimeNamingState(
            speciesID: speciesID,
            defaultName: defaultName,
            enteredCharacters: [],
            completionAction: completion
        )
        scene = .naming
        substate = "naming"
        publishSnapshot()
    }

    func handleNaming(button: RuntimeButton) {
        guard var state = namingState else { return }

        switch button {
        case .cancel:
            if state.enteredCharacters.isEmpty == false {
                state.enteredCharacters.removeLast()
            }
        case .confirm, .start:
            finalizeNaming()
            return
        default:
            break
        }

        namingState = state
        publishSnapshot()
    }

    func finalizeNaming() {
        guard let state = namingState else { return }

        let nickname: String
        if state.enteredCharacters.isEmpty {
            nickname = state.defaultName
        } else {
            nickname = state.enteredText.trimmingCharacters(in: .whitespaces)
                .isEmpty ? state.defaultName : state.enteredText
        }

        switch state.completionAction {
        case .returnToFieldAfterCapture:
            applyNicknameToLastPartyMember(nickname)
            namingState = nil
            returnToFieldAfterCapture()

        case .returnToFieldAfterStarter:
            namingState = nil
            finalizeStarterChoiceSequence(nickname: nickname)
        case let .continueCaptureAftermath(aftermath):
            applyNicknameToLastPartyMember(nickname)
            namingState = nil
            continueCaptureAftermath(aftermath)
        }

        traceEvent(
            .nicknameApplied,
            "Named \(state.speciesID) as \(nickname).",
            details: [
                "speciesID": state.speciesID,
                "nickname": nickname,
                "wasDefault": String(nickname == state.defaultName),
            ]
        )
    }

    public func typeNamingCharacter(_ character: Character) {
        guard var state = namingState else { return }
        let upper = Character(character.uppercased())
        guard RuntimeNamingState.validCharacters.contains(upper) else { return }
        guard state.enteredCharacters.count < RuntimeNamingState.maxLength else { return }
        state.enteredCharacters.append(upper)
        namingState = state
        publishSnapshot()
    }

    private func returnToFieldAfterCapture() {
        if var gameplayState {
            gameplayState.battle = nil
            self.gameplayState = gameplayState
        }
        scene = .field
        substate = "field"
        captureAftermathPokedexSelectionID = nil
        requestDefaultMapMusic()
        publishSnapshot()
    }

    private func applyNicknameToLastPartyMember(_ nickname: String) {
        guard var gameplayState,
              gameplayState.playerParty.isEmpty == false else { return }
        gameplayState.playerParty[gameplayState.playerParty.count - 1].nickname = nickname
        self.gameplayState = gameplayState
    }
}
