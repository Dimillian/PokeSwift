import PokeDataModel

extension GameRuntime {

    // MARK: - Nickname Confirmation (on-field Yes/No prompt)

    func beginNicknameConfirmation(
        speciesID: String,
        defaultName: String,
        completion: RuntimeNamingCompletionAction
    ) {
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
        }
    }

    func beginNicknameConfirmationAfterCapture(battle: RuntimeBattleState) {
        cancelBattlePresentation()
        guard var gameplayState else { return }
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        self.gameplayState = gameplayState

        let speciesID = battle.enemyPokemon.speciesID
        let defaultName = content.species(id: speciesID)?.displayName ?? speciesID.capitalized

        traceEvent(
            .battleEnded,
            "Captured \(speciesID) in \(battle.battleID).",
            mapID: gameplayState.mapID,
            battleID: battle.battleID,
            battleKind: battle.kind,
            details: [
                "outcome": "captured",
                "speciesID": speciesID,
            ]
        )

        beginNicknameConfirmation(
            speciesID: speciesID,
            defaultName: defaultName,
            completion: .returnToFieldAfterCapture
        )
    }

    // MARK: - Naming Screen (text input on black screen)

    func beginNaming(
        speciesID: String,
        defaultName: String,
        completion: RuntimeNamingCompletionAction
    ) {
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
