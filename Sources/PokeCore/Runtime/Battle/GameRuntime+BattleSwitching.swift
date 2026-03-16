extension GameRuntime {
    func resolveBattlePartySelection(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .partySelection,
              gameplayState.playerParty.indices.contains(battle.focusedPartyIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let selectedIndex = battle.focusedPartyIndex
        let selectionMode = battle.partySelectionMode
        guard selectedIndex != battle.playerActiveIndex else {
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
        let recalledIndex = battle.playerActiveIndex
        if gameplayState.playerParty.indices.contains(recalledIndex) {
            gameplayState.playerParty[recalledIndex] = clearBattleStatStages(recalledPokemon)
        }
        battle.playerActiveIndex = selectedIndex
        battle.playerPokemon = clearBattleStatStages(gameplayState.playerParty[selectedIndex])
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
            replacementBeats = makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon,
                pendingAction: .moveSelection
            )
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
                        enemyActiveIndex: nextEnemyIndex,
                        stagedSoundEffectRequests: sendOutSoundEffectRequests(
                            side: .enemy,
                            speciesID: battle.enemyParty[nextEnemyIndex].speciesID
                        )
                    ),
                ],
            ]
            replacementBeats = makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyParty[nextEnemyIndex]
            )
        case .optionalSwitch:
            battle.message = "Come back, \(recalledPokemon.nickname)!"
            updateBattlePresentation(
                battle: &battle,
                stage: .resultText,
                uiVisibility: .visible,
                activeSide: .player,
                hidePlayerPokemon: true,
                meterAnimation: nil,
                transitionStyle: .none
            )
            replacementBeats = [
                .init(
                    delay: battlePresentationDelay(base: 0),
                    stage: .resultText,
                    uiVisibility: .visible,
                    activeSide: .player,
                    hidePlayerPokemon: true,
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
                    playerPokemon: battle.playerPokemon,
                    stagedSoundEffectRequests: sendOutSoundEffectRequests(
                        side: .player,
                        speciesID: battle.playerPokemon.speciesID
                    )
                ),
            ]
        }

        scheduleBattlePresentation(replacementBeats, battleID: battle.battleID)
    }

    func continueSwitchTurnAfterPlayerSwap(battle: inout RuntimeBattleState) {
        var enemyPokemon = battle.enemyPokemon
        var playerPokemon = battle.playerPokemon
        let enemyMoveIndex = selectEnemyMoveIndex(battle: battle, enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
        let enemyAction = resolveBattleAction(
            side: .enemy,
            attacker: enemyPokemon,
            defender: playerPokemon,
            moveIndex: enemyMoveIndex,
            defenderCanActLaterInTurn: false
        )
        var actionBeats = makeBeats(for: enemyAction)
        if let pendingAction = enemyAction.pendingAction,
           actionBeats.isEmpty == false {
            actionBeats[actionBeats.count - 1].pendingAction = pendingAction
        }

        var batches: [[RuntimeBattlePresentationBeat]] = []
        if actionBeats.isEmpty == false {
            batches.append(actionBeats)
        }

        applyResolvedBattleAction(
            enemyAction,
            side: .enemy,
            simulatedPlayer: &playerPokemon,
            simulatedEnemy: &enemyPokemon
        )
        battle.aiLayer2Encouragement += 1

        if enemyAction.pendingAction == nil {
            if appendPostActionResolutionIfNeeded(
                battle: battle,
                simulatedPlayer: &playerPokemon,
                simulatedEnemy: enemyPokemon,
                batches: &batches
            ) == false,
               appendResidualResolutionIfNeeded(
                   actingSide: .enemy,
                   battle: battle,
                   simulatedPlayer: &playerPokemon,
                   simulatedEnemy: &enemyPokemon,
                   batches: &batches
               ) == false {
                batches.append([
                    commandReadyBeat(
                        delay: battlePresentationDelay(base: 0.24),
                        playerPokemon: playerPokemon,
                        enemyPokemon: enemyPokemon
                    ),
                ])
            }
        }

        if batches.isEmpty {
            batches.append([
                commandReadyBeat(
                    delay: battlePresentationDelay(base: 0),
                    playerPokemon: playerPokemon,
                    enemyPokemon: enemyPokemon
                ),
            ])
        }

        battle.enemyPokemon = enemyPokemon
        battle.playerPokemon = playerPokemon

        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.queuedMessages = []
        battle.pendingPresentationBatches = Array(batches.dropFirst())
        battle.message = ""
        scheduleBattlePresentation(batches.first ?? [], battleID: battle.battleID)
    }
}
