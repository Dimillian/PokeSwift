import PokeDataModel

extension GameRuntime {
    func beginNaming(
        speciesID: String,
        defaultName: String,
        completion: RuntimeNamingCompletionAction
    ) {
        namingState = RuntimeNamingState(
            speciesID: speciesID,
            defaultName: defaultName,
            enteredCharacters: [],
            cursorRow: 0,
            cursorColumn: 0,
            completionAction: completion
        )
        scene = .naming
        substate = "naming"
        publishSnapshot()
    }

    func handleNaming(button: RuntimeButton) {
        guard var state = namingState else { return }

        switch button {
        case .up:
            if state.cursorRow > 0 {
                state.cursorRow -= 1
            }
        case .down:
            if state.cursorRow < state.gridRowCount - 1 {
                state.cursorRow += 1
                if state.isOnEnd {
                    state.cursorColumn = 0
                }
            }
        case .left:
            if state.isOnEnd {
                break
            } else if state.cursorColumn > 0 {
                state.cursorColumn -= 1
            }
        case .right:
            if state.isOnEnd {
                break
            } else if state.cursorColumn < state.gridColumnCount - 1 {
                state.cursorColumn += 1
            }
        case .confirm:
            if state.isOnEnd {
                finalizeNaming()
                return
            }
            let row = RuntimeNamingState.gridCharacters[state.cursorRow]
            let char = row[state.cursorColumn]
            if state.enteredCharacters.count < RuntimeNamingState.maxLength {
                state.enteredCharacters.append(char)
            }
        case .cancel:
            if state.enteredCharacters.isEmpty == false {
                state.enteredCharacters.removeLast()
            }
        case .start:
            finalizeNaming()
            return
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
            if var gameplayState {
                gameplayState.battle = nil
                self.gameplayState = gameplayState
            }
            namingState = nil
            scene = .field
            substate = "field"
            requestDefaultMapMusic()
            publishSnapshot()

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

    func beginNamingAfterCapture(battle: RuntimeBattleState) {
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

        beginNaming(
            speciesID: speciesID,
            defaultName: defaultName,
            completion: .returnToFieldAfterCapture
        )
    }

    private func applyNicknameToLastPartyMember(_ nickname: String) {
        guard var gameplayState,
              gameplayState.playerParty.isEmpty == false else { return }
        gameplayState.playerParty[gameplayState.playerParty.count - 1].nickname = nickname
        self.gameplayState = gameplayState
    }
}
