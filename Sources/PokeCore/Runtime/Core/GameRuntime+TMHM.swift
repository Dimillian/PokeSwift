import PokeDataModel

private enum TMHMLearnEligibility {
    case canLearn
    case alreadyKnows
    case incompatible
}

extension GameRuntime {
    func tmhmItem(for itemID: String) -> ItemManifest? {
        guard let item = content.item(id: itemID), item.tmhmMoveID != nil else {
            return nil
        }
        return item
    }

    func hasUsableTMHMTarget(itemID: String, party: [RuntimePokemonState]) -> Bool {
        party.contains { tmhmLearnEligibility(itemID: itemID, pokemon: $0) == .canLearn }
    }

    private func tmhmLearnEligibility(itemID: String, pokemon: RuntimePokemonState) -> TMHMLearnEligibility {
        guard let item = tmhmItem(for: itemID),
              let moveID = item.tmhmMoveID,
              let species = content.species(id: pokemon.speciesID) else {
            return .incompatible
        }

        if pokemon.moves.contains(where: { $0.id == moveID }) {
            return .alreadyKnows
        }

        return species.tmhmLearnset.contains(moveID) ? .canLearn : .incompatible
    }

    func resolveFieldTMHMSelection(_ index: Int) {
        guard var gameplayState,
              let itemID = fieldItemUseState?.itemID,
              gameplayState.playerParty.indices.contains(index),
              let item = tmhmItem(for: itemID),
              let moveID = item.tmhmMoveID,
              let move = content.move(id: moveID) else {
            return
        }

        let pokemon = gameplayState.playerParty[index]
        switch tmhmLearnEligibility(itemID: itemID, pokemon: pokemon) {
        case .incompatible:
            showFieldItemUseDialogue(
                id: "field_tmhm_no_effect",
                message: medicineNoEffectMessage
            )
            publishSnapshot()
            return
        case .alreadyKnows:
            fieldItemUseState = nil
            self.gameplayState = gameplayState
            showFieldItemUseDialogue(
                id: "field_tmhm_already_knows_\(itemID.lowercased())_\(index)",
                message: "\(pokemon.nickname) already knows \(move.displayName)."
            )
            publishSnapshot()
            return
        case .canLearn:
            break
        }

        fieldItemUseState = nil
        if pokemon.moves.count < 4 {
            var updatedPokemon = pokemon
            updatedPokemon.moves.append(RuntimeMoveState(id: move.id, currentPP: move.maxPP))
            gameplayState.playerParty[index] = updatedPokemon
            finishFieldTMHMUse(
                itemID: itemID,
                gameplayState: gameplayState,
                dialogueID: "field_tmhm_\(itemID.lowercased())_\(index)",
                message: "\(updatedPokemon.nickname) learned \(move.displayName)!"
            )
            return
        }

        fieldLearnMoveState = RuntimeFieldLearnMoveState(
            itemID: itemID,
            pokemonIndex: index,
            stage: .confirm,
            focusedIndex: 0,
            learnMoveState: RuntimeLearnMoveState(moveID: move.id, remainingMoveIDs: [])
        )
        self.gameplayState = gameplayState
        publishSnapshot()
    }

    func handleFieldLearnMove(button: RuntimeButton) {
        guard var state = fieldLearnMoveState,
              var gameplayState,
              gameplayState.playerParty.indices.contains(state.pokemonIndex) else {
            fieldLearnMoveState = nil
            publishSnapshot()
            return
        }

        let knownMoves = gameplayState.playerParty[state.pokemonIndex].moves
        switch button {
        case .up, .left:
            state.focusedIndex = max(0, state.focusedIndex - 1)
        case .down, .right:
            let maxIndex: Int
            switch state.stage {
            case .confirm:
                maxIndex = 1
            case .replace:
                maxIndex = max(0, knownMoves.count - 1)
            }
            state.focusedIndex = min(maxIndex, state.focusedIndex + 1)
        case .cancel:
            playUIConfirmSound()
            switch state.stage {
            case .confirm:
                cancelFieldLearnMove(state: state, gameplayState: gameplayState)
                return
            case .replace:
                state.stage = .confirm
                state.focusedIndex = 0
            }
        case .confirm, .start:
            playUIConfirmSound()
            switch state.stage {
            case .confirm:
                if state.focusedIndex == 0 {
                    state.stage = .replace
                    state.focusedIndex = 0
                } else {
                    cancelFieldLearnMove(state: state, gameplayState: gameplayState)
                    return
                }
            case .replace:
                switch resolveLearnMoveReplacement(
                    learnMoveState: state.learnMoveState,
                    focusedMoveIndex: state.focusedIndex,
                    knownMoves: knownMoves
                ) {
                case nil:
                    return
                case let .blocked(message):
                    self.gameplayState = gameplayState
                    fieldLearnMoveState = state
                    showFieldItemUseDialogue(
                        id: "field_tmhm_blocked_\(state.itemID.lowercased())_\(state.pokemonIndex)",
                        message: message
                    )
                    publishSnapshot()
                    return
                case let .replaced(updatedMoves, forgottenMoveName, learnedMoveName):
                    gameplayState.playerParty[state.pokemonIndex].moves = updatedMoves
                    finishFieldTMHMUse(
                        itemID: state.itemID,
                        gameplayState: gameplayState,
                        dialogueID: "field_tmhm_\(state.itemID.lowercased())_\(state.pokemonIndex)_replace",
                        message: """
                        \(gameplayState.playerParty[state.pokemonIndex].nickname) forgot \(forgottenMoveName).
                        \(gameplayState.playerParty[state.pokemonIndex].nickname) learned \(learnedMoveName)!
                        """
                    )
                    return
                }
            }
        }

        fieldLearnMoveState = state
        self.gameplayState = gameplayState
        publishSnapshot()
    }

    private func cancelFieldLearnMove(
        state: RuntimeFieldLearnMoveState,
        gameplayState: GameplayState
    ) {
        let pokemonName = gameplayState.playerParty[state.pokemonIndex].nickname
        let moveDisplayName = content.move(id: state.learnMoveState.moveID)?.displayName ?? state.learnMoveState.moveID
        fieldLearnMoveState = nil
        fieldItemUseState = nil
        self.gameplayState = gameplayState
        showFieldItemUseDialogue(
            id: "field_tmhm_declined_\(state.itemID.lowercased())_\(state.pokemonIndex)",
            message: "\(pokemonName) did not learn \(moveDisplayName)."
        )
        publishSnapshot()
    }

    private func finishFieldTMHMUse(
        itemID: String,
        gameplayState: GameplayState,
        dialogueID: String,
        message: String
    ) {
        var gameplayState = gameplayState
        fieldLearnMoveState = nil
        fieldItemUseState = nil

        if itemID.hasPrefix("TM_") {
            guard removeItem(itemID, quantity: 1, from: &gameplayState) else {
                self.gameplayState = gameplayState
                showFieldItemUseDialogue(
                    id: "field_tmhm_no_effect",
                    message: medicineNoEffectMessage
                )
                publishSnapshot()
                return
            }
            traceItemUseRemoval(itemID: itemID, gameplayState: gameplayState)
        }

        self.gameplayState = gameplayState
        showFieldItemUseDialogue(id: dialogueID, message: message)
        publishSnapshot()
    }
}
