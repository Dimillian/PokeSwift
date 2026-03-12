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
        gameplayState.playerParty[0] = clearBattleStatStages(recalledPokemon)
        gameplayState.playerParty.swapAt(0, selectedIndex)
        battle.playerPokemon = clearBattleStatStages(gameplayState.playerParty[0])
        battle.phase = .resolvingTurn
        switch selectionMode {
        case .forcedReplacement:
            battle.pendingAction = .moveSelection
        case .optionalSwitch:
            battle.pendingAction = .continueSwitchTurn
        case .trainerShift:
            battle.pendingAction = nil
        }
        battle.queuedMessages = []
        battle.pendingPresentationBatches = []
        battle.message = playerSendOutText(for: battle.playerPokemon, against: battle.enemyPokemon)
        battle.lastCaptureResult = nil
        battle.partySelectionMode = .optionalSwitch

        let replacementBeats: [RuntimeBattlePresentationBeat]
        switch selectionMode {
        case .forcedReplacement:
            replacementBeats = [
                .init(
                    delay: battlePresentationDelay(base: 0),
                    stage: .enemySendOut,
                    uiVisibility: .visible,
                    activeSide: .player,
                    message: playerSendOutText(for: battle.playerPokemon, against: battle.enemyPokemon),
                    phase: .turnText,
                    pendingAction: .moveSelection,
                    playerPokemon: battle.playerPokemon
                ),
            ]
        case let .trainerShift(nextEnemyIndex):
            battle.pendingAction = nil
            battle.pendingPresentationBatches = [
                [
                    .init(
                        delay: battlePresentationDelay(base: 0.34),
                        stage: .enemySendOut,
                        uiVisibility: .visible,
                        activeSide: .enemy,
                        message: trainerSentOutText(
                            trainerName: battle.trainerName,
                            pokemon: battle.enemyParty[nextEnemyIndex]
                        ),
                        phase: .turnText,
                        pendingAction: .moveSelection,
                        enemyParty: battle.enemyParty,
                        enemyActiveIndex: nextEnemyIndex
                    ),
                ],
            ]
            replacementBeats = makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyParty[nextEnemyIndex]
            )
        case .optionalSwitch:
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
                    message: playerSendOutText(for: battle.playerPokemon, against: battle.enemyPokemon),
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
        let enemyMoveIndex = selectEnemyMoveIndex(battle: battle, enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
        let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
        battle.aiLayer2Encouragement += 1
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
