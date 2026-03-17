import PokeDataModel

struct MoveTeachingPreparationResult {
    let messages: [String]
    let pendingLearnMove: RuntimeLearnMoveState?
}

enum MoveTeachingReplacementResolution {
    case blocked(message: String)
    case replaced(updatedMoves: [RuntimeMoveState], forgottenMoveName: String, learnedMoveName: String)
}

extension GameRuntime {
    func applyPendingMoveTeaching(
        to pokemon: inout RuntimePokemonState,
        moveIDs: [String],
        knownMoves initialKnownMoves: [RuntimeMoveState],
        setKnownMoves: ([RuntimeMoveState], inout RuntimePokemonState) -> Void
    ) -> MoveTeachingPreparationResult {
        var messages: [String] = []
        var pendingMoveIDs = moveIDs
        var knownMoves = initialKnownMoves

        while pendingMoveIDs.isEmpty == false {
            let moveID = pendingMoveIDs.removeFirst()
            guard knownMoves.contains(where: { $0.id == moveID }) == false,
                  let move = content.move(id: moveID) else {
                continue
            }

            if knownMoves.count < 4 {
                knownMoves.append(RuntimeMoveState(id: move.id, currentPP: move.maxPP))
                setKnownMoves(knownMoves, &pokemon)
                messages.append("\(pokemon.nickname) learned \(move.displayName)!")
                continue
            }

            messages.append("\(pokemon.nickname) is trying to learn \(move.displayName)!")
            messages.append("But \(pokemon.nickname) can't learn more than 4 moves.")
            return MoveTeachingPreparationResult(
                messages: messages,
                pendingLearnMove: .init(moveID: move.id, remainingMoveIDs: pendingMoveIDs)
            )
        }

        return MoveTeachingPreparationResult(messages: messages, pendingLearnMove: nil)
    }

    func learnMoveDecisionPromptMessage(moveID: String, pokemonName: String) -> String? {
        guard let move = content.move(id: moveID) else {
            return nil
        }
        return "Teach \(move.displayName) to \(pokemonName)?"
    }

    func learnMoveReplacementPromptMessage(moveID: String) -> String? {
        guard let move = content.move(id: moveID) else {
            return nil
        }
        return "Choose a move to forget for \(move.displayName)."
    }

    func resolveLearnMoveReplacement(
        learnMoveState: RuntimeLearnMoveState,
        focusedMoveIndex: Int,
        knownMoves: [RuntimeMoveState]
    ) -> MoveTeachingReplacementResolution? {
        guard knownMoves.indices.contains(focusedMoveIndex),
              let newMove = content.move(id: learnMoveState.moveID) else {
            return nil
        }

        let forgottenMoveID = knownMoves[focusedMoveIndex].id
        guard hmMoveIDs.contains(forgottenMoveID) == false else {
            let moveDisplayName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
            return .blocked(message: "\(moveDisplayName) can't be forgotten.")
        }

        let forgottenMoveName = content.move(id: forgottenMoveID)?.displayName ?? forgottenMoveID
        var updatedMoves = knownMoves
        updatedMoves[focusedMoveIndex] = RuntimeMoveState(
            id: newMove.id,
            currentPP: newMove.maxPP
        )
        return .replaced(
            updatedMoves: updatedMoves,
            forgottenMoveName: forgottenMoveName,
            learnedMoveName: newMove.displayName
        )
    }

    public var hmMoveIDs: Set<String> {
        let extractedHMMoveIDs = Set(
            content.gameplayManifest.items
                .filter { $0.id.hasPrefix("HM_") }
                .compactMap(\.tmhmMoveID)
        )
        // Focused fixtures sometimes omit unrelated HM items, but HM-forget protection
        // must still match Red's fixed HM move set in both battle and field flows.
        return extractedHMMoveIDs.union(["CUT", "FLY", "SURF", "STRENGTH", "FLASH"])
    }
}
