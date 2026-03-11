import PokeDataModel

extension GameRuntime {
    func returnToBattleMoveSelection(battle: inout RuntimeBattleState) {
        battle.phase = .moveSelection
        battle.message = "Pick the next move."
    }

    func enterBattleBagSelection(battle: inout RuntimeBattleState) {
        battle.phase = .bagSelection
        battle.focusedBagItemIndex = 0
        battle.message = "Choose an item."
    }

    func enterOptionalBattleSwitchSelection(
        battle: inout RuntimeBattleState,
        gameplayState: GameplayState
    ) {
        enterBattleSwitchSelection(
            battle: &battle,
            gameplayState: gameplayState,
            mode: .optionalSwitch
        )
    }

    func enterForcedBattleSwitchSelection(
        battle: inout RuntimeBattleState,
        gameplayState: GameplayState
    ) {
        enterBattleSwitchSelection(
            battle: &battle,
            gameplayState: gameplayState,
            mode: .forcedReplacement
        )
    }

    func enterBattleSwitchSelection(
        battle: inout RuntimeBattleState,
        gameplayState: GameplayState,
        mode: RuntimeBattlePartySelectionMode
    ) {
        battle.phase = .partySelection
        battle.partySelectionMode = mode
        battle.focusedPartyIndex = firstSwitchablePartyIndex(gameplayState: gameplayState) ?? 0
        battle.message = "Bring out which #MON?"
    }

    func handleBattle(button: RuntimeButton) {
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            switch battle.phase {
            case .moveSelection:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
            case .bagSelection:
                battle.focusedBagItemIndex = max(0, battle.focusedBagItemIndex - 1)
            case .partySelection:
                battle.focusedPartyIndex = max(0, battle.focusedPartyIndex - 1)
            case .learnMoveDecision, .learnMoveSelection:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
            default:
                break
            }
        case .down:
            switch battle.phase {
            case .moveSelection:
                battle.focusedMoveIndex = min(maxBattleActionIndex(for: battle), battle.focusedMoveIndex + 1)
            case .bagSelection:
                battle.focusedBagItemIndex = min(max(0, currentBattleBagItems.count - 1), battle.focusedBagItemIndex + 1)
            case .partySelection:
                battle.focusedPartyIndex = min(max(0, gameplayState.playerParty.count - 1), battle.focusedPartyIndex + 1)
            case .learnMoveDecision:
                battle.focusedMoveIndex = min(1, battle.focusedMoveIndex + 1)
            case .learnMoveSelection:
                battle.focusedMoveIndex = min(max(0, battle.playerPokemon.moves.count - 1), battle.focusedMoveIndex + 1)
            default:
                break
            }
        case .left:
            if battle.phase == .bagSelection {
                battle.focusedBagItemIndex = max(0, battle.focusedBagItemIndex - 1)
            }
        case .right:
            if battle.phase == .bagSelection {
                battle.focusedBagItemIndex = min(max(0, currentBattleBagItems.count - 1), battle.focusedBagItemIndex + 1)
            }
        case .cancel:
            switch battle.phase {
            case .moveSelection:
                guard battle.canRun else { break }
                playUIConfirmSound()
                attemptBattleEscape(battle: &battle)
            case .bagSelection:
                playUIConfirmSound()
                returnToBattleMoveSelection(battle: &battle)
            case .partySelection:
                guard battle.partySelectionMode == .optionalSwitch else { break }
                playUIConfirmSound()
                returnToBattleMoveSelection(battle: &battle)
            case .learnMoveSelection:
                playUIConfirmSound()
                enterLearnMoveDecisionPrompt(battle: &battle)
            default:
                break
            }
        case .confirm, .start:
            switch battle.phase {
            case .introText:
                break
            case .turnText, .resolvingTurn:
                guard battlePresentationTask == nil else { break }
                playUIConfirmSound()
                if battle.pendingPresentationBatches.isEmpty == false {
                    advanceBattlePresentationBatch(battle: &battle)
                } else {
                    advanceBattleText(battle: &battle)
                }
            case .moveSelection:
                playUIConfirmSound()
                resolveBattleTurn(battle: &battle, gameplayState: &gameplayState)
            case .bagSelection:
                playUIConfirmSound()
                resolveBattleBagSelection(battle: &battle, gameplayState: &gameplayState)
            case .partySelection:
                playUIConfirmSound()
                resolveBattlePartySelection(battle: &battle, gameplayState: &gameplayState)
            case .learnMoveDecision:
                playUIConfirmSound()
                resolveLearnMoveDecision(battle: &battle)
            case .learnMoveSelection:
                playUIConfirmSound()
                resolveLearnMoveSelection(battle: &battle)
            case .battleComplete:
                playUIConfirmSound()
                advanceBattleText(battle: &battle)
            }
        }

