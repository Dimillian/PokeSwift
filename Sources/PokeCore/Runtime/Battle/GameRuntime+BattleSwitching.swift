extension GameRuntime {
    func resolveBattlePartySelection(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .partySelection,
              gameplayState.playerParty.indices.contains(battle.focusedPartyIndex) else {
            if case .itemUse = battle.partySelectionMode {
                enterBattleBagSelection(battle: &battle)
            } else {
                returnToBattleMoveSelection(battle: &battle)
            }
            return
        }

        let selectedIndex = battle.focusedPartyIndex
        let selectionMode = battle.partySelectionMode

        if case let .itemUse(itemID) = selectionMode {
            guard let resolvedUse = applyMedicine(itemID: itemID, to: gameplayState.playerParty[selectedIndex]) else {
                playCollisionSoundIfNeeded()
                battle.message = medicineNoEffectMessage
                return
            }
            guard removeItem(itemID, quantity: 1, from: &gameplayState) else {
                enterBattleBagSelection(battle: &battle)
                battle.message = "No items left."
                return
            }

            gameplayState.playerParty[selectedIndex] = resolvedUse.updatedPokemon
            if selectedIndex == battle.playerActiveIndex {
                battle.playerPokemon = resolvedUse.updatedPokemon
            }

            traceEvent(
                .inventoryChanged,
                "Removed 1x \(itemID).",
                mapID: gameplayState.mapID,
                battleID: battle.battleID,
                details: [
                    "itemID": itemID,
                    "quantity": "1",
                    "operation": "remove",
                    "reason": "itemUse",
                ]
            )

            battle.phase = .resolvingTurn
            battle.pendingAction = nil
            battle.queuedMessages = []
            battle.pendingPresentationBatches = []
            battle.lastCaptureResult = nil
            battle.partySelectionMode = .optionalSwitch

            var enemyPokemon = battle.enemyPokemon
            var playerPokemon = battle.playerPokemon
            let enemyMoveIndex = selectEnemyMoveIndex(
                battle: battle,
                enemyPokemon: enemyPokemon,
                playerPokemon: playerPokemon
            )
            let enemyMove = applyMove(
                attacker: &enemyPokemon,
                defender: &playerPokemon,
                moveIndex: enemyMoveIndex
            )
            battle.aiLayer2Encouragement += 1
            battle.enemyPokemon = enemyPokemon
            battle.playerPokemon = playerPokemon

            var messages = [resolvedUse.message]
            messages.append(contentsOf: enemyMove.messages)
            if playerPokemon.currentHP == 0 {
                presentBattleMessages(messages, battle: &battle, pendingAction: .finish(won: false))
            } else {
                presentBattleMessages(messages, battle: &battle, pendingAction: .moveSelection)
            }
            return
        }

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
        case .itemUse:
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
                makeEnemySendOutBatch(
                    trainerName: battle.trainerName,
                    pokemon: battle.enemyParty[nextEnemyIndex],
                    enemyParty: battle.enemyParty,
                    enemyActiveIndex: nextEnemyIndex,
                    pendingAction: .moveSelection
                ),
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
            ] + makePlayerSendOutBatch(
                playerPokemon: battle.playerPokemon,
                enemyPokemon: battle.enemyPokemon,
                pendingAction: .continueSwitchTurn,
                delayBase: 0.26
            )
        case .itemUse:
            replacementBeats = []
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

        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.queuedMessages = []
        battle.pendingPresentationBatches = Array(batches.dropFirst())
        battle.message = ""
        scheduleBattlePresentation(batches.first ?? [], battleID: battle.battleID)
    }
}
