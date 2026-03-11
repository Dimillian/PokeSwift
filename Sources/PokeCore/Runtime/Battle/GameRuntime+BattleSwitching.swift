extension GameRuntime {
    func resolveBattlePartySelection(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .partySelection,
              gameplayState.playerParty.indices.contains(battle.focusedPartyIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let selectedIndex = battle.focusedPartyIndex
        let selectionMode = battle.partySelectionMode
        guard selectedIndex != 0 else {
            playCollisionSoundIfNeeded()
            battle.message = "\(battle.playerPokemon.nickname) is already out!"
            return
        }

        guard gameplayState.playerParty[selectedIndex].currentHP > 0 else {
            playCollisionSoundIfNeeded()
            battle.message = "There's no will to battle!"
            return
        }

        let recalledPokemon = battle.playerPokemon
        gameplayState.playerParty[0] = recalledPokemon
        gameplayState.playerParty.swapAt(0, selectedIndex)
        battle.playerPokemon = gameplayState.playerParty[0]
        battle.phase = .resolvingTurn
        battle.pendingAction = selectionMode == .forcedReplacement ? .moveSelection : .continueSwitchTurn
        battle.queuedMessages = []
        battle.pendingPresentationBatches = []
        battle.message = "Go! \(battle.playerPokemon.nickname)!"
        battle.lastCaptureResult = nil
        battle.partySelectionMode = .optionalSwitch

        let replacementBeats: [RuntimeBattlePresentationBeat]
        if selectionMode == .forcedReplacement {
            replacementBeats = [
                .init(
                    delay: battlePresentationDelay(base: 0),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .player,
                    message: "Go! \(battle.playerPokemon.nickname)!",
                    phase: .turnText,
                    pendingAction: .moveSelection,
                    playerPokemon: battle.playerPokemon
                ),
            ]
        } else {
            replacementBeats = [
                .init(
                    delay: battlePresentationDelay(base: 0),
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: .player,
                    message: "Come back, \(recalledPokemon.nickname)!",
                    phase: .turnText
                ),
                .init(
                    delay: battlePresentationDelay(base: 0.26),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .player,
                    message: "Go! \(battle.playerPokemon.nickname)!",
                    phase: .turnText,
                    pendingAction: .continueSwitchTurn,
                    playerPokemon: battle.playerPokemon
                ),
            ]
        }

        scheduleBattlePresentation(replacementBeats, battleID: battle.battleID)
    }

    func continueSwitchTurnAfterPlayerSwap(battle: inout RuntimeBattleState) {
        var enemyPokemon = battle.enemyPokemon
        var playerPokemon = battle.playerPokemon
        let enemyMoveIndex = selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
        let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
        battle.enemyPokemon = enemyPokemon
        battle.playerPokemon = playerPokemon

        if playerPokemon.currentHP == 0 {
            let hasReplacement = gameplayState.map { firstSwitchablePartyIndex(gameplayState: $0) != nil } ?? false
            presentBattleMessages(
                enemyMove.messages,
                battle: &battle,
                pendingAction: hasReplacement ? .continueForcedSwitch : .finish(won: false)
            )
        } else {
            presentBattleMessages(enemyMove.messages, battle: &battle, pendingAction: .moveSelection)
        }
    }
}