        guard scene == .battle, self.gameplayState?.battle != nil else {
            return
        }

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        fieldPartyReorderState = nil
        scene = .battle
        substate = "battle"
    }

    func resolveBattleTurn(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .moveSelection else {
            return
        }

        if canUseBattleBag(for: battle), battle.focusedMoveIndex == bagActionIndex(for: battle) {
            enterBattleBagSelection(battle: &battle)
            return
        }

        if canUseBattleSwitch(for: battle, gameplayState: gameplayState),
           battle.focusedMoveIndex == switchActionIndex(for: battle) {
            enterOptionalBattleSwitchSelection(battle: &battle, gameplayState: gameplayState)
            return
        }

        if battle.canRun, battle.focusedMoveIndex == runActionIndex(for: battle) {
            attemptBattleEscape(battle: &battle)
            return
        }

        guard battle.playerPokemon.moves.indices.contains(battle.focusedMoveIndex) else {
            return
        }

        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.queuedMessages = []
        battle.pendingPresentationBatches = []
        battle.message = ""
        updateBattlePresentation(
            battle: &battle,
            stage: .attackWindup,
            uiVisibility: .visible,
            activeSide: nil,
            meterAnimation: nil,
            transitionStyle: .none
        )

        let batches = makeTurnPresentationBatches(for: battle)
        guard let firstBatch = batches.first else { return }
        battle.pendingPresentationBatches = Array(batches.dropFirst())
        scheduleBattlePresentation(firstBatch, battleID: battle.battleID)
    }

    func resolveBattleBagSelection(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .bagSelection else { return }
        let bagItems = currentBattleBagItems
        guard bagItems.indices.contains(battle.focusedBagItemIndex) else {
            returnToBattleMoveSelection(battle: &battle)
            return
        }

        let itemState = bagItems[battle.focusedBagItemIndex]
        guard let item = content.item(id: itemState.itemID), item.battleUse == .ball else {
            returnToBattleMoveSelection(battle: &battle)
            battle.message = "That item can't be used here."
            return
        }
        guard removeItem(item.id, quantity: 1, from: &gameplayState) else {
            returnToBattleMoveSelection(battle: &battle)
            battle.message = "No items left."
            return
        }

        battle.phase = .resolvingTurn
        battle.pendingAction = nil

        switch attemptWildCapture(battle: &battle, gameplayState: &gameplayState, item: item) {
        case .handled:
            return
        case .continueEnemyTurn:
            break
        }

        var enemyPokemon = battle.enemyPokemon
        var playerPokemon = battle.playerPokemon
        let enemyMoveIndex = selectEnemyMoveIndex(enemyPokemon: enemyPokemon, playerPokemon: playerPokemon)
        let enemyMove = applyMove(attacker: &enemyPokemon, defender: &playerPokemon, moveIndex: enemyMoveIndex)
        battle.enemyPokemon = enemyPokemon
        battle.playerPokemon = playerPokemon

        let failureMessage = captureFailureMessage(from: battle.lastCaptureResult)
        var messages = [failureMessage]
        messages.append(contentsOf: enemyMove.messages)
        if playerPokemon.currentHP == 0 {
            presentBattleMessages(messages, battle: &battle, pendingAction: .finish(won: false))
        } else {
            presentBattleMessages(messages, battle: &battle, pendingAction: .moveSelection)
        }
    }

    func maxBattleActionIndex(for battle: RuntimeBattleState) -> Int {
        let moveActionCount = battle.playerPokemon.moves.count
        var count = moveActionCount
        if canUseBattleBag(for: battle) {
            count += 1
        }
        if let gameplayState, canUseBattleSwitch(for: battle, gameplayState: gameplayState) {
            count += 1
        }
        if battle.canRun {
            count += 1
        }
        return max(0, count - 1)
    }

    func canUseBattleBag(for battle: RuntimeBattleState) -> Bool {
        battle.kind == .wild && currentBattleBagItems.isEmpty == false
    }

    func canUseBattleSwitch(for battle: RuntimeBattleState, gameplayState: GameplayState) -> Bool {
        let _ = battle
        return gameplayState.playerParty.dropFirst().contains(where: { $0.currentHP > 0 })
    }

    func firstSwitchablePartyIndex(gameplayState: GameplayState) -> Int? {
        gameplayState.playerParty.indices.first(where: { $0 != 0 && gameplayState.playerParty[$0].currentHP > 0 })
    }

    func bagActionIndex(for battle: RuntimeBattleState) -> Int {
        battle.playerPokemon.moves.count
    }

    func switchActionIndex(for battle: RuntimeBattleState) -> Int {
        battle.playerPokemon.moves.count + (canUseBattleBag(for: battle) ? 1 : 0)
    }

    func runActionIndex(for battle: RuntimeBattleState) -> Int {
        battle.playerPokemon.moves.count
            + (canUseBattleBag(for: battle) ? 1 : 0)
            + ((gameplayState.map { canUseBattleSwitch(for: battle, gameplayState: $0) } ?? false) ? 1 : 0)
    }
}
